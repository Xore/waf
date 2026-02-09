# Windows Automation Framework - PowerShell Coding Standards

**Document Type:** Development Standards  
**Audience:** Script Developers, Contributors  
**Version:** 1.2  
**Last Updated:** February 9, 2026

---

## Purpose

This document establishes coding standards for all PowerShell scripts in the Windows Automation Framework. Following these standards ensures consistency, maintainability, and reliability across the entire script library.

---

## Critical Requirements

### MANDATORY: Execution Time Tracking

**ALL scripts MUST track execution time**

Every script must measure and log its execution duration:

```powershell
# At script start (REQUIRED)
$StartTime = Get-Date

# ... script logic ...

# In finally block (REQUIRED)
finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Duration: $ExecutionTime seconds" -Level INFO
}
```

**Why:** Execution time is critical for:
- Performance monitoring
- Timeout management
- Optimization opportunities
- SLA compliance

### MANDATORY: Dual-Method Field Setting

**ALL scripts MUST use Set-NinjaField with automatic CLI fallback**

Never call `Ninja-Property-Set` directly. Always use the wrapper:

```powershell
# Required approach
Set-NinjaField -FieldName "opsHealthScore" -Value $Score

# NEVER do this
Ninja-Property-Set "opsHealthScore" $Score
```

**Why:** The Set-NinjaField function automatically falls back to `ninjarmm-cli.exe` if `Ninja-Property-Set` fails, ensuring field updates work in all execution contexts.

### MANDATORY: No User Interaction

**ALL scripts MUST run unattended without user input**

```powershell
# FORBIDDEN - Never wait for user input
Read-Host "Press Enter to continue"
$UserChoice = Read-Host "Enter option (1-3)"
Pause
[Console]::ReadKey()

# FORBIDDEN - No confirmation prompts
Remove-Item $File -Confirm
Stop-Service $ServiceName -Confirm

# REQUIRED - Always use -Confirm:$false for automated operations
Remove-Item $File -Confirm:$false -ErrorAction Stop
Stop-Service $ServiceName -Confirm:$false -Force -ErrorAction Stop
```

**Why:** Scripts run via NinjaRMM automation in unattended mode. Any user interaction will cause the script to hang indefinitely until timeout.

**Exceptions:** None. All operations must be fully automated.

### MANDATORY: No Device Restarts Without Parameter

**Scripts MUST NOT restart devices unless explicitly authorized via parameter**

```powershell
# FORBIDDEN - Never restart without parameter
Restart-Computer
Restart-Computer -Force
Shutdown /r /t 0

# REQUIRED - Only restart if parameter provided
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$AllowRestart
)

if ($RequiresRestart) {
    if ($AllowRestart) {
        Write-Log "Restart authorized via parameter, initiating..." -Level WARN
        Restart-Computer -Force
    } else {
        Write-Log "Restart required but not authorized (use -AllowRestart)" -Level WARN
        Set-NinjaField -FieldName "opsRestartRequired" -Value "Yes"
        # Exit without restarting
    }
}
```

**Why:** Unplanned device restarts disrupt users and can cause data loss. Restarts must be scheduled and coordinated.

**Best Practice:** Set a field indicating restart required, alert administrators, and let them schedule the restart.

### MANDATORY: No Interactive Debugging

**Scripts MUST NOT use interactive debugging commands**

```powershell
# FORBIDDEN - Will hang script execution
Set-PSBreakpoint
Wait-Debugger
$DebugPreference = 'Inquire'  # Will prompt user

# REQUIRED - Use logging instead
Write-Log "Debug checkpoint: Variable value = $Value" -Level DEBUG
```

---

## Script Structure

### Standard Script Layout

Every script must follow this structure:

```powershell
1. Comment-based help (lines 1-60)
2. CmdletBinding and parameters (lines 61-70)
3. Requires statements (lines 71-73)
4. Configuration section (lines 74-90)
5. Initialization section (lines 91-110) - INCLUDES $StartTime
6. Functions section (lines 111-400) - INCLUDES Set-NinjaField
7. Main execution block (lines 401+)
8. Finally block (cleanup + execution time) - REQUIRED
```

### Template Usage

All new scripts must use the [SCRIPT_HEADER_TEMPLATE.ps1](SCRIPT_HEADER_TEMPLATE.ps1) as a starting point.

---

## Comment-Based Help

### Required Sections

Every script must include:

```powershell
<#
.SYNOPSIS
    One-line description (required)

.DESCRIPTION
    Detailed description including:
    - What the script monitors/collects
    - What calculations it performs
    - What fields it updates
    - Any important behavior notes
    - If restart capability exists, document the parameter

.PARAMETER AllowRestart
    (If applicable) Authorizes the script to restart the device if required.
    Without this parameter, script will only flag restart requirement.

.NOTES
    Script Name:    (exact filename)
    Author:         Windows Automation Framework
    Version:        X.Y
    Creation Date:  YYYY-MM-DD
    Last Modified:  YYYY-MM-DD
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily/Weekly/On-demand
    Typical Duration: ~XX seconds (REQUIRED - from actual measurements)
    Timeout Setting: XXX seconds
    
    User Interaction: NONE (fully automated)
    Restart Behavior: Never restarts unless -AllowRestart parameter provided
    
    Fields Updated:
        - fieldName1 (description)
        - fieldName2 (description)
    
    Dependencies:
        - Windows PowerShell 5.1+
        - Administrator privileges
        - NinjaRMM Agent installed
        - (other requirements)
    
    Exit Codes:
        0 - Success
        1 - General error
        2 - Missing dependencies
        3 - Permission denied
        4 - Timeout

.LINK
    https://github.com/Xore/waf
#>
```

### Best Practices

- Keep SYNOPSIS under 80 characters
- DESCRIPTION should be 3-5 sentences
- Document all NinjaRMM fields updated
- List all dependencies explicitly
- **REQUIRED: Include typical execution time from testing**
- **REQUIRED: State "User Interaction: NONE"**
- **REQUIRED: Document restart behavior**
- Document all exit codes used

---

## Naming Conventions

### Script Names

**Format:** `Verb-NounDescription.ps1`

**Examples:**
- `Get-SystemHealthScore.ps1`
- `Update-SecurityCompliance.ps1`
- `Monitor-DiskCapacity.ps1`

**Rules:**
- Use approved PowerShell verbs (Get, Set, Update, Monitor, Test, etc.)
- Use PascalCase for all parts
- Be descriptive but concise
- Avoid abbreviations unless standard (OS, CPU, RAM)

### Variable Names

**PascalCase for all variables:**

```powershell
# Good
$ComputerName
$TotalMemoryGB
$ServiceStatus
$IsHealthy
$StartTime  # REQUIRED
$ExecutionTime  # REQUIRED
$AllowRestart  # For restart parameter

# Bad
$computername
$total_memory
$svcStatus
$ishealthy
```

### Function Names

**Format:** `Verb-Noun`

```powershell
# Good
function Get-DiskSpace { }
function Test-ServiceHealth { }
function Write-Log { }
function Set-NinjaField { }  # REQUIRED in all scripts

# Bad
function getDiskSpace { }
function check_service { }
function log { }
```

### Parameter Names

**PascalCase, descriptive:**

```powershell
# Good
[Parameter()]
[string]$ComputerName

[Parameter()]
[int]$ThresholdPercent

[Parameter()]
[switch]$AllowRestart  # For restart authorization

# Bad
[Parameter()]
[string]$comp

[Parameter()]
[int]$thresh
```

---

## Error Handling

### Always Use Try-Catch

**Required for all critical operations:**

```powershell
try {
    # Critical operation
    $Result = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    
} catch {
    Write-Log "Failed to get OS information: $_" -Level ERROR
    # Graceful degradation or exit
}
```

### Error Preference

**Set at script level:**

```powershell
$ErrorActionPreference = 'Stop'
```

This ensures all errors are catchable.

### Suppress Confirmation Prompts

**Always use -Confirm:$false for automated operations:**

```powershell
# Good - No user interaction
Remove-Item $TempFile -Confirm:$false -Force -ErrorAction Stop
Stop-Service $ServiceName -Confirm:$false -Force -ErrorAction Stop
Restart-Service $ServiceName -Confirm:$false -Force -ErrorAction Stop

# Bad - Will hang waiting for confirmation
Remove-Item $TempFile
Stop-Service $ServiceName
```

### Specific Exception Handling

**Catch specific exceptions when possible:**

```powershell
try {
    $Service = Get-Service $ServiceName -ErrorAction Stop
    
} catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
    Write-Log "Service not found: $ServiceName" -Level WARN
    
} catch {
    Write-Log "Unexpected error: $_" -Level ERROR
}
```

### Graceful Degradation

**Never fail completely if partial data is acceptable:**

```powershell
# Good - Continue with partial data
try {
    $DiskC = Get-PSDrive C -ErrorAction Stop
} catch {
    Write-Log "C: drive not accessible" -Level WARN
    $DiskC = $null
}

try {
    $DiskD = Get-PSDrive D -ErrorAction Stop
} catch {
    Write-Log "D: drive not accessible" -Level WARN
    $DiskD = $null
}

# Process what we got
if ($DiskC) { Process-Disk $DiskC }
if ($DiskD) { Process-Disk $DiskD }
```

---

## Unattended Operation Standards

### No User Input Commands

**FORBIDDEN - Never use these:**

```powershell
# Interactive input
Read-Host
[Console]::ReadKey()
[Console]::ReadLine()
$Host.UI.ReadLine()

# Pause commands
Pause
Start-Sleep -Seconds 999999  # Waiting for user
cmd /c pause

# Confirmation prompts
-Confirm (without :$false)
Write-Host "Press any key..."; $Host.UI.RawUI.ReadKey()
```

**REQUIRED - Alternatives:**

```powershell
# Instead of Read-Host for choices
# Use parameters with default values
[Parameter(Mandatory=$false)]
[ValidateSet('Option1','Option2','Option3')]
[string]$Mode = 'Option1'  # Default value

# Instead of Pause
# Use logging to track progress
Write-Log "Processing complete" -Level INFO

# Instead of confirmations
# Always use -Confirm:$false
Remove-Item $File -Confirm:$false -Force
```

### Device Restart Handling

**REQUIRED Pattern:**

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$AllowRestart
)

# ... script logic ...

if ($RestartRequired) {
    Write-Log "Device restart is required" -Level WARN
    
    if ($AllowRestart) {
        Write-Log "Restart authorized via -AllowRestart parameter" -Level WARN
        Write-Log "Initiating restart in 60 seconds..." -Level WARN
        
        # Give time for field updates to sync
        Start-Sleep -Seconds 5
        
        # Perform restart
        Restart-Computer -Force -ErrorAction Stop
        
    } else {
        Write-Log "Restart NOT authorized. Use -AllowRestart to enable" -Level WARN
        
        # Flag for administrator review
        Set-NinjaField -FieldName "opsRestartRequired" -Value "Yes"
        Set-NinjaField -FieldName "opsRestartReason" -Value "$RestartReason"
        Set-NinjaField -FieldName "opsRestartDetectedDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        # Create alert if available
        Write-Log "Device requires restart: $RestartReason" -Level WARN
        
        # Exit without restarting
        exit 0
    }
}
```

### Shutdown and Reboot Commands

**FORBIDDEN without parameter:**

```powershell
# Never use these directly
Restart-Computer
Restart-Computer -Force
Stop-Computer
Stop-Computer -Force
shutdown.exe /r
shutdown.exe /s
wmic os where Primary=TRUE reboot
```

**REQUIRED with parameter check:**

```powershell
if ($AllowRestart) {
    Restart-Computer -Force
} else {
    Write-Log "Restart required but not authorized" -Level WARN
}
```

---

## Logging Standards

### Use Structured Logging

**Include Write-Log function in every script:**

```powershell
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
        'DEBUG' { if ($LogLevel -eq 'DEBUG') { Write-Verbose $LogMessage } }
        'INFO'  { Write-Host $LogMessage -ForegroundColor Cyan }
        'WARN'  { Write-Warning $LogMessage; $script:WarningCount++ }
        'ERROR' { Write-Error $LogMessage -ErrorAction Continue; $script:ErrorCount++ }
    }
}
```

### Log Levels

**Use appropriate levels:**

```powershell
# DEBUG - Detailed diagnostic information
Write-Log "Processing device: $DeviceName" -Level DEBUG

# INFO - General informational messages (including execution time)
Write-Log "Starting health check..." -Level INFO
Write-Log "Duration: $ExecutionTime seconds" -Level INFO  # REQUIRED

# WARN - Warning conditions (non-critical, restart required, etc.)
Write-Log "Service not found, using default" -Level WARN
Write-Log "Restart required but not authorized" -Level WARN

# ERROR - Error conditions (critical)
Write-Log "Failed to connect to WMI" -Level ERROR
```

### What to Log

**Required logging points:**

```powershell
# 1. Script start (REQUIRED)
Write-Log "Starting: $ScriptName v$Version" -Level INFO

# 2. Major steps
Write-Log "Gathering system information..." -Level INFO

# 3. Important values (DEBUG level)
Write-Log "Total memory: $TotalMemory GB" -Level DEBUG

# 4. Warnings (including restart requirements)
Write-Log "Disk space below 20%" -Level WARN
Write-Log "Restart required: $Reason" -Level WARN

# 5. Errors
Write-Log "Failed to query CIM: $_" -Level ERROR

# 6. Script completion and execution time (REQUIRED)
Write-Log "Script completed in $ExecutionTime seconds" -Level INFO
```

---

## Performance Best Practices

### Use CIM Instead of WMI

**CIM is faster and more reliable:**

```powershell
# Good - CIM cmdlets
$OS = Get-CimInstance Win32_OperatingSystem
$Disks = Get-CimInstance Win32_LogicalDisk

# Bad - Legacy WMI
$OS = Get-WmiObject Win32_OperatingSystem
$Disks = Get-WmiObject Win32_LogicalDisk
```

### Filter Early

**Filter at the source, not after:**

```powershell
# Good - Filter in query
$CriticalEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Level = 1,2  # Critical and Error
    StartTime = (Get-Date).AddDays(-7)
}

# Bad - Get all then filter
$AllEvents = Get-WinEvent -LogName System
$CriticalEvents = $AllEvents | Where-Object { $_.Level -le 2 }
```

### Limit Result Sets

**Only get what you need:**

```powershell
# Good - Limit results
$RecentErrors = Get-WinEvent -LogName System -MaxEvents 100 |
    Where-Object { $_.Level -eq 2 }

# Bad - Get everything
$AllErrors = Get-WinEvent -LogName System |
    Where-Object { $_.Level -eq 2 }
```

### Avoid Expensive Operations in Loops

**Move calculations outside loops:**

```powershell
# Good
$Threshold = Get-ThresholdValue
foreach ($Item in $Items) {
    if ($Item.Value -gt $Threshold) {
        Process-Item $Item
    }
}

# Bad
foreach ($Item in $Items) {
    if ($Item.Value -gt (Get-ThresholdValue)) {  # Called every loop!
        Process-Item $Item
    }
}
```

### Use Select-Object to Limit Properties

**Don't carry unnecessary data:**

```powershell
# Good
$Processes = Get-Process | Select-Object Name, CPU, WorkingSet

# Bad
$Processes = Get-Process  # Gets all properties
```

### Monitor Execution Time

**Track performance in testing:**

```powershell
# During development, measure specific operations
$OperationStart = Get-Date
$Result = Invoke-ExpensiveOperation
$OperationTime = ((Get-Date) - $OperationStart).TotalSeconds
Write-Log "Operation completed in $OperationTime seconds" -Level DEBUG
```

---

## Code Formatting

### Indentation

**4 spaces, no tabs:**

```powershell
if ($Condition) {
    Write-Log "Condition met" -Level INFO
    if ($SubCondition) {
        Write-Log "Sub-condition met" -Level DEBUG
    }
}
```

### Line Length

**Maximum 120 characters per line:**

```powershell
# Good - Readable
$Result = Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 3 } |
    Select-Object DeviceID, FreeSpace, Size

# Bad - Too long
$Result = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object DeviceID, FreeSpace, Size, VolumeName, FileSystem
```

### Braces

**Opening brace on same line:**

```powershell
# Good
if ($Condition) {
    # Code
}

# Bad
if ($Condition)
{
    # Code
}
```

### Blank Lines

**Use for readability:**

```powershell
# Good
function Get-DiskSpace {
    $Disks = Get-CimInstance Win32_LogicalDisk
    
    foreach ($Disk in $Disks) {
        $FreePercent = ($Disk.FreeSpace / $Disk.Size) * 100
        
        if ($FreePercent -lt 10) {
            Write-Log "Low disk space on $($Disk.DeviceID)" -Level WARN
        }
    }
    
    return $Disks
}

# Bad - No spacing
function Get-DiskSpace {
    $Disks = Get-CimInstance Win32_LogicalDisk
    foreach ($Disk in $Disks) {
        $FreePercent = ($Disk.FreeSpace / $Disk.Size) * 100
        if ($FreePercent -lt 10) {
            Write-Log "Low disk space on $($Disk.DeviceID)" -Level WARN
        }
    }
    return $Disks
}
```

---

## Comments

### Inline Comments

**Explain WHY, not WHAT:**

```powershell
# Good - Explains why
# Multiply by 1024 because Get-CimInstance returns bytes
$MemoryGB = $Computer.TotalPhysicalMemory / 1024 / 1024 / 1024

# Exclude system processes to avoid access denied errors
$UserProcesses = Get-Process | Where-Object { $_.Id -gt 100 }

# Restart not allowed without explicit parameter authorization
if ($RestartRequired -and -not $AllowRestart) {
    Write-Log "Restart required but not authorized" -Level WARN
}

# Bad - States the obvious
# Get the computer name
$ComputerName = $env:COMPUTERNAME

# Loop through disks
foreach ($Disk in $Disks) { }
```

### Function Comments

**Use comment-based help:**

```powershell
function Get-DiskSpace {
    <#
    .SYNOPSIS
        Retrieves disk space information for all logical drives
    
    .DESCRIPTION
        Queries CIM for logical disk information and calculates
        free space percentage. Excludes removable and network drives.
    
    .EXAMPLE
        Get-DiskSpace
        Returns disk space info for all fixed drives
    #>
    [CmdletBinding()]
    param()
    
    # Function code
}
```

### TODO Comments

**Format for trackability:**

```powershell
# TODO: Optimize this query for better performance
# TODO: Add support for network drives
# TODO: Consider caching results for 5 minutes
```

---

## Field Setting Standards

### REQUIRED: Use Set-NinjaField with CLI Fallback

**NEVER call Ninja-Property-Set directly:**

```powershell
# REQUIRED approach - Always use this
Set-NinjaField -FieldName "opsHealthScore" -Value $HealthScore

# FORBIDDEN - Never do this
Ninja-Property-Set "opsHealthScore" $HealthScore
```

### Set-NinjaField Implementation

**Every script must include this function:**

```powershell
function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value with automatic fallback to CLI
    
    .DESCRIPTION
        Attempts to set a NinjaRMM custom field using the Ninja-Property-Set cmdlet.
        If the cmdlet fails (e.g., not available in current context), automatically
        falls back to using the NinjaRMM CLI executable.
        
        This dual approach ensures field setting works in all execution contexts:
        - Ninja-Property-Set: Primary method (when running within NinjaRMM)
        - ninjarmm-cli.exe: Fallback method (when cmdlet unavailable)
    
    .PARAMETER FieldName
        The name of the custom field to set (case-sensitive)
    
    .PARAMETER Value
        The value to set for the field. Null or empty values are skipped.
    
    .EXAMPLE
        Set-NinjaField -FieldName "opsHealthScore" -Value 85
    
    .EXAMPLE
        Set-NinjaField -FieldName "capDiskCFreeGB" -Value 125.5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    # Skip null or empty values
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value provided" -Level DEBUG
        return
    }
    
    # Convert value to string
    $ValueString = $Value.ToString()
    
    # Method 1: Try Ninja-Property-Set cmdlet (primary)
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' = $ValueString" -Level DEBUG
            return
        } else {
            throw "Cmdlet not available"
        }
    } catch {
        Write-Log "Using CLI fallback for '$FieldName'" -Level DEBUG
        
        # Method 2: Fall back to NinjaRMM CLI
        try {
            $NinjaCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
            if (-not (Test-Path $NinjaCLI)) {
                throw "CLI not found: $NinjaCLI"
            }
            
            $CLIResult = & $NinjaCLI set $FieldName $ValueString 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "CLI failed: $CLIResult"
            }
            
            Write-Log "Field '$FieldName' = $ValueString (CLI)" -Level DEBUG
            $script:CLIFallbackCount++
        } catch {
            Write-Log "Failed to set '$FieldName': $_" -Level ERROR
            throw
        }
    }
}
```

### Handle Data Types Properly

```powershell
# Numbers - Format consistently
$MemoryGB = [math]::Round($MemoryBytes / 1GB, 2)
Set-NinjaField -FieldName "capMemoryTotalGB" -Value $MemoryGB

# Booleans - Use "Yes"/"No" for text fields
$IsHealthy = if ($HealthScore -ge 80) { "Yes" } else { "No" }
Set-NinjaField -FieldName "opsIsHealthy" -Value $IsHealthy

# Dates - Use ISO 8601 format
$LastBoot = Get-Date $BootTime -Format "yyyy-MM-dd HH:mm:ss"
Set-NinjaField -FieldName "opsLastBootTime" -Value $LastBoot

# Percentages - Round to 1 decimal
$DiskUsedPercent = [math]::Round($UsedPercent, 1)
Set-NinjaField -FieldName "capDiskCUsedPercent" -Value $DiskUsedPercent
```

---

## Script Execution Flow

### Standard Flow with Execution Time Tracking

```powershell
# REQUIRED: Track start time
$StartTime = Get-Date

try {
    # 1. Log start
    Write-Log "Starting script..." -Level INFO
    
    # 2. Check prerequisites
    if (-not (Test-Prerequisites)) {
        throw "Prerequisites not met"
    }
    
    # 3. Gather data
    $Data = Get-SystemData
    
    # 4. Calculate metrics
    $Metrics = Calculate-Metrics $Data
    
    # 5. Check if restart required
    if ($RequiresRestart) {
        if ($AllowRestart) {
            Write-Log "Restart authorized, initiating..." -Level WARN
            # Ensure fields are set first
            Start-Sleep -Seconds 5
            Restart-Computer -Force
        } else {
            Write-Log "Restart required but not authorized" -Level WARN
            Set-NinjaField -FieldName "opsRestartRequired" -Value "Yes"
        }
    }
    
    # 6. Set fields (using Set-NinjaField)
    Set-NinjaField -FieldName "field1" -Value $Metrics.Value1
    Set-NinjaField -FieldName "field2" -Value $Metrics.Value2
    
    # 7. Log completion
    Write-Log "Script completed successfully" -Level INFO
    
} catch {
    # 8. Handle errors
    Write-Log "Script failed: $_" -Level ERROR
    exit 1
    
} finally {
    # 9. REQUIRED: Calculate and log execution time
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $ExecutionTime seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}
```

---

## Testing Standards

### Manual Testing Checklist

Before committing any script:

```markdown
- [ ] Script runs without errors
- [ ] All fields populate correctly
- [ ] Execution time logged in finally block
- [ ] Execution time under target (documented in header)
- [ ] No user input required (runs unattended)
- [ ] No unexpected restarts (parameter check works)
- [ ] Error handling works (test failure scenarios)
- [ ] Logging is clear and helpful
- [ ] Works on different Windows versions
- [ ] Works with different hardware configurations
- [ ] Handles missing data gracefully
- [ ] Set-NinjaField fallback tested (if possible)
- [ ] -Confirm:$false on all potentially interactive cmdlets
```

### Unattended Operation Testing

```powershell
# Test that script doesn't hang
# Run with timeout to verify no user interaction
$Job = Start-Job -ScriptBlock { .\ScriptName.ps1 }
if (-not (Wait-Job $Job -Timeout 300)) {
    Write-Host "FAIL: Script hung (likely waiting for input)" -ForegroundColor Red
    Stop-Job $Job
    Remove-Job $Job
} else {
    Write-Host "PASS: Script completed without hanging" -ForegroundColor Green
    Receive-Job $Job
    Remove-Job $Job
}
```

### Restart Parameter Testing

```powershell
# Test 1: Without parameter (should NOT restart)
.\ScriptName.ps1
# Verify: Device still running
# Verify: opsRestartRequired field set if applicable

# Test 2: With parameter (should restart if required)
# WARNING: Only test on non-production VM
.\ScriptName.ps1 -AllowRestart
# Verify: Device restarts only if actually needed
```

### Performance Testing

```powershell
# Test execution time multiple times
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Run $i of 5"
    Measure-Command { .\ScriptName.ps1 }
}

# Calculate average:
# - Document in script header (Typical Duration)
# - Ensure under timeout setting
# - Compare to similar scripts
```

---

## Security Best Practices

### Never Hardcode Credentials

```powershell
# Good - Use Windows authentication
$Session = New-CimSession

# Bad - Hardcoded credentials
$Password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential("user", $Password)
```

### Validate Input

```powershell
function Get-ServiceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,100)]
        [string]$ServiceName
    )
    
    # Input is validated before use
    $Service = Get-Service $ServiceName -ErrorAction Stop
}
```

### Use Least Privilege

```powershell
# Only request privileges actually needed
# Run as SYSTEM when necessary (via NinjaRMM)
# Otherwise run as standard user
```

---

## Version Control

### Update Version Numbers

**Semantic versioning:**

- **Major.Minor.Patch** (e.g., 1.2.3)
- **Major:** Breaking changes
- **Minor:** New features (backward compatible)
- **Patch:** Bug fixes

```powershell
# In script header
$ScriptVersion = "1.2.3"

# In comment-based help
# Version: 1.2.3
# Last Modified: 2026-02-09
```

### Commit Messages

**Format:**

```
[Category] Brief description

Detailed explanation if needed

Changes:
- Added execution time tracking
- Implemented Set-NinjaField with CLI fallback
- Removed user input prompts
- Added restart parameter protection
- Improved error handling

Fields affected:
- fieldName1
- fieldName2

Execution time: 15s (was 23s)
```

---

## Anti-Patterns to Avoid

### Don't Wait for User Input

```powershell
# Bad - Script will hang
Read-Host "Press Enter to continue"
$Choice = Read-Host "Select option"
Pause

# Good - Fully automated
Write-Log "Processing..." -Level INFO
# No user interaction needed
```

### Don't Restart Without Authorization

```powershell
# Bad - Uncontrolled restart
if ($UpdatesInstalled) {
    Restart-Computer -Force
}

# Good - Parameter controlled
if ($UpdatesInstalled) {
    if ($AllowRestart) {
        Restart-Computer -Force
    } else {
        Set-NinjaField -FieldName "opsRestartRequired" -Value "Yes"
    }
}
```

### Don't Ignore Errors

```powershell
# Bad
try {
    Get-Service "MayNotExist"
} catch { }

# Good
try {
    Get-Service "MayNotExist" -ErrorAction Stop
} catch {
    Write-Log "Service not found: $_" -Level WARN
    # Handle appropriately
}
```

### Don't Use Aliases in Scripts

```powershell
# Bad - Aliases reduce readability
gci C:\ | ? { $_.Length -gt 1MB }

# Good - Full cmdlet names
Get-ChildItem C:\ | Where-Object { $_.Length -gt 1MB }
```

### Don't Call Ninja-Property-Set Directly

```powershell
# Bad - No fallback, no error handling
Ninja-Property-Set "fieldName" $Value

# Good - Uses wrapper with automatic fallback
Set-NinjaField -FieldName "fieldName" -Value $Value
```

### Don't Skip Execution Time Tracking

```powershell
# Bad - No execution time logging
try {
    # Script logic
} catch {
    # Error handling
}

# Good - Execution time tracked and logged
$StartTime = Get-Date
try {
    # Script logic
} finally {
    $ExecutionTime = ((Get-Date) - $StartTime).TotalSeconds
    Write-Log "Duration: $ExecutionTime seconds" -Level INFO
}
```

### Don't Use Interactive Confirmations

```powershell
# Bad - Will hang waiting for confirmation
Remove-Item $File
Stop-Service $ServiceName
Restart-Service $ServiceName

# Good - Suppress confirmations
Remove-Item $File -Confirm:$false -Force -ErrorAction Stop
Stop-Service $ServiceName -Confirm:$false -Force -ErrorAction Stop
Restart-Service $ServiceName -Confirm:$false -Force -ErrorAction Stop
```

---

## Code Review Checklist

Before submitting code:

```markdown
### Structure
- [ ] Uses standard script template
- [ ] Comment-based help complete with execution time
- [ ] Requires statements present
- [ ] Standard sections in correct order

### Critical Requirements
- [ ] Execution time tracking implemented ($StartTime in init)
- [ ] Execution time logged in finally block
- [ ] Set-NinjaField function included with CLI fallback
- [ ] No direct Ninja-Property-Set calls
- [ ] No user input commands (Read-Host, Pause, etc.)
- [ ] No device restarts without -AllowRestart parameter
- [ ] -Confirm:$false on all potentially interactive cmdlets

### Naming
- [ ] Script name follows convention
- [ ] Variables use PascalCase
- [ ] Functions use approved verbs
- [ ] Names are descriptive

### Error Handling
- [ ] Try-catch blocks around critical operations
- [ ] Errors logged appropriately
- [ ] Graceful degradation where possible
- [ ] Exit codes documented and used

### Logging
- [ ] Write-Log function included
- [ ] Script start/end logged
- [ ] Major steps logged
- [ ] Appropriate log levels used
- [ ] Execution time logged
- [ ] Restart requirements logged

### Performance
- [ ] Uses CIM instead of WMI
- [ ] Filters at source
- [ ] Result sets limited
- [ ] No expensive operations in loops
- [ ] Execution time documented and acceptable

### Field Setting
- [ ] Uses Set-NinjaField wrapper (NEVER direct calls)
- [ ] Function includes CLI fallback logic
- [ ] Values validated before setting
- [ ] Data types handled properly
- [ ] No null/empty values set

### Unattended Operation
- [ ] No Read-Host or similar input commands
- [ ] No Pause commands
- [ ] No interactive debugging
- [ ] Restart requires parameter authorization
- [ ] All confirmations suppressed (-Confirm:$false)

### Testing
- [ ] Tested on multiple systems
- [ ] Runs unattended without hanging
- [ ] Error scenarios tested
- [ ] Execution time measured (5+ runs)
- [ ] Fields populate correctly
- [ ] Both field setting methods tested (if possible)
- [ ] Restart parameter tested (if applicable)
```

---

## Summary

**Key Principles:**

1. **Consistency** - Follow the template and standards
2. **Reliability** - Handle errors gracefully with dual-method field setting
3. **Performance** - Track and optimize execution time
4. **Automation** - No user interaction, fully unattended
5. **Safety** - No unexpected restarts
6. **Maintainability** - Write clear, documented code
7. **Security** - Follow security best practices

**Critical Requirements:**

- ✅ **Execution time tracking** - REQUIRED in all scripts
- ✅ **Set-NinjaField with CLI fallback** - NEVER use Ninja-Property-Set directly
- ✅ **No user interaction** - NEVER use Read-Host, Pause, or confirmations
- ✅ **No restarts without parameter** - NEVER restart without -AllowRestart
- ✅ **Structured logging** - Including execution time in finally block
- ✅ **Error handling** - Try-catch on all critical operations
- ✅ **Performance optimization** - CIM, filtering, limited results

**Quick Reference:**

- Use [SCRIPT_HEADER_TEMPLATE.ps1](SCRIPT_HEADER_TEMPLATE.ps1)
- PascalCase for all names
- Try-catch for all critical operations
- Structured logging always
- CIM instead of WMI
- Filter early and limit results
- **Track execution time ($StartTime in init, log in finally)**
- **Use Set-NinjaField with CLI fallback (NEVER direct calls)**
- **No user input - fully automated**
- **No restarts without -AllowRestart parameter**
- **-Confirm:$false on interactive cmdlets**
- Test thoroughly before committing

---

**Document Version:** 1.2  
**Last Updated:** February 9, 2026  
**Changes:** Added mandatory rules for no user interaction and no restarts without parameter  
**Next Review:** Quarterly or when significant changes needed
