#Requires -Version 5.1

<#
.SYNOPSIS
    Discovers and reports network switch information using LLDP protocol

.DESCRIPTION
    Uses the Link Layer Discovery Protocol (LLDP) to discover information about
    network switches and devices connected to the local network interface.
    Requires the PSDiscoveryProtocol PowerShell module to capture and parse LLDP packets.
    
    The script performs the following:
    - Installs NuGet package provider if not present
    - Installs PSDiscoveryProtocol module if not present
    - Captures LLDP packets from the network interface
    - Filters out specific device types (e.g., Polycom phones)
    - Parses discovered device information
    - Reports switch details including model, port, VLAN, and management IP
    - Optionally saves results to NinjaRMM custom fields in HTML or JSON format
    
    LLDP information typically includes:
    - Switch manufacturer and model
    - Port number where device is connected
    - VLAN assignment
    - Management IP address of switch
    - System capabilities
    
    This script is useful for:
    - Network topology documentation
    - Switch port identification
    - VLAN verification
    - Network troubleshooting
    
    This script runs unattended without user interaction.

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save LLDP information.
    Default: 'lldpinfo'

.PARAMETER OutputFormat
    Format for custom field output.
    Valid values: 'HTML', 'JSON'
    Default: 'HTML'

.PARAMETER ExcludeDevicePattern
    Device name pattern to exclude from results (regex).
    Default: 'Polycom*' (Polycom phones)

.PARAMETER MaxRetries
    Maximum number of capture attempts if excluded devices are discovered.
    Default: 5

.EXAMPLE
    .\Network-GetLLDPInfo.ps1
    
    Captures LLDP information and saves HTML report to 'lldpinfo' custom field.

.EXAMPLE
    .\Network-GetLLDPInfo.ps1 -OutputFormat JSON -CustomFieldName "NetworkSwitch"
    
    Captures LLDP information and saves JSON report to 'NetworkSwitch' custom field.

.EXAMPLE
    .\Network-GetLLDPInfo.ps1 -ExcludeDevicePattern "Cisco.*" -MaxRetries 3
    
    Captures LLDP information, excludes Cisco devices, retries up to 3 times.

.OUTPUTS
    None. LLDP information is written to console and optionally to custom field.

.NOTES
    Script Name:    Network-GetLLDPInfo.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator
    Execution Frequency: On-demand or scheduled (e.g., daily)
    Typical Duration: ~10-30 seconds (includes module installation if needed)
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName (default: lldpinfo) - LLDP discovery results
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required for packet capture)
        - Internet access (for module installation)
        - PSDiscoveryProtocol module (auto-installed)
        - NuGet package provider (auto-installed)
        - LLDP-capable network switch
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - customFieldName: Alternative to -CustomFieldName parameter
        - outputFormat: Alternative to -OutputFormat parameter
        - excludeDevicePattern: Alternative to -ExcludeDevicePattern parameter
    
    Exit Codes:
        0 - Success (LLDP information captured)
        1 - Failure (error during capture or module installation)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://github.com/lahell/PSDiscoveryProtocol
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save LLDP information")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName = "lldpinfo",
    
    [Parameter(Mandatory=$false, HelpMessage="Output format for custom field")]
    [ValidateSet('HTML','JSON')]
    [string]$OutputFormat = "HTML",
    
    [Parameter(Mandatory=$false, HelpMessage="Device name pattern to exclude (regex)")]
    [string]$ExcludeDevicePattern = "Polycom*",
    
    [Parameter(Mandatory=$false, HelpMessage="Maximum capture retry attempts")]
    [ValidateRange(1,10)]
    [int]$MaxRetries = 5
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Network-GetLLDPInfo"

# Support NinjaRMM environment variables
if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

if ($env:outputFormat -and $env:outputFormat -notlike "null") {
    $OutputFormat = $env:outputFormat
}

if ($env:excludeDevicePattern -and $env:excludeDevicePattern -notlike "null") {
    $ExcludeDevicePattern = $env:excludeDevicePattern
}

# Trim whitespace from parameters
if ($CustomFieldName) { $CustomFieldName = $CustomFieldName.Trim() }
if ($ExcludeDevicePattern) { $ExcludeDevicePattern = $ExcludeDevicePattern.Trim() }

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

function Test-IsElevated {
    <#
    .SYNOPSIS
        Checks if script is running with administrator privileges
    #>
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-RequiredModule {
    <#
    .SYNOPSIS
        Installs required PowerShell modules
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    
    try {
        if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
            Write-Log "Installing module: $ModuleName" -Level INFO
            
            # Ensure NuGet provider is available
            if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
                Write-Log "Installing NuGet package provider" -Level INFO
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
            }
            
            # Install the module
            Install-Module -Name $ModuleName -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Log "Module '$ModuleName' installed successfully" -Level SUCCESS
        } else {
            Write-Log "Module '$ModuleName' already installed" -Level DEBUG
        }
    } catch {
        Write-Log "Failed to install module '$ModuleName': $($_.Exception.Message)" -Level ERROR
        throw
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for administrator privileges
    if (-not (Test-IsElevated)) {
        Write-Log "ERROR: This script requires administrator privileges for packet capture" -Level ERROR
        throw "Insufficient privileges"
    }
    
    # Set execution policy for this process
    Set-ExecutionPolicy Bypass -Scope Process -Force
    
    # Install required modules
    Write-Log "Checking required modules..." -Level INFO
    Install-RequiredModule -ModuleName "PSDiscoveryProtocol"
    
    # Import module
    Write-Log "Importing PSDiscoveryProtocol module..." -Level INFO
    Import-Module PSDiscoveryProtocol -Force -ErrorAction Stop
    
    # Capture LLDP packet with retry logic
    Write-Log "Capturing LLDP packets (max retries: $MaxRetries)..." -Level INFO
    $Attempt = 0
    $LLDPData = $null
    
    do {
        $Attempt++
        Write-Log "Capture attempt $Attempt of $MaxRetries" -Level INFO
        
        try {
            $Packet = Invoke-DiscoveryProtocolCapture -Type LLDP -TimeOut 10 -ErrorAction Stop
            
            if ($Packet) {
                $LLDPData = Get-DiscoveryProtocolData -Packet $Packet -ErrorAction Stop
                
                # Check if device should be excluded
                if ($ExcludeDevicePattern -and $LLDPData.Device -like $ExcludeDevicePattern) {
                    Write-Log "Device '$($LLDPData.Device)' matches exclusion pattern, retrying..." -Level WARN
                    $LLDPData = $null
                } else {
                    Write-Log "LLDP data captured successfully" -Level SUCCESS
                    break
                }
            } else {
                Write-Log "No LLDP packet received" -Level WARN
            }
        } catch {
            Write-Log "Capture attempt failed: $($_.Exception.Message)" -Level WARN
        }
        
        if ($Attempt -lt $MaxRetries) {
            Start-Sleep -Seconds 2
        }
        
    } while ($Attempt -lt $MaxRetries)
    
    # Process results
    if ($LLDPData) {
        Write-Log "" -Level INFO
        Write-Log "LLDP Information:" -Level INFO
        Write-Log "  Device: $($LLDPData.Device)" -Level INFO
        Write-Log "  Model: $($LLDPData.Model)" -Level INFO
        Write-Log "  Port: $($LLDPData.Port)" -Level INFO
        Write-Log "  VLAN: $($LLDPData.VLAN)" -Level INFO
        Write-Log "  Management IP: $($LLDPData.IPAddress)" -Level INFO
        
        # Format output based on requested format
        $OutputData = switch ($OutputFormat) {
            'HTML' {
                $LLDPData | ConvertTo-Html -Fragment
            }
            'JSON' {
                $LLDPData | ConvertTo-Json -Depth 3
            }
        }
        
        # Save to custom field
        if ($CustomFieldName) {
            Set-NinjaField -FieldName $CustomFieldName -Value $OutputData
            Write-Log "Results saved to custom field '$CustomFieldName' in $OutputFormat format" -Level INFO
        }
        
    } else {
        Write-Log "Failed to capture LLDP data after $MaxRetries attempts" -Level ERROR
        
        if ($CustomFieldName) {
            Set-NinjaField -FieldName $CustomFieldName -Value "LLDP capture failed after $MaxRetries attempts"
        }
        
        $script:ExitCode = 1
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
