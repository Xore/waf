#!/usr/bin/env pwsh
# Script 03: Performance Analyzer
# Purpose: Calculate system performance and responsiveness score
# Frequency: Every 4 hours
# Runtime: ~20 seconds
# Timeout: 60 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Performance Analyzer (v4.0 Native-Enhanced)"

    $performanceScore = 100

    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    $cpuUtilization = (Get-Counter '\\Processor(_Total)\\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    try {
        $diskActiveTime = (Get-Counter '\\PhysicalDisk(_Total)\\% Disk Time' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
    } catch {
        $diskActiveTime = 0
    }

    if ($cpuUtilization -gt 90) {
        $performanceScore -= 20
    } elseif ($cpuUtilization -gt 80) {
        $performanceScore -= 15
    } elseif ($cpuUtilization -gt 70) {
        $performanceScore -= 10
    }

    if ($memUtilization -gt 95) {
        $performanceScore -= 20
    } elseif ($memUtilization -gt 85) {
        $performanceScore -= 15
    } elseif ($memUtilization -gt 75) {
        $performanceScore -= 10
    }

    if ($diskActiveTime -gt 90) {
        $performanceScore -= 15
    } elseif ($diskActiveTime -gt 80) {
        $performanceScore -= 10
    }

    $bootTime = ((Get-Date) - $os.LastBootUpTime).TotalSeconds
    if ($bootTime -lt 300) {
        if ($bootTime -gt 120) {
            $performanceScore -= 15
        } elseif ($bootTime -gt 90) {
            $performanceScore -= 10
        }
    }

    if ($performanceScore -lt 0) { $performanceScore = 0 }
    if ($performanceScore -gt 100) { $performanceScore = 100 }

    Ninja-Property-Set OPSPerformanceScore $performanceScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Performance Score = $performanceScore"
    Write-Output "  CPU Utilization: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  Memory Utilization: $memUtilization%"
    Write-Output "  Disk Active Time: $([math]::Round($diskActiveTime, 1))%"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
