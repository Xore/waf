# NinjaRMM Custom Field Framework - OPS Core Operational Scores (Native-Enhanced)

**File:** 01_OPS_Operational_Scores.md  
**Version:** v1.0 (Initial Native Integration Release)  
**Category:** OPS (Operational Composite Scores)  
**Field Count:** 6 OPS fields  
**Last Updated:** February 2, 2026

---

## Overview

OPS fields provide intelligent composite scoring that combines multiple data sources, including NinjaOne native metrics and custom telemetry, to express device state as simple 0–100 scores.

Native CPU, Memory, Disk, Network, and other core metrics are provided by NinjaOne. OPS scores no longer rely on custom resource-collection fields.

---

## OPS Fields (6)

### OPSHealthScore
- Type: Integer (0-100)  
- Default: 100  
- Purpose: Overall device health composite score  
- Populated By: Script 1 - Health Score Calculator  
- Update Frequency: Every 4 hours  
- Data Sources: Native metrics + custom intelligence

Scoring logic:
```text
Base Score: 100

Deductions (using native metrics):
  - Crashes (STATAppCrashes24h > 10): -20 points
  - Disk Free Space < 15% (native): -15 points
  - Memory Utilization > 90% (native): -15 points
  - Service failures: -10 points
  - Security issues: -20 points
  - Updates overdue: -10 points
  - Boot time > 120s: -10 points

Minimum Score: 0
```

Score categories:
```text
90-100 = Excellent
70-89  = Good
50-69  = Fair
30-49  = Poor
0-29   = Critical
```

---

### OPSStabilityScore
- Type: Integer (0-100)  
- Default: 100  
- Purpose: Application and system stability score  
- Populated By: Script 2 - Stability Analyzer  
- Update Frequency: Every 4 hours  
- Data Sources: Event logs + crash telemetry

Scoring logic:
```text
Base Score: 100

Deductions:
  - Each crash (24h): -2 points
  - Each hang (24h): -1.5 points
  - Each service failure: -3 points
  - Each BSOD: -20 points
  - Uptime < 24h with crashes: -10 points

Minimum Score: 0
```

---

### OPSPerformanceScore
- Type: Integer (0-100)  
- Default: 100  
- Purpose: System performance and responsiveness score  
- Populated By: Script 3 - Performance Analyzer  
- Update Frequency: Every 4 hours  
- Data Sources: Native performance metrics + custom measurements

Scoring logic:
```text
Base Score: 100

Deductions (using native metrics):
  - CPU Utilization > 80% (native): -15 points
  - Memory Utilization > 85% (native): -15 points
  - Disk Active Time > 80% (native): -10 points
  - Boot time > 120s (custom): -15 points
  - Network latency > 100ms (native): -10 points

Minimum Score: 0
```

---

### OPSSecurityScore
- Type: Integer (0-100)  
- Default: 100  
- Purpose: Security posture score  
- Populated By: Script 4 - Security Analyzer  
- Update Frequency: Daily  
- Data Sources: Native security status + custom hardening checks

Scoring logic:
```text
Base Score: 100

Deductions (using native metrics):
  - Antivirus disabled/not installed (native): -40 points
  - Firewall disabled (native): -30 points
  - BitLocker disabled: -15 points
  - Critical patches missing (native): -15 points
  - SMBv1 enabled: -10 points

Minimum Score: 0
```

---

### OPSCapacityScore
- Type: Integer (0-100)  
- Default: 100  
- Purpose: Resource capacity and headroom score  
- Populated By: Script 5 - Capacity Analyzer  
- Update Frequency: Daily  
- Data Sources: Native capacity metrics + predictive analytics

Scoring logic:
```text
Base Score: 100

Deductions (using native metrics):
  - Disk Free Space < 20% (native): -30 points
  - Disk Free Space < 10% (native): -50 points (override)
  - Memory Utilization > 85% (native): -20 points
  - CPU Utilization sustained > 75% (native): -15 points
  - Days until disk full < 30 (custom predictive): -15 points

Minimum Score: 0
```

---

### OPSLastScoreUpdate
- Type: DateTime  
- Default: Empty  
- Purpose: Timestamp of last OPS score calculation  
- Populated By: Scripts 1–5  
- Update Frequency: Every 4 hours  
- Format: yyyy-MM-dd HH:mm:ss

---

## Script-to-OPS Mapping

- Script 1: Health Score Calculator → OPSHealthScore, OPSLastScoreUpdate  
- Script 2: Stability Analyzer → OPSStabilityScore, OPSLastScoreUpdate  
- Script 3: Performance Analyzer → OPSPerformanceScore, OPSLastScoreUpdate  
- Script 4: Security Analyzer → OPSSecurityScore, OPSLastScoreUpdate  
- Script 5: Capacity Analyzer → OPSCapacityScore, OPSLastScoreUpdate  

---

File: 01_OPS_Operational_Scores.md  
Framework Version: v1.0  
Status: Production Ready
