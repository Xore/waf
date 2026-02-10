#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates or modifies Windows registry values

.DESCRIPTION
    Creates or updates registry values at specified paths with support for all common
    registry value types. The script can create registry key paths if they don't exist
    and verifies successful value creation.
    
    The script performs the following:
    - Creates or modifies registry values
    - Supports all common registry value types (String, DWord, QWord, Binary, MultiString, ExpandString)
    - Creates registry key paths when -Force is specified
    - Validates registry path format and hive
    - Converts value data to appropriate type
    - Verifies successful value creation
    - Can save operation results to NinjaRMM custom fields
    
    This is useful for applying registry-based configurations, security settings, and
    application preferences across multiple systems through centralized management.
    
    CAUTION: Modifying the registry can cause system instability if incorrect values
    are set. Always verify registry paths and values before deployment.
    
    This script runs unattended without user interaction.

.PARAMETER RegistryPath
    Full registry path where the value should be created/modified.
    Must start with a valid hive: HKLM:, HKCU:, HKCR:, HKU:, or HKCC:
    Example: "HKLM:\SOFTWARE\Company\Application"

.PARAMETER ValueName
    Name of the registry value to create or modify.
    Cannot be empty or whitespace.

.PARAMETER ValueData
    Data to set for the registry value.
    Format depends on ValueType:
    - String/ExpandString: Plain text
    - DWord: Integer (0-4294967295)
    - QWord: Long integer
    - Binary: Comma-separated bytes (e.g., "01,02,FF")
    - MultiString: Pipe-separated strings (e.g., "value1|value2|value3")

.PARAMETER ValueType
    Type of registry value to create.
    Valid values: String, ExpandString, Binary, DWord, QWord, MultiString
    Default: String

.PARAMETER Force
    Creates the registry path if it doesn't exist.
    Without this switch, script fails if path doesn't exist.

.PARAMETER SaveToCustomField
    Name of a NinjaRMM custom field to save the operation results.

.EXAMPLE
    .\RegistryManagement-SetValue.ps1 -RegistryPath "HKLM:\SOFTWARE\MyApp" -ValueName "Setting1" -ValueData "Enabled" -Force
    
    Creates registry path and sets a string value.

.EXAMPLE
    .\RegistryManagement-SetValue.ps1 -RegistryPath "HKCU:\Software\Test" -ValueName "Count" -ValueData 42 -ValueType "DWord"
    
    Sets a DWORD value in current user hive.

.EXAMPLE
    .\RegistryManagement-SetValue.ps1 -RegistryPath "HKLM:\SOFTWARE\App" -ValueName "Servers" -ValueData "srv1|srv2|srv3" -ValueType "MultiString"
    
    Creates a multi-string value with three entries.

.NOTES
    Script Name:    RegistryManagement-SetValue.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (SYSTEM via NinjaRMM)
    Execution Frequency: On-demand for configuration management
    Typical Duration: 1-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (for HKLM modifications)
        - Appropriate registry permissions
    
    Environment Variables (Optional):
        - registryPath: Alternative to -RegistryPath parameter
        - valueName: Alternative to -ValueName parameter
        - valueData: Alternative to -ValueData parameter
        - valueType: Alternative to -ValueType parameter
        - force: Alternative to -Force parameter ("true" enables)
        - saveToCustomField: Alternative to -SaveToCustomField parameter
    
    Exit Codes:
        0 - Success (registry value set successfully)
        1 - Failure (validation error, path not found, or set operation failed)
    
    WARNING: Incorrect registry modifications can cause system instability or prevent
    Windows from starting. Always test changes in a non-production environment first.

.LINK
    https://github.com/Xore/waf
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-itemproperty
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^(HKLM|HKCU|HKCR|HKU|HKCC):')]
    [string]$RegistryPath,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,255)]
    [string]$ValueName,
    
    [Parameter(Mandatory=$true)]
    [AllowEmptyString()]
    [string]$ValueData,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('String','ExpandString','Binary','DWord','QWord','MultiString')]
    [string]$ValueType = 'String',
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [ValidateLength(1,255)]
    [string]$SaveToCustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "RegistryManagement-SetValue"

# Support environment variables
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

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$script:ExitCode = 0
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0
$RegistryPathCreated = $false
$ValueSet = $false

Set-StrictMode -Version Latest

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
        'ERROR' { $script:ErrorCount++; $script:ExitCode = 1 }
    }
}

function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field with CLI fallback
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Value
    )
    
    try {
        $null = Ninja-Property-Set-Piped -Name $Name -Value $Value 2>&1
        Write-Log "Custom field '$Name' updated successfully" -Level DEBUG
    } catch {
        Write-Log "Ninja cmdlet unavailable, using CLI fallback for field '$Name'" -Level WARN
        $script:CLIFallbackCount++
        
        try {
            $NinjaPath = "C:\Program Files (x86)\NinjaRMMAgent\ninjarmm-cli.exe"
            if (-not (Test-Path $NinjaPath)) {
                $NinjaPath = "C:\Program Files\NinjaRMMAgent\ninjarmm-cli.exe"
            }
            
            if (Test-Path $NinjaPath) {
                $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
                $ProcessInfo.FileName = $NinjaPath
                $ProcessInfo.Arguments = "set $Name `"$Value`""
                $ProcessInfo.UseShellExecute = $false
                $ProcessInfo.RedirectStandardOutput = $true
                $ProcessInfo.RedirectStandardError = $true
                $Process = New-Object System.Diagnostics.Process
                $Process.StartInfo = $ProcessInfo
                $null = $Process.Start()
                $null = $Process.WaitForExit(5000)
                Write-Log "CLI fallback succeeded for field '$Name'" -Level DEBUG
            } else {
                throw "NinjaRMM CLI executable not found"
            }
        } catch {
            Write-Log "CLI fallback failed for field '$Name': $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    Write-Log "Registry Path: $RegistryPath" -Level INFO
    Write-Log "Value Name: $ValueName" -Level INFO
    Write-Log "Value Type: $ValueType" -Level INFO
    Write-Log "Value Data: $ValueData" -Level INFO
    
    # Check if path exists
    if (-not (Test-Path -Path $RegistryPath)) {
        if ($Force) {
            Write-Log "Registry path does not exist, creating: $RegistryPath" -Level INFO
            try {
                New-Item -Path $RegistryPath -Force -ErrorAction Stop | Out-Null
                $RegistryPathCreated = $true
                Write-Log "Registry path created successfully" -Level SUCCESS
            } catch {
                Write-Log "Failed to create registry path: $($_.Exception.Message)" -Level ERROR
                throw
            }
        } else {
            throw "Registry path does not exist: $RegistryPath (use -Force to create)"
        }
    } else {
        Write-Log "Registry path exists" -Level DEBUG
    }
    
    # Convert value data to appropriate type
    $ConvertedData = $ValueData
    
    try {
        switch ($ValueType) {
            'DWord' {
                $ConvertedData = [int]$ValueData
                Write-Log "Converted value to DWord: $ConvertedData" -Level DEBUG
            }
            'QWord' {
                $ConvertedData = [long]$ValueData
                Write-Log "Converted value to QWord: $ConvertedData" -Level DEBUG
            }
            'Binary' {
                $ConvertedData = [byte[]]($ValueData -split ',' | ForEach-Object { [byte]$_.Trim() })
                Write-Log "Converted value to Binary array with $($ConvertedData.Length) bytes" -Level DEBUG
            }
            'MultiString' {
                $ConvertedData = $ValueData -split '\|' | ForEach-Object { $_.Trim() }
                Write-Log "Converted value to MultiString with $($ConvertedData.Count) entries" -Level DEBUG
            }
        }
    } catch {
        Write-Log "Failed to convert value data for type $ValueType : $($_.Exception.Message)" -Level ERROR
        throw
    }
    
    # Set registry value
    Write-Log "Setting registry value..." -Level INFO
    try {
        Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $ConvertedData -Type $ValueType -ErrorAction Stop
        Write-Log "Registry value set successfully" -Level SUCCESS
        $ValueSet = $true
    } catch {
        Write-Log "Failed to set registry value: $($_.Exception.Message)" -Level ERROR
        throw
    }
    
    # Verify value was set
    try {
        $VerifyValue = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction Stop
        if ($null -ne $VerifyValue.$ValueName) {
            Write-Log "Verified registry value exists" -Level DEBUG
            $Result = "SUCCESS: Registry value '$ValueName' set to '$ValueData' ($ValueType) at $RegistryPath"
        } else {
            Write-Log "Registry value verification returned null" -Level WARN
            $Result = "WARNING: Registry value set but verification returned null at $RegistryPath"
        }
    } catch {
        Write-Log "Failed to verify registry value: $($_.Exception.Message)" -Level WARN
        $Result = "WARNING: Registry value set but verification failed at $RegistryPath"
    }
    
    # Save to custom field if specified
    if ($SaveToCustomField) {
        try {
            Set-NinjaField -Name $SaveToCustomField -Value $Result
            Write-Log "Results saved to custom field '$SaveToCustomField'" -Level SUCCESS
        } catch {
            Write-Log "Failed to save to custom field: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    $script:ExitCode = 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Registry Path Created: $RegistryPathCreated" -Level INFO
    Write-Log "  Value Set: $ValueSet" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    Write-Log "  Exit Code: $script:ExitCode" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Cleanup
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit $script:ExitCode
}
