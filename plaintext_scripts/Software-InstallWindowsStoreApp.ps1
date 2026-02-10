#Requires -Version 5.1
#Requires -RunAsAdministrator

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
    
    This script runs unattended without user interaction.

.PARAMETER PackageID
    The Microsoft Store package identifier for the application to install.
    Supports both formats:
    - Alphanumeric Store ID: "9WZDNCRFJ3Q2"
    - Publisher.AppName format: "Microsoft.WindowsTerminal"
    
    Can be provided via parameter or $env:packageid environment variable.

.EXAMPLE
    .\Software-InstallWindowsStoreApp.ps1 -PackageID "9WZDNCRFJ3Q2"
    
    Installs Microsoft Whiteboard from Microsoft Store.

.EXAMPLE
    .\Software-InstallWindowsStoreApp.ps1 -PackageID "Microsoft.WindowsTerminal"
    
    Installs Windows Terminal from Microsoft Store using Publisher.AppName format.

.EXAMPLE
    $env:packageid = "9N0DX20HK701"
    .\Software-InstallWindowsStoreApp.ps1
    
    Uses environment variable to specify package ID for Windows Terminal.

.NOTES
    File Name      : Software-InstallWindowsStoreApp.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10 1809+, Windows Server 2019+
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards with enhanced logging and NinjaRMM integration
    - 3.0: Enhanced documentation and error handling
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: As needed (software deployment)
    Typical Duration: 30-120 seconds (depends on app size and network speed)
    Timeout Setting: 300 seconds recommended
    
    User Interaction: May show installation progress UI
    Restart Behavior: N/A (no system restart required unless app requires it)
    
    Fields Updated:
        - wingetAppInstallStatus (Success/Failed)
        - wingetAppInstallDate (timestamp)
        - wingetLastPackageID (package installed)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Windows Package Manager (winget) installed
        - App Installer from Microsoft Store
        - Internet connectivity (Microsoft Store servers)
    
    Environment Variables:
        - packageid: Override parameter via environment variable

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://learn.microsoft.com/en-us/windows/package-manager/winget/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PackageID
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-InstallWindowsStoreApp"
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:CLIFallbackCount = 0

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
        Write-Output $LogMessage
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
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

    function Test-IsElevated {
        $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
        return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if (-not (Test-IsElevated)) {
            throw "Administrator privileges required"
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        # Check environment variable override
        if ($env:packageid -and $env:packageid -notlike "null") {
            $PackageID = $env:packageid
            Write-Log "Using PackageID from environment variable: $PackageID" -Level INFO
        }
        
        # Validate PackageID is provided
        if (-not $PackageID) {
            Write-Log "Package ID is required" -Level ERROR
            Write-Log "Example package IDs:" -Level INFO
            Write-Log "  - 9WZDNCRFJ3Q2 (Microsoft Whiteboard)" -Level INFO
            Write-Log "  - 9N0DX20HK701 (Windows Terminal)" -Level INFO
            Write-Log "  - Microsoft.WindowsTerminal (Windows Terminal)" -Level INFO
            throw "Missing required parameter: PackageID"
        }
        
        Write-Log "Target package: $PackageID" -Level INFO
        
        Write-Log "Verifying winget availability" -Level INFO
        
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $wingetCmd) {
            throw "winget is not installed or not available in PATH. Please install App Installer from Microsoft Store."
        }
        
        Write-Log "winget found at: $($wingetCmd.Source)" -Level SUCCESS
        
        # Get winget version
        try {
            $wingetVersion = (winget --version) -replace '[^0-9.]', ''
            Write-Log "winget version: $wingetVersion" -Level INFO
        } catch {
            Write-Log "Could not determine winget version" -Level WARN
        }
        
        Write-Log "Starting installation from Microsoft Store" -Level INFO
        Write-Log "Installation may take 30-120 seconds depending on app size" -Level INFO
        
        # Execute winget installation
        $wingetArgs = @(
            "install",
            "-e",
            "-i",
            "--id=$PackageID",
            "--source=msstore",
            "--accept-package-agreements",
            "--accept-source-agreements"
        )
        
        Write-Log "Executing: winget $($wingetArgs -join ' ')" -Level DEBUG
        
        & winget @wingetArgs
        
        $wingetExitCode = $LASTEXITCODE
        
        # Check winget exit code
        if ($wingetExitCode -ne 0) {
            $errorMessage = "winget installation failed with exit code $wingetExitCode"
            
            # Provide helpful error messages for common exit codes
            switch ($wingetExitCode) {
                -1978335189 { 
                    $errorMessage += ": No applicable installer found for this package"
                    Write-Log $errorMessage -Level ERROR
                }
                -1978335211 { 
                    Write-Log "Package is already installed" -Level WARN
                    Write-Log "Installation considered successful (already present)" -Level SUCCESS
                    
                    Set-NinjaField -FieldName "wingetAppInstallStatus" -Value "Already Installed"
                    Set-NinjaField -FieldName "wingetAppInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    Set-NinjaField -FieldName "wingetLastPackageID" -Value $PackageID
                    
                    $ExitCode = 0
                    return
                }
                -1978335222 { 
                    $errorMessage += ": User cancelled installation"
                    Write-Log $errorMessage -Level WARN
                }
                -1978335225 { 
                    $errorMessage += ": Missing dependency required for installation"
                    Write-Log $errorMessage -Level ERROR
                }
                default { 
                    Write-Log $errorMessage -Level ERROR
                    Write-Log "Check winget documentation for exit code $wingetExitCode" -Level INFO
                }
            }
            
            throw $errorMessage
        }
        
        Write-Log "Application installed successfully: $PackageID" -Level SUCCESS
        
        Set-NinjaField -FieldName "wingetAppInstallStatus" -Value "Success"
        Set-NinjaField -FieldName "wingetAppInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Set-NinjaField -FieldName "wingetLastPackageID" -Value $PackageID
        
        $ExitCode = 0
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "wingetAppInstallStatus" -Value "Failed"
        Set-NinjaField -FieldName "wingetAppInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        if ($PackageID) {
            Set-NinjaField -FieldName "wingetLastPackageID" -Value $PackageID
        }
        
        $ExitCode = 1
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
    }
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
