# Emergency Procedures - Windows Automation Framework

**Document Type:** Emergency Response Guide  
**Audience:** IT Operations, System Administrators, Support Teams  
**Priority Level:** CRITICAL  
**Last Updated:** February 9, 2026

---

## Purpose

This guide provides immediate response procedures for critical WAF incidents. Follow these procedures when facing system-wide failures, data accuracy issues, or emergency situations affecting Windows device monitoring.

---

## Emergency Contacts

### Escalation Path

**Level 1 - Help Desk/Desktop Support**
- First responders for alerts
- Execute standard procedures
- Escalate if unresolved in 30 minutes

**Level 2 - System Administrators**
- WAF configuration experts
- Script troubleshooting
- Escalate if unresolved in 1 hour

**Level 3 - IT Management**
- Strategic decisions
- Resource allocation
- Vendor engagement

**External Support**
- NinjaRMM Support: [Contact info]
- PowerShell Community: [Forums]
- WAF Repository: [GitHub issues]

---

## Severity Classification

### SEV-1: Critical (Immediate Response)

**Definition:** System-wide failure affecting monitoring of all/most devices

**Examples:**
- All scripts failing across all devices
- NinjaRMM platform outage
- Mass data corruption
- Security breach affecting monitoring

**Response Time:** Immediate (within 5 minutes)
**Resolution Target:** 2 hours maximum

---

### SEV-2: High (Urgent Response)

**Definition:** Significant monitoring failures affecting multiple devices

**Examples:**
- Critical script failing on 20%+ devices
- Dashboard unavailable
- Alert storm (100+ false positives)
- Major data accuracy issues

**Response Time:** Within 15 minutes
**Resolution Target:** 4 hours maximum

---

### SEV-3: Medium (Standard Response)

**Definition:** Isolated failures affecting specific devices/scripts

**Examples:**
- Single script failing on multiple devices
- Performance degradation
- Minor data inconsistencies
- Field population below target

**Response Time:** Within 1 hour
**Resolution Target:** 8 hours (same day)

---

### SEV-4: Low (Routine Response)

**Definition:** Non-critical issues with minimal impact

**Examples:**
- Single device script failure
- Documentation outdated
- Minor UI issues
- Enhancement requests

**Response Time:** Within 24 hours
**Resolution Target:** As resources permit

---

## EMERGENCY 1: Mass Script Failure

**Symptoms:**
- 50%+ of scripts failing across all devices
- Sudden widespread script execution errors
- Fields stop updating across fleet

**Severity:** SEV-1 (Critical)

---

### Immediate Actions (First 5 Minutes)

**Step 1: Assess Scope**
```
1. Check NinjaRMM Script Activity dashboard
2. Identify affected scripts: All / Specific scripts?
3. Identify affected devices: All / Subset?
4. Check start time: When did failures begin?
5. Document initial findings
```

**Step 2: Notify Stakeholders**
```
Immediate notifications:
- Alert IT management
- Notify monitoring team
- Post in team chat: "WAF EMERGENCY - Mass script failure"
- Set status: Incident in progress
```

**Step 3: Stop Further Damage**
```
If scripts are causing device issues:
1. Navigate to NinjaRMM Automation Policies
2. Disable all WAF automation policies
3. Confirm no new executions starting
4. Document action taken and timestamp
```

---

### Investigation Phase (Minutes 5-30)

**Step 4: Check NinjaRMM Platform Status**
```
1. Visit status.ninjarmm.com (or equivalent)
2. Check for reported outages
3. Check NinjaRMM community forums
4. Test basic agent connectivity

If platform issue:
   - Document as external issue
   - Monitor NinjaRMM status updates
   - Communicate to stakeholders
   - Wait for platform recovery
   - Skip to Recovery Phase when resolved
```

**Step 5: Investigate Environmental Changes**
```
Check recent changes:
- Windows updates deployed? (last 24 hours)
- NinjaRMM agent updates?
- Domain/network changes?
- Active Directory changes?
- Security policy changes?
- PowerShell version changes?

Document findings for each item checked.
```

**Step 6: Analyze Error Messages**
```
1. Navigate to failed script execution logs
2. Collect error messages from 5-10 different devices
3. Identify common error patterns:

Common patterns:
- "Access Denied" = Permission issue
- "Timeout" = Performance issue
- "Command not found" = PowerShell/feature issue
- "Network error" = Connectivity issue
- "Invalid operation" = Script logic issue
```

**Step 7: Test Single Device**
```
1. Select one representative device
2. Manually execute one failed script
3. Monitor execution in real-time
4. Capture full error output
5. Document results

If manual execution succeeds:
   - Issue may be automation policy configuration
   - Check policy settings
   - Check scheduling conflicts

If manual execution fails:
   - Issue is script or environment
   - Proceed to root cause analysis
```

---

### Root Cause Analysis (Minutes 30-60)

**Common Cause 1: Windows Update Broke Compatibility**

**Indicators:**
- Failures started after patch Tuesday
- All devices show same error
- Previously working scripts now fail

**Resolution:**
```
1. Identify problematic Windows update
2. Check if PowerShell cmdlets changed
3. Test script on un-patched device
4. Options:
   a) Wait for Microsoft hotfix
   b) Modify script for compatibility
   c) Roll back update (extreme cases)
5. Implement chosen solution
6. Test on pilot device
7. Deploy fix
```

---

**Common Cause 2: Permission Changes**

**Indicators:**
- Error messages mention "Access Denied"
- Scripts worked previously
- Execution context issue

**Resolution:**
```
1. Verify automation policy execution context: SYSTEM
2. Check NinjaRMM agent service account permissions
3. Verify no group policy blocked script execution
4. Test with Set-ExecutionPolicy check
5. Restore proper permissions:
   - Re-configure automation policy if needed
   - Work with AD team if GPO changed
6. Test on pilot device
7. Deploy fix
```

---

**Common Cause 3: Script Repository Corruption**

**Indicators:**
- Scripts show as modified unexpectedly
- Syntax errors in previously working scripts
- Random script failures

**Resolution:**
```
1. Compare current scripts to Git repository
2. Identify corrupted/modified scripts
3. Re-upload clean versions from Git:
   - Navigate to NinjaRMM Scripts
   - Delete corrupted script
   - Re-upload from repository
   - Reconfigure automation policies if needed
4. Test on pilot device
5. Deploy to all devices
```

---

**Common Cause 4: NinjaRMM Agent Issues**

**Indicators:**
- Agent version recently updated
- Scripts work when run manually (not via agent)
- Inconsistent failures

**Resolution:**
```
1. Check agent versions across fleet
2. Identify if recent agent update
3. Contact NinjaRMM support
4. Options:
   a) Wait for agent hotfix
   b) Roll back agent (with support guidance)
   c) Modify scripts for compatibility
5. Implement solution
6. Test and deploy
```

---

### Recovery Phase (Hour 1-2)

**Step 8: Implement Fix**
```
1. Document planned fix clearly
2. Get approval if major change
3. Test fix on 3-5 pilot devices
4. Monitor for 15-30 minutes
5. Verify:
   - Scripts execute successfully
   - Fields populate correctly
   - No new errors
   - Performance acceptable
```

**Step 9: Gradual Rollout**
```
1. Re-enable automation for 10% of devices
2. Monitor for 30 minutes
3. If stable, expand to 50% of devices
4. Monitor for 1 hour
5. If stable, expand to 100% of devices
6. Monitor for 24 hours

If issues at any stage:
   - Stop rollout
   - Revert to previous stage
   - Re-investigate
```

**Step 10: Validate Recovery**
```
Check:
- Script success rate >95%
- Fields populating
- No error spike
- Health scores updating
- Dashboards showing current data
```

---

### Post-Incident Actions

**Step 11: Document Incident**
```markdown
## Incident Report: Mass Script Failure

**Date/Time:** [Start] to [End]
**Duration:** [Hours]
**Severity:** SEV-1
**Devices Affected:** [Count/Percentage]

### Timeline
- HH:MM - Issue detected
- HH:MM - Stakeholders notified
- HH:MM - Scripts disabled
- HH:MM - Root cause identified
- HH:MM - Fix implemented
- HH:MM - Recovery complete

### Root Cause
[Detailed explanation]

### Impact
- Monitoring unavailable for X hours
- Y devices without updates
- Z alerts potentially missed

### Resolution
[Steps taken to resolve]

### Prevention
[Measures to prevent recurrence]

### Lessons Learned
1. [Lesson 1]
2. [Lesson 2]
```

**Step 12: Communicate Resolution**
```
Notify:
- Management (incident resolved)
- Monitoring team (normal operations resumed)
- Affected users (if applicable)
- Update team chat status
```

**Step 13: Implement Prevention Measures**
```
Based on root cause:
- Update documentation
- Add monitoring for early detection
- Create alerts for similar issues
- Schedule preventive maintenance
- Update runbooks
```

---

## EMERGENCY 2: Dashboard Unavailable

**Symptoms:**
- Cannot access NinjaRMM dashboard
- Dashboard loads but shows no data
- Dashboard extremely slow (unusable)

**Severity:** SEV-2 (High)

---

### Immediate Actions (First 15 Minutes)

**Step 1: Verify Scope**
```
Check:
- Is it just you? (ask colleagues)
- Specific dashboard or all dashboards?
- NinjaRMM portal accessible?
- Internet connectivity working?
- Browser issues? (try different browser)
```

**Step 2: Check Platform Status**
```
1. Visit status.ninjarmm.com
2. Check for reported outages
3. Check NinjaRMM Twitter/status channels

If platform outage:
   - Document outage start time
   - Notify stakeholders
   - Use alternative monitoring (if available)
   - Wait for platform recovery
   - Skip to workarounds below
```

**Step 3: Attempt Basic Troubleshooting**
```
1. Clear browser cache/cookies
2. Try incognito/private browsing
3. Try different browser
4. Try different device
5. Check if API access works (if applicable)
```

---

### Workarounds (While Dashboard Down)

**Option 1: API Access**
```
If you have API access configured:
1. Use API to query critical device data
2. Export to CSV for review
3. Create temporary reports
4. Monitor critical alerts via API
```

**Option 2: Direct Device Access**
```
For critical monitoring:
1. RDP/remote into critical devices
2. Manually check health metrics:
   - Disk space (Get-PSDrive)
   - Memory usage (Get-Process)
   - Event logs (Get-EventLog)
   - Services status (Get-Service)
```

**Option 3: Alternative Tools**
```
Temporary monitoring:
1. Windows Admin Center (if deployed)
2. PowerShell remoting
3. SCOM/other monitoring (if available)
4. Manual checks
```

---

### Recovery Actions

**If Dashboard Performance Issue:**
```
1. Reduce dashboard complexity:
   - Remove large widgets
   - Reduce date ranges
   - Limit device count per widget
2. Optimize queries
3. Create simpler dashboards
4. Contact NinjaRMM support for guidance
```

**If Data Not Loading:**
```
1. Check if scripts are executing
2. Verify fields are populating
3. Check dashboard widget configurations
4. Rebuild dashboard if corrupted
5. Restore from backup if available
```

---

## EMERGENCY 3: Alert Storm

**Symptoms:**
- 100+ alerts triggered in short time
- Mostly false positives
- Alert fatigue setting in
- Legitimate alerts buried

**Severity:** SEV-2 (High)

---

### Immediate Actions (First 10 Minutes)

**Step 1: Stop the Bleeding**
```
1. Identify triggering alert condition
2. Navigate to NinjaRMM Alert Policies
3. Temporarily disable the problem alert:
   - Note which alert disabled
   - Document time disabled
   - Plan to re-enable after fix
4. Clear existing false positive alerts
```

**Step 2: Triage Legitimate Alerts**
```
1. Review alerts generated during storm
2. Identify any legitimate critical alerts
3. Create tickets for real issues
4. Prioritize by severity
```

**Step 3: Investigate Root Cause**
```
Common causes:
- Threshold too sensitive
- Data calculation error
- Maintenance window not excluded
- Normal activity triggering alert
- Script reporting incorrect values
```

---

### Resolution

**Fix Approach 1: Adjust Threshold**
```
If data is correct but threshold wrong:
1. Analyze normal value ranges
2. Calculate appropriate threshold:
   - Mean + (2 × Standard Deviation)
   - Or 95th percentile + buffer
3. Update alert condition
4. Test on subset of devices
5. Re-enable alert
6. Monitor for 24 hours
```

**Fix Approach 2: Fix Data Issue**
```
If data calculation incorrect:
1. Identify the script providing data
2. Review calculation logic
3. Test script manually on device
4. Fix script bug
5. Redeploy script
6. Wait for data to update
7. Re-enable alert
```

**Fix Approach 3: Add Exclusions**
```
If certain conditions should not alert:
1. Add maintenance window exclusions
2. Exclude specific device groups
3. Add business hours filtering
4. Add "sustained" condition (e.g., "for 15 minutes")
5. Re-enable alert
```

---

## EMERGENCY 4: Data Accuracy Crisis

**Symptoms:**
- Multiple reports of incorrect monitoring data
- Health scores don't match reality
- Critical decisions based on bad data
- User confidence in system eroding

**Severity:** SEV-2 (High)

---

### Immediate Actions (First 30 Minutes)

**Step 1: Assess Impact**
```
1. How many devices affected?
2. Which fields are incorrect?
3. How long has data been wrong?
4. What decisions were made on bad data?
5. Document all findings
```

**Step 2: Communicate Issue**
```
Immediate notifications:
- Alert management: Data accuracy issue
- Notify teams: Do not rely on [specific fields] until fixed
- Post visible warning on dashboard (if possible)
- Document all stakeholders notified
```

**Step 3: Quarantine Bad Data**
```
1. Mark affected fields as "Unverified"
2. Remove from critical dashboards temporarily
3. Disable alerts based on affected data
4. Provide alternative data sources if available
```

---

### Investigation

**Step 4: Validate Good Data Sources**
```
1. Identify fields known to be accurate
2. Test against ground truth (manual checks)
3. Document verified accurate fields
4. Use as baseline for troubleshooting
```

**Step 5: Identify Data Issue Pattern**
```
Check:
- All devices or subset?
- All fields or specific category?
- Consistent error or intermittent?
- Recent change correlation?
```

**Step 6: Root Cause Analysis**
```
Common causes:
- Script logic error
- Unit conversion error (GB vs MB)
- Data type mismatch
- Field mapping error
- Calculation formula error
- Data source changed
```

---

### Resolution

**Step 7: Fix Data Source**
```
1. Identify root cause script/calculation
2. Review logic carefully
3. Test fix on pilot device
4. Compare to known good data
5. Deploy fix
6. Force immediate script re-run
```

**Step 8: Data Correction**
```
Options for historical data:
a) Leave as-is (note date range affected)
b) Recalculate (if possible)
c) Mark as invalid (clear field values)

Document decision and rationale.
```

**Step 9: Validation**
```
1. Manually verify 10+ devices
2. Compare to ground truth
3. Verify calculations correct
4. Check edge cases
5. Confirm 100% accuracy before declaring fixed
```

---

### Post-Resolution

**Step 10: Restore Confidence**
```
1. Communicate fix completed
2. Provide validation evidence
3. Re-enable affected alerts
4. Restore dashboard widgets
5. Remove warning notices
6. Offer to review any decisions made during issue
```

**Step 11: Prevent Recurrence**
```
1. Implement data quality checks
2. Add validation scripts
3. Create data quality dashboard
4. Schedule regular accuracy audits
5. Improve testing procedures
```

---

## EMERGENCY 5: Rollback Required

**Symptoms:**
- Recent change caused major issues
- Need to revert to previous state
- Time-critical situation

**Severity:** SEV-1 or SEV-2 (depending on impact)

---

### Immediate Actions

**Step 1: Make Rollback Decision**
```
Decision criteria:
- Is fix possible within SLA?
- Is impact severe and widespread?
- Is root cause clear?
- Are resources available to fix?

If NO to most: ROLLBACK
If YES to most: ATTEMPT FIX FIRST
```

**Step 2: Stop the Bleeding**
```
1. Disable automation policies (stop further damage)
2. Notify stakeholders: Rollback in progress
3. Document rollback decision and reason
```

---

### Rollback Execution

**Type 1: Script Rollback**
```
1. Identify previous working script version:
   - Check Git repository history
   - Or restore from backup
2. Re-upload previous version to NinjaRMM
3. Test on pilot device
4. Verify works as expected
5. Re-enable automation policies
6. Monitor for 1 hour
```

**Type 2: Field Rollback**
```
Note: Cannot undo field changes easily

1. Export current data (backup)
2. If field renamed:
   - Create old field name again
   - Migrate data back
   - Update scripts
3. If field deleted:
   - Recreate field
   - Re-run scripts to populate
4. Update dashboards to use restored fields
5. Update alert policies
```

**Type 3: Configuration Rollback**
```
1. Restore automation policy settings:
   - Schedules
   - Device groups
   - Execution settings
2. Restore alert policy settings
3. Restore dashboard configurations
4. Test on pilot device
5. Deploy to all devices
```

---

### Post-Rollback

**Step 3: Validate Rollback**
```
Verify:
- Scripts executing successfully
- Fields populating correctly
- Dashboards working
- Alerts functioning
- No new errors
- Performance acceptable
```

**Step 4: Analyze Failed Change**
```
1. Document what change was attempted
2. Document why it failed
3. Identify what should have been done differently
4. Plan how to safely re-attempt (if still needed)
5. Update procedures to prevent similar failures
```

---

## EMERGENCY 6: Security Incident

**Symptoms:**
- Unauthorized access to monitoring system
- Suspicious script modifications
- Data exfiltration concerns
- Compromised credentials

**Severity:** SEV-1 (Critical)

---

### Immediate Actions

**Step 1: Activate Security Incident Response**
```
1. Notify security team immediately
2. Do NOT modify anything (preserve evidence)
3. Document everything observed
4. Isolate affected systems if possible
5. Follow organization security incident procedures
```

**Step 2: Contain Threat**
```
Based on security team guidance:
1. Disable compromised accounts
2. Rotate API keys/credentials
3. Disable automation policies (prevent malicious scripts)
4. Review recent changes (identify malicious actions)
5. Preserve logs for forensics
```

**Step 3: Assess Impact**
```
Determine:
- What data was accessed?
- Were scripts modified?
- Were devices affected?
- What credentials were compromised?
- Duration of unauthorized access?
```

---

### Recovery (After Security Clearance)

**Step 4: Clean and Restore**
```
1. Verify all scripts against Git repository
2. Re-upload any modified scripts from known good source
3. Reset all credentials
4. Review all configurations
5. Audit all recent changes
6. Remove any backdoors/malicious modifications
```

**Step 5: Enhanced Monitoring**
```
1. Enable enhanced logging temporarily
2. Monitor for suspicious activity
3. Review access logs daily
4. Implement additional security controls
```

---

## Emergency Response Checklist

```markdown
## Emergency Response - Quick Checklist

### Initial Response (First 5 Minutes)
- [ ] Assess severity (SEV-1, 2, 3, or 4)
- [ ] Notify appropriate stakeholders
- [ ] Document start time and symptoms
- [ ] Stop further damage if applicable

### Investigation (Next 30-60 Minutes)
- [ ] Identify root cause
- [ ] Test theories on pilot device
- [ ] Document findings
- [ ] Determine fix approach

### Resolution (Hour 1-2)
- [ ] Implement fix
- [ ] Test on pilot devices
- [ ] Gradual rollout
- [ ] Validate recovery
- [ ] Monitor for stability

### Post-Incident
- [ ] Document incident report
- [ ] Communicate resolution
- [ ] Implement prevention measures
- [ ] Update documentation
- [ ] Conduct lessons learned session
```

---

## Emergency Response Kit

### Essential Information Always Available

**1. Emergency Contacts List**
- Team members with phone numbers
- Escalation contacts
- Vendor support contacts

**2. Access Credentials**
- NinjaRMM admin access
- GitHub repository access
- Backup/restore system access

**3. Documentation Links**
- This emergency procedures guide
- Troubleshooting flowcharts
- Script repository location
- Configuration backup location

**4. Quick Commands**
```powershell
# Force script re-run on device
Invoke-Command -ComputerName DEVICE -ScriptBlock { ... }

# Check script execution logs
Get-EventLog -LogName Application -Source NinjaRMM

# Manual health check
Get-ComputerInfo | Select-Object *
```

---

## Communication Templates

### Initial Notification Template
```
SUBJECT: [SEV-X] WAF Emergency - [Brief Description]

INCIDENT: [Description]
START TIME: [HH:MM]
IMPACT: [Scope of impact]
STATUS: Investigation in progress
ETA: [Estimated time to resolution]
ACTIONS: [What we're doing]
NEXT UPDATE: [When]

[Your Name]
```

### Progress Update Template
```
SUBJECT: UPDATE: [SEV-X] WAF Emergency

STATUS UPDATE: [Current status]
ROOT CAUSE: [If identified]
RESOLUTION PROGRESS: [What's been done]
NEXT STEPS: [What's next]
ETA: [Updated estimate]
NEXT UPDATE: [When]
```

### Resolution Notification Template
```
SUBJECT: RESOLVED: [SEV-X] WAF Emergency

INCIDENT: [Description]
DURATION: [Start] to [End] ([Total duration])
ROOT CAUSE: [Explanation]
RESOLUTION: [What fixed it]
IMPACT: [Summary of impact]
PREVENTION: [Steps to prevent recurrence]
FOLLOW-UP: [Any remaining actions]

Normal operations resumed.

[Your Name]
```

---

## Best Practices During Emergencies

### DO:
- Stay calm and methodical
- Document everything
- Communicate frequently
- Test fixes before wide deployment
- Ask for help when needed
- Follow established procedures
- Preserve evidence (logs, screenshots)

### DON'T:
- Panic or rush
- Make changes without documenting
- Skip testing phase
- Work in isolation
- Assume you know without verifying
- Skip post-incident documentation
- Blame individuals

---

## Training and Preparation

### Regular Drills

**Quarterly:**
- Run tabletop exercise simulating emergency
- Practice using this guide
- Verify contact information current
- Test backup/restore procedures

**Annually:**
- Full emergency simulation
- Update procedures based on lessons learned
- Train new team members
- Review all emergency scenarios

---

## Summary

**Key Principles:**

1. **Assess quickly** - Understand scope and severity
2. **Communicate early** - Notify stakeholders immediately
3. **Stop damage** - Prevent issue from spreading
4. **Investigate methodically** - Don't skip steps
5. **Test fixes** - Never deploy untested fixes in emergency
6. **Document everything** - For post-mortem and future
7. **Learn and improve** - Every incident improves procedures

**Remember:**
- It's an emergency for the system, not for you
- Methodical response beats rushed response
- Team collaboration is critical
- Documentation prevents repeat incidents

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Next Review:** Quarterly or after any SEV-1 incident
