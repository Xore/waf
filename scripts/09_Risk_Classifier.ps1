#!/usr/bin/env pwsh
# Script 09: Risk Classifier
# Purpose: Classify devices into risk categories based on multiple data sources
# Frequency: Every 4 hours
# Runtime: ~10 seconds
# Timeout: 60 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Risk Classifier (v4.0 Native-Enhanced)"

    $healthScore = Ninja-Property-Get OPSHealthScore
    if ([string]::IsNullOrEmpty($healthScore)) { $healthScore = 50 }

    $securityScore = Ninja-Property-Get OPSSecurityScore
    if ([string]::IsNullOrEmpty($securityScore)) { $securityScore = 50 }

    if ($healthScore -ge 70) {
        $healthLevel = "Healthy"
    } elseif ($healthScore -ge 40) {
        $healthLevel = "Degraded"
    } else {
        $healthLevel = "Critical"
    }

    if ($securityScore -ge 80) {
        $securityExposure = "Low"
    } elseif ($securityScore -ge 60) {
        $securityExposure = "Medium"
    } elseif ($securityScore -ge 40) {
        $securityExposure = "High"
    } else {
        $securityExposure = "Critical"
    }

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    try {
        $lastBackup = (Get-CimInstance -Namespace root\\WMI -Class MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue).PredictFailure
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
        $dataLossRisk = "Medium"
    }

    $rebootRequired = $false
    try {
        $rebootPending = (Test-Path "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Component Based Servicing\\RebootPending") -or
                         (Test-Path "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WindowsUpdate\\Auto Update\\RebootRequired")
        if ($rebootPending) {
            $rebootLevel = "High"
        } else {
            $rebootLevel = "None"
        }
    } catch {
        $rebootLevel = "None"
    }

    if ($securityScore -ge 80 -and $healthScore -ge 70) {
        $complianceFlag = "Compliant"
    } elseif ($securityScore -ge 60 -and $healthScore -ge 50) {
        $complianceFlag = "Warning"
    } elseif ($securityScore -ge 40) {
        $complianceFlag = "Non-Compliant"
    } else {
        $complianceFlag = "Critical"
    }

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
