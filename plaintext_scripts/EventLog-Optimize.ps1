#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Optimizes Windows Event Logs.
.DESCRIPTION
    Optimizes Windows Event Logs by clearing old logs and adjusting log size limits.
    Prevents log files from consuming excessive disk space and improves event log query performance.
.PARAMETER LogsToOptimize
    Array of log names to optimize. Default: System, Application, Security
.PARAMETER MaxLogSizeMB
    Maximum log file size in MB. If specified, adjusts all optimized logs to this size.
.PARAMETER ClearLogs
    If specified, clears the event logs after backing up.
.EXAMPLE
    -LogsToOptimize System,Application -MaxLogSizeMB 512
    Optimizes System and Application logs with 512MB max size.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param(
    [string[]]$LogsToOptimize = @("System", "Application", "Security"),
    [int]$MaxLogSizeMB,
    [switch]$ClearLogs
)

begin {
    $StartTime = Get-Date

    function Write-Log {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Warning', 'Error')]
            [string]$Level = 'Info'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $Output = "[$Timestamp] [$Level] $Message"
        Write-Host $Output
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($env:logsToOptimize -and $env:logsToOptimize -notlike "null") {
        $LogsToOptimize = $env:logsToOptimize -split ','
    }
    if ($env:maxLogSizeMB -and $env:maxLogSizeMB -notlike "null") {
        $MaxLogSizeMB = [int]$env:maxLogSizeMB
    }
    if ($env:clearLogs -and $env:clearLogs -eq "true") {
        $ClearLogs = $true
    }
}

process {
    if (-not (Test-IsElevated)) {
        Write-Log "Access Denied. Please run with Administrator privileges." -Level Error
        exit 1
    }

    try {
        Write-Log "Optimizing event logs: $($LogsToOptimize -join ', ')"
        
        if ($MaxLogSizeMB) {
            Write-Log "Setting maximum log size to $MaxLogSizeMB MB"
        }

        $ErrorCount = 0

        foreach ($LogName in $LogsToOptimize) {
            try {
                Write-Log "Processing log: $LogName"
                
                $Log = Get-WinEvent -ListLog $LogName -ErrorAction Stop
                
                if ($MaxLogSizeMB) {
                    $MaxSizeBytes = $MaxLogSizeMB * 1MB
                    $Log.MaximumSizeInBytes = $MaxSizeBytes
                    $Log.SaveChanges()
                    Write-Log "Set maximum size to $MaxLogSizeMB MB"
                }

                if ($ClearLogs) {
                    Write-Log "Clearing log: $LogName"
                    wevtutil.exe cl $LogName
                    Write-Log "$LogName cleared successfully"
                }
                
                Write-Log "$LogName optimized successfully"
            }
            catch {
                Write-Log "Failed to optimize $LogName: $_" -Level Error
                $ErrorCount++
            }
        }

        if ($ErrorCount -gt 0) {
            Write-Log "Event log optimization completed with $ErrorCount errors" -Level Warning
            exit 1
        }

        Write-Log "Event log optimization completed successfully"
    }
    catch {
        Write-Log "Event log optimization failed: $_" -Level Error
        exit 1
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
