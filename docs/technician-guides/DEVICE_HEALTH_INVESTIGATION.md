# Device Health Investigation Guide

**Purpose:** Systematic approach to investigating unhealthy devices  
**Skill Level:** Intermediate  
**Estimated Time:** 20-45 minutes per investigation  
**Last Updated:** February 9, 2026

---

## When to Use This Guide

**Use this guide when:**
- Device health score <70
- Multiple component scores are low
- Proactive investigation (before alert)
- User reports vague "slowness"
- Trending downward over time
- Preparing for maintenance

**Don't use for:**
- Emergency situations (use alert playbooks)
- Single specific issue (use troubleshooting flowcharts)
- Routine checks (use dashboard review)

---

## Investigation Overview

Comprehensive device investigation follows this 7-phase approach:

1. **Preparation** (2 min) - Gather context
2. **Health Assessment** (5 min) - Overall status
3. **Component Analysis** (10 min) - Drill into scores
4. **Historical Review** (5 min) - Trends over time
5. **Root Cause Identification** (10 min) - Find the problem
6. **Remediation Planning** (10 min) - Plan the fix
7. **Documentation** (5 min) - Record findings

**Total time:** 45 minutes for thorough investigation

---

## Phase 1: Preparation (2 minutes)

### Gather Context

**Questions to answer:**
- Who is the user?
- What is their role?
- How critical is this device?
- Any recent incidents or changes?
- Any upcoming maintenance windows?

**Check in NinjaRMM:**
- Device details (OS, specs, location)
- User contact information
- Device group membership
- Tags and notes
- Recent activity

**Document:**
```
Device: [Name]
User: [Name/Contact]
Role: [User role]
Criticality: [Low/Medium/High/Critical]
Context: [Recent changes, issues, plans]
```

---

## Phase 2: Health Assessment (5 minutes)

### Check Overall Health

**Primary fields:**
```
opsHealthScore:        XX  (Target: 75+)
opsOverallScore:       XX  (Same as opsHealthScore)
opsStatus:            [Status]  (Target: "Healthy")
opsLastHealthCheck:   [Timestamp]
```

**Interpret health score:**
- **90-100:** Excellent - Nothing to do
- **75-89:** Good - Minor optimization possible
- **60-74:** Fair - Needs attention (you are here)
- **40-59:** Poor - Action required
- **0-39:** Critical - Urgent action needed

**Quick assessment:**
- Is score accurate? (data recent?)
- Is this expected? (old device, heavy use?)
- Is this changing? (stable, improving, declining?)

---

## Phase 3: Component Analysis (10 minutes)

### Analyze Component Scores

**The Four Pillars of Health:**

#### Pillar 1: Stability (Weight: 20%)

**Check:**
```
opsStabilityScore:     XX  (Target: 90+)
statCrashCount30d:     X   (Target: 0)
statErrorCount30d:     X   (Target: <20)
statWarningCount30d:   X   (Target: <50)
statRebootCount30d:    X   (Target: <10)
statLastCrashDate:     [Timestamp]
```

**Red flags:**
- Score <70: System unstable
- Crashes >2: Hardware or driver issues
- Errors >100: Something wrong
- Frequent reboots: Updates or crashes

**Common causes:**
- Driver incompatibility
- Hardware failure (RAM, disk)
- Software conflicts
- Malware
- Windows corruption

**Investigation actions:**
1. Review System event log (crashes)
2. Review Application log (app errors)
3. Check Device Manager (hardware errors)
4. Review installed updates (recent changes)
5. Check disk health (SMART status)

---

#### Pillar 2: Performance (Weight: 20%)

**Check:**
```
opsPerformanceScore:   XX  (Target: 80+)
statAvgCPUUsage:       X%  (Target: <70%)
statAvgMemoryUsage:    X%  (Target: <80%)
statAvgDiskUsage:      X%  (Target: <80%)
```

**Red flags:**
- Score <70: Performance issues
- CPU >80%: Overloaded or malware
- Memory >85%: Insufficient RAM
- Disk >85%: I/O bottleneck

**Common causes:**
- Insufficient resources for workload
- Background processes (updates, scans)
- Malware/unwanted software
- Old/slow hardware
- Disk fragmentation

**Investigation actions:**
1. Check Task Manager (real-time usage)
2. Identify top processes (CPU, memory, disk)
3. Review startup programs (unnecessary load)
4. Check for malware (suspicious processes)
5. Review specs vs requirements (adequate?)

---

#### Pillar 3: Security (Weight: 30%)

**Check:**
```
opsSecurityScore:        XX  (Target: 90+)
secAntivirusEnabled:     [true/false]
secAntivirusProduct:     [Name]
secAntivirusUpdated:     [true/false]
secFirewallEnabled:      [true/false]
secBitLockerEnabled:     [true/false]
secSecureBootEnabled:    [true/false]
secTPMEnabled:           [true/false]
secVulnerabilityCount:   X   (Target: 0)
secComplianceStatus:     [Status]
```

**Red flags:**
- Score <80: Security gaps
- AV disabled: Immediate risk
- AV outdated: Vulnerable
- Firewall off: Exposed
- Vulnerabilities >0: Patch needed

**Common causes:**
- User disabled protection
- Malware disabled protection
- Update failures
- Misconfiguration
- Policy not applied

**Investigation actions:**
1. Verify actual AV status (not just field)
2. Check definition update date
3. Review firewall rules
4. Check BitLocker status
5. Review missing security updates

---

#### Pillar 4: Capacity (Weight: 30%)

**Check:**
```
opsCapacityScore:        XX  (Target: 80+)
capDiskFreeGB:           X   (Target: >50 GB)
capDiskFreePercent:      X%  (Target: >20%)
capDiskTotalGB:          X   (Total)
capMemoryTotalGB:        X   (Total)
capMemoryUsedGB:         X   (Used)
capMemoryUsedPercent:    X%  (Target: <80%)
capWarningLevel:         [Level]
capForecastDaysFull:     X   (Days)
```

**Red flags:**
- Score <70: Capacity issues
- Disk <15%: Running out of space
- Disk <5%: Critical
- Memory >85%: Insufficient RAM
- Forecast <30 days: Plan expansion

**Common causes:**
- Temp files accumulation
- User data growth
- Log files
- Inadequate initial sizing
- Backups stored locally

**Investigation actions:**
1. Analyze disk usage (TreeSize)
2. Identify large files/folders
3. Check temp folders
4. Review memory allocation
5. Check growth trend

---

## Phase 4: Historical Review (5 minutes)

### Analyze Trends

**Compare to history:**
- Has score been declining?
- Is this a sudden drop?
- Is this cyclical? (daily, weekly)
- Any correlation with events?

**Questions to answer:**

**Trending down:**
- What changed?
- When did decline start?
- Rate of decline?
- Will it continue?

**Sudden drop:**
- What happened?
- Specific event?
- User action?
- System update?

**Stable low:**
- Chronic issue?
- Baseline problem?
- Needs upgrade?
- Risk accepted?

**Check timestamps:**
```
opsLastHealthCheck:    [When assessed?]
statLastCrashDate:     [When crashed?]
secLastSecurityScan:   [When scanned?]
updLastPatchDate:      [When patched?]
```

**Recent = <24 hours**
**Current = <7 days**
**Stale = >7 days**

---

## Phase 5: Root Cause Identification (10 minutes)

### The Five Whys Technique

Ask "why" five times to reach root cause:

**Example:**
1. **Why is health score low?**
   → Because capacity score is 45

2. **Why is capacity score 45?**
   → Because disk is 92% full

3. **Why is disk 92% full?**
   → Because C:\Temp has 80 GB of files

4. **Why does C:\Temp have 80 GB?**
   → Because temp cleanup doesn't run

5. **Why doesn't temp cleanup run?**
   → Because scheduled task is disabled

**Root cause:** Scheduled task disabled

### Common Root Causes

**Hardware:**
- Failing hard drive
- Failing RAM
- Overheating CPU
- Outdated components

**Software:**
- Driver incompatibility
- Application conflicts
- Malware infection
- Windows corruption

**Configuration:**
- Misconfigured policies
- Disabled services
- Wrong settings
- Missing prerequisites

**Capacity:**
- Insufficient disk space
- Insufficient RAM
- Undersized initially
- Growth not managed

**User:**
- Heavy workload
- Inappropriate use
- Disabled protections
- Installed unapproved software

**External:**
- Network issues
- Server problems
- Policy changes
- Recent updates

---

## Phase 6: Remediation Planning (10 minutes)

### Develop Action Plan

**Plan structure:**
1. Immediate actions (stop the bleeding)
2. Short-term fixes (address symptoms)
3. Long-term solutions (fix root cause)
4. Prevention measures (avoid recurrence)

**Example plan:**

**Immediate (today):**
- Free up 20 GB disk space
- Restart stuck services
- Enable antivirus

**Short-term (this week):**
- Clean up temp files
- Uninstall unused software
- Apply missing updates
- Run full malware scan

**Long-term (this month):**
- Expand disk to 250 GB
- Upgrade RAM to 16 GB
- Implement automated cleanup
- Schedule regular maintenance

**Prevention (ongoing):**
- Enable disk cleanup automation
- Monitor growth monthly
- User training on software management
- Regular health checks

### Get Approvals

**Need approval for:**
- Reboots during business hours
- Software removal
- Hardware upgrades
- Policy changes
- Budget expenditure

**Approval process:**
1. Document business case
2. Estimate cost/time
3. Identify risks
4. Submit to manager
5. Wait for approval
6. Schedule work

---

## Phase 7: Documentation (5 minutes)

### Create Investigation Report

**Use this template:**

```markdown
# Device Health Investigation Report

**Device:** [Name]
**User:** [Name]
**Date:** [Date]
**Investigator:** [Your name]
**Health Score:** XX → Target: 75+

## Executive Summary
[2-3 sentence summary of findings and plan]

## Current State
- Health Score: XX
- Stability: XX
- Performance: XX
- Security: XX
- Capacity: XX
- Overall Status: [Good/Fair/Poor/Critical]

## Key Findings
1. [Finding 1 with severity]
2. [Finding 2 with severity]
3. [Finding 3 with severity]

## Root Cause
[Primary root cause identified]

## Impact
- User: [How user affected]
- Business: [Business impact]
- Risk: [Risk if not addressed]

## Remediation Plan

### Immediate (Today)
- [ ] Action 1
- [ ] Action 2

### Short-term (This Week)
- [ ] Action 1
- [ ] Action 2

### Long-term (This Month)
- [ ] Action 1
- [ ] Action 2

### Prevention
- [ ] Action 1
- [ ] Action 2

## Approvals Needed
- [ ] Reboot approval
- [ ] Budget approval ($XXX)
- [ ] Change window

## Follow-up
- Next check: [Date]
- Expected score: XX
- Verify by: [Date]

## Notes
[Any additional context, concerns, or observations]
```

---

## Investigation Checklist

**Print this for reference:**

```
□ PREPARATION
  □ Gathered device context
  □ Identified user and criticality
  □ Reviewed recent history

□ HEALTH ASSESSMENT
  □ Checked overall health score
  □ Verified data freshness
  □ Noted status and trends

□ COMPONENT ANALYSIS
  □ Stability score reviewed
  □ Performance score reviewed
  □ Security score reviewed
  □ Capacity score reviewed
  □ Identified lowest components

□ HISTORICAL REVIEW
  □ Checked score trends
  □ Identified when decline started
  □ Noted correlations

□ ROOT CAUSE
  □ Applied Five Whys
  □ Identified root cause
  □ Verified with evidence

□ REMEDIATION PLAN
  □ Immediate actions defined
  □ Short-term fixes planned
  □ Long-term solutions identified
  □ Prevention measures included
  □ Approvals identified

□ DOCUMENTATION
  □ Investigation report completed
  □ Ticket updated
  □ User notified
  □ Follow-up scheduled
```

---

## Tips for Efficient Investigations

**1. Start with Lowest Component**
Focus energy where problem is worst

**2. Look for Multiple Issues**
Often several problems compound

**3. Check Timestamps**
Stale data means wait for refresh

**4. Compare Similar Devices**
Is this device-specific or systemic?

**5. User Input Valuable**
They know their device's behavior

**6. Fix While Investigating**
Safe quick wins (empty recycle bin)

**7. Document As You Go**
Don't rely on memory later

**8. Schedule Follow-up**
Verify fix worked (24-48 hours)

---

## After Investigation

**Immediate:**
- Execute immediate actions
- Update ticket/alert
- Notify user of plan
- Get necessary approvals

**24 Hours Later:**
- Check if score improved
- Verify immediate actions worked
- Begin short-term fixes

**1 Week Later:**
- Complete short-term fixes
- Verify health score >70
- Begin long-term planning

**1 Month Later:**
- Implement long-term solutions
- Implement prevention measures
- Close investigation
- Update documentation

---

## When to Escalate

**Escalate if:**
- Root cause unclear after thorough investigation
- Multiple critical components
- Hardware replacement needed
- Specialized knowledge required
- Policy/architectural changes needed
- Budget approval required
- User is VIP/executive

**Escalation should include:**
- Complete investigation report
- Evidence collected
- Attempted fixes
- Recommendation
- Priority/urgency

---

**Remember:** A thorough investigation prevents recurring issues. Take the time to find and fix the root cause, not just symptoms.

**Last Updated:** February 9, 2026, 8:13 PM CET
