# NinjaRMM Custom Field Framework - NET Fields
**File:** 17_NET_Network_Monitoring.md
**Category:** NET (Network Monitoring)
**Description:** Network connectivity, bandwidth, and configuration monitoring

---

## Overview

Network monitoring fields track connectivity status, network configuration, adapter performance, and bandwidth utilization for the Windows Automation Framework.

---

## NET - Network Monitoring Core Fields

### NETConnected
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device has active network connectivity
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

### NETConnectionType
- **Type:** Dropdown
- **Valid Values:** Wired, WiFi, Cellular, VPN, Disconnected
- **Default:** Disconnected
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

### NETAdapterSpeed
- **Type:** Integer
- **Default:** 0
- **Purpose:** Network adapter link speed in Mbps
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours
- **Unit:** Megabits per second

### NETPublicIP
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

### NETPrivateIP
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

### NETDefaultGateway
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

### NETDNSServers
- **Type:** Text
- **Max Length:** 200 characters
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

### NETDHCPEnabled
- **Type:** Checkbox
- **Default:** True
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

### NETBandwidthUsageMbps
- **Type:** Integer
- **Default:** 0
- **Purpose:** Current bandwidth utilization in Mbps
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

### NETPacketLossPercent
- **Type:** Integer (0-100)
- **Default:** 0
- **Purpose:** Packet loss percentage to gateway
- **Populated By:** **Script 8** - Network Monitor
- **Update Frequency:** Every 4 hours

---

## Script Integration

### Script 8: Network Monitor
**Execution:** Every 4 hours
**Runtime:** ~20 seconds
**Fields Updated:** All NET fields

---

**Total Fields:** 10 fields
**Category:** NET (Network Monitoring)
**Last Updated:** February 2, 2026
