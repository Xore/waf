# Responding to Alerts - Technician Guide

**Purpose:** Step-by-step playbook for alert response  
**Skill Level:** Beginner to Intermediate  
**Estimated Time:** 5-30 minutes per alert  
**Last Updated:** February 9, 2026

---

## Alert Response Overview

WAF alerts notify you when devices cross critical thresholds. This guide helps you respond effectively and efficiently.

---

## Alert Severity Levels

### Critical (Red)
**Response Time:** Within 1 hour  
**Escalate If:** Cannot resolve in 2 hours

**Common Critical Alerts:**
- Health score <40
- Disk space <5%
- Multiple system crashes
- Security protection disabled
- Mission-critical device affected

### Warning (Yellow)
**Response Time:** Same business day  
**Escalate If:** Cannot resolve in 8 hours

**Common Warning Alerts:**
- Health score 40-59
- Disk space 5-15%
- Increasing error counts
- Missing important updates
- Capacity trending toward full

### Informational (Blue)
**Response Time:** Within 1 week  
**Escalate If:** Pattern emerges

**Common Info Alerts:**
- Health score 60-74
- Routine maintenance due
- Configuration drift detected
- Non-critical updates available

---

## Standard Alert Response Process

### Step 1: Acknowledge (30 seconds)

**Actions:**
1. Open alert in NinjaRMM
2. Read alert message completely
3. Click "Acknowledge" button
4. Note alert time and severity

**Why:** Lets team know someone is working on it

### Step 2: Assess (2-3 minutes)

**Questions to answer:**
- What device is affected?
- What triggered the alert?
- Is device online?
- Is user currently working?
- Is this business hours?
- Any recent changes to device?

**Check in NinjaRMM:**
- Device status (online/offline)
- Last contact time
- Recent activity logs
- Other active alerts

### Step 3: Investigate (5-15 minutes)

**Open device details:**
1. Navigate to affected device
2. Go to Custom Fields
3. Find the field that triggered alert
4. Review related fields
5. Check component scores
6. Review recent history

**Document findings:**
- Current field values
- When issue started (timestamp)
- Trend (getting better/worse)
- Related issues found

### Step 4: Diagnose (5-10 minutes)

**Determine root cause:**
- Is this expected? (maintenance, known issue)
- Is this device-specific? (hardware, user)
- Is this widespread? (multiple devices)
- Is this new? (recent change, update)

**Use troubleshooting flowcharts:**
- Script Execution Failure
- Field Not Populating
- Performance Impact
- Alert False Positive

### Step 5: Resolve or Escalate (Variable)

**Can you fix it?**

**YES - Proceed with fix:**
1. Plan remediation steps
2. Get approval if needed
3. Execute fix
4. Verify resolution
5. Update alert with resolution
6. Close alert

**NO - Escalate:**
1. Document investigation
2. Capture screenshots
3. Note attempted fixes
4. Escalate to appropriate team
5. Update alert status
6. Follow up later

### Step 6: Document (2-5 minutes)

**Add alert comment:**
```
Investigated: [Time]
Root Cause: [Brief description]
Action Taken: [What you did]
Result: [Resolved/Escalated/Monitoring]
Follow-up: [If needed]
```

**Update ticket if applicable**

---

## Alert-Specific Playbooks

### Playbook 1: Health Score Critical (<40)

**Alert Message:** "Device health score is critical (XX)"

**Immediate Actions:**

1. **Check Device Online Status**
   - If offline: Contact user, check network
   - If online: Proceed to step 2

2. **Review Component Scores**
   ```
   opsStabilityScore:    XX
   opsPerformanceScore:  XX
   opsSecurityScore:     XX
   opsCapacityScore:     XX
   ```
   Identify lowest score(s)

3. **Investigate Lowest Score:**

   **If Stability is lowest (<40):**
   - Check `statCrashCount30d` (crashes)
   - Check `statErrorCount30d` (errors)
   - Review System event log
   - Look for: repeated crashes, driver issues
   - **Common fixes:** Update drivers, repair Windows, replace hardware

   **If Performance is lowest (<40):**
   - Check `statAvgCPUUsage` (should be <80%)
   - Check `statAvgMemoryUsage` (should be <85%)
   - Review running processes
   - Look for: malware, resource hogs, insufficient specs
   - **Common fixes:** Remove malware, kill processes, add RAM

   **If Security is lowest (<40):**
   - Check `secAntivirusEnabled` (must be true)
   - Check `secFirewallEnabled` (must be true)
   - Check `secAntivirusUpdated` (must be true)
   - Look for: disabled protection, outdated definitions
   - **Common fixes:** Enable AV/firewall, update definitions

   **If Capacity is lowest (<40):**
   - Check `capDiskFreePercent` (should be >15%)
   - Check `capMemoryUsedPercent` (should be <85%)
   - Review disk space usage
   - Look for: full disk, temp files, logs
   - **Common fixes:** Disk cleanup, delete temps, expand storage

4. **Take Action**
   - Execute appropriate fix
   - Monitor for 24 hours
   - Verify score improves

5. **Escalate If:**
   - Multiple components critical
   - Hardware failure suspected
   - No clear fix available
   - User productivity impacted

---

### Playbook 2: Disk Space Critical (<5%)

**Alert Message:** "Disk space critically low (X% free)"

**Immediate Actions:**

1. **Verify Alert**
   - Check `capDiskFreeGB` (how much free?)
   - Check `capDiskTotalGB` (total size?)
   - Calculate: X GB free out of Y GB total

2. **Check Forecast**
   - Check `capForecastDaysFull` (days until full)
   - If <7 days: URGENT
   - If <3 days: CRITICAL

3. **Quick Wins (5 minutes)**
   - Empty Recycle Bin
   - Delete temp files: `C:\Windows\Temp`
   - Clear browser caches
   - Run Disk Cleanup (cleanmgr.exe)

4. **Deeper Investigation**
   - Use TreeSize/WinDirStat
   - Identify large files/folders
   - Check for:
     - Old backups
     - Log files
     - Downloads folder
     - User profiles (temp data)

5. **Common Culprits**
   - Windows Update cache
   - Print spooler
   - SQL databases
   - VM snapshots
   - User PST files

6. **Long-term Solutions**
   - Archive old data
   - Expand disk (if VM)
   - Add storage
   - Implement retention policies

7. **Verify Resolution**
   - Confirm >15% free
   - Wait for next script run
   - Check score improves

---

### Playbook 3: Security Protection Disabled

**Alert Message:** "Antivirus or Firewall disabled"

**Immediate Actions:**

1. **Verify Status**
   - Check `secAntivirusEnabled` (should be true)
   - Check `secFirewallEnabled` (should be true)
   - Check `secAntivirusProduct` (which AV?)

2. **Contact User FIRST**
   - Ask if they disabled it
   - Ask if IT disabled it (maintenance)
   - If yes to either: Document and close
   - If no: Security incident possible

3. **Check Device Remotely**
   - Open Security Center
   - Verify actual status
   - Check for conflicts

4. **Re-enable Protection**
   
   **Antivirus:**
   - Open AV console
   - Enable real-time protection
   - Update definitions
   - Run quick scan

   **Firewall:**
   - Open Windows Security
   - Enable firewall (all profiles)
   - Verify rules intact
   - Test connectivity

5. **Investigate Why Disabled**
   - Check event logs
   - Look for:
     - User action
     - Malware activity
     - Software conflict
     - Group Policy change

6. **Security Scan**
   - Run full antivirus scan
   - Run anti-malware scan
   - Check for rootkits
   - Review installed programs

7. **Escalate If:**
   - Cannot re-enable
   - Malware suspected
   - User didn't disable
   - Protection repeatedly disabled

---

### Playbook 4: Update Compliance Failure

**Alert Message:** "Missing critical updates (X updates)"

**Immediate Actions:**

1. **Check Update Status**
   - Check `updMissingCriticalCount` (how many?)
   - Check `updLastPatchDate` (when last updated?)
   - Check `updLastPatchCheck` (when last checked?)

2. **Verify Windows Update Service**
   - Confirm service running
   - Check for errors
   - Review update history

3. **Check Maintenance Window**
   - Is device in maintenance window?
   - Can we update now?
   - Is user working?

4. **Initiate Update Check**
   - Run Windows Update manually
   - Download missing updates
   - Note any failures

5. **Common Update Issues**
   
   **Updates won't download:**
   - Check disk space (need >10 GB)
   - Check internet connectivity
   - Check WSUS connectivity
   - Clear update cache

   **Updates won't install:**
   - Check for pending reboot
   - Review error codes
   - Check for conflicts
   - Run DISM/SFC

   **Updates keep failing:**
   - Reset Windows Update components
   - Use Update Troubleshooter
   - Manual install problem updates
   - Consider in-place upgrade

6. **Schedule Reboot**
   - Coordinate with user
   - Schedule during maintenance
   - Verify updates apply
   - Confirm post-reboot

7. **Verify Resolution**
   - Check `updMissingCriticalCount` = 0
   - Confirm `updLastPatchDate` updated
   - Score improves within 24h

---

### Playbook 5: Performance Degradation

**Alert Message:** "Performance score below threshold (XX)"

**Immediate Actions:**

1. **Check Performance Metrics**
   - Check `statAvgCPUUsage` (target <80%)
   - Check `statAvgMemoryUsage` (target <85%)
   - Check `statAvgDiskUsage` (target <85%)

2. **Contact User**
   - Are they experiencing slowness?
   - When did it start?
   - What tasks are slow?

3. **Remote Investigation**
   
   **High CPU:**
   - Open Task Manager
   - Sort by CPU usage
   - Identify top processes
   - Check for:
     - Malware (suspicious names)
     - System processes (updates, scans)
     - User applications (heavy workload)
   - Action: Kill if safe, scan if suspicious

   **High Memory:**
   - Check available RAM
   - Identify memory hogs
   - Check for:
     - Memory leaks (growing over time)
     - Too many programs running
     - Insufficient RAM for workload
   - Action: Restart apps, close unnecessary, add RAM

   **High Disk:**
   - Check disk activity
   - Identify what's reading/writing
   - Check for:
     - Windows updates
     - Antivirus scan
     - Backup running
     - Disk issues (bad sectors)
   - Action: Wait if temporary, check disk health

4. **Quick Fixes**
   - Restart device (if user agrees)
   - Disable startup programs
   - Update drivers
   - Check for Windows updates
   - Run disk optimization

5. **Monitor**
   - Check metrics after 2 hours
   - Verify improvement
   - Follow up with user

---

## Alert Response Time Guidelines

| Severity | Response | Investigation | Resolution | Total |
|----------|----------|---------------|------------|-------|
| Critical | <15 min | 15-30 min | 1-2 hours | <3 hours |
| Warning | <1 hour | 30-60 min | 2-4 hours | <8 hours |
| Info | <4 hours | As needed | 1-2 days | <1 week |

---

## Escalation Criteria

**Escalate immediately if:**
- Security incident suspected
- Data loss risk
- Mission-critical system down
- Multiple devices affected (>10%)
- Unable to diagnose within 30 minutes
- Fix requires approval
- User VIP/executive
- After-hours emergency

**Escalation paths:**
- Security issues → Security team
- Hardware issues → Hardware team
- Network issues → Network team
- Complex issues → Senior technician
- Business impact → Management

---

## Documentation Requirements

**Every alert must have:**
- Acknowledgment time
- Investigation summary
- Root cause (if found)
- Actions taken
- Resolution or escalation
- Follow-up required?

**Use this template:**
```
Alert: [Alert name]
Device: [Device name]
Severity: [Critical/Warning/Info]
Acknowledged: [Time]
Investigated: [Time]

Findings:
- [Key finding 1]
- [Key finding 2]

Root Cause: [Description]

Actions:
1. [Action 1]
2. [Action 2]

Result: [Resolved/Escalated/Monitoring]

Follow-up: [If needed]

Closed: [Time]
```

---

## Best Practices

**1. Acknowledge Fast**
Let team know you're on it (30 seconds)

**2. Investigate Before Acting**
Understand before fixing (5-10 minutes)

**3. Document As You Go**
Capture findings immediately

**4. Communicate Proactively**
Update users and team regularly

**5. Verify Resolution**
Don't assume - confirm fix worked

**6. Learn from Patterns**
If same alert repeats, find root cause

**7. Ask for Help**
Escalate when stuck (don't waste time)

**8. Close Properly**
Complete documentation before closing

---

## Common Mistakes to Avoid

**❌ Closing without investigating**
Result: Issue persists, recurs

**❌ Acting without understanding**
Result: Make problem worse

**❌ Not contacting user**
Result: Disrupt their work unexpectedly

**❌ Incomplete documentation**
Result: Next person starts from zero

**❌ Ignoring patterns**
Result: Miss systemic issues

**❌ Delayed escalation**
Result: SLA breach, user frustration

**❌ Not verifying fix**
Result: False closure, repeat alerts

---

## After Your First Month

**Skills you'll develop:**
- Recognize patterns instantly
- Diagnose faster (3-5 minutes)
- Know common fixes by heart
- Prevent false positives
- Tune thresholds effectively

**Advanced techniques:**
- Batch similar alerts
- Automate common fixes
- Predict issues before alerts
- Mentor new technicians
- Improve alert conditions

---

## Quick Reference Card

**Print this section for your desk:**

```
WAF ALERT RESPONSE CHEAT SHEET

1. ACKNOWLEDGE (30s)
   - Open alert
   - Click acknowledge
   
2. ASSESS (2m)
   - Device online?
   - User working?
   - Recent changes?
   
3. INVESTIGATE (10m)
   - Review field values
   - Check component scores
   - Use flowcharts
   
4. DIAGNOSE (10m)
   - Expected?
   - Device-specific?
   - Widespread?
   
5. FIX or ESCALATE
   - Can I fix? → Do it
   - Can't fix? → Escalate
   
6. DOCUMENT (5m)
   - What found
   - What did
   - Result
   
7. VERIFY (24h)
   - Score improved?
   - Alert cleared?
   - User happy?

CRITICAL → 1h response
WARNING → 8h response
INFO → 1w response

ESCALATE IF:
- Security incident
- Can't diagnose
- Multiple devices
- Business impact
```

---

**Remember:** Every alert is an opportunity to prevent a bigger problem. Respond promptly, investigate thoroughly, document completely.

**Last Updated:** February 9, 2026, 8:12 PM CET
