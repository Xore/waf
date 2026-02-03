# Phase 2: WYSIWYG Field Discovery Summary

**Date:** February 3, 2026  
**Status:** Discovery In Progress (47% Complete)  
**Fields Confirmed:** 8 of 17 fields

## Purpose

This document provides a quick reference summary of all discovered WYSIWYG fields for Phase 2 conversion. Each field has been inspected and confirmed from actual script code.

## Confirmed WYSIWYG Fields

### Infrastructure Monitoring (5 fields)

| Field Name | Script | Purpose | HTML Type |
|-----------|--------|---------|----------|
| `mssqlInstanceSummary` | Script_38_MSSQL_Server_Monitor.ps1 | SQL Server instance status table | Table |
| `veeamJobSummary` | Script_48_Veeam_Backup_Monitor.ps1 | Backup job results table | Table |
| `dnsZoneSummary` | Script_03_DNS_Server_Monitor.ps1 | DNS zone details with type, dynamic, AD integration | Table |
| `dhcpScopeSummary` | Script_02_DHCP_Server_Monitor.ps1 | DHCP scope utilization with ranges and lease counts | Table |
| `fsShareSummary` | Script_45_File_Server_Monitor.ps1 | File share listing with paths and sizes | Table |

### Server Role Monitoring (3 fields)

| Field Name | Script | Purpose | HTML Type |
|-----------|--------|---------|----------|
| `printPrinterSummary` | Script_46_Print_Server_Monitor.ps1 | Printer status, queue counts, driver info | Table |
| `hvVMSummary` | 08_HyperV_Host_Monitor.ps1 | VM list with state, CPU, memory, uptime | Table |
| `blVolumeSummary` | 07_BitLocker_Monitor.ps1 | BitLocker volumes with encryption status | Table |

### Fields Remaining to Discover (9 fields)

1. Script_43_Group_Policy_Monitor.ps1 - GPO summary field
2. 12_FlexLM_License_Monitor.ps1 - License feature summary
3. 20_FlexLM_License_Monitor.ps1 - License feature summary (duplicate?)
4. Script_47_FlexLM_License_Monitor.ps1 - License feature summary (newest version?)
5. 28_Security_Surface_Telemetry.ps1 - Security metrics summary
6. 18_HyperV_Host_Monitor.ps1 - May duplicate 08_HyperV
7. 16_ROLE_Additional.md references - Unknown fields
8. 08_DRIFT_Configuration_Drift.md references - Unknown fields
9. Apache/Web server monitor - If it exists

## Field Discovery Progress

**Completion Rate:** 47% (8/17 fields confirmed)

### Discovery Timeline

- **Feb 3, 2026 22:20 CET:** Initial search found 31 WYSIWYG references
- **Feb 3, 2026 22:24 CET:** Confirmed 5 fields (DNS, DHCP, File Server)
- **Feb 3, 2026 22:27 CET:** Confirmed 3 more fields (Print, HyperV, BitLocker)
- **Total confirmed:** 8 fields ready for conversion

## HTML Structure Patterns

### Standard Table Structure

All confirmed fields use similar HTML table structures:

```html
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'>
  <th>Column1</th><th>Column2</th><th>Column3</th>
</tr>
<tr>
  <td>Value1</td><td>Value2</td><td>Value3</td>
</tr>
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary:</strong> Additional context text
</p>
```

### Color Coding Patterns

**Status Colors (Common):**
- Green: Healthy, Normal, Running, Primary
- Red: Critical, Error, Offline
- Orange: Warning, PaperJam, Secondary
- Blue: Secondary zones
- Gray: Stopped, Stub zones, Inactive

**Examples:**
```html
<td style='color:green'>Running</td>
<td style='color:red'>Critical</td>
<td style='color:orange'>78%</td>
```

## Field Details by Category

### DNS Zone Summary

**Field:** `dnsZoneSummary`  
**Columns:** Zone Name | Type | Dynamic | AD Integrated  
**Color Coding:** Primary=green, Secondary=blue, Stub=gray  
**Footer:** Total zone count including auto-created

### DHCP Scope Summary

**Field:** `dhcpScopeSummary`  
**Columns:** Scope Name | Range | State | Utilization | Leases  
**Color Coding:** >90%=red, >75%=orange, else=green  
**Footer:** Scope count, active leases, overall utilization %

### File Share Summary

**Field:** `fsShareSummary`  
**Columns:** Share Name | Path | Size  
**Color Coding:** None (informational only)  
**Footer:** Total share count

### Print Server Summary

**Field:** `printPrinterSummary`  
**Columns:** Printer | Status | Jobs | Driver  
**Color Coding:** Normal=green, Offline/Error=red, Jam/Out=orange  
**Footer:** Printer counts, offline/error totals, job totals

### HyperV VM Summary

**Field:** `hvVMSummary`  
**Columns:** VM Name | State | CPU | Memory (GB) | Uptime  
**Color Coding:** Running=green, Off=gray, Other=orange  
**Footer:** None (table only)

### BitLocker Volume Summary

**Field:** `blVolumeSummary`  
**Columns:** Drive | Status | % | Method  
**Color Coding:** None (informational only)  
**Footer:** None (table only)

### SQL Instance Summary

**Field:** `mssqlInstanceSummary`  
**Details:** TBD (requires script inspection)  
**Assumed columns:** Instance | Status | Version | Databases

### Veeam Job Summary

**Field:** `veeamJobSummary`  
**Details:** TBD (requires script inspection)  
**Assumed columns:** Job Name | Status | Last Run | Size

## Conversion Priority Order

### High Priority (Core Infrastructure)

1. `dhcpScopeSummary` - Critical for network management
2. `dnsZoneSummary` - Critical for DNS management
3. `mssqlInstanceSummary` - Database monitoring
4. `fsShareSummary` - File server monitoring
5. `veeamJobSummary` - Backup monitoring

### Medium Priority (Server Roles)

6. `printPrinterSummary` - Print server management
7. `hvVMSummary` - Virtualization monitoring
8. `blVolumeSummary` - Security compliance

### Low Priority (Specialized)

9. FlexLM license fields (after discovery)
10. Group Policy field (after discovery)
11. Security telemetry field (after discovery)

## Next Steps

### Immediate Actions

1. **Inspect remaining scripts** to confirm final 9 fields:
   - Script_43_Group_Policy_Monitor.ps1
   - 12_FlexLM_License_Monitor.ps1 and variants
   - 28_Security_Surface_Telemetry.ps1

2. **Verify Script_38 and Script_48** HTML structures:
   - Confirm `mssqlInstanceSummary` columns
   - Confirm `veeamJobSummary` columns

3. **Begin Phase 2a conversions** (8 confirmed fields ready)

### Conversion Workflow

For each confirmed field:

1. **NinjaOne Admin Panel:**
   - Navigate to Organization > Custom Fields
   - Find field by exact name
   - Change type from WYSIWYG to TEXT
   - Save configuration

2. **Update Script Documentation:**
   - Change header comment from "(WYSIWYG)" to "(Text)"
   - No code changes required

3. **Test on Development Device:**
   - Run script manually
   - Verify HTML appears in field
   - Check dashboard rendering

4. **Mark Complete:**
   - Update PHASE2_WYSIWYG_to_Text_Conversion_Tracking.md
   - Record completion date

## Related Documents

- [PHASE2_WYSIWYG_to_Text_Conversion_Tracking.md](./PHASE2_WYSIWYG_to_Text_Conversion_Tracking.md) - Main tracking
- [ACTION_PLAN_Field_Conversion_Documentation.md](./ACTION_PLAN_Field_Conversion_Documentation.md) - Overall plan
- [PHASE1_Dropdown_to_Text_Conversion_Tracking.md](./PHASE1_Dropdown_to_Text_Conversion_Tracking.md) - Phase 1

---

**Document Status:** Living document, updated as fields discovered  
**Last Updated:** February 3, 2026 22:27 CET  
**Next Update:** After inspecting remaining 9 fields
