# WAF Quick Start Guide

**Purpose:** Deploy essential monitoring in 15 minutes  
**Audience:** Administrators  
**Created:** February 8, 2026  
**Time Required:** 15-20 minutes

---

## Overview

This guide gets you up and running with core health monitoring using a minimal field and script set. Full deployment details are in the [Deployment_Guide.md](Deployment_Guide.md).

---

## Prerequisites

- NinjaOne admin access
- PowerShell 5.1+ on target devices
- Windows 10/11 or Server 2016+
- 10 minutes for field creation
- 5 minutes for script deployment

---

## Step 1: Create Essential Fields (10 minutes)

### Core Health Fields (6 fields)

Navigate to **NinjaOne > Organization > Custom Fields**

**1. healthStatus** (Text, Device scope)
- Description: Overall device health status
- Used by: 01_Device_Health_Collector.ps1

**2. healthScore** (Text, Device scope) 
- Description: Numeric health score 0-100
- Used by: 01_Device_Health_Collector.ps1

**3. stabilityScore** (Text, Device scope)
- Description: System stability score 0-100
- Used by: 02_System_Stability_Monitor.ps1

**4. securityScore** (Text, Device scope)
- Description: Security posture score 0-100
- Used by: 15_Security_Posture_Scorer.ps1

**5. capacityScore** (Text, Device scope)
- Description: Capacity availability score 0-100
- Used by: 09_Capacity_Score_Calculator.ps1

**6. diskSpacePercent** (Text, Device scope)
- Description: Lowest disk free space percentage
- Used by: 03_Performance_Analyzer.ps1

### Critical Alert Fields (3 fields)

**7. backupHealthStatus** (Text, Device scope)
- Description: Backup health classification
- Used by: Script_48_Veeam_Backup_Monitor.ps1

**8. bitlockerHealthStatus** (Text, Device scope)
- Description: BitLocker encryption status
- Used by: 07_BitLocker_Monitor.ps1

**9. lastHealthCheck** (DateTime, Device scope)
- Description: Last health check timestamp
- Used by: All core scripts

### Field Creation Steps

1. Click **Add Custom Field**
2. Enter field name exactly as shown
3. Select field type (Text or DateTime)
4. Select scope: **Device**
5. Click **Save**
6. Repeat for all 9 fields

---

## Step 2: Deploy Core Scripts (5 minutes)

### Upload 5 Essential Scripts

Navigate to **NinjaOne > Administration > Library > Automation**

**Script 1: 01_Device_Health_Collector.ps1**
- Purpose: Calculate overall device health
- Schedule: Daily at 6 AM
- Timeout: 60 seconds

**Script 2: 02_System_Stability_Monitor.ps1**
- Purpose: Monitor system crashes and stability
- Schedule: Daily at 6:15 AM
- Timeout: 60 seconds

**Script 3: 09_Capacity_Score_Calculator.ps1**
- Purpose: Calculate resource capacity score
- Schedule: Daily at 6:30 AM
- Timeout: 60 seconds

**Script 4: 15_Security_Posture_Scorer.ps1**
- Purpose: Assess security posture
- Schedule: Daily at 6:45 AM
- Timeout: 60 seconds

**Script 5: 07_BitLocker_Monitor.ps1**
- Purpose: Monitor BitLocker encryption
- Schedule: Daily at 7 AM
- Timeout: 30 seconds

### Script Upload Steps

1. Click **New > Script**
2. Name: Use script filename
3. Copy PowerShell code from `/scripts/` directory
4. Platform: **Windows**
5. Click **Save**
6. Repeat for all 5 scripts

---

## Step 3: Assign to Devices (2 minutes)

Navigate to **NinjaOne > Administration > Automation Policies**

1. Create policy: **WAF Core Monitoring**
2. Add all 5 scripts to policy
3. Configure schedules (daily, staggered 15 minutes apart)
4. Assign policy to device groups
5. Save policy

---

## Step 4: Create Basic Dashboard (3 minutes)

Navigate to **NinjaOne > Devices**

### Dashboard Configuration

**Columns to Add:**
1. Device Name (default)
2. Health Status (healthStatus field)
3. Health Score (healthScore field)
4. Stability (stabilityScore field)
5. Security (securityScore field)
6. Capacity (capacityScore field)
7. Disk Space % (diskSpacePercent field)
8. Last Check (lastHealthCheck field)

**Filters:**
- Health Status = "Critical" (view critical devices)
- Health Status = "Warning" (view warned devices)

**Sorting:**
- Primary: Health Status (Critical first)
- Secondary: Health Score (lowest first)

### Conditional Formatting

**Status Colors:**
- Critical → Red highlight
- Warning → Yellow highlight
- Healthy → Green highlight
- Unknown → Gray highlight

---

## Step 5: Configure Critical Alerts (5 minutes)

Navigate to **NinjaOne > Administration > Conditions**

### Alert 1: Critical Health Status
```
Condition Name: P1-Health-Critical
If: healthStatus = "Critical"
Then: Send Email to: alerts@company.com
      Create Ticket
      Priority: P1
```

### Alert 2: Critical Disk Space
```
Condition Name: P1-Disk-Critical  
If: diskSpacePercent < 10
Then: Send Email to: alerts@company.com
      Create Ticket
      Priority: P1
```

### Alert 3: BitLocker Not Enabled
```
Condition Name: P2-BitLocker-Missing
If: bitlockerHealthStatus = "Critical"
And: Device Type = "Laptop"
Then: Send Email to: security@company.com
      Create Ticket
      Priority: P2
```

---

## Step 6: Test Deployment (5 minutes)

### Manual Test Run

1. Select test device
2. Navigate to **Scripts** tab
3. Run **01_Device_Health_Collector.ps1** manually
4. Wait for completion (30-60 seconds)
5. Refresh device page
6. Verify **healthStatus** and **healthScore** populated
7. Repeat for other 4 scripts

### Verify Dashboard

1. Navigate to **Devices** dashboard
2. Verify new columns visible
3. Verify test device shows data
4. Test filters and sorting

### Verify Alerts

1. Navigate to **Conditions**
2. Check condition evaluation status
3. If device is critical, verify alert triggered

---

## Expected Results

### After 24 Hours

**Field Population:**
- All 9 fields populated on all devices
- Health scores calculated (0-100 range)
- Status values (Healthy/Warning/Critical/Unknown)
- Timestamps updated daily

**Dashboard Visibility:**
- Clear health overview of all devices
- Critical devices highlighted in red
- Warning devices highlighted in yellow
- Sortable by any metric

**Alert Functionality:**
- Critical health triggers immediate alerts
- Low disk space generates tickets
- Missing BitLocker flagged on laptops

---

## Next Steps

### Expand Monitoring (Week 2)

Add these fields and scripts:
- Server monitoring (if servers present)
- Performance metrics (CPU, memory trends)
- Security drift detection
- Patch compliance tracking

**See:** [Deployment_Guide.md](Deployment_Guide.md) for full deployment

### Enhance Dashboards (Week 3)

**See:** [Dashboard_Templates.md](Dashboard_Templates.md) for:
- Server health dashboard
- Security posture dashboard
- Capacity planning dashboard
- Patching status dashboard

### Advanced Features (Week 4)

Explore advanced monitoring:
- Predictive analytics (capacity forecasting)
- Drift detection (configuration changes)
- User experience monitoring
- Automated remediation

**See:** Complete field reference and documentation in this directory

---

## Troubleshooting

### Fields Not Populating

**Check:**
1. Script execution completed successfully
2. No errors in script output log
3. Field names match exactly (case-sensitive)
4. Device has automation policy assigned
5. Scripts scheduled and enabled

**Solution:**
- Review script output for errors
- Verify `Ninja-Property-Set` commands in script
- Check PowerShell execution policy
- Ensure device online and reachable

### Dashboard Not Showing Fields

**Check:**
1. Fields created in correct scope (Device)
2. Field type matches (Text, DateTime)
3. Device has policy assigned
4. Scripts have run at least once

**Solution:**
- Refresh dashboard
- Clear browser cache
- Verify field creation in admin panel
- Re-run scripts manually

### Alerts Not Triggering

**Check:**
1. Conditions created and enabled
2. Field values match condition criteria
3. Alert actions configured correctly
4. Email addresses valid

**Solution:**
- Test condition manually
- Verify condition evaluation log
- Check spam folder for alerts
- Verify NinjaOne notification settings

---

## Support Resources

**Documentation:**
- [Custom Fields Complete Reference](Custom_Fields_Complete_Reference.md) - All field details
- [Deployment Guide](Deployment_Guide.md) - Full deployment procedure
- [Alert Configuration Guide](Alert_Configuration_Guide.md) - Advanced alerting

**Scripts:**
- Script source code: `/scripts/` directory
- Script documentation: `/docs/scripts/` directory
- Coding standards: `/docs/WAF_CODING_STANDARDS.md`

**Visual Guides:**
- Framework diagrams: `/docs/diagrams/` directory
- Architecture overview: `/docs/diagrams/01_Framework_Architecture.md`
- Data flow: `/docs/diagrams/03_Data_Flow.md`

---

## Summary

**Time Investment:** 15-20 minutes  
**Fields Created:** 9 essential fields  
**Scripts Deployed:** 5 core scripts  
**Dashboards:** 1 health overview  
**Alerts:** 3 critical conditions  

**Result:** Basic health monitoring operational with critical alerting

**Next Step:** Wait 24 hours for first data collection cycle, then expand to full deployment

---

**Quick Start Complete!**

You now have basic health monitoring running. Review the dashboard daily and address any critical alerts. Once comfortable, proceed to full deployment using the [Deployment_Guide.md](Deployment_Guide.md).
