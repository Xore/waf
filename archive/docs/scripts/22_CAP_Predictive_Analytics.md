# Script 22: CAP Capacity Trend Forecaster

**File:** Script_22_CAP_Predictive_Analytics.md  
**Version:** v1.0  
**Script Number:** 22  
**Category:** Extended Automation - Predictive Capacity  
**Last Updated:** February 2, 2026

---

## Purpose

Predict resource exhaustion dates using trend analysis and forecasting.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~25 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [CAPMemoryForecastRisk](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (Dropdown: Low, Medium, High, Critical)
- [CAPCPUForecastRisk](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (Dropdown: Low, Medium, High, Critical)
- [CAPDaysUntilDiskFull](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (Integer)

---

## PowerShell Implementation

```powershell
# Script 22: Capacity Trend Forecaster
# Predict resource exhaustion

param()

try {
    Write-Output "Starting Capacity Trend Forecaster (v1.0)"

    # Get current disk usage
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $diskSizeGB = [math]::Round($disk.Size / 1GB, 2)
    $diskUsedGB = $diskSizeGB - $diskFreeGB

    # Get historical disk usage
    $historicalUsage = Ninja-Property-Get capHistoricalDiskUsage
    
    if ([string]::IsNullOrEmpty($historicalUsage)) {
        # First run - initialize history
        $history = @{
            Date = (Get-Date -Format "yyyy-MM-dd")
            UsedGB = $diskUsedGB
        }
        $historyJson = @($history) | ConvertTo-Json -Compress
        Ninja-Property-Set capHistoricalDiskUsage $historyJson
        
        $daysUntilFull = 999
        $growthRate = 0
    } else {
        # Parse history
        try {
            $historyArray = $historicalUsage | ConvertFrom-Json
            if ($historyArray -is [System.Array]) {
                $historyList = $historyArray
            } else {
                $historyList = @($historyArray)
            }
        } catch {
            $historyList = @()
        }

        # Add current reading
        $newEntry = @{
            Date = (Get-Date -Format "yyyy-MM-dd")
            UsedGB = $diskUsedGB
        }
        $historyList += $newEntry

        # Keep last 30 days only
        if ($historyList.Count -gt 30) {
            $historyList = $historyList | Select-Object -Last 30
        }

        # Calculate growth rate (GB per day)
        if ($historyList.Count -ge 2) {
            $oldestEntry = $historyList[0]
            $newestEntry = $historyList[-1]
            $daysDiff = ((Get-Date) - [DateTime]::Parse($oldestEntry.Date)).Days
            
            if ($daysDiff -gt 0) {
                $growthRate = ($newestEntry.UsedGB - $oldestEntry.UsedGB) / $daysDiff
            } else {
                $growthRate = 0
            }

            # Predict days until full
            if ($growthRate -gt 0.1) {
                $daysUntilFull = [math]::Round($diskFreeGB / $growthRate)
            } else {
                $daysUntilFull = 999
            }
        } else {
            $growthRate = 0
            $daysUntilFull = 999
        }

        # Save updated history
        $historyJson = $historyList | ConvertTo-Json -Compress
        Ninja-Property-Set capHistoricalDiskUsage $historyJson
    }

    # Assess memory forecast risk
    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    if ($memUtilization -gt 90) {
        $memRisk = "Critical"
    } elseif ($memUtilization -gt 85) {
        $memRisk = "High"
    } elseif ($memUtilization -gt 80) {
        $memRisk = "Medium"
    } else {
        $memRisk = "Low"
    }

    # Assess CPU forecast risk
    $cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    if ($cpuUtilization -gt 90) {
        $cpuRisk = "Critical"
    } elseif ($cpuUtilization -gt 80) {
        $cpuRisk = "High"
    } elseif ($cpuUtilization -gt 70) {
        $cpuRisk = "Medium"
    } else {
        $cpuRisk = "Low"
    }

    # Update custom fields
    Ninja-Property-Set capMemoryForecastRisk $memRisk
    Ninja-Property-Set capCPUForecastRisk $cpuRisk
    Ninja-Property-Set capDaysUntilDiskFull $daysUntilFull
    Ninja-Property-Set capGrowthRate ([math]::Round($growthRate, 3))

    Write-Output "SUCCESS: Capacity forecast completed"
    Write-Output "  Disk Growth Rate: $([math]::Round($growthRate, 2)) GB/day"
    Write-Output "  Days Until Full: $daysUntilFull"
    Write-Output "  Memory Risk: $memRisk"
    Write-Output "  CPU Risk: $cpuRisk"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [CAP Capacity Fields](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md)
- [Script 05: Capacity Analyzer](Script_05_OPS_Capacity_Analyzer.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_22_CAP_Predictive_Analytics.md  
**Version:** v1.0  
**Status:** Production Ready
