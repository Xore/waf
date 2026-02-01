# Complete Framework Field-to-Script Mapping v4.0
**File:** 51_Field_to_Script_Complete_Mapping.md  
**Date:** February 1, 2026, 6:00 PM CET  
**Total Fields:** 277 fields (+7 patching fields)  
**Total Scripts:** 110 scripts (+5 patching scripts)  
**Purpose:** Complete traceability from every field to its populating scripts

---

## PATCHING AUTOMATION SCRIPTS (NEW)

### Script PR1: Patch Ring 1 (Test) Deployment
**Frequency:** Weekly (Tuesday)  
**Fields Updated:**
- patchLastAttemptDate (DateTime)
- patchLastAttemptStatus (Text)
- patchLastPatchCount (Integer)
- patchRebootPending (Checkbox)
- updMissingCriticalCount (Integer)
- updMissingImportantCount (Integer)
- updMissingOptionalCount (Integer)

### Script PR2: Patch Ring 2 (Production) Deployment
**Frequency:** Weekly (Tuesday, after 7-day PR1 soak)  
**Fields Updated:**
- patchLastAttemptDate (DateTime)
- patchLastAttemptStatus (Text)
- patchLastPatchCount (Integer)
- patchRebootPending (Checkbox)

### Script P1-P4: Priority-Based Patch Validators
**Frequency:** Before each patch deployment  
**Fields Updated:**
- patchValidationStatus (Dropdown)
- patchValidationNotes (Text)
- patchValidationDate (DateTime)

---

## NEW PATCHING FIELDS

| Field Name | Type | Populated By | Update Frequency |
|------------|------|--------------|------------------|
| patchRing | Dropdown | Manual configuration | As needed |
| patchLastAttemptDate | DateTime | Scripts PR1, PR2 | Per deployment |
| patchLastAttemptStatus | Text | Scripts PR1, PR2 | Per deployment |
| patchLastPatchCount | Integer | Scripts PR1, PR2 | Per deployment |
| patchRebootPending | Checkbox | Scripts PR1, PR2 | Per deployment |
| patchValidationStatus | Dropdown | Scripts P1-P4 Validators | Before deployment |
| patchValidationNotes | Text | Scripts P1-P4 Validators | Before deployment |
| patchValidationDate | DateTime | Scripts P1-P4 Validators | Before deployment |

---

## MAPPING TABLE: ALL FIELDS → SCRIPTS

### Extended DRIFT Fields (File 15)

| Field Name | Type | Populated By | Update Frequency |
|------------|------|--------------|------------------|
| DRIFTLocalAdminDrift | Checkbox | Script 14 - Local Admin Drift Analyzer | Daily |
| DRIFTLocalAdminDriftMagnitude | Dropdown | Script 14 - Local Admin Drift Analyzer | Daily |
| DRIFTNewAppsCount | Integer | Script 20 - Software Inventory Baseline and Shadow-IT Detector | Daily |
| DRIFTNewAppsList | WYSIWYG | Script 20 - Software Inventory Baseline and Shadow-IT Detector | Daily |
| DRIFTCriticalServiceDrift | Checkbox | Script 21 - Critical Service Configuration Drift Monitor | Daily |
| DRIFTCriticalServiceNotes | Text | Script 21 - Critical Service Configuration Drift Monitor | Daily |
| DRIFTFirmwareDrift | Checkbox | Script 32 - Thermal and Firmware Telemetry | Daily |
| DRIFTFirmwareDriftNotes | Text | Script 32 - Thermal and Firmware Telemetry | Daily |
| DRIFTDriftEvents30d | Integer | Script 35 - Baseline Coverage and Drift Density Telemetry | Daily |
| DRIFTBaselineAge | Integer | Script 35 - Baseline Coverage and Drift Density Telemetry | Daily |

### Extended SEC Fields (File 16)

| Field Name | Type | Populated By | Update Frequency |
|------------|------|--------------|------------------|
| SECFailedLogonCount24h | Integer | Script 15 - Security Posture Consolidator | Daily |
| SECAccountLockouts24h | Integer | Script 15 - Security Posture Consolidator | Daily |
| SECSuspiciousLoginScore | Integer | Script 16 - Suspicious Login Pattern Detector | Every 4 hours |
| SECInternetExposedPortsCount | Integer | Script 28 - Security Surface Telemetry | Daily |
| SECHighRiskServicesExposed | Integer | Script 28 - Security Surface Telemetry | Daily |
| SECSoonExpiringCertsCount | Integer | Script 28 - Security Surface Telemetry | Daily |
| SECSecuritySurfaceSummaryHtml | WYSIWYG | Script 28 - Security Surface Telemetry | Daily |
| SECEncryptionCompliance | Dropdown | Script 20 - Security Config Checker (enhanced) | Daily |
| SECSecurityPostureScore | Integer | Script 15 - Security Posture Consolidator | Daily |
| SECLastThreatDetection | DateTime | Script 15 - Security Posture Consolidator | Daily |

### Extended UX/APP Fields (File 17)

| Field Name | Type | Populated By | Update Frequency |
|------------|------|--------------|------------------|
| UXExperienceScore | Integer | Script 17 - Application Experience Profiler | Daily |
| UXApplicationHangCount24h | Integer | Script 17 - Application Experience Profiler | Daily |
| UXBootDegradationFlag | Checkbox | Script 19 - Chronic Slow-Boot Detector | Daily |
| UXBootTrend | Dropdown | Script 19 - Chronic Slow-Boot Detector | Daily |
| UXCollabFailures24h | Integer | Script 29 - Collaboration and Outlook UX Telemetry | Every 4 hours |
| UXCollabPoorQuality24h | Integer | Script 29 - Collaboration and Outlook UX Telemetry | Every 4 hours |
| UXLoginRetryCount24h | Integer | Script 30 - User Environment Friction Tracker | Daily |
| UXUserExperienceDetailHtml | WYSIWYG | Scripts 17, 29, 30 - Multiple UX scripts | Daily |
| UXProfileOptimizationNeeded | Checkbox | Script 18 - Profile Hygiene and Cleanup Advisor | Daily |
| UXLastUserActivityDate | DateTime | Script 17 - Application Experience Profiler | Daily |
| APPTopCrashingApp | Text | Script 17 - Application Experience Profiler | Daily |
| APPTopProblemApps | WYSIWYG | Script 17 - Application Experience Profiler | Daily |
| APPOfficeVersion | Text | Script 34 - Licensing and Feature Utilization Telemetry | Daily |
| APPOfficeActivation | Dropdown | Script 34 - Licensing and Feature Utilization Telemetry | Daily |
| APPOutlookFailures24h | Integer | Script 29 - Collaboration and Outlook UX Telemetry | Every 4 hours |

### Extended CAP/UPD/NET Fields (File 19)

| Field Name | Type | Populated By | Update Frequency |
|------------|------|--------------|------------------|
| CAPMemoryForecastRisk | Dropdown | Script 22 - Capacity Trend Forecaster | Weekly |
| CAPCPUForecastRisk | Dropdown | Script 22 - Capacity Trend Forecaster | Weekly |
| CAPCapacityActionNeeded | Checkbox | Script 22 - Capacity Trend Forecaster | Weekly |
| CAPSaaSLatencyCategory | Dropdown | Script 31 - Remote Connectivity and SaaS Quality Telemetry | Every 4 hours |
| UPDPatchAgeDays | Integer | Script 23 - Patch-Compliance Aging Analyzer | Daily |
| UPDPatchComplianceLabel | Dropdown | Script 23 - Patch-Compliance Aging Analyzer | Daily |
| NETWiFiDisconnects24h | Integer | Script 31 - Remote Connectivity and SaaS Quality Telemetry | Every 4 hours |
| NETVPNAverageLatencyMs | Integer | Script 31 - Remote Connectivity and SaaS Quality Telemetry | Every 4 hours |
| NETRemoteConnectivityHtml | WYSIWYG | Script 31 - Remote Connectivity and SaaS Quality Telemetry | Every 4 hours |
| NETSaaSEndpointStatus | Text | Script 31 - Remote Connectivity and SaaS Quality Telemetry | Every 4 hours |

---

## SCRIPT EXECUTION SCHEDULE

### Every 4 Hours
- Script 1-9: Core OPS/STAT/RISK metrics
- Script 16: Suspicious Login Pattern Detector
- Script 27: Telemetry Freshness Monitor
- Script 29: Collaboration and Outlook UX Telemetry
- Script 31: Remote Connectivity and SaaS Quality Telemetry
- Script 9-11: IIS, MSSQL, MySQL monitors

### Daily
- Script 14: Local Admin Drift Analyzer
- Script 15: Security Posture Consolidator
- Script 17: Application Experience Profiler
- Script 18: Profile Hygiene and Cleanup Advisor
- Script 19: Chronic Slow-Boot Detector
- Script 20: Software Inventory Baseline and Shadow-IT Detector
- Script 21: Critical Service Configuration Drift Monitor
- Script 23: Patch-Compliance Aging Analyzer
- Script 28: Security Surface Telemetry
- Script 30: User Environment Friction Tracker
- Script 32: Thermal and Firmware Telemetry
- Script 34: Licensing and Feature Utilization Telemetry
- Script 35: Baseline Coverage and Drift Density Telemetry

### Weekly
- Script 22: Capacity Trend Forecaster
- Script 24: Device Lifetime and Replacement Predictor
- **Script PR1: Patch Ring 1 Deployment** (Tuesday)
- **Script PR2: Patch Ring 2 Deployment** (Tuesday, week 2)

### On-Demand / Pre-Deployment
- **Script P1: Critical Device Patch Validator**
- **Script P2: High Priority Device Patch Validator**
- **Script P3-P4: Medium/Low Priority Device Patch Validator**

---

## SCRIPT DEPENDENCY CHAINS

### Chain 1: Baseline & Drift Detection
1. Script 18: Baseline Establishment - Run first
2. Script 11: Drift Detector - Requires baseline
3. Scripts 14, 20, 21: Specific drift detectors - Requires baseline
4. Script 35: Baseline Coverage - Validates baseline quality

### Chain 2: Telemetry → Scoring → Classification
1. Scripts 6-8: Telemetry Collection - Collect raw data
2. Scripts 1-5: Score Calculation - Calculate scores
3. Script 9: Risk Classification - Classify based on scores
4. Script 27: Freshness Monitor - Validate data quality

### Chain 3: Security Posture & Response
1. Script 20: Security Config Checker - Check configuration
2. Script 15: Security Posture Consolidator - Calculate posture
3. Script 16: Suspicious Login Detector - Detect threats
4. Script 28: Security Surface Telemetry - Assess exposure

### Chain 4: Capacity Forecast → Prediction
1. Script 7: Resource Monitor - Collect capacity data
2. Script 22: Capacity Trend Forecaster - Analyze trends
3. Script 24: Device Lifetime Predictor - Predict replacement

### Chain 5: Patching Workflow (NEW)
1. **Script P1/P2/P3-P4: Validation** - Pre-deployment validation
2. **Script PR1: Test Ring** - Deploy to 10-20 test devices
3. **7-day soak period** - Monitor PR1 success
4. **Script PR2: Production Ring** - Deploy to all production devices

---

## FIELD UPDATE PRIORITY

### P1 Critical (Every 4 hours or more frequent)
- All OPS scores (health, stability, performance, security, capacity)
- All STAT telemetry (crashes, hangs, resource usage)
- All RISK classifications
- Security authentication metrics
- IIS/SQL server health
- **Patch validation status (before deployment)**

### P2 High (Daily)
- Extended security metrics
- User experience scores
- Configuration drift detection
- Patch compliance
- Licensing status
- **Patch deployment results**

### P3 Medium (Weekly)
- Capacity forecasting
- Predictive analytics
- Trend analysis
- **Patch ring assignments**

---

## TOTAL SCRIPT COUNT BY CATEGORY

| Category | Script Count | Description |
|----------|--------------|-------------|
| Core Monitoring | 13 scripts | OPS/STAT/RISK/Infrastructure |
| Extended Automation | 14 scripts | Drift, Security, UX |
| Advanced Telemetry | 9 scripts | Capacity, Predictive, Network |
| Server Role Monitoring | 11 scripts | IIS, SQL, MySQL, Apache, etc. |
| **Patching Automation** | **5 scripts** | **PR1, PR2, P1, P2, P3-P4 validators** |
| **TOTAL** | **110 scripts** | **Complete framework** |

---

## PATCHING SCRIPT INTEGRATION

The new patching scripts integrate with existing framework components:

### Uses These Existing Fields
- OPSHealthScore - Go/no-go decision thresholds
- STATStabilityScore - System stability validation
- STATCrashCount30d - Crash history assessment
- BASEBusinessCriticality - Validation strictness levels
- RISKExposureLevel - Patch prioritization
- SRVRole - Maintenance window requirements
- AUTOAllowAfterHoursReboot - Reboot automation control

### Populates These New Fields
- patchRing - PR1-Test, PR2-Production
- patchLastAttemptDate - Deployment timestamp
- patchLastAttemptStatus - Success/Failed/Deferred
- patchLastPatchCount - Number of patches installed
- patchRebootPending - Reboot requirement flag
- patchValidationStatus - Pre-deployment validation result
- patchValidationNotes - Validation details
- patchValidationDate - Validation timestamp

### Works With These Compound Conditions
- P1PatchFailedVulnerable - Critical patch failure alerts
- P2MultiplePatchesFailed - Repeated failure alerts
- P2PendingRebootUpdates - Reboot tracking
- P4PatchesCurrent - Compliance reporting

---

**File:** 51_Field_to_Script_Complete_Mapping.md  
**Last Updated:** February 1, 2026, 6:00 PM CET  
**Framework Version:** 4.0 with Patching Automation  
**Status:** Production Ready
