# NinjaRMM Custom Field Framework - Update Management
**File:** 11_UPD_Update_Management.md  
**Category:** UPD (Windows Update Management)  
**Field Count:** 6 fields  
**Extracted From:** 14_BASE_SEC_UPD_Core_Security_Baseline.md

---

## Overview

Update management fields track Windows Update compliance, missing patches, pending reboots, and overall patch status. Critical for security and system stability.

---

## UPD - Update Management Fields

### UPDLastWindowsUpdate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Date of last successfully installed Windows update
- **Populated By:** **Script 10** - Update Compliance Monitor (Note: Script 23 is Update Aging Tracker)
- **Update Frequency:** Daily
- **Format:** yyyy-MM-dd HH:mm:ss

**Use Cases:**
```
Compliance monitoring:
  - Track update cadence
  - Identify stale systems
  - Audit requirements

Thresholds:
  < 30 days = Compliant
  30-60 days = Review needed
  > 60 days = Non-compliant
```

---

### UPDPendingReboot
- **Type:** Checkbox
- **Default:** False
- **Purpose:** System restart required to complete update installation
- **Populated By:** **Script 10** - Update Compliance Monitor
- **Update Frequency:** Every 4 hours

**Detection Methods:**
```
Checks for:
  - HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired
  - HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending
  - Pending file rename operations
  - WMI CCM_ClientUtilities
```

---

### UPDMissingUpdatesCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Total count of missing Windows updates (all types)
- **Populated By:** **Script 10** - Update Compliance Monitor
- **Update Frequency:** Daily
- **Range:** 0 to 9999

**Categories Included:**
```
- Critical updates
- Security updates
- Important updates
- Optional updates
- Feature updates
```

---

### UPDMissingSecurityCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Count of missing security and critical updates
- **Populated By:** **Script 10** - Update Compliance Monitor
- **Update Frequency:** Daily
- **Range:** 0 to 9999

**Priority Updates:**
```
Includes:
  - Critical updates (system stability)
  - Security updates (vulnerability fixes)

Excludes:
  - Optional updates
  - Feature updates
  - Driver updates
```

**Thresholds:**
```
0 = Compliant
1-2 = Minor gap
3-5 = Significant gap
6+ = Critical gap
```

---

### UPDLastScanDate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Last successful Windows Update scan for available updates
- **Populated By:** **Script 10** - Update Compliance Monitor
- **Update Frequency:** Daily
- **Format:** yyyy-MM-dd HH:mm:ss

**Use Cases:**
```
Validation:
  - Confirm Windows Update service functioning
  - Detect scan failures
  - Monitor update service health

Alert if:
  LastScanDate > 7 days old
```

---

### UPDComplianceStatus
- **Type:** Dropdown
- **Valid Values:** Compliant, Minor Gap, Significant Gap, Critical Gap, Unknown
- **Default:** Unknown
- **Purpose:** Overall Windows Update compliance status
- **Populated By:** **Script 10** - Update Compliance Monitor
- **Update Frequency:** Daily

**Compliance Logic:**
```
Compliant:
  - UPDLastWindowsUpdate < 30 days
  - UPDMissingSecurityCount = 0
  - UPDLastScanDate < 7 days

Minor Gap:
  - UPDLastWindowsUpdate 30-45 days
  - OR UPDMissingUpdatesCount 1-3 (non-security)
  - AND UPDMissingSecurityCount = 0

Significant Gap:
  - UPDLastWindowsUpdate 45-90 days
  - OR UPDMissingSecurityCount 1-2
  - OR UPDMissingUpdatesCount 5+

Critical Gap:
  - UPDLastWindowsUpdate > 90 days
  - OR UPDMissingSecurityCount >= 3
  - OR UPDPendingReboot for > 14 days

Unknown:
  - Cannot determine status
  - Windows Update service error
  - Insufficient data
```

---

## Script-to-Field Mapping

### Script 10: Update Compliance Monitor
**Execution:** Daily (full scan), Every 4 hours (reboot check)  
**Runtime:** ~45 seconds  
**Fields Updated:** All UPD fields (6 fields)

**Monitoring Workflow:**
1. Check Windows Update service status
2. Query last installed update date
3. Scan for missing updates
4. Count security vs. non-security updates
5. Check for pending reboot
6. Calculate compliance status
7. Update all UPD fields

**Error Handling:**
```
If Windows Update service unavailable:
  - Set UPDComplianceStatus = Unknown
  - Log error details
  - Attempt service repair
```

**Note:** Original documentation incorrectly referenced Script 23 (which is Update Aging Tracker). Script 10 is the actual Update Compliance Monitor.

---

## Compound Conditions

### Pattern 1: Critical Updates Missing
```
Condition:
  UPDComplianceStatus = "Critical Gap"
  OR UPDMissingSecurityCount >= 3

Action:
  Priority: P1 Critical
  Automation: Force Windows Update scan and installation
  Ticket: Critical security updates missing
  Alert: Immediate escalation
```

### Pattern 2: Pending Reboot Extended
```
Condition:
  UPDPendingReboot = True
  AND (Current Date - UPDLastWindowsUpdate) > 14 days

Action:
  Priority: P2 High
  Automation: Schedule maintenance reboot
  Ticket: Pending reboot required for security updates
```

### Pattern 3: Update Service Failure
```
Condition:
  UPDLastScanDate > 7 days old
  OR UPDComplianceStatus = "Unknown"

Action:
  Priority: P2 High
  Automation: Repair Windows Update service
  Ticket: Windows Update service not functioning
```

### Pattern 4: Non-Compliant System
```
Condition:
  UPDLastWindowsUpdate > 60 days
  OR UPDComplianceStatus IN ("Significant Gap", "Critical Gap")

Action:
  Priority: P2 High
  Automation: Force update scan and install
  Ticket: System not compliant with update policy
```

---

## Integration Points

### Related Fields
- **SECAntivirusUpToDate** (antivirus definitions)
- **OPSHealthScore** (overall system health)
- **AUTORemediationEnabled** (automated patching)

### Automation Integration
```
If UPDMissingSecurityCount > 0:
  AND AUTORemediationEnabled = True
  AND AUTORemediationLevel >= "Standard"
  
  Then:
    - Trigger Windows Update installation
    - Schedule reboot during maintenance window
    - Monitor installation progress
```

---

## Best Practices

### Update Cadence
```
Recommended Schedule:
  - Security updates: Within 7 days of release
  - Critical updates: Within 14 days of release
  - Feature updates: Within 30 days of validation
```

### Reboot Management
```
Best Practices:
  - Schedule reboots during maintenance windows
  - Allow 48-72 hours for user-initiated reboot
  - Force reboot only for critical security patches
  - Notify users 24 hours in advance
```

---

**Total Fields:** 6 fields  
**Scripts Required:** 1 script (Script 10)  
**Related Categories:** SEC (Security), AUTO (Automation)

---

**File:** 11_UPD_Update_Management.md  
**Last Updated:** February 2, 2026  
**Framework Version:** 3.0
