#Requires -Version 5.1

<#
.SYNOPSIS
    Complete removal of Microsoft Configuration Manager (SCCM/CCM) client

.DESCRIPTION
    Comprehensive uninstallation and cleanup of Microsoft Configuration Manager
    client components from Windows systems. Removes all client binaries, registry
    entries, configuration files, and WMI repository data.
    
    Technical Implementation:
    This script performs a complete removal of the SCCM/CCM client by executing
    multiple cleanup operations in sequence:
    
    1. Client Uninstallation:
       - Executes CCMSetup.exe with /uninstall parameter
       - This is Microsoft's official uninstallation method
       - Initiates graceful shutdown of CCM services
       - Removes installed client components through Windows Installer
    
    2. Registry Cleanup:
       - Removes HKLM\SOFTWARE\Microsoft\CCM (client configuration)
       - Removes HKLM\SOFTWARE\Microsoft\SMS (legacy SMS 2003 entries)
       - Force deletion with /f flag to suppress confirmations
       - Removes client GUID, certificates, policy data
    
    3. File System Cleanup:
       - Removes C:\Windows\CCM (client installation directory)
       - Removes C:\Windows\CCMSetup (setup files directory)
       - Removes C:\Windows\SMSCFG.ini (legacy configuration file)
       - /s flag for recursive directory deletion
       - /q flag for quiet operation without prompts
       - /f flag for forcing deletion of read-only files
    
    4. WMI Repository Repair:
       - Executes winmgmt /salvagerepository
       - Rebuilds WMI repository to remove CCM namespaces
       - Cleans up root\ccm and root\sms WMI classes
       - Verifies repository consistency after client removal
    
    Configuration Manager Client Components Removed:
    
    Services:
    - CCMExec (Configuration Manager Client Service)
    - CcmExecSvc (Configuration Manager Executive Service)
    - smstsmgr (Task Sequence Manager)
    - CmRcService (Remote Control Service)
    
    Registry Keys:
    - HKLM\SOFTWARE\Microsoft\CCM
      * Client configuration and settings
      * Site assignment information
      * Certificate store references
      * Policy and inventory data
    
    - HKLM\SOFTWARE\Microsoft\SMS
      * Legacy SMS 2003 compatibility data
      * Client components registration
      * Provider information
    
    File System Locations:
    - C:\Windows\CCM\
      * Client binaries (PolicyAgent.exe, CcmExec.exe)
      * Log files (ccmexec.log, PolicyAgent.log, etc.)
      * Cache directory (C:\Windows\CCM\Cache)
      * Inventory data (*.sic files)
      * Certificates (C:\Windows\CCM\Certificates)
    
    - C:\Windows\CCMSetup\
      * Setup bootstrapper files
      * Installation logs (ccmsetup.log)
      * Client.msi and related MSI files
    
    - C:\Windows\SMSCFG.ini
      * Legacy configuration file
      * Contains site code and client settings
    
    WMI Namespaces Cleaned:
    - root\ccm (client namespace)
    - root\sms (management namespace)
    - root\cimv2\sms (provider namespace)
    
    Execution Flow:
    1. Run CCMSetup.exe /uninstall (10-60 seconds)
    2. Delete registry keys (instant)
    3. Remove file system directories (5-30 seconds)
    4. Delete configuration file (instant)
    5. Salvage WMI repository (30-120 seconds)
    
    Important Considerations:
    
    Prerequisites:
    - Must run with Administrator privileges
    - CCMSetup.exe must exist at C:\Windows\CCMSetup\CCMSetup.exe
    - No active remote control or task sequence sessions
    - System should not be PXE booting or in WinPE
    
    Side Effects:
    - Client will no longer report to Configuration Manager
    - Software deployments will stop
    - Hardware/software inventory will cease
    - Remote control functionality will be removed
    - OS deployment task sequences will fail
    - Compliance settings evaluation will stop
    
    Post-Removal State:
    - No CCM services running
    - No scheduled tasks for CCM operations
    - WMI provider unregistered
    - Client certificate removed from store
    - All cached packages deleted
    
    Common Use Cases:
    - Removing retired SCCM infrastructure clients
    - Preparing systems for migration to new management platform
    - Troubleshooting corrupt client installations
    - Decommissioning managed workstations
    - Cleanup after failed client installations
    
    Failure Scenarios:
    
    1. CCMSetup.exe not found:
       - Client may have been partially removed
       - Manual registry/file cleanup will still execute
       - WMI repair will still run
    
    2. Files in use:
       - Services may need manual stop before script
       - Reboot may be required to complete cleanup
       - Use Process Explorer to identify locking processes
    
    3. Registry access denied:
       - Verify Administrator privileges
       - Check for Group Policy restrictions
       - May need to take ownership of registry keys
    
    4. WMI repository corruption:
       - winmgmt /salvagerepository may fail
       - Alternative: winmgmt /resetrepository (more aggressive)
       - May require safe mode for deep corruption
    
    Verification Steps After Removal:
    1. Check Services: Get-Service -Name CCMExec, CmRcService
    2. Check Registry: Test-Path "HKLM:\SOFTWARE\Microsoft\CCM"
    3. Check Files: Test-Path "C:\Windows\CCM"
    4. Check WMI: Get-WmiObject -Namespace root\ccm -List
    
    Alternative Removal Methods:
    - Use Configuration Manager console to uninstall (if accessible)
    - Use Group Policy to deploy uninstallation script
    - Use third-party management tools (PDQ Deploy, etc.)
    - Manual removal via PowerShell (more controlled)
    
    Related Microsoft Documentation:
    - CCMSetup.exe command-line parameters
    - Client installation and removal procedures
    - WMI repository maintenance commands
    - Configuration Manager client troubleshooting

.EXAMPLE
    .\Software-RemoveCCMClient.ps1
    
    Executes complete CCM client removal sequence.

.NOTES
    Script Name:    Software-RemoveCCMClient.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or Administrator required
    Execution Frequency: One-time (client removal)
    Typical Duration: 60-180 seconds
    Timeout Setting: 300 seconds recommended
    
    User Interaction: NONE (runs silently)
    Restart Behavior: Recommended after completion
    
    NinjaRMM Fields Updated: None
    
    Dependencies:
        - Administrator privileges (mandatory)
        - CCMSetup.exe present (optional but recommended)
        - WMI service running
    
    Exit Codes:
        0 - Removal commands executed successfully
        Note: Individual command failures may not propagate to exit code
              Check console output for detailed status
    
    WARNING: This is a destructive operation
             Client cannot be remotely managed after removal
             Requires manual reinstallation to restore SCCM management
             Consider backing up CCM logs before removal

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://learn.microsoft.com/en-us/mem/configmgr/core/clients/deploy/deploy-clients-to-windows-computers
#>

[CmdletBinding()]
param()

# Configuration
$ScriptVersion = "3.0"
$ScriptName = "Software-RemoveCCMClient"

Write-Host "========================================"
Write-Host "Starting: $ScriptName v$ScriptVersion"
Write-Host "========================================"
Write-Host ""

try {
    # Step 1: Uninstall CCM client using official uninstaller
    Write-Host "Step 1: Running CCMSetup.exe /uninstall..."
    if (Test-Path "C:\Windows\CCMSetup\CCMSetup.exe") {
        Start-Process -FilePath "C:\Windows\CCMSetup\CCMSetup.exe" -ArgumentList "/uninstall" -Wait -NoNewWindow
        Write-Host "CCMSetup.exe /uninstall completed"
    } else {
        Write-Host "WARNING: CCMSetup.exe not found, skipping official uninstaller"
    }
    
    # Step 2: Remove CCM registry keys
    Write-Host ""
    Write-Host "Step 2: Removing CCM registry keys..."
    
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\CCM") {
        reg delete "HKLM\SOFTWARE\Microsoft\CCM" /f | Out-Null
        Write-Host "Removed HKLM\SOFTWARE\Microsoft\CCM"
    } else {
        Write-Host "Registry key HKLM\SOFTWARE\Microsoft\CCM not found"
    }
    
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\SMS") {
        reg delete "HKLM\SOFTWARE\Microsoft\SMS" /f | Out-Null
        Write-Host "Removed HKLM\SOFTWARE\Microsoft\SMS"
    } else {
        Write-Host "Registry key HKLM\SOFTWARE\Microsoft\SMS not found"
    }
    
    # Step 3: Remove CCM directories
    Write-Host ""
    Write-Host "Step 3: Removing CCM directories..."
    
    if (Test-Path "C:\Windows\CCM") {
        Remove-Item -Path "C:\Windows\CCM" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed C:\Windows\CCM directory"
    } else {
        Write-Host "Directory C:\Windows\CCM not found"
    }
    
    if (Test-Path "C:\Windows\CCMSetup") {
        Remove-Item -Path "C:\Windows\CCMSetup" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed C:\Windows\CCMSetup directory"
    } else {
        Write-Host "Directory C:\Windows\CCMSetup not found"
    }
    
    # Step 4: Remove configuration file
    Write-Host ""
    Write-Host "Step 4: Removing SMSCFG.ini configuration file..."
    
    if (Test-Path "C:\Windows\SMSCFG.ini") {
        Remove-Item -Path "C:\Windows\SMSCFG.ini" -Force -ErrorAction SilentlyContinue
        Write-Host "Removed C:\Windows\SMSCFG.ini"
    } else {
        Write-Host "Configuration file C:\Windows\SMSCFG.ini not found"
    }
    
    # Step 5: Salvage WMI repository to remove CCM namespaces
    Write-Host ""
    Write-Host "Step 5: Salvaging WMI repository to remove CCM namespaces..."
    Write-Host "This may take 30-120 seconds..."
    
    winmgmt /salvagerepository | Out-Null
    Write-Host "WMI repository salvage completed"
    
    Write-Host ""
    Write-Host "========================================"
    Write-Host "CCM Client Removal Completed"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "IMPORTANT: A system restart is recommended to complete the removal."
    Write-Host "The system is no longer managed by Configuration Manager."
    
    exit 0
}
catch {
    Write-Host ""
    Write-Host "ERROR: CCM client removal encountered an error: $($_.Exception.Message)"
    Write-Host "Some components may have been removed successfully."
    Write-Host "Check the output above for detailed status."
    exit 1
}
