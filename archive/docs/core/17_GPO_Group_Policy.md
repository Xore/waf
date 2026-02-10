# NinjaRMM Custom Field Framework - GPO Fields
**File:** 17_GPO_Group_Policy.md
**Category:** GPO (Group Policy)
**Description:** Group Policy application monitoring and compliance

---

## Overview

Group Policy fields monitor GPO application status, track applied policies, detect errors, and ensure domain policy compliance for the Windows Automation Framework.

**Critical Note:** Script 16 is Security Remediation, not Group Policy Monitor. GPO monitoring script needs to be implemented separately.

---

## GPO - Group Policy Core Fields

### GPOApplied
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device is domain-joined and receiving Group Policy
- **Populated By:** **TBD: Group Policy Monitor** (Script 16 conflict - Security Remediation)
- **Update Frequency:** Daily

### GPOLastApplied
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last successful GPO application
- **Populated By:** **TBD: Group Policy Monitor**
- **Update Frequency:** Daily
- **Format:** yyyy-MM-dd HH:mm:ss

### GPOCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Number of applied Group Policy Objects
- **Populated By:** **TBD: Group Policy Monitor**
- **Update Frequency:** Daily

### GPOErrorsPresent
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Group Policy errors detected
- **Populated By:** **TBD: Group Policy Monitor**
- **Update Frequency:** Daily

### GPOLastError
- **Type:** Text
- **Max Length:** 500 characters
- **Default:** None
- **Populated By:** **TBD: Group Policy Monitor**
- **Update Frequency:** Daily

### GPOAppliedList
- **Type:** WYSIWYG
- **Default:** Empty
- **Purpose:** HTML list of applied GPOs
- **Populated By:** **TBD: Group Policy Monitor**
- **Update Frequency:** Daily

---

## Script Integration

### TBD: Group Policy Monitor
**Status:** Not yet implemented (Script 16 is Security Remediation)
**Planned Execution:** Daily
**Planned Runtime:** ~30 seconds
**Fields to Update:** All GPO fields (6 fields)

**Critical Issue:** All 6 GPO fields have NO script support. Script 16 is Security Remediation, not GPO Monitor.

---

**Total Fields:** 6 fields
**Category:** GPO (Group Policy)
**Last Updated:** February 3, 2026
