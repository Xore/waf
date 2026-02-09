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
    Script Name:    AD-JoinComputerToDomain.ps1
    Author:         Windows Automation Framework
    Version:        2.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand
    Typical Duration: ~8-15 seconds (measured average, excluding restart)
    Timeout Setting: 300 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: Restarts ONLY if NoRestart switch is NOT provided
    
    Fields Updated:
        - adDomainJoinStatus (Success/Failed)
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

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "2.0"
$ScriptName = "AD-JoinComputerToDomain"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

# ============================================================================
# FUNCTIONS
# ============================================================================

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

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check environment variable overrides
    if ($env:domainToJoin -and $env:domainToJoin -notlike "null") { 
        $DomainName = $env:domainToJoin 
    }
    if ($env:usernameToJoinDomainWith -and $env:usernameToJoinDomainWith -notlike "null") { 
        $UserName = $env:usernameToJoinDomainWith
    }
    if ($env:passwordToJoinDomainWithCustomField -and $env:passwordToJoinDomainWithCustomField -notlike "null") {
        try {
            if (Get-Command Ninja-Property-Get -ErrorAction SilentlyContinue) {
                $Password = Ninja-Property-Get -Name $env:passwordToJoinDomainWithCustomField
                Write-Log "Retrieved password from secure custom field" -Level DEBUG
            }
        } catch {
            Write-Log "Failed to get password from secure custom field" -Level ERROR
            throw "Failed to retrieve password from custom field"
        }
    }
    if ($env:serverName -and $env:serverName -notlike "null") { 
        $Server = $env:serverName 
    }
    if ($env:noRestart) {
        $NoRestart = [System.Convert]::ToBoolean($env:noRestart)
    }
    
    # Validate required parameters
    if ([string]::IsNullOrWhiteSpace($DomainName)) {
        throw "DomainName parameter is required"
    }
    if ([string]::IsNullOrWhiteSpace($UserName)) {
        throw "UserName parameter is required"
    }
    if ([string]::IsNullOrWhiteSpace($Password)) {
        throw "Password parameter is required"
    }
    
    Write-Log "Domain: $DomainName" -Level INFO
    Write-Log "Username: $UserName" -Level INFO
    Write-Log "Restart after join: $(-not $NoRestart)" -Level INFO
    if ($Server) {
        Write-Log "Target DC: $Server" -Level INFO
    }
    
    # Create credential object
    Write-Log "Creating domain credentials" -Level DEBUG
    $JoinCred = [PSCredential]::new($UserName, $(ConvertTo-SecureString -String $Password -AsPlainText -Force))
    
    # Join domain
    Write-Log "Joining computer $env:COMPUTERNAME to domain $DomainName" -Level INFO
    
    $JoinParams = @{
        DomainName = $DomainName
        Credential = $JoinCred
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
        
        # Set fields before restart
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
    } else {
        throw "Add-Computer returned HasSucceeded=False"
    }
    
    Write-Log "Domain join operation completed" -Level INFO
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Failed"
    Set-NinjaField -FieldName "adJoinDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    exit 1
    
} finally {
    # Clear credentials from memory
    if ($JoinCred) { $JoinCred = $null }
    if ($Password) { $Password = $null }
    
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}

if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
