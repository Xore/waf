<#
.SYNOPSIS
    NinjaRMM Script 29: Collaboration and Outlook UX Telemetry

.DESCRIPTION
    Monitors Teams and Outlook performance.
    Tracks crashes, hangs, and poor quality events.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~25 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - uxCollabFailures24h (Integer)
    - uxCollabPoorQuality24h (Integer)
    - appOutlookFailures24h (Integer)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    $startTime = (Get-Date).AddHours(-24)

    # Check Teams crashes
    $teamsCrashes = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1000
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Message -match "Teams.exe"
    }

    $teamsFailures = $teamsCrashes.Count

    # Check Outlook crashes
    $outlookCrashes = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1000
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Message -match "OUTLOOK.EXE"
    }

    $outlookFailures = $outlookCrashes.Count

    # Check Teams performance issues (hangs)
    $teamsHangs = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1002
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Message -match "Teams.exe"
    }

    $poorQuality = $teamsHangs.Count

    # Update custom fields
    Ninja-Property-Set uxCollabFailures24h $teamsFailures
    Ninja-Property-Set uxCollabPoorQuality24h $poorQuality
    Ninja-Property-Set appOutlookFailures24h $outlookFailures

    Write-Output "Teams Failures: $teamsFailures | Poor Quality: $poorQuality | Outlook: $outlookFailures"

} catch {
    Write-Output "Error: $_"
    exit 1
}
