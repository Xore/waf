#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Joins a computer to an Active Directory domain

.DESCRIPTION
    Joins the local computer to a specified Active Directory domain using provided credentials.
    Supports optional restart control and specific domain controller targeting.
    
    The script performs the following:
    - Validates required credentials and domain name
    - Creates secure credential object
    - Joins computer to domain
    - Optionally restarts computer (with parameter protection)
    - Updates NinjaRMM custom fields with join status
    
    This script runs unattended without user interaction.

.PARAMETER DomainName
    Target domain name to join (e.g., contoso.com)

.PARAMETER UserName
    Domain administrator username (format: DOMAIN\User or user@domain.com)

.PARAMETER Password
    Domain administrator password (plain text, converted to secure string)

.PARAMETER Server
    Optional specific domain controller IP or hostname.
    Only use if DNS cannot locate DC or specific DC targeting needed.

.PARAMETER NoRestart
    Prevents automatic restart after domain join.
    Without this switch, computer restarts automatically upon successful join.

.EXAMPLE
    .\AD-JoinComputerToDomain.ps1 -DomainName "contoso.com" -UserName "CONTOSO\Admin" -Password "Pass123" -NoRestart
    
    Joins computer to contoso.com domain without restarting.

.EXAMPLE
    .\AD-JoinComputerToDomain.ps1 -DomainName "contoso.com" -UserName "admin@contoso.com" -Password "Pass123"
    
    Joins computer and restarts automatically.

.NOTES
    File Name      : AD-JoinComputerToDomain.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 2.0: Enhanced logging and NinjaRMM integration
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand
    Typical Duration: 8-15 seconds (measured average, excluding restart)
    Timeout Setting: 300 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: Restarts ONLY if NoRestart switch is NOT provided
    
    NinjaRMM Fields Updated:
        - adDomainJoinStatus (Success/Failed/In Progress)
        - adDomainName (domain name)
        - adJoinDate (timestamp)
        - adRestartPending (Yes/No)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Network connectivity to domain controller
    
    Environment Variables (Optional):
        - domainToJoin: Alternative to -DomainName
        - usernameToJoinDomainWith: Alternative to -UserName
        - passwordToJoinDomainWithCustomField: Secure field for password
        - serverName: Alternative to -Server
        - noRestart: Alternative to -NoRestart
    
    Exit Codes:
        0 - Success (domain joined)
        1 - Failure (missing parameters, join failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Domain name to join")]
    [String]$DomainName,
    
    [Parameter(Mandatory=$false, HelpMessage="Domain admin username")]
    [String]$UserName,
    
    [Parameter(Mandatory=$false, HelpMessage="Domain admin password")]
    [String]$Password,
    
    [Parameter(Mandatory=$false, HelpMessage="Specific domain controller")]
    [String]$Server,
    
    [Parameter(Mandatory=$false, HelpMessage="Prevent automatic restart")]
    [Switch]$NoRestart
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "AD-JoinComputerToDomain"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:CLIFallbackCount = 0
    
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    $script:JoinCred = $null

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
                    throw "NinjaRMM CLI not found"
                }
                
                $CLIArgs = @("set", $FieldName, $ValueString)
                $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    throw "CLI exit code: $LASTEXITCODE"
                }
                
                Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
                $script:CLIFallbackCount++
                
            } catch {
                Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
            }
        }
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:domainToJoin -and $env:domainToJoin -notlike "null") { 
            $DomainName = $env:domainToJoin
            Write-Log "Using domain from environment: $DomainName" -Level DEBUG
        }
        
        if ($env:usernameToJoinDomainWith -and $env:usernameToJoinDomainWith -notlike "null") { 
            $UserName = $env:usernameToJoinDomainWith
            Write-Log "Using username from environment" -Level DEBUG
        }
        
        if ($env:passwordToJoinDomainWithCustomField -and $env:passwordToJoinDomainWithCustomField -notlike "null") {
            try {
                if (Get-Command Ninja-Property-Get -ErrorAction SilentlyContinue) {
                    $Password = Ninja-Property-Get -Name $env:passwordToJoinDomainWithCustomField
                    Write-Log "Retrieved password from secure custom field" -Level DEBUG
                } else {
                    Write-Log "Ninja-Property-Get cmdlet not available" -Level WARN
                }
            } catch {
                Write-Log "Failed to get password from secure custom field: $_" -Level ERROR
                $script:ExitCode = 1
                return
            }
        }
        
        if ($env:serverName -and $env:serverName -notlike "null") { 
            $Server = $env:serverName
            Write-Log "Using server from environment: $Server" -Level DEBUG
        }
        
        if ($env:noRestart) {
            $NoRestart = [System.Convert]::ToBoolean($env:noRestart)
            Write-Log "NoRestart from environment: $NoRestart" -Level DEBUG
        }
        
        if ([string]::IsNullOrWhiteSpace($DomainName)) {
            Write-Log "DomainName parameter is required" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        if ([string]::IsNullOrWhiteSpace($UserName)) {
            Write-Log "UserName parameter is required" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        if ([string]::IsNullOrWhiteSpace($Password)) {
            Write-Log "Password parameter is required" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        Write-Log "Domain: $DomainName" -Level INFO
        Write-Log "Username: $UserName" -Level INFO
        Write-Log "Restart after join: $(-not $NoRestart)" -Level INFO
        
        if ($Server) {
            Write-Log "Target DC: $Server" -Level INFO
        }
        
        Write-Log "Creating domain credentials" -Level DEBUG
        $script:JoinCred = [PSCredential]::new(
            $UserName, 
            $(ConvertTo-SecureString -String $Password -AsPlainText -Force)
        )
        
        Write-Log "Joining computer $env:COMPUTERNAME to domain $DomainName" -Level INFO
        
        $JoinParams = @{
            DomainName = $DomainName
            Credential = $script:JoinCred
            Force = $true
            Confirm = $false
            PassThru = $true
            ErrorAction = 'Stop'
        }
        
        if ($Server) {
            $JoinParams['Server'] = $Server
        }
        
        if (-not $NoRestart) {
            Write-Log "Computer will restart after successful join" -Level WARN
            $JoinParams['Restart'] = $true
            
            Set-NinjaField -FieldName "adDomainJoinStatus" -Value "In Progress"
            Set-NinjaField -FieldName "adDomainName" -Value $DomainName
            Start-Sleep -Seconds 2
        }
        
        $JoinResult = Add-Computer @JoinParams
        
        if ($JoinResult.HasSucceeded) {
            Write-Log "SUCCESS: Computer joined to domain $DomainName" -Level SUCCESS
            
            Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Success"
            Set-NinjaField -FieldName "adDomainName" -Value $DomainName
            Set-NinjaField -FieldName "adJoinDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            if ($NoRestart) {
                Write-Log "MANUAL RESTART REQUIRED to complete domain join" -Level WARN
                Set-NinjaField -FieldName "adRestartPending" -Value "Yes"
            } else {
                Write-Log "Computer will restart now" -Level WARN
                Set-NinjaField -FieldName "adRestartPending" -Value "No"
            }
            
            $script:ExitCode = 0
        } else {
            Write-Log "Add-Computer returned HasSucceeded=False" -Level ERROR
            $script:ExitCode = 1
        }
        
        Write-Log "Domain join operation completed" -Level INFO
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        
        Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Failed"
        Set-NinjaField -FieldName "adJoinDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        $script:ExitCode = 1
    }
}

end {
    try {
        if ($script:JoinCred) { 
            $script:JoinCred = $null 
            Write-Log "Cleared credentials from memory" -Level DEBUG
        }
        
        if ($Password) { 
            $Password = $null
        }
        
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
