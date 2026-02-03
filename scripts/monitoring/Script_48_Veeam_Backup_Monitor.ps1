<#
.SYNOPSIS
    Script 48: Veeam Backup Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Veeam Backup & Replication server including job status, repository space,
    warnings, failures, and backup health. Updates 12 VEEAM fields.

.FIELDS UPDATED
    - VEEAMInstalled (Checkbox)
    - VEEAMVersion (Text)
    - VEEAMJobCount (Integer)
    - VEEAMJobsSuccessful24h (Integer)
    - VEEAMJobsWarning24h (Integer)
    - VEEAMJobsFailed24h (Integer)
    - VEEAMRepositorySpaceGB (Integer)
    - VEEAMRepositoryFreePercent (Integer)
    - VEEAMLastBackupTime (DateTime)
    - VEEAMJobSummary (WYSIWYG)
    - VEEAMBackupServerName (Text)
    - VEEAMHealthStatus (Text)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~40 seconds
    Requires: Veeam Backup & Replication installed

.NOTES
    File: Script_48_Veeam_Backup_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Infrastructure Monitoring
    Dependencies: Veeam.Backup.PowerShell module

.RELATED DOCUMENTATION
    - docs/core/14_ROLE_Infrastructure.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 5)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Veeam Backup Monitor (Script 48)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $veeamInstalled = $false
    $veeamVersion = "Not Installed"
    $jobCount = 0
    $jobsSuccessful24h = 0
    $jobsWarning24h = 0
    $jobsFailed24h = 0
    $repositorySpaceGB = 0
    $repositoryFreePercent = 100
    $lastBackupTime = ""
    $jobSummary = ""
    $backupServerName = $env:COMPUTERNAME
    $healthStatus = "Unknown"
    
    # Check if Veeam is installed
    Write-Host "Checking Veeam installation..."
    $veeamService = Get-Service -Name "VeeamBackupSvc" -ErrorAction SilentlyContinue
    
    if ($null -eq $veeamService) {
        Write-Host "Veeam Backup & Replication is not installed."
        
        # Update fields for non-Veeam systems
        Ninja-Property-Set veeamInstalled $false
        Ninja-Property-Set veeamVersion "Not Installed"
        Ninja-Property-Set veeamJobCount 0
        Ninja-Property-Set veeamJobsSuccessful24h 0
        Ninja-Property-Set veeamJobsWarning24h 0
        Ninja-Property-Set veeamJobsFailed24h 0
        Ninja-Property-Set veeamRepositorySpaceGB 0
        Ninja-Property-Set veeamRepositoryFreePercent 100
        Ninja-Property-Set veeamLastBackupTime ""
        Ninja-Property-Set veeamJobSummary "Veeam not installed"
        Ninja-Property-Set veeamBackupServerName $env:COMPUTERNAME
        Ninja-Property-Set veeamHealthStatus "Unknown"
        
        Write-Host "Veeam Backup Monitor complete (not installed)."
        exit 0
    }
    
    $veeamInstalled = $true
    Write-Host "Veeam Backup & Replication is installed. Service Status: $($veeamService.Status)"
    
    # Load Veeam PowerShell snap-in/module
    Write-Host "Loading Veeam PowerShell module..."
    try {
        # Try new module first
        if (Get-Module -ListAvailable -Name Veeam.Backup.PowerShell) {
            Import-Module Veeam.Backup.PowerShell -ErrorAction Stop
            Write-Host "Veeam.Backup.PowerShell module loaded."
        } else {
            # Try legacy snap-in
            Add-PSSnapin VeeamPSSnapin -ErrorAction Stop
            Write-Host "VeeamPSSnapin loaded."
        }
    } catch {
        Write-Warning "Failed to load Veeam PowerShell module: $_"
        throw "Veeam PowerShell module not available"
    }
    
    # Connect to Veeam server
    try {
        Write-Host "Connecting to Veeam backup server..."
        Connect-VBRServer -Server localhost -ErrorAction Stop
        Write-Host "Connected to Veeam server."
    } catch {
        Write-Warning "Failed to connect to Veeam server: $_"
    }
    
    # Get Veeam version
    try {
        $veeamInfo = Get-VBRServerSession
        if ($veeamInfo) {
            $veeamVersion = "Veeam B&R v$($veeamInfo.ProductVersion)"
            $backupServerName = $veeamInfo.Server
        } else {
            # Alternative method
            $veeamRegPath = "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication"
            if (Test-Path $veeamRegPath) {
                $version = (Get-ItemProperty -Path $veeamRegPath -Name "CoreVersion" -ErrorAction SilentlyContinue).CoreVersion
                if ($version) {
                    $veeamVersion = "Veeam B&R v$version"
                }
            }
        }
        Write-Host "Veeam Version: $veeamVersion"
    } catch {
        Write-Warning "Failed to get Veeam version: $_"
        $veeamVersion = "Veeam B&R (version unknown)"
    }
    
    # Get backup jobs
    Write-Host "Retrieving backup jobs..."
    try {
        $jobs = Get-VBRJob
        $jobCount = $jobs.Count
        Write-Host "Total Jobs: $jobCount"
        
        # Get job sessions from last 24 hours
        $startTime = (Get-Date).AddHours(-24)
        $htmlRows = @()
        
        foreach ($job in $jobs) {
            $latestSession = Get-VBRBackupSession | Where-Object { $job.Id -eq $_.JobId } | Sort-Object -Property EndTime -Descending | Select-Object -First 1
            
            if ($latestSession -and $latestSession.EndTime -ge $startTime) {
                # Count by result
                switch ($latestSession.Result) {
                    'Success' { $jobsSuccessful24h++ }
                    'Warning' { $jobsWarning24h++ }
                    'Failed' { $jobsFailed24h++ }
                }
                
                # Track most recent backup
                if ($latestSession.EndTime) {
                    $backupTime = $latestSession.EndTime
                    if ($lastBackupTime -eq "" -or $backupTime -gt [DateTime]$lastBackupTime) {
                        $lastBackupTime = $backupTime.ToString("yyyy-MM-dd HH:mm:ss")
                    }
                }
                
                # Build HTML row
                $resultColor = switch ($latestSession.Result) {
                    'Success' { 'green' }
                    'Warning' { 'orange' }
                    'Failed' { 'red' }
                    default { 'black' }
                }
                
                $jobName = $job.Name
                $jobResult = $latestSession.Result
                $jobEndTime = if ($latestSession.EndTime) { $latestSession.EndTime.ToString("yyyy-MM-dd HH:mm") } else { "N/A" }
                
                $htmlRows += "<tr><td>$jobName</td><td style='color:$resultColor'>$jobResult</td><td>$jobEndTime</td></tr>"
            }
        }
        
        Write-Host "Jobs (24h): Success=$jobsSuccessful24h, Warning=$jobsWarning24h, Failed=$jobsFailed24h"
        
        # Build job summary HTML
        if ($htmlRows.Count -gt 0) {
            $jobSummary = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Job Name</th><th>Result</th><th>End Time</th></tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary (24h):</strong> Success: $jobsSuccessful24h | Warning: $jobsWarning24h | Failed: $jobsFailed24h
</p>
"@
        } else {
            $jobSummary = "No backup jobs executed in the last 24 hours"
        }
        
    } catch {
        Write-Warning "Failed to retrieve backup jobs: $_"
        $jobSummary = "Unable to retrieve job information"
    }
    
    # Get repository information
    Write-Host "Checking backup repositories..."
    try {
        $repositories = Get-VBRBackupRepository
        
        if ($repositories) {
            $totalSpaceGB = 0
            $totalFreeGB = 0
            
            foreach ($repo in $repositories) {
                $capacityGB = [Math]::Round($repo.GetContainer().CachedTotalSpace.InGigabytes)
                $freeGB = [Math]::Round($repo.GetContainer().CachedFreeSpace.InGigabytes)
                
                $totalSpaceGB += $capacityGB
                $totalFreeGB += $freeGB
            }
            
            $repositorySpaceGB = $totalSpaceGB
            if ($totalSpaceGB -gt 0) {
                $repositoryFreePercent = [Math]::Round(($totalFreeGB / $totalSpaceGB) * 100)
            }
            
            Write-Host "Repository Space: $repositorySpaceGB GB, Free: $repositoryFreePercent%"
        }
    } catch {
        Write-Warning "Failed to get repository information: $_"
    }
    
    # Determine health status
    if ($veeamService.Status -ne 'Running') {
        $healthStatus = "Critical"
    } elseif ($jobsFailed24h -gt 0) {
        $healthStatus = "Critical"
    } elseif ($jobsWarning24h -gt 0 -or $repositoryFreePercent -lt 20) {
        $healthStatus = "Warning"
    } else {
        $healthStatus = "Healthy"
    }
    
    Write-Host "Health Status: $healthStatus"
    
    # Disconnect from Veeam server
    try {
        Disconnect-VBRServer -ErrorAction SilentlyContinue
    } catch {
        # Silent fail
    }
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set veeamInstalled $true
    Ninja-Property-Set veeamVersion $veeamVersion
    Ninja-Property-Set veeamJobCount $jobCount
    Ninja-Property-Set veeamJobsSuccessful24h $jobsSuccessful24h
    Ninja-Property-Set veeamJobsWarning24h $jobsWarning24h
    Ninja-Property-Set veeamJobsFailed24h $jobsFailed24h
    Ninja-Property-Set veeamRepositorySpaceGB $repositorySpaceGB
    Ninja-Property-Set veeamRepositoryFreePercent $repositoryFreePercent
    Ninja-Property-Set veeamLastBackupTime $lastBackupTime
    Ninja-Property-Set veeamJobSummary $jobSummary
    Ninja-Property-Set veeamBackupServerName $backupServerName
    Ninja-Property-Set veeamHealthStatus $healthStatus
    
    Write-Host "Veeam Backup Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Veeam Backup Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set veeamInstalled $false
    Ninja-Property-Set veeamHealthStatus "Unknown"
    Ninja-Property-Set veeamJobSummary "Monitor script error: $errorMessage"
    
    exit 1
}
