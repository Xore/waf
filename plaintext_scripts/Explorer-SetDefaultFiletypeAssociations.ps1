#Requires -Version 5.1

<#
.SYNOPSIS
    Set the default application for file extensions for all users.
.DESCRIPTION
    Set the default application a given file extension should be opened with for all users.
    This script can also enable/disable the User Choice Protection Driver.
.EXAMPLE
    .\Explorer-SetDefaultFiletypeAssociations.ps1 -Action "Set File Association" -ApplicationName "Notepad" -Extensions ".txt, .csv" -ProgId "AppXkv2jqn1pq8ajm0p5dhgqde7aafykkrrn"

    Setting association of '.csv' to 'AppXkv2jqn1pq8ajm0p5dhgqde7aafykkrrn' for Administrator.
    Association set.

PARAMETER: -Action "Set File Association"
    Specify whether you would like to set the default application for a given extension, or disable or enable the block on the '.html', '.htm', or '.pdf' extensions.
    Valid actions are 'Set File Association', 'Disable User Choice Protection Driver' or 'Enable User Choice Protection Driver'.

PARAMETER: -ApplicationName "ReplaceMeWithTheNameOfAnApplication"
    Specify the application you are setting as the default for your given file extension(s).

PARAMETER: -Extensions ".ai, .csv, .txt"
    Provide a comma-separated list of file extensions to set the default association for.

PARAMETER: -ProgId "ChromeHTML"
    Enter the programmatic identifier for your given application.

LICENSE:
    Modified version from: https://github.com/DanysysTeam/PS-SFTA/
    This script incorporates the Get-HexDateTime and Get-Hash functions from Danysys.
    MIT License - Copyright (c) 2022 Danysys. <danysys.com>

.NOTES
    File Name      : Explorer-SetDefaultFiletypeAssociations.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3.0.0 standards (script-scoped exit code)
    - 1.0: Initial release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Action = "Set File Association",
    [Parameter()]
    [String]$ApplicationName,
    [Parameter()]
    [String]$Extensions,
    [Parameter()]
    [String]$ProgID,
    [Parameter()]
    [Switch]$RestartExplorer,
    [Parameter()]
    [Switch]$ForceRestartComputer
)

begin {
    $ErrorActionPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Output $logMessage }
        }
    }

    if ($env:restartExplorer -eq "true") { $RestartExplorer = $true }
    if ($env:forceRestartComputer -eq "true") { $ForceRestartComputer = $true }
    if ($env:action -and $env:action -notlike "null") { $Action = $env:action }
    if ($env:applicationName -and $env:applicationName -notlike "null") { $ApplicationName = $env:applicationName }
    if ($env:fileExtensions -and $env:fileExtensions -notlike "null") { $Extensions = $env:fileExtensions }
    if ($env:programId -and $env:programId -notlike "null") { $ProgID = $env:programId }

    if ($Action) { $Action = $Action.Trim() }

    if (!$Action) {
        Write-Log "No action was specified. Please specify either 'Set File Association', 'Disable User Choice Protection Driver' or 'Enable User Choice Protection Driver'." -Level ERROR
        exit 1
    }

    $ValidActions = "Set File Association", "Disable User Choice Protection Driver", "Enable User Choice Protection Driver"
    if ($ValidActions -notcontains $Action) {
        Write-Log "An invalid action of '$Action' was given. Please give a valid action such as 'Set File Association', 'Disable User Choice Protection Driver' or 'Enable User Choice Protection Driver'." -Level ERROR
        exit 1
    }

    if ($ApplicationName) { $ApplicationName = $ApplicationName.Trim() }

    if(($Action -eq "Disable User Choice Protection Driver" -or $Action -eq "Enable User Choice Protection Driver") -and $ApplicationName){
        Write-Log "Cannot add an association and '$Action' at the same time." -Level ERROR
        exit 1
    }

    if ($ApplicationName -match '[\\/:*?"<>\|]') {
        Write-Log "The application name '$ApplicationName' contains invalid characters: '\/:*?`"<>|'" -Level ERROR
        exit 1
    }

    if (!$ApplicationName -and $Action -ne "Disable User Choice Protection Driver" -and $Action -ne "Enable User Choice Protection Driver") {
        Write-Log "An application name was not given. The application name as shown in Ninja is required." -Level ERROR
        exit 1
    }

    $ExtensionList = New-Object System.Collections.Generic.List[string]
    $ProtectedExtensions = ".html", ".htm", ".pdf"

    $UserProtectionService = Get-Service -Name "UCPD" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
    $UserProtectionTask = Get-ScheduledTask -TaskName "UCPD velocity" -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -ErrorAction SilentlyContinue | Where-Object { $_.State -ne "Disabled" }

    if(($Action -eq "Disable User Choice Protection Driver" -or $Action -eq "Enable User Choice Protection Driver") -and $Extensions){
        Write-Log "Cannot add an association and '$Action' at the same time." -Level ERROR
        exit 1
    }

    if ($Extensions -and $Action -ne "Disable User Choice Protection Driver" -and $Action -ne "Enable User Choice Protection Driver") {
        $Extensions -split ',' | ForEach-Object {
            $ExtensionToAdd = $_.Trim()
            if (!$ExtensionToAdd) { return }

            if ($ExtensionToAdd -notmatch '^\.') {
                $ExtensionToAdd = ".$ExtensionToAdd"
                Write-Log "Added a '.' to the extension. New extension '$ExtensionToAdd'." -Level WARNING
            }

            if ($ExtensionToAdd -match '[\\/:*?"<>\|]') {
                Write-Log "The extension '$ExtensionToAdd' contains invalid characters: '\/:*?`"<>|'" -Level ERROR
                $script:ExitCode = 1
                return
            }

            if (!(Test-Path -Path "Registry::HKEY_CLASSES_ROOT\$ExtensionToAdd" -ErrorAction SilentlyContinue)) {
                Write-Log "'$ExtensionToAdd' is invalid; it was not found in HKEY_CLASSES_ROOT." -Level ERROR
                $script:ExitCode = 1
                return
            }

            if ($ProtectedExtensions -contains $ExtensionToAdd -and ($UserProtectionService -or $UserProtectionTask)) {
                Write-Log "'$ExtensionToAdd' may be protected by the 'User Choice Protection Driver'. You may need to select the 'Disable User Choice Protection Driver' to successfully complete this change." -Level WARNING
            }

            $ExtensionList.Add($ExtensionToAdd)
        }
    }

    if ((!$Extensions -or $ExtensionList.Count -eq 0) -and $Action -ne "Disable User Choice Protection Driver" -and $Action -ne "Enable User Choice Protection Driver") {
        Write-Log "You must provide a valid extension to set a default program association." -Level ERROR
        exit 1
    }

    if ($ProgID) { $ProgID = $ProgID.Trim() }

    if(($Action -eq "Disable User Choice Protection Driver" -or $Action -eq "Enable User Choice Protection Driver") -and $ProgID){
        Write-Log "Cannot add an association and '$Action' at the same time." -Level ERROR
        exit 1
    }

    if (!$ProgId -and $Action -ne "Disable User Choice Protection Driver" -and $Action -ne "Enable User Choice Protection Driver") {
        Write-Log "Missing the program id for the program you'd like to associate with your given file type." -Level ERROR
        Write-Log "https://learn.microsoft.com/en-us/windows/win32/shell/fa-progids"
        exit 1
    }

    if ($ProgID -Match '^\.') {
        Write-Log "Program ID '$ProgID' starts with an invalid character '.'. Please specify a different program id." -Level ERROR
        Write-Log "https://learn.microsoft.com/en-us/windows/win32/shell/fa-progids"
        exit 1
    }

    function Get-HexDateTime {
        [OutputType([string])]
        $now = [DateTime]::Now
        $dateTime = [DateTime]::New($now.Year, $now.Month, $now.Day, $now.Hour, $now.Minute, 0)
        $fileTime = $dateTime.ToFileTime()
        $hi = ($fileTime -shr 32)
        $low = ($fileTime -band 0xFFFFFFFFL)
        ($hi.ToString("X8") + $low.ToString("X8")).ToLower()
    }

    function Get-Hash {
        [CmdletBinding()]
        param (
            [Parameter( Position = 0, Mandatory = $True )]
            [string]$BaseInfo
        )
    
        function local:Get-ShiftRight {
            [CmdletBinding()]
            param (
                [Parameter( Position = 0, Mandatory = $true)]
                [long] $iValue, 
                [Parameter( Position = 1, Mandatory = $true)]
                [int] $iCount 
            )
            if ($iValue -band 0x80000000) {
                Write-Output (( $iValue -shr $iCount) -bxor 0xFFFF0000)
            }
            else {
                Write-Output ($iValue -shr $iCount)
            }
        }
    
        function local:Get-Long {
            [CmdletBinding()]
            param (
                [Parameter( Position = 0, Mandatory = $true)]
                [byte[]] $Bytes,
                [Parameter( Position = 1)]
                [int] $Index = 0
            )
            Write-Output ([BitConverter]::ToInt32($Bytes, $Index))
        }
    
        function local:Convert-Int32 {
            param (
                [Parameter( Position = 0, Mandatory = $true)]
                [long] $Value
            )
            [byte[]] $bytes = [BitConverter]::GetBytes($Value)
            return [BitConverter]::ToInt32( $bytes, 0) 
        }
    
        [Byte[]] $bytesBaseInfo = [System.Text.Encoding]::Unicode.GetBytes($baseInfo) 
        $bytesBaseInfo += 0x00, 0x00  
        
        $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
        [Byte[]] $bytesMD5 = $MD5.ComputeHash($bytesBaseInfo)
        
        $lengthBase = ($baseInfo.Length * 2) + 2 
        $length = (($lengthBase -band 4) -le 1) + (Get-ShiftRight $lengthBase 2) - 1
        $base64Hash = ""
    
        if ($length -gt 1) {
            $map = @{PDATA = 0; CACHE = 0; COUNTER = 0 ; INDEX = 0; MD51 = 0; MD52 = 0; OUTHASH1 = 0; OUTHASH2 = 0;
                R0 = 0; R1 = @(0, 0); R2 = @(0, 0); R3 = 0; R4 = @(0, 0); R5 = @(0, 0); R6 = @(0, 0); R7 = @(0, 0)
            }
        
            $map.CACHE = 0
            $map.OUTHASH1 = 0
            $map.PDATA = 0
            $map.MD51 = (((Get-Long $bytesMD5) -bor 1) + 0x69FB0000L)
            $map.MD52 = ((Get-Long $bytesMD5 4) -bor 1) + 0x13DB0000L
            $map.INDEX = Get-ShiftRight ($length - 2) 1
            $map.COUNTER = $map.INDEX + 1
        
            while ($map.COUNTER) {
                $map.R0 = Convert-Int32 ((Get-Long $bytesBaseInfo $map.PDATA) + [long]$map.OUTHASH1)
                $map.R1[0] = Convert-Int32 (Get-Long $bytesBaseInfo ($map.PDATA + 4))
                $map.PDATA = $map.PDATA + 8
                $map.R2[0] = Convert-Int32 (($map.R0 * ([long]$map.MD51)) - (0x10FA9605L * ((Get-ShiftRight $map.R0 16))))
                $map.R2[1] = Convert-Int32 ((0x79F8A395L * ([long]$map.R2[0])) + (0x689B6B9FL * (Get-ShiftRight $map.R2[0] 16)))
                $map.R3 = Convert-Int32 ((0xEA970001L * $map.R2[1]) - (0x3C101569L * (Get-ShiftRight $map.R2[1] 16) ))
                $map.R4[0] = Convert-Int32 ($map.R3 + $map.R1[0])
                $map.R5[0] = Convert-Int32 ($map.CACHE + $map.R3)
                $map.R6[0] = Convert-Int32 (($map.R4[0] * [long]$map.MD52) - (0x3CE8EC25L * (Get-ShiftRight $map.R4[0] 16)))
                $map.R6[1] = Convert-Int32 ((0x59C3AF2DL * $map.R6[0]) - (0x2232E0F1L * (Get-ShiftRight $map.R6[0] 16)))
                $map.OUTHASH1 = Convert-Int32 ((0x1EC90001L * $map.R6[1]) + (0x35BD1EC9L * (Get-ShiftRight $map.R6[1] 16)))
                $map.OUTHASH2 = Convert-Int32 ([long]$map.R5[0] + [long]$map.OUTHASH1)
                $map.CACHE = ([long]$map.OUTHASH2)
                $map.COUNTER = $map.COUNTER - 1
            }
    
            [Byte[]] $outHash = @(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
            [byte[]] $buffer = [BitConverter]::GetBytes($map.OUTHASH1)
            $buffer.CopyTo($outHash, 0)
            $buffer = [BitConverter]::GetBytes($map.OUTHASH2)
            $buffer.CopyTo($outHash, 4)
        
            $map = @{PDATA = 0; CACHE = 0; COUNTER = 0 ; INDEX = 0; MD51 = 0; MD52 = 0; OUTHASH1 = 0; OUTHASH2 = 0;
                R0 = 0; R1 = @(0, 0); R2 = @(0, 0); R3 = 0; R4 = @(0, 0); R5 = @(0, 0); R6 = @(0, 0); R7 = @(0, 0)
            }
        
            $map.CACHE = 0
            $map.OUTHASH1 = 0
            $map.PDATA = 0
            $map.MD51 = ((Get-Long $bytesMD5) -bor 1)
            $map.MD52 = ((Get-Long $bytesMD5 4) -bor 1)
            $map.INDEX = Get-ShiftRight ($length - 2) 1
            $map.COUNTER = $map.INDEX + 1
    
            while ($map.COUNTER) {
                $map.R0 = Convert-Int32 ((Get-Long $bytesBaseInfo $map.PDATA) + ([long]$map.OUTHASH1))
                $map.PDATA = $map.PDATA + 8
                $map.R1[0] = Convert-Int32 ($map.R0 * [long]$map.MD51)
                $map.R1[1] = Convert-Int32 ((0xB1110000L * $map.R1[0]) - (0x30674EEFL * (Get-ShiftRight $map.R1[0] 16)))
                $map.R2[0] = Convert-Int32 ((0x5B9F0000L * $map.R1[1]) - (0x78F7A461L * (Get-ShiftRight $map.R1[1] 16)))
                $map.R2[1] = Convert-Int32 ((0x12CEB96DL * (Get-ShiftRight $map.R2[0] 16)) - (0x46930000L * $map.R2[0]))
                $map.R3 = Convert-Int32 ((0x1D830000L * $map.R2[1]) + (0x257E1D83L * (Get-ShiftRight $map.R2[1] 16)))
                $map.R4[0] = Convert-Int32 ([long]$map.MD52 * ([long]$map.R3 + (Get-Long $bytesBaseInfo ($map.PDATA - 4))))
                $map.R4[1] = Convert-Int32 ((0x16F50000L * $map.R4[0]) - (0x5D8BE90BL * (Get-ShiftRight $map.R4[0] 16)))
                $map.R5[0] = Convert-Int32 ((0x96FF0000L * $map.R4[1]) - (0x2C7C6901L * (Get-ShiftRight $map.R4[1] 16)))
                $map.R5[1] = Convert-Int32 ((0x2B890000L * $map.R5[0]) + (0x7C932B89L * (Get-ShiftRight $map.R5[0] 16)))
                $map.OUTHASH1 = Convert-Int32 ((0x9F690000L * $map.R5[1]) - (0x405B6097L * (Get-ShiftRight ($map.R5[1]) 16)))
                $map.OUTHASH2 = Convert-Int32 ([long]$map.OUTHASH1 + $map.CACHE + $map.R3) 
                $map.CACHE = ([long]$map.OUTHASH2)
                $map.COUNTER = $map.COUNTER - 1
            }
        
            $buffer = [BitConverter]::GetBytes($map.OUTHASH1)
            $buffer.CopyTo($outHash, 8)
            $buffer = [BitConverter]::GetBytes($map.OUTHASH2)
            $buffer.CopyTo($outHash, 12)
        
            [Byte[]] $outHashBase = @(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
            $hashValue1 = ((Get-Long $outHash 8) -bxor (Get-Long $outHash))
            $hashValue2 = ((Get-Long $outHash 12) -bxor (Get-Long $outHash 4))
        
            $buffer = [BitConverter]::GetBytes($hashValue1)
            $buffer.CopyTo($outHashBase, 0)
            $buffer = [BitConverter]::GetBytes($hashValue2)
            $buffer.CopyTo($outHashBase, 4)
            $base64Hash = [Convert]::ToBase64String($outHashBase) 
        }
        $base64Hash
    }

    function Find-InstallKey {
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipeline = $True)]
            [String]$DisplayName,
            [Parameter()]
            [Switch]$UninstallString,
            [Parameter()]
            [String]$UserBaseKey
        )
        process {
            $InstallList = New-Object System.Collections.Generic.List[Object]

            if (!$UserBaseKey) {
                $Result = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
                if ($Result) { $InstallList.Add($Result) }

                $Result = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
                if ($Result) { $InstallList.Add($Result) }
            }
            else {
                $Result = Get-ChildItem -Path "$UserBaseKey\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
                if ($Result) { $InstallList.Add($Result) }
    
                $Result = Get-ChildItem -Path "$UserBaseKey\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
                if ($Result) { $InstallList.Add($Result) }
            }
    
            if ($UninstallString) {
                $InstallList | Select-Object -ExpandProperty UninstallString -ErrorAction SilentlyContinue
            }
            else {
                $InstallList
            }
        }
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
            Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" -ErrorAction SilentlyContinue |
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
        if (-not (Test-Path -Path $Path)) {
            try {
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Unable to create the registry path $Path for $Name: $($_.Exception.Message)" -Level ERROR
                exit 1
            }
        }
        if (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Unable to set registry key for $Name at $Path: $($_.Exception.Message)" -Level ERROR
                exit 1
            }
            Write-Log "$Path\$Name changed from $CurrentValue to $((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name)"
        }
        else {
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Unable to set registry key for $Name at $Path: $($_.Exception.Message)" -Level ERROR
                exit 1
            }
            Write-Log "Set $Path\$Name to $((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name)"
        }
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    $script:ExitCode = 0
}

process {
    if (!(Test-IsElevated)) {
        Write-Log "Access Denied. Please run with administrator privileges." -Level ERROR
        exit 1
    }

    if ($Action -eq "Disable User Choice Protection Driver") {
        Write-Log "Disabling the User Choice Protection Driver service."

        if (Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UCPD" -ErrorAction SilentlyContinue) {
            Set-RegKey -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UCPD" -Name "Start" -Value 4
        }
        else {
            Write-Log "The User Choice Protection Driver service does not exist." -Level ERROR
            $script:ExitCode = 1
        }

        Write-Log "Disabling the User Choice Protection scheduled task."
        $ScheduledTask = Get-ScheduledTask -TaskName "UCPD velocity" -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -ErrorAction SilentlyContinue
        if ($ScheduledTask) {
            try {
                $ScheduledTask | Disable-ScheduledTask -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Failed to disable User Choice Protection scheduled task: $($_.Exception.Message)" -Level ERROR
                exit 1
            }
        }
        else {
            Write-Log "The 'UCPD velocity' scheduled task was not found." -Level ERROR
            $script:ExitCode = 1
        }

        if ($RestartExplorer -and $script:ExitCode -eq 0) {
            Write-Log "Restarting Explorer.exe as requested."
            Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 1
            if (!(Test-IsSystem) -and !(Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
                Start-Process explorer.exe
            }
        }

        if ($ForceRestartComputer -and $script:ExitCode -eq 0) {
            Write-Log "Scheduling forced restart for $((Get-Date).AddSeconds(60))."
            Start-Process shutdown.exe -ArgumentList "/r /t 60" -Wait -NoNewWindow
        }
        elseif ($script:ExitCode -eq 0) {
            Write-Log "In order for the User Protection Driver updates to take immediate effect, you may need to restart the computer." -Level WARNING
        }

        exit $script:ExitCode
    }

    if ($Action -eq "Enable User Choice Protection Driver") {
        Write-Log "Enabling the User Choice Protection Driver service."

        if (Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UCPD" -ErrorAction SilentlyContinue) {
            Set-RegKey -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UCPD" -Name "Start" -Value 1
        }
        else {
            Write-Log "The User Choice Protection Driver service does not exist." -Level ERROR
            $script:ExitCode = 1
        }

        Write-Log "Enabling the User Choice Protection scheduled task."
        $ScheduledTask = Get-ScheduledTask -TaskName "UCPD velocity" -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -ErrorAction SilentlyContinue
        if ($ScheduledTask) {
            try {
                $ScheduledTask | Enable-ScheduledTask -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Failed to enable User Choice Protection scheduled task: $($_.Exception.Message)" -Level ERROR
                exit 1
            }
        }
        else {
            Write-Log "The 'UCPD velocity' scheduled task was not found." -Level ERROR
            $script:ExitCode = 1
        }

        if ($RestartExplorer -and $script:ExitCode -eq 0) {
            Write-Log "Restarting Explorer.exe as requested."
            Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 1
            if (!(Test-IsSystem) -and !(Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
                Start-Process explorer.exe
            }
        }

        if ($ForceRestartComputer -and $script:ExitCode -eq 0) {
            Write-Log "Scheduling forced restart for $((Get-Date).AddSeconds(60))."
            Start-Process shutdown.exe -ArgumentList "/r /t 60" -Wait -NoNewWindow
        }
        elseif ($script:ExitCode -eq 0) {
            Write-Log "In order for the User Protection Driver updates to take immediate effect, you may need to restart the computer." -Level WARNING
        }

        exit $script:ExitCode
    }

    Write-Log "Checking that '$ApplicationName' is installed."
    $ProgramIsInstalled = Find-InstallKey -DisplayName $ApplicationName

    $UserProfiles = Get-UserHives -Type "All"
    $ProfileWasLoaded = New-Object System.Collections.Generic.List[object]

    if (Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\Software\Classes\$ProgID" -ErrorAction SilentlyContinue) {
        $ProgIDisValid = $True
    }

    ForEach ($UserProfile in $UserProfiles) {
        If (!(Test-Path -Path Registry::HKEY_USERS\$($UserProfile.SID) -ErrorAction SilentlyContinue)) {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe LOAD HKU\$($UserProfile.SID) `"$($UserProfile.UserHive)`"" -Wait -WindowStyle Hidden
            $ProfileWasLoaded.Add($UserProfile)
        }

        if (Test-Path -Path "Registry::HKEY_USERS\$($UserProfile.SID)\Software\Classes\$ProgID" -ErrorAction SilentlyContinue) {
            $ProgIDisValid = $True
        }

        if (!$ProgramIsInstalled) {
            $ProgramIsInstalled = Find-InstallKey -DisplayName $ApplicationName -UserBaseKey "Registry::HKEY_USERS\$($UserProfile.SID)"
        }
    }

    if (!$ProgIDisValid) {
        Write-Log "Program ID '$ProgID' is invalid and was not found at HKEY_CLASSES_ROOT\$ProgID. Please specify a different program id." -Level ERROR
        Write-Log "https://learn.microsoft.com/en-us/windows/win32/shell/fa-progids"
        exit 1
    }

    if (!$ProgramIsInstalled) {
        $ProgramIsInstalled = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ApplicationName*" }
    }

    if ($ProfileWasLoaded.Count -gt 0 -and !$ProgramIsInstalled) {
        ForEach ($UserProfile in $ProfileWasLoaded) {
            [gc]::Collect()
            Start-Sleep 1
            Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe UNLOAD HKU\$($UserProfile.SID)" -Wait -WindowStyle Hidden | Out-Null
        }
    }

    if (!$ProgramIsInstalled) {
        Write-Log "The application '$ApplicationName' was not found." -Level WARNING
    }
    else {
        Write-Log "Found '$ApplicationName'."
    }

    ForEach ($UserProfile in $UserProfiles) {
        $ExtensionList | ForEach-Object {
            Write-Log "Setting association of '$_' to '$ProgId' for $($UserProfile.Username)."
            
            $userExperience = "User Choice set via Windows User Experience {D18B6DD5-6124-4341-9318-804003BAFA0B}"
            $hexDateTime = Get-HexDateTime
        
            $File = $_
            $ToBeHashed = "$File$($UserProfile.SID)$ProgID$hexDateTime$userExperience".ToLower()
            $Hash = Get-Hash -BaseInfo $ToBeHashed

            Set-RegKey -Path "Registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$File\UserChoice" -Name "Hash" -Value $Hash -PropertyType String
            Set-RegKey -Path "Registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$File\UserChoice" -Name "ProgId" -Value $ProgID -PropertyType String

            Write-Log "Association set."
        }
    }

    if ($ProfileWasLoaded.Count -gt 0) {
        ForEach ($UserProfile in $ProfileWasLoaded) {
            [gc]::Collect()
            Start-Sleep 1
            Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe UNLOAD HKU\$($UserProfile.SID)" -Wait -WindowStyle Hidden | Out-Null
        }
    }

    if ($RestartExplorer -and $script:ExitCode -eq 0) {
        Write-Log "Restarting Explorer.exe as requested."
        Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 1
        if (!(Test-IsSystem) -and !(Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
            Start-Process explorer.exe
        }
    }
    elseif (!$ForceRestartComputer -and $script:ExitCode -eq 0) {
        Write-Log "In order for the thumbnails to update immediately, you may need to restart Explorer." -Level WARNING
    }

    if ($ForceRestartComputer -and $script:ExitCode -eq 0) {
        Write-Log "Scheduling forced restart for $((Get-Date).AddSeconds(60))."
        Start-Process shutdown.exe -ArgumentList "/r /t 60" -Wait -NoNewWindow
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $Duration seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
