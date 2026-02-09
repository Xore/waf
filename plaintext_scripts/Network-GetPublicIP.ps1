#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves the public IP address of the computer by querying external services.

.DESCRIPTION
    This script queries external IP detection services to determine the computer's public-facing 
    IP address. This is useful for systems behind NAT/firewall to identify their external IP, 
    which differs from internal LAN addresses.
    
    The script attempts multiple reliable IP detection services with fallback logic to ensure 
    successful retrieval even if one service is unavailable.

.PARAMETER SaveToCustomField
    Name of a custom field to save the detected public IP address.

.EXAMPLE
    -SaveToCustomField "PublicIP"

    [Info] Detecting public IP address...
    Public IP: 203.0.113.42
    [Info] IP address saved to custom field 'PublicIP'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Requires: Internet connectivity
    
.COMPONENT
    Invoke-RestMethod - HTTP client for API queries
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod

.FUNCTIONALITY
    - Queries external IP detection services (ifconfig.me, ipinfo.io, api.ipify.org)
    - Uses fallback logic with multiple services for reliability
    - Detects public-facing IP address behind NAT/firewall
    - Validates IP address format
    - Can save IP address to custom fields for tracking
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

    $IPServices = @(
        "https://ifconfig.me/ip",
        "https://api.ipify.org",
        "https://ipinfo.io/ip"
    )

    $ExitCode = 0
}

process {
    try {
        Write-Host "[Info] Detecting public IP address..."
        
        $PublicIP = $null
        foreach ($Service in $IPServices) {
            try {
                Write-Host "[Info] Trying service: $Service"
                $PublicIP = (Invoke-RestMethod -Uri $Service -TimeoutSec 10 -ErrorAction Stop).Trim()
                if ($PublicIP -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
                    Write-Host "Public IP: $PublicIP"
                    break
                }
            }
            catch {
                Write-Host "[Warn] Failed to query $Service: $_"
            }
        }

        if (-not $PublicIP) {
            Write-Host "[Error] Could not detect public IP address from any service"
            $ExitCode = 1
        }
        elseif ($SaveToCustomField) {
            try {
                $PublicIP | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] IP address saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to detect public IP: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
