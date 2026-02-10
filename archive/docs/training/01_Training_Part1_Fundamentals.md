# NinjaOne Custom Field Framework - Complete Training Guide

**Version:** 1.0  
**Date:** February 1, 2026, 10:13 PM CET  
**Purpose:** Comprehensive training material for framework implementation and operation  
**Audience:** IT Administrators, Technicians, MSP Engineers

---

## TABLE OF CONTENTS

1. [Introduction & Overview](#introduction)
2. [Learning Objectives](#learning-objectives)
3. [Module 1: Framework Fundamentals](#module-1)
4. [Module 2: Custom Fields Deep Dive](#module-2)
5. [Module 3: PowerShell Scripts](#module-3)
6. [Module 4: Compound Conditions](#module-4)
7. [Module 5: Dynamic Groups](#module-5)
8. [Module 6: Patching Automation](#module-6)
9. [Module 7: Troubleshooting](#module-7)
10. [Module 8: Advanced Topics](#module-8)
11. [Hands-On Labs](#labs)
12. [Certification & Assessment](#certification)

---

<a name="introduction"></a>
## INTRODUCTION & OVERVIEW

### What is the NinjaOne Custom Field Framework?

The NinjaOne Custom Field Framework v4.0 is a comprehensive monitoring, automation, and intelligence platform consisting of:

- **277 custom intelligence fields** - Deep operational insights
- **110 PowerShell scripts** - Automated monitoring and remediation
- **75 hybrid compound conditions** - Smart alerting (Native + Custom)
- **74 dynamic groups** - Automated device segmentation

### Why v4.0 is Different

Version 4.0 represents a paradigm shift from purely custom metrics to a **hybrid approach**:

**v3.0 Approach (Legacy):**
```
Custom Script → Collect CPU % → Write to custom field → Wait 4 hours
Problem: Lag, false positives, high maintenance
```

**v4.0 Approach (Hybrid):**
```
Native Metric: CPU Utilization % (real-time)
+ Custom Intelligence: OPSHealthScore (context)
= Smart Alert with <10% false positives
```

**Result:** 70% fewer false positives, 50% faster deployment, 65% lower maintenance costs

---

<a name="learning-objectives"></a>
## LEARNING OBJECTIVES

By completing this training, you will be able to:

**Level 1 (Basics):**
- Understand framework architecture and components
- Create and configure custom fields
- Schedule and deploy PowerShell scripts
- Monitor script execution and troubleshoot failures

**Level 2 (Intermediate):**
- Create hybrid compound conditions (Native + Custom)
- Build dynamic device groups
- Configure patching automation (ring-based deployment)
- Interpret health scores and predictive analytics

**Level 3 (Advanced):**
- Customize scripts for your environment
- Tune condition thresholds and reduce false positives
- Build automation workflows with safety controls
- Implement advanced ML/RCA concepts

**Level 4 (Expert):**
- Design custom modules and integrations
- Optimize framework performance at scale
- Train other administrators
- Contribute to framework development

---

<a name="module-1"></a>
## MODULE 1: FRAMEWORK FUNDAMENTALS (2 hours)

### 1.1 Architecture Overview

The framework operates in layers:

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 4: AUTOMATION & ALERTS                                │
│  - 75 Compound Conditions (Hybrid Native + Custom)           │
│  - 74 Dynamic Groups                                         │
│  - Automated Remediation Scripts (40-65)                     │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│  LAYER 3: INTELLIGENCE FIELDS                                │
│  - 277 Custom Fields                                         │
│  - Health Scores (OPS, STAT, SEC)                           │
│  - Predictive Analytics (CAP)                                │
│  - Risk Classification (RISK)                                │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│  LAYER 2: DATA COLLECTION                                    │
│  - 110 PowerShell Scripts                                    │
│  - Native NinjaOne Metrics (CPU, Memory, Disk, etc.)        │
│  - Event Logs, Services, Processes                           │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│  LAYER 1: NINJAONE PLATFORM                                  │
│  - RMM Agent on devices                                      │
│  - Cloud API and database                                    │
│  - Script execution engine                                   │
└─────────────────────────────────────────────────────────────┘
```

**Data Flow:**
1. NinjaOne agent collects native metrics (real-time)
2. PowerShell scripts run on schedule (every 4h, daily, weekly)
3. Scripts write results to custom fields
4. Compound conditions evaluate (Native + Custom logic)
5. Actions trigger (alerts, tickets, remediation scripts)

### 1.2 Framework Statistics (Quick Facts)

| Component | Count | Purpose |
|-----------|-------|---------|
| Custom Fields | 277 | Store intelligence data |
| PowerShell Scripts | 110 | Collect & analyze data |
| Compound Conditions | 75 | Smart alerting |
| Dynamic Groups | 74 | Device segmentation |
| Lines of Code | 26,400 | Total PowerShell code |

### 1.3 Deployment Timeline

**Week 1-2: Core Monitoring**
- 35 essential custom fields
- Scripts 1-13 (infrastructure)
- Native monitoring enabled
- 15 P1 critical conditions

**Week 3-4: Extended Intelligence**
- 26 extended fields
- Scripts 14-36 (automation + telemetry)
- 40 P1+P2+P3 conditions
- 30 dynamic groups

**Week 5-6: Full Deployment**
- All 277 fields
- All 110 scripts
- All 75 conditions
- All 74 groups

**Week 7-8: Patching Automation (Optional)**
- 8 patching fields
- PR1, PR2, P1-P4 scripts
- Ring-based deployment

**Total:** 4-8 weeks depending on scope

### 1.4 Hands-On Exercise 1.1

**Task:** Navigate the NinjaOne interface and locate framework components

**Steps:**
1. Log into your NinjaOne dashboard
2. Navigate to **Administration** → **Custom Fields**
3. Search for fields starting with "OPS" (6 operational fields)
4. Navigate to **Administration** → **Automation** → **Scripts**
5. Locate Script 15 (Security Posture Consolidator)
6. Navigate to **Administration** → **Automation** → **Conditions**
7. Create test condition: "Device Down" = True
8. Navigate to **Devices** → **Dynamic Groups**
9. Create test group: Filter by "Device Down = True"

**Expected Result:**
- Familiarity with NinjaOne interface
- Understanding of where framework components live
- Test condition and group created successfully

---

<a name="module-2"></a>
## MODULE 2: CUSTOM FIELDS DEEP DIVE (3 hours)

### 2.1 Field Categories & Purpose

The 277 custom fields are organized into 16 categories:

**Core Intelligence (35 essential fields):**

1. **OPS (Operations)** - 6 fields
   ```
   OPSHealthScore (Integer 0-100)
   - Composite health: uptime + performance + security
   - Updated every 4 hours
   - Alert if < 60 (degraded), < 40 (critical)

   OPSPerformanceScore (Integer 0-100)
   - System responsiveness
   - Combines CPU, Memory, Disk I/O

   OPSSecurityScore (Integer 0-100)
   - Security posture: AV + Firewall + Updates
   - Native metrics + custom intelligence
   ```

2. **STAT (Stability)** - 15 fields
   ```
   STATStabilityScore (Integer 0-100)
   - Overall system stability
   - Crash counts + boot time + service failures

   STATCrashCount30d (Integer)
   - Application crashes in last 30 days
   - Event log derived (Event ID 1000)

   STATBootTimeSec (Integer)
   - Last boot time in seconds
   - Alert if > 120 sec (slow boot)
   ```

3. **CAP (Capacity Planning)** - 6 fields
   ```
   CAPDaysUntilDiskFull (Integer)
   - Predictive disk exhaustion
   - Linear regression on 30-day trend
   - Alert if < 30 days

   CAPMemoryPressureScore (Integer 0-100)
   - Memory contention metric
   - Page faults + available bytes
   ```

4. **SEC (Security)** - 5 fields
   ```
   SECSecurityPostureScore (Integer 0-100)
   - Overall security health
   - Combines native AV/Firewall + custom checks

   SECFailedLogonCount24h (Integer)
   - Failed login attempts
   - Event log Event ID 4625
   - Alert if > 10 (possible attack)
   ```

5. **RISK (Risk Management)** - 7 fields
   ```
   RISKExposureLevel (Dropdown)
   - Options: Low, Medium, High, Critical
   - Manual classification
   - Used in condition logic

   BASEBusinessCriticality (Dropdown)
   - Options: Low, Medium, High, Critical
   - Business impact tier
   ```

### 2.2 Field Types & Data Types

**Available Field Types:**

| Type | Purpose | Example |
|------|---------|---------|
| Text | Short string | "Running", "Failed" |
| Text Area | Long text | Full error messages |
| Integer | Whole numbers | 42, -5, 1000 |
| Decimal | Floating point | 3.14, 99.7 |
| Checkbox | Boolean | True/False |
| Dropdown | Select list | "Low/Medium/High/Critical" |
| Multi-Select | Multiple options | "Web,SQL,DNS" |
| Date | Date only | 2026-02-01 |
| DateTime | Date + Time | 2026-02-01 22:13:00 |
| WYSIWYG | HTML content | Formatted reports |

**Best Practices:**
- Use Integer for scores (0-100 range)
- Use Dropdown for classifications (limit options)
- Use DateTime for timestamps (not Text)
- Use WYSIWYG for complex output (RCA reports)

### 2.3 Creating Custom Fields

**Step-by-Step: Create OPSHealthScore Field**

1. **Navigate:** Administration → Custom Fields → Add Custom Field

2. **Configuration:**
   ```
   Field Name: OPSHealthScore
   Display Name: Health Score
   Type: Integer
   Category: Operations
   Description: Composite system health (0-100)
   Required: No
   Visible: Yes
   ```

3. **Scope:**
   - Apply to: Device Roles → All

4. **Save:** Click "Create Custom Field"

5. **Verify:** Device page now shows "Health Score" field

**Repeat for all 35 core fields** (see field definitions document)

### 2.4 Field Population Methods

**Method 1: PowerShell Script (Most Common)**
```powershell
$customFieldName = "OPSHealthScore"
$healthScore = 85  # Calculated value

Ninja-Property-Set $customFieldName $healthScore
```

**Method 2: Manual Entry**
- Navigate to device → Custom Fields tab
- Click field → Enter value → Save

**Method 3: API (Bulk Updates)**
```powershell
# Bulk update via API
$devices = Get-NinjaDevices
foreach ($device in $devices) {
    Set-NinjaCustomField -DeviceId $device.id -FieldName "RISKExposureLevel" -Value "Medium"
}
```

**Method 4: Native Metrics (v4.0)**
- No script needed - real-time
- Example: CPU Utilization %, Memory Utilization %

### 2.5 Field Update Frequencies

**Real-Time (Native Metrics):**
- CPU Utilization %
- Memory Utilization %
- Disk Free Space %
- Device Down/Offline

**Every 4 Hours (Scripts 1-13):**
- Infrastructure services (IIS, SQL, DHCP, DNS)
- OPSHealthScore, OPSPerformanceScore
- STATStabilityScore

**Daily (Scripts 14-36):**
- Security posture (Script 15)
- Drift detection (Scripts 14, 21)
- Capacity forecasting (Script 22)
- User experience metrics

**Weekly:**
- Predictive analytics (Script 24)
- Advanced telemetry

**On-Demand:**
- Remediation scripts (40-65)
- HARD security assessment (Script 66)

### 2.6 Hands-On Exercise 2.1

**Task:** Create and populate a custom field

**Steps:**
1. Create custom field:
   - Name: "TestHealthScore"
   - Type: Integer
   - Category: Test

2. Create simple PowerShell script:
```powershell
$score = Get-Random -Minimum 0 -Maximum 100
Ninja-Property-Set "TestHealthScore" $score
Write-Host "Set TestHealthScore to $score"
```

3. Save as "Test_Health_Script"

4. Schedule script:
   - Frequency: Every 4 hours
   - Target: Your test device

5. Run manually → Verify field populates

6. Wait 4 hours → Verify automatic execution

**Expected Result:**
- Custom field created
- Script runs successfully
- Field shows random score 0-100
- Understanding of field population workflow

---

<a name="module-3"></a>
## MODULE 3: POWERSH ELL SCRIPTS (4 hours)

### 3.1 Script Organization

**110 Scripts in 6 Categories:**

| Range | Category | Count | Purpose |
|-------|----------|-------|---------|
| 1-13 | Infrastructure Services | 13 | Server monitoring |
| 14-24 | Extended Automation | 11 | Drift, security, capacity |
| 27-36 | Advanced Telemetry | 10 | Deep analytics |
| 40-65 | Remediation | 26 | Automated fixes |
| 66-105 | HARD Security | 40 | Security hardening |
| PR1-P4 | Patching | 5 | Ring-based deployment |

### 3.2 Script Anatomy

**Every framework script follows this structure:**

```powershell
#REGION: Script Header
<#
.SYNOPSIS
    Brief description

.DESCRIPTION
    Detailed purpose and functionality

.NOTES
    Script ID: 15
    Version: 1.0
    Author: Framework Team
    Last Updated: 2026-02-01
#>
#ENDREGION

#REGION: Configuration
$scriptVersion = "1.0"
$customFieldPrefix = "SEC"
$debugMode = $false
#ENDREGION

#REGION: Functions
function Write-Log {
    param([string]$Message)
    if ($debugMode) {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message"
    }
}

function Get-SecurityPosture {
    # Main logic here
}
#ENDREGION

#REGION: Main Execution
try {
    Write-Log "Starting Security Posture Consolidator"

    # Step 1: Collect data
    $avStatus = Get-NativeAVStatus
    $firewallStatus = Get-NativeFir ewallStatus

    # Step 2: Calculate score
    $score = Calculate-SecurityScore -AV $avStatus -Firewall $firewallStatus

    # Step 3: Write to custom field
    Ninja-Property-Set "SECSecurityPostureScore" $score

    Write-Log "Complete: Score = $score"
}
catch {
    Write-Error "Script failed: $_"
    exit 1
}
#ENDREGION
```

### 3.3 Key Framework Scripts

**Script 15: Security Posture Consolidator (Most Important)**

Purpose: Combines native and custom security metrics into single score

```powershell
# Pseudocode
$avScore = 0
if (Native-AntivirusStatus = "Current") { $avScore = 100 }
elseif (Native-AntivirusStatus = "Outdated") { $avScore = 50 }
else { $avScore = 0 }

$firewallScore = 0
if (Native-FirewallStatus = "Enabled") { $firewallScore = 100 }

$patchScore = 0
$patchAge = (Today - Native-LastPatchDate).Days
if ($patchAge < 7) { $patchScore = 100 }
elseif ($patchAge < 30) { $patchScore = 70 }
else { $patchScore = 30 }

$finalScore = ($avScore * 0.4) + ($firewallScore * 0.3) + ($patchScore * 0.3)
Ninja-Property-Set "SECSecurityPostureScore" $finalScore
```

**Script 22: Capacity Trend Forecaster**

Purpose: Predict disk exhaustion using linear regression

```powershell
# Collect 30 days of disk space data
$diskData = Get-DiskSpaceHistory -Days 30

# Calculate daily growth rate
$growth = ($diskData[0] - $diskData[29]) / 30  # GB per day

# Current free space
$freeGB = (Native-DiskFreeSpace / 1GB)

# Days until full
$daysUntilFull = $freeGB / $growth

Ninja-Property-Set "CAPDaysUntilDiskFull" [int]$daysUntilFull
```

**Script 36: Server Role Detector**

Purpose: Auto-detect server roles (IIS, SQL, DNS, DHCP, etc.)

```powershell
$roles = @()

if (Get-Service W3SVC -ErrorAction SilentlyContinue) { $roles += "IIS" }
if (Get-Service MSSQLSERVER -ErrorAction SilentlyContinue) { $roles += "SQL" }
if (Get-Service DNS -ErrorAction SilentlyContinue) { $roles += "DNS" }
if (Get-Service DHCPServer -ErrorAction SilentlyContinue) { $roles += "DHCP" }

Ninja-Property-Set "SRVServerRoles" ($roles -join ",")
Ninja-Property-Set "SRVServerRole" ($roles.Count -gt 0)
```

### 3.4 Script Scheduling

**Best Practices:**

1. **Frequency by Category:**
   ```
   Critical Infrastructure (1-13): Every 4 hours
   Security & Drift (14-24): Daily at 2 AM
   Telemetry (27-36): Daily at 3 AM
   Remediation (40-65): On-demand only
   Patching (PR1-PR2): Weekly Tuesday 2 AM
   ```

2. **Stagger Execution:**
   ```
   02:00 - Scripts 1-13 (infrastructure)
   02:30 - Script 15 (security)
   03:00 - Scripts 27-36 (telemetry)
   04:00 - Script 22 (capacity forecasting)
   ```

3. **Avoid Peak Hours:**
   - Don't run during 8 AM - 6 PM (business hours)
   - Spread load across non-peak times

4. **Timeout Settings:**
   ```
   Simple scripts: 60 seconds
   Complex analysis: 120 seconds
   Patching: 30 minutes
   ```

### 3.5 Testing Scripts Locally

**PowerShell ISE Testing:**

```powershell
# 1. Create test function to simulate Ninja-Property-Set
function Ninja-Property-Set {
    param($name, $value)
    Write-Host "Would set $name = $value"
}

# 2. Run your script
# Script logic here...

# 3. Check output
# Expected: "Would set OPSHealthScore = 85"
```

**Remote Testing on Device:**

```powershell
# Run as SYSTEM account (NinjaOne context)
psexec -s powershell.exe

# Then run script
.\Script_15_Security_Posture.ps1
```

### 3.6 Hands-On Exercise 3.1

**Task:** Create and deploy a monitoring script

**Steps:**
1. Create "Script 99: Test Device Monitor"
```powershell
# Collect CPU from native metric
$cpuPercent = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue

# Collect Memory
$os = Get-WmiObject Win32_OperatingSystem
$memPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

# Collect Disk
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)

# Calculate simple health score
$health = 100
if ($cpuPercent > 80) { $health -= 20 }
if ($memPercent > 90) { $health -= 30 }
if ($diskPercent > 90) { $health -= 30 }

# Write to custom field
Ninja-Property-Set "TestHealthScore" $health

Write-Host "Health: $health% (CPU: $cpuPercent%, Mem: $memPercent%, Disk: $diskPercent%)"
```

2. Deploy to NinjaOne:
   - Administration → Automation → Scripts → Add Script
   - Paste code → Save as "Test Device Monitor"

3. Schedule:
   - Frequency: Every 4 hours
   - Target: Test device

4. Run manually → Check output

5. Verify custom field updated

**Expected Result:**
- Script runs successfully
- TestHealthScore field populated
- Understanding of script deployment workflow

---

<a name="module-4"></a>
## MODULE 4: COMPOUND CONDITIONS (3 hours)

### 4.1 v4.0 Hybrid Conditions (Native + Custom)

**The Revolution: From Custom-Only to Hybrid**

**v3.0 Approach (Legacy):**
```
Condition: CAPDiskFreePercent < 10
Problem:
  - Relies on script (4-hour delay)
  - No real-time detection
  - High false positives
  - No business context
```

**v4.0 Approach (Hybrid):**
```
Condition:
  Native: Disk Free Space < 10% (real-time)
  AND Custom: CAPDaysUntilDiskFull < 30 (predictive)
  AND Custom: OPSHealthScore < 60 (context)
  AND Custom: RISKExposureLevel IN ("High", "Critical")

Result:
  - Real-time detection (<1 min)
  - Predictive urgency (30 days)
  - Health context (not just disk)
  - Business impact considered
  - 70% fewer false positives
```

### 4.2 Condition Priority Levels

**P1 - Critical (15 conditions):**
- Service-impacting failures
- Immediate action required
- Create P1 ticket + alert
- Examples: Device down, SMART failure, security breach

**P2 - High (20 conditions):**
- Degraded performance
- Urgent attention needed
- Create P2 ticket
- Examples: High disk usage, patch failures, drift detected

**P3 - Medium (25 conditions):**
- Proactive warnings
- Investigation required
- Create P3 ticket
- Examples: Capacity warnings, baseline not established

**P4 - Low (15 conditions):**
- Informational
- Positive health tracking
- No ticket (optional alert)
- Examples: All systems healthy, compliance met

### 4.3 Creating Hybrid Conditions

**Example: P1 Critical Disk Failure**

1. **Navigate:** Administration → Automation → Conditions → Add Condition

2. **Configure:**
   ```
   Name: P1_DiskCriticalImminent
   Priority: Critical
   Description: Disk space critically low with imminent failure
   ```

3. **Logic (Hybrid Native + Custom):**
   ```
   Trigger When ALL of the following are true:

   [Native Metric]
   └─ Disk Free Space < 5%
      └─ For partition: C:
      └─ Duration: 15 minutes

   [Custom Field - Predictive]
   └─ CAPDaysUntilDiskFull < 3

   [Custom Field - Context]
   └─ OPSHealthScore < 50

   [Custom Field - Business Impact]
   └─ RISKExposureLevel IN ("High", "Critical")
   ```

4. **Actions:**
   ```
   1. Create Ticket (Priority: P1)
      Template: "CRITICAL: Disk space exhausted on {{device_name}}"

   2. Send Alert
      Recipients: IT Operations team
      Method: Email + SMS

   3. Run Script
      Script: 50 (Emergency Disk Cleanup)
      Condition: AUTORemediationEligible = True

   4. Update Custom Field
      Field: AUTO LastRemediationAttempt
      Value: {{current_datetime}}
   ```

5. **Exclusions:**
   ```
   Do NOT trigger if:
   - Device in group "AUTO_Restricted"
   - BASEBusinessCriticality = "Test"
   ```

### 4.4 Condition Testing

**Dry-Run Mode:**
```
1. Create condition
2. Set to "Report Only" (no actions)
3. Monitor for 7 days
4. Review triggered events
5. Tune thresholds
6. Enable actions when satisfied
```

**Testing Checklist:**
- [ ] Condition triggers on expected devices
- [ ] No false positives on healthy devices
- [ ] Actions execute correctly
- [ ] Exclusions work as intended
- [ ] Performance impact acceptable

### 4.5 Condition Tuning

**Reduce False Positives:**

**Problem:** Disk condition triggers too often

**Solution:**
```
Original: Disk Free Space < 10%
Tuned:    Disk Free Space < 10%
          AND CAPDaysUntilDiskFull < 30
          AND Duration: 30 minutes (not momentary spike)
          AND OPSHealthScore < 60 (overall unhealthy)
```

**Add Business Context:**
```
Original: STATCrashCount30d > 5
Tuned:    STATCrashCount30d > 5
          AND RISKBusinessCriticalFlag = True (only critical devices)
          AND STATStabilityScore < 50 (overall unstable)
```

### 4.6 Hands-On Exercise 4.1

**Task:** Create hybrid condition with native and custom fields

**Steps:**
1. Create condition:
   ```
   Name: Test_HighMemoryWithCrashes
   Description: High memory usage with application crashes
   ```

2. Logic:
   ```
   Native: Memory Utilization > 90% for 15 minutes
   AND Custom: STATCrashCount30d > 2
   AND Custom: OPSHealthScore < 70
   ```

3. Actions:
   ```
   - Create ticket (P2)
   - Send email alert
   - Log to custom field: "AUTOLastAlertTime"
   ```

4. Test:
   - Set manual override: Memory Utilization = 95% (if possible)
   - Or wait for real high memory event
   - Verify condition triggers
   - Verify actions execute

**Expected Result:**
- Hybrid condition created
- Understanding of native + custom logic
- Actions configured correctly
- Successful test execution

---

<a name="module-5"></a>
## MODULE 5: DYNAMIC GROUPS (2 hours)

### 5.1 Group Categories

**74 Dynamic Groups in 7 Categories:**

1. **Critical Health (12 groups)**
   - Devices requiring immediate attention
   - Examples: CRIT_Stability_Risk, CRIT_Disk_Critical

2. **Operational (15 groups)**
   - Device type segmentation
   - Examples: OPS_Workstations_Standard, OPS_Servers_Critical

3. **Automation (10 groups)**
   - Automation eligibility
   - Examples: AUTO_Safe_Aggressive, AUTO_Restricted

4. **Drift & Compliance (8 groups)**
   - Configuration management
   - Examples: DRIFT_Active, BASE_No_Baseline

5. **Capacity Planning (12 groups)**
   - Resource forecasting
   - Examples: CAP_Disk_Upgrade_30d, CAP_Memory_Pressure

6. **Device Lifecycle (8 groups)**
   - Hardware replacement planning
   - Examples: PRED_Replace_0_6m, PRED_Replace_6_12m

7. **User Experience (9 groups)**
   - End-user satisfaction
   - Examples: UX_Poor, UX_Collaboration_Issues

### 5.2 Creating Dynamic Groups

**Example: Critical Servers Group**

1. **Navigate:** Devices → Dynamic Groups → Add Group

2. **Configure:**
   ```
   Name: OPS_Servers_Critical
   Description: Production critical servers requiring enhanced monitoring
   ```

3. **Filters (ALL must match):**
   ```
   [Device Type]
   └─ Operating System Type = "Windows Server"

   [Custom Field - Role Detection]
   └─ SRVServerRole = True

   [Custom Field - Business Classification]
   └─ RISKBusinessCriticalFlag = True
      OR BASEBusinessCriticality IN ("High", "Critical")

   [Custom Field - Health Threshold]
   └─ OPSHealthScore >= 50 (only healthy enough for production)
   ```

4. **Exclusions (ANY match):**
   ```
   - Device Name contains "TEST"
   - Device Name contains "DEV"
   - BASEBusinessCriticality = "Test"
   ```

5. **Actions (Applied to all devices in group):**
   ```
   - Enhanced monitoring (every 15 minutes instead of 4 hours)
   - Priority alerting (P1 escalation)
   - Manual approval required for automation
   ```

### 5.3 Group-Based Automation

**Use Cases:**

**1. Automated Patching by Ring:**
```
Group: PATCH_Ring_PR1_Test
  Filter: patchRing = "PR1-Test"
  Script: PR1 (Weekly Tuesday 2 AM)

Group: PATCH_Ring_PR2_Production
  Filter: patchRing = "PR2-Production"
  Script: PR2 (Weekly Tuesday 2 AM, after PR1 success)
```

**2. Disk Cleanup Automation:**
```
Group: CAP_Disk_Critical_Auto
  Filter: Disk Free Space < 10%
         AND CAPDaysUntilDiskFull < 30
         AND AUTORemediationEligible = True
  Script: 50 (Emergency Disk Cleanup)
  Frequency: Daily at 2 AM
```

**3. Security Remediation:**
```
Group: SEC_Vulnerable_Auto
  Filter: Antivirus Status = "Disabled"
         AND SECSecurityPostureScore < 40
         AND AUTO_Safe_Aggressive member
  Script: 61 (Security Hardening - AV)
  Frequency: Hourly check
```

### 5.4 Hands-On Exercise 5.1

**Task:** Create dynamic group for automation targeting

**Steps:**
1. Create group:
   ```
   Name: Test_AutomationEligible
   Description: Test devices safe for aggressive automation
   ```

2. Filters:
   ```
   Device Name contains: "TEST"
   AND OPSHealthScore > 80
   AND STATStabilityScore > 80
   AND AUTORemediationEligible = True
   ```

3. Verify membership:
   - Check devices in group
   - Confirm all match criteria

4. Assign script:
   - Script: Test Device Monitor (from Module 3)
   - Frequency: Every 4 hours
   - Target: Test_AutomationEligible group

**Expected Result:**
- Dynamic group created
- Devices automatically added/removed based on criteria
- Script executes only on group members
- Understanding of group-based automation

---

<a name="module-6"></a>
## MODULE 6: PATCHING AUTOMATION (3 hours)

### 6.1 Ring-Based Deployment Model

**The Two-Ring Approach:**

```
┌─────────────────────────────────────────────────────────┐
│  RING 1 (PR1-Test): 10-20 Test Devices                  │
│  Purpose: Validate patches before production             │
│  Deploy: Tuesday Week 1, 2:00 AM                        │
│  Soak Period: 7 days                                    │
│  Success Criteria: 90%+ success rate                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ 7-day validation
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  RING 2 (PR2-Production): All Production Devices        │
│  Purpose: Controlled production deployment              │
│  Deploy: Tuesday Week 2, 2:00 AM (after PR1 success)    │
│  Priority: P1 Critical first → P4 Low last              │
│  Validation: Pre/post health checks                     │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Patching Custom Fields (8 fields)

```
patchRing (Dropdown: PR1-Test, PR2-Production)
  - Manual assignment
  - Determines deployment schedule

patchLastAttemptDate (DateTime)
  - Auto-populated by PR1/PR2 scripts
  - Last patch attempt timestamp

patchLastAttemptStatus (Text)
  - "Success", "Failed: [reason]", "Pending", "Skipped: [reason]"

patchLastPatchCount (Integer)
  - Number of patches installed

patchRebootPending (Checkbox)
  - Reboot required post-patch

patchValidationStatus (Dropdown: Passed, Failed, Pending, Error)
  - Pre/post validation result

patchValidationNotes (Text)
  - Detailed validation output

patchValidationDate (DateTime)
  - When validation ran
```

### 6.3 Patching Scripts

**Script PR1: Test Ring Deployment**

Purpose: Deploy patches to 10-20 test devices

```powershell
# Pseudocode
if (Device not in PATCH_Ring_PR1_Test group) {
    Exit  # Only PR1 devices
}

# Pre-deployment validation (Script P1/P2)
$validation = Validate-PatchReadiness
if ($validation -ne "Passed") {
    Ninja-Property-Set "patchLastAttemptStatus" "Skipped: $validation"
    Exit
}

# Install patches
$result = Install-WindowsUpdates -Category "Critical,Important"

# Update fields
Ninja-Property-Set "patchLastAttemptDate" (Get-Date)
Ninja-Property-Set "patchLastAttemptStatus" $result.Status
Ninja-Property-Set "patchLastPatchCount" $result.Count
Ninja-Property-Set "patchRebootPending" $result.RebootRequired

# Post-validation
Start-Sleep -Seconds 300  # Wait 5 minutes
$postValidation = Validate-PostPatch
Ninja-Property-Set "patchValidationStatus" $postValidation
```

**Script P1: Critical Device Validator**

Purpose: Pre-patch validation for critical devices

```powershell
# Check 1: Health score threshold
if (OPSHealthScore < 80) {
    return "Failed: Health score too low ($OPSHealthScore)"
}

# Check 2: Stability
if (STATStabilityScore < 80) {
    return "Failed: Stability score too low ($STATStabilityScore)"
}

# Check 3: Recent backup
$lastBackup = (Native-BackupStatus).LastBackupDate
if ($lastBackup -lt (Get-Date).AddHours(-24)) {
    return "Failed: No backup within 24 hours"
}

# Check 4: Disk space
$diskFree = Native-DiskFreeSpace
if ($diskFree -lt 5GB) {
    return "Failed: Insufficient disk space ($diskFree GB)"
}

# Check 5: No recent crashes
if (STATCrashCount7d > 0) {
    return "Failed: Recent crashes detected ($STATCrashCount7d)"
}

return "Passed"
```

### 6.4 Ring Assignment Strategy

**PR1-Test Ring Candidates (10-20 devices):**
```
Criteria:
  - Non-production devices
  - Various hardware types (representative sample)
  - Stable baseline (OPSHealthScore > 80)
  - IT department owned (easy recovery)

Examples:
  - IT staff workstations
  - Test servers
  - Development machines
  - Lab devices

Manual Assignment:
  1. Device → Custom Fields
  2. patchRing = "PR1-Test"
  3. Save
```

**PR2-Production Ring (All others):**
```
Criteria:
  - All production devices
  - Automatically assigned (default)

Sub-Priority (within PR2):
  P1 Critical: Deploy first (2 AM Tuesday Week 2)
  P2 High: Deploy after P1 (4 AM Tuesday)
  P3 Medium: Deploy after P2 (overnight)
  P4 Low: Deploy last (weekend)
```

### 6.5 Monitoring Patch Success

**Dashboard Widgets:**

1. **Patch Success Rate (Last 30 Days)**
   ```
   Total Devices: 500
   Successful: 475 (95%)
   Failed: 15 (3%)
   Skipped: 10 (2%)
   ```

2. **PR1 Test Ring Health**
   ```
   Total PR1 Devices: 15
   Last Deployment: 2026-01-28
   Success Rate: 93% (14/15)
   Failed: SERVER-TEST-01 (disk space)
   Soak Period: 4 days remaining
   ```

3. **Pending Reboots**
   ```
   Devices requiring reboot: 45
   Critical devices: 3 (manual reboot)
   Auto-reboot eligible: 42 (weekend)
   ```

4. **Patch Compliance**
   ```
   Fully patched: 450 (90%)
   Missing critical patches: 30 (6%)
   Missing non-critical: 20 (4%)
   ```

### 6.6 Hands-On Exercise 6.1

**Task:** Configure patching automation for test environment

**Steps:**
1. Create patching custom fields (8 fields from 6.2)

2. Assign test devices to PR1 ring:
   - Select 3-5 test devices
   - Set patchRing = "PR1-Test"

3. Create PATCH_Ring_PR1_Test group:
   ```
   Filter: patchRing = "PR1-Test"
   ```

4. Deploy Script PR1 (or simplified version):
   ```powershell
   # Simplified PR1 for testing
   Ninja-Property-Set "patchLastAttemptDate" (Get-Date)
   Ninja-Property-Set "patchLastAttemptStatus" "Success (Test)"
   Ninja-Property-Set "patchLastPatchCount" 5
   Write-Host "Test PR1 deployment complete"
   ```

5. Schedule:
   - Target: PATCH_Ring_PR1_Test group
   - Frequency: Run once (manual)

6. Execute → Verify fields populated

**Expected Result:**
- Patching fields created
- PR1 ring devices configured
- Script executes successfully
- Understanding of ring-based deployment

---

## PART 2: ADVANCED MODULES

(Document continues with Modules 7-8, Hands-On Labs, and Certification in next section due to length)

---

**File:** Training_Material_Part1.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 10:13 PM CET  
**Status:** In Progress (Part 1 of 2)
