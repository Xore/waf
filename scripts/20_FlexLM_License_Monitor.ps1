<#
.SYNOPSIS
    NinjaRMM Script 20: FlexLM License Monitor

.DESCRIPTION
    Monitors FlexLM/FlexNet license server health.
    Tracks license usage, vendor daemons, and expiring licenses.
    Part of Infrastructure Monitoring suite - Server Roles.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - flexlmInstalled (Checkbox)
    - flexlmVersion (Text)
    - flexlmVendorDaemons (Integer)
    - flexlmDaemonsDown (Integer)
    - flexlmTotalLicenses (Integer)
    - flexlmLicensesInUse (Integer)
    - flexlmLicenseUtilizationPercent (Integer)
    - flexlmDeniedRequests24h (Integer)
    - flexlmExpiringLicenses30d (Integer)
    - flexlmLicenseSummary (WYSIWYG)
    - flexlmHealthStatus (Dropdown)
    
    Framework Version: 4.0
    Last Updated: February 2, 2026
    
    IMPORTANT: Configure FlexLM paths and license file location before deployment
#>

param()

try {
    $flexlmPaths = @(
        "C:\\Program Files\\Flexera\\FlexNet License Server",
        "C:\\FlexLM",
        "C:\\Program Files (x86)\\Common Files\\Macrovision Shared\\FLEXnet Publisher"
    )

    $lmutilPath = $null
    foreach ($path in $flexlmPaths) {
        $testPath = Join-Path $path "lmutil.exe"
        if (Test-Path $testPath) {
            $lmutilPath = $testPath
            break
        }
    }

    if (-not $lmutilPath) {
        Ninja-Property-Set flexlmInstalled $false
        Write-Output "FlexLM not found"
        exit 0
    }

    Ninja-Property-Set flexlmInstalled $true

    $versionOutput = & $lmutilPath -v 2>&1
    if ($versionOutput -match "v([0-9.]+)") {
        $version = $matches[1]
        Ninja-Property-Set flexlmVersion $version
    }

    $licenseFile = "C:\\FlexLM\\license.dat"
    if (-not (Test-Path $licenseFile)) {
        Write-Output "License file not found at $licenseFile"
        Ninja-Property-Set flexlmHealthStatus "Unknown"
        exit 0
    }

    $statusOutput = & $lmutilPath lmstat -c $licenseFile -a 2>&1

    $vendorDaemons = ($statusOutput | Select-String "Vendor daemon status").Count
    Ninja-Property-Set flexlmVendorDaemons $vendorDaemons

    $daemonsDown = ($statusOutput | Select-String "is not running|DOWN").Count
    Ninja-Property-Set flexlmDaemonsDown $daemonsDown

    $totalLicenses = 0
    $inUse = 0
    $denied = 0

    $features = $statusOutput | Select-String "Users of (.+?):"
    foreach ($feature in $features) {
        if ($feature.Line -match "Total of (\\d+) licenses? issued.*Total of (\\d+) licenses? in use") {
            $totalLicenses += [int]$matches[1]
            $inUse += [int]$matches[2]
        }
    }

    Ninja-Property-Set flexlmTotalLicenses $totalLicenses
    Ninja-Property-Set flexlmLicensesInUse $inUse

    $utilization = if ($totalLicenses -gt 0) {
        [int](($inUse / $totalLicenses) * 100)
    } else { 0 }

    Ninja-Property-Set flexlmLicenseUtilizationPercent $utilization

    $logFile = Join-Path (Split-Path $licenseFile) "flexlm.log"
    if (Test-Path $logFile) {
        $last24h = (Get-Date).AddHours(-24)
        $deniedRequests = Get-Content $logFile | Select-String "DENIED" | Where-Object {
            if ($_ -match "(\\d{1,2}:\\d{2}:\\d{2})") {
                try {
                    $logTime = [DateTime]::Parse($matches[1])
                    $logTime -gt $last24h
                } catch {
                    $false
                }
            }
        }
        $denied = ($deniedRequests | Measure-Object).Count
    }

    Ninja-Property-Set flexlmDeniedRequests24h $denied

    $expiringCount = 0
    $licenseContent = Get-Content $licenseFile
    $licenseLines = $licenseContent | Select-String "FEATURE|INCREMENT"

    foreach ($line in $licenseLines) {
        if ($line -match "\\d{1,2}-\\w{3}-(\\d{4})") {
            try {
                $expiryDate = [DateTime]::ParseExact($matches[0], "dd-MMM-yyyy", $null)
                $daysUntilExpiry = ($expiryDate - (Get-Date)).Days

                if ($daysUntilExpiry -gt 0 -and $daysUntilExpiry -le 30) {
                    $expiringCount++
                }
            } catch {
            }
        }
    }

    Ninja-Property-Set flexlmExpiringLicenses30d $expiringCount

    $html = "<h4>FlexLM License Server</h4>"
    $html += "<table>"
    $html += "<tr><td>Total Licenses:</td><td>$totalLicenses</td></tr>"
    $html += "<tr><td>In Use:</td><td>$inUse</td></tr>"
    $html += "<tr><td>Utilization:</td><td style='color:$(if($utilization -gt 90){'red'}elseif($utilization -gt 70){'orange'}else{'green'})'>$utilization%</td></tr>"
    $html += "<tr><td>Denied (24h):</td><td style='color:$(if($denied -gt 0){'red'}else{'green'})'>$denied</td></tr>"
    $html += "<tr><td>Vendor Daemons:</td><td>$vendorDaemons</td></tr>"
    $html += "<tr><td>Daemons Down:</td><td style='color:$(if($daemonsDown -gt 0){'red'}else{'green'})'>$daemonsDown</td></tr>"
    $html += "<tr><td>Expiring Soon:</td><td>$expiringCount</td></tr>"
    $html += "</table>"

    Ninja-Property-Set flexlmLicenseSummary $html

    if ($daemonsDown -eq 0 -and $denied -eq 0 -and $utilization -lt 90) {
        $health = "Healthy"
    } elseif ($daemonsDown -eq 0 -and ($denied -le 5 -or $utilization -lt 95)) {
        $health = "Warning"
    } else {
        $health = "Critical"
    }

    Ninja-Property-Set flexlmHealthStatus $health

    Write-Output "FlexLM Health: $health | Licenses: $inUse/$totalLicenses ($utilization%) | Denied: $denied | Expiring: $expiringCount"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set flexlmHealthStatus "Unknown"
    exit 1
}
