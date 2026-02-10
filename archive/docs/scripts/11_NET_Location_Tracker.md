# Script 11: NET Network Location Tracker

**File:** Script_11_NET_Location_Tracker.md  
**Version:** v1.0  
**Script Number:** 11  
**Category:** Core Monitoring - Network Location  
**Last Updated:** February 2, 2026

---

## Purpose

Track network location changes for network-aware policy application.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~10 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [NETLocationCurrent](../core/13_NET_GPO_AD_Core_Network_Identity.md) (Dropdown: Office, Remote, Unknown)
- [NETLocationPrevious](../core/13_NET_GPO_AD_Core_Network_Identity.md) (Dropdown: Office, Remote, Unknown)
- [NETVPNConnected](../core/13_NET_GPO_AD_Core_Network_Identity.md) (Checkbox)

---

## Use Cases

- Apply different security policies based on location
- Track device movement for security monitoring
- VPN compliance enforcement for remote users

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Network Location Tracker (v1.0)"

    # Get previous location
    $previousLocation = Ninja-Property-Get NETLocationCurrent
    if ([string]::IsNullOrEmpty($previousLocation)) { $previousLocation = "Unknown" }

    # Detect VPN connection
    $vpnConnected = $false
    $vpnAdapters = Get-NetAdapter | Where-Object { 
        $_.InterfaceDescription -match "VPN|Virtual|Cisco|Pulse|GlobalProtect" -and 
        $_.Status -eq "Up" 
    }
    if ($vpnAdapters) {
        $vpnConnected = $true
    }

    # Detect current location based on network characteristics
    $currentLocation = "Unknown"
    
    # Check for domain connection (likely office)
    $domain = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    if ($domain) {
        # Check if can reach domain controller
        $dc = $env:LOGONSERVER
        if ($dc -and (Test-Connection -ComputerName $dc.TrimStart("\\") -Count 1 -Quiet)) {
            $currentLocation = "Office"
        }
    }

    # If VPN connected but not on domain network, likely remote
    if ($vpnConnected -and $currentLocation -eq "Unknown") {
        $currentLocation = "Remote"
    }

    # Check default gateway to detect corporate network
    if ($currentLocation -eq "Unknown") {
        $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | 
            Where-Object { $_.NextHop -ne "0.0.0.0" } | 
            Select-Object -First 1).NextHop
        
        # Example: Check if gateway is in corporate IP range (customize for your network)
        if ($gateway -match "^10\." -or $gateway -match "^192\.168\.1\." -or $gateway -match "^172\.(1[6-9]|2[0-9]|3[01])\." ) {
            $currentLocation = "Office"
        } else {
            $currentLocation = "Remote"
        }
    }

    # Update fields
    Ninja-Property-Set NETLocationPrevious $previousLocation
    Ninja-Property-Set NETLocationCurrent $currentLocation
    Ninja-Property-Set NETVPNConnected $vpnConnected

    Write-Output "SUCCESS: Location tracking completed"
    Write-Output "  Previous Location: $previousLocation"
    Write-Output "  Current Location: $currentLocation"
    Write-Output "  VPN Connected: $vpnConnected"

    # Alert on location change
    if ($previousLocation -ne $currentLocation -and $previousLocation -ne "Unknown") {
        Write-Output "ALERT: Location changed from $previousLocation to $currentLocation"
    }

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [NET Network Fields](../core/13_NET_GPO_AD_Core_Network_Identity.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_11_NET_Location_Tracker.md  
**Version:** v1.0  
**Status:** Production Ready
