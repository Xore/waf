# NinjaRMM Custom Field Framework - GPO Fields
**File:** 18_GPO_Group_Policy.md
**Category:** GPO (Group Policy)
**Description:** Group Policy application monitoring and compliance

---

## Overview

Group Policy fields monitor GPO application status, track applied policies, detect errors, and ensure domain policy compliance for the Windows Automation Framework.

---

## GPO - Group Policy Core Fields

### GPOApplied
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device is domain-joined and receiving Group Policy
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

### GPOLastApplied
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last successful GPO application
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily
- **Format:** yyyy-MM-dd HH:mm:ss

### GPOCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Number of applied Group Policy Objects
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

### GPOErrorsPresent
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Group Policy errors detected
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

### GPOLastError
- **Type:** Text
- **Max Length:** 500 characters
- **Default:** None
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

### GPOAppliedList
- **Type:** WYSIWYG
- **Default:** Empty
- **Purpose:** HTML list of applied GPOs
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

---

## Script Integration

### Script 16: Group Policy Monitor
**Execution:** Daily
**Runtime:** ~30 seconds
**Fields Updated:** All GPO fields

---

**Total Fields:** 6 fields
**Category:** GPO (Group Policy)
**Last Updated:** February 2, 2026
