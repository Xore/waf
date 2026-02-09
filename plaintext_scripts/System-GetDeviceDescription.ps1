#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Retrieves the Windows device description from operating system properties

.DESCRIPTION
    Simple utility script that queries the Win32_OperatingSystem WMI/CIM class
    to retrieve the device description field. This field typically contains
    custom text set by administrators to identify the device purpose or location.
    
    The script performs the following:
    - Checks for administrator privileges
    - Queries Win32_OperatingSystem for Description property
    - Handles empty/null descriptions gracefully
    - Optionally saves result to NinjaRMM custom field
    - Provides clear output for monitoring
    
    Device descriptions are useful for inventory management, asset tracking,
    and identifying system roles in larger environments.

.PARAMETER CustomField
    Name of NinjaRMM custom field to store the device description.
    If not specified, the description is only displayed.

.EXAMPLE
    .\System-GetDeviceDescription.ps1
    
    Retrieves and displays the current device description.

.EXAMPLE
    .\System-GetDeviceDescription.ps1 -CustomField "deviceDescription"
    
    Retrieves device description and saves it to custom field.

.NOTES
    Script Name:    System-GetDeviceDescription.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required for WMI/CIM access)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~1 second
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomField - Device description (if specified)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges
        - Windows 10 or Server 2016 minimum
        - WMI/CIM service running
    
    Environment Variables (Optional):
        - nameOfCustomField: Override -CustomField parameter
    
    Exit Codes:
        0 - Success (description retrieved)
        1 - Failure (access denied or query failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field to store device description")]
    [string]$CustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "System-GetDeviceDescription"

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
    
    Write-Output $LogMessage
    
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
        Checks if script is running with Administrator privileges
    #>
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-DeviceDescription {
    <#
    .SYNOPSIS
        Retrieves device description from Win32_OperatingSystem
    #>
    try {
        Write-Log "Querying Win32_OperatingSystem for device description" -Level DEBUG
        
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        
        if ($OS.Description) {
            $Description = $OS.Description.Trim()
            Write-Log "Device description retrieved: '$Description'" -Level SUCCESS
            return $Description
        } else {
            Write-Log "Device description is empty" -Level WARN
            return $null
        }
        
    } catch {
        Write-Log "Failed to query device description: $($_.Exception.Message)" -Level ERROR
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
    
    # Check for environment variable override
    if ($env:nameOfCustomField -and $env:nameOfCustomField -notlike "null") {
        $CustomField = $env:nameOfCustomField.Trim()
        Write-Log "CustomField from environment: $CustomField" -Level INFO
    }
    
    # Validate custom field parameter
    if ($CustomField) {
        $CustomField = $CustomField.Trim()
        
        if ([string]::IsNullOrWhiteSpace($CustomField)) {
            throw "CustomField parameter is empty after trimming"
        }
        
        Write-Log "Custom field specified: $CustomField" -Level INFO
    }
    
    # Check administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required. Please run as Administrator."
    }
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    
    # Retrieve device description
    $Description = Get-DeviceDescription
    
    # Prepare output value
    if ($Description) {
        Write-Log "Current device description: '$Description'" -Level INFO
        $OutputValue = $Description
    } else {
        Write-Log "No device description is currently set" -Level WARN
        $OutputValue = "No device description is currently set"
    }
    
    # Update custom field if specified
    if ($CustomField) {
        Write-Log "Updating custom field: $CustomField" -Level INFO
        Set-NinjaField -FieldName $CustomField -Value $OutputValue
        Write-Log "Custom field updated successfully" -Level SUCCESS
    }
    
    Write-Log "Device description retrieval completed" -Level SUCCESS
    exit 0
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    if ($CustomField) {
        Set-NinjaField -FieldName $CustomField -Value "Error: $($_.Exception.Message)"
    }
    
    exit 1
    
} finally {
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
