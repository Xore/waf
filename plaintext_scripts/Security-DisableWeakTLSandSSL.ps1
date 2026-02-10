#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Disables weak SSL/TLS protocols and enables strong encryption

.DESCRIPTION
    Configures Windows cryptographic protocols to disable insecure versions and enable
    secure modern protocols. This script performs the following:
    
    The script performs the following:
    - Validates administrator privileges
    - Backs up current protocol configuration to registry
    - Disables SSL 2.0, SSL 3.0, TLS 1.0, TLS 1.1 (weak/insecure)
    - Enables TLS 1.2 (secure, widely supported)
    - Optionally enables TLS 1.3 (Windows Server 2022+, Windows 11+)
    - Configures both server and client components
    - Verifies all changes were applied successfully
    - Optionally schedules system restart to apply changes
    - Saves configuration status to custom fields
    
    This is critical for:
    - PCI DSS compliance (requires TLS 1.2+ only)
    - HIPAA security requirements
    - NIST cybersecurity framework
    - Protection against POODLE, BEAST, CRIME attacks
    - Modern browser and application compatibility
    - Securing network communications
    
    This script runs unattended without user interaction.
    
    WARNING: This may affect legacy applications that require older protocols.
    Test thoroughly before deploying to production systems.

.PARAMETER Restart
    Schedule an automatic system restart in 30 seconds to apply changes.
    Default: $false

.PARAMETER EnableTLS13
    Enable TLS 1.3 if supported by the operating system.
    Requires Windows 11 or Windows Server 2022 or newer.
    Default: $true (if OS supports it)

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save protocol configuration status.
    Must be a valid custom field name (max 200 characters).

.PARAMETER BackupRegistry
    Create a backup of registry settings before making changes.
    Default: $true

.EXAMPLE
    .\Security-DisableWeakTLSandSSL.ps1
    
    Disables weak protocols, enables TLS 1.2, without restart.

.EXAMPLE
    .\Security-DisableWeakTLSandSSL.ps1 -Restart
    
    Disables weak protocols and schedules restart in 30 seconds.

.EXAMPLE
    .\Security-DisableWeakTLSandSSL.ps1 -EnableTLS13 -CustomFieldName "TLSConfig"
    
    Enables TLS 1.3 (if supported) and saves status to custom field.

.OUTPUTS
    None. Protocol configuration status is written to console and optionally to custom field.

.NOTES
    Script Name:    Security-DisableWeakTLSandSSL.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-08
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required)
    Execution Frequency: One-time or as-needed for compliance
    Typical Duration: ~3-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: Optional (-Restart parameter)
    
    Fields Updated:
        - CustomFieldName (if specified) - Protocol configuration status
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Windows 10, Windows Server 2016 or higher
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - forceRestart: Alternative to -Restart parameter
        - enableTLS13: Alternative to -EnableTLS13 parameter
        - customFieldName: Alternative to -CustomFieldName parameter
        - backupRegistry: Alternative to -BackupRegistry parameter
    
    Registry Paths:
        - HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols
    
    Protocols Disabled:
        - SSL 2.0 (obsolete since 2011)
        - SSL 3.0 (vulnerable to POODLE)
        - TLS 1.0 (deprecated by major browsers)
        - TLS 1.1 (deprecated by major browsers)
    
    Protocols Enabled:
        - TLS 1.2 (current standard)
        - TLS 1.3 (latest, if supported)
    
    Exit Codes:
        0 - Success (protocols configured)
        1 - Error (configuration failed)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/en-us/windows-server/security/tls/tls-registry-settings
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Schedule automatic restart")]
    [switch]$Restart,
    
    [Parameter(Mandatory=$false, HelpMessage="Enable TLS 1.3 if supported")]
    [switch]$EnableTLS13 = $true,
    
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save results")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName,
    
    [Parameter(Mandatory=$false, HelpMessage="Backup registry before changes")]
    [switch]$BackupRegistry = $true
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Security-DisableWeakTLSandSSL"

# Support NinjaRMM environment variables
if ($env:forceRestart -and $env:forceRestart -notlike "null") {
    $Restart = [System.Convert]::ToBoolean($env:forceRestart)
}

if ($env:enableTLS13 -and $env:enableTLS13 -notlike "null") {
    $EnableTLS13 = [bool]::Parse($env:enableTLS13)
}

if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

if ($env:backupRegistry -and $env:backupRegistry -notlike "null") {
    $BackupRegistry = [bool]::Parse($env:backupRegistry)
}

# Trim whitespace from parameters
if ($CustomFieldName) { $CustomFieldName = $CustomFieldName.Trim() }

# Registry base path
$RegBasePath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
$BackupPath = "$env:TEMP\TLS_SSL_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"

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

function Test-TLS13Support {
    <#
    .SYNOPSIS
        Checks if operating system supports TLS 1.3
    #>
    try {
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $BuildNumber = [int]$OS.BuildNumber
        
        # Windows 11 (build 22000+) or Windows Server 2022 (build 20348+)
        if ($OS.Caption -match "Windows 11" -or ($OS.Caption -match "Server" -and $BuildNumber -ge 20348)) {
            return $true
        }
        
        # Windows 10 21H2+ (build 19044+) with update
        if ($OS.Caption -match "Windows 10" -and $BuildNumber -ge 19044) {
            return $true
        }
        
        return $false
    } catch {
        Write-Log "Failed to check TLS 1.3 support" -Level DEBUG
        return $false
    }
}

function Backup-ProtocolRegistry {
    <#
    .SYNOPSIS
        Backs up current protocol registry settings
    #>
    try {
        $RegKey = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL"
        $Result = & reg.exe export $RegKey $BackupPath /y 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Registry backup created: $BackupPath" -Level SUCCESS
            return $true
        } else {
            Write-Log "Registry backup failed: $Result" -Level WARN
            return $false
        }
    } catch {
        Write-Log "Failed to backup registry: $_" -Level WARN
        return $false
    }
}

function Set-ProtocolConfiguration {
    <#
    .SYNOPSIS
        Configures a specific protocol
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProtocolName,
        
        [Parameter(Mandatory=$true)]
        [int]$Enabled,
        
        [Parameter(Mandatory=$true)]
        [int]$DisabledByDefault
    )
    
    $RegServerPath = "$RegBasePath\$ProtocolName\Server"
    $RegClientPath = "$RegBasePath\$ProtocolName\Client"
    
    try {
        # Configure Server component
        if (-not (Test-Path $RegServerPath)) {
            New-Item $RegServerPath -Force -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -Path $RegServerPath -Name 'Enabled' -Value $Enabled -PropertyType 'DWord' -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegServerPath -Name 'DisabledByDefault' -Value $DisabledByDefault -PropertyType 'DWord' -Force -ErrorAction Stop | Out-Null
        
        # Configure Client component
        if (-not (Test-Path $RegClientPath)) {
            New-Item $RegClientPath -Force -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -Path $RegClientPath -Name 'Enabled' -Value $Enabled -PropertyType 'DWord' -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $RegClientPath -Name 'DisabledByDefault' -Value $DisabledByDefault -PropertyType 'DWord' -Force -ErrorAction Stop | Out-Null
        
        # Verify configuration
        $ServerEnabled = Get-ItemPropertyValue -Path $RegServerPath -Name 'Enabled' -ErrorAction Stop
        $ServerDisabled = Get-ItemPropertyValue -Path $RegServerPath -Name 'DisabledByDefault' -ErrorAction Stop
        
        if ($ServerEnabled -eq $Enabled -and $ServerDisabled -eq $DisabledByDefault) {
            return $true
        } else {
            Write-Log "Verification failed for $ProtocolName" -Level ERROR
            return $false
        }
        
    } catch {
        Write-Log "Failed to configure $ProtocolName: $_" -Level ERROR
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
    
    Write-Log "Configuring SSL/TLS protocols for security hardening" -Level INFO
    Write-Log "" -Level INFO
    
    # Backup registry if requested
    if ($BackupRegistry) {
        Write-Log "Creating registry backup..." -Level INFO
        Backup-ProtocolRegistry | Out-Null
        Write-Log "" -Level INFO
    }
    
    # Check TLS 1.3 support
    $TLS13Supported = Test-TLS13Support
    if ($TLS13Supported) {
        Write-Log "TLS 1.3 is supported on this system" -Level SUCCESS
    } else {
        Write-Log "TLS 1.3 is not supported on this system" -Level INFO
        if ($EnableTLS13) {
            Write-Log "Disabling TLS 1.3 configuration (not supported)" -Level WARN
            $EnableTLS13 = $false
        }
    }
    Write-Log "" -Level INFO
    
    # Define protocol configurations
    $Protocols = @(
        @{ Name = 'SSL 2.0'; Enable = 0; Default = 1; Description = 'Obsolete (1995), DROWN vulnerability' }
        @{ Name = 'SSL 3.0'; Enable = 0; Default = 1; Description = 'Vulnerable to POODLE attack' }
        @{ Name = 'TLS 1.0'; Enable = 0; Default = 1; Description = 'Deprecated, BEAST vulnerability' }
        @{ Name = 'TLS 1.1'; Enable = 0; Default = 1; Description = 'Deprecated, weak cryptography' }
        @{ Name = 'TLS 1.2'; Enable = 1; Default = 0; Description = 'Current standard, secure' }
    )
    
    # Add TLS 1.3 if supported and enabled
    if ($TLS13Supported -and $EnableTLS13) {
        $Protocols += @{ Name = 'TLS 1.3'; Enable = 1; Default = 0; Description = 'Latest standard, maximum security' }
    }
    
    # Configure each protocol
    Write-Log "Configuring protocols..." -Level INFO
    Write-Log "" -Level INFO
    
    $Report = New-Object System.Collections.Generic.List[String]
    $Report.Add("SSL/TLS PROTOCOL CONFIGURATION")
    $Report.Add("Configured: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $Report.Add("")
    
    $SuccessCount = 0
    $FailCount = 0
    
    foreach ($Protocol in $Protocols) {
        $Success = Set-ProtocolConfiguration -ProtocolName $Protocol.Name -Enabled $Protocol.Enable -DisabledByDefault $Protocol.Default
        
        if ($Success) {
            $State = if ($Protocol.Enable -eq 0) { "DISABLED" } else { "ENABLED" }
            $Level = if ($Protocol.Enable -eq 0) { 'SUCCESS' } else { 'SUCCESS' }
            
            Write-Log "$($Protocol.Name): $State" -Level $Level
            Write-Log "  Reason: $($Protocol.Description)" -Level INFO
            
            $Report.Add("$($Protocol.Name): $State")
            $Report.Add("  $($Protocol.Description)")
            
            $SuccessCount++
        } else {
            Write-Log "$($Protocol.Name): FAILED" -Level ERROR
            $Report.Add("$($Protocol.Name): CONFIGURATION FAILED")
            $FailCount++
        }
        Write-Log "" -Level INFO
    }
    
    $Report.Add("")
    $Report.Add("Summary: $SuccessCount configured, $FailCount failed")
    
    # Summary
    Write-Log "========================================" -Level INFO
    Write-Log "CONFIGURATION SUMMARY" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "Protocols Configured: $SuccessCount" -Level INFO
    Write-Log "Configuration Failures: $FailCount" -Level INFO
    Write-Log "" -Level INFO
    
    if ($FailCount -gt 0) {
        Write-Log "WARNING: Some protocols failed to configure" -Level WARN
        Write-Log "Review error messages above for details" -Level WARN
        Write-Log "" -Level INFO
    }
    
    # Restart handling
    if ($Restart) {
        Write-Log "RESTART: Scheduling system restart in 30 seconds" -Level WARN
        Write-Log "Changes will take effect after restart" -Level INFO
        $Report.Add("")
        $Report.Add("System restart scheduled for 30 seconds")
        
        Start-Process cmd.exe -ArgumentList "/c shutdown.exe /r /t 30" -WindowStyle Hidden
    } else {
        Write-Log "IMPORTANT: System restart required for changes to take effect" -Level WARN
        Write-Log "Run with -Restart parameter to schedule automatic restart" -Level INFO
        $Report.Add("")
        $Report.Add("RESTART REQUIRED: Changes pending until reboot")
    }
    
    # Save to custom field if specified
    if ($CustomFieldName) {
        $FormattedReport = $Report -join "`n"
        Set-NinjaField -FieldName $CustomFieldName -Value $FormattedReport
        Write-Log "Configuration saved to custom field '$CustomFieldName'" -Level INFO
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    if ($BackupPath -and (Test-Path $BackupPath)) {
        Write-Log "Registry backup available at: $BackupPath" -Level INFO
    }
    
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
    if ($BackupPath -and (Test-Path $BackupPath)) {
        Write-Log "  Backup File: $BackupPath" -Level INFO
    }
    Write-Log "  Exit Code: $script:ExitCode" -Level INFO
    Write-Log "========================================" -Level INFO
    
    exit $script:ExitCode
}
