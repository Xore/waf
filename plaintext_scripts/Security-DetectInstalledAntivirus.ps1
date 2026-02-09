#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Comprehensive antivirus detection and status monitoring for Windows systems

.DESCRIPTION
    Detects installed antivirus software across 19 supported products and monitors
    their operational status, definition dates, and update currency. The script uses
    multiple detection methods to ensure accurate identification:
    
    - Windows Security Center (workstations)
    - Registry installation keys
    - Process and service verification
    - Definition file parsing
    - Product-specific configuration files
    
    Detection Methods by Product:
    
    1. Registry-Based Detection:
       - Installation keys in HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall
       - Product-specific registry keys (ESET, Sophos, F-Secure, etc.)
       - Both 32-bit (Wow6432Node) and 64-bit registry paths
    
    2. File System Detection:
       - Program Files installation directories
       - Definition file locations
       - Configuration files (JSON, INI, XML formats)
    
    3. Runtime Detection:
       - Running processes (executable names)
       - Active Windows services
       - Security Center registration (Windows 10/11 workstations)
    
    Definition Status Monitoring:
    - Parses product-specific definition files for update dates
    - Compares against configurable threshold (default 7 days)
    - Handles various date formats (Unix timestamps, ISO, proprietary)
    - Reports "Up to Date" or "Outdated" status
    
    Supported Antivirus Products:
    - Avast Antivirus
    - AVG Antivirus Business Edition
    - Bitdefender Endpoint Security
    - CrowdStrike Falcon
    - Cylance PROTECT
    - Elastic Defend
    - ESET Security
    - F-Secure
    - Huntress
    - Kaspersky Endpoint Security
    - Kaspersky Small Office Security
    - Malwarebytes
    - Sentinel Agent (SentinelOne)
    - Sophos Intercept X
    - Trend Micro Maximum Security
    - Trend Micro Security Agent
    - VIPRE Business Agent
    - Webroot SecureAnywhere
    - Windows Defender
    
    The script exports results to NinjaRMM custom fields in multiple formats:
    - WYSIWYG HTML table with color-coded status
    - Text fields for product names, status, and definition dates

.PARAMETER DaysUntilOutdated
    Number of days before definitions are considered outdated (1-30, default 7).

.PARAMETER WYSIWYGField
    Name of WYSIWYG custom field for HTML table output.

.PARAMETER NameField
    Name of text custom field for comma-separated antivirus names.

.PARAMETER StatusField
    Name of text custom field for comma-separated running status values.

.PARAMETER DefinitionField
    Name of text custom field for definition dates and status.

.EXAMPLE
    .\Security-DetectInstalledAntivirus.ps1
    
    Detects antivirus with default 7-day threshold, displays to console.

.EXAMPLE
    .\Security-DetectInstalledAntivirus.ps1 -DaysUntilOutdated 14 -WYSIWYGField "avStatus"
    
    Uses 14-day threshold and saves HTML table to custom field.

.EXAMPLE
    .\Security-DetectInstalledAntivirus.ps1 -NameField "avName" -StatusField "avRunning" -DefinitionField "avDefs"
    
    Populates three separate custom fields with AV details.

.NOTES
    Script Name:    Security-DetectInstalledAntivirus.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required for Security Center and service queries)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~5-15 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - WYSIWYGField - HTML formatted table with AV status (if specified)
        - NameField - Comma-separated antivirus product names (if specified)
        - StatusField - Comma-separated running status (if specified)
        - DefinitionField - Definition dates and status (if specified)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges
        - Windows 10 or Server 2016 minimum
    
    Security Center API:
        - Available on Windows 10/11 workstations
        - Not available on Windows Server
        - Provides standardized AV status via WMI
    
    Exit Codes:
        0 - Success (antivirus detected or not found)
        1 - Failure (custom field update failed or validation error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Days until definitions considered outdated (1-30)")]
    [ValidateRange(1,30)]
    [int]$DaysUntilOutdated = 7,
    
    [Parameter(Mandatory=$false, HelpMessage="WYSIWYG custom field for HTML table")]
    [string]$WYSIWYGField,
    
    [Parameter(Mandatory=$false, HelpMessage="Text custom field for antivirus names")]
    [string]$NameField,
    
    [Parameter(Mandatory=$false, HelpMessage="Text custom field for running status")]
    [string]$StatusField,
    
    [Parameter(Mandatory=$false, HelpMessage="Text custom field for definition date/status")]
    [string]$DefinitionField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Security-DetectInstalledAntivirus"

# Support NinjaRMM environment variables for field names
if ($env:definitionsAgeLimitInDays) { $DaysUntilOutdated = [int]$env:definitionsAgeLimitInDays }
if ($env:wysiwygCustomFieldName) { $WYSIWYGField = $env:wysiwygCustomFieldName }
if ($env:antivirusNameCustomField) { $NameField = $env:antivirusNameCustomField }
if ($env:statusCustomFieldName) { $StatusField = $env:statusCustomFieldName }
if ($env:definitionDateAndStatusCustomField) { $DefinitionField = $env:definitionDateAndStatusCustomField }

# Trim whitespace from all parameters
if ($WYSIWYGField) { $WYSIWYGField = $WYSIWYGField.Trim() }
if ($NameField) { $NameField = $NameField.Trim() }
if ($StatusField) { $StatusField = $StatusField.Trim() }
if ($DefinitionField) { $DefinitionField = $DefinitionField.Trim() }

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# ANTIVIRUS DEFINITIONS
# ============================================================================

$AVsToCheck = @(
    [PSCustomObject]@{ Name = "Avast Antivirus"; ControlPanelName = "Avast Free Antivirus"; InstallPath = "$env:ProgramFiles\Avast Software\Avast"; RelevantProcesses = "AvastSvc","aswEngSrv"; RelevantServices = "avast! Antivirus" }
    [PSCustomObject]@{ Name = "AVG Antivirus Business Edition"; ControlPanelName = "AVG Business Security"; InstallPath = "$env:ProgramFiles\AVG\Antivirus"; RelevantProcesses = "AVGSvc","avgToolsSvc","bcc","bccavsvc"; RelevantServices = "AVG Antivirus","avgBcc" }
    [PSCustomObject]@{ Name = "Bitdefender Endpoint Security"; ControlPanelName = "Bitdefender Endpoint Security Tools","Bitdefender Agent"; InstallPath = "$env:ProgramFiles\Bitdefender\Endpoint Security"; RelevantProcesses = "EPSecurityService","EPProtectedService"; RelevantServices = "EPSecurityService","EPProtectedService" }
    [PSCustomObject]@{ Name = "CrowdStrike"; ControlPanelName = "CrowdStrike Windows Sensor"; InstallPath = "$env:ProgramFiles\CrowdStrike"; RelevantProcesses = "CSFalconService"; RelevantServices = "CSFalconService" }
    [PSCustomObject]@{ Name = "Cylance"; ControlPanelName = "Cylance OPTICS","Cylance Smart Antivirus","Cylance PROTECT"; InstallPath = "$env:ProgramFiles\Cylance" }
    [PSCustomObject]@{ Name = "Elastic Defend"; ControlPanelName = "Elastic Agent"; RelevantProcesses = "elastic-agent","elastic-endpoint"; RelevantServices = "Elastic Agent","ElasticEndpoint" }
    [PSCustomObject]@{ Name = "ESET Security"; ControlPanelName = "ESET Security","ESET Server Security"; InstallPath = "$env:ProgramFiles\ESET\ESET Security"; RelevantProcesses = "ekrn"; RelevantServices = "ekrn","efwd" }
    [PSCustomObject]@{ Name = "F-Secure"; ControlPanelName = "F-Secure"; InstallPath = "$env:ProgramFiles\F-Secure"; RelevantProcesses = "fshoster64"; RelevantServices = "fshoster" }
    [PSCustomObject]@{ Name = "Huntress"; ControlPanelName = "Huntress Agent"; InstallPath = "$env:ProgramFiles\Huntress"; RelevantProcesses = "HuntressAgent","HuntressRio"; RelevantServices = "HuntressAgent","HuntressRio" }
    [PSCustomObject]@{ Name = "Kaspersky Endpoint Security"; ControlPanelName = "Kaspersky Endpoint Security"; InstallPath = "${env:ProgramFiles(x86)}\Kaspersky Lab\KES*"; RelevantProcesses = "avp"; RelevantServices = "AVP.KES*" }
    [PSCustomObject]@{ Name = "Kaspersky Small Office Security"; ControlPanelName = "Kaspersky Small Office Security"; InstallPath = "${env:ProgramFiles(x86)}\Kaspersky Lab\Kaspersky Small Office Security*"; RelevantProcesses = "avp"; RelevantServices = "AVP*.*" }
    [PSCustomObject]@{ Name = "MalwareBytes"; InstallPath = "$env:ProgramFiles\Malwarebytes\Anti-Malware"; ControlPanelName = "Malwarebytes"; RelevantProcesses = "Malwarebytes"; RelevantServices = "MBAMService" }
    [PSCustomObject]@{ Name = "Sentinel Agent"; ControlPanelName = "Sentinel Agent"; InstallPath = "$env:ProgramFiles\SentinelOne"; RelevantProcesses = "SentinelServiceHost","SentinelStaticEngine"; RelevantServices = "SentinelAgent","SentinelHelperService" }
    [PSCustomObject]@{ Name = "Sophos Intercept X"; ControlPanelName = "Sophos Endpoint Agent","Sophos Endpoint Defense"; InstallPath = "$env:ProgramFiles\Sophos\Sophos Endpoint Agent","$env:ProgramFiles\Sophos\Endpoint Defense"; RelevantProcesses = "SophosFileScanner","SophosFS"; RelevantServices = "Sophos Endpoint Defense Service" }
    [PSCustomObject]@{ Name = "Trend Micro Maximum Security"; ControlPanelName = "Trend Micro Maximum Security"; InstallPath = "$env:ProgramFiles\Trend Micro"; RelevantProcesses = "coreServiceShell"; RelevantServices = "Amsp" }
    [PSCustomObject]@{ Name = "Trend Micro Security Agent"; ControlPanelName = "Trend Micro Worry-Free Business Security Agent"; InstallPath = "${env:ProgramFiles(x86)}\Trend Micro\Security Agent"; RelevantProcesses = "NTRTScan","TmListen"; RelevantServices = "ntrtscan","TmCCSF" }
    [PSCustomObject]@{ Name = "VIPRE Business Agent"; ControlPanelName = "VIPRE Business Agent"; InstallPath = "$env:ProgramFiles\VIPRE Business Agent"; RelevantProcesses = "SBAMSvc"; RelevantServices = "SBAMSvc" }
    [PSCustomObject]@{ Name = "Webroot SecureAnywhere"; DisplayName = "Webroot SecureAnywhere"; InstallPath = "$env:ProgramFiles\Webroot"; RelevantProcesses = "WRSA"; RelevantServices = "WRCoreService","WRSkyClient" }
    [PSCustomObject]@{ Name = "Windows Defender"; RelevantProcesses = "MsMpEng"; RelevantServices = "WinDefend" }
)

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Output "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'WARN'  { $script:WarningCount++ }
        'ERROR' { $script:ErrorCount++ }
    }
}

function Set-NinjaField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    # Handle WYSIWYG formatting
    if ($FieldName -eq $WYSIWYGField) {
        $ValueString = $ValueString -replace ' ', '&nbsp;'
    }
    
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' set successfully" -Level DEBUG
            return
        } else {
            throw "Ninja-Property-Set cmdlet not available"
        }
    } catch {
        Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
        
        try {
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            $CLIArgs = @("set", $FieldName, $ValueString)
            $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "CLI exit code: $LASTEXITCODE, Output: $CLIResult"
            }
            
            Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
            $script:CLIFallbackCount++
            
        } catch {
            Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
        }
    }
}

function Test-IsElevated {
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsServer {
    try {
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        return ($OS.ProductType -eq 2 -or $OS.ProductType -eq 3)
    } catch {
        Write-Log "Unable to determine if system is server: $_" -Level WARN
        return $false
    }
}

function Find-InstallKey {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [string]$DisplayName
    )
    
    process {
        $InstallList = New-Object System.Collections.Generic.List[Object]
        
        $RegistryPaths = @(
            "Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($Path in $RegistryPaths) {
            try {
                $Result = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | 
                    Get-ItemProperty | 
                    Where-Object { $_.DisplayName -like "*$DisplayName*" }
                
                if ($Result) {
                    $InstallList.Add($Result)
                }
            } catch {
                Write-Log "Failed to read registry path: $Path" -Level DEBUG
            }
        }
        
        return $InstallList
    }
}

function Get-SecurityCenterAV {
    if (Test-IsServer) {
        return $null
    }
    
    try {
        return Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction Stop
    } catch {
        Write-Log "Failed to query Security Center: $_" -Level DEBUG
        return $null
    }
}

function Get-DefinitionDate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AntiVirus
    )
    
    $DefinitionDate = $null
    
    switch ($AntiVirus.Name) {
        "Avast Antivirus" {
            $DefFile = "$env:ProgramFiles\Avast Software\Avast\defs\aswdefs.ini"
            if (Test-Path $DefFile) {
                $Content = (Get-Content $DefFile -ErrorAction SilentlyContinue) -replace '[^0-9]' | Where-Object { $_ }
                if ($Content) {
                    $DefinitionDate = [datetime]::ParseExact($Content, 'yyMMddHH', $null)
                    $DefinitionDate = [System.TimeZoneInfo]::ConvertTimeFromUtc($DefinitionDate, [System.TimeZoneInfo]::Local)
                }
            }
        }
        "AVG Antivirus Business Edition" {
            $DefFile = "$env:ProgramFiles\AVG\Antivirus\defs\aswdefs.ini"
            if (Test-Path $DefFile) {
                $Content = (Get-Content $DefFile -ErrorAction SilentlyContinue) -replace '[^0-9]' | Where-Object { $_ }
                if ($Content) {
                    $DefinitionDate = [datetime]::ParseExact($Content, 'yyMMddHH', $null)
                    $DefinitionDate = [System.TimeZoneInfo]::ConvertTimeFromUtc($DefinitionDate, [System.TimeZoneInfo]::Local)
                }
            }
        }
        "Bitdefender Endpoint Security" {
            $DefFiles = @(
                "$env:ProgramFiles\Bitdefender\Endpoint Security\update_statistics.xml",
                "$env:ProgramFiles\Bitdefender\Bitdefender Endpoint Security\update_statistics.xml"
            )
            
            foreach ($DefFile in $DefFiles) {
                if (Test-Path $DefFile) {
                    try {
                        [xml]$UpdateStats = Get-Content $DefFile
                        $UnixTime = $UpdateStats.UpdateStatistics.Antivirus.Update.succtime
                        if ($UnixTime) {
                            $UnixStart = [datetime]'1970-01-01 00:00:00'
                            $DefinitionDate = $UnixStart.AddSeconds($UnixTime).ToLocalTime()
                            break
                        }
                    } catch {
                        Write-Log "Failed to parse Bitdefender XML: $_" -Level DEBUG
                    }
                }
            }
        }
        "ESET Security" {
            try {
                $RegPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\ESET\ESET Security\CurrentVersion\Info"
                $ScannerVersion = (Get-ItemProperty $RegPath -ErrorAction Stop).ScannerVersion
                if ($ScannerVersion -match '\((\d{8})\)') {
                    $DefinitionDate = [datetime]::ParseExact($Matches[1], 'yyyyMMdd', $null)
                }
            } catch {}
        }
        "F-Secure" {
            try {
                $RegPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\F-Secure\Ultralight\updates"
                $Engines = Get-ChildItem $RegPath -ErrorAction SilentlyContinue
                $LatestVersions = @()
                
                foreach ($Engine in $Engines) {
                    $Versions = Get-ChildItem "Registry::$($Engine.Name)" -ErrorAction SilentlyContinue
                    $Latest = ($Versions | Sort-Object Name -Descending | Select-Object -First 1).PSChildName
                    if ($Latest) { $LatestVersions += [long]$Latest }
                }
                
                if ($LatestVersions) {
                    $LatestTimestamp = ($LatestVersions | Sort-Object -Descending)[0]
                    $UnixStart = [datetime]'1970-01-01 00:00:00'
                    $DefinitionDate = $UnixStart.AddSeconds($LatestTimestamp).ToLocalTime()
                }
            } catch {}
        }
        "Kaspersky Endpoint Security" {
            $KESCli = Get-ChildItem "${env:ProgramFiles(x86)}\Kaspersky Lab\KES*\kescli.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($KESCli) {
                try {
                    $TempFile = "$env:TEMP\KESdata.txt"
                    $Process = Start-Process $KESCli.FullName -ArgumentList "--opswat","GetDefinitionState" -RedirectStandardOutput $TempFile -NoNewWindow -Wait -PassThru
                    if ($Process.ExitCode -eq 0) {
                        $Data = Get-Content $TempFile -ErrorAction SilentlyContinue
                        if ($Data -match '\d+/\d+/\d{4}') {
                            $DefinitionDate = [datetime]::ParseExact($Data, 'M/d/yyyy H:m:s', $null).ToLocalTime()
                        }
                    }
                    Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
                } catch {}
            }
        }
        "MalwareBytes" {
            $ConfigFile = "$env:ProgramData\Malwarebytes\MBAMService\config\UpdateControllerConfig.json"
            if (Test-Path $ConfigFile) {
                try {
                    $Config = Get-Content $ConfigFile | Select-Object -Skip 1 | ConvertFrom-Json
                    if ($Config.db_pub_date) {
                        $UnixStart = [datetime]'1970-01-01 00:00:00'
                        $DefinitionDate = $UnixStart.AddSeconds($Config.db_pub_date).ToLocalTime()
                    }
                } catch {}
            }
        }
        "Sophos Intercept X" {
            try {
                $RegPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Sophos\EndpointDefense\Acknowledged"
                $VirusData = (Get-ItemProperty $RegPath -ErrorAction Stop).VirusDataVersion
                if ($VirusData) {
                    $DefinitionDate = [datetime]::ParseExact($VirusData, 'yyyyMMddHH', $null)
                }
            } catch {}
        }
        "Trend Micro Maximum Security" {
            try {
                $InstallTime = (Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\TrendMicro\AMSP" -ErrorAction Stop).InstallTime
                if ($InstallTime) {
                    $UnixStart = [datetime]'1970-01-01 00:00:00'
                    $DefinitionDate = $UnixStart.AddSeconds($InstallTime).ToLocalTime()
                }
            } catch {}
        }
        "Trend Micro Security Agent" {
            $IniFile = "${env:ProgramFiles(x86)}\Trend Micro\Security Agent\ofcscan.ini"
            if (Test-Path $IniFile) {
                try {
                    $Section = ""
                    Get-Content $IniFile | ForEach-Object {
                        if ($_ -match '^\[(.+)\]') { $Section = $_ }
                        if ($Section -match 'INI_PROGRAM_VERSION_SECTION' -and $_ -match '^Pattern_Last_Update=(.+)') {
                            $DateString = ($Matches[1] -replace '[^0-9]').Trim()
                            if ($DateString) {
                                $DefinitionDate = [datetime]::ParseExact($DateString, 'yyyyMMddHHmmss', $null)
                            }
                        }
                    }
                } catch {}
            }
        }
        "VIPRE Business Agent" {
            $DefFile = "$env:ProgramFiles\VIPRE Business Agent\Definitions\DefVer.txt"
            if (Test-Path $DefFile) {
                try {
                    $Content = (Get-Content $DefFile -ErrorAction Stop) -replace '.*,' | Where-Object { $_ }
                    if ($Content) {
                        $DefinitionDate = Get-Date $Content.Trim()
                    }
                } catch {}
            }
        }
        "Windows Defender" {
            try {
                if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
                    $Status = Get-MpComputerStatus -ErrorAction Stop
                    $DefinitionDate = $Status.AntivirusSignatureLastUpdated
                }
            } catch {}
        }
    }
    
    return $DefinitionDate
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    
    Write-Log "Detection threshold: $DaysUntilOutdated days" -Level INFO
    
    $DetectedAVs = New-Object System.Collections.Generic.List[Object]
    
    # Query Security Center (workstations only)
    $SecurityCenterAVs = Get-SecurityCenterAV
    
    if ($SecurityCenterAVs) {
        Write-Log "Found $($SecurityCenterAVs.Count) antivirus product(s) in Security Center" -Level INFO
        
        foreach ($AV in $SecurityCenterAVs) {
            $State = $AV.ProductState
            $RunningStatus = if (($State -band 0xF000) -eq 0x1000) { "Running" } else { "Not Running" }
            $UpToDate = if (($State -band 0x00F0) -eq 0x00) { "Up to Date" } else { "Outdated" }
            $DefDate = if ($AV.timestamp) { (Get-Date $AV.timestamp).ToShortDateString() } else { "Unknown" }
            
            $DetectedAVs.Add([PSCustomObject]@{
                "Antivirus Name" = $AV.displayName
                "Status" = $RunningStatus
                "Definition Status" = $UpToDate
                "Definition Date" = $DefDate
            })
        }
    }
    
    # Manual detection for all products
    foreach ($AV in $AVsToCheck) {
        $Installed = $false
        $RunningStatus = "Unknown"
        
        # Check installation key
        if ($AV.ControlPanelName) {
            foreach ($Name in $AV.ControlPanelName) {
                if (Find-InstallKey -DisplayName $Name) {
                    $Installed = $true
                    break
                }
            }
        }
        
        # Check install path
        if (-not $Installed -and $AV.InstallPath) {
            foreach ($Path in $AV.InstallPath) {
                if (Test-Path $Path -ErrorAction SilentlyContinue) {
                    $Item = Get-Item $Path -ErrorAction SilentlyContinue
                    if ($Item -and ($Item.PSIsContainer -eq $false -or (Get-ChildItem $Path -ErrorAction SilentlyContinue))) {
                        $Installed = $true
                        break
                    }
                }
            }
        }
        
        # Check processes
        if ($AV.RelevantProcesses) {
            $ProcessRunning = $false
            foreach ($Proc in $AV.RelevantProcesses) {
                if (Get-Process $Proc -ErrorAction SilentlyContinue) {
                    $ProcessRunning = $true
                    break
                }
            }
            if ($ProcessRunning) {
                $Installed = $true
                $RunningStatus = "Running"
            }
        }
        
        # Check services
        if ($AV.RelevantServices) {
            $ServiceRunning = $false
            foreach ($Svc in $AV.RelevantServices) {
                if (Get-Service $Svc -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }) {
                    $ServiceRunning = $true
                    break
                }
            }
            if ($ServiceRunning) {
                $Installed = $true
                if ($RunningStatus -eq "Unknown") {
                    $RunningStatus = "Running"
                }
            }
        }
        
        if ($Installed) {
            # Get definition date
            $DefDate = Get-DefinitionDate -AntiVirus $AV
            
            # Determine definition status
            $DefStatus = if ($AV.Name -in @("CrowdStrike","Elastic Defend","Huntress","Sentinel Agent","Webroot SecureAnywhere")) {
                "Not Applicable"
            } elseif ($DefDate) {
                if ((Get-Date).AddDays(-$DaysUntilOutdated) -ge $DefDate) {
                    "Outdated"
                } else {
                    "Up to Date"
                }
            } else {
                "Unknown"
            }
            
            # Skip if already detected via Security Center
            if ($DetectedAVs."Antivirus Name" -notcontains $AV.Name) {
                $DetectedAVs.Add([PSCustomObject]@{
                    "Antivirus Name" = $AV.Name
                    "Status" = $RunningStatus
                    "Definition Status" = $DefStatus
                    "Definition Date" = if ($DefDate) { $DefDate.ToShortDateString() } else { "Unknown" }
                })
            }
        }
    }
    
    # Display results
    Write-Log "" -Level INFO
    if ($DetectedAVs.Count -eq 0) {
        Write-Log "No antivirus software detected" -Level WARN
    } else {
        Write-Log "Detected $($DetectedAVs.Count) antivirus product(s):" -Level SUCCESS
        $DetectedAVs | Sort-Object "Antivirus Name" | Format-Table -AutoSize | Out-String | Write-Output
    }
    
    # Update custom fields
    if ($WYSIWYGField) {
        $HTML = if ($DetectedAVs.Count -eq 0) {
            "<h1 style='color: #D53948'>No antivirus detected</h1>"
        } else {
            $Table = $DetectedAVs | ConvertTo-Html -Fragment
            $Table = $Table -replace "<th>","<th><b>" -replace "</th>","</b></th>"
            $Table = $Table | ForEach-Object {
                if ($_ -match "Outdated") { $_ -replace "<tr>","<tr class=danger>" } else { $_ }
            }
            "<div class='card flex-grow-1'><div class='card-title-box'><div class='card-title'><i class='fa-solid fa-shield-virus'></i>&nbsp;&nbsp;Antivirus Status</div></div><div class='card-body' style='white-space: nowrap;'>$Table</div></div>"
        }
        Set-NinjaField -FieldName $WYSIWYGField -Value $HTML
    }
    
    if ($NameField) {
        $Names = if ($DetectedAVs.Count -eq 0) { "No antivirus detected" } else { ($DetectedAVs."Antivirus Name" -join ", ") }
        Set-NinjaField -FieldName $NameField -Value $Names
    }
    
    if ($StatusField) {
        $Statuses = if ($DetectedAVs.Count -eq 0) { "No antivirus detected" } else { ($DetectedAVs.Status -join ", ") }
        Set-NinjaField -FieldName $StatusField -Value $Statuses
    }
    
    if ($DefinitionField) {
        $Definitions = if ($DetectedAVs.Count -eq 0) {
            "No antivirus detected"
        } else {
            ($DetectedAVs | ForEach-Object {
                if ($_."Definition Date" -ne "Unknown") {
                    "$($_."Definition Date") | $($_."Definition Status")"
                } else {
                    $_."Definition Status"
                }
            }) -join ", "
        }
        Set-NinjaField -FieldName $DefinitionField -Value $Definitions
    }
    
    Write-Log "Antivirus detection completed successfully" -Level SUCCESS
    exit 0
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Products Detected: $($DetectedAVs.Count)" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    Write-Log "========================================" -Level INFO
}
