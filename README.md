# NinjaOne Custom Field Framework - Master Index

**Version:** 4.0  
**Last Updated:** February 2, 2026, 2:00 AM CET  
**Total Files:** 54 documentation files  
**Total Scripts:** 110 PowerShell scripts  
**Total Fields:** 277 custom fields

---

## Quick Start Navigation

**New Users:** Start with 00_README.md, 01_Framework_Architecture.md, docs/reference/256_Executive_Summary_Core.md  
**Implementation:** Follow docs/core/* for fields, docs/scripts/* for scripts  
**Patching Automation:** See docs/patching/* for ring-based deployment  
**Troubleshooting:** docs/reference/255_Quick_Reference.md, docs/automation/152_Framework_Master_Summary.md

---

## Part 1: Foundation & Architecture (Root Files)

### 00_README.md
**Purpose:** Framework overview, quick start guide  
**Location:** Root directory  
**Key Content:**
- What's included in v4.0 (277 fields, 110 scripts, 75 conditions, 74 groups)
- Native metrics integration (12 core metrics)
- Quick start guide (4-week deployment)
- Benefits overview
- Documentation structure

### README.md (This File)
**Purpose:** Complete navigation index for all framework files  
**Location:** Root directory  
**Key Content:**
- File organization by category
- Quick navigation by use case
- Deployment phase guidance
- Complete file listing with paths

### 01_Framework_Architecture.md
**Purpose:** Six-layer architecture design and principles  
**Location:** Root directory  
**Key Content:**
- Layer 1: Telemetry Scripts (data collection)
- Layer 2: Custom Field Storage (intelligence persistence)
- Layer 3: Classification Logic (intelligence derivation)
- Layer 4: Dynamic Groups (automation routing)
- Layer 5: Remediation Automation (self-healing)
- Layer 6: Helpdesk Visibility (human interface)
- Design principles and best practices

---

## Part 2: Core Custom Fields (docs/core/)

### docs/core/10_OPS_STAT_RISK_Core_Metrics.md
**Fields:** 35 essential operational metrics  
**Key Content:**
- **OPS Prefix (6 fields):** Health, Performance, Stability, Security, Capacity scores
- **STAT Prefix (15 fields):** Crash tracking, boot time, uptime, telemetry
- **RISK Prefix (7 fields):** Business criticality, exposure levels, compliance

### docs/core/11_AUTO_UX_SRV_Core_Experience.md
**Fields:** 26 automation and user experience fields  
**Key Content:**
- **AUTO Prefix (8 fields):** Safety gates, remediation eligibility, automation control
- **UX Prefix (8 fields):** User satisfaction scores, friction tracking, performance metrics
- **SRV Prefix (5 fields):** Server role detection and classification

### docs/core/12_DRIFT_CAP_BAT_Core_Monitoring.md
**Fields:** 21 drift and capacity fields  
**Key Content:**
- **DRIFT Prefix (9 fields):** Configuration baseline monitoring, active drift detection
- **CAP Prefix (6 fields):** Predictive capacity forecasting, days until full, growth rates
- **BAT Prefix (3 fields):** Battery health monitoring for laptops

### docs/core/13_NET_GPO_AD_Core_Network_Identity.md
**Fields:** 15 network and identity fields  
**Key Content:**
- **NET Prefix (8 fields):** Location detection, VPN status, connectivity quality
- **GPO Prefix (4 fields):** Group Policy performance and compliance
- **AD Prefix (3 fields):** Active Directory integration, last logon tracking

### docs/core/14_BASE_SEC_UPD_Core_Security_Baseline.md
**Fields:** 18 baseline and security fields  
**Key Content:**
- **BASE Prefix (7 fields):** Baseline establishment, drift tracking, business criticality
- **SEC Prefix (5 fields):** Security posture scoring, compliance flags
- **UPD Prefix (4 fields):** Patch compliance, missing updates, aging

### docs/core/15_Server_Roles_Database_Web.md
**Fields:** 64 database and web server fields  
**Key Content:**
- **IIS (28 fields):** Web server health, application pools, sites
- **MSSQL (25 fields):** SQL Server monitoring, database health
- **MYSQL (11 fields):** MySQL/MariaDB monitoring

### docs/core/16_Server_Roles_Infrastructure.md
**Fields:** 53 infrastructure service fields  
**Key Content:**
- **APACHE (13 fields):** Apache web server monitoring
- **VEEAM (16 fields):** Backup monitoring and compliance
- **DHCP (12 fields):** DHCP server health
- **DNS (12 fields):** DNS server monitoring

### docs/core/17_Server_Roles_Additional.md
**Fields:** 91 additional server role fields  
**Key Content:**
- **EVT (7 fields):** Event log monitoring
- **FS (8 fields):** File server shares and connections
- **PRINT (8 fields):** Print server queues
- **HV (9 fields):** Hyper-V virtualization
- **BL (6 fields):** BitLocker encryption
- **FEAT (5 fields):** Windows features
- **FLEXLM (11 fields):** FlexLM license server

---

## Part 3: Patching Framework (docs/patching/)

### docs/patching/45_Patching_Framework_Main.md
**Purpose:** Comprehensive patching strategy overview  
**Key Content:**
- Server-focused patching (workstations manual)
- Ring-based deployment (PR1 Test, PR2 Production)
- Priority-based validation (P1-P4)
- Workflow and automation

### docs/patching/46_Patching_Custom_Fields.md
**Fields:** 8 patching custom fields  
**Key Content:**
- PATCHRing (PR1-Test, PR2-Production)
- PATCHEligible (eligibility status)
- PATCHCriticality (Critical, Standard, Development)
- PATCHMaintenanceWindow
- Compliance and validation fields

### docs/patching/47_Patching_Quick_Start.md
**Purpose:** Fast deployment guide for patching automation  
**Key Content:**
- 4-week deployment timeline
- Server classification
- Ring assignment
- Testing procedures

### docs/patching/48_Patching_Ring_Deployment.md
**Purpose:** Ring-based deployment strategy  
**Key Content:**
- PR1 test ring configuration
- PR2 production ring rollout
- Soak period management
- Success criteria

### docs/patching/49_Patching_Windows_Tutorial.md
**Purpose:** Windows OS patching step-by-step  
**Key Content:**
- Windows Update configuration
- Ring-based deployment workflow
- Validation procedures

### docs/patching/50_Patching_Software_Tutorial.md
**Purpose:** Third-party software patching guide  
**Key Content:**
- Software patching workflow
- Application-specific considerations
- Testing requirements

### docs/patching/51_Patching_Policy_Guide.md
**Purpose:** Policy configuration reference  
**Key Content:**
- NinjaOne policy setup
- Maintenance window configuration
- Ring-specific policies

### docs/patching/52_Patching_Scripts.md
**Scripts:** PR1, PR2, P1-P4 (5 patching scripts, 1,200 LOC)  
**Key Content:**
- PR1: Test ring deployment
- PR2: Production ring deployment
- P1-P4: Priority validators
- Pre/post validation
- Rollback procedures

### docs/patching/53_Patching_Summary.md
**Purpose:** Quick reference for patching framework  
**Key Content:**
- Component summary
- Workflow overview
- Best practices

---

## Part 4: Script Documentation (docs/scripts/)

### docs/scripts/93_Scripts_Field_Mapping.md
**Purpose:** Comprehensive field-to-script mapping  
**Key Content:**
- 277 fields mapped to 110 scripts
- Execution schedules
- Dependencies and prerequisites
- Integration details

### docs/scripts/80_Scripts_Monitoring_01_to_13.md
**Scripts:** 1-13 (Infrastructure monitoring, 5,200 LOC)  
**Key Content:**
- Scripts 1-13 (infrastructure services)
- Execution every 4 hours
- Server role monitoring
- Native metric integration

### docs/scripts/82_Scripts_Automation_14_to_20.md
**Scripts:** 14-20 (Core automation fields)  
**Key Content:**
- Automation eligibility detection
- UX metric collection
- Server role identification

### docs/scripts/83_Scripts_Automation_14_to_27.md
**Scripts:** 14-27 (Extended automation, 2,800 LOC)  
**Key Content:**
- Drift detection
- Security posture
- Baseline management
- Capacity forecasting

### docs/scripts/85_Scripts_Telemetry_28_to_36.md
**Scripts:** 28-36 (Advanced telemetry, 1,800 LOC)  
**Key Content:**
- Event log analysis
- Licensing tracking
- Feature detection
- Advanced metrics

### docs/scripts/86_Scripts_Capacity_Predictive.md
**Purpose:** Predictive capacity analysis scripts  
**Key Content:**
- Disk growth trending
- Memory utilization forecasting
- Days-until-full calculation

### docs/scripts/90_Scripts_Baseline_Refresh.md
**Scripts:** Baseline management  
**Key Content:**
- Baseline snapshot creation
- Drift detection logic
- Refresh procedures

### docs/scripts/91_Scripts_Emergency_Cleanup.md
**Scripts:** Script 50 (Emergency disk cleanup)  
**Key Content:**
- Safe cleanup procedures
- Temp file removal
- Windows cleanup integration

### docs/scripts/92_Scripts_Memory_Optimization.md
**Scripts:** Script 55 (Memory optimization)  
**Key Content:**
- Memory pressure detection
- Safe optimization procedures
- Working set trimming

### docs/scripts/95_Scripts_Service_Print_Spooler.md
**Scripts:** Script 41 (Print Spooler restart)  
**Key Content:**
- Print Spooler remediation
- Safe restart procedures

### docs/scripts/96_Scripts_Service_Windows_Update.md
**Scripts:** Script 42 (Windows Update service)  
**Key Content:**
- Windows Update service remediation
- Update troubleshooting

### docs/scripts/97_Scripts_Service_DNS_Client.md
**Scripts:** Script 43 (DNS Client service)  
**Key Content:**
- DNS Client remediation
- Network connectivity fixes

### docs/scripts/98_Scripts_Service_Network.md
**Scripts:** Script 44 (Network services)  
**Key Content:**
- Network service remediation
- Connectivity restoration

### docs/scripts/99_Scripts_Service_Remote_Desktop.md
**Scripts:** Script 45 (RDP service)  
**Key Content:**
- Remote Desktop service remediation
- RDP troubleshooting

---

## Part 5: Health Checks (docs/health-checks/)

### docs/health-checks/115_Health_Checks_Quick_Reference.md
**Purpose:** Quick reference for health check configuration  
**Key Content:**
- Health check types
- Configuration guidelines
- Best practices

### docs/health-checks/116_Health_Checks_Templates.md
**Purpose:** Health check configuration templates  
**Key Content:**
- Hybrid health check approach
- Template library
- Native + custom integration
- Configuration examples

### docs/health-checks/117_Health_Checks_Summary.md
**Purpose:** Health check framework summary  
**Key Content:**
- Component overview
- Integration strategy
- Performance considerations

---

## Part 6: Automation & Conditions (docs/automation/)

### docs/automation/150_Compound_Conditions.md
**Purpose:** Complete condition library (75 patterns)  
**Key Content:**
- P1 Critical (15 conditions)
- P2 High (20 conditions)
- P3 Medium (25 conditions)
- P4 Low (15 conditions)
- Hybrid native + custom logic
- Trigger actions and remediation

### docs/automation/151_Dynamic_Groups.md
**Purpose:** Dynamic group patterns (74 groups)  
**Key Content:**
- Critical health groups (12)
- Operational groups (15)
- Automation groups (10)
- Drift & compliance groups (8)
- Capacity planning groups (12)
- Lifecycle groups (8)
- User experience groups (9)

### docs/automation/152_Framework_Master_Summary.md
**Purpose:** Master reference and complete framework overview  
**Key Content:**
- All components summary
- Deployment architecture
- Integration strategy
- Success metrics

---

## Part 7: ROI & Business Case (docs/roi/)

### docs/roi/185_ROI_Analysis_No_ML.md
**Purpose:** Core framework ROI (without ML)  
**Key Content:**
- Cost analysis: €4,500 deployment
- Benefit categories
- ROI calculations: 98-115% Year 1
- Payback period: 4.5-5.5 months
- Sensitivity analysis

### docs/roi/186_ROI_Analysis_With_ML.md
**Purpose:** Full framework ROI (with ML/RCA)  
**Key Content:**
- Cost analysis: €7,250 deployment
- ML/RCA benefits
- ROI calculations: 66-203% Year 1
- Payback period: 7.2 months
- Platform costs included

---

## Part 8: Training & Troubleshooting (docs/training/)

### docs/training/220_Training_Part1_Fundamentals.md
**Purpose:** Training modules 1-4 (24 hours)  
**Key Content:**
- Module 1: Framework Fundamentals
- Module 2: Custom Fields Deep Dive
- Module 3: PowerShell Scripts Overview
- Module 4: Compound Conditions
- Hands-on labs

### docs/training/221_Training_Part2_Advanced.md
**Purpose:** Training modules 5-8 (40 hours)  
**Key Content:**
- Module 5: Dynamic Groups
- Module 6: Patching Automation
- Module 7: Framework Troubleshooting
- Module 8: Advanced Customization
- Advanced labs

### docs/training/222_Training_ML_Integration.md
**Purpose:** ML/RCA training (64 hours)  
**Key Content:**
- Module 9: ML/RCA Integration
- Module 10: API Integration
- Module 11: Enterprise Deployment
- Capstone project

### docs/training/223_Troubleshooting_Guide.md
**Purpose:** Framework-powered troubleshooting  
**Key Content:**
- Common issues and solutions
- Field validation procedures
- Script debugging
- Condition troubleshooting
- Performance optimization

---

## Part 9: Reference & Executive Summaries (docs/reference/)

### docs/reference/255_Quick_Reference.md
**Purpose:** Day-to-day operations guide  
**Key Content:**
- Field prefix quick reference
- Common field values
- Script execution guide
- Condition trigger reference
- Daily operations checklist

### docs/reference/256_Executive_Summary_Core.md
**Purpose:** Executive summary for core framework  
**Key Content:**
- Business case overview
- Core framework benefits
- ROI summary (no ML)
- Deployment timeline
- Success metrics

### docs/reference/257_Executive_Summary_ML.md
**Purpose:** Executive summary with ML/RCA  
**Key Content:**
- Strategic overview with ML
- Advanced capabilities
- ML/RCA benefits
- ROI summary (with ML)
- Enterprise considerations

### docs/reference/258_Framework_Statistics.md
**Purpose:** Metrics and statistics  
**Key Content:**
- Framework component counts
- Coverage statistics
- Performance benchmarks
- Success rate metrics

### docs/reference/259_Framework_Diagrams.md
**Purpose:** Visual architecture reference  
**Key Content:**
- Architecture diagrams
- Data flow visualizations
- Integration patterns
- Deployment topology

### docs/reference/260_Native_Integration_Summary.md
**Purpose:** v3.0 → v4.0 upgrade guide  
**Key Content:**
- Native vs custom metrics
- Migration strategy
- Field mapping changes
- Deprecated components
- Upgrade procedures

---

## Part 10: Advanced Topics (docs/advanced/)

### docs/advanced/290_RCA_Advanced.md
**Purpose:** Advanced RCA techniques  
**Key Content:**
- RCA methodology
- Advanced analysis patterns
- Integration strategies

### docs/advanced/291_RCA_Explained.md
**Purpose:** RCA framework explanation  
**Key Content:**
- How RCA works
- Algorithm details
- Use cases and examples
- Benefits and limitations

### docs/advanced/292_RCA_Diagrams.md
**Purpose:** RCA visual reference  
**Key Content:**
- RCA workflow diagrams
- Analysis tree visualizations
- Integration architecture

### docs/advanced/293_ML_RCA_Integration.md
**Purpose:** Machine learning & RCA integration guide  
**Key Content:**
- Infrastructure setup (InfluxDB, Python)
- ML model implementation
- RCA automation
- API integration
- Performance tuning

---

## Quick Navigation by Use Case

### I Need To: Monitor Device Health
**Files:**
- docs/core/10_OPS_STAT_RISK_Core_Metrics.md
- docs/automation/150_Compound_Conditions.md
- docs/reference/255_Quick_Reference.md

**Scripts:**
- docs/scripts/80_Scripts_Monitoring_01_to_13.md

### I Need To: Detect Configuration Drift
**Files:**
- docs/core/12_DRIFT_CAP_BAT_Core_Monitoring.md
- docs/automation/150_Compound_Conditions.md

**Scripts:**
- docs/scripts/83_Scripts_Automation_14_to_27.md
- docs/scripts/90_Scripts_Baseline_Refresh.md

### I Need To: Track Security Posture
**Files:**
- docs/core/14_BASE_SEC_UPD_Core_Security_Baseline.md
- docs/automation/150_Compound_Conditions.md

**Scripts:**
- docs/scripts/83_Scripts_Automation_14_to_27.md

### I Need To: Monitor Servers (IIS, SQL, etc.)
**Files:**
- docs/core/15_Server_Roles_Database_Web.md
- docs/core/16_Server_Roles_Infrastructure.md
- docs/core/17_Server_Roles_Additional.md

**Scripts:**
- docs/scripts/80_Scripts_Monitoring_01_to_13.md

### I Need To: Plan Capacity & Predict Failures
**Files:**
- docs/core/12_DRIFT_CAP_BAT_Core_Monitoring.md

**Scripts:**
- docs/scripts/86_Scripts_Capacity_Predictive.md

### I Need To: Improve User Experience
**Files:**
- docs/core/11_AUTO_UX_SRV_Core_Experience.md

**Scripts:**
- docs/scripts/82_Scripts_Automation_14_to_20.md

### I Need To: Automate Patching
**Files:**
- docs/patching/45_Patching_Framework_Main.md
- docs/patching/46_Patching_Custom_Fields.md
- docs/patching/47_Patching_Quick_Start.md
- docs/patching/48_Patching_Ring_Deployment.md

**Scripts:**
- docs/patching/52_Patching_Scripts.md

**Conditions:**
- docs/automation/150_Compound_Conditions.md (Patch-related conditions)

---

## Deployment Phases

### Phase 1: Core Monitoring (Week 1-2)
**Deploy:**
- docs/core/10_OPS_STAT_RISK_Core_Metrics.md (35 core fields)
- docs/scripts/80_Scripts_Monitoring_01_to_13.md (core monitoring)
- 20 P1/P2 critical conditions
- 10 essential groups

**Actions:**
- Create custom fields
- Deploy monitoring scripts
- Configure native monitoring
- Test on pilot group (10-20 devices)

### Phase 2: Extended Intelligence (Week 3-4)
**Deploy:**
- docs/core/11-14_*.md (26 extended fields)
- docs/scripts/83_Scripts_Automation_14_to_27.md (automation + telemetry)
- 40 P1/P2/P3 conditions
- 30 groups

**Actions:**
- Add extended fields
- Deploy automation scripts
- Expand to 25% of fleet
- Validate alert accuracy

### Phase 3: Server Infrastructure (Week 4-5)
**Deploy:**
- docs/core/15-17_Server_Roles_*.md (117 server fields as needed)
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
- docs/patching/46_Patching_Custom_Fields.md (8 PATCH fields)
- docs/patching/52_Patching_Scripts.md (PR1, PR2, P1-P4)
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

### Directory Organization

- **Root:** Foundation files (00, 01, README)
- **docs/core/:** Custom field definitions (10-17)
- **docs/patching/:** Patching framework (45-53)
- **docs/scripts/:** PowerShell scripts (80-99, 100-101 deprecated)
- **docs/health-checks/:** Health check templates (115-117)
- **docs/automation/:** Conditions & groups (150-152)
- **docs/roi/:** ROI analysis (185-186)
- **docs/training/:** Training materials (220-223)
- **docs/reference/:** Quick references & summaries (255-260)
- **docs/advanced/:** ML/RCA advanced topics (290-293)

### File Numbering System

- **00-09:** Foundation & Architecture (root)
- **10-17:** Core & Server Custom Fields (docs/core/)
- **45-53:** Patching Framework (docs/patching/)
- **80-99:** Scripts (docs/scripts/)
- **115-117:** Health Checks (docs/health-checks/)
- **150-152:** Automation (docs/automation/)
- **185-186:** ROI (docs/roi/)
- **220-223:** Training (docs/training/)
- **255-260:** Reference (docs/reference/)
- **290-293:** Advanced (docs/advanced/)

---

## Complete File Listing by Directory

### Root Directory
1. 00_README.md
2. 01_Framework_Architecture.md
3. README.md (this file - previously 02_Master_Index.md)

### docs/core/
4. 10_OPS_STAT_RISK_Core_Metrics.md
5. 11_AUTO_UX_SRV_Core_Experience.md
6. 12_DRIFT_CAP_BAT_Core_Monitoring.md
7. 13_NET_GPO_AD_Core_Network_Identity.md
8. 14_BASE_SEC_UPD_Core_Security_Baseline.md
9. 15_Server_Roles_Database_Web.md
10. 16_Server_Roles_Infrastructure.md
11. 17_Server_Roles_Additional.md

### docs/patching/
12. 45_Patching_Framework_Main.md
13. 46_Patching_Custom_Fields.md
14. 47_Patching_Quick_Start.md
15. 48_Patching_Ring_Deployment.md
16. 49_Patching_Windows_Tutorial.md
17. 50_Patching_Software_Tutorial.md
18. 51_Patching_Policy_Guide.md
19. 52_Patching_Scripts.md
20. 53_Patching_Summary.md

### docs/scripts/
21. 80_Scripts_Monitoring_01_to_13.md
22. 81_Scripts_Fields_14_to_20.md
23. 82_Scripts_Automation_14_to_20.md
24. 83_Scripts_Automation_14_to_27.md
25. 84_Scripts_Automation_19_to_24.md
26. 85_Scripts_Telemetry_28_to_36.md
27. 86_Scripts_Capacity_Predictive.md
28. 90_Scripts_Baseline_Refresh.md
29. 91_Scripts_Emergency_Cleanup.md
30. 92_Scripts_Memory_Optimization.md
31. 93_Scripts_Field_Mapping.md
32. 95_Scripts_Service_Print_Spooler.md
33. 96_Scripts_Service_Windows_Update.md
34. 97_Scripts_Service_DNS_Client.md
35. 98_Scripts_Service_Network.md
36. 99_Scripts_Service_Remote_Desktop.md
37. 100_Scripts_03_to_08_Part1_DEPRECATED.md
38. 101_Scripts_07_to_12_Part2_DEPRECATED.md

### docs/health-checks/
39. 115_Health_Checks_Quick_Reference.md
40. 116_Health_Checks_Templates.md
41. 117_Health_Checks_Summary.md

### docs/automation/
42. 150_Compound_Conditions.md
43. 151_Dynamic_Groups.md
44. 152_Framework_Master_Summary.md

### docs/roi/
45. 185_ROI_Analysis_No_ML.md
46. 186_ROI_Analysis_With_ML.md

### docs/training/
47. 220_Training_Part1_Fundamentals.md
48. 221_Training_Part2_Advanced.md
49. 222_Training_ML_Integration.md
50. 223_Troubleshooting_Guide.md

### docs/reference/
51. 255_Quick_Reference.md
52. 256_Executive_Summary_Core.md
53. 257_Executive_Summary_ML.md
54. 258_Framework_Statistics.md
55. 259_Framework_Diagrams.md
56. 260_Native_Integration_Summary.md

### docs/advanced/
57. 290_RCA_Advanced.md
58. 291_RCA_Explained.md
59. 292_RCA_Diagrams.md
60. 293_ML_RCA_Integration.md

---

## Version Information

**Framework Version:** 4.0  
**Release Date:** February 2, 2026  
**Status:** Production Ready  
**Recommended For:** All new NinjaOne deployments

### Version 4.0 Highlights

- 277 custom intelligence fields
- 110 PowerShell scripts (26,400 LOC)
- 75 hybrid compound conditions
- 74 dynamic groups
- Native NinjaOne metric integration (12 core metrics)
- Ring-based patching automation
- ML/RCA optional capabilities
- 70% reduction in false positives
- 4-week core deployment (8 weeks with patching)
- Complete documentation suite (60 files)
- Organized directory structure

---

## Support & Maintenance

**Documentation Updates:** All files include timestamp and version number  
**Framework Support:** See docs/automation/152_Framework_Master_Summary.md  
**Deployment Assistance:** See docs/training/* for guides and templates  
**Custom Modifications:** Document in local files for team reference

---

**File:** README.md (formerly 02_Master_Index.md)  
**Version:** 4.0  
**Last Updated:** February 2, 2026, 2:07 AM CET  
**Total Documentation:** 60 files  
**Status:** Production Ready
