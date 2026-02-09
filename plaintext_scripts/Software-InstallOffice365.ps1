#Requires -Version 5.1

<#
.SYNOPSIS
    Installs Office 365 from a config file or creates a generic config file and installs.
.DESCRIPTION
    Installs Office 365 from a config file or creates a generic config file and installs.
    
    
    
    OLD 
    
    [String]$OfficeInstallDownloadPath = "$env:TEMP\Office365Install",
#>

[CmdletBinding()]
param(
    [Parameter()]
    [String]$ConfigurationXMLFile,
    [Parameter()]
    [String]$OfficeInstallDownloadPath = "C:\Temp\Office365Install",
    [Parameter()]
    [String]$officeVersionToInstall = "$env:officeversionToInstall",
    [Parameter()]
    [String]$Restart = $env:autorestart
)


$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

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
        PIDKEY = 'asdfasdfasdf'
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
        PIDKEY = 'adfasdfasdfadsfasdf'
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
        PIDKEY = 'adfasdfasdfasdf'
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
        PIDKEY = 'asdfasdfasdfasdf2'
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


    if ($env:linkToConfigurationXml -and $env:linkToConfigurationXml -notlike "null") { $ConfigurationXMLFile = $env:linkToConfigurationXml }
    if ($env:restartComputer -like "true") { $Restart = $True }
    $CleanUpInstallFiles = $True
    
    if ($ConfigurationXMLFile -and $ConfigurationXMLFile -notmatch "^http(s)?://") {
        Write-Host "[Warn] http(s):// is required to download the file. Adding https:// to your input...."
        $ConfigurationXMLFile = "https://$ConfigurationXMLFile"
        Write-Host "[Warn] New Url $ConfigurationXMLFile."
    }
    
    $SupportedTLSversions = [enum]::GetValues('Net.SecurityProtocolType')
    if ( ($SupportedTLSversions -contains 'Tls13') -and ($SupportedTLSversions -contains 'Tls12') ) {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
    }
    elseif ( $SupportedTLSversions -contains 'Tls12' ) {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    }
    else {
        Write-Host "[Warn] TLS 1.2 and or TLS 1.3 are not supported on this system. This script may fail!"
        if ($PSVersionTable.PSVersion.Major -lt 3) {
            Write-Host "[Warn] PowerShell 2 / .NET 2.0 doesn't support TLS 1.2."
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
    $ExcludeApps | ForEach-Object {
      $ExcludeAppsString += "<ExcludeApp ID =`"$_`" />"
    }
  }

  if ($LanguageIDs) {
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

  # PIDKEY String erstellen
  if ($PIDKEY) {
    $PIDKEYString = "PIDKEY=`"$PIDKEY`""
  }
  else {
    $PIDKEYString = $Null
  }

  # AutoActivate Property erstellen
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

  $OfficeXML
  
}

function Get-ODTURL {

  $OfficeDeploymentRegex = '"url":"(https:\/\/download\.microsoft\.com\/[^"]*officedeploymenttool[^"]*)"'

  [String]$MSWebPage = Invoke-RestMethod 'https://www.microsoft.com/en-us/download/details.aspx?id=49117'

  $MSWebPage | ForEach-Object {
    if ($_ -match $OfficeDeploymentRegex) {
      $matches[1]
    }
  }

}
    function Set-XMLFile {
        switch ($officeVersionToInstall) {
            { $OfficeConfigurations.ContainsKey($_) } {
                $config = $OfficeConfigurations[$officeVersionToInstall]
                $OfficeXML = Write-OfficeXMLFile @config
        
                # XML speichern
                $xmlPath = "$OfficeInstallDownloadPath\OfficeInstall.xml"
                $OfficeXML.Save($xmlPath)
        
                Write-Host "$officeVersionToInstall Office-Konfiguration erstellt: $xmlPath" -ForegroundColor Green
            }
            default {
                Write-Host "Unbekannte Office-Version: $officeVersionToInstall" -ForegroundColor Red
                $config = $OfficeConfigurations["Standard English"]
                $OfficeXML = Write-OfficeXMLFile @config
        
                # XML speichern
                $xmlPath = "$OfficeInstallDownloadPath\OfficeInstall.xml"
                $OfficeXML.Save($xmlPath)
        
                Write-Host "$officeVersionToInstall Office-Konfiguration erstellt: $xmlPath" -ForegroundColor Green
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
                Write-Host "[Warn] Unable to find the download link for the Office Deployment Tool at: $Uri. Attempt $i of 3."
                Start-Sleep -Seconds $($i * 30)
            }
            catch {
                Write-Host "[Warn] Unable to connect to the Microsoft website. Attempt $i of 3."
            }
        }
        
        if (-not $DownloadURL) {
            Write-Host "[Error] Unable to find the download link for the Office Deployment Tool at: $Uri"
            exit 1
        }
        return $DownloadURL
    }
    
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Invoke-Download {
        param(
            [Parameter()][String]$URL,
            [Parameter()][String]$Path,
            [Parameter()][int]$Attempts = 3,
            [Parameter()][Switch]$SkipSleep
        )
    
        Write-Host "[Info] URL '$URL' was given."
        Write-Host "[Info] Downloading the file..."

        $SupportedTLSversions = [enum]::GetValues('Net.SecurityProtocolType')
        if ( ($SupportedTLSversions -contains 'Tls13') -and ($SupportedTLSversions -contains 'Tls12') ) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
        }
        elseif ( $SupportedTLSversions -contains 'Tls12' ) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        }
        else {
            Write-Host "[Warn] TLS 1.2 and/or TLS 1.3 are not supported on this system. This download may fail!"
            if ($PSVersionTable.PSVersion.Major -lt 3) {
                Write-Host "[Warn] PowerShell 2 / .NET 2.0 doesn't support TLS 1.2."
            }
        }

        $i = 1
        While ($i -le $Attempts) {
            if (!($SkipSleep)) {
                $SleepTime = Get-Random -Minimum 3 -Maximum 15
                Write-Host "[Info] Waiting for $SleepTime seconds."
                Start-Sleep -Seconds $SleepTime
            }
            
            if ($i -ne 1) { Write-Host "" }
            Write-Host "[Info] Download Attempt $i"

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
                Write-Host "[Warn] An error has occurred while downloading!"
                Write-Host $_.Exception.Message
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
                Write-Host "[Warn] File failed to download."
                Write-Host ""
            }
            $i++
        }

        if (!(Test-Path $Path)) {
            Write-Host "[Error] Failed to download file."
            Write-Host "Please verify the URL of '$URL'."
            exit 1
        }
        else {
            return $Path
        }
    }

    function Find-UninstallKey {
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipeline)][String]$DisplayName,
            [Parameter()][Switch]$UninstallString
        )
        process {
            $UninstallList = New-Object System.Collections.Generic.List[Object]

            $Result = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Get-ItemProperty | 
                Where-Object { $_.DisplayName -like "*$DisplayName*" }
            if ($Result) { $UninstallList.Add($Result) }

            $Result = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Get-ItemProperty | 
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
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    if (-not (Test-Path $OfficeInstallDownloadPath )) {
        New-Item -Path $OfficeInstallDownloadPath -ItemType Directory | Out-Null
    }

    if (-not ($ConfigurationXMLFile)) {
        Set-XMLFile
    }
    else {
        Invoke-Download -URL $ConfigurationXMLFile -Path "$OfficeInstallDownloadPath\OfficeInstall.xml"
        try {
            [xml]::new().Load("$OfficeInstallDownloadPath\OfficeInstall.xml")
        }
        catch {
            Write-Host "[Error] The XML file is not valid. Please check the file and try again."
            exit 1
        }
    }

    $ConfigurationXMLPath = "$OfficeInstallDownloadPath\OfficeInstall.xml"
    $ODTInstallLink = Get-ODTURL

    Write-Host "[Info] Downloading the Office Deployment Tool..."
    Invoke-Download -URL $ODTInstallLink -Path "$OfficeInstallDownloadPath\ODTSetup.exe"

    try {
        Write-Host "[Info] Running the Office Deployment Tool..."
        Start-Process "$OfficeInstallDownloadPath\ODTSetup.exe" -ArgumentList "/quiet /extract:$OfficeInstallDownloadPath" -Wait -NoNewWindow
    }
    catch {
        Write-Host "[Warn] Error running the Office Deployment Tool. The error is below:"
        Write-Host "$_"
        exit 1
    }

    try {
        Write-Host "[Info] Downloading and installing Microsoft 365"
        $Install = Start-Process "$OfficeInstallDownloadPath\Setup.exe" -ArgumentList "/configure $ConfigurationXMLPath" -Wait -PassThru -NoNewWindow

        if ($Install.ExitCode -ne 0) {
            Write-Host "[Error] Exit Code does not indicate success! $Install.ExitCode"

            exit 1
        }
    }
    catch {
        Write-Host "[Warn] Error running the Office install. The error is below:"
        Write-Host "$_"
    }

    $OfficeInstalled = Find-UninstallKey -DisplayName "Microsoft 365"

    if ($CleanUpInstallFiles) {
        Write-Host "[Info] Cleaning up install files..."
        Remove-Item -Path $OfficeInstallDownloadPath -Force -Recurse
    }

    if ($OfficeInstalled) {
        Write-Host "[Info] $($OfficeInstalled.DisplayName) installed successfully!"
        if ($Restart -eq 'true') {
            Write-Host "[Info] Restarting the computer in 60 seconds..."
            Start-Process shutdown.exe -ArgumentList "-r -t 60" -Wait -NoNewWindow
        }
        exit 0
    }
    else {
        Write-Host "[Error] Microsoft 365 was not detected after the install ran!"
        exit 1
    }