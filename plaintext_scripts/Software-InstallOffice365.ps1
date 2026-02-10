#Requires -Version 5.1

<#
.SYNOPSIS
    Installs Microsoft Office 365 using Office Deployment Tool with predefined or custom configurations.

.DESCRIPTION
    Automates the installation of Microsoft Office 365 (Microsoft 365 Apps) using the Office
    Deployment Tool (ODT). Supports predefined configurations for common scenarios or custom
    XML configuration files downloaded from a URL.
    
    The script includes several predefined configurations:
    - Standard German (O365ProPlusRetail, de-de, 64-bit)
    - Standard English (O365ProPlusRetail, en-us, 64-bit)
    - Project Standard 2019 Volume (German and English)
    - Visio Standard 2019 Volume (German and English)
    
    Each configuration specifies:
    - Office edition (O365ProPlusRetail, ProjectStd2019Volume, VisioStd2019Volume, etc.)
    - Architecture (64-bit or 32-bit)
    - Update channel (MonthlyEnterprise, Current, SemiAnnual, etc.)
    - Language(s) to install
    - Apps to exclude (Teams, Outlook, OneNote, etc.)
    - Licensing mode (subscription or volume)
    - Update settings
    
    The script handles the complete installation workflow:
    1. Download Office Deployment Tool (ODT) from Microsoft
    2. Create or download XML configuration file
    3. Extract ODT files
    4. Execute setup.exe with configuration
    5. Verify installation success
    6. Clean up temporary files
    7. Optionally restart the computer

.PARAMETER ConfigurationXMLFile
    URL to a custom Office configuration XML file.
    If provided, overrides predefined configurations.
    Must be a valid HTTP(S) URL.

.PARAMETER OfficeInstallDownloadPath
    Path where Office Deployment Tool and installation files will be downloaded.
    Default: C:\Temp\Office365Install

.PARAMETER officeVersionToInstall
    Name of predefined configuration to use.
    Options:
    - "Standard German"
    - "Standard English"
    - "Project Standard 2019 Volume German"
    - "Project Standard 2019 Volume English"
    - "Visio Standard 2019 Volume German"
    - "Visio Standard 2019 Volume English"

.PARAMETER Restart
    Whether to restart the computer after successful installation.
    Default: False

.EXAMPLE
    .\Software-InstallOffice365.ps1 -officeVersionToInstall "Standard English"
    
    Installs Office 365 ProPlus with English language and standard exclusions.

.EXAMPLE
    .\Software-InstallOffice365.ps1 -ConfigurationXMLFile "https://example.com/office-config.xml"
    
    Installs Office 365 using a custom configuration file from the specified URL.

.NOTES
    Script Name:    Software-InstallOffice365.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Minimum OS: Windows 10, Windows Server 2016
    
    Execution Context: SYSTEM or Administrator required
    Execution Frequency: As needed (software deployment)
    Typical Duration: 10-30 minutes (depends on network speed and configuration)
    Timeout Setting: 60 minutes recommended
    
    User Interaction: May show installation progress UI
    Restart Behavior: Optional via -Restart parameter
    
    NinjaRMM Fields Updated: None
    
    Dependencies:
        - Administrator privileges (mandatory)
        - Internet connectivity (to download ODT and Office files)
        - 10+ GB free disk space
    
    Exit Codes:
        0 - Office 365 successfully installed
        1 - Access denied, download failed, or installation failed

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/en-us/deployoffice/overview-office-deployment-tool
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [String]$ConfigurationXMLFile,
    
    [Parameter(Mandatory=$false)]
    [String]$OfficeInstallDownloadPath = "C:\Temp\Office365Install",
    
    [Parameter(Mandatory=$false)]
    [String]$officeVersionToInstall,
    
    [Parameter(Mandatory=$false)]
    [String]$Restart
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $VerbosePreference = 'Continue'
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0"
    $ScriptName = "Software-InstallOffice365"
    $StartTime = Get-Date
    $CleanUpInstallFiles = $True
    
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
    
    # Predefined Office configurations
    $OfficeConfigurations = @{
        "Standard German" = @{
            OfficeEdition = 'O365ProPlusRetail'
            OfficeArch = '64'
            Channel = 'MonthlyEnterprise'
            LanguageIDs = @('de-de')
            ExcludeApps = @('Groove', 'Lync', 'OutlookForWindows', 'Teams')
            AcceptEULA = 'TRUE'
            DisplayInstall = $true
            EnableUpdates = 'TRUE'
            ForceOpenAppShutdown = 'TRUE'
            SharedComputerLicensing = '0'
            KeepMSI = $false
            SetFileFormat = $true
        }
        "Standard English" = @{
            OfficeEdition = 'O365ProPlusRetail'
            OfficeArch = '64'
            Channel = 'MonthlyEnterprise'
            LanguageIDs = @('en-us')
            ExcludeApps = @('Groove', 'Lync', 'OutlookForWindows')
            AcceptEULA = 'TRUE'
            DisplayInstall = $true
            EnableUpdates = 'TRUE'
            ForceOpenAppShutdown = 'TRUE'
            SharedComputerLicensing = '0'
            KeepMSI = $false
            SetFileFormat = $true
        }
        "Project Standard 2019 Volume German" = @{
            OfficeEdition = 'ProjectStd2019Volume'
            OfficeArch = '64'
            Channel = 'MonthlyEnterprise'
            LanguageIDs = @('de-de')
            PIDKEY = 'YOUR-LICENSE-KEY-HERE'
            AutoActivate = '1'
            AcceptEULA = 'TRUE'
            DisplayInstall = $true
            EnableUpdates = 'TRUE'
            ForceOpenAppShutdown = 'TRUE'
            SharedComputerLicensing = '0'
            SetFileFormat = $true
        }
        "Project Standard 2019 Volume English" = @{
            OfficeEdition = 'ProjectStd2019Volume'
            OfficeArch = '64'
            Channel = 'MonthlyEnterprise'
            LanguageIDs = @('en-us')
            PIDKEY = 'YOUR-LICENSE-KEY-HERE'
            AutoActivate = '1'
            AcceptEULA = 'TRUE'
            DisplayInstall = $true
            EnableUpdates = 'TRUE'
            ForceOpenAppShutdown = 'TRUE'
            SharedComputerLicensing = '0'
            SetFileFormat = $true
        }
        "Visio Standard 2019 Volume German" = @{
            OfficeEdition = 'VisioStd2019Volume'
            OfficeArch = '64'
            Channel = 'MonthlyEnterprise'
            LanguageIDs = @('de-de')
            PIDKEY = 'YOUR-LICENSE-KEY-HERE'
            AutoActivate = '1'
            ExcludeApps = @('Groove')
            AcceptEULA = 'TRUE'
            DisplayInstall = $true
            EnableUpdates = 'TRUE'
            ForceOpenAppShutdown = 'TRUE'
            SharedComputerLicensing = '0'
            SetFileFormat = $true
        }
        "Visio Standard 2019 Volume English" = @{
            OfficeEdition = 'VisioStd2019Volume'
            OfficeArch = '64'
            Channel = 'MonthlyEnterprise'
            LanguageIDs = @('en-us')
            PIDKEY = 'YOUR-LICENSE-KEY-HERE'
            AutoActivate = '1'
            ExcludeApps = @('Groove')
            AcceptEULA = 'TRUE'
            DisplayInstall = $true
            EnableUpdates = 'TRUE'
            ForceOpenAppShutdown = 'TRUE'
            SharedComputerLicensing = '0'
            SetFileFormat = $true
        }
    }
    
    function Write-OfficeXMLFile {
        [CmdletBinding(DefaultParameterSetName = 'NoXML')]
        param(
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('TRUE', 'FALSE')]$AcceptEULA = 'TRUE',
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('SemiAnnualPreview', 'SemiAnnual', 'MonthlyEnterprise', 'CurrentPreview', 'Current')]$Channel = 'Current',
            [Parameter(ParameterSetName = 'NoXML')][Switch]$DisplayInstall,
            [Parameter(ParameterSetName = 'NoXML')][Switch]$IncludeProject,
            [Parameter(ParameterSetName = 'NoXML')][Switch]$IncludeVisio,
            [Parameter(ParameterSetName = 'NoXML')][Array]$LanguageIDs,
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('Groove', 'Outlook', 'OutlookForWindows', 'OneNote', 'Access', 'OneDrive', 'Publisher', 'Word', 'Excel', 'PowerPoint', 'Teams', 'Lync')][Array]$ExcludeApps,
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('64', '32')]$OfficeArch = '64',
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('O365ProPlusRetail', 'O365BusinessRetail', 'ProjectStd2019Volume', 'ProjectPro2019Volume', 'VisioStd2019Volume', 'VisioPro2019Volume')]$OfficeEdition = 'O365ProPlusRetail',
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet(0, 1)]$SharedComputerLicensing = '0',
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('TRUE', 'FALSE')]$EnableUpdates = 'TRUE',
            [Parameter(ParameterSetName = 'NoXML')][String]$SourcePath,
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('TRUE', 'FALSE')]$PinItemsToTaskbar = 'TRUE',
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('TRUE', 'FALSE')]$ForceOpenAppShutdown = 'FALSE',
            [Parameter(ParameterSetName = 'NoXML')][Switch]$KeepMSI,
            [Parameter(ParameterSetName = 'NoXML')][Switch]$RemoveAllProducts,
            [Parameter(ParameterSetName = 'NoXML')][Switch]$SetFileFormat,
            [Parameter(ParameterSetName = 'NoXML')][Switch]$ChangeArch,
            [Parameter(ParameterSetName = 'NoXML')][String]$PIDKEY,
            [Parameter(ParameterSetName = 'NoXML')][ValidateSet('0', '1')]$AutoActivate
        )
        
        if ($ExcludeApps) {
            $ExcludeAppsString = ""
            $ExcludeApps | ForEach-Object {
                $ExcludeAppsString += "<ExcludeApp ID =`"$_`" />"
            }
        }
        
        if ($LanguageIDs) {
            $LanguageString = ""
            $LanguageIDs | ForEach-Object {
                $LanguageString += "<Language ID =`"$_`" />"
            }
        }
        else {
            $LanguageString = "<Language ID=`"MatchOS`" />"
        }
        
        if ($OfficeArch) {
            $OfficeArchString = "`"$OfficeArch`""
        }
        
        if ($ChangeArch) {
            $MigrateArch = "MigrateArch=`"TRUE`""
        }
        else {
            $MigrateArch = $Null
        }
        
        if ($KeepMSI) {
            $RemoveMSIString = $Null
        }
        else {
            $RemoveMSIString = '<RemoveMSI />'
        }
        
        if ($RemoveAllProducts) {
            $RemoveAllString = "<Remove All=`"TRUE`" />"
        }
        else {
            $RemoveAllString = $Null
        }
        
        if ($SetFileFormat) {
            $AppSettingsString = '<AppSettings>
      <Setup Name="Company" Value="MoellerGroup" />
      <User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas" />
      <User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
      <User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
    </AppSettings>'
        }
        else {
            $AppSettingsString = $Null
        }
        
        if ($Channel) {
            $ChannelString = "Channel=`"$Channel`""
        }
        else {
            $ChannelString = $Null
        }
        
        if ($SourcePath) {
            $SourcePathString = "SourcePath=`"$SourcePath`"" 
        }
        else {
            $SourcePathString = $Null
        }
        
        if ($DisplayInstall) {
            $SilentInstallString = 'Full'
        }
        else {
            $SilentInstallString = 'None'
        }
        
        if ($PIDKEY) {
            $PIDKEYString = "PIDKEY=`"$PIDKEY`""
        }
        else {
            $PIDKEYString = $Null
        }
        
        if ($AutoActivate) {
            $AutoActivateString = "<Property Name=`"AUTOACTIVATE`" Value=`"$AutoActivate`" />"
        }
        else {
            $AutoActivateString = $Null
        }
        
        if ($IncludeProject) {
            $ProjectString = "<Product ID=`"ProjectProRetail`"`>$ExcludeAppsString $LanguageString</Product>"
        }
        else {
            $ProjectString = $Null
        }
        
        if ($IncludeVisio) {
            $VisioString = "<Product ID=`"VisioProRetail`"`>$ExcludeAppsString $LanguageString</Product>"
        }
        else {
            $VisioString = $Null
        }
        
        $OfficeXML = [XML]@"
  <Configuration ID="e3d25963-6959-4e4c-9f57-6f2f66eda8bd">
    <Add OfficeClientEdition=$OfficeArchString $ChannelString $SourcePathString $MigrateArch >
      <Product ID="$OfficeEdition" $PIDKEYString>
        $LanguageString
        $ExcludeAppsString
      </Product>
      $ProjectString
      $VisioString
    </Add>  
    <Property Name="PinIconsToTaskbar" Value="$PinItemsToTaskbar" />
    <Property Name="FORCEAPPSHUTDOWN" Value="$ForceOpenAppShutdown" />
    <Property Name="SharedComputerLicensing" Value="$SharedComputerlicensing" />
    $AutoActivateString
    <Display Level="$SilentInstallString" AcceptEULA="$AcceptEULA" />
    <Updates Enabled="$EnableUpdates" />
    $AppSettingsString
    $RemoveMSIString
    $RemoveAllString
  </Configuration>
"@
        
        return $OfficeXML
    }
    
    function Set-XMLFile {
        switch ($officeVersionToInstall) {
            { $OfficeConfigurations.ContainsKey($_) } {
                $config = $OfficeConfigurations[$officeVersionToInstall]
                $OfficeXML = Write-OfficeXMLFile @config
                $xmlPath = "$OfficeInstallDownloadPath\OfficeInstall.xml"
                $OfficeXML.Save($xmlPath)
                Write-Log "$officeVersionToInstall Office configuration created: $xmlPath"
            }
            default {
                Write-Log "Unknown Office version: $officeVersionToInstall, using Standard English" "WARNING"
                $config = $OfficeConfigurations["Standard English"]
                $OfficeXML = Write-OfficeXMLFile @config
                $xmlPath = "$OfficeInstallDownloadPath\OfficeInstall.xml"
                $OfficeXML.Save($xmlPath)
                Write-Log "Standard English Office configuration created: $xmlPath"
            }
        }
    }
    
    function Get-ODTURL {
        $Uri = 'https://www.microsoft.com/en-us/download/details.aspx?id=49117'
        $DownloadURL = ""
        
        for ($i = 1; $i -le 3; $i++) {
            try {
                $MSWebPage = Invoke-WebRequest -Uri $Uri -UseBasicParsing -MaximumRedirection 10
                $DownloadURL = $MSWebPage.Links | Where-Object { $_.href -like "*officedeploymenttool*.exe" } | Select-Object -ExpandProperty href -First 1
                if ($DownloadURL) { break }
                Write-Log "Unable to find the download link for the Office Deployment Tool. Attempt $i of 3." "WARNING"
                Start-Sleep -Seconds $($i * 30)
            }
            catch {
                Write-Log "Unable to connect to the Microsoft website. Attempt $i of 3." "WARNING"
            }
        }
        
        if (-not $DownloadURL) {
            Write-Log "Unable to find the download link for the Office Deployment Tool at: $Uri" "ERROR"
            exit 1
        }
        return $DownloadURL
    }
    
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    
    function Invoke-Download {
        param(
            [Parameter()][String]$URL,
            [Parameter()][String]$Path,
            [Parameter()][int]$Attempts = 3,
            [Parameter()][Switch]$SkipSleep
        )
        
        Write-Log "URL '$URL' was given."
        Write-Log "Downloading the file..."
        
        $SupportedTLSversions = [enum]::GetValues('Net.SecurityProtocolType')
        if ( ($SupportedTLSversions -contains 'Tls13') -and ($SupportedTLSversions -contains 'Tls12') ) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
        }
        elseif ( $SupportedTLSversions -contains 'Tls12' ) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        }
        else {
            Write-Log "TLS 1.2 and/or TLS 1.3 are not supported on this system. This download may fail!" "WARNING"
        }
        
        $i = 1
        While ($i -le $Attempts) {
            if (!($SkipSleep)) {
                $SleepTime = Get-Random -Minimum 3 -Maximum 15
                Write-Log "Waiting for $SleepTime seconds."
                Start-Sleep -Seconds $SleepTime
            }
            
            Write-Log "Download Attempt $i"
            
            $PreviousProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue'
            try {
                if ($PSVersionTable.PSVersion.Major -lt 4) {
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.DownloadFile($URL, $Path)
                }
                else {
                    $WebRequestArgs = @{
                        Uri                = $URL
                        OutFile            = $Path
                        MaximumRedirection = 10
                        UseBasicParsing    = $true
                    }
                    Invoke-WebRequest @WebRequestArgs
                }
                $File = Test-Path -Path $Path -ErrorAction SilentlyContinue
            }
            catch {
                Write-Log "An error has occurred while downloading!" "WARNING"
                Write-Log $_.Exception.Message "WARNING"
                if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
                    Remove-Item $Path -Force -Confirm:$false -ErrorAction SilentlyContinue
                }
                $File = $False
            }
            
            $ProgressPreference = $PreviousProgressPreference
            if ($File) {
                $i = $Attempts
            }
            else {
                Write-Log "File failed to download." "WARNING"
            }
            $i++
        }
        
        if (!(Test-Path $Path)) {
            Write-Log "Failed to download file." "ERROR"
            Write-Log "Please verify the URL of '$URL'." "ERROR"
            exit 1
        }
        else {
            return $Path
        }
    }
    
    function Find-UninstallKey {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline)][String]$DisplayName,
            [Parameter()][Switch]$UninstallString
        )
        
        process {
            $UninstallList = New-Object System.Collections.Generic.List[Object]
            
            $Result = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Get-ItemProperty | 
                Where-Object { $_.DisplayName -like "*$DisplayName*" }
            if ($Result) { $UninstallList.Add($Result) }
            
            $Result = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Get-ItemProperty | 
                Where-Object { $_.DisplayName -like "*$DisplayName*" }
            if ($Result) { $UninstallList.Add($Result) }
            
            if ($UninstallString) {
                $UninstallList | Select-Object -ExpandProperty UninstallString -ErrorAction Ignore
            }
            else {
                $UninstallList
            } 
        }
    }
    
    Write-Log "Starting $ScriptName v$ScriptVersion"
    
    # Override with environment variables
    if ($env:linkToConfigurationXml -and $env:linkToConfigurationXml -notlike "null") { 
        $ConfigurationXMLFile = $env:linkToConfigurationXml 
        Write-Log "Using ConfigurationXMLFile from environment: $ConfigurationXMLFile"
    }
    if ($env:restartComputer -like "true") { 
        $Restart = $True 
        Write-Log "Restart enabled from environment variable"
    }
    if ($env:officeversionToInstall -and $env:officeversionToInstall -notlike "null") { 
        $officeVersionToInstall = $env:officeversionToInstall 
        Write-Log "Using Office version from environment: $officeVersionToInstall"
    }
    
    # URL validation
    if ($ConfigurationXMLFile -and $ConfigurationXMLFile -notmatch "^http(s)?://") {
        Write-Log "http(s):// is required to download the file. Adding https:// to your input...." "WARNING"
        $ConfigurationXMLFile = "https://$ConfigurationXMLFile"
        Write-Log "New Url $ConfigurationXMLFile."
    }
    
    # TLS configuration
    $SupportedTLSversions = [enum]::GetValues('Net.SecurityProtocolType')
    if ( ($SupportedTLSversions -contains 'Tls13') -and ($SupportedTLSversions -contains 'Tls12') ) {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
    }
    elseif ( $SupportedTLSversions -contains 'Tls12' ) {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    }
    else {
        Write-Log "TLS 1.2 and or TLS 1.3 are not supported on this system. This script may fail!" "WARNING"
    }
}

process {
    try {
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. Please run with Administrator privileges." "ERROR"
            exit 1
        }
        
        Write-Log "Creating download directory: $OfficeInstallDownloadPath"
        if (-not (Test-Path $OfficeInstallDownloadPath)) {
            New-Item -Path $OfficeInstallDownloadPath -ItemType Directory | Out-Null
        }
        
        if (-not ($ConfigurationXMLFile)) {
            Write-Log "Using predefined configuration"
            Set-XMLFile
        }
        else {
            Write-Log "Downloading custom configuration file"
            Invoke-Download -URL $ConfigurationXMLFile -Path "$OfficeInstallDownloadPath\OfficeInstall.xml"
            try {
                [xml]::new().Load("$OfficeInstallDownloadPath\OfficeInstall.xml")
            }
            catch {
                Write-Log "The XML file is not valid. Please check the file and try again." "ERROR"
                exit 1
            }
        }
        
        $ConfigurationXMLPath = "$OfficeInstallDownloadPath\OfficeInstall.xml"
        $ODTInstallLink = Get-ODTURL
        
        Write-Log "Downloading the Office Deployment Tool..."
        Invoke-Download -URL $ODTInstallLink -Path "$OfficeInstallDownloadPath\ODTSetup.exe"
        
        Write-Log "Extracting the Office Deployment Tool..."
        Start-Process "$OfficeInstallDownloadPath\ODTSetup.exe" -ArgumentList "/quiet /extract:$OfficeInstallDownloadPath" -Wait -NoNewWindow
        
        Write-Log "Downloading and installing Microsoft 365..."
        Write-Log "This may take 10-30 minutes depending on network speed"
        $Install = Start-Process "$OfficeInstallDownloadPath\Setup.exe" -ArgumentList "/configure $ConfigurationXMLPath" -Wait -PassThru -NoNewWindow
        
        if ($Install.ExitCode -ne 0) {
            Write-Log "Exit Code does not indicate success! Exit Code: $($Install.ExitCode)" "ERROR"
            exit 1
        }
        
        Write-Log "Verifying installation..."
        $OfficeInstalled = Find-UninstallKey -DisplayName "Microsoft 365"
        
        if ($CleanUpInstallFiles) {
            Write-Log "Cleaning up install files..."
            Remove-Item -Path $OfficeInstallDownloadPath -Force -Recurse -ErrorAction SilentlyContinue
        }
        
        if ($OfficeInstalled) {
            Write-Log "$($OfficeInstalled.DisplayName) installed successfully!"
            if ($Restart -eq 'true') {
                Write-Log "Restarting the computer in 60 seconds..." "WARNING"
                Start-Process shutdown.exe -ArgumentList "-r -t 60" -Wait -NoNewWindow
            }
            exit 0
        }
        else {
            Write-Log "Microsoft 365 was not detected after the install ran!" "ERROR"
            exit 1
        }
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
