#Requires -Version 5.1

<#
.SYNOPSIS
    Reports on certificates expiring within a specified number of days.

.DESCRIPTION
    This script scans the local computer certificate store and identifies certificates that will 
    expire within the specified threshold period. It reports certificate details including subject, 
    thumbprint, issuer, and expiration date to help administrators proactively manage certificate 
    renewals.
    
    Certificate expiration can cause service outages and security issues. Proactive monitoring 
    allows administrators to renew certificates before they expire.

.PARAMETER DaysUntilExpiration
    Number of days threshold for expiration warning. Default: 30 days

.PARAMETER StoreLocation
    Certificate store location to scan. Default: LocalMachine
    Valid values: LocalMachine, CurrentUser

.PARAMETER SaveToCustomField
    Name of a custom field to save the expiring certificates report.

.EXAMPLE
    .\Certificates-GetExpiring.ps1 -DaysUntilExpiration 30
    
    Scanning LocalMachine certificate store for certificates expiring within 30 days...
    Found 2 certificate(s) expiring within 30 days
    
    Subject: CN=webserver.contoso.com | Expires: 03/15/2026 14:30:00

.EXAMPLE
    .\Certificates-GetExpiring.ps1 -DaysUntilExpiration 60 -SaveToCustomField "ExpiringCerts"
    
    Scans for certificates expiring within 60 days and saves report to custom field.

.OUTPUTS
    None. Status information is written to the console and optionally to a custom field.

.NOTES
    File Name      : Certificates-GetExpiring.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
.COMPONENT
    PKI - Public Key Infrastructure certificate management
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/pki/get-childitem

.FUNCTIONALITY
    - Scans LocalMachine or CurrentUser certificate stores
    - Identifies certificates expiring within threshold period
    - Reports certificate subject, thumbprint, issuer, expiration date
    - Can save report to custom fields for monitoring
    - Provides certificate renewal planning data
#>

[CmdletBinding()]
param(
    [Parameter()]
    [int]$DaysUntilExpiration = 30,
    
    [Parameter()]
    [ValidateSet("LocalMachine", "CurrentUser")]
    [string]$StoreLocation = "LocalMachine",
    
    [Parameter()]
    [string]$SaveToCustomField
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Output $logMessage }
        }
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        
        try {
            $CustomField = $Value | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            Write-Log "Failed to set custom field: $_" -Level ERROR
            throw
        }
    }

    if ($env:daysUntilExpiration -and $env:daysUntilExpiration -notlike "null") {
        $DaysUntilExpiration = [int]$env:daysUntilExpiration
    }
    if ($env:storeLocation -and $env:storeLocation -notlike "null") {
        $StoreLocation = $env:storeLocation
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    $ExitCode = 0
    $ExpirationThreshold = (Get-Date).AddDays($DaysUntilExpiration)
}

process {
    try {
        Write-Log "Scanning $StoreLocation certificate store for certificates expiring within $DaysUntilExpiration days..."
        
        $ExpiringCerts = Get-ChildItem -Path "Cert:\$StoreLocation\My" -ErrorAction Stop | Where-Object {
            $_.NotAfter -le $ExpirationThreshold -and $_.NotAfter -ge (Get-Date)
        }

        if ($ExpiringCerts) {
            Write-Log "Found $($ExpiringCerts.Count) certificate(s) expiring within $DaysUntilExpiration days" -Level WARNING
            
            $Report = @()
            foreach ($Cert in $ExpiringCerts) {
                $CertInfo = "Subject: $($Cert.Subject) | Thumbprint: $($Cert.Thumbprint) | Issuer: $($Cert.Issuer) | Expires: $($Cert.NotAfter)"
                Write-Log $CertInfo
                $Report += $CertInfo
            }

            if ($SaveToCustomField) {
                try {
                    $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Log "Report saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Log "Failed to save to custom field: $_" -Level ERROR
                    $ExitCode = 1
                }
            }
            
            $ExitCode = 1
        }
        else {
            Write-Log "No certificates expiring within $DaysUntilExpiration days"
        }
    }
    catch {
        Write-Log "Failed to scan certificates: $_" -Level ERROR
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
