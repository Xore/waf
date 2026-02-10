#Requires -Version 5.1

<#
.SYNOPSIS
    Restarts a Windows service by name.

.DESCRIPTION
    This script restarts a Windows service with proper error handling and status verification. 
    It stops the service gracefully, waits for complete shutdown, then starts it again. The 
    script includes configurable timeout values and validates the service exists before attempting 
    to restart it.
    
    This is useful for applying configuration changes, clearing memory leaks, or recovering from 
    service failures without requiring a full system restart.

.PARAMETER ServiceName
    Name of the Windows service to restart. This can be either the display name or the service name.

.PARAMETER WaitTimeout
    Maximum seconds to wait for the service to stop before forcing. Default: 30 seconds

.PARAMETER StartTimeout
    Maximum seconds to wait for the service to start. Default: 30 seconds

.PARAMETER SaveToCustomField
    Name of a custom field to save the restart operation results.

.EXAMPLE
    -ServiceName "Spooler"

    [Info] Restarting service 'Spooler'...
    [Info] Current status: Running
    [Info] Stopping service...
    [Info] Service stopped successfully
    [Info] Starting service...
    [Info] Service 'Spooler' restarted successfully

.EXAMPLE
    -ServiceName "wuauserv" -WaitTimeout 60

    [Info] Restarting service 'wuauserv'...
    [Info] Using wait timeout of 60 seconds
    [Info] Service 'wuauserv' restarted successfully

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Requires: Administrator privileges
    
.COMPONENT
    Service - Windows Service Management
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/restart-service

.FUNCTIONALITY
    - Restarts Windows services by name
    - Validates service exists before restart
    - Reports current state before restart
    - Gracefully stops service with configurable timeout
    - Waits for complete shutdown before starting
    - Verifies successful restart
    - Can save restart results to custom fields
    - Provides detailed status throughout operation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceName,
    [int]$WaitTimeout = 30,
    [int]$StartTimeout = 30,
    [string]$SaveToCustomField
)

begin {
    if ($env:serviceName -and $env:serviceName -notlike "null") {
        $ServiceName = $env:serviceName
    }
    if ($env:waitTimeout -and $env:waitTimeout -notlike "null") {
        $WaitTimeout = [int]$env:waitTimeout
    }
    if ($env:startTimeout -and $env:startTimeout -notlike "null") {
        $StartTimeout = [int]$env:startTimeout
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

    if ([string]::IsNullOrWhiteSpace($ServiceName)) {
        Write-Host "[Error] ServiceName parameter is required"
        exit 1
    }

    try {
        Write-Host "[Info] Restarting service '$ServiceName'..."
        
        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if (-not $Service) {
            $Service = Get-Service -DisplayName $ServiceName -ErrorAction SilentlyContinue
        }

        if (-not $Service) {
            Write-Host "[Error] Service '$ServiceName' not found"
            exit 1
        }

        $ActualServiceName = $Service.Name
        $DisplayName = $Service.DisplayName
        $InitialStatus = $Service.Status
        
        Write-Host "[Info] Current status: $InitialStatus"

        if ($WaitTimeout -ne 30 -or $StartTimeout -ne 30) {
            Write-Host "[Info] Using wait timeout of $WaitTimeout seconds and start timeout of $StartTimeout seconds"
        }

        if ($InitialStatus -eq "Running") {
            Write-Host "[Info] Stopping service..."
            Stop-Service -Name $ActualServiceName -Force -ErrorAction Stop
            
            $Service.WaitForStatus('Stopped', (New-TimeSpan -Seconds $WaitTimeout))
            
            if ($Service.Status -eq "Stopped") {
                Write-Host "[Info] Service stopped successfully"
            } else {
                Write-Host "[Warn] Service did not stop within $WaitTimeout seconds"
            }
        }

        Write-Host "[Info] Starting service..."
        Start-Service -Name $ActualServiceName -ErrorAction Stop
        
        $Service.WaitForStatus('Running', (New-TimeSpan -Seconds $StartTimeout))
        
        $Service.Refresh()
        $FinalStatus = $Service.Status

        if ($FinalStatus -eq "Running") {
            Write-Host "[Info] Service '$DisplayName' restarted successfully"
            $Result = "Service '$DisplayName' restarted successfully at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        } else {
            Write-Host "[Error] Service is in status '$FinalStatus' after restart attempt"
            $Result = "Service '$DisplayName' restart failed - final status: $FinalStatus"
            $ExitCode = 1
        }

        if ($SaveToCustomField) {
            try {
                $Result | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            } catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to restart service: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
