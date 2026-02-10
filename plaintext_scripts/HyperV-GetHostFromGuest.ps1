#Requires -Version 5.1

<#
.SYNOPSIS
    Reports on the hypervisor hostname of a guest VM.

.DESCRIPTION
    Reports on the hypervisor hostname of a guest VM. Must be run on a Hyper-V guest VM.
    Queries the Hyper-V registry keys to determine the physical host name where the VM
    is running. This information is useful for asset management and troubleshooting.
    
    The script requires that the Hyper-V Data Exchange integration service is enabled
    on the guest VM. This integration service populates the registry key with host information.

.PARAMETER TextCustomFieldName
    Name of the NinjaRMM custom field where the hypervisor hostname will be saved.

.EXAMPLE
    .\HyperV-GetHostFromGuest.ps1

    [2026-02-10 16:40:00] [INFO] WIN11-EDUCATION is hosted on: HYPERV-HOST-1

.EXAMPLE
    .\HyperV-GetHostFromGuest.ps1 -TextCustomFieldName "hypervHost"

    [2026-02-10 16:40:00] [INFO] WIN11-EDUCATION is hosted on: HYPERV-HOST-1
    [2026-02-10 16:40:00] [INFO] Hypervisor host saved to custom field: hypervHost

.OUTPUTS
    None. Hypervisor hostname is written to console and optionally to NinjaRMM custom field.

.NOTES
    File Name      : HyperV-GetHostFromGuest.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3.0.0 standards (script-scoped exit code)
    - 1.0: Initial release
    
    Requirements:
    - Must be run on a Hyper-V guest VM
    - Hyper-V Data Exchange integration service must be enabled
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$TextCustomFieldName
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
            'ERROR' { Write-Error $LogMessage }
            'WARNING' { Write-Warning $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:TextCustomFieldName -and $env:TextCustomFieldName -notlike "null") {
        $TextCustomFieldName = $env:TextCustomFieldName
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-IsVM {
        try {
            $model = (Get-CimInstance -ClassName Win32_ComputerSystem -Property Model -ErrorAction Stop).Model

            if ($model -match "Virtual|VM") {
                return $true
            }
            else {
                $manufacturer = (Get-CimInstance -Class Win32_BIOS -Property Manufacturer -ErrorAction Stop).Manufacturer

                if ($manufacturer -match "Proxmox") {
                    return $true
                }
                else {
                    return $false
                }
            }
        }
        catch {
            Write-Log "Unable to validate whether this device is a VM: $_" -Level ERROR
            exit 1
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
}

process {
    try {
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. Please run with Administrator privileges." -Level ERROR
            $script:ExitCode = 1
            return
        }

        if (-not (Test-IsVM)) {
            Write-Log "Host is not a virtual machine." -Level ERROR
            $script:ExitCode = 1
            return
        }

        $regPath = "HKLM:\Software\Microsoft\Virtual Machine\Guest\Parameters"

        if (-not (Test-Path $regPath)) {
            Write-Log "Registry key cannot be found. This either means that $env:computername is not a Hyper-V guest, or the 'Data Exchange' integration is disabled in the VM settings." -Level ERROR
            $script:ExitCode = 1
            return
        }

        $HyperVHost = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).PhysicalHostName

        if ([string]::IsNullOrWhiteSpace($HyperVHost)) {
            Write-Log "Registry key exists but the value is blank." -Level ERROR
            $script:ExitCode = 1
            return
        }

        Write-Log "$env:computername is hosted on: $HyperVHost"

        if ($TextCustomFieldName) {
            try {
                Set-NinjaProperty -Name $TextCustomFieldName -Value $HyperVHost -ErrorAction Stop
                Write-Log "Hypervisor host saved to custom field: $TextCustomFieldName"
            }
            catch {
                Write-Log "Error setting custom field: $_" -Level ERROR
                $script:ExitCode = 1
            }
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
