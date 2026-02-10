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
    
    Provides 24-hour rolling window analysis to identify active threats and trending attack
    patterns requiring immediate security response.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secFailedLoginCount24h (Integer: failed login attempts in last 24 hours)
    - secAccountLockouts24h (Integer: account lockouts in last 24 hours)
    - secSuspiciousActivityCount (Integer: suspicious PowerShell events in last 24 hours)
    
    Dependencies:
    - Windows Security event log
    - PowerShell Operational event log
    - Script block logging enabled for full coverage (Group Policy)
    
    Security Considerations:
    - High failed login counts may indicate brute force attacks
    - Account lockouts could signal automated attack tools
    - Suspicious PowerShell patterns often indicate post-exploitation activity
    - Regular monitoring enables early detection of compromise attempts
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Advanced Threat Telemetry (v4.0)..."
    $startTime = (Get-Date).AddHours(-24)
    Write-Output "INFO: Analyzing security events from last 24 hours (since $($startTime.ToString('yyyy-MM-dd HH:mm')))"

    # Count failed login attempts (Event ID 4625)
    Write-Output "INFO: Checking failed login attempts..."
    try {
        $failedLogins = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4625
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        $failedLoginCount = if ($failedLogins) { $failedLogins.Count } else { 0 }
        
        if ($failedLoginCount -gt 0) {
            Write-Output "WARNING: Detected $failedLoginCount failed login attempt(s) in last 24 hours"
        } else {
            Write-Output "INFO: No failed login attempts detected (good)"
        }
    } catch {
        Write-Output "WARNING: Failed to query failed login events: $_"
        $failedLoginCount = 0
    }

    # Count account lockouts (Event ID 4740)
    Write-Output "INFO: Checking account lockouts..."
    try {
        $lockouts = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4740
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        $lockoutCount = if ($lockouts) { $lockouts.Count } else { 0 }
        
        if ($lockoutCount -gt 0) {
            Write-Output "WARNING: Detected $lockoutCount account lockout(s) in last 24 hours"
        } else {
            Write-Output "INFO: No account lockouts detected (good)"
        }
    } catch {
        Write-Output "WARNING: Failed to query lockout events: $_"
        $lockoutCount = 0
    }

    # Check for suspicious PowerShell activity (Event ID 4104 - Script Block Logging)
    Write-Output "INFO: Checking for suspicious PowerShell activity..."
    try {
        $suspiciousPS = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-PowerShell/Operational'
            ID = 4104
            StartTime = $startTime
        } -ErrorAction SilentlyContinue | Where-Object {
            $_.Message -match "Invoke-Expression|IEX|DownloadString|System.Net.WebClient"
        }

        $suspiciousCount = if ($suspiciousPS) { $suspiciousPS.Count } else { 0 }
        
        if ($suspiciousCount -gt 0) {
            Write-Output "ALERT: Detected $suspiciousCount suspicious PowerShell event(s) in last 24 hours"
            Write-Output "  Common indicators: IEX, DownloadString, WebClient usage"
        } else {
            Write-Output "INFO: No suspicious PowerShell activity detected (good)"
        }
    } catch {
        Write-Output "WARNING: Failed to query PowerShell events: $_"
        $suspiciousCount = 0
    }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating threat telemetry metrics..."
    Ninja-Property-Set secFailedLoginCount24h $failedLoginCount
    Ninja-Property-Set secAccountLockouts24h $lockoutCount
    Ninja-Property-Set secSuspiciousActivityCount $suspiciousCount

    Write-Output "SUCCESS: Advanced threat telemetry complete"
    Write-Output "SUMMARY: Failed Logins: $failedLoginCount | Lockouts: $lockoutCount | Suspicious Activity: $suspiciousCount"
    
    # Determine threat level
    if ($suspiciousCount -gt 0 -or $lockoutCount -gt 5 -or $failedLoginCount -gt 20) {
        Write-Output "THREAT LEVEL: HIGH - Investigation recommended"
    } elseif ($failedLoginCount -gt 10 -or $lockoutCount -gt 2) {
        Write-Output "THREAT LEVEL: MEDIUM - Monitor closely"
    } else {
        Write-Output "THREAT LEVEL: LOW - Normal activity"
    }
    
    exit 0

} catch {
    Write-Output "ERROR: Advanced Threat Telemetry failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
