# NinjaRMM Custom Field Framework - Architecture
**File:** 01_Framework_Architecture.md  
**Version:** 3.1  
**Last Updated:** February 1, 2026, 4:30 PM CET  
**Purpose:** Six-layer architecture design and principles

---

## EXECUTIVE SUMMARY

The NinjaRMM Custom Field Framework transforms traditional RMM monitoring from reactive alerting to proactive intelligence through a six-layer architecture. Each layer builds upon the previous one to convert raw telemetry into actionable insights, automated remediation, and simplified helpdesk workflows.

**Core Principle:** Store intelligence in custom fields, not just raw metrics. Fields become the central nervous system that connects scripts, conditions, groups, and dashboards.

---

## SIX-LAYER ARCHITECTURE

### Layer 1: Telemetry Scripts (Data Collection)

**Purpose:** Collect raw system metrics and derive intelligence

**Components:**
- 105+ PowerShell scripts running on devices
- Scheduled execution (every 4 hours for critical, daily for analysis)
- SYSTEM context execution for full access
- Error handling and logging

**Examples:**
- Script 1: Health Score Calculator (calculates OPSHealthScore 0-100)
- Script 2: Stability Analyzer (counts crashes, hangs, service failures)
- Script 6: Telemetry Collector (collects event log data)
- Script 7: Resource Monitor (CPU, memory, disk metrics)
- Script 8: Network Monitor (location detection, VPN status)

**Data Flow:**
```
Windows System -> PowerShell Script -> Calculations/Logic -> Custom Field Update
```

**Key Characteristics:**
- Scripts run locally on each device
- No external dependencies (WMI, CIM, registry only)
- Self-contained logic per script
- Idempotent execution (safe to run multiple times)

---

### Layer 2: Custom Field Storage (Intelligence Persistence)

**Purpose:** Store derived intelligence per device, accessible to all layers

**Components:**
- 270+ custom fields across 28 prefix categories
- Persistent storage in NinjaRMM device records
- Queryable by conditions, groups, and dashboards
- Historical tracking (via NinjaRMM field history)

**Field Organization:**
- **OPS:** Operational scores (health, stability, performance)
- **STAT:** Raw telemetry (crashes, uptime, resource metrics)
- **RISK:** Risk classification (security exposure, compliance)
- **AUTO:** Automation control (safety gates, eligibility flags)
- **Infrastructure:** Server-specific monitoring (IIS, MSSQL, VEEAM, etc.)

**Data Flow:**
```
Script Updates Field -> Field Stored in NinjaRMM -> Field Available to All Layers
```

**Key Characteristics:**
- Single source of truth per device
- No database queries needed (fields are indexed)
- Real-time access by conditions and groups
- Historical trend analysis possible

---

### Layer 3: Classification Logic (Intelligence Derivation)

**Purpose:** Transform raw metrics into actionable intelligence

**Components:**
- Scoring algorithms (0-100 scales)
- Threshold-based classification
- Multi-factor risk assessment
- Pattern-based root cause analysis

**Examples:**

**Health Score Calculation:**
```
Base Score: 100
- Crashes (> 10): -20 points
- Disk space < 15%: -15 points
- Memory pressure > 90%: -15 points
- Security issues: -20 points
= OPSHealthScore (0-100)
```

**Risk Classification:**
```
IF SECAntivirusEnabled = False AND SECFirewallEnabled = False
THEN RISKSecurityExposure = "Critical"
ELSE IF SECSecurityPostureScore < 40
THEN RISKSecurityExposure = "High"
... (thresholds defined in field documentation)
```

**Reboot Recommendation:**
```
IF STATUptimeDays > 120 OR (STATUptimeDays > 90 AND STATAppCrashes24h > 15)
THEN RISKRebootLevel = "Critical"
ELSE IF STATUptimeDays > 60
THEN RISKRebootLevel = "Medium"
... (logic in scripts)
```

**Data Flow:**
```
Multiple Fields -> Classification Logic -> Derived Intelligence Field
(STAT fields) -> (Script calculation) -> (OPS/RISK fields)
```

**Key Characteristics:**
- Composite scoring (multiple inputs -> single score)
- Context-aware (considers device type, role, criticality)
- Actionable thresholds (green/yellow/red zones)
- Self-documenting (field descriptions explain scoring)

---

### Layer 4: Dynamic Groups (Automation Routing)

**Purpose:** Automatically segment devices based on field values for targeted automation

**Components:**
- 70+ dynamic groups
- Real-time membership updates
- Field-based filters (complex multi-field logic)
- Automation routing targets

**Examples:**

**Critical Stability Risk Group:**
```
Filter: OPSStabilityScore < 40 OR STATAppCrashes24h > 20 OR STATBSODCount30d > 0
Use Case: High-priority intervention, escalated alerts
Action: Create P1 ticket, run diagnostics script
```

**Safe for Aggressive Automation:**
```
Filter: AUTORemediationEligible = True 
    AND RISKBusinessCriticalFlag = False 
    AND OPSStabilityScore > 80
    AND AUTOAutomationRisk < 30
Use Case: Automated remediation without manual approval
Action: Enable disk cleanup, service restarts, optimization
```

**Replacement Immediate (0-6 months):**
```
Filter: PREDReplacementWindow = "0-6 months"
Use Case: Budget planning, proactive replacement
Action: Generate purchase requisition, notify management
```

**Server Infrastructure - MSSQL Critical:**
```
Filter: SRVServerRole = True 
    AND MSSQLHealthStatus = "Critical"
    AND RISKBusinessCriticalFlag = True
Use Case: Database server failures requiring immediate attention
Action: Create P1 ticket, escalate to DBA, run backup validation
```

**Data Flow:**
```
Field Values Change -> Group Membership Re-evaluated -> Device Added/Removed from Group
```

**Key Characteristics:**
- Real-time updates (membership changes as fields change)
- Nested logic (complex AND/OR conditions)
- Automation targeting (groups drive script execution)
- Reporting segments (group membership reports)

---

### Layer 5: Remediation Automation (Self-Healing)

**Purpose:** Automatically fix common issues with safety gates

**Components:**
- Remediation scripts (automated fixes)
- Safety control flags (multi-gate approval)
- Pre-flight validation checks
- Rollback capabilities
- Comprehensive logging

**Safety Mechanism Example:**

**Disk Cleanup Automation:**
```
Pre-Flight Checks:
1. Check: AUTORemediationEligible = True
2. Check: AUTOAllowCleanup = True
3. Check: RISKBusinessCriticalFlag = False
4. Check: OPSHealthScore < 70 (only if needed)
5. Check: CAPDiskFreePercent < 20 (trigger threshold)

IF All Checks Pass:
  - Create restore point
  - Run cleanup (temp files, Windows Update cache, etc.)
  - Log actions to AUTO_RemediationHistory
  - Update CAPDiskFreePercent after cleanup
  - Send notification
ELSE:
  - Create alert for manual intervention
  - Log reason for automation block
```

**Service Restart Automation:**
```
Pre-Flight Checks:
1. Check: AUTOAllowServiceRestart = True
2. Check: Service is critical (from BASE_CriticalServicesList)
3. Check: Service stopped unexpectedly (not manual stop)
4. Check: Not in maintenance window

IF All Checks Pass:
  - Log pre-state
  - Attempt service restart
  - Wait 30 seconds
  - Validate service running
  - Update STATServiceFailures24h
  - Log outcome
ELSE:
  - Create escalated ticket
```

**Data Flow:**
```
Condition Triggers -> Pre-Flight Checks -> Execute Remediation -> Update Fields -> Notify
```

**Key Characteristics:**
- Multi-gate safety (AND logic for multiple flags)
- Business criticality awareness (never auto-reboot production servers)
- Logging and audit trail (all actions recorded)
- Rollback capabilities (restore points before changes)
- Gradual rollout (pilot -> production)

---

### Layer 6: Helpdesk Visibility (Human Interface)

**Purpose:** Present actionable intelligence to helpdesk, not raw metrics

**Traditional Monitoring Problem:**
```
Alert: "Disk Space = 15 GB"
Technician Thinks: "Is that good or bad? What size is the drive? Is this urgent?"
Result: Alert fatigue, ignored warnings
```

**Framework Approach:**
```
Dashboard Widget: "Device Health Score: 45 (Poor)"
Details:
  - Disk space critical (5% free, 12 GB) <- Actionable
  - 15 crashes in 24 hours <- Root cause
  - Uptime: 90 days <- Contributing factor
Recommended Action: "Run disk cleanup script, schedule reboot"
Severity: Yellow (attention needed within 24h)
```

**Dashboard Components:**

**Health Score Widget:**
```
Display: Large numeric score (0-100) with color coding
  90-100: Green (Excellent)
  70-89: Green (Good)
  50-69: Yellow (Fair - needs attention)
  30-49: Orange (Poor - urgent)
  0-29: Red (Critical - immediate action)

Breakdown:
  Stability: 65
  Performance: 80
  Security: 55
  Capacity: 40 <- Lowest contributor highlighted
```

**Critical Devices Widget:**
```
List: Devices in CRIT_Stability_Risk group
Columns:
  - Device Name
  - Health Score (color-coded)
  - Primary Issue (interpreted root cause)
  - Days in Critical State
  - Recommended Action (script to run)
Sort: By health score (lowest first)
```

**Capacity Planning Widget:**
```
Chart: Disk space forecast
  - Green zone: > 30 days until full
  - Yellow zone: 15-30 days until full
  - Red zone: < 15 days until full
Action: "Expand disk on 5 devices in next 30 days"
```

**Data Flow:**
```
Custom Fields -> Dashboard Query -> Interpreted Display -> Actionable Insight
```

**Key Characteristics:**
- Actionable, not informational (tell tech what to do)
- Color-coded severity (visual triage)
- Root cause included (not just symptom)
- Recommended actions (run script X, create ticket)
- Reduced alert fatigue (intelligent thresholds)

---

## DATA FLOW EXAMPLE

### Scenario: High Crash Rate Device

**Layer 1: Telemetry Scripts**
```
Script 6 (Telemetry Collector) runs every 4 hours:
- Queries Application Event Log for Event ID 1000 (crashes)
- Counts crashes in last 24 hours
- Result: 18 crashes found
- Updates: STATAppCrashes24h = 18
```

**Layer 2: Custom Field Storage**
```
Field updated in NinjaRMM:
- STATAppCrashes24h: 18 (was 5 four hours ago)
- Field change triggers re-evaluation of groups and conditions
```

**Layer 3: Classification Logic**
```
Script 2 (Stability Analyzer) runs every 4 hours:
- Reads: STATAppCrashes24h = 18
- Reads: STATAppHangs24h = 7
- Reads: STATServiceFailures24h = 3
- Calculates: OPSStabilityScore = 100 - (18*2) - (7*1.5) - (3*3) = 45.5 -> 45
- Updates: OPSStabilityScore = 45
- Classification: "Poor" (score < 50)
```

**Layer 4: Dynamic Groups**
```
Group: CRIT_Stability_Risk (filter: OPSStabilityScore < 40)
- Device NOT added (score = 45, threshold = 40)

Group: HEALTH_Degraded (filter: OPSHealthScore BETWEEN 40 AND 69)
- Device ADDED (overall health score = 55 due to crashes)

Group: SYMPTOM_Crashes_Elevated (filter: STATAppCrashes24h > 15)
- Device ADDED (18 crashes > threshold 15)
```

**Layer 5: Remediation Automation**
```
Condition: HIGH_Stability_Degraded triggers:
- Logic: OPSStabilityScore < 60 AND STATAppCrashes24h > 10
- Device matches: Yes (45 < 60, 18 > 10)

Pre-Flight Checks:
- AUTORemediationEligible: True (passes)
- RISKBusinessCriticalFlag: False (passes)
- Action: Run Script 40 (System Health Diagnostics)

Script 40 Executes:
- Collects additional diagnostics
- Checks for specific failing applications
- Updates AUTO_RemediationHistory: "Diagnostics run, Chrome crashing repeatedly"
- Creates ticket: "P2 - High crash rate on DEVICE123, Chrome issue detected"
```

**Layer 6: Helpdesk Visibility**
```
Dashboard Widget: Critical Devices
- DEVICE123 appears in list
- Health Score: 55 (Yellow, "Fair")
- Primary Issue: "High application crash rate (18 crashes, Chrome)"
- Recommended Action: "Review Chrome extensions, consider reinstall"
- Days in Degraded State: 1 day
- Technician clicks "Run Chrome Reset Script" button
```

**Result:**
- Issue detected automatically within 4 hours
- Root cause identified (Chrome crashes)
- Ticket created with context
- Helpdesk sees actionable intelligence
- Recommended remediation provided
- Total time from symptom to action: < 5 hours (vs days with traditional monitoring)

---

## DESIGN PRINCIPLES

### 1. Intelligence Over Raw Data

**Traditional Approach:**
- Alert: "CPU = 85%"
- Technician must interpret: Is this normal? Is it sustained? What's causing it?

**Framework Approach:**
- OPSPerformanceScore = 65 (Fair)
- Interpretation: Performance degraded due to sustained high CPU (3-hour average 82%)
- Root cause: "Windows Update service consuming CPU"
- Action: "Wait for update to complete, or run Script 55 to optimize"

### 2. Field-Centric Architecture

**Core Principle:** Custom fields are the central nervous system

- Scripts write to fields (Layer 1 -> Layer 2)
- Conditions read from fields (Layer 2 -> Layer 4)
- Groups filter by fields (Layer 2 -> Layer 4)
- Dashboards query fields (Layer 2 -> Layer 6)
- Remediation validates fields (Layer 2 -> Layer 5)

**Benefit:** No complex queries, no external databases, real-time access

### 3. Gradual Automation Rollout

**Phase 1: Monitoring Only (Week 1-4)**
- Deploy fields and scripts
- Observe patterns
- Validate data accuracy
- Build confidence

**Phase 2: Alerting (Week 5-6)**
- Create compound conditions
- Enable ticketing
- No automated remediation yet
- Manual intervention

**Phase 3: Pilot Automation (Week 6-7)**
- Enable remediation on 5-10 low-risk devices
- Set all safety flags to True
- Monitor daily
- Validate safety gates work

**Phase 4: Production Automation (Week 7-8)**
- Expand to 50% of non-critical devices
- Keep critical servers manual
- Continuous monitoring
- Tune thresholds

### 4. Safety Through Multi-Gate Approval

**Single Gate (Risky):**
```
IF AUTORemediationEligible = True THEN RUN SCRIPT
```

**Multi-Gate (Safe):**
```
IF AUTORemediationEligible = True
AND AUTOAllowCleanup = True
AND RISKBusinessCriticalFlag = False
AND OPSStabilityScore < 70
AND CAPDiskFreePercent < 20
THEN RUN DISK CLEANUP SCRIPT
```

**Benefit:** Five independent checks must pass, prevents accidental execution

### 5. Context-Aware Automation

**Context Factors:**
- Device type (workstation vs server)
- Server role (database, web, file server)
- Business criticality (production vs test)
- Time of day (business hours vs after-hours)
- Recent stability (don't automate on unstable devices)
- User presence (logged in vs idle)

**Example:**
```
Script: Reboot Device
Context Checks:
- Server? If yes, block reboot (require manual approval)
- Business critical? If yes, block (RISKBusinessCriticalFlag)
- User logged in? If yes, wait until logoff
- Business hours? If yes, schedule for after-hours
- Recent crashes? If yes, block (needs investigation)
- Uptime < 7 days? If yes, block (recently rebooted)

Result: Only reboots low-risk workstations during after-hours when idle
```

### 6. Self-Documenting Intelligence

**Traditional Monitoring:**
```
Field: DiskSpaceGB = 12
Technician must know: "Is 12 GB good or bad for this drive?"
```

**Framework Approach:**
```
Field: CAPDiskFreePercent = 5
Field: CAPDaysUntilDiskFull = 8
Field: CAPDiskForecast = "Critical - will be full in 8 days"
Field: RISKCapacityLevel = "Critical"
Dashboard: "CRITICAL: Disk 95% full, 8 days until full. Run cleanup script or expand disk."
```

**Benefit:** Intelligence is explicit, no interpretation needed

---

## INTEGRATION PATTERNS

### Pattern 1: Event-Driven Workflow

```
1. Event occurs (crash, service failure, disk full)
2. Script detects event (Layer 1: Telemetry)
3. Field updated (Layer 2: Storage)
4. Group membership changes (Layer 4: Dynamic Group)
5. Condition triggers (Layer 4 -> Layer 5)
6. Automation executes (Layer 5: Remediation)
7. Fields updated with results (Layer 2: Storage)
8. Dashboard reflects change (Layer 6: Visibility)
```

### Pattern 2: Scheduled Analysis

```
1. Daily script execution (Layer 1)
2. Analyze trends (capacity growth, crash patterns)
3. Update intelligence fields (Layer 2)
4. Predictive alerts (Layer 3: Classification)
5. Proactive tickets created before failure
```

### Pattern 3: User-Initiated Remediation

```
1. Helpdesk views dashboard (Layer 6)
2. Sees recommended action ("Run Disk Cleanup")
3. Clicks button to execute script
4. Script validates safety flags (Layer 5)
5. Executes if safe, otherwise alerts
6. Updates fields with results (Layer 2)
7. Dashboard refreshes showing improvement
```

---

## SCALABILITY

### Small Deployment (50-100 devices)
- Deploy core fields only (153 fields from files 10-14)
- Essential scripts (20-30 scripts)
- Critical conditions (15 P1 conditions)
- Core groups (10-15 groups)
- Implementation time: 2-4 weeks

### Medium Deployment (100-500 devices)
- Full core fields (153 fields)
- Infrastructure fields for servers (113 additional)
- All core scripts (105 scripts)
- Full automation (69 conditions, 70+ groups)
- Implementation time: 6-8 weeks

### Large Deployment (500+ devices)
- Full framework (270+ fields)
- Custom scripts for specific environments
- Advanced automation patterns
- Integration with other tools (ticketing, monitoring)
- Implementation time: 8-12 weeks

### Enterprise Deployment (1000+ devices)
- Multi-tenant support (field prefixes per client)
- Custom dashboards per team
- API integration for external systems
- Advanced reporting and analytics
- Implementation time: 12-16 weeks

---

## PERFORMANCE CONSIDERATIONS

### Script Execution

**Impact:** 105 scripts running every 4 hours per device

**Mitigation:**
- Stagger execution (random offset 0-30 minutes)
- Optimize script runtime (< 60 seconds per script)
- Use efficient PowerShell (avoid expensive operations)
- Cache results where possible

**Typical Load:**
- 500 devices * 105 scripts = 52,500 script executions per day
- Average runtime: 30 seconds per script
- Total CPU time: 437 hours per day (distributed across 500 devices)
- Per device: ~52 minutes CPU time per day (< 4% of daily capacity)

### Field Updates

**Impact:** 270 fields per device being updated regularly

**Mitigation:**
- Batch field updates in scripts (one API call per script)
- Update only changed fields
- Use appropriate update frequencies (not every field every 4 hours)

**Typical Load:**
- 500 devices * 50 field updates per day = 25,000 field updates
- NinjaRMM handles this easily (< 1 API call per device per hour)

### Condition Evaluation

**Impact:** 69 conditions checked every 5 minutes

**Mitigation:**
- Use simple field comparisons (no complex queries)
- Leverage dynamic groups (pre-filtered devices)
- Disable conditions not actively used

**Typical Load:**
- 69 conditions * 500 devices = 34,500 condition checks per 5 minutes
- NinjaRMM optimized for this (evaluates locally, not via API)

---

## MAINTENANCE

### Daily Tasks
- Review critical condition alerts (5-10 minutes)
- Check script execution failures (5 minutes)
- Validate remediation actions (10 minutes)

### Weekly Tasks
- Review dynamic group populations (10 minutes)
- Tune condition thresholds if needed (15 minutes)
- Generate operational reports (15 minutes)

### Monthly Tasks
- Review field utilization (unused fields)
- Optimize slow scripts (if runtime > 60s)
- Update documentation for customizations
- Stakeholder reporting (ROI, metrics)

### Quarterly Tasks
- Framework version updates (new fields, scripts)
- Major threshold reviews (seasonal adjustments)
- Strategic planning (new automation opportunities)

---

## CONCLUSION

The six-layer architecture transforms NinjaRMM from a basic RMM tool into an intelligent automation platform. By storing intelligence in custom fields and building automation logic on top of those fields, the framework enables:

- **Proactive monitoring** (detect before users report)
- **Intelligent automation** (context-aware remediation)
- **Simplified helpdesk** (actionable insights, not raw metrics)
- **Scalable operations** (automation handles routine tasks)
- **Measurable ROI** (reduced MTTR, lower ticket volume, improved satisfaction)

The framework is production-ready and can be deployed in phases over 8 weeks with minimal risk.

---

**Next Steps:**
1. Review `03_Implementation_Roadmap_8_Weeks.md` for deployment plan
2. Review `00_Master_Index.md` for complete file navigation
3. Start with core fields (files 10-14) and essential scripts

---

**FILE: 01_Framework_Architecture.md**  
**Version:** 3.1 Complete  
**Last Updated:** February 1, 2026, 4:30 PM CET
