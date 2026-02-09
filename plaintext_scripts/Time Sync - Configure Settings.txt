#Requires -Version 5.1

<#
.SYNOPSIS
    Set the time zone and NTP time sync settings for the local machine.
.DESCRIPTION
    Set the time zone and NTP time sync settings for the local machine.

.PARAMETER -ListTimeZones
    List the available time zones. If selected, all other options will be ignored.
.PARAMETER -SetTimeZone
    Choose a time zone to set. Requires the ID from the 'List Time Zones' option.
.PARAMETER -EnableAndStartWindowsTimeService
    Enable and start the Windows Time service if it is disabled or not running. This will set the Start Type to 'Automatic.' This service is a prerequisite for all time sync settings besides the time zone.
.PARAMETER -SetSyncType
    Choose to sync from NTP servers, from the domain, or both.
.PARAMETER -SetSyncServers
    Specify NTP servers to sync from. Only used if 'Both' or 'NTP' is selected for Set Sync Type. Separate multiple servers with a comma.
.PARAMETER -SyncIntervalInMinutes
    Specify the sync interval in minutes. This value is required if using either 'Both' or 'NTP' for Set Sync Type, and only applies to NTP syncing. Valid range is 1 - 546 minutes.
.PARAMETER -EnableOrDisableGuestVmToHostSync
    For virtual machines, enable or disable time synchronization from the guest to the host. Setting this to 'Disable' is required for the other time sync settings to work as expected.
.PARAMETER -SyncNow
    Force a sync after the settings are applied.

.EXAMPLE
    -SetTimeZone "Central Standard Time"

    [Info] Setting time zone to 'Central Standard Time'...
    [Info] Changing time zone from '(UTC-09:00) Alaska' to '(UTC-06:00) Central Time (US & Canada)'...
    [Info] Time zone successfully set to 'Central Standard Time'.

    ### Current time zone settings: ###
    ...
    ### Current time sync settings: ###
    ...
    ### Current time: ###
    ...

.EXAMPLE
    -SetSyncType "NTP" -SetSyncServers "time.nist.gov" -SyncIntervalInMinutes 120

    [Info] Setting host to sync with provided NTP servers...
    [Info] Host is currently set to sync time from domain. Changing to NTP.
    [Info] Successfully set host to sync using NTP.
    [Info] Changing NTP sync servers from 'time-a-g.nist.gov 129.6.15.29' to 'time.nist.gov'...
    [Info] Successfully set host to use the following servers for NTP: time.nist.gov

    [Info] Setting sync interval to 120 minutes...
    [Info] Setting HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NTPClient to 7200...
    [Info] Successfully changed sync interval from 4 minutes (240) to 120 minutes (7200).

    ### Previous time sync settings: ###

    Sync Type                      : Domain only
    NTP Servers                    : time-a-g.nist.gov, 129.6.15.29
    Last Sync Time                 : 7/3/2025 12:09:59 PM
    Last Sync Source               : Local CMOS Clock
    Sync Interval (NTP)            : 4 minutes
    Sync Interval Minimum (Domain) : 1 minutes
    Sync Interval Maximum (Domain) : 546 minutes

    ### Current time zone settings: ###
    ...

    ### Current time sync settings: ###

    Sync Type                      : NTP only
    NTP Servers                    : time.nist.gov
    Last Sync Time                 : 5/5/2025 3:59:03 PM
    Last Sync Source               : Local CMOS Clock
    Sync Interval (NTP)            : 120 minutes
    Sync Interval Minimum (Domain) : 1 minutes
    Sync Interval Maximum (Domain) : 546 minutes

    ### Current time: ###
    ...

.EXAMPLE
    -SetSyncType "NT5DS" -SyncNow

    [Info] Setting host to sync time from the domain...
    [Info] Host is currently set to sync time from NTP. Changing to domain.
    [Info] Successfully set host to sync time from domain.

    [Info] Attempting to force a sync with current time settings...
    Sending resync command to local computer
    The command completed successfully.

    ### Previous time sync settings: ###

    Sync Type                      : NTP only
    NTP Servers                    : time.nist.gov
    Last Sync Time                 : 7/3/2025 2:01:22 PM
    Last Sync Source               : time.nist.gov
    Sync Interval (NTP)            : 120 minutes
    Sync Interval Minimum (Domain) : 1 minutes
    Sync Interval Maximum (Domain) : 546 minutes

    ### Current time zone settings: ###
    ...

    ### Current time sync settings: ###

    Sync Type                      : Domain only
    NTP Servers                    : time.nist.gov
    Last Sync Time                 : 5/5/2025 4:04:45 PM
    Last Sync Source               : SRV16-DC1-TEST.test.lan
    Sync Interval (NTP)            : 120 minutes
    Sync Interval Minimum (Domain) : 1 minutes
    Sync Interval Maximum (Domain) : 17 minutes

    ### Current time: ###
    ...

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Version: 1.1
    Release Notes: Adjusted so 'List Time Zone' displays the time zone ID. Time zone ID is also now required to set the appropriate time zone.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$ListTimeZones = [System.Convert]::ToBoolean($env:ListTimeZones),

    [Parameter()]
    [string]$SetTimeZone,

    [Parameter()]
    [string]$SetSyncType,

    [Parameter()]
    [string]$SetSyncServers,

    [Parameter()]
    $SyncIntervalInMinutes,

    [Parameter()]
    [string]$EnableOrDisableGuestVMToHostSync,

    [Parameter()]
    [switch]$EnableAndStartWindowsTimeService = [System.Convert]::ToBoolean($env:EnableAndStartWindowsTimeService),

    [Parameter()]
    [switch]$SyncNow = [System.Convert]::ToBoolean($env:SyncNow)
)

begin {
    # Import script variables
    if ($env:setTimeZone) {
        if ([string]::IsNullOrWhiteSpace($env:setTimeZone)) {
            Write-Host -Object "[Error] Provided time zone is blank. Please provide a valid time zone."
            exit 1
        }
        $SetTimeZone = $env:setTimeZone.Trim()
    }
    if ($env:setSyncType) { $SetSyncType = $env:setSyncType }
    if ($env:setSyncServers) {
        if ([string]::IsNullOrWhiteSpace($env:SetSyncServers)) {
            Write-Host -Object "[Error] Provided sync servers are blank. Please provide a valid list of NTP servers separated by commas."
            exit 1
        }
        $SetSyncServers = $env:setSyncServers.Trim()
    }
    if ($env:syncIntervalInMinutes) {$SyncIntervalInMinutes = $env:syncIntervalInMinutes }
    if ($env:EnableOrDisableGuestVMToHostSync) { $EnableOrDisableGuestVMToHostSync = $env:EnableOrDisableGuestVMToHostSync }

    # Validate the provided sync interval is an integer
    if ($SyncIntervalInMinutes) {
        try {
            $SyncIntervalInMinutes = [int]$SyncIntervalInMinutes
        }
        catch {
            Write-Host -Object "[Error] '$SyncIntervalInMinutes' is not a valid integer. Please provide a valid integer value for the sync interval in minutes."
            exit 1
        }
    }

    function Test-IsDomainJoined {
        # Check the PowerShell version to determine the appropriate cmdlet to use
        try {
            if ($PSVersionTable.PSVersion.Major -lt 3) {
                return $(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
            }
            else {
                return $(Get-CimInstance -Class Win32_ComputerSystem).PartOfDomain
            }
        }
        catch {
            Write-Host -Object "[Error] Unable to validate whether or not this device is a part of a domain."
            Write-Host -Object "[Error] $($_.Exception.Message)"
            exit 1
        }
    }

    function Test-IsDomainReachable {
        try {
            $searcher = [adsisearcher]"(&(objectCategory=computer)(name=$env:ComputerName))"
            $searcher.FindOne()
        }
        catch {
            Write-Host -Object "[Error] Failed to connect to the domain!"
            Write-Host -Object "[Error] $($_.Exception.Message)"
            $False
        }
    }

    function Test-IsElevated {
        [CmdletBinding()]
        param ()

        # Get the current Windows identity of the user running the script
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()

        # Create a WindowsPrincipal object based on the current identity
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)

        # Check if the current user is in the Administrator role
        # The function returns $True if the user has administrative privileges, $False otherwise
        # 544 is the value for the Built In Administrators role
        # Reference: https://learn.microsoft.com/en-us/dotnet/api/system.security.principal.windowsbuiltinrole
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]'544')
    }

    function Test-IsVM {
        try {
            # first test via model. Hyper-V and VMWare sets these properties automatically and they are read-only
            if ($PSVersionTable.PSVersion.Major -lt 3) {
                $model = (Get-WmiObject -Class Win32_ComputerSystem -Property Model -ErrorAction Stop).Model
            }
            else {
                $model = (Get-CimInstance -ClassName Win32_ComputerSystem -Property Model -ErrorAction Stop).Model
            }

            # Hyper-V uses "Virtual Machine" VMWare uses "VM"
            if ($model -match "Virtual|VM"){
                return $true
            }
            else{
                # Proxmox can be identified via the manufacturer
                if ($PSVersionTable.PSVersion.Major -lt 3) {
                    $manufacturer = (Get-WmiObject -Class Win32_BIOS -Property Manufacturer -ErrorAction Stop).Manufacturer
                }
                else {
                    $manufacturer = (Get-CimInstance -Class Win32_BIOS -Property Manufacturer -ErrorAction Stop).Manufacturer
                }

                if ($manufacturer -match "Proxmox"){
                    return $true
                }
                else{
                    return $false
                }
            }
        }
        catch {
            Write-Host -Object "[Error] Unable to validate whether or not this device is a VM."
            Write-Host -Object "[Error] $($_.Exception.Message)"
            exit 1
        }
    }

    function Set-RegKey {
        [CmdletBinding()]
        param (
            [Parameter()]
            [String]$Path,
            [Parameter()]
            [String]$Name,
            [Parameter()]
            $Value,
            [Parameter()]
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            [String]$PropertyType = "DWord"
        )

        if([String]::IsNullOrWhiteSpace($Path)){
            throw (New-Object System.ArgumentNullException("You must provide a valid path to a registry key."))
        }

        if($Path -notmatch "^(Registry::|HKCR:\\|HKCU:\\|HKLM:\\|HKU:\\|HKCC:\\|TestRegistry:\\)"){
            throw (New-Object System.ArgumentException("The path provided '$Path' is invalid as it does not start with 'Registry::', 'HKCR:\', 'HKCU:\', 'HKLM:\', 'HKU:\' or 'HKCC:\'."))
        }

        if($Path -match "^Registry::" -and $Path -notmatch "^Registry::(HKCR\\|HKEY_CLASSES_ROOT\\|HKCU\\|HKEY_CURRENT_USER\\|HKLM\\|HKEY_LOCAL_MACHINE|HKU\\|HKEY_USERS|HKCC\\|HKEY_CURRENT_CONFIG)"){
            throw (New-Object System.ArgumentException("The path provided '$Path' is invalid as it does not start with a valid registry root such as 'HKLM\' or 'HKEY_LOCAL_MACHINE\'."))
        }

        if([String]::IsNullOrWhiteSpace($Name)){
            throw (New-Object System.ArgumentNullException("You must provide a valid name for the registry property."))
        }

        # Create list to store status messages
        $Status = [System.Collections.Generic.List[String]]::new()

        # Check if the specified registry path exists
        if (!(Test-Path -Path $Path)) {
            try {
                # If the path does not exist, create it
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
                $Status.Add("CreatedPath")
            }
            catch {
                throw $_
            }
        }

        # Check if the registry key already exists at the specified path
        if (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
            # Retrieve the current value of the registry key
            $previousValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
            if ($previousValue -eq $Value) {
                $Status.Add("AlreadySet")
            }
            else {
                try {
                    # Update the registry key with the new value
                    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
                    $Status.Add("Updated")
                }
                catch {
                    throw $_
                }
            }
        }
        else {
            try {
                # If the registry key does not exist, create it with the specified value and property type
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
                $Status.Add("CreatedRegKey")
            }
            catch {
                throw $_
            }
        }

        # Output will be the registry key and its value
        try {
            $output = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        }
        catch {
            throw $_
        }

        # Add previous value to the output object
        $output | Add-Member -MemberType NoteProperty -Name "PreviousValue" -Value $previousValue
        # Add status to the output object
        $output | Add-Member -MemberType NoteProperty -Name "Status" -Value $Status
        return $output
    }

    function Get-TimeSettings {
        # Get the time sync status
        try {
            $StatusOutputFilename = "$env:temp\w32tm_status_output_$(Get-Random).txt"
            Start-Process -FilePath "$env:WinDir\system32\w32tm.exe" -ArgumentList "/query /status" -RedirectStandardOutput $StatusOutputFilename -NoNewWindow -Wait
        }
        catch {
            throw (New-Object System.Exception("Unable to retrieve time sync status."))
        }

        # Get the time sync configuration
        try {
            $ConfigOutputFilename = "$env:temp\w32tm_config_output_$(Get-Random).txt"
            Start-Process -FilePath "$env:WinDir\system32\w32tm.exe" -ArgumentList "/query /configuration" -RedirectStandardOutput $ConfigOutputFilename -NoNewWindow -Wait
        }
        catch {
            throw (New-Object System.Exception("Unable to retrieve time sync configuration."))
        }

        # Attempt to read the status output file
        try {
            $status = Get-Content $StatusOutputFilename -Encoding Oem
        }
        catch {
            throw (New-Object System.Exception("Unable to read time sync status."))
        }

        # Attempt to read the config output file
        try {
            $config = Get-Content $ConfigOutputFilename -Encoding Oem
        }
        catch {
            throw (New-Object System.Exception("Unable to read time sync configuration."))
        }

        $lastSyncTime = ($status[-4] -replace "^\w+:\s" -replace "^.+: " | Out-String).Trim()
        $lastSyncSource = ($status[-3] -replace "^\w+:\s" -replace "^.+: " -replace ",0x\w" | Out-String).Trim()
        $syncType = (($config | Select-String -Pattern "^Type: ") -replace "Type: " -replace "\(.+$" | Out-String).Trim()

        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
        $NtpServers = (Get-ItemProperty -Path $regPath -Name "NtpServer" -ErrorAction SilentlyContinue).NtpServer.Trim() -replace ",0x\w" -replace "\s", ", "

        $syncType = switch ($syncType) {
            "NTP" { "NTP only" }
            "NT5DS" { "Domain only" }
            "AllSync" { "Domain with NTP as fallback" }
            default { "Unknown" }
        }

        # Get the SpecialPollInterval from the config
        $SpecialPollInterval = ($config | Select-String -Pattern "^SpecialPollInterval: ") -replace "SpecialPollInterval: " -replace "\(.+$"
        # Convert the SpecialPollInterval to minutes
        $SpecialPollIntervalInMinutes = [int]$SpecialPollInterval / 60

        $object = [PSCustomObject]@{
            "Sync Type"           = $syncType
            "NTP Servers"         = $NtpServers
            "Last Sync Time"      = $lastSyncTime
            "Last Sync Source"    = $lastSyncSource
            "Sync Interval (NTP)" = "$SpecialPollIntervalInMinutes minutes"
        }

        # Get the Min and Max poll intervals used for domain time sync
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
        $MinPollInterval = (Get-ItemProperty -Path $regPath -Name "MinPollInterval" -ErrorAction SilentlyContinue).MinPollInterval
        $MaxPollInterval = (Get-ItemProperty -Path $regPath -Name "MaxPollInterval" -ErrorAction SilentlyContinue).MaxPollInterval

        if ($MinPollInterval -and $MaxPollInterval) {
            # These values are actually powers of 2, the resulting value is the amount of seconds
            $MinPollInterval = [math]::Pow(2, $MinPollInterval)
            $MaxPollInterval = [math]::Pow(2, $MaxPollInterval)

            # Convert those seconds to minutes
            $MinPollInterval = [math]::Round($MinPollInterval / 60)
            $MaxPollInterval = [math]::Round($MaxPollInterval / 60)

            # Add the intervals to the object
            $object | Add-Member -MemberType NoteProperty -Name "Sync Interval Minimum (Domain)" -Value "$MinPollInterval minutes"
            $object | Add-Member -MemberType NoteProperty -Name "Sync Interval Maximum (Domain)" -Value "$MaxPollInterval minutes"
        }
        else {
            Write-Host -Object "[Warning] Unable to retrieve the minimum and maximum poll intervals from the registry."
            $object | Add-Member -MemberType NoteProperty -Name "Sync Interval Minimum (Domain)" -Value "Unavailable"
            $object | Add-Member -MemberType NoteProperty -Name "Sync Interval Maximum (Domain)" -Value "Unavailable"
        }

        # Attempt to remove the status output file
        try {
            Remove-Item $StatusOutputFilename -ErrorAction Stop
        }
        catch {
            Write-Host -Object "[Warning] Unable to delete the temporary file '$StatusOutputFilename'."
        }

        # Attempt to remove the config output file
        try {
            Remove-Item $ConfigOutputFilename -ErrorAction Stop
        }
        catch {
            Write-Host -Object "[Warning] Unable to delete the temporary file '$ConfigOutputFilename'."
        }

        return $object
    }

}
process {
    # Attempt to determine if the current session is running with Administrator privileges.
    try {
        $IsElevated = Test-IsElevated -ErrorAction Stop
    }
    catch {
        Write-Host -Object "[Error] $($_.Exception.Message)"
        Write-Host -Object "[Error] Unable to determine if the account '$env:Username' is running with Administrator privileges."
        exit 1
    }

    if (!$IsElevated) {
        Write-Host -Object "[Error] Access Denied: The user '$env:Username' does not have administrator privileges, or the script is not running with elevated permissions."
        exit 1
    }

    # Error if the script is running on an unsupported OS
    try {
        $os = Get-CimInstance -Class Win32_OperatingSystem -ErrorAction Stop
        if ($os.Caption -notmatch "Windows 10|Windows 11|Windows Server 2016|Windows Server 2019|Windows Server 2022") {
            Write-Host -Object "[Error] $($OS.Caption) is not supported. This script only supports Windows 10+ and  Windows Server 2016+."
            exit 1
        }
    }
    catch {
        Write-Host -Object "[Error] Unable to determine the operating system."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    # Error if no choices are selected
    if (-not ($SetTimeZone -or $SetSyncType -or $SetSyncServers -or $SyncIntervalInMinutes -or $ListTimeZones -or $EnableOrDisableGuestVMToHostSync -or $EnableAndStartWindowsTimeService -or $SyncNow)) {
        Write-Host -Object "[Error] No parameters provided. Please provide at least one parameter."
        exit 1
    }

    # Warn that if list timezones is selected, other options will be ignored
    if ($ListTimeZones -and ($SetTimeZone -or $SetSyncType -or $SetSyncServers -or $SyncIntervalInMinutes -or $EnableOrDisableGuestVMToHostSync -or $EnableAndStartWindowsTimeService -or $SyncNow)) {
        Write-Host -Object "[Warning] ListTimeZones cannot be used with other options."
    }

    # List all available time zones if selected and exit
    if ($ListTimeZones) {
        try {
            $timeZones = Get-TimeZone -ListAvailable -ErrorAction Stop | Sort-Object Id
            Write-Host ""
            ($timeZones | Select-Object Id | Format-Table | Out-String).Trim()
        }
        catch {
            Write-Host -Object "[Error] Unable to list available time zones."
            Write-Host -Object "[Error] $($_.Exception.Message)"
            exit 1
        }
        exit 0
    }

    # Validate SetSyncType
    if ($SetSyncType -and $SetSyncType -notin @("Both", "NTP", "NT5DS", "Both - Prefer Domain, NTP Servers As Fallback", "NTP - Use Sync Servers", "NT5DS - Sync From Domain")) {
        Write-Host -Object "[Error] Invalid sync type selected. Please choose 'Both', 'NTP' or 'NT5DS'."
        exit 1
    }

    # Set flags for syncing source options
    switch -Regex ($SetSyncType) {
        "^NTP" { $SyncFromNTP = $true }
        "^NT5DS" { $SyncFromDomain = $true }
        "^Both" { $SyncFromDomain = $true; $SyncFromNTP = $true }
    }

    # Error if sync servers are provided but we are not syncing from NTP
    if ($SetSyncServers -and -not $SyncFromNTP) {
        Write-Host -Object "[Error] Sync servers can only be set when syncing from NTP. Please choose 'Both' or 'NTP' as the sync type if you want to specify servers to sync with."
        exit 1
    }

    # Error if we are syncing from NTP but no interval is set
    if ($SyncFromNTP -and -not $SyncIntervalInMinutes) {
        Write-Host -Object "[Error] Sync interval must be set when syncing from NTP servers. Please provide a sync interval between 1 and 546."
        exit 1
    }

    # Error if we are setting a sync type and the host is a VM, but no option is set for guest VM to host sync
    if ($SetSyncType -and (Test-IsVM) -and [string]::IsNullOrWhiteSpace($EnableOrDisableGuestVMToHostSync)) {
        Write-Host -Object "[Error] 'Enable or Disable Guest VM To Host Sync' must be set when running on a virtual machine. Please provide a value of 'Enable' or 'Disable'."
        exit 1
    }

    # Validate EnableOrDisableGuestVMToHostSync
    if ($EnableOrDisableGuestVMToHostSync -and $EnableOrDisableGuestVMToHostSync -notin @("Enable", "Disable")) {
        Write-Host -Object "[Error] Invalid input for 'Enable Or Disable Guest VM To Host Sync'. Valid options are: Enable, Disable"
        exit 1
    }

    # Validate sync interval is in range
    if ($SyncIntervalInMinutes -and ($SyncIntervalInMinutes -lt 1 -or $SyncIntervalInMinutes -gt 546)) {
        Write-Host -Object "[Error] Sync interval must be between 1 and 546 minutes."
        exit 1
    }

    $ExitCode = 0

    # Determine if the device is joined to a domain
    try {
        $IsDomainJoined = Test-IsDomainJoined -ErrorAction Stop
    }
    catch {
        Write-Host -Object "[Error] Unable to determine if the device is joined to a domain."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    # Warn the user that GPOs might overwrite these settings if the device is domain joined
    if ($IsDomainJoined) {
        Write-Host -Object "`n[Warning] This device is joined to a domain. Group Policies may override the settings you are trying to apply."
    }

    # Verify the requested time zone is valid
    if ($SetTimeZone) {
        try {
            $timeZoneToSet = Get-TimeZone -ListAvailable -ErrorAction Stop | Where-Object { $_.Id -eq "$SetTimeZone" }
        }
        catch {
            Write-Host -Object "[Error] Unable to find time zone '$SetTimeZone'. Please use the 'List Time Zones' option to see all valid time zones."
            Write-Host -Object "[Error] $($_.Exception.Message)"
            # If the time zone is invalid, set the flag to skip the rest of the time sync settings
            $skipSettings = $true
            $ExitCode = 1
        }

        # Set time zone if a valid time zone is found
        if ($timeZoneToSet) {
            Write-Host -Object "`n[Info] Setting time zone to '$SetTimeZone'..."

            # Retrieve current time zone for comparison
            try {
                $currentTimeZone = Get-TimeZone -ErrorAction Stop
            }
            catch {
                Write-Host -Object "[Error] Unable to retrieve current time zone settings."
                Write-Host -Object "[Error] $($_.Exception.Message)"
                $ExitCode = 1
            }

            if ($currentTimeZone.Id -eq $timeZoneToSet.Id) {
                Write-Host -Object "[Info] Time zone is already set to '$SetTimeZone'."
            }
            else {
                # Set the validated time zone
                try {
                    Write-Host -Object "[Info] Changing time zone from '$($currentTimeZone.DisplayName)' to '$($timeZoneToSet.DisplayName)'..."
                    Set-TimeZone -Id $timeZoneToSet.Id -ErrorAction Stop
                    Write-Host -Object "[Info] Time zone successfully set to '$SetTimeZone'."
                    $timeZoneChanged = $true
                }
                catch {
                    Write-Host -Object "[Error] Unable to set time zone to '$SetTimeZone'."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    exit 1
                }
            }
        }
        else {
            Write-Host -Object "[Error] Unable to find time zone '$SetTimeZone'. Please use the 'List Time Zones' option to see all valid time zones."
            $skipSettings = $true
            $ExitCode = 1
        }
    }

    # Get status of Windows Time Service
    # This service is required for the rest of the sync settings to work
    try {
        $WindowsTimeService = Get-Service -Name "w32time" -ErrorAction Stop
    }
    catch {
        Write-Host -Object "[Error] Unable to retrieve Windows Time service status."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    # Enable the Windows Time service if requested
    if ($EnableAndStartWindowsTimeService) {
        Write-Host -Object "`n[Info] Setting Windows Time service to start up automatically..."

        if ($WindowsTimeService.StartType -ne "Automatic") {
            try {
                Set-Service -Name "w32time" -StartupType Automatic -ErrorAction Stop
                Write-Host -Object "[Info] Windows Time service enabled successfully."
            }
            catch {
                Write-Host -Object "[Error] Unable to enable Windows Time service."
                Write-Host -Object "[Error] $($_.Exception.Message)"
                # Set flag to true so that we can skip the rest of the sync settings
                $serviceError = $true
                $ExitCode = 1
            }
        }
        else {
            Write-Host "[Info] Windows Time service is already set to start automatically."
        }

        Write-Host -Object "`n[Info] Starting Windows Time service..."
        if ($WindowsTimeService.Status -ne "Running") {
            try {
                Start-Service -Name "w32time" -WarningAction SilentlyContinue -ErrorAction Stop
                Write-Host -Object "[Info] Windows Time service started successfully."
            }
            catch {
                Write-Host -Object "[Error] Unable to enable Windows Time service."
                Write-Host -Object "[Error] $($_.Exception.Message)"
                # Set flag to true so that we can skip the rest of the sync settings
                $serviceError = $true
                $ExitCode = 1
            }
        }
        else {
            Write-Host "[Info] Windows Time service is already running."
        }
        Write-Host ""
    }
    # Otherwise check if the service is running and set to start automatically, error if not
    else {
        if ($WindowsTimeService.StartType -ne "Automatic") {
            Write-Host "`n[Error] Windows Time service is not set to start automatically. Please use the 'Enable and Start Windows Time Service' option to enable it."
            # Set flag to true so that we can skip the rest of the sync settings
            $serviceError = $true
            $ExitCode = 1
        }
        elseif ($WindowsTimeService.Status -ne "Running") {
            Write-Host "`n[Error] Windows Time service is not running. Please use the 'Enable and Start Windows Time Service' option to start it."
            # Set flag to true so that we can skip the rest of the sync settings
            $serviceError = $true
            $ExitCode = 1
        }
    }

    # Get current time sync settings
    if (-not $serviceError) {
        try {
            $currentTimeSyncSettings = Get-TimeSettings -ErrorAction Stop
        }
        catch {
            Write-Host -Object "[Error] Unable to retrieve current time sync settings."
            Write-Host -Object "[Error] $($_.Exception.Message)"
            $ExitCode = 1
        }
    }

    # Skip the rest of the sync settings if the time zone was invalid (so $skipSettings is true)
    if ($skipSettings) {
        Write-Host "`n[Error] Skipping time zone and sync settings because the given time zone is invalid."
    }
    # or if the Windows Time service is not running (so $serviceError is true), and we are setting sync settings
    elseif ($serviceError -and ($SetSyncType -or $SetSyncServers -or $SyncIntervalInMinutes -or $EnableOrDisableGuestVMToHostSync)) {
        Write-Host "`n[Error] Skipping time sync settings because Windows Time service is not running."
    }
    # Otherwise, proceed with setting the provided time sync settings
    elseif ($SetSyncType -or $SetSyncServers -or $SyncIntervalInMinutes -or $EnableOrDisableGuestVMToHostSync) {
        # Warn if sync interval is set when syncing from domain only
        if ($SyncFromDomain -and -not $SyncFromNTP -and $SyncIntervalInMinutes) {
            Write-Host -Object "`n[Warning] Sync interval is only applicable when syncing from NTP servers. Setting the interval will be skipped."
            $SyncIntervalInMinutes = $null
        }

        # Get current min and max poll values. These are used to determine if the sync interval is valid when NTP is in use, or if the min/max values need to be changed back to support the default domain only behavior
        $configRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
        $minPollValue = (Get-ItemProperty -Path $configRegPath -Name "MinPollInterval" -ErrorAction SilentlyContinue).MinPollInterval
        $maxPollValue = (Get-ItemProperty -Path $configRegPath -Name "MaxPollInterval" -ErrorAction SilentlyContinue).MaxPollInterval

        # If sync interval is set, validate the min and max poll intervals
        if ($SyncIntervalInMinutes) {

            # The minimum poll interval is 5 (2^5 = 32 seconds) and the maximum poll interval is 15 (2^15 = 546 minutes)
            # Check that minimum poll interval is set to its min (5 is 32 seconds)
            # If not, set the value to 5 so that the Sync Interval can be set safely
            if ($minPollValue -ne 5) {
                try {
                    Write-Host "`n[Info] Setting registry to decrease minimum allowable sync interval so that it can be set safely."
                    Write-Host "[Info] Setting $configRegPath\MinPollInterval to 5."
                    $set = Set-RegKey -Path $configRegPath -Name "MinPollInterval" -Value 5 -PropertyType "DWord"
                    Write-Host "[Info] Successfully set $configRegPath\MinPollInterval to 5 (previous value $($set.PreviousValue))."
                }
                catch {
                    Write-Host -Object "[Error] Unable to set minimum poll interval to its min value."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    exit 1
                }
            }

            # Check that maximum poll interval is set to its max (15 is 546 minutes)
            # If not, set the value to 15 so that the Sync Interval can be set safely
            if ($maxPollValue -ne 15) {
                try {
                    Write-Host "`n[Info] Setting registry to increase maximum allowable sync interval so that it can be set safely."
                    Write-Host "[Info] Setting $configRegPath\MaxPollInterval to 15."
                    $set = Set-RegKey -Path $configRegPath -Name "MaxPollInterval" -Value 15 -PropertyType "DWord"
                    Write-Host "[Info] Successfully set $configRegPath\MaxPollInterval to 15 (previous value $($set.PreviousValue))."
                }
                catch {
                    Write-Host -Object "[Error] Unable to set maximum poll interval to its max value."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    exit 1
                }
            }
        }

        # If syncing from domain, test if domain is joined and reachable
        # If either test fails, skip setting the sync type to domain
        if ($SyncFromDomain) {
            if (-not ($IsDomainJoined)) {
                Write-Host -Object "[Error] The system is not domain joined. Cannot set host to sync time from domain."
                $SyncFromDomain = $null
                $ExitCode = 1
            }
            elseif (-not (Test-IsDomainReachable)) {
                Write-Host -Object "[Error] The system is not able to reach the domain. Cannot set host to sync time from domain."
                $SyncFromDomain = $null
                $ExitCode = 1
            }
        }

        # If sync servers are set, validate each one
        if ($SetSyncServers) {
            # Split the SetSyncServers string into an array if it contains multiple servers
            [array]$SetSyncServers = ($SetSyncServers -split ",").Trim()

            # Create a list to store validated sync servers
            $ValidatedSyncServers = [System.Collections.Generic.List[String]]::new()

            # Validate SetSyncServers
            foreach ($server in $SetSyncServers) {
                # Test NTP response from the server
                $testNTP = w32tm.exe /stripchart /computer:$server /samples:1 /dataonly

                # Use regex to determine if the NTP test was successful
                # The last line of the output should be in the format: "xx:xx:xx, +/-x.xs"
                if ($testNTP[-1] -notmatch "^\d{2}\:\d{2}\:\d{2}\,\s[\+,\-]\d+\.\d+s") {
                    Write-Host -Object "[Error] Unable to connect to NTP server: '$server'"
                    $ExitCode = 1
                    continue
                }

                # Determine sync flag value to append
                # Sync flags used below are:
                #   0x9 - Combines 'Use SpecialPollInterval' (0x1) and 'Force client mode' (0x8)
                #   0xB - Combines 'Use SpecialPollInterval' (0x1), 'Force client mode' (0x8) and 'Use as fallback only' (0x2)
                if ($SyncFromNTP -and -not $SyncFromDomain) {
                    $syncFlagValue = ",0x9"
                }
                elseif ($SyncFromDomain -and $SyncFromNTP) {
                    $syncFlagValue = ",0xB"
                }

                # Add validated server to list
                $ValidatedSyncServers.Add("$server$SyncFlagValue")
            }
        }

        # This path is only present on virtual machines
        $ProviderRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider"

        # Set guest VM to host sync if specified
        if ($EnableOrDisableGuestVMToHostSync) {
            # If the path exists, move forward with changing the value
            if (Test-Path $ProviderRegPath) {
                $ProviderEnabled = (Get-ItemProperty -Path $ProviderRegPath -Name "Enabled" -ErrorAction SilentlyContinue).Enabled

                switch ($EnableOrDisableGuestVMToHostSync) {
                    "Enable" { $desiredValue = 1 }
                    "Disable" { $desiredValue = 0 }
                }

                Write-Host -Object "`n[Info] Setting VM time provider to $EnableOrDisableGuestVMToHostSync."
                if ($ProviderEnabled -ne $desiredValue) {
                    try {
                        Write-Host -Object "[Info] Setting $providerRegPath\Enabled to $desiredValue."
                        $set = Set-RegKey -Path $ProviderRegPath -Name "Enabled" -Value $desiredValue -PropertyType "DWord"
                        Write-Host "[Info] Successfully set $providerRegPath\Enabled to $desiredValue (previous value $($set.PreviousValue))."
                    }
                    catch {
                        Write-Host -Object "[Error] Unable to disable VM time provider."
                        Write-Host -Object "[Error] $($_.Exception.Message)"
                        $ExitCode = 1
                    }
                }
                else {
                    Write-Host -Object "[Info] The VM time provider is already set to $EnableOrDisableGuestVMToHostSync."
                }
            }
            else {
                Write-Host -Object "`n[Warning] The VM time provider cannot be found. This may be because $env:computername is not a VM. No changes will be made to the guest VM to host sync option."
            }
        }

        # Check if the VM time provider is enabled again since it may have changed above
        # If so, and we are setting a sync source, warn the user that it may lead to inconsistency
        $ProviderEnabled = (Get-ItemProperty -Path $ProviderRegPath -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
        if (($SyncFromNTP -or $SyncFromDomain) -and $ProviderEnabled -eq 1) {
            Write-Host "`n[Warning] Guest VM to host sync is enabled. This may cause inconsistency with time sync settings."
        }

        # Get current Type and NTPServer values
        $parametersRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
        $currentType = (Get-ItemProperty -Path $parametersRegPath -Name "Type" -ErrorAction SilentlyContinue).Type
        $currentServers = (Get-ItemProperty -Path $parametersRegPath -Name "NtpServer" -ErrorAction SilentlyContinue).NtpServer

        # Set sync type to domain and NTP if "Both" was selected
        # Otherwise set to domain or NTP only
        if ($SyncFromDomain -and $SyncFromNTP) {
            Write-Host -Object "`n[Info] Setting host to sync time from the domain and NTP..."

            if ($currentType -eq "AllSync") {
                Write-Host -Object "[Info] Host is already set to sync time from both domain and NTP."
            }
            else {
                switch ($currentType) {
                    "NTP" {
                        Write-Host -Object "[Info] Host is currently set to sync time from NTP. Changing to domain and NTP."
                    }
                    "NT5DS" {
                        Write-Host -Object "[Info] Host is currently set to sync time from domain only. Changing to domain and NTP."
                    }
                }

                try {
                    w32tm.exe /config /syncfromflags:domhier, manual /update | Out-Null
                    Write-Host -Object "[Info] Successfully set host to sync time from domain and NTP."
                    $timeSyncSettingsChanged = $true
                }
                catch {
                    Write-Host -Object "[Error] Unable to set time to sync from domain."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }
            }
        }
        elseif ($SyncFromNTP) {
            Write-Host -Object "`n[Info] Setting host to sync with provided NTP servers..."
            # Only set sync to NTP if one of the servers is valid, or there is a currently set server
            if ($ValidatedSyncServers -or $currentServers) {
                if ($currentType -eq "NTP") {
                    Write-Host -Object "[Info] Host is already set to sync time using NTP."
                }
                else {
                    switch ($currentType) {
                        "NT5DS" {
                            Write-Host -Object "[Info] Host is currently set to sync time from domain. Changing to NTP."
                        }
                        "AllSync" {
                            Write-Host -Object "[Info] Host is currently set to sync time from both domain and NTP. Changing to NTP only."
                        }
                    }

                    try {
                        w32tm.exe /config /syncfromflags:manual /reliable:YES /update | Out-Null
                        Write-Host -Object "[Info] Successfully set host to sync using NTP."
                        $timeSyncSettingsChanged = $true
                    }
                    catch {
                        Write-Host -Object "[Error] Unable to set sync type to NTP."
                        Write-Host -Object "[Error] $($_.Exception.Message)"
                        $ExitCode = 1
                    }
                }
            }
        }
        elseif ($SyncFromDomain) {
            Write-Host -Object "`n[Info] Setting host to sync time from the domain..."

            if ($currentType -eq "NT5DS") {
                Write-Host -Object "[Info] Host is already set to sync time from domain."
            }
            else {
                switch ($currentType) {
                    "NTP" {
                        Write-Host -Object "[Info] Host is currently set to sync time from NTP. Changing to domain."
                    }
                    "AllSync" {
                        Write-Host -Object "[Info] Host is currently set to sync time from both domain and NTP. Changing to domain only."
                    }
                }
                try {
                    w32tm.exe /config /syncfromflags:domhier /update | Out-Null
                    Write-Host -Object "[Info] Successfully set host to sync time from domain."
                    $timeSyncSettingsChanged = $true
                }
                catch {
                    Write-Host -Object "[Error] Unable to set time to sync from domain."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }
            }

            # Define the default values based on OS
            switch -Regex ((Get-CimInstance -Class Win32_OperatingSystem).Caption) {
                "Windows 10" { $defaultMinPollValue = 10; $defaultMaxPollValue = 15 }
                "Windows 11" { $defaultMinPollValue = 10; $defaultMaxPollValue = 15 }
                "Windows Server" { $defaultMinPollValue = 6; $defaultMaxPollValue = 10 }
            }

            # Set min and max poll values back to default if they were changed
            if ($minPollValue -ne $defaultMinPollValue) {
                try {
                    Write-Host -Object "`n[Info] Setting minimum allowable sync interval back to the default value."
                    Write-Host -Object "[Info] Setting $configRegPath\MinPollInterval to $defaultMinPollValue."
                    $set = Set-RegKey -Path $configRegPath -Name "MinPollInterval" -Value $defaultMinPollValue -PropertyType "DWord"
                    Write-Host -Object "[Info] Successfully set $configRegPath\MinPollInterval to $defaultMinPollValue (previous value $($set.PreviousValue))."
                    $timeSyncSettingsChanged = $true
                }
                catch {
                    Write-Host -Object "[Error] Unable to set minimum poll interval to its default value."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }
            }

            if ($maxPollValue -ne $defaultMaxPollValue) {
                try {
                    Write-Host -Object "`n[Info] Setting maximum allowable sync interval back to the default value."
                    Write-Host -Object "[Info] Setting $configRegPath\MaxPollInterval to $defaultMaxPollValue."
                    $set = Set-RegKey -Path $configRegPath -Name "MaxPollInterval" -Value $defaultMaxPollValue -PropertyType "DWord"
                    Write-Host -Object "[Info] Successfully set $configRegPath\MaxPollInterval to $defaultMaxPollValue (previous value $($set.PreviousValue))."
                    $timeSyncSettingsChanged = $true
                }
                catch {
                    Write-Host -Object "[Error] Unable to set maximum poll interval to its default value."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }
            }
        }

        # Warn the user if using current servers because no valid servers were provided
        if ($SyncFromNTP -and $currentServers -and -not $ValidatedSyncServers) {
            Write-Host -Object "[Warning] No valid NTP servers provided. Currently set servers will be used: $($currentServers -replace ",0x\w")"
        }

        # Set the sync server list if at least one is valid
        # Otherwise, error if NTP sync was requested but there are no current servers
        if ($ValidatedSyncServers) {
            $SyncServerList = $ValidatedSyncServers -join " "

            # Warn if sync type is not set to NTP
            if ($currentType -notmatch "AllSync|NTP" -and -not $SyncFromNTP) {
                Write-Host -Object "[Warning] Sync type is not set to NTP. Setting sync servers will not take effect until the sync type is set to NTP."
            }

            if ($currentServers -eq $SyncServerList) {
                Write-Host -Object "[Info] NTP sync servers are already set to: $($SyncServerList -replace ",0x\w")"
            }
            else {
                try {
                    Write-Host -Object "[Info] Changing NTP sync servers from '$($currentServers -replace ",0x\w")' to '$($SyncServerList -replace ",0x\w")'..."
                    w32tm.exe /config /manualpeerlist:$SyncServerList /reliable:YES /update | Out-Null
                    Write-Host -Object "[Info] Successfully set host to use the following servers for NTP: $($SyncServerList -replace ",0x\w")"
                    $timeSyncSettingsChanged = $true
                }
                catch {
                    Write-Host -Object "[Error] Unable to set host to sync NTP with the servers: $($SyncServerList -replace ",0x\w")"
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }
            }
        }
        elseif ($SyncFromNTP -and -not $currentServers) {
            Write-Host -Object "[Error] No valid NTP servers provided. Please provide valid NTP servers."
            $ExitCode = 1
        }

        # Set sync interval
        if ($SyncIntervalInMinutes) {
            Write-Host -Object "`n[Info] Setting sync interval to $SyncIntervalInMinutes minutes..."

            # Path to the registry key
            $NTPClientRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NTPClient"

            try {
                # Value is in seconds so need to convert minutes to seconds
                $valueToSet = $SyncIntervalInMinutes * 60

                Write-Host -Object "[Info] Setting $NTPClientRegPath to $valueToSet..."

                # Set the interval registry key
                $set = Set-RegKey -Path $NTPClientRegPath -Name "SpecialPollInterval" -Value $valueToSet -PropertyType "DWord"

                # For changes to take effect, restart the Windows Time service and update the configuration
                Restart-Service -Name "w32time" -WarningAction SilentlyContinue -ErrorAction Stop
                w32tm.exe /config /update | Out-Null

                # Output results
                if ($set.Status -contains "AlreadySet") {
                    Write-Host -Object "[Info] Sync interval is already set to $SyncIntervalInMinutes minutes."
                }
                else {
                    Write-Host -Object "[Info] Successfully changed sync interval from $($set.PreviousValue / 60) minutes ($($set.PreviousValue)) to $SyncIntervalInMinutes minutes ($valueToSet)."
                    $timeSyncSettingsChanged = $true
                }
            }
            catch {
                Write-Host -Object "[Error] Unable to set sync interval to $SyncIntervalInMinutes minutes."
                Write-Host -Object "[Error] $($_.Exception.Message)"
                $ExitCode = 1
            }
        }
    }

    # Force a sync if selected and there is no issue with the time service (w32tm relies on it to resync)
    if ($syncNow) {
        if ($serviceError) {
            Write-Host "`n[Error] Unable to force a time sync because the Windows Time service is not running."
            $ExitCode = 1
        }
        else {
            # Check the current sync type to determine if we can force a sync
            try {
                $currentSyncType = (Get-TimeSettings -ErrorAction Stop)."Sync Type"
            }
            catch {
                Write-Host -Object "`n[Error] Unable to retrieve current sync type."
                Write-Host -Object "[Error] $($_.Exception.Message)"
                $currentSyncType = "Unknown"
            }

            if ($currentSyncType -eq "Unknown") {
                Write-Host -Object "`n[Error] Unable to determine the current sync type. The time sync settings may not be configured correctly."
                Write-Host -Object "[Error] Unable to force a time sync because the sync type is unknown. Please correct the time sync settings and try again."
                $ExitCode = 1
            }
            else {
                # Force a time sync
                try {
                    Write-Host "`n[Info] Attempting to force a sync with current time settings..."

                    # Create a temporary file to store the output
                    $ResyncOutputFile = "$env:temp\w32tm_resync_output_$(Get-Random).txt"
                    Start-Process -FilePath "$env:Windir\System32\w32tm.exe" -ArgumentList "/resync" -NoNewWindow -Wait -RedirectStandardOutput $ResyncOutputFile -ErrorAction Stop
                }
                catch {
                    Write-Host -Object "[Error] Unable to initiate time sync."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }

                # Make sure the output file exists
                if (Test-Path -Path $ResyncOutputFile) {
                    # Read the output of the time sync
                    try {
                        $outputContent = Get-Content $ResyncOutputFile -Encoding Oem -ErrorAction Stop
                        ($outputContent | Out-String).Trim() | Out-Host
                    }
                    catch {
                        Write-Host -Object "[Error] Unable to read the output of the time sync."
                        Write-Host -Object "[Error] $($_.Exception.Message)"
                        $ExitCode = 1
                    }

                    # Clean up the output file
                    try {
                        Remove-Item -Path $ResyncOutputFile -Force -ErrorAction Stop
                    }
                    catch {
                        Write-Host -Object "[Error] Unable to delete the output file."
                        Write-Host -Object "[Error] $($_.Exception.Message)"
                        $ExitCode = 1
                    }
                }
                else {
                    Write-Host -Object "[Error] Unable to find the output file."
                    $ExitCode = 1
                }
            }
        }
    }

    # Show previous time zone settings
    if ($currentTimeZone -and $timeZoneChanged) {
        Write-Host -Object "`n### Previous time zone settings: ###`n"
        ($currentTimeZone | Out-String).Trim()
    }

    # Show previous time sync settings
    if ($currentTimeSyncSettings -and $timeSyncSettingsChanged) {
        Write-Host -Object "`n### Previous time sync settings: ###`n"
        ($currentTimeSyncSettings | Format-List | Out-String).Trim()
    }

    # Show current time zone settings
    try {
        Write-Host -Object "`n### Current time zone settings: ###`n"
        (Get-TimeZone -ErrorAction Stop | Out-String).Trim()
    }
    catch {
        Write-Host -Object "[Error] Unable to retrieve current time zone settings."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        $ExitCode = 1
    }

    # Show current time sync settings if the Windows Time service is running
    if (-not $serviceError) {
        try {
            Write-Host -Object "`n### Current time sync settings: ###`n"
            (Get-TimeSettings -ErrorAction Stop | Format-List | Out-String).Trim()
        }
        catch {
            Write-Host -Object "[Error] Unable to retrieve current time sync settings."
            Write-Host -Object "[Error] $($_.Exception.Message)"
            $ExitCode = 1
        }
    }
    else {
        Write-Host -Object "`n[Error] Unable to retrieve current time sync settings because the Windows Time service is not running."
    }

    # Show current time
    try {
        Write-Host -Object "`n### Current time: ###"
        Get-Date -DisplayHint DateTime -ErrorAction Stop | Out-Host
    }
    catch {
        Write-Host -Object "[Error] Unable to retrieve current time."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        $ExitCode = 1
    }

    exit $ExitCode
}
end {
    
    
    
}