#Requires -Version 5.1

<#
.SYNOPSIS
    Re-registers Diamod server COM objects and fixes file permissions.

.DESCRIPTION
    Re-registers the Diamod server application by running regsvr32 on required DLL
    files and corrects NTFS permissions on the Diamod installation directory.
    
    Resolves common Diamod server registration and access issues. Diamod requires
    proper COM registration and file permissions to function correctly.

.PARAMETER DiamodPath
    Path to Diamod server installation directory.
    Default: C:\Program Files (x86)\Diamod

.PARAMETER DLLsToRegister
    Array of DLL filenames to register.
    Default: diamod.dll, diamodadmin.dll

.EXAMPLE
    Diamod-ReregisterServerFixPermissions.ps1
    Re-registers COM objects and fixes permissions using defaults.

.EXAMPLE
    Diamod-ReregisterServerFixPermissions.ps1 -DiamodPath "D:\Diamod" -DLLsToRegister @("diamod.dll")
    Uses custom path and registers only specific DLL.

.NOTES
    File Name      : Diamod-ReregisterServerFixPermissions.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Requires       : Administrator privileges
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 format with enhanced error handling
    - 1.0: Initial version
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$DiamodPath = 'C:\Program Files (x86)\Diamod',
    
    [Parameter()]
    [string[]]$DLLsToRegister = @('diamod.dll', 'diamodadmin.dll')
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Host $logMessage }
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
}

process {
    try {
        if ($env:diamodPath -and $env:diamodPath -notlike 'null') {
            $DiamodPath = $env:diamodPath
        }

        if (-not (Test-IsElevated)) {
            throw 'Access Denied. Please run with Administrator privileges'
        }

        if (-not (Test-Path -Path $DiamodPath)) {
            throw "Diamod installation not found at: $DiamodPath"
        }

        Write-Log 'Re-registering Diamod server COM objects...'
        
        $RegisteredCount = 0
        $FailedCount = 0
        
        foreach ($DLL in $DLLsToRegister) {
            $DLLPath = Join-Path -Path $DiamodPath -ChildPath $DLL
            
            if (Test-Path -Path $DLLPath) {
                Write-Log "Registering: $DLLPath"
                
                $Result = Start-Process -FilePath 'regsvr32.exe' -ArgumentList '/s', "`"$DLLPath`"" -Wait -PassThru -NoNewWindow -ErrorAction Stop
                
                if ($Result.ExitCode -eq 0) {
                    Write-Log "Successfully registered $DLL"
                    $RegisteredCount++
                }
                else {
                    Write-Log "Failed to register $DLL (Exit code: $($Result.ExitCode))" -Level ERROR
                    $FailedCount++
                }
            }
            else {
                Write-Log "DLL not found: $DLLPath" -Level WARNING
                $FailedCount++
            }
        }

        Write-Log 'Fixing file permissions on Diamod directory...'
        
        $ACL = Get-Acl -Path $DiamodPath
        
        $UsersRule = New-Object Security.AccessControl.FileSystemAccessRule(
            'Users',
            'ReadAndExecute',
            'ContainerInherit,ObjectInherit',
            'None',
            'Allow'
        )
        
        $SystemRule = New-Object Security.AccessControl.FileSystemAccessRule(
            'SYSTEM',
            'FullControl',
            'ContainerInherit,ObjectInherit',
            'None',
            'Allow'
        )
        
        $ACL.SetAccessRule($UsersRule)
        $ACL.SetAccessRule($SystemRule)
        Set-Acl -Path $DiamodPath -AclObject $ACL -ErrorAction Stop
        
        Write-Log 'Permissions updated successfully'
        Write-Log "Diamod server re-registration complete ($RegisteredCount succeeded, $FailedCount failed)"
        
        if ($FailedCount -gt 0) {
            exit 1
        }
        else {
            exit 0
        }
    }
    catch {
        Write-Log "Failed to re-register Diamod server: $_" -Level ERROR
        exit 1
    }
}

end {
    [System.GC]::Collect()
}