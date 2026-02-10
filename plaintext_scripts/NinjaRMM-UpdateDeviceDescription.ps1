#Requires -Version 4

<#
.SYNOPSIS
    Updates the current device description.
.DESCRIPTION
    Updates the current device description.
.EXAMPLE
    -Description "Kitchen Computer"
    
    Attempting to set device description to 'Kitchen Computer'.


    SystemDirectory : C:\Windows\system32
    Organization    : vm.net
    BuildNumber     : 9600
    RegisteredUser  : NA
    SerialNumber    : 00252-70000-00000-AA382
    Version         : 6.3.9600

    Successfully set device description to 'Kitchen Computer'.


PARAMETER: -Description "ReplaceMeWithADeviceDescription"
    Specify the device description you would like to set.

PARAMETER: -ClearDescription
    Clear the current device description.

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2012 R2
    Version: 3.0.0
    Release Notes:
    (v3.0.0) 2026-02-10 - Upgraded to V3.0.0 standards (script-scoped exit code)
    (v1.0) Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Description,
    [Parameter()]
    [Switch]$ClearDescription = [System.Convert]::ToBoolean($env:clearDeviceDescription)
)

begin {
    if($env:deviceDescription -and $env:deviceDescription -notlike "null"){ $Description = $env:deviceDescription }

    if ($Description) {
        $Description = $Description.Trim()
    }

    if (!$Description -and !$ClearDescription) {
        Write-Host -Object "[Error] You must provide a description to set."
        exit 1
    }

    if ($ClearDescription -and $Description) {
        Write-Host -Object "[Error] You cannot clear and set the device description at the same time."
        exit 1
    }

    if ($ClearDescription) {
        $Description = $Null
    }

    $DescriptionLength = $Description | Measure-Object -Character | Select-Object -ExpandProperty Characters
    if ($DescriptionLength -ge 40) {
        Write-Host -Object "[Warning] The description '$Description' is greater than 40 characters. It may appear trimmed in certain situations."
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    $script:ExitCode = 0
}

process {
    if (!(Test-IsElevated)) {
        Write-Host -Object "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    try {
        Write-Host -Object "Attempting to set device description to '$Description'."
        if ($PSVersionTable.PSVersion.Major -lt 5) {
            Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop | Set-WmiInstance -Property @{ 'Description' = $Description } -ErrorAction Stop
        }
        else {
            Get-CimInstance -Class Win32_OperatingSystem -ErrorAction Stop | Set-CimInstance -Property @{ 'Description' = $Description } -ErrorAction Stop
        }
        Write-Host -Object "Successfully set device description to '$Description'."
    }
    catch {
        Write-Host -Object "[Error] Failed to set the device description."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    exit $script:ExitCode
}

end {
    
}
