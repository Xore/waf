#!/bin/bash
# NinjaRMM WAF Documentation Reorganization Script
# Generated: February 2, 2026
# This script moves and renames all markdown files according to the reorganization plan

set -e  # Exit on error

echo "========================================="
echo "Starting Documentation Reorganization"
echo "========================================="

# Phase 1: Directories already created via GitHub
echo ""
echo "Phase 1: Directory structure - COMPLETE (via GitHub)"

# Phase 2: Delete old file (now replaced by 02_Master_Index.md)
echo ""
echo "Phase 2: Removing duplicate 00_Master_Index.md..."
git rm 00_Master_Index.md
git commit -m "Remove 00_Master_Index.md (replaced by 02_Master_Index.md)"

# Phase 3: Move Core Framework files (10-17)
echo ""
echo "Phase 3: Moving Core Framework files (10-17)..."
git mv 10_OPS_STAT_RISK_Core_Metrics.md docs/core/10_OPS_STAT_RISK_Core_Metrics.md
git mv 11_AUTO_UX_SRV_Core_Experience.md docs/core/11_AUTO_UX_SRV_Core_Experience.md
git mv 12_DRIFT_CAP_BAT_Core_Monitoring.md docs/core/12_DRIFT_CAP_BAT_Core_Monitoring.md
git mv 13_NET_GPO_AD_Core_Network_Identity.md docs/core/13_NET_GPO_AD_Core_Network_Identity.md
git mv 14_BASE_SEC_UPD_Core_Security_Baseline.md docs/core/14_BASE_SEC_UPD_Core_Security_Baseline.md
git mv 22_IIS_MSSQL_MYSQL_Database_Web_Servers.md docs/core/15_Server_Roles_Database_Web.md
git mv 23_APACHE_VEEAM_DHCP_DNS_Infrastructure.md docs/core/16_Server_Roles_Infrastructure.md
git mv 24_EVT_FS_PRINT_HV_BL_FEAT_FLEXLM_Additional_Roles.md docs/core/17_Server_Roles_Additional.md
git commit -m "Move and renumber core framework files (10-17)"

# Phase 4: Move Patching files (45-53)
echo ""
echo "Phase 4: Moving Patching Framework files (45-53)..."
git mv 30_PATCH_Main_Patching_Framework.md docs/patching/45_Patching_Framework_Main.md
git mv 31_PATCH_Custom_Fields.md docs/patching/46_Patching_Custom_Fields.md
git mv 36_PATCH_Quick_Start_Guide.md docs/patching/47_Patching_Quick_Start.md
git mv 44_PATCH_Ring_Based_Deployment.md docs/patching/48_Patching_Ring_Deployment.md
git mv 46_PATCH_Windows_OS_Tutorial.md docs/patching/49_Patching_Windows_Tutorial.md
git mv 47_PATCH_Software_Patching_Tutorial.md docs/patching/50_Patching_Software_Tutorial.md
git mv 48_PATCH_Policy_Configuration_Guide.md docs/patching/51_Patching_Policy_Guide.md
git mv 61_Scripts_Patching_Automation.md docs/patching/52_Patching_Scripts.md
git mv PATCHING_GENERATION_SUMMARY.md docs/patching/53_Patching_Summary.md
git commit -m "Move and renumber patching files (45-53)"

# Phase 5: Move Script Documentation files (80-101)
echo ""
echo "Phase 5: Moving Script Documentation files (80-101)..."
git mv 55_Scripts_01_13_Infrastructure_Monitoring.md docs/scripts/80_Scripts_Monitoring_01_to_13.md
git mv 56_Custom_Fields_Scripts_14_20_Server_Monitoring.md docs/scripts/81_Scripts_Fields_14_to_20.md
git mv 57_Script_Conditions_Automation_Scripts_14_20.md docs/scripts/82_Scripts_Automation_14_to_20.md
git mv 53_Scripts_14_27_Extended_Automation.md docs/scripts/83_Scripts_Automation_14_to_27.md
git mv 59_Scripts_19_24_Extended_Automation.md docs/scripts/84_Scripts_Automation_19_to_24.md
git mv 54_Scripts_28_36_Advanced_Telemetry.md docs/scripts/85_Scripts_Telemetry_28_to_36.md
git mv 60_Scripts_22_24_27_34_36_Capacity_Predictive.md docs/scripts/86_Scripts_Capacity_Predictive.md
git mv 18_Scripts_Baseline_Refresh.md docs/scripts/90_Scripts_Baseline_Refresh.md
git mv 50_Scripts_Emergency_Disk_Cleanup.md docs/scripts/91_Scripts_Emergency_Cleanup.md
git mv 56_Scripts_Memory_Optimization.md docs/scripts/92_Scripts_Memory_Optimization.md
git mv 51_Field_to_Script_Complete_Mapping.md docs/scripts/93_Scripts_Field_Mapping.md
git mv 41_Scripts_Service_Restart_Print_Spooler.md docs/scripts/95_Scripts_Service_Print_Spooler.md
git mv 42_Scripts_Service_Restart_Windows_Update.md docs/scripts/96_Scripts_Service_Windows_Update.md
git mv 43_Scripts_Service_Restart_DNS_Client.md docs/scripts/97_Scripts_Service_DNS_Client.md
git mv 44_Scripts_Service_Restart_Network_Services.md docs/scripts/98_Scripts_Service_Network.md
git mv 45_Scripts_Service_Restart_Remote_Desktop.md docs/scripts/99_Scripts_Service_Remote_Desktop.md
git mv 57_Scripts_03_08_Infrastructure_Part1.md docs/scripts/100_Scripts_03_to_08_Part1_DEPRECATED.md
git mv 58_Scripts_07_08_11_12_Infrastructure_Part2.md docs/scripts/101_Scripts_07_to_12_Part2_DEPRECATED.md
git commit -m "Move and renumber script documentation files (80-101)"

# Phase 6: Move Health Checks files (115-117)
echo ""
echo "Phase 6: Moving Health Check files (115-117)..."
git mv 70_Custom_Health_Check_Quick_Reference.md docs/health-checks/115_Health_Checks_Quick_Reference.md
git mv 70_Custom_Health_Check_Templates.md docs/health-checks/116_Health_Checks_Templates.md
git mv CUSTOM_HEALTH_CHECK_SUMMARY.md docs/health-checks/117_Health_Checks_Summary.md
git commit -m "Move and renumber health check files (115-117)"

# Phase 7: Move Automation files (150-152)
echo ""
echo "Phase 7: Moving Automation files (150-152)..."
git mv 91_Compound_Conditions_Complete.md docs/automation/150_Compound_Conditions.md
git mv 92_Dynamic_Groups_Complete.md docs/automation/151_Dynamic_Groups.md
git mv 98_Framework_Complete_Summary_Master.md docs/automation/152_Framework_Master_Summary.md
git commit -m "Move and renumber automation files (150-152)"

# Phase 8: Move ROI files (185-186)
echo ""
echo "Phase 8: Moving ROI Analysis files (185-186)..."
git mv 100_Detailed_ROI_Analysis_No_ML.md docs/roi/185_ROI_Analysis_No_ML.md
git mv 100_Detailed_ROI_Analysis_ML_with_Platform_Costs.md docs/roi/186_ROI_Analysis_With_ML.md
git commit -m "Move and renumber ROI analysis files (185-186)"

# Phase 9: Move Training files (220-223)
echo ""
echo "Phase 9: Moving Training files (220-223)..."
git mv Framework_Training_Material_Part1.md docs/training/220_Training_Part1_Fundamentals.md
git mv Framework_Training_Material_Part2.md docs/training/221_Training_Part2_Advanced.md
git mv ML_Integration_Guide.md docs/training/222_Training_ML_Integration.md
git mv Troubleshooting_Guide_Servers_Clients.md docs/training/223_Troubleshooting_Guide.md
git commit -m "Move and renumber training files (220-223)"

# Phase 10: Move Reference files (255-260)
echo ""
echo "Phase 10: Moving Reference files (255-260)..."
git mv 99_Quick_Reference_Guide.md docs/reference/255_Quick_Reference.md
git mv Executive_Summary_Core_Framework.md docs/reference/256_Executive_Summary_Core.md
git mv Executive_Summary_ML_Framework.md docs/reference/257_Executive_Summary_ML.md
git mv Framework_Statistics_Summary.md docs/reference/258_Framework_Statistics.md
git mv Framework_Visual_Diagrams.md docs/reference/259_Framework_Diagrams.md
git mv NATIVE_INTEGRATION_OPTIMIZATION_SUMMARY.md docs/reference/260_Native_Integration_Summary.md
git commit -m "Move and renumber reference files (255-260)"

# Phase 11: Move Advanced files (290-293)
echo ""
echo "Phase 11: Moving Advanced topics files (290-293)..."
git mv Chapter_6_Advanced_RCA.md docs/advanced/290_RCA_Advanced.md
git mv Chapter_6_Explained.md docs/advanced/291_RCA_Explained.md
git mv Chapter_6_RCA_Diagrams.md docs/advanced/292_RCA_Diagrams.md
git mv ML_RCA_Integration.md docs/advanced/293_ML_RCA_Integration.md
git commit -m "Move and renumber advanced topic files (290-293)"

# Phase 12: Delete duplicate files
echo ""
echo "Phase 12: Deleting duplicate files..."
[ -f Quick_Reference_Guide.md ] && git rm Quick_Reference_Guide.md && echo "Removed Quick_Reference_Guide.md"
[ -f README.md ] && git rm README.md && echo "Removed README.md (keeping 00_README.md)"
git commit -m "Remove duplicate reference files"

# Push all changes
echo ""
echo "========================================="
echo "Reorganization Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - 9 directories created"
echo "  - 57 files moved and renumbered"
echo "  - 3 duplicate files removed"
echo "  - All changes committed"
echo ""
echo "Next step: Push to GitHub"
echo "  git push origin main"
echo ""
