# NinjaRMM Custom Field Framework - Drift, Capacity, and Battery Management
**File:** 12_DRIFT_CAP_BAT_Core_Monitoring.md  
**Categories:** DRIFT (Configuration Drift) + CAP (Capacity Planning) + BAT (Battery Health)  
**Field Count:** ~30 fields  
**Consolidates:** Original files 16, 17, 18

---

## Overview

Core fields for configuration drift detection, capacity planning, and battery health monitoring. Essential for change management, proactive capacity management, and mobile device support.

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
    <td>Windows Update: Manual→Automatic</td>
    <td>2026-01-30</td>
  </tr>
  <tr>
    <td>Admin</td>
    <td style="color:red;">New local admin: jsmith</td>
    <td>2026-01-29</td>
  </tr>
</table>
```

---

## CAP - Capacity Planning Core Fields

### CAPDaysUntilDiskFull
- **Type:** Integer
- **Default:** 999
- **Purpose:** Estimated days until system drive full based on growth trend
- **Populated By:** **Script 22** - Capacity Trend Forecaster
- **Update Frequency:** Weekly
- **Range:** 0 to 999 days

**Calculation:**
```
Method: Linear regression on disk usage over 30 days

If growth_rate > 0:
  days_remaining = free_space / daily_growth_rate
Else:
  days_remaining = 999 (no growth detected)

Cap at 999 for display purposes
```

**Thresholds:**
```
> 180 days = Healthy capacity
90-180 days = Monitor
30-89 days = Plan action
15-29 days = Urgent action needed
< 15 days = Critical
```

---

### CAPMemoryUtilizationTrend
- **Type:** Dropdown
- **Valid Values:** Stable, Increasing, Decreasing, Volatile
- **Default:** Stable
- **Purpose:** 30-day memory usage trend
- **Populated By:** **Script 22** - Capacity Trend Forecaster
- **Update Frequency:** Weekly

**Trend Detection:**
```
Stable:
  - Variance < 10% over 30 days
  - Consistent usage pattern

Increasing:
  - Usage growing > 2% per week
  - Upward trend detected

Decreasing:
  - Usage declining > 2% per week
  - Downward trend detected

Volatile:
  - Variance > 20% over 30 days
  - Inconsistent pattern
```

---

### CAPCPUUtilizationTrend
- **Type:** Dropdown
- **Valid Values:** Stable, Increasing, Decreasing, Volatile
- **Default:** Stable
- **Purpose:** 30-day CPU usage trend
- **Populated By:** **Script 22** - Capacity Trend Forecaster
- **Update Frequency:** Weekly

---

### CAPCapacityHealthScore
- **Type:** Integer (0-100)
- **Default:** 100
- **Purpose:** Overall capacity health score
- **Populated By:** **Script 22** - Capacity Trend Forecaster
- **Update Frequency:** Weekly
- **Range:** 0 to 100

**Scoring Logic:**
```
Base Score: 100

Deductions:
  - Disk free < 20%: -20 points
  - Disk free < 10%: -40 points (override)
  - Days until full < 90: -15 points
  - Days until full < 30: -30 points (override)
  - Memory pressure avg > 80%: -15 points
  - CPU avg > 75%: -15 points
  - Increasing trends: -10 points

Minimum Score: 0
```

---

### CAPCapacityAlert
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Capacity issue requiring attention
- **Populated By:** **Script 22** - Capacity Trend Forecaster
- **Update Frequency:** Weekly

**Triggers:**
```
Set to True if:
  - CAPDaysUntilDiskFull < 30
  - OR STATDiskFreePercent < 15%
  - OR STATMemoryPressure > 90%
  - OR CAPCapacityHealthScore < 50
```

---

## BAT - Battery Health Fields

### BATBatteryPresent
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device has a battery (laptop/tablet)
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Daily

**Detection:**
```PowerShell
$battery = Get-CimInstance -ClassName Win32_Battery
return ($null -ne $battery)
```

---

### BATDesignCapacityMWh
- **Type:** Integer
- **Default:** 0
- **Purpose:** Battery design capacity in milliwatt-hours
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Daily
- **Range:** 0 to 999999 mWh
- **Unit:** Milliwatt-hours

---

### BATFullChargeCapacityMWh
- **Type:** Integer
- **Default:** 0
- **Purpose:** Current full charge capacity in milliwatt-hours
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Daily
- **Range:** 0 to 999999 mWh
- **Unit:** Milliwatt-hours

---

### BATHealthPercent
- **Type:** Integer (0-100)
- **Default:** 100
- **Purpose:** Battery health percentage (full charge / design capacity)
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Daily
- **Range:** 0 to 100 percent

**Calculation:**
```
Battery Health = (Full Charge Capacity / Design Capacity) * 100

Example:
  Design: 60000 mWh
  Full Charge: 48000 mWh
  Health: (48000 / 60000) * 100 = 80%
```

**Health Categories:**
```
90-100% = Excellent (like new)
80-89%  = Good (normal aging)
70-79%  = Fair (noticeable degradation)
60-69%  = Poor (replacement soon)
< 60%   = Critical (replace immediately)
```

---

### BATCycleCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Number of battery charge cycles
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Daily
- **Range:** 0 to 9999

**Cycle Definition:**
```
1 cycle = 100% discharge and recharge
  (Can be accumulated: 50% + 50% = 1 cycle)

Typical Battery Lifespan:
  300-500 cycles: Standard laptop battery
  500-1000 cycles: Premium laptop battery
  1000+ cycles: High-quality battery
```

---

### BATChemistry
- **Type:** Text
- **Max Length:** 50 characters
- **Default:** Unknown
- **Purpose:** Battery chemistry type
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Daily

**Common Values:**
```
Lithium-Ion (Li-Ion)
Lithium-Polymer (LiPo)
Nickel-Metal Hydride (NiMH)
```

---

### BATEstimatedRuntime
- **Type:** Integer
- **Default:** 0
- **Purpose:** Estimated runtime in minutes at current usage
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Every 4 hours
- **Range:** 0 to 9999 minutes
- **Unit:** Minutes

---

### BATChargeStatus
- **Type:** Dropdown
- **Valid Values:** Charging, Discharging, Full, Unknown
- **Default:** Unknown
- **Purpose:** Current battery charge status
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Every 4 hours

---

### BATLastFullCharge
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last full charge (100%)
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Real-time
- **Format:** yyyy-MM-dd HH:mm:ss

---

### BATReplacementRecommended
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Battery replacement recommended
- **Populated By:** **Script 12** - Battery Health Monitor
- **Update Frequency:** Daily

**Triggers:**
```
Set to True if:
  - BATHealthPercent < 70%
  - OR BATCycleCount > 800
  - OR BATEstimatedRuntime < 60 minutes (when full)
  - OR Windows battery warning present
```

---

## Script-to-Field Mapping

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

### Script 22: Capacity Trend Forecaster
**Execution:** Weekly  
**Runtime:** ~35 seconds  
**Fields Updated:**
- CAPDaysUntilDiskFull
- CAPMemoryUtilizationTrend
- CAPCPUUtilizationTrend
- CAPCapacityHealthScore
- CAPCapacityAlert

**Data Requirements:**
- 30 days of historical telemetry
- STATDiskFreePercent history
- STATMemoryPressure history
- STATCPUAveragePercent history

---

### Script 12: Battery Health Monitor
**Execution:** Daily (or Every 4 hours for runtime/status)  
**Runtime:** ~15 seconds  
**Fields Updated:**
- BATBatteryPresent
- BATDesignCapacityMWh
- BATFullChargeCapacityMWh
- BATHealthPercent
- BATCycleCount
- BATChemistry
- BATEstimatedRuntime
- BATChargeStatus
- BATLastFullCharge
- BATReplacementRecommended

**Device Applicability:**
- Laptops
- Tablets
- 2-in-1 devices
- Skipped on desktops/servers

---

## Compound Conditions

### Pattern 1: Configuration Drift Critical
```
Condition:
  DRIFTDriftDetected = True
  AND DRIFTDriftSeverity IN ("Significant", "Critical")

Action:
  Priority: P2 High
  Automation: Drift analysis workflow
  Ticket: Critical configuration drift detected
  Assignment: Security team + desktop support
```

### Pattern 2: Capacity Critical
```
Condition:
  CAPDaysUntilDiskFull < 15
  OR STATDiskFreePercent < 10%

Action:
  Priority: P1 Critical
  Automation: Disk cleanup + capacity expansion
  Ticket: Disk capacity critical
  Assignment: Desktop support (immediate)
```

### Pattern 3: Battery Replacement Due
```
Condition:
  BATBatteryPresent = True
  AND BATReplacementRecommended = True

Action:
  Priority: P3 Medium
  Automation: Battery report generation
  Ticket: Battery replacement recommended
  Assignment: Hardware procurement + desktop support
```

---

## Dynamic Groups

### Group 1: Configuration Drift Detected
```
Condition: DRIFTDriftDetected = True
Purpose: Devices with configuration changes
Automation: Drift review workflow
Policy: Change management
```

### Group 2: Capacity Issues
```
Condition: CAPCapacityAlert = True OR CAPDaysUntilDiskFull < 30
Purpose: Devices with capacity concerns
Automation: Cleanup + expansion
Policy: Proactive capacity management
```

### Group 3: Battery Health Poor
```
Condition: BATBatteryPresent = True AND BATHealthPercent < 70
Purpose: Laptops needing battery replacement
Automation: Replacement workflow
Policy: Hardware lifecycle management
```

---

**Total Fields This File:** ~30 fields  
**Scripts Required:** 3 scripts (Scripts 11, 12, 22)  
**Update Frequencies:** Daily, Weekly, Every 4 hours  
**Priority Level:** High (Change Management & Capacity)

---

**File:** 12_DRIFT_CAP_BAT_Core_Monitoring.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete  
**Consolidates:** Original files 16, 17, 18
