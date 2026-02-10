#Requires -Version 5.1

<#
.SYNOPSIS
    Creates or modifies a Windows registry value.

.DESCRIPTION
    This script creates or updates a registry value at the specified path. It supports all 
    common registry value types (String, DWord, QWord, Binary, MultiString, ExpandString). 
    The script will create the registry key path if it doesn't exist.
    
    This is useful for applying registry-based configurations, security settings, and 
    application preferences across multiple systems.
    
    CAUTION: Modifying the registry can cause system instability if incorrect values are set.
    Always verify registry paths and values before deployment.

.PARAMETER RegistryPath
    Full registry path where the value should be created/modified.
    Example: "HKLM:\SOFTWARE\Company\Application"
    Supported hives: HKLM, HKCU, HKCR, HKU, HKCC

.PARAMETER ValueName
    Name of the registry value to create or modify.

.PARAMETER ValueData
    Data to set for the registry value.

.PARAMETER ValueType
    Type of registry value. Valid options:
    - String (REG_SZ)
    - ExpandString (REG_EXPAND_SZ)
    - Binary (REG_BINARY)
    - DWord (REG_DWORD)
    - QWord (REG_QWORD)
    - MultiString (REG_MULTI_SZ)
    Default: String

.PARAMETER Force
    If specified, creates the registry path if it doesn't exist.

.PARAMETER SaveToCustomField
    Name of a custom field to save the registry operation results.

.EXAMPLE
    -RegistryPath "HKLM:\SOFTWARE\MyApp" -ValueName "Setting1" -ValueData "Enabled" -Force

    [Info] Setting registry value...
    [Info] Creating registry path: HKLM:\SOFTWARE\MyApp
    [Info] Setting value 'Setting1' to 'Enabled' (String)
    [Info] Registry value set successfully

.EXAMPLE
    -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -ValueName "Hidden" -ValueData 1 -ValueType "DWord"

    [Info] Setting registry value...
    [Info] Setting value 'Hidden' to '1' (DWord)
    [Info] Registry value set successfully

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Requires: Administrator privileges for HKLM modifications
    
    WARNING: Incorrect registry modifications can cause system instability.
    
.COMPONENT
    Registry - Windows Registry manipulation
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-itemproperty

.FUNCTIONALITY
    - Creates or modifies registry values
    - Supports all common registry value types
    - Creates registry key paths when needed
    - Validates registry path format
    - Verifies successful value creation
    - Can save operation results to custom fields
    - Useful for configuration management and compliance
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RegistryPath,
    [Parameter(Mandatory = $true)]
    [string]$ValueName,
    [Parameter(Mandatory = $true)]
    [string]$ValueData,
    [ValidateSet("String", "ExpandString", "Binary", "DWord", "QWord", "MultiString")]
    [string]$ValueType = "String",
    [switch]$Force,
    [string]$SaveToCustomField
)

begin {
    if ($env:registryPath -and $env:registryPath -notlike "null") {
        $RegistryPath = $env:registryPath
    }
    if ($env:valueName -and $env:valueName -notlike "null") {
        $ValueName = $env:valueName
    }
    if ($env:valueData -and $env:valueData -notlike "null") {
        $ValueData = $env:valueData
    }
    if ($env:valueType -and $env:valueType -notlike "null") {
        $ValueType = $env:valueType
    }
    if ($env:force -eq "true") {
        $Force = $true
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        $NinjaValue = $Value
        $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $ExitCode = 0
}

process {
    if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
        Write-Host "[Error] RegistryPath parameter is required"
        exit 1
    }

    if ([string]::IsNullOrWhiteSpace($ValueName)) {
        Write-Host "[Error] ValueName parameter is required"
        exit 1
    }

    if ($RegistryPath -notmatch "^(HKLM|HKCU|HKCR|HKU|HKCC):") {
        Write-Host "[Error] Registry path must start with a valid hive (HKLM:, HKCU:, HKCR:, HKU:, or HKCC:)"
        exit 1
    }

    try {
        Write-Host "[Info] Setting registry value..."
        
        if (-not (Test-Path -Path $RegistryPath)) {
            if ($Force) {
                Write-Host "[Info] Creating registry path: $RegistryPath"
                New-Item -Path $RegistryPath -Force -ErrorAction Stop | Out-Null
            } else {
                Write-Host "[Error] Registry path does not exist: $RegistryPath"
                Write-Host "[Info] Use -Force parameter to create the path"
                exit 1
            }
        }

        $ConvertedData = $ValueData
        
        switch ($ValueType) {
            "DWord" {
                try {
                    $ConvertedData = [int]$ValueData
                } catch {
                    Write-Host "[Error] ValueData must be a valid integer for DWord type"
                    exit 1
                }
            }
            "QWord" {
                try {
                    $ConvertedData = [long]$ValueData
                } catch {
                    Write-Host "[Error] ValueData must be a valid long integer for QWord type"
                    exit 1
                }
            }
            "Binary" {
                try {
                    $ConvertedData = [byte[]]($ValueData -split ',' | ForEach-Object { [byte]$_.Trim() })
                } catch {
                    Write-Host "[Error] ValueData must be comma-separated bytes for Binary type (e.g., '01,02,03')"
                    exit 1
                }
            }
            "MultiString" {
                $ConvertedData = $ValueData -split '\|' | ForEach-Object { $_.Trim() }
            }
        }

        Write-Host "[Info] Setting value '$ValueName' to '$ValueData' ($ValueType)"
        
        Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $ConvertedData -Type $ValueType -ErrorAction Stop
        
        $VerifyValue = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue
        
        if ($VerifyValue.$ValueName -ne $null) {
            Write-Host "[Info] Registry value set successfully"
            $Result = "Registry value '$ValueName' set to '$ValueData' at $RegistryPath"
        } else {
            Write-Host "[Error] Failed to verify registry value was set"
            $Result = "Failed to set registry value '$ValueName' at $RegistryPath"
            $ExitCode = 1
        }

        if ($SaveToCustomField) {
            try {
                $Result | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            } catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to set registry value: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
