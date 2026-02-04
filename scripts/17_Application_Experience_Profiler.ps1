<#
.SYNOPSIS
    Application Experience Profiler - User Experience and Application Performance Monitoring

.DESCRIPTION
    Monitors application performance and user experience by tracking application crashes and
    hangs, calculating user experience score based on application reliability, and identifying
    problematic applications that degrade user productivity.
    
    Provides quantitative assessment of application stability from the user's perspective by
    analyzing Windows Application event log for crash and hang events. Enables proactive
    identification of applications requiring updates, patches, or replacement.
    
    User Experience Scoring Model (100 points, deductions applied):
    
    Application Crashes (no maximum limit):
    - Deduction: 5 points per crash in last 24 hours
    - Event IDs: 1000 (Application Error), 1001 (Application Fault)
    - Indicates: Application instability, compatibility issues, bugs
    - Impact: Direct user frustration and lost productivity
    
    Application Hangs (no maximum limit):
    - Deduction: 3 points per hang in last 24 hours
    - Event ID: 1002 (Application Hang)
    - Indicates: Resource contention, infinite loops, deadlocks
    - Impact: System appears frozen, user must force-close
    
    Score Interpretation:
    - 90-100: Excellent application experience
    - 75-89: Good application experience
    - 60-74: Fair experience - some application issues
    - 50-59: Poor experience - frequent application problems
    - Below 50: Critical - severe application instability
    
    Top Crashing Application Identification:
    - Parses crash events to extract application names
    - Groups crashes by application
    - Identifies most frequently crashing application
    - Enables targeted remediation (update, reinstall, replace)
    
    Use Cases:
    - User experience monitoring and reporting
    - Application stability assessment
    - Problematic application identification
    - Software quality tracking
    - Help desk ticket correlation
    - Application upgrade/replacement prioritization

.NOTES
    Frequency: Daily
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - uxExperienceScore (Integer: 0-100 user experience score)
    - uxApplicationHangCount24h (Integer: hang events in last 24 hours)
    - appTopCrashingApp (Text: name of most frequently crashing application)
    
    Dependencies:
    - Windows Application event log
    - Event IDs: 1000, 1001, 1002
    
    Event Log Details:
    - 1000: Application error (crash with error reporting)
    - 1001: Application fault (crash with Windows Error Reporting)
    - 1002: Application hang (program not responding)
    
    Application Name Extraction:
    - Parsed from event message text
    - Regex pattern: "Application: (.+?)\s"
    - Fallback: "Unknown" if parsing fails
    - Grouped by frequency for top crasher identification
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Application Experience Profiler (v4.0)..."

    # Initialize score at maximum
    $score = 100
    $startTime = (Get-Date).AddHours(-24)
    Write-Output "INFO: Analyzing application events for last 24 hours..."

    # Collect application crash events
    Write-Output "INFO: Querying application crash events (Event IDs 1000, 1001)..."
    try {
        $crashes = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            ID = 1000, 1001
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        $crashCount = $crashes.Count
        Write-Output "INFO: Found $crashCount application crash event(s)"
    } catch {
        $crashes = @()
        $crashCount = 0
        Write-Output "INFO: No crash events found or unable to query"
    }

    # Collect application hang events
    Write-Output "INFO: Querying application hang events (Event ID 1002)..."
    try {
        $hangs = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            ID = 1002
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        $hangCount = $hangs.Count
        Write-Output "INFO: Found $hangCount application hang event(s)"
    } catch {
        $hangs = @()
        $hangCount = 0
        Write-Output "INFO: No hang events found or unable to query"
    }

    # Calculate user experience score
    Write-Output "INFO: Calculating user experience score..."
    $crashDeduction = $crashCount * 5
    $hangDeduction = $hangCount * 3
    
    $score -= $crashDeduction
    $score -= $hangDeduction

    if ($crashDeduction -gt 0) {
        Write-Output "  Crash deduction: -$crashDeduction points ($crashCount events x 5)"
    }
    if ($hangDeduction -gt 0) {
        Write-Output "  Hang deduction: -$hangDeduction points ($hangCount events x 3)"
    }

    # Enforce minimum score
    if ($score -lt 0) { $score = 0 }

    # Identify top crashing application
    Write-Output "INFO: Identifying top crashing application..."
    $topCrasher = "None"
    
    if ($crashes.Count -gt 0) {
        try {
            $crashApps = $crashes | ForEach-Object {
                if ($_.Message -match "Application: (.+?)\s") {
                    $matches[1]
                }
            }
            
            if ($crashApps) {
                $topCrasher = ($crashApps | Group-Object | Sort-Object Count -Descending | 
                    Select-Object -First 1).Name
                
                if ([string]::IsNullOrEmpty($topCrasher)) {
                    $topCrasher = "Unknown"
                }
                
                Write-Output "INFO: Top crashing application: $topCrasher"
            } else {
                $topCrasher = "Unknown"
                Write-Output "WARNING: Could not parse application names from crash events"
            }
        } catch {
            $topCrasher = "Unknown"
            Write-Output "WARNING: Error identifying top crasher: $_"
        }
    } else {
        Write-Output "INFO: No crashes detected - top crasher: None"
    }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating user experience metrics..."
    Ninja-Property-Set uxExperienceScore $score
    Ninja-Property-Set uxApplicationHangCount24h $hangCount
    Ninja-Property-Set appTopCrashingApp $topCrasher

    Write-Output "SUCCESS: Application experience profiling complete"
    Write-Output "USER EXPERIENCE SCORE: $score/100"
    Write-Output "APPLICATION STABILITY METRICS:"
    Write-Output "  - Application Crashes (24h): $crashCount"
    Write-Output "  - Application Hangs (24h): $hangCount"
    Write-Output "  - Top Crashing Application: $topCrasher"
    
    # Provide user experience assessment
    if ($score -ge 90) {
        Write-Output "ASSESSMENT: Excellent application experience"
    } elseif ($score -ge 75) {
        Write-Output "ASSESSMENT: Good application experience"
    } elseif ($score -ge 60) {
        Write-Output "ASSESSMENT: Fair experience - some application issues present"
    } elseif ($score -ge 50) {
        Write-Output "ASSESSMENT: Poor experience - frequent application problems"
    } else {
        Write-Output "ASSESSMENT: Critical - severe application instability affecting users"
    }
    
    # Provide recommendations
    if ($topCrasher -ne "None" -and $topCrasher -ne "Unknown") {
        Write-Output "RECOMMENDATION: Investigate $topCrasher for updates or replacement"
    }
    if ($crashCount -gt 5) {
        Write-Output "RECOMMENDATION: Multiple application crashes detected - consider system health check"
    }
    if ($hangCount -gt 3) {
        Write-Output "RECOMMENDATION: Frequent hangs detected - check for resource contention"
    }

    exit 0
} catch {
    Write-Output "ERROR: Application Experience Profiler failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
