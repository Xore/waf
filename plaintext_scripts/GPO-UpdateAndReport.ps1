#Requires -Version 5.1

<#
.SYNOPSIS
    Forces Group Policy update and generates comprehensive report.

.DESCRIPTION
    This script performs a forced Group Policy update (gpupdate /force) and generates
    a comprehensive HTML report of all applied Group Policies using gpresult. The report
    includes domain information, applied GPOs, policy status, and configuration details.
    
    The script performs the following:
    - Validates domain membership and domain controller connectivity
    - Checks elevation status and running context (SYSTEM/User)
    - Executes gpupdate /force with configurable timeout
    - Validates Computer and User policy update results
    - Generates XML report using gpresult
    - Parses XML to extract GPO details (Name, Type, Enabled, IsValid, FilterAllowed)
    - Creates formatted HTML table with all applied GPOs
    - Saves report to NinjaRMM custom field
    - Provides detailed execution summary
    
    When running as SYSTEM, automatically uses the last logged-on user for the report
    unless a specific user is provided.

.PARAMETER CustomFieldName
    Name of the NinjaRMM custom field to store the HTML report. Default: "groupPolicy"

.PARAMETER Timeout
    Maximum time in seconds for gpupdate to wait. Default: 120 seconds
    Valid range: 30-600 seconds

.PARAMETER User
    Specific domain user account to generate report for (requires elevation).
    Format: DOMAIN\username
    Example: "CONTOSO\jdoe"

.EXAMPLE
    .\GPO-UpdateAndReport.ps1

    [2026-02-10 21:00:00] [INFO] Starting: GPO-UpdateAndReport v3.0.0
    [2026-02-10 21:00:00] [INFO] Starting Group Policy update (timeout: 120 seconds)
    [2026-02-10 21:00:15] [SUCCESS] Computer Policy updated successfully!
    [2026-02-10 21:00:15] [SUCCESS] User Policy updated successfully!
    [2026-02-10 21:00:16] [INFO] Generating Group Policy result report
    [2026-02-10 21:00:18] [SUCCESS] Generated Group Policy report with 8 GPO(s)
    [2026-02-10 21:00:18] [SUCCESS] Report saved to custom field: groupPolicy

.EXAMPLE
    .\GPO-UpdateAndReport.ps1 -User "CONTOSO\jdoe" -Timeout 180

    Updates Group Policy with 180 second timeout and generates report for specified user.

.EXAMPLE
    .\GPO-UpdateAndReport.ps1 -CustomFieldName "gpoStatus" -Timeout 90

    Updates with 90 second timeout and saves to custom "gpoStatus" field.

.OUTPUTS
    HTML formatted report stored in NinjaRMM custom field.
    Console output with execution status and summary.

.NOTES
    File Name      : GPO-UpdateAndReport.ps1
    Prerequisite   : PowerShell 5.1 or higher, Domain-joined computer
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with error/warning counters and execution summary
    - 2.0: Added Write-Log function and execution tracking
    - 1.1: Updated calculated name
    - 1.0: Initial release
    
    Execution Context: Flexible (can run as user or SYSTEM)
    Execution Frequency: On-demand or scheduled
    Typical Duration: 20-60 seconds (depends on GPO count and network)
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A
    
    Required Privileges:
        - Standard user: Update user policies, generate user-context report
        - Administrator: Update computer policies, generate full report
        - SYSTEM: Full access, uses last logged-on user for report
    
    Important Notes:
        - Non-elevated execution cannot retrieve Computer GPO data
        - Domain Controller connectivity required for updates
        - Trust relationship must be intact for successful update
        - Report generation may fail if no user has logged in (SYSTEM context)

.COMPONENT
    gpupdate.exe - Windows Group Policy update tool
    gpresult.exe - Windows Group Policy results tool
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Forces Group Policy refresh
    - Validates policy update success
    - Generates comprehensive HTML reports
    - Handles multiple execution contexts
    - Updates NinjaRMM custom fields
    - Validates domain connectivity
    - Provides detailed error reporting
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name to store the report")]
    [String]$CustomFieldName = "groupPolicy",
    
    [Parameter(Mandatory=$false, HelpMessage="Timeout in seconds for gpupdate")]
    [ValidateRange(30, 600)]
    [Int]$Timeout = 120,
    
    [Parameter(Mandatory=$false, HelpMessage="Specific user to generate report for")]
    [String]$User
)

begin {
    Set-StrictMode -Version Latest
    
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "GPO-UpdateAndReport"
    $TempReportPath = "$env:TEMP\gpresult.xml"
    
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:GPOCount = 0
    $script:UpdateSuccess = $false

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
            [string]$Level = 'INFO'
        )
        
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { 
                Write-Error $LogMessage
                $script:ErrorCount++
            }
            'WARN' { 
                Write-Warning $LogMessage
                $script:WarningCount++
            }
            default { 
                Write-Output $LogMessage 
            }
        }
    }

    if ($env:customFieldName -and $env:customFieldName -notlike "null") { 
        $CustomFieldName = $env:customFieldName 
    }
    if ($env:groupPolicyTimeout -and $env:groupPolicyTimeout -notlike "null") { 
        $Timeout = [int]$env:groupPolicyTimeout 
    }
    if ($env:user -and $env:user -notlike "null") { 
        $User = $env:user 
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
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
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Type,
            
            [Parameter(Mandatory=$true)]
            [AllowEmptyString()]
            [string]$Result
        )

        if ($Result | Select-String "errors") {
            Write-Log "$Type Policy was not updated successfully!" -Level ERROR
            return $false
        }
        else {
            Write-Log "$Type Policy updated successfully!" -Level SUCCESS
            return $true
        }
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        $UpdateSuccess = $true

        if (-not (Test-IsElevated)) {
            Write-Log "Script is not running with Administrator privileges." -Level WARN
            Write-Log "The report will not contain Computer GPO data." -Level WARN
            
            if ($User) {
                Write-Log "Not elevated - unable to create report for specified user." -Level WARN
                Write-Log "Will create a report for the current user instead." -Level WARN
            }
        }

        if (-not (Test-IsDomainJoined)) {
            Write-Log "This computer is not joined to a domain!" -Level ERROR
            $script:ExitCode = 1
            return
        }

        Write-Log "Computer is domain-joined" -Level INFO

        if ((Test-IsDomainJoined) -and -not (Test-IsDomainController) -and -not (Test-ComputerSecureChannel -ErrorAction Ignore)) {
            Write-Log "This device does not have a secure connection to the Domain Controller!" -Level ERROR
            Write-Log "Is the domain controller reachable?" -Level ERROR
            $UpdateSuccess = $false
            $script:ExitCode = 1
        }

        Write-Log "Starting Group Policy update (timeout: $Timeout seconds)" -Level INFO
        
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
            $UpdateSuccess = $false
            $script:ExitCode = 1
        } else {
            $script:UpdateSuccess = $true
        }

        if (Test-Path $TempReportPath -ErrorAction SilentlyContinue) { 
            Remove-Item $TempReportPath -Force -ErrorAction SilentlyContinue
        }

        Write-Log "Generating Group Policy result report" -Level INFO

        if ((Test-IsSystem) -and -not $User) {
            $LastLoggedInUser = Get-ItemPropertyValue -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "LastLoggedOnUser" -ErrorAction SilentlyContinue
            
            if ($LastLoggedInUser) {
                Write-Log "Using last logged-on user: $LastLoggedInUser" -Level INFO
                Invoke-Command { gpresult.exe /USER $LastLoggedInUser /X $env:TEMP\gpresult.xml }
            }
            else {
                Write-Log "Could not determine the last logged-on user." -Level ERROR
                Write-Log "Cannot generate report as SYSTEM without a user context." -Level ERROR
                Write-Log "Please specify a user using -User parameter or have a user sign in." -Level ERROR
                $script:ExitCode = 1
                return
            }
        }
        elseif ($User -and (Test-IsElevated)) {
            Write-Log "Generating report for specified user: $User" -Level INFO
            Invoke-Command { gpresult.exe /USER $User /X $env:TEMP\gpresult.xml }
        }
        else {
            Write-Log "Generating report for current user" -Level INFO
            Invoke-Command { gpresult.exe /X $env:TEMP\gpresult.xml }
        }

        if (-not (Test-Path $TempReportPath -ErrorAction SilentlyContinue)) {
            Write-Log "Failed to generate report with gpresult!" -Level ERROR
            $script:ExitCode = 1
            return
        }

        [xml]$resultXML = Get-Content $TempReportPath

        if (Test-Path $TempReportPath -ErrorAction SilentlyContinue) { 
            Remove-Item $TempReportPath -Force -ErrorAction SilentlyContinue
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

        $script:GPOCount = ($GPOs | Measure-Object).Count
        Write-Log "Generated Group Policy report with $script:GPOCount GPO(s)" -Level SUCCESS

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
        
        $Report | Ninja-Property-Set-Piped -Name $CustomFieldName
        Write-Log "Report saved to custom field: $CustomFieldName" -Level SUCCESS

        if (-not $UpdateSuccess) {
            Write-Log "Group Policy update completed with warnings or errors" -Level WARN
            $script:ExitCode = 1
        } else {
            Write-Log "Group Policy update and report completed successfully" -Level SUCCESS
        }
    }
    catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Summary:" -Level INFO
        Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "  Errors: $script:ErrorCount" -Level INFO
        Write-Log "  Warnings: $script:WarningCount" -Level INFO
        Write-Log "  GPO Count: $script:GPOCount" -Level INFO
        Write-Log "  Update Success: $script:UpdateSuccess" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
