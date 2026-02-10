#Requires -Version 5.1

<#
.SYNOPSIS
    Sets the required registry key to either block the forced migration from 'classic Outlook' to 'New Outlook' and optionally hides the 'Try the New Outlook' toggle button.

.DESCRIPTION
    This script configures registry settings to control Outlook's migration behavior from classic Outlook to New Outlook.
    It can disable/enable the forced migration policy and hide/show the 'Try the New Outlook' toggle button for users.
    The script supports targeting specific users or all users on the system.
    
    Key Features:
    - Controls Outlook migration policy (Enable/Disable/Default)
    - Hides/shows the 'Try the New Outlook' toggle button
    - Supports per-user or system-wide configuration
    - Loads/unloads user registry hives as needed
    - Compatible with domain-joined systems (warns about GPO override)
    - Validates Office/Microsoft 365 installation

.PARAMETER MigrationPolicy
    Sets the automatic forced migration policy for classic Outlook to New Outlook.
    Valid values: 'Enable', 'Disable', 'Default'
    Default: 'Disable'

.PARAMETER NewOutlookToggle
    Controls visibility of the 'Try the New Outlook' toggle button in Outlook.
    Valid values: 'Hide Toggle', 'Show Toggle', 'Default'
    If not specified, the toggle setting will not be modified.

.PARAMETER UserToSetPolicyFor
    Specifies a username to target for policy changes.
    If not specified, applies policy to all users on the system.
    Username must not exceed 20 characters and must not contain spaces or special characters.

.EXAMPLE
    Outlook-SetForcedMigration.ps1
    Disables forced migration for all users (default behavior).

.EXAMPLE
    Outlook-SetForcedMigration.ps1 -MigrationPolicy "Disable" -NewOutlookToggle "Hide Toggle"
    Disables forced migration AND hides the toggle button for all users.

.EXAMPLE
    Outlook-SetForcedMigration.ps1 -MigrationPolicy "Enable" -UserToSetPolicyFor "jsmith"
    Enables forced migration for user 'jsmith' only.

.EXAMPLE
    Outlook-SetForcedMigration.ps1 -NewOutlookToggle "Show Toggle" -UserToSetPolicyFor "admin"
    Shows the toggle button for user 'admin' (does not change migration policy).

.EXAMPLE
    Outlook-SetForcedMigration.ps1 -MigrationPolicy "Default"
    Resets migration policy to default (removes registry key) for all users.

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Version: 3.0
    Release Notes: 
        - V3.0: Added Write-Log function, execution tracking, enhanced error handling, structured helper functions
        - V1.0: Initial Release
    
    Exit Codes:
        0 = Success
        1 = Failure (various error conditions)
    
    Requirements:
        - Administrator privileges required
        - Microsoft Office or Microsoft 365 must be installed
    
    Registry Paths:
        - Migration Policy: HKEY_USERS\<SID>\Software\Policies\Microsoft\office\16.0\outlook\preferences\NewOutlookMigrationUserSetting
        - Toggle Button: HKEY_USERS\<SID>\Software\Microsoft\Office\16.0\Outlook\Options\General\HideNewOutlookToggle

.LINK
    https://learn.microsoft.com/en-us/microsoft-365-apps/outlook/get-started/control-install
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Enable', 'Disable', 'Default')]
    [String]$MigrationPolicy = 'Disable',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Hide Toggle', 'Show Toggle', 'Default')]
    [String]$NewOutlookToggle,
    
    [Parameter(Mandatory = $false)]
    [ValidateLength(1, 20)]
    [ValidatePattern('^[^\[\]:;|=+*?<>/\\,"@\s]+$')]
    [String]$UserToSetPolicyFor
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    Set-StrictMode -Version Latest
    
    $ExitCode = 0
    $ScriptStartTime = Get-Date

    function Write-Log {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
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

    function Find-InstallKey {
        <#
        .SYNOPSIS
            Searches for installed software in the Windows registry.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [String]$DisplayName,
            
            [Parameter(Mandatory = $false)]
            [Switch]$UninstallString,
            
            [Parameter(Mandatory = $false)]
            [String]$UserBaseKey
        )
        
        process {
            $InstallList = New-Object System.Collections.Generic.List[Object]
            
            try {
                if (!$UserBaseKey) {
                    $Paths = @(
                        'Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                        'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
                    )
                }
                else {
                    $Paths = @(
                        "$UserBaseKey\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                        "$UserBaseKey\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
                    )
                }
                
                foreach ($Path in $Paths) {
                    if (Test-Path -Path $Path) {
                        $Result = Get-ChildItem -Path $Path -ErrorAction Stop | 
                            Get-ItemProperty | 
                            Where-Object { $_.DisplayName -like "*$DisplayName*" }
                        
                        if ($Result) { 
                            $InstallList.Add($Result) 
                        }
                    }
                }
            }
            catch {
                Write-Log "Failed to retrieve registry keys at '$Path': $($_.Exception.Message)" -Level ERROR
                throw
            }
            
            if ($UninstallString) {
                return $InstallList | Select-Object -ExpandProperty UninstallString -ErrorAction SilentlyContinue
            }
            else {
                return $InstallList
            }
        }
    }

    function Get-UserHives {
        <#
        .SYNOPSIS
            Retrieves user profile information including registry hive paths.
        #>
        param (
            [Parameter(Mandatory = $false)]
            [ValidateSet('AzureAD', 'DomainAndLocal', 'All')]
            [String]$Type = 'All',
            
            [Parameter(Mandatory = $false)]
            [String[]]$ExcludedUsers,
            
            [Parameter(Mandatory = $false)]
            [switch]$IncludeDefault
        )
        
        $Patterns = switch ($Type) {
            'AzureAD'        { 'S-1-12-1-(\d+-?){4}$' }
            'DomainAndLocal' { 'S-1-5-21-(\d+-?){4}$' }
            'All'            { 'S-1-12-1-(\d+-?){4}$'; 'S-1-5-21-(\d+-?){4}$' } 
        }
        
        try {
            $UserProfiles = foreach ($Pattern in $Patterns) { 
                Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction Stop |
                    Where-Object { $_.PSChildName -match $Pattern } | 
                    Select-Object @{Name = 'SID'; Expression = { $_.PSChildName } },
                    @{Name = 'Username'; Expression = { "$($_.ProfileImagePath | Split-Path -Leaf)" } }, 
                    @{Name = 'Domain'; Expression = { if ($_.PSChildName -match 'S-1-12-1-(\d+-?){4}$') { 'AzureAD' } else { $null } } }, 
                    @{Name = 'UserHive'; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }, 
                    @{Name = 'Path'; Expression = { $_.ProfileImagePath } }
            }
        }
        catch {
            Write-Log "Failed to scan registry keys at 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList': $($_.Exception.Message)" -Level ERROR
            throw
        }
        
        if ($IncludeDefault) {
            $DefaultProfile = [PSCustomObject]@{
                Username = 'Default'
                Domain   = $env:COMPUTERNAME
                SID      = 'DefaultProfile'
                Userhive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
                Path     = 'C:\Users\Default'
            }
            
            if ($ExcludedUsers -notcontains $DefaultProfile.Username) {
                $UserProfiles += $DefaultProfile
            }
        }
        
        try {
            $AllAccounts = if ($PSVersionTable.PSVersion.Major -lt 3) {
                Get-WmiObject -Class 'win32_UserAccount' -ErrorAction Stop
            }
            else {
                Get-CimInstance -ClassName 'win32_UserAccount' -ErrorAction Stop
            }
        }
        catch {
            Write-Log "Failed to gather complete profile information: $($_.Exception.Message)" -Level ERROR
            throw
        }
        
        $CompleteUserProfiles = $UserProfiles | ForEach-Object {
            $SID = $_.SID
            $Win32Object = $AllAccounts | Where-Object { $_.SID -eq $SID }
            
            if ($Win32Object) {
                $Win32Object | Add-Member -NotePropertyName UserHive -NotePropertyValue $_.UserHive -Force
                $Win32Object
            }
            else {
                [PSCustomObject]@{
                    Name     = $_.Username
                    Domain   = $_.Domain
                    SID      = $_.SID
                    UserHive = $_.UserHive
                    Path     = $_.Path
                }
            }
        }
        
        return $CompleteUserProfiles | Where-Object { $ExcludedUsers -notcontains $_.Name }
    }

    function Set-RegKey {
        <#
        .SYNOPSIS
            Creates or updates a registry key with proper error handling.
        #>
        param (
            [Parameter(Mandatory = $true)]
            [string]$Path,
            
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true)]
            $Value,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet('DWord', 'QWord', 'String', 'ExpandedString', 'Binary', 'MultiString', 'Unknown')]
            [string]$PropertyType = 'DWord'
        )
        
        if (!(Test-Path -Path $Path)) {
            try {
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
                Write-Log "Created registry path: $Path"
            }
            catch {
                Write-Log "Unable to create registry path $Path for $Name: $($_.Exception.Message)" -Level ERROR
                throw
            }
        }
        
        $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
        
        if ($null -ne $CurrentValue) {
            if ($CurrentValue -eq $Value) {
                Write-Log "$Path\$Name is already set to '$Value'"
            }
            else {
                try {
                    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
                    Write-Log "$Path\$Name changed from $CurrentValue to $Value"
                }
                catch {
                    Write-Log "Unable to set registry key $Name at $Path: $($_.Exception.Message)" -Level ERROR
                    throw
                }
            }
        }
        else {
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
                Write-Log "Set $Path\$Name to $Value"
            }
            catch {
                Write-Log "Unable to create registry key $Name at $Path: $($_.Exception.Message)" -Level ERROR
                throw
            }
        }
    }

    function Test-IsDomainJoined {
        <#
        .SYNOPSIS
            Checks if the computer is joined to a domain.
        #>
        try {
            if ($PSVersionTable.PSVersion.Major -lt 3) {
                return (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop).PartOfDomain
            }
            else {
                return (Get-CimInstance -Class Win32_ComputerSystem -ErrorAction Stop).PartOfDomain
            }
        }
        catch {
            Write-Log "Unable to validate whether device is part of a domain: $($_.Exception.Message)" -Level WARNING
            return $false
        }
    }

    function Test-IsDomainController {
        <#
        .SYNOPSIS
            Checks if the computer is a domain controller.
        #>
        try {
            $OS = if ($PSVersionTable.PSVersion.Major -lt 3) {
                Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
            }
            else {
                Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            }
            
            return ($OS.ProductType -eq 2)
        }
        catch {
            Write-Log "Unable to validate whether device is a domain controller: $($_.Exception.Message)" -Level WARNING
            return $false
        }
    }

    function Test-IsElevated {
        <#
        .SYNOPSIS
            Checks if the current PowerShell session is running with administrator privileges.
        #>
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Mount-UserRegistryHive {
        <#
        .SYNOPSIS
            Loads a user's registry hive if not already loaded.
        #>
        param (
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$UserProfile
        )
        
        if (!(Test-Path -Path "Registry::HKEY_USERS\$($UserProfile.SID)" -ErrorAction SilentlyContinue)) {
            try {
                Start-Process -FilePath 'cmd.exe' -ArgumentList "/C reg.exe LOAD HKU\$($UserProfile.SID) `"$($UserProfile.UserHive)`"" -Wait -WindowStyle Hidden -ErrorAction Stop
                Write-Log "Loaded registry hive for user '$($UserProfile.Name)' (SID: $($UserProfile.SID))"
                return $true
            }
            catch {
                Write-Log "Failed to load registry hive for user '$($UserProfile.Name)': $($_.Exception.Message)" -Level WARNING
                return $false
            }
        }
        return $false
    }

    function Dismount-UserRegistryHive {
        <#
        .SYNOPSIS
            Unloads a user's registry hive.
        #>
        param (
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$UserProfile
        )
        
        try {
            [System.GC]::Collect()
            Start-Sleep -Milliseconds 500
            Start-Process -FilePath 'cmd.exe' -ArgumentList "/C reg.exe UNLOAD HKU\$($UserProfile.SID)" -Wait -WindowStyle Hidden -ErrorAction Stop
            Write-Log "Unloaded registry hive for user '$($UserProfile.Name)' (SID: $($UserProfile.SID))"
        }
        catch {
            Write-Log "Failed to unload registry hive for user '$($UserProfile.Name)': $($_.Exception.Message)" -Level WARNING
        }
    }

    if ($env:migrationAction -and $env:migrationAction -ne 'null') { 
        $MigrationPolicy = $env:migrationAction 
    }
    if ($env:toggleButtonAction -and $env:toggleButtonAction -ne 'null') { 
        $NewOutlookToggle = $env:toggleButtonAction 
    }
    if ($env:usernameToSetPolicyFor -and $env:usernameToSetPolicyFor -ne 'null') { 
        $UserToSetPolicyFor = $env:usernameToSetPolicyFor 
    }
    
    Write-Log '=== Outlook Migration Policy Configuration ==='
    Write-Log "Migration Policy: $MigrationPolicy"
    if ($NewOutlookToggle) {
        Write-Log "New Outlook Toggle: $NewOutlookToggle"
    }
    if ($UserToSetPolicyFor) {
        Write-Log "Target User: $UserToSetPolicyFor"
    }
}

process {
    try {
        if (!(Test-IsElevated)) {
            Write-Log 'Access Denied. Script must run with Administrator privileges.' -Level ERROR
            exit 1
        }
        
        if (Test-IsDomainJoined -or Test-IsDomainController) {
            Write-Log 'This device is joined to a domain. Settings may be overridden by Group Policy.' -Level WARNING
            Write-Log 'See: https://learn.microsoft.com/en-us/microsoft-365-apps/outlook/get-started/control-install#prevent-users-from-switching-to-new-outlook' -Level WARNING
        }
        
        Write-Log 'Checking for Office installation...'
        $OfficeInstallations = Find-InstallKey -DisplayName 'Office 201'
        $Microsoft365Installations = Find-InstallKey -DisplayName 'Microsoft 365'
        
        if (!$OfficeInstallations -and !$Microsoft365Installations) {
            Write-Log 'Microsoft Office was not detected on this device.' -Level ERROR
            exit 1
        }
        
        Write-Log 'Office installation detected.'
        
        if ($UserToSetPolicyFor) {
            Write-Log "Retrieving user profile for '$UserToSetPolicyFor'..."
        }
        else {
            Write-Log 'Gathering all user profiles...'
        }
        
        $UserProfiles = Get-UserHives -Type 'All'
        
        if ($UserToSetPolicyFor) {
            $ProfileToSet = $UserProfiles | Where-Object { $_.Name -eq $UserToSetPolicyFor }
            
            if (!$ProfileToSet) {
                Write-Log "No user profile matching '$UserToSetPolicyFor' was found." -Level ERROR
                Write-Log 'Available user profiles:'
                $UserProfiles | ForEach-Object { Write-Log "  - $($_.Name) (SID: $($_.SID))" }
                exit 1
            }
            
            $UserProfiles = $ProfileToSet
        }
        
        if (!$UserProfiles) {
            Write-Log 'Failed to retrieve any user profiles.' -Level ERROR
            exit 1
        }
        
        Write-Log "Successfully retrieved $($UserProfiles.Count) user profile(s)."
        
        $ProfileWasLoaded = New-Object System.Collections.Generic.List[PSCustomObject]
        
        foreach ($UserProfile in $UserProfiles) {
            if (Mount-UserRegistryHive -UserProfile $UserProfile) {
                $ProfileWasLoaded.Add($UserProfile)
            }
        }
        
        $OutlookMigrationRegistryPaths = New-Object System.Collections.Generic.List[PSCustomObject]
        $NewOutlookToggleRegistryPaths = New-Object System.Collections.Generic.List[PSCustomObject]
        
        foreach ($UserProfile in $UserProfiles) {
            $OutlookMigrationRegistryPaths.Add([PSCustomObject]@{
                    Username = $UserProfile.Name
                    Path     = "Registry::HKEY_USERS\$($UserProfile.SID)\Software\Policies\Microsoft\office\16.0\outlook\preferences"
                })
            
            $NewOutlookToggleRegistryPaths.Add([PSCustomObject]@{
                    Username = $UserProfile.Name
                    BasePath = "Registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Office"
                    Path     = "Registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Office\16.0\Outlook\Options\General"
                })
        }
        
        Write-Log ''
        Write-Log '=== Setting Outlook Migration Policy ==='
        
        foreach ($RegPath in $OutlookMigrationRegistryPaths) {
            $Username = $RegPath.Username
            
            try {
                switch ($MigrationPolicy) {
                    'Enable' { 
                        Write-Log "Setting migration policy for user '$Username' to ENABLED"
                        Set-RegKey -Path $RegPath.Path -Name 'NewOutlookMigrationUserSetting' -Value 1
                    }
                    'Disable' { 
                        Write-Log "Setting migration policy for user '$Username' to DISABLED"
                        Set-RegKey -Path $RegPath.Path -Name 'NewOutlookMigrationUserSetting' -Value 0
                    }
                    'Default' { 
                        Write-Log "Resetting migration policy for user '$Username' to DEFAULT"
                        
                        if (Test-Path -Path $RegPath.Path -ErrorAction SilentlyContinue) {
                            $ExistingValue = (Get-ItemProperty -Path $RegPath.Path -ErrorAction SilentlyContinue).NewOutlookMigrationUserSetting
                            
                            if ($null -ne $ExistingValue) {
                                Remove-ItemProperty -Path $RegPath.Path -Name 'NewOutlookMigrationUserSetting' -ErrorAction Stop
                                Write-Log "Removed registry key: $($RegPath.Path)\NewOutlookMigrationUserSetting"
                            }
                            else {
                                Write-Log "Registry key already at default for user '$Username'"
                            }
                        }
                        else {
                            Write-Log "Registry key already at default for user '$Username'"
                        }
                    }
                }
                
                Write-Log "Successfully set migration policy for user '$Username'"
            }
            catch {
                Write-Log "Failed to set migration policy for user '$Username': $($_.Exception.Message)" -Level ERROR
                $ExitCode = 1
            }
        }
        
        if (!$NewOutlookToggle) {
            Write-Log ''
            Write-Log 'New Outlook toggle setting not specified - skipping toggle configuration.'
            
            foreach ($UserProfile in $ProfileWasLoaded) {
                Dismount-UserRegistryHive -UserProfile $UserProfile
            }
            
            if ($ExitCode -eq 0) {
                Write-Log 'Successfully configured Outlook migration policy.'
            }
            exit $ExitCode
        }
        
        Write-Log ''
        Write-Log '=== Setting New Outlook Toggle Visibility ==='
        
        foreach ($RegPath in $NewOutlookToggleRegistryPaths) {
            $Username = $RegPath.Username
            
            try {
                switch ($NewOutlookToggle) {
                    'Hide Toggle' { 
                        Write-Log "Setting toggle for user '$Username' to HIDDEN"
                        
                        if (!(Test-Path -Path $RegPath.BasePath)) {
                            New-Item -Path $RegPath.BasePath -Force -ErrorAction Stop | Out-Null
                            Write-Log "Created base path: $($RegPath.BasePath)"
                        }
                        
                        Set-RegKey -Path $RegPath.Path -Name 'HideNewOutlookToggle' -Value 1
                    }
                    'Show Toggle' { 
                        Write-Log "Setting toggle for user '$Username' to VISIBLE"
                        
                        if (!(Test-Path -Path $RegPath.BasePath)) {
                            New-Item -Path $RegPath.BasePath -Force -ErrorAction Stop | Out-Null
                            Write-Log "Created base path: $($RegPath.BasePath)"
                        }
                        
                        Set-RegKey -Path $RegPath.Path -Name 'HideNewOutlookToggle' -Value 0
                    }
                    'Default' { 
                        Write-Log "Resetting toggle for user '$Username' to DEFAULT"
                        
                        if (Test-Path -Path $RegPath.Path -ErrorAction SilentlyContinue) {
                            $ExistingValue = (Get-ItemProperty -Path $RegPath.Path -ErrorAction SilentlyContinue).HideNewOutlookToggle
                            
                            if ($null -ne $ExistingValue) {
                                Remove-ItemProperty -Path $RegPath.Path -Name 'HideNewOutlookToggle' -ErrorAction Stop
                                Write-Log "Removed registry key: $($RegPath.Path)\HideNewOutlookToggle"
                            }
                            else {
                                Write-Log "Registry key already at default for user '$Username'"
                            }
                        }
                        else {
                            Write-Log "Registry key already at default for user '$Username'"
                        }
                    }
                }
                
                Write-Log "Successfully set toggle visibility for user '$Username'"
            }
            catch {
                Write-Log "Failed to set toggle visibility for user '$Username': $($_.Exception.Message)" -Level ERROR
                $ExitCode = 1
            }
        }
        
        foreach ($UserProfile in $ProfileWasLoaded) {
            Dismount-UserRegistryHive -UserProfile $UserProfile
        }
        
        if ($ExitCode -eq 0) {
            Write-Log ''
            Write-Log 'Successfully configured all Outlook settings.'
            Write-Log 'Note: You may need to close and re-open Outlook for changes to take effect.'
        }
        
        exit $ExitCode
    }
    catch {
        Write-Log "Unexpected error: $($_.Exception.Message)" -Level ERROR
        exit 1
    }
}

end {
    $executionTime = (Get-Date) - $ScriptStartTime
    Write-Log "Script execution completed in $($executionTime.TotalSeconds) seconds."
    
    [System.GC]::Collect()
}
