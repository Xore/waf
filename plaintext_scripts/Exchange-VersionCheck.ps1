#Requires -Version 5.1

<#
.SYNOPSIS
    Detects installed Microsoft Exchange Server version and build number

.DESCRIPTION
    Queries the system registry to identify if Microsoft Exchange Server is installed
    and reports the version, build number, and cumulative update level. This information
    is critical for patch management, security compliance, and inventory tracking.
    
    The script performs the following:
    - Checks for Exchange Server installation via registry keys
    - Identifies Exchange version (2013, 2016, 2019)
    - Retrieves full build number (major.minor.build.revision)
    - Determines product name based on version numbers
    - Optionally saves version information to NinjaRMM custom fields
    - Reports if Exchange is not installed on the system
    
    Knowing the exact Exchange version helps administrators ensure systems are
    up-to-date with security patches, plan upgrades, and maintain compliance.
    
    This script runs unattended without user interaction.

.PARAMETER SaveToCustomField
    Optional name of NinjaRMM custom field to save Exchange version information.
    Must be a valid custom field name (max 200 characters).
    Format saved: "Exchange Server 2019 - Version: 15.2.1118.7"

.EXAMPLE
    .\Exchange-VersionCheck.ps1
    
    Detects Exchange Server and displays version to console.

.EXAMPLE
    .\Exchange-VersionCheck.ps1 -SaveToCustomField "ExchangeVersion"
    
    Detects Exchange Server and saves version to specified custom field.

.NOTES
    Script Name:    Exchange-VersionCheck.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or Administrator
    Execution Frequency: Daily or on-demand
    Typical Duration: ~1-2 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - SaveToCustomField (if specified) - Exchange version and build
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Registry access for Exchange detection
        - Must run on Exchange Server (or reports not installed)
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - saveToCustomField: Alternative to -SaveToCustomField parameter
    
    Exit Codes:
        0 - Success (Exchange detected or not installed)
        1 - Failure (custom field update failed or detection error)

.LINK
    https://github.com/Xore/waf
    https://learn.microsoft.com/en-us/exchange/new-features/build-numbers-and-release-dates
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save Exchange version")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$SaveToCustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Exchange-VersionCheck"

# Support NinjaRMM environment variable
if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
    $SaveToCustomField = $env:saveToCustomField
}

# Trim whitespace from parameter
if ($SaveToCustomField) {
    $SaveToCustomField = $SaveToCustomField.Trim()
}

# Exchange registry path
$ExchangeRegistryPath = "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$script:ExitCode = 0
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

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
            $script:ExitCode = 1
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
    
    Write-Log "Detecting Exchange Server installation..." -Level INFO
    
    # Check if Exchange registry key exists
    if (Test-Path -Path $ExchangeRegistryPath) {
        Write-Log "Exchange registry key found" -Level DEBUG
        
        # Read Exchange installation information
        $ExchangeInfo = Get-ItemProperty -Path $ExchangeRegistryPath -ErrorAction Stop
        
        # Extract version components
        $MajorVersion = $ExchangeInfo.MsiProductMajor
        $BuildMajor = $ExchangeInfo.MsiBuildMajor
        $BuildMinor = $ExchangeInfo.MsiBuildMinor
        $FullVersion = "$MajorVersion.$BuildMajor.$BuildMinor"
        
        # Determine product name based on version
        $ProductName = switch ($MajorVersion) {
            15 {
                if ($BuildMajor -ge 2000) {
                    "Exchange Server 2019"
                } elseif ($BuildMajor -ge 1000) {
                    "Exchange Server 2016"
                } else {
                    "Exchange Server 2013"
                }
            }
            14 {
                "Exchange Server 2010"
            }
            8 {
                "Exchange Server 2007"
            }
            default {
                "Exchange Server (Unknown Version $MajorVersion)"
            }
        }
        
        Write-Log "" -Level INFO
        Write-Log "Exchange Server Detected: $ProductName" -Level SUCCESS
        Write-Log "Full Version: $FullVersion" -Level INFO
        Write-Log "  Major Version: $MajorVersion" -Level INFO
        Write-Log "  Build: $BuildMajor.$BuildMinor" -Level INFO
        
        # Format output for custom field
        $Output = "$ProductName - Version: $FullVersion"
        
        # Save to custom field if specified
        if ($SaveToCustomField) {
            Set-NinjaField -FieldName $SaveToCustomField -Value $Output
            
            if ($script:ExitCode -eq 0) {
                Write-Log "Version saved to custom field '$SaveToCustomField'" -Level SUCCESS
            }
        }
        
        Write-Log "Exchange detection completed successfully" -Level SUCCESS
        
    } else {
        Write-Log "Exchange Server registry key not found" -Level DEBUG
        Write-Log "Exchange Server is not installed on this system" -Level INFO
        
        # Save status to custom field if specified
        if ($SaveToCustomField) {
            Set-NinjaField -FieldName $SaveToCustomField -Value "Not Installed"
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
    
    exit $script:ExitCode
}
