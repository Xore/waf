# Windows Automation Framework (WAF)

Enterprise-grade monitoring and automation framework for NinjaRMM.

**Version:** 4.0  
**Status:** Production Ready  
**Last Updated:** February 8, 2026

---

## Quick Start

Get monitoring running in 5 minutes: **[Quick Start Guide →](docs/QUICK_START.md)**

---

## Overview

The Windows Automation Framework (WAF) provides comprehensive monitoring, automation, and management capabilities for Windows devices through NinjaRMM. With 277+ custom fields and 110 automated scripts, WAF delivers enterprise-grade visibility and control.

### Key Features

- **Comprehensive Monitoring:** 277+ custom fields track every aspect of device health
- **Automated Scripts:** 110 scripts for monitoring, maintenance, and remediation
- **Dashboard Templates:** 6 complete dashboards with 50+ widget configurations
- **Alert System:** 50+ pre-configured alert templates for critical events
- **Patching Automation:** Ring-based deployment with priority-based validation
- **Predictive Analytics:** Capacity forecasting and device lifetime prediction
- **Security Monitoring:** Complete security posture tracking and compliance
- **Server Monitoring:** Specialized monitoring for IIS, SQL, MySQL, Hyper-V, and more

---

## Documentation

### Getting Started

- **[Quick Start Guide](docs/QUICK_START.md)** - 5-minute setup (start here!)
- **[Deployment Guide](docs/reference/DEPLOYMENT_GUIDE.md)** - Complete deployment procedures
- **[Quick Reference Card](docs/reference/QUICK_REFERENCE.md)** - One-page cheat sheet

### Reference Documentation

- **[Custom Fields Complete](docs/reference/CUSTOM_FIELDS_COMPLETE.md)** - All 277+ fields documented
- **[Dashboard Templates](docs/reference/DASHBOARD_TEMPLATES.md)** - 6 dashboards, 50+ widgets
- **[Alert Configuration](docs/reference/ALERT_CONFIGURATION.md)** - 50+ alert templates

### Additional Resources

- **[WAF Coding Standards](docs/WAF_CODING_STANDARDS.md)** - Development guidelines
- **[Repository Organization Plan](docs/REPOSITORY_REORGANIZATION_PLAN.md)** - Structure overview

---

## Installation

### Prerequisites

- NinjaRMM tenant with administrator access
- NinjaRMM agent installed on target devices
- PowerShell 5.1 or later on target devices
- Permissions to create custom fields and deploy scripts

### Quick Installation (5 minutes)

1. **Create Custom Fields**
   - Start with essential 10 fields (see Quick Start)
   - Expand to full 277+ fields as needed

2. **Deploy Scripts**
   - Begin with core monitoring scripts
   - Add server-specific scripts as needed
   - Configure patching automation (optional)

3. **Configure Automation**
   - Set up script scheduling
   - Create automation policies
   - Configure safety controls

4. **Create Dashboards**
   - Use provided templates
   - Customize for your environment

5. **Set Up Alerts**
   - Deploy critical alerts first
   - Tune thresholds based on environment

### Full Installation (1-3 weeks)

See [Deployment Guide](docs/reference/DEPLOYMENT_GUIDE.md) for complete step-by-step instructions.

---

## Features Overview

### Monitoring Capabilities

**Core Monitoring:**
- Health scoring (0-100 scale)
- Stability analysis
- Performance metrics
- Security posture
- Capacity planning

**Extended Monitoring:**
- Configuration drift detection
- User experience tracking
- Application performance
- Network connectivity
- Backup validation

**Server Monitoring:**
- IIS web servers
- Microsoft SQL Server
- MySQL/MariaDB
- Hyper-V virtualization
- Veeam backup
- Active Directory
- DNS, DHCP, File servers
- Print servers
- FlexLM licensing

### Automation Features

**Patching:**
- Ring-based deployment (test → production)
- Priority-based validation (P1 Critical → P4 Low)
- Automatic health checks
- Maintenance window awareness
- Rollback capabilities

**Remediation:**
- Automatic service restart
- Disk space cleanup
- Memory optimization
- Security hardening
- Configuration drift correction

**Analytics:**
- Capacity forecasting
- Device lifetime prediction
- Replacement planning
- Trend analysis

---

## Architecture

### Custom Field Categories (277+ fields)

1. **OPS** - Operational metrics (15+ fields)
2. **STAT** - Statistical telemetry (20+ fields)
3. **RISK** - Risk classifications (15+ fields)
4. **SEC** - Security metrics (25+ fields)
5. **CAP** - Capacity metrics (20+ fields)
6. **UPD** - Update compliance (15+ fields)
7. **DRIFT** - Configuration drift (10+ fields)
8. **UX** - User experience (15+ fields)
9. **SRV** - Server roles (60+ fields)
10. **NET** - Network metrics (10+ fields)
11. **PRED** - Predictive analytics (10+ fields)
12. **AUTO** - Automation controls (8+ fields)
13. **PATCH** - Patching automation (8+ fields)

### Script Categories (110 scripts)

1. **Core Monitoring** - Essential device monitoring (13 scripts)
2. **Extended Automation** - Advanced features (14 scripts)
3. **Advanced Telemetry** - Capacity and predictive (9 scripts)
4. **Server Role Monitoring** - Server-specific scripts (11 scripts)
5. **Patching Automation** - Patch management (5 scripts)

---

## Quick Examples

### Create a Critical Health Alert

```
Condition: opsHealthScore < 40
Actions:
  - Create ticket (Priority: P1 Critical)
  - Send email to on-call team
  - Run diagnostic script
Notification: Immediate
```

### Create a Disk Space Dashboard

```
Widget 1: Average Disk Free % (Gauge)
Widget 2: Devices with <20% Free (List)
Widget 3: Disk Forecast (Chart)
Widget 4: Days Until Full (Table)
```

### Deploy Patches to Test Ring

```
Script: PR1 - Patch Ring 1 Test Deployment
Schedule: Weekly Tuesday
Target: Devices with patchRing = "PR1"
Validation: Health score > 70
Reboot: After hours only
```

---

## Success Metrics

### Monitoring Coverage
- **277+ custom fields** capturing comprehensive device data
- **110 automated scripts** running continuously
- **4-hour update frequency** for critical metrics
- **Daily updates** for extended metrics

### Alert System
- **50+ alert templates** for common scenarios
- **4 severity levels** (P1 Critical → P4 Low)
- **Automatic escalation** for unresolved issues
- **False positive rate** < 10%

### Automation
- **95%+ script success rate** target
- **98%+ field population rate** target
- **< 30 seconds** average script execution
- **< 5 seconds** dashboard load time

---

## Support

### Documentation
- **[Quick Start](docs/QUICK_START.md)** - Get started in 5 minutes
- **[Reference Suite](docs/reference/)** - Complete documentation
- **[Deployment Guide](docs/reference/DEPLOYMENT_GUIDE.md)** - Full deployment

### Community
- **Issues:** [GitHub Issues](https://github.com/Xore/waf/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Xore/waf/discussions)
- **Repository:** [github.com/Xore/waf](https://github.com/Xore/waf)

### Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

---

## License

See [LICENSE](LICENSE) for details.

---

## Changelog

### Version 4.0 (February 8, 2026)

**Added:**
- Complete reference documentation suite (5 comprehensive guides)
- 277+ custom fields fully documented
- 110 scripts including patching automation
- Dashboard templates with 50+ widgets
- Alert configuration guide with 50+ templates
- Complete deployment guide with 10 phases
- Quick start guide for 5-minute setup

**Changed:**
- Repository reorganization for better navigation
- Documentation streamlined and consolidated
- Historical artifacts moved to archive

**Improved:**
- Field naming consistency
- Script error handling
- Documentation searchability
- User onboarding experience

---

## Project Statistics

- **Total Custom Fields:** 277+
- **Total Scripts:** 110
- **Dashboard Templates:** 6
- **Alert Templates:** 50+
- **Documentation Pages:** 35+
- **Lines of Code:** 25,000+
- **Development Time:** 6+ months
- **Production Status:** Ready

---

**Get Started:** [Quick Start Guide →](docs/QUICK_START.md)  
**Full Documentation:** [docs/](docs/)  
**Support:** [GitHub Issues](https://github.com/Xore/waf/issues)
