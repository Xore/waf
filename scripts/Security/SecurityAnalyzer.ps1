#Requires -Version 5.1

<#
.SYNOPSIS
    Security Analyzer - Comprehensive Security Posture Scoring

.DESCRIPTION
    Calculates comprehensive security posture score by evaluating critical security controls
    including antivirus protection, firewall configuration, disk encryption, protocol security,
    and patch compliance. Provides weighted scoring model to quantify overall security posture.
    
    Implements defense-in-depth assessment by checking multiple security layers from endpoint
    protection to data encryption. Uses 100-point scoring system with significant deductions
    for missing or disabled security controls that expose the system to threats.
    
    Security Scoring Model (100 points, deductions applied):
    
    Antivirus Protection (40 points maximum):
    - No antivirus installed: -40 points (critical vulnerability)
    - Antivirus disabled: -30 points (severe risk)
    - Antivirus enabled: 0 deduction
    
    Firewall Protection (30 points maximum):
    - Any firewall profile disabled: -30 points
    - All profiles enabled: 0 deduction
    
    Disk Encryption (15 points maximum):
    - BitLocker not enabled on C: -15 points
    - BitLocker protection on: 0 deduction
    
    Protocol Security (10 points maximum):
    - SMBv1 protocol enabled: -10 points (known vulnerability)
    - SMBv1 disabled: 0 deduction
    
    Patch Compliance (15 points maximum):
    - Critical patches missing: -15 points
    - All critical patches installed: 0 deduction
    
    Score Interpretation:
    - 90-100: Excellent security posture
    - 75-89: Good security posture
    - 60-74: Fair security, gaps exist
    - Below 60: Poor security, immediate action required

.PARAMETER SecurityScoreField
    NinjaRMM custom field name to store the security score (0-100).
    Default: OPSSecurityScore

.PARAMETER LastUpdateField
    NinjaRMM custom field name to store the last update timestamp.
    Default: OPSLastScoreUpdate

.EXAMPLE
    .\SecurityAnalyzer.ps1

    Runs security analysis with default custom field names.

.EXAMPLE
    .\SecurityAnalyzer.ps1 -SecurityScoreField "SecurityScore" -LastUpdateField "SecurityLastUpdate"

    Runs security analysis with custom field names.

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : SecurityAnalyzer.ps1
    Prerequisite   : PowerShell 5.1 or higher, Admin privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    Frequency      : Daily
    Runtime        : Approximately 30 seconds
    Timeout        : 90 seconds
    Context        : SYSTEM
    
    Change Log:
    - 3.0.0: V3 migration with standardized logging, error handling, and custom field management
    - 4.0: Previous version with basic scoring
    
    Dependencies:
    - WMI/CIM: root/SecurityCenter2 AntiVirusProduct class
    - Get-NetFirewallProfile cmdlet
    - Get-BitLockerVolume cmdlet (requires BitLocker feature)
    - Get-WindowsOptionalFeature cmdlet
    - Microsoft.Update.Session COM object
    
    Security Standards Alignment:
    - CIS Controls: Antivirus, firewall, encryption, patching
    - NIST Cybersecurity Framework: Protect function
    - Microsoft Security Baseline recommendations
    
    Exit Codes:
    - 0: Script completed successfully
    - 1: Script encountered errors
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$SecurityScoreField = "OPSSecurityScore",
    
    [Parameter()]
    [String]$LastUpdateField = "OPSLastScoreUpdate"
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
            'WARNING' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:securityScoreField -and $env:securityScoreField -notlike "null") {
        $SecurityScoreField = $env:securityScoreField
    }
    if ($env:lastUpdateField -and $env:lastUpdateField -notlike "null") {
        $LastUpdateField = $env:lastUpdateField
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
        Write-Log "Starting Security Analyzer (v3.0.0)"

        $securityScore = 100
        $findings = @()
        $controlStatus = @{}

        Write-Log "Checking antivirus protection..."
        try {
            $avProduct = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
            
            if (-not $avProduct) {
                $securityScore -= 40
                $findings += "No antivirus installed (-40 points)"
                $controlStatus['Antivirus'] = 'Not Installed'
                Write-Log "No antivirus product detected" -Level CRITICAL
            } 
            elseif ($avProduct.productState -band 0x1000) {
                $controlStatus['Antivirus'] = "Enabled ($($avProduct.displayName))"
                Write-Log "Antivirus is enabled: $($avProduct.displayName)"
            } 
            else {
                $securityScore -= 30
                $findings += "Antivirus disabled: $($avProduct.displayName) (-30 points)"
                $controlStatus['Antivirus'] = 'Disabled'
                Write-Log "Antivirus is disabled: $($avProduct.displayName)" -Level CRITICAL
            }
        }
        catch {
            $securityScore -= 40
            $findings += "Antivirus check failed (-40 points)"
            $controlStatus['Antivirus'] = 'Check Failed'
            Write-Log "Failed to check antivirus status: $_" -Level ERROR
        }

        Write-Log "Checking firewall configuration..."
        try {
            $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            $fwDisabled = ($firewallProfiles | Where-Object { $_.Enabled -eq $false })
            $fwDisabledCount = $fwDisabled.Count
            
            if ($fwDisabledCount -gt 0) {
                $securityScore -= 30
                $disabledProfiles = ($fwDisabled.Name -join ', ')
                $findings += "$fwDisabledCount firewall profile(s) disabled: $disabledProfiles (-30 points)"
                $controlStatus['Firewall'] = "$fwDisabledCount profile(s) disabled"
                Write-Log "Firewall profiles disabled: $disabledProfiles" -Level CRITICAL
            } 
            else {
                $controlStatus['Firewall'] = 'All profiles enabled'
                Write-Log "All firewall profiles enabled"
            }
        }
        catch {
            $securityScore -= 30
            $findings += "Firewall check failed (-30 points)"
            $controlStatus['Firewall'] = 'Check Failed'
            Write-Log "Failed to check firewall status: $_" -Level ERROR
        }

        Write-Log "Checking BitLocker encryption..."
        try {
            $bitlocker = Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue
            if ($bitlocker -and $bitlocker.ProtectionStatus -eq 'On') {
                $controlStatus['BitLocker'] = 'Enabled'
                Write-Log "BitLocker protection is ON for C: drive"
            } 
            else {
                $securityScore -= 15
                $findings += "BitLocker not enabled on C: drive (-15 points)"
                $controlStatus['BitLocker'] = 'Disabled'
                Write-Log "BitLocker protection is OFF on C: drive" -Level WARNING
            }
        }
        catch {
            $securityScore -= 15
            $findings += "BitLocker check failed, assuming not protected (-15 points)"
            $controlStatus['BitLocker'] = 'Check Failed'
            Write-Log "Unable to check BitLocker status: $_" -Level WARNING
        }

        Write-Log "Checking SMBv1 protocol status..."
        try {
            $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
            if ($smbv1 -and $smbv1.State -eq 'Enabled') {
                $securityScore -= 10
                $findings += "SMBv1 protocol enabled (known vulnerability, -10 points)"
                $controlStatus['SMBv1'] = 'Enabled (Vulnerable)'
                Write-Log "SMBv1 protocol is enabled" -Level WARNING
            } 
            else {
                $controlStatus['SMBv1'] = 'Disabled'
                Write-Log "SMBv1 protocol is disabled"
            }
        }
        catch {
            $controlStatus['SMBv1'] = 'Unable to check'
            Write-Log "Unable to check SMBv1 status, assuming safe: $_"
        }

        Write-Log "Checking for critical Windows updates..."
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 AND Type='Software'")
            $criticalUpdates = ($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq 'Critical' })
            $criticalCount = $criticalUpdates.Count
            
            if ($criticalCount -gt 0) {
                $securityScore -= 15
                $findings += "$criticalCount critical update(s) missing (-15 points)"
                $controlStatus['CriticalUpdates'] = "$criticalCount missing"
                Write-Log "$criticalCount critical update(s) pending installation" -Level WARNING
            } 
            else {
                $controlStatus['CriticalUpdates'] = 'All installed'
                Write-Log "No critical updates pending"
            }
        }
        catch {
            Write-Log "Unable to check Windows Update status: $_" -Level WARNING
            $controlStatus['CriticalUpdates'] = 'Unable to check'
        }

        if ($securityScore -lt 0) { $securityScore = 0 }
        if ($securityScore -gt 100) { $securityScore = 100 }

        $assessment = switch ($securityScore) {
            { $_ -ge 90 } { 'Excellent security posture' }
            { $_ -ge 75 } { 'Good security posture' }
            { $_ -ge 60 } { 'Fair security - gaps exist, remediation recommended' }
            default { 'Poor security - immediate action required' }
        }

        Write-Log "Security score calculated: $securityScore/100"
        Write-Log "Assessment: $assessment"

        Write-Log "Updating NinjaRMM custom fields..."
        try {
            Set-NinjaProperty -Name $SecurityScoreField -Value $securityScore -ErrorAction Stop
            Write-Log "Security score saved to field: $SecurityScoreField"
        }
        catch {
            Write-Log "Failed to update security score field: $_" -Level ERROR
        }

        try {
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Set-NinjaProperty -Name $LastUpdateField -Value $timestamp -ErrorAction Stop
            Write-Log "Last update timestamp saved to field: $LastUpdateField"
        }
        catch {
            Write-Log "Failed to update timestamp field: $_" -Level ERROR
        }

        Write-Log "SECURITY CONTROL STATUS:"
        foreach ($control in $controlStatus.Keys | Sort-Object) {
            Write-Log "  $control : $($controlStatus[$control])"
        }

        if ($findings.Count -gt 0) {
            Write-Log "SECURITY GAPS IDENTIFIED:"
            $findings | ForEach-Object { Write-Log "  - $_" -Level WARNING }
        } 
        else {
            Write-Log "All security controls passed validation"
        }

        Write-Log "Security analysis completed successfully"
    }
    catch {
        Write-Log "Security analysis failed with unexpected error: $_" -Level ERROR
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
