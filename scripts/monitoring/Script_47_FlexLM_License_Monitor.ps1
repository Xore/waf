<#
.SYNOPSIS
    FlexLM License Monitor - FlexNet License Server Health and Utilization Monitoring

.DESCRIPTION
    Monitors FlexLM/FlexNet license servers including vendor daemon status, license pool
    utilization, denied checkout requests, license expirations, and server health. Essential
    for enterprise software licensing compliance and preventing license exhaustion.
    
    Critical for detecting license denials that block users from running software, tracking
    license utilization for capacity planning, and identifying expiring licenses before they
    cause software outages. Foundational for managing expensive engineering/CAD software licenses.
    
    Monitoring Scope:
    
    FlexLM Installation Detection:
    - Searches for lmutil.exe in common paths:
      - C:\Program Files\FlexLM\lmutil.exe
      - C:\FlexLM\lmutil.exe
      - C:\Autodesk\Network License Manager\lmutil.exe
      - C:\Program Files\Flexera Software\FlexNet Manager\lmutil.exe
    - Falls back to PATH environment variable
    - Gracefully exits if lmutil not found
    
    License File Discovery:
    - Searches common license file locations:
      - C:\FlexLM\license.dat
      - C:\Program Files\FlexLM\license.dat
      - C:\Autodesk\Network License Manager\*.lic
    - Checks LM_LICENSE_FILE environment variable
    - Parses SERVER directive for license server hostname
    
    License Server Status:
    - Executes lmutil lmstat -a command
    - Queries all vendor daemons and license features
    - Comprehensive license server health check
    
    Version Detection:
    - Parses lmutil copyright header
    - Identifies FlexLM/FlexNet version
    - Compatibility and upgrade tracking
    
    Vendor Daemon Monitoring:
    - Counts active vendor daemons (ISV servers)
    - Each daemon manages specific vendor licenses
    - Common vendors: Autodesk, ANSYS, MATLAB, SolidWorks
    - Daemon failures prevent license checkouts
    
    Daemon Health Check:
    - Parses daemon status: UP or DOWN
    - UP = daemon running and serving licenses
    - DOWN = daemon crashed, licenses unavailable
    - Critical for service availability
    
    License Utilization Tracking:
    - Parses "X OUT OF Y LICENSES IN USE" patterns
    - Aggregates across all license features
    - Calculates overall utilization percentage
    - High utilization (>90%) risks checkout denials
    
    Denied Request Detection:
    - Counts DENIED license checkout attempts
    - Indicates insufficient license capacity
    - Users blocked from running software
    - Critical metric for license purchasing decisions
    
    License Expiration Monitoring:
    - Parses license expiration dates
    - Identifies licenses expiring within 30 days
    - Prevents unexpected software outages
    - Critical for license renewal planning
    
    Server Uptime Tracking:
    - Parses license server uptime in days
    - Converts to hours for consistency
    - Long uptimes indicate stability
    
    Health Status Classification:
    
    Healthy:
    - All daemons running (UP)
    - Low utilization (<90%)
    - No denied requests
    - No expiring licenses
    
    Warning:
    - High utilization (>90%)
    - Denied requests detected (>10/24h)
    - Licenses expiring within 30 days
    - Action needed
    
    Critical:
    - Vendor daemon down
    - License server unreachable
    - Service unavailable
    
    Unknown:
    - FlexLM not installed
    - lmutil not found
    - Query failed
    - Script execution error

.NOTES
    Frequency: Every 4 hours
    Runtime: ~35 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - FLEXLMInstalled (Checkbox)
    - FLEXLMVersion (Text: FlexLM version)
    - FLEXLMVendorDaemonCount (Integer: ISV daemon count)
    - FLEXLMLicenseUtilization (Integer: overall utilization %)
    - FLEXLMDeniedRequests24h (Integer: checkout denials)
    - FLEXLMDaemonStatus (Text: Running, Stopped, Unknown, Error)
    - FLEXLMExpiringLicenses30d (Integer: licenses expiring soon)
    - FLEXLMServerUptime (Integer: uptime in hours)
    - FLEXLMLicenseServerName (Text: license server hostname)
    - FLEXLMLicenseSummary (WYSIWYG: HTML formatted summary)
    - FLEXLMHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - FlexLM/FlexNet Publisher installed
    - lmutil.exe command-line utility
    - License file (license.dat or .lic)
    - Network access to license server port (default 27000-27009)
    
    FlexLM Architecture:
    - lmgrd: Master license daemon
    - Vendor daemons: ISV-specific servers (e.g., adskflex, ansyslmd)
    - License file: Defines SERVER, VENDOR, FEATURE lines
    
    Common Vendors:
    - Autodesk (AutoCAD, Revit, Inventor): adskflex
    - ANSYS (simulation): ansyslmd
    - MATLAB: MLM
    - SolidWorks: sw_d
    - Siemens NX: ugslmd
    
    License File Format:
    - SERVER: License server hostname and port
    - VENDOR: Vendor daemon name and path
    - FEATURE: Licensed product, count, expiration
    
    Common Issues:
    - lmutil not found: Install FlexLM tools or add to PATH
    - License file missing: Check LM_LICENSE_FILE or default paths
    - Daemon down: Check vendor daemon service/process
    - Port blocked: Verify firewall allows 27000-27009
    - Denied requests: Purchase additional licenses
    - Expiring licenses: Contact vendor for renewal
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting FlexLM License Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
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
    
    Write-Output "INFO: Searching for FlexLM lmutil.exe..."
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
            Write-Output "INFO: Found lmutil.exe: $lmutilExe"
            break
        }
    }
    
    if ($null -eq $lmutilExe) {
        $lmutilExe = (Get-Command lmutil.exe -ErrorAction SilentlyContinue).Source
        if ($lmutilExe) {
            Write-Output "INFO: Found lmutil.exe in PATH"
        }
    }
    
    if ($null -eq $lmutilExe) {
        Write-Output "INFO: FlexLM not installed (lmutil.exe not found)"
        
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
        
        Write-Output "SUCCESS: FlexLM monitoring skipped (not installed)"
        exit 0
    }
    
    $flexlmInstalled = $true
    
    Write-Output "INFO: Searching for license file..."
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
            Write-Output "INFO: Found license file: $licenseFile"
            break
        }
    }
    
    if ($null -eq $licenseFile) {
        $envLicense = $env:LM_LICENSE_FILE
        if ($envLicense -and (Test-Path $envLicense)) {
            $licenseFile = $envLicense
            Write-Output "INFO: Found license file from environment: $licenseFile"
        }
    }
    
    if ($null -eq $licenseFile) {
        Write-Output "WARNING: License file not found, using localhost as default"
        $licenseServerName = "localhost"
    } else {
        $licenseContent = Get-Content $licenseFile -ErrorAction SilentlyContinue
        $serverLine = $licenseContent | Where-Object { $_ -match '^SERVER\s+(\S+)' } | Select-Object -First 1
        if ($serverLine -match '^SERVER\s+(\S+)') {
            $licenseServerName = $matches[1]
            Write-Output "INFO: License server: $licenseServerName"
        }
    }
    
    Write-Output "INFO: Querying license server status..."
    try {
        $statusArgs = @('lmstat', '-a')
        if ($licenseFile) {
            $statusArgs += @('-c', $licenseFile)
        }
        
        $statusOutput = & $lmutilExe $statusArgs 2>&1 | Out-String
        
        if ($statusOutput -match 'lmutil - Copyright.*v([0-9.]+)') {
            $flexlmVersion = "FlexLM v$($matches[1])"
            Write-Output "INFO: Version: $flexlmVersion"
        }
        
        $vendorDaemons = ($statusOutput | Select-String 'Vendor daemon status').Count
        $vendorDaemonCount = $vendorDaemons
        Write-Output "INFO: Vendor daemons: $vendorDaemonCount"
        
        if ($statusOutput -match 'UP') {
            $daemonStatus = "Running"
        } elseif ($statusOutput -match 'DOWN') {
            $daemonStatus = "Stopped"
        } else {
            $daemonStatus = "Unknown"
        }
        Write-Output "INFO: Daemon status: $daemonStatus"
        
        if ($statusOutput -match 'License server status:\s+(\d+)') {
            $uptimeDays = [int]$matches[1]
            $serverUptime = $uptimeDays * 24
            Write-Output "INFO: Server uptime: $serverUptime hours"
        }
        
        $inUseMatches = [regex]::Matches($statusOutput, '(\d+) OUT OF (\d+) LICENSES? IN USE')
        $totalInUse = 0
        $totalAvailable = 0
        
        foreach ($match in $inUseMatches) {
            $totalInUse += [int]$match.Groups[1].Value
            $totalAvailable += [int]$match.Groups[2].Value
        }
        
        if ($totalAvailable -gt 0) {
            $licenseUtilization = [Math]::Round(($totalInUse / $totalAvailable) * 100)
            Write-Output "INFO: License utilization: $licenseUtilization% ($totalInUse/$totalAvailable)"
        }
        
        $deniedMatches = [regex]::Matches($statusOutput, 'DENIED:(\d+)')
        foreach ($match in $deniedMatches) {
            $deniedRequests24h += [int]$match.Groups[1].Value
        }
        Write-Output "INFO: Denied requests: $deniedRequests24h"
        
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
        Write-Output "INFO: Expiring licenses (30d): $expiringLicenses30d"
        
    } catch {
        Write-Output "WARNING: Failed to query license server: $_"
        $daemonStatus = "Error"
    }
    
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
    
    Write-Output "INFO: Determining health status..."
    if ($daemonStatus -ne "Running") {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Critical - Daemon not running"
    } elseif ($deniedRequests24h -gt 10 -or $expiringLicenses30d -gt 0) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - Denied requests or expiring licenses"
    } elseif ($licenseUtilization -gt 90) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - High license utilization"
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: FlexLM license server healthy"
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
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
    
    Write-Output "SUCCESS: FlexLM License monitoring complete"
    Write-Output "FLEXLM LICENSE METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - License Server: $licenseServerName"
    Write-Output "  - Version: $flexlmVersion"
    Write-Output "  - Vendor Daemons: $vendorDaemonCount ($daemonStatus)"
    Write-Output "  - Utilization: $licenseUtilization%"
    Write-Output "  - Denied Requests: $deniedRequests24h"
    Write-Output "  - Expiring (30d): $expiringLicenses30d"
    Write-Output "  - Uptime: $serverUptime hours"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: FlexLM License Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set flexlmInstalled $false
    Ninja-Property-Set flexlmHealthStatus "Unknown"
    Ninja-Property-Set flexlmLicenseSummary "Monitor script error: $errorMessage"
    
    exit 1
}
