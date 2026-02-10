#Requires -Version 5.1
#Requires -Modules WebAdministration

<#
.SYNOPSIS
    Restarts a specified IIS application pool

.DESCRIPTION
    Restarts an IIS application pool by name with graceful shutdown and verification.
    This script performs the following operations:
    - Validates the application pool exists
    - Reports current state before restart
    - Stops the app pool gracefully with configurable timeout
    - Waits for complete shutdown
    - Starts the app pool
    - Verifies successful restart
    - Saves results to NinjaRMM custom fields if specified
    
    This is useful for applying configuration changes, clearing memory leaks, recovering
    from hung worker processes, or routine maintenance operations. The script includes
    safety checks and detailed status reporting throughout the restart process.
    
    This script runs unattended without user interaction.

.PARAMETER AppPoolName
    Name of the IIS application pool to restart. This is a required parameter.
    The app pool must exist in IIS or the script will fail.

.PARAMETER WaitTimeout
    Maximum seconds to wait for the app pool to stop before forcing.
    Default is 30 seconds. Increase for larger applications.

.PARAMETER SaveToCustomField
    Name of a NinjaRMM custom field to save the restart operation results.
    Results include timestamp and final state.

.EXAMPLE
    .\IIS-RestartAppPool.ps1 -AppPoolName "DefaultAppPool"
    
    Restarts the DefaultAppPool with default 30-second timeout.

.EXAMPLE
    .\IIS-RestartAppPool.ps1 -AppPoolName "MyWebApp" -WaitTimeout 60
    
    Restarts MyWebApp pool with 60-second timeout.

.EXAMPLE
    .\IIS-RestartAppPool.ps1 -AppPoolName "DefaultAppPool" -SaveToCustomField "LastAppPoolRestart"
    
    Restarts pool and saves results to custom field.

.NOTES
    Script Name:    IIS-RestartAppPool.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (SYSTEM via NinjaRMM)
    Execution Frequency: On-demand or scheduled for maintenance
    Typical Duration: 5-15 seconds depending on app pool size
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: Restarts specified IIS app pool only
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - WebAdministration PowerShell module
        - IIS role installed on Windows Server
        - Administrator privileges required
    
    Environment Variables (Optional):
        - appPoolName: Alternative to -AppPoolName parameter
        - waitTimeout: Alternative to -WaitTimeout parameter
        - saveToCustomField: Alternative to -SaveToCustomField parameter
    
    Exit Codes:
        0 - Success (app pool restarted successfully)
        1 - Failure (app pool not found, restart failed, or verification failed)
    
    Performance Note:
        Stop/start time varies based on app pool size and active requests.
        Timeout should be adjusted based on application requirements.

.LINK
    https://github.com/Xore/waf
    https://learn.microsoft.com/en-us/powershell/module/webadministration/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppPoolName,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(5,300)]
    [int]$WaitTimeout = 30,
    
    [Parameter(Mandatory=$false)]
    [ValidateLength(1,255)]
    [string]$SaveToCustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "IIS-RestartAppPool"

# Support environment variables
if ($env:appPoolName -and $env:appPoolName -notlike "null") {
    $AppPoolName = $env:appPoolName
}
if ($env:waitTimeout -and $env:waitTimeout -notlike "null") {
    $WaitTimeout = [int]$env:waitTimeout
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
$InitialState = "Unknown"
$FinalState = "Unknown"
$RestartSuccessful = $false

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
        [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS','ALERT')]
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
        'ALERT' { $script:WarningCount++ }
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
    
    # Validate AppPoolName parameter
    if ([string]::IsNullOrWhiteSpace($AppPoolName)) {
        throw "AppPoolName parameter is required and cannot be empty"
    }
    
    Write-Log "Target app pool: $AppPoolName" -Level INFO
    Write-Log "Wait timeout: $WaitTimeout seconds" -Level DEBUG
    
    # Import WebAdministration module
    try {
        Import-Module WebAdministration -ErrorAction Stop
        Write-Log "WebAdministration module loaded successfully" -Level DEBUG
    } catch {
        throw "Failed to load WebAdministration module. Ensure IIS is installed: $($_.Exception.Message)"
    }
    
    # Check if app pool exists
    Write-Log "Verifying app pool exists..." -Level INFO
    $AppPool = Get-Item "IIS:\AppPools\$AppPoolName" -ErrorAction SilentlyContinue
    
    if (-not $AppPool) {
        throw "Application pool '$AppPoolName' not found in IIS"
    }
    
    $InitialState = $AppPool.State
    Write-Log "App pool found - Current state: $InitialState" -Level INFO
    
    # Stop app pool if running
    if ($InitialState -eq "Started") {
        Write-Log "Stopping application pool..." -Level INFO
        
        try {
            Stop-WebAppPool -Name $AppPoolName -ErrorAction Stop
            
            # Wait for app pool to stop
            $ElapsedSeconds = 0
            $CurrentState = (Get-WebAppPoolState -Name $AppPoolName).Value
            
            while ($CurrentState -ne "Stopped" -and $ElapsedSeconds -lt $WaitTimeout) {
                Start-Sleep -Seconds 1
                $ElapsedSeconds++
                $CurrentState = (Get-WebAppPoolState -Name $AppPoolName).Value
            }
            
            if ($CurrentState -ne "Stopped") {
                Write-Log "App pool did not stop within $WaitTimeout seconds (current state: $CurrentState)" -Level WARN
                Write-Log "Forcing restart anyway..." -Level WARN
            } else {
                Write-Log "App pool stopped successfully after $ElapsedSeconds seconds" -Level SUCCESS
            }
            
        } catch {
            Write-Log "Error stopping app pool: $($_.Exception.Message)" -Level ERROR
            throw
        }
        
    } else {
        Write-Log "App pool is not running (state: $InitialState), proceeding to start" -Level INFO
    }
    
    # Start app pool
    Write-Log "Starting application pool..." -Level INFO
    
    try {
        Start-WebAppPool -Name $AppPoolName -ErrorAction Stop
        Start-Sleep -Seconds 2
        
        $FinalState = (Get-WebAppPoolState -Name $AppPoolName).Value
        
        if ($FinalState -eq "Started") {
            Write-Log "App pool '$AppPoolName' restarted successfully" -Level SUCCESS
            $RestartSuccessful = $true
            $ResultMessage = "App pool '$AppPoolName' restarted successfully at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        } else {
            Write-Log "App pool is in state '$FinalState' after restart attempt" -Level ERROR
            $ResultMessage = "App pool '$AppPoolName' restart failed - final state: $FinalState"
            $script:ExitCode = 1
        }
        
    } catch {
        Write-Log "Error starting app pool: $($_.Exception.Message)" -Level ERROR
        $ResultMessage = "App pool '$AppPoolName' restart failed: $($_.Exception.Message)"
        throw
    }
    
    # Save to custom field if specified
    if ($SaveToCustomField) {
        try {
            Set-NinjaField -Name $SaveToCustomField -Value $ResultMessage
            Write-Log "Results saved to custom field '$SaveToCustomField'" -Level SUCCESS
        } catch {
            Write-Log "Failed to save to custom field: $($_.Exception.Message)" -Level ERROR
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
    Write-Log "  App Pool Name: $AppPoolName" -Level INFO
    Write-Log "  Initial State: $InitialState" -Level INFO
    Write-Log "  Final State: $FinalState" -Level INFO
    Write-Log "  Restart Successful: $RestartSuccessful" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    Write-Log "  Exit Code: $script:ExitCode" -Level INFO
    Write-Log "========================================" -Level INFO
    
    exit $script:ExitCode
}
