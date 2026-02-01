# Chapter 6 Explained: Understanding Root Cause Analysis Concepts

**Version:** 1.0  
**Date:** February 1, 2026, 9:47 PM CET  
**Purpose:** Non-technical explanation of RCA concepts and methodology

---

## Introduction: What Is Root Cause Analysis?

### The Problem We're Solving

Imagine your car's "Check Engine" light comes on. That light is a **symptom** - it tells you something is wrong, but not **what** is wrong. You could have:

- A loose gas cap (simple fix)
- A failing oxygen sensor (moderate issue)
- Engine overheating (serious problem)
- Transmission failure (critical failure)

**Root Cause Analysis (RCA)** is like being a detective who figures out which of these problems caused the check engine light. In IT monitoring, when an anomaly is detected (the "check engine light"), RCA identifies the underlying issue that triggered it.

---

## The Medical Diagnosis Analogy

### How Doctors Diagnose Patients

When you visit a doctor with symptoms, they follow a process:

1. **Symptoms Assessment:** "I have a headache, fever, and fatigue"
2. **Baseline Comparison:** "Is your temperature higher than normal? (98.6°F baseline)"
3. **Timeline Construction:** "When did the headache start? Then the fever?"
4. **Correlation Analysis:** "Headaches often accompany fevers"
5. **Causal Testing:** "Did the headache cause the fever, or vice versa?"
6. **Diagnosis:** "You have the flu (root cause). Headache and fatigue are symptoms."

**Our RCA system does the same thing for computers:**

1. **Symptoms:** MLAnomalyScore = 92 (something is very wrong)
2. **Baseline:** Compare current metrics to "healthy" baseline (last week)
3. **Timeline:** Which metrics deviated first? (disk space at 8:00 AM, memory at 8:45 AM)
4. **Correlation:** Memory pressure and disk issues occurred together
5. **Causal Testing:** Did low disk space cause memory pressure?
6. **Diagnosis:** Low disk space is the root cause; memory pressure is a symptom

---

## Core Concepts Explained

### Concept 1: Baseline vs Incident Comparison

**Baseline Period:** When the device was healthy (7 days ago, same time window)
**Incident Period:** 24 hours before the anomaly was detected

**Why We Compare:**
- A CPU at 80% might be normal for a busy server but abnormal for a workstation
- A laptop with 50 crashes/day is critical, but 2 crashes/day might be normal for a developer's machine
- **Context matters** - we compare each device to its own historical "normal"

**Example:**

```
Device: FILE-SERVER-01
Metric: STATMemoryUsedPercent

Baseline (Jan 25, 8:00 AM - 9:00 AM):
- Average: 45%
- Standard Deviation: 5%
- Range: 40-50%

Incident (Feb 1, 8:00 AM - 9:00 AM):
- Average: 92%
- Peak: 98%
- This is +47% above baseline!

Conclusion: Memory usage is SIGNIFICANTLY elevated
```

---

### Concept 2: Z-Score (Statistical Significance)

**What Is It?**
A z-score tells us "how many standard deviations away from normal is this value?"

**Simple Explanation:**
- Z-score of 0 = exactly average (normal)
- Z-score of 1 = slightly above average (probably fine)
- Z-score of 2 = unusual (95% of the time, values are within ±2)
- Z-score of 3+ = very unusual (99.7% confidence something is wrong)

**Real-World Example:**

Adult male height in US:
- Average: 5'9" (69 inches)
- Standard deviation: 3 inches

Person A: 6'0" (72 inches)
- Z-score = (72 - 69) / 3 = 1.0
- Interpretation: Taller than average, but normal

Person B: 6'9" (81 inches)
- Z-score = (81 - 69) / 3 = 4.0
- Interpretation: Extremely tall (99.99th percentile)

**Applied to IT Metrics:**

```
STATAppCrashes24h (Application Crashes)

Baseline: 
- Mean = 2 crashes/day
- Std Dev = 1 crash

Incident:
- Current = 15 crashes/day
- Z-score = (15 - 2) / 1 = 13.0

Interpretation: EXTREMELY abnormal (something is seriously wrong)
```

**Threshold We Use:** Z-score > 2.0 = deviation flagged

---

### Concept 3: Correlation vs Causation

**The Golden Rule:** "Correlation does not imply causation"

**Correlation:** Two things happen together
**Causation:** One thing causes the other

**Example - Ice Cream Sales and Drowning Deaths:**

Observation: Ice cream sales and drowning deaths are highly correlated
- When ice cream sales increase, drowning deaths increase
- When ice cream sales decrease, drowning deaths decrease

**Question:** Does ice cream cause drowning? NO!

**Root Cause:** Both are caused by a third factor - **summer weather**
- Summer → Hot weather → More people buy ice cream
- Summer → Hot weather → More people swim → More drowning incidents

**Applied to IT:**

```
Observation: Three metrics deviated together
1. STATMemoryUsedPercent increased to 92%
2. STATAppCrashes24h increased to 15 crashes
3. OPSHealthScore decreased to 35

Are they correlated? YES (all three happened during the incident)

But which caused which?
- Did memory pressure cause app crashes?
- Did app crashes cause memory pressure?
- Did something else cause both?

We need Granger Causality Testing to find out!
```

---

### Concept 4: Granger Causality (Does A Predict B?)

**What It Tests:**
"If I know the history of metric A, can I predict metric B better than if I only know the history of metric B?"

**Simple Explanation:**
- If A causes B, then changes in A should happen **before** changes in B
- By looking at past values of A, we should be able to predict future values of B

**Real-World Example:**

Does "dark clouds" cause "rain"?

Test: Can we predict rain better if we know about dark clouds vs just looking at rain history?
- Approach 1: Predict rain based on "did it rain yesterday?"
- Approach 2: Predict rain based on "did it rain yesterday + were there dark clouds?"

If Approach 2 is significantly better → Dark clouds Granger-cause rain ✓

**Applied to IT:**

```
Hypothesis: Low disk space causes memory pressure

Test: Can we predict STATMemoryUsedPercent better if we know CAPDaysUntilDiskFull history?

Data Timeline:
8:00 AM - CAPDaysUntilDiskFull drops to 3 days
8:45 AM - STATMemoryUsedPercent starts climbing
9:15 AM - Memory hits 85%
9:30 AM - Memory hits 92%

Granger Test Result:
- P-value = 0.003 (very significant)
- Conclusion: CAPDaysUntilDiskFull DOES predict STATMemoryUsedPercent

Interpretation: Low disk space happened first and predicts memory pressure
→ Low disk space likely CAUSES memory pressure
```

**Why This Happens:**
When disk space is low, Windows uses more RAM for caching because it can't write to disk efficiently. This causes memory pressure.

---

### Concept 5: Temporal Ordering (Timeline Analysis)

**The Principle:** The root cause happens **first**, symptoms happen **later**

**Real-World Example:**

```
Car breakdown timeline:
6:00 AM - Engine oil leak starts
7:30 AM - Engine temperature rises
8:00 AM - Engine overheating warning light
8:15 AM - Engine knocking noise
8:30 AM - Complete engine failure

Root Cause: Oil leak (happened first at 6:00 AM)
Symptoms: Everything else (temperature, warning, noise, failure)
```

**Applied to IT:**

```
Server incident timeline:
8:00 AM - CAPDaysUntilDiskFull deviates (disk running out)
8:45 AM - STATMemoryUsedPercent deviates (memory pressure)
9:15 AM - STATDiskActivePercent deviates (disk thrashing)
10:30 AM - STATAppCrashes24h deviates (applications crashing)
11:00 AM - STATServiceFailures24h deviates (services failing)
12:00 PM - OPSHealthScore deviates (overall health crashes)

Root Cause: Disk space (first deviation at 8:00 AM)
Cascade: Disk → Memory → I/O → Crashes → Service failures → Health decline
```

**Our Algorithm:**
- Metrics that deviate **earlier** get higher temporal scores
- First deviation = 100 points, last deviation = 0 points

---

### Concept 6: Root Cause Scoring Algorithm

**How We Rank Potential Root Causes:**

We combine three factors:

**1. Temporal Score (40% weight):**
- "Did this metric deviate early in the incident?"
- Earlier = more likely to be the root cause

**2. Causal Score (40% weight):**
- "How many other metrics does this one cause?"
- More downstream effects = more likely to be root cause

**3. Severity Score (20% weight):**
- "How abnormal is this metric's value?"
- Larger deviation = potentially more important

**Example Calculation:**

```
Metric: CAPDaysUntilDiskFull

Temporal Score:
- Deviated first (rank 1 out of 10)
- Score = 100 × (1 - 0/10) = 100

Causal Score:
- Causes 5 other metrics (Memory, DiskIO, Crashes, Services, Health)
- Score = min(100, 5 × 20 + 0.99 × 50) = 100

Severity Score:
- Z-score = -4.5 (very significant)
- Score = min(100, 4.5 × 20) = 90

Combined Score:
= (100 × 0.4) + (100 × 0.4) + (90 × 0.2)
= 40 + 40 + 18
= 98/100

Conclusion: CAPDaysUntilDiskFull is the root cause with 98% confidence
```

---

## The Complete RCA Process: Step-by-Step Example

### Scenario: Production Server Anomaly

**Alert:** MLAnomalyScore = 92 on SERVER-PROD-05 at Feb 1, 2:30 PM

**Step 1: Extract Data Windows**

```
Baseline Period: Jan 25, 2:30 PM - Jan 26, 2:30 PM (7 days ago, 24 hours)
Incident Period: Jan 31, 2:30 PM - Feb 1, 2:30 PM (yesterday, 24 hours)

Data Collected: 277 metrics × 6 samples (every 4 hours) = 1,662 data points
```

**Step 2: Detect Deviations**

```
Comparing each metric's incident avg vs baseline avg:

Metric: CAPDaysUntilDiskFull
- Baseline: 45 days until full (healthy)
- Incident: 2 days until full (critical!)
- Z-score: -4.5 (extremely low)
- Percent change: -95.6%
- Status: CRITICAL DEVIATION ✗

Metric: STATMemoryUsedPercent
- Baseline: 45% average
- Incident: 92% average
- Z-score: +4.8 (extremely high)
- Percent change: +104%
- Status: CRITICAL DEVIATION ✗

Metric: STATAppCrashes24h
- Baseline: 2 crashes/day
- Incident: 15 crashes/day
- Z-score: +3.9 (very high)
- Percent change: +650%
- Status: CRITICAL DEVIATION ✗

... (20 more metrics deviated)

Total Deviations Found: 23 metrics
```

**Step 3: Build Timeline**

```
Chronological order of first deviations:

8:00 AM - CAPDaysUntilDiskFull (disk space warning)
8:45 AM - STATMemoryUsedPercent (memory climbing)
9:15 AM - STATDiskActivePercent (disk I/O saturated)
10:30 AM - STATAppCrashes24h (apps starting to crash)
11:00 AM - STATServiceFailures24h (services failing)
12:00 PM - OPSHealthScore (overall health deteriorating)
12:30 PM - OPSStabilityScore (system unstable)
1:00 PM - SECFailedLogonCount24h (users can't log in)
2:00 PM - NETGatewayLatencyMs (network degraded)

Pattern: Disk issue → Resource pressure → Application failures → System degradation
```

**Step 4: Test Causality**

```
Granger Causality Tests (does A predict B?):

Test 1: CAPDaysUntilDiskFull → STATMemoryUsedPercent
- P-value: 0.003 (highly significant)
- Conclusion: Disk space DOES predict memory pressure ✓

Test 2: CAPDaysUntilDiskFull → STATDiskActivePercent
- P-value: 0.008 (significant)
- Conclusion: Disk space DOES predict disk I/O ✓

Test 3: STATMemoryUsedPercent → STATAppCrashes24h
- P-value: 0.012 (significant)
- Conclusion: Memory pressure DOES predict crashes ✓

Test 4: STATAppCrashes24h → OPSHealthScore
- P-value: 0.019 (significant)
- Conclusion: Crashes DO predict health decline ✓

Causal Chain Discovered:
Disk Space → Memory Pressure → Disk I/O Saturation
                              ↓
                        App Crashes → Service Failures → Health Decline
```

**Step 5: Rank Root Causes**

```
Root Cause Candidates (ranked by combined score):

1. CAPDaysUntilDiskFull
   - Temporal Score: 100 (first deviation)
   - Causal Score: 100 (causes 5 metrics)
   - Severity Score: 90 (z=-4.5)
   - Combined: 98/100 ← IDENTIFIED ROOT CAUSE

2. STATMemoryUsedPercent
   - Temporal Score: 86 (second deviation)
   - Causal Score: 75 (causes 3 metrics)
   - Severity Score: 96 (z=+4.8)
   - Combined: 84/100 ← Symptom/cascade effect

3. STATDiskActivePercent
   - Temporal Score: 71
   - Causal Score: 50 (causes 2 metrics)
   - Severity Score: 78
   - Combined: 66/100 ← Symptom

4. STATAppCrashes24h
   - Temporal Score: 57
   - Causal Score: 50
   - Severity Score: 78
   - Combined: 60/100 ← Downstream symptom
```

**Step 6: Generate Report**

```
ROOT CAUSE ANALYSIS REPORT
==========================

Device: SERVER-PROD-05
Anomaly Detected: Feb 1, 2026, 2:30 PM
Analysis Confidence: 98/100

ROOT CAUSE IDENTIFIED:
CAPDaysUntilDiskFull (Disk Space Exhaustion)
- Current: 2 days until C: drive full
- Normal: 45 days until full
- Change: -95.6% (critical decline)

FAILURE CASCADE:
1. Disk space dropped to critical levels (8:00 AM)
   ↓
2. Windows increased RAM caching due to disk pressure (8:45 AM)
   ↓
3. Memory exhausted → Disk thrashing began (9:15 AM)
   ↓
4. Applications unable to allocate memory → Crashes (10:30 AM)
   ↓
5. Critical services failed due to resource starvation (11:00 AM)
   ↓
6. Overall system health critically degraded (12:00 PM)

METRICS AFFECTED: 23 total
- Performance: 8 metrics
- Stability: 6 metrics  
- Security: 4 metrics
- User Experience: 5 metrics

RECOMMENDED ACTIONS:
Immediate (next 1 hour):
1. Run disk cleanup script (Script 45)
2. Clear temp files and logs
3. Identify large files for deletion/archival

Short-term (next 24 hours):
4. Add 100GB storage capacity
5. Implement automated cleanup policies

Long-term (next 30 days):
6. Enable disk quota monitoring
7. Configure storage auto-expansion
8. Review application log retention policies

SIMILAR HISTORICAL INCIDENTS:
This incident is 94% similar to INC-2025-1234 (Nov 15, 2025)
- Previous Root Cause: Low disk space on C: drive
- Previous Resolution: Cleared 80GB temp files + added 200GB storage
- Resolution Time: 45 minutes

ESTIMATED RESOLUTION TIME: 30-60 minutes
```

---

## Why This Matters: Business Value

### Traditional Approach (Manual RCA)

**When alert fires:**
1. Technician logs into server (5 min)
2. Checks Task Manager, Event Viewer (15 min)
3. Reviews 277 metrics manually in NinjaOne (30 min)
4. Correlates multiple dashboards (30 min)
5. Tests hypotheses (disk? memory? network?) (45 min)
6. Identifies root cause (if lucky) (60 min)
7. Escalates if stuck (another 60+ min)

**Total Time: 3-6 hours**
**Success Rate: 60-70%** (sometimes root cause is missed)

### Automated Approach (ML-Powered RCA)

**When alert fires:**
1. RCA system automatically triggered
2. Analyzes 277 metrics in 90 seconds
3. Identifies root cause with 98% confidence
4. Generates actionable report
5. Technician reviews report and executes fix (15 min)

**Total Time: 20-30 minutes**
**Success Rate: 70-85%** (validated against historical incidents)

### ROI Calculation

**Scenario:** 50 incidents per year

**Traditional:**
- 50 incidents × 4 hours average = 200 hours
- 200 hours × €50/hour = €10,000

**Automated:**
- 50 incidents × 0.5 hours average = 25 hours  
- 25 hours × €50/hour = €1,250

**Savings:** €8,750 per year in labor
**Plus:** Faster resolution = less downtime = €5,000-€15,000 additional savings

**Total Annual Benefit:** €13,750-€23,750

---

## Common Questions

### Q: How accurate is automated RCA?

**A:** 70-85% accuracy when validated against human-confirmed root causes.

- 70-75% for complex multi-factor incidents
- 80-85% for single root cause incidents
- 90%+ when similar historical pattern exists

**What about the 15-30% where it's wrong?**
- System provides confidence scores
- Low confidence (<70%) = flag for human review
- Over time, system learns from corrections

---

### Q: What if multiple root causes exist?

**A:** The system ranks ALL candidates, not just the top one.

Example output:
```
Root Cause Candidates:
1. CAPDaysUntilDiskFull (98/100) ← Primary
2. STATMemoryUsedPercent (84/100) ← Secondary?
3. NETGatewayLatencyMs (72/100) ← Tertiary?
```

If #1 and #2 are both >80%, investigate both.

---

### Q: Can the system learn from mistakes?

**A:** Yes, through feedback loops.

```
RCA Prediction: CAPDaysUntilDiskFull
Human Validation: Correct ✓

Action: Store in historical database
- Incident signature
- Root cause
- Successful resolution
- Resolution time

Future Use: Pattern matching finds 94% similar incident
           → Suggests same resolution
```

When RCA is wrong:
```
RCA Prediction: CAPDaysUntilDiskFull
Human Validation: Actually was failing network switch ✗

Action: Update incident record
        Retrain model with corrected label
        Adjust causality weights
```

---

### Q: Does this replace human technicians?

**A:** No, it **augments** them.

**Humans still needed for:**
- Reviewing RCA reports
- Executing fixes
- Handling edge cases (<30% of incidents)
- Validating automated actions
- Strategic planning

**System handles:**
- Data analysis (277 metrics in 90 seconds)
- Pattern matching (compare to 1000s of historical incidents)
- Hypothesis testing (Granger causality across all metric pairs)
- Report generation

**Result:** Technicians spend time fixing problems, not searching for them.

---

## Conclusion

Root Cause Analysis transforms IT operations from **reactive** to **proactive**:

**Before RCA:**
- "The server is slow!" (4 hours of investigation)
- "Why did this happen?" (often unclear)
- "Will it happen again?" (unknown)

**After RCA:**
- "The server is slow because disk space is 98% full" (30 minutes)
- "This happened because log rotation failed" (clear root cause)
- "Yes, this will recur in 2 days unless fixed" (predictive)

**The power is in the automation** - letting machines do what they do best (analyze thousands of data points) so humans can do what they do best (solve problems).

---

**File:** Chapter_6_Explained.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 9:47 PM CET  
**Status:** Production Ready
