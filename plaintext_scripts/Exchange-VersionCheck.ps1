#Requires -Version 5.1

<#
.SYNOPSIS
    Detects installed Exchange Server version and build number.

.DESCRIPTION
    This script queries the system to identify if Microsoft Exchange Server is installed and 
    reports the version, build number, and cumulative update level. This information is critical 
    for patch management and security compliance.
    
    Knowing the exact Exchange version helps administrators ensure systems are up-to-date with 
    security patches and identify systems requiring updates.

.PARAMETER SaveToCustomField
    Name of a custom field to save the Exchange version information.

.EXAMPLE
    -SaveToCustomField "ExchangeVersion"

    [Info] Detecting Exchange Server installation...
    Exchange Server Detected: Exchange Server 2019
    Version: 15.2.1118.7
    Build: CU11
    [Info] Version saved to custom field 'ExchangeVersion'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2
    Release notes: Initial release for WAF v3.0
    
.COMPONENT
    Registry - Exchange installation information
    
.LINK
    https://learn.microsoft.com/en-us/exchange/new-features/build-numbers-and-release-dates

.FUNCTIONALITY
    - Detects Exchange Server installation via registry
    - Identifies Exchange version (2013, 2016, 2019)
    - Reports build number and cumulative update level
    - Can save version information to custom fields
    - Reports if Exchange is not installed
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
        Write-Host "[Info] Detecting Exchange Server installation..."
        
        $ExchangeKey = "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup"
        
        if (Test-Path -Path $ExchangeKey) {
            $ExchangeInfo = Get-ItemProperty -Path $ExchangeKey -ErrorAction Stop
            
            $Version = $ExchangeInfo.MsiProductMajor
            $Build = $ExchangeInfo.MsiBuildMajor
            $Revision = $ExchangeInfo.MsiBuildMinor
            $FullVersion = "$Version.$Build.$Revision"
            
            $ProductName = switch ($Version) {
                15 {
                    if ($Build -ge 2000) { "Exchange Server 2019" }
                    elseif ($Build -ge 1000) { "Exchange Server 2016" }
                    else { "Exchange Server 2013" }
                }
                default { "Exchange Server (Unknown Version)" }
            }

            Write-Host "Exchange Server Detected: $ProductName"
            Write-Host "Version: $FullVersion"
            
            $Output = "$ProductName - Version: $FullVersion"

            if ($SaveToCustomField) {
                try {
                    $Output | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Host "[Info] Version saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Host "[Error] Failed to save to custom field: $_"
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Host "[Info] Exchange Server not installed on this system"
        }
    }
    catch {
        Write-Host "[Error] Failed to detect Exchange version: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
