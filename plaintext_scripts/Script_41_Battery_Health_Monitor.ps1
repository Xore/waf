<#
.SYNOPSIS
    Battery Health Monitor - Laptop/Mobile Device Battery Health and Lifecycle Tracking

.DESCRIPTION
    Monitors battery health for laptops, tablets, and mobile devices including capacity
    degradation, charge cycles, chemistry, runtime estimation, and replacement recommendations.
    Essential for managing laptop fleet lifecycle and preventing unexpected battery failures.
    
    Critical for identifying batteries requiring replacement before they fail in the field,
    tracking warranty status based on cycle counts, and ensuring mobile workforce productivity.
    Automatically skips execution on desktop systems without batteries to avoid unnecessary
    resource consumption.
    
    Monitoring Scope:
    
    Battery Presence Detection:
    - Queries Win32_Battery WMI class
    - Detects laptops, tablets, 2-in-1 devices
    - Gracefully exits on desktops without batteries
    - Prevents false positives on desktop systems
    
    Battery Chemistry Identification:
    - Maps WMI chemistry codes to types:
      - 6: Lithium-Ion (most common laptops)
      - 8: Lithium-Polymer (thin/light devices)
      - 4: Nickel Cadmium (legacy)
      - 5: Nickel Metal Hydride (legacy)
    - Determines battery technology and characteristics
    
    Capacity Monitoring:
    - Design Capacity: Original manufacturer specification (mWh)
    - Full Charge Capacity: Current maximum charge (mWh)
    - Degradation tracking over battery lifetime
    
    Battery Health Calculation:
    - Health % = (Full Charge Capacity / Design Capacity) * 100
    - Typical new battery: 95-100%
    - Healthy battery: 80-100%
    - Worn battery: 60-80%
    - Failed battery: <60%
    
    Charge Status Monitoring:
    - Maps battery status codes:
      - 1: Discharging (on battery power)
      - 2: Charging (plugged in, not full)
      - 3: Full (100% charged)
      - 4: Low (approaching critical)
      - 5: Critical (imminent shutdown)
    
    Runtime Estimation:
    - Reads EstimatedRunTime from WMI
    - Returns minutes of battery life remaining
    - Special value 71582788: AC power/charging
    - Critical metric for mobile workers
    
    Cycle Count Tracking:
    - Primary: Parses powercfg /batteryreport XML
    - Fallback: Checks battery registry keys
    - Cycle = full discharge + recharge
    - Typical laptop battery rated for 300-1000 cycles
    
    Last Full Charge Timestamp:
    - Extracted from battery report XML
    - Tracks charging behavior patterns
    - Useful for troubleshooting charging issues
    
    Replacement Recommendation Logic:
    - Health <70%: Significant capacity loss
    - Cycle count >800: Exceeded typical lifespan
    - Runtime <60min when full: Insufficient for mobile use
    - Windows battery warning (Event ID 105): OS-detected failure
    
    Health Status Implications:
    - Replacement Recommended: Purchase new battery
    - Healthy: No action needed
    - Monitored continuously for degradation trends

.NOTES
    Frequency: Daily (full metrics), Every 4 hours (status/runtime)
    Runtime: ~15 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - BATBatteryPresent (Checkbox)
    - BATDesignCapacityMWh (Integer: Original capacity mWh)
    - BATFullChargeCapacityMWh (Integer: Current max capacity mWh)
    - BATHealthPercent (Integer: Capacity health %)
    - BATCycleCount (Integer: Charge/discharge cycles)
    - BATChemistry (Text: Battery technology type)
    - BATEstimatedRuntime (Integer: Minutes remaining)
    - BATChargeStatus (Text: Charging, Discharging, Full, Low, Critical)
    - BATLastFullCharge (DateTime: Last 100% charge timestamp)
    - BATReplacementRecommended (Checkbox: Needs replacement)
    
    Dependencies:
    - Win32_Battery WMI class
    - powercfg.exe (battery report generation)
    - Battery present in system
    
    Device Targeting:
    - Laptops: Primary use case
    - Tablets: Surface, iPad-like devices
    - 2-in-1 devices: Convertible laptops
    - Mobile workstations: Dell Precision, HP ZBook
    
    Battery Chemistry Types:
    - Lithium-Ion: Most common, good energy density
    - Lithium-Polymer: Thin devices, flexible form factor
    - Nickel Cadmium: Legacy, memory effect
    - Nickel Metal Hydride: Legacy, better than NiCd
    
    Typical Battery Lifespans:
    - Consumer laptops: 300-500 cycles (2-3 years)
    - Business laptops: 500-800 cycles (3-5 years)
    - Premium laptops: 800-1000 cycles (5+ years)
    
    Replacement Criteria:
    - Health <70%: Capacity too low for productive use
    - Cycles >800: Approaching end of rated lifespan
    - Runtime <60min: Insufficient for meetings/travel
    - Windows warning: OS detected battery failure
    
    Common Issues:
    - No battery found: Normal for desktops
    - Cycle count 0: Registry data missing or new battery
    - Runtime 71582788: Currently on AC power
    - Health >100%: Calibration issue or measurement error
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting Battery Health Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    $batteryPresent = $false
    $designCapacity = 0
    $fullChargeCapacity = 0
    $healthPercent = 100
    $cycleCount = 0
    $chemistry = "Unknown"
    $estimatedRuntime = 0
    $chargeStatus = "Unknown"
    $lastFullCharge = ""
    $replacementRecommended = $false
    
    Write-Output "INFO: Checking for battery..."
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    
    if ($null -eq $battery) {
        Write-Output "INFO: No battery detected (likely desktop system)"
        
        Ninja-Property-Set batBatteryPresent $false
        Ninja-Property-Set batDesignCapacityMWh 0
        Ninja-Property-Set batFullChargeCapacityMWh 0
        Ninja-Property-Set batHealthPercent 100
        Ninja-Property-Set batCycleCount 0
        Ninja-Property-Set batChemistry "N/A"
        Ninja-Property-Set batEstimatedRuntime 0
        Ninja-Property-Set batChargeStatus "Unknown"
        Ninja-Property-Set batLastFullCharge ""
        Ninja-Property-Set batReplacementRecommended $false
        
        Write-Output "SUCCESS: Battery monitoring skipped (no battery)"
        exit 0
    }
    
    $batteryPresent = $true
    Write-Output "INFO: Battery detected: $($battery.Name)"
    
    $chemistryCode = $battery.Chemistry
    $chemistry = switch ($chemistryCode) {
        1 { "Other" }
        2 { "Unknown" }
        3 { "Lead Acid" }
        4 { "Nickel Cadmium" }
        5 { "Nickel Metal Hydride" }
        6 { "Lithium-Ion" }
        7 { "Zinc Air" }
        8 { "Lithium-Polymer" }
        default { "Unknown" }
    }
    Write-Output "INFO: Battery chemistry: $chemistry"
    
    $designCapacity = $battery.DesignCapacity
    Write-Output "INFO: Design capacity: $designCapacity mWh"
    
    $fullChargeCapacity = $battery.FullChargeCapacity
    Write-Output "INFO: Full charge capacity: $fullChargeCapacity mWh"
    
    if ($designCapacity -gt 0 -and $fullChargeCapacity -gt 0) {
        $healthPercent = [Math]::Round(($fullChargeCapacity / $designCapacity) * 100)
        if ($healthPercent -gt 100) { $healthPercent = 100 }
        Write-Output "INFO: Battery health: $healthPercent%"
    }
    
    $batteryStatusCode = $battery.BatteryStatus
    $chargeStatus = switch ($batteryStatusCode) {
        1 { "Discharging" }
        2 { "Charging" }
        3 { "Full" }
        4 { "Low" }
        5 { "Critical" }
        6 { "Charging" }
        7 { "Charging" }
        8 { "Charging" }
        9 { "Charging" }
        10 { "Unknown" }
        11 { "Discharging" }
        default { "Unknown" }
    }
    Write-Output "INFO: Charge status: $chargeStatus"
    
    $estimatedRuntimeMinutes = $battery.EstimatedRunTime
    if ($estimatedRuntimeMinutes -eq 71582788) {
        $estimatedRuntime = 0
        Write-Output "INFO: Estimated runtime: N/A (on AC power)"
    } else {
        $estimatedRuntime = $estimatedRuntimeMinutes
        Write-Output "INFO: Estimated runtime: $estimatedRuntime minutes"
    }
    
    Write-Output "INFO: Generating battery report for cycle count..."
    try {
        $reportPath = "$env:TEMP\battery-report.xml"
        
        $null = powercfg /batteryreport /xml /output $reportPath 2>&1
        
        if (Test-Path $reportPath) {
            [xml]$reportXml = Get-Content $reportPath
            
            $cycleCountNode = $reportXml.SelectSingleNode("//CycleCount")
            if ($cycleCountNode) {
                $cycleCount = [int]$cycleCountNode.InnerText
                Write-Output "INFO: Cycle count: $cycleCount"
            }
            
            $lastFullChargeNode = $reportXml.SelectSingleNode("//History/LastFullCharge")
            if ($lastFullChargeNode) {
                $lastFullChargeDate = [DateTime]::Parse($lastFullChargeNode.InnerText)
                $lastFullCharge = $lastFullChargeDate.ToString("yyyy-MM-dd HH:mm:ss")
                Write-Output "INFO: Last full charge: $lastFullCharge"
            }
            
            Remove-Item $reportPath -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Output "WARNING: Failed to get cycle count from battery report: $_"
    }
    
    if ($cycleCount -eq 0) {
        try {
            $batteryKeys = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{72631e54-78a4-11d0-bcf7-00aa00b7b32a}" -ErrorAction SilentlyContinue
            foreach ($key in $batteryKeys) {
                $cycleCountValue = (Get-ItemProperty -Path $key.PSPath -Name "CycleCount" -ErrorAction SilentlyContinue).CycleCount
                if ($cycleCountValue) {
                    $cycleCount = $cycleCountValue
                    Write-Output "INFO: Cycle count (from registry): $cycleCount"
                    break
                }
            }
        } catch {
            Write-Output "WARNING: Failed to get cycle count from registry: $_"
        }
    }
    
    Write-Output "INFO: Evaluating replacement recommendation..."
    $replacementRecommended = $false
    
    if ($healthPercent -lt 70) {
        $replacementRecommended = $true
        Write-Output "  CRITERIA: Health below 70% ($healthPercent%)"
    } elseif ($cycleCount -gt 800) {
        $replacementRecommended = $true
        Write-Output "  CRITERIA: Cycle count exceeds 800 ($cycleCount)"
    } elseif ($estimatedRuntime -lt 60 -and $chargeStatus -eq "Full") {
        $replacementRecommended = $true
        Write-Output "  CRITERIA: Runtime under 60 minutes when full ($estimatedRuntime min)"
    }
    
    try {
        $batteryWarning = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-Kernel-Power'
            Id = 105
            StartTime = (Get-Date).AddDays(-30)
        } -MaxEvents 1 -ErrorAction SilentlyContinue
        
        if ($batteryWarning) {
            $replacementRecommended = $true
            Write-Output "  CRITERIA: Windows battery warning detected"
        }
    } catch {
        # No warning found
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set batBatteryPresent $true
    Ninja-Property-Set batDesignCapacityMWh $designCapacity
    Ninja-Property-Set batFullChargeCapacityMWh $fullChargeCapacity
    Ninja-Property-Set batHealthPercent $healthPercent
    Ninja-Property-Set batCycleCount $cycleCount
    Ninja-Property-Set batChemistry $chemistry
    Ninja-Property-Set batEstimatedRuntime $estimatedRuntime
    Ninja-Property-Set batChargeStatus $chargeStatus
    Ninja-Property-Set batLastFullCharge $lastFullCharge
    Ninja-Property-Set batReplacementRecommended $replacementRecommended
    
    Write-Output "SUCCESS: Battery Health monitoring complete"
    Write-Output "BATTERY HEALTH METRICS:"
    Write-Output "  - Chemistry: $chemistry"
    Write-Output "  - Health: $healthPercent%"
    Write-Output "  - Design Capacity: $designCapacity mWh"
    Write-Output "  - Full Charge Capacity: $fullChargeCapacity mWh"
    Write-Output "  - Cycle Count: $cycleCount"
    Write-Output "  - Charge Status: $chargeStatus"
    Write-Output "  - Runtime: $estimatedRuntime minutes"
    Write-Output "  - Replacement Recommended: $replacementRecommended"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: Battery Health Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set batBatteryPresent $false
    Ninja-Property-Set batChemistry "Error"
    
    exit 1
}
