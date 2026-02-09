# Script Refactoring Guide - Windows Automation Framework

**Document Type:** Refactoring Guide  
**Audience:** Script Developers, Maintainers  
**Version:** 1.0  
**Last Updated:** February 9, 2026

---

## Purpose

This guide provides a systematic approach to refactoring existing WAF scripts to meet the [Coding Standards](CODING_STANDARDS.md). Follow this step-by-step process to improve script quality, reliability, and maintainability.

---

## When to Refactor

### Triggers for Refactoring

**Mandatory:**
- Script fails frequently (>5% failure rate)
- Script times out regularly (>5% timeout rate)
- Script has no error handling
- Script causes performance issues
- Script is being modified for new features

**Recommended:**
- Script lacks proper logging
- Script doesn't follow naming conventions
- Script has poor documentation
- Code review identifies issues
- Quarterly maintenance cycle

**Optional:**
- Improving code readability
- Standardizing across all scripts
- Applying new best practices

---

## Refactoring Process Overview

### 5-Phase Approach

```
Phase 1: Assessment (10 min)
   ↓
Phase 2: Backup & Setup (5 min)
   ↓
Phase 3: Apply Standards (30-60 min)
   ↓
Phase 4: Testing (20 min)
   ↓
Phase 5: Deployment (10 min)

Total Time: 75-105 minutes per script
```

---

## Phase 1: Assessment

### Step 1.1: Review Current Script

**Read through the entire script and document:**

```markdown
## Script Assessment - [ScriptName.ps1]

### Current Status
- Lines of code: XXX
- Functions: X
- Fields updated: X
- Has error handling: Yes/No
- Has logging: Yes/No
- Uses CIM or WMI: CIM/WMI/Mixed
- Execution time: XX seconds
- Failure rate: X%

### Issues Identified
- [ ] No comment-based help
- [ ] No error handling
- [ ] No structured logging
- [ ] Uses WMI instead of CIM
- [ ] Poor variable naming
- [ ] No input validation
- [ ] Hardcoded values
- [ ] Performance issues
- [ ] Other: [describe]

### Priority
- [ ] High - Fixes critical issues
- [ ] Medium - Improves reliability
- [ ] Low - Cosmetic improvements
```

### Step 1.2: Calculate Refactoring Effort

**Estimate time based on complexity:**

| Complexity | Characteristics | Time Estimate |
|------------|----------------|---------------|
| **Simple** | <100 lines, few functions, minimal logic | 30-45 min |
| **Medium** | 100-300 lines, several functions, moderate logic | 45-75 min |
| **Complex** | >300 lines, many functions, complex logic | 75-120 min |

### Step 1.3: Define Success Criteria

```markdown
## Success Criteria

- [ ] Follows coding standards 100%
- [ ] All critical operations have error handling
- [ ] Structured logging implemented
- [ ] Execution time < XX seconds
- [ ] Failure rate < 2%
- [ ] All tests pass
- [ ] Code review approved
```

---

## Phase 2: Backup & Setup

### Step 2.1: Create Backup

```powershell
# Backup original script
Copy-Item "ScriptName.ps1" "ScriptName.ps1.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
```

### Step 2.2: Create Working Branch

```bash
# In Git
git checkout -b refactor/script-name
git add .
git commit -m "[Refactor] Backup before refactoring ScriptName.ps1"
```

### Step 2.3: Set Up Testing Environment

```markdown
## Test Environment

### Test Systems
- [ ] Test VM 1: Windows 10 Pro
- [ ] Test VM 2: Windows 11 Enterprise
- [ ] Test VM 3: Windows Server 2022

### Test Scenarios
- [ ] Normal operation
- [ ] Missing data (e.g., no D: drive)
- [ ] WMI error simulation
- [ ] Timeout simulation
- [ ] Low resources simulation
```

---

## Phase 3: Apply Standards

### Step 3.1: Add Comment-Based Help (10 min)

**Replace or add proper header:**

```powershell
<#
.SYNOPSIS
    [Write clear one-line description]

.DESCRIPTION
    [Write detailed description including:
    - What data is collected
    - What calculations are performed
    - What fields are updated
    - Any important behavior notes]

.NOTES
    Script Name:    [ExactFileName.ps1]
    Author:         Windows Automation Framework
    Version:        [X.Y - increment appropriately]
    Creation Date:  [Original date]
    Last Modified:  [Today's date]
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: [Daily/Weekly/On-demand]
    Typical Duration: ~XX seconds
    Timeout Setting: XXX seconds
    
    Fields Updated:
        - [fieldName1] (description)
        - [fieldName2] (description)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - [Other dependencies]
    
    Exit Codes:
        0 - Success
        1 - General error
        2 - Missing dependencies
        3 - Permission denied
        4 - Timeout

.LINK
    https://github.com/Xore/waf
#>
```

**Checklist:**
- [ ] SYNOPSIS is clear and concise
- [ ] DESCRIPTION covers all functionality
- [ ] All updated fields are listed
- [ ] Dependencies are documented
- [ ] Exit codes are documented

---

### Step 3.2: Add CmdletBinding and Requires (5 min)

**Add after comment-based help:**

```powershell
[CmdletBinding()]
param(
    # Add parameters if needed
)

#Requires -Version 5.1
#Requires -RunAsAdministrator
```

---

### Step 3.3: Add Configuration Section (5 min)

**Standardize configuration:**

```powershell
# ============================================================================
# CONFIGURATION
# ============================================================================

# Script version
$ScriptVersion = "1.1"  # Increment from previous

# Logging configuration
$LogLevel = "INFO"
$VerbosePreference = 'SilentlyContinue'

# Timeouts and limits
$DefaultTimeout = 300
$MaxRetries = 3

# Script-specific configuration
$DiskSpaceThresholdPercent = 10
$MaxEventLogDays = 7
# etc.
```

**Move all hardcoded values here**

---

### Step 3.4: Add Initialization Section (5 min)

```powershell
# ============================================================================
# INITIALIZATION
# ============================================================================

# Start timing
$StartTime = Get-Date
$ScriptName = $MyInvocation.MyCommand.Name

# Initialize error tracking
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
```

---

### Step 3.5: Add Standard Functions (10 min)

**Add Write-Log function:**

```powershell
# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes structured log messages
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'DEBUG' { if ($LogLevel -eq 'DEBUG') { Write-Verbose $LogMessage } }
        'INFO'  { Write-Host $LogMessage -ForegroundColor Cyan }
        'WARN'  { Write-Warning $LogMessage; $script:WarningCount++ }
        'ERROR' { Write-Error $LogMessage; $script:ErrorCount++ }
    }
}
```

**Add Set-NinjaField function:**

```powershell
function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value with validation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    try {
        if ($null -eq $Value -or $Value -eq "") {
            Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
            return
        }
        
        Ninja-Property-Set $FieldName $Value
        Write-Log "Field '$FieldName' = $Value" -Level DEBUG
        
    } catch {
        Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
    }
}
```

**Add other utility functions as needed**

---

### Step 3.6: Wrap Main Logic in Try-Catch (15 min)

**Restructure main execution:**

```powershell
# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # [EXISTING SCRIPT LOGIC GOES HERE]
    # Add try-catch blocks around critical operations
    
    Write-Log "Script completed successfully" -Level INFO
    
} catch {
    Write-Log "Script execution failed: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    exit 1
    
} finally {
    # Calculate execution time
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    # Summary
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $ExecutionTime seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "========================================" -Level INFO
}

# Exit with appropriate code
if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
```

---

### Step 3.7: Add Error Handling to Critical Operations (15 min)

**Identify critical operations:**
- WMI/CIM queries
- File operations
- Registry access
- Service queries
- Event log queries

**Wrap each in try-catch:**

```powershell
# Before:
$OS = Get-CimInstance Win32_OperatingSystem
$FreeMemory = $OS.FreePhysicalMemory

# After:
try {
    $OS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $FreeMemory = $OS.FreePhysicalMemory
    Write-Log "Retrieved OS information" -Level DEBUG
    
} catch {
    Write-Log "Failed to get OS info: $_" -Level ERROR
    $FreeMemory = 0  # Graceful degradation
}
```

---

### Step 3.8: Replace Write-Host with Write-Log (10 min)

**Find and replace all output:**

```powershell
# Before:
Write-Host "Processing..."
Write-Host "Error: Something failed" -ForegroundColor Red

# After:
Write-Log "Processing..." -Level INFO
Write-Log "Something failed" -Level ERROR
```

**Search for:**
- `Write-Host`
- `Write-Output` (if used for logging)
- `Write-Warning` (keep, but ensure counted)
- `Write-Error` (keep, but ensure counted)

---

### Step 3.9: Replace Direct Field Setting (10 min)

**Find and replace all Ninja-Property-Set:**

```powershell
# Before:
Ninja-Property-Set "fieldName" $Value

# After:
Set-NinjaField -FieldName "fieldName" -Value $Value
```

**Use Find & Replace:**
- Find: `Ninja-Property-Set (["'])([^"']+)\1 (.+)`
- Replace: `Set-NinjaField -FieldName "$2" -Value $3`

---

### Step 3.10: Optimize Performance (15 min)

**Replace WMI with CIM:**

```powershell
# Before:
$Disks = Get-WmiObject Win32_LogicalDisk

# After:
$Disks = Get-CimInstance Win32_LogicalDisk
```

**Add filtering:**

```powershell
# Before:
$Events = Get-WinEvent -LogName System
$Errors = $Events | Where-Object { $_.Level -eq 2 }

# After:
$Errors = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Level = 2
    StartTime = (Get-Date).AddDays(-7)
} -MaxEvents 100
```

**Optimize loops:**

```powershell
# Before:
foreach ($Item in $Items) {
    $Threshold = Get-ConfigValue "Threshold"  # Called every iteration!
    if ($Item.Value -gt $Threshold) {
        Process-Item $Item
    }
}

# After:
$Threshold = Get-ConfigValue "Threshold"  # Called once
foreach ($Item in $Items) {
    if ($Item.Value -gt $Threshold) {
        Process-Item $Item
    }
}
```

---

### Step 3.11: Improve Variable Naming (10 min)

**Apply PascalCase and descriptive names:**

```powershell
# Before:
$comp = $env:COMPUTERNAME
$mem = Get-Memory
$pct = ($used / $total) * 100

# After:
$ComputerName = $env:COMPUTERNAME
$TotalMemoryGB = Get-TotalMemory
$UsedPercent = ($UsedSpace / $TotalSpace) * 100
```

**Use Find & Replace carefully:**
- Find: `\$comp\b`
- Replace: `$ComputerName`

---

### Step 3.12: Add Code Comments (5 min)

**Add comments for complex logic:**

```powershell
# Calculate free space percentage
# Note: CIM returns bytes, so divide by 1GB for readability
$FreeSpaceGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
$TotalSpaceGB = [math]::Round($Disk.Size / 1GB, 2)
$FreePercent = [math]::Round(($FreeSpaceGB / $TotalSpaceGB) * 100, 1)

# Skip system reserved partitions (< 100MB)
if ($TotalSpaceGB -lt 0.1) {
    Write-Log "Skipping small partition: $($Disk.DeviceID)" -Level DEBUG
    continue
}
```

---

## Phase 4: Testing

### Step 4.1: Syntax Validation (2 min)

```powershell
# Check syntax
$Errors = $null
$null = [System.Management.Automation.PSParser]::Tokenize(
    (Get-Content "ScriptName.ps1" -Raw), 
    [ref]$Errors
)

if ($Errors) {
    Write-Host "Syntax errors found:" -ForegroundColor Red
    $Errors | Format-Table -AutoSize
} else {
    Write-Host "Syntax valid" -ForegroundColor Green
}
```

### Step 4.2: Dry Run Test (5 min)

```powershell
# Test execution (use -WhatIf if supported)
.\ScriptName.ps1 -Verbose

# Check:
# - No errors thrown
# - Logging works
# - Execution time acceptable
# - Output looks correct
```

### Step 4.3: Field Population Test (5 min)

```powershell
# After running script, check NinjaRMM
# Verify all expected fields are populated

# Check fields in NinjaRMM:
# - Field values are correct
# - Data types are appropriate
# - No "N/A" where data should exist
```

### Step 4.4: Error Scenario Testing (5 min)

**Test error handling:**

```powershell
# Simulate WMI failure
Rename-Service "WinMgmt" "WinMgmt.disabled"
.\ScriptName.ps1
Rename-Service "WinMgmt.disabled" "WinMgmt"

# Check:
# - Script doesn't crash
# - Error logged appropriately
# - Graceful degradation works
```

### Step 4.5: Performance Test (3 min)

```powershell
# Time the execution
Measure-Command { .\ScriptName.ps1 }

# Should be:
# - Within timeout limit
# - Similar or faster than original
# - No significant resource spikes
```

---

## Phase 5: Deployment

### Step 5.1: Code Review (10 min)

**Self-review checklist:**

```markdown
### Code Review Checklist

#### Structure
- [ ] Uses standard template format
- [ ] Comment-based help complete
- [ ] All sections present
- [ ] Logical flow maintained

#### Standards Compliance
- [ ] Naming conventions followed
- [ ] Error handling on all critical ops
- [ ] Structured logging throughout
- [ ] No direct Ninja-Property-Set calls
- [ ] CIM used instead of WMI

#### Quality
- [ ] Code is readable
- [ ] Complex logic is commented
- [ ] No hardcoded values
- [ ] Performance optimized

#### Testing
- [ ] All tests passed
- [ ] Fields populate correctly
- [ ] Error handling verified
- [ ] Performance acceptable
```

### Step 5.2: Update Version History (2 min)

**Document changes:**

```powershell
<#
.NOTES
    Version History:
    1.0 - 2025-01-15 - Initial version
    1.1 - 2026-02-09 - Refactored to meet coding standards:
                       - Added structured logging
                       - Added comprehensive error handling
                       - Improved performance (WMI -> CIM)
                       - Improved variable naming
                       - Added execution summary
#>
```

### Step 5.3: Commit Changes (3 min)

```bash
git add ScriptName.ps1
git commit -m "[Refactor] ScriptName.ps1 - Apply coding standards

Changes:
- Added comment-based help
- Implemented structured logging
- Added comprehensive error handling
- Replaced WMI with CIM queries
- Improved variable naming (PascalCase)
- Added execution timing and summary
- Optimized performance

Testing:
- Tested on Windows 10, 11, Server 2022
- All fields populate correctly
- Error handling verified
- Execution time: 15s (was 23s)
- No failures in 10 test runs

Fields affected:
- fieldName1
- fieldName2"

git push origin refactor/script-name
```

### Step 5.4: Pilot Deployment (5 min)

```markdown
## Pilot Deployment Plan

### Phase 1: 3 Pilot Devices
- Device 1: Windows 10 workstation
- Device 2: Windows 11 workstation  
- Device 3: Windows Server 2022
- Duration: 48 hours
- Monitor: Execution success, field updates, errors

### Phase 2: 10% of Fleet
- 15 devices (10% of 150)
- Duration: 1 week
- Monitor: Same as Phase 1

### Phase 3: Full Deployment
- All 150 devices
- Duration: Ongoing
- Monitor: Weekly performance reviews
```

---

## Refactoring Checklist Template

```markdown
# Refactoring Checklist - [ScriptName.ps1]

**Date Started:** YYYY-MM-DD  
**Target Completion:** YYYY-MM-DD  
**Developer:** [Name]

## Phase 1: Assessment
- [ ] Script reviewed
- [ ] Issues documented
- [ ] Effort estimated: XX minutes
- [ ] Success criteria defined

## Phase 2: Backup & Setup
- [ ] Backup created
- [ ] Git branch created
- [ ] Test environment ready

## Phase 3: Apply Standards
- [ ] Comment-based help added
- [ ] CmdletBinding added
- [ ] Configuration section added
- [ ] Initialization section added
- [ ] Write-Log function added
- [ ] Set-NinjaField function added
- [ ] Main logic wrapped in try-catch
- [ ] Error handling on critical operations
- [ ] Write-Host replaced with Write-Log
- [ ] Direct field setting replaced
- [ ] Performance optimized
- [ ] Variable naming improved
- [ ] Code comments added

## Phase 4: Testing
- [ ] Syntax validated
- [ ] Dry run test passed
- [ ] Field population verified
- [ ] Error scenarios tested
- [ ] Performance acceptable

## Phase 5: Deployment
- [ ] Code review completed
- [ ] Version history updated
- [ ] Changes committed
- [ ] Pilot deployment plan created
- [ ] Pilot deployed successfully
- [ ] Full deployment completed

## Results
- **Execution Time:** Before: XXs | After: XXs
- **Failure Rate:** Before: X% | After: X%
- **Lines of Code:** Before: XXX | After: XXX
- **Standards Compliance:** X%

## Notes
[Any issues, lessons learned, or recommendations]
```

---

## Common Refactoring Patterns

### Pattern 1: WMI to CIM

```powershell
# Before
$OS = Get-WmiObject Win32_OperatingSystem
$Services = Get-WmiObject Win32_Service

# After
$OS = Get-CimInstance Win32_OperatingSystem
$Services = Get-CimInstance Win32_Service
```

### Pattern 2: Add Logging

```powershell
# Before
$Value = Get-Something

# After
Write-Log "Retrieving something..." -Level INFO
try {
    $Value = Get-Something
    Write-Log "Retrieved: $Value" -Level DEBUG
} catch {
    Write-Log "Failed to retrieve: $_" -Level ERROR
    $Value = "N/A"
}
```

### Pattern 3: Error Handling

```powershell
# Before
$Service = Get-Service "ServiceName"
if ($Service.Status -eq "Running") {
    $Status = "OK"
}

# After
try {
    $Service = Get-Service "ServiceName" -ErrorAction Stop
    $Status = if ($Service.Status -eq "Running") { "OK" } else { "Stopped" }
    Write-Log "Service status: $Status" -Level DEBUG
} catch {
    Write-Log "Service not found: $_" -Level WARN
    $Status = "Not Found"
}
```

### Pattern 4: Field Setting

```powershell
# Before
if ($Value) {
    Ninja-Property-Set "fieldName" $Value
}

# After
Set-NinjaField -FieldName "fieldName" -Value $Value
```

---

## Troubleshooting Refactoring Issues

### Issue: Script slower after refactoring

**Check:**
- Is logging level set to DEBUG? (Change to INFO)
- Are you calling functions inside loops unnecessarily?
- Did you add synchronous operations that could be parallel?

### Issue: Fields not populating

**Check:**
- Is Set-NinjaField function working correctly?
- Are values null or empty (function skips these)?
- Check NinjaRMM field names match exactly

### Issue: Errors not being caught

**Check:**
- Is `$ErrorActionPreference = 'Stop'` set?
- Are you using `-ErrorAction Stop` on cmdlets?
- Is the try-catch block wrapping the right code?

### Issue: Script fails on certain systems

**Check:**
- Are prerequisites validated?
- Is error handling graceful?
- Are you handling missing features (e.g., no TPM)?

---

## Batch Refactoring

### Refactoring Multiple Scripts

**Process:**

1. **Prioritize scripts:**
   - High failure rate first
   - High execution frequency second
   - Critical functionality third

2. **Group by similarity:**
   - Disk monitoring scripts
   - Security monitoring scripts
   - Performance scripts
   - etc.

3. **Refactor in batches:**
   - 5 scripts per week
   - Test thoroughly between batches
   - Learn from each refactoring

4. **Track progress:**
   ```markdown
   ## Refactoring Progress
   
   - [ ] Phase 7.1 Scripts (50 scripts)
     - [x] Disk monitoring (5 scripts) - Week 1
     - [x] Memory monitoring (3 scripts) - Week 1
     - [ ] Security monitoring (8 scripts) - Week 2
     - [ ] Performance monitoring (10 scripts) - Week 3
     - [ ] Update monitoring (6 scripts) - Week 4
     - [ ] Miscellaneous (18 scripts) - Week 5-6
   
   - [ ] Phase 7.2 Scripts (40 scripts) - Week 7-12
   - [ ] Phase 7.3 Scripts (20 scripts) - Week 13-16
   ```

---

## Summary

**Key Steps:**

1. **Assess** - Understand current state and effort required
2. **Backup** - Never lose working code
3. **Apply** - Follow standards systematically
4. **Test** - Verify everything works
5. **Deploy** - Roll out carefully with monitoring

**Time Investment:**
- Simple script: 30-45 minutes
- Medium script: 45-75 minutes
- Complex script: 75-120 minutes

**Benefits:**
- Improved reliability
- Better maintainability
- Consistent code quality
- Easier troubleshooting
- Better performance

**Remember:**
- Don't rush - quality over speed
- Test thoroughly - avoid breaking production
- Document changes - help future maintainers
- Learn from each refactoring - improve the process

---

## Related Documents

- [Coding Standards](CODING_STANDARDS.md) - Standards to follow
- [Script Header Template](SCRIPT_HEADER_TEMPLATE.ps1) - Template to use
- [Troubleshooting Flowcharts](../troubleshooting/FLOWCHARTS.md) - Debug issues

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Next Review:** After first 10 script refactorings completed
