# NinjaRMM Custom Field Framework - AUTO Fields
**File:** 11_AUTO_Automation_Control.md
**Category:** AUTO (Automation Control)
**Description:** Automation control, remediation tracking, and safety monitoring

---

## Overview

Automation control fields enable automated remediation with safety controls, track remediation history, and monitor automation safety metrics for the Windows Automation Framework.

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

## Script Integration

### Script 40: Automation Safety Validator
**Execution:** Daily
**Runtime:** ~15 seconds
**Fields Updated:**
- AUTORemediationEnabled (validates)
- AUTORemediationCount30d
- AUTOFailedRemediations30d
- AUTOSafetyFlag

### All Remediation Scripts (41-105)
**Execution:** Triggered by conditions
**Runtime:** Varies
**Fields Updated:**
- AUTOLastRemediationDate
- AUTOLastRemediationAction

---

**Total Fields:** 7 fields
**Category:** AUTO (Automation Control)
**Last Updated:** February 2, 2026
