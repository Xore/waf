<#
.SYNOPSIS
    Brief one-line description of what the script does

.DESCRIPTION
    Detailed description of the script's purpose, functionality, and behavior.
    Include information about what the script monitors, calculates, or reports.
    Mention any important dependencies or requirements.

.PARAMETER ParameterName
    Description of the parameter (if the script accepts parameters)

.EXAMPLE
    Example usage of the script
    PS> .\ScriptName.ps1
    
.EXAMPLE
    Additional example with parameters
    PS> .\ScriptName.ps1 -ParameterName "Value"

.NOTES
    Script Name:    ScriptName.ps1
    Author:         Windows Automation Framework
    Version:        1.0
    Creation Date:  YYYY-MM-DD
    Last Modified:  YYYY-MM-DD
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: [Daily/Weekly/On-demand/etc.]
    Typical Duration: ~XX seconds
    Timeout Setting: XXX seconds
    
    Fields Updated:
        - fieldName1 (description)
        - fieldName2 (description)
        - fieldName3 (description)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM agent installed
        - [Any other required modules or features]
    
    Exit Codes:
        0 - Success
        1 - General error
        2 - Missing dependencies
        3 - Permission denied
        4 - Timeout
    
.LINK
    https://github.com/Xore/waf
    
.LINK
    Related documentation or script references
#>

[CmdletBinding()]
param(
    # Define parameters here if needed
    # [Parameter(Mandatory=$false)]
    # [string]$ParameterName = "DefaultValue"
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURATION
# ============================================================================

# Script version
$ScriptVersion = "1.0"

# Logging configuration
$LogLevel = "INFO"  # DEBUG, INFO, WARN, ERROR
$VerbosePreference = 'SilentlyContinue'  # Change to 'Continue' for debug

# Timeouts and limits
$DefaultTimeout = 300  # 5 minutes
$MaxRetries = 3

# NinjaRMM CLI path
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

# Start timing
$StartTime = Get-Date
$ScriptName = $MyInvocation.MyCommand.Name

# Initialize error tracking
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
        Writes structured log messages
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Output based on level
    switch ($Level) {
        'DEBUG' { if ($LogLevel -eq 'DEBUG') { Write-Verbose $LogMessage } }
        'INFO'  { Write-Host $LogMessage -ForegroundColor Cyan }
        'WARN'  { Write-Warning $LogMessage; $script:WarningCount++ }
        'ERROR' { Write-Error $LogMessage; $script:ErrorCount++ }
    }
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Validates required prerequisites before script execution
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Checking prerequisites..." -Level INFO
    
    try {
        # Check PowerShell version
        $PSVersionRequired = [Version]"5.1"
        $PSVersionCurrent = $PSVersionTable.PSVersion
        if ($PSVersionCurrent -lt $PSVersionRequired) {
            throw "PowerShell version $PSVersionRequired or higher required. Current: $PSVersionCurrent"
        }
        
        # Check if running as administrator
        $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "Script must be run with administrator privileges"
        }
        
        # Check NinjaRMM CLI exists (for fallback)
        if (-not (Test-Path $NinjaRMMCLI)) {
            Write-Log "NinjaRMM CLI not found at: $NinjaRMMCLI" -Level WARN
            Write-Log "Field setting fallback will not be available" -Level WARN
        }
        
        # Add additional prerequisite checks here
        
        Write-Log "Prerequisites validated successfully" -Level INFO
        return $true
        
    } catch {
        Write-Log "Prerequisite check failed: $_" -Level ERROR
        return $false
    }
}

function Get-SafeValue {
    <#
    .SYNOPSIS
        Safely retrieves a value with error handling
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        $DefaultValue = "N/A"
    )
    
    try {
        $Result = & $ScriptBlock
        if ($null -eq $Result -or $Result -eq "") {
            return $DefaultValue
        }
        return $Result
    } catch {
        Write-Log "Error getting value: $_" -Level WARN
        return $DefaultValue
    }
}

function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value with automatic fallback to CLI
    
    .DESCRIPTION
        Attempts to set a NinjaRMM custom field using the Ninja-Property-Set cmdlet.
        If the cmdlet fails (e.g., not available in current context), automatically
        falls back to using the NinjaRMM CLI executable.
        
        This dual approach ensures field setting works in all execution contexts:
        - Ninja-Property-Set: Primary method (when running within NinjaRMM)
        - ninjarmm-cli.exe: Fallback method (when cmdlet unavailable)
    
    .PARAMETER FieldName
        The name of the custom field to set (case-sensitive)
    
    .PARAMETER Value
        The value to set for the field. Null or empty values are skipped.
    
    .EXAMPLE
        Set-NinjaField -FieldName "opsHealthScore" -Value 85
    
    .EXAMPLE
        Set-NinjaField -FieldName "capDiskCFreeGB" -Value 125.5
    
    .NOTES
        The function tracks fallback usage via $script:CLIFallbackCount for monitoring.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    # Validate value is not null or empty
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value provided" -Level DEBUG
        return
    }
    
    # Convert value to string for consistent handling
    $ValueString = $Value.ToString()
    
    # Attempt 1: Try Ninja-Property-Set cmdlet (primary method)
    try {
        # Check if cmdlet exists
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' set to: $ValueString" -Level DEBUG
            return
        } else {
            Write-Log "Ninja-Property-Set cmdlet not available, using CLI fallback" -Level DEBUG
            throw "Cmdlet not found"
        }
        
    } catch {
        Write-Log "Ninja-Property-Set failed for '$FieldName': $_" -Level DEBUG
        Write-Log "Attempting CLI fallback..." -Level DEBUG
        
        # Attempt 2: Fall back to NinjaRMM CLI
        try {
            # Verify CLI exists
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            # Execute CLI command
            # Format: ninjarmm-cli.exe set <field-name> <value>
            $CLIArgs = @("set", $FieldName, $ValueString)
            $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
            
            # Check if CLI execution succeeded
            if ($LASTEXITCODE -ne 0) {
                throw "CLI returned exit code: $LASTEXITCODE. Output: $CLIResult"
            }
            
            Write-Log "Field '$FieldName' set via CLI to: $ValueString" -Level DEBUG
            $script:CLIFallbackCount++
            
        } catch {
            # Both methods failed
            Write-Log "Failed to set field '$FieldName' (both methods): $_" -Level ERROR
            throw
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
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        throw "Prerequisites not met"
    }
    
    # Main script logic goes here
    Write-Log "Executing main logic..." -Level INFO
    
    # Example: Gather data
    # $SomeData = Get-SafeValue { Get-CimInstance Win32_OperatingSystem }
    
    # Example: Calculate metrics
    # $SomeMetric = Calculate-Something $SomeData
    
    # Example: Set fields (with automatic fallback)
    # Set-NinjaField -FieldName "fieldName" -Value $SomeMetric
    
    Write-Log "Script execution completed successfully" -Level INFO
    
} catch {
    Write-Log "Script execution failed: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    exit 1
    
} finally {
    # Calculate execution time
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    # Summary
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $ExecutionTime seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    # Report CLI fallback usage if applicable
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
