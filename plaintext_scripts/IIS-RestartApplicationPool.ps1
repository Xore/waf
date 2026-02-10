#Requires -Version 5.1 -Modules WebAdministration

<#
.SYNOPSIS
    Restarts a specified IIS application pool.

.DESCRIPTION
    This script stops and starts an IIS application pool to force a complete restart. It provides
    detailed status reporting including current state verification, stop/start operations, and
    final state confirmation.
    
    Restarting application pools is a common troubleshooting step for resolving memory leaks,
    configuration issues, or applying code changes in web applications.

.PARAMETER ApplicationPoolName
    Name of the IIS application pool to restart. Required.

.PARAMETER WaitSeconds
    Number of seconds to wait between stop and start operations. Default: 5 seconds

.PARAMETER VerifyState
    If specified, verifies the pool is actually running after restart. Default: True

.EXAMPLE
    -ApplicationPoolName "DefaultAppPool"

    [Info] Restarting application pool 'DefaultAppPool'...
    [Info] Current state: Started
    [Info] Stopping application pool...
    [Info] Application pool stopped successfully
    [Info] Waiting 5 seconds...
    [Info] Starting application pool...
    [Info] Application pool started successfully
    [Info] Final state: Started

.EXAMPLE
    -ApplicationPoolName "MyWebApp" -WaitSeconds 10

    Waits 10 seconds between stop and start for thorough cleanup.

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2 with IIS role
    Release notes: Initial release for WAF v3.0
    Requires: WebAdministration PowerShell module, IIS role installed, administrator privileges
    
.COMPONENT
    WebAdministration - IIS management PowerShell module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/webadministration/

.FUNCTIONALITY
    - Restarts specified IIS application pool
    - Verifies current state before restart
    - Stops application pool gracefully
    - Waits specified time for cleanup
    - Starts application pool
    - Verifies final running state
    - Provides detailed operation status
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ApplicationPoolName,
    
    [int]$WaitSeconds = 5,
    
    [switch]$VerifyState = $true
)

begin {
    if ($env:applicationPoolName -and $env:applicationPoolName -notlike "null") {
        $ApplicationPoolName = $env:applicationPoolName
    }
    if ($env:waitSeconds -and $env:waitSeconds -notlike "null") {
        $WaitSeconds = [int]$env:waitSeconds
    }
    if ($env:verifyState -eq "false") {
        $VerifyState = $false
    }

    $ExitCode = 0
}

process {
    try {
        Write-Host "[Info] Restarting application pool '$ApplicationPoolName'..."
        
        Import-Module WebAdministration -ErrorAction Stop
        
        $AppPool = Get-Item "IIS:\AppPools\$ApplicationPoolName" -ErrorAction Stop
        
        if (-not $AppPool) {
            Write-Host "[Error] Application pool '$ApplicationPoolName' not found"
            exit 1
        }

        Write-Host "[Info] Current state: $($AppPool.State)"

        if ($AppPool.State -ne "Stopped") {
            Write-Host "[Info] Stopping application pool..."
            Stop-WebAppPool -Name $ApplicationPoolName -ErrorAction Stop
            
            $Timeout = 30
            $Elapsed = 0
            while ((Get-WebAppPoolState -Name $ApplicationPoolName).Value -ne "Stopped" -and $Elapsed -lt $Timeout) {
                Start-Sleep -Seconds 1
                $Elapsed++
            }
            
            if ((Get-WebAppPoolState -Name $ApplicationPoolName).Value -eq "Stopped") {
                Write-Host "[Info] Application pool stopped successfully"
            } else {
                Write-Host "[Error] Application pool did not stop within timeout period"
                $ExitCode = 1
            }
        }

        Write-Host "[Info] Waiting $WaitSeconds seconds..."
        Start-Sleep -Seconds $WaitSeconds

        Write-Host "[Info] Starting application pool..."
        Start-WebAppPool -Name $ApplicationPoolName -ErrorAction Stop
        
        $Timeout = 30
        $Elapsed = 0
        while ((Get-WebAppPoolState -Name $ApplicationPoolName).Value -ne "Started" -and $Elapsed -lt $Timeout) {
            Start-Sleep -Seconds 1
            $Elapsed++
        }

        $FinalState = (Get-WebAppPoolState -Name $ApplicationPoolName).Value
        Write-Host "[Info] Final state: $FinalState"

        if ($VerifyState -and $FinalState -ne "Started") {
            Write-Host "[Error] Application pool is not running after restart"
            $ExitCode = 1
        } else {
            Write-Host "[Info] Application pool restarted successfully"
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
