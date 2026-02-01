# NinjaRMM Custom Field Framework - Core Operational Metrics (Native-Enhanced)
**File:** 10_OPS_STAT_RISK_Core_Metrics.md  
**Version:** 4.0 (Native Integration)  
**Categories:** OPS (Operational Scores) + STAT (Raw Telemetry) + RISK (Classification)  
**Field Count:** 19 core fields (down from 45)  
**Last Updated:** February 1, 2026

---

## Overview

Core operational metrics that form the foundation of device health monitoring, including composite health scores, raw telemetry data, and risk classifications.

**Native Integration:** This version eliminates fields that duplicate NinjaOne's built-in monitoring capabilities (CPU, Memory, Disk metrics). These are now accessed via NinjaOne's native conditions and monitoring.

---

## NATIVE METRICS (No Custom Fields Required)

The following metrics are **available natively** in NinjaOne and should NOT be created as custom fields:

| Metric Type | NinjaOne Native | Previous Custom Field |
|-------------|-----------------|----------------------|
| **CPU Utilization** | CPU Utilization % (real-time, time-averaged) | ~~STATCPUAveragePercent~~ |
| **Memory Utilization** | Memory Utilization % (real-time) | ~~STATMemoryPressure~~ |
| **Disk Free Space** | Disk Free Space % and absolute (per-drive) | ~~STATDiskFreePercent, STATDiskFreeGB~~ |
| **Disk Performance** | Disk Active Time % (I/O monitoring) | ~~STATDiskResponseTimeMs~~ |
| **Network Performance** | Network Performance (SNMP monitoring) | ~~STATNetworkLatencyMs~~ |
| **Device Status** | Device Down/Offline (connectivity check) | ~~OPSSystemOnline~~ |
| **Service Status** | Windows Service Status (per-service) | Custom service monitors |
| **SMART Status** | SMART Status (drive health) | Custom disk health |
| **Pending Reboot** | Pending Reboot (OS flag) | Custom reboot detection |
| **Backup Status** | Backup Status (success/failed/warning) | Custom backup tracking |
| **Antivirus Status** | Antivirus Status (enabled/disabled/current) | Custom AV monitoring |
| **Patch Status** | Patch Failed, Patch Status (per-patch) | Custom patch tracking |
| **Event Log** | Windows Event Log (specific Event IDs) | Custom event parsing |

**Usage:** Access these metrics directly in compound conditions, dashboards, and reports via NinjaOne's native interface.

---

## OPS - Operational Score Fields (6 Fields)

These fields provide **intelligent composite scoring** that combines multiple data sources including native metrics.

### OPSHealthScore
- **Type:** Integer (0-100)
- **Default:** 100
- **Purpose:** Overall device health composite score
- **Populated By:** Script 1 - Health Score Calculator
- **Update Frequency:** Every 4 hours
- **Data Sources:** Native metrics + custom intelligence

**Scoring Logic:**
```
Base Score: 100

Deductions (using native metrics):
  - Crashes (STATAppCrashes24h > 10): -20 points
  - Disk Free Space < 15% (native): -15 points
  - Memory Utilization > 90% (native): -15 points
  - Service failures: -10 points
  - Security issues: -20 points
  - Updates overdue: -10 points
  - Boot time > 120s: -10 points

Minimum Score: 0
```

**Score Categories:**
```
90-100 = Excellent (optimal health)
70-89  = Good (minor issues)
50-69  = Fair (attention needed)
30-49  = Poor (multiple problems)
0-29   = Critical (urgent intervention)
```

**Integration with Native:**
Script queries NinjaOne's native metrics (Disk, Memory, CPU) and combines with custom telemetry to calculate composite health.

---

### OPSStabilityScore
- **Type:** Integer (0-100)
- **Default:** 100
- **Purpose:** Application and system stability score
- **Populated By:** Script 2 - Stability Analyzer
- **Update Frequency:** Every 4 hours
- **Data Sources:** Event logs + crash telemetry

**Scoring Logic:**
```
Base Score: 100

Deductions:
  - Each crash (24h): -2 points
  - Each hang (24h): -1.5 points
  - Each service failure: -3 points
  - Each BSOD: -20 points
  - Uptime < 24h with crashes: -10 points

Minimum Score: 0
```

**Integration with Native:**
Uses Windows Event Log (native) and custom crash counting for comprehensive stability assessment.

---

### OPSPerformanceScore
- **Type:** Integer (0-100)
- **Default:** 100
- **Purpose:** System performance and responsiveness score
- **Populated By:** Script 3 - Performance Analyzer
- **Update Frequency:** Every 4 hours
- **Data Sources:** Native performance metrics + custom measurements

**Scoring Logic:**
```
Base Score: 100

Deductions (using native metrics):
  - CPU Utilization > 80% (native): -15 points
  - Memory Utilization > 85% (native): -15 points
  - Disk Active Time > 80% (native): -10 points
  - Boot time > 120s (custom): -15 points
  - Network latency > 100ms (native): -10 points

Minimum Score: 0
```

**Integration with Native:**
Queries NinjaOne's native CPU, Memory, Disk metrics to calculate performance scoring without custom data collection.

---

### OPSSecurityScore
- **Type:** Integer (0-100)
- **Default:** 100
- **Purpose:** Security posture score
- **Populated By:** Script 4 - Security Analyzer
- **Update Frequency:** Daily
- **Data Sources:** Native security status + custom hardening checks

**Scoring Logic:**
```
Base Score: 100

Deductions (using native metrics):
  - Antivirus disabled/not installed (native): -40 points
  - Firewall disabled (native): -30 points
  - BitLocker disabled: -15 points
  - Critical patches missing (native): -15 points
  - SMBv1 enabled: -10 points

Minimum Score: 0
```

**Integration with Native:**
Uses NinjaOne's Antivirus Status, Patch Status, and Firewall status natively, supplements with custom hardening checks.

---

### OPSCapacityScore
- **Type:** Integer (0-100)
- **Default:** 100
- **Purpose:** Resource capacity and headroom score
- **Populated By:** Script 5 - Capacity Analyzer
- **Update Frequency:** Daily
- **Data Sources:** Native capacity metrics + predictive analytics

**Scoring Logic:**
```
Base Score: 100

Deductions (using native metrics):
  - Disk Free Space < 20% (native): -30 points
  - Disk Free Space < 10% (native): -50 points (override)
  - Memory Utilization > 85% (native): -20 points
  - CPU Utilization sustained > 75% (native): -15 points
  - Days until disk full < 30 (custom predictive): -15 points

Minimum Score: 0
```

**Integration with Native:**
Combines NinjaOne's real-time capacity metrics with custom predictive capacity analytics (CAPDaysUntilDiskFull).

---

### OPSLastScoreUpdate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last OPS score calculation
- **Populated By:** All OPS scoring scripts (1-5)
- **Update Frequency:** Every 4 hours
- **Format:** yyyy-MM-dd HH:mm:ss

**Purpose:**
Tracks when intelligence scores were last calculated, ensuring data freshness.

---

## STAT - Raw Telemetry Fields (6 Fields)

These fields collect **custom telemetry** not available through NinjaOne's native monitoring.

### STATAppCrashes24h
- **Type:** Integer
- **Default:** 0
- **Purpose:** Application crash count in last 24 hours
- **Populated By:** Script 6 - Telemetry Collector
- **Update Frequency:** Every 4 hours
- **Range:** 0 to 9999
- **Event Source:** Application Event Log, Event ID 1000, 1001

**Thresholds:**
```
0-2    = Normal
3-10   = Elevated
11-20  = High
21+    = Critical
```

**Why Custom:**
NinjaOne doesn't aggregate crash counts over time periods. This custom field provides historical crash frequency for stability scoring.

---

### STATAppHangs24h
- **Type:** Integer
- **Default:** 0
- **Purpose:** Application hang/freeze count in last 24 hours
- **Populated By:** Script 6 - Telemetry Collector
- **Update Frequency:** Every 4 hours
- **Range:** 0 to 9999
- **Event Source:** Application Event Log, Event ID 1002

**Why Custom:**
Application hang detection and aggregation for user experience scoring.

---

### STATServiceFailures24h
- **Type:** Integer
- **Default:** 0
- **Purpose:** Windows service failure count in last 24 hours
- **Populated By:** Script 6 - Telemetry Collector
- **Update Frequency:** Every 4 hours
- **Range:** 0 to 9999
- **Event Source:** System Event Log, Event ID 7031, 7034

**Why Custom:**
Aggregates service failure frequency for stability assessment. NinjaOne tracks individual service status but not failure frequency.

---

### STATBSODCount30d
- **Type:** Integer
- **Default:** 0
- **Purpose:** Blue Screen of Death count in last 30 days
- **Populated By:** Script 6 - Telemetry Collector
- **Update Frequency:** Daily
- **Range:** 0 to 999
- **Event Source:** System Event Log, Event ID 1001 (BugCheck), Event ID 41 (Kernel-Power)

**Why Custom:**
Critical stability metric for hardware/driver issues. Requires historical aggregation not provided natively.

---

### STATUptimeDays
- **Type:** Integer
- **Default:** 0
- **Purpose:** Days since last reboot
- **Populated By:** Script 6 - Telemetry Collector
- **Update Frequency:** Every 4 hours
- **Range:** 0 to 9999 days
- **Calculation:** (Current time - Last boot time) in days

**Why Custom:**
Provides uptime in days format for reboot recommendation logic. Native uptime is available but this field standardizes the format.

---

### STATLastTelemetryUpdate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last telemetry collection
- **Populated By:** Script 6 - Telemetry Collector
- **Update Frequency:** Every 4 hours
- **Format:** yyyy-MM-dd HH:mm:ss

**Purpose:**
Ensures telemetry data freshness and script execution tracking.

---

## RISK - Classification Fields (7 Fields)

These fields provide **intelligent risk classification** based on native metrics and custom intelligence.

### RISKHealthLevel
- **Type:** Dropdown
- **Valid Values:** Healthy, Degraded, Critical, Unknown
- **Default:** Unknown
- **Purpose:** Overall device health classification
- **Populated By:** Script 9 - Risk Classifier
- **Update Frequency:** Every 4 hours
- **Data Sources:** OPSHealthScore + native metrics

**Classification Logic:**
```
Healthy:
  - OPSHealthScore >= 70
  - No critical native alerts (disk, memory, CPU)

Degraded:
  - OPSHealthScore 40-69
  - OR multiple minor native alerts

Critical:
  - OPSHealthScore < 40
  - OR critical native alert (disk < 5%, service down)

Unknown:
  - Insufficient data
```

---

### RISKRebootLevel
- **Type:** Dropdown
- **Valid Values:** None, Low, Medium, High, Critical
- **Default:** None
- **Purpose:** Reboot recommendation level
- **Populated By:** Script 9 - Risk Classifier
- **Update Frequency:** Every 4 hours
- **Data Sources:** STATUptimeDays + Pending Reboot (native) + crash counts

**Classification Logic:**
```
None:
  - Uptime < 30 days
  - No crashes or pending updates

Low:
  - Uptime 30-60 days
  - Minor issues present

Medium:
  - Uptime 60-90 days
  - OR moderate crash rate

High:
  - Uptime > 90 days
  - OR Pending Reboot = True (native)
  - OR high crash rate

Critical:
  - Uptime > 120 days
  - OR Pending Reboot with critical patches (native)
  - OR system instability
```

---

### RISKSecurityExposure
- **Type:** Dropdown
- **Valid Values:** Low, Medium, High, Critical
- **Default:** Low
- **Purpose:** Security risk exposure level
- **Populated By:** Script 9 - Risk Classifier
- **Update Frequency:** Daily
- **Data Sources:** Native security status + custom hardening

**Classification Logic:**
```
Low:
  - Antivirus enabled and current (native)
  - Firewall enabled (native)
  - Patches current (native)

Medium:
  - Minor security gaps
  - Patches 30-45 days old (native)

High:
  - Antivirus outdated (native)
  - OR Firewall disabled (native)
  - OR Patches > 45 days old (native)

Critical:
  - Antivirus disabled (native)
  - Firewall disabled (native)
  - Critical patches missing (native)
```

---

### RISKComplianceFlag
- **Type:** Dropdown
- **Valid Values:** Compliant, Warning, Non-Compliant, Critical
- **Default:** Compliant
- **Purpose:** Overall compliance status
- **Populated By:** Script 9 - Risk Classifier
- **Update Frequency:** Daily
- **Data Sources:** Multiple native and custom sources

---

### RISKShadowIT
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Shadow IT detected (unauthorized software)
- **Populated By:** Script 9 - Risk Classifier
- **Update Frequency:** Daily
- **Detection:** Based on DRIFTNewAppsCount and software baseline (custom)

---

### RISKDataLossRisk
- **Type:** Dropdown
- **Valid Values:** Low, Medium, High, Critical
- **Default:** Low
- **Purpose:** Data loss risk assessment
- **Populated By:** Script 9 - Risk Classifier
- **Update Frequency:** Daily
- **Data Sources:** Backup Status (native) + Disk Space (native) + SMART (native)

**Classification Logic:**
```
Low:
  - Backup Status = Success (native, < 24h)
  - Disk Free Space > 20% (native)
  - SMART Status = Healthy (native)

Medium:
  - Backup 24-72h old (native)
  - OR Disk Free Space < 20% (native)

High:
  - Backup Status = Failed (native, > 72h)
  - OR Disk Free Space < 10% (native)
  - OR SMART Status = Warning (native)

Critical:
  - Backup Status = Failed (native, > 7 days)
  - Disk Free Space < 5% (native)
  - SMART Status = Failed (native)
```

---

### RISKLastRiskAssessment
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last risk classification
- **Populated By:** Script 9 - Risk Classifier
- **Update Frequency:** Every 4 hours
- **Format:** yyyy-MM-dd HH:mm:ss

---

## Script-to-Field Mapping (7 Active Scripts)

### Script 1: Health Score Calculator
**Execution:** Every 4 hours  
**Runtime:** ~15 seconds  
**Data Sources:** Native metrics (Disk, Memory, CPU) + Custom telemetry  
**Fields Updated:**
- OPSHealthScore
- OPSLastScoreUpdate

**Native Integration:**
- Queries Disk Free Space (native)
- Queries Memory Utilization (native)
- Queries CPU Utilization (native)
- Combines with STATAppCrashes24h and other custom fields

---

### Script 2: Stability Analyzer
**Execution:** Every 4 hours  
**Runtime:** ~10 seconds  
**Data Sources:** Windows Event Log (native) + Custom crash counts  
**Fields Updated:**
- OPSStabilityScore
- OPSLastScoreUpdate

**Native Integration:**
- Reads Windows Event Log (native)
- Combines with STATAppCrashes24h, STATBSODCount30d

---

### Script 3: Performance Analyzer
**Execution:** Every 4 hours  
**Runtime:** ~20 seconds  
**Data Sources:** Native performance metrics + Custom measurements  
**Fields Updated:**
- OPSPerformanceScore
- OPSLastScoreUpdate

**Native Integration:**
- Queries CPU Utilization (native)
- Queries Memory Utilization (native)
- Queries Disk Active Time (native)
- Supplements with boot time (custom)

---

### Script 4: Security Analyzer
**Execution:** Daily  
**Runtime:** ~30 seconds  
**Data Sources:** Native security status + Custom hardening  
**Fields Updated:**
- OPSSecurityScore
- OPSLastScoreUpdate

**Native Integration:**
- Queries Antivirus Status (native)
- Queries Patch Status (native)
- Queries Firewall status (native)
- Supplements with custom hardening checks

---

### Script 5: Capacity Analyzer
**Execution:** Daily  
**Runtime:** ~15 seconds  
**Data Sources:** Native capacity metrics + Predictive analytics  
**Fields Updated:**
- OPSCapacityScore
- OPSLastScoreUpdate

**Native Integration:**
- Queries Disk Free Space (native)
- Queries Memory Utilization (native)
- Combines with CAPDaysUntilDiskFull (custom predictive)

---

### Script 6: Telemetry Collector
**Execution:** Every 4 hours  
**Runtime:** ~25 seconds  
**Data Sources:** Windows Event Log (native) + System queries  
**Fields Updated:**
- STATAppCrashes24h
- STATAppHangs24h
- STATServiceFailures24h
- STATBSODCount30d
- STATUptimeDays
- STATLastTelemetryUpdate

**Native Integration:**
- Reads Windows Event Log (native)
- Aggregates crash and hang events over time
- Provides custom telemetry not available natively

---

### Script 9: Risk Classifier
**Execution:** Every 4 hours  
**Runtime:** ~10 seconds  
**Data Sources:** Native metrics + OPS scores + STAT telemetry  
**Fields Updated:**
- RISKHealthLevel
- RISKRebootLevel
- RISKSecurityExposure
- RISKComplianceFlag
- RISKShadowIT
- RISKDataLossRisk
- RISKLastRiskAssessment

**Native Integration:**
- Queries multiple native conditions (Backup, AV, Patches, Disk)
- Combines with OPS scores and STAT counts
- Produces intelligent risk classifications

---

## DEPRECATED SCRIPTS (Not Required)

### ~~Script 7: Resource Monitor~~ (DEPRECATED)
**Reason:** Replaced by NinjaOne native metrics  
**Previous Fields:**
- ~~STATCPUAveragePercent~~ → Use CPU Utilization (native)
- ~~STATMemoryPressure~~ → Use Memory Utilization (native)
- ~~STATDiskFreePercent~~ → Use Disk Free Space (native)
- ~~STATDiskFreeGB~~ → Use Disk Free Space (native)
- ~~STATDiskResponseTimeMs~~ → Use Disk Active Time (native)

**Migration:** Remove script. Update compound conditions to use native metrics.

---

### ~~Script 8: Network Monitor~~ (DEPRECATED)
**Reason:** Replaced by NinjaOne native network monitoring  
**Previous Fields:**
- ~~STATNetworkLatencyMs~~ → Use Network Performance (native SNMP)

**Migration:** Remove script. Use native network monitoring for latency tracking.

---

## Integration Examples

### Compound Condition Using Native + Custom
```
Condition: Critical System Failure
Priority: P1 Critical
Check Frequency: Every 5 minutes

Logic:
  (Device Down = True OR CPU Utilization > 95% for 10 minutes) [NATIVE]
  AND OPSHealthScore < 40 [CUSTOM]
  AND STATCrashCount30d > 0 [CUSTOM]

Result: High-confidence critical alert combining native real-time 
        monitoring with custom intelligence scoring
```

### Health Dashboard Widget
```html
<div class="health-widget">
  <div class="score-circle {{class}}">{{OPSHealthScore}}</div>
  <div class="breakdown">
    <div>Stability: {{OPSStabilityScore}}</div>
    <div>Performance: {{OPSPerformanceScore}}</div>
    <div>Security: {{OPSSecurityScore}}</div>
    <div>Capacity: {{OPSCapacityScore}}</div>
  </div>
  <div class="native-metrics">
    <div>CPU: {{CPU_Utilization}}%</div>  <!-- Native -->
    <div>Memory: {{Memory_Utilization}}%</div>  <!-- Native -->
    <div>Disk: {{Disk_Free_Space}}%</div>  <!-- Native -->
  </div>
  <div class="risk-level {{risk-class}}">{{RISKHealthLevel}}</div>
</div>
```

---

## Migration Guide

### From Original Framework (v3.0) to Native-Enhanced (v4.0)

**Step 1: Stop Deprecated Scripts**
- Disable Script 7 (Resource Monitor)
- Disable Script 8 (Network Monitor)

**Step 2: Update Compound Conditions**
- Replace `STATCPUAveragePercent` with native CPU Utilization
- Replace `STATMemoryPressure` with native Memory Utilization
- Replace `STATDiskFreePercent` with native Disk Free Space
- Replace `OPSSystemOnline` with native Device Down

**Step 3: Archive Deprecated Fields**
- Mark deprecated fields as inactive
- Do not delete (preserve historical data)
- Fields: STATCPUAveragePercent, STATMemoryPressure, STATDiskFreePercent, 
  STATDiskFreeGB, STATDiskResponseTimeMs, STATNetworkLatencyMs, OPSSystemOnline

**Step 4: Deploy Updated Scripts**
- Update Scripts 1-5 to query native metrics
- Continue running Script 6 (Telemetry) as-is
- Continue running Script 9 (Risk Classification) with native queries

**Step 5: Test and Validate**
- Verify compound conditions trigger correctly
- Validate dashboard displays native metrics
- Confirm OPS scores calculate correctly with native data

**Timeline:** 1-2 weeks for gradual migration

---

## Benefits of Native Integration

### Operational Benefits
- **Real-time monitoring:** Native metrics update instantly vs 4-hour script delay
- **Higher accuracy:** Hardware-level and OS-level monitoring
- **Lower overhead:** Fewer scripts running = lower agent resource usage
- **Better reliability:** Native monitoring doesn't fail like custom scripts

### Technical Benefits
- **58% fewer custom fields** (19 vs 45)
- **78% fewer scripts** (7 vs 9 in core, much more in full framework)
- **Reduced complexity:** Simpler architecture, easier maintenance
- **Faster deployment:** Less to configure and test

### Business Benefits
- **Lower false positives:** Native + custom = smarter alerts
- **Better context:** Combines real-time native with historical intelligence
- **Reduced costs:** Less maintenance, faster troubleshooting
- **Improved ROI:** Deploy faster, maintain easier

---

**Total Fields This File:** 19 core fields (down from 45)  
**Active Scripts:** 7 scripts (Scripts 1-6, 9)  
**Deprecated Scripts:** 2 scripts (Scripts 7-8)  
**Native Metrics Used:** 11+ NinjaOne built-in capabilities  
**Update Frequencies:** Every 4 hours (intelligence), Real-time (native)  
**Priority Level:** Critical (Core Framework Foundation)

---

**File:** 10_OPS_STAT_RISK_Core_Metrics.md  
**Last Updated:** February 1, 2026, 4:59 PM CET  
**Framework Version:** 4.0 (Native Integration)  
**Status:** Production Ready
