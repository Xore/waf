<#
.SYNOPSIS
    Script 41: Battery Health Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors battery health for laptops and mobile devices including capacity, degradation,
    cycle count, charge status, and replacement recommendations. Updates 10 BAT fields.
    Automatically skips execution on desktop systems without batteries.

.FIELDS UPDATED
    - BATBatteryPresent (Checkbox)
    - BATDesignCapacityMWh (Integer)
    - BATFullChargeCapacityMWh (Integer)
    - BATHealthPercent (Integer)
    - BATCycleCount (Integer)
    - BATChemistry (Text)
    - BATEstimatedRuntime (Integer)
    - BATChargeStatus (Text)
    - BATLastFullCharge (DateTime)
    - BATReplacementRecommended (Checkbox)

.EXECUTION
    Frequency: Daily (full metrics), Every 4 hours (status/runtime)
    Runtime: ~15 seconds
    Requires: Battery present (laptops/tablets)

.NOTES
    File: Script_41_Battery_Health_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Hardware Monitoring
    Dependencies: Win32_Battery WMI class
    Device Targeting: Laptops, tablets, 2-in-1 devices only

.RELATED DOCUMENTATION
    - docs/core/13_BAT_Battery_Health.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 2)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Battery Health Monitor (Script 41)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
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
    
    # Check if battery is present
    Write-Host "Checking for battery..."
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    
    if ($null -eq $battery) {
        Write-Host "No battery detected. This is likely a desktop system."
        
        # Update fields for no-battery state
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
        
        Write-Host "Battery Health Monitor complete (no battery)."
        exit 0
    }
    
    $batteryPresent = $true
    Write-Host "Battery detected: $($battery.Name)"
    
    # Get battery chemistry
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
    Write-Host "Battery Chemistry: $chemistry"
    
    # Get design capacity (in mWh)
    $designCapacity = $battery.DesignCapacity
    Write-Host "Design Capacity: $designCapacity mWh"
    
    # Get full charge capacity (in mWh)
    $fullChargeCapacity = $battery.FullChargeCapacity
    Write-Host "Full Charge Capacity: $fullChargeCapacity mWh"
    
    # Calculate battery health percentage
    if ($designCapacity -gt 0 -and $fullChargeCapacity -gt 0) {
        $healthPercent = [Math]::Round(($fullChargeCapacity / $designCapacity) * 100)
        # Cap at 100%
        if ($healthPercent -gt 100) { $healthPercent = 100 }
        Write-Host "Battery Health: $healthPercent%"
    }
    
    # Get charge status
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
    Write-Host "Charge Status: $chargeStatus"
    
    # Get estimated runtime (in minutes)
    $estimatedRuntimeMinutes = $battery.EstimatedRunTime
    if ($estimatedRuntimeMinutes -eq 71582788) {
        # Battery is charging or on AC power
        $estimatedRuntime = 0
    } else {
        $estimatedRuntime = $estimatedRuntimeMinutes
    }
    Write-Host "Estimated Runtime: $estimatedRuntime minutes"
    
    # Get cycle count from battery report
    try {
        Write-Host "Generating battery report for cycle count..."
        $reportPath = "$env:TEMP\battery-report.xml"
        
        # Generate battery report
        $null = powercfg /batteryreport /xml /output $reportPath 2>&1
        
        if (Test-Path $reportPath) {
            [xml]$reportXml = Get-Content $reportPath
            
            # Extract cycle count
            $cycleCountNode = $reportXml.SelectSingleNode("//CycleCount")
            if ($cycleCountNode) {
                $cycleCount = [int]$cycleCountNode.InnerText
                Write-Host "Cycle Count: $cycleCount"
            }
            
            # Extract last full charge timestamp
            $lastFullChargeNode = $reportXml.SelectSingleNode("//History/LastFullCharge")
            if ($lastFullChargeNode) {
                $lastFullChargeDate = [DateTime]::Parse($lastFullChargeNode.InnerText)
                $lastFullCharge = $lastFullChargeDate.ToString("yyyy-MM-dd HH:mm:ss")
                Write-Host "Last Full Charge: $lastFullCharge"
            }
            
            # Clean up report file
            Remove-Item $reportPath -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "Failed to get cycle count from battery report: $_"
    }
    
    # If cycle count not found from report, check registry
    if ($cycleCount -eq 0) {
        try {
            $batteryKeys = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{72631e54-78a4-11d0-bcf7-00aa00b7b32a}" -ErrorAction SilentlyContinue
            foreach ($key in $batteryKeys) {
                $cycleCountValue = (Get-ItemProperty -Path $key.PSPath -Name "CycleCount" -ErrorAction SilentlyContinue).CycleCount
                if ($cycleCountValue) {
                    $cycleCount = $cycleCountValue
                    Write-Host "Cycle Count (from registry): $cycleCount"
                    break
                }
            }
        } catch {
            Write-Warning "Failed to get cycle count from registry: $_"
        }
    }
    
    # Determine if replacement is recommended
    $replacementRecommended = $false
    
    if ($healthPercent -lt 70) {
        $replacementRecommended = $true
        Write-Host "Replacement recommended: Health below 70%"
    } elseif ($cycleCount -gt 800) {
        $replacementRecommended = $true
        Write-Host "Replacement recommended: Cycle count exceeds 800"
    } elseif ($estimatedRuntime -lt 60 -and $chargeStatus -eq "Full") {
        $replacementRecommended = $true
        Write-Host "Replacement recommended: Runtime under 60 minutes when full"
    }
    
    # Check for Windows battery warning
    try {
        $batteryWarning = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-Kernel-Power'
            Id = 105  # Battery replacement warning
            StartTime = (Get-Date).AddDays(-30)
        } -MaxEvents 1 -ErrorAction SilentlyContinue
        
        if ($batteryWarning) {
            $replacementRecommended = $true
            Write-Host "Replacement recommended: Windows battery warning detected"
        }
    } catch {
        # No warning found, continue
    }
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
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
    
    Write-Host "Battery Health Monitor complete. Health: $healthPercent%, Replacement: $replacementRecommended"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Battery Health Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set batBatteryPresent $false
    Ninja-Property-Set batChemistry "Error"
    
    exit 1
}
