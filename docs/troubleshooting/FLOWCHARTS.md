# WAF Troubleshooting Flowcharts

**Purpose:** Decision-tree flowcharts for common issues  
**Last Updated:** February 9, 2026

---

## How to Use These Flowcharts

1. **Start at the top** of the relevant flowchart
2. **Follow the arrows** based on your situation
3. **Perform the suggested action** at each step
4. **Continue until resolved** or escalation needed

---

## Flowchart 1: Script Execution Failure

```
                    Script Execution Failed?
                             |
                             v
              Check NinjaRMM Activity Log
              for Error Message
                             |
       +---------------------+---------------------+
       |                     |                     |
       v                     v                     v
  "Access Denied"      "Timeout"           "Command Not Found"
       |                     |                     |
       v                     v                     v
  Check Execution      Check Script          Check PowerShell
  Context              Duration              Version
       |                     |                     |
       v                     v                     v
  Should be SYSTEM     Compare to            Need 5.1+
       |               Timeout Setting             |
       |                     |                     |
       v                     v                     v
  If not SYSTEM:       Duration > Timeout?   If < 5.1:
  - Check automation        |                 - Upgrade PS
    policy settings    +----+----+            - Or remove
  - Verify script           |    |              device from
    category            YES  |    NO            WAF pilot
  - Re-upload script        |    |                   |
       |                    v    v                   v
       |              Increase  Script            RESOLVED
       |              Timeout   Logic
       |              by 50%    Error
       |                  |         |
       v                  v         v
  RESOLVED          RESOLVED   Review Script
                                    Code
                                    |
                                    v
                               Fix & Retest
                                    |
                                    v
                               RESOLVED

       +---------------------+---------------------+
       |                     |                     |
       v                     v                     v
  "Network Error"    "WMI Error"       "Other Error"
       |                     |                     |
       v                     v                     v
  Check:               Check:                Review:
  - Connectivity       - WMI service         - Full error
  - Firewall          running                 log
  - DNS               - WMI repository       - Script code
  - Proxy             corruption             - Recent changes
       |                     |                     |
       v                     v                     v
  Fix Network          Repair WMI           Contact Support
  Issue                Repository            with Details
       |                     |                     |
       v                     v                     v
  RESOLVED            RESOLVED             ESCALATED


ESCALATION CRITERIA:
- Error persists after following flowchart
- Error affects multiple devices (>10%)
- No clear error message
- Suspected product bug
```

---

## Flowchart 2: Field Not Populating

```
                  Custom Field is Empty?
                           |
                           v
          Which script populates this field?
          (See Field Quick Reference)
                           |
                           v
              Is that script executing?
              (Check Automation Activity)
                           |
              +------------+------------+
              |                         |
              v                         v
             NO                        YES
              |                         |
              v                         |
      Script Not Running                |
              |                         |
      +-------+-------+                 |
      |               |                 |
      v               v                 |
  Automation      Device Not            |
  Policy          in Target             |
  Disabled        Group                 |
      |               |                 |
      v               v                 |
  Enable          Add Device            |
  Policy          to Group              |
      |               |                 |
      v               v                 |
  RESOLVED        RESOLVED              |
                                        |
                                        v
                          Is script execution successful?
                          (Check for errors)
                                        |
                           +------------+------------+
                           |                         |
                           v                         v
                          NO                        YES
                           |                         |
                           v                         |
                  Script Failing                     |
                           |                         |
                           v                         |
            Use "Script Failure" Flowchart          |
                           |                         |
                           v                         |
                      RESOLVED                       |
                                                     |
                                                     v
                              Script succeeds but field empty?
                                                     |
                                    +----------------+----------------+
                                    |                                 |
                                    v                                 v
                        Check Field Name                   Check Ninja-Property-Set
                        in Script Code                     Command Present
                                    |                                 |
                                    v                                 v
                        Field name matches exactly?        Command present?
                        (case-sensitive!)                           |
                                    |                     +-----------+-----------+
                         +----------+----------+          |                       |
                         |                     |          v                       v
                         v                     v         YES                      NO
                        YES                   NO          |                       |
                         |                     |          |                       v
                         |                     v          |                  Add Command
                         |             Fix Field Name     |                  to Script
                         |             in Script          |                       |
                         |                     |          |                       v
                         v                     v          |                  RESOLVED
                Check Field Type       RESOLVED           |
                Compatible?                               |
                         |                                 |
              +----------+----------+                      |
              |                     |                      |
              v                     v                      |
             YES                   NO                      |
              |                     |                      |
              v                     v                      |
     Check Value Format    Fix Field Type                 |
     (e.g., Unix Epoch)    or Script Logic                |
              |                     |                      |
              v                     v                      |
     Value correct?           RESOLVED                    |
              |                                             |
    +---------+---------+                                 |
    |                   |                                 |
    v                   v                                 |
   YES                 NO                                 |
    |                   |                                 |
    |                   v                                 |
    |          Fix Value Format                           |
    |                   |                                 |
    |                   v                                 |
    |              RESOLVED                                |
    |                                                      |
    v                                                     |
Contact Support                                          |
(Unexpected Issue)                                       |
    |                                                      |
    v                                                     v
ESCALATED                                           RESOLVED


COMMON FIELD NAME MISTAKES:
- Wrong capitalization (opsHealthScore not opshealthscore)
- Typos (opsCapacityScore not opsCapacityScor)
- Wrong prefix (opsStatus not statStatus)

COMMON VALUE FORMAT ISSUES:
- Dates not in Unix Epoch (use [int](Get-Date -UFormat %s))
- Strings too long for field type
- Invalid dropdown values
- Special characters in text fields
```

---

## Flowchart 3: Performance Impact

```
            Device Performance Degraded?
            User Reports Slowness?
                      |
                      v
        When does slowness occur?
                      |
        +-------------+-------------+
        |                           |
        v                           v
   All the Time              During Specific Times
        |                           |
        v                           |
   Likely NOT WAF                  |
   (WAF scripts run               |
    in background)                 |
        |                           |
        v                           v
  Investigate:            Check Script Execution
  - Other software        Schedule
  - Malware                       |
  - Hardware                      v
  - Windows issues       Does timing match?
        |                          |
        v               +----------+----------+
  NOT WAF RELATED       |                     |
                        v                     v
                       YES                   NO
                        |                     |
                        |                     v
                        |              NOT WAF RELATED
                        |              (Coincidence)
                        |                     |
                        v                     v
            Check Script Execution      RESOLVED
            Times in Logs
                        |
                        v
        Are any scripts taking >30s?
                        |
          +-------------+-------------+
          |                           |
          v                           v
         YES                         NO
          |                           |
          v                           v
  Which scripts are slow?     Scripts fast but
          |                   still slow?
          |                           |
          v                           v
  Check Script Logs          Check Concurrent
  for Details                Execution
          |                           |
          v                           |
  Common Slow Scripts:               |
  - Script 6 (Updates)               |
  - Script 4 (Security)              |
  - Script 2 (Stability)             |
          |                           |
          v                           v
  Optimization Options:      Too Many Scripts
                             Running at Once?
  1. Increase Timeout                |
     (Buy more time)        +--------+--------+
                            |                 |
  2. Optimize Queries       v                 v
     (Event log filters)   YES               NO
                            |                 |
  3. Stagger Schedule       v                 v
     (Spread load)    Stagger      Check Device
                      Execution    Performance
  4. Reduce Scope    Times                   |
     (Less history)         |                 v
                            |         Device Slow?
  5. Cache Results          |         (High CPU/Mem)
     (If possible)          |                 |
                            |       +---------+---------+
          |                 |       |                   |
          v                 v       v                   v
  Apply Optimization   RESOLVED    YES                 NO
          |                       Device            Minimal
          v                       Issues            Impact
  Test on Single                      |                 |
  Device First                        v                 v
          |                    Fix Device         Impact
          v                    Performance       Acceptable
  Monitor Results                     |                 |
          |                           v                 v
          v                      RESOLVED         RESOLVED
  Improvement?
          |
    +-----+-----+
    |           |
    v           v
   YES         NO
    |           |
    v           v
  Roll Out   Contact
  to All     Support
  Devices         |
    |             v
    v        ESCALATED
RESOLVED


PERFORMANCE IMPACT THRESHOLDS:
- Acceptable: <5% CPU, <150MB RAM per script
- Warning: 5-15% CPU, 150-300MB RAM
- Critical: >15% CPU, >300MB RAM
- User-Noticeable: Any sustained >30s execution
```

---

## Flowchart 4: Alert False Positives

```
            Alert Triggered Incorrectly?
                        |
                        v
        What type of false positive?
                        |
        +---------------+---------------+
        |                               |
        v                               v
  Alert for Normal            Alert for Known
  Condition                   Approved Exception
        |                               |
        v                               |
  Check Field Value                    |
  That Triggered Alert                 |
        |                               |
        v                               |
  Is field value correct?              |
        |                               |
  +-----+-----+                         |
  |           |                         |
  v           v                         |
 YES          NO                        |
  |           |                         |
  |           v                         |
  |   Field Value Wrong                 |
  |           |                         |
  |           v                         |
  |   Use "Field Not Populating"        |
  |   Flowchart to Fix                  |
  |           |                         |
  |           v                         |
  |       RESOLVED                      |
  |                                     |
  v                                     v
Field Value Correct              Document Exception
but Alert Wrong?                 in System
  |                                     |
  v                                     v
Review Alert Threshold         Add to Exclusions/
  |                            Known Exceptions
  v                                     |
Is threshold appropriate?              v
  |                                RESOLVED
  +----------+----------+
  |                     |
  v                     v
 NO                    YES
  |                     |
  v                     |
Adjust Alert                    |
Threshold                       |
  |                             |
  Examples:                     |
  - Disk <10% too strict        |
  - Health <70 too strict       |
  - Error count >5 too strict   |
  |                             |
  v                             v
Test New              Review Alert Logic
Threshold                     |
  |                           |
  v                           v
Monitor for         Logic captures true
24-48 Hours         issues correctly?
  |                           |
  v                  +--------+--------+
Still False              |              |
Positives?               v              v
  |                     YES             NO
  +-----+-----+          |              |
  |           |          |              v
  v           v          |         Alert Logic
 YES          NO         |         Has Bug
  |           |          |              |
  v           v          |              v
Adjust    RESOLVED       |      Contact Support
Again                    |      for Fix
  |                      |              |
  v                      v              v
RESOLVED          RESOLVED        ESCALATED


ALERT TUNING BEST PRACTICES:
1. Start conservative (fewer alerts)
2. Tune based on real incidents
3. Document all threshold changes
4. Monitor false positive rate
5. Target <10% false positive rate

COMMON THRESHOLD ADJUSTMENTS:
- Disk Space: 15% → 10% (stricter)
- Health Score: 70 → 60 (more lenient)
- Error Count: 5 → 10 (more lenient)
- Uptime: 30 days → 60 days (more lenient)
```

---

## Flowchart 5: Dashboard Loading Slow

```
                Dashboard Loads Slowly?
                      (>10 seconds)
                            |
                            v
            Which dashboard is slow?
                            |
            +---------------+---------------+
            |                               |
            v                               v
     All Dashboards                  Specific Dashboard
            |                               |
            v                               |
    Likely NinjaRMM                         |
    Platform Issue                          |
            |                               |
            v                               |
    - Check NinjaRMM Status                 |
    - Contact NinjaRMM Support              |
    - Wait for resolution                   |
            |                               |
            v                               v
       ESCALATED                    Review Dashboard
                                    Widget Count
                                            |
                                            v
                                How many widgets?
                                            |
                                +-----------+-----------+
                                |                       |
                                v                       v
                              <20                     20+
                                |                       |
                                |                       v
                                |               Too Many Widgets
                                |                       |
                                |                       v
                                |               Optimization:
                                |               - Split into
                                |                 multiple dashboards
                                |               - Remove unused
                                |                 widgets
                                |               - Simplify queries
                                |                       |
                                v                       v
                        Check Query                RESOLVED
                        Complexity
                                |
                                v
                    Are queries filtering
                    efficiently?
                                |
                    +-----------+-----------+
                    |                       |
                    v                       v
                   YES                     NO
                    |                       |
                    |                       v
                    |               Optimize Queries:
                    |               - Add device filters
                    |               - Limit date ranges
                    |               - Use indexed fields
                    |                       |
                    |                       v
                    |                  RESOLVED
                    |
                    v
            Check Data Volume
                    |
                    v
        Monitoring how many devices?
                    |
        +-----------+-----------+
        |                       |
        v                       v
     <100                    100+
        |                       |
        |                       v
        |               Large Scale
        |               Deployment
        |                       |
        |                       v
        |               Consider:
        |               - Regional dashboards
        |               - Role-based dashboards
        |               - Cached reports
        |                       |
        v                       v
   Check Browser            RESOLVED
   Performance
        |
        v
   - Clear cache
   - Try different browser
   - Check extensions
   - Test incognito mode
        |
        v
   Improvement?
        |
    +---+---+
    |       |
    v       v
   YES     NO
    |       |
    v       v
RESOLVED Contact
        Support
            |
            v
       ESCALATED


DASHBOARD PERFORMANCE TIPS:
- Keep widgets <15 per dashboard
- Use filters to limit data
- Avoid complex calculations
- Cache when possible
- Refresh less frequently
```

---

## Quick Decision Matrix

| Symptom | First Check | Most Likely Cause | Quick Fix |
|---------|-------------|-------------------|------------|
| Script fails | Error message | Timeout | Increase timeout |
| Field empty | Script running? | Script not executing | Enable policy |
| Device slow | Timing | Concurrent execution | Stagger schedule |
| False alerts | Field value | Threshold too strict | Adjust threshold |
| Dashboard slow | Widget count | Too many widgets | Split dashboard |

---

## Escalation Checklist

Before escalating to support:

- [ ] Followed relevant flowchart completely
- [ ] Documented all troubleshooting steps
- [ ] Captured error messages/screenshots
- [ ] Identified scope (single device vs many)
- [ ] Checked for recent changes
- [ ] Reviewed documentation/FAQ
- [ ] Attempted workaround if available

**When to escalate immediately:**
- Security concern
- Data corruption suspected
- System-wide failure
- Critical device affected

---

**Last Updated:** February 9, 2026, 1:18 AM CET
