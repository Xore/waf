# WAF Script Catalog

**Complete listing of all Windows Automation Framework scripts.**

---

## Overview

This catalog contains 200+ PowerShell scripts organized by category. Each entry includes the script name, category, primary purpose, and NinjaOne integration status.

**Legend:**
- 📊 **Monitoring** - Collects and reports metrics
- ⚙️ **Automation** - Performs automated actions
- 🛡️ **Security** - Security and compliance checks
- 📝 **Reporting** - Generates reports
- 🔧 **Remediation** - Fixes issues automatically
- ✅ **NinjaOne** - Populates custom fields

---

## Quick Navigation

- [Active Directory (15+)](#active-directory)
- [Network Management (20+)](#network-management)
- [Hardware Monitoring (10+)](#hardware-monitoring)
- [Hyper-V Virtualization (12+)](#hyper-v-virtualization)
- [Server Roles (20+)](#server-roles)
- [Security & Compliance (15+)](#security--compliance)
- [Application Management (25+)](#application-management)
- [System Operations (30+)](#system-operations)
- [File Operations (10+)](#file-operations)
- [Monitoring Frameworks (30+)](#monitoring-frameworks)

---

## Active Directory

### Domain Controller Operations

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| AD-DomainControllerHealthReport.ps1 | 📊📝 | Comprehensive DC health check with replication status | ✅ |
| AD-ReplicationHealthReport.ps1 | 📊📝 | AD replication monitoring and alerting | ✅ |
| AD-Monitor.ps1 | 📊 | Core AD monitoring script | ✅ |
| ActiveDirectoryMonitor.ps1 | 📊 | Alternative AD monitoring implementation | ✅ |

### User & Group Management

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| AD-GetOUMembers.ps1 | 📝 | List all members of specified OU | - |
| AD-GetOrganizationalUnit.ps1 | 📝 | Query OU information and structure | - |
| AD-ModifyUserGroupMembership.ps1 | ⚙️ | Add/remove users from groups | - |
| AD-UserGroupMembershipReport.ps1 | 📝 | Generate user group membership reports | ✅ |
| AD-UserLoginHistoryReport.ps1 | 📝 | Track user login history | ✅ |
| AD-UserLogonHistory.ps1 | 📝 | Alternative login history implementation | ✅ |
| AD-LockedOutUserReport.ps1 | 📊📝 | Report on locked user accounts | ✅ |

### Domain Operations

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| AD-JoinComputerToDomain.ps1 | ⚙️ | Automated domain join with validation | - |
| AD-JoinDomain.ps1 | ⚙️ | Simple domain join operation | - |
| AD-RemoveComputerFromDomain.ps1 | ⚙️ | Remove computer from domain safely | - |
| AD-RepairTrust.ps1 | 🔧 | Repair broken trust relationships | - |

---

## Network Management

### DNS Operations

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| DNSServerMonitor_v1.ps1 | 📊 | Basic DNS server monitoring | ✅ |
| DNSServerMonitor_v2.ps1 | 📊 | Enhanced DNS monitoring | ✅ |
| DNSServerMonitor_v3.ps1 | 📊 | Advanced DNS monitoring with alerting | ✅ |

### DHCP Operations

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| DHCPServerMonitor.ps1 | 📊 | DHCP server health and scope monitoring | ✅ |
| DHCP-AlertOnLeaseLow.ps1 | 📊 | Alert when DHCP leases running low | ✅ |
| DHCP-FindRogueServersNmap.ps1 | 🛡️ | Detect unauthorized DHCP servers | ✅ |

### Network Diagnostics

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Network-CheckIPConfig.ps1 | 📊 | Verify network configuration | ✅ |
| Network-DriveMapping.ps1 | ⚙️ | Manage network drive mappings | - |
| Network-GetPublicIP.ps1 | 📊 | Retrieve public IP address | ✅ |
| Network-LLDPInformation.ps1 | 📝 | Collect LLDP topology information | ✅ |
| Network-ManageSMB.ps1 | ⚙️ | SMB protocol management | - |
| Network-TestConnectivity.ps1 | 📊 | Network connectivity testing | - |
| Network-TracerouteWithGeolocation.ps1 | 📝 | Enhanced traceroute with geo data | - |

---

## Hardware Monitoring

### Battery & Power

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| BatteryHealthMonitor.ps1 | 📊 | Basic battery health check | ✅ |
| BatteryHealthMonitor_v2.ps1 | 📊 | Advanced battery monitoring with history | ✅ |
| Hardware-CheckBatteryHealth.ps1 | 📊 | Comprehensive battery health analysis | ✅ |

### System Hardware

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Hardware-GetAttachedMonitors.ps1 | 📝 | Detect and report monitor information | ✅ |
| Hardware-GetCPUTemp.ps1 | 📊 | CPU temperature monitoring | ✅ |
| Hardware-GetDellDockInfo.ps1 | 📝 | Dell docking station information | ✅ |
| Hardware-SSDWearHealthAlert.ps1 | 📊 | SSD wear level monitoring | ✅ |
| Hardware-USBDriveAlert.ps1 | 🛡️ | Alert on USB drive insertion | ✅ |
| Disk-GetSMARTStatus.ps1 | 📊 | SMART disk health monitoring | ✅ |

---

## Hyper-V Virtualization

### Core Monitoring Suite

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| HyperVMonitor.ps1 | 📊 | Primary Hyper-V monitoring (31 KB) | ✅ |
| HyperVHealthCheck.ps1 | 📊 | Comprehensive health validation (28 KB) | ✅ |
| HyperVPerformanceMonitor.ps1 | 📊 | Performance metrics collection (31 KB) | ✅ |
| HyperVCapacityPlanner.ps1 | 📝 | Capacity planning analysis (29 KB) | ✅ |
| HyperVClusterAnalytics.ps1 | 📊 | Cluster monitoring and analytics (28 KB) | ✅ |
| HyperVBackupComplianceMonitor.ps1 | 📊 | Backup compliance verification (27 KB) | ✅ |
| HyperVStoragePerformanceMonitor.ps1 | 📊 | Storage performance metrics (32 KB) | ✅ |
| HyperVMultiHostAggregator.ps1 | 📊 | Multi-host aggregation (23 KB) | ✅ |

### VM Operations

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| HyperV-CheckpointExpirationAlert.ps1 | 📊 | Alert on old VM checkpoints | ✅ |
| HyperV-GetHostFromGuest.ps1 | 📝 | Identify host from guest VM | - |
| HyperV-ReplicationAlert.ps1 | 📊 | Monitor VM replication status | ✅ |
| HyperVHostMonitor_v1.ps1 | 📊 | Basic host monitoring | ✅ |

---

## Server Roles

### Web Servers

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| IIS-ApplicationPoolMonitor.ps1 | 📊 | IIS application pool monitoring | ✅ |
| IIS-GetApplicationPools.ps1 | 📝 | List IIS application pools | - |
| IIS-GetWebsites.ps1 | 📝 | List IIS websites | - |
| IIS-ManageSite.ps1 | ⚙️ | Manage IIS sites (start/stop) | - |
| IIS-RestartApplicationPool.ps1 | 🔧 | Restart IIS app pools | - |
| ApacheWebServerMonitor.ps1 | 📊 | Apache web server monitoring | ✅ |

### File & Print Servers

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| FileServerMonitor_v1.ps1 | 📊 | Basic file server monitoring | ✅ |
| FileServerMonitor_v2.ps1 | 📊 | Enhanced file server monitoring | ✅ |
| FileServerMonitor_v3.ps1 | 📊 | Advanced file server monitoring | ✅ |
| PrintServer-GetPrinters.ps1 | 📝 | List all printers on print server | - |
| PrintServer-MonitorQueues.ps1 | 📊 | Monitor print queues | ✅ |
| PrintServer-RestartSpooler.ps1 | 🔧 | Restart print spooler service | - |
| PrintServer-Status.ps1 | 📊 | Print server status monitoring | ✅ |

### Database Servers

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| MySQL-CheckService.ps1 | 📊 | MySQL service monitoring | ✅ |
| MySQL-Monitor.ps1 | 📊 | MySQL server health monitoring | ✅ |
| SQLServer-CheckStatus.ps1 | 📊 | SQL Server status monitoring | ✅ |
| SQLServer-MonitorBackups.ps1 | 📊 | SQL backup monitoring | ✅ |

### Other Server Roles

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Exchange-VersionCheck.ps1 | 📊 | Exchange server version monitoring | ✅ |
| FlexLMLicenseMonitor_v1.ps1 | 📊 | FlexLM license server monitoring | ✅ |
| FlexLMLicenseMonitor_v2.ps1 | 📊 | Enhanced FlexLM monitoring | ✅ |
| FlexLMLicenseMonitor_v3.ps1 | 📊 | Advanced FlexLM monitoring | ✅ |

---

## Security & Compliance

### Encryption & Protection

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| BitLockerMonitor_v1.ps1 | 🛡️ | Basic BitLocker status monitoring | ✅ |
| BitLockerMonitor_v2.ps1 | 🛡️ | Enhanced BitLocker monitoring | ✅ |

### Certificate Management

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Certificates-GetExpiring.ps1 | 📊 | Monitor expiring certificates | ✅ |
| Certificates-LocalExpirationAlert.ps1 | 📊 | Local cert expiration alerts | ✅ |

### Firewall & Network Security

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Firewall-AuditStatus.ps1 | 🛡️ | Windows Firewall audit | ✅ |
| Firewall-AuditStatus2.ps1 | 🛡️ | Enhanced firewall auditing | ✅ |

### Threat Detection

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| AdvancedThreatTelemetry.ps1 | 🛡️ | Advanced threat detection metrics | ✅ |
| EndpointDetectionResponse.ps1 | 🛡️ | EDR-style endpoint monitoring | ✅ |
| SecuritySurfaceTelemetry.ps1 | 🛡️ | Security posture telemetry | ✅ |

### Compliance

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| ComplianceAttestationReporter.ps1 | 📝 | Compliance status reporting | ✅ |
| Entra-Audit.ps1 | 🛡️ | Entra ID audit logging | ✅ |
| Licensing-UnlicensedWindowsAlert.ps1 | 📊 | Windows licensing compliance | ✅ |

---

## Application Management

### Microsoft Office

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Office-GetVersion.ps1 | 📝 | Office version detection | ✅ |
| Office-VersionMonitor.ps1 | 📊 | Office version monitoring | ✅ |
| Office365-CheckActivation.ps1 | 📊 | M365 activation status | ✅ |
| Outlook-ConfigureProfile.ps1 | ⚙️ | Automated Outlook profile setup | - |
| Outlook-ManageProfiles.ps1 | ⚙️ | Outlook profile management | - |
| CollaborationOutlookUXTelemetry.ps1 | 📊 | Outlook UX metrics | ✅ |

### OneDrive

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| OneDrive-CheckStatus.ps1 | 📊 | OneDrive sync status | ✅ |
| OneDrive-Configure.ps1 | ⚙️ | OneDrive configuration | - |
| OneDrive-InstallPerUser.ps1 | ⚙️ | Per-user OneDrive installation | - |

### Browsers

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Browser-ListExtensions.ps1 | 📝 | List browser extensions (36 KB) | ✅ |
| Explorer-SetDefaultFiletypeAssociations.ps1 | ⚙️ | Set default file associations | - |
| Explorer-SetShowHiddenFiles.ps1 | ⚙️ | Configure hidden files visibility | - |

### Application-Specific

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| BDE-StartSAPandBrowser.ps1 | ⚙️ | Launch SAP GUI and browser | - |
| Cepros-FixCdbpcIniPermissions.ps1 | 🔧 | Fix Cepros permissions | - |
| Cepros-UpdateCDBServerURL.ps1 | ⚙️ | Update Cepros server URL | - |
| Diamod-ReregisterServerFixPermissions.ps1 | 🔧 | Fix Diamod permissions | - |
| ApplicationExperienceProfiler.ps1 | 📊 | Application performance profiling | ✅ |

---

## System Operations

### Event Log Management

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| EventLogMonitor_v1.ps1 | 📊 | Basic event log monitoring | ✅ |
| EventLogMonitor_v2.ps1 | 📊 | Advanced event log monitoring | ✅ |
| EventLog-BackupToLocalDisk.ps1 | ⚙️ | Backup event logs locally | - |
| EventLog-Optimize.ps1 | 🔧 | Optimize event log sizes | - |
| EventLog-Search.ps1 | 📝 | Search event logs | - |

### Group Policy

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| GPO-Monitor.ps1 | 📊 | Group Policy monitoring | ✅ |
| GPO-UpdateAndReport.ps1 | ⚙️📝 | Update GPO and report | ✅ |
| GroupPolicyMonitor.ps1 | 📊 | Alternative GPO monitoring | ✅ |

### Service & Process Management

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Service-GetStatus.ps1 | 📝 | Service status reporting | - |
| Service-Restart.ps1 | 🔧 | Service restart automation | - |
| Process-Monitor.ps1 | 📊 | Process monitoring | ✅ |
| Process-Terminate.ps1 | 🔧 | Process termination | - |

### Disk & Storage

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| EmergencyDiskCleanup.ps1 | 🔧 | Emergency disk space recovery | - |
| Storage-CapacityForecasting.ps1 | 📝 | Disk capacity trend analysis | ✅ |
| Storage-GetDiskSpace.ps1 | 📊 | Disk space monitoring | ✅ |

### Performance

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Performance-CheckCPUMemory.ps1 | 📊 | CPU and memory monitoring | ✅ |
| Performance-GetBaseline.ps1 | 📝 | Establish performance baseline | ✅ |
| PerformanceAnalyzer.ps1 | 📊 | Comprehensive performance analysis | ✅ |

### System Configuration

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| Device-UpdateLocation.ps1 | ⚙️ | Update device location in RMM | ✅ |
| Power-ConfigureSettings.ps1 | ⚙️ | Power management configuration | - |
| Registry-Backup.ps1 | ⚙️ | Registry backup automation | - |
| Time-SyncNTP.ps1 | ⚙️ | NTP time synchronization | - |
| UAC-AuditLevel.ps1 | 🛡️ | UAC level auditing | ✅ |

---

## File Operations

### File Management

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| FileOps-CopyFileToAllDesktops.ps1 | ⚙️ | Distribute file to all user desktops | - |
| FileOps-CopyFileToFolder.ps1 | ⚙️ | Copy file to specified location | - |
| FileOps-CopyFolderRobocopy.ps1 | ⚙️ | Robust folder copy with Robocopy | - |
| FileOps-DeleteFileOrFolder.ps1 | ⚙️ | Delete files or folders | - |
| FileOps-DownloadFromURL.ps1 | ⚙️ | Download files from URLs (22 KB) | - |

### File Monitoring

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| FileModification-Monitor.ps1 | 📊 | Monitor file modifications | ✅ |
| HostFile-Monitor.ps1 | 🛡️ | Monitor hosts file changes | ✅ |

---

## Monitoring Frameworks

### Core Framework (Numbered Series)

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| 01-HealthScoreCalculator.ps1 | 📊 | Overall system health scoring | ✅ |
| 02-StabilityAnalyzer.ps1 | 📊 | System stability metrics | ✅ |
| 03-PerformanceAnalyzer.ps1 | 📊 | Performance analysis | ✅ |
| 04-SecurityAnalyzer.ps1 | 🛡️ | Security posture analysis | ✅ |
| 05-CapacityAnalyzer.ps1 | 📝 | Capacity planning | ✅ |
| HealthScoreCalculator.ps1 | 📊 | Standalone health calculator | ✅ |
| StabilityAnalyzer.ps1 | 📊 | Standalone stability analyzer | ✅ |
| CapacityAnalyzer.ps1 | 📊 | Standalone capacity analyzer | ✅ |
| BaselineManager.ps1 | 📊 | Baseline establishment and comparison | ✅ |
| DriftDetector.ps1 | 📊 | Configuration drift detection | ✅ |

### Priority & Patch Management

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| P1CriticalDeviceValidator.ps1 | 📊 | Validate P1 (critical) devices | ✅ |
| P2HighPriorityValidator.ps1 | 📊 | Validate P2 (high) devices | ✅ |
| P3P4MediumLowValidator.ps1 | 📊 | Validate P3/P4 devices | ✅ |
| PR1PatchRing1Deployment.ps1 | ⚙️ | Patch Ring 1 (test) deployment | ✅ |
| PR2PatchRing2Deployment.ps1 | ⚙️ | Patch Ring 2 (production) deployment | ✅ |

### Telemetry Collection

| Script | Type | Purpose | NinjaOne |
|--------|------|---------|----------|
| TelemetryCollector.ps1 | 📊 | Comprehensive telemetry collection | ✅ |
| Uptime-Monitor.ps1 | 📊 | System uptime tracking | ✅ |

---

## Statistics

### By Category

| Category | Script Count |
|----------|-------------|
| Active Directory | 15+ |
| Network Management | 20+ |
| Hardware Monitoring | 10+ |
| Hyper-V Virtualization | 12+ |
| Server Roles | 20+ |
| Security & Compliance | 15+ |
| Application Management | 25+ |
| System Operations | 30+ |
| File Operations | 10+ |
| Monitoring Frameworks | 30+ |
| **TOTAL** | **200+** |

### By Type

| Type | Count | Percentage |
|------|-------|------------|
| 📊 Monitoring | 120+ | 60% |
| ⚙️ Automation | 40+ | 20% |
| 📝 Reporting | 30+ | 15% |
| 🛡️ Security | 20+ | 10% |
| 🔧 Remediation | 15+ | 7% |

### NinjaOne Integration

- **Scripts with NinjaOne integration:** 150+
- **Scripts without integration:** 50+
- **Integration rate:** ~75%

---

## Usage Examples

### Finding Scripts by Category

```powershell
# List all Active Directory scripts
Get-ChildItem ./plaintext_scripts -Filter "AD-*.ps1"

# List all monitoring scripts
Get-ChildItem ./plaintext_scripts -Filter "*Monitor*.ps1"

# List all Hyper-V scripts
Get-ChildItem ./plaintext_scripts -Filter "HyperV*.ps1"
```

### Finding Scripts by Purpose

```powershell
# Find security-related scripts
Get-ChildItem ./plaintext_scripts | Where-Object {
    $_.Name -match "Security|BitLocker|Firewall|Certificate"
}

# Find remediation scripts
Get-ChildItem ./plaintext_scripts | Where-Object {
    $_.Name -match "Restart|Fix|Repair|Emergency"
}
```

---

## Related Documentation

- **[Getting Started Guide](/docs/GETTING_STARTED.md)** - Setup and deployment
- **[Category Guides](/docs/scripts/categories/)** - Detailed category documentation
- **[Coding Standards](/docs/standards/CODING_STANDARDS.md)** - Development standards

---

**Last Updated:** 2026-02-11  
**Total Scripts:** 200+  
**Repository:** [github.com/Xore/waf](https://github.com/Xore/waf)
