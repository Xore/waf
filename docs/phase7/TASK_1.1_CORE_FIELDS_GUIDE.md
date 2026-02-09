# Task 1.1: Core Custom Fields Creation Guide

**Task:** Create 50 Core Custom Fields  
**Phase:** 7.1 - Foundation Deployment  
**Priority:** P1 (Critical)  
**Status:** 🚧 IN PROGRESS  
**Started:** February 9, 2026, 1:07 AM CET  
**Estimated Time:** 2-3 hours

---

## Overview

This guide provides complete specifications for creating the 50 core custom fields required for Phase 7.1 foundation deployment. These fields enable essential monitoring capabilities and form the foundation for the Windows Automation Framework.

---

## Field Creation Instructions

### NinjaRMM Field Creation Process

1. Navigate to **Administration > Device Custom Fields**
2. Click **Add Custom Field**
3. Fill in field specifications from tables below
4. Click **Save**
5. Repeat for all 50 fields

---

## Operations Fields (15 fields)

### Category: OPS - Operational Metrics

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 1 | opsHealthScore | Integer | 0-100 | Overall device health score calculated from multiple metrics |
| 2 | opsStabilityScore | Integer | 0-100 | System stability score based on crash/error frequency |
| 3 | opsPerformanceScore | Integer | 0-100 | Performance score based on CPU, memory, disk metrics |
| 4 | opsSecurityScore | Integer | 0-100 | Security posture score from AV, firewall, encryption status |
| 5 | opsCapacityScore | Integer | 0-100 | Capacity health score from disk/memory availability |
| 6 | opsOverallScore | Integer | 0-100 | Weighted average of all operational scores |
| 7 | opsLastHealthCheck | Date/Time | Unix Epoch | Timestamp of last health score calculation |
| 8 | opsUptime | Integer | Seconds | Current system uptime in seconds |
| 9 | opsUptimeDays | Integer | Days | Current system uptime in days (calculated) |
| 10 | opsLastBootTime | Date/Time | Unix Epoch | Timestamp of last system boot |
| 11 | opsDeviceAge | Integer | Seconds | Device age since first enrollment |
| 12 | opsDeviceAgeMonths | Integer | Months | Device age in months (calculated) |
| 13 | opsMonitoringEnabled | Checkbox | true/false | Whether WAF monitoring is enabled for this device |
| 14 | opsStatus | Dropdown | See values | Current operational status |
| 15 | opsNotes | Text | Free text | Administrative notes about device status |

**opsStatus Dropdown Values:**
- Healthy
- Warning
- Critical
- Unknown
- Maintenance

---

## Statistics Fields (10 fields)

### Category: STAT - Statistical Telemetry

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 16 | statCrashCount30d | Integer | 0+ | Number of system crashes in last 30 days |
| 17 | statErrorCount30d | Integer | 0+ | Number of error events in last 30 days |
| 18 | statWarningCount30d | Integer | 0+ | Number of warning events in last 30 days |
| 19 | statRebootCount30d | Integer | 0+ | Number of system reboots in last 30 days |
| 20 | statStabilityScore | Integer | 0-100 | Stability score from event log analysis |
| 21 | statAvgCPUUsage | Integer | 0-100 | Average CPU usage percentage over 24 hours |
| 22 | statAvgMemoryUsage | Integer | 0-100 | Average memory usage percentage over 24 hours |
| 23 | statAvgDiskUsage | Integer | 0-100 | Average disk usage percentage over 24 hours |
| 24 | statLastCrashDate | Date/Time | Unix Epoch | Timestamp of most recent system crash |
| 25 | statUpgradeAvailable | Checkbox | true/false | Whether OS upgrade is available |

---

## Security Fields (10 fields)

### Category: SEC - Security Metrics

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 26 | secAntivirusEnabled | Checkbox | true/false | Whether antivirus protection is enabled |
| 27 | secAntivirusProduct | Text | Product name | Name of installed antivirus product |
| 28 | secAntivirusUpdated | Checkbox | true/false | Whether AV definitions are current (< 7 days) |
| 29 | secFirewallEnabled | Checkbox | true/false | Whether Windows Firewall is enabled |
| 30 | secBitLockerEnabled | Checkbox | true/false | Whether BitLocker encryption is enabled |
| 31 | secSecureBootEnabled | Checkbox | true/false | Whether Secure Boot is enabled |
| 32 | secTPMEnabled | Checkbox | true/false | Whether TPM chip is present and enabled |
| 33 | secLastSecurityScan | Date/Time | Unix Epoch | Timestamp of last security posture scan |
| 34 | secVulnerabilityCount | Integer | 0+ | Number of identified security vulnerabilities |
| 35 | secComplianceStatus | Dropdown | See values | Overall security compliance status |

**secComplianceStatus Dropdown Values:**
- Compliant
- Non-Compliant
- Unknown
- Exempt

---

## Capacity Fields (10 fields)

### Category: CAP - Capacity Metrics

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 36 | capDiskFreeGB | Integer | 0+ | Free disk space in gigabytes (C: drive) |
| 37 | capDiskFreePercent | Integer | 0-100 | Free disk space as percentage (C: drive) |
| 38 | capDiskTotalGB | Integer | 0+ | Total disk size in gigabytes (C: drive) |
| 39 | capMemoryTotalGB | Integer | 0+ | Total system memory in gigabytes |
| 40 | capMemoryUsedGB | Integer | 0+ | Currently used memory in gigabytes |
| 41 | capMemoryUsedPercent | Integer | 0-100 | Memory usage as percentage |
| 42 | capCPUCores | Integer | 1+ | Number of physical CPU cores |
| 43 | capCPUThreads | Integer | 1+ | Number of logical CPU threads |
| 44 | capWarningLevel | Dropdown | See values | Capacity warning level |
| 45 | capForecastDaysFull | Integer | 0+ | Forecasted days until disk is full |

**capWarningLevel Dropdown Values:**
- Normal
- Warning
- Critical

---

## Updates Fields (5 fields)

### Category: UPD - Update Compliance

| # | Field Name | Type | Values/Range | Description |
|---|------------|------|--------------|-------------|
| 46 | updComplianceStatus | Dropdown | See values | Overall patch compliance status |
| 47 | updMissingCriticalCount | Integer | 0+ | Number of missing critical updates |
| 48 | updMissingImportantCount | Integer | 0+ | Number of missing important updates |
| 49 | updLastPatchDate | Date/Time | Unix Epoch | Timestamp of last installed patch |
| 50 | updLastPatchCheck | Date/Time | Unix Epoch | Timestamp of last Windows Update check |

**updComplianceStatus Dropdown Values:**
- Compliant
- Minor Gap
- Major Gap
- Critical Gap

---

## Field Creation Script

### PowerShell Script for Documentation

```powershell
<#
.SYNOPSIS
    Core Custom Fields - Creation Reference
    
.DESCRIPTION
    This script documents the 50 core custom fields for Phase 7.1.
    Fields must be created manually in NinjaRMM UI or via API.
    
.NOTES
    Use this as reference when creating fields in NinjaRMM.
#>

# Operations Fields (15)
$opsFields = @(
    @{Name="opsHealthScore"; Type="INTEGER"; Description="Overall device health score (0-100)"}
    @{Name="opsStabilityScore"; Type="INTEGER"; Description="System stability score (0-100)"}
    @{Name="opsPerformanceScore"; Type="INTEGER"; Description="Performance score (0-100)"}
    @{Name="opsSecurityScore"; Type="INTEGER"; Description="Security posture score (0-100)"}
    @{Name="opsCapacityScore"; Type="INTEGER"; Description="Capacity health score (0-100)"}
    @{Name="opsOverallScore"; Type="INTEGER"; Description="Weighted average of all scores (0-100)"}
    @{Name="opsLastHealthCheck"; Type="TIMESTAMP"; Description="Last health check timestamp"}
    @{Name="opsUptime"; Type="INTEGER"; Description="Current uptime in seconds"}
    @{Name="opsUptimeDays"; Type="INTEGER"; Description="Current uptime in days"}
    @{Name="opsLastBootTime"; Type="TIMESTAMP"; Description="Last system boot timestamp"}
    @{Name="opsDeviceAge"; Type="INTEGER"; Description="Device age in seconds"}
    @{Name="opsDeviceAgeMonths"; Type="INTEGER"; Description="Device age in months"}
    @{Name="opsMonitoringEnabled"; Type="CHECKBOX"; Description="WAF monitoring enabled"}
    @{Name="opsStatus"; Type="DROPDOWN"; Values=@("Healthy","Warning","Critical","Unknown","Maintenance"); Description="Current status"}
    @{Name="opsNotes"; Type="TEXT"; Description="Administrative notes"}
)

# Statistics Fields (10)
$statFields = @(
    @{Name="statCrashCount30d"; Type="INTEGER"; Description="Crashes in last 30 days"}
    @{Name="statErrorCount30d"; Type="INTEGER"; Description="Errors in last 30 days"}
    @{Name="statWarningCount30d"; Type="INTEGER"; Description="Warnings in last 30 days"}
    @{Name="statRebootCount30d"; Type="INTEGER"; Description="Reboots in last 30 days"}
    @{Name="statStabilityScore"; Type="INTEGER"; Description="Stability score (0-100)"}
    @{Name="statAvgCPUUsage"; Type="INTEGER"; Description="Average CPU usage %"}
    @{Name="statAvgMemoryUsage"; Type="INTEGER"; Description="Average memory usage %"}
    @{Name="statAvgDiskUsage"; Type="INTEGER"; Description="Average disk usage %"}
    @{Name="statLastCrashDate"; Type="TIMESTAMP"; Description="Last crash timestamp"}
    @{Name="statUpgradeAvailable"; Type="CHECKBOX"; Description="OS upgrade available"}
)

# Security Fields (10)
$secFields = @(
    @{Name="secAntivirusEnabled"; Type="CHECKBOX"; Description="Antivirus enabled"}
    @{Name="secAntivirusProduct"; Type="TEXT"; Description="Antivirus product name"}
    @{Name="secAntivirusUpdated"; Type="CHECKBOX"; Description="AV definitions current"}
    @{Name="secFirewallEnabled"; Type="CHECKBOX"; Description="Firewall enabled"}
    @{Name="secBitLockerEnabled"; Type="CHECKBOX"; Description="BitLocker enabled"}
    @{Name="secSecureBootEnabled"; Type="CHECKBOX"; Description="Secure Boot enabled"}
    @{Name="secTPMEnabled"; Type="CHECKBOX"; Description="TPM enabled"}
    @{Name="secLastSecurityScan"; Type="TIMESTAMP"; Description="Last security scan"}
    @{Name="secVulnerabilityCount"; Type="INTEGER"; Description="Vulnerability count"}
    @{Name="secComplianceStatus"; Type="DROPDOWN"; Values=@("Compliant","Non-Compliant","Unknown","Exempt"); Description="Compliance status"}
)

# Capacity Fields (10)
$capFields = @(
    @{Name="capDiskFreeGB"; Type="INTEGER"; Description="Free disk space (GB)"}
    @{Name="capDiskFreePercent"; Type="INTEGER"; Description="Free disk space (%)"}
    @{Name="capDiskTotalGB"; Type="INTEGER"; Description="Total disk size (GB)"}
    @{Name="capMemoryTotalGB"; Type="INTEGER"; Description="Total memory (GB)"}
    @{Name="capMemoryUsedGB"; Type="INTEGER"; Description="Used memory (GB)"}
    @{Name="capMemoryUsedPercent"; Type="INTEGER"; Description="Memory usage (%)"}
    @{Name="capCPUCores"; Type="INTEGER"; Description="Physical CPU cores"}
    @{Name="capCPUThreads"; Type="INTEGER"; Description="Logical CPU threads"}
    @{Name="capWarningLevel"; Type="DROPDOWN"; Values=@("Normal","Warning","Critical"); Description="Warning level"}
    @{Name="capForecastDaysFull"; Type="INTEGER"; Description="Days until disk full"}
)

# Updates Fields (5)
$updFields = @(
    @{Name="updComplianceStatus"; Type="DROPDOWN"; Values=@("Compliant","Minor Gap","Major Gap","Critical Gap"); Description="Patch compliance status"}
    @{Name="updMissingCriticalCount"; Type="INTEGER"; Description="Missing critical updates"}
    @{Name="updMissingImportantCount"; Type="INTEGER"; Description="Missing important updates"}
    @{Name="updLastPatchDate"; Type="TIMESTAMP"; Description="Last patch install date"}
    @{Name="updLastPatchCheck"; Type="TIMESTAMP"; Description="Last update check date"}
)

Write-Host "Total Core Fields: 50"
Write-Host "- Operations: 15"
Write-Host "- Statistics: 10"
Write-Host "- Security: 10"
Write-Host "- Capacity: 10"
Write-Host "- Updates: 5"
```

---

## Field Relationships

### Health Score Calculation

**opsHealthScore** is calculated from:
- opsStabilityScore (20% weight)
- opsPerformanceScore (20% weight)
- opsSecurityScore (30% weight)
- opsCapacityScore (30% weight)

### Stability Score Calculation

**opsStabilityScore** is calculated from:
- statCrashCount30d (40% impact)
- statErrorCount30d (30% impact)
- statWarningCount30d (20% impact)
- statRebootCount30d (10% impact)

### Security Score Calculation

**opsSecurityScore** is calculated from:
- secAntivirusEnabled (20%)
- secAntivirusUpdated (15%)
- secFirewallEnabled (15%)
- secBitLockerEnabled (15%)
- secSecureBootEnabled (10%)
- secTPMEnabled (10%)
- secVulnerabilityCount (15% - inverse)

### Capacity Score Calculation

**opsCapacityScore** is calculated from:
- capDiskFreePercent (50%)
- capMemoryUsedPercent (50% - inverse)

---

## Validation Checklist

After creating all 50 fields:

- [ ] All 15 Operations fields created
- [ ] All 10 Statistics fields created
- [ ] All 10 Security fields created
- [ ] All 10 Capacity fields created
- [ ] All 5 Updates fields created
- [ ] Field names match exactly (case-sensitive)
- [ ] Field types are correct
- [ ] Dropdown values are configured
- [ ] Date/Time fields accept Unix Epoch
- [ ] All fields visible in device details

---

## Expected Outcomes

Once these 50 fields are created:

1. **Core monitoring enabled** - Essential health metrics can be tracked
2. **Dashboard foundation** - Widgets can display health scores
3. **Alert capability** - Conditions can trigger on field values
4. **Script targets** - Scripts 1-13 can populate these fields
5. **Operational visibility** - IT team can see device health at a glance

---

## Next Steps

After completing Task 1.1:

1. **Task 1.2** - Deploy 13 core monitoring scripts
2. **Task 1.3** - Configure pilot devices (5-10 devices)
3. **Task 1.4** - Wait 24 hours and validate field population

---

## API Creation Method (Alternative)

For programmatic field creation using NinjaRMM API:

```bash
# Example API call to create a field
curl -X POST "https://api.ninjarmm.com/v2/organization/custom-fields" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "opsHealthScore",
    "type": "INTEGER",
    "description": "Overall device health score (0-100)"
  }'
```

**Note:** API method requires NinjaRMM API access and authentication.

---

## Troubleshooting

### Issue: Field Already Exists
**Solution:** Check field name spelling, may need to delete duplicate first

### Issue: Dropdown Values Not Saving
**Solution:** Ensure values are entered one per line, press Enter after each

### Issue: Date/Time Fields Not Accepting Data
**Solution:** Verify field type is "Date and Time", scripts use Unix Epoch format

### Issue: Field Not Visible
**Solution:** Check field is enabled and assigned to correct scope (Device/Organization)

---

**Task Status:** 🚧 Ready for Execution  
**Prerequisites:** NinjaRMM admin access  
**Estimated Time:** 2-3 hours for manual creation  
**Next Task:** Task 1.2 - Deploy Core Monitoring Scripts
