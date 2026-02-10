#Requires -Version 5.1
#Requires -RunAsAdministrator

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

.EXAMPLE
    .\VPN-InstallAzureVPNAppPackage.ps1
    
    Installs Azure VPN Client from local package file.

.NOTES
    File Name      : VPN-InstallAzureVPNAppPackage.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10 version 1809 or later
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced error handling and verification
    - 1.0: Initial release
    
    Execution Context: SYSTEM (required for application installation)
    Execution Frequency: One-time deployment or upgrade scenarios
    Typical Duration: 10-30 seconds
    Timeout Setting: 180 seconds (3 minutes) recommended
    
    User Interaction: None (silent installation)
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
#>

[CmdletBinding()]
param()

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "VPN-InstallAzureVPNAppPackage"
    $PackagePath = "C:\Temp\AzureVPN\AzVpnAppx_4.0.1.0_ARM64_x86_x64.msixbundle"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        Write-Log "Verifying package file..." -Level INFO
        Write-Log "Package path: $PackagePath" -Level DEBUG
        
        if (-not (Test-Path -Path $PackagePath -PathType Leaf)) {
            throw "Package file not found: $PackagePath"
        }
        
        $PackageFile = Get-Item -Path $PackagePath
        $PackageSizeMB = [math]::Round($PackageFile.Length / 1MB, 2)
        
        Write-Log "Package file verified" -Level SUCCESS
        Write-Log "Package size: $PackageSizeMB MB" -Level INFO
        Write-Log "Package modified: $($PackageFile.LastWriteTime)" -Level DEBUG
        
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
        
        Write-Log "Verifying installation..." -Level INFO
        
        $InstalledApp = Get-AppxPackage -Name "Microsoft.AzureVpn" -ErrorAction SilentlyContinue
        
        if ($InstalledApp) {
            Write-Log "Azure VPN Client detected" -Level SUCCESS
            Write-Log "Installed version: $($InstalledApp.Version)" -Level INFO
            Write-Log "Package full name: $($InstalledApp.PackageFullName)" -Level DEBUG
        } else {
            Write-Log "Azure VPN Client not detected after installation" -Level WARN
        }
        
        Write-Log "Azure VPN Client installation completed successfully" -Level SUCCESS
        $script:ExitCode = 0
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
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
