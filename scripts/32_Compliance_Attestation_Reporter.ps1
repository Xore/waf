<#
.SYNOPSIS
    Compliance and Attestation Reporter - Security Posture Scoring and Compliance Validation

.DESCRIPTION
    Generates comprehensive compliance attestation by evaluating multiple security control areas
    including patch management, endpoint protection, firewall configuration, backup status, and
    disk encryption. Produces scored compliance assessment with detailed non-compliance reasons.
    
    Implements weighted scoring model where critical security controls (patches, antivirus) carry
    higher point values than supplementary controls. Enables automated compliance reporting for
    regulatory frameworks including CIS Controls, NIST Cybersecurity Framework, and industry
    standards like PCI-DSS and HIPAA baseline requirements.
    
    Compliance Scoring Model (100 points total):
    - Critical Patches: 30 points (deducted if missing critical patches)
    - Real-time Protection: 25 points (antivirus/EDR active scanning)
    - Firewall Status: 20 points (Windows Firewall or third-party enabled)
    - Backup Currency: 15-20 points (successful backup within 7 days)
    - Disk Encryption: 10 points (BitLocker or equivalent full-disk encryption)
    
    Attestation Status Thresholds:
    - Compliant: 90-100 points (minimal gaps, production-ready)
    - Partial: 70-89 points (moderate gaps, requires remediation)
    - Non-Compliant: 0-69 points (significant gaps, immediate action required)
    
    Integrates with other WAF monitoring scripts by querying their output fields to build
    comprehensive security posture view without duplicating checks.

.NOTES
    Frequency: Daily
    Runtime: ~15 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - compComplianceScore (Integer: 0-100 point scale)
    - compAttestationStatus (Text: Compliant, Partial, Non-Compliant)
    - compLastAttestationDate (DateTime: timestamp of assessment)
    - compNonCompliantReasons (Text: semicolon-separated list of compliance gaps)
    
    Dependencies:
    - Reads fields from other WAF scripts:
      - updMissingCriticalCount (patch management)
      - secRealtimeProtectionOn (EDR/antivirus)
      - secFirewallEnabled (firewall status)
      - backupLastSuccess (backup validation)
      - secEncryptionEnabled (disk encryption)
    
    Compliance Frameworks Supported:
    - CIS Controls v8 (Critical Security Controls)
    - NIST Cybersecurity Framework
    - ISO 27001 baseline controls
    - PCI-DSS security requirements
    - HIPAA Security Rule technical safeguards
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Compliance and Attestation Reporter (v4.0)..."
    Write-Output "INFO: Evaluating security controls for compliance scoring..."
    
    $complianceScore = 100
    $nonCompliantReasons = @()

    # Check 1: Critical Patch Status (30 points)
    Write-Output "INFO: Checking critical patch status..."
    $criticalMissing = Ninja-Property-Get updMissingCriticalCount
    
    if ($criticalMissing -and $criticalMissing -gt 0) {
        $complianceScore -= 30
        $nonCompliantReasons += "$criticalMissing critical patch(es) missing"
        Write-Output "WARNING: Missing $criticalMissing critical patch(es) (-30 points)"
    } else {
        Write-Output "PASS: No critical patches missing (+30 points)"
    }

    # Check 2: Real-time Antivirus Protection (25 points)
    Write-Output "INFO: Checking real-time protection status..."
    $realtimeProtection = Ninja-Property-Get secRealtimeProtectionOn
    
    if ($realtimeProtection -ne $true) {
        $complianceScore -= 25
        $nonCompliantReasons += "Real-time protection disabled"
        Write-Output "FAIL: Real-time protection is DISABLED (-25 points)"
    } else {
        Write-Output "PASS: Real-time protection is ENABLED (+25 points)"
    }

    # Check 3: Firewall Status (20 points)
    Write-Output "INFO: Checking firewall status..."
    $firewallEnabled = Ninja-Property-Get secFirewallEnabled
    
    if ($firewallEnabled -ne $true) {
        $complianceScore -= 20
        $nonCompliantReasons += "Firewall disabled"
        Write-Output "FAIL: Firewall is DISABLED (-20 points)"
    } else {
        Write-Output "PASS: Firewall is ENABLED (+20 points)"
    }

    # Check 4: Backup Currency (15-20 points)
    Write-Output "INFO: Checking backup currency..."
    $lastBackup = Ninja-Property-Get backupLastSuccess
    
    if ($lastBackup) {
        try {
            $backupDate = [datetime]$lastBackup
            $backupAge = (Get-Date) - $backupDate
            
            if ($backupAge.TotalDays -gt 7) {
                $complianceScore -= 15
                $nonCompliantReasons += "Backup is $([math]::Round($backupAge.TotalDays, 1)) days old (>7 days)"
                Write-Output "WARNING: Backup age $([math]::Round($backupAge.TotalDays, 1)) days exceeds 7-day policy (-15 points)"
            } else {
                Write-Output "PASS: Backup is current ($([math]::Round($backupAge.TotalDays, 1)) days old) (+15 points)"
            }
        } catch {
            $complianceScore -= 20
            $nonCompliantReasons += "Invalid backup date format"
            Write-Output "FAIL: Cannot parse backup date (-20 points)"
        }
    } else {
        $complianceScore -= 20
        $nonCompliantReasons += "No backup data available"
        Write-Output "FAIL: No backup data available (-20 points)"
    }

    # Check 5: Disk Encryption (10 points)
    Write-Output "INFO: Checking disk encryption status..."
    $encryptionEnabled = Ninja-Property-Get secEncryptionEnabled
    
    if ($encryptionEnabled -ne $true) {
        $complianceScore -= 10
        $nonCompliantReasons += "Disk encryption not enabled"
        Write-Output "WARNING: Disk encryption is NOT enabled (-10 points)"
    } else {
        Write-Output "PASS: Disk encryption is ENABLED (+10 points)"
    }

    # Ensure score doesn't go below 0
    if ($complianceScore -lt 0) { 
        $complianceScore = 0 
        Write-Output "INFO: Score floor applied (minimum 0)"
    }

    # Determine attestation status based on score
    if ($complianceScore -ge 90) {
        $attestationStatus = "Compliant"
        Write-Output "STATUS: COMPLIANT (score: $complianceScore/100)"
    } elseif ($complianceScore -ge 70) {
        $attestationStatus = "Partial"
        Write-Output "STATUS: PARTIAL COMPLIANCE (score: $complianceScore/100) - Remediation required"
    } else {
        $attestationStatus = "Non-Compliant"
        Write-Output "STATUS: NON-COMPLIANT (score: $complianceScore/100) - Immediate action required"
    }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating compliance fields..."
    Ninja-Property-Set compComplianceScore $complianceScore
    Ninja-Property-Set compAttestationStatus $attestationStatus
    Ninja-Property-Set compLastAttestationDate (Get-Date)

    if ($nonCompliantReasons.Count -gt 0) {
        $reasonsText = $nonCompliantReasons -join "; "
        Ninja-Property-Set compNonCompliantReasons $reasonsText
        Write-Output "Non-Compliant Items: $reasonsText"
    } else {
        Ninja-Property-Set compNonCompliantReasons "Fully compliant - all controls passed"
        Write-Output "INFO: All compliance controls passed"
    }

    Write-Output "SUCCESS: Compliance attestation complete"
    Write-Output "FINAL SCORE: $complianceScore/100 | STATUS: $attestationStatus | GAPS: $($nonCompliantReasons.Count)"
    
    exit 0

} catch {
    Write-Output "ERROR: Compliance Attestation Reporter failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    
    # Set error state
    Ninja-Property-Set compAttestationStatus "Unknown"
    Ninja-Property-Set compNonCompliantReasons "Assessment failed: $_"
    
    exit 1
}
