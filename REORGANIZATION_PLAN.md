# Markdown Files Reorganization Plan - v4.0
**Created:** February 2, 2026  
**Status:** Pending Approval  
**Numbering System:** 35-Space Ranges

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
4. **35-space ranges** for massive expansion room
5. **Logical grouping** with subdirectories
6. **Clear naming:** `##_Category_Specific_Topic.md`

---

## NUMBERING RANGES (35 Slots Each)

| Range | Category | Slots Used | Slots Available |
|-------|----------|------------|----------------|
| 00-09 | Root Level | 3 | 7 |
| 10-44 | Core Framework | 8 | 27 |
| 45-79 | Patching Framework | 9 | 26 |
| 80-114 | Script Documentation | 18 | 17 |
| 115-149 | Health Checks | 3 | 32 |
| 150-184 | Automation & Conditions | 3 | 32 |
| 185-219 | ROI Analysis | 2 | 33 |
| 220-254 | Training & Guides | 4 | 31 |
| 255-289 | Reference & Summary | 6 | 29 |
| 290-324 | Advanced Topics (RCA/ML) | 4 | 31 |

**Total Capacity:** 325 files  
**Currently Used:** 60 files  
**Available for Growth:** 265 slots

---

## BENEFITS OF 35-SPACE RANGES

1. **Massive Expansion Room** - Each category can grow significantly
2. **Clear Boundaries** - Easy to identify which range a file belongs to
3. **No Future Conflicts** - Plenty of buffer between categories
4. **Logical Grouping** - Related files stay within same range
5. **Future-Proof** - Room for years of growth and additions

---

## NEW DIRECTORY STRUCTURE

```
/
├── 00_README.md (main readme)
├── 01_Framework_Architecture.md
├── 02_Master_Index.md (renumbered from 00)
├── docs/
│   ├── core/          (10-44: Core Framework - 35 slots)
│   ├── patching/      (45-79: Patching - 35 slots)
│   ├── scripts/       (80-114: Script Documentation - 35 slots)
│   ├── health-checks/ (115-149: Health Checks - 35 slots)
│   ├── automation/    (150-184: Automation - 35 slots)
│   ├── roi/           (185-219: ROI Analysis - 35 slots)
│   ├── training/      (220-254: Training - 35 slots)
│   ├── reference/     (255-289: Reference - 35 slots)
│   └── advanced/      (290-324: RCA/ML - 35 slots)
└── scripts/ (PowerShell scripts, unchanged)
```

---

## DETAILED FILE MAPPING

### ROOT LEVEL (00-09) - 3 files

| Current | New | Action |
|---------|-----|--------|
| 00_README.md | 00_README.md | Keep |
| 01_Framework_Architecture.md | 01_Framework_Architecture.md | Keep |
| 00_Master_Index.md | 02_Master_Index.md | Renumber |

**Available slots:** 03-09 (7 slots)

---

### docs/core/ (10-44) - 8 files

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

**Available slots:** 18-44 (27 slots)

---

### docs/patching/ (45-79) - 9 files

| Current | New |
|---------|-----|
| 30_PATCH_Main_Patching_Framework.md | docs/patching/45_Patching_Framework_Main.md |
| 31_PATCH_Custom_Fields.md | docs/patching/46_Patching_Custom_Fields.md |
| 36_PATCH_Quick_Start_Guide.md | docs/patching/47_Patching_Quick_Start.md |
| 44_PATCH_Ring_Based_Deployment.md | docs/patching/48_Patching_Ring_Deployment.md |
| 46_PATCH_Windows_OS_Tutorial.md | docs/patching/49_Patching_Windows_Tutorial.md |
| 47_PATCH_Software_Patching_Tutorial.md | docs/patching/50_Patching_Software_Tutorial.md |
| 48_PATCH_Policy_Configuration_Guide.md | docs/patching/51_Patching_Policy_Guide.md |
| 61_Scripts_Patching_Automation.md | docs/patching/52_Patching_Scripts.md |
| PATCHING_GENERATION_SUMMARY.md | docs/patching/53_Patching_Summary.md |

**Available slots:** 54-79 (26 slots)

---

### docs/scripts/ (80-114) - 18 files

#### Monitoring Scripts (80-89)
| Current | New |
|---------|-----|
| 55_Scripts_01_13_Infrastructure_Monitoring.md | docs/scripts/80_Scripts_Monitoring_01_to_13.md |
| 56_Custom_Fields_Scripts_14_20_Server_Monitoring.md | docs/scripts/81_Scripts_Fields_14_to_20.md |
| 57_Script_Conditions_Automation_Scripts_14_20.md | docs/scripts/82_Scripts_Automation_14_to_20.md |
| 53_Scripts_14_27_Extended_Automation.md | docs/scripts/83_Scripts_Automation_14_to_27.md |
| 59_Scripts_19_24_Extended_Automation.md | docs/scripts/84_Scripts_Automation_19_to_24.md |
| 54_Scripts_28_36_Advanced_Telemetry.md | docs/scripts/85_Scripts_Telemetry_28_to_36.md |
| 60_Scripts_22_24_27_34_36_Capacity_Predictive.md | docs/scripts/86_Scripts_Capacity_Predictive.md |

**Available:** 87-89 (3 slots)

#### Utility Scripts (90-94)
| Current | New |
|---------|-----|
| 18_Scripts_Baseline_Refresh.md | docs/scripts/90_Scripts_Baseline_Refresh.md |
| 50_Scripts_Emergency_Disk_Cleanup.md | docs/scripts/91_Scripts_Emergency_Cleanup.md |
| 56_Scripts_Memory_Optimization.md | docs/scripts/92_Scripts_Memory_Optimization.md |
| 51_Field_to_Script_Complete_Mapping.md | docs/scripts/93_Scripts_Field_Mapping.md |

**Available:** 94 (1 slot)

#### Service Restart Scripts (95-99)
| Current | New |
|---------|-----|
| 41_Scripts_Service_Restart_Print_Spooler.md | docs/scripts/95_Scripts_Service_Print_Spooler.md |
| 42_Scripts_Service_Restart_Windows_Update.md | docs/scripts/96_Scripts_Service_Windows_Update.md |
| 43_Scripts_Service_Restart_DNS_Client.md | docs/scripts/97_Scripts_Service_DNS_Client.md |
| 44_Scripts_Service_Restart_Network_Services.md | docs/scripts/98_Scripts_Service_Network.md |
| 45_Scripts_Service_Restart_Remote_Desktop.md | docs/scripts/99_Scripts_Service_Remote_Desktop.md |

#### Deprecated Scripts (100-104)
| Current | New |
|---------|-----|
| 57_Scripts_03_08_Infrastructure_Part1.md | docs/scripts/100_Scripts_03_to_08_Part1_DEPRECATED.md |
| 58_Scripts_07_08_11_12_Infrastructure_Part2.md | docs/scripts/101_Scripts_07_to_12_Part2_DEPRECATED.md |

**Available:** 102-114 (13 slots)

---

### docs/health-checks/ (115-149) - 3 files

| Current | New |
|---------|-----|
| 70_Custom_Health_Check_Quick_Reference.md | docs/health-checks/115_Health_Checks_Quick_Reference.md |
| 70_Custom_Health_Check_Templates.md | docs/health-checks/116_Health_Checks_Templates.md |
| CUSTOM_HEALTH_CHECK_SUMMARY.md | docs/health-checks/117_Health_Checks_Summary.md |

**Available slots:** 118-149 (32 slots)

---

### docs/automation/ (150-184) - 3 files

| Current | New |
|---------|-----|
| 91_Compound_Conditions_Complete.md | docs/automation/150_Compound_Conditions.md |
| 92_Dynamic_Groups_Complete.md | docs/automation/151_Dynamic_Groups.md |
| 98_Framework_Complete_Summary_Master.md | docs/automation/152_Framework_Master_Summary.md |

**Available slots:** 153-184 (32 slots)

---

### docs/roi/ (185-219) - 2 files

| Current | New |
|---------|-----|
| 100_Detailed_ROI_Analysis_No_ML.md | docs/roi/185_ROI_Analysis_No_ML.md |
| 100_Detailed_ROI_Analysis_ML_with_Platform_Costs.md | docs/roi/186_ROI_Analysis_With_ML.md |

**Available slots:** 187-219 (33 slots)

---

### docs/training/ (220-254) - 4 files

| Current | New |
|---------|-----|
| Framework_Training_Material_Part1.md | docs/training/220_Training_Part1_Fundamentals.md |
| Framework_Training_Material_Part2.md | docs/training/221_Training_Part2_Advanced.md |
| ML_Integration_Guide.md | docs/training/222_Training_ML_Integration.md |
| Troubleshooting_Guide_Servers_Clients.md | docs/training/223_Troubleshooting_Guide.md |

**Available slots:** 224-254 (31 slots)

---

### docs/reference/ (255-289) - 6 files

| Current | New |
|---------|-----|
| 99_Quick_Reference_Guide.md | docs/reference/255_Quick_Reference.md |
| Executive_Summary_Core_Framework.md | docs/reference/256_Executive_Summary_Core.md |
| Executive_Summary_ML_Framework.md | docs/reference/257_Executive_Summary_ML.md |
| Framework_Statistics_Summary.md | docs/reference/258_Framework_Statistics.md |
| Framework_Visual_Diagrams.md | docs/reference/259_Framework_Diagrams.md |
| NATIVE_INTEGRATION_OPTIMIZATION_SUMMARY.md | docs/reference/260_Native_Integration_Summary.md |

**Available slots:** 261-289 (29 slots)

---

### docs/advanced/ (290-324) - 4 files

| Current | New |
|---------|-----|
| Chapter_6_Advanced_RCA.md | docs/advanced/290_RCA_Advanced.md |
| Chapter_6_Explained.md | docs/advanced/291_RCA_Explained.md |
| Chapter_6_RCA_Diagrams.md | docs/advanced/292_RCA_Diagrams.md |
| ML_RCA_Integration.md | docs/advanced/293_ML_RCA_Integration.md |

**Available slots:** 294-324 (31 slots)

---

## FILES TO DELETE

- `Quick_Reference_Guide.md` (duplicate of 99_Quick_Reference_Guide.md)
- `README.md` (duplicate of 00_README.md)

---

## EXECUTION PHASES

### Phase 1: Create Directories
```bash
mkdir -p docs/{core,patching,scripts,health-checks,automation,roi,training,reference,advanced}
```

### Phase 2: Fix Duplicate Numbers (PRIORITY)
1. 00_Master_Index.md → 02_Master_Index.md
2. All duplicate 44s, 56s, 57s, 70s, 100s to new ranges

### Phase 3: Move Files to Subdirectories
Move all files according to category ranges

### Phase 4: Delete Duplicates
1. Delete Quick_Reference_Guide.md
2. Delete README.md (root)

### Phase 5: Update Cross-References
1. Update 02_Master_Index.md
2. Update 00_README.md
3. Update all internal documentation links

---

## SUMMARY

**Total Files:** 60 markdown files (+ 2 to delete)  
**Actions:**
- Move: 57 files to subdirectories
- Renumber: 52 files to new ranges
- Delete: 2 duplicate files
- Create: 9 directories
- Update: All cross-references

**Result:**
- ✅ No duplicate numbers
- ✅ Clear 35-space categorization
- ✅ 265 slots available for future growth
- ✅ One topic per file
- ✅ Logical subdirectory organization

---

**Status:** Ready for execution - awaiting approval
