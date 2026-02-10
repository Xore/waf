#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs .NET Framework 3.5 on Windows systems using DISM.

.DESCRIPTION
    Enables .NET Framework 3.5 feature on Windows 10 and Windows Server systems using the
    Deployment Image Servicing and Management (DISM) tool. This component is required by
    many legacy applications and is not installed by default on modern Windows versions.
    
    The script performs the following:
    - Validates administrator privileges
    - Checks if .NET Framework 3.5 is already installed
    - Enables the NetFx3 feature using DISM with online mode
    - Downloads required files from Windows Update if needed
    - Verifies successful installation
    - Updates NinjaRMM custom fields with installation status
    
    This script runs unattended without user interaction.

.PARAMETER None
    This script accepts no parameters.

.EXAMPLE
    .\Software-InstallNetFramework35.ps1
    
    Installs .NET Framework 3.5 if not already present.

.NOTES
    File Name      : Software-InstallNetFramework35.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards implementation
    - 1.0: Initial single-line version
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or initial deployment
    Typical Duration: 2-10 minutes (depends on download speed)
    Timeout Setting: 15 minutes recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no system restart required)
    
    Fields Updated:
        - netFramework35Status (Installed/Failed/Already Installed)
        - netFramework35InstallDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Internet connection (for downloading components)
        - DISM tool (built into Windows)
    
    Environment Variables: None

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/dotnet/framework/install/dotnet-35-windows-10
#>

[CmdletBinding()]
param ()

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-InstallNetFramework35"
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

    function Test-NetFramework35Installed {
        try {
            $Feature = Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction Stop
            return ($Feature.State -eq 'Enabled')
        } catch {
            Write-Log "Unable to query NetFx3 feature status" -Level WARN
            return $false
        }
    }
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
        
        Write-Log "Checking if .NET Framework 3.5 is installed" -Level INFO
        $IsInstalled = Test-NetFramework35Installed
        
        if ($IsInstalled) {
            Write-Log ".NET Framework 3.5 is already installed" -Level SUCCESS
            
            Set-NinjaField -FieldName "netFramework35Status" -Value "Already Installed"
            Set-NinjaField -FieldName "netFramework35InstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            $ExitCode = 0
        } else {
            Write-Log ".NET Framework 3.5 is not installed - starting installation" -Level INFO
            Write-Log "This may take several minutes..." -Level INFO
            
            try {
                Write-Log "Executing DISM to enable NetFx3 feature" -Level DEBUG
                $DismArgs = @(
                    '/Online',
                    '/Enable-Feature',
                    '/FeatureName:NetFx3',
                    '/All',
                    '/NoRestart',
                    '/Quiet'
                )
                
                $DismProcess = Start-Process -FilePath "DISM.exe" -ArgumentList $DismArgs -Wait -PassThru -NoNewWindow
                $DismExitCode = $DismProcess.ExitCode
                
                Write-Log "DISM exit code: $DismExitCode" -Level DEBUG
                
                if ($DismExitCode -eq 0 -or $DismExitCode -eq 3010) {
                    Write-Log "DISM completed successfully" -Level SUCCESS
                    
                    Start-Sleep -Seconds 3
                    
                    $IsInstalledNow = Test-NetFramework35Installed
                    if ($IsInstalledNow) {
                        Write-Log ".NET Framework 3.5 installed successfully" -Level SUCCESS
                        
                        Set-NinjaField -FieldName "netFramework35Status" -Value "Installed"
                        Set-NinjaField -FieldName "netFramework35InstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                        
                        if ($DismExitCode -eq 3010) {
                            Write-Log "Reboot may be required to complete installation" -Level WARN
                        }
                        
                        $ExitCode = 0
                    } else {
                        throw "Installation reported success but feature is not enabled"
                    }
                } else {
                    throw "DISM failed with exit code: $DismExitCode"
                }
                
            } catch {
                Write-Log "Installation failed: $($_.Exception.Message)" -Level ERROR
                
                Set-NinjaField -FieldName "netFramework35Status" -Value "Failed"
                Set-NinjaField -FieldName "netFramework35InstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                
                throw
            }
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
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
