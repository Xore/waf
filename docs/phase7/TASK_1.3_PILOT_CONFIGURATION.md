# Task 1.3: Pilot Device Configuration Guide

**Task:** Configure 5-10 Pilot Devices  
**Phase:** 7.1 - Foundation Deployment  
**Priority:** P1 (Critical)  
**Status:** ⏸️ PENDING (Depends on Task 1.2)  
**Estimated Time:** 1 hour

---

## Overview

This guide provides instructions for selecting and configuring the initial pilot devices for Phase 7.1 foundation deployment testing.

---

## Prerequisites

- [ ] Task 1.1 complete (50 core fields created)
- [ ] Task 1.2 complete (13 core scripts deployed)
- [ ] NinjaRMM admin access
- [ ] Access to test devices

---

## Pilot Device Selection Criteria

### Required Characteristics

**Diversity:**
- Mix of Windows 10 and Windows 11
- At least one Windows Server (if available)
- Both domain-joined and workgroup devices
- Various hardware configurations

**Safety:**
- Non-production or low-criticality systems
- IT team members' devices preferred
- Devices that can be monitored closely
- Systems with flexible reboot schedules

**Availability:**
- Devices online during business hours
- Stable network connectivity
- Active NinjaRMM agents
- Recent agent communication (< 1 hour)

### Recommended Pilot Devices

**Minimum Pilot (5 devices):**
1. IT Admin workstation (Windows 11, domain-joined)
2. IT Support workstation (Windows 10, domain-joined)
3. Test workstation (Windows 11, workgroup)
4. Test server (Windows Server 2022, if available)
5. Developer workstation (Windows 10/11, domain-joined)

**Optimal Pilot (10 devices):**
- 5 devices above PLUS:
6. Marketing workstation (Windows 11)
7. Finance workstation (Windows 10)
8. Remote worker laptop (Windows 11)
9. Conference room PC (Windows 10)
10. Lab test system (Windows Server 2019)

---

## Device Selection Process

### Step 1: Identify Candidate Devices

1. Navigate to **Devices** in NinjaRMM
2. Filter devices:
   - Status: Online
   - Last Contact: < 1 hour
   - Agent Version: Current
3. Review device list
4. Note potential pilot candidates

### Step 2: Validate Device Suitability

For each candidate device, verify:

**Technical Checks:**
- [ ] Agent communicating normally
- [ ] No critical alerts active
- [ ] Sufficient disk space (> 10 GB free)
- [ ] PowerShell 5.1+ installed
- [ ] Remote execution enabled

**Business Checks:**
- [ ] Device owner approves participation
- [ ] Non-critical workload
- [ ] Can accommodate monitoring overhead
- [ ] Available for troubleshooting if needed

### Step 3: Document Selected Devices

Create pilot device inventory:

```
Pilot Device Inventory - Phase 7.1

Device 1:
  Name: IT-ADMIN-01
  OS: Windows 11 Pro 23H2
  Domain: CONTOSO\IT-Admin
  Owner: John Doe
  Role: IT Administration
  Notes: Primary pilot device

Device 2:
  Name: IT-SUPPORT-02
  OS: Windows 10 Pro 22H2
  Domain: CONTOSO\IT-Support
  Owner: Jane Smith
  Role: IT Support
  Notes: Secondary pilot

[Continue for all devices...]
```

---

## Configuration Steps

### Step 1: Create Device Group

1. Navigate to **Administration > Device Groups**
2. Click **Add Device Group**
3. Configure group:
   ```
   Name: WAF Pilot - Phase 7.1
   Description: Initial pilot devices for WAF foundation deployment
   Type: Static
   ```
4. Click **Save**

### Step 2: Add Devices to Group

1. For each pilot device:
   - Navigate to device details
   - Click **Edit**
   - Add to group: "WAF Pilot - Phase 7.1"
   - Click **Save**

2. Verify all devices added:
   - Go to Device Groups
   - Open "WAF Pilot - Phase 7.1"
   - Confirm device count (should be 5-10)

### Step 3: Tag Pilot Devices

1. Create custom tag: **waf-pilot-7.1**
2. Apply tag to all pilot devices:
   - Select all pilot devices (bulk action)
   - Add tag: waf-pilot-7.1
   - Confirm

### Step 4: Configure Automation Policies

**Policy 1: WAF Core - Daily**

1. Navigate to **Automation > Scheduled Automations**
2. Open policy: "WAF Core - Daily"
3. Configure targeting:
   ```
   Target Type: Device Group
   Group: WAF Pilot - Phase 7.1
   ```
4. Save policy
5. Enable policy

**Policy 2: WAF Core - Every 8 Hours**

1. Open policy: "WAF Core - Every 8 Hours"
2. Configure targeting:
   ```
   Target Type: Device Group
   Group: WAF Pilot - Phase 7.1
   ```
3. Save policy
4. Wait 1 hour for initial execution
5. Enable policy

**Policy 3: WAF Core - Every 4 Hours**

1. Open policy: "WAF Core - Every 4 Hours"
2. Configure targeting:
   ```
   Target Type: Device Group
   Group: WAF Pilot - Phase 7.1
   ```
3. Save policy
4. Wait 1 hour
5. Enable policy

**Policy 4: WAF Core - Every 2 Hours**

1. Open policy: "WAF Core - Every 2 Hours"
2. Configure targeting:
   ```
   Target Type: Device Group
   Group: WAF Pilot - Phase 7.1
   ```
3. Save policy
4. Wait 1 hour
5. Enable policy

### Step 5: Verify Policy Assignment

1. Navigate to each pilot device
2. Check **Automation** tab
3. Verify all 4 WAF policies are active:
   - [ ] WAF Core - Daily
   - [ ] WAF Core - Every 8 Hours
   - [ ] WAF Core - Every 4 Hours
   - [ ] WAF Core - Every 2 Hours

---

## Initial Monitoring

### Hour 1-2: Daily Scripts

Monitor execution of:
- Script 13: Configuration Manager (1 AM)
- Script 12: Baseline Manager (2 AM)
- Script 9: Device Information Collector (3 AM)
- Script 10: Group Policy Monitor (4 AM)

**Check:**
- Scripts execute successfully
- No timeout errors
- Execution times reasonable (<90s)

### Hour 3-4: 8-Hour Scripts

Monitor execution of:
- Script 5: Capacity Monitor
- Script 6: Update Compliance Checker

**Check:**
- Scripts complete within timeout
- Fields begin populating
- No permission errors

### Hour 5-6: 4-Hour Scripts

Monitor execution of:
- Script 2: System Stability Monitor
- Script 3: Performance Metrics Collector
- Script 4: Security Posture Scanner
- Script 7: Uptime Tracker
- Script 11: Network Monitor

**Check:**
- All scripts execute
- Multiple fields populate
- No conflicts or errors

### Hour 7-8: 2-Hour Scripts

Monitor execution of:
- Script 8: Error Event Monitor

**Check:**
- Frequent execution successful
- No resource impact
- Event log reading works

### Hour 9+: Health Score

Monitor execution of:
- Script 1: Health Score Calculator

**Check:**
- Health scores calculated
- Scores within 0-100 range
- Status values populated

---

## Communication Plan

### Notify Pilot Users

Send email to pilot device owners:

```
Subject: WAF Monitoring Pilot - Phase 7.1 Starting

Hello [Name],

Your device [Device Name] has been selected for the Windows Automation 
Framework (WAF) monitoring pilot program.

What to Expect:
- Automated monitoring scripts will run periodically
- Scripts run in background with minimal impact
- No action required from you
- Monitoring begins: [Date/Time]
- Duration: 7-14 days

What We're Monitoring:
- System health and stability
- Performance metrics
- Security posture
- Capacity usage
- Update compliance

Impact:
- Negligible performance impact
- Scripts run as background tasks
- No interruption to your work

Contact:
- Questions: it-team@company.com
- Issues: Submit ticket
- Feedback: waf-pilot@company.com

Thank you for participating!

IT Operations Team
```

---

## Validation Checklist

### Configuration Complete
- [ ] 5-10 pilot devices selected
- [ ] Device group created
- [ ] Devices added to group
- [ ] Pilot tag applied
- [ ] All 4 automation policies configured
- [ ] Policies enabled in sequence
- [ ] Policy assignment verified on devices
- [ ] Pilot users notified

### Ready for Task 1.4
- [ ] 24 hours elapsed since policy enablement
- [ ] All scripts executed at least once
- [ ] No critical errors in logs
- [ ] Fields beginning to populate
- [ ] Device owners report no issues

---

## Troubleshooting

### Issue: Device Not Receiving Scripts
**Solutions:**
- Verify device in group
- Check agent online
- Review policy targeting
- Force policy sync

### Issue: Scripts Failing on Specific Device
**Solutions:**
- Check device event logs
- Verify PowerShell version
- Test script manually
- Review permissions

### Issue: User Reports Performance Impact
**Solutions:**
- Review script execution times
- Check for concurrent execution
- Adjust scheduling if needed
- Consider removing device from pilot

---

## Next Steps

After completing Task 1.3:

1. **Wait 24 hours** - Allow full execution cycle
2. **Monitor continuously** - Watch for errors or issues
3. **Task 1.4** - Perform initial validation
4. **Document findings** - Note any issues or concerns

---

**Task Status:** ⏸️ Ready to Begin (After Task 1.2)  
**Prerequisites:** Scripts deployed and scheduled  
**Estimated Time:** 1 hour + 24-hour wait  
**Next Task:** Task 1.4 - Initial Validation
