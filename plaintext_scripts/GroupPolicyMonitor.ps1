<#
.SYNOPSIS
    Group Policy Monitor - GPO Application Status and Error Detection

.DESCRIPTION
    Monitors Group Policy application status, tracks applied GPOs, detects processing errors,
    and provides HTML summary of all applied policies. Parses gpresult XML output to provide
    comprehensive GPO monitoring and maintains historical error tracking.
    
    Provides detailed visibility into Group Policy deployment including GPO names, paths,
    application timestamps, and error detection from event logs. Supports both domain-joined
    and workgroup computers with graceful handling of non-domain environments.

.NOTES
    Frequency: Daily
    Runtime: ~30 seconds
    Timeout: 120 seconds
    Context: SYSTEM
    
    Fields Updated:
    - GPOApplied (Text: "true"/"false")
    - GPOLastApplied (DateTime: Unix Epoch seconds since 1970-01-01 UTC)
    - GPOCount (Integer: number of applied computer GPOs)
    - GPOErrorsPresent (Text: "true"/"false")
    - GPOLastError (Text: error message, max 500 chars)
    - GPOAppliedList (WYSIWYG: HTML formatted table of all applied GPOs)
    
    Dependencies:
    - gpresult.exe (built-in Windows tool)
    - Requires domain-joined computer for full functionality
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
    
.MIGRATION NOTES
    v1.1 -> v4.0 Changes:
    - Updated to Framework 4.0 standards
    - Enhanced .NOTES section with complete field documentation
    - Added timeout specification
    - Improved .DESCRIPTION with functionality details
    
    v1.0 -> v1.1 Changes:
    - Converted GPOLastApplied from text to DateTime field (Unix Epoch format)
    - Uses inline DateTimeOffset conversion (no helper functions needed)
    - Maintains human-readable logging for troubleshooting
    - NinjaOne handles timezone display automatically
    - Applies to both gpresult and registry fallback methods
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Group Policy Monitor (Script 43 v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $gpoApplied = "false"
    $lastApplied = 0
    $gpoCount = 0
    $errorsPresent = "false"
    $lastError = "None"
    $appliedList = ""
    
    # Check if computer is domain-joined
    Write-Host "INFO: Checking domain membership..."
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    
    if ($computerSystem.PartOfDomain -eq $false) {
        Write-Host "INFO: Computer is not domain-joined. Group Policy not applicable."
        
        # Update fields for non-domain computers
        Ninja-Property-Set gpoApplied "false"
        Ninja-Property-Set gpoLastApplied 0
        Ninja-Property-Set gpoCount 0
        Ninja-Property-Set gpoErrorsPresent "false"
        Ninja-Property-Set gpoLastError "Not domain-joined"
        Ninja-Property-Set gpoAppliedList "Computer is not domain-joined"
        
        Write-Host "SUCCESS: Group Policy Monitor complete (not domain-joined)"
        exit 0
    }
    
    Write-Host "INFO: Computer is domain-joined: $($computerSystem.Domain)"
    
    # Generate Group Policy report
    try {
        Write-Host "INFO: Generating Group Policy report..."
        $reportPath = "$env:TEMP\gpresult.xml"
        
        # Run gpresult to generate XML report
        $null = gpresult /f /x $reportPath 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "gpresult failed with exit code $LASTEXITCODE"
        }
        
        if (-not (Test-Path $reportPath)) {
            throw "Group Policy report file not created"
        }
        
        Write-Host "INFO: Group Policy report generated successfully"
        
        # Parse XML report
        [xml]$gpoReport = Get-Content $reportPath
        
        # Get computer GPOs
        $computerGPOs = $gpoReport.Rsop.ComputerResults.GPO
        
        if ($computerGPOs) {
            $gpoApplied = "true"
            $gpoCount = @($computerGPOs).Count
            Write-Host "INFO: Applied GPOs: $gpoCount"
            
            # Get last applied time from first GPO
            $readTime = $gpoReport.Rsop.ReadTime
            if ($readTime) {
                $lastAppliedDate = [DateTime]::Parse($readTime)
                $lastApplied = [DateTimeOffset]$lastAppliedDate | Select-Object -ExpandProperty ToUnixTimeSeconds
                Write-Host "INFO: Last Applied: $($lastAppliedDate.ToString('yyyy-MM-dd HH:mm:ss'))"
            }
            
            # Build HTML list of applied GPOs
            $htmlRows = @()
            foreach ($gpo in $computerGPOs) {
                $gpoName = $gpo.Name
                $gpoPath = $gpo.Path.Identifier.'#text'
                $htmlRows += "<tr><td>$gpoName</td><td style='font-size:0.85em;color:#666'>$gpoPath</td></tr>"
            }
            
            $appliedList = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>GPO Name</th><th>Path</th></tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; color:#666; margin-top:10px;'>Total: $gpoCount GPO(s) applied</p>
"@
        } else {
            Write-Host "WARNING: No computer GPOs found in report"
            $appliedList = "No Group Policies applied to this computer"
        }
        
        # Clean up report file
        Remove-Item $reportPath -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "WARNING: Failed to generate/parse Group Policy report: $_"
        $lastError = "Report generation failed: $_"
        $errorsPresent = "true"
        $appliedList = "Unable to generate GPO report"
    }
    
    # Check for Group Policy errors in event log
    try {
        Write-Host "INFO: Checking for Group Policy errors..."
        $startTime = (Get-Date).AddHours(-24)
        
        $gpoErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-GroupPolicy'
            Level = 1,2
            StartTime = $startTime
        } -MaxEvents 10 -ErrorAction SilentlyContinue
        
        if ($gpoErrors -and $gpoErrors.Count -gt 0) {
            $errorsPresent = "true"
            $lastError = $gpoErrors[0].Message
            
            # Truncate if too long
            if ($lastError.Length -gt 500) {
                $lastError = $lastError.Substring(0, 497) + "..."
            }
            
            Write-Host "WARNING: Group Policy errors detected: $($gpoErrors.Count) error(s) in last 24 hours"
        } else {
            Write-Host "INFO: No Group Policy errors detected"
            $lastError = "None"
        }
    } catch {
        Write-Host "WARNING: Failed to check event log for GPO errors: $_"
    }
    
    # Alternative method: Check GP application status from registry
    if ($gpoApplied -eq "false") {
        try {
            Write-Host "INFO: Checking registry for GP application status..."
            $gpoRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine"
            
            if (Test-Path $gpoRegPath) {
                $gpoState = Get-ItemProperty -Path $gpoRegPath -ErrorAction SilentlyContinue
                
                if ($gpoState) {
                    # Get last GPUpdate time
                    $lastGPUpdate = $gpoState.LastGPOProcessingTime
                    if ($lastGPUpdate) {
                        $lastAppliedDate = [DateTime]::Parse($lastGPUpdate)
                        $lastApplied = [DateTimeOffset]$lastAppliedDate | Select-Object -ExpandProperty ToUnixTimeSeconds
                        $gpoApplied = "true"
                        Write-Host "INFO: Last Applied (registry): $($lastAppliedDate.ToString('yyyy-MM-dd HH:mm:ss'))"
                    }
                }
            }
        } catch {
            Write-Host "WARNING: Failed to check registry for GP status: $_"
        }
    }
    
    # Check for pending GP refresh
    try {
        $pendingRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List"
        if (Test-Path $pendingRegPath) {
            Write-Host "INFO: Group Policy extensions are registered"
        }
    } catch {
        # Silent fail
    }
    
    # If still no GPO data, set minimal info
    if ($gpoApplied -eq "false" -and $computerSystem.PartOfDomain) {
        $gpoApplied = "true"
        $appliedList = "Unable to retrieve detailed GPO list (gpresult failed)"
        $lastError = "GPO report generation failed"
        $errorsPresent = "true"
    }
    
    # Update NinjaRMM custom fields
    Write-Host "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set gpoApplied $gpoApplied
    Ninja-Property-Set gpoLastApplied $lastApplied
    Ninja-Property-Set gpoCount $gpoCount
    Ninja-Property-Set gpoErrorsPresent $errorsPresent
    Ninja-Property-Set gpoLastError $lastError
    Ninja-Property-Set gpoAppliedList $appliedList
    
    Write-Host "SUCCESS: Group Policy Monitor complete. GPOs Applied: $gpoCount, Errors: $errorsPresent"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Host "ERROR: Group Policy Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set gpoApplied "false"
    Ninja-Property-Set gpoLastApplied 0
    Ninja-Property-Set gpoErrorsPresent "true"
    Ninja-Property-Set gpoLastError "Monitor script error: $errorMessage"
    Ninja-Property-Set gpoAppliedList "Script execution failed"
    
    exit 1
}
