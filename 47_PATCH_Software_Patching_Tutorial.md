# Third-Party Software Patching - Dashboard Operations Guide
**File:** 47_PATCH_Software_Patching_Tutorial.md  
**Version:** 2.0 (Dashboard Operations Focus)  
**Last Updated:** February 1, 2026, 5:37 PM CET  
**Applies To:** Windows Servers and Workstations

---

## OVERVIEW

This guide shows you how to use NinjaOne's software patch management dashboard to approve and apply third-party application updates [web:338][web:343][web:346].

### What You'll Learn
- Navigate the software patching dashboard
- Review available application updates
- Approve software patches manually
- Apply software updates to devices
- Monitor software patching status
- Troubleshoot common software patching issues

### Prerequisites
- Application inventory enabled
- Software patch policies configured (see 48_PATCH_Policy_Configuration_Guide.md)
- Ring-based groups created

---

## PART 1: NAVIGATING SOFTWARE PATCHING DASHBOARD

### Step 1: Access Software Patch Management

**Navigate to:** NinjaOne Dashboard > Patching > Software Patches

**Dashboard Overview:**

#### Top Metrics
```
Total Applications: 1,245 (across all devices)
Outdated Applications: 245 (20%)
Updates Available: 387 updates
Devices Needing Updates: 123 devices
Failed Updates (24h): 5 updates
```

#### Application Risk Summary
```
High-Risk Apps (Browsers, Communication):
  Outdated: 45 devices (9%)
  Current: 455 devices (91%)

Medium-Risk Apps (Productivity):
  Outdated: 78 devices (15.6%)
  Current: 422 devices (84.4%)

Low-Risk Apps (Utilities, Dev Tools):
  Outdated: 122 devices (24.4%)
  Current: 378 devices (75.6%)
```

#### Recent Software Update Activity
- Shows last 50 software update activities
- Real-time updates during deployments
- Click any activity for detailed logs

---

### Step 2: Filter Software Patches

**Dashboard Filters:**
```
Application Category:
  [All] [Browsers] [Productivity] [Communication] [Development] [Utilities]

Risk Level:
  [All] [High-Risk] [Medium-Risk] [Low-Risk]

Update Status:
  [All] [Available] [Pending Approval] [Installing] [Failed]

Device Type:
  [All] [Servers] [Workstations]

Ring:
  [All] [Ring 0] [Ring 1] [Ring 2] [Ring 3]
```

**Search:**
- Search by application name, version, or vendor
- Example: "Chrome", "Adobe Reader", "Zoom"

---

### Step 3: Understanding Application Update Status

**Application Status Icons:**
- ✅ **Up-to-date:** Latest version installed
- ⚠️ **Update Available:** Newer version available (1-30 days old)
- 🔴 **Outdated:** Significantly outdated (30+ days) or security vulnerability
- 🔄 **Updating:** Update currently installing
- ❌ **Update Failed:** Installation failed
- 🚫 **Excluded:** Update excluded from deployment

**Update Priority Badges:**
- 🔥 **Critical:** Security vulnerability, deploy ASAP
- ⚡ **High:** Important security or stability update
- 📊 **Medium:** Feature update or minor improvements
- 🔧 **Low:** Optional update, cosmetic changes

---

## PART 2: REVIEWING AVAILABLE SOFTWARE UPDATES

### Step 1: View All Available Updates

**Navigate to:** Patching > Software Patches > Available Updates

**Update List View:**

| Application | Current Version | Latest Version | Priority | Devices | Status |
|-------------|----------------|----------------|----------|---------|--------|
| Google Chrome | 122.0.6261.94 | 123.0.6312.58 | High | 45 | Pending |
| Adobe Acrobat Reader | 23.008.20421 | 24.001.20604 | High | 30 | Pending |
| Zoom | 5.16.10 | 5.17.5 | Medium | 25 | Pending |
| 7-Zip | 23.01 | 24.01 | Low | 15 | Pending |

**Sort Options:**
- By Priority (Critical → Low)
- By Affected Devices (Most → Least)
- By Release Date (Newest → Oldest)
- By Application Name (A-Z)

---

### Step 2: Review Application Update Details

**Click any application update to view details:**

#### Basic Information
```
Application: Google Chrome
Current Version: 122.0.6261.94 (installed on 45 devices)
Latest Version: 123.0.6312.58
Release Date: February 8, 2026 (6 days ago)
Update Priority: High (security vulnerabilities fixed)
Vendor: Google LLC
```

#### What's New
```
Security Fixes:
  - CVE-2026-1234: High severity - Use-after-free in V8
  - CVE-2026-5678: Medium severity - Out of bounds memory access

Bug Fixes:
  - Fixed crash when using certain extensions
  - Improved performance on low-memory systems

New Features:
  - Enhanced privacy controls
  - Improved tab grouping
```

#### Affected Devices
```
Total Devices with Chrome: 45 devices

Version Distribution:
  122.0.6261.94 (Current): 45 devices (100%)
  123.0.6312.58 (Latest): 0 devices (0%)

Ring Breakdown:
  Ring 0 (Lab/Test): 2 devices
  Ring 1 (Pilot): 5 devices
  Ring 2 (Broad): 18 devices
  Ring 3 (Critical): 20 devices
```

#### Installation Requirements
```
Installer Size: 95 MB
Disk Space Required: 300 MB
Reboot Required: No
Application Must Be Closed: Yes (Chrome will be closed automatically)
Estimated Installation Time: 2-3 minutes per device
```

#### Known Issues
```
Known Issue: May reset some custom settings
Workaround: Export Chrome settings before update

Known Issue: Extensions may need to be re-enabled
Workaround: Check extensions after update
```

---

### Step 3: Check Application Compatibility

**Before approving, verify compatibility:**

**Navigate to:** Applications > [Application Name] > Compatibility

```
Compatibility Status: Google Chrome 123.0.6312.58

Tested Environments:
  ✅ Windows 10 22H2: Compatible
  ✅ Windows 11 23H2: Compatible
  ✅ Windows Server 2022: Compatible
  ⚠️ Windows Server 2016: Not tested

Application Conflicts:
  ⚠️ May conflict with legacy web applications using ActiveX
  ✅ Compatible with internal company intranet

User Feedback (from vendor/community):
  95% positive reviews
  Common complaint: "Extension compatibility issues" (5%)
```

---

## PART 3: APPROVING SOFTWARE UPDATES MANUALLY

### Scenario 1: Approve High-Risk App Update (Chrome) for Ring 0

**Purpose:** Initial validation on lab devices

**Steps:**
1. **Navigate to:** Patching > Software Patches > Available Updates
2. **Select:** Google Chrome 123.0.6312.58
3. **Click "Approve Update" button**
4. **Approval Dialog:**
   ```
   Approve Update: Google Chrome 123.0.6312.58

   Apply to:
     [•] Specific Groups
         [✓] Ring 0 - Lab/Test Devices (2 devices with Chrome)
         [ ] Ring 1 - Pilot Production (5 devices)
         [ ] Ring 2 - Broad Production (18 devices)
         [ ] Ring 3 - Critical Production (20 devices)

   Deployment Timing:
     [•] Deploy immediately (Ring 0 doesn't wait)
     [ ] Schedule for later
     [ ] Wait for next maintenance window

   Application Handling:
     [✓] Close Chrome if running
     Close warning delay: [5] minutes
     [✓] Notify user before closing (if logged in)

   Installation Options:
     [✓] Uninstall previous version automatically
     [✓] Suppress installation prompts (silent install)
     [ ] Create system restore point (unnecessary for Chrome)

   Post-Installation:
     [✓] Verify application launches successfully
     [✓] Check for startup errors
     [✓] Update application inventory
   ```

5. **Configure:**
   - Select Ring 0 only (2 devices)
   - Deploy immediately
   - 5-minute warning before closing Chrome
   - Silent installation

6. **Click "Approve and Deploy"**

7. **Monitor Installation:**
   ```
   Installing Google Chrome 123.0.6312.58

   LAB-TEST-01:
     🔄 Closing Chrome... (user notified)
     🔄 Downloading installer (95 MB)... 80%
     ⏳ Installing...

   LAB-TEST-02:
     ✅ Chrome closed successfully
     ✅ Installer downloaded
     ✅ Installation complete
     ✅ Chrome launched successfully

   Overall: 50% complete (1/2 devices)
   ```

---

### Scenario 2: Approve Medium-Risk App Update (Adobe Reader) for All Rings

**Purpose:** Deploy trusted update after Ring 0 validation

**Steps:**
1. **Navigate to:** Patching > Software Patches > Available Updates
2. **Select:** Adobe Acrobat Reader 24.001.20604
3. **Verify Ring 0 passed:**
   - Ring 0 Status: Passed ✅ (deployed 3 days ago)
   - Confidence Score: 95
   - User Feedback: No issues reported
4. **Click "Approve Update" button**
5. **Approval Dialog:**
   ```
   Approve Update: Adobe Acrobat Reader 24.001.20604

   Ring 0 Validation: PASSED (3 days ago, confidence 95)

   Apply to (progressive deployment):
     [•] Progressive ring deployment (recommended)
         [✓] Ring 1 - Pilot (10 devices) - Deploy Friday
         [✓] Ring 2 - Broad (50 devices) - Deploy Saturday + 1 week
         [✓] Ring 3 - Critical (50 devices) - Deploy Saturday + 2 weeks

     [ ] Deploy to specific ring only
     [ ] Deploy to all rings simultaneously

   Deployment Schedule:
     Ring 1: Friday, Feb 14, 2026 - 18:00
     Ring 2: Saturday, Feb 22, 2026 - 20:00 (pending Ring 1 pass)
     Ring 3: Saturday, Mar 1, 2026 - 20:00 (pending Ring 2 pass)

   Ring Promotion Prerequisites:
     [✓] Ring 1 must pass before Ring 2 (confidence ≥85)
     [✓] Ring 2 must pass before Ring 3 (confidence ≥90)
     [✓] Automatic halt if confidence drops below 70

   Application Handling:
     [✓] Close Adobe Reader if running
     Close warning: [10] minutes
     Retry if app in use: [3] times (15 min intervals)
   ```

6. **Configure:**
   - Use progressive ring deployment
   - Automatic prerequisites enabled
   - 10-minute warning for users

7. **Click "Approve Progressive Deployment"**

8. **Confirmation:**
   ```
   Progressive Deployment Scheduled

   Adobe Acrobat Reader 24.001.20604 will deploy:

   Ring 1: Friday, Feb 14 at 18:00 (10 devices)
     → Validation period: 5 days
     → Promotion to Ring 2: Auto (if confidence ≥85)

   Ring 2: Saturday, Feb 22 at 20:00 (50 devices, pending Ring 1)
     → Validation period: 7 days
     → Promotion to Ring 3: Auto (if confidence ≥90)

   Ring 3: Saturday, Mar 1 at 20:00 (50 devices, pending Ring 2)
     → Validation: Continuous monitoring

   You'll receive notifications at each stage.
   Total deployment time: ~2 weeks
   ```

---

### Scenario 3: Approve Low-Risk App Update (7-Zip) - All Devices

**Purpose:** Deploy low-risk utility update broadly

**Steps:**
1. **Navigate to:** Patching > Software Patches > Available Updates
2. **Select:** 7-Zip 24.01
3. **Click "Approve Update" button**
4. **Approval Dialog:**
   ```
   Approve Update: 7-Zip 24.01

   Risk Level: Low (utility application)

   Apply to:
     [•] All devices with 7-Zip (15 devices)
     [ ] Specific groups

   Deployment Timing:
     [ ] Deploy immediately
     [•] Flexible deployment (within 7 days)
         Devices will update during next available window

   Application Handling:
     [✓] Close 7-Zip if running (no data loss risk)
     [ ] Warn user (low-risk app, not necessary)

   Installation:
     [✓] Silent installation (no user interaction)
     [✓] Uninstall previous version
   ```

5. **Configure:**
   - All devices (15 devices)
   - Flexible 7-day window (non-urgent)
   - Silent installation, no user warning

6. **Click "Approve and Deploy"**

---

## PART 4: APPLYING SOFTWARE UPDATES TO SPECIFIC DEVICES

### Scenario 1: Update Application on Single Device

**Purpose:** Manually update Chrome on specific workstation

**Steps:**
1. **Navigate to:** Devices > All Devices
2. **Search:** USER-WS-025
3. **Click device name** > **Applications tab**
4. **Application List:**
   ```
   Installed Applications:

   ⚠️ Google Chrome 122.0.6261.94 (Outdated - 6 days)
      Latest: 123.0.6312.58 (security update available)
      [Update Now] button

   ✅ Microsoft Office 2021 (Up-to-date)

   ⚠️ Adobe Acrobat Reader 23.008.20421 (Outdated - 12 days)
      Latest: 24.001.20604
      [Update Now] button

   ✅ Zoom 5.17.5 (Up-to-date)
   ```

5. **Click "Update Now"** next to Google Chrome
6. **Update Dialog:**
   ```
   Update Google Chrome on USER-WS-025

   Current Version: 122.0.6261.94
   New Version: 123.0.6312.58

   User: John Doe (currently logged in)
   Chrome Status: Running (2 windows, 15 tabs open)

   Update Options:
     [•] Update now (close Chrome)
         [✓] Warn user 5 minutes before closing
         [✓] Save open tabs automatically

     [ ] Schedule for later (when user logs off)

   Estimated Downtime: 2 minutes
   ```

7. **Click "Update Now"**

8. **User sees notification:**
   ```
   Chrome Update Required

   Google Chrome will close in 5 minutes to install a security update.

   Your open tabs will be saved and restored after the update.

   [Update Now] [Remind Me in 15 min (1 deferral remaining)]
   ```

9. **Monitor in real-time:**
   ```
   Updating Chrome on USER-WS-025

   ✅ User notified (5 min warning)
   ✅ Chrome closed (tabs saved)
   ✅ Installer downloaded (95 MB)
   🔄 Installing Chrome 123.0.6312.58...
   ✅ Installation complete
   ✅ Chrome launched, tabs restored

   Status: Update successful (2 min 15 sec)
   ```

---

### Scenario 2: Bulk Update Application Across Multiple Devices

**Purpose:** Update Zoom on all devices with outdated version

**Steps:**
1. **Navigate to:** Applications > Application Catalog
2. **Select:** Zoom
3. **View Zoom status:**
   ```
   Zoom Version Distribution (25 devices total)

   5.17.5 (Latest): 20 devices (80%)
   5.16.10 (Outdated): 5 devices (20%) ⚠️

   Outdated Devices:
   - USER-WS-012 (Ring 2)
   - USER-WS-034 (Ring 2)
   - USER-WS-055 (Ring 3)
   - SQL-PROD-01 (Ring 3) - Server with Zoom
   - APP-DEV-02 (Ring 1)
   ```

4. **Select outdated devices** (checkboxes)
5. **Click "Update Selected Devices" button**
6. **Bulk Update Dialog:**
   ```
   Bulk Update: Zoom 5.16.10 → 5.17.5

   Devices Selected: 5 devices

   Deployment Strategy:
     [•] Smart deployment (avoid meeting times)
         Analyze Zoom usage patterns
         Deploy during low-usage periods

     [ ] Immediate deployment (all at once)

   Meeting Detection:
     [✓] Skip devices in active Zoom meetings
     [✓] Retry after meeting ends
     Maximum retry attempts: [5] times

   User Notification:
     [✓] Notify 10 minutes before closing Zoom
     [✓] Allow user to defer once (defer 30 minutes)
   ```

7. **Click "Start Smart Deployment"**

8. **Smart deployment in action:**
   ```
   Zoom Update - Smart Deployment

   Analysis Complete:
   - USER-WS-012: No active meeting, deploying now ✅
   - USER-WS-034: In meeting (detected), waiting... ⏳
   - USER-WS-055: No active meeting, deploying now ✅
   - SQL-PROD-01: Server (no user), deploying now ✅
   - APP-DEV-02: In meeting (detected), waiting... ⏳

   Status: 3/5 completed
   Waiting for 2 devices to finish meetings (retrying every 15 min)
   ```

---

## PART 5: MONITORING SOFTWARE UPDATE DEPLOYMENT

### Real-Time Software Update Dashboard

**Navigate to:** Patching > Software Patches > Monitoring

**Key Widgets:**

#### Widget 1: Active Software Updates
```
Currently Updating: 12 devices

Application Breakdown:
  Chrome: 5 devices (installing)
  Adobe Reader: 4 devices (downloading)
  Zoom: 3 devices (waiting for meeting to end)

Average Update Time:
  Chrome: 2 minutes
  Adobe Reader: 3 minutes
  Zoom: 1 minute
```

#### Widget 2: Update Success Rate
```
Last 24 Hours:
  Successful: 45 updates (90%)
  Failed: 3 updates (6%)
  In Progress: 2 updates (4%)

Failed Updates:
  Chrome on APP-PROD-08: Application in use (retry pending)
  Adobe Reader on USER-WS-099: Installer corrupted (re-download)
  Zoom on USER-WS-045: Disk space insufficient (cleanup needed)
```

#### Widget 3: Application Version Compliance
```
Target: 90%+ on current or previous version

Chrome:
  Latest (123.0.6312.58): 40 devices (89%)
  Previous (122.0.6261.94): 5 devices (11%)
  Older: 0 devices (0%)
  Compliance: 100% ✅

Adobe Reader:
  Latest (24.001.20604): 25 devices (83%)
  Previous (23.008.20421): 5 devices (17%)
  Older: 0 devices (0%)
  Compliance: 100% ✅
```

---

### Post-Deployment Validation

**After updates complete, verify:**

**Navigate to:** Patching > Software Patches > Deployment Report

```
Software Update Report: Google Chrome 123.0.6312.58

Deployment Period: Feb 14-28, 2026 (2-week ring cycle)

Device Summary:
  Total Devices: 45 devices
  Successful: 44 devices (98%)
  Failed: 1 device (2%)

Ring Breakdown:
  Ring 0: 2/2 devices (100%) - Deployed Feb 14
  Ring 1: 5/5 devices (100%) - Deployed Feb 21
  Ring 2: 17/18 devices (94%) - Deployed Feb 28
  Ring 3: 20/20 devices (100%) - Deployed Feb 28

Failed Device:
  APP-PROD-08 (Ring 2): Persistent "application in use" error
  Resolution: Manual update scheduled during maintenance window

Ring Validation Scores:
  Ring 0: 100 (passed immediately)
  Ring 1: 95 (passed, promoted to Ring 2)
  Ring 2: 92 (passed, promoted to Ring 3)

Application Health:
  Launch Success: 100% (all devices can launch Chrome)
  Settings Preserved: 95% (2 devices reported reset settings)
  Extension Compatibility: 90% (4 devices needed to re-enable extensions)

Recommendation: Deployment successful, continue monitoring ✅
```

---

## PART 6: TROUBLESHOOTING SOFTWARE PATCHING ISSUES

### Issue 1: Application Fails to Update - "In Use" Error

**Symptom:** Update shows "Failed - Application in use"

**Cause:** User has application open during deployment

**Solution via Dashboard:**
1. **Navigate to:** Devices > [Device] > Applications > [Application]
2. **Click "Force Update" button**
3. **Force Update Dialog:**
   ```
   Force Update: Google Chrome on USER-WS-025

   Current Status: Application in use (2 windows open)
   User: John Doe (logged in)

   Force Options:
     [•] Send final warning, then force close
         Warning delay: [5] minutes
         [✓] Save open tabs/data

     [ ] Wait for user to close application manually

   After forced close:
     [✓] Install update immediately
     [✓] Relaunch application automatically
   ```

4. **Click "Force Update"**

**Prevention:** Enable "Close application automatically" in policy with longer warning delays

---

### Issue 2: Software Update Downloaded But Not Installed

**Symptom:** Update status shows "Downloaded" but not "Installed" for hours

**Cause:** Waiting for maintenance window or user action

**Solution via Dashboard:**
1. **Navigate to:** Devices > [Device] > Applications > [Application]
2. **Check update status:**
   ```
   Adobe Acrobat Reader Update Status

   Status: Downloaded (waiting for installation)
   Reason: Waiting for maintenance window (Saturday 20:00)
   Installer: Cached locally (125 MB)
   Time Until Window: 2 days 5 hours
   ```

3. **Override maintenance window:**
   - Click "Install Now" button
   - Confirmation: "Install outside maintenance window?"
   - Click "Yes, Install Now"

4. **Or change policy:**
   - Navigate to: Patching > Policies > [Policy Name]
   - Change: "Install timing" from "Maintenance window" to "Immediate"

---

### Issue 3: Application Won't Launch After Update

**Symptom:** Application crashes or won't start after update

**Cause:** Corrupted update or incompatibility

**Solution via Dashboard:**
1. **Navigate to:** Devices > [Device] > Applications > [Application]
2. **Click "Rollback Update" button**
3. **Rollback Dialog:**
   ```
   Rollback: Adobe Acrobat Reader on USER-WS-025

   Current Version: 24.001.20604 (not launching)
   Previous Version: 23.008.20421 (known working)

   Rollback Options:
     [✓] Uninstall current version
     [✓] Reinstall previous version from cache
     [✓] Preserve user settings/documents

   After rollback:
     [✓] Exclude version 24.001.20604 from future updates
     Reason: "Application launch failure"
     Re-evaluate: [30] days
   ```

4. **Click "Rollback"**

5. **Verify rollback:**
   - Application launches successfully
   - Version shows 23.008.20421
   - Update 24.001.20604 excluded

**Prevention:**
- Test updates on Ring 0 before broad deployment
- Maintain cached previous versions for quick rollback

---

### Issue 4: Update Installed But Version Unchanged

**Symptom:** Dashboard shows "Installed" but version number same

**Cause:** Application inventory not refreshed, or update didn't actually install

**Solution via Dashboard:**
1. **Navigate to:** Devices > [Device] > Actions
2. **Click "Refresh Inventory" button**
3. **Inventory Scan Dialog:**
   ```
   Refresh Inventory: USER-WS-025

   Scan Type:
     [•] Applications only (faster, 2-3 minutes)
     [ ] Full inventory (slower, 10-15 minutes)

   Force rescan: [✓] Yes (bypass cache)
   ```

4. **Click "Start Scan"**

5. **After scan completes:**
   - Navigate to: Devices > [Device] > Applications
   - Check application version
   - If still unchanged: Update may have failed silently

6. **If version unchanged, retry update:**
   - Applications > [Application] > "Update Now"
   - Monitor installation logs closely
   - Check for error messages

---

### Issue 5: Multiple Versions of Same Application Installed

**Symptom:** Device has Chrome 120, 121, and 122 all installed

**Cause:** Failed uninstall of previous versions

**Solution via Dashboard:**
1. **Navigate to:** Devices > [Device] > Applications
2. **Filter by:** "Google Chrome"
3. **Shows:**
   ```
   Google Chrome Installations:

   ⚠️ Chrome 120.0.6099.71 (old, should be removed)
   ⚠️ Chrome 121.0.6167.85 (old, should be removed)
   ✅ Chrome 122.0.6261.94 (current, keep)
   ```

4. **Select old versions** (checkboxes)
5. **Click "Uninstall Selected" button**
6. **Uninstall Dialog:**
   ```
   Uninstall: Chrome 120.0.6099.71 and Chrome 121.0.6167.85

   [✓] Remove application files
   [✓] Remove user data (settings, cache)
         ⚠️ Warning: This will reset Chrome settings
   [✓] Remove registry entries

   Keep Latest Version: Chrome 122.0.6261.94 ✅
   ```

7. **Click "Uninstall"**

**Prevention:**
- Enable "Uninstall previous version" in software update policies
- Run cleanup script monthly

---

## SUMMARY CHECKLIST

### Software Patching Dashboard Operations Complete When You Can:
- ☐ Navigate software patching dashboard
- ☐ Review available application updates
- ☐ Assess update priority (high/medium/low risk)
- ☐ Approve updates for specific rings
- ☐ Apply updates to individual devices
- ☐ Apply updates to device groups
- ☐ Monitor real-time update progress
- ☐ Validate post-deployment success
- ☐ Troubleshoot 5 common issues
- ☐ Rollback problematic updates
- ☐ Exclude updates from deployment

---

**Version:** 2.0 (Dashboard Operations Focus)  
**Last Updated:** February 1, 2026, 5:37 PM CET  
**Related:** 48_PATCH_Policy_Configuration_Guide.md (policy setup)  
**Related:** 44_PATCH_Ring_Based_Deployment.md (ring strategy)
