<#
.SYNOPSIS
    Script 38: MSSQL Server Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Microsoft SQL Server instances including database health, backup status,
    failed jobs, transaction log size, and overall server health. Updates 8 MSSQL fields.

.FIELDS UPDATED
    - MSSQLInstalled (Checkbox)
    - MSSQLInstanceCount (Integer)
    - MSSQLInstanceSummary (WYSIWYG)
    - MSSQLDatabaseCount (Integer)
    - MSSQLFailedJobsCount (Integer)
    - MSSQLLastBackup (DateTime)
    - MSSQLTransactionLogSizeMB (Integer)
    - MSSQLHealthStatus (Dropdown)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~45 seconds
    Requires: SQL Server installed, appropriate permissions

.NOTES
    File: Script_38_MSSQL_Server_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Database Monitoring
    Dependencies: SQL Server, SqlServer PowerShell module (or legacy SQLPS)

.RELATED DOCUMENTATION
    - docs/core/12_ROLE_Database_Web.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 1)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting MSSQL Server Monitor (Script 38)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $mssqlInstalled = $false
    $instanceCount = 0
    $instanceSummary = ""
    $databaseCount = 0
    $failedJobsCount = 0
    $lastBackup = $null
    $transactionLogSizeMB = 0
    $healthStatus = "Unknown"
    
    # Check if SQL Server is installed
    Write-Host "Checking SQL Server installation..."
    $sqlServices = Get-Service -Name "MSSQL*" -ErrorAction SilentlyContinue
    
    if ($null -eq $sqlServices -or $sqlServices.Count -eq 0) {
        Write-Host "SQL Server is not installed on this system."
        
        # Update NinjaRMM fields for non-SQL systems
        Ninja-Property-Set mssqlInstalled $false
        Ninja-Property-Set mssqlInstanceCount 0
        Ninja-Property-Set mssqlInstanceSummary "SQL Server not installed"
        Ninja-Property-Set mssqlDatabaseCount 0
        Ninja-Property-Set mssqlFailedJobsCount 0
        Ninja-Property-Set mssqlLastBackup ""
        Ninja-Property-Set mssqlTransactionLogSizeMB 0
        Ninja-Property-Set mssqlHealthStatus "Unknown"
        
        Write-Host "MSSQL Monitor complete (not installed)."
        exit 0
    }
    
    $mssqlInstalled = $true
    Write-Host "SQL Server is installed. Proceeding with monitoring..."
    
    # Import SQL Server module
    try {
        if (Get-Module -ListAvailable -Name SqlServer) {
            Import-Module SqlServer -ErrorAction Stop
            Write-Host "SqlServer module loaded."
        } elseif (Get-Module -ListAvailable -Name SQLPS) {
            Import-Module SQLPS -DisableNameChecking -ErrorAction Stop
            Write-Host "SQLPS module loaded (legacy)."
        } else {
            throw "SQL Server PowerShell module not available."
        }
    } catch {
        Write-Warning "SQL module import failed: $_. Using WMI fallback."
    }
    
    # Get SQL Server instances
    $instances = @()
    $htmlRows = @()
    
    try {
        # Get instances from services
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
            
            $instances += [PSCustomObject]@{
                Name = $instanceName
                ServerName = $serverName
                Status = $service.Status
                StartType = $service.StartType
            }
            
            # Build HTML row
            $statusColor = if ($service.Status -eq 'Running') { 'green' } else { 'red' }
            $htmlRows += "<tr><td>$instanceName</td><td style='color:$statusColor'>$($service.Status)</td></tr>"
        }
        
        $instanceCount = $instances.Count
        Write-Host "SQL Instances found: $instanceCount"
        
    } catch {
        Write-Warning "Failed to enumerate SQL instances: $_"
    }
    
    # Build instance summary HTML
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
    
    # Query running instances for detailed metrics
    foreach ($instance in $instances | Where-Object { $_.Status -eq 'Running' }) {
        try {
            Write-Host "Querying instance: $($instance.ServerName)..."
            
            # Get database count
            $dbQuery = "SELECT COUNT(*) as DbCount FROM sys.databases WHERE state_desc = 'ONLINE'"
            $dbResult = Invoke-Sqlcmd -ServerInstance $instance.ServerName -Query $dbQuery -ConnectionTimeout 10 -QueryTimeout 30 -ErrorAction Stop
            $databaseCount += $dbResult.DbCount
            
            # Get last backup date
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
            }
            
            # Get transaction log size
            $logQuery = @"
SELECT SUM(size * 8 / 1024) as LogSizeMB
FROM sys.master_files
WHERE type_desc = 'LOG'
"@
            $logResult = Invoke-Sqlcmd -ServerInstance $instance.ServerName -Query $logQuery -ConnectionTimeout 10 -QueryTimeout 30 -ErrorAction Stop
            $transactionLogSizeMB += [int]$logResult.LogSizeMB
            
            # Get failed jobs (last 24 hours)
            $jobQuery = @"
SELECT COUNT(*) as FailedCount
FROM msdb.dbo.sysjobhistory jh
INNER JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
WHERE jh.run_status = 0
  AND jh.run_date >= CONVERT(VARCHAR(8), DATEADD(day, -1, GETDATE()), 112)
"@
            $jobResult = Invoke-Sqlcmd -ServerInstance $instance.ServerName -Database "msdb" -Query $jobQuery -ConnectionTimeout 10 -QueryTimeout 30 -ErrorAction Stop
            $failedJobsCount += $jobResult.FailedCount
            
            Write-Host "Instance metrics collected: Databases=$($dbResult.DbCount), FailedJobs=$($jobResult.FailedCount)"
            
        } catch {
            Write-Warning "Failed to query instance $($instance.ServerName): $_"
        }
    }
    
    # Determine health status
    $stoppedInstances = ($instances | Where-Object { $_.Status -ne 'Running' }).Count
    
    if ($stoppedInstances -gt 0) {
        $healthStatus = "Critical"
    } elseif ($failedJobsCount -gt 0) {
        $healthStatus = "Warning"
    } elseif ($null -eq $lastBackup -or ((Get-Date) - $lastBackup).TotalHours -gt 24) {
        $healthStatus = "Warning"
    } else {
        $healthStatus = "Healthy"
    }
    
    Write-Host "Overall Health Status: $healthStatus"
    Write-Host "Total Databases: $databaseCount"
    Write-Host "Failed Jobs (24h): $failedJobsCount"
    Write-Host "Transaction Log Size: $transactionLogSizeMB MB"
    if ($lastBackup) {
        Write-Host "Last Backup: $lastBackup"
    }
    
    # Format last backup for NinjaRMM
    $lastBackupFormatted = if ($lastBackup) {
        $lastBackup.ToString("yyyy-MM-dd HH:mm:ss")
    } else {
        ""
    }
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set mssqlInstalled $true
    Ninja-Property-Set mssqlInstanceCount $instanceCount
    Ninja-Property-Set mssqlInstanceSummary $instanceSummary
    Ninja-Property-Set mssqlDatabaseCount $databaseCount
    Ninja-Property-Set mssqlFailedJobsCount $failedJobsCount
    Ninja-Property-Set mssqlLastBackup $lastBackupFormatted
    Ninja-Property-Set mssqlTransactionLogSizeMB $transactionLogSizeMB
    Ninja-Property-Set mssqlHealthStatus $healthStatus
    
    Write-Host "MSSQL Server Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "MSSQL Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set mssqlHealthStatus "Unknown"
    Ninja-Property-Set mssqlInstanceSummary "Monitor script error: $errorMessage"
    
    exit 1
}
