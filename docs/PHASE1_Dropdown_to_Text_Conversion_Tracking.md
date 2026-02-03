# Phase 1: Dropdown to Text Field Conversion Tracking

**Status:** In Progress  
**Started:** February 3, 2026

## Overview

This document tracks the conversion of all dropdown custom fields to text fields across the Windows Automation Framework scripts. This conversion is necessary because NinjaOne dropdown fields cannot filter data dynamically in the dashboard.

## Benefits of Text Field Migration

- **Dashboard Filtering:** Text fields support filtering and search operations
- **Better UX:** Users can quickly find specific values without dropdown navigation
- **Sorting Capability:** Proper alphabetical/numerical sorting in dashboard views
- **Consistency:** Aligns with framework text-first strategy

## Conversion Requirements

### Field Migration Steps

1. **Identify all dropdown fields** in NinjaOne custom field configuration
2. **Convert each dropdown to text field** in NinjaOne admin panel
3. **Update script documentation** to reflect TEXT field type
4. **Test script execution** to verify proper value writing
5. **Validate dashboard filtering** works correctly

### Code Changes Required

No PowerShell code changes are needed. The `Ninja-Property-Set` command works identically for both field types. Only the NinjaOne field configuration and script documentation comments need updating.

## Complete Dropdown Field Inventory

### Main Scripts Directory (17 fields)

#### Security Monitoring

- **17_BitLocker_Monitor.ps1**
  - `bitlockerHealthStatus` (Dropdown → TEXT)
  - Values: Healthy, Warning, Critical, Unknown

#### Server Role Monitoring

- **03_DNS_Server_Monitor.ps1**
  - `dnsServerStatus` (Dropdown → TEXT)
  - Values: Active, Degraded, Failed, Unknown

- **05_File_Server_Monitor.ps1** / **15_File_Server_Monitor.ps1**
  - `fileServerHealthStatus` (Dropdown → TEXT)
  - Values: Healthy, Warning, Critical, Unknown

- **06_Print_Server_Monitor.ps1** / **16_Print_Server_Monitor.ps1**
  - `printServerStatus` (Dropdown → TEXT)
  - Values: Healthy, Warning, Critical, Unknown

- **11_MySQL_Server_Monitor.ps1** / **19_MySQL_Server_Monitor.ps1**
  - `mysqlServerStatus` (Dropdown → TEXT)
  - Values: Running, Stopped, Degraded, Unknown

- **18_HyperV_Host_Monitor.ps1**
  - `hypervHostStatus` (Dropdown → TEXT)
  - Values: Healthy, Warning, Critical, Unknown

#### Validation Scripts

- **P1_Critical_Device_Validator.ps1**
  - `criticalDeviceStatus` (Dropdown → TEXT)
  - Values: Valid, Missing, Misconfigured

- **P2_High_Priority_Validator.ps1**
  - `highPriorityStatus` (Dropdown → TEXT)
  - Values: Valid, Missing, Warning

#### Analysis Tools

- **14_Local_Admin_Drift_Analyzer.ps1**
  - `adminDriftStatus` (Dropdown → TEXT)
  - Values: Compliant, Drift Detected, Unknown

- **18_Profile_Hygiene_Cleanup_Advisor.ps1**
  - `profileHygieneStatus` (Dropdown → TEXT)
  - Values: Healthy, Cleanup Recommended, Critical

- **20_Server_Role_Identifier.ps1**
  - `serverRoleStatus` (Dropdown → TEXT)
  - Values: Identified, Unidentified, Multiple Roles

- **20_FlexLM_License_Monitor.ps1** / **12_FlexLM_License_Monitor.ps1**
  - `licenseServerStatus` (Dropdown → TEXT)
  - Values: Available, Low, Critical, Unreachable

- **21_Battery_Health_Monitor.ps1**
  - `batteryHealthStatus` (Dropdown → TEXT)
  - Values: Good, Fair, Poor, Replace

### Monitoring Directory Scripts (10 fields)

- **Script_01_Apache_Web_Server_Monitor.ps1**
  - `apacheHealthStatus` (Dropdown → TEXT)
  - Values: Unknown, Healthy, Warning, Critical

- **Script_03_DNS_Server_Monitor.ps1**
  - Requires inspection (likely `dnsHealthStatus`)

- **Script_38_MSSQL_Server_Monitor.ps1**
  - `mssqlHealthStatus` (Dropdown → TEXT)
  - Values: Unknown, Healthy, Warning, Critical

- **Script_39_MySQL_Server_Monitor.ps1**
  - Requires inspection (likely `mysqlHealthStatus`)

- **Script_40_Network_Monitor.ps1**
  - `netConnectionType` (Dropdown → TEXT)
  - Values: Disconnected, WiFi, VPN, Cellular, Wired

- **Script_41_Battery_Health_Monitor.ps1**
  - Requires inspection (likely `batteryHealthStatus`)

- **Script_44_Event_Log_Monitor.ps1**
  - `evtHealthStatus` (Dropdown → TEXT)
  - Values: Healthy, Warning, Critical, Unknown

- **Script_45_File_Server_Monitor.ps1**
  - Requires inspection (likely `fileServerHealthStatus`)

- **Script_47_FlexLM_License_Monitor.ps1**
  - Requires inspection (likely `flexlmHealthStatus`)

- **Script_48_Veeam_Backup_Monitor.ps1**
  - `veeamHealthStatus` (Dropdown → TEXT)
  - Values: Unknown, Healthy, Warning, Critical

## Summary Statistics

**Total Dropdown Fields Identified:** 27+  
**Main Scripts:** 17 fields  
**Monitoring Scripts:** 10+ fields  

**Field Categories:**
- Health Status Fields: ~20 fields
- Connection Type: 1 field (netConnectionType)
- Validation Status: 2 fields
- Role/License Status: 2 fields
- Battery Status: 1+ field

## Conversion Progress

### Status Legend

- **Not Started:** Field identified but conversion not yet performed
- **In Progress:** NinjaOne field being converted or tested
- **Completed:** Field converted, documentation updated, tested

### Main Scripts Checklist

| Script | Field Name | Status | Date Completed |
|--------|-----------|--------|----------------|
| 17_BitLocker_Monitor.ps1 | bitlockerHealthStatus | Not Started | - |
| 03_DNS_Server_Monitor.ps1 | dnsServerStatus | Not Started | - |
| 05_File_Server_Monitor.ps1 | fileServerHealthStatus | Not Started | - |
| 06_Print_Server_Monitor.ps1 | printServerStatus | Not Started | - |
| 11_MySQL_Server_Monitor.ps1 | mysqlServerStatus | Not Started | - |
| 15_File_Server_Monitor.ps1 | fileServerHealthStatus | Not Started | - |
| 16_Print_Server_Monitor.ps1 | printServerStatus | Not Started | - |
| 18_HyperV_Host_Monitor.ps1 | hypervHostStatus | Not Started | - |
| 19_MySQL_Server_Monitor.ps1 | mysqlServerStatus | Not Started | - |
| P1_Critical_Device_Validator.ps1 | criticalDeviceStatus | Not Started | - |
| P2_High_Priority_Validator.ps1 | highPriorityStatus | Not Started | - |
| 14_Local_Admin_Drift_Analyzer.ps1 | adminDriftStatus | Not Started | - |
| 18_Profile_Hygiene_Cleanup_Advisor.ps1 | profileHygieneStatus | Not Started | - |
| 20_Server_Role_Identifier.ps1 | serverRoleStatus | Not Started | - |
| 12_FlexLM_License_Monitor.ps1 | licenseServerStatus | Not Started | - |
| 20_FlexLM_License_Monitor.ps1 | licenseServerStatus | Not Started | - |
| 21_Battery_Health_Monitor.ps1 | batteryHealthStatus | Not Started | - |

### Monitoring Scripts Checklist

| Script | Field Name | Status | Date Completed |
|--------|------------|--------|----------------|
| Script_01_Apache_Web_Server_Monitor.ps1 | apacheHealthStatus | Not Started | - |
| Script_03_DNS_Server_Monitor.ps1 | TBD (needs inspection) | Not Started | - |
| Script_38_MSSQL_Server_Monitor.ps1 | mssqlHealthStatus | Not Started | - |
| Script_39_MySQL_Server_Monitor.ps1 | TBD (needs inspection) | Not Started | - |
| Script_40_Network_Monitor.ps1 | netConnectionType | Not Started | - |
| Script_41_Battery_Health_Monitor.ps1 | TBD (needs inspection) | Not Started | - |
| Script_44_Event_Log_Monitor.ps1 | evtHealthStatus | Not Started | - |
| Script_45_File_Server_Monitor.ps1 | TBD (needs inspection) | Not Started | - |
| Script_47_FlexLM_License_Monitor.ps1 | TBD (needs inspection) | Not Started | - |
| Script_48_Veeam_Backup_Monitor.ps1 | veeamHealthStatus | Not Started | - |

## Recommended Conversion Order

### Batch 1: Core Health Status Fields (Priority)
These are the most commonly used across infrastructure:
1. `bitlockerHealthStatus`
2. `dnsServerStatus`
3. `fileServerHealthStatus`
4. `printServerStatus`
5. `mysqlServerStatus`

### Batch 2: Advanced Monitoring
6. `hypervHostStatus`
7. `mssqlHealthStatus`
8. `apacheHealthStatus`
9. `veeamHealthStatus`
10. `evtHealthStatus`

### Batch 3: Validation & Analysis
11. `criticalDeviceStatus`
12. `highPriorityStatus`
13. `adminDriftStatus`
14. `profileHygieneStatus`
15. `serverRoleStatus`

### Batch 4: Specialized Fields
16. `licenseServerStatus`
17. `batteryHealthStatus`
18. `netConnectionType`

## Testing Protocol

### Pre-Conversion Testing

1. Document current dropdown values in NinjaOne
2. Capture screenshot of field configuration
3. Export current field data if possible

### Post-Conversion Testing

1. Run affected script on test device
2. Verify value appears correctly in NinjaOne dashboard
3. Test dashboard filtering with new text field
4. Verify sorting works as expected
5. Confirm no data loss from conversion

## Notes

### Known Considerations

- **Data Preservation:** NinjaOne retains existing dropdown values when converting to text
- **Case Sensitivity:** Text fields are case-sensitive for filtering; maintain consistent capitalization
- **Value Validation:** Consider implementing runtime validation in scripts if needed
- **Documentation:** Update script header comments to reflect TEXT field type

### Common Status Value Patterns

Most health status fields use one of these patterns:
- **4-State:** Unknown, Healthy, Warning, Critical
- **3-State:** Healthy, Warning, Critical
- **Service:** Running, Stopped, Degraded, Unknown
- **Validation:** Valid, Missing, Misconfigured/Warning

### Future Enhancements

- Consider standardizing status values across all health monitoring scripts
- Potentially create shared constants for common status values
- Add validation functions to ensure only approved values are written

## Related Documentation

- [ACTION_PLAN_Field_Conversion_Documentation.md](./ACTION_PLAN_Field_Conversion_Documentation.md) - Master conversion plan
- Pre-Phase E: Date/Time Field Standards (Completed)
- Phase 2: WYSIWYG to Text+HTML (Pending)

---

**Last Updated:** February 3, 2026
