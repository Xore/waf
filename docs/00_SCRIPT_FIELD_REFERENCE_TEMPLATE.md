# Script-Field Reference Matrix - TEMPLATE
**Purpose:** Shows bidirectional relationships between scripts and custom fields  
**Note:** This is a template showing the structure. Actual data will be populated during audit.

---

## How to Use This Reference

### Three Views Available:

1. **Script-Centric View** - "What fields does Script X use?"
2. **Field-Centric View** - "What scripts use Field Y?"
3. **Relationship Map** - Visual overview of all dependencies

### Relationship Types:
- **[P] Populates** - Script writes/sets the field value
- **[R] Requires** - Script reads/depends on the field value
- **[P+R] Both** - Script both reads and writes the field

---

# View 1: Script-to-Field Matrix

## Script 4: Calculate Operational Scores
**Purpose:** Calculates health, performance, and risk scores for devices  
**Category:** Core Monitoring  
**Documentation:** [Link to script doc]

### Fields POPULATED by Script 4:

| Field Name | Type | Use Case | Calculation Method | Doc Link |
|------------|------|----------|-------------------|----------|
| OPSHealthScore | Number (0-100) | Overall device health metric | Weighted avg: CPU(30%) + Memory(30%) + Disk(40%) | [01_OPS](core/01_OPS_Operational_Scores.md) |
| OPSPerformanceScore | Number (0-100) | Device performance rating | Based on response times and throughput | [01_OPS](core/01_OPS_Operational_Scores.md) |
| OPSRiskScore | Number (0-100) | Security and stability risk | Combines vulnerability count, patch status, uptime | [01_OPS](core/01_OPS_Operational_Scores.md) |
| OPSLastCalculated | DateTime | Timestamp of last calculation | Current datetime when script runs | [01_OPS](core/01_OPS_Operational_Scores.md) |

### Fields REQUIRED by Script 4 (Dependencies):

| Field Name | Type | Why Required | Populated By | If Missing |
|------------|------|--------------|--------------|------------|
| STATCPUAverage | Number | CPU component of health score | Script 3 | Uses 0, logs warning |
| STATMemoryAverage | Number | Memory component of health score | Script 3 | Uses 0, logs warning |
| STATDiskUsage | Number | Disk component of health score | Script 3 | Uses 0, logs warning |
| BASEBaselineEstablished | Boolean | Determines if baseline comparison possible | Script 8 | Skips baseline comparison |

### Use Cases:

1. **Health Monitoring Dashboard**
   - OPSHealthScore displayed on main dashboard
   - Color-coded: Green (>80), Yellow (50-80), Red (<50)
   - Updated every 15 minutes

2. **Automated Alerting**
   - Triggers alert if OPSHealthScore < 70
   - Critical alert if < 50
   - Email notification to admin

3. **Reporting**
   - Weekly health report uses OPSHealthScore
   - Trend analysis over time
   - Executive dashboard summary

4. **Automation Triggers**
   - OPSHealthScore < 50 triggers auto-remediation
   - Initiates disk cleanup, memory optimization
   - Logs remediation actions

### Script Execution:
- **Frequency:** Every 15 minutes
- **Duration:** ~2-5 seconds per device
- **Priority:** High
- **Error Handling:** Logs errors, uses last known good values

---

## Script 8: Establish Device Baseline
**Purpose:** Creates initial performance baseline for new devices  
**Category:** Baseline Management  
**Documentation:** [Link to script doc]

### Fields POPULATED by Script 8:

| Field Name | Type | Use Case | Calculation Method | Doc Link |
|------------|------|----------|-------------------|----------|
| BASEBaselineEstablished | Boolean | Indicates baseline exists | Set to true after 7 days of data | [07_BASE](core/07_BASE_Baseline_Management.md) |
| BASEBaselineDate | DateTime | When baseline was established | Date after 7-day monitoring period | [07_BASE](core/07_BASE_Baseline_Management.md) |
| BASECPUBaseline | Number | Normal CPU usage baseline | Average of 7 days, excluding outliers | [07_BASE](core/07_BASE_Baseline_Management.md) |
| BASEMemoryBaseline | Number | Normal memory usage baseline | Average of 7 days, excluding outliers | [07_BASE](core/07_BASE_Baseline_Management.md) |

### Fields REQUIRED by Script 8 (Dependencies):

| Field Name | Type | Why Required | Populated By | If Missing |
|------------|------|--------------|--------------|------------|
| STATCPUAverage | Number | Builds CPU baseline from history | Script 3 | Cannot establish baseline |
| STATMemoryAverage | Number | Builds memory baseline from history | Script 3 | Cannot establish baseline |
| STATFirstSeen | DateTime | Determines if 7 days elapsed | Script 3 | Uses device install date |

### Use Cases:

1. **New Device Onboarding**
   - Automatically establishes baseline after 7 days
   - No manual configuration needed
   - Adapts to specific device workload

2. **Drift Detection**
   - BASEBaselineEstablished enables drift monitoring
   - Script 12 uses baseline for comparison
   - Alerts on significant deviations

---

# View 2: Field-to-Script Matrix

## OPSHealthScore
**Type:** Number (0-100)  
**Category:** Operational Scores  
**Defined In:** [01_OPS_Operational_Scores.md](core/01_OPS_Operational_Scores.md)  
**Purpose:** Single metric representing overall device health

### POPULATED BY:

| Script | Script Name | How Calculated | Frequency | Conditions |
|--------|-------------|----------------|-----------|------------|
| Script 4 | Calculate Operational Scores | Weighted avg of CPU/Memory/Disk | Every 15 min | Always runs |

**Calculation Formula:**
```
OPSHealthScore = (CPU_Score * 0.3) + (Memory_Score * 0.3) + (Disk_Score * 0.4)

Where:
  CPU_Score = 100 - STATCPUAverage
  Memory_Score = 100 - STATMemoryAverage  
  Disk_Score = 100 - STATDiskUsage
```

### CONSUMED BY (Scripts that read this field):

| Script | Script Name | How Used | Action Taken | Threshold |
|--------|-------------|----------|--------------|----------|
| Script 18 | Health Alert Generator | Triggers alerts | Email notification if low | < 70 |
| Script 23 | Weekly Report Generator | Includes in report | Adds to PDF report | Any value |
| Script 45 | Auto-Remediation | Initiates cleanup | Runs disk cleanup, memory opt | < 50 |
| Script 52 | Dashboard Updater | Displays on dashboard | Color-coded visualization | Any value |

### Use Cases:

#### 1. Executive Dashboard
**Who:** IT Management  
**Frequency:** Real-time  
**Purpose:** At-a-glance health status

```
IF OPSHealthScore >= 80 THEN
  Display GREEN indicator "Healthy"
ELSE IF OPSHealthScore >= 50 THEN
  Display YELLOW indicator "Warning"
ELSE
  Display RED indicator "Critical"
END IF
```

#### 2. Automated Alerting
**Who:** IT Operations  
**Frequency:** Every 15 minutes  
**Purpose:** Proactive issue detection

```
IF OPSHealthScore < 70 THEN
  Send warning email
  Log event
END IF

IF OPSHealthScore < 50 THEN
  Send critical alert
  Page on-call engineer
  Trigger Script 45 (Auto-remediation)
END IF
```

#### 3. Capacity Planning
**Who:** IT Planning  
**Frequency:** Monthly  
**Purpose:** Identify devices needing upgrade

```
Query devices WHERE OPSHealthScore < 60 for 30 days
Generate upgrade recommendation report
Calculate ROI for hardware refresh
```

#### 4. SLA Reporting
**Who:** Service Delivery  
**Frequency:** Monthly  
**Purpose:** Track service level compliance

```
SLA Target: 95% of devices with OPSHealthScore > 70

Monthly Report:
  Total Devices: [count]
  Above Target: [count] ([percent]%)
  Below Target: [count] ([percent]%)
  SLA Status: [Met/Missed]
```

### Related Fields:

**Feeds Into (depends on):**
- STATCPUAverage (30% weight)
- STATMemoryAverage (30% weight)
- STATDiskUsage (40% weight)

**Feeds From (influences):**
- OPSPerformanceScore (correlation analysis)
- OPSRiskScore (combined health/risk matrix)

### Data Flow:

```
Script 3 (Telemetry Collection)
    ↓
  STATCPUAverage
  STATMemoryAverage
  STATDiskUsage
    ↓
Script 4 (Calculate Scores)
    ↓
  OPSHealthScore
    ↓
  [→ Script 18: Alerting]
  [→ Script 23: Reporting]
  [→ Script 45: Auto-remediation]
  [→ Script 52: Dashboard]
```

### Historical Data:
- **Retention:** 90 days
- **Aggregation:** Daily average stored
- **Trending:** Used for predictive analysis

---

## BASEBaselineEstablished
**Type:** Boolean (True/False)  
**Category:** Baseline Management  
**Defined In:** [07_BASE_Baseline_Management.md](core/07_BASE_Baseline_Management.md)  
**Purpose:** Indicates if performance baseline has been established

### POPULATED BY:

| Script | Script Name | Logic | Frequency | Conditions |
|--------|-------------|-------|-----------|------------|
| Script 8 | Establish Device Baseline | Sets to True after 7 days of monitoring | Hourly | Device age > 7 days AND sufficient data |

**Logic:**
```
IF device_age >= 7 days 
   AND data_points >= 672 (7 days * 24 hours * 4 samples/hour)
   AND no_major_incidents
THEN
  BASEBaselineEstablished = True
  Calculate baseline metrics
END IF
```

### CONSUMED BY:

| Script | Script Name | How Used | Action if True | Action if False |
|--------|-------------|----------|----------------|----------------|
| Script 4 | Calculate Scores | Enables baseline comparison | Compare to baseline | Use absolute thresholds |
| Script 12 | Drift Detection | Required to run | Monitors for drift | Skips drift detection |
| Script 15 | Performance Analysis | Determines analysis type | Baseline-relative analysis | Absolute value analysis |
| Script 22 | Anomaly Detection | ML model selection | Use baseline model | Use absolute model |

### Use Cases:

#### 1. New Device Onboarding
**Timeline:** First 7 days

```
Day 0: Device deployed
  BASEBaselineEstablished = False
  Monitoring begins
  Collecting data points

Day 1-6: Learning phase
  BASEBaselineEstablished = False
  Continue data collection
  No drift detection

Day 7: Baseline ready
  Script 8 runs
  BASEBaselineEstablished = True
  Drift detection enabled
```

#### 2. Conditional Script Execution
**Purpose:** Scripts adapt behavior based on baseline status

```powershell
IF $BASEBaselineEstablished -eq $true THEN
    # Use baseline-relative thresholds
    $threshold = $BASECPUBaseline * 1.5
    IF $currentCPU > $threshold THEN
        Alert "CPU usage 50% above baseline"
    END IF
ELSE
    # Use absolute thresholds
    IF $currentCPU > 90 THEN
        Alert "CPU usage above 90%"
    END IF
END IF
```

### Related Fields:
- BASEBaselineDate (when baseline was set)
- BASECPUBaseline (baseline CPU value)
- BASEMemoryBaseline (baseline memory value)
- BASEDiskBaseline (baseline disk value)

---

# View 3: Relationship Map

## Visual Dependency Map

### Legend:
- **[P]** = Populates/Writes
- **[R]** = Requires/Reads  
- **[P+R]** = Both
- **→** = Data flow direction

### Core Operational Flow:

```
[Script 3: Telemetry Collection]
    [P] → STATCPUAverage
    [P] → STATMemoryAverage
    [P] → STATDiskUsage
          ↓
          [R]
          ↓
[Script 4: Calculate Scores]
    [P] → OPSHealthScore
    [P] → OPSPerformanceScore
    [P] → OPSRiskScore
          ↓
          [R]
          ↓
    [→ Script 18: Alerting]
    [→ Script 23: Reporting]
    [→ Script 45: Auto-Remediation]
```

### Baseline Establishment Flow:

```
[Script 3: Telemetry Collection]
    [P] → STATCPUAverage (7 days)
    [P] → STATMemoryAverage (7 days)
          ↓
          [R]
          ↓
[Script 8: Establish Baseline]
    [P] → BASEBaselineEstablished = True
    [P] → BASECPUBaseline
    [P] → BASEMemoryBaseline
          ↓
          [R]
          ↓
[Script 12: Drift Detection]
    [P] → DRIFTDetected
    [P] → DRIFTPercentage
```

### Security Monitoring Flow:

```
[Script 15: Security Scan]
    [P] → SECLastScanDate
    [P] → SECVulnerabilityCount
    [P] → SECPatchStatus
          ↓
          [R]
          ↓
    [→ Script 4: (Used in OPSRiskScore)]
    [→ Script 30: Alert if scan overdue]
    [→ Script 31: Vulnerability report]
```

---

## Dependency Chains

### Chain 1: Health Score Calculation
```
Script 3 → STAT fields → Script 4 → OPS fields → Scripts 18,23,45,52
```

### Chain 2: Baseline and Drift
```
Script 3 → STAT fields → Script 8 → BASE fields → Script 12 → DRIFT fields
```

### Chain 3: Security Risk
```
Script 15 → SEC fields → Script 4 → OPSRiskScore → Script 18 (alerts)
```

---

## Machine-Readable Format

### JSON Structure:

```json
{
  "scripts": [
    {
      "script_id": 4,
      "script_name": "Calculate Operational Scores",
      "populates": [
        {
          "field": "OPSHealthScore",
          "type": "Number",
          "calculation": "Weighted average",
          "use_case": "Overall device health metric"
        }
      ],
      "requires": [
        {
          "field": "STATCPUAverage",
          "type": "Number",
          "populated_by": 3,
          "required": true,
          "fallback": "Use 0, log warning"
        }
      ]
    }
  ],
  "fields": [
    {
      "field_name": "OPSHealthScore",
      "type": "Number",
      "category": "Operational Scores",
      "populated_by": [4],
      "consumed_by": [18, 23, 45, 52],
      "use_cases": [
        "Dashboard display",
        "Alerting",
        "Reporting",
        "Auto-remediation trigger"
      ]
    }
  ]
}
```

---

**This template will be populated with actual data during the audit process.**  
**Last Updated:** February 2, 2026  
**Status:** Template - Awaiting Data Population
