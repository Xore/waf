<#
.SYNOPSIS
    Veeam Backup Monitor - Veeam Backup & Replication Health and Job Status Monitoring

.DESCRIPTION
    Monitors Veeam Backup & Replication infrastructure including backup job execution status,
    repository capacity, job success/warning/failure rates, and backup server health. Provides
    comprehensive backup compliance tracking and capacity planning for enterprise backup
    infrastructure.
    
    Critical for ensuring backup SLAs are met, detecting job failures before they impact RPO/RTO
    objectives, and proactively managing repository capacity to prevent backup failures due to
    storage exhaustion. Essential for disaster recovery readiness.
    
    Monitoring Scope:
    
    Veeam Installation Detection:
    - Checks for VeeamBackupSvc service
    - Loads Veeam.Backup.PowerShell module or VeeamPSSnapin (legacy)
    - Connects to local Veeam backup server
    - Retrieves version from registry or server session
    - Gracefully exits if Veeam not installed
    
    Backup Job Inventory:
    - Retrieves all configured backup jobs via Get-VBRJob (server/VM backups)
    - Retrieves computer backup jobs via Get-VBRComputerBackupJob (endpoint backups)
    - Tracks total job count for capacity planning
    - Monitors job execution over last 24 hours
    - Categorizes job results: Success, Warning, Failed
    
    Job Session Analysis (24-Hour Window):
    - Queries Get-VBRBackupSession for recent executions
    - Queries Get-VBRComputerBackupJobSession for endpoint backup sessions
    - Counts successful jobs (green status)
    - Counts warning jobs (orange status - partial success)
    - Counts failed jobs (red status - critical)
    - Tracks most recent backup completion time
    - Builds HTML job summary table with color-coded results
    
    Repository Capacity Monitoring:
    - Queries all backup repositories via Get-VBRBackupRepository
    - Calculates total repository space (GB)
    - Calculates aggregate free space percentage
    - Warns when free space drops below 20%
    - Critical metric for preventing backup failures
    
    Job Summary Reporting:
    - Generates HTML formatted job status table
    - Includes job name, result, end time for each job
    - Color-coded results: green (success), orange (warning), red (failed)
    - Stores in WYSIWYG field for dashboard visualization
    - 24-hour summary statistics at bottom
    
    Health Status Classification:
    
    Healthy:
    - Veeam service running
    - No failed jobs in 24h
    - No warnings in 24h
    - Repository free space >20%
    
    Warning:
    - Service running but jobs with warnings
    - Repository free space <20%
    - Partial backup failures
    
    Critical:
    - Veeam service stopped
    - Any failed backup jobs in 24h
    - Service degraded
    
    Unknown:
    - Veeam not installed
    - PowerShell module unavailable
    - Script execution error

.NOTES
    Frequency: Every 4 hours
    Runtime: ~40 seconds
    Timeout: 120 seconds
    Context: SYSTEM
    
    Fields Updated:
    - VEEAMInstalled (Checkbox)
    - VEEAMVersion (Text: Veeam B&R version)
    - VEEAMJobCount (Integer: total configured jobs)
    - VEEAMJobsSuccessful24h (Integer: successful in 24h)
    - VEEAMJobsWarning24h (Integer: warnings in 24h)
    - VEEAMJobsFailed24h (Integer: failed in 24h)
    - VEEAMRepositorySpaceGB (Integer: total repository capacity)
    - VEEAMRepositoryFreePercent (Integer: aggregate free space %)
    - VEEAMLastBackupTime (DateTime: most recent backup completion - ISO format)
    - VEEAMJobSummary (WYSIWYG: HTML formatted job status table)
    - VEEAMBackupServerName (Text: Veeam server hostname)
    - VEEAMHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - Veeam Backup & Replication installed
    - Veeam.Backup.PowerShell module or VeeamPSSnapin
    - VeeamBackupSvc service running
    - Local administrator permissions
    - PowerShell remoting to Veeam server (if remote)
    
    Supported Veeam Versions:
    - Veeam Backup & Replication 9.5+
    - Veeam Backup & Replication 10.x
    - Veeam Backup & Replication 11.x
    - Veeam Backup & Replication 12.x
    
    PowerShell Module Loading:
    - Primary: Veeam.Backup.PowerShell (v10+)
    - Fallback: VeeamPSSnapin (legacy v9.5)
    
    Common Issues:
    - Module not found: Install Veeam console on monitoring server
    - Connection failed: Verify VeeamBackupSvc service running
    - Access denied: Run as administrator or Veeam user
    - Timeout: Increase timeout for large Veeam deployments
    
    Framework Version: 4.3
    Last Updated: February 9, 2026
    Changelog: 
    - v4.3: Fixed DateTime format for veeamLastBackupTime (ISO format yyyy-MM-ddTHH:mm:ss)
    - v4.2: Fixed connection handling, improved version detection, suppressed warnings
    - v4.1: Added Get-VBRComputerBackupJob support for endpoint backups
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting Veeam Backup Monitor (v4.3)..."
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
    $i = 0
    
    # Check if Veeam is installed
    Write-Output "INFO: Checking for Veeam Backup & Replication..."
    $veeamService = Get-Service -Name "VeeamBackupSvc" -ErrorAction SilentlyContinue
    
    if ($null -eq $veeamService) {
        Write-Output "INFO: Veeam Backup & Replication not installed"
        
        # Update fields for non-Veeam systems
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamInstalled $false
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamVersion "Not Installed"
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobCount 0
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobsSuccessful24h 0
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobsWarning24h 0
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobsFailed24h 0
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamRepositorySpaceGB 0
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamRepositoryFreePercent 100
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamLastBackupTime ""
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobSummary "Veeam not installed"
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamBackupServerName $env:COMPUTERNAME
        & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamHealthStatus "Unknown"
        
        Write-Output "SUCCESS: Veeam monitoring skipped (not installed)"
        exit 0
    }
    
    $veeamInstalled = $true
    Write-Output "INFO: Veeam detected - Service: $($veeamService.Status)"
    
    # Load Veeam PowerShell module
    Write-Output "INFO: Loading Veeam PowerShell module..."
    try {
        if (Get-Module -ListAvailable -Name Veeam.Backup.PowerShell) {
            Import-Module Veeam.Backup.PowerShell -WarningAction SilentlyContinue -ErrorAction Stop
            Write-Output "INFO: Veeam.Backup.PowerShell module loaded"
        } else {
            Add-PSSnapin VeeamPSSnapin -ErrorAction Stop
            Write-Output "INFO: VeeamPSSnapin (legacy) loaded"
        }
    } catch {
        Write-Output "ERROR: Failed to load Veeam PowerShell module: $_"
        throw "Veeam PowerShell module unavailable"
    }
    
    # Connect to Veeam server (disconnect first if already connected)
    Write-Output "INFO: Connecting to Veeam backup server..."
    try {
        # Disconnect any existing session
        Disconnect-VBRServer -ErrorAction SilentlyContinue | Out-Null
        
        # Connect to local server
        Connect-VBRServer -Server localhost -ErrorAction Stop | Out-Null
        Write-Output "INFO: Connected to Veeam server"
    } catch {
        Write-Output "INFO: Using existing Veeam server connection"
    }
    
    # Get Veeam version
    Write-Output "INFO: Detecting Veeam version..."
    try {
        $veeamInfo = Get-VBRServerSession -ErrorAction SilentlyContinue
        if ($veeamInfo -and $veeamInfo.ProductVersion) {
            $veeamVersion = "Veeam B&R v$($veeamInfo.ProductVersion)"
            $backupServerName = if ($veeamInfo.Server) { $veeamInfo.Server } else { $env:COMPUTERNAME }
            Write-Output "INFO: Version: $veeamVersion"
            Write-Output "INFO: Server: $backupServerName"
        } else {
            # Fallback to registry
            $veeamRegPath = "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication"
            if (Test-Path $veeamRegPath) {
                $version = (Get-ItemProperty -Path $veeamRegPath -Name "CoreVersion" -ErrorAction SilentlyContinue).CoreVersion
                if ($version) {
                    $veeamVersion = "Veeam B&R v$version"
                    Write-Output "INFO: Version from registry: $veeamVersion"
                } else {
                    $veeamVersion = "Veeam B&R (version unknown)"
                    Write-Output "INFO: Version could not be determined"
                }
            } else {
                $veeamVersion = "Veeam B&R (version unknown)"
                Write-Output "INFO: Version could not be determined"
            }
        }
    } catch {
        Write-Output "WARNING: Failed to get Veeam version: $_"
        $veeamVersion = "Veeam B&R (version unknown)"
    }
    
    # Get backup jobs (server/VM backups)
    Write-Output "INFO: Retrieving server/VM backup jobs..."
    $allJobs = @()
    try {
        $serverJobs = Get-VBRJob -WarningAction SilentlyContinue
        if ($serverJobs) {
            $allJobs += $serverJobs
            Write-Output "INFO: Found $($serverJobs.Count) server/VM backup jobs"
        }
    } catch {
        Write-Output "WARNING: Failed to retrieve server/VM backup jobs: $_"
    }
    
    # Get computer backup jobs (endpoint backups)
    Write-Output "INFO: Retrieving computer/endpoint backup jobs..."
    try {
        $computerJobs = Get-VBRComputerBackupJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($computerJobs) {
            $allJobs += $computerJobs
            Write-Output "INFO: Found $($computerJobs.Count) computer/endpoint backup jobs"
        } else {
            Write-Output "INFO: No computer backup jobs configured"
        }
    } catch {
        Write-Output "INFO: Computer backup jobs not available (cmdlet not found or no jobs configured)"
    }
    
    $jobCount = $allJobs.Count
    Write-Output "INFO: Total jobs: $jobCount"
    
    # Get job sessions from last 24 hours
    $startTime = (Get-Date).AddHours(-24)
    $htmlRows = @()
    $lastBackupDateTime = $null
    
    Write-Output "INFO: Analyzing job sessions (24h window)..."
    
    # Process server/VM backup jobs
    $serverJobsToProcess = $allJobs | Where-Object { $_.GetType().Name -ne 'VBRComputerBackupJob' }
    if ($serverJobsToProcess) {
        Write-Output "INFO: Processing $($serverJobsToProcess.Count) server/VM job sessions..."
        $i = 0
        foreach ($job in $serverJobsToProcess) {
            try {
                $latestSession = Get-VBRBackupSession | Where-Object { $job.Id -eq $_.JobId } | Sort-Object -Property EndTime -Descending | Select-Object -First 1
                
                $i++
                                
                Write-Output "INFO: Processing $($i)/$($serverJobsToProcess.Count) $($job.Name)"
                
                if ($latestSession -and $latestSession.EndTime -ge $startTime) {
                    # Count by result
                    switch ($latestSession.Result) {
                        'Success' { $jobsSuccessful24h++ }
                        'Warning' { $jobsWarning24h++ }
                        'Failed' { $jobsFailed24h++ }
                    }
                    
                    # Track most recent backup (as DateTime object for comparison)
                    if ($latestSession.EndTime) {
                        $backupTime = $latestSession.EndTime
                        if ($null -eq $lastBackupDateTime -or $backupTime -gt $lastBackupDateTime) {
                            $lastBackupDateTime = $backupTime
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
            } catch {
                Write-Output "WARNING: Failed to process job '$($job.Name)': $_"
            }
        }
    }
    
    # Process computer/endpoint backup jobs
    $computerBackupJobs = $allJobs | Where-Object { $_.GetType().Name -eq 'VBRComputerBackupJob' }
    if ($computerBackupJobs) {
        Write-Output "INFO: Processing $($computerBackupJobs.Count) computer backup job sessions..."
        $i = 0
        foreach ($job in $computerBackupJobs) {
            try {
                $latestSession = Get-VBRComputerBackupJobSession -Job $job -ErrorAction SilentlyContinue | Sort-Object -Property EndTime -Descending | Select-Object -First 1
                              
                $i++
                                
                Write-Output "INFO: Processing $($i)/$($computerBackupJobs.Count) $($job.Name)"

                if ($latestSession -and $latestSession.EndTime -ge $startTime) {
                    # Count by result
                    switch ($latestSession.Result) {
                        'Success' { $jobsSuccessful24h++ }
                        'Warning' { $jobsWarning24h++ }
                        'Failed' { $jobsFailed24h++ }
                    }
                    
                    # Track most recent backup (as DateTime object for comparison)
                    if ($latestSession.EndTime) {
                        $backupTime = $latestSession.EndTime
                        if ($null -eq $lastBackupDateTime -or $backupTime -gt $lastBackupDateTime) {
                            $lastBackupDateTime = $backupTime
                        }
                    }
                    
                    # Build HTML row
                    $resultColor = switch ($latestSession.Result) {
                        'Success' { 'green' }
                        'Warning' { 'orange' }
                        'Failed' { 'red' }
                        default { 'black' }
                    }
                    
                    $jobName = "$($job.Name) (Endpoint)"
                    $jobResult = $latestSession.Result
                    $jobEndTime = if ($latestSession.EndTime) { $latestSession.EndTime.ToString("yyyy-MM-dd HH:mm") } else { "N/A" }
                    
                    $htmlRows += "<tr><td>$jobName</td><td style='color:$resultColor'>$jobResult</td><td>$jobEndTime</td></tr>"
                }
            } catch {
                Write-Output "WARNING: Failed to process computer backup job '$($job.Name)': $_"
            }
        }
    }
    
    # Convert DateTime to ISO format (yyyy-MM-ddTHH:mm:ss) for NinjaRMM
    if ($null -ne $lastBackupDateTime) {
        $lastBackupTime = $lastBackupDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
        Write-Output "INFO: Last backup time: $lastBackupTime (ISO format)"
    } else {
        $lastBackupTime = ""
        Write-Output "INFO: No backup time recorded"
    }
    
    Write-Output "INFO: Job results (24h): Success=$jobsSuccessful24h, Warning=$jobsWarning24h, Failed=$jobsFailed24h"
    
    # Build job summary HTML
    if ($htmlRows.Count -gt 0) {
        $jobSummary = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr><th>Job Name</th><th>Result</th><th>End Time</th></tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary (24h):</strong> Success: $jobsSuccessful24h | Warning: $jobsWarning24h | Failed: $jobsFailed24h
</p>
"@
    } else {
        $jobSummary = "No backup jobs executed in the last 24 hours"
    }
    
    # Get repository information
    Write-Output "INFO: Checking backup repositories..."
    try {
        $repositories = Get-VBRBackupRepository -ErrorAction SilentlyContinue
        
        if ($repositories) {
            $totalSpaceGB = 0
            $totalFreeGB = 0
            
            foreach ($repo in $repositories) {
                try {
                    $capacityGB = [Math]::Round($repo.GetContainer().CachedTotalSpace.InGigabytes)
                    $freeGB = [Math]::Round($repo.GetContainer().CachedFreeSpace.InGigabytes)
                    
                    $totalSpaceGB += $capacityGB
                    $totalFreeGB += $freeGB
                } catch {
                    Write-Output "WARNING: Failed to get capacity for repository '$($repo.Name)': $_"
                }
            }
            
            $repositorySpaceGB = $totalSpaceGB
            if ($totalSpaceGB -gt 0) {
                $repositoryFreePercent = [Math]::Round(($totalFreeGB / $totalSpaceGB) * 100)
            }
            
            Write-Output "INFO: Repository capacity: $repositorySpaceGB GB total, $repositoryFreePercent% free"
        } else {
            Write-Output "INFO: No backup repositories found"
        }
    } catch {
        Write-Output "WARNING: Failed to get repository information: $_"
    }
    
    # Determine health status
    Write-Output "INFO: Determining health status..."
    if ($veeamService.Status -ne 'Running') {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Veeam service stopped"
    } elseif ($jobsFailed24h -gt 0) {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Backup job failures detected ($jobsFailed24h failed)"
    } elseif ($jobsWarning24h -gt 0 -or $repositoryFreePercent -lt 20) {
        $healthStatus = "Warning"
        if ($jobsWarning24h -gt 0) {
            Write-Output "  ASSESSMENT: Backup jobs with warnings ($jobsWarning24h warnings)"
        }
        if ($repositoryFreePercent -lt 20) {
            Write-Output "  ASSESSMENT: Low repository space ($repositoryFreePercent% free)"
        }
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: All backup jobs successful"
    }
    
    # Disconnect from Veeam server
    try {
        Disconnect-VBRServer -ErrorAction SilentlyContinue | Out-Null
    } catch {
        # Silent fail
    }
    
    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamInstalled $true
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamVersion $veeamVersion
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobCount $jobCount
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobsSuccessful24h $jobsSuccessful24h
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobsWarning24h $jobsWarning24h
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobsFailed24h $jobsFailed24h
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamRepositorySpaceGB $repositorySpaceGB
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamRepositoryFreePercent $repositoryFreePercent
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamLastBackupTime $lastBackupTime
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobSummary $jobSummary
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamBackupServerName $backupServerName
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamHealthStatus $healthStatus
    
    Write-Output "SUCCESS: Veeam Backup monitoring complete"
    Write-Output "VEEAM BACKUP METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - Version: $veeamVersion"
    Write-Output "  - Server: $backupServerName"
    Write-Output "  - Total Jobs: $jobCount"
    Write-Output "  - Successful (24h): $jobsSuccessful24h"
    Write-Output "  - Warnings (24h): $jobsWarning24h"
    Write-Output "  - Failed (24h): $jobsFailed24h"
    Write-Output "  - Repository Space: $repositorySpaceGB GB ($repositoryFreePercent% free)"
    if ($lastBackupTime) {
        Write-Output "  - Last Backup: $lastBackupTime"
    }
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: Veeam Backup Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    # Set error state in fields
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamInstalled $false
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamHealthStatus "Unknown"
    & "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set veeamJobSummary "Monitor script error: $errorMessage"
    
    exit 1
}
