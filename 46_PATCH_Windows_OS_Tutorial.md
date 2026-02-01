# Windows OS Patching Tutorial - Complete Guide
**File:** 46_PATCH_Windows_OS_Tutorial.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026  
**Applies To:** Windows Server 2016+, Windows 10/11

---

## OVERVIEW

This tutorial provides step-by-step instructions for configuring automated Windows operating system patching using NinjaOne's native patch management combined with the ring-based deployment framework [web:338][web:339].

### What You'll Learn
- Configure Windows Update policies in NinjaOne
- Set up ring-based OS patch deployment
- Apply patches to Windows Server and Windows Workstation
- Configure reboot policies
- Monitor patch deployment status
- Troubleshoot common OS patching issues

---

## PART 1: NINJONE WINDOWS UPDATE CONFIGURATION

### Step 1: Access Patch Management Dashboard

**Navigate to:** NinjaOne Dashboard > Patching > Patch Management

**What You'll See:**
- Patch compliance overview
- Devices needing attention
- Failed patches
- Pending approvals [web:339]

---

### Step 2: Configure Windows Update Settings

**Navigate to:** Administration > Patching > Settings

**Configure Global Settings:**

#### Update Detection
```
Scan Frequency: Every 4 hours
Scan Method: Windows Update Agent (WUA)
Include Optional Updates: No (unchecked)
Include Driver Updates: Yes (for servers), No (for workstations)
Include Feature Updates: Require Approval (manual)
```

**Rationale:**
- 4-hour scan ensures patches detected quickly [web:338]
- Optional updates excluded (bloatware risk)
- Drivers included for servers (stability), excluded for workstations (compatibility)
- Feature updates require approval (major changes need validation)

---

#### Patch Approval Defaults
```
Critical Updates: Auto-approve after 2 days (Ring 0 validation period)
Security Updates: Auto-approve after 2 days
Important Updates: Auto-approve after 7 days (Ring 1 validation period)
Recommended Updates: Require Approval (manual)
Optional Updates: Auto-reject
Definition Updates: Auto-approve immediately (antivirus definitions)
```

**Rationale:**
- Critical/Security patches auto-approved after Ring 0 testing (2 days) [web:330]
- Important patches wait for Ring 1 validation (7 days)
- Recommended/Optional require manual review (avoid bloat)

---

#### Reboot Behavior Defaults
```
Reboot if Required: Yes (enabled)
Maximum Reboot Delay: 4 hours
Force Reboot After Delay: Yes (enabled)
Suppress Reboot Notifications: No (users should know)
Allow User to Defer Reboot: Yes, up to 3 times (workstations only)
```

**Rationale:**
- Servers: Force reboot to complete patching
- Workstations: Allow user deferral (business hour protection)
- 4-hour delay gives users time to save work [web:342]

---

### Step 3: Create Windows Update Policy Templates

NinjaOne allows policy templates per device type. Create 2 templates:

#### Template 1: Windows Server OS Patching
**Name:** Windows Server - OS Patches - Ring-Based

**Patch Types:**
- ☑ Critical Updates
- ☑ Security Updates
- ☑ Important Updates
- ☑ Drivers (server hardware only)
- ☐ Feature Updates (manual approval)
- ☐ Optional Updates

**Approval Settings:**
- Auto-approve Critical/Security: After 2 days
- Auto-approve Important: After 7 days
- Require approval for: Feature Updates, Drivers (optional)

**Reboot Settings:**
- Reboot if required: Yes
- Reboot delay: 15 minutes
- Force reboot: Yes, after 30 minutes
- Notify users: Yes (if logged in)

**Maintenance Window:**
- Use device-specific window (from PATCHMaintenanceWindow field)
- Fallback: Saturday 22:00-02:00

---

#### Template 2: Windows Workstation OS Patching
**Name:** Windows Workstation - OS Patches - Ring-Based

**Patch Types:**
- ☑ Critical Updates
- ☑ Security Updates
- ☑ Important Updates
- ☐ Drivers (too risky for workstations)
- ☐ Feature Updates (manual approval)
- ☐ Optional Updates

**Approval Settings:**
- Auto-approve Critical/Security: After 2 days
- Auto-approve Important: After 7 days
- Require approval for: Feature Updates

**Reboot Settings:**
- Reboot if required: Yes
- Reboot delay: 2 hours (users need time)
- Force reboot: Yes, after 4 hours
- Allow user to defer: Yes, up to 3 times
- Defer duration: 4 hours per deferral

**Maintenance Window:**
- Use device-specific window (from PATCHMaintenanceWindow field)
- Fallback: Outside business hours (18:00-08:00)

**Save Templates** for use in ring-based policies

---

## PART 2: RING-BASED OS PATCH DEPLOYMENT

### Step 1: Apply Templates to Ring Groups

**Navigate to:** Administration > Patching > Policies > Add Policy

#### Policy 1: Ring 0 - OS Patches (Lab/Test)
**Name:** Ring 0 - Windows OS Patches - Lab/Test

**Apply Policy To:** Dynamic Group "Ring 0 - Lab/Test Devices"

**Template:** 
- Servers: Windows Server - OS Patches - Ring-Based
- Workstations: Windows Workstation - OS Patches - Ring-Based

**Schedule:**
- Day: Tuesday (Patch Tuesday)
- Time: 20:00 (8:00 PM)
- Window: 3 hours

**Override Settings (Ring 0 specific):**
- Auto-approve all patches: Immediately (no delay)
- Force reboot: Immediately (no user deferral)

**Validation Period:** 48 hours (Wednesday-Thursday)

**Save Policy**

---

#### Policy 2: Ring 1 - OS Patches (Pilot Production)
**Name:** Ring 1 - Windows OS Patches - Pilot

**Apply Policy To:** Dynamic Group "Ring 1 - Pilot Production"

**Template:** 
- Servers: Windows Server - OS Patches - Ring-Based
- Workstations: Windows Workstation - OS Patches - Ring-Based

**Schedule:**
- Day: Friday
- Time: 21:00 (9:00 PM)
- Window: 4 hours

**Prerequisites (Advanced Settings):**
- PATCHRingStatus (Ring 0) = "Passed"
- PATCHConfidenceScore (Ring 0) ≥ 90

**Override Settings (Ring 1 specific):**
- Auto-approve: Use template defaults (2/7 day delays)
- Notify IT staff: Yes (email notification)

**Validation Period:** 5 days (Saturday-Wednesday)

**Save Policy**

---

#### Policy 3: Ring 2 - OS Patches (Broad Production)
**Name:** Ring 2 - Windows OS Patches - Broad

**Apply Policy To:** Dynamic Group "Ring 2 - Broad Production"

**Template:** 
- Servers: Windows Server - OS Patches - Ring-Based
- Workstations: Windows Workstation - OS Patches - Ring-Based

**Schedule:**
- Day: 2nd Saturday of deployment cycle
- Time: 22:00 (10:00 PM)
- Window: 4 hours

**Prerequisites:**
- PATCHRingStatus (Ring 1) = "Passed"
- PATCHConfidenceScore (Ring 1) ≥ 85
- Failure Rate (Ring 1) < 2%

**Override Settings:**
- Use template defaults (no overrides)
- Notify all users: 24 hours before deployment

**Validation Period:** 7 days (Sunday-Saturday)

**Save Policy**

---

#### Policy 4: Ring 3 - OS Patches (Critical Production)
**Name:** Ring 3 - Windows OS Patches - Critical

**Apply Policy To:** Dynamic Group "Ring 3 - Critical Production"

**Template:** 
- Servers: Windows Server - OS Patches - Ring-Based
- Workstations: Windows Workstation - OS Patches - Ring-Based

**Schedule:**
- Day: 3rd Saturday of deployment cycle
- Time: 23:00 (11:00 PM)
- Window: 4 hours

**Prerequisites:**
- PATCHRingStatus (Ring 2) = "Passed"
- PATCHConfidenceScore (Ring 2) ≥ 90
- Failure Rate (Ring 2) < 1%
- Manual approval gate: Yes (extra validation step)

**Override Settings (Ring 3 specific):**
- Critical patches only: Exclude Important unless critical
- Extended reboot delay: 60 minutes (critical systems need time)
- Backup verification: Mandatory (must be < 24 hours old)

**Validation Period:** Continuous monitoring (indefinite)

**Save Policy**

---

## PART 3: MONITORING OS PATCH DEPLOYMENT

### Step 1: Real-Time Monitoring Dashboard

**Navigate to:** Patching > Patch Management Dashboard

**Key Widgets to Add:**

#### Widget 1: Patch Deployment Status
- Shows: Devices currently installing patches
- Filter by: Ring (0, 1, 2, 3)
- Refresh: Every 5 minutes

#### Widget 2: Patch Success Rate by Ring
- Shows: Success rate per ring (target: >95%)
- Chart type: Bar chart
- Time period: Last 7 days

#### Widget 3: Devices Needing Reboot
- Shows: Devices with pending reboot after patch
- Alert if: Pending > 4 hours (patch not complete)
- Action: Force reboot or investigate

#### Widget 4: Failed Patches
- Shows: Devices with failed patch installations
- Filter by: Ring, OS version, patch KB number
- Action: Review logs, retry, or exclude patch [web:339]

---

### Step 2: Automated Monitoring (Script PR2)

**Script PR2 monitors OS patching automatically:**

**Every 4 Hours During Validation:**
1. Query patch status for devices in current ring
2. Calculate success rate:
   ```
   Success Rate = (Successful Patches / Total Patches) × 100
   ```
3. Check for critical failures:
   - OS boot failure after patch
   - Windows Update service stopped
   - Patch rollback triggered
4. Update PATCHConfidenceScore field
5. Trigger alerts if:
   - Success rate < 90%
   - Critical service failed
   - Multiple devices reporting same error

**Alert Example:**
```
ALERT: Ring 1 OS Patching - Confidence Score Dropped
Ring: Ring 1 - Pilot Production
Confidence Score: 75 (threshold: 85)
Issue: 3 devices failed to install KB5034441 (Windows Update)
Affected Devices: APP-PROD-02, APP-PROD-05, APP-PROD-08
Error: "Update failed with error 0x80070643"
Action Required: Investigate KB5034441 compatibility
Recommendation: Exclude KB5034441, promote Ring 1 → Ring 2 delayed
```

---

### Step 3: Post-Deployment Validation

**Navigate to:** Device > Patching Tab

**For Each Device in Current Ring:**

#### Check 1: Patch Installation Status
```
Expected: All patches "Installed"
Actual: Review list
Action: If "Failed" → Click for error details
```

#### Check 2: Reboot Status
```
Expected: Reboot completed, system uptime > 15 minutes
Actual: Check device uptime
Action: If pending reboot > 4 hours → Force reboot
```

#### Check 3: Windows Update Service
```
Expected: Windows Update service running
Actual: Services > Windows Update > Status
Action: If stopped → Start service, investigate logs
```

#### Check 4: Event Log Errors
```
Expected: No critical errors in last 2 hours
Actual: Event Viewer > System/Application logs
Action: If errors → Review, correlate with patches
```

#### Check 5: Performance Baseline
```
Expected: CPU/Memory/Disk within ±10% of pre-patch baseline
Actual: Compare current utilization to baseline
Action: If degraded > 20% → Investigate, consider rollback
```

**Validation Result:**
- All checks passed → Device validated ✅
- Any check failed → Device requires attention ⚠️
- Critical failure → Initiate rollback 🚨

---

## PART 4: TROUBLESHOOTING OS PATCHING ISSUES

### Issue 1: Patch Installation Failed (Error 0x80070643)

**Symptom:** Patch shows "Failed" in NinjaOne, error code 0x80070643

**Cause:** .NET Framework corruption or Windows Update components issue [web:345]

**Solution:**
```powershell
# Run on affected device

# Stop Windows Update service
Stop-Service -Name wuauserv -Force

# Clear Windows Update cache
Remove-Item C:\Windows\SoftwareDistribution\* -Recurse -Force

# Reset Windows Update components
DISM /Online /Cleanup-Image /RestoreHealth

# Start Windows Update service
Start-Service -Name wuauserv

# Retry patch installation via NinjaOne
```

**Prevention:** Run DISM health check in pre-patch validation (Script P2)

---

### Issue 2: Pending Reboot Not Completing

**Symptom:** Device shows "Pending Reboot" for > 4 hours

**Cause:** User logged in and deferring reboot, or service preventing shutdown

**Solution 1 (Workstation with User):**
```powershell
# Send notification to user
msg * "System reboot required to complete patching. Please save work and reboot within 30 minutes."

# If still not rebooted after 30 minutes, force reboot
shutdown /r /f /t 300 /c "Forced reboot for patching - 5 minutes"
```

**Solution 2 (Server):**
```powershell
# Check which services preventing shutdown
Get-Service | Where-Object {$_.Status -eq "Running" -and $_.ServicesDependedOn}

# Stop non-critical services
Stop-Service -Name "ServiceName" -Force

# Force reboot
Restart-Computer -Force
```

**Prevention:** Set aggressive force reboot timeout in policy (Ring 3: 60 min, Ring 2: 30 min)

---

### Issue 3: OS Patch Breaks Application

**Symptom:** Application fails to start or crashes after OS patch

**Cause:** Patch incompatibility with application (e.g., KB5034441 breaks legacy .NET apps)

**Solution:**
```powershell
# Immediate: Uninstall problematic patch
wusa /uninstall /kb:5034441 /quiet /norestart

# Reboot device
Restart-Computer -Force

# In NinjaOne: Exclude patch from future deployments
# Administration > Patching > Patch Exclusions > Add KB5034441
```

**Prevention:**
- Test patches on Ring 0 lab devices with all critical applications
- Maintain application compatibility matrix (KB number vs app version)
- Use Ring 1 pilot group with diverse application workloads

---

### Issue 4: Windows Update Service Won't Start

**Symptom:** Service shows "Stopped", cannot be started manually

**Cause:** Corrupted Windows Update database or service dependency failure

**Solution:**
```powershell
# Check service dependencies
sc qc wuauserv

# Check dependent services status
Get-Service BITS, CryptSvc, msiserver | Select Name, Status

# Reset Windows Update service
net stop wuauserv
net stop bits
net stop cryptsvc

# Rename SoftwareDistribution folder
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old

# Restart services
net start wuauserv
net start bits
net start cryptsvc

# Re-register Windows Update DLLs
regsvr32 wuaueng.dll /s
regsvr32 wups.dll /s
regsvr32 wuapi.dll /s
```

**Prevention:** Run service health check in pre-patch validation (Script P2)

---

### Issue 5: Feature Update Installed When Not Approved

**Symptom:** Windows 10 upgraded to Windows 11, or Server 2019 → 2022

**Cause:** Patch policy misconfigured, Feature Updates not set to "Require Approval"

**Solution (Rollback):**
```powershell
# Windows has 10-day rollback window for feature updates

# Option 1: GUI rollback
Settings > Update & Security > Recovery > Go back to previous version

# Option 2: Command line rollback
# Run from WinPE or Safe Mode
DISM /Image:C:\ /Cleanup-Image /RevertPendingActions
```

**Prevention:**
- Set Feature Updates to "Require Approval" in all policies
- Exclude Feature Updates from auto-approval
- Test feature updates on Ring 0 only, manually promote to Ring 1+

---

## PART 5: BEST PRACTICES FOR OS PATCHING [web:315][web:345]

### Pre-Patch Preparation
1. **Verify backups:** All devices must have successful backup < 24 hours old
2. **Check disk space:** Minimum 10 GB free on C: drive (patches need temp space)
3. **Test on Ring 0:** Always test patches on lab devices first (48-hour validation)
4. **Review patch notes:** Check Microsoft release notes for known issues

### During Patch Deployment
1. **Monitor actively:** Watch dashboard during maintenance window
2. **Have war room:** For Ring 3 (critical systems), staff IT team during deployment
3. **Staged reboots:** Stagger reboot times to avoid network/infrastructure overload
4. **Communication:** Notify users 24-48 hours before Ring 2/3 deployments

### Post-Patch Validation
1. **Service health:** Verify all critical services running
2. **Application testing:** Test business-critical applications
3. **Performance check:** Compare CPU/Memory/Disk to baseline (within ±10%)
4. **Event logs:** Review for critical errors in last 2 hours
5. **User feedback:** Collect feedback from Ring 1 (IT staff, pilot users)

### Patch Exclusions
**When to Exclude a Patch:**
- Breaks critical application
- Causes boot failure or BSOD
- Significant performance degradation (> 20%)
- Microsoft issues official guidance to uninstall

**How to Exclude:**
```
NinjaOne: Administration > Patching > Patch Exclusions
Add KB number: KB5034441
Reason: "Breaks legacy .NET application XYZ"
Applies to: All devices OR specific group
Review date: 30 days (re-evaluate monthly)
```

---

## PART 6: OS PATCHING COMPLIANCE REPORTING

### Daily Compliance Check (Script P4)

**Script P4 generates OS patching compliance report:**

**Metrics Tracked:**
- Missing Critical OS patches (count per device)
- Missing Important OS patches (count per device)
- Days since last OS patch (calculated from PATCHLastPatchDate)
- Compliance status (Compliant / Warning / Non-Compliant / Critical)

**Compliance Thresholds:**
```
Compliant: 
  - 0 missing Critical patches
  - 0-2 missing Important patches
  - Last patched < 30 days ago

Warning:
  - 0 missing Critical patches
  - 3-5 missing Important patches
  - Last patched 30-60 days ago

Non-Compliant:
  - 0 missing Critical patches
  - 6+ missing Important patches
  - Last patched 61-90 days ago

Critical:
  - 1+ missing Critical patches
  - OR last patched > 90 days ago
```

### Executive Dashboard

**Create Executive Summary Widget:**
```
Widget: OS Patching Compliance Summary
Metrics:
  - Total devices: 500
  - Compliant: 475 (95%)
  - Warning: 15 (3%)
  - Non-Compliant: 8 (1.6%)
  - Critical: 2 (0.4%)

  - Average days since last patch: 14 days
  - Ring 3 average: 21 days (acceptable, delayed by design)

  - Patches deployed this month: 1,245
  - Success rate: 97.2%
  - Failed patches: 35 (2.8%)
```

**Trend Chart (Last 3 Months):**
- Show compliance improving over time
- Target: 95%+ compliant month-over-month

---

## SUMMARY CHECKLIST

### OS Patching Configuration Complete When:
- ☐ Windows Update settings configured (scan frequency, approval defaults)
- ☐ 2 policy templates created (Server + Workstation)
- ☐ 4 ring-based policies configured (Ring 0, 1, 2, 3)
- ☐ Policies applied to dynamic groups (ring-based)
- ☐ Pre/Post validation scripts deployed (Scripts P2, P3)
- ☐ Monitoring dashboard configured (4 widgets minimum)
- ☐ Automated monitoring enabled (Script PR2 every 4 hours)
- ☐ Compliance reporting configured (Script P4 daily)
- ☐ Rollback procedures documented and tested
- ☐ IT staff trained on troubleshooting common issues

---

**Version:** 1.0  
**Last Updated:** February 1, 2026  
**Applies To:** Windows Server 2016+, Windows 10/11  
**Industry Standards:** Microsoft best practices [web:329], NinjaOne recommendations [web:338][web:339]  
**Next:** 47_PATCH_Software_Patching_Tutorial.md (third-party applications)
