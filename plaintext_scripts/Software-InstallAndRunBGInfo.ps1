#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Downloads, installs and configures BGInfo to run automatically for all users.

.DESCRIPTION
    Downloads BGInfo from Sysinternals, installs it to System32\SysInternals, and
    configures it to run at system startup for all users. Supports custom BGI configuration
    files from local paths or URLs.
    
    The script performs the following:
    - Validates administrator privileges
    - Downloads BGInfo.exe from Microsoft Sysinternals
    - Creates startup shortcut for all users
    - Optionally downloads and applies custom BGI configuration
    - Updates NinjaRMM custom fields with installation status
    
    Note: Already logged-in users must logout/login to see BGInfo updates.
    This script runs unattended without user interaction.

.PARAMETER Config
    Optional path or URL to a BGI configuration file.
    Can be a local file path or HTTP/HTTPS URL.
    If not specified, uses BGInfo default configuration.
    Examples: "C:\Config\bginfo.bgi", "https://example.com/config.bgi"

.EXAMPLE
    .\Software-InstallAndRunBGInfo.ps1
    
    Installs BGInfo with default configuration.

.EXAMPLE
    .\Software-InstallAndRunBGInfo.ps1 -Config "C:\BGInfo\custom.bgi"
    
    Installs BGInfo with custom local configuration file.

.EXAMPLE
    .\Software-InstallAndRunBGInfo.ps1 -Config "https://example.com/bginfo.bgi"
    
    Installs BGInfo and downloads configuration from URL.

.NOTES
    File Name      : Software-InstallAndRunBGInfo.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards implementation
    - 1.1: Calculated Name Update
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or initial deployment
    Typical Duration: 5-15 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no system restart required)
    
    Fields Updated:
        - bginfoInstallStatus (Success/Failed)
        - bginfoInstallDate (timestamp)
        - bginfoConfigPath (configuration file path)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Internet access to live.sysinternals.com
    
    Environment Variables (Optional):
        - configFilePathOrUrlLink: Alternative to -Config parameter

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/sysinternals/downloads/bginfo
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Path or URL to BGI configuration file")]
    [string]$Config
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-InstallAndRunBGInfo"
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:CLIFallbackCount = 0

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
        $LogMessage = "[$Timestamp] [$Level] $Message"
        Write-Output $LogMessage
        
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

    function Invoke-Download {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$URL,
            [Parameter(Mandatory=$true)]
            [string]$Path,
            [Parameter(Mandatory=$false)]
            [int]$Attempts = 3
        )
        
        Write-Log "Downloading from: $URL" -Level INFO
        Write-Log "  Destination: $Path" -Level DEBUG
        
        $SupportedTLS = [enum]::GetValues('Net.SecurityProtocolType')
        if (($SupportedTLS -contains 'Tls13') -and ($SupportedTLS -contains 'Tls12')) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
        } elseif ($SupportedTLS -contains 'Tls12') {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        }
        
        $AttemptCounter = 1
        While ($AttemptCounter -le $Attempts) {
            Write-Log "  Download attempt $AttemptCounter of $Attempts" -Level DEBUG
            
            try {
                $WebRequestArgs = @{
                    Uri                = $URL
                    OutFile            = $Path
                    MaximumRedirection = 10
                    UseBasicParsing    = $true
                    ErrorAction        = 'Stop'
                }
                
                Invoke-WebRequest @WebRequestArgs
                
                if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
                    Write-Log "  Download successful" -Level SUCCESS
                    return
                }
            } catch {
                Write-Log "  Download attempt $AttemptCounter failed: $($_.Exception.Message)" -Level WARN
                
                if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
                    Remove-Item $Path -Force -ErrorAction SilentlyContinue
                }
            }
            
            $AttemptCounter++
            
            if ($AttemptCounter -le $Attempts) {
                Start-Sleep -Seconds 2
            }
        }
        
        throw "Failed to download file after $Attempts attempts"
    }

    function New-Shortcut {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Path,
            [Parameter(Mandatory=$true)]
            [string]$Target,
            [Parameter(Mandatory=$false)]
            [string]$Arguments,
            [Parameter(Mandatory=$false)]
            [string]$WorkingDir
        )
        
        Write-Log "Creating shortcut: $Path" -Level DEBUG
        
        $ShellObject = New-Object -ComObject "WScript.Shell"
        $Shortcut = $ShellObject.CreateShortcut($Path)
        $Shortcut.TargetPath = $Target
        
        if ($WorkingDir) { $Shortcut.WorkingDirectory = $WorkingDir }
        if ($Arguments) { $Shortcut.Arguments = $Arguments }
        
        $Shortcut.Save()
        
        if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
            throw "Failed to create shortcut at: $Path"
        }
        
        Write-Log "Shortcut created successfully" -Level SUCCESS
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:configFilePathOrUrlLink -and $env:configFilePathOrUrlLink -notlike "null") {
            $Config = $env:configFilePathOrUrlLink
            Write-Log "Using config from environment: $Config" -Level INFO
        }
        
        if (-not (Test-IsElevated)) {
            throw "Administrator privileges required"
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        $TargetDir = Join-Path -Path $env:WinDir -ChildPath "System32\SysInternals"
        $BGInfoExe = Join-Path -Path $TargetDir -ChildPath "BGInfo.exe"
        
        if (-not (Test-Path $TargetDir -ErrorAction SilentlyContinue)) {
            Write-Log "Creating directory: $TargetDir" -Level INFO
            New-Item -ItemType Directory -Path $TargetDir -Force -ErrorAction Stop | Out-Null
        }
        
        Write-Log "Downloading BGInfo from Sysinternals" -Level INFO
        Invoke-Download -URL "https://live.sysinternals.com/Bginfo.exe" -Path $BGInfoExe -Attempts 3
        
        if (-not (Test-Path $BGInfoExe -ErrorAction SilentlyContinue)) {
            throw "BGInfo.exe not found after download: $BGInfoExe"
        }
        
        Write-Log "BGInfo installed to: $BGInfoExe" -Level SUCCESS
        
        $ConfigPath = $null
        if ($Config) {
            Write-Log "Processing configuration: $Config" -Level INFO
            
            if (Test-Path -Path $Config -ErrorAction SilentlyContinue) {
                $ConfigPath = $Config
                Write-Log "Using local config file" -Level INFO
            } else {
                try {
                    $ConfigDir = Join-Path -Path $env:PROGRAMDATA -ChildPath "SysInternals"
                    if (-not (Test-Path -Path $ConfigDir -ErrorAction SilentlyContinue)) {
                        New-Item -ItemType Directory -Path $ConfigDir -Force -ErrorAction Stop | Out-Null
                    }
                    
                    $ConfigPath = Join-Path -Path $ConfigDir -ChildPath "bginfoConfig.bgi"
                    Write-Log "Downloading config from URL" -Level INFO
                    Invoke-Download -URL $Config -Path $ConfigPath -Attempts 3
                    
                } catch {
                    Write-Log "Failed to download config: $($_.Exception.Message)" -Level ERROR
                    throw "Failed to download or access configuration file"
                }
            }
        }
        
        $StartupPath = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\Windows\Start Menu\Programs\StartUp\StartupBGInfo.lnk"
        
        if (Test-Path -Path $StartupPath -ErrorAction SilentlyContinue) {
            Write-Log "Removing existing startup shortcut" -Level DEBUG
            Remove-Item -Path $StartupPath -Force -ErrorAction SilentlyContinue
        }
        
        if ($ConfigPath) {
            $Arguments = "/iq `"$ConfigPath`" /accepteula /timer:0 /silent"
            Write-Log "Creating startup shortcut with custom config" -Level INFO
        } else {
            $Arguments = "/accepteula /timer:0 /silent"
            Write-Log "Creating startup shortcut with default config" -Level INFO
        }
        
        New-Shortcut -Path $StartupPath -Target $BGInfoExe -Arguments $Arguments
        
        Write-Log "Startup shortcut created: $StartupPath" -Level SUCCESS
        
        Set-NinjaField -FieldName "bginfoInstallStatus" -Value "Success"
        Set-NinjaField -FieldName "bginfoInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        if ($ConfigPath) {
            Set-NinjaField -FieldName "bginfoConfigPath" -Value $ConfigPath
        }
        
        Write-Log "BGInfo installed and configured successfully" -Level SUCCESS
        Write-Log "Users must logout/login to see BGInfo on desktop" -Level INFO
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "bginfoInstallStatus" -Value "Failed"
        Set-NinjaField -FieldName "bginfoInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Summary:" -Level INFO
        Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "  Errors: $script:ErrorCount" -Level INFO
        Write-Log "  Warnings: $script:WarningCount" -Level INFO
        
        if ($script:CLIFallbackCount -gt 0) {
            Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
        }
        
        Write-Log "  Exit Code: $script:ExitCode" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
