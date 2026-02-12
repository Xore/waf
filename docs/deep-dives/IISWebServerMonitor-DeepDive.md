# IISWebServerMonitor.ps1 - Deep Dive Guide

## Overview

**IISWebServerMonitor.ps1** is a comprehensive monitoring solution for Microsoft Internet Information Services (IIS) web server infrastructure, tracking application pool health, worker processes, request throughput, queue depths, and error rates. This script is essential for maintaining high-availability web services, preventing application pool failures, and ensuring SLA compliance for Windows-based web hosting environments.

### Key Capabilities

- **Application Pool Management**: Automated detection of stopped or crashed application pools
- **Worker Process Monitoring**: Real-time tracking of w3wp.exe processes and process health
- **Request Performance Tracking**: Throughput monitoring and capacity planning metrics
- **Queue Depth Analysis**: Early warning system for performance degradation and saturation
- **Error Rate Monitoring**: Event log analysis for application and service failures
- **Multi-Tenant Support**: Virtual host (vhost) inventory for shared hosting environments

---

## Technical Architecture

### Monitoring Scope

```
IIS Web Server Infrastructure
├── Installation Detection
│   ├── Web-Server feature verification
│   ├── WebAdministration module availability
│   ├── IIS version detection (registry)
│   └── Graceful exit if not installed
│
├── Website Inventory
│   ├── Virtual host enumeration (Get-Website)
│   ├── Site count for multi-tenant tracking
│   └── Configured vs. active sites
│
├── Application Pool Management
│   ├── Total pool count (Get-IISAppPool)
│   ├── Running pool identification
│   ├── Stopped pool detection (critical)
│   └── Pool state classification
│
├── Worker Process Monitoring
│   ├── Active w3wp.exe count
│   ├── Process-to-pool mapping
│   ├── Memory and CPU per worker
│   └── Zero workers = service failure
│
├── Performance Metrics
│   ├── Request rate (req/sec)
│   ├── Request queue depth
│   ├── Throughput capacity assessment
│   └── Saturation detection
│
└── Error Monitoring
    ├── System event log queries
    ├── IIS-specific providers
    ├── 24-hour error aggregation
    └── Last error message capture
```

### Data Collection Flow

```
1. Role Verification
   └→ Web-Server feature installed?
       ├→ No: Record Unknown status, exit gracefully
       └→ Yes: Continue monitoring

2. Module Loading
   └→ Import-Module WebAdministration
       ├→ Success: Proceed with IIS cmdlets
       └→ Failure: Check IIS Management Tools installation

3. Version Detection
   └→ Registry: HKLM:\SOFTWARE\Microsoft\InetStp
       ├→ MajorVersion, MinorVersion
       └→ Format as "IIS X.Y"

4. Website Enumeration
   └→ Get-Website → Count virtual hosts
       └→ Multi-tenant capacity metric

5. Application Pool Analysis
   └→ Get-IISAppPool
       ├→ Count total pools
       ├→ Identify stopped pools (State ≠ 'Started')
       └→ Log stopped pool names

6. Worker Process Tracking
   └→ Get-Process w3wp → Count active workers
       └→ Zero workers with sites = Warning

7. Performance Collection
   ├→ Counter: \Web Service(_Total)\Total Method Requests/sec
   └→ Counter: \HTTP Service Request Queues(_Total)\CurrentQueueSize

8. Error Analysis
   └→ Query System log (24h)
       ├→ Providers: Microsoft-Windows-IIS*, W3SVC*
       ├→ Level: 1 (Critical), 2 (Error)
       ├→ Count total errors
       └→ Capture last error message (max 1000 chars)

9. Health Classification
   └→ appPoolsStopped > 0? → Critical
   └→ errorCount24h > 50 OR requestQueueLength > 1000? → Warning
   └→ workerProcesses = 0 AND vhostCount > 0? → Warning
   └→ Else: Healthy
```

---

## Field Reference

### Custom Fields Configuration

```powershell
# Boolean Fields
iisInstalled                # Checkbox: IIS installed status

# Integer Fields
iisVHostCount               # Configured virtual hosts (websites)
iisRequestsPerSecond        # Current request rate
iisErrorCount24h            # Error events in last 24 hours
iisWorkerProcesses          # Active w3wp.exe count
iisAppPoolCount             # Total application pools
iisAppPoolsStopped          # Stopped pools (CRITICAL metric)
iisRequestQueueLength       # Current request queue depth

# Text Fields
iisVersion                  # IIS version (e.g., "IIS 10.0")
iisLastError                # Most recent error message (max 1000 chars)
iisHealthStatus             # Dropdown: Healthy|Warning|Critical|Unknown
```

### Field Value Examples

**Healthy IIS Server:**
```
iisInstalled = true
iisVersion = "IIS 10.0"
iisVHostCount = 5
iisRequestsPerSecond = 45
iisErrorCount24h = 8
iisWorkerProcesses = 5
iisAppPoolCount = 6
iisAppPoolsStopped = 0
iisRequestQueueLength = 12
iisLastError = "None"
iisHealthStatus = "Healthy"
```

**Warning State (High Queue):**
```
iisRequestQueueLength = 1500
iisErrorCount24h = 65
iisHealthStatus = "Warning"
```

**Critical State (App Pool Stopped):**
```
iisAppPoolsStopped = 2
iisWorkerProcesses = 3 (down from 5)
iisHealthStatus = "Critical"
iisLastError = "Application pool 'DefaultAppPool' has been disabled..."
```

---

## Monitoring Logic Details

### Application Pool State Management

Application pools provide process isolation and resource boundaries:

```powershell
# Application pool state detection
$appPools = Get-IISAppPool
$appPoolsStopped = ($appPools | Where-Object { $_.State -ne 'Started' }).Count

if ($appPoolsStopped -gt 0) {
    $stoppedNames = ($appPools | Where-Object { $_.State -ne 'Started' }).Name -join ', '
    # CRITICAL: Stopped pools mean unavailable websites
}
```

**Application Pool States:**

| State | Description | Impact | Action Required |
|-------|-------------|--------|------------------|
| **Started** | Running normally | None | Monitor performance |
| **Stopped** | Manually stopped or failed | Site unavailable | Investigate cause, restart pool |
| **Stopping** | Shutdown in progress | Partial availability | Wait or investigate hang |
| **Starting** | Startup in progress | Temporary unavail | Wait or check startup errors |

**Common Causes of Stopped Pools:**
- Application crashes (unhandled exceptions)
- Rapid-fail protection triggered (5 crashes in 5 minutes)
- Identity account password expired
- Insufficient permissions for app pool identity
- Manual stop for maintenance
- Resource exhaustion (memory, handles)

### Worker Process Monitoring

Each w3wp.exe process represents an application pool worker:

```powershell
# Worker process enumeration
$workerProcesses = (Get-Process -Name w3wp -ErrorAction SilentlyContinue).Count

# Zero workers with configured sites = problem
if ($workerProcesses -eq 0 -and $vhostCount -gt 0) {
    # No workers serving sites - service failure or idle timeout
}
```

**Worker Process Characteristics:**
- **One process per app pool** (default, can be multiple for web gardens)
- **Process recycling**: Periodic or on-demand for memory management
- **Idle timeout**: Workers shut down after 20 minutes of inactivity (default)
- **Startup mode**: AlwaysRunning vs. OnDemand

**Worker Process Metrics:**
```powershell
# Get detailed worker process information
$workers = Get-Process w3wp | Select-Object Id, WorkingSet64, CPU, StartTime
foreach ($worker in $workers) {
    $memoryMB = [Math]::Round($worker.WorkingSet64 / 1MB, 2)
    $uptime = (Get-Date) - $worker.StartTime
    # High memory (>2GB) or frequent restarts indicate issues
}
```

### Request Performance Tracking

Real-time throughput monitoring:

```powershell
# Request rate from performance counter
$requestsPerSecond = (Get-Counter "\Web Service(_Total)\Total Method Requests/sec").CounterSamples.CookedValue
```

**Request Rate Baselines:**

| Site Type | Typical Rate | High Load | Alert Threshold |
|-----------|--------------|-----------|------------------|
| Small business site | 1-10 req/s | 20-50 req/s | >100 req/s |
| Medium corporate site | 10-50 req/s | 100-200 req/s | >500 req/s |
| High-traffic web app | 100-500 req/s | 1000-2000 req/s | >3000 req/s |
| Enterprise portal | 500-2000 req/s | 5000-10000 req/s | >15000 req/s |

**Request Rate Patterns:**
- **Sudden spike**: Traffic surge, DDoS attack, bot crawling
- **Sudden drop**: Application failure, network issue, upstream problem
- **Gradual increase**: Organic growth, successful campaign
- **Oscillating pattern**: Load balancer health check, scheduled tasks

### Request Queue Analysis

Queue depth indicates saturation and performance degradation:

```powershell
# HTTP.sys request queue depth
$requestQueueLength = (Get-Counter "\HTTP Service Request Queues(_Total)\CurrentQueueSize").CounterSamples.CookedValue
```

**Queue Depth Interpretation:**

- **0-100**: Healthy - Requests processed immediately
- **100-500**: Acceptable - Minor delays under load
- **500-1000**: Warning - Performance degradation noticeable
- **>1000**: Critical - Significant user-facing delays
- **>5000**: Severe - Service effectively unavailable

**Causes of High Queue Depth:**
1. **Insufficient worker processes**: Increase queue limit or app pool workers
2. **Slow backend**: Database queries, API calls, external dependencies
3. **Thread starvation**: Synchronous operations blocking threads
4. **Memory pressure**: Excessive garbage collection pauses
5. **CPU saturation**: Complex processing, inefficient code

**Relationship to Worker Processes:**
```
Queue Length / Worker Process = ~200-500 requests per process

Example:
- Queue: 2000 requests
- Workers: 2 processes
- Load: 1000 requests/process (OVERLOADED)

Solution: Increase worker processes or add web servers
```

### Error Rate Monitoring

Event log analysis for application and service failures:

```powershell
# IIS error detection (24-hour window)
$iisErrors = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-IIS*', 'W3SVC*'
    Level = 1,2  # Critical and Error
    StartTime = (Get-Date).AddHours(-24)
}

$errorCount24h = $iisErrors.Count
$lastError = ($iisErrors | Select-Object -First 1).Message
```

**Common IIS Event IDs:**

| Event ID | Source | Description | Severity |
|----------|--------|-------------|----------|
| **2268** | W3SVC | Worker process failed to initialize | Critical |
| **2282** | W3SVC | Application pool disabled due to rapid-fail | Critical |
| **5002** | WAS | App pool identity invalid | Error |
| **5021** | WAS | App pool recycled | Warning |
| **5186** | WAS | Failed to initialize runtime | Critical |

**Error Rate Thresholds:**
- **0-10 errors/24h**: Normal (transient issues, expected restarts)
- **10-50 errors/24h**: Acceptable (monitor for patterns)
- **>50 errors/24h**: Warning (investigate application issues)
- **>200 errors/24h**: Critical (major service degradation)

### Health Status Logic

Multi-factor health assessment:

```
Health Status Decision Tree:

appPoolsStopped > 0?
├→ Yes: CRITICAL (sites unavailable)
└→ No: Check next condition
    
    errorCount24h > 50 OR requestQueueLength > 1000?
    ├→ Yes: WARNING (degraded performance)
    └→ No: Check next condition
        
        workerProcesses = 0 AND vhostCount > 0?
        ├→ Yes: WARNING (no workers for configured sites)
        └→ No: HEALTHY
```

**Status Meanings:**
- **Healthy**: All pools running, normal error rates, acceptable queues
- **Warning**: Performance degraded, high errors, or idle workers
- **Critical**: Stopped app pools, sites unavailable, service failure
- **Unknown**: IIS not installed or monitoring failure

---

## Real-World Scenarios

### Scenario 1: Application Pool Rapid-Fail Protection

**Symptom:**
```
iisAppPoolsStopped = 1
iisHealthStatus = "Critical"
iisLastError = "Application pool 'MyAppPool' has been disabled due to a series of failures..."
iisWorkerProcesses = 4 (down from 5)
```

**Investigation Steps:**

1. **Check application pool configuration:**
```powershell
# Review rapid-fail protection settings
Get-ItemProperty "IIS:\AppPools\MyAppPool" | Select-Object Name, State

# Check failure settings
Get-ItemProperty "IIS:\AppPools\MyAppPool" -Name failure | Format-List

# Typical settings:
# - rapidFailProtection: True
# - rapidFailProtectionInterval: 5 minutes
# - rapidFailProtectionMaxCrashes: 5
```

2. **Review application event log:**
```powershell
# Check for .NET application errors
Get-WinEvent -LogName Application -ProviderName "ASP.NET*" -MaxEvents 50 | 
    Where-Object { $_.LevelDisplayName -eq "Error" } | 
    Select-Object TimeCreated, Message | Format-Table -Wrap

# Common crash causes:
# - Unhandled exceptions
# - OutOfMemoryException
# - StackOverflowException
# - Configuration errors
```

3. **Check IIS logs for error patterns:**
```powershell
# Parse IIS logs for 500 errors
$iisLogPath = "C:\inetpub\logs\LogFiles\W3SVC1"
$logFiles = Get-ChildItem $iisLogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 3

foreach ($logFile in $logFiles) {
    Get-Content $logFile.FullName | Select-String "500" | Select-Object -First 10
}
```

**Common Root Causes:**
- Application code throwing unhandled exceptions
- Database connection failures (connection string, permissions)
- Missing dependencies (DLLs, configuration files)
- Memory leaks causing OutOfMemoryException
- File system permissions preventing file access

**Resolution:**

1. **Fix underlying application issue**
2. **Restart the application pool:**
```powershell
Restart-WebAppPool -Name "MyAppPool"

# Or if disabled, re-enable first:
Set-WebAppPoolState -Name "MyAppPool" -State Started
```

3. **Adjust rapid-fail settings if crashes are transient:**
```powershell
# Increase crash tolerance (use cautiously)
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name failure.rapidFailProtectionMaxCrashes -Value 10
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name failure.rapidFailProtectionInterval -Value "00:10:00"
```

### Scenario 2: High Request Queue Backlog

**Symptom:**
```
iisRequestQueueLength = 3500
iisRequestsPerSecond = 150
iisHealthStatus = "Warning"
User reports: "Website extremely slow"
```

**Investigation Steps:**

1. **Check worker process resource usage:**
```powershell
# Identify resource-constrained workers
Get-Process w3wp | Select-Object Id, 
    @{N='MemoryMB';E={[Math]::Round($_.WorkingSet64/1MB,2)}},
    @{N='CPU%';E={$_.CPU}},
    @{N='Threads';E={$_.Threads.Count}} | Format-Table

# High CPU (>80%) or memory (>2GB) indicates bottleneck
```

2. **Analyze request distribution:**
```powershell
# Check current requests per app pool
$appMgrObject = Get-WmiObject -Namespace "root\WebAdministration" -Class "ApplicationPool"
foreach ($pool in $appMgrObject) {
    Write-Output "$($pool.Name): Current Requests = $($pool.CurrentWorkerProcesses)"
}
```

3. **Review application pool queue limit:**
```powershell
# Check queue length setting
Get-ItemProperty "IIS:\AppPools\MyAppPool" -Name queueLength

# Default: 1000
# If queue exceeds this, requests are rejected with 503
```

**Common Causes:**
- Slow database queries blocking worker threads
- External API calls with high latency
- Insufficient worker processes for load
- Thread pool starvation (async/await issues)
- Long-running synchronous operations

**Resolution:**

1. **Increase worker process count (web garden):**
```powershell
# Increase to 4 worker processes per app pool
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name processModel.maxProcesses -Value 4

# NOTE: Web gardens complicate session state - use out-of-process sessions
```

2. **Increase queue length:**
```powershell
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name queueLength -Value 5000
```

3. **Optimize application code:**
   - Convert synchronous operations to async
   - Implement caching for expensive operations
   - Optimize database queries
   - Use connection pooling

4. **Scale horizontally:**
   - Add additional web servers behind load balancer
   - Implement Application Request Routing (ARR)

### Scenario 3: Zero Workers Despite Active Sites

**Symptom:**
```
iisWorkerProcesses = 0
iisVHostCount = 3
iisAppPoolsStopped = 0
iisHealthStatus = "Warning"
Websites return 503 or timeout on first request
```

**Investigation Steps:**

1. **Check application pool startup mode:**
```powershell
# Check if pools are configured for on-demand start
Get-IISAppPool | Select-Object Name, State, 
    @{N='StartMode';E={$_.StartMode}}

# StartMode: OnDemand (default) vs. AlwaysRunning
```

2. **Verify idle timeout settings:**
```powershell
# Check idle timeout
Get-ItemProperty "IIS:\AppPools\*" -Name processModel.idleTimeout | Format-Table

# Default: 20 minutes
# Workers shut down after idle timeout if no requests
```

3. **Test site accessibility:**
```powershell
# Trigger worker process start
Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing

# Check if worker spawned
$newWorkerCount = (Get-Process w3wp -ErrorAction SilentlyContinue).Count
Write-Output "Workers after request: $newWorkerCount"
```

**Common Causes:**
- Idle timeout expired (expected behavior for low-traffic sites)
- Application preloading not configured
- AlwaysRunning not set for critical apps
- Startup failures not generating errors

**Resolution:**

1. **Configure AlwaysRunning for critical applications:**
```powershell
# Set application pool to AlwaysRunning
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name startMode -Value "AlwaysRunning"

# Enable application preload
Set-ItemProperty "IIS:\Sites\MySite" -Name applicationDefaults.preloadEnabled -Value $true
```

2. **Disable idle timeout for critical pools:**
```powershell
# Set idle timeout to 0 (never time out)
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name processModel.idleTimeout -Value "00:00:00"
```

3. **Implement application warm-up:**
```powershell
# Install Application Initialization module
Install-WindowsFeature Web-AppInit

# Configure warm-up URLs
$warmupConfig = @'
<applicationInitialization>
    <add initializationPage="/warmup.aspx" />
    <add initializationPage="/api/health" />
</applicationInitialization>
'@

# Add to web.config or applicationHost.config
```

### Scenario 4: Memory Leak in Application Pool

**Symptom:**
```
iisWorkerProcesses = 5
Worker memory growing: 500MB → 1.5GB → 2.5GB over hours
Eventual OutOfMemoryException and pool crash
```

**Investigation Steps:**

1. **Monitor worker memory over time:**
```powershell
# Track memory growth
$iterations = 60  # Monitor for 1 hour
$interval = 60    # Check every minute

for ($i = 0; $i -lt $iterations; $i++) {
    $workers = Get-Process w3wp | Select-Object Id, 
        @{N='MemoryMB';E={[Math]::Round($_.WorkingSet64/1MB,2)}},
        StartTime
    
    $workers | Add-Member -NotePropertyName "Timestamp" -NotePropertyValue (Get-Date)
    $workers | Export-Csv "C:\Temp\WorkerMemory.csv" -Append -NoTypeInformation
    
    Start-Sleep -Seconds $interval
}
```

2. **Configure memory recycling:**
```powershell
# Check current recycling settings
Get-ItemProperty "IIS:\AppPools\MyAppPool" -Name recycling | Format-List

# Check if memory-based recycling is configured
Get-ItemProperty "IIS:\AppPools\MyAppPool" -Name recycling.periodicRestart.memory
```

3. **Capture memory dump for analysis:**
```powershell
# Identify worker PID
$workerPID = (Get-Process w3wp | Sort-Object WorkingSet64 -Descending)[0].Id

# Create memory dump (requires procdump.exe from Sysinternals)
procdump.exe -ma $workerPID "C:\Dumps\w3wp_$workerPID.dmp"

# Analyze with WinDbg or Visual Studio for memory leaks
```

**Resolution:**

1. **Implement memory-based recycling:**
```powershell
# Recycle when memory exceeds 1.5 GB
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name recycling.periodicRestart.memory -Value 1572864  # KB
```

2. **Configure periodic recycling:**
```powershell
# Recycle daily at 3 AM
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name recycling.periodicRestart.schedule -Value @{value="03:00:00"}
```

3. **Set request-based recycling:**
```powershell
# Recycle after 100,000 requests
Set-ItemProperty "IIS:\AppPools\MyAppPool" -Name recycling.periodicRestart.requests -Value 100000
```

---

## NinjaRMM Integration

### Automation Policy Setup

**Regular Monitoring (Every 4 Hours):**
```yaml
Policy Name: IIS - Health Check
Schedule: Every 4 hours (0:00, 4:00, 8:00, 12:00, 16:00, 20:00)
Script: IISWebServerMonitor.ps1
Timeout: 90 seconds
Context: SYSTEM
Conditions:
  - Web-Server feature installed
  - OS Type = Windows Server
```

**High-Frequency Monitoring (Critical Environments):**
```yaml
Policy Name: IIS - Critical Site Monitoring
Schedule: Every 15 minutes
Script: IISWebServerMonitor.ps1
Timeout: 60 seconds
Purpose: Rapid detection of pool failures for mission-critical sites
```

### Alert Conditions

**Critical Alert - Application Pool Stopped:**
```
Condition: iisAppPoolsStopped > 0
Alert: Email + SMS + Ticket
Priority: P1
Subject: CRITICAL: IIS Application Pool Stopped - {{device.name}}
Body: |
  One or more IIS application pools have stopped.
  
  Stopped Pools: {{custom.iisAppPoolsStopped}}
  Last Error: {{custom.iisLastError}}
  Worker Processes: {{custom.iisWorkerProcesses}}
  
  IMMEDIATE ACTION REQUIRED - Websites may be unavailable.
  Review application logs and restart affected pools.
```

**Warning Alert - High Request Queue:**
```
Condition: iisRequestQueueLength > 1000
Alert: Email + Ticket
Priority: P2
Subject: WARNING: IIS High Request Queue - {{device.name}}
Body: |
  IIS request queue is experiencing backlog.
  
  Queue Length: {{custom.iisRequestQueueLength}}
  Request Rate: {{custom.iisRequestsPerSecond}} req/sec
  Worker Processes: {{custom.iisWorkerProcesses}}
  
  Performance degradation detected. Consider scaling or optimization.
```

**Warning Alert - High Error Rate:**
```
Condition: iisErrorCount24h > 50
Alert: Email
Priority: P3
Subject: WARNING: IIS High Error Rate - {{device.name}}
Body: |
  IIS experiencing elevated error rate.
  
  Errors (24h): {{custom.iisErrorCount24h}}
  Last Error: {{custom.iisLastError}}
  Health Status: {{custom.iisHealthStatus}}
  
  Review application logs and event viewer for details.
```

**Info Alert - No Worker Processes:**
```
Condition: iisWorkerProcesses = 0 AND iisVHostCount > 0
Alert: Email
Subject: INFO: IIS No Active Workers - {{device.name}}
Body: |
  IIS has no active worker processes despite configured sites.
  
  Virtual Hosts: {{custom.iisVHostCount}}
  App Pools Stopped: {{custom.iisAppPoolsStopped}}
  
  May be idle timeout (expected) or startup failure (investigate).
```

### Dashboard Widgets

**IIS Health Status Widget:**
```
Widget Type: Status Indicator
Field: iisHealthStatus
Title: IIS Web Server Health
Colors:
  Healthy: Green
  Warning: Yellow
  Critical: Red
  Unknown: Gray
```

**Performance Metrics Widget:**
```
Widget Type: Multi-Metric Display
Fields:
  - iisVHostCount (Virtual Hosts)
  - iisAppPoolCount (App Pools)
  - iisWorkerProcesses (Workers)
  - iisRequestsPerSecond (Req/Sec)
  - iisRequestQueueLength (Queue)
Title: IIS Performance Metrics
```

**Error Summary Widget:**
```
Widget Type: Text Display
Fields:
  - iisErrorCount24h (Error Count)
  - iisLastError (Last Error Message)
Title: IIS Errors (24h)
Refresh: On field update
```

---

## Advanced Customization

### Example 1: Per-Site Performance Tracking

Monitor individual website metrics:

```powershell
# Add after website enumeration
Write-Output "INFO: Collecting per-site metrics..."

$siteMetrics = @()
foreach ($site in Get-Website) {
    try {
        $siteName = $site.Name
        $siteState = $site.State
        $appPoolName = $site.ApplicationPool
        
        # Get site-specific performance counters
        $siteCounterPath = "\Web Service($siteName)\Current Connections"
        $connections = [Math]::Round((Get-Counter -Counter $siteCounterPath -ErrorAction SilentlyContinue).CounterSamples.CookedValue)
        
        $siteMetrics += [PSCustomObject]@{
            Site = $siteName
            State = $siteState
            AppPool = $appPoolName
            Connections = $connections
        }
        
        Write-Output "  $siteName: $connections connections, $siteState"
    } catch {
        Write-Output "  WARNING: Failed to get metrics for $siteName"
    }
}

# Build HTML report
$siteRows = $siteMetrics | ForEach-Object {
    "<tr><td>$($_.Site)</td><td>$($_.State)</td><td>$($_.AppPool)</td><td>$($_.Connections)</td></tr>"
}

$siteReport = @"
<table border='1' style='border-collapse:collapse; width:100%;'>
<tr style='background-color:#f0f0f0;'><th>Site</th><th>State</th><th>App Pool</th><th>Connections</th></tr>
$($siteRows -join "`n")
</table>
"@

Ninja-Property-Set iisSiteMetrics $siteReport
```

### Example 2: SSL Certificate Expiration Monitoring

Track SSL certificate expiration for HTTPS bindings:

```powershell
# Add after website enumeration
Write-Output "INFO: Checking SSL certificate expiration..."

$expiringCerts = @()
foreach ($site in Get-Website) {
    foreach ($binding in $site.Bindings.Collection) {
        if ($binding.Protocol -eq "https" -and $binding.certificateHash) {
            try {
                $certHash = $binding.certificateHash
                $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $certHash }
                
                if ($cert) {
                    $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
                    
                    if ($daysUntilExpiry -lt 30) {
                        $expiringCerts += "$($site.Name): Certificate expires in $daysUntilExpiry days"
                        Write-Output "  WARNING: $($site.Name) cert expires in $daysUntilExpiry days"
                    }
                }
            } catch {
                Write-Output "  WARNING: Failed to check certificate for $($site.Name)"
            }
        }
    }
}

if ($expiringCerts.Count -gt 0) {
    $certReport = $expiringCerts -join "<br>"
    Ninja-Property-Set iisExpiringCerts $certReport
    
    if ($healthStatus -eq "Healthy") {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - Expiring SSL certificates"
    }
}
```

### Example 3: Failed Request Tracing Analysis

Identify slow requests from Failed Request Tracing logs:

```powershell
# Add after error monitoring
Write-Output "INFO: Analyzing Failed Request Tracing logs..."

try {
    $frebLogPath = "C:\inetpub\logs\FailedReqLogFiles"
    
    if (Test-Path $frebLogPath) {
        # Find recent FREB logs (last 24 hours)
        $recentFrebs = Get-ChildItem -Path $frebLogPath -Recurse -Filter "*.xml" | 
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) }
        
        $frebCount = $recentFrebs.Count
        Write-Output "  Failed requests logged: $frebCount"
        
        if ($frebCount -gt 100) {
            Write-Output "  WARNING: High volume of failed requests"
            
            # Parse top failures
            $frebSummary = $recentFrebs | ForEach-Object {
                [xml]$frebXml = Get-Content $_.FullName
                $url = $frebXml.failedRequest.url
                $statusCode = $frebXml.failedRequest.statusCode
                [PSCustomObject]@{ Url = $url; StatusCode = $statusCode }
            } | Group-Object Url | Sort-Object Count -Descending | Select-Object -First 5
            
            $frebReport = ($frebSummary | ForEach-Object { 
                "$($_.Name): $($_.Count) failures" 
            }) -join "<br>"
            
            Ninja-Property-Set iisTopFailures $frebReport
        }
        
        Ninja-Property-Set iisFrebCount $frebCount
    }
} catch {
    Write-Output "WARNING: Failed to analyze FREB logs: $_"
}
```

### Example 4: Application Pool Identity Auditing

Verify application pool identity accounts:

```powershell
# Add after application pool enumeration
Write-Output "INFO: Auditing application pool identities..."

$identityIssues = @()
foreach ($pool in Get-IISAppPool) {
    try {
        $identity = $pool.ProcessModel.IdentityType
        $userName = $pool.ProcessModel.UserName
        
        Write-Output "  $($pool.Name): $identity"
        
        # Check for risky identity types
        if ($identity -eq "LocalSystem") {
            $identityIssues += "$($pool.Name) runs as LocalSystem (excessive privileges)"
        }
        
        # Check for custom accounts
        if ($identity -eq "SpecificUser" -and $userName) {
            # Verify account exists and is enabled
            try {
                $adUser = Get-ADUser $userName -Properties Enabled -ErrorAction Stop
                
                if (-not $adUser.Enabled) {
                    $identityIssues += "$($pool.Name) identity account disabled: $userName"
                }
            } catch {
                # Not an AD account or account not found
            }
        }
    } catch {
        Write-Output "  WARNING: Failed to check identity for $($pool.Name)"
    }
}

if ($identityIssues.Count -gt 0) {
    $identityReport = $identityIssues -join "<br>"
    Ninja-Property-Set iisIdentityIssues $identityReport
    
    Write-Output "  WARNING: Identity configuration issues detected"
}
```

### Example 5: Request Execution Time Tracking

Monitor request execution time from IIS logs:

```powershell
# Add after performance collection
Write-Output "INFO: Analyzing request execution times..."

try {
    # Parse most recent IIS log
    $logPath = "C:\inetpub\logs\LogFiles"
    $latestLog = Get-ChildItem -Path $logPath -Recurse -Filter "*.log" | 
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($latestLog) {
        # Parse time-taken field (last field in W3C format)
        $logLines = Get-Content $latestLog.FullName | Select-Object -Last 1000
        
        $executionTimes = $logLines | ForEach-Object {
            if ($_ -match "^\d") {  # Skip header lines
                $fields = $_ -split " "
                if ($fields.Count -gt 0) {
                    $timeTaken = [int]($fields[-1])  # Last field is time-taken in ms
                    $timeTaken
                }
            }
        } | Where-Object { $_ -ne $null }
        
        if ($executionTimes.Count -gt 0) {
            $avgTime = [Math]::Round(($executionTimes | Measure-Object -Average).Average)
            $maxTime = ($executionTimes | Measure-Object -Maximum).Maximum
            $slowRequests = ($executionTimes | Where-Object { $_ -gt 5000 }).Count
            
            Write-Output "  Avg execution: $avgTime ms"
            Write-Output "  Max execution: $maxTime ms"
            Write-Output "  Slow requests (>5s): $slowRequests"
            
            Ninja-Property-Set iisAvgExecutionTime $avgTime
            Ninja-Property-Set iisSlowRequestCount $slowRequests
            
            if ($avgTime -gt 3000) {
                Write-Output "  WARNING: High average execution time"
                
                if ($healthStatus -eq "Healthy") {
                    $healthStatus = "Warning"
                }
            }
        }
    }
} catch {
    Write-Output "WARNING: Failed to analyze execution times: $_"
}
```

### Example 6: Compression Configuration Audit

Verify compression is enabled for bandwidth optimization:

```powershell
# Add after server configuration
Write-Output "INFO: Auditing compression settings..."

try {
    # Check static compression
    $staticComp = Get-WebConfigurationProperty -PSPath "MACHINE/WEBROOT/APPHOST" `
        -Filter "system.webServer/httpCompression" -Name "directory"
    
    $staticEnabled = Get-WebConfigurationProperty -PSPath "MACHINE/WEBROOT/APPHOST" `
        -Filter "system.webServer/httpCompression/scheme[@name='gzip']" -Name "doStaticCompression"
    
    $dynamicEnabled = Get-WebConfigurationProperty -PSPath "MACHINE/WEBROOT/APPHOST" `
        -Filter "system.webServer/httpCompression/scheme[@name='gzip']" -Name "doDynamicCompression"
    
    Write-Output "  Static compression: $($staticEnabled.Value)"
    Write-Output "  Dynamic compression: $($dynamicEnabled.Value)"
    
    Ninja-Property-Set iisStaticCompression $staticEnabled.Value
    Ninja-Property-Set iisDynamicCompression $dynamicEnabled.Value
    
    if (-not $staticEnabled.Value -and -not $dynamicEnabled.Value) {
        Write-Output "  WARNING: Compression disabled (increased bandwidth usage)"
    }
} catch {
    Write-Output "WARNING: Failed to check compression: $_"
}
```

---

## Troubleshooting Guide

### Issue: WebAdministration Module Not Loading

**Symptoms:**
- Script fails with "Module not found"
- Get-Website cmdlet unavailable

**Causes:**
- IIS Management Tools not installed
- PowerShell module path issue

**Solutions:**

1. **Install IIS Management Tools:**
```powershell
Install-WindowsFeature Web-Mgmt-Tools -IncludeAllSubFeature
```

2. **Verify module exists:**
```powershell
Get-Module -ListAvailable WebAdministration

# Should show module path
```

3. **Manual module import:**
```powershell
Import-Module "$env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\WebAdministration\WebAdministration.psd1"
```

### Issue: Performance Counters Return Zero

**Symptoms:**
- `iisRequestsPerSecond = 0` despite traffic
- Counter not found errors

**Causes:**
- Performance counter corruption
- IIS counters not registered
- Service recently restarted

**Solutions:**

1. **Rebuild performance counters:**
```cmd
cd C:\Windows\System32
lodctr /R
```

2. **Re-register IIS counters:**
```cmd
cd C:\Windows\System32\inetsrv
appcmd.exe install module /name:"HttpLoggingModule"
```

3. **Check counter availability:**
```powershell
Get-Counter -ListSet "Web Service" | Select-Object -ExpandProperty Counter
```

### Issue: Event Log Query Slow or Times Out

**Symptoms:**
- Script exceeds timeout
- High CPU during event log query

**Causes:**
- Large System event log
- Excessive IIS events

**Solutions:**

1. **Limit query scope:**
```powershell
# Query last 6 hours instead of 24
$startTime = (Get-Date).AddHours(-6)

# Limit results
$iisErrors = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-IIS*'
    Level = 1,2
    StartTime = $startTime
    MaxEvents = 100
}
```

2. **Archive old logs:**
```powershell
wevtutil.exe archive-log System "C:\EventArchive\System_$(Get-Date -Format 'yyyyMMdd').evtx"
wevtutil.exe clear-log System /bu:"C:\EventArchive\System_backup.evtx"
```

---

## Performance Optimization

### Parallel Site Enumeration

For servers with many websites:

```powershell
# Parallel site metrics collection
$sites = Get-Website
$jobs = @()

foreach ($site in $sites) {
    $jobs += Start-Job -ScriptBlock {
        param($siteName)
        
        try {
            $counterPath = "\Web Service($siteName)\Current Connections"
            $connections = (Get-Counter -Counter $counterPath).CounterSamples.CookedValue
            
            [PSCustomObject]@{
                Site = $siteName
                Connections = $connections
            }
        } catch {
            $null
        }
    } -ArgumentList $site.Name
}

# Wait for completion
$results = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job
```

---

## Integration Examples

### Example 1: Application Insights Integration

Export IIS metrics to Azure Application Insights:

```powershell
# After metrics collection
$instrumentationKey = "your-app-insights-key"
$endpoint = "https://dc.services.visualstudio.com/v2/track"

$telemetry = @{
    name = "Microsoft.ApplicationInsights.Metric"
    time = (Get-Date).ToUniversalTime().ToString("o")
    iKey = $instrumentationKey
    data = @{
        baseType = "MetricData"
        baseData = @{
            metrics = @(
                @{ name = "IIS.RequestRate"; value = $requestsPerSecond }
                @{ name = "IIS.QueueLength"; value = $requestQueueLength }
                @{ name = "IIS.WorkerProcesses"; value = $workerProcesses }
                @{ name = "IIS.AppPoolsStopped"; value = $appPoolsStopped }
            )
            properties = @{
                server = $env:COMPUTERNAME
                version = $iisVersion
            }
        }
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Method Post -Uri $endpoint -Body $telemetry -ContentType "application/json"
```

---

## Summary

**IISWebServerMonitor.ps1** provides comprehensive monitoring for Microsoft IIS web server infrastructure, offering critical visibility into application pool health, worker process status, request performance, and error rates. This monitoring is essential for maintaining high-availability web services and preventing user-facing outages.

### Key Takeaways

1. **Application Pool Failures**: Stopped pools = unavailable websites - immediate critical alerts required
2. **Queue Depth Monitoring**: Early warning system for performance degradation before users notice
3. **Proactive Recycling**: Memory-based and periodic recycling prevents crashes and OutOfMemory errors
4. **Error Pattern Analysis**: Event log monitoring identifies application issues requiring code fixes
5. **Capacity Planning**: Request rate and worker process metrics guide scaling decisions

### Recommended Implementation

- **Regular Monitoring**: Every 4 hours for standard environments
- **High-Frequency Monitoring**: Every 15 minutes for mission-critical sites
- **Critical Alerts**: Immediate notification for stopped application pools
- **Warning Alerts**: Email for high queues, error rates, or missing workers
- **Dashboard Integration**: Real-time health status and performance metrics

---

**Script Location:** [`plaintext_scripts/IISWebServerMonitor.ps1`](https://github.com/Xore/waf/blob/main/plaintext_scripts/IISWebServerMonitor.ps1)

**Related Documentation:**
- [Monitoring Overview](../Monitoring-Overview.md)
- [NinjaRMM Custom Fields Guide](../NinjaRMM-CustomFields.md)
- [Alert Configuration Guide](../Alert-Configuration.md)

**Last Updated:** February 12, 2026  
**Framework Version:** 4.0