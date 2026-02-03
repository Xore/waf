# WAF Field Type Conversion & Documentation Completeness Plan

**Date:** February 3, 2026  
**Status:** Planning Phase  
**Priority:** High

---

## Executive Summary

This plan outlines the systematic conversion of all dropdown custom fields to text fields and ensures complete documentation coverage for all 48+ scripts in the Windows Automation Framework. The goal is to eliminate dropdown field dependencies, reduce PowerShell module dependencies, migrate Active Directory queries to ADSI, ensure language compatibility (German/English Windows), and create a comprehensive documentation suite following consistent style guidelines and coding standards.

---

## Pre-Phase A: Active Directory ADSI Migration

### Objective
Migrate Active Directory monitoring scripts from ActiveDirectory PowerShell module to native ADSI (Active Directory Services Interface) queries to eliminate module dependencies and improve performance.

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

## Pre-Phase B: Module Dependency Reduction

### Objective
Audit all scripts for PowerShell module dependencies and replace with native cmdlets, .NET methods, WMI/CIM, or Windows API calls where possible.

### Scope
All 48+ scripts in the framework

### Module Dependency Audit

#### Search Patterns

**Find all Import-Module calls:**
```powershell
# Search pattern
Import-Module
Requires -Module
#Requires -Modules
```

**Common modules to check:**
- ActiveDirectory (migrate to ADSI - see Pre-Phase A)
- ServerManager (replace with DISM/WMI)
- Storage (replace with WMI/CIM)
- NetAdapter (replace with WMI/CIM)
- DnsClient (replace with .NET)
- Hyper-V (keep if critical, but check alternatives)
- PrintManagement (replace with WMI)
- ScheduledTasks (replace with COM objects)

#### Replacement Strategies

**1. ActiveDirectory Module → ADSI**
- Already covered in Pre-Phase A
- Use LDAP queries via System.DirectoryServices

**2. ServerManager Module → DISM/WMI**
```powershell
# BEFORE: Using ServerManager module
Import-Module ServerManager
$features = Get-WindowsFeature | Where-Object {$_.Installed -eq $true}

# AFTER: Using DISM (faster, no module)
$features = dism /online /get-features /format:table | 
    Select-String "Enabled" | 
    ForEach-Object { $_.Line }

# OR: Using WMI (more scriptable)
$features = Get-WmiObject -Class Win32_ServerFeature | 
    Select-Object Name, ID
```

**3. Storage Module → WMI/CIM**
```powershell
# BEFORE: Using Storage module
Import-Module Storage
$disks = Get-Disk
$volumes = Get-Volume

# AFTER: Using CIM (built-in, faster)
$disks = Get-CimInstance -ClassName Win32_DiskDrive
$volumes = Get-CimInstance -ClassName Win32_Volume
```

**4. NetAdapter Module → WMI/CIM**
```powershell
# BEFORE: Using NetAdapter module
Import-Module NetAdapter
$adapters = Get-NetAdapter

# AFTER: Using WMI (no module needed)
$adapters = Get-WmiObject -Class Win32_NetworkAdapter | 
    Where-Object {$_.NetEnabled -eq $true}

# OR: Using CIM (preferred)
$adapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | 
    Where-Object {$_.IPEnabled -eq $true}
```

**5. DnsClient Module → .NET**
```powershell
# BEFORE: Using DnsClient module
Import-Module DnsClient
$dns = Resolve-DnsName -Name "example.com"

# AFTER: Using .NET (no module needed)
$dns = [System.Net.Dns]::GetHostEntry("example.com")

# OR: Using nslookup (legacy but reliable)
$dns = nslookup example.com | Select-String "Address:"
```

**6. PrintManagement Module → WMI**
```powershell
# BEFORE: Using PrintManagement module
Import-Module PrintManagement
$printers = Get-Printer

# AFTER: Using WMI (no module needed)
$printers = Get-WmiObject -Class Win32_Printer
```

**7. ScheduledTasks Module → COM/Task Scheduler**
```powershell
# BEFORE: Using ScheduledTasks module
Import-Module ScheduledTasks
$tasks = Get-ScheduledTask

# AFTER: Using Task Scheduler COM object
$taskScheduler = New-Object -ComObject Schedule.Service
$taskScheduler.Connect()
$tasks = $taskScheduler.GetFolder("\").GetTasks(0)

# OR: Using schtasks.exe
$tasks = schtasks /query /fo csv | ConvertFrom-Csv
```

### Module Dependency Audit Tasks

**1. Inventory Phase:**
```powershell
# Create inventory of all Import-Module calls
# Search all .ps1 files recursively
Get-ChildItem -Path . -Filter *.ps1 -Recurse | 
    Select-String "Import-Module" | 
    Select-Object Path, LineNumber, Line
```

**2. Classification:**
- **Category A:** Can be eliminated (use native alternatives)
- **Category B:** Can be replaced with lighter alternatives
- **Category C:** Must keep (no viable alternative)

**3. Create Module Dependency Report:**

**Location:** `/docs/MODULE_DEPENDENCY_REPORT.md`

**Structure:**
```markdown
# Module Dependency Audit Report

## Summary
- Total Scripts: [count]
- Scripts with Module Dependencies: [count]
- Module Dependencies Found: [count]
- Dependencies Eliminated: [count]
- Dependencies Remaining: [count]

## Module Dependencies by Script

| Script | Module | Current Usage | Replacement Strategy | Status |
|--------|--------|---------------|---------------------|--------|
| Script_42 | ActiveDirectory | User queries | ADSI | Replaced |
| Script_XX | Storage | Disk info | WMI/CIM | Planned |

## Replacement Strategies

### ActiveDirectory Module
- **Replacement:** ADSI (LDAP queries)
- **Benefits:** No RSAT requirement, faster
- **Scripts Affected:** Script_42, Script_20
- **Status:** Complete

### Storage Module
- **Replacement:** WMI/CIM queries
- **Benefits:** Built-in, no module load time
- **Scripts Affected:** Script_05, Script_45
- **Status:** In Progress

## Performance Impact

| Module | Load Time | Replacement Load Time | Time Saved |
|--------|-----------|----------------------|------------|
| ActiveDirectory | 3-5 sec | 0 sec (native) | 3-5 sec |
| Storage | 1-2 sec | 0 sec (native) | 1-2 sec |
| NetAdapter | 1-2 sec | 0 sec (native) | 1-2 sec |

## Compatibility Improvements

- **Systems without RSAT:** All scripts now work
- **Constrained Language Mode:** Compatible
- **PowerShell Version:** Compatible with PS 2.0+
- **Memory Footprint:** Reduced by XX MB average
```

**4. Implementation Priority:**

High Priority (implement immediately):
- ActiveDirectory → ADSI (Pre-Phase A)
- Storage → WMI/CIM
- NetAdapter → WMI/CIM
- DnsClient → .NET

Medium Priority (implement if time allows):
- ServerManager → DISM/WMI
- PrintManagement → WMI
- ScheduledTasks → COM

Low Priority (keep if complex):
- Hyper-V (if used)
- VMware PowerCLI (if used)
- Specialized modules with no alternatives

**5. Testing Requirements:**

For each replaced module:
- [ ] Original functionality preserved
- [ ] Performance improved or equal
- [ ] Error handling robust
- [ ] Works without module installed
- [ ] Compatible with older PowerShell versions
- [ ] Documentation updated

### Module Replacement Quality Checks

**Before Replacement:**
- Document current behavior
- Note all parameters used
- Capture sample output
- List all error scenarios

**After Replacement:**
- Verify same output format
- Test all code paths
- Verify error handling
- Performance benchmark
- Document any behavioral changes

---

## Pre-Phase C: Language Compatibility (German/English Windows)

### Objective
Ensure all scripts function correctly on both German and English Windows installations by avoiding language-dependent queries and using language-neutral approaches.

### Scope
All 48+ scripts in the framework

### Language Compatibility Requirements

**CRITICAL:** Scripts must work identically on:
- Windows (English - US, UK, International)
- Windows (German - Germany, Austria, Switzerland)
- Any other Windows language installation

### Common Language-Dependent Issues

#### 1. Service Name Queries
**PROBLEM:** Service display names are localized

```powershell
# WRONG - Display names are localized
Get-Service | Where-Object {$_.DisplayName -eq "Windows Update"}
# German: "Windows Update" vs English: "Windows Update" (same in this case)
# BUT: "Task Scheduler" (EN) vs "Aufgabenplanung" (DE)

# CORRECT - Use service names (always English)
Get-Service | Where-Object {$_.Name -eq "wuauserv"}
Get-Service | Where-Object {$_.Name -eq "Schedule"}
```

#### 2. Event Log Queries
**PROBLEM:** Event log names and sources can be localized

```powershell
# WRONG - Log names may be localized
Get-EventLog -LogName "Application" 
# Usually works, but better to use WMI

# CORRECT - Use WMI with LogFile property (language-neutral)
Get-WmiObject -Class Win32_NTLogEvent -Filter "LogFile='Application'"

# CORRECT - Use Get-WinEvent with XPath (language-neutral)
Get-WinEvent -FilterHashtable @{LogName='Application'; ID=1000}
```

#### 3. Windows Feature Names
**PROBLEM:** Feature display names are localized

```powershell
# WRONG - Display names are localized
Get-WindowsFeature | Where-Object {$_.DisplayName -eq "DNS Server"}
# German: "DNS-Server" vs English: "DNS Server"

# CORRECT - Use feature names (always English)
Get-WindowsFeature | Where-Object {$_.Name -eq "DNS"}

# BETTER - Use DISM with feature names
dism /online /get-featureinfo /featurename:DNS-Server-Full-Role
```

#### 4. Registry Value Parsing
**PROBLEM:** Some registry values contain localized text

```powershell
# WRONG - Parsing localized strings
$osName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
if ($osName -like "*Professional*") { }
# German: "Professional" vs "Professional" (same)
# BUT: "Home" vs "Home" (usually same, but not guaranteed)

# CORRECT - Use edition ID (language-neutral)
$editionID = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
if ($editionID -eq "Professional") { }
```

#### 5. WMI Class Property Values
**PROBLEM:** Some WMI properties return localized values

```powershell
# POTENTIALLY PROBLEMATIC - Status values may be localized in older systems
$service = Get-WmiObject Win32_Service -Filter "Name='wuauserv'"
if ($service.Status -eq "Running") { }
# Usually "Running" in all languages, but check StartMode, State properties

# CORRECT - Use State property (numeric or standard English)
$service = Get-WmiObject Win32_Service -Filter "Name='wuauserv'"
if ($service.State -eq "Running") { }  # Standard across languages

# BETTER - Use Started property (boolean)
if ($service.Started -eq $true) { }
```

#### 6. User and Group Names
**PROBLEM:** Built-in accounts and groups are localized

```powershell
# WRONG - Built-in group names are localized
$admins = Get-LocalGroupMember -Group "Administrators"
# German: "Administratoren" vs English: "Administrators"

# CORRECT - Use SID (language-neutral)
$adminsSID = "S-1-5-32-544"  # Built-in Administrators group
$admins = Get-LocalGroupMember -SID $adminsSID

# CORRECT - Use well-known SIDs for built-in accounts
# Administrators: S-1-5-32-544
# Users: S-1-5-32-545
# Guests: S-1-5-32-546
# Power Users: S-1-5-32-547
# SYSTEM: S-1-5-18
```

#### 7. Date and Time Formatting
**PROBLEM:** Date/time formats vary by locale

```powershell
# WRONG - Parsing locale-dependent date strings
$dateString = "01/02/2026"  # US: Jan 2, DE: Feb 1
$date = [DateTime]::Parse($dateString)

# CORRECT - Use ISO 8601 format (universal)
$dateString = "2026-02-01T00:00:00"
$date = [DateTime]::Parse($dateString)

# CORRECT - Use Get-Date with format specifier
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# CORRECT - Use invariant culture for parsing
$date = [DateTime]::ParseExact($dateString, "yyyy-MM-dd", 
    [System.Globalization.CultureInfo]::InvariantCulture)
```

#### 8. Folder Paths
**PROBLEM:** Special folder names are localized

```powershell
# WRONG - Hardcoded localized folder names
$desktop = "C:\Users\$env:USERNAME\Desktop"
# German: "Desktop" vs English: "Desktop" (same in modern Windows)
# BUT: Documents: "Dokumente" (DE) vs "Documents" (EN)

# CORRECT - Use environment variables
$desktop = [Environment]::GetFolderPath("Desktop")
$documents = [Environment]::GetFolderPath("MyDocuments")
$appData = [Environment]::GetFolderPath("ApplicationData")

# CORRECT - Use special folder enumeration
# Desktop, MyDocuments, ApplicationData, LocalApplicationData, etc.
```

### Language-Neutral Coding Patterns

#### Pattern 1: Service Queries
```powershell
# Language-neutral service check
function Test-ServiceRunning {
    param([string]$ServiceName)  # Use service name, not display name
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        return ($service.Status -eq 'Running')
    } catch {
        Write-Host "WARNING: Service not found - $ServiceName"
        return $false
    }
}

# Usage
if (Test-ServiceRunning -ServiceName "wuauserv") {
    Write-Host "INFO: Windows Update service is running"
}
```

#### Pattern 2: Group Membership by SID
```powershell
# Language-neutral group membership check
function Test-UserInGroup {
    param(
        [string]$Username,
        [string]$GroupSID  # Use SID instead of group name
    )
    
    try {
        $user = New-Object System.Security.Principal.NTAccount($Username)
        $userSID = $user.Translate([System.Security.Principal.SecurityIdentifier])
        
        $group = New-Object System.Security.Principal.SecurityIdentifier($GroupSID)
        $groupMembers = ([ADSI]"WinNT://./$group").psbase.Invoke("Members")
        
        foreach ($member in $groupMembers) {
            $memberPath = $member.GetType().InvokeMember("ADsPath", 'GetProperty', $null, $member, $null)
            if ($memberPath -match $Username) {
                return $true
            }
        }
        return $false
    } catch {
        Write-Host "ERROR: Failed to check group membership - $($_.Exception.Message)"
        return $false
    }
}

# Usage - Check if user is administrator
$adminGroupSID = "S-1-5-32-544"  # Built-in Administrators
if (Test-UserInGroup -Username $env:USERNAME -GroupSID $adminGroupSID) {
    Write-Host "INFO: User is administrator"
}
```

#### Pattern 3: Date Handling
```powershell
# Language-neutral date formatting
function Format-DateForLogging {
    param([DateTime]$Date)
    
    # ISO 8601 format - universal and sortable
    return $Date.ToString("yyyy-MM-dd HH:mm:ss", 
        [System.Globalization.CultureInfo]::InvariantCulture)
}

# Language-neutral date comparison
function Compare-FileAge {
    param(
        [string]$FilePath,
        [int]$MaxAgeDays
    )
    
    $file = Get-Item $FilePath -ErrorAction SilentlyContinue
    if (-not $file) { return $false }
    
    $age = (Get-Date) - $file.LastWriteTime
    return ($age.TotalDays -gt $MaxAgeDays)
}
```

#### Pattern 4: File Paths
```powershell
# Language-neutral special folder access
function Get-SpecialFolderPath {
    param(
        [System.Environment+SpecialFolder]$Folder
    )
    
    return [Environment]::GetFolderPath($Folder)
}

# Usage
$desktopPath = Get-SpecialFolderPath -Folder Desktop
$documentsPath = Get-SpecialFolderPath -Folder MyDocuments
$appDataPath = Get-SpecialFolderPath -Folder ApplicationData
$tempPath = Get-SpecialFolderPath -Folder InternetCache
```

### Language Compatibility Audit Tasks

**1. Audit All Scripts for Language Dependencies:**

**Search Patterns:**
```powershell
# Find potential language-dependent code
# Service display name usage
Select-String -Pattern "DisplayName" -Path *.ps1 -Recurse

# Hardcoded group names
Select-String -Pattern "\"Administrators\"" -Path *.ps1 -Recurse
Select-String -Pattern "\"Users\"" -Path *.ps1 -Recurse
Select-String -Pattern "Get-LocalGroupMember" -Path *.ps1 -Recurse

# Hardcoded folder paths
Select-String -Pattern "\\Desktop" -Path *.ps1 -Recurse
Select-String -Pattern "\\Documents" -Path *.ps1 -Recurse
Select-String -Pattern "\\Dokumente" -Path *.ps1 -Recurse

# Date parsing without culture
Select-String -Pattern "\[DateTime\]::Parse" -Path *.ps1 -Recurse
Select-String -Pattern "\.ToString\(" -Path *.ps1 -Recurse
```

**2. Create Language Compatibility Report:**

**Location:** `/docs/LANGUAGE_COMPATIBILITY_REPORT.md`

**Structure:**
```markdown
# Language Compatibility Audit Report

## Summary
- Total Scripts Audited: [count]
- Scripts with Language Dependencies: [count]
- Issues Found: [count]
- Issues Resolved: [count]
- Issues Remaining: [count]

## Test Environments
- Windows 10/11 English (en-US)
- Windows 10/11 German (de-DE)
- Windows Server 2019/2022 English (en-US)
- Windows Server 2019/2022 German (de-DE)

## Issues by Category

### Service Name Issues
| Script | Line | Issue | Resolution | Status |
|--------|------|-------|------------|--------|
| Script_XX | 42 | DisplayName query | Use .Name property | Fixed |

### Group Name Issues
| Script | Line | Issue | Resolution | Status |
|--------|------|-------|------------|--------|
| Script_XX | 15 | Hardcoded "Administrators" | Use SID S-1-5-32-544 | Fixed |

### Date/Time Formatting Issues
| Script | Line | Issue | Resolution | Status |
|--------|------|-------|------------|--------|
| Script_XX | 87 | Parse without culture | Use InvariantCulture | Fixed |

### File Path Issues
| Script | Line | Issue | Resolution | Status |
|--------|------|-------|------------|--------|
| Script_XX | 23 | Hardcoded Desktop path | Use GetFolderPath | Fixed |

## Well-Known SIDs Reference

### Built-in Groups
- Administrators: S-1-5-32-544
- Users: S-1-5-32-545
- Guests: S-1-5-32-546
- Power Users: S-1-5-32-547
- Account Operators: S-1-5-32-548
- Server Operators: S-1-5-32-549
- Print Operators: S-1-5-32-550
- Backup Operators: S-1-5-32-551
- Replicators: S-1-5-32-552

### Built-in Accounts
- SYSTEM: S-1-5-18
- LOCAL SERVICE: S-1-5-19
- NETWORK SERVICE: S-1-5-20
- Administrator (500): S-1-5-21-domain-500
- Guest (501): S-1-5-21-domain-501

## Testing Checklist

For each script:
- [ ] Tested on English Windows
- [ ] Tested on German Windows
- [ ] No hardcoded display names
- [ ] No hardcoded group names
- [ ] No hardcoded localized paths
- [ ] Date handling uses InvariantCulture
- [ ] Service queries use .Name property
- [ ] Group queries use SID or .NET methods
- [ ] All output identical on both languages
- [ ] Documentation updated
```

**3. Implementation Priority:**

Critical (fix immediately):
- Service display name queries → Use service names
- Hardcoded group names → Use SIDs
- Date parsing without culture → Use InvariantCulture

High Priority:
- Folder path hardcoding → Use GetFolderPath
- WMI localized property queries → Use language-neutral properties

Medium Priority:
- Event log queries → Verify language-neutrality
- Registry value parsing → Use EditionID where possible

**4. Testing Requirements:**

For each script modification:
- [ ] Test on Windows (English)
- [ ] Test on Windows (German)
- [ ] Compare outputs (must be identical)
- [ ] Verify all functionality preserved
- [ ] Document any platform-specific behavior
- [ ] Update documentation with language compatibility notes

### Language Compatibility Quality Checks

**Before Changes:**
- Run script on English Windows, capture output
- Run script on German Windows, capture output
- Document any differences
- Identify root cause of differences

**After Changes:**
- Run script on English Windows, capture output
- Run script on German Windows, capture output
- Verify outputs are identical
- Verify no functionality lost
- Performance test (should be same or better)

### Common Built-in Service Names (Language-Neutral)

```powershell
# Always use these service names (not display names)
$languageNeutralServices = @{
    "WindowsUpdate" = "wuauserv"
    "TaskScheduler" = "Schedule"
    "WindowsDefender" = "WinDefend"
    "WindowsFirewall" = "MpsSvc"
    "BITS" = "BITS"
    "RemoteRegistry" = "RemoteRegistry"
    "DNS" = "DNS"
    "DHCP" = "DHCPServer"
    "IIS" = "W3SVC"
    "MSSQL" = "MSSQLSERVER"
    "EventLog" = "EventLog"
    "PrintSpooler" = "Spooler"
    "RemoteDesktop" = "TermService"
    "VMTools" = "VMTools"
    "VSS" = "VSS"
}
```

---

## Phase 0: Coding Standards and Conventions

### Objective
Establish and enforce consistent coding standards across all PowerShell scripts in the framework.

### PowerShell Output Standards

**CRITICAL:** All scripts must use standardized output cmdlets for consistency and proper integration with NinjaRMM.

#### Output Cmdlet Usage Rules

**REQUIRED: Use Write-Host Exclusively**

All script output must use `Write-Host` for status messages, results, and logging.

**PROHIBITED: Do Not Use:**
- `Write-Output` - Reserved for pipeline data
- `Write-Error` - Not compatible with framework standards
- `Write-Warning` - Not compatible with framework standards
- `Write-Verbose` - Not compatible with framework standards
- `Write-Debug` - Not compatible with framework standards
- `Write-Information` - Not compatible with framework standards

**Standard Output Patterns:**

```powershell
# SUCCESS messages
Write-Host "SUCCESS: Operation completed successfully"
Write-Host "SUCCESS: Field updated - FieldName: Value"

# ERROR messages
Write-Host "ERROR: Operation failed - Reason"
Write-Host "ERROR: $($_.Exception.Message)"

# INFO messages
Write-Host "INFO: Processing step X of Y"
Write-Host "INFO: Current value: $variable"

# STATUS messages
Write-Host "Starting Script_XX - [Script Name]"
Write-Host "Completed Script_XX - [Script Name]"
```

**Examples of Correct Usage:**

```powershell
try {
    Write-Host "Starting Risk Classifier"
    
    # Processing logic
    $result = Get-SomeData
    Write-Host "INFO: Retrieved $($result.Count) items"
    
    # Update fields
    Ninja-Property-Set FieldName $value
    Write-Host "SUCCESS: Field updated - FieldName: $value"
    
    Write-Host "SUCCESS: Risk classification completed"
    exit 0
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host "ERROR: Script execution failed"
    exit 1
}
```

**Examples of Incorrect Usage (DO NOT USE):**

```powershell
# WRONG - Do not use Write-Error
Write-Error "Something went wrong"  # PROHIBITED

# WRONG - Do not use Write-Warning
Write-Warning "This is a warning"  # PROHIBITED

# WRONG - Do not use Write-Verbose
Write-Verbose "Detailed information"  # PROHIBITED

# WRONG - Do not use Write-Output for logging
Write-Output "Status message"  # PROHIBITED for logging

# CORRECT - Use Write-Host instead
Write-Host "ERROR: Something went wrong"
Write-Host "WARNING: This is a warning"
Write-Host "INFO: Detailed information"
```

#### Audit Task: Output Cmdlet Standardization

**Search and Replace Patterns:**

1. Find all instances of prohibited cmdlets:
   - `Write-Error`
   - `Write-Warning`
   - `Write-Verbose`
   - `Write-Debug`
   - `Write-Information`
   - Inappropriate `Write-Output` usage

2. Replace with appropriate `Write-Host` equivalents:
   - `Write-Error "text"` → `Write-Host "ERROR: text"`
   - `Write-Warning "text"` → `Write-Host "WARNING: text"`
   - `Write-Verbose "text"` → `Write-Host "INFO: text"`
   - `Write-Debug "text"` → `Write-Host "DEBUG: text"`

3. Document conversion in script comments

**Quality Check:**
- [ ] No Write-Error in any script
- [ ] No Write-Warning in any script
- [ ] No Write-Verbose in any script
- [ ] No Write-Debug in any script
- [ ] No Write-Information in any script
- [ ] All logging uses Write-Host
- [ ] Consistent message prefixes (SUCCESS, ERROR, INFO, WARNING, DEBUG)

### Additional Coding Standards

**Error Handling:**
```powershell
try {
    # Script logic
    Write-Host "SUCCESS: Operation completed"
    exit 0
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
```

**Exit Codes:**
- `exit 0` - Success
- `exit 1` - General error
- `exit 2` - Configuration error (if needed)

**Variable Naming:**
- Use PascalCase for custom field names: `$OPSHealthScore`
- Use camelCase for local variables: `$healthScore`, `$dataValue`
- Use descriptive names, avoid single letters except for loops

**Comments:**
- No checkmark or cross characters in comments
- No emojis in code or comments
- Use clear, technical language
- Document complex logic with inline comments

**Module Usage:**
- Avoid Import-Module where native alternatives exist
- Document justification if module import is required
- Test scripts work without optional modules installed

**Language Compatibility:**
- Use service names, not display names
- Use SIDs for built-in groups and accounts
- Use InvariantCulture for date/time operations
- Use [Environment]::GetFolderPath for special folders
- Never hardcode localized strings

[Rest of the document continues as in version 1.4, with updated sections noting language compatibility requirements throughout]

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

2. **Pre-Phase B: Module Dependency Audit**
   - Inventory all Import-Module calls
   - Create MODULE_DEPENDENCY_REPORT.md
   - Classify dependencies (eliminate/replace/keep)
   - Plan replacement strategy for each module

3. **Pre-Phase C: Language Compatibility Audit**
   - Scan all scripts for language-dependent code
   - Create LANGUAGE_COMPATIBILITY_REPORT.md
   - Document all issues found
   - Prioritize fixes (critical/high/medium)
   - Set up German and English test environments

**Week 1: Assessment and Language Fixes**
4. **Pre-Phase C: Implement Language Compatibility Fixes**
   - Fix service name queries (use .Name)
   - Fix group name queries (use SIDs)
   - Fix date/time handling (InvariantCulture)
   - Fix file paths (GetFolderPath)
   - Test on German Windows
   - Test on English Windows

5. Phase 0: Review coding standards and create compliance checklist
6. Phase 2.1: Documentation Audit (identify what exists)
7. Phase 5.0: Review style guide and create compliance checklist
8. Create tracking spreadsheet for all tasks
9. Set up testing environment (German + English Windows)

**Week 2: Core Changes and Standards Audit**
10. **Pre-Phase B: Implement module replacements** (priority dependencies)
11. Phase 1: Field Conversion + Output Cmdlet Standardization (update all scripts)
12. Phase 3: TBD and Incomplete Implementation Audit (CRITICAL)
13. Create TBD_INVENTORY.md and IMPLEMENTATION_STATUS.md
14. Script testing and validation (both languages)

**Week 3: Documentation Creation and TBD Resolution**
15. Phase 2.2: Create Missing Documentation (fill gaps, follow style guide)
16. Phase 2.3: Document Conditions with three-layer documentation
17. Phase 3.3: Document or implement all TBD items
18. Initial review of created documentation for style compliance

**Week 4: Visual and Reference Materials**
19. Phase 4: Update Diagrams (visual representation)
20. Phase 5.1-5.2: Quick References and Training Docs
21. Phase 5.3: README files
22. Verify all TBD items resolved before proceeding
23. Style guide and coding standards compliance check

**Week 5: Index Creation and Quality Assurance**
24. Phase 5.4: Create All Index Documents (AFTER TBD resolution)
25. Phase 6: Complete QA checks (including coding standards and language testing)
26. Fix identified issues
27. Second round of testing (both languages)
28. Final style guide and coding standards compliance verification

**Week 6: Finalization**
29. Phase 7: Create final deliverables
30. Final review and approval
31. Repository cleanup and organization

---

## Success Criteria

### Project Complete When

**Technical Requirements:**
- All dropdown field references converted to text
- All AD queries migrated to ADSI (no ActiveDirectory module)
- Module dependencies minimized (replacements implemented)
- **All scripts tested and working on German Windows**
- **All scripts tested and working on English Windows**
- **No language-dependent code remains**
- All scripts function correctly with text fields
- No breaking changes to existing deployments
- All automated tests passing
- All scripts use Write-Host exclusively (no Write-Error, Write-Warning, etc.)
- AD connectivity validated before queries
- Scripts work without optional modules installed

**Documentation Requirements:**
- Every script has corresponding documentation
- ADSI implementation documented with examples
- Module dependency replacements documented
- **Language compatibility documented for each script**
- **LANGUAGE_COMPATIBILITY_REPORT.md complete**
- All compound conditions documented with THREE representations
- All diagrams reflect current state
- Complete index and reference suite exists
- 100% documentation coverage verified
- All quality checks passed
- Zero unresolved TBD items
- All documentation follows established style guide
- Coding standards documentation complete
- MODULE_DEPENDENCY_REPORT.md complete and accurate

**Quality Requirements:**
- No broken links in any documentation
- All code examples tested and working
- All code examples use Write-Host only
- No PowerShell module dependencies where alternatives exist
- **Script outputs identical on German and English Windows**
- Consistent formatting throughout
- Professional presentation quality
- All cross-references accurate
- Implementation status clearly documented
- TBD_INVENTORY.md shows 100% resolution
- Style guide compliance verified for all documents
- Coding standards compliance verified for all scripts
- No checkmarks, crosses, or emojis in code or documentation
- ADSI functions tested on domain and workgroup systems
- **Language-neutral code verified on multiple Windows languages**

---

## Resource Estimates

### Time Estimates by Phase

| Phase | Estimated Hours | Complexity |
|-------|----------------|------------|
| Pre-Phase A: ADSI Migration | 4-6 hours | High |
| Pre-Phase B: Module Dependency Audit | 3-4 hours | Medium-High |
| Pre-Phase B: Module Replacement Implementation | 4-6 hours | High |
| Pre-Phase C: Language Compatibility Audit | 3-4 hours | Medium-High |
| Pre-Phase C: Language Compatibility Fixes | 5-7 hours | High |
| Phase 0: Coding Standards | 1-2 hours | Low |
| Phase 1: Field Conversion + Output Standardization | 5-7 hours | Medium-High |
| Phase 2: Documentation Audit & Creation | 8-10 hours | High |
| Phase 3: TBD Audit and Resolution | 4-6 hours | High |
| Phase 4: Diagram Updates | 2-3 hours | Medium |
| Phase 5: Comprehensive Suite | 6-8 hours | Medium-High |
| Phase 6: Quality Assurance | 6-8 hours | High |
| Phase 7: Final Deliverables | 2-3 hours | Low |

**Total Estimated Effort:** 53-74 hours

### Required Tools

- PowerShell ISE or VS Code
- Git for version control
- Markdown editor with style checking
- Diagram creation tool (Draw.io, Mermaid, etc.)
- NinjaOne test instance
- Documentation review tools
- Text search tools (grep, ripgrep, or IDE search)
- Markdown linter for style consistency
- PowerShell script analyzer
- **Domain-joined test system** (for ADSI testing)
- **Workgroup test system** (for graceful exit testing)
- **German Windows test system** (VM or physical)
- **English Windows test system** (VM or physical)

---

## Risk Management

### Potential Risks

1. **Breaking Changes Risk**
   - Mitigation: Extensive testing before deployment
   - Backup: Version control and rollback procedures

2. **Documentation Drift Risk**
   - Mitigation: Include documentation in code review process
   - Control: Automated documentation validation

3. **Time Overrun Risk**
   - Mitigation: Phased approach allows adjustment
   - Buffer: 20-30% time buffer included

4. **Incomplete Coverage Risk**
   - Mitigation: Automated completeness checks
   - Validation: Multiple review passes

5. **Hidden TBD Items Risk**
   - Mitigation: Comprehensive search using multiple patterns
   - Validation: Manual review of all files
   - Control: TBD_INVENTORY.md as single source of truth

6. **Style Inconsistency Risk**
   - Mitigation: Clear style guide and reference documents
   - Validation: Automated linting where possible
   - Control: Style compliance checklist for each document

7. **Coding Standards Non-Compliance Risk**
   - Mitigation: Automated script analysis for prohibited cmdlets
   - Validation: Manual code review
   - Control: Coding standards document and compliance checklist

8. **ADSI Migration Compatibility Risk**
   - Mitigation: Test on multiple system types (domain/workgroup)
   - Validation: Verify behavior matches original functionality
   - Control: Comprehensive test scenarios documented
   - Fallback: Keep module-based version as reference

9. **Module Replacement Regression Risk**
   - Mitigation: Preserve original behavior documentation
   - Validation: Side-by-side testing before/after
   - Control: Regression test suite for critical functions
   - Rollback: Version control allows quick revert

10. **Language Compatibility Risk**
    - Mitigation: Test all scripts on both German and English Windows
    - Validation: Compare outputs byte-by-byte for differences
    - Control: Language compatibility checklist for each script
    - Documentation: Clear guidelines for language-neutral code
    - Fallback: German and English test VMs available for validation

---

## Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-03 | 1.0 | WAF Team | Initial action plan created |
| 2026-02-03 | 1.1 | WAF Team | Added Phase 3 for TBD audit, moved index creation to after TBD resolution |
| 2026-02-03 | 1.2 | WAF Team | Enhanced compound condition documentation with three-layer approach, added comprehensive style guide requirements |
| 2026-02-03 | 1.3 | WAF Team | Added Phase 0 for coding standards, Write-Host requirement, prohibited cmdlet audit and conversion |
| 2026-02-03 | 1.4 | WAF Team | Added Pre-Phase A (ADSI migration for AD queries) and Pre-Phase B (module dependency reduction audit and replacement) |
| 2026-02-03 | 1.5 | WAF Team | Added Pre-Phase C (German/English Windows language compatibility audit and fixes) |

---

## Approval and Sign-off

**Plan Reviewed By:** _______________  
**Date:** _______________  
**Approved By:** _______________  
**Date:** _______________

---

**END OF ACTION PLAN**
