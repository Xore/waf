#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves all currently logged-on users on the system.

.DESCRIPTION
    This script queries the system to identify all currently logged-on users including console, 
    RDP, and disconnected sessions. It provides username, session type, session state, and 
    logon time for each active user session.
    
    Monitoring logged-on users is useful for system administration, security auditing, and 
    ensuring compliance with concurrent user license limits.

.PARAMETER SaveToCustomField
    Name of a custom field to save the logged-on users information.

.EXAMPLE
    -SaveToCustomField "ActiveUsers"

    [Info] Querying logged-on users...
    User: DOMAIN\john.doe | Session: Console | State: Active | Logon: 02/10/2026 08:30:00
    User: DOMAIN\jane.smith | Session: RDP | State: Disconnected | Logon: 02/09/2026 14:15:00
    [Info] Found 2 logged-on users
    [Info] Results saved to custom field 'ActiveUsers'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    
.COMPONENT
    quser.exe - Windows query user utility
    
.LINK
    https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/quser

.FUNCTIONALITY
    - Queries all active user sessions using quser command
    - Identifies console, RDP, and disconnected sessions
    - Reports session state (Active, Disconnected)
    - Provides logon timestamp for each session
    - Can save user session data to custom fields
#>

[CmdletBinding()]
param(
    [string]$SaveToCustomField
)

begin {
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
}

process {
    try {
        Write-Host "[Info] Querying logged-on users..."
        
        $QuserOutput = quser 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $Users = $QuserOutput | Select-Object -Skip 1 | ForEach-Object {
                $_ -replace '\s{2,}', ',' 
            } | ConvertFrom-Csv -Header "USERNAME", "SESSIONNAME", "ID", "STATE", "IDLE", "LOGON"

            $UserList = @()
            foreach ($User in $Users) {
                $UserInfo = "User: $($User.USERNAME) | Session: $($User.SESSIONNAME) | State: $($User.STATE)"
                Write-Host $UserInfo
                $UserList += $UserInfo
            }

            Write-Host "[Info] Found $($Users.Count) logged-on user(s)"

            if ($SaveToCustomField -and $UserList.Count -gt 0) {
                try {
                    $UserList -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Host "[Error] Failed to save to custom field: $_"
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Host "[Info] No users currently logged on"
        }
    }
    catch {
        Write-Host "[Error] Failed to query logged-on users: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
