#!/usr/bin/env pwsh
# Script 04: Security Analyzer
# Purpose: Calculate security posture score based on security controls
# Frequency: Daily
# Runtime: ~30 seconds
# Timeout: 90 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Security Analyzer (v4.0 Native-Enhanced)"

    $securityScore = 100

    $avProduct = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
    if (-not $avProduct) {
        $securityScore -= 40
        $avStatus = "Not Installed"
    } elseif ($avProduct.productState -band 0x1000) {
        $avStatus = "Enabled"
    } else {
        $securityScore -= 30
        $avStatus = "Disabled"
    }

    $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    $fwDisabled = ($firewallProfiles | Where-Object { $_.Enabled -eq $false }).Count
    if ($fwDisabled -gt 0) {
        $securityScore -= 30
    }

    try {
        $bitlocker = Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue
        if ($bitlocker.ProtectionStatus -ne 'On') {
            $securityScore -= 15
        }
    } catch {
        $securityScore -= 15
    }

    try {
        $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
        if ($smbv1.State -eq 'Enabled') {
            $securityScore -= 10
        }
    } catch {
    }

    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0 AND Type='Software'")
        $criticalUpdates = ($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq 'Critical' }).Count
        if ($criticalUpdates -gt 0) {
            $securityScore -= 15
        }
    } catch {
    }

    if ($securityScore -lt 0) { $securityScore = 0 }
    if ($securityScore -gt 100) { $securityScore = 100 }

    Ninja-Property-Set OPSSecurityScore $securityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Security Score = $securityScore"
    Write-Output "  Antivirus: $avStatus"
    Write-Output "  Firewall Disabled Profiles: $fwDisabled"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
