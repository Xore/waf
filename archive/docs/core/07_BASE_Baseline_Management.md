# NinjaRMM Custom Field Framework - Baseline Management
**File:** 07_BASE_Baseline_Management.md  
**Category:** BASE (Baseline Configuration Management)  
**Field Count:** 7 fields  
**Extracted From:** 14_BASE_SEC_UPD_Core_Security_Baseline.md

---

## Overview

Baseline management fields capture and track the initial configuration state of systems. These fields provide a foundation for configuration drift detection and change management.

---

## BASE - Baseline Management Fields

### BASEBaselineEstablished
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Initial configuration baseline captured
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Once, then validated daily

**Use Cases:**
- Track which devices have baseline captured
- Compliance requirement verification
- Configuration management readiness

---

### BASEBaselineDate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Date baseline was established
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Once
- **Format:** yyyy-MM-dd HH:mm:ss

**Use Cases:**
- Baseline age tracking
- Refresh cycle management
- Audit trail for configuration management

---

### BASESoftwareList
- **Type:** WYSIWYG
- **Purpose:** Baseline list of installed software
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Baseline establishment, refreshed quarterly

**Format:**
```
Application Name | Version | Install Date
Microsoft Office 365 | 16.0.14326 | 2025-01-15
Adobe Acrobat Reader | 2023.008.20421 | 2025-01-10
```

---

### BASEServiceList
- **Type:** WYSIWYG
- **Purpose:** Baseline list of Windows services
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Baseline establishment, refreshed quarterly

**Format:**
```
Service Name | Display Name | Startup Type | Status
wuauserv | Windows Update | Automatic | Running
Spooler | Print Spooler | Automatic | Running
```

---

### BASEProcessList
- **Type:** WYSIWYG
- **Purpose:** Baseline list of running processes
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Baseline establishment, refreshed quarterly

**Format:**
```
Process Name | Path | User Context
explorer.exe | C:\Windows\explorer.exe | SYSTEM
chrome.exe | C:\Program Files\Google\Chrome\Application\chrome.exe | User
```

---

### BASEStartupList
- **Type:** WYSIWYG
- **Purpose:** Baseline list of startup programs
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Baseline establishment, refreshed quarterly

**Format:**
```
Name | Command | Location
Microsoft OneDrive | C:\Users\User\AppData\Local\Microsoft\OneDrive\OneDrive.exe | HKCU\Run
```

---

### BASELocalAdmins
- **Type:** WYSIWYG
- **Purpose:** Baseline list of local administrators
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Baseline establishment, refreshed quarterly

**Format:**
```
Username | Full Name | Type
Administrator | Built-in Administrator | Local
Domain\ITAdmin | IT Administrator | Domain
```

---

## Script-to-Field Mapping

### Script 18: Baseline Establishment
**Execution:** Once (initial), On-demand (refresh)  
**Runtime:** ~2 minutes  
**Fields Updated:** All BASE fields

**Workflow:**
1. Check if baseline already established
2. Collect software inventory
3. Collect services configuration
4. Collect running processes
5. Collect startup programs
6. Collect local administrators
7. Set BASEBaselineEstablished = True
8. Set BASEBaselineDate = Current DateTime

---

## Compound Conditions

### Pattern 1: Baseline Not Established
```
Condition:
  BASEBaselineEstablished = False

Action:
  Priority: P3 Medium
  Automation: Run Script 18 (Baseline Establishment)
  Ticket: Baseline establishment required
```

### Pattern 2: Baseline Refresh Needed
```
Condition:
  BASEBaselineDate < (CurrentDate - 90 days)

Action:
  Priority: P4 Low
  Automation: Run Script 18 (Refresh Mode)
  Ticket: Baseline refresh recommended
```

---

**Total Fields:** 7 fields  
**Scripts Required:** 1 script (Script 18)  
**Related Categories:** DRIFT (Configuration Drift Detection)

---

**File:** 07_BASE_Baseline_Management.md  
**Last Updated:** February 2, 2026  
**Framework Version:** 3.0
