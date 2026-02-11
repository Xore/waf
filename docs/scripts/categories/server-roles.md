# Server Role Monitoring

**Complete guide to server role monitoring scripts in the WAF framework.**

---

## Overview

The WAF Server Role Monitoring suite provides 20+ scripts for web servers (IIS/Apache), file/print servers, database servers (SQL/MySQL), and specialized services. Designed for mixed server environments with diverse workloads.

### Script Categories

| Category | Script Count | Primary Focus |
|----------|--------------|---------------|
| Web Servers | 7 | IIS and Apache |
| File & Print Servers | 7 | File shares and printers |
| Database Servers | 4 | SQL Server and MySQL |
| Other Services | 5+ | Exchange, FlexLM, etc. |

**Total:** 20+ scripts | **Complexity:** Intermediate to Advanced

---

## Web Servers

### IIS Scripts

#### IIS-ApplicationPoolMonitor.ps1

**Purpose:** Monitor IIS application pool health.

**NinjaOne Fields:**
```powershell
iis_app_pools_total         # Total pools
iis_app_pools_running       # Running pools
iis_app_pools_stopped       # Stopped pools
iis_app_pools_recycled_24h  # Recycled (24h)
```

**Usage:**
```powershell
.\IIS-ApplicationPoolMonitor.ps1
```

---

#### IIS-GetApplicationPools.ps1

**Purpose:** List all IIS application pools.

**Usage:**
```powershell
.\IIS-GetApplicationPools.ps1
```

---

#### IIS-GetWebsites.ps1

**Purpose:** List all IIS websites.

**Usage:**
```powershell
.\IIS-GetWebsites.ps1
```

---

#### IIS-ManageSite.ps1

**Purpose:** Start/stop IIS sites.

**Usage:**
```powershell
# Start site
.\IIS-ManageSite.ps1 -SiteName "Default Web Site" -Action Start

# Stop site
.\IIS-ManageSite.ps1 -SiteName "MainApp" -Action Stop
```

---

#### IIS-RestartApplicationPool.ps1

**Purpose:** Restart IIS application pools.

**Usage:**
```powershell
.\IIS-RestartApplicationPool.ps1 -PoolName "DefaultAppPool"
```

---

### Apache

#### ApacheWebServerMonitor.ps1

**Purpose:** Apache web server monitoring.

**NinjaOne Fields:**
```powershell
apache_service_status       # Running/Stopped
apache_requests_per_sec     # Request rate
apache_workers_busy         # Busy workers
apache_workers_idle         # Idle workers
```

**Usage:**
```powershell
.\ApacheWebServerMonitor.ps1
```

---

## File & Print Servers

### FileServerMonitor_v1/v2/v3.ps1

**Purpose:** File server health and capacity monitoring.

**v3 Features (Recommended):**
- Share availability
- Permission validation
- Disk capacity
- File count statistics
- Share access monitoring
- Shadow copy status

**NinjaOne Fields:**
```powershell
fs_shares_total             # Total shares
fs_shares_accessible        # Accessible shares
fs_disk_space_gb            # Total space
fs_disk_free_gb             # Free space
fs_disk_used_percent        # Utilization
fs_shadow_copies_enabled    # Shadow copy status
```

**Usage (v3):**
```powershell
.\FileServerMonitor_v3.ps1
```

---

### Print Server Scripts

#### PrintServer-MonitorQueues.ps1

**Purpose:** Monitor print queue status.

**NinjaOne Fields:**
```powershell
ps_printers_total           # Total printers
ps_printers_online          # Online printers
ps_jobs_queued              # Queued jobs
ps_jobs_error               # Jobs in error
```

**Usage:**
```powershell
.\PrintServer-MonitorQueues.ps1
```

---

#### PrintServer-GetPrinters.ps1

**Purpose:** List all printers.

**Usage:**
```powershell
.\PrintServer-GetPrinters.ps1
```

---

#### PrintServer-RestartSpooler.ps1

**Purpose:** Restart print spooler service.

**Usage:**
```powershell
.\PrintServer-RestartSpooler.ps1
```

---

#### PrintServer-Status.ps1

**Purpose:** Print server overall status.

**Usage:**
```powershell
.\PrintServer-Status.ps1
```

---

## Database Servers

### SQL Server

#### SQLServer-CheckStatus.ps1

**Purpose:** SQL Server service and health monitoring.

**NinjaOne Fields:**
```powershell
sql_service_status          # Service status
sql_databases_count         # Database count
sql_databases_online        # Online databases
sql_version                 # SQL Server version
```

**Usage:**
```powershell
.\SQLServer-CheckStatus.ps1
```

---

#### SQLServer-MonitorBackups.ps1

**Purpose:** SQL backup monitoring.

**Usage:**
```powershell
.\SQLServer-MonitorBackups.ps1 -RPOHours 24
```

---

### MySQL

#### MySQL-CheckService.ps1

**Purpose:** MySQL service monitoring.

**Usage:**
```powershell
.\MySQL-CheckService.ps1
```

---

#### MySQL-Monitor.ps1

**Purpose:** MySQL server health monitoring.

**NinjaOne Fields:**
```powershell
mysql_service_status        # Service status
mysql_connections_active    # Active connections
mysql_queries_per_sec       # Query rate
mysql_uptime_hours          # Uptime
```

**Usage:**
```powershell
.\MySQL-Monitor.ps1
```

---

## Other Server Roles

### Exchange-VersionCheck.ps1

**Purpose:** Exchange server version monitoring.

**Usage:**
```powershell
.\Exchange-VersionCheck.ps1
```

---

### FlexLM License Monitor

#### FlexLMLicenseMonitor_v1/v2/v3.ps1

**Purpose:** FlexLM license server monitoring.

**v3 Features:**
- License availability
- License usage
- User checkout tracking
- Server status
- Denial tracking

**NinjaOne Fields:**
```powershell
flexlm_service_status       # Service status
flexlm_licenses_total       # Total licenses
flexlm_licenses_used        # Used licenses
flexlm_licenses_available   # Available licenses
flexlm_denials_24h          # Denials (24h)
```

**Usage (v3):**
```powershell
.\FlexLMLicenseMonitor_v3.ps1 -ServerPort 27000@licserver
```

---

## Best Practices

### Monitoring Frequency

| Service Type | Recommended Interval | Priority |
|--------------|---------------------|----------|
| IIS App Pools | 15 minutes | High |
| File Server | 30 minutes | Medium |
| Print Server | 1 hour | Low |
| SQL Server | 15 minutes | High |
| MySQL | 15 minutes | High |
| FlexLM | 30 minutes | Medium |

### Alert Thresholds

```powershell
# IIS
- App pool stopped: CRITICAL
- Recycled > 5/day: WARNING

# File Server
- Disk > 90%: WARNING
- Disk > 95%: CRITICAL
- Share inaccessible: CRITICAL

# Print Server
- Spooler stopped: CRITICAL
- Jobs in error > 5: WARNING

# Database
- Service stopped: CRITICAL
- Backup age > RPO: WARNING

# FlexLM
- Service down: CRITICAL
- Licenses exhausted: WARNING
- Denials > 10/day: INFO
```

---

**Last Updated:** 2026-02-11  
**Scripts:** 20+  
**Complexity:** Intermediate to Advanced
