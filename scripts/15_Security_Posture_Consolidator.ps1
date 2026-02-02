<#
.SYNOPSIS
    NinjaRMM Script 15: Security Posture Consolidator

.DESCRIPTION
    Calculates comprehensive security posture score.
    Evaluates antivirus, firewall, BitLocker, SMBv1, and authentication security.

.NOTES
    Frequency: Daily
    Runtime: ~35 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secSecurityPostureScore (Integer 0-100)
    - secFailedLogonCount24h (Integer)
    - secAccountLockouts24h (Integer)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    # Initialize score
    $score = 100

    # Check antivirus
    $avInstalled = Ninja-Property-Get secAntivirusInstalled
    $avEnabled = Ninja-Property-Get secAntivirusEnabled
    $avUpToDate = Ninja-Property-Get secAntivirusUpToDate

    if ($avInstalled -eq $false) { $score -= 40 }
    elseif ($avEnabled -eq $false) { $score -= 30 }
    elseif ($avUpToDate -eq $false) { $score -= 15 }

    # Check firewall
    $fwEnabled = Ninja-Property-Get secFirewallEnabled
    if ($fwEnabled -eq $false) { $score -= 30 }

    # Check BitLocker
    $blEnabled = Ninja-Property-Get secBitLockerEnabled
    if ($blEnabled -eq $false) { $score -= 15 }

    # Check SMBv1
    $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
    if ($smbv1 -and $smbv1.State -eq "Enabled") { $score -= 10 }

    # Check failed logons (last 24 hours)
    $startTime = (Get-Date).AddHours(-24)
    $failedLogons = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

    if ($failedLogons -gt 50) { $score -= 20 }
    elseif ($failedLogons -gt 20) { $score -= 10 }
    elseif ($failedLogons -gt 10) { $score -= 5 }

    # Check account lockouts
    $lockouts = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4740
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

    # Ensure score doesn't go negative
    if ($score -lt 0) { $score = 0 }

    # Update custom fields
    Ninja-Property-Set secSecurityPostureScore $score
    Ninja-Property-Set secFailedLogonCount24h $failedLogons
    Ninja-Property-Set secAccountLockouts24h $lockouts

    Write-Output "Security Posture Score: $score | Failed Logons: $failedLogons | Lockouts: $lockouts"

} catch {
    Write-Output "Error: $_"
    exit 1
}
