# Script 18: CLEANUP Profile Hygiene Advisor

**File:** Script_18_CLEANUP_Profile_Hygiene_Advisor.md  
**Version:** v1.0  
**Script Number:** 18  
**Category:** Extended Automation - Cleanup Recommendations  
**Last Updated:** February 2, 2026

---

## Purpose

Identify cleanup opportunities and calculate potential space savings.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~45 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- CLEANUPRecommendedCleanupMB (Integer)
- CLEANUPCleanupPriority (Dropdown: Low, Medium, High, Critical)

---

## PowerShell Implementation

```powershell
# Script 18: Profile Hygiene and Cleanup Advisor
# Identifies cleanup opportunities

param()

try {
    Write-Output "Starting Profile Hygiene and Cleanup Advisor (v1.0)"

    $totalCleanupMB = 0

    # Check Windows temp files
    $tempPath = "$env:SystemRoot\Temp"
    if (Test-Path $tempPath) {
        $tempSize = (Get-ChildItem $tempPath -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        $totalCleanupMB += [math]::Round($tempSize, 2)
        Write-Output "Windows Temp: $([math]::Round($tempSize, 2)) MB"
    }

    # Check user temp files
    $userTemp = "$env:TEMP"
    if (Test-Path $userTemp) {
        $userTempSize = (Get-ChildItem $userTemp -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        $totalCleanupMB += [math]::Round($userTempSize, 2)
        Write-Output "User Temp: $([math]::Round($userTempSize, 2)) MB"
    }

    # Check Windows Update cache
    $wuCache = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuCache) {
        $wuSize = (Get-ChildItem $wuCache -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        $totalCleanupMB += [math]::Round($wuSize, 2)
        Write-Output "Windows Update Cache: $([math]::Round($wuSize, 2)) MB"
    }

    # Check recycle bin
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0xA)
    if ($recycleBin) {
        $rbSize = ($recycleBin.Items() | Measure-Object -Property Size -Sum).Sum / 1MB
        if ($rbSize) {
            $totalCleanupMB += [math]::Round($rbSize, 2)
            Write-Output "Recycle Bin: $([math]::Round($rbSize, 2)) MB"
        }
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

    Write-Output "SUCCESS: Cleanup potential = $totalCleanupMB MB"
    Write-Output "  Priority: $priority"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_18_CLEANUP_Profile_Hygiene_Advisor.md  
**Version:** v1.0  
**Status:** Production Ready
