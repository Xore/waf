<#
.SYNOPSIS
    NinjaRMM Script 30: Advanced Threat and Security Telemetry

.DESCRIPTION
    Monitors advanced security events including failed logins,
    suspicious PowerShell activity, and account lockouts.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secFailedLoginCount24h (Integer)
    - secSuspiciousActivityCount (Integer)
    - secAccountLockouts24h (Integer)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    $startTime = (Get-Date).AddHours(-24)

    # Count failed login attempts
    $failedLogins = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $failedLoginCount = if ($failedLogins) { $failedLogins.Count } else { 0 }

    # Count account lockouts
    $lockouts = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4740
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $lockoutCount = if ($lockouts) { $lockouts.Count } else { 0 }

    # Check for suspicious PowerShell activity
    $suspiciousPS = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-PowerShell/Operational'
        ID = 4104
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Message -match "Invoke-Expression|IEX|DownloadString|System.Net.WebClient"
    }

    $suspiciousCount = if ($suspiciousPS) { $suspiciousPS.Count } else { 0 }

    # Update custom fields
    Ninja-Property-Set secFailedLoginCount24h $failedLoginCount
    Ninja-Property-Set secAccountLockouts24h $lockoutCount
    Ninja-Property-Set secSuspiciousActivityCount $suspiciousCount

    Write-Output "Failed Logins: $failedLoginCount | Lockouts: $lockoutCount | Suspicious: $suspiciousCount"

} catch {
    Write-Output "Error: $_"
    exit 1
}
