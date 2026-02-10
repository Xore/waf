# WAF Field Quick Reference

**Purpose:** Quick lookup for all WAF custom fields  
**Total Fields:** 277+  
**Last Updated:** February 9, 2026

---

## How to Use This Reference

- **Find by Category:** Jump to section (OPS, STAT, SEC, etc.)
- **Find by Name:** Use Ctrl+F to search field name
- **Populating Script:** See which script updates each field
- **Print:** Optimized for printing (one category per page)

---

## Operations (OPS) - 15 Fields

**Purpose:** Core operational health and status

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| opsHealthScore | Integer | 0-100 | Script 1 | Overall device health score |
| opsStabilityScore | Integer | 0-100 | Script 2 | System stability score |
| opsPerformanceScore | Integer | 0-100 | Script 3 | Performance health score |
| opsSecurityScore | Integer | 0-100 | Script 4 | Security posture score |
| opsCapacityScore | Integer | 0-100 | Script 5 | Capacity health score |
| opsOverallScore | Integer | 0-100 | Script 1 | Weighted overall score |
| opsLastHealthCheck | Date/Time | Unix Epoch | Script 1 | Last health check timestamp |
| opsUptime | Integer | Seconds | Script 7 | Device uptime in seconds |
| opsUptimeDays | Integer | Days | Script 7 | Device uptime in days |
| opsLastBootTime | Date/Time | Unix Epoch | Script 7 | Last boot timestamp |
| opsDeviceAge | Integer | Seconds | Script 9 | Device age since first boot |
| opsDeviceAgeMonths | Integer | Months | Script 9 | Device age in months |
| opsMonitoringEnabled | Checkbox | true/false | Script 13 | WAF monitoring active |
| opsStatus | Dropdown | See values | Script 1 | Overall status classification |
| opsNotes | Text | Free text | Manual | Administrative notes |

**opsStatus Values:** Healthy, Warning, Critical, Unknown

---

## Statistics (STAT) - 10 Fields

**Purpose:** Event and error tracking statistics

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| statCrashCount30d | Integer | 0+ | Script 2 | Application crashes (30 days) |
| statErrorCount30d | Integer | 0+ | Script 8 | Error events (30 days) |
| statWarningCount30d | Integer | 0+ | Script 8 | Warning events (30 days) |
| statRebootCount30d | Integer | 0+ | Script 2 | System reboots (30 days) |
| statStabilityScore | Integer | 0-100 | Script 2 | Calculated stability score |
| statAvgCPUUsage | Integer | 0-100 | Script 3 | Average CPU usage % |
| statAvgMemoryUsage | Integer | 0-100 | Script 3 | Average memory usage % |
| statAvgDiskUsage | Integer | 0-100 | Script 3 | Average disk usage % |
| statLastCrashDate | Date/Time | Unix Epoch | Script 2 | Last crash timestamp |
| statUpgradeAvailable | Checkbox | true/false | Script 6 | OS upgrade available |

---

## Security (SEC) - 10 Fields

**Purpose:** Security posture and compliance

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| secAntivirusEnabled | Checkbox | true/false | Script 4 | Antivirus active |
| secAntivirusProduct | Text | Product name | Script 4 | AV product name |
| secAntivirusUpdated | Checkbox | true/false | Script 4 | AV definitions current |
| secFirewallEnabled | Checkbox | true/false | Script 4 | Windows Firewall active |
| secBitLockerEnabled | Checkbox | true/false | Script 4 | BitLocker encryption on |
| secSecureBootEnabled | Checkbox | true/false | Script 4 | Secure Boot enabled |
| secTPMEnabled | Checkbox | true/false | Script 4 | TPM chip enabled |
| secLastSecurityScan | Date/Time | Unix Epoch | Script 4 | Last security scan |
| secVulnerabilityCount | Integer | 0+ | Script 4 | Known vulnerabilities |
| secComplianceStatus | Dropdown | See values | Script 4 | Compliance classification |

**secComplianceStatus Values:** Compliant, Non-Compliant, Partial, Unknown

---

## Capacity (CAP) - 10 Fields

**Purpose:** Resource capacity and usage

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| capDiskFreeGB | Integer | GB | Script 5 | Free disk space (C:) |
| capDiskFreePercent | Integer | 0-100 | Script 5 | Free disk percentage |
| capDiskTotalGB | Integer | GB | Script 5 | Total disk size (C:) |
| capMemoryTotalGB | Integer | GB | Script 5 | Total RAM installed |
| capMemoryUsedGB | Integer | GB | Script 5 | Current RAM usage |
| capMemoryUsedPercent | Integer | 0-100 | Script 5 | Memory usage percentage |
| capCPUCores | Integer | 1+ | Script 5 | CPU core count |
| capCPUThreads | Integer | 1+ | Script 5 | CPU thread count |
| capWarningLevel | Dropdown | See values | Script 5 | Capacity warning level |
| capForecastDaysFull | Integer | Days | Script 5 | Days until disk full |

**capWarningLevel Values:** Normal, Warning, Critical

---

## Updates (UPD) - 5 Fields

**Purpose:** Windows Update compliance

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| updComplianceStatus | Dropdown | See values | Script 6 | Update compliance status |
| updMissingCriticalCount | Integer | 0+ | Script 6 | Missing critical updates |
| updMissingImportantCount | Integer | 0+ | Script 6 | Missing important updates |
| updLastPatchDate | Date/Time | Unix Epoch | Script 6 | Last update installed |
| updLastPatchCheck | Date/Time | Unix Epoch | Script 6 | Last update check |

**updComplianceStatus Values:** Compliant, Partial, Non-Compliant, Unknown

---

## Risk (RISK) - 15 Fields

**Purpose:** Risk classification and management

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| riskOverallScore | Integer | 0-100 | Script 14 | Overall risk score |
| riskSecurityLevel | Dropdown | See values | Script 14 | Security risk level |
| riskStabilityLevel | Dropdown | See values | Script 14 | Stability risk level |
| riskCapacityLevel | Dropdown | See values | Script 14 | Capacity risk level |
| riskComplianceLevel | Dropdown | See values | Script 14 | Compliance risk level |
| riskBusinessImpact | Dropdown | See values | Manual/Script | Business impact rating |
| riskCriticality | Dropdown | See values | Manual/Script | Device criticality |
| riskLastAssessment | Date/Time | Unix Epoch | Script 14 | Last risk assessment |
| riskMitigationPlan | Text | Free text | Manual | Mitigation plan |
| riskOwner | Text | Username | Manual | Risk owner |
| riskAcceptedBy | Text | Username | Manual | Risk acceptance authority |
| riskAcceptedDate | Date/Time | Unix Epoch | Manual | Risk acceptance date |
| riskReviewDue | Date/Time | Unix Epoch | Manual | Next review due |
| riskExceptions | Text | Base64 JSON | Manual | Approved exceptions |
| riskNotes | Text | Free text | Manual | Risk management notes |

**Risk Level Values:** Low, Medium, High, Critical  
**Business Impact Values:** Minimal, Low, Medium, High, Critical  
**Criticality Values:** Non-Critical, Low, Medium, High, Mission-Critical

---

## Configuration Drift (DRIFT) - 10 Fields

**Purpose:** Configuration change detection

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| driftScore | Integer | 0-100 | Script 15 | Configuration drift score |
| driftDetected | Checkbox | true/false | Script 15 | Drift currently detected |
| driftLastDetection | Date/Time | Unix Epoch | Script 15 | Last drift detection |
| driftChangedItems | Integer | 0+ | Script 15 | Number of changed items |
| driftSeverity | Dropdown | See values | Script 15 | Drift severity |
| driftBaseline | Date/Time | Unix Epoch | Script 12 | Baseline date |
| driftApproved | Checkbox | true/false | Manual | Drift approved |
| driftDetails | Text | Base64 JSON | Script 15 | Detailed drift info |
| driftRemediationStatus | Dropdown | See values | Manual | Remediation status |
| driftLastRemediation | Date/Time | Unix Epoch | Manual | Last remediation |

**Drift Severity:** Minimal, Low, Medium, High, Critical  
**Remediation Status:** Not Started, In Progress, Completed, Failed, Approved

---

## User Experience (UX) - 15 Fields

**Purpose:** End-user experience monitoring

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| uxScore | Integer | 0-100 | Script 16 | User experience score |
| uxBootTime | Integer | Seconds | Script 16 | Boot time duration |
| uxLoginTime | Integer | Seconds | Script 16 | Login time duration |
| uxAppLaunchTime | Integer | Seconds | Script 16 | Avg app launch time |
| uxResponsiveness | Integer | 0-100 | Script 16 | Responsiveness score |
| uxFreezeCount30d | Integer | 0+ | Script 16 | UI freezes (30 days) |
| uxSlownessCount30d | Integer | 0+ | Script 16 | Slowness events |
| uxLastUserComplaint | Date/Time | Unix Epoch | Manual | Last complaint logged |
| uxSatisfactionScore | Integer | 1-5 | Manual | User satisfaction |
| uxPrimaryUser | Text | Username | Script 9 | Primary user |
| uxActiveHoursStart | Integer | 0-23 | Manual/Script | Active hours start |
| uxActiveHoursEnd | Integer | 0-23 | Manual/Script | Active hours end |
| uxUsagePattern | Dropdown | See values | Script 16 | Usage classification |
| uxPerformanceImpact | Dropdown | See values | Script 16 | Performance impact |
| uxNotes | Text | Free text | Manual | UX notes |

**Usage Pattern:** Light, Moderate, Heavy, Power User, Unknown  
**Performance Impact:** None, Minimal, Noticeable, Significant, Severe

---

## Network (NET) - 10 Fields

**Purpose:** Network connectivity monitoring

| Field Name | Type | Range | Populated By | Description |
|------------|------|-------|--------------|-------------|
| netConnectivityScore | Integer | 0-100 | Script 11 | Connectivity health |
| netPrimaryInterface | Text | Interface | Script 11 | Primary NIC name |
| netIPAddress | Text | IP | Script 11 | Current IP address |
| netDNSServers | Text | IPs | Script 11 | DNS servers (comma-sep) |
| netGateway | Text | IP | Script 11 | Default gateway |
| netLatency | Integer | Milliseconds | Script 11 | Gateway latency |
| netBandwidthUp | Integer | Mbps | Script 11 | Upload bandwidth |
| netBandwidthDown | Integer | Mbps | Script 11 | Download bandwidth |
| netDisconnectCount30d | Integer | 0+ | Script 11 | Disconnections (30d) |
| netLastDisconnect | Date/Time | Unix Epoch | Script 11 | Last disconnect |

---

## Quick Field Lookup by Script

### Script 1: Health Score Calculator
- opsHealthScore, opsOverallScore, opsLastHealthCheck, opsStatus

### Script 2: System Stability Monitor
- opsStabilityScore, statCrashCount30d, statRebootCount30d, statStabilityScore, statLastCrashDate

### Script 3: Performance Metrics Collector
- opsPerformanceScore, statAvgCPUUsage, statAvgMemoryUsage, statAvgDiskUsage

### Script 4: Security Posture Scanner
- opsSecurityScore, secAntivirusEnabled, secAntivirusProduct, secAntivirusUpdated, secFirewallEnabled, secBitLockerEnabled, secSecureBootEnabled, secTPMEnabled, secLastSecurityScan, secVulnerabilityCount, secComplianceStatus

### Script 5: Capacity Monitor
- opsCapacityScore, capDiskFreeGB, capDiskFreePercent, capDiskTotalGB, capMemoryTotalGB, capMemoryUsedGB, capMemoryUsedPercent, capCPUCores, capCPUThreads, capWarningLevel, capForecastDaysFull

### Script 6: Update Compliance Checker
- updComplianceStatus, updMissingCriticalCount, updMissingImportantCount, updLastPatchDate, updLastPatchCheck, statUpgradeAvailable

### Script 7: Uptime Tracker
- opsUptime, opsUptimeDays, opsLastBootTime

### Script 8: Error Event Monitor
- statErrorCount30d, statWarningCount30d

### Script 9: Device Information Collector
- opsDeviceAge, opsDeviceAgeMonths, uxPrimaryUser

### Script 11: Network Monitor
- netConnectivityScore, netPrimaryInterface, netIPAddress, netDNSServers, netGateway, netLatency, netBandwidthUp, netBandwidthDown, netDisconnectCount30d, netLastDisconnect

### Script 12: Baseline Manager
- driftBaseline

### Script 13: Configuration Manager
- opsMonitoringEnabled

---

## Field Value Interpretation

### Health Scores (0-100)
- **90-100:** Excellent - No action needed
- **75-89:** Good - Monitor periodically
- **60-74:** Fair - Review and plan improvements
- **40-59:** Poor - Action required soon
- **0-39:** Critical - Immediate attention required

### Percentages (Capacity)
- **0-70%:** Normal range
- **71-85%:** Warning - Plan expansion
- **86-95%:** Critical - Urgent action
- **96-100%:** Emergency - Immediate action

### Event Counts (30 days)
- **0:** Perfect
- **1-5:** Acceptable
- **6-20:** Concerning - Investigate
- **21+:** Critical - Immediate action

---

**Print Tip:** Print this document for desk reference  
**Digital Tip:** Bookmark in browser for quick access  
**Mobile Tip:** Save offline for field work

**Last Updated:** February 9, 2026, 1:17 AM CET
