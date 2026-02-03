# Phase 1: Dropdown to Text Conversion Procedure

**Purpose:** Step-by-step guide for converting dropdown fields to text fields in NinjaOne

## Prerequisites

- NinjaOne admin access with custom field management permissions
- Access to the [PHASE1_Dropdown_to_Text_Conversion_Tracking.md](./PHASE1_Dropdown_to_Text_Conversion_Tracking.md) document
- Test device available for validation

## Conversion Procedure

### Step 1: Pre-Conversion Documentation

Before converting each field:

1. **Log into NinjaOne Admin Panel**
   - Navigate to Administration > Custom Fields
   - Locate the target dropdown field

2. **Document Current Configuration**
   - Field name (exact spelling and capitalization)
   - Field type (confirm it is Dropdown)
   - Dropdown values (all available options)
   - Field category/group (if applicable)
   - Screenshot the field configuration

3. **Check Current Usage**
   - Navigate to Devices view
   - Filter by the field to see current data distribution
   - Note any devices using the field
   - Export data if needed for backup

### Step 2: Field Conversion in NinjaOne

1. **Access Field Settings**
   - Administration > Custom Fields
   - Find the dropdown field in the list
   - Click Edit/Modify

2. **Change Field Type**
   - Change field type from "Dropdown" to "Text"
   - NinjaOne will display a warning about data preservation
   - **IMPORTANT:** NinjaOne retains existing dropdown values as text
   - Confirm the conversion

3. **Verify Field Settings**
   - Confirm field name remains unchanged
   - Check that field category/group is preserved
   - Verify permissions are still correct
   - Save changes

### Step 3: Post-Conversion Validation

1. **Verify Existing Data**
   - Navigate to Devices with existing field values
   - Confirm dropdown values converted to text correctly
   - Check that no data was lost during conversion

2. **Test Script Execution**
   - Identify a test device with the relevant role/feature
   - Run the affected monitoring script manually
   - Verify script completes without errors
   - Confirm new value appears in NinjaOne dashboard

3. **Test Dashboard Filtering**
   - Navigate to Devices view in NinjaOne
   - Add the converted text field as a column
   - Test filtering by typing partial values
   - Verify sorting works alphabetically
   - Confirm search functionality works

### Step 4: Update Script Documentation

1. **Locate Script File**
   - Find the script in the repository
   - Open for editing

2. **Update Field Documentation**
   - Locate the `.FIELDS UPDATED` section in script header
   - Change field type from `(Dropdown)` to `(Text)`
   - Example:
     ```powershell
     # Before:
     - bitlockerHealthStatus (Dropdown)
     
     # After:
     - bitlockerHealthStatus (Text)
     ```

3. **Commit Changes**
   - Commit message format: `Update field documentation: [fieldname] Dropdown → Text`
   - Push to repository

### Step 5: Update Tracking Document

1. **Open Tracking Document**
   - Edit [PHASE1_Dropdown_to_Text_Conversion_Tracking.md](./PHASE1_Dropdown_to_Text_Conversion_Tracking.md)

2. **Update Checklist**
   - Find the field in the appropriate checklist table
   - Change Status from "Not Started" to "Completed"
   - Add completion date in format: YYYY-MM-DD

3. **Commit Update**
   - Commit message: `Mark [fieldname] conversion as complete`

## Batch Processing Workflow

For efficient batch conversions, follow this workflow:

### Batch 1 Example: Core Health Status Fields

**Fields:** bitlockerHealthStatus, dnsServerStatus, fileServerHealthStatus, printServerStatus, mysqlServerStatus

1. **Pre-work (15 minutes)**
   - Document all 5 fields in NinjaOne
   - Take screenshots
   - Note current value distributions

2. **Conversion (10 minutes)**
   - Convert all 5 fields sequentially
   - Verify each conversion immediately

3. **Testing (20 minutes)**
   - Test 1-2 scripts from the batch
   - Verify dashboard filtering on all 5 fields
   - Confirm data integrity

4. **Documentation (10 minutes)**
   - Update script headers for all affected scripts
   - Update tracking document
   - Commit all changes

**Total Time per Batch:** ~55 minutes

## Troubleshooting

### Issue: Field Not Found in NinjaOne

**Cause:** Field may not exist yet or has different name

**Solution:**
- Check field naming in NinjaOne (case-sensitive)
- Search for similar field names
- If field doesn't exist, it may need to be created first
- Verify script is actually deployed and running

### Issue: Data Lost After Conversion

**Cause:** Rare NinjaOne issue or incorrect field selected

**Solution:**
- Check if you converted the correct field
- Verify field name spelling matches exactly
- Contact NinjaOne support if data truly lost
- Restore from backup/export if available

### Issue: Script Fails After Conversion

**Cause:** Script likely had errors before conversion (conversion doesn't affect script execution)

**Solution:**
- Review script execution logs in NinjaOne
- Test script manually on device
- Check if device meets script requirements
- Verify `Ninja-Property-Set` commands use correct field names

### Issue: Filtering Not Working on Converted Field

**Cause:** Browser cache or NinjaOne UI needs refresh

**Solution:**
- Hard refresh browser (Ctrl+F5)
- Clear NinjaOne cache
- Log out and log back in
- Wait 5-10 minutes for NinjaOne to update indexes

## Quality Checklist

Before marking a field conversion as complete, verify:

- [ ] Field converted from Dropdown to Text in NinjaOne
- [ ] Existing data preserved and visible
- [ ] Test script executed successfully
- [ ] New values appear correctly in dashboard
- [ ] Dashboard filtering works
- [ ] Dashboard sorting works
- [ ] Script header documentation updated
- [ ] Tracking document updated with completion date
- [ ] All changes committed to repository

## Field-Specific Notes

### netConnectionType (Script_40)

**Special Consideration:** This field has 5 distinct values (Disconnected, WiFi, VPN, Cellular, Wired)

**Testing:** Ensure filtering can distinguish between all connection types

### licenseServerStatus (Multiple Scripts)

**Special Consideration:** Used by both Script_12 and Script_20

**Testing:** Verify both scripts write to same field correctly after conversion

### Health Status Fields (Most Scripts)

**Special Consideration:** Most use 4-state pattern (Unknown, Healthy, Warning, Critical)

**Best Practice:** Test filtering for "Critical" to quickly identify problem systems

## Post-Phase 1 Validation

After completing all conversions:

1. **Dashboard Review**
   - Create custom device view with all converted fields
   - Verify all fields display correctly
   - Test filtering on multiple fields simultaneously
   - Confirm sorting works across all converted fields

2. **Script Execution Review**
   - Check NinjaOne activity logs for script errors
   - Verify all monitoring scripts still running on schedule
   - Confirm no increase in script failures

3. **User Acceptance**
   - Demonstrate improved filtering to team
   - Gather feedback on dashboard usability
   - Document any issues or requests

## Success Criteria

Phase 1 is complete when:

- All 27+ dropdown fields converted to text in NinjaOne
- All affected script headers updated
- All fields tested and validated
- Tracking document shows 100% completion
- No data loss occurred during conversions
- Dashboard filtering confirmed working
- All changes committed to repository

## Next Phase

After completing Phase 1, proceed to:

**Phase 2:** WYSIWYG to Text+HTML Field Conversions

Refer to the master action plan: [ACTION_PLAN_Field_Conversion_Documentation.md](./ACTION_PLAN_Field_Conversion_Documentation.md)

---

**Document Version:** 1.0  
**Last Updated:** February 3, 2026  
**Next Review:** After Batch 1 completion
