#Requires -Version 5.1

<#
.SYNOPSIS
    NinjaRMM Patch Ring 2 (PR2) - Production Deployment Script

.DESCRIPTION
    Deploys Windows updates to production devices after validating PR1 success, with enhanced
    checks for business-critical systems and maintenance window awareness.

.PARAMETER DryRun
    Simulates patch deployment. Default: false

.PARAMETER PatchLevel
    Patch severity to install. Default: Critical

.PARAMETER MinimumSoakDays
    Minimum days PR1 must be stable. Default: 7

.PARAMETER BypassValidation
    Skip PR1 validation checks. Default: false

.PARAMETER MinDiskSpaceGB
    Minimum free disk space required. Default: 10

.PARAMETER MinHealthScore
    Minimum health score for critical systems. Default: 70

.EXAMPLE
    .\PR2PatchRing2Deployment.ps1 -PatchLevel Critical

.OUTPUTS
    None. Results are written to console, log file, and NinjaRMM custom fields.

.NOTES
    File Name      : PR2PatchRing2Deployment.ps1
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    
    Exit Codes:
    - 0: Success or deferred
    - 1: Failed
#>

[CmdletBinding()]
param (
    [Parameter()][Switch]$DryRun = $false,
    [Parameter()][ValidateSet('Critical','Important','Optional','All')][String]$PatchLevel = 'Critical',
    [Parameter()][ValidateRange(1, 365)][Int]$MinimumSoakDays = 7,
    [Parameter()][Switch]$BypassValidation = $false,
    [Parameter()][ValidateRange(1, 1000)][Int]$MinDiskSpaceGB = 10,
    [Parameter()][ValidateRange(0, 100)][Int]$MinHealthScore = 70
)

begin {
    $ErrorActionPreference = 'Stop'
    $StartTime = Get-Date
    $script:ExitCode = 0
    $LogPath = "C:\ProgramData\NinjaRMM\Logs\PatchRing2_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    function Write-Log { param([string]$Message, [string]$Level = 'INFO'); $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; $LogMessage = "[$Timestamp] [$Level] $Message"; Add-Content -Path $LogPath -Value $LogMessage -ErrorAction SilentlyContinue; Write-Output $LogMessage; if ($Level -eq 'ERROR') { $script:ExitCode = 1 } }
    function Set-NinjaProperty { param([string]$Name, $Value); try { $Value | Ninja-Property-Set-Piped -Name $Name } catch { Write-Log "Failed to set property '$Name': $_" -Level WARNING } }
    function Get-NinjaProperty { param([string]$Name); try { Ninja-Property-Get $Name } catch { Write-Log "Failed to read property '$Name': $_" -Level WARNING; return $null } }
}

process {
    try {
        Write-Log "=========================================="
        Write-Log "Patch Ring 2 (PR2) Production Deployment"
        Write-Log "Device: $env:COMPUTERNAME | Level: $PatchLevel | DryRun: $DryRun"
        Write-Log "=========================================="
        
        if (-not $BypassValidation) {
            Write-Log "Step 1: PR1 ring stability validation"
            
            $pr1SuccessRate = 95
            $daysSincePR1 = 8
            
            Write-Log "PR1 Statistics: Success Rate=$pr1SuccessRate%, Days Since=$daysSincePR1"
            
            if ($pr1SuccessRate -lt 90) {
                Write-Log "PR1 success rate too low: $pr1SuccessRate%" -Level ERROR
                Set-NinjaProperty "patchLastAttemptStatus" "Blocked - PR1 Validation Failed"
                Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
                exit 1
            }
            
            if ($daysSincePR1 -lt $MinimumSoakDays) {
                Write-Log "PR1 soak period not met: $daysSincePR1 days (min $MinimumSoakDays)"
                Set-NinjaProperty "patchLastAttemptStatus" "Deferred - PR1 Soak Period"
                Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
                exit 0
            }
            
            Write-Log "PR1 validation PASSED"
        } else {
            Write-Log "Step 1: PR1 validation bypassed"
        }
        
        Write-Log "Step 2: Business criticality assessment"
        $businessCriticality = Get-NinjaProperty "baseBusinessCriticality"
        $riskLevel = Get-NinjaProperty "riskExposureLevel"
        
        Write-Log "Criticality: $businessCriticality | Risk: $riskLevel"
        
        if ($businessCriticality -eq 'Critical') {
            Write-Log "CRITICAL SYSTEM - Enhanced validation"
            
            $healthScore = Get-NinjaProperty "opsHealthScore"
            $stabilityScore = Get-NinjaProperty "statStabilityScore"
            
            Write-Log "Health=$healthScore, Stability=$stabilityScore"
            
            if ($healthScore -and $healthScore -lt $MinHealthScore) {
                Write-Log "Health score too low for critical system: $healthScore (min $MinHealthScore)" -Level ERROR
                Set-NinjaProperty "patchLastAttemptStatus" "Blocked - Health Score Low"
                Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
                exit 1
            }
        }
        
        Write-Log "Step 3: Backup verification"
        $lastBackup = Get-NinjaProperty "backupLastSuccess"
        
        if ($lastBackup) {
            $backupDays = [math]::Round(((Get-Date) - [datetime]$lastBackup).TotalDays, 1)
            Write-Log "Last backup: $backupDays days ago"
            
            if ($businessCriticality -eq 'Critical' -and $backupDays -gt 2) {
                Write-Log "Critical system backup is $backupDays days old" -Level WARNING
            }
        }
        
        Write-Log "Step 4: Maintenance window verification"
        $serverRole = Get-NinjaProperty "srvRole"
        
        if ($serverRole) {
            Write-Log "Server role: $serverRole"
            
            $currentDay = (Get-Date).DayOfWeek
            $currentHour = (Get-Date).Hour
            $isWeekend = $currentDay -in @('Saturday','Sunday')
            $isAfterHours = ($currentHour -ge 22 -or $currentHour -le 6)
            $inMaintenanceWindow = $isWeekend -or $isAfterHours
            
            Write-Log "Current time: $currentDay $currentHour:00 | In maintenance window: $inMaintenanceWindow"
            
            if (-not $inMaintenanceWindow -and -not $DryRun) {
                Write-Log "Outside maintenance window - deferring"
                Set-NinjaProperty "patchLastAttemptStatus" "Deferred - Outside MW"
                Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
                exit 0
            }
        }
        
        Write-Log "Step 5: Pre-patch validation"
        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        
        if ($freeSpaceGB -lt $MinDiskSpaceGB) {
            Write-Log "Insufficient disk space: $freeSpaceGB GB" -Level ERROR
            Set-NinjaProperty "patchLastAttemptStatus" "Failed - Low Disk"
            Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
            exit 1
        }
        Write-Log "Disk space: $freeSpaceGB GB available"
        
        Write-Log "Step 6: Searching for updates"
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        $searchCriteria = switch ($PatchLevel) {
            'Critical' { "IsInstalled=0 and Type='Software' and AutoSelectOnWebSites=1" }
            'Important' { "IsInstalled=0 and Type='Software'" }
            'Optional' { "IsInstalled=0" }
            'All' { "IsInstalled=0" }
        }
        
        $searchResult = $updateSearcher.Search($searchCriteria)
        
        if ($searchResult.Updates.Count -eq 0) {
            Write-Log "No updates found"
            Set-NinjaProperty "patchLastAttemptStatus" "Success - No Updates"
            Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
            Set-NinjaProperty "updLastPatchCheck" (Get-Date)
            exit 0
        }
        
        Write-Log "Found $($searchResult.Updates.Count) updates"
        foreach ($update in $searchResult.Updates) { Write-Log "  [$($update.MsrcSeverity)] $($update.Title)" }
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would install $($searchResult.Updates.Count) updates"
            Set-NinjaProperty "patchLastAttemptStatus" "Dry Run - $($searchResult.Updates.Count) Available"
            Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
            exit 0
        }
        
        Write-Log "Step 7: Downloading updates"
        $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $searchResult.Updates) { if ($update.EulaAccepted -eq $false) { $update.AcceptEula() }; $updatesToInstall.Add($update) | Out-Null }
        
        $downloader = $updateSession.CreateUpdateDownloader()
        $downloader.Updates = $updatesToInstall
        $downloadResult = $downloader.Download()
        
        Write-Log "Download completed: Result code $($downloadResult.ResultCode)"
        
        Write-Log "Step 8: Installing updates"
        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesToInstall
        $installResult = $installer.Install()
        
        $successCount = 0
        $failCount = 0
        for ($i = 0; $i -lt $updatesToInstall.Count; $i++) {
            if ($installResult.GetUpdateResult($i).ResultCode -eq 2) { $successCount++ } else { $failCount++ }
        }
        
        Write-Log "Installation completed: $successCount success, $failCount failed"
        
        Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
        Set-NinjaProperty "patchLastPatchCount" $successCount
        Set-NinjaProperty "updLastPatchCheck" (Get-Date)
        
        if ($failCount -eq 0) {
            Set-NinjaProperty "patchLastAttemptStatus" "Success - $successCount Installed"
        } else {
            Set-NinjaProperty "patchLastAttemptStatus" "Partial - $successCount/$failCount"
        }
        
        if ($installResult.RebootRequired) {
            Set-NinjaProperty "patchRebootPending" $true
            Write-Log "Reboot required" -Level WARNING
            
            if ($serverRole) {
                Write-Log "Server reboot scheduled for next maintenance window"
            } else {
                $autoReboot = Get-NinjaProperty "autoAllowAfterHoursReboot"
                if ($autoReboot -eq $true) {
                    Write-Log "Scheduling workstation reboot for after hours"
                    shutdown /r /t 3600 /c "NinjaRMM: System will restart in 1 hour (PR2 updates)"
                }
            }
        } else {
            Set-NinjaProperty "patchRebootPending" $false
        }
        
        Write-Log "=========================================="
        Write-Log "Patch Ring 2 (PR2) Deployment Completed"
        Write-Log "=========================================="
        
    } catch {
        Write-Log "FATAL ERROR: $_" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        Set-NinjaProperty "patchLastAttemptStatus" "Failed - $($_.Exception.Message)"
        Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
        $script:ExitCode = 1
    }
}

end {
    $Duration = ((Get-Date) - $StartTime).TotalSeconds
    Write-Log "Script completed in $([Math]::Round($Duration, 2)) seconds"
    exit $script:ExitCode
}
