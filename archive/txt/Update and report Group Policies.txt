#Requires -Version 5.1

<#
.SYNOPSIS
    Initiates a gpupdate. It will perform a gpupdate /force
.DESCRIPTION
    Initiates a gpupdate. It will perform a gpupdate /force
.EXAMPLE
    (No Parameters)
  
    Computer Policy updated successfully!
    User Policy updated successfully!

    ##### Group Policy Result ##### 

    Domain: test.lan 
    Site Name: Default-First-Site-Name 
    Slow Link?: false 

    Computer Account Used: TEST\KYLE-WIN10-TEST$ 
    User Account Used: TEST\tuser 

    Name                                   Type     Enabled IsValid FilterAllowed AccessDenied
    ----                                   ----     ------- ------- ------------- ------------
    {1ED0F3EF-6E54-4380-8BB3-6683A8D02E59} Computer N/A     false   false         false       
    {31B2F340-016D-11D2-945F-00C04FB984F9} User     N/A     false   false         N/A         
    Default Domain Policy                  Computer true    true    true          false       
    Local Group Policy                     Computer true    true    true          false       
    Local Group Policy                     User     true    true    true          false       
    Test GPO                               User     true    true    true          N/A         

PARAMETER: -Timeout "30"
    The amount of time in seconds gpupdate should try to update. After that time gpupdate will timeout if no update is received.
    
PARAMETER: -CustomFieldName "ReplaceMeWithAnyMultilineCustomField"

    The name of a multiline customfield to store the results in.

PARAMETER: -User "CONTOSO\jdoe"
    The name of a user you'd like to generate a gpresult report with.

PARAMETER: AllUsers
    When the script is ran as system it will logout all logged in users upon successful gpupdate. If ran as a user it will logout only just that user if required.
.EXAMPLE
    Computer Policy updated successfully!
    User Policy updated successfully!

    ##### Group Policy Result ##### 

    Domain: test.lan 
    Site Name: Default-First-Site-Name 
    Slow Link?: false 

    Computer Account Used: TEST\KYLE-WIN10-TEST$ 
    User Account Used: TEST\tuser 

    Name                                   Type     Enabled IsValid FilterAllowed AccessDenied
    ----                                   ----     ------- ------- ------------- ------------
    {1ED0F3EF-6E54-4380-8BB3-6683A8D02E59} Computer N/A     false   false         false       
    {31B2F340-016D-11D2-945F-00C04FB984F9} User     N/A     false   false         N/A         
    Default Domain Policy                  Computer true    true    true          false       
    Local Group Policy                     Computer true    true    true          false       
    Local Group Policy                     User     true    true    true          false       
    Test GPO                               User     true    true    true          N/A         

.EXAMPLE
    Computer Policy updated successfully!
    User Policy updated successfully!

    ##### Group Policy Result ##### 

    Domain: test.lan 
    Site Name: Default-First-Site-Name 
    Slow Link?: false 

    Computer Account Used: TEST\KYLE-WIN10-TEST$ 
    User Account Used: TEST\tuser 

    Name                                   Type     Enabled IsValid FilterAllowed AccessDenied
    ----                                   ----     ------- ------- ------------- ------------
    {1ED0F3EF-6E54-4380-8BB3-6683A8D02E59} Computer N/A     false   false         false       
    {31B2F340-016D-11D2-945F-00C04FB984F9} User     N/A     false   false         N/A         
    Default Domain Policy                  Computer true    true    true          false       
    Local Group Policy                     Computer true    true    true          false       
    Local Group Policy                     User     true    true    true          false       
    Test GPO                               User     true    true    true          N/A         



    WARNING: -Reboot was specified. Scheduling a reboot for 06/22/2023 13:24:16!
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Version: 1.1
    Release Notes: Updated Calculated Name
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
    # If script variables are used overwrite their parameter
    if ($env:customFieldName -and $env:customFieldName -notlike "null") { $CustomFieldName = $env:customFieldName }
    if ($env:groupPolicyTimeout -and $env:groupPolicyTimeout -notlike "null") { $Timeout = $env:groupPolicyTimeout }
    if ($env:user -and $env:user -notlike "null") { $User = $env:user }

    # Checks if script is running with elevated permissions
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    # Checks if script is running as system
    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    # Check if the computer is domain joined (group policy is still a thing on non-domain joined machine just not normally used)
    function Test-IsDomainJoined {
        return $(Get-CimInstance -Class Win32_ComputerSystem).PartOfDomain
    }

    # Check if its a domain controller running this
    function Test-IsDomainController {
        return $(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2
    }

    # Outputs the currently logged in users in a more powershell friendly format
    function Get-QUser {
        $quser = quser.exe
        $quser -replace '\s{2,}', ',' -replace '>' | ConvertFrom-Csv
    }

    # Simply checks if gpupdate threw any errors
    function Test-GroupPolicyResults {
        param(
            [string]$Type,
            [string]$Result
        )

        if ($Result | Select-String "errors") {
            Write-Error "[Error] $Type Policy was not updated successfully!"
            $False
        }
        else {
            Write-Host "$Type Policy updated successfully!"
            $True
        }
    }

}
process {
    # We don't want to exit the script for most errors as the gpresult report might still be helpful
    $Success = $True

    if (-not (Test-IsElevated)) {
        Write-Warning "This script is not running with Administrator priveledges. The end report will not contain Computer GPO data."
        if ($User) {
            Write-Warning "Not elevated unable to create group policy result report for specified user. Will create a report for the current user instead."
        }
    }

    # Warns the end user if the computer is not-domain joined. I don't consider this a failure though just something to keep in mind.
    if (-not (Test-IsDomainJoined)) {
        Write-Warning "This computer is not joined to the domain!"
    }

    # If a secure connection to the domain cannot be established group policy will fail to update. 
    if ((Test-IsDomainJoined) -and -not (Test-IsDomainController) -and -not (Test-ComputerSecureChannel -ErrorAction Ignore)) {
        Write-Warning "This device does not have a secure connection to the Domain Controller! Is the domain controller reachable?"
        $Success = $False
    }

    # Updates group policy. We only use /force when Logoff is specified due to gpupdate stalling the script if a logoff is needed.
    $gpupdate = if ((Test-IsSystem)) {
        Invoke-Command { gpupdate.exe /force /wait:$Timeout }
    }
    else {
        Invoke-Command { gpupdate.exe /wait:$Timeout }
    }

    # Split up the results between Computer Policy and User Policy
    $computerResult = $gpupdate | Select-String "Computer Policy"
    $userResult = $gpupdate | Select-String "User Policy"

    # Testing them to confirm gpupdate worked
    $ComputerTest = Test-GroupPolicyResults -Type "Computer" -Result $computerResult
    $UserTest = Test-GroupPolicyResults -Type "User" -Result $userResult

    # If either of them are unsuccessful we'll want to exit with a status code of 1 but we'll want the result report first.
    if (-not $UserTest -or -not $ComputerTest) {
        $Success = $False
    }

    # If the script somehow got interupted before it had a chance to clean up its results we'll want to remove the previous results
    if (Test-Path "$env:TEMP\gpresult.xml" -ErrorAction Ignore) { Remove-Item "$env:TEMP\gpresult.xml" -Force }

    # We can't generate results with gpresult as the SYSTEM user so we'll attempt to generate results for the last logged in user.
    if ((Test-IsSystem) -and -not $User) {
        $LastLoggedInUser = Get-ItemPropertyValue -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "LastLoggedOnUser" -ErrorAction Ignore 
        if ($LastLoggedInUser) {
            Invoke-Command { gpresult.exe /USER $LastLoggedInUser /X "$env:TEMP\gpresult.xml" }
        }
        else {
            Write-Error "[Error] Couldn't determine the last logged on user. We cannot generate a report as System please either specify a user using -User or have one sign in. :)"
        }
    }
    elseif ($User -and (Test-IsElevated)) {
        # Of course if we were given a user to generate results for we'll want to do that instead.
        Invoke-Command { gpresult.exe /USER $User /X "$env:TEMP\gpresult.xml" }
    }
    else {
        # All other cases we'll want to generate the results as the same user the script is running as.
        Invoke-Command { gpresult.exe /X "$env:TEMP\gpresult.xml" }
    }

    # If we failed to generate the results that's not a big deal but we'll want to alert whoever ran it that that's what happened.
    if (-not (Test-Path "$env:TEMP\gpresult.xml" -ErrorAction Ignore) ) {
        Write-Error "Failed to generate report with gpresult!"
        exit 0
    }

    # Cast the xml to an xml type
    [xml]$resultXML = Get-Content "$env:TEMP\gpresult.xml"

    # Cleaning up after ourself
    if (Test-Path "$env:TEMP\gpresult.xml" -ErrorAction Ignore) { Remove-Item "$env:TEMP\gpresult.xml" -Force }

    # Lets construct an object for the active gpo's that we can format into a table later
    $GPOs = $resultXML.DocumentElement | ForEach-Object {
        ForEach ($GPO in $_.ComputerResults.GPO.Name) {
            $ComputerGPO = [PSCustomObject]@{
                Name          = $GPO
                Type          = "Computer"
                Enabled       = $resultXML.DocumentElement.ComputerResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object Enabled -ExpandProperty Enabled -ErrorAction Ignore
                IsValid       = $resultXML.DocumentElement.ComputerResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object IsValid -ExpandProperty IsValid -ErrorAction Ignore
                FilterAllowed = $resultXML.DocumentElement.ComputerResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object FilterAllowed -ExpandProperty FilterAllowed -ErrorAction Ignore
            }

            # If any values are blank we'll want to replace it with N/A
            if (-not $ComputerGPO.Enabled) { $ComputerGPO.Enabled = "N/A" }
            if (-not $ComputerGPO.IsValid) { $ComputerGPO.IsValid = "N/A" }
            if (-not $ComputerGPO.FilterAllowed) { $ComputerGPO.FilterAllowed = "N/A" }

            $ComputerGPO
        }

        ForEach ($GPO in $_.UserResults.GPO.Name) {
            $UserGPO = [PSCustomObject]@{
                Name          = $GPO
                Type          = "User"
                Enabled       = $resultXML.DocumentElement.UserResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object Enabled -ExpandProperty Enabled -ErrorAction Ignore
                IsValid       = $resultXML.DocumentElement.UserResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object IsValid -ExpandProperty IsValid -ErrorAction Ignore
                FilterAllowed = $resultXML.DocumentElement.UserResults.GPO | Where-Object { $_.Name -like $GPO } | Select-Object FilterAllowed -ExpandProperty FilterAllowed -ErrorAction Ignore
            }

            # If any values are blank we'll want to replace it with N/A
            if (-not $UserGPO.Enabled) { $UserGPO.Enabled = "N/A" }
            if (-not $UserGPO.IsValid) { $UserGPO.IsValid = "N/A" }
            if (-not $UserGPO.FilterAllowed) { $UserGPO.FilterAllowed = "N/A" }

            $UserGPO
        }
    }

    # Construct report
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
    foreach($gpo in $GPOs)
     {
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
    # Output Report
    # $Report | Ninja-Property-Set-Piped -Name grouppolicy
    #$Report | c:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe set $env:customFieldName --stdin
    $Report | Ninja-Property-Set-Piped -Name $env:customFieldName


    # If we had any kind of failures its best to not reboot the system or logoff any users
    if (-not $Success) {
        exit 1
    }
}
end {
    
    
    
}
