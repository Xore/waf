#Requires -Version 5.1

<#
.SYNOPSIS
    Monitors SSD wear levels and alerts when thresholds are exceeded.

.DESCRIPTION
    Conditional script that monitors SSD drive health by checking wear levels and write errors.
    Uses Windows Storage Management API to query storage reliability counters and detect
    drives that may be failing or have reached their estimated wear limit.
    
    A wear percentage of 100% indicates that the estimated wear level has been reached.
    The script can be used as a monitoring condition to alert when SSDs approach or exceed
    configured wear thresholds.
    
    Note: Some drives don't report all needed details to the OS. This can be caused by:
    - RAID controllers that abstract drive information
    - BIOS settings that disable SMART reporting
    - Drive firmware that doesn't expose wear leveling data

.PARAMETER WearLevelPercentMax
    The maximum estimated wear level percentage before failing the check.
    Default: 80%

.EXAMPLE
    .\Hardware-SSDWearHealthAlert.ps1

    [2026-02-10 16:35:00] [INFO] Checking SSD wear levels
    [2026-02-10 16:35:00] [INFO] No disks were found with wear level above 80%

.EXAMPLE
    .\Hardware-SSDWearHealthAlert.ps1 -WearLevelPercentMax 90

    Fails the check if any SSD is found to have used 90% or more of its estimated wear leveling.

.OUTPUTS
    None. Drive health information is written to console.

.NOTES
    File Name      : Hardware-SSDWearHealthAlert.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.1: Updated calculated name
    - 1.0: Initial release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [int]$WearLevelPercentMax = 80
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

    if ($env:WearLevelPercentMax -and $env:WearLevelPercentMax -notlike "null") {
        $WearLevelPercentMax = [int]$env:WearLevelPercentMax
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Write-UnhealthyDisk {
        param([PSObject[]]$Disks)
        process {
            $Disks | ForEach-Object {
                try {
                    $PhysicalDisk = Get-PhysicalDisk -DeviceNumber $_ | Select-Object FriendlyName, DeviceId, MediaType, OperationalStatus, HealthStatus
                    $StorageReliabilityCounters = Get-PhysicalDisk -DeviceNumber $_ | Get-StorageReliabilityCounter | Select-Object Temperature, WriteErrorsTotal, Wear
                    
                    Write-Log "Drive: $($PhysicalDisk.FriendlyName)" -Level WARNING
                    Write-Log "  DeviceId: $($PhysicalDisk.DeviceId) | Type: $($PhysicalDisk.MediaType) | Status: $($PhysicalDisk.OperationalStatus) | Health: $($PhysicalDisk.HealthStatus)" -Level WARNING
                    Write-Log "  Temp: $($StorageReliabilityCounters.Temperature) C | Total Write Errors: $($StorageReliabilityCounters.WriteErrorsTotal) | Wear: $($StorageReliabilityCounters.Wear)%" -Level WARNING
                    
                    Write-Output 1
                }
                catch {
                    Write-Output 0
                }
            } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        }
    }
}

process {
    try {
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. Please run with Administrator privileges." -Level ERROR
            $ExitCode = 1
            return
        }

        Write-Log "Checking SSD wear levels (threshold: $WearLevelPercentMax%)"

        $Disks = Get-PhysicalDisk
        
        $UnhealthySSDDisks = $Disks | Where-Object { 
            $_.MediaType -like "SSD" -and $_.PhysicalLocation -notlike "*.vhd*" 
        } | Get-StorageReliabilityCounter | Where-Object {
            (
                $null -ne $_.WriteErrorsTotal -and
                $_.WriteErrorsTotal -ge 1
            ) -or
            (
                $null -ne $_.Wear -and
                $_.Wear -ge $WearLevelPercentMax
            )
        }

        $DeviceIds = $UnhealthySSDDisks | Sort-Object -Property DeviceId -Unique | Select-Object -ExpandProperty DeviceId
        $DriveCount = Write-UnhealthyDisk -Disks $DeviceIds

        if ($DeviceIds.Count -and $DriveCount) {
            Write-Log "Found $($DeviceIds.Count) disk(s) with wear level above $WearLevelPercentMax%" -Level WARNING
            $ExitCode = 1
        }
        else {
            Write-Log "No disks were found with wear level above $WearLevelPercentMax%"
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
