<#
.SYNOPSIS
    Counts running instances of a specified application with optional title filtering

.DESCRIPTION
    This script enumerates all visible windows and counts instances matching the specified
    application process name. Optionally filters by window title using wildcard patterns.
    Returns an integer count suitable for monitoring, alerting, or scripting workflows.
    
    Key features:
    - Process name matching (e.g., 'chrome', 'excel')
    - Optional wildcard title pattern filtering
    - Excludes minimized windows by default
    - Option to include minimized windows
    - Clean integer output for automation
    - Detailed logging available via -Verbose
    
    This script runs unattended without user interaction.

.PARAMETER ProcessName
    Name of the process to count (without .exe extension).
    Examples: 'chrome', 'EXCEL', 'notepad', 'Teams'
    Case-insensitive matching.

.PARAMETER TitlePattern
    Optional wildcard pattern to filter windows by title.
    Supports * (any characters) and ? (single character).
    Examples: '*GitHub*', 'Document1*', '*Meeting - Teams'
    If omitted, counts all windows of the specified process.

.PARAMETER IncludeMinimized
    If specified, includes minimized (iconic) windows in the count.
    By default, only visible non-minimized windows are counted.

.PARAMETER Quiet
    Suppresses all output except the final integer count.
    Useful for scripting and automation scenarios.

.EXAMPLE
    PS> .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome'
    3
    
    Counts all visible Chrome windows.

.EXAMPLE
    PS> .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -TitlePattern '*GitHub*'
    1
    
    Counts Chrome windows with 'GitHub' in the title.

.EXAMPLE
    PS> .\Get-ApplicationInstanceCount.ps1 -ProcessName 'EXCEL' -TitlePattern '*.xlsx*'
    2
    
    Counts Excel windows with .xlsx files open.

.EXAMPLE
    PS> .\Get-ApplicationInstanceCount.ps1 -ProcessName 'Teams' -IncludeMinimized
    1
    
    Counts Teams windows including minimized ones.

.EXAMPLE
    PS> .\Get-ApplicationInstanceCount.ps1 -ProcessName 'notepad' -Quiet
    0
    
    Quiet mode - only outputs the count number.

.EXAMPLE
    PS> $count = .\Get-ApplicationInstanceCount.ps1 -ProcessName 'chrome' -Quiet
    PS> if ($count -gt 5) { Write-Host "Too many Chrome windows!" }
    
    Capture count for conditional logic.

.NOTES
    Script Name:    Get-ApplicationInstanceCount.ps1
    Author:         Windows Automation Framework
    Version:        1.0
    Creation Date:  2026-02-14
    Last Modified:  2026-02-14
    
    Execution Context: User or SYSTEM
    Execution Frequency: On-demand or scheduled
    Typical Duration: <1 second
    Timeout Setting: 10 seconds
    
    User Interaction: NONE (fully automated)
    Restart Behavior: Never restarts
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Windows 10/11 or Windows Server 2016+
        - User32.dll (Windows API)
    
    Exit Codes:
        0 - Success (always returns 0, count is in output)
    
    Output Format:
        Standard execution: Log messages + final integer count
        Quiet mode: Integer count only
        
    Use Cases:
        - Monitor application instance limits
        - Alert when too many instances running
        - Validate application launch success
        - Inventory open documents by title pattern
        - Automation workflow conditions
    
.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ProcessName,
    
    [Parameter(Mandatory=$false)]
    [string]$TitlePattern = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeMinimized,
    
    [Parameter(Mandatory=$false)]
    [switch]$Quiet
)

#Requires -Version 5.1

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "1.0"
$ErrorActionPreference = 'Stop'
$script:InstanceCount = 0

# ============================================================================
# WINDOWS API DEFINITIONS
# ============================================================================

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
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
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    
    if ($Quiet) { return }
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'INFO'  { Write-Verbose $LogMessage }
        'WARN'  { Write-Warning $LogMessage }
        'ERROR' { Write-Host $LogMessage -ForegroundColor Red }
    }
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
        return $Escaped
    } else {
        return [regex]::Escape($Pattern)
    }
}

function Test-WindowMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$hWnd,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetProcessName,
        
        [Parameter(Mandatory=$false)]
        [string]$TitleRegex = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$IncludeMinimized = $false
    )
    
    if (-not [Win32]::IsWindowVisible($hWnd)) {
        return $false
    }
    
    if (-not $IncludeMinimized -and [Win32]::IsIconic($hWnd)) {
        return $false
    }
    
    $ProcessId = 0
    [Win32]::GetWindowThreadProcessId($hWnd, [ref]$ProcessId) | Out-Null
    
    if ($ProcessId -eq 0) {
        return $false
    }
    
    try {
        $Process = Get-Process -Id $ProcessId -ErrorAction Stop
        
        if ($Process.ProcessName -ne $TargetProcessName) {
            return $false
        }
        
        if ($TitleRegex) {
            $WindowTitle = Get-WindowTitle -hWnd $hWnd
            
            if ($WindowTitle -notmatch $TitleRegex) {
                Write-Log "Window excluded - Title '$WindowTitle' does not match pattern" -Level INFO
                return $false
            }
            
            Write-Log "Window matched - Process: $($Process.ProcessName), Title: '$WindowTitle'" -Level INFO
        } else {
            $WindowTitle = Get-WindowTitle -hWnd $hWnd
            Write-Log "Window matched - Process: $($Process.ProcessName), Title: '$WindowTitle'" -Level INFO
        }
        
        return $true
        
    } catch {
        return $false
    }
}

function Get-ApplicationInstanceCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName,
        
        [Parameter(Mandatory=$false)]
        [string]$TitlePattern = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$IncludeMinimized = $false
    )
    
    Write-Log "Starting enumeration for process: $ProcessName" -Level INFO
    
    if ($TitlePattern) {
        $TitleRegex = Convert-WildcardToRegex -Pattern $TitlePattern
        Write-Log "Using title pattern: '$TitlePattern' (regex: '$TitleRegex')" -Level INFO
    } else {
        $TitleRegex = ""
        Write-Log "No title pattern specified - counting all windows" -Level INFO
    }
    
    if ($IncludeMinimized) {
        Write-Log "Including minimized windows" -Level INFO
    } else {
        Write-Log "Excluding minimized windows" -Level INFO
    }
    
    $Count = 0
    
    $Callback = {
        param($hWnd, $lParam)
        
        if (Test-WindowMatch -hWnd $hWnd -TargetProcessName $ProcessName -TitleRegex $TitleRegex -IncludeMinimized $IncludeMinimized) {
            $script:InstanceCount++
        }
        
        return $true
    }
    
    $CallbackDelegate = [Win32+EnumWindowsProc]$Callback
    [Win32]::EnumWindows($CallbackDelegate, [IntPtr]::Zero) | Out-Null
    
    Write-Log "Enumeration complete - Found $script:InstanceCount instance(s)" -Level INFO
    
    return $script:InstanceCount
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    if (-not $Quiet) {
        Write-Log "========================================" -Level INFO
        Write-Log "Get-ApplicationInstanceCount v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    
    $Count = Get-ApplicationInstanceCount -ProcessName $ProcessName -TitlePattern $TitlePattern -IncludeMinimized:$IncludeMinimized
    
    Write-Output $Count
    
    if (-not $Quiet) {
        Write-Log "========================================" -Level INFO
        Write-Log "Script execution completed successfully" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    
    exit 0
    
} catch {
    Write-Log "Script execution failed: $_" -Level ERROR
    Write-Output 0
    exit 0
}
