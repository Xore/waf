#Requires -Version 5.1

<#
.SYNOPSIS
    Configure Windows Explorer hidden files visibility for users

.DESCRIPTION
    Manages the Windows Explorer registry setting that controls whether hidden files
    and folders are visible in File Explorer. Supports both single-user (current logged
    on user) and system-wide (all users) deployment modes.
    
    Technical Implementation:
    The script modifies the following registry value for each target user:
    HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Hidden
    
    Values:
    - 1 = Show hidden files and folders (VISIBLE)
    - 2 = Do not show hidden files and folders (HIDDEN)
    
    Execution Context Behavior:
    
    1. Run as SYSTEM (via RMM):
       - Affects all user profiles on the computer
       - Loads and modifies each user's NTUSER.DAT registry hive
       - Includes logged-on and logged-off users
       - Does NOT affect Default user profile unless explicitly included
    
    2. Run as Current User:
       - Affects only the currently logged-on user
       - Modifies HKEY_CURRENT_USER directly
       - No registry hive loading required
    
    Registry Hive Loading Process:
    When run as SYSTEM, the script:
    1. Enumerates user SIDs from ProfileList registry key
    2. Identifies which NTUSER.DAT files are not currently loaded
    3. Mounts unloaded hives to HKEY_USERS\<SID> using reg.exe
    4. Applies changes to all mounted and existing hives
    5. Unmounts temporarily loaded hives after changes complete
    
    Explorer Restart Behavior:
    Changes take effect immediately for File Explorer windows opened AFTER the change.
    Existing Explorer windows show the old setting until refreshed. The -RestartExplorer
    switch forces all Explorer.exe processes to restart:
    
    - As SYSTEM: Restarts Explorer for ALL logged-on users
    - As User: Restarts Explorer only for current user session
    - Users will see their Explorer windows close and reopen
    - May cause brief visual disruption (desktop icons reload)
    
    Use Cases:
    - IT troubleshooting (enable to see hidden system files)
    - Security hardening (disable to prevent casual file system exploration)
    - User training environments (ensure consistency)
    - Compliance requirements (standardize Explorer behavior)

.PARAMETER Action
    Specify whether to Enable or Disable showing hidden files and folders.
    Valid values: "Enable", "Disable"

.PARAMETER RestartExplorer
    If specified, restarts Explorer.exe to apply changes immediately.
    Without this, users must manually restart Explorer or log off/on.

.EXAMPLE
    .\Explorer-SetShowHiddenFiles.ps1 -Action "Enable"
    
    Shows hidden files for current user (if run as user) or all users (if run as SYSTEM).

.EXAMPLE
    .\Explorer-SetShowHiddenFiles.ps1 -Action "Disable" -RestartExplorer
    
    Hides hidden files and restarts Explorer immediately.

.EXAMPLE
    .\Explorer-SetShowHiddenFiles.ps1 -Action "Enable"
    
    When run via NinjaRMM as SYSTEM, affects all user profiles.

.NOTES
    Script Name:    Explorer-SetShowHiddenFiles.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: User or SYSTEM (both supported)
    Execution Frequency: One-time or policy enforcement
    Typical Duration: ~2-5 seconds (plus Explorer restart time if requested)
    Timeout Setting: 60 seconds recommended (allows for Explorer restart)
    
    User Interaction: MINIMAL (Explorer windows close/reopen if restart enabled)
    Restart Behavior: N/A (no system restart required)
    
    Registry Modified:
        - Per-User: HKEY_USERS\<SID>\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Hidden
        - Current User equivalent: HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Hidden
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - No elevation required (works as standard user for current user mode)
        - SYSTEM context required for all-users mode
    
    Exit Codes:
        0 - Success (settings applied)
        1 - Failure (invalid action, no profiles found, or Explorer restart error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Action: Enable or Disable showing hidden files")]
    [ValidateSet('Enable','Disable')]
    [string]$Action,
    
    [Parameter(Mandatory=$false, HelpMessage="Restart Explorer to apply changes immediately")]
    [switch]$RestartExplorer
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Explorer-SetShowHiddenFiles"

# Support NinjaRMM environment variables
if ($env:action -and $env:action -ne "null") {
    $Action = $env:action
}

if ($env:restartExplorer) {
    $RestartExplorer = [System.Convert]::ToBoolean($env:restartExplorer)
}

# Validate action parameter
if ($Action) {
    $Action = $Action.Trim()
}

if (-not $Action) {
    Write-Output "[ERROR] Action parameter required. Specify 'Enable' or 'Disable'."
    exit 1
}

if ($Action -notin @('Enable','Disable')) {
    Write-Output "[ERROR] Invalid action '$Action'. Valid values: Enable, Disable"
    exit 1
}

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:ExitCode = 0

# ============================================================================
# FUNCTIONS
# ============================================================================

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

function Test-IsSystem {
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    return ($Identity.Name -like "NT AUTHORITY*" -or $Identity.IsSystem)
}

function Get-UserProfiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('AzureAD','DomainAndLocal','All')]
        [string]$Type = 'All'
    )
    
    $Patterns = switch ($Type) {
        'AzureAD' { @('S-1-12-1-(\d+-?){4}$') }
        'DomainAndLocal' { @('S-1-5-21-(\d+-?){4}$') }
        'All' { @('S-1-12-1-(\d+-?){4}$', 'S-1-5-21-(\d+-?){4}$') }
    }
    
    $Profiles = New-Object System.Collections.Generic.List[Object]
    
    foreach ($Pattern in $Patterns) {
        try {
            $Items = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" -ErrorAction Stop |
                Where-Object { $_.PSChildName -match $Pattern }
            
            foreach ($Item in $Items) {
                $Profile = [PSCustomObject]@{
                    SID = $Item.PSChildName
                    Username = Split-Path $Item.ProfileImagePath -Leaf
                    UserHive = Join-Path $Item.ProfileImagePath "NTUSER.DAT"
                    Path = $Item.ProfileImagePath
                }
                $Profiles.Add($Profile)
            }
        } catch {
            Write-Log "Failed to enumerate profiles for pattern $Pattern : $_" -Level WARN
        }
    }
    
    return $Profiles
}

function Set-RegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        $Value,
        [Parameter(Mandatory=$false)]
        [ValidateSet('String','ExpandString','Binary','DWord','MultiString','QWord')]
        [string]$Type = 'DWord'
    )
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            Write-Log "Created registry path: $Path" -Level DEBUG
        }
        
        $CurrentValue = $null
        try {
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
        } catch {}
        
        if ($null -ne $CurrentValue) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -ErrorAction Stop | Out-Null
            $NewValue = (Get-ItemProperty -Path $Path -Name $Name).$Name
            Write-Log "$Path\$Name: $CurrentValue -> $NewValue" -Level INFO
        } else {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
            $NewValue = (Get-ItemProperty -Path $Path -Name $Name).$Name
            Write-Log "$Path\$Name: Created with value $NewValue" -Level INFO
        }
        
        return $true
        
    } catch {
        Write-Log "Failed to set $Path\$Name : $_" -Level ERROR
        return $false
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    $IsSystem = Test-IsSystem
    $ActionVerb = if ($Action -eq 'Enable') { 'Enabling' } else { 'Disabling' }
    $RegistryValue = if ($Action -eq 'Enable') { 1 } else { 2 }
    
    Write-Log "Action: $ActionVerb show hidden files" -Level INFO
    Write-Log "Context: $(if ($IsSystem) {'SYSTEM (all users)'} else {'Current user only'})" -Level INFO
    Write-Log "Restart Explorer: $(if ($RestartExplorer) {'Yes'} else {'No'})" -Level INFO
    Write-Log "" -Level INFO
    
    # Get target user profiles
    if ($IsSystem) {
        $UserProfiles = Get-UserProfiles -Type 'All'
        Write-Log "Found $($UserProfiles.Count) user profile(s) to process" -Level INFO
    } else {
        $UserProfiles = Get-UserProfiles -Type 'All' | 
            Where-Object { $_.SID -eq [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value }
        
        if (-not $UserProfiles) {
            Write-Log "Could not identify current user profile" -Level ERROR
            exit 1
        }
        
        Write-Log "Processing current user only: $($UserProfiles.Username)" -Level INFO
    }
    
    if ($UserProfiles.Count -eq 0) {
        Write-Log "No user profiles found to process" -Level ERROR
        exit 1
    }
    
    # Track which hives we load (so we can unload them later)
    $LoadedHives = New-Object System.Collections.Generic.List[Object]
    
    # Load registry hives for users not currently logged in
    Write-Log "" -Level INFO
    Write-Log "Loading registry hives..." -Level INFO
    
    foreach ($Profile in $UserProfiles) {
        $HivePath = "Registry::HKEY_USERS\$($Profile.SID)"
        
        if (-not (Test-Path $HivePath)) {
            if (Test-Path $Profile.UserHive) {
                Write-Log "Loading hive for $($Profile.Username) ($($Profile.SID))" -Level DEBUG
                $LoadResult = Start-Process -FilePath "reg.exe" -ArgumentList "LOAD","HKU\$($Profile.SID)","`"$($Profile.UserHive)`"" -Wait -WindowStyle Hidden -PassThru
                
                if ($LoadResult.ExitCode -eq 0) {
                    $LoadedHives.Add($Profile)
                    Write-Log "Successfully loaded hive for $($Profile.Username)" -Level DEBUG
                } else {
                    Write-Log "Failed to load hive for $($Profile.Username) (exit code: $($LoadResult.ExitCode))" -Level WARN
                }
            } else {
                Write-Log "Hive file not found for $($Profile.Username): $($Profile.UserHive)" -Level WARN
            }
        } else {
            Write-Log "Hive already loaded for $($Profile.Username)" -Level DEBUG
        }
    }
    
    # Apply registry changes
    Write-Log "" -Level INFO
    Write-Log "Applying registry changes..." -Level INFO
    
    $SuccessCount = 0
    $SkippedCount = 0
    
    foreach ($Profile in $UserProfiles) {
        $RegPath = "Registry::HKEY_USERS\$($Profile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        
        if (-not (Test-Path "Registry::HKEY_USERS\$($Profile.SID)")) {
            Write-Log "Skipping $($Profile.Username) (hive not accessible)" -Level WARN
            $SkippedCount++
            continue
        }
        
        $CurrentValue = $null
        try {
            $CurrentValue = (Get-ItemProperty -Path $RegPath -Name "Hidden" -ErrorAction Stop).Hidden
        } catch {}
        
        if ($CurrentValue -eq $RegistryValue) {
            Write-Log "User '$($Profile.Username)' already configured correctly (value=$CurrentValue)" -Level INFO
            $SkippedCount++
            continue
        }
        
        Write-Log "Processing user: $($Profile.Username)" -Level INFO
        $Result = Set-RegistryValue -Path $RegPath -Name "Hidden" -Value $RegistryValue -Type 'DWord'
        
        if ($Result) {
            $SuccessCount++
        } else {
            $script:ExitCode = 1
        }
    }
    
    # Unload registry hives
    if ($LoadedHives.Count -gt 0) {
        Write-Log "" -Level INFO
        Write-Log "Unloading registry hives..." -Level INFO
        
        [System.GC]::Collect()
        Start-Sleep -Seconds 1
        
        foreach ($Profile in $LoadedHives) {
            Write-Log "Unloading hive for $($Profile.Username)" -Level DEBUG
            $UnloadResult = Start-Process -FilePath "reg.exe" -ArgumentList "UNLOAD","HKU\$($Profile.SID)" -Wait -WindowStyle Hidden -PassThru
            
            if ($UnloadResult.ExitCode -ne 0) {
                Write-Log "Warning: Failed to unload hive for $($Profile.Username) (exit code: $($UnloadResult.ExitCode))" -Level WARN
            }
        }
    }
    
    # Restart Explorer if requested
    if ($RestartExplorer) {
        Write-Log "" -Level INFO
        Write-Log "Restarting Explorer.exe..." -Level INFO
        
        try {
            if ($IsSystem) {
                $ExplorerProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
            } else {
                $CurrentSessionId = (Get-Process -PID $PID).SessionId
                $ExplorerProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue | 
                    Where-Object { $_.SessionId -eq $CurrentSessionId }
            }
            
            if ($ExplorerProcesses) {
                $ExplorerProcesses | Stop-Process -Force -ErrorAction Stop
                Write-Log "Stopped $($ExplorerProcesses.Count) Explorer process(es)" -Level SUCCESS
                Start-Sleep -Seconds 2
            }
            
            if (-not $IsSystem) {
                if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
                    Start-Process -FilePath "$env:SystemRoot\explorer.exe" -ErrorAction Stop
                    Write-Log "Started Explorer.exe for current user" -Level SUCCESS
                }
            }
            
        } catch {
            Write-Log "Failed to restart Explorer: $_" -Level ERROR
            $script:ExitCode = 1
        }
    } else {
        Write-Log "" -Level INFO
        Write-Log "Explorer restart not requested. Changes will take effect:" -Level WARN
        Write-Log "  - Immediately for new Explorer windows" -Level WARN
        Write-Log "  - After Explorer restart or logoff/logon for existing windows" -Level WARN
    }
    
    # Final summary
    Write-Log "" -Level INFO
    Write-Log "Operation Summary:" -Level SUCCESS
    Write-Log "  Total Profiles: $($UserProfiles.Count)" -Level INFO
    Write-Log "  Successfully Changed: $SuccessCount" -Level INFO
    Write-Log "  Already Correct: $SkippedCount" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    
    exit $script:ExitCode
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "========================================" -Level INFO
}
