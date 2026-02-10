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
    .\Exchange-VersionCheck.ps1
    
    Detecting Exchange Server installation...
    Exchange Server Detected: Exchange Server 2019
    Version: 15.2.1118.7

.EXAMPLE
    .\Exchange-VersionCheck.ps1 -SaveToCustomField "ExchangeVersion"
    
    Detecting Exchange Server installation...
    Exchange Server Detected: Exchange Server 2019
    Version: 15.2.1118.7
    Version saved to custom field 'ExchangeVersion'

.OUTPUTS
    None. Version information is written to the console and optionally to a custom field.

.NOTES
    File Name      : Exchange-VersionCheck.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
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
    [Parameter()]
    [string]$SaveToCustomField
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Output $logMessage }
        }
    }

    function Set-NinjaProperty {
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
            Write-Log "Failed to set custom field: $_" -Level ERROR
            throw
        }
    }

    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    $ExitCode = 0
}

process {
    try {
        Write-Log "Detecting Exchange Server installation..."
        
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

            Write-Log "Exchange Server Detected: $ProductName"
            Write-Log "Version: $FullVersion"
            
            $Output = "$ProductName - Version: $FullVersion"

            if ($SaveToCustomField) {
                try {
                    $Output | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Log "Version saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Log "Failed to save to custom field: $_" -Level ERROR
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Log "Exchange Server not installed on this system"
        }
    }
    catch {
        Write-Log "Failed to detect Exchange version: $_" -Level ERROR
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
