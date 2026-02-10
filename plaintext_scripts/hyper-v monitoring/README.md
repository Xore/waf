# Hyper-V Monitoring

**Folder Purpose:** Comprehensive Hyper-V virtualization infrastructure monitoring with failover cluster support

**Last Updated:** February 10, 2026

---

## Overview

This folder contains monitoring scripts for Microsoft Hyper-V virtualization infrastructure. The scripts provide real-time visibility into VM health, resource utilization, integration services status, and failover cluster state with HTML-formatted reporting and quick health assessments for dashboard integration.

**Two-Script Approach:**
1. **Hyper-V Monitor 1.ps1** - Comprehensive detailed monitoring with HTML reports (every 15 min)
2. **Hyper-V Health Check 2.ps1** - Quick health status with event log monitoring (every 5 min)

---

## Scripts

### Hyper-V Monitor 1.ps1

**Purpose:** Comprehensive Hyper-V host and VM monitoring with cluster integration

**Monitoring Capabilities:**

#### Virtual Machine Monitoring
- **State Tracking:** Running, Stopped, Saved, Paused states
- **Uptime Calculation:** Real-time uptime for running VMs
- **Health Status:** Heartbeat integration service monitoring
- **Resource Usage:** CPU and memory utilization per VM
- **Integration Services:** Status of all guest integration components
- **Replication Health:** VM replication status (if configured)
- **Checkpoint Tracking:** Number and status of VM checkpoints
- **Generation Detection:** Gen 1 vs Gen 2 VM identification

#### Integration Services Health
- Heartbeat (VM health detection)
- Time Synchronization
- Data Exchange
- VSS Backup Integration
- Guest Service Interface
- Shutdown Service
- Operating System Detection

#### Host Resource Monitoring
- Total VM inventory count
- Running/Stopped/Other VM counts
- Host CPU utilization percentage
- Host memory utilization percentage
- Virtual switch configuration
- Hyper-V version and capabilities

#### Failover Cluster Integration
- Cluster membership detection
- Cluster health status
- Node count and state
- Quorum status
- VM ownership tracking
- Cluster resource monitoring
- CSV (Cluster Shared Volume) status

**HTML Report Features:**
- Color-coded VM status table (green/yellow/red health indicators)
- Real-time uptime display
- Integration services status matrix
- Resource utilization metrics
- Cluster node status (if clustered)
- Executive summary with counts

**Execution:**
- **Frequency:** Every 15 minutes
- **Duration:** ~25 seconds
- **Timeout:** 120 seconds
- **Context:** SYSTEM (via NinjaRMM)

**NinjaRMM Fields Updated:**

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
| `hypervHostCPUPercent` | Integer | Host CPU usage |
| `hypervHostMemoryPercent` | Integer | Host memory usage |
| `hypervVMReport` | WYSIWYG | HTML VM status table |
| `hypervHealthStatus` | Text | Overall health status |
| `hypervLastScanTime` | DateTime | Last scan timestamp |

**Health Status Classification:**

- **Healthy:** All VMs running with healthy heartbeat, resources normal, cluster healthy
- **Warning:** Degraded integration services, high resource usage (>85%), cluster warnings
- **Critical:** Failed heartbeat, cluster resources offline, resource exhaustion (>95%)
- **Unknown:** Hyper-V not installed or script error

**Dependencies:**
- Windows Server with Hyper-V role
- Hyper-V PowerShell module (auto-installed)
- FailoverClusters module (if clustered)
- PowerShell 5.1+
- Administrator privileges

---

### Hyper-V Health Check 2.ps1

**Purpose:** Quick health assessment with event log monitoring and critical issue detection

**Health Check Capabilities:**

#### Node Health Checks
- **Hyper-V Service Status:** vmms service running state
- **Host Resources:** CPU and memory threshold monitoring
- **Event Logs:** Critical events from last 24 hours
- **Storage Latency:** Disk performance monitoring
- **Network Status:** Adapter and virtual switch state
- **System Stability:** Recent reboot detection

#### Failover Cluster Quick Checks
- **Cluster Service:** Service running state
- **Quorum Health:** Vote count and quorum status
- **Node Membership:** All nodes up/down status
- **CSV Status:** Cluster Shared Volume health
- **CSV Space:** Free space warnings (<20%)
- **Cluster Networks:** Network connectivity
- **Resource Groups:** Critical resource state

#### VM Quick Health Assessment
- **Heartbeat Failures:** VMs with lost communication
- **Integration Services:** Critical service failures
- **Recent Crashes:** VMs stopped unexpectedly (24h)
- **Resource Pressure:** VMs with high utilization
- **Replication Issues:** Failed or degraded replication

#### Event Log Monitoring

Monitors critical Hyper-V event logs:
- **Microsoft-Windows-Hyper-V-VMMS-Admin**
- **Microsoft-Windows-Hyper-V-Worker-Admin**
- **Microsoft-Windows-Hyper-V-Compute-Admin**
- **Microsoft-Windows-Hyper-V-Config-Admin**
- **System** (Hyper-V related)

**Critical Event IDs Tracked:**
- 18550: VM CPU threshold exceeded
- 18551: VM memory pressure detected
- 18552: Storage latency affecting VM
- 4097: Heartbeat stopped
- 14001: VMMS stopped unexpectedly
- 14010: VMMS initialization failed
- 32004: Replication failed
- 32010: Replication connection lost

#### Performance Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Host CPU | >80% | >90% |
| Host Memory | >85% | >95% |
| Storage Latency | >50ms | >100ms |
| CSV Free Space | <20% | <10% |

**Health Status Output:**

**Status Values:**
- **HEALTHY:** All checks passed, no critical issues
- **WARNING:** Non-critical issues detected, monitoring required
- **CRITICAL:** Critical issues requiring immediate attention
- **UNKNOWN:** Unable to determine health (service down, access denied)

**Status Determination Logic:**
- Critical events in last 24 hours → CRITICAL
- Cluster quorum lost → CRITICAL
- Host resources >95% → CRITICAL
- Multiple VM heartbeat failures → CRITICAL
- CSV space <10% → CRITICAL
- Warning-level events or thresholds → WARNING
- All checks passed → HEALTHY

**Execution:**
- **Frequency:** Every 5 minutes (frequent health checks)
- **Duration:** ~10 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM (via NinjaRMM)

**NinjaRMM Fields Updated:**

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervQuickHealth` | Text | HEALTHY, WARNING, CRITICAL, UNKNOWN |
| `hypervHealthSummary` | Text | Brief health summary |
| `hypervCriticalIssues` | Integer | Count of critical issues |
| `hypervWarningIssues` | Integer | Count of warning issues |
| `hypervLastHealthCheck` | DateTime | Last check timestamp |
| `hypervTopIssues` | Text | Top 5 issues list |
| `hypervEventErrors` | Integer | Critical event count (24h) |
| `hypervClusterQuorumOK` | Checkbox | Cluster has quorum |
| `hypervCSVHealthy` | Checkbox | All CSVs healthy |
| `hypervCSVLowSpace` | Integer | CSVs with <20% free |
| `hypervVMsUnhealthy` | Integer | VMs with failed heartbeat |
| `hypervReplicationIssues` | Integer | VMs with replication problems |
| `hypervStorageLatencyMS` | Integer | Average storage latency |

**Dependencies:**
- Windows Server with Hyper-V role
- Hyper-V PowerShell module
- FailoverClusters module (if clustered)
- PowerShell 5.1+
- Administrator privileges

---

## Script Comparison

| Feature | Monitor 1.ps1 | Health Check 2.ps1 |
|---------|---------------|--------------------|
| **Purpose** | Detailed monitoring | Quick health status |
| **Frequency** | Every 15 minutes | Every 5 minutes |
| **Duration** | ~25 seconds | ~10 seconds |
| **VM Details** | Full per-VM metrics | Summary counts only |
| **Event Logs** | No | Yes (24h) |
| **Storage Latency** | No | Yes |
| **HTML Report** | Yes | No |
| **Output** | WYSIWYG table | Text status |
| **Alerting** | Dashboard display | Quick status checks |
| **Use Case** | Dashboard visibility | Alert conditions |

**Recommended Usage:**
- Run **both scripts** for complete coverage
- Health Check 2 for alerting triggers
- Monitor 1 for detailed dashboard display

---

## Research & Development

### Data Sources

This implementation researched and incorporated monitoring capabilities from:

1. **Reference Implementation:**
   - [Zabbix Hyper-V Templates](https://github.com/a-schild/Zabbix-HyperV-Templates/blob/main/hyper-v-monitoring2.ps1)
   - Comprehensive VM discovery and monitoring approach
   - Multi-language support patterns
   - Performance counter integration

2. **Microsoft Documentation:**
   - [FailoverClusters Module](https://learn.microsoft.com/en-us/powershell/module/failoverclusters/)
   - Cluster cmdlets and health monitoring
   - Node status and quorum management
   - [Cluster Shared Volumes](https://learn.microsoft.com/en-us/windows-server/failover-clustering/failover-cluster-csvs)
   - CSV I/O synchronization and health

3. **Event Log Monitoring:**
   - [Hyper-V Event Logs Overview](https://virtualizationdojo.com/hyper-v/an-overview-of-hyper-v-event-logs/)
   - Critical event IDs and troubleshooting
   - [Monitoring Operational Logs](https://virtualizationdojo.com/hyper-v/monitoring-hyper-v-operational-and-admin-event-logs/)

4. **Performance Monitoring:**
   - [Hyper-V Performance Counters](https://www.nakivo.com/blog/tips-and-tools-for-microsoft-hyper-v-monitoring/)
   - Storage latency monitoring
   - CPU and memory thresholds

5. **Community Scripts:**
   - [Hyper-V Health Report](https://jdhitsolutions.com/blog/powershell/7047/my-powershell-hyper-v-health-report/)
   - HTML report generation patterns
   - Health check methodologies

### Additional Monitoring Opportunities

Future enhancements could include:

#### Performance Metrics
- Network throughput per VM
- Disk IOPS and latency per VM
- Virtual switch performance
- Queue depth monitoring
- Live migration bandwidth usage

#### Advanced Health Checks
- Guest OS patch compliance
- Backup job status integration
- Replica lag monitoring (time-based)
- Storage migration tracking
- Integration service version checks

#### Cluster Advanced Features
- Live migration history and duration
- Failover event tracking and frequency
- CSV performance metrics (IOPS, latency)
- Cluster witness status and type
- Network bandwidth by cluster network

#### Capacity Planning
- VM growth trends
- Resource overcommitment ratios
- Checkpoint space consumption
- VHD/VHDX fragmentation levels
- Snapshot chain depth

---

## Design Decisions

### Two-Script Architecture

**Choice:** Separate monitoring and health check scripts

**Rationale:**
- **Monitoring Script (15 min):** Detailed VM enumeration, HTML generation (expensive)
- **Health Check Script (5 min):** Quick status checks, event log scanning (lightweight)
- Allows frequent health checks without overhead
- Enables different alerting strategies
- Health check runs 3x per monitoring cycle

**Benefits:**
- Faster alert response (5 min vs 15 min)
- Lower resource usage (quick checks more frequent)
- Separation of concerns (detail vs. health)
- Independent troubleshooting

### HTML Reporting Format

**Choice:** HTML table with embedded CSS styling

**Rationale:**
- Native support in NinjaRMM WYSIWYG fields
- Color-coded health indicators highly visible
- Responsive to dashboard width
- No external dependencies
- Similar to proven Veeam monitor approach

### Health Color Coding

| Color | State | Meaning |
|-------|-------|--------|
| Green | Healthy | VM running with healthy heartbeat |
| Light Green | OK | VM running, heartbeat OK but apps unknown |
| Yellow | Warning | VM paused or minor issues |
| Orange | Degraded | No contact or warnings |
| Red | Critical | Lost communication or failed |
| Gray | Inactive | VM stopped or integration services disabled |

### Event Log Monitoring

**Choice:** 24-hour rolling window with specific event ID tracking

**Rationale:**
- Balance between recency and historical context
- Specific event IDs for actionable alerts
- Avoids alert fatigue from older events
- Aligns with typical SLA response times

**Event Selection Criteria:**
- Events indicating service failures
- Performance threshold breaches
- VM state changes (unexpected)
- Replication issues
- Storage problems

### Cluster Detection Logic

**Approach:** Progressive capability detection

1. Check for FailoverClusters module
2. Attempt Get-Cluster connection
3. Graceful fallback if not clustered
4. Report cluster status in separate fields

**Benefits:**
- Works on standalone and clustered hosts
- No errors on non-clustered systems
- Automatic cluster capability discovery

### Module Auto-Installation

Follows WAF coding standards for automatic module installation:

```powershell
# Hyper-V module installation pattern
- Check if module available
- Install as Windows feature if missing
- Import module with error handling
- Graceful failure with detailed logging
```

**Why:** Ensures script works on fresh Hyper-V installations without manual module setup.

---

## Troubleshooting

### Common Issues

#### "Hyper-V service (vmms) not found"

**Cause:** Hyper-V role not installed

**Resolution:**
```powershell
# Install Hyper-V role
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

#### "Failed to install or import Hyper-V PowerShell module"

**Cause:** Hyper-V PowerShell management tools not installed

**Resolution:**
```powershell
# Install Hyper-V PowerShell
Install-WindowsFeature -Name Hyper-V-PowerShell
```

#### "Cluster information shows Error"

**Cause:** Cluster service not running or permissions issue

**Resolution:**
```powershell
# Check cluster service
Get-Service clussvc

# Start if stopped
Start-Service clussvc
```

#### "No events found in event logs"

**Cause:** Event log channels not enabled or cleared

**Resolution:**
```powershell
# Enable Hyper-V operational logs
wevtutil sl Microsoft-Windows-Hyper-V-VMMS-Admin /e:true
wevtutil sl Microsoft-Windows-Hyper-V-Worker-Admin /e:true
```

#### High Execution Time (>60 seconds)

**Cause:** Large number of VMs or slow storage

**Resolution:**
- Increase timeout setting in NinjaRMM
- Consider reducing monitoring frequency
- Check host storage performance
- Use Health Check 2 for frequent checks

### Debug Mode

Enable detailed logging by modifying script:

```powershell
# Change at top of script
$LogLevel = "DEBUG"  # Shows all operations
$VerbosePreference = 'Continue'  # Shows verbose output
```

---

## Performance Considerations

### Script Performance

**Monitor 1.ps1:**
- Typical Duration: ~25 seconds
- Factors: Number of VMs (~0.5s per VM)
- Cluster queries: +2-5s

**Health Check 2.ps1:**
- Typical Duration: ~10 seconds
- Event log queries: ~3-5s
- VM summary checks: ~2-3s
- Resource checks: <1s

**Optimization Applied:**
- Parallel-safe VM enumeration
- Minimal property retrieval
- Efficient error handling
- Cached integration service queries
- Event log filtering with hash tables

### Resource Impact

**CPU:** Low (<1% on modern hardware)
**Memory:** 
- Monitor 1: ~50-100 MB during execution
- Health Check 2: ~30-50 MB during execution

**Network:** Minimal (local queries, cluster API if clustered)

---

## Integration Examples

### NinjaRMM Dashboard Widget

The `hypervVMReport` field contains styled HTML suitable for dashboard display:

```html
<!-- Automatically rendered in NinjaRMM dashboard -->
<table with color-coded VM health>
<summary section with counts>
<cluster status if applicable>
```

### Alert Conditions

Recommended NinjaRMM alert conditions:

**Critical Alerts (Health Check 2):**
- `hypervQuickHealth` = "CRITICAL"
- `hypervCriticalIssues` > 0
- `hypervClusterQuorumOK` = False
- `hypervVMsUnhealthy` > 0
- `hypervCSVLowSpace` > 0
- `hypervEventErrors` > 5 (last 24h)
- `hypervStorageLatencyMS` > 100

**Warning Alerts (Health Check 2):**
- `hypervQuickHealth` = "WARNING"
- `hypervWarningIssues` > 0
- `hypervReplicationIssues` > 0
- `hypervStorageLatencyMS` > 50

**Critical Alerts (Monitor 1):**
- `hypervHealthStatus` = "Critical"
- `hypervVMsRunning` < expected minimum
- `hypervHostCPUPercent` > 95
- `hypervHostMemoryPercent` > 95
- `hypervClusterStatus` = "Offline" (if clustered)

**Warning Alerts (Monitor 1):**
- `hypervHealthStatus` = "Warning"
- `hypervHostCPUPercent` > 85
- `hypervHostMemoryPercent` > 85
- `hypervClusterStatus` = "Degraded" (if clustered)

**Informational:**
- `hypervVMCount` changes (VM added/removed)
- `hypervClustered` changes (cluster membership change)

---

## Comparison to Other Solutions

### vs. System Center Virtual Machine Manager (SCVMM)

**Advantages:**
- No licensing costs
- Lightweight agent-based
- Integrated with existing RMM
- Custom field reporting

**Limitations:**
- No deep performance trending
- No capacity forecasting
- Limited historical data

### vs. Zabbix Hyper-V Monitoring

**Advantages:**
- Native NinjaRMM integration
- HTML-formatted reports
- Simplified deployment
- Unified monitoring platform

**Similarities:**
- VM discovery approach
- Integration services monitoring
- Health status classification

### vs. Native Hyper-V Manager

**Advantages:**
- Centralized multi-host monitoring
- Automated alerting
- Historical tracking
- Dashboard visualization

**Limitations:**
- Less granular real-time metrics
- No interactive console access
- Summary-focused vs. detail-focused

---

## Version History

### Version 1.0 (2026-02-10)

**Initial Release - Two Scripts**

**Hyper-V Monitor 1.ps1:**
- VM state and health monitoring
- Integration services status
- Host resource utilization
- Failover cluster support
- HTML report generation
- NinjaRMM field integration

**Hyper-V Health Check 2.ps1:**
- Quick health status determination
- Event log monitoring (24h)
- Storage latency tracking
- CSV health and space monitoring
- Cluster quorum validation
- Top issues reporting

**Research:**
- Based on Zabbix Hyper-V Templates patterns
- Event log monitoring from Virtualization DOJO
- CSV monitoring from Microsoft documentation
- Performance thresholds from community best practices
- Incorporated WAF coding standards
- Modeled HTML reporting after Veeam monitor

**Testing:**
- Tested on Windows Server 2022
- Verified with standalone Hyper-V host
- Validated cluster detection logic
- Confirmed module auto-installation
- Event log query performance validated

---

## Roadmap

### Planned Enhancements

**Version 1.1 (Q1 2026):**
- Performance counter integration
- Network adapter statistics
- Disk I/O metrics per VM
- Live migration tracking
- Replication lag time monitoring

**Version 1.2 (Q2 2026):**
- Historical trend analysis
- Capacity planning metrics
- VM backup integration status
- Enhanced cluster CSV monitoring
- Integration service version tracking

**Version 2.0 (Q3 2026):**
- Multi-host aggregation
- Cluster-wide reporting
- Resource pool monitoring
- Guest OS-level integration
- Predictive analytics

---

## References

### Documentation

- [Microsoft Hyper-V PowerShell Reference](https://learn.microsoft.com/en-us/powershell/module/hyper-v/)
- [Failover Clustering PowerShell](https://learn.microsoft.com/en-us/powershell/module/failoverclusters/)
- [Hyper-V Integration Services](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-hyper-v-integration-services)
- [Cluster Shared Volumes](https://learn.microsoft.com/en-us/windows-server/failover-clustering/failover-cluster-csvs)

### Community Resources

- [Zabbix Hyper-V Templates](https://github.com/a-schild/Zabbix-HyperV-Templates) - Reference implementation
- [Hyper-V Event Logs](https://virtualizationdojo.com/hyper-v/an-overview-of-hyper-v-event-logs/) - Event monitoring guide
- [Monitoring Event Logs with PowerShell](https://virtualizationdojo.com/hyper-v/monitoring-hyper-v-operational-and-admin-event-logs/) - PowerShell patterns
- [Hyper-V Performance Monitoring](https://www.nakivo.com/blog/tips-and-tools-for-microsoft-hyper-v-monitoring/) - Performance counters
- [Hyper-V Health Report](https://jdhitsolutions.com/blog/powershell/7047/my-powershell-hyper-v-health-report/) - Community script

### WAF Standards

- [CODING_STANDARDS.md](../docs/standards/CODING_STANDARDS.md)
- [OUTPUT_FORMATTING.md](../docs/standards/OUTPUT_FORMATTING.md)
- [SCRIPT_HEADER_TEMPLATE.ps1](../docs/standards/SCRIPT_HEADER_TEMPLATE.ps1)

---

## Support

For issues, questions, or enhancement requests:

1. Check troubleshooting section above
2. Review WAF documentation
3. Open issue on GitHub repository
4. Contact Windows Automation Framework team

---

**Framework Version:** 1.0  
**Document Version:** 1.1  
**Last Review:** February 10, 2026  
**Next Review:** Quarterly or when enhancements added
