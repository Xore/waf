#Requires -Version 5.1

<#
.SYNOPSIS
    Complete removal of SAP GUI installations from Windows systems

.DESCRIPTION
    Performs comprehensive uninstallation of SAP GUI versions 7.30 through 8.0,
    including all components, registry entries, configuration files, and user data.
    Supports both 32-bit and 64-bit SAP GUI installations.
    
    The script:
    - Terminates SAP Logon processes
    - Uninstalls SAP GUI components using native uninstaller
    - Removes registry entries
    - Cleans up user profile data
    - Removes shared configuration files

.EXAMPLE
    .\SAP-PurgeSAPGUI.ps1
    
    Removes all SAP GUI versions and cleans up residual files.

.NOTES
    File Name      : SAP-PurgeSAPGUI.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced uninstallation process and cleanup
    - 2.0: Added support for SAP GUI 8.0
    - 1.0: Initial release
    
    Execution Context: SYSTEM (required for complete uninstallation)
    Execution Frequency: One-time or on-demand for SAP upgrades
    Typical Duration: 5-15 minutes (depends on installed versions)
    Timeout Setting: 1800 seconds (30 minutes) recommended
    
    User Interaction: Minimal (SAP Logon will close, uninstallation silent)
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

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "SAP-PurgeSAPGUI"
    
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
            Write-Log "Uninstalling $Version" -Level INFO
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        Write-Log "Terminating SAP Logon processes" -Level INFO
        $SAPProcesses = Get-Process -Name "saplogon" -ErrorAction SilentlyContinue
        
        if ($SAPProcesses) {
            $SAPProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Log "Terminated $($SAPProcesses.Count) SAP Logon process(es)" -Level SUCCESS
            Start-Sleep -Seconds 2
        } else {
            Write-Log "No SAP Logon processes running" -Level INFO
        }
        
        Write-Log "Beginning SAP GUI uninstallation" -Level INFO
        
        Write-Log "Uninstalling SAP GUI general components" -Level INFO
        
        Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\Setup\NwSapSetup.exe" `
            -Arguments '/product:"SAPWUS" /uninstall /silent /quiet /noRestart' `
            -Version "SAP WUSA"
        
        Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
            -Arguments '/product:"SCRIPTED" /uninstall /silent /quiet /noRestart' `
            -Version "SAP Scripting (x86)"
        
        Write-Log "Uninstalling SAP GUI 7.30" -Level INFO
        
        Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" `
            -Arguments '/uninstall /silent /quiet /product="ECL710+SAPDTS+BW350+KW710+GUI710ISHMED+GUI710TWEAK+JNet+SAPGUI710" /TitleComponent:"SAPGUI710" /IgnoreMissingProducts' `
            -Version "SAP GUI 7.30 Suite"
        
        Invoke-SAPUninstaller -UninstallerPath "C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" `
            -Arguments '/product:"ECL710" /uninstall /silent /quiet' `
            -Version "SAP GUI 7.30 ECL"
        
        Write-Log "Uninstalling SAP GUI 7.40" -Level INFO
        
        Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
            -Arguments '/uninstall /silent /product="SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
            -Version "SAP GUI 7.40"
        
        Write-Log "Uninstalling SAP GUI 7.50" -Level INFO
        
        Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
            -Arguments '/uninstall /silent /quiet /product="SRX+SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
            -Version "SAP GUI 7.50 (Full)"
        
        Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
            -Arguments '/uninstall /silent /quiet /product="SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
            -Version "SAP GUI 7.50 (Standard)"
        
        Write-Log "Uninstalling SAP GUI 7.60" -Level INFO
        
        Invoke-SAPUninstaller -UninstallerPath "C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" `
            -Arguments '/uninstall /silent /quiet /product="SCRIPTED+SCE+SAPDTS+KW+GUIISHMED+JNet+CALSYNC+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts' `
            -Version "SAP GUI 7.60"
        
        Write-Log "Uninstalling SAP GUI 8.0" -Level INFO
        
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
        
        Write-Log "Cleaning up registry entries" -Level INFO
        
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
                Write-Log "Registry key not found: $RegPath" -Level DEBUG
            }
        }
        
        Write-Log "Cleaning up user profile SAP folders" -Level INFO
        
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
        
        Write-Log "Cleaning up shared configuration files" -Level INFO
        
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
                Write-Log "Not found: $($Item.Path)" -Level DEBUG
            }
        }
        
        Write-Log "SAP GUI purge completed successfully" -Level SUCCESS
        
        if ($script:ErrorCount -gt 0) {
            Write-Log "Some errors occurred during uninstallation" -Level WARN
            $script:ExitCode = 1
        } else {
            $script:ExitCode = 0
        }
        
    } catch {
        Write-Log "SAP GUI purge failed: $($_.Exception.Message)" -Level ERROR
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
