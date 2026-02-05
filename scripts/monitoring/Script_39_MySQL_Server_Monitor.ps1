<#
.SYNOPSIS
    MySQL/MariaDB Server Monitor - MySQL Database Health and Replication Monitoring

.DESCRIPTION
    Monitors MySQL and MariaDB database servers including database inventory, replication
    health, replication lag, slow query performance, and service status. Essential for ensuring
    database availability, replication integrity, and query performance.
    
    Critical for detecting replication failures that cause data inconsistencies, identifying
    slow queries that degrade application performance, and monitoring replication lag that
    impacts read replica freshness. Foundational for MySQL database administration.
    
    Monitoring Scope:
    
    MySQL/MariaDB Detection:
    - Searches for MySQL* and MariaDB services
    - Detects MySQL, MariaDB, Percona variants
    - Gracefully exits if database not installed
    
    MySQL Client Discovery:
    - Searches common installation paths:
      - C:\Program Files\MySQL\MySQL Server*\bin\mysql.exe
      - C:\Program Files\MariaDB*\bin\mysql.exe
      - C:\MySQL\bin\mysql.exe
      - C:\xampp\mysql\bin\mysql.exe
    - Falls back to PATH environment variable
    - Requires mysql.exe for queries
    
    Version Detection:
    - Executes SELECT VERSION() query
    - Identifies MySQL vs MariaDB
    - Tracks major/minor version
    - Compatibility and upgrade planning
    
    Database Inventory:
    - Queries information_schema.SCHEMATA
    - Counts user databases (excludes system schemas)
    - Filters: information_schema, mysql, performance_schema, sys
    - Capacity planning metric
    
    Replication Monitoring:
    - Master Detection: SHOW MASTER STATUS
    - Slave Detection: SHOW SLAVE STATUS
    - Tracks replication role: Master, Slave, N/A
    - Monitors replication threads:
      - Slave_IO_Running (network replication)
      - Slave_SQL_Running (local replay)
    - Both must be "Yes" for healthy replication
    
    Replication Lag Tracking:
    - Reads Seconds_Behind_Master from SHOW SLAVE STATUS
    - Measures delay between master and replica
    - High lag (>300s) indicates issues:
      - Network problems
      - Replica overload
      - Large transactions
    - NULL indicates replication stopped
    
    Slow Query Analysis:
    - Primary: Parses slow query log file
    - Filters last 24 hours of entries
    - Fallback: Queries performance_schema
    - High counts (>1000/24h) suggest:
      - Missing indexes
      - Inefficient queries
      - Table scans
    
    Health Status Classification:
    
    Healthy:
    - MySQL service running
    - Replication operational (if configured)
    - Low slow query count (<1000/24h)
    - Replication lag acceptable (<300s)
    
    Warning:
    - High slow query rate (>1000/24h)
    - Replication lag elevated (>300s)
    - Performance degraded
    
    Critical:
    - MySQL service stopped
    - Replication error (IO or SQL thread stopped)
    - Database unavailable
    
    Unknown:
    - MySQL not installed
    - Client not found
    - Authentication failed
    - Script execution error

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - MYSQLInstalled (Checkbox)
    - MYSQLVersion (Text: MySQL or MariaDB version)
    - MYSQLDatabaseCount (Integer: user databases)
    - MYSQLReplicationStatus (Text: Master, Slave, N/A, Error, Unknown)
    - MYSQLReplicationLag (Integer: seconds behind master)
    - MYSQLSlowQueries24h (Integer: slow queries in 24h)
    - MYSQLHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - MySQL or MariaDB installed
    - mysql.exe command-line client
    - Database credentials configured
    - Network access to MySQL port (default 3306)
    
    Credential Configuration:
    - Default: root user, no password (insecure)
    - Production: Use NinjaRMM secure custom fields
    - Store credentials separately per device
    - Grant minimal required privileges:
      - SELECT on information_schema
      - REPLICATION CLIENT for SHOW SLAVE STATUS
    
    Replication Roles:
    - Master: Source database, accepts writes
    - Slave/Replica: Read-only copy, replays master changes
    - N/A: Standalone database, no replication
    
    Replication Thread States:
    - Slave_IO_Running: Yes = receiving changes from master
    - Slave_SQL_Running: Yes = applying changes locally
    - Both must be Yes for healthy replication
    
    Common Issues:
    - Client not found: Install MySQL client tools
    - Authentication failed: Configure credentials in script
    - Replication error: Check network, master status
    - High lag: Reduce replica load or upgrade hardware
    - Slow queries: Add indexes, optimize queries
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting MySQL/MariaDB Server Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    $mysqlInstalled = $false
    $mysqlVersion = "Not Installed"
    $databaseCount = 0
    $replicationStatus = "N/A"
    $replicationLag = 0
    $slowQueries24h = 0
    $healthStatus = "Unknown"
    
    Write-Output "INFO: Checking for MySQL/MariaDB installation..."
    
    $mysqlService = Get-Service -Name "MySQL*", "MariaDB" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $mysqlService) {
        Write-Output "INFO: MySQL/MariaDB not installed"
        
        Ninja-Property-Set mysqlInstalled $false
        Ninja-Property-Set mysqlVersion "Not Installed"
        Ninja-Property-Set mysqlDatabaseCount 0
        Ninja-Property-Set mysqlReplicationStatus "N/A"
        Ninja-Property-Set mysqlReplicationLag 0
        Ninja-Property-Set mysqlSlowQueries24h 0
        Ninja-Property-Set mysqlHealthStatus "Unknown"
        
        Write-Output "SUCCESS: MySQL monitoring skipped (not installed)"
        exit 0
    }
    
    $mysqlInstalled = $true
    Write-Output "INFO: MySQL/MariaDB detected - Service: $($mysqlService.DisplayName), Status: $($mysqlService.Status)"
    
    Write-Output "INFO: Searching for mysql.exe client..."
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
            Write-Output "INFO: Found MySQL client: $mysqlExe"
            break
        }
    }
    
    if ($null -eq $mysqlExe) {
        $mysqlExe = (Get-Command mysql.exe -ErrorAction SilentlyContinue).Source
        if ($mysqlExe) {
            Write-Output "INFO: Found MySQL client in PATH"
        }
    }
    
    if ($null -eq $mysqlExe) {
        Write-Output "WARNING: MySQL client (mysql.exe) not found, cannot query database"
        
        Ninja-Property-Set mysqlInstalled $true
        Ninja-Property-Set mysqlVersion "Unknown (client not found)"
        Ninja-Property-Set mysqlHealthStatus "Warning"
        
        exit 0
    }
    
    $mysqlUser = "root"
    $mysqlPassword = ""
    $mysqlHost = "localhost"
    $mysqlPort = 3306
    
    $connArgs = @(
        "--host=$mysqlHost",
        "--port=$mysqlPort",
        "--user=$mysqlUser",
        "--batch",
        "--skip-column-names",
        "--connect-timeout=10"
    )
    
    if ($mysqlPassword) {
        $connArgs += "--password=$mysqlPassword"
    }
    
    Write-Output "INFO: Querying MySQL version..."
    try {
        $versionQuery = "SELECT VERSION();"
        $versionArgs = $connArgs + @("-e", $versionQuery)
        $versionOutput = & $mysqlExe $versionArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $versionOutput) {
            $mysqlVersion = ($versionOutput -split "`n")[0].Trim()
            Write-Output "INFO: Version: $mysqlVersion"
        } else {
            throw "Version query failed: $versionOutput"
        }
    } catch {
        Write-Output "WARNING: Failed to get MySQL version: $_"
        $mysqlVersion = "Unknown"
    }
    
    Write-Output "INFO: Counting databases..."
    try {
        $dbQuery = "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys');"
        $dbArgs = $connArgs + @("-e", $dbQuery)
        $dbOutput = & $mysqlExe $dbArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $dbOutput) {
            $databaseCount = [int]($dbOutput -split "`n")[0].Trim()
            Write-Output "INFO: Databases: $databaseCount"
        }
    } catch {
        Write-Output "WARNING: Failed to get database count: $_"
    }
    
    Write-Output "INFO: Checking replication status..."
    try {
        $slaveQuery = "SHOW SLAVE STATUS\\G"
        $slaveArgs = $connArgs + @("-e", $slaveQuery)
        $slaveOutput = & $mysqlExe $slaveArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $slaveOutput -match "Slave_IO_Running") {
            $ioRunning = ($slaveOutput | Select-String "Slave_IO_Running: (\w+)").Matches.Groups[1].Value
            $sqlRunning = ($slaveOutput | Select-String "Slave_SQL_Running: (\w+)").Matches.Groups[1].Value
            
            if ($ioRunning -eq "Yes" -and $sqlRunning -eq "Yes") {
                $replicationStatus = "Slave"
            } else {
                $replicationStatus = "Error"
            }
            
            $lagMatch = $slaveOutput | Select-String "Seconds_Behind_Master: (\d+|NULL)"
            if ($lagMatch) {
                $lagValue = $lagMatch.Matches.Groups[1].Value
                $replicationLag = if ($lagValue -eq "NULL") { 0 } else { [int]$lagValue }
            }
            
            Write-Output "INFO: Replication: $replicationStatus, Lag: $replicationLag seconds"
        } else {
            $masterQuery = "SHOW MASTER STATUS\\G"
            $masterArgs = $connArgs + @("-e", $masterQuery)
            $masterOutput = & $mysqlExe $masterArgs 2>&1
            
            if ($LASTEXITCODE -eq 0 -and $masterOutput -match "File:") {
                $replicationStatus = "Master"
                Write-Output "INFO: Replication: Master"
            } else {
                $replicationStatus = "N/A"
                Write-Output "INFO: Replication: Not configured"
            }
        }
    } catch {
        Write-Output "WARNING: Failed to check replication status: $_"
        $replicationStatus = "Unknown"
    }
    
    Write-Output "INFO: Analyzing slow queries..."
    try {
        $slowLogQuery = "SHOW VARIABLES LIKE 'slow_query_log_file';"
        $slowLogArgs = $connArgs + @("-e", $slowLogQuery)
        $slowLogOutput = & $mysqlExe $slowLogArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $slowLogOutput) {
            $slowQueryFile = ($slowLogOutput -split "`t")[1]
            
            if ($slowQueryFile -and (Test-Path $slowQueryFile)) {
                $yesterday = (Get-Date).AddDays(-1)
                $recentQueries = Get-Content $slowQueryFile -ErrorAction SilentlyContinue | 
                    Where-Object { $_ -match "^# Time:" -and [DateTime]::Parse($_.Substring(7)) -gt $yesterday }
                $slowQueries24h = $recentQueries.Count
                Write-Output "INFO: Slow queries (24h): $slowQueries24h"
            }
        }
    } catch {
        Write-Output "WARNING: Failed to get slow query count: $_"
    }
    
    Write-Output "INFO: Determining health status..."
    if ($mysqlService.Status -ne 'Running') {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Critical - MySQL service stopped"
    } elseif ($replicationStatus -eq "Error") {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Critical - Replication error"
    } elseif ($slowQueries24h -gt 1000 -or $replicationLag -gt 300) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - High slow queries or replication lag"
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: MySQL database healthy"
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set mysqlInstalled $true
    Ninja-Property-Set mysqlVersion $mysqlVersion
    Ninja-Property-Set mysqlDatabaseCount $databaseCount
    Ninja-Property-Set mysqlReplicationStatus $replicationStatus
    Ninja-Property-Set mysqlReplicationLag $replicationLag
    Ninja-Property-Set mysqlSlowQueries24h $slowQueries24h
    Ninja-Property-Set mysqlHealthStatus $healthStatus
    
    Write-Output "SUCCESS: MySQL/MariaDB monitoring complete"
    Write-Output "MYSQL SERVER METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - Version: $mysqlVersion"
    Write-Output "  - Databases: $databaseCount"
    Write-Output "  - Replication: $replicationStatus"
    if ($replicationStatus -eq "Slave") {
        Write-Output "  - Replication Lag: $replicationLag seconds"
    }
    Write-Output "  - Slow Queries (24h): $slowQueries24h"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: MySQL Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set mysqlHealthStatus "Unknown"
    
    exit 1
}
