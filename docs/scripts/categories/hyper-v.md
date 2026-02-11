# Hyper-V Virtualization Monitoring

**Complete guide to Hyper-V monitoring scripts in the WAF framework.**

---

## Overview

The WAF Hyper-V monitoring suite provides comprehensive virtualization infrastructure monitoring with 8 enterprise-grade scripts totaling 229 KB of PowerShell automation. Designed for production environments with multiple hosts, clustered configurations, and business-critical workloads.

### Suite Components

| Script | Size | Purpose | Complexity |
|--------|------|---------|------------|
| HyperVMonitor.ps1 | 31 KB | Primary monitoring and health scoring | Advanced |
| HyperVHealthCheck.ps1 | 28 KB | Comprehensive health validation | Advanced |
| HyperVPerformanceMonitor.ps1 | 31 KB | Performance metrics collection | Advanced |
| HyperVCapacityPlanner.ps1 | 29 KB | Capacity planning and forecasting | Expert |
| HyperVClusterAnalytics.ps1 | 28 KB | Cluster health and failover readiness | Expert |
| HyperVBackupComplianceMonitor.ps1 | 27 KB | Backup validation and compliance | Advanced |
| HyperVStoragePerformanceMonitor.ps1 | 32 KB | Storage subsystem performance | Advanced |
| HyperVMultiHostAggregator.ps1 | 23 KB | Multi-host data aggregation | Expert |

**Total:** 229 KB | **Average Complexity:** Advanced-Expert

---

## Quick Start

### Prerequisites

**System Requirements:**
- Windows Server 2016+ with Hyper-V role
- PowerShell 5.1 or later
- Hyper-V PowerShell module
- Administrator privileges
- NinjaOne agent (for RMM integration)

**Permissions Required:**
- Local Administrator on Hyper-V host
- Hyper-V Administrators group membership
- Read access to cluster (if applicable)

### Installation Check

```powershell
# Verify Hyper-V role installed
Get-WindowsFeature -Name Hyper-V

# Verify PowerShell module
Get-Module -ListAvailable -Name Hyper-V

# Import module
Import-Module Hyper-V

# Test basic access
Get-VM | Select-Object Name, State
```

### First Deployment

```powershell
# Navigate to scripts directory
cd C:\Scripts\waf\plaintext_scripts

# Run primary monitor (basic)
.\HyperVMonitor.ps1 -Verbose

# Review output in NinjaOne custom fields
# Check for alerts and health scores
```

---

## Script Details

### 1. HyperVMonitor.ps1 - Primary Monitoring

**Purpose:** Central monitoring script providing overall Hyper-V infrastructure health.

**Key Features:**
- VM inventory and state monitoring
- Host resource utilization
- Virtual switch health
- Integration services status
- Memory pressure detection
- CPU queue length monitoring
- Health score calculation (0-100)

**NinjaOne Custom Fields:**
```
hv_health_score          - Overall health (0-100)
hv_vm_count              - Total VMs
hv_vm_running            - Running VMs
hv_vm_stopped            - Stopped VMs
hv_host_memory_gb        - Host total memory
hv_host_memory_free_gb   - Host free memory
hv_host_cpu_percent      - Host CPU utilization
hv_virtual_switches      - Number of virtual switches
hv_integration_services  - VMs needing IC updates
```

**Usage Examples:**

```powershell
# Basic monitoring
.\HyperVMonitor.ps1

# Verbose output for troubleshooting
.\HyperVMonitor.ps1 -Verbose

# Run as scheduled task (NinjaOne)
# Schedule: Every 15 minutes
# Action: Run PowerShell script
```

**Alert Conditions:**
- Health score < 70: WARNING
- Health score < 50: CRITICAL
- Memory pressure detected: WARNING
- Integration services outdated: INFO
- VM stopped unexpectedly: CRITICAL

---

### 2. HyperVHealthCheck.ps1 - Comprehensive Validation

**Purpose:** In-depth health validation with detailed diagnostics.

**Key Features:**
- 50+ health checks across all components
- Virtual machine configuration validation
- Host configuration best practices
- Storage health assessment
- Network configuration validation
- Replication health (if configured)
- Detailed remediation recommendations

**Check Categories:**
1. **Host Configuration** (15 checks)
   - BIOS virtualization enabled
   - Hyper-V role properly configured
   - Required services running
   - Time synchronization
   - Event log errors

2. **Virtual Machine Health** (20 checks)
   - Integration services version
   - Dynamic memory configuration
   - Virtual processor allocation
   - Checkpoint age and count
   - Disk fragmentation

3. **Storage Health** (10 checks)
   - Disk space availability
   - Storage path accessibility
   - VHD/VHDX integrity
   - CSV health (if clustered)
   - Storage QoS policies

4. **Network Health** (8 checks)
   - Virtual switch configuration
   - Network adapter health
   - VLAN configuration
   - Bandwidth allocation

**Usage:**

```powershell
# Full health check
.\HyperVHealthCheck.ps1 -Comprehensive

# Quick check (critical items only)
.\HyperVHealthCheck.ps1 -QuickCheck

# Generate detailed report
.\HyperVHealthCheck.ps1 -GenerateReport -ReportPath "C:\Reports"
```

**Output Format:**
```
=== Hyper-V Health Check Report ===
Host: HV-SERVER-01
Date: 2026-02-11 20:45:00

OVERALL STATUS: HEALTHY
Passed Checks: 48/50 (96%)
Warnings: 2
Errors: 0

[PASS] BIOS Virtualization Enabled
[PASS] Hyper-V Services Running
[WARN] Integration Services Outdated (VM: SQL-PROD)
[WARN] Checkpoint Age > 7 days (VM: DEV-TEST)
[PASS] Storage Health OK
...

RECOMMENDATIONS:
1. Update integration services on SQL-PROD
2. Remove old checkpoints from DEV-TEST
```

---

### 3. HyperVPerformanceMonitor.ps1 - Performance Metrics

**Purpose:** Real-time performance monitoring with historical trending.

**Monitored Metrics:**

**Host Level:**
- CPU utilization (total and per-core)
- Memory utilization and pressure
- Network throughput (per adapter)
- Disk I/O (IOPS, latency, throughput)
- Logical processor queue length

**VM Level:**
- CPU usage percentage
- Assigned and consumed memory
- Network bytes sent/received
- Disk read/write operations
- Integration overhead

**Performance Counters:**
```
Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time
Hyper-V Dynamic Memory Balancer\Available Memory
Hyper-V Virtual Network Adapter(*)\Bytes Sent/sec
Hyper-V Virtual Storage Device(*)\Read Operations/Sec
```

**Usage:**

```powershell
# Real-time monitoring (30 second intervals)
.\HyperVPerformanceMonitor.ps1 -Interval 30 -Duration 3600

# Monitor specific VMs
.\HyperVPerformanceMonitor.ps1 -VMNames "SQL-PROD","WEB-01"

# Export metrics to CSV
.\HyperVPerformanceMonitor.ps1 -ExportCSV -Path "C:\Metrics"
```

**NinjaOne Fields:**
```
hv_perf_host_cpu         - Host CPU %
hv_perf_host_memory      - Host memory %
hv_perf_network_mbps     - Network throughput
hv_perf_disk_iops        - Disk IOPS
hv_perf_worst_vm         - VM with highest resource usage
```

---

### 4. HyperVCapacityPlanner.ps1 - Capacity Planning

**Purpose:** Capacity forecasting and resource trending for growth planning.

**Analysis Components:**

1. **Current Capacity:**
   - Total host resources (CPU, RAM, Storage)
   - Allocated resources to VMs
   - Available capacity for new VMs
   - Overcommit ratios

2. **Trend Analysis:**
   - 30/60/90 day resource trends
   - Growth rate calculations
   - Projected resource exhaustion dates
   - Seasonal pattern detection

3. **Recommendations:**
   - Optimal VM placement
   - Resource rebalancing suggestions
   - Hardware upgrade timeline
   - Cost optimization opportunities

**Usage:**

```powershell
# Generate capacity report
.\HyperVCapacityPlanner.ps1 -AnalysisPeriodDays 90

# Forecast future capacity
.\HyperVCapacityPlanner.ps1 -ForecastMonths 6

# What-if analysis (new VM)
.\HyperVCapacityPlanner.ps1 -SimulateVM -CPUs 4 -MemoryGB 16
```

**Report Example:**
```
=== Capacity Planning Report ===

Current Capacity:
  CPU: 48 cores (36 allocated, 12 available)
  Memory: 512 GB (380 GB allocated, 132 GB available)
  Storage: 10 TB (7.2 TB used, 2.8 TB available)

Trend Analysis (90 days):
  CPU Growth: +2% per month
  Memory Growth: +5% per month
  Storage Growth: +8% per month

Forecasted Exhaustion:
  CPU: 18 months
  Memory: 8 months (ACTION REQUIRED)
  Storage: 11 months

Recommendations:
  1. Plan memory upgrade within 6 months
  2. Storage expansion required in Q3 2026
  3. Consider VM right-sizing (3 VMs over-allocated)
```

---

### 5. HyperVClusterAnalytics.ps1 - Cluster Monitoring

**Purpose:** Failover cluster health and analytics (for clustered Hyper-V).

**Cluster Checks:**
- Cluster service health
- Node availability and status
- Cluster shared volume (CSV) health
- Quorum configuration
- Network redundancy
- Live migration capability
- Failover readiness score

**Usage:**

```powershell
# Monitor cluster health
.\HyperVClusterAnalytics.ps1 -ClusterName "HV-CLUSTER"

# Test failover readiness
.\HyperVClusterAnalytics.ps1 -TestFailover -VMName "CRITICAL-APP"

# Analyze cluster performance
.\HyperVClusterAnalytics.ps1 -PerformanceAnalysis -Days 30
```

**NinjaOne Fields:**
```
hv_cluster_health        - Cluster health score
hv_cluster_nodes         - Total nodes
hv_cluster_nodes_up      - Online nodes
hv_cluster_csv_count     - CSV count
hv_cluster_quorum        - Quorum status
hv_cluster_failover_ready - Failover readiness %
```

---

### 6. HyperVBackupComplianceMonitor.ps1 - Backup Validation

**Purpose:** Validate VM backup compliance and identify gaps.

**Validation Checks:**
- Backup age (last successful backup)
- Backup consistency
- Recovery point objectives (RPO) compliance
- VM backup exclusions
- Checkpoint interference with backups
- Backup storage capacity

**Usage:**

```powershell
# Check backup compliance
.\HyperVBackupComplianceMonitor.ps1 -RPOHours 24

# Generate compliance report
.\HyperVBackupComplianceMonitor.ps1 -ReportPath "C:\Reports"

# Alert on non-compliance
.\HyperVBackupComplianceMonitor.ps1 -AlertThreshold 48
```

**Alert Examples:**
```
CRITICAL: SQL-PROD not backed up in 36 hours (RPO: 24h)
WARNING: DEV-SERVER backup age: 28 hours
INFO: All production VMs compliant with backup policy
```

---

### 7. HyperVStoragePerformanceMonitor.ps1 - Storage Metrics

**Purpose:** Deep storage subsystem performance analysis.

**Monitored Metrics:**
- Disk latency (read/write)
- IOPS per disk
- Queue depth
- Throughput (MB/s)
- Storage path health
- CSV redirect overhead (if clustered)

**Performance Baselines:**
```
Excellent: < 10ms latency, > 10,000 IOPS
Good:      < 20ms latency, > 5,000 IOPS
Fair:      < 50ms latency, > 2,000 IOPS
Poor:      > 50ms latency, < 2,000 IOPS
```

**Usage:**

```powershell
# Monitor storage performance
.\HyperVStoragePerformanceMonitor.ps1 -Interval 60

# Identify bottlenecks
.\HyperVStoragePerformanceMonitor.ps1 -AnalyzeBottlenecks

# Compare against baseline
.\HyperVStoragePerformanceMonitor.ps1 -BaselineComparison
```

---

### 8. HyperVMultiHostAggregator.ps1 - Multi-Host Aggregation

**Purpose:** Aggregate metrics across multiple Hyper-V hosts.

**Aggregation Features:**
- Cross-host VM inventory
- Total infrastructure capacity
- Aggregate health scoring
- Resource distribution analysis
- Multi-host trending
- Infrastructure-wide recommendations

**Usage:**

```powershell
# Aggregate multiple hosts
$hosts = @("HV-01", "HV-02", "HV-03", "HV-04")
.\HyperVMultiHostAggregator.ps1 -Hosts $hosts

# Generate infrastructure report
.\HyperVMultiHostAggregator.ps1 -Hosts $hosts -GenerateReport

# Compare host performance
.\HyperVMultiHostAggregator.ps1 -Hosts $hosts -CompareHosts
```

**Output Example:**
```
=== Multi-Host Infrastructure Summary ===

Total Hosts: 4 (all online)
Total VMs: 87 (82 running, 5 stopped)
Total Capacity:
  CPU: 192 cores (145 allocated, 47 available)
  Memory: 2048 GB (1620 GB allocated, 428 GB available)
  Storage: 40 TB (28 TB used, 12 TB available)

Average Health Score: 89/100

Host Performance:
  HV-01: 92/100 (Excellent)
  HV-02: 88/100 (Good)
  HV-03: 90/100 (Excellent)
  HV-04: 85/100 (Good)

Recommendations:
  - Rebalance 3 VMs from HV-02 to HV-04
  - Plan storage expansion on HV-01
```

---

## Deployment Scenarios

### Scenario 1: Single Host Monitoring

**Environment:** Single Hyper-V host, 10-20 VMs

**Recommended Scripts:**
1. HyperVMonitor.ps1 (every 15 minutes)
2. HyperVHealthCheck.ps1 (daily)
3. HyperVPerformanceMonitor.ps1 (hourly)

**Setup:**
```powershell
# Configure in NinjaOne
# Script 1: HyperVMonitor.ps1
#   Schedule: Every 15 minutes
#   Timeout: 5 minutes
#
# Script 2: HyperVHealthCheck.ps1
#   Schedule: Daily at 2:00 AM
#   Timeout: 10 minutes
#
# Script 3: HyperVPerformanceMonitor.ps1
#   Schedule: Hourly
#   Timeout: 5 minutes
```

---

### Scenario 2: Clustered Environment

**Environment:** 3-4 node cluster, 50+ VMs, CSV storage

**Recommended Scripts:**
1. HyperVMonitor.ps1 (per host, every 15 minutes)
2. HyperVClusterAnalytics.ps1 (per cluster, every 30 minutes)
3. HyperVMultiHostAggregator.ps1 (once per hour)
4. HyperVBackupComplianceMonitor.ps1 (daily)

**Setup:**
```powershell
# Per-host monitoring
foreach ($node in $clusterNodes) {
    Invoke-Command -ComputerName $node -ScriptBlock {
        C:\Scripts\HyperVMonitor.ps1
    }
}

# Cluster-wide monitoring
.\HyperVClusterAnalytics.ps1 -ClusterName "PROD-CLUSTER"

# Aggregated view
.\HyperVMultiHostAggregator.ps1 -Hosts $clusterNodes
```

---

### Scenario 3: Enterprise Multi-Site

**Environment:** Multiple data centers, 20+ hosts, 500+ VMs

**Recommended Scripts:**
- All 8 scripts deployed per site
- Central aggregation server
- Custom reporting dashboard

**Architecture:**
```
Site A (10 hosts) ──┐
                    │
Site B (8 hosts) ───┼──> Central Aggregator ──> Dashboard
                    │
Site C (6 hosts) ───┘
```

---

## Troubleshooting

### Common Issues

#### Issue: "Access Denied" Errors

**Solution:**
```powershell
# Verify permissions
Get-VMHost | Select-Object Name, LogicalProcessorCount

# Add user to Hyper-V Administrators
Add-LocalGroupMember -Group "Hyper-V Administrators" -Member "DOMAIN\User"

# Restart PowerShell session
```

#### Issue: Performance Counters Not Available

**Solution:**
```powershell
# Rebuild performance counters
lodctr /R

# Restart services
Restart-Service vmms
Restart-Service vmcompute
```

#### Issue: High CPU Usage During Monitoring

**Solution:**
- Increase monitoring intervals
- Reduce number of performance counters
- Use Quick mode instead of Comprehensive

---

## Best Practices

### Monitoring Frequency

| Script | Recommended Interval | Resource Impact |
|--------|---------------------|------------------|
| HyperVMonitor | 15 minutes | Low |
| HyperVHealthCheck | Daily | Medium |
| HyperVPerformanceMonitor | 1 hour | Medium |
| HyperVCapacityPlanner | Weekly | High |
| HyperVClusterAnalytics | 30 minutes | Low |
| HyperVBackupCompliance | Daily | Low |
| HyperVStoragePerformance | 1 hour | Medium |
| HyperVMultiHostAggregator | 1 hour | Low |

### Alert Thresholds

```powershell
# Recommended alert configuration
$alertConfig = @{
    HealthScore = @{
        Warning = 70
        Critical = 50
    }
    Memory = @{
        Warning = 85  # percent
        Critical = 95
    }
    CPU = @{
        Warning = 80
        Critical = 90
    }
    Storage = @{
        Warning = 80
        Critical = 90
    }
}
```

### Performance Optimization

1. **Use Quick Checks** during business hours
2. **Schedule Comprehensive Checks** during maintenance windows
3. **Stagger Monitoring** across hosts (avoid simultaneous execution)
4. **Implement Caching** for frequently accessed data
5. **Archive Old Data** to prevent bloat

---

## Related Documentation

- **[Script Catalog](/docs/scripts/SCRIPT_CATALOG.md)** - Complete script listing
- **[Getting Started](/docs/GETTING_STARTED.md)** - Setup guide
- **[Capacity Planning Guide](/docs/guides/advanced/capacity-planning.md)** - Detailed capacity planning

---

**Last Updated:** 2026-02-11  
**Scripts:** 8  
**Total Size:** 229 KB  
**Complexity:** Advanced-Expert
