<#
.SYNOPSIS
    NinjaRMM Script 31: Endpoint Detection and Response Telemetry

.DESCRIPTION
    Monitors antivirus/EDR status, threat detection, and quarantine actions.
    Tracks real-time protection and scan results.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secEDREnabled (Checkbox)
    - secRealtimeProtectionOn (Checkbox)
    - secThreatsDetected24h (Integer)
    - secQuarantineItemCount (Integer)
    - secLastScanDate (DateTime)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    # Get Windows Defender status
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue

    if ($defenderStatus) {
        # Check if real-time protection is enabled
        $realtimeEnabled = $defenderStatus.RealTimeProtectionEnabled
        Ninja-Property-Set secRealtimeProtectionOn $realtimeEnabled

        # Check if any AV/EDR is enabled
        $edrEnabled = $defenderStatus.AntivirusEnabled -or $defenderStatus.RealTimeProtectionEnabled
        Ninja-Property-Set secEDREnabled $edrEnabled

        # Get last scan date
        $lastQuickScan = $defenderStatus.QuickScanEndTime
        $lastFullScan = $defenderStatus.FullScanEndTime

        $lastScan = if ($lastQuickScan -gt $lastFullScan) { $lastQuickScan } else { $lastFullScan }
        if ($lastScan) {
            Ninja-Property-Set secLastScanDate $lastScan
        }

        # Get threat history
        $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
        $recentThreats = $threats | Where-Object {
            $_.InitialDetectionTime -gt (Get-Date).AddHours(-24)
        }

        $threatCount = if ($recentThreats) { $recentThreats.Count } else { 0 }
        Ninja-Property-Set secThreatsDetected24h $threatCount

        # Get quarantine items
        $quarantine = Get-MpThreat -ErrorAction SilentlyContinue
        $quarantineCount = if ($quarantine) { $quarantine.Count } else { 0 }
        Ninja-Property-Set secQuarantineItemCount $quarantineCount

        Write-Output "EDR: $edrEnabled | Realtime: $realtimeEnabled | Threats: $threatCount | Quarantine: $quarantineCount"
    } else {
        Write-Output "Windows Defender status not available"
        Ninja-Property-Set secEDREnabled $false
        Ninja-Property-Set secRealtimeProtectionOn $false
    }

} catch {
    Write-Output "Error: $_"
    exit 1
}
