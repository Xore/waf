#Requires -Version 5.1

<#
.SYNOPSIS
    Remove SAP user profile data from all user accounts

.DESCRIPTION
    Recursively deletes SAP folders from AppData\Roaming for all user profiles
    on the system. This removes cached SAP logon data, connection profiles,
    and user-specific SAP GUI configurations.
    
    The script:
    - Enumerates all user profile directories
    - Removes SAP folders from AppData\Roaming for each user
    - Reports success/failure for each user profile processed
    - Handles both active and inactive user accounts
    
    Data Impact:
    Users will lose:
    - Saved SAP connection profiles
    - SAP Logon shortcuts
    - Custom GUI settings and preferences
    - Cached landscape data
    - Session history

.EXAMPLE
    .\SAP-DeleteUserProfiles.ps1
    
    Removes SAP folders from all user profiles on the system.

.NOTES
    File Name      : SAP-DeleteUserProfiles.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced logging and error handling
    - 2.0: Added profile enumeration improvements
    - 1.0: Initial release
    
    Execution Context: SYSTEM (required to access all user profiles)
    Execution Frequency: One-time or on-demand for SAP cleanup
    Typical Duration: 1-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: None (runs silently, no user notification)
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

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "SAP-DeleteUserProfiles"
    
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        $UserProfilesPath = Split-Path $env:USERPROFILE -Parent
        
        Write-Log "User profiles path: $UserProfilesPath" -Level INFO
        
        Write-Log "Enumerating user profiles" -Level INFO
        
        try {
            $UserFolders = Get-ChildItem -Path $UserProfilesPath -Directory -ErrorAction Stop
            Write-Log "Found $($UserFolders.Count) user profile(s)" -Level INFO
        } catch {
            Write-Log "Failed to enumerate user profiles: $_" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        Write-Log "Removing SAP folders from user profiles" -Level INFO
        
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
        
        Write-Log "SAP user profile cleanup summary:" -Level SUCCESS
        Write-Log "  Total Profiles: $($UserFolders.Count)" -Level INFO
        Write-Log "  SAP Folders Deleted: $DeletedCount" -Level INFO
        Write-Log "  No SAP Data Found: $NotFoundCount" -Level INFO
        
        if ($script:ErrorCount -gt 0) {
            Write-Log "Some errors occurred during deletion" -Level WARN
            $script:ExitCode = 1
        } else {
            $script:ExitCode = 0
        }
        
    } catch {
        Write-Log "SAP user profile deletion failed: $($_.Exception.Message)" -Level ERROR
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
