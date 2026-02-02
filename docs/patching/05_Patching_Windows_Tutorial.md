# Windows OS Patching - Dashboard Operations Guide
**File:** 46_PATCH_Windows_OS_Tutorial.md  
**Version:** 2.0 (Dashboard Operations Focus)  
**Last Updated:** February 1, 2026, 5:37 PM CET  
**Applies To:** Windows Server 2016+, Windows 10/11

---

## OVERVIEW

This guide shows you how to use NinjaOne's patch management dashboard to approve and apply Windows OS patches manually and monitor automated deployments [web:338][web:339].

### What You'll Learn
- Navigate the NinjaOne patching dashboard
- Review available Windows Updates
- Approve patches manually (for workstations and manual-approval servers)
- Apply patches to individual devices or groups
- Monitor patch deployment status in real-time
- Troubleshoot common OS patching issues

### Prerequisites
- Patch policies already configured (see 48_PATCH_Policy_Configuration_Guide.md)
- Ring-based groups created (see 44_PATCH_Ring_Based_Deployment.md)
- Devices assigned to appropriate rings

---

## PART 1: NAVIGATING THE PATCHING DASHBOARD

### Step 1: Access Patch Management

**Navigate to:** NinjaOne Dashboard > Patching > Patch Management

**Dashboard Overview - What You See:**

#### Top Metrics Bar
```
Total Devices: 500
Patches Available: 1,245
Devices Need Attention: 23
Failed Patches: 8
Pending Reboots: 15
```

#### Device Status Summary
```
Compliant: 450 (90%)
Warning: 30 (6%)
Non-Compliant: 15 (3%)
Critical: 5 (1%)
```

#### Recent Activity Feed
- Shows last 50 patch activities (installed, failed, approved, etc.)
- Real-time updates during active deployments
- Click any activity for detailed logs

---

### Step 2: Filter and Search

**Dashboard Filters (Top Right):**

```
Device Type: [All Devices] [Servers] [Workstations]
Ring: [All Rings] [Ring 0] [Ring 1] [Ring 2] [Ring 3]
Status: [All] [Needs Patches] [Failed] [Pending Reboot]
Organization: [Select Organization]
Date Range: [Last 7 Days] [Last 30 Days] [Custom]
```

**Search Box:**
- Search by device name, KB number, or patch title
- Example searches:
  - "KB5034441" (specific patch)
  - "SQL-PROD" (device name pattern)
  - "Security Update for Windows" (patch title)

---

### Step 3: Understanding Status Icons

**Device Status Icons:**
- ✅ **Green:** Fully patched, compliant
- ⚠️ **Yellow:** Patches available (warning)
- 🔴 **Red:** Critical patches missing or failed patches
- 🔄 **Blue:** Patch installation in progress
- ⏸️ **Gray:** Pending reboot or manual approval needed

**Patch Status Icons:**
- ✅ **Installed:** Patch successfully installed
- ⏳ **Pending:** Waiting for approval or maintenance window
- 🔄 **Installing:** Currently being installed
- ❌ **Failed:** Installation failed (click for error details)
- 🚫 **Excluded:** Patch excluded from deployment
- 📥 **Downloaded:** Downloaded but not yet installed

---

## PART 2: REVIEWING AVAILABLE PATCHES

### Step 1: View All Available Patches

**Navigate to:** Patching > Patches > Available

**Patch List View:**

| Patch Title | KB Number | Severity | Release Date | Devices | Status |
|-------------|-----------|----------|--------------|---------|--------|
| 2026-02 Security Update for Windows Server | KB5034441 | Critical | 2026-02-11 | 45 | Pending |
| 2026-02 Cumulative Update for Windows 10 | KB5034467 | Important | 2026-02-11 | 120 | Pending |
| Update for Windows Defender | KB2267602 | Definition | 2026-02-01 | 200 | Auto-Approve |

**Sort Options:**
- By Severity (Critical → Optional)
- By Release Date (Newest → Oldest)
- By Affected Devices (Most → Least)

---

### Step 2: Review Patch Details

**Click any patch to view details:**

#### Basic Information
```
Title: 2026-02 Security Update for Windows Server 2022
KB Number: KB5034441
Release Date: February 11, 2026
Severity: Critical
Category: Security Update
Reboot Required: Yes
Microsoft Support URL: https://support.microsoft.com/kb/5034441
```

#### Affected Devices
```
Total Devices: 45 servers
  Ring 0 (Lab/Test): 2 devices
  Ring 1 (Pilot): 5 devices
  Ring 2 (Broad): 18 devices
  Ring 3 (Critical): 20 devices

Status Breakdown:
  Pending Approval: 45 devices
  Scheduled: 0 devices
  Installed: 0 devices
  Failed: 0 devices
```

#### Known Issues (from Microsoft)
```
Known Issue 1: May cause startup delays on systems with Bitlocker
Workaround: Ensure Bitlocker recovery key is accessible

Known Issue 2: Incompatibility with legacy antivirus software
Workaround: Update antivirus before installing patch
```

#### Superseded Patches
```
This patch supersedes:
  - KB5033118 (January 2026 Update)
  - KB5032190 (December 2025 Update)
```

---

### Step 3: Check Ring Readiness

**Before approving a patch, verify ring readiness:**

**Navigate to:** Dashboard > Widgets > Add "Ring Readiness Status"

```
Ring 0 (Lab/Test):
  Status: Ready for Deployment
  Devices: 5 devices
  Last Validation: Passed (2 days ago)
  Confidence Score: N/A (first in ring)

Ring 1 (Pilot):
  Status: Awaiting Ring 0 Validation
  Prerequisite: Ring 0 confidence score ≥ 90
  Current Ring 0 Score: N/A (not deployed yet)
  Estimated Ready: February 13, 2026 (if Ring 0 passes)

Ring 2 (Broad):
  Status: Awaiting Ring 1 Validation
  Prerequisite: Ring 1 confidence score ≥ 85
  Estimated Ready: February 20, 2026

Ring 3 (Critical):
  Status: Awaiting Ring 2 Validation
  Prerequisite: Ring 2 confidence score ≥ 90
  Estimated Ready: February 27, 2026
```

**Interpretation:**
- Only Ring 0 is ready for immediate deployment
- Other rings will auto-deploy after validation (if policies configured)
- Manual approval can override prerequisites (use caution)

---

## PART 3: APPROVING PATCHES MANUALLY

### Scenario 1: Approve Patch for Ring 0 (Lab/Test)

**Purpose:** Initial validation before production deployment

**Steps:**
1. **Navigate to:** Patching > Patches > Available
2. **Select patch:** Click KB5034441 (checkbox on left)
3. **Click "Approve" button** (top right)
4. **Approval Dialog appears:**
   ```
   Approve Patch: KB5034441

   Apply to:
     [•] Specific Groups (recommended)
         [✓] Ring 0 - Lab/Test Devices (5 devices)
         [ ] Ring 1 - Pilot Production (10 devices)
         [ ] Ring 2 - Broad Production (50 devices)
         [ ] Ring 3 - Critical Production (50 devices)

     [ ] All Devices (not recommended for first deployment)

   Deployment Timing:
     [•] Deploy immediately
     [ ] Schedule for later: [Date/Time picker]
     [ ] Wait for next maintenance window

   Reboot Behavior:
     [✓] Reboot if required
     Reboot delay: [15] minutes
     [✓] Force reboot after delay

   Notification:
     [✓] Notify administrators on completion
     [ ] Notify end users before deployment
   ```

5. **Configure settings:**
   - Select "Ring 0 - Lab/Test Devices" only
   - Choose "Deploy immediately" (Ring 0 doesn't wait)
   - Keep reboot settings (15 min delay, force reboot)
   - Enable admin notification

6. **Click "Approve and Deploy"**

7. **Confirmation:**
   ```
   Patch Approved Successfully

   KB5034441 has been approved for:
     - Ring 0 - Lab/Test Devices (5 devices)

   Deployment will begin immediately.
   Estimated completion: 30-45 minutes

   You will receive notification when complete.
   ```

8. **Monitor deployment:**
   - Dashboard > Activity Feed shows "Installing KB5034441 on LAB-TEST-01..."
   - Click device name for real-time installation log
   - Wait for all Ring 0 devices to complete

---

### Scenario 2: Approve Patch for Workstations (Manual Approval Required)

**Purpose:** Deploy patches to workstations with user coordination

**Steps:**
1. **Navigate to:** Patching > Patches > Available
2. **Filter:** Device Type = "Workstations", Status = "Pending Approval"
3. **Select patch:** KB5034467 (Windows 10 Cumulative Update)
4. **Click "Approve" button**
5. **Approval Dialog:**
   ```
   Approve Patch: KB5034467

   Apply to:
     [•] Specific Groups
         [✓] All Workstations (200 devices)

   Deployment Timing:
     [ ] Deploy immediately (not recommended for workstations)
     [•] Schedule for later: [Friday, Feb 14, 2026] [18:00]
     [ ] Wait for next maintenance window

   Reboot Behavior:
     [✓] Reboot if required
     Reboot delay: [2] hours (gives users time to save work)
     [ ] Force reboot after delay (allow user to defer)
     [✓] Allow user to defer reboot (up to [3] times)

   Notification:
     [✓] Notify end users 24 hours before deployment
     [✓] Notify end users 1 hour before deployment
     [✓] Send reminder if reboot deferred
   ```

6. **Configure settings:**
   - Schedule for Friday evening (end of work week)
   - 2-hour reboot delay (users can finish work)
   - Allow 3 deferrals (users control timing)
   - Enable all user notifications

7. **Click "Approve and Deploy"**

8. **User Notification Example (sent 24 hours before):**
   ```
   Subject: Windows Update Scheduled for Friday, Feb 14 at 6:00 PM

   A Windows security update will be installed on Friday, February 14 at 6:00 PM.

   What to expect:
   - Update will install automatically
   - You'll be prompted to restart your computer 2 hours after installation
   - You can defer the restart up to 3 times (4 hours each)
   - Please save your work before restarting

   Patch Details: KB5034467 (Windows 10 Security Update)
   Reboot Required: Yes

   Questions? Contact IT Helpdesk: helpdesk@company.com
   ```

---

### Scenario 3: Emergency Patch (Critical Zero-Day)

**Purpose:** Deploy critical security patch to all devices immediately

**Steps:**
1. **Navigate to:** Patching > Patches > Available
2. **Identify emergency patch:** KB5035001 (zero-day exploit fix)
3. **Click patch > Click "Approve" > Emergency Deployment Mode**
4. **Emergency Approval Dialog:**
   ```
   EMERGENCY PATCH DEPLOYMENT

   WARNING: This will bypass ring validation and deploy immediately to all devices.
   Use only for critical security patches.

   Patch: KB5035001 (Zero-Day Security Fix)
   Severity: Critical
   Reason: Active exploitation detected (CVE-2026-12345)

   Apply to:
     [•] All Servers (100 devices)
     [•] All Workstations (200 devices)

   Deployment:
     [•] Deploy immediately (no delay)
     [✓] Bypass ring prerequisites
     [✓] Bypass maintenance windows

   Reboot:
     [✓] Force reboot after installation (no user deferral)
     Reboot delay: [30] minutes maximum

   Notification:
     [✓] Alert all administrators
     [✓] Notify all users (critical patch)
     [✓] Create incident ticket

   Confirmation:
     [ ] I understand this bypasses normal validation
     [ ] I have management approval for emergency deployment
     [ ] I have reviewed Microsoft security advisory
   ```

5. **Check all confirmation boxes**
6. **Click "Deploy Emergency Patch"**
7. **Immediate Actions:**
   - All devices begin installing immediately
   - Helpdesk notified to expect calls
   - War room staffed (all hands on deck)
   - Monitor dashboard every 5 minutes

**Use Sparingly:** Emergency deployment should be rare (< 2 times/year)

---

## PART 4: APPLYING PATCHES TO SPECIFIC DEVICES

### Scenario 1: Single Device Manual Patch

**Purpose:** Patch a specific server or workstation immediately

**Steps:**
1. **Navigate to:** Devices > All Devices
2. **Search for device:** Type "SQL-PROD-01" in search box
3. **Click device name** to open device details
4. **Click "Patching" tab** (left sidebar)
5. **View device patch status:**
   ```
   Patch Status: Warning (3 patches available)

   Available Patches:
   ✅ KB5034441 (Critical) - 2026-02 Security Update
   ✅ KB5034467 (Important) - Windows Cumulative Update
   ✅ KB2267602 (Definition) - Windows Defender Update

   Installed Patches (Last 30 Days):
   ✅ KB5033118 - Installed Jan 15, 2026
   ✅ KB5032190 - Installed Dec 10, 2025
   ```

6. **Select patches to install:**
   - Check boxes next to KB5034441 and KB2267602
   - (Skip KB5034467 if not urgent)

7. **Click "Install Selected Patches" button**

8. **Installation Dialog:**
   ```
   Install Patches on SQL-PROD-01

   Patches Selected: 2
     - KB5034441 (Critical)
     - KB2267602 (Definition)

   Installation Options:
     [•] Install now (recommended for off-hours)
     [ ] Schedule for later

   Reboot:
     [✓] Reboot if required (KB5034441 requires reboot)
     Reboot delay: [15] minutes
     [✓] Force reboot after delay

   Backup Verification:
     [✓] Verify backup < 24 hours old (recommended for servers)
     Last Backup: Success (6 hours ago) ✅
   ```

9. **Click "Install Patches"**

10. **Real-Time Monitoring:**
    ```
    Installation Progress: KB5034441

    [██████████████████░░░░░░] 75% Complete

    Steps:
    ✅ Backup verified (6 hours old)
    ✅ Pre-installation checks passed
    ✅ Download completed (125 MB)
    🔄 Installing patch...
    ⏳ Reboot required after installation

    Estimated Time Remaining: 3 minutes
    ```

11. **After reboot:**
    ```
    Patch Installation Complete

    SQL-PROD-01:
    ✅ KB5034441 - Installed successfully
    ✅ KB2267602 - Installed successfully
    ✅ System rebooted at 22:15
    ✅ All services started successfully
    ✅ Post-installation checks passed

    Device Status: Compliant (0 patches pending)
    Next Scan: February 2, 2026 at 06:00 AM
    ```

---

### Scenario 2: Bulk Device Patching

**Purpose:** Apply patches to multiple devices at once (e.g., all web servers)

**Steps:**
1. **Navigate to:** Devices > Dynamic Groups
2. **Select group:** "Web Servers - Ring 2" (10 devices)
3. **Click "Actions" dropdown** (top right)
4. **Select "Patch Management"**
5. **Bulk Patching Dialog:**
   ```
   Bulk Patch Installation

   Devices Selected: 10 web servers

   Available Patches:
   [✓] KB5034441 (Critical) - Applies to 10/10 devices
   [✓] KB5034467 (Important) - Applies to 10/10 devices
   [ ] KB2267602 (Definition) - Applies to 10/10 devices (exclude)

   Deployment Strategy:
     [•] Staggered deployment (recommended)
         Install on: [2] devices every [30] minutes
         Total time: ~2.5 hours

     [ ] Simultaneous deployment
         Install on all 10 devices at once
         Total time: ~30 minutes (higher risk)

   Reboot Timing:
     [•] Stagger reboots (5 min apart)
     [ ] Reboot all at once (may overload infrastructure)

   Failure Handling:
     [✓] Pause deployment if 20% fail
     [✓] Send alert on each failure
     [ ] Continue deployment regardless of failures
   ```

6. **Configure:**
   - Use staggered deployment (2 devices every 30 min)
   - Stagger reboots (don't overload load balancer)
   - Pause if failures occur

7. **Click "Start Bulk Deployment"**

8. **Monitor in real-time:**
   ```
   Bulk Patch Deployment: Web Servers - Ring 2

   Batch 1 (Devices 1-2):
   ✅ WEB-PROD-01 - Installing KB5034441... 50%
   ✅ WEB-PROD-02 - Installing KB5034441... 50%

   Batch 2 (Devices 3-4):
   ⏳ Waiting for Batch 1 to complete (15 min remaining)

   Batch 3 (Devices 5-6):
   ⏳ Waiting...

   Overall Progress: 20% (2/10 devices completed)
   Estimated Completion: 22:45 (2 hours 15 min)
   ```

9. **Handle failures gracefully:**
   - If WEB-PROD-03 fails, deployment pauses
   - Alert sent: "Batch 2 failed on WEB-PROD-03 (error: 0x80070643)"
   - Options: Skip device and continue, or abort all

---

## PART 5: MONITORING PATCH DEPLOYMENT

### Real-Time Monitoring Dashboard

**Navigate to:** Patching > Monitoring > Real-Time

**Key Widgets:**

#### Widget 1: Active Deployments
```
Currently Installing Patches: 15 devices

Ring 0 (Lab/Test): 0 devices
Ring 1 (Pilot): 5 devices (installing KB5034441)
Ring 2 (Broad): 10 devices (installing KB5034441)
Ring 3 (Critical): 0 devices (awaiting Ring 2 validation)

Average Installation Time: 12 minutes per device
Estimated Completion: 22:30 (45 minutes remaining)
```

#### Widget 2: Installation Progress
```
Device Status:
✅ Completed: 8 devices (53%)
🔄 In Progress: 5 devices (33%)
⏳ Queued: 2 devices (13%)
❌ Failed: 0 devices (0%)

Success Rate: 100% (8/8 completed successfully)
```

#### Widget 3: Devices Pending Reboot
```
Pending Reboot: 8 devices

Will reboot automatically in:
  SQL-PROD-01: 12 minutes
  APP-PROD-02: 8 minutes
  WEB-PROD-05: 15 minutes
  ...

Manual Reboot Required: 0 devices
```

#### Widget 4: Failed Patches
```
Failed Installations: 0 in last hour

Recent Failures (Last 24h):
❌ APP-PROD-08 - KB5034441 (Error: 0x80070643)
   Action: Retry scheduled for 23:00

❌ SQL-DEV-02 - KB5034467 (Error: Disk space insufficient)
   Action: Cleanup required, retrying after cleanup
```

---

### Post-Deployment Validation

**After patches complete, verify success:**

**Navigate to:** Patching > Reports > Deployment Summary

```
Deployment Report: KB5034441 (Ring 1)

Deployment Window: Feb 14, 2026 21:00-23:00

Device Summary:
  Total Devices: 10
  Successful: 9 (90%)
  Failed: 1 (10%)
  Pending: 0 (0%)

Installation Details:
  Average Install Time: 14 minutes
  Average Download Size: 125 MB
  Total Reboots: 9 devices

Failures:
  APP-PROD-08: Error 0x80070643 (Windows Update corruption)
  Resolution: Re-run Windows Update troubleshooter, retry

Ring Validation:
  Confidence Score: 92 (target: ≥85)
  Service Health: 100% (all services running)
  Performance Impact: -2% (within acceptable range)
  Event Log Errors: 0 critical errors

Recommendation: PASS - Promote to Ring 2 ✅
```

---

## PART 6: TROUBLESHOOTING COMMON ISSUES

### Issue 1: Patch Installation Failed (Error 0x80070643)

**Symptom:** Patch shows "Failed" in dashboard, error code 0x80070643

**Cause:** .NET Framework corruption or Windows Update components issue [web:345]

**Solution:**
```powershell
# Run on affected device via NinjaOne script or remote tools

# Stop Windows Update service
Stop-Service -Name wuauserv -Force

# Clear Windows Update cache
Remove-Item C:\Windows\SoftwareDistribution\* -Recurse -Force

# Reset Windows Update components
DISM /Online /Cleanup-Image /RestoreHealth

# Start Windows Update service
Start-Service -Name wuauserv

# Retry patch via dashboard (Devices > [Device] > Patching > Retry Failed)
```

**Prevention:** Run DISM health check in pre-patch validation

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

**Solution 2 (Server - via Dashboard):**
1. Navigate to: Devices > [Device Name] > Actions
2. Click "Force Reboot Now"
3. Confirmation dialog: "Force reboot SQL-PROD-01?"
   - Reboot delay: [5] minutes (grace period for service shutdown)
   - [✓] Notify logged-in users
4. Click "Force Reboot"

**Prevention:** Set aggressive force reboot timeout in policy

---

### Issue 3: OS Patch Breaks Application

**Symptom:** Application fails to start or crashes after OS patch

**Cause:** Patch incompatibility with application (e.g., KB5034441 breaks legacy .NET apps)

**Solution via Dashboard:**
1. **Navigate to:** Patching > Patches > Installed
2. **Search for:** KB5034441
3. **Click patch > Actions > Uninstall**
4. **Uninstall Dialog:**
   ```
   Uninstall Patch: KB5034441

   Affected Devices: 45 devices

   Select devices to uninstall from:
   [✓] SQL-PROD-01 (application broken)
   [ ] All other devices (keep installed)

   Reboot after uninstall: [✓] Yes (required)
   Reboot delay: [15] minutes

   After uninstall:
   [✓] Exclude patch from future deployments
   Reason: "Breaks legacy .NET application XYZ"
   ```
5. **Click "Uninstall Patch"**
6. **Verify exclusion:**
   - Navigate to: Patching > Settings > Exclusions
   - Confirm KB5034441 listed
   - Re-enable in 30 days (check for updated patch)

**Prevention:**
- Test patches on Ring 0 lab devices with all critical applications
- Maintain application compatibility matrix

---

### Issue 4: Windows Update Service Won't Start

**Symptom:** Service shows "Stopped", cannot be started manually

**Cause:** Corrupted Windows Update database or service dependency failure

**Solution via Dashboard:**
1. Navigate to: Devices > [Device] > Services
2. Check service dependencies:
   - Windows Update (wuauserv): Status = Stopped
   - BITS (bits): Status = ?
   - Cryptographic Services (cryptsvc): Status = ?
   - MSI Installer (msiserver): Status = ?

3. If dependencies stopped, run repair script:
   ```powershell
   # Deploy via NinjaOne script engine

   # Stop all Windows Update services
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

4. Verify in dashboard:
   - Devices > [Device] > Services
   - Windows Update service should show "Running"
   - Trigger patch scan: Devices > [Device] > Patching > Scan Now

---

### Issue 5: Feature Update Installed When Not Approved

**Symptom:** Windows 10 upgraded to Windows 11, or Server 2019 → 2022

**Cause:** Patch policy misconfigured, Feature Updates not excluded

**Solution via Dashboard:**
1. **Navigate to:** Devices > [Device] > Patching > Installed
2. **Identify feature update:** Look for "Feature Update to Windows 11"
3. **Check rollback window:**
   - Windows allows 10-day rollback for feature updates
   - If within 10 days: Rollback available
   - If beyond 10 days: Rollback not possible (restore from backup)

4. **Rollback via Dashboard (within 10 days):**
   - Navigate to: Devices > [Device] > Actions
   - Click "Rollback Feature Update"
   - Confirmation: "This will revert Windows 11 back to Windows 10"
   - Click "Rollback Now"
   - Device reboots and reverts (takes 30-60 minutes)

5. **Prevent future:**
   - Navigate to: Patching > Settings > Patch Categories
   - Feature Updates: Set to "Require Approval" (never auto-approve)
   - Save settings

**Prevention:**
- Always set Feature Updates to "Require Approval"
- Test feature updates on Ring 0 only, manually promote if needed

---

## SUMMARY CHECKLIST

### Dashboard Operations Complete When You Can:
- ☐ Navigate patch management dashboard confidently
- ☐ Review available patches and assess priority
- ☐ Approve patches for specific rings manually
- ☐ Apply patches to individual devices
- ☐ Apply patches to device groups (bulk)
- ☐ Monitor real-time deployment progress
- ☐ Validate post-deployment success
- ☐ Troubleshoot 5 common patching issues
- ☐ Uninstall problematic patches
- ☐ Exclude patches from future deployment

---

**Version:** 2.0 (Dashboard Operations Focus)  
**Last Updated:** February 1, 2026, 5:37 PM CET  
**Related:** 48_PATCH_Policy_Configuration_Guide.md (policy setup)  
**Related:** 44_PATCH_Ring_Based_Deployment.md (ring strategy)
