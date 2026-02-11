# Hardware Monitoring

**Complete guide to hardware monitoring scripts in the WAF framework.**

---

## Overview

The WAF Hardware Monitoring suite provides 10+ scripts for battery health, temperature monitoring, disk health, and hardware inventory. Designed for mixed environments with laptops, desktops, and servers.

### Script Categories

| Category | Script Count | Primary Focus |
|----------|--------------|---------------|
| Battery & Power | 3 | Laptop battery monitoring |
| System Hardware | 6+ | CPU, disk, peripherals |

**Total:** 10+ scripts | **Complexity:** Beginner to Intermediate

---

## Battery & Power

### BatteryHealthMonitor.ps1 & BatteryHealthMonitor_v2.ps1

**Purpose:** Monitor battery health and degradation.

**v2 Features (Recommended):**
- Battery capacity (design vs current)
- Charge cycles
- Health percentage
- Estimated remaining life
- Charging status
- Power profile

**NinjaOne Custom Fields:**
```powershell
hw_battery_present          # Battery present
hw_battery_health_percent   # Health (0-100)
hw_battery_cycles           # Charge cycles
hw_battery_capacity_design  # Design capacity (mWh)
hw_battery_capacity_current # Current capacity (mWh)
hw_battery_charging         # Charging status
```

**Usage (v2):**

```powershell
# Check battery health
.\BatteryHealthMonitor_v2.ps1

# Detailed report
.\BatteryHealthMonitor_v2.ps1 -Detailed

# Alert if health < 80%
.\BatteryHealthMonitor_v2.ps1 -AlertThreshold 80
```

**Output Example:**
```
=== Battery Health Report ===
Manufacturer: LGC
Model: DELL ABC1234

Capacity:
  Design: 60,000 mWh
  Current: 48,000 mWh
  Health: 80%

Usage:
  Charge Cycles: 245
  Estimated Life: 255 cycles remaining

Status: ⚠️ WARNING
Recommendation: Consider battery replacement within 6 months
```

**Alert Thresholds:**
```powershell
> 90% health: GOOD
80-90% health: FAIR
70-80% health: WARNING
< 70% health: CRITICAL (replace soon)
```

---

### Hardware-CheckBatteryHealth.ps1

**Purpose:** Alternative battery health implementation.

**Usage:**
```powershell
.\Hardware-CheckBatteryHealth.ps1
```

---

## System Hardware

### Hardware-GetCPUTemp.ps1

**Purpose:** Monitor CPU temperature.

**NinjaOne Field:**
```powershell
hw_cpu_temp_celsius         # CPU temperature
```

**Usage:**
```powershell
.\Hardware-GetCPUTemp.ps1
```

**Alert Thresholds:**
```
< 60°C: Normal
60-80°C: Warm (check cooling)
80-90°C: Hot (WARNING)
> 90°C: CRITICAL (thermal throttling)
```

---

### Hardware-GetAttachedMonitors.ps1

**Purpose:** Detect connected monitors.

**NinjaOne Fields:**
```powershell
hw_monitors_count           # Number of monitors
hw_monitors_list            # Monitor models
```

**Usage:**
```powershell
.\Hardware-GetAttachedMonitors.ps1
```

---

### Hardware-GetDellDockInfo.ps1

**Purpose:** Dell docking station information.

**Usage:**
```powershell
.\Hardware-GetDellDockInfo.ps1
```

---

### Hardware-SSDWearHealthAlert.ps1

**Purpose:** SSD wear level monitoring.

**Monitored Metrics:**
- Wear level percentage
- Total bytes written (TBW)
- Bad block count
- SMART status

**NinjaOne Fields:**
```powershell
hw_ssd_wear_level           # Wear level %
hw_ssd_tbw                  # Total bytes written
hw_ssd_smart_status         # SMART status
```

**Usage:**
```powershell
.\Hardware-SSDWearHealthAlert.ps1

# Alert threshold
.\Hardware-SSDWearHealthAlert.ps1 -WearLevelThreshold 80
```

---

### Hardware-USBDriveAlert.ps1

**Purpose:** Alert on USB drive insertion (security).

**Usage:**
```powershell
.\Hardware-USBDriveAlert.ps1
```

---

### Disk-GetSMARTStatus.ps1

**Purpose:** Disk SMART health monitoring.

**Monitored Attributes:**
- Reallocated sectors
- Spin retry count
- Temperature
- Power-on hours
- Overall health status

**NinjaOne Fields:**
```powershell
hw_disk_smart_status        # Pass/Fail
hw_disk_temp_celsius        # Disk temperature
hw_disk_power_on_hours      # Operating hours
```

**Usage:**
```powershell
.\Disk-GetSMARTStatus.ps1

# Alert on predictive failure
.\Disk-GetSMARTStatus.ps1 -AlertOnPredictiveFailure
```

---

## Best Practices

### Monitoring Frequency

| Script | Recommended Interval | Device Type |
|--------|---------------------|-------------|
| BatteryHealthMonitor_v2 | Daily | Laptops |
| Hardware-GetCPUTemp | Hourly | Servers |
| Hardware-SSDWearHealthAlert | Weekly | All with SSD |
| Disk-GetSMARTStatus | Daily | All |

### Alert Thresholds

```powershell
# Battery
- Health < 70%: Replace soon
- Cycles > 500: End of life

# Temperature
- CPU > 85°C: WARNING
- CPU > 95°C: CRITICAL

# SSD Wear
- Wear > 80%: Plan replacement
- Wear > 95%: URGENT

# SMART
- Reallocated sectors > 0: WARNING
- Predictive failure: CRITICAL
```

---

**Last Updated:** 2026-02-11  
**Scripts:** 10+  
**Complexity:** Beginner to Intermediate
