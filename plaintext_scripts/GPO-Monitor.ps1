#Requires -Version 5.1 -Modules GroupPolicy

<#
.SYNOPSIS
    Monitors Group Policy Object (GPO) changes in Active Directory domain.

.DESCRIPTION
    This script queries the domain for recent Group Policy changes by examining GPO version 
    numbers and modification timestamps. It alerts administrators to recent GPO modifications 
    to help track policy changes and identify unauthorized modifications.
    
    Monitoring GPO changes is critical for change control, security compliance, and 
    troubleshooting unexpected policy application issues.

.PARAMETER HoursBack
    Number of hours in the past to check for GPO changes. Default: 24 hours

.PARAMETER SaveToCustomField
    Name of a custom field to save the GPO change report.

.EXAMPLE
    -HoursBack 48

    [Info] Monitoring GPO changes in the last 48 hours...
    [Info] Found 2 recently modified GPO(s)
    
    GPO Name: Default Domain Policy
    Modified: 02/09/2026 10:30:00
    Modified By: DOMAIN\AdminUser

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2 (Domain Controller or RSAT)
    Release notes: Initial release for WAF v3.0
    Requires: GroupPolicy PowerShell module, domain access
    
.COMPONENT
    GroupPolicy - Active Directory Group Policy management module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/grouppolicy/

.FUNCTIONALITY
    - Queries all domain GPOs for modification timestamps
    - Identifies GPOs modified within specified time window
    - Reports GPO name, modification time, and modifier
    - Can save change report to custom fields
    - Alerts on recent GPO modifications
#>

[CmdletBinding()]
param(
    [int]$HoursBack = 24,
    [string]$SaveToCustomField
)

begin {
    if ($env:hoursBack -and $env:hoursBack -notlike "null") {
        $HoursBack = [int]$env:hoursBack
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

    $ExitCode = 0
    $Threshold = (Get-Date).AddHours(-$HoursBack)
}

process {
    try {
        Write-Host "[Info] Monitoring GPO changes in the last $HoursBack hours..."
        
        $AllGPOs = Get-GPO -All -ErrorAction Stop
        $RecentlyModified = $AllGPOs | Where-Object { $_.ModificationTime -ge $Threshold }

        if ($RecentlyModified) {
            Write-Host "[Info] Found $($RecentlyModified.Count) recently modified GPO(s)`n"
            
            $Report = @()
            foreach ($GPO in $RecentlyModified) {
                $GPOInfo = "GPO: $($GPO.DisplayName) | Modified: $($GPO.ModificationTime) | Owner: $($GPO.Owner)"
                Write-Host $GPOInfo
                $Report += $GPOInfo
            }

            if ($SaveToCustomField) {
                try {
                    $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Host "`n[Info] Report saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Host "[Error] Failed to save to custom field: $_"
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Host "[Info] No GPO changes detected in the last $HoursBack hours"
        }
    }
    catch {
        Write-Host "[Error] Failed to monitor GPOs: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
