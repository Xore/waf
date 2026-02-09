# Comprehensive Standards Compliance Action Plan

**Created:** February 9, 2026, 11:20 PM CET  
**Status:** IN PROGRESS  
**Scope:** All 219+ plaintext_scripts

---

## Executive Summary

This document provides the complete action plan for refactoring all WAF scripts to meet standards compliance. It incorporates requirements from:

1. **CODING_STANDARDS.md** - Overall coding standards
2. **LANGUAGE_AWARE_PATHS.md** - Internationalization requirements
3. **OUTPUT_FORMATTING.md** - Output formatting standards
4. **SCRIPT_HEADER_TEMPLATE.ps1** - Template structure
5. **SCRIPT_REFACTORING_GUIDE.md** - Step-by-step refactoring process

---

## Critical Requirements Checklist

### Every Script MUST Have:

#### Phase 1: Critical (MUST FIX)

- [ ] **Output Formatting (Plain Text Only)**
  - Replace all `Write-Host` with plain `Write-Output`
  - Remove `-ForegroundColor`, `-BackgroundColor`, `-Object` parameters
  - Remove `-NoNewline`, `-Separator` parameters
  - No ANSI color codes or escape sequences
  - No emoji or special Unicode characters in scripts
  - All output ASCII-compatible

- [ ] **Unattended Operation**
  - NO `Read-Host` commands (script will hang)
  - NO `Pause` commands (script will hang)
  - NO `[Console]::ReadKey()` (script will hang)
  - NO prompts or user input of any kind
  - Add `-Confirm:$false` to all interactive cmdlets
  - `Remove-Item -Confirm:$false -Force`
  - `Stop-Service -Confirm:$false -Force`
  - `Restart-Service -Confirm:$false -Force`

- [ ] **Restart Protection**
  - ALL restart commands require `-AllowRestart` parameter
  - `Restart-Computer` wrapped in parameter check
  - `Stop-Computer` wrapped in parameter check
  - `shutdown.exe` wrapped in parameter check
  - Set fields before restart (allow 5s sync time)
  - Flag restart requirement if not authorized

- [ ] **Field Setting with CLI Fallback**
  - NEVER call `Ninja-Property-Set` directly (FORBIDDEN)
  - ALWAYS use `Set-NinjaField` wrapper function
  - Function includes automatic ninjarmm-cli.exe fallback
  - Tracks CLI usage with `$script:CLIFallbackCount`

#### Phase 2: Important (SHOULD FIX)

- [ ] **Execution Time Tracking (REQUIRED)**
  - `$StartTime = Get-Date` at script initialization
  - `finally` block calculates duration
  - Logs execution time: `"Duration: $ExecutionTime seconds"`
  - Document typical duration in script header
  - Test 5+ times for accurate average

- [ ] **Language-Aware Paths**
  - Use `[Environment]::GetFolderPath()` for special folders
  - Never hardcode `C:\Users` or `C:\Programme`
  - Never hardcode `Desktop`, `Documents`, etc.
  - Use registry for Windows paths when needed
  - Handle both English and non-English Windows

- [ ] **Module Dependencies**
  - List all required modules in header
  - Check module availability before use
  - Graceful failure if module missing
  - Import modules explicitly

#### Phase 3: Recommended (NICE TO HAVE)

- [ ] **Comment-Based Help**
  - `.SYNOPSIS` - Clear one-line description
  - `.DESCRIPTION` - Detailed functionality explanation
  - `.PARAMETER` - Document all parameters
  - `.EXAMPLE` - At least one usage example
  - `.NOTES` - Version, author, requirements, duration, behavior
  - `.LINK` - GitHub repo link
  - **Document typical execution time**
  - **Document: "User Interaction: NONE"**
  - **Document restart behavior explicitly**

- [ ] **Error Handling**
  - Try-catch-finally on main execution
  - Try-catch on critical operations
  - Specific error messages with context
  - Proper exit codes (0=success, 1=error)
  - Log errors with `Write-Log -Level ERROR`

- [ ] **Code Structure**
  - Use `[CmdletBinding()]`
  - Configuration section for all settings
  - Initialization section with $StartTime
  - Functions section with standard functions
  - Main execution in try-catch-finally
  - Summary logging in finally block

---

## Standard Functions Template

### Write-Log Function (REQUIRED)

```powershell
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Plain text output only - no colors
    Write-Output $LogMessage
    
    # Track counts
    switch ($Level) {
        'WARN'  { $script:WarningCount++ }
        'ERROR' { $script:ErrorCount++ }
    }
}
```

### Set-NinjaField Function (REQUIRED)

```powershell
function Set-NinjaField {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    # Method 1: Try Ninja-Property-Set cmdlet
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
            $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
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

---

## Script Structure Template

```powershell
<#
.SYNOPSIS
    [Clear one-line description]

.DESCRIPTION
    [Detailed description]
    
    This script runs unattended without user interaction.

.PARAMETER AllowRestart
    (If applicable) Authorizes device restart if required.
    Without this parameter, script will only flag restart requirement.

.NOTES
    Script Name:    [Filename.ps1]
    Version:        [X.Y]
    Last Modified:  [Date]
    
    Execution Context: SYSTEM (via NinjaRMM)
    Typical Duration: ~XX seconds (REQUIRED)
    
    User Interaction: NONE (fully automated)
    Restart Behavior: Never restarts unless -AllowRestart provided
    
    Fields Updated:
        - [fieldName] (description)
    
    Exit Codes:
        0 - Success
        1 - Error

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$AllowRestart
)

#Requires -Version 5.1

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date  # REQUIRED
$ScriptName = $MyInvocation.MyCommand.Name

$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    # [Function code as above]
}

function Set-NinjaField {
    # [Function code as above]
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "Starting: $ScriptName"
    
    # [MAIN LOGIC HERE]
    # - Use Write-Log for all output
    # - Use Set-NinjaField for all field setting
    # - Add -Confirm:$false to interactive cmdlets
    # - Wrap restarts in parameter check
    # - Use language-aware paths
    
    Write-Log "Script completed successfully"
    
} catch {
    Write-Log "Script execution failed: $_" -Level ERROR
    exit 1
    
} finally {
    # REQUIRED: Calculate and log execution time
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================"
    Write-Log "Execution Summary:"
    Write-Log "  Duration: $ExecutionTime seconds"
    Write-Log "  Errors: $script:ErrorCount"
    Write-Log "  Warnings: $script:WarningCount"
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount"
    }
    
    Write-Log "========================================"
}

if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
```

---

## Search & Replace Patterns

### Remove User Interaction

```powershell
# FIND AND REMOVE (will cause hang):
Read-Host
Pause
[Console]::ReadKey()
$Host.UI.ReadLine()
cmd /c pause

# REPLACE WITH:
# Use parameters with defaults instead
# Or just remove - script runs automatically
```

### Replace Output Commands

```powershell
# FIND:
Write-Host "Message" -ForegroundColor Green
Write-Host $var -Object $obj -NoNewline
Write-Host $items -Separator ", "
Write-Host "Text: " -NoNewline
Write-Host $value

# REPLACE WITH:
Write-Log "Message"
$combined = "Text: $value"
Write-Log $combined
$itemList = $items -join ", "
Write-Log $itemList
```

### Protect Restart Commands

```powershell
# FIND:
Restart-Computer
Restart-Computer -Force
shutdown /r /t 0

# REPLACE WITH:
if ($AllowRestart) {
    Write-Log "Restart authorized via parameter" -Level WARN
    Set-NinjaField -FieldName "opsRestartInitiated" -Value "Yes"
    Start-Sleep -Seconds 5
    Restart-Computer -Force
} else {
    Write-Log "Restart required but NOT authorized" -Level WARN
    Set-NinjaField -FieldName "opsRestartRequired" -Value "Yes"
}
```

### Replace Field Setting

```powershell
# FIND (FORBIDDEN):
Ninja-Property-Set "fieldName" $Value
Ninja-Property-Set "opsHealthScore" $Score

# REPLACE WITH (REQUIRED):
Set-NinjaField -FieldName "fieldName" -Value $Value
Set-NinjaField -FieldName "opsHealthScore" -Value $Score
```

### Add Confirmation Suppression

```powershell
# FIND:
Remove-Item $Path
Stop-Service $Name
Restart-Service $Name

# REPLACE WITH:
Remove-Item $Path -Confirm:$false -Force
Stop-Service $Name -Confirm:$false -Force
Restart-Service $Name -Confirm:$false -Force
```

### Replace Hardcoded Paths

```powershell
# FIND (WRONG):
"C:\Users\$Username\Desktop"
"C:\Users\$Username\Documents"
"C:\Program Files"

# REPLACE WITH (CORRECT):
[Environment]::GetFolderPath('Desktop')
[Environment]::GetFolderPath('MyDocuments')
[Environment]::GetFolderPath('ProgramFiles')
```

---

## Validation Commands

### Check for Violations

```powershell
# Run these searches on each script to find violations

# 1. Check for direct Ninja-Property-Set calls (should be 0)
Select-String -Path "Script.ps1" -Pattern "Ninja-Property-Set"

# 2. Check for user interaction commands (should be 0)
Select-String -Path "Script.ps1" -Pattern "Read-Host|Pause|ReadKey|ReadLine"

# 3. Check for unprotected restarts
Select-String -Path "Script.ps1" -Pattern "Restart-Computer|Stop-Computer|shutdown"
# Verify each has parameter check

# 4. Check for output formatting issues
Select-String -Path "Script.ps1" -Pattern "Write-Host.*-ForegroundColor|Write-Host.*-BackgroundColor"
Select-String -Path "Script.ps1" -Pattern "Write-Host.*-NoNewline|Write-Host.*-Separator"

# 5. Check for hardcoded paths
Select-String -Path "Script.ps1" -Pattern "C:\\Users|C:\\Programme|\\Desktop\\|\\Documents\\"

# 6. Verify execution time tracking
Select-String -Path "Script.ps1" -Pattern "\$StartTime\s*="
Select-String -Path "Script.ps1" -Pattern "finally\s*{"
# Verify both exist
```

---

## Refactoring Workflow

### For Each Script:

1. **Open original script**
2. **Create backup** (auto-saved in Git)
3. **Run violation checks** (commands above)
4. **Apply template structure**
   - Add comment-based help
   - Add initialization with $StartTime
   - Add Write-Log function
   - Add Set-NinjaField function
5. **Fix Phase 1 violations** (Critical)
   - Replace all Write-Host
   - Remove all user interaction
   - Protect all restart commands
   - Replace all Ninja-Property-Set
   - Add -Confirm:$false to interactive cmdlets
6. **Fix Phase 2 violations** (Important)
   - Verify $StartTime in initialization
   - Add finally block with duration logging
   - Fix hardcoded paths
7. **Fix Phase 3 violations** (Recommended)
   - Enhance error handling
   - Improve documentation
8. **Test unattended execution**
   - Start-Job with timeout
   - Verify no hang
9. **Measure execution time** (5+ runs)
10. **Update header** with measured duration
11. **Commit with detailed message**
12. **Update progress tracking**

---

## Testing Checklist

### Per Script Testing:

```markdown
- [ ] Syntax validation (no errors)
- [ ] Unattended execution test (no hang within 5 minutes)
- [ ] Execution time measured (5 runs, average calculated)
- [ ] Zero violations found:
  - [ ] 0 Ninja-Property-Set direct calls
  - [ ] 0 Read-Host/Pause commands
  - [ ] 0 unprotected restart commands
  - [ ] 0 Write-Host with colors
  - [ ] 0 hardcoded user paths
- [ ] $StartTime exists
- [ ] Finally block logs duration
- [ ] Set-NinjaField function exists
- [ ] Write-Log function exists
- [ ] Restart parameter tested (if applicable)
- [ ] Fields populate correctly
- [ ] Error handling works
```

---

## Progress Tracking

Progress is tracked in: `STANDARDS_COMPLIANCE_PROGRESS.md`

Each script entry includes:
- Script name and status
- Commit hash
- Size change
- Violations found and fixed
- Phase 1-3 compliance details
- Testing results
- Execution time measurements

---

## Estimated Timeline

| Phase | Scripts | Time per Script | Total Time |
|-------|---------|----------------|------------|
| Small (<500 lines) | ~150 | 30-45 min | 75-112 hours |
| Medium (500-2000) | ~50 | 45-75 min | 37-62 hours |
| Large (2000+) | ~19 | 75-120 min | 23-38 hours |
| **TOTAL** | **219** | **Average 52 min** | **135-212 hours** |

### Realistic Schedule

- **Per session:** 8-12 scripts (6-9 hours)
- **Per week:** 3-4 sessions = 24-48 scripts
- **Total duration:** 5-9 weeks for all 219 scripts

---

## Priority Order

### High Priority (Complete First)
1. **AD Category** (14 scripts) - Domain operations
2. **Security Category** (16 scripts) - Critical security
3. **Monitoring Category** (7 scripts) - High frequency
4. **Network Category** (16 scripts) - Infrastructure

### Medium Priority
5. Storage, Services, Updates, Windows

### Lower Priority
6. Specialty scripts, utilities

---

## Success Metrics

### Per Script:
- 100% standards compliance
- 0 critical violations
- Execution time documented
- Unattended execution verified
- All tests passed

### Overall Project:
- 219 scripts refactored
- Average execution time improvement
- Zero scripts with user interaction
- Zero unprotected restart commands
- 100% using Set-NinjaField wrapper
- All scripts with execution time tracking

---

## Related Documentation

- **CODING_STANDARDS.md** - Complete standards reference
- **OUTPUT_FORMATTING.md** - Output formatting rules
- **LANGUAGE_AWARE_PATHS.md** - Path handling requirements
- **SCRIPT_REFACTORING_GUIDE.md** - Detailed refactoring steps
- **SCRIPT_HEADER_TEMPLATE.ps1** - Template file
- **STANDARDS_COMPLIANCE_PROGRESS.md** - Progress tracking

---

**Action Plan Version:** 1.0  
**Created:** February 9, 2026, 11:20 PM CET  
**Next Update:** After completing first category (AD - 14 scripts)
