<#
.SYNOPSIS
    NinjaRMM Script 32: Compliance and Attestation Reporter

.DESCRIPTION
    Generates compliance attestation based on security posture,
    patch status, and backup verification.

.NOTES
    Frequency: Daily
    Runtime: ~15 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - compComplianceScore (Integer 0-100)
    - compAttestationStatus (Dropdown: Compliant, Non-Compliant, Partial, Unknown)
    - compLastAttestationDate (DateTime)
    - compNonCompliantReasons (Text)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    $complianceScore = 100
    $nonCompliantReasons = @()

    # Check 1: Patch Status
    $criticalMissing = Ninja-Property-Get updMissingCriticalCount
    if ($criticalMissing -and $criticalMissing -gt 0) {
        $complianceScore -= 30
        $nonCompliantReasons += "$criticalMissing critical patches missing"
    }

    # Check 2: Antivirus Status
    $realtimeProtection = Ninja-Property-Get secRealtimeProtectionOn
    if ($realtimeProtection -ne $true) {
        $complianceScore -= 25
        $nonCompliantReasons += "Realtime protection disabled"
    }

    # Check 3: Firewall Status
    $firewallEnabled = Ninja-Property-Get secFirewallEnabled
    if ($firewallEnabled -ne $true) {
        $complianceScore -= 20
        $nonCompliantReasons += "Firewall disabled"
    }

    # Check 4: Backup Status
    $lastBackup = Ninja-Property-Get backupLastSuccess
    if ($lastBackup) {
        $backupAge = (Get-Date) - [datetime]$lastBackup
        if ($backupAge.TotalDays -gt 7) {
            $complianceScore -= 15
            $nonCompliantReasons += "Backup older than 7 days"
        }
    } else {
        $complianceScore -= 20
        $nonCompliantReasons += "No backup data"
    }

    # Check 5: Encryption Status
    $encryptionEnabled = Ninja-Property-Get secEncryptionEnabled
    if ($encryptionEnabled -ne $true) {
        $complianceScore -= 10
        $nonCompliantReasons += "Disk encryption not enabled"
    }

    # Ensure score doesn't go below 0
    if ($complianceScore -lt 0) { $complianceScore = 0 }

    # Determine attestation status
    if ($complianceScore -ge 90) {
        $attestationStatus = "Compliant"
    } elseif ($complianceScore -ge 70) {
        $attestationStatus = "Partial"
    } else {
        $attestationStatus = "Non-Compliant"
    }

    # Update custom fields
    Ninja-Property-Set compComplianceScore $complianceScore
    Ninja-Property-Set compAttestationStatus $attestationStatus
    Ninja-Property-Set compLastAttestationDate (Get-Date)

    if ($nonCompliantReasons.Count -gt 0) {
        Ninja-Property-Set compNonCompliantReasons ($nonCompliantReasons -join "; ")
    } else {
        Ninja-Property-Set compNonCompliantReasons "Fully compliant"
    }

    Write-Output "Compliance Score: $complianceScore | Status: $attestationStatus"

} catch {
    Write-Output "Error: $_"
    exit 1
}
