#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves CPU temperature information from hardware sensors.

.DESCRIPTION
    This script queries CPU temperature data using WMI thermal zone information. It retrieves 
    temperature readings from available thermal sensors and converts them to Celsius and 
    Fahrenheit. This data is useful for monitoring system health and detecting overheating issues.
    
    Temperature monitoring is critical for identifying cooling problems, thermal throttling, 
    and potential hardware failures. The script accesses Win32_TemperatureProbe when available 
    or uses alternative methods for temperature detection.

.PARAMETER SaveToCustomField
    Name of a custom field to save the CPU temperature reading.

.EXAMPLE
    -SaveToCustomField "CPUTemperature"

    [Info] Querying CPU temperature sensors...
    CPU Temperature: 45 C (113 F)
    [Info] Temperature saved to custom field 'CPUTemperature'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Note: Temperature sensor availability depends on hardware and drivers
    
.COMPONENT
    WMI - Win32_TemperatureProbe and thermal zone queries
    
.LINK
    https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-temperatureprobe

.FUNCTIONALITY
    - Queries WMI thermal zone information
    - Retrieves CPU temperature from hardware sensors
    - Converts temperatures to Celsius and Fahrenheit
    - Reports temperature readings for monitoring
    - Can save temperature data to custom fields
    - Handles systems without accessible temperature sensors
#>

[CmdletBinding()]
param(
    [string]$SaveToCustomField
)

begin {
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        $NinjaValue = $Value
        $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $ExitCode = 0
}

process {
    try {
        Write-Host "[Info] Querying CPU temperature sensors..."
        
        $TempData = Get-CimInstance -Namespace "root/WMI" -ClassName "MSAcpi_ThermalZoneTemperature" -ErrorAction SilentlyContinue

        if ($TempData) {
            $TempKelvin = $TempData.CurrentTemperature / 10
            $TempCelsius = $TempKelvin - 273.15
            $TempFahrenheit = ($TempCelsius * 9/5) + 32

            Write-Host "CPU Temperature: $([Math]::Round($TempCelsius, 1)) C ($([Math]::Round($TempFahrenheit, 1)) F)"

            if ($SaveToCustomField) {
                try {
                    "$([Math]::Round($TempCelsius, 1)) C" | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Host "[Info] Temperature saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Host "[Error] Failed to save to custom field: $_"
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Host "[Warn] CPU temperature sensors not accessible on this system"
            Write-Host "[Info] This may be due to hardware limitations or missing drivers"
        }
    }
    catch {
        Write-Host "[Error] Failed to query CPU temperature: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
