#Requires -Version 5.1

<#
.SYNOPSIS
    Searches Windows Event Logs for specific event IDs or patterns within a time range.

.DESCRIPTION
    This script queries Windows Event Logs to find events matching specified criteria including 
    event ID, log name, time range, and optional keyword filters. It provides formatted output 
    of matching events for troubleshooting and auditing purposes.
    
    Event log searching is essential for diagnosing system issues, investigating security incidents, 
    and compliance auditing. This script simplifies complex event log queries.

.PARAMETER LogName
    Name of the event log to search. Default: System
    Common values: System, Application, Security

.PARAMETER EventID
    Specific event ID to search for. If not specified, returns all events.

.PARAMETER Hours
    Number of hours in the past to search. Default: 24 hours

.PARAMETER MaxEvents
    Maximum number of events to return. Default: 100

.PARAMETER SaveToCustomField
    Name of a custom field to save the search results.

.EXAMPLE
    -LogName System -EventID 1074 -Hours 48

    [Info] Searching System log for Event ID 1074 in the last 48 hours...
    [Info] Found 3 matching event(s)
    
    TimeCreated: 02/09/2026 15:30:00
    Message: The process C:\Windows\System32\shutdown.exe has initiated the restart...

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    
.COMPONENT
    Get-WinEvent - Windows event log query cmdlet
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent

.FUNCTIONALITY
    - Queries Windows Event Logs with time-based filters
    - Supports filtering by event ID
    - Returns configurable maximum number of events
    - Provides formatted output with timestamp and message
    - Can save results to custom fields for reporting
    - Supports System, Application, Security, and custom event logs
#>

[CmdletBinding()]
param(
    [string]$LogName = "System",
    [int]$EventID,
    [int]$Hours = 24,
    [int]$MaxEvents = 100,
    [string]$SaveToCustomField
)

begin {
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
    $StartTime = (Get-Date).AddHours(-$Hours)
}

process {
    try {
        $FilterHashtable = @{
            LogName = $LogName
            StartTime = $StartTime
        }

        if ($EventID) {
            $FilterHashtable['ID'] = $EventID
            Write-Host "[Info] Searching $LogName log for Event ID $EventID in the last $Hours hours..."
        }
        else {
            Write-Host "[Info] Searching $LogName log for all events in the last $Hours hours..."
        }

        $Events = Get-WinEvent -FilterHashtable $FilterHashtable -MaxEvents $MaxEvents -ErrorAction Stop

        if ($Events) {
            Write-Host "[Info] Found $($Events.Count) matching event(s)`n"
            
            $Report = @()
            foreach ($Event in $Events) {
                $EventInfo = "TimeCreated: $($Event.TimeCreated) | ID: $($Event.Id) | Message: $($Event.Message.Substring(0, [Math]::Min(100, $Event.Message.Length)))"
                Write-Host $EventInfo
                $Report += $EventInfo
            }

            if ($SaveToCustomField) {
                try {
                    $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Host "`n[Info] Results saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Host "[Error] Failed to save to custom field: $_"
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Host "[Info] No matching events found"
        }
    }
    catch {
        Write-Host "[Error] Failed to search event log: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
