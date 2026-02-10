#Requires -Version 5.1

<#
.SYNOPSIS
    Alerts when local certificates will expire within a configurable timeframe.

.DESCRIPTION
    This script scans all local certificate stores and alerts when certificates will expire 
    within the specified number of days. It can optionally ignore self-signed certificates, 
    certificates that have been expired for a long time, and certificates that were only 
    valid for an extremely short time frame.
    
    This helps administrators proactively manage certificate renewals and avoid service 
    disruptions caused by expired certificates.

.PARAMETER ExpirationFromCustomField
    Name of custom field to retrieve expiration days threshold from.
    Default: certExpirationAlertDays

.PARAMETER DaysUntilExpiration
    Number of days threshold for expiration warning. Default: 30 days

.PARAMETER MustBeValidBefore
    Only alert on certificates older than X days. Default: 2 days
    This silences alerts about certificates only valid for 24 hours.

.PARAMETER Cutoff
    Don't alert on certificates expired for longer than X days. Default: 91 days

.PARAMETER IgnoreSelfSignedCerts
    Ignore certificates where subject and issuer are identical.

.EXAMPLE
    .\Certificates-LocalExpirationAlert.ps1
    
    Checking for certificates expiring within 30 days...
    No certificates found expiring within threshold

.EXAMPLE
    .\Certificates-LocalExpirationAlert.ps1 -DaysUntilExpiration 366 -IgnoreSelfSignedCerts
    
    Checks for certificates expiring within 1 year, ignoring self-signed certs

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : Certificates-LocalExpirationAlert.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/pki/
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$ExpirationFromCustomField = "certExpirationAlertDays",
    
    [Parameter()]
    [int]$DaysUntilExpiration = 30,
    
    [Parameter()]
    [int]$MustBeValidBefore = 2,
    
    [Parameter()]
    [int]$Cutoff = 91,
    
    [Parameter()]
    [Switch]$IgnoreSelfSignedCerts
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

    function Test-IsElevated {
        <#
        .SYNOPSIS
            Tests if script is running with administrator privileges.
        #>
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($env:expirationFromCustomFieldName -and $env:expirationFromCustomFieldName -notlike "null") { 
        $ExpirationFromCustomField = $env:expirationFromCustomFieldName 
    }
    if ($env:daysUntilExpiration -and $env:daysUntilExpiration -notlike "null") { 
        $DaysUntilExpiration = $env:daysUntilExpiration 
    }
    if ($env:certificateMustBeOlderThanXDays -and $env:certificateMustBeOlderThanXDays -notlike "null") { 
        $MustBeValidBefore = $env:certificateMustBeOlderThanXDays 
    }
    if ($env:skipCertsExpiredForMoreThanXDays -and $env:skipCertsExpiredForMoreThanXDays -notlike "null") { 
        $Cutoff = $env:skipCertsExpiredForMoreThanXDays 
    }
    if ($env:ignoreSelfSignedCerts -and $env:ignoreSelfSignedCerts -notlike "null") {
        $IgnoreSelfSignedCerts = [System.Convert]::ToBoolean($env:ignoreSelfSignedCerts)
    }

    try {
        $CustomField = Ninja-Property-Get -Name $ExpirationFromCustomField 2>$null
        if ($CustomField -and $DaysUntilExpiration -eq 30 -and (Test-IsElevated)) {
            Write-Log "Retrieved value of $CustomField days from Custom Field $ExpirationFromCustomField"
            $DaysUntilExpiration = $CustomField
        }
    }
    catch {
        Write-Log "Unable to retrieve custom field value: $_" -Level WARNING
    }

    $ExitCode = 0
}

process {
    try {
        $ExpirationDate = (Get-Date "11:59pm").AddDays($DaysUntilExpiration)
        $CutoffDate = (Get-Date "12am").AddDays(-$Cutoff)
        $MustBeValidBeforeDate = (Get-Date "12am").AddDays(-$MustBeValidBefore)

        Write-Log "Checking for certificates valid before $MustBeValidBeforeDate and expiring before $ExpirationDate"
        
        $Certificates = Get-ChildItem -Path "Cert:\" -Recurse -ErrorAction SilentlyContinue
        
        $ExpiredCertificates = $Certificates | Where-Object { 
            $_.NotAfter -le $ExpirationDate -and 
            $_.NotAfter -gt $CutoffDate -and 
            $_.NotBefore -lt $MustBeValidBeforeDate 
        }

        if ($IgnoreSelfSignedCerts -and $ExpiredCertificates) {
            Write-Log "Removing self-signed certificates from list"
            $ExpiredCertificates = $ExpiredCertificates | Where-Object { $_.Subject -ne $_.Issuer }
        }

        if ($ExpiredCertificates) {
            Write-Log "Expired certificates found!" -Level WARNING

            $Report = $ExpiredCertificates | ForEach-Object {
                [PSCustomObject]@{
                    SerialNumber   = $_.SerialNumber
                    HasPrivateKey  = $_.HasPrivateKey
                    ExpirationDate = $_.NotAfter
                    Subject        = if ($_.Subject.Length -gt 35) { $_.Subject.Substring(0, 35) + "..." } else { $_.Subject }
                }
            }

            Write-Log "Expired Certificates:"
            $Report | Format-Table -AutoSize | Out-String | Write-Log

            $ExitCode = 1
        }
        else {
            Write-Log "No certificates found expiring before $ExpirationDate and after $CutoffDate"
        }
    }
    catch {
        Write-Log "Failed to check certificate expiration: $_" -Level ERROR
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
