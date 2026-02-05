<#
.SYNOPSIS
    Print Server Monitor - Windows Print Server Queue and Printer Health Monitoring

.DESCRIPTION
    Monitors Windows Print Server infrastructure including printer inventory, print job queues,
    stuck jobs, printer errors, offline printers, and spooler health. Essential for maintaining
    print service availability and detecting queue backlogs.
    
    Critical for preventing print job backlogs that impact business operations, detecting offline
    printers before users report issues, and identifying stuck jobs that block print queues.
    Foundational for enterprise printing infrastructure management.
    
    Monitoring Scope:
    
    Print Server Role Detection:
    - Checks Print-Server Windows feature
    - Verifies printer management PowerShell cmdlets
    - Gracefully exits if role not installed
    
    Printer Inventory:
    - Enumerates all printers via Get-Printer
    - Counts total configured printers
    - Tracks printer status: Normal, Offline, Error, etc.
    - Capacity and configuration management metric
    
    Offline Printer Detection:
    - Identifies printers with Offline or Error status
    - Offline printers cannot accept jobs
    - Critical metric for service availability
    
    Printer Error Monitoring:
    - Detects error conditions: PaperJam, PaperOut, TonerLow, DoorOpen
    - Hardware issue early warning
    - Prevents job failures
    
    Print Queue Analysis:
    - Queries Get-PrintJob for all printers
    - Counts total jobs across all queues
    - Aggregates queue depth for capacity planning
    
    Stuck Job Detection:
    - Identifies jobs with error states: Error, Paused, Blocked, UserIntervention
    - Detects jobs older than 1 hour (time-based stuck detection)
    - Stuck jobs block queue and prevent printing
    - Critical metric for queue health
    
    Printer Summary Reporting:
    - HTML formatted printer table
    - Includes printer name, status, job count, driver name
    - Color-coded status: green (Normal), orange (PaperJam/PaperOut), red (Offline/Error)
    - Per-printer job count for load balancing
    - Summary statistics at bottom
    
    Spooler Error Detection:
    - Queries System event log for PrintService errors (24h)
    - Provider: Microsoft-Windows-PrintService
    - Severity: Critical (Level 1) and Error (Level 2)
    - Detects spooler crashes, driver failures
    
    Health Status Classification:
    
    Healthy:
    - All printers online
    - No stuck jobs
    - No printer errors
    - Normal operations
    
    Warning:
    - Printer errors detected (paper jams, toner low)
    - Some stuck jobs (1-5)
    - Action recommended
    
    Critical:
    - Offline printers (service unavailable)
    - Many stuck jobs (>5)
    - Queue blocked
    
    Unknown:
    - Print Server role not installed
    - Script execution error
    - Query failures

.NOTES
    Frequency: Daily (config), Every 4 hours (status)
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - PRINTPrintServerRole (Checkbox)
    - PRINTPrinterCount (Integer: total configured printers)
    - PRINTQueueCount (Integer: total jobs in all queues)
    - PRINTStuckJobsCount (Integer: error/old jobs)
    - PRINTPrinterErrors (Integer: printers with error conditions)
    - PRINTOfflinePrinters (Integer: offline/unavailable printers)
    - PRINTPrinterSummary (WYSIWYG: HTML formatted printer table)
    - PRINTHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - Print-Server Windows feature
    - PrintManagement PowerShell module
    - Administrator privileges
    - Event log read access
    
    Printer Status Values:
    - Normal: Operational
    - Offline: Not reachable
    - Error: General error state
    - PaperJam: Paper jam detected
    - PaperOut: Out of paper
    - TonerLow: Low toner warning
    - DoorOpen: Printer door open
    
    Job Status Values:
    - Printing: Currently printing
    - Paused: Manually paused
    - Error: Print error
    - Blocked: Queue blocked
    - UserIntervention: Requires user action
    
    Stuck Job Criteria:
    - JobStatus matches error/blocked states
    - OR job submitted more than 1 hour ago
    
    Event Log Sources:
    - Provider: Microsoft-Windows-PrintService
    - LogName: System
    - Spooler crashes, driver failures, queue errors
    
    Common Issues:
    - Offline printers: Check network connectivity, printer power
    - Stuck jobs: Clear queue manually or restart spooler
    - Paper jams: Physical printer maintenance needed
    - Driver errors: Update printer drivers
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting Print Server Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    $printServerRole = $false
    $printerCount = 0
    $queueCount = 0
    $stuckJobsCount = 0
    $printerErrors = 0
    $offlinePrinters = 0
    $printerSummary = ""
    $healthStatus = "Unknown"
    
    Write-Output "INFO: Checking for Print Server role..."
    $printRole = Get-WindowsFeature -Name "Print-Server" -ErrorAction SilentlyContinue
    
    if ($null -eq $printRole -or -not $printRole.Installed) {
        Write-Output "INFO: Print Server role not installed"
        
        Ninja-Property-Set printPrintServerRole $false
        Ninja-Property-Set printPrinterCount 0
        Ninja-Property-Set printQueueCount 0
        Ninja-Property-Set printStuckJobsCount 0
        Ninja-Property-Set printPrinterErrors 0
        Ninja-Property-Set printOfflinePrinters 0
        Ninja-Property-Set printPrinterSummary "Print Server role not installed"
        Ninja-Property-Set printHealthStatus "Unknown"
        
        Write-Output "SUCCESS: Print Server monitoring skipped (role not installed)"
        exit 0
    }
    
    $printServerRole = $true
    Write-Output "INFO: Print Server role detected"
    
    Write-Output "INFO: Enumerating printers..."
    try {
        $printers = Get-Printer -ErrorAction Stop
        $printerCount = $printers.Count
        Write-Output "INFO: Printers configured: $printerCount"
        
        $offlinePrinters = ($printers | Where-Object { $_.PrinterStatus -eq 'Offline' -or $_.PrinterStatus -eq 'Error' }).Count
        Write-Output "INFO: Offline printers: $offlinePrinters"
        
        $printerErrors = ($printers | Where-Object { 
            $_.PrinterStatus -match 'Error|PaperJam|PaperOut|TonerLow|DoorOpen' 
        }).Count
        Write-Output "INFO: Printers with errors: $printerErrors"
        
    } catch {
        Write-Output "WARNING: Failed to enumerate printers: $_"
    }
    
    Write-Output "INFO: Analyzing print queues..."
    try {
        $allJobs = @()
        foreach ($printer in $printers) {
            $jobs = Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue
            if ($jobs) {
                $allJobs += $jobs
            }
        }
        
        $queueCount = $allJobs.Count
        Write-Output "INFO: Total jobs in queue: $queueCount"
        
        $stuckJobs = $allJobs | Where-Object { 
            $_.JobStatus -match 'Error|Paused|Blocked|UserIntervention' -or 
            ((Get-Date) - $_.SubmittedTime).TotalHours -gt 1
        }
        $stuckJobsCount = if ($stuckJobs) { $stuckJobs.Count } else { 0 }
        Write-Output "INFO: Stuck jobs: $stuckJobsCount"
        
    } catch {
        Write-Output "WARNING: Failed to check print queues: $_"
    }
    
    Write-Output "INFO: Building printer summary..."
    if ($printerCount -gt 0) {
        $htmlRows = @()
        foreach ($printer in $printers) {
            $printerName = $printer.Name
            $printerStatus = $printer.PrinterStatus
            $driverName = $printer.DriverName
            
            $jobsForPrinter = (Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue).Count
            
            Write-Output "  Printer: $printerName - Status: $printerStatus, Jobs: $jobsForPrinter"
            
            $statusColor = switch ($printerStatus) {
                'Normal' { 'green' }
                'Offline' { 'red' }
                'Error' { 'red' }
                'PaperJam' { 'orange' }
                'PaperOut' { 'orange' }
                default { 'black' }
            }
            
            $htmlRows += "<tr><td>$printerName</td><td style='color:$statusColor'>$printerStatus</td><td>$jobsForPrinter</td><td style='font-size:0.85em'>$driverName</td></tr>"
        }
        
        $printerSummary = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Printer</th><th>Status</th><th>Jobs</th><th>Driver</th></tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary:</strong><br/>
Total Printers: $printerCount | Offline: $offlinePrinters | Errors: $printerErrors<br/>
Total Jobs: $queueCount | Stuck Jobs: $stuckJobsCount
</p>
"@
    } else {
        $printerSummary = "No printers configured on this server"
    }
    
    Write-Output "INFO: Checking print spooler errors (24h)..."
    try {
        $startTime = (Get-Date).AddHours(-24)
        $spoolerErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-PrintService'
            Level = 1,2
            StartTime = $startTime
        } -MaxEvents 10 -ErrorAction SilentlyContinue
        
        if ($spoolerErrors) {
            $printerErrors += $spoolerErrors.Count
            Write-Output "  WARNING: Spooler errors detected: $($spoolerErrors.Count)"
        }
    } catch {
        # No errors or event log not accessible
    }
    
    Write-Output "INFO: Determining health status..."
    if ($offlinePrinters -gt 0 -or $stuckJobsCount -gt 5) {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Critical - Offline printers or many stuck jobs"
    } elseif ($printerErrors -gt 0 -or $stuckJobsCount -gt 0) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - Printer errors or stuck jobs detected"
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: Print server healthy"
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set printPrintServerRole $true
    Ninja-Property-Set printPrinterCount $printerCount
    Ninja-Property-Set printQueueCount $queueCount
    Ninja-Property-Set printStuckJobsCount $stuckJobsCount
    Ninja-Property-Set printPrinterErrors $printerErrors
    Ninja-Property-Set printOfflinePrinters $offlinePrinters
    Ninja-Property-Set printPrinterSummary $printerSummary
    Ninja-Property-Set printHealthStatus $healthStatus
    
    Write-Output "SUCCESS: Print Server monitoring complete"
    Write-Output "PRINT SERVER METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - Printers: $printerCount"
    Write-Output "  - Offline: $offlinePrinters"
    Write-Output "  - Errors: $printerErrors"
    Write-Output "  - Total Jobs: $queueCount"
    Write-Output "  - Stuck Jobs: $stuckJobsCount"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: Print Server Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set printPrintServerRole $false
    Ninja-Property-Set printHealthStatus "Unknown"
    Ninja-Property-Set printPrinterSummary "Monitor script error: $errorMessage"
    
    exit 1
}
