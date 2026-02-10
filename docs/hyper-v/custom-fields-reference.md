# Hyper-V Monitoring Custom Fields Reference

**Version:** 1.0  
**Last Updated:** 2026-02-11  
**Total Fields:** 28 (Current) | 109 (Planned)

---

## Overview

This document provides a complete reference for all NinjaRMM custom fields used by the Hyper-V monitoring suite. Fields are organized by script and include data types, update frequencies, and usage examples.

---

## Field Naming Convention

**Pattern:** `hypervCategoryName`

**Examples:**
- `hypervVMCount` - General VM information
- `hypervClusterStatus` - Cluster-specific data
- `hypervPerfCPU` - Performance metrics
- `hypervBackupLastRun` - Backup information

**Rules:**
- Prefix: `hyperv` (all lowercase)
- Category: Optional middle identifier
- Name: Descriptive suffix in camelCase
- No underscores or hyphens

---

## Current Fields (v1.0) - 28 Fields

### Script 1: Hyper-V Monitor (14 fields)

#### Core Installation

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervInstalled` | Checkbox | Hyper-V role installed | `True` |
| `hypervVersion` | Text | Hyper-V version string | `10.0.20348.1` |

**Update Frequency:** Every 15 minutes  
**Data Source:** `Get-WindowsFeature Hyper-V`

#### VM Inventory

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervVMCount` | Integer | Total VMs configured | `15` |
| `hypervVMsRunning` | Integer | Currently running VMs | `12` |
| `hypervVMsStopped` | Integer | Stopped VMs | `2` |
| `hypervVMsOther` | Integer | Saved/Paused VMs | `1` |

**Update Frequency:** Every 15 minutes  
**Data Source:** `Get-VM | Group-Object State`

**Calculation:**
```powershell
$VMs = Get-VM
$hypervVMCount = $VMs.Count
$hypervVMsRunning = ($VMs | Where-Object State -eq 'Running').Count
$hypervVMsStopped = ($VMs | Where-Object State -eq 'Off').Count
$hypervVMsOther = ($VMs | Where-Object State -in 'Saved','Paused').Count
```

#### Cluster Information

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervClustered` | Checkbox | Is cluster member | `True` |
| `hypervClusterName` | Text | Cluster name | `HVCLUSTER01` |
| `hypervClusterNodeCount` | Integer | Total cluster nodes | `3` |
| `hypervClusterStatus` | Text | Cluster health | `Online` / `Degraded` / `Offline` |

**Update Frequency:** Every 15 minutes  
**Data Source:** `Get-Cluster`, `Get-ClusterNode`

**Possible Values for hypervClusterStatus:**
- `Online` - All nodes up, quorum healthy
- `Degraded` - Some nodes down or warnings
- `Offline` - Cluster unavailable
- `N/A` - Not clustered

#### Host Resources

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervHostCPUPercent` | Integer | Host CPU usage % | `65` |
| `hypervHostMemoryPercent` | Integer | Host memory usage % | `72` |

**Update Frequency:** Every 15 minutes  
**Data Source:** `Get-Counter` for CPU, `Get-CimInstance Win32_OperatingSystem` for memory

**Calculation:**
```powershell
# CPU percentage
$CPU = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2
$hypervHostCPUPercent = [math]::Round($CPU.CounterSamples.CookedValue)

# Memory percentage
$OS = Get-CimInstance Win32_OperatingSystem
$MemUsedGB = ($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / 1MB
$hypervHostMemoryPercent = [math]::Round(($MemUsedGB / ($OS.TotalVisibleMemorySize / 1MB)) * 100)
```

#### HTML Report

| Field Name | Type | Description | Update Frequency |
|------------|------|-------------|------------------|
| `hypervVMReport` | WYSIWYG | HTML VM status table | Every 15 minutes |

**Content:** Color-coded table with VM status, health, uptime, and resource usage

**HTML Structure:**
```html
<table style="border-collapse: collapse; width: 100%;">
  <thead>
    <tr style="background-color: #0078d4; color: white;">
      <th>VM Name</th>
      <th>State</th>
      <th>Health</th>
      <th>CPU %</th>
      <th>Memory GB</th>
    </tr>
  </thead>
  <tbody>
    <tr style="background-color: #d4edda;">  <!-- Green for healthy -->
      <td>DC01</td>
      <td>Running</td>
      <td>Healthy</td>
      <td>15</td>
      <td>4.2</td>
    </tr>
  </tbody>
</table>
```

**Color Coding:**
- Green (`#d4edda`) - Running, healthy
- Yellow (`#fff3cd`) - Running, warnings
- Red (`#f8d7da`) - Stopped or critical
- Gray (`#e2e3e5`) - Saved/Paused

#### Overall Status

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervHealthStatus` | Text | Overall health | `Healthy` / `Warning` / `Critical` / `Unknown` |

**Update Frequency:** Every 15 minutes

**Status Logic:**
```powershell
if ($CriticalIssues -gt 0 -or $HostCPU -gt 95 -or $HostMemory -gt 95) {
    $hypervHealthStatus = "Critical"
} elseif ($WarningIssues -gt 0 -or $HostCPU -gt 85 -or $HostMemory -gt 85) {
    $hypervHealthStatus = "Warning"
} elseif ($hypervInstalled) {
    $hypervHealthStatus = "Healthy"
} else {
    $hypervHealthStatus = "Unknown"
}
```

---

### Script 2: Hyper-V Health Check (14 fields)

#### Quick Health Status

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervQuickHealth` | Text | Health status | `HEALTHY` / `WARNING` / `CRITICAL` / `UNKNOWN` |
| `hypervHealthSummary` | Text | Brief summary | "All systems normal" |
| `hypervCriticalIssues` | Integer | Critical issue count | `0` |
| `hypervWarningIssues` | Integer | Warning issue count | `2` |

**Update Frequency:** Every 5 minutes  
**Purpose:** Rapid health assessment for alerting

**Status Determination:**
- `HEALTHY` - All checks passed
- `WARNING` - Non-critical issues detected
- `CRITICAL` - Critical issues requiring immediate attention
- `UNKNOWN` - Unable to determine health

#### Issue Tracking

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervTopIssues` | Text | Top 5 issues | "CSV1: Low space (15%)\nVM-SQL: High CPU\n..." |
| `hypervEventErrors` | Integer | Critical events (24h) | `3` |

**Update Frequency:** Every 5 minutes  
**Data Source:** Event logs (last 24 hours)

#### Cluster Health Checks

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervClusterQuorumOK` | Checkbox | Cluster has quorum | `True` |
| `hypervCSVHealthy` | Checkbox | All CSVs healthy | `True` |
| `hypervCSVLowSpace` | Integer | CSVs with <20% free | `1` |

**Update Frequency:** Every 5 minutes  
**Critical Alert Triggers:** `hypervClusterQuorumOK = False`, `hypervCSVLowSpace > 0`

#### VM Health Metrics

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervVMsUnhealthy` | Integer | VMs with failed heartbeat | `0` |
| `hypervReplicationIssues` | Integer | VMs with replication problems | `0` |

**Update Frequency:** Every 5 minutes

#### Storage Performance

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervStorageLatencyMS` | Integer | Average storage latency (ms) | `12` |

**Update Frequency:** Every 5 minutes  
**Thresholds:** <10ms good, 10-50ms acceptable, 50-100ms warning, >100ms critical

#### Timestamps

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `hypervLastHealthCheck` | DateTime | Last health check | `2026-02-11 00:20:00` |
| `hypervLastScanTime` | DateTime | Last full scan | `2026-02-11 00:15:00` |

**Update Frequency:** Every script execution

---

## Planned Fields (v2.0) - 81 Additional Fields

### Script 3: Performance Monitor (12 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervPerfVMHighCPU` | Text | VMs with high CPU (>80%) |
| `hypervPerfVMHighMemory` | Text | VMs with high memory (>85%) |
| `hypervPerfVMHighNetwork` | Text | VMs with high network utilization |
| `hypervPerfVMHighLatency` | Text | VMs with high disk latency |
| `hypervPerfNetworkMbpsTotal` | Integer | Total network throughput (Mbps) |
| `hypervPerfDiskIOPSTotal` | Integer | Total disk IOPS |
| `hypervPerfQueueDepthAvg` | Integer | Average queue depth |
| `hypervPerfQueueDepthMax` | Integer | Maximum queue depth |
| `hypervPerfVSwitchDropRate` | Float | Virtual switch packet drop rate % |
| `hypervPerfLiveMigrationActive` | Integer | Active live migrations |
| `hypervPerfLiveMigrationBandwidth` | Integer | Migration bandwidth (Mbps) |
| `hypervPerfLastUpdate` | DateTime | Last performance update |

**Update Frequency:** Every 10 minutes

---

### Script 4: Capacity Planner (15 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervCapCPUOvercommit` | Float | CPU overcommitment ratio |
| `hypervCapMemoryOvercommit` | Float | Memory overcommitment ratio |
| `hypervCapStorageUsedGB` | Integer | Total storage used (GB) |
| `hypervCapStorageFreeGB` | Integer | Total storage free (GB) |
| `hypervCapStorageDaysRemaining` | Integer | Days until storage full |
| `hypervCapVMGrowthRate` | Float | VM count growth rate (per month) |
| `hypervCapCPUTrend7d` | Float | 7-day CPU usage trend |
| `hypervCapMemoryTrend7d` | Float | 7-day memory usage trend |
| `hypervCapCheckpointSpaceGB` | Integer | Space used by checkpoints |
| `hypervCapVMsWithCheckpoints` | Integer | VMs with active checkpoints |
| `hypervCapVMsWithLongChains` | Integer | VMs with checkpoint chains >3 |
| `hypervCapFragmentationPercent` | Integer | Average VHD fragmentation % |
| `hypervCapRecommendedAction` | Text | Capacity recommendation |
| `hypervCapForecastReport` | WYSIWYG | HTML forecast report |
| `hypervCapLastUpdate` | DateTime | Last capacity analysis |

**Update Frequency:** Daily

---

### Script 5: Cluster Analytics (17 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervClusterMigrations24h` | Integer | Migrations in last 24 hours |
| `hypervClusterMigrationsSuccess` | Integer | Successful migrations |
| `hypervClusterMigrationsFailed` | Integer | Failed migrations |
| `hypervClusterMigrationSuccessRate` | Float | Success rate percentage |
| `hypervClusterMigrationAvgDuration` | Integer | Average migration time (seconds) |
| `hypervClusterFailovers24h` | Integer | Failovers in last 24 hours |
| `hypervClusterFailoverReason` | Text | Last failover reason |
| `hypervClusterCSVIOPS` | Integer | Cluster Shared Volume IOPS |
| `hypervClusterCSVLatencyMS` | Integer | CSV average latency (ms) |
| `hypervClusterCSVMaxLatency` | Integer | CSV max latency (ms) |
| `hypervClusterWitnessType` | Text | Witness type (Cloud/FileShare/Disk) |
| `hypervClusterWitnessStatus` | Text | Witness health status |
| `hypervClusterNetworkHealth` | Text | Cluster network status |
| `hypervClusterResourceGroups` | Integer | Total resource groups |
| `hypervClusterResourcesOnline` | Integer | Online resources |
| `hypervClusterResourcesOffline` | Integer | Offline resources |
| `hypervClusterLastUpdate` | DateTime | Last analytics update |

**Update Frequency:** Every 15 minutes

---

### Script 6: Backup & Compliance (18 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervBackupVMsWithBackup` | Integer | VMs with configured backup |
| `hypervBackupVMsNeverBacked` | Integer | VMs never backed up |
| `hypervBackupLastSuccess` | DateTime | Most recent successful backup |
| `hypervBackupOldestDays` | Integer | Oldest backup age (days) |
| `hypervBackupFailures24h` | Integer | Failed backups (24h) |
| `hypervBackupVSSStatus` | Text | VSS writer status |
| `hypervComplianceVMsNeedUpdates` | Integer | VMs needing Windows updates |
| `hypervComplianceVMsRebootPending` | Integer | VMs with pending reboot |
| `hypervComplianceOldestPatchDays` | Integer | Oldest missing patch (days) |
| `hypervComplianceIntServicesOK` | Integer | VMs with current int services |
| `hypervComplianceIntServicesOld` | Integer | VMs with outdated int services |
| `hypervComplianceGuestVersions` | Text | Guest OS versions summary |
| `hypervComplianceVMsLowDisk` | Integer | VMs with low disk space |
| `hypervComplianceCriticalPatches` | Integer | Total critical patches needed |
| `hypervComplianceSecurityScore` | Integer | Overall security score (0-100) |
| `hypervComplianceReport` | WYSIWYG | HTML compliance report |
| `hypervComplianceStatus` | Text | Overall compliance status |
| `hypervComplianceLastUpdate` | DateTime | Last compliance check |

**Update Frequency:** Daily

---

### Script 7: Storage Performance (15 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervStorageReadIOPS` | Integer | Total read IOPS |
| `hypervStorageWriteIOPS` | Integer | Total write IOPS |
| `hypervStorageReadMBps` | Integer | Read throughput (MB/s) |
| `hypervStorageWriteMBps` | Integer | Write throughput (MB/s) |
| `hypervStorageReadLatencyMS` | Integer | Average read latency (ms) |
| `hypervStorageWriteLatencyMS` | Integer | Average write latency (ms) |
| `hypervStorageQueueDepthAvg` | Integer | Average queue depth |
| `hypervStorageCSVCacheHitRate` | Float | CSV cache hit rate % |
| `hypervStorageCSVMetadataOps` | Integer | CSV metadata operations/sec |
| `hypervStorageVMsHighLatency` | Text | VMs with high storage latency |
| `hypervStorageMigrationActive` | Integer | Active storage migrations |
| `hypervStorageMigrationProgress` | Integer | Migration progress % |
| `hypervStorageFragmentation` | Integer | Average fragmentation % |
| `hypervStorageOverprovisionRatio` | Float | Thin provisioning ratio |
| `hypervStorageLastUpdate` | DateTime | Last storage update |

**Update Frequency:** Every 10 minutes

---

### Script 8: Multi-Host Aggregator (14 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervClusterVMsTotal` | Integer | Total VMs across cluster |
| `hypervClusterVMsRunning` | Integer | Running VMs cluster-wide |
| `hypervClusterCPUAvgPercent` | Integer | Cluster average CPU % |
| `hypervClusterMemoryAvgPercent` | Integer | Cluster average memory % |
| `hypervClusterVMDistribution` | Text | VM count per node |
| `hypervClusterBalanceScore` | Integer | VM balance score (0-100) |
| `hypervClusterCapacityGB` | Integer | Total cluster capacity (GB) |
| `hypervClusterUsedGB` | Integer | Total cluster used (GB) |
| `hypervClusterFreeGB` | Integer | Total cluster free (GB) |
| `hypervClusterHealthScore` | Integer | Overall cluster health (0-100) |
| `hypervClusterPredictiveIssues` | Integer | Predicted issues count |
| `hypervClusterRecommendations` | Text | Top recommendations |
| `hypervClusterAggregateReport` | WYSIWYG | HTML cluster report |
| `hypervClusterLastAggregation` | DateTime | Last aggregation time |

**Update Frequency:** Every 30 minutes

---

## Field Type Reference

### Data Types in NinjaRMM

| Type | Description | Example | Notes |
|------|-------------|---------|-------|
| **Checkbox** | Boolean value | `True` / `False` | Shows as checked/unchecked |
| **Text** | String value | `"HEALTHY"` | Max ~64KB |
| **Integer** | Whole number | `15` | -2,147,483,648 to 2,147,483,647 |
| **Float** | Decimal number | `3.14` | For percentages, ratios |
| **DateTime** | Timestamp | `2026-02-11 00:20:00` | ISO 8601 format preferred |
| **WYSIWYG** | HTML content | `<table>...</table>` | Renders HTML in dashboard |

### Type Selection Guidelines

**Use Checkbox when:**
- Binary state (yes/no, true/false)
- Visual indicator needed
- Example: `hypervInstalled`, `hypervClusterQuorumOK`

**Use Text when:**
- Status values with multiple states
- Names, descriptions, lists
- Example: `hypervHealthStatus`, `hypervClusterName`

**Use Integer when:**
- Counts, quantities
- Whole percentages
- Example: `hypervVMCount`, `hypervHostCPUPercent`

**Use Float when:**
- Ratios, precise percentages
- Performance metrics
- Example: `hypervCapCPUOvercommit`, `hypervStorageCSVCacheHitRate`

**Use DateTime when:**
- Timestamps needed for trending
- Age calculations required
- Example: `hypervLastScanTime`, `hypervBackupLastSuccess`

**Use WYSIWYG when:**
- Rich formatting needed
- Tables or structured data
- Color-coded displays
- Example: `hypervVMReport`, `hypervCapForecastReport`

---

## Alert Configuration Examples

### Critical Alerts

```yaml
# Alert 1: Critical Health Status
Field: hypervQuickHealth
Condition: Equals "CRITICAL"
Severity: Critical
Notification: Immediate

# Alert 2: Cluster Quorum Lost
Field: hypervClusterQuorumOK
Condition: Equals False
Severity: Critical
Notification: Immediate + SMS

# Alert 3: VMs Unhealthy
Field: hypervVMsUnhealthy
Condition: Greater than 0
Severity: Critical
Notification: Within 5 minutes

# Alert 4: Host Resources Critical
Field: hypervHostCPUPercent OR hypervHostMemoryPercent
Condition: Greater than 95
Severity: Critical
Notification: Within 10 minutes
```

### Warning Alerts

```yaml
# Alert 5: Warning Health Status
Field: hypervQuickHealth
Condition: Equals "WARNING"
Severity: Warning
Notification: Within 15 minutes

# Alert 6: CSV Low Space
Field: hypervCSVLowSpace
Condition: Greater than 0
Severity: Warning
Notification: Within 1 hour

# Alert 7: High Storage Latency
Field: hypervStorageLatencyMS
Condition: Greater than 50
Severity: Warning
Notification: Within 30 minutes
```

---

## Dashboard Widget Configuration

### Recommended Widget: VM Status Overview

**Primary Display:**
- Field: `hypervVMReport` (WYSIWYG)
- Width: Full
- Height: Auto

**Status Indicators:**
- Field: `hypervQuickHealth` (Text with color coding)
- Field: `hypervHealthStatus` (Text)

**Key Metrics:**
- Field: `hypervVMsRunning` / `hypervVMCount`
- Field: `hypervHostCPUPercent`
- Field: `hypervHostMemoryPercent`

**Cluster Status (if applicable):**
- Field: `hypervClusterStatus`
- Field: `hypervClusterQuorumOK`

---

## Field Update Patterns

### Standard Pattern

```powershell
# Using Set-NinjaField function
Set-NinjaField -FieldName "hypervVMCount" -Value $VMCount
Set-NinjaField -FieldName "hypervHealthStatus" -Value $HealthStatus
Set-NinjaField -FieldName "hypervLastScanTime" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
```

### Error Handling

```powershell
try {
    $VMCount = (Get-VM).Count
    Set-NinjaField -FieldName "hypervVMCount" -Value $VMCount
} catch {
    Write-Log "Failed to get VM count: $_" -Level ERROR
    Set-NinjaField -FieldName "hypervHealthStatus" -Value "Unknown"
}
```

### Null/Empty Handling

```powershell
# Handle null values
$Value = if ($null -eq $Result) { 0 } else { $Result }
Set-NinjaField -FieldName "hypervVMCount" -Value $Value

# Handle empty strings
$Status = if ([string]::IsNullOrWhiteSpace($StatusValue)) { "Unknown" } else { $StatusValue }
Set-NinjaField -FieldName "hypervHealthStatus" -Value $Status
```

---

## Field Relationship Map

### Primary Dependencies

```
hypervInstalled (root)
└── If True:
    ├── hypervVMCount
    ├── hypervVMsRunning
    ├── hypervHealthStatus
    └── hypervClustered
        └── If True:
            ├── hypervClusterName
            ├── hypervClusterStatus
            └── hypervClusterQuorumOK
```

### Status Hierarchy

```
hypervHealthStatus (high-level, updated every 15 min)
└── Derived from:
    ├── hypervQuickHealth (real-time, updated every 5 min)
    ├── hypervCriticalIssues
    ├── hypervHostCPUPercent
    └── hypervHostMemoryPercent
```

---

## Migration Notes (V1 → V2)

### Field Additions (v2.0)

**No Breaking Changes:**
- All v1.0 fields remain unchanged
- New fields additive only
- Existing dashboards continue working

**New Field Categories:**
- Performance metrics (12 fields)
- Capacity planning (15 fields)
- Cluster analytics (17 fields)
- Backup & compliance (18 fields)
- Storage performance (15 fields)
- Multi-host aggregation (14 fields)

### Upgrade Path

1. **Create new custom fields** in NinjaRMM
2. **Deploy new scripts** (3-8) alongside existing
3. **Update dashboards** to include new metrics
4. **Configure new alerts** for additional monitoring
5. **Test thoroughly** before production rollout

---

## Best Practices

### Field Updates

1. **Always validate data** before updating fields
2. **Use consistent formatting** (dates, numbers)
3. **Handle errors gracefully** (set to "Unknown" on failure)
4. **Log all field updates** for troubleshooting
5. **Never leave fields undefined** after script execution

### Performance

1. **Batch field updates** when possible
2. **Avoid excessive update frequency** (<5 minutes)
3. **Use appropriate data types** (Integer vs Float)
4. **Limit WYSIWYG field size** (<100KB recommended)

### Alerting

1. **Set appropriate thresholds** for your environment
2. **Use escalation** for critical alerts
3. **Avoid alert fatigue** (tune warning levels)
4. **Test alert conditions** before production

---

## Support

**Documentation:**
- [Hyper-V Overview](./overview.md)
- [Deployment Guide](./deployment-guide.md)
- [Hyper-V README](../../hyper-v monitoring/README.md)

**Questions:**
- Review field descriptions above
- Check script source code
- Consult deployment guide
- Open GitHub issue

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-11  
**Maintained By:** WAF Team
