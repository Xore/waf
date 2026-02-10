# Hyper-V Monitoring

**Folder Purpose:** Comprehensive Hyper-V virtualization infrastructure monitoring with failover cluster support

**Last Updated:** February 10, 2026

---

## Overview

This folder contains monitoring scripts for Microsoft Hyper-V virtualization infrastructure. The scripts provide real-time visibility into VM health, resource utilization, integration services status, and failover cluster state with HTML-formatted reporting for dashboard integration.

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

3. **PowerShell Monitoring Best Practices:**
   - [Hyper-V Performance Monitoring](https://virtualizationdojo.com/hyper-v/get-counter/)
   - Performance counter usage with Get-Counter
   - Dynamic memory monitoring patterns

### Additional Monitoring Opportunities

Future enhancements could include:

#### Performance Metrics
- Network throughput per VM
- Disk IOPS and latency
- Virtual switch performance
- Queue depth monitoring

#### Advanced Health Checks
- Guest OS patch compliance
- Backup job status integration
- Replica lag monitoring
- Storage migration tracking

#### Cluster Advanced Features
- Live migration history
- Failover event tracking
- CSV performance metrics
- Cluster witness status

#### Capacity Planning
- VM growth trends
- Resource overcommitment ratios
- Checkpoint space consumption
- VHD/VHDX fragmentation

---

## Design Decisions

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

#### High Execution Time (>60 seconds)

**Cause:** Large number of VMs or slow storage

**Resolution:**
- Increase timeout setting in NinjaRMM
- Consider reducing monitoring frequency
- Check host storage performance

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

**Typical Duration:** ~25 seconds

**Factors Affecting Duration:**
- Number of VMs (adds ~0.5s per VM)
- Cluster size (adds ~2-5s for cluster queries)
- Storage performance (VM metadata retrieval)
- Network latency (clustered environments)

**Optimization Applied:**
- Parallel-safe VM enumeration
- Minimal property retrieval
- Efficient error handling
- Cached integration service queries

### Resource Impact

**CPU:** Low (<1% on modern hardware)
**Memory:** ~50-100 MB during execution
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

**Critical Alerts:**
- `hypervHealthStatus` = "Critical"
- `hypervVMsRunning` < expected minimum
- `hypervHostCPUPercent` > 95
- `hypervHostMemoryPercent` > 95
- `hypervClusterStatus` = "Offline" (if clustered)

**Warning Alerts:**
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

**Initial Release**

**Features:**
- VM state and health monitoring
- Integration services status
- Host resource utilization
- Failover cluster support
- HTML report generation
- NinjaRMM field integration

**Research:**
- Based on Zabbix Hyper-V Templates patterns
- Incorporated WAF coding standards
- Modeled HTML reporting after Veeam monitor
- Cluster monitoring from Microsoft documentation

**Testing:**
- Tested on Windows Server 2022
- Verified with standalone Hyper-V host
- Validated cluster detection logic
- Confirmed module auto-installation

---

## Roadmap

### Planned Enhancements

**Version 1.1 (Q1 2026):**
- Performance counter integration
- Network adapter statistics
- Disk I/O metrics per VM
- Live migration tracking

**Version 1.2 (Q2 2026):**
- Historical trend analysis
- Capacity planning metrics
- VM backup integration status
- Enhanced cluster CSV monitoring

**Version 2.0 (Q3 2026):**
- Multi-host aggregation
- Cluster-wide reporting
- Resource pool monitoring
- Guest OS-level integration

---

## References

### Documentation

- [Microsoft Hyper-V PowerShell Reference](https://learn.microsoft.com/en-us/powershell/module/hyper-v/)
- [Failover Clustering PowerShell](https://learn.microsoft.com/en-us/powershell/module/failoverclusters/)
- [Hyper-V Integration Services](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-hyper-v-integration-services)

### Community Resources

- [Zabbix Hyper-V Templates](https://github.com/a-schild/Zabbix-HyperV-Templates) - Reference implementation
- [Hyper-V Performance Monitoring](https://virtualizationdojo.com/hyper-v/get-counter/) - Performance counter guide
- [TechNet Gallery](https://techcommunity.microsoft.com/) - Microsoft community scripts

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
**Document Version:** 1.0  
**Last Review:** February 10, 2026  
**Next Review:** Quarterly or when enhancements added
