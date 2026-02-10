#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves CPU temperature information from hardware sensors

.DESCRIPTION
    Queries CPU temperature data using WMI thermal zone information. Retrieves
    temperature readings from available thermal sensors and converts them to Celsius
    and Fahrenheit.
    
    The script performs the following:
    - Queries WMI thermal zone information (MSAcpi_ThermalZoneTemperature)
    - Retrieves CPU temperature from hardware sensors
    - Converts temperatures from Kelvin to Celsius and Fahrenheit
    - Reports temperature readings for monitoring
    - Optionally saves temperature data to NinjaRMM custom fields
    - Handles systems without accessible temperature sensors gracefully
    
    Temperature monitoring is critical for identifying cooling problems, thermal
    throttling, and potential hardware failures.
    
    Note: Temperature sensor availability depends on hardware, BIOS/UEFI settings,
    and installed drivers. Some systems may not expose thermal zone information.
    
    This script runs unattended without user interaction.

.PARAMETER SaveToCustomField
    Optional name of NinjaRMM custom field to save CPU temperature reading.
    Must be a valid custom field name (max 200 characters).
    Temperature is saved in format: "45.0 C"

.EXAMPLE
    .\Hardware-GetCPUTemp.ps1
    
    Queries CPU temperature and displays to console.

.EXAMPLE
    .\Hardware-GetCPUTemp.ps1 -SaveToCustomField "CPUTemperature"
    
    Queries CPU temperature and saves result to specified custom field.

.NOTES
    Script Name:    Hardware-GetCPUTemp.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or Administrator
    Execution Frequency: On-demand or scheduled (e.g., every 5 minutes)
    Typical Duration: ~1-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - SaveToCustomField (if specified) - Temperature in Celsius (e.g., "45.0 C")
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - WMI access for thermal zone queries
        - Hardware must support ACPI thermal zones
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - saveToCustomField: Alternative to -SaveToCustomField parameter
    
    Exit Codes:
        0 - Success (temperature retrieved or sensors not accessible)
        1 - Failure (custom field update failed or critical error)

.LINK
    https://github.com/Xore/waf
    https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-temperatureprobe
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save CPU temperature")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$SaveToCustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Hardware-GetCPUTemp"

# Support NinjaRMM environment variable
if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
    $SaveToCustomField = $env:saveToCustomField
}

# Trim whitespace from parameter
if ($SaveToCustomField) {
    $SaveToCustomField = $SaveToCustomField.Trim()
}

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$script:ExitCode = 0
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

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
        
        # Method 2: Try ninjarmm-cli.exe
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
            $script:ExitCode = 1
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
    
    Write-Log "Querying CPU temperature sensors..." -Level INFO
    
    # Query thermal zone information from WMI
    $TempData = Get-CimInstance -Namespace "root/WMI" -ClassName "MSAcpi_ThermalZoneTemperature" -ErrorAction SilentlyContinue
    
    if ($TempData) {
        # Convert from tenths of Kelvin to Celsius and Fahrenheit
        $TempKelvin = $TempData.CurrentTemperature / 10
        $TempCelsius = $TempKelvin - 273.15
        $TempFahrenheit = ($TempCelsius * 9/5) + 32
        
        # Round to one decimal place
        $TempCelsiusRounded = [Math]::Round($TempCelsius, 1)
        $TempFahrenheitRounded = [Math]::Round($TempFahrenheit, 1)
        
        Write-Log "CPU Temperature: $TempCelsiusRounded C ($TempFahrenheitRounded F)" -Level SUCCESS
        
        # Save to custom field if specified
        if ($SaveToCustomField) {
            $TempString = "$TempCelsiusRounded C"
            Set-NinjaField -FieldName $SaveToCustomField -Value $TempString
            
            if ($script:ExitCode -eq 0) {
                Write-Log "Temperature saved to custom field '$SaveToCustomField'" -Level SUCCESS
            }
        }
        
    } else {
        Write-Log "CPU temperature sensors not accessible on this system" -Level WARN
        Write-Log "This may be due to:" -Level INFO
        Write-Log "  - Hardware limitations (no ACPI thermal zones)" -Level INFO
        Write-Log "  - Missing or incompatible drivers" -Level INFO
        Write-Log "  - BIOS/UEFI settings restricting sensor access" -Level INFO
        
        # Save status to custom field if specified
        if ($SaveToCustomField) {
            Set-NinjaField -FieldName $SaveToCustomField -Value "Sensors not accessible"
        }
    }
    
    if ($script:ExitCode -eq 0) {
        Write-Log "Temperature query completed successfully" -Level SUCCESS
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
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    Write-Log "  Exit Code: $script:ExitCode" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Cleanup
    [System.GC]::Collect()
    
    exit $script:ExitCode
}
