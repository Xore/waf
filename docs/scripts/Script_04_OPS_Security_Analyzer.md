# Script 04: OPS Security Analyzer

**File:** Script_04_OPS_Security_Analyzer.md  
**Version:** v1.0  
**Script Number:** 04  
**Category:** Core Monitoring - OPS Scores  
**Last Updated:** February 2, 2026

---

## Purpose

Calculate security posture score based on security controls.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Native Integration (v1.0)

- Queries **Antivirus Status** (native) for AV state
- Queries **Patch Status** (native) for update compliance
- Queries **Firewall Status** (native) for firewall state
- Supplements with BitLocker, SMBv1, and hardening checks (custom)

---

## Fields Updated

- [OPSSecurityScore](../core/10_OPS_Core_Operational_Scores.md) (Integer 0-100)
- [OPSLastScoreUpdate](../core/10_OPS_Core_Operational_Scores.md) (DateTime)

---

## Scoring Logic

```text
Base Score: 100

Deductions (using native metrics):
  - Antivirus disabled/not installed (native): -40 points
  - Firewall disabled (native): -30 points
  - BitLocker disabled: -15 points (custom check)
  - Critical patches missing (native): -15 points
  - SMBv1 enabled: -10 points (custom check)

Minimum Score: 0
```

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Security Analyzer (v1.0 Native-Enhanced)"

    $securityScore = 100

    # Check Antivirus status (native query)
    $avProduct = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
    if (-not $avProduct) {
        $securityScore -= 40
        Write-Output "DEDUCTION: Antivirus not installed (-40)"
    } elseif ($avProduct.productState -band 0x1000) {
        Write-Output "OK: Antivirus enabled"
    } else {
        $securityScore -= 40
        Write-Output "DEDUCTION: Antivirus disabled (-40)"
    }

    # Check Windows Firewall status (native)
    $firewall = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    $firewallDisabled = $firewall | Where-Object { $_.Enabled -eq $false }
    if ($firewallDisabled) {
        $securityScore -= 30
        Write-Output "DEDUCTION: Firewall disabled (-30)"
    } else {
        Write-Output "OK: Firewall enabled"
    }

    # Check BitLocker status (custom check)
    $bitlocker = Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue
    if ($bitlocker.ProtectionStatus -ne 'On') {
        $securityScore -= 15
        Write-Output "DEDUCTION: BitLocker not enabled (-15)"
    } else {
        Write-Output "OK: BitLocker enabled"
    }

    # Check critical patches (native)
    $criticalPatches = Ninja-Property-Get UPDMissingCriticalCount
    if ([string]::IsNullOrEmpty($criticalPatches)) { $criticalPatches = 0 }
    if ($criticalPatches -gt 0) {
        $securityScore -= 15
        Write-Output "DEDUCTION: $criticalPatches critical patches missing (-15)"
    } else {
        Write-Output "OK: No critical patches missing"
    }

    # Check SMBv1 status (custom check)
    $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
    if ($smbv1.State -eq 'Enabled') {
        $securityScore -= 10
        Write-Output "DEDUCTION: SMBv1 enabled (-10)"
    } else {
        Write-Output "OK: SMBv1 disabled"
    }

    # Ensure score stays within bounds
    if ($securityScore -lt 0) { $securityScore = 0 }
    if ($securityScore -gt 100) { $securityScore = 100 }

    Ninja-Property-Set OPSSecurityScore $securityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Security Score = $securityScore"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [OPS Custom Fields](../core/10_OPS_Core_Operational_Scores.md)
- [SEC Security Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [UPD Update Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [Script 10: Update Assessment Collector](Script_10_UPD_Update_Assessment_Collector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_04_OPS_Security_Analyzer.md  
**Version:** v1.0  
**Status:** Production Ready
