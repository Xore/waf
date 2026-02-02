# Script 15: SEC Security Posture Consolidator

**File:** Script_15_SEC_Security_Posture_Consolidator.md  
**Version:** v1.0  
**Script Number:** 15  
**Category:** Extended Automation - Security Consolidation  
**Last Updated:** February 2, 2026

---

## Purpose

Calculate overall security posture score from multiple security controls.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~35 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [SECSecurityPostureScore](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer 0-100)
- [SECFailedLogonCount24h](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)
- [SECAccountLockouts24h](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)

---

## PowerShell Implementation

```powershell
# Script 15: Security Posture Consolidator
# Calculates comprehensive security posture score

param()

try {
    Write-Output "Starting Security Posture Consolidator (v1.0)"

    # Initialize score
    $score = 100

    # Check antivirus
    $avInstalled = Ninja-Property-Get secAntivirusInstalled
    $avEnabled = Ninja-Property-Get secAntivirusEnabled
    $avUpToDate = Ninja-Property-Get secAntivirusUpToDate

    if ($avInstalled -eq $false) { $score -= 40 }
    elseif ($avEnabled -eq $false) { $score -= 30 }
    elseif ($avUpToDate -eq $false) { $score -= 15 }

    # Check firewall
    $fwEnabled = Ninja-Property-Get secFirewallEnabled
    if ($fwEnabled -eq $false) { $score -= 30 }

    # Check BitLocker
    $blEnabled = Ninja-Property-Get secBitLockerEnabled
    if ($blEnabled -eq $false) { $score -= 15 }

    # Check SMBv1
    $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
    if ($smbv1.State -eq "Enabled") { 
        $score -= 10 
        Write-Output "DEDUCTION: SMBv1 enabled (-10)"
    }

    # Check failed logons (last 24 hours)
    $startTime = (Get-Date).AddHours(-24)
    $failedLogons = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

    if ($failedLogons -gt 50) { 
        $score -= 20 
        Write-Output "DEDUCTION: $failedLogons failed logons > 50 (-20)"
    }
    elseif ($failedLogons -gt 20) { 
        $score -= 10 
        Write-Output "DEDUCTION: $failedLogons failed logons > 20 (-10)"
    }
    elseif ($failedLogons -gt 10) { 
        $score -= 5 
        Write-Output "DEDUCTION: $failedLogons failed logons > 10 (-5)"
    }

    # Check account lockouts
    $lockouts = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4740
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

    # Ensure score doesn't go negative
    if ($score -lt 0) { $score = 0 }

    # Update custom fields
    Ninja-Property-Set secSecurityPostureScore $score
    Ninja-Property-Set secFailedLogonCount24h $failedLogons
    Ninja-Property-Set secAccountLockouts24h $lockouts

    Write-Output "SUCCESS: Security Posture Score = $score"
    Write-Output "  Failed Logons (24h): $failedLogons"
    Write-Output "  Account Lockouts (24h): $lockouts"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [SEC Security Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [Script 04: Security Analyzer](Script_04_OPS_Security_Analyzer.md)
- [Script 16: Suspicious Login Detector](Script_16_SEC_Suspicious_Login_Detector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_15_SEC_Security_Posture_Consolidator.md  
**Version:** v1.0  
**Status:** Production Ready
