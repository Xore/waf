#Requires -Version 5.1

<#
.SYNOPSIS
    Reports the status of Remote Desktop and the port it is listening on.

.DESCRIPTION
    Checks the Remote Desktop (RDP) configuration on a Windows system by querying
    registry settings. Reports whether RDP is enabled or disabled and which port
    it is configured to listen on (default is 3389).
    
    The script checks:
    - fDenyTSConnections registry value (0 = Enabled, 1 = Disabled)
    - PortNumber registry value (default = 3389)
    
    Results can optionally be saved to a NinjaRMM custom field for monitoring.

.PARAMETER RdpStatusCustomFieldName
    Name of a NinjaRMM custom field to save the RDP status results to.

.EXAMPLE
    .\RDP-CheckStatusAndPort.ps1

    [2026-02-10 16:50:00] [INFO] RDP Status: Enabled | Port: 3389

.EXAMPLE
    .\RDP-CheckStatusAndPort.ps1 -RdpStatusCustomFieldName "rdpStatus"

    [2026-02-10 16:50:00] [INFO] RDP Status: Enabled | Port: 3389
    [2026-02-10 16:50:00] [INFO] RDP status saved to custom field: rdpStatus

.OUTPUTS
    None. RDP status information is written to console and optionally to NinjaRMM custom field.

.NOTES
    File Name      : RDP-CheckStatusAndPort.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3.0.0 standards (script-scoped exit code)
    - 1.0: Initial release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$RdpStatusCustomFieldName
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

    if ($env:rdpStatusCustomFieldName -and $env:rdpStatusCustomFieldName -notlike "null") {
        $RdpStatusCustomFieldName = $env:rdpStatusCustomFieldName
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
        Write-Log "Checking Remote Desktop configuration"

        $RdpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
        
        $DenyRdpConnections = Get-ItemProperty -Path $RdpPath -Name 'fDenyTSConnections' -ErrorAction SilentlyContinue | 
            Select-Object -ExpandProperty fDenyTSConnections -ErrorAction SilentlyContinue
        
        $RdpPort = Get-ItemProperty -Path "$RdpPath\WinStations\RDP-Tcp" -Name PortNumber -ErrorAction SilentlyContinue | 
            Select-Object -ExpandProperty PortNumber -ErrorAction SilentlyContinue

        $RdpEnabled = if ($DenyRdpConnections -eq 0) { "Enabled" } else { "Disabled" }
        $RdpPort = if ($null -eq $RdpPort) { "3389" } else { "$RdpPort" }

        $Report = "$RdpEnabled | Port: $RdpPort"

        Write-Log "RDP Status: $Report"

        if ($RdpStatusCustomFieldName) {
            try {
                Set-NinjaProperty -Name $RdpStatusCustomFieldName -Value $Report -ErrorAction Stop
                Write-Log "RDP status saved to custom field: $RdpStatusCustomFieldName"
            }
            catch {
                Write-Log "Failed to set custom field: $_" -Level ERROR
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
