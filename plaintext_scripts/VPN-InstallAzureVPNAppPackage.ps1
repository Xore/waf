#Requires -Version 5.1

<#
.SYNOPSIS
    Install Azure VPN Client application package

.DESCRIPTION
    Deploys the Azure VPN Client (MSIX bundle) from a local package file.
    The Azure VPN Client enables secure point-to-site VPN connections to
    Azure Virtual Network Gateways using modern authentication methods.
    
    Technical Implementation:
    This script installs the Azure VPN Client using the Windows App Installer
    framework (Add-AppxPackage cmdlet). The deployment process:
    
    1. Package Format:
       - MSIX Bundle (.msixbundle extension)
       - Contains multiple architecture versions (ARM64, x86, x64)
       - Windows automatically selects appropriate architecture
       - Signed by Microsoft for security validation
    
    2. Installation Technology:
       Add-AppxPackage is the PowerShell cmdlet for MSIX/AppX deployment:
       - Part of Windows 10/11 native app deployment framework
       - Requires administrator privileges for system-wide installation
       - Validates package signature before installation
       - Registers app with Windows Package Manager
       - Creates Start Menu shortcuts automatically
    
    3. Package Location:
       Expected path: C:\Temp\AzureVPN\AzVpnAppx_4.0.1.0_ARM64_x86_x64.msixbundle
       
       The package file must be:
       - Pre-downloaded to local system
       - Accessible to SYSTEM account
       - Valid MSIX bundle format
       - Digitally signed by Microsoft
    
    4. Azure VPN Client Features:
       - Supports Azure Active Directory authentication
       - Certificate-based authentication
       - RADIUS authentication
       - OpenVPN and IKEv2 protocols
       - Split tunneling configuration
       - Per-app VPN policies
       - Always On VPN capability
    
    5. Version Information:
       This script targets version 4.0.1.0 of the Azure VPN Client.
       The version number is embedded in the package filename.
       
       Version 4.x includes:
       - Enhanced Azure AD integration
       - Improved connection reliability
       - Better network transition handling
       - Support for conditional access policies
    
    Prerequisites:
    - Windows 10 version 1809 or later (for MSIX support)
    - Package file must exist at specified path
    - Administrative privileges required
    - No previous version check (will upgrade if already installed)
    
    Post-Installation:
    - Application appears in Start Menu as "Azure VPN"
    - Configuration profiles must be imported separately
    - Connection profiles typically deployed via:
      * Manual import of azurevpnconfig.xml
      * Intune policy deployment
      * Group Policy configuration
    
    Package Acquisition:
    The MSIX bundle is typically obtained from:
    - Microsoft Download Center
    - Azure Portal (P2S VPN configuration download)
    - Intune app deployment
    - SCCM application package
    
    Error Scenarios:
    - Package file not found: Verify download/copy operation
    - Installation failed: Check Windows Event Log (Application)
    - Signature validation failure: Package may be corrupted
    - Insufficient permissions: Requires administrator rights
    - Incompatible OS version: Requires Windows 10 1809+
    
    Use Cases:
    - Enterprise VPN client deployment
    - Azure Virtual Network Gateway connectivity
    - Remote access to Azure resources
    - Hybrid cloud connectivity solutions
    - Zero Trust Network Access (ZTNA) implementations

.EXAMPLE
    .\VPN-InstallAzureVPNAppPackage.ps1
    
    Installs Azure VPN Client from local package file.

.NOTES
    Script Name:    VPN-InstallAzureVPNAppPackage.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (required for application installation)
    Execution Frequency: One-time deployment or upgrade scenarios
    Typical Duration: 10-30 seconds
    Timeout Setting: 180 seconds (3 minutes) recommended
    
    User Interaction: NONE (silent installation)
    Restart Behavior: N/A (no system restart required)
    
    Software Installed:
        - Azure VPN Client v4.0.1.0
        - Multi-architecture bundle (ARM64, x86, x64)
    
    Package Requirements:
        - Source: C:\Temp\AzureVPN\AzVpnAppx_4.0.1.0_ARM64_x86_x64.msixbundle
        - Size: Approximately 30-50 MB
        - Must be digitally signed by Microsoft
    
    Dependencies:
        - Windows 10 version 1809 or later
        - MSIX installation framework
        - Administrative privileges
        - Package file pre-staged to C:\Temp\AzureVPN\
    
    Exit Codes:
        0 - Success (Azure VPN Client installed)
        1 - Failure (installation error or package not found)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://learn.microsoft.com/en-us/azure/vpn-gateway/openvpn-azure-ad-client
#>

[CmdletBinding()]
param()

# Configuration
$ScriptVersion = "3.0"
$ScriptName = "VPN-InstallAzureVPNAppPackage"
$PackagePath = "C:\Temp\AzureVPN\AzVpnAppx_4.0.1.0_ARM64_x86_x64.msixbundle"

# Initialization
$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:ExitCode = 0

# Functions

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

# Main Execution

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "" -Level INFO
    
    # Verify package file exists
    Write-Log "Verifying package file..." -Level INFO
    Write-Log "Package path: $PackagePath" -Level DEBUG
    
    if (-not (Test-Path -Path $PackagePath -PathType Leaf)) {
        Write-Log "Package file not found: $PackagePath" -Level ERROR
        throw "Package file not found: $PackagePath"
    }
    
    # Get package file information
    $PackageFile = Get-Item -Path $PackagePath
    $PackageSizeMB = [math]::Round($PackageFile.Length / 1MB, 2)
    
    Write-Log "Package file verified" -Level SUCCESS
    Write-Log "Package size: $PackageSizeMB MB" -Level INFO
    Write-Log "Package modified: $($PackageFile.LastWriteTime)" -Level DEBUG
    
    # Install Azure VPN Client
    Write-Log "" -Level INFO
    Write-Log "Installing Azure VPN Client..." -Level INFO
    
    try {
        Add-AppxPackage -Path $PackagePath -ErrorAction Stop
        Write-Log "Azure VPN Client installed successfully" -Level SUCCESS
        
    } catch {
        Write-Log "AppX package installation failed" -Level ERROR
        Write-Log "Error details: $($_.Exception.Message)" -Level ERROR
        
        if ($_.ErrorDetails) {
            Write-Log "Extended details: $($_.ErrorDetails.Message)" -Level ERROR
        }
        
        throw
    }
    
    # Verify installation
    Write-Log "" -Level INFO
    Write-Log "Verifying installation..." -Level INFO
    
    $InstalledApp = Get-AppxPackage -Name "Microsoft.AzureVpn" -ErrorAction SilentlyContinue
    
    if ($InstalledApp) {
        Write-Log "Azure VPN Client detected" -Level SUCCESS
        Write-Log "Installed version: $($InstalledApp.Version)" -Level INFO
        Write-Log "Package full name: $($InstalledApp.PackageFullName)" -Level DEBUG
    } else {
        Write-Log "Azure VPN Client not detected after installation" -Level WARN
    }
    
    Write-Log "" -Level INFO
    Write-Log "Azure VPN Client installation completed successfully" -Level SUCCESS
    
    exit $script:ExitCode
    
} catch {
    Write-Log "Azure VPN Client installation failed: $($_.Exception.Message)" -Level ERROR
    $script:ExitCode = 1
    exit $script:ExitCode
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
    Write-Log "========================================" -Level INFO
}
