#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Checks if LSASS process protection is enabled

.DESCRIPTION
    Verifies whether LSASS (Local Security Authority Subsystem Service) running protection
    is enabled on the system. LSASS protection helps prevent credential theft attacks by
    preventing unauthorized processes from reading LSASS memory, which contains sensitive
    authentication credentials.
    
    The script performs the following:
    - Checks LSASS RunAsPPL (Protected Process Light) registry setting
    - Reports current protection status
    - Optionally enables protection if disabled
    - Saves status to NinjaRMM custom fields if specified
    - Alerts when protection is disabled (security risk)
    - Notifies when restart is required after enabling
    
    LSASS protection is configured via the RunAsPPL registry setting. Enabling this
    protection is a security best practice that helps defend against credential dumping
    tools like Mimikatz and other memory-based attacks.
    
    This script runs unattended without user interaction.

.PARAMETER EnableIfDisabled
    Automatically enables LSASS protection if it is currently disabled.
    Requires system restart to take effect.

.PARAMETER SaveToCustomField
    Name of a NinjaRMM custom field to save the LSASS protection status.
    Possible values: "Enabled", "Disabled", "Enabled (Restart Required)"

.EXAMPLE
    .\LSASS-RunningProtectionCheck.ps1
    
    Checks LSASS protection status and reports result.

.EXAMPLE
    .\LSASS-RunningProtectionCheck.ps1 -EnableIfDisabled
    
    Checks LSASS protection and enables it if disabled.

.EXAMPLE
    .\LSASS-RunningProtectionCheck.ps1 -EnableIfDisabled -SaveToCustomField "LSASSProtectionStatus"
    
    Checks, enables if needed, and saves status to custom field.

.NOTES
    Script Name:    LSASS-RunningProtectionCheck.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (SYSTEM via NinjaRMM)
    Execution Frequency: On-demand or scheduled for security audits
    Typical Duration: 1-2 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: Restart required if protection is enabled by script
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges required
        - Windows 10 or higher / Windows Server 2016 or higher
    
    Environment Variables (Optional):
        - enableIfDisabled: Alternative to -EnableIfDisabled parameter ("true" enables)
        - saveToCustomField: Alternative to -SaveToCustomField parameter
    
    Exit Codes:
        0 - Success (protection enabled or successfully enabled)
        1 - Failure (protection disabled and not auto-enabled, or enable operation failed)
    
    Security Note:
        LSASS protection (RunAsPPL) is a critical security feature that should be enabled
        on all production systems to protect against credential theft attacks.

.LINK
    https://github.com/Xore/waf
    https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$EnableIfDisabled,
    
    [Parameter(Mandatory=$false)]
    [ValidateLength(1,255)]
    [string]$SaveToCustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "LSASS-RunningProtectionCheck"

# Support environment variables
if ($env:enableIfDisabled -eq "true") {
    $EnableIfDisabled = $true
}
if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
    $SaveToCustomField = $env:saveToCustomField
}

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$script:ExitCode = 0
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0
$ProtectionEnabled = $false
$ProtectionChanged = $false

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
        [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS','ALERT')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Plain text output only - no colors
    Write-Output $LogMessage
    
    # Track counts
    switch ($Level) {
        'WARN'  { $script:WarningCount++ }
        'ERROR' { $script:ErrorCount++; $script:ExitCode = 1 }
        'ALERT' { $script:WarningCount++ }
    }
}

function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field with CLI fallback
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Value
    )
    
    try {
        $null = Ninja-Property-Set-Piped -Name $Name -Value $Value 2>&1
        Write-Log "Custom field '$Name' updated successfully" -Level DEBUG
    } catch {
        Write-Log "Ninja cmdlet unavailable, using CLI fallback for field '$Name'" -Level WARN
        $script:CLIFallbackCount++
        
        try {
            $NinjaPath = "C:\Program Files (x86)\NinjaRMMAgent\ninjarmm-cli.exe"
            if (-not (Test-Path $NinjaPath)) {
                $NinjaPath = "C:\Program Files\NinjaRMMAgent\ninjarmm-cli.exe"
            }
            
            if (Test-Path $NinjaPath) {
                $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
                $ProcessInfo.FileName = $NinjaPath
                $ProcessInfo.Arguments = "set $Name `"$Value`""
                $ProcessInfo.UseShellExecute = $false
                $ProcessInfo.RedirectStandardOutput = $true
                $ProcessInfo.RedirectStandardError = $true
                $Process = New-Object System.Diagnostics.Process
                $Process.StartInfo = $ProcessInfo
                $null = $Process.Start()
                $null = $Process.WaitForExit(5000)
                Write-Log "CLI fallback succeeded for field '$Name'" -Level DEBUG
            } else {
                throw "NinjaRMM CLI executable not found"
            }
        } catch {
            Write-Log "CLI fallback failed for field '$Name': $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
}

function Test-IsElevated {
    <#
    .SYNOPSIS
        Checks if current session has administrator privileges
    #>
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    Write-Log "Administrator privileges verified" -Level DEBUG
    
    # Check LSASS protection status
    Write-Log "Checking LSASS protection status..." -Level INFO
    
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    Write-Log "Registry path: $RegPath" -Level DEBUG
    
    try {
        $RunAsPPL = Get-ItemProperty -Path $RegPath -Name "RunAsPPL" -ErrorAction SilentlyContinue | 
                    Select-Object -ExpandProperty RunAsPPL
        
        $ProtectionEnabled = ($RunAsPPL -eq 1)
        
        if ($ProtectionEnabled) {
            Write-Log "LSASS protection is ENABLED" -Level SUCCESS
            $Status = "Enabled"
        } else {
            Write-Log "LSASS protection is DISABLED - security risk detected" -Level ALERT
            $Status = "Disabled"
            $script:ExitCode = 1
            
            # Enable protection if requested
            if ($EnableIfDisabled) {
                Write-Log "EnableIfDisabled flag set - attempting to enable protection" -Level INFO
                
                try {
                    Set-ItemProperty -Path $RegPath -Name "RunAsPPL" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop
                    Write-Log "LSASS protection enabled successfully" -Level SUCCESS
                    Write-Log "RESTART REQUIRED for changes to take effect" -Level WARN
                    $Status = "Enabled (Restart Required)"
                    $ProtectionChanged = $true
                    $script:ExitCode = 0
                } catch {
                    Write-Log "Failed to enable LSASS protection: $($_.Exception.Message)" -Level ERROR
                    throw
                }
            } else {
                Write-Log "Use -EnableIfDisabled parameter to automatically enable protection" -Level INFO
            }
        }
        
    } catch {
        Write-Log "Failed to check RunAsPPL registry value: $($_.Exception.Message)" -Level ERROR
        throw
    }
    
    # Save to custom field if specified
    if ($SaveToCustomField) {
        try {
            Set-NinjaField -Name $SaveToCustomField -Value $Status
            Write-Log "Status saved to custom field '$SaveToCustomField': $Status" -Level SUCCESS
        } catch {
            Write-Log "Failed to save to custom field: $($_.Exception.Message)" -Level ERROR
            throw
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
    Write-Log "  LSASS Protection: $(if ($ProtectionEnabled) {'Enabled'} else {'Disabled'})" -Level INFO
    Write-Log "  Protection Changed: $ProtectionChanged" -Level INFO
    if ($ProtectionChanged) {
        Write-Log "  Restart Required: YES" -Level INFO
    }
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    Write-Log "  Exit Code: $script:ExitCode" -Level INFO
    Write-Log "========================================" -Level INFO
    
    exit $script:ExitCode
}
