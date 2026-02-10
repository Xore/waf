#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Retrieves members of an Active Directory Organizational Unit

.DESCRIPTION
    Queries Active Directory for users within a specified Organizational Unit (OU).
    Searches for OUs matching the provided name and lists all user accounts within them.
    
    The script performs the following:
    - Validates Active Directory module availability
    - Searches for OUs matching the specified name
    - Retrieves all users from matching OUs
    - Displays results with OU distinguished names
    - Optionally saves results to NinjaRMM custom field
    
    This script runs unattended without user interaction.

.PARAMETER OU
    Name of the Organizational Unit to query.
    Supports wildcards (searches for OUs starting with this name).
    Example: "Sales" will match "OU=Sales,DC=contoso,DC=com"

.PARAMETER CustomField
    Optional name of NinjaRMM custom field to store results.
    Results will be saved as multiline text with OU paths and user lists.

.EXAMPLE
    .\AD-GetOUMembers.ps1 -OU "Sales"
    
    Retrieves all users from OUs starting with "Sales" and displays to console.

.EXAMPLE
    .\AD-GetOUMembers.ps1 -OU "IT" -CustomField "itOuMembers"
    
    Retrieves users from IT OUs and saves results to specified custom field.

.NOTES
    File Name      : AD-GetOUMembers.ps1
    Prerequisite   : PowerShell 5.1 or higher, Active Directory module
    Minimum OS     : Windows Server 2012 R2, Windows 10
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 2.0: Enhanced logging and NinjaRMM integration
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand
    Typical Duration: 3-8 seconds (depends on OU size)
    Timeout Setting: 180 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    NinjaRMM Fields Updated:
        - CustomField parameter (if specified) - User list by OU
        - adOuQueryStatus (Success/Failed/No Results)
        - adOuQueryDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Active Directory PowerShell module (RSAT)
        - Must run on Domain Controller or system with RSAT
    
    Environment Variables (Optional):
        - OuName: Alternative to -OU parameter
        - CustomField: Alternative to -CustomField parameter
    
    Exit Codes:
        0 - Success (users retrieved)
        1 - Failure (missing module, access denied, query failed)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/powershell/module/activedirectory/
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of OU to query")]
    [ValidateNotNullOrEmpty()]
    [string]$OU,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field name to store results")]
    [ValidateNotNullOrEmpty()]
    [string]$CustomField
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "AD-GetOUMembers"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:CLIFallbackCount = 0
    
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

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
        Write-Output "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
        }
    }

    function Set-NinjaField {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$FieldName,
            [Parameter(Mandatory=$true)]
            [AllowNull()]
            $Value
        )
        
        if ($null -eq $Value -or $Value -eq "") {
            Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
            return
        }
        
        $ValueString = $Value.ToString()
        
        try {
            if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
                Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
                Write-Log "Field '$FieldName' set successfully" -Level DEBUG
                return
            } else {
                throw "Ninja-Property-Set cmdlet not available"
            }
        } catch {
            Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
            
            try {
                if (-not (Test-Path $NinjaRMMCLI)) {
                    throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
                }
                
                $CLIArgs = @("set", $FieldName, $ValueString)
                $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    throw "CLI exit code: $LASTEXITCODE, Output: $CLIResult"
                }
                
                Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
                $script:CLIFallbackCount++
                
            } catch {
                Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
            }
        }
    }

    function Test-IsElevated {
        $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
        return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:OuName -and $env:OuName -notlike "null") {
            $OU = $env:OuName
            Write-Log "Using OU from environment: $OU" -Level INFO
        }
        
        if ($env:CustomField -and $env:CustomField -notlike "null") {
            $CustomField = $env:CustomField
            Write-Log "Using custom field from environment: $CustomField" -Level INFO
        }
        
        if ([string]::IsNullOrWhiteSpace($OU)) {
            Write-Log "OU parameter is required" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        if (-not (Test-IsElevated)) {
            Write-Log "Administrator privileges required" -Level ERROR
            $script:ExitCode = 1
            return
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        Write-Log "Checking Active Directory module availability" -Level INFO
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
            Write-Log "Active Directory PowerShell module not found. RSAT required." -Level ERROR
            Write-Log "Run on Domain Controller or install RSAT." -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        try {
            Import-Module ActiveDirectory -ErrorAction Stop
            Write-Log "Active Directory module loaded" -Level SUCCESS
        } catch {
            Write-Log "Failed to import Active Directory module: $_" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        Write-Log "Searching for OUs matching: $OU" -Level INFO
        $OUPaths = Get-ADOrganizationalUnit -Filter * -ErrorAction Stop | 
            Where-Object { $_.DistinguishedName -like "OU=$OU*" } | 
            Select-Object -ExpandProperty DistinguishedName
        
        if (-not $OUPaths) {
            Write-Log "No OUs found matching: $OU" -Level WARN
            Set-NinjaField -FieldName "adOuQueryStatus" -Value "No Results"
            Set-NinjaField -FieldName "adOuQueryDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            $script:ExitCode = 0
            return
        }
        
        Write-Log "Found $($OUPaths.Count) matching OU(s)" -Level SUCCESS
        
        $Report = [System.Collections.Generic.List[string]]::new()
        $TotalUsers = 0
        
        foreach ($OUPath in $OUPaths) {
            Write-Log "Processing OU: $OUPath" -Level DEBUG
            
            $Report.Add("")
            $Report.Add($OUPath)
            $Report.Add("-" * $OUPath.Length)
            
            try {
                $Users = Get-ADUser -Filter * -SearchBase $OUPath -ErrorAction Stop | 
                    Select-Object -ExpandProperty UserPrincipalName
                
                if ($Users) {
                    foreach ($User in $Users) {
                        $Report.Add($User)
                        $TotalUsers++
                    }
                    Write-Log "Found $($Users.Count) user(s) in $OUPath" -Level INFO
                } else {
                    $Report.Add("(No users found)")
                    Write-Log "No users found in $OUPath" -Level DEBUG
                }
            } catch {
                Write-Log "Error querying users from $OUPath - $_" -Level WARN
                $Report.Add("(Error: $_)")
            }
        }
        
        $ReportText = $Report -join "`n"
        Write-Log "OU Member Report:" -Level INFO
        Write-Output $ReportText
        Write-Log "Total users found: $TotalUsers" -Level SUCCESS
        
        if ($CustomField) {
            Set-NinjaField -FieldName $CustomField -Value $ReportText
            Write-Log "Results saved to custom field: $CustomField" -Level SUCCESS
        }
        
        Set-NinjaField -FieldName "adOuQueryStatus" -Value "Success"
        Set-NinjaField -FieldName "adOuQueryDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        Write-Log "OU member query completed successfully" -Level SUCCESS
        $script:ExitCode = 0
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Set-NinjaField -FieldName "adOuQueryStatus" -Value "Failed"
        Set-NinjaField -FieldName "adOuQueryDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
        
        if ($script:CLIFallbackCount -gt 0) {
            Write-Log "CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
        }
        
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
