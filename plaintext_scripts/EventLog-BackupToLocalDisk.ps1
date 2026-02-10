#Requires -Version 5.1

<#
.SYNOPSIS
    Exports specified event logs to a compressed zip file.

.DESCRIPTION
    This script exports Windows event logs to .evtx files and compresses them into a zip archive.
    Supports date range filtering and automatic cleanup of temporary files.

.PARAMETER EventLogs
    Comma-separated list of event log names to export (e.g., "System,Security,Application").

.PARAMETER BackupDestination
    Path to the folder where the backup zip file will be saved.

.PARAMETER StartDate
    Optional start date for filtering events (format: yyyy-MM-dd).

.PARAMETER EndDate
    Optional end date for filtering events (format: yyyy-MM-dd).

.EXAMPLE
    .\EventLog-BackupToLocalDisk.ps1 -EventLogs "System,Security" -BackupDestination "C:\Temp\EventLogs\"

    Exports System and Security event logs to C:\Temp\EventLogs\

.EXAMPLE
    .\EventLog-BackupToLocalDisk.ps1 -EventLogs "System" -BackupDestination "C:\Backup" -StartDate "2026-02-01" -EndDate "2026-02-10"

    Exports System event log for date range February 1-10, 2026.

.OUTPUTS
    Creates a compressed .zip file containing the exported event logs.

.NOTES
    File Name      : EventLog-BackupToLocalDisk.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$EventLogs,
    
    [Parameter()]
    [String]$BackupDestination,
    
    [Parameter()]
    [DateTime]$StartDate,
    
    [Parameter()]
    [DateTime]$EndDate
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $ExitCode = 0
    
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

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

process {
    try {
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. Please run with Administrator privileges." -Level ERROR
            $ExitCode = 1
            return
        }

        if ($env:eventLogs -and $env:eventLogs -notlike "null") {
            $EventLogs = $env:eventLogs
        }
        
        $EventLogNames = $EventLogs -split "," | ForEach-Object { $_.Trim() }
        
        if ($env:backupDestination -and $env:backupDestination -notlike "null") {
            $BackupDestination = $env:backupDestination
        }
        if ($env:startDate -and $env:startDate -notlike "null") {
            $StartDate = $env:startDate
        }
        if ($env:endDate -and $env:endDate -notlike "null") {
            $EndDate = $env:endDate
        }

        if ($StartDate) {
            try {
                $StartDate = Get-Date -Date $StartDate
            }
            catch {
                Write-Log "The specified start date is not a valid date." -Level ERROR
                $ExitCode = 1
                return
            }
        }
        
        if ($EndDate) {
            try {
                $EndDate = Get-Date -Date $EndDate
            }
            catch {
                Write-Log "The specified end date is not a valid date." -Level ERROR
                $ExitCode = 1
                return
            }
        }

        if (Test-Path -Path $BackupDestination -PathType Container -ErrorAction SilentlyContinue) {
            $BackupDestination = Get-Item -Path $BackupDestination
        }
        else {
            try {
                $BackupDestination = New-Item -Path $BackupDestination -ItemType Directory -ErrorAction Stop
            }
            catch {
                Write-Log "The specified backup destination is not a valid path to a folder." -Level ERROR
                $ExitCode = 1
                return
            }
        }

        Write-Log "Today is $(Get-Date -Format yyyy-MM-dd-HH-mm)"

        $AvailableLogs = wevtutil.exe el | ForEach-Object {
            if ($EventLogNames -and ($EventLogNames -contains $_ -or $EventLogNames -like $_)) { $_ }
        }

        if ($AvailableLogs.Count -eq 0) {
            Write-Log "No Event Logs matching: $EventLogNames" -Level ERROR
            $ExitCode = 1
            return
        }

        Write-Log "EventLogs are $EventLogNames"
        Write-Log "Backup Destination is $BackupDestination"

        if ($StartDate) {
            $StartDate = $StartDate.ToUniversalTime()
            Write-Log "Start Date is $(Get-Date -Date $StartDate -Format yyyy-MM-dd-HH-mm)"
        }
        else {
            Write-Log "Start Date is null"
        }
        
        if ($EndDate) {
            $EndDate = $EndDate.ToUniversalTime()
            Write-Log "End Date is $(Get-Date -Date $EndDate -Format yyyy-MM-dd-HH-mm)"
        }
        else {
            Write-Log "End Date is null"
        }

        if ($StartDate -and $EndDate -and $StartDate -gt $EndDate) {
            $OldEndDate = $EndDate
            $OldStartDate = $StartDate
            $EndDate = $OldStartDate
            $StartDate = $OldEndDate
            Write-Log "Start Date is after the end date. Flipping dates." -Level WARNING
        }

        Write-Log "Exporting Event Logs..."
        $ExportedFiles = @()
        
        foreach ($EventLog in $EventLogNames) {
            $EventLogPath = Join-Path -Path $BackupDestination -ChildPath "$EventLog.evtx"
            try {
                $Query = if ($StartDate -and $EndDate) {
                    "*[System[TimeCreated[@SystemTime>='$(Get-Date -Date $StartDate -UFormat "%Y-%m-%dT%H:%M:%S")' and @SystemTime<='$(Get-Date -Date $EndDate -UFormat "%Y-%m-%dT%H:%M:%S")']]]" 
                }
                elseif ($StartDate) {
                    "*[System[TimeCreated[@SystemTime>='$(Get-Date -Date $StartDate -UFormat "%Y-%m-%dT%H:%M:%S")']]]" 
                }
                elseif ($EndDate) {
                    "*[System[TimeCreated[@SystemTime<='$(Get-Date -Date $EndDate -UFormat "%Y-%m-%dT%H:%M:%S")']]]" 
                }
                else {
                    "*[System[TimeCreated[@SystemTime>='1970-01-01T00:00:00']]]" 
                }

                wevtutil.exe epl "$EventLog" "$EventLogPath" /ow:true /query:"$Query" 2>$null

                if (Test-Path -Path $EventLogPath -ErrorAction SilentlyContinue) {
                    $EventCount = (Get-WinEvent -Path $EventLogPath -ErrorAction SilentlyContinue).Count
                    if ($EventCount -and $EventCount -gt 0) {
                        Write-Log "Found $EventCount events from $EventLog"
                        Write-Log "Exported Event Logs to $EventLogPath"
                        $ExportedFiles += $EventLogPath
                    }
                    else {
                        Write-Log "No events found in $EventLog" -Level WARNING
                    }
                }
                else {
                    throw "Export failed"
                }
            }
            catch {
                Write-Log "Failed to export event logs $EventLog" -Level ERROR
                continue
            }
        }

        if ($ExportedFiles.Count -eq 0) {
            Write-Log "No event logs were exported." -Level ERROR
            $ExitCode = 1
            return
        }

        Write-Log "Compressing Event Logs..."

        $Destination = Join-Path -Path $BackupDestination -ChildPath (
            "Backup-" + ($EventLogNames -join '-') + "-" + (Get-Date -Format yyyy-MM-dd-HH-mm) + ".zip"
        )

        $CompressArchiveSplat = @{
            Path            = $ExportedFiles
            DestinationPath = $Destination
            Update          = $true
        }

        $CompressError = $true
        $ErrorCount = 0
        $TimeOut = 120
        
        while ($CompressError -and $ErrorCount -lt $TimeOut) {
            try {
                Compress-Archive @CompressArchiveSplat -ErrorAction Stop
                $CompressError = $false
                break
            }
            catch {
                $CompressError = $true
                if ($ErrorCount -eq 0) {
                    Write-Log "Waiting for wevtutil.exe to close file." -Level WARNING
                }
                Start-Sleep -Seconds 1
                $ErrorCount++
            }
        }

        if ($CompressError) {
            Write-Log "Failed to compress Event Logs (timed out)." -Level ERROR
            $ExitCode = 1
        }
        else {
            Write-Log "Compressed Event Logs to $Destination"
        }

        if (Test-Path -Path $Destination -ErrorAction SilentlyContinue) {
            Write-Log "Removing Temporary Event Logs..."
            foreach ($EventLogPath in $ExportedFiles) {
                try {
                    Remove-Item -Path $EventLogPath -Force -ErrorAction Stop
                    Write-Log "Removed Temporary Event Logs: $EventLogPath"
                }
                catch {
                    Write-Log "Failed to remove temporary file: $EventLogPath" -Level WARNING
                }
            }
        }
        else {
            Write-Log "Renaming Event Logs..."
            foreach ($EventLogPath in $ExportedFiles) {
                if (Test-Path -Path $EventLogPath -ErrorAction SilentlyContinue) {
                    try {
                        $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($EventLogPath)
                        $NewName = "$BaseName-$(Get-Date -Format yyyy-MM-dd-HH-mm).evtx"
                        $NewPath = Rename-Item -Path $EventLogPath -NewName $NewName -PassThru -ErrorAction Stop
                        Write-Log "Event Logs saved to: $NewPath"
                    }
                    catch {
                        Write-Log "Event Logs saved to: $EventLogPath"
                    }
                }
            }
        }
    }
    catch {
        Write-Log "An unexpected error occurred: $_" -Level ERROR
        $ExitCode = 1
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
        exit $ExitCode
    }
}
