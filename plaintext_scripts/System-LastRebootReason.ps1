#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Retrieves and reports system reboot reasons from event logs

.DESCRIPTION
    Comprehensive reboot tracking script that analyzes Windows event logs to
    determine the reasons for system reboots and shutdowns. Queries Event IDs
    6008 (unexpected shutdowns) and 1074 (planned shutdowns/reboots) to build
    a complete reboot history.
    
    The script performs the following:
    - Retrieves last 14 reboot events from System event log
    - Translates SIDs to usernames for proper user attribution
    - Formats reboot data with timestamps and reasons
    - Optionally saves latest reboot to text custom field
    - Optionally saves full history to WYSIWYG custom field
    - Generates HTML formatted report for easy viewing
    - Provides detailed console output for troubleshooting
    
    Unexpected shutdowns can indicate power failures, crashes, or forced
    shutdowns. Planned reboots show Windows Update installs, user-initiated
    reboots, and maintenance operations.

.PARAMETER TextCustomField
    Name of NinjaRMM text custom field to store latest reboot reason.
    Value will be truncated to 100 characters if needed.

.PARAMETER WysiwygCustomField
    Name of NinjaRMM WYSIWYG custom field to store full reboot history.
    Displays HTML formatted table of up to 14 recent reboots.

.PARAMETER MaxEvents
    Maximum number of reboot events to retrieve.
    Default: 14

.EXAMPLE
    .\System-LastRebootReason.ps1
    
    Retrieves and displays last 14 reboot reasons.

.EXAMPLE
    .\System-LastRebootReason.ps1 -TextCustomField "lastRebootReason"
    
    Saves latest reboot reason to text custom field.

.EXAMPLE
    .\System-LastRebootReason.ps1 -WysiwygCustomField "rebootHistory"
    
    Saves full reboot history to WYSIWYG custom field with HTML formatting.

.EXAMPLE
    .\System-LastRebootReason.ps1 -TextCustomField "lastRebootReason" -WysiwygCustomField "rebootHistory" -MaxEvents 20
    
    Saves to both fields and retrieves up to 20 events.

.NOTES
    Script Name:    System-LastRebootReason.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: Administrator (required for event log access)
    Execution Frequency: Daily or after reboot
    Typical Duration: ~3-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - TextCustomField - Latest reboot reason (single line, max 100 chars)
        - WysiwygCustomField - Full reboot history (HTML table)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges
        - System event log access
        - Windows 10 or Server 2016 minimum
    
    Event IDs Monitored:
        - 6008: Unexpected shutdown (crash, power loss)
        - 1074: Planned shutdown/restart (user, Windows Update)
    
    Environment Variables (Optional):
        - lastRebootReasonTextCustomField: Override -TextCustomField parameter
        - last14RebootReasonsWysiwygCustomField: Override -WysiwygCustomField parameter
        - maxEvents: Override -MaxEvents parameter
    
    Exit Codes:
        0 - Success (reboot reasons retrieved)
        1 - Failure (no events found or field update failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Text custom field for latest reboot")]
    [string]$TextCustomField,
    
    [Parameter(Mandatory=$false, HelpMessage="WYSIWYG custom field for reboot history")]
    [string]$WysiwygCustomField,
    
    [Parameter(Mandatory=$false, HelpMessage="Maximum number of events to retrieve")]
    [ValidateRange(1, 100)]
    [int]$MaxEvents = 14
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "System-LastRebootReason"

# Event IDs to monitor
$UnexpectedShutdownEventID = 6008  # Unexpected shutdown
$PlannedShutdownEventID = 1074      # Planned shutdown/restart

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
        $Value,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Text','WYSIWYG')]
        [string]$Type = 'Text'
    )
    
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    # Handle WYSIWYG non-breaking spaces
    if ($Type -eq 'WYSIWYG') {
        $ValueString = $ValueString -replace ' ', '&nbsp;'
    }
    
    # Check character limits
    $CharCount = $ValueString.Length
    $Limit = if ($Type -eq 'WYSIWYG') { 45000 } else { 10000 }
    
    if ($CharCount -gt $Limit) {
        Write-Log "Value exceeds $Limit character limit ($CharCount chars), truncating" -Level WARN
        $ValueString = $ValueString.Substring(0, $Limit - 3) + "..."
    }
    
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' set successfully ($CharCount chars)" -Level DEBUG
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

function Get-RebootEvents {
    <#
    .SYNOPSIS
        Retrieves reboot/shutdown events from System event log
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$MaxEvents
    )
    
    try {
        Write-Log "Querying event log for reboot reasons (Event IDs 6008, 1074)" -Level INFO
        
        # Build XML filter for specific event IDs
        [xml]$FilterXML = @"
<QueryList>
  <Query Id='0' Path='System'>
    <Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-Eventlog' or @Name='EventLog' or @Name='Microsoft-Windows-Kernel-General'] and(EventID=$UnexpectedShutdownEventID)]]</Select>
    <Select Path='System'>*[System[(EventID=$PlannedShutdownEventID)]]</Select>
  </Query>
</QueryList>
"@
        
        $Events = Get-WinEvent -FilterXml $FilterXML -MaxEvents $MaxEvents -ErrorAction Stop
        
        if ($Events) {
            Write-Log "Found $($Events.Count) reboot event(s)" -Level SUCCESS
            return $Events
        } else {
            Write-Log "No reboot events found" -Level WARN
            return $null
        }
        
    } catch {
        Write-Log "Failed to query event log: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function ConvertFrom-SIDToUsername {
    <#
    .SYNOPSIS
        Converts a SID to a username using various methods
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SID,
        
        [Parameter(Mandatory=$false)]
        $UserProfiles
    )
    
    try {
        # Try direct SID translation first
        $SecurityID = New-Object System.Security.Principal.SecurityIdentifier($SID)
        $Username = $SecurityID.Translate([System.Security.Principal.NTAccount]).Value
        
        if ($Username) {
            Write-Log "Translated SID $SID to $Username" -Level DEBUG
            return $Username
        }
        
    } catch {
        Write-Log "Direct SID translation failed for $SID, trying registry lookup" -Level DEBUG
    }
    
    # Fallback to registry profile lookup
    if ($UserProfiles) {
        $Profile = $UserProfiles | Where-Object { $_.PSChildName -eq $SID }
        
        if ($Profile -and $Profile.ProfileImagePath) {
            $Username = Split-Path -Path $Profile.ProfileImagePath -Leaf
            Write-Log "Found username from profile: $Username" -Level DEBUG
            return $Username
        }
    }
    
    # Ultimate fallback - return SID itself
    Write-Log "Could not translate SID $SID, using SID as username" -Level WARN
    return $SID
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable overrides
    if ($env:lastRebootReasonTextCustomField -and $env:lastRebootReasonTextCustomField -notlike "null") {
        $TextCustomField = $env:lastRebootReasonTextCustomField.Trim()
        Write-Log "TextCustomField from environment: $TextCustomField" -Level INFO
    }
    
    if ($env:last14RebootReasonsWysiwygCustomField -and $env:last14RebootReasonsWysiwygCustomField -notlike "null") {
        $WysiwygCustomField = $env:last14RebootReasonsWysiwygCustomField.Trim()
        Write-Log "WysiwygCustomField from environment: $WysiwygCustomField" -Level INFO
    }
    
    if ($env:maxEvents -and $env:maxEvents -notlike "null") {
        $MaxEvents = [int]$env:maxEvents
        Write-Log "MaxEvents from environment: $MaxEvents" -Level INFO
    }
    
    # Validate custom field parameters
    if ($TextCustomField -and [string]::IsNullOrWhiteSpace($TextCustomField)) {
        throw "TextCustomField parameter is empty after trimming"
    }
    
    if ($WysiwygCustomField -and [string]::IsNullOrWhiteSpace($WysiwygCustomField)) {
        throw "WysiwygCustomField parameter is empty after trimming"
    }
    
    # Check administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required. Please run as Administrator."
    }
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    
    # Retrieve reboot events
    $RebootEvents = Get-RebootEvents -MaxEvents $MaxEvents
    
    if (-not $RebootEvents) {
        throw "No reboot events found in System event log"
    }
    
    $EventCount = $RebootEvents.Count
    
    if ($EventCount -lt $MaxEvents) {
        Write-Log "Only $EventCount reboot event(s) found (requested $MaxEvents)" -Level WARN
    }
    
    # Get user profiles for SID translation
    Write-Log "Loading user profiles for SID translation" -Level DEBUG
    try {
        $UserProfiles = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*"
        Write-Log "Loaded $($UserProfiles.Count) user profile(s)" -Level DEBUG
    } catch {
        Write-Log "Failed to load user profiles: $_" -Level WARN
        $UserProfiles = $null
    }
    
    # Format reboot events
    Write-Log "Formatting reboot event data" -Level DEBUG
    
    $FormattedResults = foreach ($Event in $RebootEvents) {
        # Determine username
        $Username = if ($Event.UserId) {
            ConvertFrom-SIDToUsername -SID $Event.UserId.Value -UserProfiles $UserProfiles
        } else {
            "N/A"
        }
        
        # Create formatted object
        [PSCustomObject]@{
            TimeCreated   = $Event.TimeCreated
            FormattedDate = $Event.TimeCreated.ToString('MM/dd/yyyy hh:mm tt')
            EventID       = $Event.Id
            Username      = $Username
            Message       = $Event.Message
        }
    }
    
    Write-Log "Formatted $($FormattedResults.Count) reboot event(s)" -Level SUCCESS
    
    # Update text custom field if specified
    if ($TextCustomField) {
        Write-Log "Updating text custom field: $TextCustomField" -Level INFO
        
        $LatestEvent = $FormattedResults | Select-Object -First 1
        
        # Truncate message if too long
        $MessageText = $LatestEvent.Message -replace '[\r\n]+', ' '
        if ($MessageText.Length -gt 100) {
            $MessageText = $MessageText.Substring(0, 97) + "..."
        }
        
        $TextValue = "$($LatestEvent.FormattedDate) | EventID: $($LatestEvent.EventID) | Username: $($LatestEvent.Username) | Reason: $MessageText"
        
        Set-NinjaField -FieldName $TextCustomField -Value $TextValue -Type 'Text'
        Write-Log "Text custom field updated successfully" -Level SUCCESS
    }
    
    # Update WYSIWYG custom field if specified
    if ($WysiwygCustomField) {
        Write-Log "Updating WYSIWYG custom field: $WysiwygCustomField" -Level INFO
        
        # Generate HTML table
        $HTMLTable = $FormattedResults |
            Select-Object FormattedDate, EventID, Username, Message |
            ConvertTo-Html -Fragment
        
        # Format HTML table
        $HTMLTable = $HTMLTable -replace '<th>', '<th><b>' -replace '</th>', '</b></th>'
        $HTMLTable = $HTMLTable -replace '<th><b>FormattedDate', "<th style='width: 12em'><b>Date"
        $HTMLTable = $HTMLTable -replace '<th><b>EventID', "<th style='width: 6em'><b>Event ID"
        $HTMLTable = $HTMLTable -replace '<th><b>Username', "<th style='width: 20em'><b>Username"
        $HTMLTable = $HTMLTable -replace '<th><b>Message', "<th><b>Reason"
        
        $HTMLValue = $HTMLTable -join "`n"
        
        Set-NinjaField -FieldName $WysiwygCustomField -Value $HTMLValue -Type 'WYSIWYG'
        Write-Log "WYSIWYG custom field updated successfully" -Level SUCCESS
    }
    
    # Display results to console
    Write-Log "" -Level INFO
    Write-Log "Past Reboot Events:" -Level INFO
    Write-Log "==================" -Level INFO
    
    foreach ($Event in $FormattedResults) {
        Write-Log "" -Level INFO
        Write-Log "Date: $($Event.FormattedDate)" -Level INFO
        Write-Log "Event ID: $($Event.EventID)" -Level INFO
        Write-Log "Username: $($Event.Username)" -Level INFO
        Write-Log "Reason: $($Event.Message -replace '[\r\n]+', ' ')" -Level INFO
    }
    
    Write-Log "" -Level INFO
    Write-Log "Reboot tracking completed: $EventCount event(s) processed" -Level SUCCESS
    
    exit 0
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    exit 1
    
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
}
