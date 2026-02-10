#Requires -Version 5.1

<#
.SYNOPSIS
    Updates NinjaRMM device location based on public IP geolocation.

.DESCRIPTION
    Retrieves the device's public IP address and uses geolocation services to
    determine physical location. Updates the NinjaRMM device location field with
    detected city, region, and country information.
    
    Useful for mobile devices and remote workers to ensure accurate inventory
    and reporting data in the RMM system.

.PARAMETER GeoIPService
    Geolocation API service URL.
    Default: https://ipapi.co/json/

.PARAMETER CustomFieldName
    Name of the custom field to store location data.
    Default: DeviceLocation

.EXAMPLE
    Device-UpdateLocation.ps1
    Detects location and updates default custom field.

.EXAMPLE
    Device-UpdateLocation.ps1 -GeoIPService "https://api.ipgeolocation.io/ipgeo" -CustomFieldName "LOCATION"
    Uses alternate API and custom field name.

.NOTES
    File Name      : Device-UpdateLocation.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Requires       : Internet connectivity
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 format with enhanced error handling
    - 1.0: Initial version
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$GeoIPService = 'https://ipapi.co/json/',
    
    [Parameter()]
    [string]$CustomFieldName = 'DeviceLocation'
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest
    
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        Write-Output $logMessage
        
        if ($Level -eq 'ERROR') { $script:ErrorCount++ }
        if ($Level -eq 'WARNING') { $script:WarningCount++ }
    }

    function Set-NinjaField {
        <#
        .SYNOPSIS
            Sets NinjaRMM custom field with CLI fallback.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [AllowEmptyString()]
            [string]$Value
        )
        
        try {
            if (Get-Command 'Ninja-Property-Set-Piped' -ErrorAction SilentlyContinue) {
                $Value | Ninja-Property-Set-Piped -Name $Name
            }
            else {
                Write-Log "CLI fallback - Would set field '$Name' to: $Value" -Level 'INFO'
            }
        }
        catch {
            Write-Log "Failed to set custom field '$Name': $_" -Level 'ERROR'
            throw
        }
    }
}

process {
    try {
        if ($env:geoIPService -and $env:geoIPService -notlike 'null') {
            $GeoIPService = $env:geoIPService
        }
        
        if ($env:customFieldName -and $env:customFieldName -notlike 'null') {
            $CustomFieldName = $env:customFieldName
        }

        Write-Log 'Detecting public IP address...'
        
        $GeoData = Invoke-RestMethod -Uri $GeoIPService -TimeoutSec 10 -ErrorAction Stop
        
        if ($GeoData.ip) {
            Write-Log "Public IP: $($GeoData.ip)"
        }

        if ($GeoData.city -and $GeoData.region -and $GeoData.country_name) {
            $Location = "$($GeoData.city), $($GeoData.region), $($GeoData.country_name)"
            Write-Log "Location detected: $Location"
            
            Write-Log 'Updating device location in NinjaRMM...'
            $Location | Set-NinjaField -Name $CustomFieldName
            Write-Log 'Device location updated successfully'
        }
        else {
            Write-Log 'Incomplete geolocation data received' -Level 'WARNING'
            Write-Log "Received data: City=$($GeoData.city), Region=$($GeoData.region), Country=$($GeoData.country_name)" -Level 'WARNING'
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Log "Failed to update device location: $_" -Level 'ERROR'
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Output "`n========================================"
        Write-Output "Execution Summary"
        Write-Output "========================================"
        Write-Output "Script: Device-UpdateLocation.ps1"
        Write-Output "Duration: $Duration seconds"
        Write-Output "Errors: $script:ErrorCount"
        Write-Output "Warnings: $script:WarningCount"
        Write-Output "Exit Code: $script:ExitCode"
        Write-Output "========================================"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
