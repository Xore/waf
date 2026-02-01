# NinjaOne Enhanced Compound Conditions - Complete Library
**Version:** 1.0 (Native Integration)  
**Last Updated:** February 1, 2026  
**Total Patterns:** 75+ conditions  
**Enhancement:** Combines NinjaOne native metrics with custom intelligence fields

---

## OVERVIEW

This library provides compound condition patterns that combine **NinjaOne's native monitoring** with **custom intelligence fields** for smarter, context-aware alerting that reduces false positives and improves root cause detection.

### Enhancement Strategy

**Native Metrics (NinjaOne Built-in):**
- Disk Free Space percentage
- CPU Utilization percentage
- Memory Utilization percentage
- SMART Status
- Device Down/Offline
- Pending Reboot
- Backup Status
- Antivirus Status
- Patch Failed
- Windows Service Status
- Windows Event Log (specific Event IDs)

**Custom Intelligence Fields (Framework):**
- OPSHealthScore - Overall device health
- STATStabilityScore - System stability assessment
- RISKExposureLevel - Risk classification
- CAPDaysUntilDiskFull - Predictive disk capacity
- STATCrashCount30d - Crash frequency
- NETLocationCurrent - Network location awareness
- BASEDriftScore - Configuration drift detection

### Why This Matters

**Old Approach (Native Only):**
```
Alert: Disk < 10% free
Problem: Too many false positives, no context
```

**New Approach (Native + Custom):**
```
Alert: Disk < 10% AND CAPDaysUntilDiskFull < 7 AND OPSHealthScore < 60
Result: High-confidence critical alert with context and urgency
```

---

## PRIORITY LEVELS

**P1 - Critical:** Immediate action required, service-impacting  
**P2 - High:** Urgent attention needed, degraded performance  
**P3 - Medium:** Investigation needed, proactive intervention  
**P4 - Low:** Informational, tracking, optimization

---

## P1 CRITICAL CONDITIONS (15 PATTERNS)

### 1. Critical System Failure (Native + Custom)

**Condition Name:** P1_CriticalSystemFailure  
**Priority:** P1 Critical  
**Check Frequency:** Every 5 minutes

**Logic:**
```
(Device Down = True OR CPU Utilization > 95% for 10 minutes)
AND OPSHealthScore < 40
AND STATCrashCount30d > 0
```

**Rationale:** Device offline or CPU maxed out, combined with poor health and recent crashes indicates critical failure.

**Actions:**
- Create P1 ticket: Critical system failure detected
- Alert: Operations team (immediate)
- Run Script: Emergency diagnostic collection
- Escalate: After 10 minutes

**Custom Fields Used:**
- OPSHealthScore
- STATCrashCount30d

---

### 2. Disk Space Critical with Imminent Failure (Native + Custom)

**Condition Name:** P1_DiskCriticalImminent  
**Priority:** P1 Critical  
**Check Frequency:** Every 5 minutes

**Logic:**
```
Disk Free Space < 5% (any drive)
AND CAPDaysUntilDiskFull < 3
AND (STATStabilityScore < 50 OR OPSHealthScore < 50)
```

**Rationale:** Native disk alert combined with predictive capacity shows imminent failure, system already unstable.

**Actions:**
- Create P1 ticket: Disk space critical - failure imminent
- Run Script: Emergency disk cleanup (if AUTOAllowCleanup = True)
- Alert: Operations team (immediate)
- Escalate: After 5 minutes

**Custom Fields Used:**
- CAPDaysUntilDiskFull
- STATStabilityScore
- OPSHealthScore
- AUTOAllowCleanup

---

### 3. Memory Exhaustion with System Instability (Native + Custom)

**Condition Name:** P1_MemoryExhaustionUnstable  
**Priority:** P1 Critical  
**Check Frequency:** Every 5 minutes

**Logic:**
```
Memory Utilization > 95% for 15 minutes
AND STATCrashCount30d > 2
AND OPSHealthScore < 50
```

**Rationale:** Native memory exhaustion combined with crash history indicates high risk of system failure.

**Actions:**
- Create P1 ticket: Memory exhaustion with crash risk
- Run Script: Identify memory-consuming processes
- Alert: Operations team (immediate)
- Run Script: Memory cleanup (if AUTOAllowCleanup = True)

**Custom Fields Used:**
- STATCrashCount30d
- OPSHealthScore
- AUTOAllowCleanup

---

### 4. SMART Failure Detected (Native + Custom)

**Condition Name:** P1_SMARTFailureDetected  
**Priority:** P1 Critical  
**Check Frequency:** Every 10 minutes

**Logic:**
```
SMART Status = Failed
AND OPSHealthScore < 70
AND RISKExposureLevel = "Critical"
```

**Rationale:** Native SMART failure is imminent hardware failure. Risk level determines urgency.

**Actions:**
- Create P1 ticket: Hard drive SMART failure - immediate replacement required
- Alert: Operations team (immediate)
- Run Script: Emergency backup initiation
- Escalate: After 30 minutes
- Flag: Device for hardware replacement

**Custom Fields Used:**
- OPSHealthScore
- RISKExposureLevel

---

### 5. Backup Failed on Business Critical Device (Native + Custom)

**Condition Name:** P1_BackupFailedCritical  
**Priority:** P1 Critical  
**Check Frequency:** Every 30 minutes

**Logic:**
```
Backup Status = Failed (last 24 hours)
AND RISKExposureLevel = "Critical"
AND BASEBusinessCriticality = "Critical"
```

**Rationale:** Backup failure on business-critical system is data loss risk.

**Actions:**
- Create P1 ticket: Backup failed on critical system
- Alert: Backup team (immediate)
- Run Script: Retry backup job
- Escalate: After 2 hours

**Custom Fields Used:**
- RISKExposureLevel
- BASEBusinessCriticality

---

### 6. Antivirus Disabled on Critical System (Native + Custom)

**Condition Name:** P1_AntivirusDisabledCritical  
**Priority:** P1 Critical  
**Check Frequency:** Every 15 minutes

**Logic:**
```
Antivirus Status = Disabled OR Antivirus Status = Not Installed
AND RISKExposureLevel IN ("Critical", "High")
AND NETLocationCurrent = "Office"
```

**Rationale:** No AV protection on high-risk device in corporate network is security incident.

**Actions:**
- Create P1 ticket: Antivirus disabled on critical system
- Alert: Security team (immediate)
- Run Script: Enable Windows Defender
- Isolate: Network isolation if compromised

**Custom Fields Used:**
- RISKExposureLevel
- NETLocationCurrent

---

### 7. Reboot Pending for Extended Period (Native + Custom)

**Condition Name:** P1_RebootPendingExtended  
**Priority:** P1 Critical  
**Check Frequency:** Every 1 hour

**Logic:**
```
Pending Reboot = True
AND UPDDaysSinceLastReboot > 30
AND BASEBusinessCriticality = "Critical"
AND STATCrashCount30d > 0
```

**Rationale:** Extended uptime with pending reboot and crashes indicates patch/stability issues.

**Actions:**
- Create P1 ticket: Reboot required for critical system - extended uptime
- Alert: Operations team
- Schedule: Maintenance window reboot
- Verify: Change approval required

**Custom Fields Used:**
- UPDDaysSinceLastReboot
- BASEBusinessCriticality
- STATCrashCount30d

---

### 8. Critical Service Down (Native + Custom)

**Condition Name:** P1_CriticalServiceDown  
**Priority:** P1 Critical  
**Check Frequency:** Every 5 minutes

**Logic:**
```
Windows Service Status = Stopped (specific critical services)
AND SRVRole CONTAINS ("SQL", "Exchange", "Domain Controller", "File Server")
AND BASEBusinessCriticality = "Critical"
```

**Rationale:** Business-critical service stopped on server with critical role.

**Actions:**
- Create P1 ticket: Critical service down
- Alert: Operations team (immediate)
- Run Script: Restart service (if AUTOAllowServiceRestart = True)
- Escalate: After 5 minutes

**Custom Fields Used:**
- SRVRole
- BASEBusinessCriticality
- AUTOAllowServiceRestart

---

### 9. Multiple System Failures Combined (Native + Custom)

**Condition Name:** P1_MultipleFailuresCombined  
**Priority:** P1 Critical  
**Check Frequency:** Every 5 minutes

**Logic:**
```
(Disk Free Space < 10% OR Memory Utilization > 90%)
AND CPU Utilization > 85% for 10 minutes
AND OPSHealthScore < 30
AND STATStabilityScore < 40
```

**Rationale:** Multiple native resource alerts combined with poor health scoring indicates catastrophic system state.

**Actions:**
- Create P1 ticket: Multiple system failures - catastrophic state
- Alert: Operations team (immediate)
- Run Script: Emergency diagnostic collection
- Run Script: Automated remediation (if AUTORemediationEligible = True)
- Escalate: Immediate

**Custom Fields Used:**
- OPSHealthScore
- STATStabilityScore
- AUTORemediationEligible

---

### 10. Patch Failed on Vulnerable System (Native + Custom)

**Condition Name:** P1_PatchFailedVulnerable  
**Priority:** P1 Critical  
**Check Frequency:** Every 4 hours

**Logic:**
```
Patch Failed = True (critical patches)
AND UPDMissingCriticalCount > 5
AND RISKExposureLevel = "Critical"
AND NETLocationCurrent = "Office"
```

**Rationale:** Failed patches combined with missing critical updates on exposed corporate system.

**Actions:**
- Create P1 ticket: Critical patch failures on vulnerable system
- Alert: Patch management team (immediate)
- Run Script: Manual patch retry
- Isolate: Consider network isolation if highly vulnerable

**Custom Fields Used:**
- UPDMissingCriticalCount
- RISKExposureLevel
- NETLocationCurrent

---

### 11. Disk I/O Failure with Data Risk (Native + Custom)

**Condition Name:** P1_DiskIOFailureDataRisk  
**Priority:** P1 Critical  
**Check Frequency:** Every 10 minutes

**Logic:**
```
Windows Event Log CONTAINS (Event ID: 7, 11, 51) (last 24 hours)
AND SMART Status = Warning OR SMART Status = Failed
AND BASEBusinessCriticality = "Critical"
AND Backup Status = Failed
```

**Rationale:** Disk I/O errors with SMART warning and backup failure is imminent data loss.

**Actions:**
- Create P1 ticket: Disk I/O failure with data loss risk
- Alert: Operations team (immediate)
- Run Script: Emergency backup initiation
- Flag: Hardware replacement urgent
- Escalate: Immediate

**Custom Fields Used:**
- BASEBusinessCriticality

---

### 12. Server Down During Business Hours (Native + Custom)

**Condition Name:** P1_ServerDownBusinessHours  
**Priority:** P1 Critical  
**Check Frequency:** Every 3 minutes

**Logic:**
```
Device Down = True
AND SRVRole IS NOT NULL
AND BASEBusinessCriticality IN ("Critical", "High")
AND Current Time BETWEEN 08:00 AND 18:00 (business hours)
```

**Rationale:** Server offline during business hours with critical services.

**Actions:**
- Create P1 ticket: Critical server down during business hours
- Alert: Operations team (immediate)
- Alert: Business stakeholders
- Escalate: After 5 minutes
- Page: On-call engineer

**Custom Fields Used:**
- SRVRole
- BASEBusinessCriticality

---

### 13. CPU Thermal Event with Instability (Native + Custom)

**Condition Name:** P1_CPUThermalEventUnstable  
**Priority:** P1 Critical  
**Check Frequency:** Every 10 minutes

**Logic:**
```
Windows Event Log CONTAINS (Event ID: 41) (Kernel-Power critical)
AND CPU Utilization > 90% for 20 minutes
AND STATCrashCount30d > 1
AND OPSHealthScore < 50
```

**Rationale:** Thermal events with high CPU and crashes indicates hardware failure or cooling issue.

**Actions:**
- Create P1 ticket: CPU thermal event with system instability
- Alert: Operations team (immediate)
- Run Script: Temperature diagnostic
- Flag: Hardware inspection required

**Custom Fields Used:**
- STATCrashCount30d
- OPSHealthScore

---

### 14. Configuration Drift on Production Server (Native + Custom)

**Condition Name:** P1_ConfigDriftProductionServer  
**Priority:** P1 Critical  
**Check Frequency:** Every 1 hour

**Logic:**
```
BASEDriftScore > 80
AND SRVRole IS NOT NULL
AND BASEBusinessCriticality = "Critical"
AND Windows Event Log CONTAINS (Event ID: 1102) (Security log cleared)
```

**Rationale:** High configuration drift with security log tampering on critical server indicates compromise or unauthorized changes.

**Actions:**
- Create P1 ticket: Unauthorized configuration changes on production server
- Alert: Security team (immediate)
- Run Script: Configuration snapshot and comparison
- Isolate: Consider network isolation
- Escalate: Security incident response

**Custom Fields Used:**
- BASEDriftScore
- SRVRole
- BASEBusinessCriticality

---

### 15. Network-Based Attack Indicators (Native + Custom)

**Condition Name:** P1_NetworkAttackIndicators  
**Priority:** P1 Critical  
**Check Frequency:** Every 10 minutes

**Logic:**
```
Antivirus Status = Threat Detected
AND Windows Event Log CONTAINS (Event ID: 5152, 5157) (Firewall blocked connections)
AND NETLocationCurrent = "Office"
AND RISKExposureLevel = "Critical"
```

**Rationale:** Active threat detection with firewall blocks indicates active network attack.

**Actions:**
- Create P1 ticket: Network-based attack detected
- Alert: Security team (immediate)
- Isolate: Network isolation
- Run Script: Security forensics collection
- Escalate: Security incident response (immediate)

**Custom Fields Used:**
- NETLocationCurrent
- RISKExposureLevel

---

## P2 HIGH PRIORITY CONDITIONS (20 PATTERNS)

### 16. High Disk Usage with Growth Trend (Native + Custom)

**Condition Name:** P2_HighDiskUsageGrowth  
**Priority:** P2 High  
**Check Frequency:** Every 15 minutes

**Logic:**
```
Disk Free Space < 15%
AND CAPDaysUntilDiskFull < 14
AND CAPDiskGrowthRateMBPerDay > 500
```

**Rationale:** Native disk alert with predictive capacity shows proactive intervention needed.

**Actions:**
- Create P2 ticket: High disk usage with rapid growth
- Run Script: Disk usage analysis
- Alert: Operations team
- Schedule: Cleanup or expansion within 7 days

**Custom Fields Used:**
- CAPDaysUntilDiskFull
- CAPDiskGrowthRateMBPerDay

---

### 17. Memory Pressure with Performance Degradation (Native + Custom)

**Condition Name:** P2_MemoryPressurePerformance  
**Priority:** P2 High  
**Check Frequency:** Every 15 minutes

**Logic:**
```
Memory Utilization > 85% for 20 minutes
AND OPSPerformanceScore < 60
AND STATAvgBootTimeSec > 180
```

**Rationale:** Native memory alert combined with poor performance metrics.

**Actions:**
- Create P2 ticket: Memory pressure causing performance degradation
- Run Script: Identify memory consumers
- Alert: Operations team
- Recommend: Memory upgrade analysis

**Custom Fields Used:**
- OPSPerformanceScore
- STATAvgBootTimeSec

---

### 18. CPU High with Stability Issues (Native + Custom)

**Condition Name:** P2_CPUHighStabilityIssues  
**Priority:** P2 High  
**Check Frequency:** Every 15 minutes

**Logic:**
```
CPU Utilization > 80% for 30 minutes
AND STATStabilityScore < 70
AND STATCrashCount30d > 0
```

**Rationale:** High CPU with recent crashes indicates resource contention or application issues.

**Actions:**
- Create P2 ticket: High CPU with stability concerns
- Run Script: Process analysis and performance capture
- Alert: Operations team
- Investigate: Resource-intensive applications

**Custom Fields Used:**
- STATStabilityScore
- STATCrashCount30d

---

### 19. Pending Reboot with Updates (Native + Custom)

**Condition Name:** P2_PendingRebootUpdates  
**Priority:** P2 High  
**Check Frequency:** Every 4 hours

**Logic:**
```
Pending Reboot = True
AND UPDDaysSinceLastReboot > 14
AND UPDMissingImportantCount > 0
```

**Rationale:** Extended uptime with pending updates requires reboot for security and stability.

**Actions:**
- Create P2 ticket: Reboot required for pending updates
- Alert: Operations team
- Schedule: Maintenance window reboot (if AUTOAllowAfterHoursReboot = True)
- Notify: End user (if workstation)

**Custom Fields Used:**
- UPDDaysSinceLastReboot
- UPDMissingImportantCount
- AUTOAllowAfterHoursReboot

---

### 20. Backup Failed on Standard System (Native + Custom)

**Condition Name:** P2_BackupFailedStandard  
**Priority:** P2 High  
**Check Frequency:** Every 1 hour

**Logic:**
```
Backup Status = Failed (last 48 hours)
AND BASEBusinessCriticality IN ("High", "Standard")
AND RISKExposureLevel != "Low"
```

**Rationale:** Backup failure on standard systems still poses data loss risk.

**Actions:**
- Create P2 ticket: Backup failed on standard system
- Alert: Backup team
- Run Script: Retry backup job
- Escalate: After 24 hours

**Custom Fields Used:**
- BASEBusinessCriticality
- RISKExposureLevel

---

### 21. Antivirus Outdated (Native + Custom)

**Condition Name:** P2_AntivirusOutdated  
**Priority:** P2 High  
**Check Frequency:** Every 4 hours

**Logic:**
```
Antivirus Status = Outdated (definitions > 7 days old)
AND NETLocationCurrent = "Office"
AND RISKExposureLevel IN ("High", "Critical")
```

**Rationale:** Outdated antivirus on corporate network is security risk.

**Actions:**
- Create P2 ticket: Antivirus definitions outdated
- Alert: Security team
- Run Script: Force definition update
- Escalate: After 24 hours

**Custom Fields Used:**
- NETLocationCurrent
- RISKExposureLevel

---

### 22. Multiple Patches Failed (Native + Custom)

**Condition Name:** P2_MultiplePatchesFailed  
**Priority:** P2 High  
**Check Frequency:** Every 4 hours

**Logic:**
```
Patch Failed = True (3+ patches in last 30 days)
AND UPDMissingImportantCount > 3
AND RISKExposureLevel IN ("High", "Critical")
```

**Rationale:** Pattern of patch failures indicates patching issues requiring intervention.

**Actions:**
- Create P2 ticket: Multiple patch installation failures
- Alert: Patch management team
- Run Script: Patch diagnostic and repair
- Escalate: After 48 hours

**Custom Fields Used:**
- UPDMissingImportantCount
- RISKExposureLevel

---

### 23. Service Restart Loop (Native + Custom)

**Condition Name:** P2_ServiceRestartLoop  
**Priority:** P2 High  
**Check Frequency:** Every 15 minutes

**Logic:**
```
Windows Event Log CONTAINS (Event ID: 7031, 7034) (Service crashed) (5+ times in 1 hour)
AND SRVRole IS NOT NULL
AND OPSHealthScore < 70
```

**Rationale:** Service repeatedly crashing indicates application or configuration issue.

**Actions:**
- Create P2 ticket: Service restart loop detected
- Alert: Operations team
- Run Script: Service diagnostic collection
- Investigate: Application logs and dependencies

**Custom Fields Used:**
- SRVRole
- OPSHealthScore

---

### 24. SMART Warning with No Backup (Native + Custom)

**Condition Name:** P2_SMARTWarningNoBackup  
**Priority:** P2 High  
**Check Frequency:** Every 1 hour

**Logic:**
```
SMART Status = Warning
AND Backup Status != Success (last 7 days)
AND BASEBusinessCriticality IN ("High", "Critical")
```

**Rationale:** Disk showing early failure signs without recent backup.

**Actions:**
- Create P2 ticket: SMART warning detected without recent backup
- Alert: Operations team
- Run Script: Immediate backup initiation
- Schedule: Hardware replacement

**Custom Fields Used:**
- BASEBusinessCriticality

---

### 25. Network Location Changed to Untrusted (Native + Custom)

**Condition Name:** P2_NetworkLocationUntrusted  
**Priority:** P2 High  
**Check Frequency:** Every 30 minutes

**Logic:**
```
NETLocationCurrent = "Unknown" OR NETLocationCurrent = "Remote"
AND NETLocationPrevious = "Office"
AND BASEBusinessCriticality IN ("High", "Critical")
AND RISKExposureLevel = "Critical"
```

**Rationale:** Critical device moved from trusted to untrusted network.

**Actions:**
- Create P2 ticket: Critical device on untrusted network
- Alert: Security team
- Verify: Device location and user
- Apply: Enhanced security policy

**Custom Fields Used:**
- NETLocationCurrent
- NETLocationPrevious
- BASEBusinessCriticality
- RISKExposureLevel

---

### 26. High Configuration Drift (Native + Custom)

**Condition Name:** P2_HighConfigurationDrift  
**Priority:** P2 High  
**Check Frequency:** Every 4 hours

**Logic:**
```
BASEDriftScore > 60
AND BASEBusinessCriticality IN ("High", "Critical")
AND BASEDriftDetectionEnabled = True
```

**Rationale:** Significant configuration changes on business-critical system require validation.

**Actions:**
- Create P2 ticket: High configuration drift detected
- Alert: Operations team
- Run Script: Configuration comparison report
- Verify: Change management approval

**Custom Fields Used:**
- BASEDriftScore
- BASEBusinessCriticality
- BASEDriftDetectionEnabled

---

### 27. Excessive Crash History (Native + Custom)

**Condition Name:** P2_ExcessiveCrashHistory  
**Priority:** P2 High  
**Check Frequency:** Daily

**Logic:**
```
STATCrashCount30d > 5
AND OPSHealthScore < 70
AND STATStabilityScore < 60
```

**Rationale:** Pattern of crashes indicates underlying stability issue.

**Actions:**
- Create P2 ticket: Excessive system crashes detected
- Alert: Operations team
- Run Script: Crash dump analysis
- Investigate: Hardware or driver issues

**Custom Fields Used:**
- STATCrashCount30d
- OPSHealthScore
- STATStabilityScore

---

### 28. Slow Boot Time with Stability Issues (Native + Custom)

**Condition Name:** P2_SlowBootStability  
**Priority:** P2 High  
**Check Frequency:** Daily

**Logic:**
```
STATAvgBootTimeSec > 300
AND STATStabilityScore < 70
AND OPSHealthScore < 70
```

**Rationale:** Slow boot combined with poor stability indicates system health issues.

**Actions:**
- Create P2 ticket: Slow boot time with stability concerns
- Run Script: Boot performance analysis
- Investigate: Startup programs and services
- Consider: System optimization

**Custom Fields Used:**
- STATAvgBootTimeSec
- STATStabilityScore
- OPSHealthScore

---

### 29. VPN Connection Failures (Native + Custom)

**Condition Name:** P2_VPNConnectionFailures  
**Priority:** P2 High  
**Check Frequency:** Every 1 hour

**Logic:**
```
NETVPNConnected = False
AND NETLocationCurrent = "Remote"
AND BASEBusinessCriticality IN ("High", "Critical")
AND Windows Event Log CONTAINS (Event ID: 20227) (VPN connection failed)
```

**Rationale:** VPN failures on remote critical devices indicate connectivity or security issues.

**Actions:**
- Create P2 ticket: VPN connection failures on remote device
- Alert: Network team
- Run Script: VPN diagnostic
- Support: End user VPN troubleshooting

**Custom Fields Used:**
- NETVPNConnected
- NETLocationCurrent
- BASEBusinessCriticality

---

### 30. Domain Controller Synchronization Issues (Native + Custom)

**Condition Name:** P2_DCSyncIssues  
**Priority:** P2 High  
**Check Frequency:** Every 30 minutes

**Logic:**
```
Windows Event Log CONTAINS (Event ID: 2042) (AD replication failure)
AND SRVRole CONTAINS "Domain Controller"
AND ADLastSyncStatus = "Failed"
```

**Rationale:** AD replication failures on domain controller are critical infrastructure issues.

**Actions:**
- Create P2 ticket: Domain Controller synchronization failure
- Alert: Infrastructure team (urgent)
- Run Script: AD replication diagnostic
- Escalate: After 1 hour

**Custom Fields Used:**
- SRVRole
- ADLastSyncStatus

---

### 31. File Server Capacity Warning (Native + Custom)

**Condition Name:** P2_FileServerCapacityWarning  
**Priority:** P2 High  
**Check Frequency:** Every 1 hour

**Logic:**
```
Disk Free Space < 20%
AND SRVRole CONTAINS "File Server"
AND CAPDaysUntilDiskFull < 30
AND BASEBusinessCriticality IN ("High", "Critical")
```

**Rationale:** File servers running low on space with predictive capacity warning.

**Actions:**
- Create P2 ticket: File server capacity warning
- Alert: Storage team
- Run Script: File server quota analysis
- Plan: Storage expansion

**Custom Fields Used:**
- SRVRole
- CAPDaysUntilDiskFull
- BASEBusinessCriticality

---

### 32. SQL Server High Memory (Native + Custom)

**Condition Name:** P2_SQLServerHighMemory  
**Priority:** P2 High  
**Check Frequency:** Every 30 minutes

**Logic:**
```
Memory Utilization > 90% for 30 minutes
AND SRVRole CONTAINS "SQL Server"
AND OPSPerformanceScore < 60
```

**Rationale:** SQL Server memory pressure affecting performance.

**Actions:**
- Create P2 ticket: SQL Server memory pressure
- Alert: Database team
- Run Script: SQL Server memory diagnostic
- Investigate: Query performance and indexing

**Custom Fields Used:**
- SRVRole
- OPSPerformanceScore

---

### 33. Exchange Server Queue Backup (Native + Custom)

**Condition Name:** P2_ExchangeQueueBackup  
**Priority:** P2 High  
**Check Frequency:** Every 15 minutes

**Logic:**
```
Windows Event Log CONTAINS (Event ID: 1025) (Exchange queue growing)
AND SRVRole CONTAINS "Exchange"
AND OPSHealthScore < 70
```

**Rationale:** Exchange mail queue backing up indicates mail flow issues.

**Actions:**
- Create P2 ticket: Exchange mail queue backup
- Alert: Messaging team (urgent)
- Run Script: Exchange queue diagnostic
- Investigate: SMTP connectors and DNS

**Custom Fields Used:**
- SRVRole
- OPSHealthScore

---

### 34. Hyper-V Host Resource Contention (Native + Custom)

**Condition Name:** P2_HyperVResourceContention  
**Priority:** P2 High  
**Check Frequency:** Every 30 minutes

**Logic:**
```
(CPU Utilization > 85% OR Memory Utilization > 90%) for 20 minutes
AND SRVRole CONTAINS "Hyper-V"
AND OPSPerformanceScore < 60
```

**Rationale:** Hyper-V host resource pressure affects all guest VMs.

**Actions:**
- Create P2 ticket: Hyper-V host resource contention
- Alert: Virtualization team
- Run Script: VM resource analysis
- Consider: VM migration or host upgrade

**Custom Fields Used:**
- SRVRole
- OPSPerformanceScore

---

### 35. Print Server Queue Stalled (Native + Custom)

**Condition Name:** P2_PrintServerQueueStalled  
**Priority:** P2 High  
**Check Frequency:** Every 30 minutes

**Logic:**
```
Windows Event Log CONTAINS (Event ID: 372) (Print queue stalled)
AND SRVRole CONTAINS "Print Server"
AND Windows Service Status = Stopped (Print Spooler)
```

**Rationale:** Print spooler issues affecting business operations.

**Actions:**
- Create P2 ticket: Print server queue stalled
- Alert: Infrastructure team
- Run Script: Restart print spooler (if AUTOAllowServiceRestart = True)
- Clear: Print queue if needed

**Custom Fields Used:**
- SRVRole
- AUTOAllowServiceRestart

---

## P3 MEDIUM PRIORITY CONDITIONS (25 PATTERNS)

### 36. Moderate Disk Usage (Native + Custom)

**Condition Name:** P3_ModerateDiskUsage  
**Priority:** P3 Medium  
**Check Frequency:** Every 1 hour

**Logic:**
```
Disk Free Space < 25%
AND CAPDaysUntilDiskFull < 60
AND CAPDaysUntilDiskFull > 14
```

**Rationale:** Proactive disk space monitoring with adequate lead time.

**Actions:**
- Create P3 ticket: Moderate disk usage - cleanup recommended
- Run Script: Disk usage report
- Notify: End user (if workstation)
- Schedule: Cleanup within 30 days

**Custom Fields Used:**
- CAPDaysUntilDiskFull

---

### 37. Elevated CPU Usage Pattern (Native + Custom)

**Condition Name:** P3_ElevatedCPUPattern  
**Priority:** P3 Medium  
**Check Frequency:** Every 1 hour

**Logic:**
```
CPU Utilization > 70% for 1 hour
AND OPSPerformanceScore < 75
AND OPSPerformanceScore > 50
```

**Rationale:** Moderate CPU usage affecting performance but not critical.

**Actions:**
- Create P3 ticket: Elevated CPU usage pattern
- Run Script: Process analysis
- Investigate: Background tasks or applications

**Custom Fields Used:**
- OPSPerformanceScore

---

### 38. Memory Usage Above Normal (Native + Custom)

**Condition Name:** P3_MemoryAboveNormal  
**Priority:** P3 Medium  
**Check Frequency:** Every 1 hour

**Logic:**
```
Memory Utilization > 80% for 1 hour
AND OPSPerformanceScore < 75
AND STATStabilityScore > 70
```

**Rationale:** Elevated memory but system stable, may need optimization.

**Actions:**
- Create P3 ticket: Memory usage above normal
- Run Script: Memory usage analysis
- Recommend: Memory optimization or upgrade

**Custom Fields Used:**
- OPSPerformanceScore
- STATStabilityScore

---

### 39. Pending Reboot Standard System (Native + Custom)

**Condition Name:** P3_PendingRebootStandard  
**Priority:** P3 Medium  
**Check Frequency:** Every 8 hours

**Logic:**
```
Pending Reboot = True
AND UPDDaysSinceLastReboot > 7
AND UPDDaysSinceLastReboot < 14
AND BASEBusinessCriticality = "Standard"
```

**Rationale:** Standard system needs reboot but not urgent.

**Actions:**
- Create P3 ticket: Reboot recommended
- Notify: End user
- Schedule: Convenient reboot time
- Remind: Weekly until resolved

**Custom Fields Used:**
- UPDDaysSinceLastReboot
- BASEBusinessCriticality

---

### 40. Configuration Drift Low Impact (Native + Custom)

**Condition Name:** P3_ConfigDriftLowImpact  
**Priority:** P3 Medium  
**Check Frequency:** Daily

**Logic:**
```
BASEDriftScore > 40
AND BASEDriftScore < 60
AND BASEBusinessCriticality = "Standard"
```

**Rationale:** Moderate configuration changes on standard systems for tracking.

**Actions:**
- Create P3 ticket: Configuration changes detected
- Run Script: Configuration comparison report
- Document: Changes in change log

**Custom Fields Used:**
- BASEDriftScore
- BASEBusinessCriticality

---

### 41. Occasional Crashes (Native + Custom)

**Condition Name:** P3_OccasionalCrashes  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
STATCrashCount30d BETWEEN 1 AND 3
AND OPSHealthScore > 70
AND STATStabilityScore > 70
```

**Rationale:** Infrequent crashes on otherwise healthy system, track for patterns.

**Actions:**
- Create P3 ticket: Occasional system crashes detected
- Run Script: Crash dump analysis
- Monitor: For increasing frequency

**Custom Fields Used:**
- STATCrashCount30d
- OPSHealthScore
- STATStabilityScore

---

### 42. Slow Boot Time Optimization (Native + Custom)

**Condition Name:** P3_SlowBootOptimization  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
STATAvgBootTimeSec > 180
AND STATAvgBootTimeSec < 300
AND OPSHealthScore > 70
```

**Rationale:** Boot time could be improved but system otherwise healthy.

**Actions:**
- Create P3 ticket: Boot time optimization recommended
- Run Script: Boot performance analysis
- Recommend: Startup program review

**Custom Fields Used:**
- STATAvgBootTimeSec
- OPSHealthScore

---

### 43. VPN Intermittent Connectivity (Native + Custom)

**Condition Name:** P3_VPNIntermittent  
**Priority:** P3 Medium  
**Check Frequency:** Daily

**Logic:**
```
NETVPNConnected = False
AND NETLocationCurrent = "Remote"
AND BASEBusinessCriticality = "Standard"
```

**Rationale:** VPN issues on standard remote devices, proactive support.

**Actions:**
- Create P3 ticket: VPN intermittent connectivity
- Support: End user troubleshooting guide
- Monitor: Connection stability

**Custom Fields Used:**
- NETVPNConnected
- NETLocationCurrent
- BASEBusinessCriticality

---

### 44. Backup Warning (Native + Custom)

**Condition Name:** P3_BackupWarning  
**Priority:** P3 Medium  
**Check Frequency:** Daily

**Logic:**
```
Backup Status = Warning (slow backup or partial)
AND BASEBusinessCriticality = "Standard"
```

**Rationale:** Backup completed but with warnings, needs investigation.

**Actions:**
- Create P3 ticket: Backup completed with warnings
- Investigate: Backup logs
- Optimize: Backup schedule or exclusions

**Custom Fields Used:**
- BASEBusinessCriticality

---

### 45. Antivirus on Remote Network (Native + Custom)

**Condition Name:** P3_AntivirusRemote  
**Priority:** P3 Medium  
**Check Frequency:** Daily

**Logic:**
```
Antivirus Status = Outdated (definitions > 3 days old)
AND NETLocationCurrent = "Remote"
AND RISKExposureLevel = "Standard"
```

**Rationale:** Remote device with slightly outdated AV, lower risk.

**Actions:**
- Create P3 ticket: Antivirus definitions outdated on remote device
- Support: End user update instructions
- Schedule: Forced update on next connection

**Custom Fields Used:**
- NETLocationCurrent
- RISKExposureLevel

---

### 46. Missing Optional Updates (Native + Custom)

**Condition Name:** P3_MissingOptionalUpdates  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
UPDMissingOptionalCount > 5
AND UPDMissingCriticalCount = 0
AND UPDMissingImportantCount = 0
```

**Rationale:** Optional updates missing but security patches current.

**Actions:**
- Create P3 ticket: Optional updates available
- Schedule: Maintenance window installation
- Notify: End user of pending updates

**Custom Fields Used:**
- UPDMissingOptionalCount
- UPDMissingCriticalCount
- UPDMissingImportantCount

---

### 47. SMART Status Normal but Old Drive (Native + Custom)

**Condition Name:** P3_SMARTNormalOldDrive  
**Priority:** P3 Medium  
**Check Frequency:** Monthly

**Logic:**
```
SMART Status = Healthy
AND Device Age > 5 years (custom calculation)
AND BASEBusinessCriticality IN ("High", "Critical")
```

**Rationale:** Drive healthy but age warrants proactive replacement planning.

**Actions:**
- Create P3 ticket: Drive aging - proactive replacement recommended
- Plan: Hardware refresh schedule
- Verify: Backup strategy current

**Custom Fields Used:**
- BASEBusinessCriticality

---

### 48. Network Location Changed (Native + Custom)

**Condition Name:** P3_NetworkLocationChanged  
**Priority:** P3 Medium  
**Check Frequency:** Daily

**Logic:**
```
NETLocationCurrent != NETLocationPrevious
AND BASEBusinessCriticality = "Standard"
```

**Rationale:** Network location changed, track for security and policy application.

**Actions:**
- Create P3 ticket: Network location changed
- Verify: Policy applied correctly
- Document: Location change

**Custom Fields Used:**
- NETLocationCurrent
- NETLocationPrevious
- BASEBusinessCriticality

---

### 49. Server Role Detection (Native + Custom)

**Condition Name:** P3_ServerRoleDetection  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
SRVRole IS NOT NULL
AND Windows Server OS
AND BASEBusinessCriticality = NULL (not yet classified)
```

**Rationale:** Server detected but not classified, needs business criticality assignment.

**Actions:**
- Create P3 ticket: Server role detected - classification needed
- Request: Business criticality assignment
- Update: Device documentation

**Custom Fields Used:**
- SRVRole
- BASEBusinessCriticality

---

### 50. Low Risk Exposure (Native + Custom)

**Condition Name:** P3_LowRiskExposure  
**Priority:** P3 Medium  
**Check Frequency:** Monthly

**Logic:**
```
RISKExposureLevel = "Low"
AND OPSHealthScore > 80
AND NETLocationCurrent = "Office"
```

**Rationale:** Device performing well, informational tracking.

**Actions:**
- No ticket creation
- Dashboard: Display in healthy devices report
- Report: Monthly health summary

**Custom Fields Used:**
- RISKExposureLevel
- OPSHealthScore
- NETLocationCurrent

---

### 51. Performance Baseline Established (Native + Custom)

**Condition Name:** P3_PerformanceBaselineEstablished  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
BASEPerformanceBaseline IS NOT NULL
AND OPSPerformanceScore BETWEEN 75 AND 90
```

**Rationale:** Device has established baseline and performing normally.

**Actions:**
- No ticket creation
- Monitor: For deviations from baseline
- Report: Weekly performance summary

**Custom Fields Used:**
- BASEPerformanceBaseline
- OPSPerformanceScore

---

### 52. Disk Growth Rate Normal (Native + Custom)

**Condition Name:** P3_DiskGrowthNormal  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
CAPDiskGrowthRateMBPerDay < 200
AND Disk Free Space > 25%
AND CAPDaysUntilDiskFull > 90
```

**Rationale:** Disk usage within normal parameters, proactive tracking.

**Actions:**
- No ticket creation
- Report: Weekly capacity planning report
- Monitor: For trend changes

**Custom Fields Used:**
- CAPDiskGrowthRateMBPerDay
- CAPDaysUntilDiskFull

---

### 53. Battery Health Degradation (Native + Custom)

**Condition Name:** P3_BatteryHealthDegradation  
**Priority:** P3 Medium  
**Check Frequency:** Monthly

**Logic:**
```
BATHealthPercent < 80
AND BATHealthPercent > 60
AND Device Type = Laptop
```

**Rationale:** Battery capacity degrading but still functional.

**Actions:**
- Create P3 ticket: Battery health degradation detected
- Notify: End user of battery status
- Plan: Battery replacement if under 60%

**Custom Fields Used:**
- BATHealthPercent

---

### 54. User Profile Size Large (Native + Custom)

**Condition Name:** P3_UserProfileSizeLarge  
**Priority:** P3 Medium  
**Check Frequency:** Monthly

**Logic:**
```
UXUserProfileSizeGB > 10
AND Disk Free Space > 20%
```

**Rationale:** Large user profile may affect performance and roaming.

**Actions:**
- Create P3 ticket: Large user profile detected
- Support: End user cleanup guidance
- Investigate: Profile redirection or cleanup

**Custom Fields Used:**
- UXUserProfileSizeGB

---

### 55. GPO Application Slow (Native + Custom)

**Condition Name:** P3_GPOApplicationSlow  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
GPOLastApplyTimeSec > 60
AND NETLocationCurrent = "Office"
AND STATAvgBootTimeSec > 180
```

**Rationale:** Slow GPO application affecting boot time.

**Actions:**
- Create P3 ticket: Slow GPO application detected
- Investigate: GPO processing and network latency
- Optimize: GPO structure or filtering

**Custom Fields Used:**
- GPOLastApplyTimeSec
- NETLocationCurrent
- STATAvgBootTimeSec

---

### 56. AD Computer Object Stale (Native + Custom)

**Condition Name:** P3_ADComputerStale  
**Priority:** P3 Medium  
**Check Frequency:** Monthly

**Logic:**
```
ADLastLogonDays > 90
AND Device Down = True (for 30+ days)
```

**Rationale:** Computer object not used in extended period, cleanup candidate.

**Actions:**
- Create P3 ticket: Stale computer object detected
- Verify: Device decommissioned or retired
- Plan: AD cleanup if confirmed unused

**Custom Fields Used:**
- ADLastLogonDays

---

### 57. Security Baseline Drift (Native + Custom)

**Condition Name:** P3_SecurityBaselineDrift  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
SECSecurityPosture < 80
AND SECSecurityPosture > 60
AND RISKExposureLevel = "Standard"
```

**Rationale:** Moderate security posture drift needing correction.

**Actions:**
- Create P3 ticket: Security baseline drift detected
- Run Script: Security baseline comparison
- Remediate: Security settings if approved

**Custom Fields Used:**
- SECSecurityPosture
- RISKExposureLevel

---

### 58. Update Compliance Good (Native + Custom)

**Condition Name:** P3_UpdateComplianceGood  
**Priority:** P3 Medium  
**Check Frequency:** Weekly

**Logic:**
```
UPDMissingCriticalCount = 0
AND UPDMissingImportantCount = 0
AND UPDDaysSinceLastReboot < 7
```

**Rationale:** Device fully patched and rebooted, positive confirmation.

**Actions:**
- No ticket creation
- Dashboard: Display in compliant devices
- Report: Weekly compliance summary

**Custom Fields Used:**
- UPDMissingCriticalCount
- UPDMissingImportantCount
- UPDDaysSinceLastReboot

---

### 59. Automation Eligibility Review (Native + Custom)

**Condition Name:** P3_AutomationEligibilityReview  
**Priority:** P3 Medium  
**Check Frequency:** Monthly

**Logic:**
```
AUTORemediationEligible = False
AND OPSHealthScore > 80
AND STATStabilityScore > 80
AND Device Age > 1 year
```

**Rationale:** Stable device candidate for automation enablement.

**Actions:**
- Create P3 ticket: Device candidate for automation eligibility
- Review: Automation safety criteria
- Enable: Automation flags if approved

**Custom Fields Used:**
- AUTORemediationEligible
- OPSHealthScore
- STATStabilityScore

---

### 60. Capacity Planning Forecast (Native + Custom)

**Condition Name:** P3_CapacityPlanningForecast  
**Priority:** P3 Medium  
**Check Frequency:** Monthly

**Logic:**
```
CAPDaysUntilDiskFull BETWEEN 60 AND 180
AND CAPDiskGrowthRateMBPerDay > 100
```

**Rationale:** Long-term capacity planning based on growth trends.

**Actions:**
- No ticket creation
- Report: Quarterly capacity planning report
- Plan: Storage expansion timeline

**Custom Fields Used:**
- CAPDaysUntilDiskFull
- CAPDiskGrowthRateMBPerDay

---

## P4 LOW PRIORITY CONDITIONS (15 PATTERNS)

### 61. Device Health Excellent (Native + Custom)

**Condition Name:** P4_DeviceHealthExcellent  
**Priority:** P4 Low  
**Check Frequency:** Weekly

**Logic:**
```
OPSHealthScore > 90
AND STATStabilityScore > 90
AND OPSPerformanceScore > 90
```

**Rationale:** Device performing optimally, positive tracking.

**Actions:**
- No ticket creation
- Dashboard: Display in top performers
- Report: Monthly excellence report

**Custom Fields Used:**
- OPSHealthScore
- STATStabilityScore
- OPSPerformanceScore

---

### 62. Low Disk Usage (Native + Custom)

**Condition Name:** P4_LowDiskUsage  
**Priority:** P4 Low  
**Check Frequency:** Monthly

**Logic:**
```
Disk Free Space > 50%
AND CAPDaysUntilDiskFull > 365
```

**Rationale:** Excellent disk capacity, informational.

**Actions:**
- No ticket creation
- Report: Monthly capacity summary

**Custom Fields Used:**
- CAPDaysUntilDiskFull

---

### 63. CPU Utilization Normal (Native + Custom)

**Condition Name:** P4_CPUNormal  
**Priority:** P4 Low  
**Check Frequency:** Daily

**Logic:**
```
CPU Utilization < 50% (average)
AND OPSPerformanceScore > 80
```

**Rationale:** Normal CPU usage, positive tracking.

**Actions:**
- No ticket creation
- Monitor: For changes

**Custom Fields Used:**
- OPSPerformanceScore

---

### 64. Memory Utilization Optimal (Native + Custom)

**Condition Name:** P4_MemoryOptimal  
**Priority:** P4 Low  
**Check Frequency:** Daily

**Logic:**
```
Memory Utilization < 70% (average)
AND OPSPerformanceScore > 80
```

**Rationale:** Optimal memory usage, positive tracking.

**Actions:**
- No ticket creation
- Monitor: For changes

**Custom Fields Used:**
- OPSPerformanceScore

---

### 65. No Crashes Recorded (Native + Custom)

**Condition Name:** P4_NoCrashes  
**Priority:** P4 Low  
**Check Frequency:** Monthly

**Logic:**
```
STATCrashCount30d = 0
AND STATStabilityScore > 85
```

**Rationale:** Excellent stability, positive tracking.

**Actions:**
- No ticket creation
- Dashboard: Display in stable devices
- Report: Monthly stability report

**Custom Fields Used:**
- STATCrashCount30d
- STATStabilityScore

---

### 66. Fast Boot Time (Native + Custom)

**Condition Name:** P4_FastBootTime  
**Priority:** P4 Low  
**Check Frequency:** Monthly

**Logic:**
```
STATAvgBootTimeSec < 90
AND OPSPerformanceScore > 85
```

**Rationale:** Excellent boot performance, positive tracking.

**Actions:**
- No ticket creation
- Dashboard: Display in fast boot devices
- Report: Monthly performance report

**Custom Fields Used:**
- STATAvgBootTimeSec
- OPSPerformanceScore

---

### 67. VPN Always Connected (Native + Custom)

**Condition Name:** P4_VPNAlwaysConnected  
**Priority:** P4 Low  
**Check Frequency:** Weekly

**Logic:**
```
NETVPNConnected = True
AND NETLocationCurrent = "Remote"
AND Device Type = Laptop
```

**Rationale:** Remote user maintaining VPN connectivity, positive behavior.

**Actions:**
- No ticket creation
- Report: Weekly VPN compliance report

**Custom Fields Used:**
- NETVPNConnected
- NETLocationCurrent

---

### 68. Backup Success Consistent (Native + Custom)

**Condition Name:** P4_BackupSuccessConsistent  
**Priority:** P4 Low  
**Check Frequency:** Weekly

**Logic:**
```
Backup Status = Success (last 7 consecutive backups)
AND BASEBusinessCriticality IN ("High", "Critical")
```

**Rationale:** Excellent backup compliance on critical systems.

**Actions:**
- No ticket creation
- Dashboard: Display in backup compliant devices
- Report: Weekly backup success report

**Custom Fields Used:**
- BASEBusinessCriticality

---

### 69. Antivirus Current (Native + Custom)

**Condition Name:** P4_AntivirusCurrent  
**Priority:** P4 Low  
**Check Frequency:** Daily

**Logic:**
```
Antivirus Status = Current (definitions < 24 hours old)
AND Antivirus Status = Enabled
AND RISKExposureLevel IN ("Low", "Standard")
```

**Rationale:** Excellent antivirus compliance, positive tracking.

**Actions:**
- No ticket creation
- Dashboard: Display in AV compliant devices

**Custom Fields Used:**
- RISKExposureLevel

---

### 70. Patches Current (Native + Custom)

**Condition Name:** P4_PatchesCurrent  
**Priority:** P4 Low  
**Check Frequency:** Weekly

**Logic:**
```
Patch Status = Current (no missing patches)
AND UPDDaysSinceLastReboot < 7
```

**Rationale:** Excellent patch compliance, positive tracking.

**Actions:**
- No ticket creation
- Dashboard: Display in patch compliant devices
- Report: Weekly patch compliance report

**Custom Fields Used:**
- UPDDaysSinceLastReboot

---

### 71. Network Location Stable (Native + Custom)

**Condition Name:** P4_NetworkLocationStable  
**Priority:** P4 Low  
**Check Frequency:** Weekly

**Logic:**
```
NETLocationCurrent = NETLocationPrevious (no change for 30 days)
AND NETLocationCurrent = "Office"
```

**Rationale:** Device consistently in expected network location.

**Actions:**
- No ticket creation
- Report: Monthly location compliance

**Custom Fields Used:**
- NETLocationCurrent
- NETLocationPrevious

---

### 72. Configuration Baseline Stable (Native + Custom)

**Condition Name:** P4_ConfigurationStable  
**Priority:** P4 Low  
**Check Frequency:** Monthly

**Logic:**
```
BASEDriftScore < 20
AND BASEBusinessCriticality IN ("High", "Critical")
```

**Rationale:** Minimal configuration drift on critical systems, excellent stability.

**Actions:**
- No ticket creation
- Dashboard: Display in configuration compliant devices
- Report: Monthly configuration stability report

**Custom Fields Used:**
- BASEDriftScore
- BASEBusinessCriticality

---

### 73. SMART Status Excellent (Native + Custom)

**Condition Name:** P4_SMARTExcellent  
**Priority:** P4 Low  
**Check Frequency:** Monthly

**Logic:**
```
SMART Status = Healthy
AND Device Age < 3 years
```

**Rationale:** Drive health excellent on newer systems.

**Actions:**
- No ticket creation
- Report: Monthly hardware health report

**Custom Fields Used:**
- None (native only)

---

### 74. Server Uptime Optimal (Native + Custom)

**Condition Name:** P4_ServerUptimeOptimal  
**Priority:** P4 Low  
**Check Frequency:** Monthly

**Logic:**
```
Device Down = False (last 30 days)
AND SRVRole IS NOT NULL
AND OPSHealthScore > 90
```

**Rationale:** Server excellent uptime and health.

**Actions:**
- No ticket creation
- Dashboard: Display in high-availability servers
- Report: Monthly server uptime report

**Custom Fields Used:**
- SRVRole
- OPSHealthScore

---

### 75. Low Risk Profile (Native + Custom)

**Condition Name:** P4_LowRiskProfile  
**Priority:** P4 Low  
**Check Frequency:** Monthly

**Logic:**
```
RISKExposureLevel = "Low"
AND OPSHealthScore > 85
AND STATStabilityScore > 85
AND BASEBusinessCriticality = "Standard"
```

**Rationale:** Device low risk with excellent health, positive tracking.

**Actions:**
- No ticket creation
- Dashboard: Display in low-risk healthy devices
- Report: Monthly risk assessment summary

**Custom Fields Used:**
- RISKExposureLevel
- OPSHealthScore
- STATStabilityScore
- BASEBusinessCriticality

---

## CUSTOM FIELDS USED IN NATIVE INTEGRATION

### Essential Custom Fields (Required)

**Operational Scores:**
- OPSHealthScore - Overall device health (0-100)
- OPSPerformanceScore - Performance assessment (0-100)
- STATStabilityScore - System stability (0-100)

**Telemetry:**
- STATCrashCount30d - Crashes in last 30 days
- STATAvgBootTimeSec - Average boot time in seconds

**Capacity Planning:**
- CAPDaysUntilDiskFull - Predictive disk capacity
- CAPDiskGrowthRateMBPerDay - Daily disk growth rate

**Risk Classification:**
- RISKExposureLevel - Risk assessment (Low/Standard/High/Critical)

**Baseline:**
- BASEBusinessCriticality - Business importance (Standard/High/Critical)
- BASEDriftScore - Configuration drift score (0-100)

**Network:**
- NETLocationCurrent - Current network location
- NETLocationPrevious - Previous network location
- NETVPNConnected - VPN connection status

**Updates:**
- UPDMissingCriticalCount - Count of missing critical patches
- UPDMissingImportantCount - Count of missing important patches
- UPDMissingOptionalCount - Count of missing optional patches
- UPDDaysSinceLastReboot - Days since last system reboot

**Server:**
- SRVRole - Detected server role(s)

**Automation:**
- AUTORemediationEligible - Approved for automation
- AUTOAllowCleanup - Allow disk cleanup automation
- AUTOAllowServiceRestart - Allow service restart automation
- AUTOAllowAfterHoursReboot - Allow scheduled reboots

**Active Directory:**
- ADLastLogonDays - Days since last AD logon
- ADLastSyncStatus - AD synchronization status

**Security:**
- SECSecurityPosture - Security configuration score (0-100)

**User Experience:**
- UXUserProfileSizeGB - User profile size in GB

**Group Policy:**
- GPOLastApplyTimeSec - GPO application time in seconds

**Battery:**
- BATHealthPercent - Battery health percentage

---

## REMOVED/DEPRECATED FIELDS

The following fields from the original framework are **NOT used** in the native-enhanced conditions as they duplicate NinjaOne's built-in capabilities:

**Removed (Native Equivalent Exists):**
- OPSSystemOnline (use: Device Down native)
- STATDiskFreePercent (use: Disk Free Space native)
- STATCPUUtilizationPercent (use: CPU Utilization native)
- STATMemoryUtilizationPercent (use: Memory Utilization native)
- STATDiskActiveTimePercent (use: Disk Active Time native)
- Any custom service monitoring (use: Windows Service Status native)

**Total Custom Fields in Native-Enhanced Framework: ~35 fields**  
(Reduced from 153+ by eliminating native metric duplicates)

---

## DEPLOYMENT RECOMMENDATIONS

### Phase 1: Critical Conditions (Week 1)
Deploy P1 conditions (15 patterns) focusing on business-critical alerts.

### Phase 2: High Priority (Week 2-3)
Add P2 conditions (20 patterns) for proactive monitoring.

### Phase 3: Medium Priority (Week 4-5)
Implement P3 conditions (25 patterns) for optimization tracking.

### Phase 4: Low Priority (Week 6-8)
Add P4 conditions (15 patterns) for reporting and positive tracking.

### Testing Strategy
- Start with pilot group (10-20 devices)
- Monitor alert volume and accuracy
- Tune thresholds based on environment
- Gradually expand to full deployment

---

## BEST PRACTICES

### Threshold Tuning
- Start with conservative thresholds
- Monitor false positive rate
- Adjust based on baseline metrics
- Document threshold changes

### Alert Fatigue Prevention
- Combine multiple checks (native + custom)
- Use appropriate check frequencies
- Escalate only critical alerts
- Provide clear remediation paths

### Performance Impact
- Native conditions are optimized by NinjaOne
- Custom field checks are lightweight
- Combined conditions minimal overhead
- Schedule heavy checks during off-hours

### Documentation
- Document threshold decisions
- Track condition modifications
- Review quarterly for effectiveness
- Maintain change log

---

**Version:** 1.0 (Native Integration)  
**Last Updated:** February 1, 2026, 4:45 PM CET  
**Total Conditions:** 75 patterns  
**Custom Fields Required:** ~35 fields  
**Native Metrics Used:** 11+ built-in conditions  
**Status:** Production Ready
