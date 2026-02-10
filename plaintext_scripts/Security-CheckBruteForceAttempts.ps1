#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Detects and reports possible brute force login attempts

.DESCRIPTION
    Monitors Windows Security Event Log for failed login attempts (Event ID 4625)
    and identifies potential brute force attacks based on configurable thresholds.
    
    The script performs the following:
    - Validates administrator privileges
    - Checks audit policy configuration for logon events
    - Optionally enables logon auditing if not configured
    - Queries Security Event Log for failed login attempts
    - Filters for relevant logon types (2=Interactive, 7=Unlock, 10=RemoteInteractive)
    - Correlates attempts by account and source IP
    - Identifies accounts exceeding the attempt threshold
    - Reports detailed information about suspicious activity
    - Optionally saves results to NinjaRMM custom fields
    
    This script is useful for:
    - Security monitoring and threat detection
    - Compliance requirements (PCI DSS, HIPAA, etc.)
    - Incident response
    - Forensic analysis
    - Automated alerting
    
    This script runs unattended without user interaction.

.PARAMETER Hours
    Number of hours to look back in the event log.
    Default: 1

.PARAMETER Attempts
    Minimum number of failed login attempts to trigger an alert.
    Default: 8

.PARAMETER EnableAuditing
    Automatically enable logon auditing if not configured.
    Default: $false

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save brute force detection results.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\Security-CheckBruteForceAttempts.ps1
    
    Checks for brute force attempts in the last 1 hour with default threshold of 8 attempts.

.EXAMPLE
    .\Security-CheckBruteForceAttempts.ps1 -Hours 24 -Attempts 5
    
    Checks for brute force attempts in the last 24 hours with threshold of 5 attempts.

.EXAMPLE
    .\Security-CheckBruteForceAttempts.ps1 -EnableAuditing -CustomFieldName "BruteForceStatus"
    
    Enables auditing if needed and saves results to 'BruteForceStatus' custom field.

.OUTPUTS
    None. Brute force detection results are written to console and optionally to custom field.

.NOTES
    Script Name:    Security-CheckBruteForceAttempts.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required)
    Execution Frequency: Scheduled (e.g., every hour or daily)
    Typical Duration: ~5-15 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName (if specified) - Brute force detection results
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Windows 10, Windows Server 2016 or higher
        - Security Event Log access
        - Logon auditing enabled (or -EnableAuditing switch)
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - hours: Alternative to -Hours parameter
        - attempts: Alternative to -Attempts parameter
        - enableAuditing: Alternative to -EnableAuditing switch
        - customFieldName: Alternative to -CustomFieldName parameter
    
    Event IDs:
        - 4625: Failed logon attempt
    
    Logon Types:
        - 2: Interactive (console logon)
        - 7: Unlock (workstation unlock)
        - 10: RemoteInteractive (RDP/Terminal Services)
    
    Exit Codes:
        0 - Success (no brute force detected)
        1 - Alert (possible brute force detected) or Error

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4625
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Hours to look back in event log")]
    [ValidateRange(1,168)]
    [int]$Hours = 1,
    
    [Parameter(Mandatory=$false, HelpMessage="Minimum failed attempts to trigger alert")]
    [ValidateRange(1,1000)]
    [int]$Attempts = 8,
    
    [Parameter(Mandatory=$false, HelpMessage="Enable logon auditing if not configured")]
    [switch]$EnableAuditing,
    
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save results")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Security-CheckBruteForceAttempts"

# Support NinjaRMM environment variables
if ($env:hours -and $env:hours -notlike "null") {
    $Hours = [int]$env:hours
}

if ($env:attempts -and $env:attempts -notlike "null") {
    $Attempts = [int]$env:attempts
}

if ($env:enableAuditing -and $env:enableAuditing -notlike "null") {
    $EnableAuditing = [bool]::Parse($env:enableAuditing)
}

if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

# Trim whitespace from parameters
if ($CustomFieldName) { $CustomFieldName = $CustomFieldName.Trim() }

# Event configuration
$EventId = 4625  # Failed logon
$RelevantLogonTypes = @(2, 7, 10)  # Interactive, Unlock, RemoteInteractive

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
    
    # Truncate if exceeds NinjaRMM field limit (10,000 characters)
    if ($ValueString.Length -gt 10000) {
        Write-Log "Field value exceeds 10,000 characters, truncating" -Level WARN
        $ValueString = $ValueString.Substring(0, 9950) + "`n... (truncated)"
    }
    
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
        Checks if script is running with administrator privileges
    #>
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-LogonAuditPolicy {
    <#
    .SYNOPSIS
        Checks if logon auditing is properly configured
    #>
    try {
        $AuditPolicy = & auditpol.exe /get /category:* 2>&1
        $LogonPolicy = $AuditPolicy | Where-Object { $_ -like "*Logon*Success and Failure" }
        
        return ($null -ne $LogonPolicy)
    } catch {
        Write-Log "Failed to check audit policy: $_" -Level WARN
        return $false
    }
}

function Enable-LogonAuditing {
    <#
    .SYNOPSIS
        Enables logon auditing
    #>
    try {
        Write-Log "Enabling logon auditing..." -Level INFO
        & auditpol.exe /set /subcategory:"Logon" /success:enable /failure:enable
        Write-Log "Logon auditing enabled successfully" -Level SUCCESS
        Write-Log "Future failed login attempts will be captured" -Level INFO
        return $true
    } catch {
        Write-Log "Failed to enable logon auditing: $_" -Level ERROR
        return $false
    }
}

function Get-LocalUserAccounts {
    <#
    .SYNOPSIS
        Retrieves list of local user accounts
    #>
    $Accounts = New-Object System.Collections.Generic.List[String]
    
    try {
        Get-LocalUser -ErrorAction Stop | 
            Select-Object -ExpandProperty Name | 
            ForEach-Object { $Accounts.Add($_) }
    } catch {
        Write-Log "Fallback to net.exe for user list" -Level DEBUG
        
        $NetUser = net.exe user 2>&1
        $($NetUser | Select-Object -Skip 4 | Select-Object -SkipLast 2) -join ',' -replace '\s+', ',' -split ',' |
            Sort-Object -Unique |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { $Accounts.Add($_) }
    }
    
    return $Accounts
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for administrator privileges
    if (-not (Test-IsElevated)) {
        Write-Log "ERROR: This script requires administrator privileges" -Level ERROR
        throw "Access Denied"
    }
    
    Write-Log "Checking for brute force login attempts" -Level INFO
    Write-Log "  Time Window: Last $Hours hour(s)" -Level INFO
    Write-Log "  Alert Threshold: $Attempts failed attempts" -Level INFO
    Write-Log "" -Level INFO
    
    # Check audit policy
    if (Test-LogonAuditPolicy) {
        Write-Log "Logon auditing is properly configured" -Level SUCCESS
    } else {
        Write-Log "Logon auditing is NOT configured" -Level WARN
        
        if ($EnableAuditing) {
            if (-not (Enable-LogonAuditing)) {
                throw "Failed to enable logon auditing"
            }
        } else {
            Write-Log "Auditing not enabled - use -EnableAuditing switch to enable" -Level WARN
            throw "Logon auditing required"
        }
    }
    
    # Calculate start time for event log query
    $QueryStartTime = (Get-Date).AddHours(0 - $Hours)
    Write-Log "Querying events from: $($QueryStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Level INFO
    
    # Query Security Event Log for failed login attempts
    try {
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = "Security"
            ID = $EventId
            StartTime = $QueryStartTime
        } -ErrorAction Stop | ForEach-Object {
            $Message = $_.Message -split [System.Environment]::NewLine
            $Account = ($Message | Where-Object { $_ -Like "*Account Name:*" }) -split '\s+' | Select-Object -Last 1
            [int]$LogonType = ($Message | Where-Object { $_ -Like "Logon Type:*" }) -split '\s+' | Select-Object -Last 1
            $SourceIP = ($Message | Where-Object { $_ -Like "*Source Network Address:*" }) -split '\s+' | Select-Object -Last 1
            
            [PSCustomObject]@{
                TimeCreated = $_.TimeCreated
                Account = $Account
                LogonType = $LogonType
                SourceIP = $SourceIP
            }
        } | Where-Object { $_.LogonType -in $RelevantLogonTypes }
        
        Write-Log "Found $(@($Events).Count) relevant failed login events" -Level INFO
        
    } catch {
        if ($_.Exception.Message -like "*No events were found*") {
            Write-Log "No failed login attempts found in the last $Hours hour(s)" -Level SUCCESS
            
            if ($CustomFieldName) {
                Set-NinjaField -FieldName $CustomFieldName -Value "No failed login attempts detected in last $Hours hour(s)"
            }
            
            # No brute force detected - exit 0
            return
        } else {
            throw $_
        }
    }
    
    # Get local user accounts
    $UserAccounts = Get-LocalUserAccounts
    Write-Log "Found $($UserAccounts.Count) local user accounts" -Level DEBUG
    
    # Add accounts from failed login events
    $Events | Select-Object -ExpandProperty Account | ForEach-Object { $UserAccounts.Add($_) }
    
    # Analyze failed login attempts by account
    $Results = $UserAccounts | Select-Object -Unique | ForEach-Object {
        $Account = $_
        $AccountEvents = $Events | Where-Object { $_.Account -like $Account }
        $AttemptCount = $AccountEvents.Count
        
        if ($AttemptCount -gt 0) {
            $SourceIPs = $AccountEvents | Select-Object -ExpandProperty SourceIP -Unique
            $FirstAttempt = ($AccountEvents | Select-Object -ExpandProperty TimeCreated | Measure-Object -Minimum).Minimum
            $LastAttempt = ($AccountEvents | Select-Object -ExpandProperty TimeCreated | Measure-Object -Maximum).Maximum
            
            [PSCustomObject]@{
                Account = $Account
                Attempts = $AttemptCount
                SourceIPs = $SourceIPs -join ', '
                FirstAttempt = $FirstAttempt
                LastAttempt = $LastAttempt
            }
        }
    } | Sort-Object -Property Attempts -Descending
    
    # Identify accounts exceeding threshold
    $BruteForceAttempts = $Results | Where-Object { $_.Attempts -ge $Attempts }
    
    if ($BruteForceAttempts) {
        Write-Log "" -Level INFO
        Write-Log "ALERT: Possible brute force attempts detected!" -Level ERROR
        Write-Log "" -Level INFO
        
        # Build report
        $Report = New-Object System.Collections.Generic.List[String]
        $Report.Add("BRUTE FORCE ALERT - $($BruteForceAttempts.Count) account(s) exceeded threshold")
        $Report.Add("")
        $Report.Add("Threshold: $Attempts attempts in $Hours hour(s)")
        $Report.Add("")
        
        foreach ($Attempt in $BruteForceAttempts) {
            Write-Log "Account: $($Attempt.Account)" -Level WARN
            Write-Log "  Failed Attempts: $($Attempt.Attempts)" -Level WARN
            Write-Log "  Source IPs: $($Attempt.SourceIPs)" -Level WARN
            Write-Log "  First Attempt: $($Attempt.FirstAttempt)" -Level WARN
            Write-Log "  Last Attempt: $($Attempt.LastAttempt)" -Level WARN
            Write-Log "" -Level INFO
            
            $Report.Add("Account: $($Attempt.Account)")
            $Report.Add("  Failed Attempts: $($Attempt.Attempts)")
            $Report.Add("  Source IPs: $($Attempt.SourceIPs)")
            $Report.Add("  First Attempt: $($Attempt.FirstAttempt.ToString('yyyy-MM-dd HH:mm:ss'))")
            $Report.Add("  Last Attempt: $($Attempt.LastAttempt.ToString('yyyy-MM-dd HH:mm:ss'))")
            $Report.Add("")
        }
        
        if ($CustomFieldName) {
            $FormattedReport = $Report -join "`n"
            Set-NinjaField -FieldName $CustomFieldName -Value $FormattedReport
            Write-Log "Alert saved to custom field '$CustomFieldName'" -Level INFO
        }
        
        # Set exit code to 1 to indicate alert condition
        $script:ExitCode = 1
        
    } else {
        Write-Log "No brute force attempts detected" -Level SUCCESS
        Write-Log "" -Level INFO
        Write-Log "Failed login summary:" -Level INFO
        
        foreach ($Result in $Results) {
            Write-Log "  $($Result.Account): $($Result.Attempts) attempt(s) from $($Result.SourceIPs)" -Level INFO
        }
        
        if ($CustomFieldName) {
            $Summary = "No brute force detected. Total failed logins: $($Results.Count) accounts with $(@($Events).Count) total attempts in last $Hours hour(s)"
            Set-NinjaField -FieldName $CustomFieldName -Value $Summary
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
