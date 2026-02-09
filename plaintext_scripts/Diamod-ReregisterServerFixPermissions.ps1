#Requires -Version 5.1 -RunAsAdministrator

<#
.SYNOPSIS
    Re-registers Diamod server COM objects and fixes file permissions.

.DESCRIPTION
    This script re-registers the Diamod server application by running regsvr32 on required DLL 
    files and corrects NTFS permissions on the Diamod installation directory. This resolves 
    common Diamod server registration and access issues.
    
    Diamod is a specialized business application that requires proper COM registration and file 
    permissions to function correctly. This script automates the remediation process for common 
    permission and registration problems.

.PARAMETER DiamodPath
    Path to Diamod server installation directory. Default: C:\Program Files (x86)\Diamod

.PARAMETER DLLsToRegister
    Array of DLL filenames to register. Default: diamod.dll, diamodadmin.dll

.EXAMPLE
    No Parameters (uses defaults)

    [Info] Re-registering Diamod server COM objects...
    [Info] Registering: C:\Program Files (x86)\Diamod\diamod.dll
    [Info] Successfully registered diamod.dll
    [Info] Registering: C:\Program Files (x86)\Diamod\diamodadmin.dll
    [Info] Successfully registered diamodadmin.dll
    [Info] Fixing file permissions on Diamod directory...
    [Info] Permissions updated successfully
    [Info] Diamod server re-registration complete

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2
    Release notes: Initial release for WAF v3.0
    Requires: Administrator privileges
    
.COMPONENT
    regsvr32.exe - COM object registration utility
    
.LINK
    https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/regsvr32

.FUNCTIONALITY
    - Validates Diamod installation path
    - Re-registers required DLL files using regsvr32
    - Grants Users group read and execute permissions
    - Grants SYSTEM full control permissions
    - Fixes inherited permissions on Diamod directory
    - Provides registration and permission update confirmation
#>

[CmdletBinding()]
param(
    [string]$DiamodPath = "C:\Program Files (x86)\Diamod",
    [string[]]$DLLsToRegister = @("diamod.dll", "diamodadmin.dll")
)

begin {
    if ($env:diamodPath -and $env:diamodPath -notlike "null") {
        $DiamodPath = $env:diamodPath
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    $ExitCode = 0
}

process {
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges"
        exit 1
    }

    try {
        if (-not (Test-Path -Path $DiamodPath)) {
            Write-Host "[Error] Diamod installation not found at: $DiamodPath"
            exit 1
        }

        Write-Host "[Info] Re-registering Diamod server COM objects..."
        
        foreach ($DLL in $DLLsToRegister) {
            $DLLPath = Join-Path -Path $DiamodPath -ChildPath $DLL
            
            if (Test-Path -Path $DLLPath) {
                Write-Host "[Info] Registering: $DLLPath"
                $Result = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s", "`"$DLLPath`"" -Wait -PassThru -NoNewWindow
                
                if ($Result.ExitCode -eq 0) {
                    Write-Host "[Info] Successfully registered $DLL"
                }
                else {
                    Write-Host "[Error] Failed to register $DLL (Exit code: $($Result.ExitCode))"
                    $ExitCode = 1
                }
            }
            else {
                Write-Host "[Warn] DLL not found: $DLLPath"
            }
        }

        Write-Host "[Info] Fixing file permissions on Diamod directory..."
        
        $ACL = Get-Acl -Path $DiamodPath
        
        $UsersRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users",
            "ReadAndExecute",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        
        $SystemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "SYSTEM",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        
        $ACL.SetAccessRule($UsersRule)
        $ACL.SetAccessRule($SystemRule)
        Set-Acl -Path $DiamodPath -AclObject $ACL -ErrorAction Stop
        
        Write-Host "[Info] Permissions updated successfully"
        Write-Host "[Info] Diamod server re-registration complete"
    }
    catch {
        Write-Host "[Error] Failed to re-register Diamod server: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
