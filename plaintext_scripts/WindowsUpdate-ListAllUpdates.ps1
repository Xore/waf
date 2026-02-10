#Requires -Version 5.1

<#
.SYNOPSIS
    List all installed Windows Updates with history and status

.DESCRIPTION
    Retrieves comprehensive Windows Update installation history using PSWindowsUpdate
    module. Generates an HTML table with update details including date, title, KB
    number, and installation result. Designed for NinjaRMM documentation fields.
    
    Technical Implementation:
    This script uses the PSWindowsUpdate PowerShell module to query Windows Update
    history from the Windows Update Agent (WUA) API. It provides a more reliable
    method than parsing event logs or querying Get-HotFix alone.
    
    Data Source Priority:
    1. Primary: PSWindowsUpdate Get-WUHistory cmdlet
       - Queries Windows Update Agent API directly
       - Retrieves last 2000 update entries
       - Includes all update types (Security, Driver, Definition, etc.)
       - Shows installation status (Succeeded, Failed, In Progress)
    
    Update Information Captured:
    - Date: Installation or attempt timestamp
    - Title: Full update description
    - KB: Knowledge Base article number(s)
    - Result: Installation outcome (Succeeded, Failed, etc.)
    - Operation: Install, Uninstall, or Other
    
    PSWindowsUpdate Module:
    Comprehensive third-party module for Windows Update management.
    
    Features:
    - Get-WUHistory: Retrieve update installation history
    - Supports filtering by date, KB, or title
    - Returns structured objects with detailed properties
    - Works with WSUS, Windows Update, and Microsoft Update
    
    Installation:
    - Automatically installed from PowerShell Gallery if missing
    - Requires NuGet package provider
    - Installed in CurrentUser scope to avoid permission issues
    - Uses TLS 1.2 for secure gallery connection
    
    HTML Output Generation:
    Creates Bootstrap-styled responsive table with:
    - Font Awesome icon in header
    - Sortable columns (date, title, KB, result)
    - Responsive design for mobile viewing
    - Integrated NinjaOne card styling
    
    NinjaRMM Integration:
    Results written to custom field "installedUpdates" (or configurable).
    Field should be WYSIWYG type to render HTML table correctly.
    
    Common Update Results:
    - Succeeded: Update installed successfully
    - Failed: Installation failed (check Windows Update logs)
    - In Progress: Update currently installing
    - Aborted: Installation cancelled by user or system
    - Not Started: Scheduled but not yet attempted
    
    Use Cases:
    - Compliance reporting for patch management
    - Troubleshooting failed update installations
    - Audit trail for security updates
    - Capacity planning for maintenance windows
    - Documentation for change management
    
    Performance Considerations:
    - Retrieves last 2000 updates (configurable)
    - Typical execution time: 10-30 seconds
    - May be slower on systems with large update history
    - HTML generation scales linearly with update count
    
    Limitations:
    - Requires PSWindowsUpdate module installation
    - May miss updates installed via DISM or offline methods
    - Historical data depends on Windows Update log retention
    - Very old updates may not appear in WUA history

.PARAMETER CustomField
    Name of NinjaRMM custom field to store results (default: installedUpdates)

.PARAMETER MaxUpdates
    Maximum number of updates to retrieve (default: 2000)

.EXAMPLE
    .\WindowsUpdate-ListAllUpdates.ps1
    
    Retrieves last 2000 updates and stores in default custom field.

.EXAMPLE
    .\WindowsUpdate-ListAllUpdates.ps1 -CustomField "UpdateHistory" -MaxUpdates 1000
    
    Retrieves last 1000 updates and stores in custom field "UpdateHistory".

.NOTES
    File Name      : WindowsUpdate-ListAllUpdates.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete rewrite to V3 standards with English documentation
    - 2.0: German version with basic functionality
    - 1.0: Initial release
    
    Execution Context: SYSTEM or User (works in both contexts)
    Execution Frequency: Daily or weekly for update tracking
    Typical Duration: 10-30 seconds
    Timeout Setting: 120 seconds recommended
    
    User Interaction: None (runs silently in background)
    Restart Behavior: N/A (no system restart)
    
    NinjaRMM Fields Updated:
        - installedUpdates (or custom field specified)
          Contains HTML table with update history
    
    Dependencies:
        - PSWindowsUpdate module (auto-installed from PSGallery)
        - NuGet package provider 2.8.5.201 or higher
        - Internet access to PowerShell Gallery (first run only)
        - Windows Update Agent service running
    
    Exit Codes:
        0 - Successfully retrieved and stored update history
        1 - Failed to retrieve update history or module installation failed

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://www.powershellgallery.com/packages/PSWindowsUpdate
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$CustomField = "installedUpdates",
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 5000)]
    [int]$MaxUpdates = 2000
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "WindowsUpdate-ListAllUpdates"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0

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
        Write-Output "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
        }
    }

    function Install-PSWindowsUpdate {
        [CmdletBinding()]
        param()
        
        try {
            Write-Log "Checking for PSWindowsUpdate module..." -Level INFO
            
            if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
                Write-Log "PSWindowsUpdate module already installed" -Level SUCCESS
                return $true
            }
            
            Write-Log "PSWindowsUpdate not found, installing..." -Level INFO
            
            $previousSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
            if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
                Write-Log "Installing NuGet package provider..." -Level INFO
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -Confirm:$false | Out-Null
            }
            
            $galleryInfo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
            if ($galleryInfo.InstallationPolicy -ne 'Trusted') {
                Write-Log "Setting PSGallery as trusted repository..." -Level INFO
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
            }
            
            Write-Log "Installing PSWindowsUpdate module from PowerShell Gallery..." -Level INFO
            Install-Module -Name PSWindowsUpdate -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -Confirm:$false -ErrorAction Stop
            
            [Net.ServicePointManager]::SecurityProtocol = $previousSecurityProtocol
            
            Write-Log "PSWindowsUpdate module installed successfully" -Level SUCCESS
            return $true
            
        } catch {
            Write-Log "Failed to install PSWindowsUpdate module: $($_.Exception.Message)" -Level ERROR
            return $false
        }
    }

    function Get-UpdateHistory {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [int]$MaxEntries
        )
        
        try {
            Write-Log "Retrieving last $MaxEntries Windows Updates from history..." -Level INFO
            
            $updates = Get-WUHistory -Last $MaxEntries -ErrorAction Stop | ForEach-Object {
                [PSCustomObject]@{
                    Date      = $_.Date
                    Title     = $_.Title
                    KB        = if ($_.KB) { $_.KB -join ',' } else { 'N/A' }
                    Result    = $_.Result
                    Operation = $_.Operation
                }
            }
            
            Write-Log "Retrieved $($updates.Count) update entries" -Level SUCCESS
            return $updates
            
        } catch {
            Write-Log "Failed to retrieve update history: $($_.Exception.Message)" -Level ERROR
            return $null
        }
    }

    function ConvertTo-HTMLTable {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [array]$Updates
        )
        
        $html = [System.Collections.Generic.List[string]]::new()
        
        $html.Add(@"
<div class='card flex-grow-1'>
  <div class='card-title-box'>
    <div class='card-title'><i class='fas fa-history'></i>&nbsp;&nbsp;Windows Update History</div>
  </div>
  <div class='card-body'>
    <p class='card-text'></p>
    <table>
      <thead>
        <tr>
          <th>Date</th>
          <th>Title</th>
          <th>KB</th>
          <th>Result</th>
        </tr>
      </thead>
      <tbody>
"@)
        
        foreach ($update in $Updates) {
            $html.Add("        <tr>")
            $html.Add("          <td>$($update.Date)</td>")
            $html.Add("          <td>$($update.Title)</td>")
            $html.Add("          <td>$($update.KB)</td>")
            $html.Add("          <td>$($update.Result)</td>")
            $html.Add("        </tr>")
        }
        
        $html.Add(@"
      </tbody>
    </table>
  </div>
</div>
"@)
        
        return ($html -join "`n")
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:customFieldName -and $env:customFieldName -notlike "null") {
            $CustomField = $env:customFieldName
            Write-Log "Using custom field from environment: $CustomField" -Level INFO
        }
        
        if ($env:maxUpdates -and $env:maxUpdates -notlike "null") {
            $MaxUpdates = [int]$env:maxUpdates
            Write-Log "Using max updates from environment: $MaxUpdates" -Level INFO
        }
        
        if (-not (Install-PSWindowsUpdate)) {
            Write-Log "Cannot proceed without PSWindowsUpdate module" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        Write-Log "Importing PSWindowsUpdate module..." -Level INFO
        Import-Module PSWindowsUpdate -ErrorAction Stop
        Write-Log "Module imported successfully" -Level SUCCESS
        
        $updateHistory = Get-UpdateHistory -MaxEntries $MaxUpdates
        
        if ($null -eq $updateHistory -or $updateHistory.Count -eq 0) {
            Write-Log "No update history found or failed to retrieve" -Level ERROR
            Write-Log "Possible causes: No updates installed, WUA service issue, or insufficient permissions" -Level WARN
            $script:ExitCode = 1
            return
        }
        
        $sortedUpdates = $updateHistory | Sort-Object Date -Descending
        
        Write-Log "Generating HTML table with $($sortedUpdates.Count) updates..." -Level INFO
        $htmlReport = ConvertTo-HTMLTable -Updates $sortedUpdates
        
        Write-Log "Updating NinjaRMM custom field: $CustomField" -Level INFO
        $htmlReport | Ninja-Property-Set-Piped -Name $CustomField
        
        Write-Log "Successfully updated custom field with Windows Update history" -Level SUCCESS
        Write-Log "Total updates listed: $($sortedUpdates.Count)" -Level INFO
        
        $succeededCount = ($sortedUpdates | Where-Object { $_.Result -eq 'Succeeded' }).Count
        $failedCount = ($sortedUpdates | Where-Object { $_.Result -eq 'Failed' }).Count
        
        Write-Log "Successful installations: $succeededCount" -Level INFO
        if ($failedCount -gt 0) {
            Write-Log "Failed installations: $failedCount" -Level WARN
        }
        
        $script:ExitCode = 0
        
    } catch {
        Write-Log "Windows Update history retrieval failed: $($_.Exception.Message)" -Level ERROR
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
