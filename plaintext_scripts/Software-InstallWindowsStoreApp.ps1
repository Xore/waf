#Requires -Version 5.1

<#
.SYNOPSIS
    Installs Windows Store applications using winget package manager.

.DESCRIPTION
    Automates the installation of Microsoft Store applications using Windows Package Manager (winget).
    The script verifies winget availability, handles package agreements, and installs applications
    silently with comprehensive error handling and logging.
    
    Windows Package Manager (winget) Overview:
    Winget is Microsoft's official command-line package manager for Windows 10 1809+ and Windows 11.
    It provides centralized software management, automated installations, and version control for
    applications from multiple sources including Microsoft Store, winget repository, and custom sources.
    
    Technical Implementation:
    
    1. Prerequisites Check:
       - Verifies winget.exe is available in system PATH
       - Winget is typically installed with App Installer (Microsoft Store app)
       - Available by default on Windows 11
       - Can be manually installed on Windows 10 via App Installer or GitHub releases
    
    2. Parameter Handling:
       - Accepts PackageID via parameter or environment variable
       - Environment variable priority: $env:packageid overrides parameter
       - Validates PackageID is provided before proceeding
    
    3. Installation Process:
       - Source: msstore (Microsoft Store repository)
       - Flags used:
         * -e (--exact): Exact match for package ID
         * -i (--interactive): Interactive installation (shows progress)
         * --accept-package-agreements: Auto-accepts package license agreements
         * --accept-source-agreements: Auto-accepts source repository agreements
    
    4. Exit Code Handling:
       - Captures winget LASTEXITCODE
       - 0: Success
       - Non-zero: Installation failure (specific codes vary)
    
    Common Exit Codes from Winget:
    - 0: Success
    - -1978335189 (0x8A15000B): No applicable installer found
    - -1978335212 (0x8A150014): No applicable upgrade found
    - -1978335211 (0x8A150015): Package already installed
    - -1978335222 (0x8A15001E): User cancelled installation
    - -1978335225 (0x8A150021): Missing dependency
    
    Microsoft Store Package ID Format:
    Package IDs for Microsoft Store apps typically follow patterns:
    - Old format: 9-character alphanumeric (e.g., 9WZDNCRFJ3Q2)
    - New format: Publisher.AppName (e.g., Microsoft.WindowsTerminal)
    
    Finding Package IDs:
    1. Use winget search: winget search "app name"
    2. Microsoft Store URL: Last segment after /9 (e.g., ms-windows-store://pdp/?productid=9WZDNCRFJ3Q2)
    3. NinjaRMM documentation or package repository
    
    Common Microsoft Store Applications:
    - Windows Terminal: Microsoft.WindowsTerminal or 9N0DX20HK701
    - Microsoft Whiteboard: 9WZDNCRFJ3Q2
    - Microsoft To Do: 9NBLGGH5R558
    - PowerToys: Microsoft.PowerToys or XP89DCGQ3K6VLD
    - Xbox Game Bar: Microsoft.XboxGamingOverlay
    
    Winget Installation Behavior:
    - Downloads app from Microsoft Store servers
    - Installs to user or system context based on app manifest
    - Registers app with Windows Apps & Features
    - Creates Start Menu entries and shortcuts
    - Respects app update policies
    
    Advantages of Winget vs Manual Installation:
    - Automated silent installation
    - Version management and updates
    - Scriptable and repeatable deployments
    - No user interaction required
    - Consistent installation across multiple systems
    - Audit trail via exit codes and logs
    
    Limitations and Considerations:
    - Requires App Installer to be installed
    - Internet connectivity required (downloads from Microsoft servers)
    - Some apps may require user account (Microsoft Account)
    - Interactive flag may show progress UI despite silent intent
    - Microsoft Store service must be enabled
    
    Troubleshooting:
    
    1. Winget Not Found:
       - Install App Installer from Microsoft Store
       - Download from GitHub: https://github.com/microsoft/winget-cli/releases
       - Verify PATH includes: C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe
    
    2. Installation Fails:
       - Check internet connectivity
       - Verify Microsoft Store service is running
       - Check Windows Update service status
       - Review winget logs: %LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir
    
    3. Package Not Found:
       - Verify PackageID is correct
       - Check if app is available in your region
       - Try alternative package ID format
       - Search using: winget search "app name" --source msstore
    
    4. Access Denied:
       - Run as Administrator for system-wide installations
       - Check Group Policy restrictions on Microsoft Store
       - Verify Windows license activation status

.PARAMETER PackageID
    The Microsoft Store package identifier for the application to install.
    Supports both formats:
    - Alphanumeric Store ID: "9WZDNCRFJ3Q2"
    - Publisher.AppName format: "Microsoft.WindowsTerminal"
    
    Can be provided via parameter or $env:packageid environment variable.

.EXAMPLE
    .\Software-InstallWindowsStoreApp.ps1 -PackageID "9WZDNCRFJ3Q2"
    
    Installs Microsoft Whiteboard from Microsoft Store.
    
    Output:
    Verifying winget availability...
    winget is available
    Installing package: 9WZDNCRFJ3Q2
    Application installed successfully: 9WZDNCRFJ3Q2

.EXAMPLE
    .\Software-InstallWindowsStoreApp.ps1 -PackageID "Microsoft.WindowsTerminal"
    
    Installs Windows Terminal from Microsoft Store using Publisher.AppName format.

.EXAMPLE
    $env:packageid = "9N0DX20HK701"
    .\Software-InstallWindowsStoreApp.ps1
    
    Uses environment variable to specify package ID for Windows Terminal.

.NOTES
    Script Name:    Software-InstallWindowsStoreApp.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Minimum OS: Windows 10 1809+, Windows Server 2019+
    
    Execution Context: User or SYSTEM
    Execution Frequency: As needed (software deployment)
    Typical Duration: 30-120 seconds (depends on app size and network speed)
    Timeout Setting: 300 seconds recommended
    
    User Interaction: May show installation progress UI
    Restart Behavior: Not required (unless app requires it)
    
    NinjaRMM Fields Updated: None
    
    Dependencies:
        - Windows Package Manager (winget) installed
        - App Installer from Microsoft Store
        - Internet connectivity (Microsoft Store servers)
        - Microsoft Store service enabled
    
    Exit Codes:
        0 - Application installed successfully
        1 - Missing package ID, winget not found, or installation failed

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://learn.microsoft.com/en-us/windows/package-manager/winget/
    
.LINK
    https://learn.microsoft.com/en-us/windows/package-manager/winget/install
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PackageID
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0"
    $ScriptName = "Software-InstallWindowsStoreApp"
    $StartTime = Get-Date
    
    function Write-Log {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [ValidateSet('INFO', 'WARNING', 'ERROR')]
            [string]$Level = 'INFO'
        )
        
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR'   { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default   { Write-Host $logMessage }
        }
    }
    
    Write-Log "Starting $ScriptName v$ScriptVersion"
    
    # Check environment variable override
    if ($env:packageid -and $env:packageid -notlike "null") {
        $PackageID = $env:packageid
        Write-Log "Using PackageID from environment variable: $PackageID"
    }
    
    # Validate PackageID is provided
    if (-not $PackageID) {
        Write-Log "Package ID is required. Please specify a Microsoft Store package ID." "ERROR"
        Write-Log "Example package IDs:" "INFO"
        Write-Log "  - 9WZDNCRFJ3Q2 (Microsoft Whiteboard)" "INFO"
        Write-Log "  - 9N0DX20HK701 (Windows Terminal)" "INFO"
        Write-Log "  - Microsoft.WindowsTerminal (Windows Terminal - alternate format)" "INFO"
        exit 1
    }
}

process {
    try {
        Write-Log "Verifying winget availability..."
        
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $wingetCmd) {
            Write-Log "winget is not installed or not available in PATH." "ERROR"
            Write-Log "Please install App Installer from Microsoft Store or download from GitHub." "ERROR"
            exit 1
        }
        
        Write-Log "winget is available at: $($wingetCmd.Source)"
        
        Write-Log "Installing package: $PackageID"
        Write-Log "Source: Microsoft Store (msstore)"
        Write-Log "Installation may take 30-120 seconds depending on app size and network speed..."
        
        # Execute winget installation
        winget install -e -i --id=$PackageID --source=msstore --accept-package-agreements --accept-source-agreements
        
        # Check winget exit code
        if ($LASTEXITCODE -ne 0) {
            Write-Log "winget installation failed with exit code $LASTEXITCODE" "ERROR"
            
            # Provide helpful error messages for common exit codes
            switch ($LASTEXITCODE) {
                -1978335189 { Write-Log "No applicable installer found for this package" "ERROR" }
                -1978335211 { Write-Log "Package is already installed" "WARNING" }
                -1978335222 { Write-Log "User cancelled installation" "WARNING" }
                -1978335225 { Write-Log "Missing dependency required for installation" "ERROR" }
                default { Write-Log "Check winget documentation for exit code details" "ERROR" }
            }
            
            exit 1
        }
        
        Write-Log "Application installed successfully: $PackageID"
        exit 0
    }
    catch {
        Write-Log "Application installation failed: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

end {
    if ($StartTime) {
        $executionTime = (Get-Date) - $StartTime
        Write-Log "Script execution time: $($executionTime.TotalSeconds) seconds"
    }
    [System.GC]::Collect()
}
