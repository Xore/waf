#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Copies a file to a destination folder.
.DESCRIPTION
    Copies a file from source to destination path with validation.
    Requires environment variables: sourcefile and destinationpath.
.EXAMPLE
    $env:sourcefile = 'C:\source\file.txt'
    $env:destinationpath = 'C:\destination\'
    Copies file.txt to destination folder.
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
}

process {
    try {
        if ([string]::IsNullOrWhiteSpace($env:sourcefile)) {
            Write-Log "Environment variable 'sourcefile' is not set" -Level Error
            exit 1
        }

        if ([string]::IsNullOrWhiteSpace($env:destinationpath)) {
            Write-Log "Environment variable 'destinationpath' is not set" -Level Error
            exit 1
        }

        if (-not (Test-Path -Path $env:sourcefile -PathType Leaf)) {
            Write-Log "Source file does not exist: $env:sourcefile" -Level Error
            exit 1
        }

        Write-Log "Copying file from $env:sourcefile to $env:destinationpath"
        Copy-Item -Path $env:sourcefile -Destination $env:destinationpath -Force -ErrorAction Stop
        Write-Log "File copied successfully to $env:destinationpath"
    }
    catch {
        Write-Log "File copy failed: $_" -Level Error
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
