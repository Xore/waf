#Requires -Version 5.1

<#
.SYNOPSIS
    Detects wired Ethernet connections running slower than 1 Gbps

.DESCRIPTION
    Monitors physical Ethernet adapters and alerts when link speeds are below 1 Gbps.
    This script identifies devices connected to slow switches, hubs, or experiencing
    cable issues that prevent Gigabit speeds.
    
    The script performs the following:
    - Scans all physical network adapters (excludes virtual adapters)
    - Filters for wired Ethernet connections (802.3 media type)
    - Identifies active connections only (Status = Up)
    - Detects link speeds below 1 Gbps
    - Reports adapter details including name, description, status, and link speed
    - Optionally saves results to NinjaRMM custom fields
    - Exits with code 1 if slow connections found (alert condition)
    - Exits with code 0 if all connections are 1 Gbps or faster
    
    This script is useful for:
    - Identifying outdated network infrastructure
    - Detecting bad network cables or connectors
    - Compliance checking for minimum network standards
    - Performance troubleshooting
    
    This script runs unattended without user interaction.

.PARAMETER MinimumSpeedMbps
    Minimum acceptable link speed in Mbps.
    Default: 1000 (1 Gbps)

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save slow adapter information.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\Network-AlertWiredSub1Gbps.ps1
    
    Detects wired adapters slower than 1 Gbps and displays results to console.
    Exits with code 1 if slow adapters found, code 0 if all are 1 Gbps or faster.

.EXAMPLE
    .\Network-AlertWiredSub1Gbps.ps1 -MinimumSpeedMbps 2500
    
    Detects wired adapters slower than 2.5 Gbps.

.EXAMPLE
    .\Network-AlertWiredSub1Gbps.ps1 -CustomFieldName "SlowNetworkStatus"
    
    Detects slow adapters and saves formatted results to specified custom field.

.OUTPUTS
    None. Network adapter information is written to console and optionally to custom field.

.NOTES
    Script Name:    Network-AlertWiredSub1Gbps.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or User
    Execution Frequency: On-demand or scheduled (e.g., daily)
    Typical Duration: ~1-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName (if specified) - Formatted slow adapter information
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Get-NetAdapter cmdlet (built-in)
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - minimumSpeedMbps: Alternative to -MinimumSpeedMbps parameter
        - customFieldName: Alternative to -CustomFieldName parameter
    
    Exit Codes:
        0 - Success (all wired adapters are at minimum speed or faster)
        1 - Alert (one or more wired adapters below minimum speed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Minimum acceptable link speed in Mbps")]
    [ValidateRange(1, 100000)]
    [int]$MinimumSpeedMbps = 1000,
    
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save slow adapter information")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Network-AlertWiredSub1Gbps"

# Support NinjaRMM environment variables
if ($env:minimumSpeedMbps -and $env:minimumSpeedMbps -notlike "null") {
    $MinimumSpeedMbps = [int]$env:minimumSpeedMbps
}

if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

# Trim whitespace from parameter
if ($CustomFieldName) {
    $CustomFieldName = $CustomFieldName.Trim()
}

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$script:ExitCode = 0
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes structured log messages with plain text output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Plain text output only - no colors
    Write-Output $LogMessage
    
    # Track counts
    switch ($Level) {
        'WARN'  { $script:WarningCount++ }
        'ERROR' { $script:ErrorCount++ }
    }
}

function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value with automatic fallback to CLI
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    # Truncate if exceeds NinjaRMM field limit (10,000 characters)
    if ($ValueString.Length -gt 10000) {
        Write-Log "Field value exceeds 10,000 characters, truncating" -Level WARN
        $ValueString = $ValueString.Substring(0, 9950) + "`n... (truncated)"
    }
    
    # Method 1: Try Ninja-Property-Set cmdlet
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' set successfully" -Level DEBUG
            return
        } else {
            throw "Ninja-Property-Set cmdlet not available"
        }
    } catch {
        Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
        
        # Method 2: Try ninjarmm-cli.exe
        try {
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            $CLIArgs = @("set", $FieldName, $ValueString)
            $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "CLI exit code: $LASTEXITCODE, Output: $CLIResult"
            }
            
            Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
            $script:CLIFallbackCount++
            
        } catch {
            Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
        }
    }
}

function Format-Speed {
    <#
    .SYNOPSIS
        Converts link speed string to Mbps value
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SpeedString
    )
    
    try {
        # Handle Gbps speeds
        if ($SpeedString -match '([0-9.]+)\s*Gbps') {
            $SpeedGbps = [decimal]$matches[1]
            return [int]($SpeedGbps * 1000)
        }
        # Handle Mbps speeds
        elseif ($SpeedString -match '([0-9.]+)\s*Mbps') {
            return [int][decimal]$matches[1]
        }
        # Handle Kbps speeds
        elseif ($SpeedString -match '([0-9.]+)\s*Kbps') {
            $SpeedKbps = [decimal]$matches[1]
            return [int]($SpeedKbps / 1000)
        }
        # Default: return 0 if can't parse
        else {
            Write-Log "Could not parse speed: $SpeedString" -Level WARN
            return 0
        }
    } catch {
        Write-Log "Error parsing speed '$SpeedString': $_" -Level WARN
        return 0
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    Write-Log "Scanning for wired Ethernet adapters below $MinimumSpeedMbps Mbps..." -Level INFO
    
    # Query for physical network adapters
    $AllAdapters = Get-NetAdapter -ErrorAction Stop
    
    # Filter for wired Ethernet adapters that are connected
    $WiredAdapters = $AllAdapters | Where-Object {
        $_.Virtual -eq $false -and
        $_.Status -eq 'Up' -and
        ($_.PhysicalMediaType -like '*802.3*' -or $_.NdisPhysicalMedium -eq 14)
    }
    
    if (-not $WiredAdapters) {
        Write-Log "No active wired Ethernet adapters found" -Level INFO
        
        if ($CustomFieldName) {
            Set-NinjaField -FieldName $CustomFieldName -Value "No active wired adapters found"
        }
        
    } else {
        Write-Log "Found $(@($WiredAdapters).Count) active wired adapter(s)" -Level INFO
        Write-Log "" -Level INFO
        
        # Check for slow adapters
        $SlowAdapters = New-Object System.Collections.Generic.List[Object]
        
        foreach ($Adapter in $WiredAdapters) {
            $SpeedMbps = Format-Speed -SpeedString $Adapter.LinkSpeed
            
            Write-Log "Adapter: $($Adapter.Name)" -Level INFO
            Write-Log "  Description: $($Adapter.InterfaceDescription)" -Level INFO
            Write-Log "  Status: $($Adapter.Status)" -Level INFO
            Write-Log "  Link Speed: $($Adapter.LinkSpeed) ($SpeedMbps Mbps)" -Level INFO
            
            if ($SpeedMbps -lt $MinimumSpeedMbps) {
                Write-Log "  WARNING: Below minimum speed of $MinimumSpeedMbps Mbps" -Level WARN
                
                $SlowAdapters.Add([PSCustomObject]@{
                    Name = $Adapter.Name
                    Description = $Adapter.InterfaceDescription
                    Status = $Adapter.Status
                    LinkSpeed = $Adapter.LinkSpeed
                    SpeedMbps = $SpeedMbps
                    MacAddress = $Adapter.MacAddress
                    InterfaceIndex = $Adapter.InterfaceIndex
                })
            }
            
            Write-Log "" -Level INFO
        }
        
        # Report results
        if ($SlowAdapters.Count -gt 0) {
            Write-Log "ALERT: Found $($SlowAdapters.Count) wired adapter(s) below $MinimumSpeedMbps Mbps" -Level WARN
            
            # Build report
            $Report = New-Object System.Collections.Generic.List[String]
            $Report.Add("SLOW NETWORK ALERT - $($SlowAdapters.Count) adapter(s) below $MinimumSpeedMbps Mbps")
            $Report.Add("")
            
            $AdapterIndex = 1
            foreach ($Adapter in $SlowAdapters) {
                $Report.Add("Adapter $AdapterIndex of $($SlowAdapters.Count):")
                $Report.Add("  Name: $($Adapter.Name)")
                $Report.Add("  Description: $($Adapter.Description)")
                $Report.Add("  Link Speed: $($Adapter.LinkSpeed) ($($Adapter.SpeedMbps) Mbps)")
                $Report.Add("  MAC Address: $($Adapter.MacAddress)")
                $Report.Add("  Interface Index: $($Adapter.InterfaceIndex)")
                $Report.Add("")
                $AdapterIndex++
            }
            
            $Report.Add("Recommendation: Check network cables, switch ports, and adapter drivers")
            
            # Save to custom field if specified
            if ($CustomFieldName) {
                $FormattedReport = $Report -join "`n"
                Set-NinjaField -FieldName $CustomFieldName -Value $FormattedReport
                Write-Log "Results saved to custom field '$CustomFieldName'" -Level INFO
            }
            
            # Set exit code to 1 to indicate alert condition
            $script:ExitCode = 1
            
        } else {
            Write-Log "All wired adapters are at $MinimumSpeedMbps Mbps or faster" -Level SUCCESS
            
            # Save to custom field if specified
            if ($CustomFieldName) {
                Set-NinjaField -FieldName $CustomFieldName -Value "All wired adapters at $MinimumSpeedMbps Mbps or faster"
                Write-Log "Status saved to custom field '$CustomFieldName'" -Level INFO
            }
        }
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    $script:ExitCode = 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    Write-Log "  Exit Code: $script:ExitCode" -Level INFO
    Write-Log "========================================" -Level INFO
    
    exit $script:ExitCode
}
