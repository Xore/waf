# Windows Automation Framework (WAF)

**Version:** 3.0  
**Status:** Production Ready  
**Last Updated:** 2026-02-10

## 📊 Overview

The Windows Automation Framework (WAF) is a comprehensive, production-ready collection of PowerShell scripts designed for enterprise Windows system monitoring, health assessment, and automation through NinjaRMM integration.

### Key Features

✅ **Comprehensive Monitoring** - 50+ specialized scripts covering all aspects of Windows infrastructure  
✅ **Hyper-V Excellence** - Complete 8-script Hyper-V monitoring suite (V3 standards)  
✅ **NinjaRMM Integration** - Seamless custom field updates and alerting  
✅ **Enterprise-Grade** - Production-tested, error handling, execution tracking  
✅ **Modular Design** - Use individual scripts or complete suites  
✅ **Standardized** - V3 framework standards for consistency

---

## 🚀 Quick Start

### Prerequisites

- **Operating System:** Windows Server 2012 R2+ or Windows 10/11
- **PowerShell:** Version 5.1 or later
- **RMM Platform:** NinjaRMM (recommended) or compatible alternative
- **Permissions:** Administrator privileges (most scripts)

### Installation

1. **Clone the Repository**
   ```powershell
   git clone https://github.com/Xore/waf.git
   cd waf
   ```

2. **Review Script Requirements**
   - Check script headers for dependencies
   - Verify custom fields in NinjaRMM
   - Configure execution policies

3. **Deploy Scripts**
   - Upload to NinjaRMM as Components
   - Schedule execution (see script headers)
   - Configure thresholds and alerting

### First Steps

**Start with Health Monitoring:**
```powershell
# Run a basic health check
.\scripts\01_Health_Score_Calculator.ps1
```

**Try Hyper-V Monitoring (if applicable):**
```powershell
# Monitor Hyper-V VMs
.\"hyper-v monitoring\Hyper-V VM Inventory and Health 1.ps1"
```

**Review Results:**
- Check NinjaRMM custom fields
- Review script output and logs
- Verify execution times

---

## 📁 Repository Structure

```
waf/
├── hyper-v monitoring/         👑 8 production scripts (V3 complete)
│   ├── Script 1: VM Inventory & Health
│   ├── Script 2: VM Backup Status
│   ├── Script 3: Host Resources & Capacity
│   ├── Script 4: VM Replication Monitor
│   ├── Script 5: Cluster Health Monitor
│   ├── Script 6: Performance Monitor
│   ├── Script 7: Storage Performance
│   └── Script 8: Multi-Host Aggregator
│
├── scripts/                    📦 44 core monitoring scripts
│   ├── Health & Monitoring (10)
│   ├── Server-Specific (8)
│   ├── Security (6)
│   ├── Patching & Compliance (5)
│   ├── Capacity & Performance (4)
│   └── [See full catalog]
│
├── plaintext_scripts/          📤 Legacy script versions
├── archive/                    📚 Historical documentation
│
├── README.md                   📝 This file
├── FRAMEWORK_ARCHITECTURE.md   🏛️ Architecture overview
├── CHANGELOG.md                📝 Version history
├── CONTRIBUTING.md             🤝 Development guide
└── DOCUMENTATION_PROGRESS.md   📋 Implementation tracker
```

---

## 🎯 Use Cases

### Infrastructure Monitoring
- **Hyper-V Environments:** Complete 8-script monitoring suite
- **Server Health:** Performance, capacity, stability analysis
- **Service Monitoring:** DNS, File Server, Print Server, MySQL
- **Security Posture:** BitLocker, login patterns, threat detection

### Patch Management
- **Update Assessment:** Windows Update tracking
- **Patch Ring Deployment:** Staged rollout automation
- **Compliance Validation:** Priority-based verification

### Capacity Planning
- **Resource Analysis:** CPU, memory, disk forecasting
- **Trend Detection:** Historical performance tracking
- **Threshold Alerts:** Proactive capacity warnings

### Compliance & Security
- **Security Surface Telemetry:** Attack surface monitoring
- **Compliance Attestation:** Regulatory reporting
- **Drift Detection:** Configuration change tracking

---

## 📊 Hyper-V Monitoring Suite

**Status:** ✅ Production Ready (All V3 Standards)

Comprehensive 8-script monitoring solution for Hyper-V environments:

| Script | Focus | Custom Fields | Frequency |
|--------|-------|---------------|------------|
| **1. VM Inventory & Health** | VM status, configuration | 14 | 15 min |
| **2. VM Backup Status** | Backup health, checkpoints | 14 | 30 min |
| **3. Host Resources** | CPU, memory, capacity | 16 | 5 min |
| **4. VM Replication** | Replication health | 13 | 10 min |
| **5. Cluster Health** | Cluster node status | 14 | 5 min |
| **6. Performance Monitor** | VM performance metrics | 14 | 5 min |
| **7. Storage Performance** | Storage I/O, latency | 14 | 10 min |
| **8. Multi-Host Aggregator** | Cluster-wide analysis | 14 | 30 min |

**Total Custom Fields:** 109  
**Deployment Time:** ~1 hour  
**Documentation:** See `/docs/hyper-v/` (coming soon)

---

## 🛠️ Core Scripts Catalog

### Health & Monitoring (10 scripts)
- `01_Health_Score_Calculator.ps1` - Overall system health scoring
- `02_Stability_Analyzer.ps1` - System stability metrics
- `03_Performance_Analyzer.ps1` - Performance monitoring
- `04_Event_Log_Monitor.ps1` - Critical event tracking
- `06_Telemetry_Collector.ps1` - System telemetry
- `11_Network_Location_Tracker.ps1` - Network connectivity
- `12_Baseline_Manager.ps1` - Configuration baseline
- `13_Drift_Detector.ps1` - Configuration drift
- `21_Battery_Health_Monitor.ps1` - Laptop battery health

### Server-Specific (8 scripts)
- `03_DNS_Server_Monitor.ps1` - DNS server health
- `05_File_Server_Monitor.ps1` - File server monitoring
- `06_Print_Server_Monitor.ps1` - Print server health
- `08_HyperV_Host_Monitor.ps1` - Hyper-V host basics
- `11_MySQL_Server_Monitor.ps1` - MySQL monitoring
- `12_FlexLM_License_Monitor.ps1` - License server
- `20_Server_Role_Identifier.ps1` - Role detection

### Security (6 scripts)
- `04_Security_Analyzer.ps1` - Security posture
- `15_Security_Posture_Consolidator.ps1` - Consolidated security
- `16_Suspicious_Login_Pattern_Detector.ps1` - Login anomalies
- `28_Security_Surface_Telemetry.ps1` - Attack surface
- `30_Advanced_Threat_Telemetry.ps1` - Threat detection
- `31_Endpoint_Detection_Response.ps1` - EDR telemetry

### Patching & Compliance (5 scripts)
- `09_Risk_Classifier.ps1` - Risk assessment
- `10_Update_Assessment_Collector.ps1` - Update tracking
- `P1_Critical_Device_Validator.ps1` - Priority 1 validation
- `P2_High_Priority_Validator.ps1` - Priority 2 validation
- `P3_P4_Medium_Low_Validator.ps1` - Priority 3/4 validation

### Remediation & Tools (5 scripts)
- `19_Proactive_Remediation_Engine.ps1` - Auto-remediation
- `41_Restart_Print_Spooler.ps1` - Print spooler fix
- `42_Restart_Windows_Update.ps1` - Update service fix
- `50_Emergency_Disk_Cleanup.ps1` - Emergency cleanup

---

## 📝 Documentation

### Quick Links

- **[Framework Architecture](FRAMEWORK_ARCHITECTURE.md)** - System design and components
- **[Changelog](CHANGELOG.md)** - Version history and updates
- **[Contributing Guide](CONTRIBUTING.md)** - Development standards
- **[Progress Tracker](DOCUMENTATION_PROGRESS.md)** - Documentation status

### Coming Soon

- `/docs/getting-started/` - Installation and setup guides
- `/docs/hyper-v/` - Hyper-V monitoring complete guide
- `/docs/scripts/` - Individual script documentation
- `/docs/troubleshooting/` - Common issues and solutions
- `/docs/reference/` - Custom fields and API reference

---

## ⚙️ Technical Standards

### V3 Framework Standards

**All new scripts and upgrades follow V3 standards:**

✅ **Standardized Function Names**
   - `Set-NinjaField` (not `Set-NinjaRMMField`)
   - `Write-Log` for consistent logging

✅ **Error Handling**
   - `$ErrorsEncountered` counter
   - `$ErrorDetails` array
   - Comprehensive try/catch blocks

✅ **Execution Tracking**
   - `$ExecutionStartTime` / `$ExecutionEndTime`
   - `finally` block with execution time reporting
   - Exit code standards (0=success, 1-98=errors, 99=unexpected)

✅ **Documentation**
   - Complete `.SYNOPSIS` and `.DESCRIPTION`
   - `.NOTES` section with metadata
   - Dependency documentation
   - Custom field mapping

**Migration Status:**
- Hyper-V Scripts: 8/8 (100%) V3 compliant
- Core Scripts: Migration in progress
- Legacy Scripts: Conversion planned

---

## 🔗 Integration

### NinjaRMM Integration

**Custom Fields:**
- Scripts automatically create/update custom fields
- Field names follow consistent patterns
- Data types: Text, Integer, Float, DateTime, WYSIWYG

**Scheduling:**
- Configured via NinjaRMM Components
- Execution frequency in script headers
- Timeout settings documented

**Alerting:**
- Status fields trigger conditions
- Threshold-based alerting
- HTML reports for visualization

**Example:**
```powershell
# Scripts use standardized field updates
Set-NinjaField -FieldName "hypervVMCount" -Value 15
Set-NinjaField -FieldName "hypervStatus" -Value "HEALTHY"
Set-NinjaField -FieldName "hypervLastScan" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
```

---

## 📊 Performance Metrics

### Typical Execution Times

| Script Category | Average Time | Max Time |
|----------------|--------------|----------|
| Health Checks | 5-15 seconds | 30 sec |
| Hyper-V Monitoring | 10-30 seconds | 60 sec |
| Server Monitoring | 15-45 seconds | 90 sec |
| Emergency Tools | 30-120 seconds | 5 min |

### Resource Usage

- **CPU:** Typically <5% during execution
- **Memory:** 50-200 MB per script
- **Network:** Minimal (local WMI/CIM queries)
- **Disk I/O:** Low (read-only operations)

---

## 🤝 Contributing

Contributions are welcome! Please review our [Contributing Guide](CONTRIBUTING.md) for:

- Code standards and templates
- Testing requirements
- Pull request process
- Development workflow

**Quick Start for Contributors:**
1. Fork the repository
2. Create a feature branch
3. Follow V3 standards
4. Test thoroughly
5. Submit pull request

---

## 📜 License

**Copyright:** Windows Automation Framework  
**License:** Proprietary - Internal Use  
**Contact:** See repository owner

---

## 📧 Support & Contact

**Issues:** Use GitHub Issues for bug reports and feature requests  
**Discussions:** GitHub Discussions for questions and community support  
**Documentation:** Check `/docs/` for guides and references

---

## 📊 Project Status

**Current Version:** 3.0  
**Active Development:** Yes  
**Production Ready:** Yes (Hyper-V suite)  
**Last Update:** 2026-02-10

**Recent Milestones:**
- ✅ Hyper-V monitoring suite completed (8 scripts)
- ✅ V3 standards established
- 🚧 Core scripts V3 migration in progress
- 🚧 Documentation expansion ongoing

---

## 🔎 Quick Reference

### Common Commands

```powershell
# Test script locally
.\script-name.ps1 -Verbose

# Check PowerShell version
$PSVersionTable.PSVersion

# Review execution policy
Get-ExecutionPolicy

# Set execution policy (if needed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# View script help
Get-Help .\script-name.ps1 -Full
```

### File Naming Convention

- **Hyper-V Scripts:** `Hyper-V [Description] [Number].ps1`
- **Core Scripts:** `[Number]_[Description].ps1`
- **Priority Scripts:** `P[1-4]_[Description].ps1`
- **Patch Rings:** `PR[1-3]_[Description].ps1`

---

**🌟 Star this repository if you find it useful!**

**[Report Issues](https://github.com/Xore/waf/issues) | [Request Features](https://github.com/Xore/waf/issues/new) | [View Documentation](DOCUMENTATION_PROGRESS.md)**
