# NinjaRMM Custom Field Framework - Baseline, Security, and Updates
**File:** 14_BASE_SEC_UPD_Core_Security_Baseline.md  
**Categories:** BASE (Baseline) + SEC (Security) + UPD (Updates)  
**Field Count:** ~35 fields  
**Consolidates:** Original files 22, 23, 24

---

## Overview

Core baseline management, security monitoring, and update compliance fields. Foundation for configuration management, security posture, and patch management.

---

## BASE - Baseline Management Core Fields

### BASEBaselineEstablished
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Initial configuration baseline captured
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Once, then validated daily

### BASEBaselineDate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Date baseline was established
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Once

### BASESoftwareList
- **Type:** WYSIWYG
- **Purpose:** Baseline list of installed software
- **Populated By:** **Script 18** - Baseline Establishment
- **Update Frequency:** Baseline establishment, refreshed quarterly

### BASEServiceList
- **Type:** WYSIWYG
- **Purpose:** Baseline list of Windows services
- **Populated By:** **Script 18** - Baseline Establishment

### BASEProcessList
- **Type:** WYSIWYG
- **Purpose:** Baseline list of running processes
- **Populated By:** **Script 18** - Baseline Establishment

### BASEStartupList
- **Type:** WYSIWYG
- **Purpose:** Baseline list of startup programs
- **Populated By:** **Script 18** - Baseline Establishment

### BASELocalAdmins
- **Type:** WYSIWYG
- **Purpose:** Baseline list of local administrators
- **Populated By:** **Script 18** - Baseline Establishment

---

## SEC - Security Monitoring Core Fields

### SECAntivirusInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Every 4 hours

### SECAntivirusEnabled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Every 4 hours

### SECAntivirusUpToDate
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Every 4 hours

### SECFirewallEnabled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Every 4 hours

### SECBitLockerEnabled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

### SECBitLockerStatus
- **Type:** Dropdown
- **Valid Values:** Fully Encrypted, Encrypting, Suspended, Decrypted, Not Enabled
- **Default:** Not Enabled
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

### SECSMBv1Enabled
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Insecure SMBv1 protocol enabled
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Daily

### SECOpenPorts
- **Type:** Text
- **Max Length:** 500 characters
- **Purpose:** List of open listening ports
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Daily

### SECUACEnabled
- **Type:** Checkbox
- **Default:** True
- **Purpose:** User Access Control enabled
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Daily

### SECSecureBootEnabled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Daily

---

## UPD - Update Management Core Fields

### UPDLastWindowsUpdate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Date of last installed Windows update
- **Populated By:** **Script 23** - Update Compliance Monitor
- **Update Frequency:** Daily

### UPDPendingReboot
- **Type:** Checkbox
- **Default:** False
- **Purpose:** System restart required for updates
- **Populated By:** **Script 23** - Update Compliance Monitor
- **Update Frequency:** Every 4 hours

### UPDMissingUpdatesCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Count of missing Windows updates
- **Populated By:** **Script 23** - Update Compliance Monitor
- **Update Frequency:** Daily

### UPDMissingSecurityCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Count of missing security updates (critical)
- **Populated By:** **Script 23** - Update Compliance Monitor
- **Update Frequency:** Daily

### UPDLastScanDate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Last Windows Update scan
- **Populated By:** **Script 23** - Update Compliance Monitor
- **Update Frequency:** Daily

### UPDComplianceStatus
- **Type:** Dropdown
- **Valid Values:** Compliant, Minor Gap, Significant Gap, Critical Gap, Unknown
- **Default:** Unknown
- **Populated By:** **Script 23** - Update Compliance Monitor
- **Update Frequency:** Daily

**Compliance Logic:**
```
Compliant:
  - Last update < 30 days
  - Missing security updates = 0

Minor Gap:
  - Last update 30-45 days
  - OR missing 1-2 non-security updates

Significant Gap:
  - Last update 45-90 days
  - OR missing 1-2 security updates
  - OR missing 5+ non-security updates

Critical Gap:
  - Last update > 90 days
  - OR missing 3+ security updates

Unknown:
  - Cannot determine status
```

---

## Script-to-Field Mapping

### Script 4: Security Analyzer
**Execution:** Every 4 hours (AV), Daily (full scan)  
**Runtime:** ~30 seconds  
**Fields Updated:** All SEC fields except BitLocker

### Script 7: BitLocker Monitor
**Execution:** Daily  
**Runtime:** ~15 seconds  
**Fields Updated:** SECBitLockerEnabled, SECBitLockerStatus

### Script 18: Baseline Establishment
**Execution:** Once (initial), On-demand (refresh)  
**Runtime:** ~2 minutes  
**Fields Updated:** All BASE fields

### Script 23: Update Compliance Monitor
**Execution:** Daily  
**Runtime:** ~45 seconds  
**Fields Updated:** All UPD fields

---

## Compound Conditions

### Pattern 1: Baseline Not Established
```
Condition:
  BASEBaselineEstablished = False

Action:
  Priority: P3 Medium
  Automation: Run Script 18 (Baseline Establishment)
  Ticket: Baseline establishment required
```

### Pattern 2: Security Controls Disabled
```
Condition:
  SECAntivirusEnabled = False
  OR SECFirewallEnabled = False

Action:
  Priority: P1 Critical
  Automation: Enable security controls
  Ticket: Critical security controls disabled
```

### Pattern 3: Updates Critical Gap
```
Condition:
  UPDComplianceStatus = "Critical Gap"
  OR UPDMissingSecurityCount > 3

Action:
  Priority: P1 Critical
  Automation: Force Windows Update scan
  Ticket: Critical updates missing
```

---

**Total Fields This File:** ~35 fields  
**Scripts Required:** 4 scripts (Scripts 4, 7, 18, 23)

---

**File:** 14_BASE_SEC_UPD_Core_Security_Baseline.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete
