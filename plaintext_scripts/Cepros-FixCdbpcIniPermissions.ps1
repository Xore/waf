#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Fixes NTFS permissions on Cepros CDBPC.INI configuration file

.DESCRIPTION
    Sets appropriate NTFS permissions on the Cepros CONTACT CIM DATABASE Desktop installation
    directory and cdbpc.ini configuration file to allow proper access for users. This resolves
    common access denied errors when the Cepros application attempts to read or write to its
    configuration file.
    
    The script performs the following:
    - Validates administrator privileges
    - Verifies Cepros installation directory exists
    - Grants Full Control to Everyone on the installation directory (with inheritance)
    - Grants Full Control to Users and Benutzer groups on the INI file
    - Reports success or failure status
    
    The "Benutzer" group is included for German language systems where the Users group
    has a localized name.
    
    This script runs unattended without user interaction.

.PARAMETER ProgramPath
    Path to Cepros installation directory.
    Default: C:\Program Files\CONTACT CIM DATABASE Desktop 11.7
    Can be overridden by environment variable: programPath

.PARAMETER IniFileName
    Name of the INI configuration file.
    Default: cdbpc.ini
    Can be overridden by environment variable: iniFileName

.EXAMPLE
    .\Cepros-FixCdbpcIniPermissions.ps1
    
    Fixes permissions using default paths.
    Setting permissions on directory: C:\Program Files\CONTACT CIM DATABASE Desktop 11.7
    Setting permissions on INI file: C:\Program Files\CONTACT CIM DATABASE Desktop 11.7\cdbpc.ini
    Permissions set successfully on cdbpc.ini
    Cepros permissions fixed successfully

.EXAMPLE
    .\Cepros-FixCdbpcIniPermissions.ps1 -ProgramPath "C:\Cepros" -IniFileName "config.ini"
    
    Uses custom installation path and configuration file name.

.NOTES
    Script Name:    Cepros-FixCdbpcIniPermissions.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or when access denied errors occur
    Typical Duration: ~1-2 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - None (consider adding status fields in future)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - Cepros CONTACT CIM DATABASE Desktop installed
        - NTFS file system (for ACL support)
    
    Environment Variables (Optional):
        - programPath: Override default Cepros installation path
        - iniFileName: Override default INI file name
    
    Exit Codes:
        0 - Success (permissions set successfully)
        1 - Failure (missing privileges, path not found, or ACL error)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Path to Cepros installation directory")]
    [ValidateNotNullOrEmpty()]
    [string]$ProgramPath = "$env:ProgramFiles\CONTACT CIM DATABASE Desktop 11.7",
    
    [Parameter(Mandatory=$false, HelpMessage="Name of INI configuration file")]
    [ValidateNotNullOrEmpty()]
    [string]$IniFileName = "cdbpc.ini"
)

begin {
    Set-StrictMode -Version Latest
    
    # ============================================================================
    # CONFIGURATION
    # ============================================================================
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Cepros-FixCdbpcIniPermissions"
    
    # NinjaRMM CLI path for fallback
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    # ============================================================================
    # INITIALIZATION
    # ============================================================================
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:CLIFallbackCount = 0
    
    # ============================================================================
    # FUNCTIONS
    # ============================================================================
    
    function Write-Log {
        <#
        .SYNOPSIS
            Writes structured log messages with plain text output
        #>
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
        
        # Plain text output only - no colors
        Write-Output $LogMessage
        
        # Track counts
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
        }
    }
    
    function Set-NinjaField {
        <#
        .SYNOPSIS
            Sets a NinjaRMM custom field value with automatic fallback to CLI
        #>
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
        
        # Method 1: Try Ninja-Property-Set cmdlet
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
            
            # Method 2: Fall back to NinjaRMM CLI
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
        <#
        .SYNOPSIS
            Checks if script is running with Administrator privileges
        #>
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
        
        # Check for environment variable overrides
        if ($env:programPath -and $env:programPath -notlike 'null') {
            $ProgramPath = $env:programPath
            Write-Log "Using program path from environment: $ProgramPath" -Level INFO
        }
        
        if ($env:iniFileName -and $env:iniFileName -notlike 'null') {
            $IniFileName = $env:iniFileName
            Write-Log "Using INI filename from environment: $IniFileName" -Level INFO
        }
        
        # Validate administrator privileges
        if (-not (Test-IsElevated)) {
            Write-Log "Administrator privileges required" -Level ERROR
            $script:ExitCode = 1
            return
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        # Validate Cepros installation path exists
        if (-not (Test-Path $ProgramPath)) {
            Write-Log "Cepros installation path not found: $ProgramPath" -Level ERROR
            Write-Log "Verify Cepros is installed or provide correct path via -ProgramPath parameter" -Level ERROR
            $script:ExitCode = 1
            return
        }
        Write-Log "Cepros installation found at: $ProgramPath" -Level INFO
        
        # ============================================================================
        # SET DIRECTORY PERMISSIONS
        # ============================================================================
        
        Write-Log "Setting permissions on installation directory" -Level INFO
        
        try {
            $Acl = Get-Acl -Path $ProgramPath -ErrorAction Stop
            
            # Grant Full Control to Everyone (with inheritance for all subdirectories and files)
            $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "Everyone",
                "FullControl",
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )
            
            $Acl.SetAccessRule($Rule)
            Set-Acl -Path $ProgramPath -AclObject $Acl -ErrorAction Stop
            
            Write-Log "Directory permissions set successfully (Everyone: Full Control)" -Level SUCCESS
            
        } catch {
            Write-Log "Failed to set directory permissions: $($_.Exception.Message)" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        # ============================================================================
        # SET INI FILE PERMISSIONS
        # ============================================================================
        
        $IniFilePath = Join-Path -Path $ProgramPath -ChildPath $IniFileName
        
        if (-not (Test-Path -Path $IniFilePath)) {
            Write-Log "INI file not found: $IniFilePath" -Level WARN
            Write-Log "Directory permissions have been set, but INI file does not exist yet" -Level INFO
            # Not a critical error - INI file might be created later
        } else {
            Write-Log "Setting permissions on INI file: $IniFilePath" -Level INFO
            
            try {
                $IniAcl = Get-Acl -Path $IniFilePath -ErrorAction Stop
                
                # Grant Full Control to Benutzer (German "Users" group)
                $BenutzerRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "Benutzer",
                    "FullControl",
                    "None",
                    "None",
                    "Allow"
                )
                $IniAcl.AddAccessRule($BenutzerRule)
                
                # Grant Full Control to Users (English "Users" group)
                $UsersRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "Users",
                    "FullControl",
                    "None",
                    "None",
                    "Allow"
                )
                $IniAcl.AddAccessRule($UsersRule)
                
                Set-Acl -Path $IniFilePath -AclObject $IniAcl -ErrorAction Stop
                
                Write-Log "INI file permissions set successfully (Users/Benutzer: Full Control)" -Level SUCCESS
                
            } catch {
                Write-Log "Failed to set INI file permissions: $($_.Exception.Message)" -Level ERROR
                $script:ExitCode = 1
                return
            }
        }
        
        Write-Log "Cepros CDBPC.INI permissions fixed successfully" -Level SUCCESS
        $script:ExitCode = 0
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        # Calculate and log execution time
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
        
    } finally {
        # Force garbage collection
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
