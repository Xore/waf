<#
.SYNOPSIS
    Script 39: MySQL/MariaDB Server Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors MySQL and MariaDB server instances including database health, replication status,
    slow queries, and overall server health. Updates 7 MYSQL custom fields.

.FIELDS UPDATED
    - MYSQLInstalled (Checkbox)
    - MYSQLVersion (Text)
    - MYSQLDatabaseCount (Integer)
    - MYSQLReplicationStatus (Text)
    - MYSQLReplicationLag (Integer)
    - MYSQLSlowQueries24h (Integer)
    - MYSQLHealthStatus (Text)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Requires: MySQL/MariaDB installed, credentials configured

.NOTES
    File: Script_39_MySQL_Server_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Database Monitoring
    Dependencies: MySQL command-line client (mysql.exe) in PATH
    Credentials: Use NinjaRMM secure custom fields for MySQL credentials

.RELATED DOCUMENTATION
    - docs/core/12_ROLE_Database_Web.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 1)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting MySQL/MariaDB Server Monitor (Script 39)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $mysqlInstalled = $false
    $mysqlVersion = "Not Installed"
    $databaseCount = 0
    $replicationStatus = "N/A"
    $replicationLag = 0
    $slowQueries24h = 0
    $healthStatus = "Unknown"
    
    # Check if MySQL/MariaDB is installed
    Write-Host "Checking MySQL/MariaDB installation..."
    
    # Check for MySQL service
    $mysqlService = Get-Service -Name "MySQL*", "MariaDB" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $mysqlService) {
        Write-Host "MySQL/MariaDB is not installed on this system."
        
        # Update NinjaRMM fields for non-MySQL systems
        Ninja-Property-Set mysqlInstalled $false
        Ninja-Property-Set mysqlVersion "Not Installed"
        Ninja-Property-Set mysqlDatabaseCount 0
        Ninja-Property-Set mysqlReplicationStatus "N/A"
        Ninja-Property-Set mysqlReplicationLag 0
        Ninja-Property-Set mysqlSlowQueries24h 0
        Ninja-Property-Set mysqlHealthStatus "Unknown"
        
        Write-Host "MySQL Monitor complete (not installed)."
        exit 0
    }
    
    $mysqlInstalled = $true
    Write-Host "MySQL/MariaDB is installed. Service: $($mysqlService.DisplayName), Status: $($mysqlService.Status)"
    
    # Find mysql.exe client
    $mysqlExe = $null
    $searchPaths = @(
        "C:\Program Files\MySQL\MySQL Server*\bin\mysql.exe",
        "C:\Program Files\MariaDB*\bin\mysql.exe",
        "C:\MySQL\bin\mysql.exe",
        "C:\xampp\mysql\bin\mysql.exe"
    )
    
    foreach ($path in $searchPaths) {
        $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $mysqlExe = $found.FullName
            Write-Host "Found MySQL client: $mysqlExe"
            break
        }
    }
    
    if ($null -eq $mysqlExe) {
        # Try PATH
        $mysqlExe = (Get-Command mysql.exe -ErrorAction SilentlyContinue).Source
        if ($mysqlExe) {
            Write-Host "Found MySQL client in PATH: $mysqlExe"
        }
    }
    
    if ($null -eq $mysqlExe) {
        Write-Warning "MySQL client (mysql.exe) not found. Cannot query database."
        
        Ninja-Property-Set mysqlInstalled $true
        Ninja-Property-Set mysqlVersion "Unknown (client not found)"
        Ninja-Property-Set mysqlHealthStatus "Warning"
        
        exit 0
    }
    
    # Get MySQL credentials from NinjaRMM custom fields (if configured)
    # For security, these should be stored as secure custom fields
    $mysqlUser = "root"  # Default, should be configured per environment
    $mysqlPassword = ""  # Should use secure field: Ninja-Property-Get mysqlPassword
    $mysqlHost = "localhost"
    $mysqlPort = 3306
    
    # Build connection string
    $connArgs = @(
        "--host=$mysqlHost",
        "--port=$mysqlPort",
        "--user=$mysqlUser"
    )
    
    if ($mysqlPassword) {
        $connArgs += "--password=$mysqlPassword"
    }
    
    # Add options for batch/silent mode
    $connArgs += @(
        "--batch",
        "--skip-column-names",
        "--connect-timeout=10"
    )
    
    # Get MySQL version
    try {
        $versionQuery = "SELECT VERSION();"
        $versionArgs = $connArgs + @("-e", $versionQuery)
        $versionOutput = & $mysqlExe $versionArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $versionOutput) {
            $mysqlVersion = ($versionOutput -split "`n")[0].Trim()
            Write-Host "MySQL Version: $mysqlVersion"
        } else {
            throw "Version query failed: $versionOutput"
        }
    } catch {
        Write-Warning "Failed to get MySQL version: $_"
        $mysqlVersion = "Unknown"
    }
    
    # Get database count
    try {
        $dbQuery = "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys');"
        $dbArgs = $connArgs + @("-e", $dbQuery)
        $dbOutput = & $mysqlExe $dbArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $dbOutput) {
            $databaseCount = [int]($dbOutput -split "`n")[0].Trim()
            Write-Host "Database Count: $databaseCount"
        }
    } catch {
        Write-Warning "Failed to get database count: $_"
    }
    
    # Check replication status
    try {
        $slaveQuery = "SHOW SLAVE STATUS\\G"
        $slaveArgs = $connArgs + @("-e", $slaveQuery)
        $slaveOutput = & $mysqlExe $slaveArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $slaveOutput -match "Slave_IO_Running") {
            # This is a slave/replica
            $ioRunning = ($slaveOutput | Select-String "Slave_IO_Running: (\w+)").Matches.Groups[1].Value
            $sqlRunning = ($slaveOutput | Select-String "Slave_SQL_Running: (\w+)").Matches.Groups[1].Value
            
            if ($ioRunning -eq "Yes" -and $sqlRunning -eq "Yes") {
                $replicationStatus = "Slave"
            } else {
                $replicationStatus = "Error"
            }
            
            # Get replication lag
            $lagMatch = $slaveOutput | Select-String "Seconds_Behind_Master: (\d+|NULL)"
            if ($lagMatch) {
                $lagValue = $lagMatch.Matches.Groups[1].Value
                $replicationLag = if ($lagValue -eq "NULL") { 0 } else { [int]$lagValue }
            }
            
            Write-Host "Replication Status: $replicationStatus, Lag: $replicationLag seconds"
        } else {
            # Check if master
            $masterQuery = "SHOW MASTER STATUS\\G"
            $masterArgs = $connArgs + @("-e", $masterQuery)
            $masterOutput = & $mysqlExe $masterArgs 2>&1
            
            if ($LASTEXITCODE -eq 0 -and $masterOutput -match "File:") {
                $replicationStatus = "Master"
                Write-Host "Replication Status: Master"
            } else {
                $replicationStatus = "N/A"
            }
        }
    } catch {
        Write-Warning "Failed to check replication status: $_"
        $replicationStatus = "Unknown"
    }
    
    # Get slow query count (last 24 hours)
    try {
        $slowQueryFile = $null
        
        # Try to find slow query log file
        $slowLogQuery = "SHOW VARIABLES LIKE 'slow_query_log_file';"
        $slowLogArgs = $connArgs + @("-e", $slowLogQuery)
        $slowLogOutput = & $mysqlExe $slowLogArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $slowLogOutput) {
            $slowQueryFile = ($slowLogOutput -split "`t")[1]
        }
        
        if ($slowQueryFile -and (Test-Path $slowQueryFile)) {
            # Count lines in slow query log from last 24 hours
            $yesterday = (Get-Date).AddDays(-1)
            $recentQueries = Get-Content $slowQueryFile -ErrorAction SilentlyContinue | 
                Where-Object { $_ -match "^# Time:" -and [DateTime]::Parse($_.Substring(7)) -gt $yesterday }
            $slowQueries24h = $recentQueries.Count
            Write-Host "Slow Queries (24h): $slowQueries24h"
        } else {
            # Alternative: query from performance schema if available
            $perfQuery = "SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest WHERE SUM_TIMER_WAIT > 10000000000000;"
            $perfArgs = $connArgs + @("-e", $perfQuery)
            $perfOutput = & $mysqlExe $perfArgs 2>&1
            
            if ($LASTEXITCODE -eq 0 -and $perfOutput) {
                $slowQueries24h = [int]($perfOutput -split "`n")[0].Trim()
            }
        }
    } catch {
        Write-Warning "Failed to get slow query count: $_"
    }
    
    # Determine health status
    if ($mysqlService.Status -ne 'Running') {
        $healthStatus = "Critical"
    } elseif ($replicationStatus -eq "Error") {
        $healthStatus = "Critical"
    } elseif ($slowQueries24h -gt 1000 -or $replicationLag -gt 300) {
        $healthStatus = "Warning"
    } else {
        $healthStatus = "Healthy"
    }
    
    Write-Host "Overall Health Status: $healthStatus"
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set mysqlInstalled $true
    Ninja-Property-Set mysqlVersion $mysqlVersion
    Ninja-Property-Set mysqlDatabaseCount $databaseCount
    Ninja-Property-Set mysqlReplicationStatus $replicationStatus
    Ninja-Property-Set mysqlReplicationLag $replicationLag
    Ninja-Property-Set mysqlSlowQueries24h $slowQueries24h
    Ninja-Property-Set mysqlHealthStatus $healthStatus
    
    Write-Host "MySQL/MariaDB Server Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "MySQL Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set mysqlHealthStatus "Unknown"
    
    exit 1
}
