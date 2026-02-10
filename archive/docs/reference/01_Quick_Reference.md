# NinjaOne Custom Field Framework - Quick Reference Guide
**File:** 99_Quick_Reference_Guide.md  
**Version:** 1.0 (Native-Enhanced with Patching Automation)  
**Purpose:** Fast lookup and troubleshooting

---

## QUICK START

### 1. Deploy Core Fields (Day 1)
```
Fields to Create: 35 essential custom fields (OPS, STAT, RISK, AUTO, UX, SRV)
Native Monitoring: Enable CPU, Memory, Disk, SMART, Backup monitoring
Scripts to Deploy: None yet (data collection starts automatically)
Validation: Check field population after 24 hours
```

### 2. Deploy Core Scripts (Day 2)
```
Priority Scripts:
  - Script 15: Security Posture Consolidator
  - Script 7: Resource Monitor (if custom metrics needed)
  - Script 36: Server Role Detector

Test on 5-10 pilot devices first
```

### 3. Create Critical Conditions (Day 3) - Hybrid Native + Custom
```
Must-Have Conditions (Hybrid):
  1. P1_CriticalSystemFailure (Native Device Down + Custom Health Score)
  2. P1_DiskCriticalImminent (Native Disk < 5% + Custom Days Until Full)
  3. P1_MemoryExhaustionUnstable (Native Memory > 95% + Custom Crashes)
  4. P1_SMARTFailureDetected (Native SMART + Custom Risk Level)
  5. P1_SecurityControlsDown (Native AV/Firewall + Custom Security Score)
```

### 4. Create Core Groups (Day 4)
```
Essential Groups:
  1. CRIT_Stability_Risk
  2. CRIT_Security_Risk
  3. CRIT_Disk_Critical
  4. OPS_Workstations_Standard
  5. OPS_Servers_Critical
```

---

## FIELD QUICK LOOKUP

### Most Important Fields (Top 20) - v4.0

| Field Name | Type | Purpose | Update Frequency | Native Alternative |
|------------|------|---------|------------------|-------------------|
| OPSHealthScore | Integer (0-100) | Composite health | Every 4h | None (custom calc) |
| OPSPerformanceScore | Integer (0-100) | Performance assessment | Every 4h | None (custom calc) |
| STATStabilityScore | Integer (0-100) | Overall stability | Every 4h | None (custom calc) |
| SECSecurityPostureScore | Integer (0-100) | Security health | Daily | None (custom calc) |
| CAPDaysUntilDiskFull | Integer | Predictive capacity | Daily | None (custom forecast) |
| STATCrashCount30d | Integer | Crash count | Daily | None (event log derived) |
| RISKExposureLevel | Dropdown | Risk classification | Manual | None (manual set) |
| BASEBusinessCriticality | Dropdown | Criticality tier | Manual | None (manual set) |
| AUTORemediationEligible | Checkbox | Automation safety | Manual | None (manual set) |
| BASEDriftScore | Integer (0-100) | Config drift level | Daily | None (custom calc) |

**Note:** Use native metrics for real-time monitoring:
- CPU → Native: CPU Utilization %
- Memory → Native: Memory Utilization %
- Disk → Native: Disk Free Space %
- SMART → Native: SMART Status
- Device Online → Native: Device Down/Offline
- Backup → Native: Backup Status
- Antivirus → Native: Antivirus Status
- Patches → Native: Patch Status

### Critical Server Fields (Top 10)

| Field Name | Purpose | When to Alert | Native Alternative |
|------------|---------|---------------|-------------------|
| VEEAMFailedJobsCount | Backup failures | > 0 | Native: Backup Status = Failed |
| MSSQLLastBackup | SQL backup time | > 24h ago | Check manually or script |
| IISAppPoolsStopped | IIS pools down | > 0 | Windows Service Status |
| DHCPScopesDepleted | DHCP exhaustion | > 0 | Custom (no native) |
| DNSHealthStatus | DNS health | "Critical" | Windows Service Status |
| HVHealthStatus | Hyper-V health | "Critical" | Windows Service Status |

---

## SCRIPT QUICK LOOKUP

### Most Important Scripts - v4.0

| Script | Name | Frequency | Runtime | Priority | Notes |
|--------|------|-----------|---------|----------|-------|
| 15 | Security Posture Consolidator | Daily | 35s | Critical | Combines native + custom |
| 36 | Server Role Detector | Daily | 25s | High | Auto-detects server roles |
| 22 | Capacity Trend Forecaster | Weekly | 35s | High | Predictive analytics |
| 23 | Update Compliance Monitor | Daily | 45s | Critical | Works with native patch data |
| 18 | Baseline Establishment | Once | 2min | High | Initial setup |
| **PR1** | **Patch Ring 1 Test Deploy** | **Weekly** | **Variable** | **Critical** | **NEW v4.0** |
| **PR2** | **Patch Ring 2 Prod Deploy** | **Weekly** | **Variable** | **Critical** | **NEW v4.0** |
| **P1** | **Critical Device Validator** | **Pre-patch** | **30s** | **Critical** | **NEW v4.0** |

### Troubleshooting Scripts

| Issue | Run Script | Expected Result |
|-------|------------|-----------------|
| Disk full | Script 50: Emergency Cleanup | Free 2-5GB |
| Service down | Script 41-45: Service Restart | Service running |
| Poor performance | Script 55: Memory Optimization | Improved RAM |
| Drift detected | Script 18: Baseline Refresh | Updated baseline |
| Security issue | Script 61-65: Security Hardening | Improved posture |

---

## CONDITION QUICK LOOKUP - v4.0 HYBRID

### Critical Conditions (Must Create) - Native + Custom

```
1. Critical System Failure (P1)
   Logic: (Device Down = True OR CPU Utilization > 95% for 10min)
          AND OPSHealthScore < 40
          AND STATCrashCount30d > 0
   Action: Create ticket P1, Run Script 40

2. Disk Critical Imminent (P1)
   Logic: Disk Free Space < 5%
          AND CAPDaysUntilDiskFull < 3
          AND OPSHealthScore < 50
   Action: Create ticket P1, Run Script 50

3. Memory Exhaustion Unstable (P1)
   Logic: Memory Utilization > 95% for 15min
          AND STATCrashCount30d > 2
          AND OPSHealthScore < 50
   Action: Create ticket P1, Run memory diagnostic

4. SMART Failure Detected (P1)
   Logic: SMART Status = Failed
          AND RISKExposureLevel = "Critical"
   Action: Create ticket P1, Begin replacement

5. Security Controls Down (P1)
   Logic: (Antivirus Status = Disabled OR Antivirus Status = Outdated)
          AND SECSecurityPostureScore < 40
   Action: Create ticket P1, Run Script 61

6. Patch Failed Vulnerable (P1) - NEW v4.0
   Logic: Patch Status = Failed
          AND patchLastAttemptStatus CONTAINS "Critical"
          AND RISKExposureLevel IN ("High", "Critical")
   Action: Create ticket P1, Run Script P1 validator
```

---

## GROUP QUICK LOOKUP

### Essential Groups (Top 10)

```
1. CRIT_Stability_Risk
   Filter: STATStabilityScore < 40 OR STATCrashCount30d > 5
   Use: Priority intervention

2. CRIT_Security_Risk
   Filter: SECSecurityPostureScore < 40 OR Antivirus Status = Disabled
   Use: Security remediation

3. CRIT_Disk_Critical
   Filter: Disk Free Space < 10% OR CAPDaysUntilDiskFull < 30
   Use: Disk cleanup

4. CRIT_Update_Gap
   Filter: Patch Status CONTAINS "Failed" OR patchLastAttemptStatus = "Critical Gap"
   Use: Patch management

5. OPS_Servers_Critical
   Filter: SRVServerRole = True AND RISKBusinessCriticalFlag = True
   Use: Enhanced monitoring

6. AUTO_Safe_Aggressive
   Filter: AUTORemediationEligible = True AND STATStabilityScore > 80
   Use: Auto-remediation

7. PATCH_Ring_PR1_Test - NEW v4.0
   Filter: patchRing = "PR1-Test"
   Use: Test ring patching

8. PATCH_Ring_PR2_Production - NEW v4.0
   Filter: patchRing = "PR2-Production"
   Use: Production patching

9. DRIFT_Active
   Filter: BASEDriftScore > 60 OR DRIFTLocalAdminDrift = True
   Use: Compliance audit

10. UX_Poor
    Filter: UXExperienceScore < 70
    Use: User satisfaction
```

---

## TROUBLESHOOTING

### Field Not Populating

```
Problem: Custom field shows empty value
Checks:
  1. Verify script is scheduled and running
  2. Check script execution logs for errors
  3. Confirm device is online (Native: Device Down = False)
  4. Verify field name matches in script
  5. Check script has necessary permissions

Solution:
  - Run script manually on affected device
  - Check NinjaOne script history
  - Review error messages
```

### Script Failing

```
Problem: Script execution fails or times out
Checks:
  1. Review script error log
  2. Check PowerShell execution policy
  3. Verify required modules installed
  4. Check script runs as SYSTEM account
  5. Confirm timeout settings (increase if needed)

Solution:
  - Test script locally as SYSTEM
  - Add error handling
  - Break into smaller scripts
  - Increase timeout from 60s to 120s
```

### Condition Not Triggering

```
Problem: Automation condition doesn't fire
Checks:
  1. Verify both native metrics AND custom fields have correct values
  2. Check condition logic syntax (hybrid conditions)
  3. Confirm condition is enabled
  4. Review condition check frequency
  5. Verify device matches ALL criteria

Solution:
  - Test condition logic manually
  - Check native metric availability
  - Verify custom field data types match
  - Enable condition logging
  - Review condition history
```

### Automation Safety

```
Problem: Worried about automation causing issues
Checks:
  1. AUTORemediationEligible = True
  2. STATStabilityScore > 80
  3. RISKBusinessCriticalFlag = False for test devices
  4. Use AUTO_Safe_Aggressive group

Solution:
  - Start with read-only scripts
  - Test on non-production devices
  - Enable manual approval for critical servers
  - Monitor automation logs closely
```

---

## COMMON PATTERNS

### Pattern 1: New Device Onboarding (v4.0)
```
Day 1: Device added to NinjaOne
       Native metrics populate immediately (CPU, Memory, Disk, etc.)
       Core custom fields start populating (via scripts)

Day 2: Run Script 18 to establish baseline
       Run Script 36 to detect server roles
       Wait 24 hours for full data collection

Day 3: Device classified into dynamic groups
       Hybrid conditions begin monitoring
       Patching ring assigned (PR1 or PR2)

Day 4: Full automation enabled
       Device fully integrated
```

### Pattern 2: Server Deployment (v4.0)
```
Step 1: Set RISKBusinessCriticalFlag = True
Step 2: Set BASEBusinessCriticality = "Critical"
Step 3: Set patchRing = "PR2-Production"
Step 4: Assign to OPS_Servers_Critical group
Step 5: Configure server-specific scripts (9-13)
Step 6: Enable enhanced monitoring (every 15min)
Step 7: Create hybrid conditions (Native + Custom)
Step 8: Restrict automation to manual approval
```

### Pattern 3: Patching Workflow (v4.0) - NEW
```
Week 1 - Tuesday:
  Step 1: PR1 devices validated (Script P1/P2)
  Step 2: Script PR1 deploys patches to test ring
  Step 3: Monitor for 7 days (soak period)
  Step 4: Track patchLastAttemptStatus

Week 2 - Tuesday (after 90%+ PR1 success):
  Step 1: PR2 devices validated (Script P1-P4 by priority)
  Step 2: Script PR2 deploys patches to production
  Step 3: Monitor patchValidationStatus
  Step 4: Automated rollback if failures detected
```

### Pattern 4: Hybrid Condition Creation (v4.0)
```
Old v3.0 Approach:
  Custom: CAPDiskFreePercent < 10
  Problem: Script delay, false positives

New v4.0 Approach:
  Native: Disk Free Space < 10% (real-time)
  AND Custom: CAPDaysUntilDiskFull < 7 (predictive)
  AND Custom: OPSHealthScore < 60 (context)
  Result: High confidence, low false positives
```

---

## NATIVE METRICS REFERENCE (v4.0)

### Available Native Metrics
```
System Health:
  - CPU Utilization % (real-time)
  - Memory Utilization % (real-time)
  - Disk Free Space % and absolute (real-time)
  - Disk Active Time % (real-time)
  - SMART Status (per drive)

System State:
  - Device Down/Offline (real-time)
  - Pending Reboot (OS flag)
  - Windows Service Status (per service)
  - Windows Event Log (Event IDs)

Security:
  - Antivirus Status (enabled/disabled/current/outdated)
  - Firewall Status
  - Backup Status (success/failed/warning)
  - Patch Status (installed/failed/missing)
```

### When to Use Native vs Custom
```
Use Native:
  - Real-time system metrics (CPU, Memory, Disk)
  - Binary state (Online/Offline, Enabled/Disabled)
  - Built-in monitoring (AV, Backup, Patches)
  - Service status
  - Event logs

Use Custom:
  - Composite scores (Health, Performance, Stability)
  - Predictive analytics (Days Until Disk Full)
  - Historical aggregation (Crash count 30d)
  - Business classification (Criticality, Risk)
  - Drift detection
  - Automation control flags
```

---

## PATCHING QUICK REFERENCE (v4.0) - NEW

### Patching Fields
```
patchRing - Dropdown: PR1-Test, PR2-Production
patchLastAttemptDate - DateTime: Last patch attempt
patchLastAttemptStatus - Text: Success/Failed/reason
patchLastPatchCount - Integer: Patches installed
patchRebootPending - Checkbox: Reboot required
patchValidationStatus - Dropdown: Passed/Failed/Error/Pending
patchValidationNotes - Text: Validation details
patchValidationDate - DateTime: Validation timestamp
```

### Patching Scripts
```
Script PR1: Test ring deployment (10-20 devices, Tuesday Week 1)
Script PR2: Production deployment (all devices, Tuesday Week 2)
Script P1: Critical device validator (Health ≥ 80, Backup ≤ 24h)
Script P2: High priority validator (Health ≥ 70, Backup ≤ 72h)
Script P3-P4: Medium/low validator (Health ≥ 60/50)
```

### Patching Groups
```
PATCH_Ring_PR1_Test: patchRing = "PR1-Test"
PATCH_Ring_PR2_Production: patchRing = "PR2-Production"
PATCH_Validation_Failed: patchValidationStatus = "Failed"
PATCH_Reboot_Pending: patchRebootPending = True
```

### Patching Conditions
```
P1_PatchFailedVulnerable: Patch Failed + Critical Exposure
P2_MultiplePatchesFailed: 3+ failures in 30 days
P2_PendingRebootUpdates: Reboot pending > 7 days
P4_PatchesCurrent: Compliant status (positive health)
```

---

## VERSION COMPARISON

| Feature | v3.0 | v4.0 | Change |
|---------|------|------|--------|
| Custom Fields | 358 | 277 | -81 (-23%) |
| Scripts | 105 | 110 | +5 (patching) |
| Native Metrics | 0 | 12+ | New |
| Compound Conditions | 69 | 75 | +6 (patching) |
| Deployment Time | 8 weeks | 4-8 weeks | 50% faster core |
| False Positives | ~30% | ~10% | -70% |
| Patching | Manual | Automated | New feature |

---

**File:** 99_Quick_Reference_Guide.md  
**Version:** 1.0 (Native-Enhanced with Patching Automation)  
**Last Updated:** February 1, 2026  
**Status:** Production Ready
