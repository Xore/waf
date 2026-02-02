#!/usr/bin/env pwsh
# Script 11: Network Location Tracker
# Purpose: Track network location changes for network-aware policy application
# Frequency: Every 4 hours
# Runtime: ~10 seconds
# Timeout: 60 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Network Location Tracker (v4.0 Native-Enhanced)"

    $currentLocation = Ninja-Property-Get NETLocationCurrent
    if ([string]::IsNullOrEmpty($currentLocation)) { $currentLocation = "Unknown" }

    $vpnAdapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'VPN|Cisco|Palo Alto|FortiClient|OpenVPN' -and $_.Status -eq 'Up' }
    $vpnConnected = $vpnAdapters.Count -gt 0

    $gateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1 -ExpandProperty NextHop
    
    $newLocation = "Unknown"
    if ($gateway) {
        if ($gateway -match '^10\\.' -or $gateway -match '^172\\.(1[6-9]|2[0-9]|3[0-1])\\.' -or $gateway -match '^192\\.168\\.') {
            if ($vpnConnected) {
                $newLocation = "Remote"
            } else {
                $pingResult = Test-Connection -ComputerName $gateway -Count 1 -Quiet
                if ($pingResult) {
                    $newLocation = "Office"
                } else {
                    $newLocation = "Unknown"
                }
            }
        } else {
            $newLocation = "Remote"
        }
    }

    if ($newLocation -ne $currentLocation -and $currentLocation -ne "Unknown") {
        Ninja-Property-Set NETLocationPrevious $currentLocation
    }

    Ninja-Property-Set NETLocationCurrent $newLocation
    Ninja-Property-Set NETVPNConnected $vpnConnected

    Write-Output "SUCCESS: Network location tracked"
    Write-Output "  Current Location: $newLocation"
    Write-Output "  Previous Location: $currentLocation"
    Write-Output "  VPN Connected: $vpnConnected"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
