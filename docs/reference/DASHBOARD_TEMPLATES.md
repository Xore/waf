# WAF Dashboard Templates Guide

**Purpose:** Ready-to-use dashboard configurations for Windows Automation Framework  
**Created:** February 8, 2026  
**Audience:** Administrators, operations teams, management  
**Status:** Production ready templates

---

## Overview

This guide provides complete dashboard configurations for common monitoring scenarios. Each template includes widget specifications, field mappings, and visual layout recommendations.

### Available Dashboards
1. Executive Overview Dashboard
2. Infrastructure Monitoring Dashboard
3. Security Dashboard
4. Patching Dashboard
5. Capacity Planning Dashboard
6. Active Directory Dashboard

---

## 1. Executive Overview Dashboard

**Purpose:** High-level view of IT environment health for management  
**Audience:** Executives, IT managers, directors  
**Update Frequency:** Real-time to hourly

### Widgets

#### 1.1 Critical Devices Count
**Type:** Number widget with trend  
**Field:** Count of devices in critical state  
**Logic:** 
```
(opsHealthScore < 40) OR 
(statStabilityScore < 40) OR 
(secSecurityPostureScore < 40)
```
**Color Coding:**
- Green: 0 devices
- Yellow: 1-5 devices
- Red: 6+ devices

**Trend:** Show 7-day change

#### 1.2 Average Health Score
**Type:** Gauge widget  
**Field:** `opsHealthScore`  
**Calculation:** Average across all online devices  
**Ranges:**
- 90-100: Green (Excellent)
- 70-89: Light green (Good)
- 50-69: Yellow (Fair)
- 30-49: Orange (Poor)
- 0-29: Red (Critical)

#### 1.3 Devices by Health Category
**Type:** Pie chart  
**Field:** `opsHealthScore`  
**Categories:**
- Excellent (90-100)
- Good (70-89)
- Fair (50-69)
- Poor (30-49)
- Critical (0-29)

**Display:** Show count and percentage for each category

#### 1.4 Security Posture Overview
**Type:** Horizontal bar chart  
**Fields:**
- `secAntivirusEnabled = False` (Antivirus Disabled)
- `secFirewallEnabled = False` (Firewall Disabled)
- `updComplianceStatus = "Critical Gap"` (Critical Patch Gap)
- `secSecurityPostureScore < 50` (Poor Security Posture)

**Goal:** All bars should show 0 devices

#### 1.5 Patch Compliance Status
**Type:** Stacked bar chart  
**Field:** `updComplianceStatus`  
**Categories:**
- Compliant (Green)
- Minor Gap (Light yellow)
- Significant Gap (Orange)
- Critical Gap (Red)
- Unknown (Gray)

**Display:** Show percentages and counts

#### 1.6 Backup Health
**Type:** Number widget  
**Field:** `veeamFailedJobsCount > 0` OR `backupLastSuccess > 24h ago`  
**Display:** Count of devices with backup issues  
**Alert:** Red if > 0

#### 1.7 Top 10 Problem Devices
**Type:** Data table  
**Columns:**
- Device Name
- Health Score (`opsHealthScore`)
- Stability Score (`statStabilityScore`)
- Security Score (`secSecurityPostureScore`)
- Primary Issue (lowest score category)

**Sort:** By lowest health score  
**Actions:** Click to view device details

#### 1.8 Script Execution Success Rate
**Type:** Percentage gauge  
**Data Source:** NinjaRMM script execution logs  
**Calculation:** (Successful executions / Total executions) × 100  
**Target:** > 95%  
**Color Coding:**
- Green: 95-100%
- Yellow: 90-94%
- Red: < 90%

### Layout Recommendation
```
+------------------+------------------+------------------+
| Critical Devices | Average Health   | Security Posture |
| (Large number)   | (Gauge)          | (Bar chart)      |
+------------------+------------------+------------------+
| Health Category Distribution         | Patch Compliance |
| (Pie chart - spans 2 columns)        | (Stacked bar)    |
+--------------------------------------+------------------+
| Backup Health    | Script Success   |                  |
| (Number)         | (Gauge)          |                  |
+------------------+------------------+------------------+
| Top 10 Problem Devices                                 |
| (Data table - spans full width)                        |
+--------------------------------------------------------+
```

---

## 2. Infrastructure Monitoring Dashboard

**Purpose:** Detailed server and infrastructure health monitoring  
**Audience:** System administrators, infrastructure team  
**Update Frequency:** Real-time to every 15 minutes

### Widgets

#### 2.1 Server Health by Role
**Type:** Grouped bar chart  
**Fields:** `srvRole` grouped by `opsHealthScore` ranges  
**Roles:**
- IIS Web Servers
- MSSQL Database Servers
- DNS Servers
- DHCP Servers
- Domain Controllers
- Hyper-V Hosts
- File Servers
- Print Servers

**Display:** Show health score distribution per role

#### 2.2 IIS Server Status
**Type:** Data table  
**Fields:**
- Device Name
- `iisHealthStatus`
- `iisAppPoolsRunning` / `iisAppPoolsTotal`
- `iisAppPoolsStopped`
- `iisWorkerProcessCrashes24h`
- `iisRequestQueueLength`

**Alert:** Highlight rows where `iisHealthStatus = "Critical"` OR `iisAppPoolsStopped > 0`

#### 2.3 SQL Server Health
**Type:** Data table  
**Fields:**
- Device Name
- `mssqlHealthStatus`
- `mssqlLastBackup` (hours ago)
- `mssqlDatabaseStatus`
- `mssqlDeadlocks24h`
- `mssqlConnectionCount`

**Alert:** Highlight rows where `mssqlHealthStatus = "Critical"` OR `mssqlLastBackup > 24h`

#### 2.4 DNS Server Status
**Type:** Status list  
**Fields:**
- Device Name
- `dnsHealthStatus`
- `dnsZoneCount`
- `dnsFailedQueries24h`
- `dnsZoneTransferErrors24h`

**Alert:** Red status if `dnsHealthStatus = "Critical"`

#### 2.5 DHCP Server Status
**Type:** Status list with gauge  
**Fields:**
- Device Name
- `dhcpHealthStatus`
- `dhcpScopesTotal`
- `dhcpScopesDepleted`
- `dhcpScopeUtilizationPercent`

**Alert:** Red if `dhcpScopesDepleted > 0` OR `dhcpScopeUtilizationPercent > 90%`

#### 2.6 Hyper-V Host Health
**Type:** Data table  
**Fields:**
- Host Name
- `hvHealthStatus`
- `hvVMCountRunning` / `hvVMCountTotal`
- `hvMemoryAvailableMB`
- `hvStorageAvailableGB`

**Alert:** Highlight critical hosts

#### 2.7 Veeam Backup Status
**Type:** Status widget  
**Fields:**
- `veeamHealthStatus`
- `veeamFailedJobsCount`
- `veeamWarningJobsCount`
- `veeamRunningJobsCount`

**Display:** Show last 24h summary with color coding

#### 2.8 Capacity Alerts by Server
**Type:** Data table  
**Fields:**
- Device Name
- `capDiskFreePercent`
- `capDaysUntilDiskFull`
- `capMemoryUsedPercent`
- CPU Utilization (native metric)

**Filter:** Only show servers with warnings (disk < 20%, memory > 85%, days < 90)

#### 2.9 Service Failures Summary
**Type:** Number widgets row  
**Fields:**
- Total service failures: `statServiceFailures24h` (sum)
- Devices affected: Count where `statServiceFailures24h > 0`
- Critical services down: Count where `driftCriticalServiceDrift = True`

### Layout Recommendation
```
+------------------+------------------+------------------+
| Server Health by Role (Bar chart - spans 3 columns)    |
+------------------+------------------+------------------+
| IIS Server Status (Table - spans 2 columns) | Veeam   |
|                                              | Backup  |
+----------------------------------------------+ Status  |
| SQL Server Health (Table - spans 2 columns) |         |
+----------------------------------------------+---------+
| DNS Status       | DHCP Status      | HyperV Health   |
| (List)           | (List + Gauge)   | (Table)         |
+------------------+------------------+------------------+
| Capacity Alerts by Server (Table - full width)        |
+--------------------------------------------------------+
| Service Failures Summary (3 number widgets)            |
+--------------------------------------------------------+
```

---

## 3. Security Dashboard

**Purpose:** Security posture monitoring and threat detection  
**Audience:** Security team, compliance officers, IT management  
**Update Frequency:** Real-time to every 4 hours

### Widgets

#### 3.1 Security Posture Score Distribution
**Type:** Histogram  
**Field:** `secSecurityPostureScore`  
**Ranges:**
- 90-100 (Excellent)
- 70-89 (Good)
- 50-69 (Needs Attention)
- 30-49 (At Risk)
- 0-29 (Critical)

**Display:** Bar chart with device counts per range

#### 3.2 Security Control Status
**Type:** Status grid (4 quadrants)  
**Fields:**
- Antivirus: Count where `secAntivirusEnabled = False`
- Firewall: Count where `secFirewallEnabled = False`
- BitLocker: Count where `secBitLockerStatus != "Protected"`
- Windows Defender: Count where `secDefenderEnabled = False`

**Color:** Green if 0, Red if > 0

#### 3.3 Patch Compliance by Priority
**Type:** Grouped bar chart  
**Fields:** Device priority (`basePriority`) × `updComplianceStatus`  
**Groups:**
- P1 Critical devices
- P2 High priority devices
- P3 Medium priority devices
- P4 Low priority devices

**Display:** Show compliance status distribution per priority level

#### 3.4 Authentication Security
**Type:** Data table  
**Fields:**
- Device Name
- `secFailedLogonCount24h`
- `secAccountLockouts24h`
- `secSuspiciousLoginScore`
- `secLastThreatDetection`

**Filter:** Only show devices with suspicious activity  
**Sort:** By `secSuspiciousLoginScore` descending

#### 3.5 Internet Exposure Risk
**Type:** Number widgets with detail table  
**Summary Fields:**
- Total exposed ports: Sum of `secInternetExposedPortsCount`
- High-risk services: Sum of `secHighRiskServicesExposed`
- Devices exposed: Count where `secInternetExposedPortsCount > 0`

**Detail Table:**
- Device Name
- `secInternetExposedPortsCount`
- `secHighRiskServicesExposed`
- `secSecuritySurfaceSummaryHtml` (click to view)

#### 3.6 Certificate Expiration Tracking
**Type:** Timeline chart  
**Field:** `secSoonExpiringCertsCount`  
**Display:** Show devices with certificates expiring in:
- < 7 days (Critical - Red)
- 7-30 days (Warning - Orange)
- 30-90 days (Attention - Yellow)

#### 3.7 Configuration Drift Alerts
**Type:** Status list  
**Fields:**
- Device Name
- `driftLocalAdminDrift`
- `driftLocalAdminDriftMagnitude`
- `driftNewAppsCount`
- `driftCriticalServiceDrift`

**Filter:** Only show devices with active drift  
**Alert:** Highlight "High" or "Critical" magnitude

#### 3.8 Encryption Compliance
**Type:** Pie chart  
**Field:** `secEncryptionCompliance`  
**Categories:**
- Compliant (Green)
- Partial (Yellow)
- Non-Compliant (Red)
- Unknown (Gray)

**Display:** Show percentage and device count

#### 3.9 Threat Detection Timeline
**Type:** Line chart  
**Field:** `secLastThreatDetection`  
**Display:** Show count of threat detections over last 30 days  
**Grouping:** By day

### Layout Recommendation
```
+------------------+------------------+------------------+
| Security Posture Distribution (Histogram - 2 cols) |  |
|                                     | Security Control|
|                                     | Status (Grid)   |
+-------------------------------------+-----------------+
| Patch Compliance by Priority (Bar chart - full)     |
+------------------------------------------------------+
| Authentication Security (Table - spans 2 columns)   |
|                                     | Certificate     |
|                                     | Expiration      |
+-------------------------------------+-----------------+
| Internet Exposure Risk (Numbers + Table)            |
+-----------------------------------------------------+
| Config Drift     | Encryption       | Threat Timeline|
| (List)           | Compliance (Pie) | (Line chart)   |
+------------------+------------------+----------------+
```

---

## 4. Patching Dashboard

**Purpose:** Patch deployment tracking and compliance monitoring  
**Audience:** Patch management team, operations  
**Update Frequency:** Real-time to daily

### Widgets

#### 4.1 Patch Ring Distribution
**Type:** Donut chart  
**Field:** `patchRing`  
**Categories:**
- PR1-Test (Inner ring)
- PR2-Production (Outer ring)
- Unassigned (No ring)

**Display:** Show device count and percentage

#### 4.2 Patch Validation Status
**Type:** Status grid  
**Field:** `patchValidationStatus`  
**Rows:**
- P1 Critical devices
- P2 High priority devices
- P3 Medium priority devices
- P4 Low priority devices

**Columns:**
- Passed (Green)
- Failed (Red)
- Pending (Yellow)
- Error (Orange)

#### 4.3 Recent Patch Deployments
**Type:** Timeline chart  
**Fields:**
- `patchLastAttemptDate`
- `patchLastAttemptStatus`
- `patchLastPatchCount`

**Display:** Show last 30 days of patch activity  
**Color Code:**
- Success (Green)
- Partial (Yellow)
- Failed (Red)
- Deferred (Gray)

#### 4.4 Devices Requiring Reboot
**Type:** Data table  
**Fields:**
- Device Name
- `patchRebootPending`
- `updDaysSinceLastReboot`
- `patchLastAttemptDate`
- `patchLastPatchCount`

**Filter:** `patchRebootPending = True`  
**Sort:** By `updDaysSinceLastReboot` descending  
**Alert:** Highlight if days > 7

#### 4.5 Patch Compliance by Device Priority
**Type:** Stacked bar chart  
**X-Axis:** Device priority (P1, P2, P3, P4)  
**Y-Axis:** Device count  
**Stacks:** `updComplianceStatus`
- Compliant (Green)
- Minor Gap (Light yellow)
- Significant Gap (Orange)
- Critical Gap (Red)

#### 4.6 Missing Updates Summary
**Type:** Number widgets row  
**Fields:**
- Critical updates: Sum of `updMissingCriticalCount`
- Important updates: Sum of `updMissingImportantCount`
- Optional updates: Sum of `updMissingOptionalCount`

**Alert:** Red if critical > 0

#### 4.7 Patch Deployment Failures
**Type:** Data table  
**Fields:**
- Device Name
- `patchLastAttemptStatus`
- `patchLastAttemptDate`
- `patchValidationNotes`
- `opsHealthScore`
- `statStabilityScore`

**Filter:** `patchLastAttemptStatus` contains "Failed"  
**Sort:** By `patchLastAttemptDate` descending (most recent first)

#### 4.8 PR1 Test Ring Health
**Type:** Scorecard  
**Fields:** Devices where `patchRing = "PR1-Test"`  
**Metrics:**
- Device count
- Average health score
- Average stability score
- Deployment success rate
- Days since last PR1 deployment

**Color:** Green if all metrics healthy

#### 4.9 Patch Age Distribution
**Type:** Histogram  
**Field:** `updPatchAgeDays`  
**Ranges:**
- 0-30 days (Current - Green)
- 31-45 days (Aging - Light yellow)
- 46-90 days (Old - Orange)
- 91+ days (Critical - Red)

### Layout Recommendation
```
+------------------+------------------+------------------+
| Patch Ring       | Patch Validation Status Grid       |
| Distribution     | (P1, P2, P3, P4 rows)              |
| (Donut)          |                                    |
+------------------+------------------------------------+
| Recent Patch Deployments Timeline (Full width)       |
+------------------------------------------------------+
| Devices Requiring Reboot (Table - spans 2 columns)  |
|                                     | PR1 Test Ring  |
|                                     | Health         |
+-------------------------------------+----------------+
| Patch Compliance by Priority (Stacked bar - 2 cols) |
|                                     | Missing Updates|
|                                     | Summary        |
+-------------------------------------+----------------+
| Patch Deployment Failures (Table - full width)      |
+------------------------------------------------------+
| Patch Age Distribution (Histogram - full width)     |
+------------------------------------------------------+
```

---

## 5. Capacity Planning Dashboard

**Purpose:** Capacity monitoring, trending, and forecasting  
**Audience:** Capacity planning team, infrastructure managers  
**Update Frequency:** Daily to weekly

### Widgets

#### 5.1 Disk Space Forecast Timeline
**Type:** Area chart with forecast line  
**Field:** `capDaysUntilDiskFull`  
**Display:** 
- Show devices grouped by forecast range
- < 30 days (Critical - Red area)
- 30-90 days (Warning - Orange area)
- 90-180 days (Attention - Yellow area)
- 180+ days (OK - Green area)

**X-Axis:** Time (next 180 days)  
**Y-Axis:** Device count

#### 5.2 Devices by Disk Space Category
**Type:** Horizontal bar chart  
**Field:** `capDiskFreePercent`  
**Categories:**
- Critical (< 5%)
- Low (5-10%)
- Warning (10-20%)
- Adequate (20-40%)
- Healthy (40%+)

**Sort:** By severity (Critical at top)

#### 5.3 Memory Utilization Trends
**Type:** Line chart  
**Field:** `capMemoryUsedPercent`  
**Display:** Show trend over last 30 days  
**Lines:**
- Average across all devices
- P90 (90th percentile)
- Maximum

**Threshold line:** 85% (warning threshold)

#### 5.4 Capacity Action Items
**Type:** Data table  
**Fields:**
- Device Name
- `capCapacityActionNeeded`
- `capDaysUntilDiskFull`
- `capDiskFreePercent`
- `capMemoryForecastRisk`
- `capCPUForecastRisk`

**Filter:** `capCapacityActionNeeded = True`  
**Sort:** By `capDaysUntilDiskFull` ascending (most urgent first)

#### 5.5 Memory Forecast Risk Matrix
**Type:** Status grid  
**Field:** `capMemoryForecastRisk`  
**Rows:** Device priority (P1, P2, P3, P4)  
**Columns:** Risk level
- Low (Green)
- Medium (Yellow)
- High (Orange)
- Critical (Red)

#### 5.6 CPU Forecast Risk Matrix
**Type:** Status grid  
**Field:** `capCPUForecastRisk`  
**Rows:** Device priority (P1, P2, P3, P4)  
**Columns:** Risk level
- Low (Green)
- Medium (Yellow)
- High (Orange)
- Critical (Red)

#### 5.7 Storage Growth Rate
**Type:** Trend chart  
**Calculation:** Change in `capDiskFreePercent` over time  
**Display:** Show top 10 devices with fastest storage consumption  
**Metrics:**
- GB per day growth rate
- Projected full date
- Current free space

#### 5.8 Network Connectivity Quality
**Type:** Status list  
**Fields:**
- Device Name
- `netWiFiDisconnects24h`
- `netVPNAverageLatencyMs`
- `capSaaSLatencyCategory`
- `netSaaSEndpointStatus`

**Filter:** Show only devices with issues  
**Alert:** Highlight poor connectivity

#### 5.9 Resource Optimization Candidates
**Type:** Data table  
**Logic:** Devices with low utilization (potential for consolidation)  
**Fields:**
- Device Name
- CPU average (< 20%)
- Memory average (< 40%)
- Disk usage (< 50%)
- `predReplacementWindow`

**Display:** Identify under-utilized resources

### Layout Recommendation
```
+------------------------------------------------------+
| Disk Space Forecast Timeline (Area chart - full)    |
+------------------+-----------------------------------+
| Disk Space       | Capacity Action Items (Table)   |
| Categories       |                                  |
| (Bar chart)      |                                  |
+------------------+------------------+---------------+
| Memory Trends    | Memory Forecast  | CPU Forecast |
| (Line chart)     | Risk (Grid)      | Risk (Grid)  |
+------------------+------------------+---------------+
| Storage Growth Rate (Trend - spans 2 columns)       |
|                                     | Network       |
|                                     | Connectivity  |
+-------------------------------------+---------------+
| Resource Optimization Candidates (Table - full)    |
+----------------------------------------------------+
```

---

## 6. Active Directory Dashboard

**Purpose:** Active Directory health and domain controller monitoring  
**Audience:** Domain administrators, identity team  
**Update Frequency:** Real-time to every 4 hours

### Widgets

#### 6.1 Domain Controller Health
**Type:** Status list  
**Fields:**
- DC Name
- `adDCReachable`
- `adDomainTrustStatus`
- `adReplicationStatus`
- `adReplicationLagMinutes`

**Alert:** Red if unreachable or replication lag > 60 minutes

#### 6.2 Domain-Joined Devices Status
**Type:** Donut chart  
**Fields:**
- `adDomainJoined = True` (Domain-joined)
- `adDomainJoined = False` (Workgroup)

**Additional Metric:** Show count where `adDCReachable = False` (cannot reach DC)

#### 6.3 GPO Application Status
**Type:** Data table  
**Fields:**
- Device Name
- `adGPOLastRefreshTime`
- `adGPOAppliedCount`
- `adGPOProcessingTime`
- `adDomainControllerName`

**Alert:** Highlight if `adGPOLastRefreshTime > 24h ago` OR `adGPOAppliedCount = 0`

#### 6.4 Domain Contact Timeline
**Type:** Line chart  
**Field:** `adLastDomainContactTime`  
**Display:** Show devices that haven't contacted DC recently  
**Ranges:**
- < 2 hours (OK)
- 2-12 hours (Warning)
- 12-24 hours (Alert)
- 24+ hours (Critical)

#### 6.5 Replication Lag (DC Only)
**Type:** Gauge chart  
**Field:** `adReplicationLagMinutes` (for domain controllers only)  
**Display:** Average and maximum replication lag  
**Ranges:**
- 0-15 min (Green)
- 15-60 min (Yellow)
- 60+ min (Red)

#### 6.6 Computer Account Status
**Type:** Status grid  
**Fields:**
- Total domain-joined devices
- Active in last 7 days
- Active in last 30 days
- Stale (> 90 days)

**Alert:** Show stale computer accounts that may need cleanup

#### 6.7 Authentication Issues
**Type:** Data table  
**Fields:**
- Device Name
- `secFailedLogonCount24h`
- `adPasswordLastSet`
- `adDomainTrustStatus`
- `adLastDomainContactTime`

**Filter:** Show devices with authentication problems

#### 6.8 Site and OU Distribution
**Type:** Tree map  
**Fields:**
- `adSiteName` (top level)
- `adComputerOU` (second level)

**Display:** Show device distribution across sites and OUs  
**Color:** Based on average health score per site/OU

#### 6.9 User Logon Activity
**Type:** Timeline chart  
**Fields:**
- `adUserLoggedOn` (current user)
- `uxLastUserActivityDate`

**Display:** Show user activity patterns over last 30 days  
**Use Case:** Identify inactive devices

### Layout Recommendation
```
+------------------+-----------------------------------+
| Domain Controller Health (Status list - 2 columns)  |
|                                                      |
+------------------+------------------+---------------+
| Domain-Joined    | GPO Application Status (Table)  |
| Devices Status   |                                  |
| (Donut)          |                                  |
+------------------+----------------------------------+
| Domain Contact Timeline (Line chart - 2 columns)    |
|                                     | Replication  |
|                                     | Lag (Gauge)  |
+-------------------------------------+--------------+
| Computer Account Status (Grid) | Authentication   |
|                                | Issues (Table)   |
+--------------------------------+------------------+
| Site and OU Distribution (Tree map - 2 columns)    |
|                                     | User Logon   |
|                                     | Activity     |
+-------------------------------------+--------------+
```

---

## Implementation Notes

### Widget Configuration Best Practices

1. **Color Consistency**
   - Green: Healthy, success, compliant
   - Yellow: Warning, needs attention
   - Orange: Significant issue, degraded
   - Red: Critical, failed, urgent
   - Gray: Unknown, not applicable

2. **Refresh Rates**
   - Real-time widgets: 1-5 minutes
   - Operational widgets: 15-30 minutes
   - Statistical widgets: 1-4 hours
   - Trend widgets: Daily

3. **Click-Through Actions**
   - Device name → Device details page
   - Alert counts → Filtered device list
   - Charts → Drill-down view
   - Status indicators → Related logs

4. **Filtering Options**
   - By device priority (P1-P4)
   - By organizational unit
   - By device type (server/workstation)
   - By location
   - By custom groups

5. **Export Capabilities**
   - All data tables exportable to CSV
   - Charts exportable as images
   - Schedule automated reports
   - Email distribution lists

### Access Control Recommendations

- **Executive Dashboard:** Read-only for all users
- **Infrastructure Dashboard:** Full access for infrastructure team
- **Security Dashboard:** Restricted to security team and management
- **Patching Dashboard:** Patch team and operations
- **Capacity Dashboard:** Capacity planning team and management
- **Active Directory Dashboard:** Domain administrators only

### Mobile Optimization

All dashboards should be responsive for tablet/mobile viewing with:
- Simplified layouts for small screens
- Touch-friendly interactions
- Key metrics prioritized at top
- Collapsible sections for detail views

---

## Customization Guide

### Adding Custom Widgets

1. Identify the custom field(s) to display
2. Choose appropriate widget type (table, chart, gauge, etc.)
3. Define filtering logic
4. Set color coding and thresholds
5. Configure refresh rate
6. Add to appropriate dashboard section

### Creating Custom Dashboards

Use these templates as starting points:
1. Copy relevant widgets from existing templates
2. Adjust fields to match your custom fields
3. Modify thresholds for your environment
4. Test with pilot user group
5. Refine based on feedback
6. Document customizations

### Dashboard Maintenance

- Review quarterly for relevance
- Update thresholds based on environment changes
- Add new widgets as fields are added
- Remove deprecated widgets
- Gather user feedback
- Optimize performance (limit data ranges, use aggregations)

---

**Total Dashboards:** 6 complete configurations  
**Total Widgets:** 50+ widget specifications  
**Status:** Production ready  
**Last Updated:** February 8, 2026
