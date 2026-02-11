# Active Directory Scripts

**Complete guide to WAF Active Directory automation and monitoring scripts.**

---

## Overview

The WAF Active Directory suite provides comprehensive tools for monitoring, reporting, and managing Active Directory environments. These scripts cover domain controller health, user/group management, replication monitoring, and domain operations.

**Total Scripts:** 15+  
**NinjaOne Integration:** 12+ scripts  
**Categories:** DC Operations, User Management, Domain Operations

---

## Quick Start

### Prerequisites

- Domain-joined Windows Server or workstation
- Active Directory PowerShell module (RSAT-AD-PowerShell)
- Domain Admin or equivalent permissions (read-only for monitoring)
- Network connectivity to domain controllers

### Installation

```powershell
# Install AD PowerShell module
Install-WindowsFeature -Name RSAT-AD-PowerShell

# Import module
Import-Module ActiveDirectory

# Verify connectivity
Get-ADDomain
```

---

## Domain Controller Monitoring

### AD-DomainControllerHealthReport.ps1

**Purpose:** Comprehensive domain controller health assessment

**Features:**
- DC service status (NTDS, DNS, Netlogon, KDC)
- FSMO role verification
- Replication partner status
- SYSVOL/NETLOGON share availability
- Event log error analysis
- Performance metrics (CPU, memory, disk)

**Usage:**
```powershell
# Basic execution
./AD-DomainControllerHealthReport.ps1

# With verbose output
./AD-DomainControllerHealthReport.ps1 -Verbose

# Specify domain controller
./AD-DomainControllerHealthReport.ps1 -DomainController "DC01.domain.com"
```

**NinjaOne Fields:**
- `ad_dc_health_status` - Overall health score
- `ad_dc_service_status` - Critical services status
- `ad_dc_replication_status` - Replication health
- `ad_dc_last_check` - Last check timestamp

**Output Example:**
```
Domain Controller Health Report
================================
DC Name: DC01.domain.com
Domain: CONTOSO.COM
Site: Default-First-Site-Name

Service Status:
  NTDS: Running ✓
  DNS: Running ✓
  Netlogon: Running ✓
  KDC: Running ✓

FSMO Roles:
  Schema Master: DC01
  Domain Naming Master: DC01

Replication Status:
  Inbound: Healthy (0 failures)
  Outbound: Healthy (0 failures)

Overall Health: HEALTHY (Score: 95/100)
```

---

### AD-ReplicationHealthReport.ps1

**Purpose:** Detailed AD replication monitoring

**Features:**
- Per-DC replication status
- Replication partner discovery
- Failure detection and alerting
- Replication lag analysis
- Site link evaluation

**Usage:**
```powershell
# Check all DCs
./AD-ReplicationHealthReport.ps1

# Check specific site
./AD-ReplicationHealthReport.ps1 -Site "MainOffice"

# Alert on failures only
./AD-ReplicationHealthReport.ps1 -AlertOnFailureOnly
```

**NinjaOne Fields:**
- `ad_repl_status` - Overall replication status
- `ad_repl_failures` - Number of replication failures
- `ad_repl_lag_max` - Maximum replication lag (minutes)
- `ad_repl_last_success` - Last successful replication

**Common Issues:**

| Issue | Cause | Solution |
|-------|-------|----------|
| High replication lag | Network latency, DC overload | Check network, review DC resources |
| Replication failures | Authentication, firewall, time sync | Verify Kerberos, ports, time sync |
| Partner not found | DC offline, DNS issues | Verify DC status, DNS records |

---

### AD-Monitor.ps1

**Purpose:** Core AD monitoring with NinjaOne integration

**Features:**
- Real-time AD health monitoring
- Automated alerting on issues
- Performance baseline tracking
- Custom field population
- Scheduled execution support

**Usage:**
```powershell
# Standard monitoring run
./AD-Monitor.ps1

# With alerting
./AD-Monitor.ps1 -EnableAlerts -AlertThreshold "Warning"

# Silent mode (NinjaOne only)
./AD-Monitor.ps1 -Silent
```

**Recommended Schedule:** Every 15 minutes via NinjaOne automation policy

---

## User & Group Management

### AD-GetOUMembers.ps1

**Purpose:** List all members of organizational units

**Usage:**
```powershell
# List all users in OU
./AD-GetOUMembers.ps1 -OU "OU=Users,OU=Corporate,DC=domain,DC=com"

# Include nested OUs
./AD-GetOUMembers.ps1 -OU "OU=Corporate,DC=domain,DC=com" -Recursive

# Export to CSV
./AD-GetOUMembers.ps1 -OU "OU=Users,DC=domain,DC=com" -ExportCSV "C:\Temp\users.csv"
```

**Output Includes:**
- User name and SAM account
- Email address
- Enabled/disabled status
- Last logon timestamp
- Group memberships

---

### AD-UserGroupMembershipReport.ps1

**Purpose:** Generate comprehensive user group membership reports

**Features:**
- Per-user group listings
- Nested group expansion
- Security vs distribution groups
- Group membership history
- Privileged group identification

**Usage:**
```powershell
# Single user report
./AD-UserGroupMembershipReport.ps1 -Username "jdoe"

# All users in OU
./AD-UserGroupMembershipReport.ps1 -OU "OU=IT,DC=domain,DC=com"

# Privileged groups only
./AD-UserGroupMembershipReport.ps1 -PrivilegedGroupsOnly
```

**NinjaOne Fields:**
- `ad_user_group_count` - Total groups per user
- `ad_privileged_groups` - Privileged group memberships
- `ad_report_last_run` - Report generation timestamp

---

### AD-ModifyUserGroupMembership.ps1

**Purpose:** Automated user group membership management

**Usage:**
```powershell
# Add user to group
./AD-ModifyUserGroupMembership.ps1 -Username "jdoe" -Group "IT-Support" -Action "Add"

# Remove user from group
./AD-ModifyUserGroupMembership.ps1 -Username "jdoe" -Group "Temp-Access" -Action "Remove"

# Bulk operation from CSV
./AD-ModifyUserGroupMembership.ps1 -ImportCSV "C:\Temp\membership.csv"
```

**CSV Format:**
```csv
Username,Group,Action
jdoe,IT-Support,Add
jsmith,Contractors,Remove
```

---

### AD-UserLoginHistoryReport.ps1

**Purpose:** Track user authentication events

**Features:**
- Login success/failure tracking
- Source IP and computer identification
- Time-based analysis
- Failed login alerting
- Anomaly detection

**Usage:**
```powershell
# Last 24 hours
./AD-UserLoginHistoryReport.ps1 -Hours 24

# Specific user
./AD-UserLoginHistoryReport.ps1 -Username "jdoe" -Days 7

# Failed logins only
./AD-UserLoginHistoryReport.ps1 -FailedOnly -Hours 1
```

**NinjaOne Fields:**
- `ad_login_attempts_24h` - Login attempts (24h)
- `ad_failed_logins_24h` - Failed logins (24h)
- `ad_unique_users_24h` - Unique authenticated users

---

### AD-LockedOutUserReport.ps1

**Purpose:** Identify and report locked user accounts

**Usage:**
```powershell
# All locked accounts
./AD-LockedOutUserReport.ps1

# With unlock option
./AD-LockedOutUserReport.ps1 -AutoUnlock -NotifyUser

# Specific OU only
./AD-LockedOutUserReport.ps1 -OU "OU=Users,DC=domain,DC=com"
```

**Alert Conditions:**
- Account locked > 3 times in 1 hour
- Administrative account locked
- Service account locked

---

## Domain Operations

### AD-JoinComputerToDomain.ps1

**Purpose:** Automated domain join with validation

**Features:**
- Pre-join validation (DNS, connectivity)
- Credential handling
- OU placement
- Post-join verification
- Rollback on failure

**Usage:**
```powershell
# Join with credentials
./AD-JoinComputerToDomain.ps1 -Domain "contoso.com" -Credential (Get-Credential)

# Join to specific OU
./AD-JoinComputerToDomain.ps1 -Domain "contoso.com" -OU "OU=Workstations,DC=contoso,DC=com"

# With custom computer name
./AD-JoinComputerToDomain.ps1 -Domain "contoso.com" -NewName "WS-001"
```

**Pre-requisites Check:**
- DNS resolution to domain
- Time synchronization (within 5 minutes)
- Network connectivity to DC
- No existing computer object conflict

---

### AD-RemoveComputerFromDomain.ps1

**Purpose:** Safe domain removal with cleanup

**Features:**
- Graceful domain unjoin
- AD object cleanup
- Local account creation
- Workgroup join
- Audit trail logging

**Usage:**
```powershell
# Remove from domain
./AD-RemoveComputerFromDomain.ps1 -Credential (Get-Credential)

# With local admin creation
./AD-RemoveComputerFromDomain.ps1 -CreateLocalAdmin -AdminName "localadmin"

# Clean AD object
./AD-RemoveComputerFromDomain.ps1 -RemoveADObject
```

---

### AD-RepairTrust.ps1

**Purpose:** Repair broken computer trust relationships

**Features:**
- Trust validation
- Secure channel reset
- Password synchronization
- Automatic retry logic
- Verification testing

**Usage:**
```powershell
# Test trust
./AD-RepairTrust.ps1 -TestOnly

# Repair trust
./AD-RepairTrust.ps1 -Credential (Get-Credential)

# Force reset
./AD-RepairTrust.ps1 -Force
```

**Common Symptoms:**
- "Trust relationship failed" logon errors
- Cannot authenticate to domain
- Group Policy not applying

**Resolution Steps:**
1. Verify network connectivity
2. Check time synchronization
3. Run trust test
4. Reset secure channel
5. Reboot if required

---

## Integration Scenarios

### Scenario 1: Automated DC Health Monitoring

**Objective:** 24/7 domain controller health monitoring with alerting

**Implementation:**
```powershell
# Deploy via NinjaOne automation policy
# Schedule: Every 15 minutes
# Conditions: Domain Controllers only

./AD-DomainControllerHealthReport.ps1 -Verbose
./AD-ReplicationHealthReport.ps1 -AlertOnFailureOnly
```

**Alert Configuration:**
- Warning: Health score < 80
- Critical: Health score < 60
- Critical: Replication failures > 0
- Warning: Replication lag > 60 minutes

---

### Scenario 2: User Lifecycle Management

**Objective:** Automated user provisioning and deprovisioning

**Workflow:**
1. New user onboarding
   ```powershell
   ./AD-CreateUser.ps1 -Template "Standard-Employee"
   ./AD-ModifyUserGroupMembership.ps1 -Action "Add" -Groups @("All-Users", "VPN-Access")
   ```

2. Group membership changes
   ```powershell
   ./AD-ModifyUserGroupMembership.ps1 -ImportCSV "changes.csv"
   ```

3. User offboarding
   ```powershell
   ./AD-DisableUser.ps1 -Username "jdoe" -RemoveGroups -ExpiryDate (Get-Date).AddDays(30)
   ```

---

### Scenario 3: Security Compliance Reporting

**Objective:** Regular security posture reporting

**Monthly Tasks:**
```powershell
# Privileged group membership
./AD-UserGroupMembershipReport.ps1 -PrivilegedGroupsOnly -ExportPath "C:\Reports\Privileged-$(Get-Date -Format 'yyyy-MM').csv"

# Failed login attempts
./AD-UserLoginHistoryReport.ps1 -FailedOnly -Days 30 -ExportPath "C:\Reports\FailedLogins-$(Get-Date -Format 'yyyy-MM').csv"

# Locked accounts
./AD-LockedOutUserReport.ps1 -ExportPath "C:\Reports\LockedAccounts-$(Get-Date -Format 'yyyy-MM').csv"
```

---

## Troubleshooting

### Common Issues

#### "Access Denied" Errors

**Cause:** Insufficient permissions

**Solution:**
```powershell
# Verify current user
whoami

# Check AD permissions
Get-ADUser (whoami -user) -Properties MemberOf | Select-Object -ExpandProperty MemberOf

# Run with explicit credentials
$cred = Get-Credential
./AD-Script.ps1 -Credential $cred
```

#### Module Not Found

**Cause:** AD PowerShell module not installed

**Solution:**
```powershell
# Windows Server
Install-WindowsFeature -Name RSAT-AD-PowerShell

# Windows 10/11
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online

# Verify
Get-Module -ListAvailable ActiveDirectory
```

#### Slow Script Execution

**Cause:** Large AD environment, network latency

**Solution:**
```powershell
# Use server-side filtering
Get-ADUser -Filter "Enabled -eq $true" -Properties LastLogonDate

# Limit search scope
./AD-Script.ps1 -SearchBase "OU=Users,DC=domain,DC=com"

# Run from domain controller
Invoke-Command -ComputerName DC01 -ScriptBlock { ./AD-Script.ps1 }
```

---

## Best Practices

### Security

1. **Least Privilege:** Use read-only accounts for monitoring
2. **Credential Storage:** Never hardcode credentials
3. **Audit Logging:** Enable comprehensive logging
4. **Sensitive Data:** Encrypt exports containing user information

### Performance

1. **Query Optimization:** Use -Filter instead of Where-Object
2. **Property Selection:** Only retrieve needed properties
3. **Batch Operations:** Process users in batches for large operations
4. **Scheduling:** Run intensive reports during off-peak hours

### Monitoring

1. **Regular Execution:** Schedule DC health checks every 15 minutes
2. **Baseline Tracking:** Establish normal operational baselines
3. **Alert Tuning:** Adjust thresholds to minimize false positives
4. **Trend Analysis:** Review historical data for capacity planning

---

## Related Documentation

- **[Script Catalog](/docs/scripts/SCRIPT_CATALOG.md)** - Complete script listing
- **[Getting Started](/docs/GETTING_STARTED.md)** - Setup guide
- **[NinjaOne Integration](/docs/guides/ninjaone-integration.md)** - RMM integration details

---

**Last Updated:** 2026-02-11  
**Script Count:** 15+  
**Category:** Active Directory
