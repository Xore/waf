#Requires -Version 5.1

<#
.SYNOPSIS
    Advanced Threat Telemetry - Security Event Detection and Monitoring

.DESCRIPTION
    Monitors advanced security events and suspicious activity patterns including failed login
    attempts, account lockouts, and potentially malicious PowerShell command execution. Analyzes
    Windows Security and PowerShell Operational event logs to detect indicators of compromise.
    
    Tracks failed authentication events (Event ID 4625) which may indicate brute force attacks
    or credential stuffing attempts. Monitors account lockout events (Event ID 4740) which could
    signal automated attack tools or password guessing campaigns.
    
    Detects suspicious PowerShell script block execution (Event ID 4104) containing common
    attack patterns such as:
    - Invoke-Expression / IEX (code execution from strings)
    - DownloadString (downloading and executing remote scripts)
    - System.Net.WebClient (web-based payload delivery)
    - Base64 encoded commands
    - Obfuscation techniques
    
    Provides rolling window analysis to identify active threats and trending attack
    patterns requiring immediate security response.

.PARAMETER FailedLoginField
    NinjaRMM custom field name to store failed login count.
    Default: secFailedLoginCount24h

.PARAMETER LockoutField
    NinjaRMM custom field name to store account lockout count.
    Default: secAccountLockouts24h

.PARAMETER SuspiciousActivityField
    NinjaRMM custom field name to store suspicious PowerShell activity count.
    Default: secSuspiciousActivityCount

.PARAMETER TimeWindowHours
    Number of hours to look back for security events.
    Default: 24

.PARAMETER FailedLoginThreshold
    Threshold for failed logins to trigger medium threat level.
    Default: 10

.PARAMETER LockoutThreshold
    Threshold for account lockouts to trigger medium threat level.
    Default: 2

.EXAMPLE
    .\AdvancedThreatTelemetry.ps1

    Runs threat detection with default settings (24-hour window).

.EXAMPLE
    .\AdvancedThreatTelemetry.ps1 -TimeWindowHours 48 -FailedLoginThreshold 20

    Runs with 48-hour window and higher failed login threshold.

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : AdvancedThreatTelemetry.ps1
    Prerequisite   : PowerShell 5.1 or higher, Admin privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    Frequency      : Every 4 hours
    Runtime        : Approximately 30 seconds
    Timeout        : 90 seconds
    Context        : SYSTEM
    
    Change Log:
    - 3.0.0: V3 migration with standardized logging, error handling, and parameterized thresholds
    - 4.0: Previous version with threat detection
    
    Fields Updated:
    - secFailedLoginCount24h: Integer failed login attempts in time window
    - secAccountLockouts24h: Integer account lockouts in time window
    - secSuspiciousActivityCount: Integer suspicious PowerShell events in time window
    
    Dependencies:
    - Windows Security event log
    - PowerShell Operational event log
    - Script block logging enabled for full coverage (Group Policy)
    
    Security Considerations:
    - High failed login counts may indicate brute force attacks
    - Account lockouts could signal automated attack tools
    - Suspicious PowerShell patterns often indicate post-exploitation activity
    - Regular monitoring enables early detection of compromise attempts
    - Combine with other security telemetry for comprehensive threat assessment
    
    Threat Level Classification:
    - HIGH: Suspicious PowerShell activity OR >5 lockouts OR >20 failed logins
    - MEDIUM: >10 failed logins OR >2 lockouts
    - LOW: Below medium thresholds
    
    Exit Codes:
    - 0: Script completed successfully
    - 1: Script encountered errors
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$FailedLoginField = "secFailedLoginCount24h",
    
    [Parameter()]
    [String]$LockoutField = "secAccountLockouts24h",
    
    [Parameter()]
    [String]$SuspiciousActivityField = "secSuspiciousActivityCount",
    
    [Parameter()]
    [ValidateRange(1, 168)]
    [Int]$TimeWindowHours = 24,
    
    [Parameter()]
    [ValidateRange(1, 1000)]
    [Int]$FailedLoginThreshold = 10,
    
    [Parameter()]
    [ValidateRange(1, 100)]
    [Int]$LockoutThreshold = 2
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

    if ($env:failedLoginField -and $env:failedLoginField -notlike "null") {
        $FailedLoginField = $env:failedLoginField
    }
    if ($env:lockoutField -and $env:lockoutField -notlike "null") {
        $LockoutField = $env:lockoutField
    }
    if ($env:suspiciousActivityField -and $env:suspiciousActivityField -notlike "null") {
        $SuspiciousActivityField = $env:suspiciousActivityField
    }
    if ($env:timeWindowHours -and $env:timeWindowHours -notlike "null") {
        $TimeWindowHours = [int]$env:timeWindowHours
    }
    if ($env:failedLoginThreshold -and $env:failedLoginThreshold -notlike "null") {
        $FailedLoginThreshold = [int]$env:failedLoginThreshold
    }
    if ($env:lockoutThreshold -and $env:lockoutThreshold -notlike "null") {
        $LockoutThreshold = [int]$env:lockoutThreshold
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

    $SuspiciousPatterns = @(
        'Invoke-Expression',
        'IEX',
        'DownloadString',
        'System.Net.WebClient',
        'Net.WebClient',
        'FromBase64String',
        '-encodedcommand',
        '-enc',
        'hidden',
        'bypass'
    )
}

process {
    try {
        Write-Log "Starting Advanced Threat Telemetry (v3.0.0)"
        
        $metrics = @{
            'FailedLogins' = 0
            'AccountLockouts' = 0
            'SuspiciousActivity' = 0
        }
        
        $analysisStartTime = (Get-Date).AddHours(-$TimeWindowHours)
        Write-Log "Analyzing security events from last $TimeWindowHours hour(s)"
        Write-Log "Analysis window: $($analysisStartTime.ToString('yyyy-MM-dd HH:mm')) to $((Get-Date).ToString('yyyy-MM-dd HH:mm'))"

        Write-Log "Checking failed login attempts (Event ID 4625)..."
        try {
            $failedLoginEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = 4625
                StartTime = $analysisStartTime
            } -ErrorAction SilentlyContinue

            $metrics['FailedLogins'] = if ($failedLoginEvents) { ($failedLoginEvents | Measure-Object).Count } else { 0 }
            
            if ($metrics['FailedLogins'] -gt 0) {
                Write-Log "Detected $($metrics['FailedLogins']) failed login attempt(s)" -Level WARNING
            } 
            else {
                Write-Log "No failed login attempts detected"
            }
        } 
        catch {
            Write-Log "Failed to query failed login events: $_" -Level WARNING
        }

        Write-Log "Checking account lockouts (Event ID 4740)..."
        try {
            $lockoutEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = 4740
                StartTime = $analysisStartTime
            } -ErrorAction SilentlyContinue

            $metrics['AccountLockouts'] = if ($lockoutEvents) { ($lockoutEvents | Measure-Object).Count } else { 0 }
            
            if ($metrics['AccountLockouts'] -gt 0) {
                Write-Log "Detected $($metrics['AccountLockouts']) account lockout(s)" -Level WARNING
            } 
            else {
                Write-Log "No account lockouts detected"
            }
        } 
        catch {
            Write-Log "Failed to query lockout events: $_" -Level WARNING
        }

        Write-Log "Checking for suspicious PowerShell activity (Event ID 4104)..."
        try {
            $psEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Microsoft-Windows-PowerShell/Operational'
                ID = 4104
                StartTime = $analysisStartTime
            } -ErrorAction SilentlyContinue
            
            if ($psEvents) {
                $patternString = $SuspiciousPatterns -join '|'
                $suspiciousEvents = $psEvents | Where-Object {
                    $_.Message -match $patternString
                }
                
                $metrics['SuspiciousActivity'] = if ($suspiciousEvents) { ($suspiciousEvents | Measure-Object).Count } else { 0 }
                
                if ($metrics['SuspiciousActivity'] -gt 0) {
                    Write-Log "Detected $($metrics['SuspiciousActivity']) suspicious PowerShell event(s)" -Level ALERT
                    Write-Log "  Common indicators: IEX, DownloadString, WebClient, Base64, obfuscation" -Level ALERT
                } 
                else {
                    Write-Log "No suspicious PowerShell activity detected"
                }
            } 
            else {
                Write-Log "No PowerShell events found in time window"
            }
        } 
        catch {
            Write-Log "Failed to query PowerShell events: $_" -Level WARNING
        }

        $threatLevel = 'LOW'
        $threatReason = @()
        
        if ($metrics['SuspiciousActivity'] -gt 0) {
            $threatLevel = 'HIGH'
            $threatReason += "Suspicious PowerShell activity detected ($($metrics['SuspiciousActivity']) events)"
        }
        
        if ($metrics['AccountLockouts'] -gt 5) {
            $threatLevel = 'HIGH'
            $threatReason += "Excessive account lockouts ($($metrics['AccountLockouts']) events)"
        }
        
        if ($metrics['FailedLogins'] -gt 20) {
            $threatLevel = 'HIGH'
            $threatReason += "Excessive failed logins ($($metrics['FailedLogins']) events)"
        }
        
        if ($threatLevel -ne 'HIGH') {
            if ($metrics['FailedLogins'] -gt $FailedLoginThreshold) {
                $threatLevel = 'MEDIUM'
                $threatReason += "Elevated failed logins ($($metrics['FailedLogins']) events, threshold: $FailedLoginThreshold)"
            }
            
            if ($metrics['AccountLockouts'] -gt $LockoutThreshold) {
                $threatLevel = 'MEDIUM'
                $threatReason += "Elevated account lockouts ($($metrics['AccountLockouts']) events, threshold: $LockoutThreshold)"
            }
        }
        
        if ($threatLevel -eq 'LOW') {
            $threatReason += 'Normal activity levels'
        }

        Write-Log "Threat level assessment: $threatLevel"
        $threatReason | ForEach-Object { Write-Log "  - $_" }

        Write-Log "Updating NinjaRMM custom fields..."
        try {
            Set-NinjaProperty -Name $FailedLoginField -Value $metrics['FailedLogins'] -ErrorAction Stop
            Write-Log "Failed login count saved to field: $FailedLoginField"
        }
        catch {
            Write-Log "Failed to update failed login field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $LockoutField -Value $metrics['AccountLockouts'] -ErrorAction Stop
            Write-Log "Account lockout count saved to field: $LockoutField"
        }
        catch {
            Write-Log "Failed to update lockout field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $SuspiciousActivityField -Value $metrics['SuspiciousActivity'] -ErrorAction Stop
            Write-Log "Suspicious activity count saved to field: $SuspiciousActivityField"
        }
        catch {
            Write-Log "Failed to update suspicious activity field: $_" -Level ERROR
        }

        Write-Log "THREAT TELEMETRY SUMMARY:"
        Write-Log "  Failed Logins: $($metrics['FailedLogins'])"
        Write-Log "  Account Lockouts: $($metrics['AccountLockouts'])"
        Write-Log "  Suspicious PowerShell Events: $($metrics['SuspiciousActivity'])"
        Write-Log "  Threat Level: $threatLevel"

        if ($threatLevel -eq 'HIGH') {
            Write-Log "RECOMMENDATION: Immediate investigation required" -Level ALERT
        } 
        elseif ($threatLevel -eq 'MEDIUM') {
            Write-Log "RECOMMENDATION: Monitor closely for escalation" -Level WARNING
        }

        Write-Log "Advanced threat telemetry completed successfully"
    }
    catch {
        Write-Log "Advanced threat telemetry failed with unexpected error: $_" -Level ERROR
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
