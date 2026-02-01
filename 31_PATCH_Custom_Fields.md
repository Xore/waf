# PATCH Custom Fields - Detailed Documentation
**File:** 31_PATCH_Custom_Fields.md  
**Version:** 1.0  
**Field Count:** 8 fields  
**Last Updated:** February 1, 2026

---

## OVERVIEW

Custom fields for tracking patching eligibility, status, and compliance in the NinjaOne patching framework. These fields work in conjunction with NinjaOne's native patch management to provide server-focused automated patching.

---

## FIELD DEFINITIONS

### PATCHEligible
- **Type:** Dropdown
- **Values:** Eligible, Not Eligible, Manual Only, Excluded
- **Default:** Manual Only
- **Purpose:** Controls automated patching eligibility
- **Populated By:** Script P1 (Patching Eligibility Assessor)
- **Update Frequency:** Daily

**Value Definitions:**
- **Eligible:** Device approved for automated patching (servers only)
- **Not Eligible:** Device not meeting requirements for automation
- **Manual Only:** Requires manual approval for patches (workstations default)
- **Excluded:** Permanently excluded from automated patching

**Business Rules:**
```
IF Device Type = "Server" AND BASEBusinessCriticality IS SET
  THEN PATCHEligible = "Eligible"
ELSE IF Device Type = "Workstation"
  THEN PATCHEligible = "Manual Only"
ELSE
  PATCHEligible = "Not Eligible"
```

**Used In:**
- Dynamic Groups: All patch tier groups
- Compound Conditions: Pre-patch validation
- Automation Scripts: Script P1

---

### PATCHCriticality
- **Type:** Dropdown
- **Values:** Critical, Standard, Development, Test
- **Default:** (empty)
- **Purpose:** Determines patching schedule and maintenance window
- **Populated By:** Script P1 (mapped from BASEBusinessCriticality)
- **Update Frequency:** Daily or when BASEBusinessCriticality changes

**Value Definitions:**
- **Critical:** Mission-critical servers, weekly patching, 2-hour window
- **Standard:** Production servers, monthly patching, 4-hour window
- **Development:** Dev/test servers, monthly patching, flexible window
- **Test:** Test-only servers, as-needed patching

**Mapping from BASE Field:**
```
BASEBusinessCriticality = "Critical" → PATCHCriticality = "Critical"
BASEBusinessCriticality = "High" → PATCHCriticality = "Standard"
BASEBusinessCriticality = "Standard" → PATCHCriticality = "Standard"
BASEBusinessCriticality = "Low" → PATCHCriticality = "Development"
```

**Patch Schedules:**
- **Critical:** Every Sunday 2:00-4:00 AM
- **Standard:** 3rd Sunday of month 2:00-6:00 AM
- **Development:** 4th Sunday of month 2:00-6:00 AM
- **Test:** As needed (manual trigger)

**Used In:**
- Patch Policy Assignment
- Dynamic Groups: Tier-specific groups
- Maintenance Window Calculation

---

### PATCHMaintenanceWindow
- **Type:** Text (Single Line)
- **Max Length:** 50 characters
- **Format:** "Day HH:MM-HH:MM" or "DayOfWeek HH:MM-HH:MM"
- **Purpose:** Approved maintenance window for automated patching
- **Populated By:** Script P1 (based on PATCHCriticality)
- **Update Frequency:** Daily or when PATCHCriticality changes

**Format Examples:**
- "Sunday 02:00-04:00"
- "3rd Sunday 02:00-06:00"
- "4th Sunday 22:00-02:00"
- "Saturday 23:00-Sunday 03:00"

**Window Assignments by Criticality:**
```
Critical → "Sunday 02:00-04:00" (2-hour window, every week)
Standard → "3rd Sunday 02:00-06:00" (4-hour window, monthly)
Development → "4th Sunday 02:00-06:00" (4-hour window, monthly)
Test → "As Needed" (no scheduled window)
```

**Usage:**
- NinjaOne patch policies reference this field
- Pre-patch validation checks current time vs window
- Prevents out-of-window patch installations

---

### PATCHLastPatchDate
- **Type:** DateTime
- **Default:** (empty)
- **Format:** yyyy-MM-dd HH:mm:ss
- **Purpose:** Timestamp of last successful patch installation
- **Populated By:** Script P3 (Post-Patch Validation) + NinjaOne native
- **Update Frequency:** After each successful patch cycle

**Update Logic:**
```
1. NinjaOne completes patch installation
2. Server reboots (if required)
3. Script P3 runs post-patch validation
4. If validation passes:
   - Update PATCHLastPatchDate = Current DateTime
   - Log success
5. If validation fails:
   - Do NOT update PATCHLastPatchDate
   - Initiate rollback
```

**Compliance Calculation:**
```
Days Since Last Patch = (Current Date - PATCHLastPatchDate)

Compliance Status:
  0-30 days = Compliant
  31-60 days = Warning
  61-90 days = Non-Compliant
  > 90 days = Critical
```

**Used In:**
- Compound Conditions: Compliance alerts
- Dynamic Groups: Recent patches group
- Compliance Reports: Patch frequency analysis
- Dashboard Widgets: Last patch date display

---

### PATCHComplianceStatus
- **Type:** Dropdown
- **Values:** Compliant, Warning, Non-Compliant, Critical
- **Default:** Compliant
- **Purpose:** Overall patch compliance status
- **Populated By:** Script P4 (Patch Compliance Reporter)
- **Update Frequency:** Daily at 8:00 AM

**Status Definitions:**

**Compliant:**
- All critical patches applied
- All important patches applied
- Last patched < 30 days ago
- No pending critical updates

**Warning:**
- Some optional patches missing
- OR Last patched 30-60 days ago
- OR 1-2 important patches missing (non-critical)

**Non-Compliant:**
- 3+ important patches missing
- OR Last patched 61-90 days ago
- OR Critical patches available but not installed

**Critical:**
- 1+ critical security patches missing
- OR Last patched > 90 days ago
- OR Security vulnerability exposure

**Calculation Logic:**
```powershell
# Script P4 logic
$criticalMissing = (Get NinjaOne Patch Status).CriticalCount
$importantMissing = (Get NinjaOne Patch Status).ImportantCount
$daysSinceLastPatch = (Get-Date) - PATCHLastPatchDate

IF $criticalMissing > 0 OR $daysSinceLastPatch > 90
  THEN "Critical"
ELSE IF $importantMissing > 3 OR $daysSinceLastPatch > 60
  THEN "Non-Compliant"
ELSE IF $importantMissing > 0 OR $daysSinceLastPatch > 30
  THEN "Warning"
ELSE
  THEN "Compliant"
```

**Used In:**
- Compliance Dashboard
- Executive Reports
- Compound Conditions: Compliance violation alerts
- Dynamic Groups: Compliance-based groups

---

### PATCHMissingCriticalCount
- **Type:** Integer
- **Default:** 0
- **Range:** 0 to 999
- **Purpose:** Count of missing critical security patches
- **Populated By:** Script P4 (queries NinjaOne Patch Status native)
- **Update Frequency:** Daily at 8:00 AM

**Data Source:**
```powershell
# Query NinjaOne native patch data
$patchStatus = Get-NinjaOnePatchStatus -DeviceID $deviceId
$criticalMissing = $patchStatus | 
    Where-Object { $_.Severity -eq "Critical" -and $_.Status -eq "Missing" } |
    Measure-Object | 
    Select-Object -ExpandProperty Count

Ninja-Property-Set PATCHMissingCriticalCount $criticalMissing
```

**Thresholds:**
```
0 = Compliant (no missing critical patches)
1-2 = Warning (investigate and schedule patching)
3+ = Critical (immediate attention required)
```

**Impact on Compliance:**
- If PATCHMissingCriticalCount > 0 → PATCHComplianceStatus = "Critical"
- Triggers immediate compliance alert
- Escalated to management in daily report

**Used In:**
- Compound Conditions: PC5 (Critical Patches Missing)
- Compliance Dashboard (red flag indicator)
- Executive Reports (security exposure metric)
- Escalation Workflows

---

### PATCHLastFailureReason
- **Type:** Text (Multi-line)
- **Max Length:** 500 characters
- **Default:** (empty)
- **Purpose:** Detailed reason for last patch failure
- **Populated By:** Script P2 (Pre-Patch) or Script P3 (Post-Patch)
- **Update Frequency:** When validation fails or patch fails

**Common Failure Reasons:**

**Pre-Patch Failures (Script P2):**
- "Backup Status: Failed (last successful backup > 24 hours ago)"
- "Disk Space: Insufficient (C: drive has 8 GB free, requires 10 GB minimum)"
- "Pending Reboot: System has pending reboot from previous operation"
- "Service Baseline: Failed to capture running services list"

**Post-Patch Failures (Script P3):**
- "Service SQL Server failed to start after reboot"
- "Performance degradation: CPU utilization increased by 35% post-patch"
- "Event Log: 3 critical errors detected in last 30 minutes"
- "Application Health Check: IIS application pool stopped"

**Format:**
```
[Timestamp] [Validation Stage] [Failure Category]: [Detailed Reason]

Example:
2026-02-01 02:45:00 - Post-Patch - Service Failure: SQL Server (MSSQLSERVER) 
service failed to start after Windows Update KB5034441. Error: 
"The service did not respond to the start or control request in a timely fashion."
```

**Used In:**
- Troubleshooting dashboards
- Failure analysis reports
- Compound Conditions: PC1, PC2 (pre-patch failures)
- Alert notifications (included in alert text)
- Rollback decision-making

---

### PATCHPreValidationStatus
- **Type:** Dropdown
- **Values:** Passed, Failed, Not Run, In Progress
- **Default:** Not Run
- **Purpose:** Status of pre-patch validation checks
- **Populated By:** Script P2 (Pre-Patch Validation)
- **Update Frequency:** 2 hours before maintenance window

**Status Definitions:**

**Passed:**
- All pre-patch validation checks successful
- Backup verified (< 24 hours, successful)
- Disk space sufficient (> 10 GB free)
- Service baseline captured
- Performance baseline captured
- No pending reboots from previous issues

**Failed:**
- One or more validation checks failed
- PATCHLastFailureReason populated with details
- Patch installation deferred automatically
- Alert sent to administrators

**Not Run:**
- Validation hasn't executed yet (initial state)
- OR device not eligible for automated patching
- OR outside maintenance window

**In Progress:**
- Validation currently running
- Temporary state (< 5 minutes typically)

**Validation Flow:**
```
1. Maintenance window approaching (T-2 hours)
2. Script P2 triggered
3. PATCHPreValidationStatus = "In Progress"
4. Run all validation checks
5. IF all pass:
     PATCHPreValidationStatus = "Passed"
     Allow patch installation to proceed
   ELSE:
     PATCHPreValidationStatus = "Failed"
     Defer patch installation
     Send alert with PATCHLastFailureReason
```

**Used In:**
- Patch policy prerequisites (only patch if "Passed")
- Dynamic Groups: Servers eligible for patching
- Compound Conditions: PC1, PC2 (validation failures)
- Pre-patch dashboard

---

## FIELD RELATIONSHIPS

### Eligibility Chain
```
BASEBusinessCriticality (BASE field)
  ↓
PATCHCriticality (determines tier)
  ↓
PATCHMaintenanceWindow (assigns window)
  ↓
PATCHEligible = "Eligible" (enables automation)
  ↓
Dynamic Group Assignment (assigns to patch policy)
```

### Validation Chain
```
Maintenance Window Approaching (T-2 hours)
  ↓
Script P2: Pre-Patch Validation
  ↓
PATCHPreValidationStatus = "Passed" or "Failed"
  ↓
IF "Passed" → Proceed with patching
IF "Failed" → Defer + Alert
  ↓
NinjaOne Applies Patches
  ↓
Script P3: Post-Patch Validation
  ↓
IF Success → Update PATCHLastPatchDate
IF Failure → Populate PATCHLastFailureReason + Rollback
```

### Compliance Chain
```
Daily 8:00 AM: Script P4 Executes
  ↓
Query NinjaOne Patch Status (native)
  ↓
Calculate:
  - PATCHMissingCriticalCount
  - Days since PATCHLastPatchDate
  ↓
Determine PATCHComplianceStatus
  ↓
IF "Critical" or "Non-Compliant" → Trigger alerts
  ↓
Update Compliance Dashboard
```

---

## FIELD CREATION SCRIPT

```powershell
# NinjaRMM Custom Field Creation Script
# Run in NinjaRMM UI: Administration > Custom Fields > Import

$fields = @(
    @{
        Name = "PATCHEligible"
        Type = "DROPDOWN"
        Values = @("Eligible", "Not Eligible", "Manual Only", "Excluded")
        Default = "Manual Only"
    },
    @{
        Name = "PATCHCriticality"
        Type = "DROPDOWN"
        Values = @("Critical", "Standard", "Development", "Test")
    },
    @{
        Name = "PATCHMaintenanceWindow"
        Type = "TEXT"
        MaxLength = 50
    },
    @{
        Name = "PATCHLastPatchDate"
        Type = "DATETIME"
    },
    @{
        Name = "PATCHComplianceStatus"
        Type = "DROPDOWN"
        Values = @("Compliant", "Warning", "Non-Compliant", "Critical")
        Default = "Compliant"
    },
    @{
        Name = "PATCHMissingCriticalCount"
        Type = "INTEGER"
        Default = 0
    },
    @{
        Name = "PATCHLastFailureReason"
        Type = "WYSIWYG"
        MaxLength = 500
    },
    @{
        Name = "PATCHPreValidationStatus"
        Type = "DROPDOWN"
        Values = @("Passed", "Failed", "Not Run", "In Progress")
        Default = "Not Run"
    }
)

# Create each field
foreach ($field in $fields) {
    Write-Output "Creating field: $($field.Name)"
    # NinjaRMM API call to create custom field
    # (Use NinjaRMM UI or API depending on version)
}
```

---

## TROUBLESHOOTING

### Issue: PATCHEligible stuck on "Not Eligible"
**Cause:** BASEBusinessCriticality field not set  
**Solution:** Set BASEBusinessCriticality, then run Script P1 manually

### Issue: PATCHPreValidationStatus always "Failed"
**Cause:** Check PATCHLastFailureReason for specific failure  
**Common:** Backup not current or disk space low  
**Solution:** Address underlying issue, script will retry

### Issue: PATCHMissingCriticalCount not updating
**Cause:** Script P4 not running or NinjaOne patch scan not recent  
**Solution:** Trigger manual patch scan, then run Script P4

### Issue: PATCHComplianceStatus incorrect
**Cause:** PATCHLastPatchDate not updated after successful patch  
**Solution:** Check Script P3 logs, may need to manually update field

---

**Version:** 1.0  
**Last Updated:** February 1, 2026  
**Total Fields:** 8  
**Related Scripts:** P1, P2, P3, P4  
**Related Documents:** 30_PATCH_Main_Patching_Framework.md
