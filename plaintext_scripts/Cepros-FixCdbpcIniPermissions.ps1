<#
.SYNOPSIS
    Fix CDBPC.INI file permissions for Cepros application

.DESCRIPTION
    Sets appropriate NTFS permissions on Cepros CONTACT CIM DATABASE Desktop installation
    directory and cdbpc.ini configuration file to allow proper access.

.NOTES
    Author: WAF
    Version: 2.0
    Converted from batch to PowerShell
    Requires: Administrator privileges
#>

try {
    $programPath = "$env:ProgramFiles\CONTACT CIM DATABASE Desktop 11.7"
    $iniFile = Join-Path $programPath "cdbpc.ini"

    # Check if path exists
    if (-not (Test-Path $programPath)) {
        Write-Error "Cepros installation path not found: $programPath"
        exit 1
    }

    # Set permissions on directory - Everyone Full Control, inherited
    Write-Host "Setting permissions on directory: $programPath"
    $acl = Get-Acl $programPath
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Everyone",
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl $programPath $acl

    # Set permissions on INI file - Users Full Control
    if (Test-Path $iniFile) {
        Write-Host "Setting permissions on INI file: $iniFile"
        $iniAcl = Get-Acl $iniFile
        
        # Add Benutzer (Users in German) group
        $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Benutzer",
            "FullControl",
            "None",
            "None",
            "Allow"
        )
        $iniAcl.AddAccessRule($userRule)
        
        # Add Users (English) group
        $usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users",
            "FullControl",
            "None",
            "None",
            "Allow"
        )
        $iniAcl.AddAccessRule($usersRule)
        
        Set-Acl $iniFile $iniAcl
        Write-Host "Permissions set successfully on $iniFile"
    }
    else {
        Write-Warning "INI file not found: $iniFile"
    }

    Write-Host "SUCCESS: Cepros permissions fixed successfully"
    exit 0
}
catch {
    Write-Error "ERROR: Failed to set Cepros permissions - $($_.Exception.Message)"
    exit 1
}
