# NinjaRMM Custom Field Framework - Security Monitoring
**File:** 08_SEC_Security_Monitoring.md  
**Category:** SEC (Security Monitoring)  
**Field Count:** 10 fields  
**Extracted From:** 14_BASE_SEC_UPD_Core_Security_Baseline.md

---

## Overview

Security monitoring fields track the security posture of endpoints including antivirus status, firewall configuration, encryption status, and security protocol compliance.

---

## SEC - Security Monitoring Fields

### SECAntivirusInstalled
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Antivirus software installed on system
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Every 4 hours

**Detection Logic:**
```
Checks for:
  - Windows Defender
  - Third-party AV (Symantec, McAfee, Trend Micro, etc.)
  - Security Center registration
```

---

### SECAntivirusEnabled
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Antivirus real-time protection active
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Every 4 hours

---

### SECAntivirusUpToDate
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Antivirus definitions current (< 7 days old)
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Every 4 hours

---

### SECFirewallEnabled
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Windows Firewall enabled on all profiles
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Every 4 hours

**Validation:**
```
All profiles must be enabled:
  - Domain Profile
  - Private Profile
  - Public Profile
```

---

### SECBitLockerEnabled
- **Type:** Checkbox
- **Default:** False
- **Purpose:** BitLocker encryption enabled on system drive
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

---

### SECBitLockerStatus
- **Type:** Dropdown
- **Valid Values:** Fully Encrypted, Encrypting, Suspended, Decrypted, Not Enabled
- **Default:** Not Enabled
- **Purpose:** Detailed BitLocker encryption status
- **Populated By:** **Script 7** - BitLocker Monitor
- **Update Frequency:** Daily

**Status Definitions:**
```
Fully Encrypted:
  - Encryption complete
  - Protection enabled

Encrypting:
  - Encryption in progress
  - Protection enabled

Suspended:
  - Encryption complete
  - Protection temporarily disabled

Decrypted:
  - Decryption complete
  - No protection

Not Enabled:
  - BitLocker never configured
```

---

### SECSMBv1Enabled
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Insecure SMBv1 protocol enabled (security risk)
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Daily

**Security Impact:**
```
SMBv1 vulnerabilities:
  - WannaCry ransomware vector
  - No encryption support
  - Known exploits

Recommendation: Disable SMBv1
```

---

### SECOpenPorts
- **Type:** Text
- **Max Length:** 500 characters
- **Purpose:** List of open listening ports on system
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Daily

**Format:**
```
80 (HTTP), 443 (HTTPS), 3389 (RDP), 445 (SMB)
```

---

### SECUACEnabled
- **Type:** Checkbox
- **Default:** True
- **Purpose:** User Access Control (UAC) enabled
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Daily

**Security Levels:**
```
Enabled (Recommended):
  - Always notify
  - Notify on changes

Disabled (Risk):
  - No UAC prompts
  - Security vulnerability
```

---

### SECSecureBootEnabled
- **Type:** Checkbox
- **Default:** False
- **Purpose:** UEFI Secure Boot enabled
- **Populated By:** **Script 4** - Security Analyzer
- **Update Frequency:** Daily

**Requirements:**
```
Required for:
  - Windows 11
  - Credential Guard
  - Device Guard
  - Modern security features
```

---

## Script-to-Field Mapping

### Script 4: Security Analyzer
**Execution:** Every 4 hours (AV checks), Daily (full scan)  
**Runtime:** ~30 seconds  
**Fields Updated:** All SEC fields except BitLocker (8 fields)

**Scan Workflow:**
1. Check antivirus installation and status
2. Verify firewall configuration
3. Check SMBv1 status
4. Scan open ports
5. Verify UAC status
6. Check Secure Boot status

---

### Script 7: BitLocker Monitor
**Execution:** Daily  
**Runtime:** ~15 seconds  
**Fields Updated:** SECBitLockerEnabled, SECBitLockerStatus (2 fields)

**Monitoring Workflow:**
1. Query BitLocker status for all volumes
2. Check encryption percentage
3. Verify protection status
4. Update status fields

---

## Compound Conditions

### Pattern 1: Critical Security Controls Disabled
```
Condition:
  SECAntivirusEnabled = False
  OR SECFirewallEnabled = False

Action:
  Priority: P1 Critical
  Automation: Attempt to enable controls
  Ticket: Critical security controls disabled
  Alert: Immediate notification
```

### Pattern 2: Antivirus Definitions Outdated
```
Condition:
  SECAntivirusInstalled = True
  AND SECAntivirusUpToDate = False

Action:
  Priority: P2 High
  Automation: Force definition update
  Ticket: Antivirus definitions outdated
```

### Pattern 3: SMBv1 Security Risk
```
Condition:
  SECSMBv1Enabled = True

Action:
  Priority: P2 High
  Automation: Disable SMBv1 (if no dependencies)
  Ticket: SMBv1 security vulnerability detected
```

### Pattern 4: Encryption Not Enabled
```
Condition:
  SECBitLockerStatus = "Not Enabled"
  AND DeviceType = "Laptop"

Action:
  Priority: P3 Medium
  Automation: None (requires user interaction)
  Ticket: BitLocker encryption recommended
```

---

**Total Fields:** 10 fields  
**Scripts Required:** 2 scripts (Scripts 4, 7)  
**Related Categories:** BASE (Baseline), UPD (Updates)

---

**File:** 08_SEC_Security_Monitoring.md  
**Last Updated:** February 2, 2026  
**Framework Version:** 3.0
