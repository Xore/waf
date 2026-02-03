<#
.SYNOPSIS
    NinjaRMM Script 11: MySQL Server Monitor

.DESCRIPTION
    Monitors MySQL/MariaDB database server health.
    Tracks databases, replication status, and query performance.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - mysqlInstalled (Checkbox)
    - mysqlVersion (Text)
    - mysqlDatabaseCount (Integer)
    - mysqlReplicationStatus (Text)
    - mysqlReplicationLag (Integer)
    - mysqlSlowQueries24h (Integer)
    - mysqlHealthStatus (Text)
    
    Framework Version: 4.0
    Last Updated: February 3, 2026
    
    IMPORTANT: Configure MySQL connection parameters before deployment
#>

param()

try {
    # Check if MySQL service is running
    $mysqlService = Get-Service -Name 'MySQL*','MariaDB*' -ErrorAction SilentlyContinue

    if (-not $mysqlService) {
        Ninja-Property-Set mysqlInstalled $false
        Write-Output "MySQL/MariaDB not installed"
        exit 0
    }

    Ninja-Property-Set mysqlInstalled $true

    # MySQL connection parameters (customize as needed)
    $mysqlBin = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    $mysqlUser = "root"
    $mysqlPassword = ""  # Use secure credential management in production

    # Alternative: Check for MariaDB
    if (-not (Test-Path $mysqlBin)) {
        $mysqlBin = "C:\Program Files\MariaDB 10.6\bin\mysql.exe"
    }

    if (-not (Test-Path $mysqlBin)) {
        Write-Output "MySQL binary not found at expected location"
        Ninja-Property-Set mysqlHealthStatus "Unknown"
        exit 0
    }

    # Get MySQL version
    $versionOutput = & $mysqlBin --version 2>&1
    $version = if ($versionOutput -match "Ver ([0-9.]+)") { $matches[1] } else { "Unknown" }

    Ninja-Property-Set mysqlVersion $version

    # Execute MySQL queries
    try {
        # Get database count
        $dbQuery = "SHOW DATABASES;"
        $databases = & $mysqlBin -u $mysqlUser -e $dbQuery 2>&1 | 
            Where-Object {$_ -notmatch "Database|information_schema|mysql|performance_schema|sys"}

        $dbCount = ($databases | Measure-Object).Count
        Ninja-Property-Set mysqlDatabaseCount $dbCount

        # Check replication status
        $replQuery = "SHOW SLAVE STATUS\G"
        $replStatus = & $mysqlBin -u $mysqlUser -e $replQuery 2>&1

        if ($replStatus -match "Slave_IO_Running") {
            # This is a slave
            $ioRunning = $replStatus -match "Slave_IO_Running: Yes"
            $sqlRunning = $replStatus -match "Slave_SQL_Running: Yes"

            if ($ioRunning -and $sqlRunning) {
                $replStatusValue = "Slave"

                # Get seconds behind master
                if ($replStatus -match "Seconds_Behind_Master: (\d+)") {
                    $lag = [int]$matches[1]
                    Ninja-Property-Set mysqlReplicationLag $lag
                }
            } else {
                $replStatusValue = "Error"
                Ninja-Property-Set mysqlReplicationLag 0
            }
        } else {
            # Check if master
            $masterQuery = "SHOW MASTER STATUS\G"
            $masterStatus = & $mysqlBin -u $mysqlUser -e $masterQuery 2>&1

            if ($masterStatus -match "File:") {
                $replStatusValue = "Master"
            } else {
                $replStatusValue = "N/A"
            }
            Ninja-Property-Set mysqlReplicationLag 0
        }

        Ninja-Property-Set mysqlReplicationStatus $replStatusValue

        # Get slow queries
        $slowQuery = "SHOW GLOBAL STATUS LIKE 'Slow_queries';"
        $slowQueries = & $mysqlBin -u $mysqlUser -e $slowQuery 2>&1

        if ($slowQueries -match "Slow_queries\s+(\d+)") {
            $slowCount = [int]$matches[1]
            Ninja-Property-Set mysqlSlowQueries24h $slowCount
        }

        # Determine health status
        if ($mysqlService.Status -eq 'Running' -and $replStatusValue -ne "Error") {
            $health = "Healthy"
        } elseif ($mysqlService.Status -eq 'Running') {
            $health = "Warning"
        } else {
            $health = "Critical"
        }

        Ninja-Property-Set mysqlHealthStatus $health

        Write-Output "MySQL Health: $health | Version: $version | DBs: $dbCount | Replication: $replStatusValue"

    } catch {
        Write-Output "MySQL query error: $_"
        Ninja-Property-Set mysqlHealthStatus "Unknown"
    }

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set mysqlHealthStatus "Unknown"
    exit 1
}
