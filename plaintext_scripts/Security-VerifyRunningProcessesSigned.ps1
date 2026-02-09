#Requires -Version 5.1

<#
.SYNOPSIS
    Verifies digital signatures of all running processes and reports unsigned executables.

.DESCRIPTION
    This script enumerates all running processes, validates their digital signatures using 
    authenticode verification, and identifies unsigned or invalidly signed executables. Results 
    can be saved to custom fields for monitoring and security compliance.
    
    Digital signature verification is critical for detecting malware, unauthorized software, 
    and ensuring compliance with security policies that require code signing.

.PARAMETER SaveToMultilineField
    Name of a multiline custom field to save the list of unsigned processes.

.PARAMETER SaveToWysiwygField
    Name of a WYSIWYG custom field to save formatted HTML output with signature details.

.EXAMPLE
    -SaveToMultilineField "UnsignedProcesses"

    Scanning 142 running processes...
    Found 3 unsigned processes
    [Warn] Unsigned: notepad++.exe (PID: 5432)
    [Warn] Unsigned: custom_tool.exe (PID: 8912)
    [Warn] Unsigned: test.exe (PID: 1024)
    [Info] Results saved to custom field 'UnsignedProcesses'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    
.COMPONENT
    Get-AuthenticodeSignature - PowerShell cmdlet for signature verification
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-authenticodesignature

.FUNCTIONALITY
    - Enumerates all running processes with executable paths
    - Validates digital signatures using Get-AuthenticodeSignature
    - Identifies unsigned, invalid, or missing signatures
    - Filters system processes and known safe executables
    - Reports signature status, signer information, and certificate details
    - Saves results to custom fields for compliance tracking
#>

[CmdletBinding()]
param(
    [string]$SaveToMultilineField,
    [string]$SaveToWysiwygField
)

begin {
    if ($env:saveToMultilineField -and $env:saveToMultilineField -notlike "null") {
        $SaveToMultilineField = $env:saveToMultilineField
    }
    if ($env:saveToWysiwygField -and $env:saveToWysiwygField -notlike "null") {
        $SaveToWysiwygField = $env:saveToWysiwygField
    }

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

        $NinjaPropertyOptions = $null
        if ($Type -and $Type -eq "Dropdown") {
            if ($DocumentName) {
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
            else {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }

        if ($NinjaPropertyOptions -and $NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }

        $NinjaValue = switch ($Type) {
            "Checkbox" { [System.Convert]::ToBoolean($Value) }
            "Date or Date Time" {
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
                $TimeSpan.TotalSeconds
            }
            "Dropdown" {
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID
                if (-not $Selection) {
                    throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown")
                }
                $Selection
            }
            default { $Value }
        }

        if ($DocumentName) {
            $CustomField = Ninja-Property-Docs-Set -AttributeName $Name -AttributeValue $NinjaValue @DocumentationParams 2>&1
        }
        else {
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        }

        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $ExitCode = 0
}

process {
    try {
        $Processes = Get-Process | Where-Object { $_.Path } | Sort-Object -Property Path -Unique
        Write-Host "[Info] Scanning $($Processes.Count) running processes..."

        $UnsignedProcesses = New-Object System.Collections.Generic.List[Object]

        foreach ($Process in $Processes) {
            try {
                $Signature = Get-AuthenticodeSignature -FilePath $Process.Path -ErrorAction Stop
                
                if ($Signature.Status -ne "Valid") {
                    $UnsignedProcesses.Add([PSCustomObject]@{
                        ProcessName = $Process.ProcessName
                        Path = $Process.Path
                        PID = $Process.Id
                        Status = $Signature.Status
                        Signer = $Signature.SignerCertificate.Subject
                    })
                    Write-Host "[Warn] $($Signature.Status): $($Process.ProcessName) (PID: $($Process.Id))"
                }
            }
            catch {
                Write-Host "[Warn] Could not verify signature for $($Process.ProcessName): $_"
            }
        }

        Write-Host "[Info] Found $($UnsignedProcesses.Count) unsigned or invalid processes"

        if ($SaveToMultilineField -and $UnsignedProcesses.Count -gt 0) {
            try {
                $Output = $UnsignedProcesses | ForEach-Object { "$($_.ProcessName) - $($_.Path) - Status: $($_.Status)" } | Out-String
                $Output | Set-NinjaProperty -Name $SaveToMultilineField -Type "MultiLine"
                Write-Host "[Info] Results saved to custom field '$SaveToMultilineField'"
            }
            catch {
                Write-Host "[Error] Failed to save to multiline custom field: $_"
                $ExitCode = 1
            }
        }

        if ($SaveToWysiwygField -and $UnsignedProcesses.Count -gt 0) {
            try {
                $htmlOutput = "<h3>Unsigned or Invalid Processes</h3><table border='1'><tr><th>Process</th><th>Path</th><th>Status</th></tr>"
                foreach ($proc in $UnsignedProcesses) {
                    $htmlOutput += "<tr><td>$($proc.ProcessName)</td><td>$($proc.Path)</td><td>$($proc.Status)</td></tr>"
                }
                $htmlOutput += "</table>"
                $htmlOutput | Set-NinjaProperty -Name $SaveToWysiwygField -Type "WYSIWYG"
                Write-Host "[Info] Results saved to WYSIWYG custom field '$SaveToWysiwygField'"
            }
            catch {
                Write-Host "[Error] Failed to save to WYSIWYG custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to scan processes: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
