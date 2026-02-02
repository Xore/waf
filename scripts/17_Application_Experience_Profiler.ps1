<#
.SYNOPSIS
    NinjaRMM Script 17: Application Experience Profiler

.DESCRIPTION
    Monitors application performance and user experience.
    Tracks crashes, hangs, and identifies problematic applications.

.NOTES
    Frequency: Daily
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - uxExperienceScore (Integer 0-100)
    - uxApplicationHangCount24h (Integer)
    - appTopCrashingApp (Text)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    $score = 100
    $startTime = (Get-Date).AddHours(-24)

    # Get application crashes
    $crashes = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1000, 1001
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $crashCount = $crashes.Count

    # Get application hangs
    $hangs = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1002
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $hangCount = $hangs.Count

    # Calculate score deductions
    $score -= ($crashCount * 5)
    $score -= ($hangCount * 3)

    if ($score -lt 0) { $score = 0 }

    # Find top crashing app
    $topCrasher = "None"
    if ($crashes.Count -gt 0) {
        $crashApps = $crashes | ForEach-Object {
            if ($_.Message -match "Application: (.+?)\s") {
                $matches[1]
            }
        }
        $topCrasher = ($crashApps | Group-Object | Sort-Object Count -Descending | 
            Select-Object -First 1).Name
        
        if ([string]::IsNullOrEmpty($topCrasher)) {
            $topCrasher = "Unknown"
        }
    }

    # Update custom fields
    Ninja-Property-Set uxExperienceScore $score
    Ninja-Property-Set uxApplicationHangCount24h $hangCount
    Ninja-Property-Set appTopCrashingApp $topCrasher

    Write-Output "UX Score: $score | Crashes: $crashCount | Hangs: $hangCount | Top: $topCrasher"

} catch {
    Write-Output "Error: $_"
    exit 1
}
