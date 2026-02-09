# Task 1.2: Core Monitoring Scripts Deployment Guide

**Task:** Deploy 13 Core Monitoring Scripts  
**Phase:** 7.1 - Foundation Deployment  
**Priority:** P1 (Critical)  
**Status:** ⏸️ PENDING (Depends on Task 1.1)  
**Estimated Time:** 3-4 hours

---

## Overview

This guide provides deployment instructions for the 13 core monitoring scripts that populate the 50 core custom fields. These scripts form the foundation of the WAF monitoring system.

---

## Prerequisites

- [ ] Task 1.1 complete (50 core fields created)
- [ ] NinjaRMM admin access
- [ ] Scripts available in `/scripts/core/` directory
- [ ] Test devices identified for pilot

---

## Core Scripts Overview

### Script Categories

**Health Monitoring (4 scripts):**
- Script 1: Health Score Calculator
- Script 2: System Stability Monitor
- Script 3: Performance Metrics Collector
- Script 4: Security Posture Scanner

**Capacity & Updates (2 scripts):**
- Script 5: Capacity Monitor
- Script 6: Update Compliance Checker

**System Information (3 scripts):**
- Script 7: Uptime and Boot Time Tracker
- Script 8: Error Event Monitor
- Script 9: Device Information Collector

**Configuration Management (4 scripts):**
- Script 10: Group Policy Monitor
- Script 11: Network Connectivity Monitor
- Script 12: Baseline Manager
- Script 13: Configuration Manager

---

## Script 1: Health Score Calculator

### Purpose
Calculates overall device health score from multiple metrics.

### Fields Populated
- `opsHealthScore` (0-100)
- `opsOverallScore` (0-100)
- `opsLastHealthCheck` (Unix Epoch)
- `opsStatus` (Dropdown)

### Schedule
**Frequency:** Every 4 hours  
**Execution Context:** System  
**Timeout:** 60 seconds

### Dependencies
- Requires other scripts to run first (reads their field values)
- Should be scheduled AFTER Scripts 2, 3, 4, 5

### Configuration
```yaml
Script Name: WAF - Health Score Calculator
Category: Monitoring
Script Type: PowerShell
Execution Context: System
Timeout: 60 seconds
Schedule: Every 4 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 2: System Stability Monitor

### Purpose
Monitors system stability through event log analysis.

### Fields Populated
- `opsStabilityScore` (0-100)
- `statCrashCount30d` (Integer)
- `statErrorCount30d` (Integer)
- `statWarningCount30d` (Integer)
- `statRebootCount30d` (Integer)
- `statStabilityScore` (0-100)
- `statLastCrashDate` (Unix Epoch)

### Schedule
**Frequency:** Every 4 hours  
**Execution Context:** System  
**Timeout:** 90 seconds

### Configuration
```yaml
Script Name: WAF - System Stability Monitor
Category: Monitoring
Script Type: PowerShell
Execution Context: System
Timeout: 90 seconds
Schedule: Every 4 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 3: Performance Metrics Collector

### Purpose
Collects CPU, memory, and disk performance metrics.

### Fields Populated
- `opsPerformanceScore` (0-100)
- `statAvgCPUUsage` (0-100%)
- `statAvgMemoryUsage` (0-100%)
- `statAvgDiskUsage` (0-100%)

### Schedule
**Frequency:** Every 4 hours  
**Execution Context:** System  
**Timeout:** 60 seconds

### Configuration
```yaml
Script Name: WAF - Performance Metrics Collector
Category: Monitoring
Script Type: PowerShell
Execution Context: System
Timeout: 60 seconds
Schedule: Every 4 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 4: Security Posture Scanner

### Purpose
Scans security configuration and calculates security score.

### Fields Populated
- `opsSecurityScore` (0-100)
- `secAntivirusEnabled` (Checkbox)
- `secAntivirusProduct` (Text)
- `secAntivirusUpdated` (Checkbox)
- `secFirewallEnabled` (Checkbox)
- `secBitLockerEnabled` (Checkbox)
- `secSecureBootEnabled` (Checkbox)
- `secTPMEnabled` (Checkbox)
- `secLastSecurityScan` (Unix Epoch)
- `secVulnerabilityCount` (Integer)
- `secComplianceStatus` (Dropdown)

### Schedule
**Frequency:** Every 4 hours  
**Execution Context:** System  
**Timeout:** 90 seconds

### Configuration
```yaml
Script Name: WAF - Security Posture Scanner
Category: Security
Script Type: PowerShell
Execution Context: System
Timeout: 90 seconds
Schedule: Every 4 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 5: Capacity Monitor

### Purpose
Monitors disk and memory capacity, forecasts usage.

### Fields Populated
- `opsCapacityScore` (0-100)
- `capDiskFreeGB` (Integer)
- `capDiskFreePercent` (0-100%)
- `capDiskTotalGB` (Integer)
- `capMemoryTotalGB` (Integer)
- `capMemoryUsedGB` (Integer)
- `capMemoryUsedPercent` (0-100%)
- `capCPUCores` (Integer)
- `capCPUThreads` (Integer)
- `capWarningLevel` (Dropdown)
- `capForecastDaysFull` (Integer)

### Schedule
**Frequency:** Every 8 hours  
**Execution Context:** System  
**Timeout:** 60 seconds

### Configuration
```yaml
Script Name: WAF - Capacity Monitor
Category: Monitoring
Script Type: PowerShell
Execution Context: System
Timeout: 60 seconds
Schedule: Every 8 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 6: Update Compliance Checker

### Purpose
Checks Windows Update compliance and missing patches.

### Fields Populated
- `updComplianceStatus` (Dropdown)
- `updMissingCriticalCount` (Integer)
- `updMissingImportantCount` (Integer)
- `updLastPatchDate` (Unix Epoch)
- `updLastPatchCheck` (Unix Epoch)

### Schedule
**Frequency:** Every 8 hours  
**Execution Context:** System  
**Timeout:** 120 seconds

### Configuration
```yaml
Script Name: WAF - Update Compliance Checker
Category: Updates
Script Type: PowerShell
Execution Context: System
Timeout: 120 seconds
Schedule: Every 8 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 7: Uptime and Boot Time Tracker

### Purpose
Tracks system uptime and last boot time.

### Fields Populated
- `opsUptime` (Seconds)
- `opsUptimeDays` (Days)
- `opsLastBootTime` (Unix Epoch)

### Schedule
**Frequency:** Every 4 hours  
**Execution Context:** System  
**Timeout:** 30 seconds

### Configuration
```yaml
Script Name: WAF - Uptime and Boot Time Tracker
Category: Monitoring
Script Type: PowerShell
Execution Context: System
Timeout: 30 seconds
Schedule: Every 4 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 8: Error Event Monitor

### Purpose
Monitors Windows event logs for errors and warnings.

### Fields Populated
- `statErrorCount30d` (Integer) - supplemental
- `statWarningCount30d` (Integer) - supplemental

### Schedule
**Frequency:** Every 2 hours  
**Execution Context:** System  
**Timeout:** 90 seconds

### Configuration
```yaml
Script Name: WAF - Error Event Monitor
Category: Monitoring
Script Type: PowerShell
Execution Context: System
Timeout: 90 seconds
Schedule: Every 2 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 9: Device Information Collector

### Purpose
Collects device hardware and OS information.

### Fields Populated
- `opsDeviceAge` (Seconds)
- `opsDeviceAgeMonths` (Months)
- `capCPUCores` (Integer) - supplemental
- `capCPUThreads` (Integer) - supplemental
- `statUpgradeAvailable` (Checkbox)

### Schedule
**Frequency:** Daily (once per day)  
**Execution Context:** System  
**Timeout:** 60 seconds

### Configuration
```yaml
Script Name: WAF - Device Information Collector
Category: Inventory
Script Type: PowerShell
Execution Context: System
Timeout: 60 seconds
Schedule: Daily at 3:00 AM
Target: Pilot devices (Phase 7.1)
```

---

## Script 10: Group Policy Monitor

### Purpose
Monitors Group Policy application status.

### Fields Populated
- `opsNotes` (Text) - GPO status appended

### Schedule
**Frequency:** Daily (once per day)  
**Execution Context:** System  
**Timeout:** 60 seconds

### Configuration
```yaml
Script Name: WAF - Group Policy Monitor
Category: Configuration
Script Type: PowerShell
Execution Context: System
Timeout: 60 seconds
Schedule: Daily at 4:00 AM
Target: Pilot devices (Phase 7.1 - domain-joined only)
```

**Note:** Should only target domain-joined devices.

---

## Script 11: Network Connectivity Monitor

### Purpose
Monitors network connectivity and DNS resolution.

### Fields Populated
- `opsNotes` (Text) - Network status appended

### Schedule
**Frequency:** Every 4 hours  
**Execution Context:** System  
**Timeout:** 60 seconds

### Configuration
```yaml
Script Name: WAF - Network Connectivity Monitor
Category: Networking
Script Type: PowerShell
Execution Context: System
Timeout: 60 seconds
Schedule: Every 4 hours
Target: Pilot devices (Phase 7.1)
```

---

## Script 12: Baseline Manager

### Purpose
Establishes and tracks performance baselines.

### Fields Populated
- Various statistical fields for baselining

### Schedule
**Frequency:** Daily (once per day)  
**Execution Context:** System  
**Timeout:** 90 seconds

### Configuration
```yaml
Script Name: WAF - Baseline Manager
Category: Analytics
Script Type: PowerShell
Execution Context: System
Timeout: 90 seconds
Schedule: Daily at 2:00 AM
Target: Pilot devices (Phase 7.1)
```

---

## Script 13: Configuration Manager

### Purpose
Tracks configuration changes and drift.

### Fields Populated
- `opsNotes` (Text) - Configuration status

### Schedule
**Frequency:** Daily (once per day)  
**Execution Context:** System  
**Timeout:** 90 seconds

### Configuration
```yaml
Script Name: WAF - Configuration Manager
Category: Configuration
Script Type: PowerShell
Execution Context: System
Timeout: 90 seconds
Schedule: Daily at 1:00 AM
Target: Pilot devices (Phase 7.1)
```

---

## Deployment Sequence

### Step-by-Step Deployment

**Phase 1: Upload Scripts (30 minutes)**

1. Navigate to Administration > Automation > Scripts
2. Upload each script file from `/scripts/core/` directory
3. Configure script metadata (name, category, timeout)
4. Save each script

**Phase 2: Create Automation Policies (1 hour)**

1. Navigate to Automation > Scheduled Automations
2. Create policy: "WAF Core - Every 2 Hours"
   - Scripts: 8
   - Schedule: Every 2 hours
   - Target: Pilot devices

3. Create policy: "WAF Core - Every 4 Hours"
   - Scripts: 1, 2, 3, 4, 7, 11
   - Schedule: Every 4 hours (stagger by 15 minutes)
   - Target: Pilot devices

4. Create policy: "WAF Core - Every 8 Hours"
   - Scripts: 5, 6
   - Schedule: Every 8 hours
   - Target: Pilot devices

5. Create policy: "WAF Core - Daily"
   - Scripts: 9 (3 AM), 12 (2 AM), 13 (1 AM), 10 (4 AM)
   - Schedule: Daily at specified times
   - Target: Pilot devices

**Phase 3: Enable Policies (15 minutes)**

1. Review each policy configuration
2. Enable "WAF Core - Daily" first
3. Wait 1 hour
4. Enable "WAF Core - Every 8 Hours"
5. Wait 1 hour
6. Enable "WAF Core - Every 4 Hours"
7. Wait 1 hour
8. Enable "WAF Core - Every 2 Hours"

**Phase 4: Monitor Initial Execution (1-2 hours)**

1. Monitor script execution logs
2. Check for errors
3. Verify field population begins
4. Document any issues

---

## Schedule Summary

### Execution Frequency Table

| Frequency | Scripts | Total Executions/Day |
|-----------|---------|---------------------|
| Every 2 hours | 1 script (#8) | 12 executions |
| Every 4 hours | 6 scripts (#1,2,3,4,7,11) | 36 executions |
| Every 8 hours | 2 scripts (#5,6) | 6 executions |
| Daily | 4 scripts (#9,10,12,13) | 4 executions |
| **Total** | **13 scripts** | **58 executions/day** |

### Daily Execution Timeline

```
00:00 - Scripts 2,3,4,7,11 (Every 4h)
01:00 - Script 13 (Daily)
02:00 - Script 8 (Every 2h), Script 12 (Daily)
03:00 - Script 9 (Daily)
04:00 - Scripts 2,3,4,7,11 (Every 4h), Script 10 (Daily), Script 1 (after others)
05:00 - Scripts 5,6 (Every 8h)
06:00 - Script 8 (Every 2h)
08:00 - Scripts 2,3,4,7,11 (Every 4h), Script 1
10:00 - Script 8 (Every 2h)
12:00 - Scripts 2,3,4,7,11 (Every 4h), Script 1
13:00 - Scripts 5,6 (Every 8h)
14:00 - Script 8 (Every 2h)
16:00 - Scripts 2,3,4,7,11 (Every 4h), Script 1
18:00 - Script 8 (Every 2h)
20:00 - Scripts 2,3,4,7,11 (Every 4h), Script 1
21:00 - Scripts 5,6 (Every 8h)
22:00 - Script 8 (Every 2h)
```

---

## Validation Checklist

After deployment:

### Upload Validation
- [ ] All 13 scripts uploaded to NinjaRMM
- [ ] Script names match convention
- [ ] Categories assigned correctly
- [ ] Timeouts configured appropriately
- [ ] Execution context set to System

### Policy Validation
- [ ] 4 automation policies created
- [ ] Scripts assigned to correct policies
- [ ] Schedules configured correctly
- [ ] Pilot devices targeted
- [ ] Policies enabled in sequence

### Execution Validation (After 24 hours)
- [ ] All scripts executed at least once
- [ ] No timeout errors
- [ ] No permission errors
- [ ] Execution times < configured timeout
- [ ] Fields begin populating

---

## Troubleshooting

### Issue: Script Timeout
**Symptoms:** Script execution exceeds timeout  
**Solutions:**
- Increase timeout value (add 30 seconds)
- Optimize script performance
- Check for network latency issues

### Issue: Permission Denied
**Symptoms:** Script fails with access denied errors  
**Solutions:**
- Verify execution context is System
- Check local admin rights
- Review script permissions requirements

### Issue: Fields Not Populating
**Symptoms:** Scripts run but fields stay empty  
**Solutions:**
- Verify field names match exactly (case-sensitive)
- Check script logs for errors
- Verify Ninja-Property-Set commands executed
- Check field type compatibility

### Issue: High Resource Usage
**Symptoms:** Scripts consuming excessive CPU/memory  
**Solutions:**
- Stagger execution times more
- Reduce concurrent script execution
- Optimize script queries
- Increase execution intervals

---

## Performance Expectations

### Target Metrics

| Metric | Target | Acceptable | Warning |
|--------|--------|------------|----------|
| Avg Execution Time | < 30s | < 45s | > 60s |
| Success Rate | > 98% | > 95% | < 95% |
| CPU Usage Peak | < 30% | < 50% | > 50% |
| Memory Usage | < 100MB | < 200MB | > 200MB |

---

## Next Steps

After completing Task 1.2:

1. **Task 1.3** - Configure 5-10 pilot devices
2. **Wait 24 hours** - Allow scripts to execute and populate fields
3. **Task 1.4** - Validate field population and script performance

---

**Task Status:** ⏸️ Ready to Begin (After Task 1.1)  
**Prerequisites:** 50 core fields created  
**Estimated Time:** 3-4 hours  
**Next Task:** Task 1.3 - Pilot Device Configuration
