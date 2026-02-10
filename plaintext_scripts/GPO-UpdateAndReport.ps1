#Requires -Version 5.1

<#
.SYNOPSIS
    Force Group Policy update and generate detailed report.

.DESCRIPTION
    This script performs a forced Group Policy update (gpupdate /force) and generates
    a comprehensive report of all applied Group Policies using gpresult. The report
    includes domain information, applied GPOs, and policy status.

.PARAMETER CustomFieldName
    Name of the NinjaRMM custom field to store the HTML report. Default: "groupPolicy"

.PARAMETER Timeout
    Maximum time in seconds for gpupdate to wait. Default: 120 seconds

.PARAMETER User
    Specific domain user account to generate report for (requires elevation).
    Format: DOMAIN\username

.EXAMPLE
    .\GPO-UpdateAndReport.ps1

    Computer Policy updated successfully!
    User Policy updated successfully!
    Generated Group Policy report with 8 GPOs

.EXAMPLE
    .\GPO-UpdateAndReport.ps1 -User "CONTOSO\jdoe" -Timeout 180

    Updates Group Policy with 180 second timeout and generates report for specified user.

.OUTPUTS
    HTML report stored in NinjaRMM custom field.

.NOTES
    File Name      : GPO-UpdateAndReport.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.1: Updated calculated name
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$CustomFieldName = "groupPolicy",
    
    [Parameter()]
    [Int]$Timeout = 120,
    
    [Parameter()]
    [String]$User
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $ExitCode = 0
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $LogMessage }
            'WARNING' { Write-Warning $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:customFieldName -and $env:customFieldName -notlike "null") { 
        $CustomFieldName = $env:customFieldName 
    }
    if ($env:groupPolicyTimeout -and $env:groupPolicyTimeout -notlike "null") { 
        $Timeout = $env:groupPolicyTimeout 
    }
    if ($env:user -and $env:user -notlike "null") { 
        $User = $env:user 
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    function Test-IsDomainJoined {
        return (Get-CimInstance -Class Win32_ComputerSystem).PartOfDomain
    }

    function Test-IsDomainController {
        return (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2
    }

    function Test-GroupPolicyResults {
        param(
            [string]$Type,
            [string]$Result
        )

        if ($Result | Select-String "errors") {
            Write-Log "$Type Policy was not updated successfully!" -Level ERROR
            return $false
        }
        else {
            Write-Log "$Type Policy updated successfully!"
            return $true
        }
    }
}

process {
    try {
        $Success = $true

        if (-not (Test-IsElevated)) {
            Write-Log "This script is not running with Administrator privileges. The end report will not contain Computer GPO data." -Level WARNING
            if ($User) {
                Write-Log "Not elevated unable to create group policy result report for specified user. Will create a report for the current user instead." -Level WARNING
            }
        }

        if (-not (Test-IsDomainJoined)) {
            Write-Log "This computer is not joined to the domain!" -Level WARNING
        }

        if ((Test-IsDomainJoined) -and -not (Test-IsDomainController) -and -not (Test-ComputerSecureChannel -ErrorAction Ignore)) {
            Write-Log "This device does not have a secure connection to the Domain Controller! Is the domain controller reachable?" -Level WARNING
            $Success = $false
        }

        Write-Log "Starting Group Policy update (timeout: $Timeout seconds)"
        
        $gpupdate = if (Test-IsSystem) {
            Invoke-Command { gpupdate.exe /force /wait:$Timeout }
        }
        else {
            Invoke-Command { gpupdate.exe /wait:$Timeout }
        }

        $computerResult = $gpupdate | Select-String "Computer Policy"
        $userResult = $gpupdate | Select-String "User Policy"

        $ComputerTest = Test-GroupPolicyResults -Type "Computer" -Result $computerResult
        $UserTest = Test-GroupPolicyResults -Type "User" -Result $userResult

        if (-not $UserTest -or -not $ComputerTest) {
            $Success = $false
        }

        if (Test-Path "$env:TEMP\gpresult.xml" -ErrorAction SilentlyContinue) { 
            Remove-Item "$env:TEMP\gpresult.xml" -Force 
        }

        Write-Log "Generating Group Policy result report"

        if ((Test-IsSystem) -and -not $User) {
            $LastLoggedInUser = Get-ItemPropertyValue -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "LastLoggedOnUser" -ErrorAction SilentlyContinue
            if ($LastLoggedInUser) {
                Invoke-Command { gpresult.exe /USER $LastLoggedInUser /X "$env:TEMP\gpresult.xml" }
            }
            else {
                Write-Log "Couldn't determine the last logged on user. Cannot generate a report as System. Please specify a user using -User or have one sign in." -Level ERROR
            }
        }
        elseif ($User -and (Test-IsElevated)) {
            Invoke-Command { gpresult.exe /USER $User /X "$env:TEMP\gpresult.xml" }
        }
        else {
            Invoke-Command { gpresult.exe /X "$env:TEMP\gpresult.xml" }
        }

        if (-not (Test-Path "$env:TEMP\gpresult.xml" -ErrorAction SilentlyContinue)) {
            Write-Log "Failed to generate report with gpresult!" -Level ERROR
            $ExitCode = 1
            return
        }

        [xml]$resultXML = Get-Content "$env:TEMP\gpresult.xml"

        if (Test-Path "$env:TEMP\gpresult.xml" -ErrorAction SilentlyContinue) { 
            Remove-Item "$env:TEMP\gpresult.xml" -Force 
        }

        $GPOs = $resultXML.DocumentElement | ForEach-Object {
            ForEach ($GPO in $_.ComputerResults.GPO.Name) {
                $ComputerGPO = [PSCustomObject]@{
                    Name          = $GPO
                    Type          = "Computer"
                    Enabled       = $resultXML.DocumentElement.ComputerResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object -ExpandProperty Enabled -ErrorAction SilentlyContinue
                    IsValid       = $resultXML.DocumentElement.ComputerResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object -ExpandProperty IsValid -ErrorAction SilentlyContinue
                    FilterAllowed = $resultXML.DocumentElement.ComputerResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object -ExpandProperty FilterAllowed -ErrorAction SilentlyContinue
                }

                if (-not $ComputerGPO.Enabled) { $ComputerGPO.Enabled = "N/A" }
                if (-not $ComputerGPO.IsValid) { $ComputerGPO.IsValid = "N/A" }
                if (-not $ComputerGPO.FilterAllowed) { $ComputerGPO.FilterAllowed = "N/A" }

                $ComputerGPO
            }

            ForEach ($GPO in $_.UserResults.GPO.Name) {
                $UserGPO = [PSCustomObject]@{
                    Name          = $GPO
                    Type          = "User"
                    Enabled       = $resultXML.DocumentElement.UserResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object -ExpandProperty Enabled -ErrorAction SilentlyContinue
                    IsValid       = $resultXML.DocumentElement.UserResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object -ExpandProperty IsValid -ErrorAction SilentlyContinue
                    FilterAllowed = $resultXML.DocumentElement.UserResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object -ExpandProperty FilterAllowed -ErrorAction SilentlyContinue
                }

                if (-not $UserGPO.Enabled) { $UserGPO.Enabled = "N/A" }
                if (-not $UserGPO.IsValid) { $UserGPO.IsValid = "N/A" }
                if (-not $UserGPO.FilterAllowed) { $UserGPO.FilterAllowed = "N/A" }

                $UserGPO
            }
        }

        $Report = New-Object System.Collections.Generic.List[string]
        $Report.Add("
<div class='card flex-grow-1'>
  <div class='card-title-box'>
    <div class='card-title'><i class='fas fa-building'></i>&nbsp;&nbsp;Group Policy Results</div>
  </div>
  <div class='card-body'>
    <p class='card-text'></p>
    <p><b>Domain</b><br>$($resultXML.DocumentElement.UserResults.Domain)</p>
    <p><b>Site Name</b><br>$($resultXML.DocumentElement.UserResults.Site)</p>
    <p><b>Slow Link?</b><br>$($resultXML.DocumentElement.UserResults.SlowLink)</p>
    <p><b>Computer Account Used</b><br>$($resultXML.DocumentElement.ComputerResults.Name)</p>
    <p><b>User Account Used</b><br>$($resultXML.DocumentElement.UserResults.Name)</p>
    <table>
      <thead>
        <tr>
           <th>Name</th>
           <th>Type</th>
           <th>Enabled</th>
           <th>IsValid</th>
           <th>FilterAllowed</th>
        </tr>
      </thead>
        <tbody>
  ")
        
        foreach ($gpo in $GPOs) {
            $Report.Add("<tr>")
            $Report.Add("<td>$($gpo.Name)</td>")
            $Report.Add("<td>$($gpo.Type)</td>")
            $Report.Add("<td>$($gpo.Enabled)</td>")
            $Report.Add("<td>$($gpo.IsValid)</td>")
            $Report.Add("<td>$($gpo.FilterAllowed)</td>")
            $Report.Add("</tr>")
        }

        $Report.Add("
    </tbody>
  </table>
  </div>
</div>
")
        
        Write-Log "Generated Group Policy report with $($GPOs.Count) GPO(s)"
        $Report | Ninja-Property-Set-Piped -Name $CustomFieldName
        Write-Log "Report saved to custom field: $CustomFieldName"

        if (-not $Success) {
            $ExitCode = 1
        }
    }
    catch {
        Write-Log "Script execution failed: $_" -Level ERROR
        $ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $Duration seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
