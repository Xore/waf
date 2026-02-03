<#
.SYNOPSIS
    Script 45: File Server Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors File Server role including shares, open files, connected users, quota violations,
    and access errors. Updates 8 FS fields with HTML summary.

.FIELDS UPDATED
    - FSFileServerRole (Checkbox)
    - FSShareCount (Integer)
    - FSShareSummary (WYSIWYG)
    - FSOpenFilesCount (Integer)
    - FSConnectedUsers (Integer)
    - FSQuotaViolations (Integer)
    - FSAccessErrors24h (Integer)
    - FSHealthStatus (Text)

.EXECUTION
    Frequency: Daily (config), Every 4 hours (usage)
    Runtime: ~35 seconds
    Requires: File Server role installed

.NOTES
    File: Script_45_File_Server_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Server Role Monitoring
    Dependencies: File Server role, SMB PowerShell module

.RELATED DOCUMENTATION
    - docs/core/16_ROLE_Additional.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 4)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting File Server Monitor (Script 45)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $fileServerRole = $false
    $shareCount = 0
    $shareSummary = ""
    $openFilesCount = 0
    $connectedUsers = 0
    $quotaViolations = 0
    $accessErrors24h = 0
    $healthStatus = "Unknown"
    
    # Check if File Server role is installed
    Write-Host "Checking File Server role..."
    $fsRole = Get-WindowsFeature -Name "FS-FileServer" -ErrorAction SilentlyContinue
    
    if ($null -eq $fsRole -or -not $fsRole.Installed) {
        Write-Host "File Server role is not installed."
        
        # Update fields for non-file servers
        Ninja-Property-Set fsFileServerRole $false
        Ninja-Property-Set fsShareCount 0
        Ninja-Property-Set fsShareSummary "File Server role not installed"
        Ninja-Property-Set fsOpenFilesCount 0
        Ninja-Property-Set fsConnectedUsers 0
        Ninja-Property-Set fsQuotaViolations 0
        Ninja-Property-Set fsAccessErrors24h 0
        Ninja-Property-Set fsHealthStatus "Unknown"
        
        Write-Host "File Server Monitor complete (role not installed)."
        exit 0
    }
    
    $fileServerRole = $true
    Write-Host "File Server role is installed."
    
    # Get SMB shares (excluding administrative shares)
    Write-Host "Enumerating SMB shares..."
    try {
        $shares = Get-SmbShare | Where-Object { $_.Special -eq $false }
        $shareCount = $shares.Count
        Write-Host "Share Count: $shareCount"
        
        # Build share summary HTML
        if ($shareCount -gt 0) {
            $htmlRows = @()
            foreach ($share in $shares) {
                $sharePath = $share.Path
                $shareType = $share.ShareType
                
                # Get share size if path exists
                $shareSize = "N/A"
                if ($sharePath -and (Test-Path $sharePath)) {
                    try {
                        $folderSize = (Get-ChildItem -Path $sharePath -Recurse -File -ErrorAction SilentlyContinue | 
                            Measure-Object -Property Length -Sum).Sum
                        $shareSizeGB = [Math]::Round($folderSize / 1GB, 2)
                        $shareSize = "$shareSizeGB GB"
                    } catch {
                        $shareSize = "Unknown"
                    }
                }
                
                $htmlRows += "<tr><td>$($share.Name)</td><td>$sharePath</td><td>$shareSize</td></tr>"
            }
            
            $shareSummary = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Share Name</th><th>Path</th><th>Size</th></tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; color:#666; margin-top:10px;'>Total Shares: $shareCount</p>
"@
        } else {
            $shareSummary = "No file shares configured"
        }
    } catch {
        Write-Warning "Failed to enumerate shares: $_"
        $shareSummary = "Unable to retrieve share information"
    }
    
    # Get open files count
    Write-Host "Counting open files..."
    try {
        $openFiles = Get-SmbOpenFile -ErrorAction SilentlyContinue
        $openFilesCount = if ($openFiles) { $openFiles.Count } else { 0 }
        Write-Host "Open Files: $openFilesCount"
    } catch {
        Write-Warning "Failed to get open files count: $_"
    }
    
    # Get connected users count
    Write-Host "Counting connected users..."
    try {
        $sessions = Get-SmbSession -ErrorAction SilentlyContinue
        $connectedUsers = if ($sessions) { ($sessions | Select-Object -Unique -Property ClientUserName).Count } else { 0 }
        Write-Host "Connected Users: $connectedUsers"
    } catch {
        Write-Warning "Failed to get connected users count: $_"
    }
    
    # Check for FSRM (File Server Resource Manager) quota violations
    Write-Host "Checking quota violations..."
    try {
        $fsrmFeature = Get-WindowsFeature -Name "FS-Resource-Manager" -ErrorAction SilentlyContinue
        
        if ($fsrmFeature -and $fsrmFeature.Installed) {
            # FSRM is installed, check quotas
            $quotas = Get-FsrmQuota -ErrorAction SilentlyContinue
            
            if ($quotas) {
                $quotaViolations = ($quotas | Where-Object { $_.Usage -gt $_.Limit }).Count
                Write-Host "Quota Violations: $quotaViolations"
            }
        } else {
            Write-Host "FSRM not installed, quota monitoring not available."
        }
    } catch {
        Write-Warning "Failed to check quota violations: $_"
    }
    
    # Check for access errors in event log (last 24 hours)
    Write-Host "Checking file access errors (24h)..."
    try {
        $startTime = (Get-Date).AddHours(-24)
        $fsErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-SMBServer'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $accessErrors24h = if ($fsErrors) { $fsErrors.Count } else { 0 }
        Write-Host "Access Errors (24h): $accessErrors24h"
    } catch {
        Write-Warning "Failed to check access errors: $_"
    }
    
    # Determine health status
    if ($accessErrors24h -gt 50) {
        $healthStatus = "Critical"
    } elseif ($quotaViolations -gt 0 -or $accessErrors24h -gt 10) {
        $healthStatus = "Warning"
    } else {
        $healthStatus = "Healthy"
    }
    
    Write-Host "Health Status: $healthStatus"
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set fsFileServerRole $true
    Ninja-Property-Set fsShareCount $shareCount
    Ninja-Property-Set fsShareSummary $shareSummary
    Ninja-Property-Set fsOpenFilesCount $openFilesCount
    Ninja-Property-Set fsConnectedUsers $connectedUsers
    Ninja-Property-Set fsQuotaViolations $quotaViolations
    Ninja-Property-Set fsAccessErrors24h $accessErrors24h
    Ninja-Property-Set fsHealthStatus $healthStatus
    
    Write-Host "File Server Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "File Server Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set fsFileServerRole $false
    Ninja-Property-Set fsHealthStatus "Unknown"
    Ninja-Property-Set fsShareSummary "Monitor script error: $errorMessage"
    
    exit 1
}
