#Requires -Version 5.1 -RunAsAdministrator

<#
.SYNOPSIS
    Checks if LSASS (Local Security Authority Subsystem Service) process protection is enabled.

.DESCRIPTION
    This script verifies whether LSASS running protection is enabled on the system. LSASS protection
    helps prevent credential theft attacks by preventing unauthorized processes from reading LSASS
    memory, which contains sensitive authentication credentials.
    
    LSASS protection is configured via the RunAsPPL (Protected Process Light) registry setting.
    Enabling this protection is a security best practice that helps defend against credential
    dumping tools like Mimikatz.

.PARAMETER EnableIfDisabled
    If specified, automatically enables LSASS protection if it is currently disabled. Requires restart.

.PARAMETER SaveToCustomField
    Name of a custom field to save the LSASS protection status.

.EXAMPLE
    No Parameters

    [Info] Checking LSASS protection status...
    [Info] LSASS protection is enabled

.EXAMPLE
    -EnableIfDisabled

    [Info] Checking LSASS protection status...
    [Alert] LSASS protection is disabled
    [Info] Enabling LSASS protection...
    [Info] LSASS protection enabled - restart required for changes to take effect

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Requires: Administrator privileges
    
.COMPONENT
    Registry - HKLM:\SYSTEM\CurrentControlSet\Control\Lsa
    
.LINK
    https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection

.FUNCTIONALITY
    - Checks LSASS RunAsPPL registry setting
    - Reports current protection status
    - Optionally enables protection if disabled
    - Can save status to custom fields
    - Alerts when protection is disabled (security risk)
    - Notifies when restart is required
#>

[CmdletBinding()]
param(
    [switch]$EnableIfDisabled = $false,
    [string]$SaveToCustomField
)

begin {
    if ($env:enableIfDisabled -eq "true") {
        $EnableIfDisabled = $true
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
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
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges"
        exit 1
    }

    try {
        Write-Host "[Info] Checking LSASS protection status..."
        
        $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $RunAsPPL = Get-ItemProperty -Path $RegPath -Name "RunAsPPL" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty RunAsPPL

        $IsProtected = $RunAsPPL -eq 1
        $Status = if ($IsProtected) { "Enabled" } else { "Disabled" }

        if ($IsProtected) {
            Write-Host "[Info] LSASS protection is enabled"
        }
        else {
            Write-Host "[Alert] LSASS protection is disabled - security risk detected"
            $ExitCode = 1

            if ($EnableIfDisabled) {
                Write-Host "[Info] Enabling LSASS protection..."
                try {
                    Set-ItemProperty -Path $RegPath -Name "RunAsPPL" -Value 1 -Type DWord -Force -Confirm:$false
                    Write-Host "[Info] LSASS protection enabled - restart required for changes to take effect"
                    $Status = "Enabled (Restart Required)"
                    $ExitCode = 0
                }
                catch {
                    Write-Host "[Error] Failed to enable LSASS protection: $_"
                    $ExitCode = 1
                }
            }
        }

        if ($SaveToCustomField) {
            try {
                $Status | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Status saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to check LSASS protection: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
