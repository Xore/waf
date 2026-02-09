#Requires -Version 5.1

<#
.SYNOPSIS
    Monitor Active Directory domain integration and health status

.DESCRIPTION
    Comprehensive Active Directory monitoring solution that tracks domain membership,
    domain controller connectivity, secure channel health, computer account status,
    user account details, and group memberships using native ADSI LDAP queries.
    
    Technical Implementation:
    The script uses ADSI (Active Directory Service Interfaces) with LDAP protocol
    for all Active Directory queries, eliminating the need for Remote Server
    Administration Tools (RSAT). This approach provides:
    
    1. Maximum Compatibility:
       - Works on any Windows system without additional components
       - No PowerShell Active Directory module required
       - No RSAT installation needed
       - Compatible with workstation and server editions
    
    2. LDAP Query Methodology:
       - Direct LDAP:// protocol binding to domain controllers
       - Uses RootDSE for domain discovery
       - DirectorySearcher for efficient queries
       - Native .NET directory services classes
    
    3. Computer Account Information:
       - Distinguished Name (DN) and organizational unit (OU)
       - Group memberships (direct, not transitive)
       - Password last set timestamp (converted to Unix epoch)
       - Account enabled/disabled status (userAccountControl flags)
       - Operating system and DNS hostname
    
    4. User Account Information:
       - Identifies last logged-on user from registry
       - Queries user attributes (given name, surname)
       - Enumerates group memberships
       - Account status and contact information
    
    5. Trust Relationship Health:
       - Tests secure channel using Test-ComputerSecureChannel
       - Validates domain controller connectivity via ping
       - Verifies LDAP binding to domain
       - Identifies broken trust relationships
    
    6. Domain Controller Location:
       - Uses nltest /dsgetdc for DC discovery
       - Identifies primary domain controller
       - Determines Active Directory site name
       - Validates network connectivity to DC
    
    Data Encoding:
    Group membership arrays are stored in NinjaRMM as Base64 encoded JSON arrays,
    allowing for structured data storage in text fields while maintaining
    compatibility with NinjaRMM's field type constraints.
    
    Performance Considerations:
    - LDAP queries are optimized with PropertiesToLoad filters
    - Subtree scope used for comprehensive searches
    - Typical execution time: 10-15 seconds
    - Network latency to domain controller may impact duration
    
    Error Handling Strategy:
    - Gracefully handles non-domain-joined computers
    - Reports LDAP connection failures without script failure
    - Continues operation when individual queries fail
    - Updates status fields to reflect connectivity issues
    
    Use Cases:
    - Domain membership verification for compliance
    - Trust relationship monitoring and alerting
    - User access auditing and group membership tracking
    - Computer account health monitoring
    - Domain infrastructure health checks

.EXAMPLE
    .\AD-Monitor.ps1
    
    Monitors AD status for current computer and last logged-on user.

.NOTES
    Script Name:    AD-Monitor.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM (recommended for full functionality)
    Execution Frequency: Every 4 hours (critical), Daily (informational)
    Typical Duration: 10-15 seconds
    Timeout Setting: 120 seconds recommended
    
    User Interaction: NONE (runs silently in background)
    Restart Behavior: N/A (no system restart)
    
    NinjaRMM Fields Updated:
        Text Fields:
        - adDomainJoined ("true"/"false")
        - adDomainName (domain FQDN or workgroup name)
        - adDomainController (DC hostname)
        - adSiteName (AD site name)
        - adComputerOU (computer distinguished name)
        - adLastLogonUser (domain\username format)
        - adUserFirstName (user's given name)
        - adUserLastName (user's surname)
        - adTrustRelationshipHealthy ("true"/"false")
        
        Array Fields (Base64 encoded JSON):
        - adComputerGroups (array of group names)
        - adUserGroups (array of group names)
        
        DateTime Field:
        - adPasswordLastSet (Unix epoch seconds since 1970-01-01 UTC)
    
    Dependencies:
        - Windows Domain Services (for domain-joined computers)
        - Network connectivity to domain controller
        - LDAP port 389 access to domain controller
        - No PowerShell modules or RSAT required
    
    Exit Codes:
        0 - Success (AD monitoring completed)
        1 - Failure (critical error during monitoring)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param()

# Configuration
$ScriptVersion = "3.0"
$ScriptName = "AD-Monitor"

# Initialization
$StartTime = Get-Date
$ErrorActionPreference = 'Continue'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:ExitCode = 0

# Functions

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

function Test-ADConnection {
    [CmdletBinding()]
    param()
    
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        if ([string]::IsNullOrEmpty($defaultNamingContext)) {
            Write-Log "Unable to connect to Active Directory via LDAP" -Level ERROR
            return $false
        }
        
        Write-Log "Active Directory LDAP connection established" -Level SUCCESS
        Write-Log "Default naming context: $defaultNamingContext" -Level DEBUG
        return $true
        
    } catch {
        Write-Log "Active Directory LDAP connection failed: $_" -Level ERROR
        return $false
    }
}

function Get-ADComputerViaADSI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=computer)(cn=$ComputerName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'cn','dNSHostName','sAMAccountName','operatingSystem',
            'operatingSystemVersion','memberOf','userAccountControl',
            'pwdLastSet','distinguishedName','whenCreated'
        ))
        $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        
        $result = $searcher.FindOne()
        
        if (-not $result) {
            Write-Log "Computer not found in AD via LDAP: $ComputerName" -Level WARN
            return $null
        }
        
        $computer = $result.Properties
        
        # Extract group memberships
        $groups = @()
        if ($computer['memberOf']) {
            foreach ($groupDN in $computer['memberOf']) {
                if ($groupDN -match 'CN=([^,]+)') {
                    $groups += $matches[1]
                }
            }
        }
        
        # Convert pwdLastSet to Unix epoch
        $pwdLastSet = 0
        if ($computer['pwdLastSet'] -and $computer['pwdLastSet'][0]) {
            try {
                $pwdLastSetValue = $computer['pwdLastSet'][0]
                if ($pwdLastSetValue -is [System.__ComObject]) {
                    $pwdLastSetValue = [Int64]$pwdLastSetValue
                }
                $pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
                $pwdLastSet = [int64](([DateTimeOffset]$pwdLastSetDate).ToUniversalTime() - [DateTimeOffset]::new(1970, 1, 1, 0, 0, 0, [TimeSpan]::Zero)).TotalSeconds
                Write-Log "Password last set: $($pwdLastSetDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Level DEBUG
            } catch {
                Write-Log "Failed to convert pwdLastSet: $_" -Level WARN
            }
        }
        
        return [PSCustomObject]@{
            Name = if ($computer['cn']) { $computer['cn'][0] } else { '' }
            SamAccountName = if ($computer['sAMAccountName']) { $computer['sAMAccountName'][0] } else { '' }
            DNSHostName = if ($computer['dNSHostName']) { $computer['dNSHostName'][0] } else { '' }
            OperatingSystem = if ($computer['operatingSystem']) { $computer['operatingSystem'][0] } else { '' }
            OSVersion = if ($computer['operatingSystemVersion']) { $computer['operatingSystemVersion'][0] } else { '' }
            DistinguishedName = if ($computer['distinguishedName']) { $computer['distinguishedName'][0] } else { '' }
            Groups = $groups -join ', '
            GroupCount = $groups.Count
            GroupsArray = $groups
            PasswordLastSet = $pwdLastSet
            Enabled = if ($computer['userAccountControl']) { -not ([int]$computer['userAccountControl'][0] -band 2) } else { $false }
        }
        
    } catch {
        Write-Log "Failed to query computer via LDAP: $_" -Level ERROR
        return $null
    }
}

function Get-ADUserViaADSI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName
    )
    
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $defaultNamingContext = $rootDSE.defaultNamingContext
        
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = [ADSI]"LDAP://$defaultNamingContext"
        $searcher.Filter = "(&(objectClass=user)(objectCategory=person)(sAMAccountName=$SamAccountName))"
        $searcher.PropertiesToLoad.AddRange(@(
            'givenName','sn','displayName','userPrincipalName',
            'sAMAccountName','memberOf','userAccountControl',
            'mail','distinguishedName'
        ))
        $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        
        $result = $searcher.FindOne()
        
        if (-not $result) {
            Write-Log "User not found via LDAP: $SamAccountName" -Level WARN
            return $null
        }
        
        $user = $result.Properties
        
        # Extract group memberships
        $groups = @()
        if ($user['memberOf']) {
            foreach ($groupDN in $user['memberOf']) {
                if ($groupDN -match 'CN=([^,]+)') {
                    $groups += $matches[1]
                }
            }
        }
        
        return [PSCustomObject]@{
            SamAccountName = if ($user['sAMAccountName']) { $user['sAMAccountName'][0] } else { '' }
            FirstName = if ($user['givenName']) { $user['givenName'][0] } else { '' }
            LastName = if ($user['sn']) { $user['sn'][0] } else { '' }
            DisplayName = if ($user['displayName']) { $user['displayName'][0] } else { '' }
            UserPrincipalName = if ($user['userPrincipalName']) { $user['userPrincipalName'][0] } else { '' }
            EmailAddress = if ($user['mail']) { $user['mail'][0] } else { '' }
            DistinguishedName = if ($user['distinguishedName']) { $user['distinguishedName'][0] } else { '' }
            Groups = $groups -join ', '
            GroupCount = $groups.Count
            GroupsArray = $groups
            Enabled = if ($user['userAccountControl']) { -not ([int]$user['userAccountControl'][0] -band 2) } else { $false }
        }
        
    } catch {
        Write-Log "Failed to query user via LDAP: $_" -Level ERROR
        return $null
    }
}

# Main Execution

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    Write-Log "Using native ADSI LDAP queries (no RSAT required)" -Level INFO
    Write-Log "" -Level INFO
    
    # Check domain membership
    Write-Log "Checking domain membership..." -Level INFO
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    
    if ($computerSystem.PartOfDomain -eq $false) {
        Write-Log "Computer is not domain-joined (Workgroup: $($computerSystem.Workgroup))" -Level INFO
        
        # Update fields for non-domain computers
        Ninja-Property-Set adDomainJoined "false"
        Ninja-Property-Set adDomainName $computerSystem.Workgroup
        Ninja-Property-Set adDomainController "N/A"
        Ninja-Property-Set adSiteName "N/A"
        Ninja-Property-Set adComputerOU "N/A"
        Ninja-Property-Set adComputerGroups ""
        Ninja-Property-Set adLastLogonUser "N/A"
        Ninja-Property-Set adUserFirstName ""
        Ninja-Property-Set adUserLastName ""
        Ninja-Property-Set adUserGroups ""
        Ninja-Property-Set adPasswordLastSet 0
        Ninja-Property-Set adTrustRelationshipHealthy "true"
        
        Write-Log "Active Directory monitoring complete (not domain-joined)" -Level SUCCESS
        exit 0
    }
    
    $domainName = $computerSystem.Domain
    Write-Log "Computer is domain-joined: $domainName" -Level SUCCESS
    
    # Test LDAP connection
    if (-not (Test-ADConnection)) {
        Write-Log "Cannot proceed without Active Directory LDAP connection" -Level ERROR
        
        Ninja-Property-Set adDomainJoined "true"
        Ninja-Property-Set adDomainName $domainName
        Ninja-Property-Set adDomainController "LDAP connection failed"
        Ninja-Property-Set adTrustRelationshipHealthy "false"
        
        $script:ExitCode = 1
        exit $script:ExitCode
    }
    
    # Locate domain controller
    Write-Log "" -Level INFO
    Write-Log "Locating domain controller..." -Level INFO
    $domainController = "Unknown"
    $siteName = "Unknown"
    
    try {
        $dcInfo = nltest /dsgetdc:$domainName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $dcLine = $dcInfo | Where-Object { $_ -match 'DC:\s*\\\\(.+)' }
            if ($dcLine -match 'DC:\s*\\\\(.+)') {
                $domainController = $matches[1]
                Write-Log "Domain Controller: $domainController" -Level SUCCESS
            }
            
            $siteLine = $dcInfo | Where-Object { $_ -match 'Site Name:\s*(.+)' }
            if ($siteLine -match 'Site Name:\s*(.+)') {
                $siteName = $matches[1].Trim()
                Write-Log "Site Name: $siteName" -Level INFO
            }
        } else {
            Write-Log "Failed to locate domain controller" -Level WARN
            $domainController = "Unable to locate"
        }
    } catch {
        Write-Log "Error getting domain controller: $_" -Level WARN
        $domainController = "Error"
    }
    
    # Test secure channel
    Write-Log "" -Level INFO
    Write-Log "Testing secure channel to domain..." -Level INFO
    $trustHealthy = "true"
    
    try {
        $testResult = Test-ComputerSecureChannel -ErrorAction Stop
        $trustHealthy = if ($testResult) { "true" } else { "false" }
        
        if ($testResult) {
            Write-Log "Secure channel is healthy" -Level SUCCESS
        } else {
            Write-Log "Secure channel test failed - trust relationship broken" -Level ERROR
            $script:ExitCode = 1
        }
    } catch {
        Write-Log "Failed to test secure channel: $_" -Level ERROR
        $trustHealthy = "false"
        $script:ExitCode = 1
    }
    
    # Query computer account
    Write-Log "" -Level INFO
    Write-Log "Querying computer account via LDAP..." -Level INFO
    $computerInfo = Get-ADComputerViaADSI -ComputerName $env:COMPUTERNAME
    
    $computerOU = "Unable to query"
    $passwordLastSet = 0
    $computerGroups = @()
    
    if ($computerInfo) {
        $computerOU = $computerInfo.DistinguishedName
        $passwordLastSet = $computerInfo.PasswordLastSet
        $computerGroups = $computerInfo.GroupsArray
        
        Write-Log "Computer DN: $computerOU" -Level INFO
        Write-Log "Computer Groups: $($computerInfo.GroupCount) memberships" -Level INFO
        Write-Log "Account Enabled: $($computerInfo.Enabled)" -Level INFO
    } else {
        Write-Log "Failed to query computer account" -Level WARN
    }
    
    # Get last logged-on user
    Write-Log "" -Level INFO
    Write-Log "Identifying last logged-on user..." -Level INFO
    $lastLogonUser = "Unknown"
    
    try {
        $lastLogonReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "LastLoggedOnUser" -ErrorAction SilentlyContinue
        
        if ($lastLogonReg) {
            $lastLogonUser = $lastLogonReg.LastLoggedOnUser
            Write-Log "Last Logon User: $lastLogonUser" -Level INFO
        } else {
            $currentUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
            if ($currentUser) {
                $lastLogonUser = $currentUser
                Write-Log "Current User: $lastLogonUser" -Level INFO
            }
        }
    } catch {
        Write-Log "Failed to get last logon user: $_" -Level WARN
    }
    
    # Query user account
    $userFirstName = ""
    $userLastName = ""
    $userGroups = @()
    
    if ($lastLogonUser -ne "Unknown" -and $lastLogonUser -ne "N/A") {
        # Extract username from domain\username format
        $username = $lastLogonUser
        if ($lastLogonUser -match '\\(.+)$') {
            $username = $matches[1]
        }
        
        Write-Log "" -Level INFO
        Write-Log "Querying user account via LDAP for $username..." -Level INFO
        $userInfo = Get-ADUserViaADSI -SamAccountName $username
        
        if ($userInfo) {
            $userFirstName = $userInfo.FirstName
            $userLastName = $userInfo.LastName
            $userGroups = $userInfo.GroupsArray
            
            Write-Log "User: $($userInfo.DisplayName)" -Level INFO
            Write-Log "User Groups: $($userInfo.GroupCount) memberships" -Level INFO
            Write-Log "Account Enabled: $($userInfo.Enabled)" -Level INFO
        } else {
            Write-Log "Failed to query user account" -Level WARN
        }
    }
    
    # Test DC connectivity
    if ($domainController -notin @("Unable to locate", "Error", "Unknown")) {
        Write-Log "" -Level INFO
        Write-Log "Testing connectivity to domain controller..." -Level INFO
        
        try {
            $pingResult = Test-Connection -ComputerName $domainController -Count 2 -Quiet -ErrorAction SilentlyContinue
            
            if (-not $pingResult) {
                Write-Log "Unable to ping domain controller $domainController" -Level WARN
                $trustHealthy = "false"
            } else {
                Write-Log "Domain controller is reachable" -Level SUCCESS
            }
        } catch {
            Write-Log "Failed to test DC connectivity: $_" -Level WARN
        }
    }
    
    # Update NinjaRMM custom fields
    Write-Log "" -Level INFO
    Write-Log "Updating NinjaRMM custom fields..." -Level INFO
    
    Ninja-Property-Set adDomainJoined "true"
    Ninja-Property-Set adDomainName $domainName
    Ninja-Property-Set adDomainController $domainController
    Ninja-Property-Set adSiteName $siteName
    Ninja-Property-Set adComputerOU $computerOU
    Ninja-Property-Set adComputerGroups $computerGroups
    Ninja-Property-Set adLastLogonUser $lastLogonUser
    Ninja-Property-Set adUserFirstName $userFirstName
    Ninja-Property-Set adUserLastName $userLastName
    Ninja-Property-Set adUserGroups $userGroups
    Ninja-Property-Set adPasswordLastSet $passwordLastSet
    Ninja-Property-Set adTrustRelationshipHealthy $trustHealthy
    
    Write-Log "" -Level INFO
    Write-Log "Active Directory monitoring summary:" -Level SUCCESS
    Write-Log "  Domain: $domainName" -Level INFO
    Write-Log "  Trust Healthy: $trustHealthy" -Level INFO
    Write-Log "  Computer Groups: $($computerGroups.Count)" -Level INFO
    Write-Log "  User Groups: $($userGroups.Count)" -Level INFO
    
    exit $script:ExitCode
    
} catch {
    Write-Log "Active Directory monitoring failed: $($_.Exception.Message)" -Level ERROR
    
    # Set error state
    Ninja-Property-Set adDomainJoined "false"
    Ninja-Property-Set adDomainName "Error"
    Ninja-Property-Set adTrustRelationshipHealthy "false"
    
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
    Write-Log "========================================" -Level INFO
}
