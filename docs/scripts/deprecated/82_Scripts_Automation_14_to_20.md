# Script Conditions & Automation - Server Monitoring Scripts 14-20
**Document:** 57_Script_Conditions_Automation_Scripts_14_20.md  
**Version:** 4.0  
**Last Updated:** February 2, 2026  
**Scripts Covered:** 14-20 (Server Role Monitoring)

---

## OVERVIEW

This document provides NinjaRMM automation policies, conditions, and scheduling for Scripts 14-20.
These scripts monitor server-specific roles and should only execute on devices with those roles installed.

**Design Philosophy:** Scripts self-detect roles and exit gracefully if not applicable. Optional conditions can reduce unnecessary executions.

---

## SCRIPT EXECUTION MATRIX

| Script | Name | Frequency | Target Devices | Self-Detection | Recommended Condition |
|--------|------|-----------|----------------|----------------|----------------------|
| 14 | DNS Server Monitor | 4 hours | DNS servers | Yes | Optional: Server OS |
| 15 | File Server Monitor | 4 hours | File servers | Yes | Optional: Server OS |
| 16 | Print Server Monitor | 4 hours | Print servers | Yes | Optional: Server OS |
| 17 | BitLocker Monitor | Daily | All devices | Yes | None (run everywhere) |
| 18 | Hyper-V Host Monitor | 4 hours | Hyper-V hosts | Yes | Optional: Server OS |
| 19 | MySQL Server Monitor | 4 hours | MySQL servers | Yes | Optional: Custom tag |
| 20 | FlexLM License Monitor | 4 hours | License servers | Yes | Optional: Custom tag |

---

## SCRIPT 14: DNS Server Monitor

### Scheduling
- **Frequency:** Every 4 hours
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Recommended Conditions
**Option 1: No Condition (Recommended)**
- Script self-detects DNS role
- Exits gracefully if not found
- No false positives

**Option 2: OS Condition**
```
IF Operating System contains "Server"
THEN Run Script 14
```

**Option 3: Custom Field Condition**
```
IF dnsServerInstalled = TRUE
THEN Run Script 14
```
Note: Requires initial run to populate field (chicken-and-egg problem)

### Detection Logic
Script checks:
1. `Get-WindowsFeature -Name DNS`
2. If not installed: Sets `dnsServerInstalled = false`, exits 0
3. If installed: Continues monitoring

---

## SCRIPT 15: File Server Monitor

### Scheduling
- **Frequency:** Every 4 hours
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Recommended Conditions
**Option 1: No Condition (Recommended)**
- Script self-detects File Server role
- Minimal overhead on non-file servers

**Option 2: OS Condition**
```
IF Operating System contains "Server"
THEN Run Script 15
```

### Detection Logic
Script checks:
1. `Get-WindowsFeature -Name FS-FileServer`
2. If not installed: Sets `fileServerInstalled = false`, exits 0
3. If installed: Monitors shares and connections

---

## SCRIPT 16: Print Server Monitor

### Scheduling
- **Frequency:** Every 4 hours
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Recommended Conditions
**Option 1: No Condition (Recommended)**
- Script self-detects Print Services role
- Quick exit if not applicable

**Option 2: OS Condition**
```
IF Operating System contains "Server"
THEN Run Script 16
```

### Detection Logic
Script checks:
1. `Get-WindowsFeature -Name Print-Services`
2. If not installed: Sets `printServerInstalled = false`, exits 0
3. If installed: Monitors printers and queues

---

## SCRIPT 17: BitLocker Monitor

### Scheduling
- **Frequency:** Daily (00:00-06:00)
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

### Recommended Conditions
**No Condition Required**
- Run on ALL devices (workstations and servers)
- BitLocker applicable to all Windows editions
- Security compliance monitoring

### Detection Logic
Script checks:
1. `Get-BitLockerVolume`
2. If not available: Sets `bitlockerEnabled = false`, exits 0
3. If available: Monitors encryption status

### Use Cases
- Endpoint encryption compliance
- Server drive encryption monitoring
- Regulatory compliance (HIPAA, PCI-DSS, etc.)

---

## SCRIPT 18: Hyper-V Host Monitor

### Scheduling
- **Frequency:** Every 4 hours
- **Runtime:** ~40 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Recommended Conditions
**Option 1: No Condition (Recommended)**
- Script self-detects Hyper-V role
- Minimal overhead on non-Hyper-V servers

**Option 2: OS Condition**
```
IF Operating System contains "Server"
THEN Run Script 18
```

**Option 3: Role Tag Condition**
```
IF Device Role Tag = "Hyper-V Host"
THEN Run Script 18
```

### Detection Logic
Script checks:
1. `Get-WindowsFeature -Name Hyper-V`
2. If not installed: Sets `hvHyperVInstalled = false`, exits 0
3. If installed: Monitors VMs, resources, replication

---

## SCRIPT 19: MySQL Server Monitor

### Scheduling
- **Frequency:** Every 4 hours
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Recommended Conditions
**Option 1: Device Role Tag**
```
IF Device Role Tag = "Database Server"
OR Device Role Tag = "MySQL Server"
THEN Run Script 19
```

**Option 2: No Condition**
- Script self-detects MySQL/MariaDB service
- Quick exit if not found

### Detection Logic
Script checks:
1. `Get-Service -Name 'MySQL*','MariaDB*'`
2. If not found: Sets `mysqlInstalled = false`, exits 0
3. If found: Monitors databases, replication, performance

### Configuration Required
**IMPORTANT:** Update script with MySQL connection parameters:
- MySQL binary path (default: `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`)
- Username (default: `root`)
- Password (use secure credential management)

---

## SCRIPT 20: FlexLM License Monitor

### Scheduling
- **Frequency:** Every 4 hours
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

### Recommended Conditions
**Option 1: Device Role Tag**
```
IF Device Role Tag = "License Server"
OR Device Role Tag = "FlexLM Server"
THEN Run Script 20
```

**Option 2: No Condition**
- Script self-detects FlexLM installation
- Quick exit if not found

### Detection Logic
Script checks:
1. Tests for `lmutil.exe` in common FlexLM paths
2. If not found: Sets `flexlmInstalled = false`, exits 0
3. If found: Monitors licenses, daemons, utilization

### Configuration Required
**IMPORTANT:** Update script with FlexLM paths:
- FlexLM installation path (default: `C:\FlexLM`)
- License file path (default: `C:\FlexLM\license.dat`)
- Adjust paths based on your deployment

---

## AUTOMATION POLICIES

### Policy 1: Server Role Monitoring (Scripts 14-16, 18)
**Target:** All Windows Servers  
**Schedule:** Every 4 hours  
**Scripts:** 14, 15, 16, 18  
**Condition:**
```
IF Operating System contains "Server"
THEN Run Scripts 14, 15, 16, 18
```

### Policy 2: BitLocker Compliance (Script 17)
**Target:** All Windows devices  
**Schedule:** Daily (02:00 AM)  
**Scripts:** 17  
**Condition:** None (run on all devices)

### Policy 3: Database Servers (Script 19)
**Target:** Tagged database servers  
**Schedule:** Every 4 hours  
**Scripts:** 19  
**Condition:**
```
IF Device Role Tag contains "Database"
OR Device Role Tag contains "MySQL"
THEN Run Script 19
```

### Policy 4: License Servers (Script 20)
**Target:** Tagged license servers  
**Schedule:** Every 4 hours  
**Scripts:** 20  
**Condition:**
```
IF Device Role Tag = "License Server"
THEN Run Script 20
```

---

## DEVICE ROLE TAGGING

### Recommended Tags
Create these device role tags in NinjaRMM:

**Server Roles:**
- `DNS Server`
- `File Server`
- `Print Server`
- `Hyper-V Host`
- `Database Server`
- `MySQL Server`
- `License Server`
- `FlexLM Server`

### Tagging Strategy
**Option 1: Manual Tagging**
- Tag devices during onboarding
- Update tags when roles change

**Option 2: Automated Tagging**
- Use Script 20 (Server Role Identifier) output
- Create automation rules based on custom fields
- Example: If `dnsServerInstalled = true`, add tag "DNS Server"

---

## CONDITION BEST PRACTICES

### When to Use Conditions
**Use conditions when:**
- You have many devices (> 500)
- You want to reduce script execution overhead
- You have clear device tagging/categorization
- You want centralized policy management

**Skip conditions when:**
- You have few devices (< 100)
- Scripts have efficient self-detection
- You want zero-configuration deployment
- You prefer script-level intelligence

### Performance Considerations
**Script Execution Overhead:**
- Self-detection check: 1-2 seconds
- Graceful exit: < 1 second
- Network impact: Minimal (local checks only)

**Recommendation:** For Scripts 14-18, rely on self-detection. Only use conditions for Scripts 19-20 if you have dedicated database/license servers.

---

## SCHEDULING RECOMMENDATIONS

### 4-Hour Monitoring (Scripts 14-16, 18-20)
**Execution Times:**
- 00:00, 04:00, 08:00, 12:00, 16:00, 20:00

**Why 4 hours?**
- Balances freshness vs. overhead
- Server metrics change slowly
- Aligns with endpoint monitoring (Scripts 1-6)

### Daily Monitoring (Script 17)
**Execution Time:**
- 02:00 AM (low-activity window)

**Why daily?**
- BitLocker status rarely changes
- Security posture monitoring
- Compliance reporting (daily snapshots)

### Staggered Execution
If running multiple scripts, stagger execution:
- 00:00: Script 14 (DNS)
- 00:15: Script 15 (File)
- 00:30: Script 16 (Print)
- 00:45: Script 18 (Hyper-V)
- 01:00: Script 19 (MySQL)
- 01:15: Script 20 (FlexLM)
- 02:00: Script 17 (BitLocker)

---

## MONITORING ALERTS

### Recommended Conditions for Alerts

**DNS Server Critical:**
```
IF dnsHealthStatus = "Critical"
THEN Alert: DNS Server Down
```

**File Server Warning:**
```
IF fileActiveConnections > 1000
OR fileHealthStatus = "Warning"
THEN Alert: File Server High Load
```

**Print Server Critical:**
```
IF printQueuedJobs > 50
OR printHealthStatus = "Critical"
THEN Alert: Print Server Queue Jam
```

**BitLocker Non-Compliant:**
```
IF bitlockerEnabled = TRUE
AND bitlockerProtectedVolumes < bitlockerVolumeCount
THEN Alert: BitLocker Incomplete Encryption
```

**Hyper-V Critical:**
```
IF hvReplicationHealthIssues > 0
OR hvHealthStatus = "Critical"
THEN Alert: Hyper-V Replication Failed
```

**MySQL Critical:**
```
IF mysqlReplicationStatus = "Error"
OR mysqlHealthStatus = "Critical"
THEN Alert: MySQL Replication Broken
```

**FlexLM Critical:**
```
IF flexlmDaemonsDown > 0
OR flexlmLicenseUtilizationPercent > 95
THEN Alert: License Server Critical
```

---

## DEPLOYMENT CHECKLIST

### Pre-Deployment
- [ ] Create all 60 custom fields (see document 56)
- [ ] Configure dropdown values
- [ ] Create device role tags (optional)
- [ ] Review and customize MySQL connection settings (Script 19)
- [ ] Review and customize FlexLM paths (Script 20)

### Deployment
- [ ] Upload Scripts 14-20 to NinjaRMM
- [ ] Create automation policies (or skip for self-detection)
- [ ] Set execution schedules (4-hour or daily)
- [ ] Configure timeout values (90 seconds)
- [ ] Assign policies to device groups

### Post-Deployment
- [ ] Monitor first execution results
- [ ] Verify custom fields populate correctly
- [ ] Check for script errors on non-applicable devices
- [ ] Configure alerting conditions
- [ ] Create dashboards for server monitoring

### Testing
- [ ] Test Script 14 on DNS server
- [ ] Test Script 15 on File server
- [ ] Test Script 16 on Print server
- [ ] Test Script 17 on workstation and server
- [ ] Test Script 18 on Hyper-V host
- [ ] Test Script 19 on MySQL server (after config)
- [ ] Test Script 20 on FlexLM server (after config)
- [ ] Verify graceful exits on non-applicable devices

---

## TROUBLESHOOTING

### Script Execution Issues
**Problem:** Script times out on large Hyper-V hosts  
**Solution:** Increase timeout to 120 seconds for Script 18

**Problem:** MySQL script fails with connection error  
**Solution:** Verify MySQL binary path and credentials in Script 19

**Problem:** FlexLM script doesn't find lmutil.exe  
**Solution:** Update `$flexlmPaths` array in Script 20 with correct path

### Detection Issues
**Problem:** Script runs on non-applicable devices  
**Solution:** Scripts are designed to handle this. Verify exit code is 0 (success) on non-applicable devices

**Problem:** Custom field not updating  
**Solution:** Check script execution history for errors. Verify custom field exists and has correct name.

### Performance Issues
**Problem:** Too many script executions  
**Solution:** Add OS-level conditions (`Operating System contains "Server"`) to reduce executions

---

**Version:** 4.0  
**Status:** Production Ready  
**Scripts:** 14-20  
**Last Updated:** February 2, 2026
