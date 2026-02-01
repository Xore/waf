<#
.SYNOPSIS
    NinjaRMM Script 42: Restart Windows Update

.DESCRIPTION
    Restart Windows Update service when updates fail.
    Emergency service restart automation.

.NOTES
    Frequency: On-demand / Alert-triggered
    Runtime: 5-10 seconds
    Timeout: 30 seconds
    Context: SYSTEM
    
    Services: wuauserv, BITS
    
    Fields Updated:
    - svcWULastRestart (DateTime)
    - svcWUStatus (Text)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    Write-Output "Restarting Windows Update service..."

    Stop-Service -Name wuauserv -Force -ErrorAction Stop
    Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    Start-Service -Name wuauserv -ErrorAction Stop
    Start-Service -Name BITS -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $service = Get-Service -Name wuauserv
    if ($service.Status -eq "Running") {
        Write-Output "SUCCESS: Windows Update service is running"
        Ninja-Property-Set svcWULastRestart (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Ninja-Property-Set svcWUStatus "Running"
        exit 0
    } else {
        throw "Windows Update failed to start"
    }

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set svcWUStatus "Failed"
    exit 1
}
