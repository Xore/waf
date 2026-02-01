# NinjaRMM Custom Field Framework - Automation, UX, and Server Intelligence
**File:** 11_AUTO_UX_SRV_Core_Experience.md  
**Categories:** AUTO (Automation Control) + UX (User Experience) + SRV (Server Intelligence)  
**Field Count:** ~25 fields  
**Consolidates:** Original files 13, 14, 15

---

## Overview

Core fields for automation control, user experience monitoring, and server role intelligence. These fields enable automated remediation, track user experience quality, and identify server-specific configurations.

---

## AUTO - Automation Control Fields

### AUTORemediationEnabled
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Master switch to enable/disable automated remediation
- **Populated By:** Manual configuration or **Script 40** - Automation Safety Validator
- **Update Frequency:** Manual or daily validation

**Use Cases:**
- Gradual rollout of automation
- Maintenance windows (disable during critical periods)
- High-risk device exclusion
- Compliance requirements

---

### AUTORemediationLevel
- **Type:** Dropdown
- **Valid Values:** None, Basic, Standard, Advanced, Full
- **Default:** None
- **Purpose:** Granular control over automation scope
- **Populated By:** Manual configuration

**Level Definitions:**
```
None:
  - No automated actions
  - Manual intervention only

Basic:
  - Service restarts
  - Temp file cleanup
  - Event log clearing

Standard:
  - All Basic actions
  - Application restarts
  - Network adapter resets
  - Windows Update service repairs

Advanced:
  - All Standard actions
  - Disk cleanup
  - Profile repairs
  - Registry corrections

Full:
  - All Advanced actions
  - System restarts (with conditions)
  - Software installations/removals
  - Configuration changes
```

---

### AUTOLastRemediationDate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last automated remediation action
- **Populated By:** All remediation scripts
- **Update Frequency:** Real-time (when remediation occurs)
- **Format:** yyyy-MM-dd HH:mm:ss

---

### AUTOLastRemediationAction
- **Type:** Text
- **Max Length:** 500 characters
- **Default:** None
- **Purpose:** Description of last automated action taken
- **Populated By:** All remediation scripts
- **Update Frequency:** Real-time

**Format:**
```
[ScriptName] | [Action] | [Result]

Examples:
Script 45 | Restarted Windows Update service | Success
Script 48 | Cleared temp files (2.3 GB) | Success
Script 52 | Failed to restart Print Spooler | Failed - Service locked
```

---

### AUTORemediationCount30d
- **Type:** Integer
- **Default:** 0
- **Purpose:** Count of automated actions in last 30 days
- **Populated By:** **Script 40** - Automation Safety Validator
- **Update Frequency:** Daily
- **Range:** 0 to 9999

**Thresholds:**
```
0-5    = Low automation activity (normal)
6-15   = Moderate automation (acceptable)
16-30  = High automation (review recommended)
31+    = Very high (possible recurring issue)
```

---

### AUTOFailedRemediations30d
- **Type:** Integer
- **Default:** 0
- **Purpose:** Count of failed automation attempts in last 30 days
- **Populated By:** **Script 40** - Automation Safety Validator
- **Update Frequency:** Daily
- **Range:** 0 to 9999

---

### AUTOSafetyFlag
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Automation safety concern detected
- **Populated By:** **Script 40** - Automation Safety Validator
- **Update Frequency:** Daily

**Triggers:**
```
Set to True if:
  - AUTOFailedRemediations30d > 5
  - OR AUTORemediationCount30d > 50
  - OR Remediation caused system instability
  - OR Manual safety override
```

---

## UX - User Experience Core Fields

### UXBootTimeSeconds
- **Type:** Integer
- **Default:** 0
- **Purpose:** Most recent boot time in seconds
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Every 4 hours (after boot)
- **Range:** 0 to 9999 seconds
- **Measurement:** From BIOS handoff to desktop ready

**Performance Categories:**
```
0-30s    = Excellent (SSD with optimized startup)
31-60s   = Good (standard performance)
61-120s  = Fair (acceptable but improvable)
121-180s = Slow (user frustration likely)
181+s    = Very Slow (serious issue)
```

---

### UXLoginTimeSeconds
- **Type:** Integer
- **Default:** 0
- **Purpose:** Most recent user login time in seconds
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Every 4 hours (after login)
- **Range:** 0 to 9999 seconds
- **Measurement:** From credential entry to desktop usable

**Performance Categories:**
```
0-10s   = Excellent
11-20s  = Good
21-40s  = Fair
41-60s  = Slow
61+s    = Very Slow
```

---

### UXApplicationResponsiveness
- **Type:** Dropdown
- **Valid Values:** Excellent, Good, Fair, Poor, Critical
- **Default:** Good
- **Purpose:** Overall application responsiveness assessment
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Every 4 hours

**Assessment Logic:**
```
Excellent:
  - 0 hangs in 24h
  - All apps respond < 2s

Good:
  - 1-2 hangs in 24h
  - Most apps responsive

Fair:
  - 3-5 hangs in 24h
  - Occasional delays

Poor:
  - 6-10 hangs in 24h
  - Frequent delays

Critical:
  - 11+ hangs in 24h
  - Consistent unresponsiveness
```

---

### UXUserSatisfactionScore
- **Type:** Integer (0-100)
- **Default:** 75
- **Purpose:** Calculated user satisfaction score based on experience metrics
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Daily
- **Range:** 0 to 100

**Calculation:**
```
Base Score: 100

Deductions:
  - Boot time > 120s: -15 points
  - Login time > 40s: -10 points
  - Crashes per day: -5 points each (max -25)
  - Hangs per day: -3 points each (max -20)
  - Application responsiveness poor: -15 points
  - Network latency high: -10 points

Minimum Score: 0
```

---

### UXTopIssue
- **Type:** Text
- **Max Length:** 200 characters
- **Default:** None
- **Purpose:** Primary user experience issue identified
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Daily

**Example Values:**
```
Frequent application crashes (Outlook)
Slow boot time (avg 145 seconds)
High memory pressure causing slowdowns
Network latency affecting SaaS performance
Profile load issues extending login time
```

---

### UXLastUserFeedback
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last user-reported issue
- **Populated By:** Ticket integration or manual entry
- **Update Frequency:** Real-time
- **Format:** yyyy-MM-dd HH:mm:ss

---

## SRV - Server Intelligence Fields

### SRVServerRole
- **Type:** Dropdown
- **Valid Values:** Workstation, File Server, Domain Controller, Database Server, Web Server, Application Server, Print Server, Hyper-V Host, Other
- **Default:** Workstation
- **Purpose:** Primary server role classification
- **Populated By:** **Script 36** - Server Role Detector
- **Update Frequency:** Daily

**Detection Logic:**
```
Workstation:
  - Windows client OS (10, 11)
  - No server roles installed

File Server:
  - File Server role installed
  - OR large shared folders detected

Domain Controller:
  - Active Directory Domain Services role
  - NTDS service running

Database Server:
  - SQL Server, MySQL, PostgreSQL detected

Web Server:
  - IIS or Apache installed

Application Server:
  - Application-specific services
  - No other server role dominant

Print Server:
  - Print and Document Services role

Hyper-V Host:
  - Hyper-V role installed
  - Virtual machines present
```

---

### SRVRoleCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Number of server roles installed
- **Populated By:** **Script 36** - Server Role Detector
- **Update Frequency:** Daily
- **Range:** 0 to 50

---

### SRVCriticalService
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device hosts critical business services
- **Populated By:** Manual configuration or **Script 36** - Server Role Detector
- **Update Frequency:** Daily

**Auto-Detection Criteria:**
```
Set to True if:
  - Domain Controller
  - OR Database Server with production databases
  - OR Primary file server
  - OR Exchange Server
  - OR Other manually flagged critical services
```

---

### SRVMaintenanceWindow
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** Anytime
- **Purpose:** Preferred maintenance window for automated actions
- **Populated By:** Manual configuration
- **Update Frequency:** Manual

**Format:**
```
Examples:
Weekends 02:00-06:00
Daily 01:00-05:00
Monday-Friday 22:00-06:00
Manual approval required
```

---

### SRVUpgradeEligible
- **Type:** Checkbox
- **Default:** True
- **Purpose:** Device eligible for automated OS/application upgrades
- **Populated By:** Manual configuration
- **Update Frequency:** Manual

**Use Cases:**
- Exclude production servers from automatic upgrades
- Phased rollout control
- Testing/validation requirements
- Change control compliance

---

### SRVBackupStatus
- **Type:** Dropdown
- **Valid Values:** Current, Warning, Overdue, None, Unknown
- **Default:** Unknown
- **Purpose:** Backup status for server
- **Populated By:** **Script 13** - Veeam Backup Monitor or backup integration
- **Update Frequency:** Daily

**Status Definitions:**
```
Current:
  - Last backup < 24 hours
  - Backup successful

Warning:
  - Last backup 24-48 hours
  - OR backup completed with warnings

Overdue:
  - Last backup > 48 hours
  - OR backup failed

None:
  - No backup configured

Unknown:
  - Cannot determine backup status
```

---

### SRVMonitoringProfile
- **Type:** Dropdown
- **Valid Values:** Standard, Enhanced, Critical, Minimal
- **Default:** Standard
- **Purpose:** Monitoring intensity level for device
- **Populated By:** Manual configuration or **Script 36** - Server Role Detector
- **Update Frequency:** Daily

**Profile Definitions:**
```
Minimal:
  - Basic health checks only
  - Weekly script execution
  - P4 Low alert priority

Standard:
  - Standard monitoring (default)
  - Daily script execution
  - P3 Medium alert priority

Enhanced:
  - Increased monitoring frequency
  - Every 4 hours script execution
  - P2 High alert priority

Critical:
  - Maximum monitoring
  - Hourly checks for critical metrics
  - P1 Critical alert priority
  - 24/7 on-call escalation
```

---

## Script-to-Field Mapping

### Script 17: Application Experience Profiler
**Execution:** Every 4 hours  
**Runtime:** ~30 seconds  
**Fields Updated:**
- UXBootTimeSeconds
- UXLoginTimeSeconds
- UXApplicationResponsiveness
- UXUserSatisfactionScore
- UXTopIssue

### Script 36: Server Role Detector
**Execution:** Daily  
**Runtime:** ~25 seconds  
**Fields Updated:**
- SRVServerRole
- SRVRoleCount
- SRVCriticalService
- SRVMonitoringProfile

### Script 40: Automation Safety Validator
**Execution:** Daily  
**Runtime:** ~15 seconds  
**Fields Updated:**
- AUTORemediationEnabled (validates)
- AUTORemediationCount30d
- AUTOFailedRemediations30d
- AUTOSafetyFlag

### Script 13: Veeam Backup Monitor
**Execution:** Daily  
**Runtime:** ~20 seconds  
**Fields Updated:**
- SRVBackupStatus

### All Remediation Scripts (41-105)
**Execution:** Triggered by conditions  
**Runtime:** Varies  
**Fields Updated:**
- AUTOLastRemediationDate
- AUTOLastRemediationAction

---

## Integration Examples

### Automation Control Widget
```html
<div class="automation-widget">
  <h4>Automation Status</h4>
  <div>Enabled: {{AUTORemediationEnabled}}</div>
  <div>Level: {{AUTORemediationLevel}}</div>
  <div>Actions (30d): {{AUTORemediationCount30d}}</div>
  <div>Failed (30d): {{AUTOFailedRemediations30d}}</div>
  <div class="last-action">{{AUTOLastRemediationAction}}</div>
</div>
```

### User Experience Widget
```html
<div class="ux-widget">
  <h4>User Experience</h4>
  <div class="satisfaction-score {{class}}">{{UXUserSatisfactionScore}}</div>
  <div>Boot: {{UXBootTimeSeconds}}s | Login: {{UXLoginTimeSeconds}}s</div>
  <div>Responsiveness: {{UXApplicationResponsiveness}}</div>
  <div class="top-issue">{{UXTopIssue}}</div>
</div>
```

### Server Intelligence Widget
```html
<div class="server-widget">
  <h4>Server Information</h4>
  <div>Role: {{SRVServerRole}}</div>
  <div>Critical Service: {{SRVCriticalService}}</div>
  <div>Backup Status: {{SRVBackupStatus}}</div>
  <div>Monitoring: {{SRVMonitoringProfile}}</div>
  <div>Maintenance: {{SRVMaintenanceWindow}}</div>
</div>
```

---

## Compound Conditions

### Pattern 1: Automation Safety Concern
```
Condition:
  AUTOSafetyFlag = True
  OR AUTOFailedRemediations30d > 5

Action:
  Priority: P2 High
  Automation: Disable auto-remediation
  Ticket: Automation safety review required
  Assignment: RMM administrators
```

### Pattern 2: Poor User Experience
```
Condition:
  UXUserSatisfactionScore < 50
  OR UXBootTimeSeconds > 180

Action:
  Priority: P3 Medium
  Automation: UX improvement workflow
  Ticket: User experience degraded
  Assignment: Desktop support team
```

### Pattern 3: Critical Server Backup Overdue
```
Condition:
  SRVCriticalService = True
  AND SRVBackupStatus = "Overdue"

Action:
  Priority: P1 Critical
  Automation: Backup validation + trigger
  Ticket: Critical server backup failed
  Assignment: Backup team + management
```

---

**Total Fields This File:** ~25 fields  
**Scripts Required:** 5 scripts (Scripts 13, 17, 36, 40, 41-105)  
**Update Frequencies:** Every 4 hours, Daily, Real-time  
**Priority Level:** High (Core User Experience & Automation)

---

**File:** 11_AUTO_UX_SRV_Core_Experience.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete  
**Consolidates:** Original files 13, 14, 15
