# Output Formatting Standards - Windows Automation Framework

**Document Type:** Development Standards  
**Audience:** Script Developers, Contributors  
**Version:** 1.0  
**Last Updated:** February 9, 2026

---

## Purpose

This document establishes strict standards for script output formatting to ensure compatibility, readability, and proper parsing across all execution contexts including NinjaRMM automation, PowerShell consoles, log files, and monitoring systems.

---

## Critical Requirements

### MANDATORY: No Emojis or Unicode Symbols

**ALL scripts MUST NEVER use emojis or special Unicode symbols in any output**

Emojis and special symbols cause encoding issues, break log parsing, and display incorrectly in many contexts.

```powershell
# FORBIDDEN - Never use emojis or symbols
Write-Host "Status: ✅ Success"  # Will break in logs
Write-Host "Error: ❌ Failed"    # Encoding issues
Write-Host "Warning: ⚠️ Issue"   # Not supported
Write-Log "Done ✓" -Level INFO   # Breaks parsing
Write-Log "Failed ✗" -Level ERROR

# FORBIDDEN - Special Unicode symbols
Write-Host "Progress: █████░░░░░ 50%"  # Progress bars
Write-Host "Status → Active"  # Arrows
Write-Host "Disk • 45% full"  # Bullets
Write-Host "System ☑ Ready"   # Checkboxes
Write-Host "CPU ≈ 80%"        # Math symbols

# REQUIRED - Plain text only
Write-Log "Status: Success" -Level INFO
Write-Log "Status: Failed" -Level ERROR
Write-Log "Status: Warning" -Level WARN
Write-Log "Progress: 50 percent complete" -Level INFO
Write-Log "Status: Active" -Level INFO
Write-Log "Disk: 45 percent full" -Level INFO
Write-Log "System: Ready" -Level INFO
Write-Log "CPU: 80 percent" -Level INFO
```

**Why:**
- Emojis break log file encoding (UTF-8 issues)
- Special symbols don't display in NinjaRMM console
- Log parsing tools fail on Unicode characters
- Text files become corrupted
- Database storage issues
- Email notifications display incorrectly
- API integrations fail

**Exceptions:** NONE. Plain ASCII text only.

### MANDATORY: No Color Formatting

**ALL scripts MUST NEVER use color formatting in output**

Color codes are stripped in log files and cause issues in automated environments.

```powershell
# FORBIDDEN - Never use colors
Write-Host "Success" -ForegroundColor Green
Write-Host "Error" -ForegroundColor Red  
Write-Host "Warning" -ForegroundColor Yellow
Write-Host "Info" -ForegroundColor Cyan

# FORBIDDEN - ANSI color codes
Write-Host "`e[32mSuccess`e[0m"  # Green
Write-Host "`e[31mError`e[0m"    # Red
$Host.UI.RawUI.ForegroundColor = 'Green'

# FORBIDDEN - Console color manipulation
[Console]::ForegroundColor = 'Green'
[Console]::BackgroundColor = 'Black'

# REQUIRED - Plain text with severity levels
Write-Log "Operation successful" -Level INFO
Write-Log "Operation failed" -Level ERROR
Write-Log "Potential issue detected" -Level WARN
Write-Log "Additional information" -Level DEBUG
```

**Why:**
- Color codes are stripped in log files
- NinjaRMM console doesn't preserve colors
- Automated parsing fails with color codes
- Log aggregation tools strip ANSI codes
- Email notifications lose formatting
- Screen readers cannot interpret colors
- Severity levels provide same information

**Exceptions:** NONE. Use log levels instead of colors.

### MANDATORY: No Visual Progress Indicators

**Scripts MUST NOT use visual progress indicators like progress bars or spinners**

These rely on cursor positioning and terminal control, which don't work in automated execution.

```powershell
# FORBIDDEN - No progress bars
Write-Progress -Activity "Processing" -Status "50% Complete" -PercentComplete 50

# FORBIDDEN - No ASCII progress bars
Write-Host "[█████░░░░░] 50%"
Write-Host "Progress: ===================> 50%"

# FORBIDDEN - No spinners
Write-Host "`r|" -NoNewline
Write-Host "`r/" -NoNewline  
Write-Host "`r-" -NoNewline
Write-Host "`r\" -NoNewline

# FORBIDDEN - No cursor positioning
[Console]::SetCursorPosition(0, 0)
[Console]::CursorLeft = 0

# REQUIRED - Log percentage milestones
Write-Log "Processing: 0 percent complete" -Level INFO
Write-Log "Processing: 25 percent complete" -Level INFO
Write-Log "Processing: 50 percent complete" -Level INFO  
Write-Log "Processing: 75 percent complete" -Level INFO
Write-Log "Processing: 100 percent complete" -Level INFO

# OR - Log item counts
Write-Log "Processing item 50 of 100" -Level INFO
Write-Log "Processed 50 of 100 files" -Level INFO
```

**Why:**
- Write-Progress doesn't appear in log files
- Cursor manipulation breaks in non-interactive contexts
- NinjaRMM doesn't support terminal control codes
- Log files become unreadable with escape sequences
- Automated monitoring cannot parse progress bars

**Exceptions:** NONE. Log milestone percentages instead.

---

## Output Standards

### Use Write-Log for All Output

**ALL scripts must use Write-Log function instead of Write-Host or Write-Output**

```powershell
# REQUIRED - Write-Log function
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Write to console (plain text only)
    Write-Output $LogMessage
    
    # Optionally write to file
    if ($script:LogFilePath) {
        Add-Content -Path $script:LogFilePath -Value $LogMessage -ErrorAction SilentlyContinue
    }
}

# GOOD - Plain text with severity
Write-Log "Disk space check completed" -Level INFO
Write-Log "Low disk space detected" -Level WARN
Write-Log "Failed to access disk" -Level ERROR
Write-Log "Disk C: has 45 percent free space" -Level DEBUG

# BAD - Write-Host with colors
Write-Host "Success!" -ForegroundColor Green

# BAD - Write-Output without structure
Write-Output "Something happened"
```

### Status Indicators

**Use plain text words for status, not symbols**

```powershell
# REQUIRED - Plain text status
Write-Log "Status: Success" -Level INFO
Write-Log "Status: Failed" -Level ERROR
Write-Log "Status: Running" -Level INFO
Write-Log "Status: Stopped" -Level WARN
Write-Log "Status: Pending" -Level INFO
Write-Log "Status: Completed" -Level INFO
Write-Log "Status: Skipped" -Level WARN

# FORBIDDEN - Symbols
Write-Log "Status: ✓" -Level INFO  # Checkmark
Write-Log "Status: ✗" -Level ERROR  # X mark
Write-Log "Status: ►" -Level INFO   # Play symbol
Write-Log "Status: ■" -Level WARN   # Stop symbol
Write-Log "Status: ..." -Level INFO  # Ellipsis

# REQUIRED - Boolean results
Write-Log "Check passed: Yes" -Level INFO
Write-Log "Check passed: No" -Level ERROR
Write-Log "Is healthy: True" -Level INFO
Write-Log "Is healthy: False" -Level WARN
```

### Numeric Values

**Use full words for percentages and measurements**

```powershell
# REQUIRED - Full words
Write-Log "CPU usage: 75 percent" -Level INFO
Write-Log "Memory free: 8 GB" -Level INFO
Write-Log "Disk C: 120 GB free of 500 GB total" -Level INFO
Write-Log "Temperature: 45 degrees Celsius" -Level INFO
Write-Log "Approximately 1000 files" -Level INFO
Write-Log "Greater than 50 percent" -Level INFO
Write-Log "Less than or equal to 100" -Level INFO

# FORBIDDEN - Special symbols
Write-Log "CPU: 75%" -Level INFO         # Use 'percent'
Write-Log "Temp: 45°C" -Level INFO       # Use 'degrees Celsius'
Write-Log "~1000 files" -Level INFO      # Use 'approximately'
Write-Log "Memory: 8GB" -Level INFO      # Add space: '8 GB'
Write-Log ">50%" -Level INFO             # Use 'greater than'
Write-Log "≤100" -Level INFO             # Use words
Write-Log "±5" -Level INFO               # Use 'plus or minus'
```

### Lists and Formatting

**Use plain text formatting without special characters**

```powershell
# REQUIRED - Plain text lists
Write-Log "Services checked:" -Level INFO
Write-Log "  - Windows Update" -Level INFO
Write-Log "  - Windows Defender" -Level INFO  
Write-Log "  - Windows Firewall" -Level INFO

# REQUIRED - Numbered lists
Write-Log "Steps completed:" -Level INFO
Write-Log "  1. Checked disk space" -Level INFO
Write-Log "  2. Verified services" -Level INFO
Write-Log "  3. Updated registry" -Level INFO

# FORBIDDEN - Special bullets
Write-Log "Services checked:" -Level INFO
Write-Log "  • Windows Update" -Level INFO      # Bullet symbol
Write-Log "  ● Windows Defender" -Level INFO    # Filled bullet
Write-Log "  ◦ Windows Firewall" -Level INFO    # Hollow bullet
Write-Log "  ✓ Service running" -Level INFO     # Checkmark

# REQUIRED - Indentation with spaces or hyphens
Write-Log "Category: System" -Level INFO
Write-Log "  Subcategory: Disk" -Level INFO
Write-Log "    Item: Drive C" -Level INFO
```

### Separators and Dividers

**Use hyphens or equals signs for separators**

```powershell
# REQUIRED - ASCII separators
Write-Log "============================================" -Level INFO
Write-Log "  System Health Check Report" -Level INFO
Write-Log "============================================" -Level INFO

Write-Log "--------------------------------------------" -Level INFO
Write-Log "Section: Disk Space" -Level INFO  
Write-Log "--------------------------------------------" -Level INFO

# FORBIDDEN - Unicode box drawing
Write-Log "═══════════════════════════════════════════" -Level INFO
Write-Log "┌─────────────────────────────────────────┐" -Level INFO
Write-Log "│ Report │" -Level INFO
Write-Log "└─────────────────────────────────────────┘" -Level INFO
Write-Log "╔═══════════════════════════════════════╗" -Level INFO
```

### Arrows and Connectors

**Use plain text words instead of arrows**

```powershell
# REQUIRED - Plain text
Write-Log "Old value: 100" -Level INFO
Write-Log "New value: 200" -Level INFO
Write-Log "Changed from 100 to 200" -Level INFO

Write-Log "Source: Server1" -Level INFO
Write-Log "Target: Server2" -Level INFO
Write-Log "Copy from Server1 to Server2" -Level INFO

# FORBIDDEN - Arrow symbols
Write-Log "100 → 200" -Level INFO          # Right arrow
Write-Log "100 => 200" -Level INFO         # Fat arrow  
Write-Log "Server1 ➜ Server2" -Level INFO  # Arrow
Write-Log "A ⇒ B" -Level INFO             # Double arrow
Write-Log "X ← Y" -Level INFO             # Left arrow
```

---

## Special Cases

### Test/Development Scripts Only

**Test scripts (not deployed to production) MAY use colors for developer convenience**

```powershell
# ACCEPTABLE in test scripts only (Tests\ folder)
if ($env:SCRIPT_ENV -eq 'Development') {
    Write-Host "Test passed" -ForegroundColor Green
} else {
    Write-Log "Test passed" -Level INFO
}

# Better approach - Separate test and production functions
function Write-TestLog {
    param($Message, $Status)
    
    if ($env:SCRIPT_ENV -eq 'Development') {
        $Color = switch ($Status) {
            'Success' { 'Green' }
            'Failed'  { 'Red' }
            'Warning' { 'Yellow' }
            default   { 'White' }
        }
        Write-Host $Message -ForegroundColor $Color
    } else {
        Write-Log $Message -Level INFO
    }
}
```

**This is ONLY acceptable in:**
- Scripts in `Tests\` folder
- Scripts in `Development\` folder  
- Scripts explicitly marked as development-only

**NEVER acceptable in:**
- Production scripts
- Scripts deployed to NinjaRMM
- Scripts in the main scripts folder

### Interactive Console Sessions

**Manual console sessions MAY use Write-Host for immediate feedback**

When running scripts manually in PowerShell for troubleshooting:

```powershell
# Check if running interactively
if ([Environment]::UserInteractive -and -not $env:NINJARMM_AUTOMATION) {
    Write-Host "Running in interactive mode" -ForegroundColor Cyan
    # Interactive feedback OK here
} else {
    # Production execution - plain text only
    Write-Log "Script started" -Level INFO
}
```

**However, prefer Write-Log in all cases for consistency.**

---

## Anti-Patterns

### Common Violations

```powershell
# VIOLATION 1: Emoji in success message
Write-Log "Backup completed successfully! 🎉" -Level INFO
# FIX:
Write-Log "Backup completed successfully" -Level INFO

# VIOLATION 2: Checkmarks for status
Write-Log "Service Status: ✓ Running" -Level INFO
# FIX:
Write-Log "Service Status: Running" -Level INFO

# VIOLATION 3: Colored error messages
Write-Host "ERROR: Failed to connect" -ForegroundColor Red
# FIX:
Write-Log "Failed to connect" -Level ERROR

# VIOLATION 4: Progress bar
for ($i = 1; $i -le 100; $i++) {
    Write-Progress -Activity "Processing" -PercentComplete $i
}
# FIX:
$Total = 100
for ($i = 1; $i -le $Total; $i++) {
    if ($i % 25 -eq 0) {
        $Percent = ($i / $Total) * 100
        Write-Log "Processing: $Percent percent complete" -Level INFO
    }
}

# VIOLATION 5: Unicode box drawing
Write-Log "╔══════════════╗" -Level INFO
Write-Log "║ System Info  ║" -Level INFO
Write-Log "╚══════════════╝" -Level INFO
# FIX:
Write-Log "===================" -Level INFO
Write-Log "  System Info" -Level INFO  
Write-Log "===================" -Level INFO

# VIOLATION 6: Math symbols
Write-Log "Value ≈ 100" -Level INFO
Write-Log "Range: 1→10" -Level INFO
Write-Log "Result ≤ 50" -Level INFO
# FIX:
Write-Log "Value approximately 100" -Level INFO
Write-Log "Range: 1 to 10" -Level INFO
Write-Log "Result less than or equal to 50" -Level INFO

# VIOLATION 7: Percentage without word
Write-Log "CPU at 85%" -Level INFO
# FIX:
Write-Log "CPU at 85 percent" -Level INFO

# VIOLATION 8: Degree symbol
Write-Log "CPU temperature: 65°C" -Level INFO
# FIX:
Write-Log "CPU temperature: 65 degrees Celsius" -Level INFO
```

---

## Rationale

### Why These Restrictions?

**NinjaRMM Compatibility:**
- NinjaRMM console displays plain text only
- Custom fields store text without formatting
- Email alerts strip special characters
- API responses are JSON (text-based)

**Log File Integrity:**
- UTF-8 emojis corrupt text files
- ANSI color codes clutter logs
- Special symbols break log parsing
- Grep/regex searches fail on Unicode

**Monitoring and Alerting:**
- SIEM tools expect plain text
- Alert rules parse text messages
- Log aggregation relies on consistent encoding
- Database storage requires safe text

**Accessibility:**
- Screen readers cannot interpret emojis
- Colors are meaningless to visually impaired
- Symbols have no semantic meaning
- Plain text is universally accessible

**Cross-Platform:**
- Different PowerShell versions handle Unicode differently
- Windows PowerShell 5.1 vs PowerShell 7 differences
- Console encoding varies by locale
- File system encoding inconsistent

---

## Testing Output Format

### Validate Script Output

```powershell
function Test-OutputFormat {
    <#
    .SYNOPSIS
        Tests script output for compliance with formatting standards
    #>
    param(
        [string]$ScriptPath
    )
    
    Write-Host "Testing output format for: $ScriptPath" -ForegroundColor Cyan
    
    # Get script content
    $Content = Get-Content $ScriptPath -Raw
    
    # Check for forbidden patterns
    $Violations = @()
    
    # Check for emojis (Unicode range)
    if ($Content -match '[\u{1F300}-\u{1F9FF}]') {
        $Violations += "Contains emoji characters"
    }
    
    # Check for common Unicode symbols
    $ForbiddenSymbols = @('✓', '✗', '✅', '❌', '⚠️', '►', '■', '●', '•', '→', '⇒', '←', '≈', '≤', '≥', '°', '±')
    foreach ($Symbol in $ForbiddenSymbols) {
        if ($Content -match [regex]::Escape($Symbol)) {
            $Violations += "Contains forbidden symbol: $Symbol"
        }
    }
    
    # Check for Write-Host with colors
    if ($Content -match 'Write-Host.*-ForegroundColor') {
        $Violations += "Uses Write-Host with -ForegroundColor"
    }
    
    if ($Content -match 'Write-Host.*-BackgroundColor') {
        $Violations += "Uses Write-Host with -BackgroundColor"
    }
    
    # Check for Write-Progress
    if ($Content -match 'Write-Progress') {
        $Violations += "Uses Write-Progress"
    }
    
    # Check for ANSI codes
    if ($Content -match '`e\[\d+m') {
        $Violations += "Uses ANSI color codes"
    }
    
    # Check for Console color manipulation
    if ($Content -match '\[Console\]::.*Color') {
        $Violations += "Manipulates Console colors"
    }
    
    # Report results
    if ($Violations.Count -eq 0) {
        Write-Host "PASS: No formatting violations found" -ForegroundColor Green
        return $true
    } else {
        Write-Host "FAIL: Found $($Violations.Count) violation(s):" -ForegroundColor Red
        foreach ($Violation in $Violations) {
            Write-Host "  - $Violation" -ForegroundColor Yellow
        }
        return $false
    }
}

# Usage
Test-OutputFormat -ScriptPath "C:\Scripts\MyScript.ps1"
```

---

## Quick Reference

### Prohibited Elements

| Prohibited | Reason | Alternative |
|------------|--------|-------------|
| Emojis (🎉✅❌) | Encoding issues | Plain text words |
| Unicode symbols (✓✗→) | Display problems | Text equivalents |
| Colors (-ForegroundColor) | Stripped in logs | Log levels (INFO/WARN/ERROR) |
| Write-Progress | Not logged | Log milestone percentages |
| ANSI codes (`e[32m) | Corrupts logs | Write-Log function |
| Degree symbol (°) | Unicode issues | "degrees Celsius" |
| Percent sign alone (%) | Potential parsing | "percent" |
| Math symbols (≈≤≥) | Display issues | Words ("approximately") |
| Arrows (→⇒←) | Unicode issues | "to", "from" |
| Box drawing (╔═╗) | Encoding problems | Hyphens and equals |

### Approved Elements

| Approved | Usage |
|----------|-------|
| Write-Log | All script output |
| Plain ASCII text | Status messages |
| Hyphens (-) | List items, separators |
| Equals signs (=) | Section dividers |
| Numbers (1, 2, 3) | Numbered lists |
| Words | Status indicators |
| Log levels | INFO, WARN, ERROR, DEBUG |
| Spaces | Indentation |

---

## Integration with Standards

This document supplements [CODING_STANDARDS.md](CODING_STANDARDS.md):

- Include Write-Log function in all scripts
- Never use Write-Host with colors in production code
- Test scripts with Test-OutputFormat function
- Document output format in comment-based help
- Review logs to verify readability

**Checklist item:** "No emojis, symbols, or colors in output"

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Related Documents:** [CODING_STANDARDS.md](CODING_STANDARDS.md)  
**Next Review:** Quarterly or when issues identified
