#Requires -Version 5.1

<#
.SYNOPSIS
    Audits User Account Control (UAC) level and reports compliance status.

.DESCRIPTION
    Audits the User Account Control (UAC) configuration on Windows systems by checking
    registry settings that control UAC behavior. Determines the UAC level (0-3) and
    validates if the system meets security best practices.
    
    UAC Levels:
    - 0: Never notify (UAC disabled)
    - 1: Notify me only (do not dim desktop)
    - 2: Notify me only (default) - RECOMMENDED
    - 3: Always notify
    
    Exit Codes:
    - 0: UAC is set to default (level 2) or higher
    - 1: UAC is set lower than default (security risk)
    
    The script can optionally save the UAC level to a NinjaRMM custom field for monitoring.

.PARAMETER CustomField
    Name of a NinjaRMM custom field to save the UAC level results to.

.EXAMPLE
    .\Security-AuditUACLevel.ps1

    [2026-02-11 00:38:00] [INFO] UAC Level: 2 = Notify me only (default)
    [2026-02-11 00:38:00] [INFO] UAC Enabled with defaults

.EXAMPLE
    .\Security-AuditUACLevel.ps1 -CustomField "uacLevel"

    [2026-02-11 00:38:00] [INFO] UAC Level: 2 = Notify me only (default)
    [2026-02-11 00:38:00] [INFO] UAC Enabled with defaults
    [2026-02-11 00:38:00] [INFO] UAC level saved to custom field: uacLevel

.OUTPUTS
    None. UAC audit results are written to console and optionally to NinjaRMM custom field.

.NOTES
    File Name      : Security-AuditUACLevel.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 7, Windows Server 2012
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log and proper exit code handling
    - 1.1: Renamed script and added Script Variable support
    - 1.0: Initial release
    
    Security Note: UAC level 2 or higher is recommended for production systems.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$CustomField
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $script:ExitCode = 0
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Output $LogMessage; $script:ExitCode = 1 }
            'WARNING' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomField = $env:customFieldName
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $Value
        )
        try {
            $NinjaValue = $Value
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            throw "Failed to set NinjaRMM property: $_"
        }
    }

    $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    
    $RegistryValues = @(
        "FilterAdministratorToken",
        "EnableUIADesktopToggle",
        "ConsentPromptBehaviorAdmin",
        "ConsentPromptBehaviorUser",
        "EnableInstallerDetection",
        "ValidateAdminCodeSignatures",
        "EnableSecureUIAPaths",
        "EnableLUA",
        "PromptOnSecureDesktop",
        "EnableVirtualization"
    )
}

process {
    try {
        Write-Log "Starting UAC level audit"

        $UacSettings = @{}
        
        foreach ($ValueName in $RegistryValues) {
            $Result = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue | 
                Select-Object -ExpandProperty $ValueName -ErrorAction SilentlyContinue
            
            if ($null -eq $Result) {
                $Result = switch ($ValueName) {
                    'FilterAdministratorToken' { 0 }
                    'EnableUIADesktopToggle' { 0 }
                    'ConsentPromptBehaviorAdmin' { 5 }
                    'ConsentPromptBehaviorUser' { 3 }
                    'EnableInstallerDetection' { 0 }
                    'ValidateAdminCodeSignatures' { 0 }
                    'EnableSecureUIAPaths' { 1 }
                    'EnableLUA' { 1 }
                    'PromptOnSecureDesktop' { 1 }
                    'EnableVirtualization' { 1 }
                    Default { 1 }
                }
            }
            
            $UacSettings[$ValueName] = $Result
            Write-Log "$ValueName = $Result" -Level DEBUG
        }

        $IsHomeEdition = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption -like "*Home*"
        
        $IsDefaultConfig = (
            $UacSettings['ConsentPromptBehaviorAdmin'] -eq 5 -and
            $UacSettings['ConsentPromptBehaviorUser'] -eq 3 -and
            $UacSettings['EnableLUA'] -eq 1 -and
            $UacSettings['FilterAdministratorToken'] -eq 0 -and
            $UacSettings['EnableUIADesktopToggle'] -eq 0 -and
            (($IsHomeEdition -and $UacSettings['EnableInstallerDetection'] -eq 0) -or
             (-not $IsHomeEdition -and $UacSettings['EnableInstallerDetection'] -eq 1)) -and
            $UacSettings['ValidateAdminCodeSignatures'] -eq 0 -and
            $UacSettings['EnableSecureUIAPaths'] -eq 1 -and
            $UacSettings['PromptOnSecureDesktop'] -eq 1 -and
            $UacSettings['EnableVirtualization'] -eq 1
        )

        $IsDisabled = (
            $UacSettings['EnableLUA'] -eq 0 -or
            $UacSettings['ConsentPromptBehaviorAdmin'] -eq 0 -or
            $UacSettings['PromptOnSecureDesktop'] -eq 0
        )

        $UACLevel = if ($UacSettings['EnableLUA'] -eq 0) {
            0
        }
        elseif ($UacSettings['ConsentPromptBehaviorAdmin'] -eq 5 -and
                $UacSettings['PromptOnSecureDesktop'] -eq 0 -and
                $UacSettings['EnableLUA'] -eq 1) {
            1
        }
        elseif ($UacSettings['ConsentPromptBehaviorAdmin'] -eq 5 -and
                $UacSettings['PromptOnSecureDesktop'] -eq 1 -and
                $UacSettings['EnableLUA'] -eq 1) {
            2
        }
        elseif ($UacSettings['ConsentPromptBehaviorAdmin'] -eq 2 -and
                $UacSettings['PromptOnSecureDesktop'] -eq 1 -and
                $UacSettings['EnableLUA'] -eq 1) {
            3
        }
        else {
            0
        }

        $UACLevelText = switch ($UACLevel) {
            0 { "Never notify" }
            1 { "Notify me only (do not dim desktop)" }
            2 { "Notify me only (default)" }
            3 { "Always notify" }
            Default { "Unknown" }
        }

        Write-Log "UAC Level: $UACLevel = $UACLevelText"

        if ($IsDefaultConfig) {
            Write-Log "UAC Enabled with defaults"
        }
        elseif ($IsDisabled) {
            Write-Log "UAC Disabled" -Level WARNING
        }
        else {
            Write-Log "UAC Enabled with custom configuration" -Level WARNING
        }

        if ($CustomField) {
            try {
                Set-NinjaProperty -Name $CustomField -Value "$UACLevel = $UACLevelText" -ErrorAction Stop
                Write-Log "UAC level saved to custom field: $CustomField"
            }
            catch {
                Write-Log "Failed to update custom field ($CustomField): $_" -Level ERROR
            }
        }

        if ($UACLevel -lt 2) {
            Write-Log "UAC level is below recommended settings (Level 2 or higher required)" -Level WARNING
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Log "An unexpected error occurred: $_" -Level ERROR
        $script:ExitCode = 1
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
        exit $script:ExitCode
    }
}
