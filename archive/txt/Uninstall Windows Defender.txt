<#
.SYNOPSIS
    Wrapper script to uninstall Windows Defender feature.

.DESCRIPTION
    This script safely uninstalls the Windows-Defender feature on both
    Windows Server and Windows Client systems. Reports status including
    pending reboot requirements. Never reboots automatically.

.EXAMPLE
    .\Uninstall-WindowsDefender.ps1

.NOTES
    Exit Codes:
    0 = Success
    1 = Failure
#>

[CmdletBinding()]
param()

# Ensure script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Starting Windows Defender uninstallation..." -ForegroundColor Cyan
    
    # Detect if running on Server or Client OS
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $isServer = $osInfo.ProductType -ne 1  # 1 = Workstation, 2 = Domain Controller, 3 = Server
    
    if ($isServer) {
        Write-Host "Detected Windows Server - using WindowsFeature cmdlets" -ForegroundColor Gray
        
        # Check if Windows-Defender feature exists
        $feature = Get-WindowsFeature -Name Windows-Defender -ErrorAction Stop
        
        if (-not $feature) {
            Write-Host "WARNING: Windows-Defender feature not found on this system" -ForegroundColor Yellow
            exit 1
        }
        
        if (-not $feature.Installed) {
            Write-Host "Windows-Defender is already uninstalled" -ForegroundColor Green
            exit 0
        }
        
        # Attempt to uninstall Windows Defender
        Write-Host "Uninstalling Windows-Defender feature..." -ForegroundColor Yellow
        $result = Uninstall-WindowsFeature -Name Windows-Defender -ErrorAction Stop
        
        # Check if uninstallation was successful
        if ($result.Success) {
            Write-Host "" # Empty line
            Write-Host "Windows Defender uninstalled successfully!" -ForegroundColor Green
            Write-Host "Exit Code: $($result.ExitCode)" -ForegroundColor Gray
            
            # Check for pending reboot
            if ($result.RestartNeeded -eq 'Yes') {
                Write-Host "" # Empty line
                Write-Host "*** REBOOT REQUIRED ***" -ForegroundColor Yellow
                Write-Host "A system reboot is required to complete the uninstallation." -ForegroundColor Yellow
                Write-Host "Please restart your computer at your earliest convenience." -ForegroundColor Yellow
            } else {
                Write-Host "" # Empty line
                Write-Host "No reboot required." -ForegroundColor Green
            }
            
            exit 0
        } else {
            Write-Host "ERROR: Uninstallation failed" -ForegroundColor Red
            Write-Host "Exit Code: $($result.ExitCode)" -ForegroundColor Red
            exit 1
        }
        
    } else {
        Write-Host "Detected Windows Client - using WindowsOptionalFeature cmdlets" -ForegroundColor Gray
        
        # Check if Windows-Defender feature exists
        $feature = Get-WindowsOptionalFeature -Online -FeatureName Windows-Defender -ErrorAction Stop
        
        if (-not $feature) {
            Write-Host "WARNING: Windows-Defender feature not found on this system" -ForegroundColor Yellow
            exit 1
        }
        
        if ($feature.State -eq 'Disabled') {
            Write-Host "Windows-Defender is already disabled" -ForegroundColor Green
            exit 0
        }
        
        # Attempt to disable Windows Defender
        Write-Host "Disabling Windows-Defender feature..." -ForegroundColor Yellow
        $result = Disable-WindowsOptionalFeature -Online -FeatureName Windows-Defender -NoRestart -ErrorAction Stop
        
        # Check if operation was successful
        Write-Host "" # Empty line
        Write-Host "Windows Defender disabled successfully!" -ForegroundColor Green
        
        if ($result.RestartNeeded) {
            Write-Host "" # Empty line
            Write-Host "*** REBOOT REQUIRED ***" -ForegroundColor Yellow
            Write-Host "A system reboot is required to complete the uninstallation." -ForegroundColor Yellow
            Write-Host "Please restart your computer at your earliest convenience." -ForegroundColor Yellow
            exit 0
        } else {
            Write-Host "No reboot required." -ForegroundColor Green
            exit 0
        }
    }
    
} catch {
    Write-Host "ERROR: An error occurred during uninstallation: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
    exit 1
}
