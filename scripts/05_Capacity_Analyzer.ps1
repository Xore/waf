#!/usr/bin/env pwsh
# Script 05: Capacity Analyzer
# Purpose: Calculate resource capacity and headroom score
# Frequency: Daily
# Runtime: ~15 seconds
# Timeout: 60 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Capacity Analyzer (v4.0 Native-Enhanced)"

    $capacityScore = 100

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    $daysUntilFull = Ninja-Property-Get CAPDaysUntilDiskFull
    if ([string]::IsNullOrEmpty($daysUntilFull)) { $daysUntilFull = 999 }

    if ($diskFreePercent -lt 10) {
        $capacityScore -= 50
    } elseif ($diskFreePercent -lt 20) {
        $capacityScore -= 30
    } elseif ($diskFreePercent -lt 30) {
        $capacityScore -= 15
    }

    if ($memUtilization -gt 90) {
        $capacityScore -= 25
    } elseif ($memUtilization -gt 85) {
        $capacityScore -= 20
    } elseif ($memUtilization -gt 80) {
        $capacityScore -= 10
    }

    if ($daysUntilFull -lt 30 -and $daysUntilFull -gt 0) {
        $capacityScore -= 15
    } elseif ($daysUntilFull -lt 60 -and $daysUntilFull -gt 0) {
        $capacityScore -= 10
    }

    if ($capacityScore -lt 0) { $capacityScore = 0 }
    if ($capacityScore -gt 100) { $capacityScore = 100 }

    Ninja-Property-Set OPSCapacityScore $capacityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Capacity Score = $capacityScore"
    Write-Output "  Disk Free: $diskFreePercent%"
    Write-Output "  Memory Utilization: $memUtilization%"
    Write-Output "  Days Until Disk Full: $daysUntilFull"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
