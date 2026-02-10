#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Hides or shows the 'News and Interests' tab in the taskbar. On Windows 11, it hides or shows the widgets tab.
.DESCRIPTION
    Hides or shows the 'News and Interests' tab in the taskbar. On Windows 11, it hides or shows the widgets tab.
.EXAMPLE
    (No Parameters)
    
    WARNING: Hiding News and Interests from the taskbar for all users!
    Registry::HKEY_USERS\S-1-12-1-2117605486-1182246982-3318994623-3070967164\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa changed from 1 to 0
    Registry::HKEY_USERS\S-1-5-21-4122835015-3639794443-155648563-1001\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa changed from 1 to 0
    WARNING: This script will take effect the next time the user completes a full sign-in or restarts.

PARAMETER: -Enable
    Reveals the 'News and Interests' tab in the taskbar.
.EXAMPLE
    -Enable

    Revealing News and Interests for all users!
    Registry::HKEY_USERS\S-1-12-1-2117605486-1182246982-3318994623-3070967164\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa changed from 0 to 1
    Registry::HKEY_USERS\S-1-5-21-4122835015-3639794443-155648563-1001\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa changed from 0 to 1
    WARNING: This script will take effect the next time the user completes a full sign-in or restarts.

PARAMETER: -PreventChanges
    Should the end-user be able to modify this setting after it's been set with this script?
.EXAMPLE
    -PreventChanges
    
    WARNING: Hiding News and Interests from the taskbar for all users!
    Set Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh\AllowNewsAndInterests to 0
    WARNING: This script will take effect the next time the user completes a full sign-in or restarts.

PARAMETER: -RestartExplorer
    In order for this script to take immediate effect, explorer.exe will need to be restarted.
.EXAMPLE
    -RestartExplorer

    WARNING: Hiding News and Interests from the taskbar for all users!
    Registry::HKEY_USERS\S-1-12-1-2117605486-1182246982-3318994623-3070967164\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa changed from 1 to 0
    Registry::HKEY_USERS\S-1-5-21-4122835015-3639794443-155648563-1001\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa changed from 1 to 0
    WARNING: Restarting Explorer.exe

.OUTPUTS
    None
.NOTES
    Minimum Supported OS: Windows 10+
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param (
    [Parameter()]
    [Switch]$Enable,
    [Parameter()]
    [Switch]$PreventChanges = [System.Convert]::ToBoolean($env:preventChanges),
    [Parameter()]
    [Switch]$RestartExplorer = [System.Convert]::ToBoolean($env:restartExplorer)
)

begin {
    $StartTime = Get-Date

    function Write-Log {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Warning', 'Error')]
            [string]$Level = 'Info'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $Output = "[$Timestamp] [$Level] $Message"
        Write-Host $Output
    }

    if ($env:showOrHide -and $env:showOrHide -notlike "null") { if ($env:showOrHide -eq "Show") { $Enable = $True } }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    function Get-UserHives {
        param (
            [Parameter()]
            [ValidateSet('AzureAD', 'DomainAndLocal', 'All')]
            [String]$Type = "All",
            [Parameter()]
            [String[]]$ExcludedUsers,
            [Parameter()]
            [switch]$IncludeDefault
        )
    
        $Patterns = switch ($Type) {
            "AzureAD" { "S-1-12-1-(\d+-?){4}$" }
            "DomainAndLocal" { "S-1-5-21-(\d+-?){4}$" }
            "All" { "S-1-12-1-(\d+-?){4}$" ; "S-1-5-21-(\d+-?){4}$" } 
        }
    
        $UserProfiles = Foreach ($Pattern in $Patterns) { 
            Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
                Where-Object { $_.PSChildName -match $Pattern } | 
                Select-Object @{Name = "SID"; Expression = { $_.PSChildName } },
                @{Name = "UserName"; Expression = { "$($_.ProfileImagePath | Split-Path -Leaf)" } }, 
                @{Name = "UserHive"; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }, 
                @{Name = "Path"; Expression = { $_.ProfileImagePath } }
        }
    
        switch ($IncludeDefault) {
            $True {
                $DefaultProfile = "" | Select-Object UserName, SID, UserHive, Path
                $DefaultProfile.UserName = "Default"
                $DefaultProfile.SID = "DefaultProfile"
                $DefaultProfile.Userhive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
                $DefaultProfile.Path = "C:\Users\Default"
    
                $DefaultProfile | Where-Object { $ExcludedUsers -notcontains $_.UserName }
            }
        }
    
        $UserProfiles | Where-Object { $ExcludedUsers -notcontains $_.UserName }
    }

    function Set-RegKey {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        if (-not $(Test-Path -Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)) {
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Unable to set registry key for $Name at $Path please see below error!" -Level Error
                Write-Log "$($_.Exception.Message)" -Level Error
                exit 1
            }
            Write-Log "$Path\$Name changed from $CurrentValue to $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name)"
        }
        else {
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Unable to set registry key for $Name at $Path please see below error!" -Level Error
                Write-Log "$($_.Exception.Message)" -Level Error
                exit 1
            }
            Write-Log "Set $Path\$Name to $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name)"
        }
    }
    
    function Get-OSName {
        systeminfo | findstr /B /C:"OS Name"
    }

    $OSName = Get-OSName
}

process {
    if (!(Test-IsElevated)) {
        Write-Log "Access Denied. Please run with Administrator privileges." -Level Error
        exit 1
    }

    if ($OSName -Like "*11*") {
        $AllUserPath = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh" -ErrorAction Ignore).AllowNewsAndInterests
    }
    else {
        $AllUserPath = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -ErrorAction Ignore).EnableFeeds
    }

    if ($AllUserPath -ge 0) {
        $EnableOrDisable = switch ($AllUserPath) {
            1 { "revealed" }
            default { "hidden" }
        }

        if (-not ($PreventChanges)) {
            Write-Log "News and Interests is currently $EnableOrDisable for all users. Removing 'Prevent Changes' setting to replace it with individual user setting as requested." -Level Warning
            
            if ($OSName -Like "*11*") {
                Remove-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests"
            }
            else {
                Remove-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds"
            }
        }
    }

    if ($OSName -Like "*11*") {
        $KeyPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh"
        $KeyName = "AllowNewsAndInterests"
        $Value = if ($Enable) { 1 }else { 0 }
    }
    else {
        $KeyPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
        $KeyName = "EnableFeeds"
        $Value = if ($Enable) { 1 }else { 0 }
    }

    if (-not ($PreventChanges)) {
        $UserProfiles = Get-UserHives -Type "All"

        $KeyPath = New-Object System.Collections.Generic.List[string]
        $LoadedProfiles = New-Object System.Collections.Generic.List[Object]

        Foreach ($UserProfile in $UserProfiles) {
            If ((Test-Path "Registry::HKEY_USERS\$($UserProfile.SID)" -ErrorAction Ignore) -eq $false) {
                $LoadedProfiles.Add($UserProfile)
                Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe LOAD HKU\$($UserProfile.SID) `"$($UserProfile.UserHive)`"" -Wait -WindowStyle Hidden
            }
            if ($OSName -Like "*11*") {
                $KeyPath.Add("Registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced")
            }
            else {
                $KeyPath.Add("Registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Feeds")
            }
        }

        if ($OSName -Like "*11*") {
            $KeyName = "TaskbarDa"
            $Value = if ($Enable) { 1 }else { 0 }
        }
        else {
            $KeyName = "ShellFeedsTaskbarViewMode"
            $Value = if ($Enable) { 0 }else { 2 }
        }
    }

    if ($Enable) {
        Write-Log "Revealing News and Interests for all users!"
    }
    else {
        Write-Log "Hiding News and Interests from the taskbar for all users!" -Level Warning
    }
    
    $KeyPath | ForEach-Object { Set-RegKey -Path $_ -Name $KeyName -Value $Value }

    Foreach ($LoadedProfile in $LoadedProfiles) {
        [gc]::Collect()
        Start-Sleep 1
        Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe UNLOAD HKU\$($LoadedProfile.SID)" -Wait -WindowStyle Hidden | Out-Null
    }

    if ($RestartExplorer) {
        Write-Log "Restarting Explorer.exe as requested."

        Get-Process explorer | Stop-Process -Force
        
        Start-Sleep -Seconds 1

        if (!(Test-IsSystem) -and !(Get-Process -Name "explorer")) {
            Start-Process explorer.exe
        }
    }
    else {
        Write-Log "This script will take effect the next time the user completes a full sign-in or restarts." -Level Warning
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
