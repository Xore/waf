# Script 28: SEC Security Surface Telemetry

**File:** Script_28_SEC_Security_Surface_Telemetry.md  
**Version:** v1.0  
**Script Number:** 28  
**Category:** Advanced Telemetry - Security Surface  
**Last Updated:** February 2, 2026

---

## Purpose

Analyze exposed ports, services, and certificate expiration for security surface monitoring.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~40 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [SECInternetExposedPortsCount](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)
- [SECHighRiskServicesExposed](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)
- [SECSoonExpiringCertsCount](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer)
- SECSecuritySurfaceSummaryHtml (Text/HTML)

---

## PowerShell Implementation

```powershell
# Script 28: Security Surface Telemetry
# Analyzes security exposure

param()

try {
    Write-Output "Starting Security Surface Telemetry (v1.0)"

    # Get listening ports
    $listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue

    # High-risk ports
    $highRiskPorts = @(21, 23, 135, 139, 445, 1433, 3389, 5900)
    $exposedHighRisk = ($listening | Where-Object {
        $_.LocalPort -in $highRiskPorts
    }).Count

    # Check certificates expiring in next 30 days
    $expiringCerts = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object {
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

    Write-Output "SUCCESS: Security surface analysis completed"
    Write-Output "  Total Listening Ports: $($listening.Count)"
    Write-Output "  High-Risk Services Exposed: $exposedHighRisk"
    Write-Output "  Expiring Certificates (30d): $expiringCount"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [SEC Security Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [Script 04: Security Analyzer](Script_04_OPS_Security_Analyzer.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_28_SEC_Security_Surface_Telemetry.md  
**Version:** v1.0  
**Status:** Production Ready
