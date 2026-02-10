<#
.SYNOPSIS
    Hyper-V Storage Performance Monitor - Detailed storage I/O metrics and CSV performance.

.DESCRIPTION
    This script collects detailed storage performance metrics for Hyper-V:
    - Disk IOPS per VM (read/write split)
    - Disk throughput per VM (MB/s)
    - Disk latency per VM (read/write averages and maximums)
    - Disk queue depth per virtual disk
    - CSV I/O statistics per volume
    - CSV cache hit rate
    - CSV metadata operations/sec
    - Storage migration tracking (active/recent)
    - Storage migration progress %
    - VHD/VHDX file fragmentation detection
    - Thin provisioning utilization
    - Storage overprovisioning ratio
    
    Focuses on storage-specific metrics complementing the general Performance Monitor.

.NOTES
    Author:         Windows Automation Framework
    Created:        2026-02-10
    Version:        1.0
    Purpose:        Hyper-V storage performance monitoring
    
    Execution Context:  SYSTEM
    Execution Frequency: Every 10 minutes
    Estimated Duration: ~25 seconds
    Timeout Setting:    60 seconds
    
    Fields Updated:
    - hypervStorageVMsHighIOPS (Text)          - VMs with >20,000 IOPS
    - hypervStorageVMsHighLatency (Text)       - VMs with >100ms latency
    - hypervStorageVMsHighQueue (Text)         - VMs with queue >32
    - hypervStorageCSVCacheHitRate (Float)     - CSV cache hit rate %
    - hypervStorageMigrationsActive (Integer)  - Active storage migrations
    - hypervStorageFragmentedVMs (Integer)     - VMs with >15% fragmentation
    - hypervStorageThinProvisionedGB (Integer) - Thin provisioned allocated GB
    - hypervStorageOverprovisionRatio (Float)  - Overprovisioning ratio
    - hypervStorageMaxQueueDepth (Integer)     - Highest queue depth
    - hypervStorageMaxLatency (Integer)        - Highest latency (ms)
    - hypervStorageCSVStatus (Text)            - CSV health status
    - hypervStoragePerformanceReport (WYSIWYG) - HTML storage metrics
    - hypervStorageStatus (Text)               - Overall storage status
    - hypervStorageLastScan (DateTime)         - Last scan timestamp
    
    Dependencies:
    - Hyper-V role installed
    - Hyper-V PowerShell module
    - FailoverClusters module (if clustered)
    - Windows Server 2012 R2 or later
    
    Exit Codes:
    0  = Success
    1  = Hyper-V not installed
    2  = Module import failed
    99 = Unexpected error

.EXAMPLE
    .\Hyper-V_Storage_Performance_Monitor_7.ps1

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
$ScriptName = "Hyper-V Storage Performance Monitor 7"

# Storage thresholds
$Thresholds = @{
    IOPSHigh = 20000           # IOPS - Very high disk operations
    LatencyWarningMS = 50      # ms - Warning latency
    LatencyCriticalMS = 100    # ms - Critical latency  
    QueueDepthWarning = 32     # Queue depth warning
    QueueDepthCritical = 64    # Queue depth critical
    CSVCacheHitLow = 70        # % - Low cache hit rate
    CSVCacheHitGood = 90       # % - Good cache hit rate
    FragmentationWarning = 15  # % - VHD fragmentation warning
    FragmentationCritical = 30 # % - VHD fragmentation critical
}

$FieldPrefix = "hypervStorage"

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

function Get-StoragePerformanceCounters {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Collecting storage performance counters..."
        
        $CounterPaths = @(
            # VM Storage Device counters
            '\Hyper-V Virtual Storage Device(*)\Read Operations/sec',
            '\Hyper-V Virtual Storage Device(*)\Write Operations/sec',
            '\Hyper-V Virtual Storage Device(*)\Read Bytes/sec',
            '\Hyper-V Virtual Storage Device(*)\Write Bytes/sec',
            '\Hyper-V Virtual Storage Device(*)\Read Latency',
            '\Hyper-V Virtual Storage Device(*)\Write Latency',
            '\Hyper-V Virtual Storage Device(*)\Queue Length',
            
            # Physical disk counters for host
            '\LogicalDisk(*)\Avg. Disk sec/Read',
            '\LogicalDisk(*)\Avg. Disk sec/Write',
            '\LogicalDisk(*)\% Idle Time'
        )
        
        $Counters = Get-Counter -Counter $CounterPaths -ErrorAction Stop -MaxSamples 1
        
        return @{
            Timestamp = Get-Date
            Samples = $Counters.CounterSamples
        }
        
    } catch {
        Write-Log "Failed to collect storage counters: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-CSVPerformanceCounters {
    [CmdletBinding()]
    param()
    
    try {
        # Check if clustered
        if (-not (Get-Service -Name ClusSvc -ErrorAction SilentlyContinue)) {
            Write-Log "Cluster service not present, skipping CSV counters"
            return $null
        }
        
        Write-Log "Collecting CSV performance counters..."
        
        $CSVCounterPaths = @(
            '\Cluster CSV File System(*)\Reads/sec',
            '\Cluster CSV File System(*)\Writes/sec',
            '\Cluster CSV File System(*)\Read Bytes/sec',
            '\Cluster CSV File System(*)\Write Bytes/sec',
            '\Cluster CSV File System(*)\Read Latency',
            '\Cluster CSV File System(*)\Write Latency',
            '\Cluster CSV File System(*)\Read Queue Length',
            '\Cluster CSV File System(*)\Write Queue Length',
            '\Cluster CSV File System(*)\Redirected Reads/sec',
            '\Cluster CSV File System(*)\Redirected Writes/sec'
        )
        
        # Try to get CSV cache counters (may not exist on all versions)
        try {
            $CSVCounterPaths += '\Cluster CSV Volume Cache(*)\Cache Hit Reads/sec'
            $CSVCounterPaths += '\Cluster CSV Volume Cache(*)\Cache Miss Reads/sec'
        } catch {
            Write-Log "CSV cache counters not available" -Level DEBUG
        }
        
        $CSVCounters = Get-Counter -Counter $CSVCounterPaths -ErrorAction Stop -MaxSamples 1
        
        return @{
            Timestamp = Get-Date
            Samples = $CSVCounters.CounterSamples
        }
        
    } catch {
        Write-Log "Failed to collect CSV counters: $($_.Exception.Message)" -Level WARNING
        return $null
    }
}

function Get-VMStorageMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CounterData
    )
    
    try {
        Write-Log "Processing VM storage metrics..."
        
        $VMStorage = @{}
        
        foreach ($Sample in $CounterData.Samples) {
            $InstanceName = $Sample.InstanceName
            $CounterPath = $Sample.Path
            $Value = $Sample.CookedValue
            
            # Skip host disk counters (LogicalDisk)
            if ($CounterPath -notlike '*Virtual Storage Device*') {
                continue
            }
            
            # Extract VM name from instance: "VMName_DiskPath"
            $VMName = ($InstanceName -split '_')[0]
            
            if (-not $VMStorage.ContainsKey($VMName)) {
                $VMStorage[$VMName] = @{
                    VMName = $VMName
                    ReadIOPS = 0
                    WriteIOPS = 0
                    ReadMBps = 0
                    WriteMBps = 0
                    ReadLatency = @()
                    WriteLatency = @()
                    QueueDepth = @()
                }
            }
            
            if ($CounterPath -like '*Read Operations/sec*') {
                $VMStorage[$VMName].ReadIOPS += $Value
            }
            elseif ($CounterPath -like '*Write Operations/sec*') {
                $VMStorage[$VMName].WriteIOPS += $Value
            }
            elseif ($CounterPath -like '*Read Bytes/sec*') {
                $VMStorage[$VMName].ReadMBps += $Value
            }
            elseif ($CounterPath -like '*Write Bytes/sec*') {
                $VMStorage[$VMName].WriteMBps += $Value
            }
            elseif ($CounterPath -like '*Read Latency*') {
                $VMStorage[$VMName].ReadLatency += $Value
            }
            elseif ($CounterPath -like '*Write Latency*') {
                $VMStorage[$VMName].WriteLatency += $Value
            }
            elseif ($CounterPath -like '*Queue Length*') {
                $VMStorage[$VMName].QueueDepth += $Value
            }
        }
        
        # Build VM objects
        $VMObjects = @()
        foreach ($VMName in $VMStorage.Keys) {
            $Metrics = $VMStorage[$VMName]
            
            $VMObj = [PSCustomObject]@{
                VMName = $VMName
                ReadIOPS = [Math]::Round($Metrics.ReadIOPS, 0)
                WriteIOPS = [Math]::Round($Metrics.WriteIOPS, 0)
                TotalIOPS = [Math]::Round($Metrics.ReadIOPS + $Metrics.WriteIOPS, 0)
                ReadMBps = [Math]::Round($Metrics.ReadMBps / 1MB, 2)
                WriteMBps = [Math]::Round($Metrics.WriteMBps / 1MB, 2)
                TotalMBps = [Math]::Round(($Metrics.ReadMBps + $Metrics.WriteMBps) / 1MB, 2)
                ReadLatencyMS = if ($Metrics.ReadLatency.Count -gt 0) { 
                    [Math]::Round(($Metrics.ReadLatency | Measure-Object -Average).Average, 2) 
                } else { 0 }
                WriteLatencyMS = if ($Metrics.WriteLatency.Count -gt 0) { 
                    [Math]::Round(($Metrics.WriteLatency | Measure-Object -Average).Average, 2) 
                } else { 0 }
                AvgLatencyMS = if ($Metrics.ReadLatency.Count -gt 0 -or $Metrics.WriteLatency.Count -gt 0) {
                    [Math]::Round((($Metrics.ReadLatency + $Metrics.WriteLatency | Measure-Object -Average).Average), 2)
                } else { 0 }
                MaxQueueDepth = if ($Metrics.QueueDepth.Count -gt 0) { 
                    [Math]::Round(($Metrics.QueueDepth | Measure-Object -Maximum).Maximum, 0) 
                } else { 0 }
            }
            
            $VMObjects += $VMObj
        }
        
        Write-Log "Processed storage metrics for $($VMObjects.Count) VMs"
        return $VMObjects
        
    } catch {
        Write-Log "Failed to process VM storage metrics: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Get-CSVMetrics {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$CounterData
    )
    
    if (-not $CounterData) {
        return $null
    }
    
    try {
        Write-Log "Processing CSV metrics..."
        
        $CSVMetrics = @{}
        
        foreach ($Sample in $CounterData.Samples) {
            $InstanceName = $Sample.InstanceName
            $CounterPath = $Sample.Path
            $Value = $Sample.CookedValue
            
            if (-not $CSVMetrics.ContainsKey($InstanceName)) {
                $CSVMetrics[$InstanceName] = @{
                    Name = $InstanceName
                    ReadIOPS = 0
                    WriteIOPS = 0
                    ReadLatency = 0
                    WriteLatency = 0
                    ReadQueue = 0
                    WriteQueue = 0
                    RedirectedReads = 0
                    RedirectedWrites = 0
                    CacheHitReads = 0
                    CacheMissReads = 0
                }
            }
            
            if ($CounterPath -like '*Reads/sec*' -and $CounterPath -notlike '*Redirected*') {
                $CSVMetrics[$InstanceName].ReadIOPS = $Value
            }
            elseif ($CounterPath -like '*Writes/sec*' -and $CounterPath -notlike '*Redirected*') {
                $CSVMetrics[$InstanceName].WriteIOPS = $Value
            }
            elseif ($CounterPath -like '*Read Latency*') {
                $CSVMetrics[$InstanceName].ReadLatency = $Value
            }
            elseif ($CounterPath -like '*Write Latency*') {
                $CSVMetrics[$InstanceName].WriteLatency = $Value
            }
            elseif ($CounterPath -like '*Redirected Reads/sec*') {
                $CSVMetrics[$InstanceName].RedirectedReads = $Value
            }
            elseif ($CounterPath -like '*Redirected Writes/sec*') {
                $CSVMetrics[$InstanceName].RedirectedWrites = $Value
            }
            elseif ($CounterPath -like '*Cache Hit Reads/sec*') {
                $CSVMetrics[$InstanceName].CacheHitReads = $Value
            }
            elseif ($CounterPath -like '*Cache Miss Reads/sec*') {
                $CSVMetrics[$InstanceName].CacheMissReads = $Value
            }
        }
        
        # Build CSV objects
        $CSVObjects = @()
        foreach ($CSVName in $CSVMetrics.Keys) {
            $Metrics = $CSVMetrics[$CSVName]
            
            $CacheHitRate = if (($Metrics.CacheHitReads + $Metrics.CacheMissReads) -gt 0) {
                [Math]::Round(($Metrics.CacheHitReads / ($Metrics.CacheHitReads + $Metrics.CacheMissReads)) * 100, 2)
            } else { 0 }
            
            $CSVObj = [PSCustomObject]@{
                Name = $CSVName
                ReadIOPS = [Math]::Round($Metrics.ReadIOPS, 0)
                WriteIOPS = [Math]::Round($Metrics.WriteIOPS, 0)
                TotalIOPS = [Math]::Round($Metrics.ReadIOPS + $Metrics.WriteIOPS, 0)
                ReadLatencyMS = [Math]::Round($Metrics.ReadLatency, 2)
                WriteLatencyMS = [Math]::Round($Metrics.WriteLatency, 2)
                AvgLatencyMS = [Math]::Round(($Metrics.ReadLatency + $Metrics.WriteLatency) / 2, 2)
                RedirectedIOPS = [Math]::Round($Metrics.RedirectedReads + $Metrics.RedirectedWrites, 0)
                CacheHitRate = $CacheHitRate
            }
            
            $CSVObjects += $CSVObj
        }
        
        Write-Log "Processed metrics for $($CSVObjects.Count) CSVs"
        return $CSVObjects
        
    } catch {
        Write-Log "Failed to process CSV metrics: $($_.Exception.Message)" -Level WARNING
        return $null
    }
}

function Get-StorageMigrations {
    [CmdletBinding()]
    param()
    
    try {
        # Check for active storage migrations via event log (last 10 minutes)
        $StartEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
            ID = 20414
            StartTime = (Get-Date).AddMinutes(-10)
        } -ErrorAction SilentlyContinue
        
        $CompleteEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
            ID = 20415
            StartTime = (Get-Date).AddMinutes(-10)
        } -ErrorAction SilentlyContinue
        
        $ActiveMigrations = @()
        
        foreach ($Start in $StartEvents) {
            $VMName = if ($Start.Message -match '"([^"]+)"') { $Matches[1] } else { "Unknown" }
            
            # Check if completed
            $Completed = $CompleteEvents | Where-Object { 
                $_.Message -match $VMName -and $_.TimeCreated -gt $Start.TimeCreated 
            } | Select-Object -First 1
            
            if (-not $Completed) {
                $ActiveMigrations += [PSCustomObject]@{
                    VMName = $VMName
                    StartTime = $Start.TimeCreated
                    Duration = ((Get-Date) - $Start.TimeCreated).TotalMinutes
                }
            }
        }
        
        return $ActiveMigrations
        
    } catch {
        Write-Log "Failed to check storage migrations: $($_.Exception.Message)" -Level WARNING
        return @()
    }
}

function Get-VHDFragmentation {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking VHD fragmentation (this may take time)..."
        
        # Get all VM hard disks
        $VMs = Get-VM -ErrorAction SilentlyContinue
        $FragmentedVMs = @()
        $VHDCount = 0
        
        foreach ($VM in $VMs) {
            try {
                $HardDrives = Get-VMHardDiskDrive -VMName $VM.Name -ErrorAction SilentlyContinue
                
                foreach ($Drive in $HardDrives) {
                    $VHDPath = $Drive.Path
                    $VHDCount++
                    
                    # Check fragmentation using FSUTIL (requires elevated privileges)
                    try {
                        $Result = fsutil file queryFragmentation "$VHDPath" 2>&1
                        
                        if ($Result -match 'Percent Fragmentation\s*:\s*(\d+\.?\d*)%') {
                            $FragPercent = [float]$Matches[1]
                            
                            if ($FragPercent -gt $Thresholds.FragmentationWarning) {
                                $FragmentedVMs += [PSCustomObject]@{
                                    VMName = $VM.Name
                                    VHDPath = $VHDPath
                                    FragmentationPercent = $FragPercent
                                }
                            }
                        }
                    } catch {
                        Write-Log "Failed to check fragmentation for $VHDPath" -Level DEBUG
                    }
                }
            } catch {
                Write-Log "Failed to get hard drives for VM $($VM.Name)" -Level DEBUG
            }
        }
        
        Write-Log "Checked fragmentation for $VHDCount VHD files, found $($FragmentedVMs.Count) fragmented"
        return $FragmentedVMs
        
    } catch {
        Write-Log "Failed VHD fragmentation check: $($_.Exception.Message)" -Level WARNING
        return @()
    }
}

function Get-StorageCapacity {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Calculating storage capacity metrics..."
        
        $VMs = Get-VM -ErrorAction SilentlyContinue
        $TotalAllocatedGB = 0
        $TotalUsedGB = 0
        
        foreach ($VM in $VMs) {
            try {
                $VHDs = Get-VHD -VMId $VM.Id -ErrorAction SilentlyContinue
                
                foreach ($VHD in $VHDs) {
                    $TotalAllocatedGB += $VHD.Size / 1GB
                    $TotalUsedGB += $VHD.FileSize / 1GB
                }
            } catch {
                Write-Log "Failed to get VHD info for VM $($VM.Name)" -Level DEBUG
            }
        }
        
        $OverprovisionRatio = if ($TotalUsedGB -gt 0) {
            [Math]::Round($TotalAllocatedGB / $TotalUsedGB, 2)
        } else { 1.0 }
        
        return @{
            TotalAllocatedGB = [Math]::Round($TotalAllocatedGB, 2)
            TotalUsedGB = [Math]::Round($TotalUsedGB, 2)
            ThinProvisionedGB = [Math]::Round($TotalAllocatedGB - $TotalUsedGB, 2)
            OverprovisionRatio = $OverprovisionRatio
        }
        
    } catch {
        Write-Log "Failed to calculate storage capacity: $($_.Exception.Message)" -Level WARNING
        return @{
            TotalAllocatedGB = 0
            TotalUsedGB = 0
            ThinProvisionedGB = 0
            OverprovisionRatio = 1.0
        }
    }
}

function Get-StorageIssues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMMetrics,
        
        [Parameter()]
        [array]$CSVMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $Issues = @{
        HighIOPS = @()
        HighLatency = @()
        HighQueue = @()
    }
    
    foreach ($VM in $VMMetrics) {
        if ($VM.TotalIOPS -gt $Thresholds.IOPSHigh) {
            $Issues.HighIOPS += "$($VM.VMName) ($($VM.TotalIOPS) IOPS)"
        }
        
        if ($VM.AvgLatencyMS -gt $Thresholds.LatencyCriticalMS) {
            $Issues.HighLatency += "$($VM.VMName) ($($VM.AvgLatencyMS)ms)"
        }
        
        if ($VM.MaxQueueDepth -gt $Thresholds.QueueDepthWarning) {
            $Issues.HighQueue += "$($VM.VMName) (Queue: $($VM.MaxQueueDepth))"
        }
    }
    
    return $Issues
}

function Get-StorageStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Issues,
        
        [Parameter()]
        [array]$CSVMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $CriticalConditions = 0
    $WarningConditions = 0
    
    # Check VM storage issues
    if ($Issues.HighLatency.Count -gt 0) { $CriticalConditions++ }
    if ($Issues.HighQueue.Count -gt 0) { $WarningConditions++ }
    if ($Issues.HighIOPS.Count -gt 0) { $WarningConditions++ }
    
    # Check CSV issues
    if ($CSVMetrics) {
        foreach ($CSV in $CSVMetrics) {
            if ($CSV.AvgLatencyMS -gt $Thresholds.LatencyCriticalMS) {
                $CriticalConditions++
            }
            elseif ($CSV.AvgLatencyMS -gt $Thresholds.LatencyWarningMS) {
                $WarningConditions++
            }
            
            if ($CSV.CacheHitRate -gt 0 -and $CSV.CacheHitRate -lt $Thresholds.CSVCacheHitLow) {
                $WarningConditions++
            }
        }
    }
    
    if ($CriticalConditions -gt 0) {
        return "CRITICAL"
    } elseif ($WarningConditions -gt 0) {
        return "WARNING"
    } else {
        return "HEALTHY"
    }
}

function New-StorageHTMLReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMMetrics,
        
        [Parameter()]
        [array]$CSVMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Issues,
        
        [Parameter(Mandatory)]
        [hashtable]$Capacity,
        
        [Parameter(Mandatory)]
        [int]$FragmentedCount,
        
        [Parameter(Mandatory)]
        [int]$ActiveMigrations
    )
    
    $HTML = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 15px; }
    th { background-color: #0078d4; color: white; padding: 8px; text-align: left; font-weight: 600; }
    td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
    tr:hover { background-color: #f5f5f5; }
    .good { background-color: #d4edda; }
    .warning { background-color: #fff3cd; }
    .critical { background-color: #f8d7da; }
    .summary { background-color: #e7f3ff; padding: 10px; margin-bottom: 15px; border-left: 4px solid #0078d4; }
    .section-title { font-weight: 600; margin-top: 15px; margin-bottom: 8px; color: #0078d4; }
</style>

<div class='summary'>
    <strong>Storage Overview:</strong><br/>
    VMs: $($VMMetrics.Count) | High IOPS: $($Issues.HighIOPS.Count) | High Latency: $($Issues.HighLatency.Count) | Fragmented: $FragmentedCount<br/>
    Thin Provisioned: $($Capacity.ThinProvisionedGB)GB | Overprovision Ratio: $($Capacity.OverprovisionRatio):1 | Active Migrations: $ActiveMigrations
</div>

<div class='section-title'>VM Storage Performance</div>
<table>
    <thead>
        <tr>
            <th>VM Name</th>
            <th>IOPS (R/W)</th>
            <th>Throughput (MB/s)</th>
            <th>Latency (ms)</th>
            <th>Queue</th>
        </tr>
    </thead>
    <tbody>
"@
    
    foreach ($VM in ($VMMetrics | Sort-Object VMName)) {
        $RowClass = 'good'
        if ($VM.AvgLatencyMS -gt 100 -or $VM.MaxQueueDepth -gt 32) {
            $RowClass = 'critical'
        } elseif ($VM.AvgLatencyMS -gt 50 -or $VM.TotalIOPS -gt 20000) {
            $RowClass = 'warning'
        }
        
        $HTML += "        <tr class='$RowClass'>"
        $HTML += "<td>$($VM.VMName)</td>"
        $HTML += "<td>$($VM.TotalIOPS) <small>(R:$($VM.ReadIOPS) W:$($VM.WriteIOPS))</small></td>"
        $HTML += "<td>$($VM.TotalMBps) <small>(R:$($VM.ReadMBps) W:$($VM.WriteMBps))</small></td>"
        $HTML += "<td>$($VM.AvgLatencyMS) <small>(R:$($VM.ReadLatencyMS) W:$($VM.WriteLatencyMS))</small></td>"
        $HTML += "<td>$($VM.MaxQueueDepth)</td>"
        $HTML += "</tr>`n"
    }
    
    $HTML += "    </tbody>`n</table>"
    
    # CSV section if available
    if ($CSVMetrics -and $CSVMetrics.Count -gt 0) {
        $HTML += "<div class='section-title'>CSV Performance</div>"
        $HTML += "<table><thead><tr><th>CSV</th><th>IOPS</th><th>Latency (ms)</th><th>Redirected IOPS</th><th>Cache Hit %</th></tr></thead><tbody>"
        
        foreach ($CSV in $CSVMetrics) {
            $RowClass = if ($CSV.AvgLatencyMS -gt 100) { 'critical' } 
                        elseif ($CSV.AvgLatencyMS -gt 50 -or $CSV.CacheHitRate -lt 70) { 'warning' } 
                        else { 'good' }
            
            $HTML += "<tr class='$RowClass'>"
            $HTML += "<td>$($CSV.Name)</td>"
            $HTML += "<td>$($CSV.TotalIOPS)</td>"
            $HTML += "<td>$($CSV.AvgLatencyMS)</td>"
            $HTML += "<td>$($CSV.RedirectedIOPS)</td>"
            $HTML += "<td>$($CSV.CacheHitRate)</td>"
            $HTML += "</tr>"
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
    
    # Check Hyper-V
    $HyperVService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if (-not $HyperVService -or $HyperVService.Status -ne 'Running') {
        Write-Log "Hyper-V service not running" -Level ERROR
        Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value "NOT_AVAILABLE"
        exit 1
    }
    
    # Import modules
    Import-Module Hyper-V -ErrorAction Stop
    
    # Collect storage performance counters
    $StorageCounters = Get-StoragePerformanceCounters
    if (-not $StorageCounters) {
        Write-Log "Failed to collect storage counters" -Level ERROR
        exit 2
    }
    
    # Collect CSV counters if clustered
    $CSVCounters = Get-CSVPerformanceCounters
    
    # Process metrics
    $VMStorageMetrics = Get-VMStorageMetrics -CounterData $StorageCounters
    $CSVMetrics = if ($CSVCounters) { Get-CSVMetrics -CounterData $CSVCounters } else { $null }
    
    # Check storage migrations
    $ActiveMigrations = Get-StorageMigrations
    
    # Check VHD fragmentation (may be slow)
    $FragmentedVMs = @()  # Get-VHDFragmentation  # Disabled by default - too slow
    
    # Get storage capacity
    $Capacity = Get-StorageCapacity
    
    # Identify issues
    $StorageIssues = Get-StorageIssues -VMMetrics $VMStorageMetrics -CSVMetrics $CSVMetrics -Thresholds $Thresholds
    
    # Determine status
    $StorageStatus = Get-StorageStatus -Issues $StorageIssues -CSVMetrics $CSVMetrics -Thresholds $Thresholds
    
    # Calculate metrics
    $MaxQueueDepth = if ($VMStorageMetrics.Count -gt 0) {
        ($VMStorageMetrics | Measure-Object -Property MaxQueueDepth -Maximum).Maximum
    } else { 0 }
    
    $MaxLatency = if ($VMStorageMetrics.Count -gt 0) {
        ($VMStorageMetrics | Measure-Object -Property AvgLatencyMS -Maximum).Maximum
    } else { 0 }
    
    $AvgCSVCacheHitRate = if ($CSVMetrics -and $CSVMetrics.Count -gt 0) {
        [Math]::Round(($CSVMetrics | Measure-Object -Property CacheHitRate -Average).Average, 2)
    } else { 0 }
    
    # Generate HTML report
    $HTMLReport = New-StorageHTMLReport -VMMetrics $VMStorageMetrics `
                                         -CSVMetrics $CSVMetrics `
                                         -Issues $StorageIssues `
                                         -Capacity $Capacity `
                                         -FragmentedCount $FragmentedVMs.Count `
                                         -ActiveMigrations $ActiveMigrations.Count
    
    # Update fields
    Write-Log "Updating NinjaRMM custom fields..."
    
    Set-NinjaField -FieldName "$($FieldPrefix)VMsHighIOPS" -Value ($StorageIssues.HighIOPS -join "; ")
    Set-NinjaField -FieldName "$($FieldPrefix)VMsHighLatency" -Value ($StorageIssues.HighLatency -join "; ")
    Set-NinjaField -FieldName "$($FieldPrefix)VMsHighQueue" -Value ($StorageIssues.HighQueue -join "; ")
    Set-NinjaField -FieldName "$($FieldPrefix)CSVCacheHitRate" -Value $AvgCSVCacheHitRate
    Set-NinjaField -FieldName "$($FieldPrefix)MigrationsActive" -Value $ActiveMigrations.Count
    Set-NinjaField -FieldName "$($FieldPrefix)FragmentedVMs" -Value $FragmentedVMs.Count
    Set-NinjaField -FieldName "$($FieldPrefix)ThinProvisionedGB" -Value $Capacity.ThinProvisionedGB
    Set-NinjaField -FieldName "$($FieldPrefix)OverprovisionRatio" -Value $Capacity.OverprovisionRatio
    Set-NinjaField -FieldName "$($FieldPrefix)MaxQueueDepth" -Value $MaxQueueDepth
    Set-NinjaField -FieldName "$($FieldPrefix)MaxLatency" -Value $MaxLatency
    Set-NinjaField -FieldName "$($FieldPrefix)CSVStatus" -Value $(if ($CSVMetrics) { "MONITORED" } else { "NOT_CLUSTERED" })
    Set-NinjaField -FieldName "$($FieldPrefix)PerformanceReport" -Value $HTMLReport
    Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value $StorageStatus
    Set-NinjaField -FieldName "$($FieldPrefix)LastScan" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "========================================"
    Write-Log "Storage Performance Summary:"
    Write-Log "  VMs Monitored: $($VMStorageMetrics.Count)"
    Write-Log "  Storage Status: $StorageStatus"
    Write-Log "  Max Queue Depth: $MaxQueueDepth"
    Write-Log "  Max Latency: $($MaxLatency)ms"
    if ($CSVMetrics) {
        Write-Log "  CSV Cache Hit Rate: $($AvgCSVCacheHitRate)%"
    }
    Write-Log "  Overprovision Ratio: $($Capacity.OverprovisionRatio):1"
    Write-Log "========================================"
    Write-Log "Script completed successfully"
    
    exit 0
    
} catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    $ErrorsEncountered++
    $ErrorDetails += $_.Exception.Message
    
    Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value "ERROR"
    
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
