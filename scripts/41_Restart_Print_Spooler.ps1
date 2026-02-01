<#
.SYNOPSIS
    NinjaRMM Script 41: Restart Print Spooler

.DESCRIPTION
    Restart Print Spooler service when print jobs are stuck.
    Emergency service restart automation.

.NOTES
    Frequency: On-demand / Alert-triggered
    Runtime: 5-10 seconds
    Timeout: 30 seconds
    Context: SYSTEM
    
    Fields Updated:
    - svcSpoolerLastRestart (DateTime)
    - svcSpoolerStatus (Text)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    Write-Output "Restarting Print Spooler service..."

    $service = Get-Service -Name Spooler -ErrorAction Stop
    $initialStatus = $service.Status

    if ($service.Status -eq "Running") {
        Stop-Service -Name Spooler -Force -ErrorAction Stop
        Start-Sleep -Seconds 3
    }

    Start-Service -Name Spooler -ErrorAction Stop
    Start-Sleep -Seconds 2

    $service = Get-Service -Name Spooler
    if ($service.Status -eq "Running") {
        Write-Output "SUCCESS: Print Spooler is running"
        Ninja-Property-Set svcSpoolerLastRestart (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Ninja-Property-Set svcSpoolerStatus "Running"
        exit 0
    } else {
        throw "Service failed to start"
    }

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set svcSpoolerStatus "Failed"
    exit 1
}
