#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves all currently logged-on users on the system

.DESCRIPTION
    Queries the system to identify all currently logged-on users including console,
    RDP, and disconnected sessions. Provides username, session type, session state,
    and logon time for each active user session.
    
    The script performs the following:
    - Queries all active user sessions using quser command
    - Identifies console, RDP, and disconnected sessions
    - Reports session state (Active, Disconnected)
    - Provides logon timestamp for each session
    - Optionally saves user session data to NinjaRMM custom fields
    
    Monitoring logged-on users is useful for system administration, security auditing,
    and ensuring compliance with concurrent user license limits.
    
    This script runs unattended without user interaction.

.PARAMETER SaveToCustomField
    Optional name of NinjaRMM custom field to save logged-on user information.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\User-GetLoggedOnUsers.ps1
    
    Queries and displays all logged-on users to console.

.EXAMPLE
    .\User-GetLoggedOnUsers.ps1 -SaveToCustomField "ActiveUsers"
    
    Queries users and saves formatted list to specified custom field.

.NOTES
    Script Name:    User-GetLoggedOnUsers.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or Administrator
    Execution Frequency: On-demand or scheduled
    Typical Duration: ~1-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - SaveToCustomField (if specified) - Semicolon-separated list of active sessions
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - quser.exe (Windows built-in utility)
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - saveToCustomField: Alternative to -SaveToCustomField parameter
    
    Exit Codes:
        0 - Success (users found or no users logged on)
        1 - Failure (custom field update failed or query error)

.LINK
    https://github.com/Xore/waf
    https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/quser
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save user list")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$SaveToCustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "User-GetLoggedOnUsers"

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
$script:ExitCode = 0
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
    
    Write-Log "Querying logged-on users..." -Level INFO
    
    # Execute quser command to get logged-on users
    $QuserOutput = quser 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        # Parse quser output
        $Users = $QuserOutput | Select-Object -Skip 1 | ForEach-Object {
            $_ -replace '\s{2,}', ','
        } | ConvertFrom-Csv -Header "USERNAME", "SESSIONNAME", "ID", "STATE", "IDLE", "LOGON"
        
        if ($Users -and $Users.Count -gt 0) {
            Write-Log "Found $($Users.Count) logged-on user(s)" -Level SUCCESS
            Write-Log "" -Level INFO
            
            $UserList = @()
            foreach ($User in $Users) {
                # Format user session information
                $SessionType = if ($User.SESSIONNAME -and $User.SESSIONNAME -ne " ") { $User.SESSIONNAME } else { "Console" }
                $SessionState = if ($User.STATE -and $User.STATE -ne " ") { $User.STATE } else { "Active" }
                
                $UserInfo = "User: $($User.USERNAME) | Session: $SessionType | State: $SessionState"
                
                if ($User.LOGON -and $User.LOGON -ne " ") {
                    $UserInfo += " | Logon: $($User.LOGON)"
                }
                
                Write-Log $UserInfo -Level INFO
                $UserList += $UserInfo
            }
            
            # Save to custom field if specified
            if ($SaveToCustomField -and $UserList.Count -gt 0) {
                Write-Log "" -Level INFO
                $FormattedList = $UserList -join "; "
                Set-NinjaField -FieldName $SaveToCustomField -Value $FormattedList
                
                if ($script:ExitCode -eq 0) {
                    Write-Log "Results saved to custom field '$SaveToCustomField'" -Level SUCCESS
                }
            }
        } else {
            Write-Log "No users currently logged on" -Level INFO
        }
    } else {
        # quser returned non-zero exit code (typically means no users logged on)
        Write-Log "No users currently logged on" -Level INFO
    }
    
    if ($script:ExitCode -eq 0) {
        Write-Log "User query completed successfully" -Level SUCCESS
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
    
    exit $script:ExitCode
}
