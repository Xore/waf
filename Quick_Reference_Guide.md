# NinjaOne Custom Field Framework - Quick Reference Guide

**Version:** 1.0  
**Last Updated:** February 1, 2026, 9:19 PM CET  
**Purpose:** Day-to-day operations reference

---

## Quick Access Cheat Sheet

### Field Prefix Quick Reference

| Prefix | Meaning | Count | Priority | Example Field |
|--------|---------|-------|----------|---------------|
| OPS | Operations | 6 | Essential | OPSHealthScore |
| STAT | Statistics | 15 | Essential | STATAppCrashes24h |
| RISK | Risk | 7 | Essential | RISKSecurityExposure |
| AUTO | Automation | 8 | Essential | AUTORemediationEligible |
| UX | User Experience | 8 | Essential | UXUserSatisfactionScore |
| SRV | Server | 5 | Essential | SRVRole |
| DRIFT | Drift | 9 | Essential | DRIFTActiveChanges |
| CAP | Capacity | 6 | Essential | CAPDaysUntilDiskFull |
| BAT | Battery | 3 | Essential | BATHealthPercent |
| NET | Network | 8 | Essential | NETLocationCurrent |
| GPO | Group Policy | 4 | Essential | GPOLastApplyTimeSec |
| AD | Active Directory | 3 | Essential | ADLastLogonDays |
| BASE | Baseline | 7 | Essential | BASEBusinessCriticality |
| SEC | Security | 5 | Essential | SECSecurityPosture |
| UPD | Updates | 4 | Essential | UPDMissingCriticalCount |
| PATCH | Patching | 8 | Critical | PATCHRing |

---

## Field-to-Script Mapping: What Gets Collected and How

### Native NinjaOne Metrics (No Script Required)

These metrics are collected automatically by NinjaOne agent - **NO custom fields or scripts needed:**

| Metric | Source | Update Frequency | Used For |
|--------|--------|------------------|----------|
| CPU Utilization (%) | Native Hardware Monitor | Real-time (1-min avg) | Hybrid conditions, performance alerts |
| Memory Utilization (%) | Native Hardware Monitor | Real-time | Hybrid conditions, capacity planning |
| Disk Free Space (GB/%) | Native Disk Monitor | Real-time (per drive) | Hybrid conditions, capacity alerts |
| Disk Active Time (%) | Native Disk Monitor | Real-time | IO performance monitoring |
| Network Bandwidth | Native Network Monitor | Real-time | Connectivity quality |
| Device Online/Offline | Native Connectivity | Instant | Availability monitoring |
| SMART Status | Native Disk Health | Every 4 hours | Drive failure prediction |
| Pending Reboot | Native OS Detection | Real-time | Maintenance scheduling |
| Antivirus Status | Native Security Monitor | Every 15 minutes | Security posture |
| Firewall Status | Native Security Monitor | Every 15 minutes | Security posture |
| Patch Status | Native Windows Update | Every 4 hours | Compliance tracking |
| Backup Status | Native Backup Integration | Per backup job | Data protection monitoring |

**Framework Integration:** Hybrid compound conditions combine these native metrics with custom intelligence fields for context-aware alerting.

---

### Core Custom Fields: OPS, STAT, RISK (Populated by Scripts 1-9)

#### Script 1: Health Score Calculator
**Frequency:** Every 4 hours  
**Runtime:** ~30 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| OPSHealthScore | Integer (0-100) | Composite health score (CPU, Memory, Disk, Stability, Security) |
| OPSLastScoreUpdate | DateTime | Last calculation timestamp |

**Data Sources:** Queries native CPU, Memory, Disk metrics + custom STAT fields

---

#### Script 2: Stability Analyzer
**Frequency:** Every 4 hours  
**Runtime:** ~35 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| OPSStabilityScore | Integer (0-100) | System stability composite score |

**Data Sources:** Windows Event Log (native) + crash/hang counters

---

#### Script 3: Performance Analyzer
**Frequency:** Every 4 hours  
**Runtime:** ~30 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| OPSPerformanceScore | Integer (0-100) | System performance composite score |

**Data Sources:** Native CPU, Memory, Disk Active Time metrics

---

#### Script 4: Security Analyzer
**Frequency:** Daily  
**Runtime:** ~35 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| OPSSecurityScore | Integer (0-100) | Security posture composite score |

**Data Sources:** Native AV, Firewall, Patch Status + custom SEC fields

---

#### Script 5: Capacity Analyzer
**Frequency:** Daily  
**Runtime:** ~40 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| OPSCapacityScore | Integer (0-100) | Capacity headroom assessment |

**Data Sources:** Native Disk Free Space, Memory Usage + predictive CAP fields

---

#### Script 6: Telemetry Collector - Crashes & Hangs
**Frequency:** Every 4 hours  
**Runtime:** ~25 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| STATAppCrashes24h | Integer | Application crashes (24-hour window) |
| STATAppHangs24h | Integer | Application hangs (24-hour window) |
| STATServiceFailures24h | Integer | Service failures (24-hour window) |
| STATBSODCount30d | Integer | Blue Screen of Death events (30 days) |

**Data Sources:** Windows Event Log (Application, System logs)

---

#### Script 7: Telemetry Collector - Uptime & Boot
**Frequency:** Every 4 hours  
**Runtime:** ~20 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| STATUptimeDays | Float | Days since last reboot |
| STATLastBootTime | DateTime | Last boot timestamp |
| STATBootTimeSec | Integer | Boot time in seconds |

**Data Sources:** WMI (Win32_OperatingSystem)

---

#### Script 8: Telemetry Collector - Resource Usage
**Frequency:** Every 4 hours  
**Runtime:** ~25 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| STATCPUAveragePercent | Float | CPU average (4-hour window) |
| STATMemoryUsedPercent | Float | Memory utilization percentage |
| STATDiskFreePercent | Float | Lowest disk free space percentage |
| STATDiskActivePercent | Float | Disk active time percentage |
| STATLastTelemetryUpdate | DateTime | Last collection timestamp |

**Data Sources:** Performance Counters (Processor, Memory, LogicalDisk)

**Note:** These fields provide historical/averaged data. Use native metrics for real-time alerting.

---

#### Script 9: Risk Classifier
**Frequency:** Daily  
**Runtime:** ~30 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| RISKHealthLevel | Dropdown | Healthy / Degraded / Critical / Unknown |
| RISKRebootLevel | Dropdown | None / Low / Medium / High / Critical |
| RISKSecurityExposure | Dropdown | Low / Medium / High / Critical |
| RISKComplianceFlag | Checkbox | Compliance issue detected |
| RISKShadowIT | Checkbox | Unauthorized software detected |
| RISKDataLossRisk | Dropdown | Low / Medium / High / Critical |
| RISKLastRiskAssessment | DateTime | Last assessment timestamp |

**Data Sources:** All OPS scores + SEC fields + Backup Status (native)

---

### Extended Automation: AUTO, UX, SRV (Scripts 10-13)

#### Script 10: Automation Safety Validator
**Frequency:** Every 4 hours  
**Runtime:** ~20 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| AUTORemediationEligible | Checkbox | Device safe for automation (Health > 70, Stability > 70) |
| AUTOAutomationRisk | Integer (0-100) | Automation risk score (0=safe, 100=dangerous) |
| AUTOLastSafetyCheck | DateTime | Last validation timestamp |

**Data Sources:** OPSHealthScore, OPSStabilityScore, BASEBusinessCriticality

---

#### Script 11: User Experience Monitor
**Frequency:** Daily  
**Runtime:** ~35 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| UXUserSatisfactionScore | Integer (0-100) | Composite UX score (boot time, crashes, hangs, performance) |
| UXBootTimeSec | Integer | Average boot time in seconds |
| UXSlowBootFlag | Checkbox | Boot time > 120 seconds |
| UXLastUXUpdate | DateTime | Last UX calculation timestamp |

**Data Sources:** STATBootTimeSec, STATAppCrashes24h, STATAppHangs24h

---

#### Script 12: Server Role Detector
**Frequency:** Daily  
**Runtime:** ~25 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| SRVRole | Dropdown | Domain Controller / File Server / Web Server / SQL Server / Generic Server / Workstation |
| SRVRoleConfidence | Integer (0-100) | Detection confidence level |
| SRVServicesRunning | Integer | Critical services running count |
| SRVLastRoleDetection | DateTime | Last detection timestamp |

**Data Sources:** Windows Services, Windows Features, Registry

---

#### Script 13: Network & Location Monitor
**Frequency:** Every 4 hours  
**Runtime:** ~30 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| NETLocationCurrent | Dropdown | Office / Home / Public / VPN / Unknown |
| NETIPAddress | Text | Current primary IP address |
| NETVPNConnected | Checkbox | VPN connection active |
| NETGatewayLatencyMs | Integer | Gateway ping latency (ms) |
| NETDNSServer | Text | Primary DNS server IP |
| NETLastNetworkUpdate | DateTime | Last network scan timestamp |

**Data Sources:** Network Adapters (WMI), Route Table, DNS Configuration

---

### Configuration Drift: DRIFT, BASE (Scripts 14, 18, 20-21, 35)

#### Script 14: Local Admin Drift Analyzer
**Frequency:** Daily  
**Runtime:** ~30 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| DRIFTLocalAdminDrift | Checkbox | Local admin accounts changed from baseline |
| DRIFTLocalAdminCount | Integer | Current local admin account count |
| DRIFTLocalAdminList | Text | Current local admin usernames |

**Data Sources:** Local Users and Groups (WMI)

---

#### Script 18: Baseline Establishment
**Frequency:** Once/Monthly (on-demand)  
**Runtime:** ~120 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| BASEEstablished | Checkbox | Baseline snapshot created |
| BASEEstablishedDate | DateTime | Baseline creation date |
| BASEBusinessCriticality | Dropdown | Critical / High / Standard / Low (manual override) |

**Data Sources:** System configuration snapshot (services, software, local admins)

---

#### Script 20: Software Baseline & Shadow-IT Detector
**Frequency:** Daily  
**Runtime:** ~40 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| DRIFTNewAppsCount | Integer | New applications since baseline |
| DRIFTNewAppsList | WYSIWYG | HTML list of new applications |
| RISKShadowIT | Checkbox | Unauthorized software detected |

**Data Sources:** Installed Programs (Registry), Software baseline

---

#### Script 21: Critical Service Drift Monitor
**Frequency:** Daily  
**Runtime:** ~30 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| DRIFTCriticalServiceDrift | Checkbox | Critical service configuration changed |
| DRIFTCriticalServiceNotes | Text | Details of service changes |

**Data Sources:** Windows Services configuration

---

#### Script 35: Baseline Coverage & Drift Density
**Frequency:** Daily  
**Runtime:** ~25 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| DRIFTActiveChanges | Integer | Active drift events count |
| DRIFTDriftEvents30d | Integer | Total drift events (30 days) |
| BASEBaselineAge | Integer | Days since baseline established |

**Data Sources:** All DRIFT fields aggregation

---

### Capacity Planning: CAP (Scripts 5, 22)

#### Script 22: Capacity Trend Forecaster
**Frequency:** Weekly  
**Runtime:** ~35 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| CAPDaysUntilDiskFull | Integer | Predicted days until disk C: full (based on 30-day trend) |
| CAPDiskGrowthRateMBDay | Float | Disk consumption rate (MB/day) |
| CAPMemoryForecastRisk | Dropdown | Low / Medium / High (memory pressure in 30-90 days) |
| CAPCPUForecastRisk | Dropdown | Low / Medium / High (CPU trend forecast) |
| CAPCapacityActionNeeded | Checkbox | Capacity intervention required |

**Data Sources:** Historical Disk Free Space (native), Memory Usage (native), CPU Usage (native)

---

### Security: SEC (Scripts 4, 15-16, 28)

#### Script 15: Security Posture Consolidator
**Frequency:** Daily  
**Runtime:** ~35 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| SECSecurityPosture | Integer (0-100) | Composite security score |
| SECFailedLogonCount24h | Integer | Failed login attempts (24 hours) |
| SECAccountLockouts24h | Integer | Account lockouts (24 hours) |
| SECLastThreatDetection | DateTime | Last security threat detected |

**Data Sources:** Windows Security Event Log, Native AV/Firewall Status

---

#### Script 16: Suspicious Login Pattern Detector
**Frequency:** Every 4 hours  
**Runtime:** ~25 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| SECSuspiciousLoginScore | Integer (0-100) | Anomaly detection score (0=normal, 100=suspicious) |

**Data Sources:** Windows Security Event Log (Event IDs 4625, 4740)

---

#### Script 28: Security Surface Telemetry
**Frequency:** Daily  
**Runtime:** ~30 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| SECInternetExposedPortsCount | Integer | Open ports exposed to internet |
| SECHighRiskServicesExposed | Integer | High-risk services exposed (RDP, SMB, etc.) |
| SECSoonExpiringCertsCount | Integer | Certificates expiring in 30 days |
| SECSecuritySurfaceSummaryHtml | WYSIWYG | HTML summary of security exposure |

**Data Sources:** Firewall rules, Certificate store, Network configuration

---

### Patching: UPD, PATCH (Scripts 23, PR1, PR2, P1-P4)

#### Script 23: Patch Compliance Aging Analyzer
**Frequency:** Daily  
**Runtime:** ~30 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| UPDMissingCriticalCount | Integer | Missing critical updates count |
| UPDMissingImportantCount | Integer | Missing important updates count |
| UPDLastPatchDate | DateTime | Last patch installation date |
| UPDPatchAgeDays | Integer | Days since last patch |
| UPDComplianceStatus | Dropdown | Compliant / Minor Gap / Significant Gap / Critical Gap |

**Data Sources:** Native Patch Status + Windows Update History

---

#### Script PR1: Patch Ring 1 (Test) Deployment
**Frequency:** Weekly (Tuesday)  
**Runtime:** 10-30 minutes (device-dependent)  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| PATCHLastAttemptDate | DateTime | Last patch deployment attempt |
| PATCHLastAttemptStatus | Text | Success / Failed / Deferred |
| PATCHLastPatchCount | Integer | Number of patches installed |
| PATCHRebootPending | Checkbox | Reboot required for patches |

**Data Sources:** Windows Update API, PSWindowsUpdate module

---

#### Script PR2: Patch Ring 2 (Production) Deployment
**Frequency:** Weekly (Tuesday, after 7-day PR1 soak)  
**Runtime:** 10-30 minutes (device-dependent)  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| PATCHLastAttemptDate | DateTime | Last patch deployment attempt |
| PATCHLastAttemptStatus | Text | Success / Failed / Deferred |
| PATCHLastPatchCount | Integer | Number of patches installed |
| PATCHRebootPending | Checkbox | Reboot required for patches |

**Data Sources:** Windows Update API, PSWindowsUpdate module

---

#### Scripts P1-P4: Priority-Based Patch Validators
**Frequency:** Before each patch deployment  
**Runtime:** 10-20 seconds each  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| PATCHValidationStatus | Dropdown | Passed / Failed / Warning |
| PATCHValidationNotes | Text | Validation details (health, backup, disk space) |
| PATCHValidationDate | DateTime | Last validation timestamp |

**Data Sources:** OPSHealthScore, Native Backup Status, Native Disk Free Space

---

### Infrastructure: IIS, MSSQL, MYSQL, APACHE, VEEAM, etc. (Server Scripts)

#### Script 101: IIS Web Server Monitor
**Frequency:** Every 4 hours  
**Runtime:** ~35 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| IISWebServerRunning | Checkbox | IIS service running |
| IISSiteCount | Integer | Number of websites configured |
| IISAppPoolCount | Integer | Number of application pools |
| IISStoppedSitesCount | Integer | Stopped websites count |
| IISStoppedSitesList | Text | Names of stopped websites |
| IISFailedRequestsCount | Integer | Failed requests (24 hours) |
| IISAverageResponseTimeMs | Integer | Average response time (ms) |
| IISCPUPercent | Float | IIS worker process CPU usage |
| IISMemoryMB | Integer | IIS worker process memory (MB) |

**Data Sources:** IIS WMI Provider, IIS Configuration, Performance Counters

---

#### Script 102: MSSQL Server Monitor
**Frequency:** Every 4 hours  
**Runtime:** ~45 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| MSSQLServiceRunning | Checkbox | SQL Server service running |
| MSSQLVersion | Text | SQL Server version |
| MSSQLDatabaseCount | Integer | Number of databases |
| MSSQLFailedJobsCount | Integer | Failed SQL Agent jobs (24 hours) |
| MSSQLBlockedProcesses | Integer | Blocked processes count |
| MSSQLLongRunningQueries | Integer | Queries running > 60 seconds |
| MSSQLDatabaseSizeGB | Float | Total database size (GB) |

**Data Sources:** SQL Server WMI, T-SQL Queries (via sqlcmd)

---

#### Script 103: VEEAM Backup Monitor
**Frequency:** Daily  
**Runtime:** ~35 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| VEEAMServiceRunning | Checkbox | Veeam service running |
| VEEAMLastBackupStatus | Dropdown | Success / Warning / Failed / None |
| VEEAMLastBackupDate | DateTime | Last backup completion date |
| VEEAMBackupAgeDays | Integer | Days since last successful backup |
| VEEAMFailedJobsCount | Integer | Failed backup jobs (7 days) |
| VEEAMBackupSizeGB | Float | Last backup size (GB) |

**Data Sources:** Veeam PowerShell Module, Veeam Registry Keys

---

### Battery Health: BAT (Script 25)

#### Script 25: Battery Health Monitor
**Frequency:** Daily  
**Runtime:** ~20 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| BATHealthPercent | Integer (0-100) | Battery health percentage |
| BATDesignCapacityMWh | Integer | Original design capacity (mWh) |
| BATFullChargeCapacityMWh | Integer | Current full charge capacity (mWh) |
| BATCycleCount | Integer | Battery charge cycles |
| BATEstimatedRuntime | Integer | Estimated runtime (minutes) |

**Data Sources:** WMI (Win32_Battery, BatteryStatus), Power Configuration

**Note:** Only runs on laptops (skips desktops/servers)

---

### Group Policy & Active Directory: GPO, AD (Scripts 26, 27)

#### Script 26: Group Policy Performance Monitor
**Frequency:** Every 4 hours  
**Runtime:** ~25 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| GPOLastApplyTimeSec | Integer | Last GPO application time (seconds) |
| GPOLastApplyDate | DateTime | Last GPO application timestamp |
| GPOErrorCount | Integer | GPO errors in last application |
| GPOSlowFlag | Checkbox | GPO apply time > 60 seconds |

**Data Sources:** Group Policy Event Log (Event IDs 1500-1503)

---

#### Script 27: Active Directory Integration Monitor
**Frequency:** Daily  
**Runtime:** ~20 seconds  

| Field Populated | Type | What It Measures |
|----------------|------|------------------|
| ADDomainJoined | Checkbox | Device is domain-joined |
| ADDomainName | Text | Active Directory domain name |
| ADLastLogonDays | Integer | Days since last AD logon |
| ADComputerAccountAge | Integer | Days since computer account created |

**Data Sources:** WMI (Win32_ComputerSystem), LDAP Queries

**Note:** Only runs on domain-joined devices

---

## Script Execution Schedule Summary

### Every 4 Hours (Critical Monitoring)
- Scripts 1-3: Health, Stability, Performance Scores
- Script 6-8: Telemetry Collection (crashes, uptime, resources)
- Script 10: Automation Safety Validator
- Script 13: Network & Location Monitor
- Script 16: Suspicious Login Pattern Detector
- Script 26: Group Policy Performance
- Scripts 101-103: Infrastructure (IIS, MSSQL, etc.)

### Daily (Proactive Intelligence)
- Script 4-5: Security & Capacity Scores
- Script 9: Risk Classifier
- Script 11-12: UX Monitor, Server Role Detector
- Scripts 14-21: Drift Detection (local admin, software, services)
- Script 15: Security Posture Consolidator
- Script 23: Patch Compliance Analyzer
- Script 25: Battery Health Monitor
- Script 27: Active Directory Monitor
- Script 28: Security Surface Telemetry
- Script 35: Baseline Coverage

### Weekly (Predictive Analytics)
- Script 22: Capacity Trend Forecaster
- Script 24: Device Lifetime Predictor
- Script PR1: Patch Ring 1 Deployment (Tuesday)
- Script PR2: Patch Ring 2 Deployment (Tuesday, Week 2)

### On-Demand / Pre-Deployment
- Script 18: Baseline Establishment (manual/monthly)
- Scripts P1-P4: Patch Validators (before patching)
- Scripts 40-65: Remediation scripts (condition-triggered)

---

## Script Runtime Performance Targets

| Script Category | Target Runtime | Acceptable Max | Optimization Priority |
|----------------|----------------|----------------|----------------------|
| Core Monitoring (1-13) | 20-30s | 60s | High |
| Extended Automation (14-24) | 25-40s | 90s | Medium |
| Infrastructure (101-110) | 30-45s | 120s | Medium |
| Remediation (40-65) | 30-60s | 180s | Low (runs on-demand) |
| Patching (PR1, PR2) | 10-30 min | Device-dependent | N/A (controlled) |

**Note:** If scripts consistently exceed acceptable max, review for optimization opportunities.

---

## Common Field Values

### Health Score (OPSHealthScore)

- **90-100:** Excellent
- **70-89:** Good
- **50-69:** Fair (needs attention)
- **30-49:** Poor (urgent action)
- **0-29:** Critical (immediate action)

### Stability Score (OPSStabilityScore)

- **90-100:** Excellent
- **70-89:** Good
- **50-69:** Fair
- **30-49:** Poor
- **0-29:** Critical

### Security Posture Score (SECSecurityPosture)

- **90-100:** Excellent
- **70-89:** Good
- **50-69:** Needs Attention
- **30-49:** At Risk
- **0-29:** Critical

### Update Compliance Status (UPDComplianceStatus)

- **Compliant:** Last update < 30 days, no security gaps
- **Minor Gap:** Last update 30-45 days
- **Significant Gap:** Last update 45-90 days OR 1-2 security updates missing
- **Critical Gap:** Last update > 90 days OR 3+ security updates missing
- **Unknown:** Cannot determine

### Automation Risk Levels (AUTOAutomationRisk)

- **0-20:** Very Low (safe for aggressive automation)
- **21-40:** Low (safe for standard automation)
- **41-60:** Medium (manual approval recommended)
- **61-80:** High (restricted automation)
- **81-100:** Very High (no automation)

### Business Criticality (BASEBusinessCriticality)

- **Critical:** Production servers, mission-critical systems
- **High:** Important services, business operations
- **Standard:** Regular workstations, non-critical servers
- **Low:** Test environments, development systems

### Patch Ring (PATCHRing)

- **PR1-Test:** Test ring (10-20 devices)
- **PR2-Production:** Production ring (all other devices)
- **Excluded:** Not eligible for automated patching

---

## Troubleshooting Guide

### Issue: Fields Not Populating

**Symptoms:** Custom fields remain empty after script execution

**Troubleshooting Steps:**
1. Check script execution logs in NinjaOne
2. Verify script is assigned to correct device group
3. Confirm script schedule is active
4. Check device connectivity (online/offline)
5. Review script error messages
6. Verify permissions (SYSTEM context required)

**Common Causes:**
- Script not scheduled or disabled
- Device offline during execution window
- PowerShell execution policy blocking
- Field name mismatch in script
- Insufficient permissions

**Resolution:**
- Re-run script manually on affected device
- Verify field names match exactly (case-sensitive)
- Check execution policy: `Get-ExecutionPolicy`
- Review NinjaOne activity log for errors

---

### Issue: False Positive Alerts

**Symptoms:** Receiving alerts that don't require action

**Troubleshooting Steps:**
1. Review condition logic (native + custom thresholds)
2. Check field values on alerted device
3. Verify device context (workstation vs server, criticality)
4. Adjust condition thresholds if needed
5. Add additional context filters

**Common Causes:**
- Thresholds too aggressive for environment
- Missing context filters (business criticality, device type)
- Temporary spikes triggering sustained conditions
- Hybrid condition missing custom intelligence check

**Resolution:**
- Add time-based conditions (e.g., "for 15 minutes")
- Include health/stability score checks
- Add business criticality filters
- Increase threshold values gradually

---

### Issue: Scripts Running Slowly

**Symptoms:** Script execution takes > 60 seconds

**Troubleshooting Steps:**
1. Check script runtime in execution logs
2. Identify slow operations (WMI queries, disk I/O)
3. Review script for inefficient loops
4. Check server load during execution
5. Optimize slow queries

**Common Causes:**
- Inefficient WMI/CIM queries
- Large log files being parsed
- Nested loops over large datasets
- Network-dependent operations

**Resolution:**
- Use `-Filter` parameters in WMI queries
- Limit log file parsing (recent entries only)
- Cache frequently accessed data
- Run heavy scripts during off-hours
- Consider splitting into multiple scripts

---

### Issue: Automation Not Triggering

**Symptoms:** Remediation scripts not executing despite conditions being met

**Troubleshooting Steps:**
1. Verify condition is active and triggering
2. Check automation safety flags (AUTORemediationEligible, etc.)
3. Review device group membership
4. Confirm remediation script is assigned
5. Check business criticality blocks

**Common Causes:**
- Safety flags set to False/disabled
- Device not in automation-eligible group
- Business criticality flag blocking automation
- Manual approval required but not granted
- Automation script not assigned to condition

**Resolution:**
- Review and adjust safety flags
- Verify dynamic group membership
- Check BASEBusinessCriticality setting
- Assign remediation script to condition
- Review automation action configuration

---

### Issue: High CPU During Script Execution

**Symptoms:** Device CPU spikes during monitoring scripts

**Troubleshooting Steps:**
1. Identify which script is causing spike
2. Review script for inefficient operations
3. Check execution frequency (too often?)
4. Stagger script execution times
5. Optimize resource-intensive queries

**Common Causes:**
- Too many scripts running simultaneously
- Inefficient loops or queries
- Large dataset processing
- Frequent execution schedule

**Resolution:**
- Add random delay offset (0-30 min)
- Reduce execution frequency if possible
- Optimize PowerShell code
- Use more efficient cmdlets
- Consider script consolidation

---

## Daily Operations Checklist

### Morning (10 minutes)

- [ ] Review P1 Critical condition alerts
- [ ] Check script execution failures (last 24h)
- [ ] Validate overnight patching results (if applicable)
- [ ] Review automation actions taken
- [ ] Check dashboard for anomalies

### Weekly (30 minutes)

- [ ] Review dynamic group populations (unexpected changes?)
- [ ] Check condition threshold effectiveness
- [ ] Generate operational reports
- [ ] Review false positive rate
- [ ] Tune thresholds if needed

### Monthly (2 hours)

- [ ] Review field utilization (unused fields?)
- [ ] Optimize slow scripts (runtime > 60s)
- [ ] Update documentation for customizations
- [ ] Stakeholder reporting (ROI, metrics)
- [ ] Plan for next month's improvements

### Quarterly (4 hours)

- [ ] Framework version updates
- [ ] Major threshold reviews
- [ ] Strategic planning (new automation)
- [ ] Staff training refresher
- [ ] Audit and compliance review

---

## Common Tasks

### Add New Device to Automation

1. Verify device meets requirements (health > 70, stability > 70)
2. Set `AUTORemediationEligible = True`
3. Set appropriate automation flags:
   - `AUTOAllowCleanup = True` (if disk cleanup desired)
   - `AUTOAllowServiceRestart = True` (if service restarts desired)
   - `AUTOAllowAfterHoursReboot = False` (default)
4. Verify `BASEBusinessCriticality` is set correctly
5. Monitor for 1 week before enabling aggressive automation

### Exclude Device from Automation

1. Set `AUTORemediationEligible = False`
2. Set all other AUTO flags to False
3. Document reason in device notes
4. Device will still be monitored, but no automation

### Configure New Server for Patching

1. Set `BASEBusinessCriticality` (Critical/High/Standard)
2. Set `PATCHRing = PR1-Test` (for testing) or `PR2-Production`
3. Define maintenance window in server notes
4. Monitor first patch cycle closely
5. Adjust settings based on results

### Investigate High Alert Volume

1. Check alert source (which condition?)
2. Review recent field value changes
3. Identify common pattern across devices
4. Determine if legitimate issue or false positive
5. Adjust thresholds or add context filters
6. Document changes

### Manually Run Script on Device

1. Navigate to device in NinjaOne
2. Go to Scripts tab
3. Select script to run
4. Click "Run Now"
5. Monitor execution log
6. Verify field updates after completion

---

## Field Population Expectations

### Core Intelligence (35 fields) - Should be 95%+ populated

| Prefix | Expected Population | Frequency | Populated By |
|--------|---------------------|-----------|--------------|
| OPS | 100% | Every 4 hours | Scripts 1-5 |
| STAT | 100% | Every 4 hours | Scripts 6-8 |
| RISK | 100% | Daily | Script 9 |
| AUTO | 100% | Every 4 hours | Script 10 |
| UX | 95% | Daily | Script 11 |
| SRV | 90% | Daily | Script 12 (servers only) |
| DRIFT | 90% | Daily | Scripts 14, 20-21, 35 |
| CAP | 95% | Daily/Weekly | Scripts 5, 22 |
| BAT | 80% | Daily | Script 25 (laptops only) |
| NET | 95% | Every 4 hours | Script 13 |
| GPO | 90% | Every 4 hours | Script 26 |
| AD | 85% | Daily | Script 27 (domain-joined only) |
| BASE | 95% | Weekly/manual | Script 18 |
| SEC | 100% | Daily | Scripts 4, 15-16, 28 |
| UPD | 100% | Daily | Script 23 |

### Infrastructure (117 fields) - Role-specific

- Only populated on servers with specific roles
- IIS fields: Only on IIS servers (Script 101)
- MSSQL fields: Only on SQL servers (Script 102)
- VEEAM fields: Only on Veeam servers (Script 103)
- etc.

### Patching (8 fields) - Should be 100% on servers

| Field | Population | Updated By |
|-------|------------|------------|
| PATCHRing | 100% (manual) | Administrator |
| PATCHLastAttemptDate | 100% | Scripts PR1, PR2 |
| PATCHLastAttemptStatus | 100% | Scripts PR1, PR2 |
| PATCHValidationStatus | 100% | Scripts P1-P4 |

---

## Performance Benchmarks

### Script Execution Times (Target)

| Script Category | Target Runtime | Acceptable Max |
|----------------|----------------|----------------|
| Core Monitoring (1-13) | < 30s | 60s |
| Extended Automation (14-24) | < 45s | 90s |
| Advanced Telemetry (27-36) | < 30s | 60s |
| Remediation (40-65) | < 60s | 120s |
| Patching (PR1, PR2) | 10-30 min | Device-dependent |

### Alert Response Times (Target)

| Priority | Detection | Investigation | Resolution |
|----------|-----------|---------------|------------|
| P1 Critical | < 5 min | < 15 min | < 1 hour |
| P2 High | < 15 min | < 1 hour | < 4 hours |
| P3 Medium | < 1 hour | < 4 hours | < 24 hours |
| P4 Low | < 24 hours | As needed | As needed |

---

## Script Naming Convention

### Format
`[Number]_[Category]_[Function].ps1`

### Examples
- `01_HealthScoreCalculator.ps1` - Script 1
- `15_SecurityPostureConsolidator.ps1` - Script 15
- `PR1_PatchRing1TestDeployment.ps1` - Patch Ring 1
- `P1_CriticalDevicePatchValidator.ps1` - Priority 1 Validator

---

## Support Resources

### Documentation Files

- **Framework Overview:** 00_README.md
- **Architecture:** 01_Framework_Architecture.md
- **Field Definitions:** Files 10-24
- **Script Repository:** Files 51-61
- **Field-to-Script Mapping:** File 51 (complete mapping)
- **Compound Conditions:** File 91
- **Dynamic Groups:** File 92
- **Complete Summary:** File 98
- **This File:** 99_Quick_Reference_Guide.md

### Getting Help

1. **Framework Documentation:** See File 98 for complete reference
2. **Field Mapping:** See File 51 for which script populates which field
3. **Deployment Assistance:** See Files 91-99 for templates and guides
4. **Custom Modifications:** Document in local files for team reference

---

## Version History

### Version 1.0 - February 2026 (CURRENT)

- Initial production release
- 277 custom intelligence fields
- 110 PowerShell scripts (26,400 LOC)
- 75 hybrid compound conditions
- 74 dynamic groups
- Native NinjaOne metric integration
- Complete field-to-script mapping
- Complete documentation suite

---

**This is your go-to reference for day-to-day operations. Bookmark this file for quick access!**

---

**File:** Quick_Reference_Guide.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 9:19 PM CET  
**Status:** Production Ready
