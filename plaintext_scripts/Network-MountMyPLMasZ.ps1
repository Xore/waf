#Requires -Version 5.1

<#
.SYNOPSIS
    Maps a network drive to a specified UNC path

.DESCRIPTION
    Maps a network share to a drive letter, typically used for mounting
    PLM (Product Lifecycle Management) or other shared network resources.
    
    The script performs the following:
    - Validates the UNC path format
    - Removes existing drive mapping if present
    - Creates new network drive mapping
    - Verifies the mapping was successful
    - Optionally saves mapping status to NinjaRMM custom fields
    - Supports persistent mappings that survive reboots
    
    This script is useful for:
    - Automated drive mapping in login scripts
    - Ensuring consistent drive letter assignments
    - Troubleshooting network connectivity
    - Standardizing access to shared resources
    
    This script runs unattended without user interaction.

.PARAMETER DriveLetter
    Drive letter to map (A-Z).
    Default: 'Z'

.PARAMETER UNCPath
    UNC path to the network share (e.g., \\server\share).
    Default: '\\de.mgp.int\FS\myPLM'

.PARAMETER Persistent
    Make the drive mapping persistent across reboots.
    Default: $false

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save mapping status.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\Network-MountMyPLMasZ.ps1
    
    Maps \\de.mgp.int\FS\myPLM to drive Z: (non-persistent).

.EXAMPLE
    .\Network-MountMyPLMasZ.ps1 -DriveLetter 'P' -UNCPath '\\server\shared' -Persistent
    
    Maps \\server\shared to drive P: with persistent mapping.

.EXAMPLE
    .\Network-MountMyPLMasZ.ps1 -CustomFieldName "DriveMapStatus"
    
    Maps drive and saves status to 'DriveMapStatus' custom field.

.OUTPUTS
    None. Mapping status is written to console and optionally to custom field.

.NOTES
    Script Name:    Network-MountMyPLMasZ.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: User or SYSTEM
    Execution Frequency: On-demand or at logon
    Typical Duration: ~1-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName (if specified) - Drive mapping status
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Network access to UNC path
        - Appropriate permissions on network share
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - driveLetter: Alternative to -DriveLetter parameter
        - uncPath: Alternative to -UNCPath parameter
        - persistent: Alternative to -Persistent parameter
        - customFieldName: Alternative to -CustomFieldName parameter
    
    Exit Codes:
        0 - Success (drive mapped successfully)
        1 - Failure (mapping failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Drive letter to map (A-Z)")]
    [ValidatePattern('^[A-Za-z]$')]
    [string]$DriveLetter = 'Z',
    
    [Parameter(Mandatory=$false, HelpMessage="UNC path to network share")]
    [ValidatePattern('^\\\\[^\\]+\\[^\\]+(\\.*)?$')]
    [string]$UNCPath = '\\de.mgp.int\FS\myPLM',
    
    [Parameter(Mandatory=$false, HelpMessage="Make mapping persistent across reboots")]
    [switch]$Persistent,
    
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save mapping status")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Network-MountMyPLMasZ"

# Support NinjaRMM environment variables
if ($env:driveLetter -and $env:driveLetter -notlike "null") {
    $DriveLetter = $env:driveLetter
}

if ($env:uncPath -and $env:uncPath -notlike "null") {
    $UNCPath = $env:uncPath
}

if ($env:persistent -and $env:persistent -notlike "null") {
    $Persistent = [bool]::Parse($env:persistent)
}

if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

# Trim whitespace and ensure uppercase for drive letter
$DriveLetter = $DriveLetter.Trim().ToUpper()
$UNCPath = $UNCPath.Trim()
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

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    Write-Log "Mapping network drive..." -Level INFO
    Write-Log "  Drive Letter: $DriveLetter`:" -Level INFO
    Write-Log "  UNC Path: $UNCPath" -Level INFO
    Write-Log "  Persistent: $Persistent" -Level INFO
    Write-Log "" -Level INFO
    
    # Check if drive letter is already in use
    $ExistingDrive = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue
    
    if ($ExistingDrive) {
        Write-Log "Drive $DriveLetter`: is already mapped to: $($ExistingDrive.DisplayRoot)" -Level WARN
        
        # If it's mapped to the same path, consider it success
        if ($ExistingDrive.DisplayRoot -eq $UNCPath) {
            Write-Log "Drive is already mapped to the correct path" -Level INFO
            
            if ($CustomFieldName) {
                Set-NinjaField -FieldName $CustomFieldName -Value "Drive $DriveLetter`: already mapped to $UNCPath"
            }
            
        } else {
            Write-Log "Removing existing drive mapping..." -Level INFO
            try {
                Remove-PSDrive -Name $DriveLetter -Force -ErrorAction Stop
                Write-Log "Existing mapping removed" -Level INFO
            } catch {
                Write-Log "Failed to remove existing mapping: $($_.Exception.Message)" -Level ERROR
                throw
            }
        }
    }
    
    # Create the drive mapping
    if (-not $ExistingDrive -or $ExistingDrive.DisplayRoot -ne $UNCPath) {
        Write-Log "Creating drive mapping..." -Level INFO
        
        try {
            # Use New-PSDrive for PowerShell-only mapping
            $NewDrive = New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root $UNCPath -Persist:$Persistent -ErrorAction Stop
            
            Write-Log "Drive mapped successfully!" -Level SUCCESS
            Write-Log "  Drive: $($NewDrive.Name):" -Level INFO
            Write-Log "  Root: $($NewDrive.Root)" -Level INFO
            Write-Log "  Provider: $($NewDrive.Provider)" -Level INFO
            
            # Verify the mapping works by testing path access
            if (Test-Path "${DriveLetter}:\") {
                Write-Log "Drive accessibility verified" -Level SUCCESS
                
                if ($CustomFieldName) {
                    $Status = "Drive $DriveLetter`: successfully mapped to $UNCPath"
                    if ($Persistent) {
                        $Status += " (persistent)"
                    }
                    Set-NinjaField -FieldName $CustomFieldName -Value $Status
                }
            } else {
                Write-Log "WARNING: Drive mapped but path not accessible" -Level WARN
            }
            
        } catch {
            Write-Log "Failed to map drive: $($_.Exception.Message)" -Level ERROR
            
            if ($CustomFieldName) {
                Set-NinjaField -FieldName $CustomFieldName -Value "Failed to map drive $DriveLetter`: to $UNCPath - $($_.Exception.Message)"
            }
            
            $script:ExitCode = 1
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
    
    exit $script:ExitCode
}
