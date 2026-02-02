<#
.SYNOPSIS
    Script 46: Print Server Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Print Server role including printer queues, stuck jobs, printer errors,
    offline printers, and queue health. Updates 8 PRINT fields with HTML summary.

.FIELDS UPDATED
    - PRINTPrintServerRole (Checkbox)
    - PRINTPrinterCount (Integer)
    - PRINTQueueCount (Integer)
    - PRINTStuckJobsCount (Integer)
    - PRINTPrinterErrors (Integer)
    - PRINTOfflinePrinters (Integer)
    - PRINTPrinterSummary (WYSIWYG)
    - PRINTHealthStatus (Dropdown)

.EXECUTION
    Frequency: Daily (config), Every 4 hours (status)
    Runtime: ~30 seconds
    Requires: Print Server role installed

.NOTES
    File: Script_46_Print_Server_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Server Role Monitoring
    Dependencies: Print Server role, Print Management PowerShell

.RELATED DOCUMENTATION
    - docs/core/16_ROLE_Additional.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 4)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Print Server Monitor (Script 46)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $printServerRole = $false
    $printerCount = 0
    $queueCount = 0
    $stuckJobsCount = 0
    $printerErrors = 0
    $offlinePrinters = 0
    $printerSummary = ""
    $healthStatus = "Unknown"
    
    # Check if Print Server role is installed
    Write-Host "Checking Print Server role..."
    $printRole = Get-WindowsFeature -Name "Print-Server" -ErrorAction SilentlyContinue
    
    if ($null -eq $printRole -or -not $printRole.Installed) {
        Write-Host "Print Server role is not installed."
        
        # Update fields for non-print servers
        Ninja-Property-Set printPrintServerRole $false
        Ninja-Property-Set printPrinterCount 0
        Ninja-Property-Set printQueueCount 0
        Ninja-Property-Set printStuckJobsCount 0
        Ninja-Property-Set printPrinterErrors 0
        Ninja-Property-Set printOfflinePrinters 0
        Ninja-Property-Set printPrinterSummary "Print Server role not installed"
        Ninja-Property-Set printHealthStatus "Unknown"
        
        Write-Host "Print Server Monitor complete (role not installed)."
        exit 0
    }
    
    $printServerRole = $true
    Write-Host "Print Server role is installed."
    
    # Get printers
    Write-Host "Enumerating printers..."
    try {
        $printers = Get-Printer -ErrorAction Stop
        $printerCount = $printers.Count
        Write-Host "Printer Count: $printerCount"
        
        # Count offline printers
        $offlinePrinters = ($printers | Where-Object { $_.PrinterStatus -eq 'Offline' -or $_.PrinterStatus -eq 'Error' }).Count
        Write-Host "Offline Printers: $offlinePrinters"
        
        # Count printers with errors
        $printerErrors = ($printers | Where-Object { 
            $_.PrinterStatus -match 'Error|PaperJam|PaperOut|TonerLow|DoorOpen' 
        }).Count
        Write-Host "Printers with Errors: $printerErrors"
        
    } catch {
        Write-Warning "Failed to enumerate printers: $_"
    }
    
    # Get print queues (jobs)
    Write-Host "Checking print queues..."
    try {
        $allJobs = @()
        foreach ($printer in $printers) {
            $jobs = Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue
            if ($jobs) {
                $allJobs += $jobs
            }
        }
        
        $queueCount = $allJobs.Count
        Write-Host "Total Jobs in Queue: $queueCount"
        
        # Count stuck jobs (jobs older than 1 hour or in error state)
        $stuckJobs = $allJobs | Where-Object { 
            $_.JobStatus -match 'Error|Paused|Blocked|UserIntervention' -or 
            ((Get-Date) - $_.SubmittedTime).TotalHours -gt 1
        }
        $stuckJobsCount = if ($stuckJobs) { $stuckJobs.Count } else { 0 }
        Write-Host "Stuck Jobs: $stuckJobsCount"
        
    } catch {
        Write-Warning "Failed to check print queues: $_"
    }
    
    # Build printer summary HTML
    Write-Host "Building printer summary..."
    if ($printerCount -gt 0) {
        $htmlRows = @()
        foreach ($printer in $printers) {
            $printerName = $printer.Name
            $printerStatus = $printer.PrinterStatus
            $driverName = $printer.DriverName
            
            # Get job count for this printer
            $jobsForPrinter = (Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue).Count
            
            # Determine status color
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
    
    # Check for print spooler errors in event log
    Write-Host "Checking print spooler errors..."
    try {
        $startTime = (Get-Date).AddHours(-24)
        $spoolerErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-PrintService'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -MaxEvents 10 -ErrorAction SilentlyContinue
        
        if ($spoolerErrors) {
            $printerErrors += $spoolerErrors.Count
            Write-Warning "Print spooler errors detected: $($spoolerErrors.Count)"
        }
    } catch {
        # No errors found or event log not accessible
    }
    
    # Determine health status
    if ($offlinePrinters -gt 0 -or $stuckJobsCount -gt 5) {
        $healthStatus = "Critical"
    } elseif ($printerErrors -gt 0 -or $stuckJobsCount -gt 0) {
        $healthStatus = "Warning"
    } else {
        $healthStatus = "Healthy"
    }
    
    Write-Host "Health Status: $healthStatus"
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set printPrintServerRole $true
    Ninja-Property-Set printPrinterCount $printerCount
    Ninja-Property-Set printQueueCount $queueCount
    Ninja-Property-Set printStuckJobsCount $stuckJobsCount
    Ninja-Property-Set printPrinterErrors $printerErrors
    Ninja-Property-Set printOfflinePrinters $offlinePrinters
    Ninja-Property-Set printPrinterSummary $printerSummary
    Ninja-Property-Set printHealthStatus $healthStatus
    
    Write-Host "Print Server Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Print Server Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set printPrintServerRole $false
    Ninja-Property-Set printHealthStatus "Unknown"
    Ninja-Property-Set printPrinterSummary "Monitor script error: $errorMessage"
    
    exit 1
}
