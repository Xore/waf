<#
.SYNOPSIS
    NinjaRMM Script 7: BitLocker Monitor

.DESCRIPTION
    Monitors BitLocker encryption status on all volumes.
    Tracks encryption progress, recovery key escrow, and compliance.

.NOTES
    Frequency: Daily
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secBitLockerEnabled (Checkbox)
    - secBitLockerStatus (Text)
    - blComplianceStatus (Dropdown)
    - blVolumeCount (Integer)
    - blFullyEncryptedCount (Integer)
    - blEncryptionInProgress (Checkbox)
    - blRecoveryKeyEscrowed (Checkbox)
    - blVolumeSummary (WYSIWYG)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
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
        $hasADBackup = $keyProtectors | Where-Object {
            $_.KeyProtectorType -eq "RecoveryPassword" -and
            $_.RecoveryPassword
        }
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
        $encryptionMethod = ($vol.EncryptionMethod -replace "Aes", "AES-")
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

    Write-Output "BitLocker: $compliance | Encrypted: $fullyEncrypted/$volumeCount | Keys Escrowed: $keysEscrowed"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set blComplianceStatus "Unknown"
    exit 1
}
