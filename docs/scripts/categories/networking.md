# Network Management & Monitoring

**Complete guide to network management scripts in the WAF framework.**

---

## Overview

The WAF Network Management suite provides 20+ scripts for DNS/DHCP operations, connectivity testing, drive mapping, and network diagnostics. Designed for complex enterprise networks with multiple subnets, VLANs, and network services.

### Script Categories

| Category | Script Count | Primary Focus |
|----------|--------------|---------------|
| DNS Operations | 3 | DNS server monitoring |
| DHCP Operations | 3 | DHCP scope management |
| Network Diagnostics | 7+ | Connectivity and troubleshooting |
| Configuration Management | 5+ | Network settings automation |

**Total:** 20+ scripts | **Complexity:** Intermediate

---

## DNS Operations

### DNSServerMonitor_v1/v2/v3.ps1

**Purpose:** DNS server health monitoring with progressive feature enhancement.

**Version Evolution:**

| Feature | v1 | v2 | v3 |
|---------|----|----|----|
| Basic service check | ✅ | ✅ | ✅ |
| Zone health | ❌ | ✅ | ✅ |
| Query response time | ❌ | ✅ | ✅ |
| Forwarder validation | ❌ | ❌ | ✅ |
| DNSSEC validation | ❌ | ❌ | ✅ |
| Performance metrics | ❌ | Basic | Advanced |

**v3 Features (Recommended):**
- DNS service status
- Zone replication health
- Query performance (avg response time)
- Forwarder availability
- Cache efficiency
- DNSSEC validation
- Scavenging status
- Dynamic update security

**NinjaOne Custom Fields:**
```powershell
dns_service_status          # Running/Stopped
dns_zones_total             # Total zones
dns_zones_healthy           # Healthy zones
dns_query_avg_ms            # Average query time
dns_forwarders_status       # Forwarder health
dns_cache_efficiency        # Cache hit ratio
dns_scavenging_enabled      # Scavenging status
```

**Usage (v3):**

```powershell
# Comprehensive monitoring
.\DNSServerMonitor_v3.ps1

# Performance focus
.\DNSServerMonitor_v3.ps1 -PerformanceAnalysis

# Zone health check
.\DNSServerMonitor_v3.ps1 -ZoneHealthOnly
```

**Alert Thresholds:**
```powershell
$alerts = @{
    QueryTime = @{
        Warning = 50    # 50ms
        Critical = 100  # 100ms
    }
    CacheEfficiency = @{
        Warning = 70    # Below 70%
        Critical = 50   # Below 50%
    }
}
```

---

## DHCP Operations

### DHCPServerMonitor.ps1

**Purpose:** DHCP server and scope monitoring.

**Key Features:**
- Service health
- Scope utilization
- Lease availability
- Authorization status
- Failover partner health

**NinjaOne Fields:**
```powershell
dhcp_service_status         # Running/Stopped
dhcp_scopes_total           # Total scopes
dhcp_leases_available       # Available leases
dhcp_utilization_percent    # Average utilization
dhcp_authorized             # Server authorized
```

**Usage:**
```powershell
.\DHCPServerMonitor.ps1
```

---

### DHCP-AlertOnLeaseLow.ps1

**Purpose:** Alert when DHCP scope capacity runs low.

**Usage:**
```powershell
# Alert at 90% utilization
.\DHCP-AlertOnLeaseLow.ps1 -Threshold 90
```

---

### DHCP-FindRogueServersNmap.ps1

**Purpose:** Detect unauthorized DHCP servers on network.

**Usage:**
```powershell
.\DHCP-FindRogueServersNmap.ps1 -Subnet "10.0.0.0/24"
```

---

## Network Diagnostics

### Network-TestConnectivity.ps1

**Purpose:** Comprehensive connectivity testing.

**Tests Performed:**
- ICMP ping
- TCP port connectivity
- DNS resolution
- HTTP/HTTPS response
- Traceroute

**Usage:**
```powershell
# Basic connectivity
.\Network-TestConnectivity.ps1 -Target "google.com"

# Specific port
.\Network-TestConnectivity.ps1 -Target "webserver" -Port 443

# Full diagnostics
.\Network-TestConnectivity.ps1 -Target "server.local" -Comprehensive
```

---

### Network-GetPublicIP.ps1

**Purpose:** Retrieve public IP address.

**NinjaOne Field:**
```powershell
net_public_ip               # Public IP address
```

**Usage:**
```powershell
.\Network-GetPublicIP.ps1
```

---

### Network-LLDPInformation.ps1

**Purpose:** Collect LLDP network topology information.

**Usage:**
```powershell
.\Network-LLDPInformation.ps1
```

---

### Network-TracerouteWithGeolocation.ps1

**Purpose:** Enhanced traceroute with geolocation data.

**Usage:**
```powershell
.\Network-TracerouteWithGeolocation.ps1 -Target "8.8.8.8"
```

---

## Configuration Management

### Network-CheckIPConfig.ps1

**Purpose:** Verify network adapter configuration.

**Checks:**
- IP address assignment
- Subnet mask
- Default gateway
- DNS servers
- DHCP vs Static

**NinjaOne Fields:**
```powershell
net_ip_address              # Primary IP
net_subnet_mask             # Subnet mask
net_default_gateway         # Gateway IP
net_dns_servers             # DNS server list
net_dhcp_enabled            # DHCP enabled
```

**Usage:**
```powershell
.\Network-CheckIPConfig.ps1
```

---

### Network-DriveMapping.ps1

**Purpose:** Manage network drive mappings.

**Usage:**
```powershell
# Map drive
.\Network-DriveMapping.ps1 -Drive "Z:" -Path "\\server\share" -Map

# Unmap drive
.\Network-DriveMapping.ps1 -Drive "Z:" -Unmap
```

---

### Network-ManageSMB.ps1

**Purpose:** SMB protocol management and security.

**Usage:**
```powershell
# Check SMB configuration
.\Network-ManageSMB.ps1 -Check

# Disable SMBv1
.\Network-ManageSMB.ps1 -DisableSMBv1
```

---

## Best Practices

### Monitoring Frequency

| Script | Interval | Impact |
|--------|----------|--------|
| DNSServerMonitor_v3 | 15 min | Low |
| DHCPServerMonitor | 30 min | Low |
| Network-TestConnectivity | Hourly | Low |
| Network-GetPublicIP | Daily | Very Low |

---

**Last Updated:** 2026-02-11  
**Scripts:** 20+  
**Complexity:** Intermediate
