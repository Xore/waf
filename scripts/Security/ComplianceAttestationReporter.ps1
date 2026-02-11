#Requires -Version 5.1

<#
.SYNOPSIS
    Compliance and Attestation Reporter - Security Posture Scoring and Compliance Validation

.DESCRIPTION
    Generates comprehensive compliance attestation by evaluating multiple security control areas
    including patch management, endpoint protection, firewall configuration, backup status, and
    disk encryption. Produces scored compliance assessment with detailed non-compliance reasons.
    
    Implements weighted scoring model where critical security controls (patches, antivirus) carry
    higher point values than supplementary controls. Enables automated compliance reporting for
    regulatory frameworks including CIS Controls, NIST Cybersecurity Framework, and industry
    standards like PCI-DSS and HIPAA baseline requirements.
    
    Compliance Scoring Model (100 points total):
    - Critical Patches: 30 points (deducted if missing critical patches)
    - Real-time Protection: 25 points (antivirus/EDR active scanning)
    - Firewall Status: 20 points (Windows Firewall or third-party enabled)
    - Backup Currency: 15-20 points (successful backup within threshold days)
    - Disk Encryption: 10 points (BitLocker or equivalent full-disk encryption)
    
    Attestation Status Thresholds:
    - Compliant: 90-100 points (minimal gaps, production-ready)
    - Partial: 70-89 points (moderate gaps, requires remediation)
    - Non-Compliant: 0-69 points (significant gaps, immediate action required)
    
    Integrates with other WAF monitoring scripts by querying their output fields to build
    comprehensive security posture view without duplicating checks.

.PARAMETER ComplianceScoreField
    NinjaRMM custom field name to store compliance score (0-100).
    Default: compComplianceScore

.PARAMETER AttestationStatusField
    NinjaRMM custom field name to store attestation status.
    Default: compAttestationStatus

.PARAMETER LastAttestationField
    NinjaRMM custom field name to store last attestation timestamp.
    Default: compLastAttestationDate

.PARAMETER NonCompliantReasonsField
    NinjaRMM custom field name to store non-compliant reasons.
    Default: compNonCompliantReasons

.PARAMETER PatchStatusField
    NinjaRMM custom field name to read missing critical patch count.
    Default: updMissingCriticalCount

.PARAMETER RealtimeProtectionField
    NinjaRMM custom field name to read real-time protection status.
    Default: secRealtimeProtectionOn

.PARAMETER FirewallField
    NinjaRMM custom field name to read firewall status.
    Default: secFirewallEnabled

.PARAMETER BackupField
    NinjaRMM custom field name to read last backup success date.
    Default: backupLastSuccess

.PARAMETER EncryptionField
    NinjaRMM custom field name to read disk encryption status.
    Default: secEncryptionEnabled

.PARAMETER BackupAgeDaysThreshold
    Maximum age in days for backup to be considered current.
    Default: 7

.EXAMPLE
    .\ComplianceAttestationReporter.ps1

    Runs compliance assessment with default settings (7-day backup threshold).

.EXAMPLE
    .\ComplianceAttestationReporter.ps1 -BackupAgeDaysThreshold 14

    Runs with 14-day backup currency threshold.

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : ComplianceAttestationReporter.ps1
    Prerequisite   : PowerShell 5.1 or higher, Admin privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    Frequency      : Daily
    Runtime        : Approximately 15 seconds
    Timeout        : 60 seconds
    Context        : SYSTEM
    
    Change Log:
    - 3.0.0: V3 migration with standardized logging, error handling, and parameterized configuration
    - 4.0: Previous version with compliance attestation
    
    Fields Updated:
    - compComplianceScore: Integer 0-100 point scale
    - compAttestationStatus: Text (Compliant, Partial, Non-Compliant, Unknown)
    - compLastAttestationDate: DateTime timestamp of assessment
    - compNonCompliantReasons: Text semicolon-separated list of compliance gaps
    
    Fields Read (from other WAF scripts):
    - updMissingCriticalCount: Critical patch count
    - secRealtimeProtectionOn: Real-time protection status
    - secFirewallEnabled: Firewall status
    - backupLastSuccess: Last backup timestamp
    - secEncryptionEnabled: Disk encryption status
    
    Compliance Frameworks Supported:
    - CIS Controls v8 (Critical Security Controls)
    - NIST Cybersecurity Framework
    - ISO 27001 baseline controls
    - PCI-DSS security requirements
    - HIPAA Security Rule technical safeguards
    
    Scoring Model:
    - Critical Patches: 30 points (all-or-nothing)
    - Real-time Protection: 25 points (all-or-nothing)
    - Firewall: 20 points (all-or-nothing)
    - Backup Currency: 15-20 points (stale backup = -15, no backup = -20)
    - Disk Encryption: 10 points (all-or-nothing)
    
    Exit Codes:
    - 0: Script completed successfully
    - 1: Script encountered errors
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$ComplianceScoreField = "compComplianceScore",
    
    [Parameter()]
    [String]$AttestationStatusField = "compAttestationStatus",
    
    [Parameter()]
    [String]$LastAttestationField = "compLastAttestationDate",
    
    [Parameter()]
    [String]$NonCompliantReasonsField = "compNonCompliantReasons",
    
    [Parameter()]
    [String]$PatchStatusField = "updMissingCriticalCount",
    
    [Parameter()]
    [String]$RealtimeProtectionField = "secRealtimeProtectionOn",
    
    [Parameter()]
    [String]$FirewallField = "secFirewallEnabled",
    
    [Parameter()]
    [String]$BackupField = "backupLastSuccess",
    
    [Parameter()]
    [String]$EncryptionField = "secEncryptionEnabled",
    
    [Parameter()]
    [ValidateRange(1, 365)]
    [Int]$BackupAgeDaysThreshold = 7
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
            'FAIL' { Write-Output $LogMessage }
            'PASS' { Write-Output $LogMessage }
            'WARNING' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:complianceScoreField -and $env:complianceScoreField -notlike "null") {
        $ComplianceScoreField = $env:complianceScoreField
    }
    if ($env:attestationStatusField -and $env:attestationStatusField -notlike "null") {
        $AttestationStatusField = $env:attestationStatusField
    }
    if ($env:lastAttestationField -and $env:lastAttestationField -notlike "null") {
        $LastAttestationField = $env:lastAttestationField
    }
    if ($env:nonCompliantReasonsField -and $env:nonCompliantReasonsField -notlike "null") {
        $NonCompliantReasonsField = $env:nonCompliantReasonsField
    }
    if ($env:patchStatusField -and $env:patchStatusField -notlike "null") {
        $PatchStatusField = $env:patchStatusField
    }
    if ($env:realtimeProtectionField -and $env:realtimeProtectionField -notlike "null") {
        $RealtimeProtectionField = $env:realtimeProtectionField
    }
    if ($env:firewallField -and $env:firewallField -notlike "null") {
        $FirewallField = $env:firewallField
    }
    if ($env:backupField -and $env:backupField -notlike "null") {
        $BackupField = $env:backupField
    }
    if ($env:encryptionField -and $env:encryptionField -notlike "null") {
        $EncryptionField = $env:encryptionField
    }
    if ($env:backupAgeDaysThreshold -and $env:backupAgeDaysThreshold -notlike "null") {
        $BackupAgeDaysThreshold = [int]$env:backupAgeDaysThreshold
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

    function Get-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name
        )
        try {
            $result = Ninja-Property-Get $Name 2>&1
            if ($result.Exception) {
                throw $result
            }
            return $result
        }
        catch {
            Write-Log "Failed to read NinjaRMM property '$Name': $_" -Level WARNING
            return $null
        }
    }

    $ComplianceWeights = @{
        'CriticalPatches' = 30
        'RealtimeProtection' = 25
        'Firewall' = 20
        'BackupCurrency' = 15
        'BackupMissing' = 20
        'DiskEncryption' = 10
    }
}

process {
    try {
        Write-Log "Starting Compliance and Attestation Reporter (v3.0.0)"
        Write-Log "Evaluating security controls for compliance scoring..."
        
        $complianceScore = 100
        $nonCompliantReasons = @()
        $controlResults = @()

        Write-Log "Control 1: Critical Patch Status ($($ComplianceWeights['CriticalPatches']) points)"
        try {
            $criticalMissing = Get-NinjaProperty -Name $PatchStatusField
            
            if ($null -ne $criticalMissing -and $criticalMissing -gt 0) {
                $deduction = $ComplianceWeights['CriticalPatches']
                $complianceScore -= $deduction
                $reason = "$criticalMissing critical patch(es) missing"
                $nonCompliantReasons += $reason
                $controlResults += "FAIL: $reason (-$deduction points)"
                Write-Log "$criticalMissing critical patch(es) missing" -Level FAIL
            } 
            else {
                $controlResults += "PASS: No critical patches missing (+$($ComplianceWeights['CriticalPatches']) points)"
                Write-Log "No critical patches missing" -Level PASS
            }
        }
        catch {
            Write-Log "Failed to check patch status: $_" -Level WARNING
        }

        Write-Log "Control 2: Real-time Antivirus Protection ($($ComplianceWeights['RealtimeProtection']) points)"
        try {
            $realtimeProtection = Get-NinjaProperty -Name $RealtimeProtectionField
            
            if ($realtimeProtection -ne $true) {
                $deduction = $ComplianceWeights['RealtimeProtection']
                $complianceScore -= $deduction
                $reason = "Real-time protection disabled"
                $nonCompliantReasons += $reason
                $controlResults += "FAIL: $reason (-$deduction points)"
                Write-Log "Real-time protection is DISABLED" -Level FAIL
            } 
            else {
                $controlResults += "PASS: Real-time protection is ENABLED (+$($ComplianceWeights['RealtimeProtection']) points)"
                Write-Log "Real-time protection is ENABLED" -Level PASS
            }
        }
        catch {
            Write-Log "Failed to check real-time protection: $_" -Level WARNING
        }

        Write-Log "Control 3: Firewall Status ($($ComplianceWeights['Firewall']) points)"
        try {
            $firewallEnabled = Get-NinjaProperty -Name $FirewallField
            
            if ($firewallEnabled -ne $true) {
                $deduction = $ComplianceWeights['Firewall']
                $complianceScore -= $deduction
                $reason = "Firewall disabled"
                $nonCompliantReasons += $reason
                $controlResults += "FAIL: $reason (-$deduction points)"
                Write-Log "Firewall is DISABLED" -Level FAIL
            } 
            else {
                $controlResults += "PASS: Firewall is ENABLED (+$($ComplianceWeights['Firewall']) points)"
                Write-Log "Firewall is ENABLED" -Level PASS
            }
        }
        catch {
            Write-Log "Failed to check firewall status: $_" -Level WARNING
        }

        Write-Log "Control 4: Backup Currency ($($ComplianceWeights['BackupCurrency'])-$($ComplianceWeights['BackupMissing']) points)"
        try {
            $lastBackup = Get-NinjaProperty -Name $BackupField
            
            if ($lastBackup) {
                try {
                    $backupDate = [datetime]$lastBackup
                    $backupAge = (Get-Date) - $backupDate
                    $backupAgeDays = [math]::Round($backupAge.TotalDays, 1)
                    
                    if ($backupAge.TotalDays -gt $BackupAgeDaysThreshold) {
                        $deduction = $ComplianceWeights['BackupCurrency']
                        $complianceScore -= $deduction
                        $reason = "Backup is $backupAgeDays days old (threshold: $BackupAgeDaysThreshold days)"
                        $nonCompliantReasons += $reason
                        $controlResults += "FAIL: $reason (-$deduction points)"
                        Write-Log "Backup age $backupAgeDays days exceeds $BackupAgeDaysThreshold-day policy" -Level FAIL
                    } 
                    else {
                        $controlResults += "PASS: Backup is current ($backupAgeDays days old) (+$($ComplianceWeights['BackupCurrency']) points)"
                        Write-Log "Backup is current ($backupAgeDays days old)" -Level PASS
                    }
                } 
                catch {
                    $deduction = $ComplianceWeights['BackupMissing']
                    $complianceScore -= $deduction
                    $reason = "Invalid backup date format"
                    $nonCompliantReasons += $reason
                    $controlResults += "FAIL: $reason (-$deduction points)"
                    Write-Log "Cannot parse backup date: $_" -Level FAIL
                }
            } 
            else {
                $deduction = $ComplianceWeights['BackupMissing']
                $complianceScore -= $deduction
                $reason = "No backup data available"
                $nonCompliantReasons += $reason
                $controlResults += "FAIL: $reason (-$deduction points)"
                Write-Log "No backup data available" -Level FAIL
            }
        }
        catch {
            Write-Log "Failed to check backup status: $_" -Level WARNING
        }

        Write-Log "Control 5: Disk Encryption ($($ComplianceWeights['DiskEncryption']) points)"
        try {
            $encryptionEnabled = Get-NinjaProperty -Name $EncryptionField
            
            if ($encryptionEnabled -ne $true) {
                $deduction = $ComplianceWeights['DiskEncryption']
                $complianceScore -= $deduction
                $reason = "Disk encryption not enabled"
                $nonCompliantReasons += $reason
                $controlResults += "FAIL: $reason (-$deduction points)"
                Write-Log "Disk encryption is NOT enabled" -Level FAIL
            } 
            else {
                $controlResults += "PASS: Disk encryption is ENABLED (+$($ComplianceWeights['DiskEncryption']) points)"
                Write-Log "Disk encryption is ENABLED" -Level PASS
            }
        }
        catch {
            Write-Log "Failed to check encryption status: $_" -Level WARNING
        }

        if ($complianceScore -lt 0) {
            $complianceScore = 0
            Write-Log "Score floor applied (minimum 0)"
        }

        if ($complianceScore -ge 90) {
            $attestationStatus = "Compliant"
            $statusMessage = "COMPLIANT - Minimal gaps, production-ready"
        } 
        elseif ($complianceScore -ge 70) {
            $attestationStatus = "Partial"
            $statusMessage = "PARTIAL COMPLIANCE - Moderate gaps, remediation required"
        } 
        else {
            $attestationStatus = "Non-Compliant"
            $statusMessage = "NON-COMPLIANT - Significant gaps, immediate action required"
        }

        Write-Log "Compliance assessment complete: $statusMessage (score: $complianceScore/100)"

        Write-Log "Updating NinjaRMM custom fields..."
        try {
            Set-NinjaProperty -Name $ComplianceScoreField -Value $complianceScore -ErrorAction Stop
            Write-Log "Compliance score saved to field: $ComplianceScoreField"
        }
        catch {
            Write-Log "Failed to update compliance score field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $AttestationStatusField -Value $attestationStatus -ErrorAction Stop
            Write-Log "Attestation status saved to field: $AttestationStatusField"
        }
        catch {
            Write-Log "Failed to update attestation status field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $LastAttestationField -Value (Get-Date) -ErrorAction Stop
            Write-Log "Attestation timestamp saved to field: $LastAttestationField"
        }
        catch {
            Write-Log "Failed to update attestation date field: $_" -Level ERROR
        }

        $reasonsText = if ($nonCompliantReasons.Count -gt 0) {
            $nonCompliantReasons -join "; "
        } 
        else {
            "Fully compliant - all controls passed"
        }

        try {
            Set-NinjaProperty -Name $NonCompliantReasonsField -Value $reasonsText -ErrorAction Stop
            Write-Log "Non-compliant reasons saved to field: $NonCompliantReasonsField"
        }
        catch {
            Write-Log "Failed to update non-compliant reasons field: $_" -Level ERROR
        }

        Write-Log "COMPLIANCE ATTESTATION SUMMARY:"
        Write-Log "  Final Score: $complianceScore/100"
        Write-Log "  Status: $attestationStatus"
        Write-Log "  Gaps Identified: $($nonCompliantReasons.Count)"
        
        Write-Log "CONTROL RESULTS:"
        $controlResults | ForEach-Object { Write-Log "  $_" }

        if ($nonCompliantReasons.Count -gt 0) {
            Write-Log "NON-COMPLIANT ITEMS:"
            $nonCompliantReasons | ForEach-Object { Write-Log "  - $_" -Level WARNING }
        }

        Write-Log "Compliance and attestation reporting completed successfully"
    }
    catch {
        Write-Log "Compliance attestation failed with unexpected error: $_" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        
        try {
            Set-NinjaProperty -Name $AttestationStatusField -Value "Unknown" -ErrorAction SilentlyContinue
            Set-NinjaProperty -Name $NonCompliantReasonsField -Value "Assessment failed: $_" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "Failed to set error state fields" -Level ERROR
        }
        
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
