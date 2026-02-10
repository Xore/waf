#Requires -Version 5.1

<#
.SYNOPSIS
    Starts SAP GUI and Chrome browser for BDE workflow automation.

.DESCRIPTION
    Automates the startup sequence for Business Desktop Environment (BDE) operations
    by launching SAP GUI followed by Google Chrome browser. Validates both applications
    are installed before attempting to start them.
    
    This standardizes the startup process for users requiring both SAP GUI and
    browser-based tools as part of their daily workflow.

.PARAMETER SAPPath
    Full path to the SAP GUI executable.
    Default: C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe

.PARAMETER ChromePath
    Full path to Google Chrome executable.
    Default: C:\Program Files\Google\Chrome\Application\chrome.exe

.EXAMPLE
    BDE-StartSAPandBrowser.ps1
    Launches SAP GUI and Chrome using default installation paths.

.EXAMPLE
    BDE-StartSAPandBrowser.ps1 -SAPPath "D:\SAP\saplogon.exe" -ChromePath "C:\Program Files\Chrome\chrome.exe"
    Uses custom paths for SAP GUI and Chrome.

.NOTES
    File Name      : BDE-StartSAPandBrowser.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 format with enhanced error handling
    - 1.0: Initial version
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SAPPath = 'C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe',
    
    [Parameter()]
    [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Host $logMessage }
        }
    }
}

process {
    try {
        if ($env:sapPath -and $env:sapPath -notlike 'null') {
            $SAPPath = $env:sapPath
        }
        
        if ($env:chromePath -and $env:chromePath -notlike 'null') {
            $ChromePath = $env:chromePath
        }

        $ApplicationsStarted = 0

        if (-not (Test-Path -Path $SAPPath -ErrorAction SilentlyContinue)) {
            Write-Log "SAP GUI not found at: $SAPPath" -Level ERROR
        }
        else {
            Write-Log "Starting SAP GUI from: $SAPPath"
            Start-Process -FilePath $SAPPath -ErrorAction Stop
            Write-Log 'SAP GUI started successfully'
            $ApplicationsStarted++
        }

        Start-Sleep -Seconds 2

        if (-not (Test-Path -Path $ChromePath -ErrorAction SilentlyContinue)) {
            Write-Log "Chrome browser not found at: $ChromePath" -Level ERROR
        }
        else {
            Write-Log "Starting Chrome browser from: $ChromePath"
            Start-Process -FilePath $ChromePath -ErrorAction Stop
            Write-Log 'Chrome browser started successfully'
            $ApplicationsStarted++
        }

        if ($ApplicationsStarted -eq 2) {
            Write-Log 'BDE workflow startup complete'
            exit 0
        }
        elseif ($ApplicationsStarted -gt 0) {
            Write-Log 'BDE workflow partially started (some applications missing)' -Level WARNING
            exit 1
        }
        else {
            Write-Log 'BDE workflow startup failed (no applications started)' -Level ERROR
            exit 1
        }
    }
    catch {
        Write-Log "Failed to start BDE workflow: $_" -Level ERROR
        exit 1
    }
}

end {
    [System.GC]::Collect()
}