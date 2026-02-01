# NinjaOne Patching Framework - Server-Focused Strategy
**Version:** 1.0  
**Last Updated:** February 1, 2026, 5:12 PM CET  
**Status:** Production Ready

---

## EXECUTIVE SUMMARY

This chapter extends the NinjaRMM Custom Field Framework v1.0 with a **server-focused patching strategy** that leverages NinjaOne's native Windows Update and software patching capabilities.

### Core Principles
- ✅ **Servers Only:** Automated patching restricted to servers
- ✅ **Workstations Excluded:** Manual approval required for workstations
- ✅ **Native NinjaOne Patching:** Uses built-in patch management
- ✅ **Business Criticality Aware:** Different schedules by server tier
- ✅ **Maintenance Windows:** Patches applied during approved windows only
- ✅ **Automated Rollback:** Failed patches trigger alerts and rollback
- ✅ **Compliance Tracking:** Automated patch compliance reporting

### Why Servers Only?
**Workstations:**
- User-facing devices require user coordination
- End-user disruption risk too high for automation
- Desktop applications may have compatibility issues
- Manual approval workflow preferred

**Servers:**
- Managed maintenance windows
- Controlled environments
- Predictable workloads
- Higher security compliance requirements
- Less user disruption

---

## FRAMEWORK COMPONENTS

### 1. Custom Fields (8 Fields)
**Prefix:** PATCH  
**Purpose:** Track patching eligibility, status, and compliance

### 2. Patching Policies (4 Policies)
- **Critical Servers:** Weekly patching (Sundays 2-4 AM)
- **Standard Servers:** Monthly patching (3rd Sunday 2-6 AM)
- **Development Servers:** Monthly patching (4th Sunday 2-6 AM)
- **Workstations:** Manual approval only (no automation)

### 3. Automation Scripts (4 Scripts)
- **Script P1:** Patching Eligibility Assessor
- **Script P2:** Pre-Patch Validation
- **Script P3:** Post-Patch Validation
- **Script P4:** Patch Compliance Reporter

### 4. Compound Conditions (12 Conditions)
- Pre-patch validation checks
- Post-patch failure detection
- Compliance violation alerts
- Patch window monitoring

### 5. Dynamic Groups (8 Groups)
- Servers by criticality (Critical/Standard/Dev)
- Patch compliance status
- Patch eligibility status
- Failed patch detection

---

## DOCUMENTATION STRUCTURE

### Essential Reading
1. **30_PATCH_Main_Patching_Framework.md** - This file, overview
2. **31_PATCH_Custom_Fields.md** - 8 custom fields for patch tracking
3. **32_PATCH_Policies_Configuration.md** - 4 patching policies setup
4. **33_PATCH_Automation_Scripts.md** - 4 automation scripts
5. **34_PATCH_Compound_Conditions.md** - 12 monitoring conditions
6. **35_PATCH_Dynamic_Groups.md** - 8 automated groups

### Quick Start Guides
- **36_PATCH_Quick_Start_Guide.md** - 30-minute deployment guide
- **37_PATCH_Server_Classification_How_To.md** - Classify servers by tier
- **38_PATCH_Maintenance_Windows_How_To.md** - Configure maintenance windows
- **39_PATCH_Troubleshooting_Guide.md** - Common issues and solutions

### Reference Documents
- **40_PATCH_Policy_Templates.md** - Copy-paste policy configurations
- **41_PATCH_Rollback_Procedures.md** - Failed patch rollback steps
- **42_PATCH_Compliance_Reporting.md** - Automated compliance reports
- **43_PATCH_Best_Practices.md** - Industry best practices

---

## PATCHING WORKFLOW

### Phase 1: Pre-Patch (Automated)
```
1. NinjaOne detects available patches
2. Script P1 checks server eligibility
3. Script P2 runs pre-patch validation:
   - Backup verification (must be < 24h old)
   - Disk space check (must be > 10 GB free)
   - Service status baseline snapshot
   - Performance baseline capture
4. If validation passes → Patch approved
5. If validation fails → Patch deferred + alert
```

### Phase 2: Patching (NinjaOne Native)
```
1. Maintenance window opens (e.g., Sunday 2 AM)
2. NinjaOne applies patches automatically:
   - Windows Updates (Critical, Important, Security)
   - Software updates (approved applications)
3. Server reboots if required
4. NinjaOne monitors reboot and service startup
```

### Phase 3: Post-Patch (Automated)
```
1. Script P3 runs post-patch validation (15 min after reboot):
   - All critical services running
   - Performance within baseline (+/- 20%)
   - No new errors in Event Log
   - Application health checks pass
2. If validation passes → Success logged
3. If validation fails → Alert + rollback initiated
```

### Phase 4: Compliance (Automated)
```
1. Script P4 runs daily compliance check:
   - Missing patches by severity
   - Days since last patch
   - Patch policy compliance
2. Update custom fields:
   - PATCHComplianceStatus
   - PATCHMissingCriticalCount
   - PATCHLastPatchDate
3. Generate compliance reports
```

---

## CUSTOM FIELD DEFINITIONS

### PATCHEligible
- **Type:** Dropdown
- **Values:** Eligible, Not Eligible, Manual Only, Excluded
- **Purpose:** Controls which devices can receive automated patches
- **Logic:**
  - Servers with BASEBusinessCriticality set → Eligible
  - Workstations → Manual Only (default)
  - Excluded devices → Excluded

### PATCHCriticality
- **Type:** Dropdown
- **Values:** Critical, Standard, Development, Test
- **Purpose:** Determines patching schedule and maintenance window
- **Mapping:**
  - Critical → Weekly patches (Sundays 2-4 AM)
  - Standard → Monthly patches (3rd Sunday 2-6 AM)
  - Development → Monthly patches (4th Sunday)
  - Test → As needed

### PATCHMaintenanceWindow
- **Type:** Text
- **Format:** "Day HH:MM-HH:MM" (e.g., "Sunday 02:00-04:00")
- **Purpose:** Approved maintenance window for patching
- **Examples:**
  - Critical servers: "Sunday 02:00-04:00"
  - Standard servers: "Sunday 02:00-06:00"
  - Dev servers: "Sunday 22:00-02:00"

### PATCHLastPatchDate
- **Type:** DateTime
- **Purpose:** Date/time of last successful patch application
- **Updated By:** NinjaOne native patching + Script P3
- **Format:** yyyy-MM-dd HH:mm:ss

### PATCHComplianceStatus
- **Type:** Dropdown
- **Values:** Compliant, Warning, Non-Compliant, Critical
- **Purpose:** Overall patch compliance status
- **Logic:**
  - Compliant: All critical patches applied, < 30 days old
  - Warning: Missing optional patches, or 30-60 days since last patch
  - Non-Compliant: Missing important patches, or 60-90 days
  - Critical: Missing critical patches, or > 90 days

### PATCHMissingCriticalCount
- **Type:** Integer
- **Purpose:** Count of missing critical security patches
- **Updated By:** Script P4 (queries NinjaOne Patch Status)
- **Threshold:** 0 = Compliant, 1-2 = Warning, 3+ = Critical

### PATCHLastFailureReason
- **Type:** Text (Multi-line)
- **Purpose:** Reason for last patch failure (if any)
- **Updated By:** Script P3 (post-patch validation)
- **Examples:**
  - "Service SQL Server failed to start after patch"
  - "Disk space insufficient (< 10 GB)"
  - "Backup older than 24 hours"

### PATCHPreValidationStatus
- **Type:** Dropdown
- **Values:** Passed, Failed, Not Run, In Progress
- **Purpose:** Status of pre-patch validation checks
- **Updated By:** Script P2 (pre-patch validation)

---

## PATCHING POLICIES

### Policy 1: Critical Servers - Weekly Patching
**Applies To:** Dynamic Group "Servers - Critical Tier"

**Patch Types:**
- Windows Updates: Critical, Security, Definition Updates
- Software Updates: Approved critical applications only

**Schedule:**
- **Day:** Every Sunday
- **Window:** 2:00 AM - 4:00 AM
- **Frequency:** Weekly

**Pre-Requisites:**
- PATCHEligible = "Eligible"
- PATCHCriticality = "Critical"
- PATCHPreValidationStatus = "Passed"
- Backup Status = Success (< 24 hours)

**Reboot Behavior:**
- Reboot if required: Yes
- Reboot delay: None (immediate)
- Force reboot: Yes (after 30 min if pending)

**Notifications:**
- Pre-patch: 24 hours before
- Post-patch: Success/failure within 1 hour
- Escalation: Critical failures to on-call team

---

### Policy 2: Standard Servers - Monthly Patching
**Applies To:** Dynamic Group "Servers - Standard Tier"

**Patch Types:**
- Windows Updates: Critical, Important, Security, Recommended
- Software Updates: All approved applications

**Schedule:**
- **Day:** 3rd Sunday of each month
- **Window:** 2:00 AM - 6:00 AM
- **Frequency:** Monthly

**Pre-Requisites:**
- PATCHEligible = "Eligible"
- PATCHCriticality = "Standard"
- PATCHPreValidationStatus = "Passed"

**Reboot Behavior:**
- Reboot if required: Yes
- Reboot delay: 15 minutes
- Force reboot: Yes (after 1 hour if pending)

---

### Policy 3: Development Servers - Monthly Patching
**Applies To:** Dynamic Group "Servers - Development Tier"

**Patch Types:**
- Windows Updates: All types
- Software Updates: All applications

**Schedule:**
- **Day:** 4th Sunday of each month (after standard servers)
- **Window:** 2:00 AM - 6:00 AM
- **Frequency:** Monthly

**Pre-Requisites:**
- PATCHEligible = "Eligible"
- PATCHCriticality = "Development"

**Reboot Behavior:**
- Reboot if required: Yes
- Reboot delay: None
- Force reboot: Yes

---

### Policy 4: Workstations - Manual Approval Only
**Applies To:** Dynamic Group "All Workstations"

**Patch Types:**
- Windows Updates: All types (manual approval)
- Software Updates: All applications (manual approval)

**Schedule:**
- **Automation:** Disabled
- **Approval:** Required for all patches
- **Installation:** User-initiated or manual deployment

**Behavior:**
- Patches detected and staged by NinjaOne
- Notifications sent to users
- IT approval required before installation
- User can defer patches (within policy limits)

---

## AUTOMATION SCRIPTS

### Script P1: Patching Eligibility Assessor
**Execution:** Daily at 6:00 AM  
**Runtime:** ~30 seconds per device  
**Purpose:** Determine which servers are eligible for automated patching

**Logic:**
```powershell
1. Check device type (Server vs Workstation)
2. If Workstation → PATCHEligible = "Manual Only"
3. If Server:
   a. Check BASEBusinessCriticality field
   b. Map to PATCHCriticality:
      - BASEBusinessCriticality = "Critical" → PATCHCriticality = "Critical"
      - BASEBusinessCriticality = "High" → PATCHCriticality = "Standard"
      - BASEBusinessCriticality = "Standard" → PATCHCriticality = "Standard"
   c. Set PATCHEligible = "Eligible"
   d. Set PATCHMaintenanceWindow based on criticality
4. Update custom fields
```

---

### Script P2: Pre-Patch Validation
**Execution:** 2 hours before maintenance window  
**Runtime:** ~45 seconds per device  
**Purpose:** Validate server readiness for patching

**Validation Checks:**
1. **Backup Verification:**
   - Query NinjaOne Backup Status
   - Must be "Success" and < 24 hours old
   - If failed → Defer patch + alert

2. **Disk Space Check:**
   - Query C: drive free space (native)
   - Must be > 10 GB free
   - If insufficient → Defer patch + alert

3. **Service Baseline:**
   - Capture list of running critical services
   - Store in baseline for post-patch comparison

4. **Performance Baseline:**
   - Capture CPU, Memory, Disk utilization (native)
   - Store for post-patch comparison

5. **Pending Reboot Check:**
   - Query Pending Reboot status (native)
   - If pending from previous issue → Alert (manual intervention)

**Result:**
- All checks pass → PATCHPreValidationStatus = "Passed"
- Any check fails → PATCHPreValidationStatus = "Failed" + defer patch + alert

---

### Script P3: Post-Patch Validation
**Execution:** 15 minutes after reboot  
**Runtime:** ~45 seconds per device  
**Purpose:** Validate server health after patching

**Validation Checks:**
1. **Service Validation:**
   - Compare running services to pre-patch baseline
   - Alert if critical services not running

2. **Performance Validation:**
   - Compare CPU, Memory, Disk to pre-patch baseline
   - Alert if deviation > 20%

3. **Event Log Check:**
   - Query System/Application logs for errors (last 30 min)
   - Alert if critical errors (Event ID 1000, 1001, etc.)

4. **Application Health Checks:**
   - Run custom health checks (from 70_Custom_Health_Check_Templates.md)
   - Alert if any fail

**Result:**
- All checks pass → Log success, update PATCHLastPatchDate
- Any check fails → Alert + initiate rollback + update PATCHLastFailureReason

---

### Script P4: Patch Compliance Reporter
**Execution:** Daily at 8:00 AM  
**Runtime:** ~20 seconds per device  
**Purpose:** Calculate patch compliance and update tracking fields

**Logic:**
```powershell
1. Query NinjaOne Patch Status (native):
   - Missing Critical patches
   - Missing Important patches
   - Missing Optional patches
2. Calculate days since last patch
3. Determine compliance status:
   - Critical patches missing OR > 90 days → "Critical"
   - Important patches missing OR > 60 days → "Non-Compliant"
   - Optional patches missing OR > 30 days → "Warning"
   - All current → "Compliant"
4. Update custom fields:
   - PATCHMissingCriticalCount
   - PATCHComplianceStatus
5. Generate report (if non-compliant)
```

---

## COMPOUND CONDITIONS

### Pre-Patch Conditions

#### PC1: Pre-Patch Validation Failed - Backup Missing
**Priority:** P2 High  
**Check Frequency:** Every 4 hours  
**Logic:**
```
PATCHEligible = "Eligible"
AND PATCHPreValidationStatus = "Failed"
AND PATCHLastFailureReason CONTAINS "backup"
AND Backup Status != "Success" (native)
```
**Action:** Alert + defer patch until backup successful

---

#### PC2: Pre-Patch Validation Failed - Insufficient Disk Space
**Priority:** P1 Critical  
**Check Frequency:** Every 1 hour  
**Logic:**
```
PATCHEligible = "Eligible"
AND PATCHPreValidationStatus = "Failed"
AND Disk Free Space < 10 GB (native)
```
**Action:** Alert + defer patch + disk cleanup automation

---

### Post-Patch Conditions

#### PC3: Post-Patch Service Failure
**Priority:** P1 Critical  
**Check Frequency:** Real-time  
**Logic:**
```
PATCHLastPatchDate within last 2 hours
AND Windows Service Status != "Running" (native, critical services)
AND STATServiceFailures24h > 0
```
**Action:** Critical alert + initiate rollback

---

#### PC4: Post-Patch Performance Degradation
**Priority:** P2 High  
**Check Frequency:** Every 15 minutes  
**Logic:**
```
PATCHLastPatchDate within last 4 hours
AND (CPU Utilization > 90% for 30 min OR Memory Utilization > 95%)
AND OPSPerformanceScore < 60
```
**Action:** Alert + performance investigation

---

### Compliance Conditions

#### PC5: Critical Patches Missing - Servers
**Priority:** P1 Critical  
**Check Frequency:** Daily  
**Logic:**
```
Device Type = "Server"
AND PATCHMissingCriticalCount > 0
AND PATCHComplianceStatus = "Critical"
```
**Action:** Critical compliance alert + escalate to management

---

#### PC6: Patch Compliance Warning - 60+ Days
**Priority:** P3 Medium  
**Check Frequency:** Daily  
**Logic:**
```
Device Type = "Server"
AND PATCHLastPatchDate > 60 days ago
AND PATCHComplianceStatus IN ("Warning", "Non-Compliant")
```
**Action:** Compliance warning + schedule manual patching

---

## DYNAMIC GROUPS

### Group 1: Servers - Critical Tier (Automated Patching)
**Purpose:** Critical servers eligible for weekly automated patching  
**Criteria:**
```
Device Type = "Server"
AND PATCHEligible = "Eligible"
AND PATCHCriticality = "Critical"
AND PATCHPreValidationStatus = "Passed"
```
**Patch Policy:** Policy 1 (Weekly, Sunday 2-4 AM)

---

### Group 2: Servers - Standard Tier (Automated Patching)
**Purpose:** Standard servers eligible for monthly automated patching  
**Criteria:**
```
Device Type = "Server"
AND PATCHEligible = "Eligible"
AND PATCHCriticality = "Standard"
AND PATCHPreValidationStatus = "Passed"
```
**Patch Policy:** Policy 2 (Monthly, 3rd Sunday 2-6 AM)

---

### Group 3: Servers - Development Tier (Automated Patching)
**Purpose:** Development servers eligible for monthly patching  
**Criteria:**
```
Device Type = "Server"
AND PATCHEligible = "Eligible"
AND PATCHCriticality = "Development"
```
**Patch Policy:** Policy 3 (Monthly, 4th Sunday)

---

### Group 4: Workstations - Manual Approval Required
**Purpose:** All workstations requiring manual patch approval  
**Criteria:**
```
Device Type = "Workstation"
OR PATCHEligible = "Manual Only"
```
**Patch Policy:** Policy 4 (Manual approval only)

---

### Group 5: Patch Compliance - Critical Violations
**Purpose:** Servers with critical patch compliance issues  
**Criteria:**
```
Device Type = "Server"
AND PATCHComplianceStatus = "Critical"
AND PATCHMissingCriticalCount > 0
```
**Use:** Compliance reporting and escalation

---

### Group 6: Patch Compliance - Non-Compliant
**Purpose:** Servers needing attention for patch compliance  
**Criteria:**
```
Device Type = "Server"
AND PATCHComplianceStatus IN ("Non-Compliant", "Warning")
AND PATCHLastPatchDate > 30 days ago
```
**Use:** Monthly compliance review

---

### Group 7: Pre-Patch Validation Failed
**Purpose:** Servers that failed pre-patch validation  
**Criteria:**
```
Device Type = "Server"
AND PATCHEligible = "Eligible"
AND PATCHPreValidationStatus = "Failed"
```
**Use:** Troubleshooting and remediation

---

### Group 8: Recent Patches - Last 7 Days
**Purpose:** Servers patched in last week for monitoring  
**Criteria:**
```
Device Type = "Server"
AND PATCHLastPatchDate within last 7 days
```
**Use:** Post-patch monitoring and validation

---

## DEPLOYMENT TIMELINE

### Week 1: Preparation
**Day 1-2: Field Creation**
- Create 8 PATCH custom fields in NinjaOne
- Document field purposes and values

**Day 3-4: Server Classification**
- Review all servers
- Set BASEBusinessCriticality (Critical/High/Standard)
- Map to PATCHCriticality tiers

**Day 5-7: Policy Planning**
- Define maintenance windows by server tier
- Get approval from stakeholders
- Document escalation procedures

### Week 2: Configuration
**Day 1-2: Script Deployment**
- Deploy Script P1 (Eligibility Assessor)
- Run manually on all devices
- Validate PATCHEligible and PATCHCriticality fields

**Day 3-4: Dynamic Groups**
- Create 8 dynamic groups
- Validate membership
- Verify servers in correct tiers

**Day 5-7: Patch Policies**
- Configure 4 patch policies in NinjaOne
- Assign to dynamic groups
- Test policy assignments

### Week 3: Testing
**Day 1-3: Development Tier Testing**
- Deploy Script P2 (Pre-Patch Validation) to dev servers
- Deploy Script P3 (Post-Patch Validation) to dev servers
- Run test patch cycle on development servers
- Validate pre/post checks

**Day 4-7: Standard Tier Testing**
- Test patch cycle on 2-3 standard tier servers
- Monitor for issues
- Validate rollback procedures
- Fine-tune thresholds

### Week 4: Production Rollout
**Day 1-2: Standard Tier Rollout**
- Enable patching for all standard tier servers
- Monitor first patch cycle
- Address any issues

**Day 3-4: Critical Tier Rollout**
- Enable patching for critical tier servers
- Extra monitoring during first cycle
- Validate success

**Day 5-7: Monitoring & Compliance**
- Deploy Script P4 (Compliance Reporter)
- Create compound conditions
- Set up compliance dashboards
- Documentation and training

**Total Timeline:** 4 weeks to full production

---

## ROLLBACK PROCEDURES

### Automated Rollback Triggers
- Critical service fails to start after patch
- Performance degradation > 20% after patch
- Critical application health check fails
- Event log shows critical errors

### Rollback Process
1. **Detection:** Script P3 detects failure (15 min post-reboot)
2. **Alert:** Critical alert sent to on-call team
3. **Automatic Actions:**
   - Uninstall last Windows Update (if identifiable)
   - Restore service baseline configuration
   - Restart affected services
4. **Validation:** Re-run post-patch checks
5. **Manual Intervention:** If auto-rollback fails, escalate

### Manual Rollback Steps
See **41_PATCH_Rollback_Procedures.md** for detailed steps

---

## SUCCESS METRICS

### Patch Compliance Targets
- **Critical Servers:** 100% compliant (0 missing critical patches)
- **Standard Servers:** 95% compliant (patched within 30 days)
- **Development Servers:** 90% compliant (patched within 60 days)
- **Workstations:** 85% compliant (manual patching)

### Operational Metrics
- **Patch Success Rate:** > 95% (first attempt success)
- **Rollback Rate:** < 2% (patches requiring rollback)
- **Pre-Validation Failure Rate:** < 5% (deferred due to pre-checks)
- **Mean Time to Patch:** < 14 days (critical patches)

### Business Metrics
- **Security Incident Reduction:** 30%+ reduction in patch-related incidents
- **Compliance Audit Success:** 100% pass rate
- **Downtime Reduction:** 50%+ reduction in patch-related downtime
- **Labor Savings:** 80+ hours/month saved on manual patching

---

## COMPLIANCE REPORTING

### Daily Compliance Dashboard
- Total servers by criticality tier
- Patch compliance status (Compliant/Warning/Critical)
- Missing critical patches count
- Servers needing attention

### Weekly Compliance Report
- Patch success rate (last 7 days)
- Failed patches and reasons
- Servers overdue for patching
- Pre-validation failure analysis

### Monthly Executive Report
- Overall patch compliance percentage
- Compliance trend (last 3 months)
- Security exposure reduction
- Cost savings from automation

### Audit Reports
- Patch history by server (last 12 months)
- Compliance status at any point in time
- Exception approvals and justifications
- Rollback incidents and resolutions

---

## BEST PRACTICES

### Server Classification
- Review and update criticality quarterly
- Document business justification for critical tier
- Limit critical tier to < 20% of servers (most manageable)

### Maintenance Windows
- Schedule during lowest business impact times
- Stagger windows across tiers (avoid all-at-once)
- Coordinate with backup windows (backup first)
- Allow 4-6 hour windows for standard servers

### Testing
- Always test patches on dev/test servers first
- Wait 1 week before applying to production
- Monitor vendor patch notes for known issues
- Maintain patch exclusion list for problematic updates

### Communication
- Notify stakeholders 24-48 hours before patching
- Send patch completion summary within 4 hours
- Escalate failures immediately
- Monthly compliance reports to management

### Continuous Improvement
- Review failed patches monthly
- Adjust thresholds based on false positives/negatives
- Update exclusion list quarterly
- Refine maintenance windows based on feedback

---

## RELATED FRAMEWORK COMPONENTS

This patching framework integrates with:
- **OPS Fields:** OPSHealthScore, OPSSecurityScore (impacted by patches)
- **RISK Fields:** RISKSecurityExposure, RISKComplianceFlag (patch compliance)
- **BASE Fields:** BASEBusinessCriticality (determines patch tier)
- **Native Metrics:** Backup Status, Disk Space, Service Status, Patch Status

---

## NEXT STEPS

1. Read **36_PATCH_Quick_Start_Guide.md** for deployment steps
2. Review **31_PATCH_Custom_Fields.md** for field definitions
3. Configure servers using **37_PATCH_Server_Classification_How_To.md**
4. Set up policies using **32_PATCH_Policies_Configuration.md**
5. Deploy scripts from **33_PATCH_Automation_Scripts.md**

---

**Version:** 1.0  
**Last Updated:** February 1, 2026, 5:12 PM CET  
**Status:** Production Ready  
**Applies To:** NinjaRMM Framework v1.0+  
**Author:** Enterprise IT Architecture Team
