<#
.SYNOPSIS
    Apache Web Server Monitor - Apache HTTP Server Health and Performance Monitoring

.DESCRIPTION
    Monitors Apache HTTP Server infrastructure including virtual host configuration, request
    throughput, error rates, worker process health, and overall server status. Provides
    comprehensive Apache monitoring to ensure web service availability and performance.
    
    Critical for environments running Apache as primary web server, detecting configuration
    issues, performance degradation, and service failures before they impact users. Enables
    proactive Apache administration and capacity planning.
    
    Monitoring Scope:
    
    Apache Installation Detection:
    - Searches common installation paths:
      * C:\Apache24\bin\httpd.exe (standard Windows installation)
      * C:\Apache22\bin\httpd.exe (legacy version)
      * C:\Program Files\Apache Group\Apache2\bin\httpd.exe
      * C:\xampp\apache\bin\httpd.exe (XAMPP bundle)
    - Checks system PATH for httpd.exe
    - Detects Apache Windows services
    - Gracefully exits if Apache not installed
    
    Version Detection:
    - Executes httpd -v to identify Apache version
    - Tracks Apache 2.2.x, 2.4.x releases
    - Version information for security patch tracking
    
    Virtual Host Inventory:
    - Executes httpd -S to enumerate virtual hosts
    - Counts configured vhosts across all ports
    - Tracks multi-tenant web hosting configurations
    - Capacity planning metric
    
    Worker Process Monitoring:
    - Counts active httpd.exe processes
    - Indicates server load and concurrency
    - Zero workers = service not running (critical)
    - Process pool health assessment
    
    Request Performance Tracking:
    - Queries mod_status (if enabled) at /server-status?auto
    - Parses ReqPerSec metric
    - Throughput monitoring for capacity planning
    - Requires mod_status module and configuration
    
    Error Rate Monitoring:
    - Reads Apache error.log (last 1000 lines)
    - Counts [error] and [crit] severity entries
    - Estimates 24-hour error count
    - High error rates indicate application or configuration issues
    
    Health Status Classification:
    
    Healthy:
    - Apache service running
    - Worker processes active
    - Error count acceptable (<100/24h)
    
    Warning:
    - Service running but high error rate (>100/24h)
    - Performance degraded
    
    Critical:
    - Apache service stopped
    - No worker processes detected
    - Server unavailable
    
    Unknown:
    - Script execution error
    - Apache not installed
    - Insufficient permissions

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - APACHEInstalled (Checkbox: true if Apache detected)
    - APACHEVersion (Text: Apache version string)
    - APACHEVHostCount (Integer: configured virtual hosts)
    - APACHERequestsPerSec (Integer: current request rate)
    - APACHEErrorCount24h (Integer: estimated error count)
    - APACHEWorkerProcesses (Integer: active httpd processes)
    - APACHEHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - Apache HTTP Server (httpd.exe)
    - Optional: mod_status module for request metrics
    - Read access to Apache error.log
    
    Common Installation Paths:
    - Standard: C:\Apache24
    - XAMPP: C:\xampp\apache
    - Legacy: C:\Apache22
    - Custom: Check PATH environment variable
    
    mod_status Configuration:
    - Enable in httpd.conf: LoadModule status_module modules/mod_status.so
    - Configure access: <Location "/server-status">
    - Requires localhost access permission
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting Apache Web Server Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $apacheInstalled = $false
    $apacheVersion = "Not Installed"
    $vhostCount = 0
    $requestsPerSec = 0
    $errorCount24h = 0
    $workerProcesses = 0
    $healthStatus = "Unknown"
    
    # Search for Apache installation
    Write-Output "INFO: Searching for Apache installation..."
    $apachePaths = @(
        "C:\Apache24\bin\httpd.exe",
        "C:\Apache22\bin\httpd.exe",
        "C:\Program Files\Apache Group\Apache2\bin\httpd.exe",
        "C:\xampp\apache\bin\httpd.exe"
    )
    
    $httpdExe = $null
    foreach ($path in $apachePaths) {
        if (Test-Path $path) {
            $httpdExe = $path
            Write-Output "INFO: Found Apache at: $httpdExe"
            break
        }
    }
    
    # Try PATH if not found in standard locations
    if ($null -eq $httpdExe) {
        Write-Output "INFO: Checking PATH for httpd.exe..."
        $httpdExe = (Get-Command httpd.exe -ErrorAction SilentlyContinue).Source
        if ($httpdExe) {
            Write-Output "INFO: Found Apache in PATH: $httpdExe"
        }
    }
    
    # Check for Apache service
    $apacheService = Get-Service -Name "Apache*" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $httpdExe -and $null -eq $apacheService) {
        Write-Output "INFO: Apache HTTP Server is not installed"
        
        # Update fields for non-Apache systems
        Ninja-Property-Set apacheInstalled $false
        Ninja-Property-Set apacheVersion "Not Installed"
        Ninja-Property-Set apacheVHostCount 0
        Ninja-Property-Set apacheRequestsPerSec 0
        Ninja-Property-Set apacheErrorCount24h 0
        Ninja-Property-Set apacheWorkerProcesses 0
        Ninja-Property-Set apacheHealthStatus "Unknown"
        
        Write-Output "SUCCESS: Apache monitoring skipped (not installed)"
        exit 0
    }
    
    $apacheInstalled = $true
    Write-Output "INFO: Apache HTTP Server detected"
    
    # Get Apache version
    Write-Output "INFO: Detecting Apache version..."
    try {
        if ($httpdExe) {
            $versionOutput = & $httpdExe -v 2>&1
            if ($versionOutput -match 'Apache/(\d+\.\d+\.\d+)') {
                $apacheVersion = "Apache/$($matches[1])"
                Write-Output "INFO: Version: $apacheVersion"
            }
        }
    } catch {
        Write-Output "WARNING: Failed to get Apache version: $_"
        $apacheVersion = "Apache (version unknown)"
    }
    
    # Get worker processes count
    Write-Output "INFO: Counting worker processes..."
    try {
        $httpdProcesses = Get-Process -Name "httpd" -ErrorAction SilentlyContinue
        $workerProcesses = if ($httpdProcesses) { $httpdProcesses.Count } else { 0 }
        Write-Output "INFO: Worker processes: $workerProcesses"
    } catch {
        Write-Output "WARNING: Failed to count worker processes: $_"
    }
    
    # Get virtual host count from configuration
    Write-Output "INFO: Enumerating virtual hosts..."
    try {
        if ($httpdExe) {
            $configTest = & $httpdExe -S 2>&1
            $vhostLines = $configTest | Select-String "port \d+" -AllMatches
            $vhostCount = $vhostLines.Count
            Write-Output "INFO: Virtual hosts configured: $vhostCount"
        }
    } catch {
        Write-Output "WARNING: Failed to get vhost count: $_"
    }
    
    # Get server status from mod_status (if enabled)
    Write-Output "INFO: Checking server-status (mod_status)..."
    try {
        $statusUrl = "http://localhost/server-status?auto"
        $statusData = Invoke-WebRequest -Uri $statusUrl -TimeoutSec 5 -ErrorAction SilentlyContinue
        
        if ($statusData) {
            $content = $statusData.Content
            
            # Parse requests per second
            if ($content -match 'ReqPerSec:\s+([\d.]+)') {
                $requestsPerSec = [Math]::Round([decimal]$matches[1])
                Write-Output "INFO: Request rate: $requestsPerSec req/sec"
            }
        } else {
            Write-Output "INFO: mod_status not accessible (may be disabled or restricted)"
        }
    } catch {
        Write-Output "INFO: Server status not available (mod_status may be disabled)"
    }
    
    # Get error count from error log (last 24 hours estimate)
    Write-Output "INFO: Analyzing error log..."
    try {
        $apacheRoot = Split-Path (Split-Path $httpdExe)
        $errorLogPath = Join-Path $apacheRoot "logs\error.log"
        
        if (Test-Path $errorLogPath) {
            $errorLines = Get-Content $errorLogPath -Tail 1000 -ErrorAction SilentlyContinue | 
                Where-Object { $_ -match '\[error\]|\[crit\]' }
            
            $errorCount24h = if ($errorLines) { $errorLines.Count } else { 0 }
            Write-Output "INFO: Errors detected (24h estimate): $errorCount24h"
        } else {
            Write-Output "INFO: Error log not found at: $errorLogPath"
        }
    } catch {
        Write-Output "WARNING: Failed to read error log: $_"
    }
    
    # Determine health status
    Write-Output "INFO: Determining health status..."
    if ($apacheService -and $apacheService.Status -ne 'Running') {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Apache service stopped"
    } elseif ($workerProcesses -eq 0) {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: No worker processes running"
    } elseif ($errorCount24h -gt 100) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: High error rate detected"
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: Apache server operational"
    }
    
    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set apacheInstalled $true
    Ninja-Property-Set apacheVersion $apacheVersion
    Ninja-Property-Set apacheVHostCount $vhostCount
    Ninja-Property-Set apacheRequestsPerSec $requestsPerSec
    Ninja-Property-Set apacheErrorCount24h $errorCount24h
    Ninja-Property-Set apacheWorkerProcesses $workerProcesses
    Ninja-Property-Set apacheHealthStatus $healthStatus
    
    Write-Output "SUCCESS: Apache monitoring complete"
    Write-Output "APACHE SERVER METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - Version: $apacheVersion"
    Write-Output "  - Virtual Hosts: $vhostCount"
    Write-Output "  - Worker Processes: $workerProcesses"
    Write-Output "  - Request Rate: $requestsPerSec req/sec"
    Write-Output "  - Errors (24h): $errorCount24h"
    
    if ($apacheService) {
        Write-Output "  - Service Status: $($apacheService.Status)"
    }
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: Apache Web Server Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    # Set error state in fields
    Ninja-Property-Set apacheInstalled $false
    Ninja-Property-Set apacheHealthStatus "Unknown"
    
    exit 1
}
