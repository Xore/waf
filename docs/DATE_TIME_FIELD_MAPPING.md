# Date/Time Field Mapping for Unix Epoch Migration

**Date:** February 3, 2026  
**Status:** Analysis Complete  
**Phase:** Pre-Phase E Implementation

---

## Executive Summary

This document provides a comprehensive mapping of all date/time fields currently stored as text that need to be migrated to Unix Epoch format. Analysis identified 4 scripts with date/time text fields requiring migration.

---

## Identified Date/Time Fields

### Script_42_Active_Directory_Monitor.ps1

**Field:** `ADPasswordLastSet`
- **Current Type:** Text
- **Current Format:** "yyyy-MM-dd HH:mm:ss"
- **Source Data:** AD pwdLastSet (FileTime format)
- **Target Type:** Date/Time (Unix Epoch)
- **Migration Priority:** HIGH
- **Code Location:** Line ~198-209 (conversion), Line ~478 (field set)

**Current Implementation:**
```powershell
$pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
$pwdLastSet = $pwdLastSetDate.ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
Ninja-Property-Set adPasswordLastSet $pwdLastSet
```

**Target Implementation:**
```powershell
$pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
$pwdTimestamp = [DateTimeOffset]$pwdLastSetDate | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set adPasswordLastSet $pwdTimestamp
Write-Host "INFO: Password last set: $($pwdLastSetDate.ToString('yyyy-MM-dd HH:mm:ss'))"
```

---

### 12_Baseline_Manager.ps1

**Field:** `BASEPerformanceBaseline.Timestamp` (embedded in JSON)
- **Current Type:** Text (within JSON object)
- **Current Format:** "yyyy-MM-dd HH:mm:ss"
- **Source Data:** Current date/time
- **Target Type:** Should extract to separate Date/Time field
- **Migration Priority:** MEDIUM
- **Code Location:** Line ~23

**Current Implementation:**
```powershell
$baseline = @{
    CPU = [math]::Round($cpuUtilization, 2)
    Memory = $memUtilization
    DiskFree = $diskFreePercent
    Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}
$baselineJson = $baseline | ConvertTo-Json -Compress
Ninja-Property-Set BASEPerformanceBaseline $baselineJson
```

**Target Implementation:**
```powershell
$baseline = @{
    CPU = [math]::Round($cpuUtilization, 2)
    Memory = $memUtilization
    DiskFree = $diskFreePercent
}
$baselineJson = $baseline | ConvertTo-Json -Compress
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()

Ninja-Property-Set BASEPerformanceBaseline $baselineJson
Ninja-Property-Set BASELastUpdated $timestamp  # New separate Date/Time field
Write-Host "INFO: Baseline updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
```

**Recommendation:** Create separate `BASELastUpdated` Date/Time field instead of embedding timestamp in JSON.

---

### Script_43_Group_Policy_Monitor.ps1

**Field:** `GPOLastApplied`
- **Current Type:** DateTime (checkbox field - needs verification)
- **Current Format:** "yyyy-MM-dd HH:mm:ss"
- **Source Data:** GP ReadTime or LastGPOProcessingTime
- **Target Type:** Date/Time (Unix Epoch)
- **Migration Priority:** HIGH
- **Code Location:** Line ~85, Line ~153

**Current Implementation (Method 1 - gpresult):**
```powershell
$readTime = $gpoReport.Rsop.ReadTime
if ($readTime) {
    $lastAppliedDate = [DateTime]::Parse($readTime)
    $lastApplied = $lastAppliedDate.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "Last Applied: $lastApplied"
}
```

**Current Implementation (Method 2 - registry):**
```powershell
$lastGPUpdate = $gpoState.LastGPOProcessingTime
if ($lastGPUpdate) {
    $lastApplied = ([DateTime]::Parse($lastGPUpdate)).ToString("yyyy-MM-dd HH:mm:ss")
    $gpoApplied = $true
}
```

**Target Implementation:**
```powershell
# Method 1 - gpresult
$readTime = $gpoReport.Rsop.ReadTime
if ($readTime) {
    $lastAppliedDate = [DateTime]::Parse($readTime)
    $lastApplied = [DateTimeOffset]$lastAppliedDate | Select-Object -ExpandProperty ToUnixTimeSeconds
    Write-Host "INFO: Last Applied: $($lastAppliedDate.ToString('yyyy-MM-dd HH:mm:ss'))"
}

# Method 2 - registry
$lastGPUpdate = $gpoState.LastGPOProcessingTime
if ($lastGPUpdate) {
    $lastAppliedDate = [DateTime]::Parse($lastGPUpdate)
    $lastApplied = [DateTimeOffset]$lastAppliedDate | Select-Object -ExpandProperty ToUnixTimeSeconds
    $gpoApplied = $true
    Write-Host "INFO: Last Applied: $($lastAppliedDate.ToString('yyyy-MM-dd HH:mm:ss'))"
}
```

---

### Script_41_Battery_Health_Monitor.ps1

**Note:** Search indicated this script contains date formatting, but needs detailed analysis to identify specific fields.

**Action Required:** Analyze script for date/time field usage.

---

## Migration Priority Matrix

| Script | Field | Priority | Complexity | Estimated Time |
|--------|-------|----------|------------|----------------|
| Script_42 | ADPasswordLastSet | HIGH | Low | 15 min |
| Script_43 | GPOLastApplied | HIGH | Low | 15 min |
| 12_Baseline | BASELastUpdated | MEDIUM | Medium | 30 min |
| Script_41 | TBD | TBD | TBD | TBD |

**Total Estimated Migration Time:** 1-2 hours for identified fields

---

## NinjaOne Field Creation Checklist

### Fields to Create

- [ ] **ADPasswordLastSet** (Date/Time)
  - Label: "AD Password Last Set"
  - Type: Date and Time
  - Scope: Device
  - Description: "Active Directory computer account password last set time (Unix Epoch)"

- [ ] **GPOLastApplied** (Date/Time)
  - Label: "GPO Last Applied"
  - Type: Date and Time
  - Scope: Device
  - Description: "Group Policy last application time (Unix Epoch)"

- [ ] **BASELastUpdated** (Date/Time)
  - Label: "Baseline Last Updated"
  - Type: Date and Time
  - Scope: Device
  - Description: "Performance baseline last update time (Unix Epoch)"

---

## Migration Sequence

### Phase 1: High-Priority Fields (Week 1)

**Day 1: Script_42 Migration**
- [ ] Create ADPasswordLastSet Date/Time field in NinjaOne
- [ ] Update Script_42 code (lines ~198-209, ~478)
- [ ] Update script header documentation
- [ ] Test on domain-joined system
- [ ] Verify field display in NinjaOne
- [ ] Validate timezone handling
- [ ] Document in PROGRESS_TRACKING.md

**Day 2: Script_43 Migration**
- [ ] Create GPOLastApplied Date/Time field in NinjaOne
- [ ] Update Script_43 code (lines ~85, ~153)
- [ ] Update script header documentation
- [ ] Test on domain-joined system
- [ ] Verify field display in NinjaOne
- [ ] Document in PROGRESS_TRACKING.md

### Phase 2: Medium-Priority Fields (Week 1-2)

**Day 3: 12_Baseline Manager**
- [ ] Create BASELastUpdated Date/Time field in NinjaOne
- [ ] Refactor baseline JSON (remove Timestamp property)
- [ ] Add separate timestamp field set
- [ ] Update script header documentation
- [ ] Test baseline tracking
- [ ] Document in PROGRESS_TRACKING.md

### Phase 3: Remaining Scripts (Week 2)

**Day 4-5: Audit and Migrate Remaining**
- [ ] Analyze Script_41_Battery_Health_Monitor.ps1
- [ ] Search for additional date/time patterns
- [ ] Create any additional Date/Time fields needed
- [ ] Migrate remaining scripts
- [ ] Complete testing and validation

---

## Code Pattern Reference

### Pattern 1: Current DateTime

**OLD:**
```powershell
$timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
Ninja-Property-Set someField $timestamp
```

**NEW:**
```powershell
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
Ninja-Property-Set someField $timestamp
Write-Host "INFO: Updated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
```

### Pattern 2: Parse DateTime String

**OLD:**
```powershell
$dateTime = [DateTime]::Parse($dateString)
$formatted = $dateTime.ToString("yyyy-MM-dd HH:mm:ss")
Ninja-Property-Set someField $formatted
```

**NEW:**
```powershell
$dateTime = [DateTime]::Parse($dateString)
$timestamp = [DateTimeOffset]$dateTime | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set someField $timestamp
Write-Host "INFO: Date/Time: $($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
```

### Pattern 3: FileTime Conversion (AD)

**OLD:**
```powershell
$fileTime = [Int64]$adProperty[0]
$dateTime = [DateTime]::FromFileTime($fileTime)
$formatted = $dateTime.ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
Ninja-Property-Set someField $formatted
```

**NEW:**
```powershell
$fileTime = [Int64]$adProperty[0]
$dateTime = [DateTime]::FromFileTime($fileTime)
$timestamp = [DateTimeOffset]$dateTime | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set someField $timestamp
Write-Host "INFO: Date/Time: $($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
```

### Pattern 4: CIM DateTime

**OLD:**
```powershell
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$formatted = $bootTime.ToString("yyyy-MM-dd HH:mm:ss")
Ninja-Property-Set systemLastBoot $formatted
```

**NEW:**
```powershell
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$timestamp = [DateTimeOffset]$bootTime | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set systemLastBoot $timestamp
Write-Host "INFO: Last boot: $($bootTime.ToString('yyyy-MM-dd HH:mm:ss'))"
```

---

## Testing Validation Matrix

| Test | Script_42 | Script_43 | 12_Baseline | Status |
|------|-----------|-----------|-------------|--------|
| Field Creation | [ ] | [ ] | [ ] | Pending |
| Code Update | [ ] | [ ] | [ ] | Pending |
| Unit Test | [ ] | [ ] | [ ] | Pending |
| Display Test | [ ] | [ ] | [ ] | Pending |
| Sorting Test | [ ] | [ ] | [ ] | Pending |
| Filter Test | [ ] | [ ] | [ ] | Pending |
| German Windows | [ ] | [ ] | [ ] | Pending |
| English Windows | [ ] | [ ] | [ ] | Pending |
| Timezone Test | [ ] | [ ] | [ ] | Pending |
| Documentation | [ ] | [ ] | [ ] | Pending |

---

## Documentation Updates Required

### Per-Script Updates

**Script_42_Active_Directory_Monitor.ps1:**
- Update `.FIELDS UPDATED` section
- Change ADPasswordLastSet from "Text: ISO 8601 format" to "Date/Time: Unix Epoch seconds"
- Update related docs: `docs/core/18_AD_Active_Directory.md`

**Script_43_Group_Policy_Monitor.ps1:**
- Update `.FIELDS UPDATED` section
- Change GPOLastApplied from "DateTime" to "Date/Time: Unix Epoch seconds"
- Update related docs: `docs/core/17_GPO_Group_Policy.md`

**12_Baseline_Manager.ps1:**
- Add new field to `.FIELDS UPDATED` section
- Add BASELastUpdated as "Date/Time: Unix Epoch seconds"
- Update related docs (if any)

### Global Updates

- [ ] Update `docs/ACTION_PLAN_Field_Conversion_Documentation.md`
  - Mark Pre-Phase E scripts as complete
  - Update change log

- [ ] Update `docs/PROGRESS_TRACKING.md`
  - Track completion status per script
  - Update time estimates

- [ ] Update `docs/DATE_TIME_FIELD_AUDIT.md`
  - Mark completed migrations
  - Update success criteria

---

## Known Issues and Considerations

### Script_43 Field Type Confusion

**Issue:** Script_43 header documents `GPOLastApplied` as "DateTime" field type, but NinjaOne may have this as Text or Checkbox.

**Resolution Required:** Verify actual field type in NinjaOne and determine if:
1. Field already exists as proper DateTime field (no migration needed)
2. Field exists as Text (needs migration to Unix Epoch)
3. Field exists as Checkbox (incorrect type, needs recreation)

**Action:** Check NinjaOne field configuration before migration.

### Baseline Manager JSON Structure

**Issue:** Current implementation embeds timestamp inside JSON object, which is not ideal for sorting/filtering.

**Recommendation:** Extract timestamp to separate field for proper date/time handling.

**Impact:** Requires creating new field and updating script logic, but improves data structure.

---

## Success Criteria

### Technical Requirements
- [ ] All identified date/time text fields migrated to Unix Epoch
- [ ] No date/time values stored as formatted strings
- [ ] All scripts use inline DateTimeOffset conversion
- [ ] Human-readable logging preserved in all scripts
- [ ] No helper functions needed (inline only)

### Testing Requirements
- [ ] All scripts tested on domain-joined systems
- [ ] Timezone handling validated (UTC storage, local display)
- [ ] German Windows compatibility confirmed
- [ ] English Windows compatibility confirmed
- [ ] NinjaOne dashboard display verified
- [ ] Sorting by date fields works correctly
- [ ] Filtering by date range works correctly

### Documentation Requirements
- [ ] All script headers updated with Unix Epoch format
- [ ] Field types documented in `.FIELDS UPDATED` sections
- [ ] Related documentation files updated
- [ ] DATE_TIME_FIELD_AUDIT.md marked complete
- [ ] PROGRESS_TRACKING.md updated

---

## Next Actions

1. **Immediate (Today):**
   - Create ADPasswordLastSet Date/Time field in NinjaOne
   - Migrate Script_42 code
   - Test and validate

2. **This Week:**
   - Create GPOLastApplied Date/Time field
   - Migrate Script_43 code
   - Create BASELastUpdated Date/Time field
   - Migrate 12_Baseline_Manager.ps1

3. **Next Week:**
   - Analyze Script_41 and any other scripts
   - Complete remaining migrations
   - Finalize testing and documentation

---

## References

- **DATE_TIME_FIELD_AUDIT.md** - Audit document and strategy
- **ACTION_PLAN_Field_Conversion_Documentation.md** - Pre-Phase E requirements
- **PROGRESS_TRACKING.md** - Overall project status
- **Script source files** - Current implementations

---

## Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-03 | 1.0 | WAF Team | Initial field mapping created |

---

**END OF DATE/TIME FIELD MAPPING**
