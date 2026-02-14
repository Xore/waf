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
    - Automatically snaps left/right windows together WITHOUT gaps
    - Accounts for taskbar and DWM invisible window frames in all calculations
    - Only moves exactly the number of windows declared in configuration
    - Handles multiple windows of same application with distinct placement
    - Supports wildcard patterns in TitlePattern
    - Uses proper restore/maximize states
    - Profile-based configurations
    - Compensates for invisible window borders in Windows 10/11
    
    This script runs unattended without user interaction.

.PARAMETER LayoutProfile
    Layout profile name to apply

.PARAMETER ConfigPath
    Optional path to external configuration file

.PARAMETER DryRun
    If specified, shows what would be done without actually moving windows

.NOTES
    Script Name:    Window Layout Manager 1.ps1
    Author:         Windows Automation Framework
    Version:        1.7
    Creation Date:  2026-02-14
    Last Modified:  2026-02-14
    
    Dependencies:
        - Windows PowerShell 5.1+
        - Windows 10/11
        - User32.dll, Dwmapi.dll
    
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

$ScriptVersion = "1.7"
$LogLevel = "INFO"
$VerbosePreference = 'SilentlyContinue'
$DefaultTimeout = 30

$LayoutProfiles = @{
    '2xChrome1xVSCode' = @{
        ChromeLeft = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Left'; TitlePattern = $null; MonitorNumber = 1; Position = 'left' }
        ChromeRight = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Right'; TitlePattern = $null; MonitorNumber = 1; Position = 'right' }
        VSCodeFull = @{ ApplicationName = 'Code'; DisplayName = 'VS Code Full'; TitlePattern = $null; MonitorNumber = 2; Position = 'full' }
    }
    '2xBDE2xSAP' = @{
        BDELeft = @{ ApplicationName = 'BDE'; DisplayName = 'BDE Left'; TitlePattern = $null; MonitorNumber = 1; Position = 'left' }
        BDERight = @{ ApplicationName = 'BDE'; DisplayName = 'BDE Right'; TitlePattern = $null; MonitorNumber = 1; Position = 'right' }
        SAPLeft = @{ ApplicationName = 'saplogon'; DisplayName = 'SAP Left'; TitlePattern = $null; MonitorNumber = 2; Position = 'left' }
        SAPRight = @{ ApplicationName = 'saplogon'; DisplayName = 'SAP Right'; TitlePattern = $null; MonitorNumber = 2; Position = 'right' }
    }
    'WebDev' = @{
        ChromeJira = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Jira'; TitlePattern = '*Jira*'; MonitorNumber = 1; Position = 'left' }
        ChromeGitHub = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome GitHub'; TitlePattern = '*GitHub*'; MonitorNumber = 1; Position = 'right' }
        VSCodeFull = @{ ApplicationName = 'Code'; DisplayName = 'VS Code'; TitlePattern = $null; MonitorNumber = 2; Position = 'full' }
    }
    'DataAnalysis' = @{
        ExcelLeft = @{ ApplicationName = 'EXCEL'; DisplayName = 'Excel'; TitlePattern = $null; MonitorNumber = 1; Position = 'left' }
        PowerBIRight = @{ ApplicationName = 'PBIDesktop'; DisplayName = 'Power BI'; TitlePattern = $null; MonitorNumber = 1; Position = 'right' }
    }
    '3xChrome' = @{
        ChromeLeft = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Left'; TitlePattern = $null; MonitorNumber = 1; Position = 'left' }
        ChromeRight = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Right'; TitlePattern = $null; MonitorNumber = 1; Position = 'right' }
        ChromeFull = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Full'; TitlePattern = $null; MonitorNumber = 2; Position = 'full' }
    }
    '2xChrome' = @{
        ChromeLeft = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Left'; TitlePattern = $null; MonitorNumber = 1; Position = 'left' }
        ChromeRight = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Right'; TitlePattern = $null; MonitorNumber = 1; Position = 'right' }
    }
    'EmailCalendar' = @{
        OutlookLeft = @{ ApplicationName = 'OUTLOOK'; DisplayName = 'Outlook Mail'; TitlePattern = '*Inbox*'; MonitorNumber = 1; Position = 'left' }
        OutlookRight = @{ ApplicationName = 'OUTLOOK'; DisplayName = 'Outlook Calendar'; TitlePattern = '*Calendar*'; MonitorNumber = 1; Position = 'right' }
    }
    'MeetingSetup' = @{
        TeamsLeft = @{ ApplicationName = 'ms-teams'; DisplayName = 'Microsoft Teams'; TitlePattern = $null; MonitorNumber = 1; Position = 'left' }
        OneNoteRight = @{ ApplicationName = 'ONENOTE'; DisplayName = 'OneNote'; TitlePattern = $null; MonitorNumber = 1; Position = 'right' }
    }
}

$DefaultWindowLayoutConfig = @{
    ChromeLeft = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Left'; TitlePattern = $null; MonitorNumber = 1; Position = 'left' }
    ChromeRight = @{ ApplicationName = 'chrome'; DisplayName = 'Chrome Right'; TitlePattern = $null; MonitorNumber = 1; Position = 'right' }
}

$StartTime = Get-Date
$ScriptName = $MyInvocation.MyCommand.Name
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0

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
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
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
    [DllImport("dwmapi.dll")]
    public static extern int DwmGetWindowAttribute(IntPtr hwnd, int dwAttribute, out RECT pvAttribute, int cbAttribute);
    
    public const uint MONITOR_DEFAULTTONEAREST = 2;
    public const uint SWP_NOZORDER = 0x0004;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_SHOWWINDOW = 0x0040;
    public const uint SWP_FRAMECHANGED = 0x0020;
    public const int SW_RESTORE = 9;
    public const int SW_MAXIMIZE = 3;
    public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
}
"@

function Write-Log {
    param([string]$Message, [ValidateSet('DEBUG','INFO','WARN','ERROR')][string]$Level = 'INFO')
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    switch ($Level) {
        'DEBUG' { if ($LogLevel -eq 'DEBUG') { Write-Verbose $LogMessage } }
        'INFO'  { Write-Host $LogMessage -ForegroundColor Cyan }
        'WARN'  { Write-Warning $LogMessage; $script:WarningCount++ }
        'ERROR' { Write-Host $LogMessage -ForegroundColor Red; $script:ErrorCount++ }
    }
}

function Get-LayoutConfiguration {
    param([string]$ProfileName, [string]$FilePath)
    if ($FilePath -and (Test-Path $FilePath)) {
        Write-Log "Loading configuration from file: $FilePath"
        return Import-Clixml $FilePath
    }
    if ($ProfileName) {
        if ($LayoutProfiles.ContainsKey($ProfileName)) {
            Write-Log "Loading layout profile: $ProfileName"
            return $LayoutProfiles[$ProfileName]
        }
        throw "Unknown layout profile: $ProfileName"
    }
    Write-Log "Using default configuration"
    return $DefaultWindowLayoutConfig
}

function Get-MonitorLayout {
    Write-Log "Enumerating monitors..."
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
                Handle = $hMonitor
                IsPrimary = $IsPrimary
                Bounds = [PSCustomObject]@{ X = $Mon.Left; Y = $Mon.Top; Width = $Mon.Right - $Mon.Left; Height = $Mon.Bottom - $Mon.Top }
                WorkArea = [PSCustomObject]@{ X = $Work.Left; Y = $Work.Top; Width = $Work.Right - $Work.Left; Height = $Work.Bottom - $Work.Top }
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
    if ($Primary) { $Primary.DisplayNumber = $DisplayNumber++ }
    $Secondary = $MonitorList | Where-Object { -not $_.IsPrimary } | Sort-Object { $_.Bounds.X }, { $_.Bounds.Y }
    foreach ($Mon in $Secondary) { $Mon.DisplayNumber = $DisplayNumber++ }
    return $MonitorList.ToArray()
}

function Get-WindowTitle {
    param([IntPtr]$hWnd)
    $Length = [Win32]::GetWindowTextLength($hWnd)
    if ($Length -eq 0) { return "" }
    $Builder = New-Object System.Text.StringBuilder ($Length + 1)
    [Win32]::GetWindowText($hWnd, $Builder, $Builder.Capacity) | Out-Null
    return $Builder.ToString()
}

function Get-WindowFrameSize {
    param([IntPtr]$hWnd)
    try {
        $WindowRect = New-Object RECT
        [Win32]::GetWindowRect($hWnd, [ref]$WindowRect) | Out-Null
        $FrameRect = New-Object RECT
        $Result = [Win32]::DwmGetWindowAttribute(
            $hWnd,
            [Win32]::DWMWA_EXTENDED_FRAME_BOUNDS,
            [ref]$FrameRect,
            [System.Runtime.InteropServices.Marshal]::SizeOf($FrameRect)
        )
        if ($Result -eq 0) {
            return [PSCustomObject]@{
                Left = $FrameRect.Left - $WindowRect.Left
                Top = $FrameRect.Top - $WindowRect.Top
                Right = $WindowRect.Right - $FrameRect.Right
                Bottom = $WindowRect.Bottom - $FrameRect.Bottom
            }
        }
    } catch {}
    return [PSCustomObject]@{ Left = 7; Top = 0; Right = 7; Bottom = 7 }
}

function Get-ApplicationWindows {
    param([array]$Monitors)
    Write-Log "Enumerating application windows..."
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
                        $WindowObj = [PSCustomObject]@{
                            Handle = $hWnd
                            ProcessId = $ProcessId
                            ProcessName = $Process.ProcessName
                            Title = Get-WindowTitle -hWnd $hWnd
                            MonitorNumber = if ($MonitorObj) { $MonitorObj.DisplayNumber } else { 0 }
                            IsMaximized = [Win32]::IsZoomed($hWnd)
                            Rect = [PSCustomObject]@{ X = $Rect.Left; Y = $Rect.Top; Width = $Rect.Right - $Rect.Left; Height = $Rect.Bottom - $Rect.Top }
                            AssignedToRule = $null
                        }
                        [void]$WindowList.Add($WindowObj)
                    }
                } catch {}
            }
        }
        return $true
    }
    $CallbackDelegate = [Win32+EnumWindowsProc]$Callback
    [Win32]::EnumWindows($CallbackDelegate, [IntPtr]::Zero) | Out-Null
    Write-Log "Found $($WindowList.Count) total visible windows"
    return $WindowList.ToArray()
}

function Get-ZonesForMonitor {
    param([PSCustomObject]$Monitor, [bool]$HasLeftRule = $false, [bool]$HasRightRule = $false)
    $WA = $Monitor.WorkArea
    if ($HasLeftRule -and $HasRightRule) {
        $LeftWidth = [Math]::Floor($WA.Width / 2)
        $RightWidth = $WA.Width - $LeftWidth
        return @{
            left = @{ X = $WA.X; Y = $WA.Y; Width = $LeftWidth; Height = $WA.Height }
            right = @{ X = $WA.X + $LeftWidth; Y = $WA.Y; Width = $RightWidth; Height = $WA.Height }
            full = @{ X = $WA.X; Y = $WA.Y; Width = $WA.Width; Height = $WA.Height }
        }
    }
    $HalfWidth = [Math]::Floor($WA.Width / 2)
    return @{
        left = @{ X = $WA.X; Y = $WA.Y; Width = $HalfWidth; Height = $WA.Height }
        right = @{ X = $WA.X + $HalfWidth; Y = $WA.Y; Width = $WA.Width - $HalfWidth; Height = $WA.Height }
        full = @{ X = $WA.X; Y = $WA.Y; Width = $WA.Width; Height = $WA.Height }
    }
}

function Set-WindowSnap {
    param([IntPtr]$hWnd, [string]$Position, [hashtable]$Zone, [switch]$DryRun)
    if ($DryRun) {
        Write-Log "  [DRY RUN] Would snap to $Position (X=$($Zone.X), Y=$($Zone.Y), W=$($Zone.Width), H=$($Zone.Height))"
        return $true
    }
    try {
        if ($Position -eq 'full') {
            $Result = [Win32]::ShowWindow($hWnd, [Win32]::SW_MAXIMIZE)
            if ($Result) {
                Write-Log "  Window maximized successfully"
                return $true
            }
            Write-Log "  Failed to maximize window" -Level WARN
            return $false
        }
        $Frame = Get-WindowFrameSize -hWnd $hWnd
        Write-Log "  Frame borders: L=$($Frame.Left), T=$($Frame.Top), R=$($Frame.Right), B=$($Frame.Bottom)" -Level DEBUG
        $AdjustedX = $Zone.X - $Frame.Left
        $AdjustedY = $Zone.Y - $Frame.Top
        $AdjustedWidth = $Zone.Width + $Frame.Left + $Frame.Right
        $AdjustedHeight = $Zone.Height + $Frame.Top + $Frame.Bottom
        $Placement = New-Object WINDOWPLACEMENT
        $Placement.length = [System.Runtime.InteropServices.Marshal]::SizeOf($Placement)
        if (-not [Win32]::GetWindowPlacement($hWnd, [ref]$Placement)) {
            Write-Log "  Failed to get window placement" -Level WARN
            return $false
        }
        $Placement.showCmd = [Win32]::SW_RESTORE
        $Placement.rcNormalPosition.Left = $AdjustedX
        $Placement.rcNormalPosition.Top = $AdjustedY
        $Placement.rcNormalPosition.Right = $AdjustedX + $AdjustedWidth
        $Placement.rcNormalPosition.Bottom = $AdjustedY + $AdjustedHeight
        $Placement.flags = 0
        if ([Win32]::SetWindowPlacement($hWnd, [ref]$Placement)) {
            Write-Log "  Snapped to X=$($Zone.X), Y=$($Zone.Y), W=$($Zone.Width), H=$($Zone.Height) (compensated for DWM frame)"
            return $true
        }
        Write-Log "  Failed to set window placement" -Level WARN
        return $false
    } catch {
        Write-Log "  Error during snap operation: $_" -Level ERROR
        return $false
    }
}

function Select-WindowForRule {
    param([array]$Windows, [hashtable]$Rule)
    $Candidates = $Windows | Where-Object { $_.ProcessName -eq $Rule.ApplicationName -and $null -eq $_.AssignedToRule }
    if ($Candidates.Count -eq 0) { return $null }
    if ($Rule.TitlePattern) {
        $Pattern = $Rule.TitlePattern -replace '\*', '.*' -replace '\?', '.'
        $Candidates = $Candidates | Where-Object { $_.Title -match $Pattern }
        if ($Candidates.Count -eq 0) { return $null }
    }
    $OnTargetMonitor = $Candidates | Where-Object { $_.MonitorNumber -eq $Rule.MonitorNumber }
    if ($OnTargetMonitor) { return $OnTargetMonitor | Select-Object -First 1 }
    return $Candidates | Select-Object -First 1
}

try {
    Write-Log "Starting: $ScriptName v$ScriptVersion"
    if ($DryRun) { Write-Log "DRY RUN MODE" -Level WARN }
    $WindowLayoutConfig = Get-LayoutConfiguration -ProfileName $LayoutProfile -FilePath $ConfigPath
    if ($WindowLayoutConfig.Count -eq 0) { throw "No window layout rules defined" }
    $Monitors = Get-MonitorLayout
    if ($Monitors.Count -eq 0) { throw "No monitors detected" }
    $Windows = Get-ApplicationWindows -Monitors $Monitors
    $RulesByMonitor = @{}
    foreach ($RuleName in $WindowLayoutConfig.Keys) {
        $Rule = $WindowLayoutConfig[$RuleName]
        $MonNum = $Rule.MonitorNumber
        if (-not $RulesByMonitor.ContainsKey($MonNum)) { $RulesByMonitor[$MonNum] = @() }
        $RulesByMonitor[$MonNum] += @{ Name = $RuleName; Rule = $Rule }
    }
    $MovedCount = 0
    $SkippedCount = 0
    foreach ($MonitorNumber in ($RulesByMonitor.Keys | Sort-Object)) {
        $Monitor = $Monitors | Where-Object { $_.DisplayNumber -eq $MonitorNumber } | Select-Object -First 1
        if (-not $Monitor) {
            Write-Log "Monitor $MonitorNumber not found" -Level WARN
            $SkippedCount += $RulesByMonitor[$MonitorNumber].Count
            continue
        }
        Write-Log "Processing monitor $MonitorNumber..."
        $RulesForMonitor = $RulesByMonitor[$MonitorNumber]
        $HasLeft = $RulesForMonitor | Where-Object { $_.Rule.Position -eq 'left' }
        $HasRight = $RulesForMonitor | Where-Object { $_.Rule.Position -eq 'right' }
        $Zones = Get-ZonesForMonitor -Monitor $Monitor -HasLeftRule ($null -ne $HasLeft) -HasRightRule ($null -ne $HasRight)
        foreach ($RuleEntry in $RulesForMonitor) {
            $RuleName = $RuleEntry.Name
            $Rule = $RuleEntry.Rule
            Write-Log "Applying rule '$RuleName' ($($Rule.DisplayName))..."
            $Window = Select-WindowForRule -Windows $Windows -Rule $Rule
            if (-not $Window) {
                Write-Log "  No matching window found" -Level WARN
                $SkippedCount++
                continue
            }
            $Window.AssignedToRule = $RuleName
            Write-Log "  Found window: '$($Window.Title)' (PID: $($Window.ProcessId))"
            $Zone = $Zones[$Rule.Position]
            if (Set-WindowSnap -hWnd $Window.Handle -Position $Rule.Position -Zone $Zone -DryRun:$DryRun) {
                $MovedCount++
            } else {
                $SkippedCount++
            }
        }
    }
    Write-Log "Placement complete: $MovedCount moved, $SkippedCount skipped"
} catch {
    Write-Log "Script execution failed: $_" -Level ERROR
    exit 1
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Duration: $ExecutionTime seconds"
}
exit 0
