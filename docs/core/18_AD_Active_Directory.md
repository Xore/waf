# NinjaRMM Custom Field Framework - AD Fields
**File:** 18_AD_Active_Directory.md
**Category:** AD (Active Directory)
**Description:** Active Directory domain integration and trust monitoring

---

## Overview

Active Directory fields monitor domain membership, track domain controller connections, verify trust relationships, and manage computer account health for the Windows Automation Framework.

**Critical Note:** Script 15 is Cleanup Analyzer, not Active Directory Monitor. AD monitoring script needs to be implemented separately.

---

## AD - Active Directory Core Fields

### ADDomainJoined
- **Type:** Checkbox
- **Default:** False
- **Purpose:** Device is joined to Active Directory domain
- **Populated By:** **TBD: Active Directory Monitor** (Script 15 conflict - Cleanup Analyzer)
- **Update Frequency:** Every 4 hours

### ADDomainName
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** WORKGROUP
- **Populated By:** **TBD: Active Directory Monitor**
- **Update Frequency:** Every 4 hours

### ADDomainController
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** None
- **Populated By:** **TBD: Active Directory Monitor**
- **Update Frequency:** Every 4 hours

### ADSiteName
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** None
- **Populated By:** **TBD: Active Directory Monitor**
- **Update Frequency:** Daily

### ADComputerOU
- **Type:** Text
- **Max Length:** 500 characters
- **Default:** None
- **Purpose:** Organizational Unit path in Active Directory
- **Populated By:** **TBD: Active Directory Monitor**
- **Update Frequency:** Daily

### ADLastLogonUser
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** None
- **Populated By:** **TBD: Active Directory Monitor**
- **Update Frequency:** Every 4 hours

### ADPasswordLastSet
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Computer account password last changed
- **Populated By:** **TBD: Active Directory Monitor**
- **Update Frequency:** Daily

### ADTrustRelationshipHealthy
- **Type:** Checkbox
- **Default:** True
- **Purpose:** Secure channel to domain controller is healthy
- **Populated By:** **TBD: Active Directory Monitor**
- **Update Frequency:** Every 4 hours

### ADLastSyncTime
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Last successful domain sync
- **Populated By:** **TBD: Active Directory Monitor**
- **Update Frequency:** Every 4 hours

---

## Script Integration

### TBD: Active Directory Monitor
**Status:** Not yet implemented (Script 15 is Cleanup Analyzer)
**Planned Execution:** Every 4 hours (critical), Daily (informational)
**Planned Runtime:** ~25 seconds
**Fields to Update:** All AD fields (9 fields)

**Critical Issue:** All 9 AD fields have NO script support. Script 15 is Cleanup Analyzer, not AD Monitor.

---

**Total Fields:** 9 fields
**Category:** AD (Active Directory)
**Last Updated:** February 3, 2026
