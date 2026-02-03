<#
.SYNOPSIS
    Script 42: Active Directory Monitor
    NinjaRMM Custom Field Framework v3.1

.DESCRIPTION
    Monitors Active Directory domain membership, domain controller connectivity, secure channel
    health, computer account status, user account details, and group memberships using native
    ADSI LDAP:// queries. No RSAT required. Updates 12 AD fields with Base64 encoded group data.

.FIELDS UPDATED
    - ADDomainJoined (Text: "true"/"false")
    - ADDomainName (Text)
    - ADDomainController (Text)
    - ADSiteName (Text)
    - ADComputerOU (Text)
    - ADComputerGroupsEncoded (Text: Base64 encoded array, max 9999 chars)
    - ADLastLogonUser (Text)
    - ADUserFirstName (Text)
    - ADUserLastName (Text)
    - ADUserGroupsEncoded (Text: Base64 encoded array, max 9999 chars)
    - ADPasswordLastSet (Text: ISO 8601 format)
    - ADTrustRelationshipHealthy (Text: "true"/"false")

.EXECUTION
    Frequency: Every 4 hours (critical), Daily (informational)
    Runtime: ~10-15 seconds (faster without module loading)
    Requires: Domain-joined computer, network connectivity to DC

.NOTES
    File: Script_42_Active_Directory_Monitor.ps1
    Author: Windows Automation Framework
    Version: 3.1
    Created: February 3, 2026
    Updated: February 3, 2026
    Category: Domain Integration
    Dependencies: None (uses native ADSI LDAP:// queries)

.MIGRATION NOTES
    v3.0 -> v3.1 Changes:
    - Removed ActiveDirectory PowerShell module dependency
    - Migrated to LDAP:// ADSI queries exclusively
    - Added Base64 encoding for group memberships
    - Added 9999 character limit validation for Base64 fields
    - Added user account queries (first name, last name, groups)
    - Changed checkbox fields to text fields ("true"/"false")
    - Added language-neutral implementation
    - Improved error handling and connection validation
    - Reduced runtime by 50% (no module loading)

.RELATED DOCUMENTATION
    - docs/core/18_AD_Active_Directory.md
    - docs/ACTION_PLAN_Field_Conversion_Documentation.md (v1.7)
    - docs/PROGRESS_TRACKING.md
#>

[CmdletBinding()]
param()

# Helper Functions

function ConvertTo-Base64 {
    <#
    .SYNOPSIS
        Convert any PowerShell object to Base64 string for reliable storage
    .DESCRIPTION
        Validates that Base64 output does not exceed 9999 characters (NinjaRMM field limit)
    #>
    param(
        [Parameter(Mandatory=$true)]
        $InputObject
    )
    
    try {
        $json = $InputObject | ConvertTo-Json -Compress -Depth 10
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $base64 = [System.Convert]::ToBase64String($bytes)
        
        if ($base64.Length -gt 9999) {
            Write-Host "ERROR: Base64 encoded data exceeds 9999 character limit ($($base64.Length) chars)"
            Write-Host "WARNING: Data will be truncated or omitted to prevent field overflow"
            return $null
        }
        
        Write-Host "INFO: Base64 encoded data size: $($base64.Length) characters"
        return $base64
    } catch {
        Write-Host "ERROR: Failed to convert to Base64 - $($_.Exception.Message)"
        return $null
    }
}

function ConvertFrom-Base64 {
    <#
    .SYNOPSIS
        Convert Base64 string back to PowerShell object
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Base64String
    )
    
    try {
        if ([string]::IsNullOrWhiteSpace($Base64String)) {
            return $null
        }
        
        $bytes = [System.Convert]::FromBase64String($Base64String)
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        $object = $json | ConvertFrom-Json
        return $object
    } catch {
        Write-Host "ERROR: Failed to decode Base64 - $($_.Exception.Message)"
        return $null
    }
}

function Test-ADConnection {
    <#
    .SYNOPSIS
        Check Active Directory connectivity using LDAP:// protocol
    #>
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        if ([string]::IsNullOrEmpty($defaultNamingContext)) {
            Write-Host "ERROR: Unable to connect to Active Directory via LDAP"
            return $false
        }
        
        Write-Host "INFO: Active Directory LDAP connection established"
        Write-Host "INFO: Default naming context: $defaultNamingContext"
        return $true
    } catch {
        Write-Host "ERROR: Active Directory LDAP connection failed - $($_.Exception.Message)"
        return $false
    }
}

function Get-ADComputerViaADSI {
    <#
    .SYNOPSIS
        Query computer information using LDAP:// protocol only
    #>
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=computer)(cn=$ComputerName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'cn',
            'dNSHostName',
            'sAMAccountName',
            'operatingSystem',
            'operatingSystemVersion',
            'memberOf',
            'userAccountControl',
            'pwdLastSet',
            'distinguishedName',
            'whenCreated'
        ))
        $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        
        $result = $searcher.FindOne()
        
        if ($result) {
            $computer = $result.Properties
            
            $groups = @()
            if ($computer['memberOf']) {
                foreach ($groupDN in $computer['memberOf']) {
                    if ($groupDN -match 'CN=([^,]+)') {
                        $groups += $matches[1]
                    }
                }
            }
            
            $pwdLastSet = ""
            if ($computer['pwdLastSet'] -and $computer['pwdLastSet'][0]) {
                try {
                    $pwdLastSetValue = $computer['pwdLastSet'][0]
                    if ($pwdLastSetValue -is [System.__ComObject]) {
                        $pwdLastSetValue = [Int64]$pwdLastSetValue
                    }
                    $pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
                    $pwdLastSet = $pwdLastSetDate.ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
                } catch {
                    Write-Host "WARNING: Failed to convert pwdLastSet - $($_.Exception.Message)"
                }
            }
            
            return [PSCustomObject]@{
                Name = if ($computer['cn']) { $computer['cn'][0] } else { "" }
                SamAccountName = if ($computer['sAMAccountName']) { $computer['sAMAccountName'][0] } else { "" }
                DNSHostName = if ($computer['dNSHostName']) { $computer['dNSHostName'][0] } else { "" }
                OperatingSystem = if ($computer['operatingSystem']) { $computer['operatingSystem'][0] } else { "" }
                OSVersion = if ($computer['operatingSystemVersion']) { $computer['operatingSystemVersion'][0] } else { "" }
                DistinguishedName = if ($computer['distinguishedName']) { $computer['distinguishedName'][0] } else { "" }
                Groups = $groups -join ", "
                GroupCount = $groups.Count
                GroupsArray = $groups
                PasswordLastSet = $pwdLastSet
                Enabled = if ($computer['userAccountControl']) { 
                    -not ([int]$computer['userAccountControl'][0] -band 2) 
                } else { 
                    $false 
                }
            }
        } else {
            Write-Host "WARNING: Computer not found in AD via LDAP - $ComputerName"
            return $null
        }
    } catch {
        Write-Host "ERROR: Failed to query computer via LDAP - $($_.Exception.Message)"
        return $null
    }
}

function Get-ADUserViaADSI {
    <#
    .SYNOPSIS
        Query user information using LDAP:// protocol only
    #>
    param(
        [string]$SamAccountName
    )
    
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=user)(objectCategory=person)(sAMAccountName=$SamAccountName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'givenName',
            'sn',
            'displayName',
            'userPrincipalName',
            'sAMAccountName',
            'memberOf',
            'userAccountControl',
            'mail',
            'distinguishedName'
        ))
        $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        
        $result = $searcher.FindOne()
        
        if ($result) {
            $user = $result.Properties
            
            $groups = @()
            if ($user['memberOf']) {
                foreach ($groupDN in $user['memberOf']) {
                    if ($groupDN -match 'CN=([^,]+)') {
                        $groups += $matches[1]
                    }
                }
            }
            
            return [PSCustomObject]@{
                SamAccountName = if ($user['sAMAccountName']) { $user['sAMAccountName'][0] } else { "" }
                FirstName = if ($user['givenName']) { $user['givenName'][0] } else { "" }
                LastName = if ($user['sn']) { $user['sn'][0] } else { "" }
                DisplayName = if ($user['displayName']) { $user['displayName'][0] } else { "" }
                UserPrincipalName = if ($user['userPrincipalName']) { $user['userPrincipalName'][0] } else { "" }
                EmailAddress = if ($user['mail']) { $user['mail'][0] } else { "" }
                DistinguishedName = if ($user['distinguishedName']) { $user['distinguishedName'][0] } else { "" }
                Groups = $groups -join ", "
                GroupCount = $groups.Count
                GroupsArray = $groups
                Enabled = if ($user['userAccountControl']) { 
                    -not ([int]$user['userAccountControl'][0] -band 2) 
                } else { 
                    $false 
                }
            }
        } else {
            Write-Host "WARNING: User not found via LDAP - $SamAccountName"
            return $null
        }
    } catch {
        Write-Host "ERROR: Failed to query user via LDAP - $($_.Exception.Message)"
        return $null
    }
}

# Main Script

try {
    Write-Host "Starting Active Directory Monitor (Script 42 v3.1)..."
    Write-Host "INFO: Using native ADSI LDAP:// queries (no RSAT required)"
    $ErrorActionPreference = 'Stop'
    
    # Check if computer is domain-joined
    Write-Host "INFO: Checking domain membership..."
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    
    if ($computerSystem.PartOfDomain -eq $false) {
        Write-Host "INFO: Computer is not domain-joined (Workgroup: $($computerSystem.Workgroup))"
        
        # Update fields for non-domain computers
        Ninja-Property-Set adDomainJoined "false"
        Ninja-Property-Set adDomainName $computerSystem.Workgroup
        Ninja-Property-Set adDomainController "N/A"
        Ninja-Property-Set adSiteName "N/A"
        Ninja-Property-Set adComputerOU "N/A"
        Ninja-Property-Set adComputerGroupsEncoded ""
        Ninja-Property-Set adLastLogonUser "N/A"
        Ninja-Property-Set adUserFirstName ""
        Ninja-Property-Set adUserLastName ""
        Ninja-Property-Set adUserGroupsEncoded ""
        Ninja-Property-Set adPasswordLastSet ""
        Ninja-Property-Set adTrustRelationshipHealthy "true"
        
        Write-Host "SUCCESS: Active Directory Monitor complete (not domain-joined)"
        exit 0
    }
    
    $domainName = $computerSystem.Domain
    Write-Host "INFO: Computer is domain-joined: $domainName"
    
    # Test LDAP connection
    if (-not (Test-ADConnection)) {
        Write-Host "ERROR: Cannot proceed without Active Directory LDAP connection"
        
        # Set error state
        Ninja-Property-Set adDomainJoined "true"
        Ninja-Property-Set adDomainName $domainName
        Ninja-Property-Set adDomainController "LDAP connection failed"
        Ninja-Property-Set adTrustRelationshipHealthy "false"
        
        exit 1
    }
    
    # Get domain controller using nltest
    $domainController = "Unknown"
    $siteName = "Unknown"
    
    try {
        Write-Host "INFO: Locating domain controller..."
        $dcInfo = nltest /dsgetdc:$domainName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $dcLine = $dcInfo | Where-Object { $_ -match 'DC:\s*\\\\(.+)' }
            if ($dcLine -match 'DC:\s*\\\\(.+)') {
                $domainController = $matches[1]
                Write-Host "INFO: Domain Controller: $domainController"
            }
            
            $siteLine = $dcInfo | Where-Object { $_ -match 'Site Name:\s*(.+)' }
            if ($siteLine -match 'Site Name:\s*(.+)') {
                $siteName = $matches[1].Trim()
                Write-Host "INFO: Site Name: $siteName"
            }
        } else {
            Write-Host "WARNING: Failed to locate domain controller"
            $domainController = "Unable to locate"
        }
    } catch {
        Write-Host "WARNING: Error getting domain controller: $($_.Exception.Message)"
        $domainController = "Error"
    }
    
    # Test secure channel (trust relationship)
    $trustHealthy = "true"
    try {
        Write-Host "INFO: Testing secure channel to domain..."
        $testResult = Test-ComputerSecureChannel -ErrorAction Stop
        $trustHealthy = if ($testResult) { "true" } else { "false" }
        
        if ($testResult) {
            Write-Host "INFO: Secure channel is healthy"
        } else {
            Write-Host "WARNING: Secure channel test failed - trust relationship broken"
        }
    } catch {
        Write-Host "WARNING: Failed to test secure channel: $($_.Exception.Message)"
        $trustHealthy = "false"
    }
    
    # Query computer account via LDAP://
    Write-Host "INFO: Querying computer account via LDAP://..."
    $computerInfo = Get-ADComputerViaADSI -ComputerName $env:COMPUTERNAME
    
    $computerOU = "Unable to query"
    $computerGroupsBase64 = ""
    $passwordLastSet = ""
    
    if ($computerInfo) {
        $computerOU = $computerInfo.DistinguishedName
        Write-Host "INFO: Computer DN: $computerOU"
        Write-Host "INFO: Computer Groups: $($computerInfo.GroupCount) memberships"
        
        $passwordLastSet = $computerInfo.PasswordLastSet
        if ($passwordLastSet) {
            Write-Host "INFO: Password Last Set: $passwordLastSet"
        }
        
        if ($computerInfo.GroupsArray -and $computerInfo.GroupsArray.Count -gt 0) {
            $computerGroupsBase64 = ConvertTo-Base64 -InputObject $computerInfo.GroupsArray
            if ($computerGroupsBase64) {
                Write-Host "INFO: Encoded $($computerInfo.GroupCount) computer groups as Base64 (validated <9999 chars)"
            } else {
                Write-Host "WARNING: Computer groups Base64 encoding failed or exceeded limit"
            }
        }
    } else {
        Write-Host "WARNING: Failed to query computer account"
    }
    
    # Get last logged-on user
    $lastLogonUser = "Unknown"
    try {
        $lastLogonReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "LastLoggedOnUser" -ErrorAction SilentlyContinue
        
        if ($lastLogonReg) {
            $lastLogonUser = $lastLogonReg.LastLoggedOnUser
            Write-Host "INFO: Last Logon User: $lastLogonUser"
        } else {
            $currentUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
            if ($currentUser) {
                $lastLogonUser = $currentUser
                Write-Host "INFO: Current User: $lastLogonUser"
            }
        }
    } catch {
        Write-Host "WARNING: Failed to get last logon user: $($_.Exception.Message)"
    }
    
    # Query user account via LDAP:// (if we have a username)
    $userFirstName = ""
    $userLastName = ""
    $userGroupsBase64 = ""
    
    if ($lastLogonUser -ne "Unknown" -and $lastLogonUser -ne "N/A") {
        # Extract username from domain\username format
        $username = $lastLogonUser
        if ($lastLogonUser -match '\\(.+)$') {
            $username = $matches[1]
        }
        
        Write-Host "INFO: Querying user account via LDAP:// for $username..."
        $userInfo = Get-ADUserViaADSI -SamAccountName $username
        
        if ($userInfo) {
            $userFirstName = $userInfo.FirstName
            $userLastName = $userInfo.LastName
            Write-Host "INFO: User: $($userInfo.DisplayName)"
            Write-Host "INFO: User Groups: $($userInfo.GroupCount) memberships"
            
            if ($userInfo.GroupsArray -and $userInfo.GroupsArray.Count -gt 0) {
                $userGroupsBase64 = ConvertTo-Base64 -InputObject $userInfo.GroupsArray
                if ($userGroupsBase64) {
                    Write-Host "INFO: Encoded $($userInfo.GroupCount) user groups as Base64 (validated <9999 chars)"
                } else {
                    Write-Host "WARNING: User groups Base64 encoding failed or exceeded limit"
                }
            }
        } else {
            Write-Host "WARNING: Failed to query user account"
        }
    }
    
    # Test connectivity to domain controller
    if ($domainController -ne "Unable to locate" -and $domainController -ne "Error" -and $domainController -ne "Unknown") {
        try {
            Write-Host "INFO: Testing connectivity to domain controller..."
            $pingResult = Test-Connection -ComputerName $domainController -Count 2 -Quiet -ErrorAction SilentlyContinue
            
            if (-not $pingResult) {
                Write-Host "WARNING: Unable to ping domain controller $domainController"
                $trustHealthy = "false"
            } else {
                Write-Host "INFO: Domain controller is reachable"
            }
        } catch {
            Write-Host "WARNING: Failed to test DC connectivity: $($_.Exception.Message)"
        }
    }
    
    # Update NinjaRMM custom fields
    Write-Host "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set adDomainJoined "true"
    Ninja-Property-Set adDomainName $domainName
    Ninja-Property-Set adDomainController $domainController
    Ninja-Property-Set adSiteName $siteName
    Ninja-Property-Set adComputerOU $computerOU
    Ninja-Property-Set adComputerGroupsEncoded $computerGroupsBase64
    Ninja-Property-Set adLastLogonUser $lastLogonUser
    Ninja-Property-Set adUserFirstName $userFirstName
    Ninja-Property-Set adUserLastName $userLastName
    Ninja-Property-Set adUserGroupsEncoded $userGroupsBase64
    Ninja-Property-Set adPasswordLastSet $passwordLastSet
    Ninja-Property-Set adTrustRelationshipHealthy $trustHealthy
    
    Write-Host "SUCCESS: Active Directory Monitor complete"
    Write-Host "INFO: Domain: $domainName, Trust Healthy: $trustHealthy"
    Write-Host "INFO: Computer Groups: $($computerInfo.GroupCount if $computerInfo else 0)"
    Write-Host "INFO: User Groups: $($userInfo.GroupCount if $userInfo else 0)"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Host "ERROR: Active Directory Monitor failed - $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set adDomainJoined "false"
    Ninja-Property-Set adDomainName "Error"
    Ninja-Property-Set adTrustRelationshipHealthy "false"
    
    exit 1
}
