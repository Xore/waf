#Requires -Version 5.1

<#
.SYNOPSIS
    Checks Windows Firewall status for all network profiles.

.DESCRIPTION
    This script examines the status of Windows Defender Firewall across all three network 
    profiles (Domain, Private, Public). It reports whether the firewall is enabled or disabled 
    for each profile and can optionally alert if any profile has the firewall disabled.
    
    This is critical for security compliance and ensuring systems are protected from 
    unauthorized network access. Many compliance frameworks require firewall to be enabled 
    on all profiles.

.PARAMETER AlertOnDisabled
    If specified, the script will exit with an error code if any firewall profile is disabled.

.PARAMETER SaveToCustomField
    Name of a custom field to save the firewall status report.

.EXAMPLE
    No Parameters

    [Info] Checking Windows Firewall status...
    Domain Profile: Enabled
    Private Profile: Enabled
    Public Profile: Enabled
    [Info] Windows Firewall is enabled on all profiles

.EXAMPLE
    -AlertOnDisabled

    [Info] Checking Windows Firewall status...
    Domain Profile: Enabled
    Private Profile: Disabled
    Public Profile: Enabled
    [Alert] Windows Firewall is disabled on 1 profile(s)
    [Alert] Private profile has firewall disabled

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    
.COMPONENT
    NetSecurity - Windows Firewall PowerShell module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/netsecurity/get-netfirewallprofile

.FUNCTIONALITY
    - Checks Windows Firewall status for all network profiles
    - Reports enabled/disabled state for Domain, Private, and Public profiles
    - Optional alerting when firewall is disabled
    - Identifies which specific profiles have firewall disabled
    - Can save status report to custom fields
    - Security compliance monitoring
    - Useful for audit and vulnerability assessments
#>

[CmdletBinding()]
param(
    [switch]$AlertOnDisabled,
    [string]$SaveToCustomField
)

begin {
    if ($env:alertOnDisabled -eq "true") {
        $AlertOnDisabled = $true
    }
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
        Write-Host "[Info] Checking Windows Firewall status..."
        
        $FirewallProfiles = Get-NetFirewallProfile -ErrorAction Stop
        
        $Report = @()
        $DisabledProfiles = @()
        
        foreach ($Profile in $FirewallProfiles) {
            $ProfileName = $Profile.Name
            $Status = if ($Profile.Enabled) { "Enabled" } else { "Disabled" }
            
            Write-Host "${ProfileName} Profile: $Status"
            $Report += "${ProfileName}: $Status"
            
            if (-not $Profile.Enabled) {
                $DisabledProfiles += $ProfileName
            }
        }
        
        if ($DisabledProfiles.Count -gt 0) {
            Write-Host "[Alert] Windows Firewall is disabled on $($DisabledProfiles.Count) profile(s)"
            foreach ($Profile in $DisabledProfiles) {
                Write-Host "[Alert] $Profile profile has firewall disabled"
            }
            
            if ($AlertOnDisabled) {
                $ExitCode = 1
            }
        } else {
            Write-Host "[Info] Windows Firewall is enabled on all profiles"
        }

        if ($SaveToCustomField) {
            try {
                $Report -join " | " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            } catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to check firewall status: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
