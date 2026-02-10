#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Monitors if user profiles have modern authentication for Office 365 enabled or disabled.

.DESCRIPTION
    This script checks each user profile on the system to determine if modern authentication (ADAL) 
    is enabled for Microsoft Office 365. Modern authentication provides enhanced security through 
    multi-factor authentication and conditional access policies.
    
    The script examines:
    - Office 2013 (15.0): Checks if EnableADAL is set to 1
    - Office 2016/2019/365 (16.0): Checks if EnableADAL is not set to 0
    
    This monitoring is critical for security compliance as legacy authentication protocols are 
    being deprecated by Microsoft and pose security risks.

.EXAMPLE
    .\Office365-ModernAuthAlert.ps1

    [2026-02-10 01:53:20] [INFO] Starting Office 365 Modern Authentication check...
    [2026-02-10 01:53:20] [INFO] Checking 3 user profiles
    [2026-02-10 01:53:21] [INFO] User 'JohnDoe': Modern auth enabled
    [2026-02-10 01:53:21] [WARNING] User 'JaneSmith': Modern auth is not enabled
    [2026-02-10 01:53:22] [INFO] User 'Administrator': Modern auth enabled
    [2026-02-10 01:53:22] [WARNING] Found 1 user(s) with modern auth disabled

.OUTPUTS
    System.Int32
    Exit code: 0 if all users have modern auth enabled, 1 if any user has it disabled

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes:
    (v3.0) 2026-02-10 - Upgraded to V3 standards: Write-Log function, execution tracking, enhanced error handling
    (v1.1) 2025-12-01 - Renamed script
    (v1.0) 2025-11-01 - Initial release
    
.COMPONENT
    Registry - User profile registry hive loading and querying
    
.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/en-us/microsoft-365/admin/security-and-compliance/enable-modern-authentication

.FUNCTIONALITY
    - Loads each user profile registry hive
    - Checks Office 2013 EnableADAL setting
    - Checks Office 2016/2019/365 EnableADAL setting
    - Reports users with modern auth disabled
    - Returns appropriate exit codes for monitoring
    - Properly unloads registry hives after checking
#>

[CmdletBinding()]
param()

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    Set-StrictMode -Version Latest
    
    $startTime = Get-Date
    $exitCode = 0
    $foundModernAuthDisabled = $false
    $disabledUsers = [System.Collections.ArrayList]::new()

    function Write-Log {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG')]
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
        [CmdletBinding()]
        param()
        
        try {
            $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
            return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        catch {
            Write-Log "Failed to check elevation status: $($_.Exception.Message)" -Level ERROR
            return $false
        }
    }

    function Load-UserHive {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$SID,
            
            [Parameter(Mandatory = $true)]
            [string]$HivePath
        )
        
        try {
            if (-not (Test-Path -Path $HivePath)) {
                Write-Log "User hive not found: $HivePath" -Level WARNING
                return $false
            }
            
            $process = Start-Process -FilePath "reg.exe" -ArgumentList "LOAD", "HKU\$SID", $HivePath -Wait -WindowStyle Hidden -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Log "Successfully loaded hive for SID: $SID" -Level DEBUG
                return $true
            }
            else {
                Write-Log "Failed to load hive for SID: $SID (Exit code: $($process.ExitCode))" -Level WARNING
                return $false
            }
        }
        catch {
            Write-Log "Error loading hive for SID $SID : $($_.Exception.Message)" -Level WARNING
            return $false
        }
    }

    function Unload-UserHive {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$SID
        )
        
        try {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            Start-Sleep -Milliseconds 500
            
            $process = Start-Process -FilePath "reg.exe" -ArgumentList "UNLOAD", "HKU\$SID" -Wait -WindowStyle Hidden -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Log "Successfully unloaded hive for SID: $SID" -Level DEBUG
                return $true
            }
            else {
                Write-Log "Failed to unload hive for SID: $SID (Exit code: $($process.ExitCode))" -Level WARNING
                return $false
            }
        }
        catch {
            Write-Log "Error unloading hive for SID $SID : $($_.Exception.Message)" -Level WARNING
            return $false
        }
    }

    function Test-ModernAuthEnabled {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$SID,
            
            [Parameter(Mandatory = $true)]
            [string]$UserName
        )
        
        $registryPaths = @(
            @{ Path = "SOFTWARE\Microsoft\Office\15.0\Common\Identity"; Version = "2013" },
            @{ Path = "SOFTWARE\Microsoft\Office\16.0\Common\Identity"; Version = "2016/2019/365" }
        )
        $valueName = "EnableADAL"
        $isEnabled = $true
        
        foreach ($regPath in $registryPaths) {
            $fullPath = "Registry::HKEY_USERS\$SID\$($regPath.Path)"
            
            if (Test-Path -Path $fullPath -ErrorAction SilentlyContinue) {
                try {
                    $value = Get-ItemProperty -Path $fullPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName -ErrorAction SilentlyContinue
                    
                    if ($regPath.Version -eq "2013") {
                        if ($null -ne $value -and $value -ne 1) {
                            Write-Log "User '$UserName': Office $($regPath.Version) modern auth is not enabled (EnableADAL = $value)" -Level WARNING
                            $isEnabled = $false
                        }
                    }
                    elseif ($regPath.Version -eq "2016/2019/365") {
                        if ($null -ne $value -and $value -eq 0) {
                            Write-Log "User '$UserName': Office $($regPath.Version) modern auth is disabled (EnableADAL = $value)" -Level WARNING
                            $isEnabled = $false
                        }
                    }
                }
                catch {
                    Write-Log "Error checking modern auth for user '$UserName' in Office $($regPath.Version): $($_.Exception.Message)" -Level DEBUG
                }
            }
        }
        
        if ($isEnabled) {
            Write-Log "User '$UserName': Modern auth enabled" -Level DEBUG
        }
        
        return $isEnabled
    }
}

process {
    try {
        Write-Log "Starting Office 365 Modern Authentication check..."
        
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. This script must be run with Administrator privileges" -Level ERROR
            $exitCode = 1
            return
        }
        
        $userProfiles = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" -ErrorAction Stop |
            Where-Object { $_.PSChildName -match "S-1-5-21-(\d+-?){4}$" } |
            Select-Object @{
                Name = "SID"
                Expression = { $_.PSChildName }
            },
            @{
                Name = "UserHive"
                Expression = { "$($_.ProfileImagePath)\NTuser.dat" }
            },
            @{
                Name = "UserName"
                Expression = { $_.ProfileImagePath | Split-Path -Leaf }
            }
        
        if (-not $userProfiles -or $userProfiles.Count -eq 0) {
            Write-Log "No user profiles found on this system" -Level WARNING
            $exitCode = 0
            return
        }
        
        Write-Log "Checking $($userProfiles.Count) user profile(s)"
        
        foreach ($userProfile in $userProfiles) {
            $profileWasLoaded = $false
            
            try {
                $profileWasLoaded = Test-Path -Path "Registry::HKEY_USERS\$($userProfile.SID)" -ErrorAction SilentlyContinue
                
                if (-not $profileWasLoaded) {
                    Write-Log "Loading registry hive for user: $($userProfile.UserName)" -Level DEBUG
                    $loadSuccess = Load-UserHive -SID $userProfile.SID -HivePath $userProfile.UserHive
                    
                    if (-not $loadSuccess) {
                        Write-Log "Skipping user '$($userProfile.UserName)' - could not load registry hive" -Level WARNING
                        continue
                    }
                }
                
                $isEnabled = Test-ModernAuthEnabled -SID $userProfile.SID -UserName $userProfile.UserName
                
                if (-not $isEnabled) {
                    $foundModernAuthDisabled = $true
                    [void]$disabledUsers.Add($userProfile.UserName)
                }
            }
            catch {
                Write-Log "Error processing user profile '$($userProfile.UserName)': $($_.Exception.Message)" -Level ERROR
            }
            finally {
                if (-not $profileWasLoaded) {
                    Unload-UserHive -SID $userProfile.SID
                }
            }
        }
        
        if ($foundModernAuthDisabled) {
            Write-Log "Found $($disabledUsers.Count) user(s) with modern auth disabled: $($disabledUsers -join ', ')" -Level WARNING
            $exitCode = 1
        }
        else {
            Write-Log "All user profiles have modern authentication enabled" -Level SUCCESS
            $exitCode = 0
        }
    }
    catch {
        Write-Log "Critical error during modern auth check: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $exitCode = 1
    }
}

end {
}

finally {
    $duration = (Get-Date) - $startTime
    Write-Log "Script execution completed in $($duration.TotalSeconds) seconds" -Level DEBUG
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit $exitCode
}
