<#
.SYNOPSIS
    Update Assessment Collector - Windows Update Compliance and Patch Status

.DESCRIPTION
    Collects comprehensive Windows Update compliance data by querying available updates and
    categorizing them by severity (Critical, Important, Optional). Provides patch management
    metrics essential for security compliance and vulnerability management.
    
    Uses Windows Update Agent COM interface to enumerate all available software updates,
    classify them by Microsoft Security Response Center (MSRC) severity ratings, and track
    reboot requirements based on system uptime.
    
    Severity Classifications (MSRC Standard):
    
    Critical Updates:
    - Vulnerabilities exploitable with no user interaction
    - Wormable vulnerabilities
    - Remote code execution flaws
    - Requires immediate installation
    
    Important Updates:
    - Vulnerabilities requiring user interaction
    - Privilege escalation flaws
    - Information disclosure issues
    - Should be installed within 30 days
    
    Optional Updates (Moderate/Low):
    - Non-security updates
    - Feature enhancements
    - Minor bug fixes
    - Install at convenience
    
    Reboot Tracking:
    - Measures days since last reboot
    - Indicates pending patch installation
    - Compliance threshold: reboot within 30 days of patching

.NOTES
    Frequency: Daily
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - UPDMissingCriticalCount (Integer: count of critical patches not installed)
    - UPDMissingImportantCount (Integer: count of important patches not installed)
    - UPDMissingOptionalCount (Integer: count of optional updates not installed)
    - UPDDaysSinceLastReboot (Integer: days since last system boot)
    
    Dependencies:
    - Microsoft.Update.Session COM object
    - Windows Update service running
    - WMI/CIM: Win32_OperatingSystem
    
    Compliance Standards:
    - CIS Controls: Continuous Vulnerability Management
    - NIST SP 800-53: SI-2 Flaw Remediation
    - PCI-DSS: Requirement 6.2 (Security patches within 30 days)
    - HIPAA: Technical Safeguards
    
    Use Cases:
    - Patch compliance reporting
    - Vulnerability exposure tracking
    - Security audit preparation
    - Change management scheduling
    - Risk prioritization
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Update Assessment Collector (v4.0)..."

    # Initialize Windows Update session
    Write-Output "INFO: Initializing Windows Update Agent..."
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    
    # Search for available updates
    Write-Output "INFO: Searching for available software updates..."
    $searchResult = $updateSearcher.Search("IsInstalled=0 AND Type='Software'")
    $totalUpdates = $searchResult.Updates.Count
    Write-Output "INFO: Found $totalUpdates available update(s)"
    
    # Initialize counters
    $criticalCount = 0
    $importantCount = 0
    $optionalCount = 0
    
    # Classify updates by severity
    Write-Output "INFO: Classifying updates by MSRC severity..."
    foreach ($update in $searchResult.Updates) {
        $severity = $update.MsrcSeverity
        $title = $update.Title
        
        switch ($severity) {
            'Critical' { 
                $criticalCount++
                Write-Output "  CRITICAL: $title"
            }
            'Important' { 
                $importantCount++
                Write-Output "  IMPORTANT: $title"
            }
            'Moderate' { 
                $optionalCount++
            }
            'Low' { 
                $optionalCount++
            }
            default { 
                $optionalCount++
            }
        }
    }

    # Calculate reboot status
    Write-Output "INFO: Calculating days since last reboot..."
    $os = Get-CimInstance Win32_OperatingSystem
    $daysSinceReboot = [int]((Get-Date) - $os.LastBootUpTime).Days
    $lastBoot = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
    Write-Output "INFO: Last boot: $lastBoot ($daysSinceReboot days ago)"

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating patch compliance fields..."
    Ninja-Property-Set UPDMissingCriticalCount $criticalCount
    Ninja-Property-Set UPDMissingImportantCount $importantCount
    Ninja-Property-Set UPDMissingOptionalCount $optionalCount
    Ninja-Property-Set UPDDaysSinceLastReboot $daysSinceReboot

    Write-Output "SUCCESS: Update assessment complete"
    Write-Output "PATCH COMPLIANCE SUMMARY:"
    Write-Output "  - Missing Critical: $criticalCount"
    Write-Output "  - Missing Important: $importantCount"
    Write-Output "  - Missing Optional: $optionalCount"
    Write-Output "  - Days Since Reboot: $daysSinceReboot"
    
    # Provide compliance assessment
    if ($criticalCount -eq 0 -and $importantCount -eq 0) {
        Write-Output "COMPLIANCE STATUS: Excellent - all security patches installed"
    } elseif ($criticalCount -gt 0) {
        Write-Output "COMPLIANCE STATUS: Non-Compliant - critical patches missing (immediate action required)"
    } elseif ($importantCount -gt 5) {
        Write-Output "COMPLIANCE STATUS: Poor - multiple important patches missing"
    } else {
        Write-Output "COMPLIANCE STATUS: Fair - some important patches missing"
    }
    
    if ($daysSinceReboot -gt 30) {
        Write-Output "REBOOT STATUS: Overdue - system has not rebooted in over 30 days"
    } elseif ($daysSinceReboot -gt 14) {
        Write-Output "REBOOT STATUS: Consider rebooting to finalize patch installation"
    } else {
        Write-Output "REBOOT STATUS: Acceptable"
    }

    exit 0
} catch {
    Write-Output "ERROR: Update Assessment Collector failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
