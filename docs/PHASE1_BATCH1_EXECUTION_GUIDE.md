# Phase 1 Batch 1 Execution Guide

**Date:** February 3, 2026 22:34 CET  
**Batch:** 1 of 4 (Core Health Status Fields)  
**Fields:** 5 dropdown fields  
**Estimated Time:** 55 minutes  
**Status:** READY TO EXECUTE

## Batch 1 Overview

### Fields to Convert

1. **bitlockerHealthStatus** - BitLocker Monitor (Script 07)
2. **dnsServerStatus** - DNS Server Monitor (Script 03)
3. **fileServerHealthStatus** - File Server Monitor (Script 45)
4. **printServerStatus** - Print Server Monitor (Script 46)
5. **mysqlServerStatus** - MySQL Server Monitor (if exists)

### Why These Fields First?

- **Core Infrastructure** - Critical monitoring components
- **High Visibility** - Frequently viewed in dashboard
- **Standard Pattern** - All use same health status values
- **Low Risk** - Well-tested scripts, stable functionality
- **Quick Validation** - Easy to verify conversions work

## Pre-Execution Checklist

**Before starting, verify:**

- [ ] NinjaOne admin access confirmed
- [ ] Access to Organization > Custom Fields section
- [ ] Test device identified for validation
- [ ] Git repository access confirmed
- [ ] VS Code or text editor ready
- [ ] This guide open and ready to follow
- [ ] PHASE1_Dropdown_to_Text_Conversion_Tracking.md open for updates

## Batch 1 Execution Steps

### Step 1: Document Current State (10 minutes)

**For each field, record:**

1. Navigate to NinjaOne admin panel
2. Go to Organization > Custom Fields
3. Search for field by name
4. Take screenshot or note:
   - Current field type (should be "Dropdown")
   - Dropdown values listed
   - Field scope (Organization or Device)
   - Any description text

**Quick Reference - Expected Dropdown Values:**

**Standard Health Status Pattern:**
- Healthy
- Warning
- Critical
- Unknown

**Server Status Pattern (if different):**
- Healthy
- Degraded
- Critical
- Stopped
- Unknown

### Step 2: Convert Fields in NinjaOne (25 minutes total, 5 min per field)

**For each field, perform these steps:**

#### Field 1: bitlockerHealthStatus

1. **NinjaOne Admin Panel:**
   - Navigate to Organization > Custom Fields
   - Search: "bitlockerHealthStatus"
   - Click "Edit" button
   - Change "Type" dropdown from "Dropdown" to "Text"
   - Click "Save"
   - **Verify:** Field type now shows "Text"

2. **Verify Existing Data:**
   - Open a device that has this field populated
   - Check that existing value is preserved
   - Value should still display correctly

**Expected Result:** Field converted, existing data preserved

#### Field 2: dnsServerStatus

1. **NinjaOne Admin Panel:**
   - Navigate to Organization > Custom Fields
   - Search: "dnsServerStatus"
   - Click "Edit" button
   - Change "Type" from "Dropdown" to "Text"
   - Click "Save"
   - **Verify:** Field type now shows "Text"

2. **Verify Existing Data:**
   - Check device with DNS Server role
   - Confirm value preserved

**Expected Result:** Field converted, existing data preserved

#### Field 3: fileServerHealthStatus

1. **NinjaOne Admin Panel:**
   - Navigate to Organization > Custom Fields
   - Search: "fileServerHealthStatus"
   - Click "Edit" button
   - Change "Type" from "Dropdown" to "Text"
   - Click "Save"
   - **Verify:** Field type now shows "Text"

2. **Verify Existing Data:**
   - Check file server device
   - Confirm value preserved

**Expected Result:** Field converted, existing data preserved

#### Field 4: printServerStatus

1. **NinjaOne Admin Panel:**
   - Navigate to Organization > Custom Fields
   - Search: "printServerStatus"
   - Click "Edit" button
   - Change "Type" from "Dropdown" to "Text"
   - Click "Save"
   - **Verify:** Field type now shows "Text"

2. **Verify Existing Data:**
   - Check print server device
   - Confirm value preserved

**Expected Result:** Field converted, existing data preserved

#### Field 5: mysqlServerStatus

**Note:** This field may not exist if no MySQL monitoring is deployed. If field doesn't exist, skip and note in tracking document.

1. **NinjaOne Admin Panel:**
   - Navigate to Organization > Custom Fields
   - Search: "mysqlServerStatus"
   - **If exists:**
     - Click "Edit" button
     - Change "Type" from "Dropdown" to "Text"
     - Click "Save"
     - **Verify:** Field type now shows "Text"
   - **If not found:**
     - Note in tracking document: "Field does not exist"
     - Continue to next step

**Expected Result:** Field converted (if exists) or noted as non-existent

### Step 3: Update Script Documentation (10 minutes)

**Scripts to Update:**

1. **scripts/07_BitLocker_Monitor.ps1**
   - Open in VS Code
   - Find header section with field list
   - Change: `bitlockerHealthStatus (Dropdown)` to `bitlockerHealthStatus (Text)`
   - Save file

2. **scripts/monitoring/Script_03_DNS_Server_Monitor.ps1**
   - Open in VS Code
   - Find header section with field list
   - Change: `dnsServerStatus (Dropdown)` to `dnsServerStatus (Text)`
   - Save file

3. **scripts/monitoring/Script_45_File_Server_Monitor.ps1**
   - Open in VS Code
   - Find header section with field list
   - Change: `fileServerHealthStatus (Dropdown)` to `fileServerHealthStatus (Text)`
   - Save file

4. **scripts/monitoring/Script_46_Print_Server_Monitor.ps1**
   - Open in VS Code
   - Find header section with field list
   - Change: `printServerStatus (Dropdown)` to `printServerStatus (Text)`
   - Save file

5. **MySQL script (if exists)** - Update accordingly

**Git Commit:**
```bash
cd /path/to/waf
git add scripts/07_BitLocker_Monitor.ps1
git add scripts/monitoring/Script_03_DNS_Server_Monitor.ps1
git add scripts/monitoring/Script_45_File_Server_Monitor.ps1
git add scripts/monitoring/Script_46_Print_Server_Monitor.ps1
git commit -m "Phase 1 Batch 1: Update field type documentation (Dropdown to Text)"
git push
```

### Step 4: Test Script Execution (15 minutes)

**Test each converted field:**

#### Test 1: BitLocker Monitor

1. Select test device in NinjaOne (any Windows device)
2. Navigate to device > Scripts
3. Run: "07_BitLocker_Monitor.ps1"
4. Wait for completion
5. **Verify:**
   - Script completes without errors
   - Check device custom fields
   - `bitlockerHealthStatus` populated with text value
   - Value is one of: Healthy, Warning, Critical, Unknown

**Expected Output:** Script success, field populated

#### Test 2: DNS Server Monitor

1. Select test device with DNS Server role
2. Run: "Script_03_DNS_Server_Monitor.ps1"
3. Wait for completion
4. **Verify:**
   - Script completes successfully
   - `dnsServerStatus` field populated
   - Value matches server state

**Expected Output:** Script success, field populated

#### Test 3: File Server Monitor

1. Select test device with File Server role
2. Run: "Script_45_File_Server_Monitor.ps1"
3. Wait for completion
4. **Verify:**
   - Script completes successfully
   - `fileServerHealthStatus` field populated
   - Value reflects server health

**Expected Output:** Script success, field populated

#### Test 4: Print Server Monitor

1. Select test device with Print Server role (or skip if not available)
2. Run: "Script_46_Print_Server_Monitor.ps1"
3. Wait for completion
4. **Verify:**
   - Script completes successfully
   - `printServerStatus` field populated
   - Value reflects server health

**Expected Output:** Script success, field populated

### Step 5: Validate Dashboard Display (10 minutes)

**For each converted field:**

1. **Device Details View:**
   - Navigate to test device in NinjaOne
   - Open device details page
   - Locate each converted field
   - **Verify:** Value displays correctly
   - **Verify:** Field is readable and formatted properly

2. **Search Functionality:**
   - Use NinjaOne search/filter
   - Filter by field value (e.g., "Healthy")
   - **Verify:** Devices appear in results
   - **Verify:** Search works correctly

3. **Custom Views (if applicable):**
   - Open any custom device views
   - Check if fields appear
   - **Verify:** Fields display in views
   - **Verify:** Sorting works correctly

**Expected Result:** All fields searchable, filterable, and display correctly

### Step 6: Update Tracking Document (5 minutes)

**Update PHASE1_Dropdown_to_Text_Conversion_Tracking.md:**

1. Open the tracking document
2. For each field, mark as completed:

```markdown
| bitlockerHealthStatus | 07_BitLocker_Monitor.ps1 | Completed | 2026-02-03 |
| dnsServerStatus | Script_03_DNS_Server_Monitor.ps1 | Completed | 2026-02-03 |
| fileServerHealthStatus | Script_45_File_Server_Monitor.ps1 | Completed | 2026-02-03 |
| printServerStatus | Script_46_Print_Server_Monitor.ps1 | Completed | 2026-02-03 |
| mysqlServerStatus | [script name or N/A] | Completed/Skipped | 2026-02-03 |
```

3. Update batch completion status:

```markdown
### Batch 1: Core Health Status Fields
**Status:** ✓ COMPLETED  
**Date Completed:** February 3, 2026  
**Fields Converted:** 4-5 fields  
**Issues:** None / [list any issues]
```

4. Save and commit:

```bash
git add docs/PHASE1_Dropdown_to_Text_Conversion_Tracking.md
git commit -m "Phase 1 Batch 1: Mark fields as completed"
git push
```

## Troubleshooting

### Issue: Field Not Found in NinjaOne

**Solution:**
- Verify exact field name (case-sensitive)
- Check if field is at Organization vs Device scope
- Search for similar names (typos, variations)
- If truly missing, note in tracking document and skip

### Issue: Existing Data Lost After Conversion

**Solution:**
- This should NOT happen - NinjaOne preserves data
- If data lost, immediately:
  - Document which field
  - Check if value was properly set before conversion
  - Re-run script to repopulate
  - Contact NinjaOne support if persistent

### Issue: Script Fails After Conversion

**Solution:**
- Check script output for specific error
- Verify field name matches exactly
- Confirm field type is now "Text"
- No code changes should be needed
- If persistent, review script code for issues

### Issue: Dashboard Search Not Working

**Solution:**
- Give NinjaOne 5-10 minutes to re-index
- Refresh browser cache
- Try exact value match first
- Check that field has values populated
- Verify field is set to searchable in NinjaOne

## Success Criteria

**Batch 1 is complete when:**

- [x] All 5 fields identified in NinjaOne
- [ ] All 5 fields converted from Dropdown to Text
- [ ] Existing data verified as preserved
- [ ] All 4-5 script headers updated
- [ ] All scripts tested successfully
- [ ] All fields display correctly in dashboard
- [ ] Dashboard search/filter working
- [ ] Tracking document updated
- [ ] All changes committed to git
- [ ] No errors or data loss

## Next Steps After Batch 1

**When Batch 1 is complete:**

1. **Review Results:**
   - Check for any issues
   - Document lessons learned
   - Confirm all success criteria met

2. **Prepare Batch 2:**
   - Review Batch 2 fields (Advanced Monitoring)
   - Ensure test devices available
   - Schedule time for execution

3. **Update Project Status:**
   - Update FIELD_CONVERSION_STATUS document
   - Note Batch 1 completion
   - Record any issues or improvements

## Time Tracking

**Actual Time Spent:**

| Activity | Estimated | Actual | Notes |
|----------|-----------|--------|-------|
| Pre-work | 10 min | ___ min | Documentation review |
| Field conversions | 25 min | ___ min | NinjaOne admin work |
| Script updates | 10 min | ___ min | Header changes |
| Testing | 15 min | ___ min | Script execution |
| Dashboard validation | 10 min | ___ min | UI verification |
| Tracking updates | 5 min | ___ min | Documentation |
| **Total** | **55 min** | **___ min** | |

**Notes on Timing:**
- Record actual time to improve future estimates
- Note any delays or issues that extended time
- Use for planning remaining batches

## Batch 1 Completion Checklist

**Before marking Batch 1 complete, verify:**

- [ ] All 5 fields converted in NinjaOne (or noted as N/A)
- [ ] Field type shows "Text" for all converted fields
- [ ] Existing field values preserved on test devices
- [ ] All script headers updated with "(Text)" notation
- [ ] All changes committed to git repository
- [ ] Scripts executed successfully on test devices
- [ ] New values populated correctly in fields
- [ ] Dashboard displays values correctly
- [ ] Search/filter functionality works
- [ ] Tracking document updated with completion dates
- [ ] No errors encountered (or all errors resolved)
- [ ] Time tracking completed
- [ ] Ready to proceed to Batch 2

---

**Batch Status:** READY TO EXECUTE  
**Created:** February 3, 2026 22:34 CET  
**Next Batch:** Batch 2 (Advanced Monitoring - 5 fields)  
**Estimated Batch 2 Start:** After Batch 1 completion and validation
