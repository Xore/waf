# WAF Script Quick Reference

**Purpose:** Quick lookup for all WAF automation scripts  
**Total Scripts:** 110+  
**Last Updated:** February 9, 2026

---

## Core Monitoring Scripts (13)

### Script 1: Health Score Calculator
**File:** `01_Health_Score_Calculator.ps1`  
**Schedule:** Daily (1 AM)  
**Timeout:** 60 seconds  
**Purpose:** Calculate overall device health from component scores

**Fields Updated:**
- opsHealthScore
- opsOverallScore
- opsLastHealthCheck
- opsStatus

**Dependencies:** Must run AFTER Scripts 2-7 (needs component scores)

**Typical Duration:** 10-15 seconds

---

### Script 2: System Stability Monitor
**File:** `02_System_Stability_Monitor.ps1`  
**Schedule:** Every 4 hours  
**Timeout:** 90 seconds  
**Purpose:** Monitor system crashes, errors, and reboots

**Fields Updated:**
- opsStabilityScore
- statCrashCount30d
- statRebootCount30d
- statStabilityScore
- statLastCrashDate

**Dependencies:** None

**Typical Duration:** 20-30 seconds

**Notes:** Queries System and Application event logs

---

### Script 3: Performance Metrics Collector
**File:** `03_Performance_Metrics_Collector.ps1`  
**Schedule:** Every 4 hours  
**Timeout:** 60 seconds  
**Purpose:** Collect CPU, memory, disk performance metrics

**Fields Updated:**
- opsPerformanceScore
- statAvgCPUUsage
- statAvgMemoryUsage
- statAvgDiskUsage

**Dependencies:** None

**Typical Duration:** 15-25 seconds

**Notes:** Calculates averages from performance counters

---

### Script 4: Security Posture Scanner
**File:** `04_Security_Posture_Scanner.ps1`  
**Schedule:** Every 4 hours  
**Timeout:** 90 seconds  
**Purpose:** Scan security settings and compliance

**Fields Updated:**
- opsSecurityScore
- secAntivirusEnabled
- secAntivirusProduct
- secAntivirusUpdated
- secFirewallEnabled
- secBitLockerEnabled
- secSecureBootEnabled
- secTPMEnabled
- secLastSecurityScan
- secVulnerabilityCount
- secComplianceStatus

**Dependencies:** None

**Typical Duration:** 25-40 seconds

**Notes:** WMI queries for security state, BitLocker status

---

### Script 5: Capacity Monitor
**File:** `05_Capacity_Monitor.ps1`  
**Schedule:** Every 8 hours  
**Timeout:** 60 seconds  
**Purpose:** Monitor disk space, memory, CPU capacity

**Fields Updated:**
- opsCapacityScore
- capDiskFreeGB
- capDiskFreePercent
- capDiskTotalGB
- capMemoryTotalGB
- capMemoryUsedGB
- capMemoryUsedPercent
- capCPUCores
- capCPUThreads
- capWarningLevel
- capForecastDaysFull

**Dependencies:** None

**Typical Duration:** 15-20 seconds

**Notes:** Includes disk space growth forecasting

---

### Script 6: Update Compliance Checker
**File:** `06_Update_Compliance_Checker.ps1`  
**Schedule:** Every 8 hours  
**Timeout:** 120 seconds  
**Purpose:** Check Windows Update status and compliance

**Fields Updated:**
- updComplianceStatus
- updMissingCriticalCount
- updMissingImportantCount
- updLastPatchDate
- updLastPatchCheck
- statUpgradeAvailable

**Dependencies:** None

**Typical Duration:** 45-90 seconds

**Notes:** Slowest core script - queries Windows Update

---

### Script 7: Uptime Tracker
**File:** `07_Uptime_Tracker.ps1`  
**Schedule:** Every 4 hours  
**Timeout:** 30 seconds  
**Purpose:** Track system uptime and last boot time

**Fields Updated:**
- opsUptime
- opsUptimeDays
- opsLastBootTime

**Dependencies:** None

**Typical Duration:** 5-10 seconds

**Notes:** Very fast, simple WMI query

---

### Script 8: Error Event Monitor
**File:** `08_Error_Event_Monitor.ps1`  
**Schedule:** Every 2 hours  
**Timeout:** 90 seconds  
**Purpose:** Monitor error and warning events

**Fields Updated:**
- statErrorCount30d
- statWarningCount30d

**Dependencies:** None

**Typical Duration:** 20-35 seconds

**Notes:** Most frequent core script

---

### Script 9: Device Information Collector
**File:** `09_Device_Information_Collector.ps1`  
**Schedule:** Daily (3 AM)  
**Timeout:** 60 seconds  
**Purpose:** Collect device metadata and information

**Fields Updated:**
- opsDeviceAge
- opsDeviceAgeMonths
- uxPrimaryUser

**Dependencies:** None

**Typical Duration:** 10-20 seconds

**Notes:** Gathers basic system info

---

### Script 10: Group Policy Monitor
**File:** `10_Group_Policy_Monitor.ps1`  
**Schedule:** Daily (4 AM)  
**Timeout:** 60 seconds  
**Purpose:** Monitor Group Policy application status

**Fields Updated:**
- (Extended fields in Phase 7.2)

**Dependencies:** None

**Typical Duration:** 15-25 seconds

**Notes:** Uses GPResult for GP status

---

### Script 11: Network Monitor
**File:** `11_Network_Monitor.ps1`  
**Schedule:** Every 4 hours  
**Timeout:** 60 seconds  
**Purpose:** Monitor network connectivity and performance

**Fields Updated:**
- netConnectivityScore
- netPrimaryInterface
- netIPAddress
- netDNSServers
- netGateway
- netLatency
- netBandwidthUp
- netBandwidthDown
- netDisconnectCount30d
- netLastDisconnect

**Dependencies:** None

**Typical Duration:** 15-30 seconds

**Notes:** Network tests may add latency

---

### Script 12: Baseline Manager
**File:** `12_Baseline_Manager.ps1`  
**Schedule:** Daily (2 AM)  
**Timeout:** 90 seconds  
**Purpose:** Manage configuration baselines

**Fields Updated:**
- driftBaseline

**Dependencies:** None

**Typical Duration:** 20-40 seconds

**Notes:** Creates/updates baseline snapshots

---

### Script 13: Configuration Manager
**File:** `13_Configuration_Manager.ps1`  
**Schedule:** Daily (1 AM - runs first)  
**Timeout:** 90 seconds  
**Purpose:** Manage WAF configuration and state

**Fields Updated:**
- opsMonitoringEnabled

**Dependencies:** None

**Typical Duration:** 15-30 seconds

**Notes:** Initialization script

---

## Daily Execution Schedule

```
Time  | Scripts Running
------|----------------------------------
01:00 | Script 13 (Config Manager)
01:15 | Script 1 (Health Score)
02:00 | Script 12 (Baseline Manager)
02:00 | Script 8 (Error Monitor)
03:00 | Script 9 (Device Info)
04:00 | Script 8 (Error Monitor)
04:00 | Scripts 2,3,4,7,11 (4-hour cycle)
06:00 | Script 8 (Error Monitor)
06:00 | Script 5 (Capacity - 8-hour)
08:00 | Script 8 (Error Monitor)
08:00 | Scripts 2,3,4,7,11 (4-hour cycle)
10:00 | Script 8 (Error Monitor)
12:00 | Script 8 (Error Monitor)
12:00 | Scripts 2,3,4,7,11 (4-hour cycle)
14:00 | Script 8 (Error Monitor)
14:00 | Script 5 (Capacity - 8-hour)
14:00 | Script 6 (Updates - 8-hour)
16:00 | Script 8 (Error Monitor)
16:00 | Scripts 2,3,4,7,11 (4-hour cycle)
18:00 | Script 8 (Error Monitor)
20:00 | Script 8 (Error Monitor)
20:00 | Scripts 2,3,4,7,11 (4-hour cycle)
22:00 | Script 8 (Error Monitor)
22:00 | Script 5 (Capacity - 8-hour)
22:00 | Script 6 (Updates - 8-hour)
00:00 | Script 8 (Error Monitor)
00:00 | Scripts 2,3,4,7,11 (4-hour cycle)
```

**Total Daily Executions:** ~58 script runs per device

---

## Performance Targets

| Metric | Target | Alert If |
|--------|--------|----------|
| Average Execution Time | <30s | >45s |
| 95th Percentile Time | <60s | >90s |
| Success Rate | >95% | <90% |
| Timeout Rate | <2% | >5% |
| Error Rate | <3% | >10% |

---

## Troubleshooting Quick Guide

### Script Always Fails
1. Check error message in logs
2. Verify PowerShell version (need 5.1+)
3. Test script manually on device
4. Check execution context (should be SYSTEM)
5. Review timeout setting

### Script Times Out
1. Check typical duration vs timeout
2. Increase timeout by 50%
3. Optimize script queries
4. Check device performance

### Fields Not Populating
1. Verify script succeeds
2. Check field name matches (case-sensitive)
3. Verify Ninja-Property-Set command
4. Check field type compatibility

### Performance Impact
1. Review execution times
2. Check for concurrent execution
3. Stagger schedules more
4. Optimize slow queries

---

## Script Categories (Extended - Phase 7.2+)

### Risk & Drift (Scripts 14-15)
- Script 14: Risk Assessment Calculator
- Script 15: Configuration Drift Detector

### User Experience (Script 16)
- Script 16: User Experience Monitor

### Applications (Scripts 17-19)
- Script 17: Application Inventory Collector
- Script 18: Application Health Monitor
- Script 19: License Compliance Checker

### Backup (Scripts 20-21)
- Script 20: Backup Status Validator
- Script 21: Backup Performance Monitor

### Predictive (Scripts 22-24)
- Script 22: Failure Prediction Engine
- Script 23: Capacity Forecaster
- Script 24: Maintenance Scheduler

### Automation (Scripts 25-27)
- Script 25: Auto-Remediation Controller
- Script 26: Maintenance Window Manager
- Script 27: Change Control Integration

### Server Roles (Scripts 28-38)
- Script 28: IIS Web Server Monitor
- Script 29: SQL Server Monitor
- Script 30: Active Directory Monitor
- Script 31: Hyper-V Monitor
- Scripts 32-38: Additional server roles

### Patching (Scripts 39-43)
- Script 39: Patch Ring Manager
- Script 40: Patch Deployment Controller
- Script 41: Patch Validation Checker
- Script 42: Patch Rollback Manager
- Script 43: Patch Reporting

---

**Print Tip:** Print pages 1-4 for desk reference  
**Bookmark:** Save for quick troubleshooting access  
**Mobile:** Helpful for on-site work

**Last Updated:** February 9, 2026, 1:17 AM CET
