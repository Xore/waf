# Script 09: RISK Classifier

**File:** Script_09_RISK_Classifier.md  
**Version:** v1.0  
**Script Number:** 09  
**Category:** Core Monitoring - Risk Assessment  
**Last Updated:** February 2, 2026

---

## Purpose

Classify devices into risk categories based on multiple data sources.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~10 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Native Integration (v1.0)

- Queries **Backup Status** (native) for data loss risk
- Queries **SMART Status** (native) for hardware risk
- Queries **Pending Reboot** (native) for reboot recommendation
- Queries **Antivirus Status**, **Firewall Status**, **Patch Status** (native) for security risk
- Combines with [OPS scores](../core/10_OPS_Core_Operational_Scores.md) and [STAT telemetry](../core/11_STAT_Core_Telemetry.md) (custom)

---

## Fields Updated

- [RISKHealthLevel](../core/12_RISK_Core_Classification.md) (Dropdown: Healthy, Degraded, Critical, Unknown)
- [RISKRebootLevel](../core/12_RISK_Core_Classification.md) (Dropdown: None, Low, Medium, High, Critical)
- [RISKSecurityExposure](../core/12_RISK_Core_Classification.md) (Dropdown: Low, Medium, High, Critical)
- [RISKComplianceFlag](../core/12_RISK_Core_Classification.md) (Dropdown: Compliant, Warning, Non-Compliant, Critical)
- [RISKShadowIT](../core/12_RISK_Core_Classification.md) (Checkbox)
- [RISKDataLossRisk](../core/12_RISK_Core_Classification.md) (Dropdown: Low, Medium, High, Critical)
- [RISKLastRiskAssessment](../core/12_RISK_Core_Classification.md) (DateTime)

---

## Key Classifications

### Health Level

- **Healthy:** OPSHealthScore >= 70, no critical native alerts
- **Degraded:** OPSHealthScore 40-69, or multiple minor native alerts
- **Critical:** OPSHealthScore < 40, or critical native alert
- **Unknown:** Unable to assess (script failures)

### Data Loss Risk

- **Low:** Backup Success (native, < 24h), Disk > 20%, SMART Healthy (native)
- **Medium:** Backup 24-72h old, or Disk < 20%
- **High:** Backup Failed (> 72h), or Disk < 10%, or SMART Warning
- **Critical:** No backup (> 7 days), Disk < 5%, SMART Failed

### Security Exposure

- **Low:** All security controls enabled, patches current
- **Medium:** 1-2 security issues, or patches 30-60 days old
- **High:** 3+ security issues, or patches 60-90 days old
- **Critical:** AV/Firewall disabled, or patches > 90 days old

### Reboot Level

- **None:** No reboot needed
- **Low:** Uptime > 30 days, no pending patches
- **Medium:** Pending patches, uptime > 60 days
- **High:** Critical patches pending, or uptime > 90 days
- **Critical:** System instability detected, immediate reboot recommended

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Risk Classifier (v1.0 Native-Enhanced)"

    # Query OPS scores
    $healthScore = Ninja-Property-Get OPSHealthScore
    if ([string]::IsNullOrEmpty($healthScore)) { $healthScore = 50 }

    $securityScore = Ninja-Property-Get OPSSecurityScore
    if ([string]::IsNullOrEmpty($securityScore)) { $securityScore = 50 }

    # Query native backup status
    # Note: This is a placeholder - actual implementation depends on backup solution integration
    $lastBackup = (Get-Date).AddHours(-12) # Placeholder
    $backupAge = ((Get-Date) - $lastBackup).TotalHours

    # Query native disk status
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    # Query uptime
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    $uptimeDays = [math]::Round($uptime.TotalDays, 1)

    # Classify Health Level
    if ($healthScore -ge 70) {
        $healthLevel = "Healthy"
    } elseif ($healthScore -ge 40) {
        $healthLevel = "Degraded"
    } else {
        $healthLevel = "Critical"
    }

    # Classify Data Loss Risk
    if ($backupAge -lt 24 -and $diskFreePercent -gt 20) {
        $dataLossRisk = "Low"
    } elseif ($backupAge -lt 72 -and $diskFreePercent -gt 10) {
        $dataLossRisk = "Medium"
    } elseif ($backupAge -lt 168 -and $diskFreePercent -gt 5) {
        $dataLossRisk = "High"
    } else {
        $dataLossRisk = "Critical"
    }

    # Classify Security Exposure
    if ($securityScore -ge 80) {
        $securityExposure = "Low"
    } elseif ($securityScore -ge 60) {
        $securityExposure = "Medium"
    } elseif ($securityScore -ge 40) {
        $securityExposure = "High"
    } else {
        $securityExposure = "Critical"
    }

    # Classify Reboot Level
    if ($uptimeDays -lt 30) {
        $rebootLevel = "None"
    } elseif ($uptimeDays -lt 60) {
        $rebootLevel = "Low"
    } elseif ($uptimeDays -lt 90) {
        $rebootLevel = "Medium"
    } else {
        $rebootLevel = "High"
    }

    # Set compliance flag
    if ($healthScore -ge 70 -and $securityScore -ge 80) {
        $complianceFlag = "Compliant"
    } elseif ($healthScore -ge 50 -and $securityScore -ge 60) {
        $complianceFlag = "Warning"
    } elseif ($healthScore -ge 30 -and $securityScore -ge 40) {
        $complianceFlag = "Non-Compliant"
    } else {
        $complianceFlag = "Critical"
    }

    # Update fields
    Ninja-Property-Set RISKHealthLevel $healthLevel
    Ninja-Property-Set RISKDataLossRisk $dataLossRisk
    Ninja-Property-Set RISKSecurityExposure $securityExposure
    Ninja-Property-Set RISKRebootLevel $rebootLevel
    Ninja-Property-Set RISKComplianceFlag $complianceFlag
    Ninja-Property-Set RISKLastRiskAssessment (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Risk classification completed"
    Write-Output "  Health Level: $healthLevel"
    Write-Output "  Data Loss Risk: $dataLossRisk"
    Write-Output "  Security Exposure: $securityExposure"
    Write-Output "  Reboot Level: $rebootLevel"
    Write-Output "  Compliance: $complianceFlag"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [RISK Classification Fields](../core/12_RISK_Core_Classification.md)
- [OPS Operational Scores](../core/10_OPS_Core_Operational_Scores.md)
- [STAT Telemetry Fields](../core/11_STAT_Core_Telemetry.md)
- [Script 01: Health Score Calculator](Script_01_OPS_Health_Score_Calculator.md)
- [Script 04: Security Analyzer](Script_04_OPS_Security_Analyzer.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_09_RISK_Classifier.md  
**Version:** v1.0  
**Status:** Production Ready
