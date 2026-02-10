#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls applications using UninstallString with automatic silent parameters.

.DESCRIPTION
    Automates the removal of installed applications by locating their registry uninstall entries
    and executing the appropriate uninstallation command with silent parameters. Supports both
    MSI and EXE-based installers with automatic detection and parameter injection.
    
    This script handles typical uninstall patterns such as:
    - msiexec /X{GUID} /qn /norestart
    - uninstall.exe /S /norestart
    - Custom uninstallers with various silent flags
    
    The script searches multiple registry locations including:
    - HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall (64-bit)
    - HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall (32-bit)
    - HKEY_USERS\*\Software\Microsoft\Windows\CurrentVersion\Uninstall (per-user)
    - HKEY_USERS\*\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall (per-user 32-bit)
    
    For MSI-based applications, the script automatically:
    - Converts /I (install) to /X (uninstall)
    - Adds /qn (quiet no UI) if not present
    - Adds /norestart if not present
    
    For EXE-based applications, the script automatically:
    - Adds /S (silent) if not present
    - Adds /norestart if not present
    
    The script includes timeout protection to prevent hung uninstall processes from blocking
    automation workflows. If an uninstall exceeds the specified timeout, the process is
    terminated forcefully.

.PARAMETER Name
    Exact name of the application(s) to uninstall, separated by commas.
    Must match the DisplayName in the registry exactly.
    Example: 'VLC media player, Everything 1.4.1.1024 (x64)'

.PARAMETER Arguments
    Additional custom arguments to pass to the uninstaller, separated by commas.
    These arguments are appended to the UninstallString.
    Example: '/SILENT, /NOREBOOT'

.PARAMETER Reboot
    Schedules a system reboot 60 seconds after successful uninstallation.
    Default: False

.PARAMETER Timeout
    Maximum time in minutes to wait for each uninstall process to complete.
    If exceeded, the process is forcefully terminated.
    Valid range: 1-60 minutes
    Default: 10 minutes

.EXAMPLE
    .\Software-UninstallApplication.ps1 -Name "VLC media player"
    
    Uninstalls VLC media player using its registry UninstallString.
    
    Output:
    [2026-02-10 21:00:00] [INFO] Beginning uninstall of VLC media player using MsiExec.exe /X{GUID} /qn /norestart...
    [2026-02-10 21:00:30] [INFO] Exit code for VLC media player: 0
    [2026-02-10 21:01:00] [SUCCESS] Successfully uninstalled your requested apps!

.EXAMPLE
    .\Software-UninstallApplication.ps1 -Name "7-Zip 23.01 (x64)" -Timeout 5
    
    Uninstalls 7-Zip with a 5-minute timeout.

.EXAMPLE
    .\Software-UninstallApplication.ps1 -Name "Adobe Reader" -Arguments "/SILENT" -Reboot
    
    Uninstalls Adobe Reader with custom silent argument and schedules reboot after completion.

.NOTES
    File Name      : Software-UninstallApplication.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards implementation with proper error handling
    - 2.0: Added timeout and multi-app support
    - 1.0: Initial release
    
    Execution Context: SYSTEM or Administrator required
    Execution Frequency: As needed (software removal)
    Typical Duration: 1-10 minutes (depends on application size)
    Timeout Setting: User-configurable (1-60 minutes, default 10)
    
    User Interaction: NONE (runs silently)
    Restart Behavior: Optional via -Reboot parameter
    
    Fields Updated: None
    
    Dependencies:
        - Administrator privileges (mandatory)
        - Target application must be installed
        - UninstallString must exist in registry
    
    Environment Variables (Optional):
        - nameOfAppToUninstall: Alternative to -Name parameter
        - arguments: Alternative to -Arguments parameter
        - timeoutInMinutes: Alternative to -Timeout parameter
        - reboot: Alternative to -Reboot switch

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [String]$Name,
    
    [Parameter(Mandatory=$false)]
    [String]$Arguments,
    
    [Parameter(Mandatory=$false)]
    [switch]$Reboot = [System.Convert]::ToBoolean($env:reboot),
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 10
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Software-UninstallApplication"
    $StartTime = Get-Date
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0
    
    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'SUCCESS')]
            [string]$Level = 'INFO'
        )
        
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        Write-Output $LogMessage
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++; $script:ExitCode = 1 }
        }
    }
    
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    
    function Get-UserHives {
        param(
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
    
    function Find-UninstallKey {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $True)]
            [String]$DisplayName,
            
            [Parameter()]
            [Switch]$UninstallString
        )
        
        process {
            $UninstallList = New-Object System.Collections.Generic.List[Object]
            
            $Result = Get-ChildItem "Registry::HKEY_USERS\*\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -match "$([regex]::Escape($DisplayName))" }
            if ($Result) { $UninstallList.Add($Result) }
            
            $Result = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -match "$([regex]::Escape($DisplayName))" }
            if ($Result) { $UninstallList.Add($Result) }
            
            $Result = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -match "$([regex]::Escape($DisplayName))" }
            if ($Result) { $UninstallList.Add($Result) }
            
            $Result = Get-ChildItem "Registry::HKEY_USERS\*\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -match "$([regex]::Escape($DisplayName))" }
            if ($Result) { $UninstallList.Add($Result) }
            
            if ($UninstallString) {
                $UninstallList | ForEach-Object { $_ | Select-Object DisplayName, UninstallString -ErrorAction SilentlyContinue }
            }
            else {
                $UninstallList
            }
        }
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        # Override with environment variables
        if ($env:nameOfAppToUninstall -and $env:nameOfAppToUninstall -notlike "null") { 
            $Name = $env:nameOfAppToUninstall 
            Write-Log "Using application name from environment: $Name" -Level INFO
        }
        if ($env:arguments -and $env:arguments -notlike "null") { 
            $Arguments = $env:arguments 
            Write-Log "Using custom arguments from environment: $Arguments" -Level INFO
        }
        if ($env:timeoutInMinutes -and $env:timeoutInMinutes -notlike "null") { 
            $Timeout = $env:timeoutInMinutes 
            Write-Log "Using timeout from environment: $Timeout minutes" -Level INFO
        }
        
        # Validate parameters
        if (-not $Name) {
            Write-Log "No application name provided" -Level ERROR
            throw "Application name is required"
        }
        
        if (-not $Timeout) {
            Write-Log "No timeout given" -Level ERROR
            throw "Timeout must be between 1 and 60 minutes"
        }
        
        if ($Timeout -lt 1 -or $Timeout -gt 60) {
            Write-Log "Invalid timeout of $Timeout minutes" -Level ERROR
            throw "Timeout must be between 1 and 60 minutes"
        }
        
        # Parse application names
        $AppNames = New-Object System.Collections.Generic.List[String]
        $Name -split ',' | ForEach-Object {
            $AppNames.Add($_.Trim())
        }
        
        Write-Log "Applications to uninstall: $($AppNames -join ', ')" -Level INFO
        Write-Log "Timeout: $Timeout minutes" -Level INFO
        
        if (-not (Test-IsElevated)) {
            Write-Log "Administrator privileges required" -Level ERROR
            throw "Access denied"
        }
        
        Write-Log "Loading user registry hives..." -Level INFO
        $UserProfiles = Get-UserHives -Type "All"
        $ProfileWasLoaded = New-Object System.Collections.Generic.List[string]
        
        Foreach ($UserProfile in $UserProfiles) {
            If ((Test-Path Registry::HKEY_USERS\$($UserProfile.SID)) -eq $false) {
                Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe LOAD HKU\$($UserProfile.SID) `"$($UserProfile.UserHive)`"" -Wait -WindowStyle Hidden
                $ProfileWasLoaded.Add("$($UserProfile.SID)")
            }
        }
        
        Write-Log "Searching for applications in registry..." -Level INFO
        $SimilarAppsToName = $AppNames | ForEach-Object { Find-UninstallKey -DisplayName $_ -UninstallString }
        
        if (-not $SimilarAppsToName) {
            Write-Log "Requested applications not found in registry" -Level ERROR
            throw "Applications not found"
        }
        
        # Unload hives
        ForEach ($UserHive in $ProfileWasLoaded) {
            [gc]::Collect()
            Start-Sleep -Milliseconds 500
            Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe UNLOAD HKU\$($UserHive)" -Wait -WindowStyle Hidden | Out-Null
        }
        
        # Find exact matches
        $AppsToUninstall = New-Object System.Collections.Generic.List[Object]
        $ExactMatch = $false
        $UninstallStringFound = $false
        
        $SimilarAppsToName | ForEach-Object {
            foreach ($AppName in $AppNames) {
                if ($AppName -eq $_.DisplayName) {
                    $ExactMatch = $True
                    if ($_.UninstallString) {
                        $UninstallStringFound = $True
                        $AppsToUninstall.Add($_)
                        Write-Log "Found: $($_.DisplayName)" -Level INFO
                    }
                }
            }
        }
        
        if (-not $ExactMatch) {
            Write-Log "Requested applications not found. Similar apps:" -Level ERROR
            $SimilarAppsToName | ForEach-Object { Write-Log "  - $($_.DisplayName)" -Level INFO }
            throw "Exact match not found"
        }
        
        if (-not $UninstallStringFound) {
            Write-Log "No uninstall string found for requested apps" -Level ERROR
            throw "UninstallString missing"
        }
        
        # Check for missing apps
        $AppNames | ForEach-Object {
            if ($AppsToUninstall.DisplayName -notcontains $_) {
                Write-Log "UninstallString missing or app not found: $_" -Level ERROR
            }
        }
        
        $TimeoutInSeconds = $Timeout * 60
        $UninstallStartTime = Get-Date
        
        # Process each app
        $AppsToUninstall | ForEach-Object {
            $AdditionalArguments = New-Object System.Collections.Generic.List[String]
            $Executable = $null
            
            if($_.UninstallString -match "msiexec"){
                $Executable = "msiexec.exe"
            }
            
            if($_.UninstallString -notmatch "msiexec" -and $_.UninstallString -match '[a-zA-Z]:\\(?:[^\\\/:*?"<>|\r\n]+\\)*[^\\\/:*?"<>|\r\n]*'){
                $Executable = $Matches[0]
            }
            
            if(-not $Executable){
                Write-Log "Unable to find uninstall executable for $($_.DisplayName)" -Level ERROR
                return
            }
            
            $PossibleArguments = $_.UninstallString -split ' ' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^/"}
            
            foreach ($PossibleArgument in $PossibleArguments) {
                if (-not ($PossibleArgument -match "^/I{") -and $PossibleArgument) {
                    $AdditionalArguments.Add($PossibleArgument)
                }
                if ($PossibleArgument -match "^/I{") {
                    $AdditionalArguments.Add("$($PossibleArgument -replace '/I', '/X')")
                }
            }
            
            if ($Arguments) {
                $Arguments.Split(',') | ForEach-Object {
                    $AdditionalArguments.Add($_.Trim())
                }
            }
            
            if($Executable -match "Msiexec"){
                if($AdditionalArguments -notcontains "/qn"){
                    $AdditionalArguments.Add("/qn")
                }
                if($AdditionalArguments -notcontains "/norestart"){
                    $AdditionalArguments.Add("/norestart")
                }
            }elseif($Executable -match "\.exe"){
                if($AdditionalArguments -notcontains "/S"){
                    $AdditionalArguments.Add("/S")
                }
                if($AdditionalArguments -notcontains "/norestart"){
                    $AdditionalArguments.Add("/norestart")
                }
            }
            
            Write-Log "Beginning uninstall of $($_.DisplayName) using $Executable $($AdditionalArguments -join ' ')..." -Level INFO
            
            try{
                if ($AdditionalArguments) {
                    $Uninstall = Start-Process $Executable -ArgumentList $AdditionalArguments -NoNewWindow -PassThru
                }
                else {
                    $Uninstall = Start-Process $Executable -NoNewWindow -PassThru
                }
            }catch{
                Write-Log "Failed to start uninstall process: $($_.Exception.Message)" -Level ERROR
                return
            }
            
            $TimeElapsed = (Get-Date) - $UninstallStartTime
            $RemainingTime = $TimeoutInSeconds - $TimeElapsed.TotalSeconds
            
            try {
                $Uninstall | Wait-Process -Timeout $RemainingTime -ErrorAction Stop
            }
            catch {
                Write-Log "Uninstall process for $($_.DisplayName) exceeded timeout of $Timeout minutes" -Level WARN
                Write-Log "Terminating process..." -Level WARN
                $Uninstall | Stop-Process -Force
            }
            
            Write-Log "Exit code for $($_.DisplayName): $($Uninstall.ExitCode)" -Level INFO
            if ($Uninstall.ExitCode -ne 0) {
                Write-Log "Non-zero exit code detected" -Level ERROR
            }
        }
        
        Write-Log "Waiting 30 seconds before verification..." -Level INFO
        Start-Sleep -Seconds 30
        
        # Reload hives for verification
        $UserProfiles = Get-UserHives -Type "All"
        $ProfileWasLoaded = New-Object System.Collections.Generic.List[string]
        
        Foreach ($UserProfile in $UserProfiles) {
            If ((Test-Path Registry::HKEY_USERS\$($UserProfile.SID)) -eq $false) {
                Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe LOAD HKU\$($UserProfile.SID) `"$($UserProfile.UserHive)`"" -Wait -WindowStyle Hidden
                $ProfileWasLoaded.Add("$($UserProfile.SID)")
            }
        }
        
        Write-Log "Verifying uninstallation..." -Level INFO
        $SimilarAppsToName = $AppNames | ForEach-Object { Find-UninstallKey -DisplayName $_ }
        $UninstallFailure = $false
        
        $SimilarAppsToName | ForEach-Object {
            foreach ($AppName in $AppNames) {
                if ($_.DisplayName -eq $AppName) {
                    Write-Log "Failed to uninstall $($_.DisplayName)" -Level ERROR
                    $UninstallFailure = $True
                }
            }
        }
        
        # Unload hives
        ForEach ($UserHive in $ProfileWasLoaded) {
            [gc]::Collect()
            Start-Sleep -Milliseconds 500
            Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe UNLOAD HKU\$($UserHive)" -Wait -WindowStyle Hidden | Out-Null
        }
        
        if (-not $UninstallFailure) {
            Write-Log "Successfully uninstalled all requested applications" -Level SUCCESS
        }
        
        if ($Reboot -and -not $UninstallFailure) {
            Write-Log "Reboot requested. Scheduling restart for 60 seconds from now..." -Level WARN
            Start-Process shutdown.exe -ArgumentList "/r /t 60" -Wait -NoNewWindow
        }
        
    }
    catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Summary:" -Level INFO
        Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "  Errors: $script:ErrorCount" -Level INFO
        Write-Log "  Warnings: $script:WarningCount" -Level INFO
        Write-Log "  Exit Code: $script:ExitCode" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
