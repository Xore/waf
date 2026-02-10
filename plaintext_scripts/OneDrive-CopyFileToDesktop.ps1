#Requires -Version 5.1

<#
.SYNOPSIS
    Copies a file from a source location to the OneDrive Desktop folder.

.DESCRIPTION
    Copies a specified file to the user's OneDrive Desktop folder. This script is useful
    for deploying files, documentation, or shortcuts to user desktops in environments
    where OneDrive folder redirection is enabled.
    
    The script validates that:
    - Source file exists
    - OneDrive environment variable is set
    - OneDrive Desktop folder is accessible
    
    If the destination file already exists, it will be overwritten.

.PARAMETER SourcePath
    Full path to the source file to copy. Can also be provided via environment variable.

.EXAMPLE
    .\OneDrive-CopyFileToDesktop.ps1 -SourcePath "C:\Temp\UserGuide.pdf"

    [2026-02-10 16:45:00] [INFO] Copying file to OneDrive Desktop
    [2026-02-10 16:45:00] [SUCCESS] File copied successfully to C:\Users\John\OneDrive\Desktop\UserGuide.pdf

.EXAMPLE
    $env:SourcePath = "C:\Temp\Document.docx"
    .\OneDrive-CopyFileToDesktop.ps1

    Uses environment variable to specify source file.

.OUTPUTS
    None. Status information is written to console.

.NOTES
    File Name      : OneDrive-CopyFileToDesktop.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete rewrite to V3 standards with comprehensive error handling
    - 1.0: Initial simple copy script
    
    Requirements:
    - OneDrive must be configured and syncing
    - User must have write permissions to OneDrive Desktop folder
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$SourcePath
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $ExitCode = 0
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $LogMessage }
            'WARNING' { Write-Warning $LogMessage }
            'SUCCESS' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:SourcePath -and $env:SourcePath -notlike "null") {
        $SourcePath = $env:SourcePath
    }
}

process {
    try {
        if ([string]::IsNullOrWhiteSpace($SourcePath)) {
            Write-Log "SourcePath parameter is required" -Level ERROR
            $ExitCode = 1
            return
        }

        Write-Log "Copying file to OneDrive Desktop"
        Write-Log "Source: $SourcePath" -Level DEBUG

        if (-not (Test-Path -Path $SourcePath -PathType Leaf)) {
            Write-Log "Source file does not exist: $SourcePath" -Level ERROR
            $ExitCode = 1
            return
        }

        if ([string]::IsNullOrWhiteSpace($env:OneDrive)) {
            Write-Log "OneDrive environment variable is not set. OneDrive may not be configured for this user." -Level ERROR
            $ExitCode = 1
            return
        }

        $destinationFolder = Join-Path $env:OneDrive "Desktop"
        
        if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
            Write-Log "OneDrive Desktop folder does not exist: $destinationFolder" -Level ERROR
            $ExitCode = 1
            return
        }

        $fileName = Split-Path -Path $SourcePath -Leaf
        $destinationPath = Join-Path $destinationFolder $fileName

        Copy-Item -Path $SourcePath -Destination $destinationFolder -Force -ErrorAction Stop
        
        Write-Log "File copied successfully to $destinationPath" -Level SUCCESS
    }
    catch {
        Write-Log "Failed to copy file: $_" -Level ERROR
        $ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $Duration seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
