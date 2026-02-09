#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configure LM hash storage policy for Windows authentication security

.DESCRIPTION
    Manages the NoLMHash registry setting that controls whether Windows stores
    LAN Manager (LM) hashes of user passwords. LM hashes are cryptographically weak
    (DES-based) and vulnerable to rainbow table and brute-force attacks.
    
    Security Background:
    LM hashes are legacy password hashes from Windows NT era that:
    - Split passwords into two 7-character chunks
    - Convert to uppercase before hashing
    - Use weak DES encryption
    - Can be cracked in seconds with modern tools
    
    Microsoft Security Baseline recommends disabling LM hash storage:
    - Prevents storage of weak password hashes
    - Forces use of stronger NTLM or NTLMv2 hashes
    - Reduces attack surface for credential theft
    - Required for compliance with security frameworks (CIS, NIST, DISA STIG)
    
    The script modifies the following registry key:
    HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\NoLMHash
    
    Values:
    - 0 = LM hashes are stored (INSECURE - legacy compatibility)
    - 1 = LM hashes are NOT stored (SECURE - recommended)
    
    Important Notes:
    - Changes apply to new passwords only (existing hashes remain until password change)
    - Does not affect NTLM/NTLMv2 authentication
    - No system restart required
    - Legacy systems (Windows 95/98/ME) cannot authenticate if LM hashes disabled
    - Modern systems (Windows 2000+) unaffected
    
    Compliance Mappings:
    - CIS Microsoft Windows Benchmark: 2.3.11.6
    - NIST 800-53: IA-5(1)
    - DISA STIG: WN10-SO-000145

.PARAMETER Enable
    If specified, ENABLES LM hash storage (sets NoLMHash=0, INSECURE).
    Not recommended except for legacy compatibility requirements.

.EXAMPLE
    .\Security-SetLMHashStorage.ps1
    
    Disables LM hash storage (secure, recommended).

.EXAMPLE
    .\Security-SetLMHashStorage.ps1 -Enable
    
    Enables LM hash storage (insecure, legacy compatibility only).

.NOTES
    Script Name:    Security-SetLMHashStorage.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required for LSA registry modification)
    Execution Frequency: One-time or policy enforcement
    Typical Duration: Less than 1 second
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Registry Modified:
        - HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\NoLMHash
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges
        - Windows 10 or Server 2016 minimum
    
    Security Impact:
        - HIGH when disabling (improves security)
        - HIGH when enabling (degrades security)
    
    Exit Codes:
        0 - Success (registry value set)
        1 - Failure (insufficient privileges or registry error)

.LINK
    https://github.com/Xore/waf

.LINK
    https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-security-do-not-store-lan-manager-hash-value-on-next-password-change
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Enable LM hash storage (INSECURE, not recommended)")]
    [switch]$Enable
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Security-SetLMHashStorage"

# Support NinjaRMM environment variable
if ($env:enableOrDisable -and $env:enableOrDisable -ne "null") {
    switch ($env:enableOrDisable) {
        "Enable"  { $Enable = $true }
        "Disable" { $Enable = $false }
    }
}

# Registry configuration
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryName = "NoLMHash"
$RegistryValue = if ($Enable) { 0 } else { 1 }

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0

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
    
    Write-Output $LogMessage
    
    switch ($Level) {
        'WARN'  { $script:WarningCount++ }
        'ERROR' { $script:ErrorCount++ }
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

function Set-RegistryValue {
    <#
    .SYNOPSIS
        Sets or creates a registry value with logging
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
        # Ensure registry path exists
        if (-not (Test-Path $Path)) {
            Write-Log "Creating registry path: $Path" -Level DEBUG
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Get current value if it exists
        $CurrentValue = $null
        try {
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
        } catch {
            Write-Log "Registry value does not exist, will create new" -Level DEBUG
        }
        
        # Set or update the value
        if ($null -ne $CurrentValue) {
            Write-Log "Current value: $Path\$Name = $CurrentValue" -Level INFO
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force | Out-Null
            Write-Log "Updated value: $Path\$Name = $Value" -Level SUCCESS
        } else {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
            Write-Log "Created value: $Path\$Name = $Value" -Level SUCCESS
        }
        
        # Verify the change
        $NewValue = (Get-ItemProperty -Path $Path -Name $Name).$Name
        if ($NewValue -eq $Value) {
            Write-Log "Registry value verified successfully" -Level DEBUG
            return $true
        } else {
            Write-Log "Registry value mismatch after setting (expected: $Value, got: $NewValue)" -Level ERROR
            return $false
        }
        
    } catch {
        Write-Log "Failed to set registry value: $($_.Exception.Message)" -Level ERROR
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
    
    # Check administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required for LSA registry modification"
    }
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    
    # Determine action
    $Action = if ($Enable) { "ENABLING" } else { "DISABLING" }
    $SecurityImpact = if ($Enable) { "REDUCES security (allows weak LM hashes)" } else { "IMPROVES security (blocks weak LM hashes)" }
    
    Write-Log "" -Level INFO
    Write-Log "Action: $Action LM hash storage" -Level INFO
    Write-Log "Registry: $RegistryPath\$RegistryName" -Level INFO
    Write-Log "New Value: $RegistryValue" -Level INFO
    Write-Log "Security Impact: $SecurityImpact" -Level INFO
    Write-Log "" -Level INFO
    
    # Warn if enabling (insecure)
    if ($Enable) {
        Write-Log "WARNING: Enabling LM hash storage is NOT RECOMMENDED" -Level WARN
        Write-Log "WARNING: LM hashes are cryptographically weak and easily cracked" -Level WARN
        Write-Log "WARNING: Only enable for legacy system compatibility" -Level WARN
        Write-Log "" -Level INFO
    }
    
    # Set the registry value
    Write-Log "Setting registry value..." -Level INFO
    $Success = Set-RegistryValue -Path $RegistryPath -Name $RegistryName -Value $RegistryValue -Type 'DWord'
    
    if ($Success) {
        Write-Log "" -Level INFO
        Write-Log "LM hash storage successfully $(if ($Enable) {'enabled'} else {'disabled'})" -Level SUCCESS
        Write-Log "Changes apply to new passwords only" -Level INFO
        Write-Log "No system restart required" -Level INFO
        
        if (-not $Enable) {
            Write-Log "Recommendation: Force password change for all users to remove existing LM hashes" -Level INFO
        }
        
        exit 0
    } else {
        throw "Registry value verification failed"
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "========================================" -Level INFO
}
