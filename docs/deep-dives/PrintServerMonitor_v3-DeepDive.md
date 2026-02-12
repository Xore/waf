# PrintServerMonitor_v3.ps1 - Deep Dive Guide

## Overview

**PrintServerMonitor_v3.ps1** is a comprehensive monitoring solution for Windows Print Server infrastructure, tracking printer availability, print job queues, stuck jobs, printer errors, and spooler health. This script is essential for maintaining print service availability, preventing queue backlogs, and detecting offline printers before they impact business operations.

### Key Capabilities

- **Printer Inventory Management**: Automated tracking of all configured printers and status
- **Queue Health Monitoring**: Real-time analysis of print queues and job counts
- **Stuck Job Detection**: Identification of error states and aging jobs blocking queues
- **Offline Printer Alerting**: Early detection of unavailable printers
- **Error State Monitoring**: Tracking of paper jams, toner issues, and hardware errors
- **Dashboard Integration**: HTML-formatted printer summaries for visual monitoring

---

## Technical Architecture

### Monitoring Scope

```
Print Server Infrastructure
├── Role Detection
│   ├── Print-Server feature verification
│   ├── PrintManagement module availability
│   └── Graceful exit if not installed
│
├── Printer Inventory
│   ├── Total printer count (Get-Printer)
│   ├── Printer status tracking (Normal/Offline/Error)
│   ├── Driver name and version
│   └── Configuration capacity metric
│
├── Printer Status Classification
│   ├── Online printers (Normal)
│   ├── Offline printers (unreachable)
│   ├── Error conditions (jams, toner, doors)
│   └── Hardware issues
│
├── Queue Analysis
│   ├── Total job count across all queues
│   ├── Per-printer job counts
│   ├── Queue depth tracking
│   └── Job age analysis
│
├── Stuck Job Detection
│   ├── Error state jobs (Error, Blocked)
│   ├── Paused jobs
│   ├── UserIntervention required
│   ├── Age-based detection (>1 hour old)
│   └── Queue blocking identification
│
└── Spooler Health
    ├── System event log queries
    ├── PrintService provider errors
    ├── 24-hour error aggregation
    └── Spooler crash detection
```

### Data Collection Flow

```
1. Role Verification
   └→ Print-Server feature installed?
       ├→ No: Record Unknown status, exit gracefully
       └→ Yes: Continue monitoring

2. Printer Enumeration
   └→ Get-Printer → List all printers
       ├→ Count total printers
       ├→ Identify offline printers (Status = Offline/Error)
       ├→ Count error conditions (PaperJam, PaperOut, TonerLow)
       └→ Record per-printer status

3. Queue Analysis
   └→ For each printer:
       ├→ Get-PrintJob -PrinterName
       ├→ Count jobs in queue
       ├→ Analyze job status
       └→ Check job age (SubmittedTime)

4. Stuck Job Detection
   └→ Filter jobs:
       ├→ JobStatus matches error states?
       ├→ OR job age > 1 hour?
       └→ Count as stuck

5. Printer Summary
   └→ Build HTML table:
       ├→ Printer name, status, job count, driver
       ├→ Color-code status (green/orange/red)
       ├→ Per-printer job metrics
       └→ Summary statistics

6. Spooler Error Check
   └→ Query System event log (24h):
       ├→ Provider: Microsoft-Windows-PrintService
       ├→ Level: Critical (1), Error (2)
       └→ Count spooler errors

7. Health Classification
   └→ offlinePrinters > 0 OR stuckJobsCount > 5? → Critical
   └→ printerErrors > 0 OR stuckJobsCount > 0? → Warning  
   └→ Else: Healthy
```

---

## Field Reference

### Custom Fields Configuration

```powershell
# Boolean Fields
printPrintServerRole       # Checkbox: Print Server role installed

# Integer Fields
printPrinterCount          # Total configured printers
printQueueCount            # Total jobs across all queues
printStuckJobsCount        # Jobs in error or aged >1 hour
printPrinterErrors         # Printers with error conditions
printOfflinePrinters       # Offline/unreachable printers

# Text/WYSIWYG Fields
printPrinterSummary        # WYSIWYG: HTML formatted printer table
printHealthStatus          # Text: Healthy|Warning|Critical|Unknown
```

### Field Value Examples

**Healthy Print Server:**
```
printPrintServerRole = true
printPrinterCount = 12
printQueueCount = 3
printStuckJobsCount = 0
printPrinterErrors = 0
printOfflinePrinters = 0
printPrinterSummary = [HTML table with 12 printers, all normal]
printHealthStatus = "Healthy"
```

**Warning State (Paper Jam):**
```
printPrinterErrors = 2
printStuckJobsCount = 1
printHealthStatus = "Warning"
printPrinterSummary shows orange-coded printers with PaperJam status
```

**Critical State (Offline Printers):**
```
printOfflinePrinters = 3
printStuckJobsCount = 8
printHealthStatus = "Critical"
```

---

## Monitoring Logic Details

### Printer Status Classification

Printer status indicates operational state:

```powershell
# Status enumeration
$printers = Get-Printer
foreach ($printer in $printers) {
    $status = $printer.PrinterStatus
    # Normal, Offline, Error, PaperJam, PaperOut, TonerLow, DoorOpen
}
```

**Status Meanings:**

| Status | Operational | Description | User Impact |
|--------|-------------|-------------|-------------|
| **Normal** | Yes | Printer ready | None |
| **Offline** | No | Network unreachable | Jobs queue but don't print |
| **Error** | No | General error | Jobs may fail |
| **PaperJam** | No | Paper jam detected | Requires physical intervention |
| **PaperOut** | No | Out of paper | Requires paper reload |
| **TonerLow** | Degraded | Low toner warning | Print quality may degrade |
| **DoorOpen** | No | Cover/door open | Safety interlock |

**Offline Detection:**
```powershell
$offlinePrinters = ($printers | Where-Object { 
    $_.PrinterStatus -eq 'Offline' -or $_.PrinterStatus -eq 'Error' 
}).Count

# Offline = service unavailable, critical metric
```

**Error Condition Detection:**
```powershell
$printerErrors = ($printers | Where-Object { 
    $_.PrinterStatus -match 'Error|PaperJam|PaperOut|TonerLow|DoorOpen'
}).Count

# Error conditions require action, warning metric
```

### Print Queue Analysis

Job enumeration and queue depth tracking:

```powershell
# Per-printer queue analysis
$allJobs = @()
foreach ($printer in $printers) {
    $jobs = Get-PrintJob -PrinterName $printer.Name
    if ($jobs) {
        $allJobs += $jobs
    }
}

$queueCount = $allJobs.Count
```

**Queue Depth Interpretation:**

- **0-10 jobs**: Normal - Typical small office load
- **10-50 jobs**: Acceptable - Moderate activity
- **50-100 jobs**: High - Monitor for stuck jobs
- **>100 jobs**: Critical - Likely backlog or stuck queue

**Per-Printer Load Balancing:**
```powershell
# Identify high-load printers
$printersWithJobs = @{}
foreach ($printer in $printers) {
    $jobCount = (Get-PrintJob -PrinterName $printer.Name).Count
    $printersWithJobs[$printer.Name] = $jobCount
    
    if ($jobCount -gt 20) {
        # High load on this printer
    }
}
```

**Common Queue Patterns:**
- **All jobs on one printer**: Load imbalance, redirect users
- **No jobs anywhere**: Either quiet period or spooler issue
- **Many jobs on offline printer**: Users don't know it's offline

### Stuck Job Detection

Identifying jobs that block print queues:

```powershell
# Multi-criteria stuck job detection
$stuckJobs = $allJobs | Where-Object { 
    # Error states
    $_.JobStatus -match 'Error|Paused|Blocked|UserIntervention' -or 
    # Age-based detection
    ((Get-Date) - $_.SubmittedTime).TotalHours -gt 1
}

$stuckJobsCount = if ($stuckJobs) { $stuckJobs.Count } else { 0 }
```

**Stuck Job Criteria:**

**Status-Based:**
- **Error**: Job failed during processing
- **Paused**: Manually paused by user/admin
- **Blocked**: Queue blocked, often by previous failed job
- **UserIntervention**: Requires user action (paper size, manual feed)

**Age-Based:**
- Job submitted >1 hour ago and still in queue
- Indicates slow processing or hidden failure

**Stuck Job Impact:**
```
Stuck jobs at front of queue block all subsequent jobs.

Example:
Queue: [Job1-Stuck] [Job2-Waiting] [Job3-Waiting] ...

Jobs 2-100 cannot print until Job1 is cleared.
```

**Stuck Job Thresholds:**
- **0 stuck**: Healthy
- **1-5 stuck**: Warning - Monitor and clear manually
- **>5 stuck**: Critical - Major queue blockage

### Printer Summary Reporting

HTML-formatted printer table with status visualization:

```powershell
# Color-coded status display
$statusColor = switch ($printerStatus) {
    'Normal' { 'green' }      # Operational
    'Offline' { 'red' }       # Critical - unavailable
    'Error' { 'red' }         # Critical - failure
    'PaperJam' { 'orange' }   # Warning - requires intervention
    'PaperOut' { 'orange' }   # Warning - consumable needed
    default { 'black' }       # Unknown/other
}

$htmlRows += "<tr><td>$printerName</td><td style='color:$statusColor'>$printerStatus</td>..."
```

**Summary Table Structure:**
```html
| Printer Name | Status | Jobs | Driver |
|--------------|--------|------|--------|
| HP-Laser-01  | Normal (green) | 2    | HP Universal PCL6 |
| Canon-Color-02 | PaperJam (orange) | 5 | Canon Generic Plus PCL6 |
| Xerox-Main   | Offline (red) | 0    | Xerox Global Print Driver |

Summary:
Total Printers: 12 | Offline: 1 | Errors: 1
Total Jobs: 23 | Stuck Jobs: 5
```

**Dashboard Value:**
- Quick visual assessment of print infrastructure
- Identify problem printers at a glance
- Load distribution visibility
- Driver inventory for standardization

### Spooler Health Monitoring

Event log analysis for spooler stability:

```powershell
# Query print service errors (24 hours)
$spoolerErrors = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-PrintService'
    Level = 1,2  # Critical and Error
    StartTime = (Get-Date).AddHours(-24)
}
```

**Common Spooler Event IDs:**

| Event ID | Description | Severity | Cause |
|----------|-------------|----------|-------|
| **372** | Print spooler failed to load driver | Critical | Driver corruption |
| **808** | Print spooler service stopped unexpectedly | Critical | Crash or manual stop |
| **842** | Failed to save printer settings | Error | Registry/permissions |
| **2004** | Printer driver installation failed | Error | Driver package issue |
| **4227** | Print job failed | Error | Application/driver issue |

**Spooler Error Patterns:**
- **Repeated 372**: Driver corruption, reinstall driver
- **Multiple 808**: Spooler crashes, investigate dump files
- **Continuous 4227**: Application issue or corrupted document

---

## Real-World Scenarios

### Scenario 1: Offline Printer Blocking Queue

**Symptom:**
```
printOfflinePrinters = 1
printQueueCount = 47
printStuckJobsCount = 47
printHealthStatus = "Critical"
User reports: "Nothing is printing"
```

**Investigation Steps:**

1. **Identify offline printer:**
```powershell
Get-Printer | Where-Object { $_.PrinterStatus -eq 'Offline' }

# Output: HP-Accounting-Floor2 - Offline
```

2. **Check jobs in that queue:**
```powershell
Get-PrintJob -PrinterName "HP-Accounting-Floor2" | Select-Object Id, DocumentName, UserName, SubmittedTime

# 47 jobs queued, oldest from 3 days ago
```

3. **Test printer connectivity:**
```powershell
$printerIP = "192.168.10.50"
Test-NetConnection -ComputerName $printerIP -Port 9100

# If fails: Network/printer issue
# If succeeds: Configuration problem
```

**Common Causes:**
- Printer powered off or network cable disconnected
- Printer IP address changed (DHCP issue)
- Network switch port disabled
- Firewall blocking print port (9100/515)
- Printer firmware crashed

**Resolution:**

1. **Physical checks:**
   - Verify printer is powered on
   - Check network cable connection
   - Ping printer IP address

2. **Clear queue if printer can't be restored immediately:**
```powershell
# Remove all jobs from offline printer
Get-PrintJob -PrinterName "HP-Accounting-Floor2" | Remove-PrintJob

# Redirect users to backup printer
Set-Printer -Name "HP-Accounting-Floor2-Backup" -Published $true
```

3. **Restore printer connectivity:**
```powershell
# If IP changed, update port
$newIP = "192.168.10.51"
Set-PrinterPort -Name "IP_$printerIP" -IPAddress $newIP

# Or recreate port
Add-PrinterPort -Name "IP_$newIP" -PrinterHostAddress $newIP
Set-Printer -Name "HP-Accounting-Floor2" -PortName "IP_$newIP"
```

### Scenario 2: Paper Jam Causing Job Backlog

**Symptom:**
```
printPrinterErrors = 1
printStuckJobsCount = 3
printHealthStatus = "Warning"
Printer status: PaperJam
```

**Investigation Steps:**

1. **Identify jammed printer:**
```powershell
Get-Printer | Where-Object { $_.PrinterStatus -eq 'PaperJam' } | Select-Object Name, Location

# Output: Canon-HR-Main - Building A, Room 215
```

2. **Check affected jobs:**
```powershell
Get-PrintJob -PrinterName "Canon-HR-Main" | Format-Table Id, DocumentName, UserName, Position

# Typically 1 job printing when jam occurred, others queued
```

**Resolution:**

1. **Physical intervention required:**
   - Walk to printer location (Building A, Room 215)
   - Clear paper jam following printer instructions
   - Verify no torn paper remains in mechanism

2. **Resume printing:**
```powershell
# After physical jam cleared, check if status auto-updates
Get-Printer -Name "Canon-HR-Main" | Select-Object PrinterStatus

# If still shows PaperJam, restart printer
# Jobs will automatically resume
```

3. **If jobs don't resume:**
```powershell
# Restart print spooler
Restart-Service Spooler

# Or resume individual jobs
Get-PrintJob -PrinterName "Canon-HR-Main" | 
    Where-Object { $_.JobStatus -eq 'Paused' } | 
    Resume-PrintJob
```

**Preventative Actions:**
- Train users on proper paper loading
- Replace worn pickup rollers
- Use recommended paper type/weight
- Schedule regular printer maintenance

### Scenario 3: Stuck Job Blocking Entire Queue

**Symptom:**
```
printStuckJobsCount = 1
printQueueCount = 25
All 25 jobs are for same printer
No jobs printing despite printer showing "Normal"
```

**Investigation Steps:**

1. **Examine stuck job:**
```powershell
$jobs = Get-PrintJob -PrinterName "Xerox-Main" | Sort-Object SubmittedTime
$firstJob = $jobs[0]

$firstJob | Format-List Id, DocumentName, UserName, SubmittedTime, JobStatus, Size

# Example output:
# Id: 1523
# DocumentName: LargeReport.pdf
# UserName: DOMAIN\jsmith
# SubmittedTime: 2/11/2026 9:00 AM (8 hours ago)
# JobStatus: Error
# Size: 250 MB
```

2. **Check for error details:**
```powershell
# Query application event log for print errors
Get-WinEvent -LogName Application -MaxEvents 50 | 
    Where-Object { $_.Message -match 'print' -and $_.TimeCreated -gt (Get-Date).AddHours(-8) }

# Common errors:
# - "Insufficient memory"
# - "Invalid document format"
# - "Driver failed"
```

**Common Stuck Job Causes:**
- Corrupted document (malformed PDF, oversized image)
- Insufficient spooler disk space
- Driver incompatibility
- Document size exceeds printer memory
- User cancelled locally but job still in queue

**Resolution:**

1. **Remove stuck job:**
```powershell
# Remove specific job
Remove-PrintJob -PrinterName "Xerox-Main" -ID 1523

# Verify queue clears
Get-PrintJob -PrinterName "Xerox-Main"

# Jobs should automatically start printing
```

2. **If jobs still don't print:**
```powershell
# Restart spooler service
Restart-Service Spooler

# Check if jobs survived restart
Get-PrintJob -PrinterName "Xerox-Main"
```

3. **Investigate root cause:**
```powershell
# Check spooler disk space
Get-Volume | Where-Object { $_.DriveLetter -eq 'C' }

# Spooler folder location
$spoolFolder = "C:\Windows\System32\spool\PRINTERS"
Get-ChildItem $spoolFolder | Measure-Object -Property Length -Sum

# If nearly full (>90%), clean up old spool files
```

4. **Contact user about document:**
```powershell
# Notify user of failed job
$user = "jsmith"
$message = @"
Your print job 'LargeReport.pdf' failed to print on Xerox-Main.
Please try:
1. Reducing document size
2. Printing to a different printer
3. Breaking into smaller sections
"@

# Send via email or ticketing system
```

### Scenario 4: Spooler Service Crashing

**Symptom:**
```
printHealthStatus = "Critical"
All printers show "Offline" intermittently
Event log: Multiple Event ID 808 (spooler stopped)
Print queue clears unexpectedly
```

**Investigation Steps:**

1. **Check spooler crash frequency:**
```powershell
# Count spooler stop events
Get-WinEvent -LogName System -MaxEvents 1000 | 
    Where-Object { 
        $_.ProviderName -eq 'Service Control Manager' -and 
        $_.Message -match 'Print Spooler.*terminated' 
    } | 
    Group-Object { $_.TimeCreated.Date } | 
    Select-Object Count, Name

# If crashing multiple times per day: Critical issue
```

2. **Identify problematic driver:**
```powershell
# Check recent driver loads before crashes
Get-WinEvent -LogName System | 
    Where-Object { $_.Id -eq 372 } |  # Driver load failures
    Select-Object -First 10 TimeCreated, Message

# Common culprit: Specific driver version causing crash
```

3. **Review crash dumps:**
```powershell
# Spooler crash dumps location
$dumpPath = "C:\Windows\Minidump"
Get-ChildItem $dumpPath -Filter "*.dmp" | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# Use WinDbg or DebugDiag for analysis
# Typical issues: Driver memory corruption, third-party spooler extension
```

**Common Spooler Crash Causes:**
- Buggy printer driver (manufacturer update needed)
- Third-party print management software conflict
- Antivirus scanning spooler folder
- Corrupted spooler database
- Memory leak in driver

**Resolution:**

1. **Isolate problematic driver:**
```powershell
# Temporarily disable suspect printers one-by-one
$suspectPrinters = @('HP-Finance', 'Canon-IT')

foreach ($printer in $suspectPrinters) {
    Set-Printer -Name $printer -Published $false
    Write-Output "Disabled $printer - Monitor for crashes"
}

# If crashes stop, identified problem driver
```

2. **Update printer driver:**
```powershell
# Download latest driver from manufacturer
# Install via Print Management console

# Or update via PowerShell (Windows Update catalog)
Add-PrinterDriver -Name "HP Universal Printing PCL 6" -InfPath "C:\Drivers\HP\hpcu206u.inf"

# Update printer to use new driver
Set-Printer -Name "HP-Finance" -DriverName "HP Universal Printing PCL 6"
```

3. **Prevent spooler auto-restart:**
```powershell
# Configure spooler service recovery
$service = Get-WmiObject -Class Win32_Service -Filter "Name='Spooler'"
$service.ChangeStartMode("Automatic")

# Set recovery actions: Restart service on failure
sc.exe failure Spooler reset= 86400 actions= restart/60000/restart/60000/restart/60000
```

4. **Implement monitoring:**
```powershell
# Create scheduled task to alert on spooler stop
$trigger = New-EventTrigger -LogName System -Source "Service Control Manager" -EventId 7036
# (Spooler service entered stopped state)

# Send alert to monitoring system
```

---

## NinjaRMM Integration

### Automation Policy Setup

**Regular Monitoring (Every 4 Hours):**
```yaml
Policy Name: Print Server - Queue Health Check
Schedule: Every 4 hours (0:00, 4:00, 8:00, 12:00, 16:00, 20:00)
Script: PrintServerMonitor_v3.ps1
Timeout: 90 seconds
Context: SYSTEM
Conditions:
  - Print-Server feature installed
  - OS Type = Windows Server
```

**Business Hours Monitoring (More Frequent):**
```yaml
Policy Name: Print Server - Business Hours Check
Schedule: Every 30 minutes (8 AM - 6 PM, Mon-Fri)
Script: PrintServerMonitor_v3.ps1
Timeout: 90 seconds
Purpose: Rapid detection during peak usage
```

### Alert Conditions

**Critical Alert - Offline Printers:**
```
Condition: printOfflinePrinters > 0
Alert: Email + SMS + Ticket
Priority: P1
Subject: CRITICAL: Print Server Offline Printers - {{device.name}}
Body: |
  One or more printers are offline and unavailable.
  
  Offline Printers: {{custom.printOfflinePrinters}}
  Total Queued Jobs: {{custom.printQueueCount}}
  Stuck Jobs: {{custom.printStuckJobsCount}}
  
  IMMEDIATE ACTION REQUIRED
  Check printer power, network connectivity, and spooler service.
  
  Printer Details:
  {{custom.printPrinterSummary}}
```

**Critical Alert - Major Queue Backlog:**
```
Condition: printStuckJobsCount > 5
Alert: Email + Ticket
Priority: P1
Subject: CRITICAL: Print Queue Backlog - {{device.name}}
Body: |
  Print server has major queue backlog.
  
  Stuck Jobs: {{custom.printStuckJobsCount}}
  Total Jobs: {{custom.printQueueCount}}
  
  Multiple jobs are blocking print queues.
  Clear stuck jobs immediately to restore service.
```

**Warning Alert - Printer Errors:**
```
Condition: printPrinterErrors > 0
Alert: Email
Priority: P2
Subject: WARNING: Printer Errors Detected - {{device.name}}
Body: |
  Printers require attention.
  
  Printers with Errors: {{custom.printPrinterErrors}}
  Stuck Jobs: {{custom.printStuckJobsCount}}
  
  Check for paper jams, empty trays, or toner issues.
  
  {{custom.printPrinterSummary}}
```

**Info Alert - High Queue Depth:**
```
Condition: printQueueCount > 50 AND printStuckJobsCount = 0
Alert: Email
Subject: INFO: High Print Queue Volume - {{device.name}}
Body: |
  Print server experiencing high queue volume.
  
  Total Jobs: {{custom.printQueueCount}}
  Printers: {{custom.printPrinterCount}}
  
  No stuck jobs detected - jobs processing normally.
  Monitor for capacity issues.
```

### Dashboard Widgets

**Printer Summary Widget:**
```
Widget Type: Custom Field Display
Field: printPrinterSummary (WYSIWYG)
Title: Print Server Status
Description: Current printer inventory and queue status
Refresh: On field update
```

**Print Health Status Widget:**
```
Widget Type: Status Indicator
Field: printHealthStatus
Title: Print Server Health
Colors:
  Healthy: Green
  Warning: Yellow
  Critical: Red
  Unknown: Gray
```

**Queue Metrics Widget:**
```
Widget Type: Multi-Metric Display
Fields:
  - printPrinterCount (Total Printers)
  - printOfflinePrinters (Offline)
  - printQueueCount (Queued Jobs)
  - printStuckJobsCount (Stuck Jobs)
Title: Print Queue Metrics
```

---

## Advanced Customization

### Example 1: Driver Version Inventory

Track driver versions for standardization:

```powershell
# Add after printer enumeration
Write-Output "INFO: Inventorying printer drivers..."

$driverInventory = @{}
foreach ($printer in $printers) {
    $driverName = $printer.DriverName
    
    if (-not $driverInventory.ContainsKey($driverName)) {
        $driver = Get-PrinterDriver -Name $driverName -ErrorAction SilentlyContinue
        if ($driver) {
            $driverInventory[$driverName] = @{
                Version = $driver.MajorVersion
                PrinterCount = 1
            }
        }
    } else {
        $driverInventory[$driverName].PrinterCount++
    }
}

# Build driver report
$driverReport = ($driverInventory.GetEnumerator() | ForEach-Object {
    "$($_.Key) (v$($_.Value.Version)): $($_.Value.PrinterCount) printers"
}) -join "<br>"

Ninja-Property-Set printDriverInventory $driverReport
Write-Output "INFO: Driver inventory: $($driverInventory.Count) unique drivers"
```

### Example 2: Per-User Job Tracking

Identify heavy print users:

```powershell
# Add after queue analysis
Write-Output "INFO: Analyzing per-user print activity..."

$userJobs = $allJobs | Group-Object UserName | 
    Sort-Object Count -Descending | 
    Select-Object -First 10

if ($userJobs) {
    $topUsersReport = ($userJobs | ForEach-Object {
        "$($_.Name): $($_.Count) jobs"
    }) -join "<br>"
    
    Ninja-Property-Set printTopUsers $topUsersReport
    Write-Output "  Top user: $($userJobs[0].Name) - $($userJobs[0].Count) jobs"
    
    # Alert if single user has excessive jobs
    if ($userJobs[0].Count -gt 50) {
        Write-Output "  WARNING: User $($userJobs[0].Name) has excessive print jobs"
    }
}
```

### Example 3: Print Cost Estimation

Estimate print costs based on page counts:

```powershell
# Add after queue analysis  
Write-Output "INFO: Estimating print costs..."

$totalPages = 0
foreach ($job in $allJobs) {
    # TotalPages property available for some drivers
    if ($job.TotalPages) {
        $totalPages += $job.TotalPages
    }
}

if ($totalPages -gt 0) {
    # Cost estimation (example: $0.05 per page)
    $costPerPage = 0.05
    $estimatedCost = $totalPages * $costPerPage
    
    Write-Output "  Total pages in queue: $totalPages"
    Write-Output "  Estimated cost: `$$([Math]::Round($estimatedCost, 2))"
    
    Ninja-Property-Set printQueuePages $totalPages
    Ninja-Property-Set printEstimatedCost $estimatedCost
}
```

### Example 4: Automatic Stuck Job Cleanup

Automatically clear very old stuck jobs:

```powershell
# Add after stuck job detection
Write-Output "INFO: Checking for auto-clearable stuck jobs..."

$autoCleanThresholdHours = 24  # Jobs older than 24 hours
$autoClearedCount = 0

foreach ($job in $stuckJobs) {
    $jobAge = ((Get-Date) - $job.SubmittedTime).TotalHours
    
    if ($jobAge -gt $autoCleanThresholdHours) {
        try {
            Write-Output "  Auto-clearing old job: $($job.DocumentName) ($(([Math]::Round($jobAge, 1))) hours old)"
            
            Remove-PrintJob -PrinterName $job.PrinterName -ID $job.Id -ErrorAction Stop
            $autoClearedCount++
        } catch {
            Write-Output "  WARNING: Failed to auto-clear job $($job.Id): $_"
        }
    }
}

if ($autoClearedCount -gt 0) {
    Write-Output "INFO: Auto-cleared $autoClearedCount stuck jobs"
    Ninja-Property-Set printAutoClearedJobs $autoClearedCount
}
```

### Example 5: Printer Availability SLA Tracking

Track printer uptime percentage:

```powershell
# Requires historical data storage
Write-Output "INFO: Calculating printer SLA..."

$slaDataFile = "C:\ProgramData\PrintServerMonitor\SLA.json"

# Load previous status
if (Test-Path $slaDataFile) {
    $slaData = Get-Content $slaDataFile | ConvertFrom-Json
} else {
    $slaData = @{}
}

$currentTime = Get-Date
foreach ($printer in $printers) {
    $printerName = $printer.Name
    $isOnline = ($printer.PrinterStatus -eq 'Normal')
    
    if (-not $slaData.$printerName) {
        $slaData.$printerName = @{
            TotalChecks = 0
            OnlineChecks = 0
            LastCheck = $currentTime
        }
    }
    
    $slaData.$printerName.TotalChecks++
    if ($isOnline) {
        $slaData.$printerName.OnlineChecks++
    }
    $slaData.$printerName.LastCheck = $currentTime
    
    # Calculate SLA percentage
    $slaPercentage = [Math]::Round(($slaData.$printerName.OnlineChecks / $slaData.$printerName.TotalChecks) * 100, 2)
    
    Write-Output "  $printerName SLA: $slaPercentage% ($(($slaData.$printerName.TotalChecks)) checks)"
}

# Save updated SLA data
$slaData | ConvertTo-Json | Set-Content $slaDataFile
```

### Example 6: Network Printer Connectivity Test

Test network connectivity to IP-based printers:

```powershell
# Add after printer enumeration
Write-Output "INFO: Testing network printer connectivity..."

$networkIssues = @()

foreach ($printer in $printers) {
    # Extract IP from port if network printer
    $port = Get-PrinterPort -Name $printer.PortName -ErrorAction SilentlyContinue
    
    if ($port -and $port.PrinterHostAddress) {
        $printerIP = $port.PrinterHostAddress
        
        # Test connectivity
        $pingResult = Test-NetConnection -ComputerName $printerIP -Port 9100 -InformationLevel Quiet -WarningAction SilentlyContinue
        
        if (-not $pingResult) {
            $networkIssues += "$($printer.Name) ($printerIP) - Network unreachable"
            Write-Output "  WARNING: Cannot reach $($printer.Name) at $printerIP"
        }
    }
}

if ($networkIssues.Count -gt 0) {
    $networkReport = $networkIssues -join "<br>"
    Ninja-Property-Set printNetworkIssues $networkReport
    
    Write-Output "  ASSESSMENT: $($networkIssues.Count) printers have network issues"
}
```

---

## Troubleshooting Guide

### Issue: Get-Printer Returns No Printers

**Symptoms:**
- `printPrinterCount = 0` despite printers configured
- Script completes but shows "No printers configured"

**Causes:**
- PrintManagement module not loaded
- Permissions issue
- Print spooler not running

**Solutions:**

1. **Verify spooler service:**
```powershell
Get-Service Spooler

# If stopped, start it
Start-Service Spooler
```

2. **Test Get-Printer cmdlet:**
```powershell
# Run manually to see actual error
Get-Printer -ErrorAction Stop

# If "Access Denied": Run as admin
# If "Command not found": Install Print Management tools
```

3. **Install Print Management tools:**
```powershell
Install-WindowsFeature Print-Services -IncludeManagementTools
```

### Issue: Stuck Job Count Always Zero

**Symptoms:**
- `printStuckJobsCount = 0` always
- Users report jobs not printing

**Causes:**
- Jobs cleared before script runs
- Get-PrintJob permissions issue
- Job age calculation error

**Solutions:**

1. **Increase monitoring frequency:**
```
Run script every 15 minutes instead of 4 hours
Stuck jobs may clear before detection
```

2. **Verify job enumeration:**
```powershell
# Manually check for jobs
foreach ($printer in (Get-Printer)) {
    $jobs = Get-PrintJob -PrinterName $printer.Name
    if ($jobs) {
        $jobs | Format-Table PrinterName, Id, JobStatus, SubmittedTime
    }
}
```

3. **Adjust age threshold:**
```powershell
# Change from 1 hour to 30 minutes
$stuckJobs = $allJobs | Where-Object { 
    $_.JobStatus -match 'Error|Paused|Blocked|UserIntervention' -or 
    ((Get-Date) - $_.SubmittedTime).TotalMinutes -gt 30  # More sensitive
}
```

### Issue: HTML Table Not Displaying

**Symptoms:**
- `printPrinterSummary` field blank or shows raw HTML
- Dashboard doesn't render table

**Causes:**
- WYSIWYG field not configured
- HTML sanitization removing table
- Special characters in printer names

**Solutions:**

1. **Verify field type:**
```
NinjaRMM Custom Field Settings:
- Field Name: printPrinterSummary
- Field Type: WYSIWYG (NOT Text)
```

2. **Escape special characters:**
```powershell
# HTML-encode printer names
$printerNameSafe = [System.Web.HttpUtility]::HtmlEncode($printerName)
$htmlRows += "<tr><td>$printerNameSafe</td>..."
```

3. **Test HTML validity:**
```powershell
# Output HTML to file for inspection
$printerSummary | Out-File "C:\Temp\PrinterSummary.html"
# Open in browser to verify rendering
```

---

## Performance Optimization

### Parallel Printer Queries

For servers with many printers:

```powershell
# Use runspaces for parallel job enumeration
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
$runspacePool.Open()

$jobs = @()
foreach ($printer in $printers) {
    $scriptBlock = {
        param($printerName)
        $jobCount = (Get-PrintJob -PrinterName $printerName -ErrorAction SilentlyContinue).Count
        return $jobCount
    }
    
    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($printer.Name)
    $powershell.RunspacePool = $runspacePool
    
    $jobs += [PSCustomObject]@{
        Printer = $printer.Name
        Pipe = $powershell
        Result = $powershell.BeginInvoke()
    }
}

# Collect results
foreach ($job in $jobs) {
    $jobCount = $job.Pipe.EndInvoke($job.Result)
    Write-Output "$($job.Printer): $jobCount jobs"
    $job.Pipe.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()
```

---

## Summary

**PrintServerMonitor_v3.ps1** provides comprehensive monitoring for Windows Print Server infrastructure, offering critical visibility into printer availability, queue health, and stuck job detection. This monitoring prevents print service disruptions and enables proactive intervention before users are impacted.

### Key Takeaways

1. **Offline Detection**: Immediate alerts when printers become unavailable prevent extended service outages
2. **Stuck Job Management**: Early detection of queue blockages maintains print service throughput
3. **Error State Monitoring**: Paper jams and hardware issues caught before queues back up
4. **Dashboard Visibility**: HTML summaries provide at-a-glance infrastructure health assessment
5. **Proactive Maintenance**: Error patterns guide printer maintenance scheduling

### Recommended Implementation

- **Regular Monitoring**: Every 4 hours for standard environments
- **Business Hours Monitoring**: Every 30 minutes during peak usage (8 AM - 6 PM)
- **Critical Alerts**: Immediate notification for offline printers
- **Warning Alerts**: Email for printer errors and stuck jobs
- **Dashboard Integration**: Visual printer status and queue metrics

---

**Script Location:** [`plaintext_scripts/PrintServerMonitor_v3.ps1`](https://github.com/Xore/waf/blob/main/plaintext_scripts/PrintServerMonitor_v3.ps1)

**Related Documentation:**
- [Monitoring Overview](../Monitoring-Overview.md)
- [NinjaRMM Custom Fields Guide](../NinjaRMM-CustomFields.md)
- [Alert Configuration Guide](../Alert-Configuration.md)

**Last Updated:** February 12, 2026  
**Framework Version:** 4.0