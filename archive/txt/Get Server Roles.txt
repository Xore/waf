#Requires -Version 4.0

<#
.SYNOPSIS
    Retrieves the installed server roles and optionally sets the Ninja device tags accordingly.
.DESCRIPTION
    Retrieves the installed server roles and optionally sets the Ninja device tags accordingly.
.EXAMPLE
    -MultilineCustomField "multiline" -SetTags -RemoveUnusedRoleTags

    ### Current Server Roles ###

    DisplayName : Active Directory Domain Services
    Name        : AD-Domain-Services
    InstallName : DirectoryServices-DomainController
    Acronym     : ADDS

    DisplayName : DNS Server
    Name        : DNS
    InstallName : DNS-Server-Full-Role
    Acronym     : DNSS

    DisplayName : File Server
    Name        : FS-FileServer
    InstallName : CoreFileServer
    Acronym     : FS

    DisplayName : Server for NFS
    Name        : FS-NFS-Service
    InstallName : {ServicesForNFS-ServerAndClient, ServerForNFS-Infrastructure}
    Acronym     : SNFS

    DisplayName : Storage Services
    Name        : Storage-Services
    InstallName : Storage-Services
    Acronym     : SS

    All unused server role tags are already removed.
    Assigning the tag 'ADDS'.
    Successfully assigned the tag.
    Assigning the tag 'DNS'.
    Successfully assigned the tag.
    Assigning the tag 'CoreFileServer'.
    Successfully assigned the tag.
    Assigning the tag 'ServicesForNFS-ServerAndClient'.
    Successfully assigned the tag.
    Assigning the tag 'Storage Services'.
    Successfully assigned the tag.

    Attempting to set the custom field 'Multiline'.
    Successfully set the custom field 'Multiline'!

.PARAMETER -SetTags
    Assigns each installed role as a device tag. The device tag must be equal to its DisplayName, Name, InstallName, or Acronym.

.PARAMETER -RemoveUnusedRoleTags
    Checks the currently assigned device tags, and if a tag matches a role that is not installed, removes it.

.PARAMETER -MultilineCustomField "ReplaceMeWithAMultilineCustomField"
    Optionally saves the results to a multiline custom field.

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2
    Version: 1.1
    Release Notes:
    - Resolved duplicate acronym handling when using 'Remove Unused Role Tags'.
    - No longer prioritizing existing tags.
    - Set to only remove role tags.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$MultilineCustomField,
    [Parameter()]
    [Switch]$SetTags = [System.Convert]::ToBoolean($env:setTags),
    [Parameter()]
    [Switch]$RemoveUnusedRoleTags = [System.Convert]::ToBoolean($env:removeUnusedRoleTags)
)

begin {
    # If script form variables are used, replace the command-line parameter with their value.
    if ($env:multilineCustomFieldName) { $MultilineCustomField = $env:multilineCustomFieldName }

    # Validate the Multiline Custom Field if it is provided.
    if ($MultilineCustomField) {
        # Check if the provided field is empty or contains only whitespace.
        if ([String]::IsNullOrWhiteSpace($MultilineCustomField)) {
            Write-Host -Object "[Error] The 'Multiline Custom Field Name' is invalid."
            Write-Host -Object "[Error] Please provide a valid Multiline Custom Field Name to save the results, or leave it blank."
            Write-Host -Object "[Error] https://ninjarmm.zendesk.com/hc/articles/360060920631-Custom-Field-Setup"
            exit 1
        }

        # Trim any whitespace.
        $MultilineCustomField = $MultilineCustomField.Trim()

        # Validate that the custom field contains only valid characters (digits and uppercase letters).
        if ($MultilineCustomField -match "[^0-9A-Z]") {
            Write-Host -Object "[Error] The 'Multiline Custom Field Name' of '$MultilineCustomField' is invalid because it contains invalid characters."
            Write-Host -Object "[Error] Please provide a valid Multiline Custom Field Name to save the results, or leave it blank."
            Write-Host -Object "[Error] https://ninjarmm.zendesk.com/hc/articles/360060920631-Custom-Field-Setup"
            exit 1
        }
    }

    # Fallback roll names
    $EnglishNames = @(
        [PSCustomObject]@{ NumericId = 16; DisplayName = "Active Directory Certificate Services"; Name = "AD-Certificate"; InstallName = "ADCertificateServicesRole"; Acronym = "ADCS" }
        [PSCustomObject]@{ NumericId = 10; DisplayName = "Active Directory Domain Services"; Name = "AD-Domain-Services"; InstallName = "DirectoryServices-DomainController"; Acronym = "ADDS" }
        [PSCustomObject]@{ NumericId = 8; DisplayName = "Active Directory Federation Services"; Name = "ADFS-Federation"; InstallName = "IdentityServer-SecurityTokenService"; Acronym = "ADFS" }
        [PSCustomObject]@{ NumericId = 9; DisplayName = "Active Directory Lightweight Directory Services"; Name = "ADLDS"; InstallName = "DirectoryServices-ADAM"; Acronym = "ADLDS" }
        [PSCustomObject]@{ NumericId = 17; DisplayName = "Active Directory Rights Management Services"; Name = "ADRMS"; InstallName = "RightsManagementServices-Role"; Acronym = "ADRMS" }
        [PSCustomObject]@{ NumericId = 1; DisplayName = "Application Server"; Name = "Application-Server"; InstallName = "Application-Server"; Acronym = "AS" }
        [PSCustomObject]@{ NumericId = 1025; DisplayName = "Device Health Attestation"; Name = "DeviceHealthAttestationService"; InstallName = "DeviceHealthAttestationService"; Acronym = "DHA" }
        [PSCustomObject]@{ NumericId = 12; DisplayName = "DHCP Server"; Name = "DHCP"; InstallName = "DHCPServer"; Acronym = "DHCPS" }
        [PSCustomObject]@{ NumericId = 13; DisplayName = "DNS Server"; Name = "DNS"; InstallName = "DNS-Server-Full-Role"; Acronym = "DNSS" }
        [PSCustomObject]@{ NumericId = 5; DisplayName = "Fax Server"; Name = "Fax"; InstallName = "FaxServiceRole"; Acronym = "FS" }
        [PSCustomObject]@{ NumericId = 255; DisplayName = "File Server"; Name = "FS-FileServer"; InstallName = "CoreFileServer"; Acronym = "FS" }
        [PSCustomObject]@{ NumericId = 350; DisplayName = "BranchCache for Network Files"; Name = "FS-BranchCache"; InstallName = "SMBHashGeneration"; Acronym = "BCNF" }
        [PSCustomObject]@{ NumericId = 436; DisplayName = "Data Deduplication"; Name = "FS-Data-Deduplication"; InstallName = "Dedup-Core"; Acronym = "DD" }
        [PSCustomObject]@{ NumericId = 101; DisplayName = "DFS Namespaces"; Name = "FS-DFS-Namespace"; InstallName = "DFSN-Server"; Acronym = "DFSN" }
        [PSCustomObject]@{ NumericId = 102; DisplayName = "DFS Replication"; Name = "FS-DFS-Replication"; InstallName = "DFSR-Infrastructure-ServerEdition"; Acronym = "DFSR" }
        [PSCustomObject]@{ NumericId = 104; DisplayName = "File Server Resource Manager"; Name = "FS-Resource-Manager"; InstallName = "FSRM-Infrastructure"; Acronym = "FSRM" }
        [PSCustomObject]@{ NumericId = 434; DisplayName = "File Server VSS Agent Service"; Name = "FS-VSS-Agent"; InstallName = "FileServerVSSAgent"; Acronym = "FSVSSAS" }
        [PSCustomObject]@{ NumericId = 435; DisplayName = "iSCSI Target Server"; Name = "FS-iSCSITarget-Server"; InstallName = "iSCSITargetServer"; Acronym = "SCSITS" }
        [PSCustomObject]@{ NumericId = 437; DisplayName = "iSCSI Target Storage Provider (VDS and VSS hardware providers)"; Name = "iSCSITarget-VSS-VDS"; InstallName = "SCSITargetStorageProviders"; Acronym = "SCSITSPVDSVSS" }
        [PSCustomObject]@{ NumericId = 431; DisplayName = "Server for NFS"; Name = "FS-NFS-Service"; InstallName = @("ServicesForNFS-ServerAndClient", "ServerForNFS-Infrastructure"); Acronym = "SNFS" }
        [PSCustomObject]@{ NumericId = 486; DisplayName = "Work Folders"; Name = "FS-SyncShareService"; InstallName = "WorkFolders-Server"; Acronym = "WF" }
        [PSCustomObject]@{ NumericId = 482; DisplayName = "Storage Services"; Name = "FStorage-Services"; InstallName = "Storage-Services"; Acronym = "SS" }
        [PSCustomObject]@{ NumericId = 1009; DisplayName = "Host Guardian Service"; Name = "HostGuardianServiceRole"; InstallName = "HostGuardianService-Package"; Acronym = "HGS" }
        [PSCustomObject]@{ NumericId = 20; DisplayName = "Hyper-V"; Name = "Hyper-V"; InstallName = @("Microsoft-Hyper-V-Offline", "Microsoft-Hyper-V-Online"); Acronym = "HV" }
        [PSCustomObject]@{ NumericId = 1001; DisplayName = "MultiPoint Services"; Name = "MultiPointServerRole"; InstallName = "MultiPoint-Role"; Acronym = "MPS" }
        [PSCustomObject]@{ NumericId = 14; DisplayName = "Network Policy and Access Services"; Name = "NPAS"; InstallName = "NPAS-Role"; Acronym = "NPAS" }
        [PSCustomObject]@{ NumericId = 7; DisplayName = "Print and Document Services"; Name = "Print-Services"; InstallName = "Printing-Server-Foundation-Features"; Acronym = "PDS" }
        [PSCustomObject]@{ NumericId = 468; DisplayName = "Remote Access"; Name = "RemoteAccess"; InstallName = "RemoteAccess"; Acronym = "RA" }
        [PSCustomObject]@{ NumericId = 18; DisplayName = "Remote Desktop Services"; Name = "Remote-Desktop-Services"; InstallName = "Remote-Desktop-Services"; Acronym = "RDS" }
        [PSCustomObject]@{ NumericId = 430; DisplayName = "Volume Activation Services"; Name = "VolumeActivation"; InstallName = "VolumeActivation-Full-Role"; Acronym = "VAS" }
        [PSCustomObject]@{ NumericId = 2; DisplayName = "Web Server (IIS)"; Name = "Web-Server"; InstallName = "IIS-WebServerRole"; Acronym = "IIS" }
        [PSCustomObject]@{ NumericId = 19; DisplayName = "Windows Deployment Services"; Name = "WDS"; InstallName = "Microsoft-Windows-Deployment-Services"; Acronym = "WDS" }
        [PSCustomObject]@{ NumericId = 485; DisplayName = "Windows Server Essentials Experience"; Name = "ServerEssentialsRole"; InstallName = "WSS-Product-Package"; Acronym = "WSEE" }
        [PSCustomObject]@{ NumericId = 404; DisplayName = "Windows Server Update Services"; Name = "UpdateServices"; InstallName = "UpdateServices"; Acronym = "WSUS" }
    )

    function Get-N1Tags {
        [CmdletBinding()]
        param(
            [Parameter()]
            [Switch]$Assigned
        )

        # Initialize a ProcessStartInfo object to configure the process
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

        $NinjaCliArguments = New-Object System.Collections.Generic.List[String]
        $NinjaCliArguments.Add("--direct-out")
        if ($Assigned) {
            $NinjaCliArguments.Add("tag-get")
        } else {
            $NinjaCliArguments.Add("tag-options")
        }

        $ProcessInfo.Arguments = $NinjaCliArguments -join " "

        # Configure the process to not use the shell and redirect input/output
        $ProcessInfo.UseShellExecute = $False
        $ProcessInfo.RedirectStandardOutput = $True
        $ProcessInfo.RedirectStandardError = $True
        $ProcessInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $ProcessInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $ProcessInfo.CreateNoWindow = $True

        # Start the process
        $ninjarmmcli = [System.Diagnostics.Process]::Start($ProcessInfo)

        if (!$ninjarmmcli) {
            Write-Error -Category ResourceUnavailable -Exception (New-Object System.ObjectDisposedException("The ninjarmm-cli process object was not found."))
            return
        }

        $ninjarmmcli.WaitForExit()

        # Read and output any errors from the process's standard error stream
        while (!$ninjarmmcli.StandardError.EndOfStream) {
            $ninjarmmcli.StandardError.ReadLine() | Write-Error
        }

        # Read and output the process's standard output
        while (!$ninjarmmcli.StandardOutput.EndOfStream) {
            $ninjarmmcli.StandardOutput.ReadLine()
        }
    }

    function Set-N1Tag {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $True)]
            [String]$Name
        )

        # Initialize a ProcessStartInfo object to configure the process
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
        $ProcessInfo.Arguments = "--direct-out tag-set `"$Name`""

        # Configure the process to not use the shell and redirect input/output
        $ProcessInfo.UseShellExecute = $False
        $ProcessInfo.RedirectStandardOutput = $True
        $ProcessInfo.RedirectStandardError = $True
        $ProcessInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $ProcessInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $ProcessInfo.CreateNoWindow = $True

        # Start the process
        $ninjarmmcli = [System.Diagnostics.Process]::Start($ProcessInfo)

        if (!$ninjarmmcli) {
            Write-Error -Category ResourceUnavailable -Exception (New-Object System.ObjectDisposedException("The ninjarmm-cli process object was not found."))
            return
        }

        $ninjarmmcli.WaitForExit()

        # Read and output any errors from the process's standard error stream
        while (!$ninjarmmcli.StandardError.EndOfStream) {
            $ninjarmmcli.StandardError.ReadLine() | Write-Error
        }

        # Read and output the process's standard output
        while (!$ninjarmmcli.StandardOutput.EndOfStream) {
            $ninjarmmcli.StandardOutput.ReadLine()
        }
    }

    function Remove-N1Tag {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $True)]
            [String]$Name
        )

        # Initialize a ProcessStartInfo object to configure the process
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
        $ProcessInfo.Arguments = "--direct-out tag-clear `"$Name`""

        # Configure the process to not use the shell and redirect input/output
        $ProcessInfo.UseShellExecute = $False
        $ProcessInfo.RedirectStandardOutput = $True
        $ProcessInfo.RedirectStandardError = $True
        $ProcessInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $ProcessInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $ProcessInfo.CreateNoWindow = $True

        # Start the process
        $ninjarmmcli = [System.Diagnostics.Process]::Start($ProcessInfo)

        if (!$ninjarmmcli) {
            Write-Error -Category ResourceUnavailable -Exception (New-Object System.ObjectDisposedException("The ninjarmm-cli process object was not found."))
            return
        }

        $ninjarmmcli.WaitForExit()

        # Read and output any errors from the process's standard error stream
        while (!$ninjarmmcli.StandardError.EndOfStream) {
            $ninjarmmcli.StandardError.ReadLine() | Write-Error
        }

        # Read and output the process's standard output
        while (!$ninjarmmcli.StandardOutput.EndOfStream) {
            $ninjarmmcli.StandardOutput.ReadLine()
        }
    }


    function Test-IsServer {
        [CmdletBinding()]
        param()

        # Determine the method to retrieve the operating system information based on PowerShell version
        $OS = if ($PSVersionTable.PSVersion.Major -lt 3) {
            Get-WmiObject -Class Win32_OperatingSystem
        } else {
            Get-CimInstance -ClassName Win32_OperatingSystem
        }

        # Check if the ProductType is "2", which indicates that the system is a domain controller or is a server
        if (($OS.ProductType -eq "2" -or $OS.ProductType -eq "3") -and $OS.OperatingSystemSku -ne "175") {
            return $true
        }
    }

    function Set-CustomField {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value,
            [Parameter()]
            [String]$Type,
            [Parameter()]
            [String]$DocumentName,
            [Parameter()]
            [Switch]$Piped
        )

        if ($Type -eq "Date Time") { $Type = "DateTime" }
        if ($Type -match "[-]") { $Type = $Type -replace '-' }
        if ($Type -match "[/]") { $Type = $Type -replace '/' }

        # Remove the non-breaking space character
        if ($Type -eq "WYSIWYG") {
            $Value = $Value -replace ' ', '&nbsp;'
        }

        if ($Type -eq "DateTime" -or $Type -eq "Date") {
            $Type = "Date or Date Time"
        }

        # Measure the number of characters in the provided value
        $Characters = $Value | ConvertTo-Json | Measure-Object -Character | Select-Object -ExpandProperty Characters

        # Throw an error if the value exceeds the character limit of 200,000 characters
        if ($Piped -and $Characters -ge 200000) {
            throw [System.ArgumentOutOfRangeException]::New("Character limit exceeded: the value is greater than or equal to 200,000 characters.")
        }

        if (!$Piped -and $Characters -ge 45000) {
            throw [System.ArgumentOutOfRangeException]::New("Character limit exceeded: the value is greater than or equal to 45,000 characters.")
        }

        # Initialize a hashtable for additional documentation parameters
        $DocumentationParams = @{}

        # If a document name is provided, add it to the documentation parameters
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }

        # Define a list of valid field types
        $ValidFields = "Checkbox", "Date", "Date or Date Time", "DateTime", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine",
        "MultiSelect", "Phone", "Secure", "Text", "Time", "URL", "WYSIWYG"

        # Warn the user if the provided type is not valid
        if ($Type -and $ValidFields -notcontains $Type) { Write-Warning "$Type is an invalid type. Please check here for valid types: https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" }

        # Define types that require options to be retrieved
        $NeedsOptions = "Dropdown", "MultiSelect"

        # If the property is being set in a document or field and the type needs options, retrieve them
        if ($DocumentName) {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
        } else {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }

        # Throw an error if there was an issue retrieving the property options
        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }

        # Process the property value based on its type
        switch ($Type) {
            "Checkbox" {
                # Convert the value to a boolean for Checkbox type
                $NinjaValue = [System.Convert]::ToBoolean($Value)
            }
            "Date or Date Time" {
                # Convert the value to a Unix timestamp for Date or Date Time type
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
                [long]$NinjaValue = $TimeSpan.TotalSeconds
            }
            "Dropdown" {
                # Convert the dropdown value to its corresponding GUID
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID

                # Throw an error if the value is not present in the dropdown options
                if (!($Selection)) {
                    throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown options.")
                }

                $NinjaValue = $Selection
            }
            "MultiSelect" {
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selections = New-Object System.Collections.Generic.List[String]
                if ($Value -match "[,]") {
                    $Value = $Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                }

                $Value | ForEach-Object {
                    $GivenValue = $_
                    $Selection = $Options | Where-Object { $_.Name -eq $GivenValue } | Select-Object -ExpandProperty GUID

                    # Throw an error if the value is not present in the dropdown options
                    if (!($Selection)) {
                        throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown options.")
                    }

                    $Selections.Add($Selection)
                }

                $NinjaValue = $Selections -join ","
            }
            "Time" {
                # Convert the value to a Unix timestamp for Date or Date Time type
                $LocalTime = (Get-Date $Value)
                $LocalTimeZone = [TimeZoneInfo]::Local
                $UtcTime = [TimeZoneInfo]::ConvertTimeToUtc($LocalTime, $LocalTimeZone)

                [long]$NinjaValue = ($UtcTime.TimeOfDay).TotalSeconds
            }
            default {
                # For other types, use the value as is
                $NinjaValue = $Value
            }
        }

        # Set the property value in the document if a document name is provided
        if ($DocumentName) {
            $CustomField = Ninja-Property-Docs-Set -AttributeName $Name -AttributeValue $NinjaValue @DocumentationParams 2>&1
        } else {
            try {
                # Otherwise, set the standard property value
                if ($Piped) {
                    $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
                } else {
                    $CustomField = Ninja-Property-Set -Name $Name -Value $NinjaValue 2>&1
                }
            } catch {
                throw $_.Exception.Message
            }
        }

        # Throw an error if setting the property failed
        if ($CustomField.Exception) {
            throw $CustomField
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

    if (!$ExitCode) {
        $ExitCode = 0
    }
}
process {
    # Attempt to determine if the current session is running with Administrator privileges.
    try {
        $IsElevated = Test-IsElevated -ErrorAction Stop
    } catch {
        # Log an error if unable to determine administrative privileges
        Write-Host -Object "[Error] $($_.Exception.Message)"
        Write-Host -Object "[Error] Unable to determine if the account '$env:Username' has Administrator privileges."
        exit 1
    }

    # Exit if the script is not running with Administrator privileges
    if (!$IsElevated) {
        Write-Host -Object "[Error] Access Denied: Please run with Administrator privileges."
        exit 1
    }

    # Check if the current device is a server
    try {
        $IsServer = Test-IsServer -ErrorAction Stop
    } catch {
        # Log an error if unable to determine if the device is a server
        Write-Host -Object "[Error] $($_.Exception.Message)"
        Write-Host -Object "[Error] Unable to determine if this device is a server."
        exit 1
    }

    # Exit if the device is not a server
    if (!$IsServer) {
        Write-Host -Object "[Error] Windows workstations do not support server roles. Please run this script on a device with Windows Server installed."
        exit 1
    }

    # Retrieve the list of server roles and their installation status
    try {
        $ServerRoles = Get-WindowsFeature -ErrorAction Stop | Where-Object { $_.AdditionalInfo.NumericId -ne 481 -and $_.AdditionalInfo.NumericId -ne 6 -and
            ($_.FeatureType -like "Role" -or $_.Parent -eq "File-Services" -or $_.Parent -eq "FileAndStorage-Services") } |
            Select-Object DisplayName, Name, @{ Name = "NumericId"; Expression = { $_.AdditionalInfo.NumericId } },
            @{ Name = "InstallName"; Expression = { $_.AdditionalInfo.InstallName } },
            @{ Name = "Acronym"; Expression = { ("$($_.DisplayName)" -creplace "[^A-Z]") } }, Installed

        # Adjust acronyms for roles with parentheses in their display names
        $ServerRoles = $ServerRoles | ForEach-Object {
            if ($_.DisplayName -match "[\(\)]") {
                $_.Acronym = $_.DisplayName -replace "[^\(]+\(" -replace "\).*"
            }

            $_
        }

        # Separate installed and uninstalled server roles
        $CurrentServerRoles = $ServerRoles | Where-Object { $_.Installed }
        $UninstalledServerRoles = $ServerRoles | Where-Object { !$_.Installed }
    } catch {
        # Log an error if unable to retrieve server roles
        Write-Host -Object "[Error] $($_.Exception.Message)"
        Write-Host -Object "[Error] Unable to retrieve the current Windows Server roles."
        exit 1
    }

    # Warn if no server roles are installed
    if (!$CurrentServerRoles) {
        Write-Host -Object "[Warning] No server roles are installed on this device."
    } else {
        # Display the list of currently installed server roles
        Write-Host -Object "`n### Current Server Roles ###`n"
        ($CurrentServerRoles | Format-List -Property DisplayName, Name, InstallName, Acronym | Out-String).Trim() | Write-Host
        Write-Host -Object ""
    }

    # Initialize tag management if tagging options are enabled
    if ($SetTags -or $RemoveUnusedRoleTags) {
        try {
            # Retrieve the list of available tags
            $AvailableTags = Get-N1Tags -ErrorAction Stop
        } catch {
            # Log an error if unable to retrieve available tags
            Write-Host -Object "[Error] $($_.Exception.Message)"
            Write-Host -Object "[Error] Failed to retrieve the available tags."
            $ExitCode = 1
        }

        try {
            # Retrieve the list of currently assigned tags
            $CurrentlyAssignedTags = Get-N1Tags -Assigned -ErrorAction Stop
        } catch {
            # Log an error if unable to retrieve assigned tags
            Write-Host -Object "[Error] $($_.Exception.Message)"
            Write-Host -Object "[Error] Failed to retrieve the assigned tags."
            $ExitCode = 1
        }

        # Initialize lists for tags to assign and remove
        $TagsToAssign = New-Object System.Collections.Generic.List[String]
        $TagsToRemove = New-Object System.Collections.Generic.List[String]
    }

    # Notify if there are no unused tags to remove
    if ($RemoveUnusedRoleTags -and !$CurrentlyAssignedTags) {
        Write-Host -Object "All unused server role tags are already removed."
    }

    # Notify if there are no available tags to set
    if ($SetTags -and !$AvailableTags) {
        Write-Host -Object "[Error] There are no available tags to set."
        $ExitCode = 1
    }

    # Identify tags to assign for installed server roles
    if ($CurrentServerRoles -and $SetTags -and $AvailableTags) {
        $CurrentServerRoles | ForEach-Object {

            if ($AvailableTags -contains $_.DisplayName) {
                Write-Verbose -Message "The display name $($_.DisplayName) is available to assign."
                $TagsToAssign.Add($_.DisplayName)
                return
            }

            if ($AvailableTags -contains $_.Name) {
                Write-Verbose -Message "The display name $($_.Name) is available to assign."
                $TagsToAssign.Add($_.Name)
                return
            }

            foreach ($InstallName in $_.InstallName) {
                if ($AvailableTags -contains $InstallName) {
                    Write-Verbose -Message "The install name $InstallName is available to assign."
                    $TagsToAssign.Add($InstallName)
                    return
                }
            }

            if ($AvailableTags -contains $_.Acronym) {
                Write-Verbose -Message "The acronym $($_.Acronym) is available to assign."
                $TagsToAssign.Add($_.Acronym)
                return
            }

            # Check for English name equivalents of the role
            $DesiredId = $_.NumericId
            $EnglishName = $EnglishNames | Where-Object { $_.NumericId -eq $DesiredId }
            if (!$EnglishName) {
                Write-Host -Object "[Error] Unable to find the tag for the role '$($_.DisplayName)'."
                Write-Host -Object "[Error] Please create a tag that equals its DisplayName, Name, InstallName or Acronym."
                $ExitCode = 1
                return
            }

            if ($AvailableTags -contains $EnglishName.DisplayName) {
                Write-Verbose -Message "The display name $($EnglishName.DisplayName) is available to assign."
                $TagsToAssign.Add($EnglishName.DisplayName)
                return
            }

            if ($AvailableTags -contains $EnglishName.Name) {
                Write-Verbose -Message "The install name $($EnglishName.Name) is available to assign."
                $TagsToAssign.Add($EnglishName.Name)
                return
            }

            foreach ($InstallName in $EnglishName.InstallName) {
                if ($AvailableTags -contains $InstallName) {
                    Write-Verbose -Message "The install name $InstallName is available to assign."
                    $TagsToAssign.Add($InstallName)
                    return
                }
            }

            if ($AvailableTags -contains $EnglishName.Acronym) {
                Write-Verbose -Message "The acronym $($EnglishName.Acronym) is available to assign."
                $TagsToAssign.Add($EnglishName.Acronym)
                return
            }

            # Log an error if unable to find a tag for the role
            Write-Host -Object "[Error] Unable to find the tag for the role '$($_.DisplayName)'."
            Write-Host -Object "[Error] Please create a tag that equals its DisplayName, Name, InstallName or Acronym."
            $ExitCode = 1
        }
    }

    # Identify tags to remove for uninstalled server roles
    if ($UninstalledServerRoles -and $RemoveUnusedRoleTags -and $CurrentlyAssignedTags) {
        $CurrentlyAssignedTags | ForEach-Object {
            if ($TagsToAssign -contains $_) {
                return
            }

            if ($ServerRoles.DisplayName -contains $_) {
                Write-Verbose -Message "This device is assigned the tag '$_'."
                $TagsToRemove.Add("$_")
                return
            }

            if ($ServerRoles.Name -contains $_) {
                Write-Verbose -Message "This device is assigned the tag '$_'."
                $TagsToRemove.Add("$_")
                return
            }

            if ($ServerRoles.InstallName -contains $_) {
                Write-Verbose -Message "This device is assigned the tag '$_'."
                $TagsToRemove.Add("$_")
                return
            }

            if ($ServerRoles.Acronym -contains $_) {
                Write-Verbose -Message "This device is assigned the tag '$_'."
                $TagsToRemove.Add("$_")
                return
            }

            # Check for English name equivalents of the role
            if ($EnglishNames.DisplayName -contains $_) {
                Write-Verbose -Message "This device is assigned the tag '$_'."
                $TagsToRemove.Add("$_")
                return
            }

            if ($EnglishNames.Name -contains $_) {
                Write-Verbose -Message "This device is assigned the tag '$_'."
                $TagsToRemove.Add("$_")
                return
            }

            if ($EnglishNames.InstallName -contains $_) {
                Write-Verbose -Message "This device is assigned the tag '$_'."
                $TagsToRemove.Add("$_")
                return
            }

            if ($EnglishNames.Acronym -contains $_) {
                Write-Verbose -Message "This device is assigned the tag '$_'."
                $TagsToRemove.Add("$_")
                return
            }
        }
    }

    # Check if there are tags to remove
    if ($TagsToRemove.Count -gt 0) {
        $TagsToRemove | Select-Object -Unique | ForEach-Object {
            try {
                # Attempt to remove the tag
                Write-Host -Object "Removing the tag '$_' because it no longer applies."
                Remove-N1Tag -Name $_ -ErrorAction Stop
                Write-Host -Object "Successfully removed the tag."
            } catch {
                # Log an error if the tag removal fails
                Write-Host -Object "[Error] $($_.Exception.Message)"
                Write-Host -Object "[Error] Failed to remove the requested tag."
                $ExitCode = 1
            }
        }
    }

    # Check if there are tags to assign and if there are currently assigned tags
    if ($TagsToAssign.Count -gt 0 -and $CurrentlyAssignedTags) {
        # Initialize a list to store tags that are already assigned
        $AlreadyAssignedTags = New-Object System.Collections.Generic.List[String]

        # Iterate through the tags to assign
        $TagsToAssign | ForEach-Object {
            # If the tag is not already in the list of assigned tags, notify the user
            if ($CurrentlyAssignedTags -contains $_ -and $AlreadyAssignedTags -notcontains $_) {
                Write-Host -Object "This device is already assigned the tag '$_'."
            }

            # If the tag is in the list of currently assigned tags, add it to the list of already assigned tags
            if ($CurrentlyAssignedTags -contains $_) {
                $AlreadyAssignedTags.Add($_)
            }
        }

        # Remove tags that are already assigned from the list of tags to assign
        $AlreadyAssignedTags | ForEach-Object {
            $TagsToAssign.Remove("$_") | Out-Null
        }
    }

    # Check if there are tags to assign
    if ($TagsToAssign.Count -gt 0) {
        $TagsToAssign | Select-Object -Unique | ForEach-Object {
            try {
                # Attempt to assign the tag
                Write-Host -Object "Assigning the tag '$_'."
                Set-N1Tag -Name $_ -ErrorAction Stop
                Write-Host -Object "Successfully assigned the tag."
            } catch {
                # Log an error if the tag assignment fails
                Write-Host -Object "[Error] $($_.Exception.Message)"
                Write-Host -Object "[Error] Failed to assign the requested tag."
                $ExitCode = 1
            }
        }
    }

    # Check if a custom field name is provided
    if ($MultilineCustomField) {
        Write-Host "`nAttempting to set the custom field '$MultilineCustomField'."

        # Initialize a list to store the custom field value
        $CustomFieldValue = New-Object System.Collections.Generic.List[string]

        # Add current server roles to the custom field value
        if ($CurrentServerRoles) {
            $CustomFieldValue.Add("### Current Server Roles ###")
            ($CurrentServerRoles | Format-List -Property DisplayName, Name, InstallName, Acronym | Out-String).Trim() -split "`n" | ForEach-Object {
                if ([string]::IsNullOrWhiteSpace($_)) {
                    $CustomFieldValue.Add("")
                } else {
                    $CustomFieldValue.Add($_)
                }
            }
        } else {
            # Add a warning if no server roles are installed
            $CustomFieldValue.Add("[Warning] No server roles are currently installed.")
        }

        # Check if the custom field value exceeds the character limit
        $Characters = $CustomFieldValue | ConvertTo-Json | Measure-Object -Character | Select-Object -ExpandProperty Characters
        if ($Characters -ge 9500) {
            Write-Host "[Warning] The 10,000-character limit has been reached! Trimming output until the character limit is satisfied."

            # Truncate output if it exceeds the limit
            $i = 0
            [array]$CustomFieldList = $CustomFieldValue
            do {
                # Notify the user that data is being truncated
                $CustomFieldValue = New-Object System.Collections.Generic.List[String]
                $CustomFieldValue.Add("[Warning] This info has been truncated to accommodate the 10,000 character limit.")
                $CustomFieldValue.Add("")

                # Reverse the order of existing data so that the latest entries appear first
                [array]::Reverse($CustomFieldList)

                # Remove the oldest entry to reduce character count
                $CustomFieldList[$i] = $null
                $i++

                # Restore the original order of remaining data
                [array]::Reverse($CustomFieldList)

                # Append truncated data back to the custom field value
                $CustomFieldValue.Add($($CustomFieldList | Out-String))

                # Recalculate character count and continue trimming if necessary
                $Characters = ($CustomFieldValue | Out-String) | ConvertTo-Json | Measure-Object -Character | Select-Object -ExpandProperty Characters
            } while ($Characters -ge 9500)
        }

        try {
            # Attempt to set the custom field
            Set-CustomField -Name $MultilineCustomField -Value ($CustomFieldValue | Out-String) -ErrorAction Stop
            Write-Host "Successfully set the custom field '$MultilineCustomField'!"
        } catch {
            # Log an error if setting the custom field fails
            Write-Host -Object "[Error] $($_.Exception.Message)"
            Write-Host -Object "[Error] Unable to set the custom field '$MultilineCustomField'."
            $ExitCode = 1
        }
    }

    exit $ExitCode
}
end {
    
    
    
}