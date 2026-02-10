<#
.SYNOPSIS
    Hyper-V Performance Monitor - Detailed VM and host performance metrics collection.

.DESCRIPTION
    This script collects detailed performance metrics for Hyper-V hosts and virtual machines:
    - Network throughput per VM (MB/s sent/received)
    - Disk IOPS per VM (read/write operations)
    - Disk latency per VM (read/write milliseconds)
    - Virtual switch performance (packets, drops)
    - Queue depth per virtual disk
    - Live migration bandwidth tracking
    - Host CPU and memory pressure
    
    Performance data is collected using Windows performance counters and formatted
    into HTML reports for dashboard display. High-utilization VMs are identified
    and reported separately for quick identification of performance bottlenecks.

.PARAMETER NinjaRMMField
    Not used directly. Script updates multiple NinjaRMM custom fields.

.NOTES
    Author:         Windows Automation Framework
    Created:        2026-02-10
    Version:        1.0
    Purpose:        Hyper-V performance monitoring with detailed metrics
    
    Execution Context:  SYSTEM
    Execution Frequency: Every 10 minutes
    Estimated Duration: ~20 seconds
    Timeout Setting:    60 seconds
    
    Fields Updated:
    - hypervPerfVMHighNetwork (Text)           - VMs with >500MB/s network usage
    - hypervPerfVMHighIOPS (Text)              - VMs with >10,000 IOPS
    - hypervPerfVMHighLatency (Text)           - VMs with >50ms disk latency
    - hypervPerfVMHighQueue (Text)             - VMs with queue depth >16
    - hypervPerfVSwitchDropRate (Float)        - Packet drop rate percentage
    - hypervPerfQueueDepthMax (Integer)        - Highest queue depth observed
    - hypervPerfMigrationBandwidth (Integer)   - Live migration bandwidth MB/s
    - hypervPerfHostCPUQueue (Integer)         - Processor queue length
    - hypervPerfReport (WYSIWYG)               - HTML performance metrics table
    - hypervPerfStatus (Text)                  - Overall performance status
    - hypervPerfBottlenecks (Integer)          - Count of performance bottlenecks
    - hypervPerfLastScan (DateTime)            - Last scan timestamp
    
    Dependencies:
    - Hyper-V role installed
    - Hyper-V PowerShell module
    - Windows Server 2012 R2 or later
    - Administrator privileges
    
    Exit Codes:
    0  = Success
    1  = Hyper-V not installed
    2  = Module import failed
    3  = Performance counter query failed
    99 = Unexpected error

.EXAMPLE
    .\Hyper-V_Performance_Monitor_3.ps1
    
    Collects performance metrics and updates NinjaRMM fields.

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
$ScriptName = "Hyper-V Performance Monitor 3"

# Performance thresholds
$Thresholds = @{
    NetworkHighMBps = 500      # MB/s - High network usage
    IOPSHigh = 10000           # IOPS - High disk operations
    LatencyWarningMS = 50      # ms - Warning latency
    LatencyCriticalMS = 100    # ms - Critical latency
    QueueDepthWarning = 16     # Queue depth warning
    QueueDepthCritical = 32    # Queue depth critical
    DropRateWarning = 1.0      # % - Packet drop warning
    DropRateCritical = 5.0     # % - Packet drop critical
    CPUQueueWarning = 2        # Per logical processor
}

# NinjaRMM field prefix
$FieldPrefix = "hypervPerf"

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

function Set-NinjaRMMField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value (dual-method for compatibility).
    #>
    param(
        [string]$FieldName,
        [AllowNull()]
        [object]$Value
    )
    
    try {
        # Method 1: Direct Ninja Property
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set -Name $FieldName -Value $Value
        }
        
        # Method 2: Registry-based (fallback)
        $RegPath = "HKLM:\SOFTWARE\NinjaRMMAgent\CustomFields"
        if (Test-Path $RegPath) {
            Set-ItemProperty -Path $RegPath -Name $FieldName -Value $Value -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "Failed to set field $FieldName : $($_.Exception.Message)" -Level WARNING
    }
}

function Get-HyperVPerformanceCounters {
    <#
    .SYNOPSIS
        Collects all Hyper-V performance counters in a single optimized call.
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Collecting performance counters..."
        
        # Build counter array for batch collection
        $CounterPaths = @(
            # Host CPU
            '\Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time',
            '\System\Processor Queue Length',
            
            # VM CPU (all VMs)
            '\Hyper-V Hypervisor Virtual Processor(*)\% Guest Run Time',
            
            # VM Network (all adapters)
            '\Hyper-V Virtual Network Adapter(*)\Bytes Sent/sec',
            '\Hyper-V Virtual Network Adapter(*)\Bytes Received/sec',
            
            # Virtual Switch
            '\Hyper-V Virtual Switch(*)\Packets/sec',
            '\Hyper-V Virtual Switch(*)\Dropped Packets Outgoing/sec',
            
            # VM Storage (all disks)
            '\Hyper-V Virtual Storage Device(*)\Read Operations/sec',
            '\Hyper-V Virtual Storage Device(*)\Write Operations/sec',
            '\Hyper-V Virtual Storage Device(*)\Read Latency',
            '\Hyper-V Virtual Storage Device(*)\Write Latency',
            '\Hyper-V Virtual Storage Device(*)\Queue Length',
            
            # Host Memory
            '\Memory\Available MBytes'
        )
        
        # Check for live migration counters (may not exist if no active migrations)
        try {
            $MigrationCounter = Get-Counter '\Hyper-V VM Live Migration(*)\Data Rate' -ErrorAction Stop -MaxSamples 1
            $HasMigration = $true
        } catch {
            $HasMigration = $false
        }
        
        # Collect all counters
        $Counters = Get-Counter -Counter $CounterPaths -ErrorAction Stop -MaxSamples 1
        
        # Build result object
        $Result = @{
            Timestamp = Get-Date
            HostCPU = ($Counters.CounterSamples | Where-Object { $_.Path -like '*% Total Run Time*' }).CookedValue
            ProcessorQueue = ($Counters.CounterSamples | Where-Object { $_.Path -like '*Processor Queue Length*' }).CookedValue
            AvailableMemoryMB = ($Counters.CounterSamples | Where-Object { $_.Path -like '*Available MBytes*' }).CookedValue
            VMCounters = $Counters.CounterSamples | Where-Object { $_.InstanceName -ne '_Total' -and $_.InstanceName -ne '' }
            HasMigration = $HasMigration
            MigrationCounters = if ($HasMigration) { $MigrationCounter.CounterSamples } else { @() }
        }
        
        Write-Log "Collected $($Result.VMCounters.Count) VM counter samples"
        return $Result
        
    } catch {
        Write-Log "Failed to collect performance counters: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-VMPerformanceMetrics {
    <#
    .SYNOPSIS
        Processes raw performance counters into per-VM metrics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CounterData
    )
    
    try {
        Write-Log "Processing VM performance metrics..."
        
        # Group counters by VM
        $VMMetrics = @{}
        
        foreach ($Sample in $CounterData.VMCounters) {
            # Parse VM name from instance
            $InstanceName = $Sample.InstanceName
            $CounterPath = $Sample.Path
            $Value = $Sample.CookedValue
            
            # Extract VM name based on counter type
            $VMName = $null
            
            if ($CounterPath -like '*Virtual Processor*') {
                # Format: "VMName:Hv VP 0"
                $VMName = ($InstanceName -split ':')[0]
            }
            elseif ($CounterPath -like '*Virtual Network Adapter*') {
                # Format: "VMName - Network Adapter"
                $VMName = ($InstanceName -split ' - ')[0]
            }
            elseif ($CounterPath -like '*Virtual Storage Device*') {
                # Format: "VMName_DiskPath"
                $VMName = ($InstanceName -split '_')[0]
            }
            elseif ($CounterPath -like '*Virtual Switch*') {
                # Virtual switch metrics (not per-VM)
                $VMName = $null
            }
            
            if ($VMName) {
                if (-not $VMMetrics.ContainsKey($VMName)) {
                    $VMMetrics[$VMName] = @{
                        VMName = $VMName
                        CPU = @()
                        NetworkSent = 0
                        NetworkReceived = 0
                        ReadIOPS = 0
                        WriteIOPS = 0
                        ReadLatency = @()
                        WriteLatency = @()
                        QueueDepth = @()
                    }
                }
                
                # Categorize counter
                if ($CounterPath -like '*% Guest Run Time*') {
                    $VMMetrics[$VMName].CPU += $Value
                }
                elseif ($CounterPath -like '*Bytes Sent/sec*') {
                    $VMMetrics[$VMName].NetworkSent += $Value
                }
                elseif ($CounterPath -like '*Bytes Received/sec*') {
                    $VMMetrics[$VMName].NetworkReceived += $Value
                }
                elseif ($CounterPath -like '*Read Operations/sec*') {
                    $VMMetrics[$VMName].ReadIOPS += $Value
                }
                elseif ($CounterPath -like '*Write Operations/sec*') {
                    $VMMetrics[$VMName].WriteIOPS += $Value
                }
                elseif ($CounterPath -like '*Read Latency*') {
                    $VMMetrics[$VMName].ReadLatency += $Value
                }
                elseif ($CounterPath -like '*Write Latency*') {
                    $VMMetrics[$VMName].WriteLatency += $Value
                }
                elseif ($CounterPath -like '*Queue Length*') {
                    $VMMetrics[$VMName].QueueDepth += $Value
                }
            }
        }
        
        # Calculate aggregates and create VM objects
        $VMObjects = @()
        
        foreach ($VMName in $VMMetrics.Keys) {
            $Metrics = $VMMetrics[$VMName]
            
            $VMObj = [PSCustomObject]@{
                VMName = $VMName
                CPUPercent = if ($Metrics.CPU.Count -gt 0) { [Math]::Round(($Metrics.CPU | Measure-Object -Average).Average, 1) } else { 0 }
                NetworkSentMBps = [Math]::Round($Metrics.NetworkSent / 1MB, 2)
                NetworkReceivedMBps = [Math]::Round($Metrics.NetworkReceived / 1MB, 2)
                NetworkTotalMBps = [Math]::Round(($Metrics.NetworkSent + $Metrics.NetworkReceived) / 1MB, 2)
                ReadIOPS = [Math]::Round($Metrics.ReadIOPS, 0)
                WriteIOPS = [Math]::Round($Metrics.WriteIOPS, 0)
                TotalIOPS = [Math]::Round($Metrics.ReadIOPS + $Metrics.WriteIOPS, 0)
                ReadLatencyMS = if ($Metrics.ReadLatency.Count -gt 0) { [Math]::Round(($Metrics.ReadLatency | Measure-Object -Average).Average, 2) } else { 0 }
                WriteLatencyMS = if ($Metrics.WriteLatency.Count -gt 0) { [Math]::Round(($Metrics.WriteLatency | Measure-Object -Average).Average, 2) } else { 0 }
                AvgLatencyMS = if ($Metrics.ReadLatency.Count -gt 0 -or $Metrics.WriteLatency.Count -gt 0) { 
                    [Math]::Round((($Metrics.ReadLatency + $Metrics.WriteLatency | Measure-Object -Average).Average), 2) 
                } else { 0 }
                MaxQueueDepth = if ($Metrics.QueueDepth.Count -gt 0) { [Math]::Round(($Metrics.QueueDepth | Measure-Object -Maximum).Maximum, 0) } else { 0 }
            }
            
            $VMObjects += $VMObj
        }
        
        Write-Log "Processed metrics for $($VMObjects.Count) VMs"
        return $VMObjects
        
    } catch {
        Write-Log "Failed to process VM metrics: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Get-VirtualSwitchMetrics {
    <#
    .SYNOPSIS
        Calculates virtual switch performance metrics including drop rate.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CounterData
    )
    
    try {
        $SwitchCounters = $CounterData.VMCounters | Where-Object { $_.Path -like '*Virtual Switch*' }
        
        $TotalPackets = ($SwitchCounters | Where-Object { $_.Path -like '*Packets/sec*' -and $_.Path -notlike '*Dropped*' } | 
            Measure-Object -Property CookedValue -Sum).Sum
        
        $DroppedPackets = ($SwitchCounters | Where-Object { $_.Path -like '*Dropped*' } | 
            Measure-Object -Property CookedValue -Sum).Sum
        
        $DropRate = if ($TotalPackets -gt 0) {
            [Math]::Round(($DroppedPackets / $TotalPackets) * 100, 4)
        } else { 0 }
        
        return @{
            TotalPacketsPerSec = [Math]::Round($TotalPackets, 0)
            DroppedPacketsPerSec = [Math]::Round($DroppedPackets, 0)
            DropRatePercent = $DropRate
        }
        
    } catch {
        Write-Log "Failed to calculate switch metrics: $($_.Exception.Message)" -Level WARNING
        return @{
            TotalPacketsPerSec = 0
            DroppedPacketsPerSec = 0
            DropRatePercent = 0
        }
    }
}

function Get-LiveMigrationBandwidth {
    <#
    .SYNOPSIS
        Gets current live migration bandwidth if migration is active.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CounterData
    )
    
    if (-not $CounterData.HasMigration) {
        return 0
    }
    
    try {
        $TotalBandwidth = ($CounterData.MigrationCounters | Measure-Object -Property CookedValue -Sum).Sum
        return [Math]::Round($TotalBandwidth / 1MB, 2)
    } catch {
        return 0
    }
}

function Get-PerformanceBottlenecks {
    <#
    .SYNOPSIS
        Identifies VMs with performance bottlenecks based on thresholds.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $Bottlenecks = @{
        HighNetwork = @()
        HighIOPS = @()
        HighLatency = @()
        HighQueue = @()
    }
    
    foreach ($VM in $VMMetrics) {
        if ($VM.NetworkTotalMBps -gt $Thresholds.NetworkHighMBps) {
            $Bottlenecks.HighNetwork += "$($VM.VMName) ($([Math]::Round($VM.NetworkTotalMBps, 0))MB/s)"
        }
        
        if ($VM.TotalIOPS -gt $Thresholds.IOPSHigh) {
            $Bottlenecks.HighIOPS += "$($VM.VMName) ($($VM.TotalIOPS) IOPS)"
        }
        
        if ($VM.AvgLatencyMS -gt $Thresholds.LatencyWarningMS) {
            $Bottlenecks.HighLatency += "$($VM.VMName) ($($VM.AvgLatencyMS)ms)"
        }
        
        if ($VM.MaxQueueDepth -gt $Thresholds.QueueDepthWarning) {
            $Bottlenecks.HighQueue += "$($VM.VMName) (Queue: $($VM.MaxQueueDepth))"
        }
    }
    
    return $Bottlenecks
}

function Get-PerformanceStatus {
    <#
    .SYNOPSIS
        Determines overall performance status based on bottlenecks and thresholds.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Bottlenecks,
        
        [Parameter(Mandatory)]
        [hashtable]$SwitchMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds,
        
        [Parameter(Mandatory)]
        [int]$ProcessorQueue,
        
        [Parameter(Mandatory)]
        [int]$LogicalProcessors
    )
    
    $Issues = @()
    
    # Check for critical conditions
    if ($Bottlenecks.HighLatency.Count -gt 0) {
        $CriticalLatency = $Bottlenecks.HighLatency | Where-Object { $_ -match '\((\d+)ms\)' -and [int]$Matches[1] -gt $Thresholds.LatencyCriticalMS }
        if ($CriticalLatency) {
            $Issues += "CRITICAL: $($CriticalLatency.Count) VMs with critical latency (>$($Thresholds.LatencyCriticalMS)ms)"
        }
    }
    
    if ($SwitchMetrics.DropRatePercent -gt $Thresholds.DropRateCritical) {
        $Issues += "CRITICAL: Virtual switch drop rate $($SwitchMetrics.DropRatePercent)% (>$($Thresholds.DropRateCritical)%)"
    }
    
    if ($ProcessorQueue -gt ($LogicalProcessors * $Thresholds.CPUQueueWarning)) {
        $Issues += "CRITICAL: CPU queue length $ProcessorQueue (threshold: $($LogicalProcessors * $Thresholds.CPUQueueWarning))"
    }
    
    # Check for warning conditions
    if ($Bottlenecks.HighNetwork.Count -gt 0) {
        $Issues += "WARNING: $($Bottlenecks.HighNetwork.Count) VMs with high network usage"
    }
    
    if ($Bottlenecks.HighIOPS.Count -gt 0) {
        $Issues += "WARNING: $($Bottlenecks.HighIOPS.Count) VMs with high IOPS"
    }
    
    if ($Bottlenecks.HighQueue.Count -gt 0) {
        $Issues += "WARNING: $($Bottlenecks.HighQueue.Count) VMs with high queue depth"
    }
    
    if ($SwitchMetrics.DropRatePercent -gt $Thresholds.DropRateWarning -and $SwitchMetrics.DropRatePercent -le $Thresholds.DropRateCritical) {
        $Issues += "WARNING: Virtual switch drop rate $($SwitchMetrics.DropRatePercent)%"
    }
    
    # Determine status
    if ($Issues | Where-Object { $_ -like 'CRITICAL:*' }) {
        return "CRITICAL"
    } elseif ($Issues | Where-Object { $_ -like 'WARNING:*' }) {
        return "WARNING"
    } else {
        return "HEALTHY"
    }
}

function New-PerformanceHTMLReport {
    <#
    .SYNOPSIS
        Generates HTML report of VM performance metrics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$VMMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Bottlenecks,
        
        [Parameter(Mandatory)]
        [hashtable]$SwitchMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds,
        
        [Parameter(Mandatory)]
        [int]$MigrationBandwidth
    )
    
    $HTML = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 15px; }
    th { background-color: #0078d4; color: white; padding: 8px; text-align: left; font-weight: 600; }
    td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
    tr:hover { background-color: #f5f5f5; }
    .excellent { background-color: #d4edda; color: #155724; }
    .good { background-color: #d1ecf1; color: #0c5460; }
    .warning { background-color: #fff3cd; color: #856404; }
    .critical { background-color: #f8d7da; color: #721c24; }
    .summary { background-color: #e7f3ff; padding: 10px; margin-bottom: 15px; border-left: 4px solid #0078d4; }
    .metric { display: inline-block; margin-right: 20px; }
    .metric-label { font-weight: 600; }
</style>

<div class='summary'>
    <div class='metric'><span class='metric-label'>Total VMs:</span> $($VMMetrics.Count)</div>
    <div class='metric'><span class='metric-label'>High Network:</span> $($Bottlenecks.HighNetwork.Count)</div>
    <div class='metric'><span class='metric-label'>High IOPS:</span> $($Bottlenecks.HighIOPS.Count)</div>
    <div class='metric'><span class='metric-label'>High Latency:</span> $($Bottlenecks.HighLatency.Count)</div>
    <div class='metric'><span class='metric-label'>Switch Drop Rate:</span> $($SwitchMetrics.DropRatePercent)%</div>
"@
    
    if ($MigrationBandwidth -gt 0) {
        $HTML += "    <div class='metric'><span class='metric-label'>Live Migration:</span> $($MigrationBandwidth)MB/s</div>"
    }
    
    $HTML += "</div>"
    
    # VM Performance Table
    $HTML += @"
<table>
    <thead>
        <tr>
            <th>VM Name</th>
            <th>CPU %</th>
            <th>Network (MB/s)</th>
            <th>IOPS</th>
            <th>Latency (ms)</th>
            <th>Queue</th>
        </tr>
    </thead>
    <tbody>
"@
    
    foreach ($VM in ($VMMetrics | Sort-Object VMName)) {
        # Determine row class based on worst metric
        $RowClass = 'excellent'
        
        if ($VM.AvgLatencyMS -gt $Thresholds.LatencyCriticalMS -or 
            $VM.MaxQueueDepth -gt $Thresholds.QueueDepthCritical) {
            $RowClass = 'critical'
        }
        elseif ($VM.NetworkTotalMBps -gt $Thresholds.NetworkHighMBps -or 
                $VM.TotalIOPS -gt $Thresholds.IOPSHigh -or 
                $VM.AvgLatencyMS -gt $Thresholds.LatencyWarningMS -or
                $VM.MaxQueueDepth -gt $Thresholds.QueueDepthWarning) {
            $RowClass = 'warning'
        }
        
        $HTML += "        <tr class='$RowClass'>"
        $HTML += "<td>$($VM.VMName)</td>"
        $HTML += "<td>$($VM.CPUPercent)</td>"
        $HTML += "<td>$($VM.NetworkTotalMBps) <small>(↑$($VM.NetworkSentMBps) ↓$($VM.NetworkReceivedMBps))</small></td>"
        $HTML += "<td>$($VM.TotalIOPS) <small>(R:$($VM.ReadIOPS) W:$($VM.WriteIOPS))</small></td>"
        $HTML += "<td>$($VM.AvgLatencyMS) <small>(R:$($VM.ReadLatencyMS) W:$($VM.WriteLatencyMS))</small></td>"
        $HTML += "<td>$($VM.MaxQueueDepth)</td>"
        $HTML += "</tr>`n"
    }
    
    $HTML += "    </tbody>`n</table>"
    
    # Add bottleneck details if any
    if ($Bottlenecks.HighNetwork.Count -gt 0 -or $Bottlenecks.HighIOPS.Count -gt 0 -or 
        $Bottlenecks.HighLatency.Count -gt 0 -or $Bottlenecks.HighQueue.Count -gt 0) {
        
        $HTML += "<div style='margin-top: 10px; padding: 8px; background-color: #fff3cd; border-left: 4px solid #ffc107;'>"
        $HTML += "<strong>Performance Bottlenecks Detected:</strong><br/>"
        
        if ($Bottlenecks.HighNetwork.Count -gt 0) {
            $HTML += "<strong>High Network:</strong> $($Bottlenecks.HighNetwork -join ', ')<br/>"
        }
        if ($Bottlenecks.HighIOPS.Count -gt 0) {
            $HTML += "<strong>High IOPS:</strong> $($Bottlenecks.HighIOPS -join ', ')<br/>"
        }
        if ($Bottlenecks.HighLatency.Count -gt 0) {
            $HTML += "<strong>High Latency:</strong> $($Bottlenecks.HighLatency -join ', ')<br/>"
        }
        if ($Bottlenecks.HighQueue.Count -gt 0) {
            $HTML += "<strong>High Queue:</strong> $($Bottlenecks.HighQueue -join ', ')"
        }
        
        $HTML += "</div>"
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
    
    # Check if Hyper-V is installed
    $HyperVService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if (-not $HyperVService) {
        Write-Log "Hyper-V service (vmms) not found. Hyper-V role not installed." -Level ERROR
        Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value "NOT_INSTALLED"
        exit 1
    }
    
    if ($HyperVService.Status -ne 'Running') {
        Write-Log "Hyper-V service is not running. Status: $($HyperVService.Status)" -Level ERROR
        Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value "SERVICE_STOPPED"
        exit 1
    }
    
    # Import Hyper-V module
    Write-Log "Importing Hyper-V module..."
    try {
        Import-Module Hyper-V -ErrorAction Stop
    } catch {
        Write-Log "Failed to import Hyper-V module: $($_.Exception.Message)" -Level ERROR
        Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value "MODULE_ERROR"
        exit 2
    }
    
    # Get system info for CPU queue threshold calculation
    $LogicalProcessors = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
    Write-Log "Detected $LogicalProcessors logical processors"
    
    # Collect performance counters
    $CounterData = Get-HyperVPerformanceCounters
    if (-not $CounterData) {
        Write-Log "Failed to collect performance counters" -Level ERROR
        Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value "COUNTER_ERROR"
        exit 3
    }
    
    # Process VM metrics
    $VMMetrics = Get-VMPerformanceMetrics -CounterData $CounterData
    
    # Get virtual switch metrics
    $SwitchMetrics = Get-VirtualSwitchMetrics -CounterData $CounterData
    
    # Get live migration bandwidth
    $MigrationBandwidth = Get-LiveMigrationBandwidth -CounterData $CounterData
    
    # Identify bottlenecks
    $Bottlenecks = Get-PerformanceBottlenecks -VMMetrics $VMMetrics -Thresholds $Thresholds
    
    # Determine overall status
    $PerformanceStatus = Get-PerformanceStatus -Bottlenecks $Bottlenecks `
                                                -SwitchMetrics $SwitchMetrics `
                                                -Thresholds $Thresholds `
                                                -ProcessorQueue $CounterData.ProcessorQueue `
                                                -LogicalProcessors $LogicalProcessors
    
    # Generate HTML report
    $HTMLReport = New-PerformanceHTMLReport -VMMetrics $VMMetrics `
                                             -Bottlenecks $Bottlenecks `
                                             -SwitchMetrics $SwitchMetrics `
                                             -Thresholds $Thresholds `
                                             -MigrationBandwidth $MigrationBandwidth
    
    # Calculate total bottlenecks
    $TotalBottlenecks = $Bottlenecks.HighNetwork.Count + $Bottlenecks.HighIOPS.Count + `
                        $Bottlenecks.HighLatency.Count + $Bottlenecks.HighQueue.Count
    
    # Find maximum queue depth across all VMs
    $MaxQueueDepth = if ($VMMetrics.Count -gt 0) {
        ($VMMetrics | Measure-Object -Property MaxQueueDepth -Maximum).Maximum
    } else { 0 }
    
    # Update NinjaRMM fields
    Write-Log "Updating NinjaRMM custom fields..."
    
    Set-NinjaRMMField -FieldName "$($FieldPrefix)VMHighNetwork" -Value ($Bottlenecks.HighNetwork -join "; ")
    Set-NinjaRMMField -FieldName "$($FieldPrefix)VMHighIOPS" -Value ($Bottlenecks.HighIOPS -join "; ")
    Set-NinjaRMMField -FieldName "$($FieldPrefix)VMHighLatency" -Value ($Bottlenecks.HighLatency -join "; ")
    Set-NinjaRMMField -FieldName "$($FieldPrefix)VMHighQueue" -Value ($Bottlenecks.HighQueue -join "; ")
    Set-NinjaRMMField -FieldName "$($FieldPrefix)VSwitchDropRate" -Value $SwitchMetrics.DropRatePercent
    Set-NinjaRMMField -FieldName "$($FieldPrefix)QueueDepthMax" -Value $MaxQueueDepth
    Set-NinjaRMMField -FieldName "$($FieldPrefix)MigrationBandwidth" -Value $MigrationBandwidth
    Set-NinjaRMMField -FieldName "$($FieldPrefix)HostCPUQueue" -Value $CounterData.ProcessorQueue
    Set-NinjaRMMField -FieldName "$($FieldPrefix)Report" -Value $HTMLReport
    Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value $PerformanceStatus
    Set-NinjaRMMField -FieldName "$($FieldPrefix)Bottlenecks" -Value $TotalBottlenecks
    Set-NinjaRMMField -FieldName "$($FieldPrefix)LastScan" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    # Calculate execution time (MANDATORY)
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    
    Write-Log "========================================"
    Write-Log "Performance Summary:"
    Write-Log "  VMs Monitored: $($VMMetrics.Count)"
    Write-Log "  Performance Status: $PerformanceStatus"
    Write-Log "  Total Bottlenecks: $TotalBottlenecks"
    Write-Log "  Switch Drop Rate: $($SwitchMetrics.DropRatePercent)%"
    Write-Log "  Max Queue Depth: $MaxQueueDepth"
    if ($MigrationBandwidth -gt 0) {
        Write-Log "  Live Migration: $($MigrationBandwidth)MB/s"
    }
    Write-Log "  Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    Write-Log "========================================"
    Write-Log "Script completed successfully"
    
    exit 0
    
} catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value "ERROR"
    
    # Calculate execution time even on error
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    
    exit 99
}
