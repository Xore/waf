#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Complete removal of PuTTY SSH client from Windows systems

.DESCRIPTION
    Comprehensive uninstallation script that removes all traces of PuTTY from
    Windows systems. PuTTY is a free SSH and telnet client that may need removal
    for security, compliance, or software standardization purposes.
    
    The script performs the following cleanup operations:
    - Removes program files from Program Files directories (x86 and x64)
    - Deletes user configuration and session data from AppData
    - Cleans registry entries (HKCU and HKLM, including WOW6432Node)
    - Removes Start Menu shortcuts from all user locations
    - Attempts to stop any running PuTTY processes
    - Optionally saves configuration backup before removal
    - Reports detailed status of each removal operation
    
    Common PuTTY installation locations checked:
    - C:\Program Files\PuTTY
    - C:\Program Files (x86)\PuTTY
    - %APPDATA%\PuTTY
    - HKCU:\Software\SimonTatham\PuTTY
    - HKLM:\Software\SimonTatham\PuTTY
    
    The script is safe to run even if PuTTY is not installed.

.PARAMETER BackupSettings
    If specified, exports PuTTY registry settings to a backup file before removal.
    Backup is saved to Windows TEMP directory with timestamp.

.PARAMETER StatusField
    Name of NinjaRMM custom field to store uninstallation status.

.EXAMPLE
    .\Software-UninstallPuTTY.ps1
    
    Removes PuTTY with default settings (no backup).

.EXAMPLE
    .\Software-UninstallPuTTY.ps1 -BackupSettings
    
    Backs up PuTTY configuration before uninstallation.

.EXAMPLE
    .\Software-UninstallPuTTY.ps1 -StatusField "puttyRemovalStatus"
    
    Removes PuTTY and saves status to custom field.

.NOTES
    Script Name:    Software-UninstallPuTTY.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required for complete removal)
    Execution Frequency: On-demand (software removal)
    Typical Duration: ~5-10 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - StatusField - Uninstallation status and summary (if specified)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges
        - Windows 10 or Server 2016 minimum
    
    Software Removed:
        - PuTTY (all versions)
        - Associated configuration files
        - Registry entries
        - Start Menu shortcuts
    
    Exit Codes:
        0 - Success (PuTTY removed or not found)
        1 - Failure (partial removal or errors occurred)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Backup PuTTY settings before removal")]
    [switch]$BackupSettings,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field for uninstallation status")]
    [string]$StatusField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Software-UninstallPuTTY"

# PuTTY locations
$ProgramPaths = @(
    "$env:ProgramFiles\PuTTY",
    "${env:ProgramFiles(x86)}\PuTTY"
)

$AppDataPaths = @(
    "$env:APPDATA\PuTTY",
    "$env:LOCALAPPDATA\PuTTY"
)

$RegistryPaths = @(
    "HKCU:\Software\SimonTatham",
    "HKLM:\Software\SimonTatham",
    "HKLM:\Software\WOW6432Node\SimonTatham"
)

$StartMenuPaths = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\PuTTY",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\PuTTY"
)

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:RemovalCount = 0
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

function Stop-PuTTYProcesses {
    <#
    .SYNOPSIS
        Attempts to stop any running PuTTY processes
    #>
    try {
        $PuTTYProcesses = Get-Process -Name "putty","plink","pageant","psftp" -ErrorAction SilentlyContinue
        
        if ($PuTTYProcesses) {
            Write-Log "Found $($PuTTYProcesses.Count) running PuTTY process(es)" -Level INFO
            
            foreach ($Process in $PuTTYProcesses) {
                try {
                    $Process | Stop-Process -Force -ErrorAction Stop
                    Write-Log "Stopped process: $($Process.Name) (PID: $($Process.Id))" -Level SUCCESS
                } catch {
                    Write-Log "Failed to stop process $($Process.Name): $_" -Level WARN
                }
            }
        } else {
            Write-Log "No running PuTTY processes found" -Level DEBUG
        }
    } catch {
        Write-Log "Error checking for PuTTY processes: $_" -Level WARN
    }
}

function Backup-PuTTYSettings {
    <#
    .SYNOPSIS
        Exports PuTTY registry settings to backup file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )
    
    try {
        $RegistryKey = "HKCU:\Software\SimonTatham\PuTTY"
        
        if (Test-Path $RegistryKey) {
            Write-Log "Backing up PuTTY settings to: $BackupPath" -Level INFO
            
            # Export registry key
            $RegExportPath = $RegistryKey -replace '^HKCU:', 'HKEY_CURRENT_USER'
            $Result = Start-Process -FilePath "reg.exe" -ArgumentList "export","`"$RegExportPath`"","`"$BackupPath`"" -Wait -PassThru -NoNewWindow
            
            if ($Result.ExitCode -eq 0) {
                Write-Log "Settings backed up successfully" -Level SUCCESS
                return $true
            } else {
                Write-Log "Registry export failed with exit code: $($Result.ExitCode)" -Level ERROR
                return $false
            }
        } else {
            Write-Log "No PuTTY settings found to backup" -Level WARN
            return $false
        }
    } catch {
        Write-Log "Failed to backup settings: $_" -Level ERROR
        return $false
    }
}

function Remove-PathIfExists {
    <#
    .SYNOPSIS
        Removes a file or directory if it exists
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$Description
    )
    
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Log "Removed $Description : $Path" -Level SUCCESS
            $script:RemovalCount++
            return $true
        } catch {
            Write-Log "Failed to remove $Description : $Path - $_" -Level ERROR
            return $false
        }
    } else {
        Write-Log "Not found: $Path" -Level DEBUG
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
        throw "Administrator privileges required for complete PuTTY removal"
    }
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    
    # Stop running processes
    Write-Log "Checking for running PuTTY processes" -Level INFO
    Stop-PuTTYProcesses
    
    # Backup settings if requested
    if ($BackupSettings) {
        $BackupFile = Join-Path $env:TEMP "PuTTY_Settings_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        $BackupResult = Backup-PuTTYSettings -BackupPath $BackupFile
        
        if ($BackupResult) {
            Write-Log "Backup saved to: $BackupFile" -Level SUCCESS
        }
    }
    
    # Remove program files
    Write-Log "" -Level INFO
    Write-Log "[1/4] Removing PuTTY program files" -Level INFO
    
    foreach ($Path in $ProgramPaths) {
        Remove-PathIfExists -Path $Path -Description "Program files"
    }
    
    # Remove user data
    Write-Log "" -Level INFO
    Write-Log "[2/4] Removing user configuration and data" -Level INFO
    
    foreach ($Path in $AppDataPaths) {
        Remove-PathIfExists -Path $Path -Description "User data"
    }
    
    # Remove registry entries
    Write-Log "" -Level INFO
    Write-Log "[3/4] Cleaning registry entries" -Level INFO
    
    foreach ($Path in $RegistryPaths) {
        Remove-PathIfExists -Path $Path -Description "Registry key"
    }
    
    # Remove Start Menu shortcuts
    Write-Log "" -Level INFO
    Write-Log "[4/4] Removing Start Menu shortcuts" -Level INFO
    
    foreach ($Path in $StartMenuPaths) {
        Remove-PathIfExists -Path $Path -Description "Start Menu folder"
    }
    
    # Determine final status
    Write-Log "" -Level INFO
    
    if ($script:RemovalCount -eq 0) {
        Write-Log "PuTTY was not found on this system" -Level INFO
        $FinalStatus = "Not Installed"
    } elseif ($script:ErrorCount -eq 0) {
        Write-Log "PuTTY successfully removed ($script:RemovalCount item(s) deleted)" -Level SUCCESS
        $FinalStatus = "Successfully Removed"
    } else {
        Write-Log "PuTTY partially removed ($script:RemovalCount item(s) deleted, $script:ErrorCount error(s))" -Level WARN
        $FinalStatus = "Partially Removed"
    }
    
    # Update status field if specified
    if ($StatusField) {
        $StatusMessage = "$FinalStatus - Removed: $script:RemovalCount, Errors: $script:ErrorCount"
        Set-NinjaField -FieldName $StatusField -Value $StatusMessage
    }
    
    # Exit with appropriate code
    if ($script:ErrorCount -gt 0 -and $script:RemovalCount -gt 0) {
        Write-Log "Partial removal completed with errors" -Level WARN
        exit 1
    } else {
        Write-Log "Uninstallation completed successfully" -Level SUCCESS
        exit 0
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    if ($StatusField) {
        Set-NinjaField -FieldName $StatusField -Value "Error: $($_.Exception.Message)"
    }
    
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Items Removed: $script:RemovalCount" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}
