# Plaintext Scripts Migration Plan

**Project:** Windows Automation Framework (WAF)  
**Task:** Standardize and migrate 200+ scripts from plaintext_scripts folder  
**Date:** February 9, 2026  
**Status:** Planning Phase

---

## Executive Summary

The plaintext_scripts folder contains 200+ automation scripts that need to be standardized according to WAF Coding Standards. This plan outlines the complete migration process including renaming, code updates, testing, and documentation.

### Key Objectives

1. Rename all scripts to follow WAF naming conventions
2. Apply WAF Coding Standards to all scripts
3. Eliminate duplicates
4. Add proper documentation headers
5. Remove emojis/checkmarks per Space guidelines
6. Test all scripts for compatibility
7. Create comprehensive documentation

### Timeline Overview

- **Phase 1 - Preparation:** 1 day
- **Phase 2 - Analysis & Documentation:** 2-3 days  
- **Phase 3 - Duplicate Resolution:** 1 day
- **Phase 4 - Batch Renaming:** 1 day
- **Phase 5 - Code Standardization:** 4-6 weeks
- **Phase 6 - Testing:** 2 weeks
- **Phase 7 - Deployment:** 1 week

**Total Estimated Time:** 8-11 weeks

---

## Phase 1: Preparation (1 Day)

### Objectives
- Set up tracking infrastructure
- Create backup procedures
- Establish validation tools

### Tasks

#### 1.1 Create Tracking Documents
- [ ] Create master script inventory spreadsheet
- [ ] Set up GitHub Project board for tracking
- [ ] Create progress dashboard

#### 1.2 Backup Current State
```powershell
# Create timestamped backup
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "C:\Backups\plaintext_scripts_$timestamp"
Copy-Item -Path "plaintext_scripts" -Destination $backupPath -Recurse
```

#### 1.3 Set Up Development Environment
- [ ] Create development branch: `feature/script-standardization`
- [ ] Set up local testing environment
- [ ] Install required validation tools

#### 1.4 Create Validation Scripts
- [ ] Script to check naming conventions
- [ ] Script to validate file headers
- [ ] Script to detect duplicates
- [ ] Script to check for emojis/special characters

---

## Phase 2: Analysis & Documentation (2-3 Days)

### Objectives
- Analyze all scripts thoroughly
- Document current state
- Identify issues and dependencies

### Tasks

#### 2.1 Inventory All Scripts
- [ ] List all scripts with current names
- [ ] Categorize by function type
- [ ] Identify script purposes
- [ ] Document dependencies

#### 2.2 Duplicate Detection
- [ ] Find exact duplicates (file hash comparison)
- [ ] Find similar scripts (content analysis)
- [ ] Document differences between versions
- [ ] Create deduplication plan

#### 2.3 Compliance Analysis
- [ ] Check for emoji/checkmark usage
- [ ] Identify RSAT dependencies
- [ ] Find external script references
- [ ] List module requirements

#### 2.4 Dependency Mapping
- [ ] Map custom fields used
- [ ] Identify shared functions
- [ ] Document module dependencies
- [ ] List OS/role requirements

---

## Phase 3: Duplicate Resolution (1 Day)

### Identified Duplicates

| Script 1 | Script 2 | Status | Action |
|----------|----------|--------|--------|
| Firewall - Audit Status.txt | Firewall - Audit Status 2.txt | Exact Duplicate | Delete #2 |
| Install Siemens NX .txt | Install Siemens NX  2.txt | Similar | Merge & Delete |
| Enable Mini-Dumps for BSOD (Blue Screen).txt | enable minidumps.txt | Similar | Merge & Delete |

### Tasks

#### 3.1 Resolve Exact Duplicates
- [ ] Verify file hashes match
- [ ] Keep better-named version
- [ ] Document deletion in tracking sheet

#### 3.2 Merge Similar Scripts
- [ ] Compare script contents
- [ ] Merge best features from both
- [ ] Test merged version
- [ ] Document merge decisions

---

## Phase 4: Batch Renaming (1 Day)

### Naming Convention

**Monitoring Scripts:**
```
Script_XX_Description_Monitor.ps1
Example: Script_01_Active_Directory_Domain_Controller_Health_Monitor.ps1
```

**Automation Scripts:**
```
XX_Description_Action.ps1
Example: 01_Active_Directory_Get_OU_Members.ps1
```

### Tasks

#### 4.1 Generate Rename Mapping
- [ ] Create CSV with old name → new name mapping
- [ ] Review for naming conflicts
- [ ] Validate against conventions
- [ ] Get approval for mapping

#### 4.2 Execute Renaming
```powershell
# Use rename script (see PLAINTEXT_SCRIPTS_RENAME.ps1)
.\scripts\Rename-PlaintextScripts.ps1 -MappingFile "rename_mapping.csv" -WhatIf
# Review changes, then execute:
.\scripts\Rename-PlaintextScripts.ps1 -MappingFile "rename_mapping.csv"
```

#### 4.3 Update Documentation
- [ ] Update inventory spreadsheet
- [ ] Update tracking documents
- [ ] Commit renamed files to Git

---

## Phase 5: Code Standardization (4-6 Weeks)

### Objectives
- Apply WAF Coding Standards to all scripts
- Add proper headers
- Implement error handling
- Remove prohibited elements

### Process Per Script

#### 5.1 Header Addition/Update
```powershell
<#
.SYNOPSIS
    Script XX: Brief one-line description

.DESCRIPTION
    Detailed multi-line description

.FIELDS UPDATED
    - fieldName1 (Type: Description)
    - fieldName2 (Date/Time: Unix Epoch)

.REQUIREMENTS
    - Windows version
    - PowerShell 5.1+
    - Domain membership (if needed)

.HELPER FUNCTIONS
    - FunctionName: Purpose

.NOTES
    Version: 1.0
    Author: WAF Team
    Last Updated: YYYY-MM-DD
    Language Compatibility: German/English Windows
    RSAT Required: No

.CHANGELOG
    1.0 (YYYY-MM-DD): Initial standardized version
#>

#Requires -Version 5.1
```

#### 5.2 Code Updates Required

**For Each Script:**
- [ ] Add/update synopsis header
- [ ] Embed helper functions (remove external references)
- [ ] Convert date/time to Unix Epoch format
- [ ] Convert complex data to Base64 JSON
- [ ] Replace RSAT modules with LDAP queries
- [ ] Use Write-Host exclusively
- [ ] Add proper error handling
- [ ] Remove emojis/checkmarks
- [ ] Add language-neutral code
- [ ] Implement proper exit codes

#### 5.3 Batch Processing Strategy

**Week 1-2: Active Directory Scripts (8 scripts)**
- Script_01 through Script_03
- Related automation scripts

**Week 2-3: System Monitoring Scripts (15 scripts)**
- Script_04 through Script_12
- Health and performance monitors

**Week 3-4: Security & Compliance Scripts (12 scripts)**
- Script_13 through Script_21
- Security monitoring and alerting

**Week 4-5: Network & Server Scripts (25 scripts)**
- Script_22 through Script_40
- Network, firewall, and server monitoring

**Week 5-6: Remaining Scripts (140+ scripts)**
- All automation scripts
- Specialized scripts
- Utility scripts

---

## Phase 6: Testing (2 Weeks)

### Test Matrix

| Test Type | Environment | OS | Language | Domain |
|-----------|-------------|----|----|--------|
| Unit Test | Dev | Win10 | EN | Yes |
| Unit Test | Dev | Win11 | EN | Yes |
| Unit Test | Dev | Win10 | DE | Yes |
| Unit Test | Dev | WinSrv2019 | EN | Yes |
| Unit Test | Dev | Win10 | EN | No (Workgroup) |
| Integration | Staging | Mixed | EN/DE | Yes |
| UAT | Production | Mixed | EN/DE | Yes |

### Tasks

#### 6.1 Create Test Plans
- [ ] Define test cases for each script category
- [ ] Create test data sets
- [ ] Set up test environments
- [ ] Define success criteria

#### 6.2 Unit Testing
- [ ] Test each script individually
- [ ] Verify field updates
- [ ] Check error handling
- [ ] Validate output format
- [ ] Test on multiple OS versions

#### 6.3 Integration Testing
- [ ] Test script sequences
- [ ] Verify custom field updates in NinjaRMM
- [ ] Check dashboard compatibility
- [ ] Test alert triggers

#### 6.4 User Acceptance Testing
- [ ] Deploy to test devices
- [ ] Monitor for 1 week
- [ ] Collect feedback
- [ ] Fix identified issues

---

## Phase 7: Deployment (1 Week)

### Pre-Deployment Checklist

- [ ] All scripts tested and approved
- [ ] Documentation complete
- [ ] Migration guide created
- [ ] Rollback plan prepared
- [ ] Stakeholders notified

### Deployment Strategy

#### 7.1 Pilot Deployment (Day 1-2)
- Deploy to 10% of devices
- Monitor closely for issues
- Collect metrics

#### 7.2 Staged Rollout (Day 3-5)
- 25% of devices on Day 3
- 50% of devices on Day 4
- 75% of devices on Day 5

#### 7.3 Full Deployment (Day 6)
- Deploy to all remaining devices
- Monitor dashboards
- Verify alerts

#### 7.4 Post-Deployment (Day 7)
- Collect final metrics
- Document lessons learned
- Update documentation
- Archive old scripts

---

## Risk Management

### Identified Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking changes in scripts | High | High | Comprehensive testing, rollback plan |
| Field mapping changes | Medium | High | Document all changes, update dashboards |
| NinjaRMM compatibility | Low | High | Test in staging environment first |
| Timeline overrun | Medium | Medium | Buffer time in schedule, prioritize critical scripts |
| Resource availability | Medium | Medium | Assign backup resources |

### Rollback Plan

If critical issues are discovered:

1. **Immediate Actions**
   - Stop deployment
   - Notify stakeholders
   - Assess impact

2. **Rollback Procedure**
   ```powershell
   # Restore from backup
   $backupPath = "C:\Backups\plaintext_scripts_backup"
   Remove-Item "plaintext_scripts" -Recurse -Force
   Copy-Item -Path $backupPath -Destination "plaintext_scripts" -Recurse
   ```

3. **Communication**
   - Document issues
   - Notify affected teams
   - Create fix plan

---

## Quality Assurance

### Code Review Checklist

For each script before approval:

- [ ] Naming convention followed
- [ ] Synopsis header complete
- [ ] No external script references
- [ ] No RSAT-only modules
- [ ] No emojis or checkmarks
- [ ] Proper error handling
- [ ] Write-Host used exclusively
- [ ] Unix Epoch for dates
- [ ] Base64 for complex data
- [ ] Language-neutral code
- [ ] Tested on German/English Windows
- [ ] No hardcoded credentials

### Automated Validation

```powershell
# Run validation suite
.\scripts\Validate-ScriptStandards.ps1 -ScriptPath "path\to\script.ps1"

# Expected output:
# [PASS] Naming convention
# [PASS] Header present
# [PASS] No external references
# [FAIL] Emoji detected on line 45
# [PASS] Error handling present
```

---

## Success Metrics

### Key Performance Indicators

| Metric | Target | Measurement |
|--------|--------|-------------|
| Scripts standardized | 100% | Count of compliant scripts |
| Test success rate | >95% | Passing tests / total tests |
| Deployment success | >98% | Devices without errors |
| Rollback rate | <2% | Scripts requiring rollback |
| Documentation complete | 100% | All scripts documented |

### Reporting

- **Daily:** Progress updates in tracking sheet
- **Weekly:** Status report to stakeholders
- **End of Phase:** Phase completion report
- **End of Project:** Final migration report

---

## Resource Requirements

### Personnel

- **Lead Developer:** Full-time, 8-11 weeks
- **QA Engineer:** Part-time, 3 weeks
- **Technical Writer:** Part-time, 2 weeks
- **DevOps Engineer:** Part-time, 1 week

### Tools & Infrastructure

- Development environment
- Staging environment
- Test devices (various OS/configs)
- GitHub repository access
- NinjaRMM test tenant

---

## Communication Plan

### Stakeholders

- IT Management
- Operations Team
- End Users (minimal impact)

### Communication Schedule

| When | What | To Whom | Method |
|------|------|---------|--------|
| Project Start | Kickoff notification | All stakeholders | Email |
| Weekly | Progress update | IT Management | Status report |
| Before Deployment | Change notification | Operations Team | Email + Meeting |
| During Deployment | Status updates | Operations Team | Chat/Email |
| After Deployment | Completion report | All stakeholders | Email |

---

## Documentation Deliverables

### Required Documents

1. **PLAINTEXT_SCRIPTS_INVENTORY.md** - Complete script catalog
2. **PLAINTEXT_SCRIPTS_RENAME_MAPPING.csv** - Old → New name mapping
3. **PLAINTEXT_SCRIPTS_MIGRATION_GUIDE.md** - Step-by-step guide
4. **PLAINTEXT_SCRIPTS_TESTING_RESULTS.md** - Test results summary
5. **PLAINTEXT_SCRIPTS_DEPLOYMENT_REPORT.md** - Final deployment report

### Script Documentation

Each script needs:
- Complete synopsis header
- Inline comments for complex logic
- Changelog with version history
- Usage examples (where applicable)

---

## Next Steps

### Immediate Actions (This Week)

1. **Create tracking infrastructure**
   - Set up GitHub Project board
   - Create inventory spreadsheet
   - Set up development branch

2. **Generate detailed inventory**
   - Run analysis scripts
   - Document all scripts
   - Identify duplicates

3. **Create validation tools**
   - Naming convention checker
   - Code standards validator
   - Emoji/special character detector

4. **Approval & Sign-off**
   - Review plan with stakeholders
   - Get approval to proceed
   - Allocate resources

### Week 1 Actions

1. Complete Phase 1 (Preparation)
2. Complete Phase 2 (Analysis & Documentation)
3. Complete Phase 3 (Duplicate Resolution)
4. Begin Phase 4 (Batch Renaming)

---

## Appendices

### Appendix A: Naming Convention Reference

See [PLAINTEXT_SCRIPTS_INVENTORY.md](PLAINTEXT_SCRIPTS_INVENTORY.md) for complete mapping.

### Appendix B: Validation Scripts

See `scripts/` folder for:
- `Validate-ScriptStandards.ps1`
- `Rename-PlaintextScripts.ps1`
- `Detect-Duplicates.ps1`
- `Check-EmojiUsage.ps1`

### Appendix C: WAF Coding Standards

See [WAF_CODING_STANDARDS.md](WAF_CODING_STANDARDS.md) for complete standards.

---

## Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Lead | | | |
| IT Manager | | | |
| QA Lead | | | |

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Next Review:** Weekly during project execution
