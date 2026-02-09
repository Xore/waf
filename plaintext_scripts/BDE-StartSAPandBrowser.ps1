#Requires -Version 5.1

<#
.SYNOPSIS
    Starts SAP GUI application and launches Chrome browser for BDE workflow.

.DESCRIPTION
    This script automates the startup sequence for BDE (Business Data Entry) operations by launching 
    SAP GUI followed by Google Chrome browser. It ensures both applications are running before 
    proceeding, providing a streamlined workflow initialization.
    
    This automation is useful for standardizing the startup process for users who require both 
    SAP GUI and browser-based tools as part of their daily workflow.

.PARAMETER SAPPath
    Full path to the SAP GUI executable. Default: C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe

.PARAMETER ChromePath
    Full path to Google Chrome executable. Default: C:\Program Files\Google\Chrome\Application\chrome.exe

.EXAMPLE
    No Parameters (uses default paths)

    [Info] Starting SAP GUI from: C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe
    [Info] SAP GUI started successfully
    [Info] Starting Chrome browser from: C:\Program Files\Google\Chrome\Application\chrome.exe
    [Info] Chrome browser started successfully
    [Info] BDE workflow startup complete

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    User interaction: Applications will launch in foreground
    Restart behavior: N/A
    Typical duration: < 5 seconds
    
.COMPONENT
    SAP GUI - SAP Logon application
    Google Chrome - Web browser
    
.LINK
    https://support.sap.com/en/product/connectors/sapgui.html

.FUNCTIONALITY
    - Validates SAP GUI installation path
    - Launches SAP Logon application
    - Validates Chrome browser installation
    - Launches Chrome browser
    - Provides startup sequence confirmation
    - Reports any missing applications or startup failures
#>

[CmdletBinding()]
param(
    [string]$SAPPath = "C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe",
    [string]$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
)

begin {
    if ($env:sapPath -and $env:sapPath -notlike "null") {
        $SAPPath = $env:sapPath
    }
    if ($env:chromePath -and $env:chromePath -notlike "null") {
        $ChromePath = $env:chromePath
    }

    $ExitCode = 0
}

process {
    try {
        if (-not (Test-Path -Path $SAPPath -ErrorAction SilentlyContinue)) {
            Write-Host "[Error] SAP GUI not found at: $SAPPath"
            $ExitCode = 1
        }
        else {
            Write-Host "[Info] Starting SAP GUI from: $SAPPath"
            Start-Process -FilePath $SAPPath -ErrorAction Stop
            Write-Host "[Info] SAP GUI started successfully"
        }

        Start-Sleep -Seconds 2

        if (-not (Test-Path -Path $ChromePath -ErrorAction SilentlyContinue)) {
            Write-Host "[Error] Chrome browser not found at: $ChromePath"
            $ExitCode = 1
        }
        else {
            Write-Host "[Info] Starting Chrome browser from: $ChromePath"
            Start-Process -FilePath $ChromePath -ErrorAction Stop
            Write-Host "[Info] Chrome browser started successfully"
        }

        if ($ExitCode -eq 0) {
            Write-Host "[Info] BDE workflow startup complete"
        }
    }
    catch {
        Write-Host "[Error] Failed to start BDE workflow: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
