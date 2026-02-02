# Script 14: DRIFT Local Admin Analyzer

**File:** Script_14_DRIFT_Local_Admin_Analyzer.md  
**Version:** v1.0  
**Script Number:** 14  
**Category:** Extended Automation - Admin Drift Detection  
**Last Updated:** February 2, 2026

---

## Purpose

Detect unauthorized local administrator changes.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [DRIFTLocalAdminDrift](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (Checkbox)
- [DRIFTLocalAdminDriftMagnitude](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (Dropdown: None, Minor, Moderate, Significant)

---

## PowerShell Implementation

```powershell
# Script 14: Local Admin Drift Analyzer
# Detects changes to local administrators group

param()

try {
    Write-Output "Starting Local Admin Drift Analyzer (v1.0)"

    # Get current local administrators
    $currentAdmins = Get-LocalGroupMember -Group "Administrators" | 
        Select-Object -ExpandProperty Name

    # Get baseline from custom field
    $baselineAdmins = Ninja-Property-Get baseLocalAdmins

    if ([string]::IsNullOrEmpty($baselineAdmins)) {
        Write-Output "Baseline not established. Run Script 18 first."
        exit 0
    }

    # Parse baseline
    $baselineList = $baselineAdmins -split ','

    # Compare
    $added = $currentAdmins | Where-Object {$_ -notin $baselineList}
    $removed = $baselineList | Where-Object {$_ -notin $currentAdmins}

    $driftDetected = ($added.Count -gt 0 -or $removed.Count -gt 0)

    # Calculate magnitude
    $totalChanges = $added.Count + $removed.Count
    if ($totalChanges -eq 0) {
        $magnitude = "None"
    } elseif ($totalChanges -le 2) {
        $magnitude = "Minor"
    } elseif ($totalChanges -le 5) {
        $magnitude = "Moderate"
    } else {
        $magnitude = "Significant"
    }

    # Update custom fields
    Ninja-Property-Set driftLocalAdminDrift $driftDetected
    Ninja-Property-Set driftLocalAdminDriftMagnitude $magnitude

    if ($driftDetected) {
        $details = "Added: $($added -join ', ') | Removed: $($removed -join ', ')"
        Write-Output "DRIFT DETECTED: $details"
        Write-Output "Magnitude: $magnitude"
    } else {
        Write-Output "SUCCESS: No drift detected"
    }

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
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_14_DRIFT_Local_Admin_Analyzer.md  
**Version:** v1.0  
**Status:** Production Ready
