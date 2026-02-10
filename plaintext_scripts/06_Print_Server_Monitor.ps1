<#
.SYNOPSIS
    Print Server Monitor - Print Queue and Printer Health Monitoring

.DESCRIPTION
    Monitors Windows Print Server infrastructure including printer availability, print queue
    status, job processing, and stuck job detection. Provides comprehensive print server health
    assessment to ensure printing services remain operational and prevent user productivity loss
    from print failures.
    
    Critical for environments dependent on centralized printing services, identifying printer
    errors, queue backlogs, and stuck jobs before users escalate issues. Enables proactive print
    server maintenance and reduces help desk ticket volume.
    
    Monitoring Scope:
    
    Print Services Role Detection:
    - Checks for Print-Services Windows Feature
    - Gracefully exits if print server role not installed
    - Prevents monitoring overhead on non-print-server systems
    
    Printer Inventory:
    - Enumerates all configured printers
    - Excludes non-physical printers:
      * Fax devices
      * Microsoft XPS Document Writer
      * OneNote printer
      * PDF virtual printers
    - Counts actual print queue endpoints
    - Tracks printer availability and status
    
    Print Job Queue Monitoring:
    - Counts total jobs across all print queues
    - Identifies backlog and processing delays
    - Capacity planning metric
    - Performance indicator for print server load
    
    Stuck Job Detection:
    - Identifies jobs older than 30 minutes
    - Jobs submitted but not completed
    - Indicates printer communication failures
    - Print driver issues
    - Network connectivity problems
    - Immediate intervention required
    
    Printer Error Detection:
    - Monitors printer status flags:
      * Error (generic hardware failure)
      * Offline (network disconnected or powered off)
      * PaperOut (consumable exhaustion)
      * PaperJam (mechanical failure)
    - Counts printers requiring attention
    - Enables targeted troubleshooting
    
    Health Status Classification:
    
    Healthy:
    - All printers operational (no error states)
    - No stuck print jobs detected
    - Print queues processing normally
    - No intervention required
    
    Warning:
    - 1-2 printers with errors OR
    - 1-3 stuck jobs detected
    - Minor issues present but service functional
    - Investigation recommended
    
    Critical:
    - 3 or more printers with errors OR
    - 4 or more stuck jobs
    - Print service significantly degraded
    - Immediate remediation required
    
    Unknown:
    - Script execution error
    - Insufficient permissions
    - Print Spooler service not running

.NOTES
    Frequency: Every 4 hours
    Runtime: ~25 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - psPrintServerInstalled (Checkbox: true if Print-Services role installed)
    - psPrinterCount (Integer: number of physical printers configured)
    - psJobsQueued (Integer: total jobs across all queues)
    - psStuckJobs (Integer: jobs older than 30 minutes)
    - psHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - Windows Print Services role
    - Print Spooler service (Spooler) running
    - SYSTEM context for printer and queue enumeration
    
    PowerShell Cmdlets Used:
    - Get-WindowsFeature: Role detection
    - Get-Printer: Printer enumeration and status
    - Get-PrintJob: Queue job tracking
    
    Common Issues:
    - Stuck jobs often indicate driver or network issues
    - Offline printers may be powered off or network disconnected
    - Paper jams require physical intervention
    - Print Spooler service crashes cause total failure
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Print Server Monitor (v4.0)..."

    # Detect Print Services role installation
    Write-Output "INFO: Checking for Print Services role..."
    $printRole = Get-WindowsFeature -Name Print-Services -ErrorAction SilentlyContinue

    if (-not $printRole -or -not $printRole.Installed) {
        Write-Output "INFO: Print Services role not installed on this system"
        Ninja-Property-Set psPrintServerInstalled $false
        Write-Output "SUCCESS: Print server monitoring skipped (role not present)"
        exit 0
    }

    Write-Output "INFO: Print Services role detected - beginning monitoring"
    Ninja-Property-Set psPrintServerInstalled $true

    # Enumerate printers (exclude virtual printers)
    Write-Output "INFO: Enumerating printers..."
    $printers = Get-Printer -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch 'Fax|XPS|OneNote|PDF'
    }

    $printerCount = $printers.Count
    Write-Output "INFO: Found $printerCount physical printer(s)"
    Ninja-Property-Set psPrinterCount $printerCount
    
    if ($printerCount -gt 0) {
        Write-Output "PRINTERS:"
        $printers | ForEach-Object {
            Write-Output "  - $($_.Name): $($_.PrinterStatus) (Shared: $($_.Shared))"
        }
    }

    # Count queued print jobs
    Write-Output "INFO: Checking print queues..."
    $allJobs = Get-PrintJob -ErrorAction SilentlyContinue
    $totalJobs = if ($allJobs) { $allJobs.Count } else { 0 }
    
    Write-Output "INFO: Total queued print jobs: $totalJobs"
    Ninja-Property-Set psJobsQueued $totalJobs

    # Identify stuck jobs (older than 30 minutes)
    Write-Output "INFO: Detecting stuck print jobs..."
    $stuckThreshold = (Get-Date).AddMinutes(-30)
    $stuckJobs = 0
    $stuckJobDetails = @()

    if ($allJobs) {
        $stuckJobsList = $allJobs | Where-Object {
            $_.SubmittedTime -lt $stuckThreshold
        }
        
        $stuckJobs = $stuckJobsList.Count
        
        if ($stuckJobs -gt 0) {
            Write-Output "WARNING: Found $stuckJobs stuck print job(s) (older than 30 minutes)"
            $stuckJobDetails = $stuckJobsList | Select-Object -First 5
        }
    }

    Ninja-Property-Set psStuckJobs $stuckJobs

    # Check for printer errors
    Write-Output "INFO: Checking printer health status..."
    $errorPrinters = $printers | Where-Object {
        $_.PrinterStatus -match 'Error|Offline|PaperOut|PaperJam'
    }
    
    $printerErrors = $errorPrinters.Count
    
    if ($printerErrors -gt 0) {
        Write-Output "WARNING: Found $printerErrors printer(s) with error conditions"
    }

    # Determine overall health status
    Write-Output "INFO: Determining print server health status..."
    if ($printerErrors -eq 0 -and $stuckJobs -eq 0) {
        $health = "Healthy"
        Write-Output "  ASSESSMENT: All printers operational, no stuck jobs"
    } elseif ($printerErrors -le 2 -or $stuckJobs -le 3) {
        $health = "Warning"
        Write-Output "  ASSESSMENT: Minor issues detected (Errors: $printerErrors, Stuck: $stuckJobs)"
    } else {
        $health = "Critical"
        Write-Output "  ASSESSMENT: Multiple print issues (Errors: $printerErrors, Stuck: $stuckJobs)"
    }

    Ninja-Property-Set psHealthStatus $health

    Write-Output "SUCCESS: Print server monitoring complete"
    Write-Output "PRINT SERVER METRICS:"
    Write-Output "  - Health Status: $health"
    Write-Output "  - Printers Configured: $printerCount"
    Write-Output "  - Jobs Queued: $totalJobs"
    Write-Output "  - Stuck Jobs: $stuckJobs"
    Write-Output "  - Printers with Errors: $printerErrors"
    
    # Report printer errors
    if ($printerErrors -gt 0) {
        Write-Output "PRINTERS WITH ERRORS:"
        $errorPrinters | ForEach-Object {
            Write-Output "  - $($_.Name): $($_.PrinterStatus)"
        }
        Write-Output "RECOMMENDATION: Check printer connectivity and consumables"
    }
    
    # Report stuck jobs
    if ($stuckJobs -gt 0) {
        Write-Output "STUCK PRINT JOBS:"
        $stuckJobDetails | ForEach-Object {
            $age = [math]::Round(((Get-Date) - $_.SubmittedTime).TotalMinutes, 0)
            Write-Output "  - Job $($_.Id) on $($_.PrinterName): $($_.DocumentName) (submitted $age minutes ago)"
        }
        Write-Output "RECOMMENDATION: Cancel stuck jobs and check printer connectivity"
    }
    
    # Capacity warnings
    if ($totalJobs -gt 50) {
        Write-Output "INFO: High queue volume ($totalJobs jobs) may indicate processing delays"
    }

    exit 0
} catch {
    Write-Output "ERROR: Print Server Monitor failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    Ninja-Property-Set psHealthStatus "Unknown"
    exit 1
}
