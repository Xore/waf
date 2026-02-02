# Custom Fields - Server Monitoring Scripts 14-20
**Document:** 56_Custom_Fields_Scripts_14_20_Server_Monitoring.md  
**Version:** 4.0  
**Last Updated:** February 2, 2026  
**Scripts Covered:** 14-20 (Server Role Monitoring)

---

## OVERVIEW

This document defines all custom fields required for Scripts 14-20 (Server Monitoring).
These scripts monitor specific server roles and should only run on devices with those roles installed.

**Total Fields:** 60 fields across 7 server role monitoring scripts

---

## SCRIPT 14: DNS Server Monitor

### Fields (4 total)

| Field Name | Type | Values/Format | Description |
|------------|------|---------------|-------------|
| dnsServerInstalled | Checkbox | true/false | DNS Server role installed |
| dnsZoneCount | Integer | 0-999 | Number of DNS zones |
| dnsQueryRate | Integer | 0-999999 | Queries per hour |
| dnsHealthStatus | Dropdown | Healthy, Warning, Critical, Unknown | DNS server health |

### Dropdown Values
**dnsHealthStatus:**
- Healthy
- Warning
- Critical
- Unknown

---

## SCRIPT 15: File Server Monitor

### Fields (4 total)

| Field Name | Type | Values/Format | Description |
|------------|------|---------------|-------------|
| fileServerInstalled | Checkbox | true/false | File Server role installed |
| fileShareCount | Integer | 0-999 | Number of SMB shares |
| fileActiveConnections | Integer | 0-9999 | Active SMB sessions |
| fileHealthStatus | Dropdown | Healthy, Warning, Critical, Unknown | File server health |

### Dropdown Values
**fileHealthStatus:**
- Healthy
- Warning
- Critical
- Unknown

---

## SCRIPT 16: Print Server Monitor

### Fields (4 total)

| Field Name | Type | Values/Format | Description |
|------------|------|---------------|-------------|
| printServerInstalled | Checkbox | true/false | Print Services role installed |
| printPrinterCount | Integer | 0-999 | Number of printers |
| printQueuedJobs | Integer | 0-99999 | Queued print jobs |
| printHealthStatus | Dropdown | Healthy, Warning, Critical, Unknown | Print server health |

### Dropdown Values
**printHealthStatus:**
- Healthy
- Warning
- Critical
- Unknown

---

## SCRIPT 17: BitLocker Monitor

### Fields (4 total)

| Field Name | Type | Values/Format | Description |
|------------|------|---------------|-------------|
| bitlockerEnabled | Checkbox | true/false | BitLocker available |
| bitlockerVolumeCount | Integer | 0-99 | Total volumes |
| bitlockerProtectedVolumes | Integer | 0-99 | Encrypted volumes |
| bitlockerHealthStatus | Dropdown | Healthy, Warning, Critical, Unknown | Encryption health |

### Dropdown Values
**bitlockerHealthStatus:**
- Healthy (all volumes protected)
- Warning (partial protection)
- Critical (no protection)
- Unknown (check failed)

---

## SCRIPT 18: Hyper-V Host Monitor

### Fields (9 total)

| Field Name | Type | Values/Format | Description |
|------------|------|---------------|-------------|
| hvHyperVInstalled | Checkbox | true/false | Hyper-V role installed |
| hvVMCount | Integer | 0-999 | Total VMs |
| hvVMRunningCount | Integer | 0-999 | Running VMs |
| hvVMStoppedCount | Integer | 0-999 | Stopped VMs |
| hvMemoryAssignedGB | Integer | 0-99999 | Memory assigned to VMs (GB) |
| hvStorageUsedGB | Integer | 0-999999 | VM storage used (GB) |
| hvReplicationHealthIssues | Integer | 0-999 | Replication problems |
| hvVMSummary | WYSIWYG | HTML table | VM summary table |
| hvHealthStatus | Dropdown | Healthy, Warning, Critical, Unknown | Hyper-V health |

### Dropdown Values
**hvHealthStatus:**
- Healthy (all VMs running, no issues)
- Warning (some VMs stopped, minor issues)
- Critical (replication failed, major issues)
- Unknown (check failed)

---

## SCRIPT 19: MySQL Server Monitor

### Fields (7 total)

| Field Name | Type | Values/Format | Description |
|------------|------|---------------|-------------|
| mysqlInstalled | Checkbox | true/false | MySQL/MariaDB installed |
| mysqlVersion | Text | Version string | MySQL version |
| mysqlDatabaseCount | Integer | 0-9999 | Number of databases |
| mysqlReplicationStatus | Dropdown | Master, Slave, Error, N/A | Replication role/status |
| mysqlReplicationLag | Integer | 0-99999 | Seconds behind master |
| mysqlSlowQueries24h | Integer | 0-999999 | Slow queries count |
| mysqlHealthStatus | Dropdown | Healthy, Warning, Critical, Unknown | MySQL health |

### Dropdown Values
**mysqlReplicationStatus:**
- Master (is replication source)
- Slave (replication target, running)
- Error (replication broken)
- N/A (standalone server)

**mysqlHealthStatus:**
- Healthy (running, replication OK)
- Warning (running, minor issues)
- Critical (stopped, replication failed)
- Unknown (connection failed)

---

## SCRIPT 20: FlexLM License Monitor

### Fields (11 total)

| Field Name | Type | Values/Format | Description |
|------------|------|---------------|-------------|
| flexlmInstalled | Checkbox | true/false | FlexLM server installed |
| flexlmVersion | Text | Version string | FlexLM version |
| flexlmVendorDaemons | Integer | 0-99 | Vendor daemons count |
| flexlmDaemonsDown | Integer | 0-99 | Failed daemons |
| flexlmTotalLicenses | Integer | 0-99999 | Total licenses |
| flexlmLicensesInUse | Integer | 0-99999 | Licenses checked out |
| flexlmLicenseUtilizationPercent | Integer | 0-100 | License usage % |
| flexlmDeniedRequests24h | Integer | 0-99999 | Denied license requests |
| flexlmExpiringLicenses30d | Integer | 0-999 | Licenses expiring soon |
| flexlmLicenseSummary | WYSIWYG | HTML table | License summary table |
| flexlmHealthStatus | Dropdown | Healthy, Warning, Critical, Unknown | License server health |

### Dropdown Values
**flexlmHealthStatus:**
- Healthy (all daemons up, utilization < 90%)
- Warning (minor issues, utilization 90-95%)
- Critical (daemons down, utilization > 95%)
- Unknown (check failed)

---

## FIELD SUMMARY BY TYPE

### Checkboxes (7 fields)
All "Installed" detection fields:
- dnsServerInstalled
- fileServerInstalled
- printServerInstalled
- bitlockerEnabled
- hvHyperVInstalled
- mysqlInstalled
- flexlmInstalled

### Integers (37 fields)
Count and metric fields for all monitoring scripts

### Text (2 fields)
Version strings:
- mysqlVersion
- flexlmVersion

### Dropdown (8 fields)
Health and status fields:
- dnsHealthStatus
- fileHealthStatus
- printHealthStatus
- bitlockerHealthStatus
- hvHealthStatus
- mysqlHealthStatus
- mysqlReplicationStatus
- flexlmHealthStatus

### WYSIWYG (2 fields)
HTML summary tables:
- hvVMSummary
- flexlmLicenseSummary

---

## DEPLOYMENT CHECKLIST

### NinjaRMM Configuration
1. Create all 60 custom fields in NinjaRMM
2. Configure dropdown values exactly as specified
3. Set field permissions appropriately
4. Test field updates with sample data

### Script Conditions
Each server monitoring script should have a condition to only run on appropriate devices:

**Script 14 (DNS):** Only run on DNS servers  
**Script 15 (File):** Only run on File servers  
**Script 16 (Print):** Only run on Print servers  
**Script 17 (BitLocker):** Run on all devices (optional)  
**Script 18 (Hyper-V):** Only run on Hyper-V hosts  
**Script 19 (MySQL):** Only run on MySQL servers  
**Script 20 (FlexLM):** Only run on License servers

### Role Detection
Scripts self-detect if the role is installed and exit gracefully if not found.
No external conditions required - scripts handle detection internally.

---

## FIELD NAMING CONVENTION

All fields follow this pattern:
- **Prefix:** Role abbreviation (dns, file, print, bitlocker, hv, mysql, flexlm)
- **Camel Case:** Clear, descriptive names
- **Suffixes:** 
  - "Installed" or "Enabled" for detection
  - "Count" for quantities
  - "Percent" for percentages
  - "Status" for health/state
  - "Summary" for HTML tables

---

**Version:** 4.0  
**Status:** Production Ready  
**Total Fields:** 60  
**Scripts:** 14-20  
