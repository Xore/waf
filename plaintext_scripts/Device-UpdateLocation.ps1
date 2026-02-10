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
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Host $logMessage }
        }
    }

    function Set-NinjaProperty {
        <#
        .SYNOPSIS
            Sets NinjaRMM custom field value using piped input.
        #>
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        
        try {
            $CustomField = $Value | Ninja-Property-Set-Piped -Name $Name 2>&1
            
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            throw "Failed to set custom field '$Name': $_"
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
            $Location | Set-NinjaProperty -Name $CustomFieldName
            Write-Log 'Device location updated successfully'
            
            exit 0
        }
        else {
            Write-Log 'Incomplete geolocation data received' -Level WARNING
            Write-Log "Received data: City=$($GeoData.city), Region=$($GeoData.region), Country=$($GeoData.country_name)" -Level WARNING
            exit 1
        }
    }
    catch {
        Write-Log "Failed to update device location: $_" -Level ERROR
        exit 1
    }
}

end {
    [System.GC]::Collect()
}