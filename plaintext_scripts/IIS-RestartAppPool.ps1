#Requires -Version 5.1 -Modules WebAdministration

<#
.SYNOPSIS
    Restarts a specified IIS application pool.

.DESCRIPTION
    This script restarts an IIS application pool by name. It verifies the pool exists, stops it 
    gracefully, waits for complete shutdown, then starts it again. This is useful for applying 
    configuration changes, clearing memory leaks, or recovering from hung worker processes.
    
    The script includes safety checks to ensure the application pool exists and provides 
    detailed status reporting throughout the restart process.

.PARAMETER AppPoolName
    Name of the IIS application pool to restart. Required parameter.

.PARAMETER WaitTimeout
    Maximum seconds to wait for the app pool to stop before forcing. Default: 30 seconds

.PARAMETER SaveToCustomField
    Name of a custom field to save the restart operation results.

.EXAMPLE
    -AppPoolName "DefaultAppPool"

    [Info] Restarting IIS application pool 'DefaultAppPool'...
    [Info] Current state: Started
    [Info] Stopping application pool...
    [Info] Application pool stopped successfully
    [Info] Starting application pool...
    [Info] Application pool 'DefaultAppPool' restarted successfully

.EXAMPLE
    -AppPoolName "MyWebApp" -WaitTimeout 60

    [Info] Restarting IIS application pool 'MyWebApp'...
    [Info] Using wait timeout of 60 seconds
    [Info] Application pool 'MyWebApp' restarted successfully

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2 with IIS role
    Release notes: Initial release for WAF v3.0
    Requires: WebAdministration PowerShell module, IIS role installed
    
.COMPONENT
    WebAdministration - IIS management PowerShell module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/webadministration/

.FUNCTIONALITY
    - Restarts IIS application pools by name
    - Validates application pool exists before restart
    - Reports current state before restart
    - Gracefully stops app pool with configurable timeout
    - Waits for complete shutdown before starting
    - Verifies successful restart
    - Can save restart results to custom fields
    - Provides detailed status throughout operation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppPoolName,
    [int]$WaitTimeout = 30,
    [string]$SaveToCustomField
)

begin {
    if ($env:appPoolName -and $env:appPoolName -notlike "null") {
        $AppPoolName = $env:appPoolName
    }
    if ($env:waitTimeout -and $env:waitTimeout -notlike "null") {
        $WaitTimeout = [int]$env:waitTimeout
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
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
    if ([string]::IsNullOrWhiteSpace($AppPoolName)) {
        Write-Host "[Error] AppPoolName parameter is required"
        exit 1
    }

    try {
        Write-Host "[Info] Restarting IIS application pool '$AppPoolName'..."
        
        Import-Module WebAdministration -ErrorAction Stop

        $AppPool = Get-Item "IIS:\AppPools\$AppPoolName" -ErrorAction SilentlyContinue

        if (-not $AppPool) {
            Write-Host "[Error] Application pool '$AppPoolName' not found"
            exit 1
        }

        $InitialState = $AppPool.State
        Write-Host "[Info] Current state: $InitialState"

        if ($WaitTimeout -ne 30) {
            Write-Host "[Info] Using wait timeout of $WaitTimeout seconds"
        }

        if ($InitialState -eq "Started") {
            Write-Host "[Info] Stopping application pool..."
            Stop-WebAppPool -Name $AppPoolName -ErrorAction Stop
            
            $ElapsedSeconds = 0
            while ((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Stopped" -and $ElapsedSeconds -lt $WaitTimeout) {
                Start-Sleep -Seconds 1
                $ElapsedSeconds++
            }

            if ((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Stopped") {
                Write-Host "[Warn] Application pool did not stop within $WaitTimeout seconds, forcing restart"
            } else {
                Write-Host "[Info] Application pool stopped successfully"
            }
        }

        Write-Host "[Info] Starting application pool..."
        Start-WebAppPool -Name $AppPoolName -ErrorAction Stop
        
        Start-Sleep -Seconds 2
        $FinalState = (Get-WebAppPoolState -Name $AppPoolName).Value

        if ($FinalState -eq "Started") {
            Write-Host "[Info] Application pool '$AppPoolName' restarted successfully"
            $Result = "App pool '$AppPoolName' restarted successfully at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        } else {
            Write-Host "[Error] Application pool is in state '$FinalState' after restart attempt"
            $Result = "App pool '$AppPoolName' restart failed - final state: $FinalState"
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
        Write-Host "[Error] Failed to restart application pool: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
