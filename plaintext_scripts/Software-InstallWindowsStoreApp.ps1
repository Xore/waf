#Requires -Version 5.1

<#
.SYNOPSIS
    Installs Windows Store applications using winget package manager.

.DESCRIPTION
    This script installs applications from the Microsoft Store using the Windows Package Manager 
    (winget). It verifies winget availability, accepts package agreements, and installs the 
    specified application by package ID.
    
    Winget is Microsoft's official command-line package manager for Windows 10 and later, providing 
    automated software installation and management capabilities. This script specifically targets 
    Microsoft Store applications using the msstore source.

.PARAMETER PackageID
    The Microsoft Store package identifier for the application to install.
    Example: "9WZDNCRFJ3Q2" for Microsoft Whiteboard

.EXAMPLE
    -PackageID "9WZDNCRFJ3Q2"

    Verifying winget availability...
    Installing package: 9WZDNCRFJ3Q2
    Application installed successfully: 9WZDNCRFJ3Q2

.EXAMPLE
    No Parameters (uses environment variable)
    
    Verifying winget availability...
    Installing package from environment: Microsoft.WindowsTerminal
    Application installed successfully: Microsoft.WindowsTerminal

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2019
    Release notes: Initial release for WAF v3.0
    
.COMPONENT
    winget - Windows Package Manager CLI
    
.LINK
    https://learn.microsoft.com/en-us/windows/package-manager/winget/
    https://learn.microsoft.com/en-us/windows/package-manager/winget/install

.FUNCTIONALITY
    - Verifies winget availability in system PATH
    - Installs Microsoft Store applications by package ID
    - Accepts package and source agreements automatically
    - Uses exact match installation (-e flag)
    - Provides interactive installation mode (-i flag)
    - Validates installation success via exit codes
#>

[CmdletBinding()]
param(
    [string]$PackageID
)

begin {
    if ($env:packageid -and $env:packageid -notlike "null") {
        $PackageID = $env:packageid
    }

    if (-not $PackageID) {
        Write-Host "[Error] Package ID is required. Please specify a Microsoft Store package ID."
        Write-Host "[Info] Example package IDs:"
        Write-Host "       - 9WZDNCRFJ3Q2 (Microsoft Whiteboard)"
        Write-Host "       - 9N0DX20HK701 (Windows Terminal)"
        exit 1
    }

    $ExitCode = 0
}

process {
    try {
        Write-Host "[Info] Verifying winget availability..."
        if (-not (Get-Command winget -ErrorAction Stop)) {
            throw "winget is not installed or not available in PATH."
        }
        Write-Host "[Info] winget is available"

        Write-Host "[Info] Installing package: $PackageID"
        Write-Host "[Info] Source: Microsoft Store (msstore)"
        
        winget install -e -i --id=$PackageID --source=msstore --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -ne 0) {
            throw "winget installation failed with exit code $LASTEXITCODE."
        }

        Write-Host "[Info] Application installed successfully: $PackageID"
        $ExitCode = 0
    }
    catch {
        Write-Host "[Error] Application installation failed: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
