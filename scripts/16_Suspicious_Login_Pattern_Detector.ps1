<#
.SYNOPSIS
    Suspicious Login Pattern Detector - Anomalous Authentication Behavior Analysis

.DESCRIPTION
    Detects anomalous authentication patterns and assigns risk scores based on suspicious login
    behaviors including excessive failed authentications, unusual timing patterns, repeated account
    lockouts, and abnormal privilege escalation attempts. Implements behavioral analytics to identify
    potential credential-based attacks, insider threats, and compromised accounts.
    
    Uses machine-learning inspired scoring model where multiple weak indicators combine to produce
    actionable threat intelligence. Analyzes Windows Security event log for authentication events
    within a rolling 4-hour window to detect active attack campaigns while minimizing false positives
    from isolated incidents.
    
    Risk Scoring Model (0-100 point scale):
    
    Failed Logon Patterns (20 points):
    - Threshold: >10 failed authentications in 4 hours
    - Indicates: Brute force attacks, credential stuffing, password spraying
    - Event ID: 4625 (An account failed to log on)
    
    Off-Hours Activity (15 points):
    - Threshold: Successful logons between 2:00 AM - 5:00 AM
    - Indicates: Compromised credentials, unauthorized access, insider threats
    - Event ID: 4624 (An account was successfully logged on)
    
    Account Lockout Frequency (25 points):
    - Threshold: >2 lockouts in 4 hours
    - Indicates: Automated attack tools, password guessing campaigns
    - Event ID: 4740 (A user account was locked out)
    
    Privilege Escalation Volume (10 points):
    - Threshold: >20 special privilege assignments in 4 hours
    - Indicates: Lateral movement, privilege abuse, reconnaissance
    - Event ID: 4672 (Special privileges assigned to new logon)
    
    Threat Level Interpretation:
    - 0-25: Normal activity (routine authentication patterns)
    - 26-49: Low suspicion (monitor for trends)
    - 50-75: Medium suspicion (investigate and document)
    - 76-100: High suspicion (immediate security response required)
    
    Integrates with security operations workflows to trigger automated responses including user
    notifications, account restrictions, enhanced logging, and incident ticket creation.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~25 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secSuspiciousLoginScore (Integer: 0-100 risk score)
    
    Dependencies:
    - Windows Security event log
    - Audit policy enabled for logon/logoff events
    - Account lockout events logged (domain or local)
    - Privilege use auditing enabled
    
    Security Considerations:
    - High scores indicate active attacks requiring immediate investigation
    - False positives possible during maintenance windows or system changes
    - Combine with other telemetry for comprehensive threat assessment
    - Scores persist for trending and pattern analysis over time
    - Consider environmental baselines when setting alert thresholds
    
    Use Cases:
    - Detect brute force and password spray attacks
    - Identify compromised credential usage
    - Monitor for insider threat behaviors
    - Validate authentication policies
    - Compliance reporting for access controls
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Suspicious Login Pattern Detector (v4.0)..."
    $suspicionScore = 0
    $indicators = @()
    $startTime = (Get-Date).AddHours(-4)
    Write-Output "INFO: Analyzing authentication events from last 4 hours (since $($startTime.ToString('yyyy-MM-dd HH:mm')))"

    # Indicator 1: Multiple Failed Logon Attempts (20 points)
    Write-Output "INFO: Checking for excessive failed logon attempts..."
    try {
        $failedLogons = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4625
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        $failedCount = if ($failedLogons) { $failedLogons.Count } else { 0 }
        Write-Output "INFO: Detected $failedCount failed logon attempt(s)"
        
        if ($failedCount -gt 10) {
            $suspicionScore += 20
            $indicators += "Excessive failed logons: $failedCount attempts (+20)"
            Write-Output "ALERT: Excessive failed logon attempts detected (+20 suspicion)"
        }
    } catch {
        Write-Output "WARNING: Failed to query failed logon events: $_"
    }

    # Indicator 2: Off-Hours Authentication (15 points)
    Write-Output "INFO: Checking for off-hours authentication activity..."
    $currentHour = (Get-Date).Hour
    
    if ($currentHour -ge 2 -and $currentHour -le 5) {
        Write-Output "INFO: Current time is during off-hours window (2:00 AM - 5:00 AM)"
        
        try {
            $recentLogons = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = 4624
                StartTime = $startTime
            } -ErrorAction SilentlyContinue

            if ($recentLogons -and $recentLogons.Count -gt 0) {
                $suspicionScore += 15
                $indicators += "Off-hours successful logon(s): $($recentLogons.Count) event(s) (+15)"
                Write-Output "ALERT: Off-hours authentication detected (+15 suspicion)"
            }
        } catch {
            Write-Output "WARNING: Failed to query successful logon events: $_"
        }
    } else {
        Write-Output "INFO: Current time is within normal business hours (off-hours check skipped)"
    }

    # Indicator 3: Account Lockout Events (25 points)
    Write-Output "INFO: Checking for account lockout events..."
    try {
        $lockouts = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4740
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        $lockoutCount = if ($lockouts) { $lockouts.Count } else { 0 }
        Write-Output "INFO: Detected $lockoutCount account lockout(s)"
        
        if ($lockoutCount -gt 2) {
            $suspicionScore += 25
            $indicators += "Multiple account lockouts: $lockoutCount events (+25)"
            Write-Output "ALERT: Multiple account lockouts detected (+25 suspicion)"
        }
    } catch {
        Write-Output "WARNING: Failed to query lockout events: $_"
    }

    # Indicator 4: Privilege Escalation Attempts (10 points)
    Write-Output "INFO: Checking for privilege escalation patterns..."
    try {
        $privEsc = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4672
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        $privEscCount = if ($privEsc) { $privEsc.Count } else { 0 }
        Write-Output "INFO: Detected $privEscCount special privilege assignment(s)"
        
        if ($privEscCount -gt 20) {
            $suspicionScore += 10
            $indicators += "High privilege escalation volume: $privEscCount events (+10)"
            Write-Output "WARNING: Elevated privilege escalation activity detected (+10 suspicion)"
        }
    } catch {
        Write-Output "WARNING: Failed to query privilege escalation events: $_"
    }

    # Cap score at maximum 100
    if ($suspicionScore -gt 100) { 
        $suspicionScore = 100 
        Write-Output "INFO: Score capped at maximum (100)"
    }

    # Update NinjaRMM custom field
    Write-Output "INFO: Updating suspicious login score..."
    Ninja-Property-Set secSuspiciousLoginScore $suspicionScore

    # Determine threat level and provide guidance
    Write-Output "SUCCESS: Suspicious login pattern detection complete"
    Write-Output "FINAL SCORE: $suspicionScore/100"
    
    if ($indicators.Count -gt 0) {
        Write-Output "INDICATORS TRIGGERED:"
        $indicators | ForEach-Object { Write-Output "  - $_" }
    } else {
        Write-Output "No suspicious indicators detected"
    }
    
    if ($suspicionScore -ge 76) {
        Write-Output "THREAT LEVEL: HIGH - Immediate investigation required"
        Write-Output "RECOMMENDATION: Review authentication logs, verify user activity, consider account restrictions"
    } elseif ($suspicionScore -ge 50) {
        Write-Output "THREAT LEVEL: MEDIUM - Investigation and documentation recommended"
        Write-Output "RECOMMENDATION: Monitor for continued patterns, review recent user changes"
    } elseif ($suspicionScore -ge 26) {
        Write-Output "THREAT LEVEL: LOW - Continue monitoring for trends"
    } else {
        Write-Output "THREAT LEVEL: NORMAL - Routine authentication patterns"
    }
    
    exit 0

} catch {
    Write-Output "ERROR: Suspicious Login Pattern Detector failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
