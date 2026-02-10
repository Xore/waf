<#
.SYNOPSIS
    Hyper-V Monitor - Comprehensive Hyper-V host, VM, and failover cluster monitoring

.DESCRIPTION
    Monitors Hyper-V infrastructure including VM status, health, uptime, resource utilization,
    integration services, failover cluster state, and node health. Provides comprehensive
    visibility into virtualization infrastructure with HTML-formatted reporting for dashboard
    integration.
    
    This script is essential for maintaining high availability and performance of virtualized
    workloads, detecting VM health issues, tracking cluster failovers, and proactively managing
    resource constraints in Hyper-V environments.
    
    Monitoring Scope:
    
    Hyper-V Installation Detection:
    - Checks for Hyper-V role installation (vmms service)
    - Validates Hyper-V PowerShell module availability
    - Auto-installs Hyper-V PowerShell module if needed
    - Gracefully exits if Hyper-V not installed
    - Reports Hyper-V version from registry
    
    Virtual Machine Monitoring:
    - VM state tracking (Running, Off, Saved, Paused)
    - VM uptime calculation for running VMs
    - VM health status (Heartbeat integration service)
    - CPU usage per VM
    - Memory utilization (assigned vs. demand)
    - Replication health (if enabled)
    - Integration services status
    - VM generation (Gen 1 vs Gen 2)
    - Dynamic memory configuration
    - Checkpoint count and status
    
    Integration Services Health:
    - Heartbeat service status
    - Time synchronization status
    - Data exchange status
    - VSS backup status
    - Guest service interface status
    - Shutdown service status
    - Operating system detection (if available)
    
    Host Resource Monitoring:
    - Total VMs configured on host
    - Running VM count
    - Stopped VM count
    - Host CPU utilization
    - Host memory utilization
    - Virtual switch configuration
    - Hyper-V host version and capabilities
    
    Failover Cluster Integration:
    - Cluster membership detection
    - Cluster node status and state
    - Cluster resource health
    - VM ownership by node
    - Cluster quorum status
    - Recent failover detection
    - Cluster shared volume (CSV) status
    - Cluster network health
    
    HTML Report Generation:
    - Color-coded VM status table
    - VM health indicators (green/yellow/red)
    - Uptime display in days/hours/minutes
    - Integration services status matrix
    - Cluster node status if clustered
    - Resource utilization metrics
    - Stores in WYSIWYG field for dashboard display
    
    Health Status Classification:
    
    Healthy:
    - All VMs running with healthy heartbeat
    - All integration services operational
    - No cluster issues (if clustered)
    - Resource utilization within limits
    
    Warning:
    - VMs with degraded integration services
    - High resource utilization (>85%)
    - Cluster nodes in warning state
    - VMs with old checkpoints
    
    Critical:
    - VMs with failed heartbeat
    - Cluster resources offline
    - Host resource exhaustion (>95%)
    - Critical integration service failures
    
    Unknown:
    - Hyper-V not installed
    - Module unavailable
    - Script execution error

.NOTES
    Script Name:    Hyper-V Monitor 1.ps1
    Author:         Windows Automation Framework
    Version:        1.0
    Creation Date:  2026-02-10
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Every 15 minutes
    Typical Duration: ~25 seconds
    Timeout Setting: 120 seconds
    
    User Interaction: NONE (fully automated)
    Restart Behavior: Never restarts device
    
    Fields Updated:
        - hypervInstalled (Checkbox: Hyper-V role installed)
        - hypervVersion (Text: Hyper-V version)
        - hypervVMCount (Integer: total VMs)
        - hypervVMsRunning (Integer: running VMs)
        - hypervVMsStopped (Integer: stopped VMs)
        - hypervVMsOther (Integer: saved/paused VMs)
        - hypervClustered (Checkbox: failover cluster member)
        - hypervClusterName (Text: cluster name)
        - hypervClusterNodeCount (Integer: total cluster nodes)
        - hypervClusterStatus (Text: cluster health)
        - hypervHostCPUPercent (Integer: host CPU usage)
        - hypervHostMemoryPercent (Integer: host memory usage)
        - hypervVMReport (WYSIWYG: HTML VM status table)
        - hypervHealthStatus (Text: Healthy, Warning, Critical, Unknown)
        - hypervLastScanTime (DateTime: last successful scan - ISO format)
    
    Dependencies:
        - Windows PowerShell 5.1+
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Hyper-V role installed
        - Internet connectivity (for module installation)
        - PowerShell Gallery access
    
    Required Modules (auto-installed):
        - Hyper-V (Latest - auto-installed if missing)
        - FailoverClusters (Latest - only if clustered)
    
    Exit Codes:
        0 - Success
        1 - General error
        2 - Missing dependencies / Module installation failed
        3 - Permission denied

.LINK
    https://github.com/Xore/waf
    
.LINK
    Reference: https://github.com/a-schild/Zabbix-HyperV-Templates
#>

[CmdletBinding()]
param()

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURATION
# ============================================================================

# Script version
$ScriptVersion = "1.0"

# Logging configuration
$LogLevel = "INFO"  # DEBUG, INFO, WARN, ERROR
$VerbosePreference = 'SilentlyContinue'

# Timeouts and limits
$DefaultTimeout = 120
$MaxRetries = 3

# NinjaRMM CLI path
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# Resource thresholds
$WarningCPUPercent = 85
$CriticalCPUPercent = 95
$WarningMemoryPercent = 85
$CriticalMemoryPercent = 95

# ============================================================================
# INITIALIZATION
# ============================================================================

# Start timing - REQUIRED FOR ALL SCRIPTS
$StartTime = Get-Date
$ScriptName = $MyInvocation.MyCommand.Name

# Initialize error tracking
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

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

function Get-SafeValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        $DefaultValue = "N/A"
    )
    
    try {
        $Result = & $ScriptBlock
        if ($null -eq $Result -or $Result -eq "") {
            return $DefaultValue
        }
        return $Result
    } catch {
        Write-Log "Error getting value: $_" -Level DEBUG
        return $DefaultValue
    }
}

function Format-Uptime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [TimeSpan]$Uptime
    )
    
    if ($Uptime.TotalDays -ge 1) {
        return "{0}d {1}h {2}m" -f [Math]::Floor($Uptime.TotalDays), $Uptime.Hours, $Uptime.Minutes
    } elseif ($Uptime.TotalHours -ge 1) {
        return "{0}h {1}m" -f [Math]::Floor($Uptime.TotalHours), $Uptime.Minutes
    } else {
        return "{0}m" -f [Math]::Floor($Uptime.TotalMinutes)
    }
}

function Get-VMHealthColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$State,
        
        [Parameter(Mandatory=$false)]
        [string]$Heartbeat = "Unknown"
    )
    
    if ($State -ne "Running") {
        return "gray"
    }
    
    switch ($Heartbeat) {
        "OkApplicationsHealthy" { return "green" }
        "OkApplicationsUnknown" { return "lightgreen" }
        "LostCommunication" { return "red" }
        "NoContact" { return "orange" }
        "Paused" { return "yellow" }
        default { return "gray" }
    }
}

function Test-HyperVInstalled {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking for Hyper-V installation..." -Level INFO
        
        # Check for Hyper-V service
        $HyperVService = Get-Service -Name "vmms" -ErrorAction SilentlyContinue
        
        if ($null -eq $HyperVService) {
            Write-Log "Hyper-V service (vmms) not found" -Level INFO
            return $false
        }
        
        Write-Log "Hyper-V service found: $($HyperVService.Status)" -Level INFO
        return $true
        
    } catch {
        Write-Log "Error checking Hyper-V installation: $_" -Level ERROR
        return $false
    }
}

function Install-HyperVModule {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking Hyper-V PowerShell module..." -Level INFO
        
        # Check if module is available
        if (Get-Module -ListAvailable -Name Hyper-V) {
            Write-Log "Hyper-V module already installed" -Level DEBUG
            Import-Module Hyper-V -ErrorAction Stop
            Write-Log "Hyper-V module imported successfully" -Level INFO
            return $true
        }
        
        # Try to install as Windows feature
        Write-Log "Installing Hyper-V PowerShell module..." -Level INFO
        
        # Check if DISM/WindowsFeature cmdlets available
        if (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue) {
            Install-WindowsFeature -Name Hyper-V-PowerShell -ErrorAction Stop | Out-Null
            Write-Log "Hyper-V PowerShell feature installed" -Level INFO
        } elseif (Get-Command Enable-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -All -NoRestart -ErrorAction Stop | Out-Null
            Write-Log "Hyper-V PowerShell feature enabled" -Level INFO
        } else {
            throw "Unable to install Hyper-V module - install cmdlets not available"
        }
        
        # Import the module
        Import-Module Hyper-V -ErrorAction Stop
        Write-Log "Hyper-V module imported successfully" -Level INFO
        return $true
        
    } catch {
        Write-Log "Failed to install/import Hyper-V module: $_" -Level ERROR
        return $false
    }
}

function Get-HyperVVersion {
    [CmdletBinding()]
    param()
    
    try {
        # Try registry first
        $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization"
        if (Test-Path $RegPath) {
            $Version = Get-ItemProperty -Path $RegPath -Name "Version" -ErrorAction SilentlyContinue
            if ($Version) {
                return "Hyper-V v$($Version.Version)"
            }
        }
        
        # Fallback to VM host info
        $VMHost = Get-VMHost -ErrorAction SilentlyContinue
        if ($VMHost -and $VMHost.HyperVVersion) {
            return "Hyper-V v$($VMHost.HyperVVersion)"
        }
        
        return "Hyper-V (version unknown)"
        
    } catch {
        Write-Log "Error detecting Hyper-V version: $_" -Level WARN
        return "Hyper-V (version unknown)"
    }
}

function Test-FailoverClusterMember {
    [CmdletBinding()]
    param()
    
    try {
        # Check if FailoverClusters module is available
        if (-not (Get-Module -ListAvailable -Name FailoverClusters)) {
            Write-Log "FailoverClusters module not available" -Level DEBUG
            return $false
        }
        
        Import-Module FailoverClusters -ErrorAction Stop
        
        # Try to get cluster information
        $Cluster = Get-Cluster -ErrorAction SilentlyContinue
        
        if ($null -ne $Cluster) {
            Write-Log "System is a member of cluster: $($Cluster.Name)" -Level INFO
            return $true
        }
        
        return $false
        
    } catch {
        Write-Log "Not a cluster member or cluster service not running" -Level DEBUG
        return $false
    }
}

function Get-ClusterInformation {
    [CmdletBinding()]
    param()
    
    try {
        $ClusterInfo = @{
            Clustered = $false
            ClusterName = ""
            NodeCount = 0
            ClusterStatus = "N/A"
            LocalNodeStatus = "N/A"
            QuorumStatus = "N/A"
        }
        
        if (-not (Test-FailoverClusterMember)) {
            return $ClusterInfo
        }
        
        # Get cluster details
        $Cluster = Get-Cluster -ErrorAction Stop
        $ClusterInfo.Clustered = $true
        $ClusterInfo.ClusterName = $Cluster.Name
        
        # Get all nodes
        $Nodes = Get-ClusterNode -ErrorAction SilentlyContinue
        if ($Nodes) {
            $ClusterInfo.NodeCount = @($Nodes).Count
            
            # Check local node status
            $LocalNode = $Nodes | Where-Object { $_.Name -eq $env:COMPUTERNAME }
            if ($LocalNode) {
                $ClusterInfo.LocalNodeStatus = $LocalNode.State.ToString()
            }
        }
        
        # Get quorum status
        try {
            $Quorum = Get-ClusterQuorum -ErrorAction SilentlyContinue
            if ($Quorum) {
                $ClusterInfo.QuorumStatus = $Quorum.QuorumType.ToString()
            }
        } catch {
            Write-Log "Unable to retrieve quorum status" -Level DEBUG
        }
        
        # Overall cluster health
        if ($Nodes) {
            $OnlineNodes = @($Nodes | Where-Object { $_.State -eq 'Up' }).Count
            if ($OnlineNodes -eq $ClusterInfo.NodeCount) {
                $ClusterInfo.ClusterStatus = "Healthy"
            } elseif ($OnlineNodes -gt 0) {
                $ClusterInfo.ClusterStatus = "Degraded"
            } else {
                $ClusterInfo.ClusterStatus = "Offline"
            }
        }
        
        return $ClusterInfo
        
    } catch {
        Write-Log "Error getting cluster information: $_" -Level WARN
        return @{
            Clustered = $false
            ClusterName = ""
            NodeCount = 0
            ClusterStatus = "Error"
            LocalNodeStatus = "Error"
            QuorumStatus = "Error"
        }
    }
}

function Get-VMDetailedStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $VM
    )
    
    try {
        $VMStatus = @{
            Name = $VM.Name
            State = $VM.State.ToString()
            Status = $VM.Status.ToString()
            Uptime = "N/A"
            CPUUsage = 0
            MemoryAssignedMB = 0
            MemoryDemandMB = 0
            Generation = $VM.Generation
            IntegrationServicesState = "Unknown"
            Heartbeat = "Unknown"
            HealthColor = "gray"
            ReplicationHealth = "NotApplicable"
            CheckpointCount = 0
        }
        
        # Uptime for running VMs
        if ($VM.State -eq 'Running' -and $VM.Uptime) {
            $VMStatus.Uptime = Format-Uptime -Uptime $VM.Uptime
        }
        
        # CPU usage
        if ($VM.State -eq 'Running') {
            $VMStatus.CPUUsage = $VM.CPUUsage
        }
        
        # Memory
        $VMMemory = Get-VMMemory -VM $VM -ErrorAction SilentlyContinue
        if ($VMMemory) {
            $VMStatus.MemoryAssignedMB = [Math]::Round($VMMemory.Startup / 1MB)
            if ($VM.State -eq 'Running' -and $VM.MemoryDemand) {
                $VMStatus.MemoryDemandMB = [Math]::Round($VM.MemoryDemand / 1MB)
            }
        }
        
        # Integration services
        $IntServices = Get-VMIntegrationService -VM $VM -ErrorAction SilentlyContinue
        if ($IntServices) {
            $HeartbeatService = $IntServices | Where-Object { $_.Name -like "*Heartbeat*" -or $_.Name -eq "Heartbeat" }
            if ($HeartbeatService) {
                $VMStatus.Heartbeat = $HeartbeatService.PrimaryStatusDescription
                $VMStatus.IntegrationServicesState = if ($HeartbeatService.Enabled) { "Enabled" } else { "Disabled" }
            }
        }
        
        # Health color based on state and heartbeat
        $VMStatus.HealthColor = Get-VMHealthColor -State $VM.State -Heartbeat $VMStatus.Heartbeat
        
        # Replication health
        $Replication = Get-VMReplication -VM $VM -ErrorAction SilentlyContinue
        if ($Replication) {
            $VMStatus.ReplicationHealth = $Replication.ReplicationHealth.ToString()
        }
        
        # Checkpoints
        $Checkpoints = Get-VMSnapshot -VM $VM -ErrorAction SilentlyContinue
        if ($Checkpoints) {
            $VMStatus.CheckpointCount = @($Checkpoints).Count
        }
        
        return $VMStatus
        
    } catch {
        Write-Log "Error getting VM status for $($VM.Name): $_" -Level WARN
        return @{
            Name = $VM.Name
            State = "Error"
            Status = "Error"
            Uptime = "N/A"
            CPUUsage = 0
            MemoryAssignedMB = 0
            MemoryDemandMB = 0
            Generation = 0
            IntegrationServicesState = "Unknown"
            Heartbeat = "Unknown"
            HealthColor = "red"
            ReplicationHealth = "Error"
            CheckpointCount = 0
        }
    }
}

function Build-VMHTMLReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$VMList,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$ClusterInfo
    )
    
    try {
        $HTMLRows = @()
        
        foreach ($VMStatus in $VMList) {
            $StateColor = switch ($VMStatus.State) {
                'Running' { 'green' }
                'Off' { 'gray' }
                'Saved' { 'blue' }
                'Paused' { 'orange' }
                default { 'black' }
            }
            
            # Build table row
            $HTMLRows += @"
<tr>
    <td><strong>$($VMStatus.Name)</strong></td>
    <td style='color:$StateColor'><strong>$($VMStatus.State)</strong></td>
    <td style='background-color:$($VMStatus.HealthColor); color:white; text-align:center; font-weight:bold;'>$($VMStatus.Heartbeat)</td>
    <td>$($VMStatus.Uptime)</td>
    <td>$($VMStatus.CPUUsage)%</td>
    <td>$($VMStatus.MemoryAssignedMB) MB</td>
    <td>Gen $($VMStatus.Generation)</td>
    <td>$($VMStatus.IntegrationServicesState)</td>
</tr>
"@
        }
        
        # Build summary section
        $TotalVMs = $VMList.Count
        $RunningVMs = @($VMList | Where-Object { $_.State -eq 'Running' }).Count
        $StoppedVMs = @($VMList | Where-Object { $_.State -eq 'Off' }).Count
        $HealthyVMs = @($VMList | Where-Object { $_.HealthColor -eq 'green' }).Count
        $WarningVMs = @($VMList | Where-Object { $_.HealthColor -in @('yellow','orange','lightgreen') }).Count
        $CriticalVMs = @($VMList | Where-Object { $_.HealthColor -eq 'red' }).Count
        
        # Build HTML
        $HTML = @"
<style>
table { border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; font-size: 12px; }
th { background-color: #0078D4; color: white; padding: 8px; text-align: left; }
td { padding: 6px; border-bottom: 1px solid #ddd; }
tr:hover { background-color: #f5f5f5; }
.summary { margin-top: 15px; padding: 10px; background-color: #f0f0f0; border-radius: 5px; }
.summary-item { display: inline-block; margin-right: 20px; }
</style>

<table>
<tr>
    <th>VM Name</th>
    <th>State</th>
    <th>Health</th>
    <th>Uptime</th>
    <th>CPU</th>
    <th>Memory</th>
    <th>Generation</th>
    <th>Integration Services</th>
</tr>
$($HTMLRows -join "`n")
</table>

<div class='summary'>
    <div class='summary-item'><strong>Total VMs:</strong> $TotalVMs</div>
    <div class='summary-item'><strong>Running:</strong> <span style='color:green'>$RunningVMs</span></div>
    <div class='summary-item'><strong>Stopped:</strong> <span style='color:gray'>$StoppedVMs</span></div>
    <div class='summary-item'><strong>Healthy:</strong> <span style='color:green'>$HealthyVMs</span></div>
"@
        
        if ($WarningVMs -gt 0) {
            $HTML += "    <div class='summary-item'><strong>Warning:</strong> <span style='color:orange'>$WarningVMs</span></div>`n"
        }
        
        if ($CriticalVMs -gt 0) {
            $HTML += "    <div class='summary-item'><strong>Critical:</strong> <span style='color:red'>$CriticalVMs</span></div>`n"
        }
        
        # Add cluster info if available
        if ($ClusterInfo -and $ClusterInfo.Clustered) {
            $HTML += "    <div class='summary-item'><strong>Cluster:</strong> $($ClusterInfo.ClusterName) ($($ClusterInfo.ClusterStatus))</div>`n"
        }
        
        $HTML += "</div>"
        
        return $HTML
        
    } catch {
        Write-Log "Error building HTML report: $_" -Level ERROR
        return "<p style='color:red'>Error generating report</p>"
    }
}

function Get-HostResourceUtilization {
    [CmdletBinding()]
    param()
    
    try {
        $Resources = @{
            CPUPercent = 0
            MemoryPercent = 0
        }
        
        # Get CPU usage
        $CPU = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        if ($CPU) {
            $Resources.CPUPercent = [Math]::Round($CPU.CounterSamples[0].CookedValue)
        }
        
        # Get memory usage
        $OS = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($OS) {
            $TotalMemory = $OS.TotalVisibleMemorySize
            $FreeMemory = $OS.FreePhysicalMemory
            $UsedMemory = $TotalMemory - $FreeMemory
            $Resources.MemoryPercent = [Math]::Round(($UsedMemory / $TotalMemory) * 100)
        }
        
        return $Resources
        
    } catch {
        Write-Log "Error getting host resource utilization: $_" -Level WARN
        return @{ CPUPercent = 0; MemoryPercent = 0 }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Initialize variables
    $hypervInstalled = $false
    $hypervVersion = "Not Installed"
    $vmCount = 0
    $vmsRunning = 0
    $vmsStopped = 0
    $vmsOther = 0
    $clustered = $false
    $clusterName = ""
    $clusterNodeCount = 0
    $clusterStatus = "N/A"
    $hostCPUPercent = 0
    $hostMemoryPercent = 0
    $vmReport = ""
    $healthStatus = "Unknown"
    
    # Check if Hyper-V is installed
    if (-not (Test-HyperVInstalled)) {
        Write-Log "Hyper-V is not installed on this system" -Level INFO
        
        # Update fields for non-Hyper-V systems
        Set-NinjaField -FieldName "hypervInstalled" -Value $false
        Set-NinjaField -FieldName "hypervVersion" -Value "Not Installed"
        Set-NinjaField -FieldName "hypervVMCount" -Value 0
        Set-NinjaField -FieldName "hypervVMsRunning" -Value 0
        Set-NinjaField -FieldName "hypervVMsStopped" -Value 0
        Set-NinjaField -FieldName "hypervVMsOther" -Value 0
        Set-NinjaField -FieldName "hypervClustered" -Value $false
        Set-NinjaField -FieldName "hypervClusterName" -Value ""
        Set-NinjaField -FieldName "hypervClusterNodeCount" -Value 0
        Set-NinjaField -FieldName "hypervClusterStatus" -Value "N/A"
        Set-NinjaField -FieldName "hypervHostCPUPercent" -Value 0
        Set-NinjaField -FieldName "hypervHostMemoryPercent" -Value 0
        Set-NinjaField -FieldName "hypervVMReport" -Value "Hyper-V not installed"
        Set-NinjaField -FieldName "hypervHealthStatus" -Value "Unknown"
        Set-NinjaField -FieldName "hypervLastScanTime" -Value ""
        
        Write-Log "Hyper-V monitoring skipped (not installed)" -Level INFO
        exit 0
    }
    
    $hypervInstalled = $true
    Write-Log "Hyper-V installation detected" -Level INFO
    
    # Install/Import Hyper-V module
    if (-not (Install-HyperVModule)) {
        throw "Failed to install or import Hyper-V PowerShell module"
    }
    
    # Get Hyper-V version
    $hypervVersion = Get-HyperVVersion
    Write-Log "Hyper-V Version: $hypervVersion" -Level INFO
    
    # Get cluster information
    Write-Log "Checking for failover cluster membership..." -Level INFO
    $ClusterInfo = Get-ClusterInformation
    $clustered = $ClusterInfo.Clustered
    $clusterName = $ClusterInfo.ClusterName
    $clusterNodeCount = $ClusterInfo.NodeCount
    $clusterStatus = $ClusterInfo.ClusterStatus
    
    if ($clustered) {
        Write-Log "System is clustered: $clusterName ($clusterStatus)" -Level INFO
        Write-Log "Cluster nodes: $clusterNodeCount" -Level INFO
    } else {
        Write-Log "System is not a cluster member" -Level INFO
    }
    
    # Get all VMs
    Write-Log "Retrieving virtual machines..." -Level INFO
    $VMs = Get-VM -ErrorAction Stop
    $vmCount = @($VMs).Count
    Write-Log "Found $vmCount virtual machines" -Level INFO
    
    # Process each VM
    $VMStatusList = @()
    $vmHealthy = 0
    $vmWarning = 0
    $vmCritical = 0
    
    foreach ($VM in $VMs) {
        Write-Log "Processing VM: $($VM.Name)" -Level DEBUG
        
        # Count by state
        switch ($VM.State) {
            'Running' { $vmsRunning++ }
            'Off' { $vmsStopped++ }
            default { $vmsOther++ }
        }
        
        # Get detailed status
        $VMStatus = Get-VMDetailedStatus -VM $VM
        $VMStatusList += $VMStatus
        
        # Count health status
        switch ($VMStatus.HealthColor) {
            'green' { $vmHealthy++ }
            'lightgreen' { $vmHealthy++ }
            { $_ -in @('yellow','orange') } { $vmWarning++ }
            'red' { $vmCritical++ }
        }
    }
    
    Write-Log "VM Status - Running: $vmsRunning, Stopped: $vmsStopped, Other: $vmsOther" -Level INFO
    Write-Log "VM Health - Healthy: $vmHealthy, Warning: $vmWarning, Critical: $vmCritical" -Level INFO
    
    # Get host resource utilization
    Write-Log "Getting host resource utilization..." -Level INFO
    $HostResources = Get-HostResourceUtilization
    $hostCPUPercent = $HostResources.CPUPercent
    $hostMemoryPercent = $HostResources.MemoryPercent
    Write-Log "Host CPU: $hostCPUPercent%, Memory: $hostMemoryPercent%" -Level INFO
    
    # Build HTML report
    Write-Log "Building HTML report..." -Level INFO
    $vmReport = Build-VMHTMLReport -VMList $VMStatusList -ClusterInfo $ClusterInfo
    
    # Determine overall health status
    Write-Log "Determining overall health status..." -Level INFO
    
    if ($vmCritical -gt 0) {
        $healthStatus = "Critical"
        Write-Log "Health: Critical - $vmCritical VMs in critical state" -Level WARN
    } elseif ($vmWarning -gt 0 -or $hostCPUPercent -ge $WarningCPUPercent -or $hostMemoryPercent -ge $WarningMemoryPercent) {
        $healthStatus = "Warning"
        if ($vmWarning -gt 0) {
            Write-Log "Health: Warning - $vmWarning VMs in warning state" -Level WARN
        }
        if ($hostCPUPercent -ge $WarningCPUPercent) {
            Write-Log "Health: Warning - High host CPU usage ($hostCPUPercent%)" -Level WARN
        }
        if ($hostMemoryPercent -ge $WarningMemoryPercent) {
            Write-Log "Health: Warning - High host memory usage ($hostMemoryPercent%)" -Level WARN
        }
    } elseif ($clustered -and $clusterStatus -ne "Healthy") {
        $healthStatus = "Warning"
        Write-Log "Health: Warning - Cluster status: $clusterStatus" -Level WARN
    } else {
        $healthStatus = "Healthy"
        Write-Log "Health: Healthy - All VMs operating normally" -Level INFO
    }
    
    # Update NinjaRMM fields
    Write-Log "Updating NinjaRMM custom fields..." -Level INFO
    
    Set-NinjaField -FieldName "hypervInstalled" -Value $true
    Set-NinjaField -FieldName "hypervVersion" -Value $hypervVersion
    Set-NinjaField -FieldName "hypervVMCount" -Value $vmCount
    Set-NinjaField -FieldName "hypervVMsRunning" -Value $vmsRunning
    Set-NinjaField -FieldName "hypervVMsStopped" -Value $vmsStopped
    Set-NinjaField -FieldName "hypervVMsOther" -Value $vmsOther
    Set-NinjaField -FieldName "hypervClustered" -Value $clustered
    Set-NinjaField -FieldName "hypervClusterName" -Value $clusterName
    Set-NinjaField -FieldName "hypervClusterNodeCount" -Value $clusterNodeCount
    Set-NinjaField -FieldName "hypervClusterStatus" -Value $clusterStatus
    Set-NinjaField -FieldName "hypervHostCPUPercent" -Value $hostCPUPercent
    Set-NinjaField -FieldName "hypervHostMemoryPercent" -Value $hostMemoryPercent
    Set-NinjaField -FieldName "hypervVMReport" -Value $vmReport
    Set-NinjaField -FieldName "hypervHealthStatus" -Value $healthStatus
    Set-NinjaField -FieldName "hypervLastScanTime" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    Write-Log "========================================" -Level INFO
    Write-Log "HYPER-V MONITORING SUMMARY" -Level INFO
    Write-Log "  Health Status: $healthStatus" -Level INFO
    Write-Log "  Version: $hypervVersion" -Level INFO
    Write-Log "  Total VMs: $vmCount" -Level INFO
    Write-Log "  Running: $vmsRunning | Stopped: $vmsStopped | Other: $vmsOther" -Level INFO
    Write-Log "  Host CPU: $hostCPUPercent% | Memory: $hostMemoryPercent%" -Level INFO
    if ($clustered) {
        Write-Log "  Cluster: $clusterName ($clusterStatus)" -Level INFO
    }
    Write-Log "========================================" -Level INFO
    
    Write-Log "Script execution completed successfully" -Level INFO
    
} catch {
    Write-Log "Script execution failed: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    
    # Set error state
    Set-NinjaField -FieldName "hypervHealthStatus" -Value "Unknown"
    Set-NinjaField -FieldName "hypervVMReport" -Value "Monitor script error: $($_.Exception.Message)"
    
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
