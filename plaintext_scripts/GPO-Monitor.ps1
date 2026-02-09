#Requires -Version 5.1

<#
.SYNOPSIS
    Monitors Group Policy application status and detects errors

.DESCRIPTION
    Comprehensive Group Policy monitoring script that tracks applied GPOs, detects
    processing errors, and generates detailed reports. Parses gpresult XML output
    to provide complete visibility into Group Policy deployment.
    
    The script performs the following:
    - Checks domain membership status
    - Generates Group Policy report using gpresult
    - Parses applied computer GPOs from XML
    - Checks event logs for Group Policy errors (last 24 hours)
    - Falls back to registry checks if gpresult fails
    - Generates HTML formatted table of applied GPOs
    - Reports comprehensive status to NinjaRMM
    
    Gracefully handles non-domain computers by reporting appropriate status.
    This script runs unattended without user interaction.

.PARAMETER MaxErrors
    Maximum number of event log errors to check.
    Default: 10

.PARAMETER ErrorWindowHours
    Hours to look back for Group Policy errors in event log.
    Default: 24

.EXAMPLE
    .\GPO-Monitor.ps1
    
    Monitors GPO status with default settings.

.EXAMPLE
    .\GPO-Monitor.ps1 -ErrorWindowHours 48
    
    Checks for errors in last 48 hours.

.NOTES
    Script Name:    GPO-Monitor.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily
    Typical Duration: ~5-30 seconds
    Timeout Setting: 120 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - gpoApplied - Boolean status (true/false)
        - gpoLastApplied - Unix Epoch timestamp of last application
        - gpoCount - Number of applied computer GPOs
        - gpoErrorsPresent - Boolean error status (true/false)
        - gpoLastError - Last error message (max 500 chars)
        - gpoAppliedList - HTML formatted table of applied GPOs
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - gpresult.exe (Windows built-in)
        - Domain-joined computer for full functionality
        - Event log access
        - Windows 10 or Server 2016 minimum
    
    Environment Variables (Optional):
        - maxErrors: Override -MaxErrors parameter
        - errorWindowHours: Override -ErrorWindowHours parameter
    
    Exit Codes:
        0 - Success (monitoring completed)
        1 - Failure (script error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Maximum event log errors to check")]
    [int]$MaxErrors = 10,
    
    [Parameter(Mandatory=$false, HelpMessage="Hours to look back for errors")]
    [ValidateRange(1, 168)]
    [int]$ErrorWindowHours = 24
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "GPO-Monitor"

# Temporary report path
$ReportPath = "$env:TEMP\gpresult_$(Get-Date -Format 'yyyyMMddHHmmss').xml"

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

function Get-GPOReport {
    <#
    .SYNOPSIS
        Generates Group Policy report using gpresult
    #>
    try {
        Write-Log "Generating Group Policy report" -Level INFO
        
        # Run gpresult
        $GPResultProcess = Start-Process -FilePath "gpresult.exe" -ArgumentList "/f", "/x", $ReportPath -Wait -NoNewWindow -PassThru
        
        if ($GPResultProcess.ExitCode -ne 0) {
            throw "gpresult failed with exit code $($GPResultProcess.ExitCode)"
        }
        
        if (-not (Test-Path $ReportPath)) {
            throw "Group Policy report file not created"
        }
        
        # Parse XML
        [xml]$Report = Get-Content $ReportPath
        Write-Log "Group Policy report generated successfully" -Level SUCCESS
        
        return $Report
        
    } catch {
        Write-Log "Failed to generate Group Policy report: $_" -Level ERROR
        return $null
    } finally {
        # Clean up report file
        if (Test-Path $ReportPath) {
            Remove-Item $ReportPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-GPOErrors {
    <#
    .SYNOPSIS
        Retrieves Group Policy errors from event log
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Hours,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxEvents
    )
    
    try {
        Write-Log "Checking for Group Policy errors (last $Hours hours)" -Level DEBUG
        
        $StartTime = (Get-Date).AddHours(-$Hours)
        
        $Errors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-GroupPolicy'
            Level = 1,2  # Error and Critical
            StartTime = $StartTime
        } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue
        
        if ($Errors) {
            Write-Log "Found $($Errors.Count) Group Policy error(s)" -Level WARN
            return $Errors
        } else {
            Write-Log "No Group Policy errors detected" -Level SUCCESS
            return $null
        }
        
    } catch {
        Write-Log "Failed to query event log for GPO errors: $_" -Level WARN
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
    
    # Check for environment variable overrides
    if ($env:maxErrors -and $env:maxErrors -notlike "null") {
        $MaxErrors = [int]$env:maxErrors
        Write-Log "MaxErrors from environment: $MaxErrors" -Level INFO
    }
    
    if ($env:errorWindowHours -and $env:errorWindowHours -notlike "null") {
        $ErrorWindowHours = [int]$env:errorWindowHours
        Write-Log "ErrorWindowHours from environment: $ErrorWindowHours" -Level INFO
    }
    
    # Check domain membership
    Write-Log "Checking domain membership" -Level INFO
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    
    if (-not $ComputerSystem.PartOfDomain) {
        Write-Log "Computer is not domain-joined" -Level INFO
        
        Set-NinjaField -FieldName "gpoApplied" -Value "false"
        Set-NinjaField -FieldName "gpoLastApplied" -Value 0
        Set-NinjaField -FieldName "gpoCount" -Value 0
        Set-NinjaField -FieldName "gpoErrorsPresent" -Value "false"
        Set-NinjaField -FieldName "gpoLastError" -Value "Not domain-joined"
        Set-NinjaField -FieldName "gpoAppliedList" -Value "Computer is not domain-joined"
        
        Write-Log "Group Policy monitoring not applicable for workgroup computer" -Level SUCCESS
        exit 0
    }
    
    Write-Log "Computer is domain-joined: $($ComputerSystem.Domain)" -Level INFO
    
    # Initialize status variables
    $GPOApplied = "false"
    $LastApplied = 0
    $GPOCount = 0
    $ErrorsPresent = "false"
    $LastError = "None"
    $AppliedList = ""
    
    # Generate and parse GPO report
    $GPOReport = Get-GPOReport
    
    if ($GPOReport) {
        # Extract computer GPOs
        $ComputerGPOs = $GPOReport.Rsop.ComputerResults.GPO
        
        if ($ComputerGPOs) {
            $GPOApplied = "true"
            $GPOCount = @($ComputerGPOs).Count
            Write-Log "Found $GPOCount applied GPO(s)" -Level SUCCESS
            
            # Get last applied time
            $ReadTime = $GPOReport.Rsop.ReadTime
            if ($ReadTime) {
                $LastAppliedDate = [DateTime]::Parse($ReadTime)
                $LastApplied = [DateTimeOffset]$LastAppliedDate | Select-Object -ExpandProperty ToUnixTimeSeconds
                Write-Log "Last applied: $($LastAppliedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Level INFO
            }
            
            # Build HTML table
            $HTMLRows = foreach ($GPO in $ComputerGPOs) {
                $GPOName = $GPO.Name
                $GPOPath = $GPO.Path.Identifier.'#text'
                "<tr><td>$GPOName</td><td style='font-size:0.85em;color:#666'>$GPOPath</td></tr>"
            }
            
            $AppliedList = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>GPO Name</th><th>Path</th></tr>
$($HTMLRows -join "`n")
</table>
<p style='font-size:0.9em; color:#666; margin-top:10px;'>Total: $GPOCount GPO(s) applied</p>
"@
        } else {
            Write-Log "No computer GPOs found in report" -Level WARN
            $AppliedList = "No Group Policies applied to this computer"
        }
    } else {
        # Fallback to registry if gpresult failed
        Write-Log "Attempting registry fallback for GP status" -Level WARN
        
        try {
            $GPORegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine"
            
            if (Test-Path $GPORegPath) {
                $GPOState = Get-ItemProperty -Path $GPORegPath
                
                if ($GPOState.LastGPOProcessingTime) {
                    $LastAppliedDate = [DateTime]::Parse($GPOState.LastGPOProcessingTime)
                    $LastApplied = [DateTimeOffset]$LastAppliedDate | Select-Object -ExpandProperty ToUnixTimeSeconds
                    $GPOApplied = "true"
                    Write-Log "Last applied (from registry): $($LastAppliedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Level INFO
                }
            }
            
            $AppliedList = "Unable to retrieve detailed GPO list (gpresult failed, registry used)"
            $LastError = "GPO report generation failed"
            $ErrorsPresent = "true"
            
        } catch {
            Write-Log "Registry fallback failed: $_" -Level ERROR
            $AppliedList = "Unable to retrieve GPO status"
            $LastError = "Both gpresult and registry checks failed"
            $ErrorsPresent = "true"
        }
    }
    
    # Check for Group Policy errors
    $GPOErrors = Get-GPOErrors -Hours $ErrorWindowHours -MaxEvents $MaxErrors
    
    if ($GPOErrors) {
        $ErrorsPresent = "true"
        $LastError = $GPOErrors[0].Message
        
        # Truncate if too long
        if ($LastError.Length -gt 500) {
            $LastError = $LastError.Substring(0, 497) + "..."
        }
        
        Write-Log "Group Policy errors detected: $($GPOErrors.Count)" -Level WARN
    }
    
    # Update NinjaRMM fields
    Write-Log "Updating NinjaRMM custom fields" -Level INFO
    
    Set-NinjaField -FieldName "gpoApplied" -Value $GPOApplied
    Set-NinjaField -FieldName "gpoLastApplied" -Value $LastApplied
    Set-NinjaField -FieldName "gpoCount" -Value $GPOCount
    Set-NinjaField -FieldName "gpoErrorsPresent" -Value $ErrorsPresent
    Set-NinjaField -FieldName "gpoLastError" -Value $LastError
    Set-NinjaField -FieldName "gpoAppliedList" -Value $AppliedList
    
    Write-Log "Group Policy monitoring completed: $GPOCount GPO(s), Errors: $ErrorsPresent" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "gpoApplied" -Value "false"
    Set-NinjaField -FieldName "gpoLastApplied" -Value 0
    Set-NinjaField -FieldName "gpoErrorsPresent" -Value "true"
    Set-NinjaField -FieldName "gpoLastError" -Value "Monitor script error: $($_.Exception.Message)"
    Set-NinjaField -FieldName "gpoAppliedList" -Value "Script execution failed"
    
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

if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
