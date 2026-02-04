<#
.SYNOPSIS
    Endpoint Detection and Response Telemetry - Antivirus and Threat Monitoring

.DESCRIPTION
    Monitors endpoint security status including antivirus, EDR (Endpoint Detection and Response),
    and real-time threat protection capabilities. Tracks Windows Defender (Microsoft Defender
    Antivirus) configuration, protection status, threat detection events, and quarantine actions.
    
    Provides continuous monitoring of critical security controls including:
    - Real-time protection status (on-access scanning)
    - Antivirus/EDR engine enabled state
    - Recent threat detection events (24-hour window)
    - Quarantined malware count
    - Last scan timestamp (quick or full scan)
    
    Enables security operations teams to identify endpoints with disabled protection, detect
    active threats requiring remediation, and verify regular scanning cadence. Critical for
    maintaining baseline security posture and compliance requirements.
    
    Uses native Get-MpComputerStatus and Get-MpThreatDetection cmdlets to query Microsoft
    Defender status without requiring third-party agents or services.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secEDREnabled (Checkbox: true if antivirus or real-time protection enabled)
    - secRealtimeProtectionOn (Checkbox: true if real-time scanning active)
    - secThreatsDetected24h (Integer: threats detected in last 24 hours)
    - secQuarantineItemCount (Integer: total items in quarantine)
    - secLastScanDate (DateTime: timestamp of most recent scan)
    
    Dependencies:
    - Windows Defender cmdlets (Get-MpComputerStatus, Get-MpThreatDetection, Get-MpThreat)
    - Windows 10/11 or Windows Server 2016+
    - Microsoft Defender Antivirus installed and licensed
    
    Security Considerations:
    - Disabled real-time protection indicates compromised security posture
    - High threat counts may indicate active infection or attack
    - Outdated scan dates suggest scanning policy failures
    - Quarantine count trends help identify threat patterns
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Endpoint Detection and Response Telemetry (v4.0)..."
    
    # Query Windows Defender status
    Write-Output "INFO: Querying Microsoft Defender status..."
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue

    if ($defenderStatus) {
        Write-Output "INFO: Microsoft Defender is installed and responding"
        
        # Check if real-time protection is enabled
        $realtimeEnabled = $defenderStatus.RealTimeProtectionEnabled
        if ($realtimeEnabled) {
            Write-Output "INFO: Real-time protection is ENABLED (good)"
        } else {
            Write-Output "ALERT: Real-time protection is DISABLED (security risk)"
        }
        Ninja-Property-Set secRealtimeProtectionOn $realtimeEnabled

        # Check if any AV/EDR is enabled
        $edrEnabled = $defenderStatus.AntivirusEnabled -or $defenderStatus.RealTimeProtectionEnabled
        if ($edrEnabled) {
            Write-Output "INFO: Antivirus/EDR protection is ACTIVE"
        } else {
            Write-Output "ALERT: Antivirus/EDR protection is INACTIVE (critical security risk)"
        }
        Ninja-Property-Set secEDREnabled $edrEnabled

        # Get last scan date (use most recent of quick or full scan)
        $lastQuickScan = $defenderStatus.QuickScanEndTime
        $lastFullScan = $defenderStatus.FullScanEndTime

        $lastScan = if ($lastQuickScan -gt $lastFullScan) { $lastQuickScan } else { $lastFullScan }
        
        if ($lastScan) {
            $daysSinceLastScan = ((Get-Date) - $lastScan).Days
            Write-Output "INFO: Last scan: $($lastScan.ToString('yyyy-MM-dd HH:mm')) ($daysSinceLastScan days ago)"
            
            if ($daysSinceLastScan -gt 7) {
                Write-Output "WARNING: Last scan is over 7 days old"
            }
            
            Ninja-Property-Set secLastScanDate $lastScan
        } else {
            Write-Output "WARNING: No scan history found"
        }

        # Get threat detection history (last 24 hours)
        Write-Output "INFO: Checking threat detection history..."
        try {
            $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
            $recentThreats = $threats | Where-Object {
                $_.InitialDetectionTime -gt (Get-Date).AddHours(-24)
            }

            $threatCount = if ($recentThreats) { $recentThreats.Count } else { 0 }
            
            if ($threatCount -gt 0) {
                Write-Output "ALERT: Detected $threatCount threat(s) in last 24 hours"
                $recentThreats | Select-Object -First 5 | ForEach-Object {
                    Write-Output "  - $($_.ThreatName) detected at $($_.InitialDetectionTime.ToString('yyyy-MM-dd HH:mm'))"
                }
            } else {
                Write-Output "INFO: No threats detected in last 24 hours (good)"
            }
            
            Ninja-Property-Set secThreatsDetected24h $threatCount
        } catch {
            Write-Output "WARNING: Failed to query threat detection history: $_"
            Ninja-Property-Set secThreatsDetected24h 0
        }

        # Get quarantine item count
        Write-Output "INFO: Checking quarantine..."
        try {
            $quarantine = Get-MpThreat -ErrorAction SilentlyContinue
            $quarantineCount = if ($quarantine) { $quarantine.Count } else { 0 }
            
            if ($quarantineCount -gt 0) {
                Write-Output "INFO: Quarantine contains $quarantineCount item(s)"
            } else {
                Write-Output "INFO: Quarantine is empty (good)"
            }
            
            Ninja-Property-Set secQuarantineItemCount $quarantineCount
        } catch {
            Write-Output "WARNING: Failed to query quarantine: $_"
            Ninja-Property-Set secQuarantineItemCount 0
        }

        Write-Output "SUCCESS: EDR telemetry complete"
        Write-Output "SUMMARY: EDR: $edrEnabled | Realtime: $realtimeEnabled | Threats(24h): $threatCount | Quarantine: $quarantineCount"
        
        # Determine security posture
        if (-not $realtimeEnabled -or -not $edrEnabled) {
            Write-Output "SECURITY POSTURE: CRITICAL - Protection disabled"
        } elseif ($threatCount -gt 0) {
            Write-Output "SECURITY POSTURE: WARNING - Active threats detected"
        } else {
            Write-Output "SECURITY POSTURE: GOOD - Protection active, no recent threats"
        }
        
    } else {
        Write-Output "WARNING: Windows Defender status not available (service may be disabled or unsupported)"
        Ninja-Property-Set secEDREnabled $false
        Ninja-Property-Set secRealtimeProtectionOn $false
        Ninja-Property-Set secThreatsDetected24h 0
        Ninja-Property-Set secQuarantineItemCount 0
    }
    
    exit 0

} catch {
    Write-Output "ERROR: Endpoint Detection and Response Telemetry failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
