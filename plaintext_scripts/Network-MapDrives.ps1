#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Discovers and reports all mapped network drives across user profiles

.DESCRIPTION
    Scans registry for mapped network drives across all user profiles and reports
    the mappings with associated usernames, drive letters, and UNC paths.
    
    The script performs the following:
    - Scans HKEY_USERS registry for network drive mappings
    - Translates SIDs to usernames
    - Compiles list of all mapped drives per user
    - Reports findings to NinjaRMM custom field
    - Handles cases with no mapped drives
    
    This script runs unattended without user interaction.

.PARAMETER CustomField
    Name of NinjaRMM custom field to store mapped drive report.
    Default: "networkDrives"

.PARAMETER OutputFormat
    Format for output display.
    Valid values: List, Table
    Default: List

.EXAMPLE
    .\Network-MapDrives.ps1
    
    Scans for mapped drives and reports to default field.

.EXAMPLE
    .\Network-MapDrives.ps1 -CustomField "mappedDrives"
    
    Scans and reports to specified custom field.

.EXAMPLE
    .\Network-MapDrives.ps1 -OutputFormat Table
    
    Displays results in table format.

.NOTES
    Script Name:    Network-MapDrives.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~1-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - networkDrives (or CustomField) - Mapped drive report
        - mappedDrivesStatus (Success/NoDrives/Failed)
        - mappedDrivesCount (number of drives found)
        - mappedDrivesDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Registry access permissions
    
    Environment Variables (Optional):
        - customFieldName: Override -CustomField parameter
        - outputFormat: Override -OutputFormat parameter
    
    Exit Codes:
        0 - Success (scan completed, with or without drives found)
        1 - Failure (registry access denied or script error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name for drive report")]
    [ValidateNotNullOrEmpty()]
    [string]$CustomField = "networkDrives",
    
    [Parameter(Mandatory=$false, HelpMessage="Output format for display")]
    [ValidateSet('List','Table')]
    [string]$OutputFormat = 'List'
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Network-MapDrives"

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

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable overrides
    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomField = $env:customFieldName
        Write-Log "Using custom field from environment: $CustomField" -Level INFO
    }
    
    if ($env:outputFormat -and $env:outputFormat -notlike "null") {
        $OutputFormat = $env:outputFormat
        Write-Log "Using output format from environment: $OutputFormat" -Level INFO
    }
    
    Write-Log "Output format: $OutputFormat" -Level INFO
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required to access user registry hives"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # Scan registry for mapped drives
    Write-Log "Scanning registry for mapped network drives" -Level INFO
    
    try {
        $RegistryDrives = Get-ItemProperty "Registry::HKEY_USERS\*\Network\*" -ErrorAction Stop
    } catch {
        Write-Log "No mapped drives found in registry" -Level INFO
        $RegistryDrives = $null
    }
    
    # Process found drives
    if ($RegistryDrives) {
        Write-Log "Processing mapped drive entries" -Level INFO
        
        $MappedDrives = foreach ($Drive in $RegistryDrives) {
            try {
                # Extract SID from registry path
                $SID = ($Drive.PSParentPath -split '\\')[2]
                Write-Log "Processing drive for SID: $SID" -Level DEBUG
                
                # Translate SID to username
                try {
                    $Username = ([System.Security.Principal.SecurityIdentifier]$SID).Translate([System.Security.Principal.NTAccount]).Value
                } catch {
                    Write-Log "Failed to translate SID $SID to username" -Level WARN
                    $Username = $SID
                }
                
                # Create drive mapping object
                [PSCustomObject]@{
                    Username    = $Username
                    DriveLetter = $Drive.PSChildName
                    RemotePath  = $Drive.RemotePath
                    SID         = $SID
                }
                
                Write-Log "Found drive: $Username - $($Drive.PSChildName) -> $($Drive.RemotePath)" -Level INFO
                
            } catch {
                Write-Log "Error processing drive entry: $_" -Level ERROR
            }
        }
        
        # Check if any drives were successfully processed
        if (-not $MappedDrives) {
            Write-Log "No valid mapped drives found after processing" -Level WARN
            
            $ReportText = "No mapped network drives found"
            Set-NinjaField -FieldName $CustomField -Value $ReportText
            Set-NinjaField -FieldName "mappedDrivesStatus" -Value "NoDrives"
            Set-NinjaField -FieldName "mappedDrivesCount" -Value 0
            Set-NinjaField -FieldName "mappedDrivesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            Write-Log $ReportText -Level INFO
            exit 0
        }
        
        $DriveCount = ($MappedDrives | Measure-Object).Count
        Write-Log "Found $DriveCount mapped network drive(s)" -Level SUCCESS
        
        # Format output
        $OutputText = switch ($OutputFormat) {
            'Table' {
                $MappedDrives | Sort-Object Username, DriveLetter | Format-Table -AutoSize | Out-String
            }
            'List' {
                $Lines = foreach ($Drive in ($MappedDrives | Sort-Object Username, DriveLetter)) {
                    "User: $($Drive.Username) - Drive: $($Drive.DriveLetter): - Path: $($Drive.RemotePath)"
                }
                $Lines -join "`n"
            }
        }
        
        # Display report
        Write-Log "Mapped Network Drives:" -Level INFO
        Write-Log $OutputText -Level INFO
        
        # Update NinjaRMM fields
        Set-NinjaField -FieldName $CustomField -Value $OutputText
        Set-NinjaField -FieldName "mappedDrivesStatus" -Value "Success"
        Set-NinjaField -FieldName "mappedDrivesCount" -Value $DriveCount
        Set-NinjaField -FieldName "mappedDrivesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        Write-Log "Mapped drive report stored in field: $CustomField" -Level SUCCESS
        
    } else {
        Write-Log "No mapped network drives found" -Level INFO
        
        $ReportText = "No mapped network drives found"
        Set-NinjaField -FieldName $CustomField -Value $ReportText
        Set-NinjaField -FieldName "mappedDrivesStatus" -Value "NoDrives"
        Set-NinjaField -FieldName "mappedDrivesCount" -Value 0
        Set-NinjaField -FieldName "mappedDrivesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        Write-Log $ReportText -Level INFO
    }
    
    Write-Log "Mapped drive scan completed successfully" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    # Update failure status
    Set-NinjaField -FieldName "mappedDrivesStatus" -Value "Failed"
    Set-NinjaField -FieldName "mappedDrivesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
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
