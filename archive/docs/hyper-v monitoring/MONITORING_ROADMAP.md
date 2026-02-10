# Hyper-V Advanced Monitoring Roadmap

**Project:** Enhanced Hyper-V Monitoring Suite Development  
**Created:** February 10, 2026  
**Status:** Planning Phase  
**Target Completion:** Q3 2026

---

## Executive Summary

This roadmap outlines the development plan for advanced Hyper-V monitoring capabilities beyond the current baseline (Monitor 1 & Health Check 2). The features are organized into 6 logical monitoring scripts, each focusing on a specific domain:

1. **Performance Monitor** - VM and host performance metrics
2. **Capacity Planner** - Resource trends and growth forecasting
3. **Cluster Analytics** - Advanced cluster operations monitoring
4. **Backup & Compliance Monitor** - Guest OS health and backup integration
5. **Storage Performance Monitor** - Disk metrics and CSV analytics
6. **Multi-Host Aggregator** - Cluster-wide aggregation and reporting

---

## Current State

### Implemented (v1.0)

**Hyper-V Monitor 1.ps1:**
- VM state and uptime tracking
- Basic resource utilization (CPU, memory)
- Integration services status
- Cluster membership and health
- HTML report generation

**Hyper-V Health Check 2.ps1:**
- Quick health status determination
- Event log monitoring (24h)
- Basic storage latency
- CSV health and space
- Cluster quorum validation

### Gaps Identified

**Performance Metrics:**
- No per-VM network throughput
- No disk IOPS/latency per VM
- No virtual switch performance counters
- No queue depth monitoring
- No live migration bandwidth tracking

**Capacity Planning:**
- No historical trend data
- No growth forecasting
- No overcommitment ratio tracking
- No checkpoint space analysis
- No VHD fragmentation detection

**Advanced Cluster:**
- No migration history
- No failover event tracking
- No CSV performance metrics
- No witness monitoring
- No per-network bandwidth stats

**Guest OS Integration:**
- No patch compliance checking
- No backup status integration
- No integration service version tracking
- No guest-level monitoring

---

## Proposed Script Architecture

### Script 3: Hyper-V Performance Monitor

**File:** `Hyper-V Performance Monitor 3.ps1`  
**Frequency:** Every 10 minutes  
**Duration:** ~20 seconds  
**Purpose:** Detailed VM and host performance metrics

**Features:**
- Network throughput per VM (MB/s in/out)
- Disk IOPS per VM (read/write)
- Disk latency per VM (avg read/write ms)
- Virtual switch packet statistics
- Virtual switch drop rate
- Queue depth per virtual disk
- Network adapter statistics per VM
- CPU queue length
- Memory paging per VM
- Live migration bandwidth usage

**Research Required:**
- Hyper-V performance counter mapping
- VM network adapter counter discovery
- Virtual disk performance counter paths
- Virtual switch counter enumeration
- Live migration network counter identification

**NinjaRMM Fields (10-15):**
- `hypervPerfVMHighNetwork` (Text: VMs with >500MB/s)
- `hypervPerfVMHighIOPS` (Text: VMs with >10k IOPS)
- `hypervPerfVMHighLatency` (Text: VMs with >50ms latency)
- `hypervPerfVSwitchDropRate` (Float: packet drop %)
- `hypervPerfQueueDepthMax` (Integer: highest queue depth)
- `hypervPerfMigrationBandwidth` (Integer: MB/s)
- `hypervPerfReport` (WYSIWYG: HTML performance table)

---

### Script 4: Hyper-V Capacity Planner

**File:** `Hyper-V Capacity Planner 4.ps1`  
**Frequency:** Daily (off-peak hours)  
**Duration:** ~30 seconds  
**Purpose:** Historical trends and capacity forecasting

**Features:**
- VM resource usage trends (7/30/90 day)
- Host resource growth patterns
- Overcommitment ratios (CPU, memory, storage)
- Checkpoint space consumption per VM
- Total checkpoint storage usage
- VHD/VHDX fragmentation detection
- Snapshot chain depth per VM
- Storage space forecasting (days until full)
- VM count growth trend
- Memory demand vs. allocation trends

**Research Required:**
- Historical data storage approach (CSV files or database)
- VHD fragmentation detection methods
- Snapshot chain depth calculation
- Forecasting algorithms (linear regression)
- Performance counter historical capture

**Data Storage:**
- Local CSV files: `C:\ProgramData\WAF\HyperV\Capacity\YYYY-MM-DD.csv`
- Retention: 90 days
- Fields: Date, VMName, CPU%, Memory%, DiskGB, NetworkMB

**NinjaRMM Fields (12-15):**
- `hypervCapOvercommitCPU` (Float: CPU overcommit ratio)
- `hypervCapOvercommitMemory` (Float: Memory overcommit ratio)
- `hypervCapCheckpointSpaceGB` (Integer: total checkpoint space)
- `hypervCapVMsWithLongChains` (Integer: VMs with >5 snapshots)
- `hypervCapStorageDaysRemaining` (Integer: days until CSV full)
- `hypervCapVMGrowthRate` (Float: VMs per month)
- `hypervCapHighFragmentation` (Text: VMs with >20% fragmentation)
- `hypervCapForecastReport` (WYSIWYG: trend charts and forecasts)

---

### Script 5: Hyper-V Cluster Analytics

**File:** `Hyper-V Cluster Analytics 5.ps1`  
**Frequency:** Every 15 minutes  
**Duration:** ~15 seconds  
**Purpose:** Advanced cluster operations and event tracking

**Features:**
- Live migration history (last 24h/7d)
- Migration success/failure rate
- Average migration duration
- Failover event tracking (last 30d)
- Failover frequency per VM
- CSV IOPS per volume
- CSV latency per volume
- CSV throughput (MB/s)
- Cluster witness status and type
- Witness accessibility check
- Network bandwidth per cluster network
- Cluster network role utilization
- Recent cluster state changes

**Research Required:**
- Live migration event log IDs
- Cluster event log parsing for failovers
- CSV performance counter paths
- Cluster network performance counter discovery
- Witness configuration query methods
- Migration duration calculation from events

**NinjaRMM Fields (15-18):**
- `hypervClusterMigrations24h` (Integer: migration count)
- `hypervClusterMigrationSuccessRate` (Float: success %)
- `hypervClusterAvgMigrationTime` (Integer: seconds)
- `hypervClusterFailovers30d` (Integer: failover count)
- `hypervClusterCSVMaxIOPS` (Integer: highest IOPS)
- `hypervClusterCSVMaxLatency` (Integer: highest latency ms)
- `hypervClusterWitnessType` (Text: None/Disk/FileShare/Cloud)
- `hypervClusterWitnessStatus` (Text: OK/Failed/Unknown)
- `hypervClusterNetworkReport` (WYSIWYG: network bandwidth table)
- `hypervClusterAnalyticsReport` (WYSIWYG: migration/failover stats)

---

### Script 6: Hyper-V Backup & Compliance Monitor

**File:** `Hyper-V Backup Compliance Monitor 6.ps1`  
**Frequency:** Daily (early morning)  
**Duration:** ~45 seconds  
**Purpose:** Guest OS health and backup integration

**Features:**
- Guest OS patch compliance (Windows Update status)
- Days since last Windows Update
- Pending reboot detection in guests
- Integration service version per VM
- Integration service update available flag
- Backup job status (via Hyper-V VSS)
- Last successful backup timestamp per VM
- Days since last backup
- Backup age threshold alerts
- Replica lag time (seconds behind)
- Replication health score
- Guest OS version detection
- Guest disk space monitoring
- Antivirus status (if detectable)

**Research Required:**
- Guest OS WMI query methods (requires credentials)
- Windows Update status detection in guests
- Integration service version detection
- Hyper-V VSS writer status query
- Backup timestamp extraction methods
- Veeam/Windows Backup API integration
- Replication lag time calculation
- Guest credential management (secure storage)

**Security Considerations:**
- Guest credentials storage (encrypted)
- Minimal privilege requirements
- Guest firewall exceptions
- WinRM configuration requirements

**NinjaRMM Fields (15-20):**
- `hypervBackupVMsNeverBacked` (Integer: count)
- `hypervBackupVMsOverdue` (Integer: >7 days)
- `hypervBackupOldestDays` (Integer: days since oldest backup)
- `hypervComplianceVMsNeedUpdates` (Integer: pending updates)
- `hypervComplianceVMsNeedReboot` (Integer: pending reboot)
- `hypervComplianceIntServicesOld` (Integer: VMs with old versions)
- `hypervReplicaMaxLagSeconds` (Integer: highest lag)
- `hypervReplicaVMsLagging` (Integer: VMs >300s lag)
- `hypervBackupReport` (WYSIWYG: backup status table)
- `hypervComplianceReport` (WYSIWYG: compliance status table)

---

### Script 7: Hyper-V Storage Performance Monitor

**File:** `Hyper-V Storage Performance Monitor 7.ps1`  
**Frequency:** Every 10 minutes  
**Duration:** ~25 seconds  
**Purpose:** Detailed storage I/O metrics and analysis

**Features:**
- Disk IOPS per VM (read/write split)
- Disk throughput per VM (MB/s)
- Disk latency per VM (read/write avg/max)
- Disk queue depth per virtual disk
- Storage path performance (if multipath)
- CSV I/O statistics per volume
- CSV cache hit rate
- CSV metadata operations/sec
- Storage migration tracking (active/recent)
- Storage migration progress %
- Storage migration estimated time remaining
- VHD/VHDX file fragmentation %
- Storage thin provisioning utilization
- Storage overprovisioning ratio

**Research Required:**
- Virtual disk performance counter paths
- CSV cache performance counters
- Storage migration event log IDs
- VHD fragmentation detection via WMI
- Thin provisioning statistics retrieval
- Multipath IO counter discovery

**NinjaRMM Fields (15-18):**
- `hypervStorageVMsHighIOPS` (Text: VMs with >20k IOPS)
- `hypervStorageVMsHighLatency` (Text: VMs with >100ms)
- `hypervStorageCSVCacheHitRate` (Float: % cache hits)
- `hypervStorageMigrationsActive` (Integer: active count)
- `hypervStorageFragmentedVMs` (Integer: >15% fragmentation)
- `hypervStorageThinProvisionedGB` (Integer: allocated)
- `hypervStorageOverprovisionRatio` (Float: ratio)
- `hypervStoragePerformanceReport` (WYSIWYG: I/O metrics table)

---

### Script 8: Hyper-V Multi-Host Aggregator

**File:** `Hyper-V Multi-Host Aggregator 8.ps1`  
**Frequency:** Every 30 minutes  
**Duration:** ~60 seconds  
**Purpose:** Cluster-wide aggregation and cross-host reporting

**Features:**
- Cluster-wide VM inventory
- Total cluster resource utilization
- VM distribution by node
- VM balance score (evenness)
- Cluster-wide capacity metrics
- Aggregate performance statistics
- Cross-node VM comparison
- Cluster health score (0-100)
- Resource pool utilization
- Cluster-wide event summary
- Multi-host correlation analysis
- Predictive failure analysis
- Capacity exhaustion forecasting
- Cluster-wide HTML dashboard

**Research Required:**
- Multi-node data collection methods
- Cluster-aware WMI queries
- Data aggregation algorithms
- Balance score calculation
- Health score weighting
- Predictive analytics algorithms
- Cross-host correlation methods

**Execution Model:**
- Run on one cluster node (coordinator)
- Query all cluster nodes
- Aggregate data centrally
- Store cluster-wide report

**NinjaRMM Fields (12-15):**
- `hypervClusterTotalVMs` (Integer: all VMs)
- `hypervClusterTotalCPUPercent` (Integer: avg utilization)
- `hypervClusterTotalMemoryPercent` (Integer: avg utilization)
- `hypervClusterBalanceScore` (Integer: 0-100, 100=perfect)
- `hypervClusterHealthScore` (Integer: 0-100, 100=perfect)
- `hypervClusterCapacityDays` (Integer: days until capacity exhausted)
- `hypervClusterDashboard` (WYSIWYG: cluster-wide HTML report)

---

## Implementation Phases

### Phase 1: Research & POC (2 weeks)

**Week 1: Performance Counter Discovery**
- Map all Hyper-V performance counters
- Test counter availability on test cluster
- Document counter paths and meanings
- Identify gaps requiring alternative methods

**Week 2: Event Log Research**
- Catalog migration event IDs
- Catalog failover event IDs
- Test event log query performance
- Document event structure and parsing

**Deliverables:**
- Performance counter reference document
- Event log catalog with examples
- POC scripts for critical features

---

### Phase 2: Core Scripts Development (4 weeks)

**Week 3: Performance Monitor (Script 3)**
- Implement VM network throughput tracking
- Add disk IOPS and latency per VM
- Add virtual switch performance
- Add queue depth monitoring
- Create HTML performance report
- Test with various VM workloads

**Week 4: Storage Performance Monitor (Script 7)**
- Implement detailed disk metrics
- Add CSV performance tracking
- Add storage migration detection
- Add VHD fragmentation checks
- Create storage report
- Test with storage-intensive workloads

**Week 5: Cluster Analytics (Script 5)**
- Implement migration history tracking
- Add failover event tracking
- Add CSV performance metrics
- Add witness monitoring
- Add network bandwidth tracking
- Create analytics report
- Test on production cluster

**Week 6: Backup & Compliance (Script 6)**
- Research guest WMI access methods
- Implement patch compliance checking
- Add integration service version tracking
- Add backup status integration
- Add replica lag monitoring
- Create compliance report
- Test guest access and security

**Deliverables:**
- 4 production-ready scripts (3, 5, 6, 7)
- Complete documentation per script
- Test results and validation

---

### Phase 3: Advanced Features (4 weeks)

**Week 7: Capacity Planner (Script 4)**
- Design historical data storage
- Implement trend tracking
- Add growth forecasting algorithms
- Add overcommitment calculations
- Add checkpoint analysis
- Add VHD fragmentation tracking
- Create capacity planning report
- Test forecasting accuracy

**Week 8: Multi-Host Aggregator (Script 8)**
- Design multi-node data collection
- Implement cluster-wide queries
- Add aggregation algorithms
- Add health score calculation
- Add predictive analytics
- Create cluster dashboard
- Test on multi-node cluster

**Week 9: Integration & Testing**
- Test all scripts together
- Validate field updates
- Check performance impact
- Verify NinjaRMM integration
- Test alert conditions
- Validate HTML reports

**Week 10: Documentation & Polish**
- Complete all script documentation
- Update main README
- Create troubleshooting guides
- Write deployment guide
- Create field creation guide
- Prepare training materials

**Deliverables:**
- 2 additional scripts (4, 8)
- Complete monitoring suite (8 scripts)
- Comprehensive documentation
- Deployment and training guides

---

### Phase 4: Production Deployment (2 weeks)

**Week 11: Pilot Deployment**
- Deploy to test Hyper-V hosts
- Monitor for 1 week
- Collect user feedback
- Fix bugs and issues
- Optimize performance

**Week 12: Production Rollout**
- Deploy to all Hyper-V hosts
- Configure NinjaRMM alerts
- Set up dashboards
- Train administrators
- Document known issues

**Deliverables:**
- Production deployment
- Alert configurations
- Dashboard templates
- Training completed

---

## Research Topics & Resources

### Performance Counter Research

**Required Research:**

1. **VM Network Performance:**
   - Counter: `\Hyper-V Virtual Switch(*)\*`
   - Counter: `\Hyper-V Virtual Network Adapter(*)\*`
   - Research: Map VM name to counter instance
   - Research: Aggregate multiple NICs per VM

2. **VM Disk Performance:**
   - Counter: `\Hyper-V Virtual Storage Device(*)\*`
   - Counter: `\Hyper-V Virtual IDE Controller(*)\*`
   - Research: Map virtual disk to VM
   - Research: Read vs Write split metrics

3. **CSV Performance:**
   - Counter: `\Cluster CSV File System(*)\*`
   - Counter: `\Cluster CSV Volume Manager(*)\*`
   - Research: CSV-specific IOPS counters
   - Research: CSV cache performance

4. **Live Migration:**
   - Counter: `\Hyper-V VM Live Migration(*)\*`
   - Research: Migration bandwidth measurement
   - Research: Active migration detection

**Resources:**
- [Hyper-V Performance Counters](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/hh848518(v=ws.11))
- [CSV Performance Counters](https://learn.microsoft.com/en-us/windows-server/failover-clustering/failover-cluster-csvs)
- [Performance Tuning Hyper-V](https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/hyper-v-server/)

---

### Event Log Research

**Required Research:**

1. **Live Migration Events:**
   - Log: Microsoft-Windows-Hyper-V-VMMS-Admin
   - Event IDs: 20417, 21002, 21008
   - Research: Migration start/complete events
   - Research: Duration calculation

2. **Failover Events:**
   - Log: FailoverClustering/Operational
   - Event IDs: 1146, 1230, 1069
   - Research: Failover trigger detection
   - Research: Resource group movement

3. **Storage Migration:**
   - Log: Microsoft-Windows-Hyper-V-VMMS-Admin
   - Event ID: 20414
   - Research: Progress tracking
   - Research: Completion detection

4. **Backup Events:**
   - Log: Microsoft-Windows-Hyper-V-VMMS-Admin
   - Event IDs: 18310, 18311
   - Research: VSS backup start/complete
   - Research: Backup application identification

**Resources:**
- [Hyper-V Event Log Reference](https://virtualizationdojo.com/hyper-v/an-overview-of-hyper-v-event-logs/)
- [Failover Cluster Events](https://learn.microsoft.com/en-us/windows-server/failover-clustering/failover-cluster-event-ids)

---

### Guest OS Integration Research

**Required Research:**

1. **WinRM Access:**
   - Credential storage options
   - CIM session configuration
   - Firewall requirements
   - Authentication methods

2. **Patch Compliance:**
   - Windows Update WMI classes
   - Update pending detection
   - Reboot pending registry keys
   - Last update timestamp

3. **Integration Services:**
   - Version detection methods
   - Update availability check
   - Guest service status
   - Driver version queries

4. **Backup Integration:**
   - Veeam PowerShell module
   - Windows Server Backup cmdlets
   - Third-party backup APIs
   - VSS writer status

**Resources:**
- [PowerShell Remoting](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/08-powershell-remoting)
- [Windows Update WMI](https://learn.microsoft.com/en-us/windows/win32/wua_sdk/portal-client)

---

### Capacity Planning Research

**Required Research:**

1. **Historical Data Storage:**
   - CSV file format design
   - SQLite database option
   - Data retention strategy
   - Query performance optimization

2. **Trend Analysis:**
   - Linear regression algorithms
   - Moving average calculation
   - Seasonal adjustment
   - Anomaly detection

3. **Forecasting:**
   - Resource exhaustion prediction
   - Growth rate calculation
   - Confidence intervals
   - Forecast accuracy tracking

4. **VHD Fragmentation:**
   - Fragmentation detection via FSUTIL
   - VHD file analysis
   - Impact assessment
   - Defragmentation recommendations

**Resources:**
- [PowerShell Statistical Analysis](https://www.powershellgallery.com/packages/PSStatistics)
- [VHD Management](https://learn.microsoft.com/en-us/powershell/module/hyper-v/get-vhd)

---

### Multi-Host Aggregation Research

**Required Research:**

1. **Data Collection:**
   - Cluster-aware queries
   - Remote PowerShell execution
   - Data caching strategies
   - Collection failure handling

2. **Aggregation Algorithms:**
   - Cross-node data correlation
   - Statistical aggregation methods
   - Weighted averages
   - Outlier detection

3. **Health Scoring:**
   - Component weight assignment
   - Score calculation algorithms
   - Historical score tracking
   - Threshold tuning

4. **Predictive Analytics:**
   - Failure prediction models
   - Pattern recognition
   - Anomaly detection
   - Machine learning integration (future)

**Resources:**
- [Failover Cluster PowerShell](https://learn.microsoft.com/en-us/powershell/module/failoverclusters/)
- [Cluster-Aware Updating](https://learn.microsoft.com/en-us/windows-server/failover-clustering/cluster-aware-updating)

---

## Data Architecture

### Historical Data Storage

**Option 1: CSV Files (Recommended for v1)**
```
C:\ProgramData\WAF\HyperV\
  ├─ Capacity\           # Capacity planning data
  │   ├─ 2026-02-10.csv
  │   ├─ 2026-02-11.csv
  │   └─ ...
  ├─ Performance\       # Performance metrics
  │   ├─ 2026-02-10.csv
  │   └─ ...
  ├─ Migrations\        # Migration history
  │   ├─ 2026-02.csv
  │   └─ ...
  └─ Failovers\         # Failover events
      ├─ 2026-02.csv
      └─ ...
```

**CSV Format Example (Capacity):**
```csv
Timestamp,HostName,VMName,CPUPercent,MemoryMB,DiskGB,NetworkMB,State
2026-02-10T10:00:00Z,HOST1,VM-SQL1,45.2,8192,250,125.5,Running
2026-02-10T10:00:00Z,HOST1,VM-WEB1,12.3,4096,100,45.2,Running
```

**Retention Policy:**
- Daily files: 90 days retention
- Weekly aggregates: 1 year retention
- Monthly aggregates: 3 years retention

**Option 2: SQLite Database (Future v2)**
- Single database file per host
- Better query performance
- Relational data structure
- Requires SQLite PowerShell module

---

## Performance Considerations

### Script Performance Targets

| Script | Target Duration | Max Acceptable |
|--------|----------------|----------------|
| Performance Monitor | 20s | 30s |
| Capacity Planner | 30s | 60s |
| Cluster Analytics | 15s | 25s |
| Backup & Compliance | 45s | 90s |
| Storage Performance | 25s | 40s |
| Multi-Host Aggregator | 60s | 120s |

### Performance Optimization Strategies

**1. Parallel Processing:**
```powershell
# Use ForEach-Object -Parallel for VM enumeration
$VMs | ForEach-Object -Parallel {
    # Process each VM independently
} -ThrottleLimit 10
```

**2. Counter Batching:**
```powershell
# Get all counters in single call
$Counters = Get-Counter -Counter @(
    '\Processor(_Total)\% Processor Time',
    '\Memory\Available MBytes',
    '\Hyper-V Virtual Storage Device(*)\*'
) -ErrorAction SilentlyContinue
```

**3. Caching:**
```powershell
# Cache VM list if unchanged
if (-not $script:VMListCache -or (Get-Date) -gt $script:VMListCacheExpiry) {
    $script:VMListCache = Get-VM
    $script:VMListCacheExpiry = (Get-Date).AddMinutes(5)
}
```

**4. Selective Queries:**
```powershell
# Only query running VMs for performance metrics
$RunningVMs = Get-VM | Where-Object { $_.State -eq 'Running' }
```

---

## Testing Strategy

### Unit Testing

**Test Environments:**
- Standalone Hyper-V host (Windows Server 2022)
- 2-node failover cluster
- 4-node production cluster
- Mixed Gen1/Gen2 VMs
- Various VM workloads (SQL, Web, File Server)

**Test Scenarios:**
1. **Performance Monitor:**
   - High network throughput VM
   - High IOPS VM (database)
   - Idle VMs
   - VMs with multiple NICs
   - VMs with multiple disks

2. **Capacity Planner:**
   - Empty history (first run)
   - 30 days of history
   - 90 days of history
   - Growth scenario (add VMs)
   - Shrink scenario (remove VMs)

3. **Cluster Analytics:**
   - Active live migration
   - Planned failover
   - Unplanned failover
   - CSV ownership change
   - Network partition

4. **Backup & Compliance:**
   - VMs with recent backups
   - VMs never backed up
   - VMs with pending updates
   - VMs with old integration services
   - Mixed Windows versions

5. **Storage Performance:**
   - Active storage migration
   - Fragmented VHDs
   - Thin-provisioned storage
   - CSV under load
   - Multiple storage tiers

6. **Multi-Host Aggregator:**
   - All nodes online
   - One node offline
   - Unbalanced VM distribution
   - Mixed node versions

### Performance Testing

**Metrics to Track:**
- Script execution time
- CPU usage during execution
- Memory usage during execution
- Network bandwidth (for multi-host)
- Disk I/O generated
- NinjaRMM field update time

**Acceptance Criteria:**
- Execution time within targets
- CPU usage <5% average
- Memory usage <200MB peak
- No missed executions due to timeout
- No impact on VM performance

---

## NinjaRMM Field Planning

### Total Fields Required

**Current (Scripts 1-2):** 28 fields  
**Performance Monitor (Script 3):** +10 fields  
**Capacity Planner (Script 4):** +12 fields  
**Cluster Analytics (Script 5):** +15 fields  
**Backup & Compliance (Script 6):** +18 fields  
**Storage Performance (Script 7):** +15 fields  
**Multi-Host Aggregator (Script 8):** +12 fields  
**Total:** ~110 fields

### Field Naming Convention

**Prefix Structure:**
- `hyperv` - Base prefix (all Hyper-V monitoring)
- `hypervPerf` - Performance metrics
- `hypervCap` - Capacity planning
- `hypervCluster` - Cluster operations
- `hypervBackup` - Backup status
- `hypervCompliance` - Compliance checks
- `hypervStorage` - Storage metrics

**Field Type Guidelines:**
- Text: Status, lists, short strings (<500 chars)
- Integer: Counts, percentages, durations
- Float: Ratios, precise percentages
- Checkbox: Boolean states
- DateTime: Timestamps (ISO 8601 format)
- WYSIWYG: HTML reports

---

## Documentation Requirements

### Per-Script Documentation

Each script must include:

1. **Comment-Based Help:**
   - Complete SYNOPSIS
   - Detailed DESCRIPTION
   - NOTES section with metadata
   - Fields updated list
   - Dependencies
   - Exit codes

2. **README Section:**
   - Purpose and capabilities
   - Execution details
   - Field reference table
   - Example output
   - Troubleshooting guide

3. **Research Notes:**
   - Data sources used
   - Performance counter mapping
   - Event log IDs referenced
   - Algorithm explanations
   - Known limitations

### Main Documentation Updates

Update main README.md with:
- Script comparison table
- Recommended execution frequencies
- Alert condition examples
- Dashboard widget examples
- Troubleshooting section expansion

---

## Risk Assessment

### Technical Risks

**Risk 1: Performance Counter Availability**
- **Impact:** High
- **Probability:** Medium
- **Mitigation:** Test on multiple Hyper-V versions, provide fallback methods

**Risk 2: Guest OS Access**
- **Impact:** High
- **Probability:** High
- **Mitigation:** Make guest monitoring optional, provide credential guidance

**Risk 3: Historical Data Storage**
- **Impact:** Medium
- **Probability:** Low
- **Mitigation:** Implement data retention, monitor disk usage

**Risk 4: Script Execution Time**
- **Impact:** Medium
- **Probability:** Medium
- **Mitigation:** Optimize queries, implement caching, use parallel processing

**Risk 5: Multi-Host Data Collection**
- **Impact:** High
- **Probability:** Medium
- **Mitigation:** Handle node failures gracefully, implement timeout protection

### Operational Risks

**Risk 6: Alert Fatigue**
- **Impact:** Medium
- **Probability:** High
- **Mitigation:** Tune thresholds carefully, implement multi-level alerts

**Risk 7: Field Limit**
- **Impact:** Low
- **Probability:** Low
- **Mitigation:** Consolidate data in WYSIWYG fields, use text fields for lists

**Risk 8: Backup API Compatibility**
- **Impact:** Medium
- **Probability:** Medium
- **Mitigation:** Support multiple backup solutions, make integration optional

---

## Success Criteria

### Phase 1 Success (Research)
- [ ] All performance counters documented
- [ ] All event log IDs cataloged
- [ ] POC scripts functional
- [ ] No blocking technical issues identified

### Phase 2 Success (Core Scripts)
- [ ] Scripts 3, 5, 6, 7 completed
- [ ] All scripts meet performance targets
- [ ] All scripts follow WAF standards
- [ ] Documentation complete
- [ ] Unit tests passed

### Phase 3 Success (Advanced Features)
- [ ] Scripts 4, 8 completed
- [ ] Historical data storage functional
- [ ] Forecasting accuracy >80%
- [ ] Multi-host aggregation tested
- [ ] All integration tests passed

### Phase 4 Success (Production)
- [ ] Deployed to all Hyper-V hosts
- [ ] Alert configurations active
- [ ] Dashboard widgets created
- [ ] No performance impact on VMs
- [ ] Administrator training completed
- [ ] User satisfaction >85%

---

## Timeline Summary

**Total Duration:** 12 weeks (3 months)

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Phase 1: Research | 2 weeks | Counter docs, Event catalog, POCs |
| Phase 2: Core Scripts | 4 weeks | Scripts 3, 5, 6, 7 + docs |
| Phase 3: Advanced | 4 weeks | Scripts 4, 8 + integration |
| Phase 4: Production | 2 weeks | Deployment + training |

**Target Completion:** End of Q2 2026 (April 30, 2026)

---

## Next Steps

### Immediate Actions (This Week)

1. **Approve Roadmap:**
   - Review and approve this plan
   - Adjust timeline if needed
   - Identify any missing requirements

2. **Set Up Test Environment:**
   - Provision test Hyper-V cluster
   - Configure test VMs with various workloads
   - Set up NinjaRMM test instance

3. **Begin Research:**
   - Start performance counter discovery
   - Map Hyper-V event log structure
   - Test basic counter queries

### Week 2 Actions

1. **Complete Research Phase:**
   - Finalize counter documentation
   - Complete event log catalog
   - Build POC scripts

2. **Plan Script 3 Development:**
   - Design data structures
   - Plan HTML report layout
   - Define field schema

3. **Start Development:**
   - Begin Performance Monitor script
   - Implement network throughput tracking
   - Test on lab environment

---

**Document Status:** Draft for Review  
**Next Update:** After Phase 1 completion  
**Owner:** Windows Automation Framework Team  
**Reviewers:** TBD
