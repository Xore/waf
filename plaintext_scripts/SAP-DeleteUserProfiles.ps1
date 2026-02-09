#Requires -Version 5.1

<#
.SYNOPSIS
    Remove SAP user profile data from all user accounts

.DESCRIPTION
    Recursively deletes SAP folders from AppData\Roaming for all user profiles
    on the system. This removes cached SAP logon data, connection profiles,
    and user-specific SAP GUI configurations.
    
    Technical Implementation:
    The script enumerates all user profile directories and removes SAP-specific
    data stored in the Roaming profile folder. This is commonly needed when:
    
    1. SAP GUI Cleanup Operations:
       - After SAP GUI uninstallation
       - Before SAP landscape changes
       - When troubleshooting connection issues
       - During user account migrations
    
    2. Data Locations:
       SAP stores user-specific data in:
       - %APPDATA%\SAP (C:\Users\<username>\AppData\Roaming\SAP)
       
       This folder typically contains:
       - SAP Logon connection data (*.sap files)
       - SAP GUI configuration (GuiConfig.xml)
       - Cached landscape configuration
       - User preferences and settings
       - Session history and shortcuts
    
    3. Profile Enumeration:
       The script:
       - Identifies all user profile directories
       - Constructs path to AppData\Roaming\SAP for each user
       - Attempts deletion even if user not currently logged in
       - Handles both active and inactive user accounts
    
    4. Deletion Methodology:
       - Uses Remove-Item with -Recurse for complete folder removal
       - -Force flag removes read-only and hidden files
       - Continues on error (doesn't fail entire script if one user fails)
       - Reports success/failure for each user profile processed
    
    Profile Discovery:
    User profiles are discovered by enumerating subdirectories under
    C:\Users (or equivalent system drive path). The script specifically
    targets the Roaming folder within each user's AppData directory.
    
    Security Considerations:
    - Requires administrative privileges to access other user profiles
    - Deletes data without backup or confirmation
    - May affect currently logged-on users (files in use may fail)
    - Cannot be undone (no recycle bin for programmatic deletion)
    
    Data Impact:
    Users will lose:
    - Saved SAP connection profiles
    - SAP Logon shortcuts
    - Custom GUI settings and preferences
    - Cached landscape data
    - Session history
    
    After running this script, users must:
    - Reconfigure SAP Logon connections
    - Import landscape configuration (if available)
    - Recreate any custom settings
    
    Use Cases:
    - SAP GUI version upgrades requiring profile reset
    - Troubleshooting SAP connection issues
    - Standardizing SAP configurations across users
    - Preparing systems for SAP landscape changes
    - Cleaning up after SAP decommissioning

.EXAMPLE
    .\SAP-DeleteUserProfiles.ps1
    
    Removes SAP folders from all user profiles on the system.

.NOTES
    Script Name:    SAP-DeleteUserProfiles.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (required to access all user profiles)
    Execution Frequency: One-time or on-demand for SAP cleanup
    Typical Duration: 1-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (runs silently, no user notification)
    Restart Behavior: N/A (no system restart required)
    
    Folders Deleted:
        - C:\Users\*\AppData\Roaming\SAP (for all users)
    
    Data Impact:
        - SAP Logon connection profiles (lost)
        - SAP GUI user settings (lost)
        - Cached landscape configuration (lost)
        - No system-wide SAP configuration affected
    
    Dependencies:
        - Administrative privileges required
        - No specific software dependencies
    
    Exit Codes:
        0 - Success (SAP user profiles deleted)
        1 - Failure (error during deletion)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param()

# Configuration
$ScriptVersion = "3.0"
$ScriptName = "SAP-DeleteUserProfiles"

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

# Main Execution

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "" -Level INFO
    
    # Locate user profiles directory
    $UserProfilesPath = Split-Path $env:USERPROFILE -Parent
    
    Write-Log "User profiles path: $UserProfilesPath" -Level INFO
    Write-Log "" -Level INFO
    
    # Enumerate user profile directories
    Write-Log "Enumerating user profiles..." -Level INFO
    
    try {
        $UserFolders = Get-ChildItem -Path $UserProfilesPath -Directory -ErrorAction Stop
        Write-Log "Found $($UserFolders.Count) user profile(s)" -Level INFO
    } catch {
        Write-Log "Failed to enumerate user profiles: $_" -Level ERROR
        exit 1
    }
    
    Write-Log "" -Level INFO
    Write-Log "Removing SAP folders from user profiles..." -Level INFO
    
    $DeletedCount = 0
    $NotFoundCount = 0
    
    foreach ($UserFolder in $UserFolders) {
        $SAPPath = Join-Path $UserFolder.FullName "AppData\Roaming\SAP"
        
        if (Test-Path $SAPPath) {
            try {
                Write-Log "Processing user: $($UserFolder.Name)" -Level INFO
                Remove-Item -Path $SAPPath -Recurse -Force -ErrorAction Stop
                Write-Log "Removed SAP folder for user: $($UserFolder.Name)" -Level SUCCESS
                $DeletedCount++
            } catch {
                Write-Log "Failed to remove SAP folder for $($UserFolder.Name): $_" -Level ERROR
                $script:ErrorCount++
            }
        } else {
            Write-Log "No SAP folder found for user: $($UserFolder.Name)" -Level DEBUG
            $NotFoundCount++
        }
    }
    
    Write-Log "" -Level INFO
    Write-Log "SAP user profile cleanup summary:" -Level SUCCESS
    Write-Log "  Total Profiles: $($UserFolders.Count)" -Level INFO
    Write-Log "  SAP Folders Deleted: $DeletedCount" -Level INFO
    Write-Log "  No SAP Data Found: $NotFoundCount" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    
    if ($script:ErrorCount -gt 0) {
        Write-Log "Some errors occurred during deletion" -Level WARN
        $script:ExitCode = 1
    }
    
    exit $script:ExitCode
    
} catch {
    Write-Log "SAP user profile deletion failed: $($_.Exception.Message)" -Level ERROR
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "========================================" -Level INFO
}
