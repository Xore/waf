# Standards Compliance Action Plan

## Overview

Systematic verification and refactoring of all 219+ scripts in `plaintext_scripts/` to ensure compliance with WAF coding standards defined in `docs/standards/`.

## Action Plan Status

**Created:** February 9, 2026, 11:07 PM CET  
**Status:** PENDING - Awaiting Execution  
**Priority:** HIGH  
**Estimated Effort:** 20-40 hours (depending on non-compliance rate)

---

## Standards Documents Reference

All scripts must comply with:

1. **[CODING_STANDARDS.md](../../docs/standards/CODING_STANDARDS.md)** (v1.4)
   - File naming schema
   - Execution time tracking
   - Dual-method field setting
   - Unattended operation
   - Module dependency auto-installation

2. **[OUTPUT_FORMATTING.md](../../docs/standards/OUTPUT_FORMATTING.md)** (v1.0)
   - No emojis or Unicode symbols
   - No colors (-ForegroundColor/-BackgroundColor)
   - No Write-Progress
   - Plain ASCII text only
   - Use Write-Log function

3. **[LANGUAGE_AWARE_PATHS.md](../../docs/standards/LANGUAGE_AWARE_PATHS.md)** (v1.0)
   - Support German and English Windows
   - Use Get-LocalizedPath function
   - Never hardcode language-specific paths
   - Prefer environment variables

4. **[SCRIPT_HEADER_TEMPLATE.ps1](../../docs/standards/SCRIPT_HEADER_TEMPLATE.ps1)**
   - Standard script structure
   - Comment-based help
   - Required functions

5. **[SCRIPT_REFACTORING_GUIDE.md](../../docs/standards/SCRIPT_REFACTORING_GUIDE.md)**
   - Step-by-step refactoring process
   - Common patterns and fixes

---

## Compliance Verification Checklist

### Phase 1: Critical Standards (MUST FIX)

These violations break functionality or cause issues in production:

#### 1.1 Output Formatting (OUTPUT_FORMATTING.md)
- [ ] **No emojis** (✓, ✗, ⚠, 🔴, 🟢, etc.)
- [ ] **No Unicode symbols** (→, •, ■, ►, ◆, etc.)
- [ ] **No Write-Host with colors** (-ForegroundColor, -BackgroundColor)
- [ ] **No Write-Progress** in long-running operations
- [ ] **Plain ASCII text only** in all output
- [ ] Use words not symbols ("Success" not "✓")

**Why Critical:** NinjaRMM console corrupts UTF-8, logs become unreadable, SIEM tools fail to parse.

#### 1.2 Unattended Operation (CODING_STANDARDS.md)
- [ ] **No Read-Host** calls
- [ ] **No Pause** commands
- [ ] **No confirmations** without `-Confirm:$false`
- [ ] **No unexpected restarts** (must check -AllowRestart parameter)
- [ ] **No user interaction** of any kind

**Why Critical:** Scripts run as SYSTEM in RMM context, no user to respond, scripts hang indefinitely.

#### 1.3 Field Setting (CODING_STANDARDS.md)
- [ ] **Use Set-NinjaField wrapper** (never direct Ninja-Property-Set)
- [ ] **Include CLI fallback** for when NinjaOne module unavailable
- [ ] **Handle field setting failures** gracefully

**Why Critical:** Scripts fail silently when NinjaOne module missing, no data collected.

### Phase 2: Important Standards (SHOULD FIX)

These improve reliability, maintainability, and cross-language support:

#### 2.1 Execution Time Tracking (CODING_STANDARDS.md)
- [ ] **$StartTime captured** at script initialization
- [ ] **Execution time logged** in finally block
- [ ] **Format:** "Script execution completed in X.XX seconds"

**Why Important:** Performance monitoring, timeout debugging, optimization identification.

#### 2.2 Language-Aware Paths (LANGUAGE_AWARE_PATHS.md)
- [ ] **No hardcoded German paths** ("Schreibtisch", "Dokumente")
- [ ] **No hardcoded English paths** ("Desktop", "Documents")
- [ ] **Use Get-LocalizedPath function** for user folders
- [ ] **Prefer environment variables** ($env:APPDATA, $env:ProgramFiles)
- [ ] **Test on both languages** if paths are accessed

**Why Important:** Scripts fail on opposite language Windows, 50% of deployment fails.

#### 2.3 Module Dependencies (CODING_STANDARDS.md)
- [ ] **Auto-install required modules** (NuGet, PowerShellGet)
- [ ] **Check module availability** before use
- [ ] **Graceful degradation** if module unavailable
- [ ] **Log module installation** attempts

**Why Important:** Scripts fail immediately on fresh systems, require manual intervention.

### Phase 3: Recommended Standards (NICE TO HAVE)

These improve code quality and consistency:

#### 3.1 Comment-Based Help
- [ ] .SYNOPSIS section
- [ ] .DESCRIPTION section
- [ ] .PARAMETER sections (if parameters exist)
- [ ] .EXAMPLE section
- [ ] .NOTES section

#### 3.2 Error Handling
- [ ] Try-catch blocks around critical operations
- [ ] Meaningful error messages
- [ ] Proper exit codes (0 = success, 1 = failure)
- [ ] Log errors with context

#### 3.3 Code Structure
- [ ] Variables use PascalCase
- [ ] Functions use approved verbs (Get-, Set-, Test-, etc.)
- [ ] Consistent indentation (4 spaces)
- [ ] No trailing whitespace

---

## Execution Strategy

### Approach: Batch Processing by Category

Process scripts by functional category to leverage similar patterns.

### Priority Order

1. **High-Frequency Scripts** (run every 4 hours or more often)
   - Monitoring, telemetry, security analyzers
   - Impact: Immediate, affects all devices

2. **Critical Business Scripts** (security, compliance, backups)
   - Security posture, BitLocker, antivirus, Veeam
   - Impact: High, affects compliance and security

3. **User-Facing Scripts** (notifications, shortcuts, software installs)
   - User experience, application deployment
   - Impact: Medium, affects end-user satisfaction

4. **Maintenance Scripts** (cleanup, optimization, repairs)
   - System maintenance, troubleshooting
   - Impact: Low, run on-demand or infrequently

### Batch Processing

**Per Category:**
1. Scan all scripts in category for violations
2. Identify common patterns
3. Create category-specific refactoring template
4. Refactor scripts in batch
5. Test refactored scripts
6. Commit batch with detailed message

---

## Implementation Steps

### Step 1: Automated Scanning (2-4 hours)

Create PowerShell script to scan all scripts for common violations:

```powershell
# Script: Scan-StandardsCompliance.ps1
# Checks all scripts for common violations
# Outputs: CSV report with findings
```

**Violations to Detect:**
- Emojis and Unicode symbols (regex pattern matching)
- Write-Host with -ForegroundColor/-BackgroundColor
- Write-Progress usage
- Read-Host or Pause commands
- Hardcoded German/English paths
- Missing $StartTime or execution time logging
- Direct Ninja-Property-Set calls (no wrapper)
- Restart-Computer without -AllowRestart check

**Output Format:**
```csv
Script,Category,Violation,Line,Severity,AutoFixable
AD-JoinDomain.ps1,AD,No execution time tracking,N/A,Important,Yes
Cepros-FixCdbpcIniPermissions.ps1,Cepros,No comment-based help,N/A,Recommended,Yes
```

### Step 2: Manual Review (4-8 hours)

Review scan results and categorize scripts:

- **Green:** Fully compliant (no changes needed)
- **Yellow:** Minor violations (1-2 issues, quick fixes)
- **Orange:** Moderate violations (3-5 issues, requires attention)
- **Red:** Major violations (6+ issues, significant refactoring)

### Step 3: Batch Refactoring (10-20 hours)

Refactor scripts in batches by severity:

**Red Scripts First:**
- Complete refactoring using SCRIPT_REFACTORING_GUIDE.md
- May require architectural changes
- Test thoroughly after changes

**Orange Scripts Second:**
- Targeted fixes for specific violations
- Add missing functions (Write-Log, Set-NinjaField)
- Update paths to be language-aware

**Yellow Scripts Third:**
- Quick fixes (add execution time tracking, remove emojis)
- Minimal testing required

### Step 4: Testing & Validation (4-8 hours)

**Test Each Refactored Script:**
- Run on English Windows
- Run on German Windows (if paths accessed)
- Verify no user interaction prompts
- Verify execution time logged
- Verify fields populate correctly
- Verify output is plain text
- Check exit codes

**Test Environments:**
- Windows 10/11 English (primary)
- Windows 10/11 German (if path-dependent)
- Windows Server 2019/2022 (if server script)

### Step 5: Documentation (2-4 hours)

**Update Documentation:**
- Add compliance status to MIGRATION_PROGRESS.md
- Create STANDARDS_COMPLIANCE_REPORT.md with findings
- Update README.md with compliance rate
- Document any exceptions or deviations

---

## Script Categories (Priority Order)

### Priority 1: High-Frequency Monitoring (Every 4 hours)

**Category** | **Scripts** | **Frequency** | **Estimated Effort**
--- | --- | --- | ---
Monitoring | 7 scripts | Every 4 hours | 3-5 hours
Security | 16 scripts | Daily/Every 4h | 6-10 hours
Network | 16 scripts | Every 4 hours | 6-10 hours

**Total:** 39 scripts, 15-25 hours

### Priority 2: Critical Business Functions

**Category** | **Scripts** | **Importance** | **Estimated Effort**
--- | --- | --- | ---
AD | 14 scripts | Critical | 5-8 hours
Server | 1 script | Critical | 0.5-1 hour
Veeam | 1 script | Critical | 0.5-1 hour
SQL | 2 scripts | Critical | 1-2 hours
HyperV | 3 scripts | Critical | 1-3 hours

**Total:** 21 scripts, 8-15 hours

### Priority 3: User-Facing Operations

**Category** | **Scripts** | **Impact** | **Estimated Effort**
--- | --- | --- | ---
Software | 23 scripts | Medium | 8-12 hours
Shortcuts | 5 scripts | Low | 2-3 hours
Notifications | 1 script | Medium | 0.5-1 hour
OneDrive | 2 scripts | Medium | 1-2 hours

**Total:** 31 scripts, 11.5-18 hours

### Priority 4: Maintenance & Utilities

**Category** | **Scripts** | **Impact** | **Estimated Effort**
--- | --- | --- | ---
FileOps | 5 scripts | Low | 2-3 hours
System | 9 scripts | Low | 3-5 hours
Printing | 1 script | Low | 0.5-1 hour
Process | 2 scripts | Low | 1-2 hours
Services | 2 scripts | Low | 1-2 hours

**Total:** 19 scripts, 7.5-13 hours

### All Other Categories

**Remaining:** ~109 scripts across 25+ categories  
**Estimated Effort:** 30-50 hours

---

## Common Refactoring Patterns

### Pattern 1: Remove Emojis and Symbols

**Before:**
```powershell
Write-Host "✓ Success: Operation completed" -ForegroundColor Green
Write-Host "✗ Failed: Error occurred" -ForegroundColor Red
Write-Host "⚠ Warning: Check configuration" -ForegroundColor Yellow
```

**After:**
```powershell
Write-Log "SUCCESS: Operation completed" -Level INFO
Write-Log "ERROR: Failed - Error occurred" -Level ERROR
Write-Log "WARNING: Check configuration" -Level WARN
```

### Pattern 2: Add Execution Time Tracking

**Before:**
```powershell
try {
    # Script logic
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
```

**After:**
```powershell
$StartTime = Get-Date

try {
    # Script logic
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" -Level ERROR
    exit 1
}
finally {
    $Duration = (Get-Date) - $StartTime
    Write-Log "Script execution completed in $($Duration.TotalSeconds.ToString('F2')) seconds" -Level INFO
}
```

### Pattern 3: Replace Direct Field Setting

**Before:**
```powershell
Ninja-Property-Set myfield $value
```

**After:**
```powershell
Set-NinjaField -FieldName "myfield" -Value $value

# Include function definition:
function Set-NinjaField {
    param(
        [string]$FieldName,
        [string]$Value
    )
    
    try {
        # Try NinjaOne module
        Ninja-Property-Set $FieldName $Value
        Write-Log "Field '$FieldName' set via NinjaOne module" -Level DEBUG
    }
    catch {
        # Fallback to CLI
        $ninjaCli = "C:\Program Files\NinjaRMMAgent\programdata\ninjarmm-cli.exe"
        if (Test-Path $ninjaCli) {
            & $ninjaCli set $FieldName $Value
            Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
        }
        else {
            Write-Log "ERROR: Failed to set field '$FieldName'" -Level ERROR
        }
    }
}
```

### Pattern 4: Make Paths Language-Aware

**Before:**
```powershell
$DesktopPath = "C:\Users\$env:USERNAME\Desktop"
$DocumentsPath = "C:\Users\$env:USERNAME\Documents"
```

**After:**
```powershell
function Get-LocalizedPath {
    param([ValidateSet('Desktop', 'Documents', 'AppData')][string]$FolderType)
    
    switch ($FolderType) {
        'Desktop' {
            $Paths = @(
                "$env:USERPROFILE\Desktop",
                "$env:USERPROFILE\Schreibtisch"
            )
        }
        'Documents' {
            $Paths = @(
                "$env:USERPROFILE\Documents",
                "$env:USERPROFILE\Dokumente"
            )
        }
    }
    
    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            return $Path
        }
    }
}

$DesktopPath = Get-LocalizedPath -FolderType 'Desktop'
$DocumentsPath = Get-LocalizedPath -FolderType 'Documents'
```

### Pattern 5: Remove User Interaction

**Before:**
```powershell
$choice = Read-Host "Do you want to continue? (Y/N)"
if ($choice -ne 'Y') { exit }

Pause

Restart-Computer
```

**After:**
```powershell
param(
    [switch]$AllowRestart
)

# No Read-Host - script runs unattended
# No Pause - continues automatically

if ($AllowRestart) {
    Write-Log "Restarting computer as requested" -Level INFO
    Restart-Computer -Force
}
else {
    Write-Log "Restart required but not allowed (use -AllowRestart parameter)" -Level WARN
}
```

---

## Success Criteria

### Quantitative Metrics

- **100%** of scripts pass output formatting checks (no emojis/symbols/colors)
- **100%** of scripts operate unattended (no user interaction)
- **95%+** of scripts use Set-NinjaField wrapper
- **95%+** of scripts track execution time
- **90%+** of path-dependent scripts support both languages
- **80%+** of scripts have comment-based help

### Qualitative Indicators

- All scripts execute in NinjaRMM without hanging
- Logs are readable in plain text (no corrupted characters)
- Scripts work on both German and English Windows
- Field population is reliable and logged
- Performance baselines established (execution times)

---

## Tracking & Reporting

### Daily Progress Log

Track progress in `STANDARDS_COMPLIANCE_PROGRESS.md`:

```markdown
## February 10, 2026

**Scripts Reviewed:** 25
**Scripts Refactored:** 15
**Scripts Compliant:** 10 (already compliant)
**Total Compliant:** 25/219 (11.4%)

**Categories Completed:**
- AD: 14/14 (100%)
- Browser: 1/1 (100%)

**Issues Found:**
- Emojis: 8 scripts
- Missing execution time: 12 scripts
- Hardcoded paths: 3 scripts
```

### Weekly Summary Report

Generate weekly summary showing:
- Scripts refactored this week
- Categories completed
- Compliance rate trend
- Remaining effort estimate
- Blockers or issues

---

## Rollout Plan

### Week 1: High-Frequency Monitoring (39 scripts)
- Day 1-2: Scan and analyze
- Day 3-4: Refactor and test
- Day 5: Deploy to test group
- Day 6-7: Monitor and fix issues

### Week 2: Critical Business Functions (21 scripts)
- Day 1-2: Refactor AD and Server scripts
- Day 3: Refactor backup and database scripts
- Day 4: Test thoroughly
- Day 5: Deploy to production

### Week 3: User-Facing Operations (31 scripts)
- Day 1-2: Refactor software and shortcuts
- Day 3: Test on both German and English
- Day 4: Deploy gradually
- Day 5: User feedback collection

### Week 4: Maintenance & Utilities (19 scripts)
- Day 1-2: Refactor file ops and system scripts
- Day 3: Test and deploy
- Day 4-5: Documentation updates

### Weeks 5-8: Remaining Scripts (109 scripts)
- Process remaining categories
- Address edge cases
- Complete documentation
- Final compliance audit

---

## Risk Mitigation

### Potential Risks

1. **Breaking Changes**
   - Mitigation: Test thoroughly, deploy to test group first
   - Rollback: Keep original scripts in git history

2. **Time Overrun**
   - Mitigation: Focus on critical violations first
   - Acceptance: Some "nice to have" standards may be deferred

3. **Script Functionality Changes**
   - Mitigation: Document all changes, get peer review
   - Testing: Comprehensive testing before production

4. **Language Path Issues**
   - Mitigation: Test on both German and English Windows
   - Fallback: Use environment variables as primary method

### Rollback Procedure

If refactored script causes issues:

1. Identify problematic script via logs
2. Revert to previous commit (git history)
3. Document issue for future refactoring
4. Deploy reverted version immediately
5. Investigate root cause before re-attempting

---

## Next Actions

### Immediate (Next Session)

1. Create automated scanning script (Scan-StandardsCompliance.ps1)
2. Run scan against all 219+ scripts
3. Generate compliance report CSV
4. Prioritize scripts by violation severity
5. Begin refactoring highest-priority scripts

### This Week

- Complete automated scanning
- Start with high-frequency monitoring scripts
- Refactor 20-30 scripts
- Create compliance progress tracking document

### This Month

- Complete all critical and important violations
- Achieve 80%+ compliance on critical standards
- Deploy refactored scripts to production
- Update all documentation

---

## Resources Required

- **Developer Time:** 40-60 hours total
- **Test Environments:**
  - Windows 10/11 English
  - Windows 10/11 German
  - Windows Server 2019/2022
- **Test Devices:** 5-10 devices in test group
- **Tools:**
  - PowerShell ISE or VS Code
  - Git for version control
  - NinjaRMM test organization

---

## Related Documents

- [README.md](README.md) - Script repository overview
- [SCRIPT_INDEX.md](SCRIPT_INDEX.md) - Complete script catalog
- [MIGRATION_PROGRESS.md](MIGRATION_PROGRESS.md) - Migration tracking
- [BATCH_TO_POWERSHELL_CONVERSION.md](BATCH_TO_POWERSHELL_CONVERSION.md) - Conversion log
- [docs/standards/README.md](../../docs/standards/README.md) - Standards overview
- [docs/standards/CODING_STANDARDS.md](../../docs/standards/CODING_STANDARDS.md) - Coding standards
- [docs/standards/OUTPUT_FORMATTING.md](../../docs/standards/OUTPUT_FORMATTING.md) - Output standards
- [docs/standards/LANGUAGE_AWARE_PATHS.md](../../docs/standards/LANGUAGE_AWARE_PATHS.md) - Path handling
- [docs/standards/SCRIPT_REFACTORING_GUIDE.md](../../docs/standards/SCRIPT_REFACTORING_GUIDE.md) - Refactoring guide

---

**Document Version:** 1.0  
**Created:** February 9, 2026, 11:07 PM CET  
**Status:** Action Plan Approved - Awaiting Execution  
**Repository:** [Xore/waf](https://github.com/Xore/waf)  
**Maintained by:** WAF Team
