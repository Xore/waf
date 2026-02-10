#Requires -Version 5.1

<#
.SYNOPSIS
    Reports the active power plan and power settings.

.DESCRIPTION
    This script retrieves and reports the currently active Windows power plan along with its
    detailed power settings for both AC (plugged in) and DC (battery) modes. The report includes
    settings like sleep timers, display brightness, processor states, and more.
    
    The script provides comprehensive power configuration information useful for:
    - System auditing and compliance
    - Troubleshooting power-related issues
    - Documenting system configurations
    - Monitoring power policy enforcement

.PARAMETER PowerPlanCustomFieldName
    Name of the custom field to save the active power plan name.
    Default: activePowerPlan

.PARAMETER PowerSettingsCustomFieldName
    Name of the custom field to save the detailed power settings.
    Default: activePowerSettings

.EXAMPLE
    .\Power-ActivePlanReport.ps1
    
    Active Power Plan: Balanced 
    
    Current Power Settings For Balanced
    
    Name                          When Plugged In                 When On Battery                  Units  
    ----                          ---------------                 ---------------                  -----  
    Allow hybrid sleep            Off                             Off                              N/A    
    Display brightness            100                             40                               %      
    Hibernate after               10800                           10800                            Seconds
    Sleep after                   1800                            900                              Seconds
    Turn off display after        600                             300                              Seconds

.EXAMPLE
    .\Power-ActivePlanReport.ps1 -PowerPlanCustomFieldName "currentPowerPlan" -PowerSettingsCustomFieldName "powerConfig"
    
    Reports power plan and saves results to specified custom fields.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Upgraded to V3 standards with modern PowerShell conventions
    Requires: Administrator privileges to retrieve all power settings
    
.COMPONENT
    powercfg.exe - Windows power configuration utility
    
.LINK
    https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options

.FUNCTIONALITY
    - Retrieves active Windows power plan
    - Enumerates all power settings and their values
    - Reports AC and DC power configuration differences
    - Converts hex values to human-readable format
    - Maps numeric settings to friendly names
    - Saves results to NinjaRMM custom fields
    - Provides formatted console output
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$PowerPlanCustomFieldName = 'activePowerPlan',
    
    [Parameter()]
    [string]$PowerSettingsCustomFieldName = 'activePowerSettings'
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    
    Set-StrictMode -Version Latest
    
    $script:ExitCode = 0

    if ($env:powerPlanCustomFieldName -and $env:powerPlanCustomFieldName -notlike 'null') {
        $PowerPlanCustomFieldName = $env:powerPlanCustomFieldName
    }
    if ($env:powerSettingsCustomFieldName -and $env:powerSettingsCustomFieldName -notlike 'null') {
        $PowerSettingsCustomFieldName = $env:powerSettingsCustomFieldName
    }

    function Test-IsElevated {
        $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
        $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Get-PowerPlan {
        [CmdletBinding()]
        param(
            [Parameter()]
            [switch]$Active,
            
            [Parameter()]
            [string]$Name
        )
        
        if ($Active) {
            $Output = powercfg.exe /getactivescheme
            $Output = ($Output -replace 'Power Scheme GUID:' -split '(?=\S{8}-\S{4}-\S{4}-\S{4}-\S{12})' -split '\(' -replace '\)') | Where-Object { $_ -ne ' ' }
            $PowerPlan = @(
                [PSCustomObject]@{
                    Name = $($Output | Where-Object { $_ -notmatch '\S{8}-\S{4}-\S{4}-\S{4}-\S{12}' }).Trim()
                    GUID = $($Output | Where-Object { $_ -match '\S{8}-\S{4}-\S{4}-\S{4}-\S{12}' }).Trim()
                }
            )
        }
        else {
            $Output = powercfg.exe /L
            $PowerPlan = $Output -replace '\s{2,}', ',' -replace ' \*', ',True' -replace 'Existing Power Schemes \(\* Active\)', 'GUID,Name,Active' -replace '-{2,}' -replace 'Power Scheme GUID: ' -replace '\(' -replace '\)' | Where-Object { $_ } | ConvertFrom-Csv
        }

        if ($Name) {
            $PowerPlan | Where-Object { $_.Name -like $Name }
        }
        else {
            $PowerPlan
        }
    }

    function Get-PowerSettings {
        [CmdletBinding()]
        param()
        
        $PowerSubgroups = powercfg.exe /Q | Select-String 'Subgroup GUID:'
        $PowerSubgroups = ($PowerSubgroups -replace 'Subgroup GUID:' -replace '\(' -replace '\)').Trim() | ForEach-Object {
            @(
                [PSCustomObject]@{
                    SubName = $($_ -split '\s{2,}' | Where-Object { $_ -notmatch '(\S{8}-\S{4}-\S{4}-\S{4}-\S{12})' })
                    SubGUID = $($_ -split '\s{2,}' | Where-Object { $_ -match '(\S{8}-\S{4}-\S{4}-\S{4}-\S{12})' })
                }
            )
        }

        $PowerSettings = foreach ($Subgroup in $PowerSubgroups) {
            $Settings = powercfg.exe /Q SCHEME_CURRENT $Subgroup.SubGUID | Select-String 'Power Setting GUID:'
            ($Settings -replace 'Power Setting GUID:' -replace '\(' -replace '\)').Trim() | ForEach-Object {
                @(
                    [PSCustomObject]@{
                        Name    = $($_ -split '\s{2,}' | Where-Object { $_ -notmatch '(\S{8}-\S{4}-\S{4}-\S{4}-\S{12})' })
                        GUID    = $($_ -split '\s{2,}' | Where-Object { $_ -match '(\S{8}-\S{4}-\S{4}-\S{4}-\S{12})' })
                        SubName = $Subgroup.SubName
                        SubGUID = $Subgroup.SubGUID
                    }
                )
            }
        }

        foreach ($PowerSetting in $PowerSettings) {
            $ACValue = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String 'Current AC Power Setting Index:'
            $ACValue = ($ACValue -replace 'Current AC Power Setting Index:' -replace '\(' -replace '\)').Trim()

            $DCValue = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String 'Current DC Power Setting Index:'
            $DCValue = ($DCValue -replace 'Current DC Power Setting Index:' -replace '\(' -replace '\)').Trim()

            $ACValue = [int32]$ACValue
            $DCValue = [int32]$DCValue
            
            $FriendlyName = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String 'Possible Setting Friendly Name:'
            if ($FriendlyName) {
                $Indexes = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String 'Possible Setting Index:'
                $Indexes = $Indexes | ForEach-Object { ($_ -replace 'Possible Setting Index:').Trim() }

                $FriendlyNames = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String 'Possible Setting Friendly Name:'
                $FriendlyNames = $FriendlyNames | ForEach-Object { ($_ -replace 'Possible Setting Friendly Name:').Trim() }

                $FriendlyOptions = for ($i = 0; $i -lt $FriendlyNames.Count; $i++) {
                    [PSCustomObject]@{
                        Name  = $FriendlyNames[$i]
                        Index = $Indexes[$i]
                    }
                }

                $ACValue = $FriendlyOptions | Where-Object { [int32]$_.Index -eq $ACValue } | Select-Object -ExpandProperty Name
                $DCValue = $FriendlyOptions | Where-Object { [int32]$_.Index -eq $DCValue } | Select-Object -ExpandProperty Name

                $Units = 'N/A'
            }
            else {
                $Units = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String 'Possible Settings units:'
                $Units = ($Units -replace 'Possible Settings units:' -replace '\(' -replace '\)').Trim()
            }

            [PSCustomObject]@{
                Name              = $PowerSetting.Name
                GUID              = $PowerSetting.GUID
                'When Plugged In' = $ACValue
                'When On Battery' = $DCValue
                Units             = $Units
                SubName           = $PowerSetting.SubName
                SubGUID           = $PowerSetting.SubGUID
            }
        }
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $Value
        )
        
        $Characters = ($Value | Out-String | Measure-Object -Character).Characters
        if ($Characters -ge 10000) {
            throw "Character limit exceeded: value contains $Characters characters (maximum: 10000)"
        }
        
        try {
            $null = Ninja-Property-Set-Piped -Name $Name -Value $Value 2>&1
        }
        catch {
            throw "Failed to set custom field '$Name': $_"
        }
    }
}

process {
    try {
        if (-not (Test-IsElevated)) {
            Write-Host '[Error] Access Denied. Please run with Administrator privileges.'
            $script:ExitCode = 1
            return
        }

        Write-Host '[Info] Retrieving active power plan...'
        $ActivePowerPlan = Get-PowerPlan -Active | Select-Object -ExpandProperty Name

        if (-not $ActivePowerPlan) {
            Write-Host '[Error] Unable to retrieve active power plan'
            $script:ExitCode = 1
            return
        }

        Write-Host "[Info] Active Power Plan: $ActivePowerPlan"

        Write-Host '[Info] Retrieving power settings...'
        $CurrentPowerSettings = Get-PowerSettings | Sort-Object Name | Format-Table -Property Name, 'When Plugged In', 'When On Battery', Units -AutoSize | Out-String
        
        if (-not $CurrentPowerSettings) {
            Write-Host '[Error] Unable to retrieve power settings'
            $script:ExitCode = 1
            return
        }

        $Report = New-Object System.Collections.Generic.List[string]
        $Report.Add("Active Power Plan: $ActivePowerPlan")
        $Report.Add("`n`n### Current Power Settings For $ActivePowerPlan ###")
        $Report.Add("`n$CurrentPowerSettings")

        Write-Host ($Report -join '')

        if ($PowerPlanCustomFieldName) {
            try {
                $ActivePowerPlan | Set-NinjaProperty -Name $PowerPlanCustomFieldName
                Write-Host "[Info] Saved power plan to custom field '$PowerPlanCustomFieldName'"
            }
            catch {
                Write-Host "[Error] Failed to save power plan: $_"
                $script:ExitCode = 1
            }
        }

        if ($PowerSettingsCustomFieldName) {
            try {
                $CurrentPowerSettings | Set-NinjaProperty -Name $PowerSettingsCustomFieldName
                Write-Host "[Info] Saved power settings to custom field '$PowerSettingsCustomFieldName'"
            }
            catch {
                Write-Host "[Error] Failed to save power settings: $_"
                $script:ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Unexpected error: $_"
        $script:ExitCode = 1
    }
}

end {
    exit $script:ExitCode
}
