# NinjaRMM Custom Field Framework v1.0 (Native-Enhanced)

## 📖 Overview

A comprehensive monitoring and alerting framework for NinjaRMM that combines **NinjaOne's native monitoring** with **custom intelligence fields** for advanced device health management.

### Core Philosophy
- **Native First:** Use NinjaOne's built-in monitoring for real-time metrics
- **Custom Intelligence:** Add custom fields only for scoring, classification, and aggregation
- **Hybrid Conditions:** Combine native + custom for context-aware alerts
- **Reduce Complexity:** Fewer fields and scripts = easier maintenance

---

## 🎯 Framework Components

### 1. Core Custom Fields (19 Essential)
**Intelligence and aggregation only - no duplication of native metrics**

#### OPS - Operational Scores (6 Fields)
Composite intelligence scores combining native + custom data:
- **OPSHealthScore** - Overall health (0-100)
- **OPSStabilityScore** - Stability assessment (0-100)
- **OPSPerformanceScore** - Performance assessment (0-100)
- **OPSSecurityScore** - Security posture (0-100)
- **OPSCapacityScore** - Capacity headroom (0-100)
- **OPSLastScoreUpdate** - Last calculation timestamp

#### STAT - Raw Telemetry (6 Fields)
Custom aggregation not available natively:
- **STATAppCrashes24h** - Application crash count (24h window)
- **STATAppHangs24h** - Application hang count (24h window)
- **STATServiceFailures24h** - Service failure count (24h window)
- **STATBSODCount30d** - BSOD count (30-day window)
- **STATUptimeDays** - Days since last reboot
- **STATLastTelemetryUpdate** - Last collection timestamp

#### RISK - Classification (7 Fields)
Intelligent risk assessment:
- **RISKHealthLevel** - Health classification (Healthy/Degraded/Critical/Unknown)
- **RISKRebootLevel** - Reboot recommendation (None/Low/Medium/High/Critical)
- **RISKSecurityExposure** - Security risk level (Low/Medium/High/Critical)
- **RISKComplianceFlag** - Compliance status
- **RISKShadowIT** - Shadow IT detection flag
- **RISKDataLossRisk** - Data loss risk level
- **RISKLastRiskAssessment** - Last assessment timestamp

### 2. Core Scripts (7 Active)
**Intelligence calculation only - query native metrics, don't collect them**

| Script | Purpose | Native Integration | Frequency |
|--------|---------|-------------------|-----------|
| **1** | Health Score Calculator | Queries native Disk/Memory/CPU | 4 hours |
| **2** | Stability Analyzer | Uses Event Log (native) | 4 hours |
| **3** | Performance Analyzer | Queries native CPU/Memory/Disk | 4 hours |
| **4** | Security Analyzer | Queries native AV/Firewall/Patches | Daily |
| **5** | Capacity Analyzer | Queries native Disk/Memory + predictive | Daily |
| **6** | Telemetry Collector | Custom crash/hang aggregation | 4 hours |
| **9** | Risk Classifier | Uses native Backup/SMART/Security | 4 hours |

### 3. Hybrid Compound Conditions (75 Patterns)
**Combining native real-time monitoring with custom intelligence**

#### P1 Critical (15 Patterns)
Example: **Disk Space Critical with Imminent Failure**
```
Native: Disk Free Space < 5% (real-time)
Custom: CAPDaysUntilDiskFull < 3 (predictive intelligence)
Custom: STATStabilityScore < 50 (stability context)
Result: High-confidence critical alert with context
```

#### P2 High (20 Patterns)
Example: **Memory Exhaustion with Instability**
```
Native: Memory Utilization > 95% for 15 minutes (sustained)
Custom: STATCrashCount30d > 2 (crash history)
Custom: OPSHealthScore < 50 (composite assessment)
Result: Memory pressure + instability = urgent action
```

#### P3 Medium (25 Patterns)
Maintenance and proactive monitoring

#### P4 Low (15 Patterns)
Informational and trend alerts

### 4. Dynamic Groups (36+ Groups)
Automated device grouping based on health, risk, role, and automation eligibility

---

## 🚀 Quick Start

### New Deployment

**Week 1: Core Setup**
1. Create 19 core custom fields from `10_OPS_STAT_RISK_Core_Metrics.md`
2. Configure NinjaOne native monitoring (already available)
3. Deploy 7 core scripts from `55_Scripts_01_13_Infrastructure_Monitoring.md`
4. Scripts automatically query native metrics + add intelligence

**Week 2: Conditions & Testing**
1. Create 75 hybrid compound conditions from `91_Compound_Conditions_Complete.md`
2. Test on pilot group (10-20 devices)
3. Validate alert accuracy
4. Tune thresholds

**Week 3: Groups & Automation**
1. Create dynamic groups from `92_Dynamic_Groups_Complete.md`
2. Enable gradual automation
3. Dashboard setup
4. User training

**Week 4: Full Deployment**
1. Roll out to all devices
2. Monitor and optimize
3. Success validation

**Total Time:** 4 weeks

---

## 📁 Documentation Structure

### Essential Reading (Start Here)
1. **00_README.md** - This file, framework overview
2. **00_Master_Index.md** - Complete navigation and file index
3. **10_OPS_STAT_RISK_Core_Metrics.md** - Core 19 fields (ESSENTIAL)
4. **91_Compound_Conditions_Complete.md** - 75 hybrid condition patterns
5. **55_Scripts_01_13_Infrastructure_Monitoring.md** - 7 core scripts

### Native Integration Guides
- **NATIVE_INTEGRATION_OPTIMIZATION_SUMMARY.md** - Complete optimization guide

### Extended Documentation
- **11-14**: Extended field categories (26 optional fields)
- **22-24**: Infrastructure modules (~66 role-specific fields)
- **51-60**: Script documentation and mappings
- **70**: Custom health check templates
- **92**: Dynamic group patterns
- **98**: Framework complete summary
- **99**: Quick reference guide
- **100**: Detailed ROI analysis

---

## 🛠️ Technical Requirements

### NinjaRMM/NinjaOne Requirements
- NinjaOne agent (current version recommended)
- Native monitoring enabled (CPU, Memory, Disk, Network, Security)
- PowerShell execution capability
- Custom field creation permissions
- Compound condition creation permissions

### Supported Platforms
- Windows 10/11 (workstations)
- Windows Server 2016+ (servers)
- PowerShell 5.1+ (included in Windows)

### Optional Modules
- Server roles (IIS, SQL, MySQL, Apache, etc.)
- Backup monitoring (Veeam, etc.)
- Active Directory integration
- Custom application monitoring

---

## 🎓 Best Practices

### Use Native Metrics First
- Always check if a metric is available natively before creating custom field
- Native metrics: CPU, Memory, Disk, Network, Security, Backup, SMART, Event Log

### Custom Fields for Intelligence Only
- Composite scores (OPS fields)
- Historical aggregation (STAT fields)
- Risk classification (RISK fields)
- Predictive analytics (CAP fields)

### Hybrid Conditions
- Combine native real-time metrics with custom intelligence
- Example: `Native CPU > 85% AND Custom StabilityScore < 70 AND Custom CrashCount > 0`
- Result: High-confidence alert with full context

### Start Simple
- Deploy core 19 fields first
- Add extended 26 fields as needed
- Add infrastructure modules only for applicable servers
- Test on pilot group before full rollout

---

## 📞 Support

### Documentation
- See `00_Master_Index.md` for complete file navigation
- See `99_Quick_Reference_Guide.md` for troubleshooting
- See `NATIVE_INTEGRATION_OPTIMIZATION_SUMMARY.md` for optimization details

### Community
- Framework updates and best practices shared regularly
- User contributions welcome
- Version 1.0 recommended for all new deployments

---

## 📜 Version History

### Version 1.0 (February 2026) - CURRENT
- Initial core framework

---

## 📄 License

This framework is provided as-is for use with NinjaRMM/NinjaOne. Customize and adapt to your environment.

---

**Framework Version:** v1.0 (Native Integration)  
**Last Updated:** February 1, 2026  
**Status:** ! NOT Production Ready !  
**Recommended:** For all new deployments

---

## 🚀 Get Started Now

1. Read `10_OPS_STAT_RISK_Core_Metrics.md` for core field definitions
2. Deploy 7 core scripts from `55_Scripts_01_13_Infrastructure_Monitoring.md`
3. Create 75 hybrid conditions from `91_Compound_Conditions_Complete.md`
4. Test on pilot group
5. Roll out to production

**Deploy smarter, monitor better, maintain less with v1.0 Native Integration!**
