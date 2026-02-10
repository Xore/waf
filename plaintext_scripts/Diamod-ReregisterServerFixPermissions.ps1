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
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest
    
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        Write-Output $logMessage
        
        if ($Level -eq 'ERROR') { $script:ErrorCount++ }
        if ($Level -eq 'WARNING') { $script:WarningCount++ }
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
            Write-Log 'Access Denied. Please run with Administrator privileges' -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        if (-not (Test-Path -Path $DiamodPath)) {
            Write-Log "Diamod installation not found at: $DiamodPath" -Level 'ERROR'
            $script:ExitCode = 1
            return
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
                    Write-Log "Failed to register $DLL (Exit code: $($Result.ExitCode))" -Level 'ERROR'
                    $FailedCount++
                }
            }
            else {
                Write-Log "DLL not found: $DLLPath" -Level 'WARNING'
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
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Log "Failed to re-register Diamod server: $_" -Level 'ERROR'
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Output "`n========================================"
        Write-Output "Execution Summary"
        Write-Output "========================================"
        Write-Output "Script: Diamod-ReregisterServerFixPermissions.ps1"
        Write-Output "Duration: $Duration seconds"
        Write-Output "Errors: $script:ErrorCount"
        Write-Output "Warnings: $script:WarningCount"
        Write-Output "Exit Code: $script:ExitCode"
        Write-Output "========================================"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
