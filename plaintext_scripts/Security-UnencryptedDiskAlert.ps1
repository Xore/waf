#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Monitors and alerts on unencrypted BitLocker volumes across physical drives

.DESCRIPTION
    Security compliance script that identifies physical disk volumes lacking BitLocker
    encryption. Used for continuous monitoring of encryption status to ensure data
    protection policies are enforced across managed endpoints.
    
    Detection Methodology:
    The script uses a multi-method approach to detect encryption status:
    
    1. Primary Method (PowerShell 5.1+):
       - Get-BitLockerVolume cmdlet from BitLocker module
       - Provides real-time encryption status
       - Reports protection status and conversion progress
    
    2. Fallback Method (Legacy Systems):
       - manage-bde.exe command-line tool
       - Parses text output to extract volume status
       - Compatible with Windows 7/Server 2012+
    
    3. Volume Filtering:
       - Excludes USB/removable drives (not typically encrypted)
       - Only checks physical fixed drives
       - Validates drive has assigned letter (mounted)
    
    Encryption Status Definitions:
    - FullyDecrypted + Unlocked = Unencrypted (ALERT)
    - FullyEncrypted + Locked = Encrypted and locked (SECURE)
    - FullyEncrypted + Unlocked = Encrypted and accessible (SECURE)
    - EncryptionInProgress = Currently encrypting (ACCEPTABLE)
    - DecryptionInProgress = Currently decrypting (REVIEW)
    
    The script specifically alerts on volumes that are both:
    - LockStatus = "Unlocked" (drive is accessible)
    - VolumeStatus = "FullyDecrypted" (no encryption applied)
    
    Exit Code Strategy:
    - 0 = All physical drives are encrypted (COMPLIANT)
    - 1 = Execution error (privilege/cmdlet/permission issue)
    - 2 = Unencrypted drives detected (NON-COMPLIANT)
    
    This allows RMM platforms to trigger alerts and remediation workflows when
    exit code 2 is returned, indicating a security compliance violation.
    
    Use Cases:
    - Compliance monitoring (HIPAA, PCI-DSS, GDPR requirements)
    - Security baseline verification
    - Encryption policy enforcement
    - Audit trail generation
    - Alert triggering for unencrypted endpoints
    
    This script runs unattended without user interaction.

.PARAMETER StatusField
    Optional name of NinjaRMM custom field to store detailed encryption status.
    Must be a valid custom field name (max 200 characters).

.PARAMETER UnencryptedCountField
    Optional name of NinjaRMM custom field to store count of unencrypted volumes.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\Security-UnencryptedDiskAlert.ps1
    
    Checks encryption status, displays results, exits with code 2 if unencrypted drives found.

.EXAMPLE
    .\Security-UnencryptedDiskAlert.ps1 -StatusField "bitlockerStatus" -UnencryptedCountField "unencryptedDrives"
    
    Checks encryption and saves results to custom fields.

.OUTPUTS
    None. Encryption status is written to console and optionally to custom fields.

.NOTES
    Script Name:    Security-UnencryptedDiskAlert.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-05
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required)
    Execution Frequency: Daily or on-demand
    Typical Duration: 2-5 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - StatusField (if specified) - Detailed encryption status per volume
        - UnencryptedCountField (if specified) - Count of unencrypted drives
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Windows 10, Windows Server 2016 or higher
        - BitLocker feature installed (TPM not required for detection)
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - statusField: Alternative to -StatusField parameter
        - unencryptedCountField: Alternative to -UnencryptedCountField parameter
    
    Exit Codes:
        0 - Success (all drives encrypted, compliant)
        1 - Error (execution failure, check logs)
        2 - Alert (unencrypted drives detected, non-compliant)

.LINK
    https://github.com/Xore/waf

.LINK
    https://docs.microsoft.com/en-us/windows/security/information-protection/bitlocker/
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field for detailed encryption status")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$StatusField,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field for unencrypted drive count")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$UnencryptedCountField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Security-UnencryptedDiskAlert"

# Support NinjaRMM environment variables
if ($env:statusField -and $env:statusField -notlike "null") {
    $StatusField = $env:statusField
}

if ($env:unencryptedCountField -and $env:unencryptedCountField -notlike "null") {
    $UnencryptedCountField = $env:unencryptedCountField
}

# Trim whitespace from parameters
if ($StatusField) { $StatusField = $StatusField.Trim() }
if ($UnencryptedCountField) { $UnencryptedCountField = $UnencryptedCountField.Trim() }

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
    
    # Truncate if exceeds NinjaRMM field limit (10,000 characters)
    if ($ValueString.Length -gt 10000) {
        Write-Log "Field value exceeds 10,000 characters, truncating" -Level WARN
        $ValueString = $ValueString.Substring(0, 9950) + "`n... (truncated)"
    }
    
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

function Test-IsElevated {
    <#
    .SYNOPSIS
        Checks if script is running with administrator privileges
    #>
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PhysicalDriveLetters {
    <#
    .SYNOPSIS
        Retrieves drive letters for physical fixed drives
    #>
    try {
        $PhysicalDrives = Get-Disk | Where-Object { $_.BusType -ne 'USB' -and $_.BusType -ne 'File Backed Virtual' }
        
        $DriveLetters = $PhysicalDrives | Get-Partition | 
            Where-Object { $_.DriveLetter } | 
            Select-Object -ExpandProperty DriveLetter
        
        Write-Log "Found $($DriveLetters.Count) physical drive letter(s)" -Level DEBUG
        return $DriveLetters
        
    } catch {
        Write-Log "Failed to enumerate physical drives: $_" -Level ERROR
        throw
    }
}

function Get-BitLockerStatusModern {
    <#
    .SYNOPSIS
        Gets BitLocker status using modern PowerShell cmdlet
    #>
    try {
        $DriveLetters = Get-PhysicalDriveLetters
        
        if (-not $DriveLetters) {
            Write-Log "No physical drives found" -Level WARN
            return $null
        }
        
        $Results = New-Object System.Collections.Generic.List[Object]
        
        foreach ($Letter in $DriveLetters) {
            try {
                $Volume = Get-BitLockerVolume -MountPoint "${Letter}:" -ErrorAction Stop
                
                $Results.Add([PSCustomObject]@{
                    MountPoint = $Volume.MountPoint
                    LockStatus = $Volume.LockStatus.ToString()
                    VolumeStatus = $Volume.VolumeStatus.ToString()
                    EncryptionPercentage = $Volume.EncryptionPercentage
                    ProtectionStatus = $Volume.ProtectionStatus.ToString()
                })
                
            } catch {
                Write-Log "Failed to query BitLocker status for ${Letter}: - $_" -Level WARN
            }
        }
        
        return $Results
        
    } catch {
        Write-Log "Get-BitLockerVolume failed: $_" -Level WARN
        return $null
    }
}

function Get-BitLockerStatusLegacy {
    <#
    .SYNOPSIS
        Gets BitLocker status using legacy manage-bde.exe
    #>
    try {
        if (-not (Get-Command manage-bde.exe -ErrorAction SilentlyContinue)) {
            Write-Log "manage-bde.exe not found (BitLocker feature not installed)" -Level WARN
            return $null
        }
        
        $DriveLetters = Get-PhysicalDriveLetters
        
        if (-not $DriveLetters) {
            return $null
        }
        
        $Results = New-Object System.Collections.Generic.List[Object]
        
        foreach ($Letter in $DriveLetters) {
            try {
                $Output = manage-bde.exe -status "${Letter}:" 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "manage-bde failed for ${Letter}: (exit code $LASTEXITCODE)" -Level DEBUG
                    continue
                }
                
                $VolumeData = @{
                    MountPoint = "${Letter}:"
                    LockStatus = "Unknown"
                    VolumeStatus = "Unknown"
                }
                
                $Output -split "`n" | ForEach-Object {
                    if ($_ -match '\s*Lock Status\s*:\s*(.+)') {
                        $VolumeData.LockStatus = $Matches[1].Trim()
                    }
                    elseif ($_ -match '\s*Conversion Status\s*:\s*(.+)') {
                        $VolumeData.VolumeStatus = $Matches[1].Trim()
                    }
                }
                
                $Results.Add([PSCustomObject]$VolumeData)
                
            } catch {
                Write-Log "Failed to parse manage-bde output for ${Letter}: - $_" -Level WARN
            }
        }
        
        return $Results
        
    } catch {
        Write-Log "manage-bde.exe query failed: $_" -Level ERROR
        return $null
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for administrator privileges
    if (-not (Test-IsElevated)) {
        Write-Log "ERROR: This script requires administrator privileges" -Level ERROR
        throw "Access Denied"
    }
    
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    Write-Log "Querying BitLocker encryption status for physical drives" -Level INFO
    Write-Log "" -Level INFO
    
    # Try modern cmdlet first
    $Volumes = Get-BitLockerStatusModern
    
    # Fallback to legacy tool if needed
    if (-not $Volumes) {
        Write-Log "Falling back to manage-bde.exe (legacy method)" -Level INFO
        $Volumes = Get-BitLockerStatusLegacy
    }
    
    # Validate we got results
    if (-not $Volumes) {
        Write-Log "ERROR: Unable to determine BitLocker status" -Level ERROR
        Write-Log "BitLocker feature may not be installed on this system" -Level WARN
        throw "BitLocker unavailable"
    }
    
    Write-Log "========================================" -Level INFO
    Write-Log "BITLOCKER VOLUME STATUS" -Level INFO
    Write-Log "========================================" -Level INFO
    
    $UnencryptedCount = 0
    $StatusDetails = New-Object System.Collections.Generic.List[String]
    
    # Analyze each volume
    foreach ($Volume in $Volumes) {
        $IsUnencrypted = ($Volume.LockStatus -eq "Unlocked" -and $Volume.VolumeStatus -eq "FullyDecrypted")
        
        $Status = if ($IsUnencrypted) { "UNENCRYPTED" } else { "ENCRYPTED" }
        $StatusSymbol = if ($IsUnencrypted) { "[!]" } else { "[OK]" }
        $LogLevel = if ($IsUnencrypted) { 'ERROR' } else { 'SUCCESS' }
        
        if ($IsUnencrypted) {
            $UnencryptedCount++
        }
        
        Write-Log "$StatusSymbol Volume $($Volume.MountPoint)" -Level $LogLevel
        Write-Log "    Status: $Status" -Level INFO
        Write-Log "    Lock: $($Volume.LockStatus)" -Level INFO
        Write-Log "    Encryption: $($Volume.VolumeStatus)" -Level INFO
        Write-Log "" -Level INFO
        
        $StatusDetails.Add("$($Volume.MountPoint): $Status")
    }
    
    # Summary
    Write-Log "========================================" -Level INFO
    Write-Log "ENCRYPTION SUMMARY" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "Total Volumes Checked: $($Volumes.Count)" -Level INFO
    Write-Log "Encrypted Volumes: $($Volumes.Count - $UnencryptedCount)" -Level SUCCESS
    Write-Log "Unencrypted Volumes: $UnencryptedCount" -Level $(if ($UnencryptedCount -gt 0) { 'ERROR' } else { 'INFO' })
    Write-Log "" -Level INFO
    
    # Save to custom fields
    if ($StatusField) {
        $StatusString = $StatusDetails -join ", "
        Set-NinjaField -FieldName $StatusField -Value $StatusString
        Write-Log "Status saved to field: $StatusField" -Level DEBUG
    }
    
    if ($UnencryptedCountField) {
        Set-NinjaField -FieldName $UnencryptedCountField -Value $UnencryptedCount
        Write-Log "Unencrypted count saved to field: $UnencryptedCountField" -Level DEBUG
    }
    
    # Determine compliance status
    if ($UnencryptedCount -gt 0) {
        Write-Log "ALERT: $UnencryptedCount unencrypted drive(s) detected" -Level ERROR
        Write-Log "COMPLIANCE STATUS: NON-COMPLIANT" -Level ERROR
        Write-Log "RECOMMENDATION: Enable BitLocker encryption immediately" -Level WARN
        $script:ExitCode = 2
    } else {
        Write-Log "SUCCESS: All physical drives are encrypted" -Level SUCCESS
        Write-Log "COMPLIANCE STATUS: COMPLIANT" -Level SUCCESS
        $script:ExitCode = 0
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
    
    # Exit code meanings
    switch ($script:ExitCode) {
        0 { Write-Log "  Status: COMPLIANT (all drives encrypted)" -Level INFO }
        1 { Write-Log "  Status: ERROR (execution failed)" -Level INFO }
        2 { Write-Log "  Status: NON-COMPLIANT (unencrypted drives found)" -Level INFO }
    }
    
    Write-Log "========================================" -Level INFO
    
    # Cleanup
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit $script:ExitCode
}
