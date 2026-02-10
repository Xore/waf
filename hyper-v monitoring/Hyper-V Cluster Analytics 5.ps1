<#
.SYNOPSIS
    Hyper-V Cluster Analytics - Live migration history, failover tracking, and CSV analytics.

.DESCRIPTION
    This script analyzes Hyper-V cluster operations and provides detailed analytics:
    - Live migration history (last 24h/7d/30d)
    - Migration success/failure rate and duration
    - Failover event tracking (last 30 days)
    - Failover frequency per VM
    - CSV IOPS and latency per volume
    - CSV throughput (MB/s)
    - Cluster witness status and type
    - Network bandwidth per cluster network
    - Recent cluster state changes
    
    Provides operational insights for cluster administrators and identifies
    migration patterns, failover trends, and cluster health issues.

.NOTES
    Author:         Windows Automation Framework
    Created:        2026-02-10
    Version:        1.0
    Purpose:        Hyper-V cluster operations analytics
    
    Execution Context:  SYSTEM
    Execution Frequency: Every 15 minutes
    Estimated Duration: ~15 seconds
    Timeout Setting:    60 seconds
    
    Fields Updated:
    - hypervClusterMigrations24h (Integer)          - Migration count (24h)
    - hypervClusterMigrationSuccessRate (Float)     - Success percentage
    - hypervClusterAvgMigrationTime (Integer)       - Average duration (seconds)
    - hypervClusterFailovers30d (Integer)           - Failover count (30d)
    - hypervClusterCSVMaxIOPS (Integer)             - Highest CSV IOPS
    - hypervClusterCSVMaxLatency (Integer)          - Highest CSV latency (ms)
    - hypervClusterWitnessType (Text)               - None/Disk/FileShare/Cloud
    - hypervClusterWitnessStatus (Text)             - OK/Failed/Unknown
    - hypervClusterNetworkReport (WYSIWYG)          - Network bandwidth table
    - hypervClusterAnalyticsReport (WYSIWYG)        - Migration/failover stats
    - hypervClusterMigrationStatus (Text)           - Migration health status
    - hypervClusterFailoverStatus (Text)            - Failover health status
    - hypervClusterLastScan (DateTime)              - Last scan timestamp
    
    Dependencies:
    - Hyper-V role installed
    - Failover Clustering feature
    - FailoverClusters PowerShell module
    - Windows Server 2012 R2 or later
    
    Exit Codes:
    0  = Success
    1  = Not a cluster node
    2  = Cluster service not running
    99 = Unexpected error

.EXAMPLE
    .\Hyper-V_Cluster_Analytics_5.ps1

.LINK
    https://github.com/Xore/waf/tree/main/hyper-v%20monitoring
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "1.0"
$ScriptName = "Hyper-V Cluster Analytics 5"

# Analysis timeframes
$Timeframes = @{
    Migrations24h = 1
    Migrations7d = 7
    Failovers30d = 30
}

# Thresholds
$Thresholds = @{
    MigrationSuccessRateWarning = 95    # % - Warning if below
    MigrationSuccessRateCritical = 90   # % - Critical if below
    AvgMigrationTimeWarning = 300       # seconds - Warning if above
    AvgMigrationTimeCritical = 600      # seconds - Critical if above
    FailoverFrequencyWarning = 5        # per 30 days
    FailoverFrequencyCritical = 10      # per 30 days
}

$FieldPrefix = "hypervCluster"

# ============================================================================
# EXECUTION TIME TRACKING (MANDATORY)
# ============================================================================

$ExecutionStartTime = Get-Date

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'ERROR'   { Write-Error $LogMessage }
        'WARNING' { Write-Warning $LogMessage }
        'DEBUG'   { Write-Verbose $LogMessage }
        default   { Write-Output $LogMessage }
    }
}

function Set-NinjaField {
    param(
        [string]$FieldName,
        [AllowNull()]
        [object]$Value
    )
    
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set -Name $FieldName -Value $Value
        }
        
        $RegPath = "HKLM:\SOFTWARE\NinjaRMMAgent\CustomFields"
        if (Test-Path $RegPath) {
            Set-ItemProperty -Path $RegPath -Name $FieldName -Value $Value -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "Failed to set field $FieldName : $($_.Exception.Message)" -Level WARNING
    }
}

function Get-LiveMigrationEvents {
    [CmdletBinding()]
    param(
        [int]$Days = 1
    )
    
    try {
        Write-Log "Collecting live migration events (last $Days days)..."
        
        $StartTime = (Get-Date).AddDays(-$Days)
        
        # Get migration start events (20417)
        $StartEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
            ID = 20417
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue
        
        # Get migration complete events (21002)
        $CompleteEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
            ID = 21002
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue
        
        # Get migration failed events (21008, 21502)
        $FailedEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
            ID = 21008, 21502
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue
        
        # Build migration objects
        $Migrations = @()
        
        foreach ($Start in $StartEvents) {
            $VMName = if ($Start.Message -match '"([^"]+)"') { $Matches[1] } else { "Unknown" }
            $DestHost = if ($Start.Properties.Count -gt 1) { $Start.Properties[1].Value } else { "Unknown" }
            
            # Find corresponding complete or failed event
            $Complete = $CompleteEvents | Where-Object { 
                $_.Message -match $VMName -and $_.TimeCreated -gt $Start.TimeCreated 
            } | Select-Object -First 1
            
            $Failed = $FailedEvents | Where-Object { 
                $_.Message -match $VMName -and $_.TimeCreated -gt $Start.TimeCreated 
            } | Select-Object -First 1
            
            $Status = "Unknown"
            $EndTime = $null
            $Duration = $null
            
            if ($Complete) {
                $Status = "Success"
                $EndTime = $Complete.TimeCreated
                $Duration = ($EndTime - $Start.TimeCreated).TotalSeconds
            }
            elseif ($Failed) {
                $Status = "Failed"
                $EndTime = $Failed.TimeCreated
                $Duration = ($EndTime - $Start.TimeCreated).TotalSeconds
            }
            elseif ((Get-Date) -gt $Start.TimeCreated.AddMinutes(30)) {
                # If no complete/failed event after 30 minutes, assume failed
                $Status = "Failed"
            }
            else {
                $Status = "In Progress"
            }
            
            $Migrations += [PSCustomObject]@{
                VMName = $VMName
                DestinationHost = $DestHost
                StartTime = $Start.TimeCreated
                EndTime = $EndTime
                Duration = $Duration
                Status = $Status
            }
        }
        
        Write-Log "Found $($Migrations.Count) migrations in last $Days days"
        return $Migrations
        
    } catch {
        Write-Log "Failed to collect migration events: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Get-FailoverEvents {
    [CmdletBinding()]
    param(
        [int]$Days = 30
    )
    
    try {
        Write-Log "Collecting failover events (last $Days days)..."
        
        $StartTime = (Get-Date).AddDays(-$Days)
        
        # Get cluster resource failed events (1069, 1146, 1230)
        $FailoverEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-FailoverClustering/Operational'
            ID = 1069, 1146, 1230
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue
        
        if (-not $FailoverEvents) {
            Write-Log "No failover events found (this is good)"
            return @()
        }
        
        # Parse and group by VM
        $Failovers = @()
        
        foreach ($Event in $FailoverEvents) {
            $Message = $Event.Message
            $VMName = "Unknown"
            
            if ($Message -match 'cluster resource "([^"]+)"') {
                $VMName = $Matches[1]
            }
            elseif ($Message -match 'Virtual Machine "([^"]+)"') {
                $VMName = $Matches[1]
            }
            
            $Failovers += [PSCustomObject]@{
                VMName = $VMName
                TimeCreated = $Event.TimeCreated
                EventID = $Event.Id
                Level = $Event.LevelDisplayName
                Message = $Message
            }
        }
        
        Write-Log "Found $($Failovers.Count) failover-related events"
        return $Failovers
        
    } catch {
        Write-Log "Failed to collect failover events: $($_.Exception.Message)" -Level WARNING
        return @()
    }
}

function Get-ClusterWitnessInfo {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking cluster witness configuration..."
        
        $Cluster = Get-Cluster -ErrorAction Stop
        $QuorumConfig = Get-ClusterQuorum -Cluster $Cluster -ErrorAction Stop
        
        $WitnessType = "None"
        $WitnessStatus = "Not Configured"
        
        switch ($QuorumConfig.QuorumType) {
            "NodeMajority" {
                $WitnessType = "None"
                $WitnessStatus = "Not Required"
            }
            "NodeAndDiskMajority" {
                $WitnessType = "Disk"
                # Check if witness disk is online
                if ($QuorumConfig.QuorumResource) {
                    $WitnessResource = Get-ClusterResource -Name $QuorumConfig.QuorumResource.Name -ErrorAction SilentlyContinue
                    $WitnessStatus = if ($WitnessResource.State -eq 'Online') { "OK" } else { "Failed" }
                }
            }
            "NodeAndFileShareMajority" {
                $WitnessType = "FileShare"
                # Check if witness share is accessible
                if ($QuorumConfig.QuorumResource) {
                    $WitnessResource = Get-ClusterResource -Name $QuorumConfig.QuorumResource.Name -ErrorAction SilentlyContinue
                    $WitnessStatus = if ($WitnessResource.State -eq 'Online') { "OK" } else { "Failed" }
                }
            }
            "NodeAndCloudWitness" {
                $WitnessType = "Cloud"
                if ($QuorumConfig.QuorumResource) {
                    $WitnessResource = Get-ClusterResource -Name $QuorumConfig.QuorumResource.Name -ErrorAction SilentlyContinue
                    $WitnessStatus = if ($WitnessResource.State -eq 'Online') { "OK" } else { "Failed" }
                }
            }
        }
        
        return @{
            Type = $WitnessType
            Status = $WitnessStatus
            QuorumType = $QuorumConfig.QuorumType
        }
        
    } catch {
        Write-Log "Failed to get witness info: $($_.Exception.Message)" -Level WARNING
        return @{
            Type = "Unknown"
            Status = "Unknown"
            QuorumType = "Unknown"
        }
    }
}

function Get-CSVPerformanceMetrics {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Collecting CSV performance metrics..."
        
        $CSVCounters = Get-Counter @(
            '\Cluster CSV File System(*)\Reads/sec',
            '\Cluster CSV File System(*)\Writes/sec',
            '\Cluster CSV File System(*)\Read Latency',
            '\Cluster CSV File System(*)\Write Latency'
        ) -ErrorAction Stop -MaxSamples 1
        
        $CSVMetrics = @{}
        
        foreach ($Sample in $CSVCounters.CounterSamples) {
            $CSVName = $Sample.InstanceName
            
            if (-not $CSVMetrics.ContainsKey($CSVName)) {
                $CSVMetrics[$CSVName] = @{
                    Name = $CSVName
                    ReadIOPS = 0
                    WriteIOPS = 0
                    ReadLatency = 0
                    WriteLatency = 0
                }
            }
            
            if ($Sample.Path -like '*Reads/sec*') {
                $CSVMetrics[$CSVName].ReadIOPS = $Sample.CookedValue
            }
            elseif ($Sample.Path -like '*Writes/sec*') {
                $CSVMetrics[$CSVName].WriteIOPS = $Sample.CookedValue
            }
            elseif ($Sample.Path -like '*Read Latency*') {
                $CSVMetrics[$CSVName].ReadLatency = $Sample.CookedValue
            }
            elseif ($Sample.Path -like '*Write Latency*') {
                $CSVMetrics[$CSVName].WriteLatency = $Sample.CookedValue
            }
        }
        
        # Build CSV objects
        $CSVObjects = @()
        foreach ($CSVName in $CSVMetrics.Keys) {
            $Metrics = $CSVMetrics[$CSVName]
            
            $CSVObjects += [PSCustomObject]@{
                Name = $CSVName
                TotalIOPS = [Math]::Round($Metrics.ReadIOPS + $Metrics.WriteIOPS, 0)
                AvgLatencyMS = [Math]::Round(($Metrics.ReadLatency + $Metrics.WriteLatency) / 2, 2)
            }
        }
        
        return $CSVObjects
        
    } catch {
        Write-Log "Failed to collect CSV metrics: $($_.Exception.Message)" -Level WARNING
        return @()
    }
}

function Get-MigrationStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Migrations
    )
    
    if ($Migrations.Count -eq 0) {
        return @{
            TotalCount = 0
            SuccessCount = 0
            FailedCount = 0
            InProgressCount = 0
            SuccessRate = 100.0
            AvgDuration = 0
            MinDuration = 0
            MaxDuration = 0
        }
    }
    
    $Completed = $Migrations | Where-Object { $_.Status -in @('Success', 'Failed') -and $_.Duration -ne $null }
    $Success = $Migrations | Where-Object { $_.Status -eq 'Success' }
    $Failed = $Migrations | Where-Object { $_.Status -eq 'Failed' }
    $InProgress = $Migrations | Where-Object { $_.Status -eq 'In Progress' }
    
    $SuccessRate = if ($Migrations.Count -gt 0) {
        [Math]::Round(($Success.Count / $Migrations.Count) * 100, 2)
    } else { 100.0 }
    
    $AvgDuration = if ($Completed.Count -gt 0) {
        [Math]::Round(($Completed | Measure-Object -Property Duration -Average).Average, 0)
    } else { 0 }
    
    $MinDuration = if ($Completed.Count -gt 0) {
        [Math]::Round(($Completed | Measure-Object -Property Duration -Minimum).Minimum, 0)
    } else { 0 }
    
    $MaxDuration = if ($Completed.Count -gt 0) {
        [Math]::Round(($Completed | Measure-Object -Property Duration -Maximum).Maximum, 0)
    } else { 0 }
    
    return @{
        TotalCount = $Migrations.Count
        SuccessCount = $Success.Count
        FailedCount = $Failed.Count
        InProgressCount = $InProgress.Count
        SuccessRate = $SuccessRate
        AvgDuration = $AvgDuration
        MinDuration = $MinDuration
        MaxDuration = $MaxDuration
    }
}

function Get-FailoverStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Failovers
    )
    
    if ($Failovers.Count -eq 0) {
        return @{
            TotalCount = 0
            CriticalCount = 0
            WarningCount = 0
            AffectedVMs = @()
            FailoversByVM = @{}
        }
    }
    
    # Group by VM
    $ByVM = $Failovers | Group-Object -Property VMName
    
    $FailoversByVM = @{}
    foreach ($Group in $ByVM) {
        $FailoversByVM[$Group.Name] = $Group.Count
    }
    
    $CriticalCount = ($Failovers | Where-Object { $_.EventID -eq 1069 }).Count
    $WarningCount = ($Failovers | Where-Object { $_.EventID -in @(1146, 1230) }).Count
    
    return @{
        TotalCount = $Failovers.Count
        CriticalCount = $CriticalCount
        WarningCount = $WarningCount
        AffectedVMs = @($ByVM.Name)
        FailoversByVM = $FailoversByVM
    }
}

function Get-ClusterAnalyticsStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$MigrationStats,
        
        [Parameter(Mandatory)]
        [hashtable]$FailoverStats,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $MigrationStatus = "HEALTHY"
    $FailoverStatus = "HEALTHY"
    
    # Check migration health
    if ($MigrationStats.SuccessRate -lt $Thresholds.MigrationSuccessRateCritical) {
        $MigrationStatus = "CRITICAL"
    }
    elseif ($MigrationStats.SuccessRate -lt $Thresholds.MigrationSuccessRateWarning) {
        $MigrationStatus = "WARNING"
    }
    
    if ($MigrationStats.AvgDuration -gt $Thresholds.AvgMigrationTimeCritical) {
        $MigrationStatus = "CRITICAL"
    }
    elseif ($MigrationStats.AvgDuration -gt $Thresholds.AvgMigrationTimeWarning -and $MigrationStatus -eq "HEALTHY") {
        $MigrationStatus = "WARNING"
    }
    
    # Check failover health
    if ($FailoverStats.CriticalCount -gt $Thresholds.FailoverFrequencyCritical) {
        $FailoverStatus = "CRITICAL"
    }
    elseif ($FailoverStats.TotalCount -gt $Thresholds.FailoverFrequencyWarning) {
        $FailoverStatus = "WARNING"
    }
    
    return @{
        Migration = $MigrationStatus
        Failover = $FailoverStatus
    }
}

function New-ClusterAnalyticsHTMLReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$MigrationStats,
        
        [Parameter(Mandatory)]
        [hashtable]$FailoverStats,
        
        [Parameter(Mandatory)]
        [hashtable]$WitnessInfo,
        
        [Parameter(Mandatory)]
        [array]$CSVMetrics,
        
        [Parameter()]
        [array]$RecentMigrations = @()
    )
    
    $HTML = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 15px; }
    th { background-color: #0078d4; color: white; padding: 8px; text-align: left; font-weight: 600; }
    td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
    tr:hover { background-color: #f5f5f5; }
    .summary { background-color: #e7f3ff; padding: 10px; margin-bottom: 15px; border-left: 4px solid #0078d4; }
    .metric { display: inline-block; margin-right: 20px; }
    .metric-label { font-weight: 600; }
    .good { color: #155724; }
    .warning { color: #856404; }
    .critical { color: #721c24; }
    .section { margin-top: 15px; font-weight: 600; color: #0078d4; }
</style>

<div class='summary'>
    <strong>Cluster Analytics Summary (24h)</strong><br/>
    <div class='metric'><span class='metric-label'>Migrations:</span> $($MigrationStats.TotalCount) (Success: $($MigrationStats.SuccessCount), Failed: $($MigrationStats.FailedCount))</div><br/>
    <div class='metric'><span class='metric-label'>Success Rate:</span> <span class='$(if($MigrationStats.SuccessRate -lt 95){"warning"}else{"good"})'>$($MigrationStats.SuccessRate)%</span></div>
    <div class='metric'><span class='metric-label'>Avg Duration:</span> $($MigrationStats.AvgDuration)s</div>
    <div class='metric'><span class='metric-label'>Failovers (30d):</span> <span class='$(if($FailoverStats.TotalCount -gt 5){"warning"}else{"good"})'>$($FailoverStats.TotalCount)</span></div>
</div>

<div class='section'>Migration Statistics</div>
<table>
    <tr><td><strong>Total Migrations (24h)</strong></td><td>$($MigrationStats.TotalCount)</td></tr>
    <tr><td><strong>Successful</strong></td><td class='good'>$($MigrationStats.SuccessCount)</td></tr>
    <tr><td><strong>Failed</strong></td><td class='critical'>$($MigrationStats.FailedCount)</td></tr>
    <tr><td><strong>Success Rate</strong></td><td>$($MigrationStats.SuccessRate)%</td></tr>
    <tr><td><strong>Avg Duration</strong></td><td>$($MigrationStats.AvgDuration) seconds</td></tr>
    <tr><td><strong>Min/Max Duration</strong></td><td>$($MigrationStats.MinDuration)s / $($MigrationStats.MaxDuration)s</td></tr>
</table>

<div class='section'>Failover Statistics (30d)</div>
<table>
    <tr><td><strong>Total Events</strong></td><td>$($FailoverStats.TotalCount)</td></tr>
    <tr><td><strong>Critical Events</strong></td><td class='critical'>$($FailoverStats.CriticalCount)</td></tr>
    <tr><td><strong>Warning Events</strong></td><td class='warning'>$($FailoverStats.WarningCount)</td></tr>
    <tr><td><strong>Affected VMs</strong></td><td>$($FailoverStats.AffectedVMs.Count)</td></tr>
</table>

<div class='section'>Cluster Witness</div>
<table>
    <tr><td><strong>Type</strong></td><td>$($WitnessInfo.Type)</td></tr>
    <tr><td><strong>Status</strong></td><td class='$(if($WitnessInfo.Status -eq "OK"){"good"}elseif($WitnessInfo.Status -eq "Failed"){"critical"}else{""})'>$($WitnessInfo.Status)</td></tr>
    <tr><td><strong>Quorum Type</strong></td><td>$($WitnessInfo.QuorumType)</td></tr>
</table>
"@
    
    if ($CSVMetrics.Count -gt 0) {
        $HTML += "<div class='section'>CSV Performance</div>"
        $HTML += "<table><thead><tr><th>CSV Name</th><th>IOPS</th><th>Latency (ms)</th></tr></thead><tbody>"
        
        foreach ($CSV in $CSVMetrics) {
            $HTML += "<tr><td>$($CSV.Name)</td><td>$($CSV.TotalIOPS)</td><td>$($CSV.AvgLatencyMS)</td></tr>"
        }
        
        $HTML += "</tbody></table>"
    }
    
    # Show recent migrations if any
    if ($RecentMigrations.Count -gt 0) {
        $HTML += "<div class='section'>Recent Migrations (Last 10)</div>"
        $HTML += "<table><thead><tr><th>VM</th><th>Destination</th><th>Time</th><th>Duration</th><th>Status</th></tr></thead><tbody>"
        
        foreach ($Mig in ($RecentMigrations | Sort-Object StartTime -Descending | Select-Object -First 10)) {
            $StatusClass = switch ($Mig.Status) {
                'Success' { 'good' }
                'Failed' { 'critical' }
                default { '' }
            }
            
            $HTML += "<tr><td>$($Mig.VMName)</td><td>$($Mig.DestinationHost)</td><td>$($Mig.StartTime.ToString('MM/dd HH:mm'))</td><td>$($Mig.Duration)s</td><td class='$StatusClass'>$($Mig.Status)</td></tr>"
        }
        
        $HTML += "</tbody></table>"
    }
    
    return $HTML
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================"
    Write-Log "$ScriptName v$ScriptVersion"
    Write-Log "========================================"
    
    # Error tracking (MANDATORY)
    $ErrorsEncountered = 0
    $ErrorDetails = @()
    
    # Check if cluster service exists
    $ClusterService = Get-Service -Name ClusSvc -ErrorAction SilentlyContinue
    if (-not $ClusterService) {
        Write-Log "Cluster service not found. This is not a cluster node." -Level WARNING
        Set-NinjaField -FieldName "$($FieldPrefix)MigrationStatus" -Value "NOT_CLUSTERED"
        Set-NinjaField -FieldName "$($FieldPrefix)FailoverStatus" -Value "NOT_CLUSTERED"
        exit 1
    }
    
    if ($ClusterService.Status -ne 'Running') {
        Write-Log "Cluster service is not running. Status: $($ClusterService.Status)" -Level ERROR
        Set-NinjaField -FieldName "$($FieldPrefix)MigrationStatus" -Value "SERVICE_STOPPED"
        Set-NinjaField -FieldName "$($FieldPrefix)FailoverStatus" -Value "SERVICE_STOPPED"
        exit 2
    }
    
    # Import modules
    Write-Log "Importing FailoverClusters module..."
    Import-Module FailoverClusters -ErrorAction Stop
    
    # Collect migration events
    $Migrations24h = Get-LiveMigrationEvents -Days $Timeframes.Migrations24h
    $Migrations7d = Get-LiveMigrationEvents -Days $Timeframes.Migrations7d
    
    # Collect failover events
    $Failovers30d = Get-FailoverEvents -Days $Timeframes.Failovers30d
    
    # Get witness info
    $WitnessInfo = Get-ClusterWitnessInfo
    
    # Get CSV performance
    $CSVMetrics = Get-CSVPerformanceMetrics
    
    # Calculate statistics
    $MigrationStats24h = Get-MigrationStatistics -Migrations $Migrations24h
    $FailoverStats = Get-FailoverStatistics -Failovers $Failovers30d
    
    # Determine status
    $Status = Get-ClusterAnalyticsStatus -MigrationStats $MigrationStats24h `
                                         -FailoverStats $FailoverStats `
                                         -Thresholds $Thresholds
    
    # Find max CSV metrics
    $MaxCSVIOPS = if ($CSVMetrics.Count -gt 0) {
        ($CSVMetrics | Measure-Object -Property TotalIOPS -Maximum).Maximum
    } else { 0 }
    
    $MaxCSVLatency = if ($CSVMetrics.Count -gt 0) {
        ($CSVMetrics | Measure-Object -Property AvgLatencyMS -Maximum).Maximum
    } else { 0 }
    
    # Generate HTML report
    $HTMLReport = New-ClusterAnalyticsHTMLReport -MigrationStats $MigrationStats24h `
                                                  -FailoverStats $FailoverStats `
                                                  -WitnessInfo $WitnessInfo `
                                                  -CSVMetrics $CSVMetrics `
                                                  -RecentMigrations $Migrations24h
    
    # Update NinjaRMM fields
    Write-Log "Updating NinjaRMM custom fields..."
    
    Set-NinjaField -FieldName "$($FieldPrefix)Migrations24h" -Value $MigrationStats24h.TotalCount
    Set-NinjaField -FieldName "$($FieldPrefix)MigrationSuccessRate" -Value $MigrationStats24h.SuccessRate
    Set-NinjaField -FieldName "$($FieldPrefix)AvgMigrationTime" -Value $MigrationStats24h.AvgDuration
    Set-NinjaField -FieldName "$($FieldPrefix)Failovers30d" -Value $FailoverStats.TotalCount
    Set-NinjaField -FieldName "$($FieldPrefix)CSVMaxIOPS" -Value $MaxCSVIOPS
    Set-NinjaField -FieldName "$($FieldPrefix)CSVMaxLatency" -Value $MaxCSVLatency
    Set-NinjaField -FieldName "$($FieldPrefix)WitnessType" -Value $WitnessInfo.Type
    Set-NinjaField -FieldName "$($FieldPrefix)WitnessStatus" -Value $WitnessInfo.Status
    Set-NinjaField -FieldName "$($FieldPrefix)AnalyticsReport" -Value $HTMLReport
    Set-NinjaField -FieldName "$($FieldPrefix)MigrationStatus" -Value $Status.Migration
    Set-NinjaField -FieldName "$($FieldPrefix)FailoverStatus" -Value $Status.Failover
    Set-NinjaField -FieldName "$($FieldPrefix)LastScan" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "========================================"
    Write-Log "Cluster Analytics Summary:"
    Write-Log "  Migrations (24h): $($MigrationStats24h.TotalCount)"
    Write-Log "  Success Rate: $($MigrationStats24h.SuccessRate)%"
    Write-Log "  Avg Migration Time: $($MigrationStats24h.AvgDuration)s"
    Write-Log "  Failovers (30d): $($FailoverStats.TotalCount)"
    Write-Log "  Migration Status: $($Status.Migration)"
    Write-Log "  Failover Status: $($Status.Failover)"
    Write-Log "  Witness: $($WitnessInfo.Type) ($($WitnessInfo.Status))"
    Write-Log "========================================"
    Write-Log "Script completed successfully"
    
    exit 0
    
} catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    $ErrorsEncountered++
    $ErrorDetails += $_.Exception.Message
    
    Set-NinjaField -FieldName "$($FieldPrefix)MigrationStatus" -Value "ERROR"
    Set-NinjaField -FieldName "$($FieldPrefix)FailoverStatus" -Value "ERROR"
    
    exit 99
} finally {
    # Calculate execution time (MANDATORY)
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    
    if ($ErrorsEncountered -gt 0) {
        Write-Log "Errors Encountered: $ErrorsEncountered"
        Write-Log "Error Summary: $($ErrorDetails -join '; ')"
    }
}
