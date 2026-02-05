<#
.SYNOPSIS
    MySQL Server Monitor - MySQL/MariaDB Database Health and Replication Monitoring

.DESCRIPTION
    Monitors MySQL and MariaDB database server health including service status, database
    inventory, replication topology, replication lag, and query performance metrics.
    
    Alternative implementation to 11_MySQL_Server_Monitor.ps1 for different deployment patterns.
    
    SECURITY NOTE: Requires MySQL credentials. Use secure credential management in production.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - mysqlInstalled (Checkbox)
    - mysqlVersion (Text)
    - mysqlDatabaseCount (Integer)
    - mysqlReplicationStatus (Dropdown: Master, Slave, N/A, Error)
    - mysqlReplicationLag (Integer: seconds)
    - mysqlSlowQueries24h (Integer)
    - mysqlHealthStatus (Dropdown: Healthy, Warning, Critical, Unknown)
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

param()

try {
    Write-Output "Starting MySQL Server Monitor (v4.0 - Script 19)..."

    Write-Output "INFO: Checking for MySQL/MariaDB service..."
    $mysqlService = Get-Service -Name 'MySQL*','MariaDB*' -ErrorAction SilentlyContinue

    if (-not $mysqlService) {
        Write-Output "INFO: MySQL/MariaDB not installed"
        Ninja-Property-Set mysqlInstalled $false
        exit 0
    }

    Write-Output "INFO: Service detected: $($mysqlService.Name) ($($mysqlService.Status))"
    Ninja-Property-Set mysqlInstalled $true

    $mysqlBin = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    $mysqlUser = "root"
    $mysqlPassword = ""  # Use secure credential management

    if (-not (Test-Path $mysqlBin)) {
        $mysqlBin = "C:\Program Files\MariaDB 10.6\bin\mysql.exe"
    }

    if (-not (Test-Path $mysqlBin)) {
        Write-Output "WARNING: MySQL binary not found"
        Ninja-Property-Set mysqlHealthStatus "Unknown"
        exit 0
    }

    Write-Output "INFO: Detecting version..."
    $versionOutput = & $mysqlBin --version 2>&1
    $version = if ($versionOutput -match "Ver ([0-9.]+)") { $matches[1] } else { "Unknown" }
    
    Write-Output "INFO: Version: $version"
    Ninja-Property-Set mysqlVersion $version

    try {
        Write-Output "INFO: Querying databases..."
        $dbQuery = "SHOW DATABASES;"
        $databases = & $mysqlBin -u $mysqlUser -e $dbQuery 2>&1 | 
            Where-Object {$_ -notmatch "Database|information_schema|mysql|performance_schema|sys"}

        $dbCount = ($databases | Measure-Object).Count
        Write-Output "INFO: Found $dbCount user database(s)"
        Ninja-Property-Set mysqlDatabaseCount $dbCount

        Write-Output "INFO: Checking replication status..."
        $replQuery = "SHOW SLAVE STATUS\G"
        $replStatus = & $mysqlBin -u $mysqlUser -e $replQuery 2>&1

        if ($replStatus -match "Slave_IO_Running") {
            $ioRunning = $replStatus -match "Slave_IO_Running: Yes"
            $sqlRunning = $replStatus -match "Slave_SQL_Running: Yes"

            if ($ioRunning -and $sqlRunning) {
                $replStatusValue = "Slave"
                Write-Output "  Replication: Slave (healthy)"

                if ($replStatus -match "Seconds_Behind_Master: (\d+)") {
                    $lag = [int]$matches[1]
                    Write-Output "  Lag: $lag seconds"
                    Ninja-Property-Set mysqlReplicationLag $lag
                }
            } else {
                $replStatusValue = "Error"
                Write-Output "  CRITICAL: Replication threads failed"
                Ninja-Property-Set mysqlReplicationLag 0
            }
        } else {
            $masterQuery = "SHOW MASTER STATUS\G"
            $masterStatus = & $mysqlBin -u $mysqlUser -e $masterQuery 2>&1

            if ($masterStatus -match "File:") {
                $replStatusValue = "Master"
                Write-Output "  Replication: Master"
            } else {
                $replStatusValue = "N/A"
                Write-Output "  Replication: Standalone"
            }
            Ninja-Property-Set mysqlReplicationLag 0
        }

        Ninja-Property-Set mysqlReplicationStatus $replStatusValue

        Write-Output "INFO: Checking slow queries..."
        $slowQuery = "SHOW GLOBAL STATUS LIKE 'Slow_queries';"
        $slowQueries = & $mysqlBin -u $mysqlUser -e $slowQuery 2>&1

        if ($slowQueries -match "Slow_queries\s+(\d+)") {
            $slowCount = [int]$matches[1]
            Write-Output "INFO: Slow queries: $slowCount"
            Ninja-Property-Set mysqlSlowQueries24h $slowCount
        }

        if ($mysqlService.Status -eq 'Running' -and $replStatusValue -ne "Error") {
            $health = "Healthy"
        } elseif ($mysqlService.Status -eq 'Running') {
            $health = "Warning"
        } else {
            $health = "Critical"
        }

        Ninja-Property-Set mysqlHealthStatus $health

        Write-Output "SUCCESS: MySQL Health: $health | Version: $version | DBs: $dbCount | Replication: $replStatusValue"

    } catch {
        Write-Output "ERROR: MySQL query failed: $_"
        Ninja-Property-Set mysqlHealthStatus "Unknown"
    }

    exit 0
} catch {
    Write-Output "ERROR: $_"
    Write-Output "$($_.ScriptStackTrace)"
    Ninja-Property-Set mysqlHealthStatus "Unknown"
    exit 1
}
