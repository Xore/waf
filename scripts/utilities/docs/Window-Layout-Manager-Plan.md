# Window Layout Manager - Implementation Plan

**Document Version:** 1.1  
**Created:** 2026-02-14  
**Author:** Windows Automation Framework  
**Script:** Window Layout Manager 1.ps1

---

## Overview

This document outlines the design and implementation of the Window Layout Manager script, which automatically positions application windows across multiple monitors based on a configuration hashtable.

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
   - No gap between left and right windows
   - Handle integer division rounding correctly

5. **Configuration Model**
   - Hashtable-based configuration
   - Each entry = one placement rule
   - Optional title pattern matching for window selection

---

## Configuration Structure

### Hashtable Format

```powershell
$WindowLayoutConfig = @{
    # Unique key for each rule
    RuleName = @{
        ApplicationName = 'processname'    # Process name (e.g., 'chrome', 'Code')
        DisplayName     = 'Friendly Name'  # For logging/debugging
        TitlePattern    = 'regex|null'     # Optional: match window title
        MonitorNumber   = 1                # Target monitor (1, 2, 3...)
        Position        = 'left'           # 'left', 'right', or 'full'
    }
}
```

### Example Configuration

```powershell
$WindowLayoutConfig = @{
    # Two Chrome windows on monitor 1
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
    
    # Specific Chrome window by title
    ChromeJira = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome Jira'
        TitlePattern    = 'Jira'           # Only windows with "Jira" in title
        MonitorNumber   = 2
        Position        = 'left'
    }
    
    # VS Code full screen on monitor 2
    VSCodeFull = @{
        ApplicationName = 'Code'
        DisplayName     = 'VS Code'
        TitlePattern    = $null
        MonitorNumber   = 2
        Position        = 'full'
    }
}
```

---

## Architecture

### Component Flow

```
[Configuration] --> [Monitor Detection] --> [Window Enumeration] --> [Rule Application] --> [Window Placement]
                         |                        |                        |
                         v                        v                        v
                    [Monitors Array]        [Windows Array]         [Zone Calculation]
                    DisplayNumber 1,2,3     ProcessName, Title      left/right/full zones
                    WorkArea bounds         MonitorNumber           Snap-to-edge logic
                                            AssignedToRule flag
```

### Key Data Structures

#### Monitor Object

```powershell
[PSCustomObject]@{
    Handle        = $hMonitor       # WinAPI monitor handle
    IsPrimary     = $true/$false    # Primary display flag
    DisplayNumber = 1               # 1, 2, 3... (Windows ordering)
    Bounds        = @{              # Full monitor rectangle
        X = 0; Y = 0; Width = 1920; Height = 1080
    }
    WorkArea      = @{              # Usable area (excluding taskbar)
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
    Rect          = @{              # Current position/size
        X = 100; Y = 200; Width = 800; Height = 600
    }
    AssignedToRule = $null          # Tracks which rule claimed this window
}
```

---

## Core Functions

### 1. Get-MonitorLayout

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

### 2. Get-ApplicationWindows

**Purpose:** Enumerate all visible, non-minimized windows

**Logic:**
1. Use `EnumWindows` to iterate all top-level windows
2. Filter: `IsWindowVisible` = true, `IsIconic` = false
3. Get process ID via `GetWindowThreadProcessId`
4. Get process name via `Get-Process`
5. Get window title via `GetWindowText`
6. Determine current monitor via `MonitorFromWindow`
7. Map monitor handle to DisplayNumber
8. Initialize `AssignedToRule` = $null

**Returns:** Array of window objects

---

### 3. Select-WindowForRule

**Purpose:** Find best matching window for a placement rule

**Logic:**
1. Filter windows by `ProcessName` == `ApplicationName`
2. Filter to unassigned windows (`AssignedToRule` == $null)
3. If `TitlePattern` specified, filter by title regex match
4. Prefer window already on target monitor
5. Otherwise, select first available window
6. Return window object or $null

**Critical:** Only returns unassigned windows to prevent double-assignment

---

### 4. Get-ZonesForMonitor

**Purpose:** Calculate zone rectangles for a monitor

**Logic:**
```powershell
$WorkArea = $Monitor.WorkArea

if ($HasLeftRule -and $HasRightRule) {
    # Snap-to-edge: no gap between left and right
    $LeftWidth = [Math]::Floor($WorkArea.Width / 2)
    $RightWidth = $WorkArea.Width - $LeftWidth  # Ensures no gap
    
    $Zones = @{
        left  = @{ X = $WorkArea.X; Y = $WorkArea.Y; Width = $LeftWidth; Height = $WorkArea.Height }
        right = @{ X = $WorkArea.X + $LeftWidth; Y = $WorkArea.Y; Width = $RightWidth; Height = $WorkArea.Height }
        full  = @{ X = $WorkArea.X; Y = $WorkArea.Y; Width = $WorkArea.Width; Height = $WorkArea.Height }
    }
} else {
    # Standard half-split (small gap acceptable)
    $HalfWidth = [Math]::Floor($WorkArea.Width / 2)
    
    $Zones = @{
        left  = @{ X = $WorkArea.X; Y = $WorkArea.Y; Width = $HalfWidth; Height = $WorkArea.Height }
        right = @{ X = $WorkArea.X + $HalfWidth; Y = $WorkArea.Y; Width = $WorkArea.Width - $HalfWidth; Height = $WorkArea.Height }
        full  = @{ X = $WorkArea.X; Y = $WorkArea.Y; Width = $WorkArea.Width; Height = $WorkArea.Height }
    }
}
```

**Returns:** Hashtable with `left`, `right`, `full` zone rectangles

---

### 5. Move-WindowToZone

**Purpose:** Move window to specified zone

**Logic:**
1. Use `SetWindowPos` with zone coordinates
2. Flags: `SWP_NOZORDER | SWP_NOACTIVATE | SWP_SHOWWINDOW`
3. Do not change Z-order or activate window
4. Return success/failure

---

## Main Execution Flow

### Step-by-Step Process

```
1. Load Configuration
   - Use internal config or load from file
   - Validate: at least one rule defined

2. Enumerate Monitors
   - Call Get-MonitorLayout
   - Verify at least one monitor detected

3. Enumerate Windows
   - Call Get-ApplicationWindows
   - Build array with AssignedToRule = $null for all

4. Group Rules by Monitor
   - Organize rules by MonitorNumber
   - Enables snap logic per-monitor

5. For Each Monitor (sorted by DisplayNumber):
   a. Check if both left and right rules exist
   b. Calculate zones with snap-awareness
   c. For each rule on this monitor:
      i.   Call Select-WindowForRule
      ii.  If window found:
           - Mark window.AssignedToRule = RuleName
           - Move window to zone
           - Increment moved count
      iii. If no window found:
           - Log warning
           - Increment skipped count

6. Report Summary
   - Windows moved
   - Windows skipped
   - Execution time
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
        $Candidates = $Candidates | Where-Object { $_.Title -match $Rule.TitlePattern }
    }
    
    # Return first available
    return $Candidates | Select-Object -First 1
}
```

**Assignment Process:**
```powershell
# After selecting window for rule
$Window = Select-WindowForRule -Windows $Windows -Rule $Rule

if ($Window) {
    # Mark as assigned BEFORE moving
    $Window.AssignedToRule = $RuleName
    
    # Now move the window
    Move-WindowToZone -hWnd $Window.Handle -Zone $Zone
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
# Bad: Can create 1-pixel gap
$LeftWidth = [Math]::Floor($Width / 2)   # Example: 1920 / 2 = 960
$RightWidth = [Math]::Floor($Width / 2)  # 960
# Total = 1920 (correct)

# But if right starts at X + 960:
$RightX = $X + $LeftWidth  # 0 + 960 = 960
$RightWidth = $LeftWidth   # 960
# Right ends at 960 + 960 = 1920 (correct)

# Issue: If odd width (e.g., 1921):
$LeftWidth = Floor(1921 / 2) = 960
$RightWidth = 960
# Total = 1920 (1-pixel gap!)
```

### Solution: Complementary Width Calculation

```powershell
# Correct approach
$LeftWidth = [Math]::Floor($WorkArea.Width / 2)
$RightWidth = $WorkArea.Width - $LeftWidth  # Ensures no gap

# Example with 1921 width:
$LeftWidth = Floor(1921 / 2) = 960
$RightWidth = 1921 - 960 = 961
# Total = 1921 (perfect fit!)

$LeftZone = @{
    X = $WorkArea.X
    Width = $LeftWidth
}

$RightZone = @{
    X = $WorkArea.X + $LeftWidth  # No gap
    Width = $RightWidth
}
```

---

## Title Pattern Matching

### Use Case

Differentiate between multiple windows of same application:
- Chrome with Jira tab
- Chrome with Email tab
- Chrome with general browsing

### Implementation

**Configuration:**
```powershell
ChromeJira = @{
    ApplicationName = 'chrome'
    TitlePattern    = 'Jira'
    MonitorNumber   = 2
    Position        = 'left'
}

ChromeEmail = @{
    ApplicationName = 'chrome'
    TitlePattern    = 'Gmail|Outlook'
    MonitorNumber   = 2
    Position        = 'right'
}

ChromeGeneral = @{
    ApplicationName = 'chrome'
    TitlePattern    = $null  # Any Chrome window
    MonitorNumber   = 1
    Position        = 'full'
}
```

**Matching Logic:**
```powershell
if ($Rule.TitlePattern) {
    # Regex match on window title
    $Candidates = $Candidates | Where-Object { $_.Title -match $Rule.TitlePattern }
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
| Monitor not found | Skip rules for that monitor, log warning |
| No matching window | Skip rule, log warning |
| Window move fails | Log error, continue with next rule |
| Invalid configuration | Exit with error code 3 |
| Zero monitors detected | Exit with error code 1 |

### Graceful Degradation

- Script never crashes due to missing window
- Continues processing remaining rules if one fails
- Reports summary: moved count, skipped count, errors

---

## Testing Scenarios

### Test Case 1: Two Chrome Windows, Two Rules

**Setup:**
- 2 Chrome windows open
- 2 rules: ChromeLeft, ChromeRight
- Both target monitor 1

**Expected:**
- Window 1 moved to left half
- Window 2 moved to right half
- No gap between windows
- No third window affected

---

### Test Case 2: Three Chrome Windows, Two Rules

**Setup:**
- 3 Chrome windows open
- 2 rules: ChromeLeft, ChromeRight

**Expected:**
- First 2 windows moved
- Third window untouched

---

### Test Case 3: Title Pattern Filtering

**Setup:**
- 3 Chrome windows: "Jira", "Gmail", "YouTube"
- Rule: TitlePattern = 'Jira'

**Expected:**
- Only "Jira" window moved
- Others untouched

---

### Test Case 4: Multi-Monitor Snap

**Setup:**
- 2 monitors
- Rules: ChromeLeft (mon 1), ChromeRight (mon 1), VSCode (mon 2, full)

**Expected:**
- Monitor 1: Chrome windows snapped left/right
- Monitor 2: VSCode fullscreen

---

## Usage Examples

### Basic Usage

```powershell
# Apply default configuration
.\Window Layout Manager 1.ps1
```

### Dry Run

```powershell
# See what would happen without moving windows
.\Window Layout Manager 1.ps1 -DryRun
```

### Custom Configuration File

```powershell
# Export config to file
$WindowLayoutConfig | Export-Clixml -Path "C:\Configs\MyLayout.xml"

# Apply custom config
.\Window Layout Manager 1.ps1 -ConfigPath "C:\Configs\MyLayout.xml"
```

### Scheduled Task

```powershell
# Run at login
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File 'C:\Scripts\Window Layout Manager 1.ps1'"
Register-ScheduledTask -TaskName "WindowLayout" -Trigger $Trigger -Action $Action -RunLevel Highest
```

---

## Performance Considerations

- Typical execution time: 2-5 seconds
- Window enumeration: ~1 second per 100 windows
- Monitor detection: <0.1 seconds
- Window moves: ~0.1 seconds each

**Optimization:**
- Early exit if no matching windows
- Assignment tracking prevents redundant searches
- Direct WinAPI calls (no external modules)

---

## Limitations

1. **UWP Apps:** Some Windows Store apps may not respond to SetWindowPos
2. **Full Screen Apps:** Windows in true fullscreen may not be movable
3. **DPI Awareness:** High-DPI scaling may affect positioning accuracy
4. **Window State:** Maximized windows are moved but may need restore first

---

## Future Enhancements

- [ ] Save current layout before applying new one
- [ ] Undo/restore previous layout
- [ ] Per-user configuration profiles
- [ ] Hotkey trigger support
- [ ] Monitor resolution change detection
- [ ] GUI configuration editor

---

**Document Version:** 1.1  
**Last Updated:** 2026-02-14
