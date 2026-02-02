# NinjaRMM Custom Field Framework - DRIFT Fields
**File:** 14_DRIFT_Configuration_Drift.md
**Category:** DRIFT (Configuration Drift)
**Description:** Configuration drift detection and change management

---

## Overview

Configuration drift fields detect and track changes to system configuration compared to established baselines for the Windows Automation Framework.

---

## DRIFT - Configuration Drift Core Fields

### DRIFTDriftDetected
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Any configuration drift detected since baseline
- **Populated By:** **Script 11** - Configuration Drift Detector
- **Update Frequency:** Daily

**Triggers:**
```
Set to True if ANY drift detected in:
  - Software installations/removals
  - Service configuration changes
  - Startup program changes
  - Local administrator changes
  - Network configuration changes
  - Group Policy changes
```

---

### DRIFTLastDriftDate
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of most recent drift detection
- **Populated By:** **Script 11** - Configuration Drift Detector
- **Update Frequency:** Daily
- **Format:** yyyy-MM-dd HH:mm:ss

---

### DRIFTDriftCategory
- **Type:** Dropdown
- **Valid Values:** None, Software, Service, Startup, Admin, Network, Policy, Multiple
- **Default:** None
- **Purpose:** Primary category of detected drift
- **Populated By:** **Script 11** - Configuration Drift Detector
- **Update Frequency:** Daily

---

### DRIFTDriftSeverity
- **Type:** Dropdown
- **Valid Values:** None, Minor, Moderate, Significant, Critical
- **Default:** None
- **Purpose:** Severity assessment of configuration drift
- **Populated By:** **Script 11** - Configuration Drift Detector
- **Update Frequency:** Daily

**Severity Logic:**
```
None:
  - No drift detected

Minor:
  - 1-2 non-critical changes
  - User-initiated changes
  - Low security impact

Moderate:
  - 3-5 changes
  - OR 1 service configuration change
  - Medium security impact

Significant:
  - 6-10 changes
  - OR administrative changes
  - OR security-relevant changes
  - High security impact

Critical:
  - 11+ changes
  - OR critical service disabled
  - OR unauthorized admin added
  - OR security controls disabled
```

---

### DRIFTDriftSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Purpose:** HTML summary of all detected drift
- **Populated By:** **Script 11** - Configuration Drift Detector
- **Update Frequency:** Daily

**Example HTML:**
```html
<h4>Configuration Drift Detected</h4>
<table>
  <tr>
    <th>Category</th>
    <th>Change</th>
    <th>Detected</th>
  </tr>
  <tr>
    <td>Software</td>
    <td>Added: Chrome v121</td>
    <td>2026-01-30</td>
  </tr>
  <tr>
    <td>Service</td>
    <td>Windows Update: Manual to Automatic</td>
    <td>2026-01-30</td>
  </tr>
  <tr>
    <td style="color:red;">Admin</td>
    <td style="color:red;">New local admin: jsmith</td>
    <td>2026-01-29</td>
  </tr>
</table>
```

---

## Script Integration

### Script 11: Configuration Drift Detector
**Execution:** Daily
**Runtime:** ~40 seconds
**Fields Updated:**
- DRIFTDriftDetected
- DRIFTLastDriftDate
- DRIFTDriftCategory
- DRIFTDriftSeverity
- DRIFTDriftSummary

**Prerequisites:**
- Baseline established (Script 18 must run first)
- Baseline age < 90 days recommended

---

**Total Fields:** 5 fields
**Category:** DRIFT (Configuration Drift)
**Last Updated:** February 2, 2026
