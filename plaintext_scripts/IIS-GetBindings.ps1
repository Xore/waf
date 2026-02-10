#Requires -Version 5.1 -Modules WebAdministration

<#
.SYNOPSIS
    Retrieves IIS website bindings and SSL certificate information.

.DESCRIPTION
    This script queries all IIS websites and reports their HTTP/HTTPS bindings including hostname, 
    port, IP address, and SSL certificate details. This information is useful for inventory, 
    troubleshooting, and SSL certificate management.
    
    IIS binding information is critical for understanding web server configuration, identifying 
    port conflicts, and managing SSL certificates before they expire.

.PARAMETER IncludeCertificateDetails
    If specified, includes SSL certificate subject and expiration date for HTTPS bindings.

.PARAMETER SaveToCustomField
    Name of a custom field to save the bindings report.

.EXAMPLE
    No Parameters

    [Info] Retrieving IIS website bindings...
    Site: Default Web Site | Protocol: http | Binding: *:80:
    Site: Corporate Portal | Protocol: https | Binding: *:443:portal.contoso.com
    [Info] Found 2 website(s) with 2 total binding(s)

.EXAMPLE
    -IncludeCertificateDetails

    [Info] Retrieving IIS website bindings with certificate details...
    Site: Corporate Portal | Protocol: https | Binding: *:443:portal.contoso.com
    SSL Certificate: CN=portal.contoso.com | Expires: 03/15/2026

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2
    Release notes: 3.0.0 - Upgraded to V3.0.0 standards (script-scoped exit code)
    Requires: IIS role and WebAdministration PowerShell module
    
.COMPONENT
    WebAdministration - IIS management module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/webadministration/

.FUNCTIONALITY
    - Queries all IIS websites
    - Retrieves HTTP and HTTPS bindings
    - Reports protocol, IP, port, and hostname
    - Optionally includes SSL certificate details
    - Can save bindings report to custom fields
    - Useful for SSL certificate inventory and expiration tracking
#>

[CmdletBinding()]
param(
    [switch]$IncludeCertificateDetails,
    [string]$SaveToCustomField
)

begin {
    if ($env:includeCertificateDetails -eq "true") {
        $IncludeCertificateDetails = $true
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

    $script:ExitCode = 0
}

process {
    try {
        if ($IncludeCertificateDetails) {
            Write-Host "[Info] Retrieving IIS website bindings with certificate details..."
        }
        else {
            Write-Host "[Info] Retrieving IIS website bindings..."
        }
        
        $Websites = Get-Website -ErrorAction Stop

        if (-not $Websites) {
            Write-Host "[Info] No IIS websites configured on this server"
            exit 0
        }

        $Report = @()
        $TotalBindings = 0

        foreach ($Site in $Websites) {
            foreach ($Binding in $Site.Bindings.Collection) {
                $TotalBindings++
                $BindingInfo = "Site: $($Site.Name) | Protocol: $($Binding.protocol) | Binding: $($Binding.bindingInformation)"
                Write-Host $BindingInfo
                $Report += $BindingInfo

                if ($IncludeCertificateDetails -and $Binding.protocol -eq "https") {
                    $CertHash = $Binding.certificateHash
                    if ($CertHash) {
                        $Cert = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertHash" -ErrorAction SilentlyContinue
                        if ($Cert) {
                            $CertInfo = "  SSL Certificate: $($Cert.Subject) | Expires: $($Cert.NotAfter)"
                            Write-Host $CertInfo
                            $Report += $CertInfo
                        }
                    }
                }
            }
        }

        Write-Host "`n[Info] Found $($Websites.Count) website(s) with $TotalBindings total binding(s)"

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Report saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $script:ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to retrieve IIS bindings: $_"
        $script:ExitCode = 1
    }

    exit $script:ExitCode
}

end {
    [System.GC]::Collect()
}
