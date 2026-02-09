#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Discovers and reports installed applications for all local user profiles

.DESCRIPTION
    Scans local user profiles to identify installed applications from multiple sources:
    registry (per-user uninstall keys) and AppData executables. Generates a comprehensive
    inventory report of user-installed software across all profiles.
    
    The script performs the following:
    - Enumerates all user profiles under C:\Users
    - Loads user registry hives (NTUSER.DAT) temporarily
    - Scans per-user uninstall keys for installed applications
    - Searches AppData (Local/Roaming) for executable files
    - Generates structured JSON report
    - Updates NinjaRMM custom field with findings
    
    This script runs unattended without user interaction.

.PARAMETER CustomFieldName
    Name of NinjaRMM custom field to store application inventory.
    Default: "localinstalled"

.PARAMETER ScanAppData
    Include AppData executable scanning in inventory.
    Default: $true

.EXAMPLE
    .\Software-ListInstalledApplications.ps1
    
    Scans all users with default settings.

.EXAMPLE
    .\Software-ListInstalledApplications.ps1 -CustomFieldName "userAppsInventory"
    
    Stores results in custom field "userAppsInventory".

.EXAMPLE
    .\Software-ListInstalledApplications.ps1 -ScanAppData $false
    
    Scans registry only, skips AppData executables.

.NOTES
    Script Name:    Software-ListInstalledApplications.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Weekly or on-demand
    Typical Duration: ~10-60 seconds (depends on user count)
    Timeout Setting: 180 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - [CustomFieldName] - JSON inventory of all user applications
        - appScanStatus - Status (Success/NoUsers/Failed)
        - appScanUserCount - Number of user profiles scanned
        - appScanAppCount - Total applications found
        - appScanDate - Timestamp of scan
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required for registry hive loading)
        - reg.exe command (Windows built-in)
        - Windows 10 or Server 2016 minimum
    
    Environment Variables (Optional):
        - customFieldName: Override -CustomFieldName parameter
        - scanAppData: Override -ScanAppData parameter (true/false)
    
    Exit Codes:
        0 - Success (scan completed)
        1 - Failure (scan error or no access)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name for application inventory")]
    [string]$CustomFieldName = "localinstalled",
    
    [Parameter(Mandatory=$false, HelpMessage="Include AppData executable scanning")]
    [bool]$ScanAppData = $true
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Software-ListInstalledApplications"

# User profile paths to exclude
$ExcludedProfiles = @("Public", "Default", "Default User", "All Users")

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0
$script:TotalAppsFound = 0

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes structured log messages with plain text output
    #>
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
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value with automatic fallback to CLI
    #>
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
    
    # Check character limit
    if ($ValueString.Length -gt 10000) {
        $ValueString = $ValueString.Substring(0, 9997) + "..."
        Write-Log "Field value truncated to 10,000 characters" -Level WARN
    }
    
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
    <#
    .SYNOPSIS
        Checks if script is running with Administrator privileges
    #>
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-UserRegistryApps {
    <#
    .SYNOPSIS
        Retrieves per-user installed applications from registry
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserHivePath,
        
        [Parameter(Mandatory=$true)]
        [string]$Username
    )
    
    $Apps = @()
    $HiveLoaded = $false
    
    try {
        # Generate unique hive key name
        $HiveKey = "TempHive_$Username"
        
        Write-Log "Loading registry hive for $Username" -Level DEBUG
        
        # Load user hive
        $RegLoadResult = & reg load "HKU\$HiveKey" "$UserHivePath" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to load hive: $RegLoadResult"
        }
        
        $HiveLoaded = $true
        
        # Query uninstall key
        $KeyPath = "Registry::HKEY_USERS\$HiveKey\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        
        if (Test-Path $KeyPath) {
            $Apps = Get-ChildItem $KeyPath -ErrorAction SilentlyContinue | ForEach-Object {
                $AppInfo = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                
                if ($AppInfo.DisplayName) {
                    [PSCustomObject]@{
                        Name = $AppInfo.DisplayName
                        Version = $AppInfo.DisplayVersion
                        Publisher = $AppInfo.Publisher
                        InstallLocation = $AppInfo.InstallLocation
                    }
                }
            }
            
            Write-Log "Found $($Apps.Count) applications in registry for $Username" -Level DEBUG
        }
        
    } catch {
        Write-Log "Error loading registry hive for $Username: $_" -Level WARN
        
    } finally {
        # Always attempt to unload hive
        if ($HiveLoaded) {
            $RegUnloadResult = & reg unload "HKU\$HiveKey" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Warning: Failed to unload hive for $Username" -Level WARN
            }
        }
    }
    
    return $Apps
}

function Get-UserAppDataExecutables {
    <#
    .SYNOPSIS
        Finds executable files in user AppData directories
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserProfile
    )
    
    $Executables = @()
    $Paths = @(
        "$UserProfile\AppData\Local",
        "$UserProfile\AppData\Roaming"
    )
    
    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            try {
                $Found = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue |
                    Select-Object @(
                        @{Name="Path"; Expression={$_.FullName}},
                        @{Name="LastModified"; Expression={$_.LastWriteTime.ToString("yyyy-MM-dd")}}
                    )
                
                $Executables += $Found
                
            } catch {
                Write-Log "Error scanning $Path: $_" -Level DEBUG
            }
        }
    }
    
    Write-Log "Found $($Executables.Count) executables in AppData" -Level DEBUG
    
    return $Executables
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable overrides
    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomFieldName = $env:customFieldName
        Write-Log "Using custom field from environment: $CustomFieldName" -Level INFO
    }
    
    if ($env:scanAppData -and $env:scanAppData -notlike "null") {
        $ScanAppData = [bool]::Parse($env:scanAppData)
        Write-Log "ScanAppData from environment: $ScanAppData" -Level INFO
    }
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required to load user registry hives"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # Get all user profiles
    Write-Log "Enumerating user profiles" -Level INFO
    $UserProfiles = Get-ChildItem -Path "C:\Users" -Directory -ErrorAction Stop |
        Where-Object { $_.Name -notin $ExcludedProfiles }
    
    Write-Log "Found $($UserProfiles.Count) user profile(s) to scan" -Level INFO
    
    if ($UserProfiles.Count -eq 0) {
        Write-Log "No user profiles found to scan" -Level WARN
        
        Set-NinjaField -FieldName "appScanStatus" -Value "NoUsers"
        Set-NinjaField -FieldName "appScanUserCount" -Value 0
        Set-NinjaField -FieldName "appScanDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        exit 0
    }
    
    # Scan each user profile
    $AllUsersApps = @()
    
    foreach ($UserProfile in $UserProfiles) {
        $Username = $UserProfile.Name
        $ProfilePath = $UserProfile.FullName
        $NTUserDat = Join-Path $ProfilePath "NTUSER.DAT"
        
        Write-Log "Scanning profile: $Username" -Level INFO
        
        # Get registry applications
        $RegistryApps = @()
        if (Test-Path $NTUserDat) {
            $RegistryApps = Get-UserRegistryApps -UserHivePath $NTUserDat -Username $Username
        } else {
            Write-Log "NTUSER.DAT not found for $Username" -Level WARN
        }
        
        # Get AppData executables if enabled
        $AppDataExecutables = @()
        if ($ScanAppData) {
            $AppDataExecutables = Get-UserAppDataExecutables -UserProfile $ProfilePath
        }
        
        $TotalForUser = $RegistryApps.Count + $AppDataExecutables.Count
        $script:TotalAppsFound += $TotalForUser
        
        Write-Log "User $Username: $($RegistryApps.Count) registry apps, $($AppDataExecutables.Count) executables" -Level INFO
        
        # Store user results
        $AllUsersApps += [PSCustomObject]@{
            Username = $Username
            RegistryApps = $RegistryApps
            AppDataExecutables = $AppDataExecutables
            TotalItems = $TotalForUser
        }
    }
    
    # Generate JSON report
    Write-Log "Generating application inventory report" -Level INFO
    $ReportJSON = $AllUsersApps | ConvertTo-Json -Depth 5 -Compress
    
    Write-Log "Report size: $($ReportJSON.Length) characters" -Level DEBUG
    
    # Update NinjaRMM custom field
    Set-NinjaField -FieldName $CustomFieldName -Value $ReportJSON
    
    # Update status fields
    Set-NinjaField -FieldName "appScanStatus" -Value "Success"
    Set-NinjaField -FieldName "appScanUserCount" -Value $UserProfiles.Count
    Set-NinjaField -FieldName "appScanAppCount" -Value $script:TotalAppsFound
    Set-NinjaField -FieldName "appScanDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "Application inventory completed: $script:TotalAppsFound total items across $($UserProfiles.Count) user(s)" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "appScanStatus" -Value "Failed"
    Set-NinjaField -FieldName "appScanDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "  Total Applications Found: $script:TotalAppsFound" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}

if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
