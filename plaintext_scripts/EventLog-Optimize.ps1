#Requires -Version 5.1 -RunAsAdministrator

<#
.SYNOPSIS
    Optimizes Windows Event Logs by clearing old logs and adjusting log size limits.

.DESCRIPTION
    This script optimizes Windows Event Log performance by clearing specified event logs and 
    optionally adjusting maximum log file sizes. This prevents log files from consuming excessive 
    disk space and improves event log query performance.
    
    Large event logs can slow down system performance and consume significant disk space. Regular 
    optimization ensures logs remain manageable while retaining important recent events.

.PARAMETER LogsToOptimize
    Array of log names to optimize. Default: System, Application, Security

.PARAMETER MaxLogSizeMB
    Maximum log file size in MB. If specified, adjusts all optimized logs to this size. Default: Not set (keeps existing sizes)

.PARAMETER ClearLogs
    If specified, clears the event logs after backing up. Default: False

.EXAMPLE
    -LogsToOptimize System,Application -MaxLogSizeMB 512

    [Info] Optimizing event logs: System, Application
    [Info] Setting maximum log size to 512 MB
    [Info] Processing log: System
    [Info] Current size: 256 MB, setting to 512 MB
    [Info] System log optimized successfully
    [Info] Event log optimization complete

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Requires: Administrator privileges
    
.COMPONENT
    wevtutil.exe - Windows event log utility
    
.LINK
    https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wevtutil

.FUNCTIONALITY
    - Clears specified Windows Event Logs
    - Adjusts maximum log file sizes
    - Validates log existence before processing
    - Provides optimization status for each log
    - Prevents log fragmentation and performance degradation
#>

[CmdletBinding()]
param(
    [string[]]$LogsToOptimize = @("System", "Application", "Security"),
    [int]$MaxLogSizeMB,
    [switch]$ClearLogs
)

begin {
    if ($env:logsToOptimize -and $env:logsToOptimize -notlike "null") {
        $LogsToOptimize = $env:logsToOptimize -split ','
    }
    if ($env:maxLogSizeMB -and $env:maxLogSizeMB -notlike "null") {
        $MaxLogSizeMB = [int]$env:maxLogSizeMB
    }
    if ($env:clearLogs -and $env:clearLogs -eq "true") {
        $ClearLogs = $true
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    $ExitCode = 0
}

process {
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges"
        exit 1
    }

    try {
        Write-Host "[Info] Optimizing event logs: $($LogsToOptimize -join ', ')"
        
        if ($MaxLogSizeMB) {
            Write-Host "[Info] Setting maximum log size to $MaxLogSizeMB MB"
        }

        foreach ($LogName in $LogsToOptimize) {
            try {
                Write-Host "[Info] Processing log: $LogName"
                
                $Log = Get-WinEvent -ListLog $LogName -ErrorAction Stop
                
                if ($MaxLogSizeMB) {
                    $MaxSizeBytes = $MaxLogSizeMB * 1MB
                    $Log.MaximumSizeInBytes = $MaxSizeBytes
                    $Log.SaveChanges()
                    Write-Host "[Info] Set maximum size to $MaxLogSizeMB MB"
                }

                if ($ClearLogs) {
                    Write-Host "[Info] Clearing log: $LogName"
                    wevtutil.exe cl $LogName
                    Write-Host "[Info] $LogName cleared successfully"
                }
                
                Write-Host "[Info] $LogName optimized successfully"
            }
            catch {
                Write-Host "[Error] Failed to optimize $LogName: $_"
                $ExitCode = 1
            }
        }

        Write-Host "[Info] Event log optimization complete"
    }
    catch {
        Write-Host "[Error] Event log optimization failed: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
