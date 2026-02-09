# WAF Health Check Tools Specification

**Purpose:** Automated validation tools for WAF health monitoring  
**Status:** Design specification (implementation pending)  
**Last Updated:** February 9, 2026

---

## Overview

WAF Health Check Tools are automated validators that verify WAF is operating correctly. These tools check field population, script execution, performance, and data quality.

---

## Tool 1: Field Population Checker

### Purpose
Verifies that custom fields are being populated with current data across all monitored devices.

### Target Metrics
- Field population rate: **96%+**
- Data freshness: **<24 hours** for daily fields
- Null/empty fields: **<4%**

### Functionality

**Inputs:**
- Device group or all devices
- Field list to check (default: all WAF fields)
- Freshness threshold (default: 24 hours)

**Processing:**
1. Query all devices in scope via NinjaRMM API
2. For each device:
   - Check each WAF field for:
     - Has value (not null/empty)
     - Value format valid
     - Timestamp recent (for date fields)
3. Calculate statistics:
   - Total devices checked
   - Fields populated per device
   - Population rate per field
   - Overall population rate
   - Devices with stale data
   - Devices with missing critical fields

**Outputs:**

**Console Report:**
```
WAF Field Population Check
=========================
Run Date: 2026-02-09 20:15:00
Devices Checked: 245
Fields Checked: 50

Overall Statistics:
- Population Rate: 97.2% (Target: 96%+) ✓
- Stale Data: 3 devices (1.2%)
- Missing Critical: 2 devices (0.8%)

Status: PASS

Field Statistics:
Field                    | Populated | Rate   | Status
------------------------|-----------|--------|--------
opsHealthScore          | 245/245   | 100%   | ✓
opsStabilityScore       | 243/245   | 99.2%  | ✓
opsPerformanceScore     | 244/245   | 99.6%  | ✓
[... additional fields ...]

Devices with Issues:
- Device-001: Missing 5 fields (2% population)
- Device-042: Stale data (last update 3 days ago)
- Device-089: Missing critical field: opsHealthScore

Recommendations:
1. Investigate Device-001 (agent offline?)
2. Check script execution on Device-042
3. Verify monitoring enabled on Device-089
```

**CSV Export:**
```csv
Device,FieldsPopulated,PopulationRate,StaleFields,MissingCritical,Status
Device-001,45,90%,0,1,WARNING
Device-002,50,100%,0,0,OK
[... all devices ...]
```

**JSON Export:**
```json
{
  "runDate": "2026-02-09T20:15:00Z",
  "devicesChecked": 245,
  "fieldsChecked": 50,
  "overallPopulationRate": 97.2,
  "status": "PASS",
  "devices": [
    {
      "name": "Device-001",
      "fieldsPopulated": 45,
      "populationRate": 90.0,
      "staleFields": 0,
      "missingCritical": 1,
      "status": "WARNING"
    }
  ]
}
```

### Usage

**Command Line:**
```powershell
.\Check-WAFFieldPopulation.ps1 -DeviceGroup "All Devices" -OutputFormat "Console"
.\Check-WAFFieldPopulation.ps1 -ExportCSV "population-report.csv"
.\Check-WAFFieldPopulation.ps1 -ExportJSON "population-report.json" -Verbose
```

**Scheduled Execution:**
- Run daily at 6 AM
- Email report to WAF admin
- Alert if population rate <96%

---

## Tool 2: Script Execution Monitor

### Purpose
Verifies that WAF automation scripts are executing successfully and on schedule.

### Target Metrics
- Script success rate: **95%+**
- On-time execution: **95%+**
- Average duration: **<30 seconds**
- Timeout rate: **<2%**

### Functionality

**Inputs:**
- Date range (default: last 7 days)
- Script list (default: all WAF scripts)
- Device group or specific devices

**Processing:**
1. Query automation activity logs via API
2. For each script:
   - Count total executions
   - Count successful executions
   - Count failures (by error type)
   - Calculate average duration
   - Identify timeouts
   - Check schedule adherence
3. Identify problematic patterns:
   - Scripts with high failure rate
   - Devices with consistent failures
   - Time-based patterns (specific hours)

**Outputs:**

**Console Report:**
```
WAF Script Execution Monitor
============================
Run Date: 2026-02-09 20:15:00
Date Range: 2026-02-02 to 2026-02-09 (7 days)
Devices: 245
Scripts: 13

Overall Statistics:
- Total Executions: 10,115
- Successful: 9,847 (97.4%) ✓
- Failed: 268 (2.6%)
- Timeouts: 45 (0.4%) ✓
- Avg Duration: 24s ✓

Status: PASS

Script Performance:
Script                       | Exec | Success | Fail | Avg Time | Status
----------------------------|------|---------|------|----------|--------
01_Health_Score_Calculator  | 245  | 245     | 0    | 12s      | ✓
02_System_Stability         | 1,470| 1,458   | 12   | 28s      | ✓
03_Performance_Metrics      | 1,470| 1,465   | 5    | 22s      | ✓
06_Update_Compliance        | 735  | 701     | 34   | 78s      | ⚠
[... additional scripts ...]

Devices with Issues:
- Device-023: 12 script failures (8 different scripts)
- Device-067: Update_Compliance always fails
- Device-134: All scripts timeout

Failure Analysis:
Error Type                  | Count | %
---------------------------|-------|-----
Timeout                    | 45    | 16.8%
Access Denied              | 12    | 4.5%
WMI Query Failed           | 89    | 33.2%
Network Error              | 34    | 12.7%
Other                      | 88    | 32.8%

Recommendations:
1. Investigate Update_Compliance script timeout (78s avg)
2. Check WMI health on Device-067
3. Review Device-134 agent health (all timeouts)
4. Consider increasing timeout for script 06
```

### Usage

**Command Line:**
```powershell
.\Monitor-WAFScriptExecution.ps1 -Days 7
.\Monitor-WAFScriptExecution.ps1 -Days 30 -ExportHTML "execution-report.html"
.\Monitor-WAFScriptExecution.ps1 -Script "06_Update_Compliance" -Detailed
```

**Scheduled Execution:**
- Run daily at 7 AM
- Weekly summary email
- Alert if success rate <95%

---

## Tool 3: Performance Analyzer

### Purpose
Analyzes WAF script performance impact on devices and identifies optimization opportunities.

### Target Metrics
- Average execution time: **<30 seconds**
- 95th percentile: **<60 seconds**
- CPU impact: **<5%**
- Memory impact: **<150 MB**

### Functionality

**Inputs:**
- Date range (default: last 7 days)
- Performance threshold (default: 30s)
- Device group

**Processing:**
1. Collect execution duration data
2. Calculate statistics:
   - Mean, median, 95th percentile
   - Trend analysis (improving/degrading)
   - Outlier identification
3. Identify slow scripts
4. Analyze patterns:
   - Time of day impact
   - Device characteristics (specs)
   - Concurrent execution impact

**Outputs:**

**Console Report:**
```
WAF Performance Analysis
========================
Run Date: 2026-02-09 20:15:00
Date Range: Last 7 days
Executions Analyzed: 10,115

Performance Summary:
- Avg Duration: 24.3s (Target: <30s) ✓
- Median: 18s
- 95th Percentile: 52s (Target: <60s) ✓
- Max: 118s

Status: PASS

Script Performance Distribution:
Script                       | Avg  | P50  | P95  | Max  | Trend
----------------------------|------|------|------|------|-------
01_Health_Score_Calculator  | 12s  | 11s  | 15s  | 22s  | ➚ +2s
02_System_Stability         | 28s  | 24s  | 45s  | 78s  | ➙ stable
03_Performance_Metrics      | 22s  | 19s  | 35s  | 56s  | ➙ stable
06_Update_Compliance        | 78s  | 72s  | 105s | 118s | ➘ -5s
[... additional scripts ...]

Slowest Executions:
1. Device-089 / Update_Compliance: 118s
2. Device-023 / System_Stability: 98s
3. Device-134 / Performance_Metrics: 87s

Performance Trends (vs last week):
- Overall: -2% (improvement)
- Health_Score: +15% (degrading)
- Update_Compliance: -6% (improving)

Recommendations:
1. Optimize Health_Score_Calculator (trending slower)
2. Investigate Device-089 (consistently slowest)
3. Consider timeout increase for Update_Compliance
4. Review concurrent execution on Device-023
```

**Chart Output (HTML):**
- Execution time distribution histogram
- Trend line over time
- Per-script performance comparison
- Device performance heatmap

### Usage

**Command Line:**
```powershell
.\Analyze-WAFPerformance.ps1 -Days 7
.\Analyze-WAFPerformance.ps1 -Days 30 -ExportHTML "performance.html"
.\Analyze-WAFPerformance.ps1 -Script "06_Update_Compliance" -Detailed
```

---

## Tool 4: Data Quality Validator

### Purpose
Validates logical consistency and accuracy of WAF data across all fields.

### Target Metrics
- Data consistency: **98%+**
- Logical errors: **<2%**
- Value anomalies: **<5%**

### Functionality

**Inputs:**
- Device group or all devices
- Validation rules (default: built-in)

**Processing:**

**Validation Rules:**

1. **Range Validation:**
   - Health scores: 0-100
   - Percentages: 0-100
   - Counts: 0 or positive

2. **Logical Consistency:**
   - If opsHealthScore exists, component scores should exist
   - If secAntivirusEnabled = false, opsSecurityScore should be low
   - If capDiskFreePercent <10%, opsCapacityScore should be low
   - If statCrashCount30d >10, opsStabilityScore should be low

3. **Temporal Consistency:**
   - opsLastHealthCheck should be <24 hours old
   - If secLastSecurityScan >7 days, flag as stale
   - If updLastPatchCheck >7 days, flag issue

4. **Data Anomalies:**
   - Sudden score drops >30 points
   - Impossible values (e.g., disk >100%)
   - Missing dependent fields
   - Mismatched status and score

**Outputs:**

**Console Report:**
```
WAF Data Quality Validation
===========================
Run Date: 2026-02-09 20:15:00
Devices Validated: 245
Validation Rules: 25

Overall Quality:
- Consistency: 98.7% (Target: 98%+) ✓
- Logical Errors: 4 (1.6%) ✓
- Anomalies: 8 (3.3%) ✓

Status: PASS

Validation Results:
Rule                         | Pass | Fail | %
----------------------------|------|------|-----
Score range (0-100)         | 245  | 0    | 100%
Component scores present    | 243  | 2    | 99.2%
Status matches score        | 241  | 4    | 98.4%
Timestamps recent (<24h)    | 242  | 3    | 98.8%
Logical consistency         | 237  | 8    | 96.7%
[... additional rules ...]

Logical Errors Found:
1. Device-012: High health score (85) but AV disabled
2. Device-034: Low capacity score (45) but disk 75% free
3. Device-089: Status "Healthy" but score 58
4. Device-156: High crash count (15) but stability score 90

Anomalies Detected:
1. Device-023: Health score dropped from 92 to 58 overnight
2. Device-067: Disk free shows 120% (impossible)
3. Device-134: All scores exactly 50 (suspicious)
4. Device-189: No data updates in 5 days (stale)

Recommendations:
1. Review scoring calculation for Device-012
2. Investigate data collection on Device-067
3. Check script execution on Device-134
4. Verify agent health on Device-189
```

### Usage

**Command Line:**
```powershell
.\Validate-WAFDataQuality.ps1
.\Validate-WAFDataQuality.ps1 -DeviceGroup "Production" -ExportCSV "quality.csv"
.\Validate-WAFDataQuality.ps1 -Device "Device-067" -Verbose
```

---

## Tool Implementation Plan

### Phase 1: Design & Specification
- [x] Tool specifications documented
- [ ] API requirements defined
- [ ] Output formats finalized
- [ ] Test data prepared

### Phase 2: Development
- [ ] Tool 1: Field Population Checker (4 hours)
- [ ] Tool 2: Script Execution Monitor (6 hours)
- [ ] Tool 3: Performance Analyzer (6 hours)
- [ ] Tool 4: Data Quality Validator (8 hours)

### Phase 3: Testing
- [ ] Unit testing (each tool)
- [ ] Integration testing (tool chain)
- [ ] Performance testing (large datasets)
- [ ] User acceptance testing

### Phase 4: Deployment
- [ ] Documentation completed
- [ ] Scheduled automation configured
- [ ] Alert thresholds set
- [ ] Team training completed

**Total Effort:** 28-32 hours

---

## Usage Patterns

### Daily Operations
```powershell
# Morning health check
.\Check-WAFFieldPopulation.ps1
.\Monitor-WAFScriptExecution.ps1 -Days 1
```

### Weekly Review
```powershell
# Comprehensive weekly report
.\Check-WAFFieldPopulation.ps1 -ExportHTML "weekly-population.html"
.\Monitor-WAFScriptExecution.ps1 -Days 7 -ExportHTML "weekly-execution.html"
.\Analyze-WAFPerformance.ps1 -Days 7 -ExportHTML "weekly-performance.html"
.\Validate-WAFDataQuality.ps1 -ExportHTML "weekly-quality.html"
```

### Troubleshooting
```powershell
# Investigate specific device
.\Check-WAFFieldPopulation.ps1 -Device "Device-089" -Verbose
.\Monitor-WAFScriptExecution.ps1 -Device "Device-089" -Days 30
.\Validate-WAFDataQuality.ps1 -Device "Device-089" -Verbose
```

---

## Integration with WAF

These tools integrate with existing WAF infrastructure:

**Data Source:** NinjaRMM API
**Output:** Console, CSV, JSON, HTML
**Scheduling:** NinjaRMM automation or Windows Task Scheduler
**Alerting:** Email, NinjaRMM alerts, webhook
**Storage:** Local files, shared drive, cloud storage

---

**Last Updated:** February 9, 2026, 8:16 PM CET
