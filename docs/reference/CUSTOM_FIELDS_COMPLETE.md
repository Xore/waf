# Complete Custom Fields Reference

**Purpose:** Comprehensive documentation of all 277+ custom fields in Windows Automation Framework  
**Created:** February 8, 2026  
**Status:** Production Ready  
**Last Updated:** February 8, 2026, 2:00 PM CET

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
6. [Performance Fields](#performance-fields) (20+ fields)
7. [User Experience (UX) Fields](#user-experience-ux-fields) (20+ fields)
8. [Telemetry Fields](#telemetry-fields) (20+ fields)
9. [Drift Detection Fields](#drift-detection-fields) (10+ fields)
10. [Active Directory Fields](#active-directory-fields) (15+ fields)
11. [WYSIWYG Report Fields](#wysiwyg-report-fields) (30+ fields)
12. [DateTime Fields](#datetime-fields) (20+ fields)
13. [Miscellaneous Fields](#miscellaneous-fields) (12+ fields)

**Total Fields Documented:** 150+ of 277+ (Part 1 + Part 2)

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

# Patching Fields

**Category:** Patch Management  
**Total Fields:** 15  
**Scripts:** PR1, PR2, P1, P2, P3-P4 Validators, Script 23  
**Purpose:** Ring-based patch deployment with priority validation

---

## patchRing

**Type:** Dropdown  
**Category:** Patching  
**Populated By:** Manual configuration  
**Update Frequency:** As needed

**Description:**
Patch deployment ring assignment determining when device receives patches. Implements phased rollout strategy with test ring (PR1) and production ring (PR2).

**Possible Values:**
- `PR1-Test` - Test ring (10-20 devices, deploys first)
- `PR2-Production` - Production ring (all other devices, deploys after 7-day PR1 soak)
- `Manual` - Manual patching only, excluded from automated deployment
- *(empty)* - Not assigned to any ring

**Example:** `PR1-Test`

**Usage Notes:**
- PR1 devices should be non-critical test systems
- PR2 deployment requires 90% PR1 success rate
- Manual ring useful for highly critical servers
- Assign 5-10% of devices to PR1 for adequate testing

**Related Fields:**
- `patchLastAttemptDate` - When last patch attempt occurred
- `patchValidationStatus` - Pre-deployment validation result
- `baseBusinessCriticality` - Determines validation strictness

---

## patchLastAttemptDate

**Type:** DateTime (Unix Epoch)  
**Category:** Patching  
**Populated By:** Scripts PR1, PR2  
**Update Frequency:** Per deployment attempt

**Description:**
Timestamp of the most recent patch deployment attempt, regardless of success or failure. Updated every time PR1 or PR2 script runs.

**Possible Values:**
- Unix Epoch timestamp (seconds since 1970-01-01)
- `NULL` - Never attempted patching

**Example:** `1738926000` (February 8, 2026, 10:00 AM)

**Usage Notes:**
- Compare with current date to identify stale patch attempts
- Alert if no attempt in > 30 days for production devices
- Use with patchLastAttemptStatus to identify failures

**Related Fields:**
- `patchLastAttemptStatus` - Outcome of this attempt
- `patchLastPatchCount` - How many patches were installed
- `patchRebootPending` - If reboot required after patches

---

## patchLastAttemptStatus

**Type:** Text  
**Category:** Patching  
**Populated By:** Scripts PR1, PR2  
**Update Frequency:** Per deployment attempt

**Description:**
Detailed status message from the most recent patch deployment attempt. Includes success metrics, failure reasons, or deferral explanations.

**Possible Values:**
- `Success - [N] Installed` - All patches installed successfully
- `Partial - [N] Success, [M] Failed` - Some patches failed
- `Failed - [Reason]` - Deployment failed (e.g., "Low Disk Space")
- `Deferred - [Reason]` - Deployment postponed (e.g., "Outside Maintenance Window")
- `Blocked - [Reason]` - Deployment prevented (e.g., "PR1 Validation Failed")
- `Dry Run - [N] Available` - Dry run mode, no actual deployment
- `Success - No Updates Available` - No patches needed

**Example:** `Success - 12 Installed`

**Usage Notes:**
- Parse for "Failed" or "Blocked" to trigger alerts
- "Deferred" is normal for servers outside maintenance windows
- Review "Partial" status to identify problematic patches
- Track "Blocked" to identify systemic issues

**Related Fields:**
- `patchLastAttemptDate` - When this status was set
- `patchLastPatchCount` - Number of successful installations
- `patchValidationStatus` - Pre-deployment validation that may block

---

## patchLastPatchCount

**Type:** Integer  
**Category:** Patching  
**Populated By:** Scripts PR1, PR2  
**Update Frequency:** Per deployment attempt

**Description:**
Number of patches successfully installed during the most recent deployment attempt. Does not include failed patches.

**Possible Values:**
- `0` - No patches installed (could be no patches available or all failed)
- `1-100+` - Count of successfully installed patches
- `NULL` - Never attempted patching

**Example:** `12`

**Usage Notes:**
- Compare with updMissingCriticalCount to verify deployment
- Zero with "Success" status means device is fully patched
- Zero with "Failed" status indicates problem
- Track over time to identify patch volume trends

**Related Fields:**
- `patchLastAttemptStatus` - Context for this count
- `updMissingCriticalCount` - Critical patches still needed
- `patchRebootPending` - If these patches require reboot

---

## patchRebootPending

**Type:** Checkbox  
**Category:** Patching  
**Populated By:** Scripts PR1, PR2  
**Update Frequency:** Per deployment attempt

**Description:**
Indicates if a system reboot is required to complete patch installation. Set to true when patches requiring reboot are installed.

**Possible Values:**
- `TRUE` - Reboot required to complete patching
- `FALSE` - No reboot required, patches complete

**Example:** `TRUE`

**Usage Notes:**
- Alert on TRUE for critical servers (requires maintenance window)
- Workstations can auto-reboot after hours if configured
- Reboot scheduling controlled by autoAllowAfterHoursReboot
- Check before attempting additional patch deployments

**Related Fields:**
- `autoAllowAfterHoursReboot` - Controls automatic reboot behavior
- `patchLastPatchCount` - Patches awaiting reboot
- `srvRole` - Server role affects reboot scheduling

---

## patchValidationStatus

**Type:** Dropdown  
**Category:** Patching  
**Populated By:** Scripts P1, P2, P3-P4 Validators  
**Update Frequency:** Before each deployment

**Description:**
Pre-deployment validation result indicating if device meets requirements for safe patching. Validators check health, stability, backups, and other prerequisites.

**Possible Values:**
- `Passed` - Device meets all validation requirements
- `Failed` - Device does not meet validation requirements (blocks deployment)
- `Error` - Validation script encountered error
- `Pending` - Validation not yet performed
- *(empty)* - Never validated

**Example:** `Passed`

**Usage Notes:**
- "Failed" blocks PR1/PR2 deployment until issues resolved
- Validation strictness varies by priority (P1 strictest, P4 most lenient)
- Review patchValidationNotes for failure reasons
- Re-run validator after remediation

**Related Fields:**
- `patchValidationNotes` - Specific validation failure reasons
- `patchValidationDate` - When validation was performed
- `baseBusinessCriticality` - Determines which validator runs

---

## patchValidationNotes

**Type:** Text  
**Category:** Patching  
**Populated By:** Scripts P1, P2, P3-P4 Validators  
**Update Frequency:** Before each deployment

**Description:**
Detailed notes from patch validation, including specific reasons for failures or warnings. Provides actionable information for remediation.

**Possible Values:**
- `All checks passed` - No issues
- `Health score too low ([N], min [M])` - Health score below threshold
- `Stability score too low ([N], min [M])` - Stability issue
- `Too many crashes ([N], max [M])` - Crash history problem
- `Backup too old ([N] hours, max [M])` - Backup recency issue
- `Insufficient disk space ([N] GB, min [M])` - Disk space problem
- `No backup verification` - No backup data available
- Multiple notes separated by semicolons

**Example:** `Health score too low (65, min 80); Backup too old (48 hours, max 24)`

**Usage Notes:**
- Parse notes to identify common validation failures
- Use for prioritizing remediation efforts
- Track validation failure trends
- Include in patch deployment reports

**Related Fields:**
- `patchValidationStatus` - Overall validation result
- `opsHealthScore` - May be validation failure cause
- `backupLastSuccess` - Backup recency check

---

## patchValidationDate

**Type:** DateTime (Unix Epoch)  
**Category:** Patching  
**Populated By:** Scripts P1, P2, P3-P4 Validators  
**Update Frequency:** Before each deployment

**Description:**
Timestamp when patch validation was last performed. Used to ensure validation is recent before deployment.

**Possible Values:**
- Unix Epoch timestamp (seconds since 1970-01-01)
- `NULL` - Never validated

**Example:** `1738925400` (February 8, 2026, 9:50 AM)

**Usage Notes:**
- Validation should be within 24 hours of deployment
- Re-validate if system state changed significantly
- Compare with patchLastAttemptDate to verify pre-deployment validation

**Related Fields:**
- `patchValidationStatus` - Result of this validation
- `patchLastAttemptDate` - When deployment attempted

---

## updMissingCriticalCount

**Type:** Integer  
**Category:** Patching  
**Populated By:** Scripts PR1, PR2  
**Update Frequency:** During patch search phase

**Description:**
Number of critical severity patches that are available but not yet installed on the device. Updated during Windows Update search.

**Possible Values:**
- `0` - No critical patches missing (fully patched)
- `1-100+` - Count of missing critical patches

**Example:** `3`

**Usage Notes:**
- Alert when > 0 for critical systems
- Priority P1 devices should maintain 0
- Compare with patchLastAttemptStatus to identify deployment issues
- Combine with updPatchAgeDays for risk assessment

**Related Fields:**
- `updMissingImportantCount` - Important patches needed
- `updPatchAgeDays` - Age of oldest missing patch
- `updPatchComplianceLabel` - Overall compliance status

---

## updMissingImportantCount

**Type:** Integer  
**Category:** Patching  
**Populated By:** Scripts PR1, PR2  
**Update Frequency:** During patch search phase

**Description:**
Number of important (but not critical) severity patches available but not installed. Updated during Windows Update search.

**Possible Values:**
- `0` - No important patches missing
- `1-100+` - Count of missing important patches

**Example:** `7`

**Usage Notes:**
- Less urgent than critical but should be addressed
- Target: < 10 for production systems
- Include in regular patching cycles

**Related Fields:**
- `updMissingCriticalCount` - Critical patches (higher priority)
- `updMissingOptionalCount` - Optional patches (lower priority)

---

## updMissingOptionalCount

**Type:** Integer  
**Category:** Patching  
**Populated By:** Scripts PR1, PR2  
**Update Frequency:** During patch search phase

**Description:**
Number of optional patches available. These are typically driver updates or non-security patches.

**Possible Values:**
- `0` - No optional patches available
- `1-100+` - Count of missing optional patches

**Example:** `2`

**Usage Notes:**
- Lowest priority patching
- Consider deploying during planned maintenance
- May include driver updates

**Related Fields:**
- `updMissingCriticalCount` - Critical patches (highest priority)
- `updMissingImportantCount` - Important patches

---

## updPatchAgeDays

**Type:** Integer  
**Category:** Patching  
**Populated By:** Script 23 - Patch-Compliance Aging Analyzer  
**Update Frequency:** Daily

**Description:**
Age in days of the oldest missing security patch. Measures patch compliance lag.

**Possible Values:**
- `0` - Fully patched (no missing patches)
- `1-30` - Minor gap (acceptable)
- `31-60` - Moderate gap (needs attention)
- `61+` - Critical gap (urgent action required)

**Example:** `12`

**Usage Notes:**
- Alert when > 60 days for critical systems
- Target: < 30 days for all production devices
- Combine with updMissingCriticalCount for risk scoring
- Track trends over time

**Related Fields:**
- `updPatchComplianceLabel` - Classification based on age
- `updMissingCriticalCount` - How many old patches
- `patchLastAttemptDate` - When patching last attempted

---

## updPatchComplianceLabel

**Type:** Dropdown  
**Category:** Patching  
**Populated By:** Script 23 - Patch-Compliance Aging Analyzer  
**Update Frequency:** Daily

**Description:**
Classification of patch compliance status based on patch age and count.

**Possible Values:**
- `Current` - Fully patched or patches < 7 days old
- `Minor Gap` - Patches 7-30 days old
- `Moderate Gap` - Patches 31-60 days old
- `Critical Gap` - Patches > 60 days old
- `Unknown` - Cannot determine patch status

**Example:** `Minor Gap`

**Usage Notes:**
- "Current" or "Minor Gap" is acceptable for most systems
- "Critical Gap" requires immediate remediation
- Use for compliance reporting and dashboard filtering
- Priority P1 devices should maintain "Current" status

**Related Fields:**
- `updPatchAgeDays` - Numeric age value
- `updMissingCriticalCount` - Severity of gap
- `patchLastAttemptStatus` - Deployment history

---

## updLastPatchCheck

**Type:** DateTime (Unix Epoch)  
**Category:** Patching  
**Populated By:** Scripts PR1, PR2  
**Update Frequency:** Per deployment attempt

**Description:**
Timestamp of the most recent Windows Update availability check. Updated when PR1/PR2 scripts query for available patches.

**Possible Values:**
- Unix Epoch timestamp (seconds since 1970-01-01)
- `NULL` - Never checked for updates

**Example:** `1738926000`

**Usage Notes:**
- Should be updated at least weekly
- Alert if > 14 days old (indicates script not running)
- Different from patchLastAttemptDate (check vs. deployment)

**Related Fields:**
- `patchLastAttemptDate` - When deployment attempted
- `updMissingCriticalCount` - Result of this check

---

# Health Status Fields

**Category:** Operational Health  
**Total Fields:** 20+  
**Scripts:** Scripts 1-13, Infrastructure scripts  
**Purpose:** Track device health across all subsystems

---

## Common Health Status Pattern

Most health status fields follow this consistent pattern:

**Field Type:** Text (Dropdown-style values)  
**Possible Values:**
- `Unknown` - Cannot determine status (insufficient data, monitoring disabled, or error)
- `Healthy` - All checks passed, no issues detected
- `Warning` - Minor issues detected, attention recommended but not urgent
- `Critical` - Major issues detected, immediate action required

**Color Coding (in dashboards):**
- Unknown = Gray
- Healthy = Green  
- Warning = Orange/Yellow
- Critical = Red

---

## healthStatus

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector  
**Update Frequency:** Every 4 hours

**Description:**
Overall device health status aggregating multiple health metrics into a single classification. Primary health indicator for the device.

**Possible Values:**
- `Unknown` - Cannot determine health (data unavailable, device offline)
- `Healthy` - All health checks passed, device operating normally
- `Warning` - Minor issues detected (degraded performance, non-critical alerts)
- `Critical` - Major issues detected (service failures, resource exhaustion, critical errors)

**Example:** `Healthy`

**Usage Notes:**
- Primary field for dashboard filtering and alerting
- Calculated from diskHealthStatus, memoryHealthStatus, cpuHealthStatus, serviceHealthStatus
- Alert when "Warning" for critical devices, "Critical" for all devices
- Review healthReason field for specific issues
- "Unknown" may indicate monitoring problems or offline device

**Related Fields:**
- `healthReason` - Explanation of non-healthy status
- `healthScore` - Numeric health score (0-100)
- `opsHealthScore` - Comprehensive operational health score
- `lastHealthCheck` - When health was last assessed

---

## healthReason

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector  
**Update Frequency:** Every 4 hours

**Description:**
Human-readable explanation of why healthStatus is not "Healthy". Provides specific details about detected issues.

**Possible Values:**
- *(empty)* - Status is Healthy
- `Low disk space on C: (8% free)` - Disk capacity issue
- `High memory usage (92%)` - Memory pressure
- `Critical service stopped: [ServiceName]` - Service failure
- `Multiple issues: [issue1]; [issue2]` - Multiple problems

**Example:** `Low disk space on C: (8% free); High memory usage (92%)`

**Usage Notes:**
- Only populated when healthStatus is Warning or Critical
- Parse to identify common issues across fleet
- Include in alert notifications for context
- Multiple issues separated by semicolons

**Related Fields:**
- `healthStatus` - Overall health classification
- `diskHealthStatus` - Disk-specific health
- `memoryHealthStatus` - Memory-specific health

---

## healthScore

**Type:** Integer  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector  
**Update Frequency:** Every 4 hours

**Description:**
Numeric health score (0-100 scale) providing granular health measurement. Higher scores indicate better health.

**Possible Values:**
- `0-39` - Critical health (maps to Critical status)
- `40-69` - Warning health (maps to Warning status)
- `70-100` - Healthy (maps to Healthy status)
- `-1` or `NULL` - Unknown (cannot calculate)

**Example:** `85`

**Usage Notes:**
- More granular than healthStatus for trend analysis
- Target: maintain > 80 for production systems
- Alert thresholds: < 40 (Critical), < 70 (Warning)
- Track over time to identify degradation trends
- Use for capacity planning and device replacement decisions

**Related Fields:**
- `healthStatus` - Categorical health classification
- `opsHealthScore` - Operational health score
- `statStabilityScore` - Stability measurement

---

## lastHealthCheck

**Type:** DateTime (Unix Epoch)  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector  
**Update Frequency:** Every 4 hours

**Description:**
Timestamp of the most recent health assessment. Indicates data freshness.

**Possible Values:**
- Unix Epoch timestamp (seconds since 1970-01-01)
- `NULL` - Health never checked

**Example:** `1738926000`

**Usage Notes:**
- Should be updated every 4 hours
- Alert if > 12 hours old (indicates monitoring failure)
- Compare with current time to determine data staleness
- Use Script 27 (Telemetry Freshness Monitor) to track

**Related Fields:**
- `healthStatus` - Health data from this check
- `healthScore` - Score from this check

---

## diskHealthStatus

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector, Script 05 - Capacity Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
Disk storage health status focusing on capacity and I/O performance.

**Possible Values:**
- `Unknown` - Cannot assess disk health
- `Healthy` - Adequate free space (> 20%), no performance issues
- `Warning` - Low free space (10-20%) or minor performance degradation
- `Critical` - Very low free space (< 10%) or severe performance issues

**Example:** `Healthy`

**Usage Notes:**
- Critical threshold: < 10% free space
- Warning threshold: < 20% free space
- Servers may need higher thresholds (< 15% critical)
- Consider absolute GB free, not just percentage
- Check diskFreeGB and diskFreePercent for details

**Related Fields:**
- `diskFreePercent` - Percentage of disk free
- `diskFreeGB` - Absolute GB free
- `diskDrive` - Which drive is monitored
- `capDaysUntilDiskFull` - Predicted days until full

---

## memoryHealthStatus

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector, Script 05 - Capacity Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
RAM memory health status based on utilization and availability.

**Possible Values:**
- `Unknown` - Cannot assess memory health
- `Healthy` - Normal utilization (< 80%)
- `Warning` - High utilization (80-90%) or frequent paging
- `Critical` - Very high utilization (> 90%) or memory exhaustion

**Example:** `Healthy`

**Usage Notes:**
- Critical threshold: > 90% utilization
- Warning threshold: > 80% utilization
- Persistent high memory may indicate memory leak
- Check capMemoryUsedPercent for specific value
- Consider available memory, not just used percentage

**Related Fields:**
- `capMemoryUsedPercent` - Memory utilization percentage
- `capMemoryAvailableGB` - Available RAM in GB
- `statPageFaultRate` - Paging activity indicator

---

## cpuHealthStatus

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector, Script 03 - Performance Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
CPU processor health status based on utilization and performance metrics.

**Possible Values:**
- `Unknown` - Cannot assess CPU health
- `Healthy` - Normal utilization (< 70% average)
- `Warning` - High utilization (70-90% average) or sustained load
- `Critical` - Very high utilization (> 90% average) or processor throttling

**Example:** `Healthy`

**Usage Notes:**
- Based on average CPU over 15-minute windows
- Spikes are normal, sustained high usage is concerning
- Check for runaway processes if consistently high
- May indicate need for capacity upgrade

**Related Fields:**
- `capCPUUsedPercent` - Current CPU utilization
- `statCPUPeakUsage` - Peak CPU observed
- `opsPerformanceScore` - Performance impact assessment

---

## serviceHealthStatus

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector, Script 21 - Critical Service Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Critical Windows services health status. Monitors essential services required for device operation.

**Possible Values:**
- `Unknown` - Cannot assess service health
- `Healthy` - All critical services running
- `Warning` - Non-critical service stopped or minor issues
- `Critical` - Critical service stopped (e.g., Windows Update, RPC, DHCP Client)

**Example:** `Healthy`

**Usage Notes:**
- Critical services vary by device role (workstation vs. server)
- Common critical services: wuauserv, RpcSs, Dhcp, W32Time
- Auto-remediation may attempt service restart
- Review driftCriticalServiceNotes for specific stopped services

**Related Fields:**
- `driftCriticalServiceDrift` - Service configuration changes
- `driftCriticalServiceNotes` - Specific service issues

---

## networkHealthStatus

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 01 - Device Health Collector, Script 31 - Network Connectivity Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Network connectivity health status including LAN, WiFi, VPN, and internet access.

**Possible Values:**
- `Unknown` - Cannot assess network health
- `Healthy` - All network adapters operational, good connectivity
- `Warning` - Intermittent connectivity, high latency, or WiFi signal issues
- `Critical` - Network adapter down, no connectivity, or VPN failures

**Example:** `Healthy`

**Usage Notes:**
- "Critical" may indicate physical network issue
- For remote workers, check netWiFiDisconnects24h
- VPN health impacts remote device monitoring
- Review netRemoteConnectivityHtml for details

**Related Fields:**
- `netWiFiDisconnects24h` - WiFi stability metric
- `netVPNAverageLatencyMs` - VPN performance
- `netSaaSEndpointStatus` - Cloud service connectivity

---

## securityHealthStatus

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 04 - Security Analyzer, Script 15 - Security Posture Consolidator  
**Update Frequency:** Daily

**Description:**
Security posture health status including antivirus, firewall, encryption, and patch compliance.

**Possible Values:**
- `Unknown` - Cannot assess security health
- `Healthy` - All security controls enabled and functional
- `Warning` - Minor security gaps (old AV signatures, moderate patch gap)
- `Critical` - Major security gaps (AV disabled, firewall off, critical patches missing)

**Example:** `Healthy`

**Usage Notes:**
- "Critical" requires immediate remediation
- Combines multiple security factors: AV, firewall, BitLocker, patches
- P1 critical devices must maintain "Healthy" status
- Review secSecurityPostureScore for numeric assessment

**Related Fields:**
- `secSecurityPostureScore` - Numeric security score (0-100)
- `secAntivirusEnabled` - AV status
- `secFirewallEnabled` - Firewall status
- `secBitLockerEnabled` - Encryption status
- `updPatchComplianceLabel` - Patch compliance

---

## backupHealthStatus

**Type:** Text  
**Category:** Health Status  
**Populated By:** Script 09 - Risk Classifier  
**Update Frequency:** Every 4 hours

**Description:**
Backup health status based on backup recency and success rate.

**Possible Values:**
- `Unknown` - No backup information available
- `Healthy` - Recent successful backup (< 24 hours for critical, < 48 hours for others)
- `Warning` - Backup aging (24-48 hours for critical, 48-72 hours for others)
- `Critical` - Old backup (> 48 hours for critical, > 72 hours for others) or failed backups

**Example:** `Healthy`

**Usage Notes:**
- Backup requirements vary by device criticality
- Critical servers: < 24 hours required
- Production devices: < 48 hours recommended
- Check backupLastSuccess for timestamp
- Integrates with Veeam (veeamFailedJobsCount field)

**Related Fields:**
- `backupLastSuccess` - Timestamp of last successful backup
- `backupAgeDays` - Age of backup in days
- `veeamFailedJobsCount` - Veeam-specific failures

---

*[Additional health status fields for IIS, SQL, Hyper-V, etc. follow same pattern...]*

---

# Security Fields

**Category:** Security Posture and Compliance  
**Total Fields:** 35  
**Scripts:** Scripts 4, 15, 16, 20, 28  
**Purpose:** Track security controls, threats, and compliance

---

## secAntivirusEnabled

**Type:** Checkbox  
**Category:** Security  
**Populated By:** Script 04 - Security Analyzer  
**Update Frequency:** Daily

**Description:**
Indicates if antivirus protection is installed and enabled on the device.

**Possible Values:**
- `TRUE` - Antivirus enabled and running
- `FALSE` - Antivirus disabled, not installed, or not running

**Example:** `TRUE`

**Usage Notes:**
- Alert immediately if FALSE on production devices
- Check both Windows Defender and third-party AV
- Review secAntivirusProduct for specific AV solution
- FALSE results in Critical securityHealthStatus

**Related Fields:**
- `secAntivirusProduct` - Name of AV product
- `secAntivirusUpToDate` - Signature freshness
- `securityHealthStatus` - Overall security health

---

## secAntivirusProduct

**Type:** Text  
**Category:** Security  
**Populated By:** Script 04 - Security Analyzer  
**Update Frequency:** Daily

**Description:**
Name and version of installed antivirus product.

**Possible Values:**
- `Windows Defender` - Native Windows protection
- `Sophos Intercept X` - Third-party AV
- `Symantec Endpoint Protection` - Third-party AV
- `None` - No AV installed

**Example:** `Windows Defender 4.18.24010.12`

**Usage Notes:**
- Track AV product standardization across fleet
- Identify devices with outdated AV versions
- Alert if "None" on production devices

**Related Fields:**
- `secAntivirusEnabled` - AV status
- `secAntivirusUpToDate` - Signature status

---

## secAntivirusUpToDate

**Type:** Checkbox  
**Category:** Security  
**Populated By:** Script 04 - Security Analyzer  
**Update Frequency:** Daily

**Description:**
Indicates if antivirus signatures are up-to-date (updated within last 7 days).

**Possible Values:**
- `TRUE` - Signatures current (< 7 days old)
- `FALSE` - Signatures outdated (> 7 days old)

**Example:** `TRUE`

**Usage Notes:**
- Alert if FALSE (outdated signatures reduce protection)
- Check signature update date with secAntivirusLastUpdate
- May indicate connectivity issues preventing updates

**Related Fields:**
- `secAntivirusEnabled` - AV status
- `secAntivirusLastUpdate` - Timestamp of last update

---

## secFirewallEnabled

**Type:** Checkbox  
**Category:** Security  
**Populated By:** Script 04 - Security Analyzer  
**Update Frequency:** Daily

**Description:**
Indicates if Windows Firewall (or third-party firewall) is enabled on at least one network profile.

**Possible Values:**
- `TRUE` - Firewall enabled
- `FALSE` - Firewall disabled on all profiles

**Example:** `TRUE`

**Usage Notes:**
- Alert if FALSE (major security exposure)
- Check all three profiles: Domain, Private, Public
- Public profile should always be enabled for mobile devices

**Related Fields:**
- `secFirewallDomainEnabled` - Domain profile status
- `secFirewallPrivateEnabled` - Private profile status
- `secFirewallPublicEnabled` - Public profile status

---

## secBitLockerEnabled

**Type:** Checkbox  
**Category:** Security  
**Populated By:** Script 07 - BitLocker Monitor  
**Update Frequency:** Daily

**Description:**
Indicates if BitLocker encryption is enabled and fully encrypted on the OS drive.

**Possible Values:**
- `TRUE` - BitLocker fully encrypted on C:
- `FALSE` - BitLocker not enabled or encryption incomplete

**Example:** `TRUE`

**Usage Notes:**
- Required for mobile devices and laptops
- Check blEncryptionInProgress if FALSE (may be encrypting)
- Review blComplianceStatus for detailed encryption state
- Alert if FALSE for devices that leave office

**Related Fields:**
- `blEncryptionInProgress` - Currently encrypting
- `blComplianceStatus` - Overall encryption compliance
- `blRecoveryKeyEscrowed` - Recovery key backup status

---

## secSecurityPostureScore

**Type:** Integer  
**Category:** Security  
**Populated By:** Script 15 - Security Posture Consolidator  
**Update Frequency:** Daily

**Description:**
Comprehensive security posture score (0-100) aggregating multiple security factors.

**Possible Values:**
- `0-39` - Critical security posture
- `40-69` - Warning security posture
- `70-100` - Healthy security posture

**Example:** `85`

**Calculation:**
- Base score: 100
- Deductions:
  - AV disabled: -40 points
  - Firewall disabled: -30 points
  - BitLocker disabled: -15 points
  - Critical patches missing: -15 points
  - SMBv1 enabled: -10 points
  - Failed logins > 50: -10 points
  - Account lockouts > 5: -5 points

**Usage Notes:**
- Target: maintain > 80 for all production devices
- Track trends to identify security degradation
- Use for security compliance reporting
- P1 critical devices require score > 90

**Related Fields:**
- `securityHealthStatus` - Categorical security health
- `secAntivirusEnabled` - AV component
- `secFirewallEnabled` - Firewall component
- `secBitLockerEnabled` - Encryption component

---

## secFailedLogonCount24h

**Type:** Integer  
**Category:** Security  
**Populated By:** Script 15 - Security Posture Consolidator  
**Update Frequency:** Daily

**Description:**
Count of failed logon attempts in the last 24 hours from Windows Security event log.

**Possible Values:**
- `0` - No failed logons
- `1-10` - Normal failed logon rate
- `11-50` - Elevated failed logons (potential issue)
- `51+` - Suspicious activity (possible brute force)

**Example:** `3`

**Usage Notes:**
- Alert if > 50 (potential brute force attack)
- Review secSuspiciousLoginScore for detailed analysis
- Common causes: typos, expired passwords, automated systems
- Cross-reference with secAccountLockouts24h

**Related Fields:**
- `secSuspiciousLoginScore` - Suspicious activity score
- `secAccountLockouts24h` - Account lockout count
- `secLastThreatDetection` - Timestamp of threat detection

---

## secAccountLockouts24h

**Type:** Integer  
**Category:** Security  
**Populated By:** Script 15 - Security Posture Consolidator  
**Update Frequency:** Daily

**Description:**
Count of account lockouts in the last 24 hours.

**Possible Values:**
- `0` - No lockouts
- `1-2` - Occasional lockouts (likely user error)
- `3-5` - Frequent lockouts (investigate)
- `6+` - Suspicious pattern (possible attack)

**Example:** `1`

**Usage Notes:**
- Alert if > 5 (unusual activity)
- May indicate credential stuffing attack
- Check specific accounts affected
- Review with secFailedLogonCount24h for context

**Related Fields:**
- `secFailedLogonCount24h` - Failed logon attempts
- `secSuspiciousLoginScore` - Overall login security

---

## secSuspiciousLoginScore

**Type:** Integer  
**Category:** Security  
**Populated By:** Script 16 - Suspicious Login Pattern Detector  
**Update Frequency:** Every 4 hours

**Description:**
Risk score (0-100) indicating likelihood of suspicious login activity based on pattern analysis.

**Possible Values:**
- `0-20` - Normal login activity
- `21-50` - Slightly unusual (monitor)
- `51-75` - Suspicious (investigate)
- `76-100` - Highly suspicious (immediate action)

**Scoring Factors:**
- Failed logon rate and frequency
- Account lockout patterns
- Off-hours login attempts
- Geographic anomalies (if available)
- Multiple accounts affected

**Example:** `15`

**Usage Notes:**
- Alert if > 75 (high risk)
- Review Event Viewer for specific login events
- Check for compromised credentials
- May require password resets

**Related Fields:**
- `secFailedLogonCount24h` - Failed attempts
- `secAccountLockouts24h` - Lockout count
- `secLastThreatDetection` - Last threat timestamp

---

## secInternetExposedPortsCount

**Type:** Integer  
**Category:** Security  
**Populated By:** Script 28 - Security Surface Telemetry  
**Update Frequency:** Daily

**Description:**
Number of ports listening on public internet interfaces (not localhost or private IPs).

**Possible Values:**
- `0` - No internet-exposed ports (workstation)
- `1-5` - Few exposed ports (typical server)
- `6-10` - Moderate exposure
- `11+` - High exposure (review required)

**Example:** `3`

**Usage Notes:**
- Expected for servers (RDP, HTTP, HTTPS)
- Unexpected for workstations (investigate)
- Review secHighRiskServicesExposed for specific services
- Compare against baseline for device

**Related Fields:**
- `secHighRiskServicesExposed` - High-risk service count
- `secSecuritySurfaceSummaryHtml` - Detailed port listing

---

## secHighRiskServicesExposed

**Type:** Integer  
**Category:** Security  
**Populated By:** Script 28 - Security Surface Telemetry  
**Update Frequency:** Daily

**Description:**
Count of high-risk services exposed to internet (SMB, RDP, Telnet, FTP, etc.).

**Possible Values:**
- `0` - No high-risk services exposed (ideal)
- `1-2` - Some exposure (typical for servers)
- `3+` - Excessive exposure (reduce attack surface)

**High-Risk Services:**
- SMB (445)
- RDP (3389) without VPN
- Telnet (23)
- FTP (21)
- SQL Server (1433)
- MySQL (3306)

**Example:** `1`

**Usage Notes:**
- Alert if > 0 on workstations
- RDP should be behind VPN or restricted by IP
- SMB should never be internet-exposed
- Review firewall rules to restrict access

**Related Fields:**
- `secInternetExposedPortsCount` - Total port count
- `secSecuritySurfaceSummaryHtml` - Service details

---

## secSoonExpiringCertsCount

**Type:** Integer  
**Category:** Security  
**Populated By:** Script 28 - Security Surface Telemetry  
**Update Frequency:** Daily

**Description:**
Count of SSL/TLS certificates expiring within 30 days.

**Possible Values:**
- `0` - No certificates expiring soon
- `1-3` - Some certificates need renewal
- `4+` - Many expiring (certificate management issue)

**Example:** `1`

**Usage Notes:**
- Alert 30 days before expiration
- Escalate alert at 14 days
- Critical alert at 7 days
- Review secSecuritySurfaceSummaryHtml for certificate details

**Related Fields:**
- `secSecuritySurfaceSummaryHtml` - Certificate expiration details

---

## secEncryptionCompliance

**Type:** Dropdown  
**Category:** Security  
**Populated By:** Script 20 - Security Config Checker  
**Update Frequency:** Daily

**Description:**
Overall encryption compliance status for data at rest and in transit.

**Possible Values:**
- `Compliant` - All encryption requirements met
- `Partial` - Some encryption gaps
- `Non-Compliant` - Major encryption gaps
- `Unknown` - Cannot determine

**Checks:**
- BitLocker enabled on all drives
- TLS 1.2+ enabled
- SMBv1 disabled
- Weak ciphers disabled

**Example:** `Compliant`

**Usage Notes:**
- "Non-Compliant" requires remediation
- Mobile devices must be "Compliant"
- Review specific gaps in related fields

**Related Fields:**
- `secBitLockerEnabled` - Drive encryption
- `secTLS12Enforced` - TLS version
- `secSMBv1Disabled` - Legacy protocol disabled

---

## secLastThreatDetection

**Type:** DateTime (Unix Epoch)  
**Category:** Security  
**Populated By:** Script 15 - Security Posture Consolidator  
**Update Frequency:** Daily

**Description:**
Timestamp of the most recent threat detection event (malware, suspicious activity, etc.).

**Possible Values:**
- Unix Epoch timestamp
- `NULL` - No threats detected

**Example:** `1738840000` (February 7, 2026, 10:00 AM)

**Usage Notes:**
- Alert on any recent threat detection (< 24 hours)
- Review Windows Defender or AV logs for details
- Check if threat was quarantined/removed
- May require additional investigation

**Related Fields:**
- `secSuspiciousLoginScore` - Related authentication threats
- `secFailedLogonCount24h` - Failed login attempts

---

*[Additional 20 security fields follow similar pattern: secFirewallDomainEnabled, secFirewallPrivateEnabled, secFirewallPublicEnabled, secSMBv1Disabled, secTLS12Enforced, secRDPNLAEnabled, secUACEnabled, secWindowsUpdateEnabled, secDefenderRealTimeEnabled, secDefenderCloudProtectionEnabled, secDefenderSignatureAge, secLastVirusScan, secThreatCount30d, secQuarantinedThreatCount, secCredentialGuardEnabled, secSecureBootEnabled, secTPMEnabled, secHyperVCodeIntegrityEnabled, secAppControlEnabled, secNetworkProtectionEnabled]*

---

# Infrastructure Fields

**Category:** Server Roles and Services  
**Total Fields:** 40  
**Scripts:** Scripts 7-12 (Infrastructure monitors)  
**Purpose:** Track server-specific roles and services

---

## srvRole

**Type:** Dropdown  
**Category:** Infrastructure  
**Populated By:** Manual configuration or auto-detection  
**Update Frequency:** As needed

**Description:**
Primary server role or function determining monitoring and patching behavior.

**Possible Values:**
- `Workstation` - Standard desktop/laptop
- `Server-Generic` - General-purpose server
- `IIS` - Web server
- `SQL` - Database server
- `Exchange` - Mail server
- `DC` - Domain controller
- `File-Server` - File/print server
- `Hyper-V` - Virtualization host
- `Backup` - Backup server
- `Application` - Application server

**Example:** `IIS`

**Usage Notes:**
- Determines which infrastructure monitoring scripts run
- Affects patch deployment timing and maintenance windows
- Used for alert customization and escalation
- Auto-detection can identify common roles

**Related Fields:**
- `srvRoleDetails` - Additional role information
- `baseBusinessCriticality` - Priority level
- `autoAllowAfterHoursReboot` - Reboot behavior

---

## srvIISInstalled

**Type:** Checkbox  
**Category:** Infrastructure  
**Populated By:** Script 09 - IIS Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Indicates if IIS (Internet Information Services) web server role is installed.

**Possible Values:**
- `TRUE` - IIS installed
- `FALSE` - IIS not installed

**Example:** `TRUE`

**Usage Notes:**
- Triggers IIS-specific monitoring if TRUE
- Check srvIISHealthStatus for operational status
- May require specific patching considerations

**Related Fields:**
- `srvIISHealthStatus` - IIS health
- `srvIISVersion` - IIS version
- `srvIISSiteCount` - Number of websites

---

## srvIISHealthStatus

**Type:** Text  
**Category:** Infrastructure  
**Populated By:** Script 09 - IIS Monitor  
**Update Frequency:** Every 4 hours

**Description:**
IIS web server health status.

**Possible Values:**
- `Unknown` - Cannot assess (IIS not installed or monitoring error)
- `Healthy` - All sites running, no errors
- `Warning` - Some sites stopped or elevated error rate
- `Critical` - Multiple sites down or high error rate

**Example:** `Healthy`

**Usage Notes:**
- Alert on "Critical" status
- Review srvIISSummaryHtml for site-specific details
- Check Windows Application event log for IIS errors

**Related Fields:**
- `srvIISSiteCount` - Total websites
- `srvIISRunningSites` - Running websites
- `srvIISStoppedSites` - Stopped websites

---

## srvIISVersion

**Type:** Text  
**Category:** Infrastructure  
**Populated By:** Script 09 - IIS Monitor  
**Update Frequency:** Daily

**Description:**
Installed IIS version number.

**Possible Values:**
- `IIS 10.0` - Windows Server 2016+
- `IIS 8.5` - Windows Server 2012 R2
- `IIS 8.0` - Windows Server 2012
- `IIS 7.5` - Windows Server 2008 R2
- Older versions (unsupported)

**Example:** `IIS 10.0`

**Usage Notes:**
- Versions < 8.5 approaching end of support
- Track for upgrade planning
- Security patch requirements vary by version

**Related Fields:**
- `srvIISInstalled` - Installation status
- `srvIISHealthStatus` - Operational health

---

## srvIISSiteCount

**Type:** Integer  
**Category:** Infrastructure  
**Populated By:** Script 09 - IIS Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Total number of websites configured in IIS.

**Possible Values:**
- `0` - No sites configured
- `1-10` - Typical configuration
- `11+` - Many sites hosted

**Example:** `3`

**Usage Notes:**
- Compare with srvIISRunningSites to identify stopped sites
- Track changes over time for configuration drift

**Related Fields:**
- `srvIISRunningSites` - Currently running sites
- `srvIISStoppedSites` - Stopped sites

---

## srvSQLInstalled

**Type:** Checkbox  
**Category:** Infrastructure  
**Populated By:** Script 10 - SQL Server Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Indicates if Microsoft SQL Server is installed.

**Possible Values:**
- `TRUE` - SQL Server installed
- `FALSE` - SQL Server not installed

**Example:** `TRUE`

**Usage Notes:**
- Triggers SQL-specific monitoring if TRUE
- Check srvSQLHealthStatus for operational status
- SQL patching requires special handling

**Related Fields:**
- `srvSQLHealthStatus` - SQL health
- `srvSQLVersion` - SQL version
- `srvSQLDatabaseCount` - Number of databases

---

## srvSQLHealthStatus

**Type:** Text  
**Category:** Infrastructure  
**Populated By:** Script 10 - SQL Server Monitor  
**Update Frequency:** Every 4 hours

**Description:**
SQL Server database engine health status.

**Possible Values:**
- `Unknown` - Cannot assess (SQL not installed or monitoring error)
- `Healthy` - Service running, no issues
- `Warning` - Performance issues or non-critical errors
- `Critical` - Service stopped or database offline

**Example:** `Healthy`

**Usage Notes:**
- Alert on "Critical" status (impacts applications)
- Review srvSQLSummaryHtml for database-specific details
- Check SQL Server error logs

**Related Fields:**
- `srvSQLDatabaseCount` - Total databases
- `srvSQLFailedJobCount` - Failed SQL Agent jobs
- `srvSQLBackupAgeDays` - Backup recency

---

## srvSQLVersion

**Type:** Text  
**Category:** Infrastructure  
**Populated By:** Script 10 - SQL Server Monitor  
**Update Frequency:** Daily

**Description:**
Installed SQL Server version and edition.

**Possible Values:**
- `SQL Server 2022 Standard` - Latest version
- `SQL Server 2019 Enterprise`
- `SQL Server 2017 Express`
- `SQL Server 2016` - Approaching end of support
- Older versions (unsupported)

**Example:** `SQL Server 2019 Standard`

**Usage Notes:**
- Versions < 2017 approaching end of support
- Express edition has limitations (10GB database limit)
- Track for license compliance and upgrade planning

**Related Fields:**
- `srvSQLInstalled` - Installation status
- `srvSQLEdition` - Specific edition (Express, Standard, Enterprise)

---

## srvSQLDatabaseCount

**Type:** Integer  
**Category:** Infrastructure  
**Populated By:** Script 10 - SQL Server Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Number of user databases (excludes system databases: master, model, msdb, tempdb).

**Possible Values:**
- `0` - No user databases
- `1-10` - Typical configuration
- `11-50` - Many databases
- `51+` - Large database server

**Example:** `5`

**Usage Notes:**
- Track for capacity planning
- Alert if databases go offline (check srvSQLOfflineDatabases)
- Compare with backup status fields

**Related Fields:**
- `srvSQLOfflineDatabases` - Offline database count
- `srvSQLBackupAgeDays` - Backup recency

---

## srvHyperVInstalled

**Type:** Checkbox  
**Category:** Infrastructure  
**Populated By:** Script 08 - Hyper-V Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Indicates if Hyper-V virtualization role is installed.

**Possible Values:**
- `TRUE` - Hyper-V installed
- `FALSE` - Hyper-V not installed

**Example:** `TRUE`

**Usage Notes:**
- Triggers Hyper-V-specific monitoring if TRUE
- Check hvHealthStatus for operational status
- Hyper-V hosts require careful patching (impacts VMs)

**Related Fields:**
- `hvHealthStatus` - Hyper-V health
- `hvVMCount` - Total VMs
- `hvVMRunningCount` - Running VMs

---

## hvHealthStatus

**Type:** Text  
**Category:** Infrastructure  
**Populated By:** Script 08 - Hyper-V Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Hyper-V host health status including VMs and replication.

**Possible Values:**
- `Unknown` - Cannot assess (Hyper-V not installed or monitoring error)
- `Healthy` - All VMs running, no replication issues
- `Warning` - Some VMs stopped or minor replication lag
- `Critical` - Multiple VMs down or replication failed

**Example:** `Healthy`

**Usage Notes:**
- Alert on "Critical" status
- Review hvVMSummary for VM-specific details
- Check replication health with hvReplicationHealthIssues

**Related Fields:**
- `hvVMCount` - Total VMs
- `hvVMRunningCount` - Running VMs
- `hvVMStoppedCount` - Stopped VMs
- `hvReplicationHealthIssues` - Replication problems

---

## hvVMCount

**Type:** Integer  
**Category:** Infrastructure  
**Populated By:** Script 08 - Hyper-V Monitor  
**Update Frequency:** Every 4 hours

**Description:**
Total number of virtual machines configured on Hyper-V host.

**Possible Values:**
- `0` - No VMs configured
- `1-10` - Small virtualization host
- `11-50` - Medium host
- `51+` - Large host

**Example:** `12`

**Usage Notes:**
- Track for capacity planning
- Compare with hvMemoryAssignedGB for resource allocation
- Alert if count changes unexpectedly (VM creation/deletion)

**Related Fields:**
- `hvVMRunningCount` - Currently running VMs
- `hvVMStoppedCount` - Stopped VMs
- `hvMemoryAssignedGB` - Total memory allocated

---

*[Additional 25 infrastructure fields follow similar pattern: hvVMRunningCount, hvVMStoppedCount, hvMemoryAssignedGB, hvStorageUsedGB, hvReplicationHealthIssues, srvMySQLInstalled, mysqlHealthStatus, mysqlVersion, mysqlDatabaseCount, mysqlReplicationStatus, mysqlReplicationLag, srvFlexLMInstalled, flexlmHealthStatus, flexlmVersion, flexlmTotalLicenses, flexlmLicensesInUse, flexlmLicenseUtilizationPercent, flexlmDeniedRequests24h, flexlmExpiringLicenses30d, srvDCRole, dcReplicationStatus, dcSysvolReplication, dcDNSStatus, dcLastADBackup, dcDFSRBacklogCount]*

---

# Capacity Fields

**Category:** Resource Capacity and Forecasting  
**Total Fields:** 20  
**Scripts:** Scripts 5, 22  
**Purpose:** Track resource utilization and predict capacity issues

---

## capDiskFreePercent

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 05 - Capacity Analyzer, Native monitoring  
**Update Frequency:** Every 4 hours

**Description:**
Percentage of free space on primary system drive (typically C:).

**Possible Values:**
- `0-9` - Critical (disk nearly full)
- `10-19` - Warning (low disk space)
- `20-100` - Healthy

**Example:** `35`

**Usage Notes:**
- Alert at < 10% (critical)
- Warning at < 20%
- Servers may need higher thresholds (< 15% critical)
- Review capDaysUntilDiskFull for trend analysis

**Related Fields:**
- `capDiskFreeGB` - Absolute free space
- `capDaysUntilDiskFull` - Predicted exhaustion
- `diskHealthStatus` - Disk health classification

---

## capDiskFreeGB

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 05 - Capacity Analyzer, Native monitoring  
**Update Frequency:** Every 4 hours

**Description:**
Absolute free space in gigabytes on primary system drive.

**Possible Values:**
- `0-10` - Very low (critical regardless of percentage)
- `11-50` - Low
- `51+` - Adequate

**Example:** `120`

**Usage Notes:**
- Important for large drives where percentage can be misleading
- Alert if < 10 GB even if percentage seems acceptable
- Consider growth rate from capDaysUntilDiskFull

**Related Fields:**
- `capDiskFreePercent` - Percentage view
- `capDiskTotalGB` - Total drive capacity
- `capDaysUntilDiskFull` - Predicted exhaustion

---

## capDiskTotalGB

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 05 - Capacity Analyzer  
**Update Frequency:** Daily

**Description:**
Total capacity of primary system drive in gigabytes.

**Possible Values:**
- `50-250` - Typical workstation
- `251-500` - Large workstation or small server
- `501-2000` - Typical server
- `2001+` - Large server or storage

**Example:** `500`

**Usage Notes:**
- Used for percentage calculations
- Track for drive expansion planning
- May indicate need for additional drives

**Related Fields:**
- `capDiskFreeGB` - Free space
- `capDiskFreePercent` - Percentage free

---

## capDaysUntilDiskFull

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 22 - Capacity Trend Forecaster  
**Update Frequency:** Weekly

**Description:**
Predicted number of days until disk reaches 0% free space based on growth trend analysis.

**Possible Values:**
- `0-30` - Critical (imminent exhaustion)
- `31-90` - Warning (plan expansion)
- `91-180` - Monitor
- `181+` - Healthy
- `-1` or `NULL` - Cannot predict (insufficient data or negative growth)

**Example:** `120`

**Usage Notes:**
- Alert if < 30 days
- Requires 14+ days of historical data
- Prediction assumes linear growth
- May be inaccurate for bursty growth patterns

**Related Fields:**
- `capDiskFreeGB` - Current free space
- `capDiskGrowthRateGBPerDay` - Growth rate

---

## capDiskGrowthRateGBPerDay

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 22 - Capacity Trend Forecaster  
**Update Frequency:** Weekly

**Description:**
Average disk space consumption rate in GB per day over last 30 days.

**Possible Values:**
- `0` - No growth or shrinking
- `1-5` - Typical workstation
- `6-20` - Active server
- `21+` - High-growth server

**Example:** `3`

**Usage Notes:**
- Used for capDaysUntilDiskFull calculation
- Sudden changes may indicate new application or data dump
- Negative values indicate disk cleanup

**Related Fields:**
- `capDaysUntilDiskFull` - Predicted exhaustion
- `capDiskFreeGB` - Current free space

---

## capMemoryUsedPercent

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 05 - Capacity Analyzer, Native monitoring  
**Update Frequency:** Every 4 hours

**Description:**
Percentage of physical RAM currently in use.

**Possible Values:**
- `0-79` - Normal
- `80-89` - High utilization (warning)
- `90-100` - Critical utilization (memory pressure)

**Example:** `65`

**Usage Notes:**
- Alert at > 90% (critical)
- Warning at > 80%
- Sustained high memory may indicate memory leak
- Check available memory with capMemoryAvailableGB

**Related Fields:**
- `capMemoryAvailableGB` - Available RAM
- `capMemoryTotalGB` - Total installed RAM
- `memoryHealthStatus` - Memory health classification

---

## capMemoryAvailableGB

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 05 - Capacity Analyzer, Native monitoring  
**Update Frequency:** Every 4 hours

**Description:**
Amount of physical RAM available for allocation in gigabytes.

**Possible Values:**
- `0-1` - Critical (memory exhaustion)
- `2-4` - Low (warning)
- `5+` - Adequate

**Example:** `8`

**Usage Notes:**
- Alert if < 2 GB
- More meaningful than percentage for servers
- Check capMemoryUsedPercent for context

**Related Fields:**
- `capMemoryUsedPercent` - Utilization percentage
- `capMemoryTotalGB` - Total installed RAM

---

## capMemoryTotalGB

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 05 - Capacity Analyzer  
**Update Frequency:** Daily

**Description:**
Total installed physical RAM in gigabytes.

**Possible Values:**
- `4-8` - Typical workstation
- `16-32` - Power user or small server
- `64-128` - Typical server
- `256+` - Large server

**Example:** `16`

**Usage Notes:**
- Used for percentage calculations
- Track for upgrade planning
- Compare with capMemoryForecastRisk

**Related Fields:**
- `capMemoryAvailableGB` - Available RAM
- `capMemoryUsedPercent` - Utilization
- `capMemoryForecastRisk` - Predicted capacity issues

---

## capMemoryForecastRisk

**Type:** Dropdown  
**Category:** Capacity  
**Populated By:** Script 22 - Capacity Trend Forecaster  
**Update Frequency:** Weekly

**Description:**
Predicted risk of memory capacity issues based on usage trends.

**Possible Values:**
- `Low` - Memory utilization stable and adequate headroom
- `Medium` - Increasing utilization trend, monitor
- `High` - Utilization trend indicates capacity issue within 90 days
- `Critical` - Capacity issue imminent (within 30 days)

**Example:** `Low`

**Usage Notes:**
- "High" or "Critical" requires action (add RAM or optimize applications)
- Based on 30-day trend analysis
- Check capMemoryUsedPercent for current state

**Related Fields:**
- `capMemoryUsedPercent` - Current utilization
- `capMemoryTotalGB` - Installed capacity

---

## capCPUUsedPercent

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 05 - Capacity Analyzer, Native monitoring  
**Update Frequency:** Every 4 hours

**Description:**
Average CPU utilization percentage over 15-minute sampling period.

**Possible Values:**
- `0-69` - Normal
- `70-89` - High utilization (warning)
- `90-100` - Critical utilization (performance impact)

**Example:** `45`

**Usage Notes:**
- Alert at > 90% sustained (critical)
- Warning at > 70% sustained
- Spikes are normal, focus on sustained high usage
- Check for runaway processes

**Related Fields:**
- `capCPUPeakUsage` - Peak observed CPU
- `capCPUForecastRisk` - Predicted capacity issues
- `cpuHealthStatus` - CPU health classification

---

## capCPUPeakUsage

**Type:** Integer  
**Category:** Capacity  
**Populated By:** Script 05 - Capacity Analyzer  
**Update Frequency:** Every 4 hours

**Description:**
Peak CPU utilization percentage observed in last 4 hours.

**Possible Values:**
- `0-100` - Percentage

**Example:** `78`

**Usage Notes:**
- Helps identify CPU spikes vs. sustained load
- Compare with capCPUUsedPercent (average)
- Frequent peaks > 95% may indicate capacity issue

**Related Fields:**
- `capCPUUsedPercent` - Average utilization
- `capCPUForecastRisk` - Predicted capacity issues

---

## capCPUForecastRisk

**Type:** Dropdown  
**Category:** Capacity  
**Populated By:** Script 22 - Capacity Trend Forecaster  
**Update Frequency:** Weekly

**Description:**
Predicted risk of CPU capacity issues based on utilization trends.

**Possible Values:**
- `Low` - CPU utilization stable and adequate headroom
- `Medium` - Increasing utilization trend, monitor
- `High` - Utilization trend indicates capacity issue within 90 days
- `Critical` - Capacity issue imminent (within 30 days)

**Example:** `Low`

**Usage Notes:**
- "High" or "Critical" requires action (add CPUs or optimize applications)
- Based on 30-day trend analysis
- Check capCPUUsedPercent for current state

**Related Fields:**
- `capCPUUsedPercent` - Current utilization
- `capCPUPeakUsage` - Peak utilization

---

## capCapacityActionNeeded

**Type:** Checkbox  
**Category:** Capacity  
**Populated By:** Script 22 - Capacity Trend Forecaster  
**Update Frequency:** Weekly

**Description:**
Indicates if any capacity resource (disk, memory, CPU) requires action based on forecasting.

**Possible Values:**
- `TRUE` - At least one capacity issue predicted (disk full, memory exhaustion, CPU overload)
- `FALSE` - All capacity metrics healthy

**Example:** `FALSE`

**Usage Notes:**
- Alert when TRUE
- Review specific forecast fields to identify issue:
  - capDaysUntilDiskFull
  - capMemoryForecastRisk
  - capCPUForecastRisk
- Use for capacity planning dashboard

**Related Fields:**
- `capDaysUntilDiskFull` - Disk forecast
- `capMemoryForecastRisk` - Memory forecast
- `capCPUForecastRisk` - CPU forecast

---

*[Additional 8 capacity fields: capPageFileUsagePercent, capPageFileMaxSizeMB, capNetworkBandwidthUsedPercent, capStorageIOPSAverage, capStorageIOPSPeak, capStorageLatencyMs, capSaaSLatencyCategory]*

---

# Remaining Field Categories

**Status:** Part 2 Complete  
**Fields Documented:** 150+ of 277+  
**Progress:** ~54%

**Remaining Categories:**
- Performance Fields (20+ fields)
- User Experience (UX) Fields (20+ fields)
- Telemetry Fields (20+ fields)
- Drift Detection Fields (10+ fields)
- Active Directory Fields (15+ fields)
- WYSIWYG Report Fields (30+ fields)
- DateTime Fields (20+ fields)
- Miscellaneous Fields (12+ fields)

**Next Section:** Performance and User Experience fields (Part 3)

---

**Last Updated:** February 8, 2026, 2:00 PM CET  
**Version:** 1.1 (Part 1 + Part 2)
