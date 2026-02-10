# Hyper-V Monitoring Overview

**Framework Version:** 1.0  
**Documentation Version:** 1.0  
**Last Updated:** 2026-02-11

---

## Introduction

The WAF Hyper-V Monitoring suite provides comprehensive visibility into Microsoft Hyper-V virtualization infrastructure with failover cluster support. The suite consists of 8 scripts (2 deployed, 6 planned) that monitor VM health, resource utilization, storage performance, cluster operations, and compliance status.

### Key Features

- **Real-time VM Monitoring** - State, health, uptime, and resource tracking
- **Cluster Integration** - Full failover cluster and CSV monitoring
- **HTML Reporting** - Color-coded dashboard displays
- **Event Log Analysis** - Critical event detection and alerting
- **Performance Metrics** - CPU, memory, storage, and network tracking
- **Capacity Planning** - Trend analysis and forecasting
- **Compliance Tracking** - Guest OS patching and backup validation

---

## Architecture

### Current Deployment (v1.0)

```
┌──────────────────────────────┐
│   Hyper-V Host / Cluster Node   │
│                                │
│  ┌───────────────────────┐  │
│  │  Script 1: Monitor     │  │
│  │  Every 15 min (~25s)   │  │
│  │  • VM State & Health     │  │
│  │  • Host Resources       │  │
│  │  • Cluster Status       │  │
│  │  • HTML Report          │  │
│  └───────────────────────┘  │
│                                │
│  ┌───────────────────────┐  │
│  │  Script 2: Health      │  │
│  │  Every 5 min (~10s)    │  │
│  │  • Quick Health Status  │  │
│  │  • Event Log Monitor   │  │
│  │  • Storage Latency     │  │
│  │  • Alert Triggers      │  │
│  └───────────────────────┘  │
│                                │
│         │                     │
│         ↓ NinjaRMM Agent      │
│         │                     │
└─────────┬────────────────────┘
         │
         │ Custom Fields (28 total)
         │ • hypervInstalled
         │ • hypervVMCount
         │ • hypervHealthStatus
         │ • hypervQuickHealth
         │ • hypervVMReport (HTML)
         │ ...
         ↓
┌─────────┴────────────────────┐
│    NinjaRMM Dashboard         │
│  • VM Status Table (HTML)    │
│  • Health Indicators         │
│  • Alert Conditions          │
│  • Resource Metrics          │
└──────────────────────────────┘
```

### Planned Architecture (v2.0)

**8-Script Suite:**
1. **Monitor** - Core VM and host monitoring
2. **Health Check** - Rapid health assessment
3. **Performance Monitor** - Network, disk, I/O metrics
4. **Capacity Planner** - Trends and forecasting
5. **Cluster Analytics** - Migration and failover tracking
6. **Backup & Compliance** - Guest OS and backup validation
7. **Storage Performance** - Detailed storage I/O analysis
8. **Multi-Host Aggregator** - Cluster-wide aggregation

**Total Custom Fields:** ~110
**Total Data Coverage:** Complete virtualization infrastructure

---

## Script Suite

### Deployed Scripts (v1.0)

#### Script 1: Hyper-V Monitor ✅

**Purpose:** Comprehensive VM and host monitoring with HTML reporting

**Frequency:** Every 15 minutes  
**Duration:** ~25 seconds  
**Custom Fields:** 14

**Key Capabilities:**
- VM state tracking (Running/Stopped/Saved/Paused)
- VM uptime calculation and display
- Heartbeat integration service monitoring
- Basic CPU and memory per VM
- Integration services status (7 services)
- Host resource utilization (CPU, memory)
- Cluster detection and status
- HTML report with color-coded health indicators

**Output:** HTML table with green/yellow/red status indicators

**Use Cases:**
- Dashboard visibility
- VM inventory management
- Quick health overview
- Resource utilization tracking

---

#### Script 2: Hyper-V Health Check ✅

**Purpose:** Quick health status with event log monitoring

**Frequency:** Every 5 minutes  
**Duration:** ~10 seconds  
**Custom Fields:** 14

**Key Capabilities:**
- Quick health status (HEALTHY/WARNING/CRITICAL/UNKNOWN)
- Event log monitoring (24-hour window)
- Host resource threshold checks (CPU >80%, Memory >85%)
- Storage latency monitoring (<10ms good, >100ms critical)
- CSV health and free space monitoring
- Cluster quorum validation
- Top 5 issues reporting
- Critical event detection (specific event IDs)

**Output:** Health status text with issue counts

**Use Cases:**
- Alert trigger conditions
- Rapid problem detection
- Event log correlation
- Critical issue escalation

---

### Planned Scripts (v2.0)

#### Script 3: Performance Monitor 📋

**Frequency:** Every 10 minutes (~20s)

**Capabilities:**
- Network throughput per VM (MB/s in/out)
- Disk IOPS per VM (read/write split)
- Disk latency per VM (avg/max)
- Virtual switch statistics
- Queue depth monitoring
- Live migration bandwidth

---

#### Script 4: Capacity Planner 📋

**Frequency:** Daily (~30s)

**Capabilities:**
- Resource usage trends (7/30/90 days)
- Growth forecasting
- Overcommitment ratios
- Checkpoint space analysis
- Storage forecasting (days until full)

---

#### Script 5: Cluster Analytics 📋

**Frequency:** Every 15 minutes (~15s)

**Capabilities:**
- Live migration history and success rate
- Failover event tracking
- CSV performance metrics
- Cluster witness status
- Network bandwidth by cluster network

---

#### Script 6: Backup & Compliance 📋

**Frequency:** Daily (~45s)

**Capabilities:**
- Guest OS patch compliance
- Integration service version tracking
- Backup job status (VSS/Veeam)
- Last backup timestamp per VM
- Pending reboot detection

---

#### Script 7: Storage Performance 📋

**Frequency:** Every 10 minutes (~25s)

**Capabilities:**
- Detailed disk IOPS and throughput
- CSV I/O statistics
- CSV cache hit rate
- Storage migration tracking
- VHD/VHDX fragmentation detection

---

#### Script 8: Multi-Host Aggregator 📋

**Frequency:** Every 30 minutes (~60s)

**Capabilities:**
- Cluster-wide VM inventory
- Total cluster resource utilization
- VM balance scoring
- Cluster health score (0-100)
- Predictive failure analysis

---

## Custom Fields Reference

### Script 1: Monitor (14 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervInstalled` | Checkbox | Hyper-V role installed |
| `hypervVersion` | Text | Hyper-V version string |
| `hypervVMCount` | Integer | Total VMs configured |
| `hypervVMsRunning` | Integer | Running VMs |
| `hypervVMsStopped` | Integer | Stopped VMs |
| `hypervVMsOther` | Integer | Saved/Paused VMs |
| `hypervClustered` | Checkbox | Is cluster member |
| `hypervClusterName` | Text | Cluster name |
| `hypervClusterNodeCount` | Integer | Total cluster nodes |
| `hypervClusterStatus` | Text | Cluster health status |
| `hypervHostCPUPercent` | Integer | Host CPU usage % |
| `hypervHostMemoryPercent` | Integer | Host memory usage % |
| `hypervVMReport` | WYSIWYG | HTML VM status table |
| `hypervHealthStatus` | Text | Overall health status |

### Script 2: Health Check (14 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervQuickHealth` | Text | HEALTHY/WARNING/CRITICAL/UNKNOWN |
| `hypervHealthSummary` | Text | Brief health summary |
| `hypervCriticalIssues` | Integer | Count of critical issues |
| `hypervWarningIssues` | Integer | Count of warning issues |
| `hypervLastHealthCheck` | DateTime | Last check timestamp |
| `hypervTopIssues` | Text | Top 5 issues list |
| `hypervEventErrors` | Integer | Critical events (24h) |
| `hypervClusterQuorumOK` | Checkbox | Cluster has quorum |
| `hypervCSVHealthy` | Checkbox | All CSVs healthy |
| `hypervCSVLowSpace` | Integer | CSVs with <20% free |
| `hypervVMsUnhealthy` | Integer | VMs with failed heartbeat |
| `hypervReplicationIssues` | Integer | Replication problems |
| `hypervStorageLatencyMS` | Integer | Avg storage latency |
| `hypervLastScanTime` | DateTime | Last scan timestamp |

**Total Current Fields:** 28 (some overlap in timestamps)

---

## Health Status Classification

### Script 1: Monitor

**HEALTHY:**
- All VMs running with healthy heartbeat
- Resources <85% (CPU and memory)
- Cluster healthy (if clustered)
- No integration service failures

**WARNING:**
- Degraded integration services
- Resources 85-95%
- Cluster warnings
- Some VMs in saved/paused state

**CRITICAL:**
- Failed VM heartbeat
- Resources >95%
- Cluster resources offline
- Critical integration service failures

**UNKNOWN:**
- Hyper-V not installed
- Script execution error
- Permissions issue

### Script 2: Health Check

**HEALTHY:**
- All checks passed
- No critical events (24h)
- Resources <80%
- Storage latency <50ms
- Cluster quorum OK

**WARNING:**
- Resources 80-90%
- Storage latency 50-100ms
- Warning-level events
- CSV free space 10-20%

**CRITICAL:**
- Critical events in last 24h
- Cluster quorum lost
- Resources >90%
- Storage latency >100ms
- Multiple heartbeat failures
- CSV space <10%

---

## Alert Recommendations

### Critical Alerts

**Immediate Response Required:**

```yaml
# Script 2 - Health Check
- hypervQuickHealth: "CRITICAL"
- hypervCriticalIssues: > 0
- hypervClusterQuorumOK: False
- hypervVMsUnhealthy: > 0
- hypervCSVLowSpace: > 0 (< 10% free)
- hypervEventErrors: > 5 (24h)
- hypervStorageLatencyMS: > 100

# Script 1 - Monitor
- hypervHealthStatus: "Critical"
- hypervVMsRunning: < expected minimum
- hypervHostCPUPercent: > 95
- hypervHostMemoryPercent: > 95
- hypervClusterStatus: "Offline"
```

### Warning Alerts

**Investigation Recommended:**

```yaml
# Script 2 - Health Check
- hypervQuickHealth: "WARNING"
- hypervWarningIssues: > 0
- hypervReplicationIssues: > 0
- hypervStorageLatencyMS: > 50

# Script 1 - Monitor
- hypervHealthStatus: "Warning"
- hypervHostCPUPercent: > 85
- hypervHostMemoryPercent: > 85
- hypervClusterStatus: "Degraded"
```

### Informational

**Tracking and Trending:**

```yaml
- hypervVMCount: Changes (VM added/removed)
- hypervClustered: Changes (membership)
- hypervClusterNodeCount: Changes
```

---

## Performance Characteristics

### Execution Times

| Script | Typical | Max | Factors |
|--------|---------|-----|----------|
| Monitor | 25s | 60s | VM count (~0.5s per VM) |
| Health Check | 10s | 30s | Event log volume |

### Resource Impact

**CPU:** <1% average, brief spikes during execution  
**Memory:**
- Monitor: 50-100 MB during execution
- Health Check: 30-50 MB during execution

**Network:** Minimal (local queries, cluster API if clustered)

**Storage:** No persistent storage, logs only

### Optimization

**Applied Techniques:**
- Parallel-safe VM enumeration
- Minimal property retrieval
- Efficient error handling
- Cached integration service queries
- Event log filtering with hash tables
- Progressive capability detection

---

## Dependencies

### Required

**Windows Server Components:**
- Hyper-V role installed
- Hyper-V PowerShell module (auto-installed)
- PowerShell 5.1 or later
- Administrator privileges

**For Clustered Environments:**
- Failover Clustering feature
- FailoverClusters PowerShell module
- Cluster service running

**RMM Integration:**
- NinjaRMM agent installed
- Custom fields created (28 fields)
- Script scheduled in NinjaRMM

### Optional

**Future Scripts:**
- Veeam.Backup.PowerShell (Script 6)
- PSStatistics (Script 4)
- WinRM access to guests (Script 6)

---

## Comparison to Alternatives

### vs. System Center VMM

| Feature | WAF Hyper-V | SCVMM |
|---------|-------------|-------|
| **Cost** | Free | Licensing required |
| **Deployment** | Agent-based (RMM) | Dedicated infrastructure |
| **Integration** | NinjaRMM | System Center suite |
| **Complexity** | Low | High |
| **Trending** | Limited | Extensive |
| **Forecasting** | Planned (v2.0) | Built-in |

**Best For WAF:** Cost-conscious, RMM-centric environments

### vs. Zabbix Hyper-V

| Feature | WAF Hyper-V | Zabbix |
|---------|-------------|--------|
| **Platform** | NinjaRMM | Zabbix Server |
| **Reporting** | HTML in RMM | Zabbix dashboards |
| **Deployment** | RMM automation | Agent + server |
| **Customization** | PowerShell | Zabbix templates |
| **Learning Curve** | Low | Medium |

**Best For WAF:** Existing NinjaRMM infrastructure

### vs. Native Hyper-V Manager

| Feature | WAF Hyper-V | Hyper-V Manager |
|---------|-------------|------------------|
| **Multi-Host** | Planned (v2.0) | Manual switching |
| **Alerting** | Automated | None |
| **Historical** | RMM tracking | None |
| **Dashboard** | Centralized | Per-host |
| **Automation** | Full | Manual only |

**Best For WAF:** Centralized monitoring and alerting

---

## Roadmap

### Q1 2026 ✅
- **v1.0 Released:** Monitor and Health Check scripts
- Tested on Windows Server 2022
- Cluster support validated
- Production deployment ready

### Q2 2026 🚧
- **v1.1:** Performance Monitor (Script 3)
- **v1.2:** Storage Performance (Script 7)
- **v1.3:** Cluster Analytics (Script 5)
- Production testing and refinement

### Q3 2026 📋
- **v2.0:** Backup & Compliance (Script 6)
- **v2.1:** Capacity Planner (Script 4)
- **v2.2:** Multi-Host Aggregator (Script 8)
- Complete suite deployment

### Q4 2026 📋
- Advanced features and optimizations
- Machine learning integration
- Predictive analytics
- Enhanced reporting

---

## Next Steps

1. **Review** [Deployment Guide](./deployment-guide.md)
2. **Configure** Custom fields in NinjaRMM
3. **Deploy** Scripts 1 and 2 to pilot hosts
4. **Monitor** Dashboard and alerts
5. **Optimize** Based on environment feedback

---

**Document Status:** Current  
**Maintained By:** WAF Team  
**Next Review:** After v1.1 release
