# Window Layout Manager - Technical Plan

## Overview

Window Layout Manager is a PowerShell automation script that precisely positions application windows across multiple monitors using the Direct Border Overlap approach. Version 3.4 implements process creation time sorting to ensure consistent window selection order when multiple instances of the same application exist.

**Current Version:** 3.4  
**Script:** `scripts/utilities/Window Layout Manager.ps1`  
**Approach:** Direct Border Overlap (intentional window expansion)  
**Default Border:** 8px for Windows 10/11

## Core Concept

### Direct Border Overlap Technique

Windows have invisible borders (DWM-rendered) that create gaps when snapped side-by-side. This script eliminates gaps by intentionally overlapping windows by the border width.

**How it works:**
- Each window expands by BorderWidth pixels on left, right, and bottom edges
- Adjacent windows overlap in the border region
- The topmost window's border is visible, creating seamless appearance
- No DWM API calls required (simpler, more compatible)

**Trade-offs:**
- Windows overlap slightly (typically 8px)
- Only the topmost window has active resize handles in overlap area
- Simpler implementation than border compensation
- Fixed border width may not be perfect for all applications

## Features

### Window Positioning

- **left** - Window occupies left half of monitor
- **right** - Window occupies right half of monitor
- **full** - Window maximized to fill entire monitor

### Multi-Monitor Support

- Automatic monitor detection and enumeration
- Primary monitor always numbered as Monitor 1
- Secondary monitors sorted by position
- Cross-monitor window distribution
- Per-monitor zone calculation

### Configuration System

- Built-in layout profiles
- External configuration file support
- Per-window border overlap control
- Application name and title pattern filtering
- Monitor number assignment

### Smart Window Selection (v3.4 Enhanced)

- **Process StartTime sorting** - Windows sorted by creation time (oldest first)
- Priority-based window matching
- Title pattern filtering with wildcards
- Monitor affinity consideration
- Assignment tracking to prevent duplicates
- Process name matching (case-insensitive)

**StartTime Sorting Benefits:**
- Deterministic window selection order
- Oldest window selected first (e.g., left position)
- Consistent behavior across script executions
- Predictable layouts regardless of Z-order

## Architecture

### Script Structure

```
Window Layout Manager.ps1
├── Parameters
│   ├── LayoutProfile (optional)
│   ├── ConfigPath (optional)
│   ├── BorderWidth (default: 8)
│   └── DryRun (switch)
├── Layout Profiles
│   ├── 2xChrome1xVSCode
│   ├── 2xBDE2xSAP
│   ├── WebDev
│   ├── 2xChrome
│   └── MixedOverlap
├── Windows API Definitions
│   ├── Monitor enumeration
│   ├── Window enumeration
│   └── Window positioning
├── Functions
│   ├── Get-LayoutConfiguration
│   ├── Convert-WildcardToRegex
│   ├── Get-MonitorLayout
│   ├── Get-ApplicationWindows (v3.4: captures StartTime)
│   ├── Get-ZonesForMonitor
│   ├── Set-WindowSnapBorderOverlap
│   └── Select-WindowForRule (v3.4: sorts by StartTime)
└── Main Execution
    ├── Load configuration
    ├── Enumerate monitors
    ├── Enumerate windows
    ├── Process rules by monitor
    └── Apply window positioning
```

### Key Data Structures

**Window Placement Rule:**
```powershell
@{
    ApplicationName = 'chrome'           # Process name (without .exe)
    DisplayName     = 'Chrome Left'      # Friendly name for logs
    TitlePattern    = '*GitHub*'         # Optional wildcard pattern
    MonitorNumber   = 1                  # Target monitor (1-based)
    Position        = 'left'             # left/right/full
    UseOverlap      = $true              # Enable border overlap
}
```

**Monitor Object:**
```powershell
@{
    Handle        = [IntPtr]             # Monitor handle
    IsPrimary     = [bool]               # Is primary monitor
    DisplayNumber = [int]                # 1-based display number
    Bounds        = @{ X, Y, Width, Height }    # Full monitor bounds
    WorkArea      = @{ X, Y, Width, Height }    # Usable area (minus taskbar)
}
```

**Window Object (v3.4):**
```powershell
@{
    Handle        = [IntPtr]             # Window handle
    ProcessId     = [int]                # Process ID
    ProcessName   = [string]             # Process name
    StartTime     = [DateTime]           # Process creation time (v3.4)
    Title         = [string]             # Window title
    MonitorNumber = [int]                # Current monitor
    IsMaximized   = [bool]               # Maximized state
    Rect          = @{ X, Y, Width, Height }    # Current position
    AssignedToRule = [string]            # Assigned rule name
}
```

## Window Selection Algorithm (v3.4)

The script uses StartTime-based sorting to ensure consistent window selection:

### Selection Process

1. **Filter by process name** - Only windows matching ApplicationName
2. **Exclude assigned windows** - Skip windows already assigned to rules
3. **Apply title pattern** (if specified) - Filter by wildcard pattern
4. **Sort by StartTime** - Order candidates oldest to newest
5. **Apply monitor affinity** - Prefer windows on target monitor (within sorted order)
6. **Select oldest match** - Return first window from sorted list

### StartTime Sorting Logic

```powershell
# Separate windows by StartTime availability
$WithStartTime = $Candidates | Where-Object { $null -ne $_.StartTime }
$WithoutStartTime = $Candidates | Where-Object { $null -eq $_.StartTime }

# Sort by StartTime (oldest first)
$Sorted = @()
$Sorted += $WithStartTime | Sort-Object StartTime
$Sorted += $WithoutStartTime

# Apply monitor preference within sorted order
$OnTargetMonitor = $Sorted | Where-Object { $_.MonitorNumber -eq $TargetMonitor }
if ($OnTargetMonitor) {
    return $OnTargetMonitor | Select-Object -First 1  # Oldest on target
}

return $Sorted | Select-Object -First 1  # Oldest overall
```

### Example Behavior

If you have 3 Chrome windows:
- **Window A** - Opened at 6:00 PM (oldest)
- **Window B** - Opened at 6:15 PM
- **Window C** - Opened at 6:30 PM (newest)

With `2xChrome` profile:
- **ChromeLeft** rule → Selects Window A (6:00 PM)
- **ChromeRight** rule → Selects Window B (6:15 PM)
- **Unassigned** → Window C (6:30 PM) remains untouched

This ensures predictable, repeatable layouts regardless of window Z-order or enumeration order.

## Wildcard Pattern Matching

### Convert-WildcardToRegex Function

Converts wildcard patterns to regex for title matching:

```powershell
function Convert-WildcardToRegex {
    param([string]$Pattern)
    
    if ($Pattern -match '[*?]') {
        $Escaped = [regex]::Escape($Pattern)
        $Escaped = $Escaped -replace '\\\*', '.*'  # * -> .* (any chars)
        $Escaped = $Escaped -replace '\\\?', '.'   # ? -> . (single char)
        return $Escaped
    } else {
        return $Pattern
    }
}
```

### Pattern Examples

| Wildcard | Regex | Matches | Does Not Match |
|---|---|---|---|
| `*GitHub*` | `.*GitHub.*` | "GitHub - Chrome", "MyGitHub" | "chrome", "hub" |
| `*waf/script*` | `.*waf/script.*` | "waf/scripts/test.ps1" | "waf-scripts" |
| `Document1*` | `Document1.*` | "Document1.docx" | "Document2" |
| `*.xlsx*` | `.*\\.xlsx.*` | "Report.xlsx - Excel" | "Report.docx" |
| `*How Fast*` | `.*How Fast.*` | "How Fast Can You..." | "how fast" (case!) |

**Important:** Title pattern matching is **case-sensitive**.

## Border Overlap Control

### UseOverlap Parameter

Each window rule supports `UseOverlap` to control border behavior:

```powershell
UseOverlap = $true   # Apply border overlap (default)
UseOverlap = $false  # No overlap (precise positioning)
UseOverlap = $null   # Auto (false for 'full', true for 'left'/'right')
```

### Overlap Calculation

For `UseOverlap = $true`:
```
FinalX      = Zone.X - BorderWidth           # Expand left
FinalY      = Zone.Y                         # No top expansion
FinalWidth  = Zone.Width + (BorderWidth * 2) # Expand left + right
FinalHeight = Zone.Height + BorderWidth      # Expand bottom
```

For `UseOverlap = $false`:
```
FinalX      = Zone.X                         # No expansion
FinalY      = Zone.Y
FinalWidth  = Zone.Width
FinalHeight = Zone.Height
```

### Why No Top Expansion

The top edge is not expanded because:
- Taskbar is typically at bottom or sides
- Top expansion would conflict with title bar
- Windows native snap doesn't expand top
- Work area already accounts for taskbar

## Zone Calculation

Zones are calculated dynamically based on monitor work area:

### With Both Left and Right Rules

```
MidPoint = Floor(WorkArea.Width / 2)

left zone:
  X      = WorkArea.X
  Y      = WorkArea.Y
  Width  = MidPoint
  Height = WorkArea.Height

right zone:
  X      = WorkArea.X + MidPoint
  Y      = WorkArea.Y
  Width  = WorkArea.Width - MidPoint
  Height = WorkArea.Height
```

### With Only One Side Rule

Still splits at 50% for consistency:
```
HalfWidth = Floor(WorkArea.Width / 2)
```

This ensures windows positioned with single rule can later accommodate second window.

## Built-in Profiles

### 2xChrome1xVSCode

```powershell
Monitor 1: Chrome (left) + Chrome (right)
Monitor 2: VS Code (full)
```

Demonstrates multi-application layout with StartTime sorting for Chrome instances.

### 2xBDE2xSAP

```powershell
Monitor 1: BDE (left) + BDE (right)
Monitor 2: SAP (left) + SAP (right)
```

Dual-monitor layout with two applications, each having two instances.

### WebDev

```powershell
Monitor 1: Chrome Jira (left, *Jira*) + Chrome GitHub (right, *GitHub*)
Monitor 2: VS Code (full)
```

Demonstrates title pattern filtering combined with StartTime sorting.

### 2xChrome

```powershell
Monitor 1: Chrome (left) + Chrome (right)
```

Simple two-window layout where oldest Chrome window goes left.

### MixedOverlap

```powershell
Monitor 1: Chrome (left, UseOverlap=true) + Chrome (right, UseOverlap=false)
```

Demonstrates per-window overlap control.

## Usage Examples

### Apply Default Profile

```powershell
.\Window Layout Manager.ps1
```

Applies default 2xChrome configuration with StartTime sorting.

### Apply Named Profile

```powershell
.\Window Layout Manager.ps1 -LayoutProfile 'WebDev'
```

Applies WebDev profile with title filtering and StartTime sorting.

### Adjust Border Width

```powershell
.\Window Layout Manager.ps1 -LayoutProfile '2xChrome' -BorderWidth 7
```

Use 7px border for older Windows 10 builds.

### Dry Run Mode

```powershell
.\Window Layout Manager.ps1 -LayoutProfile 'WebDev' -DryRun
```

Shows what would happen without moving windows, including StartTime information.

### External Configuration

```powershell
.\Window Layout Manager.ps1 -ConfigPath 'C:\Config\MyLayout.xml'
```

Load configuration from external file.

## Custom Configuration

### Configuration File Format

```powershell
# Create configuration
$Config = @{
    ChromeLeft = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome Left'
        TitlePattern    = '*Documentation*'
        MonitorNumber   = 1
        Position        = 'left'
        UseOverlap      = $true
    }
    ChromeRight = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome Right'
        TitlePattern    = '*GitHub*'
        MonitorNumber   = 1
        Position        = 'right'
        UseOverlap      = $true
    }
}

# Export to file
$Config | Export-Clixml -Path 'C:\Config\MyLayout.xml'

# Use configuration
.\Window Layout Manager.ps1 -ConfigPath 'C:\Config\MyLayout.xml'
```

### Title Pattern Examples

```powershell
TitlePattern = '*GitHub*'          # Matches: 'GitHub - Chrome', 'MyGitHub Project'
TitlePattern = 'Document1*'        # Matches: 'Document1.docx', 'Document10'
TitlePattern = '*.xlsx*'           # Matches: 'Report.xlsx - Excel'
TitlePattern = '*Jira* - *'        # Matches: 'PROJ-123 - Jira - Chrome'
TitlePattern = $null               # No filtering (all windows)
```

**Important:** Title patterns are case-sensitive.

## Windows API Integration

### Monitor APIs

**EnumDisplayMonitors** - Enumerate all monitors
- Callback invoked for each monitor
- Returns monitor handle and bounds

**GetMonitorInfo** - Get monitor details
- Work area (minus taskbar)
- Primary monitor flag
- Full monitor bounds

**MonitorFromWindow** - Get window's monitor
- Returns monitor handle for window
- Used to determine current monitor

### Window APIs

**EnumWindows** - Enumerate all top-level windows
- Callback invoked for each window
- Returns window handle

**IsWindowVisible** - Check visibility
- Excludes hidden windows

**IsIconic** - Check if minimized
- Excludes minimized windows

**IsZoomed** - Check if maximized
- Used to track maximized state

**GetWindowRect** - Get window position
- Returns current rectangle

**GetWindowPlacement** - Get window placement
- Includes normal position (when not maximized)

**SetWindowPlacement** - Set window placement
- Restores window if maximized
- Sets normal position

**SetWindowPos** - Fine-tune position
- Used after SetWindowPlacement
- Ensures precise positioning

**ShowWindow** - Change window state
- Used to maximize windows (full position)

### Process Information (v3.4)

**Get-Process cmdlet** - Retrieve process details
- Returns Process object with StartTime property
- StartTime uses Windows API GetProcessTimes internally
- Gracefully handles access denied scenarios
- Some system processes may not expose StartTime

### Positioning Sequence

For `left` and `right` positions:
```
1. GetWindowPlacement - Get current placement
2. Modify rcNormalPosition - Set target rectangle
3. Set showCmd = SW_RESTORE - Restore if maximized
4. SetWindowPlacement - Apply placement
5. SetWindowPos - Fine-tune position with SWP_FRAMECHANGED
```

For `full` position:
```
1. ShowWindow(SW_MAXIMIZE) - Maximize window
```

## Logging and Diagnostics

### Log Levels

- **DEBUG** - Detailed internal operations (only with LogLevel = DEBUG)
- **INFO** - Standard operational messages (cyan color)
- **WARN** - Non-fatal issues (yellow warning)
- **ERROR** - Fatal errors (red color)

### Execution Summary (v3.4)

```
[2026-02-14 19:00:00] [INFO] ========================================
[2026-02-14 19:00:00] [INFO] Starting: Window Layout Manager.ps1 v3.4
[2026-02-14 19:00:00] [INFO] Using Direct Border Overlap approach
[2026-02-14 19:00:00] [INFO] Default border width: 8px
[2026-02-14 19:00:00] [INFO] ========================================
[2026-02-14 19:00:00] [INFO] Loading layout profile: 2xChrome
[2026-02-14 19:00:00] [INFO] Profile contains: 2xchrome
[2026-02-14 19:00:00] [INFO] Loaded 2 window placement rule(s)
[2026-02-14 19:00:00] [INFO] Enumerating monitors...
[2026-02-14 19:00:00] [INFO] Found 1 monitor(s)
[2026-02-14 19:00:00] [INFO]   Monitor 1: 1920x1080 at (0,0) [Primary]
[2026-02-14 19:00:00] [INFO] Enumerating application windows...
[2026-02-14 19:00:00] [INFO] Found 42 total visible windows
[2026-02-14 19:00:00] [INFO] Processing monitor 1...
[2026-02-14 19:00:00] [INFO] Applying rule 'ChromeLeft' (Chrome Left)...
[2026-02-14 19:00:00] [INFO]   Target: Monitor 1, Position: left
[2026-02-14 19:00:00] [INFO]   Border overlap: enabled
[2026-02-14 19:00:00] [INFO]   Found window: 'GitHub - Chrome' (PID: 12345) (started: 18:00:00)
[2026-02-14 19:00:00] [INFO]   Current: Monitor 1, 960x1040
[2026-02-14 19:00:00] [INFO]   Snapped with 8px overlap (zone: X=0, Y=0, W=960, H=1040)
[2026-02-14 19:00:00] [INFO] Applying rule 'ChromeRight' (Chrome Right)...
[2026-02-14 19:00:00] [INFO]   Target: Monitor 1, Position: right
[2026-02-14 19:00:00] [INFO]   Border overlap: enabled
[2026-02-14 19:00:00] [INFO]   Found window: 'Gmail - Chrome' (PID: 12346) (started: 18:15:00)
[2026-02-14 19:00:00] [INFO]   Current: Monitor 1, 960x1040
[2026-02-14 19:00:00] [INFO]   Snapped with 8px overlap (zone: X=960, Y=0, W=960, H=1040)
[2026-02-14 19:00:01] [INFO] Placement complete: 2 moved, 0 skipped
[2026-02-14 19:00:01] [INFO] Script execution completed successfully
[2026-02-14 19:00:01] [INFO] ========================================
[2026-02-14 19:00:01] [INFO] Execution Summary:
[2026-02-14 19:00:01] [INFO]   Duration: 1.2345678 seconds
[2026-02-14 19:00:01] [INFO]   Errors: 0
[2026-02-14 19:00:01] [INFO]   Warnings: 0
[2026-02-14 19:00:01] [INFO] ========================================
```

**Note:** v3.4 logs now include `(started: HH:mm:ss)` showing when each process was created.

### Sample Dry Run Output

```
[2026-02-14 19:00:00] [WARN] DRY RUN MODE - No changes will be made
...
[2026-02-14 19:00:00] [INFO]   Found window: 'GitHub - Chrome' (PID: 12345) (started: 18:00:00)
[2026-02-14 19:00:00] [INFO]   [DRY RUN] Would snap to left with 8px overlap (X=0, Y=0, W=960, H=1040)
```

## Error Handling

### Exit Codes

- **0** - Success (all windows positioned)
- **1** - General error (configuration, execution failure)
- **2** - Missing dependencies (PowerShell version, OS)
- **3** - Configuration error (invalid profile, file not found)

### Common Issues

**No matching window found**
- Process name doesn't match running applications
- Title pattern doesn't match any windows (check case sensitivity)
- Window already assigned to another rule

**Monitor not found**
- MonitorNumber exceeds available monitors
- Monitor disconnected during execution

**Failed to set window placement**
- Window handle invalid (window closed)
- Application blocking window movement
- System policy restriction

**Gaps still visible after overlap**
- Border width may need adjustment (try 7 or 9)
- Some applications have custom borders
- DPI scaling may affect measurements

**Title pattern not matching**
- Check case sensitivity ("GitHub" vs "github")
- Verify wildcards: `*text*` not `*text`
- Wildcard conversion bug fixed in v3.3

**StartTime unavailable (v3.4)**
- Some system processes deny StartTime access
- Windows without StartTime are sorted after those with StartTime
- Logged as DEBUG message, not a fatal error

## Performance Characteristics

### Execution Time

- Monitor enumeration: <100ms
- Window enumeration: 100-500ms (depends on window count)
- StartTime retrieval: <10ms per process (v3.4)
- Window positioning: 50-100ms per window
- Total typical: 2-5 seconds for 3-5 windows

### Complexity Analysis

- Monitor enumeration: O(m) where m = monitor count
- Window enumeration: O(n) where n = total window count
- StartTime sorting: O(n log n) for each application (v3.4)
- Window matching: O(n * r) where r = rule count
- Overall: O(n * r * log n) - sorting adds logarithmic factor

### Resource Usage

- Memory: ~20-30 MB
- CPU: Low (burst during enumeration and sorting)
- I/O: None (unless loading external config)

## Dependencies

- Windows PowerShell 5.1 or higher
- Windows 10/11 or Windows Server 2016+
- User32.dll (Windows API, always available)
- Execution Context: User (requires GUI session)
- Display: At least 1 monitor

## Limitations

### Current Limitations

1. **Three positions only** - left, right, full (no quadrants)
2. **Fixed border width** - Cannot detect actual DWM border
3. **Top-level windows only** - No child window support
4. **Case-sensitive patterns** - Title patterns respect case
5. **Single pattern per rule** - Cannot specify multiple patterns
6. **No window class filtering** - Cannot filter by window class name
7. **StartTime may be unavailable** - Some processes deny access (gracefully handled)

### Not Supported

- Vertical splits (top/bottom)
- Quadrant layouts (4-way split)
- Custom aspect ratios
- Window stacking (Z-order control)
- Animated transitions
- Window state persistence
- Dynamic border detection
- Command-line argument based selection (only process name)

## Future Enhancements

### Potential Improvements

1. **Dynamic border detection** - Auto-detect DWM border width
2. **Quadrant support** - top-left, top-right, bottom-left, bottom-right
3. **Custom zones** - User-defined zone positions and sizes
4. **GUI configuration editor** - Visual rule builder
5. **Window state persistence** - Save/restore layouts
6. **Case-insensitive patterns** - Optional case-insensitive title matching
7. **Multiple patterns per rule** - OR logic for title patterns
8. **Window class filtering** - Filter by window class name
9. **Animated positioning** - Smooth transitions
10. **Profile auto-detection** - Detect layout based on running apps
11. **Command-line based selection** - Distinguish processes by arguments

### Backward Compatibility

All enhancements should:
- Maintain existing parameter names
- Preserve default behavior
- Support existing configuration files
- Keep same exit code meanings

## Version History

### v3.4 (2026-02-14)
- **Added process StartTime sorting**
- Windows now sorted by creation time (oldest first)
- Ensures consistent window selection order
- Enhanced Get-ApplicationWindows to capture StartTime
- Modified Select-WindowForRule with StartTime-based sorting
- Graceful handling of processes without StartTime
- Logs show process start time for transparency

### v3.3 (2026-02-14)
- Fixed wildcard to regex conversion bug
- Corrected escape sequences in Convert-WildcardToRegex
- Wildcards now properly convert: `*` -> `.*`, `?` -> `.`
- Title pattern filtering now works correctly

### v3.2 (2026-02-14)
- Improved logging detail
- Added title pattern visibility in logs
- Enhanced error messages

### v3.1 (2026-02-14)
- Added UseOverlap per-window control
- Enhanced window selection algorithm
- Improved cross-monitor distribution

### v3.0 (2026-02-14)
- Initial Direct Border Overlap implementation
- Configurable border width parameter
- Profile-based configuration system
- Multi-monitor support
- Smart window selection
- DryRun mode

## Integration Points

### NinjaRMM Deployment

```powershell
# Deploy as scheduled script
# Run on user login or display change event

.\Window Layout Manager.ps1 -LayoutProfile 'WebDev'

# Capture exit code for monitoring
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Window layout failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}
```

### Scheduled Task

```xml
<Task>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Actions>
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "C:\Scripts\Window Layout Manager.ps1" -LayoutProfile "WebDev"</Arguments>
    </Exec>
  </Actions>
</Task>
```

### Group Policy Logon Script

```powershell
# GPO: User Configuration > Policies > Windows Settings > Scripts > Logon

powershell.exe -ExecutionPolicy Bypass -File "\\server\scripts\Window Layout Manager.ps1" -LayoutProfile "Corporate"
```

## Testing Strategy

### Test Scenarios

1. **Single monitor, 2 windows** - Verify left/right split with StartTime ordering
2. **Dual monitor, 4 windows** - Verify cross-monitor distribution
3. **Title pattern matching** - Verify wildcard filtering works
4. **No matching windows** - Verify graceful handling
5. **DryRun mode** - Verify no actual changes
6. **Border overlap** - Verify no gaps between windows
7. **Mixed overlap** - Verify UseOverlap per-window control
8. **Invalid profile** - Verify error handling
9. **Monitor disconnect** - Verify resilience
10. **Window close during execution** - Verify error recovery
11. **Multiple instances** - Verify StartTime sorting (oldest selected first)
12. **StartTime unavailable** - Verify graceful handling

### Validation Checks

- No gaps between left/right windows
- Windows positioned on correct monitors
- Title patterns filter correctly (case-sensitive)
- Wildcard conversion works: `*test*` -> `.*test.*`
- Maximized windows fill entire work area
- DryRun makes no changes
- Exit codes correct
- Logs show expected operations
- **Oldest window selected first (v3.4)**
- **StartTime logged correctly (v3.4)**

## Related Documentation

- **Get-ApplicationInstanceCount-Plan.md** - Companion script for counting windows
- **NinjaRMM Integration Guide** - Deployment documentation

## Conclusion

Window Layout Manager v3.4 provides a robust, production-ready solution for automated window positioning across multiple monitors. The Direct Border Overlap approach eliminates gaps while maintaining simplicity and compatibility. StartTime sorting ensures consistent, predictable window selection.

Key strengths:
- No DWM API complexity
- Configurable border overlap
- Per-window overlap control
- Profile-based configuration
- Smart window selection
- Cross-monitor awareness
- Fixed wildcard pattern matching (v3.3)
- **Process StartTime sorting (v3.4)**
- **Deterministic window order (v3.4)**
- Comprehensive logging with StartTime visibility
- DryRun mode for testing

Ideal for power users, developers, and enterprise deployments requiring consistent, repeatable window layouts across login sessions.
