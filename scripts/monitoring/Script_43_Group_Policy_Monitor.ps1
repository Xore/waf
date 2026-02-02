<#
.SYNOPSIS
    Script 43: Group Policy Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Group Policy application status, tracks applied GPOs, detects processing errors,
    and provides HTML summary of all applied policies. Updates 6 GPO fields.

.FIELDS UPDATED
    - GPOApplied (Checkbox)
    - GPOLastApplied (DateTime)
    - GPOCount (Integer)
    - GPOErrorsPresent (Checkbox)
    - GPOLastError (Text)
    - GPOAppliedList (WYSIWYG)

.EXECUTION
    Frequency: Daily
    Runtime: ~30 seconds
    Requires: Domain-joined computer, Group Policy applied

.NOTES
    File: Script_43_Group_Policy_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Domain Integration
    Dependencies: gpresult.exe, Group Policy PowerShell module (optional)

.RELATED DOCUMENTATION
    - docs/core/17_GPO_Group_Policy.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 3)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Group Policy Monitor (Script 43)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $gpoApplied = $false
    $lastApplied = ""
    $gpoCount = 0
    $errorsPresent = $false
    $lastError = "None"
    $appliedList = ""
    
    # Check if computer is domain-joined
    Write-Host "Checking domain membership..."
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    
    if ($computerSystem.PartOfDomain -eq $false) {
        Write-Host "Computer is not domain-joined. Group Policy not applicable."
        
        # Update fields for non-domain computers
        Ninja-Property-Set gpoApplied $false
        Ninja-Property-Set gpoLastApplied ""
        Ninja-Property-Set gpoCount 0
        Ninja-Property-Set gpoErrorsPresent $false
        Ninja-Property-Set gpoLastError "Not domain-joined"
        Ninja-Property-Set gpoAppliedList "Computer is not domain-joined"
        
        Write-Host "Group Policy Monitor complete (not domain-joined)."
        exit 0
    }
    
    Write-Host "Computer is domain-joined: $($computerSystem.Domain)"
    
    # Generate Group Policy report
    try {
        Write-Host "Generating Group Policy report..."
        $reportPath = "$env:TEMP\gpresult.xml"
        
        # Run gpresult to generate XML report
        $null = gpresult /f /x $reportPath 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "gpresult failed with exit code $LASTEXITCODE"
        }
        
        if (-not (Test-Path $reportPath)) {
            throw "Group Policy report file not created"
        }
        
        Write-Host "Group Policy report generated successfully."
        
        # Parse XML report
        [xml]$gpoReport = Get-Content $reportPath
        
        # Get computer GPOs
        $computerGPOs = $gpoReport.Rsop.ComputerResults.GPO
        
        if ($computerGPOs) {
            $gpoApplied = $true
            $gpoCount = @($computerGPOs).Count
            Write-Host "Applied GPOs: $gpoCount"
            
            # Get last applied time from first GPO
            $readTime = $gpoReport.Rsop.ReadTime
            if ($readTime) {
                $lastAppliedDate = [DateTime]::Parse($readTime)
                $lastApplied = $lastAppliedDate.ToString("yyyy-MM-dd HH:mm:ss")
                Write-Host "Last Applied: $lastApplied"
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
            Write-Warning "No computer GPOs found in report."
            $appliedList = "No Group Policies applied to this computer"
        }
        
        # Clean up report file
        Remove-Item $reportPath -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Warning "Failed to generate/parse Group Policy report: $_"
        $lastError = "Report generation failed: $_"
        $errorsPresent = $true
        $appliedList = "Unable to generate GPO report"
    }
    
    # Check for Group Policy errors in event log
    try {
        Write-Host "Checking for Group Policy errors..."
        $startTime = (Get-Date).AddHours(-24)
        
        $gpoErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-GroupPolicy'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -MaxEvents 10 -ErrorAction SilentlyContinue
        
        if ($gpoErrors -and $gpoErrors.Count -gt 0) {
            $errorsPresent = $true
            $lastError = $gpoErrors[0].Message
            
            # Truncate if too long
            if ($lastError.Length -gt 500) {
                $lastError = $lastError.Substring(0, 497) + "..."
            }
            
            Write-Warning "Group Policy errors detected: $($gpoErrors.Count) error(s) in last 24 hours"
        } else {
            Write-Host "No Group Policy errors detected."
            $lastError = "None"
        }
    } catch {
        Write-Warning "Failed to check event log for GPO errors: $_"
    }
    
    # Alternative method: Check GP application status from registry
    if (-not $gpoApplied) {
        try {
            Write-Host "Checking registry for GP application status..."
            $gpoRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine"
            
            if (Test-Path $gpoRegPath) {
                $gpoState = Get-ItemProperty -Path $gpoRegPath -ErrorAction SilentlyContinue
                
                if ($gpoState) {
                    # Get last GPUpdate time
                    $lastGPUpdate = $gpoState.LastGPOProcessingTime
                    if ($lastGPUpdate) {
                        $lastApplied = ([DateTime]::Parse($lastGPUpdate)).ToString("yyyy-MM-dd HH:mm:ss")
                        $gpoApplied = $true
                    }
                }
            }
        } catch {
            Write-Warning "Failed to check registry for GP status: $_"
        }
    }
    
    # Check for pending GP refresh
    try {
        $pendingRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List"
        if (Test-Path $pendingRegPath) {
            Write-Host "Group Policy extensions are registered."
        }
    } catch {
        # Silent fail
    }
    
    # If still no GPO data, set minimal info
    if (-not $gpoApplied -and $computerSystem.PartOfDomain) {
        $gpoApplied = $true  # Assume GPO is applied on domain computers
        $appliedList = "Unable to retrieve detailed GPO list (gpresult failed)"
        $lastError = "GPO report generation failed"
        $errorsPresent = $true
    }
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set gpoApplied $gpoApplied
    Ninja-Property-Set gpoLastApplied $lastApplied
    Ninja-Property-Set gpoCount $gpoCount
    Ninja-Property-Set gpoErrorsPresent $errorsPresent
    Ninja-Property-Set gpoLastError $lastError
    Ninja-Property-Set gpoAppliedList $appliedList
    
    Write-Host "Group Policy Monitor complete. GPOs Applied: $gpoCount, Errors: $errorsPresent"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Group Policy Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set gpoApplied $false
    Ninja-Property-Set gpoErrorsPresent $true
    Ninja-Property-Set gpoLastError "Monitor script error: $errorMessage"
    Ninja-Property-Set gpoAppliedList "Script execution failed"
    
    exit 1
}
