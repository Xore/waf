# WAF Field Type Conversion & Documentation Completeness Plan

**Date:** February 3, 2026  
**Status:** Planning Phase  
**Priority:** High

---

## Executive Summary

This plan outlines the systematic conversion of all dropdown custom fields to text fields and ensures complete documentation coverage for all 48+ scripts in the Windows Automation Framework. The goal is to eliminate dropdown field dependencies, reduce RSAT and non-native PowerShell module dependencies, migrate Active Directory queries to ADSI LDAP:// queries exclusively, standardize data encoding with Base64, use proper Date/Time fields with Unix Epoch format, ensure language compatibility (German/English Windows), and create a comprehensive documentation suite following consistent style guidelines and coding standards.

---

[Pre-Phase A through D sections remain unchanged - content from current version]

## Pre-Phase E: Date/Time Field Standards (Unix Epoch Format)

### Objective
Standardize all date and time data to use NinjaOne **Date** or **Date and Time** custom field types with proper Unix Epoch formatting instead of text fields. This ensures consistent date handling, proper sorting, filtering, and display across the NinjaOne platform.

### Why Use Date/Time Fields

**Benefits:**
- Proper sorting and filtering in NinjaOne dashboard
- Consistent date display across different regional settings
- Better reporting and analytics capabilities
- Automatic timezone handling
- Native date comparison operators
- ISO 8601 compliance for international teams
- Prevents date format ambiguity (MM/DD vs DD/MM)

**When to Use:**
- Timestamps (last run, last updated, last checked)
- System dates (installation date, last boot time, password last set)
- Event dates (last logon, certificate expiration, warranty expiration)
- Monitoring intervals (next scheduled check, last success/failure)
- Any date/time value that needs sorting or comparison

### NinjaOne Date/Time Field Format

**CRITICAL:** NinjaOne expects date/time values as **Unix Epoch timestamps** (seconds since January 1, 1970 00:00:00 UTC)

**Field Types:**
1. **Date** - Stores date only (no time component)
2. **Date and Time** - Stores both date and time with timezone

**Required Format:** Unix Epoch as integer (seconds since 1970-01-01 00:00:00 UTC)

### Implementation Pattern

**Convert DateTime to Unix Epoch for NinjaOne:**

```powershell
# Helper function to convert DateTime to Unix Epoch (seconds)
function ConvertTo-UnixEpoch {
    <#
    .SYNOPSIS
        Convert DateTime object to Unix Epoch seconds for NinjaOne date fields
    .DESCRIPTION
        NinjaOne Date and Date/Time fields require Unix Epoch format (seconds since 1970-01-01 UTC)
    .PARAMETER DateTime
        DateTime object to convert. Can be from Get-Date, file timestamps, AD attributes, etc.
    .EXAMPLE
        $unixTime = ConvertTo-UnixEpoch -DateTime (Get-Date)
        Ninja-Property-Set lastChecked $unixTime
    #>
    param(
        [Parameter(Mandatory=$true)]
        [DateTime]$DateTime
    )
    
    try {
        # Convert to UTC to ensure consistent timezone handling
        $utcDate = $DateTime.ToUniversalTime()
        
        # Calculate seconds since Unix Epoch (1970-01-01 00:00:00 UTC)
        $epoch = Get-Date "1970-01-01 00:00:00"
        $timeSpan = New-TimeSpan -Start $epoch -End $utcDate
        $unixSeconds = [Math]::Floor($timeSpan.TotalSeconds)
        
        Write-Host "INFO: Converted $DateTime to Unix Epoch: $unixSeconds"
        return $unixSeconds
    } catch {
        Write-Host "ERROR: Failed to convert DateTime to Unix Epoch - $($_.Exception.Message)"
        return $null
    }
}
```

**Convert Unix Epoch back to DateTime (for display/logging):**

```powershell
# Helper function to convert Unix Epoch back to DateTime
function ConvertFrom-UnixEpoch {
    <#
    .SYNOPSIS
        Convert Unix Epoch seconds back to DateTime object
    .PARAMETER UnixSeconds
        Unix Epoch timestamp (seconds since 1970-01-01 UTC)
    .EXAMPLE
        $dateTime = ConvertFrom-UnixEpoch -UnixSeconds 1738548000
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int64]$UnixSeconds
    )
    
    try {
        $epoch = Get-Date "1970-01-01 00:00:00"
        $dateTime = $epoch.AddSeconds($UnixSeconds)
        return $dateTime
    } catch {
        Write-Host "ERROR: Failed to convert Unix Epoch to DateTime - $($_.Exception.Message)"
        return $null
    }
}
```

### Common Date/Time Scenarios

**1. Current Timestamp (Last Run/Last Checked):**

```powershell
# Store current date/time
$currentTimestamp = ConvertTo-UnixEpoch -DateTime (Get-Date)
Ninja-Property-Set lastRunTimestamp $currentTimestamp
Write-Host "INFO: Script last run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
```

**2. System Boot Time:**

```powershell
# Get last boot time from WMI/CIM
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBootTime = $os.LastBootUpTime

if ($lastBootTime) {
    $bootTimestamp = ConvertTo-UnixEpoch -DateTime $lastBootTime
    Ninja-Property-Set systemLastBootTime $bootTimestamp
    Write-Host "INFO: System last boot: $($lastBootTime.ToString('yyyy-MM-dd HH:mm:ss'))"
}
```

**3. File Modification Time:**

```powershell
# Get file last modified time
$file = Get-Item "C:\SomeFile.txt" -ErrorAction SilentlyContinue
if ($file) {
    $modifiedTimestamp = ConvertTo-UnixEpoch -DateTime $file.LastWriteTime
    Ninja-Property-Set configFileLastModified $modifiedTimestamp
    Write-Host "INFO: File modified: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
}
```

**4. Active Directory pwdLastSet (Password Last Set):**

```powershell
# Convert AD FileTime to DateTime, then to Unix Epoch
if ($computer['pwdLastSet'] -and $computer['pwdLastSet'][0]) {
    try {
        # AD stores as FileTime (100-nanosecond intervals since 1601-01-01)
        $pwdLastSetValue = [Int64]$computer['pwdLastSet'][0]
        $pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
        
        # Convert to Unix Epoch for NinjaOne
        $pwdTimestamp = ConvertTo-UnixEpoch -DateTime $pwdLastSetDate
        Ninja-Property-Set adPasswordLastSet $pwdTimestamp
        
        Write-Host "INFO: Password last set: $($pwdLastSetDate.ToString('yyyy-MM-dd HH:mm:ss'))"
    } catch {
        Write-Host "ERROR: Failed to convert pwdLastSet - $($_.Exception.Message)"
    }
}
```

**5. Certificate Expiration Date:**

```powershell
# Get certificate expiration
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match "CN=MyCert" } | Select-Object -First 1

if ($cert) {
    $expirationTimestamp = ConvertTo-UnixEpoch -DateTime $cert.NotAfter
    Ninja-Property-Set certificateExpiration $expirationTimestamp
    
    # Calculate days until expiration for alerting
    $daysUntilExpiration = ($cert.NotAfter - (Get-Date)).Days
    Ninja-Property-Set certificateExpirationDays $daysUntilExpiration
    
    Write-Host "INFO: Certificate expires: $($cert.NotAfter.ToString('yyyy-MM-dd'))"
    Write-Host "INFO: Days until expiration: $daysUntilExpiration"
}
```

**6. Scheduled Task Next Run Time:**

```powershell
# Get scheduled task next run time
$task = Get-ScheduledTask -TaskName "MyTask" -ErrorAction SilentlyContinue
if ($task) {
    $taskInfo = Get-ScheduledTaskInfo -TaskName "MyTask"
    $nextRunTime = $taskInfo.NextRunTime
    
    if ($nextRunTime) {
        $nextRunTimestamp = ConvertTo-UnixEpoch -DateTime $nextRunTime
        Ninja-Property-Set taskNextRunTime $nextRunTimestamp
        Write-Host "INFO: Task next run: $($nextRunTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    }
}
```

### Date vs Text Field Comparison

**BAD - Using Text Field:**
```powershell
# Text field - inconsistent format, poor sorting, no timezone handling
$dateString = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Ninja-Property-Set lastChecked $dateString
# Issues: String comparison, locale problems, no timezone awareness
```

**GOOD - Using Date/Time Field:**
```powershell
# Date/Time field - proper format, correct sorting, timezone aware
$timestamp = ConvertTo-UnixEpoch -DateTime (Get-Date)
Ninja-Property-Set lastChecked $timestamp
# Benefits: Numeric comparison, universal format, automatic timezone handling
```

### Field Creation in NinjaOne

**Creating Date Custom Field:**
1. Go to Administration → Devices → Global Custom Fields
2. Click Add → Field
3. Select **Date** or **Date and Time** from Custom field type dropdown
4. Enter Label (e.g., "Last Boot Time", "Certificate Expiration")
5. Set Definition Scope to Device
6. Leave Filter Date Options as None (unless specific filtering needed)
7. Click Create

**Field Naming Convention:**
- Use descriptive names: `lastBootTime`, `certificateExpiration`, `passwordLastSet`
- Include context: `adPasswordLastSet`, `backupLastSuccess`, `updateLastChecked`
- Use camelCase for field names in scripts

### Migration Strategy

**Identify Text Fields Storing Dates:**
Search for patterns in existing scripts:
- `ToString("yyyy-MM-dd")`
- `Get-Date -Format`
- Fields ending in "Date", "Time", "Timestamp", "LastRun", "LastChecked"
- ISO 8601 format strings

**Convert to Date/Time Fields:**

1. **Audit Current Fields:**
   - List all custom fields storing date/time as text
   - Document current format used
   - Identify scripts writing to these fields

2. **Create New Date/Time Fields:**
   - Create Date or Date/Time field in NinjaOne
   - Use same name or append "Timestamp" to distinguish
   - Set to Device scope

3. **Update Scripts:**
   - Add `ConvertTo-UnixEpoch` helper function
   - Replace text field writes with Unix Epoch conversion
   - Keep human-readable logging for troubleshooting

4. **Test and Validate:**
   - Verify date displays correctly in NinjaOne dashboard
   - Test sorting and filtering
   - Confirm timezone handling
   - Validate on both German and English Windows

5. **Document Changes:**
   - Update script documentation
   - Note Unix Epoch requirement
   - Document field types in script headers
   - Add examples in comments

### Language Compatibility

**Unix Epoch Benefits:**
- Language-neutral (numeric value)
- No locale-specific formatting issues
- Works identically on German and English Windows
- No date format ambiguity (MM/DD/YYYY vs DD/MM/YYYY)
- Timezone-agnostic (always UTC-based)

**Regional Settings:**
NinjaOne handles display formatting based on user preferences, but storage format (Unix Epoch) remains consistent.

### Scripts to Update

**Priority Scripts (Date/Time Fields Recommended):**

1. **Script_42_Active_Directory_Monitor.ps1**
   - `adPasswordLastSet` (currently text) → Date/Time field
   - Already has pwdLastSet from LDAP, needs Unix Epoch conversion

2. **Script_01_System_Information_Monitor.ps1**
   - `systemLastBootTime` → Date/Time field
   - `osInstallDate` → Date field

3. **Backup Monitoring Scripts**
   - `backupLastSuccess` → Date/Time field
   - `backupLastFailure` → Date/Time field
   - `backupNextScheduled` → Date/Time field

4. **Certificate Monitoring Scripts**
   - `certificateExpiration` → Date field
   - `certificateIssueDate` → Date field

5. **Update/Patch Scripts**
   - `lastUpdateCheck` → Date/Time field
   - `lastPatchInstalled` → Date/Time field

6. **Antivirus/Security Scripts**
   - `avLastScan` → Date/Time field
   - `avDefinitionDate` → Date/Time field

7. **Script Execution Tracking**
   - All scripts should track `lastRunTimestamp` → Date/Time field

### Error Handling

```powershell
# Always validate DateTime before conversion
function Set-DateField {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$false)]
        [DateTime]$DateTime
    )
    
    if ($null -eq $DateTime) {
        Write-Host "WARNING: DateTime is null, skipping field $FieldName"
        return
    }
    
    try {
        $timestamp = ConvertTo-UnixEpoch -DateTime $DateTime
        if ($null -ne $timestamp) {
            Ninja-Property-Set $FieldName $timestamp
            Write-Host "SUCCESS: Set $FieldName to $($DateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        } else {
            Write-Host "ERROR: Failed to convert DateTime for field $FieldName"
        }
    } catch {
        Write-Host "ERROR: Failed to set date field $FieldName - $($_.Exception.Message)"
    }
}
```

### Testing and Validation

**Test Cases:**

1. **Current Date/Time:**
   - Store `Get-Date` as Unix Epoch
   - Verify displays correctly in NinjaOne

2. **Historical Dates:**
   - Test with dates in the past (last boot time, password set date)
   - Verify correct conversion and display

3. **Future Dates:**
   - Test with future dates (certificate expiration, scheduled tasks)
   - Verify correct calculation and display

4. **Timezone Handling:**
   - Test on systems in different timezones
   - Verify UTC conversion is correct

5. **Regional Settings:**
   - Test on German Windows (date format DD.MM.YYYY)
   - Test on English Windows (date format MM/DD/YYYY)
   - Verify NinjaOne displays correctly regardless of system locale

6. **Null Handling:**
   - Test with null/empty dates
   - Verify graceful error handling

### Documentation Requirements

**Script Header Documentation:**
```powershell
<#
.FIELDS UPDATED
    - lastBootTime (Date/Time: Unix Epoch seconds since 1970-01-01 UTC)
    - certificateExpiration (Date: Unix Epoch seconds, date only)
    - passwordLastSet (Date/Time: Unix Epoch seconds)
    
.NOTES
    Date/Time fields use Unix Epoch format (seconds since 1970-01-01 00:00:00 UTC)
    NinjaOne handles timezone display automatically based on user preferences
#>
```

**Helper Function Documentation:**
Include `ConvertTo-UnixEpoch` and `ConvertFrom-UnixEpoch` functions in all scripts using Date/Time fields with full documentation.

---

## Phase 0: Coding Standards and Conventions

### Additional Coding Standards

**Date/Time Field Usage:**
- Always use Date or Date/Time custom fields for temporal data (not text)
- Always convert DateTime to Unix Epoch seconds before storing
- Always use UTC for consistency (`ToUniversalTime()`)
- Always include `ConvertTo-UnixEpoch` helper function in scripts
- Always validate DateTime is not null before conversion
- Always log human-readable dates for troubleshooting
- Document field types in script header FIELDS UPDATED section
- Include "Unix Epoch" in field documentation

**ADSI LDAP:// Protocol Usage:**
- Always use LDAP:// protocol for all Active Directory queries
- Never use WinNT:// for AD queries (local accounts only)
- Never use GC:// unless specifically needed for global catalog
- Set SearchScope explicitly to Subtree for domain-wide queries
- Use specific LDAP filters with objectClass and objectCategory
- Request only needed attributes via PropertiesToLoad
- Always check for null/empty before accessing LDAP properties

**Base64 Encoding Usage:**
- Always use Base64 encoding for complex data structures (arrays, hashtables, nested objects)
- Always validate encoded data does not exceed 9999 characters
- Always include `ConvertTo-Base64` and `ConvertFrom-Base64` helper functions
- Log encoded data size for monitoring
- Return null and log error if size limit exceeded

[Continue with rest of coding standards]

---

## Execution Sequence

### Recommended Implementation Order

**Week 0: Pre-Implementation (CRITICAL)**

1. **Pre-Phase A: Active Directory ADSI Migration (LDAP:// Only)**
   - Implement Test-ADConnection function (LDAP:// only)
   - Create Get-ADUserViaADSI function (LDAP:// only)
   - Create Get-ADComputerViaADSI function (LDAP:// only)
   - Create Get-ADGroupViaADSI function (LDAP:// only)
   - Update Script_42_Active_Directory_Monitor.ps1
   - Verify all ADSI queries use LDAP:// protocol
   - Test on domain-joined and workgroup systems
   - Document LDAP:// approach

2. **Pre-Phase B: Module Dependency Reduction**
   - Audit all Import-Module statements
   - Identify RSAT modules to replace
   - Keep native Windows modules (Storage, BitLocker, etc.)
   - Document which modules retained and why

3. **Pre-Phase C: Base64 Encoding Standard** (COMPLETE)
   - Implement ConvertTo-Base64 helper with 9999 char limit
   - Implement ConvertFrom-Base64 helper
   - Update Script_42, Script_10, Script_11 with Base64 encoding
   - Test with complex data structures
   - Verify special character handling

4. **Pre-Phase D: Language Compatibility**
   - Test all scripts on German Windows
   - Test all scripts on English Windows
   - Verify no hardcoded language-specific strings
   - Document language-neutral approaches

5. **Pre-Phase E: Date/Time Field Standards** (NEW)
   - Create ConvertTo-UnixEpoch helper function
   - Create ConvertFrom-UnixEpoch helper function
   - Audit all scripts storing dates as text
   - Create Date/Time custom fields in NinjaOne
   - Update scripts to use Unix Epoch format
   - Test timezone handling and display
   - Verify German/English Windows compatibility
   - Document Unix Epoch requirement

[Continue with rest of execution sequence]

---

## Success Criteria

### Project Complete When

**Technical Requirements:**
- All dropdown field references converted to text
- All AD queries migrated to ADSI using LDAP:// protocol exclusively
- No WinNT:// or GC:// protocols used for AD queries
- RSAT module dependencies eliminated (native modules retained)
- All complex data storage uses Base64 encoding
- **All date/time data uses Date or Date/Time fields with Unix Epoch format**
- **All scripts include ConvertTo-UnixEpoch helper function where needed**
- All scripts tested and working on German Windows
- All scripts tested and working on English Windows
- No language-dependent code remains
- All scripts function correctly with text fields
- No breaking changes to existing deployments
- All automated tests passing
- All scripts use Write-Host exclusively
- AD connectivity validated before LDAP queries
- Scripts use native Windows modules appropriately

**Documentation Requirements:**
- Every script has corresponding documentation
- ADSI LDAP:// implementation documented with examples
- LDAP:// protocol requirement clearly stated
- Native module usage documented (why kept)
- RSAT module replacements documented
- Base64 encoding documented with examples
- **Unix Epoch date/time format documented with examples**
- **DATE_TIME_FIELD_REPORT.md complete**
- BASE64_ENCODING_REPORT.md complete
- Language compatibility documented for each script
- LANGUAGE_COMPATIBILITY_REPORT.md complete
- All compound conditions documented with THREE representations
- All diagrams reflect current state
- Complete index and reference suite exists
- 100% documentation coverage verified
- All quality checks passed
- Zero unresolved TBD items
- MODULE_DEPENDENCY_REPORT.md complete and accurate

**Quality Requirements:**
- No broken links in any documentation
- All code examples tested and working
- All code examples use Write-Host only
- All ADSI examples use LDAP:// protocol only
- **All date/time examples use Unix Epoch format**
- Native Windows modules used where appropriate
- RSAT dependencies eliminated
- Base64 encoding tested with special characters
- **Date/Time fields tested with timezone handling**
- Script outputs identical on German and English Windows
- Consistent formatting throughout
- All cross-references accurate
- TBD_INVENTORY.md shows 100% resolution
- Style guide compliance verified
- Coding standards compliance verified
- No checkmarks, crosses, or emojis
- ADSI LDAP:// functions tested on domain and workgroup systems
- Language-neutral code verified on multiple Windows languages
- Base64 encoding verified with umlauts and special characters
- **Unix Epoch date conversion verified on multiple timezones**

---

## Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-03 | 1.0 | WAF Team | Initial action plan created |
| 2026-02-03 | 1.1 | WAF Team | Added Phase 3 for TBD audit |
| 2026-02-03 | 1.2 | WAF Team | Enhanced compound condition documentation |
| 2026-02-03 | 1.3 | WAF Team | Added Phase 0 for coding standards |
| 2026-02-03 | 1.4 | WAF Team | Added Pre-Phase A (ADSI) and Pre-Phase B (module dependency reduction) |
| 2026-02-03 | 1.5 | WAF Team | Added Pre-Phase D (German/English Windows language compatibility) |
| 2026-02-03 | 1.6 | WAF Team | Refined Pre-Phase B (keep native modules, replace RSAT only) and added Pre-Phase C (Base64 encoding standard) |
| 2026-02-03 | 1.7 | WAF Team | Standardized Pre-Phase A to use LDAP:// protocol exclusively for all ADSI queries |
| 2026-02-03 | 1.8 | WAF Team | Added Pre-Phase E (Date/Time Field Standards with Unix Epoch format per NinjaOne guidelines) |

---

**END OF ACTION PLAN**
