#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs Siemens NX CAD/CAM/CAE software with specified license server configuration.

.DESCRIPTION
    Automates the silent installation of Siemens NX (formerly Unigraphics) engineering
    software using preconfigured setup files. This industrial-grade CAD/CAM/CAE application
    requires specific installation paths and license server configuration.
    
    The script performs the following:
    - Validates administrator privileges
    - Verifies setup.exe exists at specified path
    - Executes silent installation with MSI parameters
    - Configures license server connection
    - Verifies installation success
    - Updates NinjaRMM custom fields with installation status
    
    Siemens NX is a comprehensive product engineering solution used for:
    - 3D mechanical design (CAD)
    - Manufacturing (CAM)
    - Engineering analysis (CAE)
    - Product lifecycle management
    
    This script runs unattended without user interaction.

.PARAMETER SetupPath
    Full path to the Siemens NX Setup.exe installer.
    Default: C:\Temp\NX\Setup.exe

.PARAMETER InstallDir
    Target installation directory for Siemens NX.
    Default: C:\Program Files\Siemens\NX2412

.PARAMETER LicenseServer
    License server specification in format: port@hostname
    Example: 28000@licenseserver.company.com
    Default: 28000@licenseserver.company.com

.EXAMPLE
    .\Software-InstallSiemensNX.ps1
    
    Installs Siemens NX using default paths and license server.

.EXAMPLE
    .\Software-InstallSiemensNX.ps1 -InstallDir "D:\Siemens\NX2412" -LicenseServer "28000@myserver"
    
    Installs to custom directory with specified license server.

.NOTES
    File Name      : Software-InstallSiemensNX.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards implementation
    - 1.0: Initial single-line version
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or initial deployment
    Typical Duration: 15-60 minutes (depends on installation size)
    Timeout Setting: 120 minutes recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no system restart required)
    
    Fields Updated:
        - siemensNXInstallStatus (Success/Failed)
        - siemensNXInstallDate (timestamp)
        - siemensNXVersion (version installed)
        - siemensNXLicenseServer (license server configured)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Siemens NX setup files downloaded to specified path
        - Network access to license server
        - 20+ GB free disk space
    
    Environment Variables (Optional):
        - setupPath: Alternative to -SetupPath parameter
        - installDirectory: Alternative to -InstallDir parameter
        - licenseServerConfig: Alternative to -LicenseServer parameter

.LINK
    https://github.com/Xore/waf
    https://www.plm.automation.siemens.com/global/en/products/nx/
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Path to Siemens NX Setup.exe")]
    [string]$SetupPath = "C:\Temp\NX\Setup.exe",
    
    [Parameter(Mandatory=$false, HelpMessage="Installation directory")]
    [string]$InstallDir = "C:\Program Files\Siemens\NX2412",
    
    [Parameter(Mandatory=$false, HelpMessage="License server (port@hostname)")]
    [string]$LicenseServer = "28000@licenseserver.company.com"
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-InstallSiemensNX"
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
            'ERROR' { $script:ErrorCount++; $script:ExitCode = 1 }
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

    function Get-SiemensNXVersion {
        try {
            $UninstallPaths = @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
            
            $SiemensNX = Get-ChildItem -Path $UninstallPaths -ErrorAction SilentlyContinue |
                Get-ItemProperty |
                Where-Object { $_.DisplayName -like "*Siemens NX*" -or $_.DisplayName -like "*NX 2*" } |
                Select-Object -First 1
            
            if ($SiemensNX) {
                return $SiemensNX.DisplayVersion
            }
            return $null
        } catch {
            Write-Log "Error checking installed version: $_" -Level WARN
            return $null
        }
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:setupPath -and $env:setupPath -notlike "null") {
            $SetupPath = $env:setupPath
            Write-Log "Using setup path from environment: $SetupPath" -Level INFO
        }
        
        if ($env:installDirectory -and $env:installDirectory -notlike "null") {
            $InstallDir = $env:installDirectory
            Write-Log "Using install directory from environment: $InstallDir" -Level INFO
        }
        
        if ($env:licenseServerConfig -and $env:licenseServerConfig -notlike "null") {
            $LicenseServer = $env:licenseServerConfig
            Write-Log "Using license server from environment: $LicenseServer" -Level INFO
        }
        
        if (-not (Test-IsElevated)) {
            throw "Administrator privileges required"
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        Write-Log "Configuration:" -Level INFO
        Write-Log "  Setup Path: $SetupPath" -Level INFO
        Write-Log "  Install Directory: $InstallDir" -Level INFO
        Write-Log "  License Server: $LicenseServer" -Level INFO
        
        if (-not (Test-Path -Path $SetupPath -ErrorAction SilentlyContinue)) {
            throw "Setup.exe not found at: $SetupPath"
        }
        Write-Log "Setup file verified" -Level SUCCESS
        
        $ExistingVersion = Get-SiemensNXVersion
        if ($ExistingVersion) {
            Write-Log "Siemens NX version $ExistingVersion is already installed" -Level WARN
            Write-Log "Proceeding with installation (may upgrade or repair)" -Level INFO
        }
        
        Write-Log "Starting Siemens NX installation" -Level INFO
        Write-Log "This may take 15-60 minutes depending on system performance" -Level INFO
        
        $InstallArgs = @(
            '/w',
            '/s',
            "/v`"/qn INSTALLDIR=\`"$InstallDir\`" LICENSESERVER=$LicenseServer`""
        )
        
        Write-Log "Executing silent installation" -Level DEBUG
        Write-Log "  Command: $SetupPath" -Level DEBUG
        Write-Log "  Arguments: $($InstallArgs -join ' ')" -Level DEBUG
        
        $InstallProcess = Start-Process -FilePath $SetupPath -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
        $ProcessExitCode = $InstallProcess.ExitCode
        
        Write-Log "Setup process completed with exit code: $ProcessExitCode" -Level DEBUG
        
        if ($ProcessExitCode -eq 0 -or $ProcessExitCode -eq 3010) {
            Write-Log "Installation completed successfully" -Level SUCCESS
            
            if ($ProcessExitCode -eq 3010) {
                Write-Log "Reboot may be required to complete installation" -Level WARN
            }
            
            Start-Sleep -Seconds 5
            
            $InstalledVersion = Get-SiemensNXVersion
            if ($InstalledVersion) {
                Write-Log "Siemens NX version $InstalledVersion detected" -Level SUCCESS
                
                Set-NinjaField -FieldName "siemensNXInstallStatus" -Value "Success"
                Set-NinjaField -FieldName "siemensNXInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                Set-NinjaField -FieldName "siemensNXVersion" -Value $InstalledVersion
                Set-NinjaField -FieldName "siemensNXLicenseServer" -Value $LicenseServer
            } else {
                Write-Log "Installation reported success but version not detected" -Level WARN
                
                Set-NinjaField -FieldName "siemensNXInstallStatus" -Value "Success (version not detected)"
                Set-NinjaField -FieldName "siemensNXInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                Set-NinjaField -FieldName "siemensNXLicenseServer" -Value $LicenseServer
            }
            
        } elseif ($ProcessExitCode -eq 1641) {
            Write-Log "Installation completed, system restart initiated" -Level SUCCESS
            
            Set-NinjaField -FieldName "siemensNXInstallStatus" -Value "Success (reboot required)"
            Set-NinjaField -FieldName "siemensNXInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Set-NinjaField -FieldName "siemensNXLicenseServer" -Value $LicenseServer
            
        } else {
            throw "Installation failed with exit code: $ProcessExitCode"
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "siemensNXInstallStatus" -Value "Failed"
        Set-NinjaField -FieldName "siemensNXInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
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
