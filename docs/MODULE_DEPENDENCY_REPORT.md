# Module Dependency Audit Report

**Date:** February 3, 2026, 2:06 AM CET  
**Status:** Audit Complete  
**Phase:** Pre-Phase B - Module Dependency Reduction

---

## Executive Summary

Audit of all PowerShell module dependencies across 48 WAF scripts identified 6 unique modules used by 9 scripts. Modules categorized into RSAT (require elimination) and Native Windows (retain). Two RSAT modules identified for replacement.

---

## Module Inventory

### RSAT Modules (Require Replacement)

| Module | Scripts Using | Status | Replacement Strategy |
|--------|---------------|--------|---------------------|
| DhcpServer | Script_02_DHCP_Server_Monitor.ps1 | REPLACE | WMI/CIM queries to root\Microsoft\Windows\Dhcp namespace |
| DnsServer | Script_03_DNS_Server_Monitor.ps1, Script_14_DNS_Server_Monitor.ps1 (old), 03_DNS_Server_Monitor.ps1 (old), 14_DNS_Server_Monitor.ps1 (old) | REPLACE | WMI queries to MicrosoftDNS namespace + registry |

### Native Windows Modules (Retain)

| Module | Scripts Using | Status | Justification |
|--------|---------------|--------|---------------|
| WebAdministration | Script_37_IIS_Web_Server_Monitor.ps1 | KEEP | Native IIS module, ships with Windows Server |
| Hyper-V | Script_08_HyperV_Host_Monitor.ps1, 08_HyperV_Host_Monitor.ps1 (old), 18_HyperV_Host_Monitor.ps1 (old) | KEEP | Native Hyper-V module, ships with role |
| Veeam.Backup.PowerShell | Script_48_Veeam_Backup_Monitor.ps1 | KEEP | Third-party, required for Veeam monitoring |
| SqlServer | Script_38_MSSQL_Server_Monitor.ps1 | KEEP | Native SQL Server module, ships with SQL |

### Already Eliminated

| Module | Status | Completion |
|--------|--------|------------|
| ActiveDirectory | ELIMINATED | Pre-Phase A (Script_42 migrated to LDAP://) |

---

## Detailed Script Analysis

### Scripts Requiring Migration

**Script_02_DHCP_Server_Monitor.ps1**
- **Current Module:** DhcpServer (RSAT)
- **Cmdlets Used:**
  - Get-DhcpServerInDC
  - Get-DhcpServerv4Scope
  - Get-DhcpServerv4ScopeStatistics
  - Get-DhcpServerv4Failover
  - Get-DhcpServerv4Statistics
- **Replacement:** WMI/CIM queries to DHCP WMI namespace
- **Complexity:** Medium
- **Estimated Effort:** 2-3 hours

**Script_03_DNS_Server_Monitor.ps1**
- **Current Module:** DnsServer (RSAT)
- **Cmdlets Used:**
  - Get-DnsServer
  - Get-DnsServerZone
  - Get-DnsServerStatistics
  - Test-DnsServer
- **Replacement:** WMI MicrosoftDNS namespace + registry + dnscmd.exe
- **Complexity:** Medium-High
- **Estimated Effort:** 3-4 hours

### Scripts Using Native Modules (No Change Required)

**Script_37_IIS_Web_Server_Monitor.ps1**
- **Module:** WebAdministration (Native)
- **Status:** No change needed
- **Justification:** WebAdministration ships with IIS role, not RSAT

**Script_08_HyperV_Host_Monitor.ps1**
- **Module:** Hyper-V (Native)
- **Status:** No change needed
- **Justification:** Hyper-V module ships with Hyper-V role, not RSAT

**Script_38_MSSQL_Server_Monitor.ps1**
- **Module:** SqlServer (Native)
- **Status:** No change needed
- **Justification:** SqlServer module ships with SQL Server, not RSAT

**Script_48_Veeam_Backup_Monitor.ps1**
- **Module:** Veeam.Backup.PowerShell (Third-party)
- **Status:** No change needed
- **Justification:** Third-party module required for Veeam integration

---

## Duplicate/Old Scripts Found

Several old script versions found in scripts/ root (not in monitoring/ subfolder). These should be removed:

- 03_DNS_Server_Monitor.ps1 (duplicate of Script_03)
- 14_DNS_Server_Monitor.ps1 (old version)
- 08_HyperV_Host_Monitor.ps1 (duplicate of Script_08)
- 18_HyperV_Host_Monitor.ps1 (old version)

**Action:** Clean up duplicate scripts in separate cleanup task.

---

## RSAT Module Replacement Strategies

### DhcpServer Module Replacement

**WMI Namespace:** root\Microsoft\Windows\Dhcp

**Key Classes:**
- DhcpServerv4Scope
- DhcpServerv4ScopeStatistics
- DhcpServerv4Failover
- DhcpServerv4Lease

**Implementation Approach:**
```powershell
# Get DHCP scopes via WMI
$scopes = Get-CimInstance -Namespace "root/Microsoft/Windows/Dhcp" -ClassName "DhcpServerv4Scope"

# Get scope statistics
$stats = Get-CimInstance -Namespace "root/Microsoft/Windows/Dhcp" -ClassName "DhcpServerv4ScopeStatistics"

# Fallback: Use netsh dhcp commands if WMI unavailable
$netshOutput = netsh dhcp server show scope
```

**Benefits:**
- No RSAT dependency
- Available on all Windows Server with DHCP role
- WMI is native to Windows

### DnsServer Module Replacement

**WMI Namespace:** root\MicrosoftDNS

**Key Classes:**
- MicrosoftDNS_Server
- MicrosoftDNS_Zone
- MicrosoftDNS_Statistics
- MicrosoftDNS_ResourceRecord

**Implementation Approach:**
```powershell
# Get DNS zones via WMI
$zones = Get-CimInstance -Namespace "root/MicrosoftDNS" -ClassName "MicrosoftDNS_Zone"

# Get DNS server settings
$dnsServer = Get-CimInstance -Namespace "root/MicrosoftDNS" -ClassName "MicrosoftDNS_Server"

# Get statistics from registry
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\DNS\Parameters"
$dnsSettings = Get-ItemProperty -Path $regPath

# Fallback: Use dnscmd.exe for certain operations
$dnscmdOutput = dnscmd /info
```

**Benefits:**
- No RSAT dependency
- MicrosoftDNS WMI provider ships with DNS Server role
- Consistent with native Windows approach

---

## Implementation Plan

### Phase 1: DHCP Module Migration (2-3 hours)

1. Create WMI-based DHCP query functions
2. Update Script_02_DHCP_Server_Monitor.ps1
3. Test on DHCP server
4. Verify all fields populated correctly
5. Update documentation

### Phase 2: DNS Module Migration (3-4 hours)

1. Create WMI-based DNS query functions
2. Update Script_03_DNS_Server_Monitor.ps1
3. Test on DNS server
4. Verify zone enumeration and statistics
5. Update documentation

### Phase 3: Script Cleanup (30 minutes)

1. Remove duplicate scripts from root
2. Verify all active scripts in monitoring/ subfolder
3. Update documentation references

---

## Success Criteria

- Zero RSAT module dependencies across all scripts
- All DHCP monitoring functions work via WMI/CIM
- All DNS monitoring functions work via WMI/CIM
- Native Windows modules retained (WebAdministration, Hyper-V, SqlServer)
- Third-party modules retained (Veeam)
- All scripts tested and functional
- Documentation updated with WMI approaches

---

## Benefits of RSAT Elimination

**Deployment Simplification:**
- No RSAT installation required on client systems
- Reduced deployment prerequisites
- Faster script execution (no module loading)

**Compatibility:**
- Works on Server Core without RSAT
- Compatible with all Windows Server versions
- No PowerShell module version conflicts

**Performance:**
- WMI queries are faster than cmdlet abstraction
- No module loading overhead (2-5 seconds saved)
- Reduced memory footprint

**Reliability:**
- Fewer external dependencies
- More predictable behavior
- Better error handling capabilities

---

## Change Log

| Date | Time | Author | Changes |
|------|------|--------|----------|
| 2026-02-03 | 2:06 AM | WAF Team | Initial module dependency audit |

---

**Last Updated:** February 3, 2026, 2:06 AM CET
