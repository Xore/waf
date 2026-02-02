# Script 20: DRIFT Shadow IT Detector

**File:** Script_20_DRIFT_Shadow_IT_Detector.md  
**Version:** v1.0  
**Script Number:** 20  
**Category:** Extended Automation - Software Inventory  
**Last Updated:** February 2, 2026

---

## Purpose

Software inventory baseline and shadow IT detection through unauthorized software monitoring.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [DRIFTNewAppsCount](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (Integer)
- DRIFTNewAppsList (Text) - Comma-separated list of new applications

---

## PowerShell Implementation

```powershell
# Script 20: Software Inventory Baseline and Shadow IT Detector
# Detect unauthorized software installations

param()

try {
    Write-Output "Starting Shadow IT Detector (v1.0)"

    # Get current installed applications
    $currentApps = @()
    
    # Query 64-bit applications
    $currentApps += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -and $_.DisplayName -notmatch "^(KB|Update for)" } | 
        Select-Object -ExpandProperty DisplayName
    
    # Query 32-bit applications on 64-bit systems
    if ([Environment]::Is64BitOperatingSystem) {
        $currentApps += Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -and $_.DisplayName -notmatch "^(KB|Update for)" } | 
            Select-Object -ExpandProperty DisplayName
    }
    
    # Remove duplicates and sort
    $currentApps = $currentApps | Sort-Object -Unique
    $currentCount = $currentApps.Count

    # Get baseline app list from custom field
    $baselineAppsJson = Ninja-Property-Get driftApplicationBaseline
    
    if ([string]::IsNullOrEmpty($baselineAppsJson)) {
        # First run - establish baseline
        $baselineApps = $currentApps
        $newAppsCount = 0
        $newAppsList = ""
        
        # Store baseline as JSON
        $baselineJson = $baselineApps | ConvertTo-Json -Compress
        Ninja-Property-Set driftApplicationBaseline $baselineJson
        
        Write-Output "Baseline established: $currentCount applications"
    } else {
        # Parse existing baseline
        try {
            $baselineApps = $baselineAppsJson | ConvertFrom-Json
        } catch {
            $baselineApps = @()
        }
        
        # Detect new applications
        $newApps = $currentApps | Where-Object { $_ -notin $baselineApps }
        $newAppsCount = $newApps.Count
        $newAppsList = ($newApps | Select-Object -First 10) -join ", "
        
        if ($newAppsCount -gt 10) {
            $newAppsList += "... (+$($newAppsCount - 10) more)"
        }
        
        if ($newAppsCount -gt 0) {
            Write-Output "SHADOW IT DETECTED: $newAppsCount new application(s)"
            foreach ($app in ($newApps | Select-Object -First 5)) {
                Write-Output "  - $app"
            }
            if ($newAppsCount -gt 5) {
                Write-Output "  ... and $($newAppsCount - 5) more"
            }
        } else {
            Write-Output "No new applications detected"
        }
    }

    # Update drift count field
    Ninja-Property-Set driftNewAppsCount $newAppsCount
    if (-not [string]::IsNullOrEmpty($newAppsList)) {
        Ninja-Property-Set driftNewAppsList $newAppsList
    }

    Write-Output "SUCCESS: Shadow IT detection completed"
    Write-Output "  Current Applications: $currentCount"
    Write-Output "  New Applications: $newAppsCount"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [DRIFT Drift Detection Fields](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md)
- [Script 13: Drift Detector](Script_13_DRIFT_Detector.md)
- [Script 14: Local Admin Analyzer](Script_14_DRIFT_Local_Admin_Analyzer.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_20_DRIFT_Shadow_IT_Detector.md  
**Version:** v1.0  
**Status:** Production Ready
