# Hyper-V Performance Counter Reference

**Created:** February 10, 2026  
**Status:** Phase 1 Research  
**Purpose:** Complete catalog of Hyper-V performance counters for monitoring scripts

---

## Document Purpose

This document catalogs all Hyper-V performance counters discovered during research, including:
- Counter paths and instance names
- Counter descriptions and meanings
- Threshold recommendations
- Usage patterns in PowerShell
- Mapping to VMs and resources

---

## Counter Categories

### 1. Processor Performance

#### Host CPU Utilization

**Counter:** `\Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time`  
**Description:** Total physical processor utilization including host OS and all VMs  
**Unit:** Percentage (0-100)  
**Thresholds:**
- <60% = Healthy
- 60-89% = Monitor/Caution
- 90-100% = Critical

**Usage:**
```powershell
(Get-Counter '\Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time').CounterSamples.CookedValue
```

**Notes:** This is the primary counter for overall Hyper-V host CPU usage. More accurate than `\Processor(_Total)\% Processor Time` which only shows host OS usage.

---

#### Per-VM CPU Utilization

**Counter:** `\Hyper-V Hypervisor Virtual Processor(*)\% Guest Run Time`  
**Description:** CPU usage per virtual processor  
**Unit:** Percentage (0-100)  
**Instance Format:** `<VM Name>:Hv VP <#>`  
**Thresholds:**
- <75% = Optimal
- 75-85% = Warning
- >85% = Critical

**Usage:**
```powershell
# Get all virtual processor counters
$VPCounters = Get-Counter '\Hyper-V Hypervisor Virtual Processor(*)\% Guest Run Time'

# Parse VM name from instance
$VPCounters.CounterSamples | ForEach-Object {
    $VMName = ($_.InstanceName -split ':')[0]
    $VPNumber = ($_.InstanceName -split ' ')[-1]
    [PSCustomObject]@{
        VM = $VMName
        VP = $VPNumber
        CPUPercent = [Math]::Round($_.CookedValue, 2)
    }
}
```

**Notes:** Multiple instances per VM (one per vCPU). Aggregate for total VM CPU usage.

---

#### Host Processor Queue

**Counter:** `\Hyper-V Hypervisor\Logical Processors`  
**Description:** Number of logical processors on host  
**Unit:** Count  

**Counter:** `\System\Processor Queue Length`  
**Description:** Threads waiting for CPU time  
**Unit:** Count  
**Threshold:** >2 per logical processor = CPU bottleneck

---

### 2. Memory Performance

#### Host Memory Pressure

**Counter:** `\Memory\Available MBytes`  
**Description:** Available physical memory on host  
**Unit:** Megabytes  
**Threshold:** <10% of total = Critical

**Counter:** `\Hyper-V Dynamic Memory Balancer\Available Memory`  
**Description:** Memory available for VMs (if Dynamic Memory enabled)  
**Unit:** Megabytes  

---

#### Per-VM Memory Pressure

**Counter:** `\Hyper-V Dynamic Memory Balancer(*)\Average Pressure`  
**Description:** Memory pressure per VM (Dynamic Memory)  
**Unit:** Percentage  
**Instance Format:** `<VM Name>`  
**Thresholds:**
- <80% = Healthy
- 80-99% = Warning
- 100% = Critical

**Usage:**
```powershell
Get-Counter '\Hyper-V Dynamic Memory Balancer(*)\Average Pressure' | 
    Select-Object -ExpandProperty CounterSamples | 
    Where-Object { $_.CookedValue -gt 80 }
```

**Notes:** Only available for VMs with Dynamic Memory enabled.

---

### 3. Network Performance

#### Per-VM Network Throughput

**Counter:** `\Hyper-V Virtual Network Adapter(*)\Bytes Sent/sec`  
**Description:** Network bytes sent per second per VM network adapter  
**Unit:** Bytes/sec  
**Instance Format:** `<VM Name> - <Network Adapter Name>`  
**Threshold:** >250 MBps (262,144,000 bytes/sec) = Consider SR-IOV or additional adapters

**Counter:** `\Hyper-V Virtual Network Adapter(*)\Bytes Received/sec`  
**Description:** Network bytes received per second per VM network adapter  
**Unit:** Bytes/sec  

**Counter:** `\Hyper-V Virtual Network Adapter(*)\Bytes/sec`  
**Description:** Total network bytes per second (sent + received)  
**Unit:** Bytes/sec  

**Usage:**
```powershell
# Get network throughput for all VMs
$NetCounters = Get-Counter @(
    '\Hyper-V Virtual Network Adapter(*)\Bytes Sent/sec',
    '\Hyper-V Virtual Network Adapter(*)\Bytes Received/sec'
)

$NetCounters.CounterSamples | Group-Object { ($_.Path -split '\(')[1] -replace '\).*' } | ForEach-Object {
    $Instance = $_.Name
    $VMName = ($Instance -split ' - ')[0]
    $AdapterName = ($Instance -split ' - ')[1]
    $Sent = ($_.Group | Where-Object { $_.Path -like '*Sent*' }).CookedValue
    $Received = ($_.Group | Where-Object { $_.Path -like '*Received*' }).CookedValue
    
    [PSCustomObject]@{
        VM = $VMName
        Adapter = $AdapterName
        SentMBps = [Math]::Round($Sent / 1MB, 2)
        ReceivedMBps = [Math]::Round($Received / 1MB, 2)
        TotalMBps = [Math]::Round(($Sent + $Received) / 1MB, 2)
    }
}
```

---

#### Virtual Switch Performance

**Counter:** `\Hyper-V Virtual Switch(*)\Bytes/sec`  
**Description:** Total bytes per second through virtual switch  
**Unit:** Bytes/sec  
**Instance Format:** `<Virtual Switch Name>`  

**Counter:** `\Hyper-V Virtual Switch(*)\Packets/sec`  
**Description:** Total packets per second through virtual switch  
**Unit:** Packets/sec  

**Counter:** `\Hyper-V Virtual Switch(*)\Packets Received Discarded`  
**Description:** Packets dropped due to buffer issues  
**Unit:** Count  

**Counter:** `\Hyper-V Virtual Switch(*)\Dropped Packets Outgoing/sec`  
**Description:** Outbound packets dropped per second  
**Unit:** Packets/sec  
**Threshold:** >5% of total packets = Network issues

**Usage:**
```powershell
$SwitchCounters = Get-Counter @(
    '\Hyper-V Virtual Switch(*)\Packets/sec',
    '\Hyper-V Virtual Switch(*)\Dropped Packets Outgoing/sec'
)

# Calculate drop rate
$PacketsPerSec = ($SwitchCounters.CounterSamples | Where-Object { $_.Path -like '*Packets/sec*' -and $_.Path -notlike '*Dropped*' }).CookedValue
$DroppedPerSec = ($SwitchCounters.CounterSamples | Where-Object { $_.Path -like '*Dropped*' }).CookedValue
$DropRate = if ($PacketsPerSec -gt 0) { ($DroppedPerSec / $PacketsPerSec) * 100 } else { 0 }
```

---

#### Physical Network Adapter

**Counter:** `\Network Adapter(*)\Bytes Total/sec`  
**Description:** Physical NIC throughput  
**Unit:** Bytes/sec  
**Threshold:** >90% of link capacity = Add NICs or migrate VMs

---

### 4. Storage Performance

#### Per-VM Disk IOPS

**Counter:** `\Hyper-V Virtual Storage Device(*)\Read Operations/sec`  
**Description:** Read IOPS per virtual disk  
**Unit:** Operations/sec  
**Instance Format:** `<VM Name>_<Disk Location>`  

**Counter:** `\Hyper-V Virtual Storage Device(*)\Write Operations/sec`  
**Description:** Write IOPS per virtual disk  
**Unit:** Operations/sec  

**Usage:**
```powershell
$DiskIOPS = Get-Counter @(
    '\Hyper-V Virtual Storage Device(*)\Read Operations/sec',
    '\Hyper-V Virtual Storage Device(*)\Write Operations/sec'
)

$DiskIOPS.CounterSamples | Group-Object InstanceName | ForEach-Object {
    $VMDisk = $_.Name
    $VMName = ($VMDisk -split '_')[0]
    $ReadIOPS = ($_.Group | Where-Object { $_.Path -like '*Read*' }).CookedValue
    $WriteIOPS = ($_.Group | Where-Object { $_.Path -like '*Write*' }).CookedValue
    
    [PSCustomObject]@{
        VM = $VMName
        Disk = $VMDisk
        ReadIOPS = [Math]::Round($ReadIOPS, 0)
        WriteIOPS = [Math]::Round($WriteIOPS, 0)
        TotalIOPS = [Math]::Round($ReadIOPS + $WriteIOPS, 0)
    }
}
```

---

#### Per-VM Disk Latency

**Counter:** `\Hyper-V Virtual Storage Device(*)\Read Latency`  
**Description:** Average read latency in milliseconds  
**Unit:** Milliseconds  
**Instance Format:** `<VM Name>_<Disk Location>`  
**Thresholds:**
- <10ms = Good
- 10-50ms = Acceptable
- >50ms = Poor (investigate storage)

**Counter:** `\Hyper-V Virtual Storage Device(*)\Write Latency`  
**Description:** Average write latency in milliseconds  
**Unit:** Milliseconds  
**Thresholds:** Same as read latency

**Usage:**
```powershell
$DiskLatency = Get-Counter @(
    '\Hyper-V Virtual Storage Device(*)\Read Latency',
    '\Hyper-V Virtual Storage Device(*)\Write Latency'
)

$DiskLatency.CounterSamples | Group-Object InstanceName | ForEach-Object {
    $VMDisk = $_.Name
    $VMName = ($VMDisk -split '_')[0]
    $ReadLatency = ($_.Group | Where-Object { $_.Path -like '*Read*' }).CookedValue
    $WriteLatency = ($_.Group | Where-Object { $_.Path -like '*Write*' }).CookedValue
    
    [PSCustomObject]@{
        VM = $VMName
        Disk = $VMDisk
        ReadLatencyMS = [Math]::Round($ReadLatency, 2)
        WriteLatencyMS = [Math]::Round($WriteLatency, 2)
        AvgLatencyMS = [Math]::Round(($ReadLatency + $WriteLatency) / 2, 2)
    }
}
```

---

#### Per-VM Disk Throughput

**Counter:** `\Hyper-V Virtual Storage Device(*)\Read Bytes/sec`  
**Description:** Read throughput per virtual disk  
**Unit:** Bytes/sec  

**Counter:** `\Hyper-V Virtual Storage Device(*)\Write Bytes/sec`  
**Description:** Write throughput per virtual disk  
**Unit:** Bytes/sec  

---

#### Disk Queue Depth

**Counter:** `\Hyper-V Virtual Storage Device(*)\Queue Length`  
**Description:** Current queue depth for virtual disk  
**Unit:** Count  
**Thresholds:**
- <8 = Good
- 8-16 = Monitor
- >32 = Storage bottleneck

---

#### Host Storage Latency

**Counter:** `\LogicalDisk(*)\Avg. Disk sec/Read`  
**Description:** Physical disk read latency  
**Unit:** Seconds (convert to milliseconds: * 1000)  
**Threshold:** >0.015 (15ms) = Storage issues

**Counter:** `\LogicalDisk(*)\Avg. Disk sec/Write`  
**Description:** Physical disk write latency  
**Unit:** Seconds  

**Counter:** `\LogicalDisk(*)\Avg. Disk sec/Transfer`  
**Description:** Average disk latency (read + write)  
**Unit:** Seconds  
**Thresholds:**
- <0.008 (8ms) = Excellent (server virtualization)
- <0.015 (15ms) = Good (general threshold)
- <0.025 (25ms) = Acceptable (client virtualization)
- >0.025 (25ms) = Poor

---

#### Host Storage Idle Time

**Counter:** `\LogicalDisk(*)\% Idle Time`  
**Description:** Percentage of time disk was idle  
**Unit:** Percentage  
**Threshold:** <50% sustained >5 minutes = Storage overload

---

### 5. CSV (Cluster Shared Volume) Performance

#### CSV IOPS

**Counter:** `\Cluster CSV File System(*)\Reads/sec`  
**Description:** Read operations per second on CSV  
**Unit:** Operations/sec  
**Instance Format:** `<CSV Volume Name>`  

**Counter:** `\Cluster CSV File System(*)\Writes/sec`  
**Description:** Write operations per second on CSV  
**Unit:** Operations/sec  

**Usage:**
```powershell
$CSVCounters = Get-Counter @(
    '\Cluster CSV File System(*)\Reads/sec',
    '\Cluster CSV File System(*)\Writes/sec'
)

$CSVCounters.CounterSamples | Group-Object InstanceName | ForEach-Object {
    $CSVName = $_.Name
    $ReadIOPS = ($_.Group | Where-Object { $_.Path -like '*Reads/sec*' }).CookedValue
    $WriteIOPS = ($_.Group | Where-Object { $_.Path -like '*Writes/sec*' }).CookedValue
    
    [PSCustomObject]@{
        CSV = $CSVName
        ReadIOPS = [Math]::Round($ReadIOPS, 0)
        WriteIOPS = [Math]::Round($WriteIOPS, 0)
        TotalIOPS = [Math]::Round($ReadIOPS + $WriteIOPS, 0)
    }
}
```

---

#### CSV Latency

**Counter:** `\Cluster CSV File System(*)\Read Latency`  
**Description:** CSV read latency (includes CSVFS + SMB/NTFS time)  
**Unit:** Milliseconds  
**Threshold:** Should match physical disk latency

**Counter:** `\Cluster CSV File System(*)\Write Latency`  
**Description:** CSV write latency  
**Unit:** Milliseconds  

**Counter:** `\Cluster CSV File System(*)\Redirected Read Latency`  
**Description:** Latency for redirected reads (non-coordinator node)  
**Unit:** Milliseconds  

**Counter:** `\Cluster CSV File System(*)\Redirected Write Latency`  
**Description:** Latency for redirected writes (non-coordinator node)  
**Unit:** Milliseconds  

**Notes:** 
- Redirected latency = time from CSVFS to SMB/NTFS completion
- Should be approximately equal to physical disk latency
- Significant difference indicates network or coordination issues

---

#### CSV Throughput

**Counter:** `\Cluster CSV File System(*)\Read Bytes/sec`  
**Description:** CSV read throughput  
**Unit:** Bytes/sec  

**Counter:** `\Cluster CSV File System(*)\Write Bytes/sec`  
**Description:** CSV write throughput  
**Unit:** Bytes/sec  

---

#### CSV Redirected I/O

**Counter:** `\Cluster CSV File System(*)\Redirected Reads/sec`  
**Description:** Read operations sent over SMB to coordinator node  
**Unit:** Operations/sec  
**Note:** Should be 0 or minimal on coordinator node

**Counter:** `\Cluster CSV File System(*)\Redirected Writes/sec`  
**Description:** Write operations sent over SMB to coordinator node  
**Unit:** Operations/sec  
**Note:** Unexpected redirected I/O indicates coordination issues

---

#### CSV Queue Depth

**Counter:** `\Cluster CSV File System(*)\Read Queue Length`  
**Description:** Reads queued in CSV file system  
**Unit:** Count  

**Counter:** `\Cluster CSV File System(*)\Write Queue Length`  
**Description:** Writes queued in CSV file system  
**Unit:** Count  

**Counter:** `\Cluster CSV File System(*)\Redirected Read Queue Length`  
**Description:** Redirected reads queued  
**Unit:** Count  

**Counter:** `\Cluster CSV File System(*)\Redirected Write Queue Length`  
**Description:** Redirected writes queued  
**Unit:** Count  

---

### 6. Live Migration Performance

#### Migration Bandwidth

**Counter:** `\Hyper-V VM Live Migration(*)\Data Rate`  
**Description:** Live migration network bandwidth usage  
**Unit:** Bytes/sec  
**Instance Format:** `<VM Name>`  
**Note:** Only available during active migration

**Usage:**
```powershell
# Check for active migrations
$MigrationCounters = Get-Counter '\Hyper-V VM Live Migration(*)\Data Rate' -ErrorAction SilentlyContinue

if ($MigrationCounters) {
    $MigrationCounters.CounterSamples | ForEach-Object {
        [PSCustomObject]@{
            VM = $_.InstanceName
            DataRateMBps = [Math]::Round($_.CookedValue / 1MB, 2)
        }
    }
}
```

---

### 7. Hyper-V Service Health

#### VM Health Summary

**Counter:** `\Hyper-V Virtual Machine Health Summary\Health Ok`  
**Description:** Number of VMs with healthy heartbeat  
**Unit:** Count  

**Counter:** `\Hyper-V Virtual Machine Health Summary\Health Critical`  
**Description:** Number of VMs with critical health (lost heartbeat)  
**Unit:** Count  

**Usage:**
```powershell
$HealthCounters = Get-Counter @(
    '\Hyper-V Virtual Machine Health Summary\Health Ok',
    '\Hyper-V Virtual Machine Health Summary\Health Critical'
)

[PSCustomObject]@{
    HealthyVMs = ($HealthCounters.CounterSamples | Where-Object { $_.Path -like '*Ok*' }).CookedValue
    CriticalVMs = ($HealthCounters.CounterSamples | Where-Object { $_.Path -like '*Critical*' }).CookedValue
}
```

---

## Counter Discovery Methods

### List All Hyper-V Counter Sets

```powershell
# Get all Hyper-V related counter sets
Get-Counter -ListSet *Hyper-V* | Select-Object CounterSetName, Description

# Get all CSV counter sets
Get-Counter -ListSet *CSV* | Select-Object CounterSetName, Description
```

### Get All Counters in a Set

```powershell
# Get all counters for a specific set
(Get-Counter -ListSet 'Hyper-V Virtual Storage Device').Counter

# Get counter paths with descriptions
Get-Counter -ListSet 'Hyper-V Virtual Storage Device' | 
    Select-Object -ExpandProperty PathsWithInstances
```

### Get Current Counter Instances

```powershell
# Get all current instances (e.g., VM names)
(Get-Counter '\Hyper-V Hypervisor Virtual Processor(*)\% Guest Run Time').CounterSamples.InstanceName | 
    Sort-Object -Unique
```

---

## Performance Collection Best Practices

### Efficient Counter Collection

**Do:**
- Collect multiple counters in single Get-Counter call
- Use wildcards (*) for multiple instances
- Cache counter results when querying multiple times
- Use -MaxSamples 1 for current values (not averages)

**Don't:**
- Call Get-Counter separately for each counter (slow)
- Collect counters more frequently than needed
- Ignore errors (counters may not exist on all systems)

### Example: Optimal Collection

```powershell
# GOOD: Single call for multiple counters
$AllCounters = Get-Counter @(
    '\Hyper-V Virtual Storage Device(*)\Read Operations/sec',
    '\Hyper-V Virtual Storage Device(*)\Write Operations/sec',
    '\Hyper-V Virtual Storage Device(*)\Read Latency',
    '\Hyper-V Virtual Storage Device(*)\Write Latency',
    '\Hyper-V Virtual Network Adapter(*)\Bytes Sent/sec',
    '\Hyper-V Virtual Network Adapter(*)\Bytes Received/sec'
) -ErrorAction SilentlyContinue -MaxSamples 1

# Process all results
$AllCounters.CounterSamples | Group-Object InstanceName | ForEach-Object {
    # Parse and process
}
```

### Error Handling

```powershell
# Handle missing counters gracefully
try {
    $Counters = Get-Counter '\Hyper-V Virtual Storage Device(*)\Read Operations/sec' -ErrorAction Stop
} catch {
    Write-Warning "Virtual Storage Device counters not available: $($_.Exception.Message)"
    # Fallback or skip
}
```

---

## VM Name Mapping

### Challenge: Counter Instance Names vs. VM Display Names

Performance counter instance names may not exactly match VM names in Get-VM output.

**Solutions:**

1. **Parse from counter instance:**
```powershell
# Extract VM name from counter instance
$InstanceName = "SQL-Server-2022:Hv VP 0"
$VMName = ($InstanceName -split ':')[0]
```

2. **Build lookup table:**
```powershell
# Create VM name mapping
$VMMap = @{}
Get-VM | ForEach-Object {
    $VMMap[$_.Name] = $_.VMId
}

# Match counter instance to VM
$VMName = $InstanceName -replace ':.*$'  # Remove VP suffix
if ($VMMap.ContainsKey($VMName)) {
    # Valid VM
}
```

---

## Counter Availability Matrix

| Counter Category | Windows Server 2012 R2 | 2016 | 2019 | 2022 |
|------------------|------------------------|------|------|------|
| Hyper-V Hypervisor | ✓ | ✓ | ✓ | ✓ |
| Virtual Storage Device | ✓ | ✓ | ✓ | ✓ |
| Virtual Network Adapter | ✓ | ✓ | ✓ | ✓ |
| Virtual Switch | ✓ | ✓ | ✓ | ✓ |
| CSV File System | ✓ | ✓ | ✓ | ✓ |
| VM Live Migration | ✓ | ✓ | ✓ | ✓ |
| Dynamic Memory Balancer | ✓ | ✓ | ✓ | ✓ |
| VM Health Summary | ✓ | ✓ | ✓ | ✓ |

---

## References

### Microsoft Documentation
- [Performance Tuning for Hyper-V](https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/hyper-v-server/)
- [Detecting Bottlenecks in Virtualized Environment](https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/hyper-v-server/detecting-virtualized-environment-bottlenecks)
- [CSV Performance Counters](https://techcommunity.microsoft.com/blog/failoverclustering/cluster-shared-volume-performance-counters/371980)

### Community Resources
- [NAKIVO Hyper-V Monitoring Tips](https://www.nakivo.com/blog/tips-and-tools-for-microsoft-hyper-v-monitoring/)
- [Hyper-V Storage Performance Counters](https://learn.microsoft.com/en-gb/archive/blogs/neales/hyper-v-performance-storage)
- [Monitoring Hyper-V Performance](https://learn.microsoft.com/en-us/archive/blogs/tvoellm/monitoring-hyper-v-performance)
- [Performance Counters with PowerShell](https://virtualizationdojo.com/hyper-v/performance-counters-hyper-v-and-powershell-part-1/)

---

**Document Version:** 1.0  
**Last Updated:** February 10, 2026  
**Next Update:** After Script 3 implementation testing  
**Maintained By:** Windows Automation Framework Team
