<#
.SYNOPSIS
    Join a Windows computer to an Active Directory domain

.DESCRIPTION
    Joins the local computer to an Active Directory domain using provided credentials.
    Credentials must be supplied via environment variables (typically from NinjaRMM).
    
    The script performs the following:
    - Validates required environment variables
    - Creates secure credential object
    - Joins computer to specified domain
    - Optionally restarts computer if authorized
    - Updates NinjaRMM custom fields with join status
    
    This script runs unattended without user interaction.

.PARAMETER AllowRestart
    Authorizes the computer to restart after successful domain join.
    Without this parameter, script will complete join but require manual restart.
    Default: False (manual restart required)

.EXAMPLE
    .\AD-JoinDomain.ps1
    
    Joins computer to domain specified in environment variables.
    Requires manual restart to complete domain join.

.EXAMPLE
    .\AD-JoinDomain.ps1 -AllowRestart
    
    Joins computer to domain and automatically restarts.

.NOTES
    Script Name:    AD-JoinDomain.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand
    Typical Duration: ~8-12 seconds (measured average)
    Timeout Setting: 300 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: Never restarts unless -AllowRestart parameter provided
    
    Fields Updated:
        - adDomainJoinStatus (Success/Failed)
        - adDomainName (domain name)
        - adRestartRequired (Yes/No)
        - adRestartInitiated (Yes/No if restarted)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Network connectivity to domain controller
    
    Environment Variables Required:
        - user: Domain administrator username
        - pass: Domain administrator password
        - domain: Target domain name (e.g., contoso.com)
    
    Exit Codes:
        0 - Success (domain join completed)
        1 - General error (validation failure, join failure)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Authorize automatic restart after domain join")]
    [switch]$AllowRestart = $false
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "AD-JoinDomain"

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
        [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Plain text output only - no colors or special characters
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
    .DESCRIPTION
        Attempts to set a NinjaRMM custom field using Ninja-Property-Set cmdlet.
        If cmdlet fails, automatically falls back to ninjarmm-cli.exe.
        This dual approach ensures field setting works in all execution contexts.
    .PARAMETER FieldName
        The name of the custom field to set (case-sensitive)
    .PARAMETER Value
        The value to set. Null or empty values are skipped.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    # Skip null or empty values
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    # Method 1: Try Ninja-Property-Set cmdlet (primary)
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' = $ValueString" -Level DEBUG
            return
        } else {
            throw "Ninja-Property-Set cmdlet not available"
        }
    } catch {
        Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
        
        # Method 2: Fall back to NinjaRMM CLI
        try {
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            $CLIArgs = @("set", $FieldName, $ValueString)
            $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "CLI exit code: $LASTEXITCODE, Output: $CLIResult"
            }
            
            Write-Log "Field '$FieldName' = $ValueString (via CLI)" -Level DEBUG
            $script:CLIFallbackCount++
            
        } catch {
            Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
            # Don't throw - field setting failure shouldn't stop the script
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Validate required environment variables
    Write-Log "Validating environment variables" -Level INFO
    
    if ([string]::IsNullOrWhiteSpace($env:user)) {
        throw "Environment variable 'user' is not set or empty"
    }
    
    if ([string]::IsNullOrWhiteSpace($env:pass)) {
        throw "Environment variable 'pass' is not set or empty"
    }
    
    if ([string]::IsNullOrWhiteSpace($env:domain)) {
        throw "Environment variable 'domain' is not set or empty"
    }
    
    Write-Log "Domain: $env:domain" -Level INFO
    Write-Log "Username: $env:user" -Level INFO
    Write-Log "Restart Authorized: $AllowRestart" -Level INFO
    
    # Create secure credential object
    Write-Log "Creating domain credentials" -Level DEBUG
    $SecurePassword = ConvertTo-SecureString -String $env:pass -AsPlainText -Force
    $JoinCred = [PSCredential]::new($env:user, $SecurePassword)
    
    # Perform domain join with restart protection
    if ($AllowRestart) {
        Write-Log "Joining domain with automatic restart enabled" -Level INFO
        Write-Log "Computer will restart upon successful join" -Level WARN
        
        # Set fields before restart
        Set-NinjaField -FieldName "adDomainName" -Value $env:domain
        Set-NinjaField -FieldName "adRestartInitiated" -Value "Yes"
        Start-Sleep -Seconds 2  # Allow field sync
        
        $Result = Add-Computer -DomainName $env:domain -Credential $JoinCred -PassThru -Force -ErrorAction Stop -Restart
        
        Write-Log "SUCCESS: Domain join initiated, computer will restart" -Level SUCCESS
        Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Success"
        
    } else {
        Write-Log "Joining domain without automatic restart" -Level INFO
        $Result = Add-Computer -DomainName $env:domain -Credential $JoinCred -PassThru -Force -ErrorAction Stop
        
        if ($Result) {
            Write-Log "SUCCESS: Computer joined to domain '$env:domain'" -Level SUCCESS
            Write-Log "MANUAL RESTART REQUIRED to complete domain join" -Level WARN
            Write-Log "Use -AllowRestart parameter to enable automatic restart" -Level INFO
            
            # Update NinjaRMM fields
            Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Success"
            Set-NinjaField -FieldName "adDomainName" -Value $env:domain
            Set-NinjaField -FieldName "adRestartRequired" -Value "Yes"
            Set-NinjaField -FieldName "adRestartInitiated" -Value "No"
        }
    }
    
    Write-Log "Domain join operation completed successfully" -Level INFO
    
} catch {
    Write-Log "ERROR: Failed to join domain - $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    Write-Log "Verify credentials, domain name, and network connectivity" -Level ERROR
    
    # Update failure status in NinjaRMM
    Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Failed"
    Set-NinjaField -FieldName "adDomainName" -Value $env:domain
    
    exit 1
    
} finally {
    # Calculate and log execution time
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

# Exit with appropriate code
if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
