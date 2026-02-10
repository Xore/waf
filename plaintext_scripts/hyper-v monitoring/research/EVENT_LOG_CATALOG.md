# Hyper-V Event Log ID Catalog

**Created:** February 10, 2026  
**Status:** Phase 1 Research  
**Purpose:** Catalog of Hyper-V event log IDs for migration, failover, and operational tracking

---

## Event Log Channels

### Primary Event Logs

**1. Microsoft-Windows-Hyper-V-VMMS-Admin**
- Path: `Microsoft-Windows-Hyper-V-VMMS-Admin`
- Description: Virtual Machine Management Service administrative events
- Contains: VM lifecycle, migrations, configuration changes

**2. Microsoft-Windows-Hyper-V-Worker-Admin**
- Path: `Microsoft-Windows-Hyper-V-Worker-Admin`
- Description: VM worker process events
- Contains: VM crashes, worker failures, integration services

**3. Microsoft-Windows-Hyper-V-Compute-Admin**
- Path: `Microsoft-Windows-Hyper-V-Compute-Admin`
- Description: Compute service events (Windows Server 2016+)
- Contains: Container and VM compute operations

**4. Microsoft-Windows-FailoverClustering/Operational**
- Path: `Microsoft-Windows-FailoverClustering/Operational`
- Description: Failover cluster operational events
- Contains: Node state changes, resource movements, quorum events

**5. System**
- Path: `System`
- Description: System events (Hyper-V related subset)
- Contains: Service starts/stops, critical system events

---

## Live Migration Events

### Microsoft-Windows-Hyper-V-VMMS-Admin

#### Event ID: 20417
**Level:** Information  
**Description:** Live migration started  
**Message:** `The Virtual Machine Management service successfully initiated a live migration of virtual machine "<VM Name>" to host "<Destination Host>".`  
**Usage:** Track migration start time, source/destination

**Example:**
```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    ID = 20417
    StartTime = (Get-Date).AddDays(-1)
}
```

---

#### Event ID: 21002
**Level:** Information  
**Description:** Live migration completed successfully  
**Message:** `The Virtual Machine Management service successfully completed the live migration of virtual machine "<VM Name>" to host "<Destination Host>".`  
**Usage:** Track migration completion, calculate duration (21002 - 20417)

---

#### Event ID: 21008
**Level:** Error  
**Description:** Live migration failed  
**Message:** `The live migration failed for virtual machine "<VM Name>". Error: <Error Details>`  
**Usage:** Track migration failures, error analysis

---

#### Event ID: 21502
**Level:** Error  
**Description:** Live migration failed at destination  
**Message:** `Failed migration at destination host. The live migration was unsuccessful for virtual machine "<VM Name>".`  
**Usage:** Destination-side migration failures

---

#### Event ID: 20414
**Level:** Information  
**Description:** Storage migration started  
**Message:** `The Virtual Machine Management Service started a storage migration for virtual machine "<VM Name>".`  
**Usage:** Track storage migrations separately from live migrations

---

#### Event ID: 20415
**Level:** Information  
**Description:** Storage migration completed  
**Message:** `The Virtual Machine Management Service successfully completed a storage migration for virtual machine "<VM Name>".`  
**Usage:** Track storage migration completion

---

### Live Migration Duration Calculation

```powershell
# Get migration events for last 24 hours
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

# Match start and complete events
foreach ($Start in $StartEvents) {
    $VMName = $Start.Properties[0].Value
    $Complete = $CompleteEvents | Where-Object { $_.Properties[0].Value -eq $VMName -and $_.TimeCreated -gt $Start.TimeCreated } | Select-Object -First 1
    
    if ($Complete) {
        $Duration = ($Complete.TimeCreated - $Start.TimeCreated).TotalSeconds
        [PSCustomObject]@{
            VM = $VMName
            StartTime = $Start.TimeCreated
            EndTime = $Complete.TimeCreated
            DurationSeconds = $Duration
            DestinationHost = $Start.Properties[1].Value
        }
    }
}
```

---

## Failover Clustering Events

### Microsoft-Windows-FailoverClustering/Operational

#### Event ID: 1146
**Level:** Critical  
**Description:** Cluster resource moved (failover)  
**Message:** `The cluster resource hosting subsystem process has been stopped and will be restarted. This is typically associated with cluster health detection and recovery of a resource.`  
**Usage:** Detect VM failover events

**Note:** Usually preceded by Event 1230 (component timeout)

---

#### Event ID: 1230
**Level:** Warning/Error  
**Description:** Component timeout (precedes failover)  
**Message:** `A component on the server did not respond in a timely manner. The cluster resource "<VM Name>" (resource type "Virtual Machine") has exceeded the timeout threshold. Recovery actions will be taken.`  
**Usage:** Early warning of impending failover

---

#### Event ID: 1069
**Level:** Critical  
**Description:** Cluster resource failed  
**Message:** `The cluster resource "<VM Name>" of type "Virtual Machine" in clustered role "<Role Name>" failed.`  
**Usage:** Track resource failures that trigger failovers

---

#### Event ID: 1204
**Level:** Information  
**Description:** Cluster resource online  
**Message:** `The cluster resource "<VM Name>" became online.`  
**Usage:** Track successful failover completion (resource online on new node)

---

#### Event ID: 1006
**Level:** Information  
**Description:** Cluster resource moved  
**Message:** `The cluster resource "<VM Name>" was brought online.`  
**Usage:** Planned or unplanned resource movement

---

### Failover Detection Pattern

```powershell
# Detect failovers in last 30 days
$FailoverEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-FailoverClustering/Operational'
    ID = 1069, 1146, 1230
    StartTime = (Get-Date).AddDays(-30)
} -ErrorAction SilentlyContinue

# Group by VM name
$FailoverEvents | ForEach-Object {
    $Message = $_.Message
    if ($Message -match 'cluster resource "([^"]+)"') {
        $VMName = $Matches[1]
        [PSCustomObject]@{
            TimeCreated = $_.TimeCreated
            EventID = $_.Id
            VM = $VMName
            Level = $_.LevelDisplayName
            Message = $Message
        }
    }
} | Group-Object VM | ForEach-Object {
    [PSCustomObject]@{
        VM = $_.Name
        FailoverCount = ($_.Group | Where-Object { $_.EventID -eq 1069 }).Count
        Events = $_.Group | Sort-Object TimeCreated -Descending
    }
}
```

---

## VM Lifecycle Events

### Microsoft-Windows-Hyper-V-VMMS-Admin

#### Event ID: 18500
**Level:** Information  
**Description:** VM started successfully  
**Message:** `Virtual Machine "<VM Name>" started successfully.`  
**Usage:** Track VM starts

---

#### Event ID: 18502
**Level:** Information  
**Description:** VM stopped  
**Message:** `Virtual Machine "<VM Name>" stopped.`  
**Usage:** Track planned VM stops

---

#### Event ID: 18590
**Level:** Warning  
**Description:** VM crashed/unexpected stop  
**Message:** `Virtual Machine "<VM Name>" has stopped unexpectedly.`  
**Usage:** Detect VM crashes (already tracked in Health Check 2)

---

## Backup Events

### Microsoft-Windows-Hyper-V-VMMS-Admin

#### Event ID: 18310
**Level:** Information  
**Description:** VSS backup started  
**Message:** `Hyper-V VSS Writer: Starting backup for virtual machine "<VM Name>".`  
**Usage:** Track backup start time

---

#### Event ID: 18311
**Level:** Information  
**Description:** VSS backup completed  
**Message:** `Hyper-V VSS Writer: Backup completed for virtual machine "<VM Name>".`  
**Usage:** Track backup completion, calculate backup duration

---

#### Event ID: 18312
**Level:** Error  
**Description:** VSS backup failed  
**Message:** `Hyper-V VSS Writer: Backup failed for virtual machine "<VM Name>". Error: <Error Details>`  
**Usage:** Track backup failures

---

## Replication Events

### Microsoft-Windows-Hyper-V-VMMS-Admin

#### Event ID: 32002
**Level:** Information  
**Description:** Replication enabled  
**Message:** `Hyper-V successfully enabled replication for virtual machine "<VM Name>".`  
**Usage:** Track replication setup

---

#### Event ID: 32004
**Level:** Error  
**Description:** Replication failed  
**Message:** `Hyper-V Replica failed to replicate changes for virtual machine "<VM Name>". Error: <Error Details>`  
**Usage:** Track replication failures (already tracked in Health Check 2)

---

#### Event ID: 32010
**Level:** Warning  
**Description:** Replication connection lost  
**Message:** `Hyper-V Replica lost connection to replica server for virtual machine "<VM Name>".`  
**Usage:** Track replication connectivity issues

---

## Performance Events

### Microsoft-Windows-Hyper-V-VMMS-Admin

#### Event ID: 18550
**Level:** Warning  
**Description:** VM CPU threshold exceeded  
**Message:** `Virtual Machine "<VM Name>" has exceeded CPU usage threshold.`  
**Usage:** Performance monitoring (already tracked in Health Check 2)

---

#### Event ID: 18551
**Level:** Warning  
**Description:** VM memory pressure detected  
**Message:** `Virtual Machine "<VM Name>" memory pressure detected.`  
**Usage:** Memory performance monitoring

---

#### Event ID: 18552
**Level:** Warning  
**Description:** Storage latency affecting VM  
**Message:** `Virtual Machine "<VM Name>" is experiencing high storage latency.`  
**Usage:** Storage performance issues

---

## CSV Events

### Microsoft-Windows-FailoverClustering-CsvFs/Operational

#### Event ID: 5120
**Level:** Information  
**Description:** CSV volume mounted  
**Message:** `Cluster Shared Volume "<CSV Name>" is now available on this node.`  
**Usage:** Track CSV availability

---

#### Event ID: 5121
**Level:** Warning  
**Description:** CSV volume dismounted  
**Message:** `Cluster Shared Volume "<CSV Name>" is no longer available on this node.`  
**Usage:** Track CSV issues

---

#### Event ID: 5142
**Level:** Warning  
**Description:** CSV I/O redirected  
**Message:** `Cluster Shared Volume "<CSV Name>" is in redirected I/O mode.`  
**Usage:** Detect CSV performance issues (direct I/O unavailable)

---

## Event Query Optimization

### Efficient Event Log Queries

**Use FilterHashtable:**
```powershell
# GOOD: FilterHashtable (fast, filtered at source)
$Events = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    ID = 20417, 21002, 21008
    StartTime = (Get-Date).AddDays(-1)
} -ErrorAction SilentlyContinue

# BAD: Where-Object (slow, filters after retrieval)
$Events = Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-VMMS-Admin' | 
    Where-Object { $_.Id -in @(20417, 21002, 21008) }
```

**Limit Time Range:**
```powershell
# Specify time range to reduce results
$Events = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    ID = 20417
    StartTime = (Get-Date).AddHours(-24)
    EndTime = Get-Date
}
```

**Handle Missing Logs:**
```powershell
# Always use ErrorAction SilentlyContinue
try {
    $Events = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
        ID = 20417
    } -ErrorAction Stop
} catch {
    if ($_.Exception.Message -like '*No events were found*') {
        # No events (normal)
        $Events = @()
    } else {
        # Actual error
        Write-Warning "Failed to query event log: $($_.Exception.Message)"
    }
}
```

---

## Event Data Extraction

### Extract Properties from Events

```powershell
# Live migration event (20417)
$Event = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    ID = 20417
    MaxEvents = 1
}

# Properties array
$VMName = $Event.Properties[0].Value  # VM Name
$DestHost = $Event.Properties[1].Value  # Destination Host

# Generic property extraction
function Get-EventProperties {
    param($Event)
    
    for ($i = 0; $i -lt $Event.Properties.Count; $i++) {
        [PSCustomObject]@{
            Index = $i
            Value = $Event.Properties[$i].Value
        }
    }
}
```

### Parse VM Name from Message

```powershell
# Extract VM name from event message
function Get-VMNameFromEvent {
    param($Event)
    
    if ($Event.Message -match '"([^"]+)"') {
        return $Matches[1]
    }
    return $null
}

# Usage
$Events | ForEach-Object {
    $VMName = Get-VMNameFromEvent -Event $_
    # Process
}
```

---

## Event Log Performance

### Query Performance Tips

**1. Use Specific Time Ranges:**
- Narrow time ranges reduce query time
- 24-hour queries: <1 second
- 30-day queries: 1-5 seconds
- 90-day queries: 5-15 seconds

**2. Limit Event IDs:**
- Specify exact IDs instead of retrieving all events
- FilterHashtable ID filtering is very fast

**3. Use MaxEvents:**
```powershell
# Limit results to most recent
$Events = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    ID = 20417
} -MaxEvents 100
```

**4. Cache Results:**
```powershell
# Cache event queries
if (-not $script:MigrationEvents -or (Get-Date) -gt $script:MigrationEventsExpiry) {
    $script:MigrationEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
        ID = 20417, 21002, 21008
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction SilentlyContinue
    $script:MigrationEventsExpiry = (Get-Date).AddMinutes(5)
}
```

---

## Event ID Quick Reference

### Live Migration
| Event ID | Level | Description |
|----------|-------|-------------|
| 20417 | Info | Migration started |
| 21002 | Info | Migration completed |
| 21008 | Error | Migration failed |
| 21502 | Error | Migration failed at destination |
| 20414 | Info | Storage migration started |
| 20415 | Info | Storage migration completed |

### Failover Clustering
| Event ID | Level | Description |
|----------|-------|-------------|
| 1069 | Critical | Resource failed |
| 1146 | Critical | Resource subsystem restarted |
| 1230 | Warning | Component timeout |
| 1204 | Info | Resource online |
| 1006 | Info | Resource moved |

### VM Lifecycle
| Event ID | Level | Description |
|----------|-------|-------------|
| 18500 | Info | VM started |
| 18502 | Info | VM stopped |
| 18590 | Warning | VM crashed |

### Backup
| Event ID | Level | Description |
|----------|-------|-------------|
| 18310 | Info | Backup started |
| 18311 | Info | Backup completed |
| 18312 | Error | Backup failed |

### Replication
| Event ID | Level | Description |
|----------|-------|-------------|
| 32002 | Info | Replication enabled |
| 32004 | Error | Replication failed |
| 32010 | Warning | Connection lost |

### Performance
| Event ID | Level | Description |
|----------|-------|-------------|
| 18550 | Warning | CPU threshold exceeded |
| 18551 | Warning | Memory pressure |
| 18552 | Warning | Storage latency |

### CSV
| Event ID | Level | Description |
|----------|-------|-------------|
| 5120 | Info | CSV mounted |
| 5121 | Warning | CSV dismounted |
| 5142 | Warning | CSV redirected I/O |

---

## References

### Microsoft Documentation
- [Troubleshoot Live Migration Issues](https://learn.microsoft.com/en-us/troubleshoot/windows-server/virtualization/troubleshoot-live-migration-issues)
- [Hyper-V Virtual Machine Live Migration Guide](https://learn.microsoft.com/en-us/troubleshoot/windows-server/virtualization/hyper-v-virtual-machine-live-migration)
- [Failover Cluster Event IDs](https://learn.microsoft.com/en-us/windows-server/failover-clustering/failover-cluster-event-ids)

### Community Resources
- [Hyper-V Event Log Overview](https://virtualizationdojo.com/hyper-v/an-overview-of-hyper-v-event-logs/)
- [Monitoring Event Logs with PowerShell](https://virtualizationdojo.com/hyper-v/monitoring-hyper-v-operational-and-admin-event-logs/)

---

**Document Version:** 1.0  
**Last Updated:** February 10, 2026  
**Next Update:** After Script 5 implementation testing  
**Maintained By:** Windows Automation Framework Team
