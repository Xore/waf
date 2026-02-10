# Script 24: PRED Device Lifetime and Replacement Predictor

**File:** Script_24_PRED_Device_Lifetime_Predictor.md  
**Version:** v1.0  
**Script Number:** 24  
**Category:** Extended Automation - Predictive Analytics  
**Last Updated:** February 2, 2026

---

## Purpose

Predict device replacement needs based on age, hardware health, and performance trends.

---

## Execution Details

- **Frequency:** Weekly
- **Runtime:** ~25 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- PREDFailureLikelihood (Dropdown: Low, Medium, High, Critical)
- PREDReplacementScore (Integer 0-100)
- PREDReplacementWindow (Dropdown: None, 12+ months, 6-12 months, 3-6 months, Immediate)

---

## PowerShell Implementation

```powershell
# Script 24: Device Lifetime and Replacement Predictor
# Predict device replacement needs

param()

try {
    Write-Output "Starting Device Lifetime Predictor (v1.0)"

    $replacementScore = 0

    # Get device age
    $os = Get-CimInstance Win32_OperatingSystem
    $installDate = $os.InstallDate
    $deviceAgeDays = ((Get-Date) - $installDate).Days
    $deviceAgeYears = [math]::Round($deviceAgeDays / 365, 1)

    # Age scoring
    if ($deviceAgeYears -gt 5) {
        $replacementScore += 40
    } elseif ($deviceAgeYears -gt 4) {
        $replacementScore += 25
    } elseif ($deviceAgeYears -gt 3) {
        $replacementScore += 15
    }

    # Check hardware health indicators
    $healthScore = Ninja-Property-Get OPSHealthScore
    if ([string]::IsNullOrEmpty($healthScore)) { $healthScore = 70 }

    if ($healthScore -lt 40) {
        $replacementScore += 30
    } elseif ($healthScore -lt 60) {
        $replacementScore += 15
    }

    # Check SMART status
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    $unhealthyDisks = ($disks | Where-Object {$_.HealthStatus -ne "Healthy"}).Count
    
    if ($unhealthyDisks -gt 0) {
        $replacementScore += 20
    }

    # Check performance degradation
    $performanceScore = Ninja-Property-Get OPSPerformanceScore
    if ([string]::IsNullOrEmpty($performanceScore)) { $performanceScore = 70 }

    if ($performanceScore -lt 50) {
        $replacementScore += 15
    }

    # Cap at 100
    if ($replacementScore -gt 100) { $replacementScore = 100 }

    # Determine failure likelihood
    if ($replacementScore -ge 75) {
        $failureLikelihood = "Critical"
    } elseif ($replacementScore -ge 50) {
        $failureLikelihood = "High"
    } elseif ($replacementScore -ge 25) {
        $failureLikelihood = "Medium"
    } else {
        $failureLikelihood = "Low"
    }

    # Determine replacement window
    if ($replacementScore -ge 80) {
        $replacementWindow = "Immediate"
    } elseif ($replacementScore -ge 60) {
        $replacementWindow = "3-6 months"
    } elseif ($replacementScore -ge 40) {
        $replacementWindow = "6-12 months"
    } elseif ($replacementScore -ge 20) {
        $replacementWindow = "12+ months"
    } else {
        $replacementWindow = "None"
    }

    # Update custom fields
    Ninja-Property-Set predFailureLikelihood $failureLikelihood
    Ninja-Property-Set predReplacementScore $replacementScore
    Ninja-Property-Set predReplacementWindow $replacementWindow

    Write-Output "SUCCESS: Device lifetime prediction completed"
    Write-Output "  Device Age: $deviceAgeYears years"
    Write-Output "  Replacement Score: $replacementScore"
    Write-Output "  Failure Likelihood: $failureLikelihood"
    Write-Output "  Replacement Window: $replacementWindow"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_24_PRED_Device_Lifetime_Predictor.md  
**Version:** v1.0  
**Status:** Production Ready
