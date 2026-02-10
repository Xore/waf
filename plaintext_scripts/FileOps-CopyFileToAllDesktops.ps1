#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Copies file to all user desktops.
.DESCRIPTION
    Copies a file to all user desktop folders including OneDrive desktops.
    Optionally includes public desktop.
.EXAMPLE
    $env:sourceFileOrFolder = 'C:\file.txt'
    $env:copyToPublicDesktop = 'true'
    Copies file to all user desktops including public.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param ()

begin {
    $StartTime = Get-Date

    function Write-Log {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Warning', 'Error')]
            [string]$Level = 'Info'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $Output = "[$Timestamp] [$Level] $Message"
        Write-Host $Output
    }

    $SourceFile = $env:sourceFileOrFolder
    $CopyToPublic = $env:copyToPublicDesktop
}

process {
    if (-not (Test-Path -LiteralPath $SourceFile)) {
        Write-Log "Source file not found: $SourceFile" -Level Error
        exit 1
    }

    Write-Log "Source file: $SourceFile"

    $UserProfiles = if ($CopyToPublic -eq 'false') {
        Write-Log "Excluding public desktop"
        Get-ChildItem 'C:\Users' -Directory | Where-Object {
            $_.Name -notin @('All Users', 'Default', 'Default User', 'Public')
        }
    }
    else {
        Write-Log "Including public desktop"
        Get-ChildItem 'C:\Users' -Directory
    }

    $SuccessCount = 0
    $FailureCount = 0

    foreach ($UserProfile in $UserProfiles) {
        $DesktopPath = Join-Path $UserProfile.FullName 'Desktop'

        if (Test-Path -LiteralPath $DesktopPath -PathType Container) {
            try {
                Copy-Item -LiteralPath $SourceFile -Destination $DesktopPath -Force -ErrorAction Stop
                Write-Log "Copied to: $DesktopPath"
                $SuccessCount++
            }
            catch {
                Write-Log "Failed to copy to $DesktopPath : $_" -Level Warning
                $FailureCount++
            }
        }

        $OneDriveDesktop = Join-Path $UserProfile.FullName 'OneDrive - MöllerGroup GmbH\Desktop'
        if (Test-Path -LiteralPath $OneDriveDesktop -PathType Container) {
            try {
                Copy-Item -LiteralPath $SourceFile -Destination $OneDriveDesktop -Force -ErrorAction Stop
                Write-Log "Copied to OneDrive: $OneDriveDesktop"
                $SuccessCount++
            }
            catch {
                Write-Log "Failed to copy to OneDrive desktop $OneDriveDesktop : $_" -Level Warning
                $FailureCount++
            }
        }
    }

    Write-Log "Copy completed: $SuccessCount successful, $FailureCount failed"

    if ($SuccessCount -eq 0) {
        Write-Log "No files were copied successfully" -Level Error
        exit 1
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
