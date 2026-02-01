<#
.SYNOPSIS
    NinjaRMM Script 28: Security Surface Telemetry

.DESCRIPTION
    Analyzes exposed ports, services, and certificates.
    Tracks security attack surface and certificate expiration.

.NOTES
    Frequency: Daily
    Runtime: ~40 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secInternetExposedPortsCount (Integer)
    - secHighRiskServicesExposed (Integer)
    - secSoonExpiringCertsCount (Integer)
    - secSecuritySurfaceSummaryHtml (WYSIWYG)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    # Get listening ports
    $listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue

    # High-risk ports
    $highRiskPorts = @(21, 23, 135, 139, 445, 1433, 3389, 5900)
    $exposedHighRisk = ($listening | Where-Object {
        $_.LocalPort -in $highRiskPorts
    }).Count

    # Check certificates expiring in next 30 days
    $expiringCerts = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
        $_.NotAfter -lt (Get-Date).AddDays(30) -and
        $_.NotAfter -gt (Get-Date)
    }

    $expiringCount = $expiringCerts.Count

    # Update custom fields
    Ninja-Property-Set secInternetExposedPortsCount $listening.Count
    Ninja-Property-Set secHighRiskServicesExposed $exposedHighRisk
    Ninja-Property-Set secSoonExpiringCertsCount $expiringCount

    # Generate HTML summary
    $html = "<h4>Security Surface</h4>"
    $html += "<table>"
    $html += "<tr><td>Total Listening Ports:</td><td>$($listening.Count)</td></tr>"
    $html += "<tr><td>High-Risk Exposed:</td><td style='color:$(if($exposedHighRisk -gt 0){'red'}else{'green'})'>$exposedHighRisk</td></tr>"
    $html += "<tr><td>Expiring Certificates:</td><td>$expiringCount</td></tr>"
    $html += "</table>"

    Ninja-Property-Set secSecuritySurfaceSummaryHtml $html

    Write-Output "Ports: $($listening.Count) | High-Risk: $exposedHighRisk | Certs: $expiringCount"

} catch {
    Write-Output "Error: $_"
    exit 1
}
