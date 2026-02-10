#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Upgrades PowerShell to version 5.1 on supported Windows systems.

.DESCRIPTION
    Automates the upgrade of Windows PowerShell to version 5.1 on Windows Server 2012 R2
    and Windows 8.1 systems. The script handles prerequisite installations (.NET Framework 4.5.2)
    and manages the complete upgrade process including potential system restarts.
    
    The script performs the following:
    - Validates current PowerShell version and OS compatibility
    - Checks for Exchange Server (blocks upgrade if found)
    - Installs .NET Framework 4.5.2 if required
    - Downloads and installs Windows Management Framework 5.1
    - Handles automatic restarts when authorized
    - Creates detailed log file for tracking progress
    
    IMPORTANT NOTES:
    - Multiple reboots may be required during installation
    - Script will NOT run if Exchange Server is detected
    - User must manually log in after reboot for continuation
    - Log file: %TEMP%\upgrade_powershell.log tracks all operations
    
    Supported Operating Systems:
    - Windows Server 2012 R2
    - Windows 8.1
    
    This script runs unattended without user interaction when ForceRestart is enabled.

.PARAMETER Version
    Target PowerShell version to upgrade to.
    Default: "5.1"
    Currently only 5.1 is supported.

.PARAMETER ForceRestart
    Authorizes automatic system restart when required by installation.
    Default: $false
    Can be set via environment variable: $env:ForceRestart

.EXAMPLE
    .\Software-UpdatePowerShell51.ps1
    
    Upgrades to PowerShell 5.1 with manual restart (user intervention required).

.EXAMPLE
    .\Software-UpdatePowerShell51.ps1 -ForceRestart
    
    Upgrades to PowerShell 5.1 with automatic restart authorization.

.NOTES
    File Name      : Software-UpdatePowerShell51.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 8.1, Windows Server 2012 R2
    Version        : 3.0.0
    Original Author: Jordan Borean (ansible-windows project)
    Updated By     : WAF Team
    License        : MIT (original), WAF modifications
    Change Log:
    - 3.0.0: Complete V3 standards implementation with structured logging
    - 2.0: Added Script Variable support
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: One-time or as-needed for PS upgrades
    Typical Duration: 5-15 minutes (excludes restart time)
    Timeout Setting: 1800 seconds (30 minutes) recommended
    
    User Interaction: Manual login required after restart
    Restart Behavior: Restarts only if -ForceRestart provided or required by installer
    
    Fields Updated:
        - psUpgradeStatus (InProgress/Success/Failed/RestartRequired)
        - psUpgradeVersion (target version)
        - psUpgradeStartDate (start timestamp)
        - psUpgradeLastUpdate (last status update)
        - psCurrentVersion (current PowerShell version)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher (for script execution)
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Internet access to Microsoft download servers
        - 500+ MB free disk space for downloads
    
    Environment Variables (Optional):
        - ForceRestart: Set to "true" to enable automatic restart
        - Verbose: Set to "true" to enable verbose logging
    
    Exit Codes:
        0 - Success (upgrade completed or already at target version)
        1 - Failure (Exchange detected, unsupported OS, or installation error)

.LINK
    https://github.com/Xore/waf

.LINK
    https://github.com/jborean93/ansible-windows
    Original MIT-licensed implementation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Target PowerShell version")]
    [string]$Version = "5.1",
    
    [Parameter(Mandatory=$false, HelpMessage="Force automatic restart")]
    [switch]$ForceRestart = [System.Convert]::ToBoolean($env:ForceRestart)
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-UpdatePowerShell51"
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:CLIFallbackCount = 0

    $tmp_dir = $env:TEMP
    $log_file = "$tmp_dir\upgrade_powershell.log"

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
        
        Add-Content -Path $log_file -Value $LogMessage -ErrorAction SilentlyContinue
        
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

    function Invoke-Reboot {
        Write-Log "System restart required to continue PowerShell upgrade" -Level WARN
        Write-Log "Initiating restart in 30 seconds" -Level WARN
        
        Set-NinjaField -FieldName "psUpgradeStatus" -Value "RestartRequired"
        Set-NinjaField -FieldName "psUpgradeLastUpdate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        Start-Sleep -Seconds 3
        shutdown.exe /r /t 30
    }

    function Invoke-RunProcess($executable, $arguments) {
        $process = New-Object -TypeName System.Diagnostics.Process
        $psi = $process.StartInfo
        $psi.FileName = $executable
        $psi.Arguments = $arguments
        
        Write-Log "Executing: $executable $arguments" -Level DEBUG
        $process.Start() | Out-Null
        $process.WaitForExit() | Out-Null
        $exit_code = $process.ExitCode
        
        Write-Log "Process completed with exit code: $exit_code" -Level DEBUG
        return $exit_code
    }

    function Invoke-DownloadFile($url, $path) {
        Write-Log "Downloading: $url" -Level INFO
        Write-Log "Destination: $path" -Level DEBUG
        
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $client = New-Object -TypeName System.Net.WebClient
            $client.DownloadFile($url, $path)
            Write-Log "Download completed successfully" -Level SUCCESS
        } catch {
            throw "Download failed: $_"
        }
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        Write-Log "Log file: $log_file" -Level INFO
        
        if (-not (Test-IsElevated)) {
            throw "Administrator privileges required"
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        if (-not (Test-Path $tmp_dir)) {
            Write-Log "Creating temporary directory: $tmp_dir" -Level DEBUG
            New-Item -Path $tmp_dir -ItemType Directory | Out-Null
        }
        
        Set-NinjaField -FieldName "psUpgradeStatus" -Value "InProgress"
        Set-NinjaField -FieldName "psUpgradeVersion" -Value $Version
        Set-NinjaField -FieldName "psUpgradeStartDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        Write-Log "Checking for Exchange Server" -Level INFO
        $ExchangeService = Get-Service -Name MSExchangeServiceHost -ErrorAction SilentlyContinue
        $ExchangeCommand = Get-Command Exsetup.exe -ErrorAction SilentlyContinue
        
        if ($ExchangeService -or $ExchangeCommand) {
            throw "Exchange Server detected. PowerShell upgrade requires manual intervention for Exchange environments"
        }
        Write-Log "No Exchange Server detected" -Level INFO
        
        $current_ps_version = [version]"$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
        Write-Log "Current PowerShell version: $current_ps_version" -Level INFO
        
        Set-NinjaField -FieldName "psCurrentVersion" -Value $current_ps_version.ToString()
        
        if ($current_ps_version -eq [version]$Version) {
            Write-Log "PowerShell is already at target version $Version" -Level SUCCESS
            
            Set-NinjaField -FieldName "psUpgradeStatus" -Value "Success"
            Set-NinjaField -FieldName "psUpgradeLastUpdate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            $ExitCode = 0
            return
        }
        
        Write-Log "Upgrade required: $current_ps_version -> $Version" -Level INFO
        
        $os_version = [Version](Get-Item -Path "$env:SystemRoot\System32\kernel32.dll").VersionInfo.ProductVersion
        Write-Log "OS Version: $os_version" -Level DEBUG
        
        $architecture = $env:PROCESSOR_ARCHITECTURE
        if ($architecture -eq "AMD64") {
            $architecture = "x64"
        } else {
            $architecture = "x86"
        }
        Write-Log "Architecture: $architecture" -Level DEBUG
        
        $actions = @()
        
        switch ($Version) {
            "5.1" {
                if ($os_version -lt [version]"6.3") {
                    throw "Cannot upgrade Server 2008 to PowerShell v5.1. v3 is the latest supported version"
                }
                
                if ($os_version.Minor -lt 2) {
                    $wmf3_installed = Get-HotFix -Id "KB2506143" -ErrorAction SilentlyContinue
                    if ($wmf3_installed) {
                        throw "WMF 3.0 detected. Upgrade to 5.1 requires manual WMF 3.0 uninstallation first"
                    }
                }
                
                $actions += "5.1"
                break
            }
            default {
                throw "Version '$Version' is not supported in this upgrade script"
            }
        }
        
        Write-Log "Checking .NET Framework version" -Level INFO
        $dotnet_path = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        $dotnet_upgrade_needed = $false
        
        if (-not (Test-Path -Path $dotnet_path)) {
            $dotnet_upgrade_needed = $true
        } else {
            $dotnet_version = Get-ItemProperty -Path $dotnet_path -Name Release -ErrorAction SilentlyContinue
            if ($dotnet_version) {
                if ($dotnet_version.Release -lt 379893) {
                    $dotnet_upgrade_needed = $true
                }
            } else {
                $dotnet_upgrade_needed = $true
            }
        }
        
        if ($dotnet_upgrade_needed) {
            Write-Log ".NET Framework 4.5.2 upgrade required" -Level INFO
            $actions = @("dotnet") + $actions
        } else {
            Write-Log ".NET Framework 4.5.2 or higher already installed" -Level INFO
        }
        
        Write-Log "Installation plan: $($actions -join ' -> ')" -Level INFO
        
        foreach ($action in $actions) {
            $url = $null
            $file = $null
            $arguments = "/quiet /norestart"
            $error_msg = ""
            
            switch ($action) {
                "dotnet" {
                    Write-Log "Installing .NET Framework 4.5.2" -Level INFO
                    $url = "https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
                    $error_msg = "Failed to install .NET Framework 4.5.2"
                    $arguments = "/q /norestart"
                    break
                }
                "5.1" {
                    Write-Log "Installing Windows Management Framework 5.1" -Level INFO
                    if ($os_version.Minor -eq 2) {
                        $url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/W2K12-KB3191565-x64.msu"
                    } else {
                        if ($architecture -eq "x64") {
                            $url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu"
                        } else {
                            $url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1-KB3191564-x86.msu"
                        }
                    }
                    $error_msg = "Failed to install PowerShell 5.1"
                    break
                }
                default {
                    throw "Unknown action: $action"
                }
            }
            
            if ($null -eq $file) {
                $filename = $url.Split("/")[-1]
                $file = "$tmp_dir\$filename"
            }
            
            if ($null -ne $url) {
                Invoke-DownloadFile -url $url -path $file
            }
            
            Write-Log "Starting installation" -Level INFO
            $exit_code = Invoke-RunProcess -executable $file -arguments $arguments
            
            if ($exit_code -ne 0 -and $exit_code -ne 3010) {
                throw "$($error_msg): Exit code $exit_code"
            }
            
            if ($exit_code -eq 3010) {
                Write-Log "Installation requires system restart (exit code 3010)" -Level WARN
                
                if ($ForceRestart) {
                    Invoke-Reboot
                    $ExitCode = 0
                    return
                } else {
                    Write-Log "Restart required but not authorized" -Level WARN
                    Write-Log "Use -ForceRestart parameter to enable automatic restart" -Level WARN
                    
                    Set-NinjaField -FieldName "psUpgradeStatus" -Value "RestartRequired"
                    Set-NinjaField -FieldName "psUpgradeLastUpdate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    
                    $ExitCode = 0
                    return
                }
            }
        }
        
        Write-Log "PowerShell upgrade completed successfully" -Level SUCCESS
        
        Set-NinjaField -FieldName "psUpgradeStatus" -Value "Success"
        Set-NinjaField -FieldName "psUpgradeLastUpdate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        $ExitCode = 0
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "psUpgradeStatus" -Value "Failed"
        Set-NinjaField -FieldName "psUpgradeLastUpdate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        $ExitCode = 1
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
        
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
