#Requires -Version 5.1

<#
.SYNOPSIS
    Starts SAP GUI and Chrome browser for BDE workflow automation

.DESCRIPTION
    Automates the startup sequence for Business Desktop Environment (BDE) operations
    by launching SAP GUI followed by Google Chrome browser. Validates both applications
    are installed before attempting to start them.
    
    The script performs the following:
    - Validates SAP GUI executable exists at specified path
    - Validates Chrome browser executable exists at specified path
    - Launches SAP GUI application
    - Waits 2 seconds for SAP GUI to initialize
    - Launches Chrome browser
    - Reports success/failure status
    - Updates NinjaRMM custom fields (if needed)
    
    This standardizes the startup process for users requiring both SAP GUI and
    browser-based tools as part of their daily workflow.
    
    This script runs unattended without user interaction.

.PARAMETER SAPPath
    Full path to the SAP GUI executable.
    Default: C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe
    Can be overridden by environment variable: sapPath

.PARAMETER ChromePath
    Full path to Google Chrome executable.
    Default: C:\Program Files\Google\Chrome\Application\chrome.exe
    Can be overridden by environment variable: chromePath

.EXAMPLE
    .\BDE-StartSAPandBrowser.ps1
    
    Launches SAP GUI and Chrome using default installation paths.

.EXAMPLE
    .\BDE-StartSAPandBrowser.ps1 -SAPPath "D:\SAP\saplogon.exe" -ChromePath "C:\Program Files\Chrome\chrome.exe"
    
    Uses custom paths for SAP GUI and Chrome.

.NOTES
    Script Name:    BDE-StartSAPandBrowser.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or User (via NinjaRMM automation)
    Execution Frequency: On-demand or scheduled
    Typical Duration: ~2-4 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - bdeStartupStatus (Success/Partial/Failed) - if Set-NinjaField is used
        - bdeStartupDate (timestamp) - if Set-NinjaField is used
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - SAP GUI installed at default or specified path
        - Google Chrome installed at default or specified path
    
    Environment Variables (Optional):
        - sapPath: Override default SAP GUI path
        - chromePath: Override default Chrome path
    
    Exit Codes:
        0 - Success (both applications started)
        1 - Partial or complete failure

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Full path to SAP GUI executable")]
    [ValidateNotNullOrEmpty()]
    [string]$SAPPath = 'C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe',
    
    [Parameter(Mandatory=$false, HelpMessage="Full path to Google Chrome executable")]
    [ValidateNotNullOrEmpty()]
    [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

begin {
    Set-StrictMode -Version Latest
    
    # ============================================================================
    # CONFIGURATION
    # ============================================================================
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "BDE-StartSAPandBrowser"
    
    # NinjaRMM CLI path for fallback
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    # ============================================================================
    # INITIALIZATION
    # ============================================================================
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        # Check for environment variable overrides
        if ($env:sapPath -and $env:sapPath -notlike 'null') {
            $SAPPath = $env:sapPath
            Write-Log "Using SAP path from environment: $SAPPath" -Level INFO
        }
        
        if ($env:chromePath -and $env:chromePath -notlike 'null') {
            $ChromePath = $env:chromePath
            Write-Log "Using Chrome path from environment: $ChromePath" -Level INFO
        }
        
        $ApplicationsStarted = 0
        $ApplicationsAttempted = 0
        
        # ============================================================================
        # START SAP GUI
        # ============================================================================
        
        Write-Log "Validating SAP GUI installation" -Level INFO
        if (-not (Test-Path -Path $SAPPath -ErrorAction SilentlyContinue)) {
            Write-Log "SAP GUI not found at: $SAPPath" -Level ERROR
            Write-Log "Verify SAP GUI is installed or provide correct path via -SAPPath parameter" -Level ERROR
            $ApplicationsAttempted++
        } else {
            $ApplicationsAttempted++
            Write-Log "SAP GUI found at: $SAPPath" -Level INFO
            
            try {
                Write-Log "Starting SAP GUI..." -Level INFO
                Start-Process -FilePath $SAPPath -ErrorAction Stop
                Write-Log "SAP GUI started successfully" -Level SUCCESS
                $ApplicationsStarted++
            } catch {
                Write-Log "Failed to start SAP GUI: $($_.Exception.Message)" -Level ERROR
            }
        }
        
        # Wait for SAP GUI to initialize
        if ($ApplicationsStarted -gt 0) {
            Write-Log "Waiting 2 seconds for SAP GUI initialization..." -Level DEBUG
            Start-Sleep -Seconds 2
        }
        
        # ============================================================================
        # START CHROME BROWSER
        # ============================================================================
        
        Write-Log "Validating Chrome browser installation" -Level INFO
        if (-not (Test-Path -Path $ChromePath -ErrorAction SilentlyContinue)) {
            Write-Log "Chrome browser not found at: $ChromePath" -Level ERROR
            Write-Log "Verify Chrome is installed or provide correct path via -ChromePath parameter" -Level ERROR
            $ApplicationsAttempted++
        } else {
            $ApplicationsAttempted++
            Write-Log "Chrome browser found at: $ChromePath" -Level INFO
            
            try {
                Write-Log "Starting Chrome browser..." -Level INFO
                Start-Process -FilePath $ChromePath -ErrorAction Stop
                Write-Log "Chrome browser started successfully" -Level SUCCESS
                $ApplicationsStarted++
            } catch {
                Write-Log "Failed to start Chrome browser: $($_.Exception.Message)" -Level ERROR
            }
        }
        
        # ============================================================================
        # DETERMINE FINAL STATUS
        # ============================================================================
        
        if ($ApplicationsStarted -eq 2) {
            Write-Log "BDE workflow startup complete - all applications started" -Level SUCCESS
            $script:ExitCode = 0
        } elseif ($ApplicationsStarted -gt 0) {
            Write-Log "BDE workflow partially started ($ApplicationsStarted of $ApplicationsAttempted applications)" -Level WARN
            $script:ExitCode = 1
        } else {
            Write-Log "BDE workflow startup failed - no applications started" -Level ERROR
            $script:ExitCode = 1
        }
        
        Write-Log "Applications started: $ApplicationsStarted of $ApplicationsAttempted" -Level INFO
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        # Calculate and log execution time
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
        
    } finally {
        # Force garbage collection
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}