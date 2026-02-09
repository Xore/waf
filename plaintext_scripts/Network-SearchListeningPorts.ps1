#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Searches for and reports on listening or established network ports

.DESCRIPTION
    Scans for open network ports in Listen or Established states and reports
    findings with detailed process information. Supports TCP and UDP protocols.
    
    The script performs the following:
    - Queries active TCP connections and UDP endpoints
    - Filters by specified ports or scans all ports
    - Identifies processes using each port
    - Reports port status (Listen/Established/None for UDP)
    - Optionally saves results to NinjaRMM custom field
    - Generates alerts for found ports
    
    This script runs unattended without user interaction.

.PARAMETER PortsToCheck
    Comma-separated list of ports to check. Supports ranges (e.g., "80,443,8000-8100").
    If not specified, scans all listening/established ports.
    Default: All ports

.PARAMETER CustomFieldName
    Name of NinjaRMM custom field to store results.
    Default: None (output to console only)

.EXAMPLE
    .\Network-SearchListeningPorts.ps1
    
    Scans all listening and established ports.

.EXAMPLE
    .\Network-SearchListeningPorts.ps1 -PortsToCheck "80,443"
    
    Checks only ports 80 and 443.

.EXAMPLE
    .\Network-SearchListeningPorts.ps1 -PortsToCheck "80,443,8000-8100" -CustomFieldName "openPorts"
    
    Checks specified ports and saves results to custom field.

.NOTES
    Script Name:    Network-SearchListeningPorts.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~2-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - [CustomFieldName] - Port scan results (if specified)
        - portScanStatus - Status (Success/NoPorts/Failed)
        - portScanCount - Number of ports found
        - portScanDate - Timestamp of scan
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Get-NetTCPConnection cmdlet
        - Get-NetUDPEndpoint cmdlet
        - Windows 10 or Server 2016 minimum
    
    Environment Variables (Optional):
        - portsToCheck: Override -PortsToCheck parameter
        - customFieldName: Override -CustomFieldName parameter
    
    Exit Codes:
        0 - Success (scan completed, with or without ports found)
        1 - Failure (invalid parameters or scan error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Ports to check (comma-separated, supports ranges)")]
    [string]$PortsToCheck,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field name to store results")]
    [string]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Network-SearchListeningPorts"

# Port range limits
$MinPort = 1
$MaxPort = 65535

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
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
        [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS','ALERT')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Write-Output $LogMessage
    
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
    
    # Check character limit
    if ($ValueString.Length -gt 10000) {
        $ValueString = $ValueString.Substring(0, 9997) + "..."
        Write-Log "Field value truncated to 10,000 characters" -Level WARN
    }
    
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

function Test-IsElevated {
    <#
    .SYNOPSIS
        Checks if script is running with Administrator privileges
    #>
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Expand-PortList {
    <#
    .SYNOPSIS
        Expands port list with ranges into individual port numbers
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PortString
    )
    
    try {
        # Remove whitespace
        $PortString = $PortString -replace '\s', ''
        
        # Split by comma and process each entry
        $Ports = $PortString -split ',' | ForEach-Object {
            $Entry = $_.Trim()
            
            if ($Entry -match '^(\d+)-(\d+)$') {
                # Range format: 8000-8100
                $Start = [int]$Matches[1]
                $End = [int]$Matches[2]
                
                if ($Start -gt $End) {
                    throw "Invalid range: $Entry (start must be less than end)"
                }
                
                Write-Log "Expanding port range: $Start-$End" -Level DEBUG
                $Start..$End
            }
            elseif ($Entry -match '^\d+$') {
                # Single port
                [int]$Entry
            }
            else {
                throw "Invalid port format: $Entry"
            }
        }
        
        # Validate port range
        $InvalidPorts = $Ports | Where-Object { $_ -lt $MinPort -or $_ -gt $MaxPort }
        if ($InvalidPorts) {
            throw "Ports must be between $MinPort and $MaxPort. Invalid: $($InvalidPorts -join ', ')"
        }
        
        return $Ports | Select-Object -Unique | Sort-Object
        
    } catch {
        throw "Failed to parse port list: $_"
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable overrides
    if ($env:portsToCheck -and $env:portsToCheck -notlike "null") {
        $PortsToCheck = $env:portsToCheck
        Write-Log "Using ports from environment: $PortsToCheck" -Level INFO
    }
    
    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomFieldName = $env:customFieldName
        Write-Log "Using custom field from environment: $CustomFieldName" -Level INFO
    }
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required to query network connections"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # Parse port list if specified
    $TargetPorts = $null
    if ($PortsToCheck) {
        Write-Log "Parsing port specification: $PortsToCheck" -Level INFO
        $TargetPorts = Expand-PortList -PortString $PortsToCheck
        Write-Log "Checking $($TargetPorts.Count) specific port(s)" -Level INFO
    } else {
        Write-Log "Scanning all listening/established ports" -Level INFO
    }
    
    # Query TCP connections
    Write-Log "Querying TCP connections" -Level DEBUG
    $TCPConnections = Get-NetTCPConnection | Select-Object @(
        'LocalAddress',
        'LocalPort',
        'State',
        @{Name = "Protocol"; Expression = { "TCP" }},
        'OwningProcess',
        @{Name = "Process"; Expression = { 
            try {
                (Get-Process -Id $_.OwningProcess -ErrorAction Stop).ProcessName
            } catch {
                "Unknown"
            }
        }}
    )
    
    Write-Log "Found $($TCPConnections.Count) TCP connections" -Level DEBUG
    
    # Query UDP endpoints
    Write-Log "Querying UDP endpoints" -Level DEBUG
    $UDPEndpoints = Get-NetUDPEndpoint | Select-Object @(
        'LocalAddress',
        'LocalPort',
        @{Name = "State"; Expression = { "None" }},
        @{Name = "Protocol"; Expression = { "UDP" }},
        'OwningProcess',
        @{Name = "Process"; Expression = { 
            try {
                (Get-Process -Id $_.OwningProcess -ErrorAction Stop).ProcessName
            } catch {
                "Unknown"
            }
        }}
    )
    
    Write-Log "Found $($UDPEndpoints.Count) UDP endpoints" -Level DEBUG
    
    # Combine and filter connections
    $AllConnections = @($TCPConnections) + @($UDPEndpoints)
    
    $FoundPorts = $AllConnections | Where-Object {
        # Filter by target ports if specified
        $PortMatch = if ($TargetPorts) { 
            $_.LocalPort -in $TargetPorts 
        } else { 
            $true 
        }
        
        # Filter by state
        $StateMatch = (
            ($_.Protocol -eq "TCP" -and ($_.State -eq "Listen" -or $_.State -eq "Established")) -or
            ($_.Protocol -eq "UDP")
        )
        
        $PortMatch -and $StateMatch
    } | Sort-Object LocalPort | Select-Object * -Unique
    
    # Report findings
    if (-not $FoundPorts -or $FoundPorts.Count -eq 0) {
        Write-Log "No ports found matching criteria" -Level INFO
        
        Set-NinjaField -FieldName "portScanStatus" -Value "NoPorts"
        Set-NinjaField -FieldName "portScanCount" -Value 0
        Set-NinjaField -FieldName "portScanDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
    } else {
        Write-Log "Found $($FoundPorts.Count) open port(s)" -Level SUCCESS
        
        # Generate detailed output
        $Results = foreach ($Port in $FoundPorts) {
            $Message = "Port: $($Port.LocalPort), PID: $($Port.OwningProcess), Protocol: $($Port.Protocol), State: $($Port.State), Local IP: $($Port.LocalAddress), Process: $($Port.Process)"
            Write-Log $Message -Level ALERT
            $Message
        }
        
        # Save to custom field if specified
        if ($CustomFieldName) {
            Write-Log "Saving results to custom field: $CustomFieldName" -Level INFO
            $ResultsText = $Results -join "`n"
            Set-NinjaField -FieldName $CustomFieldName -Value $ResultsText
            Write-Log "Results saved to custom field" -Level SUCCESS
        }
        
        Set-NinjaField -FieldName "portScanStatus" -Value "Success"
        Set-NinjaField -FieldName "portScanCount" -Value $FoundPorts.Count
        Set-NinjaField -FieldName "portScanDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    
    Write-Log "Port scan completed successfully" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "portScanStatus" -Value "Failed"
    Set-NinjaField -FieldName "portScanDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}

if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
