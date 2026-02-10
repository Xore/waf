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

    # Check for AzureVPN connection
    $azureVpnAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'Azure' -and $_.Status -eq 'Up' }
    $vpnConnected = $azureVpnAdapter.Count -gt 0

    $newLocation = "Unknown"

    if ($vpnConnected) {
        # If AzureVPN is connected, always Remote
        $newLocation = "Remote"
    } else {
        # Get local IP address
        $localIP = Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp, Manual | 
            Where-Object { $_.IPAddress -notmatch '^169\.254\.' -and $_.IPAddress -ne '127.0.0.1' } | 
            Select-Object -First 1 -ExpandProperty IPAddress

        if ($localIP) {
            # Check IP prefix for location mapping
            if ($localIP -match '^10\.93\.') {
                $newLocation = "location1"
            } elseif ($localIP -match '^10\.43\.') {
                $newLocation = "Hauptsitz"
            } elseif ($localIP -match '^10\.') {
                # Other 10.x.x.x networks - unknown office location
                $newLocation = "Unknown"
            } else {
                # Public IP or other private ranges - likely remote/external
                $newLocation = "Remote"
            }
        } else {
            $newLocation = "Unknown"
        }
    }

    # Update previous location if changed
    if ($newLocation -ne $currentLocation -and $currentLocation -ne "Unknown") {
        Ninja-Property-Set NETLocationPrevious $currentLocation
    }

    Ninja-Property-Set NETLocationCurrent $newLocation
    Ninja-Property-Set NETVPNConnected $vpnConnected

    Write-Output "SUCCESS: Network location tracked"
    Write-Output "  Current Location: $newLocation"
    Write-Output "  Previous Location: $currentLocation"
    Write-Output "  VPN Connected: $vpnConnected"
    if ($localIP) {
        Write-Output "  Local IP: $localIP"
    }

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
