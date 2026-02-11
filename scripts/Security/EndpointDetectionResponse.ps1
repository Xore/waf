#Requires -Version 5.1

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
    - Recent threat detection events (configurable time window)
    - Quarantined malware count
    - Last scan timestamp (quick or full scan)
    - Days since last scan with threshold alerting
    
    Enables security operations teams to identify endpoints with disabled protection, detect
    active threats requiring remediation, and verify regular scanning cadence. Critical for
    maintaining baseline security posture and compliance requirements.
    
    Uses native Get-MpComputerStatus and Get-MpThreatDetection cmdlets to query Microsoft
    Defender status without requiring third-party agents or services.

.PARAMETER EDRField
    NinjaRMM custom field name to store EDR enabled status.
    Default: secEDREnabled

.PARAMETER RealtimeProtectionField
    NinjaRMM custom field name to store real-time protection status.
    Default: secRealtimeProtectionOn

.PARAMETER ThreatsDetectedField
    NinjaRMM custom field name to store threat count in time window.
    Default: secThreatsDetected24h

.PARAMETER QuarantineField
    NinjaRMM custom field name to store quarantine item count.
    Default: secQuarantineItemCount

.PARAMETER LastScanField
    NinjaRMM custom field name to store last scan timestamp.
    Default: secLastScanDate

.PARAMETER ThreatWindowHours
    Number of hours to look back for threat detections.
    Default: 24

.PARAMETER ScanAgeThresholdDays
    Number of days threshold to alert on stale scan data.
    Default: 7

.EXAMPLE
    .\EndpointDetectionResponse.ps1

    Runs EDR telemetry with default settings (24-hour threat window, 7-day scan threshold).

.EXAMPLE
    .\EndpointDetectionResponse.ps1 -ThreatWindowHours 48 -ScanAgeThresholdDays 14

    Runs with 48-hour threat window and 14-day scan age threshold.

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : EndpointDetectionResponse.ps1
    Prerequisite   : PowerShell 5.1 or higher, Admin privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    Frequency      : Every 4 hours
    Runtime        : Approximately 20 seconds
    Timeout        : 60 seconds
    Context        : SYSTEM
    
    Change Log:
    - 3.0.0: V3 migration with standardized logging, error handling, and parameterized thresholds
    - 4.0: Previous version with EDR monitoring
    
    Fields Updated:
    - secEDREnabled: Checkbox true if antivirus or real-time protection enabled
    - secRealtimeProtectionOn: Checkbox true if real-time scanning active
    - secThreatsDetected24h: Integer threats detected in time window
    - secQuarantineItemCount: Integer total items in quarantine
    - secLastScanDate: DateTime timestamp of most recent scan
    
    Dependencies:
    - Windows Defender cmdlets (Get-MpComputerStatus, Get-MpThreatDetection, Get-MpThreat)
    - Windows 10/11 or Windows Server 2016+
    - Microsoft Defender Antivirus installed and licensed
    
    Security Considerations:
    - Disabled real-time protection indicates compromised security posture
    - High threat counts may indicate active infection or attack
    - Outdated scan dates suggest scanning policy failures
    - Quarantine count trends help identify threat patterns
    
    Security Posture Classification:
    - CRITICAL: Real-time protection or EDR disabled
    - WARNING: Active threats detected in time window
    - GOOD: Protection active with no recent threats
    
    Exit Codes:
    - 0: Script completed successfully
    - 1: Script encountered errors
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$EDRField = "secEDREnabled",
    
    [Parameter()]
    [String]$RealtimeProtectionField = "secRealtimeProtectionOn",
    
    [Parameter()]
    [String]$ThreatsDetectedField = "secThreatsDetected24h",
    
    [Parameter()]
    [String]$QuarantineField = "secQuarantineItemCount",
    
    [Parameter()]
    [String]$LastScanField = "secLastScanDate",
    
    [Parameter()]
    [ValidateRange(1, 168)]
    [Int]$ThreatWindowHours = 24,
    
    [Parameter()]
    [ValidateRange(1, 365)]
    [Int]$ScanAgeThresholdDays = 7
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $script:ExitCode = 0
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Output $LogMessage; $script:ExitCode = 1 }
            'ALERT' { Write-Output $LogMessage }
            'WARNING' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:edrField -and $env:edrField -notlike "null") {
        $EDRField = $env:edrField
    }
    if ($env:realtimeProtectionField -and $env:realtimeProtectionField -notlike "null") {
        $RealtimeProtectionField = $env:realtimeProtectionField
    }
    if ($env:threatsDetectedField -and $env:threatsDetectedField -notlike "null") {
        $ThreatsDetectedField = $env:threatsDetectedField
    }
    if ($env:quarantineField -and $env:quarantineField -notlike "null") {
        $QuarantineField = $env:quarantineField
    }
    if ($env:lastScanField -and $env:lastScanField -notlike "null") {
        $LastScanField = $env:lastScanField
    }
    if ($env:threatWindowHours -and $env:threatWindowHours -notlike "null") {
        $ThreatWindowHours = [int]$env:threatWindowHours
    }
    if ($env:scanAgeThresholdDays -and $env:scanAgeThresholdDays -notlike "null") {
        $ScanAgeThresholdDays = [int]$env:scanAgeThresholdDays
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $Value
        )
        try {
            $NinjaValue = $Value
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            throw "Failed to set NinjaRMM property '$Name': $_"
        }
    }
}

process {
    try {
        Write-Log "Starting Endpoint Detection and Response Telemetry (v3.0.0)"
        
        $metrics = @{
            'EDREnabled' = $false
            'RealtimeProtection' = $false
            'ThreatsDetected' = 0
            'QuarantineCount' = 0
            'LastScanDate' = $null
            'DaysSinceLastScan' = $null
        }
        $threatDetails = @()

        Write-Log "Querying Microsoft Defender status..."
        try {
            $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
            Write-Log "Microsoft Defender is installed and responding"
            
            $metrics['RealtimeProtection'] = $defenderStatus.RealTimeProtectionEnabled
            if ($metrics['RealtimeProtection']) {
                Write-Log "Real-time protection is ENABLED"
            } 
            else {
                Write-Log "Real-time protection is DISABLED" -Level ALERT
            }

            $metrics['EDREnabled'] = $defenderStatus.AntivirusEnabled -or $defenderStatus.RealTimeProtectionEnabled
            if ($metrics['EDREnabled']) {
                Write-Log "Antivirus/EDR protection is ACTIVE"
            } 
            else {
                Write-Log "Antivirus/EDR protection is INACTIVE" -Level ALERT
            }

            $lastQuickScan = $defenderStatus.QuickScanEndTime
            $lastFullScan = $defenderStatus.FullScanEndTime
            $metrics['LastScanDate'] = if ($lastQuickScan -gt $lastFullScan) { $lastQuickScan } else { $lastFullScan }
            
            if ($metrics['LastScanDate']) {
                $metrics['DaysSinceLastScan'] = ((Get-Date) - $metrics['LastScanDate']).Days
                $scanType = if ($lastQuickScan -gt $lastFullScan) { 'Quick' } else { 'Full' }
                Write-Log "Last scan: $scanType scan on $($metrics['LastScanDate'].ToString('yyyy-MM-dd HH:mm')) ($($metrics['DaysSinceLastScan']) days ago)"
                
                if ($metrics['DaysSinceLastScan'] -gt $ScanAgeThresholdDays) {
                    Write-Log "Last scan is over $ScanAgeThresholdDays days old" -Level WARNING
                }
            } 
            else {
                Write-Log "No scan history found" -Level WARNING
            }
        }
        catch {
            Write-Log "Windows Defender status not available: $_" -Level WARNING
            Write-Log "Service may be disabled, not installed, or unsupported on this OS" -Level WARNING
        }

        Write-Log "Checking threat detection history (last $ThreatWindowHours hours)..."
        try {
            $threatWindowStart = (Get-Date).AddHours(-$ThreatWindowHours)
            $allThreats = Get-MpThreatDetection -ErrorAction Stop
            
            $recentThreats = $allThreats | Where-Object {
                $_.InitialDetectionTime -gt $threatWindowStart
            }

            $metrics['ThreatsDetected'] = if ($recentThreats) { ($recentThreats | Measure-Object).Count } else { 0 }
            
            if ($metrics['ThreatsDetected'] -gt 0) {
                Write-Log "Detected $($metrics['ThreatsDetected']) threat(s) in last $ThreatWindowHours hours" -Level ALERT
                
                $recentThreats | Select-Object -First 5 | ForEach-Object {
                    $threatDetail = "$($_.ThreatName) detected at $($_.InitialDetectionTime.ToString('yyyy-MM-dd HH:mm'))"
                    $threatDetails += $threatDetail
                    Write-Log "  - $threatDetail" -Level WARNING
                }
                
                if ($metrics['ThreatsDetected'] -gt 5) {
                    Write-Log "  (showing first 5 of $($metrics['ThreatsDetected']) threats)"
                }
            } 
            else {
                Write-Log "No threats detected in last $ThreatWindowHours hours"
            }
        } 
        catch {
            Write-Log "Failed to query threat detection history: $_" -Level WARNING
        }

        Write-Log "Checking quarantine status..."
        try {
            $quarantineItems = Get-MpThreat -ErrorAction Stop
            $metrics['QuarantineCount'] = if ($quarantineItems) { ($quarantineItems | Measure-Object).Count } else { 0 }
            
            if ($metrics['QuarantineCount'] -gt 0) {
                Write-Log "Quarantine contains $($metrics['QuarantineCount']) item(s)"
            } 
            else {
                Write-Log "Quarantine is empty"
            }
        } 
        catch {
            Write-Log "Failed to query quarantine: $_" -Level WARNING
        }

        $securityPosture = 'GOOD'
        $postureReasons = @()
        
        if (-not $metrics['RealtimeProtection'] -or -not $metrics['EDREnabled']) {
            $securityPosture = 'CRITICAL'
            if (-not $metrics['RealtimeProtection']) {
                $postureReasons += 'Real-time protection disabled'
            }
            if (-not $metrics['EDREnabled']) {
                $postureReasons += 'EDR/Antivirus disabled'
            }
        } 
        elseif ($metrics['ThreatsDetected'] -gt 0) {
            $securityPosture = 'WARNING'
            $postureReasons += "$($metrics['ThreatsDetected']) active threat(s) detected"
        } 
        else {
            $postureReasons += 'Protection active with no recent threats'
        }
        
        if ($metrics['DaysSinceLastScan'] -and $metrics['DaysSinceLastScan'] -gt $ScanAgeThresholdDays) {
            if ($securityPosture -eq 'GOOD') {
                $securityPosture = 'WARNING'
            }
            $postureReasons += "Last scan is $($metrics['DaysSinceLastScan']) days old (threshold: $ScanAgeThresholdDays days)"
        }

        Write-Log "Security posture: $securityPosture"
        $postureReasons | ForEach-Object { Write-Log "  - $_" }

        Write-Log "Updating NinjaRMM custom fields..."
        try {
            Set-NinjaProperty -Name $EDRField -Value $metrics['EDREnabled'] -ErrorAction Stop
            Write-Log "EDR enabled status saved to field: $EDRField"
        }
        catch {
            Write-Log "Failed to update EDR field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $RealtimeProtectionField -Value $metrics['RealtimeProtection'] -ErrorAction Stop
            Write-Log "Real-time protection status saved to field: $RealtimeProtectionField"
        }
        catch {
            Write-Log "Failed to update real-time protection field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $ThreatsDetectedField -Value $metrics['ThreatsDetected'] -ErrorAction Stop
            Write-Log "Threat count saved to field: $ThreatsDetectedField"
        }
        catch {
            Write-Log "Failed to update threats detected field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $QuarantineField -Value $metrics['QuarantineCount'] -ErrorAction Stop
            Write-Log "Quarantine count saved to field: $QuarantineField"
        }
        catch {
            Write-Log "Failed to update quarantine field: $_" -Level ERROR
        }

        if ($metrics['LastScanDate']) {
            try {
                Set-NinjaProperty -Name $LastScanField -Value $metrics['LastScanDate'] -ErrorAction Stop
                Write-Log "Last scan date saved to field: $LastScanField"
            }
            catch {
                Write-Log "Failed to update last scan date field: $_" -Level ERROR
            }
        }

        Write-Log "EDR TELEMETRY SUMMARY:"
        Write-Log "  EDR Enabled: $($metrics['EDREnabled'])"
        Write-Log "  Real-time Protection: $($metrics['RealtimeProtection'])"
        Write-Log "  Threats Detected ($ThreatWindowHours h): $($metrics['ThreatsDetected'])"
        Write-Log "  Quarantine Items: $($metrics['QuarantineCount'])"
        if ($metrics['LastScanDate']) {
            Write-Log "  Last Scan: $($metrics['LastScanDate'].ToString('yyyy-MM-dd HH:mm')) ($($metrics['DaysSinceLastScan']) days ago)"
        } 
        else {
            Write-Log "  Last Scan: No scan history"
        }
        Write-Log "  Security Posture: $securityPosture"

        if ($threatDetails.Count -gt 0) {
            Write-Log "DETECTED THREATS:"
            $threatDetails | ForEach-Object { Write-Log "  - $_" -Level WARNING }
        }

        Write-Log "Endpoint Detection and Response telemetry completed successfully"
    }
    catch {
        Write-Log "EDR telemetry failed with unexpected error: $_" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $([Math]::Round($Duration, 2)) seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
