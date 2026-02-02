# Patch Policy Configuration Guide - Complete Setup
**File:** 48_PATCH_Policy_Configuration_Guide.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 5:37 PM CET  
**Applies To:** Windows OS and Third-Party Software Patching

---

## OVERVIEW

This guide provides step-by-step instructions for configuring all patch management policies in NinjaOne. This includes Windows Update policies, software update policies, and ring-based deployment configuration [web:338][web:339].

### What You'll Learn
- Configure global patch management settings
- Create Windows Update policy templates
- Create software update policy templates
- Configure ring-based patch policies (OS and software)
- Set up approval workflows
- Configure reboot and notification settings

### Prerequisites
- NinjaOne admin access
- Custom fields created (PATCH fields from 31_PATCH_Custom_Fields.md)
- Dynamic groups created (Ring 0-3 from 44_PATCH_Ring_Based_Deployment.md)
- Scripts deployed (P1, P2, P3, P4, PR1, PR2 from 44_PATCH_Ring_Based_Deployment.md)

---

## PART 1: GLOBAL PATCH MANAGEMENT SETTINGS

### Step 1: Configure Windows Update Settings

**Navigate to:** Administration > Patching > Settings > Windows Update

#### Update Detection
```
Scan Frequency: Every 4 hours
Scan Method: Windows Update Agent (WUA)
Scan During Maintenance Window Only: No (scan anytime, install during window)

Include Optional Updates: No
Include Driver Updates:
  [✓] Servers (drivers needed for stability)
  [ ] Workstations (too risky, manual approval)

Include Feature Updates: Require Approval (manual)
Include Preview Updates: No (exclude beta updates)
```

**Why These Settings:**
- 4-hour scan ensures patches detected quickly
- Optional updates excluded (bloatware risk)
- Feature updates always require manual approval (major changes)

---

#### Patch Approval Defaults
```
Critical Updates:
  Auto-approve after: [2] days (Ring 0 validation period)
  Applies to: [All device groups except Ring 3]
  Ring 3: Require manual approval

Security Updates:
  Auto-approve after: [2] days (Ring 0 validation)
  Applies to: [All device groups except Ring 3]
  Ring 3: Require manual approval

Important Updates:
  Auto-approve after: [7] days (Ring 1 validation period)
  Applies to: [Ring 0, Ring 1, Ring 2]
  Ring 3: Require manual approval

Recommended Updates:
  Auto-approve: Never (require manual approval)

Optional Updates:
  Auto-approve: Never (auto-reject)

Definition Updates:
  Auto-approve: Immediately (antivirus definitions)
  Applies to: All devices
```

**Ring 3 Exception:**
- Critical systems require manual approval even after Ring 2 passes
- Extra validation step for mission-critical servers

---

#### Reboot Behavior Defaults
```
Reboot if Required: Yes (enabled globally)

Maximum Reboot Delay:
  Servers: [30] minutes
  Workstations: [4] hours

Force Reboot After Delay: Yes (enabled)

Suppress Reboot Notifications:
  Servers: Yes (no users logged in typically)
  Workstations: No (users should know)

Allow User to Defer Reboot:
  Servers: No (force reboot)
  Workstations: Yes, up to [3] times
  Defer Duration: [4] hours per deferral
```

---

#### Patch Exclusions
```
Excluded Patches:
  KB5034441: "Breaks legacy .NET applications"
  KB5033118: "Causes startup delays on Bitlocker systems"

Review Schedule: Monthly (re-evaluate exclusions)

Exclusion Applies To:
  [•] All devices
  [ ] Specific groups (can target if needed)
```

**How to Add Exclusion:**
1. Administration > Patching > Settings > Exclusions
2. Click "Add Exclusion"
3. Enter KB number: KB5034441
4. Reason: "Breaks legacy .NET application XYZ"
5. Review date: 30 days from now
6. Applies to: All devices (or select specific groups)
7. Save

**Save Global Windows Update Settings**

---

### Step 2: Configure Software Update Settings

**Navigate to:** Administration > Patching > Settings > Software Updates

#### Application Detection
```
Application Scan Frequency: Every 12 hours
Include Hidden Applications: No
Minimum Application Age: [7] days (ignore very new apps)

Auto-Detect New Applications:
  [✓] Automatically add to inventory
  [✓] Notify admin of new applications detected
  [ ] Auto-approve updates for new apps (require review first)
```

---

#### Software Update Approval Defaults
```
Security Updates (all applications):
  Auto-approve after: [7] days (Ring 0 + Ring 1 validation)
  Applies to: High-risk and medium-risk apps
  Low-risk apps: Auto-approve after [14] days

Feature Updates (all applications):
  Auto-approve: Never (require manual approval)

Version Upgrades (major versions):
  Auto-approve: Never (require manual approval)
  Example: Chrome 122 → 123 (auto-approve)
           Office 2019 → 2021 (manual approval)
```

---

#### Application Categories
```
High-Risk Applications (7-day approval delay):
  [✓] Browsers (Chrome, Firefox, Edge)
  [✓] Communication Tools (Zoom, Slack, Teams)
  [✓] PDF Readers (Adobe Acrobat, Foxit)
  [✓] Security Tools (VPN clients, antivirus)

Medium-Risk Applications (7-day approval delay):
  [✓] Productivity Tools (Microsoft Office, LibreOffice)
  [✓] Collaboration Tools (OneDrive, SharePoint)
  [✓] Business Applications (line-of-business apps)

Low-Risk Applications (14-day approval delay):
  [✓] Utilities (7-Zip, WinRAR, Notepad++)
  [✓] Development Tools (Git, VS Code, Python)
  [✓] Media Players (VLC, etc.)
```

---

#### Software Update Installation Options
```
Application Handling:
  Close application if running: Yes (default for all apps)
  Close warning delay: [5] minutes (high-risk), [10] minutes (medium-risk)
  Retry if app in use: [3] times, every [15] minutes

Installation Method:
  [✓] Silent installation (suppress prompts)
  [✓] Uninstall previous version automatically
  [ ] Create system restore point (unnecessary for most apps)

Post-Installation:
  [✓] Verify application launches successfully
  [✓] Check for startup errors (log crashes)
  [✓] Update application inventory immediately
```

**Save Global Software Update Settings**

---

## PART 2: WINDOWS UPDATE POLICY TEMPLATES

### Template 1: Windows Server OS Patching

**Navigate to:** Administration > Patching > Policies > Add Policy Template

**Template Name:** Windows Server - OS Patches - Ring-Based

#### Basic Settings
```
Template Type: Windows Update
Applies To: (Template only, assigned per ring)
Enabled: Yes
```

---

#### Patch Types to Install
```
[✓] Critical Updates
[✓] Security Updates
[✓] Important Updates
[✓] Drivers (server hardware only)
[✓] Definition Updates

[ ] Feature Updates (require manual approval)
[ ] Optional Updates (exclude)
[ ] Preview Updates (exclude)
```

---

#### Approval Settings
```
Auto-Approve Critical/Security: After [2] days (Ring 0 validation)
Auto-Approve Important: After [7] days (Ring 1 validation)

Manual Approval Required For:
  [✓] Feature Updates
  [✓] Driver Updates (optional - can auto-approve if confident)

Excluded Patches:
  [✓] Use global exclusion list (KB5034441, etc.)
  [ ] Add template-specific exclusions
```

---

#### Deployment Schedule
```
Maintenance Window Source:
  [•] Use device-specific window (from PATCHMaintenanceWindow field)
  [ ] Use fixed schedule (same time for all devices)

Fallback Window (if device field not set):
  Day: Saturday
  Time: 22:00 (10:00 PM)
  Duration: 4 hours
```

---

#### Reboot Settings
```
Reboot if Required: Yes (always for servers)

Reboot Timing:
  Reboot delay: [15] minutes (servers can tolerate short delay)
  Force reboot after: [30] minutes (if pending)

Reboot Notifications:
  [✓] Notify administrators before reboot (email/alert)
  [ ] Notify end users (servers typically have no users)

Suppress Reboot: No (never suppress for servers)
```

---

#### Advanced Options
```
Pre-Installation:
  [✓] Verify backup < 24 hours old (mandatory for servers)
  [✓] Verify disk space > 10 GB free
  [✓] Run pre-patch validation script (Script P2)

Post-Installation:
  [✓] Run post-patch validation script (Script P3)
  [✓] Verify all critical services running
  [✓] Check for Event Log errors

Maximum Patch Install Time: [120] minutes
Skip if Device Offline: Yes (don't wait indefinitely)

Retry Failed Patches:
  Retry count: [2] times
  Retry interval: [4] hours
```

---

#### Notifications
```
Pre-Deployment Notifications:
  [✓] Notify admins 24 hours before deployment
  Recipients: IT Operations team

Post-Deployment Notifications:
  [✓] Notify on success (summary email)
  [✓] Notify on failure (alert)
  [✓] Notify on reboot required
  Recipients: IT Operations team

Report Frequency: Daily (summary of all patch activity)
```

**Save Template: Windows Server - OS Patches - Ring-Based**

---

### Template 2: Windows Workstation OS Patching

**Navigate to:** Administration > Patching > Policies > Add Policy Template

**Template Name:** Windows Workstation - OS Patches - Ring-Based

#### Patch Types (Same as Server)
```
[✓] Critical Updates
[✓] Security Updates
[✓] Important Updates
[ ] Drivers (too risky for workstations)
[✓] Definition Updates
[ ] Feature Updates
[ ] Optional Updates
```

---

#### Reboot Settings (Different from Server)
```
Reboot if Required: Yes

Reboot Timing:
  Reboot delay: [2] hours (users need time to save work)
  Force reboot after: [4] hours (longer grace period)

Allow User to Defer Reboot:
  [✓] Yes, up to [3] times
  Defer duration: [4] hours per deferral (total 12 hours possible)

Reboot Notifications:
  [✓] Notify end users 1 hour before reboot
  [✓] Notify end users 15 minutes before reboot
  [✓] Send reminder if reboot deferred
  [ ] Notify administrators (only for failures)
```

---

#### User Experience
```
Installation Timing:
  [•] Outside business hours (18:00-08:00)
  [ ] Anytime (not recommended for workstations)

Business Hours:
  Monday-Friday: 08:00-18:00
  Weekends: Anytime (no business hours)

User Notification Style:
  [•] Standard Windows notifications (non-intrusive)
  [ ] Full-screen warnings (aggressive)

Allow User to Postpone:
  [✓] Yes, during business hours only
  [ ] No (force deployment regardless)
```

**Save Template: Windows Workstation - OS Patches - Ring-Based**

---

## PART 3: SOFTWARE UPDATE POLICY TEMPLATES

### Template 1: High-Risk Software (Browsers, Communication)

**Navigate to:** Administration > Patching > Policies > Add Policy Template

**Template Name:** Software Patching - High-Risk Applications - Ring-Based

#### Application Categories
```
[✓] Browsers
    - Google Chrome
    - Mozilla Firefox
    - Microsoft Edge

[✓] Communication Tools
    - Zoom
    - Slack
    - Microsoft Teams

[✓] PDF Readers
    - Adobe Acrobat Reader
    - Foxit Reader

[✓] Security Tools
    - VPN clients
    - Security software (non-AV)
```

---

#### Approval Settings
```
Security Patches:
  Auto-approve after: [3] days (Ring 0 + partial Ring 1 validation)

Feature Updates:
  Require manual approval: Yes

Version Upgrades (major versions):
  Require manual approval: Yes
  Example: Chrome 122 → 123 (auto), Chrome 120 → 125 (manual if major)
```

---

#### Deployment Settings
```
Application Handling:
  Close application if running: Yes (force close after warning)
  Close warning delay: [5] minutes (short for high-risk security updates)

  Retry if app in use: [3] times
  Retry interval: [15] minutes

Force Close After Retries: Yes (critical security updates can't wait)

Save User Data:
  [✓] Save open tabs/sessions (Chrome, Firefox)
  [✓] Save Zoom meeting info (rejoin automatically)
  [✓] Save document drafts (PDF readers)
```

---

#### Installation Window
```
Maintenance Window Source:
  [•] Use device-specific window (from PATCHMaintenanceWindow field)
  [ ] Use fixed schedule

Allow Installation Outside Window:
  [✓] Yes, if user-initiated (user clicks "Update Now")
  [ ] No (strict window enforcement)

High-Risk App Priority:
  [✓] Install as soon as possible (don't wait for low-risk apps)
```

---

#### Post-Installation
```
[✓] Relaunch application automatically (if it was running)
[✓] Restore tabs/sessions (browsers)
[✓] Verify application launches successfully
[✓] Check for crashes in first 5 minutes

Report Issues:
  [✓] Alert if application won't launch
  [✓] Alert if application crashes within 5 minutes
  [✓] Collect crash logs for analysis
```

**Save Template: Software Patching - High-Risk Applications**

---

### Template 2: Medium-Risk Software (Productivity)

**Template Name:** Software Patching - Medium-Risk Applications - Ring-Based

#### Application Categories
```
[✓] Productivity Tools
    - Microsoft Office (non-365)
    - LibreOffice
    - OpenOffice

[✓] Collaboration Tools
    - OneDrive client
    - SharePoint client
    - Dropbox

[✓] Business Applications
    - Line-of-business apps
    - CRM clients (Salesforce, etc.)
```

---

#### Approval Settings
```
Security Patches:
  Auto-approve after: [7] days (Ring 0 + Ring 1 full validation)

All Other Updates:
  Require manual approval: Yes (productivity tools need careful testing)
```

---

#### Deployment Settings
```
Application Handling:
  Close application if running: Yes
  Close warning delay: [10] minutes (longer for productivity tools)

  Retry if app in use: [5] times (more patient)
  Retry interval: [30] minutes

Force Close After Retries: Yes (but with longer patience)

Document Protection:
  [✓] Prompt user to save open documents
  [✓] Attempt auto-save if possible
  [✓] Wait for user confirmation (up to 10 min)
```

---

#### Installation Window
```
Maintenance Window Source:
  [•] Use device-specific window

Allow Installation Outside Window:
  [ ] No (strict window enforcement for productivity apps)

Reason: Productivity apps (Office, etc.) should only update during 
        non-business hours to avoid disrupting work.
```

**Save Template: Software Patching - Medium-Risk Applications**

---

### Template 3: Low-Risk Software (Utilities, Dev Tools)

**Template Name:** Software Patching - Low-Risk Applications - Ring-Based

#### Application Categories
```
[✓] Utilities
    - 7-Zip, WinRAR, WinZip
    - Notepad++
    - Paint.NET

[✓] Development Tools
    - Git
    - Visual Studio Code
    - Python, Node.js

[✓] Media Players
    - VLC
    - Media Player Classic
```

---

#### Approval Settings
```
All Updates:
  Auto-approve after: [14] days (full ring validation)

Version Upgrades:
  Auto-approve: Yes (low-risk apps can auto-upgrade)
```

---

#### Deployment Settings
```
Application Handling:
  Close application if running: Yes (immediate)
  Close warning: [2] minutes (minimal warning for low-risk)

  Retry if app in use: [2] times
  Retry interval: [10] minutes

Force Close: Yes (low-risk apps can be force-closed)
```

---

#### Installation Window
```
Maintenance Window: Not required (anytime deployment)

Timing: 24/7 (deploy whenever convenient)

Reason: Low-risk utilities can be updated anytime without 
        impacting business operations.
```

**Save Template: Software Patching - Low-Risk Applications**

---

## PART 4: RING-BASED POLICY ASSIGNMENT

### Windows OS Patches - Ring 0 (Lab/Test)

**Navigate to:** Administration > Patching > Policies > Add Policy

**Policy Name:** Ring 0 - Windows OS Patches - Lab/Test

#### Basic Settings
```
Template: Windows Server - OS Patches - Ring-Based
Policy Type: Windows Update
Enabled: Yes
```

---

#### Applies To
```
Device Group: Ring 0 - Lab/Test Devices (Dynamic Group)

Expected Devices: 5 devices (2 servers, 3 workstations)
```

---

#### Schedule
```
Day: Tuesday (Patch Tuesday release day)
Time: 20:00 (8:00 PM)
Window Duration: 3 hours (20:00-23:00)

Frequency: Weekly (every Tuesday)
```

---

#### Override Settings (Ring 0 Specific)
```
Approval Overrides:
  [✓] Override approval delays (install immediately)
  Reason: Ring 0 is for testing, install as soon as available

Reboot Overrides:
  [✓] Force reboot immediately (no delay)
  Reason: Lab devices can tolerate aggressive reboots

Notification Overrides:
  [ ] Notify end users (lab devices typically unattended)
  [✓] Notify administrators on completion
```

---

#### Validation Settings
```
Validation Period: 48 hours (Wednesday-Thursday)

Validation Scripts:
  Pre-Patch: Script P2 (Pre-Patch Validation)
  Post-Patch: Script P3 (Post-Patch Validation)

Success Criteria:
  Confidence Score Target: ≥ 90
  Failure Rate Target: < 5%

Promotion Decision:
  [✓] Auto-promote to Ring 1 if confidence ≥ 90
  [ ] Require manual promotion (Ring 0 can auto-promote)
```

**Save Policy: Ring 0 - Windows OS Patches**

---

### Windows OS Patches - Ring 1 (Pilot)

**Policy Name:** Ring 1 - Windows OS Patches - Pilot

#### Prerequisites
```
[✓] Require Ring 0 to pass validation first
    Minimum Confidence Score: 90
    Minimum Success Rate: 95%

[✓] Wait for Ring 0 validation period (48 hours)

Override Prerequisites: 
  [ ] Allow manual override (not recommended)
```

---

#### Schedule
```
Day: Friday (2-3 days after Ring 0)
Time: 21:00 (9:00 PM)
Window Duration: 4 hours

Frequency: Weekly (every Friday, if Ring 0 passed)
```

---

#### Validation Settings
```
Validation Period: 5 days (Saturday-Wednesday)

Success Criteria:
  Confidence Score Target: ≥ 85 (slightly lower than Ring 0)
  Failure Rate Target: < 2%
  User Feedback: Collect from IT staff (Ring 1 users)

Promotion Decision:
  [✓] Auto-promote to Ring 2 if all criteria met
  [✓] Collect user feedback before promotion
```

**Save Policy: Ring 1 - Windows OS Patches**

---

### Windows OS Patches - Ring 2 (Broad)

**Policy Name:** Ring 2 - Windows OS Patches - Broad

#### Prerequisites
```
[✓] Require Ring 1 to pass validation
    Minimum Confidence Score: 85
    Failure Rate: < 2%
    User Feedback: Reviewed (no major issues)

[✓] Wait for Ring 1 validation period (5 days)
```

---

#### Schedule
```
Day: 2nd Saturday (1 week after Ring 1)
Time: 22:00 (10:00 PM)
Window Duration: 4 hours

Frequency: Monthly (Patch Tuesday + 2 weeks typically)
```

---

#### Validation Settings
```
Validation Period: 7 days (Sunday-Saturday)

Success Criteria:
  Confidence Score Target: ≥ 90 (higher for broad deployment)
  Failure Rate Target: < 1% (stricter)

Promotion Decision:
  [✓] Auto-promote to Ring 3 if all criteria met
  [✓] Require manual review before Ring 3 (extra validation)
```

**Save Policy: Ring 2 - Windows OS Patches**

---

### Windows OS Patches - Ring 3 (Critical)

**Policy Name:** Ring 3 - Windows OS Patches - Critical

#### Prerequisites
```
[✓] Require Ring 2 to pass validation
    Minimum Confidence Score: 90
    Failure Rate: < 1%
    Zero critical failures

[✓] Wait for Ring 2 validation period (7 days)

[✓] Manual approval gate required (extra protection)
    Approvers: IT Director, Operations Manager
```

---

#### Schedule
```
Day: 3rd Saturday (2 weeks after Ring 2)
Time: 23:00 (11:00 PM, late night for minimal impact)
Window Duration: 4 hours

Frequency: Monthly (Patch Tuesday + 4 weeks typically)
```

---

#### Special Handling
```
Pre-Deployment:
  [✓] Mandatory backup verification (< 24 hours)
  [✓] War room staffed (on-call team ready)
  [✓] Change management ticket created

Post-Deployment:
  [✓] Continuous monitoring (24 hours)
  [✓] Immediate escalation on any failure
  [✓] Executive notification (success/failure)

Validation Period: Continuous (indefinite monitoring)
```

**Save Policy: Ring 3 - Windows OS Patches**

---

## PART 5: SOFTWARE UPDATE POLICIES (REPEAT FOR EACH RING)

Follow same pattern as Windows OS policies, but for software:

**Policy Names:**
- Ring 0 - Software Patches - High-Risk - Lab/Test
- Ring 1 - Software Patches - High-Risk - Pilot
- Ring 2 - Software Patches - High-Risk - Broad
- Ring 3 - Software Patches - High-Risk - Critical

**Key Differences from OS Patching:**
- Software can deploy 1 day after OS (avoid same-day conflicts)
- Ring validation periods can be shorter (software less risky than OS)
- Application-specific settings (close warning times, save data, etc.)

**Total Policies Created:**
- 4 Windows OS policies (Ring 0-3)
- 12 Software policies (4 rings × 3 risk levels)
- **Total: 16 ring-based policies**

---

## SUMMARY CHECKLIST

### Policy Configuration Complete When:
- ☐ Global Windows Update settings configured
- ☐ Global software update settings configured
- ☐ 2 Windows Update policy templates created (Server + Workstation)
- ☐ 3 Software Update policy templates created (High/Medium/Low risk)
- ☐ 4 Windows OS ring policies created (Ring 0-3)
- ☐ 12 Software ring policies created (4 rings × 3 templates)
- ☐ Prerequisites configured between rings
- ☐ Validation scripts assigned (P2, P3, PR2)
- ☐ Approval workflows configured
- ☐ Notification recipients set
- ☐ Test policies on Ring 0 (verify deployment works)

---

**Version:** 1.0  
**Last Updated:** February 1, 2026, 5:37 PM CET  
**Total Policies:** 16 ring-based policies (4 OS + 12 software)  
**Related:** 46_PATCH_Windows_OS_Tutorial.md (dashboard operations)  
**Related:** 47_PATCH_Software_Patching_Tutorial.md (dashboard operations)  
**Related:** 44_PATCH_Ring_Based_Deployment.md (ring strategy)
