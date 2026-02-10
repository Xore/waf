#Requires -Version 5.1

<#
.SYNOPSIS
    Creates URL desktop shortcuts for specified users.

.DESCRIPTION
    This script creates .url desktop shortcuts with specified options.
    Supports creating shortcuts for:
    - All users (new and existing)
    - All existing users only
    - Specific users

.PARAMETER Name
    Name of the shortcut (without extension).
    Example: "Login Portal"

.PARAMETER Url
    Target URL for the shortcut.
    Example: "https://www.google.com"

.PARAMETER AllExistingUsers
    Create shortcut for all existing users only.
    Does not apply to new users created later.

.PARAMETER AllUsers
    Create shortcut in Public Desktop folder.
    Applies to all users including future ones.

.EXAMPLE
    Shortcuts-CreateDesktopURL.ps1 -Name "Google" -Url "https://www.google.com" -AllUsers
    Creates a URL shortcut in Public Desktop accessible to all users.

.EXAMPLE
    Shortcuts-CreateDesktopURL.ps1 -Name "Portal" -Url "https://portal.company.com" -AllExistingUsers
    Creates shortcuts on all existing user desktops.

.NOTES
    File Name      : Shortcuts-CreateDesktopURL.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Requires       : Administrator privileges
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 format with enhanced error handling
    - 1.1: Split script and added Script Variable support
    - 1.0: Initial version
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Name,
    
    [Parameter()]
    [String]$Url,
    
    [Parameter()]
    [Switch]$AllExistingUsers,
    
    [Parameter()]
    [Switch]$AllUsers
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Host $logMessage }
        }
    }

    function Test-IsElevated {
        <#
        .SYNOPSIS
            Tests if script is running with administrator privileges.
        #>
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Get-UserHives {
        <#
        .SYNOPSIS
            Gets user profile information from registry.
        #>
        param (
            [Parameter()]
            [ValidateSet('AzureAD', 'DomainAndLocal', 'All')]
            [String]$Type = 'All',
            
            [Parameter()]
            [String[]]$ExcludedUsers,
            
            [Parameter()]
            [switch]$IncludeDefault
        )

        $Patterns = switch ($Type) {
            'AzureAD' { 'S-1-12-1-(\d+-?){4}$' }
            'DomainAndLocal' { 'S-1-5-21-(\d+-?){4}$' }
            'All' { 'S-1-12-1-(\d+-?){4}$', 'S-1-5-21-(\d+-?){4}$' }
        }

        $UserProfiles = foreach ($Pattern in $Patterns) {
            Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction SilentlyContinue |
                Where-Object { $_.PSChildName -match $Pattern } |
                Select-Object @{Name = 'SID'; Expression = { $_.PSChildName } },
                @{Name = 'UserHive'; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } },
                @{Name = 'UserName'; Expression = { $_.ProfileImagePath | Split-Path -Leaf } },
                @{Name = 'Path'; Expression = { $_.ProfileImagePath } }
        }

        if ($IncludeDefault) {
            $DefaultProfile = [PSCustomObject]@{
                UserName = 'Default'
                SID      = 'DefaultProfile'
                UserHive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
                Path     = 'C:\Users\Default'
            }
            
            if ($ExcludedUsers -notcontains $DefaultProfile.UserName) {
                $DefaultProfile
            }
        }

        $UserProfiles | Where-Object { $ExcludedUsers -notcontains $_.UserName }
    }

    function New-Shortcut {
        <#
        .SYNOPSIS
            Creates a desktop shortcut file.
        #>
        [CmdletBinding()]
        param(
            [Parameter()]
            [String]$Arguments,
            
            [Parameter()]
            [String]$IconPath,
            
            [Parameter(ValueFromPipeline = $True)]
            [String]$Path,
            
            [Parameter()]
            [String]$Target,
            
            [Parameter()]
            [String]$WorkingDir
        )
        
        process {
            try {
                Write-Log "Creating shortcut at $Path"
                $ShellObject = New-Object -ComObject 'WScript.Shell'
                $Shortcut = $ShellObject.CreateShortcut($Path)
                $Shortcut.TargetPath = $Target
                
                if ($WorkingDir) { $Shortcut.WorkingDirectory = $WorkingDir }
                if ($Arguments) { $Shortcut.Arguments = $Arguments }
                if ($IconPath) { $Shortcut.IconLocation = $IconPath }
                
                $Shortcut.Save()

                if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
                    throw "Shortcut file not created at $Path"
                }
                
                Write-Log "Successfully created shortcut at $Path"
            }
            catch {
                Write-Log "Failed to create shortcut at $Path : $_" -Level ERROR
                throw
            }
            finally {
                if ($ShellObject) {
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ShellObject) | Out-Null
                }
            }
        }
    }
}

process {
    try {
        if ($env:shortcutName -and $env:shortcutName -notlike 'null') { 
            $Name = $env:shortcutName 
        }
        
        if ($env:createTheShortcutFor -and $env:createTheShortcutFor -notlike 'null') {
            if ($env:createTheShortcutFor -eq 'All Users') { $AllUsers = $True }
            if ($env:createTheShortcutFor -eq 'All Existing Users') { $AllExistingUsers = $True }
        }
        
        if ($env:linkForUrlShortcut -and $env:linkForUrlShortcut -notlike 'null') { 
            $Url = $env:linkForUrlShortcut 
        }

        if (-not $AllUsers -and -not $AllExistingUsers) {
            throw 'You must specify which desktop to create the shortcut on (use -AllUsers or -AllExistingUsers)'
        }

        if (-not $Name) {
            throw 'You must specify a name for the shortcut'
        }
        
        if (-not $Url) {
            throw 'You must specify a URL for the shortcut'
        }

        if (-not (Test-IsElevated)) {
            throw 'Access Denied. Please run with Administrator privileges'
        }

        $ShortcutPath = New-Object System.Collections.Generic.List[String]
        $File = "$Name.url"

        if ($AllUsers) {
            $ShortcutPath.Add("$env:Public\Desktop\$File")
        }

        if ($AllExistingUsers) {
            $UserProfiles = Get-UserHives
            foreach ($Profile in $UserProfiles) {
                $ShortcutPath.Add("$($Profile.Path)\Desktop\$File")
            }
        }

        $ShortcutPath | New-Shortcut -Target $Url

        Write-Log "Successfully created $($ShortcutPath.Count) shortcut(s)"
        exit 0
    }
    catch {
        Write-Log "Script failed: $_" -Level ERROR
        exit 1
    }
}

end {
    [System.GC]::Collect()
}