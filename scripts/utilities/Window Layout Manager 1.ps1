<#
.SYNOPSIS
    Automatically positions application windows to specific monitors and zones

.DESCRIPTION
    This script manages window placement across multiple monitors using a configuration
    hashtable. It detects all monitors using Windows' display settings numbering, and
    positions application windows to specified zones (left, right, or full).
    
    Key features:
    - Matches Windows display settings monitor numbering
    - Supports left/right/full window zones with true Windows snap behavior
    - Automatically snaps left/right windows together without gaps
    - Accounts for taskbar in all calculations
    - Only moves exactly the number of windows declared in configuration
    - Handles multiple windows of same application with distinct placement
    - Supports wildcard patterns in TitlePattern (e.g., *Chrome*, Jira*)
    - Uses proper restore/maximize states (no keystroke forwarding)
    - Profile-based configurations via -LayoutProfile parameter
    - Brings windows to foreground after relocation
    
    This script runs unattended without user interaction.

.PARAMETER LayoutProfile
    Layout profile name to apply. Format examples:
    - '2xChrome1xVSCode' - 2 Chrome windows (left/right), 1 VS Code (full)
    - '2xBDE2xSAP' - 2 BDE windows, 2 SAP windows
    - Custom profiles defined in script or loaded from file

.PARAMETER ConfigPath
    Optional path to external configuration file. If not provided, uses internal config.

.PARAMETER DryRun
    If specified, shows what would be done without actually moving windows.

.EXAMPLE
    PS> .\Window Layout Manager 1.ps1 -LayoutProfile '2xChrome1xVSCode'
    Applies preset: 2 Chrome windows (left/right), 1 VS Code (full)
    
.EXAMPLE
    PS> .\Window Layout Manager 1.ps1 -LayoutProfile '2xBDE2xSAP'
    Applies preset: 2 BDE windows (left/right), 2 SAP windows (left/right)
    
.EXAMPLE
    PS> .\Window Layout Manager 1.ps1 -LayoutProfile 'DevSetup' -DryRun
    Shows what DevSetup profile would do without moving windows

.NOTES
    Script Name:    Window Layout Manager 1.ps1
    Author:         Windows Automation Framework
    Version:        1.4
    Creation Date:  2026-02-14
    Last Modified:  2026-02-14
    
    Execution Context: User or SYSTEM
    Execution Frequency: On-demand or triggered by login/display change
    Typical Duration: ~2-5 seconds
    Timeout Setting: 30 seconds
    
    User Interaction: NONE (fully automated, no prompts)
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
    [switch]$DryRun
)

#Requires -Version 5.1

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "1.4"
$LogLevel = "INFO"
$VerbosePreference = 'SilentlyContinue'
$DefaultTimeout = 30

# ============================================================================
# LAYOUT PROFILES
# ============================================================================
# Define preset layout configurations
# Format: ProfileName = hashtable of window rules

$LayoutProfiles = @{
    # Development setup: 2 Chrome + 1 VS Code
    '2xChrome1xVSCode' = @{
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
        VSCodeFull = @{
            ApplicationName = 'Code'
            DisplayName     = 'VS Code Full'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'full'
        }
    }
    
    # Business applications: 2 BDE + 2 SAP
    '2xBDE2xSAP' = @{
        BDELeft = @{
            ApplicationName = 'BDE'
            DisplayName     = 'BDE Left'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'left'
        }
        BDERight = @{
            ApplicationName = 'BDE'
            DisplayName     = 'BDE Right'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'right'
        }
        SAPLeft = @{
            ApplicationName = 'saplogon'
            DisplayName     = 'SAP Left'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'left'
        }
        SAPRight = @{
            ApplicationName = 'saplogon'
            DisplayName     = 'SAP Right'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'right'
        }
    }
    
    # Web development: Chrome with specific tabs
    'WebDev' = @{
        ChromeJira = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Jira'
            TitlePattern    = '*Jira*'
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
        VSCodeFull = @{
            ApplicationName = 'Code'
            DisplayName     = 'VS Code'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'full'
        }
    }
    
    # Data analysis: Excel + PowerBI
    'DataAnalysis' = @{
        ExcelLeft = @{
            ApplicationName = 'EXCEL'
            DisplayName     = 'Excel'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'left'
        }
        PowerBIRight = @{
            ApplicationName = 'PBIDesktop'
            DisplayName     = 'Power BI'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'right'
        }
    }
    
    # Triple Chrome setup for multi-tasking
    '3xChrome' = @{
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
        ChromeFull = @{
            ApplicationName = 'chrome'
            DisplayName     = 'Chrome Full'
            TitlePattern    = $null
            MonitorNumber   = 2
            Position        = 'full'
        }
    }
    
    # Simple dual browser
    '2xChrome' = @{
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
    
    # Email + Calendar
    'EmailCalendar' = @{
        OutlookLeft = @{
            ApplicationName = 'OUTLOOK'
            DisplayName     = 'Outlook Mail'
            TitlePattern    = '*Inbox*'
            MonitorNumber   = 1
            Position        = 'left'
        }
        OutlookRight = @{
            ApplicationName = 'OUTLOOK'
            DisplayName     = 'Outlook Calendar'
            TitlePattern    = '*Calendar*'
            MonitorNumber   = 1
            Position        = 'right'
        }
    }
    
    # Teams + OneNote for meetings
    'MeetingSetup' = @{
        TeamsLeft = @{
            ApplicationName = 'ms-teams'
            DisplayName     = 'Microsoft Teams'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'left'
        }
        OneNoteRight = @{
            ApplicationName = 'ONENOTE'
            DisplayName     = 'OneNote'
            TitlePattern    = $null
            MonitorNumber   = 1
            Position        = 'right'
        }
    }
}

# Default configuration (used when no profile specified)
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

public struct DISPLAY_DEVICE {
    public uint cb;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string DeviceName;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
    public string DeviceString;
    public uint StateFlags;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
    public string DeviceID;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
    public string DeviceKey;
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
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    // Constants
    public const uint MONITOR_DEFAULTTONEAREST = 2;
    public const uint SWP_NOZORDER = 0x0004;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_SHOWWINDOW = 0x0040;
    public const uint SWP_FRAMECHANGED = 0x0020;
    public const IntPtr HWND_TOP = 0;
    public const IntPtr HWND_TOPMOST = -1;
    public const IntPtr HWND_NOTOPMOST = -2;
    
    // ShowWindow constants
    public const int SW_RESTORE = 9;
    public const int SW_MAXIMIZE = 3;
    public const int SW_SHOWNOACTIVATE = 4;
    public const int SW_SHOW = 5;
    
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
    <#
    .SYNOPSIS
        Loads layout configuration based on profile or file
    .DESCRIPTION
        Priority order:
        1. External config file (if ConfigPath provided)
        2. Named profile (if LayoutProfile provided)
        3. Default configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProfileName,
        
        [Parameter(Mandatory=$false)]
        [string]$FilePath
    )
    
    # Priority 1: External file
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
    
    # Priority 2: Named profile
    if ($ProfileName) {
        if ($LayoutProfiles.ContainsKey($ProfileName)) {
            Write-Log "Loading layout profile: $ProfileName" -Level INFO
            $Config = $LayoutProfiles[$ProfileName]
            
            # Count applications and positions
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
    
    # Priority 3: Default
    Write-Log "Using default configuration" -Level INFO
    return $DefaultWindowLayoutConfig
}

function Set-ForegroundWindowForced {
    <#
    .SYNOPSIS
        Brings a window to the foreground using multiple techniques
    .DESCRIPTION
        Uses thread attachment and multiple API calls to reliably
        bring a window to the foreground, even if it belongs to
        another process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$hWnd,
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    if ($DryRun) {
        Write-Log "  [DRY RUN] Would bring window to foreground" -Level DEBUG
        return $true
    }
    
    try {
        # Get current foreground window and its thread
        $ForegroundWindow = [Win32]::GetForegroundWindow()
        $CurrentThreadId = [Win32]::GetCurrentThreadId()
        
        # Get target window thread
        $TargetProcessId = 0
        $TargetThreadId = [Win32]::GetWindowThreadProcessId($hWnd, [ref]$TargetProcessId)
        
        # Attach to the foreground window's thread to gain permission to change focus
        if ($ForegroundWindow -ne [IntPtr]::Zero -and $ForegroundWindow -ne $hWnd) {
            $ForegroundThreadId = [Win32]::GetWindowThreadProcessId($ForegroundWindow, [ref]$TargetProcessId)
            
            if ($ForegroundThreadId -ne $CurrentThreadId) {
                [Win32]::AttachThreadInput($CurrentThreadId, $ForegroundThreadId, $true) | Out-Null
            }
        }
        
        # Bring window to top and set as foreground
        [Win32]::BringWindowToTop($hWnd) | Out-Null
        [Win32]::ShowWindow($hWnd, [Win32]::SW_SHOW) | Out-Null
        $Result = [Win32]::SetForegroundWindow($hWnd)
        
        # Detach thread input
        if ($ForegroundWindow -ne [IntPtr]::Zero -and $ForegroundWindow -ne $hWnd) {
            $ForegroundThreadId = [Win32]::GetWindowThreadProcessId($ForegroundWindow, [ref]$TargetProcessId)
            
            if ($ForegroundThreadId -ne $CurrentThreadId) {
                [Win32]::AttachThreadInput($CurrentThreadId, $ForegroundThreadId, $false) | Out-Null
            }
        }
        
        if ($Result) {
            Write-Log "  Window brought to foreground" -Level DEBUG
        } else {
            Write-Log "  Failed to bring window to foreground (may require additional permissions)" -Level DEBUG
        }
        
        return $true
        
    } catch {
        Write-Log "  Error bringing window to foreground: $_" -Level DEBUG
        return $false
    }
}

function Convert-WildcardToRegex {
    <#
    .SYNOPSIS
        Converts wildcard pattern to regex pattern
    .DESCRIPTION
        Converts simple wildcard patterns (*, ?) to equivalent regex.
        If pattern is already regex (no wildcards), returns as-is.
    .PARAMETER Pattern
        Wildcard or regex pattern
    .EXAMPLE
        Convert-WildcardToRegex '*Chrome*' returns '.*Chrome.*'
        Convert-WildcardToRegex 'Jira*' returns 'Jira.*'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern
    )
    
    # Check if pattern contains wildcards
    if ($Pattern -match '[*?]') {
        # Escape regex special characters except * and ?
        $Escaped = [regex]::Escape($Pattern)
        
        # Convert wildcards to regex
        $Escaped = $Escaped -replace '\\\*', '.*'  # * becomes .*
        $Escaped = $Escaped -replace '\\\?', '.'   # ? becomes .
        
        Write-Log "  Converted wildcard '$Pattern' to regex '$Escaped'" -Level DEBUG
        return $Escaped
    } else {
        # No wildcards, treat as regex (or plain string)
        return $Pattern
    }
}

function Get-MonitorLayout {
    <#
    .SYNOPSIS
        Enumerates all monitors with Windows display settings numbering
    .DESCRIPTION
        Uses Windows API to enumerate monitors and assigns display numbers
        matching the order shown in Windows display settings.
        Primary monitor is always 1, others ordered left-to-right, top-to-bottom.
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Enumerating monitors..." -Level INFO
    
    $MonitorList = New-Object System.Collections.ArrayList
    
    # Enumerate all monitors
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
                DisplayNumber = 0  # Assigned later
            }
            
            [void]$MonitorList.Add($MonitorObj)
        }
        
        return $true
    }
    
    $CallbackDelegate = [Win32+MonitorEnumDelegate]$Callback
    [Win32]::EnumDisplayMonitors([IntPtr]::Zero, [IntPtr]::Zero, $CallbackDelegate, [IntPtr]::Zero) | Out-Null
    
    # Assign display numbers: primary = 1, rest sorted by X then Y
    $DisplayNumber = 1
    
    # Primary monitor first
    $Primary = $MonitorList | Where-Object { $_.IsPrimary }
    if ($Primary) {
        $Primary.DisplayNumber = $DisplayNumber++
    }
    
    # Sort remaining monitors by X (left-to-right), then Y (top-to-bottom)
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
    <#
    .SYNOPSIS
        Retrieves window title for a window handle
    #>
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
    <#
    .SYNOPSIS
        Enumerates all visible windows for specified applications
    .DESCRIPTION
        Returns a list of window objects with handle, process name, title,
        monitor number, and current position.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Monitors
    )
    
    Write-Log "Enumerating application windows..." -Level INFO
    
    $WindowList = New-Object System.Collections.ArrayList
    
    # Enumerate all windows
    $Callback = {
        param($hWnd, $lParam)
        
        # Only visible, non-minimized windows
        if ([Win32]::IsWindowVisible($hWnd) -and -not [Win32]::IsIconic($hWnd)) {
            # Get process ID
            $ProcessId = 0
            [Win32]::GetWindowThreadProcessId($hWnd, [ref]$ProcessId) | Out-Null
            
            if ($ProcessId -ne 0) {
                try {
                    $Process = Get-Process -Id $ProcessId -ErrorAction Stop
                    
                    # Get window rectangle
                    $Rect = New-Object RECT
                    if ([Win32]::GetWindowRect($hWnd, [ref]$Rect)) {
                        # Get monitor this window is on
                        $hMonitor = [Win32]::MonitorFromWindow($hWnd, [Win32]::MONITOR_DEFAULTTONEAREST)
                        $MonitorObj = $Monitors | Where-Object { $_.Handle -eq $hMonitor } | Select-Object -First 1
                        
                        # Check if window is maximized
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
                            AssignedToRule = $null  # Track which rule claimed this window
                        }
                        
                        [void]$WindowList.Add($WindowObj)
                    }
                } catch {
                    # Process may have exited, skip
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
    <#
    .SYNOPSIS
        Calculates zone rectangles for a monitor
    .DESCRIPTION
        Computes left, right, and full zones based on WorkArea.
        Handles snap-to-edge logic when both left and right are used.
    .PARAMETER Monitor
        Monitor object with WorkArea property
    .PARAMETER HasLeftRule
        Whether a 'left' rule exists for this monitor
    .PARAMETER HasRightRule
        Whether a 'right' rule exists for this monitor
    #>
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
    
    # If both left and right exist, ensure no gap
    if ($HasLeftRule -and $HasRightRule) {
        $LeftWidth = [Math]::Floor($WA.Width / 2)
        $RightWidth = $WA.Width - $LeftWidth  # Ensures total = WorkArea.Width
        
        $Zones = @{
            left  = @{ X = $WA.X; Y = $WA.Y; Width = $LeftWidth; Height = $WA.Height }
            right = @{ X = $WA.X + $LeftWidth; Y = $WA.Y; Width = $RightWidth; Height = $WA.Height }
            full  = @{ X = $WA.X; Y = $WA.Y; Width = $WA.Width; Height = $WA.Height }
        }
    } else {
        # Standard half-split (small gap acceptable if only one side used)
        $HalfWidth = [Math]::Floor($WA.Width / 2)
        
        $Zones = @{
            left  = @{ X = $WA.X; Y = $WA.Y; Width = $HalfWidth; Height = $WA.Height }
            right = @{ X = $WA.X + $HalfWidth; Y = $WA.Y; Width = $WA.Width - $HalfWidth; Height = $WA.Height }
            full  = @{ X = $WA.X; Y = $WA.Y; Width = $WA.Width; Height = $WA.Height }
        }
    }
    
    return $Zones
}

function Set-WindowSnap {
    <#
    .SYNOPSIS
        Snaps window to zone using proper Windows snap behavior
    .DESCRIPTION
        Uses WINDOWPLACEMENT to properly snap windows like Windows Snap Assist.
        For 'full' position, maximizes the window.
        For 'left' and 'right', restores window and positions to zone.
        This mimics Win+Left, Win+Right, Win+Up behavior without keystrokes.
        After relocation, brings window to foreground.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$hWnd,
        
        [Parameter(Mandatory=$true)]
        [string]$Position,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Zone,
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    if ($DryRun) {
        Write-Log "  [DRY RUN] Would snap to $Position (X=$($Zone.X), Y=$($Zone.Y), W=$($Zone.Width), H=$($Zone.Height))" -Level INFO
        return $true
    }
    
    try {
        if ($Position -eq 'full') {
            # Maximize window
            Write-Log "  Maximizing window" -Level DEBUG
            $Result = [Win32]::ShowWindow($hWnd, [Win32]::SW_MAXIMIZE)
            
            if ($Result) {
                Write-Log "  Window maximized successfully" -Level INFO
            } else {
                Write-Log "  Failed to maximize window" -Level WARN
                return $false
            }
        } else {
            # Left or Right snap: restore then position
            Write-Log "  Snapping to $Position" -Level DEBUG
            
            # Get current window placement
            $Placement = New-Object WINDOWPLACEMENT
            $Placement.length = [System.Runtime.InteropServices.Marshal]::SizeOf($Placement)
            
            if (-not [Win32]::GetWindowPlacement($hWnd, [ref]$Placement)) {
                Write-Log "  Failed to get window placement" -Level WARN
                return $false
            }
            
            # Set to normal (restored) state
            $Placement.showCmd = [Win32]::SW_RESTORE
            
            # Set the normal position to the snap zone
            $Placement.rcNormalPosition.Left = $Zone.X
            $Placement.rcNormalPosition.Top = $Zone.Y
            $Placement.rcNormalPosition.Right = $Zone.X + $Zone.Width
            $Placement.rcNormalPosition.Bottom = $Zone.Y + $Zone.Height
            
            $Placement.flags = 0
            
            # Apply the placement
            if ([Win32]::SetWindowPlacement($hWnd, [ref]$Placement)) {
                Write-Log "  Snapped to X=$($Zone.X), Y=$($Zone.Y), W=$($Zone.Width), H=$($Zone.Height)" -Level INFO
                
                # Force frame update
                $Flags = [Win32]::SWP_NOZORDER -bor [Win32]::SWP_NOACTIVATE -bor [Win32]::SWP_FRAMECHANGED
                [Win32]::SetWindowPos($hWnd, [IntPtr]::Zero, $Zone.X, $Zone.Y, $Zone.Width, $Zone.Height, $Flags) | Out-Null
            } else {
                Write-Log "  Failed to set window placement" -Level WARN
                return $false
            }
        }
        
        # Bring window to foreground after relocation
        Set-ForegroundWindowForced -hWnd $hWnd -DryRun:$DryRun | Out-Null
        
        return $true
        
    } catch {
        Write-Log "  Error during snap operation: $_" -Level ERROR
        return $false
    }
}

function Select-WindowForRule {
    <#
    .SYNOPSIS
        Selects best matching window for a placement rule
    .DESCRIPTION
        Finds an unassigned window matching the process name and optional title pattern.
        Supports wildcard patterns (*, ?) and regex patterns.
        Returns the window object or $null if no match.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Windows,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Rule
    )
    
    # Filter to matching process name
    $Candidates = $Windows | Where-Object { 
        $_.ProcessName -eq $Rule.ApplicationName -and 
        $null -eq $_.AssignedToRule  # Not yet assigned
    }
    
    if ($Candidates.Count -eq 0) {
        return $null
    }
    
    # Apply title pattern filter if specified
    if ($Rule.TitlePattern) {
        # Convert wildcard to regex if needed
        $RegexPattern = Convert-WildcardToRegex -Pattern $Rule.TitlePattern
        
        Write-Log "  Filtering by title pattern: '$($Rule.TitlePattern)'" -Level DEBUG
        
        $Candidates = $Candidates | Where-Object { $_.Title -match $RegexPattern }
        
        if ($Candidates.Count -eq 0) {
            Write-Log "  No windows matched title pattern '$($Rule.TitlePattern)'" -Level DEBUG
            return $null
        }
        
        Write-Log "  Found $($Candidates.Count) window(s) matching title pattern" -Level DEBUG
    }
    
    # Prefer window already on target monitor
    $OnTargetMonitor = $Candidates | Where-Object { $_.MonitorNumber -eq $Rule.MonitorNumber }
    if ($OnTargetMonitor) {
        return $OnTargetMonitor | Select-Object -First 1
    }
    
    # Otherwise, take first available
    return $Candidates | Select-Object -First 1
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    if ($DryRun) {
        Write-Log "DRY RUN MODE - No changes will be made" -Level WARN
    }
    Write-Log "========================================" -Level INFO
    
    # Load configuration based on parameters
    $WindowLayoutConfig = Get-LayoutConfiguration -ProfileName $LayoutProfile -FilePath $ConfigPath
    
    # Validate configuration
    if ($WindowLayoutConfig.Count -eq 0) {
        throw "No window layout rules defined"
    }
    
    Write-Log "Loaded $($WindowLayoutConfig.Count) window placement rule(s)" -Level INFO
    
    # Step 1: Enumerate monitors
    $Monitors = Get-MonitorLayout
    
    if ($Monitors.Count -eq 0) {
        throw "No monitors detected"
    }
    
    # Step 2: Enumerate all windows
    $Windows = Get-ApplicationWindows -Monitors $Monitors
    
    # Step 3: Group rules by monitor for snap calculation
    $RulesByMonitor = @{}
    foreach ($RuleName in $WindowLayoutConfig.Keys) {
        $Rule = $WindowLayoutConfig[$RuleName]
        $MonNum = $Rule.MonitorNumber
        
        if (-not $RulesByMonitor.ContainsKey($MonNum)) {
            $RulesByMonitor[$MonNum] = @()
        }
        
        $RulesByMonitor[$MonNum] += @{ Name = $RuleName; Rule = $Rule }
    }
    
    # Step 4: Apply rules
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
        
        # Check if both left and right rules exist for snap logic
        $RulesForMonitor = $RulesByMonitor[$MonitorNumber]
        $HasLeft = $RulesForMonitor | Where-Object { $_.Rule.Position -eq 'left' }
        $HasRight = $RulesForMonitor | Where-Object { $_.Rule.Position -eq 'right' }
        
        # Calculate zones with snap awareness
        $Zones = Get-ZonesForMonitor -Monitor $Monitor -HasLeftRule ($null -ne $HasLeft) -HasRightRule ($null -ne $HasRight)
        
        # Apply each rule
        foreach ($RuleEntry in $RulesForMonitor) {
            $RuleName = $RuleEntry.Name
            $Rule = $RuleEntry.Rule
            
            Write-Log "Applying rule '$RuleName' ($($Rule.DisplayName))..." -Level INFO
            Write-Log "  Target: Monitor $($Rule.MonitorNumber), Position: $($Rule.Position)" -Level INFO
            if ($Rule.TitlePattern) {
                Write-Log "  Title filter: '$($Rule.TitlePattern)'" -Level INFO
            }
            
            # Find matching window
            $Window = Select-WindowForRule -Windows $Windows -Rule $Rule
            
            if (-not $Window) {
                Write-Log "  No matching window found" -Level WARN
                $SkippedCount++
                continue
            }
            
            # Mark window as assigned to this rule
            $Window.AssignedToRule = $RuleName
            
            Write-Log "  Found window: '$($Window.Title)' (PID: $($Window.ProcessId))" -Level INFO
            Write-Log "  Current: Monitor $($Window.MonitorNumber), $($Window.Rect.Width)x$($Window.Rect.Height)$(if($Window.IsMaximized){' [Maximized]'})" -Level INFO
            
            # Get target zone
            $Zone = $Zones[$Rule.Position]
            
            # Snap window
            if (Set-WindowSnap -hWnd $Window.Handle -Position $Rule.Position -Zone $Zone -DryRun:$DryRun) {
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
