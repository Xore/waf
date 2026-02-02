# File Naming Cleanup Plan

**Status:** PENDING EXECUTION  
**Date:** February 2, 2026  
**Issue:** Files in `docs/scripts/` have inconsistent naming

---

## Problem

The `docs/scripts/` folder contains files with two naming conventions:

1. **CORRECT:** Files starting with numbers (e.g., `01_`, `02_`)
2. **INCORRECT:** Files starting with `Script_` prefix (e.g., `Script_01_`, `Script_02_`)

All files should follow the numeric prefix convention for consistency and easier sorting.

---

## Required Actions

### Phase 1: Rename Script_ Prefix Files (44 files)

Rename from `Script_##_` to `##_` format:

```
Script_01_OPS_Health_Score_Calculator.md → 01_OPS_Health_Score_Calculator.md
Script_02_OPS_Stability_Analyzer.md → 02_OPS_Stability_Analyzer.md
Script_03_OPS_Performance_Analyzer.md → 03_OPS_Performance_Analyzer.md
Script_04_OPS_Security_Analyzer.md → 04_OPS_Security_Analyzer.md
Script_05_OPS_Capacity_Analyzer.md → 05_OPS_Capacity_Analyzer.md
Script_06_STAT_Telemetry_Collector.md → 06_STAT_Telemetry_Collector.md
Script_07_BL_BitLocker_Monitor.md → 07_BL_BitLocker_Monitor.md
Script_08_HV_HyperV_Host_Monitor.md → 08_HV_HyperV_Host_Monitor.md
Script_09_RISK_Classifier.md → 09_RISK_Classifier.md
Script_10_UPD_Update_Assessment_Collector.md → 10_UPD_Update_Assessment_Collector.md
Script_11_NET_Location_Tracker.md → 11_NET_Location_Tracker.md
Script_12_BASE_Baseline_Manager.md → 12_BASE_Baseline_Manager.md
Script_13_DRIFT_Detector.md → 13_DRIFT_Detector.md
Script_14_DRIFT_Local_Admin_Analyzer.md → 14_DRIFT_Local_Admin_Analyzer.md
Script_15_SEC_Security_Posture_Consolidator.md → 15_SEC_Security_Posture_Consolidator.md
Script_16_SEC_Suspicious_Login_Detector.md → 16_SEC_Suspicious_Login_Detector.md
Script_17_UX_Application_Experience_Profiler.md → 17_UX_Application_Experience_Profiler.md
Script_18_CLEANUP_Profile_Hygiene_Advisor.md → 18_CLEANUP_Profile_Hygiene_Advisor.md
Script_19_UX_Chronic_Slow_Boot_Detector.md → 19_UX_Chronic_Slow_Boot_Detector.md
Script_20_DRIFT_Shadow_IT_Detector.md → 20_DRIFT_Shadow_IT_Detector.md
Script_21_DRIFT_Critical_Service_Monitor.md → 21_DRIFT_Critical_Service_Monitor.md
Script_22_CAP_Predictive_Analytics.md → 22_CAP_Predictive_Analytics.md
Script_23_UPD_Patch_Compliance_Aging.md → 23_UPD_Patch_Compliance_Aging.md
Script_24_PRED_Device_Lifetime_Predictor.md → 24_PRED_Device_Lifetime_Predictor.md
Script_25_Reserved.md → 25_Reserved.md
Script_26_Reserved.md → 26_Reserved.md
Script_27_Reserved.md → 27_Reserved.md
Script_28_SEC_Security_Surface_Telemetry.md → 28_SEC_Security_Surface_Telemetry.md
Script_29_UX_Collaboration_Telemetry.md → 29_UX_Collaboration_Telemetry.md
Script_30_UX_User_Environment_Friction.md → 30_UX_User_Environment_Friction.md
Script_31_NET_Remote_Connectivity_Quality.md → 31_NET_Remote_Connectivity_Quality.md
Script_32_HW_Thermal_Firmware_Telemetry.md → 32_HW_Thermal_Firmware_Telemetry.md
Script_33_Reserved.md → 33_Reserved.md
Script_34_LIC_Licensing_Feature_Utilization.md → 34_LIC_Licensing_Feature_Utilization.md
Script_35_BASE_Baseline_Coverage_Telemetry.md → 35_BASE_Baseline_Coverage_Telemetry.md
Script_36_SRV_Server_Role_Detector.md → 36_SRV_Server_Role_Detector.md
Script_37_Reserved.md → 37_Reserved.md
Script_38_Reserved.md → 38_Reserved.md
Script_39_Reserved.md → 39_Reserved.md
Script_40_Reserved.md → 40_Reserved.md
Script_41_Reserved.md → 41_Reserved.md
Script_42_Reserved.md → 42_Reserved.md
Script_43_Reserved.md → 43_Reserved.md
Script_44_Reserved.md → 44_Reserved.md
```

**Total: 44 files**

---

### Phase 2: Move Old Documentation to Deprecated (18 files)

Move these old monolithic files to `docs/scripts/deprecated/`:

```
80_Scripts_Monitoring_01_to_13.md
81_Scripts_Fields_14_to_20.md
82_Scripts_Automation_14_to_20.md
83_Scripts_Automation_14_to_27.md
84_Scripts_Automation_19_to_24.md
85_Scripts_Telemetry_28_to_36.md
86_Scripts_Capacity_Predictive.md
90_Scripts_Baseline_Refresh.md
91_Scripts_Emergency_Cleanup.md
92_Scripts_Memory_Optimization.md
93_Scripts_Field_Mapping.md
95_Scripts_Service_Print_Spooler.md
96_Scripts_Service_Windows_Update.md
97_Scripts_Service_DNS_Client.md
98_Scripts_Service_Network.md
99_Scripts_Service_Remote_Desktop.md
100_Scripts_03_to_08_Part1_DEPRECATED.md
101_Scripts_07_to_12_Part2_DEPRECATED.md
```

**Total: 18 files**

---

## Execution Method

Since GitHub API doesn't support rename operations directly, we'll:

1. **Create** new files with correct names (copy content)
2. **Delete** old files with `Script_` prefix
3. **Move** deprecated files by creating in deprecated folder and deleting from scripts folder

---

## Final Structure

After cleanup, `docs/scripts/` will contain:

```
docs/scripts/
├── README.md
├── 01_OPS_Health_Score_Calculator.md
├── 02_OPS_Stability_Analyzer.md
├── ... (Scripts 03-44)
├── 44_Reserved.md
└── deprecated/
    ├── 80_Scripts_Monitoring_01_to_13.md
    ├── ... (old monolithic files)
    └── 101_Scripts_07_to_12_Part2_DEPRECATED.md
```

---

**Status:** READY FOR EXECUTION  
**Requires:** Manual execution or batch script  
**Estimated Time:** 10-15 minutes
