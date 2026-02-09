# Windows Automation Framework - PowerShell Coding Standards

**Document Type:** Development Standards  
**Audience:** Script Developers, Contributors  
**Version:** 1.0  
**Last Updated:** February 9, 2026

---

## Purpose

This document establishes coding standards for all PowerShell scripts in the Windows Automation Framework. Following these standards ensures consistency, maintainability, and reliability across the entire script library.

---

## Script Structure

### Standard Script Layout

Every script must follow this structure:

```powershell
1. Comment-based help (lines 1-50)
2. CmdletBinding and parameters (lines 51-60)
3. Requires statements (lines 61-63)
4. Configuration section (lines 64-80)
5. Initialization section (lines 81-100)
6. Functions section (lines 101-300)
7. Main execution block (lines 301+)
8. Error handling and cleanup (finally block)
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

.NOTES
    Script Name:    (exact filename)
    Author:         Windows Automation Framework
    Version:        X.Y
    Creation Date:  YYYY-MM-DD
    Last Modified:  YYYY-MM-DD
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily/Weekly/On-demand
    Typical Duration: ~XX seconds
    Timeout Setting: XXX seconds
    
    Fields Updated:
        - fieldName1 (description)
        - fieldName2 (description)
    
    Dependencies:
        - Windows PowerShell 5.1+
        - Administrator privileges
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
- Include typical execution time
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
    $Result = Get-WmiObject Win32_OperatingSystem
    
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

### Specific Exception Handling

**Catch specific exceptions when possible:**

```powershell
try {
    $Service = Get-Service $ServiceName
    
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
    $DiskC = Get-PSDrive C
} catch {
    Write-Log "C: drive not accessible" -Level WARN
    $DiskC = $null
}

try {
    $DiskD = Get-PSDrive D
} catch {
    Write-Log "D: drive not accessible" -Level WARN
    $DiskD = $null
}

# Process what we got
if ($DiskC) { Process-Disk $DiskC }
if ($DiskD) { Process-Disk $DiskD }
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
        'DEBUG' { Write-Verbose $LogMessage }
        'INFO'  { Write-Host $LogMessage -ForegroundColor Cyan }
        'WARN'  { Write-Warning $LogMessage }
        'ERROR' { Write-Error $LogMessage }
    }
}
```

### Log Levels

**Use appropriate levels:**

```powershell
# DEBUG - Detailed diagnostic information
Write-Log "Processing device: $DeviceName" -Level DEBUG

# INFO - General informational messages
Write-Log "Starting health check..." -Level INFO

# WARN - Warning conditions (non-critical)
Write-Log "Service not found, using default" -Level WARN

# ERROR - Error conditions (critical)
Write-Log "Failed to connect to WMI" -Level ERROR
```

### What to Log

**Required logging points:**

```powershell
# 1. Script start
Write-Log "Starting: $ScriptName v$Version" -Level INFO

# 2. Major steps
Write-Log "Gathering system information..." -Level INFO

# 3. Important values (DEBUG level)
Write-Log "Total memory: $TotalMemory GB" -Level DEBUG

# 4. Warnings
Write-Log "Disk space below 20%" -Level WARN

# 5. Errors
Write-Log "Failed to query WMI: $_" -Level ERROR

# 6. Script completion
Write-Log "Script completed in $Duration seconds" -Level INFO
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
        Queries WMI for logical disk information and calculates
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

### Always Validate Before Setting

```powershell
function Set-NinjaField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    try {
        # Don't set null or empty values
        if ($null -eq $Value -or $Value -eq "") {
            Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
            return
        }
        
        # Set the field
        Ninja-Property-Set $FieldName $Value
        Write-Log "Field '$FieldName' = $Value" -Level DEBUG
        
    } catch {
        Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
    }
}
```

### Use Wrapper Function

**Never call Ninja-Property-Set directly:**

```powershell
# Good - Uses wrapper with error handling
Set-NinjaField -FieldName "opsHealthScore" -Value $HealthScore

# Bad - Direct call, no error handling
Ninja-Property-Set "opsHealthScore" $HealthScore
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

### Standard Flow

```powershell
try {
    # 1. Log start
    Write-Log "Starting script..." -Level INFO
    
    # 2. Check prerequisites
    if (-not (Test-Prerequisites)) {
        throw "Prerequisites not met"
    }
    
    # 3. Initialize variables
    $StartTime = Get-Date
    
    # 4. Gather data
    $Data = Get-SystemData
    
    # 5. Calculate metrics
    $Metrics = Calculate-Metrics $Data
    
    # 6. Set fields
    Set-NinjaField -FieldName "field1" -Value $Metrics.Value1
    Set-NinjaField -FieldName "field2" -Value $Metrics.Value2
    
    # 7. Log completion
    Write-Log "Script completed successfully" -Level INFO
    
} catch {
    # 8. Handle errors
    Write-Log "Script failed: $_" -Level ERROR
    exit 1
    
} finally {
    # 9. Cleanup and summary
    $Duration = ((Get-Date) - $StartTime).TotalSeconds
    Write-Log "Execution time: $Duration seconds" -Level INFO
}
```

---

## Testing Standards

### Manual Testing Checklist

Before committing any script:

```markdown
- [ ] Script runs without errors
- [ ] All fields populate correctly
- [ ] Execution time under target
- [ ] Error handling works (test failure scenarios)
- [ ] Logging is clear and helpful
- [ ] Works on different Windows versions
- [ ] Works with different hardware configurations
- [ ] Handles missing data gracefully
```

### Test Different Scenarios

```powershell
# Test with:
# - Missing WMI data
# - Permission errors
# - Timeout conditions
# - Unusual hardware configurations
# - Different Windows versions (10, 11, Server)
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
    $Service = Get-Service $ServiceName
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

Fields affected:
- fieldName1
- fieldName2
```

**Examples:**

```
[Fix] Correct memory calculation in health check
[Feature] Add SSD detection to disk monitoring
[Perf] Optimize event log query performance
[Docs] Update comment-based help
```

---

## Common Patterns

### Safe Value Retrieval

```powershell
function Get-SafeValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        $DefaultValue = "N/A"
    )
    
    try {
        $Result = & $ScriptBlock
        if ($null -eq $Result -or $Result -eq "") {
            return $DefaultValue
        }
        return $Result
    } catch {
        return $DefaultValue
    }
}

# Usage
$ComputerName = Get-SafeValue { $env:COMPUTERNAME } "Unknown"
```

### Percentage Calculation

```powershell
function Get-Percentage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [double]$Value,
        
        [Parameter(Mandatory=$true)]
        [double]$Total,
        
        [Parameter(Mandatory=$false)]
        [int]$DecimalPlaces = 1
    )
    
    if ($Total -eq 0) {
        return 0
    }
    
    $Percent = ($Value / $Total) * 100
    return [math]::Round($Percent, $DecimalPlaces)
}

# Usage
$UsedPercent = Get-Percentage -Value $UsedSpace -Total $TotalSpace
```

### Retry Logic

```powershell
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$DelaySeconds = 2
    )
    
    $Attempt = 1
    while ($Attempt -le $MaxRetries) {
        try {
            return & $ScriptBlock
        } catch {
            if ($Attempt -eq $MaxRetries) {
                throw
            }
            Write-Log "Attempt $Attempt failed, retrying..." -Level WARN
            Start-Sleep -Seconds $DelaySeconds
            $Attempt++
        }
    }
}

# Usage
$Service = Invoke-WithRetry { Get-Service "ServiceName" }
```

---

## Anti-Patterns to Avoid

### Don't Ignore Errors

```powershell
# Bad
try {
    Get-Service "MayNotExist"
} catch { }

# Good
try {
    Get-Service "MayNotExist"
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

### Don't Use Write-Host for Output

```powershell
# Bad - Write-Host breaks pipeline
Write-Host "Computer name: $ComputerName"

# Good - Use Write-Log or Write-Output
Write-Log "Computer name: $ComputerName" -Level INFO
```

### Don't Suppress All Errors

```powershell
# Bad - Hides problems
$ErrorActionPreference = 'SilentlyContinue'
Get-Service "ServiceName"

# Good - Handle errors explicitly
try {
    $ErrorActionPreference = 'Stop'
    Get-Service "ServiceName"
} catch {
    Write-Log "Error: $_" -Level ERROR
}
```

---

## Code Review Checklist

Before submitting code:

```markdown
### Structure
- [ ] Uses standard script template
- [ ] Comment-based help complete
- [ ] Requires statements present
- [ ] Standard sections in correct order

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

### Performance
- [ ] Uses CIM instead of WMI
- [ ] Filters at source
- [ ] Result sets limited
- [ ] No expensive operations in loops

### Field Setting
- [ ] Uses Set-NinjaField wrapper
- [ ] Values validated before setting
- [ ] Data types handled properly
- [ ] No null/empty values set

### Testing
- [ ] Tested on multiple systems
- [ ] Error scenarios tested
- [ ] Execution time acceptable
- [ ] Fields populate correctly

### Documentation
- [ ] Inline comments for complex logic
- [ ] Function help complete
- [ ] Fields documented in header
- [ ] Version number updated
```

---

## Summary

**Key Principles:**

1. **Consistency** - Follow the template and standards
2. **Reliability** - Handle errors gracefully
3. **Performance** - Optimize queries and operations
4. **Maintainability** - Write clear, documented code
5. **Security** - Follow security best practices

**Quick Reference:**

- Use [SCRIPT_HEADER_TEMPLATE.ps1](SCRIPT_HEADER_TEMPLATE.ps1)
- PascalCase for all names
- Try-catch for all critical operations
- Structured logging always
- CIM instead of WMI
- Filter early and limit results
- Validate before setting fields
- Test thoroughly before committing

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Next Review:** Quarterly or when significant changes needed
