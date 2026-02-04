<#
.SYNOPSIS
    Drift Detector - Configuration Drift and Unauthorized Software Detection

.DESCRIPTION
    Detects configuration drift by tracking changes to installed applications compared to an
    established baseline. Identifies unauthorized or unexpected software installations that may
    indicate policy violations, shadow IT, malware, or configuration management failures.
    
    Operates by maintaining an application baseline (list of all installed software) and
    comparing current installations against this baseline on each execution. New applications
    that appear since baseline establishment are flagged as drift.
    
    Drift Detection Methodology:
    
    1. Baseline Establishment (First Run):
    - Enumerates all installed applications from registry
    - Stores application list as baseline
    - Sets new app count to 0
    - No drift reported on first run
    
    2. Drift Detection (Subsequent Runs):
    - Enumerates current installed applications
    - Compares against stored baseline
    - Identifies applications not in baseline
    - Counts and reports new installations
    
    Application Sources Tracked:
    - Registry: HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
    - Includes: Windows Installer (MSI) packages
    - Includes: Setup.exe installed applications
    - Includes: Windows Store applications (if registered)
    
    Use Cases:
    - Security: Detect unauthorized software installations
    - Compliance: Verify software policy adherence
    - Change Management: Track application deployments
    - Shadow IT Detection: Identify user-installed software
    - Malware Detection: Flag unexpected executables
    - Configuration Drift: Monitor system state changes
    
    Limitations:
    - Portable applications not in registry are not detected
    - Baseline must be manually reset after authorized installations
    - Does not track application removals (only additions)
    - False positives possible from automatic updates

.NOTES
    Frequency: Daily
    Runtime: ~25 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - DRIFTBaselineApps (Text: comma-separated list of application names)
    - DRIFTNewAppsCount (Integer: count of new applications since baseline)
    
    Dependencies:
    - Windows Registry access (HKLM:\Software)
    - SYSTEM context for full application visibility
    
    Baseline Management:
    - First run establishes baseline automatically
    - Baseline persists until manually reset
    - To refresh baseline: Clear DRIFTBaselineApps field and re-run
    - Authorized deployments should trigger baseline update
    
    Integration Pattern:
    - Can trigger alerts when new apps detected
    - New app count can be used in compliance scoring
    - Drift events can initiate investigation workflows
    - Baseline updates can be scripted for change windows
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Drift Detector (v4.0)..."

    # Enumerate currently installed applications
    Write-Output "INFO: Enumerating installed applications from registry..."
    $currentApps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        Where-Object { $_.DisplayName } | 
        Select-Object -ExpandProperty DisplayName | 
        Sort-Object
    
    $currentAppCount = $currentApps.Count
    Write-Output "INFO: Found $currentAppCount installed applications"

    # Retrieve baseline
    Write-Output "INFO: Checking for existing baseline..."
    $baselineApps = Ninja-Property-Get DRIFTBaselineApps
    
    # First run: establish baseline
    if ([string]::IsNullOrEmpty($baselineApps)) {
        Write-Output "INFO: No baseline found - establishing initial baseline..."
        
        $appList = $currentApps -join ','
        Ninja-Property-Set DRIFTBaselineApps $appList
        Ninja-Property-Set DRIFTNewAppsCount 0
        
        Write-Output "SUCCESS: Baseline established with $currentAppCount applications"
        Write-Output "INFO: Future runs will detect drift from this baseline"
        Write-Output "BASELINE APPLICATIONS:"
        $currentApps | Select-Object -First 10 | ForEach-Object { Write-Output "  - $_" }
        
        if ($currentAppCount -gt 10) {
            Write-Output "  ... and $($currentAppCount - 10) more"
        }
        
        exit 0
    }

    # Subsequent runs: detect drift
    Write-Output "INFO: Baseline found - comparing current state to baseline..."
    $baselineList = $baselineApps -split ','
    $baselineCount = $baselineList.Count
    Write-Output "INFO: Baseline contains $baselineCount applications"
    
    # Identify new applications
    $newApps = $currentApps | Where-Object { $_ -notin $baselineList }
    $newAppCount = $newApps.Count
    
    # Identify removed applications (informational)
    $removedApps = $baselineList | Where-Object { $_ -notin $currentApps }
    $removedAppCount = $removedApps.Count

    # Update drift metrics
    Write-Output "INFO: Updating drift detection fields..."
    Ninja-Property-Set DRIFTNewAppsCount $newAppCount

    Write-Output "SUCCESS: Drift detection complete"
    Write-Output "DRIFT SUMMARY:"
    Write-Output "  - Baseline applications: $baselineCount"
    Write-Output "  - Current applications: $currentAppCount"
    Write-Output "  - New applications (drift): $newAppCount"
    Write-Output "  - Removed applications: $removedAppCount"

    if ($newAppCount -gt 0) {
        Write-Output "DRIFT DETECTED: $newAppCount new application(s) installed"
        Write-Output "NEW APPLICATIONS:"
        $newApps | ForEach-Object { Write-Output "  - $_" }
        
        Write-Output "RECOMMENDATION: Investigate new installations for authorization"
    } else {
        Write-Output "No configuration drift detected - system matches baseline"
    }
    
    if ($removedAppCount -gt 0) {
        Write-Output "INFO: $removedAppCount application(s) removed from baseline"
        Write-Output "REMOVED APPLICATIONS:"
        $removedApps | ForEach-Object { Write-Output "  - $_" }
    }

    exit 0
} catch {
    Write-Output "ERROR: Drift Detector failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
