#Requires -Version 5.1

<#
.SYNOPSIS
    Monitors local administrator group membership and alerts on unexpected accounts.

.DESCRIPTION
    This script queries the local Administrators group and reports all members. It can optionally 
    alert when non-whitelisted accounts are found in the group. This helps detect unauthorized 
    privilege escalation and ensures only approved accounts have administrative access.
    
    The script reports:
    - All local administrator accounts (always)
    - Domain accounts with local admin rights
    - Built-in administrator account status
    - Optional alerting for non-whitelisted accounts
    
    This is critical for security compliance and preventing unauthorized access.

.PARAMETER WhitelistedAccounts
    Comma-separated list of accounts that are approved to be local administrators. 
    If specified, alerts will be raised for any accounts not in this list.
    Format: "DOMAIN\User1,DOMAIN\User2,Administrator"

.PARAMETER SaveToCustomField
    Name of a custom field to save the administrator list.

.PARAMETER AlertOnUnauthorized
    If specified, script will exit with error code when non-whitelisted accounts are found.
    Only applies when WhitelistedAccounts is also specified.

.EXAMPLE
    No Parameters

    [Info] Monitoring local Administrators group...
    [Info] Found 3 administrator account(s):
    Administrator (Local)
    CONTOSO\Domain Admins (Domain Group)
    CONTOSO\jsmith (Domain User)

.EXAMPLE
    -WhitelistedAccounts "Administrator,CONTOSO\Domain Admins" -AlertOnUnauthorized

    [Info] Monitoring local Administrators group...
    [Info] Found 3 administrator account(s):
    Administrator (Local) - Whitelisted
    CONTOSO\Domain Admins (Domain Group) - Whitelisted
    CONTOSO\jsmith (Domain User) - UNAUTHORIZED
    [Alert] Found 1 unauthorized administrator account(s)

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: v3.0.0 - Upgraded to V3.0.0 standards (script-scoped exit code)
    
.COMPONENT
    ADSI - Active Directory Service Interfaces
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Queries local Administrators group membership
    - Reports ALL administrator accounts (always)
    - Identifies account types (local, domain user, domain group)
    - Optional whitelist verification
    - Alerts on unauthorized accounts when configured
    - Can save administrator list to custom fields
    - Security compliance monitoring
#>

[CmdletBinding()]
param(
    [string]$WhitelistedAccounts,
    [string]$SaveToCustomField,
    [switch]$AlertOnUnauthorized
)

begin {
    if ($env:whitelistedAccounts -and $env:whitelistedAccounts -notlike "null") {
        $WhitelistedAccounts = $env:whitelistedAccounts
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }
    if ($env:alertOnUnauthorized -eq "true") {
        $AlertOnUnauthorized = $true
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        $NinjaValue = $Value
        $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $script:ExitCode = 0
    $WhitelistArray = @()
    
    if ($WhitelistedAccounts) {
        $WhitelistArray = $WhitelistedAccounts -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
}

process {
    try {
        Write-Host "[Info] Monitoring local Administrators group..."
        
        $AdminGroup = [ADSI]"WinNT://./Administrators,group"
        $Members = $AdminGroup.PSBase.Invoke("Members")
        
        $AdminList = @()
        $UnauthorizedCount = 0
        $Report = @()

        foreach ($Member in $Members) {
            $MemberPath = $Member.GetType().InvokeMember("ADsPath", 'GetProperty', $null, $Member, $null)
            $MemberName = $Member.GetType().InvokeMember("Name", 'GetProperty', $null, $Member, $null)
            
            $AccountType = "Local"
            $FullName = $MemberName
            
            if ($MemberPath -match "WinNT://([^/]+)/([^/]+)/(.+)") {
                $Domain = $Matches[1]
                $FullName = "$Domain\$MemberName"
                $AccountType = "Domain User"
            } elseif ($MemberPath -match "WinNT://([^/]+)/(.+)") {
                if ($Matches[1] -ne $env:COMPUTERNAME) {
                    $Domain = $Matches[1]
                    $FullName = "$Domain\$MemberName"
                    $AccountType = "Domain User"
                }
            }
            
            try {
                $MemberClass = $Member.GetType().InvokeMember("Class", 'GetProperty', $null, $Member, $null)
                if ($MemberClass -eq "Group") {
                    if ($AccountType -eq "Domain User") {
                        $AccountType = "Domain Group"
                    } else {
                        $AccountType = "Local Group"
                    }
                }
            } catch {
            }
            
            $IsWhitelisted = $false
            if ($WhitelistArray.Count -gt 0) {
                $IsWhitelisted = $WhitelistArray -contains $FullName -or $WhitelistArray -contains $MemberName
            }
            
            $Status = ""
            if ($WhitelistArray.Count -gt 0) {
                if ($IsWhitelisted) {
                    $Status = " - Whitelisted"
                } else {
                    $Status = " - UNAUTHORIZED"
                    $UnauthorizedCount++
                }
            }
            
            $AdminEntry = "$FullName ($AccountType)$Status"
            $AdminList += $AdminEntry
            $Report += $FullName
        }

        Write-Host "[Info] Found $($AdminList.Count) administrator account(s):"
        foreach ($Admin in $AdminList) {
            Write-Host $Admin
        }

        if ($WhitelistArray.Count -gt 0 -and $UnauthorizedCount -gt 0) {
            Write-Host "[Alert] Found $UnauthorizedCount unauthorized administrator account(s)"
            if ($AlertOnUnauthorized) {
                $script:ExitCode = 1
            }
        } elseif ($WhitelistArray.Count -gt 0 -and $UnauthorizedCount -eq 0) {
            Write-Host "[Info] All administrator accounts are whitelisted"
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            } catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $script:ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to monitor local administrators: $_"
        $script:ExitCode = 1
    }

    exit $script:ExitCode
}

end {
}
