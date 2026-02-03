#!/usr/bin/env pwsh
# Script 12: Baseline Manager
# Purpose: Establish and track performance baselines, detect drift
# Frequency: Daily
# Runtime: ~20 seconds
# Timeout: 60 seconds
# Context: SYSTEM
# Version: 4.1 (Native Integration + Unix Epoch)

<#
.SYNOPSIS
    Script 12: Baseline Manager
    Establishes and tracks performance baselines

.DESCRIPTION
    Monitors CPU, memory, and disk performance metrics to establish baselines and detect drift
    from normal operating parameters. Updates baseline data and calculates drift scores.

.FIELDS UPDATED
    - BASEPerformanceBaseline (Text: JSON with CPU, Memory, DiskFree metrics)
    - BASEDriftScore (Integer: 0-100 drift score)
    - BASELastUpdated (Date/Time: Unix Epoch seconds since 1970-01-01 UTC)

.EXECUTION
    Frequency: Daily
    Runtime: ~20 seconds
    Requires: SYSTEM context

.NOTES
    File: 12_Baseline_Manager.ps1
    Author: Windows Automation Framework
    Version: 4.1
    Created: 2024
    Updated: February 3, 2026
    Category: Performance Monitoring
    Dependencies: None

.MIGRATION NOTES
    v4.0 -> v4.1 Changes:
    - Removed Timestamp from JSON structure
    - Added separate BASELastUpdated Date/Time field (Unix Epoch format)
    - Uses inline DateTimeOffset conversion (no helper functions needed)
    - Maintains human-readable logging for troubleshooting
    - NinjaOne handles timezone display automatically
    - JSON now contains only metric data (CPU, Memory, DiskFree)

.RELATED DOCUMENTATION
    - docs/DATE_TIME_FIELD_AUDIT.md
    - docs/DATE_TIME_FIELD_MAPPING.md
    - docs/ACTION_PLAN_Field_Conversion_Documentation.md (v1.9)
#>

try {
    Write-Output "Starting Baseline Manager (v4.1 Native-Enhanced + Unix Epoch)"

    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    $cpuUtilization = (Get-Counter '\\Processor(_Total)\\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    # Build baseline without timestamp (timestamp now in separate field)
    $baseline = @{
        CPU = [math]::Round($cpuUtilization, 2)
        Memory = $memUtilization
        DiskFree = $diskFreePercent
    }

    $baselineJson = $baseline | ConvertTo-Json -Compress
    
    # Create Unix Epoch timestamp for separate field
    $timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()

    $existingBaseline = Ninja-Property-Get BASEPerformanceBaseline
    $driftScore = 0

    if (-not [string]::IsNullOrEmpty($existingBaseline)) {
        try {
            $oldBaseline = $existingBaseline | ConvertFrom-Json
            $cpuDrift = [math]::Abs($baseline.CPU - $oldBaseline.CPU)
            $memDrift = [math]::Abs($baseline.Memory - $oldBaseline.Memory)
            $diskDrift = [math]::Abs($baseline.DiskFree - $oldBaseline.DiskFree)

            $driftScore = [int](($cpuDrift * 0.4) + ($memDrift * 0.4) + ($diskDrift * 0.2))
            if ($driftScore -gt 100) { $driftScore = 100 }
        } catch {
            $driftScore = 0
        }
    }

    Ninja-Property-Set BASEPerformanceBaseline $baselineJson
    Ninja-Property-Set BASEDriftScore $driftScore
    Ninja-Property-Set BASELastUpdated $timestamp

    Write-Output "SUCCESS: Baseline updated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Output "  CPU: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  Memory: $memUtilization%"
    Write-Output "  Disk Free: $diskFreePercent%"
    Write-Output "  Drift Score: $driftScore"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
