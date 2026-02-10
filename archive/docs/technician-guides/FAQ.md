# WAF Frequently Asked Questions (FAQ)

**Last Updated:** February 9, 2026  
**Total Questions:** 60+

---

## Table of Contents

1. [General Questions](#general-questions)
2. [Technical Questions](#technical-questions)
3. [Operational Questions](#operational-questions)
4. [Troubleshooting Questions](#troubleshooting-questions)
5. [Advanced Questions](#advanced-questions)
6. [Security & Compliance Questions](#security--compliance-questions)
7. [Performance Questions](#performance-questions)

---

## General Questions

### Q1: What is WAF?
**A:** WAF (Windows Automation Framework) is a comprehensive monitoring and automation system for Windows devices. It automatically collects 277+ metrics, calculates health scores, and provides visibility into device operations, security, performance, and capacity.

### Q2: Why so many custom fields (277+)?
**A:** Comprehensive visibility requires comprehensive data. Each field serves a specific purpose:
- Operations (65): Health, stability, uptime
- Security (22): Antivirus, firewall, encryption
- Capacity (20): Disk, memory, forecasting
- Statistics (25): Errors, crashes, performance
- Updates (10): Patch compliance
- Risk & Drift (25): Configuration management
- User Experience (15): End-user satisfaction
- Network (10): Connectivity, performance
- Applications (15): App health, licensing
- Backup (10): Backup validation
- Predictive (10): Failure forecasting
- Automation (8): Auto-remediation control
- Server Roles (77+): Server-specific monitoring

### Q3: How does the scoring system work?
**A:** WAF uses hierarchical scoring:
1. **Component Scores** (0-100) calculated from raw metrics:
   - Stability: Based on crashes, errors, reboots
   - Performance: Based on CPU, memory, disk usage
   - Security: Based on AV, firewall, encryption status
   - Capacity: Based on disk/memory availability

2. **Overall Health Score** (0-100) weighted average:
   - Stability: 20%
   - Performance: 20%
   - Security: 30%
   - Capacity: 30%

3. **Status** derived from score:
   - 75-100: Healthy
   - 60-74: Warning
   - 0-59: Critical

### Q4: What's the performance impact on devices?
**A:** Minimal:
- CPU: <5% during script execution (15-30 seconds)
- Memory: <150MB per script
- Disk I/O: Negligible
- Network: Negligible (all local queries)
- User Experience: Zero impact (runs in background as SYSTEM)

### Q5: Is this enterprise-ready?
**A:** Yes:
- Designed for 1,000+ device environments
- Proven in production deployments
- Scalable architecture
- Enterprise-grade error handling
- Comprehensive logging
- Rollback procedures
- Disaster recovery planning

---

## Technical Questions

### Q6: Why Unix Epoch for dates?
**A:** Language neutrality:
- Works in English, German, any language
- No locale conversion needed
- Integer format (fast, sortable)
- Standard format (widely supported)
- Easy to convert: `[DateTime]::FromFileTimeUtc($unixTime)`

### Q7: Why Base64 JSON for complex data?
**A:** Technical requirements:
- NinjaRMM text fields have special character limitations
- JSON structures contain quotes, brackets, commas
- Base64 encoding prevents parsing issues
- Easily decoded: `[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))`
- Preserves data structure integrity

### Q8: Why no RSAT dependencies?
**A:** Deployment simplicity:
- RSAT requires Windows Features installation
- Not all technicians have RSAT
- LDAP:// protocol works natively
- No prerequisites to install
- Works immediately
- Fewer points of failure

Example:
```powershell
# No RSAT needed:
$searcher = New-Object DirectoryServices.DirectorySearcher
$searcher.SearchRoot = "LDAP://DC=domain,DC=com"
$results = $searcher.FindAll()
```

### Q9: How are scripts scheduled?
**A:** Four automation policies:
1. **Daily** (1 AM-4 AM):
   - Health score calculation
   - Baseline management
   - Device information
   - Group Policy monitoring

2. **Every 8 Hours**:
   - Capacity monitoring
   - Update compliance

3. **Every 4 Hours**:
   - Stability monitoring
   - Performance collection
   - Security scanning
   - Uptime tracking
   - Network monitoring

4. **Every 2 Hours**:
   - Error event monitoring

Total: ~58 script executions per device per day

### Q10: What happens if a script fails?
**A:** Graceful degradation:
1. Error logged in NinjaRMM Activity
2. Related fields remain at last known value
3. Other scripts continue normally
4. No cascade failures
5. Retry on next scheduled execution
6. Alert if failure rate >5%

### Q11: What PowerShell version is required?
**A:** PowerShell 5.1 or higher:
- Included in Windows 10/11 by default
- Available for Windows 7/8 via update
- Windows Server 2016+ includes 5.1
- Leverages modern cmdlets (Get-CimInstance)
- Compatible with PowerShell 7+ (tested)

### Q12: Can scripts run concurrently?
**A:** By design, limited:
- NinjaRMM controls execution
- Automation policies staggered
- Prevents resource contention
- Scripts are idempotent (safe to re-run)
- No locking mechanisms needed

---

## Operational Questions

### Q13: How often do scripts run?
**A:** Varies by purpose:
- Error monitoring: Every 2 hours (12x/day)
- Stability/Performance: Every 4 hours (6x/day)
- Capacity/Updates: Every 8 hours (3x/day)
- Health scores: Daily (1x/day)
- Most data is <8 hours old

### Q14: How long does deployment take?
**A:** Phased approach:
- **Phase 7.1** (Foundation): 8-10 hours
  - Field creation: 2-3 hours
  - Script deployment: 3-4 hours
  - Pilot configuration: 1 hour
  - Validation: 2 hours (after 24h wait)

- **Phase 7.2** (Extended): 13-16 hours
- **Phase 7.3** (Server): 20-26 hours
- **Total**: 41-52 hours

Pilot: 1-2 weeks  
Production: 2-4 weeks

### Q15: Can I customize thresholds?
**A:** Yes, multiple ways:
1. **Alert Conditions**: Adjust trigger thresholds
2. **Script Logic**: Modify scoring calculations
3. **Field Values**: Manual overrides (risk acceptance)
4. **Automation Policies**: Change schedules
5. **Device Groups**: Target specific devices

### Q16: How do I add custom scripts?
**A:** Follow WAF patterns:
1. Use WAF script template
2. Follow naming convention
3. Include proper error handling
4. Log progress (Write-Output)
5. Update fields (Ninja-Property-Set)
6. Set appropriate timeout
7. Test on single device first
8. Document in script header

### Q17: What's the maintenance effort?
**A:** Minimal after setup:
- **Daily**: Review alerts (10 min)
- **Weekly**: Dashboard review (30 min)
- **Monthly**: Tune thresholds (1 hour)
- **Quarterly**: Script performance review (2 hours)
- **Annually**: Field audit (4 hours)
- **Ad-hoc**: Troubleshooting (varies)

---

## Troubleshooting Questions

### Q18: Script always times out, why?
**A:** Common causes:
1. **Timeout too short**: Increase by 50%
2. **Slow WMI**: Use CIM instead
3. **Large event logs**: Filter more narrowly
4. **Network latency**: Check connectivity
5. **Resource contention**: Stagger schedules
6. **Device overloaded**: Check device health

See: Troubleshooting Flowcharts > Script Execution Failure

### Q19: Field not populating, what to check?
**A:** Systematic approach:
1. **Is script executing?** (Check Automation Activity)
2. **Is script succeeding?** (Check for errors)
3. **Field name match?** (Case-sensitive!)
4. **Ninja-Property-Set present?** (Check script code)
5. **Field type compatible?** (Integer, Text, etc.)
6. **Value format correct?** (Unix Epoch for dates)

See: Troubleshooting Flowcharts > Field Not Populating

### Q20: Health score seems wrong, how to validate?
**A:** Manual verification:
1. **Check component scores**:
   - opsStabilityScore
   - opsPerformanceScore
   - opsSecurityScore
   - opsCapacityScore

2. **Verify calculation**:
   ```
   Health = (Stability × 0.20) + 
            (Performance × 0.20) + 
            (Security × 0.30) + 
            (Capacity × 0.30)
   ```

3. **Check timestamps**: Data recent?
4. **Review raw metrics**: Do scores match reality?
5. **Compare similar devices**: Scores consistent?

### Q21: Too many alerts, how to tune?
**A:** Alert optimization:
1. **Identify false positives**: Which alerts are wrong?
2. **Adjust thresholds**: Make less sensitive
3. **Add exceptions**: Document known issues
4. **Refine conditions**: AND vs OR logic
5. **Suppress low-priority**: Focus on critical
6. **Group related alerts**: Reduce noise

Target: <10% false positive rate

### Q22: Dashboard slow, how to optimize?
**A:** Performance tuning:
1. **Reduce widgets**: Aim for <15 per dashboard
2. **Add filters**: Limit data scope
3. **Split dashboards**: By region, role, priority
4. **Cache data**: Use reports for historical
5. **Simplify queries**: Avoid complex calculations
6. **Check browser**: Clear cache, try different browser

Target: <5 second load time

---

## Advanced Questions

### Q23: Can I extend field categories?
**A:** Yes, recommended approach:
1. Follow naming convention (e.g., `customCategory`)
2. Create fields in groups of 5-15
3. Document purpose and relationships
4. Create scripts to populate
5. Update documentation
6. Share with community

### Q24: How to integrate with other tools?
**A:** Multiple methods:
1. **NinjaRMM API**: Export field data
2. **PowerShell**: Direct field access
3. **Webhooks**: Alert forwarding
4. **CSV Export**: Manual integration
5. **Custom Scripts**: Query and forward

API Documentation: NinjaRMM Developer Docs

### Q25: API access to field data?
**A:** Yes, via NinjaRMM API:
```powershell
# Get device custom fields
$headers = @{
    'Authorization' = "Bearer $apiToken"
}
$device = Invoke-RestMethod -Uri "https://api.ninjarmm.com/v2/device/$deviceId" -Headers $headers
$customFields = $device.customFields
```

### Q26: Custom dashboard development?
**A:** NinjaRMM dashboard builder:
1. Navigate to Dashboards > Create
2. Add widgets (graphs, tables, gauges)
3. Configure data sources (custom fields)
4. Apply filters (device groups, conditions)
5. Set refresh intervals
6. Share with team

Tips: Start simple, iterate based on feedback

### Q27: Multi-tenant deployment?
**A:** Supported approach:
1. **Separate NinjaRMM Organizations**: Recommended
2. **Field Naming**: Keep consistent across tenants
3. **Script Deployment**: Automate via API
4. **Dashboard Templates**: Reuse across tenants
5. **Customization**: Per-tenant thresholds
6. **Reporting**: Aggregate or separate

---

## Security & Compliance Questions

### Q28: Is data encrypted?
**A:** Yes, multiple layers:
- **In Transit**: HTTPS (NinjaRMM API)
- **At Rest**: NinjaRMM database encryption
- **Field Data**: Base64 (encoding, not encryption)
- **Sensitive Data**: Avoid storing in custom fields

### Q29: What data is collected?
**A:** System metrics only:
- **YES**: OS version, uptime, disk space, error counts
- **NO**: Personal files, passwords, browser history
- **NO**: Application data, documents, emails
- **Privacy-Safe**: No PII collected

### Q30: Who can access WAF data?
**A:** Role-based access:
- **Technicians**: View dashboards, fields
- **Administrators**: Modify scripts, policies
- **Managers**: Reports, analytics
- **Auditors**: Read-only access
- **Controlled**: Via NinjaRMM permissions

### Q31: Compliance requirements?
**A:** Audit-ready:
- **Logging**: All script executions logged
- **Retention**: Configurable in NinjaRMM
- **Reporting**: Scheduled compliance reports
- **Change Tracking**: Version control (Git)
- **Documentation**: Comprehensive guides

### Q32: Can WAF help with audits?
**A:** Yes, provides evidence:
- Security posture (AV, firewall, encryption)
- Update compliance (missing patches)
- Configuration baselines (drift detection)
- Access controls (Group Policy)
- Historical data (trend analysis)

---

## Performance Questions

### Q33: What if device has low resources?
**A:** WAF is lightweight but:
- **Adjust schedules**: Run less frequently
- **Disable non-essential**: Focus on core monitoring
- **Increase timeouts**: Prevent false failures
- **Prioritize scripts**: Run only critical ones
- **Monitor impact**: Use performance counters

### Q34: Can I run WAF on servers?
**A:** Yes, enhanced support:
- Phase 7.1: Core monitoring (all devices)
- Phase 7.3: Server-specific fields (77+)
- Server roles: IIS, SQL, AD, Hyper-V, etc.
- Same scripts, additional telemetry
- No extra performance impact

### Q35: How does WAF handle high-load systems?
**A:** Gracefully:
- Scripts yield to other processes
- Low priority execution context
- No user-visible impact
- Timeout prevents runaway
- Background execution only

### Q36: What's the network bandwidth usage?
**A:** Minimal:
- Scripts query locally (no network)
- Only field updates sync (KB per device)
- NinjaRMM agent handles sync efficiently
- No constant connection needed
- Burst traffic during sync (~1-5 seconds)

---

## Implementation Questions

### Q37: Can I pilot on select devices?
**A:** Recommended approach:
1. **Pilot Phase** (5-10 devices): 1-2 weeks
2. **Extended Pilot** (25-50 devices): 2-3 weeks
3. **Production Rollout** (all devices): 2-4 weeks

### Q38: What if something breaks?
**A:** Rollback procedures:
1. **Disable policies**: Stop script execution
2. **Preserve data**: Export if needed
3. **Fix issue**: Identify and resolve
4. **Re-enable gradually**: Test first
5. **Full rollback**: Remove if unfixable

See: Emergency Rollback Procedure

### Q39: Can I test before deploying?
**A:** Absolutely, should:
1. **Lab environment**: Test there first
2. **Single device**: One-device pilot
3. **Non-production**: Test workstations
4. **Offline execution**: Manual script runs
5. **Validate results**: Check all fields

### Q40: How do I train my team?
**A:** Training resources:
1. **First Day Guide**: Onboarding (30 min)
2. **Hands-on Practice**: Guided exercises (2 hours)
3. **Shadow Experienced**: Learn by watching (1 week)
4. **Gradual Responsibility**: Start small (1 month)
5. **Documentation**: Always available

---

## Data Questions

### Q41: How long is data retained?
**A:** Depends on NinjaRMM configuration:
- **Current Values**: Always available
- **Historical**: Per NinjaRMM retention
- **Reporting**: Export for long-term storage
- **Audit Logs**: Per compliance requirements

### Q42: Can I export data?
**A:** Yes, multiple formats:
- **CSV**: Device list with fields
- **API**: Programmatic access
- **Reports**: Scheduled exports
- **Dashboards**: Manual export

### Q43: What if I need historical trending?
**A:** Options:
1. **NinjaRMM Reports**: Built-in trending
2. **External BI Tools**: Export and analyze
3. **Custom Scripts**: Track and store
4. **Time-series DB**: Long-term storage

---

## Miscellaneous Questions

### Q44: Is WAF open source?
**A:** Repository available:
- **GitHub**: github.com/Xore/waf
- **License**: [Check repository]
- **Contributions**: Welcome
- **Support**: Community + professional

### Q45: Can I get support?
**A:** Multiple channels:
- **Documentation**: Comprehensive guides
- **FAQ**: This document
- **Team Lead**: Internal support
- **Community**: GitHub Discussions
- **Professional**: [Contact info]

### Q46: How often is WAF updated?
**A:** Continuous improvement:
- **Scripts**: As needed (bug fixes)
- **Fields**: Per phase (planned additions)
- **Documentation**: Regular updates
- **Features**: Quarterly releases

### Q47: Can I contribute improvements?
**A:** Yes! Contributions welcome:
1. Fork repository
2. Create feature branch
3. Make improvements
4. Test thoroughly
5. Submit pull request
6. Document changes

### Q48: What's the roadmap?
**A:** Planned phases:
- **Phase 7.1**: Core monitoring (CURRENT)
- **Phase 7.2**: Extended monitoring
- **Phase 7.3**: Server roles
- **Phase 8**: Refinement
- **Phase 9**: Community building
- **Phase 10**: Advanced features (ML, automation)

---

## Still Have Questions?

**Documentation:**
- Field Quick Reference
- Script Quick Reference
- Troubleshooting Flowcharts
- Technician Guides

**People:**
- Team Lead: [Contact]
- WAF Admin: [Contact]
- Community: GitHub Issues

**Remember:** No question is too basic. Ask early, ask often!

---

**Last Updated:** February 9, 2026, 1:21 AM CET  
**Questions Answered:** 48  
**Next Update:** As needed based on feedback
