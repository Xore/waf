# Script 10: UPD Update Assessment Collector

**File:** Script_10_UPD_Update_Assessment_Collector.md  
**Version:** v1.0  
**Script Number:** 10  
**Category:** Core Monitoring - Update Compliance  
**Last Updated:** February 2, 2026

---

## Purpose

Collect Windows Update compliance data and aggregate patch counts.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Native Integration (v1.0)

- Queries **Patch Status** (native) and aggregates by severity
- Supplements with custom reboot tracking

---

## Fields Updated

- [UPDMissingCriticalCount](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)
- [UPDMissingImportantCount](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)
- [UPDMissingOptionalCount](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)
- [UPDDaysSinceLastReboot](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Update Assessment Collector (v1.0)"

    # Query Windows Update using COM object
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    
    Write-Output "Searching for missing updates..."
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")

    # Initialize counters
    $criticalCount = 0
    $importantCount = 0
    $optionalCount = 0

    # Classify updates by severity
    foreach ($update in $searchResult.Updates) {
        switch ($update.MsrcSeverity) {
            "Critical" { $criticalCount++ }
            "Important" { $importantCount++ }
            default { $optionalCount++ }
        }
    }

    # Calculate days since last reboot
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    $daysSinceReboot = [math]::Round($uptime.TotalDays, 1)

    # Update fields
    Ninja-Property-Set UPDMissingCriticalCount $criticalCount
    Ninja-Property-Set UPDMissingImportantCount $importantCount
    Ninja-Property-Set UPDMissingOptionalCount $optionalCount
    Ninja-Property-Set UPDDaysSinceLastReboot $daysSinceReboot

    Write-Output "SUCCESS: Update assessment completed"
    Write-Output "  Critical Updates Missing: $criticalCount"
    Write-Output "  Important Updates Missing: $importantCount"
    Write-Output "  Optional Updates Missing: $optionalCount"
    Write-Output "  Days Since Reboot: $daysSinceReboot"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [UPD Update Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [Script 04: Security Analyzer](Script_04_OPS_Security_Analyzer.md)
- [Script 09: Risk Classifier](Script_09_RISK_Classifier.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_10_UPD_Update_Assessment_Collector.md  
**Version:** v1.0  
**Status:** Production Ready
