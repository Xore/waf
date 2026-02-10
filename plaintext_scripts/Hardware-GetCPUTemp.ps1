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
    .\Hardware-GetCPUTemp.ps1 -SaveToCustomField "CPUTemperature"

    [2026-02-10 16:30:00] [INFO] Querying CPU temperature sensors
    [2026-02-10 16:30:00] [INFO] CPU Temperature: 45.0 C (113.0 F)
    [2026-02-10 16:30:00] [INFO] Temperature saved to custom field: CPUTemperature

.OUTPUTS
    None. Temperature data is written to console and optionally to NinjaRMM custom field.

.NOTES
    File Name      : Hardware-GetCPUTemp.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
    Note: Temperature sensor availability depends on hardware and drivers.
    
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
    [Parameter()]
    [string]$SaveToCustomField
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $ExitCode = 0
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $LogMessage }
            'WARNING' { Write-Warning $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $Value
        )
        try {
            $NinjaValue = $Value
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            throw "Failed to set NinjaRMM property: $_"
        }
    }
}

process {
    try {
        Write-Log "Querying CPU temperature sensors"
        
        $TempData = Get-CimInstance -Namespace "root/WMI" -ClassName "MSAcpi_ThermalZoneTemperature" -ErrorAction SilentlyContinue

        if ($TempData) {
            $TempKelvin = $TempData.CurrentTemperature / 10
            $TempCelsius = $TempKelvin - 273.15
            $TempFahrenheit = ($TempCelsius * 9/5) + 32

            Write-Log "CPU Temperature: $([Math]::Round($TempCelsius, 1)) C ($([Math]::Round($TempFahrenheit, 1)) F)"

            if ($SaveToCustomField) {
                try {
                    "$([Math]::Round($TempCelsius, 1)) C" | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Log "Temperature saved to custom field: $SaveToCustomField"
                }
                catch {
                    Write-Log "Failed to save to custom field: $_" -Level ERROR
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Log "CPU temperature sensors not accessible on this system" -Level WARNING
            Write-Log "This may be due to hardware limitations or missing drivers"
        }
    }
    catch {
        Write-Log "Failed to query CPU temperature: $_" -Level ERROR
        $ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $Duration seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
