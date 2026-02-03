<#
.SYNOPSIS
    Script 1: Apache Web Server Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Apache HTTP Server including virtual hosts, requests per second, errors,
    worker processes, and overall server health. Updates 7 APACHE fields.

.FIELDS UPDATED
    - APACHEInstalled (Checkbox)
    - APACHEVersion (Text)
    - APACHEVHostCount (Integer)
    - APACHERequestsPerSec (Integer)
    - APACHEErrorCount24h (Integer)
    - APACHEWorkerProcesses (Integer)
    - APACHEHealthStatus (Dropdown)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Requires: Apache HTTP Server installed

.NOTES
    File: Script_01_Apache_Web_Server_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Infrastructure Monitoring
    Dependencies: Apache httpd.exe, apachectl or httpd commands

.RELATED DOCUMENTATION
    - docs/core/14_ROLE_Infrastructure.md
    - docs/IMPLEMENTATION_PROGRESS_2026-02-03.md
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Apache Web Server Monitor (Script 1)..."
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
    Write-Host "Searching for Apache installation..."
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
            Write-Host "Found Apache: $httpdExe"
            break
        }
    }
    
    # Try PATH
    if ($null -eq $httpdExe) {
        $httpdExe = (Get-Command httpd.exe -ErrorAction SilentlyContinue).Source
        if ($httpdExe) {
            Write-Host "Found Apache in PATH: $httpdExe"
        }
    }
    
    # Check for Apache service
    $apacheService = Get-Service -Name "Apache*" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $httpdExe -and $null -eq $apacheService) {
        Write-Host "Apache HTTP Server is not installed."
        
        # Update fields for non-Apache systems
        Ninja-Property-Set apacheInstalled $false
        Ninja-Property-Set apacheVersion "Not Installed"
        Ninja-Property-Set apacheVHostCount 0
        Ninja-Property-Set apacheRequestsPerSec 0
        Ninja-Property-Set apacheErrorCount24h 0
        Ninja-Property-Set apacheWorkerProcesses 0
        Ninja-Property-Set apacheHealthStatus "Unknown"
        
        Write-Host "Apache Web Server Monitor complete (not installed)."
        exit 0
    }
    
    $apacheInstalled = $true
    Write-Host "Apache HTTP Server is installed."
    
    # Get Apache version
    try {
        if ($httpdExe) {
            $versionOutput = & $httpdExe -v 2>&1
            if ($versionOutput -match 'Apache/(\d+\.\d+\.\d+)') {
                $apacheVersion = "Apache/$($matches[1])"
                Write-Host "Apache Version: $apacheVersion"
            }
        }
    } catch {
        Write-Warning "Failed to get Apache version: $_"
        $apacheVersion = "Apache (version unknown)"
    }
    
    # Get worker processes count
    try {
        $httpdProcesses = Get-Process -Name "httpd" -ErrorAction SilentlyContinue
        $workerProcesses = if ($httpdProcesses) { $httpdProcesses.Count } else { 0 }
        Write-Host "Worker Processes: $workerProcesses"
    } catch {
        Write-Warning "Failed to count worker processes: $_"
    }
    
    # Get virtual host count from config
    try {
        if ($httpdExe) {
            $configTest = & $httpdExe -S 2>&1
            $vhostLines = $configTest | Select-String "port \d+" -AllMatches
            $vhostCount = $vhostLines.Count
            Write-Host "Virtual Hosts: $vhostCount"
        }
    } catch {
        Write-Warning "Failed to get vhost count: $_"
    }
    
    # Get server status (if mod_status is enabled)
    try {
        # Try to query server-status page (typically http://localhost/server-status)
        $statusUrl = "http://localhost/server-status?auto"
        $statusData = Invoke-WebRequest -Uri $statusUrl -TimeoutSec 5 -ErrorAction SilentlyContinue
        
        if ($statusData) {
            $content = $statusData.Content
            
            # Parse requests per second
            if ($content -match 'ReqPerSec:\s+([\d.]+)') {
                $requestsPerSec = [Math]::Round([decimal]$matches[1])
                Write-Host "Requests/sec: $requestsPerSec"
            }
        }
    } catch {
        Write-Host "Server status not accessible (mod_status may be disabled)"
    }
    
    # Get error count from log file (last 24 hours)
    try {
        $apacheRoot = Split-Path (Split-Path $httpdExe)
        $errorLogPath = Join-Path $apacheRoot "logs\error.log"
        
        if (Test-Path $errorLogPath) {
            $yesterday = (Get-Date).AddDays(-1)
            $errorLines = Get-Content $errorLogPath -Tail 1000 -ErrorAction SilentlyContinue | 
                Where-Object { $_ -match '\[error\]|\[crit\]' }
            
            # Simple count (could be improved with date parsing)
            $errorCount24h = if ($errorLines) { $errorLines.Count } else { 0 }
            Write-Host "Errors (24h estimate): $errorCount24h"
        }
    } catch {
        Write-Warning "Failed to read error log: $_"
    }
    
    # Determine health status
    if ($apacheService -and $apacheService.Status -ne 'Running') {
        $healthStatus = "Critical"
    } elseif ($workerProcesses -eq 0) {
        $healthStatus = "Critical"
    } elseif ($errorCount24h -gt 100) {
        $healthStatus = "Warning"
    } else {
        $healthStatus = "Healthy"
    }
    
    Write-Host "Health Status: $healthStatus"
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set apacheInstalled $true
    Ninja-Property-Set apacheVersion $apacheVersion
    Ninja-Property-Set apacheVHostCount $vhostCount
    Ninja-Property-Set apacheRequestsPerSec $requestsPerSec
    Ninja-Property-Set apacheErrorCount24h $errorCount24h
    Ninja-Property-Set apacheWorkerProcesses $workerProcesses
    Ninja-Property-Set apacheHealthStatus $healthStatus
    
    Write-Host "Apache Web Server Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Apache Web Server Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set apacheInstalled $false
    Ninja-Property-Set apacheHealthStatus "Unknown"
    
    exit 1
}
