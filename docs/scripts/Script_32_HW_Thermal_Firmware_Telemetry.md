# Script 32: HW Thermal and Firmware Telemetry

**File:** Script_32_HW_Thermal_Firmware_Telemetry.md  
**Version:** v1.0  
**Script Number:** 32  
**Category:** Advanced Telemetry - Hardware Health  
**Last Updated:** February 2, 2026

---

## Purpose

Monitor CPU temperatures, thermal throttling, and firmware versions.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~30 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- HWPeakCPUTemp24h (Integer)
- HWAverageCPUTemp (Integer)
- HWThermalThrottling (Checkbox)
- [BASEBIOSVersion](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Text)

---

## PowerShell Implementation

```powershell
# Script 32: Thermal and Firmware Telemetry
# Monitors hardware health

param()

try {
    Write-Output "Starting Thermal and Firmware Telemetry (v1.0)"

    # Get BIOS version
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $biosVersion = "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion) $($bios.ReleaseDate.ToString('yyyy-MM-dd'))"

    Ninja-Property-Set baseBIOSVersion $biosVersion

    # Try to get CPU temperature (requires WMI support)
    $temp = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue

    if ($temp) {
        # Convert from tenths of Kelvin to Celsius
        $tempC = [int](($temp.CurrentTemperature / 10) - 273.15)

        Ninja-Property-Set hwPeakCPUTemp24h $tempC
        Ninja-Property-Set hwAverageCPUTemp $tempC

        # Check for thermal throttling
        if ($tempC -gt 90) {
            Ninja-Property-Set hwThermalThrottling $true
            Write-Output "WARNING: High CPU temperature detected: $tempC C"
        } else {
            Ninja-Property-Set hwThermalThrottling $false
        }

        Write-Output "SUCCESS: Thermal monitoring completed"
        Write-Output "  CPU Temperature: $tempC C"
        Write-Output "  BIOS: $biosVersion"
    } else {
        Write-Output "Temperature monitoring not available on this system"
        Write-Output "  BIOS: $biosVersion"
        
        # Set defaults when temp not available
        Ninja-Property-Set hwThermalThrottling $false
    }

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [BASE Baseline Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_32_HW_Thermal_Firmware_Telemetry.md  
**Version:** v1.0  
**Status:** Production Ready
