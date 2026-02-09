<#
.SYNOPSIS
    Join a Windows computer to an Active Directory domain

.DESCRIPTION
    Joins the local computer to an Active Directory domain using provided credentials.
    Requires domain name, username, and password as environment variables.
    Supports optional restart parameter.

.PARAMETER AllowRestart
    If specified, allows the computer to restart after successful domain join.
    Default: False (no restart)

.EXAMPLE
    # Join domain without restart (manual restart required)
    .\AD-JoinDomain.ps1

.EXAMPLE
    # Join domain with automatic restart
    .\AD-JoinDomain.ps1 -AllowRestart

.NOTES
    Author: WAF Team
    Version: 2.0
    Requires: Administrator privileges
    Environment Variables Required:
        - $env:user (domain username)
        - $env:pass (domain password)
        - $env:domain (domain name)

.LINK
    https://github.com/Xore/waf
#>

param(
    [switch]$AllowRestart = $false
)

# Phase 2: Execution time tracking
$StartTime = Get-Date

# Phase 1 & 3: Write-Log function for plain text output
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Output "[$Timestamp] [$Level] $Message"
}

try {
    Write-Log "Starting domain join process" -Level INFO
    
    # Phase 3: Input validation
    if ([string]::IsNullOrWhiteSpace($env:user)) {
        throw "Environment variable 'user' is not set or empty"
    }
    
    if ([string]::IsNullOrWhiteSpace($env:pass)) {
        throw "Environment variable 'pass' is not set or empty"
    }
    
    if ([string]::IsNullOrWhiteSpace($env:domain)) {
        throw "Environment variable 'domain' is not set or empty"
    }
    
    Write-Log "Domain: $env:domain" -Level INFO
    Write-Log "Username: $env:user" -Level INFO
    
    # Create credentials
    Write-Log "Creating domain credentials" -Level DEBUG
    $SecurePassword = ConvertTo-SecureString -String $env:pass -AsPlainText -Force
    $JoinCred = [PSCredential]::new($env:user, $SecurePassword)
    
    # Phase 1: Unattended operation - check restart parameter
    if ($AllowRestart) {
        Write-Log "Joining domain with automatic restart enabled" -Level INFO
        $Result = Add-Computer -DomainName $env:domain -Credential $JoinCred -PassThru -Force -ErrorAction Stop -Restart
        Write-Log "SUCCESS: Domain join initiated, computer will restart" -Level SUCCESS
    }
    else {
        Write-Log "Joining domain without automatic restart" -Level INFO
        $Result = Add-Computer -DomainName $env:domain -Credential $JoinCred -PassThru -Force -ErrorAction Stop
        
        if ($Result) {
            Write-Log "SUCCESS: Computer joined to domain '$env:domain'" -Level SUCCESS
            Write-Log "MANUAL RESTART REQUIRED to complete domain join" -Level WARN
            Write-Log "Use -AllowRestart parameter to restart automatically" -Level INFO
        }
    }
    
    exit 0
}
catch {
    Write-Log "ERROR: Failed to join domain - $($_.Exception.Message)" -Level ERROR
    Write-Log "Verify credentials, domain name, and network connectivity" -Level ERROR
    exit 1
}
finally {
    # Phase 2: Log execution time
    $Duration = (Get-Date) - $StartTime
    Write-Log "Script execution completed in $($Duration.TotalSeconds.ToString('F2')) seconds" -Level INFO
}
