#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Monitors file modifications.
.DESCRIPTION
    Checks whether a file is present and if it has been updated within specified time frame or fails a hash check.
.PARAMETER Alert
    Alert type: 'Alert If Change' or 'Alert If No Change'
.PARAMETER Path
    Path to the file to monitor
.PARAMETER Hash
    Hash or checksum to verify file hasn't been modified
.PARAMETER Algorithm
    Hashing algorithm (SHA1, SHA256, SHA384, SHA512, MD5). Default: SHA256
.PARAMETER Days
    Number of days for modification check
.PARAMETER Hours
    Number of hours for modification check
.PARAMETER Minutes
    Number of minutes for modification check
.EXAMPLE
    -Path "C:\TestFile.txt" -Hash "35BAFB1CE99AEF3AB068AFBAABAE8F21FD9B9F02D3A9442E364FA92C0B3BEEF0" -Alert "Alert If Change"
    Monitors file for hash changes.
.EXAMPLE
    -Path "C:\TestFile.txt" -Days 30 -Alert "Alert If No Change"
    Alerts if file hasn't been modified in 30 days.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Alert,
    [Parameter()]
    [String]$Path,
    [Parameter()]
    [String]$Hash,
    [Parameter()]
    [String]$Algorithm = "SHA256",
    [Parameter()]
    [int]$Days,
    [Parameter()]
    [int]$Hours,
    [Parameter()]
    [int]$Minutes
)

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

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($env:alert -and $env:alert -notlike "null") { $Alert = $env:alert }
    if ($env:targetFilePath -and $env:targetFilePath -notlike "null") { $Path = $env:targetFilePath }
    if ($env:hash -and $env:hash -notlike "null") { $Hash = $env:hash }
    if ($env:algorithm -and $env:algorithm -notlike "null") { $Algorithm = $env:algorithm }
    if ($env:daysSinceLastModification -and $env:daysSinceLastModification -notlike "null") { $Days = $env:daysSinceLastModification }
    if ($env:hoursSinceLastModification -and $env:hoursSinceLastModification -notlike "null") { $Hours = $env:hoursSinceLastModification }
    if ($env:minutesSinceLastModification -and $env:minutesSinceLastModification -notlike "null") { $Minutes = $env:minutesSinceLastModification }

    $AllowedAlgorithms = "SHA1", "SHA256", "SHA384", "SHA512", "MD5"
}

process {
    if (-not (Test-IsElevated)) {
        Write-Log "Some files may require Administrator permissions to view" -Level Warning
    }

    if ($AllowedAlgorithms -notcontains $Algorithm) {
        Write-Log "Invalid Algorithm ($Algorithm). Allowed: SHA1, SHA256, SHA384, SHA512, MD5" -Level Error
        exit 1
    }

    if (-not $Path) {
        Write-Log "A filepath is required" -Level Error
        exit 1
    }

    if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
        Write-Log "File does not exist: $Path" -Level Error
        exit 1
    }

    Write-Log "File exists: $Path"

    $File = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if ($File.PSIsContainer) {
        Write-Log "Please provide a file path, not a directory" -Level Error
        exit 1
    }

    $AlertTriggered = $false

    if ($Hash) {
        $CurrentHash = Get-FileHash -Path $File.FullName -Algorithm $Algorithm | Select-Object -ExpandProperty Hash
        Write-Log "Hash Given: $Hash"
        Write-Log "Current Hash: $CurrentHash"

        if ($Hash -notlike $CurrentHash) {
            Write-Log "Hash mismatch" -Level Warning
            if ($Alert -eq "Alert If Change") {
                Write-Log "File has been modified" -Level Warning
                $AlertTriggered = $true
            }
        }
        else {
            Write-Log "Hash matches"
            if ($Alert -eq "Alert If No Change") {
                Write-Log "File has not been modified" -Level Warning
                $AlertTriggered = $true
            }
        }
    }

    if ($Days -or $Hours -or $Minutes) {
        $Cutoff = Get-Date
        $CurrentDate = $Cutoff

        if ($Days) { $Cutoff = $Cutoff.AddDays(-$Days) }
        if ($Hours) { $Cutoff = $Cutoff.AddHours(-$Hours) }
        if ($Minutes) { $Cutoff = $Cutoff.AddMinutes(-$Minutes) }

        $TimeSpan = New-TimeSpan $Cutoff $CurrentDate

        if ($Cutoff -ne $CurrentDate) {
            Write-Log "Checking if file was modified in the last $($TimeSpan.ToString("dd' day(s) 'hh' hour(s) 'mm' minute(s)'"))"
            Write-Log "File was last modified on $($File.LastWriteTime)"

            if ($File.LastWriteTime -ge $Cutoff) {
                Write-Log "File has been updated within the time period"
                if ($Alert -eq "Alert If Change") {
                    Write-Log "File has been modified" -Level Warning
                    $AlertTriggered = $true
                }
            }
            else {
                Write-Log "File has not been updated within the time period"
                if ($Alert -eq "Alert If No Change") {
                    Write-Log "File has not been modified" -Level Warning
                    $AlertTriggered = $true
                }
            }
        }
    }

    if ($AlertTriggered) {
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
