<#
.SYNOPSIS
    Security Analyzer - Security Posture Score and Control Validation

.DESCRIPTION
    Calculates comprehensive security posture score by evaluating critical security controls
    including antivirus protection, firewall configuration, disk encryption, protocol security,
    and patch compliance. Provides weighted scoring model to quantify overall security posture.
    
    Implements defense-in-depth assessment by checking multiple security layers from endpoint
    protection to data encryption. Uses 100-point scoring system with significant deductions
    for missing or disabled security controls that expose the system to threats.
    
    Security Scoring Model (100 points, deductions applied):
    
    Antivirus Protection (40 points maximum):
    - No antivirus installed: -40 points (critical vulnerability)
    - Antivirus disabled: -30 points (severe risk)
    - Antivirus enabled: 0 deduction
    
    Firewall Protection (30 points maximum):
    - Any firewall profile disabled: -30 points
    - All profiles enabled: 0 deduction
    
    Disk Encryption (15 points maximum):
    - BitLocker not enabled on C: -15 points
    - BitLocker protection on: 0 deduction
    
    Protocol Security (10 points maximum):
    - SMBv1 protocol enabled: -10 points (known vulnerability)
    - SMBv1 disabled: 0 deduction
    
    Patch Compliance (15 points maximum):
    - Critical patches missing: -15 points
    - All critical patches installed: 0 deduction
    
    Score Interpretation:
    - 90-100: Excellent security posture
    - 75-89: Good security posture
    - 60-74: Fair security, gaps exist
    - Below 60: Poor security, immediate action required

.NOTES
    Frequency: Daily
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - OPSSecurityScore (Integer: 0-100 security score)
    - OPSLastScoreUpdate (Text: timestamp in yyyy-MM-dd HH:mm:ss format)
    
    Dependencies:
    - WMI/CIM: root/SecurityCenter2 AntiVirusProduct class
    - Get-NetFirewallProfile cmdlet
    - Get-BitLockerVolume cmdlet (requires BitLocker feature)
    - Get-WindowsOptionalFeature cmdlet
    - Microsoft.Update.Session COM object
    
    Security Standards Alignment:
    - CIS Controls: Antivirus, firewall, encryption, patching
    - NIST Cybersecurity Framework: Protect function
    - Microsoft Security Baseline recommendations
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Security Analyzer (v4.0)..."

    # Initialize security score at maximum
    $securityScore = 100
    $findings = @()

    # Check 1: Antivirus Protection (40 points)
    Write-Output "INFO: Checking antivirus protection..."
    $avProduct = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
    
    if (-not $avProduct) {
        $securityScore -= 40
        $avStatus = "Not Installed"
        $findings += "No antivirus installed (-40)"
        Write-Output "CRITICAL: No antivirus product detected (-40 points)"
    } elseif ($avProduct.productState -band 0x1000) {
        $avStatus = "Enabled"
        Write-Output "PASS: Antivirus is enabled ($($avProduct.displayName))"
    } else {
        $securityScore -= 30
        $avStatus = "Disabled"
        $findings += "Antivirus disabled (-30)"
        Write-Output "CRITICAL: Antivirus is disabled (-30 points)"
    }

    # Check 2: Firewall Protection (30 points)
    Write-Output "INFO: Checking firewall configuration..."
    $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    $fwDisabled = ($firewallProfiles | Where-Object { $_.Enabled -eq $false }).Count
    
    if ($fwDisabled -gt 0) {
        $securityScore -= 30
        $findings += "$fwDisabled firewall profile(s) disabled (-30)"
        Write-Output "CRITICAL: $fwDisabled firewall profile(s) disabled (-30 points)"
        $firewallProfiles | Where-Object { $_.Enabled -eq $false } | ForEach-Object {
            Write-Output "  - $($_.Name) profile is DISABLED"
        }
    } else {
        Write-Output "PASS: All firewall profiles enabled"
    }

    # Check 3: BitLocker Encryption (15 points)
    Write-Output "INFO: Checking BitLocker encryption..."
    try {
        $bitlocker = Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue
        if ($bitlocker.ProtectionStatus -ne 'On') {
            $securityScore -= 15
            $findings += "BitLocker not enabled on C: (-15)"
            Write-Output "WARNING: BitLocker protection is OFF on C: drive (-15 points)"
        } else {
            Write-Output "PASS: BitLocker protection is ON for C: drive"
        }
    } catch {
        $securityScore -= 15
        $findings += "BitLocker check failed (-15)"
        Write-Output "WARNING: Unable to check BitLocker status, assuming not protected (-15 points)"
    }

    # Check 4: SMBv1 Protocol (10 points)
    Write-Output "INFO: Checking SMBv1 protocol status..."
    try {
        $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
        if ($smbv1.State -eq 'Enabled') {
            $securityScore -= 10
            $findings += "SMBv1 protocol enabled (-10)"
            Write-Output "WARNING: SMBv1 protocol is enabled (known security vulnerability, -10 points)"
        } else {
            Write-Output "PASS: SMBv1 protocol is disabled or not present"
        }
    } catch {
        Write-Output "INFO: Unable to check SMBv1 status (assuming safe)"
    }

    # Check 5: Critical Updates (15 points)
    Write-Output "INFO: Checking for critical updates..."
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0 AND Type='Software'")
        $criticalUpdates = ($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq 'Critical' }).Count
        
        if ($criticalUpdates -gt 0) {
            $securityScore -= 15
            $findings += "$criticalUpdates critical update(s) missing (-15)"
            Write-Output "WARNING: $criticalUpdates critical update(s) missing (-15 points)"
        } else {
            Write-Output "PASS: No critical updates pending"
        }
    } catch {
        Write-Output "WARNING: Unable to check Windows Update status: $_"
    }

    # Enforce score boundaries
    if ($securityScore -lt 0) { $securityScore = 0 }
    if ($securityScore -gt 100) { $securityScore = 100 }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating security metrics..."
    Ninja-Property-Set OPSSecurityScore $securityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Security analysis complete"
    Write-Output "FINAL SCORE: $securityScore/100"
    Write-Output "CONTROL STATUS:"
    Write-Output "  - Antivirus: $avStatus"
    Write-Output "  - Firewall Profiles Disabled: $fwDisabled"
    
    if ($findings.Count -gt 0) {
        Write-Output "SECURITY GAPS IDENTIFIED:"
        $findings | ForEach-Object { Write-Output "  - $_" }
    } else {
        Write-Output "All security controls passed"
    }
    
    # Provide security assessment
    if ($securityScore -ge 90) {
        Write-Output "ASSESSMENT: Excellent security posture"
    } elseif ($securityScore -ge 75) {
        Write-Output "ASSESSMENT: Good security posture"
    } elseif ($securityScore -ge 60) {
        Write-Output "ASSESSMENT: Fair security - gaps exist, remediation recommended"
    } else {
        Write-Output "ASSESSMENT: Poor security - immediate action required"
    }

    exit 0
} catch {
    Write-Output "ERROR: Security Analyzer failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
