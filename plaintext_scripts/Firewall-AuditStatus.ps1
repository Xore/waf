#Requires -Version 5.1

<#
.SYNOPSIS
    Audits Windows Firewall status for all network profiles.

.DESCRIPTION
    This script examines the Windows Firewall configuration for Domain, Private, and Public 
    network profiles. It reports the enabled/disabled status of each profile and identifies 
    any profiles that are disabled, which represents a security risk.
    
    Windows Firewall provides essential network security by filtering incoming and outgoing 
    traffic. Disabled firewall profiles leave the system vulnerable to network attacks.

.PARAMETER SaveToCustomField
    Name of a custom field to save the firewall audit results.

.EXAMPLE
    No Parameters

    [Info] Auditing Windows Firewall status...
    Domain Profile: Enabled
    Private Profile: Enabled
    Public Profile: Enabled
    [Info] All firewall profiles are enabled

.EXAMPLE
    -SaveToCustomField "FirewallStatus"

    [Info] Auditing Windows Firewall status...
    Domain Profile: Enabled
    Private Profile: Disabled
    Public Profile: Enabled
    [Alert] Private profile is DISABLED - security risk detected
    [Info] Results saved to custom field 'FirewallStatus'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    
.COMPONENT
    NetSecurity - Windows Firewall management module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/netsecurity/get-netfirewallprofile

.FUNCTIONALITY
    - Queries all Windows Firewall network profiles (Domain, Private, Public)
    - Reports enabled/disabled status for each profile
    - Identifies disabled profiles as security risks
    - Can save audit results to custom fields
    - Exits with error code if any profile is disabled
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
        Write-Host "[Info] Auditing Windows Firewall status..."
        
        $Profiles = Get-NetFirewallProfile -ErrorAction Stop
        $Report = @()
        $AllEnabled = $true

        foreach ($Profile in $Profiles) {
            $Status = if ($Profile.Enabled) { "Enabled" } else { "Disabled" }
            $ProfileInfo = "$($Profile.Name) Profile: $Status"
            
            Write-Host $ProfileInfo
            $Report += $ProfileInfo

            if (-not $Profile.Enabled) {
                Write-Host "[Alert] $($Profile.Name) profile is DISABLED - security risk detected"
                $AllEnabled = $false
                $ExitCode = 1
            }
        }

        if ($AllEnabled) {
            Write-Host "[Info] All firewall profiles are enabled"
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to audit firewall status: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
