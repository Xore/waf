# Windows Automation Framework (WAF)

**Enterprise PowerShell automation framework for Windows infrastructure monitoring, management, and compliance.**

[![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue)]() [![Scripts](https://img.shields.io/badge/scripts-200%2B-orange)]() [![License](https://img.shields.io/badge/license-MIT-green)]()

---

## Overview

Windows Automation Framework (WAF) is a comprehensive collection of 200+ PowerShell scripts for enterprise Windows environments. Designed for scalability, reliability, and NinjaOne RMM integration, WAF provides monitoring, automation, and management across diverse infrastructure components.

### Key Capabilities

- **📊 Comprehensive Monitoring** - Health scoring, stability analysis, performance monitoring, capacity planning, drift detection
- **🖥️ Hyper-V Virtualization** - Complete monitoring suite with 8 enterprise-grade scripts covering health, performance, capacity, cluster, backup, storage
- **🎯 Priority Management** - Device classification (P1-P4) and phased patch deployment (PR1-PR2) for risk-based operations
- **🔒 Security & Compliance** - Threat telemetry, endpoint detection, compliance attestation, security posture monitoring
- **💻 Active Directory** - DC health, replication monitoring, user management, group operations, trust relationships
- **🔧 Server Roles** - DNS, DHCP, IIS, file servers, print servers, Exchange, SQL monitoring
- **💾 System Operations** - Event logs, GPO, services, processes, registry, performance, disk management
- **⚡ Proactive Remediation** - Automated service recovery, emergency cleanup, restart automation

### Platform Integration

**RMM Platform:** NinjaOne  
**Custom Fields:** 100+ defined telemetry fields  
**Alert System:** Configurable thresholds with escalation  
**Dashboard Support:** Pre-configured widgets and reports  

---

## Quick Start

### Prerequisites

- Windows Server 2016+ or Windows 10/11
- PowerShell 5.1 or later
- NinjaOne RMM agent (for full integration)
- Administrator privileges
- Network connectivity for server-role scripts

### Repository Structure

```powershell
# Clone the repository
git clone https://github.com/Xore/waf.git
cd waf

# Review script organization
ls ./plaintext_scripts  # 200+ production scripts
ls ./scripts           # Organized script categories
ls ./docs              # Comprehensive documentation
```

### First Deployment

```powershell
# Review available scripts
Get-ChildItem ./plaintext_scripts -Filter *.ps1

# Deploy a monitoring script
./plaintext_scripts/HealthScoreCalculator.ps1

# Verify custom field population in NinjaOne
```

**Detailed Setup:** See `/docs/getting-started/`

---

## Repository Organization

### `/plaintext_scripts/` - Main Script Library (200+ scripts)

Comprehensive production script collection organized by function:

#### Core Monitoring Frameworks

**Numbered Framework (01-50 Series)**
- Health & Analysis: Health score calculator, stability analyzer, performance analyzer, security analyzer, capacity analyzer, telemetry collector, event log monitor, baseline manager, drift detector, risk classifier
- Server-Specific: DNS server monitor, file server monitor, print server monitor, BitLocker monitor, Hyper-V host monitor, MySQL server monitor, FlexLM license monitor, battery health monitor
- Security & Compliance: Security surface telemetry, collaboration UX telemetry, advanced threat telemetry, endpoint detection response, compliance attestation reporter
- Remediation: Restart print spooler, restart Windows Update, emergency disk cleanup

**Hyper-V Enterprise Suite (8 Scripts)**
- HyperVMonitor.ps1 (31 KB) - Primary monitoring
- HyperVHealthCheck.ps1 (28 KB) - Health validation
- HyperVPerformanceMonitor.ps1 (31 KB) - Performance metrics
- HyperVCapacityPlanner.ps1 (29 KB) - Capacity planning
- HyperVClusterAnalytics.ps1 (28 KB) - Cluster monitoring
- HyperVBackupComplianceMonitor.ps1 (27 KB) - Backup verification
- HyperVStoragePerformanceMonitor.ps1 (32 KB) - Storage metrics
- HyperVMultiHostAggregator.ps1 (23 KB) - Multi-host aggregation

**Priority & Patch Management**
- P1CriticalDeviceValidator.ps1 - Mission-critical device validation
- P2HighPriorityValidator.ps1 - High-importance device validation
- P3P4MediumLowValidator.ps1 - Standard device validation
- PR1PatchRing1Deployment.ps1 - Test ring deployment
- PR2PatchRing2Deployment.ps1 - Production ring deployment

#### Functional Categories

**Active Directory (15+ scripts)**
- Domain controller health and replication
- User/group management and reporting
- OU operations and organizational structure
- Trust relationship maintenance
- Login history and audit trails

**Network Management (20+ scripts)**
- DNS/DHCP operations and monitoring
- Connectivity testing and diagnostics
- Drive mapping and network configuration
- LLDP information and topology
- Public IP detection and routing
- Firewall auditing and SMB configuration

**Hardware Monitoring (10+ scripts)**
- Battery health and charge cycles
- CPU temperature monitoring
- SMART status and SSD wear
- Monitor detection and configuration
- Dell dock information
- USB device alerts

**Server Roles (20+ scripts)**
- IIS web server management
- Print server operations
- File server monitoring
- DNS/DHCP server operations
- Exchange version checking
- Apache/MySQL monitoring
- SQL Server monitoring

**Security & Compliance (15+ scripts)**
- Certificate expiration monitoring
- BitLocker status validation
- LSASS protection verification
- Local admin drift detection
- Firewall status auditing
- Windows licensing validation
- UAC level auditing

**Application-Specific (25+ scripts)**
- Office/Office 365 configuration
- Browser extension management
- OneDrive setup and monitoring
- Outlook profile management
- SAP GUI operations
- Cepros/Diamod integration

**System Operations (30+ scripts)**
- Event log management and search
- GPO updates and monitoring
- Service/process management
- Power management configuration
- Registry operations
- Performance monitoring
- Disk cleanup and optimization

**File Operations (10+ scripts)**
- Robocopy automation
- File distribution to desktops
- URL downloads
- Folder synchronization
- Deletion operations

**Monitoring & Telemetry (15+ scripts)**
- Capacity trend forecasting
- Device uptime tracking
- File modification alerts
- Host file monitoring
- NTP time synchronization
- Performance checks
- Telemetry collection

### `/scripts/` - Organized Categories

Structured script organization by security and functional domains.

### `/docs/` - Documentation Hub

Comprehensive documentation covering:
- Getting started guides
- Script references and catalogs
- Deployment procedures
- Troubleshooting guides
- Best practices
- Standards and conventions

### `/archive/` - Historical Reference

Complete standards documentation and historical files.

---

## Script Patterns & Standards

### V3 Framework Compliance

- **Structured Error Handling** - Try-catch blocks with graceful degradation
- **Consistent Logging** - Severity levels and structured output
- **Custom Field Integration** - NinjaOne field population
- **Naming Conventions** - Predictable naming across all scripts
- **Documentation Headers** - Purpose, requirements, usage examples

### Naming Patterns

1. **Numbered Framework** - Sequential deployment (01-50)
2. **Version Suffixes** - Multiple implementations (v1, v2, v3)
3. **Priority Indicators** - Device classification (P1-P4)
4. **Patch Rings** - Deployment phases (PR1-PR2)
5. **Functional Prefixes** - Category identification (AD-, Network-, Hardware-)

---

## Use Cases

### Enterprise Infrastructure Monitoring
Centralized monitoring across 100+ Windows servers with automated health scoring, capacity planning, trend analysis, and real-time alerting for critical failures.

### Hyper-V Virtualization Management
Comprehensive VM health and performance monitoring, capacity planning for host resources, cluster analytics and failover readiness, backup compliance verification.

### Risk-Based Patch Management
Priority-based device classification (P1-P4), phased deployment with test rings (PR1-PR2), automated validation and rollback, update compliance tracking.

### Active Directory Operations
Domain controller health monitoring, replication status verification, user lifecycle management automation, security group auditing.

### Security & Compliance
Threat detection and endpoint response, compliance attestation reporting, security posture monitoring, certificate lifecycle management.

---

## Documentation

### Core Resources

- **[Getting Started](./docs/getting-started/)** - Setup and deployment
- **[Script Catalog](./docs/scripts/)** - Complete script index
- **[Standards](./docs/standards/)** - Coding and documentation standards
- **[Troubleshooting](./docs/troubleshooting/)** - Common issues and solutions
- **[Best Practices](./docs/reference/)** - Recommended approaches

### Specialized Guides

- **[Hyper-V Monitoring](./docs/hyper-v/)** - Virtualization monitoring suite
- **[Priority System](./docs/reference/)** - P1-P4 device classification
- **[Patch Rings](./docs/reference/)** - PR1-PR2 deployment strategy
- **[Custom Fields](./docs/reference/)** - Field definitions and usage

---

## Contributing

Contributions welcome! Please follow:

1. Fork the repository
2. Create a feature branch
3. Follow V3 coding standards (see `/docs/standards/`)
4. Add comprehensive documentation
5. Test thoroughly in lab environment
6. Submit pull request with detailed description

**Guidelines:** [`CONTRIBUTING.md`](./CONTRIBUTING.md)

---

## Standards & Quality

- **V3 Compliance** - Latest framework standards
- **Error Handling** - Comprehensive try-catch blocks
- **Logging** - Structured severity levels
- **Documentation** - Inline comments and headers
- **Testing** - Lab validation required
- **NinjaOne Integration** - Custom field standards

**Complete Standards:** [`/docs/standards/`](./docs/standards/) and [`/archive/docs/standards/`](./archive/docs/standards/)

---

## Version History

**Current Version:** 3.0  
**Status:** Active Development

**Major Versions:**
- V3 (Current) - Modular architecture, comprehensive error handling, extensive custom fields
- V2 - Enhanced monitoring, NinjaOne integration, structured logging
- V1 - Initial framework, basic monitoring

**Changelog:** [`CHANGELOG.md`](./CHANGELOG.md)

---

## Support

- **Documentation:** [`/docs/`](./docs/)
- **Issues:** [GitHub Issues](https://github.com/Xore/waf/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Xore/waf/discussions)

---

## License

MIT License - see LICENSE file for details

---

**Repository:** [https://github.com/Xore/waf](https://github.com/Xore/waf)  
**Last Updated:** 2026-02-11  
**Maintained by:** Xore  
**Version:** 3.0
