# NinjaRMM Custom Field Framework - Network, GPO, and Active Directory
**File:** 13_NET_GPO_AD_Core_Network_Identity.md  
**Categories:** NET (Network) + GPO (Group Policy) + AD (Active Directory)  
**Field Count:** ~40 fields  
**Consolidates:** Original files 19, 20, 21

---

## Overview

Core network monitoring, Group Policy compliance, and Active Directory integration fields. Essential for network health, policy enforcement, and domain integration monitoring.

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

## GPO - Group Policy Core Fields

### GPOApplied
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device is domain-joined and receiving Group Policy
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

### GPOLastApplied
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last successful GPO application
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily
- **Format:** yyyy-MM-dd HH:mm:ss

### GPOCount
- **Type:** Integer
- **Default:** 0
- **Purpose:** Number of applied Group Policy Objects
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

### GPOErrorsPresent
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Group Policy errors detected
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

### GPOLastError
- **Type:** Text
- **Max Length:** 500 characters
- **Default:** None
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

### GPOAppliedList
- **Type:** WYSIWYG
- **Default:** Empty
- **Purpose:** HTML list of applied GPOs
- **Populated By:** **Script 16** - Group Policy Monitor
- **Update Frequency:** Daily

---

## AD - Active Directory Core Fields

### ADDomainJoined
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device is joined to Active Directory domain
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Every 4 hours

### ADDomainName
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** WORKGROUP
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Every 4 hours

### ADDomainController
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** None
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Every 4 hours

### ADSiteName
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** None
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Daily

### ADComputerOU
- **Type:** Text
- **Max Length:** 500 characters
- **Default:** None
- **Purpose:** Organizational Unit path in Active Directory
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Daily

### ADLastLogonUser
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** None
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Every 4 hours

### ADPasswordLastSet
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Computer account password last changed
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Daily

### ADTrustRelationshipHealthy
- **Type:** Checkbox
- **Default:** True
- **Purpose:** Secure channel to domain controller is healthy
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Every 4 hours

### ADLastSyncTime
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Last successful domain sync
- **Populated By:** **Script 15** - Active Directory Monitor
- **Update Frequency:** Every 4 hours

---

## Script-to-Field Mapping

### Script 8: Network Monitor
**Execution:** Every 4 hours  
**Runtime:** ~20 seconds  
**Fields Updated:** All NET fields

### Script 15: Active Directory Monitor
**Execution:** Every 4 hours (critical), Daily (informational)  
**Runtime:** ~25 seconds  
**Fields Updated:** All AD fields

### Script 16: Group Policy Monitor
**Execution:** Daily  
**Runtime:** ~30 seconds  
**Fields Updated:** All GPO fields

---

**Total Fields This File:** ~40 fields  
**Scripts Required:** 3 scripts (Scripts 8, 15, 16)

---

**File:** 13_NET_GPO_AD_Core_Network_Identity.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete
