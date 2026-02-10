# Reading the Dashboard - Windows Automation Framework

**Document Type:** Technician Guide  
**Audience:** Help Desk, Desktop Support, System Administrators  
**Time to Read:** 10 minutes  
**Last Updated:** February 9, 2026

---

## Purpose

This guide teaches you how to interpret the NinjaRMM dashboard displaying Windows device health data collected by WAF. You'll learn what the numbers mean, when to investigate, and how to drill down into issues.

---

## Health Score Overview

### Understanding the Overall Health Score

The **opsHealthScore** is a single number (0-100) representing overall device health.

**Score Ranges:**
- **90-100:** Excellent - Device is healthy, no action needed
- **80-89:** Good - Minor issues, routine monitoring
- **70-79:** Fair - Investigate within 24-48 hours
- **60-69:** Poor - Investigate same day
- **Below 60:** Critical - Investigate immediately

**What It Represents:**
The overall score is a weighted average of four component scores:
- Stability: 20%
- Performance: 20%
- Security: 30%
- Capacity: 30%

**Example:**
```
Device: DESKTOP-2024
Overall Health: 75 (Fair)

Breakdown:
- Stability: 85 (Good)
- Performance: 70 (Fair) ← Problem area
- Security: 90 (Excellent)
- Capacity: 65 (Poor) ← Problem area

Action: Investigate performance and capacity issues
```

---

## Component Scores Explained

### Stability Score (opsStabilityScore)

**What it measures:** System crashes, application errors, critical events

**Score Interpretation:**
- **90-100:** No crashes, minimal errors (1-2 minor events)
- **80-89:** Few errors (3-5 errors, no crashes)
- **70-79:** Moderate errors (6-10 errors or 1 crash)
- **60-69:** Frequent errors (10+ errors or multiple crashes)
- **Below 60:** System unstable (frequent crashes)

**Related Fields to Check:**
- `statCrashCount7d` - Recent crashes
- `statErrorCount7d` - Error events
- `statWarningCount7d` - Warning events
- `opsLastCrash` - When last crash occurred

**Common Causes:**
- Driver issues
- Failing hardware (RAM, disk)
- Software conflicts
- Pending updates

---

### Performance Score (opsPerformanceScore)

**What it measures:** CPU, memory, disk usage, and responsiveness

**Score Interpretation:**
- **90-100:** Excellent performance, resources available
- **80-89:** Good performance, normal usage levels
- **70-79:** Acceptable but elevated resource usage
- **60-69:** Poor performance, resources strained
- **Below 60:** Severe performance issues

**Related Fields to Check:**
- `statCPUAvg7d` - Average CPU usage
- `statMemoryUsedPercent` - Current RAM usage
- `statDiskReadAvg` / `statDiskWriteAvg` - Disk I/O
- `statBootTime` - How long boot takes
- `opsResponseTime` - System responsiveness

**Common Causes:**
- Resource-heavy applications
- Insufficient RAM
- Slow or failing disk
- Malware or unwanted software
- Background processes

---

### Security Score (opsSecurityScore)

**What it measures:** Antivirus status, firewall, encryption, updates, vulnerabilities

**Score Interpretation:**
- **90-100:** All protections enabled and current
- **80-89:** Minor security gaps (e.g., one update pending)
- **70-79:** Moderate risk (e.g., firewall disabled temporarily)
- **60-69:** Significant risk (e.g., AV disabled, multiple updates missing)
- **Below 60:** Critical risk (multiple protections disabled)

**Related Fields to Check:**
- `secAntivirusStatus` - AV enabled and updated?
- `secFirewallStatus` - Firewall enabled?
- `secBitLockerStatus` - Disk encryption status
- `secLastVirusScan` - When AV last scanned
- `updPendingCount` - Outstanding updates
- `secCVECount` - Known vulnerabilities

**Common Causes:**
- Disabled security features
- Outdated antivirus definitions
- Missed Windows updates
- Unpatched applications
- No disk encryption (policy requirement)

---

### Capacity Score (opsCapacityScore)

**What it measures:** Disk space, memory availability, growth trends

**Score Interpretation:**
- **90-100:** Ample free space (30%+ disk, 40%+ RAM available)
- **80-89:** Adequate space (20-30% disk, 30-40% RAM)
- **70-79:** Limited space (10-20% disk, 20-30% RAM)
- **60-69:** Low space (5-10% disk, 10-20% RAM)
- **Below 60:** Critical space shortage (under 5% disk or 10% RAM)

**Related Fields to Check:**
- `capDiskCFreePercent` - C: drive free space percentage
- `capDiskCFreeGB` - C: drive free space in GB
- `capMemoryAvailablePercent` - Available RAM percentage
- `capDiskGrowth30d` - Disk usage trend
- `capProjectedDaysTillFull` - When disk will fill

**Common Causes:**
- Large files accumulation
- User data not moved to network storage
- Log files growing unchecked
- Temp files not cleaned
- Insufficient hardware for workload

---

## Dashboard Layout

### Typical Widget Types

**1. Summary Cards**

Show single key metrics:
```
┌─────────────────────┐
│ Overall Health: 85  │
│ Status: Good        │
└─────────────────────┘
```

**2. Score Gauges**

Visual representation of scores:
```
  Stability      Performance     Security       Capacity
  [████████░░] 80  [██████░░░░] 60  [█████████░] 90  [███████░░░] 70
```

**3. Device Lists**

Sorted tables:
```
Device Name       Health  Last Seen   Action
DESKTOP-2024      45      2 min ago   Investigate
LAPTOP-5678       92      5 min ago   OK
SERVER-DC01       78      1 min ago   Monitor
```

**4. Trend Charts**

Historical data over time:
```
100 │     ╭─────╮
 90 │    ╱       ╲
 80 │╭──╯         ╰──╮
 70 │                 ╰─╮
 60 │                   ╰─
    └─────────────────────
    1w  3d  1d  6h  Now
```

**5. Alert Indicators**

Current alerts by severity:
```
Critical: 2
Warning:  5
Info:     12
```

---

## Color Coding

### Standard Color Meanings

**Green:** Healthy (90-100)
- No action needed
- Routine monitoring only

**Yellow/Amber:** Warning (70-89)
- Investigation recommended
- Not urgent unless trending down
- Schedule within 24-48 hours

**Red:** Critical (below 70)
- Immediate attention required
- Investigate same day
- Escalate if below 60

**Gray:** Unknown/No Data
- Script hasn't run yet
- Device offline
- Field not applicable

---

## Reading Specific Widgets

### Health Score Card

**What you see:**
```
DEVICE: DESKTOP-2024
Health: 75
Status: Fair
Last Updated: 2 minutes ago
```

**How to interpret:**
1. Check overall score (75 = Fair)
2. Verify last update time (recent = good)
3. Click for component breakdown

**When to investigate:**
- Score below 80
- Sudden drop (85 → 75 in one day)
- No update in 6+ hours

---

### Component Breakdown Widget

**What you see:**
```
Stability:    85 (Good)
Performance:  70 (Fair) ⚠
Security:     90 (Excellent)
Capacity:     65 (Poor) 🔴
```

**How to interpret:**
1. Identify lowest scores (Capacity = 65)
2. Note warning indicators (⚠, 🔴)
3. Prioritize critical (red) over warning (yellow)

**Action priority:**
1. Address red items first (Capacity = 65)
2. Monitor yellow items (Performance = 70)
3. Maintain green items

---

### Trend Chart Widget

**What you see:**
```
Health Score - Last 7 Days

100 │
 90 │╭───────╮
 80 │        ╰─╮
 70 │           ╰──╮
 60 │              ╰─
    └─────────────────
    7d  5d  3d  1d  Now
```

**How to interpret:**
1. Look for trends (steady decline = problem developing)
2. Sudden drops indicate acute issues
3. Flat lines are stable (good if high, bad if low)
4. Recovery slopes show issue resolution

**Patterns:**
- **Steady decline:** Capacity issue (disk filling)
- **Sudden drop:** Acute problem (crash, attack)
- **Oscillating:** Intermittent issue (network, app)
- **Flat low:** Chronic unresolved problem

---

### Alert Summary Widget

**What you see:**
```
Active Alerts: 7

Critical (2):
- DESKTOP-2024: Disk space <5%
- LAPTOP-5678: AV disabled

Warning (5):
- SERVER-DC01: High CPU
- DESKTOP-9999: Updates pending
- ...
```

**How to interpret:**
1. Critical alerts = immediate action
2. Count matters (2 critical vs 20 critical)
3. Review details for each alert

**Response priority:**
1. Critical security issues (AV disabled)
2. Critical capacity issues (disk full)
3. Warning-level items
4. Informational items

---

## Drilling Down into Issues

### Step-by-Step Investigation

**Starting Point:** Device shows Health Score of 65

**Step 1: Check Component Scores**
```
Click device → View details
Stability:    90 ✓
Performance:  80 ✓
Security:     55 🔴 ← Problem
Capacity:     85 ✓
```

**Step 2: Expand Problem Component**
```
Security: 55
  secAntivirusStatus: Disabled 🔴
  secFirewallStatus: Enabled ✓
  secBitLockerStatus: Not Encrypted ⚠
  updPendingCount: 15 ⚠
```

**Step 3: Identify Root Cause**
- Antivirus disabled (primary issue)
- Disk not encrypted (secondary)
- 15 pending updates (tertiary)

**Step 4: Check History**
```
Field History → secAntivirusStatus
Feb 9, 8:00 AM: Enabled
Feb 9, 2:00 PM: Disabled ← Changed recently
```

**Step 5: Investigate Context**
- Check device notes/tickets
- Contact user
- Review change logs
- Check for related alerts

**Step 6: Plan Remediation**
1. Enable antivirus immediately
2. Schedule BitLocker encryption
3. Deploy pending updates
4. Recheck score after 1 hour

---

## Common Dashboard Scenarios

### Scenario 1: Device Shows All Zeros

**What you see:**
```
Health: 0
All component scores: 0
All fields: Empty
```

**Possible causes:**
1. Scripts haven't run yet (new deployment)
2. Device offline (agent not reporting)
3. Script execution failure
4. Field creation incomplete

**How to check:**
1. Verify device online (check last agent contact)
2. Review script execution logs
3. Check automation policy assignment
4. Manually trigger script execution

---

### Scenario 2: Score Suddenly Dropped

**What you see:**
```
Yesterday: 90
Today: 65
```

**Investigation steps:**
1. Check field history (what changed?)
2. Review recent alerts
3. Check event logs for incidents
4. Contact user about recent changes
5. Review ticket history

**Common causes:**
- Security feature disabled
- Disk suddenly filled
- Application crash
- Update failure

---

### Scenario 3: Persistent Low Score

**What you see:**
```
Health: 55
Last 30 days: Consistently 50-60
```

**Investigation approach:**
1. Identify chronic issues
2. Check if known/accepted (budget, EOL device)
3. Review remediation history
4. Escalate if no progress

**Questions to answer:**
- Is this a tracking-only device (EOL, limited budget)?
- Have remediation attempts failed?
- Is device replacement needed?
- Are expectations realistic?

---

### Scenario 4: High Score But User Complains

**What you see:**
```
Health: 92 (Excellent)
User reports: "Computer is slow"
```

**Possible explanations:**
1. Issue is intermittent (metrics are averages)
2. Issue is application-specific (not system-wide)
3. User perception vs metrics
4. Issue just started (metrics lag 15-60 min)

**Investigation approach:**
1. Review real-time performance (not just WAF scores)
2. Check statCPUAvg vs current CPU
3. Review application-specific metrics
4. Check network performance (not fully covered by WAF)
5. Investigate user workflow

---

## Historical Data Review

### Viewing Trends Over Time

**30-Day View:**
Use for identifying:
- Long-term trends (capacity growth)
- Recurring patterns (weekly spikes)
- Seasonal issues
- Maintenance effectiveness

**7-Day View:**
Use for:
- Recent changes
- Short-term trends
- Issue development
- Remediation validation

**24-Hour View:**
Use for:
- Acute issues
- Change impact
- Performance patterns (business hours)
- Alert validation

---

## Exporting Data

### When to Export

**For Reporting:**
- Monthly device health reports
- Trend analysis
- Budget justification
- Executive summaries

**For Analysis:**
- Investigating complex issues
- Correlating multiple devices
- Historical comparison
- Audit trails

**For Escalation:**
- Support tickets
- Vendor engagement
- Management briefings

### Export Methods

**NinjaRMM Native:**
1. Select devices
2. Choose fields to export
3. Export as CSV
4. Open in Excel/Google Sheets

**WAF Health Check Tools:**
- Use health check scripts for comprehensive reports
- Generate HTML reports for stakeholders
- CSV exports for data analysis

---

## Dashboard Best Practices

### Daily Routine

**Morning Check (5 minutes):**
1. Review critical alerts (action needed?)
2. Check devices with health <70
3. Note any sudden score drops
4. Prioritize day's work

**Throughout Day:**
- Respond to alerts as they arrive
- Update scores after remediation
- Monitor changes to investigated devices

**End of Day (5 minutes):**
- Verify all critical items addressed
- Document open issues
- Set tomorrow's priorities

---

### Weekly Review

**Monday Morning (15 minutes):**
1. Review previous week's trends
2. Identify devices with declining scores
3. Check capacity projections
4. Plan proactive maintenance

---

### Monthly Analysis

**First Monday of Month (30 minutes):**
1. Generate health score report
2. Analyze trends across fleet
3. Identify systemic issues
4. Plan strategic improvements
5. Report to management

---

## Tips for Efficient Dashboard Use

### Customization

**Create Custom Views:**
1. "My Devices" - Devices you support
2. "Critical" - Health <60
3. "Capacity Alerts" - Disk <10%
4. "Security Issues" - Security score <80

**Use Filters:**
- Filter by score range
- Filter by device type (workstation vs server)
- Filter by location
- Filter by last update time

**Set Default Sort:**
- Sort by health score (ascending) to see worst first
- Sort by last seen (ascending) to see offline devices

---

### Keyboard Shortcuts

**Navigation:**
- Learn NinjaRMM keyboard shortcuts
- Bookmark frequently used dashboards
- Use browser search (Ctrl+F) to find specific devices

---

### Multi-Monitor Setup

**Recommended Layout:**
- Monitor 1: Main dashboard (device list)
- Monitor 2: Device details panel
- Monitor 3: Documentation/ticketing

**Single Monitor:**
- Use tabs for multiple views
- Learn Alt+Tab workflow
- Use split-screen features

---

## Common Mistakes to Avoid

### Mistake 1: Ignoring Yellow/Warning Status

**Why it's a problem:**
Warnings become critical if ignored.

**Solution:**
Schedule warning-level issues within 24-48 hours.

---

### Mistake 2: Only Looking at Overall Score

**Why it's a problem:**
Miss specific component issues.

**Solution:**
Always drill into component scores.

---

### Mistake 3: Not Reviewing Trends

**Why it's a problem:**
Miss developing problems (capacity growth).

**Solution:**
Weekly trend review for all monitored devices.

---

### Mistake 4: Treating All Red Scores Equally

**Why it's a problem:**
Score of 69 vs 10 are very different urgencies.

**Solution:**
Prioritize: <60 critical, 60-69 urgent, 70-79 soon.

---

### Mistake 5: Not Documenting Investigations

**Why it's a problem:**
Repeat investigations, lose knowledge.

**Solution:**
Add notes to device, create tickets, update documentation.

---

## Quick Decision Matrix

| Score | Status | Action | Timeframe |
|-------|--------|--------|----------|
| 90-100 | Excellent | None | - |
| 80-89 | Good | Monitor | Weekly check |
| 70-79 | Fair | Investigate | 24-48 hours |
| 60-69 | Poor | Investigate | Same day |
| 40-59 | Critical | Fix | Immediately |
| 0-39 | Severe | Escalate | Immediately |

---

## Getting Help

### When Score Doesn't Make Sense

1. Check field history (data error?)
2. Review calculation logic (see documentation)
3. Validate with other metrics
4. Ask colleague for second opinion
5. Escalate if still unclear

### When You're Unsure How to Fix

1. Consult "Responding to Alerts" guide
2. Review "Device Health Investigation" guide
3. Check WAF FAQ
4. Ask team in Slack/Teams
5. Create ticket for escalation

---

## Related Guides

- **Device Health Investigation:** Deep-dive methodology
- **Responding to Alerts:** Alert-specific playbooks
- **First Day with WAF:** Getting started
- **FAQ:** Common questions answered

---

## Summary

**Key Takeaways:**

1. Overall health score = weighted average of 4 components
2. Always drill into component scores for details
3. Color coding: Green (90+), Yellow (70-89), Red (<70)
4. Review trends, not just current values
5. Lower scores = higher priority
6. Document your investigations
7. Use custom views and filters for efficiency

**Daily Habit:**
Morning check → Respond to alerts → End of day review

**Remember:**
The dashboard is a tool to help you prioritize and investigate efficiently. Trust the data, but validate with your knowledge and user reports.

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Next Review:** March 2026
