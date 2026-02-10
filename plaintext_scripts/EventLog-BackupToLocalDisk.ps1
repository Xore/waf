#Requires -Version 5.1

<#
.SYNOPSIS
    Exports specified event logs to a compressed zip file.

.DESCRIPTION
    This script exports Windows event logs to .evtx files and compresses them into a zip archive.
    Supports date range filtering and automatic cleanup of temporary files.
    
    Event log backups are essential for forensic analysis, compliance requirements, and
    troubleshooting. This script provides flexible filtering options to export specific time
    ranges and automatically compresses files for efficient storage.

.PARAMETER EventLogs
    Comma-separated list of event log names to export.
    Examples: "System,Security,Application", "*Microsoft-Windows-*"
    Default: System,Application,Security

.PARAMETER BackupDestination
    Path to the folder where the backup zip file will be saved.
    The folder will be created if it does not exist.
    Default: C:\Temp\EventLogBackup

.PARAMETER StartDate
    Optional start date for filtering events (format: yyyy-MM-dd or full datetime).
    Events from this date forward will be included in the backup.

.PARAMETER EndDate
    Optional end date for filtering events (format: yyyy-MM-dd or full datetime).
    Events up to this date will be included in the backup.

.EXAMPLE
    .\EventLog-BackupToLocalDisk.ps1 -EventLogs "System,Security" -BackupDestination "C:\Backup"
    
    Exports System and Security event logs to C:\Backup folder.

.EXAMPLE
    .\EventLog-BackupToLocalDisk.ps1 -EventLogs "System" -BackupDestination "C:\Backup" -StartDate "2026-02-01" -EndDate "2026-02-10"
    
    Exports System event log for date range February 1-10, 2026.

.EXAMPLE
    .\EventLog-BackupToLocalDisk.ps1 -EventLogs "*Microsoft-Windows-PowerShell*" -BackupDestination "C:\Logs"
    
    Exports all PowerShell-related event logs using wildcard matching.

.OUTPUTS
    Creates a compressed .zip file containing the exported event logs.
    Temporary .evtx files are removed after successful compression.

.NOTES
    File Name      : EventLog-BackupToLocalDisk.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
.COMPONENT
    Event Log Management
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-winevent
    
.FUNCTIONALITY
    - Exports Windows event logs to .evtx format
    - Supports date range filtering for targeted exports
    - Compresses exported logs into zip archive
    - Automatic cleanup of temporary files
    - Validates administrator privileges
    - Handles multiple event logs in single operation
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$EventLogs = "System,Application,Security",
    
    [Parameter()]
    [string]$BackupDestination = "C:\Temp\EventLogBackup",
    
    [Parameter()]
    [DateTime]$StartDate,
    
    [Parameter()]
    [DateTime]$EndDate
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
        if ($env:eventLogs -and $env:eventLogs -notlike "null") {
            $EventLogs = $env:eventLogs
        }
        if ($env:backupDestination -and $env:backupDestination -notlike "null") {
            $BackupDestination = $env:backupDestination
        }
        if ($env:startDate -and $env:startDate -notlike "null") {
            $StartDate = $env:startDate
        }
        if ($env:endDate -and $env:endDate -notlike "null") {
            $EndDate = $env:endDate
        }

        # Parse event log names
        $EventLogNames = $EventLogs -split "," | ForEach-Object { $_.Trim() }
        Write-Log "Event logs to export: $($EventLogNames -join ', ')"

        # Validate and parse dates
        if ($StartDate) {
            try {
                $StartDate = Get-Date -Date $StartDate
                $StartDate = $StartDate.ToUniversalTime()
                Write-Log "Start date: $(Get-Date -Date $StartDate -Format 'yyyy-MM-dd HH:mm:ss UTC')"
            }
            catch {
                Write-Log "Invalid start date format: $StartDate" -Level 'ERROR'
                $script:ExitCode = 1
                return
            }
        }
        
        if ($EndDate) {
            try {
                $EndDate = Get-Date -Date $EndDate
                $EndDate = $EndDate.ToUniversalTime()
                Write-Log "End date: $(Get-Date -Date $EndDate -Format 'yyyy-MM-dd HH:mm:ss UTC')"
            }
            catch {
                Write-Log "Invalid end date format: $EndDate" -Level 'ERROR'
                $script:ExitCode = 1
                return
            }
        }

        # Flip dates if start is after end
        if ($StartDate -and $EndDate -and $StartDate -gt $EndDate) {
            $TempDate = $StartDate
            $StartDate = $EndDate
            $EndDate = $TempDate
            Write-Log "Start date was after end date - dates have been swapped" -Level 'WARNING'
        }

        # Validate/create backup destination
        if (Test-Path -Path $BackupDestination -PathType Container -ErrorAction SilentlyContinue) {
            $BackupDestination = Get-Item -Path $BackupDestination
            Write-Log "Using existing backup destination: $BackupDestination"
        }
        else {
            try {
                $BackupDestination = New-Item -Path $BackupDestination -ItemType Directory -Force -ErrorAction Stop
                Write-Log "Created backup destination: $BackupDestination"
            }
            catch {
                Write-Log "Failed to create backup destination: $_" -Level 'ERROR'
                $script:ExitCode = 1
                return
            }
        }

        # Get available event logs matching filter
        Write-Log "Enumerating available event logs..."
        $AvailableLogs = wevtutil.exe el | Where-Object {
            $LogName = $_
            $EventLogNames | ForEach-Object {
                if ($LogName -like $_) { return $true }
            }
        }

        if ($AvailableLogs.Count -eq 0) {
            Write-Log "No event logs found matching: $($EventLogNames -join ', ')" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        Write-Log "Found $($AvailableLogs.Count) matching event log(s)"

        # Export event logs
        Write-Log "Exporting event logs..."
        $ExportedFiles = @()
        
        foreach ($LogName in $AvailableLogs) {
            $SafeLogName = $LogName -replace '[\\/:*?"<>|]', '-'
            $EventLogPath = Join-Path -Path $BackupDestination -ChildPath "$SafeLogName.evtx"
            
            try {
                # Build XPath query for date filtering
                $Query = if ($StartDate -and $EndDate) {
                    $StartStr = Get-Date -Date $StartDate -UFormat "%Y-%m-%dT%H:%M:%S"
                    $EndStr = Get-Date -Date $EndDate -UFormat "%Y-%m-%dT%H:%M:%S"
                    "*[System[TimeCreated[@SystemTime>='$StartStr' and @SystemTime<='$EndStr']]]"
                }
                elseif ($StartDate) {
                    $StartStr = Get-Date -Date $StartDate -UFormat "%Y-%m-%dT%H:%M:%S"
                    "*[System[TimeCreated[@SystemTime>='$StartStr']]]"
                }
                elseif ($EndDate) {
                    $EndStr = Get-Date -Date $EndDate -UFormat "%Y-%m-%dT%H:%M:%S"
                    "*[System[TimeCreated[@SystemTime<='$EndStr']]]"
                }
                else {
                    "*[System[TimeCreated[@SystemTime>='1970-01-01T00:00:00']]]"
                }

                # Export using wevtutil
                $null = wevtutil.exe epl "$LogName" "$EventLogPath" /ow:true /query:"$Query" 2>&1

                if (Test-Path -Path $EventLogPath -ErrorAction SilentlyContinue) {
                    $EventCount = (Get-WinEvent -Path $EventLogPath -ErrorAction SilentlyContinue | Measure-Object).Count
                    
                    if ($EventCount -and $EventCount -gt 0) {
                        Write-Log "Exported $EventCount event(s) from $LogName"
                        $ExportedFiles += $EventLogPath
                    }
                    else {
                        Write-Log "No events found in $LogName for specified date range" -Level 'WARNING'
                        Remove-Item -Path $EventLogPath -Force -ErrorAction SilentlyContinue
                    }
                }
                else {
                    Write-Log "Failed to export $LogName" -Level 'WARNING'
                }
            }
            catch {
                Write-Log "Error exporting $LogName: $_" -Level 'WARNING'
                continue
            }
        }

        if ($ExportedFiles.Count -eq 0) {
            Write-Log "No event logs were successfully exported" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        Write-Log "Successfully exported $($ExportedFiles.Count) event log(s)"

        # Compress exported files
        Write-Log "Compressing event logs..."

        $Timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm'
        $ZipFileName = "EventLog-Backup-$Timestamp.zip"
        $ZipPath = Join-Path -Path $BackupDestination -ChildPath $ZipFileName

        # Wait for file handles to be released (wevtutil may still have files open)
        $CompressSuccess = $false
        $RetryCount = 0
        $MaxRetries = 60
        
        while (-not $CompressSuccess -and $RetryCount -lt $MaxRetries) {
            try {
                Compress-Archive -Path $ExportedFiles -DestinationPath $ZipPath -Update -ErrorAction Stop
                $CompressSuccess = $true
                break
            }
            catch {
                if ($RetryCount -eq 0) {
                    Write-Log "Waiting for file handles to be released..." -Level 'WARNING'
                }
                Start-Sleep -Seconds 1
                $RetryCount++
            }
        }

        if (-not $CompressSuccess) {
            Write-Log "Failed to compress event logs after $MaxRetries seconds" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        $ZipSize = (Get-Item -Path $ZipPath).Length / 1MB
        Write-Log "Event logs compressed successfully: $ZipPath ($([math]::Round($ZipSize, 2)) MB)"

        # Clean up temporary files
        Write-Log "Removing temporary files..."
        $RemovedCount = 0
        
        foreach ($FilePath in $ExportedFiles) {
            try {
                Remove-Item -Path $FilePath -Force -ErrorAction Stop
                $RemovedCount++
            }
            catch {
                Write-Log "Failed to remove temporary file: $FilePath" -Level 'WARNING'
            }
        }
        
        Write-Log "Removed $RemovedCount temporary file(s)"
        Write-Log "Event log backup completed successfully"
    }
    catch {
        Write-Log "Unexpected error during event log backup: $_" -Level 'ERROR'
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
        Write-Output "Script: EventLog-BackupToLocalDisk.ps1"
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
