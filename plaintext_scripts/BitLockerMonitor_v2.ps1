<#
.SYNOPSIS
    NinjaRMM Script 17: BitLocker Monitor

.DESCRIPTION
    Monitors BitLocker encryption status for all volumes.
    Part of Infrastructure Monitoring suite - Security.

.NOTES
    Frequency: Daily
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - bitlockerEnabled (Checkbox)
    - bitlockerVolumeCount (Integer)
    - bitlockerProtectedVolumes (Integer)
    - bitlockerHealthStatus (Text)
    
    Framework Version: 4.0
    Last Updated: February 3, 2026
#>

param()

try {
    $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue

    if (-not $volumes) {
        Ninja-Property-Set bitlockerEnabled $false
        Write-Output "BitLocker not available"
        exit 0
    }

    Ninja-Property-Set bitlockerEnabled $true

    $volumeCount = $volumes.Count
    $protectedCount = ($volumes | Where-Object { $_.ProtectionStatus -eq 'On' }).Count

    Ninja-Property-Set bitlockerVolumeCount $volumeCount
    Ninja-Property-Set bitlockerProtectedVolumes $protectedCount

    if ($protectedCount -eq $volumeCount) {
        $health = "Healthy"
    } elseif ($protectedCount -gt 0) {
        $health = "Warning"
    } else {
        $health = "Critical"
    }

    Ninja-Property-Set bitlockerHealthStatus $health

    Write-Output "BitLocker Health: $health | Protected: $protectedCount/$volumeCount volumes"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set bitlockerHealthStatus "Unknown"
    exit 1
}
