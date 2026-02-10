#Requires -Version 5.1

<#
.SYNOPSIS
    Detects USB drives and alerts when present

.DESCRIPTION
    Monitors the system for connected USB drives and generates alerts when detected.
    Provides detailed information about each USB drive including caption, serial number,
    partition count, drive letters, health status, and capacity.
    
    The script performs the following:
    - Scans for USB drives connected to the system
    - Retrieves drive properties (model, serial, partitions)
    - Identifies drive letters and volumes for each USB device
    - Reports drive health status and capacity information
    - Optionally saves formatted results to NinjaRMM custom fields
    - Exits with code 1 if USB drives are found (alert condition)
    - Exits with code 0 if no USB drives are present
    
    This script is useful for security monitoring, compliance checking, and
    preventing unauthorized data transfers via USB storage devices.
    
    This script runs unattended without user interaction.

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save USB drive information.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\Hardware-USBDriveAlert.ps1
    
    Detects USB drives and displays results to console.
    Exits with code 1 if USB drives found, code 0 if none found.

.EXAMPLE
    .\Hardware-USBDriveAlert.ps1 -CustomFieldName "USBDriveStatus"
    
    Detects USB drives and saves formatted results to specified custom field.

.NOTES
    Script Name:    Hardware-USBDriveAlert.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or Administrator
    Execution Frequency: On-demand or scheduled (e.g., every 15 minutes)
    Typical Duration: ~2-5 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName (if specified) - Formatted USB drive information
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - WMI/CIM access for disk queries
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - customFieldName: Alternative to -CustomFieldName parameter
    
    Exit Codes:
        0 - Success (no USB drives detected)
        1 - Alert (USB drive(s) detected)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save USB drive information")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Hardware-USBDriveAlert"

# Support NinjaRMM environment variable
if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

# Trim whitespace from parameter
if ($CustomFieldName) {
    $CustomFieldName = $CustomFieldName.Trim()
}

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
    
    Write-Log "Scanning for USB drives..." -Level INFO
    
    # Query for USB drives using CIM (PowerShell 5.1+)
    $USBDrives = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction Stop | 
        Where-Object { $_.InterfaceType -eq 'USB' }
    
    if ($USBDrives) {
        $DriveCount = @($USBDrives).Count
        Write-Log "ALERT: $DriveCount USB drive(s) detected!" -Level WARN
        Write-Log "" -Level INFO
        
        $Report = New-Object System.Collections.Generic.List[String]
        $Report.Add("USB DRIVE ALERT - $DriveCount device(s) detected")
        $Report.Add("")
        
        $DriveIndex = 1
        foreach ($Drive in $USBDrives) {
            Write-Log "Drive $DriveIndex of $DriveCount:" -Level INFO
            Write-Log "  Index: $($Drive.Index)" -Level INFO
            Write-Log "  Caption: $($Drive.Caption)" -Level INFO
            Write-Log "  Serial Number: $($Drive.SerialNumber)" -Level INFO
            Write-Log "  Partitions: $($Drive.Partitions)" -Level INFO
            
            $Report.Add("Drive $DriveIndex:")
            $Report.Add("  Index: $($Drive.Index)")
            $Report.Add("  Caption: $($Drive.Caption)")
            $Report.Add("  Serial Number: $($Drive.SerialNumber)")
            $Report.Add("  Partitions: $($Drive.Partitions)")
            
            # Get volume information for this drive
            try {
                $Partitions = Get-Partition -DiskNumber $Drive.Index -ErrorAction SilentlyContinue
                if ($Partitions) {
                    foreach ($Partition in $Partitions) {
                        try {
                            $Volume = Get-Volume -Partition $Partition -ErrorAction SilentlyContinue
                            if ($Volume) {
                                $DriveLetter = if ($Volume.DriveLetter) { $Volume.DriveLetter } else { "(No letter)" }
                                $SizeGB = [math]::Round($Volume.Size / 1GB, 2)
                                $RemainingGB = [math]::Round($Volume.SizeRemaining / 1GB, 2)
                                
                                Write-Log "  Volume: $DriveLetter" -Level INFO
                                Write-Log "    Name: $($Volume.FriendlyName)" -Level INFO
                                Write-Log "    Type: $($Volume.DriveType)" -Level INFO
                                Write-Log "    Health: $($Volume.HealthStatus)" -Level INFO
                                Write-Log "    Size: $SizeGB GB" -Level INFO
                                Write-Log "    Free: $RemainingGB GB" -Level INFO
                                
                                $Report.Add("  Volume: $DriveLetter")
                                $Report.Add("    Name: $($Volume.FriendlyName)")
                                $Report.Add("    Type: $($Volume.DriveType)")
                                $Report.Add("    Health: $($Volume.HealthStatus)")
                                $Report.Add("    Size: $SizeGB GB")
                                $Report.Add("    Free: $RemainingGB GB")
                            }
                        } catch {
                            Write-Log "  Failed to get volume info: $($_.Exception.Message)" -Level DEBUG
                        }
                    }
                }
            } catch {
                Write-Log "  Failed to get partition info: $($_.Exception.Message)" -Level DEBUG
            }
            
            Write-Log "" -Level INFO
            $Report.Add("")
            $DriveIndex++
        }
        
        # Save to custom field if specified
        if ($CustomFieldName) {
            $FormattedReport = $Report -join "`n"
            Set-NinjaField -FieldName $CustomFieldName -Value $FormattedReport
            Write-Log "Results saved to custom field '$CustomFieldName'" -Level INFO
        }
        
        # Set exit code to 1 to indicate alert condition
        $script:ExitCode = 1
        Write-Log "USB drive detection completed - ALERT CONDITION" -Level WARN
        
    } else {
        Write-Log "No USB drives detected" -Level SUCCESS
        
        # Save to custom field if specified
        if ($CustomFieldName) {
            Set-NinjaField -FieldName $CustomFieldName -Value "No USB drives detected"
            Write-Log "Status saved to custom field '$CustomFieldName'" -Level INFO
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
