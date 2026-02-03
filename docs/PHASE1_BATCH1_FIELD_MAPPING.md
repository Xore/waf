# Phase 1 Batch 1: Field Mapping

**Date:** February 3, 2026 22:37 CET  
**Status:** Ready for NinjaOne Conversion  
**Purpose:** Reference guide for field conversions

## Batch 1 Fields to Convert in NinjaOne

### Field 1: dnsServerStatus

**NinjaOne Field Name:** `DNSServerStatus` or `dnsServerStatus`  
**Current Type:** Dropdown  
**New Type:** Text  
**Script:** `scripts/monitoring/Script_03_DNS_Server_Monitor.ps1`  
**Header Line:** Line 18: `- DNSServerStatus (Dropdown)`  
**Change To:** `- DNSServerStatus (Text)`

**Current Dropdown Values:**
- Healthy
- Warning
- Critical
- Unknown

**Action in NinjaOne:**
1. Search: "DNSServerStatus" or "dnsServerStatus"
2. Edit field
3. Change Type: Dropdown → Text
4. Save

---

### Field 2: dhcpServerStatus

**NinjaOne Field Name:** `DHCPServerStatus` or `dhcpServerStatus`  
**Current Type:** Dropdown  
**New Type:** Text  
**Script:** `scripts/monitoring/Script_02_DHCP_Server_Monitor.ps1`  
**Header Line:** `- DHCPServerStatus (Dropdown)`  
**Change To:** `- DHCPServerStatus (Text)`

**Current Dropdown Values:**
- Healthy
- Degraded
- Critical
- Stopped
- Unknown

**Action in NinjaOne:**
1. Search: "DHCPServerStatus" or "dhcpServerStatus"
2. Edit field
3. Change Type: Dropdown → Text
4. Save

---

### Field 3: fsHealthStatus

**NinjaOne Field Name:** `FSHealthStatus` or `fsHealthStatus`  
**Current Type:** Dropdown  
**New Type:** Text  
**Script:** `scripts/monitoring/Script_45_File_Server_Monitor.ps1`  
**Header Line:** `- FSHealthStatus (Dropdown)`  
**Change To:** `- FSHealthStatus (Text)`

**Current Dropdown Values:**
- Healthy
- Warning
- Critical
- Unknown

**Action in NinjaOne:**
1. Search: "FSHealthStatus" or "fsHealthStatus"
2. Edit field
3. Change Type: Dropdown → Text
4. Save

---

### Field 4: printHealthStatus

**NinjaOne Field Name:** `PRINTHealthStatus` or `printHealthStatus`  
**Current Type:** Dropdown  
**New Type:** Text  
**Script:** `scripts/monitoring/Script_46_Print_Server_Monitor.ps1`  
**Header Line:** `- PRINTHealthStatus (Dropdown)`  
**Change To:** `- PRINTHealthStatus (Text)`

**Current Dropdown Values:**
- Healthy
- Warning
- Critical
- Unknown

**Action in NinjaOne:**
1. Search: "PRINTHealthStatus" or "printHealthStatus"
2. Edit field
3. Change Type: Dropdown → Text
4. Save

---

### Field 5: adHealthStatus (Additional)

**NinjaOne Field Name:** `ADHealthStatus` or `adHealthStatus`  
**Current Type:** Dropdown  
**New Type:** Text  
**Script:** `scripts/monitoring/Script_01_Active_Directory_Monitor.ps1` (if exists)  
**Expected Dropdown Values:**
- Healthy
- Warning
- Critical
- Unknown

**Action in NinjaOne:**
1. Search: "ADHealthStatus" or "adHealthStatus"
2. If field exists:
   - Edit field
   - Change Type: Dropdown → Text
   - Save
3. If field doesn't exist: Note as N/A

---

## Script Updates Required

After NinjaOne conversions complete, update these script headers:

### Script 1: DNS Server Monitor
**File:** `scripts/monitoring/Script_03_DNS_Server_Monitor.ps1`  
**Line ~18:** Change `DNSServerStatus (Dropdown)` to `DNSServerStatus (Text)`

### Script 2: DHCP Server Monitor
**File:** `scripts/monitoring/Script_02_DHCP_Server_Monitor.ps1`  
**Line ~18:** Change `DHCPServerStatus (Dropdown)` to `DHCPServerStatus (Text)`

### Script 3: File Server Monitor
**File:** `scripts/monitoring/Script_45_File_Server_Monitor.ps1`  
**Line ~17:** Change `FSHealthStatus (Dropdown)` to `FSHealthStatus (Text)`

### Script 4: Print Server Monitor
**File:** `scripts/monitoring/Script_46_Print_Server_Monitor.ps1`  
**Line ~17:** Change `PRINTHealthStatus (Dropdown)` to `PRINTHealthStatus (Text)`

### Script 5: Active Directory Monitor (if exists)
**File:** `scripts/monitoring/Script_01_Active_Directory_Monitor.ps1`  
**Update:** Change `ADHealthStatus (Dropdown)` to `ADHealthStatus (Text)`

---

## Field Name Variations

**Note:** NinjaOne may use different casing. Try these search patterns:

| Expected Name | Alternative Names | Prefix Pattern |
|---------------|-------------------|----------------|
| dnsServerStatus | DNSServerStatus | dns*, DNS* |
| dhcpServerStatus | DHCPServerStatus | dhcp*, DHCP* |
| fsHealthStatus | FSHealthStatus | fs*, FS* |
| printHealthStatus | PRINTHealthStatus | print*, PRINT* |
| adHealthStatus | ADHealthStatus | ad*, AD* |

---

## Conversion Checklist

**Pre-Conversion:**
- [ ] NinjaOne admin panel access confirmed
- [ ] Organization > Custom Fields section located
- [ ] Test device identified for validation

**NinjaOne Conversions:**
- [ ] dnsServerStatus converted (Dropdown → Text)
- [ ] dhcpServerStatus converted (Dropdown → Text)
- [ ] fsHealthStatus converted (Dropdown → Text)
- [ ] printHealthStatus converted (Dropdown → Text)
- [ ] adHealthStatus converted or noted as N/A
- [ ] All existing values verified as preserved

**Script Updates (After NinjaOne changes):**
- [ ] Script_03_DNS_Server_Monitor.ps1 header updated
- [ ] Script_02_DHCP_Server_Monitor.ps1 header updated
- [ ] Script_45_File_Server_Monitor.ps1 header updated
- [ ] Script_46_Print_Server_Monitor.ps1 header updated
- [ ] Script_01_Active_Directory_Monitor.ps1 updated (if exists)
- [ ] All changes committed to git

**Testing:**
- [ ] DNS Server Monitor tested on DNS server
- [ ] DHCP Server Monitor tested on DHCP server
- [ ] File Server Monitor tested on file server
- [ ] Print Server Monitor tested on print server
- [ ] AD Monitor tested (if exists)
- [ ] All fields populate correctly
- [ ] Dashboard display validated
- [ ] Search/filter functionality works

**Documentation:**
- [ ] PHASE1_Dropdown_to_Text_Conversion_Tracking.md updated
- [ ] Completion dates recorded
- [ ] Any issues documented
- [ ] Batch 1 marked complete

---

## Quick Commands for Script Updates

**After NinjaOne conversions, I'll update these files:**

```bash
# Files to update
scripts/monitoring/Script_03_DNS_Server_Monitor.ps1
scripts/monitoring/Script_02_DHCP_Server_Monitor.ps1
scripts/monitoring/Script_45_File_Server_Monitor.ps1
scripts/monitoring/Script_46_Print_Server_Monitor.ps1

# Change: (Dropdown) → (Text) in FIELDS UPDATED section
```

---

## Status After Completion

**When Batch 1 is complete:**
- 5 dropdown fields converted to TEXT
- 5 script headers updated
- All scripts tested and validated
- Dashboard functionality confirmed
- Ready to proceed to Batch 2

---

**Document Purpose:** Field conversion reference  
**Last Updated:** February 3, 2026 22:37 CET  
**Next Action:** Perform NinjaOne conversions, then notify for script updates
