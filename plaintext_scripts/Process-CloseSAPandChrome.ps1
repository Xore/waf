#Requires -Version 5.1

<#
.SYNOPSIS
    Forcefully closes SAP Logon and Google Chrome applications.

.DESCRIPTION
    This script terminates running instances of SAP Logon and Google Chrome browsers.
    Commonly used before system maintenance, software updates, or when troubleshooting
    application conflicts.
    
    WARNING: This script forcefully terminates processes without saving. Unsaved work
    in SAP or Chrome will be lost. Ensure users are notified before running.

.PARAMETER Applications
    Array of application process names to terminate.
    Default: saplogon, chrome
    
.PARAMETER WaitForExit
    If specified, waits up to specified seconds for graceful termination before forcing.
    Range: 1-60 seconds

.EXAMPLE
    .\Process-CloseSAPandChrome.ps1
    
    Forcefully closes SAP Logon and Chrome processes.

.EXAMPLE
    .\Process-CloseSAPandChrome.ps1 -Applications "saplogon"
    
    Closes only SAP Logon, leaving Chrome running.

.EXAMPLE
    .\Process-CloseSAPandChrome.ps1 -WaitForExit 10
    
    Attempts graceful close for 10 seconds before forcing termination.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : Process-CloseSAPandChrome.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete rewrite to V3 standards with PowerShell cmdlets
    - 1.0: Initial batch script version
    
.COMPONENT
    Process Management
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/stop-process
    
.FUNCTIONALITY
    - Terminates SAP Logon application processes
    - Terminates Google Chrome browser processes
    - Supports both graceful and forced termination
    - Reports success/failure for each application
    - Tracks all terminated process instances
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$Applications = @('saplogon', 'chrome'),
    
    [Parameter()]
    [ValidateRange(1, 60)]
    [int]$WaitForExit = 0
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
}

process {
    try {
        # Environment variable override
        if ($env:applications -and $env:applications -notlike 'null') {
            $Applications = $env:applications -split ','
        }
        if ($env:waitForExit -and $env:waitForExit -notlike 'null') {
            $WaitForExit = [int]$env:waitForExit
        }

        Write-Log 'WARNING: This will forcefully close applications - unsaved work will be lost' -Level 'WARNING'
        Write-Log "Target applications: $($Applications -join ', ')"
        
        if ($WaitForExit -gt 0) {
            Write-Log "Will attempt graceful close for $WaitForExit seconds before forcing"
        }

        $ClosedCount = 0
        $NotFoundCount = 0
        $FailedCount = 0

        foreach ($AppName in $Applications) {
            try {
                $Processes = Get-Process -Name $AppName -ErrorAction SilentlyContinue
                
                if ($Processes) {
                    $ProcessCount = ($Processes | Measure-Object).Count
                    Write-Log "Found $ProcessCount instance(s) of $AppName"
                    
                    foreach ($Process in $Processes) {
                        try {
                            if ($WaitForExit -gt 0) {
                                # Try graceful close first
                                Write-Log "Attempting graceful close of $AppName (PID: $($Process.Id))"
                                $Process.CloseMainWindow() | Out-Null
                                
                                # Wait for process to exit
                                $Waited = $Process.WaitForExit($WaitForExit * 1000)
                                
                                if (-not $Waited) {
                                    Write-Log "Process did not exit gracefully, forcing termination" -Level 'WARNING'
                                    Stop-Process -Id $Process.Id -Force -ErrorAction Stop
                                }
                                else {
                                    Write-Log "Process closed gracefully"
                                }
                            }
                            else {
                                # Force immediate termination
                                Write-Log "Forcing termination of $AppName (PID: $($Process.Id))"
                                Stop-Process -Id $Process.Id -Force -ErrorAction Stop
                            }
                            
                            $ClosedCount++
                        }
                        catch {
                            Write-Log "Failed to close $AppName (PID: $($Process.Id)): $_" -Level 'ERROR'
                            $FailedCount++
                        }
                    }
                }
                else {
                    Write-Log "No running instances of $AppName found"
                    $NotFoundCount++
                }
            }
            catch {
                Write-Log "Error processing $AppName: $_" -Level 'ERROR'
                $FailedCount++
            }
        }

        Write-Log "Summary: $ClosedCount closed, $NotFoundCount not running, $FailedCount failed"

        if ($FailedCount -gt 0) {
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Log "Unexpected error closing applications: $_" -Level 'ERROR'
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
        Write-Output "Script: Process-CloseSAPandChrome.ps1"
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
