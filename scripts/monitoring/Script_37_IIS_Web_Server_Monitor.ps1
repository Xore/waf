<#
.SYNOPSIS
    Script 37: IIS Web Server Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors IIS web server health including sites, application pools, worker processes,
    request queues, and error rates. Updates 11 IIS custom fields.

.FIELDS UPDATED
    - IISInstalled (Checkbox)
    - IISVersion (Text)
    - IISVHostCount (Integer)
    - IISRequestsPerSecond (Integer)
    - IISErrorCount24h (Integer)
    - IISWorkerProcesses (Integer)
    - IISAppPoolCount (Integer)
    - IISAppPoolsStopped (Integer)
    - IISRequestQueueLength (Integer)
    - IISLastError (Text)
    - IISHealthStatus (Dropdown)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Requires: IIS installed, Administrator privileges

.NOTES
    File: Script_37_IIS_Web_Server_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Infrastructure Monitoring
    Dependencies: WebAdministration PowerShell module

.RELATED DOCUMENTATION
    - docs/core/12_ROLE_Database_Web.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 1)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting IIS Web Server Monitor (Script 37)..."
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
    Write-Host "Checking IIS installation..."
    $iisFeature = Get-WindowsFeature -Name Web-Server -ErrorAction SilentlyContinue
    
    if ($null -eq $iisFeature -or -not $iisFeature.Installed) {
        Write-Host "IIS is not installed on this system."
        
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
        
        Write-Host "IIS Monitor complete (not installed)."
        exit 0
    }
    
    $iisInstalled = $true
    Write-Host "IIS is installed. Proceeding with monitoring..."
    
    # Import WebAdministration module
    Import-Module WebAdministration -ErrorAction Stop
    
    # Get IIS version
    try {
        $iisRegPath = "HKLM:\SOFTWARE\Microsoft\InetStp"
        if (Test-Path $iisRegPath) {
            $majorVersion = (Get-ItemProperty -Path $iisRegPath -Name MajorVersion).MajorVersion
            $minorVersion = (Get-ItemProperty -Path $iisRegPath -Name MinorVersion).MinorVersion
            $iisVersion = "IIS $majorVersion.$minorVersion"
        }
    } catch {
        $iisVersion = "IIS (Version Unknown)"
    }
    Write-Host "IIS Version: $iisVersion"
    
    # Get website count (virtual hosts)
    try {
        $sites = Get-Website
        $vhostCount = $sites.Count
        Write-Host "Virtual Hosts: $vhostCount"
    } catch {
        Write-Warning "Failed to get website count: $_"
    }
    
    # Get application pool information
    try {
        $appPools = Get-IISAppPool
        $appPoolCount = $appPools.Count
        $appPoolsStopped = ($appPools | Where-Object { $_.State -ne 'Started' }).Count
        Write-Host "App Pools: $appPoolCount (Stopped: $appPoolsStopped)"
    } catch {
        Write-Warning "Failed to get app pool information: $_"
    }
    
    # Get worker process count
    try {
        $workerProcesses = (Get-Process -Name w3wp -ErrorAction SilentlyContinue).Count
        Write-Host "Worker Processes: $workerProcesses"
    } catch {
        Write-Warning "Failed to get worker process count: $_"
    }
    
    # Get performance counter data (requests per second)
    try {
        $counterPath = "\Web Service(_Total)\Total Method Requests/sec"
        $requestsPerSecond = [Math]::Round((Get-Counter -Counter $counterPath -ErrorAction SilentlyContinue).CounterSamples.CookedValue)
        Write-Host "Requests/sec: $requestsPerSecond"
    } catch {
        Write-Warning "Failed to get requests per second: $_"
        $requestsPerSecond = 0
    }
    
    # Get request queue length
    try {
        $queueCounterPath = "\HTTP Service Request Queues(_Total)\CurrentQueueSize"
        $requestQueueLength = [Math]::Round((Get-Counter -Counter $queueCounterPath -ErrorAction SilentlyContinue).CounterSamples.CookedValue)
        Write-Host "Request Queue Length: $requestQueueLength"
    } catch {
        Write-Warning "Failed to get request queue length: $_"
        $requestQueueLength = 0
    }
    
    # Get error count from event log (last 24 hours)
    try {
        $startTime = (Get-Date).AddHours(-24)
        $iisErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-IIS*', 'W3SVC*'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $errorCount24h = if ($null -eq $iisErrors) { 0 } else { $iisErrors.Count }
        Write-Host "Errors (24h): $errorCount24h"
        
        # Get last error message
        if ($errorCount24h -gt 0) {
            $lastError = ($iisErrors | Select-Object -First 1).Message
            if ($lastError.Length -gt 1000) {
                $lastError = $lastError.Substring(0, 997) + "..."
            }
        } else {
            $lastError = "None"
        }
    } catch {
        Write-Warning "Failed to retrieve event log errors: $_"
        $errorCount24h = 0
        $lastError = "Unable to retrieve error log"
    }
    
    # Determine health status
    if ($appPoolsStopped -gt 0) {
        $healthStatus = "Critical"
    } elseif ($errorCount24h -gt 50 -or $requestQueueLength -gt 1000) {
        $healthStatus = "Warning"
    } elseif ($workerProcesses -eq 0 -and $vhostCount -gt 0) {
        $healthStatus = "Warning"
    } else {
        $healthStatus = "Healthy"
    }
    
    Write-Host "Overall Health Status: $healthStatus"
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
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
    
    Write-Host "IIS Web Server Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "IIS Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set iisHealthStatus "Unknown"
    Ninja-Property-Set iisLastError "Monitor script error: $errorMessage"
    
    exit 1
}
