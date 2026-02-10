#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Reports Windows Credential Guard configuration and operational status

.DESCRIPTION
    Examines and reports the complete status of Windows Credential Guard, including:
    
    The script performs the following:
    - Validates administrator privileges
    - Checks OS compatibility (Enterprise/Education/Server editions)
    - Verifies hardware requirements (UEFI, Secure Boot, virtualization)
    - Checks Credential Guard configuration in registry
    - Determines if Credential Guard is actively running
    - Analyzes UEFI lock status
    - Provides detailed troubleshooting information
    - Optionally saves comprehensive report to custom fields
    
    Credential Guard protects domain credentials by:
    - Isolating LSASS process in virtualized container
    - Preventing pass-the-hash attacks
    - Protecting against memory scraping
    - Using Virtualization-Based Security (VBS)
    
    This is critical for:
    - Enterprise security hardening
    - Compliance (CIS Benchmarks, NIST, DoD STIG)
    - Protection against credential theft
    - Advanced threat protection
    - Zero Trust architectures
    
    This script runs unattended without user interaction.

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save Credential Guard status.
    Must be a valid custom field name (max 200 characters).
    Format: "Configuration | Running Status"

.PARAMETER IncludeHardwareInfo
    Include hardware requirements validation in the report.
    Checks UEFI, Secure Boot, and virtualization support.
    Default: $true

.EXAMPLE
    .\Security-CredentialGuardStatus.ps1
    
    Reports Credential Guard configuration and running status.

.EXAMPLE
    .\Security-CredentialGuardStatus.ps1 -CustomFieldName "CredGuardStatus"
    
    Reports status and stores result in custom field.

.EXAMPLE
    .\Security-CredentialGuardStatus.ps1 -IncludeHardwareInfo
    
    Reports status with hardware requirements validation.

.OUTPUTS
    None. Credential Guard status is written to console and optionally to custom field.

.NOTES
    Script Name:    Security-CredentialGuardStatus.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-12
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required)
    Execution Frequency: Scheduled (e.g., weekly or on-demand)
    Typical Duration: ~2-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName (if specified) - Credential Guard status
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Supported OS: Windows 10/11 Enterprise/Education, Windows Server 2016+
        - Hardware: UEFI firmware, Secure Boot, Virtualization support
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - textCustomFieldName: Legacy parameter support
        - customFieldName: Alternative to -CustomFieldName parameter
        - includeHardwareInfo: Alternative to -IncludeHardwareInfo parameter
    
    Configuration Values:
        - 0: Disabled
        - 1: Enabled with UEFI lock
        - 2: Enabled without UEFI lock
    
    Running Status:
        - SecurityServicesRunning contains 1: Credential Guard is running
    
    Exit Codes:
        0 - Success (status reported)
        1 - Error or OS incompatible

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/en-us/windows/security/identity-protection/credential-guard/
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save results")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName,
    
    [Parameter(Mandatory=$false, HelpMessage="Include hardware requirements check")]
    [switch]$IncludeHardwareInfo = $true
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Security-CredentialGuardStatus"

# Support NinjaRMM environment variables (including legacy names)
if ($env:textCustomFieldName -and $env:textCustomFieldName -notlike "null") {
    $CustomFieldName = $env:textCustomFieldName
}

if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

if ($env:includeHardwareInfo -and $env:includeHardwareInfo -notlike "null") {
    $IncludeHardwareInfo = [bool]::Parse($env:includeHardwareInfo)
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

function Test-IsCredentialGuardRunning {
    <#
    .SYNOPSIS
        Checks if Credential Guard is actively running
    #>
    try {
        $DeviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
        return ($DeviceGuard.SecurityServicesRunning -contains 1)
    } catch {
        Write-Log "Failed to query Credential Guard running status" -Level DEBUG
        return $false
    }
}

function Test-OSCompatibility {
    <#
    .SYNOPSIS
        Checks if OS supports Credential Guard
    #>
    param(
        [Parameter(Mandatory=$true)]
        $OSInfo
    )
    
    # Windows 10/11 requires Enterprise or Education edition
    if ($OSInfo.Caption -match "Windows (10|11)") {
        if ($OSInfo.Caption -notmatch "Enterprise|Education") {
            # Check for special registry key that might indicate compatibility
            $RegKey = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($RegKey.IsolatedCredentialsRootSecret)) {
                return $false
            }
        }
        return $true
    }
    
    # Windows Server 2016 or newer
    if ($OSInfo.Caption -match "Windows Server (2016|2019|202[2-9]|20[3-9][0-9])") {
        return $true
    }
    
    return $false
}

function Get-HardwareRequirements {
    <#
    .SYNOPSIS
        Checks hardware requirements for Credential Guard
    #>
    try {
        $Computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $Firmware = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction Stop
        
        $IsUEFI = $Computer.BootupState -eq "Normal boot"
        $SecureBoot = try { Confirm-SecureBootUEFI -ErrorAction Stop } catch { $false }
        $VirtualizationEnabled = $Computer.HypervisorPresent
        
        return [PSCustomObject]@{
            IsUEFI = $IsUEFI
            SecureBoot = $SecureBoot
            VirtualizationEnabled = $VirtualizationEnabled
            AllRequirementsMet = ($IsUEFI -and $SecureBoot -and $VirtualizationEnabled)
        }
    } catch {
        Write-Log "Failed to check hardware requirements" -Level DEBUG
        return $null
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
    
    Write-Log "Checking Credential Guard status" -Level INFO
    Write-Log "" -Level INFO
    
    # Get OS information
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    Write-Log "Operating System: $($OS.Caption)" -Level INFO
    Write-Log "Version: $($OS.Version)" -Level INFO
    Write-Log "Build: $($OS.BuildNumber)" -Level INFO
    Write-Log "" -Level INFO
    
    # Check OS compatibility
    if (-not (Test-OSCompatibility -OSInfo $OS)) {
        Write-Log "ERROR: Credential Guard is not supported on this OS edition" -Level ERROR
        Write-Log "Supported editions:" -Level INFO
        Write-Log "  - Windows 10/11 Enterprise or Education" -Level INFO
        Write-Log "  - Windows Server 2016 or newer" -Level INFO
        
        if ($CustomFieldName) {
            Set-NinjaField -FieldName $CustomFieldName -Value "Incompatible OS Edition"
        }
        
        throw "Incompatible OS"
    }
    
    Write-Log "OS is compatible with Credential Guard" -Level SUCCESS
    Write-Log "" -Level INFO
    
    # Check hardware requirements if requested
    if ($IncludeHardwareInfo) {
        Write-Log "Checking hardware requirements..." -Level INFO
        $Hardware = Get-HardwareRequirements
        
        if ($Hardware) {
            Write-Log "  UEFI Firmware: $(if ($Hardware.IsUEFI) { 'Yes' } else { 'No' })" -Level $(if ($Hardware.IsUEFI) { 'SUCCESS' } else { 'WARN' })
            Write-Log "  Secure Boot: $(if ($Hardware.SecureBoot) { 'Enabled' } else { 'Disabled' })" -Level $(if ($Hardware.SecureBoot) { 'SUCCESS' } else { 'WARN' })
            Write-Log "  Virtualization: $(if ($Hardware.VirtualizationEnabled) { 'Enabled' } else { 'Disabled' })" -Level $(if ($Hardware.VirtualizationEnabled) { 'SUCCESS' } else { 'WARN' })
            
            if (-not $Hardware.AllRequirementsMet) {
                Write-Log "WARNING: Not all hardware requirements are met" -Level WARN
            }
            Write-Log "" -Level INFO
        }
    }
    
    # Check Credential Guard configuration in registry
    $LsaConfig = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" -ErrorAction Stop
    $CGConfiguration = $LsaConfig.LsaCfgFlags
    
    if ($null -eq $CGConfiguration) {
        $CGConfiguration = $LsaConfig.LsaCfgFlagsDefault
    }
    
    $CGConfigurationStatus = switch ($CGConfiguration) {
        0 { "Disabled" }
        1 { "Enabled with UEFI lock" }
        2 { "Enabled without UEFI lock" }
        default { "Unable to Determine" }
    }
    
    # Check if Credential Guard is actively running
    $IsRunning = Test-IsCredentialGuardRunning
    $CGRunningStatus = if ($IsRunning) { "Running" } else { "Not Running" }
    
    Write-Log "========================================" -Level INFO
    Write-Log "CREDENTIAL GUARD STATUS" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "Configuration: $CGConfigurationStatus" -Level $(if ($CGConfiguration -gt 0) { 'SUCCESS' } else { 'WARN' })
    Write-Log "Running Status: $CGRunningStatus" -Level $(if ($IsRunning) { 'SUCCESS' } else { 'WARN' })
    Write-Log "" -Level INFO
    
    # Analyze configuration and provide recommendations
    if ($CGConfigurationStatus -eq "Disabled" -and $IsRunning) {
        Write-Log "NOTICE: Credential Guard is disabled in registry but currently running" -Level WARN
        Write-Log "This may indicate:" -Level INFO
        Write-Log "  - Credential Guard is UEFI locked (cannot be disabled without BIOS change)" -Level INFO
        Write-Log "  - Group Policy enforcement is active" -Level INFO
        Write-Log "  - A restart is needed to apply configuration changes" -Level INFO
        Write-Log "" -Level INFO
    }
    elseif ($CGConfigurationStatus -eq "Enabled with UEFI lock") {
        Write-Log "SECURITY: UEFI lock is enabled - maximum protection" -Level SUCCESS
        Write-Log "Credential Guard cannot be disabled without BIOS/UEFI modification" -Level INFO
        Write-Log "" -Level INFO
    }
    elseif ($CGConfigurationStatus -eq "Enabled without UEFI lock") {
        Write-Log "RECOMMENDATION: Consider enabling UEFI lock for maximum protection" -Level WARN
        Write-Log "UEFI lock prevents attackers from disabling Credential Guard" -Level INFO
        Write-Log "" -Level INFO
    }
    elseif ($CGConfigurationStatus -eq "Disabled") {
        Write-Log "SECURITY RISK: Credential Guard is disabled" -Level ERROR
        Write-Log "RECOMMENDATION: Enable Credential Guard to protect domain credentials" -Level WARN
        Write-Log "Protection against: Pass-the-Hash, Pass-the-Ticket, credential theft" -Level INFO
        Write-Log "" -Level INFO
    }
    
    # Save to custom field if specified
    if ($CustomFieldName) {
        $FieldValue = "$CGConfigurationStatus | $CGRunningStatus"
        Set-NinjaField -FieldName $CustomFieldName -Value $FieldValue
        Write-Log "Status saved to custom field '$CustomFieldName'" -Level INFO
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
    
    # Cleanup
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit $script:ExitCode
}
