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
    .\Firewall-AuditStatus.ps1

    Auditing Windows Firewall status...
    Domain Profile: Enabled
    Private Profile: Enabled
    Public Profile: Enabled
    All firewall profiles are enabled

.EXAMPLE
    .\Firewall-AuditStatus.ps1 -SaveToCustomField "FirewallStatus"

    Auditing Windows Firewall status...
    Domain Profile: Enabled
    Private Profile: Disabled
    Public Profile: Enabled
    Private profile is DISABLED - security risk detected
    Results saved to custom field 'FirewallStatus'

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : Firewall-AuditStatus.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
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
    [Parameter()]
    [string]$SaveToCustomField
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
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
            'ALERT' { Write-Warning "ALERT: $Message" }
            default { Write-Output $LogMessage }
        }
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
        Write-Log "Auditing Windows Firewall status..."
        
        $Profiles = Get-NetFirewallProfile -ErrorAction Stop
        $Report = @()
        $AllEnabled = $true

        foreach ($Profile in $Profiles) {
            $Status = if ($Profile.Enabled) { "Enabled" } else { "Disabled" }
            $ProfileInfo = "$($Profile.Name) Profile: $Status"
            
            Write-Log $ProfileInfo
            $Report += $ProfileInfo

            if (-not $Profile.Enabled) {
                Write-Log "$($Profile.Name) profile is DISABLED - security risk detected" -Level ALERT
                $AllEnabled = $false
                $ExitCode = 1
            }
        }

        if ($AllEnabled) {
            Write-Log "All firewall profiles are enabled"
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Log "Results saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Log "Failed to save to custom field: $_" -Level ERROR
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Log "Failed to audit firewall status: $_" -Level ERROR
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
