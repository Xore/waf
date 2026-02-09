#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Analyzes Domain Controller health using DCDiag and reports results

.DESCRIPTION
    Runs comprehensive DCDiag diagnostic tests on a Domain Controller and reports results.
    Tests include connectivity, replication, SYSVOL, DNS, services, and more.
    
    The script performs the following:
    - Validates script runs on Domain Controller with admin privileges
    - Executes 20+ DCDiag diagnostic tests
    - Categorizes tests as passed or failed
    - Optionally generates HTML report for NinjaRMM WYSIWYG field
    - Provides detailed output for failed tests
    - Updates NinjaRMM custom fields with results
    
    This script runs unattended without user interaction.

.PARAMETER wysiwygCustomField
    Optional name of a WYSIWYG custom field to save HTML-formatted results.
    Must be a valid NinjaRMM custom field name (max 200 characters).
    If not specified, results are output to console only.

.EXAMPLE
    .\AD-DomainControllerHealthReport.ps1
    
    Runs all DCDiag tests and displays results in console.

.EXAMPLE
    .\AD-DomainControllerHealthReport.ps1 -wysiwygCustomField "dcHealthReport"
    
    Runs tests and saves HTML results to specified custom field.

.NOTES
    Script Name:    AD-DomainControllerHealthReport.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~45-90 seconds (depends on DC health)
    Timeout Setting: 300 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - wysiwygCustomField (if specified) - HTML formatted report
        - dcHealthStatus (Healthy/Issues)
        - dcFailedTestCount (number of failed tests)
        - dcLastCheckDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Must run on Domain Controller
        - DCDiag.exe (included with AD DS role)
    
    Environment Variables (Optional):
        - wysiwygCustomFieldName: Alternative to -wysiwygCustomField parameter
    
    Exit Codes:
        0 - Success (all tests passed)
        1 - Failure (one or more tests failed, or script error)

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/windows-server/identity/ad-ds/manage/dcdiag
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of WYSIWYG custom field for HTML report")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,200)]
    [String]$wysiwygCustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "AD-DomainControllerHealthReport"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# DCDiag tests to run
$DCDiagTestsToRun = @(
    "Connectivity", "Advertising", "FrsEvent", "DFSREvent", "SysVolCheck",
    "KccEvent", "KnowsOfRoleHolders", "MachineAccount", "NCSecDesc",
    "NetLogons", "ObjectsReplicated", "Replications", "RidManager",
    "Services", "SystemLog", "VerifyReferences", "CheckSDRefDom",
    "CrossRefValidation", "LocatorCheck", "Intersite"
)

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
        $Value,
        
        [Parameter(Mandatory=$false)]
        [string]$Type = "Text"
    )
    
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    # Check character limit for large values (WYSIWYG fields)
    if ($ValueString.Length -ge 200000) {
        Write-Log "Warning: Field value exceeds 200,000 characters, truncating" -Level WARN
        $ValueString = $ValueString.Substring(0, 199900)
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
        
        # Method 2: Fall back to NinjaRMM CLI
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

function Test-IsDomainController {
    <#
    .SYNOPSIS
        Checks if current machine is a Domain Controller
    #>
    try {
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        # ProductType 2 = Domain Controller
        return ($OS.ProductType -eq 2)
    } catch {
        Write-Log "Error checking DC status: $_" -Level ERROR
        return $false
    }
}

function Get-DCDiagResults {
    <#
    .SYNOPSIS
        Runs DCDiag tests and returns results
    #>
    foreach ($DCTest in $DCDiagTestsToRun) {
        $OutputFile = "$env:TEMP\dc-diag-$DCTest-$(Get-Random).txt"
        
        try {
            Write-Log "Running DCDiag test: $DCTest" -Level DEBUG
            
            # Run DCDiag for current test
            $DCDiag = Start-Process -FilePath "DCDiag.exe" `
                -ArgumentList "/test:$DCTest", "/f:$OutputFile" `
                -PassThru -Wait -NoNewWindow -ErrorAction Stop

            if ($DCDiag.ExitCode -ne 0) {
                Write-Log "DCDiag test $DCTest exited with code $($DCDiag.ExitCode)" -Level WARN
            }

            # Read results and filter empty lines
            $RawResult = Get-Content -Path $OutputFile -ErrorAction Stop | 
                Where-Object { $_.Trim() -ne "" }
        
            # Find status line
            $StatusLine = $RawResult | Where-Object { $_ -match "\. .* test $DCTest" }
            $Status = $StatusLine -split ' ' | Where-Object { $_ -like "passed" -or $_ -like "failed" }

            # Create result object
            [PSCustomObject]@{
                Test   = $DCTest
                Status = $Status
                Result = $RawResult
            }
        }
        catch {
            Write-Log "Failed to run DCDiag test $DCTest - $_" -Level ERROR
            
            # Return failure object
            [PSCustomObject]@{
                Test   = $DCTest
                Status = "failed"
                Result = @("Error: $($_.Exception.Message)")
            }
        }
        finally {
            # Cleanup temporary file
            if (Test-Path $OutputFile) {
                Remove-Item -Path $OutputFile -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for form variable override
    if ($env:wysiwygCustomFieldName -and $env:wysiwygCustomFieldName -notlike "null") {
        $wysiwygCustomField = $env:wysiwygCustomFieldName
        Write-Log "Using custom field from environment: $wysiwygCustomField" -Level INFO
    }
    
    # Validate custom field name length
    if ($wysiwygCustomField -and $wysiwygCustomField.Length -gt 200) {
        throw "Custom field name exceeds 200 character limit"
    }
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    Write-Log "Administrator privileges verified" -Level INFO

    # Check if running on Domain Controller
    if (-not (Test-IsDomainController)) {
        throw "Script must be executed on a Domain Controller"
    }
    Write-Log "Domain Controller role verified" -Level INFO

    # Initialize result lists
    $PassingTests = [System.Collections.Generic.List[object]]::new()
    $FailedTests = [System.Collections.Generic.List[object]]::new()

    # Run DCDiag tests
    Write-Log "Retrieving Directory Server Diagnosis Test Results" -Level INFO
    $TestResults = Get-DCDiagResults
    Write-Log "DCDiag tests completed" -Level INFO

    # Process results
    foreach ($Result in $TestResults) {
        $TestFailed = $false

        $Result.Status | ForEach-Object {
            if ($_ -notmatch "pass") {
                $TestFailed = $true
            }
        }

        if ($TestFailed) {
            $FailedTests.Add($Result)
        } else {
            $PassingTests.Add($Result)
        }
    }

    # Update NinjaRMM status fields
    if ($FailedTests.Count -eq 0) {
        Set-NinjaField -FieldName "dcHealthStatus" -Value "Healthy"
    } else {
        Set-NinjaField -FieldName "dcHealthStatus" -Value "Issues"
    }
    Set-NinjaField -FieldName "dcFailedTestCount" -Value $FailedTests.Count
    Set-NinjaField -FieldName "dcLastCheckDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

    # Generate HTML report if custom field specified
    if ($wysiwygCustomField) {
        try {
            Write-Log "Building HTML for Custom Field: $wysiwygCustomField" -Level INFO

            $HTML = [System.Collections.Generic.List[string]]::new()
            $HTML.Add("<h1 style='text-align: center'>Directory Server Diagnosis Test Results</h1>")
            
            $FailedPercentage = [math]::Round((($FailedTests.Count / ($FailedTests.Count + $PassingTests.Count)) * 100), 2)
            $SuccessPercentage = 100 - $FailedPercentage
            
            $HTML.Add(@"
<div class='p-3 linechart'>
    <div style='width: $FailedPercentage%; background-color: #C6313A;'></div>
    <div style='width: $SuccessPercentage%; background-color: #007644;'></div>
</div>
<ul class='unstyled p-3' style='display: flex; justify-content: space-between;'>
    <li><span class='chart-key' style='background-color: #C6313A;'></span><span>Failed ($($FailedTests.Count))</span></li>
    <li><span class='chart-key' style='background-color: #007644;'></span><span>Passed ($($PassingTests.Count))</span></li>
</ul>
"@)

            # Add failed tests
            $FailedTests | Sort-Object Test | ForEach-Object {
                $ResultText = ($_.Result | Out-String) -replace "'", "&#39;"
                $HTML.Add(@"
<div class='info-card error'>
    <i class='info-icon fa-solid fa-circle-exclamation'></i>
    <div class='info-text'>
        <div class='info-title'>$($_.Test)</div>
        <div class='info-description'>$ResultText</div>
    </div>
</div>
"@)
            }

            # Add passing tests
            $PassingTests | Sort-Object Test | ForEach-Object {
                $HTML.Add(@"
<div class='info-card success'>
    <i class='info-icon fa-solid fa-circle-check'></i>
    <div class='info-text'>
        <div class='info-title'>$($_.Test)</div>
        <div class='info-description'>Test passed.</div>
    </div>
</div>
"@)
            }

            # Set custom field
            Set-NinjaField -FieldName $wysiwygCustomField -Value ($HTML -join "") -Type "WYSIWYG"
            Write-Log "Successfully set Custom Field: $wysiwygCustomField" -Level SUCCESS
        }
        catch {
            Write-Log "Failed to set custom field: $_" -Level ERROR
        }
    }

    # Display results summary
    if ($PassingTests.Count -gt 0) {
        $PassingTestList = ($PassingTests.Test | Sort-Object) -join ", "
        Write-Log "Passing Tests ($($PassingTests.Count)): $PassingTestList" -Level SUCCESS
    }

    if ($FailedTests.Count -gt 0) {
        Write-Log "ALERT: Failed Tests Detected" -Level ERROR
        $FailedTestList = ($FailedTests.Test | Sort-Object) -join ", "
        Write-Log "Failed Tests ($($FailedTests.Count)): $FailedTestList" -Level ERROR

        Write-Log "Detailed Output for Failed Tests:" -Level INFO
        $FailedTests | Sort-Object Test | ForEach-Object {
            Write-Log "Test: $($_.Test)" -Level INFO
            $_.Result | ForEach-Object { Write-Log $_ -Level INFO }
        }
        
        exit 1
    } else {
        Write-Log "All Directory Server Diagnosis Tests Passed" -Level SUCCESS
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    exit 1
    
} finally {
    # Calculate and log execution time
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "  Tests Passed: $($PassingTests.Count)" -Level INFO
    Write-Log "  Tests Failed: $($FailedTests.Count)" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}

# Exit with appropriate code
if ($script:ErrorCount -gt 0 -or $FailedTests.Count -gt 0) {
    exit 1
} else {
    exit 0
}
