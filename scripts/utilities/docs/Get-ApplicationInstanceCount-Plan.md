# Get-ApplicationInstanceCount - Technical Plan

## Overview

Get-ApplicationInstanceCount is a lightweight PowerShell utility that counts running instances of a specified application. It supports optional window title filtering using wildcard patterns and returns a clean integer count suitable for monitoring, alerting, and automation workflows.

**Current Version:** 1.2  
**Script:** `scripts/utilities/Get-ApplicationInstanceCount.ps1`  
**Status:** Production-ready

## Purpose

Provide a simple, reliable way to:
- Monitor application instance counts for alerting thresholds
- Validate application launch success
- Inventory open documents by title pattern
- Create conditional logic in automation workflows
- Track resource usage by counting specific application windows

## Core Functionality

### Process Name Matching

Matches windows by process name (without .exe extension):
- Case-insensitive matching
- Exact process name match only
- Examples: `chrome`, `EXCEL`, `notepad`, `Teams`

### Title Pattern Filtering

Optional wildcard pattern to filter by window title:
- Supports `*` (any characters) and `?` (single character)
- Case-sensitive regex matching after conversion
- Examples: `*GitHub*`, `Document1*`, `*Meeting - Teams`
- If omitted, counts all windows of the process

### Window Visibility Rules

By default, only counts:
- Visible windows (not hidden)
- Non-minimized windows (not iconic)

With `-IncludeMinimized` switch:
- Includes minimized windows in count
- Still requires visibility (excludes truly hidden windows)

## Parameters

### ProcessName (Required)

```powershell
-ProcessName 'chrome'
```

- Type: String
- Mandatory: Yes
- Description: Process name without .exe extension
- Case-insensitive
- Must match exact process name

### TitlePattern (Optional)

```powershell
-TitlePattern '*GitHub*'
```

- Type: String
- Mandatory: No
- Default: Empty (no filtering)
- Description: Wildcard pattern for window title matching
- Supports `*` and `?` wildcards
- Converted to regex internally
- Case-sensitive matching

### IncludeMinimized (Optional)

```powershell
-IncludeMinimized
```

- Type: Switch
- Mandatory: No
- Default: False
- Description: Include minimized windows in count
- Without this, only active/visible windows counted

### Quiet (Optional)

```powershell
-Quiet
```

- Type: Switch
- Mandatory: No
- Default: False
- Description: Suppress all output except final count
- Ideal for scripting and automation
- No log messages, no verbose output

## Output Format

### Standard Mode

```
[2026-02-14 18:00:00] [INFO] ========================================
[2026-02-14 18:00:00] [INFO] Get-ApplicationInstanceCount v1.2
[2026-02-14 18:00:00] [INFO] ========================================
[2026-02-14 18:00:00] [INFO] Starting enumeration for process: chrome
[2026-02-14 18:00:00] [INFO] Using title pattern: '*GitHub*' (regex: '.*GitHub.*')
[2026-02-14 18:00:00] [INFO] Excluding minimized windows
[2026-02-14 18:00:00] [INFO]   Window matched - Process: chrome, Title: 'GitHub - Google Chrome'
[2026-02-14 18:00:00] [INFO] Enumeration complete - Found 1 instance(s)
1
[2026-02-14 18:00:00] [INFO] ========================================
[2026-02-14 18:00:00] [INFO] Script execution completed successfully
[2026-02-14 18:00:00] [INFO] ========================================
```

### Quiet Mode

```
1
```

Only the integer count is output - no log messages.

### Error Handling

On error, outputs `0` and exits with code `0`:
- Prevents monitoring systems from treating as failure
- Zero is valid count (application not running)
- Actual errors logged to stderr if not in quiet mode

## Usage Examples

### Basic Count

```powershell
.\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome'
# Output: 3 (with logs)
```

Counts all visible Chrome windows.

### Count with Title Filter

```powershell
.\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -TitlePattern '*GitHub*'
# Output: 1 (with logs)
```

Counts Chrome windows with "GitHub" in title.

### Count Excel Files

```powershell
.\Get-ApplicationInstanceCount.ps1 -ProcessName 'EXCEL' -TitlePattern '*.xlsx*'
# Output: 2
```

Counts Excel windows with .xlsx files.

### Include Minimized

```powershell
.\Get-ApplicationInstanceCount.ps1 -ProcessName 'Teams' -IncludeMinimized
# Output: 1
```

Counts Teams windows including minimized.

### Quiet Mode for Scripting

```powershell
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
if ($count -gt 5) {
    Write-Host "Too many Chrome windows!"
}
```

Capture count and use in conditional logic.

### NinjaRMM Custom Field

```powershell
$chromeCount = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
Ninja-Property-Set chromeInstanceCount $chromeCount
```

Store count in NinjaRMM custom field for monitoring.

### Alert on Threshold

```powershell
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
if ($count -eq 0) {
    Write-Host "ALERT: Chrome is not running!"
    exit 1
}
```

Alert if application not running.

### Validate Launch

```powershell
Start-Process 'chrome.exe' -ArgumentList 'https://github.com'
Start-Sleep -Seconds 3

$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -TitlePattern '*GitHub*' -Quiet
if ($count -gt 0) {
    Write-Host "Chrome launched successfully"
} else {
    Write-Host "ERROR: Chrome failed to launch"
    exit 1
}
```

Validate application launched with specific window.

## Architecture

### Script Flow

```
1. Parse Parameters
   ├── Validate ProcessName (required)
   ├── Check TitlePattern (optional)
   ├── Check IncludeMinimized flag
   └── Check Quiet flag

2. Initialize
   ├── Set ErrorActionPreference = Stop
   ├── Initialize InstanceCount = 0
   └── Log startup (unless Quiet)

3. Convert Title Pattern
   ├── If TitlePattern provided
   ├── Convert wildcards to regex
   └── Escape special characters

4. Enumerate Windows
   ├── Call EnumWindows API
   ├── For each window:
   │   ├── Check IsWindowVisible
   │   ├── Check IsIconic (if not IncludeMinimized)
   │   ├── Get ProcessId from window
   │   ├── Get Process object
   │   ├── Match ProcessName
   │   ├── Get window title (if pattern provided)
   │   ├── Match title regex (if pattern provided)
   │   └── Increment counter if all match
   └── Continue until all windows processed

5. Output Result
   ├── Write-Output <count>
   └── Exit 0
```

### Windows API Usage

**EnumWindows** - Enumerate all top-level windows
- Callback function invoked for each window
- Returns true to continue enumeration

**IsWindowVisible** - Check if window is visible
- Excludes hidden windows (not on taskbar)
- System windows often hidden

**IsIconic** - Check if window is minimized
- Used with IncludeMinimized flag
- Minimized windows still visible but iconic

**GetWindowThreadProcessId** - Get process ID from window handle
- Required to match window to process
- Returns thread ID and process ID

**GetWindowText** - Retrieve window title text
- Used when TitlePattern provided
- Returns full window title string

**GetWindowTextLength** - Get title length before allocation
- Optimize StringBuilder size
- Avoids over-allocation

## Pattern Matching

### Wildcard to Regex Conversion

```powershell
function Convert-WildcardToRegex {
    param([string]$Pattern)
    
    if ($Pattern -match '[*?]') {
        $Escaped = [regex]::Escape($Pattern)  # Escape special chars
        $Escaped = $Escaped -replace '\*', '.*'  # * -> .*
        $Escaped = $Escaped -replace '\?', '.'   # ? -> .
        return $Escaped
    } else {
        return [regex]::Escape($Pattern)
    }
}
```

### Pattern Examples

| Wildcard Pattern | Regex Pattern | Matches | Does Not Match |
|---|---|---|---|
| `*GitHub*` | `.*GitHub.*` | "GitHub - Chrome", "MyGitHub" | "chrome", "hub" |
| `Document1*` | `Document1.*` | "Document1.docx", "Document10" | "Document2.docx" |
| `*.xlsx*` | `.*\.xlsx.*` | "Report.xlsx - Excel" | "Report.docx" |
| `???-???` | `...-...` | "ABC-123" | "AB-12", "ABCD-1234" |
| `*How Fast*` | `.*How Fast.*` | "How Fast Can You..." | "how fast" (lowercase) |

### Case Sensitivity

- Process name matching: **Case-insensitive**
- Title pattern matching: **Case-sensitive** (regex default)

To make title pattern case-insensitive:
```powershell
$WindowTitle -match "(?i)$TitleRegex"
```

## Performance

### Execution Time

- Typical: **<1 second**
- With many windows (100+): **1-2 seconds**
- Depends on: Total window count, title matching complexity

### Resource Usage

- Memory: Minimal (~5-10 MB)
- CPU: Low (single enumeration pass)
- I/O: None (no file operations)

### Optimization

- Single EnumWindows pass (O(n) where n = window count)
- Early exit checks (visibility, minimized state)
- StringBuilder pre-allocation for title retrieval
- No disk I/O or network calls

## Error Handling

### Exit Codes

- **0** - Always returns 0 (success)
- Count of 0 is not an error (application not running)
- Actual errors logged to stderr, output 0

### Error Scenarios

**Process access denied**
- System processes may deny access
- Window skipped, enumeration continues
- Does not increment count

**Invalid process name**
- No matches found
- Returns 0 (valid result)
- Not treated as error

**API call failure**
- Rare edge case (memory, system state)
- Try-catch wraps entire execution
- Outputs 0 on catastrophic failure

**Invalid pattern syntax**
- Regex conversion handles most wildcards
- Complex patterns may cause regex error
- Try-catch prevents script crash

## Logging

### Log Levels

**INFO** - Standard operational messages
- Startup, parameters, matches found
- Shown by default unless -Quiet specified
- Output to stdout with cyan color

**WARN** - Non-fatal issues
- Currently unused (no warning scenarios)

**ERROR** - Fatal errors
- Logged to stderr even in Quiet mode
- Includes exception details

### Verbosity Control

```powershell
# Standard output with logs (default)
.\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome'

# Quiet mode - no logs, only count
.\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet

# Capture output without logs
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
```

## Use Cases

### Monitoring & Alerting

```powershell
# NinjaRMM condition: Alert if Chrome count > 10
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
if ($count -gt 10) {
    Write-Host "WARNING: $count Chrome instances running"
    exit 1
}
```

### Application Validation

```powershell
# Check if required app is running
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'VPNClient' -Quiet
if ($count -eq 0) {
    Write-Host "ERROR: VPN not connected"
    Start-Process 'C:\Program Files\VPN\VPNClient.exe'
    Start-Sleep -Seconds 5
}
```

### Document Inventory

```powershell
# Count open Excel budget files
$budgetFiles = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'EXCEL' -TitlePattern '*Budget*' -Quiet
Write-Host "$budgetFiles budget file(s) currently open"
```

### Resource Management

```powershell
# Close excess Chrome instances
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
if ($count -gt 5) {
    Write-Host "Too many Chrome instances ($count), closing oldest..."
    Get-Process chrome | Sort-Object StartTime | Select-Object -First ($count - 5) | Stop-Process
}
```

### Pre-deployment Check

```powershell
# Ensure app not running before deployment
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'MyApp' -Quiet
if ($count -gt 0) {
    Write-Host "ERROR: MyApp is running. Close before deploying."
    exit 1
}

# Proceed with deployment
MsiExec.exe /i MyApp.msi /quiet
```

## Integration

### NinjaRMM Integration

**Custom Field Population**
```powershell
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
Ninja-Property-Set applicationInstanceCount $count
```

**Condition-based Alert**
```powershell
# In NinjaRMM script condition
$count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
if ($count -gt 10) {
    Write-Host "Alert: Too many Chrome instances"
    exit 1
}
```

### Scheduled Task

```xml
<Task>
  <Actions>
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "C:\Scripts\Get-ApplicationInstanceCount.ps1" -ProcessName "chrome" -Quiet</Arguments>
    </Exec>
  </Actions>
  <Triggers>
    <TimeTrigger>
      <Repetition>
        <Interval>PT15M</Interval>
      </Repetition>
    </TimeTrigger>
  </Triggers>
</Task>
```

Runs every 15 minutes to monitor Chrome instance count.

### PowerShell Workflow

```powershell
workflow Monitor-Applications {
    $chromeCount = InlineScript {
        .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
    }
    
    $teamsCount = InlineScript {
        .\Get-ApplicationInstanceCount.ps1 -ProcessName 'Teams' -Quiet
    }
    
    Write-Output "Chrome: $chromeCount, Teams: $teamsCount"
}
```

## Version History

### v1.2 (2026-02-14)
- Fixed wildcard to regex conversion bug
- Corrected escape sequences in pattern matching
- Wildcards now properly convert: `*` -> `.*`, `?` -> `.`
- Fixed `-Quiet` flag - logs now show by default, suppressed with flag
- Changed INFO log output from Write-Verbose to Write-Host

### v1.1 (2026-02-14)
- Fixed Quiet flag behavior
- INFO logs now visible by default
- Quiet mode properly suppresses all logs

### v1.0 (2026-02-14)
- Initial release
- Process name matching
- Wildcard title pattern support
- Include/exclude minimized windows
- Quiet mode for scripting
- Verbose logging

## Limitations

### Current Limitations

1. **Process name only** - Cannot distinguish by executable path
2. **Single pattern** - Only one title pattern per execution
3. **Case-sensitive title matching** - Pattern matching respects case
4. **No process arguments** - Cannot filter by command-line args
5. **No child window support** - Only top-level windows counted
6. **No UWP app detection** - Universal Windows Platform apps may not be detected correctly

### Not Supported

- Counting processes without windows (background services)
- Filtering by window state (normal/maximized)
- Filtering by window position or size
- Multi-monitor awareness
- Process tree hierarchy
- Window class name filtering

## Future Enhancements

### Potential Improvements

1. **Multiple patterns** - Support array of title patterns with OR logic
2. **Case-insensitive title matching** - Add -CaseInsensitive switch
3. **Window state filtering** - Add -OnlyMaximized, -OnlyNormal switches
4. **JSON output** - Add -OutputFormat JSON for structured data
5. **Process argument filtering** - Match by command-line arguments
6. **UWP app support** - Better detection of modern Windows apps
7. **Window class filtering** - Filter by window class name
8. **Monitor-specific counting** - Count windows on specific monitor

### Backward Compatibility

All enhancements should maintain backward compatibility:
- New parameters as optional switches
- Default behavior unchanged
- Integer output format preserved

## Testing

### Test Scenarios

1. **No instances running** - Returns 0
2. **Single instance** - Returns 1
3. **Multiple instances** - Returns accurate count
4. **Title pattern match** - Filters correctly
5. **Title pattern no match** - Returns 0
6. **Invalid process name** - Returns 0 (not error)
7. **Minimized windows excluded** - Default behavior
8. **Minimized windows included** - With -IncludeMinimized
9. **Quiet mode** - Only integer output
10. **Standard mode** - Full logging with cyan color
11. **Case-sensitive patterns** - `*GitHub*` matches "GitHub", not "github"

### Validation Checks

- Count matches manual Task Manager count
- Title pattern correctly filters windows
- Wildcard conversion works: `*test*` -> `.*test.*`
- Minimized window handling correct
- No errors on empty results
- Clean integer output in Quiet mode
- Logs appear by default (not in Quiet mode)

## Dependencies

- Windows PowerShell 5.1 or higher
- Windows 10/11 or Windows Server 2016+
- User32.dll (Windows API, always available)
- Execution Context: User or SYSTEM (both supported)

## Related Scripts

- **Window Layout Manager.ps1** - Positions application windows (uses same pattern matching)
- **Get-Process** - Native PowerShell cmdlet (no window title filtering)

## Conclusion

Get-ApplicationInstanceCount provides a simple, focused utility for counting application instances with optional title filtering. Its clean integer output and quiet mode make it ideal for monitoring, alerting, and automation workflows.

Key strengths:
- Simple, single-purpose design
- No external dependencies
- Fast execution (<1 second)
- Clean output for scripting
- Comprehensive logging when needed
- Fixed wildcard pattern matching (v1.2)
- Proper logging control with -Quiet flag

Ideal for NinjaRMM monitoring, pre-deployment checks, resource management, and automated validation workflows.
