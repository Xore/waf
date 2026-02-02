# NinjaRMM Custom Field Framework - RISK Core Classification

**File:** 12_RISK_Core_Classification.md  
**Version:** v1.0 (Initial Release)  
**Category:** RISK (Classification Fields)  
**Field Count:** 7 RISK fields  
**Last Updated:** February 1, 2026

---

## Overview

RISK fields provide intelligent risk classifications based on OPS scores, STAT telemetry, and NinjaOne native metrics. They drive dynamic groups, automation, and patching decisions.

---

## RISK Fields (7)

### RISKHealthLevel
- Type: Dropdown  
- Valid Values: Healthy, Degraded, Critical, Unknown  
- Default: Unknown  
- Purpose: Overall device health classification  
- Populated By: Script 9 - Risk Classifier  
- Update Frequency: Every 4 hours  
- Data Sources: OPSHealthScore + native metrics

---

### RISKRebootLevel
- Type: Dropdown  
- Valid Values: None, Low, Medium, High, Critical  
- Default: None  
- Purpose: Reboot recommendation level  
- Populated By: Script 9 - Risk Classifier  
- Update Frequency: Every 4 hours  
- Data Sources: STATUptimeDays + Pending Reboot (native) + crash counts

---

### RISKSecurityExposure
- Type: Dropdown  
- Valid Values: Low, Medium, High, Critical  
- Default: Low  
- Purpose: Security risk exposure level  
- Populated By: Script 9 - Risk Classifier  
- Update Frequency: Daily  
- Data Sources: Native security status + custom hardening checks

---

### RISKComplianceFlag
- Type: Dropdown  
- Valid Values: Compliant, Warning, Non-Compliant, Critical  
- Default: Compliant  
- Purpose: Overall compliance status  
- Populated By: Script 9 - Risk Classifier  
- Update Frequency: Daily  
- Data Sources: Multiple native and custom sources

---

### RISKShadowIT
- Type: Checkbox  
- Default: False  
- Purpose: Shadow IT detected (unauthorized software)  
- Populated By: Script 9 - Risk Classifier  
- Update Frequency: Daily  
- Detection: Based on drift / software baseline fields

---

### RISKDataLossRisk
- Type: Dropdown  
- Valid Values: Low, Medium, High, Critical  
- Default: Low  
- Purpose: Data loss risk assessment  
- Populated By: Script 9 - Risk Classifier  
- Update Frequency: Daily  
- Data Sources: Backup Status (native) + Disk Space (native) + SMART (native)

---

### RISKLastRiskAssessment
- Type: DateTime  
- Default: Empty  
- Purpose: Timestamp of last risk classification  
- Populated By: Script 9 - Risk Classifier  
- Update Frequency: Every 4 hours  
- Format: yyyy-MM-dd HH:mm:ss

---

## Script-to-RISK Mapping

Script 9: Risk Classifier  
- Updates:  
  - RISKHealthLevel  
  - RISKRebootLevel  
  - RISKSecurityExposure  
  - RISKComplianceFlag  
  - RISKShadowIT  
  - RISKDataLossRisk  
  - RISKLastRiskAssessment  

---

File: 12_RISK_Core_Classification.md  
Framework Version: v1.0  
Status: Production Ready
