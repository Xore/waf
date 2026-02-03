# Date/Time Field Audit and Migration Plan

**Date:** February 3, 2026  
**Status:** In Progress  
**Priority:** High  
**Phase:** Pre-Phase E Implementation

---

## Executive Summary

This document audits all date/time data currently stored as text fields and provides a comprehensive migration plan to convert them to proper NinjaOne Date or Date/Time fields using Unix Epoch format. This ensures consistent date handling, proper sorting, filtering, and timezone management across the platform.

---

## Current State Analysis

### Scripts Using Date/Time Text Fields

From initial code search and analysis, the following scripts contain date/time formatting:

1. **Script_42_Active_Directory_Monitor.ps1**
   - Field: `ADPasswordLastSet`
   - Current Format: Text "yyyy-MM-dd HH:mm:ss"
   - Source: AD pwdLastSet (FileTime)
   - Migration: Convert to Date/Time field with Unix Epoch

2. **12_Baseline_Manager.ps1**
   - Likely contains timestamp fields
   - Needs detailed analysis

3. **Script_43_Group_Policy_Monitor.ps1**
   - Likely contains policy update timestamps
   - Needs detailed analysis

4. **Monitoring Scripts (scripts/monitoring/)**
   - Multiple scripts with timestamp tracking
   - Common pattern: lastChecked, lastRun, lastSuccess timestamps

### Common Date/Time Patterns Found

**Pattern 1: ToString with Format String**
```powershell
$pwdLastSetDate.ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
```

**Pattern 2: Get-Date with Format**
```powershell
Get-Date -Format "yyyy-MM-dd HH:mm:ss"
```

**Pattern 3: ISO 8601 String**
```powershell
$date.ToString("yyyy-MM-ddTHH:mm:ssZ")
```

---

## Migration Strategy

### Phase 1: Field Creation

**Action Items:**
1. Create Date/Time custom fields in NinjaOne for each timestamp field
2. Document field mappings (old text field to new Date/Time field)
3. Set proper field scopes and permissions

**Field Naming Convention:**
- Keep existing names where possible
- Append "Timestamp" if needed for clarity
- Use camelCase: `lastRunTimestamp`, `passwordLastSetTime`, `certificateExpiration`

### Phase 2: Code Pattern Migration

**Old Pattern (Text Field):**
```powershell
# BAD - Stores date as text string
$pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
$pwdLastSet = $pwdLastSetDate.ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
Ninja-Property-Set adPasswordLastSet $pwdLastSet
```

**New Pattern (Date/Time Field with Unix Epoch):**
```powershell
# GOOD - Stores date as Unix Epoch timestamp
$pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
$pwdTimestamp = [DateTimeOffset]$pwdLastSetDate | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set adPasswordLastSet $pwdTimestamp
Write-Host "INFO: Password last set: $($pwdLastSetDate.ToString('yyyy-MM-dd HH:mm:ss'))"
```

**Key Changes:**
1. Convert DateTime to Unix Epoch using `[DateTimeOffset]`
2. Store Unix Epoch integer in custom field
3. Keep human-readable logging for troubleshooting
4. No helper functions needed (inline conversion)

### Phase 3: Script-by-Script Migration

#### Script_42_Active_Directory_Monitor.ps1

**Current Implementation (Line ~198-209):**
```powershell
if ($computer['pwdLastSet'] -and $computer['pwdLastSet'][0]) {
    try {
        $pwdLastSetValue = $computer['pwdLastSet'][0]
        if ($pwdLastSetValue -is [System.__ComObject]) {
            $pwdLastSetValue = [Int64]$pwdLastSetValue
        }
        $pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
        $pwdLastSet = $pwdLastSetDate.ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
    } catch {
        Write-Host "WARNING: Failed to convert pwdLastSet - $($_.Exception.Message)"
    }
}
```

**Updated Implementation:**
```powershell
if ($computer['pwdLastSet'] -and $computer['pwdLastSet'][0]) {
    try {
        $pwdLastSetValue = $computer['pwdLastSet'][0]
        if ($pwdLastSetValue -is [System.__ComObject]) {
            $pwdLastSetValue = [Int64]$pwdLastSetValue
        }
        $pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
        $pwdLastSet = [DateTimeOffset]$pwdLastSetDate | Select-Object -ExpandProperty ToUnixTimeSeconds
        Write-Host "INFO: Password last set: $($pwdLastSetDate.ToString('yyyy-MM-dd HH:mm:ss'))"
    } catch {
        Write-Host "WARNING: Failed to convert pwdLastSet - $($_.Exception.Message)"
        $pwdLastSet = 0
    }
}
```

**Field Update (Line ~478):**
```powershell
# OLD
Ninja-Property-Set adPasswordLastSet $passwordLastSet  # Text: "yyyy-MM-dd HH:mm:ss"

# NEW
Ninja-Property-Set adPasswordLastSet $passwordLastSet  # Date/Time: Unix Epoch
```

**Documentation Update:**
```powershell
.FIELDS UPDATED
    - ADPasswordLastSet (Date/Time: Unix Epoch seconds since 1970-01-01 UTC)
```

---

## Implementation Checklist

### Script_42_Active_Directory_Monitor.ps1

- [ ] Create `ADPasswordLastSet` Date/Time field in NinjaOne
- [ ] Update line ~198-209: Convert pwdLastSet to Unix Epoch
- [ ] Update line ~478: Set Unix Epoch value to field
- [ ] Update script header documentation
- [ ] Update related documentation (docs/core/18_AD_Active_Directory.md)
- [ ] Test on domain-joined system
- [ ] Verify field display in NinjaOne dashboard
- [ ] Validate timezone handling
- [ ] Test on German and English Windows
- [ ] Document in PROGRESS_TRACKING.md

### Additional Scripts to Audit

- [ ] 12_Baseline_Manager.ps1 - Identify timestamp fields
- [ ] Script_43_Group_Policy_Monitor.ps1 - Identify policy timestamps
- [ ] Script_40_Network_Monitor.ps1 - Last check timestamps
- [ ] Script_44_Event_Log_Monitor.ps1 - Event timestamps
- [ ] Script_48_Veeam_Backup_Monitor.ps1 - Backup timestamps
- [ ] Script_02_DHCP_Server_Monitor.ps1 - DHCP timestamps
- [ ] 04_Event_Log_Monitor.ps1 - Event timestamps
- [ ] 16_Print_Server_Monitor.ps1 - Print job timestamps
- [ ] 31_Endpoint_Detection_Response.ps1 - Scan timestamps
- [ ] Script_39_MySQL_Server_Monitor.ps1 - Database timestamps
- [ ] Script_38_MSSQL_Server_Monitor.ps1 - Database timestamps
- [ ] 11_Network_Location_Tracker.ps1 - Location change timestamps
- [ ] 15_File_Server_Monitor.ps1 - File access timestamps
- [ ] 06_Print_Server_Monitor.ps1 - Print timestamps
- [ ] 03_Performance_Analyzer.ps1 - Analysis timestamps
- [ ] 29_Collaboration_Outlook_UX_Telemetry.ps1 - Telemetry timestamps
- [ ] 21_Battery_Health_Monitor.ps1 - Health check timestamps
- [ ] 01_Health_Score_Calculator.ps1 - Calculation timestamps

---

## Field Type Reference

### Date vs Date/Time Fields

**Use Date Field When:**
- Only date matters (no time component)
- Examples: warranty expiration, certificate expiration date, installation date
- Stores: Unix Epoch (midnight UTC of that date)

**Use Date/Time Field When:**
- Both date and time are relevant
- Examples: last run timestamp, last logon time, password last set
- Stores: Unix Epoch (exact second in UTC)

### Unix Epoch Conversion Examples

**Current Timestamp:**
```powershell
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
Ninja-Property-Set lastRunTimestamp $timestamp
```

**System Boot Time:**
```powershell
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBootTime = $os.LastBootUpTime
$bootTimestamp = [DateTimeOffset]$lastBootTime | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set systemLastBootTime $bootTimestamp
```

**AD FileTime Conversion:**
```powershell
$pwdLastSetValue = [Int64]$computer['pwdLastSet'][0]
$pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
$pwdTimestamp = [DateTimeOffset]$pwdLastSetDate | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set adPasswordLastSet $pwdTimestamp
```

**File Modification Time:**
```powershell
$file = Get-Item "C:\SomeFile.txt"
$modifiedTimestamp = [DateTimeOffset]$file.LastWriteTime | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set fileLastModified $modifiedTimestamp
```

---

## Testing Procedures

### Validation Steps

1. **Field Display Test**
   - Verify date displays correctly in NinjaOne dashboard
   - Check timezone handling (should show in user's local time)
   - Confirm proper date formatting

2. **Sorting Test**
   - Sort devices by date/time field
   - Verify chronological order
   - Compare with old text field sorting

3. **Filtering Test**
   - Filter by date range
   - Test relative date filters (last 7 days, etc.)
   - Verify accurate results

4. **Regional Settings Test**
   - Test on German Windows
   - Test on English Windows
   - Verify identical Unix Epoch values stored
   - Confirm display respects user's locale

5. **Edge Cases**
   - Test with null/empty dates
   - Test with very old dates (1970s)
   - Test with future dates
   - Test with daylight saving time transitions

---

## Documentation Updates Required

### Script Headers

Update `.FIELDS UPDATED` section to document Unix Epoch format:

```powershell
.FIELDS UPDATED
    - lastRunTimestamp (Date/Time: Unix Epoch seconds since 1970-01-01 UTC)
    - certificateExpiration (Date: Unix Epoch seconds, date only)
    - adPasswordLastSet (Date/Time: Unix Epoch seconds from AD FileTime)
```

### Documentation Files

Update these documentation files:

1. **docs/core/18_AD_Active_Directory.md**
   - Document ADPasswordLastSet as Date/Time field
   - Add Unix Epoch conversion example

2. **docs/ACTION_PLAN_Field_Conversion_Documentation.md**
   - Mark Pre-Phase E as complete when done
   - Update change log

3. **docs/PROGRESS_TRACKING.md**
   - Track progress on date/time field migrations
   - Document completion status per script

4. **Script-specific documentation (docs/scripts/)**
   - Update field type documentation
   - Add Unix Epoch format notes

---

## Benefits of Unix Epoch Format

### Technical Benefits

1. **Universal Format**
   - Language-neutral (numeric value)
   - No locale-specific issues
   - Works identically worldwide

2. **Timezone Management**
   - Storage in UTC (Unix Epoch)
   - Display in user's local timezone (NinjaOne handles conversion)
   - No timezone confusion

3. **Sorting and Filtering**
   - Numeric comparison (fast and accurate)
   - Proper chronological ordering
   - Native date range filtering

4. **Data Integrity**
   - No date format ambiguity (MM/DD vs DD/MM)
   - Consistent across German and English Windows
   - No parsing errors

### Operational Benefits

1. **Better Reporting**
   - Accurate date-based analytics
   - Proper trend analysis
   - Reliable aging calculations

2. **Improved Alerting**
   - Age-based conditions work correctly
   - Date comparison conditions reliable
   - No string parsing in alert rules

3. **User Experience**
   - Dates display in user's preferred format
   - Automatic timezone adjustment
   - Consistent appearance across devices

---

## Migration Schedule

### Week 1: Foundation
- [ ] Complete this audit document
- [ ] Analyze all scripts for date/time patterns
- [ ] Create comprehensive field mapping
- [ ] Create Date/Time custom fields in NinjaOne

### Week 2: High-Priority Scripts
- [ ] Migrate Script_42_Active_Directory_Monitor.ps1
- [ ] Migrate backup monitoring scripts
- [ ] Migrate certificate monitoring scripts
- [ ] Update related documentation

### Week 3: Monitoring Scripts
- [ ] Migrate all scripts in scripts/monitoring/
- [ ] Test timezone handling
- [ ] Validate German/English compatibility

### Week 4: Remaining Scripts
- [ ] Migrate remaining scripts with timestamps
- [ ] Final validation and testing
- [ ] Complete documentation updates
- [ ] Mark Pre-Phase E as complete

---

## Success Criteria

### Technical Requirements
- [ ] All timestamp data stored as Unix Epoch
- [ ] No date/time values stored as text strings
- [ ] All scripts use inline DateTimeOffset conversion
- [ ] Human-readable logging preserved
- [ ] No helper functions needed for conversion

### Documentation Requirements
- [ ] All script headers updated with Unix Epoch format notes
- [ ] Field type documented in `.FIELDS UPDATED` sections
- [ ] Related documentation updated
- [ ] Examples added to all date/time fields

### Testing Requirements
- [ ] All scripts tested on domain-joined systems
- [ ] Timezone handling validated
- [ ] German Windows compatibility confirmed
- [ ] English Windows compatibility confirmed
- [ ] NinjaOne dashboard display verified
- [ ] Sorting and filtering tested

---

## Next Steps

1. **Immediate Actions:**
   - Analyze 12_Baseline_Manager.ps1 for timestamp fields
   - Analyze Script_43_Group_Policy_Monitor.ps1 for timestamp fields
   - Create field mapping document

2. **This Week:**
   - Create Date/Time custom fields in NinjaOne
   - Migrate Script_42_Active_Directory_Monitor.ps1
   - Test and validate migration

3. **Next Week:**
   - Begin monitoring scripts migration
   - Update documentation
   - Continue systematic migration

---

## References

- **ACTION_PLAN_Field_Conversion_Documentation.md** - Pre-Phase E documentation
- **PROGRESS_TRACKING.md** - Overall project tracking
- **NinjaOne Documentation** - Date/Time field specifications
- **PowerShell DateTimeOffset Documentation** - .NET conversion methods

---

## Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-03 | 1.0 | WAF Team | Initial date/time field audit created |

---

**END OF DATE/TIME FIELD AUDIT**
