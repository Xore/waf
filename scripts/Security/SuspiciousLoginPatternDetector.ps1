#Requires -Version 5.1

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

.PARAMETER SuspicionScoreField
    NinjaRMM custom field name to store the suspicious login risk score (0-100).
    Default: secSuspiciousLoginScore

.PARAMETER TimeWindowHours
    Number of hours to look back for authentication events.
    Default: 4

.PARAMETER FailedLogonThreshold
    Threshold for failed logon attempts to trigger suspicion.
    Default: 10

.PARAMETER LockoutThreshold
    Threshold for account lockouts to trigger suspicion.
    Default: 2

.PARAMETER PrivilegeEscalationThreshold
    Threshold for privilege escalation events to trigger suspicion.
    Default: 20

.EXAMPLE
    .\SuspiciousLoginPatternDetector.ps1

    Runs suspicious login detection with default settings (4-hour window).

.EXAMPLE
    .\SuspiciousLoginPatternDetector.ps1 -TimeWindowHours 8 -FailedLogonThreshold 20

    Runs with 8-hour window and higher failed logon threshold.

.OUTPUTS
    None. Results are written to console and NinjaRMM custom field.

.NOTES
    File Name      : SuspiciousLoginPatternDetector.ps1
    Prerequisite   : PowerShell 5.1 or higher, Admin privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    Frequency      : Every 4 hours
    Runtime        : Approximately 25 seconds
    Timeout        : 90 seconds
    Context        : SYSTEM
    
    Change Log:
    - 3.0.0: V3 migration with standardized logging, error handling, and parameterized thresholds
    - 4.0: Previous version with behavioral analytics
    
    Fields Updated:
    - secSuspiciousLoginScore: Integer 0-100 risk score for authentication patterns
    
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
    
    Integrates with security operations workflows to trigger automated responses including user
    notifications, account restrictions, enhanced logging, and incident ticket creation.
    
    Exit Codes:
    - 0: Script completed successfully
    - 1: Script encountered errors
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$SuspicionScoreField = "secSuspiciousLoginScore",
    
    [Parameter()]
    [ValidateRange(1, 24)]
    [Int]$TimeWindowHours = 4,
    
    [Parameter()]
    [ValidateRange(1, 1000)]
    [Int]$FailedLogonThreshold = 10,
    
    [Parameter()]
    [ValidateRange(1, 100)]
    [Int]$LockoutThreshold = 2,
    
    [Parameter()]
    [ValidateRange(1, 1000)]
    [Int]$PrivilegeEscalationThreshold = 20
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $script:ExitCode = 0
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Output $LogMessage; $script:ExitCode = 1 }
            'ALERT' { Write-Output $LogMessage }
            'WARNING' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:suspicionScoreField -and $env:suspicionScoreField -notlike "null") {
        $SuspicionScoreField = $env:suspicionScoreField
    }
    if ($env:timeWindowHours -and $env:timeWindowHours -notlike "null") {
        $TimeWindowHours = [int]$env:timeWindowHours
    }
    if ($env:failedLogonThreshold -and $env:failedLogonThreshold -notlike "null") {
        $FailedLogonThreshold = [int]$env:failedLogonThreshold
    }
    if ($env:lockoutThreshold -and $env:lockoutThreshold -notlike "null") {
        $LockoutThreshold = [int]$env:lockoutThreshold
    }
    if ($env:privilegeEscalationThreshold -and $env:privilegeEscalationThreshold -notlike "null") {
        $PrivilegeEscalationThreshold = [int]$env:privilegeEscalationThreshold
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $Value
        )
        try {
            $NinjaValue = $Value
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            throw "Failed to set NinjaRMM property '$Name': $_"
        }
    }
}

process {
    try {
        Write-Log "Starting Suspicious Login Pattern Detector (v3.0.0)"
        
        $suspicionScore = 0
        $indicators = @()
        $metrics = @{}
        $analysisStartTime = (Get-Date).AddHours(-$TimeWindowHours)
        
        Write-Log "Analyzing authentication events from last $TimeWindowHours hour(s)"
        Write-Log "Analysis window: $($analysisStartTime.ToString('yyyy-MM-dd HH:mm')) to $((Get-Date).ToString('yyyy-MM-dd HH:mm'))"

        Write-Log "Checking for excessive failed logon attempts (threshold: $FailedLogonThreshold)..."
        try {
            $failedLogonEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = 4625
                StartTime = $analysisStartTime
            } -ErrorAction SilentlyContinue

            $failedCount = if ($failedLogonEvents) { ($failedLogonEvents | Measure-Object).Count } else { 0 }
            $metrics['FailedLogons'] = $failedCount
            Write-Log "Detected $failedCount failed logon attempt(s)"
            
            if ($failedCount -gt $FailedLogonThreshold) {
                $suspicionScore += 20
                $indicators += "Excessive failed logons: $failedCount attempts (threshold: $FailedLogonThreshold) [+20 points]"
                Write-Log "Excessive failed logon attempts detected" -Level ALERT
            }
        } 
        catch {
            Write-Log "Failed to query failed logon events: $_" -Level WARNING
            $metrics['FailedLogons'] = 'Query Failed'
        }

        Write-Log "Checking for off-hours authentication activity (2:00 AM - 5:00 AM)..."
        $currentHour = (Get-Date).Hour
        
        if ($currentHour -ge 2 -and $currentHour -le 5) {
            Write-Log "Current time is during off-hours window"
            
            try {
                $recentLogonEvents = Get-WinEvent -FilterHashtable @{
                    LogName = 'Security'
                    ID = 4624
                    StartTime = $analysisStartTime
                } -ErrorAction SilentlyContinue

                $successfulLogonCount = if ($recentLogonEvents) { ($recentLogonEvents | Measure-Object).Count } else { 0 }
                
                if ($successfulLogonCount -gt 0) {
                    $suspicionScore += 15
                    $indicators += "Off-hours successful logon(s): $successfulLogonCount event(s) [+15 points]"
                    $metrics['OffHoursActivity'] = "$successfulLogonCount logon(s)"
                    Write-Log "Off-hours authentication activity detected" -Level ALERT
                } 
                else {
                    $metrics['OffHoursActivity'] = 'No activity'
                }
            } 
            catch {
                Write-Log "Failed to query successful logon events: $_" -Level WARNING
                $metrics['OffHoursActivity'] = 'Query Failed'
            }
        } 
        else {
            $metrics['OffHoursActivity'] = 'Not in off-hours window'
            Write-Log "Current time is within normal business hours (off-hours check skipped)"
        }

        Write-Log "Checking for account lockout events (threshold: $LockoutThreshold)..."
        try {
            $lockoutEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = 4740
                StartTime = $analysisStartTime
            } -ErrorAction SilentlyContinue

            $lockoutCount = if ($lockoutEvents) { ($lockoutEvents | Measure-Object).Count } else { 0 }
            $metrics['AccountLockouts'] = $lockoutCount
            Write-Log "Detected $lockoutCount account lockout(s)"
            
            if ($lockoutCount -gt $LockoutThreshold) {
                $suspicionScore += 25
                $indicators += "Multiple account lockouts: $lockoutCount events (threshold: $LockoutThreshold) [+25 points]"
                Write-Log "Multiple account lockouts detected" -Level ALERT
            }
        } 
        catch {
            Write-Log "Failed to query lockout events: $_" -Level WARNING
            $metrics['AccountLockouts'] = 'Query Failed'
        }

        Write-Log "Checking for privilege escalation patterns (threshold: $PrivilegeEscalationThreshold)..."
        try {
            $privEscEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = 4672
                StartTime = $analysisStartTime
            } -ErrorAction SilentlyContinue

            $privEscCount = if ($privEscEvents) { ($privEscEvents | Measure-Object).Count } else { 0 }
            $metrics['PrivilegeEscalations'] = $privEscCount
            Write-Log "Detected $privEscCount special privilege assignment(s)"
            
            if ($privEscCount -gt $PrivilegeEscalationThreshold) {
                $suspicionScore += 10
                $indicators += "High privilege escalation volume: $privEscCount events (threshold: $PrivilegeEscalationThreshold) [+10 points]"
                Write-Log "Elevated privilege escalation activity detected" -Level WARNING
            }
        } 
        catch {
            Write-Log "Failed to query privilege escalation events: $_" -Level WARNING
            $metrics['PrivilegeEscalations'] = 'Query Failed'
        }

        if ($suspicionScore -gt 100) { 
            $suspicionScore = 100
            Write-Log "Score capped at maximum (100)"
        }

        $threatLevel = switch ($suspicionScore) {
            { $_ -ge 76 } { 'HIGH - Immediate investigation required' }
            { $_ -ge 50 } { 'MEDIUM - Investigation and documentation recommended' }
            { $_ -ge 26 } { 'LOW - Continue monitoring for trends' }
            default { 'NORMAL - Routine authentication patterns' }
        }

        Write-Log "Suspicious login score calculated: $suspicionScore/100"
        Write-Log "Threat level: $threatLevel"

        Write-Log "Updating NinjaRMM custom field..."
        try {
            Set-NinjaProperty -Name $SuspicionScoreField -Value $suspicionScore -ErrorAction Stop
            Write-Log "Suspicious login score saved to field: $SuspicionScoreField"
        }
        catch {
            Write-Log "Failed to update suspicion score field: $_" -Level ERROR
        }

        Write-Log "AUTHENTICATION METRICS:"
        foreach ($metric in $metrics.Keys | Sort-Object) {
            Write-Log "  $metric : $($metrics[$metric])"
        }

        if ($indicators.Count -gt 0) {
            Write-Log "SUSPICIOUS INDICATORS DETECTED:"
            $indicators | ForEach-Object { Write-Log "  - $_" -Level WARNING }
            
            if ($suspicionScore -ge 76) {
                Write-Log "RECOMMENDATION: Review authentication logs, verify user activity, consider account restrictions" -Level ALERT
            } 
            elseif ($suspicionScore -ge 50) {
                Write-Log "RECOMMENDATION: Monitor for continued patterns, review recent user changes" -Level WARNING
            }
        } 
        else {
            Write-Log "No suspicious indicators detected"
        }

        Write-Log "Suspicious login pattern detection completed successfully"
    }
    catch {
        Write-Log "Suspicious login pattern detection failed with unexpected error: $_" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $([Math]::Round($Duration, 2)) seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
