# Phase 2: WYSIWYG to Text+HTML Field Conversion Tracking

**Status:** Field Discovery In Progress  
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
  - Status: Discovered

- **Script_48_Veeam_Backup_Monitor.ps1**
  - `veeamJobSummary` (WYSIWYG → TEXT)
  - Purpose: Backup job results table
  - Status: Discovered

- **Script_03_DNS_Server_Monitor.ps1**
  - `dnsZoneSummary` (WYSIWYG → TEXT) ✓ CONFIRMED
  - Purpose: DNS zone details table with type, dynamic updates, AD integration
  - Status: Discovered

- **Script_45_File_Server_Monitor.ps1**
  - `fsShareSummary` (WYSIWYG → TEXT) ✓ CONFIRMED
  - Purpose: File share listing with path and size information
  - Status: Discovered

- **Script_02_DHCP_Server_Monitor.ps1**
  - `dhcpScopeSummary` (WYSIWYG → TEXT) ✓ CONFIRMED
  - Purpose: DHCP scope utilization table with range, state, lease counts
  - Status: Discovered

- **Script_46_Print_Server_Monitor.ps1**
  - Field requires inspection (likely `printQueueSummary` or `printerSummary`)
  - Status: Not Discovered

- **Script_01_Apache_Web_Server_Monitor.ps1**
  - Field requires inspection (likely `apacheVHostSummary` or `apacheSummary`)
  - Status: Not Discovered

### Server Role Monitoring (4 fields)

- **08_HyperV_Host_Monitor.ps1** / **18_HyperV_Host_Monitor.ps1**
  - Field requires inspection (likely `hypervVMSummary` or `vmSummary`)
  - Status: Not Discovered

- **12_FlexLM_License_Monitor.ps1** / **20_FlexLM_License_Monitor.ps1**
  - Field requires inspection (likely `flexlmFeatureSummary` or `licenseFeatureSummary`)
  - Status: Not Discovered

- **Script_47_FlexLM_License_Monitor.ps1**
  - Field requires inspection
  - Status: Not Discovered

- **Script_43_Group_Policy_Monitor.ps1**
  - Field requires inspection (likely `gpoSummary` or `gpResultSummary`)
  - Status: Not Discovered

### Security & Compliance (2 fields)

- **07_BitLocker_Monitor.ps1**
  - Field requires inspection (likely `bitlockerVolumeSummary` or `blVolumeSummary`)
  - Status: Not Discovered

- **28_Security_Surface_Telemetry.ps1**
  - Field requires inspection (likely `securitySummary` or `securityMetrics`)
  - Status: Not Discovered

### Configuration Management (1 field)

- **08_DRIFT_Configuration_Drift.md** (Documentation reference)
  - Field requires inspection
  - Status: Not Discovered

## Field Discovery Progress

**Total WYSIWYG References Found:** 31 code locations  
**Fields Identified:** 17 distinct fields  
**Fields Confirmed:** 5 fields (29%)  
**Fields Requiring Inspection:** 12 fields (71%)

### Recently Discovered Fields (Feb 3, 2026)

1. ✓ `dnsZoneSummary` - DNS zone table with type, dynamic, AD integration columns
2. ✓ `dhcpScopeSummary` - DHCP scope utilization table with range and lease info
3. ✓ `fsShareSummary` - File share listing with paths and sizes

## Discovery Phase Tasks

Before beginning conversions, complete field discovery:

1. **Inspect Remaining Scripts** (Priority Order):
   - ✓ Script_03_DNS_Server_Monitor.ps1 - COMPLETED
   - ✓ Script_02_DHCP_Server_Monitor.ps1 - COMPLETED
   - ✓ Script_45_File_Server_Monitor.ps1 - COMPLETED
   - Script_46_Print_Server_Monitor.ps1
   - Script_43_Group_Policy_Monitor.ps1
   - 08_HyperV_Host_Monitor.ps1
   - 12_FlexLM_License_Monitor.ps1
   - 07_BitLocker_Monitor.ps1
   - 28_Security_Surface_Telemetry.ps1
   - Script_01_Apache_Web_Server_Monitor.ps1 (if exists)

2. **Document Each Field:**
   - Exact field name ✓
   - Current values/examples ✓
   - HTML structure used ✓
   - Scripts that write to field ✓

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

### Status with Color Coding
```html
<td style='color:green'>Healthy</td>
<td style='color:red'>Critical</td>
<td style='color:orange'>Warning</td>
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

### Summary Footer
```html
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary:</strong> Additional context
</p>
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
| Script_03_DNS_Server_Monitor.ps1 | dnsZoneSummary | Discovered | - |
| Script_45_File_Server_Monitor.ps1 | fsShareSummary | Discovered | - |
| Script_02_DHCP_Server_Monitor.ps1 | dhcpScopeSummary | Discovered | - |
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

## HTML Structure Examples

### DNS Zone Summary Table
```html
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Zone Name</th><th>Type</th><th>Dynamic</th><th>AD Integrated</th></tr>
<tr><td>example.com</td><td style='color:green'>Primary</td><td>Secure</td><td>True</td></tr>
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary:</strong> 15 total zones (including auto-created)
</p>
```

### DHCP Scope Summary Table
```html
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Scope Name</th><th>Range</th><th>State</th><th>Utilization</th><th>Leases</th></tr>
<tr><td>Main Office</td><td>192.168.1.10 - 192.168.1.250</td><td>Active</td><td style='color:orange'>78%</td><td>188 / 241</td></tr>
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary:</strong> 3 scopes, 450 active leases, 67% overall utilization
</p>
```

### File Share Summary Table
```html
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Share Name</th><th>Path</th><th>Size</th></tr>
<tr><td>Data</td><td>D:\Shares\Data</td><td>245.67 GB</td></tr>
<tr><td>Public</td><td>D:\Shares\Public</td><td>12.34 GB</td></tr>
</table>
<p style='font-size:0.9em; color:#666; margin-top:10px;'>Total Shares: 2</p>
```

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

1. dhcpScopeSummary - Critical infrastructure component
2. dnsZoneSummary - Critical infrastructure component
3. mssqlInstanceSummary - Database monitoring
4. fsShareSummary - File server monitoring
5. veeamJobSummary - Backup monitoring

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

- All WYSIWYG fields identified and documented ✓ (In Progress: 71% remaining)
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

**Last Updated:** February 3, 2026 22:24 CET  
**Next Review:** After remaining field discovery  
**Discovery Progress:** 5/17 fields confirmed (29%)
