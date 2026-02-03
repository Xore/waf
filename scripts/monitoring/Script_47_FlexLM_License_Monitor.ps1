<#
.SYNOPSIS
    Script 47: FlexLM License Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors FlexLM/FlexNet license server including vendor daemons, license utilization,
    denied requests, daemon health, and expiration tracking. Updates 11 FLEXLM fields.

.FIELDS UPDATED
    - FLEXLMInstalled (Checkbox)
    - FLEXLMVersion (Text)
    - FLEXLMVendorDaemonCount (Integer)
    - FLEXLMLicenseUtilization (Integer)
    - FLEXLMDeniedRequests24h (Integer)
    - FLEXLMDaemonStatus (Text)
    - FLEXLMExpiringLicenses30d (Integer)
    - FLEXLMServerUptime (Integer)
    - FLEXLMLicenseServerName (Text)
    - FLEXLMLicenseSummary (WYSIWYG)
    - FLEXLMHealthStatus (Text)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~35 seconds
    Requires: FlexLM/FlexNet installed, lmutil.exe available

.NOTES
    File: Script_47_FlexLM_License_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Server Role Monitoring
    Dependencies: FlexLM lmutil.exe

.RELATED DOCUMENTATION
    - docs/core/16_ROLE_Additional.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 4)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting FlexLM License Monitor (Script 47)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $flexlmInstalled = $false
    $flexlmVersion = "Not Installed"
    $vendorDaemonCount = 0
    $licenseUtilization = 0
    $deniedRequests24h = 0
    $daemonStatus = "Unknown"
    $expiringLicenses30d = 0
    $serverUptime = 0
    $licenseServerName = "None"
    $licenseSummary = ""
    $healthStatus = "Unknown"
    
    # Search for lmutil.exe
    Write-Host "Searching for FlexLM lmutil.exe..."
    $lmutilPaths = @(
        "C:\Program Files\FlexLM\lmutil.exe",
        "C:\FlexLM\lmutil.exe",
        "C:\Program Files*\*\lmutil.exe",
        "C:\Autodesk\Network License Manager\lmutil.exe",
        "C:\Program Files\Flexera Software\FlexNet Manager\lmutil.exe"
    )
    
    $lmutilExe = $null
    foreach ($path in $lmutilPaths) {
        $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $lmutilExe = $found.FullName
            Write-Host "Found lmutil.exe: $lmutilExe"
            break
        }
    }
    
    # Try PATH
    if ($null -eq $lmutilExe) {
        $lmutilExe = (Get-Command lmutil.exe -ErrorAction SilentlyContinue).Source
        if ($lmutilExe) {
            Write-Host "Found lmutil.exe in PATH: $lmutilExe"
        }
    }
    
    if ($null -eq $lmutilExe) {
        Write-Host "FlexLM is not installed (lmutil.exe not found)."
        
        # Update fields for non-FlexLM systems
        Ninja-Property-Set flexlmInstalled $false
        Ninja-Property-Set flexlmVersion "Not Installed"
        Ninja-Property-Set flexlmVendorDaemonCount 0
        Ninja-Property-Set flexlmLicenseUtilization 0
        Ninja-Property-Set flexlmDeniedRequests24h 0
        Ninja-Property-Set flexlmDaemonStatus "Unknown"
        Ninja-Property-Set flexlmExpiringLicenses30d 0
        Ninja-Property-Set flexlmServerUptime 0
        Ninja-Property-Set flexlmLicenseServerName "N/A"
        Ninja-Property-Set flexlmLicenseSummary "FlexLM not installed"
        Ninja-Property-Set flexlmHealthStatus "Unknown"
        
        Write-Host "FlexLM License Monitor complete (not installed)."
        exit 0
    }
    
    $flexlmInstalled = $true
    
    # Find license file
    Write-Host "Searching for license file..."
    $licenseFile = $null
    $licenseSearchPaths = @(
        "C:\FlexLM\license.dat",
        "C:\Program Files\FlexLM\license.dat",
        "C:\Autodesk\Network License Manager\*.lic"
    )
    
    foreach ($path in $licenseSearchPaths) {
        $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $licenseFile = $found.FullName
            Write-Host "Found license file: $licenseFile"
            break
        }
    }
    
    # Check environment variable
    if ($null -eq $licenseFile) {
        $envLicense = $env:LM_LICENSE_FILE
        if ($envLicense -and (Test-Path $envLicense)) {
            $licenseFile = $envLicense
            Write-Host "Found license file from environment: $licenseFile"
        }
    }
    
    if ($null -eq $licenseFile) {
        Write-Warning "License file not found. Using localhost as default."
        $licenseServerName = "localhost"
    } else {
        # Parse license file for server name
        $licenseContent = Get-Content $licenseFile -ErrorAction SilentlyContinue
        $serverLine = $licenseContent | Where-Object { $_ -match '^SERVER\s+(\S+)' } | Select-Object -First 1
        if ($serverLine -match '^SERVER\s+(\S+)') {
            $licenseServerName = $matches[1]
            Write-Host "License Server: $licenseServerName"
        }
    }
    
    # Get license server status
    Write-Host "Querying license server status..."
    try {
        $statusArgs = @('lmstat', '-a')
        if ($licenseFile) {
            $statusArgs += @('-c', $licenseFile)
        }
        
        $statusOutput = & $lmutilExe $statusArgs 2>&1 | Out-String
        
        # Parse FlexLM version
        if ($statusOutput -match 'lmutil - Copyright.*v([0-9.]+)') {
            $flexlmVersion = "FlexLM v$($matches[1])"
            Write-Host "FlexLM Version: $flexlmVersion"
        }
        
        # Count vendor daemons
        $vendorDaemons = ($statusOutput | Select-String 'Vendor daemon status').Count
        $vendorDaemonCount = $vendorDaemons
        Write-Host "Vendor Daemons: $vendorDaemonCount"
        
        # Check daemon status
        if ($statusOutput -match 'UP') {
            $daemonStatus = "Running"
        } elseif ($statusOutput -match 'DOWN') {
            $daemonStatus = "Stopped"
        } else {
            $daemonStatus = "Unknown"
        }
        Write-Host "Daemon Status: $daemonStatus"
        
        # Get server uptime (in hours)
        if ($statusOutput -match 'License server status:\s+(\d+)') {
            $uptimeDays = [int]$matches[1]
            $serverUptime = $uptimeDays * 24
            Write-Host "Server Uptime: $serverUptime hours"
        }
        
        # Calculate license utilization
        $inUseMatches = [regex]::Matches($statusOutput, '(\d+) OUT OF (\d+) LICENSES? IN USE')
        $totalInUse = 0
        $totalAvailable = 0
        
        foreach ($match in $inUseMatches) {
            $totalInUse += [int]$match.Groups[1].Value
            $totalAvailable += [int]$match.Groups[2].Value
        }
        
        if ($totalAvailable -gt 0) {
            $licenseUtilization = [Math]::Round(($totalInUse / $totalAvailable) * 100)
            Write-Host "License Utilization: $licenseUtilization%"
        }
        
        # Check for denied requests
        $deniedMatches = [regex]::Matches($statusOutput, 'DENIED:(\d+)')
        foreach ($match in $deniedMatches) {
            $deniedRequests24h += [int]$match.Groups[1].Value
        }
        Write-Host "Denied Requests: $deniedRequests24h"
        
        # Check for expiring licenses (30 days)
        $expirationMatches = [regex]::Matches($statusOutput, 'expires:\s+(\d+)-(\w+)-(\d+)')
        $thirtyDaysFromNow = (Get-Date).AddDays(30)
        
        foreach ($match in $expirationMatches) {
            try {
                $expDateStr = "$($match.Groups[1].Value)-$($match.Groups[2].Value)-$($match.Groups[3].Value)"
                $expDate = [DateTime]::Parse($expDateStr)
                if ($expDate -le $thirtyDaysFromNow) {
                    $expiringLicenses30d++
                }
            } catch {
                # Unable to parse date, skip
            }
        }
        Write-Host "Expiring Licenses (30d): $expiringLicenses30d"
        
    } catch {
        Write-Warning "Failed to query license server: $_"
        $daemonStatus = "Error"
    }
    
    # Build license summary HTML
    $licenseSummary = @"
<div style='font-family:Arial,sans-serif;'>
<p><strong>License Server:</strong> $licenseServerName</p>
<p><strong>FlexLM Version:</strong> $flexlmVersion</p>
<p><strong>Daemon Status:</strong> <span style='color:$(if($daemonStatus -eq 'Running'){'green'}else{'red'})''>$daemonStatus</span></p>
<p><strong>Vendor Daemons:</strong> $vendorDaemonCount</p>
<p><strong>License Utilization:</strong> $licenseUtilization%</p>
<p><strong>Denied Requests (24h):</strong> $deniedRequests24h</p>
<p><strong>Expiring Licenses (30d):</strong> $expiringLicenses30d</p>
<p><strong>Server Uptime:</strong> $serverUptime hours</p>
</div>
"@
    
    # Determine health status
    if ($daemonStatus -ne "Running") {
        $healthStatus = "Critical"
    } elseif ($deniedRequests24h -gt 10 -or $expiringLicenses30d -gt 0) {
        $healthStatus = "Warning"
    } elseif ($licenseUtilization -gt 90) {
        $healthStatus = "Warning"
    } else {
        $healthStatus = "Healthy"
    }
    
    Write-Host "Health Status: $healthStatus"
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set flexlmInstalled $true
    Ninja-Property-Set flexlmVersion $flexlmVersion
    Ninja-Property-Set flexlmVendorDaemonCount $vendorDaemonCount
    Ninja-Property-Set flexlmLicenseUtilization $licenseUtilization
    Ninja-Property-Set flexlmDeniedRequests24h $deniedRequests24h
    Ninja-Property-Set flexlmDaemonStatus $daemonStatus
    Ninja-Property-Set flexlmExpiringLicenses30d $expiringLicenses30d
    Ninja-Property-Set flexlmServerUptime $serverUptime
    Ninja-Property-Set flexlmLicenseServerName $licenseServerName
    Ninja-Property-Set flexlmLicenseSummary $licenseSummary
    Ninja-Property-Set flexlmHealthStatus $healthStatus
    
    Write-Host "FlexLM License Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "FlexLM License Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set flexlmInstalled $false
    Ninja-Property-Set flexlmHealthStatus "Unknown"
    Ninja-Property-Set flexlmLicenseSummary "Monitor script error: $errorMessage"
    
    exit 1
}
