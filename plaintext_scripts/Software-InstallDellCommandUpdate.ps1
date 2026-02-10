#Requires -Version 5.1

<#
.SYNOPSIS
    Installs and configures Dell Command Update along with required dependencies on Dell systems.

.DESCRIPTION
    Automates the installation and configuration of Dell Command Update (DCU) on Dell-manufactured
    systems. The script performs comprehensive system management tasks:
    
    1. Verifies system is Dell-manufactured
    2. Removes legacy Dell Update applications
    3. Installs .NET 8.0 Desktop Runtime (required dependency)
    4. Downloads and installs latest Dell Command Update
    5. Configures automatic update settings
    6. Applies available driver and firmware updates
    7. Optionally schedules system reboot
    
    The script retrieves the latest versions of DCU and .NET Runtime from official sources,
    validates downloads using SHA-256/SHA-512 checksums, and ensures clean installation
    by removing conflicting legacy versions.
    
    Dell Command Update provides:
    - Automated driver updates
    - Firmware updates
    - BIOS updates
    - Application updates
    - System health monitoring
    
    The script configures DCU to automatically download and install updates while suspending
    BitLocker during updates and preventing automatic reboots.

.PARAMETER Reboot
    If specified, schedules a system reboot 60 seconds after script completion to apply updates.
    Default: Not specified (no automatic reboot)

.EXAMPLE
    .\Software-InstallDellCommandUpdate.ps1
    
    Installs Dell Command Update and applies updates without rebooting.

.EXAMPLE
    .\Software-InstallDellCommandUpdate.ps1 -Reboot
    
    Installs Dell Command Update, applies updates, and schedules reboot in 60 seconds.

.NOTES
    Script Name:    Software-InstallDellCommandUpdate.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Minimum OS: Windows 10, Windows Server 2016
    
    Execution Context: SYSTEM or Administrator required
    Execution Frequency: Quarterly or as needed
    Typical Duration: 10-30 minutes (depends on updates available)
    Timeout Setting: 60 minutes recommended
    
    User Interaction: None (silent installation)
    Restart Behavior: Optional via -Reboot parameter
    
    NinjaRMM Fields Updated: None
    
    Dependencies:
        - Administrator privileges (mandatory)
        - Internet connectivity (to download DCU and .NET Runtime)
        - Dell system (script exits gracefully on non-Dell hardware)
        - 2+ GB free disk space
    
    Exit Codes:
        0 - Success (DCU installed/updated or not needed, or non-Dell system)
        1 - Installation failed, checksum validation failed, or DCU CLI execution failed

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://www.dell.com/support/kbdoc/en-us/000177325/dell-command-update
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [Switch]$Reboot
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    Set-StrictMode -Version Latest
    Set-Location -Path $env:SystemRoot
    
    $ScriptVersion = "3.0"
    $ScriptName = "Software-InstallDellCommandUpdate"
    $StartTime = Get-Date
    
    function Write-Log {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [ValidateSet('INFO', 'WARNING', 'ERROR')]
            [string]$Level = 'INFO'
        )
        
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR'   { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default   { Write-Host $logMessage }
        }
    }
    
    function Get-Architecture {
        if ($null -ne $ENV:PROCESSOR_ARCHITEW6432) { 
            $Architecture = $ENV:PROCESSOR_ARCHITEW6432 
        }
        else {     
            if ((Get-CimInstance -ClassName CIM_OperatingSystem -ErrorAction Ignore).OSArchitecture -like 'ARM*') {
                if ([Environment]::Is64BitOperatingSystem) { $Architecture = 'arm64' }  
                else { $Architecture = 'arm' }
            }
            if ($null -eq $Architecture) { $Architecture = $ENV:PROCESSOR_ARCHITECTURE }
        }
        
        switch ($Architecture.ToLowerInvariant()) {
            { ($_ -eq 'amd64') -or ($_ -eq 'x64') } { return 'x64' }
            { $_ -eq 'x86' } { return 'x86' }
            { $_ -eq 'arm' } { return 'arm' }
            { $_ -eq 'arm64' } { return 'arm64' }
            default { throw "Architecture '$Architecture' not supported." }
        }
    }
    
    function Get-InstalledApps {
        param(
            [Parameter(Mandatory)][String[]]$DisplayNames,
            [String[]]$Exclude
        )
        
        $RegPaths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )
        
        $BroadMatch = @()
        foreach ($DisplayName in $DisplayNames) {
            $AppsWithBundledVersion = Get-ChildItem -Path $RegPaths -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" -and $null -ne $_.BundleVersion }
            if ($AppsWithBundledVersion) { $BroadMatch += $AppsWithBundledVersion }
            else { $BroadMatch += Get-ChildItem -Path $RegPaths -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" } }
        }
        
        $MatchedApps = @()
        foreach ($App in $BroadMatch) {
            if ($Exclude -notcontains $App.DisplayName) { $MatchedApps += $App }
        }
        
        return $MatchedApps | Sort-Object { [version]$_.BundleVersion } -Descending
    }
    
    function Remove-DellUpdateApps {
        param([String[]]$DisplayNames)
        
        $Apps = Get-InstalledApps -DisplayNames $DisplayNames -Exclude 'Dell SupportAssist OS Recovery Plugin for Dell Update'
        foreach ($App in $Apps) {
            Write-Log "Attempting to remove $($App.DisplayName)..."
            try {
                if ($App.UninstallString -match 'msiexec') {
                    $Guid = [regex]::Match($App.UninstallString, '\{[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\}').Value
                    Start-Process -NoNewWindow -Wait -FilePath 'msiexec.exe' -ArgumentList "/x $Guid /quiet /qn"
                }
                else { 
                    Start-Process -NoNewWindow -Wait -FilePath $App.UninstallString -ArgumentList '/quiet' 
                }
                Write-Log "Successfully removed $($App.DisplayName) [$($App.DisplayVersion)]"
            }
            catch { 
                Write-Log "Failed to remove $($App.DisplayName) [$($App.DisplayVersion)]" "WARNING"
                Write-Log $_.Exception.Message "WARNING"
                exit 1
            }
        }
    }
    
    function Install-DellCommandUpdate {
        function Get-LatestDellCommandUpdate {
            $DellKBURL = 'https://www.dell.com/support/kbdoc/en-us/000177325/dell-command-update'
            
            $Arch = Get-Architecture
            if ($Arch -like 'arm*') { 
                $FallbackDownloadURL = 'https://dl.dell.com/FOLDER13922742M/1/Dell-Command-Update-Windows-Universal-Application_TYXTK_WINARM64_5.6.0_A00.EXE'
                $FallbackChecksum = '1d0a86de060379b6324b1be35487d9891ffdbf90969b662332a294369a45d656'
                $FallbackVersion = '5.6.0'
            }
            else { 
                $FallbackDownloadURL = 'https://dl.dell.com/FOLDER13922692M/1/Dell-Command-Update-Windows-Universal-Application_2WT0J_WIN64_5.6.0_A00.EXE'
                $FallbackChecksum = 'e09b7fdf8ba5a19a837a95e1183e5a79c006be2f433909e177e24fd704c26aa1'
                $FallbackVersion = '5.6.0'
            }
            
            $Headers = @{
                'upgrade-insecure-requests' = '1'
                'user-agent'                = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'
                'accept'                    = 'text/html'
                'sec-fetch-site'            = 'same-origin'
                'sec-fetch-mode'            = 'navigate'
                'sec-fetch-user'            = '?1'
                'sec-fetch-dest'            = 'document'
                'referer'                   = "$DellKBURL"
                'accept-encoding'           = 'gzip'
                'accept-language'           = '*'
                'cache-control'             = 'max-age=0'
            }
            
            try {
                [String]$DellKB = Invoke-WebRequest -UseBasicParsing -Uri $DellKBURL -Headers $Headers -ErrorAction Ignore
                $LinkMatches = @($DellKB | Select-String '(https://www\.dell\.com.+driverid=[a-z0-9]+).+>Dell Command \| Update Windows Universal Application<\/a>' -AllMatches).Matches
                $KBLinks = foreach ($Match in $LinkMatches) { $Match.Groups[1].Value }
                
                $DownloadObjects = foreach ($Link in $KBLinks) {
                    $DownloadPage = Invoke-WebRequest -UseBasicParsing -Uri $Link -Headers $Headers -ErrorAction Ignore
                    if ($DownloadPage -match '(https://dl\.dell\.com.+Dell-Command-Update.+\.EXE)') { 
                        $Url = $Matches[1]
                        if ($DownloadPage -match 'SHA-256:.*?([a-fA-F0-9]{64})') { $Checksum = $Matches[1] }
                        [PSCustomObject]@{
                            URL      = $Url
                            Checksum = $Checksum
                        }
                    }
                }
                
                if ($Arch -like 'arm*') { $DownloadObject = $DownloadObjects | Where-Object { $_.URL -like '*winarm*' } }
                else { $DownloadObject = $DownloadObjects | Where-Object { $_.URL -notlike '*winarm*' } }
            }
            catch {}
            finally {
                if ($null -eq $DownloadObject.URL -or $null -eq $DownloadObject.Checksum) { 
                    Write-Log 'Unable to retrieve latest version info from Dell - reverting to fallback...' "WARNING"
                    $DownloadURL = $FallbackDownloadURL
                    $Checksum = $FallbackChecksum.ToUpper()
                    $Version = $FallbackVersion
                }
                else {
                    $DownloadURL = $DownloadObject.URL
                    $Checksum = ($DownloadObject.Checksum).ToUpper()
                    $Version = $DownloadURL | Select-String '[0-9]*\.[0-9]*\.[0-9]*' | ForEach-Object { $_.Matches.Value }
                }
            }
            
            return @{
                Checksum = $Checksum
                URL      = $DownloadURL
                Version  = $Version
            }
        }
        
        $LatestDellCommandUpdate = Get-LatestDellCommandUpdate
        $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDellCommandUpdate.URL -Leaf)
        $CurrentVersion = Get-InstalledApps -DisplayName 'Dell Command | Update'
        $CurrentVersionString = ("$($CurrentVersion.DisplayName) [$($CurrentVersion.DisplayVersion)]").Trim()
        
        Write-Log "Dell Command Update Version Info"
        Write-Log "Installed: $CurrentVersionString"
        Write-Log "Latest / Fallback: $($LatestDellCommandUpdate.Version)"
        
        if ($CurrentVersion.DisplayVersion -lt $LatestDellCommandUpdate.Version) {
            Write-Log "Dell Command Update installation needed"
            Write-Log "Downloading..."
            Invoke-WebRequest -Uri $LatestDellCommandUpdate.URL -OutFile $Installer -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
            
            if ($null -ne $LatestDellCommandUpdate.Checksum) {
                Write-Log "Verifying SHA256 checksum..."
                $InstallerChecksum = (Get-FileHash -Path $Installer -Algorithm SHA256).Hash
                if ($InstallerChecksum -ne $LatestDellCommandUpdate.Checksum) {
                    Write-Log "SHA256 checksum verification failed - aborting..." "ERROR"
                    Remove-Item $Installer -Force -ErrorAction Ignore
                    exit 1
                }
            }
            else { 
                Write-Log "Unable to retrieve checksum from Dell for validation - skipping..." "WARNING" 
            }
            
            if ($CurrentVersion) { Remove-DellUpdateApps -DisplayNames 'Dell Command | Update' }
            
            Write-Log "Installing latest..."
            Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/s'
            
            $CurrentVersion = Get-InstalledApps -DisplayName 'Dell Command | Update'
            if ($CurrentVersion -match $LatestDellCommandUpdate.Version) {
                Write-Log "Successfully installed $($CurrentVersion.DisplayName) [$($CurrentVersion.DisplayVersion)]"
                Remove-Item $Installer -Force -ErrorAction Ignore 
            }
            else {
                Write-Log "Dell Command Update [$($LatestDellCommandUpdate.Version)] not detected after installation attempt" "ERROR"
                Remove-Item $Installer -Force -ErrorAction Ignore 
                exit 1
            }
        }
        else { 
            Write-Log "Dell Command Update installation / upgrade not needed" 
        }
    }
    
    function Install-DotNetDesktopRuntime {
        function Get-LatestDotNetDesktopRuntime {
            try {
                $BaseURL = 'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop'
                $Version = (Invoke-WebRequest -Uri "$BaseURL/8.0/latest.version" -UseBasicParsing).Content
                $Arch = Get-Architecture
                $URL = "$BaseURL/$Version/windowsdesktop-runtime-$Version-win-$Arch.exe"
                $ChecksumURL = "https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-desktop-$Version-windows-$Arch-installer"
                
                $DownloadPage = Invoke-WebRequest -UseBasicParsing -Uri $ChecksumURL -ErrorAction Ignore
                if ($DownloadPage -match 'id="checksum".*?([a-fA-F0-9]{128})') { $Checksum = $Matches[1] }
            }
            catch {}
            finally {
                if ($Version -notmatch '^\d+(\.\d+)+$') { 
                    $URL = $null
                    $Version = $null
                }
            }
            
            return @{
                Checksum = $Checksum
                URL      = $URL
                Version  = $Version
            }
        }
        
        $LatestDotNet = Get-LatestDotNetDesktopRuntime
        $CurrentVersion = (Get-InstalledApps -DisplayName 'Microsoft Windows Desktop Runtime').BundleVersion | Where-Object { $_ -like '8.*' }
        
        Write-Log ".NET 8.0 Desktop Runtime Info"
        Write-Log "Installed: $CurrentVersion"
        Write-Log "Latest: $($LatestDotNet.Version)"
        
        if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
        if ($CurrentVersion -lt $LatestDotNet.Version) {
            Write-Log ".NET 8.0 Desktop Runtime installation needed"
            Write-Log "Downloading..."
            $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDotNet.URL -Leaf)
            Invoke-WebRequest -Uri $LatestDotNet.URL -OutFile $Installer
            
            if ($null -ne $LatestDotNet.Checksum) {
                Write-Log "Verifying SHA512 checksum..."
                $InstallerChecksum = (Get-FileHash -Path $Installer -Algorithm SHA512).Hash
                if ($InstallerChecksum -ne $LatestDotNet.Checksum) {
                    Write-Log "SHA512 checksum verification failed - aborting..." "ERROR"
                    Remove-Item $Installer -Force -ErrorAction Ignore
                    exit 1
                }
            }
            else { 
                Write-Log "Unable to retrieve checksum from Microsoft for validation - skipping..." "WARNING" 
            }
            
            Write-Log "Installing..."
            Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/install /quiet /norestart'
            
            $CurrentVersion = (Get-InstalledApps -DisplayName 'Microsoft Windows Desktop Runtime').BundleVersion | Where-Object { $_ -like '8.*' }
            if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
            if ($CurrentVersion -match $LatestDotNet.Version) {
                Write-Log "Successfully installed .NET 8.0 Desktop Runtime [$CurrentVersion]"
                Remove-Item $Installer -Force -ErrorAction Ignore 
            }
            else {
                Write-Log ".NET 8.0 Desktop Runtime [$($LatestDotNet.Version)] not detected after installation attempt" "ERROR"
                Remove-Item $Installer -Force -ErrorAction Ignore 
                exit 1
            }
        }
        elseif ($null -eq $LatestDotNet.Version) { 
            Write-Log "Unable to retrieve latest .NET 8.0 Desktop Runtime version - skipping installation / upgrade" "WARNING"
        }
        else { 
            Write-Log ".NET 8.0 Desktop Runtime installation / upgrade not needed" 
        }
    }
    
    function Invoke-DellCommandUpdate {
        $DCU = (Resolve-Path "$env:SystemDrive\Program Files*\Dell\CommandUpdate\dcu-cli.exe" -ErrorAction SilentlyContinue).Path
        if ($null -eq $DCU) {
            Write-Log "Dell Command Update CLI was not detected." "ERROR"
            exit 1
        }
        
        try {
            Write-Log "Configuring DCU automatic updates..."
            Start-Process -NoNewWindow -Wait -FilePath $DCU -ArgumentList '/configure -scheduleAction=DownloadInstallAndNotify -updatesNotification=disable -forceRestart=disable -scheduleAuto -silent'
            
            Write-Log "Applying updates using dcu-cli..."
            Start-Process -NoNewWindow -Wait -FilePath $DCU -ArgumentList '/applyUpdates -autoSuspendBitLocker=enable -reboot=disable'
        }
        catch {
            Write-Log "Unable to apply updates using the dcu-cli." "ERROR"
            Write-Log $_.Exception.Message "ERROR"
            exit 1
        }
    }
    
    Write-Log "Starting $ScriptName v$ScriptVersion"
    
    if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
}

process {
    try {
        Write-Log "Checking device manufacturer..."
        if ((Get-CimInstance -ClassName Win32_BIOS).Manufacturer -notlike '*Dell*') {
            Write-Log "Not a Dell system. Aborting..."
            exit 0
        }
        
        Write-Log "Dell system detected - proceeding with installation"
        
        Write-Log "Removing legacy Dell Update applications..."
        Remove-DellUpdateApps -DisplayNames 'Dell Update'
        
        Write-Log "Installing .NET Desktop Runtime..."
        Install-DotNetDesktopRuntime
        
        Write-Log "Installing Dell Command Update..."
        Install-DellCommandUpdate
        
        Write-Log "Invoking Dell Command Update to apply available updates..."
        Invoke-DellCommandUpdate
        
        if ($Reboot) {
            Write-Log "Reboot specified - rebooting in 60 seconds..." "WARNING"
            Start-Process -Wait -NoNewWindow -FilePath 'shutdown.exe' -ArgumentList '/r /f /t 60 /c "This system will restart in 60 seconds to install driver and firmware updates. Please save and close your work." /d p:4:1'
        }
        else { 
            Write-Log "A reboot may be needed to complete the installation of driver and firmware updates."
        }
        
        exit 0
    }
    catch {
        Write-Log "An unexpected error occurred: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

end {
    if ($StartTime) {
        $executionTime = (Get-Date) - $StartTime
        Write-Log "Script execution time: $($executionTime.TotalSeconds) seconds"
    }
    [System.GC]::Collect()
}
