# Window Layout Manager - Implementation Plan

**Document Version:** 1.3  
**Created:** 2026-02-14  
**Updated:** 2026-02-14  
**Author:** Windows Automation Framework  
**Script:** Window Layout Manager 1.ps1 v1.3

---

## Overview

This document outlines the design and implementation of the Window Layout Manager script, which automatically positions application windows across multiple monitors based on configuration profiles or hashtables.

---

## Current Status

### Version 1.3 - Implemented Features

- Monitor detection using Windows API with correct display numbering
- WorkArea-based positioning (respects taskbar)
- Profile-based configuration system
- Multiple preset profiles (2xChrome, 2xChrome1xVSCode, WebDev, etc.)
- Window assignment tracking to prevent double-assignment
- Title pattern matching using wildcard syntax
- Snap-to-edge logic for left/right windows
- Proper window placement using WINDOWPLACEMENT API
- DryRun mode for testing
- External configuration file support

### Known Issues

**Issue: Small gaps between snapped windows on Windows 10**
- **Cause:** Windows 10 adds invisible extended window frames (DWM borders) around windows, typically 7 pixels on left/right/bottom
- **Symptom:** Even with perfect WorkArea calculations, SetWindowPlacement positions the window INCLUDING the invisible border, creating visible gaps
- **Status:** ACTIVE - Needs DwmGetWindowAttribute fix (see Future Enhancements)
- **Workaround:** None currently - gaps are inherent to SetWindowPlacement behavior

---

## Key Requirements

### Functional Requirements

1. **Monitor Detection**
   - Detect all monitors exactly as Windows displays them in "Display settings"
   - Use the same numbering (1, 2, 3...) as shown in Windows
   - Account for taskbar in all calculations (use WorkArea, not full Bounds)

2. **Window Placement**
   - Support three placement zones: `left`, `right`, `full`
   - Move windows to specified monitor and zone
   - Only move exactly the number of windows declared in configuration

3. **Multiple Windows Handling**
   - Support multiple windows of same application (e.g., two Chrome windows)
   - Each rule targets exactly ONE window
   - Track which windows have been assigned to prevent double-assignment
   - If 2 Chrome rules exist, move exactly 2 Chrome windows (not more)

4. **Snap-to-Edge Logic**
   - When both `left` and `right` rules exist on same monitor, snap them together
   - Minimize gap between left and right windows
   - Handle integer division rounding correctly

5. **Profile System**
   - Predefined layout profiles for common scenarios
   - Command-line profile selection via -LayoutProfile parameter
   - Default configuration when no profile specified

---

## Configuration Structure

### Profile-Based Configuration (Current)

```powershell
# Usage
.\Window Layout Manager 1.ps1 -LayoutProfile '2xChrome'
```

### Hashtable Format

```powershell
$WindowLayoutConfig = @{
    # Unique key for each rule
    RuleName = @{
        ApplicationName = 'processname'    # Process name (e.g., 'chrome', 'Code')
        DisplayName     = 'Friendly Name'  # For logging/debugging
        TitlePattern    = 'pattern|null'   # Optional: wildcard pattern to match window title
        MonitorNumber   = 1                # Target monitor (1, 2, 3...)
        Position        = 'left'           # 'left', 'right', or 'full'
    }
}
```

### Available Profiles (v1.3)

| Profile | Description | Windows |
|---------|-------------|----------|
| `2xChrome` | Two Chrome windows side by side | 2x Chrome (left, right) |
| `2xChrome1xVSCode` | Development setup | 2x Chrome (mon 1), VS Code full (mon 2) |
| `3xChrome` | Triple Chrome | 2x Chrome (mon 1), 1x Chrome full (mon 2) |
| `WebDev` | Web development | Chrome Jira, Chrome GitHub, VS Code |
| `2xBDE2xSAP` | Business apps | 2x BDE, 2x SAP |
| `DataAnalysis` | Data work | Excel left, Power BI right |
| `EmailCalendar` | Outlook workflow | Outlook Mail left, Calendar right |
| `MeetingSetup` | Meeting mode | Teams left, OneNote right |

### Example Configurations

#### Basic Split (Default)
```powershell
$DefaultWindowLayoutConfig = @{
    ChromeLeft = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome Left'
        TitlePattern    = $null
        MonitorNumber   = 1
        Position        = 'left'
    }
    ChromeRight = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome Right'
        TitlePattern    = $null
        MonitorNumber   = 1
        Position        = 'right'
    }
}
```

#### Title Pattern Matching
```powershell
'WebDev' = @{
    ChromeJira = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome Jira'
        TitlePattern    = '*Jira*'    # Wildcard pattern
        MonitorNumber   = 1
        Position        = 'left'
    }
    ChromeGitHub = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome GitHub'
        TitlePattern    = '*GitHub*'
        MonitorNumber   = 1
        Position        = 'right'
    }
}
```

---

## Architecture

### Component Flow

```
[Profile Selection] --> [Configuration] --> [Monitor Detection] --> [Window Enumeration] --> [Rule Application] --> [Window Placement]
        |                      |                   |                        |                        |                          |
        v                      v                   v                        v                        v                          v
   -LayoutProfile        Get-LayoutConfig    Get-MonitorLayout     Get-ApplicationWindows    RulesByMonitor      Set-WindowSnap
   parameter             Profiles/$Config     DisplayNumber 1,2     ProcessName, Title        Grouped by mon     WINDOWPLACEMENT API
                        Priority: File >      WorkArea bounds       MonitorNumber             Snap detection
                        Profile > Default                           AssignedToRule flag       Zone calculation
```

### Key Data Structures

#### Monitor Object

```powershell
[PSCustomObject]@{
    Handle        = $hMonitor       # WinAPI monitor handle
    IsPrimary     = $true/$false    # Primary display flag
    DisplayNumber = 1               # 1, 2, 3... (Windows ordering)
    Bounds        = [PSCustomObject]@{              # Full monitor rectangle
        X = 0; Y = 0; Width = 1920; Height = 1080
    }
    WorkArea      = [PSCustomObject]@{              # Usable area (excluding taskbar)
        X = 0; Y = 0; Width = 1920; Height = 1040
    }
}
```

#### Window Object

```powershell
[PSCustomObject]@{
    Handle        = $hWnd           # Window handle
    ProcessId     = 12345           # Process ID
    ProcessName   = 'chrome'        # Process name (without .exe)
    Title         = 'Page Title'    # Window title
    MonitorNumber = 1               # Current monitor
    IsMaximized   = $false          # Maximized state
    Rect          = [PSCustomObject]@{              # Current position/size
        X = 100; Y = 200; Width = 800; Height = 600
    }
    AssignedToRule = $null          # Tracks which rule claimed this window
}
```

---

## Core Functions

### 1. Get-LayoutConfiguration

**Purpose:** Load configuration based on priority order

**Priority Order:**
1. External config file (if -ConfigPath provided)
2. Named profile (if -LayoutProfile provided)
3. Default configuration

**Logic:**
```powershell
if ($FilePath -and (Test-Path $FilePath)) {
    return Import-Clixml $FilePath
}

if ($ProfileName -and $LayoutProfiles.ContainsKey($ProfileName)) {
    return $LayoutProfiles[$ProfileName]
}

return $DefaultWindowLayoutConfig
```

**Features:**
- Lists available profiles if invalid profile specified
- Logs profile summary (e.g., "Profile contains: 2x chrome, 1x Code")

---

### 2. Get-MonitorLayout

**Purpose:** Enumerate monitors with Windows display settings numbering

**Logic:**
1. Use `EnumDisplayMonitors` to get all monitor handles
2. Use `GetMonitorInfo` to get bounds and work area for each
3. Identify primary monitor (flags & 1 == 1)
4. Assign DisplayNumber:
   - Primary monitor = 1
   - Remaining monitors sorted by X (left-to-right), then Y (top-to-bottom)
   - Sequential numbering starting from 2

**Returns:** Array of monitor objects with DisplayNumber

---

### 3. Get-ApplicationWindows

**Purpose:** Enumerate all visible, non-minimized windows

**Logic:**
1. Use `EnumWindows` to iterate all top-level windows
2. Filter: `IsWindowVisible` = true, `IsIconic` = false
3. Get process ID via `GetWindowThreadProcessId`
4. Get process name via `Get-Process`
5. Get window title via `GetWindowText`
6. Determine current monitor via `MonitorFromWindow`
7. Map monitor handle to DisplayNumber
8. Check maximized state via `IsZoomed`
9. Initialize `AssignedToRule` = $null

**Returns:** Array of window objects

---

### 4. Select-WindowForRule

**Purpose:** Find best matching window for a placement rule

**Logic:**
1. Filter windows by `ProcessName` == `ApplicationName`
2. Filter to unassigned windows (`AssignedToRule` == $null)
3. If `TitlePattern` specified:
   - Convert wildcard pattern to regex via `Convert-WildcardToRegex`
   - Filter by title regex match
4. Prefer window already on target monitor
5. Otherwise, select first available window
6. Return window object or $null

**Critical:** Only returns unassigned windows to prevent double-assignment

---

### 5. Convert-WildcardToRegex

**Purpose:** Convert simple wildcard patterns to regex

**Logic:**
```powershell
if ($Pattern -match '[*?]') {
    $Escaped = [regex]::Escape($Pattern)
    $Escaped = $Escaped -replace '\\\*', '.*'  # * becomes .*
    $Escaped = $Escaped -replace '\\\?', '.'   # ? becomes .
    return $Escaped
} else {
    return $Pattern  # Already regex or plain string
}
```

**Examples:**
- `*Chrome*` → `.*Chrome.*`
- `Jira*` → `Jira.*`
- `*Mail?` → `.*Mail.`

---

### 6. Get-ZonesForMonitor

**Purpose:** Calculate zone rectangles for a monitor

**Logic:**
```powershell
$WA = $Monitor.WorkArea

if ($HasLeftRule -and $HasRightRule) {
    # Snap-to-edge: minimize gap
    $MidPoint = [Math]::Floor($WA.Width / 2)
    
    $Zones = @{
        left  = @{ X = $WA.X; Y = $WA.Y; Width = $MidPoint; Height = $WA.Height }
        right = @{ X = $WA.X + $MidPoint; Y = $WA.Y; Width = $WA.Width - $MidPoint; Height = $WA.Height }
        full  = @{ X = $WA.X; Y = $WA.Y; Width = $WA.Width; Height = $WA.Height }
    }
} else {
    # Standard half-split
    $HalfWidth = [Math]::Floor($WA.Width / 2)
    $Zones = @{
        left  = @{ X = $WA.X; Y = $WA.Y; Width = $HalfWidth; Height = $WA.Height }
        right = @{ X = $WA.X + $HalfWidth; Y = $WA.Y; Width = $WA.Width - $HalfWidth; Height = $WA.Height }
        full  = @{ X = $WA.X; Y = $WA.Y; Width = $WA.Width; Height = $WA.Height }
    }
}
```

**Returns:** Hashtable with `left`, `right`, `full` zone rectangles

**Note:** Complementary width calculation (`Width - MidPoint`) ensures no mathematical gap, but DWM extended frames may still cause visual gaps.

---

### 7. Set-WindowSnap

**Purpose:** Snap window to zone using Windows snap behavior

**Logic:**

**For 'full' position:**
```powershell
[Win32]::ShowWindow($hWnd, [Win32]::SW_MAXIMIZE)
```

**For 'left' or 'right' position:**
```powershell
# Get current placement
$Placement = New-Object WINDOWPLACEMENT
[Win32]::GetWindowPlacement($hWnd, [ref]$Placement)

# Set to restored state with zone coordinates
$Placement.showCmd = [Win32]::SW_RESTORE
$Placement.rcNormalPosition.Left = $Zone.X
$Placement.rcNormalPosition.Top = $Zone.Y
$Placement.rcNormalPosition.Right = $Zone.X + $Zone.Width
$Placement.rcNormalPosition.Bottom = $Zone.Y + $Zone.Height

# Apply placement
[Win32]::SetWindowPlacement($hWnd, [ref]$Placement)

# Force frame update
$Flags = SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED
[Win32]::SetWindowPos($hWnd, [IntPtr]::Zero, $Zone.X, $Zone.Y, $Zone.Width, $Zone.Height, $Flags)
```

**Why WINDOWPLACEMENT?**
- Mimics native Windows snap behavior (Win+Left, Win+Right)
- Properly handles window restoration from maximized state
- More reliable than direct `SetWindowPos` for snapping
- Does NOT send keystrokes (safer, faster)

**Known Limitation:** SetWindowPlacement positions the window frame INCLUDING invisible DWM extended borders, causing small visual gaps.

---

## Main Execution Flow

### Step-by-Step Process

```
1. Load Configuration
   - Check for -LayoutProfile parameter
   - Check for -ConfigPath parameter
   - Fall back to default configuration
   - Validate: at least one rule defined
   - Log profile summary

2. Enumerate Monitors
   - Call Get-MonitorLayout
   - Verify at least one monitor detected
   - Log monitor details (size, position, primary flag)

3. Enumerate Windows
   - Call Get-ApplicationWindows
   - Build array with AssignedToRule = $null for all
   - Log total window count

4. Group Rules by Monitor
   - Organize rules by MonitorNumber
   - Store as: $RulesByMonitor[1] = @(Rule1, Rule2, ...)
   - Enables snap logic per-monitor

5. For Each Monitor (sorted by DisplayNumber):
   a. Verify monitor exists
   b. Check if both left and right rules exist
   c. Calculate zones with snap-awareness
   d. For each rule on this monitor:
      i.   Log rule details (name, target, position, title filter)
      ii.  Call Select-WindowForRule
      iii. If window found:
           - Log window details (title, PID, current position)
           - Mark window.AssignedToRule = RuleName
           - Get target zone
           - Call Set-WindowSnap
           - Increment moved count
      iv.  If no window found:
           - Log warning
           - Increment skipped count

6. Report Summary
   - Windows moved
   - Windows skipped
   - Execution time
   - Error/warning counts
```

---

## Multiple Windows Handling

### Problem Statement

If two Chrome windows exist and two Chrome rules are defined:
- Rule 1: Chrome Left
- Rule 2: Chrome Right

Requirement: Move exactly 2 windows (one per rule), not both to the same position.

### Solution: Assignment Tracking

**Window Object Extension:**
```powershell
AssignedToRule = $null  # Initially unassigned
```

**Selection Logic:**
```powershell
function Select-WindowForRule {
    # Filter to unassigned windows
    $Candidates = $Windows | Where-Object { 
        $_.ProcessName -eq $Rule.ApplicationName -and 
        $null -eq $_.AssignedToRule  # KEY: Only unassigned windows
    }
    
    # Apply title filter if specified
    if ($Rule.TitlePattern) {
        $RegexPattern = Convert-WildcardToRegex -Pattern $Rule.TitlePattern
        $Candidates = $Candidates | Where-Object { $_.Title -match $RegexPattern }
    }
    
    # Prefer window on target monitor, otherwise first available
    $OnTargetMonitor = $Candidates | Where-Object { $_.MonitorNumber -eq $Rule.MonitorNumber }
    if ($OnTargetMonitor) {
        return $OnTargetMonitor | Select-Object -First 1
    }
    return $Candidates | Select-Object -First 1
}
```

**Assignment Process:**
```powershell
$Window = Select-WindowForRule -Windows $Windows -Rule $Rule

if ($Window) {
    # Mark as assigned BEFORE moving (prevents double-selection)
    $Window.AssignedToRule = $RuleName
    
    # Now move the window
    Set-WindowSnap -hWnd $Window.Handle -Position $Rule.Position -Zone $Zone
}
```

**Result:**
- Rule 1 selects first unassigned Chrome window, marks it
- Rule 2 selects next unassigned Chrome window (first is now assigned)
- Each window moved to different position
- Additional Chrome windows (beyond 2) remain untouched

---

## Taskbar Handling

### WorkArea vs Bounds

**Bounds:**
- Full monitor rectangle
- Includes taskbar area
- Use case: Kiosk mode, fullscreen apps

**WorkArea:**
- Usable screen area
- Excludes taskbar, docked toolbars
- Use case: Normal window placement (this script)

**Implementation:**
```powershell
# Always use WorkArea for positioning
$Zones = Get-ZonesForMonitor -Monitor $Monitor

# WorkArea automatically accounts for:
# - Bottom taskbar: reduces Height
# - Top taskbar: increases Y, reduces Height
# - Left taskbar: increases X, reduces Width
# - Right taskbar: reduces Width
```

**Result:** Windows never overlap taskbar

---

## Snap-to-Edge Logic

### Problem: Integer Division Gap

```powershell
# Bad: Can create 1-pixel gap with odd widths
$LeftWidth = [Math]::Floor($Width / 2)   # Example: 1921 / 2 = 960
$RightWidth = [Math]::Floor($Width / 2)  # 960
# Total = 1920 (1-pixel gap!)
```

### Solution: Complementary Width Calculation

```powershell
# Correct approach (v1.3)
$LeftWidth = [Math]::Floor($WorkArea.Width / 2)
$RightWidth = $WorkArea.Width - $LeftWidth  # Ensures no mathematical gap

# Example with 1921 width:
$LeftWidth = Floor(1921 / 2) = 960
$RightWidth = 1921 - 960 = 961
# Total = 1921 (mathematically perfect!)

$LeftZone = @{
    X = $WorkArea.X
    Width = $LeftWidth
}

$RightZone = @{
    X = $WorkArea.X + $LeftWidth  # No mathematical gap
    Width = $RightWidth
}
```

**Note:** This ensures no mathematical gap in zone calculations. However, visual gaps may still appear due to DWM extended window frames (see Known Issues).

---

## Title Pattern Matching

### Use Case

Differentiate between multiple windows of same application:
- Chrome with Jira tab
- Chrome with Email tab
- Chrome with general browsing

### Wildcard Syntax (v1.3)

- `*` matches zero or more characters
- `?` matches exactly one character
- Patterns are case-insensitive

### Implementation

**Configuration:**
```powershell
ChromeJira = @{
    ApplicationName = 'chrome'
    TitlePattern    = '*Jira*'    # Matches "Jira Board", "My Jira Tasks", etc.
    MonitorNumber   = 2
    Position        = 'left'
}

ChromeEmail = @{
    ApplicationName = 'chrome'
    TitlePattern    = '*Gmail*'   # Matches any window with "Gmail" in title
    MonitorNumber   = 2
    Position        = 'right'
}

ChromeGeneral = @{
    ApplicationName = 'chrome'
    TitlePattern    = $null       # Matches any Chrome window
    MonitorNumber   = 1
    Position        = 'full'
}
```

**Matching Logic:**
```powershell
if ($Rule.TitlePattern) {
    $RegexPattern = Convert-WildcardToRegex -Pattern $Rule.TitlePattern
    $Candidates = $Candidates | Where-Object { $_.Title -match $RegexPattern }
}
```

**Execution Order Matters:**
- Process specific patterns first (Jira, Email)
- Process generic patterns last (null = any window)
- Assignment tracking prevents double-assignment

---

## Error Handling

### Scenarios and Responses

| Scenario | Behavior |
|----------|----------|
| Invalid profile name | Exit with error, list available profiles |
| Monitor not found | Skip rules for that monitor, log warning |
| No matching window | Skip rule, log warning |
| Window move fails | Log warning, continue with next rule |
| Invalid configuration | Exit with error code 3 |
| Zero monitors detected | Exit with error code 1 |
| Config file load fails | Exit with error |

### Graceful Degradation

- Script never crashes due to missing window
- Continues processing remaining rules if one fails
- Reports summary: moved count, skipped count, errors, warnings
- Exit code 0 on success, 1 on error

---

## Testing Scenarios

### Test Case 1: Profile System

**Setup:**
```powershell
.\Window Layout Manager 1.ps1 -LayoutProfile '2xChrome'
```

**Expected:**
- Loads 2xChrome profile
- Logs "Profile contains: 2x chrome"
- Moves 2 Chrome windows to left/right

---

### Test Case 2: Two Chrome Windows, Two Rules

**Setup:**
- 2 Chrome windows open
- Profile: 2xChrome (ChromeLeft, ChromeRight)
- Both target monitor 1

**Expected:**
- Window 1 moved to left half
- Window 2 moved to right half
- Minimal gap between windows (DWM frame limitation)
- No third window affected

---

### Test Case 3: Three Chrome Windows, Two Rules

**Setup:**
- 3 Chrome windows open
- Profile: 2xChrome

**Expected:**
- First 2 windows moved
- Third window untouched
- Logs "Placement complete: 2 moved, 0 skipped"

---

### Test Case 4: Title Pattern Filtering

**Setup:**
- 3 Chrome windows: "Jira Board", "Gmail", "YouTube"
- Profile: WebDev (TitlePattern = '*Jira*')

**Expected:**
- Only "Jira Board" window moved
- Others untouched
- Logs "Filtering by title pattern: '*Jira*'"

---

### Test Case 5: Multi-Monitor Snap

**Setup:**
- 2 monitors
- Profile: 2xChrome1xVSCode

**Expected:**
- Monitor 1: 2 Chrome windows snapped left/right
- Monitor 2: VS Code fullscreen (maximized)
- Logs "Processing monitor 1..." then "Processing monitor 2..."

---

### Test Case 6: DryRun Mode

**Setup:**
```powershell
.\Window Layout Manager 1.ps1 -LayoutProfile '2xChrome' -DryRun
```

**Expected:**
- Logs "DRY RUN MODE - No changes will be made"
- Shows what would be moved
- Logs "[DRY RUN] Would snap to left..."
- No actual window movement

---

## Usage Examples

### Basic Usage (Default Profile)

```powershell
# Apply default configuration (2x Chrome)
.\Window Layout Manager 1.ps1
```

### Profile Selection

```powershell
# Apply specific profile
.\Window Layout Manager 1.ps1 -LayoutProfile '2xChrome1xVSCode'
```

### Dry Run

```powershell
# See what would happen without moving windows
.\Window Layout Manager 1.ps1 -LayoutProfile 'WebDev' -DryRun
```

### Custom Configuration File

```powershell
# Create custom config
$MyLayout = @{
    App1Left = @{ ApplicationName = 'notepad'; DisplayName = 'Notepad'; TitlePattern = $null; MonitorNumber = 1; Position = 'left' }
    App2Right = @{ ApplicationName = 'calc'; DisplayName = 'Calculator'; TitlePattern = $null; MonitorNumber = 1; Position = 'right' }
}
$MyLayout | Export-Clixml -Path "C:\Configs\MyLayout.xml"

# Apply custom config
.\Window Layout Manager 1.ps1 -ConfigPath "C:\Configs\MyLayout.xml"
```

### Scheduled Task (Login Trigger)

```powershell
# Run 2xChrome1xVSCode profile at login
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-WindowStyle Hidden -File 'C:\Scripts\Window Layout Manager 1.ps1' -LayoutProfile '2xChrome1xVSCode'"
Register-ScheduledTask -TaskName "WindowLayout" -Trigger $Trigger -Action $Action -RunLevel Highest
```

---

## Performance Considerations

- **Typical execution time:** 2-5 seconds
- **Window enumeration:** ~1 second per 100 windows
- **Monitor detection:** <0.1 seconds
- **Window moves:** ~0.1 seconds each

**Optimization:**
- Early exit if no matching windows
- Assignment tracking prevents redundant searches
- Direct WinAPI calls (no external modules)
- Profile system eliminates config file I/O for common cases

---

## Limitations

1. **DWM Extended Frames:** Small gaps appear between snapped windows due to invisible window borders in Windows 10/11
2. **UWP Apps:** Some Windows Store apps may not respond to SetWindowPlacement
3. **Full Screen Apps:** Windows in true fullscreen may not be movable
4. **DPI Awareness:** High-DPI scaling may affect positioning accuracy
5. **Window State:** Maximized windows are properly handled by WINDOWPLACEMENT API

---

## Future Enhancements

### Planned for v1.4+

**High Priority:**
- [ ] **Fix DWM gap issue:** Use `DwmGetWindowAttribute(DWMWA_EXTENDED_FRAME_BOUNDS)` to detect invisible borders and compensate position
- [ ] **Per-monitor DPI awareness:** Query monitor DPI and scale coordinates accordingly
- [ ] **More profiles:** Add common business/development scenarios

**Medium Priority:**
- [ ] Save current layout before applying new one
- [ ] Undo/restore previous layout
- [ ] Hotkey trigger support (Win+Alt+1, Win+Alt+2, etc.)
- [ ] Monitor resolution change detection and auto-reapply

**Low Priority:**
- [ ] GUI configuration editor
- [ ] Per-user configuration profiles stored in registry
- [ ] Window group support (move related windows together)
- [ ] Percentage-based zones (not just 50/50 split)

---

## Technical Notes

### Why WINDOWPLACEMENT Instead of SetWindowPos?

**SetWindowPos:**
- Moves window to exact coordinates
- Does not handle maximized→restored transition well
- Requires manual state management

**WINDOWPLACEMENT (current approach):**
- Sets window's "normal" (restored) position
- Properly handles maximized→snapped transition
- Mimics native Windows snap behavior
- More reliable for complex window states

### DWM Extended Frame Bounds Issue

Windows Desktop Window Manager adds invisible borders around windows for visual effects and drop shadows. These borders:
- Are typically 7-8 pixels on left/right/bottom
- Are NOT included in GetWindowRect (returns outer frame)
- ARE included in DWMWA_EXTENDED_FRAME_BOUNDS (returns visible frame)
- Cause SetWindowPlacement to position windows with gaps

**Fix approach for v1.4:**
```powershell
# Get visible frame
$FrameRect = New-Object RECT
[DwmApi]::DwmGetWindowAttribute($hWnd, DWMWA_EXTENDED_FRAME_BOUNDS, [ref]$FrameRect, ...)

# Calculate border size
$BorderLeft = $FrameRect.Left - $WindowRect.Left
$BorderRight = $WindowRect.Right - $FrameRect.Right

# Compensate position
$AdjustedX = $Zone.X - $BorderLeft
$AdjustedWidth = $Zone.Width + $BorderLeft + $BorderRight
```

---

## Changelog

### Version 1.3 (2026-02-14)
- Implemented profile-based configuration system
- Added 8 preset profiles (2xChrome, WebDev, etc.)
- Added -LayoutProfile parameter
- Improved logging with profile summaries
- Fixed snap-to-edge calculation (complementary width)
- Added wildcard to regex conversion
- Improved monitor enumeration logging

### Version 1.2 (2026-02-14)
- Switched from SetWindowPos to WINDOWPLACEMENT API
- Better handling of maximized windows
- Added window state detection (IsMaximized)

### Version 1.1 (2026-02-14)
- Initial implementation
- Basic monitor detection
- Window enumeration
- Assignment tracking
- Snap-to-edge logic

---

**Document Version:** 1.3  
**Last Updated:** 2026-02-14  
**Script Version:** 1.3
