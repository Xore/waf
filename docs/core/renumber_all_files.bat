@echo off
REM Complete renumbering and standardization script for docs/core/
REM Fixes duplicate numbers and standardizes naming schema
REM Run this from the docs/core/ directory
REM
REM Naming Schema:
REM   NN_PREFIX_Description.md
REM   - NN: Two-digit sequential number (00-18)
REM   - PREFIX: Single category prefix (OPS, AUTO, SEC, BASE, etc.)
REM   - Description: Clear, concise description
REM
REM Changes:
REM   1. Fix duplicate numbers (08, 09)
REM   2. Standardize Server_Roles_* to ROLE_*
REM   3. Remove redundant Core_ from names
REM   4. Sequential numbering 00-18

echo ================================================================
echo NinjaRMM WAF Documentation Renumbering Script
echo ================================================================
echo.
echo This script will:
echo   - Fix duplicate file numbers
echo   - Standardize naming schema
echo   - Apply sequential numbering 00-18
echo.
echo Current issues:
echo   - Duplicate number 08 (DRIFT + SEC)
echo   - Duplicate number 09 (CAP + UPD)
echo   - Inconsistent Server_Roles_* naming
echo   - Extra Core_ in some filenames
echo.
pause
echo.

REM Step 1: Rename to temporary names to avoid conflicts
echo Step 1: Creating temporary file names...
echo ================================================================
move "01_OPS_Core_Operational_Scores.md" "TEMP_01_OPS_Operational_Scores.md"
move "03_STAT_Core_Telemetry.md" "TEMP_03_STAT_Telemetry.md"
move "04_RISK_Core_Classification.md" "TEMP_04_RISK_Classification.md"
move "08_SEC_Security_Monitoring.md" "TEMP_09_SEC_Security_Monitoring.md"
move "09_CAP_Capacity_Planning.md" "TEMP_10_CAP_Capacity_Planning.md"
move "09_UPD_Update_Management.md" "TEMP_11_UPD_Update_Management.md"
move "10_Server_Roles_Database_Web.md" "TEMP_12_ROLE_Database_Web.md"
move "11_BAT_Battery_Health.md" "TEMP_13_BAT_Battery_Health.md"
move "12_Server_Roles_Infrastructure.md" "TEMP_14_ROLE_Infrastructure.md"
move "13_NET_Network_Monitoring.md" "TEMP_15_NET_Network_Monitoring.md"
move "14_Server_Roles_Additional.md" "TEMP_16_ROLE_Additional.md"
move "15_GPO_Group_Policy.md" "TEMP_17_GPO_Group_Policy.md"
move "16_AD_Active_Directory.md" "TEMP_18_AD_Active_Directory.md"

echo.
echo Step 1 complete - All files renamed to temporary names
echo.

REM Step 2: Rename from temporary to final names
echo Step 2: Applying final file names...
echo ================================================================
move "TEMP_01_OPS_Operational_Scores.md" "01_OPS_Operational_Scores.md"
move "TEMP_03_STAT_Telemetry.md" "03_STAT_Telemetry.md"
move "TEMP_04_RISK_Classification.md" "04_RISK_Classification.md"
move "TEMP_09_SEC_Security_Monitoring.md" "09_SEC_Security_Monitoring.md"
move "TEMP_10_CAP_Capacity_Planning.md" "10_CAP_Capacity_Planning.md"
move "TEMP_11_UPD_Update_Management.md" "11_UPD_Update_Management.md"
move "TEMP_12_ROLE_Database_Web.md" "12_ROLE_Database_Web.md"
move "TEMP_13_BAT_Battery_Health.md" "13_BAT_Battery_Health.md"
move "TEMP_14_ROLE_Infrastructure.md" "14_ROLE_Infrastructure.md"
move "TEMP_15_NET_Network_Monitoring.md" "15_NET_Network_Monitoring.md"
move "TEMP_16_ROLE_Additional.md" "16_ROLE_Additional.md"
move "TEMP_17_GPO_Group_Policy.md" "17_GPO_Group_Policy.md"
move "TEMP_18_AD_Active_Directory.md" "18_AD_Active_Directory.md"

echo.
echo ================================================================
echo Renumbering complete!
echo ================================================================
echo.
echo Summary of changes:
echo   - Fixed duplicate numbers (08, 09)
echo   - Renamed 13 files
echo   - Applied sequential numbering 00-18
echo   - Standardized naming schema
echo.
echo Final file structure:
echo   00_EXTRACTION_SUMMARY.md
echo   01_OPS_Operational_Scores.md
echo   02_AUTO_Automation_Control.md
echo   03_STAT_Telemetry.md
echo   04_RISK_Classification.md
echo   05_UX_User_Experience.md
echo   06_SRV_Server_Intelligence.md
echo   07_BASE_Baseline_Management.md
echo   08_DRIFT_Configuration_Drift.md
echo   09_SEC_Security_Monitoring.md
echo   10_CAP_Capacity_Planning.md
echo   11_UPD_Update_Management.md
echo   12_ROLE_Database_Web.md
echo   13_BAT_Battery_Health.md
echo   14_ROLE_Infrastructure.md
echo   15_NET_Network_Monitoring.md
echo   16_ROLE_Additional.md
echo   17_GPO_Group_Policy.md
echo   18_AD_Active_Directory.md
echo.
echo Naming Schema Applied:
echo   NN_PREFIX_Description.md
echo   - NN: Sequential number (00-18)
echo   - PREFIX: Single category prefix
echo   - Description: Concise, clear name
echo.
echo Next steps:
echo   1. Review the changes
echo   2. Run: git status
echo   3. Run: git add .
echo   4. Run: git commit -m "Standardize file numbering and naming schema"
echo   5. Run: git push
echo.
pause
