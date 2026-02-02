#!/usr/bin/env pwsh
# Script 12: Baseline Manager
# Purpose: Establish and track performance baselines, detect drift
# Frequency: Daily
# Runtime: ~20 seconds
# Timeout: 60 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Baseline Manager (v4.0 Native-Enhanced)"

    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    $cpuUtilization = (Get-Counter '\\Processor(_Total)\\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    $baseline = @{
        CPU = [math]::Round($cpuUtilization, 2)
        Memory = $memUtilization
        DiskFree = $diskFreePercent
        Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }

    $baselineJson = $baseline | ConvertTo-Json -Compress

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

    Write-Output "SUCCESS: Baseline updated"
    Write-Output "  CPU: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  Memory: $memUtilization%"
    Write-Output "  Disk Free: $diskFreePercent%"
    Write-Output "  Drift Score: $driftScore"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
