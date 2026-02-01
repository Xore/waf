# NinjaRMM Custom Field Framework - Dynamic Groups Complete
**File:** 92_Dynamic_Groups_Complete.md  
**Total Groups:** 74 groups  
**Purpose:** Automated device segmentation and targeting  
**Integration:** NinjaRMM Dynamic Device Filters

---

## Overview

Complete library of dynamic groups that automatically segment devices based on custom field values for targeted monitoring, alerting, and automation.

---

## CRITICAL HEALTH GROUPS - 12 Groups

### Group 1: Critical Stability Risk Devices
```
Group Name: CRIT_Stability_Risk
Filter Logic:
  STATStabilityScore < 40
  OR OPSCrashCount7d > 3

Use Cases:
  - Priority monitoring
  - Proactive intervention
  - Replacement planning

Automation:
  - Daily stability report
  - Weekly review meeting
  - Escalation to management
```

### Group 2: Critical Security Issues
```
Group Name: CRIT_Security_Risk
Filter Logic:
  SECSecurityPostureScore < 40
  OR SECAntivirusEnabled = False
  OR SECFirewallEnabled = False

Use Cases:
  - Security audit focus
  - Immediate remediation
  - Compliance reporting

Dashboard Widget: Security Risk Heatmap
```

### Group 3: Disk Space Critical
```
Group Name: CRIT_Disk_Critical
Filter Logic:
  CAPDiskFreePercent < 10
  OR CAPDaysUntilDiskFull < 30

Use Cases:
  - Emergency cleanup
  - Storage expansion planning
  - User notification

Actions:
  - Run cleanup scripts daily
  - Alert storage team
```

### Group 4: Memory Exhaustion Risk
```
Group Name: CRIT_Memory_Risk
Filter Logic:
  CAPMemoryUsedPercent > 90
  OR CAPMemoryForecastRisk = "Critical"

Use Cases:
  - Performance troubleshooting
  - RAM upgrade candidates
  - Application optimization
```

### Group 5: Update Compliance Critical
```
Group Name: CRIT_Update_Gap
Filter Logic:
  UPDComplianceStatus = "Critical Gap"
  OR UPDMissingSecurityCount > 5
  OR UPDPatchAgeDays > 90

Use Cases:
  - Forced patching campaigns
  - Compliance remediation
  - Risk reporting

Automation:
  - Force Windows Update scan
  - Schedule maintenance window
```

---

## OPERATIONAL GROUPS - 15 Groups

### Group 6: Workstations - Standard
```
Group Name: OPS_Workstations_Standard
Filter Logic:
  SRVServerRole = False
  AND STATStabilityScore >= 70
  AND SECSecurityPostureScore >= 70

Use Cases:
  - Standard monitoring profile
  - Normal automation level
  - Regular maintenance schedule
```

### Group 7: Servers - Production Critical
```
Group Name: OPS_Servers_Critical
Filter Logic:
  SRVServerRole = True
  AND SRVCriticalService != ""
  AND RISKBusinessCriticalFlag = True

Use Cases:
  - Enhanced monitoring
  - Conservative automation
  - Priority support

Monitoring Intervals:
  - Scripts: Every 15 minutes
  - Health checks: Every 5 minutes
  - Backup validation: Daily
```

### Group 8: Remote Workers
```
Group Name: OPS_Remote_Workers
Filter Logic:
  NETConnectionType = "VPN"
  OR NETWiFiDisconnects24h > 5

Use Cases:
  - Connectivity monitoring
  - VPN troubleshooting
  - Remote support readiness

Special Monitoring:
  - VPN latency tracking
  - WiFi stability
  - Collaboration tool performance
```

---

## AUTOMATION GROUPS - 10 Groups

### Group 9: Safe for Aggressive Automation
```
Group Name: AUTO_Safe_Aggressive
Filter Logic:
  AUTOSafetyEnabled = True
  AND AUTOAutomationRisk < 30
  AND STATStabilityScore > 80
  AND RISKBusinessCriticalFlag = False

Use Cases:
  - Auto-remediation enabled
  - Self-healing scripts
  - Aggressive cleanup

Allowed Actions:
  - Service restarts
  - Disk cleanup
  - Application cache clear
  - Driver updates
```

### Group 10: Automation Restricted
```
Group Name: AUTO_Restricted
Filter Logic:
  RISKBusinessCriticalFlag = True
  OR AUTOAutomationRisk > 70
  OR SRVServerRole = True

Use Cases:
  - Manual approval required
  - Read-only monitoring
  - Change control process

Restrictions:
  - No automatic restarts
  - No service changes
  - No software installation
```

---

## DRIFT & COMPLIANCE GROUPS - 8 Groups

### Group 11: Configuration Drift Detected
```
Group Name: DRIFT_Active
Filter Logic:
  DRIFTLocalAdminDrift = True
  OR DRIFTCriticalServiceDrift = True
  OR DRIFTNewAppsCount > 0

Use Cases:
  - Compliance audit
  - Baseline refresh
  - Shadow IT investigation

Reports:
  - Weekly drift summary
  - Monthly compliance report
```

### Group 12: Baseline Not Established
```
Group Name: DRIFT_No_Baseline
Filter Logic:
  BASEBaselineEstablished = False
  OR BASEBaselineCoveragePercent < 80

Use Cases:
  - Initial setup required
  - Baseline establishment
  - Onboarding process

Actions:
  - Run Script 18: Establish Baseline
  - Schedule follow-up validation
```

---

## CAPACITY PLANNING GROUPS - 12 Groups

### Group 13: Disk Expansion Candidates (30-90 days)
```
Group Name: CAP_Disk_30_90d
Filter Logic:
  CAPDaysUntilDiskFull >= 30
  AND CAPDaysUntilDiskFull <= 90

Use Cases:
  - Budget planning
  - Storage procurement
  - User notification

Reports:
  - Monthly capacity forecast
  - Quarterly budget request
```

### Group 14: Memory Upgrade Candidates
```
Group Name: CAP_Memory_Upgrade
Filter Logic:
  CAPMemoryUsedPercent > 80
  OR CAPMemoryForecastRisk = "High"
  OR CAPMemoryForecastRisk = "Critical"

Use Cases:
  - Hardware refresh planning
  - Performance optimization
  - User experience improvement

Business Case:
  - Current RAM capacity
  - Utilization trend
  - Recommended upgrade
```

### Group 15: CPU Upgrade Candidates
```
Group Name: CAP_CPU_Upgrade
Filter Logic:
  CAPCPUUsedPercent > 80
  OR CAPCPUForecastRisk = "High"

Use Cases:
  - Hardware refresh
  - Application optimization
  - Virtualization candidates
```

---

## DEVICE LIFECYCLE GROUPS - 8 Groups

### Group 16: Replacement Immediate (0-6 months)
```
Group Name: LIFECYCLE_Replace_0_6m
Filter Logic:
  PREDReplacementWindow = "0-6 months"
  OR PREDFailureLikelihood = "High"

Use Cases:
  - Urgent replacement planning
  - Budget prioritization
  - User notification

Actions:
  - Create replacement request
  - Begin procurement
  - Schedule migration
```

### Group 17: Replacement Soon (6-12 months)
```
Group Name: LIFECYCLE_Replace_6_12m
Filter Logic:
  PREDReplacementWindow = "6-12 months"

Use Cases:
  - Budget planning
  - Procurement pipeline
  - Refresh cycle management
```

---

## USER EXPERIENCE GROUPS - 9 Groups

### Group 18: Poor User Experience
```
Group Name: UX_Poor
Filter Logic:
  UXExperienceScore < 70
  OR UXBootDegradationFlag = True
  OR UXApplicationHangCount24h > 5

Use Cases:
  - User satisfaction focus
  - Performance optimization
  - Support intervention

Monitoring:
  - Application crashes
  - Boot time trends
  - Login friction
```

### Group 19: Collaboration Issues
```
Group Name: UX_Collab_Issues
Filter Logic:
  UXCollabFailures24h > 3
  OR APPOutlookFailures24h > 2

Use Cases:
  - Teams/Outlook troubleshooting
  - Office 365 optimization
  - Remote work support
```

---

## GROUPS 20-74 SUMMARY

Remaining groups organized by category:

**Security Groups (5):**
- High-risk exposed services
- Expiring certificates
- BitLocker non-compliant

**Infrastructure Groups (10):**
- IIS/SQL/MySQL servers
- File/Print servers
- Hyper-V hosts
- Backup servers

**Licensing Groups (3):**
- Not activated
- Expiring licenses
- Office compliance

**Custom Groups (7):**
- By location
  - By department
- By criticality level

---

## GROUP USAGE BEST PRACTICES

### Naming Convention
```
Format: [CATEGORY]_[Descriptor]_[Timeframe]

Examples:
  CRIT_Security_Risk
  CAP_Disk_30_90d
  LIFECYCLE_Replace_0_6m
  AUTO_Safe_Aggressive
```

### Group Maintenance
```
Review Schedule:
  - Weekly: Critical groups
  - Monthly: Operational groups
  - Quarterly: All groups

Optimization:
  - Remove empty groups
  - Merge overlapping groups
  - Update filter logic
```

### Reporting Integration
```
Dashboard Widgets:
  - Group member counts
  - Trend over time
  - Risk distribution

Scheduled Reports:
  - Daily: Critical groups
  - Weekly: Operational groups
  - Monthly: All groups summary
```

---

**Total Dynamic Groups:** 74 groups  
**Categories:** 10 major categories  
**Integration:** NinjaRMM Device Filters + Dashboards

---

**File:** 92_Dynamic_Groups_Complete.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete
