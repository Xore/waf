#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs or updates Sysmon (System Monitor) with modular configuration.

.DESCRIPTION
    Downloads and installs Sysinternals Sysmon with Olaf Hartong's modular configuration.
    Sysmon is a Windows system service that monitors and logs system activity to the Windows
    event log. It provides detailed information about process creation, network connections,
    and file creation time changes.
    
    The script performs the following:
    - Validates administrator privileges
    - Checks if Sysmon is already installed
    - Downloads latest Sysmon from Microsoft Sysinternals
    - Downloads community-maintained modular configuration
    - Installs Sysmon64.exe with configuration
    - If already installed, updates configuration only
    - Verifies successful installation
    - Updates NinjaRMM custom fields with installation status
    
    Sysmon provides advanced security monitoring including:
    - Process creation and termination
    - Network connections
    - File creation timestamps
    - Registry modifications
    - Driver and DLL loading
    - DNS queries
    - WMI events
    
    This script runs unattended without user interaction.

.PARAMETER None
    This script accepts no parameters.

.EXAMPLE
    .\Software-InstallSysmon.ps1
    
    Installs Sysmon with modular configuration or updates existing installation.

.NOTES
    File Name      : Software-InstallSysmon.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards with NinjaRMM integration
    - 3.0: Refactored to V3.0 standards with Write-Log
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Initial deployment or configuration updates
    Typical Duration: 10-30 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no system restart required)
    
    Fields Updated:
        - sysmonInstallStatus (Installed/Updated/Failed)
        - sysmonInstallDate (timestamp)
        - sysmonVersion (version installed)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Internet access to download.sysinternals.com and github.com
    
    Environment Variables: None

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/sysinternals/downloads/sysmon
    https://github.com/olafhartong/sysmon-modular
#>

[CmdletBinding()]
param ()

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-InstallSysmon"
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
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

    function Get-SysmonVersion {
        try {
            $SysmonExe = "$env:SystemRoot\sysmon64.exe"
            if (Test-Path $SysmonExe) {
                $VersionInfo = (Get-Item $SysmonExe).VersionInfo
                return $VersionInfo.FileVersion
            }
            return $null
        } catch {
            return $null
        }
    }

    $ServiceName = 'Sysmon64'
    $TempPath = $env:TEMP
    $SysmonConfigUrl = 'https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml'
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if (-not (Test-IsElevated)) {
            throw "Administrator privileges required"
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        if (-not (Test-Path $TempPath)) {
            Write-Log "Creating temporary directory: $TempPath" -Level DEBUG
            New-Item -ItemType Directory -Force -Path $TempPath | Out-Null
        }
        
        Set-Location $TempPath
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $SysmonService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if ($SysmonService -and $SysmonService.Status -eq 'Running') {
            Write-Log "Sysmon is already installed and running" -Level INFO
            $CurrentVersion = Get-SysmonVersion
            Write-Log "Current version: $CurrentVersion" -Level INFO
            Write-Log "Updating configuration only" -Level INFO
            
            try {
                Write-Log "Downloading latest configuration" -Level DEBUG
                Invoke-WebRequest -Uri $SysmonConfigUrl -OutFile sysmonconfig-export.xml -UseBasicParsing -ErrorAction Stop
                
                Write-Log "Applying configuration update" -Level DEBUG
                Start-Process -NoNewWindow -FilePath "$env:SystemRoot\sysmon64.exe" -ArgumentList "-c sysmonconfig-export.xml" -Wait
                
                Write-Log "Sysmon configuration updated successfully" -Level SUCCESS
                
                Set-NinjaField -FieldName "sysmonInstallStatus" -Value "Updated"
                Set-NinjaField -FieldName "sysmonInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                if ($CurrentVersion) {
                    Set-NinjaField -FieldName "sysmonVersion" -Value $CurrentVersion
                }
                
                $ExitCode = 0
            } catch {
                throw "Failed to update configuration: $($_.Exception.Message)"
            }
        } else {
            Write-Log "Sysmon not detected - performing fresh installation" -Level INFO
            
            Write-Log "Cleaning up old temporary files" -Level DEBUG
            if (Test-Path "$TempPath\sysmon.zip") {
                Remove-Item "$TempPath\sysmon.zip" -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$TempPath\sysmon") {
                Remove-Item "$TempPath\sysmon" -Force -Recurse -ErrorAction SilentlyContinue
            }
            
            Write-Log "Downloading Sysmon from Sysinternals" -Level INFO
            Invoke-WebRequest -Uri https://download.sysinternals.com/files/Sysmon.zip -OutFile Sysmon.zip -UseBasicParsing -ErrorAction Stop
            
            Write-Log "Extracting Sysmon archive" -Level DEBUG
            Expand-Archive Sysmon.zip -Force -ErrorAction Stop
            
            Set-Location "$TempPath\Sysmon"
            
            Write-Log "Downloading modular configuration" -Level INFO
            Invoke-WebRequest -Uri $SysmonConfigUrl -OutFile sysmonconfig-export.xml -UseBasicParsing -ErrorAction Stop
            
            Write-Log "Installing Sysmon with configuration" -Level INFO
            Start-Process -NoNewWindow -FilePath ".\sysmon64.exe" -ArgumentList "-accepteula -i sysmonconfig-export.xml" -Wait
            
            Start-Sleep -Seconds 2
            
            $SysmonInstalled = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($SysmonInstalled -and $SysmonInstalled.Status -eq 'Running') {
                $InstalledVersion = Get-SysmonVersion
                Write-Log "Sysmon installed successfully" -Level SUCCESS
                Write-Log "Version: $InstalledVersion" -Level INFO
                
                Set-NinjaField -FieldName "sysmonInstallStatus" -Value "Installed"
                Set-NinjaField -FieldName "sysmonInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                if ($InstalledVersion) {
                    Set-NinjaField -FieldName "sysmonVersion" -Value $InstalledVersion
                }
                
                $ExitCode = 0
            } else {
                throw "Sysmon service not running after installation"
            }
            
            Write-Log "Cleaning up installation files" -Level DEBUG
            Set-Location $TempPath
            Remove-Item "$TempPath\sysmon.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item "$TempPath\sysmon" -Force -Recurse -ErrorAction SilentlyContinue
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "sysmonInstallStatus" -Value "Failed"
        Set-NinjaField -FieldName "sysmonInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
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
