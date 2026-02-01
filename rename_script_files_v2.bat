@echo off
REM NinjaRMM Framework File Renaming Script v2.0
REM Standardizes script documentation filenames to: NUMBER_Scripts_Description.md
REM Resolves numbering conflicts (55, 61-65)
REM Created: February 1, 2026

echo NinjaRMM Framework File Renaming Utility v2.0
echo ================================================
echo.

REM Create backup directory
if not exist "backup" mkdir backup
echo Creating backup of original files...
xcopy *.md backup\ /Y /Q
echo Backup complete.
echo.

echo Renaming files to standard format: NUMBER_Scripts_Description.md
echo.

REM ====================================================================
REM BASELINE MANAGEMENT - Script 18
REM ====================================================================
if exist "18_Baseline_Refresh.md" (
    ren "18_Baseline_Refresh.md" "18_Scripts_Baseline_Refresh.md"
    echo [OK] 18_Scripts_Baseline_Refresh.md
)

REM ====================================================================
REM SERVICE RESTART SCRIPTS - Scripts 41-45
REM ====================================================================
if exist "41_Service_Restart_Restart_Print_Spooler.md" (
    ren "41_Service_Restart_Restart_Print_Spooler.md" "41_Scripts_Service_Restart_Print_Spooler.md"
    echo [OK] 41_Scripts_Service_Restart_Print_Spooler.md
)

if exist "42_Service_Restart_Restart_Windows_Update.md" (
    ren "42_Service_Restart_Restart_Windows_Update.md" "42_Scripts_Service_Restart_Windows_Update.md"
    echo [OK] 42_Scripts_Service_Restart_Windows_Update.md
)

if exist "43_Service_Restart_Restart_DNS_Client.md" (
    ren "43_Service_Restart_Restart_DNS_Client.md" "43_Scripts_Service_Restart_DNS_Client.md"
    echo [OK] 43_Scripts_Service_Restart_DNS_Client.md
)

if exist "44_Service_Restart_Restart_Network_Services.md" (
    ren "44_Service_Restart_Restart_Network_Services.md" "44_Scripts_Service_Restart_Network_Services.md"
    echo [OK] 44_Scripts_Service_Restart_Network_Services.md
)

if exist "45_Service_Restart_Restart_Remote_Desktop.md" (
    ren "45_Service_Restart_Restart_Remote_Desktop.md" "45_Scripts_Service_Restart_Remote_Desktop.md"
    echo [OK] 45_Scripts_Service_Restart_Remote_Desktop.md
)

REM ====================================================================
REM EMERGENCY RESPONSE - Script 50
REM ====================================================================
if exist "50_Emergency_Disk_Cleanup.md" (
    ren "50_Emergency_Disk_Cleanup.md" "50_Scripts_Emergency_Disk_Cleanup.md"
    echo [OK] 50_Scripts_Emergency_Disk_Cleanup.md
)

REM ====================================================================
REM MEMORY OPTIMIZATION - Script 56 (renamed from 55 to avoid conflict)
REM Note: 55_Scripts_01_13_Infrastructure_Monitoring.md already exists
REM ====================================================================
if exist "55_Memory_Optimization.md" (
    ren "55_Memory_Optimization.md" "56_Scripts_Memory_Optimization.md"
    echo [OK] 56_Scripts_Memory_Optimization.md ^(renumbered from 55^)
)

REM ====================================================================
REM SECURITY HARDENING - Scripts 66-70 (renumbered from 61-65 to avoid conflict)
REM Note: 61_Scripts_Patching_Automation.md already exists
REM ====================================================================
if exist "61_Security_Hardening_Disable_SMBv1_and_Enable_Firewall.md" (
    ren "61_Security_Hardening_Disable_SMBv1_and_Enable_Firewall.md" "66_Scripts_Security_Hardening_SMBv1_Firewall.md"
    echo [OK] 66_Scripts_Security_Hardening_SMBv1_Firewall.md ^(renumbered from 61^)
)

if exist "62_Security_Hardening_Enable_BitLocker_Encryption.md" (
    ren "62_Security_Hardening_Enable_BitLocker_Encryption.md" "67_Scripts_Security_Hardening_BitLocker.md"
    echo [OK] 67_Scripts_Security_Hardening_BitLocker.md ^(renumbered from 62^)
)

if exist "63_Security_Hardening_Configure_Windows_Defender.md" (
    ren "63_Security_Hardening_Configure_Windows_Defender.md" "68_Scripts_Security_Hardening_Windows_Defender.md"
    echo [OK] 68_Scripts_Security_Hardening_Windows_Defender.md ^(renumbered from 63^)
)

if exist "64_Security_Hardening_Disable_Unnecessary_Services.md" (
    ren "64_Security_Hardening_Disable_Unnecessary_Services.md" "69_Scripts_Security_Hardening_Disable_Services.md"
    echo [OK] 69_Scripts_Security_Hardening_Disable_Services.md ^(renumbered from 64^)
)

if exist "65_Security_Hardening_Configure_Security_Policies.md" (
    ren "65_Security_Hardening_Configure_Security_Policies.md" "70_Scripts_Security_Hardening_Security_Policies.md"
    echo [OK] 70_Scripts_Security_Hardening_Security_Policies.md ^(renumbered from 65^)
)

echo.
echo ================================================
echo File renaming complete!
echo ================================================
echo.
echo Summary of changes:
echo   - Baseline Management: 18_Scripts_Baseline_Refresh.md
echo   - Service Restarts: 41-45_Scripts_Service_Restart_*.md
echo   - Emergency Response: 50_Scripts_Emergency_Disk_Cleanup.md
echo   - Memory Optimization: 56_Scripts_Memory_Optimization.md ^(renumbered^)
echo   - Security Hardening: 66-70_Scripts_Security_Hardening_*.md ^(renumbered^)
echo.
echo Backup saved in: backup\
echo.
echo Standard format: NUMBER_Scripts_Description.md
echo.
pause
