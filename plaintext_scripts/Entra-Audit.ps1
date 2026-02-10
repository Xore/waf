#Requires -Version 5.1

<#
.SYNOPSIS
    Audits Microsoft Entra ID (Azure AD) connection status and device join state.

.DESCRIPTION
    This script verifies the device's connection to Microsoft Entra ID (formerly Azure Active Directory) 
    using dsregcmd.exe. It checks whether the device is Azure AD joined, Workplace joined, or Hybrid 
    joined and reports the status. Results can optionally be saved to custom fields.

    The script parses output from dsregcmd /status which provides comprehensive Azure AD and workplace 
    join information including device state, tenant details, SSO status, and diagnostic data.

.PARAMETER SaveToMultilineField
    Name of a multiline custom field to save the full dsregcmd output.

.PARAMETER SaveToWysiwygField
    Name of a WYSIWYG custom field to save the formatted HTML output.

.EXAMPLE
    .\Entra-Audit.ps1
    
    Device is Entra ID Joined: True
    Device is Workplace Joined: False
    Device is Hybrid Joined: False

.EXAMPLE
    .\Entra-Audit.ps1 -SaveToMultilineField "EntraStatus" -SaveToWysiwygField "EntraStatusHTML"
    
    Device is Entra ID Joined: True
    Device is Workplace Joined: False
    Device is Hybrid Joined: False
    Successfully saved to multiline custom field 'EntraStatus'
    Successfully saved to WYSIWYG custom field 'EntraStatusHTML'

.OUTPUTS
    None. Status information is written to the console and optionally to custom fields.

.NOTES
    File Name      : Entra-Audit.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
.COMPONENT
    dsregcmd - Built-in Windows tool for Azure AD device registration diagnostics
    
.LINK
    https://learn.microsoft.com/en-us/azure/active-directory/devices/troubleshoot-device-dsregcmd

.FUNCTIONALITY
    - Executes dsregcmd.exe /status to retrieve Azure AD join information
    - Parses device state (AzureAdJoined, WorkplaceJoined, DomainJoined)
    - Detects Hybrid Azure AD join scenarios
    - Formats output for activity log and custom fields
    - Provides HTML formatted output for WYSIWYG fields with color-coded status indicators
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SaveToMultilineField,
    
    [Parameter()]
    [string]$SaveToWysiwygField
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
            [Parameter()]
            [String]$Type,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value,
            [Parameter()]
            [String]$DocumentName
        )

        $Characters = $Value | Measure-Object -Character | Select-Object -ExpandProperty Characters
        if ($Characters -ge 10000) {
            throw [System.ArgumentOutOfRangeException]::New("Character limit exceeded, value is greater than 10,000 characters.")
        }

        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }

        $ValidFields = "Attachment", "Checkbox", "Date", "Date or Date Time", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine", "MultiSelect", "Phone", "Secure", "Text", "Time", "URL", "WYSIWYG"
        if ($Type -and $ValidFields -notcontains $Type) { 
            Write-Log "$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" -Level WARNING
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

                if (-not $Selection) {
                    throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown")
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

    if ($env:saveToMultilineField -and $env:saveToMultilineField -notlike "null") {
        $SaveToMultilineField = $env:saveToMultilineField
    }
    if ($env:saveToWysiwygField -and $env:saveToWysiwygField -notlike "null") {
        $SaveToWysiwygField = $env:saveToWysiwygField
    }

    $ExitCode = 0
}

process {
    try {
        Write-Log "Starting Entra ID audit"
        
        $dsregcmd = dsregcmd /status
        
        if (!$dsregcmd) {
            throw "Failed to execute dsregcmd command"
        }
        
        $AzureAdJoined = ($dsregcmd | Select-String "AzureAdJoined\s+:\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()
        $WorkplaceJoined = ($dsregcmd | Select-String "WorkplaceJoined\s+:\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()
        $DomainJoined = ($dsregcmd | Select-String "DomainJoined\s+:\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()
        
        $IsHybridJoined = ($AzureAdJoined -eq "YES" -and $DomainJoined -eq "YES")
        
        Write-Log "Device is Entra ID Joined: $($AzureAdJoined -eq 'YES')"
        Write-Log "Device is Workplace Joined: $($WorkplaceJoined -eq 'YES')"
        Write-Log "Device is Hybrid Joined: $IsHybridJoined"
        
        if ($SaveToMultilineField) {
            try {
                $dsregcmd | Out-String | Set-NinjaProperty -Name $SaveToMultilineField -Type "MultiLine"
                Write-Log "Successfully saved to multiline custom field '$SaveToMultilineField'"
            }
            catch {
                Write-Log "Failed to save to multiline custom field: $_" -Level ERROR
                $ExitCode = 1
            }
        }
        
        if ($SaveToWysiwygField) {
            try {
                $htmlOutput = @"
<h3>Microsoft Entra ID Status</h3>
<table>
<tr><td><strong>Azure AD Joined</strong></td><td>$($AzureAdJoined -eq 'YES')</td></tr>
<tr><td><strong>Workplace Joined</strong></td><td>$($WorkplaceJoined -eq 'YES')</td></tr>
<tr><td><strong>Hybrid Joined</strong></td><td>$IsHybridJoined</td></tr>
<tr><td><strong>Domain Joined</strong></td><td>$($DomainJoined -eq 'YES')</td></tr>
</table>
<pre>$($dsregcmd | Out-String)</pre>
"@
                $htmlOutput | Set-NinjaProperty -Name $SaveToWysiwygField -Type "WYSIWYG"
                Write-Log "Successfully saved to WYSIWYG custom field '$SaveToWysiwygField'"
            }
            catch {
                Write-Log "Failed to save to WYSIWYG custom field: $_" -Level ERROR
                $ExitCode = 1
            }
        }
        
        Write-Log "Entra ID audit completed successfully"
    }
    catch {
        Write-Log "Failed to execute dsregcmd: $_" -Level ERROR
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
