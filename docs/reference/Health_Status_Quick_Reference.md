# Health Status Quick Reference

**Purpose:** Quick reference for health status classification  
**Created:** February 8, 2026  
**Format:** Status meanings and common thresholds

---

## The 4 Standard Health Status Values

### Unknown
**Meaning:** Cannot determine health status  
**Color:** Gray  
**When Used:**
- Data not available
- Script hasn't run yet
- Error during data collection
- Feature not installed
- Not applicable to device type

**Action:** Investigate why data is missing

---

### Healthy
**Meaning:** All metrics within normal parameters  
**Color:** Green  
**Criteria:** All checks passed, no issues detected

**Typical Conditions:**
- Disk space >20%
- Memory usage <80%
- CPU average <70%
- Services running
- Backup <24 hours old
- No critical errors
- Security controls enabled

**Action:** No action required, continue monitoring

---

### Warning
**Meaning:** Minor issues detected, attention needed  
**Color:** Orange/Yellow  
**Criteria:** One or more metrics approaching thresholds

**Typical Conditions:**
- Disk space 10-20%
- Memory usage 80-90%
- CPU average 70-90%
- Service degraded
- Backup 24-48 hours old
- Some errors present
- Minor security issues

**Action:** Review and plan remediation, not urgent

---

### Critical
**Meaning:** Major issues require immediate attention  
**Color:** Red  
**Criteria:** One or more metrics exceed critical thresholds

**Typical Conditions:**
- Disk space <10%
- Memory usage >90%
- CPU average >90%
- Service stopped
- Backup >48 hours old
- Many critical errors
- Security controls disabled

**Action:** Immediate intervention required

---

## Common Threshold Patterns

### Pattern 1: Percentage-Based (Disk, Memory, CPU)

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Disk Free % | >20% | 10-20% | <10% |
| Memory Used % | <80% | 80-90% | >90% |
| CPU Average % | <70% | 70-90% | >90% |
| Battery Health % | >80% | 50-80% | <50% |

### Pattern 2: Time-Based (Backups, Patches, Updates)

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Backup Age | <24h | 24-48h | >48h |
| Patch Age | <30d | 30-60d | >60d |
| AV Update Age | <24h | 24-48h | >48h |
| GPO Applied | <8h | 8-24h | >24h |
| Last Reboot | <30d | 30-60d | >60d |

### Pattern 3: Count-Based (Errors, Crashes, Services)

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Critical Errors (24h) | 0 | 1-10 | >10 |
| Crashes (30d) | 0-2 | 3-5 | >5 |
| Failed Services | 0 | 1-2 | >2 |
| Failed Logins (24h) | 0-5 | 6-10 | >10 |
| Missing Critical Patches | 0 | 0 | >0 |

### Pattern 4: Boolean/Service State

| Service | Healthy | Warning | Critical |
|---------|---------|---------|----------|
| Service Running | Yes | - | No |
| Antivirus Enabled | Yes | - | No |
| Firewall Enabled | Yes | - | No |
| BitLocker Encrypted | Yes | Partial | No |
| Backup Job Success | Yes | - | Failed |

### Pattern 5: Score-Based (0-100 Scores)

| Score Range | Status | Interpretation | Action |
|-------------|--------|----------------|--------|
| 80-100 | Healthy | Excellent health | Continue monitoring |
| 70-79 | Healthy | Good health | Monitor closely |
| 60-69 | Warning | Fair, declining | Plan remediation |
| 40-59 | Warning | Poor, attention needed | Take action soon |
| 0-39 | Critical | Very poor, urgent | Immediate action |

---

## Health Status by Category

### Overall Device Health
**Field:** `healthStatus` or `opsHealthScore`

**Healthy:** Score 70+, all systems normal  
**Warning:** Score 40-69, some issues  
**Critical:** Score <40, multiple failures  
**Unknown:** No data available

### Disk Space
**Field:** `diskHealthStatus` or `diskFreePercent`

**Healthy:** >20% free  
**Warning:** 10-20% free  
**Critical:** <10% free  
**Unknown:** Cannot access disk

### Memory
**Field:** `memoryPressure` or `memoryUsedPercent`

**Healthy:** <80% used  
**Warning:** 80-90% used  
**Critical:** >90% used  
**Unknown:** Cannot read memory

### Security
**Field:** `opsSecurityScore` or `securityPostureScore`

**Healthy:** AV+Firewall enabled, patches current  
**Warning:** Missing some patches, minor issues  
**Critical:** AV/Firewall disabled, many missing patches  
**Unknown:** Cannot assess security

### Backups
**Field:** `veeamHealthStatus` or `backupLastSuccess`

**Healthy:** Backup <24 hours, successful  
**Warning:** Backup 24-48 hours  
**Critical:** Backup >48 hours or failed  
**Unknown:** No backup data

### Server Services (DNS, DHCP, IIS, SQL, etc.)
**Field:** `dnsServerStatus`, `dhcpServerStatus`, etc.

**Healthy:** Service running, no errors  
**Warning:** Service running with errors/warnings  
**Critical:** Service stopped or major failures  
**Unknown:** Service not installed or cannot check

---

## Quick Decision Tree

```
Start: Evaluate Device
    │
    ↓
  Data Available?
    │
    ├─ No → Unknown
    │
    └─ Yes
        │
        ↓
      Any Critical Issues?
      (Service down, AV disabled, disk <10%, etc.)
        │
        ├─ Yes → Critical
        │
        └─ No
            │
            ↓
          Any Warning Issues?
          (Disk 10-20%, many warnings, degraded)
            │
            ├─ Yes → Warning
            │
            └─ No → Healthy
```

---

## Status Determination Examples

### Example 1: Workstation Health
```
Metrics:
- Disk: 35% free
- Memory: 65% used
- CPU: 45% average
- Crashes: 1 in 30 days
- Backup: 18 hours ago
- AV: Enabled
- Firewall: Enabled

Result: Healthy (all metrics in normal range)
```

### Example 2: Server Warning
```
Metrics:
- Disk: 15% free (Warning threshold)
- Memory: 75% used
- SQL Service: Running
- Backup: 36 hours ago (Warning threshold)
- Patches: 2 important missing

Result: Warning (disk and backup in warning range)
```

### Example 3: Critical Workstation
```
Metrics:
- Disk: 7% free (Critical threshold)
- Memory: 92% used (Critical threshold)
- Crashes: 12 in 30 days
- Antivirus: Disabled (Critical)
- Backup: No backup data

Result: Critical (multiple critical thresholds exceeded)
```

### Example 4: Unknown Status
```
Metrics:
- Health Score: Field empty
- Last Script Run: Never
- Telemetry: No data

Result: Unknown (no data to evaluate)
```

---

## Field-Specific Status Logic

### BitLocker Status
- **Healthy:** Fully encrypted, protection on
- **Warning:** Encryption in progress, protection suspended
- **Critical:** Not encrypted, protection off
- **Unknown:** Cannot determine (workstation, not applicable)

### DNS Server Status
- **Healthy:** Service running, zones loaded, <10 failed queries
- **Warning:** Service running, 10-50 failed queries, minor errors
- **Critical:** Service stopped, >50 failed queries, zones offline
- **Unknown:** DNS role not installed

### Patch Compliance
- **Healthy:** No critical patches missing, <5 important
- **Warning:** 1-2 critical or 5-10 important missing
- **Critical:** >2 critical or >10 important missing
- **Unknown:** Cannot check Windows Update

---

## Using Status Values

### In Dashboards
1. Filter by status: `healthStatus = "Critical"`
2. Sort by score: `opsHealthScore` ascending
3. Color-code rows by status
4. Group by status for counts

### In Conditions/Alerts
```
Critical Device Alert:
IF healthStatus = "Critical"
THEN Create P1 ticket

Warning Device Alert:
IF healthStatus = "Warning" AND baseBusinessCriticality = "Critical"
THEN Create P2 ticket
```

### In Reports
- Count devices by status
- Track status trends over time
- Identify devices degrading from Healthy → Warning → Critical
- Calculate percentage in each status

---

## Related Documentation

**Detailed Logic:** [../diagrams/07_Health_Status_Classification.md](../diagrams/07_Health_Status_Classification.md)  
**Field Meanings:** [Field_Quick_Reference.md](Field_Quick_Reference.md)  
**Alert Configuration:** [Alert_Configuration_Guide.md](Alert_Configuration_Guide.md)  
**Dashboard Templates:** [Dashboard_Templates.md](Dashboard_Templates.md)

---

**Status Values:** 4 (Unknown, Healthy, Warning, Critical)  
**Common Patterns:** 5 (Percentage, Time, Count, Boolean, Score)  
**Last Updated:** February 8, 2026
