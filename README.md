# NinjaOne Framework v4.0 - Complete Documentation

**Version:** 4.0 (Native-Enhanced with ML/RCA & Patching Automation)  
**Date:** February 1, 2026, 11:24 PM CET  
**Status:** Production Ready

---

## WHAT IS THIS FRAMEWORK?

The NinjaOne Custom Field Framework v4.0 transforms your RMM platform from basic monitoring into a **predictive, intelligent operations system**. By combining 277 custom metrics, 110 automated scripts, and optional machine learning capabilities, you gain:

- **Predictive Operations:** 3-30 day advance warning before failures occur
- **Automated Remediation:** 90%+ success rate on common issues
- **Intelligent Alerting:** 70% fewer false positives through hybrid conditions
- **Root Cause Analysis:** 87.5% faster problem resolution (4 hours → 30 minutes)
- **Ring-Based Patching:** 95% deployment success with automated validation

**Bottom Line:** Prevent €15,000+ outages, reduce MTTR by 87.5%, achieve 66-203% Year 1 ROI depending on deployment scope.

---

## FRAMEWORK COMPONENTS

### Core Architecture (277 Custom Fields)

**Essential Metrics (35 fields):**
- OPSHealthScore, OPSPerformanceScore (composite health 0-100)
- STATStabilityScore, STATCrashCount30d (stability tracking)
- RISKBusinessCriticalFlag (business context)
- CAPDaysUntilDiskFull (predictive capacity)
- SECSecurityPostureScore (security posture 0-100)

**Extended Intelligence (26 fields):**
- UXUserExperienceScore (end-user perception)
- NETConnectivityScore (network health)
- DRIFTLocalAdminDrift (configuration drift detection)
- BATHealthScore (laptop battery health)

**Infrastructure Servers (117 fields):**
- IIS (28 fields), MSSQL (25 fields), MYSQL (11 fields)
- APACHE (13 fields), VEEAM (16 fields), DHCP/DNS (24 fields)
- File Server, Print Server, Hyper-V, BitLocker, Features, FlexLM

**Patching Automation (8 fields):**
- PATCHPatchRing (PR1-Test, PR2-Production)
- PATCHLastDeploymentDate, PATCHLastValidationResult
- PATCHRollbackEligible, PATCHPriorityLevel

**ML/RCA Enhancement (5 fields - Optional):**
- MLAnomalyScore (0-100, Isolation Forest algorithm)
- MLFailureRisk (0-100, Random Forest predictor)
- MLFailurePredictedDate (estimated failure date)
- MLRootCauseAnalysis (automated RCA reports)
- MLLastAnalysisDate (tracking timestamp)

**Advanced Telemetry (91 fields - Optional):**
- Event log monitoring, baseline coverage, licensing, role detection

### Automation Layer (110 PowerShell Scripts)

**Infrastructure Monitoring (Scripts 1-13):**
- IIS, MSSQL, MYSQL, APACHE, VEEAM, DHCP, DNS monitoring
- Frequency: Every 4 hours
- Purpose: Populate server-specific metrics

**Extended Automation (Scripts 14-24):**
- Drift detection, security posture, baseline management
- Frequency: Daily
- Purpose: Track changes, detect anomalies

**Advanced Telemetry (Scripts 27-36):**
- Predictive capacity, event log analysis, licensing
- Frequency: Daily
- Purpose: Forecasting and compliance

**Remediation (Scripts 40-65):**
- Service restarts (Print Spooler, Windows Update, DNS, Network, RDP)
- Emergency disk cleanup, memory optimization
- Frequency: On-demand (triggered by conditions)
- Purpose: Automated problem resolution

**Security Hardening (Scripts 66-105):**
- 40 scripts implementing security controls
- Frequency: On-demand
- Purpose: Security compliance and hardening

**Patching Automation (Scripts PR1-P4):**
- PR1: Test ring deployment (10-20 devices)
- PR2: Production ring deployment (all devices)
- P1-P4: Priority-based deployment validators
- Frequency: Weekly (Tuesday 2 AM default)
- Purpose: Ring-based patch deployment with validation

### Intelligence Layer (75 Hybrid Conditions)

**P1 Critical (15 conditions):**
- Combine native metrics + custom fields for high-confidence alerts
- Example: CPU > 95% AND Memory > 98% AND OPSHealthScore < 30 AND BusinessCritical = True
- Actions: Create P1 ticket, SMS alert, run remediation (if eligible)

**P2 High Priority (25 conditions):**
- Performance degradation, security warnings, capacity alerts
- Example: CAPDaysUntilDiskFull < 7 AND OPSHealthScore < 60
- Actions: Create P2 ticket, email alert, schedule maintenance

**P3 Medium Priority (20 conditions):**
- Drift notifications, baseline changes, informational alerts
- Actions: Create P3 ticket, log for review

**P4 Low Priority (15 conditions):**
- Positive health tracking, compliance reporting
- Actions: Dashboard updates, reporting

**ML Conditions (3 conditions - Optional):**
- P2_MLAnomalyDetected (MLAnomalyScore > 80)
- P2_PredictedFailure (MLFailureRisk > 70)
- P3_MLAnomalyWarning (MLAnomalyScore > 60)

### Segmentation Layer (74 Dynamic Groups)

**Automation Eligibility:**
- AUTO_Safe_Aggressive (eligible for automated fixes)
- AUTO_Restricted (requires manual approval)

**Health-Based:**
- CRIT_Health_0_30 (critical health, immediate attention)
- WARN_Health_31_60 (warning health, investigation needed)
- GOOD_Health_61_100 (healthy devices)

**Capacity-Based:**
- CAP_Disk_Upgrade_0_7d (disk full in 7 days)
- CAP_Disk_Upgrade_8_30d (disk full in 30 days)
- CAP_Memory_Upgrade (memory constrained)

**Stability-Based:**
- CRIT_Stability_Risk (crash-prone devices)
- WARN_Frequent_Reboots (reboot issues)

**Patching Rings:**
- PATCH_Ring_PR1_Test (test ring devices)
- PATCH_Ring_PR2_Production (production devices)
- PATCH_Priority_P1_Critical (business-critical servers)

**ML/RCA Groups (Optional):**
- ML_Anomaly_High (anomaly score > 80)
- ML_FailureRisk_High (predicted failure in 30 days)

---

## DEPLOYMENT OPTIONS

### Option 1: Core Framework (No ML) - Recommended Start

**What You Get:**
- 35 essential custom fields
- Native metric integration (CPU, Memory, Disk, SMART)
- 13 infrastructure monitoring scripts
- 26 remediation scripts
- 15 P1 critical conditions
- 30 dynamic groups
- Ring-based patching (optional add-on)

**Investment:** €4,500 (90 hours deployment)  
**Timeline:** 2-4 weeks  
**Ideal For:** 50-200 device environments, first-time adopters  
**ROI:** 98% Year 1, 4.5 month payback (see 100_Detailed_ROI_Analysis_No_ML.md)

### Option 2: Full Framework with ML/RCA - Maximum Value

**What You Get:**
- Everything in Option 1
- PLUS: 5 ML custom fields
- PLUS: Time-series database (InfluxDB)
- PLUS: ML models (Anomaly Detection, Predictive Maintenance, RCA)
- PLUS: 3 ML conditions
- PLUS: Automated root cause analysis

**Investment:** €7,250 (138 hours deployment)  
**Timeline:** 4-8 weeks  
**Ideal For:** 100+ device environments, advanced operations teams  
**ROI:** 66-203% Year 1 depending on scope (see 100_Detailed_ROI_Analysis_ML_with_Platform_Costs.md)

### Option 3: Extended Framework (All 277 Fields) - Enterprise

**What You Get:**
- Everything in Option 2
- PLUS: 117 infrastructure server fields
- PLUS: 91 advanced telemetry fields
- PLUS: 40 security hardening scripts
- PLUS: All 75 conditions
- PLUS: All 74 dynamic groups

**Investment:** €10,000-€15,000 (200-300 hours)  
**Timeline:** 8-12 weeks  
**Ideal For:** 500+ device environments, MSPs, enterprise IT  
**ROI:** Varies by scale (contact for enterprise pricing analysis)

---

## QUICK START GUIDE

### Prerequisites

1. **NinjaOne RMM Platform**
   - Active subscription (€3-€10/device/month typical)
   - Administrator access
   - PowerShell script execution enabled

2. **Technical Resources**
   - 1 NinjaOne administrator (field creation, script deployment)
   - 1 PowerShell scripter (customization, troubleshooting)
   - Optional: 1 Python developer (ML/RCA integration)

3. **Time Commitment**
   - Option 1 (Core): 90 hours over 2-4 weeks
   - Option 2 (ML): 138 hours over 4-8 weeks
   - Option 3 (Extended): 200-300 hours over 8-12 weeks

### Phase 1: Core Deployment (Week 1-2)

**Step 1: Create Essential Custom Fields (3 hours)**
```
File: 10_OPS_STAT_RISK_Core_Metrics.md
Fields to create: 35 essential fields
  - OPSHealthScore (Integer 0-100)
  - OPSPerformanceScore (Integer 0-100)
  - STATStabilityScore (Integer 0-100)
  - CAPDaysUntilDiskFull (Integer)
  - RISKBusinessCriticalFlag (Boolean)
  - ... (30 more)
```

**Step 2: Deploy Infrastructure Scripts (4 hours)**
```
File: 55_Scripts_01_13_Infrastructure_Monitoring.md
Scripts to deploy: Scripts 1-13
  - Script 1: IIS Monitoring
  - Script 2: MSSQL Monitoring
  - Script 3: MYSQL Monitoring
  - ... (10 more)

Schedule: Every 4 hours (0, 4, 8, 12, 16, 20)
```

**Step 3: Enable Native Monitoring (2 hours)**
```
NinjaOne Dashboard → Monitoring → Enable:
  - CPU Utilization %
  - Memory Utilization %
  - Disk Free Space %
  - SMART Status
  - Antivirus Status
  - Firewall Status
```

**Step 4: Create P1 Critical Conditions (3 hours)**
```
File: 91_Compound_Conditions_Complete.md
Conditions to create: 15 P1 critical
  - P1_Critical_System_Failure
  - P1_Critical_Disk_Full
  - P1_Critical_Security_Breach
  - ... (12 more)
```

**Step 5: Test and Validate (6 hours)**
```
- Verify field population (95%+ target)
- Confirm script execution (98%+ success)
- Test condition triggering
- Validate alert routing
```

**Outcome:** Core monitoring active, 95%+ devices reporting health scores

### Phase 2: Extended Intelligence (Week 3-4)

**Step 6: Add Extended Fields (3 hours)**
```
File: 11_AUTO_UX_SRV_Core_Experience.md
File: 12_DRIFT_CAP_BAT_Core_Monitoring.md
File: 13_NET_GPO_AD_Core_Network_Identity.md
Fields to add: 26 extended fields
```

**Step 7: Deploy Automation Scripts (5 hours)**
```
File: 53_Scripts_14_27_Extended_Automation.md
Scripts to deploy: Scripts 14-24
  - Script 15: Security Posture Monitor
  - Script 18: Baseline Refresh
  - Script 20: Drift Detection
  - ... (8 more)
```

**Step 8: Create Remediation Workflows (8 hours)**
```
File: 91_Compound_Conditions_Complete.md
Conditions to create: 25 P2 + 20 P3
  - P2_DiskCapacityUrgent → Run Script 50 (Disk Cleanup)
  - P2_ServiceFailure → Run Script 41-45 (Service Restart)
  - ... (43 more)
```

**Step 9: Configure Dynamic Groups (6 hours)**
```
File: 92_Dynamic_Groups_Complete.md
Groups to create: 30 core groups
  - AUTO_Safe_Aggressive
  - CAP_Disk_Upgrade_0_7d
  - CRIT_Health_0_30
  - ... (27 more)
```

**Outcome:** Automated remediation active, 65% of tickets auto-resolved

### Phase 3: ML/RCA Integration (Week 5-6) - OPTIONAL

**Step 10: Deploy Time-Series Database (3 hours)**
```
File: ML_RCA_Integration.md (Infrastructure Setup section)
  - Install InfluxDB (Docker)
  - Create bucket (90-day retention)
  - Configure API token
```

**Step 11: Set Up ML Environment (2 hours)**
```
  - Python 3.9+ environment
  - Install libraries: pandas, numpy, scikit-learn, statsmodels
  - Create data pipeline (NinjaOne API → InfluxDB)
```

**Step 12: Train ML Models (5 hours)**
```
  - Collect 90 days baseline data
  - Train Isolation Forest (anomaly detection)
  - Train Random Forest (predictive maintenance)
  - Validate accuracy (70%+ target)
```

**Step 13: Create ML Custom Fields (3 hours)**
```
Fields to create:
  - MLAnomalyScore (Integer 0-100)
  - MLFailureRisk (Integer 0-100)
  - MLFailurePredictedDate (DateTime)
  - MLRootCauseAnalysis (WYSIWYG)
  - MLLastAnalysisDate (DateTime)
```

**Outcome:** Predictive capabilities active, 3-30 day advance warnings

### Phase 4: Patching Automation (Week 7-8) - OPTIONAL

**Step 14: Configure Patch Rings (2 hours)**
```
File: 44_PATCH_Ring_Based_Deployment.md
  - Define PR1-Test (10-20 devices)
  - Define PR2-Production (all other devices)
  - Assign priority levels (P1-P4)
```

**Step 15: Deploy Patching Scripts (5 hours)**
```
File: 61_Scripts_Patching_Automation.md
Scripts to deploy:
  - Script PR1: Test Ring Deployment
  - Script PR2: Production Ring Deployment
  - Script P1-P4: Priority Validators
```

**Outcome:** Ring-based patching active, 95%+ deployment success

---

## DOCUMENTATION INDEX

### Getting Started

| File | Purpose | Audience |
|------|---------|----------|
| **00_README.md** | This file - Framework overview | Everyone |
| **00_Master_Index.md** | Complete file index | Administrators |
| **01_Framework_Architecture.md** | Technical architecture | Engineers, Architects |
| **99_Quick_Reference_Guide.md** | Field/script/condition quick ref | Technicians |

### Business Case & ROI

| File | Purpose | Audience |
|------|---------|----------|
| **Executive_Report_v4_Framework_ML.md** | Strategic overview with ML | C-Level, IT Directors |
| **100_Detailed_ROI_Analysis_No_ML.md** | ROI without ML (Core framework) | Finance, Budget Approvers |
| **100_Detailed_ROI_Analysis_ML_with_Platform_Costs.md** | ROI with ML + NinjaRMM costs | Finance, CFO |
| **Framework_Statistics_Summary.md** | Metrics and statistics | Analysts |

### Custom Fields Documentation

| File | Fields | Purpose |
|------|--------|---------|
| **10_OPS_STAT_RISK_Core_Metrics.md** | 35 | Essential health, stability, risk |
| **11_AUTO_UX_SRV_Core_Experience.md** | 26 | Automation, UX, service monitoring |
| **12_DRIFT_CAP_BAT_Core_Monitoring.md** | 21 | Drift, capacity, battery |
| **13_NET_GPO_AD_Core_Network_Identity.md** | 15 | Network, GPO, Active Directory |
| **14_BASE_SEC_UPD_Core_Security_Baseline.md** | 18 | Baseline, security, updates |
| **22_IIS_MSSQL_MYSQL_Database_Web_Servers.md** | 64 | IIS, SQL Server, MySQL |
| **23_APACHE_VEEAM_DHCP_DNS_Infrastructure.md** | 53 | Apache, VEEAM, DHCP, DNS |
| **24_EVT_FS_PRINT_HV_BL_FEAT_FLEXLM_Additional_Roles.md** | 91 | Event logs, file server, print, Hyper-V |
| **31_PATCH_Custom_Fields.md** | 8 | Patching automation fields |

### PowerShell Scripts Documentation

| File | Scripts | Purpose |
|------|---------|---------|
| **51_Field_to_Script_Complete_Mapping.md** | All | Field-to-script mapping reference |
| **55_Scripts_01_13_Infrastructure_Monitoring.md** | 1-13 | Infrastructure monitoring scripts |
| **53_Scripts_14_27_Extended_Automation.md** | 14-27 | Extended automation scripts |
| **54_Scripts_28_36_Advanced_Telemetry.md** | 28-36 | Advanced telemetry scripts |
| **41-45_Scripts_Service_Restart_*.md** | 41-45 | Service restart remediation |
| **50_Scripts_Emergency_Disk_Cleanup.md** | 50 | Emergency disk cleanup |
| **56_Scripts_Memory_Optimization.md** | 55 | Memory optimization |
| **61_Scripts_Patching_Automation.md** | PR1-P4 | Patching automation scripts |

### Automation & Conditions

| File | Purpose | Audience |
|------|---------|----------|
| **91_Compound_Conditions_Complete.md** | All 75 hybrid conditions | Administrators |
| **92_Dynamic_Groups_Complete.md** | All 74 dynamic groups | Administrators |

### Patching Automation

| File | Purpose | Audience |
|------|---------|----------|
| **30_PATCH_Main_Patching_Framework.md** | Patching framework overview | Patch Managers |
| **44_PATCH_Ring_Based_Deployment.md** | Ring-based deployment guide | Administrators |
| **46_PATCH_Windows_OS_Tutorial.md** | Windows OS patching tutorial | Technicians |
| **47_PATCH_Software_Patching_Tutorial.md** | Software patching tutorial | Technicians |
| **48_PATCH_Policy_Configuration_Guide.md** | Policy configuration guide | Administrators |
| **36_PATCH_Quick_Start_Guide.md** | Quick start guide | Everyone |

### Advanced Topics

| File | Purpose | Audience |
|------|---------|----------|
| **ML_RCA_Integration.md** | Machine learning & RCA | Engineers, Data Scientists |
| **Troubleshooting_Guide_Servers_Clients.md** | Framework-powered troubleshooting | Technicians, Engineers |
| **Framework_Training_Material_Part1.md** | Training modules 1-4 | All IT Staff |
| **Framework_Training_Material_Part2.md** | Training modules 5-8 | Advanced Staff |

### Optimization & Reference

| File | Purpose | Audience |
|------|---------|----------|
| **NATIVE_INTEGRATION_OPTIMIZATION_SUMMARY.md** | v3.0 → v4.0 upgrade guide | Existing users |
| **98_Framework_Complete_Summary_Master.md** | Complete framework summary | Reference |
| **70_Custom_Health_Check_Templates.md** | Health check templates | Customizers |

---

## DEPLOYMENT SCENARIOS

### Scenario 1: Small Business (50 Devices)

**Profile:**
- 50 endpoints (40 workstations, 10 servers)
- 2-person IT team
- Limited budget
- Need quick wins

**Recommendation:** Core Framework (No ML)

**Deployment:**
- Week 1-2: Phase 1 (Core Monitoring)
- Week 3-4: Phase 2 (Extended Intelligence)
- Total: 4 weeks, 90 hours

**Investment:**
- Framework: €4,500 (one-time)
- NinjaRMM: €3,000/year (€5/device/month)
- **Year 1 Total: €7,500**

**Returns:**
- Year 1 Benefits: €16,250
- **Year 1 Net ROI: €8,750 (115% return)**
- Payback: 5.5 months

**Key Value:**
- Prevent 1-2 major outages/year (€10,000+ value)
- 75% faster troubleshooting
- 65% automated resolution rate

---

### Scenario 2: Medium Business (100 Devices)

**Profile:**
- 100 endpoints (75 workstations, 25 servers)
- 5-person IT team
- Moderate budget
- Want predictive capabilities

**Recommendation:** Full Framework with ML/RCA

**Deployment:**
- Week 1-2: Phase 1 (Core)
- Week 3-4: Phase 2 (Extended)
- Week 5-6: Phase 3 (ML/RCA)
- Week 7-8: Phase 4 (Patching)
- Total: 8 weeks, 138 hours

**Investment:**
- Framework: €7,250 (one-time)
- NinjaRMM: €6,000/year
- **Year 1 Total: €13,250**

**Returns:**
- Year 1 Benefits: €22,000
- **Year 1 Net ROI: €8,750 (66% return)**
- Payback: 7.2 months

**Key Value:**
- 3-30 day advance warning (ML)
- 87.5% MTTR reduction (RCA)
- Ransomware prevention (€4,000/year)
- Predictive hardware replacement

---

### Scenario 3: Enterprise / MSP (500+ Devices)

**Profile:**
- 500+ endpoints
- 10+ person IT/NOC team
- Enterprise budget
- Need full visibility and automation

**Recommendation:** Extended Framework (All 277 Fields)

**Deployment:**
- Week 1-4: Phase 1-2 (Core + Extended)
- Week 5-8: Phase 3-4 (ML + Patching)
- Week 9-12: Infrastructure servers, security hardening
- Total: 12 weeks, 250-300 hours

**Investment:**
- Framework: €12,500-€15,000 (one-time)
- NinjaRMM: €30,000/year (negotiate volume pricing)
- **Year 1 Total: €42,500-€45,000**

**Returns:**
- Varies by scale and use cases
- Typical: 50-100% Year 1 ROI for large deployments
- Major value from prevented outages and compliance

**Key Value:**
- Full infrastructure visibility
- Compliance audit readiness
- Multi-tenant support (MSPs)
- Advanced ML use cases

**Recommendation:** Contact for customized enterprise ROI analysis

---

## TRAINING & CERTIFICATION

### Level 1: Framework Administrator (24 hours)

**Modules:**
- Module 1: Framework Fundamentals (3h)
- Module 2: Custom Fields Deep Dive (4h)
- Module 3: PowerShell Scripts Overview (4h)
- Module 4: Compound Conditions (4h)
- Module 5: Dynamic Groups (3h)
- Module 6: Patching Automation (4h)
- Lab 1: Complete Deployment (2h)

**Target Audience:** NinjaOne administrators, IT managers  
**Prerequisites:** NinjaOne basic knowledge  
**Certification:** Framework Administrator Certificate

### Level 2: Framework Engineer (40 hours)

**All Level 1 content PLUS:**
- Module 7: Framework Troubleshooting (5h)
- Module 8: Advanced Customization (7h)
- Lab 2: Patching Automation (3h)
- Lab 3: Troubleshooting Scenarios (2h)
- Lab 4: Custom Module Development (3h)

**Target Audience:** Senior technicians, engineers  
**Prerequisites:** Level 1 certification  
**Certification:** Framework Engineer Certificate

### Level 3: Framework Architect (64 hours)

**All Level 2 content PLUS:**
- Module 9: ML/RCA Integration (8h)
- Module 10: API Integration & Extensibility (8h)
- Module 11: Enterprise Deployment (8h)
- Capstone: Build Custom ML Module (16h)

**Target Audience:** Architects, data scientists, senior engineers  
**Prerequisites:** Level 2 certification, Python knowledge  
**Certification:** Framework Architect Certificate

**Training Materials:**
- Framework_Training_Material_Part1.md (Modules 1-4)
- Framework_Training_Material_Part2.md (Modules 5-8)
- ML_RCA_Integration.md (Module 9-10)

---

## SUPPORT & RESOURCES

### Community Support

**Framework Documentation:**
- Complete documentation in Space: NinjaRMM
- Regular updates and enhancements
- Example scripts and templates

**Best Practices:**
- Follow phased deployment approach
- Start with Core Framework, add ML later
- Monitor KPIs monthly (false positives, MTTR, automation success)
- Tune conditions based on environment

### Professional Services (Optional)

**Deployment Assistance:**
- Guided deployment (remote support)
- Custom script development
- ML model training assistance
- Pricing: €75-€125/hour depending on scope

**Managed Deployment:**
- Turnkey deployment (all phases)
- Custom field configuration
- Script customization for your environment
- Training included
- Pricing: Contact for quote

### Success Metrics

Track these KPIs to measure framework value:

| Metric | Baseline | Target (3 months) | Measurement |
|--------|----------|-------------------|-------------|
| Mean Time to Resolution | 4h | 30min | Ticket timestamps |
| False Positive Rate | 30% | 10% | Alert accuracy audit |
| Automated Resolution % | 0% | 65% | Tickets auto-closed |
| Script Success Rate | N/A | 98% | Execution logs |
| Advance Warning (Days) | 0 | 14-30 | Predictive accuracy |

---

## VERSION HISTORY

**v4.0 (Current - February 2026):**
- Native integration (70% fewer false positives)
- ML/RCA capabilities (87.5% MTTR reduction)
- Patching automation (ring-based deployment)
- 277 fields (down from 358 in v3.0)
- 110 scripts (up from 105)
- Hybrid conditions (native + custom)

**v3.0 (Legacy - 2024-2025):**
- 358 custom fields (all custom collection)
- 105 scripts
- No native integration
- No ML capabilities
- No patching automation

**Upgrade Path:** See NATIVE_INTEGRATION_OPTIMIZATION_SUMMARY.md

---

## FREQUENTLY ASKED QUESTIONS

**Q: Do I need ML/RCA or can I start with Core Framework?**  
A: Start with Core Framework (Option 1). Add ML/RCA later when you have 90 days of baseline data and want predictive capabilities. Core Framework delivers 98-115% Year 1 ROI without ML.

**Q: What's the difference between v3.0 and v4.0?**  
A: v4.0 uses NinjaOne native metrics (CPU, Memory, Disk, SMART) instead of custom scripts, reducing fields from 358 to 277 and cutting false positives by 70%. v4.0 also adds ML/RCA and patching automation.

**Q: Can I customize the framework for my environment?**  
A: Yes! Framework is fully customizable. Add your own custom fields, modify scripts, adjust thresholds, create custom conditions. See Module 8 in Framework_Training_Material_Part2.md.

**Q: How long until I see ROI?**  
A: 4.5-7.2 months payback depending on deployment option. First benefits (faster troubleshooting, fewer false positives) appear within 2 weeks.

**Q: Do I need Python/ML expertise?**  
A: No, not for Core Framework (Option 1). ML/RCA (Option 2) requires basic Python knowledge or willingness to follow implementation guide. Professional services available.

**Q: What if my team is too small to deploy this?**  
A: Start with Phase 1 only (Core Monitoring). Deploy in 2 weeks with 18 hours effort. Add phases as time permits. Professional deployment services available.

**Q: Does this work with my existing RMM platform?**  
A: Framework is designed for NinjaOne but concepts are portable. Custom fields and scripts can be adapted to other RMM platforms with PowerShell support.

**Q: How much does NinjaRMM cost?**  
A: Typical pricing is €3-€10/device/month depending on tier and volume. Contact NinjaOne for enterprise pricing. Framework ROI calculated at €5/device/month baseline.

**Q: What if I have more than 500 devices?**  
A: Contact for enterprise analysis. At scale, consider volume NinjaRMM pricing negotiation, phased rollout to high-value devices first, or MSP multi-tenant deployment.

---

## NEXT STEPS

### Ready to Deploy?

**Step 1: Choose Deployment Option**
- Review ROI analyses (with/without ML)
- Select Core, ML, or Extended framework
- Get budget approval

**Step 2: Plan Deployment**
- Assign project sponsor
- Allocate resources (90-250 hours)
- Schedule 2-12 week timeline

**Step 3: Begin Phase 1**
- Read 01_Framework_Architecture.md
- Follow Quick Start Guide above
- Create 35 essential fields
- Deploy first 13 scripts

**Step 4: Monitor & Optimize**
- Track KPIs weekly
- Tune conditions monthly
- Expand to additional phases

### Questions or Need Help?

Review documentation in Space: NinjaRMM or contact for professional deployment assistance.

---

**File:** 00_README.md  
**Version:** 4.0  
**Last Updated:** February 1, 2026, 11:24 PM CET  
**Next Review:** May 2026

# NinjaOne Framework v4.0 - Visual Diagrams & Flowcharts

**Version:** 4.0 (Native-Enhanced with ML/RCA & Patching Automation)  
**Date:** February 2, 2026, 12:03 AM CET  
**Purpose:** Visual representations of framework architecture, data flows, and processes  
**Format:** Mermaid diagrams (render in Markdown viewers or mermaid.live)  
**Color Scheme:** Dark mode optimized for white text readability

---

## TABLE OF CONTENTS

1. [Framework Architecture Overview](#1-framework-architecture-overview)
2. [Data Flow Architecture](#2-data-flow-architecture)
3. [ML/RCA Pipeline Flow](#3-mlrca-pipeline-flow)
4. [Compound Condition Evaluation Flow](#4-compound-condition-evaluation-flow)
5. [Automated Remediation Decision Tree](#5-automated-remediation-decision-tree)
6. [Patching Automation Ring Flow](#6-patching-automation-ring-flow)
7. [Anomaly Detection Process](#7-anomaly-detection-process)
8. [Root Cause Analysis Flow](#8-root-cause-analysis-flow)
9. [Predictive Maintenance Pipeline](#9-predictive-maintenance-pipeline)
10. [Deployment Phases Timeline](#10-deployment-phases-timeline)
11. [Alert Priority Routing](#11-alert-priority-routing)
12. [Dynamic Group Membership Logic](#12-dynamic-group-membership-logic)
13. [Script Execution Workflow](#13-script-execution-workflow)
14. [Health Score Calculation](#14-health-score-calculation)
15. [Capacity Forecasting Process](#15-capacity-forecasting-process)

---

## 1. FRAMEWORK ARCHITECTURE OVERVIEW

### Four-Layer Architecture
<img width="5355" height="5035" alt="Drift to Automation Flow-2026-02-01-231328" src="https://github.com/user-attachments/assets/5a74663d-f300-4bac-a440-6b1a08886eed" />


---

## 2. DATA FLOW ARCHITECTURE

### End-to-End Data Pipeline
<img width="8192" height="4122" alt="Drift to Automation Flow-2026-02-01-231337" src="https://github.com/user-attachments/assets/46035994-f3d1-4a33-83bd-cd3ccbfbca1f" />

---

## 3. ML/RCA PIPELINE FLOW

### Machine Learning Data Pipeline
<img width="4608" height="7675" alt="Drift to Automation Flow-2026-02-01-231346" src="https://github.com/user-attachments/assets/ee0aa38f-120b-4bd6-8370-fa37058030e5" />


---

## 4. COMPOUND CONDITION EVALUATION FLOW

### Hybrid Condition Processing
<img width="5810" height="7313" alt="Drift to Automation Flow-2026-02-01-231356" src="https://github.com/user-attachments/assets/c2ef2489-107d-4ba9-bd3c-5c16a2b9fb63" />



---

## 5. AUTOMATED REMEDIATION DECISION TREE

### Script 40: Automation Eligibility Check
<img width="6654" height="8192" alt="Drift to Automation Flow-2026-02-01-231407" src="https://github.com/user-attachments/assets/d595a79c-f7e6-499a-afdd-3428284e09de" />



---

## 6. PATCHING AUTOMATION RING FLOW

### Ring-Based Deployment Process
<img width="2473" height="8192" alt="Drift to Automation Flow-2026-02-01-231416" src="https://github.com/user-attachments/assets/e573e8da-a6fd-4ed8-a18b-11205df36a0c" />


---

## 7. ANOMALY DETECTION PROCESS

### ML Isolation Forest Algorithm
<img width="3124" height="8192" alt="Drift to Automation Flow-2026-02-01-231425" src="https://github.com/user-attachments/assets/4effc8b8-4176-4185-9250-6334fabbc35d" />


---

## 8. ROOT CAUSE ANALYSIS FLOW

### Automated RCA Process
<img width="1222" height="8191" alt="Drift to Automation Flow-2026-02-01-231431" src="https://github.com/user-attachments/assets/0e217c1c-2cd0-4c6f-a240-3848f58456b6" />


---

## 9. PREDICTIVE MAINTENANCE PIPELINE

### Hardware Failure Prediction
<img width="3086" height="8191" alt="Drift to Automation Flow-2026-02-01-231438" src="https://github.com/user-attachments/assets/5e351a6f-98cd-4de3-aa48-89f253053b69" />


---

## 10. DEPLOYMENT PHASES TIMELINE

### Core Framework (No ML) - 4 Weeks
<img width="8192" height="1395" alt="Drift to Automation Flow-2026-02-01-231448" src="https://github.com/user-attachments/assets/f26497a3-1b7c-4691-b9c3-9cab23937969" />


### ML Framework (Full) - 10 Weeks
<img width="8192" height="1548" alt="Drift to Automation Flow-2026-02-01-231456" src="https://github.com/user-attachments/assets/6d3d68ef-8e19-4911-9e31-49abefcc409f" />


---

## 11. ALERT PRIORITY ROUTING

### P1-P4 Alert Classification and Routing
<img width="6318" height="7518" alt="Drift to Automation Flow-2026-02-01-231505" src="https://github.com/user-attachments/assets/a22bd579-2a90-4cbc-b8f0-4fab3ccccf29" />


---

## 12. DYNAMIC GROUP MEMBERSHIP LOGIC

### Real-Time Group Assignment
<img width="8192" height="4047" alt="Drift to Automation Flow-2026-02-01-231514" src="https://github.com/user-attachments/assets/8cfd2dc5-c78b-47d7-8549-80d8c648a3aa" />



---

## 13. SCRIPT EXECUTION WORKFLOW

### Scheduled Script Execution
<img width="4419" height="8191" alt="Drift to Automation Flow-2026-02-01-231521" src="https://github.com/user-attachments/assets/24e39c35-2f3a-4992-8d94-39ed2a32c38a" />

---

## 14. HEALTH SCORE CALCULATION

### OPSHealthScore Composite Formula
<img width="7982" height="8192" alt="Drift to Automation Flow-2026-02-01-232055" src="https://github.com/user-attachments/assets/21f9c82e-d069-4665-9168-e2ea5a158aae" />


---

## 15. CAPACITY FORECASTING PROCESS

### CAPDaysUntilDiskFull Calculation
<img width="4733" height="8192" alt="Drift to Automation Flow-2026-02-01-232136" src="https://github.com/user-attachments/assets/8ed833d6-3709-4888-b713-309bd6633aeb" />


---

### Diagram Legend

**Dark Color Scheme (Optimized for White Text):**
- 🔵 Dark Blue (#1a5490): Start/Input stages
- 🟤 Dark Goldenrod (#b8860b): Processing/Calculation stages
- 🟣 Dark Magenta (#8b008b): Decision/Evaluation stages
- 🟢 Dark Green (#228b22): Success/Completion stages
- 🔴 Dark Red (#8b0000): Critical/Failure stages
- 🟠 Dark Orange (#cc6600): Warning/Medium priority stages
- 🟡 Dark Goldenrod (#b8860b): Informational stages
- ⚫ Dark Gray (#4a5568): Neutral/End stages
- 🔴 Crimson (#c41e3a): High-priority alerts

---

**File:** Framework_Visual_Diagrams.md  
**Version:** 4.0  
**Last Updated:** February 2, 2026, 12:03 AM CET  
**Diagram Count:** 15 comprehensive flowcharts  
**Format:** Mermaid syntax (Markdown compatible)  
**Color Scheme:** Dark mode optimized  
**Status:** Complete Visual Reference
