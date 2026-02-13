#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs Siemens NX 2412 CAD/CAM/CAE software.

.DESCRIPTION
    This script performs a silent installation of Siemens NX 2412, a comprehensive 
    Computer-Aided Design (CAD), Computer-Aided Manufacturing (CAM), and Computer-Aided 
    Engineering (CAE) software suite.
    
    The script performs the following:
    - Configures temporary directory for installation
    - Sets up license server configuration (SPLM_LICENSE_SERVER)
    - Removes existing installation if present
    - Executes MSI installer with configured parameters
    - Monitors installation exit codes
    - Updates NinjaRMM custom fields with installation status
    
    Installation Parameters:
    - INSTALLDIR: C:\Program Files\Siemens\NX2412
    - SETUPFILE: C:\Temp\NX\SiemensNX.msi
    - LICENSESERVER: 28000@licenseserver.company.com (configurable)
    - LANGUAGE: english
    - SETUPTYPE: typical
    - ADDLOCAL: all (installs all components)
    
    License Server Configuration:
    The script uses SPLM_LICENSE_SERVER (Siemens PLM License Server) pointing to
    port 28000 on server licenseserver.company.com. This must be accessible from the target system.
    
    MSI Exit Codes:
    - 0: Success
    - 1-7: Success with acceptable warnings
    - 8+: Error conditions
    - 3010: Success but restart required
    
    Prerequisites:
    - Siemens NX 2412 MSI installer at C:\Temp\NX\SiemensNX.msi
    - Network access to license server (28000@licenseserver.company.com)
    - Sufficient disk space (typically 10-30 GB depending on components)
    - Administrator privileges
    
    This script runs unattended without user interaction.

.PARAMETER None
    This script accepts no parameters. Configuration is hardcoded.

.EXAMPLE
    .\Software-InstallSiemensNX2.ps1
    
    Installs Siemens NX 2412 with default configuration.

.NOTES
    File Name      : Software-InstallSiemensNX2.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Converted from batch to PowerShell V3 standards
    - 1.0: Initial batch script release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: As needed (software deployment/upgrade)
    Typical Duration: 600-1800 seconds (10-30 minutes)
    Timeout Setting: 3600 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: May require restart after installation
    
    Fields Updated:
        - siemensNXInstallStatus (Success/Failed/Restart Required)
        - siemensNXInstallDate (timestamp)
        - siemensNXVersion (2412)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Siemens NX 2412 MSI installer file
        - Network access to license server
    
    Environment Variables: None

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param ()

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-InstallSiemensNX2"
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

    # Configuration
    $TempDir = "C:\TEMP"
    $LicenseServer = "28000@licenseserver.company.com"
    $InstallDir = "C:\Program Files\Siemens\NX2412"
    $SetupFile = "C:\Temp\NX\SiemensNX.msi"
    $LogFile = "C:\Temp\NX2412_MB_Daimler_Install.log"
    $Language = "english"
    $SetupType = "typical"
    $AddLocal = "all"
    $NXVersion = "2412"
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
        
        Write-Log "Configuring Siemens NX $NXVersion installation" -Level INFO
        Write-Log "License Server: $LicenseServer" -Level INFO
        Write-Log "Install Directory: $InstallDir" -Level INFO
        
        # Ensure TEMP directory exists
        if (-not (Test-Path $TempDir)) {
            Write-Log "Creating temporary directory: $TempDir" -Level INFO
            New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        }
        
        # Set TMP environment variable
        $env:TMP = $TempDir
        $env:TEMP = $TempDir
        Write-Log "Temporary directory configured" -Level DEBUG
        
        # Verify installer exists
        if (-not (Test-Path $SetupFile)) {
            throw "Installer not found at: $SetupFile"
        }
        Write-Log "Installer found: $SetupFile" -Level SUCCESS
        
        # Get installer file size
        $InstallerSize = (Get-Item $SetupFile).Length / 1MB
        Write-Log "Installer size: $($InstallerSize.ToString('F2')) MB" -Level INFO
        
        # Remove existing installation if present
        if (Test-Path $InstallDir) {
            Write-Log "Existing installation found at $InstallDir" -Level WARN
            Write-Log "Removing existing installation" -Level INFO
            
            try {
                Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction Stop
                Write-Log "Existing installation removed successfully" -Level SUCCESS
            } catch {
                Write-Log "Failed to remove existing installation: $($_.Exception.Message)" -Level ERROR
                Write-Log "Installation will continue and may overwrite" -Level WARN
            }
        }
        
        # Prepare MSI arguments
        $MsiArgs = @(
            "/i",
            "`"$SetupFile`"",
            "/qn",
            "/L*",
            "`"$LogFile`"",
            "ADDLOCAL=$AddLocal",
            "SETUPTYPE=$SetupType",
            "LANGUAGE=$Language",
            "LICENSESERVER=$LicenseServer",
            "INSTALLDIR=`"$InstallDir`""
        )
        
        Write-Log "Starting Siemens NX installation" -Level INFO
        Write-Log "This may take 10-30 minutes depending on system performance" -Level INFO
        Write-Log "MSI log file: $LogFile" -Level INFO
        
        # Execute MSI installation
        $Process = Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiArgs -Wait -PassThru -NoNewWindow
        
        $ExitCode = $Process.ExitCode
        
        Write-Log "Installation completed with exit code: $ExitCode" -Level INFO
        
        # Interpret exit code
        if ($ExitCode -eq 0) {
            Write-Log "Siemens NX $NXVersion installed successfully" -Level SUCCESS
            
            Set-NinjaField -FieldName "siemensNXInstallStatus" -Value "Success"
            Set-NinjaField -FieldName "siemensNXInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Set-NinjaField -FieldName "siemensNXVersion" -Value $NXVersion
            
            $ExitCode = 0
            
        } elseif ($ExitCode -ge 1 -and $ExitCode -le 7) {
            Write-Log "Installation completed with acceptable warnings (exit code: $ExitCode)" -Level WARN
            
            Set-NinjaField -FieldName "siemensNXInstallStatus" -Value "Success with Warnings"
            Set-NinjaField -FieldName "siemensNXInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Set-NinjaField -FieldName "siemensNXVersion" -Value $NXVersion
            
            $ExitCode = 0
            
        } elseif ($ExitCode -eq 3010) {
            Write-Log "Installation successful but restart required" -Level WARN
            
            Set-NinjaField -FieldName "siemensNXInstallStatus" -Value "Restart Required"
            Set-NinjaField -FieldName "siemensNXInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Set-NinjaField -FieldName "siemensNXVersion" -Value $NXVersion
            
            $ExitCode = 0
            
        } else {
            throw "Installation failed with exit code: $ExitCode. Check log file: $LogFile"
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        if (Test-Path $LogFile) {
            Write-Log "MSI log file available at: $LogFile" -Level INFO
        }
        
        Set-NinjaField -FieldName "siemensNXInstallStatus" -Value "Failed"
        Set-NinjaField -FieldName "siemensNXInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
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
        Write-Log "  Duration: $([Math]::Round($ExecutionTime / 60, 2)) minutes" -Level INFO
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
