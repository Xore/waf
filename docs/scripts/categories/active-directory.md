# Active Directory Automation & Monitoring

**Complete guide to Active Directory scripts in the WAF framework.**

---

## Overview

The WAF Active Directory suite provides 15+ scripts for domain controller monitoring, user/group management, replication health, and automated reporting. Designed for enterprise AD environments with multiple domain controllers and complex organizational structures.

### Script Categories

| Category | Script Count | Complexity |
|----------|--------------|------------|
| Domain Controller Operations | 4 | Advanced |
| User & Group Management | 7 | Intermediate |
| Domain Operations | 4 | Advanced |

**Total:** 15+ scripts | **Primary Focus:** Monitoring & Automation

---

## Quick Start

### Prerequisites

**System Requirements:**
- Domain controller or domain-joined Windows Server
- PowerShell 5.1 or later
- Active Directory PowerShell module (RSAT-AD-PowerShell)
- Domain Admin or appropriate delegated permissions
- NinjaOne agent (for RMM integration)

**Module Installation:**

```powershell
# Windows Server
Install-WindowsFeature -Name RSAT-AD-PowerShell

# Windows 10/11
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

# Verify installation
Get-Module -ListAvailable ActiveDirectory

# Import module
Import-Module ActiveDirectory
```

### First Deployment

```powershell
# Test AD connectivity
Get-ADDomain

# Run basic DC health check
.\AD-DomainControllerHealthReport.ps1 -Verbose

# Check replication status
.\AD-ReplicationHealthReport.ps1
```

---

## Domain Controller Operations

### AD-DomainControllerHealthReport.ps1

**Purpose:** Comprehensive domain controller health monitoring with detailed diagnostics.

**Key Features:**
- DC service status (NTDS, KDC, DNS, Netlogon)
- Replication status and lag monitoring
- FSMO role verification
- Sysvol replication health
- Event log error analysis (last 24 hours)
- Performance metrics (CPU, memory, disk)
- Health score calculation (0-100)

**Health Checks:**
1. **Critical Services**
   - Active Directory Domain Services (NTDS)
   - Kerberos Key Distribution Center
   - DNS Server
   - Netlogon
   - DFS Replication

2. **Replication Status**
   - Last replication time
   - Replication partners
   - Failed replication attempts
   - USN deltas

3. **FSMO Roles**
   - Schema Master
   - Domain Naming Master
   - RID Master
   - PDC Emulator
   - Infrastructure Master

**NinjaOne Custom Fields:**
```powershell
ad_dc_health_score       - Overall DC health (0-100)
ad_dc_services_status    - Critical services status
ad_dc_replication_status - Replication health
ad_dc_fsmo_roles         - FSMO roles held
ad_dc_sysvol_status      - Sysvol replication status
ad_dc_last_backup        - Last system state backup
ad_dc_event_errors       - Critical errors (24h)
```

**Usage:**

```powershell
# Basic health check
.\AD-DomainControllerHealthReport.ps1

# Verbose output with detailed diagnostics
.\AD-DomainControllerHealthReport.ps1 -Verbose

# Check specific DC
.\AD-DomainControllerHealthReport.ps1 -DomainController "DC01.domain.com"

# Generate HTML report
.\AD-DomainControllerHealthReport.ps1 -HTMLReport -ReportPath "C:\Reports"
```

**Alert Thresholds:**
```powershell
$alertConfig = @{
    HealthScore = @{
        Critical = 50   # Below 50 = CRITICAL
        Warning = 70    # 50-70 = WARNING
        Good = 85       # 70-85 = GOOD
                        # Above 85 = EXCELLENT
    }
    ReplicationLag = @{
        Warning = 60    # 60 minutes
        Critical = 180  # 3 hours
    }
    EventErrors = @{
        Warning = 5     # 5+ errors in 24h
        Critical = 20   # 20+ errors in 24h
    }
}
```

---

### AD-ReplicationHealthReport.ps1

**Purpose:** Detailed Active Directory replication monitoring and diagnostics.

**Key Features:**
- Per-site replication status
- Inter-site link monitoring
- Replication topology validation
- Failed replication detection
- Replication lag calculation
- Conflict resolution status
- Metadata cleanup detection

**Replication Checks:**
```powershell
# Check replication partners
Get-ADReplicationPartnerMetadata -Target "DC01"

# Verify replication status
Get-ADReplicationUpToDatenessVectorTable -Target "DC01"

# Monitor replication failures
Get-ADReplicationFailure -Target "DC01"
```

**Usage:**

```powershell
# Check all DCs in domain
.\AD-ReplicationHealthReport.ps1

# Check specific site
.\AD-ReplicationHealthReport.ps1 -Site "HeadOffice"

# Generate detailed report
.\AD-ReplicationHealthReport.ps1 -Detailed -ExportCSV
```

**Output Example:**
```
=== AD Replication Health Report ===
Domain: contoso.com
Date: 2026-02-11 20:45:00

Replication Status: HEALTHY
Total DCs: 6
Healthy Replications: 30/30 (100%)

Per-DC Status:
  DC01 → DC02: OK (Last: 12 minutes ago)
  DC01 → DC03: OK (Last: 15 minutes ago)
  DC02 → DC01: OK (Last: 10 minutes ago)
  ...

Inter-Site Replication:
  HeadOffice → Branch1: OK (Last: 45 minutes)
  HeadOffice → Branch2: DELAYED (Last: 125 minutes) ⚠️

Recommendations:
  - Investigate replication delay to Branch2
  - Check network connectivity
```

---

### AD-Monitor.ps1 & ActiveDirectoryMonitor.ps1

**Purpose:** Core AD monitoring for scheduled automation.

**Monitored Items:**
- Domain controller availability
- User account statistics
- Group membership changes
- Password expiration tracking
- Locked account detection
- Disabled account monitoring
- Stale computer objects

**NinjaOne Fields:**
```powershell
ad_total_users           - Total user accounts
ad_enabled_users         - Enabled users
ad_disabled_users        - Disabled users
ad_locked_users          - Locked accounts
ad_password_expiring     - Passwords expiring (7 days)
ad_stale_computers       - Computers inactive 90+ days
ad_total_groups          - Total security groups
```

**Usage:**

```powershell
# Standard monitoring
.\AD-Monitor.ps1

# With email alerts
.\ActiveDirectoryMonitor.ps1 -SendEmail -SMTPServer "mail.company.com"

# Schedule in NinjaOne (every 30 minutes)
```

---

## User & Group Management

### AD-GetOUMembers.ps1

**Purpose:** List all users, computers, and groups in an Organizational Unit.

**Features:**
- Recursive OU scanning
- Object type filtering
- Property selection
- Export to CSV/JSON
- Nested group resolution

**Usage:**

```powershell
# List all users in OU
.\AD-GetOUMembers.ps1 -OU "OU=Sales,DC=contoso,DC=com" -ObjectType Users

# Include nested OUs
.\AD-GetOUMembers.ps1 -OU "OU=Company,DC=contoso,DC=com" -Recursive

# Export to CSV
.\AD-GetOUMembers.ps1 -OU "OU=IT,DC=contoso,DC=com" -ExportCSV -Path "C:\Reports"

# Get specific properties
.\AD-GetOUMembers.ps1 -OU "OU=Users,DC=contoso,DC=com" -Properties "Name","EmailAddress","Title"
```

**Output:**
```
OU: OU=Sales,DC=contoso,DC=com
Users: 45
Computers: 12
Groups: 8

Users:
  John Smith (jsmith@contoso.com)
  Jane Doe (jdoe@contoso.com)
  ...

Computers:
  SALES-PC01
  SALES-PC02
  ...
```

---

### AD-GetOrganizationalUnit.ps1

**Purpose:** Query and analyze OU structure.

**Features:**
- OU hierarchy visualization
- GPO link analysis
- Permission delegation review
- Object count per OU
- Empty OU detection

**Usage:**

```powershell
# List all OUs
.\AD-GetOrganizationalUnit.ps1

# Show OU hierarchy
.\AD-GetOrganizationalUnit.ps1 -ShowHierarchy

# Include GPO links
.\AD-GetOrganizationalUnit.ps1 -IncludeGPOs

# Find empty OUs
.\AD-GetOrganizationalUnit.ps1 -FindEmpty
```

---

### AD-ModifyUserGroupMembership.ps1

**Purpose:** Automated group membership management.

**Operations:**
- Add user to groups
- Remove user from groups
- Replace all group memberships
- Bulk user operations
- Audit trail generation

**Usage:**

```powershell
# Add user to group
.\AD-ModifyUserGroupMembership.ps1 -User "jsmith" -AddToGroup "Sales_Team"

# Remove from group
.\AD-ModifyUserGroupMembership.ps1 -User "jdoe" -RemoveFromGroup "Contractors"

# Add to multiple groups
.\AD-ModifyUserGroupMembership.ps1 -User "bjones" -AddToGroups @("IT_Team", "VPN_Users", "SharePoint_Authors")

# Bulk operation from CSV
.\AD-ModifyUserGroupMembership.ps1 -CSVPath "C:\UserGroups.csv"
```

**CSV Format:**
```csv
Username,Action,GroupName
jsmith,Add,Sales_Team
jdoe,Remove,Contractors
bjones,Add,IT_Team
```

---

### AD-UserGroupMembershipReport.ps1

**Purpose:** Comprehensive group membership reporting.

**Report Contents:**
- User's direct group memberships
- Nested group memberships
- Group nesting levels
- Permission summary
- Unusual group combinations (security analysis)

**Usage:**

```powershell
# Report for single user
.\AD-UserGroupMembershipReport.ps1 -User "jsmith"

# Report for all users in OU
.\AD-UserGroupMembershipReport.ps1 -OU "OU=IT,DC=contoso,DC=com"

# Security audit (privileged groups)
.\AD-UserGroupMembershipReport.ps1 -AuditPrivilegedGroups
```

**Output:**
```
User: John Smith (jsmith@contoso.com)
Direct Memberships: 8 groups
Nested Memberships: 15 groups
Total Effective Groups: 23

Direct Groups:
  - Domain Users
  - IT_Department
  - VPN_Users
  - SharePoint_Authors
  ...

Nested Groups (via IT_Department):
  - IT_L1_Support
  - Software_Installers
  - Remote_Desktop_Users
  ...

Privileged Access:
  ⚠️ Member of 'Server_Administrators' (via IT_Department)
  ⚠️ Member of 'Backup_Operators' (direct)
```

---

### AD-UserLoginHistoryReport.ps1 & AD-UserLogonHistory.ps1

**Purpose:** Track user login activity for security auditing.

**Tracked Events:**
- Successful logins (Event ID 4624)
- Failed login attempts (Event ID 4625)
- Logoff events (Event ID 4634)
- Account lockouts (Event ID 4740)
- Login location (workstation name)
- Login method (interactive, network, remote)

**Usage:**

```powershell
# Get login history for user
.\AD-UserLoginHistoryReport.ps1 -User "jsmith" -Days 30

# Failed login attempts only
.\AD-UserLoginHistoryReport.ps1 -User "jsmith" -FailedOnly

# All users in OU (security audit)
.\AD-UserLogonHistory.ps1 -OU "OU=Executives,DC=contoso,DC=com" -Days 7

# Detect unusual login patterns
.\AD-UserLoginHistoryReport.ps1 -User "admin" -DetectAnomalies
```

**Output:**
```
Login History: John Smith (jsmith)
Period: Last 30 days
Total Logins: 145
Failed Attempts: 2

Recent Logins:
  2026-02-11 08:15 - WORKSTATION01 (Interactive)
  2026-02-11 14:30 - VPN-SERVER (Network)
  2026-02-10 08:20 - WORKSTATION01 (Interactive)
  ...

Failed Attempts:
  2026-02-05 22:15 - UNKNOWN (Bad password)
  2026-01-28 09:00 - WORKSTATION01 (Account locked)

⚠️ ALERT: After-hours login detected (2026-02-05 22:15)
```

---

### AD-LockedOutUserReport.ps1

**Purpose:** Monitor and report on locked user accounts.

**Features:**
- Real-time lockout detection
- Lockout source identification
- Bad password attempt analysis
- Automated unlock capability
- Lockout trend analysis

**Usage:**

```powershell
# Check for locked accounts
.\AD-LockedOutUserReport.ps1

# With detailed lockout source
.\AD-LockedOutUserReport.ps1 -IncludeSource

# Auto-unlock after verification
.\AD-LockedOutUserReport.ps1 -AutoUnlock -NotifyUser
```

**NinjaOne Fields:**
```powershell
ad_locked_users_count    - Number of locked accounts
ad_locked_users_list     - Comma-separated list
ad_lockout_sources       - Workstations causing lockouts
```

---

## Domain Operations

### AD-JoinComputerToDomain.ps1

**Purpose:** Automated domain join with validation and error handling.

**Features:**
- Pre-join validation
- DNS verification
- Computer account pre-staging
- OU placement
- Post-join verification
- Automatic reboot handling

**Usage:**

```powershell
# Basic domain join
.\AD-JoinComputerToDomain.ps1 -Domain "contoso.com" -Credential $cred

# Join with specific OU
.\AD-JoinComputerToDomain.ps1 -Domain "contoso.com" -OU "OU=Workstations,DC=contoso,DC=com"

# Pre-staged computer account
.\AD-JoinComputerToDomain.ps1 -Domain "contoso.com" -ComputerName "WS-001" -PreStaged
```

---

### AD-JoinDomain.ps1

**Purpose:** Simplified domain join operation.

**Usage:**

```powershell
# Simple join
.\AD-JoinDomain.ps1 -DomainName "contoso.com" -Username "admin" -Password $pwd
```

---

### AD-RemoveComputerFromDomain.ps1

**Purpose:** Safely remove computers from domain.

**Features:**
- Computer account deletion
- Workgroup conversion
- DNS record cleanup
- Event log archival
- Verification and rollback

**Usage:**

```powershell
# Remove from domain
.\AD-RemoveComputerFromDomain.ps1 -ComputerName "OLD-PC" -Credential $cred

# Remove and delete AD object
.\AD-RemoveComputerFromDomain.ps1 -ComputerName "DECOM-SRV" -DeleteADObject
```

---

### AD-RepairTrust.ps1

**Purpose:** Repair broken trust relationships between computer and domain.

**Common Issues Fixed:**
- "Trust relationship failed" errors
- Secure channel broken
- Machine password mismatch
- Authentication failures

**Usage:**

```powershell
# Test trust
Test-ComputerSecureChannel -Verbose

# Repair trust
.\AD-RepairTrust.ps1

# Repair with verbose output
.\AD-RepairTrust.ps1 -Verbose -Credential $cred
```

**Process:**
1. Test current trust status
2. Reset machine password
3. Re-establish secure channel
4. Verify trust repaired
5. Optional reboot

---

## Deployment Scenarios

### Scenario 1: Basic AD Monitoring

**Environment:** Single domain, 2-3 DCs, 500 users

**Recommended Schedule:**
```powershell
# Every 30 minutes
.\AD-Monitor.ps1

# Daily at 2 AM
.\AD-DomainControllerHealthReport.ps1
.\AD-ReplicationHealthReport.ps1

# Weekly
.\AD-UserGroupMembershipReport.ps1 -AuditPrivilegedGroups
```

---

### Scenario 2: Multi-Site Enterprise

**Environment:** Multi-domain forest, 20+ DCs, 10,000+ users

**Monitoring Strategy:**
```powershell
# Per-site monitoring (every 15 minutes)
foreach ($site in $adSites) {
    .\AD-Monitor.ps1 -Site $site
}

# Forest-wide replication (every hour)
.\AD-ReplicationHealthReport.ps1 -Forest

# Daily security audit
.\AD-UserLoginHistoryReport.ps1 -PrivilegedUsers
.\AD-LockedOutUserReport.ps1
```

---

### Scenario 3: Security Audit Focus

**Environment:** Compliance-driven, high security requirements

**Audit Scripts:**
```powershell
# Daily
.\AD-UserLoginHistoryReport.ps1 -DetectAnomalies
.\AD-LockedOutUserReport.ps1 -IncludeSource
.\AD-UserGroupMembershipReport.ps1 -AuditPrivilegedGroups

# Weekly
.\AD-GetOUMembers.ps1 -OU "OU=Privileged,DC=contoso,DC=com" -ExportCSV

# Monthly
.\AD-GetOrganizationalUnit.ps1 -IncludeGPOs -SecurityAudit
```

---

## Best Practices

### Monitoring Frequency

| Script | Recommended Interval | Resource Impact |
|--------|---------------------|------------------|
| AD-Monitor | 30 minutes | Low |
| AD-DomainControllerHealthReport | Daily | Medium |
| AD-ReplicationHealthReport | Hourly | Low |
| AD-LockedOutUserReport | 15 minutes | Low |
| AD-UserLoginHistoryReport | Daily | High |

### Security Best Practices

1. **Use Service Accounts** for automated monitoring
2. **Limit Permissions** to read-only where possible
3. **Audit Script Execution** in security logs
4. **Encrypt Credentials** when storing
5. **Review Privileged Groups** weekly

### Performance Optimization

```powershell
# Use -Filter instead of Where-Object
Get-ADUser -Filter {Enabled -eq $true}

# Limit properties returned
Get-ADUser -Filter * -Properties Name, EmailAddress

# Use specific search base
Get-ADUser -Filter * -SearchBase "OU=Users,DC=contoso,DC=com"
```

---

## Troubleshooting

### Common Issues

#### Issue: "Unable to contact domain controller"

**Solution:**
```powershell
# Test DNS resolution
Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.contoso.com" -Type SRV

# Test LDAP connectivity
Test-NetConnection -ComputerName "DC01" -Port 389

# Specify DC explicitly
.\AD-Script.ps1 -Server "DC01.contoso.com"
```

#### Issue: "Access Denied" errors

**Solution:**
```powershell
# Verify permissions
Get-ADUser -Identity "serviceaccount" -Properties MemberOf

# Check required groups:
# - Domain Admins (for full access)
# - Account Operators (for user management)
# - Server Operators (for DC operations)
```

---

## Related Documentation

- **[Script Catalog](/docs/scripts/SCRIPT_CATALOG.md)** - Complete script listing
- **[Getting Started](/docs/GETTING_STARTED.md)** - Setup guide
- **[Security Guide](/docs/guides/advanced/security-compliance.md)** - Security best practices

---

**Last Updated:** 2026-02-11  
**Scripts:** 15+  
**Complexity:** Intermediate to Advanced
