# NinjaRMM Framework 4.0 - PowerShell Scripts

This directory contains production-ready PowerShell scripts for the NinjaRMM monitoring and automation framework.

## Repository Information

**Repository:** [Xore/waf](https://github.com/Xore/waf)  
**Scripts Directory:** [`/scripts`](https://github.com/Xore/waf/tree/main/scripts)  
**Framework Version:** 4.0  
**Last Updated:** February 2, 2026  
**Total Scripts:** 31 production-ready scripts

---

## Scripts Inventory

### Core Monitoring Scripts (1-8)

| Script | Filename | Purpose | Frequency | Fields Updated |
|--------|----------|---------|-----------|----------------|
| **01** | `01_System_Health_Collector.ps1` | System health metrics and scoring | Every 30 min | opsHealthScore, opsLastHealthCheck, opsComponentHealth |
| **02** | `02_Stability_Crash_Tracker.ps1` | System stability and crash tracking | Daily | statStabilityScore, statCrashCount30d, statCrashTrend |
| **03** | `03_User_Experience_Collector.ps1` | User experience metrics | Every 4 hours | uxExperienceScore, uxApplicationHangCount24h |
| **04** | `04_Application_Performance_Profiler.ps1` | Application performance monitoring | Every 4 hours | appTopCPUApp, appTopMemoryApp |
| **05** | `05_Network_Diagnostics.ps1` | Network connectivity and performance | Every 4 hours | netConnectivityScore, netLatencyMs, netPacketLoss |
| **06** | `06_Update_Patch_Status_Collector.ps1` | Windows Update status tracking | Every 4 hours | updMissingCriticalCount, updLastPatchCheck |
| **07** | `07_Security_Posture_Evaluator.ps1` | Security configuration assessment | Daily | secFirewallEnabled, secAntivirusStatus, secEncryptionEnabled |
| **08** | `08_Backup_Recovery_Validator.ps1` | Backup verification and validation | Daily | backupLastSuccess, backupAge, backupSizeGB |

### Resource Management Scripts (9-14)

| Script | Filename | Purpose | Frequency | Fields Updated |
|--------|----------|---------|-----------|----------------|
| **09** | `09_Capacity_Management_Forecaster.ps1` | Disk capacity forecasting | Daily | capDaysUntilFull, capForecastDate |
| **10** | `10_Storage_Health_Monitor.ps1` | Storage health and SMART monitoring | Daily | stoHealthStatus, stoSMARTWarnings |
| **11** | `11_Asset_Inventory_Compliance.ps1` | Hardware/software inventory | Weekly | asetLastInventoryDate, asetCompliance |
| **12** | `12_Operational_Intelligence_Calculator.ps1` | Operational metrics and forecasting | Daily | opsPerformanceScore, opsPredictedIssues |
| **14** | `14_Automation_Remediation_Eligibility.ps1` | Automation eligibility assessment | Daily | autoRemediationEligible, autoConfidenceScore |

### Advanced Monitoring Scripts (15-21)

| Script | Filename | Purpose | Frequency | Fields Updated |
|--------|----------|---------|-----------|----------------|
| **15** | `15_Dynamic_Priority_Classifier.ps1` | Dynamic device priority classification | Daily | basePriorityLevel, basePriorityReason |
| **16** | `16_Compound_Condition_Evaluator.ps1` | Multi-condition evaluation engine | Every 4 hours | condActiveConditions, condCriticalConditions |
| **17** | `17_Application_Experience_Profiler.ps1` | Application crash and hang tracking | Daily | uxApplicationHangCount24h, appTopCrashingApp |
| **18** | `18_Profile_Hygiene_Cleanup_Advisor.ps1` | Cleanup opportunity identification | Daily | cleanupRecommendedCleanupMB, cleanupCleanupPriority |
| **19** | `19_Proactive_Remediation_Engine.ps1` | Automated issue remediation | Every 4 hours | autoLastRemediationDate, autoLastRemediationAction |
| **20** | `20_Server_Role_Identifier.ps1` | Server role and service detection | Weekly | srvRole, srvCriticalServices, baseDeviceType |
| **21** | `21_Battery_Health_Monitor.ps1` | Battery health monitoring (laptops) | Daily | hwBatteryCapacityPercent, hwBatteryWearLevel |

### Advanced Telemetry Scripts (29-32)

| Script | Filename | Purpose | Frequency | Fields Updated |
|--------|----------|---------|-----------|----------------|
| **29** | `29_Collaboration_Outlook_UX_Telemetry.ps1` | Teams and Outlook performance | Every 4 hours | uxCollabFailures24h, appOutlookFailures24h |
| **30** | `30_Advanced_Threat_Telemetry.ps1` | Advanced threat detection | Every 4 hours | secFailedLoginCount24h, secSuspiciousActivityCount |
| **31** | `31_Endpoint_Detection_Response.ps1` | EDR and antivirus monitoring | Every 4 hours | secEDREnabled, secThreatsDetected24h |
| **32** | `32_Compliance_Attestation_Reporter.ps1` | Compliance score generation | Daily | compComplianceScore, compAttestationStatus |

### Patching Automation Scripts (PR1, PR2, P1-P4)

| Script | Filename | Purpose | Frequency | Target Devices |
|--------|----------|---------|-----------|----------------|
| **PR1** | `PR1_Patch_Ring1_Deployment.ps1` | Test ring patch deployment | Weekly (Tuesday) | patchRing=PR1 or Test tag |
| **PR2** | `PR2_Patch_Ring2_Deployment.ps1` | Production ring deployment | Weekly (Tuesday+7 days) | patchRing=PR2 or Production tag |
| **P1** | `P1_Critical_Device_Validator.ps1` | P1 Critical device validation | Pre-deployment | basePriorityLevel=P1 |
| **P2** | `P2_High_Priority_Validator.ps1` | P2 High priority validation | Pre-deployment | basePriorityLevel=P2 |
| **P3-P4** | `P3_P4_Medium_Low_Validator.ps1` | P3/P4 validation | Pre-deployment | basePriorityLevel=P3 or P4 |

---

## Script Standards

All scripts follow NinjaRMM Framework 4.0 standards:

- **No special characters** in script output (Space-compliant)
- **No emojis** in any output or comments
- **Comprehensive error handling** with try-catch blocks
- **Detailed logging** where appropriate
- **Custom field integration** using Ninja-Property-Set/Get
- **Exit codes**: 0 = success, 1 = error
- **Timeout specifications** in script headers
- **Context requirements** documented (SYSTEM/USER)

---

## Usage Instructions

### Quick Start

1. **Import scripts to NinjaRMM:**
   - Navigate to Administration > Automation > Scripting
   - Create new PowerShell script
   - Copy content from GitHub repository
   - Set execution frequency per script header

2. **Configure custom fields:**
   - Import custom field definitions from framework documentation
   - Ensure all field names match script expectations
   - Configure field permissions (Read/Write)

3. **Deploy to devices:**
   - Assign scripts to appropriate device groups
   - Configure scheduling per script recommendations
   - Monitor initial execution for errors

### Execution Frequencies

| Frequency | Scripts | Use Case |
|-----------|---------|----------|
| **Every 30 min** | 01 | Real-time health monitoring |
| **Every 4 hours** | 03, 04, 05, 06, 16, 19, 29, 30, 31 | Regular telemetry collection |
| **Daily** | 02, 07, 08, 09, 10, 12, 14, 15, 17, 18, 21, 32 | Daily health checks |
| **Weekly** | 11, 20 | Low-frequency inventory |
| **Manual/Scheduled** | PR1, PR2, P1, P2, P3-P4 | Controlled patch deployment |

---

## Patching Workflow

The patching automation scripts implement a ring-based deployment strategy:

### Week 1: Test Ring (PR1)

1. **Tuesday 10:00 AM:** Deploy critical patches to PR1 test devices
2. **Validation:** Pre-deployment health checks (P1-P4 validators)
3. **Monitoring:** 7-day soak period with daily health checks

### Week 2: Production Ring (PR2)

1. **Validation Gate:** PR1 success rate must be >= 90%
2. **Tuesday 10:00 AM:** Deploy patches to PR2 production devices
3. **Priority-based deployment:**
   - **P1 (Critical):** Manual with change approval
   - **P2 (High):** Automated during maintenance windows
   - **P3 (Medium):** Automated, flexible timing
   - **P4 (Low):** Fully automated

### Validator Thresholds

| Priority | Health Score | Stability Score | Backup Age | Disk Space |
|----------|--------------|-----------------|------------|------------|
| **P1** | >= 80 | >= 80 | <= 24 hours | >= 15 GB |
| **P2** | >= 70 | >= 70 | <= 72 hours | >= 10 GB |
| **P3** | >= 60 | >= 60 | No requirement | >= 10 GB |
| **P4** | >= 50 | No requirement | No requirement | >= 10 GB |

---

## Integration with NinjaRMM

### Custom Field Categories

Scripts update fields across 13 categories:

1. **BASE** - Base device information
2. **OPS** - Operational metrics
3. **STAT** - Stability statistics
4. **UX** - User experience
5. **APP** - Application performance
6. **NET** - Network diagnostics
7. **UPD** - Update/patch status
8. **SEC** - Security posture
9. **BACKUP** - Backup validation
10. **CAP** - Capacity management
11. **STO** - Storage health
12. **ASET** - Asset inventory
13. **COMP** - Compliance

### Compound Conditions

Scripts work with pre-defined compound conditions:

- **P1** - Critical priority devices with multiple failures
- **P2** - High priority devices needing attention
- **P3** - Medium priority with warnings
- **P4** - Low priority information

---

## Troubleshooting

### Common Issues

**Issue:** Script fails with "Ninja-Property-Set not recognized"  
**Solution:** Ensure script runs in NinjaRMM agent context, not standalone PowerShell

**Issue:** Custom field not updating  
**Solution:** Verify field name matches exactly (case-sensitive), check field permissions

**Issue:** Script times out  
**Solution:** Increase timeout value in script configuration, check for network/disk delays

**Issue:** Validation script always fails  
**Solution:** Check that prerequisite scripts have run (health score, stability score populated)

### Log Locations

- **Patching logs:** `C:\ProgramData\NinjaRMM\Logs\PatchRing*.log`
- **Script execution:** NinjaRMM Activity Log in web interface
- **Windows Event Log:** Application and System logs for diagnostic events

---

## Support and Documentation

### Framework Documentation

- **Custom Fields:** See `01_CustomFields_BASE_Master.md` in repository
- **Compound Conditions:** See `03_CompoundConditions_P1_P2_P3_P4.md`
- **Patching Details:** See `61_Scripts_Patching_Automation.md`

### Best Practices

1. **Start with core monitoring scripts** (01-08) before advanced features
2. **Test in staging environment** before production deployment
3. **Monitor script execution times** and adjust timeouts as needed
4. **Review custom field data** weekly for accuracy
5. **Use validation scripts** before patch deployments
6. **Configure alerting** on compound conditions for proactive management

### Version History

- **v4.0** (February 2, 2026) - Initial production release with 31 scripts
- Complete rewrite from Framework 3.0
- Space-compliant formatting (no special characters/emojis)
- Enhanced patching automation with ring-based deployment
- Advanced telemetry and compliance reporting

---

**Repository:** https://github.com/Xore/waf  
**Scripts:** https://github.com/Xore/waf/tree/main/scripts  
**Framework Version:** 4.0  
**Status:** Production Ready
