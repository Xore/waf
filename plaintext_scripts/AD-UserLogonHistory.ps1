#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Retrieves user session events.
.DESCRIPTION
    Retrieves user session events from Windows event logs including Logon, Logoff, Lock, and Unlock events.
.PARAMETER Days
    Number of days to retrieve events from. Default: 10
.PARAMETER NinjaField
    NinjaOne custom field to store the table. Default: UserSessionEvents
.PARAMETER Mode
    Mode for filtering SIDs or usernames. Options: Include, Exclude. Default: Include
.PARAMETER SIDs
    List of SIDs to include or exclude from output
.PARAMETER UserNames
    List of usernames to include or exclude from output
.EXAMPLE
    -Days 7 -NinjaField "SessionEvents"
    Retrieves 7 days of session events.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param (
    [int]$Days = 10,
    [string]$NinjaField = 'UserSessionEvents',
    [ValidateSet('Include', 'Exclude')]
    [string]$Mode = 'Include',
    [System.Collections.Generic.List[System.String]]$SIDs,
    [System.Collections.Generic.List[System.String]]$UserNames
)

begin {
    $StartTime = Get-Date

    function Write-Log {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Warning', 'Error')]
            [string]$Level = 'Info'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $Output = "[$Timestamp] [$Level] $Message"
        Write-Host $Output
    }

    function ConvertTo-ObjectToHtmlTable {
        param (
            [Parameter(Mandatory = $true)]
            [System.Collections.Generic.List[Object]]$Objects
        )
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.Append('<table><thead><tr>')
        $Objects[0].PSObject.Properties.Name | Where-Object { $_ -ne 'RowColour' } | ForEach-Object { [void]$sb.Append("<th>$_</th>") }
        [void]$sb.Append('</tr></thead><tbody>')
        foreach ($obj in $Objects) {
            $rowClass = if ($obj.RowColour) { $obj.RowColour } else { '' }
            [void]$sb.Append("<tr class=`"$rowClass`">")
            foreach ($propName in $obj.PSObject.Properties.Name | Where-Object { $_ -ne 'RowColour' }) {
                [void]$sb.Append("<td>$($obj.$propName)</td>")
            }
            [void]$sb.Append('</tr>')
        }
        [void]$sb.Append('</tbody></table>')
        $OutputLength = $sb.ToString() | Measure-Object -Character -IgnoreWhiteSpace | Select-Object -ExpandProperty Characters
        if ($OutputLength -gt 200000) {
            Write-Log "Output exceeds NinjaOne WYSIWYG field limit of 200,000 characters. Actual: $OutputLength" -Level Warning
        }
        return $sb.ToString()
    }

    if ($ENV:Days) { $Days = [int]::Parse($ENV:Days) }
    if ($ENV:NinjaField) { $NinjaField = $ENV:NinjaField }
    if ($ENV:Mode) { $Mode = $ENV:Mode }
    if ($ENV:SIDs) { [System.Collections.Generic.List[System.String]]$SIDs = $ENV:SIDs -split ',' }
    if ($ENV:UserNames) { [System.Collections.Generic.List[System.String]]$UserNames = $ENV:UserNames -split ',' }

    $EventTypeLookup = @{
        7001 = 'Logon'
        7002 = 'Logoff'
        4800 = 'Lock'
        4801 = 'Unlock'
    }

    $XMLNameSpace = @{'ns' = 'http://schemas.microsoft.com/win/2004/08/events/event' }
    $XPathTargetUserSID = "//ns:Data[@Name='TargetUserSid']"
    $XPathUserSID = "//ns:Data[@Name='UserSid']"
}

process {
    try {
        Write-Log "Retrieving user session events from the last $Days days"

        $Events = [System.Collections.Generic.List[Object]]::new()

        $LockUnlockEvents = Get-WinEvent -FilterHashtable @{ 
            LogName   = 'Security'
            Id        = @(4800, 4801)
            StartTime = (Get-Date).AddDays(-$Days)
        } -ErrorAction SilentlyContinue

        if ($LockUnlockEvents) {
            if ($LockUnlockEvents -is [System.Array]) {
                $Events.AddRange($LockUnlockEvents)
            }
            else {
                $Events.Add($LockUnlockEvents)
            }
        }

        $LoginLogoffEvents = Get-WinEvent -FilterHashtable @{ 
            LogName      = 'System'
            Id           = @(7001, 7002)
            StartTime    = (Get-Date).AddDays(-$Days)
            ProviderName = 'Microsoft-Windows-Winlogon' 
        } -ErrorAction SilentlyContinue

        if ($LoginLogoffEvents) {
            if ($LoginLogoffEvents -is [System.Array]) {
                $Events.AddRange($LoginLogoffEvents)
            }
            else {
                $Events.Add($LoginLogoffEvents)
            }
        }

        if (-not $Events) {
            Write-Log "No events found" -Level Warning
            exit 0
        }

        Write-Log "Processing $($Events.Count) events"

        $Results = ForEach ($Event in $Events) {
            $Skip = $false
            $User = $null
            $XML = $Event.ToXML()
            
            Switch -Regex ($Event.Id) {
                '4...' {
                    $SID = (Select-Xml -Content $XML -Namespace $XMLNameSpace -XPath $XPathTargetUserSID).Node.'#text'
                    if ($SID) {
                        if ($Mode -eq 'Include' -and $SIDs -and $SIDs -notcontains $SID) { $Skip = $true }
                        if ($Mode -eq 'Exclude' -and $SIDs -and $SIDs -contains $SID) { $Skip = $true }
                        
                        try {
                            $User = [System.Security.Principal.SecurityIdentifier]::new($SID).Translate([System.Security.Principal.NTAccount]).Value
                        }
                        catch {
                            Write-Log "Failed to parse SID ($SID) for event $($Event.Id)" -Level Warning
                            $User = $SID
                        }
                        
                        if ($Mode -eq 'Include' -and $UserNames -and $UserNames -notcontains $User) { $Skip = $true }
                        if ($Mode -eq 'Exclude' -and $UserNames -and $UserNames -contains $User) { $Skip = $true }
                    }
                    Break            
                }
                '7...' {
                    $SID = (Select-Xml -Content $XML -Namespace $XMLNameSpace -XPath $XPathUserSID).Node.'#text'
                    if ($SID) {
                        if ($Mode -eq 'Include' -and $SIDs -and $SIDs -notcontains $SID) { $Skip = $true }
                        if ($Mode -eq 'Exclude' -and $SIDs -and $SIDs -contains $SID) { $Skip = $true }
                        
                        try {
                            $User = [System.Security.Principal.SecurityIdentifier]::new($SID).Translate([System.Security.Principal.NTAccount]).Value
                        }
                        catch {
                            Write-Log "Failed to parse SID ($SID) for event $($Event.Id)" -Level Warning
                            $User = $SID
                        }
                        
                        if ($Mode -eq 'Include' -and $UserNames -and $UserNames -notcontains $User) { $Skip = $true }
                        if ($Mode -eq 'Exclude' -and $UserNames -and $UserNames -contains $User) { $Skip = $true }
                    }
                    Break
                }
            }
            
            if (-not $Skip) {
                $RowColour = switch ($Event.Id) {
                    7001 { 'success' }
                    7002 { 'danger' }
                    4800 { 'warning' }
                    4801 { 'other' }
                }
                New-Object -TypeName PSObject -Property @{
                    Time      = $Event.TimeCreated
                    Id        = $Event.Id
                    Type      = $EventTypeLookup[$event.Id]
                    User      = $User
                    RowColour = $RowColour
                }
            }
        }

        if ($Results) {
            $Objects = $Results | Sort-Object Time
            $Table = ConvertTo-ObjectToHtmlTable -Objects $Objects
            $Table | Ninja-Property-Set-Piped $NinjaField
            Write-Log "Successfully stored $($Objects.Count) events to NinjaOne field: $NinjaField"
        }
        else {
            Write-Log "No events matched the filter criteria" -Level Warning
        }
    }
    catch {
        Write-Log "Failed to retrieve user session events: $_" -Level Error
        exit 1
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
