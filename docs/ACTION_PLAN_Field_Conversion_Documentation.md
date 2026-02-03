# WAF Field Type Conversion & Documentation Completeness Plan

**Date:** February 3, 2026  
**Status:** Planning Phase  
**Priority:** High

---

## Executive Summary

This plan outlines the systematic conversion of all dropdown custom fields to text fields and ensures complete documentation coverage for all 48+ scripts in the Windows Automation Framework. The goal is to eliminate dropdown field dependencies, reduce RSAT and non-native PowerShell module dependencies, migrate Active Directory queries to ADSI LDAP:// queries exclusively, standardize data encoding with Base64, ensure language compatibility (German/English Windows), and create a comprehensive documentation suite following consistent style guidelines and coding standards.

---

## Pre-Phase A: Active Directory ADSI Migration (LDAP:// Only)

### Objective
Migrate Active Directory monitoring scripts from ActiveDirectory PowerShell module to native ADSI using **LDAP:// queries exclusively** to eliminate RSAT module dependencies and improve performance.

**CRITICAL:** All ADSI queries must use the **LDAP://** protocol. No WinNT://, GC://, or other providers.

### Scope

**Primary Script:**
- Script_42_Active_Directory_Monitor.ps1

**Related Scripts (check for AD dependencies):**
- Script_20_Server_Role_Identifier.ps1
- Script_43_Group_Policy_Monitor.ps1
- Any other scripts querying AD user/computer information

### Migration Requirements

#### AD Information to Query via ADSI LDAP://

**User Information:**
- Last Name (surname / sn)
- First Name (givenName)
- Display Name (displayName)
- User Principal Name (userPrincipalName)
- Group Memberships (memberOf)
- Account Status (userAccountControl)
- Last Logon (lastLogonTimestamp)
- SAM Account Name (sAMAccountName)

**Computer Information:**
- Computer Name (cn)
- DNS Host Name (dNSHostName)
- Operating System (operatingSystem)
- Operating System Version (operatingSystemVersion)
- Group Memberships (memberOf)
- Last Logon (lastLogonTimestamp)
- Computer Account Status (userAccountControl)

**Group Information:**
- Group Name (cn)
- Group Members (member)
- Group Type (groupType)
- Group Scope (groupType values)
- Distinguished Name (distinguishedName)
- SAM Account Name (sAMAccountName)

### ADSI LDAP:// Implementation Pattern

**CRITICAL: Always use LDAP:// protocol for all ADSI queries**

**Connection Validation:**
```powershell
# Check Active Directory connectivity using LDAP:// protocol
function Test-ADConnection {
    try {
        # Use LDAP:// protocol to connect to RootDSE
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        if ([string]::IsNullOrEmpty($defaultNamingContext)) {
            Write-Host "ERROR: Unable to connect to Active Directory via LDAP"
            return $false
        }
        
        Write-Host "INFO: Active Directory LDAP connection established"
        Write-Host "INFO: Default naming context: $defaultNamingContext"
        return $true
    } catch {
        Write-Host "ERROR: Active Directory LDAP connection failed - $($_.Exception.Message)"
        return $false
    }
}

# Always check LDAP connection before AD queries
if (-not (Test-ADConnection)) {
    Write-Host "ERROR: Cannot proceed without Active Directory LDAP connection"
    exit 1
}
```

**User Query via ADSI LDAP://:**
```powershell
# Query user information using LDAP:// protocol only
function Get-ADUserViaADSI {
    param(
        [string]$SamAccountName
    )
    
    try {
        # Get domain information using LDAP://
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        # Create LDAP searcher
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        # Use LDAP:// protocol for SearchRoot
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=user)(objectCategory=person)(sAMAccountName=$SamAccountName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'givenName',
            'sn',
            'displayName',
            'userPrincipalName',
            'sAMAccountName',
            'memberOf',
            'userAccountControl',
            'lastLogonTimestamp',
            'mail',
            'distinguishedName'
        ))
        
        # Set search scope
        $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        
        $result = $searcher.FindOne()
        
        if ($result) {
            $user = $result.Properties
            
            # Extract group memberships from memberOf attribute
            $groups = @()
            if ($user['memberOf']) {
                foreach ($groupDN in $user['memberOf']) {
                    # Extract CN from DN (e.g., "CN=Domain Admins,CN=Users,DC=domain,DC=com")
                    if ($groupDN -match 'CN=([^,]+)') {
                        $groups += $matches[1]
                    }
                }
            }
            
            # Return user object
            return [PSCustomObject]@{
                SamAccountName = if ($user['sAMAccountName']) { $user['sAMAccountName'][0] } else { "" }
                FirstName = if ($user['givenName']) { $user['givenName'][0] } else { "" }
                LastName = if ($user['sn']) { $user['sn'][0] } else { "" }
                DisplayName = if ($user['displayName']) { $user['displayName'][0] } else { "" }
                UserPrincipalName = if ($user['userPrincipalName']) { $user['userPrincipalName'][0] } else { "" }
                EmailAddress = if ($user['mail']) { $user['mail'][0] } else { "" }
                DistinguishedName = if ($user['distinguishedName']) { $user['distinguishedName'][0] } else { "" }
                Groups = $groups -join ", "
                GroupCount = $groups.Count
                GroupsArray = $groups
                Enabled = if ($user['userAccountControl']) { 
                    # Check if account is disabled (bit 2)
                    -not ([int]$user['userAccountControl'][0] -band 2) 
                } else { 
                    $false 
                }
            }
        } else {
            Write-Host "WARNING: User not found via LDAP - $SamAccountName"
            return $null
        }
    } catch {
        Write-Host "ERROR: Failed to query user via LDAP - $($_.Exception.Message)"
        return $null
    }
}

# Usage example with Base64 encoding for groups
$userInfo = Get-ADUserViaADSI -SamAccountName $env:USERNAME
if ($userInfo) {
    Write-Host "INFO: User - $($userInfo.DisplayName)"
    Write-Host "INFO: Groups - $($userInfo.GroupCount) memberships"
    
    # Store simple fields directly
    Ninja-Property-Set ADUserLastName $userInfo.LastName
    Ninja-Property-Set ADUserFirstName $userInfo.FirstName
    Ninja-Property-Set ADUserEmail $userInfo.EmailAddress
    
    # Store groups array as Base64
    if ($userInfo.GroupsArray -and $userInfo.GroupsArray.Count -gt 0) {
        $groupsBase64 = ConvertTo-Base64 -InputObject $userInfo.GroupsArray
        Ninja-Property-Set ADUserGroupsEncoded $groupsBase64
        Write-Host "SUCCESS: Stored $($userInfo.GroupCount) groups as Base64"
    }
}
```

**Computer Query via ADSI LDAP://:**
```powershell
# Query computer information using LDAP:// protocol only
function Get-ADComputerViaADSI {
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    try {
        # Get domain information using LDAP://
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        # Create LDAP searcher
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        # Use LDAP:// protocol for SearchRoot
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=computer)(cn=$ComputerName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'cn',
            'dNSHostName',
            'sAMAccountName',
            'operatingSystem',
            'operatingSystemVersion',
            'memberOf',
            'userAccountControl',
            'lastLogonTimestamp',
            'distinguishedName',
            'whenCreated'
        ))
        
        # Set search scope
        $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        
        $result = $searcher.FindOne()
        
        if ($result) {
            $computer = $result.Properties
            
            # Extract group memberships from memberOf attribute
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
                SamAccountName = if ($computer['sAMAccountName']) { $computer['sAMAccountName'][0] } else { "" }
                DNSHostName = if ($computer['dNSHostName']) { $computer['dNSHostName'][0] } else { "" }
                OperatingSystem = if ($computer['operatingSystem']) { $computer['operatingSystem'][0] } else { "" }
                OSVersion = if ($computer['operatingSystemVersion']) { $computer['operatingSystemVersion'][0] } else { "" }
                DistinguishedName = if ($computer['distinguishedName']) { $computer['distinguishedName'][0] } else { "" }
                Groups = $groups -join ", "
                GroupCount = $groups.Count
                GroupsArray = $groups
                Enabled = if ($computer['userAccountControl']) { 
                    # Check if account is disabled (bit 2)
                    -not ([int]$computer['userAccountControl'][0] -band 2) 
                } else { 
                    $false 
                }
            }
        } else {
            Write-Host "WARNING: Computer not found in AD via LDAP - $ComputerName"
            return $null
        }
    } catch {
        Write-Host "ERROR: Failed to query computer via LDAP - $($_.Exception.Message)"
        return $null
    }
}

# Usage example with Base64 encoding
$computerInfo = Get-ADComputerViaADSI -ComputerName $env:COMPUTERNAME
if ($computerInfo) {
    Write-Host "INFO: Computer - $($computerInfo.Name)"
    Write-Host "INFO: OS - $($computerInfo.OperatingSystem)"
    Write-Host "INFO: Groups - $($computerInfo.GroupCount) memberships"
    
    # Store simple fields directly
    Ninja-Property-Set ADComputerName $computerInfo.Name
    Ninja-Property-Set ADComputerOS $computerInfo.OperatingSystem
    Ninja-Property-Set ADComputerDNS $computerInfo.DNSHostName
    
    # Store groups array as Base64
    if ($computerInfo.GroupsArray -and $computerInfo.GroupsArray.Count -gt 0) {
        $groupsBase64 = ConvertTo-Base64 -InputObject $computerInfo.GroupsArray
        Ninja-Property-Set ADComputerGroupsEncoded $groupsBase64
        Write-Host "SUCCESS: Stored $($computerInfo.GroupCount) groups as Base64"
    }
}
```

**Group Query via ADSI LDAP://:**
```powershell
# Query group information using LDAP:// protocol only
function Get-ADGroupViaADSI {
    param(
        [string]$GroupName
    )
    
    try {
        # Get domain information using LDAP://
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        # Create LDAP searcher
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        # Use LDAP:// protocol for SearchRoot
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=group)(cn=$GroupName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'cn',
            'sAMAccountName',
            'member',
            'groupType',
            'distinguishedName',
            'description'
        ))
        
        # Set search scope
        $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        
        $result = $searcher.FindOne()
        
        if ($result) {
            $group = $result.Properties
            
            # Extract member DNs
            $members = @()
            if ($group['member']) {
                foreach ($memberDN in $group['member']) {
                    # Extract CN from DN
                    if ($memberDN -match 'CN=([^,]+)') {
                        $members += $matches[1]
                    }
                }
            }
            
            # Determine group scope from groupType
            $groupType = if ($group['groupType']) { [int]$group['groupType'][0] } else { 0 }
            $groupScope = switch ($groupType -band 0x0000000F) {
                2 { "Global" }
                4 { "DomainLocal" }
                8 { "Universal" }
                default { "Unknown" }
            }
            
            $isSecurityGroup = ($groupType -band 0x80000000) -ne 0
            
            # Return group object
            return [PSCustomObject]@{
                Name = if ($group['cn']) { $group['cn'][0] } else { "" }
                SamAccountName = if ($group['sAMAccountName']) { $group['sAMAccountName'][0] } else { "" }
                Description = if ($group['description']) { $group['description'][0] } else { "" }
                DistinguishedName = if ($group['distinguishedName']) { $group['distinguishedName'][0] } else { "" }
                GroupScope = $groupScope
                IsSecurityGroup = $isSecurityGroup
                MemberCount = $members.Count
                Members = $members -join ", "
                MembersArray = $members
            }
        } else {
            Write-Host "WARNING: Group not found via LDAP - $GroupName"
            return $null
        }
    } catch {
        Write-Host "ERROR: Failed to query group via LDAP - $($_.Exception.Message)"
        return $null
    }
}

# Usage example
$groupInfo = Get-ADGroupViaADSI -GroupName "Domain Admins"
if ($groupInfo) {
    Write-Host "INFO: Group - $($groupInfo.Name)"
    Write-Host "INFO: Scope - $($groupInfo.GroupScope)"
    Write-Host "INFO: Members - $($groupInfo.MemberCount)"
    Write-Host "INFO: Security Group - $($groupInfo.IsSecurityGroup)"
}
```

**Query Current User's Groups via LDAP://:**
```powershell
# Get current user's group memberships using LDAP:// only
function Get-CurrentUserGroups {
    try {
        # Get current user's SAM account name
        $samAccountName = $env:USERNAME
        
        # Query user via LDAP://
        $userInfo = Get-ADUserViaADSI -SamAccountName $samAccountName
        
        if ($userInfo -and $userInfo.GroupsArray) {
            Write-Host "INFO: Current user is member of $($userInfo.GroupCount) groups"
            return $userInfo.GroupsArray
        } else {
            Write-Host "WARNING: No group memberships found for current user"
            return @()
        }
    } catch {
        Write-Host "ERROR: Failed to get current user groups - $($_.Exception.Message)"
        return @()
    }
}

# Usage
$userGroups = Get-CurrentUserGroups
if ($userGroups.Count -gt 0) {
    # Store as Base64
    $groupsBase64 = ConvertTo-Base64 -InputObject $userGroups
    Ninja-Property-Set CurrentUserGroups $groupsBase64
    
    # Also log for visibility
    foreach ($group in $userGroups) {
        Write-Host "INFO: Member of - $group"
    }
}
```

### LDAP:// Query Best Practices

**1. Always Use LDAP:// Protocol:**
```powershell
# CORRECT - Always use LDAP://
$rootDSE = [ADSI]"LDAP://RootDSE"
$searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"

# WRONG - Do not use WinNT:// for AD queries
$user = [ADSI]"WinNT://$env:USERDOMAIN/$env:USERNAME,user"  # AVOID

# WRONG - Do not use GC:// unless specifically needed for global catalog
$searcher.SearchRoot = [ADSI]"GC://$defaultNamingContext"  # AVOID
```

**2. Use Specific LDAP Filters:**
```powershell
# GOOD - Specific filter for user accounts
$searcher.Filter = "(&(objectClass=user)(objectCategory=person)(sAMAccountName=$username))"

# GOOD - Specific filter for computers
$searcher.Filter = "(&(objectClass=computer)(cn=$computername))"

# GOOD - Specific filter for groups
$searcher.Filter = "(&(objectClass=group)(cn=$groupname))"

# AVOID - Too broad
$searcher.Filter = "(sAMAccountName=$username)"  # Could match computer accounts
```

**3. Set Search Scope:**
```powershell
# Always set search scope explicitly
$searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree

# Available options:
# - Base: Only the base object
# - OneLevel: Immediate children only
# - Subtree: All descendants (recommended for domain-wide searches)
```

**4. Request Only Needed Attributes:**
```powershell
# GOOD - Request specific attributes
$searcher.PropertiesToLoad.AddRange(@('cn', 'sAMAccountName', 'memberOf'))

# AVOID - Loading all attributes (slower)
# Don't add PropertiesToLoad if you need everything (but this is slower)
```

**5. Error Handling for LDAP Queries:**
```powershell
try {
    $rootDSE = [ADSI]"LDAP://RootDSE"
    if ([string]::IsNullOrEmpty($rootDSE.defaultNamingContext)) {
        Write-Host "ERROR: Not connected to domain or LDAP unavailable"
        exit 1
    }
} catch {
    Write-Host "ERROR: LDAP connection failed - $($_.Exception.Message)"
    Write-Host "INFO: System may be workgroup or domain unreachable"
    exit 1
}
```

### Migration Tasks

**For Script_42_Active_Directory_Monitor.ps1:**

1. **Add LDAP Connection Check:**
   - Implement Test-ADConnection function using LDAP:// at script start
   - Exit gracefully if not domain-joined or no LDAP access
   - Log connection status to custom field

2. **Replace Import-Module ActiveDirectory:**
   - Remove all Import-Module ActiveDirectory calls
   - Replace Get-ADUser with Get-ADUserViaADSI (LDAP:// only)
   - Replace Get-ADComputer with Get-ADComputerViaADSI (LDAP:// only)
   - Replace Get-ADGroup with Get-ADGroupViaADSI (LDAP:// only)
   - Ensure all ADSI connections use LDAP:// protocol

3. **Update Field Writes:**
   - Ensure all AD-related custom fields populated via LDAP://
   - Use Base64 encoding for array data (group memberships)
   - Add error handling for each LDAP query
   - Implement fallback values for query failures

4. **Test Scenarios:**
   - Domain-joined computer (should work with LDAP://)
   - Workgroup computer (should gracefully exit)
   - Domain computer without AD connectivity (should report error)
   - Different user contexts (SYSTEM vs USER)
   - Verify all queries use LDAP:// protocol only

5. **Document Changes:**
   - Update script documentation with LDAP:// approach
   - Document connection requirements
   - List LDAP attributes queried
   - Provide troubleshooting guide
   - Note LDAP:// protocol requirement

### Benefits of ADSI LDAP:// Migration

**Performance:**
- No module loading overhead (saves 2-5 seconds)
- Direct LDAP queries are faster
- Reduced memory footprint
- Efficient attribute retrieval

**Compatibility:**
- Works on systems without RSAT
- No PowerShell module dependencies
- Compatible with PowerShell 2.0+
- Works in constrained language mode
- Standard LDAP protocol (RFC 4511)

**Reliability:**
- Fewer external dependencies
- More predictable behavior
- Better error handling capabilities
- Explicit connection validation
- Direct LDAP protocol communication

**Consistency:**
- Single protocol (LDAP://) for all AD queries
- Standard LDAP filters and attributes
- Predictable behavior across all Windows versions
- No WinNT:// or GC:// protocol mixing

---

[Continue with Pre-Phase B, C, D sections from version 1.6, no changes needed]

## Pre-Phase B: Module Dependency Reduction (RSAT and Non-Native Only)

[Content from version 1.6 - no changes]

---

## Pre-Phase C: Base64 Encoding Standard for Data Storage

[Content from version 1.6 - no changes]

---

## Pre-Phase D: Language Compatibility (German/English Windows)

[Content from version 1.6 with additional note]

### Additional Note on LDAP:// and Language Compatibility

LDAP:// queries are inherently language-neutral because:
- LDAP attribute names are always English (cn, sAMAccountName, memberOf, etc.)
- LDAP filters use standard syntax regardless of Windows language
- Distinguished Names (DNs) use standard format
- No localized display names in LDAP attributes
- Protocol is RFC-standardized and language-agnostic

This makes LDAP:// queries perfectly compatible with German and English Windows installations.

[Continue with rest of Pre-Phase D content]

---

## Phase 0: Coding Standards and Conventions

[Content from version 1.6 with additions]

### Additional Coding Standards

**ADSI LDAP:// Protocol Usage:**
- Always use LDAP:// protocol for all Active Directory queries
- Never use WinNT:// for AD queries (local accounts only)
- Never use GC:// unless specifically needed for global catalog
- Set SearchScope explicitly to Subtree for domain-wide queries
- Use specific LDAP filters with objectClass and objectCategory
- Request only needed attributes via PropertiesToLoad
- Always check for null/empty before accessing LDAP properties

[Continue with rest of coding standards from version 1.6]

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
   - **Verify all ADSI queries use LDAP:// protocol**
   - Test on domain-joined and workgroup systems
   - Document LDAP:// approach

[Continue with rest of execution sequence from version 1.6]

---

## Success Criteria

### Project Complete When

**Technical Requirements:**
- All dropdown field references converted to text
- **All AD queries migrated to ADSI using LDAP:// protocol exclusively**
- **No WinNT:// or GC:// protocols used for AD queries**
- RSAT module dependencies eliminated (native modules retained)
- All complex data storage uses Base64 encoding
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
- **ADSI LDAP:// implementation documented with examples**
- **LDAP:// protocol requirement clearly stated**
- Native module usage documented (why kept)
- RSAT module replacements documented
- Base64 encoding documented with examples
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
- **All ADSI examples use LDAP:// protocol only**
- Native Windows modules used where appropriate
- RSAT dependencies eliminated
- Base64 encoding tested with special characters
- Script outputs identical on German and English Windows
- Consistent formatting throughout
- All cross-references accurate
- TBD_INVENTORY.md shows 100% resolution
- Style guide compliance verified
- Coding standards compliance verified
- No checkmarks, crosses, or emojis
- **ADSI LDAP:// functions tested on domain and workgroup systems**
- Language-neutral code verified on multiple Windows languages
- Base64 encoding verified with umlauts and special characters

---

## Resource Estimates

[Same as version 1.6 - no time estimate changes needed]

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

---

**END OF ACTION PLAN**
