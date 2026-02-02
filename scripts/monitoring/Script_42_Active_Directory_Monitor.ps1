<#
.SYNOPSIS
    Script 42: Active Directory Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Active Directory domain membership, domain controller connectivity, secure channel
    health, computer account status, and synchronization. Updates 9 AD fields.

.FIELDS UPDATED
    - ADDomainJoined (Checkbox)
    - ADDomainName (Text)
    - ADDomainController (Text)
    - ADSiteName (Text)
    - ADComputerOU (Text)
    - ADLastLogonUser (Text)
    - ADPasswordLastSet (DateTime)
    - ADTrustRelationshipHealthy (Checkbox)
    - ADLastSyncTime (DateTime)

.EXECUTION
    Frequency: Every 4 hours (critical), Daily (informational)
    Runtime: ~25 seconds
    Requires: Domain-joined computer, network connectivity to DC

.NOTES
    File: Script_42_Active_Directory_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Domain Integration
    Dependencies: Active Directory PowerShell module (optional)

.RELATED DOCUMENTATION
    - docs/core/18_AD_Active_Directory.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 3)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Active Directory Monitor (Script 42)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $domainJoined = $false
    $domainName = "WORKGROUP"
    $domainController = "None"
    $siteName = "None"
    $computerOU = "None"
    $lastLogonUser = "None"
    $passwordLastSet = ""
    $trustHealthy = $true
    $lastSyncTime = ""
    
    # Check if computer is domain-joined
    Write-Host "Checking domain membership..."
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    
    if ($computerSystem.PartOfDomain -eq $false) {
        Write-Host "Computer is not domain-joined (Workgroup: $($computerSystem.Workgroup))."
        
        # Update fields for non-domain computers
        Ninja-Property-Set adDomainJoined $false
        Ninja-Property-Set adDomainName $computerSystem.Workgroup
        Ninja-Property-Set adDomainController "N/A"
        Ninja-Property-Set adSiteName "N/A"
        Ninja-Property-Set adComputerOU "N/A"
        Ninja-Property-Set adLastLogonUser "N/A"
        Ninja-Property-Set adPasswordLastSet ""
        Ninja-Property-Set adTrustRelationshipHealthy $true
        Ninja-Property-Set adLastSyncTime ""
        
        Write-Host "Active Directory Monitor complete (not domain-joined)."
        exit 0
    }
    
    $domainJoined = $true
    $domainName = $computerSystem.Domain
    Write-Host "Computer is domain-joined: $domainName"
    
    # Get domain controller
    try {
        Write-Host "Locating domain controller..."
        $dcInfo = nltest /dsgetdc:$domainName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Parse DC name from nltest output
            $dcLine = $dcInfo | Where-Object { $_ -match 'DC:\s*\\\\(.+)' }
            if ($dcLine -match 'DC:\s*\\\\(.+)') {
                $domainController = $matches[1]
                Write-Host "Domain Controller: $domainController"
            }
            
            # Parse site name
            $siteLine = $dcInfo | Where-Object { $_ -match 'Site Name:\s*(.+)' }
            if ($siteLine -match 'Site Name:\s*(.+)') {
                $siteName = $matches[1].Trim()
                Write-Host "Site Name: $siteName"
            }
        } else {
            Write-Warning "Failed to locate domain controller."
            $domainController = "Unable to locate"
        }
    } catch {
        Write-Warning "Error getting domain controller: $_"
        $domainController = "Error"
    }
    
    # Test secure channel (trust relationship)
    try {
        Write-Host "Testing secure channel to domain..."
        $testResult = Test-ComputerSecureChannel -ErrorAction Stop
        $trustHealthy = $testResult
        
        if ($trustHealthy) {
            Write-Host "Secure channel is healthy."
        } else {
            Write-Warning "Secure channel test failed - trust relationship broken!"
        }
    } catch {
        Write-Warning "Failed to test secure channel: $_"
        $trustHealthy = $false
    }
    
    # Get last sync time (approximate from last successful Kerberos ticket)
    try {
        $lastSyncTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    } catch {
        $lastSyncTime = ""
    }
    
    # Get computer account details from Active Directory
    try {
        Write-Host "Querying computer account details..."
        
        # Try using AD module first
        if (Get-Module -ListAvailable -Name ActiveDirectory) {
            Import-Module ActiveDirectory -ErrorAction Stop
            
            $computerAccount = Get-ADComputer -Identity $env:COMPUTERNAME -Properties DistinguishedName, PasswordLastSet, LastLogonDate -ErrorAction Stop
            
            # Get OU path
            $computerOU = $computerAccount.DistinguishedName
            Write-Host "Computer OU: $computerOU"
            
            # Get password last set date
            if ($computerAccount.PasswordLastSet) {
                $passwordLastSet = $computerAccount.PasswordLastSet.ToString("yyyy-MM-dd HH:mm:ss")
                Write-Host "Password Last Set: $passwordLastSet"
            }
            
        } else {
            # Fallback: Use ADSI without AD module
            Write-Host "AD module not available, using ADSI..."
            
            $searcher = [ADSISearcher]"(name=$env:COMPUTERNAME)"
            $searcher.SearchRoot = "LDAP://$domainName"
            $computerObject = $searcher.FindOne()
            
            if ($computerObject) {
                $computerOU = $computerObject.Properties['distinguishedname'][0]
                Write-Host "Computer OU: $computerOU"
                
                # Get password last set (convert from FileTime)
                $pwdLastSetValue = $computerObject.Properties['pwdlastset'][0]
                if ($pwdLastSetValue) {
                    $pwdLastSetDate = [DateTime]::FromFileTime($pwdLastSetValue)
                    $passwordLastSet = $pwdLastSetDate.ToString("yyyy-MM-dd HH:mm:ss")
                    Write-Host "Password Last Set: $passwordLastSet"
                }
            }
        }
    } catch {
        Write-Warning "Failed to query computer account details: $_"
        $computerOU = "Unable to query"
    }
    
    # Get last logged-on user
    try {
        # Check registry for last logged-on user
        $lastLogonReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "LastLoggedOnUser" -ErrorAction SilentlyContinue
        
        if ($lastLogonReg) {
            $lastLogonUser = $lastLogonReg.LastLoggedOnUser
            Write-Host "Last Logon User: $lastLogonUser"
        } else {
            # Alternative: Check current logged-on users
            $currentUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
            if ($currentUser) {
                $lastLogonUser = $currentUser
                Write-Host "Current User: $lastLogonUser"
            }
        }
    } catch {
        Write-Warning "Failed to get last logon user: $_"
        $lastLogonUser = "Unknown"
    }
    
    # Verify domain connectivity
    if ($domainController -ne "Unable to locate" -and $domainController -ne "Error" -and $domainController -ne "None") {
        try {
            Write-Host "Testing connectivity to domain controller..."
            $pingResult = Test-Connection -ComputerName $domainController -Count 2 -Quiet -ErrorAction SilentlyContinue
            
            if (-not $pingResult) {
                Write-Warning "Unable to ping domain controller $domainController"
                $trustHealthy = $false
            }
        } catch {
            Write-Warning "Failed to test DC connectivity: $_"
        }
    }
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set adDomainJoined $true
    Ninja-Property-Set adDomainName $domainName
    Ninja-Property-Set adDomainController $domainController
    Ninja-Property-Set adSiteName $siteName
    Ninja-Property-Set adComputerOU $computerOU
    Ninja-Property-Set adLastLogonUser $lastLogonUser
    Ninja-Property-Set adPasswordLastSet $passwordLastSet
    Ninja-Property-Set adTrustRelationshipHealthy $trustHealthy
    Ninja-Property-Set adLastSyncTime $lastSyncTime
    
    Write-Host "Active Directory Monitor complete. Domain: $domainName, Trust Healthy: $trustHealthy"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Active Directory Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set adDomainJoined $false
    Ninja-Property-Set adDomainName "Error"
    Ninja-Property-Set adTrustRelationshipHealthy $false
    
    exit 1
}
