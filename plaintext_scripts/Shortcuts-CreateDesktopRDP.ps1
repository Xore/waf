#Requires -Version 5.1

<#
.SYNOPSIS
    Creates RDP desktop shortcuts with customizable display and connection settings.

.DESCRIPTION
    This script creates Remote Desktop Protocol (.rdp) shortcuts with specified options.
    Supports various display modes, authentication settings, and RD Gateway configuration.
    Can create shortcuts for all users, existing users only, or specific users.

.PARAMETER Name
    Name of the shortcut (without extension).
    Example: "Production Server"

.PARAMETER RDPTarget
    IP address or DNS name and optional port to the RDS Host.
    Example: "TEST-RDSH:28665" or "192.168.1.100"

.PARAMETER RDPUser
    Username to autofill in the RDP connection dialog.
    Example: "DOMAIN\username"

.PARAMETER AlwaysPrompt
    Always prompt for credentials when connecting.

.PARAMETER Gateway
    IP address or DNS name and optional port of the RD Gateway.
    Example: "rdp.example.com:4433"

.PARAMETER SeparateGateWayCreds
    Use different credentials for RD Gateway than Session Host.

.PARAMETER FullScreen
    Open RDP window in fullscreen mode.

.PARAMETER MultiMon
    Enable multi-monitor support for RDP session.

.PARAMETER Width
    Custom width for RDP window.
    Example: 1920

.PARAMETER Height
    Custom height for RDP window.
    Example: 1080

.PARAMETER AllExistingUsers
    Create shortcut for all existing users only.

.PARAMETER AllUsers
    Create shortcut in Public Desktop folder.

.EXAMPLE
    Shortcuts-CreateDesktopRDP.ps1 -Name "Test Server" -RDPTarget "SRV19-TEST" -AllUsers -FullScreen
    Creates fullscreen RDP shortcut for all users.

.EXAMPLE
    Shortcuts-CreateDesktopRDP.ps1 -Name "Remote Desktop" -RDPTarget "192.168.1.100" -Width 1920 -Height 1080 -AllExistingUsers
    Creates windowed RDP shortcut with custom dimensions for existing users.

.NOTES
    File Name      : Shortcuts-CreateDesktopRDP.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Requires       : Administrator privileges
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 format with enhanced error handling
    - 1.1: Renamed script, added Script Variable support
    - 1.0: Initial version
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Name,
    
    [Parameter()]
    [String]$RDPTarget,
    
    [Parameter()]
    [String]$RDPUser,
    
    [Parameter()]
    [Switch]$AlwaysPrompt = [System.Convert]::ToBoolean($env:alwaysPromptForRdpCredentials),
    
    [Parameter()]
    [String]$Gateway,
    
    [Parameter()]
    [Switch]$SeparateGateWayCreds = [System.Convert]::ToBoolean($env:separateRdpGatewayCredentials),
    
    [Parameter()]
    [Switch]$FullScreen,
    
    [Parameter()]
    [Switch]$MultiMon,
    
    [Parameter()]
    [Int]$Width,
    
    [Parameter()]
    [Int]$Height,
    
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
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Get-UserHives {
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
        
        if ($env:rdpServerAddress -and $env:rdpServerAddress -notlike 'null') { 
            $RDPTarget = $env:rdpServerAddress 
        }
        
        if ($env:rdpUsername -and $env:rdpUsername -notlike 'null') { 
            $RDPUser = $env:rdpUsername 
        }
        
        if ($env:rdpGatewayServerAddress -and $env:rdpGatewayServerAddress -notlike 'null') { 
            $Gateway = $env:rdpGatewayServerAddress 
        }
        
        if ($env:rdpWindowSize -and $env:rdpWindowSize -notlike 'null') {
            if ($env:rdpWindowSize -eq 'Fullscreen Multiple Monitor Mode') { $MultiMon = $True }
            if ($env:rdpWindowSize -eq 'Fullscreen') { $FullScreen = $True }
        }
        
        if ($env:customRdpWindowWidth -and $env:customRdpWindowWidth -notlike 'null') { 
            $Width = $env:customRdpWindowWidth 
        }
        
        if ($env:customRdpWindowHeight -and $env:customRdpWindowHeight -notlike 'null') { 
            $Height = $env:customRdpWindowHeight 
        }

        if (($Width -and -not $Height) -or ($Height -and -not $Width)) {
            Write-Log 'Both width and height must be specified. Using fullscreen mode' -Level WARNING
        }

        if (($Width -or $Height) -and ($FullScreen -or $MultiMon)) {
            if ($MultiMon) {
                Write-Log 'Conflicting display options. Using fullscreen multi-monitor' -Level WARNING
            }
            else {
                Write-Log 'Conflicting display options. Using fullscreen' -Level WARNING
            }
        }

        if (-not $AllUsers -and -not $AllExistingUsers) {
            throw 'You must specify which desktop to create the shortcut on'
        }

        if (-not $Name -or -not $RDPTarget) {
            throw 'You must specify a name and target for the shortcut'
        }

        if (-not (Test-IsElevated)) {
            throw 'Access Denied. Please run with Administrator privileges'
        }

        $ShortcutPath = New-Object System.Collections.Generic.List[String]
        $File = "$Name.rdp"

        if ($AllUsers) {
            $ShortcutPath.Add("$env:Public\Desktop\$File")
        }

        if ($AllExistingUsers) {
            $UserProfiles = Get-UserHives
            foreach ($Profile in $UserProfiles) {
                $ShortcutPath.Add("$($Profile.Path)\Desktop\$File")
            }
        }

        $RDPFile = New-Object System.Collections.Generic.List[String]

        $Template = @'
session bpp:i:32
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectwebauthn:i:1
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewaycredentialssource:i:4
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
enablerdsaadauth:i:0
'@
        $RDPFile.Add($Template)

        foreach ($Path in $ShortcutPath) {
            $RDPFile.Add("full address:s:$RDPTarget")
            $RDPFile.Add("gatewayhostname:s:$Gateway")

            if ($Width) { $RDPFile.Add("desktopwidth:i:$Width") }
            if ($Height) { $RDPFile.Add("desktopheight:i:$Height") }
            if ($MultiMon) { $RDPFile.Add('use multimon:i:1') } else { $RDPFile.Add('use multimon:i:0') }
            if ($FullScreen -or $MultiMon -or -not $Height -or -not $Width) { 
                $RDPFile.Add('screen mode id:i:2') 
            } else { 
                $RDPFile.Add('screen mode id:i:1') 
            }
            if ($AlwaysPrompt) { $RDPFile.Add('prompt for credentials:i:1') } else { $RDPFile.Add('prompt for credentials:i:0') }
            if ($Gateway) { $RDPFile.Add('gatewayusagemethod:i:2') } else { $RDPFile.Add('gatewayusagemethod:i:4') }
            
            if ($SeparateGateWayCreds) {
                $RDPFile.Add('promptcredentialonce:i:0')
                $RDPFile.Add('gatewayprofileusagemethod:i:1')
            }
            else {
                $RDPFile.Add('promptcredentialonce:i:1')
                if ($Gateway) { $RDPFile.Add('gatewayprofileusagemethod:i:0') }
            }

            if ($RDPUser) { $RDPFile.Add("username:s:$RDPUser") }

            Write-Log "Creating shortcut at $Path"
            $RDPFile | Out-File $Path -Encoding ASCII

            if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
                throw "Unable to create shortcut at $Path"
            }
        }

        Write-Log "Successfully created $($ShortcutPath.Count) RDP shortcut(s)"
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