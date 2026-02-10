#Requires -Version 5.1

<#
.SYNOPSIS
    Creates desktop shortcuts for executables with custom icons and arguments.

.DESCRIPTION
    This script creates executable (.lnk) desktop shortcuts with specified options.
    Supports custom icons from URLs, base64 strings, or local files.
    Can create shortcuts for all users, existing users only, or specific users.

.PARAMETER Name
    Name of the shortcut (without extension).

.PARAMETER ExePath
    Full path to the executable file.

.PARAMETER Arguments
    Command-line arguments to pass to the executable.

.PARAMETER StartIn
    Working directory for the executable.

.PARAMETER Icon
    Path to a local image file for the shortcut icon.
    Supported formats: ico, png, jpg, jpeg, gif, bmp

.PARAMETER IconDirectory
    Directory to store converted icon files.

.PARAMETER IconUrl
    URL to download an image file for the shortcut icon.

.PARAMETER AllExistingUsers
    Create shortcut for all existing users only.

.PARAMETER ExcludeUsers
    Comma-separated list of usernames to exclude.

.PARAMETER AllUsers
    Create shortcut in Public Desktop folder.

.EXAMPLE
    Shortcuts-CreateDesktopEXE.ps1 -Name "Firefox" -ExePath "C:\Program Files\Mozilla Firefox\firefox.exe" -AllUsers
    Creates Firefox shortcut for all users.

.EXAMPLE
    Shortcuts-CreateDesktopEXE.ps1 -Name "Google" -ExePath "C:\Program Files\Mozilla Firefox\firefox.exe" -Arguments "https://www.google.com" -IconUrl "https://www.google.com/favicon.ico" -IconDirectory "C:\ProgramData\Icons" -AllExistingUsers
    Creates Firefox shortcut that opens Google with custom icon.

.NOTES
    File Name      : Shortcuts-CreateDesktopEXE.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Requires       : Administrator privileges
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 format with enhanced error handling
    - 1.1: Split script and improved icon support
    - 1.0: Initial version
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Name,
    
    [Parameter()]
    [String]$ExePath,
    
    [Parameter()]
    [String]$Arguments,
    
    [Parameter()]
    [String]$StartIn,
    
    [Parameter()]
    [String]$Icon,
    
    [Parameter()]
    [String]$IconDirectory,
    
    [Parameter()]
    [String]$IconUrl,
    
    [Parameter()]
    [Switch]$AllExistingUsers,
    
    [Parameter()]
    [String]$ExcludeUsers,
    
    [Parameter()]
    [Switch]$AllUsers
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    
    Set-StrictMode -Version Latest
    
    Add-Type -AssemblyName System.Drawing

    $IconBase64 = $null

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

    function ConvertFrom-Base64 {
        param($Base64, $Path)
        $bytes = [Convert]::FromBase64String($Base64)
        [IO.File]::WriteAllBytes($Path, $bytes)
    }

    function Invoke-Download {
        param(
            [Parameter()][String]$URL,
            [Parameter()][String]$BaseName,
            [Parameter()][int]$Attempts = 3,
            [Parameter()][Switch]$SkipSleep
        )

        if ($URL -notmatch '^http(s)?://') {
            Write-Log 'Adding https:// to URL' -Level WARNING
            $URL = "https://$URL"
        }

        Write-Log "Downloading from $URL"

        $SupportedTLSversions = [enum]::GetValues('Net.SecurityProtocolType')
        if (($SupportedTLSversions -contains 'Tls13') -and ($SupportedTLSversions -contains 'Tls12')) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls12
        }
        elseif ($SupportedTLSversions -contains 'Tls12') {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }

        $i = 1
        while ($i -le $Attempts) {
            if (-not $SkipSleep) {
                $SleepTime = Get-Random -Minimum 3 -Maximum 15
                Write-Log "Waiting $SleepTime seconds"
                Start-Sleep -Seconds $SleepTime
            }

            Write-Log "Download attempt $i"

            try {
                $WebRequestArgs = @{
                    Uri                = $URL
                    MaximumRedirection = 10
                    UseBasicParsing    = $true
                    Method             = 'GET'
                }

                $Response = Invoke-WebRequest @WebRequestArgs
                $MimeType = $Response.Headers.'Content-Type'
                $DesiredExtension = switch -regex ($MimeType) {
                    'image/jpeg|image/jpg' { 'jpg' }
                    'image/png' { 'png' }
                    'image/gif' { 'gif' }
                    'image/bmp|image/x-windows-bmp|image/x-bmp' { 'bmp' }
                    'image/x-icon|image/vnd.microsoft.icon|application/ico' { 'ico' }
                    default { throw "Unsupported image type: $MimeType" }
                }

                $Path = "$BaseName.$DesiredExtension"
                $Response.Content | Set-Content -Path $Path -Encoding Byte
                $File = Test-Path -Path $Path -ErrorAction SilentlyContinue
            }
            catch {
                Write-Log "Download failed: $_" -Level WARNING
                if ($Path -and (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
                    Remove-Item $Path -Force -ErrorAction SilentlyContinue
                }
                $File = $False
            }

            if ($File) {
                $i = $Attempts
            }
            $i++
        }

        if ($Path -and (Test-Path $Path)) {
            return $Path
        }
    }

    function ConvertFrom-Image {
        param($ImagePath, $Path)

        try {
            $image = [Drawing.Image]::FromFile($ImagePath)
        }
        catch [System.OutOfMemoryException] {
            Write-Log 'Image file is either unsupported or too large to process' -Level ERROR
            return
        }
        catch {
            Write-Log "Failed to load image: $_" -Level ERROR
            return
        }

        $bitmap = New-Object System.Drawing.Bitmap(255, 255, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $bitmap.SetResolution(255, 255)

        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($image, 0, 0, 255, 255)

        $RandomNumber = Get-Random -Maximum 1000000
        $png = "$env:TEMP\image-$RandomNumber.png"
        $bitmap.Save($png, [Drawing.Imaging.ImageFormat]::Png)

        $pngBytes = Get-Content -Path $png -AsByteStream
        $icoHeader = [byte[]]@(0, 0, 1, 0, 1, 0)
        $imageDataSize = $pngBytes.Length
        $icoDirectory = [byte[]]@(
            255, 255, 0, 0, 0, 0, 0, 0,
            ($imageDataSize -band 0xFF),
            ([Math]::Floor($imageDataSize / [Math]::Pow(2, 8)) -band 0xFF),
            ([Math]::Floor($imageDataSize / [Math]::Pow(2, 16)) -band 0xFF),
            ([Math]::Floor($imageDataSize / [Math]::Pow(2, 24)) -band 0xFF),
            22, 0, 0, 0
        )
        $iconData = $icoHeader + $icoDirectory + $pngBytes

        if (Test-Path $Path -ErrorAction SilentlyContinue) { Remove-Item $Path -Force }
        [IO.File]::WriteAllBytes($Path, $iconData)

        if (Test-Path $png -ErrorAction SilentlyContinue) { Remove-Item $png -Force }
        $bitmap.Dispose()
        $image.Dispose()
        $graphics.Dispose()
        [GC]::Collect()

        if ([Environment]::OSVersion.Version.Major -ge 10) {
            Invoke-Command { ie4uinit.exe -show } -ErrorAction SilentlyContinue
        }
        else {
            Invoke-Command { ie4uinit.exe -ClearIconCache } -ErrorAction SilentlyContinue
        }
    }

    function New-Shortcut {
        [CmdletBinding()]
        param(
            [Parameter()][String]$Arguments,
            [Parameter()][String]$IconPath,
            [Parameter(ValueFromPipeline = $True)][String]$Path,
            [Parameter()][String]$Target,
            [Parameter()][String]$WorkingDir
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
                    throw "Shortcut not created at $Path"
                }
            }
            finally {
                if ($ShellObject) {
                    [Runtime.InteropServices.Marshal]::ReleaseComObject($ShellObject) | Out-Null
                }
            }
        }
    }
}

process {
    try {
        if ($env:shortcutName -and $env:shortcutName -notlike 'null') { $Name = $env:shortcutName }
        if ($env:createTheShortcutFor -and $env:createTheShortcutFor -notlike 'null') {
            if ($env:createTheShortcutFor -eq 'All Users') { $AllUsers = $True }
            if ($env:createTheShortcutFor -eq 'All Existing Users') { $AllExistingUsers = $True }
        }
        if ($env:exePath -and $env:exePath -notlike 'null') { $ExePath = $env:exePath }
        if ($env:exeArguments -and $env:exeArguments -notlike 'null') { $Arguments = $env:exeArguments }
        if ($env:exeShouldStartIn -and $env:exeShouldStartIn -notlike 'null') { $StartIn = $env:exeShouldStartIn }
        if ($env:linkToIconFile -and $env:linkToIconFile -notlike 'null') { $IconUrl = $env:linkToIconFile }
        if ($env:iconStorageDirectory -and $env:iconStorageDirectory -notlike 'null') { $IconDirectory = $env:iconStorageDirectory }
        if ($env:base64Icon -notlike 'null') { $IconBase64 = $env:base64icon }

        if (-not $AllUsers -and -not $AllExistingUsers) {
            throw 'You must specify which desktop to create the shortcut on'
        }

        $invalidFileNames = '[<>:"/\\|?*\x00-\x1F]|\.$|\s$'
        if ($Name -match $invalidFileNames) {
            throw 'Name contains invalid characters: <>:"/\|?*'
        }

        $ExitCode = 0

        if (($Icon -or $IconUrl) -and -not $IconDirectory) {
            Write-Log 'Icon provided but no storage directory specified. Ignoring icon' -Level WARNING
            $ExitCode = 1
            $Icon = $null
            $IconUrl = $null
        }

        if ($Icon) {
            $FileName = Split-Path $Icon -Leaf
            if ($FileName -notmatch '\.(bmp|png|jpg|jpeg|ico|gif)$') {
                Write-Log 'Invalid icon format. Supported: png, jpg, jpeg, ico, gif, bmp' -Level WARNING
                $Icon = $null
            }

            if (-not (Test-Path $Icon -ErrorAction SilentlyContinue)) {
                Write-Log 'Icon file not found. Skipping icon' -Level WARNING
                $Icon = $null
            }
        }

        if ($IconDirectory -and -not (Test-Path $IconDirectory -ErrorAction SilentlyContinue)) {
            New-Item -ItemType Directory -Path $IconDirectory | Out-Null
        }

        if (-not (Test-IsElevated)) {
            throw 'Access Denied. Please run with Administrator privileges'
        }

        $ShortcutPath = New-Object System.Collections.Generic.List[String]
        $File = "$Name.lnk"

        if ($ExcludeUsers) { $ExcludedUsers = ($ExcludeUsers -split ',').Trim() }

        if ($AllUsers) {
            $ShortcutPath.Add("$env:Public\Desktop\$File")
        }

        if ($AllExistingUsers) {
            $UserProfiles = Get-UserHives -ExcludedUsers $ExcludedUsers
            foreach ($Profile in $UserProfiles) {
                $ShortcutPath.Add("$($Profile.Path)\Desktop\$File")
            }
        }

        $ShortcutArguments = @{
            Target     = $ExePath
            WorkingDir = $StartIn
            Arguments  = $Arguments
        }

        if ($IconUrl) {
            $Icon = Invoke-Download -URL $IconUrl -BaseName "$IconDirectory\$Name"
            if ($Icon -and -not (Test-Path $Icon -ErrorAction SilentlyContinue)) {
                $ExitCode = 1
                $Icon = $null
            }
        }

        if ($IconBase64 -and $IconDirectory -and -not $Icon -and -not $IconUrl) {
            Write-Log 'Converting base64 icon to image'
            ConvertFrom-Base64 -Base64 $IconBase64 -Path "$IconDirectory\$Name.Png"
            $Icon = "$IconDirectory\$Name.Png"
        }

        if ($Icon -and (Get-Item -Path $Icon).Extension -notlike '.ico') {
            $FileHash = (Get-FileHash -Path $Icon -Algorithm MD5).Hash
            Write-Log 'Converting image to icon format'
            ConvertFrom-Image -ImagePath $Icon -Path "$IconDirectory\$FileHash.ico"
            Remove-Item -Path $Icon -Force
            $Icon = "$IconDirectory\$FileHash.ico"
        }
        elseif ($Icon -and (Test-Path $Icon -ErrorAction SilentlyContinue)) {
            $FileHash = (Get-FileHash -Path $Icon -Algorithm MD5).Hash
            Move-Item -Path $Icon -Destination "$IconDirectory\$FileHash.ico"
            $Icon = "$IconDirectory\$FileHash.ico"
        }

        if ($Icon -and (Test-Path $Icon -ErrorAction SilentlyContinue)) {
            $ShortcutArguments['IconPath'] = $Icon
        }
        elseif ($Icon) {
            $ExitCode = 1
        }

        $ShortcutPath | New-Shortcut @ShortcutArguments

        Write-Log "Successfully created $($ShortcutPath.Count) shortcut(s)"
        exit $ExitCode
    }
    catch {
        Write-Log "Script failed: $_" -Level ERROR
        exit 1
    }
}

end {
    [GC]::Collect()
}