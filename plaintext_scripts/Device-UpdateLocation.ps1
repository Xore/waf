#Requires -Version 5.1

<#
.SYNOPSIS
    Updates the NinjaRMM device location based on public IP geolocation.

.DESCRIPTION
    This script retrieves the device's public IP address and uses geolocation services to determine 
    the physical location. It then updates the NinjaRMM device location field with the detected 
    city, region, and country information.
    
    Automatic location updates are useful for mobile devices and remote workers to ensure accurate 
    inventory and reporting data in the RMM system.

.PARAMETER GeoIPService
    Geolocation API service URL. Default: https://ipapi.co/json/

.PARAMETER CustomFieldName
    Name of the custom field to store location data. Default: DeviceLocation

.EXAMPLE
    No Parameters (uses defaults)

    [Info] Detecting public IP address...
    [Info] Public IP: 203.0.113.42
    [Info] Querying geolocation data...
    [Info] Location detected: Seattle, Washington, US
    [Info] Updating device location in NinjaRMM...
    [Info] Device location updated successfully

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Requires: Internet connectivity
    
.COMPONENT
    Invoke-RestMethod - HTTP client for API queries
    
.LINK
    https://ipapi.co/api/

.FUNCTIONALITY
    - Detects device public IP address
    - Queries geolocation API for location data
    - Parses city, region, country from API response
    - Updates NinjaRMM custom field with location
    - Provides location update confirmation
#>

[CmdletBinding()]
param(
    [string]$GeoIPService = "https://ipapi.co/json/",
    [string]$CustomFieldName = "DeviceLocation"
)

begin {
    if ($env:geoIPService -and $env:geoIPService -notlike "null") {
        $GeoIPService = $env:geoIPService
    }
    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomFieldName = $env:customFieldName
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
        Write-Host "[Info] Detecting public IP address..."
        $GeoData = Invoke-RestMethod -Uri $GeoIPService -TimeoutSec 10 -ErrorAction Stop
        
        if ($GeoData.ip) {
            Write-Host "[Info] Public IP: $($GeoData.ip)"
        }

        if ($GeoData.city -and $GeoData.region -and $GeoData.country_name) {
            $Location = "$($GeoData.city), $($GeoData.region), $($GeoData.country_name)"
            Write-Host "[Info] Location detected: $Location"
            
            Write-Host "[Info] Updating device location in NinjaRMM..."
            $Location | Set-NinjaProperty -Name $CustomFieldName
            Write-Host "[Info] Device location updated successfully"
        }
        else {
            Write-Host "[Warn] Incomplete geolocation data received"
            $ExitCode = 1
        }
    }
    catch {
        Write-Host "[Error] Failed to update device location: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
