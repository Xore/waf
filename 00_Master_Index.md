# NinjaOne Custom Field Framework - Master Index

**Version:** 1.0  
**Last Updated:** February 1, 2026, 9:08 PM CET  
**Total Files:** 51 documentation files  
**Total Scripts:** 110 PowerShell scripts  
**Total Fields:** 277 custom fields

---

## Quick Start Navigation

**New Users:** Start with files 00, 01, Executive Summary  
**Implementation:** Follow files 10-24 for fields, 51-61 for scripts  
**Patching Automation:** See file 61 for ring-based deployment  
**Troubleshooting:** Files 99 (Quick Reference), 98 (Complete Summary)

---

## Part 1: Foundation & Architecture (Files 00-09)

### 00_README.md
**Purpose:** Framework overview, quick start guide  
**Key Content:**
- What's included in v1.0 (277 fields, 110 scripts, 75 conditions, 74 groups)
- Native metrics integration (12 core metrics)
- Quick start guide (4-week deployment)
- Benefits overview
- Documentation structure

### 00_Master_Index.md (This File)
**Purpose:** Complete navigation index for all 51 framework files  
**Key Content:**
- File organization by category
- Quick navigation by use case
- Deployment phase guidance
- Patching automation overview

### 01_Framework_Architecture.md
**Purpose:** Six-layer architecture design and principles  
**Key Content:**
- Layer 1: Telemetry Scripts (data collection)
- Layer 2: Custom Field Storage (intelligence persistence)
- Layer 3: Classification Logic (intelligence derivation)
- Layer 4: Dynamic Groups (automation routing)
- Layer 5: Remediation Automation (self-healing)
- Layer 6: Helpdesk Visibility (human interface)
- Design principles and best practices

### Executive_Summary.md
**Purpose:** Business case, ROI analysis, executive decision support  
**Key Content:**
- Business value summary (€14,750 first-year ROI)
- Cost analysis (€7,250 setup, €4,350/year maintenance)
- ROI by environment size
- Deployment recommendations
- Success metrics and KPIs

---

## Part 2: Core Custom Fields (Files 10-14)

### 10_OPS_STAT_RISK_Core_Metrics.md
**Purpose:** Operational scoring methodology (28 fields)  
**Key Content:**
- **OPS Prefix (6 fields):** Health, Performance, Stability, Security, Capacity scores
- **STAT Prefix (15 fields):** Crash tracking, boot time, uptime, telemetry
- **RISK Prefix (7 fields):** Business criticality, exposure levels, compliance

### 11_AUTO_UX_SRV_Core_Experience.md
**Purpose:** Automation control and user experience (21 fields)  
**Key Content:**
- **AUTO Prefix (8 fields):** Safety gates, remediation eligibility, automation control
- **UX Prefix (8 fields):** User satisfaction scores, friction tracking, performance metrics
- **SRV Prefix (5 fields):** Server role detection and classification

### 12_DRIFT_CAP_BAT_Core_Monitoring.md
**Purpose:** Drift detection and capacity planning (18 fields)  
**Key Content:**
- **DRIFT Prefix (9 fields):** Configuration baseline monitoring, active drift detection
- **CAP Prefix (6 fields):** Predictive capacity forecasting, days until full, growth rates
- **BAT Prefix (3 fields):** Battery health monitoring for laptops

### 13_NET_GPO_AD_Core_Network_Identity.md
**Purpose:** Network connectivity and identity integration (15 fields)  
**Key Content:**
- **NET Prefix (8 fields):** Location detection, VPN status, connectivity quality
- **GPO Prefix (4 fields):** Group Policy performance and compliance
- **AD Prefix (3 fields):** Active Directory integration, last logon tracking

### 14_BASE_SEC_UPD_Core_Security_Baseline.md
**Purpose:** Security posture and baseline management (16 fields)  
**Key Content:**
- **BASE Prefix (7 fields):** Baseline establishment, drift tracking, business criticality
- **SEC Prefix (5 fields):** Security posture scoring, compliance flags
- **UPD Prefix (4 fields):** Patch compliance, missing updates, aging

---

## Part 3: Extended Fields (Files 15-21)

### 15_Extended_DRIFT_Fields.md
**Purpose:** Granular configuration drift tracking (10 fields)  
**Key Content:**
- Local admin drift detection
- Software inventory changes
- Service configuration monitoring

### 16_Extended_SEC_Fields.md
**Purpose:** Advanced security telemetry (10 fields)  
**Key Content:**
- Failed login patterns
- Suspicious activity detection
- Security exposure assessment

### 17_Extended_UXAPP_Fields.md
**Purpose:** Application experience monitoring (15 fields)  
**Key Content:**
- Office 365 performance
- Collaboration tool quality
- Application stability tracking

### 18_CLEANUP_PRED_Fields.md
**Purpose:** Maintenance and predictive analytics (13 fields)  
**Key Content:**
- **CLEANUP (5 fields):** Disk cleanup recommendations
- **PRED (8 fields):** Device replacement forecasting

### 19_Extended_CAP_UPD_NET_Fields.md
**Purpose:** Expanded capacity and connectivity (10 fields)  
**Key Content:**
- Extended capacity forecasting
- Patch aging analysis
- Remote connectivity quality

### 20_Extended_BASE_HW_ALERT_Fields.md
**Purpose:** Baseline coverage and hardware monitoring (10 fields)  
**Key Content:**
- Baseline coverage metrics
- Thermal monitoring
- Firmware tracking

### 21_LIC_Extended_Fields.md
**Purpose:** Licensing and activation tracking (3 fields)  
**Key Content:**
- Windows activation status
- Office licensing
- Feature utilization

---

## Part 4: Infrastructure Fields (Files 22-24)

### 22_IIS_MSSQL_MYSQL_Database_Web_Servers.md
**Purpose:** Web and database server monitoring (26 fields)  
**Key Content:**
- **IIS (11 fields):** Web server health, application pools, sites
- **MSSQL (8 fields):** SQL Server monitoring, database health
- **MYSQL (7 fields):** MySQL/MariaDB monitoring

### 23_APACHE_VEEAM_DHCP_DNS_Infrastructure.md
**Purpose:** Critical infrastructure services (37 fields)  
**Key Content:**
- **APACHE (7 fields):** Apache web server monitoring
- **VEEAM (12 fields):** Backup monitoring and compliance
- **DHCP (9 fields):** DHCP server health
- **DNS (9 fields):** DNS server monitoring

### 24_EVT_FS_PRINT_HV_BL_FEAT_FLEXLM_Additional_Roles.md
**Purpose:** Additional server roles (54 fields)  
**Key Content:**
- **EVT (7 fields):** Event log monitoring
- **FS (8 fields):** File server shares and connections
- **PRINT (8 fields):** Print server queues
- **HV (9 fields):** Hyper-V virtualization
- **BL (6 fields):** BitLocker encryption
- **FEAT (5 fields):** Windows features
- **FLEXLM (11 fields):** FlexLM license server

---

## Part 5: Patching Framework (Files 30-36)

### 30_PATCH_Main_Patching_Framework.md
**Purpose:** Comprehensive patching strategy overview  
**Key Content:**
- Server-focused patching (workstations manual)
- Ring-based deployment (PR1 Test, PR2 Production)
- Priority-based validation (P1-P4)
- Workflow and automation

### 31_PATCH_Custom_Fields.md
**Purpose:** Patching custom field definitions (8 fields)  
**Key Content:**
- PATCHRing (PR1-Test, PR2-Production)
- PATCHEligible (eligibility status)
- PATCHCriticality (Critical, Standard, Development)
- PATCHMaintenanceWindow
- Compliance and validation fields

### 36_PATCH_Quick_Start_Guide.md
**Purpose:** Fast deployment guide for patching automation  
**Key Content:**
- 4-week deployment timeline
- Server classification
- Ring assignment
- Testing procedures

---

## Part 6: Script Documentation (Files 51-61)

### 51_Field_to_Script_Complete_Mapping.md
**Purpose:** Comprehensive field-to-script mapping  
**Key Content:**
- 277 fields mapped to 110 scripts
- Execution schedules
- Dependencies and prerequisites
- Integration details

### 55_Scripts_01_13_Infrastructure_Monitoring.md
**Purpose:** Core monitoring scripts (13 scripts, 5,200 LOC)  
**Key Content:**
- Scripts 1-13 (infrastructure services)
- Execution every 4 hours
- Server role monitoring
- Native metric integration

### 61_Scripts_Patching_Automation.md
**Purpose:** Patching automation scripts (5 scripts, 1,200 LOC)  
**Key Content:**
- PR1: Test ring deployment
- PR2: Production ring deployment
- P1-P4: Priority validators
- Pre/post validation
- Rollback procedures

---

## Part 7: Configuration Templates (Files 70-92)

### 70_Custom_Health_Check_Templates.md
**Purpose:** Health check configuration templates  
**Key Content:**
- Hybrid health check approach
- Template library
- Native + custom integration

### 91_Compound_Conditions_Complete.md
**Purpose:** Complete condition library (75 patterns)  
**Key Content:**
- P1 Critical (15 conditions)
- P2 High (20 conditions)
- P3 Medium (25 conditions)
- P4 Low (15 conditions)
- Hybrid native + custom logic

### 92_Dynamic_Groups_Complete.md
**Purpose:** Dynamic group patterns (74 groups)  
**Key Content:**
- Critical health groups (12)
- Operational groups (15)
- Automation groups (10)
- Drift & compliance groups (8)
- Capacity planning groups (12)
- Lifecycle groups (8)
- User experience groups (9)

---

## Part 8: Reference & Summary (Files 98-100)

### 98_Framework_Complete_Summary_Master.md
**Purpose:** Master reference and complete framework overview  
**Key Content:**
- All components summary
- Deployment architecture
- Integration strategy
- Success metrics

### 99_Quick_Reference_Guide.md
**Purpose:** Day-to-day operations guide  
**Key Content:**
- Field prefix quick reference
- Common field values
- Troubleshooting guide
- Daily operations checklist

### 100_Detailed_ROI_Analysis.md
**Purpose:** Comprehensive financial justification  
**Key Content:**
- Detailed cost breakdown
- Value calculation by category
- Multi-year projections
- Sensitivity analysis

---

## Quick Navigation by Use Case

### I Need To: Monitor Device Health
**Files:** 10 (OPS/STAT/RISK), 91 (Compound Conditions), 99 (Quick Reference)  
**Scripts:** 1-13 (Infrastructure Monitoring)

### I Need To: Detect Configuration Drift
**Files:** 12 (DRIFT fields), 15 (Extended DRIFT), 91 (Conditions)  
**Scripts:** 14-21 (Extended Automation)

### I Need To: Track Security Posture
**Files:** 14 (SEC/BASE), 16 (Extended SEC), 91 (Conditions)  
**Scripts:** 15-16 (Security scripts), 28 (Security telemetry)

### I Need To: Monitor Servers (IIS, SQL, etc.)
**Files:** 22-24 (Server role fields)  
**Scripts:** 1-13 (Infrastructure monitoring)

### I Need To: Plan Capacity & Predict Failures
**Files:** 12 (CAP), 19 (Extended CAP)  
**Scripts:** 22-24 (Capacity scripts)

### I Need To: Improve User Experience
**Files:** 11 (UX), 17 (Extended UXAPP)  
**Scripts:** 17-19 (UX scripts), 29-30 (Telemetry)

### I Need To: Automate Patching
**Files:** 30 (Patching framework), 31 (PATCH fields), 36 (Quick start)  
**Scripts:** 61 (Patching scripts: PR1, PR2, P1-P4)  
**Conditions:** 91 (Patch-related conditions)

---

## Deployment Phases

### Phase 1: Core Monitoring (Week 1-2)
**Deploy:**
- Files 10-14 (35 core fields)
- Scripts 1-13 (core monitoring)
- 20 P1/P2 critical conditions
- 10 essential groups

**Actions:**
- Create custom fields
- Deploy monitoring scripts
- Configure native monitoring
- Test on pilot group (10-20 devices)

### Phase 2: Extended Intelligence (Week 3-4)
**Deploy:**
- Files 15-21 (26 extended fields)
- Scripts 14-36 (automation + telemetry)
- 40 P1/P2/P3 conditions
- 30 groups

**Actions:**
- Add extended fields
- Deploy automation scripts
- Expand to 25% of fleet
- Validate alert accuracy

### Phase 3: Server Infrastructure (Week 4-5)
**Deploy:**
- Files 22-24 (117 server fields as needed)
- Server-specific scripts
- All 75 conditions
- All 74 groups

**Actions:**
- Target servers with specific roles
- Full condition library
- Roll out to 75% of fleet
- Configure dashboards

### Phase 4: Patching Automation (Week 6-8) - Optional
**Deploy:**
- Files 30-31 (8 PATCH fields)
- Scripts PR1, PR2, P1-P4
- Patching conditions
- Ring-based groups

**Actions:**
- Classify devices to rings
- Test on PR1 ring (7-day soak)
- Deploy to PR2 production
- Monitor and optimize

---

## Patching Automation Overview

### Patch Rings

**PR1 - Test Ring:**
- 10-20 test devices
- Deploy Tuesday Week 1
- Comprehensive pre/post validation
- 7-day soak period
- Must achieve 90% success rate

**PR2 - Production Ring:**
- All production devices
- Deploy Tuesday Week 2 (after soak)
- Business criticality-aware
- Maintenance window support
- Automated rollback on failure

### Priority Levels

**P1 - Critical:**
- Health Score > 80
- Stability Score > 80
- Backup within 24 hours
- Change approval required

**P2 - High:**
- Health Score > 70
- Stability Score > 70
- Backup within 72 hours
- Automated deployment

**P3 - Medium:**
- Health Score > 60
- Standard validation
- Flexible timing

**P4 - Low:**
- Health Score > 50
- Minimal validation
- Fully automated

### Deployment Workflow

1. **Pre-Validation:** Run P1/P2/P3/P4 validator scripts
2. **PR1 Deployment:** Test ring patching with comprehensive logging
3. **Soak Period:** 7 days monitoring of PR1 success rate
4. **PR2 Validation:** Verify PR1 ≥ 90% success rate
5. **PR2 Deployment:** Production ring patching with maintenance window awareness

### Integration Points

**Uses:**
- OPSHealthScore, OPSStabilityScore
- BASEBusinessCriticality
- SRVRole

**Updates:**
- PATCHLastAttemptDate
- PATCHLastAttemptStatus
- PATCHRebootPending

**Alerts:**
- P1_PatchFailed_Vulnerable
- P2_MultiplePatchesFailed

---

## File Structure Legend

### Numbering System

- **00-09:** Foundation & Architecture
- **10-24:** Core & Extended Custom Fields (by prefix)
- **30-39:** Patching Framework
- **50-61:** Implementation Guides & Scripts
- **70-79:** Configuration Templates
- **90-97:** Alerting & Automation (Conditions, Groups)
- **98-100:** Summaries & ROI

### File Types

- **Field Files (10-24):** Define custom field structure, types, values, use cases
- **Script Files (50-61):** PowerShell implementation code with documentation
- **Config Files (70-79, 90-97):** NinjaOne configuration examples
- **Summary Files (98-100):** Executive summaries and reference guides

---

## Version Information

**Framework Version:** 1.0  
**Release Date:** February 1, 2026  
**Status:** Production Ready  
**Recommended For:** All new NinjaOne deployments

### Version 1.0 Highlights

- 277 custom intelligence fields
- 110 PowerShell scripts (26,400 LOC)
- 75 hybrid compound conditions
- 74 dynamic groups
- Native NinjaOne metric integration (12 core metrics)
- Ring-based patching automation
- 70% reduction in false positives
- 4-week core deployment (8 weeks with patching)
- Complete documentation suite (51 files)

---

## Support & Maintenance

**Documentation Updates:** All files include timestamp and version number  
**Framework Support:** See File 98 for complete framework summary  
**Deployment Assistance:** See Files 91-99 for templates and guides  
**Custom Modifications:** Document in local files for team reference

---

**File:** 00_Master_Index.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 9:08 PM CET  
**Total Documentation:** 51 files  
**Status:** Production Ready
