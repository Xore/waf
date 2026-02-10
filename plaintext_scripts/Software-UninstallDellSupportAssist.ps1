#Requires -Version 5.1

<#
.SYNOPSIS
    Removes Dell SupportAssist from the system.

.DESCRIPTION
    Automates the complete removal of Dell SupportAssist application from Windows systems.
    The script detects the installed version, determines the appropriate uninstallation method,
    and executes silent removal. Supports both MSI and EXE-based installations.
    
    Dell SupportAssist Versions Supported:
    - Dell SupportAssist (Consumer)
    - Dell SupportAssist for Business PCs
    - Dell SupportAssist for Home PCs
    
    Uninstallation Methods:
    
    1. MSI-based Installation:
       - Extracts GUID from registry UninstallString
       - Uses msiexec.exe /x {GUID} /qn /norestart
       - Silent uninstall without user prompts
       - No reboot required during uninstall
    
    2. EXE-based Installation (SupportAssistUninstaller.exe):
       - Uses native Dell uninstaller
       - Arguments: /arp /S /norestart
       - Silent mode with ARP (Add/Remove Programs) flag
       - Suppresses restart prompt
    
    Process Cleanup:
    After uninstallation, the script checks for and terminates any remaining
    SupportAssistClientUI.exe processes that may still be running. This ensures
    complete removal and prevents UI popups or background tasks.
    
    Registry Locations Checked:
    - HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
    - HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
    
    Related Dell SupportAssist Applications (Not Removed):
    This script specifically targets "Dell SupportAssist" only. Other related
    applications that may be present but are NOT removed:
    - Dell SupportAssist OS Recovery
    - Dell SupportAssist Remediation
    - DellInc.DellSupportAssistforPCs (Microsoft Store app)
    - SupportAssist Recovery Assistant
    - Dell SupportAssist OS Recovery Plugin for Dell Update
    - Dell SupportAssistAgent
    - Dell Update - SupportAssist Update Plugin
    
    To extend this script to remove additional components, modify the Where-Object
    filter on line 94 to include additional DisplayName values.
    
    Common Use Cases:
    - Removing bloatware from enterprise deployments
    - Preparing systems for alternative monitoring solutions
    - Troubleshooting Dell SupportAssist conflicts
    - Corporate policy compliance (removing consumer software)
    - Preventing automatic Dell driver installations
    
    Exit Code Scenarios:
    - 0: Successfully removed Dell SupportAssist
    - 1: Access denied (not running as Administrator)
    - 1: Dell SupportAssist not found on system
    - 1: Unsupported uninstallation method detected
    - 1: Uninstallation failed (non-zero msiexec exit code)

.EXAMPLE
    .\Software-UninstallDellSupportAssist.ps1
    
    Removes Dell SupportAssist if installed.
    
    Output:
    Dell SupportAssist found
    Removing Dell SupportAssist using msiexec
    Dell SupportAssist successfully removed

.NOTES
    Script Name:    Software-UninstallDellSupportAssist.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Minimum OS: Windows 10, Windows Server 2016
    
    Execution Context: SYSTEM or Administrator required
    Execution Frequency: As needed (software removal)
    Typical Duration: 30-90 seconds
    Timeout Setting: 120 seconds recommended
    
    User Interaction: NONE (runs silently)
    Restart Behavior: Not required (script suppresses reboot)
    
    NinjaRMM Fields Updated: None
    
    Dependencies:
        - Administrator privileges (mandatory)
        - Dell SupportAssist must be installed
    
    Exit Codes:
        0 - Dell SupportAssist successfully removed
        1 - Access denied, not found, or removal failed

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://www.dell.com/support/kbdoc/en-us/000177340/dell-supportassist-for-home-pcs
#>

[CmdletBinding()]
param()

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0"
    $ScriptName = "Software-UninstallDellSupportAssist"
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
    
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    
    Write-Log "Starting $ScriptName v$ScriptVersion"
}

process {
    try {
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. Please run with Administrator privileges." "ERROR"
            exit 1
        }
        
        Write-Log "Checking for Dell SupportAssist installation..."
        
        # Get UninstallString for Dell SupportAssist from the registry
        $DellSA = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -eq 'Dell SupportAssist' } | 
            # To remove additional Dell SupportAssist components, uncomment and modify below:
            # Where-Object { $_.DisplayName -eq 'Dell SupportAssist' -or $_.DisplayName -eq 'Dell SupportAssist Remediation' } |
            # Other Dell apps related to SupportAssist:
            # 'Dell SupportAssist OS Recovery'
            # 'DellInc.DellSupportAssistforPCs'
            # 'Dell SupportAssist Remediation'
            # 'SupportAssist Recovery Assistant'
            # 'Dell SupportAssist OS Recovery Plugin for Dell Update'
            # 'Dell SupportAssistAgent'
            # 'Dell Update - SupportAssist Update Plugin'
            Select-Object -Property DisplayName, UninstallString
        
        # Check if Dell SupportAssist is installed
        if (-not $DellSA) {
            Write-Log "Dell SupportAssist not found on this system" "WARNING"
            exit 1
        }
        
        Write-Log "Dell SupportAssist found: $($DellSA.DisplayName)"
        
        $DellSA | ForEach-Object {
            $App = $_
            
            # MSI-based uninstallation
            if ($App.UninstallString -match 'msiexec.exe') {
                $null = $App.UninstallString -match '{[A-F0-9-]+}'
                $guid = $matches[0]
                
                Write-Log "Removing Dell SupportAssist using msiexec (GUID: $guid)..."
                
                $Process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -PassThru
                
                if ($Process.ExitCode -ne 0) {
                    Write-Log "Error removing Dell SupportAssist. Exit Code: $($Process.ExitCode)" "ERROR"
                    exit 1
                }
                
                Write-Log "MSI uninstallation completed successfully (Exit Code: 0)"
            }
            # EXE-based uninstallation
            elseif ($App.UninstallString -match 'SupportAssistUninstaller.exe') {
                Write-Log "Removing Dell SupportAssist using SupportAssistUninstaller.exe..."
                
                $Process = Start-Process -FilePath "$($App.UninstallString)" -ArgumentList "/arp /S /norestart" -Wait -PassThru
                
                if ($Process.ExitCode -ne 0) {
                    Write-Log "Error removing Dell SupportAssist. Exit Code: $($Process.ExitCode)" "ERROR"
                    exit 1
                }
                
                Write-Log "EXE uninstallation completed successfully (Exit Code: 0)"
            }
            else {
                Write-Log "Unsupported uninstall method found: $($App.UninstallString)" "ERROR"
                exit 1
            }
        }
        
        # Check for and stop remaining processes
        Write-Log "Checking for remaining SupportAssistClientUI processes..."
        $SupportAssistClientUI = Get-Process -Name "SupportAssistClientUI" -ErrorAction SilentlyContinue
        
        if ($SupportAssistClientUI) {
            Write-Log "SupportAssistClientUI still running, stopping process..." "WARNING"
            try {
                $SupportAssistClientUI | Stop-Process -Force -Confirm:$false -ErrorAction Stop
                Write-Log "SupportAssistClientUI process stopped successfully"
            }
            catch {
                Write-Log "Failed to stop SupportAssistClientUI process. A reboot may be required to close it." "WARNING"
            }
        } else {
            Write-Log "No remaining SupportAssistClientUI processes found"
        }
        
        Write-Log "Dell SupportAssist successfully removed"
        exit 0
    }
    catch {
        Write-Log "An unexpected error occurred: $($_.Exception.Message)" "ERROR"
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
