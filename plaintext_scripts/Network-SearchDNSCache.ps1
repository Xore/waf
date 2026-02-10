#Requires -Version 5.1

<#
.SYNOPSIS
    Search for DNS cache record names that match the specified keywords.
.DESCRIPTION
    Search for DNS cache record names that match the specified keywords.
    The DNS cache is a temporary database maintained by the operating system that contains records of all the recent visits and attempted visits to websites and other internet domains.
    This script searches the DNS cache for record names that match the specified keywords and outputs the results to the Activity Feed.
    Optionally, the results can be saved to a multiline custom field.

PARAMETER: -Keywords "ExampleInput"
    Comma separated list of keywords to search for in the DNS cache.
.EXAMPLE
    -Keywords "arpa"
    ## EXAMPLE OUTPUT WITH Keywords ##
    Entry: 1.80.19.172.in-addr.arpa, Record Name: 1.80.19.172.in-addr.arpa., Record Type: 12, Data: test.mshome.net, TTL: 598963

PARAMETER: -Keywords "arpa,mshome" -MultilineCustomField "ReplaceMeWithAnyMultilineCustomField"
    The name of the multiline custom field to save the results to.
.EXAMPLE
    -Keywords "arpa,mshome" -MultilineCustomField "ReplaceMeWithAnyMultilineCustomField"
    ## EXAMPLE OUTPUT WITH MultilineCustomField ##
    Entry: 1.80.19.172.in-addr.arpa, Record Name: 1.80.19.172.in-addr.arpa., Record Type: 12, Data: test.mshome.net, TTL: 598963
    Entry: test.mshome.net, Record Name: test.mshome.net., Record Type: 1, Data: 172.19.80.1, TTL: 598963

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Version: 3.0.0
    Release Notes: v3.0.0 - Upgraded to V3.0.0 standards (script-scoped exit code)
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String[]]$Keywords,
    [Parameter()]
    [String]$MultilineCustomField
)

begin {
    $script:ExitCode = 0
    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter()]
            [String]$Type,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value,
            [Parameter()]
            [String]$DocumentName
        )
    
        $Characters = $Value | Measure-Object -Character | Select-Object -ExpandProperty Characters
        if ($Characters -ge 10000) {
            throw [System.ArgumentOutOfRangeException]::New("Character limit exceeded, value is greater than 10,000 characters.")
        }
        
        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }
        
        $ValidFields = "Attachment", "Checkbox", "Date", "Date or Date Time", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine", "MultiSelect", "Phone", "Secure", "Text", "Time", "URL", "WYSIWYG"
        if ($Type -and $ValidFields -notcontains $Type) { Write-Warning "$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" }
        
        $NeedsOptions = "Dropdown"
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
            "Checkbox" {
                $NinjaValue = [System.Convert]::ToBoolean($Value)
            }
            "Date or Date Time" {
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
                $NinjaValue = $TimeSpan.TotalSeconds
            }
            "Dropdown" {
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID
        
                if (-not $Selection) {
                    throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown")
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
            $CustomField = Ninja-Property-Set -Name $Name -Value $NinjaValue 2>&1
        }
        
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }
}

process {
    $Keywords = if ($env:keywordsToSearch -and $env:keywordsToSearch -ne "null") {
        $env:keywordsToSearch -split "," | ForEach-Object { $_.Trim() }
    }
    else {
        $Keywords -split "," | ForEach-Object { $_.Trim() }
    }
    $Keywords = if ($Keywords -and $Keywords -ne "null") {
        $Keywords | ForEach-Object {
            Write-Host "[Info] Searching for DNS Cache Records Matching: $_"
            Write-Output "*$_*"
        }
    }
    else {
        Write-Host "[Error] No Keywords Provided"
        $script:ExitCode = 1
        exit $script:ExitCode
    }

    $MultilineCustomField = if ($env:multilineCustomField -and $env:multilineCustomField -ne "null") {
        $env:multilineCustomField -split "," | ForEach-Object { $_.Trim() }
    }
    else {
        $MultilineCustomField -split "," | ForEach-Object { $_.Trim() }
    }

    Write-Host ""

    $DnsCache = Get-DnsClientCache -Name $Keywords | Select-Object -Property Entry, Name, Type, Data, TimeToLive

    if ($null -eq $DnsCache) {
        Write-Host "[Warn] No DNS Cache Entries Found"
    }
    else {
        $Results = $DnsCache | ForEach-Object {
            "Entry: $($_.Entry), Record Name: $($_.Name), Record Type: $($_.Type), Data: $($_.Data), TTL: $($_.TimeToLive)"
        }
        Write-Host "[Info] DNS Cache Entries Found"
        if ($MultilineCustomField -and $MultilineCustomField -ne "null") {
            Write-Host "[Info] Attempting to set Custom Field '$MultilineCustomField'."
            try {
                Set-NinjaProperty -Name $MultilineCustomField -Value $($Results | Out-String)
                Write-Host "[Info] Successfully set Custom Field '$MultilineCustomField'!"
            }
            catch {
                Write-Host "[Warn] Failed to set Custom Field '$MultilineCustomField'."
                $Results | Out-String | Write-Host
            }
        }
        else {
            $Results | Out-String | Write-Host
        }
    }
    exit $script:ExitCode
}

end {
    
}
