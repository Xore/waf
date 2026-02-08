# WAF Quick Reference Card

**Purpose:** One-page cheat sheet for common Windows Automation Framework operations  
**Created:** February 8, 2026  
**Audience:** All users - administrators, technicians, operations teams

---

## Critical Fields at a Glance

### Health & Stability
- **opsHealthScore** (0-100) - Overall device health
- **statStabilityScore** (0-100) - System stability
- **statCrashCount30d** - Crashes in last 30 days
- **riskHealthLevel** - Healthy / Degraded / Critical

### Security
- **secSecurityPostureScore** (0-100) - Security health
- **secAntivirusEnabled** - AV protection status
- **secFirewallEnabled** - Firewall status
- **updComplianceStatus** - Patch compliance

### Capacity
- **capDiskFreePercent** - Disk space remaining
- **capMemoryUsedPercent** - Memory utilization
- **capDaysUntilDiskFull** - Days until disk full
- **capCapacityActionNeeded** - Capacity alert flag

### Patching
- **patchRing** - PR1-Test / PR2-Production
- **patchLastAttemptStatus** - Success / Failed / Deferred
- **patchRebootPending** - Reboot required
- **patchValidationStatus** - Passed / Failed / Pending

---

## Field Value Meanings

### Health Scores (0-100)
```
90-100  Excellent - No issues
70-89   Good - Minor issues
50-69   Fair - Attention needed
30-49   Poor - Action required
0-29    Critical - Immediate action
```

### Compliance Status
```
Compliant          Updates current, no gaps
Minor Gap          30-45 days since update
Significant Gap    45-90 days OR 1-2 security updates
Critical Gap       90+ days OR 3+ security updates
```

### Risk Levels
```
Healthy            No critical issues
Degraded           Multiple minor issues
Critical           Immediate attention required
```

---

## Common Operations

### Check Device Health
1. View **opsHealthScore** - should be 70+
2. View **statStabilityScore** - should be 70+
3. Check **statCrashCount30d** - should be 5 or less
4. Review **riskHealthLevel** - should be Healthy

### Check Security Posture
1. View **secSecurityPostureScore** - should be 70+
2. Verify **secAntivirusEnabled** = True
3. Verify **secFirewallEnabled** = True
4. Check **updComplianceStatus** - should be Compliant or Minor Gap

### Check Capacity
1. View **capDiskFreePercent** - should be 20%+
2. View **capMemoryUsedPercent** - should be 85% or less
3. Check **capDaysUntilDiskFull** - should be 90+ days
4. Review **capCapacityActionNeeded** - should be False

### Check Patch Status
1. View **updComplianceStatus** - compliance level
2. Check **patchLastAttemptDate** - last patch deployment
3. View **patchLastAttemptStatus** - deployment result
4. Check **patchRebootPending** - reboot needed

---

## Alert Thresholds

### Critical Alerts (Immediate Action)
```
opsHealthScore < 40
statStabilityScore < 40
capDiskFreePercent < 5%
secAntivirusEnabled = False
secFirewallEnabled = False
updComplianceStatus = Critical Gap
veeamFailedJobsCount > 0
```

### Warning Alerts (Attention Needed)
```
opsHealthScore < 70
statStabilityScore < 70
capDiskFreePercent < 20%
capDaysUntilDiskFull < 30 days
statCrashCount30d > 5
```

### Server-Specific Alerts
```
iisAppPoolsStopped > 0
mssqlLastBackup > 24 hours ago
dhcpScopesDepleted > 0
dnsHealthStatus = Critical
hvHealthStatus = Critical
```

---

## Troubleshooting Guide

### Field Not Updating
**Problem:** Custom field shows old or empty value

**Check:**
1. Is the script scheduled and enabled?
2. Did the script run successfully? (Check execution logs)
3. Is the device online and reachable?
4. Does the script have correct permissions?

**Solution:**
- Run script manually on the device
- Review script execution history in NinjaRMM
- Check for error messages in script output
- Verify field name matches exactly in script

### Script Execution Fails
**Problem:** Script fails or times out

**Check:**
1. Review script error log
2. Check PowerShell execution policy
3. Verify required modules are installed
4. Confirm script runs as SYSTEM account
5. Check timeout settings

**Solution:**
- Test script locally as SYSTEM user
- Add error handling to script
- Break large scripts into smaller components
- Increase timeout from 60s to 120s if needed

### Low Health Score
**Problem:** Device shows low health or stability score

**Diagnosis:**
- Check **statCrashCount30d** - high crash count
- Check **statServiceFailures24h** - service issues
- Check **capDiskFreePercent** - disk space issues
- Check **capMemoryUsedPercent** - memory issues
- Review **driftLocalAdminDrift** - configuration changes

**Remediation:**
1. Run system health diagnostics
2. Check for hardware issues
3. Review recent software changes
4. Clear temporary files and logs
5. Consider hardware upgrade if persistent

---

## Script Reference

### Core Monitoring Scripts
```
Script 1-5   - Health, Stability, Performance, Security, Capacity
Script 6     - Telemetry Collector (crashes, hangs, failures)
Script 9     - Risk Classifier
Script 15    - Security Posture Consolidator
```

### Drift Detection Scripts
```
Script 14    - Local Admin Drift Analyzer
Script 20    - Software Inventory and Shadow-IT Detector
Script 21    - Critical Service Configuration Drift Monitor
Script 35    - Baseline Coverage and Drift Density
```

### User Experience Scripts
```
Script 17    - Application Experience Profiler
Script 19    - Chronic Slow-Boot Detector
Script 29    - Collaboration and Outlook UX Telemetry
Script 30    - User Environment Friction Tracker
```

### Capacity & Predictive Scripts
```
Script 22    - Capacity Trend Forecaster
Script 23    - Patch-Compliance Aging Analyzer
Script 24    - Device Lifetime and Replacement Predictor
```

### Patching Automation Scripts
```
Script PR1   - Patch Ring 1 Test Deployment
Script PR2   - Patch Ring 2 Production Deployment
Script P1    - Critical Device Patch Validator
Script P2    - High Priority Device Patch Validator
Script P3-P4 - Medium/Low Priority Device Patch Validator
```

### Server Monitoring Scripts
```
Script 9-11  - IIS, MSSQL, MySQL Health Monitors
Script 13    - Veeam Backup Monitor
```

---

## Patch Deployment Quick Guide

### Pre-Deployment
1. Run appropriate validator script (P1, P2, or P3-P4)
2. Check **patchValidationStatus** = Passed
3. Review **patchValidationNotes** for any warnings
4. Verify **opsHealthScore** and **statStabilityScore** meet thresholds

### Test Ring Deployment (PR1)
1. Ensure devices have **patchRing** = PR1-Test
2. Run **Script PR1** on Tuesday
3. Monitor devices for 7 days
4. Check **patchLastAttemptStatus** = Success
5. Verify no increase in crashes or stability issues

### Production Deployment (PR2)
1. Verify PR1 success rate 90%+
2. Wait minimum 7 days after PR1
3. Run **Script PR2** on Tuesday
4. Monitor **patchRebootPending** for reboot requirements
5. Track **patchLastPatchCount** for installed patches

---

## Naming Conventions

### Fields
```
Format: [PREFIX][PascalCaseDescriptor]

Examples:
  opsHealthScore          (Operational health)
  statStabilityScore      (Stability statistic)
  secSecurityPostureScore (Security score)
  capDiskFreePercent      (Capacity disk space)
```

### Scripts
```
Format: [Number]_[Category]_[Function].ps1

Examples:
  15_Security_PostureConsolidator.ps1
  22_Capacity_TrendForecaster.ps1
  PR1_Patching_Ring1Deployment.ps1
```

---

## Key Statistics

### Framework Scale
- **277+ custom fields** across 13 categories
- **110 scripts** for monitoring and automation
- **5 patching automation scripts** (PR1, PR2, P1-P4)
- **Update frequencies** from real-time to weekly

### Script Execution
- **Every 4 hours:** Core monitoring (30+ scripts)
- **Daily:** Extended automation and telemetry (40+ scripts)
- **Weekly:** Capacity forecasting and patch deployment (5+ scripts)
- **On-demand:** Validators and remediation scripts

### Field Categories
1. **OPS** - Operational metrics (scores, status)
2. **STAT** - Statistical telemetry (crashes, hangs, usage)
3. **RISK** - Risk classifications (health, security, compliance)
4. **SEC** - Security metrics (posture, threats, controls)
5. **CAP** - Capacity metrics (disk, memory, CPU)
6. **UPD** - Update compliance (patches, versions)
7. **DRIFT** - Configuration drift (admin, software, services)
8. **UX** - User experience (boot times, app hangs)
9. **SRV** - Server roles (IIS, SQL, DNS, DHCP)
10. **NET** - Network metrics (connectivity, latency)
11. **PRED** - Predictive analytics (forecasts, replacements)
12. **AUTO** - Automation controls (safety, risk levels)
13. **PATCH** - Patching automation (rings, validation, status)

---

## Dashboard Widget Suggestions

### Executive View
- Critical devices count (health + stability + security)
- Average health score across all devices
- Patch compliance percentage
- Backup failure count
- Top 5 problem devices

### Operations View
- Devices by health score range
- Devices requiring attention (warnings + critical)
- Script execution success rate
- Configuration drift alerts
- Capacity warnings (30-90 day forecasts)

### Security View
- Security posture score distribution
- Devices with AV/Firewall disabled
- Devices with critical patch gaps
- Failed login attempts and suspicious activity
- Certificate expiration alerts

### Capacity View
- Disk space alerts by severity
- Memory utilization trends
- Devices approaching capacity limits
- Capacity action items
- Storage forecast by device

### Patching View
- Devices by patch ring (PR1 vs PR2)
- Patch validation status
- Pending patch deployments
- Devices with reboot pending
- Patch compliance by priority level

---

## Quick Links

### Documentation
- [Complete Custom Fields Reference](CUSTOM_FIELDS_COMPLETE.md) - All 277+ field definitions
- [Dashboard Templates](DASHBOARD_TEMPLATES.md) - Ready-to-use dashboard configs
- [Alert Configuration](ALERT_CONFIGURATION.md) - Recommended alert conditions
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Step-by-step deployment procedures

### External Resources
- [WAF Coding Standards](../WAF_CODING_STANDARDS.md) - Development guidelines
- [Phase Documentation](../) - Detailed phase summaries

---

## Emergency Contacts

### Critical Issues
- **Security breach detected:** Check **secLastThreatDetection**, review security logs
- **Backup failures:** Check **veeamFailedJobsCount**, run backup validation
- **Disk full:** Check **capDiskFreePercent**, run emergency cleanup script
- **System unstable:** Check **statStabilityScore**, review crash history

### Support Escalation
1. Review relevant custom fields for context
2. Check script execution history
3. Review dashboard for trends
4. Document findings
5. Escalate with field values and context

---

**Remember:** This is a reference card - keep it bookmarked for quick access during daily operations.

**Last Updated:** February 8, 2026  
**Framework Version:** 4.0  
**Status:** Production Ready
