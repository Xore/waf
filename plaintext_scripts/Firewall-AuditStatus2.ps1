#Requires -Version 5.1

<#
.SYNOPSIS
    Get the current status of specified Windows firewall profiles.
.DESCRIPTION
    This script audits Windows Firewall profiles (Domain, Private, Public) and reports their
    enabled/disabled status and default inbound action settings. It can optionally save results
    to a NinjaRMM custom field.
.EXAMPLE
    .\Firewall-AuditStatus2.ps1 -Domain -Private -Public
    
    Retrieving current firewall status.
    Checking for disabled firewall profiles or those that allow all inbound connections.

    ### Firewall Status ###
    Name    Enabled DefaultInboundAction
    ----    ------- --------------------
    Domain     True                Block
    Private    True                Block
    Public     True                Block

PARAMETER: -Domain
    Check the Domain Firewall Profile.

PARAMETER: -Private
    Check the Private Firewall Profile.

PARAMETER: -Public
    Check the Public Firewall Profile.

PARAMETER: -CustomField "ReplaceMeWithNameOfTextCustomField"
    Optionally specify the name of a text custom field to store the results in.

.NOTES
    File Name      : Firewall-AuditStatus2.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.1: Code cleanup and reorganization
#>

[CmdletBinding()]
param (
    [Parameter()]
    [Switch]$Domain,
    
    [Parameter()]
    [Switch]$Private,
    
    [Parameter()]
    [Switch]$Public,
    
    [Parameter()]
    [String]$CustomField
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

    if ($env:domainProfile -eq "true") { $Domain = $true }
    if ($env:privateProfile -eq "true") { $Private = $true }
    if ($env:publicProfile -eq "true") { $Public = $true }
    if ($env:firewallStatusCustomFieldName -and $env:firewallStatusCustomFieldName -notlike "null") { 
        $CustomField = $env:firewallStatusCustomFieldName 
    }

    if (!$Domain -and !$Private -and !$Public) {
        Write-Log "You must select the firewall profile you would like to audit." -Level ERROR
        exit 1
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($CustomField -and !(Test-IsElevated)) {
        Write-Log "Setting a custom field requires the script to be run with Administrator privileges." -Level ERROR
        exit 1
    }
    
    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter()]
            [String]$Type,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value,
            [Parameter()]
            [String]$DocumentName
        )
        
        $Characters = $Value | ConvertTo-Json | Measure-Object -Character | Select-Object -ExpandProperty Characters
        if ($Characters -ge 200000) {
            throw [System.ArgumentOutOfRangeException]::New("Character limit exceeded: the value is greater than or equal to 200,000 characters.")
        }
        
        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }
        
        $ValidFields = "Attachment", "Checkbox", "Date", "Date or Date Time", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine", "MultiSelect", "Phone", "Secure", "Text", "Time", "URL", "WYSIWYG"
        if ($Type -and $ValidFields -notcontains $Type) { 
            Write-Warning "$Type is an invalid type. Please check here for valid types: https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" 
        }
        
        $NeedsOptions = "Dropdown"
        if ($DocumentName) {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
        }
        else {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }
        
        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }
            
        switch ($Type) {
            "Checkbox" {
                $NinjaValue = [System.Convert]::ToBoolean($Value)
            }
            "Date or Date Time" {
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
                $NinjaValue = $TimeSpan.TotalSeconds
            }
            "Dropdown" {
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID
                if (!($Selection)) {
                    throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown options.")
                }
                $NinjaValue = $Selection
            }
            default {
                $NinjaValue = $Value
            }
        }
            
        if ($DocumentName) {
            $CustomField = Ninja-Property-Docs-Set -AttributeName $Name -AttributeValue $NinjaValue @DocumentationParams 2>&1
        }
        else {
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        }
            
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $ExitCode = 0
}

process {
    try {
        $ProfilesToAudit = New-Object -TypeName System.Collections.Generic.List[string]

        if ($Domain) { $ProfilesToAudit.Add("Domain") }
        if ($Private) { $ProfilesToAudit.Add("Private") }
        if ($Public) { $ProfilesToAudit.Add("Public") }

        Write-Log "Retrieving current firewall status."
        $NetProfile = Get-NetFirewallProfile -All -PolicyStore ActiveStore -ErrorAction Stop | 
            Select-Object "Name", "Enabled", "DefaultInboundAction" | 
            Where-Object { $ProfilesToAudit -contains $_.Name }

        Write-Log "Checking for disabled firewall profiles or those that allow all inbound connections."

        $NetProfile | ForEach-Object {
            if (!([System.Convert]::ToBoolean($_.Enabled))) {
                Write-Log "The '$($_.Name)' firewall profile is disabled!" -Level ALERT
            }

            if ($_.DefaultInboundAction -like "Allow") {
                Write-Log "The '$($_.Name)' firewall profile is set to allow all inbound connections!" -Level ALERT
            }
        }

        Write-Output "### Firewall Status ###"
        $NetProfile | Format-Table -AutoSize | Out-String | Write-Output

        if ($CustomField) {
            $NetProfile | ForEach-Object {
                if (!$_.Enabled -or $_.DefaultInboundAction -like "Allow") { 
                    $Status = "Off" 
                }
                else { 
                    $Status = "On" 
                }

                if ($CustomFieldValue) {
                    $CustomFieldValue = "$CustomFieldValue | $($_.Name): $Status"
                }
                else {
                    $CustomFieldValue = "$($_.Name): $Status"
                }
            }

            Write-Log "Attempting to set Custom Field '$CustomField'."
            Set-NinjaProperty -Name $CustomField -Value $CustomFieldValue
            Write-Log "Successfully set Custom Field '$CustomField'!"
        }
    }
    catch {
        Write-Log "$($_.Exception.Message)" -Level ERROR
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
