<#
.SYNOPSIS
    NinjaRMM Script 14: Local Admin Drift Analyzer

.DESCRIPTION
    Detects unauthorized local administrator changes.
    Compares current administrators against established baseline.

.NOTES
    Frequency: Daily
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - driftLocalAdminDrift (Checkbox)
    - driftLocalAdminDriftMagnitude (Text: None, Minor, Moderate, Significant)
    
    Prerequisites:
    - Run Script 18 (Baseline Refresh) first to establish baseline
    
    Framework Version: 4.0
    Last Updated: February 3, 2026
#>

param()

try {
    # Get current local administrators
    $currentAdmins = Get-LocalGroupMember -Group "Administrators" | 
        Select-Object -ExpandProperty Name

    # Get baseline from custom field
    $baselineAdmins = Ninja-Property-Get baseLocalAdmins

    if ([string]::IsNullOrEmpty($baselineAdmins)) {
        Write-Output "Baseline not established. Run Script 18 first."
        exit 0
    }

    # Parse baseline
    $baselineList = $baselineAdmins -split ','

    # Compare
    $added = $currentAdmins | Where-Object {$_ -notin $baselineList}
    $removed = $baselineList | Where-Object {$_ -notin $currentAdmins}

    $driftDetected = ($added.Count -gt 0 -or $removed.Count -gt 0)

    # Calculate magnitude
    $totalChanges = $added.Count + $removed.Count
    if ($totalChanges -eq 0) {
        $magnitude = "None"
    } elseif ($totalChanges -le 2) {
        $magnitude = "Minor"
    } elseif ($totalChanges -le 5) {
        $magnitude = "Moderate"
    } else {
        $magnitude = "Significant"
    }

    # Update custom fields
    Ninja-Property-Set driftLocalAdminDrift $driftDetected
    Ninja-Property-Set driftLocalAdminDriftMagnitude $magnitude

    if ($driftDetected) {
        $details = "Added: $($added -join ', ') | Removed: $($removed -join ', ')"
        Write-Output "Local admin drift detected: $details"
    } else {
        Write-Output "No local admin drift detected"
    }

} catch {
    Write-Output "Error: $_"
    exit 1
}
