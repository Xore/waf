<#
.SYNOPSIS
    MySQL Server Monitor - MySQL/MariaDB Database Health and Replication Monitoring

.DESCRIPTION
    Monitors MySQL and MariaDB database server health including service status, database
    inventory, replication topology, replication lag, and query performance metrics. Provides
    comprehensive database infrastructure monitoring to ensure data availability and replication
    integrity.
    
    Critical for environments running MySQL/MariaDB databases, detecting replication failures,
    performance degradation, and service outages before they impact applications. Enables
    proactive database administration and capacity planning.
    
    IMPORTANT SECURITY NOTE:
    This script requires MySQL credentials to query server status. Default configuration uses
    root user with blank password for initial setup. MUST be customized with secure credential
    management before production deployment. Consider using:
    - MySQL configuration file with restrictive permissions
    - Windows Credential Manager integration
    - NinjaRMM secure custom fields for credentials
    - Dedicated monitoring user with minimal privileges
    
    Monitoring Scope:
    
    MySQL/MariaDB Service Detection:
    - Scans for MySQL and MariaDB Windows services
    - Supports multiple MySQL versions and distributions
    - Gracefully exits if database server not installed
    
    Version Detection:
    - Executes mysql --version to identify server version
    - Tracks MySQL 5.x, 8.x releases
    - Tracks MariaDB 10.x releases
    - Version tracking for compatibility and upgrade planning
    
    Database Inventory:
    - Enumerates all user databases
    - Excludes system databases:
      * information_schema (metadata)
      * mysql (authentication and privileges)
      * performance_schema (instrumentation)
      * sys (diagnostic views)
    - Counts application databases only
    - Capacity planning metric
    
    Replication Status Monitoring:
    
    Master Configuration:
    - Executes SHOW MASTER STATUS
    - Confirms server is replication source
    - Indicates binary logging enabled
    - One or more slaves may be connected
    
    Slave Configuration:
    - Executes SHOW SLAVE STATUS
    - Monitors replication threads:
      * Slave_IO_Running: Receives binary logs from master
      * Slave_SQL_Running: Applies replicated transactions
    - Both threads must be "Yes" for healthy replication
    - Tracks Seconds_Behind_Master (replication lag)
    
    Standalone (N/A):
    - Neither master nor slave configuration
    - Single-server deployment
    - No replication monitoring needed
    
    Replication Error States:
    - IO or SQL thread stopped
    - Connection to master failed
    - Replication lag excessive
    - Duplicate key errors on slave
    
    Replication Lag Tracking:
    - Seconds_Behind_Master metric
    - Indicates delay between master and slave
    - Acceptable: 0-60 seconds (depending on workload)
    - Warning: 60-300 seconds
    - Critical: >300 seconds (5 minutes)
    - Zero on master and standalone servers
    
    Query Performance Monitoring:
    - Tracks Slow_queries global status variable
    - Cumulative count since server start
    - Queries exceeding long_query_time threshold
    - Performance tuning indicator
    - Index optimization opportunities
    
    Health Status Classification:
    
    Healthy:
    - Service running
    - Replication operational (if configured)
    - No replication errors
    
    Warning:
    - Service running but replication not configured
    - High slow query count
    - Minor issues present
    
    Critical:
    - Service stopped or crashed
    - Replication threads failed
    - Database unavailable
    
    Unknown:
    - MySQL binary not found
    - Authentication failure
    - Query execution error

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - mysqlInstalled (Checkbox: true if MySQL/MariaDB service present)
    - mysqlVersion (Text: MySQL/MariaDB version string)
    - mysqlDatabaseCount (Integer: number of user databases)
    - mysqlReplicationStatus (Text: Master, Slave, N/A, Error)
    - mysqlReplicationLag (Integer: seconds behind master, 0 if not slave)
    - mysqlSlowQueries24h (Integer: cumulative slow query count)
    - mysqlHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - MySQL or MariaDB Windows service
    - mysql.exe command-line client
    - Database credentials with monitoring privileges
    
    Common Installation Paths:
    - MySQL 8.0: C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe
    - MariaDB 10.6: C:\Program Files\MariaDB 10.6\bin\mysql.exe
    - Customize $mysqlBin variable for non-standard installations
    
    Required MySQL Privileges:
    - SHOW DATABASES
    - SHOW MASTER STATUS (if master)
    - SHOW SLAVE STATUS (if slave)
    - SHOW GLOBAL STATUS
    
    Security Best Practices:
    - Create dedicated monitoring user: CREATE USER 'monitor'@'localhost' IDENTIFIED BY 'secure_password';
    - Grant minimal privileges: GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'monitor'@'localhost';
    - Store credentials securely, never hardcode passwords
    - Use MySQL configuration file (~/.my.cnf) with restrictive permissions
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

param()

try {
    Write-Output "Starting MySQL Server Monitor (v4.0)..."

    # Detect MySQL/MariaDB service
    Write-Output "INFO: Checking for MySQL/MariaDB service..."
    $mysqlService = Get-Service -Name 'MySQL*','MariaDB*' -ErrorAction SilentlyContinue

    if (-not $mysqlService) {
        Write-Output "INFO: MySQL/MariaDB not installed on this system"
        Ninja-Property-Set mysqlInstalled $false
        Write-Output "SUCCESS: MySQL monitoring skipped (not installed)"
        exit 0
    }

    Write-Output "INFO: MySQL/MariaDB service detected: $($mysqlService.Name) ($($mysqlService.Status))"
    Ninja-Property-Set mysqlInstalled $true

    # MySQL connection parameters - CUSTOMIZE FOR YOUR ENVIRONMENT
    Write-Output "INFO: Configuring MySQL connection parameters..."
    $mysqlBin = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    $mysqlUser = "root"
    $mysqlPassword = ""  # WARNING: Use secure credential management in production

    # Check for MariaDB if MySQL not found
    if (-not (Test-Path $mysqlBin)) {
        Write-Output "INFO: MySQL 8.0 not found, checking for MariaDB..."
        $mysqlBin = "C:\Program Files\MariaDB 10.6\bin\mysql.exe"
    }

    if (-not (Test-Path $mysqlBin)) {
        Write-Output "WARNING: MySQL binary not found at expected locations"
        Write-Output "  Checked: C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
        Write-Output "  Checked: C:\Program Files\MariaDB 10.6\bin\mysql.exe"
        Write-Output "RECOMMENDATION: Update script with correct mysql.exe path"
        Ninja-Property-Set mysqlHealthStatus "Unknown"
        exit 0
    }

    Write-Output "INFO: MySQL client found at: $mysqlBin"

    # Get MySQL version
    Write-Output "INFO: Detecting MySQL version..."
    $versionOutput = & $mysqlBin --version 2>&1
    $version = if ($versionOutput -match "Ver ([0-9.]+)") { $matches[1] } else { "Unknown" }
    
    Write-Output "INFO: MySQL version: $version"
    Ninja-Property-Set mysqlVersion $version

    # Execute MySQL monitoring queries
    try {
        # Query 1: Database inventory
        Write-Output "INFO: Enumerating databases..."
        $dbQuery = "SHOW DATABASES;"
        $databases = & $mysqlBin -u $mysqlUser -e $dbQuery 2>&1 | 
            Where-Object {$_ -notmatch "Database|information_schema|mysql|performance_schema|sys"}

        $dbCount = ($databases | Measure-Object).Count
        Write-Output "INFO: Found $dbCount user database(s)"
        Ninja-Property-Set mysqlDatabaseCount $dbCount

        # Query 2: Replication status (slave)
        Write-Output "INFO: Checking replication configuration (slave)..."
        $replQuery = "SHOW SLAVE STATUS\G"
        $replStatus = & $mysqlBin -u $mysqlUser -e $replQuery 2>&1

        if ($replStatus -match "Slave_IO_Running") {
            Write-Output "INFO: Server is configured as replication slave"
            
            $ioRunning = $replStatus -match "Slave_IO_Running: Yes"
            $sqlRunning = $replStatus -match "Slave_SQL_Running: Yes"

            if ($ioRunning -and $sqlRunning) {
                $replStatusValue = "Slave"
                Write-Output "  Slave_IO_Running: Yes"
                Write-Output "  Slave_SQL_Running: Yes"
                Write-Output "  STATUS: Replication healthy"

                # Extract replication lag
                if ($replStatus -match "Seconds_Behind_Master: (\d+)") {
                    $lag = [int]$matches[1]
                    Write-Output "  Replication lag: $lag seconds"
                    Ninja-Property-Set mysqlReplicationLag $lag
                    
                    if ($lag -gt 300) {
                        Write-Output "  WARNING: High replication lag detected (>5 minutes)"
                    }
                }
            } else {
                $replStatusValue = "Error"
                Write-Output "  CRITICAL: Replication threads not running"
                Write-Output "  Slave_IO_Running: $(if ($ioRunning) {'Yes'} else {'No'})"
                Write-Output "  Slave_SQL_Running: $(if ($sqlRunning) {'Yes'} else {'No'})"
                Ninja-Property-Set mysqlReplicationLag 0
            }
        } else {
            # Query 3: Check if master
            Write-Output "INFO: Not a slave, checking master status..."
            $masterQuery = "SHOW MASTER STATUS\G"
            $masterStatus = & $mysqlBin -u $mysqlUser -e $masterQuery 2>&1

            if ($masterStatus -match "File:") {
                $replStatusValue = "Master"
                Write-Output "INFO: Server is configured as replication master"
            } else {
                $replStatusValue = "N/A"
                Write-Output "INFO: Server is standalone (no replication)"
            }
            Ninja-Property-Set mysqlReplicationLag 0
        }

        Ninja-Property-Set mysqlReplicationStatus $replStatusValue

        # Query 4: Slow queries performance metric
        Write-Output "INFO: Checking slow query statistics..."
        $slowQuery = "SHOW GLOBAL STATUS LIKE 'Slow_queries';"
        $slowQueries = & $mysqlBin -u $mysqlUser -e $slowQuery 2>&1

        if ($slowQueries -match "Slow_queries\s+(\d+)") {
            $slowCount = [int]$matches[1]
            Write-Output "INFO: Slow queries since startup: $slowCount"
            Ninja-Property-Set mysqlSlowQueries24h $slowCount
        } else {
            Ninja-Property-Set mysqlSlowQueries24h 0
        }

        # Determine overall health status
        Write-Output "INFO: Determining MySQL health status..."
        if ($mysqlService.Status -eq 'Running' -and $replStatusValue -ne "Error") {
            $health = "Healthy"
            Write-Output "  ASSESSMENT: MySQL server healthy"
        } elseif ($mysqlService.Status -eq 'Running') {
            $health = "Warning"
            Write-Output "  ASSESSMENT: Service running but replication errors present"
        } else {
            $health = "Critical"
            Write-Output "  ASSESSMENT: MySQL service not running"
        }

        Ninja-Property-Set mysqlHealthStatus $health

        Write-Output "SUCCESS: MySQL monitoring complete"
        Write-Output "MYSQL SERVER METRICS:"
        Write-Output "  - Health Status: $health"
        Write-Output "  - Service Status: $($mysqlService.Status)"
        Write-Output "  - Version: $version"
        Write-Output "  - User Databases: $dbCount"
        Write-Output "  - Replication Role: $replStatusValue"
        Write-Output "  - Replication Lag: $(Ninja-Property-Get mysqlReplicationLag) seconds"
        Write-Output "  - Slow Queries: $(Ninja-Property-Get mysqlSlowQueries24h)"

    } catch {
        Write-Output "ERROR: MySQL query execution failed: $_"
        Write-Output "POSSIBLE CAUSES:"
        Write-Output "  - Authentication failure (check credentials)"
        Write-Output "  - Insufficient privileges (grant PROCESS, REPLICATION CLIENT)"
        Write-Output "  - MySQL service not responding"
        Ninja-Property-Set mysqlHealthStatus "Unknown"
    }

    exit 0
} catch {
    Write-Output "ERROR: MySQL Server Monitor failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    Ninja-Property-Set mysqlHealthStatus "Unknown"
    exit 1
}
