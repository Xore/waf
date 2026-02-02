#!/usr/bin/env pwsh
# Script 13: Drift Detector
# Purpose: Detect configuration drift and unauthorized software installations
# Frequency: Daily
# Runtime: ~25 seconds
# Timeout: 90 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Drift Detector (v4.0 Native-Enhanced)"

    $currentApps = Get-ItemProperty HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\* | 
        Where-Object { $_.DisplayName } | 
        Select-Object -ExpandProperty DisplayName | 
        Sort-Object

    $baselineApps = Ninja-Property-Get DRIFTBaselineApps
    
    if ([string]::IsNullOrEmpty($baselineApps)) {
        $appList = $currentApps -join ','
        Ninja-Property-Set DRIFTBaselineApps $appList
        Ninja-Property-Set DRIFTNewAppsCount 0
        Write-Output "Baseline established with $($currentApps.Count) applications"
        exit 0
    }

    $baselineList = $baselineApps -split ','
    $newApps = $currentApps | Where-Object { $_ -notin $baselineList }
    $newAppCount = $newApps.Count

    Ninja-Property-Set DRIFTNewAppsCount $newAppCount

    if ($newAppCount -gt 0) {
        Write-Output "DRIFT DETECTED: $newAppCount new applications"
        Write-Output "New apps: $($newApps -join ', ')"
    } else {
        Write-Output "SUCCESS: No software drift detected"
    }

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
