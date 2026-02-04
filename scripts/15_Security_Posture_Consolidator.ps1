<#
.SYNOPSIS
    Security Posture Consolidator - Comprehensive Security Score Aggregation

.DESCRIPTION
    Calculates comprehensive security posture score by aggregating multiple security control
    assessments including endpoint protection, encryption, firewall, protocol security, and
    authentication monitoring. Provides unified security health metric for compliance reporting
    and risk assessment.
    
    Consolidates security telemetry from multiple sources (custom fields populated by other
    scripts) and adds real-time authentication security checks to produce holistic security
    posture score. Enables security operations teams to quickly identify systems with degraded
    security controls.
    
    Security Scoring Model (100 points, deductions applied):
    
    Endpoint Protection (40-45 points):
    - No antivirus installed: -40 points (critical vulnerability)
    - Antivirus disabled: -30 points (severe risk)
    - Antivirus definitions outdated: -15 points (moderate risk)
    
    Firewall Protection (30 points):
    - Firewall disabled: -30 points
    - All profiles enabled: 0 deduction
    
    Disk Encryption (15 points):
    - BitLocker not enabled: -15 points
    - BitLocker protection on: 0 deduction
    
    Protocol Security (10 points):
    - SMBv1 protocol enabled: -10 points (known vulnerability)
    - SMBv1 disabled: 0 deduction
    
    Authentication Security (20 points):
    - Failed logons >50 in 24h: -20 points (attack likely)
    - Failed logons >20 in 24h: -10 points (suspicious activity)
    - Failed logons >10 in 24h: -5 points (elevated activity)
    - Failed logons <=10: 0 deduction
    
    Score Interpretation:
    - 90-100: Excellent security posture
    - 75-89: Good security posture
    - 60-74: Fair security, gaps exist
    - Below 60: Poor security, immediate action required
    
    Integration Pattern:
    - Reads security control states from fields populated by other WAF scripts
    - Performs real-time authentication monitoring (failed logons, lockouts)
    - Produces consolidated score for dashboards and alerting

.NOTES
    Frequency: Daily
    Runtime: ~35 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secSecurityPostureScore (Integer: 0-100 consolidated security score)
    - secFailedLogonCount24h (Integer: failed logon attempts in last 24 hours)
    - secAccountLockouts24h (Integer: account lockout events in last 24 hours)
    
    Fields Read (from other scripts):
    - secAntivirusInstalled (Checkbox: from endpoint protection scripts)
    - secAntivirusEnabled (Checkbox: from endpoint protection scripts)
    - secAntivirusUpToDate (Checkbox: from endpoint protection scripts)
    - secFirewallEnabled (Checkbox: from firewall monitoring)
    - secBitLockerEnabled (Checkbox: from BitLocker monitoring)
    
    Dependencies:
    - Windows Security event log
    - Get-WindowsOptionalFeature cmdlet
    - Security monitoring scripts must run first (30_Advanced_Threat_Telemetry, etc.)
    
    Event IDs Monitored:
    - 4625: Failed logon attempt
    - 4740: User account locked out
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Security Posture Consolidator (v4.0)..."

    # Initialize score at maximum
    $score = 100
    $findings = @()

    # Check 1: Antivirus Protection (40-45 points)
    Write-Output "INFO: Evaluating endpoint protection..."
    $avInstalled = Ninja-Property-Get secAntivirusInstalled
    $avEnabled = Ninja-Property-Get secAntivirusEnabled
    $avUpToDate = Ninja-Property-Get secAntivirusUpToDate

    if ($avInstalled -eq $false) {
        $score -= 40
        $findings += "No antivirus installed (-40)"
        Write-Output "CRITICAL: No antivirus installed (-40 points)"
    } elseif ($avEnabled -eq $false) {
        $score -= 30
        $findings += "Antivirus disabled (-30)"
        Write-Output "CRITICAL: Antivirus disabled (-30 points)"
    } elseif ($avUpToDate -eq $false) {
        $score -= 15
        $findings += "Antivirus definitions outdated (-15)"
        Write-Output "WARNING: Antivirus definitions outdated (-15 points)"
    } else {
        Write-Output "PASS: Endpoint protection is current"
    }

    # Check 2: Firewall Protection (30 points)
    Write-Output "INFO: Evaluating firewall status..."
    $fwEnabled = Ninja-Property-Get secFirewallEnabled
    
    if ($fwEnabled -eq $false) {
        $score -= 30
        $findings += "Firewall disabled (-30)"
        Write-Output "CRITICAL: Firewall disabled (-30 points)"
    } else {
        Write-Output "PASS: Firewall enabled"
    }

    # Check 3: BitLocker Encryption (15 points)
    Write-Output "INFO: Evaluating disk encryption..."
    $blEnabled = Ninja-Property-Get secBitLockerEnabled
    
    if ($blEnabled -eq $false) {
        $score -= 15
        $findings += "BitLocker not enabled (-15)"
        Write-Output "WARNING: BitLocker not enabled (-15 points)"
    } else {
        Write-Output "PASS: BitLocker encryption enabled"
    }

    # Check 4: SMBv1 Protocol (10 points)
    Write-Output "INFO: Checking SMBv1 protocol status..."
    try {
        $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
        if ($smbv1 -and $smbv1.State -eq "Enabled") {
            $score -= 10
            $findings += "SMBv1 protocol enabled (-10)"
            Write-Output "WARNING: SMBv1 protocol enabled (known vulnerability, -10 points)"
        } else {
            Write-Output "PASS: SMBv1 protocol disabled or not present"
        }
    } catch {
        Write-Output "INFO: Unable to check SMBv1 status"
    }

    # Check 5: Authentication Security - Failed Logons (20 points)
    Write-Output "INFO: Analyzing authentication security..."
    $startTime = (Get-Date).AddHours(-24)
    
    Write-Output "INFO: Checking failed logon attempts (Event ID 4625)..."
    try {
        $failedLogons = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4625
            StartTime = $startTime
        } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
        
        if ($null -eq $failedLogons) { $failedLogons = 0 }
        
        if ($failedLogons -gt 50) {
            $score -= 20
            $findings += "Excessive failed logons: $failedLogons (-20)"
            Write-Output "ALERT: Excessive failed logons ($failedLogons) - possible attack (-20 points)"
        } elseif ($failedLogons -gt 20) {
            $score -= 10
            $findings += "High failed logons: $failedLogons (-10)"
            Write-Output "WARNING: High failed logon count ($failedLogons) - suspicious activity (-10 points)"
        } elseif ($failedLogons -gt 10) {
            $score -= 5
            $findings += "Elevated failed logons: $failedLogons (-5)"
            Write-Output "INFO: Elevated failed logon count ($failedLogons) (-5 points)"
        } else {
            Write-Output "PASS: Failed logon count acceptable ($failedLogons)"
        }
    } catch {
        Write-Output "WARNING: Unable to query failed logon events"
        $failedLogons = 0
    }

    # Check 6: Account Lockouts (informational)
    Write-Output "INFO: Checking account lockout events (Event ID 4740)..."
    try {
        $lockouts = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4740
            StartTime = $startTime
        } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
        
        if ($null -eq $lockouts) { $lockouts = 0 }
        
        if ($lockouts -gt 0) {
            Write-Output "INFO: Detected $lockouts account lockout(s) in last 24 hours"
        } else {
            Write-Output "PASS: No account lockouts detected"
        }
    } catch {
        Write-Output "WARNING: Unable to query lockout events"
        $lockouts = 0
    }

    # Enforce score boundaries
    if ($score -lt 0) { $score = 0 }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating security posture fields..."
    Ninja-Property-Set secSecurityPostureScore $score
    Ninja-Property-Set secFailedLogonCount24h $failedLogons
    Ninja-Property-Set secAccountLockouts24h $lockouts

    Write-Output "SUCCESS: Security posture consolidation complete"
    Write-Output "CONSOLIDATED SCORE: $score/100"
    Write-Output "AUTHENTICATION METRICS:"
    Write-Output "  - Failed Logons (24h): $failedLogons"
    Write-Output "  - Account Lockouts (24h): $lockouts"
    
    if ($findings.Count -gt 0) {
        Write-Output "SECURITY GAPS IDENTIFIED:"
        $findings | ForEach-Object { Write-Output "  - $_" }
    } else {
        Write-Output "All security controls passed"
    }
    
    # Provide security posture assessment
    if ($score -ge 90) {
        Write-Output "SECURITY POSTURE: Excellent"
    } elseif ($score -ge 75) {
        Write-Output "SECURITY POSTURE: Good"
    } elseif ($score -ge 60) {
        Write-Output "SECURITY POSTURE: Fair - gaps exist, remediation recommended"
    } else {
        Write-Output "SECURITY POSTURE: Poor - immediate action required"
    }

    exit 0
} catch {
    Write-Output "ERROR: Security Posture Consolidator failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
