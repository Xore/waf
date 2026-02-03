# Windows Automation Framework - Coding Standards

**Version:** 1.0  
**Date:** February 3, 2026  
**Status:** Active  
**Applies To:** All WAF PowerShell scripts

---

## Table of Contents

1. [Overview](#overview)
2. [Script Structure](#script-structure)
3. [Naming Conventions](#naming-conventions)
4. [Code Organization](#code-organization)
5. [Data Storage Standards](#data-storage-standards)
6. [Active Directory Integration](#active-directory-integration)
7. [Module Usage](#module-usage)
8. [Error Handling](#error-handling)
9. [Logging Standards](#logging-standards)
10. [Language Compatibility](#language-compatibility)
11. [Performance Guidelines](#performance-guidelines)
12. [Security Requirements](#security-requirements)
13. [Documentation Requirements](#documentation-requirements)
14. [Testing Requirements](#testing-requirements)
15. [Prohibited Practices](#prohibited-practices)

---

## Overview

### Purpose

This document establishes mandatory coding standards for all Windows Automation Framework (WAF) PowerShell scripts deployed via NinjaRMM. These standards ensure consistency, reliability, maintainability, and cross-platform compatibility.

### Scope

These standards apply to:
- All monitoring scripts (Script_XX_*.ps1)
- All automation scripts (XX_*.ps1)
- All utility scripts
- All script updates and modifications

### Compliance

All scripts MUST comply with these standards before deployment. Non-compliant scripts will be rejected during code review.

---

## Script Structure

### Standard Script Template

```powershell
<#
.SYNOPSIS
    Script XX: Brief one-line description

.DESCRIPTION
    Detailed multi-line description of what the script does,
    why it exists, and what problems it solves.

.FIELDS UPDATED
    - fieldName1 (Type: Description)
    - fieldName2 (Date/Time: Unix Epoch seconds since 1970-01-01 UTC)
    - fieldName3 (Text: Base64-encoded JSON for complex data)

.REQUIREMENTS
    - Windows XX or later
    - Domain membership (if applicable)
    - PowerShell 5.1 or later
    - Required roles/features (if applicable)

.HELPER FUNCTIONS
    - FunctionName1: Purpose and usage
    - FunctionName2: Purpose and usage

.NOTES
    Version: X.Y
    Author: WAF Team
    Last Updated: YYYY-MM-DD
    
    Language Compatibility: Works on German and English Windows
    RSAT Required: No
    Module Dependencies: [List or "None"]
    
    Date/Time fields use Unix Epoch format (seconds since 1970-01-01 00:00:00 UTC)
    Complex data uses Base64-encoded JSON (UTF-8, 9999 char limit)
    All helper functions are embedded in this script (no external dependencies)

.CHANGELOG
    X.Y (YYYY-MM-DD): Description of changes
    X.X (YYYY-MM-DD): Initial version
#>

#Requires -Version 5.1

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Place all helper functions here before main script logic

function ConvertTo-Base64 {
    <#
    .SYNOPSIS
        Convert complex objects to Base64-encoded JSON for storage
    #>
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
    <#
    .SYNOPSIS
        Decode Base64-encoded JSON back to objects
    #>
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

# ============================================================================
# MAIN SCRIPT LOGIC
# ============================================================================

Write-Host "INFO: Script XX starting..."

# Feature/Role check (if applicable)
$feature = Get-WindowsFeature -Name "FeatureName" -ErrorAction SilentlyContinue
if ($null -eq $feature -or $feature.Installed -ne $true) {
    Write-Host "INFO: Feature not installed - setting N/A values"
    Ninja-Property-Set fieldName "Not Installed"
    Write-Host "SUCCESS: Script complete (feature not present)"
    exit 0
}

# Main monitoring/automation logic here

# Store results
Ninja-Property-Set fieldName $value

# Store timestamp
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
Ninja-Property-Set lastRunTimestamp $timestamp
Write-Host "INFO: Last run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Write-Host "SUCCESS: Script XX completed successfully"
exit 0
```

### Required Sections

**Every script MUST include:**
1. Synopsis block with complete metadata
2. Helper functions section (even if empty)
3. Main script logic section
4. Proper exit codes (0 for success, 1 for failure)
5. Timestamp tracking

---

## Naming Conventions

### Script Names

**Monitoring Scripts:**
- Format: `Script_XX_Description_Monitor.ps1`
- Example: `Script_42_Active_Directory_Monitor.ps1`
- Number range: 01-99

**Automation Scripts:**
- Format: `XX_Description_Action.ps1`
- Example: `12_Baseline_Manager.ps1`
- Number range: 01-99

### Variable Names

**Use camelCase:**
```powershell
# CORRECT
$computerName = $env:COMPUTERNAME
$domainController = "DC01"
$lastBootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

# INCORRECT
$ComputerName = $env:COMPUTERNAME  # PascalCase
$domain_controller = "DC01"        # snake_case
$last-boot-time = Get-Date         # kebab-case
```

**Exceptions (use PascalCase):**
- Parameters in functions: `param($ComputerName, $DomainName)`
- Class names: `[DateTime]`, `[ADSISearcher]`

### Function Names

**Use PascalCase with approved verbs:**
```powershell
# CORRECT
function Get-ADComputerViaADSI { }
function Test-ADConnection { }
function ConvertTo-Base64 { }

# INCORRECT
function getADComputer { }         # Wrong case
function Retrieve-ADComputer { }   # Non-standard verb
function AD_Computer_Get { }       # Wrong format
```

**Approved PowerShell Verbs:**
- Get, Set, New, Remove, Test, Invoke, Start, Stop, Enable, Disable
- ConvertTo, ConvertFrom, Import, Export, Format

### Custom Field Names

**Use camelCase with descriptive names:**
```powershell
# CORRECT
Ninja-Property-Set adPasswordLastSet $timestamp
Ninja-Property-Set gpoLastApplied $timestamp
Ninja-Property-Set baseLastUpdated $timestamp

# INCORRECT
Ninja-Property-Set ADPasswordLastSet $timestamp   # PascalCase
Ninja-Property-Set ad_password_last_set $timestamp # snake_case
Ninja-Property-Set pwdLastSet $timestamp          # Too abbreviated
```

---

## Code Organization

### Script Sections Order

**MANDATORY ORDER:**
1. Synopsis block
2. `#Requires` statement
3. Helper functions section
4. Main script logic
5. Exit statement

### Self-Contained Requirement

**CRITICAL:** Scripts MUST be completely self-contained.

**ALLOWED:**
```powershell
# Native Windows modules
Import-Module Storage
Import-Module BitLocker
Import-Module DnsServer  # With feature check

# .NET Framework calls
[System.Convert]::ToBase64String($bytes)
[DateTimeOffset]::Now.ToUnixTimeSeconds()
[ADSI]"LDAP://RootDSE"

# Embedded helper functions
function ConvertTo-Base64 { }
```

**PROHIBITED:**
```powershell
# External script references
. .\HelperFunctions.ps1           # NEVER dot-source
& .\AnotherScript.ps1              # NEVER call external scripts

# Custom module imports
Import-Module .\MyModule.psm1     # NEVER import custom modules
Import-Module $PSScriptRoot\*     # NEVER use relative paths

# External dependencies
Invoke-Expression (Get-Content .\code.ps1)  # NEVER use Invoke-Expression with files
```

### Helper Function Embedding

**All helper functions MUST be embedded in scripts that use them.**

```powershell
# CORRECT - Function embedded in script
function ConvertTo-Base64 {
    # Full implementation here
}

$encoded = ConvertTo-Base64 -InputObject $data

# WRONG - External reference
. .\SharedFunctions.ps1  # This will FAIL in NinjaRMM
$encoded = ConvertTo-Base64 -InputObject $data
```

**If multiple scripts need the same function:**
- Copy the function into each script
- Update all copies when function changes
- Document which scripts use which functions

---

## Data Storage Standards

### Complex Data: Base64-Encoded JSON

**When to use:**
- Arrays with multiple elements
- Hashtables or objects
- Nested data structures
- Data with special characters

**Implementation:**
```powershell
# Encoding complex data
$complexData = @{
    Groups = @("Group1", "Group2", "Group3")
    Status = "Active"
    Timestamp = Get-Date
}

$encoded = ConvertTo-Base64 -InputObject $complexData
if ($encoded) {
    Ninja-Property-Set fieldName $encoded
    Write-Host "SUCCESS: Data encoded and stored"
} else {
    Write-Host "ERROR: Failed to encode data"
}

# Decoding complex data
$encoded = Ninja-Property-Get fieldName
if ($encoded) {
    $decoded = ConvertFrom-Base64 -Base64String $encoded
    if ($decoded) {
        Write-Host "INFO: Found $($decoded.Groups.Count) groups"
    }
}
```

**Requirements:**
- MUST use UTF-8 encoding
- MUST validate 9999 character limit
- MUST log encoded size
- MUST handle encoding errors gracefully

### Date/Time: Unix Epoch Format

**When to use:**
- Timestamps (last run, last checked)
- System dates (last boot, password set)
- Event dates (expiration, renewal)
- Any temporal data

**Implementation:**
```powershell
# Writing date/time to field
$dateTime = Get-Date
$timestamp = [DateTimeOffset]$dateTime | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set lastRunTimestamp $timestamp
Write-Host "INFO: Last run: $($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))"

# Reading date/time from field
$epoch = Ninja-Property-Get lastRunTimestamp
if ($epoch) {
    $dateTime = [DateTimeOffset]::FromUnixTimeSeconds([int64]$epoch).ToLocalTime().DateTime
    $hoursAgo = ((Get-Date) - $dateTime).TotalHours
    Write-Host "INFO: Last run was $([math]::Round($hoursAgo, 1)) hours ago"
}

# Converting AD FileTime to Unix Epoch
$pwdLastSetValue = [Int64]$computer['pwdLastSet'][0]
$pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
$timestamp = [DateTimeOffset]$pwdLastSetDate | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set adPasswordLastSet $timestamp
```

**Requirements:**
- MUST use Unix Epoch (seconds since 1970-01-01 UTC)
- MUST use inline DateTimeOffset conversion (no helper functions)
- MUST log human-readable format for troubleshooting
- MUST document field as "Unix Epoch" in script header

### Simple Data: Text Fields

**When to use:**
- Single string values
- Boolean values (as "true"/"false" strings)
- Numeric values (as strings)
- Simple comma-separated lists

**Implementation:**
```powershell
# Simple string
Ninja-Property-Set computerName $env:COMPUTERNAME

# Boolean as string
Ninja-Property-Set isDomainJoined ($computerSystem.PartOfDomain -eq $true).ToString()

# Numeric as string
Ninja-Property-Set cpuCount $processor.NumberOfLogicalProcessors.ToString()

# Simple array as comma-separated
$adapters = @("Ethernet", "Wi-Fi", "Bluetooth")
Ninja-Property-Set networkAdapters ($adapters -join ", ")
```

---

## Active Directory Integration

### LDAP:// Protocol Only

**MANDATORY:** All AD queries MUST use LDAP:// protocol.

**CORRECT:**
```powershell
# Domain connection
$rootDSE = [ADSI]"LDAP://RootDSE"
$defaultNC = $rootDSE.defaultNamingContext[0]

# Computer query
$computerName = $env:COMPUTERNAME
$searcher = [ADSISearcher]"LDAP://$defaultNC"
$searcher.Filter = "(&(objectClass=computer)(cn=$computerName))"
$searcher.PropertiesToLoad.AddRange(@('cn','distinguishedName','pwdLastSet'))
$result = $searcher.FindOne()
```

**PROHIBITED:**
```powershell
# WinNT:// - NEVER use for AD queries
$computer = [ADSI]"WinNT://$env:COMPUTERNAME"

# GC:// - NEVER use unless specifically needed for global catalog
$gc = [ADSI]"GC://domain.com"

# ActiveDirectory module - NEVER use (requires RSAT)
Get-ADComputer -Identity $computerName
```

### ADSI Query Pattern

**Standard pattern for AD queries:**
```powershell
function Get-ADComputerViaADSI {
    param([string]$ComputerName = $env:COMPUTERNAME)
    
    try {
        # Connect to domain
        $rootDSE = [ADSI]"LDAP://RootDSE"
        if ([string]::IsNullOrEmpty($rootDSE.defaultNamingContext)) {
            Write-Host "ERROR: Unable to connect to domain"
            return $null
        }
        
        $defaultNC = $rootDSE.defaultNamingContext[0]
        
        # Create searcher
        $searcher = [ADSISearcher]"LDAP://$defaultNC"
        $searcher.Filter = "(&(objectClass=computer)(objectCategory=computer)(cn=$ComputerName))"
        $searcher.SearchScope = "Subtree"
        $searcher.PropertiesToLoad.AddRange(@(
            'cn',
            'distinguishedName',
            'pwdLastSet',
            'memberOf'
        ))
        
        # Execute search
        $result = $searcher.FindOne()
        if ($null -eq $result) {
            Write-Host "INFO: Computer not found in AD"
            return $null
        }
        
        return $result.Properties
    } catch {
        Write-Host "ERROR: LDAP query failed - $($_.Exception.Message)"
        return $null
    }
}
```

### Domain Membership Check

**Check before AD queries:**
```powershell
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
if ($computerSystem.PartOfDomain -ne $true) {
    Write-Host "INFO: System not domain-joined - skipping AD queries"
    Ninja-Property-Set adMembership "Workgroup"
    exit 0
}

Write-Host "INFO: Domain: $($computerSystem.Domain)"
```

---

## Module Usage

### Native Windows Modules: Allowed

**These modules are always allowed:**
```powershell
Import-Module Storage
Import-Module BitLocker
Import-Module NetAdapter
Import-Module NetSecurity
Import-Module Defender
Import-Module ScheduledTasks
Import-Module DnsClient
```

### Server Role Modules: Allowed with Feature Check

**Pattern for server role modules:**
```powershell
# Check if role is installed
$feature = Get-WindowsFeature -Name "DHCP" -ErrorAction SilentlyContinue

if ($null -eq $feature -or $feature.Installed -ne $true) {
    Write-Host "INFO: DHCP role not installed"
    Ninja-Property-Set dhcpStatus "Not Installed"
    exit 0
}

# Import module (only if role installed)
try {
    Import-Module DhcpServer -ErrorAction Stop
    Write-Host "INFO: DhcpServer module loaded"
} catch {
    Write-Host "ERROR: Failed to load module - $($_.Exception.Message)"
    Ninja-Property-Set dhcpStatus "Error"
    exit 1
}

# Continue with DHCP monitoring
```

**Allowed server role modules:**
- DhcpServer (DHCP role)
- DnsServer (DNS role)
- Hyper-V (Hyper-V role)
- WebAdministration (IIS role)
- SqlServer (SQL Server)

### RSAT-Only Modules: Prohibited

**NEVER use these modules:**
```powershell
# ActiveDirectory - Use LDAP:// instead
Import-Module ActiveDirectory  # PROHIBITED

# GroupPolicy - Use registry/XML instead
Import-Module GroupPolicy  # PROHIBITED

# ADDSDeployment - Not needed for monitoring
Import-Module ADDSDeployment  # PROHIBITED
```

---

## Error Handling

### Try-Catch Pattern

**Use try-catch for all risky operations:**
```powershell
try {
    $result = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    Write-Host "INFO: OS query successful"
} catch {
    Write-Host "ERROR: Failed to query OS - $($_.Exception.Message)"
    Ninja-Property-Set osStatus "Error"
    exit 1
}
```

### ErrorAction Parameter

**Use appropriate ErrorAction:**
```powershell
# Stop - For critical operations
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop

# SilentlyContinue - For optional checks
$feature = Get-WindowsFeature -Name "FeatureName" -ErrorAction SilentlyContinue

# Continue (default) - For most operations
$services = Get-Service
```

### Null Checks

**Always check for null before accessing properties:**
```powershell
# CORRECT
$computer = Get-ADComputerViaADSI
if ($null -ne $computer -and $computer['pwdLastSet']) {
    $pwdLastSet = $computer['pwdLastSet'][0]
}

# INCORRECT - Will throw error if null
$pwdLastSet = $computer['pwdLastSet'][0]
```

---

## Logging Standards

### Write-Host Usage

**MANDATORY:** Use Write-Host exclusively for all output.

**Log Levels:**
```powershell
# INFO - Informational messages
Write-Host "INFO: Starting process..."
Write-Host "INFO: Found 5 items"

# SUCCESS - Successful operations
Write-Host "SUCCESS: Script completed"
Write-Host "SUCCESS: Data stored successfully"

# WARNING - Non-critical issues
Write-Host "WARNING: Item not found, using default"
Write-Host "WARNING: Low disk space detected"

# ERROR - Failures and exceptions
Write-Host "ERROR: Failed to connect - $($_.Exception.Message)"
Write-Host "ERROR: Base64 exceeds character limit"
```

### Prohibited Output

**NEVER use these:**
```powershell
Write-Output "Message"      # NO - Not visible in NinjaRMM
Write-Verbose "Message"     # NO - Requires -Verbose flag
Write-Debug "Message"       # NO - Requires -Debug flag
Write-Information "Message" # NO - PowerShell 5.0+ only
"Message"                   # NO - Implicit output
```

### Timestamp Logging

**Always log human-readable dates:**
```powershell
$dateTime = Get-Date
$timestamp = [DateTimeOffset]$dateTime | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set lastRunTimestamp $timestamp

# REQUIRED: Human-readable log
Write-Host "INFO: Last run: $($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
```

---

## Language Compatibility

### Language-Neutral Patterns

**Use numeric and boolean properties:**
```powershell
# CORRECT - Language-neutral
$service = Get-Service -Name "wuauserv"
if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) {
    Write-Host "INFO: Service is running"
}

# INCORRECT - Language-dependent
if ($service.Status -eq "Running") {  # "Wird ausgefuhrt" in German
    Write-Host "INFO: Service is running"
}
```

### Prohibited Patterns

**NEVER match localized strings:**
```powershell
# PROHIBITED
if ($service.Status -eq "Running") { }     # English only
if ($os.Caption -match "Professional") { } # Localized
if ($disk.DriveType -eq "Local Disk") { }  # Localized
```

### Required Patterns

**Use these language-neutral approaches:**
```powershell
# Service status - Use enumeration
if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { }

# OS version - Use Version property
if ($os.Version -match "^10\.") { }  # Not Caption

# Drive type - Use numeric value
if ($disk.DriveType -eq 3) { }  # 3 = Local disk

# Domain membership - Use boolean
if ($computerSystem.PartOfDomain -eq $true) { }
```

---

## Performance Guidelines

### Minimize WMI/CIM Queries

**Query once, reuse results:**
```powershell
# CORRECT
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$version = $os.Version
$lastBoot = $os.LastBootUpTime
$memory = $os.TotalVisibleMemorySize

# INCORRECT - Multiple queries
$version = (Get-CimInstance Win32_OperatingSystem).Version
$lastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$memory = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize
```

### Avoid Module Imports When Possible

**Use native commands:**
```powershell
# PREFERRED - No module import
$services = Get-Service
$processes = Get-Process
$items = Get-ChildItem

# AVOID - Requires module import
Import-Module SomeModule
$data = Get-SomeData
```

### Use -Filter Over Where-Object

**Filter at source:**
```powershell
# CORRECT - Filter at source
$service = Get-Service -Name "wuauserv"

# LESS EFFICIENT - Filter after retrieval
$service = Get-Service | Where-Object { $_.Name -eq "wuauserv" }
```

---

## Security Requirements

### No Hardcoded Credentials

**NEVER hardcode credentials:**
```powershell
# PROHIBITED
$password = "MyPassword123"
$credential = New-Object System.Management.Automation.PSCredential("user", (ConvertTo-SecureString $password -AsPlainText -Force))
```

### Use Windows Authentication

**Leverage existing authentication:**
```powershell
# CORRECT - Uses current user context
$computer = [ADSI]"LDAP://CN=$computerName,$defaultNC"
$shares = Get-SmbShare
```

### Avoid Invoke-Expression

**NEVER use Invoke-Expression with untrusted input:**
```powershell
# PROHIBITED
$command = Ninja-Property-Get userCommand
Invoke-Expression $command  # SECURITY RISK
```

---

## Documentation Requirements

### Script Header

**Complete synopsis block required:**
- .SYNOPSIS - One-line description
- .DESCRIPTION - Detailed explanation
- .FIELDS UPDATED - All fields with types
- .REQUIREMENTS - Prerequisites
- .HELPER FUNCTIONS - List of embedded functions
- .NOTES - Version, author, compatibility notes
- .CHANGELOG - Version history

### Inline Comments

**Comment complex logic:**
```powershell
# Convert AD FileTime (100-nanosecond intervals since 1601) to Unix Epoch
$pwdLastSetValue = [Int64]$computer['pwdLastSet'][0]
$pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
$timestamp = [DateTimeOffset]$pwdLastSetDate | Select-Object -ExpandProperty ToUnixTimeSeconds
```

### Function Documentation

**Document all functions:**
```powershell
function ConvertTo-Base64 {
    <#
    .SYNOPSIS
        Convert complex objects to Base64-encoded JSON for storage
    
    .PARAMETER InputObject
        The object to encode (hashtable, array, PSCustomObject)
    
    .OUTPUTS
        Base64-encoded string, or $null if encoding fails or exceeds 9999 chars
    #>
    param([Parameter(Mandatory=$true)]$InputObject)
    # Implementation
}
```

---

## Testing Requirements

### Pre-Deployment Testing

**Test on multiple systems:**
- [ ] Windows 10/11 Pro
- [ ] Windows Server 2019/2022
- [ ] Domain-joined system
- [ ] Workgroup system
- [ ] German Windows
- [ ] English Windows

### Validation Checks

**Verify before deployment:**
- [ ] Script executes without errors
- [ ] All fields update correctly
- [ ] Date/Time fields display properly in NinjaOne
- [ ] Base64 data encodes/decodes successfully
- [ ] Error handling works (test failure scenarios)
- [ ] Logging output is clear and helpful
- [ ] No RSAT dependencies
- [ ] No external script references
- [ ] Language-neutral implementation

---

## Prohibited Practices

### Absolute Prohibitions

**These practices are NEVER allowed:**

1. **External Script References**
   ```powershell
   . .\HelperFunctions.ps1  # NO
   & .\AnotherScript.ps1    # NO
   ```

2. **Custom Module Imports**
   ```powershell
   Import-Module .\MyModule.psm1  # NO
   ```

3. **RSAT-Only Modules**
   ```powershell
   Import-Module ActiveDirectory  # NO
   Import-Module GroupPolicy      # NO
   ```

4. **WinNT:// for AD**
   ```powershell
   $computer = [ADSI]"WinNT://$env:COMPUTERNAME"  # NO
   ```

5. **Localized String Matching**
   ```powershell
   if ($service.Status -eq "Running") { }  # NO
   ```

6. **Hardcoded Credentials**
   ```powershell
   $password = "MyPassword123"  # NO
   ```

7. **Non-Write-Host Output**
   ```powershell
   Write-Output "Message"  # NO
   Write-Verbose "Message" # NO
   ```

8. **Text Fields for Dates**
   ```powershell
   $date = (Get-Date).ToString("yyyy-MM-dd")
   Ninja-Property-Set lastRun $date  # NO - Use Unix Epoch
   ```

---

## Compliance Checklist

### Before Code Review

- [ ] Script uses standard template structure
- [ ] All helper functions are embedded
- [ ] No external script references
- [ ] LDAP:// used for all AD queries (if applicable)
- [ ] No RSAT-only modules
- [ ] Base64 encoding for complex data
- [ ] Unix Epoch for all date/time fields
- [ ] Language-neutral implementation
- [ ] Write-Host used exclusively
- [ ] Complete synopsis block
- [ ] Error handling implemented
- [ ] Null checks before property access
- [ ] Human-readable logging for timestamps
- [ ] Tested on German and English Windows
- [ ] No hardcoded credentials
- [ ] Feature checks for server role modules

---

## Version History

| Version | Date | Changes |
|---------|------|----------|
| 1.0 | 2026-02-03 | Initial release - Consolidated standards from Pre-Phases A-F |

---

## References

- [ACTION_PLAN_Field_Conversion_Documentation.md](ACTION_PLAN_Field_Conversion_Documentation.md)
- [ALL_PRE_PHASES_COMPLETE.md](ALL_PRE_PHASES_COMPLETE.md)
- [MODULE_DEPENDENCY_REPORT.md](MODULE_DEPENDENCY_REPORT.md)
- [PRE_PHASE_D_COMPLETION_SUMMARY.md](PRE_PHASE_D_COMPLETION_SUMMARY.md)
- [PRE_PHASE_E_COMPLETION_SUMMARY.md](PRE_PHASE_E_COMPLETION_SUMMARY.md)

---

**END OF CODING STANDARDS v1.0**
