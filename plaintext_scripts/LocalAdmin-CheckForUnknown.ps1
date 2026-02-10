#Requires -Version 5.1

<#
.SYNOPSIS
    Detects unknown or unexpected local administrator accounts on the system.

.DESCRIPTION
    This script queries the local Administrators group and compares the member list against an
    expected whitelist of known administrator accounts. Any accounts not on the whitelist are
    flagged as unknown administrators, which could indicate unauthorized access or security risks.
    
    Monitoring local administrator accounts is critical for security compliance and detecting
    potential security breaches or unauthorized privilege escalation.

.PARAMETER ExpectedAdmins
    Comma-separated list of expected administrator account names (e.g., "Administrator,AdminUser").
    Accounts not in this list will be flagged as unknown.

.PARAMETER IncludeDomainAdmins
    If specified, also checks for domain administrator groups. Default: False

.PARAMETER SaveToCustomField
    Name of a custom field to save the list of unknown administrators.

.EXAMPLE
    -ExpectedAdmins "Administrator,IT_Admin"

    [Info] Checking for unknown local administrators...
    [Info] Expected admins: Administrator, IT_Admin
    [Alert] Unknown administrator found: UnknownUser
    [Alert] 1 unknown administrator(s) detected

.EXAMPLE
    -ExpectedAdmins "Administrator" -SaveToCustomField "UnknownAdmins"

    [Info] Checking for unknown local administrators...
    [Info] All administrators are recognized
    [Info] Results saved to custom field 'UnknownAdmins'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: v3.0.0 - Upgraded to V3.0.0 standards (script-scoped exit code)
    
.COMPONENT
    ADSI - Active Directory Service Interfaces for local group queries
    
.LINK
    https://learn.microsoft.com/en-us/windows/win32/adsi/

.FUNCTIONALITY
    - Queries local Administrators group membership
    - Compares members against expected whitelist
    - Identifies unknown or unauthorized administrator accounts
    - Reports account names and sources (local/domain)
    - Can save results to custom fields for monitoring
    - Exits with error code if unknown admins detected
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ExpectedAdmins,
    
    [switch]$IncludeDomainAdmins = $false,
    
    [string]$SaveToCustomField
)

begin {
    if ($env:expectedAdmins -and $env:expectedAdmins -notlike "null") {
        $ExpectedAdmins = $env:expectedAdmins
    }
    if ($env:includeDomainAdmins -eq "true") {
        $IncludeDomainAdmins = $true
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
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
}

process {
    try {
        Write-Host "[Info] Checking for unknown local administrators..."
        
        $ExpectedList = $ExpectedAdmins -split ',' | ForEach-Object { $_.Trim() }
        Write-Host "[Info] Expected admins: $($ExpectedList -join ', ')"
        
        $AdminGroup = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
        $Members = $AdminGroup.Invoke("Members") | ForEach-Object {
            $Path = ([ADSI]$_).Path
            $Username = $Path.Split('/')[-1]
            [PSCustomObject]@{
                Name = $Username
                Path = $Path
            }
        }

        $UnknownAdmins = @()
        
        foreach ($Member in $Members) {
            $IsDomainAccount = $Member.Path -match "/[^/]+/[^/]+/"
            
            if (-not $IncludeDomainAdmins -and $IsDomainAccount) {
                continue
            }
            
            if ($ExpectedList -notcontains $Member.Name) {
                Write-Host "[Alert] Unknown administrator found: $($Member.Name)"
                $UnknownAdmins += $Member.Name
                $script:ExitCode = 1
            }
        }

        if ($UnknownAdmins.Count -eq 0) {
            Write-Host "[Info] All administrators are recognized"
        } else {
            Write-Host "[Alert] $($UnknownAdmins.Count) unknown administrator(s) detected"
        }

        if ($SaveToCustomField) {
            try {
                $Result = if ($UnknownAdmins.Count -gt 0) {
                    $UnknownAdmins -join ", "
                } else {
                    "None"
                }
                $Result | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $script:ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to check administrators: $_"
        $script:ExitCode = 1
    }

    exit $script:ExitCode
}

end {
}
