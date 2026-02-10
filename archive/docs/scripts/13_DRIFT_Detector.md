# Script 13: DRIFT Detector

**File:** Script_13_DRIFT_Detector.md  
**Version:** v1.0  
**Script Number:** 13  
**Category:** Core Monitoring - Configuration Drift  
**Last Updated:** February 2, 2026

---

## Purpose

Detect configuration drift and unauthorized software installations.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~25 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [DRIFTNewAppsCount](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (Integer)

---

## Use Cases

- Shadow IT detection
- Compliance monitoring
- Change management validation

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Drift Detector (v1.0)"

    # Get current installed applications
    $currentApps = @()
    
    # Query 64-bit applications
    $currentApps += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName } | 
        Select-Object -ExpandProperty DisplayName
    
    # Query 32-bit applications on 64-bit systems
    if ([Environment]::Is64BitOperatingSystem) {
        $currentApps += Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName } | 
            Select-Object -ExpandProperty DisplayName
    }
    
    # Remove duplicates and sort
    $currentApps = $currentApps | Sort-Object -Unique
    $currentCount = $currentApps.Count

    # Get baseline app list from custom field
    $baselineAppsJson = Ninja-Property-Get DRIFTApplicationBaseline
    
    if ([string]::IsNullOrEmpty($baselineAppsJson)) {
        # First run - establish baseline
        $baselineApps = $currentApps
        $newAppsCount = 0
        
        # Store baseline
        $baselineJson = $baselineApps | ConvertTo-Json -Compress
        Ninja-Property-Set DRIFTApplicationBaseline $baselineJson
        
        Write-Output "Baseline established: $currentCount applications"
    } else {
        # Parse existing baseline
        $baselineApps = $baselineAppsJson | ConvertFrom-Json
        
        # Detect new applications
        $newApps = $currentApps | Where-Object { $_ -notin $baselineApps }
        $newAppsCount = $newApps.Count
        
        if ($newAppsCount -gt 0) {
            Write-Output "DRIFT DETECTED: $newAppsCount new application(s):"
            foreach ($app in $newApps) {
                Write-Output "  - $app"
            }
        } else {
            Write-Output "No new applications detected"
        }
        
        # Optional: Update baseline to include new apps (uncomment if desired)
        # $baselineApps = $currentApps
        # $baselineJson = $baselineApps | ConvertTo-Json -Compress
        # Ninja-Property-Set DRIFTApplicationBaseline $baselineJson
    }

    # Update drift count field
    Ninja-Property-Set DRIFTNewAppsCount $newAppsCount

    Write-Output "SUCCESS: Drift detection completed"
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
- [Script 12: Baseline Manager](Script_12_BASE_Baseline_Manager.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_13_DRIFT_Detector.md  
**Version:** v1.0  
**Status:** Production Ready
