# PATCH Framework Quick Start Guide
**File:** 36_PATCH_Quick_Start_Guide.md  
**Version:** 1.0  
**Deployment Time:** 30 minutes (minimal setup)  
**Last Updated:** February 1, 2026

---

## OVERVIEW

This guide walks you through deploying the PATCH framework in 30 minutes for immediate server patching automation. This is the fast-track deployment for organizations that need basic automated patching quickly.

### What You'll Accomplish
- ✅ Create 8 custom fields
- ✅ Deploy 1 script (Script P1 - Eligibility)
- ✅ Create 2 dynamic groups (Critical + Standard servers)
- ✅ Configure 2 patch policies (Critical + Standard)
- ✅ Enable automated weekly/monthly patching for servers

### What's Deferred
- Advanced validation (Scripts P2, P3)
- Compliance reporting (Script P4)
- Additional dynamic groups
- Full compound conditions

**Full deployment timeline: 4 weeks (see 30_PATCH_Main_Patching_Framework.md)**

---

## PREREQUISITES

### Required
- NinjaOne account with admin access
- Custom field creation permissions
- Script deployment permissions
- Patch policy configuration permissions
- At least 1 server to test on

### Recommended
- BASE field framework deployed (for BASEBusinessCriticality)
- Understanding of your server criticality tiers
- Approved maintenance windows documented

---

## 30-MINUTE DEPLOYMENT

### Step 1: Create Custom Fields (10 minutes)

**Navigate to:** Administration > Custom Fields > Add Custom Field

**Create these 3 essential fields:**

#### Field 1: PATCHEligible
```
Name: PATCHEligible
Type: Dropdown
Values: Eligible, Not Eligible, Manual Only, Excluded
Default: Manual Only
Description: Controls automated patching eligibility
Applies To: All Devices
```

#### Field 2: PATCHCriticality
```
Name: PATCHCriticality
Type: Dropdown
Values: Critical, Standard, Development, Test
Default: (none)
Description: Determines patching schedule
Applies To: All Devices
```

#### Field 3: PATCHMaintenanceWindow
```
Name: PATCHMaintenanceWindow
Type: Text
Max Length: 50
Default: (none)
Description: Approved maintenance window
Applies To: All Devices
```

**Quick Validation:**
- Go to any device → Custom Fields tab
- Verify all 3 fields appear
- Test dropdown values work

---

### Step 2: Deploy Script P1 (5 minutes)

**Navigate to:** Administration > Automation > Scripts > Add Script

**Script Name:** Script P1 - Patching Eligibility Assessor

**Script Type:** PowerShell

**Execution Context:** System

**Timeout:** 60 seconds

**Script Content:**
```powershell
<#
Script P1: Patching Eligibility Assessor (Quick Start Version)
Purpose: Determine which devices are eligible for automated patching
#>

try {
    Write-Output "Starting Patching Eligibility Assessor"

    # Detect device type
    $computerSystem = Get-CimInstance Win32_ComputerSystem
    $isServer = $computerSystem.DomainRole -ge 2  # 2 = Server

    if ($isServer) {
        # Server detected - check if business criticality is set
        $baseCriticality = Ninja-Property-Get BASEBusinessCriticality

        if ($baseCriticality) {
            # Map BASE criticality to PATCH criticality
            switch ($baseCriticality) {
                "Critical" {
                    $patchCriticality = "Critical"
                    $maintenanceWindow = "Sunday 02:00-04:00"
                }
                "High" {
                    $patchCriticality = "Standard"
                    $maintenanceWindow = "3rd Sunday 02:00-06:00"
                }
                default {
                    $patchCriticality = "Standard"
                    $maintenanceWindow = "3rd Sunday 02:00-06:00"
                }
            }

            # Set fields
            Ninja-Property-Set PATCHEligible "Eligible"
            Ninja-Property-Set PATCHCriticality $patchCriticality
            Ninja-Property-Set PATCHMaintenanceWindow $maintenanceWindow

            Write-Output "SUCCESS: Server eligible for automated patching"
            Write-Output "  Criticality: $patchCriticality"
            Write-Output "  Window: $maintenanceWindow"
        }
        else {
            # Server but no business criticality set
            Ninja-Property-Set PATCHEligible "Not Eligible"
            Write-Output "Server found but BASEBusinessCriticality not set"
        }
    }
    else {
        # Workstation - manual only
        Ninja-Property-Set PATCHEligible "Manual Only"
        Write-Output "Workstation detected - manual patching only"
    }

    exit 0
}
catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

**Schedule:** Daily at 6:00 AM

**Apply To:** All Devices (or specific organization)

**Save and Test:**
- Run script manually on 1 server
- Check device Custom Fields tab
- Verify PATCHEligible = "Eligible" and PATCHCriticality is set

---

### Step 3: Create Dynamic Groups (5 minutes)

#### Group 1: Servers - Critical Tier

**Navigate to:** Devices > Dynamic Groups > Add Group

**Name:** Servers - Critical Tier (Auto-Patch)

**Criteria:**
```
Device Type equals "Server"
AND PATCHEligible equals "Eligible"
AND PATCHCriticality equals "Critical"
```

**Validate:** Should show servers with Critical criticality

---

#### Group 2: Servers - Standard Tier

**Name:** Servers - Standard Tier (Auto-Patch)

**Criteria:**
```
Device Type equals "Server"
AND PATCHEligible equals "Eligible"
AND PATCHCriticality equals "Standard"
```

**Validate:** Should show servers with Standard criticality

---

### Step 4: Configure Patch Policies (10 minutes)

#### Policy 1: Critical Servers - Weekly Patching

**Navigate to:** Administration > Patching > Policies > Add Policy

**Policy Name:** Critical Servers - Weekly Patching

**Applies To:** Dynamic Group "Servers - Critical Tier (Auto-Patch)"

**Patch Types to Install:**
- ☑ Critical Updates
- ☑ Security Updates
- ☑ Definition Updates
- ☐ Feature Updates
- ☐ Upgrades

**Schedule:**
- **Day:** Every Sunday
- **Time:** 2:00 AM
- **Duration:** 2 hours (2:00 AM - 4:00 AM)

**Reboot Behavior:**
- ☑ Reboot if required
- Reboot delay: None (immediate)
- ☑ Force reboot after 30 minutes if pending

**Notifications:**
- ☑ Notify before patching (24 hours)
- ☑ Notify after patching (success/failure)
- Recipients: IT Admin group

**Advanced Options:**
- ☐ Allow user to defer reboot (servers don't have users)
- ☑ Skip if device offline
- Max patch install time: 120 minutes

**Save Policy**

---

#### Policy 2: Standard Servers - Monthly Patching

**Policy Name:** Standard Servers - Monthly Patching

**Applies To:** Dynamic Group "Servers - Standard Tier (Auto-Patch)"

**Patch Types to Install:**
- ☑ Critical Updates
- ☑ Important Updates
- ☑ Security Updates
- ☑ Recommended Updates
- ☑ Definition Updates
- ☐ Feature Updates
- ☐ Upgrades

**Schedule:**
- **Day:** 3rd Sunday of each month
- **Time:** 2:00 AM
- **Duration:** 4 hours (2:00 AM - 6:00 AM)

**Reboot Behavior:**
- ☑ Reboot if required
- Reboot delay: 15 minutes
- ☑ Force reboot after 1 hour if pending

**Notifications:**
- ☑ Notify before patching (48 hours)
- ☑ Notify after patching (success/failure)

**Advanced Options:**
- ☐ Allow user to defer reboot
- ☑ Skip if device offline
- Max patch install time: 180 minutes

**Save Policy**

---

## TESTING

### Test on Development Server (Recommended)

**Step 1: Classify Test Server**
1. Choose 1 development/test server
2. Set BASEBusinessCriticality = "Standard"
3. Run Script P1 manually
4. Verify PATCHEligible = "Eligible"

**Step 2: Trigger Manual Patch**
1. Go to device → Patching tab
2. Click "Install Patches Now"
3. Select all available patches
4. Monitor installation

**Step 3: Validate Success**
1. Verify patches installed
2. Server rebooted (if needed)
3. Services started correctly
4. No errors in Event Log

**If successful → Proceed to production servers**

---

### Test on 1 Production Server (Low-Risk)

**Step 1: Choose Low-Risk Server**
- Non-critical application server
- Has recent backup
- Can tolerate brief downtime

**Step 2: Classify and Wait**
1. Set BASEBusinessCriticality appropriately
2. Run Script P1
3. Verify added to correct dynamic group
4. Wait for next maintenance window

**Step 3: Monitor First Patch Cycle**
1. Check device status during window
2. Verify patches applied
3. Check post-reboot service status
4. Review any errors

**If successful → Enable for all servers**

---

## ENABLING FOR ALL SERVERS

### Step 1: Classify Remaining Servers (Batch)

**Option A: Bulk Update via CSV**
```csv
DeviceName,BASEBusinessCriticality
SQL-PROD-01,Critical
SQL-PROD-02,Critical
APP-PROD-01,High
APP-PROD-02,High
WEB-PROD-01,High
FILE-01,Standard
...
```

**Import via:** Devices > Bulk Actions > Import Custom Fields

---

**Option B: Manual Classification**
1. Go to each server
2. Set BASEBusinessCriticality field
3. Save

---

### Step 2: Run Script P1 on All Servers
1. Go to Script P1 configuration
2. Click "Run Now"
3. Select "All Servers" or specific organization
4. Monitor execution status

---

### Step 3: Validate Group Membership
1. Check dynamic groups:
   - Servers - Critical Tier: Should show critical servers
   - Servers - Standard Tier: Should show standard servers
2. Verify counts match expectations

---

### Step 4: Monitor First Patch Cycle

**For Critical Servers (Next Sunday):**
- Monitor starting 1:50 AM
- Watch for patch installation start
- Verify reboots complete
- Check services restart

**For Standard Servers (3rd Sunday of Month):**
- Same monitoring process
- Longer window (4 hours)
- More patches typically installed

---

## POST-DEPLOYMENT

### Immediate Actions
- ✅ Document which servers are in which tier
- ✅ Add maintenance windows to IT calendar
- ✅ Configure alert notifications
- ✅ Set up dashboard widget for patch status

### Within 1 Week
- ✅ Review first patch cycle results
- ✅ Address any failures
- ✅ Fine-tune maintenance windows if needed
- ✅ Deploy remaining custom fields (for full framework)

### Within 1 Month
- ✅ Deploy Scripts P2, P3, P4 (validation and compliance)
- ✅ Create remaining compound conditions
- ✅ Set up compliance reporting
- ✅ Review and optimize

---

## QUICK REFERENCE

### Common Tasks

**Check Device Patch Eligibility:**
```
Device → Custom Fields → 
  PATCHEligible (should be "Eligible")
  PATCHCriticality (Critical or Standard)
```

**Manually Trigger Patch on Device:**
```
Device → Patching → Install Patches Now
```

**Check Next Maintenance Window:**
```
Device → Custom Fields → PATCHMaintenanceWindow
Or check dynamic group membership
```

**View Patch Status Across All Servers:**
```
Dashboard → Add Widget → Patching Summary
Filter by Dynamic Group
```

---

## TROUBLESHOOTING

### Server not showing in dynamic group
**Check:**
1. Is PATCHEligible = "Eligible"?
2. Is PATCHCriticality set correctly?
3. Run Script P1 manually
4. Refresh dynamic group

### Patches not installing
**Check:**
1. Is device in correct dynamic group?
2. Is patch policy enabled?
3. Is it within maintenance window?
4. Check device connectivity
5. Review patch policy logs

### Server rebooted unexpectedly
**Check:**
1. Was it during maintenance window?
2. Check PATCHMaintenanceWindow field
3. Review patch policy reboot settings
4. Adjust window or reboot delay if needed

---

## NEXT STEPS

### Expand to Full Framework
1. Deploy remaining 5 custom fields (31_PATCH_Custom_Fields.md)
2. Deploy Scripts P2, P3, P4 (33_PATCH_Automation_Scripts.md)
3. Create compound conditions (34_PATCH_Compound_Conditions.md)
4. Set up compliance reporting (42_PATCH_Compliance_Reporting.md)

### Advanced Features
- Pre-patch validation (Script P2)
- Post-patch validation (Script P3)
- Automated rollback
- Compliance dashboards
- Executive reporting

---

## SUCCESS CRITERIA

After 30-minute deployment, you should have:
- ✅ 3 custom fields created
- ✅ Script P1 deployed and running daily
- ✅ 2 dynamic groups with server members
- ✅ 2 patch policies configured and active
- ✅ Automated patching enabled for servers

**You're now patching servers automatically! 🎉**

---

**Version:** 1.0  
**Deployment Time:** 30 minutes  
**Last Updated:** February 1, 2026  
**Status:** Production Ready  
**Next:** Full 4-week deployment (30_PATCH_Main_Patching_Framework.md)
