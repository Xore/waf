# Script Refactoring Guide - Windows Automation Framework

**Document Type:** Refactoring Guide  
**Audience:** Script Developers, Maintainers  
**Version:** 1.2  
**Last Updated:** February 9, 2026

---

## Purpose

This guide provides a systematic approach to refactoring existing WAF scripts to meet the [Coding Standards](CODING_STANDARDS.md). Follow this step-by-step process to improve script quality, reliability, and maintainability.

---

## Critical Requirements

**ALL refactored scripts MUST include:**

1. ✅ **Execution Time Tracking** - `$StartTime` in initialization, logged in finally block
2. ✅ **Set-NinjaField with CLI Fallback** - Never call `Ninja-Property-Set` directly
3. ✅ **No User Interaction** - Never use Read-Host, Pause, or interactive prompts
4. ✅ **No Restarts Without Parameter** - Require explicit `-AllowRestart` parameter
5. ✅ **Structured Logging** - Write-Log function with levels
6. ✅ **Error Handling** - Try-catch on all critical operations

---

## When to Refactor

### Triggers for Refactoring

**Mandatory:**
- Script fails frequently (>5% failure rate)
- Script times out regularly (>5% timeout rate)
- Script has no error handling
- Script causes performance issues
- Script is being modified for new features
- **Script doesn't track execution time**
- **Script calls Ninja-Property-Set directly**
- **Script uses Read-Host or waits for user input**
- **Script restarts device without parameter check**

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
- Execution time tracked: Yes/No (CRITICAL)
- Uses Set-NinjaField: Yes/No (CRITICAL)
- Has user input commands: Yes/No (CRITICAL)
- Restarts device: Yes/No (needs parameter check)
- Execution time: XX seconds
- Failure rate: X%

### Critical Issues (Must Fix)
- [ ] No execution time tracking
- [ ] Calls Ninja-Property-Set directly
- [ ] Uses Read-Host or Pause commands
- [ ] Restarts device without parameter
- [ ] No error handling
- [ ] No structured logging

### Other Issues
- [ ] No comment-based help
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

### Critical (Must Have)
- [ ] Execution time tracked and logged
- [ ] Set-NinjaField with CLI fallback implemented
- [ ] No direct Ninja-Property-Set calls
- [ ] No user input commands (Read-Host, Pause, etc.)
- [ ] Restarts require -AllowRestart parameter
- [ ] All critical operations have error handling
- [ ] Structured logging implemented

### Standard
- [ ] Follows coding standards 100%
- [ ] Execution time < XX seconds
- [ ] Failure rate < 2%
- [ ] All tests pass
- [ ] Code review approved
- [ ] Runs unattended without hanging
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
- [ ] Field setting methods (both Ninja-Property-Set and CLI)
- [ ] Unattended execution (no hang)
- [ ] Restart parameter behavior
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
    
    This script runs unattended without user interaction.

.PARAMETER AllowRestart
    (If applicable) Authorizes the script to restart the device if required.
    Without this parameter, script will only flag restart requirement.

.NOTES
    Script Name:    [ExactFileName.ps1]
    Author:         Windows Automation Framework
    Version:        [X.Y - increment appropriately]
    Creation Date:  [Original date]
    Last Modified:  [Today's date]
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: [Daily/Weekly/On-demand]
    Typical Duration: ~XX seconds (REQUIRED - from actual measurements)
    Timeout Setting: XXX seconds
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: Never restarts unless -AllowRestart parameter provided
    
    Fields Updated:
        - [fieldName1] (description)
        - [fieldName2] (description)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - [Other dependencies]
    
    Exit Codes:
        0 - Success
        1 - General error
        2 - Missing prerequisites
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
- [ ] **Typical Duration documented from testing**
- [ ] **User Interaction: NONE documented**
- [ ] **Restart Behavior documented**
- [ ] Exit codes are documented

---

### Step 3.2: Add CmdletBinding and Requires (5 min)

**Add after comment-based help:**

```powershell
[CmdletBinding()]
param(
    # Add parameters if needed
    
    # If script may need to restart device, add this parameter:
    # [Parameter(Mandatory=$false)]
    # [switch]$AllowRestart
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

# NinjaRMM CLI path (REQUIRED for fallback)
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# Script-specific configuration
$DiskSpaceThresholdPercent = 10
$MaxEventLogDays = 7
# etc.
```

**Move all hardcoded values here**

---

### Step 3.4: Add Initialization Section (5 min)

**CRITICAL: Must include $StartTime**

```powershell
# ============================================================================
# INITIALIZATION
# ============================================================================

# Start timing - REQUIRED FOR ALL SCRIPTS
$StartTime = Get-Date
$ScriptName = $MyInvocation.MyCommand.Name

# Initialize error tracking
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0  # Track CLI usage
```

---

### Step 3.5: Add Standard Functions (15 min)

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
        'ERROR' { Write-Error $LogMessage -ErrorAction Continue; $script:ErrorCount++ }
    }
}
```

**Add Set-NinjaField function - CRITICAL:**

```powershell
function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value with automatic fallback to CLI
    
    .DESCRIPTION
        Attempts to set a NinjaRMM custom field using the Ninja-Property-Set cmdlet.
        If the cmdlet fails, automatically falls back to using ninjarmm-cli.exe.
        
        This dual approach ensures field setting works in all execution contexts.
    
    .PARAMETER FieldName
        The name of the custom field to set (case-sensitive)
    
    .PARAMETER Value
        The value to set for the field. Null or empty values are skipped.
    
    .EXAMPLE
        Set-NinjaField -FieldName "opsHealthScore" -Value 85
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    # Skip null or empty values
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    # Convert value to string
    $ValueString = $Value.ToString()
    
    # Method 1: Try Ninja-Property-Set cmdlet (primary)
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' = $ValueString" -Level DEBUG
            return
        } else {
            throw "Ninja-Property-Set cmdlet not available"
        }
    } catch {
        Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
        
        # Method 2: Fall back to NinjaRMM CLI
        try {
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            # Execute: ninjarmm-cli.exe set <field-name> <value>
            $CLIArgs = @("set", $FieldName, $ValueString)
            $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "CLI exit code: $LASTEXITCODE, Output: $CLIResult"
            }
            
            Write-Log "Field '$FieldName' = $ValueString (via CLI)" -Level DEBUG
            $script:CLIFallbackCount++
            
        } catch {
            Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
            throw
        }
    }
}
```

**Add other utility functions as needed**

---

### Step 3.6: Wrap Main Logic in Try-Catch-Finally (20 min)

**CRITICAL: Finally block must log execution time**

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
    # REQUIRED: Calculate and log execution time
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    # Summary
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $ExecutionTime seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
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

### Step 3.7: Remove User Interaction Commands (10 min)

**CRITICAL: Find and remove ALL user interaction**

```powershell
# FORBIDDEN - Find and remove these:
Read-Host "Press Enter to continue"
$UserInput = Read-Host "Enter option"
Pause
[Console]::ReadKey()
$Host.UI.ReadLine()
cmd /c pause

# Replace with logging:
Write-Log "Processing completed" -Level INFO

# Or use parameters with defaults:
[Parameter(Mandatory=$false)]
[string]$Mode = "Auto"  # Default value, no user prompt
```

**Search Strategy:**

1. Search for: `Read-Host`
2. Search for: `Pause`
3. Search for: `ReadKey`
4. Search for: `ReadLine`
5. Remove all instances
6. Verify zero occurrences remain

**Validation:**
```powershell
# Verify no user input commands remain
Select-String -Path "ScriptName.ps1" -Pattern "Read-Host|Pause|ReadKey|ReadLine"
# Should return no results
```

---

### Step 3.8: Add Restart Parameter Protection (10 min)

**CRITICAL: Protect all restart commands**

```powershell
# Before (FORBIDDEN):
if ($UpdatesNeedRestart) {
    Restart-Computer -Force
}

Restart-Computer  # Unprotected
Shutdown /r /t 0  # Unprotected

# After (REQUIRED):
if ($UpdatesNeedRestart) {
    if ($AllowRestart) {
        Write-Log "Restart authorized via parameter" -Level WARN
        Write-Log "Restarting in 60 seconds..." -Level WARN
        
        # Set fields before restart
        Set-NinjaField -FieldName "opsRestartInitiated" -Value "Yes"
        Set-NinjaField -FieldName "opsRestartReason" -Value "Windows Updates"
        Start-Sleep -Seconds 5  # Allow field sync
        
        Restart-Computer -Force
    } else {
        Write-Log "Restart required but NOT authorized" -Level WARN
        Write-Log "Use -AllowRestart parameter to enable" -Level WARN
        
        # Flag for admin review
        Set-NinjaField -FieldName "opsRestartRequired" -Value "Yes"
        Set-NinjaField -FieldName "opsRestartReason" -Value "Windows Updates"
    }
}
```

**Search Strategy:**

1. Search for: `Restart-Computer`
2. Search for: `Stop-Computer`
3. Search for: `shutdown`
4. Search for: `wmic.*reboot`
5. Wrap all with parameter check

---

### Step 3.9: Suppress Confirmations (5 min)

**Add -Confirm:$false to interactive cmdlets:**

```powershell
# Before - May hang waiting for confirmation:
Remove-Item $TempFile
Stop-Service $ServiceName
Restart-Service $ServiceName

# After - No user interaction:
Remove-Item $TempFile -Confirm:$false -Force -ErrorAction Stop
Stop-Service $ServiceName -Confirm:$false -Force -ErrorAction Stop
Restart-Service $ServiceName -Confirm:$false -Force -ErrorAction Stop
```

---

### Step 3.10: Replace Direct Field Setting (15 min)

**CRITICAL: Find and replace ALL Ninja-Property-Set calls**

```powershell
# Before (FORBIDDEN):
Ninja-Property-Set "fieldName" $Value
Ninja-Property-Set "opsHealthScore" $Score
if ($Value) { Ninja-Property-Set "field" $Value }

# After (REQUIRED):
Set-NinjaField -FieldName "fieldName" -Value $Value
Set-NinjaField -FieldName "opsHealthScore" -Value $Score
Set-NinjaField -FieldName "field" -Value $Value  # Handles null check internally
```

**Validation:**
```powershell
# Run this to verify no direct calls remain
Select-String -Path "ScriptName.ps1" -Pattern "Ninja-Property-Set" 
# Should return no results
```

---

### Step 3.11: Optimize Performance (15 min)

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

---

### Step 3.12: Improve Variable Naming (10 min)

**Apply PascalCase and descriptive names:**

```powershell
# Before:
$comp = $env:COMPUTERNAME
$mem = Get-Memory
$pct = ($used / $total) * 100
$start = Get-Date  # CRITICAL variable

# After:
$ComputerName = $env:COMPUTERNAME
$TotalMemoryGB = Get-TotalMemory
$UsedPercent = ($UsedSpace / $TotalSpace) * 100
$StartTime = Get-Date  # REQUIRED name for clarity
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

### Step 4.2: Unattended Execution Test (5 min)

**CRITICAL: Verify script doesn't hang**

```powershell
# Test that script runs without user interaction
$Job = Start-Job -ScriptBlock { .\ScriptName.ps1 }

if (-not (Wait-Job $Job -Timeout 300)) {
    Write-Host "FAIL: Script hung (waiting for input)" -ForegroundColor Red
    Stop-Job $Job
    Remove-Job $Job
} else {
    Write-Host "PASS: Script completed unattended" -ForegroundColor Green
    Receive-Job $Job
    Remove-Job $Job
}
```

### Step 4.3: Dry Run Test (5 min)

```powershell
# Test execution
.\ScriptName.ps1 -Verbose

# Verify:
# - No errors thrown
# - Logging works
# - Execution time is logged in finally block
# - No hang or wait for user input
# - Output looks correct
```

### Step 4.4: Field Population Test (5 min)

```powershell
# After running script, check NinjaRMM
# Verify all expected fields are populated

# Check:
# - Field values are correct
# - Data types are appropriate
# - No "N/A" where data should exist
# - Set-NinjaField wrapper worked
```

### Step 4.5: Execution Time Test (5 min)

**CRITICAL: Measure execution time multiple times**

```powershell
# Run 5 times and record
for ($i = 1; $i -le 5; $i++) {
    Write-Host "\nRun $i of 5:" -ForegroundColor Yellow
    .\ScriptName.ps1
}

# From the output logs, note execution times:
# Run 1: XX.X seconds
# Run 2: XX.X seconds
# Run 3: XX.X seconds
# Run 4: XX.X seconds
# Run 5: XX.X seconds
# Average: XX.X seconds

# Update script header with average time
```

### Step 4.6: Restart Parameter Test (3 min)

**Test restart behavior (if applicable):**

```powershell
# Test 1: Without parameter (should NOT restart)
.\ScriptName.ps1
# Verify: Device still running
# Verify: opsRestartRequired field set if applicable

# Test 2: With parameter (only on test VM!)
.\ScriptName.ps1 -AllowRestart
# Verify: Device restarts only if actually needed
```

---

## Phase 5: Deployment

### Step 5.1: Code Review (10 min)

**Self-review checklist:**

```markdown
### Code Review Checklist

#### Critical Requirements
- [ ] $StartTime defined in initialization
- [ ] Execution time logged in finally block
- [ ] Set-NinjaField function included
- [ ] Zero direct Ninja-Property-Set calls
- [ ] Zero user input commands (Read-Host, Pause, etc.)
- [ ] Restarts require -AllowRestart parameter
- [ ] -Confirm:$false on interactive cmdlets
- [ ] CLI fallback logic implemented

#### Structure
- [ ] Uses standard template format
- [ ] Comment-based help complete
- [ ] Typical duration documented
- [ ] User Interaction: NONE documented
- [ ] Restart Behavior documented
- [ ] All sections present
- [ ] Logical flow maintained

#### Standards Compliance
- [ ] Naming conventions followed
- [ ] Error handling on all critical ops
- [ ] Structured logging throughout
- [ ] CIM used instead of WMI

#### Quality
- [ ] Code is readable
- [ ] Complex logic is commented
- [ ] No hardcoded values
- [ ] Performance optimized

#### Testing
- [ ] All tests passed
- [ ] Runs unattended without hanging
- [ ] Fields populate correctly
- [ ] Execution time measured (5 runs)
- [ ] Error handling verified
- [ ] Restart parameter tested (if applicable)
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
                       - Added execution time tracking
                       - Implemented Set-NinjaField with CLI fallback
                       - Replaced all Ninja-Property-Set calls
                       - Removed all user interaction commands
                       - Added restart parameter protection
                       - Added structured logging
                       - Added comprehensive error handling
                       - Improved performance (WMI -> CIM)
                       - Improved variable naming
                       - Execution time: ~15s (measured avg of 5 runs)
#>
```

### Step 5.3: Commit Changes (3 min)

```bash
git add ScriptName.ps1
git commit -m "[Refactor] ScriptName.ps1 - Apply coding standards v1.2

Critical Changes:
- Added execution time tracking (StartTime + finally block)
- Implemented Set-NinjaField with ninjarmm-cli.exe fallback
- Replaced all Ninja-Property-Set direct calls (0 remaining)
- Removed all user interaction commands (Read-Host, Pause)
- Added restart parameter protection (-AllowRestart required)
- Added -Confirm:false to interactive cmdlets
- Added comprehensive error handling

Other Changes:
- Added comment-based help
- Implemented structured logging
- Replaced WMI with CIM queries
- Improved variable naming (PascalCase)
- Optimized performance

Testing:
- Tested on Windows 10, 11, Server 2022
- Runs unattended without hanging
- All fields populate correctly
- Error handling verified
- Execution time: 15.2s avg (was 23.4s)
- No failures in 10 test runs
- CLI fallback tested and working
- Restart parameter tested

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
- Monitor: Execution success, field updates, execution time, CLI usage, no hangs

### Phase 2: 10% of Fleet
- 15 devices (10% of 150)
- Duration: 1 week
- Monitor: Same as Phase 1 + performance impact

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
- [ ] Execution time tracking: Yes/No
- [ ] Direct Ninja-Property-Set calls: X found
- [ ] User input commands: X found
- [ ] Unprotected restarts: X found
- [ ] Effort estimated: XX minutes
- [ ] Success criteria defined

## Phase 2: Backup & Setup
- [ ] Backup created
- [ ] Git branch created
- [ ] Test environment ready

## Phase 3: Apply Standards

### Critical Requirements
- [ ] $StartTime added to initialization
- [ ] Finally block logs execution time
- [ ] Set-NinjaField function added
- [ ] All Ninja-Property-Set replaced (0 remaining)
- [ ] CLI fallback logic implemented
- [ ] All user input commands removed (0 remaining)
- [ ] Restart parameter protection added
- [ ] -Confirm:$false added to interactive cmdlets

### Standard Changes
- [ ] Comment-based help added
- [ ] User Interaction and Restart Behavior documented
- [ ] CmdletBinding added
- [ ] Configuration section added
- [ ] Initialization section added
- [ ] Write-Log function added
- [ ] Main logic wrapped in try-catch-finally
- [ ] Error handling on critical operations
- [ ] Performance optimized
- [ ] Variable naming improved
- [ ] Code comments added

## Phase 4: Testing
- [ ] Syntax validated
- [ ] Unattended execution test passed (no hang)
- [ ] Dry run test passed
- [ ] Field population verified
- [ ] Execution time measured (5 runs)
- [ ] Restart parameter tested (if applicable)
- [ ] Error scenarios tested
- [ ] Performance acceptable
- [ ] CLI fallback tested

## Phase 5: Deployment
- [ ] Code review completed
- [ ] Version history updated
- [ ] Changes committed
- [ ] Pilot deployment plan created
- [ ] Pilot deployed successfully
- [ ] Full deployment completed

## Results
- **Execution Time:** Before: XXs | After: XXs (avg of 5 runs)
- **Failure Rate:** Before: X% | After: X%
- **Direct Calls Removed:** X Ninja-Property-Set calls
- **User Input Removed:** X Read-Host/Pause commands
- **Restarts Protected:** X restart commands
- **CLI Fallbacks Used:** X times (in testing)
- **Standards Compliance:** 100%

## Notes
[Any issues, lessons learned, or recommendations]
```

---

## Common Refactoring Patterns

### Pattern 1: Remove User Input

```powershell
# Before (FORBIDDEN - will hang):
$UserChoice = Read-Host "Select option (1-3)"
Read-Host "Press Enter to continue"
Pause

# After (REQUIRED - use parameters):
[Parameter(Mandatory=$false)]
[ValidateSet('Option1','Option2','Option3')]
[string]$Mode = 'Option1'  # Default value

# Continue automatically
Write-Log "Processing with mode: $Mode" -Level INFO
```

### Pattern 2: Protect Restart Commands

```powershell
# Before (FORBIDDEN):
if ($UpdatesInstalled) {
    Restart-Computer -Force
}

# After (REQUIRED):
if ($UpdatesInstalled) {
    if ($AllowRestart) {
        Write-Log "Restart authorized" -Level WARN
        Set-NinjaField -FieldName "opsRestartInitiated" -Value "Yes"
        Start-Sleep -Seconds 5  # Allow field sync
        Restart-Computer -Force
    } else {
        Write-Log "Restart required but not authorized" -Level WARN
        Set-NinjaField -FieldName "opsRestartRequired" -Value "Yes"
    }
}
```

### Pattern 3: Suppress Confirmations

```powershell
# Before (may hang):
Remove-Item $TempFile
Stop-Service $ServiceName

# After (no hang):
Remove-Item $TempFile -Confirm:$false -Force -ErrorAction Stop
Stop-Service $ServiceName -Confirm:$false -Force -ErrorAction Stop
```

### Pattern 4: Add Execution Time Tracking

```powershell
# Before (MISSING CRITICAL REQUIREMENT):
try {
    # Script logic
} catch {
    Write-Host "Error: $_"
}

# After (REQUIRED):
$StartTime = Get-Date  # At script start

try {
    # Script logic
} catch {
    Write-Log "Error: $_" -Level ERROR
} finally {
    $ExecutionTime = ((Get-Date) - $StartTime).TotalSeconds
    Write-Log "Duration: $ExecutionTime seconds" -Level INFO
}
```

### Pattern 5: Replace Direct Field Setting

```powershell
# Before (FORBIDDEN):
Ninja-Property-Set "opsHealthScore" $HealthScore

if ($DiskSpace) {
    Ninja-Property-Set "capDiskCFreeGB" $DiskSpace
}

# After (REQUIRED):
Set-NinjaField -FieldName "opsHealthScore" -Value $HealthScore

# No need for null check - function handles it
Set-NinjaField -FieldName "capDiskCFreeGB" -Value $DiskSpace
```

---

## Troubleshooting Refactoring Issues

### Issue: Script hangs during testing

**Check:**
- Did you remove ALL Read-Host commands?
- Did you remove ALL Pause commands?
- Are there any -Confirm parameters without :$false?
- Check for [Console]::ReadKey() or similar

**Fix:**
```powershell
# Search for all interactive commands
Select-String -Path "ScriptName.ps1" -Pattern "Read-Host|Pause|ReadKey|ReadLine|\-Confirm(?!:\$false)"
# Remove all instances
```

### Issue: Device restarted unexpectedly

**Check:**
- Did you add parameter check to ALL restart commands?
- Is -AllowRestart parameter defined?
- Are there any shutdown.exe or wmic commands?

**Fix:**
```powershell
# Search for all restart commands
Select-String -Path "ScriptName.ps1" -Pattern "Restart-Computer|Stop-Computer|shutdown|wmic.*reboot"
# Verify all are wrapped in parameter check
```

### Issue: Execution time not appearing in logs

**Check:**
- Is `$StartTime = Get-Date` at the beginning?
- Is the calculation in the `finally` block?
- Is Write-Log being called with the duration?

**Fix:**
```powershell
# Ensure this structure
$StartTime = Get-Date  # Top of script

try { } catch { } finally {
    $ExecutionTime = ((Get-Date) - $StartTime).TotalSeconds
    Write-Log "Duration: $ExecutionTime seconds" -Level INFO
}
```

### Issue: Fields not populating after refactoring

**Check:**
- Did you replace ALL Ninja-Property-Set calls?
- Is Set-NinjaField function defined?
- Are values null (function skips null)?
- Check NinjaRMM field names (case-sensitive)

**Validation:**
```powershell
# Search for any remaining direct calls
Select-String -Path "ScriptName.ps1" -Pattern "Ninja-Property-Set"
# Should return ZERO results
```

---

## Summary

**Critical Requirements:**

1. ✅ **Execution Time Tracking** - `$StartTime` in init, logged in finally
2. ✅ **Set-NinjaField with CLI Fallback** - Never call Ninja-Property-Set directly
3. ✅ **No User Interaction** - Never use Read-Host, Pause, or prompts
4. ✅ **No Restarts Without Parameter** - Require `-AllowRestart` parameter
5. ✅ **Structured Logging** - Write-Log function
6. ✅ **Error Handling** - Try-catch-finally structure

**Time Investment:**
- Simple script: 30-45 minutes
- Medium script: 45-75 minutes
- Complex script: 75-120 minutes

**Benefits:**
- Performance monitoring enabled
- Reliable field setting in all contexts
- Fully automated unattended operation
- Controlled restart behavior
- Improved error handling
- Better maintainability
- Consistent code quality

**Remember:**
- Don't skip critical requirements
- Test execution time 5+ times for accurate average
- Verify ZERO direct Ninja-Property-Set calls remain
- Verify ZERO user input commands remain
- Test unattended execution (no hang)
- Test restart parameter if applicable
- Document typical duration in script header

---

## Related Documents

- [Coding Standards](CODING_STANDARDS.md) - Standards to follow
- [Script Header Template](SCRIPT_HEADER_TEMPLATE.ps1) - Template to use

---

**Document Version:** 1.2  
**Last Updated:** February 9, 2026  
**Changes:** Added requirements for no user interaction and restart parameter protection  
**Next Review:** After first 10 script refactorings completed
