#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables or disables LLMNR (Link-Local Multicast Name Resolution)

.DESCRIPTION
    Configures LLMNR via local group policy registry settings. LLMNR is a protocol
    that allows name resolution without requiring a DNS server, but poses security
    risks as it can be exploited for man-in-the-middle attacks and credential theft.
    
    The script performs the following:
    - Validates administrator privileges
    - Checks current LLMNR configuration
    - Modifies the registry to enable or disable LLMNR
    - Verifies the configuration change
    - Optionally saves results to NinjaRMM custom fields
    
    Security Note:
    Disabling LLMNR is a common security hardening practice recommended by:
    - Microsoft security baselines
    - CIS Benchmarks
    - NIST guidelines
    
    LLMNR works by:
    - Broadcasting name resolution requests on the local network
    - Listening for responses from other computers
    - Responding to requests from other computers
    
    This script is useful for:
    - Security hardening
    - Compliance requirements (CIS, NIST, etc.)
    - Preventing LLMNR poisoning attacks
    - Network security policy enforcement
    
    This script runs unattended without user interaction.

.PARAMETER Enable
    Switch to enable LLMNR. If omitted, LLMNR will be disabled (default).

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save LLMNR status.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\Network-SetLLMNR.ps1
    
    Disables LLMNR (recommended for security).

.EXAMPLE
    .\Network-SetLLMNR.ps1 -Enable
    
    Enables LLMNR.

.EXAMPLE
    .\Network-SetLLMNR.ps1 -CustomFieldName "LLMNRStatus"
    
    Disables LLMNR and saves status to 'LLMNRStatus' custom field.

.OUTPUTS
    None. LLMNR configuration is written to console and optionally to custom field.

.NOTES
    Script Name:    Network-SetLLMNR.ps1
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
        - CustomFieldName (if specified) - LLMNR configuration status
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Windows 10, Windows Server 2016 or higher
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - action: Alternative to -Enable switch (values: "Enable LLMNR", "Disable LLMNR")
        - customFieldName: Alternative to -CustomFieldName parameter
    
    Registry Location:
        HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient\EnableMultiCast
        0 = Disabled (recommended)
        1 = Enabled
    
    Exit Codes:
        0 - Success (LLMNR configured successfully)
        1 - Failure (configuration failed or access denied)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc957991(v=ws.10)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Enable LLMNR (if omitted, LLMNR will be disabled)")]
    [switch]$Enable,
    
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save LLMNR status")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Network-SetLLMNR"

# Support NinjaRMM environment variables
if ($env:action -and $env:action -notlike "null") {
    switch ($env:action) {
        "Enable LLMNR"  { $Enable = $true }
        "Disable LLMNR" { $Enable = $false }
    }
}

if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

# Trim whitespace from parameters
if ($CustomFieldName) { $CustomFieldName = $CustomFieldName.Trim() }

# Registry configuration
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
$RegistryName = "EnableMultiCast"
$RegistryValue = if ($Enable) { 1 } else { 0 }

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

function Set-RegistryValue {
    <#
    .SYNOPSIS
        Sets a registry value with proper error handling
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        $Value,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DWord','QWord','String','ExpandedString','Binary','MultiString')]
        [string]$PropertyType = 'DWord'
    )
    
    try {
        # Create path if it doesn't exist
        if (-not (Test-Path -Path $Path)) {
            Write-Log "Creating registry path: $Path" -Level DEBUG
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Get current value
        $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
        
        if ($null -ne $CurrentValue) {
            # Update existing value
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -ErrorAction Stop
            Write-Log "Registry: $Path\$Name changed from $CurrentValue to $Value" -Level INFO
        } else {
            # Create new value
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction Stop | Out-Null
            Write-Log "Registry: $Path\$Name created with value $Value" -Level INFO
        }
        
        return $true
        
    } catch {
        Write-Log "Failed to set registry value $Path\$Name: $($_.Exception.Message)" -Level ERROR
        return $false
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
        Write-Log "ERROR: This script requires administrator privileges" -Level ERROR
        throw "Access Denied"
    }
    
    $Action = if ($Enable) { "Enabling" } else { "Disabling" }
    Write-Log "$Action LLMNR (Link-Local Multicast Name Resolution)..." -Level INFO
    Write-Log "" -Level INFO
    
    # Get current LLMNR configuration
    $CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $RegistryName -ErrorAction SilentlyContinue).$RegistryName
    
    if ($null -ne $CurrentValue) {
        $CurrentStatus = if ($CurrentValue -eq 1) { "Enabled" } else { "Disabled" }
        Write-Log "Current LLMNR status: $CurrentStatus (value: $CurrentValue)" -Level INFO
    } else {
        Write-Log "LLMNR registry value not found (using system default)" -Level INFO
    }
    
    # Check if change is needed
    if ($CurrentValue -eq $RegistryValue) {
        $Status = if ($Enable) { "enabled" } else { "disabled" }
        Write-Log "LLMNR is already $Status - no change needed" -Level INFO
        
        if ($CustomFieldName) {
            Set-NinjaField -FieldName $CustomFieldName -Value "LLMNR: $Status (no change needed)"
        }
        
    } else {
        # Apply new LLMNR configuration
        $Success = Set-RegistryValue -Path $RegistryPath -Name $RegistryName -Value $RegistryValue -PropertyType DWord
        
        if ($Success) {
            # Verify the change
            $NewValue = (Get-ItemProperty -Path $RegistryPath -Name $RegistryName -ErrorAction SilentlyContinue).$RegistryName
            $NewStatus = if ($NewValue -eq 1) { "Enabled" } else { "Disabled" }
            
            Write-Log "" -Level INFO
            Write-Log "New LLMNR status: $NewStatus (value: $NewValue)" -Level INFO
            
            if ($NewValue -eq $RegistryValue) {
                Write-Log "LLMNR configuration changed successfully!" -Level SUCCESS
                
                # Build status message
                $StatusMessage = "LLMNR: $NewStatus"
                
                # Add security note for disabled state
                if (-not $Enable) {
                    $StatusMessage += " (Security hardening applied)"
                }
                
                if ($CustomFieldName) {
                    Set-NinjaField -FieldName $CustomFieldName -Value $StatusMessage
                }
            } else {
                Write-Log "WARNING: Registry value is $NewValue but expected $RegistryValue" -Level WARN
                $script:ExitCode = 1
            }
        } else {
            Write-Log "Failed to configure LLMNR" -Level ERROR
            $script:ExitCode = 1
        }
    }
    
    # Display security information
    Write-Log "" -Level INFO
    Write-Log "Security Information:" -Level INFO
    Write-Log "  LLMNR Disabled (0) - Recommended for security" -Level INFO
    Write-Log "  LLMNR Enabled (1)  - May pose security risks" -Level INFO
    
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
