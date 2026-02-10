#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables or disables Remote Desktop Protocol (RDP) on workstations.

.DESCRIPTION
    Configures Remote Desktop Protocol (RDP) access on Windows workstations by
    modifying registry settings and firewall rules. This script is restricted to
    workstation operating systems only - it will not run on servers or domain controllers.
    
    The script performs the following actions:
    - Sets the fDenyTSConnections registry value (0 = Enabled, 1 = Disabled)
    - Enables or disables the "Remote Desktop" firewall rule group
    - Validates that the system is a workstation before making changes
    
    Registry Path: HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server
    Firewall Group: "Remote Desktop"

.PARAMETER Enable
    Enables Remote Desktop on the workstation.

.PARAMETER Disable
    Disables Remote Desktop on the workstation.

.EXAMPLE
    .\RDP-SetRemoteDesktop.ps1 -Enable

    [2026-02-10 16:55:00] [INFO] Enabling Remote Desktop
    [2026-02-10 16:55:00] [SUCCESS] Remote Desktop enabled successfully

.EXAMPLE
    .\RDP-SetRemoteDesktop.ps1 -Disable

    [2026-02-10 16:55:00] [INFO] Disabling Remote Desktop
    [2026-02-10 16:55:00] [SUCCESS] Remote Desktop disabled successfully

.OUTPUTS
    None. Status information is written to console.

.NOTES
    File Name      : RDP-SetRemoteDesktop.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.1: Renamed script and added Script Variable support
    - 1.0: Initial release
    
    Restrictions:
    - Only works on workstation operating systems
    - Will not run on servers or domain controllers
    - Requires administrator privileges
#>

[CmdletBinding(DefaultParameterSetName = "Disable")]
param (
    [Parameter(ParameterSetName = "Enable")]
    [switch]$Enable,
    
    [Parameter(ParameterSetName = "Disable")]
    [switch]$Disable
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $ExitCode = 0
    
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
            'SUCCESS' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:action -and $env:action -notlike "null") {
        switch ($env:action) {
            "Enable" { $Enable = $true }
            "Disable" { $Disable = $true }
        }
    }

    if ($false -eq $Disable -and $false -eq $Enable) {
        Write-Log "Enable or Disable parameter is required" -Level ERROR
        exit 1
    }

    function Set-ItemProp {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        if (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name).$Name
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            Write-Log "$Path\$Name changed from $CurrentValue to $Value" -Level DEBUG
        }
        else {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            Write-Log "Set $Path\$Name to $Value" -Level DEBUG
        }
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    $Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
    $Name = "fDenyTSConnections"
    $RegEnable = 0
    $RegDisable = 1

    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $IsWorkstation = ($osInfo.ProductType -eq 1)
}

process {
    try {
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. Please run with Administrator privileges." -Level ERROR
            $ExitCode = 1
            return
        }

        if (-not $IsWorkstation) {
            Write-Log "System is a Domain Controller or Server. This script only works on workstations." -Level ERROR
            $ExitCode = 1
            return
        }

        if ($Disable) {
            Write-Log "Disabling Remote Desktop"
            
            $RegCheck = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -eq $RegCheck) {
                $RegCheck = 0
            }
            
            if ($RegDisable -ne $RegCheck) {
                Set-ItemProp -Path $Path -Name $Name -Value $RegDisable
            } else {
                Write-Log "Remote Desktop already disabled in registry" -Level DEBUG
            }
            
            try {
                Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction Stop
                Write-Log "Remote Desktop firewall rules disabled" -Level DEBUG
            }
            catch {
                Write-Log "Failed to disable Remote Desktop firewall rules: $_" -Level WARNING
            }
            
            Write-Log "Remote Desktop disabled successfully" -Level SUCCESS
        }
        elseif ($Enable) {
            Write-Log "Enabling Remote Desktop"
            
            $RegCheck = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -eq $RegCheck) {
                $RegCheck = 0
            }
            
            if ($RegEnable -ne $RegCheck) {
                Set-ItemProp -Path $Path -Name $Name -Value $RegEnable
            } else {
                Write-Log "Remote Desktop already enabled in registry" -Level DEBUG
            }
            
            try {
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction Stop
                Write-Log "Remote Desktop firewall rules enabled" -Level DEBUG
            }
            catch {
                Write-Log "Failed to enable Remote Desktop firewall rules: $_" -Level WARNING
            }
            
            Write-Log "Remote Desktop enabled successfully" -Level SUCCESS
        }
        else {
            Write-Log "Enable or Disable parameter was not specified" -Level ERROR
            $ExitCode = 1
        }
    }
    catch {
        Write-Log "An unexpected error occurred: $_" -Level ERROR
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
