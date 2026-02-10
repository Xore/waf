#Requires -Version 5.1

<#
.SYNOPSIS
    Fixes NTFS permissions on Cepros CDBPC.INI configuration file.

.DESCRIPTION
    Sets appropriate NTFS permissions on the Cepros CONTACT CIM DATABASE Desktop installation
    directory and cdbpc.ini configuration file to allow proper access for users. This resolves
    common access denied errors when the Cepros application attempts to read or write to its
    configuration file.
    
    The script grants Full Control to Everyone on the directory and Full Control to Users on
    the INI file to ensure proper application functionality.

.PARAMETER ProgramPath
    Path to Cepros installation directory.
    Default: C:\Program Files\CONTACT CIM DATABASE Desktop 11.7

.PARAMETER IniFileName
    Name of the INI configuration file.
    Default: cdbpc.ini

.EXAMPLE
    .\Cepros-FixCdbpcIniPermissions.ps1
    
    Setting permissions on directory: C:\Program Files\CONTACT CIM DATABASE Desktop 11.7
    Setting permissions on INI file: C:\Program Files\CONTACT CIM DATABASE Desktop 11.7\cdbpc.ini
    Permissions set successfully on cdbpc.ini
    Cepros permissions fixed successfully

.EXAMPLE
    .\Cepros-FixCdbpcIniPermissions.ps1 -ProgramPath "C:\Cepros" -IniFileName "config.ini"
    
    Uses custom installation path and configuration file name.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : Cepros-FixCdbpcIniPermissions.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Requires       : Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 2.0: Converted from batch to PowerShell
    - 1.0: Initial batch version

.LINK
    https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ProgramPath = "$env:ProgramFiles\CONTACT CIM DATABASE Desktop 11.7",
    
    [Parameter()]
    [string]$IniFileName = "cdbpc.ini"
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Output $logMessage }
        }
    }

    function Test-IsElevated {
        <#
        .SYNOPSIS
            Tests if script is running with administrator privileges.
        #>
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($env:programPath -and $env:programPath -notlike 'null') {
        $ProgramPath = $env:programPath
    }
    if ($env:iniFileName -and $env:iniFileName -notlike 'null') {
        $IniFileName = $env:iniFileName
    }

    $ExitCode = 0
}

process {
    try {
        if (-not (Test-IsElevated)) {
            throw 'Access Denied. Please run with Administrator privileges'
        }

        if (-not (Test-Path $ProgramPath)) {
            throw "Cepros installation path not found: $ProgramPath"
        }

        Write-Log "Fixing Cepros CDBPC.INI permissions"
        Write-Log "Setting permissions on directory: $ProgramPath"
        
        $acl = Get-Acl -Path $ProgramPath
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Everyone",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl -Path $ProgramPath -AclObject $acl
        
        Write-Log "Directory permissions set successfully"

        $iniFile = Join-Path -Path $ProgramPath -ChildPath $IniFileName
        
        if (Test-Path -Path $iniFile) {
            Write-Log "Setting permissions on INI file: $iniFile"
            $iniAcl = Get-Acl -Path $iniFile
            
            $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "Benutzer",
                "FullControl",
                "None",
                "None",
                "Allow"
            )
            $iniAcl.AddAccessRule($userRule)
            
            $usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "Users",
                "FullControl",
                "None",
                "None",
                "Allow"
            )
            $iniAcl.AddAccessRule($usersRule)
            
            Set-Acl -Path $iniFile -AclObject $iniAcl
            Write-Log "Permissions set successfully on $IniFileName"
        }
        else {
            Write-Log "INI file not found: $iniFile" -Level WARNING
        }

        Write-Log "Cepros permissions fixed successfully"
    }
    catch {
        Write-Log "Failed to set Cepros permissions: $_" -Level ERROR
        $ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $Duration seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
