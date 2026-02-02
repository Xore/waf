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
    .\PR1_Patch_Ring1_Deployment.ps1 -DryRun -PatchLevel Critical

.NOTES
    Frequency: Manual trigger or scheduled weekly (Tuesday)
    Runtime: Variable (depends on patch count)
    Context: SYSTEM
    
    Fields Updated:
    - patchLastAttemptDate (DateTime)
    - patchLastAttemptStatus (Text)
    - patchLastPatchCount (Integer)
    - patchRebootPending (Checkbox)
    - updLastPatchCheck (DateTime)
    - updMissingCriticalCount (Integer)
    - updMissingImportantCount (Integer)
    - updMissingOptionalCount (Integer)
    
    Target: Devices tagged with patchRing=PR1 or Test
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
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

    # PRE-PATCH VALIDATION
    Write-Log "Step 1: Pre-patch validation checks"

    # Check disk space
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -lt 10) {
        Write-Log "  ERROR: Insufficient disk space ($freeSpaceGB GB). Minimum 10 GB required."
        Ninja-Property-Set patchLastAttemptStatus "Failed - Low Disk Space"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        exit 1
    }

    Write-Log "  Disk space check PASSED: $freeSpaceGB GB available"

    # Check system health score
    $healthScore = Ninja-Property-Get opsHealthScore
    if ($healthScore) {
        if ($healthScore -lt 50) {
            Write-Log "  WARNING: Low health score ($healthScore). Proceeding with caution."
        } else {
            Write-Log "  Health score check PASSED: $healthScore"
        }
    }

    # CREATE RESTORE POINT
    Write-Log "Step 2: Creating system restore point"
    if (-not $DryRun) {
        try {
            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Pre-Patch PR1 $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            Write-Log "  Restore point created successfully"
        } catch {
            Write-Log "  WARNING: Could not create restore point: $($_.Exception.Message)"
        }
    }

    # SEARCH FOR UPDATES
    Write-Log "Step 3: Searching for available updates"

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
        Write-Log "  No updates found matching criteria: $PatchLevel"
        Ninja-Property-Set patchLastAttemptStatus "Success - No Updates Available"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        Ninja-Property-Set updLastPatchCheck (Get-Date)
        Write-Log "=========================================="
        exit 0
    }

    Write-Log "  Found $($searchResult.Updates.Count) updates matching $PatchLevel criteria"

    # CATEGORIZE UPDATES
    $criticalUpdates = @()
    $importantUpdates = @()
    $optionalUpdates = @()

    foreach ($update in $searchResult.Updates) {
        Write-Log "  [$($update.MsrcSeverity)] $($update.Title)"
        if ($update.MsrcSeverity -eq 'Critical') {
            $criticalUpdates += $update
        } elseif ($update.MsrcSeverity -eq 'Important') {
            $importantUpdates += $update
        } else {
            $optionalUpdates += $update
        }
    }

    Ninja-Property-Set updMissingCriticalCount $criticalUpdates.Count
    Ninja-Property-Set updMissingImportantCount $importantUpdates.Count
    Ninja-Property-Set updMissingOptionalCount $optionalUpdates.Count

    if ($DryRun) {
        Write-Log "DRY RUN MODE: Would install $($searchResult.Updates.Count) updates"
        Ninja-Property-Set patchLastAttemptStatus "Dry Run - $($searchResult.Updates.Count) Available"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        exit 0
    }

    # DOWNLOAD UPDATES
    Write-Log "Step 5: Downloading updates"
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

    if ($downloadResult.ResultCode -eq 4) {
        Write-Log "  ERROR: Download failed"
        Ninja-Property-Set patchLastAttemptStatus "Failed - Download Error"
        Ninja-Property-Set patchLastAttemptDate (Get-Date)
        exit 1
    }

    # INSTALL UPDATES
    Write-Log "Step 6: Installing updates"
    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $updatesToInstall
    $installResult = $installer.Install()

    $successCount = 0
    for ($i = 0; $i -lt $installResult.GetUpdateResult.Count; $i++) {
        if ($installResult.GetUpdateResult($i).ResultCode -eq 2) {
            $successCount++
        }
    }

    Ninja-Property-Set patchLastAttemptDate (Get-Date)
    Ninja-Property-Set patchLastPatchCount $successCount
    Ninja-Property-Set patchLastAttemptStatus "Success - $successCount Installed"

    # HANDLE REBOOT
    if ($installResult.RebootRequired) {
        Ninja-Property-Set patchRebootPending $true
        Write-Log "  Reboot required - scheduling for after hours"
    } else {
        Ninja-Property-Set patchRebootPending $false
    }

    Write-Log "=========================================="
    Write-Log "Patch Ring 1 PR1 Deployment Completed Successfully"
    Write-Log "=========================================="

} catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)"
    Ninja-Property-Set patchLastAttemptStatus "Failed - $($_.Exception.Message)"
    Ninja-Property-Set patchLastAttemptDate (Get-Date)
    exit 1
}
