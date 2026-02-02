# Script 07: BL BitLocker Monitor

**File:** Script_07_BL_BitLocker_Monitor.md  
**Version:** v1.0  
**Script Number:** 07  
**Category:** Infrastructure Monitoring - Encryption  
**Last Updated:** February 2, 2026

---

## Purpose

Monitor BitLocker encryption status on all volumes.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- BLVolumeCount (Integer)
- BLFullyEncryptedCount (Integer)
- BLEncryptionInProgress (Checkbox)
- BLRecoveryKeyEscrowed (Checkbox)
- BLVolumeSummary (Text/HTML)
- BLComplianceStatus (Dropdown: Compliant, Partial, Non-Compliant, Unknown)
- [SECBitLockerEnabled](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Checkbox)
- [SECBitLockerStatus](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Text)

---

## PowerShell Implementation

```powershell
# Script 7: BitLocker Monitor
# Monitors BitLocker encryption status

param()

try {
    Write-Output "Starting BitLocker Monitor (v1.0)"

    # Get all BitLocker volumes
    $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue

    if (-not $volumes) {
        Ninja-Property-Set secBitLockerEnabled $false
        Ninja-Property-Set secBitLockerStatus "Not Enabled"
        Ninja-Property-Set blComplianceStatus "Unknown"
        Write-Output "BitLocker not available"
        exit 0
    }

    # Count volumes by status
    $volumeCount = $volumes.Count
    $fullyEncrypted = 0
    $encrypting = 0
    $decrypted = 0
    $suspended = 0

    foreach ($vol in $volumes) {
        switch ($vol.VolumeStatus) {
            "FullyEncrypted" { $fullyEncrypted++ }
            "EncryptionInProgress" { $encrypting++ }
            "FullyDecrypted" { $decrypted++ }
            "EncryptionSuspended" { $suspended++ }
        }
    }

    Ninja-Property-Set blVolumeCount $volumeCount
    Ninja-Property-Set blFullyEncryptedCount $fullyEncrypted

    # Check if any encryption is in progress
    $encryptionActive = $encrypting -gt 0
    Ninja-Property-Set blEncryptionInProgress $encryptionActive

    # Check if BitLocker is enabled on OS drive
    $osDrive = Get-BitLockerVolume -MountPoint $env:SystemDrive
    $blEnabled = $osDrive.VolumeStatus -eq "FullyEncrypted"
    Ninja-Property-Set secBitLockerEnabled $blEnabled
    Ninja-Property-Set secBitLockerStatus $osDrive.VolumeStatus

    # Check if recovery keys are escrowed to AD
    $keysEscrowed = $true
    foreach ($vol in $volumes) {
        $keyProtectors = $vol.KeyProtector
        $hasADBackup = $keyProtectors | Where-Object {$_.KeyProtectorType -eq "RecoveryPassword" -and $_.RecoveryPassword}
        if (-not $hasADBackup) {
            $keysEscrowed = $false
            break
        }
    }
    Ninja-Property-Set blRecoveryKeyEscrowed $keysEscrowed

    # Generate volume summary HTML
    $html = "<h4>BitLocker Volumes</h4><table>"
    $html += "<tr><th>Drive</th><th>Status</th><th>%</th><th>Method</th></tr>"

    foreach ($vol in $volumes) {
        $encryptionMethod = $vol.EncryptionMethod -replace "Aes", "AES-"
        $html += "<tr>"
        $html += "<td>$($vol.MountPoint)</td>"
        $html += "<td>$($vol.VolumeStatus)</td>"
        $html += "<td>$($vol.EncryptionPercentage)%</td>"
        $html += "<td>$encryptionMethod</td>"
        $html += "</tr>"
    }
    $html += "</table>"
    Ninja-Property-Set blVolumeSummary $html

    # Determine compliance status
    if ($fullyEncrypted -eq $volumeCount -and $keysEscrowed) {
        $compliance = "Compliant"
    } elseif ($fullyEncrypted -gt 0 -or $encrypting -gt 0) {
        $compliance = "Partial"
    } else {
        $compliance = "Non-Compliant"
    }
    Ninja-Property-Set blComplianceStatus $compliance

    Write-Output "SUCCESS: BitLocker compliance: $compliance"
    Write-Output "  Encrypted: $fullyEncrypted/$volumeCount"
    Write-Output "  Keys Escrowed: $keysEscrowed"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set blComplianceStatus "Unknown"
    exit 1
}
```

---

## Related Documentation

- [SEC Security Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [Script 04: Security Analyzer](Script_04_OPS_Security_Analyzer.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_07_BL_BitLocker_Monitor.md  
**Version:** v1.0  
**Status:** Production Ready
