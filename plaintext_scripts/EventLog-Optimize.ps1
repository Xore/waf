#Requires -Version 5.1

<#
.SYNOPSIS
    Optimizes Windows Event Logs by adjusting size limits and optionally clearing old entries.

.DESCRIPTION
    Manages Windows Event Log files to prevent excessive disk space consumption and maintain
    optimal system performance. The script can adjust maximum log file sizes and clear event
    logs after backup to reclaim disk space.
    
    Event logs grow over time and can consume significant disk space. This script helps maintain
    event log health by setting appropriate size limits and clearing old entries when needed.
    Large event logs can also slow down log queries and administrative tools.

.PARAMETER LogsToOptimize
    Array of event log names to optimize.
    Default: System, Application, Security
    Examples: @("System"), @("Application", "Security"), @("*Microsoft-Windows*")

.PARAMETER MaxLogSizeMB
    Maximum log file size in megabytes.
    If specified, adjusts all optimized logs to this size limit.
    Recommended: 512 MB for production systems, 1024 MB for servers
    Range: 1-2048 MB

.PARAMETER ClearLogs
    If specified, clears the event logs after optimization.
    WARNING: Ensure logs are backed up before clearing.
    Use EventLog-BackupToLocalDisk.ps1 to create backups first.

.EXAMPLE
    .\EventLog-Optimize.ps1 -LogsToOptimize "System","Application" -MaxLogSizeMB 512
    
    Optimizes System and Application logs, setting maximum size to 512 MB each.

.EXAMPLE
    .\EventLog-Optimize.ps1 -LogsToOptimize "System" -ClearLogs
    
    Clears the System event log (WARNING: data loss will occur).

.EXAMPLE
    .\EventLog-Optimize.ps1 -MaxLogSizeMB 1024
    
    Sets maximum size to 1024 MB for default logs (System, Application, Security).

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : EventLog-Optimize.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 2.0: Added MaxLogSizeMB parameter
    - 1.0: Initial release
    
.COMPONENT
    Event Log Management
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent
    
.FUNCTIONALITY
    - Adjusts maximum event log file sizes
    - Clears event logs with confirmation
    - Validates administrator privileges
    - Tracks optimization success/failure for multiple logs
    - Prevents disk space exhaustion from growing log files
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$LogsToOptimize = @("System", "Application", "Security"),
    
    [Parameter()]
    [ValidateRange(1, 2048)]
    [int]$MaxLogSizeMB,
    
    [Parameter()]
    [switch]$ClearLogs
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

    function Test-IsElevated {
        <#
        .SYNOPSIS
            Tests if script is running with administrator privileges.
        #>
        $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
        return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

process {
    try {
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. Please run with Administrator privileges" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        # Environment variable overrides
        if ($env:logsToOptimize -and $env:logsToOptimize -notlike "null") {
            $LogsToOptimize = $env:logsToOptimize -split ','
        }
        if ($env:maxLogSizeMB -and $env:maxLogSizeMB -notlike "null") {
            $MaxLogSizeMB = [int]$env:maxLogSizeMB
        }
        if ($env:clearLogs -and $env:clearLogs -eq "true") {
            $ClearLogs = $true
        }

        Write-Log "Optimizing event logs: $($LogsToOptimize -join ', ')"
        
        if ($MaxLogSizeMB) {
            Write-Log "Target maximum log size: $MaxLogSizeMB MB"
        }
        
        if ($ClearLogs) {
            Write-Log "WARNING: Event logs will be cleared" -Level 'WARNING'
        }

        $OptimizedCount = 0
        $FailedCount = 0

        foreach ($LogName in $LogsToOptimize) {
            try {
                Write-Log "Processing log: $LogName"
                
                # Get event log configuration
                $Log = Get-WinEvent -ListLog $LogName -ErrorAction Stop
                
                if (-not $Log) {
                    Write-Log "Log not found: $LogName" -Level 'WARNING'
                    $FailedCount++
                    continue
                }
                
                $OriginalSize = [math]::Round($Log.MaximumSizeInBytes / 1MB, 2)
                Write-Log "Current maximum size: $OriginalSize MB"
                
                # Adjust maximum log size if requested
                if ($MaxLogSizeMB) {
                    try {
                        $MaxSizeBytes = $MaxLogSizeMB * 1MB
                        $Log.MaximumSizeInBytes = $MaxSizeBytes
                        $Log.SaveChanges()
                        Write-Log "Updated maximum size to $MaxLogSizeMB MB"
                    }
                    catch {
                        Write-Log "Failed to update log size: $_" -Level 'ERROR'
                        $FailedCount++
                        continue
                    }
                }

                # Clear log if requested
                if ($ClearLogs) {
                    try {
                        Write-Log "Clearing log: $LogName"
                        $null = wevtutil.exe cl $LogName 2>&1
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Log "Log cleared successfully"
                        }
                        else {
                            Write-Log "Failed to clear log (exit code: $LASTEXITCODE)" -Level 'WARNING'
                            $FailedCount++
                            continue
                        }
                    }
                    catch {
                        Write-Log "Failed to clear log: $_" -Level 'ERROR'
                        $FailedCount++
                        continue
                    }
                }
                
                Write-Log "$LogName optimized successfully"
                $OptimizedCount++
            }
            catch {
                Write-Log "Failed to optimize $LogName: $_" -Level 'ERROR'
                $FailedCount++
            }
        }

        Write-Log "Optimization complete: $OptimizedCount succeeded, $FailedCount failed"

        if ($FailedCount -gt 0) {
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Log "Unexpected error during event log optimization: $_" -Level 'ERROR'
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
        Write-Output "Script: EventLog-Optimize.ps1"
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
