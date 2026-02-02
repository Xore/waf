<#
.SYNOPSIS
    NinjaRMM Script 19: Proactive Remediation Engine

.DESCRIPTION
    Executes automated fixes for common issues based on health scores
    and automation eligibility flags.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~60 seconds
    Timeout: 120 seconds
    Context: SYSTEM
    
    Fields Updated:
    - autoLastRemediationDate (DateTime)
    - autoLastRemediationAction (Text)
    - autoRemediationCount24h (Integer)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    $remediationActions = @()
    $actionCount = 0

    # Check if remediation is eligible
    $eligible = Ninja-Property-Get autoRemediationEligible
    if ($eligible -ne $true) {
        Write-Output "Device not eligible for automated remediation"
        exit 0
    }

    # Get health score to determine remediation priority
    $healthScore = Ninja-Property-Get opsHealthScore

    # Remediation 1: Clear temporary files if disk space low
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -lt 20) {
        Write-Output "Low disk space detected: $freeSpaceGB GB - clearing temp files"
        
        # Clear Windows temp
        Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        # Clear user temp
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        $remediationActions += "Cleared temp files (disk space: $freeSpaceGB GB)"
        $actionCount++
    }

    # Remediation 2: Restart Windows Update service if stuck
    $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    if ($wuService -and $wuService.Status -ne 'Running') {
        Write-Output "Windows Update service not running - restarting"
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        $remediationActions += "Restarted Windows Update service"
        $actionCount++
    }

    # Remediation 3: Clear DNS cache if network issues
    $networkScore = Ninja-Property-Get netConnectivityScore
    if ($networkScore -and $networkScore -lt 70) {
        Write-Output "Network connectivity issues detected - flushing DNS"
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        $remediationActions += "Flushed DNS cache (network score: $networkScore)"
        $actionCount++
    }

    # Remediation 4: Reset network adapter if persistent issues
    if ($networkScore -and $networkScore -lt 50) {
        Write-Output "Severe network issues - resetting network adapter"
        $adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1
        if ($adapter) {
            Restart-NetAdapter -Name $adapter.Name -ErrorAction SilentlyContinue
            $remediationActions += "Reset network adapter: $($adapter.Name)"
            $actionCount++
        }
    }

    # Update custom fields
    if ($actionCount -gt 0) {
        Ninja-Property-Set autoLastRemediationDate (Get-Date)
        Ninja-Property-Set autoLastRemediationAction ($remediationActions -join "; ")
        Ninja-Property-Set autoRemediationCount24h $actionCount
        
        Write-Output "Completed $actionCount remediation actions"
    } else {
        Write-Output "No remediation actions needed"
    }

} catch {
    Write-Output "Error: $_"
    exit 1
}
