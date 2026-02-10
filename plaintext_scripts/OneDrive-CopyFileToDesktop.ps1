#Requires -Version 5.1

<#
.SYNOPSIS
    Copies a file from source location to OneDrive Desktop folder

.DESCRIPTION
    Copies a specified file to the user's OneDrive Desktop folder. This script is
    useful for deploying files, documentation, shortcuts, or configuration files to
    user desktops in environments where OneDrive folder redirection is enabled.
    
    The script performs the following:
    - Validates source file exists
    - Checks OneDrive environment variable is configured
    - Verifies OneDrive Desktop folder is accessible
    - Copies file to OneDrive Desktop (overwrites if exists)
    - Provides detailed logging of copy operation
    - Reports success or failure with clear error messages
    
    This is particularly useful in enterprise environments where OneDrive Known
    Folder Move (KFM) redirects the Desktop folder to OneDrive.
    
    This script runs unattended without user interaction.

.PARAMETER SourcePath
    Full path to the source file to copy.
    Must be an existing file (not a directory).
    Examples: "C:\Temp\UserGuide.pdf", "\\server\share\Document.docx"

.EXAMPLE
    .\OneDrive-CopyFileToDesktop.ps1 -SourcePath "C:\Temp\UserGuide.pdf"
    
    Copies UserGuide.pdf to the OneDrive Desktop folder.

.EXAMPLE
    .\OneDrive-CopyFileToDesktop.ps1 -SourcePath "\\server\share\Document.docx"
    
    Copies Document.docx from network share to OneDrive Desktop.

.NOTES
    Script Name:    OneDrive-CopyFileToDesktop.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or current user
    Execution Frequency: On-demand
    Typical Duration: ~1-5 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - OneDrive must be configured and syncing
        - User must have write permissions to OneDrive Desktop folder
        - Source file must be accessible from execution context
    
    Environment Variables (Optional):
        - SourcePath: Alternative to -SourcePath parameter
        - OneDrive: System environment variable (set by OneDrive client)
    
    Exit Codes:
        0 - Success (file copied successfully)
        1 - Failure (source file missing, OneDrive not configured, or copy failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Full path to source file")]
    [ValidateNotNullOrEmpty()]
    [string]$SourcePath
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "OneDrive-CopyFileToDesktop"

# Support environment variable
if ($env:SourcePath -and $env:SourcePath -notlike "null") {
    $SourcePath = $env:SourcePath
}

# Trim whitespace from parameter
if ($SourcePath) {
    $SourcePath = $SourcePath.Trim()
}

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$script:ExitCode = 0
$script:ErrorCount = 0
$script:WarningCount = 0

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

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Validate required parameter
    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
        throw "SourcePath parameter is required. Specify the full path to the file to copy."
    }
    
    Write-Log "Copying file to OneDrive Desktop" -Level INFO
    Write-Log "Source: $SourcePath" -Level INFO
    
    # Validate source file exists
    if (-not (Test-Path -Path $SourcePath -PathType Leaf)) {
        throw "Source file does not exist: $SourcePath"
    }
    
    Write-Log "Source file validated" -Level DEBUG
    
    # Get file information
    $SourceFile = Get-Item -Path $SourcePath -ErrorAction Stop
    $FileName = $SourceFile.Name
    $FileSizeKB = [math]::Round($SourceFile.Length / 1KB, 2)
    
    Write-Log "File name: $FileName" -Level INFO
    Write-Log "File size: $FileSizeKB KB" -Level DEBUG
    
    # Validate OneDrive is configured
    if ([string]::IsNullOrWhiteSpace($env:OneDrive)) {
        throw "OneDrive environment variable is not set. OneDrive may not be configured for this user."
    }
    
    Write-Log "OneDrive path: $env:OneDrive" -Level DEBUG
    
    # Build destination path
    $DestinationFolder = Join-Path $env:OneDrive "Desktop"
    
    # Validate OneDrive Desktop folder exists
    if (-not (Test-Path -Path $DestinationFolder -PathType Container)) {
        throw "OneDrive Desktop folder does not exist: $DestinationFolder"
    }
    
    Write-Log "OneDrive Desktop folder validated" -Level DEBUG
    
    $DestinationPath = Join-Path $DestinationFolder $FileName
    Write-Log "Destination: $DestinationPath" -Level INFO
    
    # Check if destination file already exists
    if (Test-Path -Path $DestinationPath) {
        Write-Log "Destination file already exists and will be overwritten" -Level WARN
    }
    
    # Copy file to destination
    Write-Log "Copying file..." -Level INFO
    Copy-Item -Path $SourcePath -Destination $DestinationFolder -Force -ErrorAction Stop
    
    # Verify copy succeeded
    if (Test-Path -Path $DestinationPath) {
        $DestFile = Get-Item -Path $DestinationPath
        $DestFileSizeKB = [math]::Round($DestFile.Length / 1KB, 2)
        
        Write-Log "File copied successfully" -Level SUCCESS
        Write-Log "Destination path: $DestinationPath" -Level INFO
        Write-Log "Destination size: $DestFileSizeKB KB" -Level DEBUG
        
        # Verify file sizes match
        if ($FileSizeKB -eq $DestFileSizeKB) {
            Write-Log "File size verification passed" -Level DEBUG
        } else {
            Write-Log "File size mismatch detected" -Level WARN
        }
    } else {
        throw "Copy operation completed but destination file not found"
    }
    
    Write-Log "Copy operation completed successfully" -Level SUCCESS
    
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
    Write-Log "  Exit Code: $script:ExitCode" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Cleanup
    [System.GC]::Collect()
    
    exit $script:ExitCode
}
