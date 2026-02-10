#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Disables Windows 11 upgrade by locking the TargetReleaseVersion and TargetReleaseVersionInfo to the currently installed version.
.DESCRIPTION
    Disables Windows 11 upgrade by locking the TargetReleaseVersion and TargetReleaseVersionInfo to the currently installed version.
.EXAMPLE
    -TargetReleaseVersion "22H2"
    Disables Windows 11 upgrade by setting the TargetReleaseVersion to 22H2
.EXAMPLE
    -TargetReleaseVersion "22H1"
    Disables Windows 11 upgrade by setting the TargetReleaseVersion to 22H1
.EXAMPLE
    -TargetReleaseVersion "2009"
    Disables Windows 11 upgrade by setting the TargetReleaseVersion to 2009
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param (
    [string]
    $TargetReleaseVersion = "22H2"
)

begin {
    $StartTime = Get-Date

    function Write-Log {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Warning', 'Error')]
            [string]$Level = 'Info'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $Output = "[$Timestamp] [$Level] $Message"
        Write-Host $Output
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Set-ItemProp {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        if (-not $(Test-Path -Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name)) {
            $CurrentValue = Get-ItemProperty -Path $Path -Name $Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Failed to set property: $_" -Level Error
            }
            Write-Log "$Path\$Name changed from $CurrentValue to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        else {
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Failed to create property: $_" -Level Error
            }
            Write-Log "Set $Path$Name to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    }
}

process {
    if ([System.Environment]::OSVersion.Version.Build -lt 10240 -or [System.Environment]::OSVersion.Version.Build -gt 22000) {
        Write-Log "OS Version is not Windows 10." -Level Error
        exit 1
    }

    if (-not (Test-IsElevated)) {
        Write-Log "Access Denied. Please run with Administrator privileges." -Level Error
        exit 1
    }

    if ($env:targetRelease -and $env:targetRelease -notlike "null") {
        if ($env:targetRelease -like "Current") {
            $release = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
            $ver = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion).DisplayVersion
            $TargetReleaseVersion = if ($release -eq '2009') { $ver } Else { $release }
        }
        else {
            $TargetReleaseVersion = $env:targetRelease
        }
    }

    try {
        Write-Log "Blocking Windows 11 upgrade with target version: $TargetReleaseVersion"
        Set-ItemProp -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "TargetReleaseVersion" -Value 1 -PropertyType DWord
        Set-ItemProp -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "TargetReleaseVersionInfo" -Value "$TargetReleaseVersion" -PropertyType String
        Set-ItemProp -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "SvOfferDeclined" -Value 1646085160366 -PropertyType QWord
        Write-Log "Successfully blocked Windows 11 upgrade"
    }
    catch {
        Write-Log "Failed to block Windows 11 Upgrade: $_" -Level Error
        exit 1
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
