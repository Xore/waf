# NinjaRMM Custom Field Framework - BAT Fields
**File:** 16_BAT_Battery_Health.md
**Category:** BAT (Battery Health)
**Description:** Battery health monitoring for mobile devices

---

## Overview

Battery health fields monitor battery capacity, degradation, charge cycles, and recommend replacement for laptops and mobile devices in the Windows Automation Framework.

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

## Script Integration

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

**Total Fields:** 10 fields
**Category:** BAT (Battery Health)
**Last Updated:** February 2, 2026
