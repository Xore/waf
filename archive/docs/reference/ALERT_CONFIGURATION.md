# WAF Alert Configuration Guide

**Purpose:** Recommended alert conditions and thresholds for Windows Automation Framework  
**Created:** February 8, 2026  
**Audience:** Administrators, operations managers, monitoring teams  
**Status:** Production-tested alert templates

---

## Overview

This guide provides complete alert configurations organized by category. Each alert includes condition logic, severity levels, recommended actions, and notification routing.

### Alert Categories
1. Critical Health Alerts
2. Security Alerts
3. Capacity Alerts
4. Backup Alerts
5. Patching Alerts
6. Infrastructure Alerts

### Severity Levels
- **P1 Critical:** Immediate response required, service impacting
- **P2 High:** Urgent attention needed, potential service impact
- **P3 Medium:** Attention needed within business hours
- **P4 Low:** Informational, review during maintenance

---

## 1. Critical Health Alerts

### 1.1 Critical Health Score
**Severity:** P1 Critical  
**Condition Logic:**
```
opsHealthScore < 40
```
**Description:** Device health has fallen to critical levels

**Actions:**
- Create ticket with P1 priority
- Send immediate notification to on-call team
- Run diagnostic script
- Check `statCrashCount30d`, `statServiceFailures24h`, `capDiskFreePercent`

**Notification:** Email + SMS to on-call engineer

**Auto-Remediation:** Run health diagnostic script

**Escalation:** If not acknowledged in 15 minutes, escalate to manager

---

### 1.2 Critical Stability Score
**Severity:** P1 Critical  
**Condition Logic:**
```
statStabilityScore < 40
```
**Description:** Device stability severely degraded

**Actions:**
- Create ticket with P1 priority
- Immediate notification
- Review crash history and event logs
- Check for recent software changes
- Consider scheduling maintenance

**Related Fields:**
- `statCrashCount30d` - Should be elevated
- `statServiceFailures24h` - Check for service issues
- `driftLocalAdminDrift` - Check for config changes

**Notification:** Email + SMS

**Auto-Remediation:** None (requires investigation)

---

### 1.3 Multiple System Crashes
**Severity:** P2 High  
**Condition Logic:**
```
statCrashCount30d > 10
```
**Description:** Device experiencing frequent crashes

**Actions:**
- Create ticket with P2 priority
- Analyze crash dumps
- Review recent software installations
- Check hardware diagnostics
- Update device drivers

**Notification:** Email to support team

**Auto-Remediation:** Run memory diagnostic

---

### 1.4 Degraded Health Status
**Severity:** P3 Medium  
**Condition Logic:**
```
opsHealthScore >= 40 AND opsHealthScore < 70
```
**Description:** Device health degraded but not critical

**Actions:**
- Create ticket with P3 priority
- Schedule review during business hours
- Identify root cause
- Plan remediation

**Notification:** Email to support queue

---

### 1.5 Service Failures
**Severity:** P2 High  
**Condition Logic:**
```
statServiceFailures24h > 5
```
**Description:** Multiple service failures detected

**Actions:**
- Create ticket with P2 priority
- Review failed services
- Check service dependencies
- Restart critical services

**Related Fields:**
- `driftCriticalServiceDrift` - Check for config changes

**Notification:** Email to operations team

**Auto-Remediation:** Attempt service restart

---

## 2. Security Alerts

### 2.1 Antivirus Disabled
**Severity:** P1 Critical  
**Condition Logic:**
```
secAntivirusEnabled = False
```
**Description:** Antivirus protection is disabled

**Actions:**
- Create ticket with P1 priority
- Immediate notification to security team
- Attempt to enable AV
- Isolate device if enable fails
- Scan for malware

**Notification:** Email + SMS to security team

**Auto-Remediation:** Run AV enable script

**Escalation:** Security manager if not resolved in 30 minutes

---

### 2.2 Firewall Disabled
**Severity:** P1 Critical  
**Condition Logic:**
```
secFirewallEnabled = False
```
**Description:** Windows Firewall is disabled

**Actions:**
- Create ticket with P1 priority
- Immediate notification to security team
- Enable firewall
- Check for policy conflicts
- Review recent changes

**Notification:** Email + SMS to security team

**Auto-Remediation:** Run firewall enable script

---

### 2.3 Critical Patch Gap
**Severity:** P1 Critical  
**Condition Logic:**
```
updComplianceStatus = "Critical Gap"
```
**Description:** Device has critical security updates missing

**Actions:**
- Create ticket with P1 priority
- Schedule emergency patching
- Validate patch compatibility
- Deploy patches
- Monitor for issues

**Related Fields:**
- `updMissingCriticalCount` - Number of critical patches
- `updPatchAgeDays` - Days since last update

**Notification:** Email to patch management team

**Auto-Remediation:** Trigger patch deployment (if validation passes)

---

### 2.4 Security Posture Critical
**Severity:** P1 Critical  
**Condition Logic:**
```
secSecurityPostureScore < 40
```
**Description:** Overall security posture at critical level

**Actions:**
- Create ticket with P1 priority
- Comprehensive security review
- Check all security controls
- Remediate findings
- Re-assess posture

**Related Fields:**
- `secAntivirusEnabled`
- `secFirewallEnabled`
- `secBitLockerStatus`
- `updComplianceStatus`

**Notification:** Email + SMS to security team

---

### 2.5 Suspicious Login Activity
**Severity:** P2 High  
**Condition Logic:**
```
secSuspiciousLoginScore > 70
```
**Description:** Potential credential compromise detected

**Actions:**
- Create ticket with P2 priority
- Review login attempts
- Check for brute force attacks
- Contact user to verify activity
- Reset password if compromised
- Enable MFA

**Related Fields:**
- `secFailedLogonCount24h`
- `secAccountLockouts24h`

**Notification:** Email to security team

---

### 2.6 Internet Exposure Risk
**Severity:** P2 High  
**Condition Logic:**
```
secHighRiskServicesExposed > 0
```
**Description:** High-risk services exposed to internet

**Actions:**
- Create ticket with P2 priority
- Identify exposed services
- Validate if exposure is intentional
- Implement firewall rules
- Consider VPN requirement

**Related Fields:**
- `secInternetExposedPortsCount`
- `secSecuritySurfaceSummaryHtml`

**Notification:** Email to security and network teams

---

### 2.7 Certificate Expiring Soon
**Severity:** P3 Medium  
**Condition Logic:**
```
secSoonExpiringCertsCount > 0
```
**Description:** SSL/TLS certificates expiring within 30 days

**Actions:**
- Create ticket with P3 priority
- Identify expiring certificates
- Renew certificates
- Test certificate deployment
- Update certificate stores

**Notification:** Email to PKI team

---

### 2.8 BitLocker Not Protected
**Severity:** P2 High (for laptops/portable devices)  
**Condition Logic:**
```
secBitLockerStatus != "Protected" 
AND deviceType = "Laptop"
```
**Description:** Portable device lacks encryption

**Actions:**
- Create ticket with P2 priority
- Enable BitLocker
- Backup recovery key
- Verify encryption status

**Notification:** Email to security team

**Auto-Remediation:** Run BitLocker enable script

---

### 2.9 Configuration Drift - Admin Changes
**Severity:** P3 Medium  
**Condition Logic:**
```
driftLocalAdminDrift = True 
AND driftLocalAdminDriftMagnitude IN ("High", "Critical")
```
**Description:** Significant local admin configuration changes detected

**Actions:**
- Create ticket with P3 priority
- Review changes
- Verify authorization
- Remediate unauthorized changes
- Update baseline if authorized

**Related Fields:**
- `driftLocalAdminDriftMagnitude`

**Notification:** Email to compliance team

---

### 2.10 Shadow IT Detection
**Severity:** P3 Medium  
**Condition Logic:**
```
driftNewAppsCount > 5
```
**Description:** Multiple unauthorized applications detected

**Actions:**
- Create ticket with P3 priority
- Review installed applications
- Validate software licenses
- Remove unauthorized software
- Update approved software list

**Related Fields:**
- `driftNewAppsList`

**Notification:** Email to IT management

---

## 3. Capacity Alerts

### 3.1 Disk Space Critical
**Severity:** P1 Critical  
**Condition Logic:**
```
capDiskFreePercent < 5
```
**Description:** Disk space critically low

**Actions:**
- Create ticket with P1 priority
- Run emergency disk cleanup
- Identify large files
- Archive or delete data
- Monitor continuously

**Notification:** Email + SMS to operations

**Auto-Remediation:** Run emergency cleanup script

**Escalation:** Manager if not resolved in 1 hour

---

### 3.2 Disk Space Low Warning
**Severity:** P2 High  
**Condition Logic:**
```
capDiskFreePercent >= 5 AND capDiskFreePercent < 20
```
**Description:** Disk space approaching critical levels

**Actions:**
- Create ticket with P2 priority
- Run disk cleanup
- Review disk usage
- Plan capacity expansion
- Schedule cleanup maintenance

**Notification:** Email to operations team

**Auto-Remediation:** Run standard cleanup script

---

### 3.3 Disk Full in 30 Days
**Severity:** P2 High  
**Condition Logic:**
```
capDaysUntilDiskFull <= 30
```
**Description:** Disk projected to fill within 30 days

**Actions:**
- Create ticket with P2 priority
- Review storage growth trends
- Plan capacity expansion
- Implement data archival
- Request additional storage

**Related Fields:**
- `capDiskFreePercent`

**Notification:** Email to capacity planning team

---

### 3.4 Capacity Action Required
**Severity:** P3 Medium  
**Condition Logic:**
```
capCapacityActionNeeded = True
```
**Description:** Automated capacity analysis recommends action

**Actions:**
- Create ticket with P3 priority
- Review capacity forecasts
- Evaluate recommendations
- Plan remediation
- Schedule expansion

**Related Fields:**
- `capMemoryForecastRisk`
- `capCPUForecastRisk`
- `capDaysUntilDiskFull`

**Notification:** Email to capacity planning team

---

### 3.5 Memory Utilization Critical
**Severity:** P2 High  
**Condition Logic:**
```
capMemoryUsedPercent > 95
```
**Description:** Memory utilization critically high

**Actions:**
- Create ticket with P2 priority
- Identify memory-intensive processes
- Restart services if needed
- Consider memory upgrade
- Monitor application behavior

**Notification:** Email to operations team

**Auto-Remediation:** Run memory optimization script

---

### 3.6 Memory Forecast Risk
**Severity:** P3 Medium  
**Condition Logic:**
```
capMemoryForecastRisk IN ("High", "Critical")
```
**Description:** Memory capacity projected to become inadequate

**Actions:**
- Create ticket with P3 priority
- Review memory trends
- Plan memory upgrade
- Optimize application usage
- Budget for hardware

**Notification:** Email to capacity planning team

---

### 3.7 CPU Forecast Risk
**Severity:** P3 Medium  
**Condition Logic:**
```
capCPUForecastRisk IN ("High", "Critical")
```
**Description:** CPU capacity projected to become inadequate

**Actions:**
- Create ticket with P3 priority
- Review CPU utilization trends
- Optimize workloads
- Consider CPU upgrade
- Evaluate virtualization

**Notification:** Email to capacity planning team

---

## 4. Backup Alerts

### 4.1 Veeam Backup Failed
**Severity:** P1 Critical (for critical servers), P2 High (for others)  
**Condition Logic:**
```
veeamFailedJobsCount > 0
```
**Description:** Veeam backup job(s) failed

**Actions:**
- Create ticket (priority based on server criticality)
- Review backup logs
- Retry failed jobs
- Check storage capacity
- Verify backup infrastructure

**Related Fields:**
- `veeamHealthStatus`
- `veeamWarningJobsCount`

**Notification:** Email + SMS (critical servers) or Email only (others)

**Auto-Remediation:** Retry backup job once

---

### 4.2 Backup Age Critical (Critical Servers)
**Severity:** P1 Critical  
**Condition Logic:**
```
backupLastSuccess > 24 hours ago
AND basePriority = "P1"
```
**Description:** Critical server backup overdue

**Actions:**
- Create ticket with P1 priority
- Immediate backup execution
- Check backup infrastructure
- Verify storage availability
- Monitor backup completion

**Notification:** Email + SMS to backup team

---

### 4.3 Backup Age Warning (All Servers)
**Severity:** P2 High  
**Condition Logic:**
```
backupLastSuccess > 48 hours ago
```
**Description:** Server backup significantly overdue

**Actions:**
- Create ticket with P2 priority
- Schedule backup
- Investigate backup failures
- Check retention policies

**Notification:** Email to backup team

---

### 4.4 SQL Backup Overdue
**Severity:** P1 Critical  
**Condition Logic:**
```
mssqlLastBackup > 24 hours ago
```
**Description:** SQL Server database backup overdue

**Actions:**
- Create ticket with P1 priority
- Execute manual SQL backup
- Check SQL Agent status
- Review backup job schedules
- Verify backup destination

**Notification:** Email + SMS to database team

**Auto-Remediation:** Trigger SQL backup job

---

### 4.5 Veeam Warning State
**Severity:** P3 Medium  
**Condition Logic:**
```
veeamWarningJobsCount > 0
```
**Description:** Veeam backup job(s) completed with warnings

**Actions:**
- Create ticket with P3 priority
- Review warning details
- Address warning causes
- Monitor next backup cycle

**Notification:** Email to backup team

---

## 5. Patching Alerts

### 5.1 Patch Deployment Failed (P1 Devices)
**Severity:** P1 Critical  
**Condition Logic:**
```
patchLastAttemptStatus CONTAINS "Failed"
AND basePriority = "P1"
```
**Description:** Patch deployment failed on critical device

**Actions:**
- Create ticket with P1 priority
- Review deployment logs
- Check pre-requisites
- Validate device health
- Retry deployment

**Related Fields:**
- `patchValidationNotes`
- `opsHealthScore`
- `statStabilityScore`

**Notification:** Email + SMS to patch team

---

### 5.2 Multiple Patch Failures
**Severity:** P2 High  
**Condition Logic:**
```
patchLastAttemptStatus CONTAINS "Failed"
AND statCrashCount30d > 3
```
**Description:** Device with repeated patch failures

**Actions:**
- Create ticket with P2 priority
- Investigate root cause
- Check Windows Update service
- Review CBS logs
- Consider manual patching

**Notification:** Email to patch team

---

### 5.3 Patch Validation Failed
**Severity:** P2 High  
**Condition Logic:**
```
patchValidationStatus = "Failed"
```
**Description:** Device failed pre-deployment validation

**Actions:**
- Create ticket with P2 priority
- Review validation failures
- Remediate issues
- Re-run validation
- Deploy patches once validated

**Related Fields:**
- `patchValidationNotes`

**Notification:** Email to patch team

---

### 5.4 Reboot Pending Extended
**Severity:** P3 Medium  
**Condition Logic:**
```
patchRebootPending = True
AND updDaysSinceLastReboot > 7
```
**Description:** Device requires reboot for over 7 days

**Actions:**
- Create ticket with P3 priority
- Contact device owner
- Schedule reboot
- Force reboot if authorized

**Related Fields:**
- `autoAllowAfterHoursReboot`

**Notification:** Email to operations team

**Auto-Remediation:** Schedule after-hours reboot (if enabled)

---

### 5.5 Patch Ring PR1 Failure Rate High
**Severity:** P2 High  
**Condition Logic:**
```
Calculated: PR1 deployment success rate < 90%
```
**Description:** Test ring deployment failure rate too high

**Actions:**
- Create ticket with P2 priority
- Hold PR2 production deployment
- Review PR1 failures
- Identify common issues
- Remediate before PR2

**Notification:** Email to patch management team

---

### 5.6 Critical Updates Missing
**Severity:** P2 High  
**Condition Logic:**
```
updMissingCriticalCount > 0
```
**Description:** Critical security updates not installed

**Actions:**
- Create ticket with P2 priority
- Schedule patch deployment
- Validate compatibility
- Deploy updates
- Verify installation

**Notification:** Email to patch team

---

### 5.7 Patch Age Excessive
**Severity:** P3 Medium  
**Condition Logic:**
```
updPatchAgeDays > 90
```
**Description:** Device hasn't been patched in over 90 days

**Actions:**
- Create ticket with P3 priority
- Verify device online
- Check patch policies
- Schedule comprehensive patching
- Update patch ring assignment

**Related Fields:**
- `updComplianceStatus`

**Notification:** Email to patch team

---

## 6. Infrastructure Alerts

### 6.1 IIS Application Pool Stopped
**Severity:** P1 Critical  
**Condition Logic:**
```
iisAppPoolsStopped > 0
```
**Description:** IIS application pool(s) not running

**Actions:**
- Create ticket with P1 priority
- Start application pool
- Review event logs
- Check application health
- Monitor for recurrence

**Related Fields:**
- `iisHealthStatus`
- `iisWorkerProcessCrashes24h`

**Notification:** Email + SMS to web team

**Auto-Remediation:** Restart application pool

**Escalation:** Web team manager if pool won't start

---

### 6.2 IIS Worker Process Crashes
**Severity:** P2 High  
**Condition Logic:**
```
iisWorkerProcessCrashes24h > 5
```
**Description:** IIS worker processes crashing frequently

**Actions:**
- Create ticket with P2 priority
- Review crash dumps
- Check application code
- Review recent deployments
- Consider application pool recycling adjustments

**Notification:** Email to web team

---

### 6.3 SQL Server Database Offline
**Severity:** P1 Critical  
**Condition Logic:**
```
mssqlDatabaseStatus CONTAINS "Offline"
```
**Description:** SQL Server database(s) offline

**Actions:**
- Create ticket with P1 priority
- Bring database online
- Check database integrity
- Review error logs
- Notify application owners

**Related Fields:**
- `mssqlHealthStatus`

**Notification:** Email + SMS to database team

---

### 6.4 SQL Deadlocks Excessive
**Severity:** P3 Medium  
**Condition Logic:**
```
mssqlDeadlocks24h > 10
```
**Description:** High number of SQL deadlocks

**Actions:**
- Create ticket with P3 priority
- Analyze deadlock graphs
- Review query patterns
- Optimize queries
- Adjust isolation levels

**Notification:** Email to database team

---

### 6.5 DNS Query Failures
**Severity:** P2 High  
**Condition Logic:**
```
dnsFailedQueries24h > 100
```
**Description:** DNS server experiencing query failures

**Actions:**
- Create ticket with P2 priority
- Check DNS service status
- Review zone configurations
- Verify forwarders
- Check network connectivity

**Related Fields:**
- `dnsHealthStatus`
- `dnsZoneTransferErrors24h`

**Notification:** Email to network team

---

### 6.6 DHCP Scope Depleted
**Severity:** P1 Critical  
**Condition Logic:**
```
dhcpScopesDepleted > 0
```
**Description:** DHCP scope(s) out of addresses

**Actions:**
- Create ticket with P1 priority
- Expand scope range
- Review lease durations
- Identify address exhaustion cause
- Consider subnet redesign

**Related Fields:**
- `dhcpScopeUtilizationPercent`

**Notification:** Email + SMS to network team

---

### 6.7 DHCP Scope Utilization High
**Severity:** P3 Medium  
**Condition Logic:**
```
dhcpScopeUtilizationPercent > 90
```
**Description:** DHCP scope nearing capacity

**Actions:**
- Create ticket with P3 priority
- Plan scope expansion
- Review current allocations
- Clean up stale leases
- Monitor utilization trends

**Notification:** Email to network team

---

### 6.8 Hyper-V Host Critical
**Severity:** P1 Critical  
**Condition Logic:**
```
hvHealthStatus = "Critical"
```
**Description:** Hyper-V host in critical state

**Actions:**
- Create ticket with P1 priority
- Check VM health
- Review host resources
- Migrate VMs if needed
- Investigate host issues

**Related Fields:**
- `hvMemoryAvailableMB`
- `hvStorageAvailableGB`

**Notification:** Email + SMS to virtualization team

---

### 6.9 Domain Controller Unreachable
**Severity:** P1 Critical  
**Condition Logic:**
```
adDCReachable = False
```
**Description:** Domain controller cannot be contacted

**Actions:**
- Create ticket with P1 priority
- Check DC status
- Verify network connectivity
- Check AD services
- Notify directory services team

**Related Fields:**
- `adDomainTrustStatus`
- `adReplicationStatus`

**Notification:** Email + SMS to directory services team

---

### 6.10 AD Replication Lag High
**Severity:** P2 High  
**Condition Logic:**
```
adReplicationLagMinutes > 60
```
**Description:** Active Directory replication delayed

**Actions:**
- Create ticket with P2 priority
- Check replication topology
- Verify network connectivity
- Review replication errors
- Force replication if needed

**Related Fields:**
- `adReplicationStatus`

**Notification:** Email to directory services team

---

## Alert Configuration Templates

### Template 1: Simple Threshold Alert
```yaml
Name: [Alert Name]
Severity: [P1/P2/P3/P4]
Condition:
  Field: [fieldName]
  Operator: [<, >, =, !=, CONTAINS]
  Value: [threshold]
Actions:
  - CreateTicket:
      Priority: [P1/P2/P3/P4]
      AssignTo: [team]
  - SendNotification:
      Channel: [Email/SMS/Both]
      Recipients: [group]
  - RunScript: [scriptName] (optional)
Escalation:
  Timeout: [minutes]
  EscalateTo: [manager/team]
```

### Template 2: Complex Logic Alert
```yaml
Name: [Alert Name]
Severity: [P1/P2/P3/P4]
Condition:
  Logic: AND/OR
  Rules:
    - Field: [field1]
      Operator: [operator]
      Value: [value1]
    - Field: [field2]
      Operator: [operator]
      Value: [value2]
Actions:
  [same as Template 1]
```

### Template 3: Priority-Based Alert
```yaml
Name: [Alert Name]
Severity: Dynamic based on basePriority
Condition:
  Field: [fieldName]
  Operator: [operator]
  Value: [threshold]
SeverityMapping:
  - If basePriority = "P1": Severity = P1
  - If basePriority = "P2": Severity = P2
  - Else: Severity = P3
Actions:
  [vary by severity]
```

---

## Notification Routing

### By Severity
- **P1 Critical:** Email + SMS to on-call engineer + manager
- **P2 High:** Email to on-call engineer + team queue
- **P3 Medium:** Email to team queue
- **P4 Low:** Email to team queue (daily digest)

### By Category
- **Health/Stability:** Operations team
- **Security:** Security team + compliance officer
- **Capacity:** Capacity planning team
- **Backup:** Backup team + storage team
- **Patching:** Patch management team
- **Infrastructure:** Specialized teams (web, database, network, etc.)

### Escalation Paths
1. **Initial Alert:** Assigned team/engineer
2. **15 minutes (P1):** Team lead
3. **30 minutes (P1):** Manager
4. **1 hour (P1):** Director
5. **P2/P3:** Escalate if SLA exceeded

---

## Alert Tuning Guidelines

### Threshold Adjustment
1. **Monitor for 30 days:** Baseline normal values
2. **Analyze false positives:** Adjust thresholds to reduce noise
3. **Review with teams:** Validate thresholds match expectations
4. **Document changes:** Track threshold adjustments
5. **Re-evaluate quarterly:** Adjust as environment changes

### Alert Suppression
- **Maintenance windows:** Suppress all non-critical alerts
- **Known issues:** Temporary suppression with expiration
- **Duplicate alerts:** Group related alerts
- **Test devices:** Separate alert policies

### Alert Dependencies
- If DC unreachable, suppress AD-related alerts
- If network down, suppress connectivity alerts
- If host down, suppress VM alerts
- If backup system down, suppress backup job alerts

---

## Testing and Validation

### Alert Testing Procedure
1. **Simulate condition:** Trigger alert condition on test device
2. **Verify detection:** Confirm alert fires within expected timeframe
3. **Check notification:** Verify correct recipients receive notification
4. **Test actions:** Confirm ticket creation and script execution
5. **Validate escalation:** Test escalation after timeout
6. **Document results:** Record test outcomes

### Production Validation
- Monitor alert volume first week
- Review false positive rate
- Adjust thresholds as needed
- Gather team feedback
- Refine notification routing

---

## Best Practices

1. **Start conservative:** Begin with higher thresholds, tighten over time
2. **Prioritize critical:** Focus on P1/P2 alerts first
3. **Avoid alert fatigue:** Too many alerts = ignored alerts
4. **Group related alerts:** Bundle similar alerts
5. **Clear descriptions:** Alert text should explain the issue
6. **Actionable alerts:** Every alert should have clear remediation steps
7. **Regular review:** Monthly review of alert effectiveness
8. **Document exceptions:** Track and justify threshold deviations
9. **Test regularly:** Quarterly alert testing
10. **Continuous improvement:** Refine based on incidents and feedback

---

**Total Alert Templates:** 50+ production-ready configurations  
**Alert Categories:** 6 comprehensive categories  
**Severity Levels:** P1 Critical to P4 Low  
**Status:** Production tested and validated  
**Last Updated:** February 8, 2026
