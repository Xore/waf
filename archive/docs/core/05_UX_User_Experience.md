# NinjaRMM Custom Field Framework - UX Fields
**File:** 05_UX_User_Experience.md
**Category:** UX (User Experience)
**Description:** User experience monitoring, performance tracking, and satisfaction scoring

---

## Overview

User experience fields track boot times, login performance, application responsiveness, and calculate overall user satisfaction scores for the Windows Automation Framework.

---

## UX - User Experience Core Fields

### UXBootTimeSeconds
- **Type:** Integer
- **Default:** 0
- **Purpose:** Most recent boot time in seconds
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Every 4 hours (after boot)
- **Range:** 0 to 9999 seconds
- **Measurement:** From BIOS handoff to desktop ready

**Performance Categories:**
```
0-30s    = Excellent (SSD with optimized startup)
31-60s   = Good (standard performance)
61-120s  = Fair (acceptable but improvable)
121-180s = Slow (user frustration likely)
181+s    = Very Slow (serious issue)
```

---

### UXLoginTimeSeconds
- **Type:** Integer
- **Default:** 0
- **Purpose:** Most recent user login time in seconds
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Every 4 hours (after login)
- **Range:** 0 to 9999 seconds
- **Measurement:** From credential entry to desktop usable

**Performance Categories:**
```
0-10s   = Excellent
11-20s  = Good
21-40s  = Fair
41-60s  = Slow
61+s    = Very Slow
```

---

### UXApplicationResponsiveness
- **Type:** Dropdown
- **Valid Values:** Excellent, Good, Fair, Poor, Critical
- **Default:** Good
- **Purpose:** Overall application responsiveness assessment
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Every 4 hours

**Assessment Logic:**
```
Excellent:
  - 0 hangs in 24h
  - All apps respond < 2s

Good:
  - 1-2 hangs in 24h
  - Most apps responsive

Fair:
  - 3-5 hangs in 24h
  - Occasional delays

Poor:
  - 6-10 hangs in 24h
  - Frequent delays

Critical:
  - 11+ hangs in 24h
  - Consistent unresponsiveness
```

---

### UXUserSatisfactionScore
- **Type:** Integer (0-100)
- **Default:** 75
- **Purpose:** Calculated user satisfaction score based on experience metrics
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Daily
- **Range:** 0 to 100

**Calculation:**
```
Base Score: 100

Deductions:
  - Boot time > 120s: -15 points
  - Login time > 40s: -10 points
  - Crashes per day: -5 points each (max -25)
  - Hangs per day: -3 points each (max -20)
  - Application responsiveness poor: -15 points
  - Network latency high: -10 points

Minimum Score: 0
```

---

### UXTopIssue
- **Type:** Text
- **Max Length:** 200 characters
- **Default:** None
- **Purpose:** Primary user experience issue identified
- **Populated By:** **Script 17** - Application Experience Profiler
- **Update Frequency:** Daily

**Example Values:**
```
Frequent application crashes (Outlook)
Slow boot time (avg 145 seconds)
High memory pressure causing slowdowns
Network latency affecting SaaS performance
Profile load issues extending login time
```

---

### UXLastUserFeedback
- **Type:** DateTime
- **Default:** Empty
- **Purpose:** Timestamp of last user-reported issue
- **Populated By:** Ticket integration or manual entry
- **Update Frequency:** Real-time
- **Format:** yyyy-MM-dd HH:mm:ss

---

## Script Integration

### Script 17: Application Experience Profiler
**Execution:** Every 4 hours
**Runtime:** ~30 seconds
**Fields Updated:**
- UXBootTimeSeconds
- UXLoginTimeSeconds
- UXApplicationResponsiveness
- UXUserSatisfactionScore
- UXTopIssue

---

**Total Fields:** 6 fields
**Category:** UX (User Experience)
**Last Updated:** February 2, 2026
