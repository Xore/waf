# NinjaRMM Custom Field Framework - STAT Core Telemetry

**File:** 03_STAT_Telemetry.md  
**Version:** v1.0 (Initial Release)  
**Category:** STAT (Raw Telemetry)  
**Field Count:** 6 STAT fields  
**Last Updated:** February 2, 2026

---

## Overview

STAT fields collect custom telemetry that is not available directly as aggregate metrics in NinjaOne, primarily by aggregating Windows Event Log data into counters and timestamps.

---

## STAT Fields (6)

### STATAppCrashes24h
- Type: Integer  
- Default: 0  
- Purpose: Application crash count in last 24 hours  
- Populated By: Script 6 - Telemetry Collector  
- Update Frequency: Every 4 hours  
- Range: 0–9999  
- Event Source: Application Event Log, Event ID 1000, 1001

---

### STATAppHangs24h
- Type: Integer  
- Default: 0  
- Purpose: Application hang/freeze count in last 24 hours  
- Populated By: Script 6 - Telemetry Collector  
- Update Frequency: Every 4 hours  
- Range: 0–9999  
- Event Source: Application Event Log, Event ID 1002

---

### STATServiceFailures24h
- Type: Integer  
- Default: 0  
- Purpose: Windows service failure count in last 24 hours  
- Populated By: Script 6 - Telemetry Collector  
- Update Frequency: Every 4 hours  
- Range: 0–9999  
- Event Source: System Event Log, Event ID 7031, 7034

---

### STATBSODCount30d
- Type: Integer  
- Default: 0  
- Purpose: BSOD count in last 30 days  
- Populated By: Script 6 - Telemetry Collector  
- Update Frequency: Daily  
- Range: 0–999  
- Event Source: System Event Log, Event ID 1001 (BugCheck), 41 (Kernel-Power)

---

### STATUptimeDays
- Type: Integer  
- Default: 0  
- Purpose: Days since last reboot  
- Populated By: Script 6 - Telemetry Collector  
- Update Frequency: Every 4 hours  
- Range: 0–9999  
- Calculation: (Current time - Last boot time) in days

---

### STATLastTelemetryUpdate
- Type: DateTime  
- Default: Empty  
- Purpose: Timestamp of last telemetry collection  
- Populated By: Script 6 - Telemetry Collector  
- Update Frequency: Every 4 hours  
- Format: yyyy-MM-dd HH:mm:ss

---

## Script-to-STAT Mapping

Script 6: Telemetry Collector  
- Updates:  
  - STATAppCrashes24h  
  - STATAppHangs24h  
  - STATServiceFailures24h  
  - STATBSODCount30d  
  - STATUptimeDays  
  - STATLastTelemetryUpdate  

---

File: 03_STAT_Telemetry.md  
Framework Version: v1.0  
Status: Production Ready
