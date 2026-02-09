#Requires -Version 5.1

<#
.SYNOPSIS
    Complete removal of SAP GUI installations from Windows systems

.DESCRIPTION
    Performs comprehensive uninstallation of SAP GUI versions 7.30 through 8.0,
    including all components, registry entries, configuration files, and user data.
    Supports both 32-bit and 64-bit SAP GUI installations.
    
    Technical Implementation:
    This script executes a complete SAP GUI purge by targeting multiple installation
    layers and residual artifacts:
    
    1. Process Termination:
       - Forcefully terminates saplogon.exe processes
       - Prevents file locks during uninstallation
       - Ensures clean uninstaller execution
    
    2. Uninstallation Methodology:
       The script uses NwSapSetup.exe (SAP's native uninstaller) with specific
       component product codes for each version:
       
       SAP GUI 7.30 Components:
       - ECL710 (SAP GUI Client 710)
       - SAPDTS (SAP Data Transfer Service)
       - BW350 (SAP Business Warehouse)
       - KW710 (Knowledge Warehouse)
       - GUI710ISHMED (Healthcare Industry Solution)
       - GUI710TWEAK (GUI Tweaks)
       - JNet (Java Connectivity)
       - SAPGUI710 (Main GUI Component)
       
       SAP GUI 7.40 Components:
       - SCRIPTED (Scripting Support)
       - SCE (SAP Composition Environment)
       - ECL (Easy Connect Library)
       - SAPDTS (Data Transfer Service)
       - KW (Knowledge Warehouse)
       - GUIISHMED (Healthcare Support)
       - JNet (Java Connectivity)
       - NWBCGUI (NetWeaver Business Client GUI)
       - SAPGUI (Main GUI Component)
       
       SAP GUI 7.50 Components:
       - SRX (SAP Router)
       - All 7.40 components plus enhanced features
       
       SAP GUI 7.60 Components:
       - CALSYNC (Calendar Synchronization)
       - Streamlined component set
       
       SAP GUI 8.0 Components (32-bit and 64-bit):
       - PdfPrintGui64 (PDF Printing)
       - SCRIPTED64 (64-bit Scripting)
       - KW64 (64-bit Knowledge Warehouse)
       - GUIISHMED64 (64-bit Healthcare)
       - CALSYNC64 (64-bit Calendar Sync)
       - RFC64 (64-bit Remote Function Call)
       - SAPGUI64 (64-bit Main Component)
    
    3. Uninstaller Parameters:
       /uninstall         - Triggers uninstallation mode
       /silent            - Suppresses user interface
       /quiet             - Suppresses progress dialogs
       /noRestart         - Prevents automatic system restart
       /product           - Specifies component list
       /TitleComponent    - Identifies primary component
       /IgnoreMissingProducts - Continues if components not found
    
    4. Installation Paths:
       The script targets both standard installation directories:
       - C:\Program Files\SAP (64-bit installations)
       - C:\Program Files (x86)\SAP (32-bit installations)
    
    5. Registry Cleanup:
       Removes all SAP-related registry keys:
       - HKLM:\SOFTWARE\SAP (64-bit keys)
       - HKLM:\SOFTWARE\WOW6432Node\SAP (32-bit keys on 64-bit Windows)
       These keys contain installation metadata, licensing, and configuration
    
    6. User Profile Cleanup:
       Recursively removes SAP folders from all user profiles:
       - %USERPROFILE%\AppData\Roaming\SAP
       - Includes cached logon data, connection profiles, and preferences
       - Processes all user accounts on the system
    
    7. Shared Configuration Removal:
       - C:\SAPconfig (custom configuration directory)
       - C:\Windows\SAPUILandscape.xml (landscape configuration)
       - Desktop shortcuts (SAP Logon, SAP Logon 64)
       - Start Menu folder (SAP Front End)
    
    Security Considerations:
    - Requires administrative privileges for program uninstallation
    - Forcefully terminates SAP processes (may cause data loss)
    - Removes registry keys systemwide
    - Deletes user data without backup
    - Use with caution in production environments
    
    Version Detection:
    The script attempts to uninstall all known SAP GUI versions without
    pre-detection. The /IgnoreMissingProducts flag ensures that uninstall
    attempts for non-existent versions do not cause script failure.
    
    Use Cases:
    - SAP GUI version upgrades requiring complete removal
    - Troubleshooting corrupted SAP GUI installations
    - System cleanup before SAP landscape changes
    - Standardization across multiple systems
    - License compliance (removing unauthorized installations)

.EXAMPLE
    .\SAP-PurgeSAPGUI.ps1
    
    Removes all SAP GUI versions and cleans up residual files.

.NOTES
    Script Name:    SAP-PurgeSAPGUI.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (required for complete uninstallation)
    Execution Frequency: One-time or on-demand for SAP upgrades
    Typical Duration: 5-15 minutes (depends on installed versions)
    Timeout Setting: 1800 seconds (30 minutes) recommended
    
    User Interaction: MINIMAL (SAP Logon will close, uninstallation silent)
    Restart Behavior: N/A (no automatic restart, but may be required after)
    
    Software Removed:
        - SAP GUI 7.30 (all components)
        - SAP GUI 7.40 (all components)
        - SAP GUI 7.50 (all components)
        - SAP GUI 7.60 (all components)
        - SAP GUI 8.0 (32-bit and 64-bit)
    
    Files/Folders Deleted:
        - C:\Program Files\SAP (partial)
        - C:\Program Files (x86)\SAP (partial)
        - C:\SAPconfig
        - C:\Windows\SAPUILandscape.xml
        - Desktop shortcuts
        - Start Menu shortcuts
        - User AppData\Roaming\SAP folders
    
    Registry Keys Deleted:
        - HKLM:\SOFTWARE\SAP
        - HKLM:\SOFTWARE\WOW6432Node\SAP
    
    Dependencies:
        - NwSapSetup.exe (SAP native uninstaller)
        - Administrative privileges required
    
    Exit Codes:
        0 - Success (SAP GUI purge completed)
        1 - Failure (uninstallation errors occurred)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param()

# Configuration
$ScriptVersion = "3.0"
$ScriptName = "SAP-PurgeSAPGUI"

# Initialization
$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
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

function Invoke-SAPUninstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$UninstallerPath,
        [Parameter(Mandatory=$true)]
        [string]$Arguments,
        [Parameter(Mandatory=$true)]
        [string]$Version
    )
    
    if (-not (Test-Path $UninstallerPath)) {
        Write-Log "Uninstaller not found for $Version : $UninstallerPath" -Level DEBUG
        return $false
    }
    
    try {
        Write-Log "Uninstalling $Version..." -Level INFO
        Write-Log "Command: $UninstallerPath $Arguments" -Level DEBUG
        
        $Process = Start-Process -FilePath $UninstallerPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
        
        if ($Process.ExitCode -eq 0) {
            Write-Log "$Version uninstallation completed successfully" -Level SUCCESS
            return $true
        } else {
            Write-Log "$Version uninstallation returned exit code: $($Process.ExitCode)" -Level WARN
            return $false
        }
        
    } catch {
        Write-Log "$Version uninstallation failed: $_" -Level ERROR
        $script:ErrorCount++
        return $false
    }
}

# Main Execution

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "" -Level INFO
    
    # Terminate SAP Logon processes
    Write-Log "Terminating SAP Logon processes..." -Level INFO
    $SAPProcesses = Get-Process -Name "saplogon" -ErrorAction SilentlyContinue
    
    if ($SAPProcesses) {
        $SAPProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Log "Terminated $($SAPProcesses.Count) SAP Logon process(es)" -Level SUCCESS
        Start-Sleep -Seconds 2
    } else {
        Write-Log "No SAP Logon processes running" -Level INFO
    }
    
    Write-Log "" -Level INFO
    Write-Log "Beginning SAP GUI uninstallation..." -Level INFO
    Write-Log "" -Level INFO
    
    # SAP GUI General Components
    Write-Log "Uninstalling SAP GUI general components..." -Level INFO
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\Setup\NwSapSetup.exe" `
        -Arguments '/product:"SAPWUS" /uninstall /silent /quiet /noRestart' `
        -Version "SAP WUSA"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/product:"SCRIPTED" /uninstall /silent /quiet /noRestart' `
        -Version "SAP Scripting (x86)"
    
    # SAP GUI 7.30
    Write-Log "" -Level INFO
    Write-Log "Uninstalling SAP GUI 7.30..." -Level INFO
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/uninstall /silent /quiet /product="ECL710+SAPDTS+BW350+KW710+GUI710ISHMED+GUI710TWEAK+JNet+SAPGUI710" /TitleComponent:"SAPGUI710" /IgnoreMissingProducts' `
        -Version "SAP GUI 7.30 Suite"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/product:"ECL710" /uninstall /silent /quiet' `
        -Version "SAP GUI 7.30 ECL"
    
    # SAP GUI 7.40
    Write-Log "" -Level INFO
    Write-Log "Uninstalling SAP GUI 7.40..." -Level INFO
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/uninstall /silent /product="SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
        -Version "SAP GUI 7.40"
    
    # SAP GUI 7.50
    Write-Log "" -Level INFO
    Write-Log "Uninstalling SAP GUI 7.50..." -Level INFO
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/uninstall /silent /quiet /product="SRX+SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
        -Version "SAP GUI 7.50 (Full)"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/uninstall /silent /quiet /product="SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
        -Version "SAP GUI 7.50 (Standard)"
    
    # SAP GUI 7.60
    Write-Log "" -Level INFO
    Write-Log "Uninstalling SAP GUI 7.60..." -Level INFO
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/uninstall /silent /quiet /product="SCRIPTED+SCE+SAPDTS+KW+GUIISHMED+JNet+CALSYNC+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
        -Version "SAP GUI 7.60"
    
    # SAP GUI 8.0 (64-bit and 32-bit)
    Write-Log "" -Level INFO
    Write-Log "Uninstalling SAP GUI 8.0..." -Level INFO
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/product:"SCRIPTED" /uninstall /silent /quiet /noRestart' `
        -Version "SAP GUI 8.0 Scripting (64-bit)"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/uninstall /silent /quiet /product="SCRIPTED+SCE+SAPDTS+KW+GUIISHMED+JNet+CALSYNC+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
        -Version "SAP GUI 8.0 (32-bit components)"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/uninstall /silent /quiet /product="PdfPrintGui64+SCRIPTED64+KW64+GUIISHMED64+CALSYNC64+RFC64+SAPGUI64" /TitleComponent:"SAPGUI64" /IgnoreMissingProducts' `
        -Version "SAP GUI 8.0 (64-bit suite)"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/silent /uninstall /product="PdfPrintGui64+SCRIPTED64+KW64+GUIISHMED64+CALSYNC64+RFC64+SAPGUI64" /TitleComponent:"SAPGUI64" /IgnoreMissingProducts' `
        -Version "SAP GUI 8.0 (64-bit x86 path)"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\nwsapsetup.exe" `
        -Arguments '/product:"PdfPrintGui64" /uninstall /silent' `
        -Version "SAP PDF Print (64-bit)"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/product:"SCRIPTED" /uninstall /noRestart /silent' `
        -Version "SAP Scripting (final)"
    
    Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
        -Arguments '/silent /uninstall /product="SCRIPTED+SCE+SAPDTS+KW+GUIISHMED+JNet+CALSYNC+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
        -Version "SAP GUI 8.0 (final cleanup)"
    
    # Registry cleanup
    Write-Log "" -Level INFO
    Write-Log "Cleaning up registry entries..." -Level INFO
    
    $RegistryPaths = @(
        'HKLM:\SOFTWARE\WOW6432Node\SAP',
        'HKLM:\SOFTWARE\SAP'
    )
    
    foreach ($RegPath in $RegistryPaths) {
        if (Test-Path $RegPath) {
            try {
                Remove-Item -Path $RegPath -Recurse -Force -ErrorAction Stop
                Write-Log "Removed registry key: $RegPath" -Level SUCCESS
            } catch {
                Write-Log "Failed to remove registry key $RegPath : $_" -Level WARN
            }
        } else {
            Write-Log "Registry key not found (already removed): $RegPath" -Level DEBUG
        }
    }
    
    # User profile cleanup
    Write-Log "" -Level INFO
    Write-Log "Cleaning up user profile SAP folders..." -Level INFO
    
    $UserProfilesPath = Split-Path $env:USERPROFILE -Parent
    $SAPFolderCount = 0
    
    try {
        $UserFolders = Get-ChildItem -Path $UserProfilesPath -Directory -ErrorAction SilentlyContinue
        
        foreach ($UserFolder in $UserFolders) {
            $SAPPath = Join-Path $UserFolder.FullName "AppData\Roaming\SAP"
            
            if (Test-Path $SAPPath) {
                try {
                    Remove-Item -Path $SAPPath -Recurse -Force -ErrorAction Stop
                    Write-Log "Removed SAP folder for user: $($UserFolder.Name)" -Level SUCCESS
                    $SAPFolderCount++
                } catch {
                    Write-Log "Failed to remove SAP folder for $($UserFolder.Name): $_" -Level WARN
                }
            }
        }
        
        Write-Log "Removed $SAPFolderCount user SAP folder(s)" -Level INFO
        
    } catch {
        Write-Log "Error during user profile cleanup: $_" -Level ERROR
        $script:ErrorCount++
    }
    
    # Shared configuration cleanup
    Write-Log "" -Level INFO
    Write-Log "Cleaning up shared configuration files..." -Level INFO
    
    $CleanupItems = @(
        @{Path='C:\SAPconfig'; Type='Directory'},
        @{Path='C:\Windows\SAPUILandscape.xml'; Type='File'},
        @{Path='C:\Users\Public\Desktop\SAP Logon.lnk'; Type='File'},
        @{Path='C:\Users\Public\Desktop\SAP Logon 64.lnk'; Type='File'},
        @{Path='C:\ProgramData\Microsoft\Windows\Start Menu\Programs\SAP Front End'; Type='Directory'}
    )
    
    foreach ($Item in $CleanupItems) {
        if (Test-Path $Item.Path) {
            try {
                if ($Item.Type -eq 'Directory') {
                    Remove-Item -Path $Item.Path -Recurse -Force -ErrorAction Stop
                } else {
                    Remove-Item -Path $Item.Path -Force -ErrorAction Stop
                }
                Write-Log "Removed: $($Item.Path)" -Level SUCCESS
            } catch {
                Write-Log "Failed to remove $($Item.Path): $_" -Level WARN
            }
        } else {
            Write-Log "Not found (already removed): $($Item.Path)" -Level DEBUG
        }
    }
    
    Write-Log "" -Level INFO
    Write-Log "SAP GUI purge completed successfully" -Level SUCCESS
    Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
    
    if ($script:ErrorCount -gt 0) {
        Write-Log "Some errors occurred during uninstallation" -Level WARN
        $script:ExitCode = 1
    }
    
    exit $script:ExitCode
    
} catch {
    Write-Log "SAP GUI purge failed: $($_.Exception.Message)" -Level ERROR
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "========================================" -Level INFO
}
