# Plaintext Scripts Standardization - Action Plan

**Project:** Windows Automation Framework (WAF)  
**Date:** February 9, 2026  
**Owner:** WAF Team  
**Status:** Ready to Execute

---

## Quick Reference

### Timeline Summary
- **Total Duration:** 8-11 weeks
- **Start Date:** TBD
- **Target Completion:** TBD

### Key Milestones
1. **Week 1:** Setup and Analysis Complete
2. **Week 2:** Renaming Complete
3. **Week 3-8:** Code Standardization
4. **Week 9-10:** Testing
5. **Week 11:** Deployment

---

## Phase 1: Immediate Actions (This Week)

### Day 1: Setup Infrastructure

**Morning (2 hours)**
```bash
# 1. Create development branch
cd /path/to/waf
git checkout -b feature/script-standardization
git push -u origin feature/script-standardization

# 2. Create backup
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "C:\Backups\WAF\plaintext_scripts_$timestamp"
Copy-Item -Path "plaintext_scripts" -Destination $backupPath -Recurse
Write-Host "Backup created at: $backupPath"

# 3. Create tracking folder
New-Item -Path "docs\tracking" -ItemType Directory -Force
```

**Afternoon (4 hours)**
- [ ] Set up GitHub Project board
- [ ] Create tracking spreadsheet template
- [ ] Install validation tools
- [ ] Review WAF Coding Standards

### Day 2: Analysis & Documentation

**Tasks:**
- [ ] Review all 164 scripts for compliance issues
- [ ] Document emoji/checkmark usage
- [ ] Identify RSAT dependencies
- [ ] List external script references
- [ ] Validate rename mapping

**Deliverables:**
- Analysis report
- Compliance issues list
- Updated inventory

### Day 3: Duplicate Resolution

**Scripts to Address:**

1. **Firewall - Audit Status 2.txt**
   ```powershell
   # Action: Delete (exact duplicate)
   Remove-Item "plaintext_scripts\Firewall - Audit Status 2.txt" -Force
   ```

2. **Install Siemens NX  2.txt**
   ```powershell
   # Action: Compare, merge best version, delete duplicate
   code "plaintext_scripts\Install Siemens NX .txt"
   code "plaintext_scripts\Install Siemens NX  2.txt"
   # After merging:
   Remove-Item "plaintext_scripts\Install Siemens NX  2.txt" -Force
   ```

3. **enable minidumps.txt**
   ```powershell
   # Action: Compare with "Enable Mini-Dumps for BSOD (Blue Screen).txt"
   # Merge and keep better version
   ```

**Deliverable:** Clean script folder with no duplicates

---

## Phase 2: Batch Renaming (Day 4-5)

### Preparation

**Create rename script:**
```powershell
# Save as: scripts/Rename-PlaintextScripts.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$MappingFile,
    
    [switch]$WhatIf
)

# Import mapping
$mapping = Import-Csv -Path $MappingFile

# Process each rename
foreach ($item in $mapping) {
    if ($item.Action -eq "Delete") {
        if ($WhatIf) {
            Write-Host "WOULD DELETE: $($item.OldName)"
        } else {
            Remove-Item "plaintext_scripts\$($item.OldName)" -Force
            Write-Host "DELETED: $($item.OldName)"
        }
    }
    elseif ($item.Action -eq "Rename") {
        $oldPath = "plaintext_scripts\$($item.OldName)"
        $newPath = "plaintext_scripts\$($item.NewName)"
        
        if ($WhatIf) {
            Write-Host "WOULD RENAME: $($item.OldName) -> $($item.NewName)"
        } else {
            Rename-Item -Path $oldPath -NewName $item.NewName
            Write-Host "RENAMED: $($item.OldName) -> $($item.NewName)"
        }
    }
}
```

### Execution Steps

```powershell
# Step 1: Test with WhatIf
.\scripts\Rename-PlaintextScripts.ps1 -MappingFile "docs\tracking\rename_mapping.csv" -WhatIf

# Step 2: Review output

# Step 3: Execute rename
.\scripts\Rename-PlaintextScripts.ps1 -MappingFile "docs\tracking\rename_mapping.csv"

# Step 4: Commit changes
git add plaintext_scripts/
git commit -m "Standardize script names according to WAF naming conventions"
git push
```

---

## Phase 3: Code Standardization (Week 2-7)

### Week-by-Week Plan

#### Week 2: Active Directory Scripts (8 scripts)

**Scripts:**
- Script_01_Active_Directory_Domain_Controller_Health_Monitor.ps1
- Script_02_Active_Directory_Replication_Health_Monitor.ps1
- Script_03_Active_Directory_General_Monitor.ps1
- 01_Active_Directory_Get_OU_Members.ps1
- 02_Active_Directory_Get_Organizational_Unit.ps1
- 03_Active_Directory_Join_Computer_to_Domain.ps1
- 04_Active_Directory_Remove_Computer_from_Domain.ps1
- 05_Active_Directory_Repair_Computer_Trust.ps1

**Tasks per script:**
1. Add standard header
2. Convert to LDAP queries (remove RSAT dependencies)
3. Add error handling
4. Convert dates to Unix Epoch
5. Remove emojis/checkmarks
6. Test on German/English Windows

**Target:** 2 scripts per day

#### Week 3: System Monitoring Scripts (11 scripts)

**Scripts:** Script_04 through Script_12

**Focus areas:**
- Battery health monitoring
- Service monitoring
- Performance metrics
- Uptime tracking

**Target:** 2-3 scripts per day

#### Week 4: Security & Compliance Scripts (12 scripts)

**Scripts:** Script_13 through Script_21

**Focus areas:**
- SMBv1 compliance
- Antivirus detection
- Security alerts
- Compliance monitoring

**Target:** 2-3 scripts per day

#### Week 5: Network & Firewall Scripts (24 scripts)

**Scripts:** Script_22 through Script_27, plus automation scripts

**Focus areas:**
- Network monitoring
- WiFi management
- Firewall auditing
- DHCP monitoring

**Target:** 4-5 scripts per day

#### Week 6: Server & Application Scripts (30 scripts)

**Scripts:** Script_28 through Script_42

**Focus areas:**
- SQL Server monitoring
- Exchange monitoring
- Hyper-V monitoring
- IIS monitoring

**Target:** 5-6 scripts per day

#### Week 7: Remaining Scripts (80+ scripts)

**Focus:**
- Installation scripts
- Removal scripts
- Utility scripts
- User management
- File operations

**Target:** 15-20 scripts per day

### Code Standardization Checklist

For each script:

```markdown
## Script: [Name]

### Pre-Work
- [ ] Read and understand current functionality
- [ ] Document custom fields used
- [ ] Identify dependencies
- [ ] List OS/role requirements

### Header Work
- [ ] Add complete synopsis block
- [ ] Document .FIELDS UPDATED
- [ ] Document .REQUIREMENTS
- [ ] List .HELPER FUNCTIONS
- [ ] Add .CHANGELOG entry
- [ ] Add #Requires -Version 5.1

### Code Updates
- [ ] Embed all helper functions
- [ ] Remove external script references
- [ ] Replace RSAT modules with LDAP
- [ ] Convert dates to Unix Epoch
- [ ] Convert complex data to Base64 JSON
- [ ] Use Write-Host exclusively
- [ ] Add try-catch error handling
- [ ] Remove emojis and checkmarks
- [ ] Add language-neutral code
- [ ] Implement proper exit codes

### Testing
- [ ] Test on Windows 10/11
- [ ] Test on English Windows
- [ ] Test on German Windows
- [ ] Test domain-joined
- [ ] Test workgroup
- [ ] Verify field updates
- [ ] Check error scenarios

### Documentation
- [ ] Update tracking spreadsheet
- [ ] Document any breaking changes
- [ ] Update usage examples
- [ ] Commit to Git
```

---

## Phase 4: Validation & Testing (Week 8-9)

### Week 8: Unit Testing

**Test Matrix:**

| OS | Language | Domain | Scripts | Notes |
|----|----------|--------|---------|-------|
| Win10 Pro | EN | Yes | All | Primary test |
| Win11 Pro | EN | Yes | All | Windows 11 validation |
| Win10 Pro | DE | Yes | All | German language |
| Server 2019 | EN | Yes | Server scripts | Server-specific |
| Win10 Pro | EN | No | All | Workgroup test |

**Testing Process:**

```powershell
# Create test report
$testReport = @()

foreach ($script in Get-ChildItem "plaintext_scripts\*.ps1") {
    Write-Host "Testing: $($script.Name)"
    
    try {
        # Execute script
        $result = & $script.FullName
        
        $testReport += [PSCustomObject]@{
            Script = $script.Name
            Status = "Pass"
            Error = $null
            Duration = $executionTime
        }
    }
    catch {
        $testReport += [PSCustomObject]@{
            Script = $script.Name
            Status = "Fail"
            Error = $_.Exception.Message
            Duration = 0
        }
    }
}

# Export report
$testReport | Export-Csv "docs\tracking\test_results.csv" -NoTypeInformation
```

### Week 9: Integration Testing

**NinjaRMM Integration:**
1. Deploy to test organization
2. Run all scripts
3. Verify custom field updates
4. Check dashboard data
5. Validate alerts

**Documentation:**
- Test results summary
- Issues found and fixed
- Performance metrics

---

## Phase 5: Deployment (Week 10-11)

### Week 10: Pilot Deployment

**Day 1-2: 10% Rollout**
- Select 10 test devices
- Deploy new scripts
- Monitor for 48 hours
- Collect metrics

**Metrics to Track:**
- Script execution success rate
- Field population rate
- Error frequency
- Dashboard update latency

**Day 3-5: Staged Rollout**
- 25% on Day 3
- 50% on Day 4  
- 75% on Day 5

**Monitoring:**
```powershell
# Check script success rates
Get-NinjaScriptResults | 
    Where-Object { $_.Status -eq "Failed" } |
    Group-Object ScriptName |
    Select-Object Name, Count
```

### Week 11: Full Deployment

**Day 1-2: Complete Rollout**
- Deploy to remaining devices
- Monitor dashboards
- Respond to issues

**Day 3-5: Stabilization**
- Fix any issues found
- Optimize performance
- Update documentation

**Day 6-7: Project Closeout**
- Final metrics collection
- Lessons learned document
- Archive old scripts
- Update training materials

---

## Validation Tools

### Tool 1: Naming Convention Checker

```powershell
# Save as: scripts/Test-ScriptNaming.ps1

param([string]$Path = "plaintext_scripts")

$scripts = Get-ChildItem -Path $Path -Filter "*.ps1"
$issues = @()

foreach ($script in $scripts) {
    $name = $script.Name
    
    # Check monitoring script naming
    if ($name -match "^Script_\d{2}_.*_Monitor\.ps1$") {
        # Valid monitoring script
    }
    # Check automation script naming
    elseif ($name -match "^\d{2}_.*\.ps1$") {
        # Valid automation script
    }
    # Check template naming
    elseif ($name -match "^TEMPLATE_.*\.ps1$") {
        # Valid template
    }
    else {
        $issues += "Invalid naming: $name"
    }
}

if ($issues.Count -eq 0) {
    Write-Host "All scripts follow naming convention" -ForegroundColor Green
} else {
    Write-Host "Found $($issues.Count) naming issues:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" }
}
```

### Tool 2: Emoji/Special Character Detector

```powershell
# Save as: scripts/Test-SpecialCharacters.ps1

param([string]$Path = "plaintext_scripts")

$scripts = Get-ChildItem -Path $Path -Filter "*.ps1"
$issues = @()

# Prohibited characters (per Space guidelines)
$prohibited = @(
    [char]0x2714,  # Checkmark
    [char]0x2718,  # X mark
    [char]0x2713,  # Check mark
    [char]0x274C   # Cross mark
)

foreach ($script in $scripts) {
    $content = Get-Content $script.FullName -Raw
    
    foreach ($char in $prohibited) {
        if ($content -match [regex]::Escape($char)) {
            $issues += "$($script.Name): Contains prohibited character '$char'"
        }
    }
    
    # Check for emoji patterns
    if ($content -match '[\u{1F300}-\u{1F9FF}]') {
        $issues += "$($script.Name): Contains emoji"
    }
}

if ($issues.Count -eq 0) {
    Write-Host "No prohibited characters found" -ForegroundColor Green
} else {
    Write-Host "Found $($issues.Count) issues:" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host "  - $_" }
}
```

### Tool 3: Code Standards Validator

```powershell
# Save as: scripts/Test-CodeStandards.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath
)

$content = Get-Content $ScriptPath -Raw
$issues = @()
$passes = @()

function Test-Standard {
    param([string]$Name, [bool]$Condition)
    if ($Condition) {
        $script:passes += $Name
        Write-Host "[PASS] $Name" -ForegroundColor Green
    } else {
        $script:issues += $Name
        Write-Host "[FAIL] $Name" -ForegroundColor Red
    }
}

# Run tests
Test-Standard "Has synopsis block" ($content -match "<#[\s\S]*\.SYNOPSIS")
Test-Standard "Has #Requires statement" ($content -match "#Requires -Version")
Test-Standard "No external references" ($content -notmatch "\. \\.\\")
Test-Standard "Uses Write-Host" ($content -match "Write-Host")
Test-Standard "No Write-Output" ($content -notmatch "Write-Output")
Test-Standard "Has error handling" ($content -match "try\s*{")
Test-Standard "Has exit codes" ($content -match "exit \d")

Write-Host "`nSummary: $($passes.Count) passed, $($issues.Count) failed"
```

---

## Risk Mitigation

### Risk: Breaking Changes

**Mitigation:**
- Comprehensive testing before deployment
- Pilot deployment to limited devices
- Maintain rollback capability
- Document all changes

**Rollback Procedure:**
```powershell
# Restore from backup
$backupPath = "C:\Backups\WAF\plaintext_scripts_backup"
Remove-Item "plaintext_scripts" -Recurse -Force
Copy-Item $backupPath "plaintext_scripts" -Recurse

# Revert Git changes
git checkout main -- plaintext_scripts/
```

### Risk: Field Mapping Changes

**Mitigation:**
- Document all field updates
- Update dashboards before deployment
- Test dashboard compatibility
- Create field migration guide

### Risk: Timeline Overrun

**Mitigation:**
- Build 20% buffer into schedule
- Prioritize critical scripts
- Add resources if needed
- Adjust scope if necessary

---

## Success Criteria

### Code Quality
- [ ] 100% of scripts follow naming convention
- [ ] 100% of scripts have complete headers
- [ ] 0 external script references
- [ ] 0 RSAT-only dependencies (except with feature checks)
- [ ] 0 emojis or checkmarks
- [ ] 100% use Write-Host
- [ ] 100% have error handling

### Testing
- [ ] >95% test success rate
- [ ] Tested on German and English Windows
- [ ] Tested on domain and workgroup
- [ ] No breaking changes in production

### Deployment
- [ ] <2% rollback rate
- [ ] >98% device success rate
- [ ] All dashboards working
- [ ] All alerts functioning

### Documentation
- [ ] All scripts documented
- [ ] Migration guide complete
- [ ] Training materials updated
- [ ] Lessons learned documented

---

## Daily Workflow

### Morning Routine (30 min)
1. Review overnight test results
2. Check GitHub issues
3. Update tracking spreadsheet
4. Plan day's work

### Development (6 hours)
1. Select next script(s)
2. Review current code
3. Apply standardization
4. Test locally
5. Commit changes

### End of Day (30 min)
1. Run validation tests
2. Update progress
3. Document issues
4. Push to Git

---

## Communication Plan

### Daily
- Update tracking spreadsheet
- Post progress in team chat

### Weekly
- Status email to stakeholders
- Team standup meeting
- Review and adjust plan

### Milestones
- Phase completion reports
- Deployment notifications
- Issue escalations

---

## Resource Links

### Documentation
- [Migration Plan](PLAINTEXT_SCRIPTS_MIGRATION_PLAN.md)
- [Script Inventory](PLAINTEXT_SCRIPTS_INVENTORY.md)
- [WAF Coding Standards](WAF_CODING_STANDARDS.md)
- [Deployment Guide](reference/DEPLOYMENT_GUIDE.md)

### Tools
- `scripts/Rename-PlaintextScripts.ps1`
- `scripts/Test-ScriptNaming.ps1`
- `scripts/Test-SpecialCharacters.ps1`
- `scripts/Test-CodeStandards.ps1`

### Tracking
- GitHub Project: [Script Standardization](https://github.com/Xore/waf/projects/X)
- Spreadsheet: `docs/tracking/progress.xlsx`
- Test Results: `docs/tracking/test_results.csv`

---

## Getting Started

### Today
```bash
# 1. Clone repository (if not already done)
git clone https://github.com/Xore/waf.git
cd waf

# 2. Create development branch
git checkout -b feature/script-standardization

# 3. Create backup
.\scripts\Backup-PlaintextScripts.ps1

# 4. Review documentation
code docs/PLAINTEXT_SCRIPTS_MIGRATION_PLAN.md
code docs/PLAINTEXT_SCRIPTS_INVENTORY.md
code docs/WAF_CODING_STANDARDS.md

# 5. Set up tracking
.\scripts\Initialize-Tracking.ps1
```

### This Week
1. Complete Phase 1 setup
2. Review all scripts
3. Resolve duplicates
4. Begin renaming

### Next Week
1. Complete renaming
2. Begin code standardization
3. Start with AD scripts

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Next Review:** Daily during execution  
**Owner:** WAF Team
