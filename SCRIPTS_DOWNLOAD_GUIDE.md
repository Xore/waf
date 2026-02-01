# NinjaOne Framework v4.0 - Complete PowerShell Scripts Download Guide

**Date:** February 2, 2026  
**Framework Version:** 4.0 (Native-Enhanced with ML/RCA & Patching Automation)  
**Total Scripts:** 110 PowerShell scripts  
**Status:** Production Ready

---

## Quick Start - Download All Scripts

### Option 1: Clone the Repository (Recommended)
```bash
git clone https://github.com/Xore/waf.git
cd waf/scripts
```

### Option 2: Download ZIP Archive
1. Go to [https://github.com/Xore/waf](https://github.com/Xore/waf)
2. Click **Code** button
3. Select **Download ZIP**
4. Extract and navigate to `scripts/` directory

### Option 3: Download Individual Scripts
Visit: [https://github.com/Xore/waf/tree/main/scripts](https://github.com/Xore/waf/tree/main/scripts)

---

## Script Organization

All 110 scripts are organized in the following structure:

```
scripts/
├── README.md                          # Overview and usage guide
├── Core_Monitoring/                   # Scripts 1-13
│   ├── Script_01_Health_Score_Calculator.ps1
│   ├── Script_02_Stability_Analyzer.ps1
│   ├── Script_03_Performance_Analyzer.ps1
│   ├── Script_04_Security_Analyzer.ps1
│   ├── Script_05_Capacity_Analyzer.ps1
│   ├── Script_06_Telemetry_Collector.ps1
│   ├── Script_09_Risk_Classifier.ps1
│   ├── Script_10_Update_Assessment_Collector.ps1
│   ├── Script_11_Network_Location_Tracker.ps1
│   ├── Script_12_Baseline_Manager.ps1
│   └── Script_13_Drift_Detector.ps1
│
├── Extended_Automation/               # Scripts 14-27
│   ├── Script_14_Local_Admin_Drift_Analyzer.ps1
│   ├── Script_15_Security_Posture_Consolidator.ps1
│   ├── Script_16_Suspicious_Login_Pattern_Detector.ps1
│   ├── Script_17_Application_Experience_Profiler.ps1
│   ├── Script_18_Profile_Hygiene_Cleanup_Advisor.ps1
│   ├── Script_19_Chronic_Slow_Boot_Detector.ps1
│   ├── Script_20_Software_Inventory_Shadow_IT_Detector.ps1
│   ├── Script_21_Critical_Service_Configuration_Drift_Monitor.ps1
│   ├── Script_22_Capacity_Trend_Forecaster.ps1
│   ├── Script_23_Patch_Compliance_Aging_Analyzer.ps1
│   ├── Script_24_Device_Lifetime_Replacement_Predictor.ps1
│   └── Script_27_Telemetry_Freshness_Monitor.ps1
│
├── Advanced_Telemetry/               # Scripts 28-36
│   ├── Script_28_Security_Surface_Telemetry.ps1
│   ├── Script_29_Collaboration_Outlook_UX_Telemetry.ps1
│   ├── Script_30_User_Environment_Friction_Tracker.ps1
│   ├── Script_31_Remote_Connectivity_SaaS_Quality_Telemetry.ps1
│   ├── Script_32_Thermal_Firmware_Telemetry.ps1
│   ├── Script_34_Licensing_Feature_Utilization_Telemetry.ps1
│   └── Script_35_Baseline_Coverage_Drift_Density_Telemetry.ps1
│
├── Server_Roles/                     # Scripts 51-110
│   ├── IIS_Web_Servers/
│   │   ├── Script_51_IIS_Health_Monitor.ps1
│   │   ├── Script_52_IIS_Application_Pool_Monitor.ps1
│   │   ├── Script_53_IIS_Site_Monitor.ps1
│   │   ├── Script_54_IIS_Request_Performance.ps1
│   │   └── Script_55_IIS_Error_Rate_Monitor.ps1
│   │
│   ├── SQL_Servers/
│   │   ├── Script_61_MSSQL_Server_Health.ps1
│   │   ├── Script_62_MSSQL_Database_Monitor.ps1
│   │   ├── Script_63_MSSQL_Query_Performance.ps1
│   │   ├── Script_71_MySQL_Server_Health.ps1
│   │   └── Script_72_MySQL_Database_Monitor.ps1
│   │
│   ├── Infrastructure_Services/
│   │   ├── Script_81_Apache_Web_Server_Health.ps1
│   │   ├── Script_82_Veeam_Backup_Monitor.ps1
│   │   ├── Script_83_DHCP_Server_Health.ps1
│   │   ├── Script_84_DNS_Server_Health.ps1
│   │   ├── Script_91_Event_Log_Collector.ps1
│   │   ├── Script_92_File_Server_Share_Monitor.ps1
│   │   └── Script_93_Print_Server_Queue_Monitor.ps1
│   │
│   └── Advanced_Features/
│       ├── Script_101_HyperV_Host_Monitor.ps1
│       ├── Script_102_BitLocker_Encryption_Status.ps1
│       ├── Script_103_Windows_Features_Monitor.ps1
│       └── Script_110_FlexLM_License_Server_Monitor.ps1
│
└── Patching_Automation/              # Patch Ring Scripts
    ├── Script_PR1_Patch_Ring_Test_Deployment.ps1
    ├── Script_PR2_Patch_Ring_Production_Deployment.ps1
    ├── Script_P1_Critical_Device_Patch_Validator.ps1
    ├── Script_P2_High_Priority_Device_Patch_Validator.ps1
    ├── Script_P3_Medium_Priority_Device_Patch_Validator.ps1
    └── Script_P4_Low_Priority_Device_Patch_Validator.ps1
```

---

## Complete Script Inventory

### Core Monitoring Scripts (11 active scripts)

| Script | Name | Frequency | Description | Download |
|--------|------|-----------|-------------|---------|
| 1 | Health Score Calculator | 4 hours | Composite health scoring | [Download](scripts/Core_Monitoring/Script_01_Health_Score_Calculator.ps1) |
| 2 | Stability Analyzer | 4 hours | System/app stability scoring | [Download](scripts/Core_Monitoring/Script_02_Stability_Analyzer.ps1) |
| 3 | Performance Analyzer | 4 hours | Performance and responsiveness | [Download](scripts/Core_Monitoring/Script_03_Performance_Analyzer.ps1) |
| 4 | Security Analyzer | Daily | Security posture scoring | [Download](scripts/Core_Monitoring/Script_04_Security_Analyzer.ps1) |
| 5 | Capacity Analyzer | Daily | Resource capacity headroom | [Download](scripts/Core_Monitoring/Script_05_Capacity_Analyzer.ps1) |
| 6 | Telemetry Collector | 4 hours | Custom crash/hang/failure tracking | [Download](scripts/Core_Monitoring/Script_06_Telemetry_Collector.ps1) |
| 9 | Risk Classifier | 4 hours | Multi-factor risk classification | [Download](scripts/Core_Monitoring/Script_09_Risk_Classifier.ps1) |
| 10 | Update Assessment | Daily | Windows Update compliance | [Download](scripts/Core_Monitoring/Script_10_Update_Assessment_Collector.ps1) |
| 11 | Network Location Tracker | 4 hours | Office/Remote/VPN tracking | [Download](scripts/Core_Monitoring/Script_11_Network_Location_Tracker.ps1) |
| 12 | Baseline Manager | Daily | Performance baseline establishment | [Download](scripts/Core_Monitoring/Script_12_Baseline_Manager.ps1) |
| 13 | Drift Detector | Daily | Configuration drift detection | [Download](scripts/Core_Monitoring/Script_13_Drift_Detector.ps1) |

**Note:** Scripts 7-8 deprecated (replaced by native NinjaOne monitoring)

### Extended Automation Scripts (14 scripts)

| Script | Name | Frequency | Description |
|--------|------|-----------|-------------|
| 14 | Local Admin Drift Analyzer | Daily | Unauthorized admin detection |
| 15 | Security Posture Consolidator | Daily | Security posture consolidation |
| 16 | Suspicious Login Pattern Detector | 4 hours | Suspicious authentication tracking |
| 17 | Application Experience Profiler | Daily | App crash/hang profiling |
| 18 | Profile Hygiene Cleanup Advisor | Daily | User profile cleanup recommendations |
| 19 | Chronic Slow-Boot Detector | Daily | Boot time degradation detection |
| 20 | Software Inventory Shadow-IT | Daily | Unauthorized software detection |
| 21 | Critical Service Drift Monitor | Daily | Service configuration drift |
| 22 | Capacity Trend Forecaster | Weekly | Predictive capacity forecasting |
| 23 | Patch Compliance Aging Analyzer | Daily | Patch aging analysis |
| 24 | Device Lifetime Predictor | Weekly | Hardware replacement prediction |
| 27 | Telemetry Freshness Monitor | 4 hours | Data quality validation |

### Advanced Telemetry Scripts (9 scripts)

| Script | Name | Frequency | Description |
|--------|------|-----------|-------------|
| 28 | Security Surface Telemetry | Daily | Security exposure assessment |
| 29 | Collaboration Outlook UX | 4 hours | Collaboration tool quality |
| 30 | User Environment Friction | Daily | Login/environment friction tracking |
| 31 | Remote Connectivity SaaS | 4 hours | VPN/WiFi/SaaS quality |
| 32 | Thermal Firmware Telemetry | Daily | Thermal monitoring, firmware tracking |
| 34 | Licensing Feature Utilization | Daily | Software licensing, activation |
| 35 | Baseline Coverage Drift Density | Daily | Baseline quality metrics |

### Server Role Monitoring Scripts (60 scripts)

#### IIS Web Servers (11 scripts)
- Scripts 51-61: IIS health, app pools, sites, performance, errors, request tracking

#### SQL Database Servers (15 scripts)
- Scripts 62-70: MS SQL Server health, databases, queries, connections, backups
- Scripts 71-76: MySQL/MariaDB health, databases, replication

#### Infrastructure Services (18 scripts)
- Scripts 77-80: Apache web server monitoring
- Scripts 81-84: Veeam backup monitoring
- Scripts 85-88: DHCP server health, scopes, leases
- Scripts 89-92: DNS server health, zones, queries

#### Additional Roles (16 scripts)
- Scripts 93-95: Event log collection and analysis
- Scripts 96-98: File server shares, connections, quotas
- Scripts 99-101: Print server queues, jobs, spooler
- Scripts 102-105: Hyper-V host, VMs, resources
- Scripts 106-108: BitLocker encryption status
- Scripts 109-110: Windows features, FlexLM license server

### Patching Automation Scripts (5 scripts - NEW)

| Script | Name | Frequency | Description |
|--------|------|-----------|-------------|
| PR1 | Patch Ring Test Deployment | Weekly (Tue) | Test ring deployment (10-20 devices) |
| PR2 | Patch Ring Production | Weekly (Tue+7) | Production ring deployment |
| P1 | Critical Device Validator | Pre-deploy | P1 critical device validation |
| P2 | High Priority Validator | Pre-deploy | P2 high priority validation |
| P3-P4 | Medium/Low Validators | Pre-deploy | P3/P4 medium/low validation |

---

## Deployment Instructions

### Prerequisites

1. **NinjaOne RMM Agent** installed on target devices
2. **PowerShell 5.1 or higher** on Windows devices
3. **Custom Fields Created** (see files 10-24, 31 for definitions)
4. **SYSTEM-level permissions** for most scripts
5. **Specific roles/features** for server monitoring scripts

### Step 1: Create Custom Fields

Before deploying scripts, create all required custom fields in NinjaOne:

1. Navigate to **Administration > Devices > Global Custom Fields**
2. Create fields as documented in:
   - File 10: OPS, STAT, RISK fields (28 fields)
   - File 11: AUTO, UX, SRV fields (21 fields)
   - File 12: DRIFT, CAP, BAT fields (18 fields)
   - File 13: NET, GPO, AD fields (15 fields)
   - File 14: BASE, SEC, UPD fields (16 fields)
   - File 31: PATCH fields (8 fields)

### Step 2: Deploy Scripts to NinjaOne

1. Navigate to **Configuration > Scripting**
2. Click **Add a new script**
3. Copy script content from `.ps1` file
4. Configure script:
   - **Name:** Use descriptive name from script header
   - **Language:** PowerShell
   - **Operating System:** Windows
   - **Architecture:** All (or x64 for specific scripts)
   - **Run As:** SYSTEM
5. Click **Save**

### Step 3: Schedule Script Execution

1. Navigate to **Policies** (or create new policy)
2. Go to **Scheduled Scripts**
3. Click **Add a scheduled script**
4. Select script and set frequency:
   - **Every 4 hours:** Scripts 1-6, 9, 16, 27, 29, 31
   - **Daily:** Scripts 10-15, 17-21, 23, 28, 30, 32, 34-35
   - **Weekly:** Scripts 22, 24, PR1, PR2
   - **On-Demand:** Scripts P1-P4

### Step 4: Test on Pilot Devices

1. Create test policy with subset of scripts
2. Apply to 10-20 pilot devices
3. Monitor execution in **Activity Log**
4. Verify custom fields populate correctly
5. Check for errors in script output

### Step 5: Roll Out to Production

1. After successful pilot (1-2 weeks)
2. Add remaining scripts to production policy
3. Roll out to 25% of fleet
4. Monitor for 1 week
5. Complete rollout to 100% of fleet

---

## Script Execution Schedule Summary

### Every 4 Hours (High Frequency)
```
Scripts: 1, 2, 3, 6, 9, 11, 16, 27, 29, 31
Purpose: Real-time health, stability, performance, security monitoring
Total Execution Time: ~80 seconds per cycle
```

### Daily (Standard Frequency)
```
Scripts: 4, 5, 10, 12-15, 17-21, 23, 28, 30, 32, 34-35
Purpose: Configuration drift, security posture, user experience, compliance
Total Execution Time: ~120 seconds per day
```

### Weekly (Low Frequency)
```
Scripts: 22, 24, PR1, PR2
Purpose: Capacity forecasting, predictive analytics, patch deployment
Total Execution Time: ~60 seconds per week
```

### On-Demand (Pre-Deployment)
```
Scripts: P1, P2, P3, P4
Purpose: Pre-patch validation
Total Execution Time: ~30 seconds per validation
```

---

## Troubleshooting

### Script Fails with "Custom Field Not Found"
**Solution:** Create the custom field referenced in the error message. Check files 10-14, 31 for field definitions.

### Script Fails with "Access Denied"
**Solution:** Ensure script runs with SYSTEM permissions. Check **Run As** setting in script configuration.

### Fields Not Updating
**Solution:**
1. Check script execution in Activity Log
2. Verify script completed successfully (exit code 0)
3. Ensure custom field has **Script Access** set to **Read/Write**
4. Check for typos in field names

### Server Role Scripts Fail
**Solution:** Ensure the specific Windows role/feature is installed (IIS, DHCP, DNS, etc.). Some scripts require administrative credentials or specific services running.

---

## Support Resources

### Documentation Files
- **00_README.md** - Framework overview and quick start
- **00_Master_Index.md** - Complete navigation index
- **01_Framework_Architecture.md** - System design and principles
- **51_Field_to_Script_Complete_Mapping.md** - Field traceability
- **98_Framework_Complete_Summary_Master.md** - Comprehensive reference
- **99_Quick_Reference_Guide.md** - Day-to-day operations

### Script Documentation
- **55_Scripts_01_13_Infrastructure_Monitoring.md** - Core scripts 1-13
- **61_Scripts_Patching_Automation.md** - Patching scripts PR1, PR2, P1-P4
- Additional script documentation in files 50-61 series

---

## Version History

### v4.0 (February 1, 2026) - Current
- Added patching automation (5 new scripts)
- Native NinjaOne metric integration
- Deprecated scripts 7-8 (replaced by native monitoring)
- 277 total custom fields
- 110 total PowerShell scripts
- Production ready

---

## License & Disclaimer

These scripts are part of the NinjaOne Custom Field Framework v4.0.

**Use at your own risk.**
- Test thoroughly in non-production environment first
- Review and modify scripts as needed for your environment
- Always maintain backups before deploying automation
- Monitor script execution and performance impact

---

**Questions?** Refer to the complete documentation in the repository root.

**Repository:** [https://github.com/Xore/waf](https://github.com/Xore/waf)  
**Framework Version:** 4.0  
**Last Updated:** February 2, 2026  
**Status:** Production Ready
