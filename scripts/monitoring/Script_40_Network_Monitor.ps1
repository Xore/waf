<#
.SYNOPSIS
    Network Monitor - Network Connectivity and Configuration Monitoring

.DESCRIPTION
    Monitors network connectivity, adapter configuration, bandwidth utilization, and packet loss.
    Tracks connection type (Wired/WiFi/VPN/Cellular), IP addresses, DNS/gateway configuration,
    DHCP status, and network performance metrics. Essential for network troubleshooting and
    capacity planning.
    
    Critical for detecting network disconnections, identifying connectivity issues before they
    impact users, monitoring bandwidth consumption, and validating network configuration.
    Foundational for remote device management and network infrastructure monitoring.
    
    Monitoring Scope:
    
    Network Adapter Detection:
    - Queries Get-NetAdapter for active adapters
    - Filters by Status = 'Up'
    - Counts total active adapters
    - Gracefully handles disconnected state
    
    Primary Adapter Selection:
    - Prioritization order:
      1. Ethernet (Gigabit, Intel, Realtek)
      2. WiFi (Wireless, 802.11)
      3. Any other active adapter
    - Uses most reliable connection type
    
    Connection Type Detection:
    - WiFi: Wireless/802.11 in description
    - VPN: TAP, Cisco AnyConnect, OpenVPN
    - Cellular: Mobile, LTE, 4G, 5G
    - Wired: Default for physical Ethernet
    
    Adapter Speed:
    - Reads LinkSpeed property
    - Converts to Mbps for consistency
    - Common speeds: 1000 Mbps (Gigabit), 100 Mbps (Fast Ethernet)
    
    IP Configuration:
    - Queries Get-NetIPConfiguration by interface index
    - IPv4 private address from local network
    - Default gateway (router IP)
    - DNS servers (comma-separated list)
    
    DHCP Status:
    - Checks Get-NetIPInterface for IPv4 DHCP setting
    - Enabled: Dynamic IP from DHCP server
    - Disabled: Static IP configuration
    
    Public IP Detection:
    - Queries api.ipify.org external service
    - Retrieves Internet-facing IP address
    - 5-second timeout for reliability
    - Useful for remote access and NAT detection
    
    Bandwidth Utilization:
    - Queries performance counter: Bytes Total/sec
    - Converts bytes to Mbps for readability
    - Real-time network throughput
    - Capacity planning metric
    
    Packet Loss Testing:
    - Pings default gateway 10 times
    - Calculates loss percentage
    - High loss indicates network problems
    - Quality metric for VoIP/video
    
    Health Implications:
    - Connected: Network available
    - Disconnected: No active adapters
    - High packet loss: Network quality issues
    - Low bandwidth: Capacity concerns

.NOTES
    Frequency: Every 4 hours
    Runtime: ~20 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - NETConnected (Checkbox)
    - NETConnectionType (Text: Wired, WiFi, VPN, Cellular, Disconnected)
    - NETAdapterSpeed (Integer: Mbps)
    - NETPublicIP (Text: Internet-facing IP)
    - NETPrivateIP (Text: Local network IP)
    - NETDefaultGateway (Text: Router IP)
    - NETDNSServers (Text: Comma-separated list, max 200 chars)
    - NETDHCPEnabled (Checkbox)
    - NETBandwidthUsageMbps (Integer: Real-time throughput)
    - NETPacketLossPercent (Integer: Packet loss to gateway)
    
    Dependencies:
    - Get-NetAdapter cmdlet (Windows 8+)
    - Get-NetIPConfiguration cmdlet
    - Get-NetIPInterface cmdlet
    - Performance counter access
    - Internet access for public IP (optional)
    
    Connection Types:
    - Wired: Physical Ethernet cable
    - WiFi: Wireless 802.11a/b/g/n/ac/ax
    - VPN: Virtual private network tunnel
    - Cellular: Mobile broadband (LTE/5G)
    - Disconnected: No active adapters
    
    Common Issues:
    - No adapters found: Check physical connections
    - Public IP failed: Firewall blocks api.ipify.org
    - High packet loss: Check cables, router, interference
    - Zero bandwidth: Performance counter access denied
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting Network Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
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
    
    Write-Output "INFO: Detecting active network adapters..."
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    
    if ($adapters.Count -eq 0) {
        Write-Output "INFO: No active network adapters found"
        
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
        
        Write-Output "SUCCESS: Network monitoring complete (disconnected)"
        exit 0
    }
    
    $connected = $true
    Write-Output "INFO: Found $($adapters.Count) active adapter(s)"
    
    $primaryAdapter = $null
    
    $primaryAdapter = $adapters | Where-Object { $_.InterfaceDescription -match 'Ethernet|Gigabit|Intel|Realtek' } | Select-Object -First 1
    
    if ($null -eq $primaryAdapter) {
        $primaryAdapter = $adapters | Where-Object { $_.InterfaceDescription -match 'Wireless|WiFi|802.11' } | Select-Object -First 1
    }
    
    if ($null -eq $primaryAdapter) {
        $primaryAdapter = $adapters | Select-Object -First 1
    }
    
    Write-Output "INFO: Primary adapter: $($primaryAdapter.Name) - $($primaryAdapter.InterfaceDescription)"
    
    if ($primaryAdapter.InterfaceDescription -match 'Wireless|WiFi|802.11') {
        $connectionType = "WiFi"
    } elseif ($primaryAdapter.InterfaceDescription -match 'VPN|TAP|Cisco AnyConnect|OpenVPN') {
        $connectionType = "VPN"
    } elseif ($primaryAdapter.InterfaceDescription -match 'Mobile|Cellular|LTE|4G|5G') {
        $connectionType = "Cellular"
    } else {
        $connectionType = "Wired"
    }
    
    Write-Output "INFO: Connection type: $connectionType"
    
    $adapterSpeed = [Math]::Round($primaryAdapter.LinkSpeed -replace '[^0-9]', '' -as [int64] / 1MB)
    Write-Output "INFO: Adapter speed: $adapterSpeed Mbps"
    
    Write-Output "INFO: Retrieving IP configuration..."
    $ipConfig = Get-NetIPConfiguration -InterfaceIndex $primaryAdapter.InterfaceIndex -ErrorAction SilentlyContinue
    
    if ($ipConfig) {
        $ipv4 = $ipConfig.IPv4Address.IPAddress
        if ($ipv4) {
            $privateIP = $ipv4
            Write-Output "INFO: Private IP: $privateIP"
        }
        
        $gateway = $ipConfig.IPv4DefaultGateway.NextHop
        if ($gateway) {
            $defaultGateway = $gateway
            Write-Output "INFO: Default gateway: $defaultGateway"
        }
        
        $dns = $ipConfig.DNSServer.ServerAddresses
        if ($dns) {
            $dnsServers = $dns -join ', '
            if ($dnsServers.Length -gt 200) {
                $dnsServers = $dnsServers.Substring(0, 197) + "..."
            }
            Write-Output "INFO: DNS servers: $dnsServers"
        }
    }
    
    $dhcpEnabled = (Get-NetIPInterface -InterfaceIndex $primaryAdapter.InterfaceIndex -AddressFamily IPv4).Dhcp -eq 'Enabled'
    Write-Output "INFO: DHCP enabled: $dhcpEnabled"
    
    Write-Output "INFO: Retrieving public IP address..."
    try {
        $publicIPResponse = Invoke-RestMethod -Uri 'https://api.ipify.org?format=text' -TimeoutSec 5 -ErrorAction Stop
        $publicIP = $publicIPResponse.Trim()
        Write-Output "INFO: Public IP: $publicIP"
    } catch {
        Write-Output "WARNING: Failed to retrieve public IP: $_"
        $publicIP = "Unable to retrieve"
    }
    
    Write-Output "INFO: Measuring bandwidth utilization..."
    try {
        $interfaceName = $primaryAdapter.InterfaceDescription
        $counterPath = "\Network Interface($interfaceName)\Bytes Total/sec"
        $bytesPerSec = (Get-Counter -Counter $counterPath -ErrorAction SilentlyContinue).CounterSamples.CookedValue
        
        $bandwidthUsage = [Math]::Round($bytesPerSec * 8 / 1MB, 2)
        Write-Output "INFO: Bandwidth usage: $bandwidthUsage Mbps"
    } catch {
        Write-Output "WARNING: Failed to measure bandwidth: $_"
        $bandwidthUsage = 0
    }
    
    if ($defaultGateway -ne "Unknown" -and $defaultGateway -ne "N/A") {
        Write-Output "INFO: Testing packet loss to gateway..."
        try {
            $pingResults = Test-Connection -ComputerName $defaultGateway -Count 10 -ErrorAction SilentlyContinue
            
            if ($pingResults) {
                $successfulPings = $pingResults.Count
                $packetLoss = [Math]::Round((1 - ($successfulPings / 10)) * 100)
                Write-Output "INFO: Packet loss: $packetLoss%"
            } else {
                Write-Output "WARNING: All pings to gateway failed"
                $packetLoss = 100
            }
        } catch {
            Write-Output "WARNING: Failed to test packet loss: $_"
            $packetLoss = 0
        }
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
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
    
    Write-Output "SUCCESS: Network monitoring complete"
    Write-Output "NETWORK METRICS:"
    Write-Output "  - Connected: $connected"
    Write-Output "  - Connection Type: $connectionType"
    Write-Output "  - Adapter Speed: $adapterSpeed Mbps"
    Write-Output "  - Private IP: $privateIP"
    Write-Output "  - Public IP: $publicIP"
    Write-Output "  - Gateway: $defaultGateway"
    Write-Output "  - DNS: $dnsServers"
    Write-Output "  - DHCP: $dhcpEnabled"
    Write-Output "  - Bandwidth Usage: $bandwidthUsage Mbps"
    Write-Output "  - Packet Loss: $packetLoss%"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: Network Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set netConnected $false
    Ninja-Property-Set netConnectionType "Disconnected"
    
    exit 1
}
