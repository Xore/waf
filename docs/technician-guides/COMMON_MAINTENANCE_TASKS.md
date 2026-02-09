# Common Maintenance Tasks - Windows Automation Framework

**Document Type:** Technician Guide  
**Audience:** System Administrators, DevOps, IT Operations  
**Time to Read:** 15 minutes  
**Last Updated:** February 9, 2026

---

## Purpose

This guide provides systematic procedures for routine WAF maintenance tasks. Regular maintenance ensures the Windows Automation Framework continues to provide accurate monitoring data and optimal performance.

---

## Maintenance Schedule Overview

### Quick Reference

| Frequency | Task | Duration | Priority |
|-----------|------|----------|----------|
| **Daily** | Review critical alerts | 5 min | High |
| **Daily** | Check script execution status | 5 min | High |
| **Weekly** | Analyze health score trends | 15 min | Medium |
| **Weekly** | Review field population rates | 10 min | Medium |
| **Monthly** | Capacity trend analysis | 20 min | High |
| **Monthly** | Script performance review | 30 min | Medium |
| **Quarterly** | Field audit and cleanup | 2 hours | Low |
| **Quarterly** | Documentation updates | 1 hour | Low |
| **Annually** | Comprehensive system review | 4 hours | Medium |

---

## Daily Tasks

### Task D1: Review Critical Alerts

**Frequency:** Every morning (start of shift)  
**Duration:** 5 minutes  
**Priority:** High

**Purpose:** Identify and prioritize urgent issues requiring immediate attention.

**Procedure:**

1. **Open Alert Dashboard**
   - Navigate to NinjaRMM Alerts
   - Filter for WAF-related alerts
   - Sort by severity (Critical first)

2. **Review Critical Alerts (Health <60)**
   ```
   Check for:
   - Devices with health score <60
   - Security score <60 (security risk)
   - Capacity score <60 (disk space critical)
   - Multiple component failures
   ```

3. **Triage and Prioritize**
   ```
   Priority 1: Security issues (AV disabled, firewall off)
   Priority 2: Capacity critical (disk <5%)
   Priority 3: Performance severe (system unusable)
   Priority 4: Stability issues (frequent crashes)
   ```

4. **Create Action Items**
   - Assign tickets for each critical alert
   - Set appropriate SLA timers
   - Document initial findings

5. **Communicate**
   - Alert team to critical issues
   - Update management if widespread

**Expected Outcome:**
- All critical alerts triaged
- Action items created
- Team aware of priorities

---

### Task D2: Check Script Execution Status

**Frequency:** Daily (morning check)  
**Duration:** 5 minutes  
**Priority:** High

**Purpose:** Ensure all monitoring scripts are executing successfully.

**Procedure:**

1. **Review Execution Logs**
   - Navigate to NinjaRMM Script Activity
   - Filter last 24 hours
   - Sort by status (Failed first)

2. **Check Key Metrics**
   ```
   Target Goals:
   - Overall success rate: >95%
   - Timeout rate: <5%
   - Permission errors: 0
   - Critical script success: 100%
   ```

3. **Identify Problem Scripts**
   ```
   If any script has <90% success:
   - Note script name
   - Count failures
   - Check error messages
   - Identify affected devices
   ```

4. **Quick Triage**
   - **Single device failures:** Device-specific issue
   - **Multiple device failures:** Script or environment issue
   - **Timeout pattern:** Performance optimization needed
   - **Permission errors:** Configuration problem

5. **Take Action**
   - Single failures: Investigate device
   - Script issues: Review script or escalate
   - Timeouts: Increase timeout or optimize script
   - Permissions: Fix automation policy

**Expected Outcome:**
- 95%+ script success rate confirmed
- Any failures triaged
- Corrective actions initiated

---

## Weekly Tasks

### Task W1: Analyze Health Score Trends

**Frequency:** Every Monday morning  
**Duration:** 15 minutes  
**Priority:** Medium

**Purpose:** Identify devices with declining health before they become critical.

**Procedure:**

1. **Generate Trend Report**
   - Export device health scores (current)
   - Compare to 7 days ago
   - Calculate change percentage

2. **Identify Declining Devices**
   ```
   Flag devices where:
   - Score dropped >10 points (85→75)
   - Score now <80
   - Consistent downward trend (3+ days)
   ```

3. **Categorize Issues**
   ```
   Group by component:
   - Stability declining: X devices
   - Performance declining: Y devices
   - Security declining: Z devices
   - Capacity declining: W devices
   ```

4. **Analyze Patterns**
   ```
   Look for:
   - Common device types affected
   - Location-based patterns
   - Time-based patterns (after updates?)
   - Systemic vs isolated issues
   ```

5. **Plan Interventions**
   - Create proactive maintenance tickets
   - Schedule capacity upgrades
   - Plan security remediations
   - Coordinate with teams

6. **Document Findings**
   ```markdown
   ## Weekly Health Trend Report - [Date]
   
   ### Summary
   - Total devices monitored: 150
   - Declining devices: 12 (8%)
   - Improving devices: 8 (5.3%)
   - Stable devices: 130 (86.7%)
   
   ### Concerns
   - Capacity: 5 devices trending down (disk growth)
   - Security: 3 devices need update attention
   - Performance: 4 devices showing degradation
   
   ### Actions Planned
   - Disk cleanup scheduled for 5 devices
   - Updates deployed to 3 devices
   - Performance investigation for 4 devices
   ```

**Expected Outcome:**
- Proactive issues identified
- Trend report documented
- Preventive actions planned

---

### Task W2: Review Field Population Rates

**Frequency:** Weekly (any day)  
**Duration:** 10 minutes  
**Priority:** Medium

**Purpose:** Ensure monitoring data is complete and accurate.

**Procedure:**

1. **Check Overall Population**
   ```
   Target: 96%+ fields populated
   
   If using health check script:
   .\WAF-HealthCheck-FieldPopulation.ps1
   ```

2. **Review Category Breakdown**
   ```
   Check each category:
   - OPS (Core operations): Target 98%+
   - STAT (Statistics): Target 95%+
   - SEC (Security): Target 95%+
   - CAP (Capacity): Target 98%+
   - UPD (Updates): Target 90%+
   ```

3. **Identify Consistently Empty Fields**
   ```
   Flag fields with <80% population:
   - Is feature not available? (e.g., TPM on old devices)
   - Is script failing?
   - Is field no longer relevant?
   ```

4. **Investigate Anomalies**
   - Check script execution for unpopulated fields
   - Review error logs
   - Test on sample device

5. **Take Corrective Action**
   ```
   - Script failing: Fix and redeploy
   - Feature unavailable: Document as expected
   - Field deprecated: Mark for removal
   - Data accuracy issue: Recalculate
   ```

**Expected Outcome:**
- 96%+ population rate confirmed
- Any gaps explained or fixed
- Documentation updated

---

## Monthly Tasks

### Task M1: Capacity Trend Analysis

**Frequency:** First Monday of each month  
**Duration:** 20 minutes  
**Priority:** High

**Purpose:** Predict and prevent capacity issues through trend analysis.

**Procedure:**

1. **Gather Capacity Data**
   ```
   Export fields:
   - capDiskCFreeGB (current free space)
   - capDiskGrowth30d (30-day growth rate)
   - capProjectedDaysTillFull (projected time to full)
   - capMemoryAvailablePercent (RAM availability)
   ```

2. **Identify At-Risk Devices**
   ```
   Critical (action within 30 days):
   - Disk <10% free
   - Projected full <60 days
   - Rapid growth (>5GB/month)
   
   Warning (action within 90 days):
   - Disk <20% free
   - Projected full <120 days
   - Steady growth (2-5GB/month)
   ```

3. **Analyze Growth Patterns**
   ```
   For each at-risk device:
   - What's growing? (logs, user data, apps)
   - Growth rate stable or accelerating?
   - Seasonal factors? (end of quarter, project work)
   - Cleanup possible or upgrade needed?
   ```

4. **Calculate Budget Impact**
   ```
   Estimate costs:
   - Devices needing disk upgrades: X devices
   - Devices needing replacement: Y devices
   - Total budget needed: $Z
   - Justification: Avoid downtime, data loss
   ```

5. **Create Action Plan**
   ```markdown
   ## Monthly Capacity Report - [Month/Year]
   
   ### Executive Summary
   - 8 devices require attention
   - 3 critical (action within 30 days)
   - 5 warning (action within 90 days)
   - Estimated cost: $4,500
   
   ### Critical Devices
   1. DESKTOP-2024: 5% free, full in 45 days → Disk upgrade
   2. LAPTOP-5678: 8% free, full in 30 days → Data migration
   3. SERVER-DB01: 7% free, full in 35 days → Storage expansion
   
   ### Actions This Month
   - Schedule disk upgrades (3 devices)
   - User data cleanup campaigns (5 devices)
   - Archive old project files
   - Submit budget request for Q2
   ```

6. **Communicate Findings**
   - Share report with management
   - Notify users of cleanup needs
   - Coordinate with procurement

**Expected Outcome:**
- Capacity risks identified
- Budget justified
- Proactive upgrades planned
- No surprise disk-full incidents

---

### Task M2: Script Performance Review

**Frequency:** Monthly  
**Duration:** 30 minutes  
**Priority:** Medium

**Purpose:** Optimize script execution times and identify performance bottlenecks.

**Procedure:**

1. **Gather Performance Data**
   ```
   Run health check:
   .\WAF-HealthCheck-Performance.ps1
   
   Or manually review:
   - Average execution times per script
   - 95th percentile times
   - Timeout rates
   - Resource usage
   ```

2. **Identify Slow Scripts**
   ```
   Flag scripts where:
   - Average time >30 seconds
   - 95th percentile >60 seconds
   - Timeout rate >5%
   - User complaints about performance
   ```

3. **Analyze Root Causes**
   ```
   For each slow script:
   - Large data sets? (event logs, file scans)
   - Inefficient queries? (WMI vs CIM)
   - Network latency? (domain queries)
   - Device-specific? (older hardware)
   ```

4. **Optimization Options**
   ```
   - Increase timeout (quick fix)
   - Optimize queries (use FilterHashtable)
   - Reduce scope (30 days → 7 days logs)
   - Add caching (reuse query results)
   - Stagger execution (avoid conflicts)
   - Split script (break into smaller pieces)
   ```

5. **Test Optimizations**
   - Test on sample device
   - Measure improvement
   - Verify data accuracy maintained
   - Deploy if successful

6. **Document Changes**
   ```markdown
   ## Script Performance Optimization - [Date]
   
   ### Script: Update Compliance Monitor (Script 6)
   
   **Before:**
   - Average time: 105 seconds
   - Timeout rate: 8.2%
   
   **Issue:** Windows Update queries taking 80+ seconds
   
   **Optimization:** 
   - Reduced query scope to 30 days (was 90 days)
   - Switched to CIM queries
   - Added result caching
   
   **After:**
   - Average time: 35 seconds (67% improvement)
   - Timeout rate: 0.5%
   
   **Status:** Deployed to production
   ```

**Expected Outcome:**
- Scripts performing within targets
- User experience improved
- Timeout rates minimized

---

## Quarterly Tasks

### Task Q1: Field Audit and Cleanup

**Frequency:** Quarterly (every 3 months)  
**Duration:** 2 hours  
**Priority:** Low

**Purpose:** Ensure field structure remains relevant and remove deprecated fields.

**Procedure:**

1. **Review All Fields** (277+ fields)
   ```
   For each field category:
   - Are all fields still relevant?
   - Any deprecated/unused fields?
   - Any missing fields needed?
   - Naming conventions consistent?
   ```

2. **Identify Unused Fields**
   ```
   Flag fields where:
   - Never populated (0% population for 90+ days)
   - Feature no longer exists
   - Business requirement changed
   - Duplicate/redundant data
   ```

3. **Assess Impact of Removal**
   ```
   Before removing a field:
   - Check dashboard usage
   - Check alert dependencies
   - Check report usage
   - Check automation policy references
   ```

4. **Plan Consolidation**
   ```
   Opportunities:
   - Merge similar fields
   - Standardize naming
   - Reorganize categories
   - Archive historical fields
   ```

5. **Document Decisions**
   ```markdown
   ## Quarterly Field Audit - Q1 2026
   
   ### Fields Reviewed: 277
   
   ### Fields to Deprecate (5):
   - oldFieldName1: Never used, replaced by newField
   - oldFieldName2: Feature removed from Windows
   - oldFieldName3: Duplicate of existingField
   
   ### Fields to Add (3):
   - newFeatureField: Support for new Windows feature
   - enhancedMetric: Requested by management
   
   ### Fields to Rename (2):
   - inconsistentName → standardName
   
   ### Next Steps:
   - Schedule field changes for next maintenance window
   - Update documentation
   - Update scripts
   - Update dashboards
   ```

6. **Execute Changes**
   - Schedule maintenance window
   - Backup existing data
   - Make changes systematically
   - Validate after completion

**Expected Outcome:**
- Field structure optimized
- Unused fields removed
- Naming consistent
- Documentation updated

---

### Task Q2: Documentation Updates

**Frequency:** Quarterly  
**Duration:** 1 hour  
**Priority:** Low

**Purpose:** Keep documentation current with system changes.

**Procedure:**

1. **Review All Documentation**
   ```
   Check each guide:
   - Accuracy (procedures still correct?)
   - Completeness (missing new features?)
   - Clarity (confusing sections?)
   - Examples (still relevant?)
   ```

2. **Incorporate Feedback**
   ```
   Review:
   - User questions (FAQ additions)
   - Support tickets (common issues)
   - Team suggestions (improvements)
   - Lessons learned (recent incidents)
   ```

3. **Update Content**
   ```
   Priority updates:
   - New field documentation
   - New script documentation
   - Changed procedures
   - New troubleshooting steps
   - Updated screenshots/diagrams
   ```

4. **Verify Links**
   - Test all internal links
   - Test all external links
   - Fix broken references

5. **Version Control**
   ```
   Update version numbers:
   - Document version
   - Last updated date
   - Change summary
   ```

**Expected Outcome:**
- Documentation accurate and current
- User feedback incorporated
- Easy to navigate and understand

---

## Annual Tasks

### Task A1: Comprehensive System Review

**Frequency:** Annually  
**Duration:** 4 hours  
**Priority:** Medium

**Purpose:** Holistic evaluation of WAF effectiveness and strategic planning.

**Procedure:**

1. **Performance Analysis**
   ```
   Review past year:
   - Incidents prevented by WAF
   - Issues detected early
   - Time saved by automation
   - False positive rate
   - User satisfaction scores
   ```

2. **Cost-Benefit Analysis**
   ```
   Calculate:
   - Setup cost (one-time)
   - Maintenance cost (annual)
   - Time saved (hours × hourly rate)
   - Downtime prevented (estimated cost)
   - ROI percentage
   ```

3. **Coverage Assessment**
   ```
   Evaluate:
   - Monitoring gaps identified?
   - Missing critical metrics?
   - New Windows features to monitor?
   - New business requirements?
   ```

4. **Strategic Planning**
   ```markdown
   ## Annual WAF Review - 2026
   
   ### Achievements
   - Monitored 150 devices reliably
   - Prevented 23 capacity failures
   - Detected 47 security issues early
   - Saved estimated 400 hours of manual work
   - ROI: 340%
   
   ### Challenges
   - Script timeout issues on older devices
   - False positives on capacity alerts
   - User training needed improvements
   
   ### Next Year Goals
   - Expand to 200 devices
   - Add server-specific monitoring
   - Integrate with ticketing system
   - Improve alert tuning
   - Develop self-service dashboard
   
   ### Budget Request
   - Training: $5,000
   - Tool enhancements: $10,000
   - Additional resources: $15,000
   - Total: $30,000
   ```

5. **Present to Management**
   - Create executive summary
   - Prepare presentation
   - Justify budget requests
   - Get approval for next year

**Expected Outcome:**
- Year in review documented
- ROI demonstrated
- Next year strategy approved
- Budget secured

---

## Ad-Hoc Maintenance Tasks

### Task AH1: Respond to Mass Script Failure

**Trigger:** Multiple scripts failing across devices  
**Duration:** 1-2 hours  
**Priority:** Critical

**Procedure:**

1. **Assess Scope**
   - How many devices affected?
   - Which scripts failing?
   - When did it start?
   - Any common factors?

2. **Immediate Actions**
   - Stop scheduled executions (if causing issues)
   - Notify team and management
   - Check for environmental changes

3. **Investigate Root Cause**
   ```
   Common causes:
   - NinjaRMM platform issue
   - Windows update broke compatibility
   - Network/domain connectivity
   - Permission changes
   - Script repository corruption
   ```

4. **Implement Fix**
   - Apply fix to test device first
   - Validate fix works
   - Deploy to all affected devices
   - Monitor for success

5. **Document Incident**
   - What happened
   - Root cause
   - Fix applied
   - Lessons learned
   - Prevention measures

---

### Task AH2: Emergency Field Restructure

**Trigger:** Critical need to change field structure  
**Duration:** 2-4 hours  
**Priority:** High

**Procedure:**

1. **Backup Existing Data**
   - Export all field values
   - Archive scripts
   - Document current configuration

2. **Create Migration Plan**
   - Map old fields to new fields
   - Identify data transformations needed
   - Plan dashboard updates
   - Plan script updates

3. **Test in Pilot**
   - Apply changes to test devices
   - Validate data migration
   - Verify dashboards work
   - Check alerts function

4. **Execute Migration**
   - Schedule maintenance window
   - Execute changes systematically
   - Validate each step
   - Monitor for issues

5. **Post-Migration Validation**
   - Verify all data migrated
   - Check all dashboards
   - Test all alerts
   - Confirm script execution

---

### Task AH3: Alert Storm Mitigation

**Trigger:** Excessive false positive alerts  
**Duration:** 30 minutes  
**Priority:** High

**Procedure:**

1. **Identify Alert Source**
   - Which field triggering?
   - How many alerts?
   - Pattern to alerts?

2. **Immediate Mitigation**
   ```
   Options:
   - Temporarily disable alert
   - Raise threshold temporarily
   - Add exclusions
   - Increase alert suppression period
   ```

3. **Root Cause Analysis**
   - Is data correct but threshold wrong?
   - Is data calculation incorrect?
   - Is this expected behavior (maintenance)?

4. **Permanent Fix**
   - Adjust thresholds appropriately
   - Fix calculation if needed
   - Add business hours filtering
   - Improve alert logic

5. **Re-enable and Monitor**
   - Re-enable alert with fix
   - Monitor for 24 hours
   - Adjust if needed

---

## Maintenance Tools

### Recommended Scripts

1. **WAF-HealthCheck-FieldPopulation.ps1**
   - Run: Weekly
   - Purpose: Verify field population

2. **WAF-HealthCheck-ScriptExecution.ps1**
   - Run: Daily
   - Purpose: Check script success rates

3. **WAF-HealthCheck-Performance.ps1**
   - Run: Monthly
   - Purpose: Analyze performance

4. **WAF-HealthCheck-DataQuality.ps1**
   - Run: Weekly
   - Purpose: Validate data accuracy

---

## Maintenance Checklist Template

```markdown
## WAF Maintenance Log - [Date]

### Daily Tasks
- [ ] Critical alerts reviewed
- [ ] Script execution status checked
- [ ] Issues: [None / List issues]

### Weekly Tasks (if applicable)
- [ ] Health score trends analyzed
- [ ] Field population reviewed
- [ ] Report generated and filed

### Monthly Tasks (if applicable)
- [ ] Capacity trend analysis complete
- [ ] Script performance reviewed
- [ ] Optimizations identified: [List]

### Quarterly Tasks (if applicable)
- [ ] Field audit complete
- [ ] Documentation updated
- [ ] Changes documented

### Notes
[Any observations, concerns, or recommendations]

### Next Actions
1. [Action item 1]
2. [Action item 2]
```

---

## Best Practices

### Scheduling Maintenance

**Morning Tasks:**
- Review alerts (start of day)
- Check script execution (after overnight runs)

**Monday Tasks:**
- Weekly trend analysis
- Field population review

**First Monday of Month:**
- Capacity trend analysis
- Script performance review

**Quarterly (End of Q1, Q2, Q3, Q4):**
- Field audit
- Documentation update

---

### Time Management

**Daily:** 10 minutes total
**Weekly:** 25 minutes total (15 min trend + 10 min fields)
**Monthly:** 50 minutes total (20 min capacity + 30 min performance)
**Quarterly:** 3 hours total (2 hours audit + 1 hour docs)
**Annual:** 4 hours

**Total Time Investment:**
- Per Week: ~2 hours (includes daily tasks)
- Per Year: ~110 hours
- Per Device: ~44 minutes/year (for 150 devices)

---

## Getting Help

### When Maintenance Takes Longer Than Expected

1. Check if issue is widespread (affects multiple devices/scripts)
2. Review recent changes (updates, configuration changes)
3. Consult troubleshooting guides
4. Ask team for assistance
5. Escalate if unresolved after 1 hour

### When You're Unsure About a Maintenance Task

1. Review this guide thoroughly
2. Check related documentation
3. Ask colleague who has done it before
4. Test on pilot device first
5. Document your process

---

## Related Guides

- **Reading the Dashboard:** Understanding monitoring data
- **Device Health Investigation:** Deep-dive troubleshooting
- **Responding to Alerts:** Alert-specific procedures
- **Troubleshooting Flowcharts:** Decision trees for issues

---

## Summary

**Key Takeaways:**

1. Daily maintenance takes ~10 minutes (alerts + scripts)
2. Weekly tasks identify trends early (25 minutes)
3. Monthly tasks prevent capacity issues (50 minutes)
4. Quarterly tasks keep system optimized (3 hours)
5. Annual review ensures strategic alignment (4 hours)
6. Total time investment: ~2 hours/week

**Remember:**
Consistent maintenance prevents emergencies. Small daily investments save large crisis responses.

**Start Simple:**
Begin with daily tasks only. Add weekly/monthly as you build routine.

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Next Review:** May 2026
