# HyperVMonitor.ps1 - Deep Dive

## Overview

**Category:** Hyper-V / Virtualization  
**Version:** 1.1  
**Complexity:** Advanced  
**Execution Context:** SYSTEM with Administrator privileges  
**Typical Duration:** ~25 seconds  
**Recommended Frequency:** Every 15 minutes

### Purpose

Comprehensive Hyper-V infrastructure monitoring covering VM status, health, resource utilization, integration services, and failover cluster state with HTML-formatted dashboard reporting.

### Key Features

- **Zero-touch module installation** - Auto-installs Hyper-V PowerShell if missing
- **Cluster-aware** - Detects and monitors failover cluster status
- **HTML reporting** - Rich visual dashboard with color-coded health indicators
- **Integration services tracking** - Monitors heartbeat and guest communication
- **Resource monitoring** - CPU, memory, and performance metrics
- **Graceful degradation** - Handles non-Hyper-V systems cleanly

---

## Architecture

### Monitoring Layers

```
┌─────────────────────────────────────────┐
│  Hyper-V Installation Detection Layer  │
│  (Service check, Module availability)  │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│     Module Auto-Installation Layer     │
│  (Install-WindowsFeature / Enable-     │
│   WindowsOptionalFeature fallback)     │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│      Cluster Detection Layer           │
│  (FailoverClusters module import)      │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ↓             ↓
  ┌──────────┐  ┌──────────┐
  │ Clustered│  │Standalone│
  │   Mode   │  │   Mode   │
  └────┬─────┘  └────┬─────┘
       │             │
       └──────┬──────┘
              ↓
┌─────────────────────────────────────────┐
│        VM Collection & Analysis        │
│  • Get-VM enumeration                  │
│  • Per-VM detailed status              │
│  • Integration services check          │
│  • Resource utilization sampling       │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│       Health Classification Engine     │
│  Critical → Warning → Healthy          │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│       HTML Report Generation           │
│  Color-coded table with health matrix  │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│      NinjaRMM Field Population         │
│  15 custom fields + WYSIWYG report     │
└─────────────────────────────────────────┘
```

### Execution Flow

1. **Detection Phase** (2-3s)
   - Check vmms service
   - Validate module availability
   - Install module if missing

2. **Collection Phase** (10-15s)
   - Enumerate VMs
   - Query VM details
   - Sample resource utilization
   - Check cluster status

3. **Analysis Phase** (3-5s)
   - Calculate health scores
   - Classify VM states
   - Aggregate statistics

4. **Reporting Phase** (3-5s)
   - Build HTML report
   - Update NinjaRMM fields
   - Log summary

---

## Parameters

### No Parameters Required

This script operates autonomously without parameters. All configuration is internal via script variables.

### Internal Configuration Variables

```powershell
# Thresholds
$WarningCPUPercent = 85      # Host CPU warning level
$CriticalCPUPercent = 95     # Host CPU critical level
$WarningMemoryPercent = 85   # Host memory warning
$CriticalMemoryPercent = 95  # Host memory critical

# Execution
$DefaultTimeout = 120        # Script timeout in seconds
$MaxRetries = 3              # Retry attempts for transient failures

# Logging
$LogLevel = "INFO"           # DEBUG, INFO, WARN, ERROR
```

**Customization:** Modify these variables in the script header to adjust thresholds.

---

## Features

### 1. Hyper-V Detection & Auto-Configuration

**Detection Logic:**
```powershell
function Test-HyperVInstalled {
    $HyperVService = Get-Service -Name "vmms" -ErrorAction SilentlyContinue
    return ($null -ne $HyperVService)
}
```

**Auto-Installation:**
```powershell
function Install-HyperVModule {
    # Try Server method first (Install-WindowsFeature)
    if (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue) {
        Install-WindowsFeature -Name Hyper-V-PowerShell
    }
    # Fallback to client method (Enable-WindowsOptionalFeature)
    elseif (Get-Command Enable-WindowsOptionalFeature) {
        Enable-WindowsOptionalFeature -Online `
            -FeatureName Microsoft-Hyper-V-Management-PowerShell `
            -All -NoRestart
    }
    
    Import-Module Hyper-V
}
```

**Benefits:**
- Works on both Server and Client SKUs
- No manual intervention required
- One-time setup per system
- Graceful failure handling

### 2. Failover Cluster Integration

**Cluster Detection:**
```powershell
function Test-FailoverClusterMember {
    Import-Module FailoverClusters -ErrorAction SilentlyContinue
    $Cluster = Get-Cluster -ErrorAction SilentlyContinue
    return ($null -ne $Cluster)
}
```

**Cluster Information Collected:**

| Data Point | Purpose | Example |
|------------|---------|----------|
| Cluster Name | Identification | "PROD-CLUSTER01" |
| Node Count | Capacity tracking | 4 |
| Cluster Status | Health indicator | "Healthy" / "Degraded" |
| Local Node Status | This node's state | "Up" / "Down" |
| Quorum Status | High availability check | "NodeAndDiskMajority" |

**Cluster Health States:**
- **Healthy**: All nodes online
- **Degraded**: Some nodes offline but quorum maintained
- **Offline**: Cluster down or quorum lost

### 3. Virtual Machine Monitoring

**VM States Tracked:**

```
Running  → VM is powered on and operational
Off      → VM is powered off
Saved    → VM is in saved state (hibernated)
Paused   → VM execution suspended
Starting → VM is booting
Stopping → VM is shutting down
```

**Per-VM Data Collection:**

```powershell
function Get-VMDetailedStatus {
    param($VM)
    
    return @{
        Name = $VM.Name
        State = $VM.State.ToString()
        Status = $VM.Status.ToString()
        Uptime = Format-Uptime -Uptime $VM.Uptime
        CPUUsage = $VM.CPUUsage
        MemoryAssignedMB = [Math]::Round($VMMemory.Startup / 1MB)
        MemoryDemandMB = [Math]::Round($VM.MemoryDemand / 1MB)
        Generation = $VM.Generation  # Gen1 or Gen2
        IntegrationServicesState = "Enabled" / "Disabled"
        Heartbeat = $HeartbeatService.PrimaryStatusDescription
        HealthColor = Get-VMHealthColor -State $State -Heartbeat $Heartbeat
        ReplicationHealth = $Replication.ReplicationHealth.ToString()
        CheckpointCount = @($Checkpoints).Count
    }
}
```

### 4. Integration Services Health

**Heartbeat Status Values:**

| Status | Meaning | Health Color |
|--------|---------|-------------|
| `OkApplicationsHealthy` | VM responsive, apps healthy | 🟢 Green |
| `OkApplicationsUnknown` | VM responsive, apps unknown | 🟢 Light Green |
| `LostCommunication` | Heartbeat timeout | 🔴 Red |
| `NoContact` | Never established contact | 🟠 Orange |
| `Paused` | VM execution paused | 🟡 Yellow |
| Unknown | Integration services disabled | ⚪ Gray |

**Integration Services Checked:**
- Heartbeat (health monitoring)
- Time synchronization
- Data exchange
- VSS (backup integration)
- Guest service interface
- Shutdown service

**Why Heartbeat Matters:**
- Detects guest OS hangs
- Validates network connectivity
- Confirms integration components loaded
- Early warning for VM issues

### 5. Resource Utilization Monitoring

**Host-Level Metrics:**

```powershell
function Get-HostResourceUtilization {
    # CPU utilization
    $CPU = Get-Counter '\Processor(_Total)\% Processor Time'
    $CPUPercent = [Math]::Round($CPU.CounterSamples[0].CookedValue)
    
    # Memory utilization
    $OS = Get-CimInstance Win32_OperatingSystem
    $TotalMemory = $OS.TotalVisibleMemorySize
    $FreeMemory = $OS.FreePhysicalMemory
    $MemoryPercent = [Math]::Round((($TotalMemory - $FreeMemory) / $TotalMemory) * 100)
    
    return @{ CPUPercent = $CPUPercent; MemoryPercent = $MemoryPercent }
}
```

**VM-Level Metrics:**
- CPU usage percentage (per VM)
- Memory assigned (startup allocation)
- Memory demand (current working set)
- Dynamic memory status

**Performance Impact:**
- Host CPU > 85% = Warning
- Host CPU > 95% = Critical
- Host Memory > 85% = Warning
- Host Memory > 95% = Critical

### 6. HTML Dashboard Reporting

**Report Structure:**

```html
<style>
table { border-collapse: collapse; width: 100%; }
th { background-color: #0078D4; color: white; padding: 8px; }
td { padding: 6px; border-bottom: 1px solid #ddd; }
tr:hover { background-color: #f5f5f5; }
</style>

<table>
  <tr>
    <th>VM Name</th>
    <th>State</th>
    <th>Health</th>
    <th>Uptime</th>
    <th>CPU</th>
    <th>Memory</th>
    <th>Generation</th>
    <th>Integration Services</th>
  </tr>
  <!-- VM rows with color-coded health indicators -->
</table>

<div class='summary'>
  Total VMs: 12 | Running: 10 | Stopped: 2
  Healthy: 9 | Warning: 1 | Critical: 0
  Cluster: PROD-CLUSTER01 (Healthy)
</div>
```

**Color Coding:**
- 🟢 **Green**: VM running and healthy
- 🟢 **Light Green**: VM running, apps unknown
- 🟡 **Yellow**: VM paused or degraded
- 🟠 **Orange**: VM no contact
- 🔴 **Red**: VM heartbeat lost
- ⚪ **Gray**: VM not running or unknown

---

## NinjaRMM Integration

### Custom Fields Updated

| Field Name | Type | Purpose | Example Value |
|------------|------|---------|---------------|
| `hypervInstalled` | Checkbox | Role presence | ✓ |
| `hypervVersion` | Text | Version info | "Hyper-V v10.0.20348" |
| `hypervVMCount` | Integer | Total VMs | 12 |
| `hypervVMsRunning` | Integer | Running count | 10 |
| `hypervVMsStopped` | Integer | Stopped count | 2 |
| `hypervVMsOther` | Integer | Saved/Paused count | 0 |
| `hypervClustered` | Checkbox | Cluster member | ✓ |
| `hypervClusterName` | Text | Cluster name | "PROD-CLUSTER01" |
| `hypervClusterNodeCount` | Integer | Total nodes | 4 |
| `hypervClusterStatus` | Text | Cluster health | "Healthy" |
| `hypervHostCPUPercent` | Integer | Host CPU usage | 42 |
| `hypervHostMemoryPercent` | Integer | Host memory usage | 68 |
| `hypervVMReport` | WYSIWYG | HTML dashboard | (HTML table) |
| `hypervHealthStatus` | Text | Overall status | "Healthy" |
| `hypervLastScanTime` | DateTime | Last scan | "2026-02-11T20:15:00" |

### Field Update Mechanism

**Primary Method (Cmdlet):**
```powershell
Ninja-Property-Set $FieldName $ValueString
```

**Fallback Method (CLI):**
```powershell
C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe set $FieldName $ValueString
```

**Graceful Degradation:**
- Tries cmdlet first (fastest)
- Falls back to CLI if cmdlet unavailable
- Logs fallback usage count
- Never fails silently

### Dashboard Queries

**Find Critical Hyper-V Hosts:**
```javascript
hypervHealthStatus = "Critical"
hypervInstalled = true
```

**Find Overloaded Hosts:**
```javascript
hypervHostCPUPercent > 85 OR hypervHostMemoryPercent > 85
```

**Find Cluster Issues:**
```javascript
hypervClustered = true AND hypervClusterStatus != "Healthy"
```

**Find Hosts with Down VMs:**
```javascript
hypervVMsOther > 0  // Saved or Paused VMs
```

**Inventory Running VMs:**
```sql
SELECT device_name, hypervVMCount, hypervVMsRunning, hypervVMsStopped
FROM devices
WHERE hypervInstalled = true
ORDER BY hypervVMsRunning DESC
```

---

## Use Cases

### 1. Proactive VM Health Monitoring

**Scenario:** Detect VM issues before users report problems.

**Detection:**
- Heartbeat status changes to `LostCommunication`
- Integration services degraded
- VM stuck in transitional state

**Automation:**
```javascript
// Alert when VM unhealthy for 15 minutes
IF hypervHealthStatus = "Critical" 
   AND condition_duration >= 15_minutes
THEN
   Send alert to on-call team
   Create incident ticket
   Run diagnostic script
```

### 2. Resource Capacity Planning

**Scenario:** Track resource utilization trends to plan hardware upgrades.

**Metrics to Track:**
- Host CPU/memory trends over 30 days
- Average VMs per host
- Peak utilization times
- Growth rate

**Dashboard Widget:**
```javascript
SELECT 
  AVG(hypervHostCPUPercent) as avg_cpu,
  AVG(hypervHostMemoryPercent) as avg_memory,
  AVG(hypervVMsRunning) as avg_vms
FROM historical_data
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY device_name
```

### 3. Cluster Failover Detection

**Scenario:** Identify when VMs migrate between cluster nodes.

**Tracking:**
- VM ownership changes
- Cluster status transitions
- Failover timing

**Alert Logic:**
```javascript
// Detect cluster degradation
IF hypervClusterStatus = "Degraded"
THEN
   Alert: "Cluster node down or quorum at risk"
   Priority: High
```

### 4. Backup Validation

**Scenario:** Ensure VSS integration services functional for backups.

**Checks:**
- Integration services enabled
- VSS service operational
- Backup components installed in guest

**Query:**
```javascript
hypervInstalled = true
AND hypervVMReport NOT CONTAINS "Enabled"
// Alert: Integration services disabled - backups may fail
```

### 5. Compliance Reporting

**Scenario:** Generate reports for virtual infrastructure audits.

**Report Elements:**
- Total VM inventory
- Running vs. stopped ratios
- Cluster configuration
- Resource allocation
- Health status history

---

## Health Classification

### Algorithm

```powershell
if ($vmCritical -gt 0) {
    $healthStatus = "Critical"
} 
elseif ($vmWarning -gt 0 -or 
        $hostCPUPercent -ge $WarningCPUPercent -or 
        $hostMemoryPercent -ge $WarningMemoryPercent) {
    $healthStatus = "Warning"
} 
elseif ($clustered -and $clusterStatus -ne "Healthy") {
    $healthStatus = "Warning"
} 
else {
    $healthStatus = "Healthy"
}
```

### Status Definitions

#### 🔴 Critical

**Triggers:**
- One or more VMs with `LostCommunication` heartbeat
- Host CPU > 95%
- Host Memory > 95%
- All cluster nodes offline

**Response:**
- Immediate alert
- Escalate to senior engineer
- Begin incident response

#### 🟡 Warning

**Triggers:**
- VMs with degraded integration services
- Host CPU 85-95%
- Host Memory 85-95%
- Cluster status "Degraded"
- VMs in saved/paused state

**Response:**
- Monitor closely
- Schedule investigation
- Plan remediation

#### 🟢 Healthy

**Criteria:**
- All running VMs have healthy heartbeat
- Host resources < 85%
- Cluster healthy (if clustered)
- No VMs in abnormal states

**Response:**
- Normal monitoring
- Trend analysis

#### ⚪ Unknown

**Triggers:**
- Hyper-V not installed
- Module installation failed
- Script execution error

**Response:**
- Verify Hyper-V role
- Check script logs
- Manual validation

---

## Error Handling

### Graceful Degradation Scenarios

#### Hyper-V Not Installed
```
Result: Success (exit 0)
Behavior: Sets all fields to default values
Fields: hypervInstalled=false, hypervVersion="Not Installed"
Log: "Hyper-V is not installed on this system"
```

#### Module Installation Failure
```
Result: Failure (exit 2)
Behavior: Logs error, attempts fallback methods
Fields: hypervHealthStatus="Unknown"
Log: "Failed to install or import Hyper-V PowerShell module"
```

#### Cluster Service Not Running
```
Result: Partial success (exit 0)
Behavior: Continues without cluster data
Fields: hypervClustered=false, hypervClusterStatus="N/A"
Log: "Not a cluster member or cluster service not running"
```

#### Individual VM Query Failure
```
Result: Partial success (exit 0)
Behavior: Skips failed VM, continues with others
Fields: VM marked as "Error" state in report
Log: "Error getting VM status for [VMName]"
```

### Retry Logic

**Transient Failures:**
```powershell
$MaxRetries = 3
$RetryDelay = 5  # seconds

for ($i = 1; $i -le $MaxRetries; $i++) {
    try {
        $Result = Get-VM -ErrorAction Stop
        break
    } catch {
        if ($i -eq $MaxRetries) { throw }
        Start-Sleep -Seconds $RetryDelay
    }
}
```

**Applies to:**
- WMI/CIM queries
- Performance counter sampling
- Cluster service queries

---

## Performance Considerations

### Execution Timeline

| Phase | Duration | Bottleneck |
|-------|----------|------------|
| Hyper-V detection | 0.5s | Service query |
| Module import | 2-3s | Module loading |
| Cluster check | 2-3s | Cluster API |
| VM enumeration | 3-5s | WMI queries |
| Per-VM details | 0.5s per VM | Integration services check |
| Resource sampling | 1-2s | Performance counters |
| HTML generation | 1-2s | String concatenation |
| Field updates | 3-5s | NinjaRMM API calls |
| **Total (10 VMs)** | **~20s** | - |
| **Total (50 VMs)** | **~40s** | VM iteration |

### Optimization Tips

**For Large Environments (50+ VMs):**

```powershell
# Batch VM queries
$VMs = Get-VM
$VMMemory = Get-VMMemory -VM $VMs
$VMIntegration = Get-VMIntegrationService -VM $VMs

# Parallel processing (PowerShell 7+)
$VMStatusList = $VMs | ForEach-Object -Parallel {
    Get-VMDetailedStatus -VM $_
} -ThrottleLimit 10
```

**Reduce Frequency for Low-Priority Environments:**
- Critical hosts: Every 15 minutes
- Standard hosts: Every 30 minutes
- Dev/test hosts: Every hour

### Resource Usage

**Memory:**
- Base: ~50 MB
- Per VM: ~1 MB
- Peak (50 VMs): ~100 MB

**CPU:**
- Average: 5-10% (brief spikes)
- Duration: 20-40 seconds
- Impact: Minimal

**Network:**
- Negligible (local WMI queries)
- NinjaRMM API: ~100 KB upload

---

## Troubleshooting

### Common Issues

#### "Hyper-V module not available"

**Symptoms:**
```
Failed to install or import Hyper-V PowerShell module
Exit code: 2
```

**Causes:**
- Hyper-V management tools not installed
- PowerShell Gallery blocked
- Insufficient permissions

**Resolution:**
```powershell
# Server:
Install-WindowsFeature -Name Hyper-V-PowerShell

# Client:
Enable-WindowsOptionalFeature -Online `
    -FeatureName Microsoft-Hyper-V-Management-PowerShell `
    -All -NoRestart

# Verify:
Get-Module -ListAvailable -Name Hyper-V
Import-Module Hyper-V
Get-VM
```

#### "Access Denied" / "Permission denied"

**Symptoms:**
```
Error getting VM status: Access is denied
Exit code: 3
```

**Causes:**
- Not running as SYSTEM
- Not running as Administrator
- Hyper-V Administrators group membership missing

**Resolution:**
```powershell
# Verify execution context
whoami
# Should be: NT AUTHORITY\SYSTEM

# Check group membership
whoami /groups | findstr "Hyper-V"

# Add user to Hyper-V Administrators
Add-LocalGroupMember -Group "Hyper-V Administrators" -Member "DOMAIN\User"
```

#### "Cluster module not found"

**Symptoms:**
```
FailoverClusters module not available
Continuing without cluster data
```

**Causes:**
- Failover Clustering tools not installed
- Not actually a cluster member

**Resolution:**
```powershell
# Install cluster management tools
Install-WindowsFeature -Name RSAT-Clustering-PowerShell

# Verify cluster membership
Get-Cluster

# Check cluster service
Get-Service ClusSvc
```

#### "VMs show as Unknown health"

**Symptoms:**
```
All VMs have gray health indicator
Heartbeat status: Unknown
```

**Causes:**
- Integration services not installed in guest
- Integration services disabled
- Guest firewall blocking

**Resolution:**
```powershell
# Check integration services
Get-VMIntegrationService -VMName "VMName"

# Enable heartbeat service
Enable-VMIntegrationService -VMName "VMName" -Name "Heartbeat"

# Install in guest (Windows):
# Control Panel → Programs → Turn Windows features on/off
# Enable: Hyper-V Guest Services
```

#### "Timeout errors with many VMs"

**Symptoms:**
```
Script execution time exceeds 120 seconds
Incomplete data collection
```

**Causes:**
- Too many VMs for default timeout
- Slow WMI queries
- Network latency (clustered)

**Resolution:**
```powershell
# Increase timeout in script
$DefaultTimeout = 300  # 5 minutes

# Adjust NinjaRMM policy timeout
# Policy → Automation → Script timeout: 300 seconds

# Reduce data collection
# Skip checkpoint count, replication checks for speed
```

### Debug Mode

**Enable Verbose Logging:**
```powershell
# Modify script header
$LogLevel = "DEBUG"
$VerbosePreference = 'Continue'

# Run manually
.\HyperVMonitor.ps1 -Verbose
```

**Log Output Locations:**
```
NinjaRMM Activity Log
Windows Event Log: Application
Script console output (when run manually)
```

---

## Advanced Usage

### Custom Thresholds

**Adjust Warning/Critical Levels:**
```powershell
# Conservative (trigger earlier)
$WarningCPUPercent = 70
$CriticalCPUPercent = 85
$WarningMemoryPercent = 70
$CriticalMemoryPercent = 85

# Aggressive (allow higher utilization)
$WarningCPUPercent = 90
$CriticalCPUPercent = 98
$WarningMemoryPercent = 90
$CriticalMemoryPercent = 98
```

### Add Custom Metrics

**Track VM Network Adapters:**
```powershell
function Get-VMDetailedStatus {
    # ... existing code ...
    
    # Add network adapter count
    $NetworkAdapters = Get-VMNetworkAdapter -VM $VM
    $VMStatus.NetworkAdapterCount = @($NetworkAdapters).Count
    
    # Add virtual switch info
    $VMStatus.VirtualSwitch = ($NetworkAdapters | Select-Object -First 1).SwitchName
    
    return $VMStatus
}
```

**Track VM Disk Usage:**
```powershell
$VHDs = Get-VMHardDiskDrive -VM $VM
$TotalVHDSizeGB = ($VHDs | ForEach-Object {
    $VHD = Get-VHD -Path $_.Path
    [Math]::Round($VHD.FileSize / 1GB, 2)
} | Measure-Object -Sum).Sum

$VMStatus.DiskSizeGB = $TotalVHDSizeGB
```

### Export to File

**CSV Export for Analysis:**
```powershell
$ExportData = foreach ($VMStatus in $VMStatusList) {
    [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Host = $env:COMPUTERNAME
        VMName = $VMStatus.Name
        State = $VMStatus.State
        Heartbeat = $VMStatus.Heartbeat
        CPUUsage = $VMStatus.CPUUsage
        MemoryAssignedMB = $VMStatus.MemoryAssignedMB
        MemoryDemandMB = $VMStatus.MemoryDemandMB
        Uptime = $VMStatus.Uptime
    }
}

$ExportPath = "C:\Logs\HyperV-Monitor-$(Get-Date -Format 'yyyyMMdd').csv"
$ExportData | Export-Csv -Path $ExportPath -Append -NoTypeInformation
```

### Integration with Monitoring Systems

**Prometheus Exporter Format:**
```powershell
# Export metrics in Prometheus format
$PrometheusMetrics = @"
# HELP hyperv_vm_count Total number of VMs
# TYPE hyperv_vm_count gauge
hyperv_vm_count{host="$env:COMPUTERNAME"} $vmCount

# HELP hyperv_vm_running Number of running VMs
# TYPE hyperv_vm_running gauge
hyperv_vm_running{host="$env:COMPUTERNAME"} $vmsRunning

# HELP hyperv_host_cpu_percent Host CPU utilization
# TYPE hyperv_host_cpu_percent gauge
hyperv_host_cpu_percent{host="$env:COMPUTERNAME"} $hostCPUPercent
"@

# Write to file for node_exporter textfile collector
$PrometheusMetrics | Out-File "C:\prometheus\textfile\hyperv.prom"
```

---

## Best Practices

### Scheduling

**Recommended Frequencies:**

| Environment | Frequency | Rationale |
|-------------|-----------|----------|
| Production Critical | Every 5 min | Rapid issue detection |
| Production Standard | Every 15 min | Balance monitoring/overhead |
| Development/Test | Every 30 min | Lower priority |
| Lab/Non-critical | Every hour | Minimal overhead |

**Timing Considerations:**
- Stagger execution across cluster nodes (offset by 5 minutes)
- Avoid peak business hours for large farms
- Align with backup windows (detect backup job issues)

### Alerting Strategy

**Tiered Alerting:**

```javascript
// P1 - Critical (immediate response)
IF hypervHealthStatus = "Critical"
   AND condition_duration >= 5_minutes
THEN
   Page on-call engineer
   Create P1 incident
   SMS notification

// P2 - Warning (next business day)
IF hypervHealthStatus = "Warning"
   AND condition_duration >= 30_minutes
THEN
   Email distribution list
   Create P2 ticket
   Dashboard alert

// P3 - Informational
IF hypervVMsOther > 0  // Saved/Paused VMs
   AND condition_duration >= 24_hours
THEN
   Weekly summary report
```

### Data Retention

**Historical Tracking:**
```sql
-- Keep 90 days of monitoring data
CREATE TABLE hyperv_history (
    timestamp DATETIME,
    device_id INT,
    vm_count INT,
    vms_running INT,
    health_status VARCHAR(20),
    host_cpu_percent INT,
    host_memory_percent INT,
    cluster_status VARCHAR(20)
)

-- Purge old data
DELETE FROM hyperv_history 
WHERE timestamp < NOW() - INTERVAL '90 days'
```

### Capacity Planning

**Growth Tracking:**
```javascript
// Calculate VM growth rate
SELECT 
  device_name,
  MIN(hyperv_vm_count) as initial_vms,
  MAX(hyperv_vm_count) as current_vms,
  MAX(hyperv_vm_count) - MIN(hyperv_vm_count) as growth,
  ((MAX(hyperv_vm_count) - MIN(hyperv_vm_count)) / MIN(hyperv_vm_count)) * 100 as growth_percent
FROM hyperv_history
WHERE timestamp >= NOW() - INTERVAL '6 months'
GROUP BY device_name
```

---

## Security Considerations

### Execution Context

**Why SYSTEM Required:**
- Access to Hyper-V management APIs
- WMI/CIM queries require elevated privileges
- Cluster queries need domain permissions
- NinjaRMM field updates

**Alternative: Hyper-V Administrators Group**
```powershell
# If not SYSTEM, must be in Hyper-V Administrators
Add-LocalGroupMember -Group "Hyper-V Administrators" -Member "DOMAIN\ServiceAccount"
```

### Data Exposure

**Sensitive Information:**
- VM names (may reveal infrastructure)
- Resource allocation (capacity planning intel)
- Cluster topology
- Uptime (patch compliance)

**Mitigation:**
- Restrict NinjaRMM dashboard access
- Role-based access control
- Audit log reviews

### Network Security

**Ports Used:**
- WMI/CIM: TCP 135, dynamic RPC (49152-65535)
- Cluster: TCP 3343 (cluster communication)

**Firewall Rules:**
```powershell
# Allow WMI inbound (clustered scenarios)
New-NetFirewallRule -DisplayName "Hyper-V Monitoring - WMI" `
    -Direction Inbound -Protocol TCP -LocalPort 135 -Action Allow

# Allow cluster communication
New-NetFirewallRule -DisplayName "Hyper-V Monitoring - Cluster" `
    -Direction Inbound -Protocol TCP -LocalPort 3343 -Action Allow
```

---

## Version History

### 1.1 (Current)
- Enhanced error handling
- CLI fallback mechanism
- Improved cluster detection
- HTML report formatting updates
- Performance optimizations

### 1.0
- Initial release
- Core VM monitoring
- Basic cluster support
- HTML report generation
- NinjaRMM integration

---

## Related Scripts

- `HyperVHealthCheck.ps1` - Deep health analysis
- `HyperVPerformanceMonitor.ps1` - Detailed performance metrics
- `HyperVBackupComplianceMonitor.ps1` - Backup validation
- `HyperVClusterAnalytics.ps1` - Cluster-specific monitoring
- `HyperVCapacityPlanner.ps1` - Resource forecasting

---

## Support

**Repository:** [github.com/Xore/waf](https://github.com/Xore/waf)  
**Documentation:** `/docs/scripts/HyperVMonitor.md`  
**Category Guide:** `/docs/categories/hyperv.md`

**Common Questions:**
- See [Troubleshooting](#troubleshooting) section above
- Check [Hyper-V Category Guide](../categories/hyperv.md)
- Review [Framework Concepts](../concepts/framework-concepts.md)
