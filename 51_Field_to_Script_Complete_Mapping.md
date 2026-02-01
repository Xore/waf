# Field to Script Complete Mapping (Native-Enhanced)
**File:** 51_Field_to_Script_Complete_Mapping.md  
**Version:** 4.0 (Native Integration)  
**Last Updated:** February 1, 2026  
**Total Custom Fields:** 35 core fields (down from 153)  
**Active Scripts:** ~30 scripts (down from 105+)

---

## OVERVIEW

This document maps all custom fields to their populating scripts in the native-enhanced framework (v4.0). 

**Native Integration:** Many metrics previously collected via custom scripts are now accessed via NinjaOne's built-in monitoring. This mapping reflects only the **custom intelligence fields** that remain necessary.

---

## NATIVE METRICS (No Custom Fields Required)

**These metrics are available natively in NinjaOne and should NOT be created as custom fields:**

| Native Metric Category | Metrics Available | Previous Custom Fields |
|------------------------|-------------------|------------------------|
| **System Performance** | CPU Utilization %, Memory Utilization %, Disk Active Time % | ~~STATCPUAveragePercent, STATMemoryPressure, STATDiskResponseTimeMs~~ |
| **Storage** | Disk Free Space % and GB (per-drive) | ~~STATDiskFreePercent, STATDiskFreeGB~~ |
| **Network** | Network Performance (SNMP), Connectivity | ~~STATNetworkLatencyMs, OPSSystemOnline~~ |
| **Services** | Windows Service Status (per-service) | Custom service monitors |
| **Hardware** | SMART Status, Temperature sensors | Custom disk health |
| **Updates & Security** | Patch Status, Antivirus Status, Firewall Status, Pending Reboot | Custom security checks |
| **Backup** | Backup Status (success/failed/warning) | Custom backup tracking |
| **Event Log** | Windows Event Log (specific Event IDs) | Custom event parsing |

**Total Native Capabilities:** 11+ metric categories  
**Custom Fields Eliminated:** 25+ fields replaced by native monitoring

---

## CORE METRICS - OPS/STAT/RISK (19 Fields, 7 Scripts)

### Script 1: Health Score Calculator
**Execution:** Every 4 hours  
**Runtime:** ~15 seconds  
**Purpose:** Calculate overall device health composite score  
**Data Sources:** Native metrics (Disk, Memory, CPU) + Custom telemetry  

**Fields Updated:**
- OPSHealthScore (Integer 0-100) - Composite health score
- OPSLastScoreUpdate (DateTime) - Last calculation timestamp

**Native Integration:**
- Queries Disk Free Space (native) for capacity assessment
- Queries Memory Utilization (native) for pressure detection
- Queries CPU Utilization (native) for performance assessment
- Combines with STATAppCrashes24h and custom telemetry

---

### Script 2: Stability Analyzer
**Execution:** Every 4 hours  
**Runtime:** ~10 seconds  
**Purpose:** Calculate system and application stability score  
**Data Sources:** Windows Event Log (native) + Custom crash counts  

**Fields Updated:**
- OPSStabilityScore (Integer 0-100) - Stability assessment score
- OPSLastScoreUpdate (DateTime) - Last calculation timestamp

**Native Integration:**
- Reads Windows Event Log (native) for service failures
- Combines with STATAppCrashes24h, STATBSODCount30d

---

### Script 3: Performance Analyzer
**Execution:** Every 4 hours  
**Runtime:** ~20 seconds  
**Purpose:** Calculate system performance and responsiveness score  
**Data Sources:** Native performance metrics + Custom measurements  

**Fields Updated:**
- OPSPerformanceScore (Integer 0-100) - Performance assessment score
- OPSLastScoreUpdate (DateTime) - Last calculation timestamp

**Native Integration:**
- Queries CPU Utilization (native) for processor load
- Queries Memory Utilization (native) for memory pressure
- Queries Disk Active Time (native) for I/O performance
- Supplements with boot time measurement (custom)

---

### Script 4: Security Analyzer
**Execution:** Daily  
**Runtime:** ~30 seconds  
**Purpose:** Calculate security posture score  
**Data Sources:** Native security status + Custom hardening checks  

**Fields Updated:**
- OPSSecurityScore (Integer 0-100) - Security posture score
- OPSLastScoreUpdate (DateTime) - Last calculation timestamp

**Native Integration:**
- Queries Antivirus Status (native) for AV state
- Queries Patch Status (native) for update compliance
- Queries Firewall Status (native) for firewall state
- Supplements with BitLocker, SMBv1, and hardening checks

---

### Script 5: Capacity Analyzer
**Execution:** Daily  
**Runtime:** ~15 seconds  
**Purpose:** Calculate resource capacity and headroom score  
**Data Sources:** Native capacity metrics + Predictive analytics  

**Fields Updated:**
- OPSCapacityScore (Integer 0-100) - Capacity assessment score
- OPSLastScoreUpdate (DateTime) - Last calculation timestamp

**Native Integration:**
- Queries Disk Free Space (native) for storage capacity
- Queries Memory Utilization (native) for memory capacity
- Combines with CAPDaysUntilDiskFull (custom predictive field)

---

### Script 6: Telemetry Collector
**Execution:** Every 4 hours  
**Runtime:** ~25 seconds  
**Purpose:** Collect custom telemetry not available natively  
**Data Sources:** Windows Event Log (native) + System queries  

**Fields Updated:**
- STATAppCrashes24h (Integer) - Application crash count (24h)
- STATAppHangs24h (Integer) - Application hang count (24h)
- STATServiceFailures24h (Integer) - Service failure count (24h)
- STATBSODCount30d (Integer) - BSOD count (30d)
- STATUptimeDays (Integer) - Days since last reboot
- STATLastTelemetryUpdate (DateTime) - Last collection timestamp

**Why Custom:**
NinjaOne doesn't aggregate crash/hang/failure counts over time periods. These custom fields provide historical frequency tracking for stability scoring.

---

### Script 9: Risk Classifier
**Execution:** Every 4 hours  
**Runtime:** ~10 seconds  
**Purpose:** Classify devices into risk categories  
**Data Sources:** Native metrics + OPS scores + STAT telemetry  

**Fields Updated:**
- RISKHealthLevel (Dropdown) - Overall health classification
- RISKRebootLevel (Dropdown) - Reboot recommendation level
- RISKSecurityExposure (Dropdown) - Security risk level
- RISKComplianceFlag (Dropdown) - Compliance status
- RISKShadowIT (Checkbox) - Shadow IT detection flag
- RISKDataLossRisk (Dropdown) - Data loss risk level
- RISKLastRiskAssessment (DateTime) - Last assessment timestamp

**Native Integration:**
- Queries Backup Status (native) for data loss risk
- Queries SMART Status (native) for hardware risk
- Queries Pending Reboot (native) for reboot recommendation
- Combines with OPS scores and STAT counts

---

## DEPRECATED SCRIPTS (Not Required in v4.0)

### ~~Script 7: Resource Monitor~~ (DEPRECATED)
**Status:** Removed - Replaced by NinjaOne native monitoring  
**Previous Runtime:** Every 4 hours, ~20 seconds  
**Previous Fields:**
- ~~STATCPUAveragePercent~~ → Use CPU Utilization (native)
- ~~STATMemoryPressure~~ → Use Memory Utilization (native)
- ~~STATDiskFreePercent~~ → Use Disk Free Space (native)
- ~~STATDiskFreeGB~~ → Use Disk Free Space (native)
- ~~STATDiskResponseTimeMs~~ → Use Disk Active Time (native)

**Migration:** Delete script, update compound conditions to use native metrics.

---

### ~~Script 8: Network Monitor~~ (DEPRECATED)
**Status:** Removed - Replaced by NinjaOne native monitoring  
**Previous Runtime:** Every 4 hours, ~15 seconds  
**Previous Fields:**
- ~~STATNetworkLatencyMs~~ → Use Network Performance (native SNMP)

**Migration:** Delete script, use native network monitoring.

---

## ADDITIONAL CUSTOM FIELDS (By Category)

### AUTO - Automation Control (4 Fields)
**No dedicated collection script - managed by automation framework**

- AUTORemediationEligible (Checkbox) - Device approved for automation
- AUTOAllowCleanup (Checkbox) - Allow disk cleanup automation
- AUTOAllowServiceRestart (Checkbox) - Allow service restart automation
- AUTOAllowAfterHoursReboot (Checkbox) - Allow scheduled reboot automation

**Populated By:** Manual setting or Script 14 (Automation Eligibility Assessor)

---

### UPD - Update Management (4 Fields)
**Script 10: Update Assessment Collector**

- UPDMissingCriticalCount (Integer) - Count of missing critical patches
- UPDMissingImportantCount (Integer) - Count of missing important patches
- UPDMissingOptionalCount (Integer) - Count of missing optional patches
- UPDDaysSinceLastReboot (Integer) - Days since last reboot

**Native Integration:** Queries Patch Status (native) and aggregates counts

---

### NET - Network & Location (3 Fields)
**Script 11: Network Location Tracker**

- NETLocationCurrent (Dropdown) - Current network location
- NETLocationPrevious (Dropdown) - Previous network location
- NETVPNConnected (Checkbox) - VPN connection status

**Purpose:** Network-aware policy application and security

---

### CAP - Capacity Planning (2 Fields)
**Script 22: Capacity Forecaster**

- CAPDaysUntilDiskFull (Integer) - Predictive days until disk full
- CAPDiskGrowthRateMBPerDay (Integer) - Daily disk growth rate in MB

**Native Integration:** Uses Disk Free Space (native) for historical trending

---

### BASE - Baseline & Classification (3 Fields)
**Script 12: Baseline Manager**

- BASEBusinessCriticality (Dropdown) - Business importance classification
- BASEDriftScore (Integer 0-100) - Configuration drift score
- BASEPerformanceBaseline (Text/JSON) - Performance baseline snapshot

**Purpose:** Device classification and drift detection

---

### DRIFT - Configuration Drift (1 Field)
**Script 13: Drift Detector**

- DRIFTNewAppsCount (Integer) - Count of new applications detected

**Purpose:** Shadow IT and configuration change detection

---

### SRV - Server Roles (1 Field)
**Script 15: Server Role Detector**

- SRVRole (Multi-select/Text) - Detected server roles

**Examples:** "SQL Server", "Domain Controller", "File Server", "Exchange"

---

### AD - Active Directory (2 Fields)
**Script 16: AD Integration Collector**

- ADLastLogonDays (Integer) - Days since last AD logon
- ADLastSyncStatus (Dropdown) - AD synchronization status

**Purpose:** AD health and device activity tracking

---

### SEC - Security Posture (1 Field)
**Script 17: Security Posture Assessor**

- SECSecurityPosture (Integer 0-100) - Security configuration score

**Native Integration:** Uses Antivirus Status, Firewall, Patches (native)

---

### GPO - Group Policy (1 Field)
**Script 18: GPO Performance Monitor**

- GPOLastApplyTimeSec (Integer) - GPO application time in seconds

**Purpose:** GPO performance and boot time analysis

---

### UX - User Experience (1 Field)
**Script 19: User Experience Collector**

- UXUserProfileSizeGB (Integer) - User profile size in GB

**Purpose:** Profile bloat detection and cleanup

---

### BAT - Battery Health (1 Field)
**Script 20: Battery Health Monitor**

- BATHealthPercent (Integer 0-100) - Battery health percentage

**Purpose:** Laptop battery degradation tracking

---

### STAT - Additional Telemetry (2 Fields)
**Script 6: Telemetry Collector (Extended)**

- STATCrashCount30d (Integer) - Total crash count (30d)
- STATAvgBootTimeSec (Integer) - Average boot time in seconds

**Purpose:** Extended stability and performance metrics

---

## FIELD COUNT SUMMARY

### Core Framework (Essential)
- **OPS Fields:** 6 (intelligence scoring)
- **STAT Fields:** 6 (custom telemetry)
- **RISK Fields:** 7 (risk classification)
- **Subtotal:** 19 core fields

### Extended Framework (Optional)
- **AUTO Fields:** 4 (automation control)
- **UPD Fields:** 4 (update management)
- **NET Fields:** 3 (network tracking)
- **CAP Fields:** 2 (capacity planning)
- **BASE Fields:** 3 (baseline & classification)
- **DRIFT Fields:** 1 (drift detection)
- **SRV Fields:** 1 (server roles)
- **AD Fields:** 2 (Active Directory)
- **SEC Fields:** 1 (security posture)
- **GPO Fields:** 1 (group policy)
- **UX Fields:** 1 (user experience)
- **BAT Fields:** 1 (battery health)
- **STAT Extended:** 2 (additional telemetry)
- **Subtotal:** 26 extended fields

### Infrastructure Modules (Role-Specific)
- **IIS/Web:** ~8 fields (web server monitoring)
- **MSSQL:** ~10 fields (SQL Server monitoring)
- **MYSQL:** ~8 fields (MySQL monitoring)
- **APACHE:** ~6 fields (Apache monitoring)
- **VEEAM:** ~8 fields (Veeam backup monitoring)
- **DHCP/DNS:** ~6 fields (DHCP/DNS monitoring)
- **Additional Roles:** ~20 fields (Exchange, Hyper-V, Print, etc.)
- **Subtotal:** ~66 infrastructure fields (optional, role-based)

### Total Framework
- **Essential Core:** 19 fields
- **Extended Core:** 26 fields
- **Infrastructure (Optional):** ~66 fields
- **Grand Total:** ~111 fields (down from 153 core + infrastructure)

**Reduction:** ~30% fewer fields overall by eliminating native metric duplicates

---

## SCRIPT EXECUTION SCHEDULE

### Every 4 Hours (High Frequency)
- Script 1: Health Score Calculator
- Script 2: Stability Analyzer
- Script 3: Performance Analyzer
- Script 6: Telemetry Collector
- Script 9: Risk Classifier

### Daily (Standard Frequency)
- Script 4: Security Analyzer
- Script 5: Capacity Analyzer
- Script 10: Update Assessment Collector
- Script 11: Network Location Tracker
- Script 12: Baseline Manager
- Script 13: Drift Detector
- Script 17: Security Posture Assessor
- Script 19: User Experience Collector
- Script 20: Battery Health Monitor

### Weekly (Low Frequency)
- Script 14: Automation Eligibility Assessor
- Script 15: Server Role Detector
- Script 22: Capacity Forecaster

### On-Demand / Triggered
- Script 16: AD Integration Collector (when domain-joined)
- Script 18: GPO Performance Monitor (during GPO apply)
- Infrastructure scripts (role-specific, conditional)

---

## NATIVE METRIC ACCESS PATTERNS

### For PowerShell Scripts (Direct Queries)

**CPU Utilization:**
```powershell
$cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
```

**Memory Utilization:**
```powershell
$os = Get-CimInstance Win32_OperatingSystem
$memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
```

**Disk Free Space:**
```powershell
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
$diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
```

**Device Uptime:**
```powershell
$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$uptimeDays = [math]::Floor($uptime.TotalDays)
```

**Service Status:**
```powershell
$service = Get-Service -Name "ServiceName" -ErrorAction SilentlyContinue
$serviceStatus = $service.Status  # Running, Stopped, etc.
```

---

## MIGRATION NOTES

### Updating Existing Scripts

**Scripts 1-5 (OPS Scorers):**
1. Replace custom field queries with native metric queries (see patterns above)
2. Keep calculation logic unchanged
3. Continue updating OPS score custom fields
4. Test on pilot devices before full deployment

**Script 6 (Telemetry):**
- No changes required - custom aggregation remains necessary

**Script 9 (Risk Classifier):**
1. Query native Backup Status instead of custom backup field
2. Query native SMART Status instead of custom disk health
3. Query native Pending Reboot instead of custom reboot detection
4. Keep risk classification logic unchanged

### Updating Compound Conditions

**Find and Replace:**
- `STATCPUAveragePercent > 90` → `CPU Utilization > 90% for 10 minutes`
- `STATMemoryPressure > 85` → `Memory Utilization > 85% for 15 minutes`
- `STATDiskFreePercent < 10` → `Disk Free Space < 10%`
- `OPSSystemOnline = False` → `Device Down = True`

---

**Version:** 4.0 (Native Integration)  
**Last Updated:** February 1, 2026, 5:04 PM CET  
**Total Custom Fields:** ~111 (down from ~153)  
**Core Custom Fields:** 19 (down from 45)  
**Active Scripts:** ~30 (down from 105+)  
**Deprecated Scripts:** 2 (Scripts 7-8)  
**Native Metrics Used:** 11+ categories  
**Status:** Production Ready
