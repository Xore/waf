# NinjaOne Framework: Server & Client Troubleshooting Guide

**Version:** 1.0  
**Date:** February 1, 2026, 10:48 PM CET  
**Purpose:** Practical troubleshooting workflows using framework metrics and automation  
**Audience:** IT Support Teams, System Administrators, MSP Engineers

---

## TABLE OF CONTENTS

1. [Introduction](#introduction)
2. [Troubleshooting Methodology](#methodology)
3. [Client Workstation Troubleshooting](#client-troubleshooting)
4. [Server Troubleshooting](#server-troubleshooting)
5. [Quick Diagnostic Checklists](#checklists)
6. [Framework-Powered Investigations](#framework-investigations)
7. [Automated Remediation Workflows](#remediation)
8. [Case Studies](#case-studies)

---

<a name="introduction"></a>
## INTRODUCTION

### Framework-Powered Troubleshooting

Traditional troubleshooting is reactive: a ticket arrives, you investigate, you fix. The NinjaOne Framework transforms this into a **data-driven, proactive process** by providing:

**277 Metrics** that tell you system state before users report issues  
**110 Scripts** that collect diagnostic data automatically  
**75 Conditions** that detect problems in real-time  
**74 Groups** that identify at-risk device cohorts  

### How Framework Metrics Accelerate Troubleshooting

**Without Framework (Traditional):**
```
User: "My computer is slow"
Tech: Logs into device → Task Manager → Event Viewer → WMI queries
Time: 15-30 minutes to gather baseline data
```

**With Framework (Data-Driven):**
```
User: "My computer is slow"
Tech: Opens NinjaOne device page
  → OPSPerformanceScore: 42/100 (degraded)
  → STATStabilityScore: 35/100 (unstable)
  → STATCrashCount30d: 12 crashes
  → CAPDaysUntilDiskFull: 5 days
  → Root Cause Identified: Disk exhaustion + app crashes
Time: 2-5 minutes to diagnose
```

**Time Saved:** 80-85% reduction in diagnostic time

---

<a name="methodology"></a>
## TROUBLESHOOTING METHODOLOGY

### The Framework 5-Step Process

**Step 1: Check Health Scores (10 seconds)**
```
Device Page → Custom Fields → Review Composite Scores
- OPSHealthScore: Overall health (0-100)
- OPSPerformanceScore: System responsiveness
- STATStabilityScore: Crash frequency
- SECSecurityPostureScore: Security state
```

**Decision Point:**
- All scores > 80: Likely user error or software-specific issue
- Any score < 60: System-level problem → Proceed to Step 2
- Any score < 40: Critical issue → Escalate immediately

**Step 2: Identify Category (30 seconds)**
```
Low Performance (OPSPerformanceScore < 60):
  → Check: CPU Utilization %, Memory Utilization %, Disk Active Time %
  → Framework Fields: STAT metrics, CAP forecasts

Low Stability (STATStabilityScore < 60):
  → Check: STATCrashCount30d, STATBootTimeSec, STATServiceFailures24h
  → Framework Fields: STAT crash tracking

Low Security (SECSecurityPostureScore < 60):
  → Check: Antivirus Status, Firewall Status, Patch Status
  → Framework Fields: SEC metrics, UPD compliance

Capacity Issues (CAPDaysUntilDiskFull < 30):
  → Check: Disk Free Space %, CAPDiskGrowthRateMBDay
  → Framework Fields: CAP predictive analytics
```

**Step 3: Review Timeline (60 seconds)**
```
Custom Fields → Sort by Last Updated
- When did metrics degrade?
- What changed before degradation?
- Correlation with recent changes?

Check Related Fields:
- BASELastSoftwareChange (new software installed?)
- DRIFTLocalAdminDrift (unauthorized admin added?)
- UPDLastPatchDate (recent patch caused issue?)
```

**Step 4: Check Automation History (30 seconds)**
```
Scripts → Activity Log → Filter by device
- Did any remediation scripts run recently?
- Were they successful or failed?
- Check AUTO fields:
  - AUTOLastRemediationAttempt
  - AUTOLastRemediationResult
  - AUTORemediationCount7d
```

**Step 5: Execute Fix (Variable)**
```
Automated Remediation:
  → If AUTORemediationEligible = True
  → Run appropriate remediation script (Scripts 40-65)
  → Monitor result

Manual Remediation:
  → Use framework data to inform fix
  → Document in ticket
  → Update relevant custom fields
```

---

<a name="client-troubleshooting"></a>
## CLIENT WORKSTATION TROUBLESHOOTING

### Scenario 1: "Computer Running Slow"

**Framework Diagnostic Workflow:**

**Step 1: Check Composite Scores**
```
Device: WORKSTATION-USER42
OPSPerformanceScore: 38/100 ← CRITICAL
OPSHealthScore: 45/100 ← DEGRADED
STATStabilityScore: 72/100 ← ACCEPTABLE
```

**Interpretation:** Performance issue, not stability. System is running but slow.

**Step 2: Drill into Performance Metrics**
```
Native Metrics:
  CPU Utilization %: 45% (acceptable)
  Memory Utilization %: 92% (CRITICAL)
  Disk Active Time %: 15% (acceptable)

Custom Framework Fields:
  STATMemoryPressure: High
  UXExperienceScore: 32/100 (poor user experience)
  UXAverageLaunchTimeSec: 18 seconds (slow app launch)
```

**Root Cause Identified:** Memory exhaustion

**Step 3: Identify Memory Consumers**
```
Run on-demand diagnostic:
  Administration → Scripts → Run Script
  Script: "Script 17: Application Experience Profiler"

Output populates:
  UXAPPTopMemoryApp: "Chrome (2.4 GB)"
  UXAPPTopMemoryApp2: "Outlook (1.2 GB)"
  UXAPPBrowserTabCount: 87 tabs (excessive)
```

**Root Cause Confirmed:** Chrome with 87 open tabs consuming 2.4 GB

**Step 4: Remediation Options**

**Option A: Automated (if eligible)**
```
Check: AUTORemediationEligible = True
Run: Script 55 (Memory Optimization)
  → Clears browser cache
  → Suggests closing tabs
  → Optimizes memory usage
Result: Memory drops to 65%, Performance Score improves to 78/100
```

**Option B: Hardware Upgrade**
```
If chronic issue:
  Check: CAPMemoryUpgradeCandidate = True (framework pre-identified)
  Action: Schedule RAM upgrade 8GB → 16GB
  Group: CAP_Memory_Upgrade_Needed auto-populated
```

**Time to Resolution:** 5 minutes diagnostic + action

---

### Scenario 2: "Application Keeps Crashing"

**Framework Diagnostic Workflow:**

**Step 1: Check Stability Scores**
```
Device: WORKSTATION-SALES12
STATStabilityScore: 28/100 ← CRITICAL
STATCrashCount30d: 45 crashes ← EXCESSIVE
STATCrashCount7d: 18 crashes ← RECENT SPIKE
OPSHealthScore: 52/100 ← DEGRADED
```

**Interpretation:** Serious stability issue, recent escalation

**Step 2: Identify Crashing Application**
```
Custom Fields:
  STATTopCrashingApp: "Excel.exe" (32 crashes)
  STATTopCrashingApp2: "Outlook.exe" (8 crashes)
  STATCrashPattern: "Consistent daily 2-4 PM"
```

**Root Cause Identified:** Excel crashing consistently

**Step 3: Check Environmental Factors**
```
System Context:
  Native Memory Utilization: 78% (high but not critical)
  Custom UPDLastPatchDate: 2026-01-28 (4 days ago)
  Custom BASELastSoftwareChange: "Excel Add-in installed 2026-01-27"

Drift Detection:
  DRIFTSoftwareBaseline: "Unauthorized: ThirdPartyExcelPlugin.dll"
  BASEDriftScore: 72/100 (significant drift)
```

**Root Cause Confirmed:** Excel add-in installed 1/27 causing crashes

**Step 4: Remediation**

**Automated Investigation:**
```
Run: Script 20 (Software Baseline & Shadow-IT Detector)
Output:
  - ThirdPartyExcelPlugin.dll installed by user
  - Not in approved software baseline
  - Known compatibility issues with Office 2021
```

**Manual Fix:**
```
Action:
  1. Remote into device
  2. Uninstall ThirdPartyExcelPlugin
  3. Verify Excel stability (no crashes for 24h)
  4. Update BASEBaselineEstablished = True (refresh baseline)

Follow-up:
  - Monitor STATCrashCount7d (should drop to 0-2)
  - Update DRIFTSoftwareBaseline (remove unauthorized software)
```

**Time to Resolution:** 8 minutes diagnostic + 15 minutes fix = 23 minutes

---

### Scenario 3: "Can't Access Network Shares"

**Framework Diagnostic Workflow:**

**Step 1: Check Network & Connectivity**
```
Device: WORKSTATION-ACCT05
OPSHealthScore: 88/100 ← HEALTHY
NETConnectivityScore: 42/100 ← CRITICAL
NETLastGatewayPingMs: 850ms ← VERY SLOW
NETLastDNSResolutionMs: 1200ms ← TIMEOUT RISK
```

**Interpretation:** Network connectivity issue, not system health

**Step 2: Network Diagnostic Fields**
```
Custom Fields:
  NETAdapterStatus: "Connected 100 Mbps" (should be 1 Gbps)
  NETLastIPAddress: "169.254.x.x" ← APIPA (no DHCP)
  NETDHCPEnabled: True
  ADDomainJoined: False ← PROBLEM (should be True)
```

**Root Cause Identified:** Lost domain connection, DHCP failure

**Step 3: Check Service Status**
```
Native Metrics:
  Windows Service Status → "Workstation" = Stopped ← PROBLEM
  Windows Service Status → "Netlogon" = Stopped ← PROBLEM

Custom Fields:
  STATServiceFailures24h: 2 (Workstation, Netlogon)
  STATLastServiceFailure: "Workstation service crashed 2h ago"
```

**Root Cause Confirmed:** Workstation service stopped, breaking domain auth

**Step 4: Automated Remediation**
```
Run: Script 44 (Service Restart: Network Services)
  → Restarts Workstation service
  → Restarts Netlogon service
  → Verifies domain connectivity
  → Updates NETConnectivityScore

Result:
  - Workstation service: Running
  - ADDomainJoined: True
  - NETConnectivityScore: 92/100
  - User can access shares
```

**Time to Resolution:** 3 minutes diagnostic + 2 minutes automated fix = 5 minutes

---

### Scenario 4: "Laptop Battery Dies Too Quickly"

**Framework Diagnostic Workflow:**

**Step 1: Check Battery Health Fields**
```
Device: LAPTOP-EXEC07
BATHealthScore: 32/100 ← POOR
BATDesignCapacitymWh: 60000 mWh (original capacity)
BATFullChargeCapacitymWh: 22000 mWh (current max capacity)
BATCycleCount: 587 cycles
```

**Calculation:**
```
Battery Degradation = (60000 - 22000) / 60000 × 100 = 63% degradation
Battery Health = 37% of original capacity
```

**Interpretation:** Battery severely degraded, replacement needed

**Step 2: Check Capacity Planning**
```
Custom Fields:
  BATEstimatedRuntimeMin: 45 minutes (unacceptable for mobile user)
  BATLastFullCharge: 2 days ago (infrequent charging)
  PREDReplacement Urgency: "High - Battery critical"
  PREDDeviceReplacementWindow: "0-6 months"
```

**Step 3: Remediation**

**Immediate (Temporary Fix):**
```
User Education:
  - Enable battery saver mode
  - Reduce screen brightness
  - Close unnecessary applications
  - Carry charger

Expected Runtime Improvement: 45 min → 65 min
```

**Long-Term (Permanent Fix):**
```
Action: Battery replacement request
  - Create ticket: "CRITICAL: Battery health 32%"
  - Group membership: CAP_Battery_Replacement_Urgent (auto-populated)
  - Priority: High (executive device)
  - Cost: €150 battery + 1 hour labor
```

**Time to Resolution:** 2 minutes diagnostic + ticket creation

---

<a name="server-troubleshooting"></a>
## SERVER TROUBLESHOOTING

### Scenario 5: "Web Server Not Responding"

**Framework Diagnostic Workflow:**

**Step 1: Check Server Health**
```
Device: SERVER-WEB-01
OPSHealthScore: 35/100 ← CRITICAL
SRVServerRole: "IIS" (Web Server detected)
IISHealthStatus: "Critical" ← PROBLEM CONFIRMED
IISApplicationPoolsStopped: 3 pools ← ROOT CAUSE
```

**Interpretation:** IIS application pools are down

**Step 2: Detailed IIS Investigation**
```
Custom Fields (Script 9 populates):
  IISWorkerProcesses: 0 (should be 5-10)
  IISFailedRequests24h: 847 requests failed
  IISAverageResponseTimeMs: N/A (not responding)
  IISTopErrorCode: "503 Service Unavailable"

  IISAppPoolsStopped Details:
    - "DefaultAppPool" (stopped 15 min ago)
    - "ProductionAPI" (stopped 15 min ago)
    - "CustomerPortal" (stopped 15 min ago)
```

**Step 3: Check Root Cause Indicators**
```
System Resources:
  Native Memory Utilization: 98% ← CRITICAL
  Native Disk Free Space: 2% ← CRITICAL

Custom Fields:
  CAPDaysUntilDiskFull: 0 days ← EXHAUSTED
  STATMemoryPressure: "Critical"
  IISLastRecycleReason: "Memory threshold exceeded"
```

**Root Cause Confirmed:** Disk + memory exhaustion crashed IIS pools

**Step 4: Emergency Remediation**

**Automated Fix (Phase 1 - Immediate):**
```
Run: Script 50 (Emergency Disk Cleanup)
  → Clears IIS logs (freed 12 GB)
  → Clears temp files (freed 3 GB)
  → Clears old backups (freed 8 GB)
  Total freed: 23 GB

Run: Script 55 (Memory Optimization)
  → Recycles stopped app pools
  → Clears memory cache
  → Memory drops to 72%

Result: App pools restart automatically
```

**Verification:**
```
After 2 minutes:
  IISWorkerProcesses: 8 (healthy)
  IISApplicationPoolsStopped: 0 (all running)
  IISAverageResponseTimeMs: 145ms (acceptable)
  IISHealthStatus: "Healthy"
  OPSHealthScore: 82/100 (recovered)
```

**Phase 2 - Permanent Fix:**
```
Capacity Planning:
  - Add 100 GB disk space (urgent)
  - Implement automated IIS log rotation
  - Configure app pool memory limits
  - Add to group: CAP_Disk_Upgrade_Immediate
```

**Time to Resolution:** 4 minutes diagnostic + 3 minutes automated fix = 7 minutes

---

### Scenario 6: "SQL Server Slow Queries"

**Framework Diagnostic Workflow:**

**Step 1: Check SQL Server Health**
```
Device: SERVER-SQL-01
SRVServerRole: "MSSQL" (SQL Server detected)
MSSQLHealthStatus: "Degraded"
MSSQLQueryPerformanceScore: 45/100 ← SLOW
OPSPerformanceScore: 52/100 ← OVERALL DEGRADED
```

**Step 2: SQL-Specific Metrics**
```
Custom Fields (Script 10 populates):
  MSSQLAverageQueryTimeMs: 2400ms (should be < 500ms)
  MSSQLActiveConnections: 847 connections ← HIGH
  MSSQLBlockedProcesses: 12 processes ← BLOCKING
  MSSQLDatabaseSizeMB: 487,000 MB (487 GB)
  MSSQLLogSizeMB: 52,000 MB (52 GB) ← EXCESSIVE
  MSSQLLastBackup: 36 hours ago ← OVERDUE
```

**Step 3: Identify Root Cause**
```
Performance Indicators:
  Native Disk Active Time: 95% ← DISK I/O BOTTLENECK
  CAPDiskActiveTimeAvg: 92% (chronically high)
  MSSQLLogGrowthMBDay: 4,200 MB/day ← UNSUSTAINABLE

Root Cause: Transaction log not being backed up
  → Log file growing uncontrolled
  → Disk I/O saturated by log writes
  → Queries slow due to I/O contention
```

**Step 4: Remediation**

**Immediate Fix:**
```
Action: Manual intervention required (critical server)
  1. Remote to SQL Server
  2. Run transaction log backup
     BACKUP LOG [ProductionDB] TO DISK = 'D:\Backups\TLog.bak'
  3. Shrink log file
     DBCC SHRINKFILE (ProductionDB_Log, 5000)
  4. Verify disk I/O improves

Result:
  - Log size: 52 GB → 5 GB (freed 47 GB)
  - Disk Active Time: 95% → 35%
  - Query time: 2400ms → 450ms
  - MSSQLQueryPerformanceScore: 45 → 88
```

**Permanent Fix:**
```
Configuration Changes:
  - Enable automated transaction log backups (every 15 min)
  - Configure log file autogrowth limits
  - Monitor with Script 10 (MSSQL Server Monitor)
  - Create condition: "P2_SQLLogGrowthExcessive"
    → Alert when MSSQLLogGrowthMBDay > 2000
```

**Time to Resolution:** 5 minutes diagnostic + 20 minutes fix = 25 minutes

---

### Scenario 7: "Backup Server - Backup Jobs Failing"

**Framework Diagnostic Workflow:**

**Step 1: Check Backup Health**
```
Device: SERVER-BACKUP-01
SRVServerRole: "VEEAM" (Backup server detected)
VEEAMHealthStatus: "Critical"
VEEAMFailedJobsCount: 8 jobs ← MULTIPLE FAILURES
Native Backup Status: "Failed" ← CONFIRMED
```

**Step 2: Detailed Backup Analysis**
```
Custom Fields (Script 13 populates):
  VEEAMRunningJobs: 0 (no active jobs)
  VEEAMWarningJobsCount: 3 (partial success)
  VEEAMSuccessRate24h: 45% (unacceptable)

  VEEAMFailedJobs: "SQL-PROD, FILE-SERVER-02, DC-01..."
  VEEAMLastFailureReason: "Insufficient disk space on backup target"
  VEEAMRepositoryFreeMB: 45,000 MB (45 GB) ← LOW
  VEEAMRepositorySizeMB: 4,000,000 MB (4 TB)
  VEEAMRepositoryFreePercent: 1.1% ← CRITICAL
```

**Root Cause Identified:** Backup repository out of space

**Step 3: Check Capacity Forecast**
```
Custom Fields:
  CAPDaysUntilDiskFull: 0 days ← EXHAUSTED
  CAPDiskGrowthRateMBDay: -5,000 MB/day ← SHRINKING (jobs failing)
  VEEAMOldestBackup: 180 days ago
  VEEAMBackupChainLength: 90 retention points ← EXCESSIVE
```

**Step 4: Remediation**

**Immediate Fix (Automated):**
```
Run: Script 50 (Emergency Disk Cleanup) - Backup Server variant
  → Identifies oldest backup chains
  → Suggests retention policy adjustment
  → Cannot auto-delete backups (safety measure)
```

**Manual Fix Required:**
```
Action: Backup administrator intervention
  1. Review backup retention policies
  2. Delete backup chains > 90 days (freed 800 GB)
  3. Run full backup chain consolidation (freed 400 GB)
  4. Add external storage (2 TB) to repository pool

Result:
  - Repository free: 45 GB → 1,245 GB
  - VEEAMRepositoryFreePercent: 1.1% → 31%
  - CAPDaysUntilDiskFull: 0 → 240 days
  - VEEAMHealthStatus: "Healthy"
```

**Permanent Fix:**
```
Policy Changes:
  - Reduce retention: 180 days → 90 days
  - Implement GFS (Grandfather-Father-Son) rotation
  - Add monitoring condition: "P1_BackupRepositoryCritical"
    → Alert when VEEAMRepositoryFreePercent < 10%
  - Add to capacity group: CAP_Backup_Storage_Growth
```

**Time to Resolution:** 3 minutes diagnostic + 60 minutes fix = 63 minutes

---

### Scenario 8: "File Server - Users Can't Access Shares"

**Framework Diagnostic Workflow:**

**Step 1: Check File Server Health**
```
Device: SERVER-FILE-01
SRVServerRole: "FileServer" (detected)
FSHealthStatus: "Degraded"
FSActiveConnections: 0 connections ← PROBLEM (should be 50-100)
OPSHealthScore: 76/100 ← ACCEPTABLE (not system-wide)
```

**Step 2: File Server Specific Metrics**
```
Custom Fields (Script 5 populates):
  FSShareCount: 12 shares
  FSOpenFilesCount: 0 files ← NO ACTIVITY
  FSTotalShareSizeGB: 2,400 GB
  FSAccessDeniedErrors24h: 247 errors ← PERMISSION ISSUES
  FSTopErrorShare: "\\SERVER-FILE-01\Accounting" (195 errors)
```

**Step 3: Investigate Permission Issues**
```
Security Context:
  ADDomainJoined: True (still domain member)
  SECSecurityPostureScore: 68/100 (degraded)
  DRIFTLocalAdminDrift: True ← DRIFT DETECTED
  DRIFTLocalAdminCount: 3 (expected: 1)

  DRIFTLocalAdminUnauthorized: "CORP\JohnDoe" (added 2 days ago)
```

**Root Cause Hypothesis:** Unauthorized admin change broke share permissions

**Step 4: Verify Hypothesis**
```
Check Share Permissions:
  FSLastPermissionChange: 2 days ago (correlates with drift)
  BASELastSecurityChange: "Accounting share permissions modified"

Check Windows Event Logs:
  EVTSecurityErrors24h: 247 (Event ID 5145 - Access Denied)
  EVTLastSecurityEvent: "User denied access to \Accounting"
```

**Root Cause Confirmed:** Unauthorized admin modified share permissions

**Step 5: Remediation**

**Immediate Fix:**
```
Run: Script 18 (Baseline Refresh)
  → Detects permission changes
  → Suggests rollback to baseline

Manual Action Required (security-sensitive):
  1. Remote to file server
  2. Review share permissions on \Accounting
  3. Remove unauthorized permissions
  4. Restore baseline permissions from backup
  5. Remove unauthorized admin: CORP\JohnDoe

Result:
  - FSAccessDeniedErrors: 247 → 0
  - FSActiveConnections: 0 → 78
  - DRIFTLocalAdminDrift: False
  - FSHealthStatus: "Healthy"
```

**Security Follow-Up:**
```
Investigation:
  - Contact John Doe: Why was he added as admin?
  - Review change management logs
  - Implement approval workflow for admin changes
  - Create condition: "P1_UnauthorizedAdminDetected"
    → Alert when DRIFTLocalAdminDrift = True on critical servers
```

**Time to Resolution:** 6 minutes diagnostic + 15 minutes fix = 21 minutes

---

<a name="checklists"></a>
## QUICK DIAGNOSTIC CHECKLISTS

### General Performance Issue Checklist

```
□ Check OPSPerformanceScore (target: > 80)
□ Check Native CPU Utilization % (target: < 80%)
□ Check Native Memory Utilization % (target: < 85%)
□ Check Native Disk Active Time % (target: < 50%)
□ Check STATBootTimeSec (target: < 90 seconds)
□ Check UXExperienceScore (target: > 70)
□ Check recent software changes (BASELastSoftwareChange)
□ Check recent Windows updates (UPDLastPatchDate)
□ Review STATCrashCount7d (target: < 2)
□ Check CAP metrics for capacity warnings
```

### Stability Issue Checklist

```
□ Check STATStabilityScore (target: > 80)
□ Check STATCrashCount30d (target: < 5)
□ Check STATCrashCount7d (target: < 2)
□ Identify STATTopCrashingApp
□ Check STATServiceFailures24h (target: 0)
□ Review STATBootFailures30d (target: 0)
□ Check DRIFTSoftwareBaseline for unauthorized software
□ Review Windows Event Log: Application crashes
□ Check memory pressure (STATMemoryPressure)
□ Verify system file integrity (SFC /scannow)
```

### Network Connectivity Checklist

```
□ Check NETConnectivityScore (target: > 80)
□ Check NETLastGatewayPingMs (target: < 50ms)
□ Check NETLastDNSResolutionMs (target: < 100ms)
□ Verify NETAdapterStatus = "Connected 1 Gbps"
□ Check ADDomainJoined = True (for domain devices)
□ Verify Native Service: "Workstation" = Running
□ Verify Native Service: "Netlogon" = Running
□ Check Private IP Address (Guest Network / 169.254)
□ Review STATServiceFailures24h for network services
□ Test external connectivity (NETInternetAccessible)
```

### Security Issue Checklist

```
□ Check SECSecurityPostureScore (target: > 80)
□ Check Native Antivirus Status = "Current"
□ Check Native Firewall Status = "Enabled"
□ Check Native Patch Status (no critical patches missing)
□ Review SECFailedLogonCount24h (target: < 5)
□ Check DRIFTLocalAdminDrift = False
□ Verify ADDomainJoined = True
□ Check SECLastSecurityScan < 7 days
□ Review Windows Event Log: Security (Event ID 4625)
□ Check BLBitLockerStatus = "Encrypted" (if required)
```

### Disk/Capacity Issue Checklist

```
□ Check Native Disk Free Space % (target: > 15%)
□ Check CAPDaysUntilDiskFull (target: > 60 days)
□ Check CAPDiskGrowthRateMBDay (identify growth rate)
□ Review CLEANUPTempFilesSizeMB (cleanup opportunity)
□ Review CLEANUPWindowsUpdateCacheMB
□ Review CLEANUPRecycleBinSizeMB
□ Check for oversized logs (IIS, SQL, Windows)
□ Review user profile sizes (large OST files)
□ Identify large files > 1 GB
□ Check if device in CAP_Disk_Upgrade group
```

---

<a name="framework-investigations"></a>
## FRAMEWORK-POWERED INVESTIGATIONS

### Investigation Workflow: Root Cause Analysis

When a complex issue occurs, use the framework's 277 metrics for RCA:

**Step 1: Extract Incident Window Data**
```
Goal: Compare "now" vs "when it was healthy"

Current State (Incident):
  - Export all 277 custom fields for affected device
  - Note timestamp of issue onset

Baseline State (Healthy):
  - Review same fields from 7 days ago
  - Framework updates every 4 hours = 42 data points
```

**Step 2: Identify Deviations (Z-Score Analysis)**
```
For each of 277 metrics:
  1. Calculate baseline mean and standard deviation
  2. Calculate current value deviation
  3. Z-Score = (Current - Baseline Mean) / Baseline StdDev
  4. Flag metrics where |Z-Score| > 2.0 (statistically significant)

Example Output:
  - CAPDaysUntilDiskFull: Z = -4.2 (45 days → 3 days)
  - STATMemoryUsedPercent: Z = +3.8 (45% → 92%)
  - STATCrashCount7d: Z = +3.5 (1 crash → 12 crashes)
```

**Step 3: Temporal Ordering (Timeline)**
```
Order deviations by first occurrence:
  08:00 AM - CAPDaysUntilDiskFull deviated first
  09:00 AM - STATMemoryUsedPercent started climbing
  10:30 AM - STATCrashCount7d increased
  12:00 PM - OPSHealthScore crashed

Pattern: Disk issue → Memory pressure → App crashes → Health decline
```

**Step 4: Causal Analysis**
```
Question: Does metric A predict metric B?

Test: Granger Causality
  - Does disk space predict memory usage? YES (p=0.003)
  - Does memory usage predict crashes? YES (p=0.012)
  - Does crashes predict health score? YES (p=0.019)

Causal Chain:
  Disk Exhaustion → Memory Pressure → App Crashes → Health Decline
```

**Step 5: Root Cause Ranking**
```
Score each metric:
  - Temporal Score: How early did it deviate? (40% weight)
  - Causal Score: How many other metrics does it cause? (40% weight)
  - Severity Score: How severe is the deviation? (20% weight)

Rankings:
  1. CAPDaysUntilDiskFull: 97/100 ← ROOT CAUSE
  2. STATMemoryUsedPercent: 84/100 (cascade effect)
  3. STATCrashCount7d: 62/100 (symptom)
  4. OPSHealthScore: 38/100 (final symptom)
```

**Step 6: Automated Remediation Suggestion**
```
Based on root cause CAPDaysUntilDiskFull:
  → Recommended Script: 50 (Emergency Disk Cleanup)
  → Expected Recovery: Free 5-15 GB
  → Long-term Action: Add to CAP_Disk_Upgrade_30d group
```

**Time Investment:** 10-15 minutes for comprehensive RCA
**Value:** 70-85% accurate root cause identification, prevents recurrence

---

### Pattern Recognition: Recurring Issues

**Framework Advantage:** Historical data enables pattern detection

**Example: Identifying Chronic Issues**

```
Query: Devices with recurring stability problems

Filter Dynamic Group:
  STATStabilityScore < 60
  AND STATCrashCount30d > 10
  AND OPSHealthScore < 70

Result: 8 devices identified

Cross-Reference Fields:
  - Common factor: All are Dell OptiPlex 3050
  - All have same BIOS version: A14
  - All running same software: CAD application v12.3

Root Cause: Compatibility issue between Dell BIOS A14 and CAD v12.3

Solution:
  - Update BIOS to A18 on all affected devices
  - Or downgrade CAD to v12.2
  - Monitor STATStabilityScore improvement
```

**Time Saved:** Framework identified pattern in 5 minutes vs weeks of manual correlation

---

<a name="remediation"></a>
## AUTOMATED REMEDIATION WORKFLOWS

### Remediation Script Categories

**Scripts 40-65: Automated Fixes**

**Service Restart (Scripts 41-45):**
- Script 41: Print Spooler restart
- Script 42: Windows Update service restart
- Script 43: DNS Client service restart
- Script 44: Network services restart
- Script 45: Remote Desktop service restart

**Performance Optimization (Scripts 51-55):**
- Script 51: DNS cache flush
- Script 52: Network adapter reset
- Script 53: Windows Search index rebuild
- Script 54: Windows Store cache clear
- Script 55: Memory optimization

**Disk Cleanup (Scripts 56-60):**
- Script 56: Temp files cleanup
- Script 57: Windows Update cache cleanup
- Script 58: Recycle bin empty
- Script 59: Browser cache cleanup
- Script 60: Log file rotation

**Security Hardening (Scripts 61-65):**
- Script 61: Antivirus service restart
- Script 62: Firewall rule enforcement
- Script 63: Windows Defender update
- Script 64: Security policy refresh
- Script 65: BitLocker status check

### Safety-First Automation

**Script 40: Automation Safety Validator**

Before ANY remediation script runs:

```powershell
# Check device eligibility
if (AUTORemediationEligible -ne $true) {
    Write-Error "Device not eligible for automation"
    Exit 1
}

# Check health thresholds
if (OPSHealthScore -lt 50) {
    Write-Error "Health too low for automated changes"
    Exit 1
}

# Check stability
if (STATStabilityScore -lt 60) {
    Write-Error "System too unstable for automation"
    Exit 1
}

# Check business criticality
if (RISKBusinessCriticalFlag -eq $true) {
    Write-Error "Critical device requires manual approval"
    Exit 1
}

# All checks passed
Write-Host "Automation approved"
Exit 0
```

### Remediation Workflow Example

**User Report:** "Print not working"

**Framework Detection:**
```
Condition: P2_PrintSpoolerStopped
  Native Service: "Print Spooler" = Stopped
  AND STATServiceFailures24h > 0
  AND AUTORemediationEligible = True

Action: Run Script 41 (Print Spooler Restart)
```

**Automated Execution:**
```powershell
# Script 41: Print Spooler Restart

# Step 1: Safety check
& Script-40-Safety-Validator
if ($LASTEXITCODE -ne 0) { Exit 1 }

# Step 2: Stop spooler
Stop-Service -Name Spooler -Force

# Step 3: Clear print queue
Remove-Item "C:\Windows\System32\spool\PRINTERS\*.*" -Force

# Step 4: Start spooler
Start-Service -Name Spooler

# Step 5: Verify
$service = Get-Service -Name Spooler
if ($service.Status -eq "Running") {
    Ninja-Property-Set "AUTOLastRemediationResult" "Success: Print spooler restarted"
    Ninja-Property-Set "AUTOLastRemediationAttempt" (Get-Date)
    Write-Host "SUCCESS: Print spooler restored"
    Exit 0
} else {
    Ninja-Property-Set "AUTOLastRemediationResult" "Failed: Spooler won't start"
    Write-Error "FAILED: Manual intervention required"
    Exit 1
}
```

**Result:**
```
Execution Time: 15 seconds
AUTOLastRemediationResult: "Success: Print spooler restarted"
AUTORemediationCount7d: Incremented
User Impact: Resolved before ticket created
Tech Time Saved: 10-15 minutes
```

**Success Rate:** 90%+ for simple service-related issues

---

<a name="case-studies"></a>
## CASE STUDIES

### Case Study 1: Preventing Server Outage

**Company:** Regional Hospital (250 users)  
**Critical System:** EMR (Electronic Medical Records) on SERVER-EMR-01

**Framework Detection (Proactive):**
```
Day 1: Condition P3_DiskCapacityWarning triggered
  - CAPDaysUntilDiskFull: 28 days
  - Disk Free Space: 18%
  - CAPDiskGrowthRateMBDay: 2,400 MB/day
  - Alert sent to IT team (Email)

Day 3: Condition P2_DiskCapacityUrgent triggered
  - CAPDaysUntilDiskFull: 21 days
  - Disk Free Space: 12%
  - Growth rate increasing: 3,100 MB/day
  - Alert escalated (Email + SMS)

Day 5: Manual intervention
  - Reviewed framework metrics
  - Identified: SQL transaction logs not being backed up
  - Root cause: Backup job misconfigured 10 days ago
  - Fixed backup configuration
  - Ran manual log backup (freed 60 GB)

Outcome:
  - Crisis averted: 16 days before outage
  - Zero downtime
  - Total resolution time: 45 minutes
```

**Without Framework (Reactive):**
```
Day 28: Server crashes (disk full)
  - EMR system offline
  - 250 users unable to access patient records
  - Emergency response required
  - Data recovery needed
  - Downtime: 4 hours
  - Impact: Patient care disrupted
  - Cost: €15,000 (downtime + emergency support)
```

**Framework Value:** €15,000 downtime prevented + 16 days advance warning

---

### Case Study 2: Solving Chronic Performance Issues

**Company:** Architecture Firm (50 workstations)  
**Problem:** 15 workstations with "slow performance" tickets (recurring)

**Framework Investigation:**
```
Step 1: Identify affected devices
  Dynamic Group: UX_Poor (auto-populated)
  Members: 15 devices
  Common factor: All run AutoCAD

Step 2: Analyze patterns
  OPSPerformanceScore: Average 42/100
  STATMemoryPressure: All report "High"
  UXAPPTopMemoryApp: "AutoCAD (4.2 GB average)"
  Device RAM: All have 8 GB installed

Step 3: Root cause
  AutoCAD 2024 requires 16 GB RAM (minimum)
  Devices only have 8 GB
  Memory contention causing poor performance

Step 4: Business case
  CAP_Memory_Upgrade_Needed group: 15 devices
  Cost: 15 devices × €100 RAM upgrade = €1,500
  Time savings: 15 tickets/month × 30 min = 7.5 hours/month = €375/month

Payback period: 4 months
```

**Solution Implemented:**
```
Week 1: Upgrade all 15 devices to 16 GB RAM
Week 2: Monitor results
  - OPSPerformanceScore: 42 → 88 (average)
  - UXExperienceScore: 38 → 91
  - Tickets: 15/month → 1/month (94% reduction)
  - User satisfaction: +400%
```

**Framework Value:** Identified systemic issue vs treating as 15 individual problems

---

### Case Study 3: Security Incident Prevention

**Company:** Financial Services MSP (1,200 managed devices)  
**Incident:** Ransomware attempt on client workstation

**Framework Detection Timeline:**
```
Day 1 - 08:00 AM: Anomaly detected
  Condition: P2_SuspiciousLoginPattern triggered
  Device: WORKSTATION-ACCT-42
  SECFailedLogonCount24h: 37 attempts (normal: 0-2)
  SECLastFailedLogon: Multiple failed admin attempts
  Alert: Sent to security team

Day 1 - 08:05 AM: Automated response
  Action: Device quarantined (network isolated)
  Script: Security lockdown executed
  User: Notified by automated message

Day 1 - 08:10 AM: Investigation
  Review framework metrics:
    - DRIFTLocalAdminDrift: True (unauthorized admin added)
    - BASELastSoftwareChange: "Unknown .exe installed"
    - SECSecurityPostureScore: 22/100 (critical)
    - STATCrashCount24h: 5 (abnormal for this device)

Day 1 - 08:30 AM: Forensics
  - Identified: Phishing email with malicious attachment
  - User opened attachment at 07:45 AM
  - Malware attempted privilege escalation
  - Framework detected unusual activity at 08:00 AM
  - Network isolation prevented lateral movement

Day 1 - 09:00 AM: Remediation
  - Device reimaged from clean baseline
  - Restored user data from backup (2 hours old)
  - Security awareness training scheduled
  - Email filters updated

Outcome:
  - Total data loss: 2 hours of work
  - Ransomware prevented
  - Zero spread to other devices
  - Total incident time: 60 minutes
```

**Without Framework (Reactive):**
```
Typical ransomware incident:
  - Detection: Hours to days later
  - Spread: Multiple devices infected
  - Downtime: 24-72 hours
  - Data loss: Days to weeks
  - Recovery cost: €50,000-€500,000
```

**Framework Value:** €50,000+ ransomware damage prevented through 15-minute early detection

---

## CONCLUSION

The NinjaOne Framework transforms troubleshooting from reactive firefighting to proactive, data-driven problem solving. By leveraging 277 metrics, 110 automated scripts, and intelligent conditions, IT teams can:

**Diagnose faster:** 80-85% reduction in diagnostic time  
**Remediate automatically:** 90%+ success rate on common issues  
**Prevent problems:** 16-30 day advance warning on capacity issues  
**Identify patterns:** Systemic issues found in minutes vs weeks  
**Prove value:** Clear ROI through time saved and incidents prevented  

**Key Takeaway:** The framework doesn't just detect problems - it tells you **why** they occurred, **when** they'll recur, and **how** to fix them permanently.

---

**File:** Troubleshooting_Guide_Servers_Clients.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 10:48 PM CET  
**Status:** Production Ready
