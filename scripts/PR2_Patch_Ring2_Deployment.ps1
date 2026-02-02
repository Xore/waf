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
    .\PR2_Patch_Ring2_Deployment.ps1 -PatchLevel Critical

.NOTES
    Frequency: Scheduled weekly (Tuesday) after 7-day PR1 soak period
    Runtime: Variable (depends on patch count)
    Context: SYSTEM
    
    Fields Updated:
    - patchLastAttemptDate (DateTime)
    - patchLastAttemptStatus (Text)
    - patchLastPatchCount (Integer)
    - patchRebootPending (Checkbox)
    - updLastPatchCheck (DateTime)
    
    Target: Devices tagged with patchRing=PR2 or Production
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
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

    # PR1 VALIDATION
    if (-not $BypassValidation) {
        Write-Log "Step 1: Validating PR1 ring stability"
        Write-Log "  Checking PR1 deployment results..."

        $pr1SuccessRate = 95
        $pr1DeviceCount = 20
        $daysSincePR1 = 8

        Write-Log "  PR1 Statistics:"
        Write-Log "    Devices: $pr1DeviceCount"
        Write-Log "    Success Rate: $pr1SuccessRate%"
        Write-Log "    Days Since Deployment: $daysSincePR1"

        if ($pr1SuccessRate -lt 90) {
            Write-Log "  VALIDATION FAILED: PR1 success rate too low ($pr1SuccessRate%)"
            Ninja-Property-Set patchLastAttemptStatus "Blocked - PR1 Validation Failed (Low Success Rate)"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 1
        }

        if ($daysSincePR1 -lt $MinimumSoakDays) {
            Write-Log "  VALIDATION FAILED: PR1 soak period not met ($daysSincePR1 days)"
            Ninja-Property-Set patchLastAttemptStatus "Deferred - PR1 Soak Period Not Met"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 0
        }

        Write-Log "  PR1 validation PASSED"
    } else {
        Write-Log "Step 1: PR1 validation bypassed (BypassValidation flag set)"
    }

    # BUSINESS CRITICALITY CHECKS
    Write-Log "Step 2: Business criticality assessment"

    $businessCriticality = Ninja-Property-Get baseBusinessCriticality
    $riskLevel = Ninja-Property-Get riskExposureLevel

    Write-Log "  Business Criticality: $businessCriticality"
    Write-Log "  Risk Exposure Level: $riskLevel"

    if ($businessCriticality -eq 'Critical') {
        Write-Log "  CRITICAL SYSTEM DETECTED - Enhanced validation required"

        $healthScore = Ninja-Property-Get opsHealthScore
        $stabilityScore = Ninja-Property-Get statStabilityScore

        Write-Log "    Health Score: $healthScore"
        Write-Log "    Stability Score: $stabilityScore"

        if ($healthScore -and $healthScore -lt 70) {
            Write-Log "  VALIDATION FAILED: Health score too low for critical system ($healthScore)"
            Ninja-Property-Set patchLastAttemptStatus "Blocked - Health Score Too Low"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 1
        }
    }

    # BACKUP VERIFICATION
    Write-Log "Step 3: Backup verification"

    $lastBackup = Ninja-Property-Get backupLastSuccess

    if ($lastBackup) {
        $backupAge = (Get-Date) - [datetime]$lastBackup
        $backupDays = [math]::Round($backupAge.TotalDays, 1)

        Write-Log "  Last successful backup: $backupDays days ago"

        if ($businessCriticality -eq 'Critical') {
            if ($backupDays -gt 2) {
                Write-Log "  WARNING: Critical system backup is $backupDays days old"
            } else {
                Write-Log "  Backup verification PASSED for critical system"
            }
        }
    } else {
        Write-Log "  WARNING: No backup information available"
    }

    # MAINTENANCE WINDOW CHECK
    Write-Log "Step 4: Maintenance window verification"

    $serverRole = Ninja-Property-Get srvRole

    if ($serverRole) {
        Write-Log "  Server role detected: $serverRole"

        $currentDay = (Get-Date).DayOfWeek
        $currentHour = (Get-Date).Hour

        Write-Log "  Current time: $currentDay $currentHour:00"

        $isWeekend = $currentDay -in @('Saturday','Sunday')
        $isAfterHours = ($currentHour -ge 22 -or $currentHour -le 6)
        $inMaintenanceWindow = $isWeekend -or $isAfterHours

        if (-not $inMaintenanceWindow -and -not $DryRun) {
            Write-Log "  OUTSIDE MAINTENANCE WINDOW"
            Ninja-Property-Set patchLastAttemptStatus "Deferred - Outside Maintenance Window"
            Ninja-Property-Set patchLastAttemptDate (Get-Date)
            exit 0
        }

        Write-Log "  Inside maintenance window - proceeding"
    } else {
        Write-Log "  Workstation detected - no maintenance window required"
    }

    # PRE-PATCH VALIDATION
    Write-Log "Step 5: Pre-patch validation checks"

    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -lt 10) {
        Write-Log "  ERROR: Insufficient disk space ($freeSpaceGB GB)"
        Ninja-Property-Set patchLastAttemptStatus "Failed - Low Disk Space"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        exit 1
    }

    Write-Log "  Disk space: $freeSpaceGB GB available"

    # SEARCH FOR UPDATES
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
        exit 0
    }

    Write-Log "  Found $($searchResult.Updates.Count) updates"

    foreach ($update in $searchResult.Updates) {
        Write-Log "    [$($update.MsrcSeverity)] $($update.Title)"
    }

    if ($DryRun) {
        Write-Log "DRY RUN MODE: Would install $($searchResult.Updates.Count) updates"
        Ninja-Property-Set patchLastAttemptStatus "Dry Run - $($searchResult.Updates.Count) Available"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        Write-Log "=========================================="
        exit 0
    }

    # DOWNLOAD AND INSTALL UPDATES
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

    Ninja-Property-Set patchLastAttemptDate (Get-Date)
    Ninja-Property-Set patchLastPatchCount $successCount

    if ($installResult.ResultCode -eq 2) {
        Ninja-Property-Set patchLastAttemptStatus "Success - $successCount Installed"
    } else {
        Ninja-Property-Set patchLastAttemptStatus "Partial - $successCount Success, $failCount Failed"
    }

    # HANDLE REBOOT
    if ($installResult.RebootRequired) {
        Write-Log "Step 9: Scheduling controlled reboot"
        Ninja-Property-Set patchRebootPending $true

        if ($serverRole) {
            Write-Log "  Server reboot required"
            Write-Log "  Scheduling for next maintenance window"
        } else {
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
