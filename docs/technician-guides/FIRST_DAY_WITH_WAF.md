# First Day with WAF - Technician Guide

**Purpose:** Onboarding guide for technicians new to WAF  
**Estimated Time:** 30 minutes to read, 1 hour to practice  
**Last Updated:** February 9, 2026

---

## Welcome to WAF!

The Windows Automation Framework (WAF) is a comprehensive monitoring system that automatically tracks 277+ metrics across all your Windows devices. This guide will help you get started.

---

## What is WAF?

**In Simple Terms:**
WAF is like a fitness tracker for computers. Just like a fitness tracker monitors your heart rate, steps, and sleep, WAF monitors your devices' health, security, performance, and capacity - all automatically.

**Technical Definition:**
WAF is an automated monitoring framework that:
- Collects 277+ data points per device
- Runs 110 PowerShell scripts on schedules
- Calculates health scores (0-100)
- Updates dashboards in real-time
- Triggers alerts when thresholds are exceeded
- Requires zero manual intervention

---

## Why WAF Exists

**Before WAF:**
- Manual device checks (time-consuming)
- Reactive problem-solving (fixing after it breaks)
- Limited visibility (can't see everything)
- Inconsistent monitoring (depends who checks)
- Missed issues (slips through cracks)

**With WAF:**
- Automatic monitoring (24/7 visibility)
- Proactive problem-prevention (fix before it breaks)
- Comprehensive visibility (277+ metrics)
- Consistent monitoring (same for all devices)
- Nothing missed (algorithms never sleep)

---

## Your First 10 Minutes

### Step 1: Open NinjaRMM (2 minutes)

1. Log into NinjaRMM
2. Navigate to **Dashboards**
3. Open **WAF - Health Overview** dashboard
4. Bookmark this page (you'll visit it daily)

### Step 2: Understand Health Scores (3 minutes)

**What you see:**
- Device list with scores (0-100)
- Color coding (green/yellow/red)
- Overall health score per device

**What the scores mean:**
- **90-100:** Excellent - Device is healthy
- **75-89:** Good - Device is fine, minor improvements possible
- **60-74:** Fair - Needs attention soon
- **40-59:** Poor - Action required
- **0-39:** Critical - Immediate attention needed

**Color coding:**
- 🟢 **Green (75-100):** Healthy - No action needed
- 🟡 **Yellow (60-74):** Warning - Review this week
- 🔴 **Red (0-59):** Critical - Review today

### Step 3: Pick a Healthy Device (2 minutes)

1. Find a device with score 80-95 (green)
2. Click on the device name
3. This opens device details

### Step 4: Explore Custom Fields (3 minutes)

1. Scroll to **Custom Fields** section
2. Look for fields starting with:
   - **ops** = Operations (health, status)
   - **stat** = Statistics (counts, averages)
   - **sec** = Security (antivirus, firewall)
   - **cap** = Capacity (disk, memory)
   - **upd** = Updates (patch status)

3. Notice the data:
   - All fields are populated
   - Timestamps are recent
   - Values make sense

**This is what "healthy" looks like!**

---

## Your First Task (15 minutes)

### Task: Investigate a Warning Device

**Goal:** Understand why a device has a warning (yellow) score

**Steps:**

1. **Find Warning Device**
   - Go back to dashboard
   - Find device with score 60-74 (yellow)
   - Click device name

2. **Check Overall Health**
   - Find field: `opsHealthScore`
   - Note the value (e.g., 68)
   - Find field: `opsStatus`
   - Should say "Warning"

3. **Check Component Scores**
   Look at these four scores:
   - `opsStabilityScore` (crashes, errors)
   - `opsPerformanceScore` (CPU, memory)
   - `opsSecurityScore` (AV, firewall)
   - `opsCapacityScore` (disk, memory)

4. **Identify Low Score**
   Which score is lowest?
   - If Stability is low: Check `statCrashCount30d`, `statErrorCount30d`
   - If Performance is low: Check `statAvgCPUUsage`, `statAvgMemoryUsage`
   - If Security is low: Check `secAntivirusEnabled`, `secFirewallEnabled`
   - If Capacity is low: Check `capDiskFreePercent`, `capMemoryUsedPercent`

5. **Understand the Issue**
   Example:
   - Capacity score = 55 (low!)
   - `capDiskFreePercent` = 8%
   - **Problem:** Disk almost full
   - **Action:** Free up space or expand disk

**Congratulations!** You just performed your first WAF investigation.

---

## Common Daily Tasks

### Morning Routine (10 minutes)

**1. Check Critical Alerts (2 min)**
- Review any new alerts from overnight
- Prioritize by severity (Critical > Warning > Info)
- Acknowledge or assign alerts

**2. Review Dashboard (5 min)**
- Open WAF - Health Overview
- Scan for red devices (critical)
- Note any new yellow devices (warnings)
- Check if yesterday's issues improved

**3. Quick Trend Check (3 min)**
- Are scores generally improving or declining?
- Any devices consistently problematic?
- Any patterns (same issues across multiple devices)?

### Throughout the Day

**When Alert Arrives:**
1. Read alert message (what triggered it?)
2. Check device in dashboard (current status?)
3. Review related fields (root cause?)
4. Take action or escalate
5. Document resolution

**When User Reports Issue:**
1. Find device in NinjaRMM
2. Check WAF health score (already monitoring it?)
3. Review component scores (which area is problem?)
4. Use WAF data to troubleshoot faster
5. Document findings

---

## Understanding the Data

### Data Freshness

**How often is data updated?**
- Core metrics: Every 2-8 hours
- Health scores: Daily
- Real-time data: Not real-time (scheduled updates)

**Last update timestamps:**
- Check `opsLastHealthCheck` field
- Should be within last 24 hours
- If older, agent may be offline

### Data Accuracy

**Can I trust the data?**
- Yes, it comes directly from Windows
- Scripts run with SYSTEM privileges
- Data sources: WMI, Event Logs, Registry
- Validated through multiple checks

**What if data seems wrong?**
1. Check timestamp (is it current?)
2. Verify on device manually
3. Check script execution logs
4. Report discrepancy to team lead

---

## Common Questions (Quick Answers)

**Q: Do I still need to manually check devices?**
A: For routine monitoring, no. For specific troubleshooting, yes.

**Q: Will WAF fix issues automatically?**
A: Not in Phase 7.1. Auto-remediation comes in Phase 7.2 (opt-in).

**Q: What if a device shows score 0?**
A: Either agent offline, monitoring not enabled, or critical failure. Investigate immediately.

**Q: Can I customize thresholds?**
A: Yes, but requires admin access. Speak with WAF administrator.

**Q: How do I learn more?**
A: Read other technician guides in this folder, ask team lead, refer to FAQ.

---

## Key Dashboards to Know

### 1. WAF - Health Overview
**Purpose:** Daily operational dashboard
**When to use:** Every morning, throughout day
**Shows:** All devices, health scores, status

### 2. WAF - Security Posture
**Purpose:** Security compliance monitoring
**When to use:** Weekly review, after security alerts
**Shows:** AV status, firewall, encryption, vulnerabilities

### 3. WAF - Capacity Planning
**Purpose:** Resource usage and forecasting
**When to use:** Monthly planning, before capacity issues
**Shows:** Disk usage, memory, growth trends, forecasts

### 4. WAF - Critical Devices
**Purpose:** High-priority device monitoring
**When to use:** Multiple times daily
**Shows:** Only mission-critical devices, detailed status

---

## Pro Tips for New Technicians

**1. Start with Green Devices**
Learn what "healthy" looks like before investigating problems.

**2. Compare Similar Devices**
Look at multiple devices of same type - what's different?

**3. Watch Trends, Not Points**
One bad day doesn't mean disaster. Look for patterns over time.

**4. Use Ctrl+F**
In device details, use browser search to find specific fields quickly.

**5. Bookmark Key Pages**
- Main dashboard
- Critical devices view
- Your favorite device (for practice)

**6. Set Up Alerts**
Ask admin to configure alerts for your team/devices.

**7. Document Your Findings**
Note what you learn - helps you and future you.

**8. Ask Questions**
Your team wants you to succeed. Ask when unsure.

---

## Hands-On Practice Exercise

**Time:** 30 minutes  
**Goal:** Get comfortable navigating WAF data

### Exercise 1: Find Specific Data (10 min)

Pick any device and find:
1. When was it last booted?
2. How much disk space is free?
3. How many errors occurred in last 30 days?
4. Is BitLocker enabled?
5. When was last Windows Update installed?

### Exercise 2: Compare Two Devices (10 min)

Pick two similar devices (same OS, same role) and compare:
1. Which has better health score?
2. Which has more available disk space?
3. Which has fewer errors?
4. What's different about security settings?
5. Which would you upgrade first and why?

### Exercise 3: Predict Tomorrow (10 min)

Pick one yellow (warning) device and:
1. Identify the lowest component score
2. Research what field values caused it
3. Predict: Will it be better or worse tomorrow?
4. Document your prediction
5. Check tomorrow to see if you were right!

---

## What's Next?

**After Your First Day:**
1. Read "Reading the Dashboard" guide
2. Review "Responding to Alerts" guide
3. Practice daily dashboard review
4. Shadow experienced technician
5. Ask to join WAF team chat

**After Your First Week:**
1. Read "Device Health Investigation" guide
2. Take on first alert response
3. Learn to identify patterns
4. Share your findings with team

**After Your First Month:**
1. Read "Common Maintenance Tasks" guide
2. Lead your first investigation
3. Mentor next new technician
4. Suggest improvements to team

---

## Help & Resources

**Documentation:**
- Field Quick Reference (all 277+ fields explained)
- Script Quick Reference (what each script does)
- Troubleshooting Flowcharts (decision trees)
- FAQ (50+ questions answered)

**People:**
- Team Lead: [Name]
- WAF Administrator: [Name]
- Escalation: [Contact]

**Tools:**
- NinjaRMM Dashboard (primary interface)
- Documentation Wiki (knowledge base)
- Team Chat (real-time help)

---

## Remember

**WAF is a Tool, Not a Replacement:**
- It enhances your capabilities
- It doesn't replace your expertise
- It gives you superpowers (visibility)
- You still make the decisions

**You'll Get Better:**
- First day: Overwhelming
- First week: Making sense
- First month: Confident
- First quarter: Expert

**We're Here to Help:**
- Questions are expected
- Learning takes time
- Team supports you
- You've got this!

---

**Welcome to the team! 🚀**

**Last Updated:** February 9, 2026, 1:20 AM CET
