#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables Windows mini crash dumps for system debugging

.DESCRIPTION
    Configures Windows crash dump settings to enable mini dumps (small memory dumps)
    for troubleshooting system crashes and blue screens. Only enables mini dumps if
    crash dumps are currently disabled; preserves existing dump configurations.
    
    The script performs the following:
    - Checks current crash dump configuration
    - Enables mini dumps if currently disabled (CrashDumpEnabled = 0)
    - Configures automatic pagefile management if needed
    - Preserves existing dump settings if already enabled
    - Reports configuration changes to NinjaRMM
    
    A system reboot may be required for changes to take effect.
    This script runs unattended without user interaction.

.PARAMETER Force
    Forces mini dump configuration even if another dump type is enabled.
    Default: $false (preserves existing configurations)

.EXAMPLE
    .\System-EnableMinidumps.ps1
    
    Enables mini dumps if currently disabled.

.EXAMPLE
    .\System-EnableMinidumps.ps1 -Force
    
    Forces mini dump configuration regardless of current setting.

.OUTPUTS
    None. Configuration status is written to console and NinjaRMM custom fields.

.NOTES
    Script Name:    System-EnableMinidumps.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required)
    Execution Frequency: On-demand or during system setup
    Typical Duration: 1-2 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: Reboot may be required for changes to take effect
    
    Fields Updated:
        - crashDumpStatus - Status (Enabled/AlreadyEnabled/Configured/Failed)
        - crashDumpType - Type (0=None, 1=Complete, 2=Kernel, 3=Mini, 7=Auto)
        - crashDumpRebootRequired - Boolean (true/false)
        - crashDumpDate - Timestamp of configuration
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Registry write access
        - Windows 10, Windows Server 2016 or higher
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - forceConfiguration: Override -Force parameter
    
    Registry Keys Modified:
        - HKLM:\System\CurrentControlSet\Control\CrashControl\CrashDumpEnabled
        - HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PagingFiles
    
    Crash Dump Types:
        0 = None (disabled)
        1 = Complete memory dump
        2 = Kernel memory dump
        3 = Small memory dump (mini dump)
        7 = Automatic memory dump
    
    Exit Codes:
        0 - Success (configuration applied or already enabled)
        1 - Failure (registry error or insufficient privileges)

.LINK
    https://github.com/Xore/waf

.LINK
    https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/memory-dump-file-options
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Force mini dump configuration")]
    [switch]$Force
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "System-EnableMinidumps"

# Registry paths
$CrashControlPath = "HKLM:\System\CurrentControlSet\Control\CrashControl"
$MemoryManagementPath = "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ExitCode = 0
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0
$script:RebootRequired = $false

Set-StrictMode -Version Latest

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
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
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
        [ValidateSet('String','ExpandString','Binary','DWord','MultiString','QWord')]
        [string]$Type = 'DWord'
    )
    
    try {
        if (-not (Test-Path -Path $Path)) {
            Write-Log "Creating registry path: $Path" -Level DEBUG
            New-Item -Path $Path -Force | Out-Null
        }
        
        $CurrentValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        
        if ($CurrentValue) {
            $OldValue = $CurrentValue.$Name
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force | Out-Null
            Write-Log "Updated $Path\$Name from $OldValue to $Value" -Level INFO
        } else {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
            Write-Log "Created $Path\$Name with value $Value" -Level INFO
        }
        
        return $true
        
    } catch {
        Write-Log "Failed to set registry value: $_" -Level ERROR
        return $false
    }
}

function Get-CrashDumpTypeName {
    <#
    .SYNOPSIS
        Converts crash dump type number to name
    #>
    param([int]$Type)
    
    switch ($Type) {
        0 { return "None" }
        1 { return "Complete" }
        2 { return "Kernel" }
        3 { return "Mini" }
        7 { return "Automatic" }
        default { return "Unknown" }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable override
    if ($env:forceConfiguration -and $env:forceConfiguration -like "true") {
        $Force = $true
        Write-Log "Force configuration enabled from environment" -Level INFO
    }
    
    if ($Force) {
        Write-Log "Force mode enabled - will override existing configuration" -Level INFO
    }
    
    # Check administrator privileges
    if (-not (Test-IsElevated)) {
        Write-Log "ERROR: This script requires administrator privileges" -Level ERROR
        throw "Access Denied"
    }
    
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    
    # Get current crash dump configuration
    Write-Log "Checking current crash dump configuration" -Level INFO
    $CurrentDumpType = Get-ItemPropertyValue -Path $CrashControlPath -Name "CrashDumpEnabled" -ErrorAction SilentlyContinue
    
    if ($null -eq $CurrentDumpType) {
        Write-Log "CrashDumpEnabled registry value not found, assuming disabled" -Level WARN
        $CurrentDumpType = 0
    }
    
    $DumpTypeName = Get-CrashDumpTypeName -Type $CurrentDumpType
    Write-Log "Current crash dump type: $CurrentDumpType ($DumpTypeName)" -Level INFO
    
    # Determine if configuration is needed
    if ($CurrentDumpType -eq 0) {
        Write-Log "Crash dumps are currently disabled - enabling mini dumps" -Level INFO
        
        # Check for pagefile configuration
        $PageFile = Get-ItemPropertyValue -Path $MemoryManagementPath -Name "PagingFiles" -ErrorAction SilentlyContinue
        
        if (-not $PageFile) {
            Write-Log "Pagefile not configured - enabling automatic management" -Level INFO
            
            $Success = Set-RegistryValue -Path $MemoryManagementPath -Name "PagingFiles" -Value "?:\pagefile.sys" -Type "MultiString"
            
            if (-not $Success) {
                throw "Failed to configure pagefile for crash dumps"
            }
            
            Write-Log "Pagefile configured for automatic management" -Level SUCCESS
            $script:RebootRequired = $true
        } else {
            Write-Log "Pagefile already configured" -Level INFO
        }
        
        # Enable mini dumps
        $Success = Set-RegistryValue -Path $CrashControlPath -Name "CrashDumpEnabled" -Value 3 -Type "DWord"
        
        if (-not $Success) {
            throw "Failed to enable mini dumps"
        }
        
        Write-Log "Mini crash dumps enabled successfully" -Level SUCCESS
        $script:RebootRequired = $true
        
        Set-NinjaField -FieldName "crashDumpStatus" -Value "Configured"
        Set-NinjaField -FieldName "crashDumpType" -Value "3"
        Set-NinjaField -FieldName "crashDumpRebootRequired" -Value "true"
        
        if ($script:RebootRequired) {
            Write-Log "NOTICE: System reboot required for crash dump changes to take effect" -Level WARN
        }
        
    } elseif ($Force) {
        Write-Log "Force mode - changing dump type from $DumpTypeName to Mini" -Level INFO
        
        $Success = Set-RegistryValue -Path $CrashControlPath -Name "CrashDumpEnabled" -Value 3 -Type "DWord"
        
        if (-not $Success) {
            throw "Failed to set mini dump configuration"
        }
        
        Write-Log "Crash dump type changed to Mini" -Level SUCCESS
        $script:RebootRequired = $true
        
        Set-NinjaField -FieldName "crashDumpStatus" -Value "Configured"
        Set-NinjaField -FieldName "crashDumpType" -Value "3"
        Set-NinjaField -FieldName "crashDumpRebootRequired" -Value "true"
        
    } else {
        Write-Log "Crash dumps already enabled as $DumpTypeName - no changes made" -Level INFO
        
        Set-NinjaField -FieldName "crashDumpStatus" -Value "AlreadyEnabled"
        Set-NinjaField -FieldName "crashDumpType" -Value $CurrentDumpType.ToString()
        Set-NinjaField -FieldName "crashDumpRebootRequired" -Value "false"
    }
    
    Set-NinjaField -FieldName "crashDumpDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "Crash dump configuration completed successfully" -Level SUCCESS
    $script:ExitCode = 0
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "crashDumpStatus" -Value "Failed"
    Set-NinjaField -FieldName "crashDumpDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
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
    Write-Log "  Reboot Required: $script:RebootRequired" -Level INFO
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
