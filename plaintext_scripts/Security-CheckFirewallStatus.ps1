#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Checks Windows Firewall status and configuration for all network profiles

.DESCRIPTION
    Examines the complete status of Windows Defender Firewall across all three network 
    profiles (Domain, Private, Public) and provides detailed analysis including:
    
    The script performs the following:
    - Validates administrator privileges
    - Checks firewall enabled/disabled status for each profile
    - Reports default inbound and outbound actions
    - Counts active firewall rules per profile
    - Identifies disabled profiles for security alerts
    - Provides detailed configuration information
    - Optionally saves comprehensive report to custom fields
    - Alerts on security compliance issues
    
    This is critical for:
    - Security compliance (PCI DSS, HIPAA, CIS Benchmarks)
    - Protecting systems from unauthorized network access
    - Audit and vulnerability assessments
    - Security posture monitoring
    - Incident response validation
    
    This script runs unattended without user interaction.

.PARAMETER AlertOnDisabled
    Exit with error code (1) if any firewall profile is disabled.
    Useful for automated monitoring and alerting.
    Default: $false

.PARAMETER IncludeRuleCount
    Include count of active firewall rules in the report.
    Default: $true

.PARAMETER CustomFieldName
    Optional name of NinjaRMM custom field to save firewall status report.
    Must be a valid custom field name (max 200 characters).

.EXAMPLE
    .\Security-CheckFirewallStatus.ps1
    
    Checks firewall status for all profiles and reports configuration.

.EXAMPLE
    .\Security-CheckFirewallStatus.ps1 -AlertOnDisabled
    
    Checks firewall and exits with error if any profile is disabled.

.EXAMPLE
    .\Security-CheckFirewallStatus.ps1 -AlertOnDisabled -CustomFieldName "FirewallStatus"
    
    Checks firewall, alerts on issues, and saves report to custom field.

.EXAMPLE
    .\Security-CheckFirewallStatus.ps1 -IncludeRuleCount:$false
    
    Checks firewall status without counting rules (faster execution).

.OUTPUTS
    None. Firewall status is written to console and optionally to custom field.

.NOTES
    Script Name:    Security-CheckFirewallStatus.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-10
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required)
    Execution Frequency: Scheduled (e.g., daily or on-demand)
    Typical Duration: ~2-5 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName (if specified) - Firewall status report
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Windows 10, Windows Server 2016 or higher
        - NetSecurity module (built-in)
        - NinjaRMM Agent (if using custom fields)
    
    Environment Variables (Optional):
        - alertOnDisabled: Alternative to -AlertOnDisabled parameter
        - includeRuleCount: Alternative to -IncludeRuleCount parameter
        - customFieldName: Alternative to -CustomFieldName parameter
    
    Firewall Profiles:
        - Domain: Network is connected to a domain controller
        - Private: Network is marked as private (home/work)
        - Public: Network is marked as public (airports, cafes)
    
    Exit Codes:
        0 - Success (firewall properly configured) or no alert requested
        1 - Alert (firewall disabled on one or more profiles) or Error

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/netsecurity/get-netfirewallprofile
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Alert if any profile has firewall disabled")]
    [switch]$AlertOnDisabled,
    
    [Parameter(Mandatory=$false, HelpMessage="Include firewall rule count in report")]
    [switch]$IncludeRuleCount = $true,
    
    [Parameter(Mandatory=$false, HelpMessage="Name of custom field to save results")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [string]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "Security-CheckFirewallStatus"

# Support NinjaRMM environment variables
if ($env:alertOnDisabled -eq "true") {
    $AlertOnDisabled = $true
}

if ($env:includeRuleCount -and $env:includeRuleCount -notlike "null") {
    $IncludeRuleCount = [bool]::Parse($env:includeRuleCount)
}

if ($env:customFieldName -and $env:customFieldName -notlike "null") {
    $CustomFieldName = $env:customFieldName
}

# Trim whitespace from parameters
if ($CustomFieldName) { $CustomFieldName = $CustomFieldName.Trim() }

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

function Get-FirewallRuleCount {
    <#
    .SYNOPSIS
        Gets count of enabled firewall rules for a specific profile
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName
    )
    
    try {
        $Rules = Get-NetFirewallRule -PolicyStore ActiveStore -Enabled True -ErrorAction Stop |
            Where-Object { $_.Profile -match $ProfileName }
        
        return $Rules.Count
    } catch {
        Write-Log "Failed to count rules for $ProfileName profile" -Level DEBUG
        return $null
    }
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
    
    Write-Log "Checking Windows Firewall status for all profiles" -Level INFO
    Write-Log "" -Level INFO
    
    # Get all firewall profiles
    $FirewallProfiles = Get-NetFirewallProfile -ErrorAction Stop
    
    # Initialize collections
    $Report = New-Object System.Collections.Generic.List[String]
    $DisabledProfiles = New-Object System.Collections.Generic.List[String]
    $ProfileDetails = New-Object System.Collections.Generic.List[PSCustomObject]
    
    $Report.Add("WINDOWS FIREWALL STATUS REPORT")
    $Report.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $Report.Add("")
    
    # Analyze each profile
    foreach ($Profile in $FirewallProfiles) {
        $ProfileName = $Profile.Name
        $IsEnabled = $Profile.Enabled
        $Status = if ($IsEnabled) { "Enabled" } else { "Disabled" }
        
        Write-Log "Profile: $ProfileName" -Level INFO
        Write-Log "  Status: $Status" -Level $(if ($IsEnabled) { 'SUCCESS' } else { 'ERROR' })
        Write-Log "  Default Inbound Action: $($Profile.DefaultInboundAction)" -Level INFO
        Write-Log "  Default Outbound Action: $($Profile.DefaultOutboundAction)" -Level INFO
        
        # Get rule count if requested
        $RuleCount = $null
        if ($IncludeRuleCount) {
            $RuleCount = Get-FirewallRuleCount -ProfileName $ProfileName
            if ($null -ne $RuleCount) {
                Write-Log "  Active Rules: $RuleCount" -Level INFO
            }
        }
        
        Write-Log "" -Level INFO
        
        # Build report
        $Report.Add("$ProfileName Profile:")
        $Report.Add("  Status: $Status")
        $Report.Add("  Inbound: $($Profile.DefaultInboundAction)")
        $Report.Add("  Outbound: $($Profile.DefaultOutboundAction)")
        if ($null -ne $RuleCount) {
            $Report.Add("  Active Rules: $RuleCount")
        }
        $Report.Add("")
        
        # Track disabled profiles
        if (-not $IsEnabled) {
            $DisabledProfiles.Add($ProfileName)
        }
        
        # Store details for summary
        $ProfileDetails.Add([PSCustomObject]@{
            Name = $ProfileName
            Enabled = $IsEnabled
            InboundAction = $Profile.DefaultInboundAction
            OutboundAction = $Profile.DefaultOutboundAction
            RuleCount = $RuleCount
        })
    }
    
    # Analyze results
    $TotalProfiles = $ProfileDetails.Count
    $EnabledProfiles = ($ProfileDetails | Where-Object { $_.Enabled }).Count
    $DisabledCount = $DisabledProfiles.Count
    
    Write-Log "========================================" -Level INFO
    Write-Log "SUMMARY" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "Total Profiles: $TotalProfiles" -Level INFO
    Write-Log "Enabled: $EnabledProfiles" -Level INFO
    Write-Log "Disabled: $DisabledCount" -Level INFO
    Write-Log "" -Level INFO
    
    # Generate alerts if needed
    if ($DisabledCount -gt 0) {
        Write-Log "ALERT: Windows Firewall is disabled on $DisabledCount profile(s)" -Level ERROR
        
        foreach ($ProfileName in $DisabledProfiles) {
            Write-Log "  - $ProfileName profile has firewall DISABLED" -Level ERROR
        }
        
        Write-Log "" -Level INFO
        Write-Log "SECURITY RISK: Disabled firewall profiles expose the system to threats" -Level WARN
        Write-Log "RECOMMENDATION: Enable firewall on all profiles immediately" -Level WARN
        
        $Report.Add("ALERT: $DisabledCount profile(s) have firewall DISABLED")
        $Report.Add("Disabled Profiles: $($DisabledProfiles -join ', ')")
        $Report.Add("")
        $Report.Add("SECURITY RISK: System exposed to network threats")
        $Report.Add("ACTION REQUIRED: Enable firewall on all profiles")
        
        # Set exit code if alerting enabled
        if ($AlertOnDisabled) {
            $script:ExitCode = 1
        }
        
    } else {
        Write-Log "SUCCESS: Windows Firewall is enabled on all profiles" -Level SUCCESS
        Write-Log "All network profiles are properly protected" -Level INFO
        
        $Report.Add("STATUS: All profiles have firewall ENABLED")
        $Report.Add("Security posture: COMPLIANT")
    }
    
    # Save to custom field if specified
    if ($CustomFieldName) {
        $FormattedReport = $Report -join "`n"
        Set-NinjaField -FieldName $CustomFieldName -Value $FormattedReport
        Write-Log "Report saved to custom field '$CustomFieldName'" -Level INFO
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
