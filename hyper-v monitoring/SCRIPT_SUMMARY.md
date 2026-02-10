# Hyper-V Monitoring Scripts - Quick Reference

**Last Updated:** February 10, 2026

---

## Complete Script Suite Overview

### Current Implementation (v1.0)

| # | Script Name | Status | Frequency | Duration | Purpose |
|---|-------------|--------|-----------|----------|----------|
| 1 | Hyper-V Monitor | ✅ Deployed | 15 min | ~25s | Comprehensive VM & host monitoring with HTML reports |
| 2 | Hyper-V Health Check | ✅ Deployed | 5 min | ~10s | Quick health status with event log monitoring |

### Planned Implementation (v2.0)

| # | Script Name | Status | Frequency | Duration | Purpose |
|---|-------------|--------|-----------|----------|----------|
| 3 | Hyper-V Performance Monitor | 📋 Planned | 10 min | ~20s | Detailed VM performance metrics (network, disk IOPS, latency) |
| 4 | Hyper-V Capacity Planner | 📋 Planned | Daily | ~30s | Historical trends, growth forecasting, capacity analysis |
| 5 | Hyper-V Cluster Analytics | 📋 Planned | 15 min | ~15s | Migration history, failover tracking, CSV performance |
| 6 | Hyper-V Backup & Compliance | 📋 Planned | Daily | ~45s | Guest OS patching, backup status, integration services |
| 7 | Hyper-V Storage Performance | 📋 Planned | 10 min | ~25s | Detailed storage I/O, CSV analytics, fragmentation |
| 8 | Hyper-V Multi-Host Aggregator | 📋 Planned | 30 min | ~60s | Cluster-wide aggregation and health scoring |

---

## Script Details

### Script 1: Hyper-V Monitor ✅

**Features:**
- VM state tracking (Running/Off/Saved/Paused)
- VM uptime calculation
- Heartbeat integration service monitoring
- Basic CPU and memory per VM
- Cluster membership detection
- HTML report with color-coded status

**Fields:** 15
**Best For:** Dashboard visibility, VM inventory

---

### Script 2: Hyper-V Health Check ✅

**Features:**
- Quick health status (HEALTHY/WARNING/CRITICAL)
- Event log monitoring (24h window)
- Host resource threshold checks
- CSV health and space monitoring
- Cluster quorum validation
- Top 5 issues reporting

**Fields:** 13
**Best For:** Alert triggers, rapid problem detection

---

### Script 3: Hyper-V Performance Monitor 📋

**Features:**
- Network throughput per VM (MB/s in/out)
- Disk IOPS per VM (read/write)
- Disk latency per VM (avg/max ms)
- Virtual switch statistics (packets, drops)
- Queue depth per virtual disk
- Live migration bandwidth usage
- Network adapter statistics
- Performance counter integration

**Fields:** 10-15
**Best For:** Performance troubleshooting, bottleneck identification

**Key Performance Counters:**
```
\Hyper-V Virtual Network Adapter(*)\Bytes Sent/sec
\Hyper-V Virtual Network Adapter(*)\Bytes Received/sec
\Hyper-V Virtual Storage Device(*)\Read Operations/sec
\Hyper-V Virtual Storage Device(*)\Write Operations/sec
\Hyper-V Virtual Storage Device(*)\Read Latency
\Hyper-V Virtual Storage Device(*)\Write Latency
\Hyper-V Virtual Switch(*)\Packets Dropped/sec
\Hyper-V VM Live Migration(*)\Data Rate
```

**Research Status:** Counter paths identified, VM mapping required

---

### Script 4: Hyper-V Capacity Planner 📋

**Features:**
- VM resource usage trends (7/30/90 day)
- Host resource growth patterns
- CPU/Memory/Storage overcommitment ratios
- Checkpoint space consumption analysis
- VHD/VHDX fragmentation detection
- Snapshot chain depth tracking
- Storage space forecasting (days until full)
- VM growth rate calculation
- Historical trend analysis

**Fields:** 12-15
**Best For:** Capacity planning, growth forecasting, budget planning

**Data Storage:**
- CSV files: `C:\ProgramData\WAF\HyperV\Capacity\`
- Retention: 90 days daily, 1 year weekly, 3 years monthly

**Algorithms:**
- Linear regression for growth forecasting
- Moving average for trend smoothing
- Anomaly detection for unusual patterns

**Research Status:** Storage format designed, forecasting algorithms TBD

---

### Script 5: Hyper-V Cluster Analytics 📋

**Features:**
- Live migration history (last 24h/7d/30d)
- Migration success/failure rate
- Average migration duration
- Failover event tracking
- Failover frequency per VM
- CSV IOPS per volume
- CSV latency per volume
- Cluster witness status and type
- Network bandwidth by cluster network
- Recent cluster state changes

**Fields:** 15-18
**Best For:** Cluster operations analysis, migration optimization

**Event Log IDs:**
```
Migrations:
- 20417: Live migration started
- 21002: Live migration completed
- 21008: Live migration failed

Failovers:
- 1146: Cluster resource moved
- 1230: Cluster node down
- 1069: Resource failed
```

**Research Status:** Event IDs cataloged, duration calculation TBD

---

### Script 6: Hyper-V Backup & Compliance Monitor 📋

**Features:**
- Guest OS patch compliance (Windows Update status)
- Days since last Windows Update
- Pending reboot detection in guests
- Integration service version per VM
- Integration service update availability
- Backup job status (VSS/Veeam/Windows Backup)
- Last successful backup timestamp per VM
- Days since last backup
- Replica lag time (seconds behind)
- Guest OS version detection
- Guest disk space monitoring

**Fields:** 15-20
**Best For:** Compliance reporting, backup validation, guest health

**Guest Access Requirements:**
- WinRM enabled in guests
- Guest credentials (encrypted storage)
- Firewall exceptions
- Administrator privileges in guests

**Backup Integrations:**
- Hyper-V VSS Writer
- Veeam PowerShell module
- Windows Server Backup cmdlets
- Third-party APIs (future)

**Research Status:** WinRM patterns defined, credential storage TBD

---

### Script 7: Hyper-V Storage Performance Monitor 📋

**Features:**
- Disk IOPS per VM (read/write split)
- Disk throughput per VM (MB/s)
- Disk latency per VM (read/write avg/max)
- Disk queue depth per virtual disk
- CSV I/O statistics per volume
- CSV cache hit rate
- CSV metadata operations/sec
- Storage migration tracking (active/recent)
- Storage migration progress %
- VHD/VHDX file fragmentation %
- Thin provisioning utilization
- Storage overprovisioning ratio

**Fields:** 15-18
**Best For:** Storage performance optimization, I/O bottleneck detection

**Key Metrics:**
```
CSV Cache Hit Rate: >90% good, <70% poor
Disk Latency: <10ms good, >50ms poor
Queue Depth: <8 good, >32 concerning
Fragmentation: <10% good, >20% defrag needed
```

**Research Status:** CSV counter paths identified, fragmentation detection TBD

---

### Script 8: Hyper-V Multi-Host Aggregator 📋

**Features:**
- Cluster-wide VM inventory
- Total cluster resource utilization
- VM distribution by node
- VM balance score (evenness 0-100)
- Cluster-wide capacity metrics
- Aggregate performance statistics
- Cluster health score (0-100)
- Resource pool utilization
- Cluster-wide event summary
- Multi-host correlation analysis
- Predictive failure analysis
- Capacity exhaustion forecasting

**Fields:** 12-15
**Best For:** Cluster overview, cross-node analysis, predictive maintenance

**Execution Model:**
- Runs on one cluster node (coordinator)
- Queries all cluster nodes remotely
- Aggregates data centrally
- Stores cluster-wide report

**Health Score Components:**
```
Node Health:        25%
VM Health:          25%
Storage Health:     20%
Network Health:     15%
Cluster Services:   15%
```

**Research Status:** Aggregation algorithms TBD, health scoring formula TBD

---

## Field Summary

| Script | Fields | Field Prefix |
|--------|--------|-------------|
| 1. Monitor | 15 | `hyperv*` |
| 2. Health Check | 13 | `hyperv*` |
| 3. Performance | 10-15 | `hypervPerf*` |
| 4. Capacity | 12-15 | `hypervCap*` |
| 5. Cluster Analytics | 15-18 | `hypervCluster*` |
| 6. Backup & Compliance | 15-20 | `hypervBackup*`, `hypervCompliance*` |
| 7. Storage Performance | 15-18 | `hypervStorage*` |
| 8. Multi-Host | 12-15 | `hypervCluster*` |
| **Total** | **~110** | - |

---

## Implementation Timeline

### Phase 1: Research (2 weeks)
- Performance counter discovery
- Event log ID cataloging
- POC development
- Technical validation

### Phase 2: Core Scripts (4 weeks)
- Week 3: Performance Monitor (Script 3)
- Week 4: Storage Performance (Script 7)
- Week 5: Cluster Analytics (Script 5)
- Week 6: Backup & Compliance (Script 6)

### Phase 3: Advanced Features (4 weeks)
- Week 7: Capacity Planner (Script 4)
- Week 8: Multi-Host Aggregator (Script 8)
- Week 9: Integration testing
- Week 10: Documentation

### Phase 4: Production (2 weeks)
- Week 11: Pilot deployment
- Week 12: Production rollout

**Total Duration:** 12 weeks  
**Target Completion:** End of Q2 2026

---

## Execution Frequency Matrix

```
Time    | 00:00 | 00:05 | 00:10 | 00:15 | 00:20 | 00:25 | 00:30
--------|-------|-------|-------|-------|-------|-------|-------
Script 1|       |       |       |   X   |       |       |   X
Script 2|   X   |   X   |   X   |   X   |   X   |   X   |   X
Script 3|   X   |       |   X   |       |   X   |       |   X
Script 4| Daily |       |       |       |       |       |
Script 5|       |       |       |   X   |       |       |   X
Script 6| Daily |       |       |       |       |       |
Script 7|   X   |       |   X   |       |   X   |       |   X
Script 8|       |       |       |       |       |       |   X
```

**Notes:**
- Script 2 runs most frequently (5 min) for rapid alerting
- Scripts 3 & 7 run every 10 min for performance monitoring
- Scripts 1 & 5 run every 15 min for detailed checks
- Script 8 runs every 30 min for aggregation
- Scripts 4 & 6 run daily (off-peak hours recommended)

---

## Alert Recommendations

### Critical Alerts

**From Health Check (Script 2):**
- `hypervQuickHealth` = "CRITICAL"
- `hypervCriticalIssues` > 0
- `hypervClusterQuorumOK` = False
- `hypervEventErrors` > 5

**From Performance (Script 3):**
- `hypervPerfVMHighLatency` contains VMs
- `hypervPerfVSwitchDropRate` > 5%

**From Cluster Analytics (Script 5):**
- `hypervClusterMigrationSuccessRate` < 90%
- `hypervClusterCSVMaxLatency` > 100ms

**From Backup (Script 6):**
- `hypervBackupVMsNeverBacked` > 0
- `hypervBackupOldestDays` > 14

**From Storage (Script 7):**
- `hypervStorageVMsHighLatency` contains VMs
- `hypervStorageCSVCacheHitRate` < 70%

### Warning Alerts

**From Monitor (Script 1):**
- `hypervHealthStatus` = "WARNING"
- `hypervHostCPUPercent` > 85%

**From Performance (Script 3):**
- `hypervPerfVMHighNetwork` contains VMs
- `hypervPerfQueueDepthMax` > 16

**From Capacity (Script 4):**
- `hypervCapStorageDaysRemaining` < 30
- `hypervCapVMsWithLongChains` > 0

**From Compliance (Script 6):**
- `hypervComplianceVMsNeedUpdates` > 5
- `hypervComplianceIntServicesOld` > 0

**From Multi-Host (Script 8):**
- `hypervClusterHealthScore` < 80
- `hypervClusterBalanceScore` < 60

---

## Resource Requirements

### Disk Space

**Per Host:**
- Script files: ~1 MB
- Historical data (90 days): ~50-100 MB
- Logs: ~10 MB
- **Total per host:** ~100-200 MB

### Execution Resources

| Script | CPU | Memory | Network |
|--------|-----|--------|----------|
| Monitor | <1% | 50-100 MB | Minimal |
| Health Check | <1% | 30-50 MB | Minimal |
| Performance | <2% | 60-120 MB | Minimal |
| Capacity | <1% | 40-80 MB | Minimal |
| Cluster Analytics | <2% | 50-100 MB | Low |
| Backup & Compliance | <3% | 80-150 MB | Medium |
| Storage Performance | <2% | 70-130 MB | Minimal |
| Multi-Host | <3% | 100-200 MB | Medium |

**Total Impact:** <5% CPU, <500 MB RAM peak usage

---

## Dependencies

### PowerShell Modules

**Required (All Scripts):**
- Hyper-V module (auto-installed)
- FailoverClusters module (if clustered)

**Optional:**
- Veeam.Backup.PowerShell (Script 6 - backup integration)
- SqlServer module (future - database storage)
- PSStatistics (Script 4 - forecasting)

### Windows Features

**Required:**
- Hyper-V role
- Hyper-V PowerShell management tools
- Failover Clustering (if clustered)

**Optional:**
- Windows Server Backup (Script 6)
- Storage Replica (Script 7)

### Network Requirements

**Intra-Cluster:**
- PowerShell Remoting (WSMan)
- Cluster API access
- File share access (for witness)

**External:**
- NinjaRMM agent communication
- Internet access (for module installation)

---

## Performance Optimization

### Best Practices

**1. Stagger Execution Times:**
```powershell
# Example scheduled task offsets
Script 1: :00, :15, :30, :45
Script 2: :00, :05, :10, :15, :20, :25, :30, :35, :40, :45, :50, :55
Script 3: :00, :10, :20, :30, :40, :50
Script 5: :05, :20, :35, :50
Script 7: :02, :12, :22, :32, :42, :52
Script 8: :08, :38
```

**2. Use Caching:**
```powershell
# Cache VM list for 5 minutes
if (-not $script:VMCache -or (Get-Date) -gt $script:VMCacheExpiry) {
    $script:VMCache = Get-VM
    $script:VMCacheExpiry = (Get-Date).AddMinutes(5)
}
```

**3. Parallel Processing:**
```powershell
# Process VMs in parallel (PowerShell 7+)
$VMs | ForEach-Object -Parallel {
    # VM processing
} -ThrottleLimit 10
```

**4. Selective Queries:**
```powershell
# Only query running VMs for performance
$RunningVMs = Get-VM | Where-Object { $_.State -eq 'Running' }
```

---

## Success Metrics

### Technical KPIs

- Script execution time within targets: >95%
- Script success rate: >99%
- No missed executions: >99.5%
- CPU impact: <5% average
- Memory impact: <500 MB peak
- No VM performance impact: 0 incidents

### Operational KPIs

- Alert accuracy: >90%
- False positive rate: <10%
- Mean time to detect (MTTD): <10 minutes
- Mean time to alert (MTTA): <15 minutes
- Dashboard load time: <3 seconds

### Business KPIs

- Reduced downtime: Target 20% reduction
- Faster problem resolution: Target 30% faster
- Capacity planning accuracy: >85%
- Administrator satisfaction: >85%
- System administrator time saved: >10 hours/month

---

## Documentation Links

- [Main README](./README.md) - Complete documentation
- [Monitoring Roadmap](./MONITORING_ROADMAP.md) - Detailed implementation plan
- [Development Log](./DEVELOPMENT_LOG.md) - v1.0 development history
- [WAF Coding Standards](../docs/standards/CODING_STANDARDS.md)
- [Script Header Template](../docs/standards/SCRIPT_HEADER_TEMPLATE.ps1)

---

**Document Version:** 1.0  
**Status:** Planning Phase  
**Next Review:** After Phase 1 completion  
**Maintained By:** Windows Automation Framework Team
