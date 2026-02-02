# Phase 2 Scripts Analysis - Script-to-Field Matrix
**Date:** February 2, 2026 12:18 PM CET  
**Status:** ✅ SCRIPTS FOLDER COMPLETE  
**Previous:** [00_PHASE2_COMPLETE_CORE_ANALYSIS.md](00_PHASE2_COMPLETE_CORE_ANALYSIS.md)  
**Audit Plan:** [00_DOCUMENTATION_AUDIT_PLAN.md](00_DOCUMENTATION_AUDIT_PLAN.md)

---

## Executive Summary

### Scripts Folder Contents:

- **📄 44 Total Files**
- **✅ 32 Documented Scripts**
- **🔲 12 Reserved Placeholders** (Scripts 25-27, 33, 37-44)
- **📖 3 Supporting Files** (README, .gitkeep, cleanup plan)

### Key Findings:

- ✅ **All core monitoring scripts documented** (Scripts 1-24)
- ✅ **Specialized scripts identified** (Scripts 28-36)
- ⚠️ **Script numbering conflicts resolved** between core/ and scripts/ folders
- ✅ **Scripts/ folder is authoritative source** for script definitions
- ✅ **New categories discovered** not in core/ field docs (BL, HV, CLEANUP, PRED, LIC, HW)

---

## Complete Script Inventory

### Scripts 1-10: Core Monitoring

| Script | Name | Category | Frequency | Updates Fields |
|--------|------|----------|-----------|----------------|
| **1** | Health Score Calculator | OPS | Every 4h | OPSHealthScore, OPSLastScoreUpdate |
| **2** | Stability Analyzer | OPS | Every 4h | OPSStabilityScore, OPSLastScoreUpdate |
| **3** | Performance Analyzer | OPS | Every 4h | OPSPerformanceScore, OPSLastScoreUpdate |
| **4** | Security Analyzer | OPS | Every 4h | OPSSecurityScore, OPSLastScoreUpdate |
| **5** | Capacity Analyzer | OPS | Daily | OPSCapacityScore, OPSLastScoreUpdate |
| **6** | Telemetry Collector | STAT | Every 4h | All STAT fields (6 fields) |
| **7** | BitLocker Monitor | BL | Daily | SECBitLockerEnabled, SECBitLockerStatus |
| **8** | HyperV Host Monitor | HV | Every 4h | (HV fields - not in core/ docs yet) |
| **9** | RISK Classifier | RISK | Every 4h | All RISK fields (7 fields) |
| **10** | Update Assessment Collector | UPD | Daily | (UPD fields - assisting Script 23) |

### Scripts 11-20: Baseline, Drift, UX

| Script | Name | Category | Frequency | Purpose |
|--------|------|----------|-----------|----------|
| **11** | NET Location Tracker | NET | Every 4h | Network location and connectivity tracking |
| **12** | Baseline Manager | BASE | On-demand | All BASE fields (7 fields) |
| **13** | DRIFT Detector | DRIFT | Daily | All DRIFT fields (5 fields) |
| **14** | Local Admin Analyzer | DRIFT | Daily | BASELocalAdmins analysis and alerting |
| **15** | Security Posture Consolidator | SEC | Daily | Security posture aggregation |
| **16** | Suspicious Login Detector | SEC | Every 4h | Login anomaly detection |
| **17** | Application Experience Profiler | UX | Every 4h | All UX fields (6 fields) |
| **18** | Profile Hygiene Advisor | CLEANUP | Weekly | Profile cleanup recommendations |
| **19** | Chronic Slow Boot Detector | UX | Daily | Boot performance anomaly detection |
| **20** | Shadow IT Detector | DRIFT | Daily | RISKShadowIT detection |

### Scripts 21-30: Capacity, Updates, Telemetry

| Script | Name | Category | Frequency | Purpose |
|--------|------|----------|-----------|----------|
| **21** | Critical Service Monitor | DRIFT | Every 4h | Service availability monitoring |
| **22** | Predictive Analytics | CAP | Weekly | All CAP fields (5 fields) |
| **23** | Patch Compliance Aging | UPD | Daily | All UPD fields (6 fields) |
| **24** | Device Lifetime Predictor | PRED | Weekly | Device replacement forecasting |
| **25-27** | *Reserved* | - | - | Future expansion |
| **28** | Security Surface Telemetry | SEC | Daily | Security telemetry aggregation |
| **29** | Collaboration Telemetry | UX | Daily | Teams, Zoom, collaboration metrics |
| **30** | User Environment Friction | UX | Daily | User experience pain point detection |

### Scripts 31-44: Network, Hardware, Server Roles

| Script | Name | Category | Frequency | Purpose |
|--------|------|----------|-----------|----------|
| **31** | Remote Connectivity Quality | NET | Every 4h | VPN, remote work quality metrics |
| **32** | Thermal Firmware Telemetry | HW | Daily | Hardware health and temperature |
| **33** | *Reserved* | - | - | Future expansion |
| **34** | Licensing Feature Utilization | LIC | Weekly | Software license usage tracking |
| **35** | Baseline Coverage Telemetry | BASE | Daily | Baseline establishment tracking |
| **36** | Server Role Detector | SRV | Daily | All SRV fields (7 fields) |
| **37-44** | *Reserved* | - | - | Future expansion (8 slots) |

**Note:** Scripts 41-105 mentioned in core/ docs as "Remediation Scripts" are not documented in scripts/ folder yet.

---

## Script Category Distribution

| Category | Script Count | Script Numbers | Primary Purpose |
|----------|--------------|----------------|------------------|
| **OPS** | 5 | 1-5 | Operational health scoring |
| **STAT** | 1 | 6 | Event log telemetry |
| **RISK** | 1 | 9 | Risk classification |
| **UPD** | 2 | 10, 23 | Windows Update compliance |
| **BASE** | 2 | 12, 35 | Configuration baseline |
| **DRIFT** | 4 | 13, 14, 20, 21 | Configuration drift detection |
| **SEC** | 3 | 15, 16, 28 | Security monitoring |
| **UX** | 4 | 17, 19, 29, 30 | User experience |
| **NET** | 2 | 11, 31 | Network monitoring |
| **CAP** | 1 | 22 | Capacity planning |
| **SRV** | 1 | 36 | Server role detection |
| **BL** | 1 | 7 | BitLocker encryption |
| **HV** | 1 | 8 | Hyper-V monitoring |
| **CLEANUP** | 1 | 18 | System cleanup |
| **PRED** | 1 | 24 | Predictive analytics |
| **HW** | 1 | 32 | Hardware telemetry |
| **LIC** | 1 | 34 | License tracking |

**Total Categories:** 17 categories  
**Documented Scripts:** 32 scripts

---

## Conflict Resolution: Core/ vs Scripts/

### ⚠️ **Critical Discovery:** Documentation Mismatch

The core/ field definition files reference script numbers that **do not match** the scripts/ folder:

| Script # | Core/ Docs Say | Scripts/ Folder Actually Is | Resolution |
|----------|----------------|----------------------------|------------|
| **8** | Network Monitor | HyperV Host Monitor | ✅ Scripts/ is correct |
| **9** | IIS Monitor | RISK Classifier | ✅ Scripts/ is correct |
| **11** | MySQL Monitor | NET Location Tracker | ✅ Scripts/ is correct |
| **11** | Configuration Drift Detector | NET Location Tracker | ✅ Should be Script 13 |
| **12** | Battery Health Monitor | Baseline Manager | ⚠️ BAT fields not mapped |
| **13** | Veeam Backup Monitor | DRIFT Detector | ⚠️ SRV backup not mapped |
| **15** | AD Monitor | Security Posture Consolidator | ⚠️ AD fields not mapped |
| **16** | GPO Monitor | Suspicious Login Detector | ⚠️ GPO fields not mapped |
| **18** | Baseline Establishment | Profile Hygiene Advisor | ✅ Should be Script 12 |

### 🛠️ **Required Actions for Phase 3:**

1. **Update core/ field docs** to reference correct script numbers from scripts/ folder
2. **Identify missing scripts** for field categories (BAT, NET, AD, GPO, IIS, MSSQL, MYSQL)
3. **Create missing script documentation** for gaps identified
4. **Verify scripts 41-105** existence and document remediation scripts

### 💡 **Likely Explanation:**

The core/ field docs appear to be **older or theoretical**, while scripts/ folder contains **actual implemented scripts**. Some planned scripts (BAT monitor as Script 12, AD monitor as Script 15, etc.) may not have been implemented yet, or were implemented with different script numbers.

---

## Missing Script Documentation

### Fields WITHOUT Corresponding Scripts in scripts/ folder:

| Field Category | Expected Functionality | Fields Count | Status |
|----------------|------------------------|--------------|--------|
| **BAT** | Battery Health Monitor | 10 fields | ❌ No script doc found |
| **NET** (partial) | Network Monitor | 10 fields | ⚠️ Scripts 11, 31 partial |
| **AD** | Active Directory Monitor | 9 fields | ❌ No script doc found |
| **GPO** | Group Policy Monitor | 6 fields | ❌ No script doc found |
| **IIS** | IIS Web Server Monitor | 11 fields | ❌ No script doc found |
| **MSSQL** | SQL Server Monitor | 8 fields | ❌ No script doc found |
| **MYSQL** | MySQL Server Monitor | 7 fields | ❌ No script doc found |
| **AUTO** | Automation Safety Validator | 7 fields | ❌ Script 40+ not documented |
| **AUTO** | Remediation Scripts (41-105) | 2 fields | ❌ Scripts 41-105 not documented |

**Total Missing:** Documentation for ~70 fields across 9 categories

### 🔍 **Analysis:**

This suggests:
1. Scripts may exist in actual NinjaRMM but lack documentation
2. Some fields may be manually populated
3. Some functionality may be planned but not yet implemented
4. Server role monitoring (IIS, MSSQL, MYSQL) may use different script numbers

---

## Script-to-Field Matrix (Verified)

### Complete Mappings from Scripts/ Folder:

```
Script 1  → OPSHealthScore, OPSLastScoreUpdate
Script 2  → OPSStabilityScore, OPSLastScoreUpdate
Script 3  → OPSPerformanceScore, OPSLastScoreUpdate
Script 4  → OPSSecurityScore, OPSLastScoreUpdate
Script 5  → OPSCapacityScore, OPSLastScoreUpdate
Script 6  → STATAppCrashes24h, STATAppHangs24h, STATServiceFailures24h, 
            STATBSODCount30d, STATUptimeDays, STATLastTelemetryUpdate
Script 7  → SECBitLockerEnabled, SECBitLockerStatus
Script 9  → RISKHealthLevel, RISKRebootLevel, RISKSecurityExposure, 
            RISKComplianceFlag, RISKShadowIT, RISKDataLossRisk, 
            RISKLastRiskAssessment
Script 12 → BASEBaselineEstablished, BASEBaselineDate, BASESoftwareList,
            BASEServiceList, BASEProcessList, BASEStartupList, BASELocalAdmins
Script 13 → DRIFTDriftDetected, DRIFTLastDriftDate, DRIFTDriftCategory,
            DRIFTDriftSeverity, DRIFTDriftSummary
Script 17 → UXBootTimeSeconds, UXLoginTimeSeconds, UXApplicationResponsiveness,
            UXUserSatisfactionScore, UXTopIssue, UXLastUserFeedback
Script 22 → CAPDaysUntilDiskFull, CAPMemoryUtilizationTrend, 
            CAPCPUUtilizationTrend, CAPCapacityHealthScore, CAPCapacityAlert
Script 23 → UPDLastWindowsUpdate, UPDPendingReboot, UPDMissingUpdatesCount,
            UPDMissingSecurityCount, UPDLastScanDate, UPDComplianceStatus
Script 36 → SRVServerRole, SRVRoleCount, SRVCriticalService, SRVMaintenanceWindow,
            SRVUpgradeEligible, SRVBackupStatus, SRVMonitoringProfile
```

**Total Verified Mappings:** ~70 fields across 14 documented scripts

---

## Script Execution Frequencies

### Distribution:

| Frequency | Count | Script Numbers |
|-----------|-------|----------------|
| **Every 4 hours** | 10 | 1, 2, 3, 4, 6, 9, 11, 16, 17, 21, 31 |
| **Daily** | 16 | 5, 7, 10, 13, 14, 15, 19, 20, 23, 28, 29, 30, 32, 35, 36 |
| **Weekly** | 3 | 18, 22, 24, 34 |
| **On-demand** | 1 | 12 |
| **Reserved** | 12 | 25-27, 33, 37-44 |

### Optimization Opportunities:

- **High-frequency scripts** (every 4h): 10 scripts = ~40 executions/day
- **Daily scripts**: 16 scripts = 16 executions/day
- **Weekly scripts**: 3 scripts = ~3 executions/week

**Total daily executions:** ~56 script runs per device (excluding on-demand)

---

## Documentation Quality in Scripts/ Folder

### Structure Observed:

✅ **Excellent Structure:**
- Script number, name, category clearly stated
- Execution frequency documented
- Runtime estimates provided
- Fields updated explicitly listed
- Cross-references to core/ field docs
- PowerShell implementation included
- Related documentation links provided

✅ **Consistent Format:**
- All scripts follow identical template
- Clear sections (Purpose, Execution, Fields, Implementation)
- Version numbers present
- Last updated dates included

### Cross-Reference Quality:

✅ **Scripts → Core/ Links:**
- Script 9 links to: `../core/12_RISK_Core_Classification.md`
- Script 9 links to: `../core/10_OPS_Core_Operational_Scores.md`
- Script 9 links to: `../core/11_STAT_Core_Telemetry.md`

⚠️ **Core/ → Scripts Links:**
- Core/ docs reference script **numbers**, not files
- No hyperlinks to actual script documentation
- Script numbers often incorrect

---

## New Categories Discovered

### Categories in scripts/ NOT in core/ field docs:

| Category | Script # | Purpose | Fields Documented? |
|----------|----------|---------|--------------------|
| **BL** | 7 | BitLocker encryption | ✅ In SEC category |
| **HV** | 8 | Hyper-V host monitoring | ❌ No HV fields doc |
| **CLEANUP** | 18 | System cleanup recommendations | ❌ No CLEANUP fields |
| **PRED** | 24 | Predictive analytics | ❌ No PRED fields |
| **HW** | 32 | Hardware telemetry | ❌ No HW fields |
| **LIC** | 34 | License utilization | ❌ No LIC fields |

**Analysis:** These scripts may:
1. Be informational only (no fields updated)
2. Update native NinjaOne fields only
3. Generate reports without field updates
4. Have field docs planned but not created yet

---

## Reserved Script Slots

### Future Expansion Capacity:

| Range | Count | Purpose (Likely) |
|-------|-------|------------------|
| **25-27** | 3 | Open slots in monitoring range |
| **33** | 1 | Open slot in telemetry range |
| **37-44** | 8 | Dedicated expansion range |

**Total Reserved:** 12 slots for future scripts

**Note:** Scripts 41-105 mentioned in core/ docs (65 remediation scripts) are not documented in scripts/ folder, suggesting:
- Different documentation location
- Auto-generated scripts
- Planned but not implemented
- Different numbering scheme

---

## Recommendations for Phase 3

### High Priority:

1. **✅ Update core/ field docs with correct script numbers** from scripts/ folder
2. **✅ Document missing scripts** for BAT, AD, GPO, NET, server roles
3. **✅ Verify remediation scripts 41-105** existence and location
4. **✅ Create comprehensive script-to-field reference matrix**
5. **✅ Add hyperlinks** from core/ docs to script docs

### Medium Priority:

6. **✅ Document HV, CLEANUP, PRED, HW, LIC field categories** if they exist
7. **✅ Standardize cross-references** between core/ and scripts/
8. **✅ Create script execution schedule** overview document
9. **✅ Add field-to-script reverse lookup** table

### Low Priority:

10. **✅ Version all documentation** consistently
11. **✅ Add last updated dates** uniformly
12. **✅ Create script dependency map** (Script 9 depends on Scripts 1-6)
13. **✅ Document script runtime performance** metrics

---

## Statistics Summary

### Scripts Folder:

| Metric | Count |
|--------|-------|
| Total files | 44 |
| Documented scripts | 32 |
| Reserved slots | 12 |
| Script categories | 17 |
| Fields verified mapped | ~70 |
| Fields missing scripts | ~63 |

### Documentation Coverage:

| Area | Status | Completion |
|------|--------|------------|
| Core monitoring (1-10) | ✅ Complete | 100% |
| Baseline/Drift (11-20) | ✅ Complete | 100% |
| Capacity/Updates (21-24) | ✅ Complete | 100% |
| Specialized (28-36) | ✅ Partial | 71% (5 of 7) |
| Remediation (41-105) | ❌ Not found | 0% |

---

**Scripts Analysis Completed:** February 2, 2026 12:18 PM CET  
**Status:** ✅ COMPLETE - Ready for Phase 3 remediation planning  
**Next Milestone:** Process remaining documentation folders and generate Phase 3 plan
