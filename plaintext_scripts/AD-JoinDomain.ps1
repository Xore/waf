#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Join a Windows computer to an Active Directory domain

.DESCRIPTION
    Joins the local computer to an Active Directory domain using provided credentials.
    Credentials must be supplied via environment variables (typically from NinjaRMM).
    
    The script performs the following:
    - Validates required environment variables
    - Creates secure credential object
    - Joins computer to specified domain
    - Optionally restarts computer if authorized
    - Updates NinjaRMM custom fields with join status
    
    This script runs unattended without user interaction.

.PARAMETER AllowRestart
    Authorizes the computer to restart after successful domain join.
    Without this parameter, script will complete join but require manual restart.
    Default: False (manual restart required)

.EXAMPLE
    .\AD-JoinDomain.ps1
    
    Joins computer to domain specified in environment variables.
    Requires manual restart to complete domain join.

.EXAMPLE
    .\AD-JoinDomain.ps1 -AllowRestart
    
    Joins computer to domain and automatically restarts.

.NOTES
    File Name      : AD-JoinDomain.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced logging and credential handling
    - 2.0: Added NinjaRMM integration
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand
    Typical Duration: 8-12 seconds
    Timeout Setting: 300 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: Never restarts unless -AllowRestart parameter provided
    
    NinjaRMM Fields Updated:
        - adDomainJoinStatus (Success/Failed)
        - adDomainName (domain name)
        - adRestartRequired (Yes/No)
        - adRestartInitiated (Yes/No if restarted)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Network connectivity to domain controller
    
    Environment Variables Required:
        - user: Domain administrator username
        - pass: Domain administrator password
        - domain: Target domain name (e.g., contoso.com)
    
    Exit Codes:
        0 - Success (domain join completed)
        1 - Failure (validation or join failure)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Authorize automatic restart after domain join")]
    [switch]$AllowRestart = $false
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "AD-JoinDomain"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:CLIFallbackCount = 0
    
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $script:JoinCred = $null
    $script:SecurePassword = $null

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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        Write-Log "Validating environment variables" -Level INFO
        
        if ([string]::IsNullOrWhiteSpace($env:user)) {
            throw "Environment variable 'user' is not set or empty"
        }
        
        if ([string]::IsNullOrWhiteSpace($env:pass)) {
            throw "Environment variable 'pass' is not set or empty"
        }
        
        if ([string]::IsNullOrWhiteSpace($env:domain)) {
            throw "Environment variable 'domain' is not set or empty"
        }
        
        Write-Log "Configuration:" -Level INFO
        Write-Log "  Domain: $env:domain" -Level INFO
        Write-Log "  Username: $env:user" -Level INFO
        Write-Log "  Restart Authorized: $AllowRestart" -Level INFO
        
        Write-Log "Creating domain credentials" -Level DEBUG
        $script:SecurePassword = ConvertTo-SecureString -String $env:pass -AsPlainText -Force
        $script:JoinCred = [PSCredential]::new($env:user, $script:SecurePassword)
        
        if ($AllowRestart) {
            Write-Log "Joining domain with automatic restart enabled" -Level INFO
            Write-Log "Computer will restart upon successful join" -Level WARN
            
            Set-NinjaField -FieldName "adDomainName" -Value $env:domain
            Set-NinjaField -FieldName "adRestartInitiated" -Value "Yes"
            Start-Sleep -Seconds 2
            
            $Result = Add-Computer -DomainName $env:domain -Credential $script:JoinCred -PassThru -Force -ErrorAction Stop -Restart
            
            Write-Log "Domain join initiated, computer will restart" -Level SUCCESS
            Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Success"
            
        } else {
            Write-Log "Joining domain without automatic restart" -Level INFO
            $Result = Add-Computer -DomainName $env:domain -Credential $script:JoinCred -PassThru -Force -ErrorAction Stop
            
            if ($Result) {
                Write-Log "Computer joined to domain successfully" -Level SUCCESS
                Write-Log "Domain: $env:domain" -Level INFO
                Write-Log "MANUAL RESTART REQUIRED to complete domain join" -Level WARN
                Write-Log "Use -AllowRestart parameter for automatic restart" -Level INFO
                
                Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Success"
                Set-NinjaField -FieldName "adDomainName" -Value $env:domain
                Set-NinjaField -FieldName "adRestartRequired" -Value "Yes"
                Set-NinjaField -FieldName "adRestartInitiated" -Value "No"
            }
        }
        
        Write-Log "Domain join operation completed" -Level INFO
        $script:ExitCode = 0
        
    } catch {
        Write-Log "Failed to join domain: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        Write-Log "Verify credentials, domain name, and network connectivity" -Level ERROR
        
        Set-NinjaField -FieldName "adDomainJoinStatus" -Value "Failed"
        Set-NinjaField -FieldName "adDomainName" -Value $env:domain
        
        $script:ExitCode = 1
    }
}

end {
    try {
        if ($null -ne $script:JoinCred) {
            $script:JoinCred = $null
            Write-Log "Credential object cleared" -Level DEBUG
        }
        
        if ($null -ne $script:SecurePassword) {
            $script:SecurePassword.Dispose()
            $script:SecurePassword = $null
            Write-Log "SecureString disposed" -Level DEBUG
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
