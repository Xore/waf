<#
.SYNOPSIS
    Automatically positions application windows using Direct Border Overlap

.DESCRIPTION
    Alternative implementation using direct border overlap to eliminate gaps.
    This approach expands window rectangles by a fixed border width to create
    overlap between adjacent windows, mimicking Windows native snap behavior.
    
    Instead of compensating for invisible DWM borders, this method intentionally
    overlaps windows by the typical border width (7-8 pixels). The topmost window's
    border will be visible at edges, but adjacent windows have no gaps.
    
    Key features:
    - Direct border overlap approach (no DWM API calls)
    - Configurable border width (default 8px for Windows 10/11)
    - Per-window border overlap control via UseOverlap config option
    - Supports left/right/full window zones
    - Profile-based configurations
    - Accounts for taskbar in calculations
    - Wildcard pattern support for window titles
    - Smart cross-monitor window distribution
    
    This script runs unattended without user interaction.

.PARAMETER LayoutProfile
    Layout profile name to apply. Examples:
    - '2xChrome1xVSCode' - 2 Chrome windows (left/right), 1 VS Code (full)
    - '2xBDE2xSAP' - 2 BDE windows, 2 SAP windows
    - Custom profiles defined in script or loaded from file

.PARAMETER ConfigPath
    Optional path to external configuration file.

.PARAMETER BorderWidth
    Default width of invisible window border in pixels. Default is 8 for Windows 10/11.
    Use 7 for older Windows 10 builds, or 0 to disable overlap globally.
    Can be overridden per-window using UseOverlap = $false in rule config.

.PARAMETER DryRun
    If specified, shows what would be done without actually moving windows.

.EXAMPLE
    PS> .\Window Layout Manager 3.ps1 -LayoutProfile '2xChrome'
    Applies 2 Chrome windows with 8px border overlap
    
.EXAMPLE
    PS> .\Window Layout Manager 3.ps1 -LayoutProfile '2xChrome' -BorderWidth 7
    Uses 7px border overlap for older Windows 10
    
.EXAMPLE
    PS> .\Window Layout Manager 3.ps1 -LayoutProfile 'DevSetup' -DryRun
    Shows what would happen without moving windows

.NOTES
    Script Name:    Window Layout Manager 3.ps1
    Author:         Windows Automation Framework
    Version:        3.3
    Creation Date:  2026-02-14
    Last Modified:  2026-02-14
    
    Execution Context: User or SYSTEM
    Execution Frequency: On-demand or triggered by login/display change
    Typical Duration: ~2-5 seconds
    Timeout Setting: 30 seconds
    
    User Interaction: NONE (fully automated)
    Restart Behavior: Never restarts
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Windows 10/11 or Windows Server 2016+
        - User32.dll (Windows API)
    
    Exit Codes:
        0 - Success
        1 - General error
        2 - Missing dependencies
        3 - Configuration error
    
    Trade-offs:
    - Windows overlap slightly (border width overlap)
    - Only topmost window has active resize handles in overlap area
    - No DWM API calls required (simpler, more compatible)
    - Fixed border width may not be perfect for all applications
    
    Config Option - UseOverlap:
    Each window rule can include 'UseOverlap' (default: $true):
    - UseOverlap = $true  : Apply border overlap (eliminate gaps)
    - UseOverlap = $false : No overlap (may show gaps, but precise positioning)
    
.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LayoutProfile = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "",
    
    [Parameter(Mandatory=$false)]
    [int]$BorderWidth = 8,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

#Requires -Version 5.1

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.3"
$LogLevel = "INFO"
$VerbosePreference = 'SilentlyContinue'
$DefaultTimeout = 30

# ============================================================================
# LAYOUT PROFILES
# ============================================================================

$LayoutProfiles = @{
    '2xChrome1xVSCode' = @{
        ChromeLeft = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Left'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'left'
            UseOverlap      = $true
        }
        ChromeRight = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Right'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'right'
            UseOverlap      = $true
        }
        VSCodeFull = @{
            ApplicationName = 'Code'
            DisplayName     = 'VS Code Full'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'full'
            UseOverlap      = $null
        }
    }
    
    '2xBDE2xSAP' = @{
        BDELeft = @{
            ApplicationName = 'BDE'
            DisplayName     = 'BDE Left'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'left'
            UseOverlap      = $true
        }
        BDERight = @{
            ApplicationName = 'BDE'
            DisplayName     = 'BDE Right'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'right'
            UseOverlap      = $true
        }
        SAPLeft = @{
            ApplicationName = 'saplogon'
            DisplayName     = 'SAP Left'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'left'
            UseOverlap      = $true
        }
        SAPRight = @{
            ApplicationName = 'saplogon'
            DisplayName     = 'SAP Right'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'right'
            UseOverlap      = $true
        }
    }
    
    'WebDev' = @{
        ChromeJira = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Jira'
            TitlePattern    = '*Jira*'
            MonitorNumber   = 1
            Position        = 'left'
            UseOverlap      = $true
        }
        ChromeGitHub = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome GitHub'
            TitlePattern    = '*GitHub*'
            MonitorNumber   = 1
            Position        = 'right'
            UseOverlap      = $true
        }
        VSCodeFull = @{
            ApplicationName = 'Code'
            DisplayName     = 'VS Code'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'full'
            UseOverlap      = $null
        }
    }
    
    '2xChrome' = @{
        ChromeLeft = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Left'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'left'
            UseOverlap      = $true
        }
        ChromeRight = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Right'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'right'
            UseOverlap      = $true
        }
    }
    
    'MixedOverlap' = @{
        ChromeLeftOverlap = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Left (with overlap)'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'left'
            UseOverlap      = $true
        }
        ChromeRightNoOverlap = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Right (no overlap)'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'right'
            UseOverlap      = $false
        }
    }
}

$DefaultWindowLayoutConfig = @{
    ChromeLeft = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome Left'
        TitlePattern    = $null
        MonitorNumber   = 1
        Position        = 'left'
        UseOverlap      = $true
    }
    ChromeRight = @{
        ApplicationName = 'chrome'
        DisplayName     = 'Chrome Right'
        TitlePattern    = $null
        MonitorNumber   = 1
        Position        = 'right'
        UseOverlap      = $true
    }
}

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ScriptName = $MyInvocation.MyCommand.Name
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0

# ============================================================================
# WINDOWS API DEFINITIONS
# ============================================================================

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public struct MONITORINFO {
    public uint Size;
    public RECT Monitor;
    public RECT WorkArea;
    public uint Flags;
}

public struct WINDOWPLACEMENT {
    public uint length;
    public uint flags;
    public uint showCmd;
    public POINT ptMinPosition;
    public POINT ptMaxPosition;
    public RECT rcNormalPosition;
}

public struct POINT {
    public int X;
    public int Y;
}

public class Win32 {
    public delegate bool MonitorEnumDelegate(IntPtr hMonitor, IntPtr hdcMonitor, ref RECT lprcMonitor, IntPtr dwData);
    
    [DllImport("user32.dll")]
    public static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip, MonitorEnumDelegate lpfnEnum, IntPtr dwData);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFO lpmi);
    
    [DllImport("user32.dll")]
    public static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint dwFlags);
    
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool IsZoomed(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    
    [DllImport("user32.dll")]
    public static extern bool GetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT lpwndpl);
    
    [DllImport("user32.dll")]
    public static extern bool SetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT lpwndpl);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    // Constants
    public const uint MONITOR_DEFAULTTONEAREST = 2;
    public const uint SWP_NOZORDER = 0x0004;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_SHOWWINDOW = 0x0040;
    public const uint SWP_FRAMECHANGED = 0x0020;
    
    // ShowWindow constants
    public const int SW_RESTORE = 9;
    public const int SW_MAXIMIZE = 3;
    public const int SW_SHOWNOACTIVATE = 4;
    
    // Window placement constants
    public const uint WPF_ASYNCWINDOWPLACEMENT = 0x0004;
}
"@

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
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
        'DEBUG' { 
            if ($LogLevel -eq 'DEBUG') { 
                Write-Verbose $LogMessage 
            } 
        }
        'INFO'  { Write-Host $LogMessage -ForegroundColor Cyan }
        'WARN'  { 
            Write-Warning $LogMessage
            $script:WarningCount++ 
        }
        'ERROR' { 
            Write-Host $LogMessage -ForegroundColor Red
            $script:ErrorCount++ 
        }
    }
}

function Get-LayoutConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProfileName,
        
        [Parameter(Mandatory=$false)]
        [string]$FilePath
    )
    
    if ($FilePath -and (Test-Path $FilePath)) {
        Write-Log "Loading configuration from file: $FilePath" -Level INFO
        try {
            $Config = Import-Clixml $FilePath
            Write-Log "Loaded custom configuration from file" -Level INFO
            return $Config
        } catch {
            Write-Log "Failed to load config file: $_" -Level ERROR
            throw "Configuration file load failed"
        }
    }
    
    if ($ProfileName) {
        if ($LayoutProfiles.ContainsKey($ProfileName)) {
            Write-Log "Loading layout profile: $ProfileName" -Level INFO
            $Config = $LayoutProfiles[$ProfileName]
            
            $AppCounts = @{}
            $Config.Keys | ForEach-Object {
                $App = $Config[$_].ApplicationName
                if (-not $AppCounts.ContainsKey($App)) {
                    $AppCounts[$App] = 0
                }
                $AppCounts[$App]++
            }
            
            $Summary = ($AppCounts.GetEnumerator() | ForEach-Object { "$($_.Value)x$($_.Key)" }) -join ', '
            Write-Log "Profile contains: $Summary" -Level INFO
            
            return $Config
        } else {
            Write-Log "Profile '$ProfileName' not found" -Level ERROR
            Write-Log "Available profiles: $($LayoutProfiles.Keys -join ', ')" -Level INFO
            throw "Unknown layout profile: $ProfileName"
        }
    }
    
    Write-Log "Using default configuration" -Level INFO
    return $DefaultWindowLayoutConfig
}

function Convert-WildcardToRegex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern
    )
    
    if ($Pattern -match '[*?]') {
        $Escaped = [regex]::Escape($Pattern)
        $Escaped = $Escaped -replace '\\\\\\*', '.*'
        $Escaped = $Escaped -replace '\\\\\\?', '.'
        
        Write-Log "  Converted wildcard '$Pattern' to regex '$Escaped'" -Level DEBUG
        return $Escaped
    } else {
        return $Pattern
    }
}

function Get-MonitorLayout {
    [CmdletBinding()]
    param()
    
    Write-Log "Enumerating monitors..." -Level INFO
    
    $MonitorList = New-Object System.Collections.ArrayList
    
    $Callback = {
        param($hMonitor, $hdcMonitor, [ref]$lprcMonitor, $dwData)
        
        $MonitorInfo = New-Object MONITORINFO
        $MonitorInfo.Size = [System.Runtime.InteropServices.Marshal]::SizeOf($MonitorInfo)
        
        if ([Win32]::GetMonitorInfo($hMonitor, [ref]$MonitorInfo)) {
            $Mon = $MonitorInfo.Monitor
            $Work = $MonitorInfo.WorkArea
            $IsPrimary = ($MonitorInfo.Flags -band 1) -eq 1
            
            $MonitorObj = [PSCustomObject]@{
                Handle        = $hMonitor
                IsPrimary     = $IsPrimary
                Bounds        = [PSCustomObject]@{
                    X      = $Mon.Left
                    Y      = $Mon.Top
                    Width  = $Mon.Right - $Mon.Left
                    Height = $Mon.Bottom - $Mon.Top
                }
                WorkArea      = [PSCustomObject]@{
                    X      = $Work.Left
                    Y      = $Work.Top
                    Width  = $Work.Right - $Work.Left
                    Height = $Work.Bottom - $Work.Top
                }
                DisplayNumber = 0
            }
            
            [void]$MonitorList.Add($MonitorObj)
        }
        
        return $true
    }
    
    $CallbackDelegate = [Win32+MonitorEnumDelegate]$Callback
    [Win32]::EnumDisplayMonitors([IntPtr]::Zero, [IntPtr]::Zero, $CallbackDelegate, [IntPtr]::Zero) | Out-Null
    
    $DisplayNumber = 1
    
    $Primary = $MonitorList | Where-Object { $_.IsPrimary }
    if ($Primary) {
        $Primary.DisplayNumber = $DisplayNumber++
    }
    
    $Secondary = $MonitorList | 
        Where-Object { -not $_.IsPrimary } | 
        Sort-Object { $_.Bounds.X }, { $_.Bounds.Y }
    
    foreach ($Mon in $Secondary) {
        $Mon.DisplayNumber = $DisplayNumber++
    }
    
    $MonitorArray = $MonitorList.ToArray()
    
    Write-Log "Found $($MonitorArray.Count) monitor(s)" -Level INFO
    foreach ($Mon in $MonitorArray) {
        Write-Log "  Monitor $($Mon.DisplayNumber): $($Mon.WorkArea.Width)x$($Mon.WorkArea.Height) at ($($Mon.WorkArea.X),$($Mon.WorkArea.Y))$(if($Mon.IsPrimary){' [Primary]'})" -Level INFO
    }
    
    return $MonitorArray
}

function Get-WindowTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$hWnd
    )
    
    $Length = [Win32]::GetWindowTextLength($hWnd)
    if ($Length -eq 0) { return "" }
    
    $Builder = New-Object System.Text.StringBuilder ($Length + 1)
    [Win32]::GetWindowText($hWnd, $Builder, $Builder.Capacity) | Out-Null
    
    return $Builder.ToString()
}

function Get-ApplicationWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Monitors
    )
    
    Write-Log "Enumerating application windows..." -Level INFO
    
    $WindowList = New-Object System.Collections.ArrayList
    
    $Callback = {
        param($hWnd, $lParam)
        
        if ([Win32]::IsWindowVisible($hWnd) -and -not [Win32]::IsIconic($hWnd)) {
            $ProcessId = 0
            [Win32]::GetWindowThreadProcessId($hWnd, [ref]$ProcessId) | Out-Null
            
            if ($ProcessId -ne 0) {
                try {
                    $Process = Get-Process -Id $ProcessId -ErrorAction Stop
                    
                    $Rect = New-Object RECT
                    if ([Win32]::GetWindowRect($hWnd, [ref]$Rect)) {
                        $hMonitor = [Win32]::MonitorFromWindow($hWnd, [Win32]::MONITOR_DEFAULTTONEAREST)
                        $MonitorObj = $Monitors | Where-Object { $_.Handle -eq $hMonitor } | Select-Object -First 1
                        
                        $IsMaximized = [Win32]::IsZoomed($hWnd)
                        
                        $WindowObj = [PSCustomObject]@{
                            Handle        = $hWnd
                            ProcessId     = $ProcessId
                            ProcessName   = $Process.ProcessName
                            Title         = Get-WindowTitle -hWnd $hWnd
                            MonitorNumber = if ($MonitorObj) { $MonitorObj.DisplayNumber } else { 0 }
                            IsMaximized   = $IsMaximized
                            Rect          = [PSCustomObject]@{
                                X      = $Rect.Left
                                Y      = $Rect.Top
                                Width  = $Rect.Right - $Rect.Left
                                Height = $Rect.Bottom - $Rect.Top
                            }
                            AssignedToRule = $null
                        }
                        
                        [void]$WindowList.Add($WindowObj)
                    }
                } catch {
                }
            }
        }
        
        return $true
    }
    
    $CallbackDelegate = [Win32+EnumWindowsProc]$Callback
    [Win32]::EnumWindows($CallbackDelegate, [IntPtr]::Zero) | Out-Null
    
    Write-Log "Found $($WindowList.Count) total visible windows" -Level INFO
    
    return $WindowList.ToArray()
}

function Get-ZonesForMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Monitor,
        
        [Parameter(Mandatory=$false)]
        [bool]$HasLeftRule = $false,
        
        [Parameter(Mandatory=$false)]
        [bool]$HasRightRule = $false
    )
    
    $WA = $Monitor.WorkArea
    
    if ($HasLeftRule -and $HasRightRule) {
        $MidPoint = [Math]::Floor($WA.Width / 2)
        
        $Zones = @{
            left  = @{ 
                X = $WA.X
                Y = $WA.Y
                Width = $MidPoint
                Height = $WA.Height
            }
            right = @{ 
                X = $WA.X + $MidPoint
                Y = $WA.Y
                Width = $WA.Width - $MidPoint
                Height = $WA.Height
            }
            full  = @{ 
                X = $WA.X
                Y = $WA.Y
                Width = $WA.Width
                Height = $WA.Height
            }
        }
    } else {
        $HalfWidth = [Math]::Floor($WA.Width / 2)
        
        $Zones = @{
           left  = @{ 
                X = $WA.X
                Y = $WA.Y
                Width = $HalfWidth
                Height = $WA.Height
            }
            right = @{ 
                X = $WA.X + $HalfWidth
                Y = $WA.Y
                Width = $WA.Width - $HalfWidth
                Height = $WA.Height
            }
            full  = @{ 
                X = $WA.X
                Y = $WA.Y
                Width = $WA.Width
                Height = $WA.Height
            }
        }
    }
    
    return $Zones
}

function Set-WindowSnapBorderOverlap {
    <#
    .SYNOPSIS
        Snaps window with optional border overlap
    .DESCRIPTION
        Positions window in zone with optional border overlap based on UseOverlap setting.
        
        UseOverlap = $true  : Expands window by BorderWidth on left, right, bottom
        UseOverlap = $false : Positions window exactly at zone boundaries (no overlap)
        UseOverlap = $null  : Same as $false for 'full' position, $true for others
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$hWnd,
        
        [Parameter(Mandatory=$true)]
        [string]$Position,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Zone,
        
        [Parameter(Mandatory=$true)]
        [int]$BorderWidth,
        
        [Parameter(Mandatory=$false)]
        [object]$UseOverlap = $true,
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    if ($null -eq $UseOverlap) {
        $UseOverlap = ($Position -ne 'full')
    }
    
    $OverlapText = if ($UseOverlap) { "with ${BorderWidth}px overlap" } else { "no overlap" }
    
    if ($DryRun) {
        Write-Log "  [DRY RUN] Would snap to $Position $OverlapText (X=$($Zone.X), Y=$($Zone.Y), W=$($Zone.Width), H=$($Zone.Height))" -Level INFO
        return $true
    }
    
    try {
        if ($Position -eq 'full') {
            Write-Log "  Maximizing window" -Level DEBUG
            $Result = [Win32]::ShowWindow($hWnd, [Win32]::SW_MAXIMIZE)
            
            if ($Result) {
                Write-Log "  Window maximized successfully" -Level INFO
            } else {
                Write-Log "  Failed to maximize window" -Level WARN
                return $false
            }
        } else {
            Write-Log "  Snapping to $Position ($OverlapText)" -Level DEBUG
            
            $Placement = New-Object WINDOWPLACEMENT
            $Placement.length = [System.Runtime.InteropServices.Marshal]::SizeOf($Placement)
            
            if (-not [Win32]::GetWindowPlacement($hWnd, [ref]$Placement)) {
                Write-Log "  Failed to get window placement" -Level WARN
                return $false
            }
            
            $Placement.showCmd = [Win32]::SW_RESTORE
            
            if ($UseOverlap) {
                $FinalX = $Zone.X - $BorderWidth
                $FinalY = $Zone.Y
                $FinalWidth = $Zone.Width + ($BorderWidth * 2)
                $FinalHeight = $Zone.Height + $BorderWidth
            } else {
                $FinalX = $Zone.X
                $FinalY = $Zone.Y
                $FinalWidth = $Zone.Width
                $FinalHeight = $Zone.Height
            }
            
            $Placement.rcNormalPosition.Left = $FinalX
            $Placement.rcNormalPosition.Top = $FinalY
            $Placement.rcNormalPosition.Right = $FinalX + $FinalWidth
            $Placement.rcNormalPosition.Bottom = $FinalY + $FinalHeight
            
            $Placement.flags = 0
            
            if ([Win32]::SetWindowPlacement($hWnd, [ref]$Placement)) {
                Write-Log "  Snapped $OverlapText (zone: X=$($Zone.X), Y=$($Zone.Y), W=$($Zone.Width), H=$($Zone.Height))" -Level INFO
                
                $Flags = [Win32]::SWP_NOZORDER -bor [Win32]::SWP_NOACTIVATE -bor [Win32]::SWP_FRAMECHANGED
                [Win32]::SetWindowPos($hWnd, [IntPtr]::Zero, $FinalX, $FinalY, $FinalWidth, $FinalHeight, $Flags) | Out-Null
                
                return $true
            } else {
                Write-Log "  Failed to set window placement" -Level WARN
                return $false
            }
        }
        
        return $true
        
    } catch {
        Write-Log "  Error during snap operation: $_" -Level ERROR
        return $false
    }
}

function Select-WindowForRule {
    <#
    .SYNOPSIS
        Smart window selection with strong cross-monitor priority
    .DESCRIPTION
        Finds an unassigned window matching the process name and optional title pattern.
        
        NEW: Strongly prioritizes windows ALREADY on the target monitor to prevent
        cross-monitor conflicts when multiple rules target the same application.
        
        Selection priority:
        1. Exact match: Title pattern + already on target monitor
        2. Title pattern match on any monitor (will be moved)
        3. No title pattern + already on target monitor
        4. No title pattern on any monitor (fallback)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Windows,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Rule,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$AllRules
    )
    
    $Candidates = $Windows | Where-Object { 
        $_.ProcessName -eq $Rule.ApplicationName -and 
        $null -eq $_.AssignedToRule
    }
    
    if ($Candidates.Count -eq 0) {
        return $null
    }
    
    Write-Log "  Found $($Candidates.Count) unassigned $($Rule.ApplicationName) window(s)" -Level DEBUG
    
    if ($Rule.TitlePattern) {
        $RegexPattern = Convert-WildcardToRegex -Pattern $Rule.TitlePattern
        Write-Log "  Filtering by title pattern: '$($Rule.TitlePattern)'" -Level DEBUG
        
        $TitleMatches = $Candidates | Where-Object { $_.Title -match $RegexPattern }
        
        if ($TitleMatches.Count -eq 0) {
            Write-Log "  No windows matched title pattern '$($Rule.TitlePattern)'" -Level DEBUG
            return $null
        }
        
        Write-Log "  Found $($TitleMatches.Count) window(s) matching title pattern" -Level DEBUG
        $Candidates = $TitleMatches
    }
    
    $OnTargetMonitor = $Candidates | Where-Object { $_.MonitorNumber -eq $Rule.MonitorNumber }
    if ($OnTargetMonitor.Count -gt 0) {
        Write-Log "  PRIORITY: Selected window already on target monitor $($Rule.MonitorNumber)" -Level INFO
        return $OnTargetMonitor | Select-Object -First 1
    }
    
    $OtherRulesForApp = $AllRules.GetEnumerator() | Where-Object {
        $_.Value.ApplicationName -eq $Rule.ApplicationName -and
        $_.Value.MonitorNumber -ne $Rule.MonitorNumber
    }
    
    if ($OtherRulesForApp) {
        $ReservedMonitors = $OtherRulesForApp.Value.MonitorNumber | Select-Object -Unique
        Write-Log "  Note: Application '$($Rule.ApplicationName)' also has rules on monitor(s): $($ReservedMonitors -join ', ')" -Level DEBUG
        
        foreach ($ReservedMon in $ReservedMonitors) {
            $CandidatesOnReserved = $Candidates | Where-Object { $_.MonitorNumber -eq $ReservedMon }
            
            if ($CandidatesOnReserved.Count -gt 0) {
                Write-Log "  Skipping $($CandidatesOnReserved.Count) window(s) on monitor $ReservedMon (reserved for other rule)" -Level DEBUG
                $Candidates = $Candidates | Where-Object { $_.MonitorNumber -ne $ReservedMon }
            }
        }
    }
    
    if ($Candidates.Count -eq 0) {
        Write-Log "  No suitable windows remain after monitor reservation check" -Level WARN
        return $null
    }
    
    Write-Log "  Selecting window from available pool (will move to monitor $($Rule.MonitorNumber))" -Level DEBUG
    return $Candidates | Select-Object -First 1
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "Using Direct Border Overlap approach" -Level INFO
    Write-Log "Default border width: ${BorderWidth}px" -Level INFO
    if ($DryRun) {
        Write-Log "DRY RUN MODE - No changes will be made" -Level WARN
    }
    Write-Log "========================================" -Level INFO
    
    $WindowLayoutConfig = Get-LayoutConfiguration -ProfileName $LayoutProfile -FilePath $ConfigPath
    
    if ($WindowLayoutConfig.Count -eq 0) {
        throw "No window layout rules defined"
    }
    
    Write-Log "Loaded $($WindowLayoutConfig.Count) window placement rule(s)" -Level INFO
    
    $Monitors = Get-MonitorLayout
    
    if ($Monitors.Count -eq 0) {
        throw "No monitors detected"
    }
    
    $Windows = Get-ApplicationWindows -Monitors $Monitors
    
    $RulesByMonitor = @{}
    foreach ($RuleName in $WindowLayoutConfig.Keys) {
        $Rule = $WindowLayoutConfig[$RuleName]
        $MonNum = $Rule.MonitorNumber
        
        if (-not $RulesByMonitor.ContainsKey($MonNum)) {
            $RulesByMonitor[$MonNum] = @()
        }
        
        $RulesByMonitor[$MonNum] += @{ Name = $RuleName; Rule = $Rule }
    }
    
    $MovedCount = 0
    $SkippedCount = 0
    
    foreach ($MonitorNumber in ($RulesByMonitor.Keys | Sort-Object)) {
        $Monitor = $Monitors | Where-Object { $_.DisplayNumber -eq $MonitorNumber } | Select-Object -First 1
        
        if (-not $Monitor) {
            Write-Log "Monitor $MonitorNumber not found, skipping rules for this monitor" -Level WARN
            $SkippedCount += $RulesByMonitor[$MonitorNumber].Count
            continue
        }
        
        Write-Log "Processing monitor $MonitorNumber..." -Level INFO
        
        $RulesForMonitor = $RulesByMonitor[$MonitorNumber]
        $HasLeft = $RulesForMonitor | Where-Object { $_.Rule.Position -eq 'left' }
        $HasRight = $RulesForMonitor | Where-Object { $_.Rule.Position -eq 'right' }
        
        $Zones = Get-ZonesForMonitor -Monitor $Monitor -HasLeftRule ($null -ne $HasLeft) -HasRightRule ($null -ne $HasRight)
        
        foreach ($RuleEntry in $RulesForMonitor) {
            $RuleName = $RuleEntry.Name
            $Rule = $RuleEntry.Rule
            
            Write-Log "Applying rule '$RuleName' ($($Rule.DisplayName))..." -Level INFO
            Write-Log "  Target: Monitor $($Rule.MonitorNumber), Position: $($Rule.Position)" -Level INFO
            if ($Rule.TitlePattern) {
                Write-Log "  Title filter: '$($Rule.TitlePattern)'" -Level INFO
            }
            
            $UseOverlap = if ($Rule.ContainsKey('UseOverlap')) { $Rule.UseOverlap } else { $true }
            $OverlapStatus = if ($null -eq $UseOverlap) { "auto" } elseif ($UseOverlap) { "enabled" } else { "disabled" }
            Write-Log "  Border overlap: $OverlapStatus" -Level INFO
            
            $Window = Select-WindowForRule -Windows $Windows -Rule $Rule -AllRules $WindowLayoutConfig
            
            if (-not $Window) {
                Write-Log "  No matching window found" -Level WARN
                $SkippedCount++
                continue
            }
            
            $Window.AssignedToRule = $RuleName
            
            Write-Log "  Found window: '$($Window.Title)' (PID: $($Window.ProcessId))" -Level INFO
            Write-Log "  Current: Monitor $($Window.MonitorNumber), $($Window.Rect.Width)x$($Window.Rect.Height)$(if($Window.IsMaximized){' [Maximized]'})" -Level INFO
            
            $Zone = $Zones[$Rule.Position]
            
            if (Set-WindowSnapBorderOverlap -hWnd $Window.Handle -Position $Rule.Position -Zone $Zone -BorderWidth $BorderWidth -UseOverlap $UseOverlap -DryRun:$DryRun) {
                $MovedCount++
            } else {
                $SkippedCount++
            }
        }
    }
    
    Write-Log "Placement complete: $MovedCount moved, $SkippedCount skipped" -Level INFO
    Write-Log "Script execution completed successfully" -Level INFO
    
} catch {
    Write-Log "Script execution failed: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $ExecutionTime seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "========================================" -Level INFO
}

if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
