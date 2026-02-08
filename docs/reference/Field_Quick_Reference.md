# Field Quick Reference

**Purpose:** Quick lookup for most important custom fields  
**Created:** February 8, 2026  
**Format:** One-line descriptions

---

## Top 50 Critical Fields

### Health and Status (10 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| healthStatus | Text | Overall device health | Critical |
| opsHealthScore | Integer | Health score 0-100 | <70 |
| statStabilityScore | Integer | Stability score 0-100 | <70 |
| opsPerformanceScore | Integer | Performance score 0-100 | <70 |
| opsSecurityScore | Integer | Security score 0-100 | <70 |
| opsCapacityScore | Integer | Capacity score 0-100 | <70 |
| riskHealthLevel | Dropdown | Health classification | Critical |
| baseDeviceType | Text | Workstation/Server | N/A |
| srvRole | Text | Server role(s) | N/A |
| telemetryLastUpdate | DateTime | Last data collection | >24h |

### Disk Space (5 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| diskFreePercent | Integer | Disk free percentage | <20% |
| diskFreeGB | Integer | Disk free gigabytes | <10GB |
| diskDaysUntilFull | Integer | Days until full | <30 |
| diskHealthStatus | Text | Disk health | Critical |
| diskIOLatencyMs | Integer | Disk response time | >50ms |

### Memory (4 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| memoryUsedPercent | Integer | Memory utilization | >85% |
| memoryAvailableGB | Integer | Available memory | <2GB |
| memoryPressure | Text | Memory status | High |
| memoryPageFaultRate | Integer | Page faults/sec | >1000 |

### Security (8 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| secAntivirusEnabled | Checkbox | AV protection | False |
| secFirewallEnabled | Checkbox | Firewall status | False |
| bitlockerHealthStatus | Text | Encryption status | Critical |
| bitlockerEncrypted | Checkbox | Drive encrypted | False |
| securityPostureScore | Integer | Security score | <70 |
| suspiciousLoginScore | Integer | Login anomaly | >50 |
| failedLogonCount24h | Integer | Failed logins | >10 |
| accountLockouts24h | Integer | Locked accounts | >3 |

### Updates and Patches (5 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| updComplianceStatus | Text | Patch status | Critical |
| updMissingCriticalCount | Integer | Critical patches | >0 |
| updMissingImportantCount | Integer | Important patches | >5 |
| patchValidationStatus | Text | Ready for patching | Failed |
| patchLastAttemptStatus | Text | Last patch result | Failed |

### Backup (3 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| backupLastSuccess | DateTime | Last backup | >24h |
| veeamHealthStatus | Text | Veeam status | Critical |
| veeamFailedJobsCount | Integer | Failed backups | >0 |

### Server Monitoring (8 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| dnsServerStatus | Text | DNS health | Critical |
| dhcpServerStatus | Text | DHCP health | Critical |
| iisHealthStatus | Text | IIS health | Critical |
| mssqlHealthStatus | Text | SQL health | Critical |
| mysqlHealthStatus | Text | MySQL health | Critical |
| fsHealthStatus | Text | File Server health | Critical |
| printHealthStatus | Text | Print health | Critical |
| hvHealthStatus | Text | Hyper-V health | Critical |

### Configuration Drift (4 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| driftLocalAdminDrift | Checkbox | Admin changes | True |
| driftNewAppsCount | Integer | Shadow IT | >0 |
| driftCriticalServiceDrift | Checkbox | Service changes | True |
| driftDriftEvents30d | Integer | Drift frequency | >10 |

### User Experience (3 fields)

| Field | Type | Purpose | Alert On |
|-------|------|---------|----------|
| uxExperienceScore | Integer | UX score 0-100 | <70 |
| uxBootDegradationFlag | Checkbox | Slow boot | True |
| appTopCrashingApp | Text | Problem app | N/A |

---

## Field Value Quick Reference

### Health Status Values
- **Unknown** - Cannot determine (missing data)
- **Healthy** - All metrics normal
- **Warning** - Attention needed soon
- **Critical** - Immediate action required

### Score Ranges (0-100)
- **80-100** - Excellent
- **70-79** - Good
- **60-69** - Fair (monitor)
- **40-59** - Poor (action needed)
- **0-39** - Critical (urgent)

### Common Thresholds
- **Disk Space** - Warning <20%, Critical <10%
- **Memory** - Warning >80%, Critical >90%
- **CPU** - Warning >80%, Critical >90%
- **Backup Age** - Warning >24h, Critical >48h
- **Patch Age** - Warning >30d, Critical >60d

---

## Field Naming Conventions

### Prefixes
- **OPS** - Operational scores and metrics
- **STAT** - Statistical telemetry
- **RISK** - Risk classifications
- **BASE** - Baseline and device info
- **SEC** - Security fields
- **CAP** - Capacity fields
- **UPD** - Update/patch fields
- **DRIFT** - Configuration drift
- **UX** - User experience
- **APP** - Application fields
- **NET** - Network fields
- **TELEMETRY** - Telemetry timestamps

### Server-Specific Prefixes
- **DNS** - DNS Server
- **DHCP** - DHCP Server
- **IIS** - IIS Web Server
- **MSSQL** - SQL Server
- **MYSQL** - MySQL Server
- **FS** - File Server
- **PRINT** - Print Server
- **HV** - Hyper-V Host
- **VEEAM** - Veeam Backup
- **FLEXLM** - FlexLM License

---

## Related Documentation

**Complete Reference:** [Complete_Custom_Fields_Reference.md](Complete_Custom_Fields_Reference.md)  
**Dashboard Usage:** [Dashboard_Templates.md](Dashboard_Templates.md)  
**Alert Thresholds:** [Alert_Configuration_Guide.md](Alert_Configuration_Guide.md)

---

**Total Fields Listed:** 50 most critical  
**Total Fields in Framework:** 277+  
**Last Updated:** February 8, 2026
