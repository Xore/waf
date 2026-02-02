<#
.SYNOPSIS
    NinjaRMM Script 16: Print Server Monitor

.DESCRIPTION
    Monitors print server health, printers, and print queues.
    Part of Infrastructure Monitoring suite - Server Roles.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - printServerInstalled (Checkbox)
    - printPrinterCount (Integer)
    - printQueuedJobs (Integer)
    - printHealthStatus (Dropdown)
    
    Framework Version: 4.0
    Last Updated: February 2, 2026
#>

param()

try {
    $printRole = Get-WindowsFeature -Name Print-Services -ErrorAction SilentlyContinue

    if (-not $printRole -or -not $printRole.Installed) {
        Ninja-Property-Set printServerInstalled $false
        Write-Output "Print Server role not installed"
        exit 0
    }

    Ninja-Property-Set printServerInstalled $true

    $printers = Get-Printer -ErrorAction SilentlyContinue
    $printerCount = $printers.Count

    Ninja-Property-Set printPrinterCount $printerCount

    $queuedJobs = 0
    foreach ($printer in $printers) {
        $jobs = Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue
        if ($jobs) {
            $queuedJobs += $jobs.Count
        }
    }

    Ninja-Property-Set printQueuedJobs $queuedJobs

    if ($queuedJobs -lt 10) {
        $health = "Healthy"
    } elseif ($queuedJobs -lt 50) {
        $health = "Warning"
    } else {
        $health = "Critical"
    }

    Ninja-Property-Set printHealthStatus $health

    Write-Output "Print Server Health: $health | Printers: $printerCount | Queued Jobs: $queuedJobs"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set printHealthStatus "Unknown"
    exit 1
}
