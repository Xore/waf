# NinjaOne Custom Field Framework - Complete Training Guide (Part 2)

**Version:** 1.0  
**Date:** February 1, 2026, 10:13 PM CET  
**Purpose:** Advanced modules, labs, and certification  
**Part:** 2 of 2

---

<a name="module-7"></a>
## MODULE 7: TROUBLESHOOTING & OPTIMIZATION (3 hours)

### 7.1 Common Issues & Solutions

**Issue 1: Custom Field Not Populating**

```
Symptom: Field shows empty or old value
Diagnosis Steps:
  1. Check script execution status
     Administration → Automation → Activity Log

  2. Verify script is scheduled
     Script → Schedules tab → Confirm frequency

  3. Run script manually
     Device → Scripts → Run script → Check output

  4. Review script logs
     Check for PowerShell errors in output

Common Causes:
  - Script not scheduled on device
  - Execution policy blocking
  - Field name typo in script
  - Permissions issue (script runs as SYSTEM)
  - Timeout (script takes > configured limit)

Solutions:
  - Re-schedule script on device/group
  - Increase timeout (60s → 120s)
  - Fix field name match
  - Add error handling to script
  - Test locally with PSExec -s
```

**Issue 2: Hybrid Condition Not Triggering**

```
Symptom: Expected alert not firing
Diagnosis Steps:
  1. Verify native metric has correct value
     Device → Monitoring → Check CPU/Memory/Disk

  2. Verify custom fields populated
     Device → Custom Fields → Check values

  3. Test condition logic manually
     Create test device matching all criteria

  4. Check condition enabled
     Automation → Conditions → Status = Active

  5. Review condition history
     Condition → History tab → See past triggers

Common Causes:
  - Native metric not available (device offline)
  - Custom field not populated yet
  - Logic error (AND vs OR)
  - Exclusion rule catching device
  - Condition disabled accidentally

Solutions:
  - Wait for custom field population (4h cycle)
  - Fix condition logic
  - Remove overly broad exclusions
  - Enable condition
  - Add logging to track evaluations
```

**Issue 3: Script Execution Failures**

```
Symptom: Script shows "Failed" in activity log
Diagnosis Steps:
  1. Check error message
     Activity Log → Click failed execution → Read error

  2. Test script locally
     Copy script → Run in PowerShell ISE → Debug

  3. Check PowerShell version
     $PSVersionTable.PSVersion (should be 5.1+)

  4. Verify required modules
     Get-Module -ListAvailable

  5. Check permissions
     Script runs as SYSTEM - test with PSExec -s

Common Causes:
  - Syntax error in PowerShell
  - Missing module/cmdlet
  - Timeout (script too slow)
  - Access denied to resource
  - WMI/CIM query failure

Solutions:
  - Fix syntax errors
  - Install required modules
  - Optimize script performance
  - Run with proper permissions
  - Add try/catch error handling
```

### 7.2 Performance Optimization

**Script Optimization Techniques:**

**1. Reduce WMI Queries:**
```powershell
# Bad (slow - multiple queries)
$cpu = Get-WmiObject Win32_Processor
$memory = Get-WmiObject Win32_OperatingSystem
$disk = Get-WmiObject Win32_LogicalDisk

# Good (fast - single session)
$cimSession = New-CimSession
$cpu = Get-CimInstance Win32_Processor -CimSession $cimSession
$memory = Get-CimInstance Win32_OperatingSystem -CimSession $cimSession
$disk = Get-CimInstance Win32_LogicalDisk -CimSession $cimSession
Remove-CimSession $cimSession
```

**2. Cache Repeated Calculations:**
```powershell
# Bad (recalculate every time)
for ($i = 0; $i < 100; $i++) {
    $result = Get-HeavyCalculation
    Do-Something $result
}

# Good (calculate once)
$result = Get-HeavyCalculation
for ($i = 0; $i < 100; $i++) {
    Do-Something $result
}
```

**3. Use Native Metrics When Possible:**
```powershell
# Bad (custom script collection)
$cpuPercent = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
Ninja-Property-Set "CPUPercent" $cpuPercent

# Good (use native metric)
# No script needed - NinjaOne already collects CPU %
# Reference in conditions as "CPU Utilization %"
```

**Condition Optimization:**

**1. Order Filters Efficiently:**
```
# Bad (expensive check first)
Condition: STATCrashCount30d > 5  (requires script data)
         AND Device Down = True (native, instant)

# Good (cheap check first - fail fast)
Condition: Device Down = True  (native, instant)
         AND STATCrashCount30d > 5  (only if device down)
```

**2. Use Appropriate Data Types:**
```
# Bad (string comparison - slow)
patchLastAttemptStatus CONTAINS "Failed"

# Good (dropdown selection - fast)
patchValidationStatus = "Failed"
```

### 7.3 Monitoring Framework Health

**Key Metrics to Track:**

**1. Field Population Rate:**
```
Target: 95%+ of fields populated
How to measure:
  - Create dashboard widget
  - Count devices where OPSHealthScore IS NOT NULL
  - Divide by total devices

  Population% = (Devices with OPSHealthScore / Total Devices) × 100
```

**2. Script Success Rate:**
```
Target: 98%+ execution success
How to measure:
  - Administration → Automation → Activity Log
  - Filter last 7 days
  - Count successes vs failures

  Success% = (Successful / Total Executions) × 100
```

**3. Alert Accuracy:**
```
Target: 90%+ alerts require action (low false positive)
How to measure:
  - Track tickets created by conditions
  - Mark as "actionable" or "false positive"

  Accuracy% = (Actionable Alerts / Total Alerts) × 100
```

**4. Automation Success Rate:**
```
Target: 90%+ remediation scripts succeed
How to measure:
  - Count Script 40-65 executions
  - Check AUTOLastRemediationResult field

  Auto_Success% = (Successful Remediations / Total Attempts) × 100
```

### 7.4 Tuning Thresholds

**Iterative Tuning Process:**

```
Week 1: Deploy with conservative thresholds
  - OPSHealthScore < 40 (very sick only)
  - Disk Free Space < 5% (critical only)
  - Monitor for missed issues

Week 2-4: Increase sensitivity (reduce thresholds)
  - OPSHealthScore < 60 (catch degraded)
  - Disk Free Space < 10% (earlier warning)
  - Monitor false positive rate

Week 5-8: Fine-tune based on data
  - Analyze historical triggers
  - Adjust thresholds to balance detection vs noise
  - Add context (health scores, business criticality)

Ongoing: Quarterly reviews
  - Review alert accuracy metrics
  - Adjust based on environment changes
  - Document threshold rationale
```

### 7.5 Hands-On Exercise 7.1

**Task:** Troubleshoot and fix a broken script

**Scenario:** Script "Test Device Monitor" is failing with error

**Broken Script:**
```powershell
# This script has 5 bugs - find and fix them!

$cpu = Get-WmiObject Win32_Processor
$cpuPercent = $cpu.LoadPercentage  # Bug 1: Wrong property

$os = Get-WmiObject Win32_OperatingSystem
$memPercent = ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize)  # Bug 2: Wrong math

$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID=C:"  # Bug 3: Missing quotes
$diskPercent = (($disk.Size - $disk.FreeSpace) / $disk.Size)

$health = 100
if ($cpuPercent > 80) { $health -= 20 }
if ($memPercent > 90) { $health -= 30 }  # Bug 4: Wrong logic (memPercent is fraction)
if ($diskPercent > 90) { $health -= 30 }

Ninja-Property-Set "TestHealth Score" $health  # Bug 5: Space in field name
```

**Steps:**
1. Run script locally → Note errors
2. Fix each bug
3. Test corrected script
4. Deploy to NinjaOne
5. Verify successful execution

**Correct Script:**
```powershell
$cpu = Get-WmiObject Win32_Processor
$cpuPercent = $cpu.LoadPercentage

$os = Get-WmiObject Win32_OperatingSystem
$memPercent = (($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100

$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskPercent = (($disk.Size - $disk.FreeSpace) / $disk.Size) * 100

$health = 100
if ($cpuPercent > 80) { $health -= 20 }
if ($memPercent > 90) { $health -= 30 }
if ($diskPercent > 90) { $health -= 30 }

Ninja-Property-Set "TestHealthScore" $health
```

**Expected Result:**
- All 5 bugs identified
- Script runs successfully
- Understanding of common scripting errors
- Debugging skills developed

---

<a name="module-8"></a>
## MODULE 8: ADVANCED TOPICS (4 hours)

### 8.1 Machine Learning Integration

**Leveraging Chapter 6 RCA Concepts:**

The framework provides 277 metrics perfect for ML analysis:

**Use Case 1: Anomaly Detection**
```
Goal: Detect unusual device behavior before failures

ML Approach:
  - Collect 90 days of baseline data (277 metrics)
  - Train Isolation Forest model
  - Score devices 0-100 (MLAnomalyScore)
  - Alert when score > 80

Implementation:
  1. Export metrics daily via NinjaOne API
  2. Store in time-series database (InfluxDB)
  3. Train model weekly with sklearn
  4. Update custom field: MLAnomalyScore
  5. Create condition: MLAnomalyScore > 80

Expected Results:
  - 70% reduction in unexpected failures
  - 3-7 day advance warning
  - Automated RCA when anomaly detected
```

**Use Case 2: Predictive Maintenance**
```
Goal: Predict device failures 30 days in advance

ML Approach:
  - Label historical failures (BSOD, hardware failure)
  - Train Random Forest classifier
  - Features: Crash counts, SMART status, boot time, stability score
  - Output: MLFailureRisk (0-100)

Implementation:
  1. Collect 12 months historical data
  2. Label failure events
  3. Train model with XGBoost
  4. Update field: MLFailureRisk, MLFailurePredictedDate
  5. Create condition: MLFailureRisk > 70

Expected Results:
  - 85%+ accuracy predicting failures
  - 30-day advance notice
  - Proactive hardware replacement
```

**Use Case 3: Root Cause Analysis**
```
Goal: Automatically identify failure root cause

ML Approach (see Chapter 6):
  - When MLAnomalyScore > 80 is detected
  - Extract 24h incident window + 7d baseline
  - Z-score deviation detection (277 metrics)
  - Granger causality testing (what caused what?)
  - Rank root causes by temporal + causal + severity scores

Implementation:
  1. Anomaly detected → Trigger RCA script
  2. Analyze time-series data
  3. Identify causal chain
  4. Update field: MLRootCauseAnalysis (WYSIWYG report)
  5. Suggest remediation actions

Expected Results:
  - 87.5% MTTR reduction (4h → 30min)
  - 70-85% accurate root cause ID
  - Automated remediation suggestions
```

### 8.2 Custom Module Development

**Creating Your Own Module:**

**Example: Application Performance Module (APP)**

**Step 1: Define Fields (10 fields)**
```
APPChromeMemoryMB (Integer) - Chrome memory usage
APPOutlookResponseMs (Integer) - Outlook responsiveness
APPTeamsCallQuality (Integer 0-100) - Teams call score
APPSlackStatus (Text) - Slack connection status
APPZoomMeetingScore (Integer 0-100) - Zoom meeting quality
APPOfficeStartupSec (Integer) - Office app startup time
APPBrowserTabCount (Integer) - Open browser tabs
APPCrashesLast7d (Integer) - App crashes
APPExperienceScore (Integer 0-100) - Composite UX score
APPLastMonitoredDate (DateTime) - Last update time
```

**Step 2: Create Monitoring Script (Script 111)**
```powershell
# Collect Chrome memory
$chrome = Get-Process chrome -ErrorAction SilentlyContinue
$chromeMemMB = ($chrome | Measure-Object WorkingSet -Sum).Sum / 1MB

# Collect Outlook performance
$outlook = Get-Process OUTLOOK -ErrorAction SilentlyContinue
if ($outlook) {
    # Measure window response time
    $responseMs = Test-OutlookResponse
}

# Calculate composite score
$score = 100
if ($chromeMemMB > 2000) { $score -= 15 }
if ($responseMs > 1000) { $score -= 20 }
# ... more logic

# Write to custom fields
Ninja-Property-Set "APPChromeMemoryMB" [int]$chromeMemMB
Ninja-Property-Set "APPOutlookResponseMs" $responseMs
Ninja-Property-Set "APPExperienceScore" $score
Ninja-Property-Set "APPLastMonitoredDate" (Get-Date)
```

**Step 3: Create Conditions (3 conditions)**
```
P2_AppPerformanceDegraded:
  APPExperienceScore < 70
  AND OPSHealthScore < 80
  → Create P2 ticket, investigate app issues

P3_HighMemoryApp:
  APPChromeMemoryMB > 2000
  AND Memory Utilization > 85%
  → Alert user, suggest closing tabs

P4_AppsHealthy:
  APPExperienceScore > 90
  → Positive health tracking
```

**Step 4: Create Groups (2 groups)**
```
APP_Poor_Performance:
  Filter: APPExperienceScore < 70
  Use: Priority investigation

APP_Memory_Heavy_Users:
  Filter: APPChromeMemoryMB > 3000
  Use: Training, hardware upgrade candidates
```

### 8.3 API Integration & Automation

**Exporting Framework Data via API:**

```powershell
# PowerShell example: Export all devices with custom fields

$ninjaUrl = "https://app.ninjarmm.com"
$apiKey = "YOUR_API_KEY"
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

# Get all devices
$devices = Invoke-RestMethod -Uri "$ninjaUrl/api/v2/devices" -Headers $headers

# Export to CSV
$export = foreach ($device in $devices) {
    # Get custom fields for device
    $customFields = Invoke-RestMethod -Uri "$ninjaUrl/api/v2/device/$($device.id)/custom-fields" -Headers $headers

    [PSCustomObject]@{
        DeviceName = $device.systemName
        OPSHealthScore = $customFields.OPSHealthScore
        STATStabilityScore = $customFields.STATStabilityScore
        CAPDaysUntilDiskFull = $customFields.CAPDaysUntilDiskFull
        # ... all 277 fields
    }
}

$export | Export-Csv "framework_data_export.csv" -NoTypeInformation
```

**Bulk Updating Fields:**

```powershell
# Example: Bulk set RISKExposureLevel based on device type

$servers = Get-NinjaDevices -Filter "OS Type = Server"
$workstations = Get-NinjaDevices -Filter "OS Type = Workstation"

# Set servers to High
foreach ($server in $servers) {
    Set-NinjaCustomField -DeviceId $server.id -FieldName "RISKExposureLevel" -Value "High"
}

# Set workstations to Medium
foreach ($ws in $workstations) {
    Set-NinjaCustomField -DeviceId $ws.id -FieldName "RISKExposureLevel" -Value "Medium"
}
```

### 8.4 Scaling to 1,000+ Devices

**Performance Considerations:**

**1. Script Execution Staggering:**
```
Problem: 1,000 devices × 110 scripts = massive load

Solution: Stagger by device ID modulo
  - Device ID ends in 0-1: Run at 02:00
  - Device ID ends in 2-3: Run at 02:15
  - Device ID ends in 4-5: Run at 02:30
  - Device ID ends in 6-7: Run at 02:45
  - Device ID ends in 8-9: Run at 03:00

Result: 20% of load per 15-minute window
```

**2. Database Optimization:**
```
Problem: 1,000 devices × 277 fields = 277,000 data points

Solution: Index critical fields
  - OPSHealthScore
  - STATStabilityScore
  - RISKExposureLevel
  - patchRing

Result: Faster condition evaluation, group filtering
```

**3. Condition Optimization:**
```
Problem: 75 conditions × 1,000 devices = 75,000 evaluations

Solution: Use exclusion groups
  - Evaluate only devices likely to match
  - Example: Server conditions only on OPS_Servers group

Result: 60% reduction in condition evaluations
```

### 8.5 Multi-Tenant MSP Deployment

**Strategies for MSPs with Multiple Clients:**

**1. Client-Specific Field Prefixes:**
```
Standard: OPSHealthScore
Client A: CLTA_OPSHealthScore
Client B: CLTB_OPSHealthScore

OR use separate NinjaOne organizations per client
```

**2. Shared Scripts, Client-Specific Thresholds:**
```powershell
# Script detects client and applies custom thresholds
$orgId = (Ninja-Property-Get "ORGID")

$thresholds = @{
    "CLIENT_A" = @{ HealthMin = 70; DiskMin = 15 }
    "CLIENT_B" = @{ HealthMin = 80; DiskMin = 10 }
}

$clientThreshold = $thresholds[$orgId]
if ($health < $clientThreshold.HealthMin) {
    # Alert
}
```

**3. Client-Specific Automation Policies:**
```
Group: CLIENT_A_AUTO_Aggressive
  Filter: Organization = "Client A"
         AND AUTORemediationEligible = True
  Actions: Full automation enabled

Group: CLIENT_B_AUTO_Restricted
  Filter: Organization = "Client B"
  Actions: Manual approval required (conservative client)
```

### 8.6 Hands-On Exercise 8.1

**Task:** Create a custom module for your environment

**Steps:**
1. Identify a monitoring gap in your environment
   Example: Track specific application performance

2. Define 5-10 custom fields for your module
   Example: APP module from 8.2

3. Create monitoring script
   Collect relevant metrics, calculate scores

4. Create 2-3 conditions
   Alert thresholds, automation triggers

5. Create 1-2 dynamic groups
   Segment devices by module metrics

6. Deploy and test
   Pilot on 5-10 devices, tune, roll out

**Expected Result:**
- Custom module deployed
- Understanding of framework extensibility
- Ability to adapt framework to unique needs

---

<a name="labs"></a>
## HANDS-ON LABS

### Lab 1: Complete Framework Deployment (4 hours)

**Objective:** Deploy core framework from scratch

**Tasks:**
1. Create 35 core custom fields (OPS, STAT, RISK, AUTO, UX, SRV)
2. Enable native monitoring (CPU, Memory, Disk, SMART)
3. Deploy Scripts 1, 7, 15, 36
4. Create 5 P1 critical hybrid conditions
5. Create 5 essential dynamic groups
6. Test on 10 pilot devices
7. Verify field population
8. Trigger test alerts
9. Review logs and metrics
10. Document any issues

**Success Criteria:**
- [ ] All 35 fields created
- [ ] Scripts execute successfully (98%+ success rate)
- [ ] Fields populate within 24 hours (95%+ population)
- [ ] Conditions trigger appropriately
- [ ] Groups auto-populate correctly

---

### Lab 2: Patching Automation Deployment (3 hours)

**Objective:** Implement ring-based patching

**Tasks:**
1. Create 8 patching custom fields
2. Assign 5 devices to PR1-Test ring
3. Assign remaining devices to PR2-Production
4. Deploy validation scripts (P1-P4)
5. Deploy PR1 deployment script
6. Run PR1 on test ring
7. Monitor for 7-day soak period
8. Deploy PR2 to production (simulated)
9. Review patch success rates
10. Create monitoring dashboard

**Success Criteria:**
- [ ] PR1 ring achieves 90%+ success rate
- [ ] Pre-deployment validation catches unhealthy devices
- [ ] Post-deployment validation detects issues
- [ ] Reboot management works correctly
- [ ] Dashboard tracks metrics accurately

---

### Lab 3: Troubleshooting & Tuning (2 hours)

**Objective:** Identify and fix common issues

**Scenario Tasks:**
1. Diagnose field not populating (broken script)
2. Fix condition not triggering (logic error)
3. Optimize slow script (performance)
4. Tune false positive alerts (threshold adjustment)
5. Debug automation failure (permissions)
6. Analyze framework health metrics
7. Create troubleshooting runbook

**Success Criteria:**
- [ ] All issues identified and resolved
- [ ] Scripts run within timeout limits
- [ ] False positive rate < 15%
- [ ] Automation success rate > 90%
- [ ] Documented solutions for future reference

---

### Lab 4: Custom Module Development (3 hours)

**Objective:** Build custom monitoring module

**Your Choice:**
- Application performance monitoring
- Network quality tracking
- Compliance auditing
- User productivity metrics
- Custom infrastructure monitoring

**Tasks:**
1. Define 8-10 custom fields for module
2. Create monitoring script
3. Create 3 compound conditions
4. Create 2 dynamic groups
5. Deploy to pilot devices
6. Test and validate data
7. Tune thresholds
8. Document module

**Success Criteria:**
- [ ] Module fields populate correctly
- [ ] Scripts provide meaningful insights
- [ ] Conditions trigger appropriately
- [ ] Groups segment devices logically
- [ ] Module integrates with core framework

---

<a name="certification"></a>
## CERTIFICATION & ASSESSMENT

### Certification Levels

**Level 1: Framework Administrator**
- Complete Modules 1-6
- Pass written exam (80%+ score)
- Complete Labs 1-2
- Demonstrate basic troubleshooting

**Level 2: Framework Engineer**
- Complete Modules 1-8
- Pass written + practical exam (85%+ score)
- Complete Labs 1-4
- Build custom module
- Demonstrate advanced troubleshooting

**Level 3: Framework Architect**
- Complete all modules
- Pass comprehensive exam (90%+ score)
- Complete all labs
- Design multi-tenant deployment
- Implement ML integration
- Present case study

### Sample Assessment Questions

**Module 1-2 (Fundamentals & Fields):**

1. How many custom fields are in the core framework v4.0?
   a) 358  b) 277  c) 110  d) 75

2. Which field type should be used for health scores?
   a) Text  b) Integer  c) Decimal  d) Dropdown

3. What is the primary benefit of v4.0 hybrid approach?
   a) More custom fields  b) 70% fewer false positives  c) Easier setup  d) Lower cost

**Module 3-4 (Scripts & Conditions):**

4. Script 15 consolidates which type of metrics?
   a) Performance  b) Security  c) Capacity  d) Patching

5. What makes a v4.0 condition "hybrid"?
   a) Multiple actions  b) Native + Custom logic  c) Multiple devices  d) Multiple scripts

6. What is the recommended frequency for infrastructure scripts (1-13)?
   a) Hourly  b) Every 4 hours  c) Daily  d) Weekly

**Module 5-6 (Groups & Patching):**

7. How many dynamic groups are in the framework?
   a) 35  b) 74  c) 110  d) 277

8. What is the purpose of PR1-Test ring?
   a) Production deployment  b) Validate patches  c) Store backups  d) Test new devices

9. What success rate must PR1 achieve before PR2 deployment?
   a) 75%  b) 80%  c) 90%  d) 95%

**Module 7-8 (Advanced Topics):**

10. What ML technique is used for anomaly detection?
    a) Linear regression  b) Isolation Forest  c) K-means clustering  d) Neural networks

**Answers:** 1-b, 2-b, 3-b, 4-b, 5-b, 6-b, 7-b, 8-b, 9-c, 10-b

---

## TRAINING SCHEDULE RECOMMENDATIONS

### Self-Paced Online (Recommended)

**Week 1:**
- Module 1: Fundamentals (2h)
- Module 2: Custom Fields (3h)
- Lab 1 Start: Create fields (2h)

**Week 2:**
- Module 3: Scripts (4h)
- Lab 1 Continue: Deploy scripts (2h)
- Module 4: Conditions (3h)

**Week 3:**
- Module 5: Dynamic Groups (2h)
- Lab 1 Complete: Test and validate (2h)
- Module 6: Patching (3h)

**Week 4:**
- Lab 2: Patching deployment (3h)
- Module 7: Troubleshooting (3h)
- Lab 3: Troubleshooting exercises (2h)

**Week 5:**
- Module 8: Advanced topics (4h)
- Lab 4: Custom module (3h)
- Review and exam prep (2h)

**Week 6:**
- Certification exam (2h)
- Final project (if required)
- Certification awarded

**Total Time:** 50 hours over 6 weeks

### Instructor-Led Workshop

**Day 1: Fundamentals (8h)**
- 09:00 - Module 1: Framework overview
- 10:30 - Module 2: Custom fields deep dive
- 12:00 - Lunch
- 13:00 - Lab 1 Part 1: Field creation
- 15:00 - Module 3: PowerShell scripts
- 17:00 - End Day 1

**Day 2: Automation (8h)**
- 09:00 - Lab 1 Part 2: Script deployment
- 11:00 - Module 4: Compound conditions
- 12:00 - Lunch
- 13:00 - Module 5: Dynamic groups
- 15:00 - Lab 1 Part 3: Testing
- 17:00 - End Day 2

**Day 3: Patching & Advanced (8h)**
- 09:00 - Module 6: Patching automation
- 11:00 - Lab 2: Patching deployment
- 12:00 - Lunch
- 13:00 - Module 7: Troubleshooting
- 15:00 - Lab 3: Troubleshooting
- 17:00 - End Day 3

**Day 4: Expert Topics (8h)**
- 09:00 - Module 8: Advanced topics
- 11:00 - Lab 4: Custom module
- 12:00 - Lunch
- 13:00 - Certification exam
- 15:00 - Final project presentations
- 17:00 - Certification ceremony

**Total Time:** 32 hours over 4 days

---

## ADDITIONAL RESOURCES

**Documentation:**
- 98_Framework_Complete_Summary_Master.md (comprehensive reference)
- 99_Quick_Reference_Guide.md (cheat sheet)
- 100_Detailed_ROI_Analysis.md (business case)
- Chapter_6_Advanced_RCA.md (ML integration)
- Chapter_6_Explained.md (RCA concepts)
- Chapter_6_RCA_Diagrams.md (visual guides)

**Community:**
- NinjaOne Community Forums
- Framework GitHub Repository (if public)
- Monthly user group meetings
- Slack/Teams channel for questions

**Support:**
- Email: framework-support@example.com
- Documentation updates quarterly
- Version release notes

---

## CERTIFICATION MAINTENANCE

**Annual Renewal Requirements:**
- Complete 10 hours continuing education
- Stay current with framework updates
- Participate in user community
- Submit case study or best practice

**Continuing Education Options:**
- Advanced ML/RCA workshop
- Multi-tenant deployment course
- Custom module development
- Performance tuning workshop
- New feature training (v5.0, v6.0, etc.)

---

**File:** Framework_Training_Material_Part2.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 10:13 PM CET  
**Status:** Production Ready
