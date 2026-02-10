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
    
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        Write-Output $LogMessage
        
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

    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }
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
                Write-Log "$($Profile.Name) profile is DISABLED - security risk detected" -Level 'WARNING'
                $AllEnabled = $false
                $script:ExitCode = 1
            }
        }

        if ($AllEnabled) {
            Write-Log "All firewall profiles are enabled"
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaField -Name $SaveToCustomField
                Write-Log "Results saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Log "Failed to save to custom field: $_" -Level 'ERROR'
                $script:ExitCode = 1
            }
        }
    }
    catch {
        Write-Log "Failed to audit firewall status: $_" -Level 'ERROR'
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
        Write-Output "Script: Firewall-AuditStatus.ps1"
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
