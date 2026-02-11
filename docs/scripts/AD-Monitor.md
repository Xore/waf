# AD-Monitor.ps1 - Deep Dive

## Overview

**Category:** Active Directory  
**Version:** 3.0.0  
**Complexity:** Advanced  
**Execution Context:** SYSTEM (recommended)  
**Typical Duration:** 10-15 seconds

### Purpose

Comprehensive Active Directory monitoring solution that tracks domain membership, domain controller connectivity, secure channel health, computer account status, user account details, and group memberships using native ADSI LDAP queries.

### Key Innovation

**RSAT-Free Implementation**: Uses ADSI (Active Directory Service Interfaces) with direct LDAP protocol queries instead of requiring Remote Server Administration Tools (RSAT). This provides maximum compatibility with any Windows system without additional components.

---

## Technical Architecture

### ADSI/LDAP Implementation

```powershell
# Direct LDAP connection without RSAT
$rootDSE = [ADSI]"LDAP://RootDSE"
$defaultNamingContext = $rootDSE.defaultNamingContext

# Create DirectorySearcher for queries
$searcher = New-Object System.DirectoryServices.DirectorySearcher
$searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
$searcher.Filter = "(&(objectClass=computer)(cn=$ComputerName))"
```

**Benefits:**
- No module dependencies
- Works on any Windows version
- Faster execution (native .NET calls)
- Reduced attack surface

### Data Collection Flow

```
1. Domain Membership Check (Win32_ComputerSystem)
   ↓
2. LDAP Connection Test (ADSI RootDSE)
   ↓
3. Domain Controller Location (nltest)
   ↓
4. Trust Relationship Test (Test-ComputerSecureChannel)
   ↓
5. Computer Account Query (LDAP)
   ↓
6. User Account Query (LDAP)
   ↓
7. NinjaRMM Field Updates
```

---

## Parameters

### No Parameters Required

This script runs autonomously without parameters, automatically detecting:
- Current computer name (`$env:COMPUTERNAME`)
- Last logged-on user (from registry)
- Domain membership status
- Domain controller location

---

## Features

### 1. Domain Membership Detection

**What it does:**
- Checks if computer is domain-joined or workgroup
- Identifies domain name and workgroup
- Handles both scenarios gracefully

**Implementation:**
```powershell
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
if ($computerSystem.PartOfDomain -eq $false) {
    # Workgroup scenario - set default values
    Ninja-Property-Set adDomainJoined "false"
    Ninja-Property-Set adDomainName $computerSystem.Workgroup
    return
}
```

### 2. LDAP Connection Validation

**What it does:**
- Tests connectivity to Active Directory via LDAP
- Validates RootDSE accessibility
- Retrieves default naming context

**Technical Details:**
- Protocol: LDAP (port 389)
- Authentication: Current computer credentials
- Timeout: Default Windows timeout (~30 seconds)

### 3. Domain Controller Discovery

**What it does:**
- Locates closest domain controller
- Identifies Active Directory site
- Uses `nltest` for DC location

**Command Output Parsing:**
```powershell
$dcInfo = nltest /dsgetdc:$domainName
# Extracts DC name from: "DC: \\DC01.domain.local"
# Extracts site from: "Site Name: Default-First-Site-Name"
```

### 4. Secure Channel Testing

**What it does:**
- Validates computer's trust relationship with domain
- Tests secure channel integrity
- Critical for detecting domain join issues

**Implementation:**
```powershell
$testResult = Test-ComputerSecureChannel -ErrorAction Stop
# Returns $true if trust is healthy, $false if broken
```

**Common Failure Scenarios:**
- Password mismatch between local and AD
- Computer account disabled in AD
- Replication issues
- Time synchronization problems

### 5. Computer Account Query

**What it does:**
- Retrieves computer object from Active Directory
- Gets group memberships
- Checks account status and password age

**LDAP Filter:**
```ldap
(&(objectClass=computer)(cn=COMPUTERNAME))
```

**Attributes Retrieved:**
- `cn` - Computer name
- `dNSHostName` - FQDN
- `sAMAccountName` - SAM account name
- `operatingSystem` - OS name
- `operatingSystemVersion` - OS version
- `memberOf` - Group memberships
- `userAccountControl` - Account flags (enabled/disabled)
- `pwdLastSet` - Password last set timestamp
- `distinguishedName` - Full DN (includes OU path)
- `whenCreated` - Creation timestamp

**Group Membership Parsing:**
```powershell
foreach ($groupDN in $computer['memberOf']) {
    if ($groupDN -match 'CN=([^,]+)') {
        $groups += $matches[1]  # Extract CN from DN
    }
}
```

### 6. User Account Query

**What it does:**
- Identifies last logged-on user
- Retrieves user details from AD
- Enumerates user group memberships

**User Identification Sources:**
1. Registry: `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\LastLoggedOnUser`
2. Fallback: Current user from `Win32_ComputerSystem.UserName`

**LDAP Filter:**
```ldap
(&(objectClass=user)(objectCategory=person)(sAMAccountName=USERNAME))
```

**Attributes Retrieved:**
- `givenName` - First name
- `sn` - Surname (last name)
- `displayName` - Display name
- `userPrincipalName` - UPN (email format)
- `sAMAccountName` - SAM account name
- `memberOf` - Group memberships
- `userAccountControl` - Account status
- `mail` - Email address
- `distinguishedName` - Full DN

---

## NinjaRMM Integration

### Custom Fields Updated

| Field Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `adDomainJoined` | Boolean String | Domain join status | "true" / "false" |
| `adDomainName` | String | Domain FQDN or workgroup | "contoso.local" |
| `adDomainController` | String | DC hostname | "DC01.contoso.local" |
| `adSiteName` | String | AD site name | "Default-First-Site-Name" |
| `adComputerOU` | String | Computer DN (includes OU) | "CN=COMP01,OU=Computers,DC=contoso,DC=local" |
| `adComputerGroups` | Array | Computer group memberships | ["Domain Computers", "Workstations"] |
| `adLastLogonUser` | String | Last user logged on | "CONTOSO\jdoe" |
| `adUserFirstName` | String | User first name | "John" |
| `adUserLastName` | String | User last name | "Doe" |
| `adUserGroups` | Array | User group memberships | ["Domain Users", "Sales"] |
| `adPasswordLastSet` | Unix Timestamp | Computer password change | 1707696000 |
| `adTrustRelationshipHealthy` | Boolean String | Trust status | "true" / "false" |

### Dashboard Use Cases

**Filtering & Reporting:**
```javascript
// Find computers with broken trust
adTrustRelationshipHealthy = "false"

// Find computers in specific OU
adComputerOU contains "OU=Servers"

// Find computers with old passwords (>90 days)
adPasswordLastSet < (current_timestamp - 7776000)

// Find computers by site
adSiteName = "RemoteOffice"
```

---

## Use Cases

### 1. Proactive Trust Monitoring

**Scenario:** Detect broken trust relationships before users notice.

**Automation:**
- Schedule: Every 4 hours
- Alert: When `adTrustRelationshipHealthy = "false"`
- Auto-remediation: Run trust repair script

**Detection Criteria:**
- `Test-ComputerSecureChannel` fails
- Cannot connect to domain controller
- LDAP queries fail

### 2. Computer Account Auditing

**Scenario:** Track computer accounts and their group memberships.

**Insights:**
- Which computers are in security groups?
- Stale computer accounts (old password)
- Computers with non-standard group memberships

### 3. User Tracking

**Scenario:** Maintain inventory of who uses which computer.

**Benefits:**
- Software license tracking
- Personalized support
- Usage analytics

### 4. Domain Controller Health

**Scenario:** Monitor DC availability and site assignment.

**Monitoring:**
- Which DC is servicing each computer?
- Are computers in correct AD sites?
- DC connectivity issues?

---

## Error Handling

### Error Scenarios

#### 1. Not Domain-Joined
```
Result: Success (exit 0)
Behavior: Sets workgroup name, marks as non-domain
Fields: adDomainJoined="false", adDomainName=workgroup name
```

#### 2. LDAP Connection Failure
```
Cause: Network issue, DC down, firewall blocking port 389
Result: Failure (exit 1)
Fields: adDomainController="LDAP connection failed"
       adTrustRelationshipHealthy="false"
```

#### 3. Broken Trust Relationship
```
Cause: Password mismatch, computer account disabled
Result: Failure (exit 1)
Detection: Test-ComputerSecureChannel returns $false
Fields: adTrustRelationshipHealthy="false"
```

#### 4. Computer Not Found in AD
```
Cause: Account deleted, wrong domain, replication delay
Result: Warning logged, partial data collected
Fields: adComputerOU="Unable to query"
       adComputerGroups=empty
```

#### 5. User Not Found in AD
```
Cause: Local account, external user, user deleted
Result: Warning logged, user fields empty
Fields: adUserFirstName=""
       adUserLastName=""
       adUserGroups=empty
```

### Graceful Degradation

The script continues execution even if some data points fail:
- Domain info succeeds → Computer query fails → User query succeeds
- Each component is independent
- Partial data is better than no data

---

## Performance Considerations

### Execution Timeline

| Phase | Duration | Notes |
|-------|----------|-------|
| Domain check | 0.1s | CIM query (fast) |
| LDAP connection | 1-2s | Network round-trip |
| DC location | 2-3s | `nltest` DNS lookup |
| Trust test | 2-5s | Cryptographic challenge/response |
| Computer LDAP query | 1-2s | Single object search |
| User LDAP query | 1-2s | Single object search |
| NinjaRMM updates | 0.5s | API calls |
| **Total** | **10-15s** | Typical execution |

### Network Requirements

**Ports Required:**
- TCP 389 (LDAP)
- UDP 389 (LDAP)
- TCP 88 (Kerberos)
- TCP 135 (RPC)
- Dynamic RPC ports (49152-65535)

**Bandwidth:**
- ~50 KB per execution
- Minimal network impact

### Resource Usage

**Memory:**
- Peak: ~30 MB
- Average: ~20 MB

**CPU:**
- Peak: <5%
- Average: <2%

---

## Troubleshooting

### Common Issues

#### "Unable to connect to Active Directory via LDAP"

**Causes:**
- Firewall blocking port 389
- DNS resolution failure
- No domain controller available
- Computer not on corporate network

**Diagnostics:**
```powershell
# Test LDAP connectivity
Test-NetConnection -ComputerName dc01.domain.local -Port 389

# Test DNS resolution
Resolve-DnsName _ldap._tcp.domain.local -Type SRV

# Check domain controller
nltest /dsgetdc:domain.local
```

**Resolution:**
- Verify network connectivity
- Check DNS configuration
- Ensure VPN is connected (remote computers)
- Verify firewall rules

#### "Secure channel test failed"

**Causes:**
- Computer password mismatch
- Computer account disabled in AD
- Time synchronization issue (>5 minutes difference)
- Replication lag

**Diagnostics:**
```powershell
# Check current status
Test-ComputerSecureChannel -Verbose

# Check time sync
w32tm /query /status

# Check computer account status in AD
Get-ADComputer -Identity $env:COMPUTERNAME -Properties Enabled
```

**Resolution:**
```powershell
# Repair trust relationship (requires domain admin)
Test-ComputerSecureChannel -Repair -Credential (Get-Credential)

# Or rejoin domain
Add-Computer -DomainName domain.local -Credential (Get-Credential) -Force
```

#### "Computer not found in AD via LDAP"

**Causes:**
- Computer account deleted
- Name mismatch (computer renamed locally)
- Searching wrong domain
- Replication delay (new computer)

**Diagnostics:**
```powershell
# Verify computer name matches AD
$env:COMPUTERNAME
(Get-ADComputer -Identity $env:COMPUTERNAME).Name

# Check domain
(Get-CimInstance Win32_ComputerSystem).Domain

# Check replication
repadmin /showrepl
```

#### "User not found via LDAP"

**Causes:**
- Local account (not domain user)
- User account deleted
- No user logged on recently
- External user (Azure AD)

**Diagnostics:**
```powershell
# Check last logged-on user
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"

# Check current user
(Get-CimInstance Win32_ComputerSystem).UserName

# Verify user exists in AD
Get-ADUser -Identity username
```

### Debug Mode

Enable verbose logging to see all LDAP queries:

```powershell
# Run manually with verbose output
.\AD-Monitor.ps1 -Verbose

# Check for DEBUG level messages
# Shows: LDAP connection details, DN paths, attribute values
```

---

## Security Considerations

### Execution Context

**Why SYSTEM context:**
- Access to registry keys (LastLoggedOnUser)
- Automatic Kerberos authentication
- Computer account credentials
- NinjaRMM API access

**User context limitations:**
- May not have registry access
- Different Kerberos ticket
- Inconsistent results

### Sensitive Data

**Information Exposed:**
- Domain membership
- User identities
- Group memberships
- Organizational unit structure

**Mitigation:**
- Data stored in NinjaRMM (access controlled)
- No credentials stored
- No password hashes
- Read-only LDAP queries

### Network Security

**LDAP vs. LDAPS:**
- Currently uses LDAP (unencrypted)
- Data is read-only queries
- Kerberos encrypts authentication
- Consider LDAPS (port 636) for sensitive environments

**LDAPS Implementation:**
```powershell
# Change LDAP:// to LDAPS://
$rootDSE = [ADSI]"LDAPS://RootDSE"
$searcher.SearchRoot = [ADSI]"LDAPS://$defaultNamingContext"
```

---

## Advanced Usage

### Customization Examples

#### Add Custom Attributes

Modify `Get-ADComputerViaADSI` to retrieve additional attributes:

```powershell
$searcher.PropertiesToLoad.AddRange(@(
    'cn','dNSHostName','sAMAccountName',
    'description',        # Computer description
    'location',          # Physical location
    'managedBy',         # Manager DN
    'lastLogonTimestamp' # Last logon time
))
```

#### Filter by OU

Modify search base to query specific OU:

```powershell
$ouDN = "OU=Workstations,DC=contoso,DC=local"
$searcher.SearchRoot = [ADSI]"LDAP://$ouDN"
```

#### Export to File

Add data export functionality:

```powershell
$exportData = [PSCustomObject]@{
    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ComputerName = $env:COMPUTERNAME
    Domain = $domainName
    DomainController = $domainController
    TrustHealthy = $trustHealthy
    ComputerGroups = $computerGroups -join ';'
    UserGroups = $userGroups -join ';'
}

$exportData | Export-Csv -Path "C:\Logs\ADMonitor.csv" -Append -NoTypeInformation
```

### Integration with Other Scripts

This script provides foundational AD data that other scripts can consume:

**Example: Conditional Patching**
```powershell
# Only patch computers in "Early Adopters" group
$computerGroups = Ninja-Property-Get adComputerGroups
if ($computerGroups -contains "Early Adopters") {
    # Install updates
}
```

**Example: User-Specific Configuration**
```powershell
# Apply settings based on user group membership
$userGroups = Ninja-Property-Get adUserGroups
if ($userGroups -contains "Sales") {
    # Configure Sales-specific software
}
```

---

## Best Practices

### Scheduling

**Recommended Frequencies:**

| Priority | Frequency | Use Case |
|----------|-----------|----------|
| Critical | Every 4 hours | Trust monitoring, broken domain join detection |
| Standard | Daily | General inventory, user tracking |
| Low | Weekly | Historical trending, reporting |

**Timing Considerations:**
- Avoid peak business hours (for network impact)
- Stagger execution across devices
- Allow 2-minute timeout

### Alerting

**Critical Alerts:**
```javascript
// Broken trust relationship
adTrustRelationshipHealthy = "false"
Severity: Critical
Action: Auto-repair if possible, escalate if fails

// No domain controller
adDomainController = "Unable to locate"
Severity: High
Action: Check network connectivity, verify DC status

// Old computer password (>90 days)
adPasswordLastSet < (current_time - 7776000)
Severity: Medium
Action: Force password reset (rejoin domain)
```

### Data Retention

**Historical Tracking:**
- Keep 90 days of AD monitoring data
- Track trust health trends
- Identify recurring issues
- Document computer/user changes

---

## Version History

### 3.0.0 (Current)
- V3 standards implementation
- `Set-StrictMode -Version Latest`
- Begin/Process/End blocks
- Enhanced error handling
- Improved logging

### 3.0
- Enhanced LDAP queries
- Better error handling
- Password age tracking
- Group membership details

### 2.0
- NinjaRMM integration
- Custom field population
- User account tracking

### 1.0
- Initial release
- Basic domain join detection
- Computer account queries

---

## Related Scripts

- `AD-DomainControllerHealthReport.ps1` - DC health checks
- `AD-ReplicationHealthReport.ps1` - Replication monitoring
- `AD-UserGroupMembershipReport.ps1` - Group membership analysis
- `AD-RepairTrust.ps1` - Automated trust repair
- `AD-JoinDomain.ps1` - Domain join automation

---

## Support

**Repository:** [github.com/Xore/waf](https://github.com/Xore/waf)  
**Documentation:** `/docs/scripts/AD-Monitor.md`  
**Category Guide:** `/docs/categories/active-directory.md`

**Common Questions:**
- See [Troubleshooting](#troubleshooting) section above
- Check [Active Directory Category Guide](../categories/active-directory.md)
- Review [Framework Concepts](../concepts/framework-concepts.md)
