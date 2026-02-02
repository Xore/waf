#!/usr/bin/env pwsh
# Script 10: Update Assessment Collector
# Purpose: Collect Windows Update compliance data and aggregate patch counts
# Frequency: Daily
# Runtime: ~30 seconds
# Timeout: 90 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Update Assessment Collector (v4.0 Native-Enhanced)"

    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    
    $searchResult = $updateSearcher.Search("IsInstalled=0 AND Type='Software'")
    
    $criticalCount = 0
    $importantCount = 0
    $optionalCount = 0
    
    foreach ($update in $searchResult.Updates) {
        switch ($update.MsrcSeverity) {
            'Critical' { $criticalCount++ }
            'Important' { $importantCount++ }
            'Moderate' { $optionalCount++ }
            'Low' { $optionalCount++ }
            default { $optionalCount++ }
        }
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $daysSinceReboot = [int]((Get-Date) - $os.LastBootUpTime).Days

    Ninja-Property-Set UPDMissingCriticalCount $criticalCount
    Ninja-Property-Set UPDMissingImportantCount $importantCount
    Ninja-Property-Set UPDMissingOptionalCount $optionalCount
    Ninja-Property-Set UPDDaysSinceLastReboot $daysSinceReboot

    Write-Output "SUCCESS: Update assessment complete"
    Write-Output "  Missing Critical: $criticalCount"
    Write-Output "  Missing Important: $importantCount"
    Write-Output "  Missing Optional: $optionalCount"
    Write-Output "  Days Since Reboot: $daysSinceReboot"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
