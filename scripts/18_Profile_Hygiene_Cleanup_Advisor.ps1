<#
.SYNOPSIS
    NinjaRMM Script 18: Profile Hygiene and Cleanup Advisor

.DESCRIPTION
    Identifies cleanup opportunities and calculates potential space savings.
    Scans temp files, Windows Update cache, and recycle bin.

.NOTES
    Frequency: Daily
    Runtime: ~45 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - cleanupRecommendedCleanupMB (Integer)
    - cleanupCleanupPriority (Dropdown: Low, Medium, High, Critical)
    
    Priority Thresholds:
    - Low: < 1 GB
    - Medium: 1-5 GB
    - High: 5-10 GB
    - Critical: > 10 GB
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    $totalCleanupMB = 0

    # Check Windows temp files
    $tempPath = "$env:SystemRoot\Temp"
    if (Test-Path $tempPath) {
        $tempSize = (Get-ChildItem $tempPath -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        $totalCleanupMB += [math]::Round($tempSize, 2)
    }

    # Check user temp files
    $userTemp = "$env:TEMP"
    if (Test-Path $userTemp) {
        $userTempSize = (Get-ChildItem $userTemp -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        $totalCleanupMB += [math]::Round($userTempSize, 2)
    }

    # Check Windows Update cache
    $wuCache = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuCache) {
        $wuSize = (Get-ChildItem $wuCache -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        $totalCleanupMB += [math]::Round($wuSize, 2)
    }

    # Check recycle bin
    $recycleBin = Get-CimInstance -ClassName Win32_RecycleBin -ErrorAction SilentlyContinue
    if ($recycleBin) {
        $rbSize = ($recycleBin | Measure-Object -Property Size -Sum).Sum / 1MB
        $totalCleanupMB += [math]::Round($rbSize, 2)
    }

    # Determine priority
    if ($totalCleanupMB -lt 1000) {
        $priority = "Low"
    } elseif ($totalCleanupMB -lt 5000) {
        $priority = "Medium"
    } elseif ($totalCleanupMB -lt 10000) {
        $priority = "High"
    } else {
        $priority = "Critical"
    }

    # Update custom fields
    Ninja-Property-Set cleanupRecommendedCleanupMB ([int]$totalCleanupMB)
    Ninja-Property-Set cleanupCleanupPriority $priority

    Write-Output "Cleanup potential: $totalCleanupMB MB | Priority: $priority"

} catch {
    Write-Output "Error: $_"
    exit 1
}
