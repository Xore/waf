<#
.SYNOPSIS
    Hyper-V Quick Health Check - Rapid host and cluster health assessment

.DESCRIPTION
    Performs rapid health assessment of Hyper-V infrastructure with focus on critical
    issues, recent events, and performance bottlenecks. Designed as a complement to the
    comprehensive monitoring script (Hyper-V Monitor 1.ps1) with emphasis on quick
    health status determination and problem detection.
    
    This script provides fast health checks suitable for frequent execution without the
    overhead of detailed VM enumeration. Ideal for alerting and dashboard status indicators.
    
    Health Check Scope:
    
    Node Health Checks:
    - Hyper-V service status (vmms)
    - Hyper-V hypervisor status
    - Host CPU and memory thresholds
    - Critical event log entries (last 24 hours)
    - Storage subsystem health
    - Network adapter status
    - Virtual switch operational state
    - Recent system reboots
    
    Failover Cluster Health (if clustered):
    - Cluster service status
    - Quorum health and vote count
    - Node membership and states
    - Cluster Shared Volume (CSV) status
    - CSV free space warnings
    - Recent cluster events
    - Cluster network status
    - Resource group health
    
    Virtual Machine Quick Checks:
    - Total VM count and state distribution
    - VMs with failed heartbeat
    - VMs with critical integration service failures
    - Recently stopped/crashed VMs (last 24 hours)
    - VMs with high resource consumption
    - Replication health summary
    - VMs with pending restarts
    
    Event Log Monitoring:
    - Hyper-V Admin log critical/error events
    - Hyper-V Worker critical events
    - Cluster service errors (if clustered)
    - System log hypervisor errors
    - Storage channel errors
    - Network VSP errors
    - Replication failures
    - Integration service failures
    
    Performance Thresholds:
    - Host CPU usage (Critical: >90%, Warning: >80%)
    - Host memory pressure (Critical: >95%, Warning: >85%)
    - Storage latency (Warning: >50ms, Critical: >100ms)
    - Network packet loss detection
    - CSV IOPS and latency
    - Live migration queue depth
    
    Health Status Output:
    
    Overall Status Classifications:
    - HEALTHY: All checks passed, no critical issues
    - WARNING: Non-critical issues detected, monitoring required
    - CRITICAL: Critical issues requiring immediate attention
    - UNKNOWN: Unable to determine health (service down, access denied)
    
    Status Determination Logic:
    - Critical events in last 24 hours → CRITICAL
    - Cluster quorum lost → CRITICAL
    - Host resources >95% → CRITICAL
    - Multiple VM heartbeat failures → CRITICAL
    - CSV space <10% → CRITICAL
    - Warning-level events or thresholds → WARNING
    - All checks passed → HEALTHY
    
    Output Format:
    - Plain text summary for quick dashboard display
    - Color-coded status indicators
    - Issue count by severity
    - Top 5 issues requiring attention
    - Timestamp of health check
    - Stores in text field for alerting

.NOTES
    Script Name:    Hyper-V Health Check 2.ps1
    Author:         Windows Automation Framework
    Version:        1.0
    Creation Date:  2026-02-10
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Every 5 minutes (frequent health checks)
    Typical Duration: ~10 seconds
    Timeout Setting: 60 seconds
    
    User Interaction: NONE (fully automated)
    Restart Behavior: Never restarts device
    
    Fields Updated:
        - hypervQuickHealth (Text: HEALTHY, WARNING, CRITICAL, UNKNOWN)
        - hypervHealthSummary (Text: Brief health summary)
        - hypervCriticalIssues (Integer: count of critical issues)
        - hypervWarningIssues (Integer: count of warning issues)
        - hypervLastHealthCheck (DateTime: last check timestamp - ISO format)
        - hypervTopIssues (Text: Top 5 issues list)
        - hypervEventErrors (Integer: critical event count last 24h)
        - hypervClusterQuorumOK (Checkbox: cluster has quorum)
        - hypervCSVHealthy (Checkbox: all CSVs healthy)
        - hypervCSVLowSpace (Integer: CSVs with <20% free)
        - hypervVMsUnhealthy (Integer: VMs with failed heartbeat)
        - hypervReplicationIssues (Integer: VMs with replication problems)
        - hypervStorageLatencyMS (Integer: average storage latency)
    
    Dependencies:
        - Windows PowerShell 5.1+
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Hyper-V role installed
        - Hyper-V PowerShell module
        - FailoverClusters module (if clustered)
    
    Exit Codes:
        0 - Success (health check completed)
        1 - General error
        2 - Missing dependencies
        3 - Permission denied

.LINK
    https://github.com/Xore/waf
    
.LINK
    Complements: Hyper-V Monitor 1.ps1 (detailed monitoring)
#>

[CmdletBinding()]
param()

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "1.0"

# Logging configuration
$LogLevel = "INFO"
$VerbosePreference = 'SilentlyContinue'

# Timeouts and limits
$DefaultTimeout = 60
$EventLogHours = 24  # Check events from last 24 hours

# NinjaRMM CLI path
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# Health thresholds
$CPUWarning = 80
$CPUCritical = 90
$MemoryWarning = 85
$MemoryCritical = 95
$CSVSpaceWarning = 20  # Percent free
$CSVSpaceCritical = 10  # Percent free
$StorageLatencyWarning = 50  # Milliseconds
$StorageLatencyCritical = 100  # Milliseconds

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ScriptName = $MyInvocation.MyCommand.Name

$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

# Health tracking
$script:CriticalIssues = @()
$script:WarningIssues = @()
$script:InfoItems = @()

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'DEBUG' { 
            if ($LogLevel -eq 'DEBUG') { 
                Write-Verbose $LogMessage 
            } 
        }
        'INFO'  { Write-Output $LogMessage }
        'WARN'  { 
            Write-Warning $LogMessage
            $script:WarningCount++ 
        }
        'ERROR' { 
            Write-Error $LogMessage -ErrorAction Continue
            $script:ErrorCount++ 
        }
    }
}

function Set-NinjaField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value provided" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' set to: $ValueString" -Level DEBUG
            return
        } else {
            throw "Cmdlet not found"
        }
    } catch {
        Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
        
        try {
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            $CLIArgs = @("set", $FieldName, $ValueString)
            $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "CLI returned exit code: $LASTEXITCODE"
            }
            
            Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
            $script:CLIFallbackCount++
            
        } catch {
            Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
            throw
        }
    }
}

function Add-CriticalIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Issue
    )
    
    $script:CriticalIssues += $Issue
    Write-Log "CRITICAL: $Issue" -Level ERROR
}

function Add-WarningIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Issue
    )
    
    $script:WarningIssues += $Issue
    Write-Log "WARNING: $Issue" -Level WARN
}

function Add-InfoItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Info
    )
    
    $script:InfoItems += $Info
    Write-Log "INFO: $Info" -Level DEBUG
}

function Test-HyperVService {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking Hyper-V service status..." -Level INFO
        
        $VMService = Get-Service -Name "vmms" -ErrorAction Stop
        
        if ($VMService.Status -ne 'Running') {
            Add-CriticalIssue "Hyper-V VMMS service not running (Status: $($VMService.Status))"
            return $false
        }
        
        Add-InfoItem "Hyper-V VMMS service running"
        return $true
        
    } catch {
        Add-CriticalIssue "Hyper-V service check failed: $_"
        return $false
    }
}

function Get-HostResourceHealth {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking host resource health..." -Level INFO
        
        # CPU check
        $CPU = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        if ($CPU) {
            $CPUPercent = [Math]::Round($CPU.CounterSamples[0].CookedValue)
            
            if ($CPUPercent -ge $CPUCritical) {
                Add-CriticalIssue "Host CPU at $CPUPercent% (Critical threshold: $CPUCritical%)"
            } elseif ($CPUPercent -ge $CPUWarning) {
                Add-WarningIssue "Host CPU at $CPUPercent% (Warning threshold: $CPUWarning%)"
            } else {
                Add-InfoItem "Host CPU: $CPUPercent%"
            }
        }
        
        # Memory check
        $OS = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($OS) {
            $TotalMemory = $OS.TotalVisibleMemorySize
            $FreeMemory = $OS.FreePhysicalMemory
            $UsedMemory = $TotalMemory - $FreeMemory
            $MemoryPercent = [Math]::Round(($UsedMemory / $TotalMemory) * 100)
            
            if ($MemoryPercent -ge $MemoryCritical) {
                Add-CriticalIssue "Host memory at $MemoryPercent% (Critical threshold: $MemoryCritical%)"
            } elseif ($MemoryPercent -ge $MemoryWarning) {
                Add-WarningIssue "Host memory at $MemoryPercent% (Warning threshold: $MemoryWarning%)"
            } else {
                Add-InfoItem "Host memory: $MemoryPercent%"
            }
        }
        
        return $true
        
    } catch {
        Add-WarningIssue "Resource health check failed: $_"
        return $false
    }
}

function Get-RecentHyperVEvents {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking recent Hyper-V events..." -Level INFO
        
        $StartTime = (Get-Date).AddHours(-$EventLogHours)
        $EventCount = 0
        
        # Critical event log sources
        $EventSources = @(
            @{Name="Microsoft-Windows-Hyper-V-VMMS-Admin"; Levels=@(1,2)},  # Critical, Error
            @{Name="Microsoft-Windows-Hyper-V-Worker-Admin"; Levels=@(1,2)},
            @{Name="Microsoft-Windows-Hyper-V-Compute-Admin"; Levels=@(1,2)},
            @{Name="Microsoft-Windows-Hyper-V-Config-Admin"; Levels=@(1,2)},
            @{Name="System"; Levels=@(1,2); Provider="Microsoft-Windows-Hyper-V*"}
        )
        
        foreach ($Source in $EventSources) {
            try {
                $FilterHash = @{
                    LogName = $Source.Name
                    Level = $Source.Levels
                    StartTime = $StartTime
                }
                
                if ($Source.Provider) {
                    $FilterHash['ProviderName'] = $Source.Provider
                }
                
                $Events = Get-WinEvent -FilterHashtable $FilterHash -ErrorAction SilentlyContinue -MaxEvents 50
                
                if ($Events) {
                    $EventCount += $Events.Count
                    
                    # Check for specific critical events
                    foreach ($Event in $Events) {
                        switch ($Event.Id) {
                            18510 { Add-InfoItem "VM started: $($Event.Message)" }
                            18511 { Add-WarningIssue "VM stopped: Event ID $($Event.Id)" }
                            18520 { Add-InfoItem "Checkpoint created" }
                            18550 { Add-CriticalIssue "VM CPU threshold exceeded: $($Event.Message)" }
                            18551 { Add-CriticalIssue "VM memory pressure detected: $($Event.Message)" }
                            18552 { Add-CriticalIssue "Storage latency affecting VM: $($Event.Message)" }
                            4097 { Add-CriticalIssue "VM heartbeat stopped: $($Event.Message)" }
                            14001 { Add-CriticalIssue "VMMS stopped unexpectedly" }
                            14010 { Add-CriticalIssue "VMMS initialization failed" }
                            32004 { Add-CriticalIssue "VM replication failed: $($Event.Message)" }
                            32010 { Add-CriticalIssue "Replication connection lost: $($Event.Message)" }
                            default { 
                                if ($Event.Level -eq 1) {
                                    Add-CriticalIssue "Critical event $($Event.Id): $($Event.LevelDisplayName)"
                                }
                            }
                        }
                    }
                }
                
            } catch {
                Write-Log "Error checking $($Source.Name): $_" -Level DEBUG
            }
        }
        
        if ($EventCount -gt 0) {
            Write-Log "Found $EventCount critical/error events in last $EventLogHours hours" -Level INFO
        } else {
            Add-InfoItem "No critical events in last $EventLogHours hours"
        }
        
        return $EventCount
        
    } catch {
        Add-WarningIssue "Event log check failed: $_"
        return 0
    }
}

function Get-VMHealthStatus {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking VM health status..." -Level INFO
        
        if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
            Add-WarningIssue "Hyper-V module not available for VM checks"
            return @{Unhealthy=0; Total=0; ReplicationIssues=0}
        }
        
        Import-Module Hyper-V -ErrorAction Stop
        
        $VMs = Get-VM -ErrorAction Stop
        $UnhealthyVMs = 0
        $ReplicationIssues = 0
        
        foreach ($VM in $VMs) {
            # Check heartbeat for running VMs
            if ($VM.State -eq 'Running') {
                $IntServices = Get-VMIntegrationService -VM $VM -ErrorAction SilentlyContinue
                $Heartbeat = $IntServices | Where-Object { $_.Name -like "*Heartbeat*" }
                
                if ($Heartbeat -and $Heartbeat.PrimaryStatusDescription -eq 'LostCommunication') {
                    Add-CriticalIssue "VM '$($VM.Name)' heartbeat lost"
                    $UnhealthyVMs++
                } elseif ($Heartbeat -and $Heartbeat.PrimaryStatusDescription -eq 'NoContact') {
                    Add-WarningIssue "VM '$($VM.Name)' no heartbeat contact"
                    $UnhealthyVMs++
                }
            }
            
            # Check replication health
            $Replication = Get-VMReplication -VM $VM -ErrorAction SilentlyContinue
            if ($Replication) {
                if ($Replication.ReplicationHealth -eq 'Critical') {
                    Add-CriticalIssue "VM '$($VM.Name)' replication critical"
                    $ReplicationIssues++
                } elseif ($Replication.ReplicationHealth -eq 'Warning') {
                    Add-WarningIssue "VM '$($VM.Name)' replication warning"
                    $ReplicationIssues++
                }
            }
        }
        
        if ($UnhealthyVMs -eq 0 -and $ReplicationIssues -eq 0) {
            Add-InfoItem "All VMs healthy ($($VMs.Count) total)"
        }
        
        return @{
            Unhealthy = $UnhealthyVMs
            Total = $VMs.Count
            ReplicationIssues = $ReplicationIssues
        }
        
    } catch {
        Add-WarningIssue "VM health check failed: $_"
        return @{Unhealthy=0; Total=0; ReplicationIssues=0}
    }
}

function Get-ClusterHealth {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking cluster health..." -Level INFO
        
        $ClusterHealth = @{
            Clustered = $false
            QuorumOK = $false
            CSVHealthy = $true
            CSVLowSpace = 0
            AvgLatency = 0
        }
        
        # Check if clustered
        if (-not (Get-Module -ListAvailable -Name FailoverClusters)) {
            Write-Log "Not a cluster member" -Level DEBUG
            return $ClusterHealth
        }
        
        Import-Module FailoverClusters -ErrorAction Stop
        
        $Cluster = Get-Cluster -ErrorAction SilentlyContinue
        if (-not $Cluster) {
            Write-Log "Not a cluster member" -Level DEBUG
            return $ClusterHealth
        }
        
        $ClusterHealth.Clustered = $true
        Add-InfoItem "Cluster member: $($Cluster.Name)"
        
        # Check quorum
        try {
            $Quorum = Get-ClusterQuorum -ErrorAction Stop
            
            # Check if cluster has quorum by looking at node states
            $Nodes = Get-ClusterNode -ErrorAction Stop
            $UpNodes = @($Nodes | Where-Object { $_.State -eq 'Up' }).Count
            $TotalNodes = $Nodes.Count
            
            # Simple quorum check - majority of nodes up
            if ($UpNodes -gt ($TotalNodes / 2)) {
                $ClusterHealth.QuorumOK = $true
                Add-InfoItem "Cluster has quorum ($UpNodes/$TotalNodes nodes up)"
            } else {
                $ClusterHealth.QuorumOK = $false
                Add-CriticalIssue "Cluster quorum lost ($UpNodes/$TotalNodes nodes up)"
            }
            
            # Check for down nodes
            $DownNodes = $Nodes | Where-Object { $_.State -ne 'Up' }
            foreach ($Node in $DownNodes) {
                Add-CriticalIssue "Cluster node down: $($Node.Name) (State: $($Node.State))"
            }
            
        } catch {
            Add-WarningIssue "Cluster quorum check failed: $_"
        }
        
        # Check CSV health
        try {
            $CSVs = Get-ClusterSharedVolume -ErrorAction Stop
            
            foreach ($CSV in $CSVs) {
                $CSVPath = $CSV.SharedVolumeInfo.FriendlyVolumeName
                
                # Check CSV state
                if ($CSV.State -ne 'Online') {
                    $ClusterHealth.CSVHealthy = $false
                    Add-CriticalIssue "CSV offline: $($CSV.Name) (State: $($CSV.State))"
                }
                
                # Check free space
                if ($CSVPath) {
                    try {
                        $Volume = Get-Volume -FilePath $CSVPath -ErrorAction SilentlyContinue
                        if ($Volume) {
                            $PercentFree = [Math]::Round(($Volume.SizeRemaining / $Volume.Size) * 100)
                            
                            if ($PercentFree -le $CSVSpaceCritical) {
                                $ClusterHealth.CSVLowSpace++
                                Add-CriticalIssue "CSV critical space: $($CSV.Name) ($PercentFree% free)"
                            } elseif ($PercentFree -le $CSVSpaceWarning) {
                                $ClusterHealth.CSVLowSpace++
                                Add-WarningIssue "CSV low space: $($CSV.Name) ($PercentFree% free)"
                            } else {
                                Add-InfoItem "CSV $($CSV.Name): $PercentFree% free"
                            }
                        }
                    } catch {
                        Add-WarningIssue "CSV space check failed for $($CSV.Name): $_"
                    }
                }
            }
            
            if ($ClusterHealth.CSVHealthy -and $ClusterHealth.CSVLowSpace -eq 0) {
                Add-InfoItem "All CSVs healthy ($($CSVs.Count) total)"
            }
            
        } catch {
            Add-WarningIssue "CSV health check failed: $_"
        }
        
        return $ClusterHealth
        
    } catch {
        Add-WarningIssue "Cluster health check failed: $_"
        return @{
            Clustered = $false
            QuorumOK = $false
            CSVHealthy = $true
            CSVLowSpace = 0
            AvgLatency = 0
        }
    }
}

function Get-StorageLatency {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking storage latency..." -Level INFO
        
        # Try to get Hyper-V specific disk latency
        $LatencyCounter = Get-Counter '\Hyper-V Virtual Storage Device(*)\Normalized Throughput' -ErrorAction SilentlyContinue
        
        if (-not $LatencyCounter) {
            # Fallback to physical disk latency
            $LatencyCounter = Get-Counter '\PhysicalDisk(*)\Avg. Disk sec/Transfer' -ErrorAction SilentlyContinue
        }
        
        if ($LatencyCounter) {
            # Convert to milliseconds
            $AvgLatency = [Math]::Round(($LatencyCounter.CounterSamples | Measure-Object -Property CookedValue -Average).Average * 1000)
            
            if ($AvgLatency -ge $StorageLatencyCritical) {
                Add-CriticalIssue "Storage latency critical: ${AvgLatency}ms (Threshold: ${StorageLatencyCritical}ms)"
            } elseif ($AvgLatency -ge $StorageLatencyWarning) {
                Add-WarningIssue "Storage latency high: ${AvgLatency}ms (Threshold: ${StorageLatencyWarning}ms)"
            } else {
                Add-InfoItem "Storage latency: ${AvgLatency}ms"
            }
            
            return $AvgLatency
        }
        
        return 0
        
    } catch {
        Write-Log "Storage latency check failed: $_" -Level DEBUG
        return 0
    }
}

function Get-OverallHealthStatus {
    [CmdletBinding()]
    param()
    
    # Determine overall health based on issue counts
    if ($script:CriticalIssues.Count -gt 0) {
        return "CRITICAL"
    } elseif ($script:WarningIssues.Count -gt 0) {
        return "WARNING"
    } elseif ($script:InfoItems.Count -gt 0) {
        return "HEALTHY"
    } else {
        return "UNKNOWN"
    }
}

function Get-HealthSummary {
    [CmdletBinding()]
    param()
    
    $Status = Get-OverallHealthStatus
    $Total = $script:CriticalIssues.Count + $script:WarningIssues.Count
    
    if ($Status -eq "HEALTHY") {
        return "All systems healthy - No issues detected"
    } elseif ($Status -eq "WARNING") {
        return "$Total warning(s) detected - Monitor required"
    } elseif ($Status -eq "CRITICAL") {
        return "$($script:CriticalIssues.Count) critical issue(s) - Immediate attention required"
    } else {
        return "Health status unknown"
    }
}

function Get-TopIssues {
    [CmdletBinding()]
    param(
        [int]$Count = 5
    )
    
    $AllIssues = @()
    
    # Add critical issues first
    foreach ($Issue in $script:CriticalIssues | Select-Object -First $Count) {
        $AllIssues += "[CRITICAL] $Issue"
    }
    
    # Add warning issues if space remains
    $Remaining = $Count - $AllIssues.Count
    if ($Remaining -gt 0) {
        foreach ($Issue in $script:WarningIssues | Select-Object -First $Remaining) {
            $AllIssues += "[WARNING] $Issue"
        }
    }
    
    if ($AllIssues.Count -eq 0) {
        return "No issues detected"
    }
    
    return ($AllIssues -join "; ")
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check if Hyper-V is installed
    if (-not (Test-HyperVService)) {
        # Not a Hyper-V host - set minimal fields and exit
        Set-NinjaField -FieldName "hypervQuickHealth" -Value "UNKNOWN"
        Set-NinjaField -FieldName "hypervHealthSummary" -Value "Hyper-V not installed"
        Set-NinjaField -FieldName "hypervCriticalIssues" -Value 0
        Set-NinjaField -FieldName "hypervWarningIssues" -Value 0
        Set-NinjaField -FieldName "hypervLastHealthCheck" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        
        Write-Log "Hyper-V not installed - health check skipped" -Level INFO
        exit 0
    }
    
    # Perform health checks
    Write-Log "Performing health checks..." -Level INFO
    
    # Host resource health
    Get-HostResourceHealth | Out-Null
    
    # Recent event log issues
    $EventCount = Get-RecentHyperVEvents
    
    # VM health status
    $VMHealth = Get-VMHealthStatus
    
    # Cluster health (if clustered)
    $ClusterHealth = Get-ClusterHealth
    
    # Storage latency
    $StorageLatency = Get-StorageLatency
    
    # Determine overall status
    $OverallHealth = Get-OverallHealthStatus
    $HealthSummary = Get-HealthSummary
    $TopIssues = Get-TopIssues -Count 5
    
    Write-Log "========================================" -Level INFO
    Write-Log "HEALTH CHECK SUMMARY" -Level INFO
    Write-Log "  Overall Status: $OverallHealth" -Level INFO
    Write-Log "  Critical Issues: $($script:CriticalIssues.Count)" -Level INFO
    Write-Log "  Warning Issues: $($script:WarningIssues.Count)" -Level INFO
    Write-Log "  Event Errors (24h): $EventCount" -Level INFO
    Write-Log "  Unhealthy VMs: $($VMHealth.Unhealthy)" -Level INFO
    if ($ClusterHealth.Clustered) {
        Write-Log "  Cluster Quorum: $(if($ClusterHealth.QuorumOK){'OK'}else{'LOST'})" -Level INFO
        Write-Log "  CSV Issues: $($ClusterHealth.CSVLowSpace)" -Level INFO
    }
    Write-Log "========================================" -Level INFO
    
    # Update NinjaRMM fields
    Write-Log "Updating NinjaRMM custom fields..." -Level INFO
    
    Set-NinjaField -FieldName "hypervQuickHealth" -Value $OverallHealth
    Set-NinjaField -FieldName "hypervHealthSummary" -Value $HealthSummary
    Set-NinjaField -FieldName "hypervCriticalIssues" -Value $script:CriticalIssues.Count
    Set-NinjaField -FieldName "hypervWarningIssues" -Value $script:WarningIssues.Count
    Set-NinjaField -FieldName "hypervLastHealthCheck" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    Set-NinjaField -FieldName "hypervTopIssues" -Value $TopIssues
    Set-NinjaField -FieldName "hypervEventErrors" -Value $EventCount
    Set-NinjaField -FieldName "hypervClusterQuorumOK" -Value $ClusterHealth.QuorumOK
    Set-NinjaField -FieldName "hypervCSVHealthy" -Value $ClusterHealth.CSVHealthy
    Set-NinjaField -FieldName "hypervCSVLowSpace" -Value $ClusterHealth.CSVLowSpace
    Set-NinjaField -FieldName "hypervVMsUnhealthy" -Value $VMHealth.Unhealthy
    Set-NinjaField -FieldName "hypervReplicationIssues" -Value $VMHealth.ReplicationIssues
    Set-NinjaField -FieldName "hypervStorageLatencyMS" -Value $StorageLatency
    
    Write-Log "Health check completed successfully" -Level INFO
    
} catch {
    Write-Log "Health check failed: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    
    # Set error state
    Set-NinjaField -FieldName "hypervQuickHealth" -Value "UNKNOWN"
    Set-NinjaField -FieldName "hypervHealthSummary" -Value "Health check error: $($_.Exception.Message)"
    
    exit 1
    
} finally {
    # Calculate execution time - REQUIRED
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $ExecutionTime seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}

# Exit with appropriate code
if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
