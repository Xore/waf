<#
.SYNOPSIS
    Risk Classifier - Device Risk Assessment and Classification

.DESCRIPTION
    Classifies devices into risk categories based on multiple data sources including
    health scores, security posture, disk space, backup status, and compliance flags.
    Provides comprehensive risk analysis across five key dimensions: health level,
    security exposure, data loss risk, reboot requirements, and compliance status.
    
    Analyzes device metrics and assigns risk levels to enable proactive management
    and prioritization of remediation efforts. Integrates with health and security
    scoring systems to provide unified risk assessment.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~10 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - RISKHealthLevel (Text: Healthy, Degraded, Critical)
    - RISKRebootLevel (Text: None, High)
    - RISKSecurityExposure (Text: Low, Medium, High, Critical)
    - RISKComplianceFlag (Text: Compliant, Warning, Non-Compliant, Critical)
    - RISKDataLossRisk (Text: Low, Medium, High, Critical)
    - RISKLastRiskAssessment (Text: timestamp in format yyyy-MM-dd HH:mm:ss)
    
    Dependencies:
    - OPSHealthScore (requires 01_Health_Score_Calculator.ps1)
    - OPSSecurityScore (requires 04_Security_Analyzer.ps1)
    
    Risk Classification Logic:
    Health Level:
      - Healthy: Score >= 70
      - Degraded: Score 40-69
      - Critical: Score < 40
    
    Security Exposure:
      - Low: Score >= 80
      - Medium: Score 60-79
      - High: Score 40-59
      - Critical: Score < 40
    
    Data Loss Risk:
      - Low: Disk > 20% free, no SMART warnings
      - Medium: Disk 10-20% free or unknown backup status
      - High: Disk 5-10% free or SMART warning detected
      - Critical: Disk < 5% free
    
    Compliance Flag:
      - Compliant: Security >= 80 AND Health >= 70
      - Warning: Security >= 60 AND Health >= 50
      - Non-Compliant: Security >= 40
      - Critical: Security < 40
    
    Framework Version: 4.0
    Last Updated: February 3, 2026
#>

try {
    Write-Output "Starting Risk Classifier (v4.0 Native-Enhanced)"

    # Get health score from health monitor
    $healthScore = Ninja-Property-Get OPSHealthScore
    if ([string]::IsNullOrEmpty($healthScore)) { $healthScore = 50 }

    # Get security score from security analyzer
    $securityScore = Ninja-Property-Get OPSSecurityScore
    if ([string]::IsNullOrEmpty($securityScore)) { $securityScore = 50 }

    # Classify health level
    if ($healthScore -ge 70) {
        $healthLevel = "Healthy"
    } elseif ($healthScore -ge 40) {
        $healthLevel = "Degraded"
    } else {
        $healthLevel = "Critical"
    }

    # Classify security exposure
    if ($securityScore -ge 80) {
        $securityExposure = "Low"
    } elseif ($securityScore -ge 60) {
        $securityExposure = "Medium"
    } elseif ($securityScore -ge 40) {
        $securityExposure = "High"
    } else {
        $securityExposure = "Critical"
    }

    # Assess data loss risk based on disk space and SMART status
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    try {
        # Check for SMART warnings indicating potential drive failure
        $lastBackup = (Get-CimInstance -Namespace root\WMI -Class MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue).PredictFailure
        if ($lastBackup) {
            $dataLossRisk = "High"
        } elseif ($diskFreePercent -lt 5) {
            $dataLossRisk = "Critical"
        } elseif ($diskFreePercent -lt 10) {
            $dataLossRisk = "High"
        } elseif ($diskFreePercent -lt 20) {
            $dataLossRisk = "Medium"
        } else {
            $dataLossRisk = "Low"
        }
    } catch {
        # If SMART check fails, base risk only on disk space
        $dataLossRisk = "Medium"
    }

    # Check for pending reboot
    $rebootRequired = $false
    try {
        $rebootPending = (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -or
                         (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")
        if ($rebootPending) {
            $rebootLevel = "High"
        } else {
            $rebootLevel = "None"
        }
    } catch {
        $rebootLevel = "None"
    }

    # Determine compliance flag based on combined health and security
    if ($securityScore -ge 80 -and $healthScore -ge 70) {
        $complianceFlag = "Compliant"
    } elseif ($securityScore -ge 60 -and $healthScore -ge 50) {
        $complianceFlag = "Warning"
    } elseif ($securityScore -ge 40) {
        $complianceFlag = "Non-Compliant"
    } else {
        $complianceFlag = "Critical"
    }

    # Update NinjaRMM custom fields
    Ninja-Property-Set RISKHealthLevel $healthLevel
    Ninja-Property-Set RISKRebootLevel $rebootLevel
    Ninja-Property-Set RISKSecurityExposure $securityExposure
    Ninja-Property-Set RISKComplianceFlag $complianceFlag
    Ninja-Property-Set RISKDataLossRisk $dataLossRisk
    Ninja-Property-Set RISKLastRiskAssessment (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Risk classification complete"
    Write-Output "  Health Level: $healthLevel"
    Write-Output "  Security Exposure: $securityExposure"
    Write-Output "  Data Loss Risk: $dataLossRisk"
    Write-Output "  Compliance: $complianceFlag"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
