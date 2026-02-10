# NinjaRMM Custom Field Framework - NET Fields
**File:** 15_NET_Network_Monitoring.md
**Category:** NET (Network Monitoring)
**Description:** Network connectivity, bandwidth, and configuration monitoring

---

## Overview

Network monitoring fields track connectivity status, network configuration, adapter performance, and bandwidth utilization for the Windows Automation Framework.

**Critical Note:** Script 8 is Hyper-V Host Monitor, not Network Monitor. NET monitoring script needs to be implemented separately.

---

## NET - Network Monitoring Core Fields

### NETConnected
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device has active network connectivity
- **Populated By:** **TBD: Network Monitor** (Script 8 conflict - currently Hyper-V Monitor)
- **Update Frequency:** Every 4 hours

### NETConnectionType
- **Type:** Dropdown
- **Valid Values:** Wired, WiFi, Cellular, VPN, Disconnected
- **Default:** Disconnected
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours

### NETAdapterSpeed
- **Type:** Integer
- **Default:** 0
- **Purpose:** Network adapter link speed in Mbps
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours
- **Unit:** Megabits per second

### NETPublicIP
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours

### NETPrivateIP
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours

### NETDefaultGateway
- **Type:** Text
- **Max Length:** 50 characters
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours

### NETDNSServers
- **Type:** Text
- **Max Length:** 200 characters
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours

### NETDHCPEnabled
- **Type:** Checkbox
- **Default:** True
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours

### NETBandwidthUsageMbps
- **Type:** Integer
- **Default:** 0
- **Purpose:** Current bandwidth utilization in Mbps
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours

### NETPacketLossPercent
- **Type:** Integer (0-100)
- **Default:** 0
- **Purpose:** Packet loss percentage to gateway
- **Populated By:** **TBD: Network Monitor**
- **Update Frequency:** Every 4 hours

---

## Script Integration

### TBD: Network Monitor
**Status:** Not yet implemented (Script 8 is Hyper-V Host Monitor)
**Planned Execution:** Every 4 hours
**Planned Runtime:** ~20 seconds
**Fields to Update:** All NET fields (10 fields)

**Critical Issue:** All 10 NET fields have NO script support. Script 8 is Hyper-V Monitor, not Network Monitor.

---

**Total Fields:** 10 fields
**Category:** NET (Network Monitoring)
**Last Updated:** February 3, 2026
