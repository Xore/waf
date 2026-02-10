#Requires -Version 5.1

<#
.SYNOPSIS
    Enable or disable Windows Fast Startup feature.

.DESCRIPTION
    This script configures Windows Fast Startup (also known as Hiberboot or Fast Boot), which
    allows Windows to boot faster by using hibernation technology. When enabled, Windows saves
    system state to disk during shutdown for faster subsequent startups.
    
    Fast Startup can be:
    - Enabled (requires hibernation to be enabled)
    - Disabled while keeping hibernation enabled
    - Disabled along with hibernation completely
    
    Note: Fast Startup may interfere with dual-boot configurations, disk encryption tools,
    or systems requiring clean shutdowns for hardware access.

.PARAMETER Enable
    Enable Fast Startup and hibernation.

.PARAMETER Disable
    Disable Fast Startup while keeping hibernation enabled.

.PARAMETER DisableHibernation
    When used with -Disable, also disables hibernation completely.

.EXAMPLE
    .\Power-SetFastStartup.ps1 -Enable
    
    [Info] Enabling Fast Startup...
    [Info] Fast Startup enabled
    [Info] Hibernation enabled

.EXAMPLE
    .\Power-SetFastStartup.ps1 -Disable
    
    [Info] Disabling Fast Startup...
    [Info] Fast Startup disabled
    [Info] Hibernation remains enabled

.EXAMPLE
    .\Power-SetFastStartup.ps1 -Disable -DisableHibernation
    
    [Info] Disabling Fast Startup and hibernation...
    [Info] Fast Startup disabled
    [Info] Hibernation disabled

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Upgraded to V3 standards with modern PowerShell conventions
    Requires: Administrator privileges to modify power settings
    
.COMPONENT
    Registry - Windows power configuration
    
.LINK
    https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-uefi-fast-startup

.FUNCTIONALITY
    - Enables or disables Windows Fast Startup feature
    - Manages hibernation configuration
    - Modifies registry settings for power management
    - Validates administrator privileges
    - Provides status feedback for all operations
#>

[CmdletBinding()]
param(
    [Parameter(ParameterSetName = 'Enable')]
    [switch]$Enable,
    
    [Parameter(ParameterSetName = 'Disable')]
    [switch]$Disable,
    
    [Parameter(ParameterSetName = 'Disable')]
    [switch]$DisableHibernation
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    
    Set-StrictMode -Version Latest
    
    $script:ExitCode = 0

    $EnableFastBoot = 'Enable Fast Boot and Hibernation'
    $DisableFastBoot = 'Disable Fast Boot'
    $DisableFastBootAndHibernation = 'Disable Fast Boot and Hibernation'

    if ($env:action) {
        switch ($env:action) {
            $EnableFastBoot {
                $Enable = $true
            }
            $DisableFastBoot {
                $Disable = $true
            }
            $DisableFastBootAndHibernation {
                $Disable = $true
                $DisableHibernation = $true
            }
        }
    }

    if ((-not $Enable -and -not $Disable) -or ($Enable -and $Disable)) {
        Write-Host "[Error] Must specify either -Enable or -Disable"
        exit 1
    }

    function Test-IsElevated {
        $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
        $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Set-RegKey {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,
            
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true)]
            $Value,
            
            [Parameter()]
            [ValidateSet('DWord', 'QWord', 'String', 'ExpandedString', 'Binary', 'MultiString', 'Unknown')]
            [string]$PropertyType = 'DWord'
        )

        if (!(Test-Path -Path $Path)) {
            try {
                $null = New-Item -Path $Path -Force -ErrorAction Stop
            }
            catch {
                throw "Unable to create registry path $Path for $Name: $_"
            }
        }

        $CurrentProperty = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($CurrentProperty) {
            $CurrentValue = $CurrentProperty.$Name
            if ($CurrentValue -eq $Value) {
                Write-Host "[Info] $Path\$Name is already set to '$Value'"
            }
            else {
                try {
                    $null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop
                    $NewValue = (Get-ItemProperty -Path $Path -Name $Name).$Name
                    Write-Host "[Info] $Path\$Name changed from $CurrentValue to $NewValue"
                }
                catch {
                    throw "Unable to set registry key $Name at $Path: $_"
                }
            }
        }
        else {
            try {
                $null = New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop
                $NewValue = (Get-ItemProperty -Path $Path -Name $Name).$Name
                Write-Host "[Info] Set $Path\$Name to $NewValue"
            }
            catch {
                throw "Unable to create registry key $Name at $Path: $_"
            }
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

        if ($Enable) {
            Write-Host '[Info] Enabling Fast Startup...'
            
            try {
                Set-RegKey -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 1
                Write-Host '[Info] Fast Startup enabled'
            }
            catch {
                Write-Host "[Error] Failed to enable Fast Startup: $_"
                $script:ExitCode = 1
                return
            }

            try {
                Set-RegKey -Path 'HKLM:\System\CurrentControlSet\Control\Power' -Name 'HibernateEnabled' -Value 1
                Write-Host '[Info] Hibernation enabled'
            }
            catch {
                Write-Host "[Error] Failed to enable hibernation: $_"
                $script:ExitCode = 1
            }
        }
        elseif ($Disable) {
            if ($DisableHibernation) {
                Write-Host '[Info] Disabling Fast Startup and hibernation...'
            }
            else {
                Write-Host '[Info] Disabling Fast Startup...'
            }
            
            try {
                Set-RegKey -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0
                Write-Host '[Info] Fast Startup disabled'
            }
            catch {
                Write-Host "[Error] Failed to disable Fast Startup: $_"
                $script:ExitCode = 1
                return
            }

            if ($DisableHibernation) {
                try {
                    Set-RegKey -Path 'HKLM:\System\CurrentControlSet\Control\Power' -Name 'HibernateEnabled' -Value 0
                    Write-Host '[Info] Hibernation disabled'
                }
                catch {
                    Write-Host "[Error] Failed to disable hibernation: $_"
                    $script:ExitCode = 1
                }
            }
            else {
                Write-Host '[Info] Hibernation remains enabled'
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
