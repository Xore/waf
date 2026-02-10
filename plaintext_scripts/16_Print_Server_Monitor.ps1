<#
.SYNOPSIS
    Print Server Monitor - Print Queue Health Monitoring

.DESCRIPTION
    Monitors Windows Print Server with simplified queue-based health assessment. Tracks printer
    count and total queued jobs across all printers.
    
    Alternative to 06_Print_Server_Monitor.ps1 with different field names and queue-based health
    thresholds instead of stuck job detection.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - printServerInstalled (Checkbox)
    - printPrinterCount (Integer)
    - printQueuedJobs (Integer: total across all printers)
    - printHealthStatus (Dropdown: Healthy <10, Warning <50, Critical 50+)
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

param()

try {
    Write-Output "Starting Print Server Monitor (v4.0 - Script 16)..."

    Write-Output "INFO: Checking for Print Services role..."
    $printRole = Get-WindowsFeature -Name Print-Services -ErrorAction SilentlyContinue

    if (-not $printRole -or -not $printRole.Installed) {
        Write-Output "INFO: Print Server role not installed"
        Ninja-Property-Set printServerInstalled $false
        exit 0
    }

    Write-Output "INFO: Print Services detected"
    Ninja-Property-Set printServerInstalled $true

    Write-Output "INFO: Enumerating printers..."
    $printers = Get-Printer -ErrorAction SilentlyContinue
    $printerCount = $printers.Count

    Write-Output "INFO: Found $printerCount printer(s)"
    Ninja-Property-Set printPrinterCount $printerCount

    Write-Output "INFO: Counting queued jobs..."
    $queuedJobs = 0
    foreach ($printer in $printers) {
        $jobs = Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue
        if ($jobs) {
            $queuedJobs += $jobs.Count
        }
    }

    Write-Output "INFO: Total queued jobs: $queuedJobs"
    Ninja-Property-Set printQueuedJobs $queuedJobs

    if ($queuedJobs -lt 10) {
        $health = "Healthy"
        Write-Output "  ASSESSMENT: Normal queue volume"
    } elseif ($queuedJobs -lt 50) {
        $health = "Warning"
        Write-Output "  ASSESSMENT: Elevated queue volume"
    } else {
        $health = "Critical"
        Write-Output "  ASSESSMENT: High queue backlog"
    }

    Ninja-Property-Set printHealthStatus $health

    Write-Output "SUCCESS: Print Server Health: $health | Printers: $printerCount | Queued Jobs: $queuedJobs"

    exit 0
} catch {
    Write-Output "ERROR: $_"
    Write-Output "$($_.ScriptStackTrace)"
    Ninja-Property-Set printHealthStatus "Unknown"
    exit 1
}
