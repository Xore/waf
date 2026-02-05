<#
.SYNOPSIS
    IIS Web Server Monitor - Internet Information Services Health and Performance Monitoring

.DESCRIPTION
    Monitors Microsoft IIS web server infrastructure including websites, application pools,
    worker processes, request throughput, error rates, and queue depths. Provides comprehensive
    IIS monitoring for Windows-based web hosting environments.
    
    Critical for detecting application pool failures, worker process crashes, request queue
    backlogs, and performance degradation before they impact end users. Essential for
    maintaining high-availability web services and SLA compliance.
    
    Monitoring Scope:
    
    IIS Installation Detection:
    - Checks Web-Server Windows feature
    - Imports WebAdministration PowerShell module
    - Reads IIS version from registry (HKLM:\SOFTWARE\Microsoft\InetStp)
    - Gracefully exits if IIS not installed
    
    Website Inventory (Virtual Hosts):
    - Enumerates all IIS websites via Get-Website
    - Counts configured virtual hosts
    - Multi-tenant hosting capacity metric
    
    Application Pool Monitoring:
    - Counts total application pools via Get-IISAppPool
    - Identifies stopped application pools (critical)
    - Application isolation and process boundary tracking
    - Pool recycling and health assessment
    
    Worker Process Monitoring:
    - Counts active w3wp.exe processes
    - Each process represents an app pool worker
    - Zero workers with active sites indicates service failure
    - Process pool health metric
    
    Request Performance Tracking:
    - Queries performance counter: Web Service(_Total)\Total Method Requests/sec
    - Real-time throughput monitoring
    - Capacity planning and load assessment
    
    Request Queue Analysis:
    - Queries counter: HTTP Service Request Queues(_Total)\CurrentQueueSize
    - Queue depth indicates saturation
    - High queues (>1000) suggest insufficient worker processes
    - Performance degradation early warning
    
    Error Rate Monitoring:
    - Queries System event log for IIS-related errors (24h)
    - Providers: Microsoft-Windows-IIS*, W3SVC*
    - Severity: Critical (Level 1) and Error (Level 2)
    - Captures last error message for troubleshooting
    - High error rates (>50/24h) indicate application issues
    
    Health Status Classification:
    
    Healthy:
    - All app pools running
    - Worker processes active
    - Error count acceptable (<50/24h)
    - Request queue normal (<1000)
    
    Warning:
    - High error rate (>50/24h)
    - Large request queue (>1000)
    - No workers but sites configured
    - Performance degraded
    
    Critical:
    - Stopped application pools detected
    - App pool crashes
    - Service unavailable
    
    Unknown:
    - IIS not installed
    - Script execution error
    - Insufficient permissions

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - IISInstalled (Checkbox)
    - IISVersion (Text: IIS major.minor version)
    - IISVHostCount (Integer: configured websites)
    - IISRequestsPerSecond (Integer: current request rate)
    - IISErrorCount24h (Integer: error events in 24h)
    - IISWorkerProcesses (Integer: active w3wp.exe count)
    - IISAppPoolCount (Integer: total app pools)
    - IISAppPoolsStopped (Integer: stopped pools - critical metric)
    - IISRequestQueueLength (Integer: current queue depth)
    - IISLastError (Text: most recent error message, max 1000 chars)
    - IISHealthStatus (Dropdown: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - Web-Server Windows feature installed
    - WebAdministration PowerShell module
    - Administrator privileges for performance counters
    - Event log read access
    
    Supported IIS Versions:
    - IIS 7.0, 7.5 (Windows Server 2008/2008 R2)
    - IIS 8.0, 8.5 (Windows Server 2012/2012 R2)
    - IIS 10.0 (Windows Server 2016/2019/2022)
    
    Performance Counters Used:
    - \Web Service(_Total)\Total Method Requests/sec
    - \HTTP Service Request Queues(_Total)\CurrentQueueSize
    
    Event Log Sources:
    - Provider: Microsoft-Windows-IIS*
    - Provider: W3SVC*
    - LogName: System
    
    Common Issues:
    - Module import fails: Install IIS Management Tools feature
    - Counter access denied: Run as administrator
    - App pool stopped: Check application error logs
    - High queue depth: Increase app pool worker process limit
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting IIS Web Server Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $iisInstalled = $false
    $iisVersion = "Not Installed"
    $vhostCount = 0
    $requestsPerSecond = 0
    $errorCount24h = 0
    $workerProcesses = 0
    $appPoolCount = 0
    $appPoolsStopped = 0
    $requestQueueLength = 0
    $lastError = "None"
    $healthStatus = "Unknown"
    
    # Check if IIS is installed
    Write-Output "INFO: Checking for IIS installation..."
    $iisFeature = Get-WindowsFeature -Name Web-Server -ErrorAction SilentlyContinue
    
    if ($null -eq $iisFeature -or -not $iisFeature.Installed) {
        Write-Output "INFO: IIS not installed on this system"
        
        # Update NinjaRMM fields for non-IIS systems
        Ninja-Property-Set iisInstalled $false
        Ninja-Property-Set iisVersion "Not Installed"
        Ninja-Property-Set iisVHostCount 0
        Ninja-Property-Set iisRequestsPerSecond 0
        Ninja-Property-Set iisErrorCount24h 0
        Ninja-Property-Set iisWorkerProcesses 0
        Ninja-Property-Set iisAppPoolCount 0
        Ninja-Property-Set iisAppPoolsStopped 0
        Ninja-Property-Set iisRequestQueueLength 0
        Ninja-Property-Set iisLastError "IIS not installed"
        Ninja-Property-Set iisHealthStatus "Unknown"
        
        Write-Output "SUCCESS: IIS monitoring skipped (not installed)"
        exit 0
    }
    
    $iisInstalled = $true
    Write-Output "INFO: IIS detected - loading WebAdministration module..."
    
    # Import WebAdministration module
    Import-Module WebAdministration -ErrorAction Stop
    Write-Output "INFO: WebAdministration module loaded"
    
    # Get IIS version
    Write-Output "INFO: Detecting IIS version..."
    try {
        $iisRegPath = "HKLM:\SOFTWARE\Microsoft\InetStp"
        if (Test-Path $iisRegPath) {
            $majorVersion = (Get-ItemProperty -Path $iisRegPath -Name MajorVersion).MajorVersion
            $minorVersion = (Get-ItemProperty -Path $iisRegPath -Name MinorVersion).MinorVersion
            $iisVersion = "IIS $majorVersion.$minorVersion"
            Write-Output "INFO: Version: $iisVersion"
        }
    } catch {
        $iisVersion = "IIS (Version Unknown)"
        Write-Output "WARNING: Failed to detect version"
    }
    
    # Get website count (virtual hosts)
    Write-Output "INFO: Enumerating websites..."
    try {
        $sites = Get-Website
        $vhostCount = $sites.Count
        Write-Output "INFO: Virtual hosts configured: $vhostCount"
    } catch {
        Write-Output "WARNING: Failed to get website count: $_"
    }
    
    # Get application pool information
    Write-Output "INFO: Checking application pools..."
    try {
        $appPools = Get-IISAppPool
        $appPoolCount = $appPools.Count
        $appPoolsStopped = ($appPools | Where-Object { $_.State -ne 'Started' }).Count
        Write-Output "INFO: App pools: $appPoolCount total, $appPoolsStopped stopped"
        
        if ($appPoolsStopped -gt 0) {
            $stoppedNames = ($appPools | Where-Object { $_.State -ne 'Started' }).Name -join ', '
            Write-Output "  WARNING: Stopped pools: $stoppedNames"
        }
    } catch {
        Write-Output "WARNING: Failed to get app pool information: $_"
    }
    
    # Get worker process count
    Write-Output "INFO: Counting worker processes..."
    try {
        $workerProcesses = (Get-Process -Name w3wp -ErrorAction SilentlyContinue).Count
        Write-Output "INFO: Worker processes (w3wp.exe): $workerProcesses"
    } catch {
        Write-Output "WARNING: Failed to get worker process count: $_"
    }
    
    # Get performance counter data (requests per second)
    Write-Output "INFO: Querying request rate..."
    try {
        $counterPath = "\Web Service(_Total)\Total Method Requests/sec"
        $requestsPerSecond = [Math]::Round((Get-Counter -Counter $counterPath -ErrorAction SilentlyContinue).CounterSamples.CookedValue)
        Write-Output "INFO: Request rate: $requestsPerSecond req/sec"
    } catch {
        Write-Output "WARNING: Failed to get requests per second: $_"
        $requestsPerSecond = 0
    }
    
    # Get request queue length
    Write-Output "INFO: Checking request queue depth..."
    try {
        $queueCounterPath = "\HTTP Service Request Queues(_Total)\CurrentQueueSize"
        $requestQueueLength = [Math]::Round((Get-Counter -Counter $queueCounterPath -ErrorAction SilentlyContinue).CounterSamples.CookedValue)
        Write-Output "INFO: Request queue: $requestQueueLength"
        
        if ($requestQueueLength -gt 1000) {
            Write-Output "  WARNING: High queue depth detected"
        }
    } catch {
        Write-Output "WARNING: Failed to get request queue length: $_"
        $requestQueueLength = 0
    }
    
    # Get error count from event log (last 24 hours)
    Write-Output "INFO: Analyzing IIS event log errors (24h)..."
    try {
        $startTime = (Get-Date).AddHours(-24)
        $iisErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-IIS*', 'W3SVC*'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $errorCount24h = if ($null -eq $iisErrors) { 0 } else { $iisErrors.Count }
        Write-Output "INFO: Errors detected (24h): $errorCount24h"
        
        # Get last error message
        if ($errorCount24h -gt 0) {
            $lastError = ($iisErrors | Select-Object -First 1).Message
            if ($lastError.Length -gt 1000) {
                $lastError = $lastError.Substring(0, 997) + "..."
            }
            Write-Output "  Last error: $($lastError.Substring(0, [Math]::Min(100, $lastError.Length)))..."
        } else {
            $lastError = "None"
        }
    } catch {
        Write-Output "WARNING: Failed to retrieve event log errors: $_"
        $errorCount24h = 0
        $lastError = "Unable to retrieve error log"
    }
    
    # Determine health status
    Write-Output "INFO: Determining health status..."
    if ($appPoolsStopped -gt 0) {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Application pool(s) stopped"
    } elseif ($errorCount24h -gt 50 -or $requestQueueLength -gt 1000) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: High error rate or queue backlog"
    } elseif ($workerProcesses -eq 0 -and $vhostCount -gt 0) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: No worker processes for configured sites"
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: IIS web server operational"
    }
    
    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set iisInstalled $true
    Ninja-Property-Set iisVersion $iisVersion
    Ninja-Property-Set iisVHostCount $vhostCount
    Ninja-Property-Set iisRequestsPerSecond $requestsPerSecond
    Ninja-Property-Set iisErrorCount24h $errorCount24h
    Ninja-Property-Set iisWorkerProcesses $workerProcesses
    Ninja-Property-Set iisAppPoolCount $appPoolCount
    Ninja-Property-Set iisAppPoolsStopped $appPoolsStopped
    Ninja-Property-Set iisRequestQueueLength $requestQueueLength
    Ninja-Property-Set iisLastError $lastError
    Ninja-Property-Set iisHealthStatus $healthStatus
    
    Write-Output "SUCCESS: IIS Web Server monitoring complete"
    Write-Output "IIS SERVER METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - Version: $iisVersion"
    Write-Output "  - Virtual Hosts: $vhostCount"
    Write-Output "  - App Pools: $appPoolCount ($appPoolsStopped stopped)"
    Write-Output "  - Worker Processes: $workerProcesses"
    Write-Output "  - Request Rate: $requestsPerSecond req/sec"
    Write-Output "  - Request Queue: $requestQueueLength"
    Write-Output "  - Errors (24h): $errorCount24h"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: IIS Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    # Set error state in fields
    Ninja-Property-Set iisHealthStatus "Unknown"
    Ninja-Property-Set iisLastError "Monitor script error: $errorMessage"
    
    exit 1
}
