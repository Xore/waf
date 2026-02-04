<#
.SYNOPSIS
    Security Surface Telemetry - Attack Surface Analysis and Monitoring

.DESCRIPTION
    Analyzes exposed network ports, services, and certificate health to identify potential
    security vulnerabilities and attack surface exposure. Monitors listening TCP ports with
    special attention to high-risk services commonly targeted by attackers.
    
    Tracks certificate expiration to prevent service disruptions from expired certificates.
    Provides HTML-formatted summary of security posture with color-coded risk indicators
    for quick visual assessment of exposure levels.
    
    High-risk ports monitored:
    - 21 (FTP) - Unencrypted file transfer
    - 23 (Telnet) - Unencrypted remote access
    - 135 (RPC) - Windows RPC endpoint mapper
    - 139 (NetBIOS) - Legacy NetBIOS session service
    - 445 (SMB) - Direct SMB file sharing
    - 1433 (SQL Server) - Database exposure
    - 3389 (RDP) - Remote Desktop
    - 5900 (VNC) - VNC remote access

.NOTES
    Frequency: Daily
    Runtime: ~40 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secInternetExposedPortsCount (Integer: total listening TCP ports)
    - secHighRiskServicesExposed (Integer: count of high-risk ports listening)
    - secSoonExpiringCertsCount (Integer: certificates expiring within 30 days)
    - secSecuritySurfaceSummaryHtml (WYSIWYG: HTML formatted security summary)
    
    Dependencies:
    - Get-NetTCPConnection cmdlet (Windows PowerShell 5.1+)
    - Access to LocalMachine certificate store
    
    Security Considerations:
    - High-risk port detection helps identify unnecessary service exposure
    - Certificate monitoring prevents service disruptions
    - Regular scanning enables trend analysis of attack surface changes
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Security Surface Telemetry (v4.0)..."
    
    # Get all listening TCP ports
    Write-Output "INFO: Scanning listening TCP ports..."
    $listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
    
    if (-not $listening) {
        Write-Output "WARNING: No listening ports detected (this is unusual)"
        $listening = @()
    } else {
        Write-Output "INFO: Found $($listening.Count) listening ports"
    }

    # Define high-risk ports commonly targeted by attackers
    $highRiskPorts = @(21, 23, 135, 139, 445, 1433, 3389, 5900)
    
    # Count exposed high-risk services
    $exposedHighRisk = ($listening | Where-Object {
        $_.LocalPort -in $highRiskPorts
    }).Count
    
    if ($exposedHighRisk -gt 0) {
        Write-Output "WARNING: $exposedHighRisk high-risk port(s) are listening"
        $listening | Where-Object { $_.LocalPort -in $highRiskPorts } | ForEach-Object {
            Write-Output "  - Port $($_.LocalPort) is listening"
        }
    } else {
        Write-Output "INFO: No high-risk ports are listening (good security posture)"
    }

    # Check certificates expiring in next 30 days
    Write-Output "INFO: Checking certificate expiration..."
    try {
        $expiringCerts = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction Stop | Where-Object {
            $_.NotAfter -lt (Get-Date).AddDays(30) -and
            $_.NotAfter -gt (Get-Date)
        }
        
        $expiringCount = $expiringCerts.Count
        
        if ($expiringCount -gt 0) {
            Write-Output "WARNING: $expiringCount certificate(s) expiring within 30 days"
            $expiringCerts | ForEach-Object {
                Write-Output "  - $($_.Subject) expires: $($_.NotAfter.ToString('yyyy-MM-dd'))"
            }
        } else {
            Write-Output "INFO: No certificates expiring within 30 days"
        }
    } catch {
        Write-Output "WARNING: Failed to check certificates: $_"
        $expiringCount = 0
    }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating security surface metrics..."
    Ninja-Property-Set secInternetExposedPortsCount $listening.Count
    Ninja-Property-Set secHighRiskServicesExposed $exposedHighRisk
    Ninja-Property-Set secSoonExpiringCertsCount $expiringCount

    # Generate HTML summary with color-coded risk indicators
    $html = "<div style='font-family: Arial, sans-serif;'>"
    $html += "<h4 style='margin-bottom: 10px;'>Security Surface Analysis</h4>"
    $html += "<table style='border-collapse: collapse; width: 100%;'>"
    $html += "<tr style='border-bottom: 1px solid #ddd;'>"
    $html += "<td style='padding: 8px;'>Total Listening Ports:</td>"
    $html += "<td style='padding: 8px; font-weight: bold;'>$($listening.Count)</td>"
    $html += "</tr>"
    $html += "<tr style='border-bottom: 1px solid #ddd;'>"
    $html += "<td style='padding: 8px;'>High-Risk Services Exposed:</td>"
    $html += "<td style='padding: 8px; font-weight: bold; color: $(if($exposedHighRisk -gt 0){'red'}else{'green'})'>$exposedHighRisk</td>"
    $html += "</tr>"
    $html += "<tr style='border-bottom: 1px solid #ddd;'>"
    $html += "<td style='padding: 8px;'>Certificates Expiring Soon:</td>"
    $html += "<td style='padding: 8px; font-weight: bold; color: $(if($expiringCount -gt 0){'orange'}else{'green'})'>$expiringCount</td>"
    $html += "</tr>"
    $html += "</table>"
    $html += "<p style='font-size: 0.85em; color: #666; margin-top: 10px;'>Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')</p>"
    $html += "</div>"

    Ninja-Property-Set secSecuritySurfaceSummaryHtml $html

    Write-Output "SUCCESS: Security surface telemetry complete"
    Write-Output "SUMMARY: Ports: $($listening.Count) | High-Risk: $exposedHighRisk | Expiring Certs: $expiringCount"
    
    exit 0

} catch {
    Write-Output "ERROR: Security Surface Telemetry failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
