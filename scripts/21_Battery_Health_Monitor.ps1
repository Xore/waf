<#
.SYNOPSIS
    NinjaRMM Script 21: Battery Health Monitor (Laptops)

.DESCRIPTION
    Monitors battery health and capacity for mobile devices.
    Tracks battery wear level and charging behavior.

.NOTES
    Frequency: Daily
    Runtime: ~10 seconds
    Timeout: 30 seconds
    Context: SYSTEM
    
    Fields Updated:
    - hwBatteryCapacityPercent (Integer 0-100)
    - hwBatteryWearLevel (Integer 0-100)
    - hwBatteryStatus (Dropdown: Good, Fair, Poor, Critical, None)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    # Check if device has battery
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue

    if (-not $battery) {
        Ninja-Property-Set hwBatteryStatus "None"
        Write-Output "No battery detected - skipping"
        exit 0
    }

    # Get battery capacity
    $designCapacity = $battery.DesignCapacity
    $fullChargeCapacity = $battery.FullChargeCapacity

    if ($designCapacity -and $fullChargeCapacity) {
        $capacityPercent = [math]::Round(($fullChargeCapacity / $designCapacity) * 100, 0)
        $wearLevel = 100 - $capacityPercent

        Ninja-Property-Set hwBatteryCapacityPercent $capacityPercent
        Ninja-Property-Set hwBatteryWearLevel $wearLevel

        # Determine battery status
        if ($capacityPercent -ge 90) {
            $status = "Good"
        } elseif ($capacityPercent -ge 70) {
            $status = "Fair"
        } elseif ($capacityPercent -ge 50) {
            $status = "Poor"
        } else {
            $status = "Critical"
        }

        Ninja-Property-Set hwBatteryStatus $status

        Write-Output "Battery Status: $status | Capacity: $capacityPercent% | Wear: $wearLevel%"
    } else {
        Write-Output "Could not determine battery capacity"
    }

} catch {
    Write-Output "Error: $_"
    exit 1
}
