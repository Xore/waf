# Phase 2: WYSIWYG to Text+HTML Field Conversion Tracking

**Status:** Planning  
**Started:** February 3, 2026  
**Prerequisites:** Phase 1 (Dropdown to Text) completion

## Overview

This document tracks the conversion of all WYSIWYG custom fields to TEXT fields containing HTML content across the Windows Automation Framework scripts. This conversion improves version control, maintainability, and consistency.

## Benefits of Text+HTML Migration

- **Version Control:** HTML stored as text is diff-friendly in git
- **Script Maintainability:** Easier to modify HTML strings in code
- **Consistency:** Single field type for formatted output
- **Better Testing:** Can validate HTML structure in tests
- **Dashboard Display:** NinjaOne renders HTML in text fields correctly
- **Field Type Simplification:** Reduces NinjaOne field type complexity

## Conversion Requirements

### Field Migration Steps

1. **Identify all WYSIWYG fields** in NinjaOne custom field configuration
2. **Convert each WYSIWYG to text field** in NinjaOne admin panel
3. **Verify HTML rendering** in NinjaOne dashboard
4. **Update script documentation** to reflect TEXT field type
5. **Test script execution** to verify proper value writing
6. **Validate dashboard display** shows formatted output correctly

### Code Changes Required

**No PowerShell code changes needed.** The `Ninja-Property-Set` command works identically for both WYSIWYG and TEXT fields when passing HTML content. Scripts already generate HTML strings, so only the NinjaOne field configuration and script documentation need updating.

## Complete WYSIWYG Field Inventory

### Infrastructure Monitoring (7 fields)

- **Script_38_MSSQL_Server_Monitor.ps1**
  - `mssqlInstanceSummary` (WYSIWYG → TEXT)
  - Purpose: SQL Server instance status table

- **Script_48_Veeam_Backup_Monitor.ps1**
  - `veeamJobSummary` (WYSIWYG → TEXT)
  - Purpose: Backup job results table

- **Script_03_DNS_Server_Monitor.ps1**
  - Field requires inspection (likely `dnsZoneSummary` or similar)

- **Script_45_File_Server_Monitor.ps1**
  - Field requires inspection (likely `fileShareSummary` or similar)

- **Script_02_DHCP_Server_Monitor.ps1**
  - Field requires inspection (likely `dhcpScopeSummary` or similar)

- **Script_46_Print_Server_Monitor.ps1**
  - Field requires inspection (likely `printerSummary` or similar)

- **Script_01_Apache_Web_Server_Monitor.ps1**
  - Field requires inspection (likely `apacheSummary` or similar)

### Server Role Monitoring (4 fields)

- **08_HyperV_Host_Monitor.ps1** / **18_HyperV_Host_Monitor.ps1**
  - Field requires inspection (likely `hypervVMSummary` or similar)

- **12_FlexLM_License_Monitor.ps1** / **20_FlexLM_License_Monitor.ps1**
  - Field requires inspection (likely `licenseFeatureSummary` or similar)

- **Script_47_FlexLM_License_Monitor.ps1**
  - Field requires inspection

- **Script_43_Group_Policy_Monitor.ps1**
  - Field requires inspection (likely `gpoSummary` or similar)

### Security & Compliance (2 fields)

- **07_BitLocker_Monitor.ps1**
  - Field requires inspection (likely `bitlockerVolumeSummary` or similar)

- **28_Security_Surface_Telemetry.ps1**
  - Field requires inspection (likely `securitySummary` or similar)

### Configuration Management (1 field)

- **08_DRIFT_Configuration_Drift.md** (Documentation reference)
  - Field requires inspection

## Field Discovery Progress

**Total WYSIWYG References Found:** 31 code locations  
**Fields Identified:** 14+ distinct fields  
**Fields Requiring Inspection:** ~10 fields

## Discovery Phase Tasks

Before beginning conversions, complete field discovery:

1. **Inspect Remaining Scripts** (Priority Order):
   - Script_03_DNS_Server_Monitor.ps1
   - Script_45_File_Server_Monitor.ps1
   - Script_02_DHCP_Server_Monitor.ps1
   - Script_46_Print_Server_Monitor.ps1
   - Script_43_Group_Policy_Monitor.ps1
   - 08_HyperV_Host_Monitor.ps1
   - 12_FlexLM_License_Monitor.ps1
   - 07_BitLocker_Monitor.ps1
   - 28_Security_Surface_Telemetry.ps1

2. **Document Each Field:**
   - Exact field name
   - Current values/examples
   - HTML structure used
   - Scripts that write to field

3. **Create Conversion Batches** (after discovery)

## Common HTML Patterns

Most WYSIWYG fields use these HTML patterns:

### Table Format (Most Common)
```html
<table border='1' style='border-collapse:collapse; width:100%'>
<tr style='background-color:#f0f0f0;'><th>Column1</th><th>Column2</th></tr>
<tr><td>Value1</td><td>Value2</td></tr>
</table>
```

### Status with Color
```html
<p style='color:green'>Success message</p>
<p style='color:red'>Error message</p>
```

### Multi-Section Summary
```html
<h3>Section Title</h3>
<p>Description text</p>
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
</ul>
```

## Conversion Progress Tracking

### Status Legend

- **Not Discovered:** Field name and details unknown
- **Discovered:** Field identified, ready for conversion
- **In Progress:** NinjaOne field being converted or tested
- **Completed:** Field converted, documentation updated, tested

### Infrastructure Monitoring Checklist

| Script | Field Name | Status | Date Completed |
|--------|-----------|--------|----------------|
| Script_38_MSSQL_Server_Monitor.ps1 | mssqlInstanceSummary | Discovered | - |
| Script_48_Veeam_Backup_Monitor.ps1 | veeamJobSummary | Discovered | - |
| Script_03_DNS_Server_Monitor.ps1 | TBD | Not Discovered | - |
| Script_45_File_Server_Monitor.ps1 | TBD | Not Discovered | - |
| Script_02_DHCP_Server_Monitor.ps1 | TBD | Not Discovered | - |
| Script_46_Print_Server_Monitor.ps1 | TBD | Not Discovered | - |
| Script_01_Apache_Web_Server_Monitor.ps1 | TBD | Not Discovered | - |

### Server Role Monitoring Checklist

| Script | Field Name | Status | Date Completed |
|--------|-----------|--------|----------------|
| 08_HyperV_Host_Monitor.ps1 | TBD | Not Discovered | - |
| 18_HyperV_Host_Monitor.ps1 | TBD | Not Discovered | - |
| 12_FlexLM_License_Monitor.ps1 | TBD | Not Discovered | - |
| 20_FlexLM_License_Monitor.ps1 | TBD | Not Discovered | - |
| Script_47_FlexLM_License_Monitor.ps1 | TBD | Not Discovered | - |
| Script_43_Group_Policy_Monitor.ps1 | TBD | Not Discovered | - |

### Security & Configuration Checklist

| Script | Field Name | Status | Date Completed |
|--------|-----------|--------|----------------|
| 07_BitLocker_Monitor.ps1 | TBD | Not Discovered | - |
| 28_Security_Surface_Telemetry.ps1 | TBD | Not Discovered | - |

## Testing Protocol

### Pre-Conversion Testing

1. **Document current WYSIWYG configuration**
   - Field name and type
   - Screenshot of field configuration
   - Example HTML content from field
   - Screenshot of dashboard display

2. **Validate HTML structure**
   - Verify HTML is well-formed
   - Check for common issues (unclosed tags, inline styles)
   - Document any special formatting

### Post-Conversion Testing

1. **Verify field conversion**
   - Confirm field changed from WYSIWYG to TEXT in NinjaOne
   - Check that existing content preserved
   - Verify field permissions unchanged

2. **Test script execution**
   - Run affected script on test device
   - Verify script completes without errors
   - Confirm HTML content appears in field

3. **Validate dashboard display**
   - Navigate to device in NinjaOne dashboard
   - Verify HTML renders correctly (tables, colors, formatting)
   - Check that display matches previous WYSIWYG rendering
   - Test that HTML special characters display correctly

4. **Test dashboard operations**
   - Verify field appears in device details
   - Test that field can be searched
   - Confirm field can be added to custom views

## Notes

### Known Considerations

- **HTML Rendering:** NinjaOne renders HTML in TEXT fields the same as WYSIWYG
- **Data Preservation:** Existing WYSIWYG content converts to text automatically
- **Script Compatibility:** No script changes required for conversion
- **Dashboard Compatibility:** Display behavior remains identical
- **Search Capability:** TEXT fields may have better search functionality

### HTML Best Practices

For scripts generating HTML content:

1. **Use inline styles** (NinjaOne may strip external CSS)
2. **Keep HTML simple** (basic tables, paragraphs, lists)
3. **Avoid JavaScript** (security restrictions in NinjaOne)
4. **Use standard HTML entities** for special characters
5. **Test HTML rendering** after any changes

### Common HTML Entities

- `&lt;` for <
- `&gt;` for >
- `&amp;` for &
- `&quot;` for "
- `&nbsp;` for non-breaking space

## Recommended Conversion Order

### Phase 2a: Infrastructure Summary Fields (Priority)

1. mssqlInstanceSummary
2. veeamJobSummary
3. DNS zone summary field
4. File share summary field
5. DHCP scope summary field

### Phase 2b: Role-Specific Summary Fields

6. Print server summary field
7. HyperV VM summary field
8. License feature summary fields
9. Group Policy summary field

### Phase 2c: Security & Specialized Fields

10. BitLocker volume summary field
11. Security surface telemetry field
12. Apache/web server summary field

## Success Criteria

Phase 2 is complete when:

- All WYSIWYG fields identified and documented
- All fields converted from WYSIWYG to TEXT in NinjaOne
- All affected script headers updated
- All fields tested and validated
- HTML rendering verified in dashboard
- Tracking document shows 100% completion
- All changes committed to repository

## Related Documentation

- [ACTION_PLAN_Field_Conversion_Documentation.md](./ACTION_PLAN_Field_Conversion_Documentation.md) - Master conversion plan
- [PHASE1_Dropdown_to_Text_Conversion_Tracking.md](./PHASE1_Dropdown_to_Text_Conversion_Tracking.md) - Phase 1 tracking

---

**Last Updated:** February 3, 2026  
**Next Review:** After field discovery completion
