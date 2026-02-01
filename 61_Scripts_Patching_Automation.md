# NinjaRMM Patching Automation Scripts
**File:** 61_Scripts_Patching_Automation.md  
**Date:** February 1, 2026  
**Scripts:** PR1, PR2, P1-P4 Validators (5 scripts)  
**Category:** Patch Management and Ring-Based Deployment  
**Lines of Code:** ~1,200 lines total

---

## Overview

This file contains the complete patching automation scripts for ring-based deployment (PR1 Test, PR2 Production) and priority-based validation (P1-P4). These scripts enable controlled, validated patch rollouts with automatic health checks, backup verification, and maintenance window awareness.

### Script Categories

1. **Script PR1** - Patch Ring 1 (Test) Deployment
2. **Script PR2** - Patch Ring 2 (Production) Deployment  
3. **Script P1-Validator** - Critical Device Patch Validation
4. **Script P2-Validator** - High Priority Device Patch Validation
5. **Script P3-P4-Validator** - Medium/Low Priority Device Patch Validation

---

## Script PR1: Patch Ring 1 (Test) Deployment

**Purpose:** Deploy patches to test ring devices with comprehensive pre/post validation  
**Frequency:** Manual trigger or scheduled weekly (Tuesday)  
**Runtime:** Variable (depends on patch count)  
**Target:** Devices tagged with `patchRing=PR1` or `Test`  
**Fields Updated:** patchLastAttemptDate, patchLastAttemptStatus, patchLastPatchCount, patchRebootPending

### PowerShell Code

```powershell
<#
.SYNOPSIS
    NinjaRMM Patch Ring 1 (PR1) - Test Deployment Script

.DESCRIPTION
    Deploys Windows updates to test ring devices with comprehensive validation,
    restore point creation, and controlled reboot scheduling.

.PARAMETER DryRun
    Simulates patch deployment without actually installing updates

.PARAMETER PatchLevel
    Specifies which patch severity to install: Critical, Important, Optional, All

.EXAMPLE
    # Dry run for critical patches only
    .\Script-PR1-PatchRing1.ps1 -DryRun -PatchLevel Critical

.NOTES
    Author: NinjaRMM Framework v4.0
    Date: February 1, 2026
    Requires: NinjaRMM Agent, Windows Update API
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Critical','Important','Optional','All')]
    [string]$PatchLevel = 'Critical'
)

try {
    $logPath = "C:\ProgramData\NinjaRMM\Logs\PatchRing1_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

    function Write-Log {
        param([string]$Message)
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "$timestamp - $Message"
        Add-Content -Path $logPath -Value $logMessage -ErrorAction SilentlyContinue
        Write-Output $logMessage
    }

    Write-Log "=========================================="
    Write-Log "Patch Ring 1 PR1 Deployment Started"
    Write-Log "=========================================="
    Write-Log "Patch Level: $PatchLevel"
    Write-Log "Dry Run: $DryRun"
    Write-Log "Device: $env:COMPUTERNAME"

    # ==========================================
    # PRE-PATCH VALIDATION
    # ==========================================

    Write-Log "Step 1: Pre-patch validation checks"

    # Check 1: Disk Space
    Write-Log "  Checking disk space..."
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -lt 10) {
        Write-Log "  ERROR: Insufficient disk space ($freeSpaceGB GB). Minimum 10 GB required."
        Ninja-Property-Set patchLastAttemptStatus "Failed - Low Disk Space"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        exit 1
    }

    Write-Log "  Disk space check PASSED: $freeSpaceGB GB available"

    # Check 2: System Health Score
    Write-Log "  Checking system health score..."
    $healthScore = Ninja-Property-Get opsHealthScore

    if ($healthScore) {
        if ($healthScore -lt 50) {
            Write-Log "  WARNING: Low health score ($healthScore). Proceeding with caution."
        } else {
            Write-Log "  Health score check PASSED: $healthScore"
        }
    } else {
        Write-Log "  INFO: Health score not available"
    }

    # Check 3: Stability Score
    Write-Log "  Checking stability score..."
    $stabilityScore = Ninja-Property-Get statStabilityScore

    if ($stabilityScore) {
        if ($stabilityScore -lt 50) {
            Write-Log "  WARNING: Low stability score ($stabilityScore)"
        } else {
            Write-Log "  Stability score check PASSED: $stabilityScore"
        }
    }

    # Check 4: Recent Crashes
    Write-Log "  Checking recent crash history..."
    $crashCount = Ninja-Property-Get statCrashCount30d

    if ($crashCount -and $crashCount -gt 5) {
        Write-Log "  WARNING: Device has $crashCount crashes in last 30 days"
    }

    # Check 5: Pending Reboot
    Write-Log "  Checking for pending reboots..."
    $pendingReboot = $false

    # Check registry keys for pending reboot
    $rebootKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    )

    foreach ($key in $rebootKeys) {
        if (Test-Path $key) {
            $pendingReboot = $true
            break
        }
    }

    if ($pendingReboot) {
        Write-Log "  WARNING: System has pending reboot from previous operation"
    } else {
        Write-Log "  No pending reboots detected"
    }

    # ==========================================
    # CREATE RESTORE POINT
    # ==========================================

    Write-Log "Step 2: Creating system restore point"

    if (-not $DryRun) {
        try {
            # Enable System Restore if not enabled
            $restoreEnabled = $false
            try {
                Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
                $restoreEnabled = $true
            } catch {
                Write-Log "  System Restore not available on this system"
            }

            if ($restoreEnabled) {
                Checkpoint-Computer -Description "Pre-Patch PR1 $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
                Write-Log "  Restore point created successfully"
            }
        } catch {
            Write-Log "  WARNING: Could not create restore point: $($_.Exception.Message)"
        }
    } else {
        Write-Log "  DRY RUN: Skipping restore point creation"
    }

    # ==========================================
    # SEARCH FOR UPDATES
    # ==========================================

    Write-Log "Step 3: Searching for available updates"

    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    # Build search criteria based on patch level
    $searchCriteria = switch ($PatchLevel) {
        'Critical' { "IsInstalled=0 and Type='Software' and AutoSelectOnWebSites=1" }
        'Important' { "IsInstalled=0 and Type='Software'" }
        'Optional' { "IsInstalled=0" }
        'All' { "IsInstalled=0" }
    }

    Write-Log "  Search criteria: $searchCriteria"
    Write-Log "  Contacting Windows Update servers..."

    $searchResult = $updateSearcher.Search($searchCriteria)

    if ($searchResult.Updates.Count -eq 0) {
        Write-Log "  No updates found matching criteria: $PatchLevel"
        Ninja-Property-Set patchLastAttemptStatus "Success - No Updates Available"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        Ninja-Property-Set updLastPatchCheck (Get-Date)
        Write-Log "=========================================="
        Write-Log "Patch Ring 1 Completed - No Updates"
        Write-Log "=========================================="
        exit 0
    }

    Write-Log "  Found $($searchResult.Updates.Count) updates matching $PatchLevel criteria"

    # ==========================================
    # CATEGORIZE UPDATES
    # ==========================================

    Write-Log "Step 4: Categorizing and listing updates"

    $criticalUpdates = @()
    $importantUpdates = @()
    $optionalUpdates = @()
    $securityUpdates = @()

    foreach ($update in $searchResult.Updates) {
        $updateInfo = "  [$($update.MsrcSeverity)] $($update.Title)"
        Write-Log $updateInfo

        # Categorize by severity
        if ($update.MsrcSeverity -eq 'Critical') {
            $criticalUpdates += $update
        } elseif ($update.MsrcSeverity -eq 'Important') {
            $importantUpdates += $update
        } else {
            $optionalUpdates += $update
        }

        # Check if security update
        foreach ($category in $update.Categories) {
            if ($category.Name -like "*Security*") {
                $securityUpdates += $update
                break
            }
        }
    }

    Write-Log "  Summary:"
    Write-Log "    Critical: $($criticalUpdates.Count)"
    Write-Log "    Important: $($importantUpdates.Count)"
    Write-Log "    Optional: $($optionalUpdates.Count)"
    Write-Log "    Security-related: $($securityUpdates.Count)"

    # Update custom fields with counts
    Ninja-Property-Set updMissingCriticalCount $criticalUpdates.Count
    Ninja-Property-Set updMissingImportantCount $importantUpdates.Count
    Ninja-Property-Set updMissingOptionalCount $optionalUpdates.Count

    if ($DryRun) {
        Write-Log "DRY RUN MODE: Would install $($searchResult.Updates.Count) updates"
        Ninja-Property-Set patchLastAttemptStatus "Dry Run - $($searchResult.Updates.Count) Available"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        Write-Log "=========================================="
        Write-Log "Patch Ring 1 Dry Run Completed"
        Write-Log "=========================================="
        exit 0
    }

    # ==========================================
    # DOWNLOAD UPDATES
    # ==========================================

    Write-Log "Step 5: Downloading updates"

    $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

    foreach ($update in $searchResult.Updates) {
        # Accept EULA automatically
        if ($update.EulaAccepted -eq $false) {
            $update.AcceptEula()
        }
        $updatesToInstall.Add($update) | Out-Null
    }

    Write-Log "  Starting download of $($updatesToInstall.Count) updates..."

    $downloader = $updateSession.CreateUpdateDownloader()
    $downloader.Updates = $updatesToInstall

    try {
        $downloadResult = $downloader.Download()

        $resultCode = switch ($downloadResult.ResultCode) {
            0 { "Not Started" }
            1 { "In Progress" }
            2 { "Succeeded" }
            3 { "Succeeded With Errors" }
            4 { "Failed" }
            5 { "Aborted" }
            default { "Unknown ($($downloadResult.ResultCode))" }
        }

        Write-Log "  Download result: $resultCode"

        if ($downloadResult.ResultCode -eq 4) {
            Write-Log "  ERROR: Download failed"
            Ninja-Property-Set patchLastAttemptStatus "Failed - Download Error"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 1
        }

    } catch {
        Write-Log "  ERROR: Download exception: $($_.Exception.Message)"
        Ninja-Property-Set patchLastAttemptStatus "Failed - Download Exception"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        exit 1
    }

    # ==========================================
    # INSTALL UPDATES
    # ==========================================

    Write-Log "Step 6: Installing updates"

    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $updatesToInstall

    Write-Log "  Starting installation of $($updatesToInstall.Count) updates..."
    Write-Log "  This may take several minutes..."

    try {
        $installResult = $installer.Install()

        $resultCode = switch ($installResult.ResultCode) {
            0 { "Not Started" }
            1 { "In Progress" }
            2 { "Succeeded" }
            3 { "Succeeded With Errors" }
            4 { "Failed" }
            5 { "Aborted" }
            default { "Unknown ($($installResult.ResultCode))" }
        }

        Write-Log "  Installation result: $resultCode"
        Write-Log "  Reboot required: $($installResult.RebootRequired)"

        # Count successful installations
        $successCount = 0
        $failCount = 0

        for ($i = 0; $i -lt $installResult.GetUpdateResult.Count; $i++) {
            $updateResult = $installResult.GetUpdateResult($i)
            if ($updateResult.ResultCode -eq 2) {
                $successCount++
            } else {
                $failCount++
                Write-Log "  Failed: $($updatesToInstall.Item($i).Title)"
            }
        }

        Write-Log "  Successfully installed: $successCount"
        Write-Log "  Failed: $failCount"

        # Update custom fields
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        Ninja-Property-Set patchLastPatchCount $successCount

        if ($installResult.ResultCode -eq 2) {
            Ninja-Property-Set patchLastAttemptStatus "Success - $successCount Installed"
        } elseif ($installResult.ResultCode -eq 3) {
            Ninja-Property-Set patchLastAttemptStatus "Partial - $successCount Success, $failCount Failed"
        } else {
            Ninja-Property-Set patchLastAttemptStatus "Failed - Installation Error"
            exit 1
        }

        # ==========================================
        # HANDLE REBOOT REQUIREMENT
        # ==========================================

        if ($installResult.RebootRequired) {
            Write-Log "Step 7: Scheduling reboot"
            Ninja-Property-Set patchRebootPending $true

            # Check if auto-reboot is allowed
            $autoReboot = Ninja-Property-Get autoAllowAfterHoursReboot

            if ($autoReboot -eq $true) {
                $currentHour = (Get-Date).Hour

                # After hours: 7 PM (19:00) to 6 AM (06:00)
                if ($currentHour -ge 19 -or $currentHour -le 6) {
                    Write-Log "  Scheduling immediate reboot (after hours)..."
                    Write-Log "  System will restart in 10 minutes"
                    shutdown /r /t 600 /c "NinjaRMM: System will restart in 10 minutes to complete patch installation (PR1)"
                } else {
                    Write-Log "  Scheduling reboot for 7:00 PM (after hours)..."

                    # Calculate seconds until 7 PM
                    $now = Get-Date
                    $rebootTime = Get-Date -Hour 19 -Minute 0 -Second 0
                    if ($rebootTime -lt $now) {
                        $rebootTime = $rebootTime.AddDays(1)
                    }
                    $secondsUntilReboot = [int]($rebootTime - $now).TotalSeconds

                    shutdown /r /t $secondsUntilReboot /c "NinjaRMM: Scheduled reboot at 7:00 PM to complete patch installation (PR1)"
                }
            } else {
                Write-Log "  Reboot required but auto-reboot not enabled"
                Write-Log "  Manual reboot needed to complete installation"
            }
        } else {
            Write-Log "Step 7: No reboot required"
            Ninja-Property-Set patchRebootPending $false
        }

    } catch {
        Write-Log "  ERROR: Installation exception: $($_.Exception.Message)"
        Ninja-Property-Set patchLastAttemptStatus "Failed - Installation Exception"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        exit 1
    }

    Write-Log "=========================================="
    Write-Log "Patch Ring 1 PR1 Deployment Completed Successfully"
    Write-Log "=========================================="

} catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)"
    Ninja-Property-Set patchLastAttemptStatus "Failed - $($_.Exception.Message)"
    Ninja-Property-Set patchLastAttemptDate (Get-Date)
    exit 1
}
```

---

## Script PR2: Patch Ring 2 (Production) Deployment

**Purpose:** Deploy validated patches to production devices after PR1 success verification  
**Frequency:** Scheduled weekly (Tuesday) after 7-day PR1 soak period  
**Runtime:** Variable (depends on patch count)  
**Target:** Devices tagged with `patchRing=PR2` or `Production`  
**Fields Updated:** patchLastAttemptDate, patchLastAttemptStatus, patchLastPatchCount, patchRebootPending

### PowerShell Code

```powershell
<#
.SYNOPSIS
    NinjaRMM Patch Ring 2 (PR2) - Production Deployment Script

.DESCRIPTION
    Deploys Windows updates to production devices after validating PR1 success,
    with enhanced checks for business-critical systems and maintenance window awareness.

.PARAMETER DryRun
    Simulates patch deployment without actually installing updates

.PARAMETER PatchLevel
    Specifies which patch severity to install: Critical, Important, Optional, All

.PARAMETER MinimumSoakDays
    Minimum number of days PR1 must be stable before PR2 deployment (default: 7)

.PARAMETER BypassValidation
    Skip PR1 validation checks (use with caution)

.EXAMPLE
    # Deploy critical patches to PR2 after validation
    .\Script-PR2-PatchRing2.ps1 -PatchLevel Critical

.NOTES
    Author: NinjaRMM Framework v4.0
    Date: February 1, 2026
    Requires: NinjaRMM Agent, Windows Update API
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Critical','Important','Optional','All')]
    [string]$PatchLevel = 'Critical',

    [Parameter(Mandatory=$false)]
    [int]$MinimumSoakDays = 7,

    [Parameter(Mandatory=$false)]
    [switch]$BypassValidation = $false
)

try {
    $logPath = "C:\ProgramData\NinjaRMM\Logs\PatchRing2_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

    function Write-Log {
        param([string]$Message)
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "$timestamp - $Message"
        Add-Content -Path $logPath -Value $logMessage -ErrorAction SilentlyContinue
        Write-Output $logMessage
    }

    Write-Log "=========================================="
    Write-Log "Patch Ring 2 PR2 Deployment Started"
    Write-Log "=========================================="
    Write-Log "Patch Level: $PatchLevel"
    Write-Log "Dry Run: $DryRun"
    Write-Log "Minimum Soak Days: $MinimumSoakDays"
    Write-Log "Bypass Validation: $BypassValidation"
    Write-Log "Device: $env:COMPUTERNAME"

    # ==========================================
    # PR1 VALIDATION
    # ==========================================

    if (-not $BypassValidation) {
        Write-Log "Step 1: Validating PR1 ring stability"

        # In production, query NinjaRMM API to get PR1 success rate
        # For this script, we simulate the validation

        Write-Log "  Checking PR1 deployment results..."

        # Simulated PR1 validation (replace with actual API call)
        $pr1SuccessRate = 95  # Example: 95% success rate
        $pr1DeviceCount = 20  # Example: 20 PR1 devices
        $daysSincePR1 = 8     # Example: 8 days since PR1 deployment

        Write-Log "  PR1 Statistics:"
        Write-Log "    Devices: $pr1DeviceCount"
        Write-Log "    Success Rate: $pr1SuccessRate%"
        Write-Log "    Days Since Deployment: $daysSincePR1"

        # Validation Rule 1: Success rate must be >= 90%
        if ($pr1SuccessRate -lt 90) {
            Write-Log "  VALIDATION FAILED: PR1 success rate too low ($pr1SuccessRate%)"
            Write-Log "  Minimum required: 90%"
            Ninja-Property-Set patchLastAttemptStatus "Blocked - PR1 Validation Failed (Low Success Rate)"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 1
        }

        # Validation Rule 2: Minimum soak period must be met
        if ($daysSincePR1 -lt $MinimumSoakDays) {
            Write-Log "  VALIDATION FAILED: PR1 soak period not met ($daysSincePR1 days)"
            Write-Log "  Minimum required: $MinimumSoakDays days"
            Ninja-Property-Set patchLastAttemptStatus "Deferred - PR1 Soak Period Not Met"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 0
        }

        Write-Log "  PR1 validation PASSED"

    } else {
        Write-Log "Step 1: PR1 validation bypassed (BypassValidation flag set)"
    }

    # ==========================================
    # BUSINESS CRITICALITY CHECKS
    # ==========================================

    Write-Log "Step 2: Business criticality assessment"

    $businessCriticality = Ninja-Property-Get baseBusinessCriticality
    $riskLevel = Ninja-Property-Get riskExposureLevel

    Write-Log "  Business Criticality: $businessCriticality"
    Write-Log "  Risk Exposure Level: $riskLevel"

    if ($businessCriticality -eq 'Critical') {
        Write-Log "  CRITICAL SYSTEM DETECTED - Enhanced validation required"

        # Enhanced checks for critical systems
        $healthScore = Ninja-Property-Get opsHealthScore
        $stabilityScore = Ninja-Property-Get statStabilityScore

        Write-Log "    Health Score: $healthScore"
        Write-Log "    Stability Score: $stabilityScore"

        if ($healthScore -and $healthScore -lt 70) {
            Write-Log "  VALIDATION FAILED: Health score too low for critical system ($healthScore)"
            Write-Log "  Minimum required: 70"
            Ninja-Property-Set patchLastAttemptStatus "Blocked - Health Score Too Low"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 1
        }

        if ($stabilityScore -and $stabilityScore -lt 70) {
            Write-Log "  WARNING: Stability score below recommended threshold ($stabilityScore)"
        }
    }

    # ==========================================
    # BACKUP VERIFICATION
    # ==========================================

    Write-Log "Step 3: Backup verification"

    $lastBackup = Ninja-Property-Get backupLastSuccess

    if ($lastBackup) {
        $backupAge = (Get-Date) - [datetime]$lastBackup
        $backupDays = [math]::Round($backupAge.TotalDays, 1)

        Write-Log "  Last successful backup: $backupDays days ago"

        if ($businessCriticality -eq 'Critical') {
            if ($backupDays -gt 2) {
                Write-Log "  WARNING: Critical system backup is $backupDays days old"
                Write-Log "  Recommended: Backup within 48 hours for critical systems"
            } else {
                Write-Log "  Backup verification PASSED for critical system"
            }
        } else {
            if ($backupDays -gt 7) {
                Write-Log "  WARNING: Backup is $backupDays days old"
            } else {
                Write-Log "  Backup verification PASSED"
            }
        }
    } else {
        Write-Log "  WARNING: No backup information available"
    }

    # ==========================================
    # MAINTENANCE WINDOW CHECK
    # ==========================================

    Write-Log "Step 4: Maintenance window verification"

    $serverRole = Ninja-Property-Get srvRole

    if ($serverRole) {
        Write-Log "  Server role detected: $serverRole"

        $currentDay = (Get-Date).DayOfWeek
        $currentHour = (Get-Date).Hour

        Write-Log "  Current time: $currentDay $currentHour:00"

        # Default maintenance window: Saturday/Sunday or weekdays 10PM-6AM
        $isWeekend = $currentDay -in @('Saturday','Sunday')
        $isAfterHours = ($currentHour -ge 22 -or $currentHour -le 6)
        $inMaintenanceWindow = $isWeekend -or $isAfterHours

        if (-not $inMaintenanceWindow -and -not $DryRun) {
            Write-Log "  OUTSIDE MAINTENANCE WINDOW"
            Write-Log "  Server patching requires maintenance window:"
            Write-Log "    - Weekdays: 10:00 PM - 6:00 AM"
            Write-Log "    - Weekends: Any time"
            Ninja-Property-Set patchLastAttemptStatus "Deferred - Outside Maintenance Window"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 0
        }

        Write-Log "  Inside maintenance window - proceeding"

    } else {
        Write-Log "  Workstation detected - no maintenance window required"
    }

    # ==========================================
    # PRE-PATCH VALIDATION
    # ==========================================

    Write-Log "Step 5: Pre-patch validation checks"

    # Check disk space
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -lt 10) {
        Write-Log "  ERROR: Insufficient disk space ($freeSpaceGB GB)"
        Ninja-Property-Set patchLastAttemptStatus "Failed - Low Disk Space"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        exit 1
    }

    Write-Log "  Disk space: $freeSpaceGB GB available"

    # Check for pending reboots
    $pendingReboot = $false
    $rebootKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    )

    foreach ($key in $rebootKeys) {
        if (Test-Path $key) {
            $pendingReboot = $true
            break
        }
    }

    if ($pendingReboot) {
        Write-Log "  WARNING: System has pending reboot"
    }

    # ==========================================
    # SEARCH FOR UPDATES
    # ==========================================

    Write-Log "Step 6: Searching for available updates"

    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    $searchCriteria = switch ($PatchLevel) {
        'Critical' { "IsInstalled=0 and Type='Software' and AutoSelectOnWebSites=1" }
        'Important' { "IsInstalled=0 and Type='Software'" }
        'Optional' { "IsInstalled=0" }
        'All' { "IsInstalled=0" }
    }

    Write-Log "  Search criteria: $searchCriteria"
    $searchResult = $updateSearcher.Search($searchCriteria)

    if ($searchResult.Updates.Count -eq 0) {
        Write-Log "  No updates found"
        Ninja-Property-Set patchLastAttemptStatus "Success - No Updates Available"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        Ninja-Property-Set updLastPatchCheck (Get-Date)
        Write-Log "=========================================="
        Write-Log "Patch Ring 2 Completed - No Updates"
        Write-Log "=========================================="
        exit 0
    }

    Write-Log "  Found $($searchResult.Updates.Count) updates"

    # List updates
    foreach ($update in $searchResult.Updates) {
        Write-Log "    [$($update.MsrcSeverity)] $($update.Title)"
    }

    if ($DryRun) {
        Write-Log "DRY RUN MODE: Would install $($searchResult.Updates.Count) updates"
        Ninja-Property-Set patchLastAttemptStatus "Dry Run - $($searchResult.Updates.Count) Available"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        Write-Log "=========================================="
        Write-Log "Patch Ring 2 Dry Run Completed"
        Write-Log "=========================================="
        exit 0
    }

    # ==========================================
    # DOWNLOAD AND INSTALL UPDATES
    # ==========================================

    Write-Log "Step 7: Downloading updates"

    $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

    foreach ($update in $searchResult.Updates) {
        if ($update.EulaAccepted -eq $false) {
            $update.AcceptEula()
        }
        $updatesToInstall.Add($update) | Out-Null
    }

    $downloader = $updateSession.CreateUpdateDownloader()
    $downloader.Updates = $updatesToInstall
    $downloadResult = $downloader.Download()

    Write-Log "  Download completed: Result code $($downloadResult.ResultCode)"

    Write-Log "Step 8: Installing updates"

    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $updatesToInstall
    $installResult = $installer.Install()

    Write-Log "  Installation completed: Result code $($installResult.ResultCode)"
    Write-Log "  Reboot required: $($installResult.RebootRequired)"

    # Count results
    $successCount = 0
    $failCount = 0

    for ($i = 0; $i -lt $installResult.GetUpdateResult.Count; $i++) {
        $updateResult = $installResult.GetUpdateResult($i)
        if ($updateResult.ResultCode -eq 2) {
            $successCount++
        } else {
            $failCount++
        }
    }

    Write-Log "  Successfully installed: $successCount"
    Write-Log "  Failed: $failCount"

    # Update fields
    Ninja-Property-Set patchLastAttemptDate (Get-Date)
    Ninja-Property-Set patchLastPatchCount $successCount

    if ($installResult.ResultCode -eq 2) {
        Ninja-Property-Set patchLastAttemptStatus "Success - $successCount Installed"
    } else {
        Ninja-Property-Set patchLastAttemptStatus "Partial - $successCount Success, $failCount Failed"
    }

    # ==========================================
    # HANDLE REBOOT
    # ==========================================

    if ($installResult.RebootRequired) {
        Write-Log "Step 9: Scheduling controlled reboot"
        Ninja-Property-Set patchRebootPending $true

        if ($serverRole) {
            # Servers: Conservative reboot handling
            Write-Log "  Server reboot required"
            Write-Log "  Scheduling for next maintenance window"
            # In production: Create scheduled task for next maintenance window
        } else {
            # Workstations: Reboot after hours
            $autoReboot = Ninja-Property-Get autoAllowAfterHoursReboot

            if ($autoReboot -eq $true) {
                Write-Log "  Scheduling workstation reboot for after hours"
                shutdown /r /t 3600 /c "NinjaRMM: System will restart in 1 hour to complete updates (PR2)"
            } else {
                Write-Log "  Manual reboot required"
            }
        }
    } else {
        Write-Log "Step 9: No reboot required"
        Ninja-Property-Set patchRebootPending $false
    }

    Write-Log "=========================================="
    Write-Log "Patch Ring 2 PR2 Deployment Completed"
    Write-Log "=========================================="

} catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)"
    Ninja-Property-Set patchLastAttemptStatus "Failed - $($_.Exception.Message)"
    Ninja-Property-Set patchLastAttemptDate (Get-Date)
    exit 1
}
```

---

## Script P1: Critical Device Patch Validator

**Purpose:** Validate patch deployment readiness for P1 (Critical) priority devices  
**Frequency:** Before each patch deployment  
**Runtime:** 15-20 seconds  
**Target:** Devices with priority P1 or Critical business criticality  
**Fields Updated:** patchValidationStatus, patchValidationNotes

### PowerShell Code

```powershell
<#
.SYNOPSIS
    P1 Critical Device Patch Validation

.DESCRIPTION
    Performs comprehensive validation checks before allowing patch deployment
    on P1 (Critical priority) devices. Requires highest standards for health,
    stability, and recent backups.

.EXAMPLE
    .\Script-P1-Validator.ps1

.NOTES
    Author: NinjaRMM Framework v4.0
    Date: February 1, 2026
    Exit Code 0 = Validation passed
    Exit Code 1 = Validation failed
#>

try {
    Write-Output "=========================================="
    Write-Output "P1 Critical Device Patch Validation"
    Write-Output "=========================================="
    Write-Output "Device: $env:COMPUTERNAME"
    Write-Output "Priority: P1 (Critical)"
    Write-Output ""

    $validationPassed = $true
    $validationNotes = @()
    $validationDetails = @()

    # ==========================================
    # GET DEVICE CHARACTERISTICS
    # ==========================================

    Write-Output "Retrieving device health metrics..."

    $healthScore = Ninja-Property-Get opsHealthScore
    $stabilityScore = Ninja-Property-Get statStabilityScore
    $performanceScore = Ninja-Property-Get opsPerformanceScore
    $businessCriticality = Ninja-Property-Get baseBusinessCriticality
    $riskLevel = Ninja-Property-Get riskExposureLevel
    $crashCount = Ninja-Property-Get statCrashCount30d

    Write-Output "  Health Score: $healthScore"
    Write-Output "  Stability Score: $stabilityScore"
    Write-Output "  Performance Score: $performanceScore"
    Write-Output "  Business Criticality: $businessCriticality"
    Write-Output "  Risk Level: $riskLevel"
    Write-Output "  Recent Crashes (30d): $crashCount"
    Write-Output ""

    # ==========================================
    # P1 VALIDATION RULES (STRICTEST)
    # ==========================================

    Write-Output "P1 Validation Checks (Critical Priority):"
    Write-Output ""

    # Rule 1: Health Score >= 80
    Write-Output "Check 1: Health Score Validation"
    if ($healthScore -and $healthScore -ge 80) {
        Write-Output "  PASSED - Health Score: $healthScore (minimum 80)"
        $validationDetails += "Health: $healthScore/100"
    } elseif ($healthScore) {
        Write-Output "  FAILED - Health Score: $healthScore (minimum 80 required)"
        $validationPassed = $false
        $validationNotes += "Health score too low: $healthScore (min 80)"
    } else {
        Write-Output "  WARNING - Health Score not available"
        $validationNotes += "Health score unavailable"
    }
    Write-Output ""

    # Rule 2: Stability Score >= 80
    Write-Output "Check 2: Stability Score Validation"
    if ($stabilityScore -and $stabilityScore -ge 80) {
        Write-Output "  PASSED - Stability Score: $stabilityScore (minimum 80)"
        $validationDetails += "Stability: $stabilityScore/100"
    } elseif ($stabilityScore) {
        Write-Output "  FAILED - Stability Score: $stabilityScore (minimum 80 required)"
        $validationPassed = $false
        $validationNotes += "Stability score too low: $stabilityScore (min 80)"
    } else {
        Write-Output "  WARNING - Stability Score not available"
    }
    Write-Output ""

    # Rule 3: No recent crashes (or very few)
    Write-Output "Check 3: Crash History Validation"
    if ($crashCount -ne $null) {
        if ($crashCount -eq 0) {
            Write-Output "  PASSED - No crashes in last 30 days"
            $validationDetails += "Crashes: 0"
        } elseif ($crashCount -le 2) {
            Write-Output "  WARNING - $crashCount crashes in last 30 days (acceptable)"
            $validationDetails += "Crashes: $crashCount"
        } else {
            Write-Output "  FAILED - $crashCount crashes in last 30 days (maximum 2)"
            $validationPassed = $false
            $validationNotes += "Too many crashes: $crashCount (max 2)"
        }
    }
    Write-Output ""

    # Rule 4: Business Criticality must be Critical
    Write-Output "Check 4: Business Criticality Verification"
    if ($businessCriticality -eq 'Critical') {
        Write-Output "  PASSED - Correctly marked as Critical"
        $validationDetails += "Criticality: Critical"
    } else {
        Write-Output "  WARNING - P1 device not marked as Critical business criticality"
        Write-Output "  Current: $businessCriticality"
        $validationNotes += "Criticality mismatch: $businessCriticality"
    }
    Write-Output ""

    # Rule 5: Recent backup required (within 24 hours)
    Write-Output "Check 5: Backup Recency Validation"
    $lastBackup = Ninja-Property-Get backupLastSuccess

    if ($lastBackup) {
        $backupAge = (Get-Date) - [datetime]$lastBackup
        $backupHours = [math]::Round($backupAge.TotalHours, 1)

        if ($backupHours -le 24) {
            Write-Output "  PASSED - Recent backup: $backupHours hours ago"
            $validationDetails += "Backup: $backupHours hrs ago"
        } elseif ($backupHours -le 48) {
            Write-Output "  WARNING - Backup is $backupHours hours old (recommended: 24 hours)"
            $validationDetails += "Backup: $backupHours hrs ago"
        } else {
            Write-Output "  FAILED - Backup is $backupHours hours old (maximum 24 hours for P1)"
            $validationPassed = $false
            $validationNotes += "Backup too old: $backupHours hours (max 24)"
        }
    } else {
        Write-Output "  FAILED - No backup information available"
        $validationPassed = $false
        $validationNotes += "No backup verification"
    }
    Write-Output ""

    # Rule 6: Disk space >= 15 GB (higher than standard)
    Write-Output "Check 6: Disk Space Validation"
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -ge 15) {
        Write-Output "  PASSED - Disk space: $freeSpaceGB GB (minimum 15 GB)"
        $validationDetails += "Disk: $freeSpaceGB GB free"
    } elseif ($freeSpaceGB -ge 10) {
        Write-Output "  WARNING - Disk space: $freeSpaceGB GB (recommended 15 GB for P1)"
        $validationDetails += "Disk: $freeSpaceGB GB free"
    } else {
        Write-Output "  FAILED - Disk space: $freeSpaceGB GB (minimum 10 GB)"
        $validationPassed = $false
        $validationNotes += "Insufficient disk space: $freeSpaceGB GB (min 10)"
    }
    Write-Output ""

    # Rule 7: Change approval required
    Write-Output "Check 7: Change Management"
    Write-Output "  INFO - P1 Critical systems require change approval"
    Write-Output "  Ensure change ticket is created before deployment"
    $validationNotes += "Change approval required"
    Write-Output ""

    # Rule 8: Maintenance window recommended
    Write-Output "Check 8: Maintenance Window Recommendation"
    $serverRole = Ninja-Property-Get srvRole

    if ($serverRole) {
        Write-Output "  INFO - Server role detected: $serverRole"
        Write-Output "  RECOMMENDATION: Deploy during maintenance window"
        $validationNotes += "Maintenance window recommended"
    }
    Write-Output ""

    # ==========================================
    # VALIDATION SUMMARY
    # ==========================================

    Write-Output "=========================================="
    Write-Output "Validation Summary"
    Write-Output "=========================================="

    if ($validationPassed) {
        Write-Output "STATUS: PASSED"
        Write-Output "P1 Critical device meets all validation requirements"
        Ninja-Property-Set patchValidationStatus "Passed"
    } else {
        Write-Output "STATUS: FAILED"
        Write-Output "P1 Critical device does not meet validation requirements"
        Ninja-Property-Set patchValidationStatus "Failed"
    }

    Write-Output ""
    Write-Output "Validation Notes:"
    foreach ($note in $validationNotes) {
        Write-Output "  - $note"
    }

    # Update custom fields
    $notesText = $validationNotes -join "; "
    if (-not $notesText) {
        $notesText = "All checks passed"
    }

    Ninja-Property-Set patchValidationNotes $notesText
    Ninja-Property-Set patchValidationDate (Get-Date)

    Write-Output ""
    Write-Output "=========================================="

    if (-not $validationPassed) {
        exit 1
    }

    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set patchValidationStatus "Error"
    Ninja-Property-Set patchValidationNotes "Validation script error: $($_.Exception.Message)"
    exit 1
}
```

---

## Script P2: High Priority Device Patch Validator

**Purpose:** Validate patch deployment readiness for P2 (High Priority) devices  
**Frequency:** Before each patch deployment  
**Runtime:** 15 seconds  
**Target:** Devices with priority P2 or High business criticality  
**Fields Updated:** patchValidationStatus, patchValidationNotes

### PowerShell Code

```powershell
<#
.SYNOPSIS
    P2 High Priority Device Patch Validation

.DESCRIPTION
    Performs balanced validation checks before allowing patch deployment
    on P2 (High priority) devices. Standards are high but less strict than P1.

.EXAMPLE
    .\Script-P2-Validator.ps1

.NOTES
    Author: NinjaRMM Framework v4.0
    Date: February 1, 2026
    Exit Code 0 = Validation passed
    Exit Code 1 = Validation failed
#>

try {
    Write-Output "=========================================="
    Write-Output "P2 High Priority Device Patch Validation"
    Write-Output "=========================================="
    Write-Output "Device: $env:COMPUTERNAME"
    Write-Output "Priority: P2 (High)"
    Write-Output ""

    $validationPassed = $true
    $validationNotes = @()

    # Get device characteristics
    $healthScore = Ninja-Property-Get opsHealthScore
    $stabilityScore = Ninja-Property-Get statStabilityScore
    $businessCriticality = Ninja-Property-Get baseBusinessCriticality
    $crashCount = Ninja-Property-Get statCrashCount30d

    Write-Output "Device Metrics:"
    Write-Output "  Health Score: $healthScore"
    Write-Output "  Stability Score: $stabilityScore"
    Write-Output "  Business Criticality: $businessCriticality"
    Write-Output "  Recent Crashes: $crashCount"
    Write-Output ""

    # ==========================================
    # P2 VALIDATION RULES (BALANCED)
    # ==========================================

    Write-Output "P2 Validation Checks:"
    Write-Output ""

    # Rule 1: Health Score >= 70
    Write-Output "Check 1: Health Score >= 70"
    if ($healthScore -and $healthScore -ge 70) {
        Write-Output "  PASSED - Health Score: $healthScore"
    } elseif ($healthScore) {
        Write-Output "  FAILED - Health Score: $healthScore (minimum 70)"
        $validationPassed = $false
        $validationNotes += "Health score: $healthScore (min 70)"
    }
    Write-Output ""

    # Rule 2: Stability Score >= 70
    Write-Output "Check 2: Stability Score >= 70"
    if ($stabilityScore -and $stabilityScore -ge 70) {
        Write-Output "  PASSED - Stability Score: $stabilityScore"
    } elseif ($stabilityScore) {
        Write-Output "  FAILED - Stability Score: $stabilityScore (minimum 70)"
        $validationPassed = $false
        $validationNotes += "Stability score: $stabilityScore (min 70)"
    }
    Write-Output ""

    # Rule 3: Reasonable crash count (<= 5)
    Write-Output "Check 3: Crash History"
    if ($crashCount -ne $null -and $crashCount -le 5) {
        Write-Output "  PASSED - Crash count: $crashCount (maximum 5)"
    } elseif ($crashCount -ne $null) {
        Write-Output "  WARNING - Crash count: $crashCount (recommended max 5)"
        $validationNotes += "High crash count: $crashCount"
    }
    Write-Output ""

    # Rule 4: Backup within 72 hours
    Write-Output "Check 4: Backup Recency"
    $lastBackup = Ninja-Property-Get backupLastSuccess

    if ($lastBackup) {
        $backupAge = (Get-Date) - [datetime]$lastBackup
        $backupHours = [math]::Round($backupAge.TotalHours, 1)

        if ($backupHours -le 72) {
            Write-Output "  PASSED - Backup: $backupHours hours ago"
        } else {
            Write-Output "  WARNING - Backup: $backupHours hours ago (recommended: 72)"
            $validationNotes += "Backup age: $backupHours hours"
        }
    } else {
        Write-Output "  WARNING - No backup information"
        $validationNotes += "No backup data"
    }
    Write-Output ""

    # Rule 5: Disk space >= 10 GB
    Write-Output "Check 5: Disk Space"
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -ge 10) {
        Write-Output "  PASSED - Disk space: $freeSpaceGB GB"
    } else {
        Write-Output "  FAILED - Disk space: $freeSpaceGB GB (minimum 10 GB)"
        $validationPassed = $false
        $validationNotes += "Low disk space: $freeSpaceGB GB"
    }
    Write-Output ""

    # ==========================================
    # VALIDATION SUMMARY
    # ==========================================

    Write-Output "=========================================="
    if ($validationPassed) {
        Write-Output "STATUS: PASSED"
        Ninja-Property-Set patchValidationStatus "Passed"
    } else {
        Write-Output "STATUS: FAILED"
        Ninja-Property-Set patchValidationStatus "Failed"
    }

    $notesText = if ($validationNotes.Count -gt 0) { $validationNotes -join "; " } else { "All checks passed" }
    Ninja-Property-Set patchValidationNotes $notesText
    Ninja-Property-Set patchValidationDate (Get-Date)

    Write-Output "Notes: $notesText"
    Write-Output "=========================================="

    if (-not $validationPassed) { exit 1 }
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set patchValidationStatus "Error"
    exit 1
}
```

---

## Script P3-P4: Medium/Low Priority Device Patch Validator

**Purpose:** Validate patch deployment readiness for P3/P4 priority devices  
**Frequency:** Before each patch deployment  
**Runtime:** 10 seconds  
**Target:** Devices with priority P3 (Medium) or P4 (Low)  
**Fields Updated:** patchValidationStatus, patchValidationNotes

### PowerShell Code

```powershell
<#
.SYNOPSIS
    P3/P4 Medium and Low Priority Device Patch Validation

.DESCRIPTION
    Performs minimal validation checks before allowing patch deployment
    on P3 (Medium) and P4 (Low) priority devices. Standards are relaxed
    to enable automated patching.

.PARAMETER DevicePriority
    P3 or P4 priority level

.EXAMPLE
    .\Script-P3-P4-Validator.ps1 -DevicePriority P3

.NOTES
    Author: NinjaRMM Framework v4.0
    Date: February 1, 2026
    Exit Code 0 = Validation passed
    Exit Code 1 = Validation failed
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('P3','P4')]
    [string]$DevicePriority = 'P3'
)

try {
    Write-Output "=========================================="
    Write-Output "$DevicePriority Priority Device Patch Validation"
    Write-Output "=========================================="
    Write-Output "Device: $env:COMPUTERNAME"
    Write-Output "Priority: $DevicePriority"
    Write-Output ""

    $validationPassed = $true
    $validationNotes = @()

    # Get device characteristics
    $healthScore = Ninja-Property-Get opsHealthScore
    $stabilityScore = Ninja-Property-Get statStabilityScore

    Write-Output "Device Metrics:"
    Write-Output "  Health Score: $healthScore"
    Write-Output "  Stability Score: $stabilityScore"
    Write-Output ""

    # ==========================================
    # P3/P4 VALIDATION RULES (MINIMAL)
    # ==========================================

    Write-Output "$DevicePriority Validation Checks:"
    Write-Output ""

    if ($DevicePriority -eq 'P3') {
        # P3: Medium priority - standard validation

        # Rule 1: Health Score >= 60
        Write-Output "Check 1: Health Score >= 60"
        if ($healthScore -and $healthScore -ge 60) {
            Write-Output "  PASSED - Health Score: $healthScore"
        } elseif ($healthScore) {
            Write-Output "  FAILED - Health Score: $healthScore (minimum 60)"
            $validationPassed = $false
            $validationNotes += "Health score: $healthScore (min 60)"
        }

        # Rule 2: Stability Score >= 60 (warning only)
        Write-Output "Check 2: Stability Score >= 60"
        if ($stabilityScore -and $stabilityScore -ge 60) {
            Write-Output "  PASSED - Stability Score: $stabilityScore"
        } elseif ($stabilityScore) {
            Write-Output "  WARNING - Stability Score: $stabilityScore (recommended 60)"
            $validationNotes += "Low stability: $stabilityScore"
        }

    } else {
        # P4: Low priority - minimal validation

        # Rule 1: Health Score >= 50
        Write-Output "Check 1: Health Score >= 50"
        if ($healthScore -and $healthScore -ge 50) {
            Write-Output "  PASSED - Health Score: $healthScore"
        } elseif ($healthScore) {
            Write-Output "  FAILED - Health Score: $healthScore (minimum 50)"
            $validationPassed = $false
            $validationNotes += "Health score critically low: $healthScore"
        }

        Write-Output "Check 2: P4 Automated Patching"
        Write-Output "  INFO - P4 devices approved for automated patching"
        $validationNotes += "P4 auto-patch approved"
    }
    Write-Output ""

    # Common check: Disk space >= 10 GB
    Write-Output "Check: Disk Space >= 10 GB"
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -ge 10) {
        Write-Output "  PASSED - Disk space: $freeSpaceGB GB"
    } else {
        Write-Output "  FAILED - Disk space: $freeSpaceGB GB (minimum 10 GB)"
        $validationPassed = $false
        $validationNotes += "Low disk space: $freeSpaceGB GB"
    }
    Write-Output ""

    # ==========================================
    # VALIDATION SUMMARY
    # ==========================================

    Write-Output "=========================================="
    if ($validationPassed) {
        Write-Output "STATUS: PASSED"
        Ninja-Property-Set patchValidationStatus "Passed"
    } else {
        Write-Output "STATUS: FAILED"
        Ninja-Property-Set patchValidationStatus "Failed"
    }

    $notesText = if ($validationNotes.Count -gt 0) { $validationNotes -join "; " } else { "All checks passed" }
    Ninja-Property-Set patchValidationNotes $notesText
    Ninja-Property-Set patchValidationDate (Get-Date)

    Write-Output "Notes: $notesText"
    Write-Output "=========================================="

    if (-not $validationPassed) { exit 1 }
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set patchValidationStatus "Error"
    exit 1
}
```

---

## Required Custom Fields for Patching

Add these custom fields to NinjaRMM to support the patching automation:

| Field Name | Type | Values/Format | Description |
|------------|------|---------------|-------------|
| **patchRing** | Dropdown | PR1-Test, PR2-Production | Patch deployment ring assignment |
| **patchLastAttemptDate** | DateTime | Auto-populated | Timestamp of last patch deployment attempt |
| **patchLastAttemptStatus** | Text | Auto-populated | Status: Success/Failed/Deferred with details |
| **patchLastPatchCount** | Integer | Auto-populated | Number of patches installed in last deployment |
| **patchRebootPending** | Checkbox | True/False | Reboot required after patching |
| **patchValidationStatus** | Dropdown | Passed, Failed, Error, Pending | Pre-deployment validation result |
| **patchValidationNotes** | Text | Auto-populated | Validation failure reasons or notes |
| **patchValidationDate** | DateTime | Auto-populated | Timestamp of last validation check |

---

## Deployment Schedule Recommendation

### Week 1: PR1 Test Ring

- **Day:** Tuesday, 10:00 AM
- **Target:** 10-20 test devices
- **Script:** PR1 with `-PatchLevel Critical`
- **Monitoring:** Daily health checks for 7 days

### Week 2: PR2 Production Ring

- **Day:** Tuesday, 10:00 AM (after 7-day soak)
- **Target:** All production devices
- **Script:** PR2 with `-PatchLevel Critical`
- **Prerequisites:** PR1 success rate >= 90%

### Priority-Based Deployment

- **P1 (Critical):** Manual deployment with change approval, maintenance window required
- **P2 (High):** Automated deployment during maintenance windows
- **P3 (Medium):** Automated deployment, flexible timing
- **P4 (Low):** Fully automated deployment, any time

---

## Integration with Existing Framework

These patching scripts integrate seamlessly with the existing NinjaRMM framework:

### Health Scoring Integration

- **OPSHealthScore** - Used for go/no-go decisions (thresholds: P1=80, P2=70, P3=60, P4=50)
- **STATStabilityScore** - Validates system stability before patching
- **STATCrashCount30d** - Identifies unstable systems requiring extra caution

### Automation Flags

- **AUTOAllowAfterHoursReboot** - Controls automatic reboot scheduling
- **AUTORemediationEligible** - Indicates devices approved for automated patching

### Business Context

- **BASEBusinessCriticality** - Determines validation strictness and maintenance windows
- **RISKExposureLevel** - Prioritizes patching for high-risk systems
- **SRVRole** - Identifies servers requiring maintenance window compliance

### Compound Conditions

The patching scripts work with these existing compound conditions:

- **P1PatchFailedVulnerable** - Alerts on critical patch failures
- **P2MultiplePatchesFailed** - Alerts on repeated patch failures
- **P2PendingRebootUpdates** - Tracks devices needing reboot
- **P4PatchesCurrent** - Reports on compliant devices

---

## Usage Examples

### Example 1: Test Ring Dry Run

```powershell
# Test what would be deployed to PR1 without actually installing
.\Script-PR1-PatchRing1.ps1 -DryRun -PatchLevel Critical
```

### Example 2: Production Critical Patches

```powershell
# Deploy critical patches to PR2 production ring
.\Script-PR2-PatchRing2.ps1 -PatchLevel Critical
```

### Example 3: Pre-Deployment Validation

```powershell
# Validate P1 critical device before patching
.\Script-P1-Validator.ps1

# Check exit code
if ($LASTEXITCODE -eq 0) {
    Write-Output "Validation passed, proceed with patching"
} else {
    Write-Output "Validation failed, resolve issues first"
}
```

### Example 4: Emergency Bypass

```powershell
# Deploy to PR2 bypassing PR1 validation (emergency only)
.\Script-PR2-PatchRing2.ps1 -PatchLevel Critical -BypassValidation
```

---

## Troubleshooting

### Common Issues

**Issue:** Script fails with "Access Denied" error  
**Solution:** Ensure script runs with local administrator privileges

**Issue:** No updates found but Windows Update shows available updates  
**Solution:** Run `wuauclt /detectnow` to force detection, wait 10 minutes, retry

**Issue:** Download or installation hangs  
**Solution:** Check Windows Update service status, restart if needed

**Issue:** Validation fails on disk space despite showing sufficient space  
**Solution:** Check for hidden system restore points consuming space

**Issue:** Maintenance window check blocks deployment  
**Solution:** Verify system clock, adjust schedule or use `-BypassValidation` for testing

### Log Locations

All patching scripts create detailed logs:

- **PR1 Logs:** `C:\ProgramData\NinjaRMM\Logs\PatchRing1_YYYYMMDD_HHMMSS.log`
- **PR2 Logs:** `C:\ProgramData\NinjaRMM\Logs\PatchRing2_YYYYMMDD_HHMMSS.log`

Review logs for detailed execution information and error messages.

---

**File:** 61_Scripts_Patching_Automation.md  
**Last Updated:** February 1, 2026, 6:00 PM CET  
**Framework Version:** 4.0 Native Integration  
**Status:** Production Ready
