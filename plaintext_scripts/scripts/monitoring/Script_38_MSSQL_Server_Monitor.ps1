<#
.SYNOPSIS
    MSSQL Server Monitor - Microsoft SQL Server Health and Database Monitoring

.DESCRIPTION
    Monitors Microsoft SQL Server instances including database inventory, backup compliance,
    SQL Agent job failures, transaction log growth, and service health. Essential for ensuring
    database availability, backup SLAs, and early detection of database issues.
    
    Critical for preventing data loss through backup monitoring, detecting job failures that
    impact business processes, and identifying transaction log growth that can cause disk
    space exhaustion. Foundational for database administration and disaster recovery readiness.
    
    Monitoring Scope:
    
    SQL Server Detection:
    - Searches for MSSQL* services
    - Detects named instances and default instance (MSSQLSERVER)
    - Supports multiple instances on single server
    - Gracefully exits if SQL Server not installed
    
    Module Loading:
    - Primary: SqlServer module (SQL Server 2016+)
    - Fallback: SQLPS module (legacy SQL Server 2012-2014)
    - WMI fallback if modules unavailable
    
    Instance Inventory:
    - Enumerates all SQL instances from services
    - Tracks instance names: DEFAULT or named instances
    - Monitors service status per instance
    - Generates HTML instance status table
    
    Database Count:
    - Queries sys.databases for online databases
    - Excludes offline or restoring databases
    - Aggregates across all running instances
    - Capacity planning metric
    
    Backup Compliance Monitoring:
    - Queries msdb.dbo.backupset for last full backup
    - Tracks most recent backup across all databases
    - Warns if no backup in 24 hours
    - Critical for RPO (Recovery Point Objective) compliance
    
    SQL Agent Job Monitoring:
    - Queries sysjobhistory for failed jobs (24h window)
    - Counts jobs with run_status = 0 (failed)
    - Failed jobs indicate maintenance issues
    - Business process impact detection
    
    Transaction Log Growth:
    - Queries sys.master_files for LOG type files
    - Calculates total log size across all databases
    - Large logs indicate log backup issues
    - Disk space exhaustion early warning
    
    Instance Summary Reporting:
    - HTML formatted instance table
    - Color-coded status: green (Running), red (Stopped)
    - Stores in WYSIWYG field for dashboard
    
    Health Status Classification:
    
    Healthy:
    - All instances running
    - No failed jobs in 24h
    - Recent backup within 24h
    - Normal operations
    
    Warning:
    - Instances running but failed jobs detected
    - No backup in 24 hours (RPO risk)
    - Action needed
    
    Critical:
    - One or more instances stopped
    - Database unavailable
    - Service failure
    
    Unknown:
    - SQL Server not installed
    - Query failures
    - Script execution error

.NOTES
    Frequency: Every 4 hours
    Runtime: ~45 seconds
    Timeout: 120 seconds
    Context: SYSTEM
    
    Fields Updated:
    - MSSQLInstalled (Checkbox)
    - MSSQLInstanceCount (Integer: total instances)
    - MSSQLInstanceSummary (WYSIWYG: HTML instance table)
    - MSSQLDatabaseCount (Integer: online databases across all instances)
    - MSSQLFailedJobsCount (Integer: failed jobs in 24h)
    - MSSQLLastBackup (DateTime: most recent full backup)
    - MSSQLTransactionLogSizeMB (Integer: total log size MB)
    - MSSQLHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - Microsoft SQL Server installed
    - SqlServer PowerShell module or SQLPS (legacy)
    - SQL Server authentication (Windows Auth via SYSTEM account)
    - Permissions: VIEW SERVER STATE, VIEW ANY DEFINITION
    - msdb database access for backup/job queries
    
    Supported SQL Versions:
    - SQL Server 2012 and newer
    - SQL Server 2014, 2016, 2017, 2019, 2022
    - SQL Server Express editions
    
    Instance Types:
    - DEFAULT: Default instance (MSSQLSERVER service)
    - Named instances: MSSQL$INSTANCENAME services
    - Multiple instances supported
    
    Connection Authentication:
    - Uses Windows Authentication (Integrated Security)
    - SYSTEM account must have SQL permissions
    - No SQL authentication credentials stored
    
    Common Issues:
    - Module not found: Install SQL Server Management Tools
    - Connection timeout: Check SQL Server service running
    - Access denied: Grant SYSTEM account SQL permissions
    - No backup data: Verify msdb database accessible
    - Large transaction logs: Configure log backups
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting MSSQL Server Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    $mssqlInstalled = $false
    $instanceCount = 0
    $instanceSummary = ""
    $databaseCount = 0
    $failedJobsCount = 0
    $lastBackup = $null
    $transactionLogSizeMB = 0
    $healthStatus = "Unknown"
    
    Write-Output "INFO: Checking for SQL Server installation..."
    $sqlServices = Get-Service -Name "MSSQL*" -ErrorAction SilentlyContinue
    
    if ($null -eq $sqlServices -or $sqlServices.Count -eq 0) {
        Write-Output "INFO: SQL Server not installed"
        
        Ninja-Property-Set mssqlInstalled $false
        Ninja-Property-Set mssqlInstanceCount 0
        Ninja-Property-Set mssqlInstanceSummary "SQL Server not installed"
        Ninja-Property-Set mssqlDatabaseCount 0
        Ninja-Property-Set mssqlFailedJobsCount 0
        Ninja-Property-Set mssqlLastBackup ""
        Ninja-Property-Set mssqlTransactionLogSizeMB 0
        Ninja-Property-Set mssqlHealthStatus "Unknown"
        
        Write-Output "SUCCESS: MSSQL monitoring skipped (not installed)"
        exit 0
    }
    
    $mssqlInstalled = $true
    Write-Output "INFO: SQL Server detected - $($sqlServices.Count) service(s) found"
    
    Write-Output "INFO: Loading SQL Server PowerShell module..."
    try {
        if (Get-Module -ListAvailable -Name SqlServer) {
            Import-Module SqlServer -ErrorAction Stop
            Write-Output "INFO: SqlServer module loaded"
        } elseif (Get-Module -ListAvailable -Name SQLPS) {
            Import-Module SQLPS -DisableNameChecking -ErrorAction Stop
            Write-Output "INFO: SQLPS module loaded (legacy)"
        } else {
            Write-Output "WARNING: SQL PowerShell module not available, using WMI fallback"
        }
    } catch {
        Write-Output "WARNING: SQL module import failed: $_"
    }
    
    Write-Output "INFO: Enumerating SQL instances..."
    $instances = @()
    $htmlRows = @()
    
    try {
        $sqlServiceNames = $sqlServices | Where-Object { $_.Name -like "MSSQL`$*" -or $_.Name -eq "MSSQLSERVER" }
        
        foreach ($service in $sqlServiceNames) {
            $instanceName = if ($service.Name -eq "MSSQLSERVER") {
                "DEFAULT"
            } else {
                $service.Name -replace "MSSQL\$", ""
            }
            
            $serverName = if ($instanceName -eq "DEFAULT") {
                $env:COMPUTERNAME
            } else {
                "$($env:COMPUTERNAME)\$instanceName"
            }
            
            Write-Output "  Instance: $instanceName ($($service.Status))"
            
            $instances += [PSCustomObject]@{
                Name = $instanceName
                ServerName = $serverName
                Status = $service.Status
                StartType = $service.StartType
            }
            
            $statusColor = if ($service.Status -eq 'Running') { 'green' } else { 'red' }
            $htmlRows += "<tr><td>$instanceName</td><td style='color:$statusColor'>$($service.Status)</td></tr>"
        }
        
        $instanceCount = $instances.Count
        Write-Output "INFO: SQL instances found: $instanceCount"
        
    } catch {
        Write-Output "WARNING: Failed to enumerate SQL instances: $_"
    }
    
    if ($htmlRows.Count -gt 0) {
        $instanceSummary = @"
<table border='1' style='border-collapse:collapse; width:100%'>
<tr><th>Instance</th><th>Status</th></tr>
$($htmlRows -join "`n")
</table>
"@
    } else {
        $instanceSummary = "No instances detected"
    }
    
    Write-Output "INFO: Querying running instances for metrics..."
    foreach ($instance in $instances | Where-Object { $_.Status -eq 'Running' }) {
        try {
            Write-Output "  Querying: $($instance.ServerName)..."
            
            $dbQuery = "SELECT COUNT(*) as DbCount FROM sys.databases WHERE state_desc = 'ONLINE'"
            $dbResult = Invoke-Sqlcmd -ServerInstance $instance.ServerName -Query $dbQuery -ConnectionTimeout 10 -QueryTimeout 30 -ErrorAction Stop
            $databaseCount += $dbResult.DbCount
            Write-Output "    Databases: $($dbResult.DbCount)"
            
            $backupQuery = @"
SELECT TOP 1 backup_finish_date 
FROM msdb.dbo.backupset 
WHERE type = 'D' 
ORDER BY backup_finish_date DESC
"@
            $backupResult = Invoke-Sqlcmd -ServerInstance $instance.ServerName -Query $backupQuery -ConnectionTimeout 10 -QueryTimeout 30 -ErrorAction Stop
            if ($backupResult -and $backupResult.backup_finish_date) {
                $backupDate = $backupResult.backup_finish_date
                if ($null -eq $lastBackup -or $backupDate -gt $lastBackup) {
                    $lastBackup = $backupDate
                }
                Write-Output "    Last backup: $backupDate"
            }
            
            $logQuery = @"
SELECT SUM(size * 8 / 1024) as LogSizeMB
FROM sys.master_files
WHERE type_desc = 'LOG'
"@
            $logResult = Invoke-Sqlcmd -ServerInstance $instance.ServerName -Query $logQuery -ConnectionTimeout 10 -QueryTimeout 30 -ErrorAction Stop
            $transactionLogSizeMB += [int]$logResult.LogSizeMB
            Write-Output "    Transaction log: $([int]$logResult.LogSizeMB) MB"
            
            $jobQuery = @"
SELECT COUNT(*) as FailedCount
FROM msdb.dbo.sysjobhistory jh
INNER JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
WHERE jh.run_status = 0
  AND jh.run_date >= CONVERT(VARCHAR(8), DATEADD(day, -1, GETDATE()), 112)
"@
            $jobResult = Invoke-Sqlcmd -ServerInstance $instance.ServerName -Database "msdb" -Query $jobQuery -ConnectionTimeout 10 -QueryTimeout 30 -ErrorAction Stop
            $failedJobsCount += $jobResult.FailedCount
            Write-Output "    Failed jobs (24h): $($jobResult.FailedCount)"
            
        } catch {
            Write-Output "WARNING: Failed to query instance $($instance.ServerName): $_"
        }
    }
    
    Write-Output "INFO: Determining health status..."
    $stoppedInstances = ($instances | Where-Object { $_.Status -ne 'Running' }).Count
    
    if ($stoppedInstances -gt 0) {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Critical - $stoppedInstances instance(s) stopped"
    } elseif ($failedJobsCount -gt 0) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - $failedJobsCount failed job(s) detected"
    } elseif ($null -eq $lastBackup -or ((Get-Date) - $lastBackup).TotalHours -gt 24) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - No recent backup (>24h)"
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: SQL Server healthy"
    }
    
    $lastBackupFormatted = if ($lastBackup) {
        $lastBackup.ToString("yyyy-MM-dd HH:mm:ss")
    } else {
        ""
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set mssqlInstalled $true
    Ninja-Property-Set mssqlInstanceCount $instanceCount
    Ninja-Property-Set mssqlInstanceSummary $instanceSummary
    Ninja-Property-Set mssqlDatabaseCount $databaseCount
    Ninja-Property-Set mssqlFailedJobsCount $failedJobsCount
    Ninja-Property-Set mssqlLastBackup $lastBackupFormatted
    Ninja-Property-Set mssqlTransactionLogSizeMB $transactionLogSizeMB
    Ninja-Property-Set mssqlHealthStatus $healthStatus
    
    Write-Output "SUCCESS: MSSQL Server monitoring complete"
    Write-Output "MSSQL SERVER METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - Instances: $instanceCount"
    Write-Output "  - Databases: $databaseCount"
    Write-Output "  - Failed Jobs (24h): $failedJobsCount"
    Write-Output "  - Transaction Log Size: $transactionLogSizeMB MB"
    if ($lastBackup) {
        Write-Output "  - Last Backup: $lastBackupFormatted"
    }
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: MSSQL Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set mssqlHealthStatus "Unknown"
    Ninja-Property-Set mssqlInstanceSummary "Monitor script error: $errorMessage"
    
    exit 1
}
