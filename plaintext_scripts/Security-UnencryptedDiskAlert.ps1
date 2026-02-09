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

.PARAMETER StatusField
    Name of NinjaRMM custom field to store detailed encryption status.

.PARAMETER UnencryptedCountField
    Name of NinjaRMM custom field to store count of unencrypted volumes.

.EXAMPLE
    .\Security-UnencryptedDiskAlert.ps1
    
    Checks encryption status, displays results, exits with code 2 if unencrypted drives found.

.EXAMPLE
    .\Security-UnencryptedDiskAlert.ps1 -StatusField "bitlockerStatus" -UnencryptedCountField "unencryptedDrives"
    
    Checks encryption and saves results to custom fields.

.NOTES
    Script Name:    Security-UnencryptedDiskAlert.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required for BitLocker queries)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~2-5 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - StatusField - Detailed encryption status per volume (if specified)
        - UnencryptedCountField - Count of unencrypted drives (if specified)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges
        - Windows 10 or Server 2016 minimum
        - BitLocker feature installed (TPM not required for detection)
    
    Exit Codes:
        0 - Success (all drives encrypted)
        1 - Failure (execution error)
        2 - Alert (unencrypted drives detected)

.LINK
    https://github.com/Xore/waf

.LINK
    https://docs.microsoft.com/en-us/windows/security/information-protection/bitlocker/
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field for detailed encryption status")]
    [string]$StatusField,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field for unencrypted drive count")]
    [string]$UnencryptedCountField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Security-UnencryptedDiskAlert"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
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

function Get-PhysicalDriveLetters {
    <#
    .SYNOPSIS
        Gets drive letters for physical (non-USB) drives
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
        Gets BitLocker status using Get-BitLockerVolume cmdlet
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
        Gets BitLocker status using manage-bde.exe (fallback)
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
    
    # Check administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required for BitLocker status queries"
    }
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    
    # Get BitLocker status (try modern method first)
    Write-Log "Querying BitLocker status..." -Level INFO
    
    $Volumes = Get-BitLockerStatusModern
    
    if (-not $Volumes) {
        Write-Log "Falling back to manage-bde.exe" -Level INFO
        $Volumes = Get-BitLockerStatusLegacy
    }
    
    if (-not $Volumes) {
        Write-Log "Unable to determine BitLocker status" -Level ERROR
        Write-Log "BitLocker feature may not be installed" -Level WARN
        exit 1
    }
    
    # Analyze encryption status
    Write-Log "" -Level INFO
    Write-Log "BitLocker Volume Status:" -Level INFO
    Write-Log "========================" -Level INFO
    
    $UnencryptedCount = 0
    $StatusDetails = New-Object System.Collections.Generic.List[String]
    
    foreach ($Volume in $Volumes) {
        $IsUnencrypted = ($Volume.LockStatus -eq "Unlocked" -and $Volume.VolumeStatus -eq "FullyDecrypted")
        
        $Status = if ($IsUnencrypted) { "UNENCRYPTED" } else { "ENCRYPTED" }
        $StatusSymbol = if ($IsUnencrypted) { "[!]" } else { "[OK]" }
        
        if ($IsUnencrypted) {
            $UnencryptedCount++
            Write-Log "$StatusSymbol $($Volume.MountPoint) - $Status (Lock: $($Volume.LockStatus), Volume: $($Volume.VolumeStatus))" -Level WARN
        } else {
            Write-Log "$StatusSymbol $($Volume.MountPoint) - $Status (Lock: $($Volume.LockStatus), Volume: $($Volume.VolumeStatus))" -Level SUCCESS
        }
        
        $StatusDetails.Add("$($Volume.MountPoint): $Status")
    }
    
    # Summary
    Write-Log "" -Level INFO
    Write-Log "Encryption Summary:" -Level INFO
    Write-Log "  Total Volumes: $($Volumes.Count)" -Level INFO
    Write-Log "  Unencrypted: $UnencryptedCount" -Level INFO
    Write-Log "  Encrypted: $($Volumes.Count - $UnencryptedCount)" -Level INFO
    
    # Update custom fields if specified
    if ($StatusField) {
        $StatusString = $StatusDetails -join ", "
        Set-NinjaField -FieldName $StatusField -Value $StatusString
        Write-Log "Status saved to field: $StatusField" -Level SUCCESS
    }
    
    if ($UnencryptedCountField) {
        Set-NinjaField -FieldName $UnencryptedCountField -Value $UnencryptedCount
        Write-Log "Unencrypted count saved to field: $UnencryptedCountField" -Level SUCCESS
    }
    
    # Exit with appropriate code
    if ($UnencryptedCount -gt 0) {
        Write-Log "" -Level INFO
        Write-Log "ALERT: $UnencryptedCount unencrypted drive(s) detected" -Level ERROR
        Write-Log "Exiting with code 2 (non-compliant)" -Level INFO
        exit 2
    } else {
        Write-Log "" -Level INFO
        Write-Log "All drives are encrypted (compliant)" -Level SUCCESS
        exit 0
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
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}
