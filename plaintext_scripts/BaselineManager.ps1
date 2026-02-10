<#
.SYNOPSIS
    Baseline Manager - Performance Baseline Establishment and Drift Detection

.DESCRIPTION
    Establishes and maintains performance baselines for system metrics (CPU, memory, disk) and
    detects drift from normal operating parameters. Uses statistical tracking to identify when
    system performance characteristics change significantly from established patterns.
    
    Implements continuous baseline tracking by periodically sampling key performance metrics and
    comparing current values against previously established baselines. Calculates weighted drift
    scores to quantify deviation magnitude and trigger alerts when systems exhibit abnormal behavior.
    
    Baseline Metrics Tracked:
    
    CPU Utilization:
    - Average processor usage over 6-second sampling period
    - Baseline represents typical CPU load during normal operations
    - Significant drift may indicate new workloads or performance issues
    - Weight: 40% of drift score
    
    Memory Utilization:
    - Percentage of physical memory consumed
    - Baseline represents typical memory footprint
    - Significant drift may indicate memory leaks or capacity issues
    - Weight: 40% of drift score
    
    Disk Free Space:
    - Percentage of C: drive remaining free
    - Baseline represents typical disk consumption rate
    - Significant drift may indicate disk space exhaustion
    - Weight: 20% of drift score
    
    Drift Score Calculation (0-100):
    - Weighted sum of absolute differences from baseline
    - Formula: (CPU_drift * 0.4) + (Memory_drift * 0.4) + (Disk_drift * 0.2)
    - Higher scores indicate greater deviation from normal
    
    Drift Score Interpretation:
    - 0-10: Normal variation (noise)
    - 11-25: Minor drift (monitor)
    - 26-50: Moderate drift (investigate)
    - 51+: Significant drift (immediate attention)
    
    Use Cases:
    - Capacity planning and trend analysis
    - Anomaly detection for performance issues
    - Change impact assessment
    - SLA compliance verification
    - Proactive problem identification

.NOTES
    Frequency: Daily
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - BASEPerformanceBaseline (Text: JSON with CPU, Memory, DiskFree metrics)
    - BASEDriftScore (Integer: 0-100 weighted drift score)
    - BASELastUpdated (DateTime: Unix Epoch seconds since 1970-01-01 UTC)
    
    Dependencies:
    - Windows Performance Counters: \Processor(_Total)\% Processor Time
    - WMI/CIM: Win32_OperatingSystem, Win32_LogicalDisk
    
    Baseline Data Format (JSON):
    {
        "CPU": 15.50,
        "Memory": 45.23,
        "DiskFree": 62.75
    }
    
    Technical Notes:
    - Uses Unix Epoch timestamps for timezone-independent storage
    - JSON contains only metric data (no embedded timestamps)
    - NinjaOne handles timezone display automatically
    - Drift calculated only when previous baseline exists
    - First run establishes initial baseline (drift = 0)
    
    Framework Version: 4.1
    Last Updated: February 4, 2026
    
.MIGRATION NOTES
    v4.0 -> v4.1 Changes:
    - Removed Timestamp from JSON structure
    - Added separate BASELastUpdated Date/Time field (Unix Epoch format)
    - Uses inline DateTimeOffset conversion (no helper functions needed)
    - Maintains human-readable logging for troubleshooting
    - JSON now contains only metric data
    
.RELATED DOCUMENTATION
    - docs/DATE_TIME_FIELD_AUDIT.md
    - docs/DATE_TIME_FIELD_MAPPING.md
    - docs/ACTION_PLAN_Field_Conversion_Documentation.md (v1.9)
#>

param()

try {
    Write-Output "Starting Baseline Manager (v4.1)..."

    # Collect current system metrics
    Write-Output "INFO: Collecting current system metrics..."
    
    # Memory utilization
    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
    Write-Output "INFO: Memory utilization: $memUtilization%"

    # CPU utilization (6-second average)
    $cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average
    Write-Output "INFO: CPU utilization: $([math]::Round($cpuUtilization, 1))%"

    # Disk free space percentage
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
    $diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    Write-Output "INFO: Disk free: $diskFreePercent% ($diskFreeGB GB)"

    # Build baseline metric object (no timestamp in JSON)
    Write-Output "INFO: Building baseline metrics..."
    $baseline = @{
        CPU = [math]::Round($cpuUtilization, 2)
        Memory = $memUtilization
        DiskFree = $diskFreePercent
    }

    $baselineJson = $baseline | ConvertTo-Json -Compress
    
    # Create Unix Epoch timestamp for separate field
    $timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $readableTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # Calculate drift from previous baseline
    Write-Output "INFO: Calculating drift from previous baseline..."
    $existingBaseline = Ninja-Property-Get BASEPerformanceBaseline
    $driftScore = 0

    if (-not [string]::IsNullOrEmpty($existingBaseline)) {
        try {
            $oldBaseline = $existingBaseline | ConvertFrom-Json
            
            # Calculate individual metric drifts
            $cpuDrift = [math]::Abs($baseline.CPU - $oldBaseline.CPU)
            $memDrift = [math]::Abs($baseline.Memory - $oldBaseline.Memory)
            $diskDrift = [math]::Abs($baseline.DiskFree - $oldBaseline.DiskFree)

            Write-Output "INFO: Drift analysis:"
            Write-Output "  - CPU drift: $([math]::Round($cpuDrift, 2))% (weight: 40%)"
            Write-Output "  - Memory drift: $([math]::Round($memDrift, 2))% (weight: 40%)"
            Write-Output "  - Disk drift: $([math]::Round($diskDrift, 2))% (weight: 20%)"

            # Calculate weighted drift score
            $driftScore = [int](($cpuDrift * 0.4) + ($memDrift * 0.4) + ($diskDrift * 0.2))
            if ($driftScore -gt 100) { $driftScore = 100 }
            
            # Provide drift assessment
            if ($driftScore -gt 50) {
                Write-Output "ALERT: Significant drift detected ($driftScore) - immediate attention required"
            } elseif ($driftScore -gt 25) {
                Write-Output "WARNING: Moderate drift detected ($driftScore) - investigation recommended"
            } elseif ($driftScore -gt 10) {
                Write-Output "INFO: Minor drift detected ($driftScore) - monitor for trends"
            } else {
                Write-Output "INFO: Normal variation ($driftScore) - within expected range"
            }
        } catch {
            Write-Output "WARNING: Could not parse previous baseline, resetting drift to 0"
            $driftScore = 0
        }
    } else {
        Write-Output "INFO: No previous baseline found - establishing initial baseline"
        $driftScore = 0
    }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating baseline fields..."
    Ninja-Property-Set BASEPerformanceBaseline $baselineJson
    Ninja-Property-Set BASEDriftScore $driftScore
    Ninja-Property-Set BASELastUpdated $timestamp

    Write-Output "SUCCESS: Baseline updated at $readableTime"
    Write-Output "CURRENT METRICS:"
    Write-Output "  - CPU: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  - Memory: $memUtilization%"
    Write-Output "  - Disk Free: $diskFreePercent% ($diskFreeGB GB)"
    Write-Output "  - Drift Score: $driftScore/100"
    Write-Output "BASELINE JSON: $baselineJson"
    Write-Output "TIMESTAMP (Unix Epoch): $timestamp"

    exit 0
} catch {
    Write-Output "ERROR: Baseline Manager failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
