# NinjaRMM Custom Field Framework - Additional Server Roles
**File:** 24_EVT_FS_PRINT_HV_BL_FEAT_FLEXLM_Additional_Roles.md  
**Categories:** EVT + FS + PRINT + HV + BL + FEAT + FLEXLM  
**Field Count:** 54 fields  
**Target:** Servers with specialized roles

---

## Overview

Monitoring for specialized server roles including Event Log management, File Servers, Print Servers, Hyper-V hosts, BitLocker encryption, Windows Features, and FlexLM license servers.

---

## EVT - Event Log Management Fields (7 fields)

### EVTEventLogFullCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Count of full event logs
- **Populated By:** **Script 4** - Event Log Monitor
- **Update Frequency:** Daily

### EVTCriticalErrors24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 4** - Event Log Monitor
- **Update Frequency:** Every 4 hours

### EVTWarnings24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 4** - Event Log Monitor
- **Update Frequency:** Every 4 hours

### EVTSecurityEvents24h
- **Type:** Integer
- **Default:** 0
- **Purpose:** Security-related events
- **Populated By:** **Script 4** - Event Log Monitor
- **Update Frequency:** Every 4 hours

### EVTTopErrorSource
- **Type:** Text
- **Max Length:** 200 characters
- **Populated By:** **Script 4** - Event Log Monitor
- **Update Frequency:** Daily

### EVTEventLogSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **Script 4** - Event Log Monitor
- **Update Frequency:** Daily

### EVTHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **Script 4** - Event Log Monitor
- **Update Frequency:** Daily

---

## FS - File Server Fields (8 fields)

### FSFileServerRole
- **Type:** Checkbox
- **Default:** False
- **Purpose:** File Server role installed
- **Populated By:** **Script 5** - File Server Monitor
- **Update Frequency:** Daily

### FSShareCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 5** - File Server Monitor
- **Update Frequency:** Daily

### FSOpenFileCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 5** - File Server Monitor
- **Update Frequency:** Every 4 hours

### FSConnectedUsersCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 5** - File Server Monitor
- **Update Frequency:** Every 4 hours

### FSQuotaExceeded
- **Type:** Integer
- **Default:** 0
- **Purpose:** Number of users exceeding quota
- **Populated By:** **Script 5** - File Server Monitor
- **Update Frequency:** Daily

### FSShareAccessErrors24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 5** - File Server Monitor
- **Update Frequency:** Every 4 hours

### FSShareSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **Script 5** - File Server Monitor
- **Update Frequency:** Daily

### FSHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **Script 5** - File Server Monitor
- **Update Frequency:** Daily

---

## PRINT - Print Server Fields (8 fields)

### PRINTPrintServerRole
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 6** - Print Server Monitor
- **Update Frequency:** Daily

### PRINTPrinterCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 6** - Print Server Monitor
- **Update Frequency:** Daily

### PRINTQueueCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 6** - Print Server Monitor
- **Update Frequency:** Daily

### PRINTPrintJobsStuck
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 6** - Print Server Monitor
- **Update Frequency:** Every 4 hours

### PRINTPrinterErrors24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 6** - Print Server Monitor
- **Update Frequency:** Every 4 hours

### PRINTOfflinePrinters
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 6** - Print Server Monitor
- **Update Frequency:** Every 4 hours

### PRINTPrinterSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **Script 6** - Print Server Monitor
- **Update Frequency:** Daily

### PRINTHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **Script 6** - Print Server Monitor
- **Update Frequency:** Daily

---

## HV - Hyper-V Host Fields (9 fields)

### HVHyperVInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Daily

### HVVMCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Total virtual machines
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Every 4 hours

### HVVMRunningCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Every 4 hours

### HVVMStoppedCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Every 4 hours

### HVMemoryAssignedGB
- **Type:** Integer
- **Default:** 0
- **Purpose:** Total memory assigned to VMs
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Every 4 hours

### HVStorageUsedGB
- **Type:** Integer
- **Default:** 0
- **Purpose:** VM storage consumption
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Daily

### HVReplicationHealthIssues
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Every 4 hours

### HVVMSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Every 4 hours

### HVHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **Script 8** - Hyper-V Host Monitor
- **Update Frequency:** Every 4 hours

---

## BL - BitLocker Extended Fields (6 fields)

### BLVolumeCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Total BitLocker-enabled volumes
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

### BLFullyEncryptedCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

### BLEncryptionInProgress
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Every 4 hours

### BLRecoveryKeyEscrowed
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Recovery keys backed up to AD
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

### BLVolumeSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

### BLComplianceStatus
- **Type:** Dropdown
- **Valid Values:** Compliant, Partial, Non-Compliant, Unknown
- **Default:** Unknown
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

---

## FEAT - Windows Features Fields (5 fields)

### FEATServerRoleCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Installed server roles
- **Populated By:** **Script 36** - Server Role Detector
- **Update Frequency:** Daily

### FEATFeatureCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Installed Windows features
- **Populated By:** **Script 36** - Server Role Detector
- **Update Frequency:** Daily

### FEATInstalledRoles
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **Script 36** - Server Role Detector
- **Update Frequency:** Daily

### FEATInstalledFeatures
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **Script 36** - Server Role Detector
- **Update Frequency:** Daily

### FEATRoleChangeDetected
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Role/feature change since baseline
- **Populated By:** **Script 36** - Server Role Detector
- **Update Frequency:** Daily

---

## FLEXLM - FlexLM License Server Fields (11 fields)

### FLEXLMInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

### FLEXLMVersion
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Daily

### FLEXLMVendorDaemons
- **Type:** Integer
- **Default:** 0
- **Purpose:** Number of vendor daemons
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

### FLEXLMTotalLicenses
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

### FLEXLMLicensesInUse
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

### FLEXLMLicenseUtilizationPercent
- **Type:** Integer (0-100)
- **Default:** 0
- **Calculation:** (InUse / Total) * 100
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

### FLEXLMDeniedRequests24h
- **Type:** Integer
- **Default:** 0
- **Purpose:** License checkout denials
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

### FLEXLMDaemonsDown
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

### FLEXLMExpiringLicenses30d
- **Type:** Integer
- **Default:** 0
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Daily

### FLEXLMLicenseSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

### FLEXLMHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **Script 12** - FlexLM License Monitor
- **Update Frequency:** Every 4 hours

---

## Compound Conditions

### File Server Share Access Issues
```
Condition:
  FSFileServerRole = True
  AND FSShareAccessErrors24h > 10

Action:
  Priority: P3 Medium
  Automation: **Script 48** - File Share Diagnostics
  Ticket: File server access issues
```

### Print Server Queue Stuck
```
Condition:
  PRINTPrintServerRole = True
  AND PRINTPrintJobsStuck > 5

Action:
  Priority: P2 High
  Automation: **Script 49** - Clear Print Queues
  Ticket: Print jobs stuck in queue
```

### Hyper-V VM Critical
```
Condition:
  HVHyperVInstalled = True
  AND HVHealthStatus = "Critical"

Action:
  Priority: P1 Critical
  Automation: **Script 50** - Hyper-V Health Check
  Ticket: Hyper-V host critical issue
```

### FlexLM License Exhaustion
```
Condition:
  FLEXLMInstalled = True
  AND FLEXLMLicenseUtilizationPercent > 90

Action:
  Priority: P2 High
  Automation: **Script 51** - FlexLM Alert
  Ticket: FlexLM license capacity warning
```

### BitLocker Non-Compliant
```
Condition:
  BLComplianceStatus = "Non-Compliant"

Action:
  Priority: P3 Medium
  Automation: **Script 52** - BitLocker Enablement
  Ticket: BitLocker encryption required
```

---

## Script-to-Field Mapping Summary

### Script 4: Event Log Monitor
**Fields:** 7 EVT fields  
**Frequency:** Daily / Every 4 hours

### Script 5: File Server Monitor
**Fields:** 8 FS fields  
**Frequency:** Daily / Every 4 hours

### Script 6: Print Server Monitor
**Fields:** 8 PRINT fields  
**Frequency:** Daily / Every 4 hours

### Script 7: BitLocker Monitor
**Fields:** 6 BL fields  
**Frequency:** Daily / Every 4 hours

### Script 8: Hyper-V Host Monitor
**Fields:** 9 HV fields  
**Frequency:** Every 4 hours

### Script 12: FlexLM License Monitor
**Fields:** 11 FLEXLM fields  
**Frequency:** Every 4 hours

### Script 36: Server Role Detector
**Fields:** 5 FEAT fields  
**Frequency:** Daily

---

**Total Fields This File:** 54 fields  
**Scripts Required:** Scripts 4-8, 12, 36 (monitoring) + Scripts 48-52 (remediation)  
**Update Frequencies:** Daily, Every 4 hours  
**Priority Level:** High (Specialized Infrastructure)

---

**File:** 24_EVT_FS_PRINT_HV_BL_FEAT_FLEXLM_Additional_Roles.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete
