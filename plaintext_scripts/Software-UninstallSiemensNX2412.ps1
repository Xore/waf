#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls Siemens NX 2412 from the system.

.DESCRIPTION
    Removes Siemens NX 2412 CAD/CAM software from Windows systems using MSI uninstaller
    and manual cleanup of installation directories. The script performs a complete
    uninstallation including:
    - MSI-based uninstallation using product GUID
    - Removal of installation directory
    - Validation of successful removal
    - NinjaRMM field updates for tracking
    
    This script runs unattended without user interaction.

.PARAMETER None
    This script accepts no parameters.

.EXAMPLE
    .\Software-UninstallSiemensNX2412.ps1
    
    Completely removes Siemens NX 2412 from the system.

.NOTES
    File Name      : Software-UninstallSiemensNX2412.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3.0.0 standards (script-scoped exit code)
    - 1.0: Initial batch script version
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand for software removal
    Typical Duration: 5-15 minutes
    Timeout Setting: 30 minutes recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no system restart required)
    
    Fields Updated:
        - siemensNX2412Status (Uninstalled/Failed/Not Found)
        - siemensNX2412UninstallDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - MSI installer engine (built into Windows)
    
    Environment Variables: None
    
    Exit Codes:
        0 - Success (uninstalled or not found)
        1 - Failure (uninstall error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param ()

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-UninstallSiemensNX2412"
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:CLIFallbackCount = 0

    $ProductGuid = "{F56493C9-7EDE-4664-8675-203572276A2A}"
    $InstallPath = "C:\Program Files\Siemens\NX2412"

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

    function Test-ProductInstalled {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Guid
        )
        
        $RegistryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$Guid",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$Guid"
        )
        
        foreach ($Path in $RegistryPaths) {
            if (Test-Path $Path) {
                return $true
            }
        }
        
        return $false
    }
    
    $script:ExitCode = 0
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
        
        Write-Log "Checking if Siemens NX 2412 is installed" -Level INFO
        $IsInstalled = Test-ProductInstalled -Guid $ProductGuid
        
        if (-not $IsInstalled) {
            Write-Log "Siemens NX 2412 is not installed (MSI not found)" -Level INFO
            
            if (Test-Path $InstallPath) {
                Write-Log "Installation directory found, cleaning up" -Level INFO
                try {
                    Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction Stop
                    Write-Log "Installation directory removed" -Level SUCCESS
                } catch {
                    Write-Log "Failed to remove installation directory: $_" -Level WARN
                }
            }
            
            Set-NinjaField -FieldName "siemensNX2412Status" -Value "Not Found"
            Set-NinjaField -FieldName "siemensNX2412UninstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            $script:ExitCode = 0
        } else {
            Write-Log "Siemens NX 2412 found - starting uninstallation" -Level INFO
            Write-Log "Product GUID: $ProductGuid" -Level DEBUG
            
            Write-Log "Running MSI uninstaller (silent mode)" -Level INFO
            
            $MsiExecArgs = @(
                "/X$ProductGuid",
                "/q",
                "/norestart"
            )
            
            $MsiProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiExecArgs -Wait -PassThru -NoNewWindow
            $MsiExitCode = $MsiProcess.ExitCode
            
            Write-Log "MSI uninstaller exit code: $MsiExitCode" -Level DEBUG
            
            $SuccessCodes = @(0, 1605, 3010)
            
            if ($MsiExitCode -in $SuccessCodes) {
                if ($MsiExitCode -eq 0) {
                    Write-Log "MSI uninstallation completed successfully" -Level SUCCESS
                } elseif ($MsiExitCode -eq 1605) {
                    Write-Log "Product not found by MSI (already uninstalled)" -Level INFO
                } elseif ($MsiExitCode -eq 3010) {
                    Write-Log "Uninstallation succeeded (restart may be required)" -Level SUCCESS
                }
                
                Start-Sleep -Seconds 2
                
                Write-Log "Checking for installation directory" -Level INFO
                if (Test-Path $InstallPath) {
                    Write-Log "Removing installation directory: $InstallPath" -Level INFO
                    
                    try {
                        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction Stop
                        Write-Log "Installation directory removed successfully" -Level SUCCESS
                    } catch {
                        Write-Log "Failed to remove directory: $($_.Exception.Message)" -Level ERROR
                        throw
                    }
                } else {
                    Write-Log "Installation directory not found (already removed)" -Level INFO
                }
                
                Write-Log "Siemens NX 2412 uninstalled successfully" -Level SUCCESS
                
                Set-NinjaField -FieldName "siemensNX2412Status" -Value "Uninstalled"
                Set-NinjaField -FieldName "siemensNX2412UninstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                
                $script:ExitCode = 0
                
            } else {
                throw "MSI uninstaller failed with exit code: $MsiExitCode"
            }
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "siemensNX2412Status" -Value "Failed"
        Set-NinjaField -FieldName "siemensNX2412UninstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
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
        
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
