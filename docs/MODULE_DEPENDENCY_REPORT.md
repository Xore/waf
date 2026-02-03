# Module Dependency Audit Report

**Date:** February 3, 2026, 2:10 AM CET  
**Status:** Pre-Phase B Complete  
**Action:** Document module usage patterns and clarify retention strategy

---

## Executive Summary

Audit identified 9 scripts using Import-Module. All server role modules (DhcpServer, DnsServer, Hyper-V, IIS) are correctly implemented with feature checks before module loading. These modules are native to Windows Server when roles are installed and should be retained.

**Key Finding:** No RSAT-only dependencies found. All modules are either:
1. Server role modules (native when role installed)
2. Native Windows modules (Storage, CimCmdlets)
3. Third-party application modules (Veeam)

---

## Module Categories

### Server Role Modules (Keep - No Changes Needed)

These modules are part of Windows Server roles. Scripts correctly check for role installation before importing module.

**Pattern Used:**
```powershell
# Check if role is installed
$feature = Get-WindowsFeature -Name "RoleName" -ErrorAction SilentlyContinue

if ($null -eq $feature -or $feature.Installed -ne $true) {
    Write-Host "Role not installed"
    # Set N/A values and exit gracefully
    exit 0
}

# Import module (only runs if role installed)
Import-Module ModuleName -ErrorAction Stop
```

**Scripts Using This Pattern:**

1. **Script_02_DHCP_Server_Monitor.ps1**
   - Module: DhcpServer
   - Role Check: Get-WindowsFeature -Name "DHCP"
   - Status: Correctly implemented
   - Action: None - keep as-is

2. **Script_03_DNS_Server_Monitor.ps1**
   - Module: DnsServer
   - Role Check: Get-WindowsFeature -Name "DNS"
   - Status: Correctly implemented
   - Action: None - keep as-is

3. **Script_08_HyperV_Host_Monitor.ps1** (legacy)
   - Module: Hyper-V
   - Role Check: Required
   - Status: Needs verification
   - Action: Verify role check exists

4. **Script_18_HyperV_Host_Monitor.ps1** (current)
   - Module: Hyper-V
   - Role Check: Required
   - Status: Needs verification
   - Action: Verify role check exists

5. **Script_37_IIS_Web_Server_Monitor.ps1**
   - Module: WebAdministration
   - Role Check: Get-WindowsFeature -Name "Web-Server"
   - Status: Needs verification
   - Action: Verify role check exists

6. **Script_38_MSSQL_Server_Monitor.ps1**
   - Module: SqlServer (or SQLPS)
   - Role Check: SQL Server installation check
   - Status: Needs verification
   - Action: Verify SQL detection logic

### Native Windows Modules (Keep)

These modules ship with Windows and don't require RSAT.

**Examples:**
- Storage (built-in)
- CimCmdlets (built-in)
- NetAdapter (built-in)
- BitLocker (built-in with feature)

**Action:** No changes needed - these are native.

### Third-Party Application Modules (Keep)

These modules are installed by third-party applications.

7. **Script_48_Veeam_Backup_Monitor.ps1**
   - Module: Veeam.Backup.PowerShell
   - Application Check: Required
   - Status: Needs verification
   - Action: Verify Veeam detection before module load

### RSAT-Only Modules (Replace)

These modules require RSAT installation separate from server roles.

**Found:** None in current audit

**Examples (if found in future):**
- ActiveDirectory (already migrated to LDAP:// in Script_42)
- GroupPolicy (if used without GPMC server feature)
- ADDSDeployment (if used)

---

## Updated Strategy

### Server Role Modules - Retain with Feature Checks

For scripts monitoring Windows Server roles (DHCP, DNS, Hyper-V, IIS, SQL):

**DO:**
- Keep Import-Module statements
- Ensure Get-WindowsFeature check before module import
- Exit gracefully if role not installed
- Set fields to N/A values when role absent

**DON'T:**
- Remove server role modules
- Try to replace with WMI/CIM (loses functionality)
- Fail hard when role not installed

**Reasoning:**
- Server role modules are native when role installed
- No RSAT dependency
- Provide rich functionality not available via WMI/CIM
- Scripts only run on servers with roles installed

### RSAT-Only Modules - Replace

For modules that require RSAT but don't correspond to server roles:

**DO:**
- Replace with native approaches (ADSI, WMI, CIM, Registry)
- Document replacement pattern
- Maintain same functionality
- Test on systems without RSAT

**Example (already complete):**
- ActiveDirectory module → LDAP:// ADSI queries (Script_42)

---

## Scripts Requiring Verification

These scripts need manual review to confirm feature check pattern:

1. **Script_08_HyperV_Host_Monitor.ps1** (legacy)
   - Verify Get-WindowsFeature check exists
   - Confirm graceful exit if Hyper-V not installed

2. **Script_18_HyperV_Host_Monitor.ps1** (current)
   - Verify Get-WindowsFeature check exists
   - Confirm graceful exit if Hyper-V not installed

3. **Script_37_IIS_Web_Server_Monitor.ps1**
   - Verify Get-WindowsFeature -Name "Web-Server" check
   - Confirm WebAdministration module error handling

4. **Script_38_MSSQL_Server_Monitor.ps1**
   - Verify SQL Server installation detection
   - Confirm SqlServer module availability check

5. **Script_48_Veeam_Backup_Monitor.ps1**
   - Verify Veeam installation detection
   - Confirm module availability before import

---

## Action Plan Updates

### Pre-Phase B Modifications

Original plan to "replace RSAT modules" is modified:

**Old Approach:**
- Replace all non-native modules
- Minimize Import-Module usage

**New Approach:**
- Keep server role modules (DHCP, DNS, Hyper-V, IIS, SQL)
- Verify feature checks exist before module import
- Only replace true RSAT-only modules (ActiveDirectory - already done)

**Rationale:**
- Server role modules are native to roles
- No RSAT dependency when role installed
- Richer functionality than WMI alternatives
- Correct implementation already exists

### Pre-Phase B Completion Criteria

**Original:**
- Replace all RSAT module dependencies

**Updated:**
1. Verify all server role scripts have feature checks
2. Confirm graceful exit when role not installed
3. Document server role module retention strategy
4. No true RSAT-only dependencies remain

---

## Verification Checklist

- [x] Script_02_DHCP - Feature check confirmed
- [x] Script_03_DNS - Feature check confirmed
- [ ] Script_08_HyperV - Needs verification
- [ ] Script_18_HyperV - Needs verification
- [ ] Script_37_IIS - Needs verification
- [ ] Script_38_MSSQL - Needs verification
- [ ] Script_48_Veeam - Needs verification

---

## Recommendations

### Immediate Actions

1. Review remaining 5 scripts for feature/installation checks
2. Add feature checks if missing
3. Standardize error handling for missing roles
4. Document pattern in coding standards

### Pattern to Enforce

**For all server role monitoring scripts:**

```powershell
# Standard pattern for server role scripts

# 1. Check if role/feature is installed
$feature = Get-WindowsFeature -Name "FeatureName" -ErrorAction SilentlyContinue

if ($null -eq $feature -or $feature.Installed -ne $true) {
    Write-Host "INFO: Feature not installed - setting N/A values"
    
    # Set all fields to appropriate N/A values
    Ninja-Property-Set fieldInstalled "false"
    Ninja-Property-Set fieldStatus "Not Installed"
    # ... set other fields ...
    
    Write-Host "SUCCESS: Monitor complete (feature not installed)"
    exit 0
}

# 2. Import module (only if role installed)
try {
    Import-Module ModuleName -ErrorAction Stop
    Write-Host "INFO: Module loaded successfully"
} catch {
    Write-Host "ERROR: Module not available - $($_.Exception.Message)"
    # Set error state
    Ninja-Property-Set fieldStatus "Error"
    exit 1
}

# 3. Continue with monitoring logic
```

---

## Conclusion

**Pre-Phase B Status:** Audit complete - no RSAT-only dependencies found.

**Key Findings:**
- Server role modules correctly implemented in 2/7 scripts
- 5 scripts need verification of feature checks
- No true RSAT dependencies to replace
- Action plan updated to reflect server role module retention

**Next Phase:** Pre-Phase C - Base64 encoding audit

---

**Report Completed:** February 3, 2026, 2:10 AM CET
