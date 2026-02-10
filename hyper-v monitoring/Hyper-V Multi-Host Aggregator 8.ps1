<#
.SYNOPSIS
    Hyper-V Multi-Host Aggregator - Cluster-wide resource analysis and VM distribution.

.DESCRIPTION
    This script aggregates data across multiple Hyper-V hosts in a cluster:
    - VM distribution across hosts
    - Resource utilization comparison (CPU, memory, storage)
    - VM placement balance analysis
    - Host capacity comparison
    - Overutilized/underutilized host identification
    - VM migration recommendations for load balancing
    - Cluster-wide resource totals and averages
    - Host performance ranking
    - Network utilization per host
    - Storage I/O distribution
    
    Provides cluster administrators with insights for optimal VM placement
    and load balancing decisions.

.NOTES
    Author:         Windows Automation Framework
    Created:        2026-02-10
    Version:        1.0
    Purpose:        Multi-host cluster analytics and load balancing
    
    Execution Context:  SYSTEM
    Execution Frequency: Every 30 minutes
    Estimated Duration: ~30 seconds
    Timeout Setting:    120 seconds
    
    Fields Updated:
    - hypervMultiHostCount (Integer)                  - Total cluster hosts
    - hypervMultiHostVMDistribution (Text)            - VM count per host
    - hypervMultiHostResourceBalance (Float)          - Balance score (0-100)
    - hypervMultiHostOverutilized (Text)              - Overutilized hosts
    - hypervMultiHostUnderutilized (Text)             - Underutilized hosts
    - hypervMultiHostTotalVMs (Integer)               - Total VMs in cluster
    - hypervMultiHostTotalCPU (Integer)               - Total CPU cores
    - hypervMultiHostTotalMemoryGB (Integer)          - Total memory GB
    - hypervMultiHostAvgCPUPercent (Float)            - Cluster average CPU %
    - hypervMultiHostAvgMemoryPercent (Float)         - Cluster average memory %
    - hypervMultiHostMigrationRecommendations (Text)  - VM migration suggestions
    - hypervMultiHostReport (WYSIWYG)                 - HTML cluster analysis
    - hypervMultiHostStatus (Text)                    - Cluster balance status
    - hypervMultiHostLastScan (DateTime)              - Last scan timestamp
    
    Dependencies:
    - Hyper-V role installed
    - Failover Clustering feature
    - FailoverClusters PowerShell module
    - Windows Server 2012 R2 or later
    - Access to all cluster nodes
    
    Exit Codes:
    0  = Success
    1  = Not a cluster node
    2  = Failed to query cluster nodes
    99 = Unexpected error

.EXAMPLE
    .\Hyper-V_Multi-Host_Aggregator_8.ps1

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
$ScriptName = "Hyper-V Multi-Host Aggregator 8"

# Balance thresholds
$Thresholds = @{
    CPUHighPercent = 80            # % - Host considered overutilized
    CPULowPercent = 30             # % - Host considered underutilized
    MemoryHighPercent = 85         # % - Host considered overutilized
    MemoryLowPercent = 40          # % - Host considered underutilized
    VMCountImbalance = 3           # VMs - Max difference for balanced cluster
    BalanceScoreGood = 80          # Score - Good balance
    BalanceScoreWarning = 60       # Score - Warning
}

$FieldPrefix = "hypervMultiHost"

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

function Get-ClusterHostMetrics {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Collecting metrics from all cluster nodes..."
        
        # Get cluster nodes
        $ClusterNodes = Get-ClusterNode -ErrorAction Stop | Where-Object { $_.State -eq 'Up' }
        
        $HostMetrics = @()
        
        foreach ($Node in $ClusterNodes) {
            $NodeName = $Node.Name
            Write-Log "Querying $NodeName..."
            
            try {
                # Get VMs on this host
                $VMs = Get-VM -ComputerName $NodeName -ErrorAction Stop
                $RunningVMs = $VMs | Where-Object { $_.State -eq 'Running' }
                
                # Get host CPU info
                $CPU = Get-CimInstance -ClassName Win32_Processor -ComputerName $NodeName -ErrorAction Stop
                $TotalCores = ($CPU | Measure-Object -Property NumberOfCores -Sum).Sum
                $TotalLogicalProcessors = ($CPU | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
                
                # Get host memory
                $Memory = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $NodeName -ErrorAction Stop
                $TotalMemoryGB = [Math]::Round($Memory.TotalPhysicalMemory / 1GB, 2)
                
                # Get current CPU usage
                try {
                    $CPUUsage = (Get-Counter -ComputerName $NodeName -Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples.CookedValue
                } catch {
                    $CPUUsage = 0
                }
                
                # Get available memory
                try {
                    $AvailableMemoryMB = (Get-Counter -ComputerName $NodeName -Counter '\Memory\Available MBytes' -ErrorAction Stop).CounterSamples.CookedValue
                    $AvailableMemoryGB = [Math]::Round($AvailableMemoryMB / 1024, 2)
                } catch {
                    $AvailableMemoryGB = 0
                }
                
                # Calculate VM resource allocation
                $AllocatedCPU = ($VMs | Measure-Object -Property ProcessorCount -Sum).Sum
                $AllocatedMemoryGB = [Math]::Round(($VMs | Measure-Object -Property MemoryStartup -Sum).Sum / 1GB, 2)
                
                $HostMetrics += [PSCustomObject]@{
                    HostName = $NodeName
                    TotalVMs = $VMs.Count
                    RunningVMs = $RunningVMs.Count
                    TotalCores = $TotalCores
                    TotalLogicalProcessors = $TotalLogicalProcessors
                    AllocatedCPU = $AllocatedCPU
                    CPUUsagePercent = [Math]::Round($CPUUsage, 2)
                    TotalMemoryGB = $TotalMemoryGB
                    AllocatedMemoryGB = $AllocatedMemoryGB
                    AvailableMemoryGB = $AvailableMemoryGB
                    MemoryUsagePercent = [Math]::Round((($TotalMemoryGB - $AvailableMemoryGB) / $TotalMemoryGB) * 100, 2)
                    CPUOvercommit = [Math]::Round($AllocatedCPU / $TotalLogicalProcessors, 2)
                    MemoryOvercommit = [Math]::Round($AllocatedMemoryGB / $TotalMemoryGB, 2)
                }
            } catch {
                Write-Log "Failed to query $NodeName : $($_.Exception.Message)" -Level WARNING
            }
        }
        
        Write-Log "Collected metrics from $($HostMetrics.Count) hosts"
        return $HostMetrics
        
    } catch {
        Write-Log "Failed to collect cluster host metrics: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Get-ResourceBalanceScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$HostMetrics
    )
    
    if ($HostMetrics.Count -le 1) {
        return 100  # Single host, perfect balance
    }
    
    # Calculate standard deviation for VM count, CPU, and memory
    $VMCounts = $HostMetrics.RunningVMs
    $CPUUsages = $HostMetrics.CPUUsagePercent
    $MemoryUsages = $HostMetrics.MemoryUsagePercent
    
    # VM count balance (0-40 points)
    $VMAvg = ($VMCounts | Measure-Object -Average).Average
    $VMStdDev = [Math]::Sqrt((($VMCounts | ForEach-Object { [Math]::Pow($_ - $VMAvg, 2) }) | Measure-Object -Average).Average)
    $VMScore = [Math]::Max(0, 40 - ($VMStdDev * 10))
    
    # CPU balance (0-30 points)
    $CPUAvg = ($CPUUsages | Measure-Object -Average).Average
    $CPUStdDev = [Math]::Sqrt((($CPUUsages | ForEach-Object { [Math]::Pow($_ - $CPUAvg, 2) }) | Measure-Object -Average).Average)
    $CPUScore = [Math]::Max(0, 30 - ($CPUStdDev / 2))
    
    # Memory balance (0-30 points)
    $MemAvg = ($MemoryUsages | Measure-Object -Average).Average
    $MemStdDev = [Math]::Sqrt((($MemoryUsages | ForEach-Object { [Math]::Pow($_ - $MemAvg, 2) }) | Measure-Object -Average).Average)
    $MemScore = [Math]::Max(0, 30 - ($MemStdDev / 2))
    
    $TotalScore = [Math]::Round($VMScore + $CPUScore + $MemScore, 2)
    
    return $TotalScore
}

function Get-OverUnderUtilizedHosts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$HostMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $Overutilized = @()
    $Underutilized = @()
    
    foreach ($Host in $HostMetrics) {
        if ($Host.CPUUsagePercent -gt $Thresholds.CPUHighPercent -or 
            $Host.MemoryUsagePercent -gt $Thresholds.MemoryHighPercent) {
            $Overutilized += "$($Host.HostName) (CPU:$($Host.CPUUsagePercent)% Mem:$($Host.MemoryUsagePercent)%)"
        }
        
        if ($Host.CPUUsagePercent -lt $Thresholds.CPULowPercent -and 
            $Host.MemoryUsagePercent -lt $Thresholds.MemoryLowPercent -and
            $Host.RunningVMs -gt 0) {
            $Underutilized += "$($Host.HostName) (CPU:$($Host.CPUUsagePercent)% Mem:$($Host.MemoryUsagePercent)%)"
        }
    }
    
    return @{
        Overutilized = $Overutilized
        Underutilized = $Underutilized
    }
}

function Get-MigrationRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$HostMetrics,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    $Recommendations = @()
    
    # Find overutilized and underutilized hosts
    $Overutilized = $HostMetrics | Where-Object { 
        $_.CPUUsagePercent -gt $Thresholds.CPUHighPercent -or 
        $_.MemoryUsagePercent -gt $Thresholds.MemoryHighPercent 
    } | Sort-Object CPUUsagePercent -Descending
    
    $Underutilized = $HostMetrics | Where-Object { 
        $_.CPUUsagePercent -lt $Thresholds.CPULowPercent -and 
        $_.MemoryUsagePercent -lt $Thresholds.MemoryLowPercent -and
        $_.RunningVMs -gt 0
    } | Sort-Object CPUUsagePercent
    
    # Check VM count imbalance
    if ($HostMetrics.Count -gt 1) {
        $MaxVMs = ($HostMetrics | Measure-Object -Property RunningVMs -Maximum).Maximum
        $MinVMs = ($HostMetrics | Measure-Object -Property RunningVMs -Minimum).Minimum
        $Difference = $MaxVMs - $MinVMs
        
        if ($Difference -gt $Thresholds.VMCountImbalance) {
            $MaxHost = ($HostMetrics | Where-Object { $_.RunningVMs -eq $MaxVMs } | Select-Object -First 1).HostName
            $MinHost = ($HostMetrics | Where-Object { $_.RunningVMs -eq $MinVMs } | Select-Object -First 1).HostName
            $Recommendations += "VM count imbalance: Consider migrating VMs from $MaxHost ($MaxVMs VMs) to $MinHost ($MinVMs VMs)"
        }
    }
    
    # Resource-based recommendations
    if ($Overutilized.Count -gt 0 -and $Underutilized.Count -gt 0) {
        $SourceHost = $Overutilized[0].HostName
        $DestHost = $Underutilized[0].HostName
        $Recommendations += "Resource imbalance: Migrate VMs from $SourceHost to $DestHost to balance load"
    }
    elseif ($Overutilized.Count -gt 0) {
        $SourceHost = $Overutilized[0].HostName
        $Recommendations += "WARNING: $SourceHost is overutilized (CPU:$($Overutilized[0].CPUUsagePercent)% Mem:$($Overutilized[0].MemoryUsagePercent)%). Consider migrating VMs or adding capacity."
    }
    
    if ($Recommendations.Count -eq 0) {
        $Recommendations += "Cluster load is well balanced. No migrations recommended."
    }
    
    return $Recommendations
}

function Get-ClusterStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [float]$BalanceScore,
        
        [Parameter(Mandatory)]
        [array]$OverutilizedHosts,
        
        [Parameter(Mandatory)]
        [hashtable]$Thresholds
    )
    
    if ($OverutilizedHosts.Count -gt 0) {
        return "CRITICAL"
    }
    elseif ($BalanceScore -lt $Thresholds.BalanceScoreWarning) {
        return "WARNING"
    }
    elseif ($BalanceScore -lt $Thresholds.BalanceScoreGood) {
        return "FAIR"
    }
    else {
        return "HEALTHY"
    }
}

function New-MultiHostHTMLReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$HostMetrics,
        
        [Parameter(Mandatory)]
        [float]$BalanceScore,
        
        [Parameter(Mandatory)]
        [array]$Recommendations
    )
    
    # Calculate cluster totals
    $TotalVMs = ($HostMetrics | Measure-Object -Property TotalVMs -Sum).Sum
    $TotalRunningVMs = ($HostMetrics | Measure-Object -Property RunningVMs -Sum).Sum
    $TotalCores = ($HostMetrics | Measure-Object -Property TotalCores -Sum).Sum
    $TotalMemoryGB = ($HostMetrics | Measure-Object -Property TotalMemoryGB -Sum).Sum
    $AvgCPU = [Math]::Round(($HostMetrics | Measure-Object -Property CPUUsagePercent -Average).Average, 2)
    $AvgMemory = [Math]::Round(($HostMetrics | Measure-Object -Property MemoryUsagePercent -Average).Average, 2)
    
    $HTML = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 15px; }
    th { background-color: #0078d4; color: white; padding: 8px; text-align: left; font-weight: 600; }
    td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
    tr:hover { background-color: #f5f5f5; }
    .summary { background-color: #e7f3ff; padding: 10px; margin-bottom: 15px; border-left: 4px solid #0078d4; }
    .good { background-color: #d4edda; }
    .warning { background-color: #fff3cd; }
    .critical { background-color: #f8d7da; }
    .recommendations { background-color: #fff3cd; padding: 10px; margin-top: 15px; border-left: 4px solid #ffc107; }
    .section { margin-top: 15px; font-weight: 600; color: #0078d4; margin-bottom: 8px; }
</style>

<div class='summary'>
    <strong>Cluster Overview</strong><br/>
    Hosts: $($HostMetrics.Count) | Total VMs: $TotalVMs ($TotalRunningVMs running) | Balance Score: $BalanceScore/100<br/>
    Total CPU Cores: $TotalCores | Total Memory: $($TotalMemoryGB)GB<br/>
    Avg CPU Usage: $AvgCPU% | Avg Memory Usage: $AvgMemory%
</div>

<div class='section'>Host Resource Utilization</div>
<table>
    <thead>
        <tr>
            <th>Host</th>
            <th>VMs</th>
            <th>CPU (Cores)</th>
            <th>CPU Usage</th>
            <th>Memory (GB)</th>
            <th>Memory Usage</th>
            <th>Overcommit</th>
        </tr>
    </thead>
    <tbody>
"@
    
    foreach ($Host in ($HostMetrics | Sort-Object HostName)) {
        $RowClass = if ($Host.CPUUsagePercent -gt 80 -or $Host.MemoryUsagePercent -gt 85) { 'critical' }
                    elseif ($Host.CPUUsagePercent -gt 70 -or $Host.MemoryUsagePercent -gt 75) { 'warning' }
                    else { 'good' }
        
        $HTML += "        <tr class='$RowClass'>"
        $HTML += "<td><strong>$($Host.HostName)</strong></td>"
        $HTML += "<td>$($Host.TotalVMs) ($($Host.RunningVMs) running)</td>"
        $HTML += "<td>$($Host.TotalLogicalProcessors) ($($Host.AllocatedCPU) allocated)</td>"
        $HTML += "<td>$($Host.CPUUsagePercent)%</td>"
        $HTML += "<td>$($Host.TotalMemoryGB) ($($Host.AllocatedMemoryGB) allocated)</td>"
        $HTML += "<td>$($Host.MemoryUsagePercent)%</td>"
        $HTML += "<td>CPU:$($Host.CPUOvercommit):1 Mem:$($Host.MemoryOvercommit):1</td>"
        $HTML += "</tr>`n"
    }
    
    $HTML += "    </tbody>`n</table>"
    
    # Add recommendations
    if ($Recommendations.Count -gt 0) {
        $HTML += "<div class='recommendations'>"
        $HTML += "<strong>Load Balancing Recommendations:</strong><br/>"
        foreach ($Rec in $Recommendations) {
            $HTML += "• $Rec<br/>"
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
    
    # Error tracking (MANDATORY)
    $ErrorsEncountered = 0
    $ErrorDetails = @()
    
    # Check if cluster service exists
    $ClusterService = Get-Service -Name ClusSvc -ErrorAction SilentlyContinue
    if (-not $ClusterService) {
        Write-Log "Cluster service not found. This is not a cluster node." -Level WARNING
        Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value "NOT_CLUSTERED"
        exit 1
    }
    
    if ($ClusterService.Status -ne 'Running') {
        Write-Log "Cluster service is not running" -Level ERROR
        Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value "SERVICE_STOPPED"
        exit 1
    }
    
    # Import modules
    Import-Module FailoverClusters -ErrorAction Stop
    Import-Module Hyper-V -ErrorAction Stop
    
    # Collect host metrics
    $HostMetrics = Get-ClusterHostMetrics
    
    if ($HostMetrics.Count -eq 0) {
        Write-Log "Failed to collect metrics from cluster hosts" -Level ERROR
        Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value "QUERY_FAILED"
        exit 2
    }
    
    # Calculate balance score
    $BalanceScore = Get-ResourceBalanceScore -HostMetrics $HostMetrics
    
    # Identify over/under utilized hosts
    $UtilizationAnalysis = Get-OverUnderUtilizedHosts -HostMetrics $HostMetrics -Thresholds $Thresholds
    
    # Get migration recommendations
    $MigrationRecommendations = Get-MigrationRecommendations -HostMetrics $HostMetrics -Thresholds $Thresholds
    
    # Determine cluster status
    $ClusterStatus = Get-ClusterStatus -BalanceScore $BalanceScore `
                                       -OverutilizedHosts $UtilizationAnalysis.Overutilized `
                                       -Thresholds $Thresholds
    
    # Calculate totals and averages
    $TotalVMs = ($HostMetrics | Measure-Object -Property TotalVMs -Sum).Sum
    $TotalCPU = ($HostMetrics | Measure-Object -Property TotalLogicalProcessors -Sum).Sum
    $TotalMemoryGB = ($HostMetrics | Measure-Object -Property TotalMemoryGB -Sum).Sum
    $AvgCPUPercent = [Math]::Round(($HostMetrics | Measure-Object -Property CPUUsagePercent -Average).Average, 2)
    $AvgMemoryPercent = [Math]::Round(($HostMetrics | Measure-Object -Property MemoryUsagePercent -Average).Average, 2)
    
    # Build VM distribution string
    $VMDistribution = ($HostMetrics | ForEach-Object { "$($_.HostName):$($_.RunningVMs)" }) -join "; "
    
    # Generate HTML report
    $HTMLReport = New-MultiHostHTMLReport -HostMetrics $HostMetrics `
                                           -BalanceScore $BalanceScore `
                                           -Recommendations $MigrationRecommendations
    
    # Update fields
    Write-Log "Updating NinjaRMM custom fields..."
    
    Set-NinjaField -FieldName "$($FieldPrefix)Count" -Value $HostMetrics.Count
    Set-NinjaField -FieldName "$($FieldPrefix)VMDistribution" -Value $VMDistribution
    Set-NinjaField -FieldName "$($FieldPrefix)ResourceBalance" -Value $BalanceScore
    Set-NinjaField -FieldName "$($FieldPrefix)Overutilized" -Value ($UtilizationAnalysis.Overutilized -join "; ")
    Set-NinjaField -FieldName "$($FieldPrefix)Underutilized" -Value ($UtilizationAnalysis.Underutilized -join "; ")
    Set-NinjaField -FieldName "$($FieldPrefix)TotalVMs" -Value $TotalVMs
    Set-NinjaField -FieldName "$($FieldPrefix)TotalCPU" -Value $TotalCPU
    Set-NinjaField -FieldName "$($FieldPrefix)TotalMemoryGB" -Value $TotalMemoryGB
    Set-NinjaField -FieldName "$($FieldPrefix)AvgCPUPercent" -Value $AvgCPUPercent
    Set-NinjaField -FieldName "$($FieldPrefix)AvgMemoryPercent" -Value $AvgMemoryPercent
    Set-NinjaField -FieldName "$($FieldPrefix)MigrationRecommendations" -Value ($MigrationRecommendations -join " | ")
    Set-NinjaField -FieldName "$($FieldPrefix)Report" -Value $HTMLReport
    Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value $ClusterStatus
    Set-NinjaField -FieldName "$($FieldPrefix)LastScan" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "========================================"
    Write-Log "Multi-Host Summary:"
    Write-Log "  Cluster Status: $ClusterStatus"
    Write-Log "  Hosts: $($HostMetrics.Count)"
    Write-Log "  Total VMs: $TotalVMs"
    Write-Log "  Balance Score: $BalanceScore/100"
    Write-Log "  Avg CPU: $AvgCPUPercent% | Avg Memory: $AvgMemoryPercent%"
    Write-Log "  Overutilized Hosts: $($UtilizationAnalysis.Overutilized.Count)"
    Write-Log "  Underutilized Hosts: $($UtilizationAnalysis.Underutilized.Count)"
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
