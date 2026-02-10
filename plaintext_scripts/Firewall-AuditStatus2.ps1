#Requires -Version 5.1

<#
.SYNOPSIS
    Audits Windows Firewall profile status and configuration.

.DESCRIPTION
    This script audits Windows Firewall profiles (Domain, Private, Public) and reports their
    enabled/disabled status and default inbound action settings. It can optionally save results
    to a NinjaRMM custom field.
    
    The script performs the following:
    - Retrieves firewall profile status from PolicyStore
    - Checks if profiles are enabled/disabled
    - Verifies default inbound action (Block/Allow)
    - Alerts on disabled profiles or permissive rules
    - Formats results as readable table
    - Optionally saves status to custom field
    
    Requires elevated privileges when setting custom fields.

.PARAMETER Domain
    Check the Domain Firewall Profile.

.PARAMETER Private
    Check the Private Firewall Profile.

.PARAMETER Public
    Check the Public Firewall Profile.

.PARAMETER CustomField
    Optional name of a text custom field to store the results in.
    Format: "ProfileName: Status | ProfileName: Status"
    Example: "Domain: On | Private: On | Public: On"

.EXAMPLE
    .\Firewall-AuditStatus2.ps1 -Domain -Private -Public

    [2026-02-10 21:59:00] [INFO] Starting: Firewall-AuditStatus2 v3.0.0
    [2026-02-10 21:59:00] [INFO] Retrieving current firewall status.
    [2026-02-10 21:59:01] [INFO] Checking for disabled firewall profiles or permissive rules.
    ### Firewall Status ###
    Name    Enabled DefaultInboundAction
    ----    ------- --------------------
    Domain     True                Block
    Private    True                Block
    Public     True                Block

.EXAMPLE
    .\Firewall-AuditStatus2.ps1 -Domain -Private -Public -CustomField "firewallStatus"

    Audits all three profiles and saves status summary to custom field.

.OUTPUTS
    Formatted table output to console.
    Optional custom field update with status summary.

.NOTES
    File Name      : Firewall-AuditStatus2.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with error/warning counters and execution summary
    - 2.0: Added Write-Log function and execution tracking
    - 1.1: Code cleanup and reorganization
    - 1.0: Initial release
    
    Execution Context: Flexible (can run as user or SYSTEM)
    Execution Frequency: On-demand or scheduled
    Typical Duration: 1-3 seconds
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A
    
    Required Privileges:
        - Standard user: Read firewall status
        - Administrator: Set custom fields

.COMPONENT
    Get-NetFirewallProfile - Windows Firewall cmdlet
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Audits Windows Firewall profile configuration
    - Detects disabled firewall profiles
    - Alerts on permissive inbound rules (Allow all)
    - Generates formatted status reports
    - Updates NinjaRMM custom fields
    - Validates at least one profile is selected
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Check the Domain Firewall Profile")]
    [Switch]$Domain,
    
    [Parameter(Mandatory=$false, HelpMessage="Check the Private Firewall Profile")]
    [Switch]$Private,
    
    [Parameter(Mandatory=$false, HelpMessage="Check the Public Firewall Profile")]
    [Switch]$Public,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field name to store results")]
    [String]$CustomField
)

begin {
    Set-StrictMode -Version Latest
    
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Firewall-AuditStatus2"
    
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:DisabledProfileCount = 0
    $script:PermissiveProfileCount = 0

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS','ALERT')]
            [string]$Level = 'INFO'
        )
        
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { 
                Write-Error $LogMessage
                $script:ErrorCount++
            }
            'WARN' { 
                Write-Warning $LogMessage
                $script:WarningCount++
            }
            'ALERT' {
                Write-Warning "ALERT: $Message"
                $script:WarningCount++
            }
            default { 
                Write-Output $LogMessage 
            }
        }
    }

    if ($env:domainProfile -eq "true") { $Domain = $true }
    if ($env:privateProfile -eq "true") { $Private = $true }
    if ($env:publicProfile -eq "true") { $Public = $true }
    if ($env:firewallStatusCustomFieldName -and $env:firewallStatusCustomFieldName -notlike "null") { 
        $CustomField = $env:firewallStatusCustomFieldName 
    }

    if (!$Domain -and !$Private -and !$Public) {
        Write-Log "You must select at least one firewall profile to audit." -Level ERROR
        Write-Log "Use -Domain, -Private, and/or -Public parameters." -Level ERROR
        $script:ExitCode = 1
        exit $script:ExitCode
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($CustomField -and !(Test-IsElevated)) {
        Write-Log "Setting a custom field requires Administrator privileges." -Level ERROR
        Write-Log "Please run this script as Administrator or omit -CustomField parameter." -Level ERROR
        $script:ExitCode = 1
        exit $script:ExitCode
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        $ProfilesToAudit = New-Object -TypeName System.Collections.Generic.List[string]

        if ($Domain) { $ProfilesToAudit.Add("Domain") }
        if ($Private) { $ProfilesToAudit.Add("Private") }
        if ($Public) { $ProfilesToAudit.Add("Public") }

        Write-Log "Auditing firewall profiles: $($ProfilesToAudit -join ', ')" -Level INFO
        Write-Log "Retrieving current firewall status." -Level INFO
        
        $NetProfile = Get-NetFirewallProfile -All -PolicyStore ActiveStore -ErrorAction Stop | 
            Select-Object "Name", "Enabled", "DefaultInboundAction" | 
            Where-Object { $ProfilesToAudit -contains $_.Name }

        Write-Log "Checking for disabled firewall profiles or permissive rules." -Level INFO

        $NetProfile | ForEach-Object {
            if (!([System.Convert]::ToBoolean($_.Enabled))) {
                Write-Log "The '$($_.Name)' firewall profile is disabled!" -Level ALERT
                $script:DisabledProfileCount++
                $script:ExitCode = 1
            }

            if ($_.DefaultInboundAction -like "Allow") {
                Write-Log "The '$($_.Name)' firewall profile allows all inbound connections!" -Level ALERT
                $script:PermissiveProfileCount++
                $script:ExitCode = 1
            }
        }

        if ($script:DisabledProfileCount -eq 0 -and $script:PermissiveProfileCount -eq 0) {
            Write-Log "All audited profiles are properly configured" -Level SUCCESS
        }

        Write-Output "`n### Firewall Status ###"
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

            Write-Log "Attempting to set Custom Field '$CustomField'." -Level INFO
            Set-NinjaProperty -Name $CustomField -Value $CustomFieldValue
            Write-Log "Successfully set Custom Field '$CustomField'!" -Level SUCCESS
        }
        
        Write-Log "Firewall audit completed successfully" -Level SUCCESS
    }
    catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Summary:" -Level INFO
        Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "  Errors: $script:ErrorCount" -Level INFO
        Write-Log "  Warnings: $script:WarningCount" -Level INFO
        Write-Log "  Disabled Profiles: $script:DisabledProfileCount" -Level INFO
        Write-Log "  Permissive Profiles: $script:PermissiveProfileCount" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
