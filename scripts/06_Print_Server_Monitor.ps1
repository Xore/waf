<#
.SYNOPSIS
    NinjaRMM Script 6: Print Server Monitor

.DESCRIPTION
    Monitors print server printers, queues, and job status.
    Tracks printer health and identifies stuck print jobs.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~25 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - psPrinterCount (Integer)
    - psJobsQueued (Integer)
    - psStuckJobs (Integer)
    - psHealthStatus (Dropdown)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    # Check if Print Services role is installed
    $printRole = Get-WindowsFeature -Name Print-Services -ErrorAction SilentlyContinue

    if (-not $printRole -or -not $printRole.Installed) {
        Ninja-Property-Set psPrintServerInstalled $false
        Write-Output "Print Services role not installed"
        exit 0
    }

    Ninja-Property-Set psPrintServerInstalled $true

    # Get all printers (excluding fax and XPS)
    $printers = Get-Printer -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch 'Fax|XPS|OneNote|PDF'
    }

    $printerCount = $printers.Count
    Ninja-Property-Set psPrinterCount $printerCount

    # Count total print jobs
    $allJobs = Get-PrintJob -ErrorAction SilentlyContinue
    $totalJobs = if ($allJobs) { $allJobs.Count } else { 0 }

    Ninja-Property-Set psJobsQueued $totalJobs

    # Identify stuck jobs (submitted more than 30 minutes ago)
    $stuckThreshold = (Get-Date).AddMinutes(-30)
    $stuckJobs = 0

    if ($allJobs) {
        $stuckJobs = ($allJobs | Where-Object {
            $_.SubmittedTime -lt $stuckThreshold
        }).Count
    }

    Ninja-Property-Set psStuckJobs $stuckJobs

    # Check printer errors
    $printerErrors = ($printers | Where-Object {
        $_.PrinterStatus -match 'Error|Offline|PaperOut|PaperJam'
    }).Count

    # Determine health status
    if ($printerErrors -eq 0 -and $stuckJobs -eq 0) {
        $health = "Healthy"
    } elseif ($printerErrors -le 2 -or $stuckJobs -le 3) {
        $health = "Warning"
    } else {
        $health = "Critical"
    }

    Ninja-Property-Set psHealthStatus $health

    Write-Output "Print Server Health: $health | Printers: $printerCount | Jobs: $totalJobs | Stuck: $stuckJobs | Errors: $printerErrors"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set psHealthStatus "Unknown"
    exit 1
}
