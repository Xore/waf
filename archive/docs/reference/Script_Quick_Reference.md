# Script Quick Reference

**Purpose:** Quick lookup for all 45 framework scripts  
**Created:** February 8, 2026  
**Format:** One-line purpose with key fields

---

## Main Scripts (30 scripts)

### Core Monitoring (Scripts 01-05)

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 01 | Device_Health_Collector | Overall device health scoring | 4 hours | opsHealthScore, healthStatus |
| 02 | System_Stability_Monitor | System stability analysis | 4 hours | statStabilityScore, statCrashCount30d |
| 03 | Performance_Analyzer | Performance metrics evaluation | 4 hours | opsPerformanceScore, cpuAvgPercent |
| 04 | Security_Posture_Evaluator | Security configuration check | Daily | opsSecurityScore, secAntivirusEnabled |
| 05 | Capacity_Analyzer | Capacity and resource scoring | Daily | opsCapacityScore, diskFreePercent |

### Telemetry Collection (Scripts 06-08)

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 06 | Telemetry_Collection_Agent | Event log telemetry aggregation | 4 hours | statAppCrashes24h, statServiceFailures24h |
| 07 | DEPRECATED | Replaced by NinjaOne native | N/A | N/A |
| 08 | DEPRECATED | Replaced by NinjaOne native | N/A | N/A |

### Risk and Classification (Scripts 09-10)

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 09 | Risk_Classification_Engine | Multi-factor risk assessment | 4 hours | riskHealthLevel, riskDataLossRisk |
| 10 | Update_Assessment_Collector | Windows Update compliance | Daily | updMissingCriticalCount, updComplianceStatus |

### Baseline Management (Scripts 11-13)

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 11 | Network_Location_Tracker | Office/Remote detection | 4 hours | netLocationCurrent, netVPNConnected |
| 12 | Baseline_Manager | Performance baseline establishment | Daily | basePerformanceBaseline, baseDriftScore |
| 13 | Drift_Detector | Configuration drift detection | Daily | driftNewAppsCount |

### Extended Automation (Scripts 14-27)

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 14 | Local_Admin_Drift_Analyzer | Admin group changes | Daily | driftLocalAdminDrift, driftLocalAdminDriftMagnitude |
| 15 | Security_Posture_Consolidator | Aggregate security score | Daily | securityPostureScore, secLastThreatDetection |
| 16 | Suspicious_Login_Detector | Anomalous login patterns | 4 hours | suspiciousLoginScore, secFailedLogonCount24h |
| 17 | Application_Experience_Profiler | App crash and hang tracking | Daily | uxExperienceScore, appTopCrashingApp |
| 18 | Profile_Hygiene_Cleanup_Advisor | User profile analysis | Daily | uxProfileOptimizationNeeded |
| 19 | Chronic_Slow_Boot_Detector | Boot degradation tracking | Daily | uxBootDegradationFlag, uxBootTrend |
| 20 | Server_Role_Identifier | Server role detection | Daily | srvRole |
| 21 | Critical_Service_Drift_Monitor | Service configuration drift | Daily | driftCriticalServiceDrift |
| 22 | Resource_Capacity_Forecaster | Capacity trend prediction | Weekly | capMemoryForecastRisk, capCPUForecastRisk |
| 23 | Patch_Aging_Analyzer | Patch compliance aging | Daily | updPatchAgeDays, updPatchComplianceLabel |
| 24 | Device_Replacement_Predictor | Hardware lifecycle prediction | Weekly | predReplacementWindow |
| 25-27 | (Extended Scripts) | Various advanced monitoring | Varies | Various |

### Advanced Telemetry (Scripts 28-36)

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 28 | Security_Surface_Telemetry | Internet exposure assessment | Daily | secInternetExposedPortsCount |
| 29 | Collaboration_UX_Telemetry | Outlook/Teams quality | 4 hours | uxCollabFailures24h |
| 30 | User_Environment_Friction_Tracker | Login retry tracking | Daily | uxLoginRetryCount24h |
| 31 | Remote_Connectivity_Telemetry | VPN/SaaS quality | 4 hours | netWiFiDisconnects24h, netVPNAverageLatencyMs |
| 32 | Thermal_Firmware_Telemetry | Hardware health | Daily | driftFirmwareDrift |
| 33-36 | (Extended Scripts) | Additional telemetry | Varies | Various |

### Patch Validation (Scripts P1-P4)

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| P1 | Critical_Device_Validator | P1 patch readiness (strict) | On-demand | patchValidationStatus, patchValidationNotes |
| P2 | High_Priority_Validator | P2 patch readiness (balanced) | On-demand | patchValidationStatus, patchValidationNotes |
| P3 | Normal_Priority_Validator | P3 patch readiness (standard) | On-demand | patchValidationStatus, patchValidationNotes |
| P4 | Low_Priority_Validator | P4 patch readiness (minimal) | On-demand | patchValidationStatus, patchValidationNotes |

---

## Monitoring Scripts (15 scripts)

Located in `/scripts/monitoring/` directory

### Server Infrastructure

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 01 | Apache_Web_Server_Monitor | Apache health monitoring | 4 hours | apacheHealthStatus |
| 02 | DHCP_Server_Monitor | DHCP scope and lease tracking | 4 hours | dhcpServerStatus, dhcpScopesDepleted |
| 03 | DNS_Server_Monitor | DNS zone and query monitoring | 4 hours | dnsServerStatus, dnsFailedQueries24h |
| 37 | IIS_Web_Server_Monitor | IIS app pool and site health | 4 hours | iisHealthStatus, iisAppPoolsStopped |
| 38 | MSSQL_Server_Monitor | SQL Server database health | 4 hours | mssqlHealthStatus, mssqlLastBackup |
| 39 | MySQL_Server_Monitor | MySQL replication health | 4 hours | mysqlHealthStatus, mysqlReplicationStatus |
| 40 | Network_Monitor | Network connectivity quality | 4 hours | netHealthStatus |
| 41 | Battery_Health_Monitor | Laptop battery health | Daily | batHealthStatus, batChargePercent |

### Domain Infrastructure

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 42 | Active_Directory_Monitor | AD computer object status | Daily | adComputerAccountAge, adGroupMembership |
| 43 | Group_Policy_Monitor | GPO application status | Daily | gpoLastApplied, gpoHealthStatus |
| 44 | Event_Log_Monitor | Event log health | Daily | evtCriticalErrors24h, evtHealthStatus |

### File and Print

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 45 | File_Server_Monitor | Share and connection tracking | 4 hours | fsHealthStatus, fsConnectedUsersCount |
| 46 | Print_Server_Monitor | Print queue and job monitoring | 4 hours | printHealthStatus, printPrintJobsStuck |

### Backup and Licensing

| # | Script Name | Purpose | Frequency | Key Fields |
|---|-------------|---------|-----------|------------|
| 47 | FlexLM_License_Monitor | FlexLM license usage | 4 hours | flexlmHealthStatus, flexlmLicensesInUse |
| 48 | Veeam_Backup_Monitor | Veeam backup job status | Daily | veeamHealthStatus, veeamFailedJobsCount |

---

## Patching Scripts (2 deployment scripts)

| Script | Purpose | Frequency | Key Fields |
|--------|---------|-----------|------------|
| PR1_Patch_Ring1 | Test ring patch deployment | Weekly Tue | patchLastAttemptDate, patchLastAttemptStatus |
| PR2_Patch_Ring2 | Production ring deployment | Weekly Tue+7 | patchLastAttemptDate, patchRebootPending |

---

## Script Categories

### By Execution Frequency

**Every 4 Hours** (Real-time monitoring)
- Scripts 01-03, 06, 09, 11, 16, 29, 31
- Monitoring Scripts 01-03, 37-40, 42, 45-47
- Total: ~20 scripts

**Daily** (Daily checks)
- Scripts 04-05, 10, 12-15, 17-21, 23, 28, 30, 32, 34-35
- Monitoring Scripts 41-44, 48
- Total: ~20 scripts

**Weekly** (Trend analysis)
- Scripts 22, 24, PR1, PR2
- Total: ~4 scripts

**On-Demand** (Pre-deployment)
- Scripts P1-P4
- Total: 4 scripts

### By Device Type

**All Devices**
- Scripts 01-06, 09-24, 28-36, P1-P4
- Total: ~35 scripts

**Servers Only**
- Monitoring Scripts 01-03, 37-39, 42-43, 45-48
- Total: ~11 scripts

**Workstations/Laptops**
- Monitoring Script 41 (Battery)
- Total: 1 script

---

## Common Script Commands

### Manual Execution
```powershell
# Run script locally
.01_Device_Health_Collector.ps1

# Run with parameters (if supported)
.P1_Critical_Device_Validator.ps1 -Verbose
```

### View Script Output
- Check NinjaOne script execution log
- Look for "INFO", "WARNING", "ERROR" prefixed messages
- Verify custom fields updated

### Troubleshoot Script
1. Run manually on device
2. Check execution logs
3. Verify prerequisites (roles, modules)
4. Confirm field names match
5. Check permissions (runs as SYSTEM)

---

## Script Dependencies

### No Dependencies (Independent)
- Most scripts run independently
- No prerequisites except Windows

### Baseline-Dependent
- Script 13 (Drift Detector) - Requires Script 12 (Baseline) run first
- Some extended scripts - May reference baseline data

### Role-Dependent
- Monitoring Scripts 01-03, 37-39, 45-48 - Require specific server roles
- Scripts check for role, exit gracefully if not present

### Domain-Dependent
- Monitoring Scripts 42-43 - Require domain-joined
- Scripts detect workgroup, exit with "N/A" status

---

## Related Documentation

**Field Meanings:** [Field_Quick_Reference.md](Field_Quick_Reference.md)  
**Health Status:** [Health_Status_Quick_Reference.md](Health_Status_Quick_Reference.md)  
**Script Details:** Individual script headers in `/scripts/` directory  
**Dependencies:** [../diagrams/06_Script_Dependencies.md](../diagrams/06_Script_Dependencies.md)

---

**Total Scripts:** 45 (30 main + 15 monitoring)  
**Deprecated:** 2 (Scripts 07-08, replaced by native)  
**Active Scripts:** 43  
**Last Updated:** February 8, 2026
