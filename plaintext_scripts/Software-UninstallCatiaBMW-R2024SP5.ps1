#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls CATIA V5 R2024 SP5 BMW Edition from the system.

.DESCRIPTION
    Removes CATIA V5 R2024 SP5 BMW Edition CAD software from Windows systems by
    locating and executing the vendor-provided uninstall batch file. The script
    performs:
    - Validation of installation presence
    - Copying uninstall batch file to temp directory
    - Execution of vendor uninstaller
    - Cleanup of temporary files
    - NinjaRMM field updates for tracking
    
    This script runs unattended without user interaction.

.PARAMETER None
    This script accepts no parameters.

.EXAMPLE
    .\Software-UninstallCatiaBMW-R2024SP5.ps1
    
    Completely removes CATIA V5 R2024 SP5 BMW Edition from the system.

.NOTES
    File Name      : Software-UninstallCatiaBMW-R2024SP5.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Converted from batch to PowerShell with V3 standards
    - 1.0: Initial batch script version
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand for software removal
    Typical Duration: 5-20 minutes
    Timeout Setting: 45 minutes recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no system restart required)
    
    Fields Updated:
        - catiaBMWStatus (Uninstalled/Failed/Not Found)
        - catiaBMWUninstallDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - CATIA uninstall batch file at expected location
    
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
    $ScriptName = "Software-UninstallCatiaBMW-R2024SP5"
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:CLIFallbackCount = 0

    $UninstallBatchSource = "C:\CATIAV5\R2024SP5_BMW\win_b64\Uninstall.bat"
    $TempDirectory = "C:\Temp\Catia"
    $UninstallBatchTemp = "$TempDirectory\Uninstall.bat"

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
        
        Write-Log "Checking for CATIA BMW R2024 SP5 installation" -Level INFO
        
        if (-not (Test-Path $UninstallBatchSource)) {
            Write-Log "CATIA BMW R2024 SP5 not found (uninstall batch missing)" -Level INFO
            Write-Log "Expected location: $UninstallBatchSource" -Level DEBUG
            
            Set-NinjaField -FieldName "catiaBMWStatus" -Value "Not Found"
            Set-NinjaField -FieldName "catiaBMWUninstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            $ExitCode = 0
        } else {
            Write-Log "CATIA BMW R2024 SP5 found - starting uninstallation" -Level INFO
            Write-Log "Uninstall batch location: $UninstallBatchSource" -Level DEBUG
            
            Write-Log "Creating temporary directory" -Level DEBUG
            if (-not (Test-Path $TempDirectory)) {
                New-Item -Path $TempDirectory -ItemType Directory -Force | Out-Null
                Write-Log "Created: $TempDirectory" -Level DEBUG
            }
            
            Write-Log "Cleaning up old uninstall batch if exists" -Level DEBUG
            if (Test-Path $UninstallBatchTemp) {
                Remove-Item -Path $UninstallBatchTemp -Force -ErrorAction SilentlyContinue
            }
            
            Write-Log "Copying uninstall batch to temp directory" -Level INFO
            try {
                Copy-Item -Path $UninstallBatchSource -Destination $UninstallBatchTemp -Force -ErrorAction Stop
                Write-Log "Uninstall batch copied successfully" -Level SUCCESS
            } catch {
                throw "Failed to copy uninstall batch: $($_.Exception.Message)"
            }
            
            if (-not (Test-Path $UninstallBatchTemp)) {
                throw "Uninstall batch not found after copy operation"
            }
            
            Write-Log "Executing CATIA uninstaller" -Level INFO
            Write-Log "This may take several minutes..." -Level INFO
            
            try {
                $ProcessInfo = Start-Process -FilePath $UninstallBatchTemp -Wait -PassThru -NoNewWindow -ErrorAction Stop
                $UninstallExitCode = $ProcessInfo.ExitCode
                
                Write-Log "Uninstaller exit code: $UninstallExitCode" -Level DEBUG
                
                if ($UninstallExitCode -eq 0) {
                    Write-Log "CATIA BMW R2024 SP5 uninstalled successfully" -Level SUCCESS
                    
                    Set-NinjaField -FieldName "catiaBMWStatus" -Value "Uninstalled"
                    Set-NinjaField -FieldName "catiaBMWUninstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    
                    $ExitCode = 0
                } else {
                    throw "Uninstaller returned exit code: $UninstallExitCode"
                }
                
            } catch {
                Write-Log "Uninstaller execution failed: $($_.Exception.Message)" -Level ERROR
                throw
            } finally {
                Write-Log "Cleaning up temporary uninstall batch" -Level DEBUG
                if (Test-Path $UninstallBatchTemp) {
                    Remove-Item -Path $UninstallBatchTemp -Force -ErrorAction SilentlyContinue
                }
            }
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "catiaBMWStatus" -Value "Failed"
        Set-NinjaField -FieldName "catiaBMWUninstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
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
