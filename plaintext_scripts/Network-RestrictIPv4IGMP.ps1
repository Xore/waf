#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configures IPv4 IGMP (Internet Group Management Protocol) level

.DESCRIPTION
    Manages IPv4 IGMP (multicast) settings for the system, controlling whether
    the computer can send and receive multicast traffic. IGMP is used for efficient
    distribution of streaming media and other one-to-many communications.
    
    The script performs the following:
    - Validates administrator privileges
    - Checks current IGMP configuration
    - Applies the specified IGMP level
    - Verifies the configuration change
    - Optionally saves results to NinjaRMM custom fields
    
    IGMP Levels:
    - None: Disables sending and receiving IGMP packets (blocks multicast)
    - SendOnly: Allows sending IGMP but not receiving (partial multicast)
    - All: Enables full IGMP functionality (default, full multicast)
    
    This script is useful for:
    - Security hardening (disable unused protocols)
    - Troubleshooting multicast issues
    - Compliance requirements
    - Network performance optimization
    
    This script runs unattended without user interaction.

.PARAMETER IGMPLevel
    IGMP level to configure.
    Valid values: 'None', 'SendOnly', 'All'
    Default: 'None'

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save IGMP status.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\Network-RestrictIPv4IGMP.ps1
    
    Disables IGMP (sets to None) - recommended for security.

.EXAMPLE
    .\Network-RestrictIPv4IGMP.ps1 -IGMPLevel All
    
    Enables full IGMP functionality (restores default).

.EXAMPLE
    .\Network-RestrictIPv4IGMP.ps1 -IGMPLevel SendOnly
    
    Allows sending IGMP but blocks receiving multicast traffic.

.EXAMPLE
    .\Network-RestrictIPv4IGMP.ps1 -IGMPLevel None -CustomFieldName "IGMPStatus"
    
    Disables IGMP and saves status to 'IGMPStatus' custom field.

.OUTPUTS
    None. IGMP configuration is written to console and optionally to custom field.

.NOTES
    Script Name:    Network-RestrictIPv4IGMP.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required)
    Execution Frequency: On-demand or during security hardening
    Typical Duration: ~1-2 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required, changes apply immediately)
    
    Fields Updated:
        - CustomFieldName (if specified) - IGMP configuration status
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Windows 10, Windows Server 2016 or higher
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - igmpLevel: Alternative to -IGMPLevel parameter
        - customFieldName: Alternative to -CustomFieldName parameter
    
    Exit Codes:
        0 - Success (IGMP configured successfully)
        1 - Failure (configuration failed or access denied)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/en-us/powershell/module/nettcpip/set-netipv4protocol
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="IGMP level: None, SendOnly, or All")]
    [ValidateSet('None','SendOnly','All')]
    [string]$IGMPLevel = 'None',
    
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save IGMP status")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Network-RestrictIPv4IGMP"

# Support NinjaRMM environment variables
if ($env:igmpLevel -and $env:igmpLevel -notlike "null") {
    $IGMPLevel = $env:igmpLevel
}

if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

# Trim whitespace from parameters
if ($CustomFieldName) { $CustomFieldName = $CustomFieldName.Trim() }

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

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for administrator privileges
    if (-not (Test-IsElevated)) {
        Write-Log "ERROR: This script requires administrator privileges" -Level ERROR
        throw "Access Denied"
    }
    
    Write-Log "Configuring IPv4 IGMP level to: $IGMPLevel" -Level INFO
    Write-Log "" -Level INFO
    
    # Get current IGMP configuration
    Write-Log "Retrieving current IGMP configuration..." -Level INFO
    $BeforeConfig = Get-NetIPv4Protocol -ErrorAction Stop
    $BeforeLevel = $BeforeConfig.IGMPLevel
    
    Write-Log "Current IGMP Level: $BeforeLevel" -Level INFO
    
    # Check if change is needed
    if ($BeforeLevel -eq $IGMPLevel) {
        Write-Log "IGMP is already set to '$IGMPLevel' - no change needed" -Level INFO
        
        if ($CustomFieldName) {
            Set-NinjaField -FieldName $CustomFieldName -Value "IGMP Level: $IGMPLevel (no change needed)"
        }
        
    } else {
        # Apply new IGMP level
        Write-Log "Changing IGMP level from '$BeforeLevel' to '$IGMPLevel'..." -Level INFO
        
        Set-NetIPv4Protocol -IGMPLevel $IGMPLevel -ErrorAction Stop
        
        # Verify the change
        $AfterConfig = Get-NetIPv4Protocol -ErrorAction Stop
        $AfterLevel = $AfterConfig.IGMPLevel
        
        Write-Log "New IGMP Level: $AfterLevel" -Level INFO
        
        if ($AfterLevel -eq $IGMPLevel) {
            Write-Log "IGMP level changed successfully!" -Level SUCCESS
            
            # Build status message
            $StatusMessage = "IGMP Level changed from '$BeforeLevel' to '$AfterLevel'"
            
            # Add security note for None level
            if ($IGMPLevel -eq 'None') {
                $StatusMessage += " (Multicast disabled for security)"
            }
            
            if ($CustomFieldName) {
                Set-NinjaField -FieldName $CustomFieldName -Value $StatusMessage
            }
        } else {
            Write-Log "WARNING: IGMP level is '$AfterLevel' but expected '$IGMPLevel'" -Level WARN
            $script:ExitCode = 1
        }
    }
    
    # Display IGMP level descriptions
    Write-Log "" -Level INFO
    Write-Log "IGMP Level Descriptions:" -Level INFO
    Write-Log "  None     - Disables sending and receiving IGMP (blocks multicast)" -Level INFO
    Write-Log "  SendOnly - Allows sending IGMP but not receiving" -Level INFO
    Write-Log "  All      - Enables full IGMP functionality (default)" -Level INFO
    
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
