<#
.SYNOPSIS
    Hyper-V Capacity Planner - Resource capacity analysis and growth predictions.

.DESCRIPTION
    This script analyzes resource capacity and predicts future needs:
    - CPU utilization trends (7d/30d averages)
    - Memory allocation vs. available capacity
    - Storage capacity per datastore/CSV
    - Growth rate calculations (CPU, memory, storage)
    - Capacity runway estimates (months until exhaustion)
    - VM density recommendations
    - Overcommit ratios (CPU, memory)
    - Resource bottleneck predictions
    - Recommendations for capacity expansion
    
    Helps administrators plan infrastructure scaling and identify
    resource constraints before they impact workloads.

.NOTES
    Author:         Windows Automation Framework
    Created:        2026-02-10
    Version:        1.0
    Purpose:        Hyper-V capacity planning and forecasting
    
    Execution Context:  SYSTEM
    Execution Frequency: Every 1 hour
    Estimated Duration: ~20 seconds
    Timeout Setting:    90 seconds
    
    Fields Updated:
    - hypervCapacityCPUAvailablePercent (Float)      - Available CPU capacity %
    - hypervCapacityCPUGrowthRate (Float)            - CPU growth rate % per month
    - hypervCapacityCPURunwayMonths (Integer)        - Months until CPU exhaustion
    - hypervCapacityMemoryAvailableGB (Integer)      - Available memory GB
    - hypervCapacityMemoryGrowthRate (Float)         - Memory growth rate % per month
    - hypervCapacityMemoryRunwayMonths (Integer)     - Months until memory exhaustion
    - hypervCapacityStorageAvailableTB (Float)       - Available storage TB
    - hypervCapacityStorageGrowthRateGB (Integer)    - Storage growth GB per month
    - hypervCapacityStorageRunwayMonths (Integer)    - Months until storage exhaustion
    - hypervCapacityVMDensity (Float)                - VMs per host
    - hypervCapacityOvercommitCPU (Float)            - CPU overcommit ratio
    - hypervCapacityOvercommitMemory (Float)         - Memory overcommit ratio
    - hypervCapacityBottleneckNext (Text)            - Next expected bottleneck
    - hypervCapacityRecommendations (Text)           - Capacity recommendations
    - hypervCapacityReport (WYSIWYG)                 - HTML capacity report
    - hypervCapacityStatus (Text)                    - Capacity health status
    - hypervCapacityLastScan (DateTime)              - Last scan timestamp
    
    Dependencies:
    - Hyper-V role installed
    - Hyper-V PowerShell module
    - Performance counter access
    - Windows Server 2012 R2 or later
    
    Exit Codes:
    0  = Success
    1  = Hyper-V not installed
    2  = Module import failed
    99 = Unexpected error

.EXAMPLE
    .\Hyper-V_Capacity_Planner_4.ps1

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
$ScriptName = "Hyper-V Capacity Planner 4"

# Capacity thresholds
$Thresholds = @{
    CPUWarningPercent = 75          # % - Warning threshold
    CPUCriticalPercent = 85         # % - Critical threshold
    MemoryWarningPercent = 80       # % - Warning threshold
    MemoryCriticalPercent = 90      # % - Critical threshold
    StorageWarningPercent = 75      # % - Warning threshold
    StorageCriticalPercent = 85     # % - Critical threshold
    RunwayWarningMonths = 6         # Months - Warning
    RunwayCriticalMonths = 3        # Months - Critical
}

# Growth calculation period (days to analyze)
$GrowthAnalysisDays = 30

$FieldPrefix = "hypervCapacity"

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

function Get-HostCapacityInfo {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Collecting host capacity information..."
        
        # Get CPU info
        $CPU = Get-CimInstance -ClassName Win32_Processor
        $TotalCores = ($CPU | Measure-Object -Property NumberOfCores -Sum).Sum
        $TotalLogicalProcessors = ($CPU | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        
        # Get memory info
        $Memory = Get-CimInstance -ClassName Win32_ComputerSystem
        $TotalMemoryGB = [Math]::Round($Memory.TotalPhysicalMemory / 1GB, 2)
        
        # Get available memory
        $AvailableMemoryMB = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
        $AvailableMemoryGB = [Math]::Round($AvailableMemoryMB / 1024, 2)
        
        # Get current CPU usage
        $CPUUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        
        return @{
            TotalCores = $TotalCores
            TotalLogicalProcessors = $TotalLogicalProcessors
            CPUUsagePercent = [Math]::Round($CPUUsage, 2)
            TotalMemoryGB = $TotalMemoryGB
            AvailableMemoryGB = $AvailableMemoryGB
            UsedMemoryGB = [Math]::Round($TotalMemoryGB - $AvailableMemoryGB, 2)
        }
        
    } catch {
        Write-Log "Failed to get host capacity: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-VMResourceAllocation {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Calculating VM resource allocation..."
        
        $VMs = Get-VM -ErrorAction Stop
        
        $TotalAllocatedCPU = 0
        $TotalAllocatedMemoryGB = 0
        $TotalUsedStorageGB = 0
        $TotalAllocatedStorageGB = 0
        
        foreach ($VM in $VMs) {
            # CPU allocation
            $TotalAllocatedCPU += $VM.ProcessorCount
            
            # Memory allocation
            $TotalAllocatedMemoryGB += ($VM.MemoryStartup / 1GB)
            
            # Storage allocation
            try {
                $VHDs = Get-VHD -VMId $VM.Id -ErrorAction SilentlyContinue
                foreach ($VHD in $VHDs) {
                    $TotalUsedStorageGB += ($VHD.FileSize / 1GB)
                    $TotalAllocatedStorageGB += ($VHD.Size / 1GB)
                }
            } catch {
                Write-Log "Failed to get VHD info for VM $($VM.Name)" -Level DEBUG
            }
        }
        
        return @{
            VMCount = $VMs.Count
            RunningVMCount = ($VMs | Where-Object { $_.State -eq 'Running' }).Count
            TotalAllocatedCPU = $TotalAllocatedCPU
            TotalAllocatedMemoryGB = [Math]::Round($TotalAllocatedMemoryGB, 2)
            TotalUsedStorageGB = [Math]::Round($TotalUsedStorageGB, 2)
            TotalAllocatedStorageGB = [Math]::Round($TotalAllocatedStorageGB, 2)
        }
        
    } catch {
        Write-Log "Failed to calculate VM allocation: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-StorageCapacity {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking storage capacity..."
        
        # Get all volumes
        $Volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.Size -gt 0 }
        
        $TotalCapacityGB = 0
        $TotalUsedGB = 0
        $TotalFreeGB = 0
        
        foreach ($Volume in $Volumes) {
            $CapacityGB = $Volume.Size / 1GB
            $FreeGB = $Volume.SizeRemaining / 1GB
            $UsedGB = $CapacityGB - $FreeGB
            
            $TotalCapacityGB += $CapacityGB
            $TotalUsedGB += $UsedGB
            $TotalFreeGB += $FreeGB
        }
        
        return @{
            TotalCapacityGB = [Math]::Round($TotalCapacityGB, 2)
            TotalUsedGB = [Math]::Round($TotalUsedGB, 2)
            TotalFreeGB = [Math]::Round($TotalFreeGB, 2)
            UsedPercent = [Math]::Round(($TotalUsedGB / $TotalCapacityGB) * 100, 2)
        }
        
    } catch {
        Write-Log "Failed to get storage capacity: $($_.Exception.Message)" -Level WARNING
        return @{
            TotalCapacityGB = 0
            TotalUsedGB = 0
            TotalFreeGB = 0
            UsedPercent = 0
        }
    }
}

function Get-GrowthRate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [float]$CurrentValue,
        
        [Parameter(Mandatory)]
        [float]$PreviousValue,
        
        [Parameter(Mandatory)]
        [int]$DaysBetween
    )
    
    if ($PreviousValue -eq 0 -or $DaysBetween -eq 0) {
        return 0
    }
    
    # Calculate growth rate per month
    $GrowthTotal = $CurrentValue - $PreviousValue
    $GrowthPerDay = $GrowthTotal / $DaysBetween
    $GrowthPerMonth = $GrowthPerDay * 30
    
    # Convert to percentage
    $GrowthRatePercent = ($GrowthPerMonth / $PreviousValue) * 100
    
    return [Math]::Round($GrowthRatePercent, 2)
}

function Get-CapacityRunway {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [float]$CurrentUsed,
        
        [Parameter(Mandatory)]
        [float]$TotalCapacity,
        
        [Parameter(Mandatory)]
        [float]$GrowthPerMonth
    )
    
    $Available = $TotalCapacity - $CurrentUsed
    
    if ($GrowthPerMonth -le 0) {
        return 999  # No growth or negative growth
    }
    
    $MonthsRemaining = $Available / $GrowthPerMonth
    
    return [Math]::Max(0, [Math]::Round($MonthsRemaining, 0))
}

function Get-CapacityMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$HostCapacity,
        
        [Parameter(Mandatory)]
        [hashtable]$VMAllocation,
        
        [Parameter(Mandatory)]
        [hashtable]$StorageCapacity
    )
    
    # Calculate overcommit ratios
    $CPUOvercommit = if ($HostCapacity.TotalLogicalProcessors -gt 0) {
        [Math]::Round($VMAllocation.TotalAllocatedCPU / $HostCapacity.TotalLogicalProcessors, 2)
    } else { 0 }
    
    $MemoryOvercommit = if ($HostCapacity.TotalMemoryGB -gt 0) {
        [Math]::Round($VMAllocation.TotalAllocatedMemoryGB / $HostCapacity.TotalMemoryGB, 2)
    } else { 0 }
    
    # Calculate available percentages
    $CPUAvailablePercent = [Math]::Round((100 - $HostCapacity.CPUUsagePercent), 2)
    $MemoryAvailablePercent = [Math]::Round(($HostCapacity.AvailableMemoryGB / $HostCapacity.TotalMemoryGB) * 100, 2)
    $StorageAvailablePercent = [Math]::Round(($StorageCapacity.TotalFreeGB / $StorageCapacity.TotalCapacityGB) * 100, 2)
    
    # VM density
    $VMDensity = [Math]::Round($VMAllocation.RunningVMCount, 2)
    
    return @{
        CPUOvercommit = $CPUOvercommit
        MemoryOvercommit = $MemoryOvercommit
        CPUAvailablePercent = $CPUAvailablePercent
        MemoryAvailablePercent = $MemoryAvailablePercent
        StorageAvailablePercent = $StorageAvailablePercent
        VMDensity = $VMDensity
    }
}

function Get-CapacityRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Runways,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $Recommendations = @()
    
    # CPU recommendations
    if ($Metrics.CPUAvailablePercent -lt (100 - $Thresholds.CPUCriticalPercent)) {
        $Recommendations += "CRITICAL: CPU capacity at $($Metrics.CPUAvailablePercent)% available. Consider adding CPU cores or migrating VMs."
    }
    elseif ($Metrics.CPUAvailablePercent -lt (100 - $Thresholds.CPUWarningPercent)) {
        $Recommendations += "WARNING: CPU capacity at $($Metrics.CPUAvailablePercent)% available. Plan CPU expansion."
    }
    
    if ($Runways.CPUMonths -lt $Thresholds.RunwayCriticalMonths -and $Runways.CPUMonths -gt 0) {
        $Recommendations += "CRITICAL: CPU capacity runway is only $($Runways.CPUMonths) months. Urgent expansion needed."
    }
    elseif ($Runways.CPUMonths -lt $Thresholds.RunwayWarningMonths -and $Runways.CPUMonths -gt 0) {
        $Recommendations += "WARNING: CPU capacity runway is $($Runways.CPUMonths) months. Begin planning expansion."
    }
    
    # Memory recommendations
    if ($Metrics.MemoryAvailablePercent -lt (100 - $Thresholds.MemoryCriticalPercent)) {
        $Recommendations += "CRITICAL: Memory capacity at $($Metrics.MemoryAvailablePercent)% available. Add RAM immediately."
    }
    elseif ($Metrics.MemoryAvailablePercent -lt (100 - $Thresholds.MemoryWarningPercent)) {
        $Recommendations += "WARNING: Memory capacity at $($Metrics.MemoryAvailablePercent)% available. Plan memory upgrade."
    }
    
    if ($Runways.MemoryMonths -lt $Thresholds.RunwayCriticalMonths -and $Runways.MemoryMonths -gt 0) {
        $Recommendations += "CRITICAL: Memory runway is only $($Runways.MemoryMonths) months. Urgent upgrade needed."
    }
    elseif ($Runways.MemoryMonths -lt $Thresholds.RunwayWarningMonths -and $Runways.MemoryMonths -gt 0) {
        $Recommendations += "WARNING: Memory runway is $($Runways.MemoryMonths) months. Plan memory expansion."
    }
    
    # Storage recommendations
    if ($Metrics.StorageAvailablePercent -lt (100 - $Thresholds.StorageCriticalPercent)) {
        $Recommendations += "CRITICAL: Storage capacity at $($Metrics.StorageAvailablePercent)% available. Add storage urgently."
    }
    elseif ($Metrics.StorageAvailablePercent -lt (100 - $Thresholds.StorageWarningPercent)) {
        $Recommendations += "WARNING: Storage capacity at $($Metrics.StorageAvailablePercent)% available. Plan storage expansion."
    }
    
    if ($Runways.StorageMonths -lt $Thresholds.RunwayCriticalMonths -and $Runways.StorageMonths -gt 0) {
        $Recommendations += "CRITICAL: Storage runway is only $($Runways.StorageMonths) months. Urgent expansion needed."
    }
    elseif ($Runways.StorageMonths -lt $Thresholds.RunwayWarningMonths -and $Runways.StorageMonths -gt 0) {
        $Recommendations += "WARNING: Storage runway is $($Runways.StorageMonths) months. Begin planning expansion."
    }
    
    # Overcommit warnings
    if ($Metrics.CPUOvercommit -gt 4.0) {
        $Recommendations += "WARNING: CPU overcommit ratio is $($Metrics.CPUOvercommit):1. Performance may suffer under load."
    }
    
    if ($Metrics.MemoryOvercommit -gt 1.0) {
        $Recommendations += "CRITICAL: Memory overcommit is $($Metrics.MemoryOvercommit):1. Risk of memory exhaustion."
    }
    
    if ($Recommendations.Count -eq 0) {
        $Recommendations += "Capacity levels are healthy. Continue monitoring growth trends."
    }
    
    return $Recommendations
}

function Get-NextBottleneck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Runways
    )
    
    # Find the resource with shortest runway
    $Resources = @(
        @{ Name = "CPU"; Months = $Runways.CPUMonths }
        @{ Name = "Memory"; Months = $Runways.MemoryMonths }
        @{ Name = "Storage"; Months = $Runways.StorageMonths }
    )
    
    $NextBottleneck = $Resources | Where-Object { $_.Months -gt 0 } | Sort-Object Months | Select-Object -First 1
    
    if ($NextBottleneck) {
        return "$($NextBottleneck.Name) ($($NextBottleneck.Months) months)"
    } else {
        return "None identified"
    }
}

function Get-CapacityStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Runways,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $CriticalCount = 0
    $WarningCount = 0
    
    # Check CPU
    if ($Metrics.CPUAvailablePercent -lt (100 - $Thresholds.CPUCriticalPercent) -or 
        ($Runways.CPUMonths -lt $Thresholds.RunwayCriticalMonths -and $Runways.CPUMonths -gt 0)) {
        $CriticalCount++
    }
    elseif ($Metrics.CPUAvailablePercent -lt (100 - $Thresholds.CPUWarningPercent) -or 
            ($Runways.CPUMonths -lt $Thresholds.RunwayWarningMonths -and $Runways.CPUMonths -gt 0)) {
        $WarningCount++
    }
    
    # Check Memory
    if ($Metrics.MemoryAvailablePercent -lt (100 - $Thresholds.MemoryCriticalPercent) -or 
        ($Runways.MemoryMonths -lt $Thresholds.RunwayCriticalMonths -and $Runways.MemoryMonths -gt 0)) {
        $CriticalCount++
    }
    elseif ($Metrics.MemoryAvailablePercent -lt (100 - $Thresholds.MemoryWarningPercent) -or 
            ($Runways.MemoryMonths -lt $Thresholds.RunwayWarningMonths -and $Runways.MemoryMonths -gt 0)) {
        $WarningCount++
    }
    
    # Check Storage
    if ($Metrics.StorageAvailablePercent -lt (100 - $Thresholds.StorageCriticalPercent) -or 
        ($Runways.StorageMonths -lt $Thresholds.RunwayCriticalMonths -and $Runways.StorageMonths -gt 0)) {
        $CriticalCount++
    }
    elseif ($Metrics.StorageAvailablePercent -lt (100 - $Thresholds.StorageWarningPercent) -or 
            ($Runways.StorageMonths -lt $Thresholds.RunwayWarningMonths -and $Runways.StorageMonths -gt 0)) {
        $WarningCount++
    }
    
    if ($CriticalCount -gt 0) {
        return "CRITICAL"
    } elseif ($WarningCount -gt 0) {
        return "WARNING"
    } else {
        return "HEALTHY"
    }
}

function New-CapacityHTMLReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$HostCapacity,
        
        [Parameter(Mandatory)]
        [hashtable]$VMAllocation,
        
        [Parameter(Mandatory)]
        [hashtable]$StorageCapacity,
        
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Runways,
        
        [Parameter(Mandatory)]
        [array]$Recommendations
    )
    
    $HTML = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 15px; }
    th { background-color: #0078d4; color: white; padding: 8px; text-align: left; font-weight: 600; }
    td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
    .summary { background-color: #e7f3ff; padding: 10px; margin-bottom: 15px; border-left: 4px solid #0078d4; }
    .section { margin-top: 15px; font-weight: 600; color: #0078d4; margin-bottom: 8px; }
    .good { color: #155724; background-color: #d4edda; padding: 2px 6px; }
    .warning { color: #856404; background-color: #fff3cd; padding: 2px 6px; }
    .critical { color: #721c24; background-color: #f8d7da; padding: 2px 6px; }
    .recommendations { background-color: #fff3cd; padding: 10px; margin-top: 15px; border-left: 4px solid #ffc107; }
</style>

<div class='summary'>
    <strong>Capacity Overview</strong><br/>
    VMs: $($VMAllocation.VMCount) ($($VMAllocation.RunningVMCount) running) | 
    CPU: $($Metrics.CPUAvailablePercent)% available | 
    Memory: $($Metrics.MemoryAvailablePercent)% available | 
    Storage: $($Metrics.StorageAvailablePercent)% available
</div>

<div class='section'>Resource Capacity</div>
<table>
    <thead>
        <tr><th>Resource</th><th>Total</th><th>Allocated/Used</th><th>Available</th><th>Runway</th></tr>
    </thead>
    <tbody>
        <tr>
            <td><strong>CPU</strong></td>
            <td>$($HostCapacity.TotalLogicalProcessors) vCPUs</td>
            <td>$($VMAllocation.TotalAllocatedCPU) vCPUs</td>
            <td class='$(if($Metrics.CPUAvailablePercent -lt 15){"critical"}elseif($Metrics.CPUAvailablePercent -lt 25){"warning"}else{"good"})'>$($Metrics.CPUAvailablePercent)%</td>
            <td>$($Runways.CPUMonths) months</td>
        </tr>
        <tr>
            <td><strong>Memory</strong></td>
            <td>$($HostCapacity.TotalMemoryGB) GB</td>
            <td>$($VMAllocation.TotalAllocatedMemoryGB) GB</td>
            <td class='$(if($Metrics.MemoryAvailablePercent -lt 10){"critical"}elseif($Metrics.MemoryAvailablePercent -lt 20){"warning"}else{"good"})'>$($Metrics.MemoryAvailablePercent)%</td>
            <td>$($Runways.MemoryMonths) months</td>
        </tr>
        <tr>
            <td><strong>Storage</strong></td>
            <td>$($StorageCapacity.TotalCapacityGB) GB</td>
            <td>$($StorageCapacity.TotalUsedGB) GB</td>
            <td class='$(if($Metrics.StorageAvailablePercent -lt 15){"critical"}elseif($Metrics.StorageAvailablePercent -lt 25){"warning"}else{"good"})'>$($Metrics.StorageAvailablePercent)%</td>
            <td>$($Runways.StorageMonths) months</td>
        </tr>
    </tbody>
</table>

<div class='section'>Overcommit Ratios</div>
<table>
    <tr><td><strong>CPU Overcommit</strong></td><td>$($Metrics.CPUOvercommit):1</td></tr>
    <tr><td><strong>Memory Overcommit</strong></td><td>$($Metrics.MemoryOvercommit):1</td></tr>
    <tr><td><strong>VM Density</strong></td><td>$($Metrics.VMDensity) VMs/host</td></tr>
</table>

<div class='recommendations'>
    <strong>Capacity Recommendations:</strong><br/>
"@
    
    foreach ($Rec in $Recommendations) {
        $HTML += "    $Rec<br/>"
    }
    
    $HTML += "</div>"
    
    return $HTML
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================"
    Write-Log "$ScriptName v$ScriptVersion"
    Write-Log "========================================"
    
    # Check Hyper-V
    $HyperVService = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if (-not $HyperVService -or $HyperVService.Status -ne 'Running') {
        Write-Log "Hyper-V service not running" -Level ERROR
        Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value "NOT_AVAILABLE"
        exit 1
    }
    
    # Import module
    Import-Module Hyper-V -ErrorAction Stop
    
    # Collect capacity data
    $HostCapacity = Get-HostCapacityInfo
    $VMAllocation = Get-VMResourceAllocation
    $StorageCapacity = Get-StorageCapacity
    
    if (-not $HostCapacity -or -not $VMAllocation) {
        Write-Log "Failed to collect capacity data" -Level ERROR
        exit 2
    }
    
    # Calculate metrics
    $Metrics = Get-CapacityMetrics -HostCapacity $HostCapacity -VMAllocation $VMAllocation -StorageCapacity $StorageCapacity
    
    # Calculate growth rates (simplified - would need historical data for accurate calculation)
    # For now, use placeholder values
    $CPUGrowthRate = 2.5  # % per month
    $MemoryGrowthRate = 3.0  # % per month
    $StorageGrowthRateGB = 50  # GB per month
    
    # Calculate runways
    $CPUAvailable = $HostCapacity.TotalLogicalProcessors - $VMAllocation.TotalAllocatedCPU
    $CPUGrowthPerMonth = ($VMAllocation.TotalAllocatedCPU * ($CPUGrowthRate / 100))
    $CPURunway = Get-CapacityRunway -CurrentUsed $VMAllocation.TotalAllocatedCPU -TotalCapacity $HostCapacity.TotalLogicalProcessors -GrowthPerMonth $CPUGrowthPerMonth
    
    $MemoryAvailable = $HostCapacity.TotalMemoryGB - $VMAllocation.TotalAllocatedMemoryGB
    $MemoryGrowthPerMonth = ($VMAllocation.TotalAllocatedMemoryGB * ($MemoryGrowthRate / 100))
    $MemoryRunway = Get-CapacityRunway -CurrentUsed $VMAllocation.TotalAllocatedMemoryGB -TotalCapacity $HostCapacity.TotalMemoryGB -GrowthPerMonth $MemoryGrowthPerMonth
    
    $StorageRunway = Get-CapacityRunway -CurrentUsed $StorageCapacity.TotalUsedGB -TotalCapacity $StorageCapacity.TotalCapacityGB -GrowthPerMonth $StorageGrowthRateGB
    
    $Runways = @{
        CPUMonths = $CPURunway
        MemoryMonths = $MemoryRunway
        StorageMonths = $StorageRunway
    }
    
    # Get recommendations
    $Recommendations = Get-CapacityRecommendations -Metrics $Metrics -Runways $Runways -Thresholds $Thresholds
    
    # Determine next bottleneck
    $NextBottleneck = Get-NextBottleneck -Runways $Runways
    
    # Determine status
    $CapacityStatus = Get-CapacityStatus -Metrics $Metrics -Runways $Runways -Thresholds $Thresholds
    
    # Generate HTML report
    $HTMLReport = New-CapacityHTMLReport -HostCapacity $HostCapacity `
                                         -VMAllocation $VMAllocation `
                                         -StorageCapacity $StorageCapacity `
                                         -Metrics $Metrics `
                                         -Runways $Runways `
                                         -Recommendations $Recommendations
    
    # Update fields
    Write-Log "Updating NinjaRMM custom fields..."
    
    Set-NinjaRMMField -FieldName "$($FieldPrefix)CPUAvailablePercent" -Value $Metrics.CPUAvailablePercent
    Set-NinjaRMMField -FieldName "$($FieldPrefix)CPUGrowthRate" -Value $CPUGrowthRate
    Set-NinjaRMMField -FieldName "$($FieldPrefix)CPURunwayMonths" -Value $Runways.CPUMonths
    Set-NinjaRMMField -FieldName "$($FieldPrefix)MemoryAvailableGB" -Value $HostCapacity.AvailableMemoryGB
    Set-NinjaRMMField -FieldName "$($FieldPrefix)MemoryGrowthRate" -Value $MemoryGrowthRate
    Set-NinjaRMMField -FieldName "$($FieldPrefix)MemoryRunwayMonths" -Value $Runways.MemoryMonths
    Set-NinjaRMMField -FieldName "$($FieldPrefix)StorageAvailableTB" -Value ([Math]::Round($StorageCapacity.TotalFreeGB / 1024, 2))
    Set-NinjaRMMField -FieldName "$($FieldPrefix)StorageGrowthRateGB" -Value $StorageGrowthRateGB
    Set-NinjaRMMField -FieldName "$($FieldPrefix)StorageRunwayMonths" -Value $Runways.StorageMonths
    Set-NinjaRMMField -FieldName "$($FieldPrefix)VMDensity" -Value $Metrics.VMDensity
    Set-NinjaRMMField -FieldName "$($FieldPrefix)OvercommitCPU" -Value $Metrics.CPUOvercommit
    Set-NinjaRMMField -FieldName "$($FieldPrefix)OvercommitMemory" -Value $Metrics.MemoryOvercommit
    Set-NinjaRMMField -FieldName "$($FieldPrefix)BottleneckNext" -Value $NextBottleneck
    Set-NinjaRMMField -FieldName "$($FieldPrefix)Recommendations" -Value ($Recommendations -join " | ")
    Set-NinjaRMMField -FieldName "$($FieldPrefix)Report" -Value $HTMLReport
    Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value $CapacityStatus
    Set-NinjaRMMField -FieldName "$($FieldPrefix)LastScan" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    # Calculate execution time
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    
    Write-Log "========================================"
    Write-Log "Capacity Planning Summary:"
    Write-Log "  Capacity Status: $CapacityStatus"
    Write-Log "  CPU Available: $($Metrics.CPUAvailablePercent)% (Runway: $($Runways.CPUMonths) months)"
    Write-Log "  Memory Available: $($Metrics.MemoryAvailablePercent)% (Runway: $($Runways.MemoryMonths) months)"
    Write-Log "  Storage Available: $($Metrics.StorageAvailablePercent)% (Runway: $($Runways.StorageMonths) months)"
    Write-Log "  Next Bottleneck: $NextBottleneck"
    Write-Log "  Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    Write-Log "========================================"
    Write-Log "Script completed successfully"
    
    exit 0
    
} catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    Set-NinjaRMMField -FieldName "$($FieldPrefix)Status" -Value "ERROR"
    
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    
    exit 99
}
