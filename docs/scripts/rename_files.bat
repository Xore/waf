@echo off
REM File Renaming Script for docs/scripts/
REM Renames Script_##_ files to ##_ format
REM Run this from the docs/scripts/ directory

echo Starting file renaming process...
echo.

REM Phase 1: Rename Script_ prefix files to numeric format
echo Phase 1: Renaming Script_ files to numeric format
echo ================================================

move "Script_01_OPS_Health_Score_Calculator.md" "01_OPS_Health_Score_Calculator.md"
move "Script_02_OPS_Stability_Analyzer.md" "02_OPS_Stability_Analyzer.md"
move "Script_03_OPS_Performance_Analyzer.md" "03_OPS_Performance_Analyzer.md"
move "Script_04_OPS_Security_Analyzer.md" "04_OPS_Security_Analyzer.md"
move "Script_05_OPS_Capacity_Analyzer.md" "05_OPS_Capacity_Analyzer.md"
move "Script_06_STAT_Telemetry_Collector.md" "06_STAT_Telemetry_Collector.md"
move "Script_07_BL_BitLocker_Monitor.md" "07_BL_BitLocker_Monitor.md"
move "Script_08_HV_HyperV_Host_Monitor.md" "08_HV_HyperV_Host_Monitor.md"
move "Script_09_RISK_Classifier.md" "09_RISK_Classifier.md"
move "Script_10_UPD_Update_Assessment_Collector.md" "10_UPD_Update_Assessment_Collector.md"
move "Script_11_NET_Location_Tracker.md" "11_NET_Location_Tracker.md"
move "Script_12_BASE_Baseline_Manager.md" "12_BASE_Baseline_Manager.md"
move "Script_13_DRIFT_Detector.md" "13_DRIFT_Detector.md"
move "Script_14_DRIFT_Local_Admin_Analyzer.md" "14_DRIFT_Local_Admin_Analyzer.md"
move "Script_15_SEC_Security_Posture_Consolidator.md" "15_SEC_Security_Posture_Consolidator.md"
move "Script_16_SEC_Suspicious_Login_Detector.md" "16_SEC_Suspicious_Login_Detector.md"
move "Script_17_UX_Application_Experience_Profiler.md" "17_UX_Application_Experience_Profiler.md"
move "Script_18_CLEANUP_Profile_Hygiene_Advisor.md" "18_CLEANUP_Profile_Hygiene_Advisor.md"
move "Script_19_UX_Chronic_Slow_Boot_Detector.md" "19_UX_Chronic_Slow_Boot_Detector.md"
move "Script_20_DRIFT_Shadow_IT_Detector.md" "20_DRIFT_Shadow_IT_Detector.md"
move "Script_21_DRIFT_Critical_Service_Monitor.md" "21_DRIFT_Critical_Service_Monitor.md"
move "Script_22_CAP_Predictive_Analytics.md" "22_CAP_Predictive_Analytics.md"
move "Script_23_UPD_Patch_Compliance_Aging.md" "23_UPD_Patch_Compliance_Aging.md"
move "Script_24_PRED_Device_Lifetime_Predictor.md" "24_PRED_Device_Lifetime_Predictor.md"
move "Script_25_Reserved.md" "25_Reserved.md"
move "Script_26_Reserved.md" "26_Reserved.md"
move "Script_27_Reserved.md" "27_Reserved.md"
move "Script_28_SEC_Security_Surface_Telemetry.md" "28_SEC_Security_Surface_Telemetry.md"
move "Script_29_UX_Collaboration_Telemetry.md" "29_UX_Collaboration_Telemetry.md"
move "Script_30_UX_User_Environment_Friction.md" "30_UX_User_Environment_Friction.md"
move "Script_31_NET_Remote_Connectivity_Quality.md" "31_NET_Remote_Connectivity_Quality.md"
move "Script_32_HW_Thermal_Firmware_Telemetry.md" "32_HW_Thermal_Firmware_Telemetry.md"
move "Script_33_Reserved.md" "33_Reserved.md"
move "Script_34_LIC_Licensing_Feature_Utilization.md" "34_LIC_Licensing_Feature_Utilization.md"
move "Script_35_BASE_Baseline_Coverage_Telemetry.md" "35_BASE_Baseline_Coverage_Telemetry.md"
move "Script_36_SRV_Server_Role_Detector.md" "36_SRV_Server_Role_Detector.md"
move "Script_37_Reserved.md" "37_Reserved.md"
move "Script_38_Reserved.md" "38_Reserved.md"
move "Script_39_Reserved.md" "39_Reserved.md"
move "Script_40_Reserved.md" "40_Reserved.md"
move "Script_41_Reserved.md" "41_Reserved.md"
move "Script_42_Reserved.md" "42_Reserved.md"
move "Script_43_Reserved.md" "43_Reserved.md"
move "Script_44_Reserved.md" "44_Reserved.md"

echo.
echo Phase 1 complete - 44 files renamed
echo.

REM Phase 2: Move old monolithic files to deprecated folder
echo Phase 2: Moving old files to deprecated folder
echo ================================================

REM Create deprecated folder if it doesn't exist
if not exist "deprecated" mkdir deprecated

move "80_Scripts_Monitoring_01_to_13.md" "deprecated\80_Scripts_Monitoring_01_to_13.md"
move "81_Scripts_Fields_14_to_20.md" "deprecated\81_Scripts_Fields_14_to_20.md"
move "82_Scripts_Automation_14_to_20.md" "deprecated\82_Scripts_Automation_14_to_20.md"
move "83_Scripts_Automation_14_to_27.md" "deprecated\83_Scripts_Automation_14_to_27.md"
move "84_Scripts_Automation_19_to_24.md" "deprecated\84_Scripts_Automation_19_to_24.md"
move "85_Scripts_Telemetry_28_to_36.md" "deprecated\85_Scripts_Telemetry_28_to_36.md"
move "86_Scripts_Capacity_Predictive.md" "deprecated\86_Scripts_Capacity_Predictive.md"
move "90_Scripts_Baseline_Refresh.md" "deprecated\90_Scripts_Baseline_Refresh.md"
move "91_Scripts_Emergency_Cleanup.md" "deprecated\91_Scripts_Emergency_Cleanup.md"
move "92_Scripts_Memory_Optimization.md" "deprecated\92_Scripts_Memory_Optimization.md"
move "93_Scripts_Field_Mapping.md" "deprecated\93_Scripts_Field_Mapping.md"
move "95_Scripts_Service_Print_Spooler.md" "deprecated\95_Scripts_Service_Print_Spooler.md"
move "96_Scripts_Service_Windows_Update.md" "deprecated\96_Scripts_Service_Windows_Update.md"
move "97_Scripts_Service_DNS_Client.md" "deprecated\97_Scripts_Service_DNS_Client.md"
move "98_Scripts_Service_Network.md" "deprecated\98_Scripts_Service_Network.md"
move "99_Scripts_Service_Remote_Desktop.md" "deprecated\99_Scripts_Service_Remote_Desktop.md"
move "100_Scripts_03_to_08_Part1_DEPRECATED.md" "deprecated\100_Scripts_03_to_08_Part1_DEPRECATED.md"
move "101_Scripts_07_to_12_Part2_DEPRECATED.md" "deprecated\101_Scripts_07_to_12_Part2_DEPRECATED.md"

echo.
echo Phase 2 complete - 18 files moved to deprecated
echo.
echo ================================================
echo File renaming complete!
echo.
echo Summary:
echo - 44 files renamed from Script_## to ## format
echo - 18 old files moved to deprecated folder
echo.
echo Next steps:
echo 1. Review the changes
echo 2. Run: git add .
echo 3. Run: git commit -m "Rename script files to numeric prefix format"
echo 4. Run: git push
echo.
pause
