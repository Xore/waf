# Markdown Files Reorganization Plan - v4.0
**Created:** February 2, 2026  
**Status:** Pending Approval

---

## ISSUES IDENTIFIED

1. **Duplicate Numbers:** 12 files have conflicting numbers (00, 44, 56, 57, 70, 100)
2. **No Numeric Prefix:** 17 files without numbering
3. **Multiple Topics:** Some files cover multiple scripts/topics
4. **Poor Categorization:** Files scattered without clear structure

---

## RULES ENFORCED

1. **ONE** topic/script per file
2. **NO** duplicate numbers
3. **ALL** files numbered (except README.md)
4. **Logical grouping** with subdirectories
5. **Clear naming:** `##_Category_Specific_Topic.md`

---

## NEW DIRECTORY STRUCTURE

```
/
├── 00_README.md (root readme)
├── 01_Framework_Architecture.md
├── 02_Master_Index.md (renumbered from 00)
├── docs/
│   ├── core/          (10-19 range - Core Framework)
│   ├── patching/      (30-39 range - Patching)
│   ├── scripts/       (50-69 range - Script Docs)
│   │   └── deprecated/ (old infrastructure docs)
│   ├── health-checks/ (70-79 range - Health Checks)
│   ├── automation/    (90-97 range - Automation)
│   ├── roi/           (100-109 range - ROI Analysis)
│   ├── training/      (110-119 range - Training)
│   ├── reference/     (120-129 range - Reference)
│   └── advanced/      (130-139 range - RCA/ML)
└── scripts/ (PowerShell scripts, unchanged)
```

---

## FILE REORGANIZATION

### ROOT LEVEL (00-09)

| Current | New | Action |
|---------|-----|--------|
| 00_README.md | 00_README.md | Keep |
| 01_Framework_Architecture.md | 01_Framework_Architecture.md | Keep |
| 00_Master_Index.md | 02_Master_Index.md | Renumber |

### docs/core/ (10-19) - Core Framework

| Current | New |
|---------|-----|
| 10_OPS_STAT_RISK_Core_Metrics.md | docs/core/10_OPS_STAT_RISK_Core_Metrics.md |
| 11_AUTO_UX_SRV_Core_Experience.md | docs/core/11_AUTO_UX_SRV_Core_Experience.md |
| 12_DRIFT_CAP_BAT_Core_Monitoring.md | docs/core/12_DRIFT_CAP_BAT_Core_Monitoring.md |
| 13_NET_GPO_AD_Core_Network_Identity.md | docs/core/13_NET_GPO_AD_Core_Network_Identity.md |
| 14_BASE_SEC_UPD_Core_Security_Baseline.md | docs/core/14_BASE_SEC_UPD_Core_Security_Baseline.md |
| 22_IIS_MSSQL_MYSQL_Database_Web_Servers.md | docs/core/15_Server_Roles_Database_Web.md |
| 23_APACHE_VEEAM_DHCP_DNS_Infrastructure.md | docs/core/16_Server_Roles_Infrastructure.md |
| 24_EVT_FS_PRINT_HV_BL_FEAT_FLEXLM_Additional_Roles.md | docs/core/17_Server_Roles_Additional.md |

### docs/patching/ (30-39) - Patching Framework

| Current | New |
|---------|-----|
| 30_PATCH_Main_Patching_Framework.md | docs/patching/30_Patching_Framework_Main.md |
| 31_PATCH_Custom_Fields.md | docs/patching/31_Patching_Custom_Fields.md |
| 36_PATCH_Quick_Start_Guide.md | docs/patching/32_Patching_Quick_Start.md |
| 44_PATCH_Ring_Based_Deployment.md | docs/patching/33_Patching_Ring_Deployment.md |
| 46_PATCH_Windows_OS_Tutorial.md | docs/patching/34_Patching_Windows_Tutorial.md |
| 47_PATCH_Software_Patching_Tutorial.md | docs/patching/35_Patching_Software_Tutorial.md |
| 48_PATCH_Policy_Configuration_Guide.md | docs/patching/36_Patching_Policy_Guide.md |
| 61_Scripts_Patching_Automation.md | docs/patching/37_Patching_Scripts.md |
| PATCHING_GENERATION_SUMMARY.md | docs/patching/38_Patching_Summary.md |

### docs/scripts/ (50-69) - Script Documentation

#### Monitoring Scripts (50-55)
| Current | New |
|---------|-----|
| 55_Scripts_01_13_Infrastructure_Monitoring.md | docs/scripts/50_Scripts_Monitoring_01_to_13.md |
| 56_Custom_Fields_Scripts_14_20_Server_Monitoring.md | docs/scripts/51_Scripts_Fields_14_to_20.md |
| 57_Script_Conditions_Automation_Scripts_14_20.md | docs/scripts/52_Scripts_Automation_14_to_20.md |
| 53_Scripts_14_27_Extended_Automation.md | docs/scripts/53_Scripts_Automation_14_to_27.md |
| 59_Scripts_19_24_Extended_Automation.md | docs/scripts/54_Scripts_Automation_19_to_24.md |
| 54_Scripts_28_36_Advanced_Telemetry.md | docs/scripts/55_Scripts_Telemetry_28_to_36.md |

#### Capacity Scripts (56-59)
| Current | New |
|---------|-----|
| 60_Scripts_22_24_27_34_36_Capacity_Predictive.md | docs/scripts/56_Scripts_Capacity_Predictive.md |

#### Utility Scripts (60-63)
| Current | New |
|---------|-----|
| 18_Scripts_Baseline_Refresh.md | docs/scripts/60_Scripts_Baseline_Refresh.md |
| 50_Scripts_Emergency_Disk_Cleanup.md | docs/scripts/61_Scripts_Emergency_Cleanup.md |
| 56_Scripts_Memory_Optimization.md | docs/scripts/62_Scripts_Memory_Optimization.md |
| 51_Field_to_Script_Complete_Mapping.md | docs/scripts/63_Scripts_Field_Mapping.md |

#### Service Restart Scripts (64-68)
| Current | New |
|---------|-----|
| 41_Scripts_Service_Restart_Print_Spooler.md | docs/scripts/64_Scripts_Service_Print_Spooler.md |
| 42_Scripts_Service_Restart_Windows_Update.md | docs/scripts/65_Scripts_Service_Windows_Update.md |
| 43_Scripts_Service_Restart_DNS_Client.md | docs/scripts/66_Scripts_Service_DNS_Client.md |
| 44_Scripts_Service_Restart_Network_Services.md | docs/scripts/67_Scripts_Service_Network.md |
| 45_Scripts_Service_Restart_Remote_Desktop.md | docs/scripts/68_Scripts_Service_Remote_Desktop.md |

#### Deprecated (No Numbers)
| Current | New |
|---------|-----|
| 57_Scripts_03_08_Infrastructure_Part1.md | docs/scripts/deprecated/Scripts_03_to_08_Part1.md |
| 58_Scripts_07_08_11_12_Infrastructure_Part2.md | docs/scripts/deprecated/Scripts_07_to_12_Part2.md |

### docs/health-checks/ (70-79)

| Current | New |
|---------|-----|
| 70_Custom_Health_Check_Quick_Reference.md | docs/health-checks/70_Health_Checks_Quick_Reference.md |
| 70_Custom_Health_Check_Templates.md | docs/health-checks/71_Health_Checks_Templates.md |
| CUSTOM_HEALTH_CHECK_SUMMARY.md | docs/health-checks/72_Health_Checks_Summary.md |

### docs/automation/ (90-97)

| Current | New |
|---------|-----|
| 91_Compound_Conditions_Complete.md | docs/automation/90_Compound_Conditions.md |
| 92_Dynamic_Groups_Complete.md | docs/automation/91_Dynamic_Groups.md |
| 98_Framework_Complete_Summary_Master.md | docs/automation/92_Framework_Master_Summary.md |

### docs/roi/ (100-109)

| Current | New |
|---------|-----|
| 100_Detailed_ROI_Analysis_No_ML.md | docs/roi/100_ROI_Analysis_No_ML.md |
| 100_Detailed_ROI_Analysis_ML_with_Platform_Costs.md | docs/roi/101_ROI_Analysis_With_ML.md |

### docs/training/ (110-119)

| Current | New |
|---------|-----|
| Framework_Training_Material_Part1.md | docs/training/110_Training_Part1_Fundamentals.md |
| Framework_Training_Material_Part2.md | docs/training/111_Training_Part2_Advanced.md |
| ML_Integration_Guide.md | docs/training/112_Training_ML_Integration.md |
| Troubleshooting_Guide_Servers_Clients.md | docs/training/113_Troubleshooting_Guide.md |

### docs/reference/ (120-129)

| Current | New |
|---------|-----|
| 99_Quick_Reference_Guide.md | docs/reference/120_Quick_Reference.md |
| Executive_Summary_Core_Framework.md | docs/reference/121_Executive_Summary_Core.md |
| Executive_Summary_ML_Framework.md | docs/reference/122_Executive_Summary_ML.md |
| Framework_Statistics_Summary.md | docs/reference/123_Framework_Statistics.md |
| Framework_Visual_Diagrams.md | docs/reference/124_Framework_Diagrams.md |
| NATIVE_INTEGRATION_OPTIMIZATION_SUMMARY.md | docs/reference/125_Native_Integration_Summary.md |

### docs/advanced/ (130-139)

| Current | New |
|---------|-----|
| Chapter_6_Advanced_RCA.md | docs/advanced/130_RCA_Advanced.md |
| Chapter_6_Explained.md | docs/advanced/131_RCA_Explained.md |
| Chapter_6_RCA_Diagrams.md | docs/advanced/132_RCA_Diagrams.md |
| ML_RCA_Integration.md | docs/advanced/133_ML_RCA_Integration.md |

### FILES TO DELETE

- `Quick_Reference_Guide.md` (duplicate of 99_Quick_Reference_Guide.md)
- `README.md` (duplicate of 00_README.md)

---

## EXECUTION PHASES

### Phase 1: Create Directories (Manual or Script)
```bash
mkdir -p docs/{core,patching,scripts/deprecated,health-checks,automation,roi,training,reference,advanced}
```

### Phase 2: Fix Duplicate Numbers (Priority)
These must be fixed first to avoid conflicts:
1. 00_Master_Index.md → 02_Master_Index.md
2. 44_PATCH_Ring_Based_Deployment.md → docs/patching/33_Patching_Ring_Deployment.md
3. 44_Scripts_Service_Restart_Network_Services.md → docs/scripts/67_Scripts_Service_Network.md
4. 56_Custom_Fields_Scripts_14_20_Server_Monitoring.md → docs/scripts/51_Scripts_Fields_14_to_20.md
5. 56_Scripts_Memory_Optimization.md → docs/scripts/62_Scripts_Memory_Optimization.md
6. 57_Script_Conditions_Automation_Scripts_14_20.md → docs/scripts/52_Scripts_Automation_14_to_20.md
7. 57_Scripts_03_08_Infrastructure_Part1.md → docs/scripts/deprecated/Scripts_03_to_08_Part1.md
8. 70_Custom_Health_Check_Quick_Reference.md → docs/health-checks/70_Health_Checks_Quick_Reference.md
9. 70_Custom_Health_Check_Templates.md → docs/health-checks/71_Health_Checks_Templates.md
10. 100_Detailed_ROI_Analysis_No_ML.md → docs/roi/100_ROI_Analysis_No_ML.md
11. 100_Detailed_ROI_Analysis_ML_with_Platform_Costs.md → docs/roi/101_ROI_Analysis_With_ML.md

### Phase 3: Move Remaining Files
Move all other files according to the reorganization plan.

### Phase 4: Delete Duplicates
1. Delete Quick_Reference_Guide.md
2. Delete README.md

### Phase 5: Update Cross-References
1. Update 02_Master_Index.md with new file paths
2. Update 00_README.md with new structure
3. Update internal links in all documentation

---

## SUMMARY

**Total Files:** 62 markdown files  
**Actions:**
- Move: 59 files
- Renumber: 35 files
- Delete: 2 duplicates
- Create: 9 directories
- Update: Cross-references in all files

**Result:** Clean, organized, no duplicate numbers, clear categorization

---

**Next Steps:** Await approval to execute reorganization.
