<#
.SYNOPSIS
    Performance Analyzer - System Responsiveness and Resource Utilization Scoring

.DESCRIPTION
    Calculates comprehensive system performance score by analyzing CPU utilization, memory
    consumption, disk activity, and system responsiveness. Provides weighted scoring model
    to identify performance bottlenecks and degradation patterns.
    
    Monitors real-time resource utilization across multiple performance counters to detect
    resource contention, thrashing, and capacity constraints. Uses 100-point scoring system
    with deductions for elevated resource usage across CPU, memory, and disk subsystems.
    
    Performance Scoring Model (100 points, deductions applied):
    
    CPU Utilization Impact:
    - >90% sustained: -20 points (severe contention)
    - >80% sustained: -15 points (high contention)
    - >70% sustained: -10 points (moderate load)
    
    Memory Utilization Impact:
    - >95% consumed: -20 points (paging/thrashing likely)
    - >85% consumed: -15 points (memory pressure)
    - >75% consumed: -10 points (elevated usage)
    
    Disk Activity Impact:
    - >90% active: -15 points (I/O bottleneck)
    - >80% active: -10 points (high I/O load)
    
    Boot Time Impact (if within 5 minutes of boot):
    - >120s: -15 points (slow boot performance)
    - >90s: -10 points (moderate boot delay)
    
    Score Interpretation:
    - 90-100: Excellent performance
    - 75-89: Good performance
    - 60-74: Fair performance, monitor closely
    - Below 60: Poor performance, investigation required

.NOTES
    Frequency: Every 4 hours
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - OPSPerformanceScore (Integer: 0-100 performance score)
    - OPSLastScoreUpdate (Text: timestamp in yyyy-MM-dd HH:mm:ss format)
    
    Dependencies:
    - Windows Performance Counters:
      - \Processor(_Total)\% Processor Time
      - \PhysicalDisk(_Total)\% Disk Time
    - WMI/CIM: Win32_OperatingSystem
    
    Performance Considerations:
    - Samples CPU over 6 seconds (3 samples at 2-second intervals)
    - Single disk counter sample for efficiency
    - Minimal overhead during measurement
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Performance Analyzer (v4.0)..."

    # Initialize performance score at maximum
    $performanceScore = 100

    # Get memory utilization
    Write-Output "INFO: Measuring memory utilization..."
    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
    Write-Output "INFO: Memory utilization: $memUtilization%"

    # Get CPU utilization (averaged over 6 seconds)
    Write-Output "INFO: Measuring CPU utilization (sampling 6 seconds)..."
    $cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average
    Write-Output "INFO: CPU utilization: $([math]::Round($cpuUtilization, 1))%"

    # Get disk activity
    Write-Output "INFO: Measuring disk activity..."
    try {
        $diskActiveTime = (Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        Write-Output "INFO: Disk active time: $([math]::Round($diskActiveTime, 1))%"
    } catch {
        Write-Output "WARNING: Unable to read disk counter, assuming 0%"
        $diskActiveTime = 0
    }

    # Apply CPU utilization penalties
    Write-Output "INFO: Evaluating CPU impact..."
    if ($cpuUtilization -gt 90) {
        $performanceScore -= 20
        Write-Output "WARNING: High CPU utilization >90% (-20 points)"
    } elseif ($cpuUtilization -gt 80) {
        $performanceScore -= 15
        Write-Output "WARNING: Elevated CPU utilization >80% (-15 points)"
    } elseif ($cpuUtilization -gt 70) {
        $performanceScore -= 10
        Write-Output "INFO: Moderate CPU utilization >70% (-10 points)"
    } else {
        Write-Output "INFO: CPU utilization normal (no penalty)"
    }

    # Apply memory utilization penalties
    Write-Output "INFO: Evaluating memory impact..."
    if ($memUtilization -gt 95) {
        $performanceScore -= 20
        Write-Output "WARNING: Critical memory pressure >95% (-20 points)"
    } elseif ($memUtilization -gt 85) {
        $performanceScore -= 15
        Write-Output "WARNING: High memory utilization >85% (-15 points)"
    } elseif ($memUtilization -gt 75) {
        $performanceScore -= 10
        Write-Output "INFO: Elevated memory utilization >75% (-10 points)"
    } else {
        Write-Output "INFO: Memory utilization normal (no penalty)"
    }

    # Apply disk activity penalties
    Write-Output "INFO: Evaluating disk impact..."
    if ($diskActiveTime -gt 90) {
        $performanceScore -= 15
        Write-Output "WARNING: Severe disk bottleneck >90% (-15 points)"
    } elseif ($diskActiveTime -gt 80) {
        $performanceScore -= 10
        Write-Output "WARNING: High disk activity >80% (-10 points)"
    } else {
        Write-Output "INFO: Disk activity normal (no penalty)"
    }

    # Check if system recently booted (within 5 minutes)
    $bootTime = ((Get-Date) - $os.LastBootUpTime).TotalSeconds
    if ($bootTime -lt 300) {
        Write-Output "INFO: System recently booted ($([math]::Round($bootTime))s ago), evaluating boot performance..."
        if ($bootTime -gt 120) {
            $performanceScore -= 15
            Write-Output "WARNING: Slow boot time >120s (-15 points)"
        } elseif ($bootTime -gt 90) {
            $performanceScore -= 10
            Write-Output "INFO: Moderate boot time >90s (-10 points)"
        } else {
            Write-Output "INFO: Good boot performance (no penalty)"
        }
    }

    # Enforce score boundaries
    if ($performanceScore -lt 0) { $performanceScore = 0 }
    if ($performanceScore -gt 100) { $performanceScore = 100 }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating performance metrics..."
    Ninja-Property-Set OPSPerformanceScore $performanceScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Performance analysis complete"
    Write-Output "FINAL SCORE: $performanceScore/100"
    Write-Output "METRICS SUMMARY:"
    Write-Output "  - CPU Utilization: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  - Memory Utilization: $memUtilization%"
    Write-Output "  - Disk Active Time: $([math]::Round($diskActiveTime, 1))%"
    
    # Provide performance assessment
    if ($performanceScore -ge 90) {
        Write-Output "ASSESSMENT: Excellent performance"
    } elseif ($performanceScore -ge 75) {
        Write-Output "ASSESSMENT: Good performance"
    } elseif ($performanceScore -ge 60) {
        Write-Output "ASSESSMENT: Fair performance - monitor closely"
    } else {
        Write-Output "ASSESSMENT: Poor performance - investigation required"
    }

    exit 0
} catch {
    Write-Output "ERROR: Performance Analyzer failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
