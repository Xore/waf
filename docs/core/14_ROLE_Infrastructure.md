# NinjaRMM Custom Field Framework - Infrastructure Services
**File:** 14_ROLE_Infrastructure.md  
**Categories:** APACHE + VEEAM + DHCP + DNS  
**Field Count:** 37 fields  
**Target:** Servers running Apache, Veeam, DHCP, or DNS services

---

## Overview

Critical infrastructure service monitoring for web servers, backup systems, and network services ensuring business continuity and network functionality.

**Critical Note:** Script 13 is DRIFT Detector, not Veeam Monitor. VEEAM monitoring script needs to be implemented separately. Scripts 1-3 also need verification/implementation for Apache, DHCP, DNS.

---

## APACHE - Apache Web Server Fields (7 fields)

### APACHEInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **TBD: Apache Web Server Monitor** (Script 1 needs verification)
- **Update Frequency:** Every 4 hours

### APACHEVersion
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **TBD: Apache Web Server Monitor**
- **Update Frequency:** Every 4 hours

### APACHEVHostCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Virtual host count
- **Populated By:** **TBD: Apache Web Server Monitor**
- **Update Frequency:** Every 4 hours

### APACHERequestsPerSecond
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: Apache Web Server Monitor**
- **Update Frequency:** Every 4 hours

### APACHEErrorCount24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: Apache Web Server Monitor**
- **Update Frequency:** Every 4 hours

### APACHEWorkerProcesses
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: Apache Web Server Monitor**
- **Update Frequency:** Every 4 hours

### APACHEHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **TBD: Apache Web Server Monitor**
- **Update Frequency:** Every 4 hours

---

## VEEAM - Veeam Backup Fields (12 fields)

### VEEAMInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **TBD: Veeam Backup Monitor** (Script 13 conflict - currently DRIFT Detector)
- **Update Frequency:** Daily

### VEEAMVersion
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMBackupJobCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMFailedJobsCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Failed backup jobs in last 24 hours
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMLastSuccessfulBackup
- **Type:** DateTime
- **Default:** Empty
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMRepositoryFreeSpaceGB
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMRepositoryFreePercent
- **Type:** Integer (0-100)
- **Default:** 100
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMRunningJobCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Every 4 hours

### VEEAMWarningJobCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Jobs completed with warnings
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMJobSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Purpose:** HTML table of all backup jobs with status
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMLastError
- **Type:** Text
- **Max Length:** 1000 characters
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

### VEEAMHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **TBD: Veeam Backup Monitor**
- **Update Frequency:** Daily

---

## DHCP - DHCP Server Fields (9 fields)

### DHCPInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **TBD: DHCP Server Monitor** (Script 2 needs verification)
- **Update Frequency:** Every 4 hours

### DHCPScopeCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: DHCP Server Monitor**
- **Update Frequency:** Every 4 hours

### DHCPTotalAddresses
- **Type:** Integer
- **Default:** 0
- **Purpose:** Total IP addresses in all scopes
- **Populated By:** **TBD: DHCP Server Monitor**
- **Update Frequency:** Every 4 hours

### DHCPAddressesInUse
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: DHCP Server Monitor**
- **Update Frequency:** Every 4 hours

### DHCPAddressUtilizationPercent
- **Type:** Integer (0-100)
- **Default:** 0
- **Calculation:** (InUse / Total) * 100
- **Populated By:** **TBD: DHCP Server Monitor**
- **Update Frequency:** Every 4 hours

### DHCPScopesDepleted
- **Type:** Integer
- **Default:** 0
- **Purpose:** Scopes with > 90% utilization
- **Populated By:** **TBD: DHCP Server Monitor**
- **Update Frequency:** Every 4 hours

### DHCPLeasesDenied24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: DHCP Server Monitor**
- **Update Frequency:** Every 4 hours

### DHCPScopeSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **TBD: DHCP Server Monitor**
- **Update Frequency:** Every 4 hours

### DHCPHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **TBD: DHCP Server Monitor**
- **Update Frequency:** Every 4 hours

---

## DNS - DNS Server Fields (9 fields)

### DNSInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **TBD: DNS Server Monitor** (Script 3 needs verification)
- **Update Frequency:** Every 4 hours

### DNSZoneCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: DNS Server Monitor**
- **Update Frequency:** Every 4 hours

### DNSQueriesPerSecond
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: DNS Server Monitor**
- **Update Frequency:** Every 4 hours

### DNSFailedQueries24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: DNS Server Monitor**
- **Update Frequency:** Every 4 hours

### DNSRecursionEnabled
- **Type:** Checkbox
- **Default:** True
- **Populated By:** **TBD: DNS Server Monitor**
- **Update Frequency:** Daily

### DNSForwarders
- **Type:** Text
- **Max Length:** 200 characters
- **Populated By:** **TBD: DNS Server Monitor**
- **Update Frequency:** Daily

### DNSZoneTransferErrors24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: DNS Server Monitor**
- **Update Frequency:** Every 4 hours

### DNSZoneSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **TBD: DNS Server Monitor**
- **Update Frequency:** Every 4 hours

### DNSHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **TBD: DNS Server Monitor**
- **Update Frequency:** Every 4 hours

---

## Compound Conditions

### Veeam Backup Failure
```
Condition:
  VEEAMInstalled = True
  AND VEEAMFailedJobsCount > 0

Action:
  Priority: P1 Critical
  Automation: **TBD: Script 45** - Veeam Job Retry (not implemented)
  Ticket: Veeam backup job failed
```

### DHCP Scope Exhaustion
```
Condition:
  DHCPInstalled = True
  AND DHCPScopesDepleted > 0

Action:
  Priority: P2 High
  Automation: **TBD: Script 46** - DHCP Scope Alert (not implemented)
  Ticket: DHCP scope exhaustion warning
```

### DNS Service Critical
```
Condition:
  DNSInstalled = True
  AND DNSHealthStatus = "Critical"

Action:
  Priority: P1 Critical
  Automation: **TBD: Script 47** - DNS Service Restart (not implemented)
  Ticket: DNS service critical failure
```

---

**Total Fields This File:** 37 fields  
**Scripts Required:** Apache, DHCP, DNS, Veeam monitors (TBD) + Scripts 45-47 (remediation - TBD)  
**Update Frequency:** Every 4 hours, Daily  
**Priority Level:** Critical (Core Infrastructure)

**Critical Issue:** Most fields in this document have NO verified script support. Script assignments need verification/implementation.

---

**File:** 14_ROLE_Infrastructure.md  
**Last Updated:** February 2, 2026  
**Framework Version:** 3.0 Complete
