<#
.SYNOPSIS
    NinjaRMM Script 1: Health Score Calculator

.DESCRIPTION
    Calculate overall device health composite score combining multiple data sources.
    Native-Enhanced v4.0 - Integrates with NinjaOne native monitoring.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~15 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - OPSHealthScore (Integer 0-100)
    - OPSLastScoreUpdate (DateTime)
    
    Native Integration:
    - Queries Disk Free Space (native)
    - Queries Memory Utilization (native)
    - Queries CPU Utilization (native)
    - Combines with custom telemetry (STATAppCrashes24h)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

try {
    Write-Output "Starting Health Score Calculator (v4.0 Native-Enhanced)"

    # Initialize base score
    $healthScore = 100

    # Query native metrics
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    $cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    # Query custom telemetry
    $crashes = Ninja-Property-Get STATAppCrashes24h
    if ([string]::IsNullOrEmpty($crashes)) { $crashes = 0 }

    # Calculate deductions
    if ($crashes -gt 10) { $healthScore -= 20 }
    elseif ($crashes -gt 5) { $healthScore -= 10 }
    elseif ($crashes -gt 2) { $healthScore -= 5 }

    if ($diskFreePercent -lt 5) { $healthScore -= 30 }
    elseif ($diskFreePercent -lt 10) { $healthScore -= 20 }
    elseif ($diskFreePercent -lt 15) { $healthScore -= 15 }

    if ($memUtilization -gt 95) { $healthScore -= 20 }
    elseif ($memUtilization -gt 90) { $healthScore -= 15 }
    elseif ($memUtilization -gt 85) { $healthScore -= 10 }

    if ($cpuUtilization -gt 90) { $healthScore -= 15 }
    elseif ($cpuUtilization -gt 80) { $healthScore -= 10 }

    # Ensure score stays within bounds
    if ($healthScore -lt 0) { $healthScore = 0 }
    if ($healthScore -gt 100) { $healthScore = 100 }

    # Update fields
    Ninja-Property-Set OPSHealthScore $healthScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Health Score = $healthScore"
    Write-Output "  Disk Free: $diskFreePercent%"
    Write-Output "  Memory Utilization: $memUtilization%"
    Write-Output "  CPU Utilization: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  Crashes (24h): $crashes"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
