# Script 23: UPD Patch Compliance Aging Analyzer

**File:** Script_23_UPD_Patch_Compliance_Aging.md  
**Version:** v1.0  
**Script Number:** 23  
**Category:** Extended Automation - Patch Compliance  
**Last Updated:** February 2, 2026

---

## Purpose

Track patch compliance aging and identify systems falling behind on updates.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [UPDPatchAgeDays](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)
- [UPDPatchComplianceLabel](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Dropdown: Current, Aging, Stale, Critical)

---

## PowerShell Implementation

```powershell
# Script 23: Patch Compliance Aging Analyzer
# Track patch compliance aging

param()

try {
    Write-Output "Starting Patch Compliance Aging Analyzer (v1.0)"

    # Query Windows Update using COM object
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    
    Write-Output "Searching for update history..."
    $updateHistory = $updateSearcher.QueryHistory(0, 50)

    # Find most recent successful installation
    $lastInstallDate = $null
    for ($i = 0; $i -lt $updateHistory.Count; $i++) {
        $update = $updateHistory.Item($i)
        if ($update.ResultCode -eq 2) {  # 2 = Succeeded
            if ($null -eq $lastInstallDate -or $update.Date -gt $lastInstallDate) {
                $lastInstallDate = $update.Date
            }
        }
    }

    # Calculate patch age
    if ($null -ne $lastInstallDate) {
        $patchAgeDays = ((Get-Date) - $lastInstallDate).Days
    } else {
        # No update history found - use OS install date
        $os = Get-CimInstance Win32_OperatingSystem
        $patchAgeDays = ((Get-Date) - $os.InstallDate).Days
    }

    # Determine compliance label
    if ($patchAgeDays -le 30) {
        $complianceLabel = "Current"
    } elseif ($patchAgeDays -le 60) {
        $complianceLabel = "Aging"
    } elseif ($patchAgeDays -le 90) {
        $complianceLabel = "Stale"
    } else {
        $complianceLabel = "Critical"
    }

    # Check for missing critical patches
    Write-Output "Checking for missing updates..."
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
    
    $criticalCount = 0
    foreach ($update in $searchResult.Updates) {
        if ($update.MsrcSeverity -eq "Critical") {
            $criticalCount++
        }
    }

    # Override label if critical patches missing
    if ($criticalCount -gt 0) {
        $complianceLabel = "Critical"
    }

    # Update custom fields
    Ninja-Property-Set updPatchAgeDays $patchAgeDays
    Ninja-Property-Set updPatchComplianceLabel $complianceLabel

    Write-Output "SUCCESS: Patch compliance analysis completed"
    Write-Output "  Last Patch Install: $lastInstallDate"
    Write-Output "  Patch Age: $patchAgeDays days"
    Write-Output "  Compliance Label: $complianceLabel"
    Write-Output "  Missing Critical Patches: $criticalCount"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [UPD Update Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [Script 10: Update Assessment Collector](Script_10_UPD_Update_Assessment_Collector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_23_UPD_Patch_Compliance_Aging.md  
**Version:** v1.0  
**Status:** Production Ready
