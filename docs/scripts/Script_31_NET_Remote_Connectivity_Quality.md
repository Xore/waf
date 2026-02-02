# Script 31: NET Remote Connectivity and SaaS Quality Telemetry

**File:** Script_31_NET_Remote_Connectivity_Quality.md  
**Version:** v1.0  
**Script Number:** 31  
**Category:** Advanced Telemetry - Network Quality  
**Last Updated:** February 2, 2026

---

## Purpose

Monitor VPN, WiFi, and SaaS connectivity quality and performance.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [NETWiFiDisconnects24h](../core/13_NET_GPO_AD_Core_Network_Identity.md) (Integer)
- [NETVPNAverageLatencyMs](../core/13_NET_GPO_AD_Core_Network_Identity.md) (Integer)
- CAPSaaSLatencyCategory (Dropdown: Unknown, Excellent, Good, Fair, Poor)

---

## PowerShell Implementation

```powershell
# Script 31: Remote Connectivity and SaaS Quality
# Monitors connectivity quality

param()

try {
    Write-Output "Starting Remote Connectivity Quality Monitor (v1.0)"

    $startTime = (Get-Date).AddHours(-24)

    # Check WiFi disconnects
    $wifiDisconnects = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ProviderName = 'Microsoft-Windows-WLAN-AutoConfig'
        ID = 8003
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $disconnectCount = $wifiDisconnects.Count

    # Test VPN latency (if VPN adapter exists)
    $vpnAdapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -match "VPN|Cisco|Palo Alto|FortiClient|GlobalProtect|Pulse"
    }

    $vpnLatency = 0
    if ($vpnAdapter -and $vpnAdapter.Status -eq 'Up') {
        # Get default gateway
        $gateway = (Get-NetRoute -InterfaceIndex $vpnAdapter.InterfaceIndex -ErrorAction SilentlyContinue | 
            Where-Object {$_.DestinationPrefix -eq '0.0.0.0/0'}).NextHop

        if ($gateway) {
            $ping = Test-Connection -ComputerName $gateway -Count 4 -ErrorAction SilentlyContinue
            if ($ping) {
                $vpnLatency = [int]($ping | Measure-Object -Property ResponseTime -Average).Average
            }
        }
    }

    # Test SaaS endpoints (Office 365)
    $saasTest = Test-Connection -ComputerName "outlook.office365.com" -Count 4 -ErrorAction SilentlyContinue
    $saasLatency = 0
    if ($saasTest) {
        $saasLatency = [int]($saasTest | Measure-Object -Property ResponseTime -Average).Average
    }

    # Categorize SaaS latency
    if ($saasLatency -eq 0) {
        $category = "Unknown"
    } elseif ($saasLatency -lt 50) {
        $category = "Excellent"
    } elseif ($saasLatency -lt 100) {
        $category = "Good"
    } elseif ($saasLatency -lt 200) {
        $category = "Fair"
    } else {
        $category = "Poor"
    }

    # Update fields
    Ninja-Property-Set netWiFiDisconnects24h $disconnectCount
    Ninja-Property-Set netVPNAverageLatencyMs $vpnLatency
    Ninja-Property-Set capSaaSLatencyCategory $category

    Write-Output "SUCCESS: Connectivity quality analysis completed"
    Write-Output "  WiFi Disconnects (24h): $disconnectCount"
    Write-Output "  VPN Latency: $vpnLatency ms"
    Write-Output "  SaaS Latency: $saasLatency ms ($category)"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [NET Network Fields](../core/13_NET_GPO_AD_Core_Network_Identity.md)
- [Script 11: Network Location Tracker](Script_11_NET_Location_Tracker.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_31_NET_Remote_Connectivity_Quality.md  
**Version:** v1.0  
**Status:** Production Ready
