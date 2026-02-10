#Requires -Version 5.1
#Requires -Modules WebAdministration

<#
.SYNOPSIS
    Restarts a specified IIS application pool.

.DESCRIPTION
    This script stops and starts an IIS application pool to force a complete restart. It provides
    detailed status reporting including current state verification, stop/start operations, and
    final state confirmation.
    
    Restarting application pools is a common troubleshooting step for resolving memory leaks,
    configuration issues, or applying code changes in web applications. The script performs a
    graceful stop with configurable wait time before starting the pool again.

.PARAMETER ApplicationPoolName
    Name of the IIS application pool to restart. Required.
    Must match an existing application pool name exactly (case-insensitive).

.PARAMETER WaitSeconds
    Number of seconds to wait between stop and start operations.
    This allows time for worker processes to fully terminate and release resources.
    Default: 5 seconds
    Range: 0-60 seconds

.PARAMETER VerifyState
    If specified, verifies the pool is actually running after restart.
    Exits with error code if pool fails to start.
    Default: True

.EXAMPLE
    .\IIS-RestartApplicationPool.ps1 -ApplicationPoolName "DefaultAppPool"

    [2026-02-11 00:02:00] [INFO] Restarting application pool 'DefaultAppPool'
    [2026-02-11 00:02:00] [INFO] Current state: Started
    [2026-02-11 00:02:01] [INFO] Stopping application pool
    [2026-02-11 00:02:02] [INFO] Application pool stopped successfully
    [2026-02-11 00:02:02] [INFO] Waiting 5 seconds
    [2026-02-11 00:02:07] [INFO] Starting application pool
    [2026-02-11 00:02:08] [INFO] Application pool started successfully
    [2026-02-11 00:02:08] [INFO] Final state: Started

.EXAMPLE
    .\IIS-RestartApplicationPool.ps1 -ApplicationPoolName "MyWebApp" -WaitSeconds 10

    Waits 10 seconds between stop and start for thorough cleanup.

.EXAMPLE
    .\IIS-RestartApplicationPool.ps1 -ApplicationPoolName "APIAppPool" -VerifyState:$false

    Restarts pool without verifying final running state.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : IIS-RestartApplicationPool.ps1
    Prerequisite   : PowerShell 5.1 or higher, IIS role with WebAdministration module
    Requires       : Administrator privileges
    Minimum OS     : Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log and execution summary
    - 1.0: Initial release
    
.COMPONENT
    WebAdministration - IIS management PowerShell module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/webadministration/

.FUNCTIONALITY
    - Restarts specified IIS application pool
    - Verifies current state before restart
    - Stops application pool gracefully with timeout
    - Waits specified time for worker process cleanup
    - Starts application pool with verification
    - Provides detailed operation status
    - Handles errors with proper exit codes
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "IIS application pool name")]
    [string]$ApplicationPoolName,
    
    [Parameter()]
    [ValidateRange(0, 60)]
    [int]$WaitSeconds = 5,
    
    [Parameter()]
    [switch]$VerifyState = $true
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest
    
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        Write-Output $LogMessage
        
        if ($Level -eq 'ERROR') { $script:ErrorCount++ }
        if ($Level -eq 'WARNING') { $script:WarningCount++ }
    }

    # Environment variable overrides
    if ($env:applicationPoolName -and $env:applicationPoolName -notlike "null") {
        $ApplicationPoolName = $env:applicationPoolName
    }
    if ($env:waitSeconds -and $env:waitSeconds -notlike "null") {
        $WaitSeconds = [int]$env:waitSeconds
    }
    if ($env:verifyState -eq "false") {
        $VerifyState = $false
    }
}

process {
    try {
        Write-Log "Restarting application pool '$ApplicationPoolName'"
        
        # Import WebAdministration module
        try {
            Import-Module WebAdministration -ErrorAction Stop
            Write-Log "WebAdministration module loaded successfully"
        }
        catch {
            Write-Log "Failed to load WebAdministration module - IIS may not be installed" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }
        
        # Verify application pool exists
        $AppPool = Get-Item "IIS:\AppPools\$ApplicationPoolName" -ErrorAction SilentlyContinue
        
        if (-not $AppPool) {
            Write-Log "Application pool '$ApplicationPoolName' not found" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        Write-Log "Current state: $($AppPool.State)"

        # Stop application pool if not already stopped
        if ($AppPool.State -ne "Stopped") {
            Write-Log "Stopping application pool"
            Stop-WebAppPool -Name $ApplicationPoolName -ErrorAction Stop
            
            # Wait for pool to stop (max 30 seconds)
            $Timeout = 30
            $Elapsed = 0
            
            while ((Get-WebAppPoolState -Name $ApplicationPoolName).Value -ne "Stopped" -and $Elapsed -lt $Timeout) {
                Start-Sleep -Seconds 1
                $Elapsed++
            }
            
            $CurrentState = (Get-WebAppPoolState -Name $ApplicationPoolName).Value
            
            if ($CurrentState -eq "Stopped") {
                Write-Log "Application pool stopped successfully"
            }
            else {
                Write-Log "Application pool did not stop within $Timeout seconds (state: $CurrentState)" -Level 'ERROR'
                $script:ExitCode = 1
                return
            }
        }
        else {
            Write-Log "Application pool is already stopped"
        }

        # Wait before starting
        if ($WaitSeconds -gt 0) {
            Write-Log "Waiting $WaitSeconds seconds for worker process cleanup"
            Start-Sleep -Seconds $WaitSeconds
        }

        # Start application pool
        Write-Log "Starting application pool"
        Start-WebAppPool -Name $ApplicationPoolName -ErrorAction Stop
        
        # Wait for pool to start (max 30 seconds)
        $Timeout = 30
        $Elapsed = 0
        
        while ((Get-WebAppPoolState -Name $ApplicationPoolName).Value -ne "Started" -and $Elapsed -lt $Timeout) {
            Start-Sleep -Seconds 1
            $Elapsed++
        }

        $FinalState = (Get-WebAppPoolState -Name $ApplicationPoolName).Value
        Write-Log "Final state: $FinalState"

        # Verify state if requested
        if ($VerifyState -and $FinalState -ne "Started") {
            Write-Log "Application pool is not running after restart" -Level 'ERROR'
            $script:ExitCode = 1
        }
        else {
            Write-Log "Application pool restarted successfully"
        }
    }
    catch {
        Write-Log "Failed to restart application pool: $_" -Level 'ERROR'
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Output "`n========================================"
        Write-Output "Execution Summary"
        Write-Output "========================================"
        Write-Output "Script: IIS-RestartApplicationPool.ps1"
        Write-Output "Duration: $Duration seconds"
        Write-Output "Errors: $script:ErrorCount"
        Write-Output "Warnings: $script:WarningCount"
        Write-Output "Exit Code: $script:ExitCode"
        Write-Output "========================================"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
