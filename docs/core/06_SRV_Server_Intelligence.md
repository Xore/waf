# NinjaRMM Custom Field Framework - SRV Fields
**File:** 06_SRV_Server_Intelligence.md
**Category:** SRV (Server Intelligence)
**Description:** Server role detection, backup monitoring, and service criticality

---

## Overview

Server intelligence fields identify server roles, track backup status, manage maintenance windows, and classify service criticality for the Windows Automation Framework.

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
- **Populated By:** **TBD: Veeam Backup Monitor** (not yet implemented - Script 13 is DRIFT Detector)
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

**Note:** Script 13 is actually DRIFT Detector, not Veeam Monitor. Veeam monitoring script needs to be implemented.

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

## Script Integration

### Script 36: Server Role Detector
**Execution:** Daily
**Runtime:** ~25 seconds
**Fields Updated:**
- SRVServerRole
- SRVRoleCount
- SRVCriticalService
- SRVMonitoringProfile

### TBD: Veeam Backup Monitor
**Status:** Not yet implemented
**Note:** Script 13 is DRIFT Detector, not Veeam Monitor
**Planned Execution:** Daily
**Planned Runtime:** ~20 seconds
**Fields to Update:**
- SRVBackupStatus

---

**Total Fields:** 7 fields
**Category:** SRV (Server Intelligence)
**Last Updated:** February 2, 2026
