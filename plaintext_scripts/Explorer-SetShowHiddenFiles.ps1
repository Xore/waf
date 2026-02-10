#Requires -Version 5.1

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
    .\Explorer-SetShowHiddenFiles.ps1 -Show

    Configuring Explorer to show hidden files and folders...
    Hidden files visibility enabled
    Explorer restart required for changes to take effect

.EXAMPLE
    .\Explorer-SetShowHiddenFiles.ps1 -Show -ShowSystemFiles

    Configuring Explorer to show hidden and system files...
    Hidden files visibility enabled
    System files visibility enabled
    Explorer restart required for changes to take effect

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : Explorer-SetShowHiddenFiles.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with proper Write-Log function
    - 1.0: Initial release
    
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
    [Parameter()]
    [switch]$Show,
    
    [Parameter()]
    [switch]$ShowSystemFiles,
    
    [Parameter()]
    [switch]$ApplyToAllUsers
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
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
            default { Write-Output $LogMessage }
        }
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
            $UserProfiles = Get-ChildItem "Registry::HKEY_USERS" -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -match "S-1-5-21" }
            
            foreach ($Profile in $UserProfiles) {
                $FullPath = "$($Profile.Name)\$RegPath"
                try {
                    Set-ItemProperty -Path "Registry::$FullPath" -Name "Hidden" -Value $HiddenValue -Type DWord -Force -Confirm:$false -ErrorAction Stop
                    
                    if ($ShowSystemFiles) {
                        Set-ItemProperty -Path "Registry::$FullPath" -Name "ShowSuperHidden" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop
                    }
                }
                catch {
                    Write-Log "Failed to update registry for profile $($Profile.Name): $_" -Level WARNING
                }
            }
        }
        else {
            Set-ItemProperty -Path "HKCU:\$RegPath" -Name "Hidden" -Value $HiddenValue -Type DWord -Force -Confirm:$false -ErrorAction Stop
            
            if ($ShowSystemFiles) {
                Set-ItemProperty -Path "HKCU:\$RegPath" -Name "ShowSuperHidden" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop
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
        Write-Log "Failed to configure Explorer settings: $_" -Level ERROR
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
