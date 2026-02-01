# Chapter 6: Root Cause Analysis Diagrams

**Version:** 1.0  
**Date:** February 1, 2026, 9:52 PM CET  
**Purpose:** Visual diagrams explaining RCA concepts and workflows

---

## Diagram 1: RCA Process Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ANOMALY DETECTED                                 │
│                    MLAnomalyScore = 92 (Critical)                        │
│                    Device: SERVER-PROD-05                                │
│                    Time: Feb 1, 2026 14:30:00                           │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 1: DATA EXTRACTION                                                 │
│  ═══════════════════════                                                 │
│                                                                          │
│  Incident Window:    Jan 31 14:30 → Feb 1 14:30  (24 hours)            │
│  Baseline Window:    Jan 24 14:30 → Jan 25 14:30 (7 days ago)          │
│                                                                          │
│  Data Collected:     277 metrics × 6 samples = 1,662 data points       │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 2: DEVIATION DETECTION (Z-Score Analysis)                          │
│  ═══════════════════════════════════════════                            │
│                                                                          │
│  Compare: Incident Mean vs Baseline Mean                                │
│  Method:  Z-Score = (Incident - Baseline) / StdDev                      │
│  Threshold: |Z-Score| > 2.0 = Significant Deviation                     │
│                                                                          │
│  Results: 23 metrics deviated significantly                             │
│           - CAPDaysUntilDiskFull:    Z = -4.5  (-95% change)            │
│           - STATMemoryUsedPercent:   Z = +4.8  (+185% change)           │
│           - STATAppCrashes24h:       Z = +3.9  (+650% change)           │
│           - OPSHealthScore:          Z = -3.5  (-42% change)            │
│           + 19 more...                                                   │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 3: TEMPORAL ORDERING (Timeline Construction)                       │
│  ══════════════════════════════════════════════                         │
│                                                                          │
│  Order deviations by first occurrence:                                  │
│                                                                          │
│  08:00 AM ─── CAPDaysUntilDiskFull       (First deviation)              │
│  08:45 AM ─── STATMemoryUsedPercent      (+45 min)                      │
│  09:15 AM ─── STATDiskActivePercent      (+75 min)                      │
│  10:30 AM ─── STATAppCrashes24h          (+150 min)                     │
│  11:00 AM ─── STATServiceFailures24h     (+180 min)                     │
│  12:00 PM ─── OPSHealthScore             (+240 min)                     │
│  12:30 PM ─── OPSStabilityScore          (+270 min)                     │
│                                                                          │
│  Pattern: Disk → Resources → Applications → System                      │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 4: CAUSAL ANALYSIS (Granger Causality Testing)                    │
│  ════════════════════════════════════════════════                       │
│                                                                          │
│  Test: Does metric A predict metric B?                                  │
│  Method: Granger causality (time-series prediction)                     │
│  Threshold: P-value < 0.05 = Statistically significant                  │
│                                                                          │
│  Causal Relationships Discovered:                                       │
│                                                                          │
│  CAPDaysUntilDiskFull ──────────┐                                       │
│         │                       │                                       │
│         ├──→ STATMemoryUsedPercent (p=0.003) ──→ STATAppCrashes24h     │
│         │                                                │              │
│         └──→ STATDiskActivePercent (p=0.008) ────────────┘              │
│                                                           │              │
│                                                           ▼              │
│                                            STATServiceFailures24h        │
│                                                           │              │
│                                                           ▼              │
│                                                    OPSHealthScore        │
│                                                                          │
│  Total: 12 causal relationships identified                              │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 5: ROOT CAUSE RANKING                                              │
│  ═══════════════════════                                                 │
│                                                                          │
│  Scoring Formula:                                                        │
│  Combined = (Temporal × 0.4) + (Causal × 0.4) + (Severity × 0.2)       │
│                                                                          │
│  Rankings:                                                               │
│                                                                          │
│  1. CAPDaysUntilDiskFull          98/100 ★★★ ROOT CAUSE                │
│     - Temporal:  100  (first deviation)                                 │
│     - Causal:    100  (causes 5 metrics)                                │
│     - Severity:   90  (Z=-4.5)                                          │
│                                                                          │
│  2. STATMemoryUsedPercent         84/100  (cascade effect)              │
│  3. STATDiskActivePercent         71/100  (symptom)                     │
│  4. STATAppCrashes24h             60/100  (downstream symptom)          │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 6: REPORT GENERATION & ACTION                                      │
│  ═══════════════════════════════════                                    │
│                                                                          │
│  Root Cause: Disk Space Exhaustion (98% confidence)                     │
│                                                                          │
│  Recommended Actions:                                                    │
│  1. Immediate: Clear temp files (Script 45)                             │
│  2. Short-term: Add 100GB storage                                       │
│  3. Long-term: Automated cleanup policies                               │
│                                                                          │
│  Update NinjaOne Fields:                                                │
│  - MLRootCauseAnalysis = [HTML Report]                                  │
│  - MLRootCauseMetric = "CAPDaysUntilDiskFull"                          │
│  - MLRootCauseConfidence = 98                                           │
│                                                                          │
│  Expected Resolution Time: 30-60 minutes                                │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Diagram 2: Z-Score Deviation Detection

```
═══════════════════════════════════════════════════════════════════════════
                    Z-SCORE STATISTICAL SIGNIFICANCE
═══════════════════════════════════════════════════════════════════════════

BASELINE DISTRIBUTION (Normal Operation - 7 days ago)
─────────────────────────────────────────────────────

         │
    40%  │                    ╭──────╮
         │                   ╱        ╲
    30%  │                  ╱          ╲
         │                 ╱            ╲
    20%  │               ╱                ╲
         │             ╱                    ╲
    10%  │          ╱                          ╲
         │      ╱                                  ╲
     0%  │──────────────────────────────────────────────────
         └────┴────┴────┴────┴────┴────┴────┴────┴────┴────
         0%   10%  20%  30%  40%  50%  60%  70%  80%  90% 100%
                              ↑
                          Mean = 45%
                          StdDev = 5%


INCIDENT DISTRIBUTION (Anomaly Period - Yesterday)
──────────────────────────────────────────────────

         │
    40%  │                                              ╭───╮
         │                                             ╱     ╲
    30%  │                                           ╱         ╲
         │                                          ╱           ╲
    20%  │                                        ╱               ╲
         │                                      ╱                   ╲
    10%  │                                   ╱                        ╲
         │                                ╱                             ╲
     0%  │────────────────────────────────────────────────────────────────
         └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────
         0%   10%  20%  30%  40%  50%  60%  70%  80%  90% 100%
                                                      ↑
                                                  Mean = 92%


Z-SCORE CALCULATION
───────────────────

Metric: STATMemoryUsedPercent

Baseline Mean (μ):        45%
Baseline StdDev (σ):       5%
Incident Mean:            92%

Z-Score = (92 - 45) / 5 = 47 / 5 = 9.4

│
│                                                          ★ Incident
│                                                          (Z = 9.4)
│                                                          │
│                                                          │
│  ══════════════════════════════════════════════════════│════
│  │      │      │      │      │      │      │      │     │
│  -3σ   -2σ   -1σ     μ     +1σ    +2σ    +3σ    +4σ  +9σ
│  ↑      ↑                    ↑      ↑
│  0.1%   2.5%                2.5%   0.1%
│  
│  Z = ±2.0 = 95% confidence (deviation threshold)
│  Z = ±3.0 = 99.7% confidence (critical)
│  Z = +9.4 = 99.9999%+ confidence (EXTREMELY abnormal)

INTERPRETATION
──────────────
Z-Score > 2.0  →  Flag as significant deviation
Memory usage is 9.4 standard deviations above normal
Probability this is random: < 0.0001%
Conclusion: CRITICAL ANOMALY - Requires immediate investigation
```

---

## Diagram 3: Granger Causality - Does A Cause B?

```
═══════════════════════════════════════════════════════════════════════════
              GRANGER CAUSALITY: DOES DISK SPACE CAUSE MEMORY PRESSURE?
═══════════════════════════════════════════════════════════════════════════

TIME SERIES DATA (24-hour incident window, 4-hour samples)
──────────────────────────────────────────────────────────

Time      CAPDaysUntilDiskFull    STATMemoryUsedPercent
────────  ───────────────────     ─────────────────────
00:00 AM         45 days                  45%
04:00 AM         38 days                  46%
08:00 AM          3 days   ← DROPS       48%
12:00 PM          2 days                  72%  ← RISES
04:00 PM          2 days                  85%  ← RISES
08:00 PM          2 days                  92%  ← RISES


VISUAL TIMELINE
───────────────

CAPDaysUntilDiskFull
│
45 ├──────────────╮
   │              │
40 │              │
   │              ╰──╮
30 │                 │
   │                 │
20 │                 │
   │                 ╰────────────┐
10 │                              │
   │                              ╰─────────────────────
 0 ├──────────────────────────────────────────────────────
   └────┬────┬────┬────┬────┬────┬────
       00:00 04:00 08:00 12:00 16:00 20:00
                    ↑
                SUDDEN DROP (disk running out)


STATMemoryUsedPercent
│
100├                              ╭────────────────────
   │                          ╭───╯
90 │                      ╭───╯
   │                  ╭───╯
80 │              ╭───╯
   │          ╭───╯
70 │      ╭───╯
   │  ╭───╯
60 │╭─╯
   │╯
50 ├──────────────────────
   └────┬────┬────┬────┬────┬────┬────
       00:00 04:00 08:00 12:00 16:00 20:00
                          ↑
                    STARTS CLIMBING (45 min after disk drop)


GRANGER CAUSALITY TEST
──────────────────────

Hypothesis: CAPDaysUntilDiskFull causes STATMemoryUsedPercent

Test 1: Predict memory using ONLY memory history
   Model: Memory(t) = f(Memory(t-1), Memory(t-2), Memory(t-3))
   Accuracy: R² = 0.65

Test 2: Predict memory using memory history + disk space history
   Model: Memory(t) = f(Memory(t-1), Memory(t-2), Memory(t-3),
                       Disk(t-1), Disk(t-2), Disk(t-3))
   Accuracy: R² = 0.94

F-Test: Is Test 2 significantly better than Test 1?
   F-statistic: 18.7
   P-value: 0.003

CONCLUSION: P < 0.05 → REJECT null hypothesis
            CAPDaysUntilDiskFull DOES Granger-cause STATMemoryUsedPercent ✓

Interpretation: Disk space changes predict future memory pressure
                → Disk space exhaustion likely CAUSES memory issues


WHY THIS HAPPENS (Technical Explanation)
─────────────────────────────────────────

Low Disk Space → Windows increases RAM caching
              → Less space for page file
              → Memory pressure increases
              → Applications compete for limited RAM
```

---

## Diagram 4: Failure Cascade Chain

```
═══════════════════════════════════════════════════════════════════════════
                         FAILURE CASCADE VISUALIZATION
═══════════════════════════════════════════════════════════════════════════

ROOT CAUSE
──────────
   ╔═══════════════════════════════╗
   ║  CAPDaysUntilDiskFull = 2d    ║  ← ROOT CAUSE (98/100 confidence)
   ║  Normal: 45d → Current: 2d    ║
   ║  Change: -95.6%               ║
   ║  First Deviation: 08:00 AM    ║
   ╚═══════════════════════════════╝
              │
              │ Granger Causality
              │ P-value: 0.003
              │
              ├─────────────────────┬─────────────────────┐
              ▼                     ▼                     ▼
   ┌─────────────────────┐  ┌─────────────────────┐  ┌──────────────────┐
   │ STATMemoryUsed      │  │ STATDiskActive      │  │ Windows Page File│
   │ Percent = 92%       │  │ Percent = 95%       │  │ Insufficient     │
   │ Normal: 45%         │  │ Normal: 35%         │  │                  │
   │ Time: 08:45 AM      │  │ Time: 09:15 AM      │  │ Time: 08:30 AM   │
   └─────────────────────┘  └─────────────────────┘  └──────────────────┘
              │                     │                          │
              │                     │                          │
              │ P=0.012            │ P=0.015                  │
              │                     │                          │
              └─────────────────────┴──────────────────────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │ STATAppCrashes24h   │  ← APPLICATION LAYER
                         │ = 15 crashes        │
                         │ Normal: 2 crashes   │
                         │ Change: +650%       │
                         │ Time: 10:30 AM      │
                         └─────────────────────┘
                                    │
                                    │ P=0.019
                                    │
                         ┌──────────┴──────────┐
                         ▼                     ▼
              ┌─────────────────────┐  ┌─────────────────────┐
              │ STATService         │  │ User Experience     │
              │ Failures24h = 8     │  │ Degradation         │
              │ Normal: 0           │  │ UXUserSatisfaction  │
              │ Time: 11:00 AM      │  │ = 25/100            │
              └─────────────────────┘  └─────────────────────┘
                         │                     │
                         │                     │
                         └──────────┬──────────┘
                                    │ P=0.028
                                    ▼
                         ┌─────────────────────┐
                         │ OPSHealthScore      │  ← SYSTEM HEALTH
                         │ = 35/100            │
                         │ Normal: 92/100      │
                         │ Change: -62%        │
                         │ Time: 12:00 PM      │
                         └─────────────────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │ CRITICAL ANOMALY    │  ← FINAL DETECTION
                         │ MLAnomalyScore = 92 │
                         │ Time: 02:30 PM      │
                         └─────────────────────┘


TIMELINE SUMMARY
────────────────

08:00 AM ───● CAPDaysUntilDiskFull drops to 2 days (ROOT CAUSE)
            │
08:30 AM ───├● Page file issues begin
            │
08:45 AM ───├● Memory pressure starts (92%)
            │
09:15 AM ───├● Disk I/O saturated (95%)
            │
10:30 AM ───├● Applications start crashing (15 crashes)
            │
11:00 AM ───├● Services begin failing (8 failures)
            │
12:00 PM ───├● Health score crashes (35/100)
            │
02:30 PM ───├● Anomaly detected by ML (MLAnomalyScore = 92)
            │
            └──→ RCA runs automatically → Identifies disk space as root cause


CAUSAL STRENGTH
───────────────

CAPDaysUntilDiskFull → STATMemoryUsedPercent    [████████████] 0.997
CAPDaysUntilDiskFull → STATDiskActivePercent    [███████████ ] 0.992
STATMemoryUsedPercent → STATAppCrashes24h       [██████████  ] 0.988
STATDiskActivePercent → STATAppCrashes24h       [█████████   ] 0.985
STATAppCrashes24h → STATServiceFailures24h      [████████    ] 0.979
STATServiceFailures24h → OPSHealthScore         [███████     ] 0.972
```

---

## Diagram 5: Root Cause Scoring Algorithm

```
═══════════════════════════════════════════════════════════════════════════
                       ROOT CAUSE SCORING ALGORITHM
═══════════════════════════════════════════════════════════════════════════

THREE SCORING DIMENSIONS
────────────────────────

1. TEMPORAL SCORE (40% weight)
   ├─ "How early did this metric deviate?"
   ├─ First deviation = 100 points
   ├─ Last deviation = 0 points
   └─ Linear scaling between

2. CAUSAL SCORE (40% weight)
   ├─ "How many downstream effects does this cause?"
   ├─ Number of causal relationships × 20 points
   ├─ Average causal strength × 50 points
   └─ Capped at 100 points

3. SEVERITY SCORE (20% weight)
   ├─ "How abnormal is the deviation?"
   ├─ Based on Z-score magnitude
   ├─ |Z-score| × 20 points
   └─ Capped at 100 points


EXAMPLE CALCULATION: CAPDaysUntilDiskFull
──────────────────────────────────────────

TEMPORAL SCORE
──────────────
Deviations ranked by time:
   1. CAPDaysUntilDiskFull      08:00 AM ← This metric (Rank 1)
   2. STATMemoryUsedPercent     08:45 AM
   3. STATDiskActivePercent     09:15 AM
   4. STATAppCrashes24h         10:30 AM
   5. STATServiceFailures24h    11:00 AM
   6. OPSHealthScore            12:00 PM
   7. OPSStabilityScore         12:30 PM

Temporal Score = 100 × (1 - (rank - 1) / (total - 1))
               = 100 × (1 - (1 - 1) / (7 - 1))
               = 100 × (1 - 0/6)
               = 100 × 1
               = 100 points ✓


CAUSAL SCORE
────────────
Causal relationships where CAPDaysUntilDiskFull is the cause:
   1. CAPDaysUntilDiskFull → STATMemoryUsedPercent   (strength: 0.997)
   2. CAPDaysUntilDiskFull → STATDiskActivePercent   (strength: 0.992)
   3. CAPDaysUntilDiskFull → PageFileIssues          (strength: 0.985)
   4. CAPDaysUntilDiskFull → STATBootTimeSec         (strength: 0.945)
   5. CAPDaysUntilDiskFull → SECEventLogFull         (strength: 0.912)

Number of effects: 5
Average strength: (0.997 + 0.992 + 0.985 + 0.945 + 0.912) / 5 = 0.966

Causal Score = min(100, num_effects × 20 + avg_strength × 50)
             = min(100, 5 × 20 + 0.966 × 50)
             = min(100, 100 + 48.3)
             = 100 points (capped) ✓


SEVERITY SCORE
──────────────
Baseline: 45 days until full
Incident: 2 days until full
Change: -43 days (-95.6%)

Z-Score = (2 - 45) / 10 = -43 / 10 = -4.3

Severity Score = min(100, |Z-score| × 20)
               = min(100, 4.3 × 20)
               = min(100, 86)
               = 86 points ✓


COMBINED SCORE
──────────────
Combined = (Temporal × 0.4) + (Causal × 0.4) + (Severity × 0.2)
         = (100 × 0.4) + (100 × 0.4) + (86 × 0.2)
         = 40 + 40 + 17.2
         = 97.2 / 100

CONCLUSION: CAPDaysUntilDiskFull is the root cause (97.2% confidence)


COMPARISON TO OTHER CANDIDATES
───────────────────────────────

Metric                      Temporal  Causal  Severity  Combined  Rank
────────────────────────    ────────  ──────  ────────  ────────  ────
CAPDaysUntilDiskFull          100      100      86       97.2      #1 ★
STATMemoryUsedPercent          86       75      96       84.2      #2
STATDiskActivePercent          71       50      78       66.2      #3
STATAppCrashes24h              57       50      78       60.2      #4
STATServiceFailures24h         43       25      60       42.0      #5
OPSHealthScore                 29        0     100       41.8      #6
OPSStabilityScore              14       25      58       30.2      #7

Root Cause: #1 (CAPDaysUntilDiskFull)
Symptoms: #2-#7 (downstream effects)
```

---

## Diagram 6: Manual vs Automated RCA Comparison

```
═══════════════════════════════════════════════════════════════════════════
                   MANUAL RCA vs AUTOMATED RCA COMPARISON
═══════════════════════════════════════════════════════════════════════════

SCENARIO: Production server anomaly detected
          MLAnomalyScore = 92 (Critical)
          Device: SERVER-PROD-05


┌───────────────────────────────────────────────────────────────────────┐
│                         MANUAL RCA PROCESS                             │
│                        (Traditional Approach)                          │
└───────────────────────────────────────────────────────────────────────┘

14:30  ● Anomaly detected → Alert sent to technician
       │
14:35  ├─ Technician receives alert (5 min response time)
       │
14:40  ├─ Log into server via RDP (5 min)
       │  └─ Check Task Manager
       │     └─ "CPU at 45%, Memory at 92% - memory issue?"
       │
15:00  ├─ Check Event Viewer (20 min)
       │  └─ Find 200+ errors across 15 event logs
       │     └─ "Application crashes... service failures... disk errors?"
       │
15:30  ├─ Review NinjaOne dashboards (30 min)
       │  └─ Manually check 277 custom fields
       │     └─ "Performance tab... stability tab... capacity tab..."
       │        └─ "Too much data - need to narrow down"
       │
16:00  ├─ Check disk space (30 min)
       │  └─ "C: drive is 98% full - this could be it!"
       │     └─ "But why is memory at 92%? Is disk the real cause?"
       │
16:30  ├─ Test hypothesis: Clear 5GB temp files (30 min)
       │  └─ Memory still at 88%
       │     └─ "Partially helped but not resolved"
       │
17:00  ├─ Escalate to senior technician (30 min)
       │  └─ Senior reviews all data again
       │     └─ "Disk space is causing page file issues → memory pressure"
       │
17:30  ├─ Implement full fix: Add 100GB storage + restart (30 min)
       │
18:00  └─ Resolved ✓

TOTAL TIME: 3.5 hours (210 minutes)
SUCCESS RATE: 60-70% (sometimes root cause is missed)
COST: €175 (3.5 hours × €50/hour)


┌───────────────────────────────────────────────────────────────────────┐
│                        AUTOMATED RCA PROCESS                           │
│                      (ML-Powered Approach)                             │
└───────────────────────────────────────────────────────────────────────┘

14:30  ● Anomaly detected → RCA system auto-triggered
       │
14:30  ├─ Extract incident & baseline data (10 sec)
       │  └─ 277 metrics × 6 samples = 1,662 data points loaded
       │
14:30  ├─ Detect deviations (Z-score analysis) (20 sec)
       │  └─ 23 metrics deviated significantly
       │
14:31  ├─ Build timeline (temporal ordering) (5 sec)
       │  └─ CAPDaysUntilDiskFull deviated first (08:00 AM)
       │
14:31  ├─ Test Granger causality (30 sec)
       │  └─ 12 causal relationships identified
       │     └─ Disk → Memory (p=0.003)
       │     └─ Memory → Crashes (p=0.012)
       │
14:31  ├─ Rank root causes (5 sec)
       │  └─ CAPDaysUntilDiskFull = 97.2/100 (ROOT CAUSE)
       │
14:32  ├─ Pattern matching (10 sec)
       │  └─ 94% similar to INC-2025-1234 (Nov 2025)
       │     └─ Previous fix: Clear temp files + add storage
       │
14:32  ├─ Generate report (10 sec)
       │  └─ HTML report created with:
       │     - Root cause: Disk space (97.2% confidence)
       │     - Failure cascade diagram
       │     - Recommended actions
       │     - Similar incidents
       │
14:32  ├─ Update NinjaOne fields (5 sec)
       │  └─ MLRootCauseAnalysis = [Report]
       │     └─ MLRootCauseConfidence = 97
       │        └─ Alert technician with analysis
       │
14:35  ├─ Technician reviews RCA report (5 min)
       │  └─ "Report shows disk space is root cause with 97% confidence"
       │     └─ "Recommends Script 45 + add storage"
       │        └─ "Similar incident resolved in 45 min last time"
       │
14:50  ├─ Execute recommended actions (15 min)
       │  └─ Run Script 45 (disk cleanup)
       │     └─ Add 100GB storage via hypervisor
       │
15:00  └─ Resolved ✓

TOTAL TIME: 30 minutes
SUCCESS RATE: 70-85% (validated against historical incidents)
COST: €25 (0.5 hours × €50/hour)


COMPARISON TABLE
────────────────

Metric                      Manual RCA    Automated RCA    Improvement
──────────────────────────  ────────────  ──────────────  ───────────
Time to Resolution          3.5 hours     30 minutes       -85.7%
Cost per Incident           €175          €25              -85.7%
Success Rate                60-70%        70-85%           +15-25%
Data Points Analyzed        50-100        1,662            +1,500%
Technician Effort           High          Low              -90%
Repeatability              Low           High             +++
Pattern Recognition        Manual        Automatic         +++
Documentation              Minimal       Comprehensive     +++


ROI ANALYSIS (50 incidents/year)
────────────────────────────────

Manual Approach:
  50 incidents × 3.5 hours = 175 hours
  175 hours × €50/hour = €8,750/year

Automated Approach:
  50 incidents × 0.5 hours = 25 hours
  25 hours × €50/hour = €1,250/year
  + ML infrastructure: €500/month = €6,000/year
  Total: €7,250/year

ANNUAL SAVINGS: €8,750 - €7,250 = €1,500 in labor
PLUS: Reduced downtime = €5,000-€10,000/year
TOTAL BENEFIT: €6,500-€11,500/year

PAYBACK PERIOD: 2-3 months
```

---

## Diagram 7: Data Flow Architecture

```
═══════════════════════════════════════════════════════════════════════════
                    RCA SYSTEM DATA FLOW ARCHITECTURE
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                      NINJAONE FRAMEWORK                                  │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  277 Custom Fields                                               │   │
│  │  ├─ OPS (Operational Scores): 25 fields                         │   │
│  │  ├─ STAT (Telemetry): 28 fields                                 │   │
│  │  ├─ CAP (Capacity): 15 fields                                   │   │
│  │  ├─ SEC (Security): 22 fields                                   │   │
│  │  ├─ NET (Network): 18 fields                                    │   │
│  │  └─ ... 169 more fields                                         │   │
│  │                                                                  │   │
│  │  Updated by 110 Scripts                                         │   │
│  │  ├─ Every 4 hours: Scripts 1-13 (performance, stability)        │   │
│  │  ├─ Daily: Scripts 14-50 (security, compliance, UX)            │   │
│  │  └─ Weekly: Scripts 51-110 (capacity, predictive)              │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ NinjaOne API
                             │ GET /api/v2/devices/{id}/custom-fields
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      DATA EXPORT LAYER                                   │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Scheduled Export Job (Daily)                                    │   │
│  │  ├─ Export all 277 fields for all devices                       │   │
│  │  ├─ Include timestamps                                          │   │
│  │  └─ Output: CSV/JSON                                            │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   TIME-SERIES DATABASE                                   │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  InfluxDB / TimescaleDB / PostgreSQL                            │   │
│  │                                                                  │   │
│  │  Schema:                                                         │   │
│  │  ├─ DeviceID (index)                                            │   │
│  │  ├─ Timestamp (index)                                           │   │
│  │  ├─ OPSHealthScore (float)                                      │   │
│  │  ├─ OPSStabilityScore (float)                                   │   │
│  │  ├─ STATAppCrashes24h (int)                                     │   │
│  │  └─ ... 274 more columns                                        │   │
│  │                                                                  │   │
│  │  Retention: 90 days detailed, 1 year aggregated                 │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ Triggered by anomaly alert
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     RCA ANALYSIS ENGINE                                  │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  AutomatedRCASystem (Python)                                     │   │
│  │                                                                  │   │
│  │  Step 1: Data Extraction                                        │   │
│  │  ├─ Query incident window (24h before anomaly)                  │   │
│  │  └─ Query baseline window (7 days ago, same 24h)                │   │
│  │     └─ SQL: SELECT * FROM metrics WHERE ...                     │   │
│  │                                                                  │   │
│  │  Step 2: Deviation Detection                                    │   │
│  │  ├─ Calculate baseline statistics (mean, stddev)                │   │
│  │  ├─ Calculate incident statistics                               │   │
│  │  ├─ Compute Z-scores                                            │   │
│  │  └─ Flag |Z| > 2.0                                              │   │
│  │     └─ Output: 23 deviated metrics                              │   │
│  │                                                                  │   │
│  │  Step 3: Timeline Analysis                                      │   │
│  │  ├─ Find first deviation timestamp per metric                   │   │
│  │  └─ Sort chronologically                                        │   │
│  │     └─ Output: Ordered timeline                                 │   │
│  │                                                                  │   │
│  │  Step 4: Causality Testing                                      │   │
│  │  ├─ For each metric pair (A, B):                                │   │
│  │  │   └─ Granger causality test                                  │   │
│  │  │      └─ If p < 0.05: A causes B                              │   │
│  │  └─ Build causality graph                                       │   │
│  │     └─ Output: 12 causal relationships                          │   │
│  │                                                                  │   │
│  │  Step 5: Root Cause Ranking                                     │   │
│  │  ├─ Calculate temporal score (40%)                              │   │
│  │  ├─ Calculate causal score (40%)                                │   │
│  │  ├─ Calculate severity score (20%)                              │   │
│  │  └─ Combined weighted score                                     │   │
│  │     └─ Output: Ranked candidates                                │   │
│  │                                                                  │   │
│  │  Step 6: Pattern Matching                                       │   │
│  │  ├─ Create incident signature (277-dim vector)                  │   │
│  │  ├─ Compare to historical incidents (cosine similarity)         │   │
│  │  └─ Return top 5 similar incidents                              │   │
│  │     └─ Output: 94% match to INC-2025-1234                       │   │
│  │                                                                  │   │
│  │  Step 7: Report Generation                                      │   │
│  │  ├─ Generate HTML report                                        │   │
│  │  │   ├─ Root cause: CAPDaysUntilDiskFull (97%)                 │   │
│  │  │   ├─ Failure cascade diagram                                │   │
│  │  │   ├─ Timeline visualization                                 │   │
│  │  │   └─ Recommended actions                                    │   │
│  │  └─ Natural language summary                                    │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ Update results
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   NINJAONE FEEDBACK LOOP                                 │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Update Custom Fields (API POST)                                 │   │
│  │  ├─ MLRootCauseAnalysis (WYSIWYG HTML)                          │   │
│  │  ├─ MLRootCauseMetric (Text): "CAPDaysUntilDiskFull"           │   │
│  │  ├─ MLRootCauseConfidence (Integer): 97                         │   │
│  │  ├─ MLRCATimestamp (DateTime): 2026-02-01 14:32:00             │   │
│  │  └─ MLRecommendedAction (Text): "Run Script 45 + add storage"  │   │
│  │                                                                  │   │
│  │  Trigger Automation                                             │   │
│  │  ├─ If confidence > 80: Auto-execute remediation               │   │
│  │  ├─ If confidence 60-80: Alert technician for review           │   │
│  │  └─ If confidence < 60: Flag for manual investigation          │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                  HISTORICAL INCIDENT DATABASE                            │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Store Validated Incidents                                       │   │
│  │  ├─ Incident signature (277-dim vector)                         │   │
│  │  ├─ Root cause (validated by human)                             │   │
│  │  ├─ Resolution steps                                            │   │
│  │  ├─ Resolution time                                             │   │
│  │  └─ Outcome (success/failure)                                   │   │
│  │                                                                  │   │
│  │  Used For:                                                       │   │
│  │  ├─ Pattern matching (find similar incidents)                   │   │
│  │  ├─ Model retraining (quarterly)                                │   │
│  │  └─ Knowledge base (recurring issues)                           │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘


PERFORMANCE METRICS
───────────────────
- Data extraction: 10 seconds
- Deviation detection: 20 seconds
- Causality testing: 30 seconds
- Root cause ranking: 5 seconds
- Report generation: 10 seconds
──────────────────────────────────
TOTAL: ~90 seconds (1.5 minutes)
```

---

**File:** Chapter_6_RCA_Diagrams.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 9:52 PM CET  
**Status:** Production Ready
