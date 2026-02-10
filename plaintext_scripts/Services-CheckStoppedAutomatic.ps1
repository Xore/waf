#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Monitors and optionally starts Windows services that are set to Automatic but not running.

.DESCRIPTION
    Identifies Windows services configured for Automatic startup that are currently stopped.
    Services with Delayed Start or Trigger Start are automatically excluded from reporting.
    Can optionally attempt to start discovered services.
    
    The script performs the following:
    - Validates system uptime (requires 15+ minutes after boot)
    - Checks administrator privileges
    - Identifies automatic services that are not running
    - Filters out delayed start and trigger start services
    - Excludes user-specified services from reporting
    - Optionally attempts to start stopped services
    - Reports detailed service information
    - Updates NinjaRMM custom fields with status
    
    This script runs unattended without user interaction.

.PARAMETER IgnoreServices
    Comma-separated list of service names to exclude from monitoring.
    Supports both service names (e.g., "wuauserv") and display names.
    Example: "SysMain,Spooler,BITS"

.PARAMETER StartFoundServices
    If specified, attempts to start any stopped automatic services found.
    Makes up to 3 attempts per service with error logging.
    Default: $false

.EXAMPLE
    .\Services-CheckStoppedAutomatic.ps1
    
    Reports on stopped automatic services without starting them.

.EXAMPLE
    .\Services-CheckStoppedAutomatic.ps1 -IgnoreServices "SysMain,BITS"
    
    Reports stopped services, excluding SysMain and BITS from results.

.EXAMPLE
    .\Services-CheckStoppedAutomatic.ps1 -StartFoundServices
    
    Reports and attempts to start all stopped automatic services.

.NOTES
    Script Name:    Services-CheckStoppedAutomatic.ps1
    Author:         Windows Automation Framework
    Version:        2.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~5-15 seconds (depends on service count)
    Timeout Setting: 120 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - stoppedServicesStatus (Success/Warning/Failed)
        - stoppedServicesDate (timestamp)
        - stoppedServicesCount (number found)
        - stoppedServicesList (service names)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Minimum 15 minutes uptime required
    
    Environment Variables (Optional):
        - servicesToExclude: Alternative to -IgnoreServices parameter
        - startFoundServices: Alternative to -StartFoundServices switch
    
    Exit Codes:
        0 - Success (no stopped services or all started successfully)
        1 - Failure (validation failed, stopped services found, or start failed)

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/powershell/module/microsoft.powershell.management/get-service
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Comma-separated list of service names to ignore")]
    [ValidateNotNullOrEmpty()]
    [string]$IgnoreServices,
    
    [Parameter(Mandatory=$false, HelpMessage="Attempt to start stopped services")]
    [switch]$StartFoundServices = [System.Convert]::ToBoolean($env:startFoundServices)
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "2.0"
$ScriptName = "Services-CheckStoppedAutomatic"
$MinimumUptimeMinutes = 15
$InvalidServiceNameCharacters = "\\|/|:"
$MaxServiceNameLength = 256

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
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
    
    Write-Output $LogMessage
    
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
    <#
    .SYNOPSIS
        Checks if script is running with Administrator privileges
    #>
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable overrides
    if ($env:servicesToExclude -and $env:servicesToExclude -notlike "null") {
        $IgnoreServices = $env:servicesToExclude
        Write-Log "Using ignore list from environment: $IgnoreServices" -Level INFO
    }
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # Check system uptime
    Write-Log "Checking system uptime" -Level DEBUG
    $LastBootDateTime = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop | 
        Select-Object -ExpandProperty LastBootUpTime
    
    $Uptime = (Get-Date) - $LastBootDateTime
    $UptimeMinutes = [math]::Round($Uptime.TotalMinutes)
    
    Write-Log "Current uptime: $UptimeMinutes minutes" -Level INFO
    
    if ($UptimeMinutes -lt $MinimumUptimeMinutes) {
        Write-Log "System uptime is less than $MinimumUptimeMinutes minutes" -Level ERROR
        Write-Log "Please wait at least $MinimumUptimeMinutes minutes after startup before running this script" -Level ERROR
        
        Set-NinjaField -FieldName "stoppedServicesStatus" -Value "Insufficient Uptime"
        Set-NinjaField -FieldName "stoppedServicesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        exit 1
    }
    
    # Build list of services to ignore
    $ServicesToIgnore = [System.Collections.Generic.List[string]]::new()
    
    if ($IgnoreServices) {
        Write-Log "Processing ignore list" -Level DEBUG
        
        $ServiceArray = if ($IgnoreServices -match ",") {
            $IgnoreServices -split ","
        } else {
            @($IgnoreServices)
        }
        
        foreach ($ServiceName in $ServiceArray) {
            $ServiceName = $ServiceName.Trim()
            
            # Validate service name
            if ($ServiceName -match $InvalidServiceNameCharacters) {
                Write-Log "Service name contains invalid characters: $ServiceName" -Level WARN
                continue
            }
            
            if ($ServiceName.Length -gt $MaxServiceNameLength) {
                Write-Log "Service name exceeds maximum length: $ServiceName" -Level WARN
                continue
            }
            
            $ServicesToIgnore.Add($ServiceName)
            Write-Log "Added to ignore list: $ServiceName" -Level DEBUG
        }
        
        Write-Log "Services to ignore: $($ServicesToIgnore.Count)" -Level INFO
    }
    
    # Get all automatic services that are not running
    Write-Log "Querying automatic services" -Level INFO
    $NonRunningAutoServices = [System.Collections.Generic.List[object]]::new()
    
    Get-Service -ErrorAction Stop | 
        Where-Object { $_.StartType -eq "Automatic" -and $_.Status -ne "Running" } | 
        ForEach-Object {
            $NonRunningAutoServices.Add($_)
        }
    
    Write-Log "Found $($NonRunningAutoServices.Count) stopped automatic services" -Level INFO
    
    # Remove trigger start services
    if ($NonRunningAutoServices.Count -gt 0) {
        Write-Log "Filtering trigger start services" -Level DEBUG
        
        try {
            $TriggerServices = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\*\*" -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -match "TriggerInfo" } | 
                Select-Object -ExpandProperty PSParentPath | 
                Split-Path -Leaf
            
            foreach ($TriggerService in $TriggerServices) {
                $ServiceToRemove = $NonRunningAutoServices | Where-Object { $_.ServiceName -eq $TriggerService }
                if ($ServiceToRemove) {
                    $NonRunningAutoServices.Remove($ServiceToRemove) | Out-Null
                    Write-Log "Excluded trigger service: $TriggerService" -Level DEBUG
                }
            }
        } catch {
            Write-Log "Error filtering trigger services: $_" -Level WARN
        }
    }
    
    # Remove delayed start services
    if ($NonRunningAutoServices.Count -gt 0) {
        Write-Log "Filtering delayed start services" -Level DEBUG
        
        try {
            $DelayedStartServices = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\*" -ErrorAction SilentlyContinue | 
                Where-Object { $_.DelayedAutoStart -eq 1 } | 
                Select-Object -ExpandProperty PSChildName
            
            foreach ($DelayedService in $DelayedStartServices) {
                $ServiceToRemove = $NonRunningAutoServices | Where-Object { $_.ServiceName -eq $DelayedService }
                if ($ServiceToRemove) {
                    $NonRunningAutoServices.Remove($ServiceToRemove) | Out-Null
                    Write-Log "Excluded delayed service: $DelayedService" -Level DEBUG
                }
            }
        } catch {
            Write-Log "Error filtering delayed services: $_" -Level WARN
        }
    }
    
    # Remove explicitly ignored services
    if ($ServicesToIgnore.Count -gt 0 -and $NonRunningAutoServices.Count -gt 0) {
        Write-Log "Filtering ignored services" -Level DEBUG
        
        foreach ($ServiceToIgnore in $ServicesToIgnore) {
            $ServiceToRemove = $NonRunningAutoServices | Where-Object { $_.ServiceName -eq $ServiceToIgnore }
            if ($ServiceToRemove) {
                $NonRunningAutoServices.Remove($ServiceToRemove) | Out-Null
                Write-Log "Excluded ignored service: $ServiceToIgnore" -Level DEBUG
            }
        }
    }
    
    Write-Log "Services after filtering: $($NonRunningAutoServices.Count)" -Level INFO
    
    # Build report
    if ($NonRunningAutoServices.Count -gt 0) {
        Write-Log "Stopped automatic services found" -Level WARN
        
        $ServicesReport = [System.Collections.Generic.List[object]]::new()
        $ServiceNamesList = [System.Collections.Generic.List[string]]::new()
        
        foreach ($Service in $NonRunningAutoServices) {
            # Get service description
            try {
                $ServiceInfo = Get-CimInstance -ClassName Win32_Service -Filter "Name = '$($Service.ServiceName)'" -ErrorAction Stop
                $Description = $ServiceInfo.Description
                
                if ($Description -and $Description.Length -gt 100) {
                    $Description = $Description.Substring(0, 100) + "..."
                }
            } catch {
                $Description = "(No description available)"
            }
            
            $ServicesReport.Add([PSCustomObject]@{
                Name = $Service.ServiceName
                Description = $Description
            })
            
            $ServiceNamesList.Add($Service.ServiceName)
        }
        
        # Display report
        Write-Log "Stopped Services Report:" -Level INFO
        foreach ($ServiceItem in ($ServicesReport | Sort-Object Name)) {
            Write-Log "  $($ServiceItem.Name): $($ServiceItem.Description)" -Level INFO
        }
        
        # Update custom fields
        Set-NinjaField -FieldName "stoppedServicesCount" -Value $NonRunningAutoServices.Count
        Set-NinjaField -FieldName "stoppedServicesList" -Value ($ServiceNamesList -join ", ")
        Set-NinjaField -FieldName "stoppedServicesStatus" -Value "Stopped Services Found"
        
    } else {
        Write-Log "No stopped automatic services detected" -Level SUCCESS
        
        Set-NinjaField -FieldName "stoppedServicesCount" -Value 0
        Set-NinjaField -FieldName "stoppedServicesList" -Value ""
        Set-NinjaField -FieldName "stoppedServicesStatus" -Value "All Services Running"
    }
    
    # Update status timestamp
    Set-NinjaField -FieldName "stoppedServicesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    # Attempt to start services if requested
    if ($StartFoundServices -and $NonRunningAutoServices.Count -gt 0) {
        Write-Log "Attempting to start stopped services" -Level INFO
        
        foreach ($Service in $NonRunningAutoServices) {
            Write-Log "Starting service: $($Service.ServiceName)" -Level INFO
            
            $Attempt = 1
            $MaxAttempts = 3
            $Started = $false
            
            while ($Attempt -le $MaxAttempts -and -not $Started) {
                Write-Log "  Attempt $Attempt of $MaxAttempts" -Level DEBUG
                
                try {
                    $Service | Start-Service -ErrorAction Stop
                    Write-Log "  Successfully started $($Service.ServiceName)" -Level SUCCESS
                    $Started = $true
                    
                } catch {
                    Write-Log "  Failed to start: $($_.Exception.Message)" -Level WARN
                    
                    if ($Attempt -eq $MaxAttempts) {
                        Write-Log "  All attempts failed for $($Service.ServiceName)" -Level ERROR
                    }
                }
                
                $Attempt++
            }
        }
    }
    
    # Determine exit code
    if ($NonRunningAutoServices.Count -gt 0) {
        Write-Log "Script completed with warnings (stopped services found)" -Level WARN
        $ExitCode = 1
    } else {
        Write-Log "Script completed successfully" -Level SUCCESS
        $ExitCode = 0
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "stoppedServicesStatus" -Value "Failed"
    Set-NinjaField -FieldName "stoppedServicesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    $ExitCode = 1
    
} finally {
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
    
    exit $ExitCode
}
