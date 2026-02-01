# Scripts 01-13 Infrastructure Monitoring (Native-Enhanced)
**File:** 55_Scripts_01_13_Infrastructure_Monitoring.md  
**Version:** 1.0 (Native Integration)  
**Script Count:** 11 active scripts (down from 13)  
**Last Updated:** February 1, 2026

---

## OVERVIEW

This document covers Scripts 1-13 of the infrastructure monitoring framework. In Version 4.0, Scripts 7 and 8 have been deprecated and replaced by NinjaOne's native monitoring capabilities.

**Active Scripts:** 1-6, 9-13 (11 total)  
**Deprecated Scripts:** 7-8 (2 scripts replaced by native)

---

## SCRIPT 1: Health Score Calculator

### Purpose
Calculate overall device health composite score combining multiple data sources.

### Execution Details
- **Frequency:** Every 4 hours
- **Runtime:** ~15 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

### Native Integration (v4.0)
- Queries **Disk Free Space** (native) for capacity assessment
- Queries **Memory Utilization** (native) for pressure detection
- Queries **CPU Utilization** (native) for performance assessment
- Combines with custom telemetry (STATAppCrashes24h, etc.)

### Fields Updated
- OPSHealthScore (Integer 0-100)
- OPSLastScoreUpdate (DateTime)

### PowerShell Implementation
```powershell
try {
    Write-Output "Starting Health Score Calculator (v4.0 Native-Enhanced)"

    # Initialize base score
    $healthScore = 100

    # Query native metrics
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    $cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    # Query custom telemetry
    $crashes = Ninja-Property-Get STATAppCrashes24h
    if ([string]::IsNullOrEmpty($crashes)) { $crashes = 0 }

    # Calculate deductions
    if ($crashes -gt 10) { $healthScore -= 20 }
    elseif ($crashes -gt 5) { $healthScore -= 10 }
    elseif ($crashes -gt 2) { $healthScore -= 5 }

    if ($diskFreePercent -lt 5) { $healthScore -= 30 }
    elseif ($diskFreePercent -lt 10) { $healthScore -= 20 }
    elseif ($diskFreePercent -lt 15) { $healthScore -= 15 }

    if ($memUtilization -gt 95) { $healthScore -= 20 }
    elseif ($memUtilization -gt 90) { $healthScore -= 15 }
    elseif ($memUtilization -gt 85) { $healthScore -= 10 }

    if ($cpuUtilization -gt 90) { $healthScore -= 15 }
    elseif ($cpuUtilization -gt 80) { $healthScore -= 10 }

    # Ensure score stays within bounds
    if ($healthScore -lt 0) { $healthScore = 0 }
    if ($healthScore -gt 100) { $healthScore = 100 }

    # Update fields
    Ninja-Property-Set OPSHealthScore $healthScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Health Score = $healthScore"
    Write-Output "  Disk Free: $diskFreePercent%"
    Write-Output "  Memory Utilization: $memUtilization%"
    Write-Output "  CPU Utilization: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  Crashes (24h): $crashes"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## SCRIPT 2: Stability Analyzer

### Purpose
Calculate system and application stability score based on crashes and failures.

### Execution Details
- **Frequency:** Every 4 hours
- **Runtime:** ~10 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

### Native Integration (v4.0)
- Reads **Windows Event Log** (native) for service failures
- Combines with custom crash counts (STATAppCrashes24h, STATBSODCount30d)

### Fields Updated
- OPSStabilityScore (Integer 0-100)
- OPSLastScoreUpdate (DateTime)

### Key Logic
```powershell
Base Score: 100

Deductions:
  - Each application crash (24h): -2 points
  - Each application hang (24h): -1.5 points
  - Each service failure: -3 points
  - Each BSOD (30d): -20 points
  - Uptime < 24h with crashes: -10 points
```

---

## SCRIPT 3: Performance Analyzer

### Purpose
Calculate system performance and responsiveness score.

### Execution Details
- **Frequency:** Every 4 hours
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

### Native Integration (v4.0)
- Queries **CPU Utilization** (native) for processor load
- Queries **Memory Utilization** (native) for memory pressure
- Queries **Disk Active Time** (native) for I/O performance
- Supplements with custom boot time measurement

### Fields Updated
- OPSPerformanceScore (Integer 0-100)
- OPSLastScoreUpdate (DateTime)

### Key Logic
```powershell
Base Score: 100

Deductions (using native metrics):
  - CPU Utilization > 80%: -15 points
  - Memory Utilization > 85%: -15 points
  - Disk Active Time > 80%: -10 points
  - Boot time > 120s: -15 points (custom)
```

---

## SCRIPT 4: Security Analyzer

### Purpose
Calculate security posture score based on security controls.

### Execution Details
- **Frequency:** Daily
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Native Integration (v4.0)
- Queries **Antivirus Status** (native) for AV state
- Queries **Patch Status** (native) for update compliance
- Queries **Firewall Status** (native) for firewall state
- Supplements with BitLocker, SMBv1, and hardening checks (custom)

### Fields Updated
- OPSSecurityScore (Integer 0-100)
- OPSLastScoreUpdate (DateTime)

### Key Logic
```powershell
Base Score: 100

Deductions (using native metrics):
  - Antivirus disabled/not installed (native): -40 points
  - Firewall disabled (native): -30 points
  - BitLocker disabled: -15 points (custom check)
  - Critical patches missing (native): -15 points
  - SMBv1 enabled: -10 points (custom check)
```

---

## SCRIPT 5: Capacity Analyzer

### Purpose
Calculate resource capacity and headroom score.

### Execution Details
- **Frequency:** Daily
- **Runtime:** ~15 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

### Native Integration (v4.0)
- Queries **Disk Free Space** (native) for storage capacity
- Queries **Memory Utilization** (native) for memory capacity
- Combines with CAPDaysUntilDiskFull (custom predictive field)

### Fields Updated
- OPSCapacityScore (Integer 0-100)
- OPSLastScoreUpdate (DateTime)

### Key Logic
```powershell
Base Score: 100

Deductions (using native metrics):
  - Disk Free Space < 20% (native): -30 points
  - Disk Free Space < 10% (native): -50 points (override)
  - Memory Utilization > 85% (native): -20 points
  - Days until disk full < 30 (custom): -15 points
```

---

## SCRIPT 6: Telemetry Collector

### Purpose
Collect custom telemetry not available natively (crashes, hangs, failures).

### Execution Details
- **Frequency:** Every 4 hours
- **Runtime:** ~25 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Why Custom (Not Native)
NinjaOne doesn't aggregate crash/hang/failure counts over time periods. This script provides historical frequency tracking essential for stability scoring.

### Fields Updated
- STATAppCrashes24h (Integer) - Application crash count
- STATAppHangs24h (Integer) - Application hang count
- STATServiceFailures24h (Integer) - Service failure count
- STATBSODCount30d (Integer) - BSOD count
- STATUptimeDays (Integer) - Days since reboot
- STATLastTelemetryUpdate (DateTime) - Last collection timestamp

### Event Sources
- Application Event Log: Event IDs 1000, 1001 (crashes), 1002 (hangs)
- System Event Log: Event IDs 7031, 7034 (service failures), 1001 (BugCheck), 41 (Kernel-Power)

---

## ~~SCRIPT 7: Resource Monitor~~ (DEPRECATED)

### Status
**DEPRECATED in v4.0 - Replaced by NinjaOne Native Monitoring**

### Previous Purpose
Collected CPU, Memory, Disk metrics via custom PowerShell script.

### Previous Fields Updated
- ~~STATCPUAveragePercent~~ → Use **CPU Utilization** (native)
- ~~STATMemoryPressure~~ → Use **Memory Utilization** (native)
- ~~STATDiskFreePercent~~ → Use **Disk Free Space** (native)
- ~~STATDiskFreeGB~~ → Use **Disk Free Space** (native)
- ~~STATDiskResponseTimeMs~~ → Use **Disk Active Time** (native)

### Migration Action
**DELETE THIS SCRIPT** from NinjaRMM. Update all compound conditions and scripts to use native metrics instead.

### Why Deprecated
- Native monitoring provides real-time data (vs 4-hour script delay)
- Hardware-level accuracy from NinjaOne agent
- No script execution overhead
- More reliable (doesn't fail like custom scripts)

---

## ~~SCRIPT 8: Network Monitor~~ (DEPRECATED)

### Status
**DEPRECATED in v4.0 - Replaced by NinjaOne Native Monitoring**

### Previous Purpose
Measured network latency to default gateway.

### Previous Fields Updated
- ~~STATNetworkLatencyMs~~ → Use **Network Performance** (native SNMP)

### Migration Action
**DELETE THIS SCRIPT** from NinjaRMM. Use NinjaOne's native network monitoring for latency tracking.

### Why Deprecated
- Native SNMP-based monitoring more comprehensive
- Continuous monitoring vs periodic script
- Better network diagnostics available natively

---

## SCRIPT 9: Risk Classifier

### Purpose
Classify devices into risk categories based on multiple data sources.

### Execution Details
- **Frequency:** Every 4 hours
- **Runtime:** ~10 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

### Native Integration (v4.0)
- Queries **Backup Status** (native) for data loss risk
- Queries **SMART Status** (native) for hardware risk
- Queries **Pending Reboot** (native) for reboot recommendation
- Queries **Antivirus Status**, **Firewall Status**, **Patch Status** (native) for security risk
- Combines with OPS scores and STAT telemetry (custom)

### Fields Updated
- RISKHealthLevel (Dropdown: Healthy, Degraded, Critical, Unknown)
- RISKRebootLevel (Dropdown: None, Low, Medium, High, Critical)
- RISKSecurityExposure (Dropdown: Low, Medium, High, Critical)
- RISKComplianceFlag (Dropdown: Compliant, Warning, Non-Compliant, Critical)
- RISKShadowIT (Checkbox)
- RISKDataLossRisk (Dropdown: Low, Medium, High, Critical)
- RISKLastRiskAssessment (DateTime)

### Key Classifications

**Health Level:**
- Healthy: OPSHealthScore >= 70, no critical native alerts
- Degraded: OPSHealthScore 40-69, or multiple minor native alerts
- Critical: OPSHealthScore < 40, or critical native alert

**Data Loss Risk:**
- Low: Backup Success (native, < 24h), Disk > 20%, SMART Healthy (native)
- Medium: Backup 24-72h old, or Disk < 20%
- High: Backup Failed (> 72h), or Disk < 10%, or SMART Warning
- Critical: No backup (> 7 days), Disk < 5%, SMART Failed

---

## SCRIPT 10: Update Assessment Collector

### Purpose
Collect Windows Update compliance data and aggregate patch counts.

### Execution Details
- **Frequency:** Daily
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Native Integration (v4.0)
- Queries **Patch Status** (native) and aggregates by severity
- Supplements with custom reboot tracking

### Fields Updated
- UPDMissingCriticalCount (Integer)
- UPDMissingImportantCount (Integer)
- UPDMissingOptionalCount (Integer)
- UPDDaysSinceLastReboot (Integer)

---

## SCRIPT 11: Network Location Tracker

### Purpose
Track network location changes for network-aware policy application.

### Execution Details
- **Frequency:** Every 4 hours
- **Runtime:** ~10 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

### Fields Updated
- NETLocationCurrent (Dropdown: Office, Remote, Unknown)
- NETLocationPrevious (Dropdown: Office, Remote, Unknown)
- NETVPNConnected (Checkbox)

### Use Cases
- Apply different security policies based on location
- Track device movement for security monitoring
- VPN compliance enforcement for remote users

---

## SCRIPT 12: Baseline Manager

### Purpose
Establish and track performance baselines, detect drift.

### Execution Details
- **Frequency:** Daily
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

### Native Integration (v4.0)
- Uses native metrics (CPU, Memory, Disk) to establish baseline
- Compares current native metrics to baseline for drift detection

### Fields Updated
- BASEBusinessCriticality (Dropdown: Standard, High, Critical)
- BASEDriftScore (Integer 0-100)
- BASEPerformanceBaseline (Text/JSON)

---

## SCRIPT 13: Drift Detector

### Purpose
Detect configuration drift and unauthorized software installations.

### Execution Details
- **Frequency:** Daily
- **Runtime:** ~25 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Fields Updated
- DRIFTNewAppsCount (Integer)

### Use Cases
- Shadow IT detection
- Compliance monitoring
- Change management validation

---

## SCRIPT EXECUTION SUMMARY

### Active Scripts (11 Total)

| Script | Name | Frequency | Runtime | Fields | Native Integration |
|--------|------|-----------|---------|--------|-------------------|
| 1 | Health Score Calculator | 4 hours | 15s | 2 | Disk, Memory, CPU |
| 2 | Stability Analyzer | 4 hours | 10s | 2 | Event Log |
| 3 | Performance Analyzer | 4 hours | 20s | 2 | CPU, Memory, Disk |
| 4 | Security Analyzer | Daily | 30s | 2 | AV, Patches, Firewall |
| 5 | Capacity Analyzer | Daily | 15s | 2 | Disk, Memory |
| 6 | Telemetry Collector | 4 hours | 25s | 6 | Event Log (aggregation) |
| 9 | Risk Classifier | 4 hours | 10s | 7 | Backup, SMART, Reboot, Security |
| 10 | Update Assessment | Daily | 30s | 4 | Patch Status |
| 11 | Network Location | 4 hours | 10s | 3 | None (custom tracking) |
| 12 | Baseline Manager | Daily | 20s | 3 | CPU, Memory, Disk (baseline) |
| 13 | Drift Detector | Daily | 25s | 1 | None (custom detection) |

**Total Execution Time (per cycle):**
- 4-hour cycle: ~80 seconds (Scripts 1, 2, 3, 6, 9, 11)
- Daily cycle: ~120 seconds (Scripts 4, 5, 10, 12, 13)

### Deprecated Scripts (2 Total)

| Script | Name | Reason | Replacement |
|--------|------|--------|-------------|
| 7 | Resource Monitor | Native monitoring superior | CPU/Memory/Disk (native) |
| 8 | Network Monitor | Native monitoring superior | Network Performance (native) |

**Scripts Eliminated:** 2 (15% reduction in script count)

---

## DEPLOYMENT NOTES

### New Deployments (v4.0)
1. Deploy Scripts 1-6, 9-13 (skip 7-8)
2. Configure native monitoring in NinjaRMM
3. Scripts 1-5 will query native metrics automatically
4. No custom field creation for deprecated metrics

### Migrations (v3.0 → v4.0)
1. Update Scripts 1-5 to query native metrics
2. Disable/delete Scripts 7-8
3. Update compound conditions to use native metrics
4. Archive (don't delete) deprecated custom fields
5. Test on pilot group before full rollout

---

**Version:** 1.0 (Native Integration)  
**Last Updated:** February 1, 2026, 5:04 PM CET  
**Active Scripts:** 11 (down from 13)  
**Deprecated Scripts:** 2 (Scripts 7-8)  
**Total Execution Time:** ~200 seconds per day  
**Status:** Production Ready
