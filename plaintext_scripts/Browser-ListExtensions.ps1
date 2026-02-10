#Requires -Version 5.1

<#
.SYNOPSIS
    Reports all installed browser extensions for Chrome, Edge, and Firefox.

.DESCRIPTION
    Scans user profiles for installed browser extensions across Chrome, Edge, and Firefox.
    Enumerates extension details including name, version, profile, and signed-in account.
    Can output results to NinjaRMM custom fields (Multiline or WYSIWYG format).
    
    Features:
    - Multi-browser support (Chrome, Edge, Firefox)
    - Per-user profile scanning
    - Extension metadata extraction
    - HTML table generation for WYSIWYG fields
    - Automatic truncation for character limits
    - Registry hive loading for offline profiles

.PARAMETER MultilineCustomField
    Name of a NinjaRMM multiline custom field to store results.
    Field name must contain only uppercase letters and numbers (A-Z, 0-9).

.PARAMETER WysiwygCustomField
    Name of a NinjaRMM WYSIWYG custom field to store HTML-formatted results.
    Field name must contain only uppercase letters and numbers (A-Z, 0-9).

.EXAMPLE
    Browser-ListExtensions.ps1
    Lists all browser extensions to console output.

.EXAMPLE
    Browser-ListExtensions.ps1 -MultilineCustomField "BROWSEREXTENSIONS"
    Lists extensions and stores plain text results in custom field.

.EXAMPLE
    Browser-ListExtensions.ps1 -WysiwygCustomField "EXTENSIONREPORT"
    Lists extensions and stores HTML table in WYSIWYG custom field.

.NOTES
    File Name      : Browser-ListExtensions.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Requires       : Administrator privileges
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3.0.0 standards (script-scoped exit code, proper cleanup)
    - 1.1: Added extension version, signed-in account detection, improved error handling
    - 1.0: Initial version
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$MultilineCustomField,
    
    [Parameter()]
    [String]$WysiwygCustomField
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Host $logMessage }
        }
    }

    function Test-IsElevated {
        <#
        .SYNOPSIS
            Tests if script is running with administrator privileges.
        #>
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Get-UserHives {
        <#
        .SYNOPSIS
            Gets user profile information from registry.
        #>
        param (
            [Parameter()]
            [ValidateSet('AzureAD', 'DomainAndLocal', 'All')]
            [String]$Type = 'All',
            
            [Parameter()]
            [String[]]$ExcludedUsers,
            
            [Parameter()]
            [switch]$IncludeDefault
        )

        $Patterns = switch ($Type) {
            'AzureAD' { 'S-1-12-1-(\d+-?){4}$' }
            'DomainAndLocal' { 'S-1-5-21-(\d+-?){4}$' }
            'All' { 'S-1-12-1-(\d+-?){4}$', 'S-1-5-21-(\d+-?){4}$' }
        }

        try {
            $UserProfiles = foreach ($Pattern in $Patterns) {
                Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction Stop |
                    Where-Object { $_.PSChildName -match $Pattern } |
                    Select-Object @{Name = 'SID'; Expression = { $_.PSChildName } },
                    @{Name = 'Username'; Expression = { $_.ProfileImagePath | Split-Path -Leaf } },
                    @{Name = 'Domain'; Expression = { if ($_.PSChildName -match 'S-1-12-1-(\d+-?){4}$') { 'AzureAD' } else { $null } } },
                    @{Name = 'UserHive'; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } },
                    @{Name = 'Path'; Expression = { $_.ProfileImagePath } }
            }
        }
        catch {
            throw "Failed to scan registry ProfileList: $_"
        }

        if ($IncludeDefault) {
            $DefaultProfile = [PSCustomObject]@{
                Username = 'Default'
                Domain   = $env:COMPUTERNAME
                SID      = 'DefaultProfile'
                UserHive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
                Path     = 'C:\Users\Default'
            }
            
            if ($ExcludedUsers -notcontains $DefaultProfile.Username) {
                $DefaultProfile
            }
        }

        try {
            $AllAccounts = Get-CimInstance -ClassName 'win32_UserAccount' -ErrorAction Stop
        }
        catch {
            throw "Failed to gather complete profile information: $_"
        }

        $CompleteUserProfiles = $UserProfiles | ForEach-Object {
            $SID = $_.SID
            $Win32Object = $AllAccounts | Where-Object { $_.SID -like $SID }

            if ($Win32Object) {
                $Win32Object | Add-Member -NotePropertyName UserHive -NotePropertyValue $_.UserHive -Force
                $Win32Object | Add-Member -NotePropertyName Path -NotePropertyValue $_.Path -Force
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

        $CompleteUserProfiles | Where-Object { $ExcludedUsers -notcontains $_.Name }
    }

    function Find-InstallKey {
        <#
        .SYNOPSIS
            Finds software installation registry keys by display name.
        #>
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

            $Paths = if ($UserBaseKey) {
                @(
                    "$UserBaseKey\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "$UserBaseKey\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )
            }
            else {
                @(
                    'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
                )
            }

            foreach ($Path in $Paths) {
                $Result = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue |
                    Get-ItemProperty |
                    Where-Object { $_.DisplayName -like "*$DisplayName*" }
                    
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

    function Convert-JSONToHashtable {
        <#
        .SYNOPSIS
            Converts JSON to hashtable using JavaScriptSerializer.
            Supports empty property names which ConvertFrom-Json does not.
        #>
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
            [string]$Json
        )

        begin {
            try {
                Add-Type -AssemblyName System.Web.Extensions -ErrorAction Stop
                $Serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer -ErrorAction Stop
            }
            catch {
                throw "Failed to initialize JSON serializer: $_"
            }
        }

        process {
            try {
                $Object = $Serializer.DeserializeObject($Json)
                Write-Output $Object
            }
            catch {
                throw "Failed to deserialize JSON: $_"
            }
        }
    }

    function Set-CustomField {
        <#
        .SYNOPSIS
            Sets NinjaRMM custom field values.
        #>
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            
            [Parameter()]
            [String]$Type,
            
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value,
            
            [Parameter()]
            [String]$DocumentName,
            
            [Parameter()]
            [Switch]$Piped
        )

        if ($Type -eq 'WYSIWYG') {
            $Value = $Value -replace ' ', '&nbsp;'
        }

        $Characters = $Value | ConvertTo-Json | Measure-Object -Character | Select-Object -ExpandProperty Characters

        if ($Piped -and $Characters -ge 200000) {
            throw "Character limit exceeded: value is greater than or equal to 200,000 characters"
        }

        if (!$Piped -and $Characters -ge 45000) {
            throw "Character limit exceeded: value is greater than or equal to 45,000 characters"
        }

        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams['DocumentName'] = $DocumentName }

        $ValidFields = 'Attachment', 'Checkbox', 'Date', 'Date or Date Time', 'Decimal', 'Dropdown', 'Email', 'Integer', 'IP Address', 'MultiLine', 'MultiSelect', 'Phone', 'Secure', 'Text', 'Time', 'URL', 'WYSIWYG'

        if ($Type -and $ValidFields -notcontains $Type) {
            Write-Warning "$Type is an invalid type. See: https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789"
        }

        $NeedsOptions = 'Dropdown'

        if ($DocumentName) {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
        }
        else {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }

        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }

        switch ($Type) {
            'Checkbox' {
                $NinjaValue = [System.Convert]::ToBoolean($Value)
            }
            'Date or Date Time' {
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date '1970-01-01 00:00:00') $Date
                $NinjaValue = $TimeSpan.TotalSeconds
            }
            'Dropdown' {
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header 'GUID', 'Name'
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID

                if (!$Selection) {
                    throw "Value is not present in dropdown options"
                }

                $NinjaValue = $Selection
            }
            default {
                $NinjaValue = $Value
            }
        }

        if ($DocumentName) {
            $CustomField = Ninja-Property-Docs-Set -AttributeName $Name -AttributeValue $NinjaValue @DocumentationParams 2>&1
        }
        else {
            try {
                if ($Piped) {
                    $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
                }
                else {
                    $CustomField = Ninja-Property-Set -Name $Name -Value $NinjaValue 2>&1
                }
            }
            catch {
                throw "Failed to set custom field: $_"
            }
        }

        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    function Get-ChromeExtensions {
        <#
        .SYNOPSIS
            Extracts Chrome extensions from user profiles.
        #>
        param(
            [Parameter(Mandatory)]
            $UserProfiles
        )

        $Extensions = New-Object System.Collections.Generic.List[object]

        foreach ($Profile in $UserProfiles) {
            $user = $Profile.Name
            $userPath = $Profile.Path

            $ChromeDataPath = "$userPath\AppData\Local\Google\Chrome\User Data"

            try {
                if (-not (Test-Path -Path $ChromeDataPath -ErrorAction Stop)) {
                    Write-Log "Chrome App Data path does not exist for $user" -Level WARNING
                    continue
                }
            }
            catch {
                Write-Log "Chrome App Data could not be accessed for $user" -Level WARNING
                continue
            }

            $AllProfiles = $null
            if (Test-Path -Path "$ChromeDataPath\Local State" -ErrorAction SilentlyContinue) {
                try {
                    $AllProfiles = Get-Content -Path "$ChromeDataPath\Local State" -Encoding UTF8 -Raw -ErrorAction Stop |
                        Convert-JSONToHashtable -ErrorAction Stop
                }
                catch {
                    Write-Log "Error parsing Chrome Local State file for $user" -Level WARNING
                    $AllProfiles = $null
                }
            }

            $PreferenceFiles = Get-ChildItem "$ChromeDataPath\*\*Preferences" -Exclude 'System Profile' -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName

            foreach ($PreferenceFile in $PreferenceFiles) {
                try {
                    $GooglePreferences = Get-Content -Path $PreferenceFile -Encoding UTF8 -Raw -ErrorAction Stop |
                        Convert-JSONToHashtable -ErrorAction Stop
                }
                catch {
                    Write-Log "Error parsing $PreferenceFile" -Level WARNING
                    continue
                }

                if ($AllProfiles) {
                    $ProfileLocation = $PreferenceFile | Get-Item | Select-Object -ExpandProperty Directory | Split-Path -Leaf
                    $ProfileName = $AllProfiles.profile.info_cache.$ProfileLocation.name
                    $SignedInAccount = $AllProfiles.profile.info_cache.$ProfileLocation.user_name
                }
                else {
                    $ProfileName = $GooglePreferences.profile.name
                    $SignedInAccount = $GooglePreferences.account_info.email
                }

                foreach ($ExtensionID in $GooglePreferences.extensions.settings.Keys) {
                    $thisExtension = $GooglePreferences.extensions.settings.$ExtensionID

                    if ($thisExtension.active_bit -eq 'False') { continue }
                    if (!$thisExtension.manifest.name) { continue }
                    
                    $Extensions.Add(
                        [PSCustomObject]@{
                            Browser             = 'Chrome'
                            User                = $user
                            Profile             = if ($ProfileName) { $ProfileName } else { 'Unavailable' }
                            Name                = $thisExtension.manifest.name
                            'Extension ID'      = $ExtensionID
                            Version             = if ($thisExtension.manifest.version) { $thisExtension.manifest.version } else { 'Unavailable' }
                            'Signed In Account' = if ($SignedInAccount) { $SignedInAccount } else { 'Not signed in' }
                            Description         = $thisExtension.manifest.description
                        }
                    )
                }
            }
        }

        return $Extensions
    }

    function Get-EdgeExtensions {
        <#
        .SYNOPSIS
            Extracts Edge extensions from user profiles.
        #>
        param(
            [Parameter(Mandatory)]
            $UserProfiles
        )

        $Extensions = New-Object System.Collections.Generic.List[object]

        foreach ($Profile in $UserProfiles) {
            $user = $Profile.Name
            $userPath = $Profile.Path

            $EdgeDataPath = "$userPath\AppData\Local\Microsoft\Edge\User Data"

            try {
                if (-not (Test-Path -Path $EdgeDataPath -ErrorAction Stop)) {
                    Write-Log "Edge App Data path does not exist for $user" -Level WARNING
                    continue
                }
            }
            catch {
                Write-Log "Edge App Data could not be accessed for $user" -Level WARNING
                continue
            }

            $AllProfiles = $null
            if (Test-Path -Path "$EdgeDataPath\Local State" -ErrorAction SilentlyContinue) {
                try {
                    $AllProfiles = Get-Content -Path "$EdgeDataPath\Local State" -Encoding UTF8 -Raw -ErrorAction Stop |
                        Convert-JSONToHashtable -ErrorAction Stop
                }
                catch {
                    Write-Log "Error parsing Edge Local State file for $user" -Level WARNING
                    $AllProfiles = $null
                }
            }

            $PreferenceFiles = Get-ChildItem "$EdgeDataPath\*\*Preferences" -Exclude 'System Profile' -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName

            foreach ($PreferenceFile in $PreferenceFiles) {
                try {
                    $EdgePreferences = Get-Content -Path $PreferenceFile -Encoding UTF8 -Raw -ErrorAction Stop |
                        Convert-JSONToHashtable -ErrorAction Stop
                }
                catch {
                    Write-Log "Error parsing $PreferenceFile" -Level WARNING
                    continue
                }

                if ($AllProfiles) {
                    $ProfileLocation = $PreferenceFile | Get-Item | Select-Object -ExpandProperty Directory | Split-Path -Leaf
                    $ProfileName = $AllProfiles.profile.info_cache.$ProfileLocation.name
                    $SignedInAccount = $AllProfiles.profile.info_cache.$ProfileLocation.user_name
                }
                else {
                    $ProfileName = $EdgePreferences.profile.name
                    $SignedInAccount = $EdgePreferences.account_info.email
                }

                foreach ($ExtensionID in $EdgePreferences.extensions.settings.Keys) {
                    $thisExtension = $EdgePreferences.extensions.settings.$ExtensionID

                    if ($thisExtension.active_bit -eq 'False') { continue }
                    if (!$thisExtension.manifest.name) { continue }
                    
                    $Extensions.Add(
                        [PSCustomObject]@{
                            Browser             = 'Edge'
                            User                = $user
                            Profile             = if ($ProfileName) { $ProfileName } else { 'Unavailable' }
                            Name                = $thisExtension.manifest.name
                            'Extension ID'      = $ExtensionID
                            Version             = if ($thisExtension.manifest.version) { $thisExtension.manifest.version } else { 'Unavailable' }
                            'Signed In Account' = if ($SignedInAccount) { $SignedInAccount } else { 'Not signed in' }
                            Description         = $thisExtension.manifest.description
                        }
                    )
                }
            }
        }

        return $Extensions
    }

    function Get-FirefoxExtensions {
        <#
        .SYNOPSIS
            Extracts Firefox extensions from user profiles.
        #>
        param(
            [Parameter(Mandatory)]
            $UserProfiles
        )

        $Extensions = New-Object System.Collections.Generic.List[object]

        foreach ($Profile in $UserProfiles) {
            $user = $Profile.Name
            $userPath = $Profile.Path

            $FirefoxProfilesPath = "$userPath\AppData\Roaming\Mozilla\Firefox\Profiles"

            try {
                if (-not (Test-Path -Path $FirefoxProfilesPath -ErrorAction Stop)) {
                    Write-Log "Firefox profiles path does not exist for $user" -Level WARNING
                    continue
                }
            }
            catch {
                Write-Log "Firefox profiles path could not be accessed for $user" -Level WARNING
                continue
            }

            $FirefoxProfileFolders = Get-ChildItem -Path $FirefoxProfilesPath -Directory -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName

            foreach ($FirefoxProfile in $FirefoxProfileFolders) {
                if (!(Test-Path -Path "$FirefoxProfile\extensions.json")) {
                    continue
                }

                try {
                    $ExtensionsData = Get-Content -Path "$FirefoxProfile\extensions.json" -Encoding UTF8 -Raw -ErrorAction Stop |
                        Convert-JSONToHashtable -ErrorAction Stop
                }
                catch {
                    Write-Log "Error parsing $FirefoxProfile\extensions.json" -Level WARNING
                    continue
                }

                $SignedInAccount = $null
                if (Test-Path "$FirefoxProfile\signedInUser.json") {
                    try {
                        $SignedInData = Get-Content -Path "$FirefoxProfile\signedInUser.json" -Encoding UTF8 -Raw -ErrorAction Stop |
                            Convert-JSONToHashtable -ErrorAction Stop
                        $SignedInAccount = $SignedInData.accountData.email
                    }
                    catch {
                        Write-Log "Error parsing $FirefoxProfile\signedInUser.json" -Level WARNING
                    }
                }

                foreach ($Extension in $ExtensionsData.addons) {
                    $Extensions.Add(
                        [PSCustomObject]@{
                            Browser             = 'Firefox'
                            User                = $user
                            Profile             = ($FirefoxProfile | Split-Path -Leaf) -replace '.+\.'
                            Name                = $Extension.defaultLocale.name
                            'Extension ID'      = $Extension.id
                            Version             = if ($Extension.version) { $Extension.version } else { 'Unavailable' }
                            'Signed In Account' = if ($SignedInAccount) { $SignedInAccount } else { 'Not signed in' }
                            Description         = $Extension.defaultLocale.description
                        }
                    )
                }
            }
        }

        return $Extensions
    }

    if ($env:WYSIWYGCustomFieldName -and $env:WYSIWYGCustomFieldName -notlike 'null') {
        $WysiwygCustomField = $env:WYSIWYGCustomFieldName.Trim()
    }
    else {
        $WysiwygCustomField = $WysiwygCustomField.Trim()
    }

    if ($env:MultilineCustomFieldName -and $env:MultilineCustomFieldName -notlike 'null') {
        $MultilineCustomField = $env:MultilineCustomFieldName.Trim()
    }
    else {
        $MultilineCustomField = $MultilineCustomField.Trim()
    }

    $script:ExitCode = 0

    if ($WysiwygCustomField -match '[^0-9A-Z]') {
        Write-Log 'WYSIWYG Custom Field Name contains invalid characters. Must be uppercase A-Z and 0-9 only' -Level ERROR
        Write-Log 'https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Field-Setup' -Level ERROR
        $WysiwygCustomField = $null
        $script:ExitCode = 1
    }

    if ($MultilineCustomField -match '[^0-9A-Z]') {
        Write-Log 'Multiline Custom Field Name contains invalid characters. Must be uppercase A-Z and 0-9 only' -Level ERROR
        Write-Log 'https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Field-Setup' -Level ERROR
        $MultilineCustomField = $null
        $script:ExitCode = 1
    }

    if ($MultilineCustomField -and $WysiwygCustomField -and $MultilineCustomField -eq $WysiwygCustomField) {
        Write-Log 'Custom Fields of different types cannot have the same name' -Level ERROR
        Write-Log 'https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Fields-Configuration-Device-Role-Fields' -Level ERROR
        exit 1
    }
}

process {
    try {
        if (!(Test-IsElevated)) {
            throw 'Access Denied. Please run with Administrator privileges'
        }

        $ChromeInstallations = [bool](Find-InstallKey -DisplayName 'Chrome')
        $FirefoxInstallations = [bool](Find-InstallKey -DisplayName 'Firefox')
        $EdgeInstallations = [bool](Find-InstallKey -DisplayName 'Edge')

        $UserProfiles = Get-UserHives -Type 'All'

        foreach ($UserProfile in $UserProfiles) {
            $ProfileWasLoaded = Test-Path "Registry::HKEY_USERS\$($UserProfile.SID)"
            
            if (-not $ProfileWasLoaded) {
                try {
                    Start-Process -FilePath 'cmd.exe' -ArgumentList "/C reg.exe LOAD HKU\$($UserProfile.SID) `"$($UserProfile.UserHive)`"" -Wait -WindowStyle Hidden
                }
                catch {
                    Write-Log "Error loading registry hive for $($UserProfile.Name)" -Level WARNING
                    $script:ExitCode = 1
                    continue
                }
            }

            if (Find-InstallKey -UserBaseKey "Registry::HKEY_USERS\$($UserProfile.SID)" -DisplayName 'Chrome') {
                $ChromeInstallations = $True
            }
            
            if (Find-InstallKey -UserBaseKey "Registry::HKEY_USERS\$($UserProfile.SID)" -DisplayName 'Firefox') {
                $FirefoxInstallations = $True
            }
            
            if (Find-InstallKey -UserBaseKey "Registry::HKEY_USERS\$($UserProfile.SID)" -DisplayName 'Edge') {
                $EdgeInstallations = $True
            }

            if (-not $ProfileWasLoaded) {
                [GC]::Collect()
                Start-Sleep 1
                
                try {
                    Start-Process -FilePath 'cmd.exe' -ArgumentList "/C reg.exe UNLOAD HKU\$($UserProfile.SID)" -Wait -WindowStyle Hidden | Out-Null
                }
                catch {
                    Write-Log "Error unloading registry hive for $($UserProfile.Name)" -Level WARNING
                    $script:ExitCode = 1
                }
            }
        }

        $BrowserExtensions = New-Object System.Collections.Generic.List[object]

        if ($ChromeInstallations) {
            Write-Log 'A Google Chrome installation was detected. Searching Chrome for browser extensions...'
            $ChromeExtensions = Get-ChromeExtensions -UserProfiles $UserProfiles
            foreach ($ext in $ChromeExtensions) {
                $BrowserExtensions.Add($ext)
            }
        }

        if ($EdgeInstallations) {
            Write-Log 'A Microsoft Edge installation was detected. Searching Microsoft Edge for browser extensions...'
            $EdgeExtensions = Get-EdgeExtensions -UserProfiles $UserProfiles
            foreach ($ext in $EdgeExtensions) {
                $BrowserExtensions.Add($ext)
            }
        }

        if ($FirefoxInstallations) {
            Write-Log 'A Firefox installation was detected. Searching Firefox for browser extensions...'
            $FirefoxExtensions = Get-FirefoxExtensions -UserProfiles $UserProfiles
            foreach ($ext in $FirefoxExtensions) {
                $BrowserExtensions.Add($ext)
            }
        }

        if ($BrowserExtensions.Count -eq 0) {
            Write-Log 'No browser extensions were found'
            exit $script:ExitCode
        }

        Write-Log 'Browser extensions were detected'

        $BrowserExtensions = $BrowserExtensions | Sort-Object Browser, User, Profile, Name

        $BrowserExtensions = $BrowserExtensions | Select-Object Browser, User, Profile, Name, 'Extension ID', Version, 'Signed In Account', @{
            Name       = 'Description'
            Expression = {
                $Characters = $_.Description | Measure-Object -Character | Select-Object -ExpandProperty Characters
                if ($Characters -gt 75) {
                    "$(($_.Description).SubString(0,75))(...)"
                }
                else {
                    $_.Description
                }
            }
        }

        if ($MultilineCustomField) {
            $multilineCharacterThreshold = 9500

            $multilineStringFormat = {
                "User: $($_.User), Profile: $($_.Profile), Name: $($_.Name), " +
                "Extension ID: $($_.'Extension ID'), Version: $($_.Version), " +
                "Signed In Account: $($_.'Signed In Account')"
            }

            $EdgeList = $BrowserExtensions | Where-Object { $_.Browser -eq 'Edge' } | ForEach-Object $multilineStringFormat
            $ChromeList = $BrowserExtensions | Where-Object { $_.Browser -eq 'Chrome' } | ForEach-Object $multilineStringFormat
            $FirefoxList = $BrowserExtensions | Where-Object { $_.Browser -eq 'Firefox' } | ForEach-Object $multilineStringFormat

            $formattedMultilineString = @"
Microsoft Edge:
$(if ($EdgeList) { $EdgeList -join "`n" } else { 'No extensions found.' })

Google Chrome:
$(if ($ChromeList) { $ChromeList -join "`n" } else { 'No extensions found.' })

Mozilla Firefox:
$(if ($FirefoxList) { $FirefoxList -join "`n" } else { 'No extensions found.' })
"@

            $Characters = $formattedMultilineString | Measure-Object -Character | Select-Object -ExpandProperty Characters

            if ($Characters -ge $multilineCharacterThreshold) {
                Write-Log '10,000 character limit for Multiline fields reached. Trimming output...' -Level WARNING

                $formattedMultilineString = $formattedMultilineString -replace '^(Microsoft Edge:|Google Chrome:|Mozilla Firefox:)', "`nThis info has been truncated to accommodate the 10,000 character limit.`n`n`$1"

                $rowRegex = '(User:.*?Signed In Account:.*(\n|$))|(Microsoft Edge:|Google Chrome:|Mozilla Firefox:|No extensions found.)'

                $lastRowStep = 1
                while ($Characters -ge $multilineCharacterThreshold) {
                    $rows = [regex]::Matches($formattedMultilineString, $rowRegex)
                    $lastRowValue = $rows[$rows.Count - $lastRowStep].Value

                    if ($lastRowValue -match '(Microsoft Edge:|Google Chrome:|Mozilla Firefox:|No extensions found\.)') {
                        $lastRowStep++
                        continue
                    }

                    $rowAboveLastRow = $rows[$rows.Count - $lastRowStep - 1].Value
                    $formattedMultilineString = $formattedMultilineString -replace [regex]::Escape($lastRowValue)

                    if ($rowAboveLastRow -match '(Microsoft Edge:|Google Chrome:|Mozilla Firefox:)') {
                        $formattedMultilineString = $formattedMultilineString -replace [regex]::Escape($rowAboveLastRow), "$rowAboveLastRow`nAll extensions have been truncated."
                    }

                    $lastRowStep = 1
                    $Characters = $formattedMultilineString | Measure-Object -Character | Select-Object -ExpandProperty Characters
                }
            }

            try {
                Write-Log "Publishing browser extensions to Multiline Custom Field '$MultilineCustomField'"
                Set-CustomField -Name $MultilineCustomField -Value $formattedMultilineString -Type 'Multiline'
                Write-Log "Successfully set '$MultilineCustomField' Custom Field"
            }
            catch {
                Write-Log "Error setting '$MultilineCustomField': $_" -Level ERROR
                $script:ExitCode = 1
            }
        }

        if ($WysiwygCustomField) {
            $wysiwygCharacterThreshold = 44500

            $htmlTable = $BrowserExtensions | ConvertTo-Html -Fragment

            $htmlTable = $htmlTable -replace '<th>Browser', '<th style="width:75px;"><b>Browser</b>'
            $htmlTable = $htmlTable -replace '<th>Profile', '<th style="width:130px;"><b>Profile</b>'
            $htmlTable = $htmlTable -replace '<th>Version', '<th><b>Version</b>'
            $htmlTable = $htmlTable -replace '<th>Description', '<th style="width:320px;"><b>Description</b>'
            $htmlTable = $htmlTable -replace '<th>User', '<th style="width:130px;"><b>User</b>'
            $htmlTable = $htmlTable -replace '<th>Name', '<th><b>Name</b>'
            $htmlTable = $htmlTable -replace '<th>Extension ID', '<th style="width:280px;"><b>Extension ID</b>'
            $htmlTable = $htmlTable -replace '<th>Signed In Account', '<th><b>Signed In Account</b>'

            $htmlTable = "<div class='card flex-grow-1'>
                            <div class='card-title-box'>
                                <div class='card-title'><i class='fa-solid fa-globe'></i>&nbsp;&nbsp;Browser Extensions</div>
                            </div>
                            <div class='card-body' style='white-space: nowrap;'>
                                $htmlTable
                            </div>
                        </div>"

            $Characters = $htmlTable | ConvertTo-Json | Measure-Object -Character | Select-Object -ExpandProperty Characters

            if ($Characters -ge $wysiwygCharacterThreshold) {
                Write-Log '45,000 character limit for WYSIWYG fields reached. Trimming output...' -Level WARNING

                $htmlTable = $htmlTable -replace '<table>', '<p>This info has been truncated to accommodate the 45,000 character limit.</p><table>'

                $rowRegex = '<tr>.*?</tr>'

                while ($Characters -ge $wysiwygCharacterThreshold) {
                    $rows = [regex]::Matches($htmlTable, $rowRegex)
                    $lastRowValue = $rows[$rows.Count - 1].Value
                    $htmlTable = $htmlTable -replace [regex]::Escape($lastRowValue)
                    $Characters = $htmlTable | ConvertTo-Json | Measure-Object -Character | Select-Object -ExpandProperty Characters
                }
            }

            try {
                Write-Log "Publishing browser extensions table to WYSIWYG Custom Field '$WysiwygCustomField'"
                Set-CustomField -Name $WysiwygCustomField -Value $htmlTable -Type 'WYSIWYG'
                Write-Log "Successfully set '$WysiwygCustomField' Custom Field"
            }
            catch {
                Write-Log "Error setting '$WysiwygCustomField': $_" -Level ERROR
                $script:ExitCode = 1
            }
        }

        if (($BrowserExtensions | Format-List | Out-String | Measure-Object -Character | Select-Object -ExpandProperty Characters) -ge 9500) {
            Write-Log '10,000 character limit for Activity Feed reached. Trimming output...' -Level WARNING

            if (-not $WysiwygCustomField) {
                Write-Log 'Please publish this report to a WYSIWYG field for a full listing of extensions' -Level WARNING
            }

            do {
                $BrowserExtensions = $BrowserExtensions | Select-Object -SkipLast 1
                $Characters = $BrowserExtensions | Format-List | Out-String | Measure-Object -Character | Select-Object -ExpandProperty Characters
            } while ($Characters -ge 9500)

            ($BrowserExtensions | Format-List | Out-String).TrimEnd() + "`n`n(...)" | Write-Host
        }
        else {
            ($BrowserExtensions | Format-List | Out-String).Trim() | Write-Host
        }

        exit $script:ExitCode
    }
    catch {
        Write-Log "Script failed: $_" -Level ERROR
        exit 1
    }
}

end {
    [System.GC]::Collect()
}
