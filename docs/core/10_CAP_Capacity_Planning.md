# NinjaRMM Custom Field Framework - CAP Fields
**File:** 10_CAP_Capacity_Planning.md
**Category:** CAP (Capacity Planning)
**Description:** Capacity trend forecasting and resource utilization analysis

---

## Overview

Capacity planning fields forecast resource exhaustion, track utilization trends, and provide proactive capacity alerts for the Windows Automation Framework.

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

## Script Integration

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

**Total Fields:** 5 fields
**Category:** CAP (Capacity Planning)
**Last Updated:** February 2, 2026
