# Task 2.1: Extended Custom Fields Creation Guide

**Task:** Create 150+ Extended Custom Fields  
**Phase:** 7.2 - Extended Monitoring  
**Priority:** P2  
**Status:** 🚧 IN PROGRESS (Planning)  
**Started:** February 9, 2026, 1:11 AM CET  
**Estimated Time:** 4-5 hours

---

## Overview

This guide provides complete specifications for creating 150+ extended custom fields required for Phase 7.2. These fields enable advanced monitoring, drift detection, user experience tracking, predictive analytics, and automation control.

---

## Prerequisites

- [ ] Task 1.1 complete (50 core fields created)
- [ ] Task 1.4 validation passed (Phase 7.1 successful)
- [ ] NinjaRMM admin access
- [ ] Core monitoring established and stable

---

## Extended Fields Overview

### Field Categories (150+ fields total)

1. **RISK** - Risk Classification (15 fields)
2. **DRIFT** - Configuration Drift (10 fields)
3. **UX** - User Experience (15 fields)
4. **NET** - Network Monitoring (10 fields)
5. **BKP** - Backup Validation (10 fields)
6. **APP** - Application Monitoring (15 fields)
7. **PRED** - Predictive Analytics (10 fields)
8. **AUTO** - Automation Control (8 fields)
9. **Additional OPS** - Extended Operations (67+ fields)

---

## Category 1: RISK - Risk Classification (15 fields)

### Purpose
Classify devices by risk level based on multiple factors for prioritization.

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 51 | riskOverallScore | Integer | 0-100 | Overall risk score (higher = more risk) |
| 52 | riskSecurityLevel | Dropdown | See values | Security risk classification |
| 53 | riskStabilityLevel | Dropdown | See values | Stability risk classification |
| 54 | riskCapacityLevel | Dropdown | See values | Capacity risk classification |
| 55 | riskComplianceLevel | Dropdown | See values | Compliance risk classification |
| 56 | riskBusinessImpact | Dropdown | See values | Business impact if device fails |
| 57 | riskCriticality | Dropdown | See values | Overall device criticality |
| 58 | riskLastAssessment | Date/Time | Unix Epoch | Last risk assessment timestamp |
| 59 | riskMitigationPlan | Text | Free text | Risk mitigation actions planned |
| 60 | riskOwner | Text | Username | Person responsible for risk management |
| 61 | riskAcceptedBy | Text | Username | Who accepted current risk level |
| 62 | riskAcceptedDate | Date/Time | Unix Epoch | When risk was accepted |
| 63 | riskReviewDue | Date/Time | Unix Epoch | Next risk review due date |
| 64 | riskExceptions | Text | Base64 JSON | List of approved risk exceptions |
| 65 | riskNotes | Text | Free text | Additional risk management notes |

**Dropdown Values:**

**riskSecurityLevel, riskStabilityLevel, riskCapacityLevel, riskComplianceLevel:**
- Low
- Medium
- High
- Critical

**riskBusinessImpact:**
- Minimal
- Low
- Medium
- High
- Critical

**riskCriticality:**
- Non-Critical
- Low
- Medium
- High
- Mission-Critical

---

## Category 2: DRIFT - Configuration Drift (10 fields)

### Purpose
Detect and track configuration changes from established baselines.

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 66 | driftScore | Integer | 0-100 | Configuration drift score (higher = more drift) |
| 67 | driftDetected | Checkbox | true/false | Whether drift currently detected |
| 68 | driftLastDetection | Date/Time | Unix Epoch | Last drift detection timestamp |
| 69 | driftChangedItems | Integer | 0+ | Number of changed configuration items |
| 70 | driftSeverity | Dropdown | See values | Drift severity classification |
| 71 | driftBaseline | Date/Time | Unix Epoch | Baseline configuration date |
| 72 | driftApproved | Checkbox | true/false | Whether drift is approved/expected |
| 73 | driftDetails | Text | Base64 JSON | Detailed drift information |
| 74 | driftRemediationStatus | Dropdown | See values | Current remediation status |
| 75 | driftLastRemediation | Date/Time | Unix Epoch | Last remediation attempt |

**Dropdown Values:**

**driftSeverity:**
- Minimal
- Low
- Medium
- High
- Critical

**driftRemediationStatus:**
- Not Started
- In Progress
- Completed
- Failed
- Approved (No Action)

---

## Category 3: UX - User Experience (15 fields)

### Purpose
Monitor end-user experience metrics and satisfaction.

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 76 | uxScore | Integer | 0-100 | Overall user experience score |
| 77 | uxBootTime | Integer | Seconds | Time to boot to login prompt |
| 78 | uxLoginTime | Integer | Seconds | Time from login to desktop ready |
| 79 | uxAppLaunchTime | Integer | Seconds | Average application launch time |
| 80 | uxResponsiveness | Integer | 0-100 | System responsiveness score |
| 81 | uxFreeze Count30d | Integer | 0+ | Number of UI freezes in last 30 days |
| 82 | uxSlowness Count30d | Integer | 0+ | Number of slowness reports in 30 days |
| 83 | uxLastUserComplaint | Date/Time | Unix Epoch | Last user-reported issue |
| 84 | uxSatisfactionScore | Integer | 1-5 | User satisfaction rating (if surveyed) |
| 85 | uxPrimaryUser | Text | Username | Primary user of this device |
| 86 | uxActiveHoursStart | Integer | 0-23 | Active hours start time (hour) |
| 87 | uxActiveHoursEnd | Integer | 0-23 | Active hours end time (hour) |
| 88 | uxUsagePattern | Dropdown | See values | Usage pattern classification |
| 89 | uxPerformanceImpact | Dropdown | See values | Performance impact on user |
| 90 | uxNotes | Text | Free text | User experience notes |

**Dropdown Values:**

**uxUsagePattern:**
- Light
- Moderate
- Heavy
- Power User
- Unknown

**uxPerformanceImpact:**
- None
- Minimal
- Noticeable
- Significant
- Severe

---

## Category 4: NET - Network Monitoring (10 fields)

### Purpose
Monitor network connectivity, performance, and issues.

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 91 | netConnectivityScore | Integer | 0-100 | Network connectivity health score |
| 92 | netPrimaryInterface | Text | Interface name | Primary network interface |
| 93 | netIPAddress | Text | IP address | Current IP address |
| 94 | netDNSServers | Text | Comma-separated | DNS server addresses |
| 95 | netGateway | Text | IP address | Default gateway |
| 96 | netLatency | Integer | Milliseconds | Network latency to gateway |
| 97 | netBandwidthUp | Integer | Mbps | Upload bandwidth |
| 98 | netBandwidthDown | Integer | Mbps | Download bandwidth |
| 99 | netDisconnectCount30d | Integer | 0+ | Network disconnections in 30 days |
| 100 | netLastDisconnect | Date/Time | Unix Epoch | Last network disconnection |

---

## Category 5: BKP - Backup Validation (10 fields)

### Purpose
Validate backup status and recoverability.

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 101 | bkpStatus | Dropdown | See values | Overall backup status |
| 102 | bkpLastSuccess | Date/Time | Unix Epoch | Last successful backup |
| 103 | bkpLastAttempt | Date/Time | Unix Epoch | Last backup attempt |
| 104 | bkpConsecutiveFailures | Integer | 0+ | Consecutive failed backups |
| 105 | bkpSolution | Text | Product name | Backup solution in use |
| 106 | bkpSizeGB | Integer | GB | Last backup size |
| 107 | bkpRetentionDays | Integer | Days | Backup retention period |
| 108 | bkpRecoveryTested | Checkbox | true/false | Whether recovery tested |
| 109 | bkpLastRecoveryTest | Date/Time | Unix Epoch | Last recovery test date |
| 110 | bkpNotes | Text | Free text | Backup notes |

**Dropdown Values:**

**bkpStatus:**
- Healthy
- Warning
- Failed
- Not Configured
- Unknown

---

## Category 6: APP - Application Monitoring (15 fields)

### Purpose
Monitor critical application health and performance.

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 111 | appHealthScore | Integer | 0-100 | Overall application health score |
| 112 | appCriticalCount | Integer | 0+ | Number of critical apps installed |
| 113 | appRunningCount | Integer | 0+ | Number of apps currently running |
| 114 | appCrashCount30d | Integer | 0+ | Application crashes in 30 days |
| 115 | appHangCount30d | Integer | 0+ | Application hangs in 30 days |
| 116 | appInventory | Text | Base64 JSON | Installed applications list |
| 117 | appCriticalList | Text | Base64 JSON | Critical applications list |
| 118 | appOutdatedCount | Integer | 0+ | Number of outdated applications |
| 119 | appUnauthorizedCount | Integer | 0+ | Number of unauthorized apps |
| 120 | appLicenseStatus | Dropdown | See values | Overall license compliance |
| 121 | appLastInventory | Date/Time | Unix Epoch | Last app inventory date |
| 122 | appProhibitedDetected | Checkbox | true/false | Prohibited software detected |
| 123 | appProhibitedList | Text | Base64 JSON | List of prohibited apps found |
| 124 | appUpdatesPending | Integer | 0+ | Application updates pending |
| 125 | appNotes | Text | Free text | Application notes |

**Dropdown Values:**

**appLicenseStatus:**
- Compliant
- Non-Compliant
- Partial
- Unknown

---

## Category 7: PRED - Predictive Analytics (10 fields)

### Purpose
Predict future issues and maintenance needs.

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 126 | predFailureRisk | Integer | 0-100 | Predicted failure risk score |
| 127 | predDaysToFailure | Integer | Days | Estimated days until failure |
| 128 | predDaysToDiskFull | Integer | Days | Days until disk full (forecast) |
| 129 | predDaysToMemoryIssue | Integer | Days | Days until memory issues |
| 130 | predReplacementDue | Date/Time | Unix Epoch | Recommended replacement date |
| 131 | predMaintenanceDue | Date/Time | Unix Epoch | Next maintenance due |
| 132 | predLifetimeRemaining | Integer | Months | Estimated device lifetime remaining |
| 133 | predConfidence | Integer | 0-100 | Prediction confidence level |
| 134 | predLastCalculation | Date/Time | Unix Epoch | Last prediction calculation |
| 135 | predNotes | Text | Free text | Prediction notes |

---

## Category 8: AUTO - Automation Control (8 fields)

### Purpose
Control automated actions and remediation.

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 136 | autoRemediationEnabled | Checkbox | true/false | Whether auto-remediation is enabled |
| 137 | autoMaintenanceWindow | Text | Time range | Allowed maintenance window |
| 138 | autoRebootAllowed | Checkbox | true/false | Whether auto-reboot is allowed |
| 139 | autoLastRemediation | Date/Time | Unix Epoch | Last auto-remediation timestamp |
| 140 | autoRemediationCount30d | Integer | 0+ | Auto-remediations in 30 days |
| 141 | autoExclusions | Text | Base64 JSON | List of automation exclusions |
| 142 | autoApprovalRequired | Checkbox | true/false | Whether actions need approval |
| 143 | autoNotes | Text | Free text | Automation control notes |

---

## Category 9: Additional OPS - Extended Operations (67+ fields)

### Subcategory: Advanced Health Metrics (20 fields)

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 144 | opsReliabilityScore | Integer | 0-100 | Device reliability score |
| 145 | opsMaintenanceScore | Integer | 0-100 | Maintenance compliance score |
| 146 | opsConfigScore | Integer | 0-100 | Configuration health score |
| 147 | opsComplexityScore | Integer | 0-100 | Environment complexity score |
| 148 | opsDependencyCount | Integer | 0+ | Number of service dependencies |
| 149 | opsServiceCount | Integer | 0+ | Number of Windows services |
| 150 | opsProcessCount | Integer | 0+ | Current process count |
| 151 | opsThreadCount | Integer | 0+ | Current thread count |
| 152 | opsHandleCount | Integer | 0+ | Current handle count |
| 153 | opsPageFileUsageMB | Integer | MB | Page file usage |
| 154 | opsPageFileSizeMB | Integer | MB | Page file size |
| 155 | opsKernelMemoryMB | Integer | MB | Kernel memory usage |
| 156 | opsCommitChargeMB | Integer | MB | Committed memory |
| 157 | opsSystemUptime | Integer | Seconds | OS uptime (vs device uptime) |
| 158 | opsLastMaintenance | Date/Time | Unix Epoch | Last maintenance performed |
| 159 | opsNextMaintenance | Date/Time | Unix Epoch | Next scheduled maintenance |
| 160 | opsMaintenanceWindow | Text | Time range | Allowed maintenance window |
| 161 | opsChangeControlRequired | Checkbox | true/false | Whether changes need approval |
| 162 | opsBackoutPlan | Text | Free text | Backout plan for changes |
| 163 | opsEscalationContact | Text | Email/phone | Escalation contact info |

### Subcategory: Extended Statistics (15 fields)

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 164 | statBSODCount30d | Integer | 0+ | Blue screens in 30 days |
| 165 | statBSODLastDate | Date/Time | Unix Epoch | Last BSOD date |
| 166 | statBSODDetails | Text | Base64 JSON | BSOD error codes/details |
| 167 | statServiceFailCount30d | Integer | 0+ | Service failures in 30 days |
| 168 | statLoginFailCount30d | Integer | 0+ | Failed logins in 30 days |
| 169 | statDiskErrorCount30d | Integer | 0+ | Disk errors in 30 days |
| 170 | statMemoryErrorCount30d | Integer | 0+ | Memory errors in 30 days |
| 171 | statNetworkErrorCount30d | Integer | 0+ | Network errors in 30 days |
| 172 | statPowerEventCount30d | Integer | 0+ | Power events in 30 days |
| 173 | statHardwareChangeCount30d | Integer | 0+ | Hardware changes in 30 days |
| 174 | statDriverIssueCount30d | Integer | 0+ | Driver issues in 30 days |
| 175 | statAuditFailCount30d | Integer | 0+ | Audit failures in 30 days |
| 176 | statSecurityEventCount30d | Integer | 0+ | Security events in 30 days |
| 177 | statPeakCPUUsage | Integer | 0-100 | Peak CPU usage recorded |
| 178 | statPeakMemoryUsage | Integer | 0-100 | Peak memory usage recorded |

### Subcategory: Extended Security (12 fields)

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 179 | secWindowsDefenderStatus | Dropdown | See values | Windows Defender status |
| 180 | secSmartScreenEnabled | Checkbox | true/false | SmartScreen enabled |
| 181 | secUACEnabled | Checkbox | true/false | UAC enabled |
| 182 | secLastVirusScan | Date/Time | Unix Epoch | Last virus scan date |
| 183 | secThreatsDetected30d | Integer | 0+ | Threats detected in 30 days |
| 184 | secThreatsQuarantined30d | Integer | 0+ | Threats quarantined in 30 days |
| 185 | secEncryptionMethod | Text | Method name | Disk encryption method |
| 186 | secEncryptionStatus | Dropdown | See values | Encryption status |
| 187 | secPasswordAge | Integer | Days | Local admin password age |
| 188 | secPasswordExpiry | Date/Time | Unix Epoch | Password expiry date |
| 189 | secLastSecurityUpdate | Date/Time | Unix Epoch | Last security update date |
| 190 | secCertificateExpiry | Date/Time | Unix Epoch | Nearest cert expiry |

**Dropdown Values:**

**secWindowsDefenderStatus:**
- Active
- Disabled
- Not Installed
- Unknown

**secEncryptionStatus:**
- Fully Encrypted
- Encryption in Progress
- Partially Encrypted
- Not Encrypted
- Unknown

### Subcategory: Extended Capacity (10 fields)

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 191 | capAllDisksFreeGB | Integer | GB | Total free space all disks |
| 192 | capAllDisksTotalGB | Integer | GB | Total size all disks |
| 193 | capSSDCount | Integer | 0+ | Number of SSDs |
| 194 | capHDDCount | Integer | 0+ | Number of HDDs |
| 195 | capDiskHealth | Dropdown | See values | Overall disk health |
| 196 | capSMARTStatus | Dropdown | See values | SMART status |
| 197 | capGrowthRateGBPerDay | Integer | GB/day | Disk usage growth rate |
| 198 | capMemorySpeed | Integer | MHz | Memory speed |
| 199 | capCPUSpeedGHz | Integer | GHz | CPU speed |
| 200 | capGPUPresent | Checkbox | true/false | Dedicated GPU present |

**Dropdown Values:**

**capDiskHealth, capSMARTStatus:**
- Healthy
- Warning
- Critical
- Failed
- Unknown

### Subcategory: Extended Updates (10 fields)

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 201 | updRebootPending | Checkbox | true/false | Reboot pending for updates |
| 202 | updRebootRequired | Checkbox | true/false | Reboot required |
| 203 | updLastRebootDate | Date/Time | Unix Epoch | Last reboot date |
| 204 | updDaysSinceLastReboot | Integer | Days | Days since last reboot |
| 205 | updWindowsUpdateEnabled | Checkbox | true/false | Windows Update enabled |
| 206 | updWSUSServer | Text | Server name | WSUS server if configured |
| 207 | updFeatureUpdatePending | Checkbox | true/false | Feature update available |
| 208 | updFeatureUpdateVersion | Text | Version | Available feature update |
| 209 | updCurrentBuild | Text | Build number | Current Windows build |
| 210 | updTargetBuild | Text | Build number | Target Windows build |

---

## Field Creation Sequence

### Priority Order

**Priority 1 - Critical (Day 1):**
- RISK fields (15 fields)
- DRIFT fields (10 fields)
- AUTO fields (8 fields)

**Priority 2 - High (Day 2):**
- UX fields (15 fields)
- PRED fields (10 fields)
- Extended OPS health (20 fields)

**Priority 3 - Medium (Day 3):**
- NET fields (10 fields)
- BKP fields (10 fields)
- APP fields (15 fields)
- Extended statistics (15 fields)

**Priority 4 - Low (Day 4):**
- Extended security (12 fields)
- Extended capacity (10 fields)
- Extended updates (10 fields)

---

## Validation Checklist

After creating all 150+ extended fields:

- [ ] All 15 RISK fields created
- [ ] All 10 DRIFT fields created
- [ ] All 15 UX fields created
- [ ] All 10 NET fields created
- [ ] All 10 BKP fields created
- [ ] All 15 APP fields created
- [ ] All 10 PRED fields created
- [ ] All 8 AUTO fields created
- [ ] All 67 additional OPS fields created
- [ ] Field names match exactly
- [ ] Field types correct
- [ ] Dropdown values configured
- [ ] Total field count: 200+ (50 core + 150+ extended)

---

## Expected Outcomes

Once extended fields are created:

1. **Advanced monitoring** - Risk, drift, UX tracking enabled
2. **Predictive capabilities** - Forecasting and analytics possible
3. **Automation control** - Fine-grained remediation control
4. **Comprehensive visibility** - 200+ data points per device
5. **Advanced dashboards** - Rich dashboard capabilities

---

## Next Steps

After completing Task 2.1:

1. **Task 2.2** - Deploy 23 extended automation scripts
2. **Task 2.3** - Expand pilot to 25-50 devices
3. **Task 2.4** - Create first 3 dashboards

---

**Task Status:** 🚧 IN PROGRESS (Planning)  
**Prerequisites:** Phase 7.1 validation passed  
**Estimated Time:** 4-5 hours for field creation  
**Total Fields:** 150+ (Fields #51-210+)
