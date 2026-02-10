#Requires -Version 5.1

<#
.SYNOPSIS
    Monitors Group Policy application status and detects errors.

.DESCRIPTION
    Comprehensive Group Policy monitoring script that tracks applied GPOs, detects processing 
    errors, and generates detailed reports. Parses gpresult XML output to provide complete 
    visibility into Group Policy deployment.
    
    The script performs the following:
    - Checks domain membership status
    - Generates Group Policy report using gpresult
    - Parses applied computer GPOs from XML
    - Checks event logs for Group Policy errors (last 24 hours)
    - Falls back to registry checks if gpresult fails
    - Generates HTML formatted table of applied GPOs
    - Reports comprehensive status to NinjaRMM
    
    Gracefully handles non-domain computers by reporting appropriate status.

.PARAMETER MaxErrors
    Maximum number of event log errors to check. Default: 10

.PARAMETER ErrorWindowHours
    Hours to look back for Group Policy errors in event log. Default: 24

.EXAMPLE
    .\GPO-Monitor.ps1

    [2026-02-10 00:59:00] [INFO] Starting: GPO-Monitor v3.0
    [2026-02-10 00:59:01] [INFO] Computer is domain-joined: contoso.com
    [2026-02-10 00:59:02] [SUCCESS] Found 12 applied GPO(s)
    [2026-02-10 00:59:02] [SUCCESS] No Group Policy errors detected
    [2026-02-10 00:59:02] [SUCCESS] Group Policy monitoring completed: 12 GPO(s), Errors: false

.EXAMPLE
    .\GPO-Monitor.ps1 -ErrorWindowHours 48

    Checks for errors in last 48 hours instead of default 24.

.OUTPUTS
    None. Status is written to console and NinjaRMM custom fields.

.NOTES
    File Name      : GPO-Monitor.ps1
    Prerequisite   : PowerShell 5.1 or higher, Domain-joined computer
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Set-StrictMode and finally block
    - 2.0: Enhanced with Write-Log and error tracking
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily
    Typical Duration: 5-30 seconds
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A
    
    Fields Updated:
        - gpoApplied - Boolean status (true/false)
        - gpoLastApplied - Unix Epoch timestamp of last application
        - gpoCount - Number of applied computer GPOs
        - gpoErrorsPresent - Boolean error status (true/false)
        - gpoLastError - Last error message (max 500 chars)
        - gpoAppliedList - HTML formatted table of applied GPOs

.COMPONENT
    gpresult.exe - Windows Group Policy results tool
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Monitors Group Policy application status
    - Detects and reports GPO processing errors
    - Generates detailed HTML reports of applied policies
    - Updates NinjaRMM custom fields with status
    - Handles domain-joined and workgroup computers
    - Falls back to registry when gpresult fails
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Maximum event log errors to check")]
    [int]$MaxErrors = 10,
    
    [Parameter(Mandatory=$false, HelpMessage="Hours to look back for errors")]
    [ValidateRange(1, 168)]
    [int]$ErrorWindowHours = 24
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "GPO-Monitor"
    $ReportPath = "$env:TEMP\gpresult_$(Get-Date -Format 'yyyyMMddHHmmss').xml"
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:CLIFallbackCount = 0
    $script:ExitCode = 0

    if ($env:maxErrors -and $env:maxErrors -notlike "null") {
        $MaxErrors = [int]$env:maxErrors
    }
    
    if ($env:errorWindowHours -and $env:errorWindowHours -notlike "null") {
        $ErrorWindowHours = [int]$env:errorWindowHours
    }

    function Write-Log {
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
        
        switch ($Level) {
            'ERROR' { 
                Write-Error $LogMessage
                $script:ErrorCount++ 
            }
            'WARN' { 
                Write-Warning $LogMessage
                $script:WarningCount++ 
            }
            default { 
                Write-Output $LogMessage 
            }
        }
    }

    function Set-NinjaField {
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
        try {
            Write-Log "Generating Group Policy report" -Level INFO
            
            $GPResultProcess = Start-Process -FilePath "gpresult.exe" -ArgumentList "/f", "/x", $ReportPath -Wait -NoNewWindow -PassThru
            
            if ($GPResultProcess.ExitCode -ne 0) {
                throw "gpresult failed with exit code $($GPResultProcess.ExitCode)"
            }
            
            if (-not (Test-Path $ReportPath)) {
                throw "Group Policy report file not created"
            }
            
            [xml]$Report = Get-Content $ReportPath
            Write-Log "Group Policy report generated successfully" -Level SUCCESS
            
            return $Report
            
        } catch {
            Write-Log "Failed to generate Group Policy report: $_" -Level ERROR
            return $null
        } finally {
            if (Test-Path $ReportPath) {
                Remove-Item $ReportPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    function Get-GPOErrors {
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
                Level = 1,2
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
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
            return
        }
        
        Write-Log "Computer is domain-joined: $($ComputerSystem.Domain)" -Level INFO
        
        $GPOApplied = "false"
        $LastApplied = 0
        $GPOCount = 0
        $ErrorsPresent = "false"
        $LastError = "None"
        $AppliedList = ""
        
        $GPOReport = Get-GPOReport
        
        if ($GPOReport) {
            $ComputerGPOs = $GPOReport.Rsop.ComputerResults.GPO
            
            if ($ComputerGPOs) {
                $GPOApplied = "true"
                $GPOCount = @($ComputerGPOs).Count
                Write-Log "Found $GPOCount applied GPO(s)" -Level SUCCESS
                
                $ReadTime = $GPOReport.Rsop.ReadTime
                if ($ReadTime) {
                    $LastAppliedDate = [DateTime]::Parse($ReadTime)
                    $LastApplied = [DateTimeOffset]$LastAppliedDate | Select-Object -ExpandProperty ToUnixTimeSeconds
                    Write-Log "Last applied: $($LastAppliedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Level INFO
                }
                
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
        
        $GPOErrors = Get-GPOErrors -Hours $ErrorWindowHours -MaxEvents $MaxErrors
        
        if ($GPOErrors) {
            $ErrorsPresent = "true"
            $LastError = $GPOErrors[0].Message
            
            if ($LastError.Length -gt 500) {
                $LastError = $LastError.Substring(0, 497) + "..."
            }
            
            Write-Log "Group Policy errors detected: $($GPOErrors.Count)" -Level WARN
        }
        
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
        
        $script:ExitCode = 1
    }
}

end {
    try {
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
        
        if ($script:ErrorCount -gt 0) {
            $script:ExitCode = 1
        }
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
