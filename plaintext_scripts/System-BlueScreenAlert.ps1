#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Detects Blue Screen of Death (BSOD) events and analyzes crash dumps

.DESCRIPTION
    Monitors system for BSOD events by checking for minidump files and unexpected
    shutdown events in the Windows event log. Uses BlueScreenView from NirSoft to
    parse minidump files and extract detailed crash information.
    
    The script performs the following:
    - Checks for administrator privileges
    - Queries event log for unexpected shutdown events (Event ID 6008)
    - Scans C:\Windows\Minidump for crash dump files
    - Downloads and runs BlueScreenView to parse dumps
    - Extracts crash details (timestamp, reason, error code, driver)
    - Reports findings to NinjaRMM custom fields
    - Cleans up downloaded tools automatically
    
    Unexpected shutdowns (Event ID 6008) can indicate various issues including
    power failures, forced shutdowns, or blue screens. This script provides
    visibility into system stability issues.
    
    This script runs unattended without user interaction.

.PARAMETER MaxDumpsToAnalyze
    Maximum number of dump files to analyze. Newer dumps are prioritized.
    Default: 10

.PARAMETER AnalyzeOlderThanDays
    Only analyze dumps newer than this many days.
    Default: 30 (last 30 days)

.EXAMPLE
    .\System-BlueScreenAlert.ps1
    
    Checks for BSOD dumps in last 30 days, analyzes up to 10 dumps.

.EXAMPLE
    .\System-BlueScreenAlert.ps1 -AnalyzeOlderThanDays 7 -MaxDumpsToAnalyze 5
    
    Analyzes BSOD dumps from last 7 days only, maximum 5 dumps.

.OUTPUTS
    None. BSOD analysis results are written to console and NinjaRMM custom fields.

.NOTES
    Script Name:    System-BlueScreenAlert.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: Administrator (required)
    Execution Frequency: Daily or on-demand
    Typical Duration: 10-30 seconds (depends on network and dump count)
    Timeout Setting: 120 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - bsodDetected - Boolean status (true/false)
        - bsodCount - Number of minidumps found
        - bsodLastDate - Unix Epoch timestamp of most recent dump
        - bsodUnexpectedShutdowns - Count of Event ID 6008 occurrences
        - bsodDetails - WYSIWYG formatted report of crashes
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - Internet access to download BlueScreenView
        - Windows 10, Windows Server 2016 or higher
        - Event log access
        - Write access to %TEMP%
        - NinjaRMM Agent (if using custom fields)
    
    External Tools:
        - BlueScreenView by NirSoft (https://www.nirsoft.net/utils/blue_screen_view.html)
        - Downloaded automatically during execution
        - Version: Latest from nirsoft.net
    
    System Configuration Requirements:
        System Properties > Startup and Recovery:
        - "Write an event to the system log" - ENABLED
        - "Write debugging information" - Automatic memory dump
    
    Environment Variables (Optional):
        - maxDumpsToAnalyze: Override -MaxDumpsToAnalyze parameter
        - analyzeOlderThanDays: Override -AnalyzeOlderThanDays parameter
    
    Exit Codes:
        0 - Success (no BSOD detected or analysis complete)
        1 - BSOD detected (minidumps found and analyzed)
        2 - Tool download/execution failure

.LINK
    https://github.com/Xore/waf

.LINK
    https://www.nirsoft.net/utils/blue_screen_view.html
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Maximum number of dumps to analyze")]
    [ValidateRange(1, 50)]
    [int]$MaxDumpsToAnalyze = 10,
    
    [Parameter(Mandatory=$false, HelpMessage="Only analyze dumps newer than this many days")]
    [ValidateRange(1, 365)]
    [int]$AnalyzeOlderThanDays = 30
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0.0"
$ScriptName = "System-BlueScreenAlert"

# BlueScreenView configuration
$BlueScreenViewZip = "bluescreenview.zip"
$BlueScreenViewExe = "BlueScreenView.exe"
$BlueScreenViewUrl = "https://www.nirsoft.net/utils/$BlueScreenViewZip"
$CsvFileName = "bluescreenview-export.csv"

# Build paths
$TempDir = $env:TEMP
$ZipPath = Join-Path -Path $TempDir -ChildPath $BlueScreenViewZip
$ExePath = Join-Path -Path $TempDir -ChildPath $BlueScreenViewExe
$CsvPath = Join-Path -Path $TempDir -ChildPath $CsvFileName

# Minidump location
$MinidumpPath = "C:\Windows\Minidump"

# CSV headers for BlueScreenView export
$CsvHeaders = @(
    "Dumpfile",
    "Timestamp",
    "Reason",
    "Errorcode",
    "Parameter1",
    "Parameter2",
    "Parameter3",
    "Parameter4",
    "CausedByDriver"
)

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
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Remove-DownloadedFiles {
    <#
    .SYNOPSIS
        Cleans up downloaded BlueScreenView files
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Paths
    )
    
    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            try {
                Remove-Item -Path $Path -Force -ErrorAction Stop
                Write-Log "Removed: $Path" -Level DEBUG
            } catch {
                Write-Log "Failed to remove $Path: $_" -Level WARN
            }
        }
    }
}

function Get-UnexpectedShutdownEvents {
    <#
    .SYNOPSIS
        Retrieves unexpected shutdown events from System log
    #>
    try {
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ID = 6008
        } -ErrorAction Stop
        
        Write-Log "Found $($Events.Count) unexpected shutdown event(s)" -Level INFO
        return $Events
        
    } catch {
        Write-Log "No unexpected shutdown events found or error querying event log" -Level DEBUG
        return $null
    }
}

function Get-MinidumpFiles {
    <#
    .SYNOPSIS
        Retrieves minidump files from Windows directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [int]$DaysOld
    )
    
    try {
        if (-not (Test-Path $Path)) {
            Write-Log "Minidump directory does not exist: $Path" -Level DEBUG
            return $null
        }
        
        $CutoffDate = (Get-Date).AddDays(-$DaysOld)
        
        $DumpFiles = Get-ChildItem -Path $Path -Filter "*.dmp" -ErrorAction Stop |
            Where-Object { $_.LastWriteTime -gt $CutoffDate } |
            Sort-Object LastWriteTime -Descending
        
        if ($DumpFiles) {
            Write-Log "Found $($DumpFiles.Count) minidump file(s) in last $DaysOld days" -Level INFO
            return $DumpFiles
        } else {
            Write-Log "No minidump files found in last $DaysOld days" -Level INFO
            return $null
        }
        
    } catch {
        Write-Log "Failed to scan for minidump files: $_" -Level ERROR
        return $null
    }
}

function Invoke-BlueScreenViewAnalysis {
    <#
    .SYNOPSIS
        Downloads BlueScreenView, runs analysis, and parses results
    #>
    try {
        Write-Log "Downloading BlueScreenView from NirSoft" -Level INFO
        Invoke-WebRequest -Uri $BlueScreenViewUrl -OutFile $ZipPath -UseBasicParsing -ErrorAction Stop
        Write-Log "Download complete" -Level SUCCESS
        
        Write-Log "Extracting BlueScreenView" -Level DEBUG
        Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force -ErrorAction Stop
        
        if (-not (Test-Path $ExePath)) {
            throw "BlueScreenView.exe not found after extraction"
        }
        
        Write-Log "Running BlueScreenView analysis" -Level INFO
        $ProcessArgs = "/scomma `"$CsvPath`""
        $Process = Start-Process -FilePath $ExePath -ArgumentList $ProcessArgs -Wait -PassThru -NoNewWindow -ErrorAction Stop
        
        if ($Process.ExitCode -ne 0) {
            throw "BlueScreenView exited with code $($Process.ExitCode)"
        }
        
        if (-not (Test-Path $CsvPath)) {
            throw "BlueScreenView did not generate output CSV"
        }
        
        Write-Log "BlueScreenView analysis complete" -Level SUCCESS
        
        # Parse CSV results
        $CsvContent = Get-Content -Path $CsvPath -ErrorAction Stop
        
        if (-not $CsvContent) {
            Write-Log "CSV file is empty - no crash data" -Level WARN
            return $null
        }
        
        $MiniDumps = $CsvContent |
            ConvertFrom-Csv -Delimiter ',' -Header $CsvHeaders |
            Select-Object -Property @{
                Name = "Timestamp"
                Expression = { 
                    try {
                        [DateTime]::Parse($_.Timestamp, [System.Globalization.CultureInfo]::CurrentCulture)
                    } catch {
                        $null
                    }
                }
            }, DumpFile, Reason, ErrorCode, CausedByDriver
        
        Write-Log "Parsed $($MiniDumps.Count) crash dump record(s)" -Level SUCCESS
        return $MiniDumps
        
    } catch {
        Write-Log "BlueScreenView analysis failed: $($_.Exception.Message)" -Level ERROR
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
    if ($env:maxDumpsToAnalyze -and $env:maxDumpsToAnalyze -notlike "null") {
        $MaxDumpsToAnalyze = [int]$env:maxDumpsToAnalyze
        Write-Log "MaxDumpsToAnalyze from environment: $MaxDumpsToAnalyze" -Level INFO
    }
    
    if ($env:analyzeOlderThanDays -and $env:analyzeOlderThanDays -notlike "null") {
        $AnalyzeOlderThanDays = [int]$env:analyzeOlderThanDays
        Write-Log "AnalyzeOlderThanDays from environment: $AnalyzeOlderThanDays" -Level INFO
    }
    
    # Check administrator privileges
    if (-not (Test-IsElevated)) {
        Write-Log "ERROR: This script requires administrator privileges" -Level ERROR
        throw "Access Denied"
    }
    
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    
    # Initialize status variables
    $BSODDetected = "false"
    $BSODCount = 0
    $BSODLastDate = 0
    $UnexpectedShutdownCount = 0
    $BSODDetails = ""
    
    # Check for unexpected shutdown events
    Write-Log "Checking for unexpected shutdown events (Event ID 6008)" -Level INFO
    $ShutdownEvents = Get-UnexpectedShutdownEvents
    
    if ($ShutdownEvents) {
        $UnexpectedShutdownCount = $ShutdownEvents.Count
        Write-Log "Unexpected shutdowns detected: $UnexpectedShutdownCount" -Level WARN
    } else {
        Write-Log "No unexpected shutdown events found" -Level SUCCESS
    }
    
    # Check for minidump files
    Write-Log "Scanning for minidump files in: $MinidumpPath" -Level INFO
    $DumpFiles = Get-MinidumpFiles -Path $MinidumpPath -DaysOld $AnalyzeOlderThanDays
    
    if (-not $DumpFiles) {
        Write-Log "No minidump files found - system is stable" -Level SUCCESS
        
        Set-NinjaField -FieldName "bsodDetected" -Value "false"
        Set-NinjaField -FieldName "bsodCount" -Value 0
        Set-NinjaField -FieldName "bsodLastDate" -Value 0
        Set-NinjaField -FieldName "bsodUnexpectedShutdowns" -Value $UnexpectedShutdownCount
        Set-NinjaField -FieldName "bsodDetails" -Value "No Blue Screen crashes detected in last $AnalyzeOlderThanDays days"
        
        Write-Log "BSOD analysis complete - no crashes detected" -Level SUCCESS
        $script:ExitCode = 0
        
    } else {
        # Minidumps found - analyze them
        $BSODDetected = "true"
        $BSODCount = $DumpFiles.Count
        
        # Get most recent dump timestamp
        $MostRecentDump = $DumpFiles | Select-Object -First 1
        $BSODLastDate = [DateTimeOffset]$MostRecentDump.LastWriteTime | Select-Object -ExpandProperty ToUnixTimeSeconds
        
        Write-Log "Most recent dump: $($MostRecentDump.Name) - $($MostRecentDump.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Level INFO
        
        # Limit analysis to MaxDumpsToAnalyze
        if ($BSODCount -gt $MaxDumpsToAnalyze) {
            Write-Log "Limiting analysis to $MaxDumpsToAnalyze most recent dump(s)" -Level INFO
        }
        
        # Run BlueScreenView analysis
        $AnalysisResults = Invoke-BlueScreenViewAnalysis
        
        if ($AnalysisResults) {
            # Build HTML report
            $HTMLRows = foreach ($Dump in $AnalysisResults | Select-Object -First $MaxDumpsToAnalyze) {
                $TimeStr = if ($Dump.Timestamp) { $Dump.Timestamp.ToString('yyyy-MM-dd HH:mm:ss') } else { "Unknown" }
                "<tr><td>$TimeStr</td><td style='color:#c00'>$($Dump.ErrorCode)</td><td>$($Dump.Reason)</td><td style='font-size:0.9em'>$($Dump.CausedByDriver)</td></tr>"
            }
            
            $BSODDetails = @"
<div style='font-family:Arial,sans-serif;'>
<h3 style='color:#c00'>Blue Screen Crashes Detected</h3>
<p><strong>Total Dumps Found:</strong> $BSODCount (last $AnalyzeOlderThanDays days)</p>
<p><strong>Unexpected Shutdowns:</strong> $UnexpectedShutdownCount</p>
<table border='1' style='border-collapse:collapse; width:100%;'>
<tr style='background-color:#f0f0f0;'><th>Timestamp</th><th>Error Code</th><th>Reason</th><th>Driver</th></tr>
$($HTMLRows -join "`n")
</table>
<p style='font-size:0.85em; color:#666; margin-top:10px;'>Analysis limited to $MaxDumpsToAnalyze most recent dump(s)</p>
</div>
"@
            
            Write-Log "Generated detailed BSOD report" -Level SUCCESS
            
        } else {
            # Analysis failed but dumps exist
            $BSODDetails = "$BSODCount minidump file(s) detected but analysis failed. Manual review recommended."
            Write-Log "BlueScreenView analysis failed - manual review needed" -Level WARN
        }
        
        # Update NinjaRMM fields
        Write-Log "Updating NinjaRMM custom fields" -Level INFO
        
        Set-NinjaField -FieldName "bsodDetected" -Value $BSODDetected
        Set-NinjaField -FieldName "bsodCount" -Value $BSODCount
        Set-NinjaField -FieldName "bsodLastDate" -Value $BSODLastDate
        Set-NinjaField -FieldName "bsodUnexpectedShutdowns" -Value $UnexpectedShutdownCount
        Set-NinjaField -FieldName "bsodDetails" -Value $BSODDetails
        
        Write-Log "BSOD analysis complete: $BSODCount crash(es) detected" -Level WARN
        
        # Exit with code 1 to indicate BSOD detected
        $script:ExitCode = 1
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "bsodDetected" -Value "false"
    Set-NinjaField -FieldName "bsodCount" -Value 0
    Set-NinjaField -FieldName "bsodDetails" -Value "Analysis script error: $($_.Exception.Message)"
    
    $script:ExitCode = 2
    
} finally {
    # Clean up downloaded files
    Write-Log "Cleaning up temporary files" -Level DEBUG
    Remove-DownloadedFiles -Paths @(
        $CsvPath,
        $ZipPath,
        $ExePath,
        "$TempDir\BlueScreenView.chm",
        "$TempDir\readme.txt"
    )
    
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
    
    # Exit code meanings
    switch ($script:ExitCode) {
        0 { Write-Log "  Status: STABLE (no BSOD detected)" -Level INFO }
        1 { Write-Log "  Status: ALERT (BSOD crashes detected)" -Level INFO }
        2 { Write-Log "  Status: ERROR (analysis failed)" -Level INFO }
    }
    
    Write-Log "========================================" -Level INFO
    
    # Cleanup
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit $script:ExitCode
}
