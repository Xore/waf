# Windows Automation Framework (WAF)

**Enterprise-grade PowerShell automation framework for Windows infrastructure monitoring, management, and compliance.**

[![Framework Version](https://img.shields.io/badge/version-3.0-blue)]() [![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue)]() [![License](https://img.shields.io/badge/license-MIT-green)]() [![Scripts](https://img.shields.io/badge/scripts-250%2B-orange)]()

---

## Overview

The Windows Automation Framework (WAF) is a comprehensive collection of 250+ PowerShell scripts designed for enterprise Windows environments. Built with scalability, reliability, and maintainability in mind, WAF provides monitoring, automation, and management capabilities across diverse infrastructure components.

### Key Features

- **📊 Comprehensive Monitoring** - 40+ numbered monitoring scripts (01-50 series) covering health, performance, security, and capacity
- **🖥️ Hyper-V Virtualization** - Enterprise-grade monitoring suite with 8 specialized scripts for virtualization infrastructure
- **🎯 Priority-Based Management** - Device classification system (P1-P4) for risk-based operations
- **🔄 Patch Ring Deployment** - Phased patching strategy (PR1-PR2) with automated validation
- **🔒 Security & Compliance** - Advanced threat detection, compliance attestation, and security posture monitoring
- **🛠️ Active Directory Integration** - Complete AD operations including health, replication, and user management
- **💻 Server Role Monitoring** - Specialized monitoring for DNS, DHCP, IIS, file servers, print servers, and more
- **⚡ Automated Remediation** - Proactive remediation engine with automated service recovery

### Integration

**Primary Platform:** NinjaOne RMM  
**Custom Fields:** 100+ defined fields for comprehensive telemetry  
**Alert System:** Configurable thresholds with cascade notifications  
**Dashboard Support:** Pre-configured widgets and reporting templates  

---

## Quick Start

### Prerequisites

- Windows Server 2016+ or Windows 10/11
- PowerShell 5.1 or later
- NinjaOne RMM agent (for full integration)
- Administrator privileges for most scripts
- Network connectivity for server-role scripts

### Basic Deployment

```powershell
# 1. Clone the repository
git clone https://github.com/Xore/waf.git
cd waf

# 2. Review script requirements
Get-Content ./docs/getting-started/quickstart.md

# 3. Deploy your first monitoring script
./scripts/01_Health_Score_Calculator.ps1

# 4. Verify custom field population in NinjaOne
```

**For detailed setup instructions:** See [`/docs/getting-started/`](./docs/getting-started/)

---

## Architecture

WAF follows a modular, standards-compliant architecture organized into functional tracks:

### Script Organization

```
waf/
├── scripts/                  # 47 production scripts (categorized)
├── plaintext_scripts/        # 200+ scripts (various patterns)
│   ├── 01-50 series          # Numbered monitoring framework
│   ├── P1-P4 validators      # Priority classification
│   ├── PR1-PR2 deployment    # Patch ring system
│   └── Legacy scripts        # AD, Network, Hardware, etc.
├── hyper-v monitoring/       # 8 enterprise Hyper-V scripts
└── docs/                     # Comprehensive documentation
```

### Monitoring Framework (01-50 Series)

**Health & Analysis (01-13)** - Core health metrics, stability, performance, and capacity  
**Server-Specific (14-21)** - DNS, file servers, print servers, Hyper-V, MySQL, licenses  
**Security & Compliance (28-32)** - Threat detection, endpoint response, compliance attestation  
**Remediation (41-50)** - Automated service recovery and emergency cleanup  

**For complete architecture:** See [`FRAMEWORK_ARCHITECTURE.md`](./FRAMEWORK_ARCHITECTURE.md)

---

## Documentation

### Core Documentation

- **[Getting Started Guide](./docs/getting-started/)** - Setup, deployment, and first steps
- **[Framework Architecture](./FRAMEWORK_ARCHITECTURE.md)** - Technical design and patterns
- **[Script Catalog](./docs/scripts/catalog.md)** - Complete index of all 250+ scripts
- **[Contributing Guidelines](./CONTRIBUTING.md)** - How to contribute to WAF
- **[Changelog](./CHANGELOG.md)** - Version history and updates

### Specialized Documentation

- **[Hyper-V Monitoring Suite](./docs/hyper-v/)** - Enterprise virtualization monitoring
- **[Numbered Framework Guide](./docs/scripts/numbered-framework.md)** - 01-50 series documentation
- **[Priority System](./docs/reference/priority-system.md)** - P1-P4 device classification
- **[Patch Ring Strategy](./docs/reference/patch-rings.md)** - PR1-PR2 deployment methodology
- **[Standards Reference](./docs/standards/)** - Coding standards and best practices

### Quick References

- **[Troubleshooting Guide](./docs/troubleshooting/)** - Common issues and solutions
- **[Best Practices](./docs/reference/best-practices.md)** - Recommended patterns and approaches
- **[Quick Reference Cards](./docs/quick-reference/)** - One-page guides by category
- **[Custom Fields Reference](./docs/reference/custom-fields.md)** - All 100+ custom fields documented

---

## Script Categories

### Active Directory (15+ scripts)
Domain controller health, replication monitoring, user management, OU operations, trust relationships, group membership tracking, login history analysis

### Network Management (20+ scripts)
DNS/DHCP monitoring, connectivity testing, public IP detection, drive mapping, LLDP information, firewall auditing, SMB configuration

### Hardware Monitoring (10+ scripts)
Battery health, CPU temperature, SMART status, SSD wear monitoring, monitor detection, Dell dock information, USB device alerts

### Application-Specific (25+ scripts)
Office/Office 365 configuration, browser extensions, OneDrive setup, Outlook profiles, SAP/Cepros/Diamod operations

### Security & Compliance (15+ scripts)
Certificate expiration, BitLocker status, LSASS protection, local admin monitoring, firewall auditing, license validation

### Server Roles (20+ scripts)
IIS management, print servers, file servers, DNS operations, DHCP monitoring, Hyper-V operations, Exchange version checks

### System Operations (30+ scripts)
Event log management, GPO updates, performance monitoring, power management, process/service management, registry operations, disk cleanup

### File Operations (10+ scripts)
Copy/move/delete automation, Robocopy integration, URL downloads, desktop file distribution

### Monitoring & Telemetry (15+ scripts)
Capacity forecasting, uptime tracking, file modification alerts, host file monitoring, NTP sync, performance checks, telemetry collection

---

## Standards & Quality

WAF adheres to comprehensive coding and documentation standards:

- **V3 Compliance Framework** - Latest standards for script structure, error handling, and logging
- **Consistent Naming Conventions** - Predictable file names and function naming
- **Custom Field Standards** - Structured naming and data type conventions
- **Error Handling Requirements** - Try-catch blocks, graceful degradation, meaningful error messages
- **Logging Standards** - Structured logging with severity levels
- **Documentation Requirements** - Inline comments, header blocks, usage examples

**Complete Standards:** See [`/docs/standards/`](./docs/standards/) and [`/archive/docs/standards/`](./archive/docs/standards/)

---

## Version History

**Current Version:** 3.0  
**Status:** Active Development  

### Major Versions

- **V3 (Current)** - Modular architecture, comprehensive error handling, extensive custom fields
- **V2** - Enhanced monitoring, NinjaOne integration, structured logging
- **V1** - Initial framework, basic monitoring capabilities

**Detailed Changelog:** See [`CHANGELOG.md`](./CHANGELOG.md)

---

## Contributing

We welcome contributions to the Windows Automation Framework! Whether you're fixing bugs, adding new scripts, or improving documentation, your help is appreciated.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/new-monitoring-script`)
3. **Follow coding standards** (see `/docs/standards/`)
4. **Add documentation** for new scripts
5. **Test thoroughly** in a lab environment
6. **Submit a pull request** with detailed description

**Detailed Guidelines:** See [`CONTRIBUTING.md`](./CONTRIBUTING.md)

---

## Use Cases

### Enterprise Infrastructure Monitoring
- Centralized health monitoring across 100+ Windows servers
- Automated capacity planning and trend analysis
- Real-time alerting for critical service failures
- Compliance reporting for security audits

### Hyper-V Virtualization Management
- VM health and performance monitoring
- Capacity planning for host resources
- Cluster analytics and failover readiness
- Backup compliance verification

### Patch Management
- Risk-based device classification (P1-P4)
- Phased deployment with test rings (PR1-PR2)
- Automated validation and rollback
- Update compliance tracking

### Active Directory Operations
- Domain controller health monitoring
- Replication status verification
- User lifecycle management automation
- Security group auditing

---

## Support & Community

### Getting Help

- **Documentation:** Start with [`/docs/getting-started/`](./docs/getting-started/)
- **Troubleshooting:** Check [`/docs/troubleshooting/`](./docs/troubleshooting/)
- **Issues:** Report bugs or request features via GitHub Issues
- **Discussions:** Join conversations in GitHub Discussions

### Project Status

- **Active Development:** Regular updates and new scripts
- **Production Ready:** Core monitoring framework stable and tested
- **Documentation:** Comprehensive guides available (ongoing expansion)
- **Community:** Open to contributions and feedback

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Acknowledgments

- Built for enterprise Windows environments
- Designed for NinjaOne RMM integration
- Inspired by real-world infrastructure challenges
- Community-driven development and enhancement

---

## Project Links

- **Repository:** [https://github.com/Xore/waf](https://github.com/Xore/waf)
- **Documentation:** [./docs/](./docs/)
- **Issues:** [GitHub Issues](https://github.com/Xore/waf/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Xore/waf/discussions)

---

**Last Updated:** 2026-02-11  
**Maintained by:** Xore  
**Version:** 3.0
