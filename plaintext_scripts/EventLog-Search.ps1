#Requires -Version 5.1

<#
.SYNOPSIS
    Searches Windows Event Logs for specific events within a time range

.DESCRIPTION
    Queries Windows Event Logs to find events matching specified criteria including
    event ID, log name, time range, and optional keyword filters. Provides formatted
    output of matching events for troubleshooting and auditing purposes.
    
    The script performs the following:
    - Queries Windows Event Logs with time-based filters
    - Filters by specific event ID or returns all events
    - Supports configurable maximum event count
    - Formats output with timestamp, event ID, and message preview
    - Optionally saves results to NinjaRMM custom fields
    - Supports System, Application, Security, and custom event logs
    
    Event log searching is essential for diagnosing system issues, investigating
    security incidents, and compliance auditing. This script simplifies complex
    event log queries into a single standardized interface.
    
    This script runs unattended without user interaction.

.PARAMETER LogName
    Name of the event log to search.
    Default: "System"
    Common values: System, Application, Security, Setup, ForwardedEvents

.PARAMETER EventID
    Specific event ID to filter for.
    If not specified, returns all events within the time range.

.PARAMETER Hours
    Number of hours in the past to search.
    Default: 24 hours
    Range: 1 to 720 (30 days)

.PARAMETER MaxEvents
    Maximum number of events to return.
    Default: 100
    Range: 1 to 10000

.PARAMETER SaveToCustomField
    Name of a NinjaRMM custom field to save the search results.
    Results are saved as semicolon-delimited text.

.EXAMPLE
    .\EventLog-Search.ps1 -LogName System -EventID 1074 -Hours 48
    
    Searches the System log for Event ID 1074 (system shutdown) in the last 48 hours.

.EXAMPLE
    .\EventLog-Search.ps1 -LogName Application -Hours 1 -MaxEvents 50
    
    Returns up to 50 Application log events from the last hour.

.EXAMPLE
    .\EventLog-Search.ps1 -LogName Security -EventID 4624 -Hours 24 -SaveToCustomField "RecentLogons"
    
    Searches for successful logon events and saves results to a custom field.

.NOTES
    Script Name:    EventLog-Search.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (SYSTEM via NinjaRMM)
    Execution Frequency: On-demand for troubleshooting
    Typical Duration: 2-10 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Get-WinEvent cmdlet
        - Appropriate permissions for queried log
        - Security log requires Administrator privileges
    
    Environment Variables (Optional):
        - logName: Alternative to -LogName parameter
        - eventID: Alternative to -EventID parameter
        - hours: Alternative to -Hours parameter
        - maxEvents: Alternative to -MaxEvents parameter
        - saveToCustomField: Alternative to -SaveToCustomField parameter
    
    Exit Codes:
        0 - Success (events found or no events matching criteria)
        1 - Failure (event log query failed or save to custom field failed)

.LINK
    https://github.com/Xore/waf
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$LogName = "System",
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,99999)]
    [int]$EventID,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,720)]
    [int]$Hours = 24,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,10000)]
    [int]$MaxEvents = 100,
    
    [Parameter(Mandatory=$false)]
    [ValidateLength(1,255)]
    [string]$SaveToCustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "EventLog-Search"

# Support environment variables
if ($env:logName -and $env:logName -notlike "null") {
    $LogName = $env:logName
}
if ($env:eventID -and $env:eventID -notlike "null") {
    $EventID = [int]$env:eventID
}
if ($env:hours -and $env:hours -notlike "null") {
    $Hours = [int]$env:hours
}
if ($env:maxEvents -and $env:maxEvents -notlike "null") {
    $MaxEvents = [int]$env:maxEvents
}
if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
    $SaveToCustomField = $env:saveToCustomField
}

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$ExitCode = 0
$ErrorCount = 0
$WarningCount = 0
$CLIFallbackCount = 0
$EventsFound = 0

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
    
    # Calculate start time for event search
    $SearchStartTime = (Get-Date).AddHours(-$Hours)
    
    # Build filter hashtable
    $FilterHashtable = @{
        LogName = $LogName
        StartTime = $SearchStartTime
    }
    
    # Log search parameters
    if ($EventID) {
        $FilterHashtable['ID'] = $EventID
        Write-Log "Searching log: $LogName" -Level INFO
        Write-Log "Event ID filter: $EventID" -Level INFO
    } else {
        Write-Log "Searching log: $LogName (all event IDs)" -Level INFO
    }
    
    Write-Log "Time range: Last $Hours hours (since $($SearchStartTime.ToString('yyyy-MM-dd HH:mm:ss')))" -Level INFO
    Write-Log "Maximum events: $MaxEvents" -Level INFO
    
    # Query event log
    try {
        $Events = Get-WinEvent -FilterHashtable $FilterHashtable -MaxEvents $MaxEvents -ErrorAction Stop
        $EventsFound = $Events.Count
        
        if ($Events) {
            Write-Log "Found $EventsFound matching event(s)" -Level SUCCESS
            Write-Log "" -Level INFO
            
            $Report = @()
            foreach ($Event in $Events) {
                # Truncate message to 150 characters for readability
                $MessagePreview = if ($Event.Message.Length -gt 150) {
                    $Event.Message.Substring(0, 150) + "..."
                } else {
                    $Event.Message
                }
                
                # Format event information
                $EventInfo = "Time: $($Event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss')) | ID: $($Event.Id) | Level: $($Event.LevelDisplayName) | Message: $MessagePreview"
                Write-Log $EventInfo -Level INFO
                
                # Add to report for custom field
                $Report += "[$($Event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))] ID:$($Event.Id) - $MessagePreview"
            }
            
            # Save to custom field if specified
            if ($SaveToCustomField) {
                try {
                    $ReportText = $Report -join "; "
                    # Truncate if too long (NinjaRMM field limit)
                    if ($ReportText.Length -gt 10000) {
                        $ReportText = $ReportText.Substring(0, 9997) + "..."
                        Write-Log "Report truncated to 10000 characters" -Level WARN
                    }
                    
                    Set-NinjaField -Name $SaveToCustomField -Value $ReportText
                    Write-Log "Results saved to custom field '$SaveToCustomField'" -Level SUCCESS
                } catch {
                    Write-Log "Failed to save to custom field '$SaveToCustomField': $($_.Exception.Message)" -Level ERROR
                    throw
                }
            }
        } else {
            Write-Log "No matching events found" -Level INFO
        }
    } catch [System.Diagnostics.Eventing.Reader.EventLogException] {
        Write-Log "Event log query failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Verify log name is correct and you have permission to read it" -Level INFO
        throw
    } catch {
        Write-Log "Event log query failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    $ExitCode = 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Events Found: $EventsFound" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $ErrorCount" -Level INFO
    Write-Log "  Warnings: $WarningCount" -Level INFO
    Write-Log "  CLI Fallbacks: $CLIFallbackCount" -Level INFO
    Write-Log "  Exit Code: $ExitCode" -Level INFO
    Write-Log "========================================" -Level INFO
    
    exit $ExitCode
}
