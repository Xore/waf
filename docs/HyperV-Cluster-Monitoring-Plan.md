# Hyper-V Cluster Monitoring - Comprehensive Deep Dive Plan

**Created:** February 13, 2026  
**Status:** Planning Phase  
**Purpose:** Complete monitoring framework for Hyper-V cluster infrastructure including nodes, VMs, storage, networking, and affiliated services

---

## Executive Summary

This plan outlines a comprehensive monitoring solution for enterprise Hyper-V cluster environments, extending beyond basic VM monitoring to include:

- **Cluster Node Health**: Health Service, membership, resource utilization
- **Storage Subsystems**: CSV, Storage Spaces Direct, physical/virtual disk health
- **Network Infrastructure**: Cluster networks, live migration, converged fabrics
- **Failover Management**: Quorum, resource groups, automatic failover tracking
- **VM High Availability**: Live migration, failover events, placement optimization
- **Performance Baselines**: Counter collection, anomaly detection, capacity planning

### Implementation Phases

| Phase | Focus Area | Timeline | Dependencies |
|-------|-----------|----------|--------------|
| **Phase 1** | Event Log Research & Catalog | Week 1-2 | EVENT_LOG_CATALOG.md (✓ Complete) |
| **Phase 2** | Node & Cluster Health Scripts | Week 3-4 | Phase 1 |
| **Phase 3** | Storage & CSV Monitoring | Week 5-6 | Phase 2 |
| **Phase 4** | Network & Migration Tracking | Week 7-8 | Phase 2 |
| **Phase 5** | Performance Counter Framework | Week 9-10 | Phase 2-4 |
| **Phase 6** | Integration & Dashboards | Week 11-12 | All Previous |
| **Phase 7** | Documentation & Deep Dive | Week 13-14 | All Previous |

---

## Phase 1: Event Log Research & Catalog ✓

**Status:** COMPLETE (February 10, 2026)

### Deliverables
- [x] Event log catalog document
- [x] Event ID quick reference tables
- [x] PowerShell query examples
- [x] Event correlation patterns

### Document Location
- `archive/docs/hyper-v monitoring/research/EVENT_LOG_CATALOG.md`

### Key Findings

**Primary Event Logs Identified:**
1. `Microsoft-Windows-Hyper-V-VMMS-Admin` - VM lifecycle, migrations
2. `Microsoft-Windows-Hyper-V-Worker-Admin` - VM worker processes
3. `Microsoft-Windows-Hyper-V-Compute-Admin` - Compute operations
4. `Microsoft-Windows-Hyper-V-High-Availability-Admin` - HA operations
5. `Microsoft-Windows-FailoverClustering/Operational` - Cluster events
6. `Microsoft-Windows-FailoverClustering-CsvFs/Operational` - CSV events
7. `Microsoft-Windows-Health/Operational` - Health Service
8. `Microsoft-Windows-StorageSpaces-Driver/Operational` - S2D events

**Critical Event IDs Cataloged:**
- Live Migration: 20417, 21002, 21008, 21502
- Failover: 1069, 1146, 1230, 1204
- CSV: 5120, 5121, 5142, 5143
- Node Health: 1000, 1001, 1002, 1135
- VM Lifecycle: 18500, 18502, 18590

---

## Phase 2: Node & Cluster Health Monitoring Scripts

**Status:** PLANNED  
**Timeline:** Week 3-4  
**Priority:** HIGH

### Objectives

Develop PowerShell monitoring scripts for cluster node and service health:

1. **Script 1: ClusterNodeHealthCheck.ps1**
   - Health Service fault monitoring
   - Node membership state tracking
   - Service status verification
   - Resource utilization collection
   - Quorum health assessment

2. **Script 2: ClusterResourceGroupMonitor.ps1**
   - Resource group state tracking
   - Failover event detection
   - Ownership history
   - Resource failure counting
   - Automatic remediation logging

3. **Script 3: ClusterDiagnosticCollector.ps1**
   - Automated `Test-Cluster` execution
   - Validation report parsing
   - Configuration drift detection
   - Cluster log collection
   - Diagnostic result archiving

### Technical Requirements

**Event Queries:**
```powershell
# Health Service Faults
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Health/Operational'
    ID = 4000, 4001, 4002
    StartTime = (Get-Date).AddHours(-24)
}

# Node Membership Events
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-FailoverClustering/Operational'
    ID = 1000, 1001, 1002, 1135, 1177, 1181
    StartTime = (Get-Date).AddHours(-24)
}

# Resource Group Failovers
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-FailoverClustering/Operational'
    ID = 1006, 1069, 1146, 1230, 1204
    StartTime = (Get-Date).AddHours(-24)
}
```

**Performance Counters:**
```powershell
# Node Resource Metrics
$counters = @(
    '\Processor(_Total)\% Processor Time',
    '\Memory\Available MBytes',
    '\Memory\% Committed Bytes In Use',
    '\PhysicalDisk(*)\Avg. Disk Queue Length',
    '\PhysicalDisk(*)\Avg. Disk sec/Read',
    '\PhysicalDisk(*)\Avg. Disk sec/Write',
    '\Network Interface(*)\Bytes Total/sec',
    '\Cluster Network(*)\Bytes Sent/sec',
    '\Cluster Network(*)\Bytes Received/sec'
)
```

**Cluster Cmdlets:**
```powershell
# Node Status
Get-ClusterNode | Select-Object Name, State, NodeWeight, 
    @{N='Uptime';E={(Get-Date) - $_.StatusInformation.LastBootTime}}

# Resource Group Status
Get-ClusterGroup | Select-Object Name, State, OwnerNode, 
    Priority, FailoverThreshold, FailoverPeriod

# Quorum Configuration
Get-ClusterQuorum | Select-Object Cluster, QuorumResource, 
    QuorumType, @{N='VoteCount';E={(Get-ClusterNode | 
    Where-Object NodeWeight -eq 1).Count}}
```

### NinjaRMM Custom Fields

**Node Health Fields:**
```yaml
# Boolean
clusterNodeHealthy: true/false
clusterQuorumHealthy: true/false
clusterHealthServiceFaults: true/false

# Integer
clusterNodeCount: 3
clusterNodeFailures24h: 0
clusterResourceGroupCount: 12
clusterFailoverEvents24h: 0
clusterQuorumVotes: 3

# Text
clusterNodeState: "Up|Down|Paused|Joining"
clusterQuorumType: "NodeMajority|NodeAndDiskMajority|NodeAndFileShareMajority"
clusterHealthStatus: "Healthy|Warning|Critical"

# WYSIWYG
clusterNodeSummary: [HTML table of node states]
clusterResourceGroupSummary: [HTML table of resource groups]
```

### Deliverables

- [ ] `ClusterNodeHealthCheck.ps1` script
- [ ] `ClusterResourceGroupMonitor.ps1` script
- [ ] `ClusterDiagnosticCollector.ps1` script
- [ ] Unit tests for cluster cmdlet availability
- [ ] Documentation for custom field setup
- [ ] NinjaRMM automation policy templates

### Success Criteria

- Scripts execute on non-cluster nodes without errors (graceful detection)
- All cluster node states correctly identified
- Failover events accurately counted and timestamped
- Health Service faults trigger appropriate alert levels
- Quorum loss detection < 30 seconds

---

## Phase 3: Storage & CSV Monitoring

**Status:** PLANNED  
**Timeline:** Week 5-6  
**Priority:** HIGH

### Objectives

Implement comprehensive storage subsystem monitoring:

1. **Script 4: ClusterSharedVolumeMonitor.ps1**
   - CSV space utilization tracking
   - I/O redirection detection
   - Ownership changes
   - CSV state monitoring (online/offline)
   - Performance metrics (IOPS, latency)

2. **Script 5: StorageSpacesDirectMonitor.ps1**
   - Physical disk health
   - Virtual disk status
   - Storage pool health
   - Resiliency settings verification
   - Rebuild progress tracking
   - Data integrity scan monitoring

3. **Script 6: DiskPerformanceCollector.ps1**
   - CSV-level IOPS tracking
   - Latency measurement
   - Queue depth monitoring
   - Throughput analysis
   - Hotspot detection

### Technical Requirements

**Event Queries:**
```powershell
# CSV Events
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-FailoverClustering-CsvFs/Operational'
    ID = 5120, 5121, 5122, 5142, 5143, 5144, 5156, 5360
    StartTime = (Get-Date).AddHours(-24)
}

# Storage Spaces Direct Events
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-StorageSpaces-Driver/Operational'
    Level = 1, 2, 3  # Critical, Error, Warning
    StartTime = (Get-Date).AddDays(-7)
}

# Data Integrity Events
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-DataIntegrityScan/Admin'
    ID = 1008, 1009
    StartTime = (Get-Date).AddDays(-7)
}

# Crash Recovery (Critical)
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-DataIntegrityScan/CrashRecovery'
    StartTime = (Get-Date).AddDays(-30)
}
```

**CSV Monitoring:**
```powershell
# CSV Space Utilization
$CSVs = Get-ClusterSharedVolume
foreach ($csv in $CSVs) {
    $csvInfo = $csv | Select-Object -Property Name -ExpandProperty SharedVolumeInfo
    foreach ($info in $csvInfo) {
        [PSCustomObject]@{
            Name = $csv.Name
            Path = $info.FriendlyVolumeName
            SizeGB = [math]::Round($info.Partition.Size / 1GB, 2)
            FreeSpaceGB = [math]::Round($info.Partition.FreeSpace / 1GB, 2)
            UsedSpaceGB = [math]::Round($info.Partition.UsedSpace / 1GB, 2)
            PercentFree = [math]::Round($info.Partition.PercentFree, 2)
            OwnerNode = $csv.OwnerNode.Name
            State = $csv.State
        }
    }
}

# I/O Redirection Detection
$RedirectedCSVs = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-FailoverClustering-CsvFs/Operational'
    ID = 5142
    StartTime = (Get-Date).AddMinutes(-15)
}
```

**Storage Spaces Direct Monitoring:**
```powershell
# Physical Disk Health
Get-PhysicalDisk | Select-Object FriendlyName, SerialNumber, 
    MediaType, HealthStatus, OperationalStatus, 
    @{N='SizeGB';E={[math]::Round($_.Size / 1GB, 2)}}

# Virtual Disk Health
Get-VirtualDisk | Select-Object FriendlyName, HealthStatus, 
    OperationalStatus, ResiliencySettingName, 
    @{N='SizeGB';E={[math]::Round($_.Size / 1GB, 2)}},
    @{N='FootprintGB';E={[math]::Round($_.FootprintOnPool / 1GB, 2)}}

# Storage Pool Status
Get-StoragePool | Select-Object FriendlyName, HealthStatus, 
    OperationalStatus, IsPrimordial,
    @{N='SizeGB';E={[math]::Round($_.Size / 1GB, 2)}},
    @{N='AllocatedGB';E={[math]::Round($_.AllocatedSize / 1GB, 2)}}

# Storage Job Progress (Rebuild)
Get-StorageJob | Select-Object Name, JobState, PercentComplete, 
    BytesProcessed, BytesTotal, ElapsedTime
```

**Performance Counters:**
```powershell
# CSV Performance
$csvCounters = @(
    '\Cluster CSV File System(*)\Reads/sec',
    '\Cluster CSV File System(*)\Writes/sec',
    '\Cluster CSV File System(*)\Read Bytes/sec',
    '\Cluster CSV File System(*)\Write Bytes/sec',
    '\Cluster CSV File System(*)\Avg. sec/Read',
    '\Cluster CSV File System(*)\Avg. sec/Write',
    '\Cluster Disk Partition(*)\% Free Space'
)

# Physical Disk Performance
$diskCounters = @(
    '\PhysicalDisk(*)\Disk Reads/sec',
    '\PhysicalDisk(*)\Disk Writes/sec',
    '\PhysicalDisk(*)\Avg. Disk Queue Length',
    '\PhysicalDisk(*)\Avg. Disk sec/Read',
    '\PhysicalDisk(*)\Avg. Disk sec/Write',
    '\PhysicalDisk(*)\Current Disk Queue Length'
)
```

### NinjaRMM Custom Fields

**CSV Fields:**
```yaml
# Boolean
csvHealthy: true/false
csvIORedirected: true/false
csvLowSpaceAlert: true/false

# Integer
csvCount: 4
csvTotalSizeGB: 8000
csvFreeSpaceGB: 3200
csvPercentFree: 40
csvRedirectionCount24h: 0

# Text
csvHealthStatus: "Healthy|Warning|Critical"

# WYSIWYG
csvSummary: [HTML table of CSV volumes]
csvIORedirectionEvents: [HTML list of redirection events]
```

**Storage Spaces Direct Fields:**
```yaml
# Boolean
s2dHealthy: true/false
s2dPhysicalDiskFailed: true/false
s2dVirtualDiskDegraded: true/false
s2dRebuildInProgress: true/false

# Integer
s2dPhysicalDiskCount: 24
s2dUnhealthyDiskCount: 0
s2dVirtualDiskCount: 6
s2dStoragePoolCapacityGB: 20000
s2dStoragePoolUsedGB: 12000

# Text
s2dHealthStatus: "Healthy|Warning|Critical"
s2dRebuildProgress: "75%"

# WYSIWYG
s2dPhysicalDiskSummary: [HTML table of disks]
s2dVirtualDiskSummary: [HTML table of virtual disks]
s2dStorageJobsSummary: [HTML table of active jobs]
```

### Deliverables

- [ ] `ClusterSharedVolumeMonitor.ps1` script
- [ ] `StorageSpacesDirectMonitor.ps1` script
- [ ] `DiskPerformanceCollector.ps1` script
- [ ] CSV space threshold alerting logic
- [ ] I/O redirection anomaly detection
- [ ] Storage rebuild notification system
- [ ] Documentation for storage monitoring

### Success Criteria

- CSV space monitoring accurate to within 1%
- I/O redirection detected within 1 minute
- Physical disk failures identified immediately
- Storage rebuild progress tracked real-time
- Performance counters collected without impacting storage I/O

---

## Phase 4: Network & Migration Monitoring

**Status:** PLANNED  
**Timeline:** Week 7-8  
**Priority:** MEDIUM-HIGH

### Objectives

Implement network infrastructure and live migration monitoring:

1. **Script 7: ClusterNetworkHealthCheck.ps1**
   - Network interface status
   - Cluster network role verification
   - Reconnection event tracking
   - Network partition detection
   - Bandwidth utilization

2. **Script 8: LiveMigrationMonitor.ps1**
   - Migration event tracking (start/complete/fail)
   - Migration duration calculation
   - Network used for migration
   - Simultaneous migration count
   - Storage migration tracking

3. **Script 9: NetworkPerformanceCollector.ps1**
   - RDMA status (if applicable)
   - SMB Direct performance
   - Network adapter teaming health
   - Packet loss detection
   - Bandwidth saturation alerts

### Technical Requirements

**Event Queries:**
```powershell
# Live Migration Events
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    ID = 20417, 21002, 21008, 21502, 20414, 20415
    StartTime = (Get-Date).AddHours(-24)
}

# Cluster Network Events
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-FailoverClustering/Operational'
    ID = 1129, 1130, 1196, 1564, 4621
    StartTime = (Get-Date).AddHours(-24)
}

# SMB Events (CSV/Live Migration traffic)
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-SmbClient/Operational'
    Level = 1, 2, 3
    StartTime = (Get-Date).AddHours(-24)
}
```

**Live Migration Tracking:**
```powershell
# Calculate migration duration
$StartEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    ID = 20417
    StartTime = (Get-Date).AddDays(-1)
}

$CompleteEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    ID = 21002
    StartTime = (Get-Date).AddDays(-1)
}

foreach ($Start in $StartEvents) {
    $VMName = $Start.Properties[0].Value
    $DestHost = $Start.Properties[1].Value
    
    $Complete = $CompleteEvents | 
        Where-Object { $_.Properties[0].Value -eq $VMName -and 
                       $_.TimeCreated -gt $Start.TimeCreated } | 
        Select-Object -First 1
    
    if ($Complete) {
        $Duration = ($Complete.TimeCreated - $Start.TimeCreated).TotalSeconds
        [PSCustomObject]@{
            VM = $VMName
            StartTime = $Start.TimeCreated
            EndTime = $Complete.TimeCreated
            DurationSeconds = $Duration
            DestinationHost = $DestHost
        }
    }
}
```

**Network Status:**
```powershell
# Cluster Network Configuration
Get-ClusterNetwork | Select-Object Name, State, Role, 
    Address, AddressMask, Metric, AutoMetric

# Network Interface Status
Get-ClusterNetworkInterface | Select-Object Name, Node, Network, 
    State, Adapter, @{N='IPv4Address';E={$_.Address}}

# RDMA Status (if applicable)
Get-NetAdapterRdma | Select-Object Name, Enabled, RdmaCapable

# SMB Multichannel Status
Get-SmbMultichannelConnection -IncludeNotSelected | 
    Select-Object ServerName, ClientInterfaceIndex, 
    ServerInterfaceIndex, CurrentChannels, MaxChannels
```

**Performance Counters:**
```powershell
# Network Throughput
$networkCounters = @(
    '\Network Interface(*)\Bytes Total/sec',
    '\Network Interface(*)\Output Queue Length',
    '\Network Interface(*)\Packets Received Discarded',
    '\Network Interface(*)\Packets Outbound Discarded',
    '\Cluster Network(*)\Bytes Sent/sec',
    '\Cluster Network(*)\Bytes Received/sec',
    '\Cluster Network(*)\Messages Sent/sec',
    '\Cluster Network(*)\Messages Received/sec'
)

# SMB Performance
$smbCounters = @(
    '\SMB Server Shares(*)\Data Bytes/sec',
    '\SMB Server Shares(*)\Current Data Queue Length',
    '\SMB Client Shares(*)\Read Bytes/sec',
    '\SMB Client Shares(*)\Write Bytes/sec',
    '\SMB Client Shares(*)\Avg. sec/Read',
    '\SMB Client Shares(*)\Avg. sec/Write'
)

# RDMA Performance (if applicable)
$rdmaCounters = @(
    '\RDMA Activity(*)\RDMA Inbound Bytes/sec',
    '\RDMA Activity(*)\RDMA Outbound Bytes/sec',
    '\RDMA Activity(*)\RDMA Inbound Frames/sec',
    '\RDMA Activity(*)\RDMA Outbound Frames/sec'
)
```

### NinjaRMM Custom Fields

**Network Fields:**
```yaml
# Boolean
clusterNetworkHealthy: true/false
clusterNetworkPartitioned: true/false
clusterRDMAEnabled: true/false
clusterSMBMultichannelEnabled: true/false

# Integer
clusterNetworkCount: 4
clusterNetworkFailures24h: 0
clusterNetworkReconnections24h: 0

# Text
clusterNetworkStatus: "Healthy|Warning|Critical"

# WYSIWYG
clusterNetworkSummary: [HTML table of networks]
clusterNetworkInterfaceSummary: [HTML table of interfaces]
```

**Live Migration Fields:**
```yaml
# Boolean
liveMigrationEnabled: true/false
liveMigrationFailures24h: true/false

# Integer
liveMigrationCount24h: 12
liveMigrationFailureCount24h: 0
liveMigrationAvgDurationSec: 45
liveMigrationMaxSimultaneous: 2

# Text
liveMigrationNetworks: "Management, LiveMig1, LiveMig2"

# WYSIWYG
liveMigrationHistory24h: [HTML table of recent migrations]
liveMigrationFailures: [HTML table of failures]
```

### Deliverables

- [ ] `ClusterNetworkHealthCheck.ps1` script
- [ ] `LiveMigrationMonitor.ps1` script
- [ ] `NetworkPerformanceCollector.ps1` script
- [ ] Migration duration baseline calculation
- [ ] Network partition alerting logic
- [ ] RDMA configuration validation
- [ ] Documentation for network monitoring

### Success Criteria

- All live migrations tracked with accurate duration
- Network failures detected within 30 seconds
- Migration failure root cause identified from events
- RDMA performance metrics collected (if enabled)
- Network partition detection < 1 minute

---

## Phase 5: Performance Counter Framework

**Status:** PLANNED  
**Timeline:** Week 9-10  
**Priority:** MEDIUM

### Objectives

Build comprehensive performance data collection and baseline framework:

1. **Script 10: PerformanceBaselineCollector.ps1**
   - Multi-day counter collection
   - Baseline calculation (avg, stddev, percentiles)
   - Anomaly detection
   - Historical trending
   - Capacity planning data

2. **Script 11: PerformanceAlertEngine.ps1**
   - Real-time counter monitoring
   - Dynamic threshold calculation
   - Alert suppression logic
   - Trend-based alerting
   - Predictive warnings

3. **Script 12: CapacityPlanningReport.ps1**
   - Resource utilization forecasting
   - Growth trend analysis
   - VM density recommendations
   - Storage capacity projections
   - Network bandwidth planning

### Technical Requirements

**Performance Counter Categories:**

**Node-Level Counters:**
```powershell
$nodeCounters = @(
    # CPU
    '\Processor(_Total)\% Processor Time',
    '\Processor Information(_Total)\% Privileged Time',
    '\Hyper-V Hypervisor Logical Processor(*)\% Total Run Time',
    '\Hyper-V Hypervisor Logical Processor(*)\% Guest Run Time',
    '\Hyper-V Hypervisor Logical Processor(*)\% Hypervisor Run Time',
    
    # Memory
    '\Memory\Available MBytes',
    '\Memory\% Committed Bytes In Use',
    '\Memory\Pages/sec',
    '\Memory\Pool Nonpaged Bytes',
    '\Hyper-V Dynamic Memory Balancer\Available Memory',
    '\Hyper-V Dynamic Memory Balancer\System Current Pressure',
    
    # Storage
    '\PhysicalDisk(*)\Disk Reads/sec',
    '\PhysicalDisk(*)\Disk Writes/sec',
    '\PhysicalDisk(*)\Avg. Disk sec/Read',
    '\PhysicalDisk(*)\Avg. Disk sec/Write',
    '\PhysicalDisk(*)\Avg. Disk Queue Length',
    '\PhysicalDisk(*)\Current Disk Queue Length',
    '\PhysicalDisk(*)\% Idle Time',
    
    # Network
    '\Network Interface(*)\Bytes Total/sec',
    '\Network Interface(*)\Output Queue Length',
    '\Network Interface(*)\Packets Received Discarded',
    '\Network Interface(*)\Packets Outbound Discarded'
)
```

**Cluster-Level Counters:**
```powershell
$clusterCounters = @(
    # Cluster Resources
    '\Cluster Resource(*)\Status',
    '\Cluster Resource(*)\Failures',
    
    # Cluster Networks
    '\Cluster Network(*)\Bytes Sent/sec',
    '\Cluster Network(*)\Bytes Received/sec',
    '\Cluster Network(*)\Messages Sent/sec',
    '\Cluster Network(*)\Messages Received/sec',
    
    # CSV Performance
    '\Cluster CSV File System(*)\Reads/sec',
    '\Cluster CSV File System(*)\Writes/sec',
    '\Cluster CSV File System(*)\Avg. sec/Read',
    '\Cluster CSV File System(*)\Avg. sec/Write',
    '\Cluster CSV File System(*)\Read Bytes/sec',
    '\Cluster CSV File System(*)\Write Bytes/sec',
    '\Cluster Disk Partition(*)\% Free Space'
)
```

**Hyper-V Counters:**
```powershell
$hypervCounters = @(
    # Virtual Machines (aggregate)
    '\Hyper-V Hypervisor\Virtual Processors',
    '\Hyper-V Hypervisor\Logical Processors',
    
    # Virtual Processor
    '\Hyper-V Hypervisor Virtual Processor(*)\% Guest Run Time',
    '\Hyper-V Hypervisor Virtual Processor(*)\% Hypervisor Run Time',
    '\Hyper-V Hypervisor Virtual Processor(*)\% Total Run Time',
    
    # Virtual Machine Memory
    '\Hyper-V Dynamic Memory VM(*)\Physical Memory',
    '\Hyper-V Dynamic Memory VM(*)\Guest Available Memory',
    '\Hyper-V Dynamic Memory VM(*)\Current Pressure',
    
    # Virtual Network Adapter
    '\Hyper-V Virtual Network Adapter(*)\Bytes/sec',
    '\Hyper-V Virtual Network Adapter(*)\Bytes Sent/sec',
    '\Hyper-V Virtual Network Adapter(*)\Bytes Received/sec',
    
    # Virtual Storage
    '\Hyper-V Virtual Storage Device(*)\Read Operations/Sec',
    '\Hyper-V Virtual Storage Device(*)\Write Operations/Sec',
    '\Hyper-V Virtual Storage Device(*)\Read Bytes/sec',
    '\Hyper-V Virtual Storage Device(*)\Write Bytes/sec'
)
```

**Baseline Calculation Logic:**
```powershell
# Collect counter samples over 7 days
$samples = @()
for ($day = 1; $day -le 7; $day++) {
    $daySamples = Get-Counter -Counter $counters -SampleInterval 300 -MaxSamples 288  # 5 min intervals
    $samples += $daySamples
}

# Calculate baseline statistics
foreach ($counter in $counters) {
    $values = $samples.CounterSamples | 
        Where-Object Path -like "*$counter*" | 
        Select-Object -ExpandProperty CookedValue
    
    $baseline = [PSCustomObject]@{
        Counter = $counter
        Average = ($values | Measure-Object -Average).Average
        StdDev = [Math]::Sqrt(($values | ForEach-Object { [Math]::Pow($_ - $avg, 2) } | Measure-Object -Average).Average)
        Percentile95 = ($values | Sort-Object)[([Math]::Floor($values.Count * 0.95))]
        Percentile99 = ($values | Sort-Object)[([Math]::Floor($values.Count * 0.99))]
        Min = ($values | Measure-Object -Minimum).Minimum
        Max = ($values | Measure-Object -Maximum).Maximum
    }
}
```

**Anomaly Detection:**
```powershell
# Detect values outside 3 standard deviations
function Test-Anomaly {
    param(
        [double]$Value,
        [double]$Baseline,
        [double]$StdDev,
        [int]$Threshold = 3
    )
    
    $deviation = [Math]::Abs($Value - $Baseline)
    return ($deviation -gt ($StdDev * $Threshold))
}

# Real-time monitoring
$currentValue = (Get-Counter $counter).CounterSamples[0].CookedValue

if (Test-Anomaly -Value $currentValue -Baseline $baseline.Average -StdDev $baseline.StdDev) {
    Write-Warning "ANOMALY DETECTED: $counter = $currentValue (baseline: $($baseline.Average) ± $($baseline.StdDev))"
}
```

### NinjaRMM Custom Fields

**Performance Baseline Fields:**
```yaml
# Integer
perfBaselineLastUpdated: 1739462400  # Unix timestamp
perfAnomaliesDetected24h: 3

# Text
perfBaselineStatus: "Current|Stale|Building"

# WYSIWYG
perfBaselineSummary: [HTML table of key counter baselines]
perfAnomalies24h: [HTML list of detected anomalies]
```

### Deliverables

- [ ] `PerformanceBaselineCollector.ps1` script
- [ ] `PerformanceAlertEngine.ps1` script
- [ ] `CapacityPlanningReport.ps1` script
- [ ] Baseline data storage structure
- [ ] Anomaly detection algorithm
- [ ] Capacity forecasting model
- [ ] Documentation for performance monitoring

### Success Criteria

- Baseline established from 7 days of data
- Anomaly detection false positive rate < 5%
- Performance data collected without impacting cluster
- Capacity forecasts accurate within 10%
- Alert suppression reduces noise by 80%

---

## Phase 6: Integration & Dashboards

**Status:** PLANNED  
**Timeline:** Week 11-12  
**Priority:** MEDIUM

### Objectives

Integrate all monitoring components into unified dashboard and alerting:

1. **Comprehensive Dashboard**
   - Cluster health overview widget
   - Node status grid
   - CSV space utilization chart
   - Recent failover timeline
   - Live migration history
   - Performance metric graphs

2. **Alert Correlation Engine**
   - Multi-event correlation
   - Root cause analysis
   - Alert storm suppression
   - Escalation logic
   - Notification routing

3. **Reporting Framework**
   - Daily cluster health report
   - Weekly capacity trending report
   - Monthly SLA compliance report
   - Ad-hoc diagnostic reports
   - Executive summary dashboards

### Technical Requirements

**Dashboard Data Aggregation:**
```powershell
# Collect all monitoring data
$clusterHealth = @{
    Timestamp = Get-Date -Format 'o'
    ClusterName = (Get-Cluster).Name
    
    # Node Health
    Nodes = Get-ClusterNode | ForEach-Object {
        @{
            Name = $_.Name
            State = $_.State
            HealthStatus = # ... from ClusterNodeHealthCheck
            CPU = # ... from PerformanceCollector
            Memory = # ... from PerformanceCollector
        }
    }
    
    # Storage Health
    CSVs = Get-ClusterSharedVolume | ForEach-Object {
        @{
            Name = $_.Name
            State = $_.State
            PercentFree = # ... from ClusterSharedVolumeMonitor
            IORedirected = # ... from ClusterSharedVolumeMonitor
        }
    }
    
    # Recent Events
    FailoverEvents = # ... from ClusterResourceGroupMonitor (last 24h)
    MigrationEvents = # ... from LiveMigrationMonitor (last 24h)
    NetworkEvents = # ... from ClusterNetworkHealthCheck (last 24h)
    
    # Performance Summary
    Performance = @{
        AvgCPU = # ... across all nodes
        AvgMemoryUsed = # ... across all nodes
        TotalVMs = (Get-VM).Count
        CSVTotalSpace = # ... sum of all CSVs
        CSVUsedSpace = # ... sum of all CSVs
    }
}

# Export to JSON for dashboard consumption
$clusterHealth | ConvertTo-Json -Depth 10 | Out-File "C:\Monitoring\ClusterHealth.json"
```

**Alert Correlation Logic:**
```powershell
# Detect cascading failures
$events = @{
    NodeFailure = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-FailoverClustering/Operational'
        ID = 1135
        StartTime = (Get-Date).AddMinutes(-5)
    }
    
    VMFailover = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-Hyper-V-High-Availability-Admin'
        ID = 21001
        StartTime = (Get-Date).AddMinutes(-5)
    }
    
    CSVOffline = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-FailoverClustering-CsvFs/Operational'
        ID = 5360
        StartTime = (Get-Date).AddMinutes(-5)
    }
}

# Correlate events
if ($events.NodeFailure -and $events.VMFailover) {
    Write-Output "ROOT CAUSE: Node failure triggered VM failovers"
    # Send single consolidated alert instead of multiple
}
```

### NinjaRMM Dashboard Widgets

**Cluster Overview Widget:**
```yaml
Widget Type: Custom HTML/JavaScript
Data Source: ClusterHealth.json (updated every 5 minutes)
Components:
  - Cluster name and overall health status
  - Node count with up/down/paused indicators
  - VM count with running/stopped/failed states
  - CSV count with space utilization
  - Recent events timeline (last 6 hours)
  - Key performance metrics (CPU, RAM, Storage)
```

**Node Grid Widget:**
```yaml
Widget Type: Data Grid
Fields:
  - Node Name
  - State (color-coded)
  - CPU Usage (%)
  - Memory Usage (%)
  - Uptime
  - Health Faults
  - Last Event
```

**CSV Space Widget:**
```yaml
Widget Type: Horizontal Bar Chart
Data: CSV volumes sorted by % used
Colors:
  - Green: 0-70% used
  - Yellow: 70-85% used
  - Red: 85-100% used
Click Action: Drill down to CSV details
```

**Migration History Widget:**
```yaml
Widget Type: Timeline/List
Data: Last 20 live migrations
Fields:
  - Timestamp
  - VM Name
  - Source Node → Destination Node
  - Duration
  - Success/Failure (color-coded)
```

### Deliverables

- [ ] Dashboard HTML/JavaScript templates
- [ ] Data aggregation scripts
- [ ] Alert correlation engine
- [ ] Report generation scripts
- [ ] Widget configuration guides
- [ ] Documentation for dashboard setup

### Success Criteria

- Dashboard updates every 5 minutes
- All critical metrics visible at a glance
- Alert correlation reduces notifications by 60%
- Reports generate automatically on schedule
- Dashboard loads in < 3 seconds

---

## Phase 7: Documentation & Deep Dive

**Status:** PLANNED  
**Timeline:** Week 13-14  
**Priority:** HIGH

### Objectives

Create comprehensive documentation matching existing deep-dive standards:

1. **Deep Dive Document: HyperVClusterMonitor-DeepDive.md**
   - Architecture overview
   - Script-by-script detailed explanation
   - Field reference guide
   - Real-world scenarios and troubleshooting
   - NinjaRMM integration guide
   - Advanced customization examples

2. **Quick Start Guide**
   - Installation checklist
   - Custom field creation
   - Automation policy setup
   - Alert configuration
   - Dashboard deployment

3. **Runbook Collection**
   - Common failure scenarios
   - Step-by-step remediation
   - Escalation procedures
   - Emergency response playbooks

### Document Structure

Following existing deep-dive format (see DNSServerMonitor_v3-DeepDive.md):

```markdown
# Hyper-V Cluster Monitoring - Deep Dive Guide

## Overview
- Key Capabilities
- Monitoring Scope
- Integration Points

## Technical Architecture
- Monitoring Scope Diagram
- Data Collection Flow
- Event Correlation Patterns

## Script Reference

### Script 1: ClusterNodeHealthCheck.ps1
- Purpose and Objectives
- Data Sources
- Field Mappings
- Logic Flow
- Examples

[... repeat for all 12 scripts ...]

## Field Reference
- Custom field definitions
- Value examples
- Type specifications
- Update frequencies

## Monitoring Logic Details
- Health Service fault interpretation
- Quorum loss detection
- CSV I/O redirection analysis
- Failover vs. Migration differentiation
- Performance baseline usage

## Real-World Scenarios

### Scenario 1: Node Communication Loss
- Symptoms
- Investigation Steps
- Root Cause Analysis
- Resolution Steps

### Scenario 2: CSV I/O Redirection Storm
[... 15-20 scenarios total ...]

## NinjaRMM Integration
- Automation Policy Setup
- Alert Conditions
- Dashboard Widgets
- Escalation Rules

## Advanced Customization
- Example 1: Multi-Site Cluster Monitoring
- Example 2: SQL Server Cluster Integration
- Example 3: SCVMM Integration
- Example 4: Azure Site Recovery Monitoring
- Example 5: Custom Performance Baselines

## Troubleshooting Guide
- Common Issues
- Script Debugging
- Event Log Analysis
- Performance Optimization

## Performance Optimization
- Query Efficiency
- Caching Strategies
- Parallel Processing
- Resource Management

## Integration Examples
- Splunk Integration
- Azure Monitor Integration
- SCOM Integration
- Grafana Dashboards

## Summary
- Key Takeaways
- Recommended Implementation
- Maintenance Schedule

---

**Script Locations:**
- ClusterNodeHealthCheck.ps1: `plaintext_scripts/ClusterNodeHealthCheck.ps1`
- [... all scripts ...]

**Related Documentation:**
- [Monitoring Overview](../Monitoring-Overview.md)
- [NinjaRMM Custom Fields Guide](../NinjaRMM-CustomFields.md)
- [Event Log Catalog](../archive/docs/hyper-v monitoring/research/EVENT_LOG_CATALOG.md)

**Last Updated:** [Date]
**Framework Version:** 4.0
```

### Deliverables

- [ ] `HyperVClusterMonitor-DeepDive.md` (main document)
- [ ] `HyperVClusterMonitor-QuickStart.md`
- [ ] `HyperVClusterMonitor-Runbooks.md`
- [ ] `HyperVClusterMonitor-APIReference.md`
- [ ] Script inline documentation (comment blocks)
- [ ] README files for each script directory
- [ ] Change log and version history

### Success Criteria

- Documentation completeness: 100% of scripts documented
- Scenario coverage: 20+ real-world scenarios
- Runbook coverage: All critical failure modes
- Review and approval by stakeholders
- Published to docs/deep-dives/

---

## Custom Field Definitions - Complete List

### Cluster Node & Health

```yaml
# Boolean Fields
clusterInstalled: true/false
clusterNodeHealthy: true/false
clusterQuorumHealthy: true/false
clusterHealthServiceFaults: true/false

# Integer Fields
clusterNodeCount: 0-999
clusterNodeFailures24h: 0-999
clusterResourceGroupCount: 0-999
clusterFailoverEvents24h: 0-999
clusterQuorumVotes: 0-999
clusterHealthFaultCount: 0-999

# Text Fields
clusterName: "CLUSTER01"
clusterNodeState: "Up|Down|Paused|Joining"
clusterQuorumType: "NodeMajority|NodeAndDiskMajority|NodeAndFileShareMajority"
clusterHealthStatus: "Healthy|Warning|Critical|Unknown"

# WYSIWYG Fields
clusterNodeSummary: [HTML table]
clusterResourceGroupSummary: [HTML table]
clusterHealthFaults: [HTML list]
```

### Storage & CSV

```yaml
# Boolean Fields
csvHealthy: true/false
csvIORedirected: true/false
csvLowSpaceAlert: true/false
s2dHealthy: true/false
s2dPhysicalDiskFailed: true/false
s2dVirtualDiskDegraded: true/false
s2dRebuildInProgress: true/false

# Integer Fields
csvCount: 0-999
csvTotalSizeGB: 0-999999
csvFreeSpaceGB: 0-999999
csvPercentFree: 0-100
csvRedirectionCount24h: 0-999
s2dPhysicalDiskCount: 0-999
s2dUnhealthyDiskCount: 0-999
s2dVirtualDiskCount: 0-999
s2dStoragePoolCapacityGB: 0-999999
s2dStoragePoolUsedGB: 0-999999

# Text Fields
csvHealthStatus: "Healthy|Warning|Critical"
s2dHealthStatus: "Healthy|Warning|Critical"
s2dRebuildProgress: "0-100%"

# WYSIWYG Fields
csvSummary: [HTML table]
csvIORedirectionEvents: [HTML list]
s2dPhysicalDiskSummary: [HTML table]
s2dVirtualDiskSummary: [HTML table]
s2dStorageJobsSummary: [HTML table]
```

### Network & Migration

```yaml
# Boolean Fields
clusterNetworkHealthy: true/false
clusterNetworkPartitioned: true/false
clusterRDMAEnabled: true/false
clusterSMBMultichannelEnabled: true/false
liveMigrationEnabled: true/false
liveMigrationFailures24h: true/false

# Integer Fields
clusterNetworkCount: 0-99
clusterNetworkFailures24h: 0-999
clusterNetworkReconnections24h: 0-999
liveMigrationCount24h: 0-999
liveMigrationFailureCount24h: 0-999
liveMigrationAvgDurationSec: 0-999999
liveMigrationMaxSimultaneous: 0-99

# Text Fields
clusterNetworkStatus: "Healthy|Warning|Critical"
liveMigrationNetworks: "Network1, Network2, Network3"

# WYSIWYG Fields
clusterNetworkSummary: [HTML table]
clusterNetworkInterfaceSummary: [HTML table]
liveMigrationHistory24h: [HTML table]
liveMigrationFailures: [HTML table]
```

### Performance & Baselines

```yaml
# Boolean Fields
perfBaselineEstablished: true/false
perfAnomalyDetected: true/false

# Integer Fields
perfBaselineLastUpdated: 0-9999999999  # Unix timestamp
perfAnomaliesDetected24h: 0-999
perfAvgNodeCPU: 0-100
perfAvgNodeMemory: 0-100
perfAvgDiskLatencyMs: 0-999
perfAvgNetworkMbps: 0-99999

# Text Fields
perfBaselineStatus: "Current|Stale|Building"

# WYSIWYG Fields
perfBaselineSummary: [HTML table]
perfAnomalies24h: [HTML list]
perfCapacityForecast: [HTML summary]
```

---

## Alert Configuration Templates

### Critical Alerts

**Node Failure Alert:**
```yaml
Alert Name: CRITICAL - Cluster Node Failure
Condition: clusterNodeFailures24h > 0 OR clusterNodeState = "Down"
Priority: P1
Notification: Email + SMS + Ticket
Subject: "CRITICAL: Cluster Node Down - {{device.name}}"
Body: |
  Cluster node failure detected.
  
  Cluster: {{custom.clusterName}}
  Failed Nodes: {{custom.clusterNodeFailures24h}}
  Current Node State: {{custom.clusterNodeState}}
  Quorum Status: {{custom.clusterQuorumHealthy}}
  
  IMMEDIATE ACTION REQUIRED - Cluster availability at risk.
  
  Recent Events:
  {{custom.clusterHealthFaults}}
```

**Quorum Loss Alert:**
```yaml
Alert Name: CRITICAL - Cluster Quorum Loss
Condition: clusterQuorumHealthy = false
Priority: P1
Notification: Email + SMS + Ticket
Subject: "CRITICAL: Cluster Quorum Lost - {{device.name}}"
Body: |
  Cluster has lost quorum and may be offline.
  
  Cluster: {{custom.clusterName}}
  Quorum Type: {{custom.clusterQuorumType}}
  Active Votes: {{custom.clusterQuorumVotes}}
  
  IMMEDIATE ACTION REQUIRED - Cluster services offline.
```

**CSV Offline Alert:**
```yaml
Alert Name: CRITICAL - CSV Volume Offline
Condition: csvHealthStatus = "Critical"
Priority: P1
Notification: Email + SMS + Ticket
Subject: "CRITICAL: CSV Volume Offline - {{device.name}}"
Body: |
  Cluster Shared Volume is offline.
  
  CSV Count: {{custom.csvCount}}
  Health Status: {{custom.csvHealthStatus}}
  
  VMs on this CSV are likely offline or failed over.
  
  Details:
  {{custom.csvSummary}}
```

### Warning Alerts

**High Failover Rate Alert:**
```yaml
Alert Name: WARNING - Excessive Failover Events
Condition: clusterFailoverEvents24h > 3
Priority: P2
Notification: Email + Ticket
Subject: "WARNING: High Failover Rate - {{device.name}}"
Body: |
  Cluster experiencing elevated failover activity.
  
  Failovers (24h): {{custom.clusterFailoverEvents24h}}
  Resource Groups: {{custom.clusterResourceGroupCount}}
  
  Review cluster logs for root cause.
  
  Resource Group Status:
  {{custom.clusterResourceGroupSummary}}
```

**CSV I/O Redirection Alert:**
```yaml
Alert Name: WARNING - CSV I/O Redirection Active
Condition: csvIORedirected = true
Priority: P2
Notification: Email
Subject: "WARNING: CSV I/O Redirection - {{device.name}}"
Body: |
  CSV is in redirected I/O mode (performance degradation).
  
  Redirection Events (24h): {{custom.csvRedirectionCount24h}}
  
  Storage connectivity issue detected - investigate storage network.
  
  Events:
  {{custom.csvIORedirectionEvents}}
```

**CSV Low Space Alert:**
```yaml
Alert Name: WARNING - CSV Low Space
Condition: csvPercentFree < 15
Priority: P2
Notification: Email
Subject: "WARNING: CSV Low Disk Space - {{device.name}}"
Body: |
  Cluster Shared Volume space below threshold.
  
  Total Size: {{custom.csvTotalSizeGB}} GB
  Free Space: {{custom.csvFreeSpaceGB}} GB
  Percent Free: {{custom.csvPercentFree}}%
  
  VM operations may fail if space exhausted.
  
  CSV Details:
  {{custom.csvSummary}}
```

**Live Migration Failures Alert:**
```yaml
Alert Name: WARNING - Live Migration Failures
Condition: liveMigrationFailures24h = true
Priority: P2
Notification: Email
Subject: "WARNING: Live Migration Failures - {{device.name}}"
Body: |
  Live migration failures detected.
  
  Total Migrations (24h): {{custom.liveMigrationCount24h}}
  Failed Migrations: {{custom.liveMigrationFailureCount24h}}
  
  Review migration network and resource availability.
  
  Failure Details:
  {{custom.liveMigrationFailures}}
```

**Storage Rebuild Alert:**
```yaml
Alert Name: INFO - Storage Rebuild In Progress
Condition: s2dRebuildInProgress = true
Priority: P3
Notification: Email
Subject: "INFO: Storage Rebuild Active - {{device.name}}"
Body: |
  Storage Spaces Direct rebuild in progress.
  
  Progress: {{custom.s2dRebuildProgress}}
  Unhealthy Disks: {{custom.s2dUnhealthyDiskCount}}
  
  Monitor rebuild completion. Performance may be impacted.
  
  Storage Jobs:
  {{custom.s2dStorageJobsSummary}}
```

### Informational Alerts

**Performance Anomaly Alert:**
```yaml
Alert Name: INFO - Performance Anomaly Detected
Condition: perfAnomalyDetected = true
Priority: P3
Notification: Email
Subject: "INFO: Performance Anomaly - {{device.name}}"
Body: |
  Performance metrics outside baseline.
  
  Anomalies (24h): {{custom.perfAnomaliesDetected24h}}
  
  Review for capacity constraints or workload changes.
  
  Anomaly Details:
  {{custom.perfAnomalies24h}}
```

---

## Success Metrics & KPIs

### Project Success Criteria

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Script Execution Success Rate | >99% | NinjaRMM task completion logs |
| Event Detection Latency | <2 minutes | Time between event and alert |
| False Positive Rate | <5% | Alert review analysis |
| Dashboard Load Time | <3 seconds | Browser performance testing |
| Documentation Completeness | 100% | Peer review checklist |
| Test Coverage | >80% | Unit test results |

### Operational KPIs (Post-Deployment)

| KPI | Target | Frequency |
|-----|--------|-----------|
| Cluster Uptime | >99.9% | Monthly |
| Unplanned Failovers | <2/month | Monthly |
| Mean Time to Detect (MTTD) | <5 minutes | Per incident |
| Mean Time to Repair (MTTR) | <30 minutes | Per incident |
| CSV Space Proactive Alerts | 100% before critical | Ongoing |
| Performance Anomaly Detection | >90% accuracy | Weekly review |

---

## Risk Assessment & Mitigation

### Identified Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Performance overhead from monitoring | Medium | Low | Implement caching, sampling, efficient queries |
| Event log overflow | Medium | Medium | Configure log retention, implement archiving |
| False positives causing alert fatigue | High | Medium | Implement alert correlation and suppression |
| Script failures on cluster changes | Medium | Low | Robust error handling, graceful degradation |
| Custom field limit exhaustion | Low | Low | Optimize field usage, combine related data |
| Network issues preventing remote monitoring | High | Low | Local caching, offline data collection |

---

## Resource Requirements

### Development Resources

- **PowerShell Developer**: 280 hours (14 weeks × 20 hours)
- **Technical Writer**: 80 hours (documentation)
- **QA Tester**: 40 hours (validation)
- **Infrastructure**: Test cluster (3 nodes minimum)

### Infrastructure Requirements

**Test Environment:**
- 3× Hyper-V nodes (Windows Server 2019+)
- Shared storage (CSV or S2D)
- 2× network adapters per node (management + cluster)
- NinjaRMM instance with custom fields enabled
- Monitoring workstation

**Production Deployment:**
- NinjaRMM licenses for all cluster nodes
- Custom field allocation (approximately 60 fields)
- Dashboard hosting (if external)
- Alert notification channels (email, SMS, ticketing)

---

## Dependencies & Prerequisites

### Software Dependencies

- Windows Server 2016 or later (2019/2022/2025 recommended)
- Hyper-V role installed
- Failover Clustering feature installed
- PowerShell 5.1 or later (7.x recommended)
- NinjaRMM agent v5.0+ installed
- .NET Framework 4.7.2 or later

### Knowledge Prerequisites

- Hyper-V cluster architecture
- PowerShell scripting (intermediate)
- Windows event log structure
- NinjaRMM automation policies
- Storage Spaces Direct (if applicable)
- Network concepts (RDMA, SMB, VLANs)

### Access Requirements

- Local Administrator on all cluster nodes
- Cluster Administrator permissions
- NinjaRMM admin access (custom fields, automation)
- Event log read permissions
- Performance counter access

---

## Change Management & Rollout Plan

### Phased Rollout Strategy

**Phase A: Lab Testing (Week 1-2)**
- Deploy scripts to isolated test cluster
- Validate all event queries
- Test custom field updates
- Performance impact assessment
- Bug fixing and optimization

**Phase B: Pilot Deployment (Week 3-4)**
- Select 1 production cluster (non-critical)
- Deploy node health monitoring only
- Validate alerting and dashboards
- Gather feedback from operations team
- Refine alert thresholds

**Phase C: Incremental Expansion (Week 5-8)**
- Add storage monitoring to pilot cluster
- Deploy to 2-3 additional clusters
- Introduce network and migration tracking
- Implement performance baseline collection
- Monitor for issues and adjust

**Phase D: Full Production (Week 9+)**
- Deploy to all production clusters
- Enable all monitoring components
- Activate full alerting suite
- Launch dashboards organization-wide
- Conduct training sessions

### Rollback Procedures

**Per-Script Rollback:**
```powershell
# Disable automation policy in NinjaRMM
# Optionally clear custom field values
$fields = @('clusterHealthStatus', 'clusterNodeSummary', ...)
foreach ($field in $fields) {
    Ninja-Property-Set $field ""
}
```

**Full Rollback:**
- Disable all Hyper-V cluster monitoring policies
- Archive collected data
- Document lessons learned
- Return to previous monitoring solution

---

## Maintenance & Support Plan

### Ongoing Maintenance

**Weekly Tasks:**
- Review alert noise and adjust thresholds
- Check dashboard performance
- Validate data collection integrity
- Monitor script execution logs

**Monthly Tasks:**
- Update performance baselines
- Review capacity planning forecasts
- Audit custom field usage
- Test disaster recovery scenarios
- Security patch review

**Quarterly Tasks:**
- Deep dive into monitoring effectiveness
- User satisfaction survey
- Documentation review and updates
- KPI analysis and reporting
- Training refreshers

### Support Structure

**Tier 1 Support (Help Desk):**
- Alert acknowledgment
- Dashboard access issues
- Basic threshold adjustments

**Tier 2 Support (Systems Team):**
- Script troubleshooting
- Custom field modifications
- Alert correlation review
- Performance tuning

**Tier 3 Support (Development Team):**
- Script enhancements
- New feature development
- Architecture changes
- Integration development

---

## Training & Knowledge Transfer

### Training Materials

**Administrator Training (4 hours):**
1. Hyper-V cluster monitoring overview (30 min)
2. Event log catalog walkthrough (45 min)
3. Script architecture and flow (60 min)
4. Dashboard navigation and interpretation (45 min)
5. Alert response procedures (60 min)

**Operations Training (2 hours):**
1. Dashboard usage (30 min)
2. Alert interpretation (30 min)
3. Common scenarios and runbooks (45 min)
4. Escalation procedures (15 min)

**Developer Training (8 hours):**
1. Complete script code review (3 hours)
2. Custom field mappings (1 hour)
3. Event query optimization (2 hours)
4. Testing and validation procedures (1 hour)
5. Contribution guidelines (1 hour)

### Documentation Deliverables

- [ ] Administrator training slides
- [ ] Operations quick reference guide
- [ ] Developer contribution guide
- [ ] Video walkthroughs (dashboard, alerts)
- [ ] Troubleshooting flowcharts

---

## Future Enhancements (Phase 8+)

### Potential Future Features

**Machine Learning Integration:**
- Predictive failure detection
- Automatic baseline adjustment
- Workload pattern recognition
- Capacity planning AI

**Advanced Automation:**
- Automatic failback scheduling
- CSV space balancing
- VM placement optimization
- Network path optimization

**Extended Integration:**
- Azure Site Recovery monitoring
- Backup solution integration (Veeam, SCDPM)
- SCOM bidirectional integration
- ServiceNow CMDB synchronization

**Enhanced Visualization:**
- 3D cluster topology maps
- Real-time migration flow visualization
- Historical trending dashboards
- Capacity heat maps

**Compliance & Auditing:**
- Configuration compliance tracking
- Security baseline validation
- Audit log collection
- Compliance reporting

---

## Appendix

### Reference Materials

**Microsoft Documentation:**
- [Failover Clustering Event IDs](https://learn.microsoft.com/en-us/windows-server/failover-clustering/failover-cluster-event-ids)
- [Hyper-V Performance Counters](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/performance-counters)
- [Storage Spaces Direct Health](https://learn.microsoft.com/en-us/azure-stack/hci/manage/health-service-overview)
- [CSV Monitoring](https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/cluster-shared-volumes)

**Community Resources:**
- [Virtualization DOJO](https://virtualizationdojo.com/)
- [Hyper-V Event Log Overview](https://virtualizationdojo.com/hyper-v/an-overview-of-hyper-v-event-logs/)
- [PowerShell Gallery - Hyper-V Modules](https://www.powershellgallery.com/)

**Internal References:**
- `archive/docs/hyper-v monitoring/research/EVENT_LOG_CATALOG.md`
- `docs/deep-dives/DNSServerMonitor_v3-DeepDive.md` (template)
- `docs/standards/` (coding standards)

### Glossary

**CSV**: Cluster Shared Volume - Shared storage accessible by all cluster nodes simultaneously

**S2D**: Storage Spaces Direct - Software-defined storage pooling multiple node disks

**RDMA**: Remote Direct Memory Access - High-performance network protocol bypassing CPU

**SMB Multichannel**: Simultaneous SMB connections over multiple network paths

**Quorum**: Voting mechanism determining cluster operational state

**Live Migration**: Moving running VMs between nodes with no downtime

**Failover**: Automatic VM restart on different node after failure

**Health Service**: Windows Server component monitoring cluster component health

**I/O Redirection**: CSV fallback mode routing I/O through coordinator node

**Node Weight**: Vote contribution in quorum calculation (0 or 1)

---

## Document Control

**Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-02-13 | Initial | Plan creation |
| 1.0 | TBD | TBD | Final approval |

**Review Schedule:**
- Weekly during development (Phases 2-6)
- Monthly post-deployment
- Quarterly comprehensive review

**Approvals Required:**
- [ ] Technical Lead
- [ ] Operations Manager
- [ ] Security Team
- [ ] Change Advisory Board

---

**Document Owner:** Windows Automation Framework Team  
**Created:** February 13, 2026  
**Status:** Planning Phase  
**Next Review:** February 20, 2026  
**Related Documents:**
- [EVENT_LOG_CATALOG.md](../archive/docs/hyper-v monitoring/research/EVENT_LOG_CATALOG.md)
- [WAF Monitoring Strategy](./Monitoring-Overview.md)
- [NinjaRMM Integration Guide](./NinjaRMM-Integration.md)