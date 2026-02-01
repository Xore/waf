# NinjaRMM Custom Field Framework - Quick Reference Guide
**File:** 99_Quick_Reference_Guide.md  
**Version:** 3.0  
**Purpose:** Fast lookup and troubleshooting

---

## QUICK START

### 1. Deploy Core Fields (Day 1)
```
Fields to Create: OPS, STAT, RISK categories (~70 fields)
Scripts to Deploy: None yet (data collection starts automatically)
Validation: Check field population after 24 hours
```

### 2. Deploy Core Scripts (Day 2)
```
Priority Scripts:
  - Script 15: Security Posture Consolidator
  - Script 4: Security Analyzer (if not running)
  - Script 7: Resource Monitor

Test on 5-10 pilot devices first
```

### 3. Create Critical Conditions (Day 3)
```
Must-Have Conditions:
  1. CRIT_SecurityControlsDown
  2. CRIT_StabilityRisk
  3. CRIT_DiskSpaceLow
  4. CRIT_MemoryExhaustion
  5. CRIT_UpdateGap
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

### Most Important Fields (Top 20)

| Field Name | Type | Purpose | Update Frequency |
|------------|------|---------|------------------|
| OPSSystemOnline | Checkbox | Device reachability | Real-time |
| STATStabilityScore | Integer (0-100) | Overall stability | Every 4h |
| SECSecurityPostureScore | Integer (0-100) | Security health | Daily |
| CAPDiskFreePercent | Integer (0-100) | Disk space | Every 4h |
| CAPMemoryUsedPercent | Integer (0-100) | Memory utilization | Every 4h |
| UPDComplianceStatus | Dropdown | Patch status | Daily |
| DRIFTLocalAdminDrift | Checkbox | Admin changes | Daily |
| AUTOSafetyEnabled | Checkbox | Automation control | Manual |
| RISKBusinessCriticalFlag | Checkbox | Criticality | Manual |
| UXExperienceScore | Integer (0-100) | User experience | Daily |

### Critical Server Fields (Top 10)

| Field Name | Purpose | When to Alert |
|------------|---------|---------------|
| VEEAMFailedJobsCount | Backup failures | > 0 |
| MSSQLLastBackup | SQL backup time | > 24h ago |
| IISAppPoolsStopped | IIS pools down | > 0 |
| DHCPScopesDepleted | DHCP exhaustion | > 0 |
| DNSHealthStatus | DNS health | "Critical" |
| HVHealthStatus | Hyper-V health | "Critical" |

---

## SCRIPT QUICK LOOKUP

### Most Important Scripts

| Script | Name | Frequency | Runtime | Priority |
|--------|------|-----------|---------|----------|
| 4 | Security Analyzer | 4h / Daily | 30s | Critical |
| 7 | Resource Monitor | 4h | 20s | Critical |
| 8 | Network Monitor | 4h | 20s | High |
| 10 | MSSQL Server Monitor | 4h | 45s | Critical |
| 13 | Veeam Backup Monitor | Daily | 35s | Critical |
| 15 | Security Posture Consolidator | Daily | 35s | Critical |
| 18 | Baseline Establishment | Once | 2min | High |
| 23 | Update Compliance Monitor | Daily | 45s | Critical |

### Troubleshooting Scripts

| Issue | Run Script | Expected Result |
|-------|------------|-----------------|
| Disk full | Script 50: Emergency Cleanup | Free 2-5GB |
| Service down | Script 41-45: Service Restart | Service running |
| Poor performance | Script 55: Memory Optimization | Improved RAM |
| Drift detected | Script 18: Baseline Refresh | Updated baseline |
| Security issue | Script 61-65: Security Hardening | Improved posture |

---

## CONDITION QUICK LOOKUP

### Critical Conditions (Must Create)

```
1. Security Controls Down
   Logic: SECAntivirusEnabled = False OR SECFirewallEnabled = False
   Action: Create ticket P1, Run Script 61

2. Stability Critical
   Logic: STATStabilityScore < 40
   Action: Create ticket P1, Run Script 40

3. Disk Critical
   Logic: CAPDiskFreePercent < 5
   Action: Create ticket P1, Run Script 50

4. Update Gap
   Logic: UPDComplianceStatus = "Critical Gap"
   Action: Create ticket P1, Run Script 23

5. Backup Failed
   Logic: VEEAMFailedJobsCount > 0
   Action: Create ticket P1, Run Script 45
```

---

## GROUP QUICK LOOKUP

### Essential Groups (Top 10)

```
1. CRIT_Stability_Risk
   Filter: STATStabilityScore < 40
   Use: Priority intervention

2. CRIT_Security_Risk
   Filter: SECSecurityPostureScore < 40
   Use: Security remediation

3. CRIT_Disk_Critical
   Filter: CAPDiskFreePercent < 10
   Use: Disk cleanup

4. CRIT_Update_Gap
   Filter: UPDComplianceStatus = "Critical Gap"
   Use: Patch management

5. OPS_Servers_Critical
   Filter: SRVServerRole = True AND RISKBusinessCriticalFlag = True
   Use: Enhanced monitoring

6. AUTO_Safe_Aggressive
   Filter: AUTOAutomationRisk < 30 AND STATStabilityScore > 80
   Use: Auto-remediation

7. LIFECYCLE_Replace_0_6m
   Filter: PREDReplacementWindow = "0-6 months"
   Use: Replacement planning

8. DRIFT_Active
   Filter: DRIFTLocalAdminDrift = True OR DRIFTNewAppsCount > 0
   Use: Compliance audit

9. CAP_Disk_30_90d
   Filter: CAPDaysUntilDiskFull BETWEEN 30 AND 90
   Use: Capacity planning

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
  3. Confirm device is online
  4. Verify field name matches in script
  5. Check script has necessary permissions

Solution:
  - Run script manually on affected device
  - Check NinjaRMM script history
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
  1. Verify custom fields have correct values
  2. Check condition logic syntax
  3. Confirm condition is enabled
  4. Review condition check frequency
  5. Verify device matches condition

Solution:
  - Test condition logic manually
  - Check field data types match
  - Enable condition logging
  - Review condition history
```

### Automation Safety

```
Problem: Worried about automation causing issues
Checks:
  1. AUTOSafetyEnabled = True
  2. AUTOAutomationRisk < 30
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

### Pattern 1: New Device Onboarding
```
Day 1: Device added to NinjaRMM
       Core fields start populating automatically

Day 2: Run Script 18 to establish baseline
       Wait 24 hours for data collection

Day 3: Device classified into dynamic groups
       Conditions begin monitoring

Day 4: Full automation enabled
       Device fully integrated
```

### Pattern 2: Server Deployment
```
Step 1: Set RISKBusinessCriticalFlag = True
Step 2: Set AUTOAutomationRisk = High
Step 3: Assign to OPS_Servers_Critical group
Step 4: Configure server-specific scripts (9-13)
Step 5: Enable enhanced monitoring (every 15min)
Step 6: Restrict automation to manual approval
```

### Pattern 3: Problem Device
```
Symptoms: High ticket volume, user complaints
Diagnosis:
  - Check STATStabilityScore (target: >70)
  - Check UXExperienceScore (target: >70)
  - Review OPSCrashCount7d (target: <3)
  - Check drift fields

Remediation:
  - Run Script 40: System Health Diagnostics
  - Run Script 18: Baseline Refresh
  - Consider hardware upgrade if scores remain low
```

---

## DASHBOARD WIDGETS

### Recommended Widgets (Top 10)

```
1. Critical Devices Count
   Source: CRIT_Stability_Risk + CRIT_Security_Risk groups
   Alert: > 5 devices

2. Average Stability Score
   Source: STATStabilityScore field
   Target: > 80

3. Security Posture Distribution
   Source: SECSecurityPostureScore field
   Alert: > 10% below 70

4. Disk Space Alerts
   Source: CRIT_Disk_Critical group
   Alert: > 0 devices

5. Update Compliance
   Source: UPDComplianceStatus field
   Target: > 90% "Compliant" or "Minor Gap"

6. Backup Health
   Source: VEEAMFailedJobsCount > 0
   Alert: Any failures

7. Configuration Drift
   Source: DRIFT_Active group count
   Review: Weekly

8. Replacement Pipeline
   Source: LIFECYCLE_Replace_0_6m group
   Use: Budget planning

9. Automation Coverage
   Source: AUTOSafetyEnabled = True count
   Target: > 80% of non-critical devices

10. Script Execution Success
    Source: NinjaRMM script success rate
    Target: > 95%
```

---

## CHEAT SHEET

### Field Naming Convention
```
Format: [CATEGORY][PascalCaseDescriptor]

Examples:
  OPSSystemOnline          (Good)
  ops_system_online        (Bad - use PascalCase)
  OPSSYSTEMONLINE          (Bad - hard to read)
```

### Script Naming Convention
```
Format: [Number]_[Category]_[Function].ps1

Examples:
  15_SEC_SecurityPostureConsolidator.ps1
  40_REMED_AutomationSafetyValidator.ps1
```

### Condition Naming Convention
```
Format: [PRIORITY]_[Descriptor]

Examples:
  CRIT_SecurityControlsDown
  HIGH_ConfigDrift
  MED_CleanupNeeded
```

### Group Naming Convention
```
Format: [CATEGORY]_[Descriptor]_[Timeframe]

Examples:
  CRIT_Stability_Risk
  CAP_Disk_30_90d
  LIFECYCLE_Replace_0_6m
```

---

## COMMON FIELD VALUES

### Stability Score
```
90-100: Excellent
70-89:  Good
50-69:  Fair
30-49:  Poor
0-29:   Critical
```

### Security Posture Score
```
90-100: Excellent
70-89:  Good
50-69:  Needs Attention
30-49:  At Risk
0-29:   Critical
```

### Update Compliance Status
```
Compliant:      Last update < 30 days, no security gaps
Minor Gap:      Last update 30-45 days
Significant Gap: Last update 45-90 days OR 1-2 security updates
Critical Gap:   Last update > 90 days OR 3+ security updates
Unknown:        Cannot determine
```

### Automation Risk Levels
```
0-20:   Very Low (safe for aggressive automation)
21-40:  Low (safe for standard automation)
41-60:  Medium (manual approval recommended)
61-80:  High (restricted automation)
81-100: Very High (no automation)
```

---

## SUPPORT RESOURCES

### Documentation Files
```
Field Definitions:      Files 10-24
Script Repository:      Files 53-60
Compound Conditions:    File 91
Dynamic Groups:         File 92
Complete Summary:       File 98 (this file)
Quick Reference:        File 99
```

### Contact Information
```
Framework Support:      See File 98
Deployment Assistance:  See Files 91-99
Custom Modifications:   Document in local files
```

---

## VERSION HISTORY

```
Version 3.0 (Feb 2026):
  - Complete framework with 358 fields
  - 102 PowerShell scripts
  - 69 compound conditions
  - 74 dynamic groups
  - Full documentation suite

Version 2.0 (Jan 2026):
  - Added server infrastructure fields
  - Extended automation scripts
  - Advanced telemetry

Version 1.0 (Dec 2025):
  - Initial core framework
  - Basic monitoring fields
  - Foundation scripts
```

---

**This is your go-to reference for day-to-day operations.**  
**Bookmark this file for quick access!**

---

**File:** 99_Quick_Reference_Guide.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete
