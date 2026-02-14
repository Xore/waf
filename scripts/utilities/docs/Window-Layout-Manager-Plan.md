# Window Layout Manager - Technical Plan

## Overview

The Window Layout Manager is an automated PowerShell script that positions application windows across multiple monitors using configurable layout profiles. It implements a direct border overlap technique to eliminate gaps between side-by-side windows, mimicking Windows native snap behavior.

**Current Version:** 3.3  
**Script:** `scripts/utilities/Window Layout Manager.ps1`  
**Status:** Production-ready

## Core Concept

### Direct Border Overlap Approach

Instead of attempting to compensate for invisible DWM (Desktop Window Manager) borders, the script intentionally overlaps windows by a configurable border width (default 8px for Windows 10/11). This creates seamless adjacent window positioning without gaps.

**How it works:**
- Each window in a left/right position is expanded by BorderWidth pixels on left, right, and bottom
- Adjacent windows physically overlap in the border area
- The topmost window's border remains visible at edges
- No DWM API calls required (simpler, more compatible)

**Trade-offs:**
- Windows overlap slightly in border regions
- Only the topmost window has active resize handles in overlap area
- Fixed border width may not be perfect for all applications
- Per-window control via `UseOverlap` config option

## Features

### Window Positioning
- Three position types: `left`, `right`, `full`
- Automatic zone calculation based on monitor work area
- Dynamic zone splitting when both left and right rules exist on same monitor
- Full-screen windows are maximized using native Windows API

### Multi-Monitor Support
- Automatic monitor enumeration and numbering
- Primary monitor = 1, secondary monitors numbered by position
- Cross-monitor window distribution
- Monitor-aware window selection

### Configuration System
- Built-in layout profiles (2xChrome1xVSCode, 2xBDE2xSAP, WebDev, etc.)
- External configuration file support via `-ConfigPath`
- Per-window overlap control via `UseOverlap` parameter
- Wildcard title pattern matching

### Window Selection Intelligence
- Priority-based selection algorithm
- Preference for windows already on target monitor
- Cross-monitor conflict detection
- Application instance tracking to prevent double-assignment

## Architecture

### Script Structure

```
Window Layout Manager.ps1
├── Configuration Section
│   ├── Script metadata (version, timeouts)
│   ├── Layout profiles hashtable
│   └── Default configuration
├── Windows API Definitions
│   ├── RECT, MONITORINFO, WINDOWPLACEMENT structures
│   └── Win32 API imports (User32.dll)
├── Core Functions
│   ├── Write-Log (logging with levels)
│   ├── Get-LayoutConfiguration (profile loading)
│   ├── Get-MonitorLayout (monitor enumeration)
│   ├── Get-ApplicationWindows (window discovery)
│   ├── Get-ZonesForMonitor (zone calculation)
│   ├── Select-WindowForRule (smart window selection)
│   └── Set-WindowSnapBorderOverlap (window positioning)
└── Main Execution
    ├── Configuration loading
    ├── Monitor discovery
    ├── Window enumeration
    ├── Rule application per monitor
    └── Summary reporting
```

### Key Data Structures

#### Window Layout Rule
```powershell
@{
    ApplicationName = 'chrome'           # Process name to match
    DisplayName     = 'Chrome Left'      # Human-readable name
    TitlePattern    = '*GitHub*'         # Optional wildcard pattern
    MonitorNumber   = 1                  # Target monitor (1=primary)
    Position        = 'left'             # left|right|full
    UseOverlap      = $true              # Enable/disable border overlap
}
```

#### Monitor Object
```powershell
[PSCustomObject]@{
    Handle        = [IntPtr]             # Windows monitor handle
    IsPrimary     = [bool]
    DisplayNumber = [int]                # 1=primary, 2+secondary
    Bounds        = @{ X, Y, Width, Height }
    WorkArea      = @{ X, Y, Width, Height }  # Excludes taskbar
}
```

#### Window Object
```powershell
[PSCustomObject]@{
    Handle        = [IntPtr]             # Window handle
    ProcessId     = [int]
    ProcessName   = [string]             # e.g., 'chrome'
    Title         = [string]
    MonitorNumber = [int]                # Current monitor
    IsMaximized   = [bool]
    Rect          = @{ X, Y, Width, Height }
    AssignedToRule = [string]            # Tracks assignment
}
```

## Window Selection Algorithm

### Selection Priority (v3.3)

1. **Exact monitor match with title pattern**
   - Window on target monitor + matching title pattern
   - Highest priority to minimize cross-monitor moves

2. **Monitor reservation check**
   - Identifies other rules targeting same application on different monitors
   - Excludes windows from "reserved" monitors
   - Prevents cross-monitor conflicts

3. **Title pattern match on any monitor**
   - Window with matching title pattern on any monitor
   - Will be moved to target monitor

4. **Fallback selection**
   - Any unassigned window of matching process name
   - Logs warning if no suitable windows remain

### Assignment Tracking

Each window has an `AssignedToRule` property set when selected. This prevents:
- Double-assignment of same window to multiple rules
- Cross-monitor conflicts when multiple rules target same application
- Incorrect window distribution

## Border Overlap Control

### UseOverlap Parameter

Each rule can specify overlap behavior:

```powershell
UseOverlap = $true   # Default - apply 8px overlap (no gaps)
UseOverlap = $false  # Precise positioning (may show gaps)
UseOverlap = $null   # Auto: false for 'full', true for left/right
```

### Overlap Calculation

For left/right positions with `UseOverlap = $true`:
```
FinalX      = Zone.X - BorderWidth
FinalY      = Zone.Y
FinalWidth  = Zone.Width + (BorderWidth * 2)
FinalHeight = Zone.Height + BorderWidth
```

For `UseOverlap = $false` or `full` position:
```
FinalX      = Zone.X
FinalY      = Zone.Y
FinalWidth  = Zone.Width
FinalHeight = Zone.Height
```

## Zone Calculation

### Dynamic Zone Splitting

Zones adapt based on rules defined for each monitor:

**When both left AND right rules exist:**
- Split at exact midpoint for symmetry
- Left zone: 0 to MidPoint
- Right zone: MidPoint to Width

**When only left OR right rule exists:**
- Default 50/50 split using HalfWidth
- Allows manual window placement in unused half

**Full position:**
- Always spans entire work area
- Maximized via Windows API (not resized)

### Work Area Respect

All zones use monitor WorkArea (excludes taskbar) instead of full Bounds:
```powershell
$WA = $Monitor.WorkArea  # Accounts for taskbar automatically
```

## Built-in Profiles

### 2xChrome1xVSCode
Two Chrome windows (left/right) on monitor 1, VS Code fullscreen on monitor 2.

### 2xBDE2xSAP
Two BDE windows on monitor 1, two SAP windows on monitor 2.

### WebDev
Chrome windows filtered by title (Jira/GitHub) on monitor 1, VS Code fullscreen on monitor 2.

### 2xChrome
Two Chrome windows side-by-side on monitor 1.

### MixedOverlap
Demonstrates per-window overlap control - left window with overlap, right without.

## Usage Examples

### Basic Profile Application
```powershell
.\Window Layout Manager.ps1 -LayoutProfile '2xChrome'
```

### Custom Border Width
```powershell
.\Window Layout Manager.ps1 -LayoutProfile '2xChrome' -BorderWidth 7
```

### Dry Run Mode
```powershell
.\Window Layout Manager.ps1 -LayoutProfile 'WebDev' -DryRun
```

### External Configuration
```powershell
.\Window Layout Manager.ps1 -ConfigPath 'C:\Configs\layout.xml'
```

### No Profile (Default Config)
```powershell
.\Window Layout Manager.ps1
# Uses $DefaultWindowLayoutConfig
```

## Custom Configuration

### Creating External Config

```powershell
$CustomConfig = @{
    Edge1 = @{
        ApplicationName = 'msedge'
        DisplayName     = 'Edge Browser 1'
        TitlePattern    = $null
        MonitorNumber   = 1
        Position        = 'left'
        UseOverlap      = $true
    }
    Edge2 = @{
        ApplicationName = 'msedge'
        DisplayName     = 'Edge Browser 2'
        TitlePattern    = $null
        MonitorNumber   = 1
        Position        = 'right'
        UseOverlap      = $true
    }
    Teams = @{
        ApplicationName = 'Teams'
        DisplayName     = 'Microsoft Teams'
        TitlePattern    = $null
        MonitorNumber   = 2
        Position        = 'full'
        UseOverlap      = $null
    }
}

$CustomConfig | Export-Clixml -Path 'C:\Configs\my-layout.xml'

.\Window Layout Manager.ps1 -ConfigPath 'C:\Configs\my-layout.xml'
```

### Title Pattern Examples

```powershell
# Match any window containing "GitHub"
TitlePattern = '*GitHub*'

# Match windows starting with "Project"
TitlePattern = 'Project*'

# Match specific window title
TitlePattern = 'My Document.docx - Word'

# No pattern (match any window)
TitlePattern = $null
```

## Windows API Integration

### Key APIs Used

- **EnumDisplayMonitors** - Enumerate all monitors
- **GetMonitorInfo** - Get monitor bounds and work area
- **MonitorFromWindow** - Determine window's current monitor
- **EnumWindows** - Enumerate all top-level windows
- **GetWindowThreadProcessId** - Get process ID from window
- **IsWindowVisible** - Filter visible windows
- **IsIconic** - Filter minimized windows
- **IsZoomed** - Check if window is maximized
- **GetWindowRect** - Get window position and size
- **GetWindowPlacement** - Get window state and position
- **SetWindowPlacement** - Set window state and position
- **SetWindowPos** - Final positioning with flags
- **ShowWindow** - Maximize or restore window

### Window Positioning Sequence

1. **Get current placement** via GetWindowPlacement
2. **Set showCmd to SW_RESTORE** (un-maximize if needed)
3. **Calculate final rectangle** with optional overlap
4. **Update rcNormalPosition** in WINDOWPLACEMENT structure
5. **Apply via SetWindowPlacement**
6. **Force refresh via SetWindowPos** with SWP_FRAMECHANGED

For full-screen windows:
1. **ShowWindow with SW_MAXIMIZE** (native Windows maximize)

## Logging and Diagnostics

### Log Levels

- **DEBUG** - Verbose details (only if $LogLevel = 'DEBUG')
- **INFO** - Standard operational messages (cyan)
- **WARN** - Non-fatal issues (yellow, increments warning count)
- **ERROR** - Fatal errors (red, increments error count)

### Execution Summary

```
========================================
Execution Summary:
  Duration: 2.34 seconds
  Errors: 0
  Warnings: 0
========================================
```

### Typical Log Output

```
[2026-02-14 03:00:00] [INFO] Starting: Window Layout Manager.ps1 v3.3
[2026-02-14 03:00:00] [INFO] Using Direct Border Overlap approach
[2026-02-14 03:00:00] [INFO] Default border width: 8px
[2026-02-14 03:00:01] [INFO] Loading layout profile: 2xChrome
[2026-02-14 03:00:01] [INFO] Profile contains: 2xchrome
[2026-02-14 03:00:01] [INFO] Found 2 monitor(s)
[2026-02-14 03:00:01] [INFO]   Monitor 1: 1920x1080 at (0,0) [Primary]
[2026-02-14 03:00:01] [INFO]   Monitor 2: 1920x1080 at (1920,0)
[2026-02-14 03:00:01] [INFO] Found 47 total visible windows
[2026-02-14 03:00:01] [INFO] Processing monitor 1...
[2026-02-14 03:00:01] [INFO] Applying rule 'ChromeLeft' (Chrome Left)...
[2026-02-14 03:00:01] [INFO]   Target: Monitor 1, Position: left
[2026-02-14 03:00:01] [INFO]   Border overlap: enabled
[2026-02-14 03:00:01] [INFO]   PRIORITY: Selected window already on target monitor 1
[2026-02-14 03:00:01] [INFO]   Found window: 'GitHub - Chrome' (PID: 12345)
[2026-02-14 03:00:01] [INFO]   Current: Monitor 1, 960x1040
[2026-02-14 03:00:01] [INFO]   Snapped with 8px overlap (zone: X=0, Y=0, W=960, H=1040)
[2026-02-14 03:00:02] [INFO] Placement complete: 2 moved, 0 skipped
```

## Error Handling

### Exit Codes

- **0** - Success (no errors)
- **1** - General error or execution failure
- **2** - Missing dependencies (reserved, not currently used)
- **3** - Configuration error (reserved, not currently used)

### Common Issues

**No monitors detected**
- Rare edge case with API failure
- Script throws exception and exits

**No matching window found**
- Logged as WARN, not fatal
- Rule skipped, continues with next rule
- Check ApplicationName matches process name exactly

**Monitor number not found**
- Logged as WARN
- All rules for that monitor skipped
- Check monitor numbering (1=primary)

**Title pattern no matches**
- Logged as DEBUG
- Rule skipped
- Verify wildcard pattern syntax

## Performance Characteristics

- **Typical Duration:** 2-5 seconds
- **Timeout Setting:** 30 seconds (not enforced, informational)
- **Window Enumeration:** O(n) where n = total visible windows
- **Rule Application:** O(m) where m = number of rules
- **No User Interaction:** Fully automated, no prompts

## Dependencies

- Windows PowerShell 5.1 or higher
- Windows 10/11 or Windows Server 2016+
- User32.dll (Windows API, always available)
- Execution Context: User or SYSTEM (both supported)

## Limitations

### Current Limitations

1. **Process name matching only** - Cannot distinguish multiple instances by command-line arguments
2. **Fixed border width** - Not dynamically detected per application
3. **No window state preservation** - Always applies configured layout
4. **Single execution model** - Not a persistent service
5. **Left/right/full only** - No quadrant or custom zones

### Not Supported

- Custom zone shapes or percentages
- Window stacking (z-order control)
- Application launching
- Process priority changes
- Multi-desktop support (Windows Virtual Desktops)
- Per-application border width detection

## Future Enhancements

### Potential Improvements

1. **Dynamic border detection** - Query DwmGetWindowAttribute per application
2. **Quadrant zones** - Support 4-way split (top-left, top-right, etc.)
3. **Custom percentages** - Allow non-50/50 splits
4. **Window state caching** - Remember original positions for restore
5. **Watch mode** - Persistent background process responding to display changes
6. **GUI configuration editor** - Visual layout designer
7. **Application launcher integration** - Start apps before positioning
8. **Profile hotkeys** - Apply profiles via keyboard shortcuts

## Version History

### v3.3 (2026-02-14)
- Enhanced cross-monitor window selection
- Strong monitor affinity priority
- Monitor reservation to prevent conflicts
- Improved debug logging for selection process

### v3.2 (2026-02-14)
- Added per-window `UseOverlap` config option
- Support for mixed overlap scenarios
- Auto-detect overlap for full-screen windows

### v3.1 (2026-02-14)
- Improved window selection logging
- Better cross-monitor awareness
- Fixed double-assignment bugs

### v3.0 (2026-02-14)
- Complete rewrite using Direct Border Overlap approach
- Removed DWM API dependencies
- Added profile system
- Multi-monitor support
- Smart window selection

## Integration Points

### NinjaRMM Integration

Deploy as unattended script:
```powershell
# Via NinjaRMM script deployment
powershell.exe -ExecutionPolicy Bypass -File "Window Layout Manager.ps1" -LayoutProfile "2xChrome" -ErrorAction Stop
```

### Scheduled Task Triggers

- User logon
- Display configuration change (via Event ID 112)
- Manual execution via shortcut

### Group Policy

Deploy via GPO logon script with custom profile per user group.

## Testing Strategy

### Test Scenarios

1. **Single monitor, 2 windows (left/right)**
2. **Dual monitor, mixed positions**
3. **Same application on multiple monitors**
4. **Title pattern filtering**
5. **Missing windows (fewer than rules)**
6. **Extra windows (more than rules)**
7. **Maximized window handling**
8. **Border overlap on/off comparison**
9. **DryRun mode verification**
10. **External config file loading**

### Validation Checks

- Windows positioned without gaps (with UseOverlap=true)
- Correct monitor assignment
- No double-assignment of windows
- Proper handling of missing applications
- Work area respected (no taskbar overlap)
- Exit code accuracy

## Related Scripts

- **Window Layout Manager GUI.ps1** - Visual interface for layout design
- **Window Layout Manager 3.ps1** - Latest development version (identical to main)

## Conclusion

The Window Layout Manager provides a robust, API-driven approach to automated window positioning with minimal user interaction. The Direct Border Overlap technique delivers gap-free adjacent windows without complex DWM calculations. The profile system and multi-monitor support make it suitable for diverse enterprise and personal productivity scenarios.

Key strengths:
- Simple, maintainable architecture
- No external dependencies
- Predictable behavior
- Extensive logging
- Production-ready error handling

Ideal for environments requiring consistent window layouts across workstations, especially when integrated with endpoint management tools like NinjaRMM.
