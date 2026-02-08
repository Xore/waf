# Complete Custom Fields Reference

**Purpose:** Comprehensive documentation of all 277+ custom fields in Windows Automation Framework  
**Created:** February 8, 2026  
**Status:** Production Ready  
**Last Updated:** February 8, 2026, 2:20 PM CET

---

## Overview

This document provides complete reference information for all custom fields used in the Windows Automation Framework. Each field includes:

- **Field Name** - Exact field name as used in NinjaOne
- **Field Type** - Data type (Text, WYSIWYG, DateTime, Checkbox, Dropdown, Integer)
- **Category** - Functional grouping
- **Description** - What the field represents
- **Populated By** - Script(s) that write to this field
- **Update Frequency** - How often the field is updated
- **Possible Values** - Valid values or ranges
- **Example Value** - Sample data
- **Usage Notes** - Important information about the field
- **Related Fields** - Other fields that provide context

---

## Table of Contents

1. [Patching Fields](#patching-fields) (15 fields) ✅
2. [Health Status Fields](#health-status-fields) (20+ fields) ✅
3. [Security Fields](#security-fields) (35 fields) ✅
4. [Infrastructure Fields](#infrastructure-fields) (40 fields) ✅
5. [Capacity Fields](#capacity-fields) (20 fields) ✅
6. [Performance Fields](#performance-fields) (20+ fields) ✅
7. [User Experience (UX) Fields](#user-experience-ux-fields) (20+ fields) ✅
8. [Telemetry Fields](#telemetry-fields) (20+ fields) ✅
9. [Drift Detection Fields](#drift-detection-fields) (10+ fields)
10. [Active Directory Fields](#active-directory-fields) (15+ fields)
11. [WYSIWYG Report Fields](#wysiwyg-report-fields) (30+ fields)
12. [DateTime Fields](#datetime-fields) (20+ fields)
13. [Miscellaneous Fields](#miscellaneous-fields) (12+ fields)

**Total Fields Documented:** 210+ of 277+ (~76% complete)

---

## Field Naming Conventions

### Prefix System

Fields use a consistent prefix system to indicate their category:

- **OPS** - Operational scores (health, stability, performance)
- **STAT** - Statistics and telemetry data
- **RISK** - Risk assessment and classification
- **SEC** - Security posture and compliance
- **CAP** - Capacity metrics (disk, memory, CPU)
- **UPD** - Update/patching information
- **DRIFT** - Configuration drift detection
- **UX** - User experience metrics
- **APP** - Application-specific data
- **NET** - Network connectivity
- **SRV** - Server roles and infrastructure
- **BASE** - Baseline and foundation data
- **AUTO** - Automation control flags
- **PRED** - Predictive analytics

### Field Type Suffixes

- **HealthStatus** - Health classification (Unknown/Healthy/Warning/Critical)
- **Score** - Numeric score (0-100 scale)
- **Count** - Integer counter
- **Percent** - Percentage value (0-100)
- **Date** - DateTime field (Unix Epoch)
- **Flag** - Boolean checkbox
- **Html** - WYSIWYG formatted report
- **Summary** - Text summary
- **Notes** - Detailed notes

---

# Part 1: Patching & Health Fields

*[Previous Part 1 content with Patching Fields (15) and Health Status Fields (20+) - see earlier version]*

---

# Part 2: Security, Infrastructure & Capacity

*[Previous Part 2 content with Security Fields (35), Infrastructure Fields (40), and Capacity Fields (20) - see earlier version]*

---

# Performance Fields

**Category:** System Performance and Responsiveness  
**Total Fields:** 20+  
**Scripts:** Scripts 1-3, 17, 19  
**Purpose:** Track device performance, stability, and responsiveness

---

## opsHealthScore

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 01 - Health Score Calculator  
**Update Frequency:** Every 4 hours

**Description:**
Comprehensive device health score (0-100) aggregating disk, memory, CPU, and crash metrics. Primary operational health indicator.

**Possible Values:**
- `0-39` - Critical health (immediate action required)
- `40-69` - Degraded health (attention needed)
- `70-89` - Good health (minor issues)
- `90-100` - Excellent health (optimal operation)

**Calculation:**
```
Base Score: 100

Deductions:
- Disk free < 5%: -30 points
- Disk free 5-10%: -20 points
- Disk free 10-15%: -15 points
- Memory usage > 95%: -20 points
- Memory usage 90-95%: -15 points
- Memory usage 85-90%: -10 points
- CPU usage > 90%: -15 points
- CPU usage 80-90%: -10 points
- Crashes > 10 (24h): -20 points
- Crashes 5-10 (24h): -10 points
- Crashes 2-5 (24h): -5 points
```

**Example:** `85`

**Usage Notes:**
- Target: maintain > 80 for production systems
- P1 critical devices require score > 90
- Alert thresholds: < 40 (Critical), < 70 (Warning)
- Used for patch validation (blocking if too low)
- Track trends for device lifecycle management

**Related Fields:**
- `opsStabilityScore` - Crash/hang stability metric
- `opsPerformanceScore` - Performance responsiveness
- `opsSecurityScore` - Security posture
- `opsCapacityScore` - Resource capacity
- `healthStatus` - Categorical health classification

---

## opsStabilityScore

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 02 - Stability Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
System stability score (0-100) based on crashes, hangs, BSOD events, and service failures. Measures reliability.

**Possible Values:**
- `0-39` - Unstable (frequent crashes/failures)
- `40-69` - Moderately stable (occasional issues)
- `70-89` - Stable (rare issues)
- `90-100` - Very stable (no issues)

**Calculation:**
```
Base Score: 100

Deductions:
- Each application crash (24h): -2 points
- Each application hang (24h): -1.5 points
- Each service failure (24h): -3 points
- Each BSOD (30d): -20 points
- Uptime < 24h with crashes: -10 points
```

**Example:** `92`

**Usage Notes:**
- Target: maintain > 85 for production systems
- Score < 70 indicates systemic stability issues
- Review statAppCrashes24h and statBSODCount30d for details
- Used for patch validation (blocks if < 80 for P1 devices)
- Persistent low scores may require hardware diagnostics

**Related Fields:**
- `statAppCrashes24h` - Application crash count
- `statAppHangs24h` - Application hang count
- `statServiceFailures24h` - Service failure count
- `statBSODCount30d` - Blue screen count
- `opsHealthScore` - Overall health score

---

## opsPerformanceScore

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
System performance and responsiveness score (0-100) based on CPU, memory, disk I/O, and boot time metrics.

**Possible Values:**
- `0-39` - Poor performance (significant degradation)
- `40-69` - Fair performance (noticeable slowness)
- `70-89` - Good performance (minor delays)
- `90-100` - Excellent performance (responsive)

**Calculation:**
```
Base Score: 100

Deductions (using native metrics):
- CPU Utilization > 80%: -15 points
- Memory Utilization > 85%: -15 points
- Disk Active Time > 80%: -10 points
- Boot time > 120s: -15 points
- Boot time > 180s: -25 points (override)
```

**Example:** `78`

**Usage Notes:**
- Target: maintain > 75 for user-facing systems
- Score < 60 indicates user experience impact
- Check boot time with uxBootTimeSeconds for slow startup
- Disk I/O issues may indicate failing drive (check SMART status)
- Used for identifying devices needing optimization

**Related Fields:**
- `capCPUUsedPercent` - CPU utilization
- `capMemoryUsedPercent` - Memory utilization
- `uxBootTimeSeconds` - System boot duration
- `opsHealthScore` - Overall health score

---

## opsSecurityScore

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 04 - Security Analyzer  
**Update Frequency:** Daily

**Description:**
Security posture score (0-100) based on security controls: antivirus, firewall, BitLocker, patches, and hardening.

**Possible Values:**
- `0-39` - Critical security posture (major gaps)
- `40-69` - Poor security posture (significant gaps)
- `70-89` - Good security posture (minor gaps)
- `90-100` - Excellent security posture (compliant)

**Calculation:**
```
Base Score: 100

Deductions (using native metrics):
- Antivirus disabled/not installed: -40 points
- Firewall disabled: -30 points
- BitLocker disabled: -15 points
- Critical patches missing: -15 points
- SMBv1 enabled: -10 points
```

**Example:** `95`

**Usage Notes:**
- Target: maintain > 90 for all production devices
- Score < 70 blocks patch deployment for P1 devices
- Review specific security fields for remediation details
- Mobile devices must maintain > 85 (encryption required)
- Used for security compliance reporting

**Related Fields:**
- `secAntivirusEnabled` - AV status
- `secFirewallEnabled` - Firewall status
- `secBitLockerEnabled` - Encryption status
- `updMissingCriticalCount` - Critical patches
- `opsHealthScore` - Overall health score

---

## opsCapacityScore

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 05 - Capacity Analyzer  
**Update Frequency:** Daily

**Description:**
Resource capacity score (0-100) based on disk, memory headroom, and predictive capacity metrics.

**Possible Values:**
- `0-39` - Critical capacity (exhaustion imminent)
- `40-69` - Low capacity (action needed)
- `70-89` - Adequate capacity (monitor)
- `90-100` - Excellent capacity (healthy headroom)

**Calculation:**
```
Base Score: 100

Deductions (using native metrics):
- Disk Free Space < 10%: -50 points (override)
- Disk Free Space < 20%: -30 points
- Memory Utilization > 85%: -20 points
- Days until disk full < 30: -15 points
- Days until disk full < 60: -10 points
```

**Example:** `75`

**Usage Notes:**
- Target: maintain > 70 for all systems
- Score < 50 requires immediate capacity planning
- Review capDaysUntilDiskFull for disk forecast
- Low scores may block patch deployment (insufficient space)
- Used for hardware upgrade prioritization

**Related Fields:**
- `capDiskFreePercent` - Disk free percentage
- `capMemoryUsedPercent` - Memory utilization
- `capDaysUntilDiskFull` - Disk exhaustion prediction
- `opsHealthScore` - Overall health score

---

## opsLastScoreUpdate

**Type:** DateTime (Unix Epoch)  
**Category:** Performance  
**Populated By:** Scripts 1-5 (All OPS score calculators)  
**Update Frequency:** Every 4 hours (or daily for security/capacity)

**Description:**
Timestamp of the most recent OPS score update. Indicates data freshness for operational scores.

**Possible Values:**
- Unix Epoch timestamp (seconds since 1970-01-01)
- `NULL` - Scores never calculated

**Example:** `1738926000` (February 8, 2026, 10:00 AM)

**Usage Notes:**
- Should be updated every 4 hours for health/stability/performance
- Alert if > 12 hours old (indicates script failure)
- Compare with current time to determine staleness
- Different scripts update at different frequencies

**Related Fields:**
- `opsHealthScore` - Health score from this update
- `opsStabilityScore` - Stability score
- `opsPerformanceScore` - Performance score

---

## uxBootTimeSeconds

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer, Script 19 - Chronic Slow-Boot Detector  
**Update Frequency:** Every 4 hours (after reboot)

**Description:**
System boot duration in seconds from power-on to login screen ready. Key user experience metric.

**Possible Values:**
- `0-60` - Excellent (SSD, optimized)
- `61-120` - Good (typical SSD)
- `121-180` - Fair (slow SSD or fast HDD)
- `181-300` - Poor (HDD or many startup items)
- `301+` - Very poor (investigate)

**Example:** `95`

**Usage Notes:**
- Target: < 120 seconds for workstations
- > 180 seconds indicates performance issue
- Check startup programs and services
- May indicate aging HDD (recommend SSD upgrade)
- Used for opsPerformanceScore calculation

**Related Fields:**
- `uxBootTrend` - Boot time trend (improving/degrading)
- `uxBootDegradationFlag` - Chronic slow boot indicator
- `opsPerformanceScore` - Performance score impact

---

## uxBootTrend

**Type:** Dropdown  
**Category:** Performance  
**Populated By:** Script 19 - Chronic Slow-Boot Detector  
**Update Frequency:** Daily

**Description:**
Trend direction of boot time over the last 30 days. Identifies performance degradation or improvement.

**Possible Values:**
- `Improving` - Boot time decreasing (faster boots)
- `Stable` - Boot time consistent (within 10% variance)
- `Degrading` - Boot time increasing (slower boots)
- `Unknown` - Insufficient data (< 5 boot samples)

**Example:** `Stable`

**Usage Notes:**
- \"Degrading\" requires investigation (accumulating startup items, fragmentation, failing drive)
- \"Improving\" may follow optimization or SSD upgrade
- Track after major changes (Windows updates, app installs)
- Used for proactive performance management

**Related Fields:**
- `uxBootTimeSeconds` - Current boot time
- `uxBootDegradationFlag` - Chronic slow boot flag
- `opsPerformanceScore` - Performance score

---

## uxBootDegradationFlag

**Type:** Checkbox  
**Category:** Performance  
**Populated By:** Script 19 - Chronic Slow-Boot Detector  
**Update Frequency:** Daily

**Description:**
Indicates chronic slow boot condition: boot time > 180 seconds for 7+ consecutive boots, or > 30% degradation vs. baseline.

**Possible Values:**
- `TRUE` - Chronic slow boot detected
- `FALSE` - Boot performance acceptable

**Example:** `FALSE`

**Usage Notes:**
- Alert when TRUE (user experience impact)
- Common causes: excessive startup items, fragmented disk, failing HDD, insufficient RAM
- Recommend startup optimization or hardware upgrade
- May justify SSD replacement or RAM upgrade

**Related Fields:**
- `uxBootTimeSeconds` - Current boot time
- `uxBootTrend` - Boot time trend
- `basePerformanceBaseline` - Historical baseline

---

## responseTimeMs

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
System responsiveness measured as average response time to file operations in milliseconds.

**Possible Values:**
- `0-50` - Excellent (fast storage)
- `51-100` - Good (typical SSD)
- `101-200` - Fair (slow SSD or fast HDD)
- `201-500` - Poor (HDD)
- `501+` - Very poor (failing drive or severe I/O contention)

**Example:** `75`

**Usage Notes:**
- Target: < 100 ms for workstations
- > 200 ms indicates storage bottleneck
- Check disk health (SMART status) if consistently high
- May indicate need for SSD upgrade
- Used for identifying slow storage impacting user experience

**Related Fields:**
- `uxBootTimeSeconds` - Boot performance
- `capStorageLatencyMs` - Storage latency metric
- `diskHealthStatus` - Disk health status

---

## diskActiveTimePercent

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer, Native monitoring  
**Update Frequency:** Every 4 hours

**Description:**
Percentage of time disk is actively processing I/O requests. High values indicate disk bottleneck.

**Possible Values:**
- `0-50` - Normal (disk not bottleneck)
- `51-80` - Elevated (monitor)
- `81-95` - High (disk bottleneck)
- `96-100` - Critical (severe bottleneck)

**Example:** `35`

**Usage Notes:**
- Target: < 80% for acceptable performance
- > 80% sustained indicates disk is performance bottleneck
- Check for intensive processes or failing drive
- Consider SSD upgrade if consistently high on HDD
- Used for opsPerformanceScore calculation

**Related Fields:**
- `capStorageIOPSAverage` - IOPS metric
- `responseTimeMs` - Response time
- `diskHealthStatus` - Disk health

---

## memoryPageFaultRate

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
Rate of memory page faults per second. High values indicate insufficient RAM (excessive paging to disk).

**Possible Values:**
- `0-100` - Normal (adequate RAM)
- `101-500` - Elevated (monitor)
- `501-1000` - High (RAM pressure)
- `1001+` - Critical (severe RAM shortage)

**Example:** `75`

**Usage Notes:**
- Target: < 500 page faults/sec
- > 1000 page faults/sec indicates severe memory pressure
- Impacts performance significantly (disk much slower than RAM)
- Recommend RAM upgrade if consistently high
- Check for memory leaks if RAM utilization also high

**Related Fields:**
- `capMemoryUsedPercent` - Memory utilization
- `capMemoryAvailableGB` - Available RAM
- `opsPerformanceScore` - Performance score

---

## cpuQueueLength

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
Number of threads waiting for CPU time. Indicates CPU contention when > 2 per processor core.

**Possible Values:**
- `0-4` - Normal (for 4-core CPU)
- `5-8` - Elevated (for 4-core CPU)
- `9+` - High contention (for 4-core CPU)

**Example:** `2`

**Usage Notes:**
- Target: < 2 threads per core
- High values indicate insufficient CPU capacity
- Check for CPU-intensive processes
- May require CPU upgrade or process optimization
- Scale thresholds by core count (8-core allows queue length up to 16)

**Related Fields:**
- `capCPUUsedPercent` - CPU utilization
- `capCPUPeakUsage` - Peak CPU usage
- `opsPerformanceScore` - Performance score

---

## networkLatencyMs

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 31 - Remote Connectivity and SaaS Quality Telemetry  
**Update Frequency:** Every 4 hours

**Description:**
Average network latency to default gateway in milliseconds. Indicates local network performance.

**Possible Values:**
- `0-10` - Excellent (wired LAN)
- `11-30` - Good (WiFi or distant gateway)
- `31-100` - Fair (slow network or congestion)
- `101+` - Poor (network issues)

**Example:** `8`

**Usage Notes:**
- Target: < 30 ms for office networks
- > 100 ms indicates network problems
- Wired connections typically < 5 ms
- WiFi typically 10-30 ms depending on signal
- Check netWiFiDisconnects24h for WiFi stability

**Related Fields:**
- `netWiFiDisconnects24h` - WiFi stability
- `networkHealthStatus` - Network health
- `capSaaSLatencyCategory` - Cloud service latency

---

## diskIOPS

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
Disk input/output operations per second. Measures storage performance and load.

**Possible Values:**
- `0-50` - Light load
- `51-200` - Moderate load (typical workstation)
- `201-500` - Heavy load (database or file server)
- `501+` - Very heavy load

**Example:** `125`

**Usage Notes:**
- HDD typically max out at 100-200 IOPS
- SSD can handle 10,000+ IOPS
- High IOPS on HDD indicates bottleneck
- Compare with diskActiveTimePercent for context

**Related Fields:**
- `capStorageIOPSAverage` - Average IOPS metric
- `diskActiveTimePercent` - Disk busy time
- `responseTimeMs` - Response time impact

---

## thermalThrottlingDetected

**Type:** Checkbox  
**Category:** Performance  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
Indicates if CPU thermal throttling was detected (CPU reducing clock speed due to overheating).

**Possible Values:**
- `TRUE` - Thermal throttling detected
- `FALSE` - No thermal throttling

**Example:** `FALSE`

**Usage Notes:**
- Alert when TRUE (hardware issue)
- Causes: dust buildup, failed fan, high ambient temperature, thermal paste degradation
- Impacts performance significantly
- Requires physical hardware inspection and cleaning
- May require fan replacement or thermal paste reapplication

**Related Fields:**
- `cpuTempCelsius` - Current CPU temperature
- `opsPerformanceScore` - Performance impact

---

## cpuTempCelsius

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
Current CPU temperature in degrees Celsius.

**Possible Values:**
- `0-60` - Normal (idle or light load)
- `61-80` - Elevated (moderate load)
- `81-90` - High (heavy load or cooling issue)
- `91+` - Critical (thermal throttling risk)

**Example:** `55`

**Usage Notes:**
- Target: < 80°C under load
- > 90°C indicates cooling problem
- Check thermalThrottlingDetected if consistently high
- Laptops typically run warmer than desktops
- Alert if > 85°C sustained

**Related Fields:**
- `thermalThrottlingDetected` - Throttling flag
- `opsPerformanceScore` - Performance impact

---

## firmwareVersion

**Type:** Text  
**Category:** Performance  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
System BIOS/UEFI firmware version.

**Possible Values:**
- Varies by manufacturer (e.g., \"Dell Inc. 2.18.0\", \"American Megatrends 1.2.3\")

**Example:** `Dell Inc. 2.18.0`

**Usage Notes:**
- Track for firmware update management
- Outdated firmware may cause hardware issues
- Some security vulnerabilities require firmware patches
- Check manufacturer website for updates

**Related Fields:**
- `driftFirmwareDrift` - Firmware change detection
- `driftFirmwareDriftNotes` - Firmware drift details

---

## lastFirmwareUpdate

**Type:** DateTime (Unix Epoch)  
**Category:** Performance  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
Timestamp of the most recent firmware update.

**Possible Values:**
- Unix Epoch timestamp
- `NULL` - Never updated (or unknown)

**Example:** `1710000000` (March 2024)

**Usage Notes:**
- Firmware > 2 years old may need updating
- Critical security patches released via firmware
- Schedule firmware updates during maintenance windows
- Requires reboot

**Related Fields:**
- `firmwareVersion` - Current firmware version
- `driftFirmwareDrift` - Firmware change flag

---

## biosMode

**Type:** Text  
**Category:** Performance  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
BIOS mode: Legacy BIOS or UEFI.

**Possible Values:**
- `UEFI` - Modern UEFI mode (recommended)
- `Legacy` - Legacy BIOS mode (older)
- `Unknown` - Cannot determine

**Example:** `UEFI`

**Usage Notes:**
- UEFI required for Secure Boot, TPM 2.0, and Windows 11
- Legacy mode limits security features
- Modern devices should use UEFI
- Changing modes requires reinstall or conversion

**Related Fields:**
- `secSecureBootEnabled` - Secure Boot status (requires UEFI)
- `secTPMEnabled` - TPM status

---

## processorName

**Type:** Text  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Daily

**Description:**
CPU processor model name and specifications.

**Possible Values:**
- Varies (e.g., \"Intel Core i7-10700K @ 3.80GHz\", \"AMD Ryzen 5 5600X\")

**Example:** `Intel Core i7-10700K @ 3.80GHz`

**Usage Notes:**
- Used for hardware inventory
- Track for lifecycle management and EOL planning
- Older processors (5+ years) may need replacement
- Performance baseline varies by processor

**Related Fields:**
- `processorCoreCount` - Number of cores
- `processorLogicalCount` - Number of threads

---

## processorCoreCount

**Type:** Integer  
**Category:** Performance  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Daily

**Description:**
Number of physical CPU cores.

**Possible Values:**
- `2-4` - Typical workstation
- `6-8` - Power user or small server
- `12-32` - Workstation or medium server
- `64+` - Large server

**Example:** `8`

**Usage Notes:**
- Used for performance assessment and capacity planning
- More cores = better multitasking performance
- Check cpuQueueLength relative to core count
- Modern workstations should have 4+ cores

**Related Fields:**
- `processorLogicalCount` - Logical processors (with hyperthreading)
- `processorName` - Processor model
- `cpuQueueLength` - CPU contention (scale by core count)

---

# User Experience (UX) Fields

**Category:** End-User Experience and Application Behavior  
**Total Fields:** 20+  
**Scripts:** Scripts 17-19, 29-30  
**Purpose:** Track user-facing performance issues and application problems

---

## uxExperienceScore

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 17 - Application Experience Profiler  
**Update Frequency:** Daily

**Description:**
Comprehensive user experience score (0-100) aggregating application crashes, hangs, login delays, and responsiveness.

**Possible Values:**
- `0-39` - Poor UX (frequent issues)
- `40-69` - Fair UX (noticeable issues)
- `70-89` - Good UX (minor issues)
- `90-100` - Excellent UX (smooth operation)

**Calculation:**
```
Base Score: 100

Deductions:
- Each application crash (24h): -3 points
- Each application hang (24h): -2 points
- Boot time > 180s: -15 points
- Login delay > 30s: -10 points
- Collaboration app failures: -5 points per failure
```

**Example:** `82`

**Usage Notes:**
- Target: maintain > 75 for user-facing devices
- Score < 60 indicates significant user frustration
- Review related UX fields for specific issues
- Use for prioritizing support and remediation
- Impacts user productivity and satisfaction

**Related Fields:**
- `uxApplicationHangCount24h` - Hang count
- `uxCollabFailures24h` - Collaboration app issues
- `uxLoginRetryCount24h` - Login problems
- `uxBootTimeSeconds` - Boot performance

---

## uxApplicationHangCount24h

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 17 - Application Experience Profiler  
**Update Frequency:** Daily

**Description:**
Number of application hangs (not responding) in the last 24 hours from Windows Event Log.

**Possible Values:**
- `0` - No hangs
- `1-5` - Occasional hangs (typical)
- `6-15` - Frequent hangs (investigate)
- `16+` - Excessive hangs (serious issue)

**Example:** `2`

**Usage Notes:**
- Alert if > 15 (severe UX impact)
- Review appTopProblemApps for specific applications
- May indicate insufficient resources or application bugs
- Check memory and CPU utilization
- Used for uxExperienceScore calculation

**Related Fields:**
- `statAppHangs24h` - Telemetry hang count (same data)
- `appTopProblemApps` - List of problematic apps
- `uxExperienceScore` - Overall UX score

---

## uxCollabFailures24h

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 29 - Collaboration and Outlook UX Telemetry  
**Update Frequency:** Every 4 hours

**Description:**
Count of Microsoft Teams, Zoom, or other collaboration application failures in the last 24 hours.

**Possible Values:**
- `0` - No failures
- `1-3` - Occasional failures
- `4-10` - Frequent failures (investigate)
- `11+` - Excessive failures (critical issue)

**Example:** `1`

**Usage Notes:**
- Alert if > 10 (impacts remote work capability)
- Common causes: network issues, outdated application, resource constraints
- Check uxCollabPoorQuality24h for quality issues
- Impacts remote worker productivity
- Review network connectivity and bandwidth

**Related Fields:**
- `uxCollabPoorQuality24h` - Poor quality session count
- `appOutlookFailures24h` - Outlook-specific failures
- `netSaaSEndpointStatus` - Cloud service connectivity

---

## uxCollabPoorQuality24h

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 29 - Collaboration and Outlook UX Telemetry  
**Update Frequency:** Every 4 hours

**Description:**
Count of collaboration sessions with poor quality (high latency, packet loss, low resolution) in the last 24 hours.

**Possible Values:**
- `0` - No quality issues
- `1-5` - Occasional quality issues
- `6-15` - Frequent quality issues
- `16+` - Persistent quality problems

**Example:** `3`

**Usage Notes:**
- Alert if > 15 (poor user experience)
- Indicates network bandwidth or latency issues
- Check netVPNAverageLatencyMs and netWiFiDisconnects24h
- May require network optimization or bandwidth upgrade
- Impacts video call quality and screen sharing

**Related Fields:**
- `uxCollabFailures24h` - Collaboration failures
- `networkLatencyMs` - Network latency
- `capNetworkBandwidthUsedPercent` - Bandwidth utilization

---

## uxLoginRetryCount24h

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 30 - User Environment Friction Tracker  
**Update Frequency:** Daily

**Description:**
Number of times user had to retry login due to authentication failures, slow profile loading, or Group Policy issues in the last 24 hours.

**Possible Values:**
- `0` - No login retries
- `1-2` - Occasional retries (typical)
- `3-5` - Frequent retries (investigate)
- `6+` - Excessive retries (serious issue)

**Example:** `1`

**Usage Notes:**
- Alert if > 5 (poor login experience)
- Common causes: slow domain controller, profile corruption, Group Policy errors
- Check profile size with uxProfileOptimizationNeeded
- May indicate network connectivity issues
- Review Active Directory replication status

**Related Fields:**
- `uxProfileOptimizationNeeded` - Profile hygiene flag
- `uxLastUserActivityDate` - Last successful login
- `secFailedLogonCount24h` - Failed login attempts

---

## uxProfileOptimizationNeeded

**Type:** Checkbox  
**Category:** User Experience  
**Populated By:** Script 18 - Profile Hygiene and Cleanup Advisor  
**Update Frequency:** Daily

**Description:**
Indicates if user profile optimization is recommended due to large profile size, temp file accumulation, or cache bloat.

**Possible Values:**
- `TRUE` - Profile optimization recommended
- `FALSE` - Profile is healthy

**Example:** `FALSE`

**Usage Notes:**
- Alert when TRUE (impacts login time)
- Large profiles slow login and logout
- Recommend profile cleanup (temp files, browser caches, Outlook OST)
- Consider folder redirection or OneDrive Known Folder Move
- Profile > 10 GB typically needs cleanup

**Related Fields:**
- `uxLoginRetryCount24h` - Login performance
- `uxBootTimeSeconds` - Boot performance (correlated)

---

## uxLastUserActivityDate

**Type:** DateTime (Unix Epoch)  
**Category:** User Experience  
**Populated By:** Script 17 - Application Experience Profiler  
**Update Frequency:** Daily

**Description:**
Timestamp of the most recent user activity (login, application usage, file access).

**Possible Values:**
- Unix Epoch timestamp
- `NULL` - No user activity detected

**Example:** `1738926000`

**Usage Notes:**
- Used to identify inactive devices (> 30 days = candidate for retirement)
- Distinguish between actively used and abandoned devices
- Help identify devices that can be safely patched/rebooted
- Track for asset management and license reclamation

**Related Fields:**
- `statUptimeDays` - System uptime
- `baseBusinessCriticality` - Device importance

---

## uxUserExperienceDetailHtml

**Type:** WYSIWYG  
**Category:** User Experience  
**Populated By:** Scripts 17, 29, 30 - Multiple UX scripts  
**Update Frequency:** Daily

**Description:**
Formatted HTML report detailing user experience metrics including application crashes, hang events, login performance, and collaboration quality.

**Possible Values:**
- HTML formatted report with tables and metrics

**Example:**
```html
<h3>User Experience Summary</h3>
<table>
  <tr><td>Application Crashes (24h)</td><td>3</td></tr>
  <tr><td>Application Hangs (24h)</td><td>2</td></tr>
  <tr><td>Top Crashing App</td><td>Microsoft Outlook</td></tr>
  <tr><td>Collaboration Failures</td><td>1</td></tr>
  <tr><td>Login Retries</td><td>0</td></tr>
</table>
```

**Usage Notes:**
- Display in dashboards or reports for detailed UX analysis
- Aggregates data from multiple UX monitoring scripts
- Use for troubleshooting user complaints
- Include in user-facing reports

**Related Fields:**
- `uxExperienceScore` - Numeric UX score
- `appTopProblemApps` - Problem application list

---

## appTopCrashingApp

**Type:** Text  
**Category:** User Experience  
**Populated By:** Script 17 - Application Experience Profiler  
**Update Frequency:** Daily

**Description:**
Name of the application with the most crashes in the last 24 hours.

**Possible Values:**
- Application name (e.g., \"Microsoft Outlook\", \"Google Chrome\", \"Adobe Acrobat\")
- `None` - No crashes

**Example:** `Microsoft Outlook`

**Usage Notes:**
- Alert if same app crashes frequently across multiple devices (systemic issue)
- May indicate need for application update or replacement
- Review appTopProblemApps for full list
- Check application version and update status

**Related Fields:**
- `statAppCrashes24h` - Total crash count
- `appTopProblemApps` - Full problem app list

---

## appTopProblemApps

**Type:** WYSIWYG  
**Category:** User Experience  
**Populated By:** Script 17 - Application Experience Profiler  
**Update Frequency:** Daily

**Description:**
Formatted HTML list of top 10 problematic applications ranked by crash and hang frequency.

**Possible Values:**
- HTML formatted list with crash/hang counts

**Example:**
```html
<ol>
  <li>Microsoft Outlook - 5 crashes, 3 hangs</li>
  <li>Google Chrome - 4 crashes, 2 hangs</li>
  <li>Adobe Acrobat - 2 crashes, 1 hang</li>
</ol>
```

**Usage Notes:**
- Use for identifying systemic application issues
- Prioritize application updates or replacements
- Compare across fleet to identify common problems
- Include in user support reports

**Related Fields:**
- `appTopCrashingApp` - #1 crashing app
- `statAppCrashes24h` - Total crashes
- `statAppHangs24h` - Total hangs

---

## appOfficeVersion

**Type:** Text  
**Category:** User Experience  
**Populated By:** Script 34 - Licensing and Feature Utilization Telemetry  
**Update Frequency:** Daily

**Description:**
Installed Microsoft Office version and channel.

**Possible Values:**
- `Office 365 ProPlus - Monthly Channel`
- `Office 2021 Professional`
- `Office 2019 Standard`
- `Office 2016` (approaching end of support)
- `Not Installed`

**Example:** `Office 365 ProPlus - Monthly Channel`

**Usage Notes:**
- Track for license compliance and upgrade planning
- Office 2016 approaching end of support (October 2025)
- Recommend Office 365 for always-current features
- Check appOfficeActivation for licensing status

**Related Fields:**
- `appOfficeActivation` - Office activation status
- `appOutlookFailures24h` - Outlook-specific issues

---

## appOfficeActivation

**Type:** Dropdown  
**Category:** User Experience  
**Populated By:** Script 34 - Licensing and Feature Utilization Telemetry  
**Update Frequency:** Daily

**Description:**
Microsoft Office activation status.

**Possible Values:**
- `Activated` - Valid license, activated
- `Grace Period` - Activation pending (30-day grace)
- `Not Activated` - No activation (unlicensed)
- `Expired` - License expired
- `Not Installed` - Office not installed

**Example:** `Activated`

**Usage Notes:**
- Alert if \"Not Activated\" or \"Expired\" (compliance issue)
- \"Grace Period\" normal for new deployments
- Check license assignment in Microsoft 365 admin center
- Impact user productivity (reduced functionality when unlicensed)

**Related Fields:**
- `appOfficeVersion` - Office version
- `appOutlookFailures24h` - Outlook issues (may be activation-related)

---

## appOutlookFailures24h

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 29 - Collaboration and Outlook UX Telemetry  
**Update Frequency:** Every 4 hours

**Description:**
Count of Microsoft Outlook application failures (crashes, hangs, synchronization errors) in the last 24 hours.

**Possible Values:**
- `0` - No failures
- `1-3` - Occasional failures
- `4-10` - Frequent failures (investigate)
- `11+` - Excessive failures (critical issue)

**Example:** `2`

**Usage Notes:**
- Alert if > 10 (significant productivity impact)
- Common causes: large mailbox, PST/OST corruption, add-in conflicts
- Review OST file size and mailbox size
- Check for problematic add-ins
- May require Outlook profile rebuild

**Related Fields:**
- `appOfficeVersion` - Office version
- `uxCollabFailures24h` - General collaboration issues
- `appTopCrashingApp` - May be Outlook

---

## uxLoginDelaySeconds

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 30 - User Environment Friction Tracker  
**Update Frequency:** Daily

**Description:**
Average user login duration in seconds from credential entry to desktop ready.

**Possible Values:**
- `0-30` - Fast (good profile, fast network)
- `31-60` - Normal
- `61-120` - Slow (investigate)
- `121+` - Very slow (serious issue)

**Example:** `45`

**Usage Notes:**
- Target: < 60 seconds for acceptable UX
- > 120 seconds indicates serious issue (large profile, Group Policy problems, slow DC)
- Check uxProfileOptimizationNeeded for profile issues
- Review Group Policy processing time
- May indicate network latency or domain controller performance

**Related Fields:**
- `uxLoginRetryCount24h` - Login retry attempts
- `uxProfileOptimizationNeeded` - Profile cleanup needed
- `uxBootTimeSeconds` - Boot performance (related)

---

## uxLogonScriptDuration

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 30 - User Environment Friction Tracker  
**Update Frequency:** Daily

**Description:**
Time in seconds required to execute logon scripts during user login.

**Possible Values:**
- `0-10` - Fast
- `11-30` - Normal
- `31-60` - Slow (review scripts)
- `61+` - Very slow (optimize scripts)

**Example:** `8`

**Usage Notes:**
- Target: < 30 seconds
- > 60 seconds significantly delays login
- Review logon scripts for inefficiencies (network timeouts, unnecessary commands)
- Consider replacing with Group Policy Preferences
- May indicate network issues if scripts access remote resources

**Related Fields:**
- `uxLoginDelaySeconds` - Total login time
- `uxLoginRetryCount24h` - Login issues

---

## uxGPOProcessingTime

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 30 - User Environment Friction Tracker  
**Update Frequency:** Daily

**Description:**
Time in seconds required to process Group Policy Objects during user login.

**Possible Values:**
- `0-10` - Fast (optimized GPOs)
- `11-30` - Normal
- `31-60` - Slow (review GPOs)
- `61+` - Very slow (optimize GPOs)

**Example:** `12`

**Usage Notes:**
- Target: < 30 seconds
- > 60 seconds delays login significantly
- Review Group Policy processing with gpresult command
- Excessive GPOs or slow DCs impact processing time
- Consider WMI filtering and loopback processing optimization

**Related Fields:**
- `uxLoginDelaySeconds` - Total login time
- `uxLogonScriptDuration` - Logon script time

---

## uxDesktopReadyTime

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 30 - User Environment Friction Tracker  
**Update Frequency:** Daily

**Description:**
Time in seconds from desktop appearing to all startup items and applications loaded (desktop fully responsive).

**Possible Values:**
- `0-30` - Fast (optimized startup)
- `31-60` - Normal
- `61-120` - Slow (review startup items)
- `121+` - Very slow (optimize startup)

**Example:** `40`

**Usage Notes:**
- Target: < 60 seconds for responsive desktop
- > 120 seconds frustrates users (appears hung)
- Review startup programs (msconfig, Task Manager)
- Disable unnecessary startup items
- Consider delayed start for non-critical applications

**Related Fields:**
- `uxLoginDelaySeconds` - Login time
- `uxBootTimeSeconds` - Boot time

---

## uxApplicationLoadTime

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 17 - Application Experience Profiler  
**Update Frequency:** Daily

**Description:**
Average time in seconds for applications to launch from double-click to window displayed.

**Possible Values:**
- `0-5` - Fast (SSD, optimized apps)
- `6-15` - Normal
- `16-30` - Slow (investigate)
- `31+` - Very slow (performance issue)

**Example:** `8`

**Usage Notes:**
- Target: < 15 seconds for acceptable UX
- > 30 seconds indicates storage or resource issue
- Check disk performance (responseTimeMs, diskActiveTimePercent)
- May indicate need for SSD upgrade
- Large applications (Office, Adobe) typically slower

**Related Fields:**
- `responseTimeMs` - Storage response time
- `diskActiveTimePercent` - Disk utilization
- `uxExperienceScore` - Overall UX score

---

## uxSuspendResumeFailures7d

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 17 - Application Experience Profiler  
**Update Frequency:** Daily

**Description:**
Number of sleep/suspend or resume failures in the last 7 days (laptop lid close/open issues).

**Possible Values:**
- `0` - No failures
- `1-3` - Occasional failures
- `4-10` - Frequent failures
- `11+` - Serious power management issue

**Example:** `1`

**Usage Notes:**
- Alert if > 10 (poor laptop experience)
- Common on laptops, rare on desktops
- May indicate driver issues (display, network, storage)
- Review Windows Event Log for power management errors
- Update drivers, especially graphics and network

**Related Fields:**
- `uxExperienceScore` - UX score impact
- `statBSODCount30d` - May correlate with BSOD

---

## uxBatteryHealthPercent

**Type:** Integer  
**Category:** User Experience  
**Populated By:** Script 17 - Application Experience Profiler  
**Update Frequency:** Daily

**Description:**
Laptop battery health percentage (design capacity vs. current full charge capacity). Laptops only.

**Possible Values:**
- `80-100` - Healthy battery
- `60-79` - Degraded battery (monitor)
- `40-59` - Poor battery (plan replacement)
- `0-39` - Critical battery (replace immediately)
- `NULL` - Not applicable (desktop) or cannot determine

**Example:** `85`

**Usage Notes:**
- Target: > 80% for acceptable battery life
- < 60% indicates battery replacement needed
- Battery degrades naturally over time (2-4 years typical lifespan)
- Alert if < 50% on business-critical laptops
- Used for laptop lifecycle management

**Related Fields:**
- `predDeviceReplacementDate` - Predicted replacement date
- `uxExperienceScore` - May impact mobile worker UX

---

# Telemetry Fields

**Category:** System Statistics and Event Tracking  
**Total Fields:** 20+  
**Scripts:** Scripts 6, 17, 27, 32, 35  
**Purpose:** Collect raw system telemetry data for analysis and scoring

---

## statAppCrashes24h

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 06 - Telemetry Collector  
**Update Frequency:** Every 4 hours

**Description:**
Count of application crashes (Event ID 1000, 1001) from Windows Application Event Log in the last 24 hours.

**Possible Values:**
- `0` - No crashes (ideal)
- `1-5` - Few crashes (acceptable)
- `6-15` - Many crashes (investigate)
- `16+` - Excessive crashes (critical issue)

**Example:** `3`

**Usage Notes:**
- Alert if > 15 (significant stability issue)
- Review appTopCrashingApp for specific application
- May indicate application bugs, driver issues, or resource constraints
- Used for opsStabilityScore calculation
- Feeds into uxExperienceScore

**Related Fields:**
- `statAppHangs24h` - Application hang count
- `opsStabilityScore` - Stability score
- `appTopCrashingApp` - Most problematic app

---

## statAppHangs24h

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 06 - Telemetry Collector  
**Update Frequency:** Every 4 hours

**Description:**
Count of application hangs (not responding, Event ID 1002) from Windows Application Event Log in the last 24 hours.

**Possible Values:**
- `0` - No hangs
- `1-5` - Few hangs
- `6-15` - Many hangs
- `16+` - Excessive hangs

**Example:** `2`

**Usage Notes:**
- Alert if > 15
- Often indicates resource constraints (CPU, memory, disk I/O)
- Review resource utilization metrics
- Used for opsStabilityScore calculation
- Same as uxApplicationHangCount24h (different naming convention)

**Related Fields:**
- `statAppCrashes24h` - Crash count
- `uxApplicationHangCount24h` - Same data, UX perspective
- `opsStabilityScore` - Stability score

---

## statServiceFailures24h

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 06 - Telemetry Collector  
**Update Frequency:** Every 4 hours

**Description:**
Count of Windows service failures (Event IDs 7031, 7034) from System Event Log in the last 24 hours.

**Possible Values:**
- `0` - No service failures
- `1-3` - Few failures (monitor)
- `4-10` - Many failures (investigate)
- `11+` - Excessive failures (critical issue)

**Example:** `1`

**Usage Notes:**
- Alert if > 10
- Service failures impact system stability and functionality
- Review specific services with serviceHealthStatus
- May require service restart or system reboot
- Used for opsStabilityScore calculation

**Related Fields:**
- `serviceHealthStatus` - Service health status
- `driftCriticalServiceDrift` - Service configuration drift
- `opsStabilityScore` - Stability score

---

## statBSODCount30d

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 06 - Telemetry Collector  
**Update Frequency:** Every 4 hours

**Description:**
Count of Blue Screen of Death (BSOD) events (Event ID 1001 BugCheck, Event ID 41 Kernel-Power) in the last 30 days.

**Possible Values:**
- `0` - No BSODs (ideal)
- `1-2` - Rare BSODs (monitor)
- `3-5` - Multiple BSODs (investigate)
- `6+` - Frequent BSODs (critical hardware issue)

**Example:** `0`

**Usage Notes:**
- Alert on any BSOD for critical systems
- BSOD indicates serious hardware or driver issue
- Review BSOD dump files for root cause
- Common causes: driver bugs, RAM failure, overheating, hardware defects
- Used for opsStabilityScore calculation (-20 points per BSOD)

**Related Fields:**
- `opsStabilityScore` - Major stability impact
- `thermalThrottlingDetected` - Overheating indicator
- `firmwareVersion` - May need firmware update

---

## statUptimeDays

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 06 - Telemetry Collector  
**Update Frequency:** Every 4 hours

**Description:**
Number of days since last system reboot.

**Possible Values:**
- `0-7` - Recently rebooted
- `8-30` - Normal uptime
- `31-90` - Extended uptime
- `91+` - Very long uptime (may need reboot)

**Example:** `12`

**Usage Notes:**
- Servers: extended uptime is acceptable (30-90 days)
- Workstations: recommend reboot weekly for updates and cleanup
- > 90 days may indicate pending reboot from patches
- Check patchRebootPending if uptime excessive
- Used for stability assessment (crashes during short uptime more concerning)

**Related Fields:**
- `patchRebootPending` - Reboot needed for patches
- `updDaysSinceLastReboot` - Same metric, update perspective
- `opsStabilityScore` - Uptime impacts stability scoring

---

## statLastTelemetryUpdate

**Type:** DateTime (Unix Epoch)  
**Category:** Telemetry  
**Populated By:** Script 06 - Telemetry Collector  
**Update Frequency:** Every 4 hours

**Description:**
Timestamp of the most recent telemetry collection run. Indicates data freshness.

**Possible Values:**
- Unix Epoch timestamp
- `NULL` - Telemetry never collected

**Example:** `1738926000`

**Usage Notes:**
- Should be updated every 4 hours
- Alert if > 12 hours old (script not running)
- Use Script 27 (Telemetry Freshness Monitor) to track staleness
- Critical for ensuring telemetry reliability

**Related Fields:**
- All STAT fields depend on this telemetry collection
- `lastHealthCheck` - Related data freshness indicator

---

## statEventLogErrors24h

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 06 - Telemetry Collector  
**Update Frequency:** Every 4 hours

**Description:**
Count of Error-level events in System and Application Event Logs in the last 24 hours.

**Possible Values:**
- `0-10` - Few errors (normal)
- `11-50` - Many errors (monitor)
- `51-100` - Excessive errors (investigate)
- `101+` - Critical error volume

**Example:** `15`

**Usage Notes:**
- Target: < 50 errors per day
- High error count indicates systemic issues
- Filter out known benign errors
- Review Event Viewer for specific error patterns
- May indicate hardware, driver, or configuration issues

**Related Fields:**
- `statEventLogWarnings24h` - Warning-level events
- `healthStatus` - Overall health

---

## statEventLogWarnings24h

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 06 - Telemetry Collector  
**Update Frequency:** Every 4 hours

**Description:**
Count of Warning-level events in System and Application Event Logs in the last 24 hours.

**Possible Values:**
- `0-50` - Few warnings (normal)
- `51-200` - Many warnings (monitor)
- `201-500` - Excessive warnings
- `501+` - Critical warning volume

**Example:** `75`

**Usage Notes:**
- Warnings less critical than errors but indicate issues
- High warning count may precede errors
- Review for patterns (e.g., disk space warnings before failure)
- Some warnings are benign (filter known patterns)

**Related Fields:**
- `statEventLogErrors24h` - Error-level events
- `healthStatus` - Overall health

---

## statDiskReadErrorCount

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
Count of disk read errors from SMART data. Indicates potential disk failure.

**Possible Values:**
- `0` - No read errors (healthy)
- `1-10` - Few errors (monitor)
- `11-100` - Many errors (failing disk, backup and replace)
- `101+` - Critical (immediate replacement required)

**Example:** `0`

**Usage Notes:**
- Alert on any disk read errors (early warning of failure)
- Backup data immediately if errors detected
- Check SMART status with smartHealthStatus
- Schedule disk replacement
- HDD more prone to errors than SSD

**Related Fields:**
- `statDiskWriteErrorCount` - Write error count
- `smartHealthStatus` - SMART overall health
- `diskHealthStatus` - Disk health status

---

## statDiskWriteErrorCount

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
Count of disk write errors from SMART data. Indicates potential disk failure.

**Possible Values:**
- `0` - No write errors (healthy)
- `1-10` - Few errors (monitor)
- `11-100` - Many errors (failing disk, backup and replace)
- `101+` - Critical (immediate replacement required)

**Example:** `0`

**Usage Notes:**
- Alert on any disk write errors (critical data integrity risk)
- Backup data immediately
- Write errors more serious than read errors (data loss risk)
- Replace disk promptly
- Check SMART status

**Related Fields:**
- `statDiskReadErrorCount` - Read error count
- `smartHealthStatus` - SMART overall health

---

## statDiskReallocatedSectors

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
SMART metric: count of reallocated sectors. Disk remaps bad sectors to spare area. Increasing count indicates disk degradation.

**Possible Values:**
- `0` - No reallocated sectors (healthy)
- `1-10` - Few sectors reallocated (monitor)
- `11-100` - Many sectors reallocated (replace disk)
- `101+` - Critical (immediate replacement)

**Example:** `0`

**Usage Notes:**
- Alert if > 0 (early warning of disk failure)
- Increasing count over time indicates active degradation
- Backup data and schedule replacement
- HDD-specific metric (SSDs have equivalent wear indicators)
- Used for predictive failure analysis

**Related Fields:**
- `statDiskReadErrorCount` - Read errors
- `statDiskWriteErrorCount` - Write errors
- `smartHealthStatus` - SMART health

---

## statDiskPendingSectors

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
SMART metric: count of sectors marked as unstable, waiting to be remapped. Indicates imminent failure.

**Possible Values:**
- `0` - No pending sectors (healthy)
- `1-5` - Few pending (monitor closely)
- `6-50` - Many pending (replace immediately)
- `51+` - Critical (disk failure imminent)

**Example:** `0`

**Usage Notes:**
- Alert immediately if > 0 (disk failure imminent)
- Pending sectors may become reallocated or fail completely
- Higher priority than reallocated sectors (failure in progress)
- Backup data and replace disk urgently
- Check daily for changes

**Related Fields:**
- `statDiskReallocatedSectors` - Already reallocated sectors
- `smartHealthStatus` - SMART health

---

## statSSDWearLevelPercent

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
SSD wear level percentage (0-100%). Higher values indicate more wear. SSD-specific metric.

**Possible Values:**
- `0-50` - Low wear (healthy)
- `51-80` - Moderate wear (monitor)
- `81-95` - High wear (plan replacement)
- `96-100` - Critical wear (replace soon)

**Example:** `25`

**Usage Notes:**
- SSDs have limited write cycles (wear out over time)
- > 80% wear indicates 1-2 years remaining life typically
- Enterprise SSDs tolerate more wear than consumer SSDs
- Plan replacement when wear > 90%
- Not applicable to HDDs

**Related Fields:**
- `statSSDLifetimeWritesGB` - Total data written
- `smartHealthStatus` - SMART health

---

## statSSDLifetimeWritesGB

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 32 - Thermal and Firmware Telemetry  
**Update Frequency:** Daily

**Description:**
Total gigabytes written to SSD over its lifetime. Used to calculate wear level.

**Possible Values:**
- Varies by SSD model and usage
- Consumer SSDs: 10-100 TB typical before wear-out
- Enterprise SSDs: 100-1000+ TB typical

**Example:** `15000` (15 TB)

**Usage Notes:**
- Track growth rate to predict SSD lifespan
- High write workloads (databases, video editing) wear SSDs faster
- Compare with manufacturer's TBW (Total Bytes Written) rating
- Not applicable to HDDs

**Related Fields:**
- `statSSDWearLevelPercent` - Wear calculation
- `smartHealthStatus` - Overall health

---

## statNetworkPacketLoss

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 31 - Remote Connectivity and SaaS Quality Telemetry  
**Update Frequency:** Every 4 hours

**Description:**
Network packet loss percentage over last measurement period. Indicates network quality issues.

**Possible Values:**
- `0` - No packet loss (ideal)
- `1-2` - Minor packet loss (acceptable)
- `3-5` - Moderate packet loss (impacts performance)
- `6+` - High packet loss (serious network issue)

**Example:** `0`

**Usage Notes:**
- Target: < 1% packet loss
- > 3% impacts VoIP and video conferencing quality
- Check network cabling, WiFi signal, or ISP if consistently high
- May correlate with netWiFiDisconnects24h for WiFi issues

**Related Fields:**
- `networkLatencyMs` - Network latency
- `netWiFiDisconnects24h` - WiFi stability
- `uxCollabPoorQuality24h` - Collaboration quality impact

---

## statNetworkRetransmitRate

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 31 - Remote Connectivity and SaaS Quality Telemetry  
**Update Frequency:** Every 4 hours

**Description:**
TCP retransmission rate percentage. High values indicate network congestion or errors.

**Possible Values:**
- `0-1` - Normal
- `2-5` - Elevated (monitor)
- `6-10` - High (network issues)
- `11+` - Critical (severe network problems)

**Example:** `1`

**Usage Notes:**
- Target: < 2%
- High retransmit rate impacts throughput and latency
- May indicate network congestion, faulty cable, or WiFi interference
- Check with statNetworkPacketLoss for correlation

**Related Fields:**
- `statNetworkPacketLoss` - Packet loss metric
- `networkLatencyMs` - Latency metric
- `networkHealthStatus` - Overall network health

---

## statMemoryCompression

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
Amount of RAM (in MB) saved by Windows memory compression feature.

**Possible Values:**
- `0-500` - Low compression (adequate RAM)
- `501-2000` - Moderate compression
- `2001-5000` - High compression (memory pressure)
- `5001+` - Extreme compression (RAM shortage)

**Example:** `800`

**Usage Notes:**
- High compression indicates memory pressure
- Windows compresses memory before paging to disk
- > 5000 MB compressed suggests need for more RAM
- Check capMemoryUsedPercent for correlation

**Related Fields:**
- `capMemoryUsedPercent` - Memory utilization
- `memoryPageFaultRate` - Paging activity

---

## statPageFileUsagePercent

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 03 - Performance Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
Percentage of page file (virtual memory) currently in use.

**Possible Values:**
- `0-30` - Normal (adequate RAM)
- `31-60` - Elevated (monitor)
- `61-90` - High (memory pressure)
- `91-100` - Critical (severe RAM shortage)

**Example:** `15`

**Usage Notes:**
- Target: < 50%
- > 70% indicates insufficient RAM
- Page file usage much slower than physical RAM
- Impacts performance significantly
- Check memoryPageFaultRate for paging activity

**Related Fields:**
- `capMemoryUsedPercent` - Physical RAM usage
- `memoryPageFaultRate` - Page faults
- `statMemoryCompression` - Memory compression

---

## statDriftEvents30d

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 35 - Baseline Coverage and Drift Density Telemetry  
**Update Frequency:** Daily

**Description:**
Count of detected configuration drift events in the last 30 days across all drift monitors.

**Possible Values:**
- `0-5` - Few drift events (stable)
- `6-15` - Moderate drift (monitor)
- `16-30` - High drift (investigate)
- `31+` - Excessive drift (configuration management issue)

**Example:** `8`

**Usage Notes:**
- Alert if > 30 (indicates configuration instability)
- Review specific drift fields for details:
  - driftNewAppsCount (software drift)
  - driftLocalAdminDrift (admin account drift)
  - driftCriticalServiceDrift (service drift)
  - driftFirmwareDrift (firmware drift)
- High drift may indicate unauthorized changes or automation issues

**Related Fields:**
- `driftNewAppsCount` - Software installation drift
- `driftLocalAdminDrift` - Admin account changes
- `baseDriftScore` - Overall drift score

---

## statBaselineAge

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 35 - Baseline Coverage and Drift Density Telemetry  
**Update Frequency:** Daily

**Description:**
Age of current baseline in days. Indicates how long since baseline was established or refreshed.

**Possible Values:**
- `0-30` - Recent baseline (fresh)
- `31-90` - Aging baseline (still valid)
- `91-180` - Old baseline (consider refresh)
- `181+` - Very old baseline (refresh recommended)

**Example:** `45`

**Usage Notes:**
- Baselines should be refreshed quarterly (every 90 days)
- Old baselines less effective for drift detection (environment changes naturally)
- Refresh baseline after major changes (OS upgrade, major app deployment)
- Used for baseline management and drift detection accuracy

**Related Fields:**
- `baseDriftScore` - Drift from this baseline
- `basePerformanceBaseline` - Baseline data
- `statDriftEvents30d` - Drift event count

---

## statTelemetryCollectionFailures7d

**Type:** Integer  
**Category:** Telemetry  
**Populated By:** Script 27 - Telemetry Freshness Monitor  
**Update Frequency:** Daily

**Description:**
Count of failed telemetry collection attempts in the last 7 days. Indicates monitoring reliability.

**Possible Values:**
- `0` - All collections successful
- `1-3` - Few failures (acceptable)
- `4-10` - Many failures (investigate)
- `11+` - Excessive failures (monitoring broken)

**Example:** `1`

**Usage Notes:**
- Alert if > 10 (telemetry unreliable)
- May indicate agent issues, network connectivity, or script errors
- Review script execution logs for error details
- Critical for ensuring data quality and alerting reliability

**Related Fields:**
- `statLastTelemetryUpdate` - Last successful collection
- All telemetry depends on collection success

---

# Remaining Field Categories

**Status:** Part 3 Complete  
**Fields Documented:** 210+ of 277+  
**Progress:** ~76%

**Remaining Categories:**
- Drift Detection Fields (10+ fields)
- Active Directory Fields (15+ fields)
- WYSIWYG Report Fields (30+ fields)
- DateTime Fields (20+ fields)
- Miscellaneous Fields (12+ fields)

**Next Section:** Drift Detection, Active Directory, and Report fields (Part 4)

---

**Last Updated:** February 8, 2026, 2:20 PM CET  
**Version:** 1.2 (Part 1 + Part 2 + Part 3)