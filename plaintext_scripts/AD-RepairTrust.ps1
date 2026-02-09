<#
.SYNOPSIS
    Repair the trust relationship between a computer and its Active Directory domain

.DESCRIPTION
    Tests and repairs the secure channel between the local computer and its Active Directory domain.
    This resolves trust relationship errors that prevent domain authentication.
    
    The script performs the following:
    - Validates required environment variables
    - Verifies computer is domain-joined
    - Tests current secure channel status
    - Repairs secure channel using domain credentials
    - Updates NinjaRMM custom fields with repair status
    
    This script runs unattended without user interaction.

.EXAMPLE
    .\AD-RepairTrust.ps1
    
    Tests and repairs the domain trust relationship using credentials
    from environment variables.

.NOTES
    Script Name:    AD-RepairTrust.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or scheduled
    Typical Duration: ~5-8 seconds (measured average)
    Timeout Setting: 180 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - adTrustRepairStatus (Success/Failed)
        - adTrustRepairDate (timestamp)
        - adDomainName (domain name)
        - adSecureChannelStatus (Functional/Broken)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Computer must be domain-joined
        - Network connectivity to domain controller
    
    Environment Variables Required:
        - user: Domain administrator username
        - pass: Domain administrator password
    
    Exit Codes:
        0 - Success (trust repaired or already functional)
        1 - General error (not domain-joined, repair failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param()

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "AD-RepairTrust"

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
    
    Write-Log "Username: $env:user" -Level INFO
    
    # Verify computer is domain-joined using CIM (not WMI)
    Write-Log "Checking domain membership status" -Level INFO
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    
    if (-not $ComputerSystem.PartOfDomain) {
        throw "Computer is not joined to a domain"
    }
    
    $DomainName = $ComputerSystem.Domain
    Write-Log "Domain: $DomainName" -Level INFO
    Write-Log "Computer Name: $($ComputerSystem.Name)" -Level INFO
    
    # Create secure credential object
    Write-Log "Creating domain credentials" -Level DEBUG
    $SecurePassword = ConvertTo-SecureString -String $env:pass -AsPlainText -Force
    $JoinCred = [PSCredential]::new($env:user, $SecurePassword)
    
    # Test current secure channel status
    Write-Log "Testing current secure channel status" -Level INFO
    $ChannelTest = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
    
    if ($ChannelTest) {
        Write-Log "Secure channel is currently functional" -Level INFO
        Write-Log "Attempting repair anyway as requested" -Level INFO
        Set-NinjaField -FieldName "adSecureChannelStatus" -Value "Functional"
    } else {
        Write-Log "Secure channel is broken - repair needed" -Level WARN
        Set-NinjaField -FieldName "adSecureChannelStatus" -Value "Broken"
    }
    
    # Repair secure channel
    Write-Log "Repairing secure channel with domain controller" -Level INFO
    $RepairResult = Test-ComputerSecureChannel -Repair -Credential $JoinCred -ErrorAction Stop
    
    if ($RepairResult) {
        Write-Log "SUCCESS: Secure channel repaired successfully" -Level SUCCESS
        Write-Log "Trust relationship with domain '$DomainName' is now functional" -Level SUCCESS
        
        # Update NinjaRMM fields
        Set-NinjaField -FieldName "adTrustRepairStatus" -Value "Success"
        Set-NinjaField -FieldName "adTrustRepairDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Set-NinjaField -FieldName "adDomainName" -Value $DomainName
        Set-NinjaField -FieldName "adSecureChannelStatus" -Value "Functional"
    } else {
        throw "Repair operation returned false"
    }
    
    Write-Log "Trust repair operation completed successfully" -Level INFO
    
} catch {
    Write-Log "ERROR: Failed to repair trust relationship - $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    Write-Log "Verify domain admin credentials and domain controller connectivity" -Level ERROR
    Write-Log "If issue persists, consider removing and rejoining the domain" -Level INFO
    
    # Update failure status in NinjaRMM
    Set-NinjaField -FieldName "adTrustRepairStatus" -Value "Failed"
    Set-NinjaField -FieldName "adTrustRepairDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
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
