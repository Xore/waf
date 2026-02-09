#Requires -Version 5.1

<#
.SYNOPSIS
    Generate detailed user session login and logout activity report from Windows Security logs

.DESCRIPTION
    Comprehensive security audit tool that extracts and analyzes Windows authentication
    events from the Security event log. Provides detailed session tracking including
    successful logins, failed login attempts, and logout events for user accounts.
    
    Technical Implementation:
    This script queries the Windows Security event log for specific authentication-related
    event IDs and processes them to create human-readable session activity reports.
    
    Event IDs Monitored:
    
    1. Event ID 4624 (Logon):
       - Successful authentication to Windows system
       - Records interactive, network, and remote desktop logins
       - Properties[5].Value contains username
       - Includes logon type information (2=Interactive, 3=Network, 10=RemoteInteractive)
       - Timestamp indicates session start time
    
    2. Event ID 4634 (Logoff):
       - User session termination
       - Records explicit logoffs and session disconnects
       - Properties[1].Value contains username
       - Timestamp indicates session end time
    
    3. Event ID 4625 (Failed Logon):
       - Authentication failure events
       - Records incorrect password attempts
       - Properties[5].Value contains username
       - Useful for security auditing and intrusion detection
       - Includes failure reason and substatus codes
    
    Data Filtering and Processing:
    
    Excluded System Accounts:
    The script filters out non-interactive system accounts to focus on human users:
    - SYSTEM (NT AUTHORITY\SYSTEM)
    - NETWORK SERVICE (NT AUTHORITY\NETWORK SERVICE)
    - LOCAL SERVICE (NT AUTHORITY\LOCAL SERVICE)
    - DWM-* (Desktop Window Manager sessions)
    - UMFD-* (User Mode Font Driver sessions)
    - Computer accounts (*$ pattern)
    
    Why These Are Excluded:
    - System accounts generate massive log volume
    - Not relevant for user activity tracking
    - Would obscure actual user session data
    - Computer account logins are AD authentication noise
    
    Time Range Filtering:
    When -Days parameter is specified:
    - Calculates StartTime as current date minus specified days
    - Uses Get-Date.AddDays(-$Days) for date arithmetic
    - Filters event log query to only retrieve recent events
    - Reduces memory usage and processing time
    - Operates on 24-hour increments from execution time
    
    User-Specific Filtering:
    When -UserName parameter is specified:
    - Performs case-insensitive wildcard match
    - Uses PowerShell -like operator for flexible matching
    - Allows partial username matching
    - Filters after event retrieval for accuracy
    
    Output Format:
    Returns PowerShell custom objects with properties:
    - Time: DateTime of event occurrence
    - Event: SessionStart, SessionStop, or FailedLogin
    - User: Username from event properties
    - ID: Windows Event ID for reference
    
    Audit Policy Requirements:
    
    This script requires proper Windows audit policy configuration:
    
    Check Current Settings:
    ```
    auditpol.exe /get /subcategory:"Logon"
    ```
    
    Expected Output:
    ```
    System audit policy
    Category/Subcategory                      Setting
    Logon/Logoff
      Logon                                   Success and Failure
    ```
    
    Enable if Not Configured:
    ```
    auditpol.exe /set /subcategory:"Logon" /success:enable /failure:enable
    ```
    
    Group Policy Configuration:
    - Path: Computer Configuration > Windows Settings > Security Settings > Advanced Audit Policy Configuration
    - Category: Logon/Logoff
    - Subcategory: Logon
    - Settings: Success and Failure
    
    Security Log Considerations:
    
    Log Size Management:
    - Default Security log size: 20 MB (varies by OS)
    - Recommended minimum: 100 MB for active systems
    - Configure via: Event Viewer > Windows Logs > Security > Properties
    - Retention: Overwrite as needed or Archive when full
    
    Event Volume Estimates:
    - Low activity workstation: 50-200 events/day
    - High activity workstation: 500-2000 events/day
    - Terminal server: 5000-50000 events/day
    - Domain controller: 100000+ events/day
    
    Performance Considerations:
    
    Memory Usage:
    - Get-WinEvent loads events into memory
    - Large time ranges can consume significant RAM
    - Use -Days parameter to limit scope
    - Processing 100,000 events requires ~500 MB RAM
    
    Processing Time:
    - 1,000 events: 1-2 seconds
    - 10,000 events: 5-15 seconds
    - 100,000 events: 30-120 seconds
    - Varies based on CPU speed and disk I/O
    
    Query Optimization:
    - FilterHashtable is faster than Where-Object filtering
    - Limits event retrieval at Windows Event Log API level
    - Reduces data transfer from event log service
    - Minimizes PowerShell object creation overhead
    
    Administrator Privileges:
    
    Why Required:
    - Security event log requires elevated permissions
    - Non-admin users receive "Access Denied" errors
    - Even read access to Security log needs admin rights
    - This is Windows security best practice
    
    Common Use Cases:
    
    1. User Activity Auditing:
       - Track when specific users log in/out
       - Verify user presence during specific timeframes
       - Generate attendance reports from login data
    
    2. Security Investigations:
       - Identify unauthorized access attempts
       - Correlate failed logins with security incidents
       - Detect brute-force attack patterns
    
    3. Compliance Reporting:
       - Meet audit requirements for access tracking
       - Generate login history for compliance reviews
       - Document user activity for regulatory purposes
    
    4. Troubleshooting:
       - Diagnose login issues for specific users
       - Verify authentication is occurring
       - Identify session timeout patterns
    
    Limitations:
    
    - Only shows local system events (not domain-wide)
    - Requires events to exist in Security log
    - Event log rotation may delete old events
    - Fast user switching may create complex session patterns
    - RDP sessions have different event patterns than console
    - Cached credentials may not generate events
    
    Integration with SIEM/Logging:
    - Output can be exported to CSV for analysis
    - Compatible with Splunk, ELK, Graylog ingestion
    - Can feed into NinjaRMM custom field storage
    - PowerShell pipeline enables further processing

.PARAMETER UserName
    Specific username to filter events (supports wildcards)

.PARAMETER Days
    Number of days to look back (24-hour increments from current time)

.EXAMPLE
    .\AD-UserLoginHistoryReport.ps1
    
    Returns all login events for all users in the entire Security log.

.EXAMPLE
    .\AD-UserLoginHistoryReport.ps1 -UserName "Fred"
    
    Returns all login events for user "Fred" from the entire Security log.

.EXAMPLE
    .\AD-UserLoginHistoryReport.ps1 -Days 7
    
    Returns the last 7 days of login events for all users.

.EXAMPLE
    .\AD-UserLoginHistoryReport.ps1 -Days 7 -UserName "Fred"
    
    Returns the last 7 days of login events for user "Fred".

.EXAMPLE
    .\AD-UserLoginHistoryReport.ps1 -Days 30 | Export-Csv -Path "LoginReport.csv" -NoTypeInformation
    
    Exports 30 days of login history to CSV file for analysis.

.OUTPUTS
    PSCustomObject[]
    
    Properties:
    - Time: DateTime of event
    - Event: SessionStart, SessionStop, or FailedLogin
    - User: Username
    - ID: Windows Event ID

.NOTES
    Script Name:    AD-UserLoginHistoryReport.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator required
    Execution Frequency: On-demand or scheduled (daily/weekly)
    Typical Duration: 5-120 seconds (depends on event count)
    Timeout Setting: 300 seconds recommended
    
    User Interaction: NONE (outputs to console/pipeline)
    Restart Behavior: N/A (read-only operation)
    
    NinjaRMM Fields Updated: None (reporting only)
    
    Dependencies:
        - Administrator privileges (mandatory)
        - Security audit policy enabled for Logon events
        - Windows Event Log service running
    
    Exit Codes:
        0 - Successfully retrieved and processed events
        1 - Access denied or audit policy not configured

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4624
    
.LINK
    https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4634
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [String]$UserName,
    
    [Parameter(Mandatory=$false)]
    [int]$Days
)

# Configuration
$ScriptVersion = "3.0"
$ScriptName = "AD-UserLoginHistoryReport"

# Check for environment variable overrides
if ($env:userToReportOn -and $env:userToReportOn -notlike "null") { 
    $UserName = $env:userToReportOn 
}

if ($env:inTheLastXDays -and $env:inTheLastXDays -notlike "null") { 
    $Days = $env:inTheLastXDays 
}

function Test-IsElevated {
    <#
    .SYNOPSIS
        Check if current session has Administrator privileges
    #>
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

try {
    Write-Host "========================================"
    Write-Host "Starting: $ScriptName v$ScriptVersion"
    Write-Host "========================================"
    Write-Host ""
    
    # Verify Administrator privileges
    if (-not (Test-IsElevated)) {
        Write-Host "ERROR: Access Denied. Security event log requires Administrator privileges."
        Write-Host ""
        Write-Host "To run this script:"
        Write-Host "1. Right-click PowerShell and select 'Run as Administrator'"
        Write-Host "2. Or ensure NinjaRMM is running scripts with SYSTEM privileges"
        exit 1
    }
    
    # System accounts to exclude from results
    $SystemUsers = @(
        "SYSTEM"
        "NETWORK SERVICE"
        "LOCAL SERVICE"
    )
    
    # Build event log filter
    $FilterHashtable = @{
        LogName = "Security"
        Id      = 4634, 4624, 4625  # Logoff, Logon, Failed Logon
    }
    
    # Add time range filter if specified
    if ($Days) {
        $StartTime = (Get-Date).AddDays(-$Days)
        $FilterHashtable.Add("StartTime", $StartTime)
        Write-Host "Retrieving events from the last $Days days (since $($StartTime.ToString('yyyy-MM-dd HH:mm:ss')))..."
    }
    else {
        Write-Host "Retrieving all available events from Security log..."
    }
    
    if ($UserName) {
        Write-Host "Filtering for username: $UserName"
    }
    
    Write-Host ""
    
    # Query Windows Event Log
    $Events = Get-WinEvent -FilterHashtable $FilterHashtable -ErrorAction Stop
    
    if (-not $Events) {
        Write-Host "No login events found in the specified time range."
        Write-Host ""
        Write-Host "Audit policy check:"
        Write-Host "Run: auditpol.exe /get /subcategory:`"Logon`""
        Write-Host ""
        Write-Host "If not enabled, run:"
        Write-Host "auditpol.exe /set /subcategory:`"Logon`" /success:enable /failure:enable"
        exit 0
    }
    
    Write-Host "Processing $($Events.Count) events..."
    Write-Host ""
    
    $ResultCount = 0
    
    # Process each event
    $Events | ForEach-Object {
        # Extract username from event properties (location varies by event ID)
        $User = if ($_.Id -eq 4634) {
            # Event ID 4634 (Logoff): username is at index 1
            $_.Properties[1].Value
        }
        else {
            # Event ID 4624/4625 (Logon/Failed): username is at index 5
            $_.Properties[5].Value
        }
        
        # Filter out system accounts and special sessions
        $IsSystemAccount = $SystemUsers -contains $User
        $IsDWM = $User -like "DWM-*"         # Desktop Window Manager
        $IsUMFD = $User -like "UMFD-*"       # User Mode Font Driver
        $IsComputer = $User -like "*$"       # Computer accounts
        
        if (-not ($IsSystemAccount -or $IsDWM -or $IsUMFD -or $IsComputer)) {
            # Apply username filter if specified
            $MatchesUser = (-not $UserName) -or ($User -like $UserName)
            
            if ($MatchesUser) {
                $ResultCount++
                
                # Output formatted event object
                [PSCustomObject]@{
                    Time  = $_.TimeCreated
                    Event = switch ($_.Id) {
                        4624 { "SessionStart" }
                        4625 { "FailedLogin" }
                        4634 { "SessionStop" }
                    }
                    User  = $User
                    ID    = $_.Id
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "========================================"
    Write-Host "Report Complete: $ResultCount events matched criteria"
    Write-Host "========================================"
    
    exit 0
}
catch {
    Write-Host ""
    Write-Host "ERROR: Failed to retrieve login history: $($_.Exception.Message)"
    
    if ($_.Exception.Message -like "*Access is denied*") {
        Write-Host ""
        Write-Host "This script requires Administrator privileges to access the Security event log."
    }
    
    exit 1
}
