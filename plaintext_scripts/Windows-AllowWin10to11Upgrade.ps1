#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Enables Windows 11 upgrade.
.DESCRIPTION
    Enables Windows 11 upgrade.
.EXAMPLE
    No parameters needed
    Enables Windows 11 upgrade.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param ()

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
}

process {
    if (-not (Test-IsElevated)) {
        Write-Log "Access Denied. Please run with Administrator privileges." -Level Error
        exit 1
    }

    Write-Log "Enabling Windows 11 upgrade..."

    $Splat = @{
        Path        = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        Name        = @("TargetReleaseVersion", "TargetReleaseVersionInfo")
        ErrorAction = "SilentlyContinue"
    }

    Remove-ItemProperty @Splat -Force
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "SvOfferDeclined" -Force -ErrorAction SilentlyContinue
    
    $TargetResult = Get-ItemProperty @Splat
    $OfferResult = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "SvOfferDeclined" -ErrorAction SilentlyContinue
    
    if ($null -ne $TargetResult -or $null -ne $OfferResult) {
        Write-Log "Failed to enable Windows 11 Upgrade" -Level Error
        exit 1
    }
    
    Write-Log "Successfully enabled Windows 11 upgrade"
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
