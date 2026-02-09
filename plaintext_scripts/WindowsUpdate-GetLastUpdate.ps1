#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves and reports the last successfully installed Windows Update

.DESCRIPTION
    Queries Windows Update history to find the most recent successfully installed
    update and reports the information to NinjaRMM custom fields.
    
    The script performs the following:
    - Queries Windows Update COM object for update history
    - Filters for successfully installed updates (ResultCode 2)
    - Identifies the most recent update
    - Calculates days since last update
    - Determines if update is overdue based on threshold
    - Reports findings to NinjaRMM custom fields
    
    This script runs unattended without user interaction.

.PARAMETER DaysThreshold
    Number of days before an update is considered overdue.
    Default: 60 days

.EXAMPLE
    .\WindowsUpdate-GetLastUpdate.ps1
    
    Checks for last update with default 60-day threshold.

.EXAMPLE
    .\WindowsUpdate-GetLastUpdate.ps1 -DaysThreshold 30
    
    Checks for last update with 30-day threshold.

.NOTES
    Script Name:    WindowsUpdate-GetLastUpdate.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily
    Typical Duration: ~2-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - lastwindowsupdatedate - Date/time of last update (ISO 8601)
        - lastwindowsupdatename - Title of last update
        - lastwindowsupdateoverdue - Boolean (true/false)
        - windowsUpdateStatus - Status (Updated/Overdue/NoHistory/Failed)
        - windowsUpdateDaysSince - Days since last update
        - windowsUpdateDate - Timestamp of check
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Windows Update COM objects (Microsoft.Update.Session)
        - NinjaRMM Agent installed
        - SYSTEM privileges
    
    Environment Variables (Optional):
        - daysThreshold: Override -DaysThreshold parameter
    
    Exit Codes:
        0 - Success (update info retrieved and reported)
        1 - Failure (COM error or script failure)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Days before update is considered overdue")]
    [ValidateRange(1, 365)]
    [int]$DaysThreshold = 60
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "WindowsUpdate-GetLastUpdate"

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

function Get-WindowsUpdateHistory {
    <#
    .SYNOPSIS
        Retrieves Windows Update history using COM objects
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Creating Windows Update COM session" -Level DEBUG
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session -ErrorAction Stop
        
        Write-Log "Creating update searcher" -Level DEBUG
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        
        Write-Log "Querying update history count" -Level DEBUG
        $HistoryCount = $UpdateSearcher.GetTotalHistoryCount()
        
        if ($HistoryCount -eq 0) {
            Write-Log "No update history found" -Level WARN
            return $null
        }
        
        Write-Log "Found $HistoryCount total update records" -Level INFO
        Write-Log "Querying update history" -Level DEBUG
        
        $Updates = $UpdateSearcher.QueryHistory(0, $HistoryCount) | 
                   Where-Object { $_.ResultCode -eq 2 } | 
                   Sort-Object -Property Date -Descending | 
                   Select-Object -First 1
        
        if (-not $Updates) {
            Write-Log "No successfully installed updates found" -Level WARN
            return $null
        }
        
        return $Updates
        
    } catch {
        Write-Log "Failed to query Windows Update history: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable override
    if ($env:daysThreshold -and $env:daysThreshold -notlike "null") {
        try {
            $DaysThreshold = [int]$env:daysThreshold
            Write-Log "Using threshold from environment: $DaysThreshold days" -Level INFO
        } catch {
            Write-Log "Invalid daysThreshold environment variable, using default: $DaysThreshold" -Level WARN
        }
    }
    
    Write-Log "Update overdue threshold: $DaysThreshold days" -Level INFO
    
    # Query Windows Update history
    Write-Log "Querying Windows Update history" -Level INFO
    $LastUpdate = Get-WindowsUpdateHistory
    
    if ($LastUpdate) {
        # Calculate time differences
        $CurrentTime = (Get-Date).ToUniversalTime()
        $LastUpdateTime = $LastUpdate.Date.ToUniversalTime()
        $DaysSinceUpdate = [Math]::Floor(($CurrentTime - $LastUpdateTime).TotalDays)
        
        # Determine if overdue
        $IsOverdue = $DaysSinceUpdate -ge $DaysThreshold
        
        Write-Log "Last Update: $($LastUpdate.Title)" -Level INFO
        Write-Log "Update Date: $($LastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Level INFO
        Write-Log "Days Since Update: $DaysSinceUpdate" -Level INFO
        Write-Log "Overdue Status: $IsOverdue" -Level INFO
        
        # Format dates for NinjaRMM
        $FormattedDate = Get-Date $LastUpdateTime -Format "yyyy-MM-ddTHH:mm:ss"
        
        # Update NinjaRMM fields
        Set-NinjaField -FieldName "lastwindowsupdatedate" -Value $FormattedDate
        Set-NinjaField -FieldName "lastwindowsupdatename" -Value $LastUpdate.Title
        Set-NinjaField -FieldName "lastwindowsupdateoverdue" -Value $IsOverdue.ToString().ToLower()
        Set-NinjaField -FieldName "windowsUpdateDaysSince" -Value $DaysSinceUpdate
        
        if ($IsOverdue) {
            Write-Log "WARNING: Windows Update is OVERDUE (threshold: $DaysThreshold days)" -Level WARN
            Set-NinjaField -FieldName "windowsUpdateStatus" -Value "Overdue"
        } else {
            Write-Log "Windows Update is current" -Level SUCCESS
            Set-NinjaField -FieldName "windowsUpdateStatus" -Value "Updated"
        }
        
        Set-NinjaField -FieldName "windowsUpdateDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        Write-Log "Windows Update check completed successfully" -Level SUCCESS
        
    } else {
        Write-Log "No update history available" -Level WARN
        
        # Update status fields
        Set-NinjaField -FieldName "windowsUpdateStatus" -Value "NoHistory"
        Set-NinjaField -FieldName "lastwindowsupdateoverdue" -Value "false"
        Set-NinjaField -FieldName "windowsUpdateDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        Write-Log "No updates found in Windows Update history" -Level INFO
    }
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    # Update failure status
    Set-NinjaField -FieldName "windowsUpdateStatus" -Value "Failed"
    Set-NinjaField -FieldName "windowsUpdateDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
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
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}

# Exit with appropriate code
if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
