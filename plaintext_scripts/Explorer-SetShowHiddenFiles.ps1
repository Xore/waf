#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Configures Windows Explorer to show or hide hidden files and folders.

.DESCRIPTION
    This script modifies the Windows Explorer view settings to control the visibility of hidden 
    files, folders, and system files. It updates the registry settings for the current user or 
    all users on the system.
    
    Showing hidden files is useful for troubleshooting and advanced system management, while 
    hiding them provides a cleaner interface for standard users.

.PARAMETER Show
    If specified, shows hidden files and folders. If not specified, hides them.

.PARAMETER ShowSystemFiles
    If specified, also shows protected operating system files.

.PARAMETER ApplyToAllUsers
    If specified, applies settings to all user profiles on the system.

.EXAMPLE
    -Show

    [Info] Configuring Explorer to show hidden files and folders...
    [Info] Hidden files visibility enabled
    [Info] Explorer restart required for changes to take effect

.EXAMPLE
    -Show -ShowSystemFiles

    [Info] Configuring Explorer to show hidden and system files...
    [Info] Hidden files visibility enabled
    [Info] System files visibility enabled
    [Info] Explorer restart required for changes to take effect

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Refactored to V3.0 standards with Write-Log function
    
.COMPONENT
    Registry - HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
    
.LINK
    https://learn.microsoft.com/en-us/windows/win32/shell/folder-views

.FUNCTIONALITY
    - Modifies Explorer Advanced settings registry keys
    - Controls Hidden files visibility (Hidden = 1 to show, 2 to hide)
    - Controls System files visibility (ShowSuperHidden = 1 to show, 0 to hide)
    - Can apply settings to all user profiles
    - Provides confirmation of settings applied
#>

[CmdletBinding()]
param(
    [switch]$Show,
    [switch]$ShowSystemFiles,
    [switch]$ApplyToAllUsers
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

    if ($env:showHidden -eq "true") {
        $Show = $true
    }
    if ($env:showSystemFiles -eq "true") {
        $ShowSystemFiles = $true
    }
    if ($env:applyToAllUsers -eq "true") {
        $ApplyToAllUsers = $true
    }

    $RegPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $ExitCode = 0
}

process {
    try {
        if ($Show) {
            $HiddenValue = 1
            Write-Log "Configuring Explorer to show hidden files and folders..."
        }
        else {
            $HiddenValue = 2
            Write-Log "Configuring Explorer to hide hidden files and folders..."
        }

        if ($ApplyToAllUsers) {
            Write-Log "Applying settings to all user profiles..."
            $UserProfiles = Get-ChildItem "Registry::HKEY_USERS" | Where-Object { $_.Name -match "S-1-5-21" }
            
            foreach ($Profile in $UserProfiles) {
                $FullPath = "$($Profile.Name)\$RegPath"
                Set-ItemProperty -Path "Registry::$FullPath" -Name "Hidden" -Value $HiddenValue -Type DWord -Force -Confirm:$false -ErrorAction SilentlyContinue
                
                if ($ShowSystemFiles) {
                    Set-ItemProperty -Path "Registry::$FullPath" -Name "ShowSuperHidden" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction SilentlyContinue
                }
            }
        }
        else {
            Set-ItemProperty -Path "HKCU:\$RegPath" -Name "Hidden" -Value $HiddenValue -Type DWord -Force -Confirm:$false
            
            if ($ShowSystemFiles) {
                Set-ItemProperty -Path "HKCU:\$RegPath" -Name "ShowSuperHidden" -Value 1 -Type DWord -Force -Confirm:$false
                Write-Log "System files visibility enabled"
            }
        }

        if ($Show) {
            Write-Log "Hidden files visibility enabled"
        }
        else {
            Write-Log "Hidden files visibility disabled"
        }
        
        Write-Log "Explorer restart required for changes to take effect"
    }
    catch {
        Write-Log "Failed to configure Explorer settings: $_" -Level Error
        $ExitCode = 1
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit $ExitCode
}
