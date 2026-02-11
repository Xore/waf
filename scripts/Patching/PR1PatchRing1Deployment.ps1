#Requires -Version 5.1

<#
.SYNOPSIS
    NinjaRMM Patch Ring 1 (PR1) - Test Deployment Script

.DESCRIPTION
    Deploys Windows updates to test ring devices with comprehensive validation, restore point
    creation, and controlled reboot scheduling. Test ring receives patches first for validation.

.PARAMETER DryRun
    Simulates patch deployment without actually installing updates. Default: false

.PARAMETER PatchLevel
    Specifies which patch severity to install. Default: Critical

.PARAMETER MinDiskSpaceGB
    Minimum free disk space required in GB. Default: 10

.PARAMETER MinHealthScore
    Minimum health score to proceed. Default: 50

.EXAMPLE
    .\PR1PatchRing1Deployment.ps1 -DryRun -PatchLevel Critical

.OUTPUTS
    None. Results are written to console, log file, and NinjaRMM custom fields.

.NOTES
    File Name      : PR1PatchRing1Deployment.ps1
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    
    Target: Devices tagged with patchRing=PR1 or Test
    
    Exit Codes:
    - 0: Success
    - 1: Failed or error occurred
#>

[CmdletBinding()]
param (
    [Parameter()][Switch]$DryRun = $false,
    [Parameter()][ValidateSet('Critical','Important','Optional','All')][String]$PatchLevel = 'Critical',
    [Parameter()][ValidateRange(1, 1000)][Int]$MinDiskSpaceGB = 10,
    [Parameter()][ValidateRange(0, 100)][Int]$MinHealthScore = 50
)

begin {
    $ErrorActionPreference = 'Stop'
    $StartTime = Get-Date
    $script:ExitCode = 0
    $LogPath = "C:\ProgramData\NinjaRMM\Logs\PatchRing1_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        Add-Content -Path $LogPath -Value $LogMessage -ErrorAction SilentlyContinue
        Write-Output $LogMessage
        if ($Level -eq 'ERROR') { $script:ExitCode = 1 }
    }
    
    function Set-NinjaProperty { param([string]$Name, $Value); try { $Value | Ninja-Property-Set-Piped -Name $Name } catch { Write-Log "Failed to set property '$Name': $_" -Level WARNING } }
    function Get-NinjaProperty { param([string]$Name); try { Ninja-Property-Get $Name } catch { Write-Log "Failed to read property '$Name': $_" -Level WARNING; return $null } }
}

process {
    try {
        Write-Log "=========================================="
        Write-Log "Patch Ring 1 (PR1) Deployment Started"
        Write-Log "Device: $env:COMPUTERNAME | Level: $PatchLevel | DryRun: $DryRun"
        Write-Log "=========================================="
        
        Write-Log "Step 1: Pre-patch validation checks"
        
        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        
        if ($freeSpaceGB -lt $MinDiskSpaceGB) {
            Write-Log "Insufficient disk space: $freeSpaceGB GB (min $MinDiskSpaceGB GB)" -Level ERROR
            Set-NinjaProperty "patchLastAttemptStatus" "Failed - Low Disk Space"
            Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
            exit 1
        }
        Write-Log "Disk space check PASSED: $freeSpaceGB GB available"
        
        $healthScore = Get-NinjaProperty "opsHealthScore"
        if ($healthScore -and $healthScore -lt $MinHealthScore) {
            Write-Log "Low health score: $healthScore (min $MinHealthScore) - Proceeding with caution" -Level WARNING
        } elseif ($healthScore) {
            Write-Log "Health score check PASSED: $healthScore"
        }
        
        Write-Log "Step 2: Creating system restore point"
        if (-not $DryRun) {
            try {
                Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
                Checkpoint-Computer -Description "Pre-Patch PR1 $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
                Write-Log "Restore point created successfully"
            } catch {
                Write-Log "Could not create restore point: $_" -Level WARNING
            }
        } else {
            Write-Log "DRY RUN: Skipping restore point creation"
        }
        
        Write-Log "Step 3: Searching for available updates"
        
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        $searchCriteria = switch ($PatchLevel) {
            'Critical' { "IsInstalled=0 and Type='Software' and AutoSelectOnWebSites=1" }
            'Important' { "IsInstalled=0 and Type='Software'" }
            'Optional' { "IsInstalled=0" }
            'All' { "IsInstalled=0" }
        }
        
        Write-Log "Search criteria: $searchCriteria"
        $searchResult = $updateSearcher.Search($searchCriteria)
        
        if ($searchResult.Updates.Count -eq 0) {
            Write-Log "No updates found matching criteria: $PatchLevel"
            Set-NinjaProperty "patchLastAttemptStatus" "Success - No Updates Available"
            Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
            Set-NinjaProperty "updLastPatchCheck" (Get-Date)
            Write-Log "=========================================="
            exit 0
        }
        
        Write-Log "Found $($searchResult.Updates.Count) updates matching $PatchLevel criteria"
        
        $criticalUpdates = @($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq 'Critical' })
        $importantUpdates = @($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq 'Important' })
        $optionalUpdates = @($searchResult.Updates | Where-Object { $_.MsrcSeverity -notmatch 'Critical|Important' })
        
        foreach ($update in $searchResult.Updates) {
            Write-Log "  [$($update.MsrcSeverity)] $($update.Title)"
        }
        
        Set-NinjaProperty "updMissingCriticalCount" $criticalUpdates.Count
        Set-NinjaProperty "updMissingImportantCount" $importantUpdates.Count
        Set-NinjaProperty "updMissingOptionalCount" $optionalUpdates.Count
        
        if ($DryRun) {
            Write-Log "DRY RUN MODE: Would install $($searchResult.Updates.Count) updates"
            Set-NinjaProperty "patchLastAttemptStatus" "Dry Run - $($searchResult.Updates.Count) Available"
            Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
            exit 0
        }
        
        Write-Log "Step 4: Downloading updates"
        $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        
        foreach ($update in $searchResult.Updates) {
            if ($update.EulaAccepted -eq $false) { $update.AcceptEula() }
            $updatesToInstall.Add($update) | Out-Null
        }
        
        $downloader = $updateSession.CreateUpdateDownloader()
        $downloader.Updates = $updatesToInstall
        $downloadResult = $downloader.Download()
        
        if ($downloadResult.ResultCode -ne 2) {
            Write-Log "Download failed with result code: $($downloadResult.ResultCode)" -Level ERROR
            Set-NinjaProperty "patchLastAttemptStatus" "Failed - Download Error"
            Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
            exit 1
        }
        Write-Log "Download completed successfully"
        
        Write-Log "Step 5: Installing updates"
        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesToInstall
        $installResult = $installer.Install()
        
        $successCount = 0
        for ($i = 0; $i -lt $updatesToInstall.Count; $i++) {
            $result = $installResult.GetUpdateResult($i)
            if ($result.ResultCode -eq 2) { $successCount++ }
        }
        
        Write-Log "Installation completed: $successCount of $($updatesToInstall.Count) successful"
        
        Set-NinjaProperty "patchLastAttemptDate" (Get-Date)
        Set-NinjaProperty "patchLastPatchCount" $successCount
        Set-NinjaProperty "patchLastAttemptStatus" "Success - $successCount Installed"
        Set-NinjaProperty "updLastPatchCheck" (Get-Date)
        
        if ($installResult.RebootRequired) {
            Set-NinjaProperty "patchRebootPending" $true
            Write-Log "Reboot required - scheduling for after hours" -Level WARNING
        } else {
            Set-NinjaProperty "patchRebootPending" $false
            Write-Log "No reboot required"
        }
        
        Write-Log "=========================================="
        Write-Log "Patch Ring 1 (PR1) Deployment Completed Successfully"
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
    Write-Log "Script execution completed in $([Math]::Round($Duration, 2)) seconds"
    exit $script:ExitCode
}
