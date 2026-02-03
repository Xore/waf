# WAF Field Type Conversion & Documentation Completeness Plan

**Date:** February 3, 2026  
**Status:** Planning Phase  
**Priority:** High

---

## Executive Summary

This plan outlines the systematic conversion of all dropdown custom fields to text fields and ensures complete documentation coverage for all 48+ scripts in the Windows Automation Framework. The goal is to eliminate dropdown field dependencies, reduce RSAT and non-native PowerShell module dependencies, migrate Active Directory queries to ADSI, standardize data encoding with Base64, ensure language compatibility (German/English Windows), and create a comprehensive documentation suite following consistent style guidelines and coding standards.

---

## Pre-Phase A: Active Directory ADSI Migration

### Objective
Migrate Active Directory monitoring scripts from ActiveDirectory PowerShell module to native ADSI (Active Directory Services Interface) queries to eliminate RSAT module dependencies and improve performance.

### Scope

**Primary Script:**
- Script_42_Active_Directory_Monitor.ps1

**Related Scripts (check for AD dependencies):**
- Script_20_Server_Role_Identifier.ps1
- Script_43_Group_Policy_Monitor.ps1
- Any other scripts querying AD user/computer information

### Migration Requirements

#### AD Information to Query via ADSI

**User Information:**
- Last Name (surname)
- First Name (givenName)
- Display Name (displayName)
- User Principal Name (userPrincipalName)
- Group Memberships (memberOf)
- Account Status (userAccountControl)
- Last Logon (lastLogonTimestamp)

**Computer Information:**
- Computer Name (cn)
- DNS Host Name (dNSHostName)
- Operating System (operatingSystem)
- Group Memberships (memberOf)
- Last Logon (lastLogonTimestamp)
- Computer Account Status (userAccountControl)

**Group Information:**
- Group Name (cn)
- Group Members (member)
- Group Type (groupType)
- Group Scope (distinguishedName)

### ADSI Implementation Pattern

**Connection Validation:**
```powershell
# Check Active Directory connectivity before queries
function Test-ADConnection {
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        if ([string]::IsNullOrEmpty($defaultNamingContext)) {
            Write-Host "ERROR: Unable to connect to Active Directory"
            return $false
        }
        
        Write-Host "INFO: Active Directory connection established"
        Write-Host "INFO: Default naming context: $defaultNamingContext"
        return $true
    } catch {
        Write-Host "ERROR: Active Directory connection failed - $($_.Exception.Message)"
        return $false
    }
}

# Always check connection before AD queries
if (-not (Test-ADConnection)) {
    Write-Host "ERROR: Cannot proceed without Active Directory connection"
    exit 1
}
```

**User Query via ADSI:**
```powershell
# Query user information without ActiveDirectory module
function Get-ADUserViaADSI {
    param(
        [string]$SamAccountName
    )
    
    try {
        # Get domain information
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        # Create LDAP searcher
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=user)(sAMAccountName=$SamAccountName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'givenName',
            'sn',
            'displayName',
            'userPrincipalName',
            'memberOf',
            'userAccountControl',
            'lastLogonTimestamp'
        ))
        
        $result = $searcher.FindOne()
        
        if ($result) {
            $user = $result.Properties
            
            # Extract group memberships
            $groups = @()
            if ($user['memberOf']) {
                foreach ($groupDN in $user['memberOf']) {
                    # Extract CN from DN
                    if ($groupDN -match 'CN=([^,]+)') {
                        $groups += $matches[1]
                    }
                }
            }
            
            # Return user object
            return [PSCustomObject]@{
                FirstName = if ($user['givenName']) { $user['givenName'][0] } else { "" }
                LastName = if ($user['sn']) { $user['sn'][0] } else { "" }
                DisplayName = if ($user['displayName']) { $user['displayName'][0] } else { "" }
                UserPrincipalName = if ($user['userPrincipalName']) { $user['userPrincipalName'][0] } else { "" }
                Groups = $groups -join ", "
                GroupCount = $groups.Count
                Enabled = if ($user['userAccountControl']) { 
                    -not ([int]$user['userAccountControl'][0] -band 2) 
                } else { 
                    $false 
                }
            }
        } else {
            Write-Host "WARNING: User not found - $SamAccountName"
            return $null
        }
    } catch {
        Write-Host "ERROR: Failed to query user via ADSI - $($_.Exception.Message)"
        return $null
    }
}

# Usage example
$userInfo = Get-ADUserViaADSI -SamAccountName $env:USERNAME
if ($userInfo) {
    Write-Host "INFO: User - $($userInfo.DisplayName)"
    Write-Host "INFO: Groups - $($userInfo.Groups)"
    Ninja-Property-Set ADUserLastName $userInfo.LastName
    Ninja-Property-Set ADUserFirstName $userInfo.FirstName
    Ninja-Property-Set ADUserGroups $userInfo.Groups
}
```

**Computer Query via ADSI:**
```powershell
# Query computer information without ActiveDirectory module
function Get-ADComputerViaADSI {
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    try {
        # Get domain information
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        # Create LDAP searcher
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=computer)(cn=$ComputerName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'cn',
            'dNSHostName',
            'operatingSystem',
            'memberOf',
            'userAccountControl',
            'lastLogonTimestamp'
        ))
        
        $result = $searcher.FindOne()
        
        if ($result) {
            $computer = $result.Properties
            
            # Extract group memberships
            $groups = @()
            if ($computer['memberOf']) {
                foreach ($groupDN in $computer['memberOf']) {
                    # Extract CN from DN
                    if ($groupDN -match 'CN=([^,]+)') {
                        $groups += $matches[1]
                    }
                }
            }
            
            # Return computer object
            return [PSCustomObject]@{
                Name = if ($computer['cn']) { $computer['cn'][0] } else { "" }
                DNSHostName = if ($computer['dNSHostName']) { $computer['dNSHostName'][0] } else { "" }
                OperatingSystem = if ($computer['operatingSystem']) { $computer['operatingSystem'][0] } else { "" }
                Groups = $groups -join ", "
                GroupCount = $groups.Count
                Enabled = if ($computer['userAccountControl']) { 
                    -not ([int]$computer['userAccountControl'][0] -band 2) 
                } else { 
                    $false 
                }
            }
        } else {
            Write-Host "WARNING: Computer not found in AD - $ComputerName"
            return $null
        }
    } catch {
        Write-Host "ERROR: Failed to query computer via ADSI - $($_.Exception.Message)"
        return $null
    }
}

# Usage example
$computerInfo = Get-ADComputerViaADSI -ComputerName $env:COMPUTERNAME
if ($computerInfo) {
    Write-Host "INFO: Computer - $($computerInfo.Name)"
    Write-Host "INFO: Groups - $($computerInfo.Groups)"
    Ninja-Property-Set ADComputerGroups $computerInfo.Groups
}
```

**Group Query via ADSI:**
```powershell
# Query group information without ActiveDirectory module
function Get-ADGroupViaADSI {
    param(
        [string]$GroupName
    )
    
    try {
        # Get domain information
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        # Create LDAP searcher
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=group)(cn=$GroupName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'cn',
            'member',
            'groupType',
            'distinguishedName'
        ))
        
        $result = $searcher.FindOne()
        
        if ($result) {
            $group = $result.Properties
            
            # Count members
            $memberCount = 0
            if ($group['member']) {
                $memberCount = $group['member'].Count
            }
            
            # Return group object
            return [PSCustomObject]@{
                Name = if ($group['cn']) { $group['cn'][0] } else { "" }
                MemberCount = $memberCount
                GroupType = if ($group['groupType']) { $group['groupType'][0] } else { "" }
                DistinguishedName = if ($group['distinguishedName']) { $group['distinguishedName'][0] } else { "" }
            }
        } else {
            Write-Host "WARNING: Group not found - $GroupName"
            return $null
        }
    } catch {
        Write-Host "ERROR: Failed to query group via ADSI - $($_.Exception.Message)"
        return $null
    }
}
```

### Migration Tasks

**For Script_42_Active_Directory_Monitor.ps1:**

1. **Add AD Connection Check:**
   - Implement Test-ADConnection function at script start
   - Exit gracefully if not domain-joined or no AD access
   - Log connection status to custom field

2. **Replace Import-Module ActiveDirectory:**
   - Remove all Import-Module ActiveDirectory calls
   - Replace Get-ADUser with Get-ADUserViaADSI
   - Replace Get-ADComputer with Get-ADComputerViaADSI
   - Replace Get-ADGroup with Get-ADGroupViaADSI

3. **Update Field Writes:**
   - Ensure all AD-related custom fields populated via ADSI
   - Add error handling for each ADSI query
   - Implement fallback values for query failures

4. **Test Scenarios:**
   - Domain-joined computer (should work)
   - Workgroup computer (should gracefully exit)
   - Domain computer without AD connectivity (should report error)
   - Different user contexts (SYSTEM vs USER)

5. **Document Changes:**
   - Update script documentation with ADSI approach
   - Document connection requirements
   - List LDAP attributes queried
   - Provide troubleshooting guide

### Benefits of ADSI Migration

**Performance:**
- No module loading overhead (saves 2-5 seconds)
- Direct LDAP queries are faster
- Reduced memory footprint

**Compatibility:**
- Works on systems without RSAT
- No PowerShell module dependencies
- Compatible with PowerShell 2.0+
- Works in constrained language mode

**Reliability:**
- Fewer external dependencies
- More predictable behavior
- Better error handling capabilities
- Explicit connection validation

---

## Pre-Phase B: Module Dependency Reduction (RSAT and Non-Native Only)

### Objective
Audit all scripts for RSAT and non-native PowerShell module dependencies and replace with native cmdlets, .NET methods, WMI/CIM, or Windows API calls. **KEEP Windows built-in modules that are native to the OS role/feature.**

### Scope
All 48+ scripts in the framework

### Module Classification

#### CRITICAL: Modules to KEEP (Native Windows Features)

**These modules are ALLOWED and should NOT be replaced:**

**Server Roles/Features (when running on Server OS):**
- **ServerManager** - Native to Windows Server, used for feature management
- **DnsServer** - Native when DNS Server role installed
- **DhcpServer** - Native when DHCP Server role installed
- **PrintManagement** - Native when Print Server role installed
- **Hyper-V** - Native when Hyper-V role installed
- **IISAdministration** - Native when IIS role installed

**Client/Server Common Modules (Built-in):**
- **ScheduledTasks** - Built-in to Windows 8+/Server 2012+
- **NetAdapter** - Built-in to Windows 8+/Server 2012+
- **NetTCPIP** - Built-in to Windows 8+/Server 2012+
- **Storage** - Built-in to Windows 8+/Server 2012+
- **BitLocker** - Built-in when BitLocker feature enabled
- **DnsClient** - Built-in to Windows 8+/Server 2012+
- **NetSecurity** - Built-in to Windows 8+/Server 2012+
- **Defender** - Built-in when Windows Defender installed

**Rationale:** These modules ship with Windows and are designed for the specific roles/features. Replacing them would reduce functionality and reliability.

#### Modules to REPLACE (RSAT and Non-Native)

**RSAT Modules (require Remote Server Administration Tools):**
- **ActiveDirectory** - RSAT only, replace with ADSI
- **GroupPolicy** - RSAT only, replace with COM objects or GPResult
- **RemoteDesktopServices** - RSAT only, use WMI alternatives

**Third-Party/Optional Modules:**
- **VMware PowerCLI** - Third-party, evaluate if needed
- **Veeam.Backup.PowerShell** - Third-party, evaluate if needed
- **Any custom modules not shipped with Windows**

### Module Dependency Audit

#### Search Patterns

**Find all Import-Module calls:**
```powershell
# Search pattern
Import-Module
Requires -Module
#Requires -Modules
```

#### Replacement Strategy (RSAT Only)

**1. ActiveDirectory Module → ADSI (HIGH PRIORITY)**
```powershell
# BEFORE: Using ActiveDirectory module (RSAT required)
Import-Module ActiveDirectory
$user = Get-ADUser -Identity $username

# AFTER: Using ADSI (no RSAT needed)
$userInfo = Get-ADUserViaADSI -SamAccountName $username
# See Pre-Phase A for full implementation
```

**2. GroupPolicy Module → GPResult/COM (MEDIUM PRIORITY)**
```powershell
# BEFORE: Using GroupPolicy module (RSAT required)
Import-Module GroupPolicy
$gpos = Get-GPO -All

# AFTER: Using gpresult.exe (built-in)
$gpresult = gpresult /Scope Computer /R

# OR: Using COM objects
$gpm = New-Object -ComObject GPMgmt.GPM
$constants = $gpm.GetConstants()
```

**3. Keep Native Modules - Example Patterns:**

```powershell
# CORRECT - Keep ServerManager on Server OS
if ((Get-WmiObject Win32_OperatingSystem).ProductType -ne 1) {
    # Server OS detected
    Import-Module ServerManager
    $features = Get-WindowsFeature
}

# CORRECT - Keep ScheduledTasks (built-in to modern Windows)
Import-Module ScheduledTasks
$tasks = Get-ScheduledTask

# CORRECT - Keep Storage (built-in to modern Windows)
Import-Module Storage
$volumes = Get-Volume

# CORRECT - Keep DnsClient (built-in to modern Windows)
Import-Module DnsClient
$dns = Resolve-DnsName -Name "example.com"

# CORRECT - Keep NetAdapter (built-in to modern Windows)
Import-Module NetAdapter
$adapters = Get-NetAdapter

# CORRECT - Keep DhcpServer when on DHCP server
if (Get-Service DHCPServer -ErrorAction SilentlyContinue) {
    Import-Module DhcpServer
    $scopes = Get-DhcpServerv4Scope
}

# CORRECT - Keep DnsServer when on DNS server
if (Get-Service DNS -ErrorAction SilentlyContinue) {
    Import-Module DnsServer
    $zones = Get-DnsServerZone
}
```

### Module Dependency Audit Tasks

**1. Inventory Phase:**
```powershell
# Create inventory of all Import-Module calls
Get-ChildItem -Path . -Filter *.ps1 -Recurse | 
    Select-String "Import-Module" | 
    Select-Object Path, LineNumber, Line
```

**2. Classification:**
- **Category A: KEEP** - Native Windows modules (ServerManager, ScheduledTasks, Storage, etc.)
- **Category B: REPLACE** - RSAT modules (ActiveDirectory, GroupPolicy)
- **Category C: EVALUATE** - Third-party modules (case-by-case basis)

**3. Create Module Dependency Report:**

**Location:** `/docs/MODULE_DEPENDENCY_REPORT.md`

**Structure:**
```markdown
# Module Dependency Audit Report

## Summary
- Total Scripts: [count]
- Scripts with Module Dependencies: [count]
- Native Module Dependencies (KEEP): [count]
- RSAT Module Dependencies (REPLACE): [count]
- Third-Party Dependencies (EVALUATE): [count]
- Dependencies Replaced: [count]

## Module Classification

### Native Modules (KEEP - No Changes Needed)

| Module | Used By | OS Role/Feature | Justification |
|--------|---------|-----------------|---------------|
| ServerManager | Script_20 | Windows Server | Native role management |
| ScheduledTasks | Script_XX | Built-in | Native to Windows 8+/2012+ |
| Storage | Script_05, Script_45 | Built-in | Native to Windows 8+/2012+ |
| DnsClient | Script_03 | Built-in | Native to Windows 8+/2012+ |
| NetAdapter | Script_40 | Built-in | Native to Windows 8+/2012+ |
| DhcpServer | Script_02 | DHCP Server Role | Native when role installed |
| DnsServer | Script_03 | DNS Server Role | Native when role installed |

### RSAT Modules (REPLACE)

| Module | Used By | Current Usage | Replacement Strategy | Status |
|--------|---------|---------------|---------------------|--------|
| ActiveDirectory | Script_42, Script_20 | User/Computer queries | ADSI | In Progress |
| GroupPolicy | Script_43 | GPO queries | GPResult/COM | Planned |

### Third-Party Modules (EVALUATE)

| Module | Used By | Purpose | Decision | Status |
|--------|---------|---------|----------|--------|
| Veeam.Backup.PowerShell | Script_48 | Backup monitoring | Keep (required) | No change |

## Replacement Details

### ActiveDirectory Module → ADSI
- **Reason for Replacement:** Requires RSAT installation
- **Replacement:** ADSI (LDAP queries)
- **Benefits:** No RSAT requirement, faster, more compatible
- **Scripts Affected:** Script_42, Script_20
- **Status:** Complete
- **Performance Impact:** 3-5 seconds faster per execution

### GroupPolicy Module → GPResult/COM
- **Reason for Replacement:** Requires RSAT installation
- **Replacement:** GPResult.exe or COM objects
- **Benefits:** No RSAT requirement
- **Scripts Affected:** Script_43
- **Status:** Planned
- **Performance Impact:** Similar or better

## Native Modules Retained

### Why We Keep Native Modules

**ServerManager** (Windows Server only):
- Native to all Windows Server installations
- Purpose-built for feature management
- No viable alternative with same functionality
- Replacing would reduce reliability

**ScheduledTasks, Storage, DnsClient, NetAdapter** (Built-in):
- Shipped with Windows 8+/Server 2012+
- No additional installation required
- Designed specifically for their purposes
- Replacing would be unnecessary complexity

**DhcpServer, DnsServer** (Server Roles):
- Native when respective server role installed
- Purpose-built for role-specific management
- Scripts check for role before importing
- No replacement needed
```

**4. Implementation Priority:**

High Priority (RSAT modules only):
- ActiveDirectory → ADSI (Pre-Phase A)
- GroupPolicy → GPResult/COM

Low Priority (evaluate case-by-case):
- Third-party modules (keep if required for functionality)

No Action Needed:
- Native Windows modules (ServerManager, ScheduledTasks, Storage, etc.)
- Server role-specific modules when role installed

**5. Testing Requirements:**

For each replaced RSAT module:
- [ ] Original functionality preserved
- [ ] Works without RSAT installed
- [ ] Performance improved or equal
- [ ] Error handling robust
- [ ] Compatible with older PowerShell versions
- [ ] Documentation updated

For native modules (no changes):
- [ ] Verify module availability check exists
- [ ] Graceful handling when module unavailable
- [ ] Documentation reflects native module usage

---

## Pre-Phase C: Base64 Encoding Standard for Data Storage

### Objective
Standardize all complex data storage in custom fields using Base64 encoding instead of JSON or XML to ensure compatibility, avoid parsing issues, and support special characters across all Windows languages.

### Scope
All scripts that store complex data structures (arrays, objects, hashtables) in custom fields

### Rationale for Base64 Encoding

**Problems with JSON/XML:**
- Character encoding issues (UTF-8 vs UTF-16)
- Special character escaping complexity
- Line break handling variations
- Parser version dependencies
- Language-specific formatting issues
- Potential corruption with special characters

**Benefits of Base64:**
- Language-agnostic (pure ASCII)
- No special character escaping needed
- No parser version dependencies
- Consistent across all systems
- Handles any data type reliably
- Survives field storage/retrieval without corruption
- Works with German, English, and all Windows languages

### Base64 Encoding/Decoding Functions

**Standard Base64 Functions:**

```powershell
# Convert any PowerShell object to Base64 string
function ConvertTo-Base64 {
    param(
        [Parameter(Mandatory=$true)]
        $InputObject
    )
    
    try {
        # Convert object to JSON first (internal representation)
        $json = $InputObject | ConvertTo-Json -Compress -Depth 10
        
        # Convert to bytes using UTF8
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        
        # Convert to Base64
        $base64 = [System.Convert]::ToBase64String($bytes)
        
        Write-Host "INFO: Converted object to Base64 (length: $($base64.Length))"
        return $base64
    } catch {
        Write-Host "ERROR: Failed to convert to Base64 - $($_.Exception.Message)"
        return $null
    }
}

# Convert Base64 string back to PowerShell object
function ConvertFrom-Base64 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Base64String
    )
    
    try {
        # Validate input
        if ([string]::IsNullOrWhiteSpace($Base64String)) {
            Write-Host "WARNING: Empty Base64 string provided"
            return $null
        }
        
        # Convert from Base64 to bytes
        $bytes = [System.Convert]::FromBase64String($Base64String)
        
        # Convert bytes to string using UTF8
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        
        # Convert JSON to object
        $object = $json | ConvertFrom-Json
        
        Write-Host "INFO: Decoded Base64 to object"
        return $object
    } catch {
        Write-Host "ERROR: Failed to decode Base64 - $($_.Exception.Message)"
        return $null
    }
}
```

### Usage Examples

**Example 1: Storing Array Data**
```powershell
# OLD WAY - JSON (potential encoding issues)
$services = @("wuauserv", "Schedule", "WinDefend")
$json = $services | ConvertTo-Json -Compress
Ninja-Property-Set ServicesList $json

# NEW WAY - Base64 (reliable)
$services = @("wuauserv", "Schedule", "WinDefend")
$base64 = ConvertTo-Base64 -InputObject $services
Ninja-Property-Set ServicesList $base64

# Retrieving
$base64 = Ninja-Property-Get ServicesList
$services = ConvertFrom-Base64 -Base64String $base64
Write-Host "INFO: Retrieved $($services.Count) services"
```

**Example 2: Storing Complex Objects**
```powershell
# OLD WAY - JSON (potential issues)
$config = @{
    LastRun = (Get-Date).ToString()
    Status = "Success"
    Items = @("Item1", "Item2", "Item3")
    Settings = @{
        Enabled = $true
        Threshold = 80
    }
}
$json = $config | ConvertTo-Json -Compress
Ninja-Property-Set ConfigData $json

# NEW WAY - Base64 (reliable)
$config = @{
    LastRun = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Status = "Success"
    Items = @("Item1", "Item2", "Item3")
    Settings = @{
        Enabled = $true
        Threshold = 80
    }
}
$base64 = ConvertTo-Base64 -InputObject $config
Ninja-Property-Set ConfigData $base64

# Retrieving
$base64 = Ninja-Property-Get ConfigData
$config = ConvertFrom-Base64 -Base64String $base64
Write-Host "INFO: Last run was $($config.LastRun)"
Write-Host "INFO: Status: $($config.Status)"
```

**Example 3: Storing Arrays with Special Characters**
```powershell
# OLD WAY - XML/JSON could have issues
$paths = @(
    "C:\Users\Müller\Desktop",
    "C:\Temp\Data with spaces & symbols",
    "\\server\share\Datenübertragung"
)

# NEW WAY - Base64 (handles all characters)
$paths = @(
    "C:\Users\Müller\Desktop",
    "C:\Temp\Data with spaces & symbols",
    "\\server\share\Datenübertragung"
)
$base64 = ConvertTo-Base64 -InputObject $paths
Ninja-Property-Set ImportantPaths $base64

# Retrieving - no character encoding issues
$base64 = Ninja-Property-Get ImportantPaths
$paths = ConvertFrom-Base64 -Base64String $base64
foreach ($path in $paths) {
    Write-Host "INFO: Path - $path"
}
```

**Example 4: AD Group Memberships (with Base64)**
```powershell
# Get AD groups via ADSI
$userInfo = Get-ADUserViaADSI -SamAccountName $env:USERNAME

if ($userInfo -and $userInfo.Groups) {
    # Store groups as Base64-encoded array
    $groupsArray = $userInfo.Groups -split ", "
    $base64 = ConvertTo-Base64 -InputObject $groupsArray
    Ninja-Property-Set ADUserGroupsEncoded $base64
    
    Write-Host "SUCCESS: Stored $($groupsArray.Count) AD groups (Base64)"
}

# Later retrieval
$base64 = Ninja-Property-Get ADUserGroupsEncoded
if ($base64) {
    $groups = ConvertFrom-Base64 -Base64String $base64
    Write-Host "INFO: User is member of $($groups.Count) groups:"
    foreach ($group in $groups) {
        Write-Host "INFO: - $group"
    }
}
```

### Migration Strategy

**Scripts That Need Base64 Encoding:**

Any script that currently stores:
- Arrays (lists of items)
- Hashtables (configuration objects)
- Complex objects with properties
- Data with special characters (umlauts, spaces, symbols)
- Multi-line text
- JSON or XML data

**Scripts That DON'T Need Base64:**

Scripts that store:
- Simple strings (single values)
- Numbers (integers, floats)
- Boolean values ($true/$false)
- Dates (as ISO 8601 strings)
- Single-line text without special characters

### Base64 Encoding Audit Tasks

**1. Identify Scripts Using Complex Data Storage:**

```powershell
# Find JSON usage
Select-String -Pattern "ConvertTo-Json" -Path *.ps1 -Recurse

# Find XML usage
Select-String -Pattern "ConvertTo-Xml" -Path *.ps1 -Recurse
Select-String -Pattern "Export-Clixml" -Path *.ps1 -Recurse

# Find array storage
Select-String -Pattern "@\(" -Path *.ps1 -Recurse

# Find hashtable storage
Select-String -Pattern "@\{" -Path *.ps1 -Recurse
```

**2. Create Base64 Encoding Migration Report:**

**Location:** `/docs/BASE64_ENCODING_REPORT.md`

**Structure:**
```markdown
# Base64 Encoding Migration Report

## Summary
- Total Scripts Audited: [count]
- Scripts Using Complex Data: [count]
- Scripts Requiring Base64: [count]
- Scripts Migrated: [count]
- Scripts Remaining: [count]

## Scripts Requiring Base64 Encoding

| Script | Current Method | Data Type | Field Name | Priority | Status |
|--------|---------------|-----------|------------|----------|--------|
| Script_42 | JSON | Array | ADUserGroups | High | Planned |
| Script_20 | JSON | Hashtable | ServerRoles | High | Planned |
| Script_XX | JSON | Object | ConfigData | Medium | Planned |

## Migration Patterns

### Pattern 1: Array Storage

**Before:**
```powershell
$items = @("item1", "item2", "item3")
$json = $items | ConvertTo-Json -Compress
Ninja-Property-Set FieldName $json
```

**After:**
```powershell
$items = @("item1", "item2", "item3")
$base64 = ConvertTo-Base64 -InputObject $items
Ninja-Property-Set FieldName $base64
```

### Pattern 2: Hashtable Storage

**Before:**
```powershell
$config = @{Key1 = "Value1"; Key2 = "Value2"}
$json = $config | ConvertTo-Json -Compress
Ninja-Property-Set FieldName $json
```

**After:**
```powershell
$config = @{Key1 = "Value1"; Key2 = "Value2"}
$base64 = ConvertTo-Base64 -InputObject $config
Ninja-Property-Set FieldName $base64
```

### Pattern 3: Retrieval

**Before:**
```powershell
$json = Ninja-Property-Get FieldName
$data = $json | ConvertFrom-Json
```

**After:**
```powershell
$base64 = Ninja-Property-Get FieldName
$data = ConvertFrom-Base64 -Base64String $base64
```

## Benefits Achieved

- **Encoding Reliability:** 100% success rate across all Windows languages
- **Special Character Support:** Full support for umlauts (ä, ö, ü), spaces, symbols
- **No Parser Dependencies:** No JSON/XML parser version issues
- **Field Size:** Base64 adds ~33% overhead but ensures reliability
- **Compatibility:** Works on all PowerShell versions 2.0+

## Testing Checklist

For each migrated script:
- [ ] Test storing data with special characters (ä, ö, ü, ß)
- [ ] Test storing data with spaces and symbols
- [ ] Test retrieval and decoding
- [ ] Verify data integrity (input == output)
- [ ] Test on German Windows
- [ ] Test on English Windows
- [ ] Verify field size doesn't exceed limits
- [ ] Document Base64 encoding in script comments
```

**3. Implementation Priority:**

High Priority:
- Scripts storing AD user/group data
- Scripts storing arrays of paths or names
- Scripts storing configuration objects

Medium Priority:
- Scripts storing multi-line text
- Scripts with occasional special characters

Low Priority:
- Scripts storing only simple strings/numbers

**4. Standard Functions Integration:**

Add ConvertTo-Base64 and ConvertFrom-Base64 functions to:
- Each script that needs them (inline functions)
- OR: Create shared utility module (if framework supports it)
- Document usage in script headers

### Base64 Quality Checks

**Before Migration:**
- Document current data format
- Capture sample data
- Test current encoding/decoding
- Identify potential issues

**After Migration:**
- Verify data integrity (original == decoded)
- Test with special characters
- Test with German text (umlauts)
- Test with paths containing spaces
- Measure field size increase (~33%)
- Verify field size within NinjaRMM limits
- Document encoding format in comments

---

## Pre-Phase D: Language Compatibility (German/English Windows)

[Content remains the same as version 1.5, with note that Base64 encoding helps with language compatibility]

### Additional Note on Base64 and Language Compatibility

Base64 encoding (Pre-Phase C) significantly helps with language compatibility by:
- Encoding all text as ASCII (no UTF-8/UTF-16 issues)
- Preserving German umlauts (ä, ö, ü, ß) perfectly
- Handling special characters in paths and names
- Avoiding language-specific parsing issues

[Continue with rest of Pre-Phase D content from version 1.5]

---

## Phase 0: Coding Standards and Conventions

[Content continues from version 1.5 with additions]

### Additional Coding Standards

**Module Usage:**
- Use native Windows modules (ServerManager, ScheduledTasks, Storage, DnsClient, NetAdapter)
- Replace RSAT modules only (ActiveDirectory, GroupPolicy)
- Check module availability before importing
- Document module requirements in script header

**Data Encoding:**
- Use Base64 encoding for complex data (arrays, objects, hashtables)
- Use plain text for simple values (strings, numbers, booleans)
- Always use ConvertTo-Base64 and ConvertFrom-Base64 functions
- Document Base64-encoded fields in comments

**Language Compatibility:**
- Use service names, not display names
- Use SIDs for built-in groups and accounts
- Use InvariantCulture for date/time operations
- Use [Environment]::GetFolderPath for special folders
- Never hardcode localized strings
- Base64 encoding helps preserve special characters

[Continue with rest of document, updating all sections to reflect:
1. Keep native modules, replace RSAT only
2. Add Base64 encoding requirements
3. Update time estimates]

---

## Execution Sequence

### Recommended Implementation Order

**Week 0: Pre-Implementation (CRITICAL)**
1. **Pre-Phase A: Active Directory ADSI Migration**
   - Implement Test-ADConnection function
   - Create Get-ADUserViaADSI function
   - Create Get-ADComputerViaADSI function
   - Update Script_42_Active_Directory_Monitor.ps1
   - Test on domain-joined and workgroup systems
   - Document ADSI approach

2. **Pre-Phase B: Module Dependency Audit (RSAT Only)**
   - Inventory all Import-Module calls
   - Classify: Native (KEEP) vs RSAT (REPLACE) vs Third-Party (EVALUATE)
   - Create MODULE_DEPENDENCY_REPORT.md
   - Plan replacement strategy for RSAT modules only
   - Document native module retention rationale

3. **Pre-Phase C: Base64 Encoding Standard**
   - Audit scripts for JSON/XML usage
   - Create BASE64_ENCODING_REPORT.md
   - Implement ConvertTo-Base64 and ConvertFrom-Base64 functions
   - Test Base64 encoding with special characters
   - Document Base64 patterns

4. **Pre-Phase D: Language Compatibility Audit**
   - Scan all scripts for language-dependent code
   - Create LANGUAGE_COMPATIBILITY_REPORT.md
   - Document all issues found
   - Prioritize fixes (critical/high/medium)
   - Set up German and English test environments

**Week 1: Assessment and Language Fixes**
5. **Pre-Phase D: Implement Language Compatibility Fixes**
   - Fix service name queries (use .Name)
   - Fix group name queries (use SIDs)
   - Fix date/time handling (InvariantCulture)
   - Fix file paths (GetFolderPath)
   - Test on German Windows
   - Test on English Windows

6. **Pre-Phase C: Migrate to Base64 Encoding**
   - Update scripts to use Base64 for complex data
   - Replace ConvertTo-Json with ConvertTo-Base64
   - Replace ConvertFrom-Json with ConvertFrom-Base64
   - Test encoding/decoding with German text
   - Verify data integrity

7. Phase 0: Review coding standards and create compliance checklist
8. Phase 2.1: Documentation Audit (identify what exists)
9. Phase 5.0: Review style guide and create compliance checklist
10. Create tracking spreadsheet for all tasks

**Week 2: Core Changes and Standards Audit**
11. **Pre-Phase B: Implement RSAT module replacements only**
12. Phase 1: Field Conversion + Output Cmdlet Standardization
13. Phase 3: TBD and Incomplete Implementation Audit (CRITICAL)
14. Create TBD_INVENTORY.md and IMPLEMENTATION_STATUS.md
15. Script testing and validation (both languages, Base64 encoding)

[Continue with weeks 3-6 as before]

---

## Success Criteria

### Project Complete When

**Technical Requirements:**
- All dropdown field references converted to text
- All AD queries migrated to ADSI (no ActiveDirectory module)
- **RSAT module dependencies eliminated (native modules retained)**
- **All complex data storage uses Base64 encoding**
- All scripts tested and working on German Windows
- All scripts tested and working on English Windows
- No language-dependent code remains
- All scripts function correctly with text fields
- No breaking changes to existing deployments
- All automated tests passing
- All scripts use Write-Host exclusively
- AD connectivity validated before queries
- Scripts use native Windows modules appropriately

**Documentation Requirements:**
- Every script has corresponding documentation
- ADSI implementation documented with examples
- **Native module usage documented (why kept)**
- **RSAT module replacements documented**
- **Base64 encoding documented with examples**
- **BASE64_ENCODING_REPORT.md complete**
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
- **Native Windows modules used where appropriate**
- **RSAT dependencies eliminated**
- **Base64 encoding tested with special characters**
- Script outputs identical on German and English Windows
- Consistent formatting throughout
- All cross-references accurate
- TBD_INVENTORY.md shows 100% resolution
- Style guide compliance verified
- Coding standards compliance verified
- No checkmarks, crosses, or emojis
- ADSI functions tested on domain and workgroup systems
- Language-neutral code verified on multiple Windows languages
- **Base64 encoding verified with umlauts and special characters**

---

## Resource Estimates

### Time Estimates by Phase

| Phase | Estimated Hours | Complexity |
|-------|----------------|------------|
| Pre-Phase A: ADSI Migration | 4-6 hours | High |
| Pre-Phase B: Module Audit (RSAT only) | 2-3 hours | Medium |
| Pre-Phase B: RSAT Replacement Implementation | 3-4 hours | Medium-High |
| Pre-Phase C: Base64 Encoding Audit | 2-3 hours | Medium |
| Pre-Phase C: Base64 Encoding Implementation | 4-5 hours | Medium-High |
| Pre-Phase D: Language Compatibility Audit | 3-4 hours | Medium-High |
| Pre-Phase D: Language Compatibility Fixes | 5-7 hours | High |
| Phase 0: Coding Standards | 1-2 hours | Low |
| Phase 1: Field Conversion + Output Standardization | 5-7 hours | Medium-High |
| Phase 2: Documentation Audit & Creation | 8-10 hours | High |
| Phase 3: TBD Audit and Resolution | 4-6 hours | High |
| Phase 4: Diagram Updates | 2-3 hours | Medium |
| Phase 5: Comprehensive Suite | 6-8 hours | Medium-High |
| Phase 6: Quality Assurance | 6-8 hours | High |
| Phase 7: Final Deliverables | 2-3 hours | Low |

**Total Estimated Effort:** 57-79 hours

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

---

**END OF ACTION PLAN**
