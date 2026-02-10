#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Restarts one or more Windows services with retry logic and timeout handling

.DESCRIPTION
    Restarts specified Windows services with configurable retry attempts and wait times.
    Supports multiple services, validates service existence, and monitors restart status.
    
    The script performs the following:
    - Validates administrator privileges
    - Accepts service names or display names
    - Restarts services with configurable timeouts
    - Retries failed starts with configurable attempts
    - Waits between restart attempts
    - Reports detailed service status
    - Updates NinjaRMM custom fields with results
    
    This script runs unattended without user interaction.

.PARAMETER Name
    Service name(s) to restart. Accepts either ServiceName or DisplayName.
    Can be a single service or comma-separated list.
    Examples: "wuauserv", "Windows Update", "Spooler,BITS"

.PARAMETER Attempts
    Number of restart attempts per service before giving up.
    Default: 3
    Range: 1-10

.PARAMETER WaitTimeInSecs
    Duration in seconds to wait for service to start between each attempt.
    Default: 15
    Range: 5-300

.EXAMPLE
    .\Services-RestartService.ps1 -Name "wuauserv"
    
    Restarts Windows Update service with default settings (3 attempts, 15 second wait).

.EXAMPLE
    .\Services-RestartService.ps1 -Name "Spooler,BITS" -Attempts 5 -WaitTimeInSecs 30
    
    Restarts Print Spooler and BITS services with 5 attempts and 30 second waits.

.EXAMPLE
    .\Services-RestartService.ps1 -Name "Windows Update"
    
    Restarts service using display name instead of service name.

.NOTES
    Script Name:    Services-RestartService.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or scheduled
    Typical Duration: 5-45 seconds (depends on service count and retry attempts)
    Timeout Setting: 120 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no system restart required)
    
    Fields Updated:
        - serviceRestartStatus (Success/Failed)
        - serviceRestartDate (timestamp)
        - serviceRestartCount (number of services restarted)
        - serviceRestartList (service names)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Services must exist on system
    
    Environment Variables (Optional):
        - Name: Alternative to -Name parameter
        - Attempts: Alternative to -Attempts parameter
        - WaitTimeInSecs: Alternative to -WaitTimeInSecs parameter
    
    Exit Codes:
        0 - Success (all services restarted successfully)
        1 - Failure (one or more services failed to restart)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Service name(s) to restart")]
    [ValidateNotNullOrEmpty()]
    [string[]]$Name,
    
    [Parameter(Mandatory=$false, HelpMessage="Number of restart attempts")]
    [ValidateRange(1, 10)]
    [int]$Attempts = 3,
    
    [Parameter(Mandatory=$false, HelpMessage="Wait time in seconds between attempts")]
    [ValidateRange(5, 300)]
    [int]$WaitTimeInSecs = 15
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Services-RestartService"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
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
        }
    }
}

function Test-IsElevated {
    <#
    .SYNOPSIS
        Checks if the script is running with administrator privileges
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
    
    # Support environment variables
    if ($env:Name -and $env:Name -notlike "null") {
        $Name = $env:Name
        Write-Log "Using service name from environment: $Name" -Level DEBUG
    }
    
    if ($env:Attempts -and $env:Attempts -notlike "null") {
        $Attempts = [int]$env:Attempts
        Write-Log "Using attempts from environment: $Attempts" -Level DEBUG
    }
    
    if ($env:WaitTimeInSecs -and $env:WaitTimeInSecs -notlike "null") {
        $WaitTimeInSecs = [int]$env:WaitTimeInSecs
        Write-Log "Using wait time from environment: $WaitTimeInSecs" -Level DEBUG
    }
    
    # Validate required parameter
    if (-not $Name) {
        throw "Name parameter is required. Specify one or more service names."
    }
    
    # Verify administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    Write-Log "Administrator privileges verified" -Level DEBUG
    
    # Parse comma-separated service names
    if ($Name -like "*,*") {
        $Name = $Name -split ',' | ForEach-Object { $_.Trim() }
        Write-Log "Processing multiple services: $($Name.Count)" -Level INFO
    }
    
    Write-Log "Configuration: Attempts=$Attempts, WaitTime=$WaitTimeInSecs seconds" -Level INFO
    Write-Log "" -Level INFO
    
    # Find services matching criteria
    Write-Log "Finding services matching criteria..." -Level INFO
    $Services = Get-Service -ErrorAction Stop | 
        Where-Object { $_.Name -in $Name -or $_.DisplayName -in $Name }
    
    if ($Services.Count -eq 0) {
        throw "No services found matching: $($Name -join ', ')"
    }
    
    Write-Log "Found $($Services.Count) service(s) to restart" -Level SUCCESS
    Write-Log "" -Level INFO
    
    $FailedServices = [System.Collections.Generic.List[string]]::new()
    $SuccessServices = [System.Collections.Generic.List[string]]::new()
    
    # Restart each service
    foreach ($Service in $Services) {
        Write-Log "Restarting service: $($Service.Name) ($($Service.DisplayName))" -Level INFO
        Write-Log "  Current status: $($Service.Status)" -Level INFO
        
        $AttemptCounter = $Attempts
        $ServiceRestarted = $false
        
        try {
            # Issue restart command
            Restart-Service -Name $Service.Name -Force -ErrorAction Stop
            Write-Log "  Restart command issued" -Level DEBUG
            
            # Wait and verify service started
            while ($AttemptCounter -gt 0) {
                Start-Sleep -Seconds $WaitTimeInSecs
                
                $CurrentService = Get-Service -Name $Service.Name -ErrorAction Stop
                $AttemptNum = $Attempts - $AttemptCounter + 1
                Write-Log "  Attempt $AttemptNum/$Attempts - Status: $($CurrentService.Status)" -Level INFO
                
                if ($CurrentService.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) {
                    Write-Log "  Service $($Service.Name) is now running" -Level SUCCESS
                    $ServiceRestarted = $true
                    $SuccessServices.Add($Service.Name)
                    break
                }
                
                # Try to start if not running
                if ($CurrentService.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
                    Write-Log "  Service not running, attempting to start" -Level WARN
                    Start-Service -Name $Service.Name -ErrorAction SilentlyContinue
                }
                
                $AttemptCounter--
            }
            
            if (-not $ServiceRestarted) {
                throw "Service failed to reach Running state after $Attempts attempts"
            }
            
        } catch {
            Write-Log "  Failed to restart $($Service.Name): $($_.Exception.Message)" -Level ERROR
            $FailedServices.Add($Service.Name)
        }
        
        Write-Log "" -Level INFO
    }
    
    # Report summary
    Write-Log "Service Restart Summary:" -Level INFO
    Write-Log "  Total services: $($Services.Count)" -Level INFO
    Write-Log "  Successfully restarted: $($SuccessServices.Count)" -Level INFO
    Write-Log "  Failed to restart: $($FailedServices.Count)" -Level INFO
    
    if ($SuccessServices.Count -gt 0) {
        Write-Log "  Success list: $($SuccessServices -join ', ')" -Level SUCCESS
    }
    
    if ($FailedServices.Count -gt 0) {
        Write-Log "  Failed list: $($FailedServices -join ', ')" -Level ERROR
    }
    
    # Update custom fields
    if ($FailedServices.Count -eq 0) {
        Set-NinjaField -FieldName "serviceRestartStatus" -Value "Success"
        Write-Log "All services restarted successfully" -Level SUCCESS
        $script:ExitCode = 0
    } else {
        Set-NinjaField -FieldName "serviceRestartStatus" -Value "Failed"
        Write-Log "Some services failed to restart" -Level ERROR
        $script:ExitCode = 1
    }
    
    Set-NinjaField -FieldName "serviceRestartDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Set-NinjaField -FieldName "serviceRestartCount" -Value $SuccessServices.Count
    Set-NinjaField -FieldName "serviceRestartList" -Value ($SuccessServices -join ", ")
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "serviceRestartStatus" -Value "Failed"
    Set-NinjaField -FieldName "serviceRestartDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
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
