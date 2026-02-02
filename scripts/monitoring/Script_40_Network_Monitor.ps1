<#
.SYNOPSIS
    Script 40: Network Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors network connectivity, adapter configuration, bandwidth utilization, and packet loss.
    Tracks connection type, IP addresses, DNS/gateway configuration. Updates 10 NET fields.

.FIELDS UPDATED
    - NETConnected (Checkbox)
    - NETConnectionType (Dropdown)
    - NETAdapterSpeed (Integer)
    - NETPublicIP (Text)
    - NETPrivateIP (Text)
    - NETDefaultGateway (Text)
    - NETDNSServers (Text)
    - NETDHCPEnabled (Checkbox)
    - NETBandwidthUsageMbps (Integer)
    - NETPacketLossPercent (Integer)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~20 seconds
    Requires: Windows networking stack

.NOTES
    File: Script_40_Network_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Network Monitoring
    Dependencies: Get-NetAdapter, Get-NetIPConfiguration

.RELATED DOCUMENTATION
    - docs/core/15_NET_Network_Monitoring.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 2)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Network Monitor (Script 40)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $connected = $false
    $connectionType = "Disconnected"
    $adapterSpeed = 0
    $publicIP = "Unknown"
    $privateIP = "Unknown"
    $defaultGateway = "Unknown"
    $dnsServers = "Unknown"
    $dhcpEnabled = $false
    $bandwidthUsage = 0
    $packetLoss = 0
    
    # Get active network adapters
    Write-Host "Detecting active network adapters..."
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    
    if ($adapters.Count -eq 0) {
        Write-Host "No active network adapters found."
        
        # Update fields for disconnected state
        Ninja-Property-Set netConnected $false
        Ninja-Property-Set netConnectionType "Disconnected"
        Ninja-Property-Set netAdapterSpeed 0
        Ninja-Property-Set netPublicIP "N/A"
        Ninja-Property-Set netPrivateIP "N/A"
        Ninja-Property-Set netDefaultGateway "N/A"
        Ninja-Property-Set netDNSServers "N/A"
        Ninja-Property-Set netDHCPEnabled $false
        Ninja-Property-Set netBandwidthUsageMbps 0
        Ninja-Property-Set netPacketLossPercent 0
        
        Write-Host "Network Monitor complete (disconnected)."
        exit 0
    }
    
    $connected = $true
    Write-Host "Found $($adapters.Count) active adapter(s)."
    
    # Prioritize adapter selection: Ethernet > WiFi > Other
    $primaryAdapter = $null
    
    # Try Ethernet first
    $primaryAdapter = $adapters | Where-Object { $_.InterfaceDescription -match 'Ethernet|Gigabit|Intel|Realtek' } | Select-Object -First 1
    
    # Fallback to WiFi
    if ($null -eq $primaryAdapter) {
        $primaryAdapter = $adapters | Where-Object { $_.InterfaceDescription -match 'Wireless|WiFi|802.11' } | Select-Object -First 1
    }
    
    # Fallback to any active adapter
    if ($null -eq $primaryAdapter) {
        $primaryAdapter = $adapters | Select-Object -First 1
    }
    
    Write-Host "Primary adapter: $($primaryAdapter.Name) - $($primaryAdapter.InterfaceDescription)"
    
    # Determine connection type
    if ($primaryAdapter.InterfaceDescription -match 'Wireless|WiFi|802.11') {
        $connectionType = "WiFi"
    } elseif ($primaryAdapter.InterfaceDescription -match 'VPN|TAP|Cisco AnyConnect|OpenVPN') {
        $connectionType = "VPN"
    } elseif ($primaryAdapter.InterfaceDescription -match 'Mobile|Cellular|LTE|4G|5G') {
        $connectionType = "Cellular"
    } else {
        $connectionType = "Wired"
    }
    
    Write-Host "Connection Type: $connectionType"
    
    # Get adapter speed (convert to Mbps)
    $adapterSpeed = [Math]::Round($primaryAdapter.LinkSpeed -replace '[^0-9]', '' -as [int64] / 1MB)
    Write-Host "Adapter Speed: $adapterSpeed Mbps"
    
    # Get IP configuration
    $ipConfig = Get-NetIPConfiguration -InterfaceIndex $primaryAdapter.InterfaceIndex -ErrorAction SilentlyContinue
    
    if ($ipConfig) {
        # Get private IP (IPv4)
        $ipv4 = $ipConfig.IPv4Address.IPAddress
        if ($ipv4) {
            $privateIP = $ipv4
            Write-Host "Private IP: $privateIP"
        }
        
        # Get default gateway
        $gateway = $ipConfig.IPv4DefaultGateway.NextHop
        if ($gateway) {
            $defaultGateway = $gateway
            Write-Host "Default Gateway: $defaultGateway"
        }
        
        # Get DNS servers
        $dns = $ipConfig.DNSServer.ServerAddresses
        if ($dns) {
            $dnsServers = $dns -join ', '
            if ($dnsServers.Length -gt 200) {
                $dnsServers = $dnsServers.Substring(0, 197) + "..."
            }
            Write-Host "DNS Servers: $dnsServers"
        }
    }
    
    # Check DHCP status
    $dhcpEnabled = (Get-NetIPInterface -InterfaceIndex $primaryAdapter.InterfaceIndex -AddressFamily IPv4).Dhcp -eq 'Enabled'
    Write-Host "DHCP Enabled: $dhcpEnabled"
    
    # Get public IP address
    try {
        Write-Host "Retrieving public IP address..."
        $publicIPResponse = Invoke-RestMethod -Uri 'https://api.ipify.org?format=text' -TimeoutSec 5 -ErrorAction Stop
        $publicIP = $publicIPResponse.Trim()
        Write-Host "Public IP: $publicIP"
    } catch {
        Write-Warning "Failed to retrieve public IP: $_"
        $publicIP = "Unable to retrieve"
    }
    
    # Get bandwidth usage from performance counters
    try {
        Write-Host "Measuring bandwidth utilization..."
        $interfaceName = $primaryAdapter.InterfaceDescription
        
        # Get current bytes sent/received
        $counterPath = "\Network Interface($interfaceName)\Bytes Total/sec"
        $bytesPerSec = (Get-Counter -Counter $counterPath -ErrorAction SilentlyContinue).CounterSamples.CookedValue
        
        # Convert to Mbps
        $bandwidthUsage = [Math]::Round($bytesPerSec * 8 / 1MB, 2)
        Write-Host "Bandwidth Usage: $bandwidthUsage Mbps"
    } catch {
        Write-Warning "Failed to measure bandwidth: $_"
        $bandwidthUsage = 0
    }
    
    # Test packet loss to gateway
    if ($defaultGateway -ne "Unknown" -and $defaultGateway -ne "N/A") {
        try {
            Write-Host "Testing packet loss to gateway..."
            $pingResults = Test-Connection -ComputerName $defaultGateway -Count 10 -ErrorAction SilentlyContinue
            
            if ($pingResults) {
                $successfulPings = $pingResults.Count
                $packetLoss = [Math]::Round((1 - ($successfulPings / 10)) * 100)
                Write-Host "Packet Loss: $packetLoss%"
            } else {
                Write-Warning "All pings to gateway failed."
                $packetLoss = 100
            }
        } catch {
            Write-Warning "Failed to test packet loss: $_"
            $packetLoss = 0
        }
    }
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set netConnected $connected
    Ninja-Property-Set netConnectionType $connectionType
    Ninja-Property-Set netAdapterSpeed $adapterSpeed
    Ninja-Property-Set netPublicIP $publicIP
    Ninja-Property-Set netPrivateIP $privateIP
    Ninja-Property-Set netDefaultGateway $defaultGateway
    Ninja-Property-Set netDNSServers $dnsServers
    Ninja-Property-Set netDHCPEnabled $dhcpEnabled
    Ninja-Property-Set netBandwidthUsageMbps $bandwidthUsage
    Ninja-Property-Set netPacketLossPercent $packetLoss
    
    Write-Host "Network Monitor complete. Connected: $connected, Type: $connectionType"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Network Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set netConnected $false
    Ninja-Property-Set netConnectionType "Disconnected"
    
    exit 1
}
