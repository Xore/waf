#Requires -Version 5.1

<#
.SYNOPSIS
    Security Posture Consolidator - Comprehensive Security Score Aggregation

.DESCRIPTION
    Calculates comprehensive security posture score by aggregating multiple security control
    assessments including endpoint protection, encryption, firewall, protocol security, and
    authentication monitoring. Provides unified security health metric for compliance reporting
    and risk assessment.
    
    Consolidates security telemetry from multiple sources (custom fields populated by other
    scripts) and adds real-time authentication security checks to produce holistic security
    posture score. Enables security operations teams to quickly identify systems with degraded
    security controls.
    
    Security Scoring Model (100 points, deductions applied):
    
    Endpoint Protection (40-45 points):
    - No antivirus installed: -40 points (critical vulnerability)
    - Antivirus disabled: -30 points (severe risk)
    - Antivirus definitions outdated: -15 points (moderate risk)
    
    Firewall Protection (30 points):
    - Firewall disabled: -30 points
    - All profiles enabled: 0 deduction
    
    Disk Encryption (15 points):
    - BitLocker not enabled: -15 points
    - BitLocker protection on: 0 deduction
    
    Protocol Security (10 points):
    - SMBv1 protocol enabled: -10 points (known vulnerability)
    - SMBv1 disabled: 0 deduction
    
    Authentication Security (20 points):
    - Failed logons >50 in 24h: -20 points (attack likely)
    - Failed logons >20 in 24h: -10 points (suspicious activity)
    - Failed logons >10 in 24h: -5 points (elevated activity)
    - Failed logons <=10: 0 deduction
    
    Score Interpretation:
    - 90-100: Excellent security posture
    - 75-89: Good security posture
    - 60-74: Fair security, gaps exist
    - Below 60: Poor security, immediate action required

.PARAMETER PostureScoreField
    NinjaRMM custom field name to store the consolidated security posture score (0-100).
    Default: secSecurityPostureScore

.PARAMETER FailedLogonField
    NinjaRMM custom field name to store failed logon count in last 24 hours.
    Default: secFailedLogonCount24h

.PARAMETER LockoutField
    NinjaRMM custom field name to store account lockout count in last 24 hours.
    Default: secAccountLockouts24h

.EXAMPLE
    .\SecurityPostureConsolidator.ps1

    Runs security posture consolidation with default custom field names.

.EXAMPLE
    .\SecurityPostureConsolidator.ps1 -PostureScoreField "SecurityScore" -FailedLogonField "FailedLogins"

    Runs with custom field names.

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : SecurityPostureConsolidator.ps1
    Prerequisite   : PowerShell 5.1 or higher, Admin privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    Frequency      : Daily
    Runtime        : Approximately 35 seconds
    Timeout        : 90 seconds
    Context        : SYSTEM
    
    Change Log:
    - 3.0.0: V3 migration with standardized logging, error handling, and custom field management
    - 4.0: Previous version with consolidation logic
    
    Fields Read (from other scripts):
    - secAntivirusInstalled: Checkbox indicating AV installation status
    - secAntivirusEnabled: Checkbox indicating AV enabled status
    - secAntivirusUpToDate: Checkbox indicating AV definition freshness
    - secFirewallEnabled: Checkbox indicating firewall status
    - secBitLockerEnabled: Checkbox indicating BitLocker status
    
    Fields Updated:
    - secSecurityPostureScore: Integer 0-100 consolidated security score
    - secFailedLogonCount24h: Integer failed logon attempts in last 24 hours
    - secAccountLockouts24h: Integer account lockout events in last 24 hours
    
    Dependencies:
    - Windows Security event log
    - Get-WindowsOptionalFeature cmdlet
    - Security monitoring scripts must run first to populate input fields
    
    Event IDs Monitored:
    - 4625: Failed logon attempt
    - 4740: User account locked out
    
    Integration Pattern:
    - Reads security control states from fields populated by other WAF scripts
    - Performs real-time authentication monitoring
    - Produces consolidated score for dashboards and alerting
    
    Exit Codes:
    - 0: Script completed successfully
    - 1: Script encountered errors
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$PostureScoreField = "secSecurityPostureScore",
    
    [Parameter()]
    [String]$FailedLogonField = "secFailedLogonCount24h",
    
    [Parameter()]
    [String]$LockoutField = "secAccountLockouts24h"
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
            'CRITICAL' { Write-Output $LogMessage; $script:ExitCode = 1 }
            'ALERT' { Write-Output $LogMessage }
            'WARNING' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:postureScoreField -and $env:postureScoreField -notlike "null") {
        $PostureScoreField = $env:postureScoreField
    }
    if ($env:failedLogonField -and $env:failedLogonField -notlike "null") {
        $FailedLogonField = $env:failedLogonField
    }
    if ($env:lockoutField -and $env:lockoutField -notlike "null") {
        $LockoutField = $env:lockoutField
    }

    function Get-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name
        )
        try {
            $Value = Ninja-Property-Get $Name 2>&1
            if ($Value.Exception) {
                Write-Log "Unable to read property '$Name': $($Value.Exception.Message)" -Level WARNING
                return $null
            }
            return $Value
        }
        catch {
            Write-Log "Failed to get NinjaRMM property '$Name': $_" -Level WARNING
            return $null
        }
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
        Write-Log "Starting Security Posture Consolidator (v3.0.0)"

        $score = 100
        $findings = @()
        $metrics = @{}

        Write-Log "Evaluating endpoint protection status..."
        try {
            $avInstalled = Get-NinjaProperty -Name "secAntivirusInstalled"
            $avEnabled = Get-NinjaProperty -Name "secAntivirusEnabled"
            $avUpToDate = Get-NinjaProperty -Name "secAntivirusUpToDate"

            if ($avInstalled -eq $false) {
                $score -= 40
                $findings += "No antivirus installed (-40 points)"
                $metrics['EndpointProtection'] = 'Not Installed'
                Write-Log "No antivirus installed" -Level CRITICAL
            } 
            elseif ($avEnabled -eq $false) {
                $score -= 30
                $findings += "Antivirus disabled (-30 points)"
                $metrics['EndpointProtection'] = 'Disabled'
                Write-Log "Antivirus disabled" -Level CRITICAL
            } 
            elseif ($avUpToDate -eq $false) {
                $score -= 15
                $findings += "Antivirus definitions outdated (-15 points)"
                $metrics['EndpointProtection'] = 'Outdated Definitions'
                Write-Log "Antivirus definitions outdated" -Level WARNING
            } 
            else {
                $metrics['EndpointProtection'] = 'Current'
                Write-Log "Endpoint protection is current"
            }
        }
        catch {
            Write-Log "Failed to evaluate endpoint protection: $_" -Level ERROR
            $metrics['EndpointProtection'] = 'Evaluation Failed'
        }

        Write-Log "Evaluating firewall status..."
        try {
            $fwEnabled = Get-NinjaProperty -Name "secFirewallEnabled"
            
            if ($fwEnabled -eq $false) {
                $score -= 30
                $findings += "Firewall disabled (-30 points)"
                $metrics['Firewall'] = 'Disabled'
                Write-Log "Firewall disabled" -Level CRITICAL
            } 
            else {
                $metrics['Firewall'] = 'Enabled'
                Write-Log "Firewall enabled"
            }
        }
        catch {
            Write-Log "Failed to evaluate firewall status: $_" -Level ERROR
            $metrics['Firewall'] = 'Evaluation Failed'
        }

        Write-Log "Evaluating disk encryption status..."
        try {
            $blEnabled = Get-NinjaProperty -Name "secBitLockerEnabled"
            
            if ($blEnabled -eq $false) {
                $score -= 15
                $findings += "BitLocker not enabled (-15 points)"
                $metrics['DiskEncryption'] = 'Not Enabled'
                Write-Log "BitLocker not enabled" -Level WARNING
            } 
            else {
                $metrics['DiskEncryption'] = 'Enabled'
                Write-Log "BitLocker encryption enabled"
            }
        }
        catch {
            Write-Log "Failed to evaluate disk encryption: $_" -Level ERROR
            $metrics['DiskEncryption'] = 'Evaluation Failed'
        }

        Write-Log "Checking SMBv1 protocol status..."
        try {
            $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
            if ($smbv1 -and $smbv1.State -eq 'Enabled') {
                $score -= 10
                $findings += "SMBv1 protocol enabled (known vulnerability, -10 points)"
                $metrics['SMBv1'] = 'Enabled (Vulnerable)'
                Write-Log "SMBv1 protocol enabled" -Level WARNING
            } 
            else {
                $metrics['SMBv1'] = 'Disabled'
                Write-Log "SMBv1 protocol disabled"
            }
        }
        catch {
            $metrics['SMBv1'] = 'Unable to check'
            Write-Log "Unable to check SMBv1 status: $_"
        }

        Write-Log "Analyzing authentication security..."
        $startTime = (Get-Date).AddHours(-24)
        $failedLogons = 0
        $lockouts = 0

        Write-Log "Checking failed logon attempts (Event ID 4625)..."
        try {
            $failedLogonEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = 4625
                StartTime = $startTime
            } -ErrorAction SilentlyContinue
            
            $failedLogons = ($failedLogonEvents | Measure-Object).Count
            
            if ($failedLogons -gt 50) {
                $score -= 20
                $findings += "Excessive failed logons: $failedLogons (-20 points)"
                $metrics['FailedLogons'] = "$failedLogons (Possible Attack)"
                Write-Log "Excessive failed logons: $failedLogons" -Level ALERT
            } 
            elseif ($failedLogons -gt 20) {
                $score -= 10
                $findings += "High failed logons: $failedLogons (-10 points)"
                $metrics['FailedLogons'] = "$failedLogons (Suspicious)"
                Write-Log "High failed logon count: $failedLogons" -Level WARNING
            } 
            elseif ($failedLogons -gt 10) {
                $score -= 5
                $findings += "Elevated failed logons: $failedLogons (-5 points)"
                $metrics['FailedLogons'] = "$failedLogons (Elevated)"
                Write-Log "Elevated failed logon count: $failedLogons"
            } 
            else {
                $metrics['FailedLogons'] = "$failedLogons (Normal)"
                Write-Log "Failed logon count acceptable: $failedLogons"
            }
        }
        catch {
            Write-Log "Unable to query failed logon events: $_" -Level WARNING
            $metrics['FailedLogons'] = 'Unable to query'
        }

        Write-Log "Checking account lockout events (Event ID 4740)..."
        try {
            $lockoutEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                ID = 4740
                StartTime = $startTime
            } -ErrorAction SilentlyContinue
            
            $lockouts = ($lockoutEvents | Measure-Object).Count
            
            if ($lockouts -gt 0) {
                $metrics['AccountLockouts'] = "$lockouts detected"
                Write-Log "Detected $lockouts account lockout(s) in last 24 hours"
            } 
            else {
                $metrics['AccountLockouts'] = 'None detected'
                Write-Log "No account lockouts detected"
            }
        }
        catch {
            Write-Log "Unable to query lockout events: $_" -Level WARNING
            $metrics['AccountLockouts'] = 'Unable to query'
        }

        if ($score -lt 0) { $score = 0 }
        if ($score -gt 100) { $score = 100 }

        $assessment = switch ($score) {
            { $_ -ge 90 } { 'Excellent' }
            { $_ -ge 75 } { 'Good' }
            { $_ -ge 60 } { 'Fair - gaps exist, remediation recommended' }
            default { 'Poor - immediate action required' }
        }

        Write-Log "Consolidated security score: $score/100"
        Write-Log "Security posture assessment: $assessment"

        Write-Log "Updating NinjaRMM custom fields..."
        try {
            Set-NinjaProperty -Name $PostureScoreField -Value $score -ErrorAction Stop
            Write-Log "Security posture score saved to field: $PostureScoreField"
        }
        catch {
            Write-Log "Failed to update posture score field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $FailedLogonField -Value $failedLogons -ErrorAction Stop
            Write-Log "Failed logon count saved to field: $FailedLogonField"
        }
        catch {
            Write-Log "Failed to update failed logon field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $LockoutField -Value $lockouts -ErrorAction Stop
            Write-Log "Account lockout count saved to field: $LockoutField"
        }
        catch {
            Write-Log "Failed to update lockout field: $_" -Level ERROR
        }

        Write-Log "SECURITY CONTROL STATUS:"
        foreach ($control in $metrics.Keys | Sort-Object) {
            Write-Log "  $control : $($metrics[$control])"
        }

        Write-Log "AUTHENTICATION METRICS:"
        Write-Log "  Failed Logons (24h): $failedLogons"
        Write-Log "  Account Lockouts (24h): $lockouts"

        if ($findings.Count -gt 0) {
            Write-Log "SECURITY GAPS IDENTIFIED:"
            $findings | ForEach-Object { Write-Log "  - $_" -Level WARNING }
        } 
        else {
            Write-Log "All security controls passed validation"
        }

        Write-Log "Security posture consolidation completed successfully"
    }
    catch {
        Write-Log "Security posture consolidation failed with unexpected error: $_" -Level ERROR
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
