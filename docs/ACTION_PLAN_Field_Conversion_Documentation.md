# WAF Field Type Conversion & Documentation Completeness Plan

**Date:** February 3, 2026  
**Status:** Planning Phase  
**Priority:** High

---

## Executive Summary

This plan outlines the systematic conversion of all dropdown custom fields to text fields and ensures complete documentation coverage for all 48+ scripts in the Windows Automation Framework. The goal is to eliminate dropdown field dependencies, reduce RSAT and non-native PowerShell module dependencies, migrate Active Directory queries to ADSI LDAP:// queries exclusively, standardize data encoding with Base64, use proper Date/Time fields with Unix Epoch format, ensure all helper functions are embedded in scripts (no external references), ensure language compatibility (German/English Windows), and create a comprehensive documentation suite following consistent style guidelines and coding standards.

---

[Pre-Phase A through D sections remain the same - preserving all content]

## Pre-Phase E: Date/Time Field Standards (Unix Epoch Format)

### Objective
Standardize all date and time data to use NinjaOne **Date** or **Date and Time** custom field types with proper Unix Epoch formatting instead of text fields. This ensures consistent date handling, proper sorting, filtering, and display across the NinjaOne platform.

### Why Use Date/Time Fields

**Benefits:**
- Proper sorting and filtering in NinjaOne dashboard
- Consistent date display across different regional settings
- Better reporting and analytics capabilities
- Automatic timezone handling by NinjaOne
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

**RECOMMENDED: Use .NET DateTimeOffset for Simplicity**

The preferred method uses `[DateTimeOffset]::FromUnixTimeSeconds()` and `.ToUnixTimeSeconds()` for cleaner, more maintainable code.

**Writing to Date/Time Field (DateTime to Unix Epoch):**

```powershell
# Example 1: Store current date/time
$currentTimestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
Ninja-Property-Set lastRunTimestamp $currentTimestamp
Write-Host "INFO: Script last run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Example 2: Store specific DateTime
$lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
if ($lastBootTime) {
    $bootTimestamp = [DateTimeOffset]$lastBootTime.ToUniversalTime() | Select-Object -ExpandProperty ToUnixTimeSeconds
    # Or more simply:
    $bootTimestamp = [DateTimeOffset]$lastBootTime | Select-Object -ExpandProperty ToUnixTimeSeconds
    Ninja-Property-Set systemLastBootTime $bootTimestamp
    Write-Host "INFO: System last boot: $($lastBootTime.ToString('yyyy-MM-dd HH:mm:ss'))"
}
```

**Reading from Date/Time Field (Unix Epoch to DateTime):**

```powershell
# Example: Get planned reboot time from custom field
$epoch = Ninja-Property-Get customRebootDateTime
if ($epoch) {
    # Convert epoch (UTC) to local time
    $planned = [DateTimeOffset]::FromUnixTimeSeconds([int64]$epoch).ToLocalTime().DateTime
    $now = Get-Date
    
    # Calculate difference in seconds
    $diffSeconds = ($planned - $now).TotalSeconds
    
    Write-Host "INFO: Planned reboot time: $($planned.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "INFO: Time until reboot: $diffSeconds seconds"
} else {
    Write-Host "INFO: No custom reboot time set."
}
```

### Common Date/Time Scenarios

**1. Current Timestamp (Last Run/Last Checked):**

```powershell
# Store current date/time as Unix Epoch
$currentTimestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
Ninja-Property-Set lastRunTimestamp $currentTimestamp
Write-Host "INFO: Script last run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
```

**2. System Boot Time:**

```powershell
# Get last boot time from WMI/CIM
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBootTime = $os.LastBootUpTime

if ($lastBootTime) {
    $bootTimestamp = [DateTimeOffset]$lastBootTime | Select-Object -ExpandProperty ToUnixTimeSeconds
    Ninja-Property-Set systemLastBootTime $bootTimestamp
    Write-Host "INFO: System last boot: $($lastBootTime.ToString('yyyy-MM-dd HH:mm:ss'))"
}
```

**3. File Modification Time:**

```powershell
# Get file last modified time
$file = Get-Item "C:\SomeFile.txt" -ErrorAction SilentlyContinue
if ($file) {
    $modifiedTimestamp = [DateTimeOffset]$file.LastWriteTime | Select-Object -ExpandProperty ToUnixTimeSeconds
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
        $pwdTimestamp = [DateTimeOffset]$pwdLastSetDate | Select-Object -ExpandProperty ToUnixTimeSeconds
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
    $expirationTimestamp = [DateTimeOffset]$cert.NotAfter | Select-Object -ExpandProperty ToUnixTimeSeconds
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
        $nextRunTimestamp = [DateTimeOffset]$nextRunTime | Select-Object -ExpandProperty ToUnixTimeSeconds
        Ninja-Property-Set taskNextRunTime $nextRunTimestamp
        Write-Host "INFO: Task next run: $($nextRunTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    }
}
```

**7. Reading and Comparing Dates:**

```powershell
# Real-world example: Scheduled reboot script
$warningSeconds = 300  # 5 minutes warning

# Get planned reboot time from custom field
$epoch = Ninja-Property-Get customRebootDateTime
if (-not $epoch) {
    Write-Host "INFO: No custom reboot time set."
    exit 0
}

# Convert epoch (UTC) to local time
$planned = [DateTimeOffset]::FromUnixTimeSeconds([int64]$epoch).ToLocalTime().DateTime
$now = Get-Date

# Calculate difference in seconds
$diffSeconds = ($planned - $now).TotalSeconds

# Max wait time = 15 minutes (900 seconds)
$maxWait = 900

if ($diffSeconds -gt 0 -and $diffSeconds -le $maxWait) {
    # Reboot is coming up within the next cycle
    if ($diffSeconds -gt $warningSeconds) {
        # Wait until warning moment
        $waitUntilWarning = $diffSeconds - $warningSeconds
        Write-Host "INFO: Waiting $waitUntilWarning seconds until showing reboot warning..."
        Start-Sleep -Seconds [int]$waitUntilWarning
    }

    # Show warning
    $msg = "System will reboot in $warningSeconds seconds. Please save your work."
    Write-Host "INFO: $msg"
    msg * $msg   # show message to all logged-on users

    # Wait remaining warning time
    Start-Sleep -Seconds [int]$warningSeconds

    # Execute reboot
    Write-Host "INFO: Executing reboot now."
    Restart-Computer -Force
}
elseif ($diffSeconds -gt $maxWait) {
    Write-Host "INFO: Planned reboot is more than 15 minutes away ($planned). Will check again later."
}
else {
    Write-Host "INFO: Planned reboot time $planned has already passed. No action taken."
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
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
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
   - Replace text field writes with Unix Epoch conversion using DateTimeOffset
   - Keep human-readable logging for troubleshooting
   - No helper functions needed (use inline conversion)

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
try {
    if ($null -ne $someDateTime) {
        $timestamp = [DateTimeOffset]$someDateTime | Select-Object -ExpandProperty ToUnixTimeSeconds
        Ninja-Property-Set someField $timestamp
        Write-Host "SUCCESS: Set someField to $($someDateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    } else {
        Write-Host "WARNING: DateTime is null, skipping field update"
    }
} catch {
    Write-Host "ERROR: Failed to convert DateTime - $($_.Exception.Message)"
}
```

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
    Uses [DateTimeOffset] for conversion (no helper functions needed)
#>
```

---

## Pre-Phase F: Helper Function Embedding Requirement

### Objective
Ensure all helper functions are embedded directly within each script. Scripts must be completely self-contained with no external dependencies or references to other PowerShell scripts.

### Critical Requirement

**NEVER reference external PowerShell scripts or modules within WAF scripts**

NinjaRMM executes scripts in isolation. Scripts cannot:
- Dot-source other scripts (`. .\HelperFunctions.ps1`)
- Import custom modules from file system (`Import-Module .\MyModule.psm1`)
- Call other PowerShell scripts (`& .\AnotherScript.ps1`)
- Reference shared function libraries

### Implementation Rules

**Rule 1: Embed All Helper Functions**
Every helper function must be defined within the script that uses it.

```powershell
# CORRECT - Helper function embedded in script
function ConvertTo-Base64 {
    param([Parameter(Mandatory=$true)]$InputObject)
    try {
        $json = $InputObject | ConvertTo-Json -Compress -Depth 10
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $base64 = [System.Convert]::ToBase64String($bytes)
        if ($base64.Length -gt 9999) {
            Write-Host "ERROR: Base64 exceeds 9999 characters"
            return $null
        }
        return $base64
    } catch {
        Write-Host "ERROR: Failed to convert to Base64 - $($_.Exception.Message)"
        return $null
    }
}

# Main script logic here
$data = @("Group1", "Group2", "Group3")
$encoded = ConvertTo-Base64 -InputObject $data
Ninja-Property-Set myField $encoded
```

```powershell
# WRONG - External reference (will fail)
. .\HelperFunctions.ps1  # DO NOT DO THIS
$encoded = ConvertTo-Base64 -InputObject $data
```

**Rule 2: Duplicate Functions When Necessary**
If multiple scripts need the same helper function, copy the function into each script.

**Benefits:**
- Scripts are portable and self-contained
- No dependency management required
- Each script can be tested independently
- No version conflicts between shared functions
- Clear which functions each script uses

**Maintenance:**
- When updating a helper function, update it in all scripts that use it
- Document which scripts use each helper function
- Consider creating a "function library" document for reference (but NOT for execution)

**Rule 3: Use Native .NET Methods for Simple Operations**
For simple operations, use inline .NET methods instead of creating helper functions.

```powershell
# GOOD - Inline conversion (no helper function needed)
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
Ninja-Property-Set lastRunTimestamp $timestamp

# GOOD - Inline Base64 encoding for simple data
$bytes = [System.Text.Encoding]::UTF8.GetBytes($simpleString)
$base64 = [System.Convert]::ToBase64String($bytes)
Ninja-Property-Set someField $base64
```

**Rule 4: Native Windows Modules Are Allowed**
Scripts CAN import native Windows PowerShell modules that are part of Windows.

```powershell
# ALLOWED - Native Windows modules
Import-Module Storage          # Part of Windows Server/Client
Import-Module BitLocker        # Part of Windows (when feature installed)
Import-Module NetSecurity      # Part of Windows
Import-Module Defender         # Part of Windows

# NOT ALLOWED - Custom modules or external scripts
Import-Module .\MyCustomModule.psm1       # External reference
. .\SharedFunctions.ps1                   # External reference
```

### Audit Strategy

**Search for External References:**

Search all scripts for these patterns:
```powershell
# Pattern 1: Dot-sourcing
. .
. $

# Pattern 2: External script calls
& .
& $
Invoke-Expression

# Pattern 3: Custom module imports
Import-Module .
Import-Module $
```

**Allowed Patterns:**
```powershell
# Native Windows modules (OK)
Import-Module Storage
Import-Module BitLocker
Import-Module NetSecurity
Import-Module Defender
Import-Module ScheduledTasks
Import-Module DnsClient

# .NET framework calls (OK)
[System.Convert]::ToBase64String()
[DateTimeOffset]::Now
[ADSI]"LDAP://"
```

### Common Helper Functions to Embed

**Base64 Encoding/Decoding:**
```powershell
function ConvertTo-Base64 {
    param([Parameter(Mandatory=$true)]$InputObject)
    try {
        $json = $InputObject | ConvertTo-Json -Compress -Depth 10
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $base64 = [System.Convert]::ToBase64String($bytes)
        if ($base64.Length -gt 9999) {
            Write-Host "ERROR: Base64 exceeds 9999 characters ($($base64.Length))"
            return $null
        }
        Write-Host "INFO: Base64 size: $($base64.Length) characters"
        return $base64
    } catch {
        Write-Host "ERROR: Failed to convert to Base64 - $($_.Exception.Message)"
        return $null
    }
}

function ConvertFrom-Base64 {
    param([Parameter(Mandatory=$true)][string]$Base64String)
    try {
        if ([string]::IsNullOrWhiteSpace($Base64String)) { return $null }
        $bytes = [System.Convert]::FromBase64String($Base64String)
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        return ($json | ConvertFrom-Json)
    } catch {
        Write-Host "ERROR: Failed to decode Base64 - $($_.Exception.Message)"
        return $null
    }
}
```

**ADSI LDAP:// Helper Functions:**
```powershell
function Test-ADConnection {
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        if ([string]::IsNullOrEmpty($rootDSE.defaultNamingContext)) {
            Write-Host "ERROR: Unable to connect via LDAP"
            return $false
        }
        Write-Host "INFO: LDAP connection established"
        return $true
    } catch {
        Write-Host "ERROR: LDAP connection failed - $($_.Exception.Message)"
        return $false
    }
}

function Get-ADUserViaADSI {
    param([string]$SamAccountName)
    # ... full function implementation here ...
}

function Get-ADComputerViaADSI {
    param([string]$ComputerName = $env:COMPUTERNAME)
    # ... full function implementation here ...
}
```

**Note:** Date/Time conversions do NOT need helper functions. Use inline DateTimeOffset methods instead.

### Documentation Requirements

**Script Header:**
```powershell
<#
.SYNOPSIS
    Script XX: Description

.DESCRIPTION
    Full description

.HELPER FUNCTIONS
    - ConvertTo-Base64: Encode complex data for storage (9999 char limit)
    - ConvertFrom-Base64: Decode stored data
    - Test-ADConnection: Validate LDAP connectivity
    - Get-ADUserViaADSI: Query user information via LDAP://
    
.NOTES
    All helper functions are embedded in this script (no external dependencies)
    Script is completely self-contained for NinjaRMM execution
#>
```

### Migration Tasks

1. **Audit All Scripts:**
   - Search for dot-sourcing (`. .\`)
   - Search for script execution (`& .\`)
   - Search for custom module imports
   - Document findings

2. **Identify Shared Functions:**
   - List all helper functions used across scripts
   - Document which scripts use which functions
   - Create reference documentation (for developers, not execution)

3. **Embed Functions:**
   - Copy required functions into each script
   - Place functions at top of script (before main logic)
   - Test each script independently

4. **Remove External References:**
   - Delete all dot-sourcing statements
   - Delete all external script calls
   - Delete custom module imports

5. **Validate:**
   - Test each script in isolation
   - Verify no external dependencies remain
   - Confirm scripts run in NinjaRMM environment

---

## Phase 0: Coding Standards and Conventions

### Additional Coding Standards

**Helper Function Requirements:**
- All helper functions MUST be embedded in the script that uses them
- NEVER reference external PowerShell scripts or custom modules
- Duplicate functions across scripts when necessary
- Place helper functions at top of script before main logic
- Document helper functions in script header .HELPER FUNCTIONS section
- Native Windows modules (Storage, BitLocker, etc.) are allowed

**Date/Time Field Usage:**
- Always use Date or Date/Time custom fields for temporal data (not text)
- Use inline DateTimeOffset methods (no helper functions needed)
- Write: `$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()`
- Read: `$dateTime = [DateTimeOffset]::FromUnixTimeSeconds([int64]$epoch).ToLocalTime().DateTime`
- Always log human-readable dates for troubleshooting
- Document field types in script header FIELDS UPDATED section
- Include "Unix Epoch" in field documentation

**ADSI LDAP:// Protocol Usage:**
- Always use LDAP:// protocol for all Active Directory queries
- Never use WinNT:// for AD queries (local accounts only)
- Never use GC:// unless specifically needed for global catalog
- Embed ADSI helper functions (Test-ADConnection, Get-ADUserViaADSI, etc.)
- Set SearchScope explicitly to Subtree for domain-wide queries
- Use specific LDAP filters with objectClass and objectCategory
- Request only needed attributes via PropertiesToLoad
- Always check for null/empty before accessing LDAP properties

**Base64 Encoding Usage:**
- Always use Base64 encoding for complex data structures (arrays, hashtables, nested objects)
- Always validate encoded data does not exceed 9999 characters
- Always embed ConvertTo-Base64 and ConvertFrom-Base64 functions in scripts that need them
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
   - Ensure functions are embedded in each script
   - Test with complex data structures
   - Verify special character handling

4. **Pre-Phase D: Language Compatibility**
   - Test all scripts on German Windows
   - Test all scripts on English Windows
   - Verify no hardcoded language-specific strings
   - Document language-neutral approaches

5. **Pre-Phase E: Date/Time Field Standards**
   - Audit all scripts storing dates as text
   - Create Date/Time custom fields in NinjaOne
   - Update scripts to use Unix Epoch format with DateTimeOffset
   - Use inline conversion (no helper functions)
   - Test timezone handling and display
   - Verify German/English Windows compatibility
   - Document Unix Epoch requirement

6. **Pre-Phase F: Helper Function Embedding Audit** (NEW)
   - Search all scripts for external references (dot-sourcing, script calls)
   - Identify scripts with external dependencies
   - List all helper functions used across scripts
   - Embed helper functions into scripts
   - Remove all external references
   - Test each script independently
   - Document which functions each script uses

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
- All date/time data uses Date or Date/Time fields with Unix Epoch format
- **All helper functions embedded in scripts (no external references)**
- **No dot-sourcing or external script calls in any script**
- All scripts tested and working on German Windows
- All scripts tested and working on English Windows
- No language-dependent code remains
- All scripts function correctly with text fields
- No breaking changes to existing deployments
- All automated tests passing
- All scripts use Write-Host exclusively
- AD connectivity validated before LDAP queries
- Scripts use native Windows modules appropriately
- Each script is completely self-contained

**Documentation Requirements:**
- Every script has corresponding documentation
- ADSI LDAP:// implementation documented with examples
- LDAP:// protocol requirement clearly stated
- Native module usage documented (why kept)
- RSAT module replacements documented
- Base64 encoding documented with examples
- Unix Epoch date/time format documented with examples
- **Helper function embedding requirement documented**
- **HELPER_FUNCTION_AUDIT.md complete**
- DATE_TIME_FIELD_REPORT.md complete
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
- All date/time examples use Unix Epoch format with DateTimeOffset
- **All scripts verified to have no external dependencies**
- Native Windows modules used where appropriate
- RSAT dependencies eliminated
- Base64 encoding tested with special characters
- Date/Time fields tested with timezone handling
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
- Unix Epoch date conversion verified on multiple timezones
- **Each script runs independently without external files**

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
| 2026-02-03 | 1.9 | WAF Team | Updated Pre-Phase E with simplified DateTimeOffset pattern and added Pre-Phase F (Helper Function Embedding Requirement) |

---

**END OF ACTION PLAN**
