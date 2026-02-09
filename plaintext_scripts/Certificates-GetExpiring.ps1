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
    -DaysUntilExpiration 30

    [Info] Scanning LocalMachine certificate store for certificates expiring within 30 days...
    [Alert] Found 2 certificate(s) expiring within 30 days
    
    Subject: CN=webserver.contoso.com
    Thumbprint: A1B2C3D4E5F6...
    Issuer: CN=Contoso CA
    Expires: 03/15/2026 14:30:00

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    
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
    [int]$DaysUntilExpiration = 30,
    [ValidateSet("LocalMachine", "CurrentUser")]
    [string]$StoreLocation = "LocalMachine",
    [string]$SaveToCustomField
)

begin {
    if ($env:daysUntilExpiration -and $env:daysUntilExpiration -notlike "null") {
        $DaysUntilExpiration = [int]$env:daysUntilExpiration
    }
    if ($env:storeLocation -and $env:storeLocation -notlike "null") {
        $StoreLocation = $env:storeLocation
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        $NinjaValue = $Value
        $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $ExitCode = 0
    $ExpirationThreshold = (Get-Date).AddDays($DaysUntilExpiration)
}

process {
    try {
        Write-Host "[Info] Scanning $StoreLocation certificate store for certificates expiring within $DaysUntilExpiration days..."
        
        $ExpiringCerts = Get-ChildItem -Path "Cert:\$StoreLocation\My" -ErrorAction Stop | Where-Object {
            $_.NotAfter -le $ExpirationThreshold -and $_.NotAfter -ge (Get-Date)
        }

        if ($ExpiringCerts) {
            Write-Host "[Alert] Found $($ExpiringCerts.Count) certificate(s) expiring within $DaysUntilExpiration days`n"
            
            $Report = @()
            foreach ($Cert in $ExpiringCerts) {
                $CertInfo = "Subject: $($Cert.Subject) | Thumbprint: $($Cert.Thumbprint) | Issuer: $($Cert.Issuer) | Expires: $($Cert.NotAfter)"
                Write-Host $CertInfo
                $Report += $CertInfo
            }

            if ($SaveToCustomField) {
                try {
                    $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Host "`n[Info] Report saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Host "[Error] Failed to save to custom field: $_"
                    $ExitCode = 1
                }
            }
            
            $ExitCode = 1
        }
        else {
            Write-Host "[Info] No certificates expiring within $DaysUntilExpiration days"
        }
    }
    catch {
        Write-Host "[Error] Failed to scan certificates: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
