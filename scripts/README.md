# NinjaOne Framework v4.0 - PowerShell Scripts

## Overview
This directory contains all 110 PowerShell scripts from the NinjaOne Custom Field Framework v4.0.

## Organization
Scripts are organized into the following categories:

### Core Monitoring Scripts (Scripts 1-13)
- **Scripts_01-06_Core_Metrics/** - Health, Stability, Performance, Security, Capacity, Telemetry
- **Scripts_09_Risk_Classification/** - Risk classification and assessment
- **Scripts_10-13_Infrastructure/** - Update assessment, network tracking, baseline management

### Extended Automation Scripts (Scripts 14-27)
- **Scripts_14-21_Drift_Security_UX/** - Drift detection, security posture, user experience
- **Scripts_22-24_Capacity_Predictive/** - Capacity forecasting, predictive analytics
- **Scripts_27_Telemetry/** - Telemetry freshness monitoring

### Advanced Telemetry Scripts (Scripts 28-36)
- **Scripts_28-31_Security_Network/** - Security surface, collaboration UX, connectivity
- **Scripts_32-36_Hardware_Licensing/** - Thermal/firmware, licensing, baseline coverage

### Server Role Monitoring Scripts (Scripts 51-110)
- **Scripts_51-60_IIS_SQL_Web/** - IIS, MS SQL, MySQL monitoring
- **Scripts_61-70_Apache_Backup/** - Apache, Veeam backup monitoring
- **Scripts_71-80_DHCP_DNS/** - DHCP, DNS infrastructure
- **Scripts_81-90_Event_FileServer/** - Event logs, file server monitoring
- **Scripts_91-100_Print_HyperV/** - Print server, Hyper-V monitoring
- **Scripts_101-110_BitLocker_Features/** - BitLocker, Windows features, FlexLM

### Patching Automation Scripts (NEW)
- **Scripts_P_Patching/** - PR1, PR2, P1-P4 validators

## Usage

### Deployment in NinjaOne
1. Navigate to **Configuration > Scripting**
2. Click **Add a new script**
3. Copy script content from desired .ps1 file
4. Configure script parameters:
   - **Language:** PowerShell
   - **Operating System:** Windows
   - **Architecture:** All
   - **Run As:** SYSTEM (for most scripts)
5. Set execution schedule based on script requirements

### Custom Field Prerequisites
Before deploying scripts, ensure corresponding custom fields are created in NinjaOne:
- See files 10-24 for field definitions
- Use file 31 for patching fields
- Reference file 51 for complete field-to-script mapping

### Execution Schedules

#### Every 4 Hours
- Scripts 1-6 (Core metrics)
- Script 9 (Risk classification)
- Script 16 (Suspicious login detector)
- Scripts 29, 31 (Collaboration UX, connectivity)

#### Daily
- Scripts 10-13 (Infrastructure)
- Scripts 14-21 (Drift, security, UX)
- Scripts 23, 28, 30, 32, 34-35 (Telemetry)

#### Weekly
- Scripts 22, 24 (Capacity forecasting, predictive analytics)
- Scripts PR1, PR2 (Patch ring deployment)

#### On-Demand
- Scripts P1-P4 (Patch validators)

## Script Categories

### Core Monitoring (13 scripts)
Provides foundational health, stability, performance, security, and capacity scoring.

### Extended Automation (14 scripts)
Detects configuration drift, monitors security posture, tracks user experience.

### Advanced Telemetry (9 scripts)
Capacity forecasting, predictive analytics, network quality monitoring.

### Server Roles (60 scripts)
Monitors IIS, SQL, MySQL, Apache, Veeam, DHCP, DNS, file servers, print servers, Hyper-V, BitLocker, Windows features, FlexLM license servers.

### Patching Automation (5 scripts)
Ring-based deployment with priority validation for automated patch management.

## Dependencies

Most scripts require:
- NinjaOne RMM Agent installed
- PowerShell 5.1 or higher
- SYSTEM-level permissions
- Corresponding custom fields created

Some server role scripts require:
- Specific Windows roles/features installed (IIS, DHCP, DNS, etc.)
- Database server access (SQL Server, MySQL)
- Administrative credentials

## Version Information

**Framework Version:** 4.0 (Native-Enhanced with ML/RCA & Patching Automation)
**Script Count:** 110 scripts
**Date:** February 1, 2026
**Status:** Production Ready

## Support

For complete documentation, see:
- **00_README.md** - Framework overview
- **00_Master_Index.md** - Complete navigation
- **01_Framework_Architecture.md** - System design
- **51_Field_to_Script_Complete_Mapping.md** - Field traceability
- **98_Framework_Complete_Summary_Master.md** - Comprehensive reference

## License

These scripts are part of the NinjaOne Custom Field Framework v4.0.
Use at your own risk. Test thoroughly before production deployment.
