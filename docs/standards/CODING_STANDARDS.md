# Windows Automation Framework - PowerShell Coding Standards

**Document Type:** Development Standards  
**Audience:** Script Developers, Contributors  
**Version:** 1.4  
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

### MANDATORY: Auto-Install Module Dependencies

**ALL scripts MUST automatically install required modules**

When importing external PowerShell modules, scripts must:
1. Check if NuGet package provider is installed
2. Check if the module is installed
3. Automatically install missing components without user interaction

```powershell
# REQUIRED - Auto-install pattern
try {
    # Ensure NuGet provider is installed
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Log "Installing NuGet package provider..." -Level INFO
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Write-Log "NuGet package provider installed" -Level INFO
    }
    
    # Check if module is installed
    if (-not (Get-Module -ListAvailable -Name ModuleName)) {
        Write-Log "Installing ModuleName module..." -Level INFO
        Install-Module -Name ModuleName -Repository PSGallery -Confirm:$false -Force
        Write-Log "ModuleName module installed" -Level INFO
    }
    
    # Import the module
    Import-Module ModuleName -ErrorAction Stop
    Write-Log "ModuleName module imported successfully" -Level DEBUG
    
} catch {
    Write-Log "Failed to install/import ModuleName: $_" -Level ERROR
    throw
}
```

**Why:** 
- Ensures scripts work on fresh systems
- No manual module installation required
- Fully automated dependency management
- Prevents "module not found" errors

---

## File Naming Standards

### Script File Naming Schema

**REQUIRED Format:**

```
[Human Readable Description] [Sequential Number].ps1
```

**Rules:**

1. **Description:** 2-5 words maximum, human-readable, no technical abbreviations
2. **Sequential Number:** Start at 1, increment for each new script
3. **No Verb-Noun Format:** Use plain language descriptions
4. **Spaces Allowed:** Use spaces between words for readability
5. **Case:** Title Case (capitalize first letter of each word)

**Examples:**

```powershell
# Good - Clear and numbered
Disk Space Monitor 1.ps1
Memory Health Check 2.ps1
Windows Update Status 3.ps1
Security Compliance Scan 4.ps1
Network Connectivity Test 5.ps1

# Bad - Too technical, no number
Get-DiskSpace.ps1
Check-MemHealth.ps1

# Bad - Too long
Monitor All System Disk Drives For Free Space 1.ps1

# Bad - Wrong numbering format
Disk Space Monitor [001].ps1
Disk Space Monitor v1.ps1
```

### Sequential Number Assignment

**Process:**

1. Check the repository for the highest existing number
2. Assign the next sequential number to your new script
3. Document the script in the inventory (if tracking exists)
4. Never reuse numbers, even if a script is deleted

**Finding Next Number:**

```powershell
# Find highest numbered script
Get-ChildItem -Path . -Filter "*.ps1" -Recurse |
    Where-Object { $_.Name -match ' (\d+)\.ps1$' } |
    ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Number = [int]$Matches[1]
        }
    } |
    Sort-Object Number -Descending |
    Select-Object -First 1

# Next available number is: HighestNumber + 1
```

### Description Guidelines

**Good Descriptions:**
- Clear purpose obvious from name
- 2-5 words maximum
- No technical jargon
- Describes WHAT it does, not HOW

**Examples:**

```
System Health Score 15.ps1           # Clear
Disk Usage Report 23.ps1             # Clear
Bitlocker Status Check 47.ps1        # Clear
Firewall Rules Audit 89.ps1          # Clear

Get-WMISystemInfo 15.ps1             # Too technical
Disk-Space-Monitor-Tool 23.ps1       # Too many hyphens
CheckIfDiskSpaceIsLow 47.ps1         # Awkward phrasing
Script1.ps1                           # No description
```

### Special Cases

**Helper Scripts:**

If creating internal helper scripts (not monitored/executed directly):

```
Helpers\[Description] [Number].ps1

Examples:
Helpers\Format Disk Data 1.ps1
Helpers\Calculate Health Score 2.ps1
```

**Test Scripts:**

```
Tests\[Description] Test [Number].ps1

Examples:
Tests\Disk Space Monitor Test 1.ps1
Tests\Memory Health Test 2.ps1
```

**Refactored Scripts:**

When refactoring, keep the same number:

```
# Before refactoring
Disk Space Monitor 15.ps1

# After refactoring (same number)
Disk Space Monitor 15.ps1

# Update version in header, not filename
```

### Migration from Old Naming

If migrating existing scripts with different naming:

**Option 1: Rename with sequential numbers (recommended)**

```powershell
# Old names
Get-DiskSpace.ps1
Get-MemoryUsage.ps1
Check-WindowsUpdate.ps1

# New names (assign next available numbers)
Disk Space Monitor 142.ps1
Memory Usage Check 143.ps1
Windows Update Status 144.ps1
```

**Option 2: Keep old format in legacy folder**

```
Legacy\Get-DiskSpace.ps1
Legacy\Get-MemoryUsage.ps1

# New scripts in root with new naming
Disk Space Monitor 1.ps1
Memory Usage Check 2.ps1
```

### Naming Anti-Patterns

**AVOID:**

```powershell
# No number
Disk Space Monitor.ps1

# Technical verb-noun format
Get-DiskSpaceMetrics.ps1

# Version numbers instead of sequential
Disk Space Monitor v2.3.ps1

# Date stamps in filename
Disk Space Monitor 2026-02-09.ps1

# Too long (>5 words)
Monitor All Local Fixed Disk Drives Free Space 1.ps1

# Abbreviations and acronyms
DSM Tool 1.ps1
WU Check Script 2.ps1

# Hyphens or underscores instead of spaces
Disk-Space-Monitor_1.ps1

# Incorrect number format
Disk Space Monitor [1].ps1
Disk Space Monitor (1).ps1
Disk Space Monitor #1.ps1
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
6. Module dependency installation (lines 111-150) - IF NEEDED
7. Functions section (lines 151-400) - INCLUDES Set-NinjaField
8. Main execution block (lines 401+)
9. Finally block (cleanup + execution time) - REQUIRED
```

### Template Usage

All new scripts must use the [SCRIPT_HEADER_TEMPLATE.ps1](SCRIPT_HEADER_TEMPLATE.ps1) as a starting point.

---

## Module Dependencies and Installation

### REQUIRED: Auto-Installation Pattern

**Every script that imports external modules MUST include auto-installation logic:**

```powershell
# ============================================================================
# MODULE DEPENDENCY INSTALLATION
# ============================================================================

try {
    Write-Log "Checking module dependencies..." -Level INFO
    
    # Step 1: Ensure NuGet package provider is installed
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Log "NuGet package provider not found, installing..." -Level INFO
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Write-Log "NuGet package provider installed successfully" -Level INFO
    } else {
        Write-Log "NuGet package provider already installed" -Level DEBUG
    }
    
    # Step 2: Check and install required modules
    $RequiredModules = @(
        'ModuleName1',
        'ModuleName2',
        'ModuleName3'
    )
    
    foreach ($ModuleName in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
            Write-Log "Module '$ModuleName' not found, installing..." -Level INFO
            Install-Module -Name $ModuleName -Repository PSGallery -Confirm:$false -Force
            Write-Log "Module '$ModuleName' installed successfully" -Level INFO
        } else {
            Write-Log "Module '$ModuleName' already installed" -Level DEBUG
        }
        
        # Step 3: Import the module
        Import-Module $ModuleName -ErrorAction Stop
        Write-Log "Module '$ModuleName' imported successfully" -Level DEBUG
    }
    
    Write-Log "All module dependencies satisfied" -Level INFO
    
} catch {
    Write-Log "Failed to install/import required modules: $_" -Level ERROR
    throw
}
```

### Single Module Installation

**For scripts requiring only one module:**

```powershell
try {
    Write-Log "Checking for ModuleName module..." -Level INFO
    
    # Ensure NuGet is installed
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Log "Installing NuGet package provider..." -Level INFO
        Install-PackageProvider -Name NuGet -Force | Out-Null
    }
    
    # Check and install module
    if (-not (Get-Module -ListAvailable -Name ModuleName)) {
        Write-Log "Installing ModuleName module..." -Level INFO
        Install-Module -Name ModuleName -Repository PSGallery -Confirm:$false -Force
        Write-Log "ModuleName module installed" -Level INFO
    }
    
    # Import module
    Import-Module ModuleName -ErrorAction Stop
    Write-Log "ModuleName module ready" -Level INFO
    
} catch {
    Write-Log "Failed to prepare ModuleName module: $_" -Level ERROR
    throw
}
```

### Module Installation Best Practices

**DO:**
- Always check for NuGet provider first
- Use `-Force` to avoid prompts
- Use `-Confirm:$false` to prevent user interaction
- Suppress output with `| Out-Null` where appropriate
- Log installation progress
- Use try-catch for error handling
- Import module after installation
- Check `Get-Module -ListAvailable` before installing

**DON'T:**
- Never assume NuGet is installed
- Never use `-Scope CurrentUser` (may not work in SYSTEM context)
- Never allow user prompts
- Never skip error handling
- Never import without checking installation first
- Never use `Import-Module -Force` unless necessary

### Common Module Installation Examples

**Example 1: PSWindowsUpdate Module**

```powershell
try {
    # Ensure NuGet provider
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Log "Installing NuGet package provider..." -Level INFO
        Install-PackageProvider -Name NuGet -Force | Out-Null
    }
    
    # Install PSWindowsUpdate if needed
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "Installing PSWindowsUpdate module..." -Level INFO
        Install-Module -Name PSWindowsUpdate -Repository PSGallery -Confirm:$false -Force
        Write-Log "PSWindowsUpdate module installed" -Level INFO
    }
    
    # Import module
    Import-Module PSWindowsUpdate -ErrorAction Stop
    Write-Log "PSWindowsUpdate module ready" -Level INFO
    
} catch {
    Write-Log "Failed to prepare PSWindowsUpdate module: $_" -Level ERROR
    throw
}
```

**Example 2: Multiple Security Modules**

```powershell
try {
    Write-Log "Preparing security modules..." -Level INFO
    
    # Ensure NuGet
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -Force | Out-Null
    }
    
    # Required security modules
    $SecurityModules = @('SecurityFever', 'PolicyFileEditor', 'AuditPolicy')
    
    foreach ($Module in $SecurityModules) {
        if (-not (Get-Module -ListAvailable -Name $Module)) {
            Write-Log "Installing $Module..." -Level INFO
            Install-Module -Name $Module -Repository PSGallery -Confirm:$false -Force
        }
        Import-Module $Module -ErrorAction Stop
    }
    
    Write-Log "All security modules ready" -Level INFO
    
} catch {
    Write-Log "Security module preparation failed: $_" -Level ERROR
    throw
}
```

**Example 3: Version-Specific Module**

```powershell
try {
    # Ensure NuGet
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -Force | Out-Null
    }
    
    # Check for specific version
    $RequiredVersion = '2.1.0'
    $Module = Get-Module -ListAvailable -Name ModuleName | 
        Where-Object { $_.Version -ge [Version]$RequiredVersion } |
        Select-Object -First 1
    
    if (-not $Module) {
        Write-Log "Installing ModuleName v$RequiredVersion or higher..." -Level INFO
        Install-Module -Name ModuleName -MinimumVersion $RequiredVersion -Repository PSGallery -Confirm:$false -Force
    }
    
    Import-Module ModuleName -MinimumVersion $RequiredVersion -ErrorAction Stop
    Write-Log "ModuleName v$RequiredVersion+ ready" -Level INFO
    
} catch {
    Write-Log "Module version check failed: $_" -Level ERROR
    throw
}
```

### Error Handling for Module Installation

**Handle common installation errors:**

```powershell
try {
    # NuGet installation
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        try {
            Write-Log "Installing NuGet package provider..." -Level INFO
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
            Write-Log "NuGet installed successfully" -Level INFO
        } catch {
            Write-Log "Failed to install NuGet provider: $_" -Level ERROR
            throw "NuGet installation failed. Cannot proceed with module installation."
        }
    }
    
    # Module installation
    if (-not (Get-Module -ListAvailable -Name ModuleName)) {
        try {
            Write-Log "Installing ModuleName module..." -Level INFO
            Install-Module -Name ModuleName -Repository PSGallery -Confirm:$false -Force -ErrorAction Stop
            Write-Log "ModuleName installed successfully" -Level INFO
        } catch {
            Write-Log "Failed to install ModuleName: $_" -Level ERROR
            
            # Check if it's a network issue
            if ($_.Exception.Message -match "Unable to resolve|timeout|network") {
                throw "Network error during module installation. Check internet connectivity."
            } else {
                throw "Module installation failed: $_"
            }
        }
    }
    
    # Module import
    try {
        Import-Module ModuleName -ErrorAction Stop
        Write-Log "ModuleName imported successfully" -Level DEBUG
    } catch {
        Write-Log "Failed to import ModuleName: $_" -Level ERROR
        throw "Module import failed. Module may be corrupted."
    }
    
} catch {
    Write-Log "Module dependency preparation failed: $_" -Level ERROR
    
    # Set field to indicate module issue
    Set-NinjaField -FieldName "opsModuleError" -Value "Yes"
    Set-NinjaField -FieldName "opsModuleErrorDetails" -Value $_.Exception.Message
    
    # Exit with error
    exit 2
}
```

### Document Module Dependencies

**In comment-based help, list all module dependencies:**

```powershell
<#
.NOTES
    Dependencies:
        - Windows PowerShell 5.1+
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Internet connectivity (for module installation)
        - PowerShell Gallery access
        
    Required Modules (auto-installed):
        - PSWindowsUpdate (Latest)
        - SecurityFever (v1.2.0+)
        - PolicyFileEditor (Latest)
        
    Network Requirements:
        - Access to PowerShell Gallery (https://www.powershellgallery.com)
        - Outbound HTTPS (port 443) allowed
#>
```

### Testing Module Installation

**Test module installation separately:**

```powershell
# Test script for module installation
function Test-ModuleInstallation {
    param(
        [string]$ModuleName
    )
    
    try {
        Write-Host "Testing $ModuleName installation..." -ForegroundColor Cyan
        
        # Check NuGet
        $NuGet = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if ($NuGet) {
            Write-Host "  NuGet: Installed (v$($NuGet.Version))" -ForegroundColor Green
        } else {
            Write-Host "  NuGet: Not installed" -ForegroundColor Yellow
        }
        
        # Check module
        $Module = Get-Module -ListAvailable -Name $ModuleName | Select-Object -First 1
        if ($Module) {
            Write-Host "  $ModuleName: Installed (v$($Module.Version))" -ForegroundColor Green
        } else {
            Write-Host "  $ModuleName: Not installed" -ForegroundColor Yellow
        }
        
        # Test import
        Import-Module $ModuleName -ErrorAction Stop
        Write-Host "  Import: Successful" -ForegroundColor Green
        
        return $true
        
    } catch {
        Write-Host "  Import: Failed - $_" -ForegroundColor Red
        return $false
    }
}

# Run tests
Test-ModuleInstallation -ModuleName 'PSWindowsUpdate'
Test-ModuleInstallation -ModuleName 'SecurityFever'
```

### Module Installation Anti-Patterns

**AVOID:**

```powershell
# Bad - No NuGet check
Install-Module ModuleName -Force

# Bad - User interaction possible
Install-Module ModuleName

# Bad - No error handling
Install-PackageProvider -Name NuGet
Install-Module ModuleName
Import-Module ModuleName

# Bad - Assumes module is installed
Import-Module ModuleName

# Bad - No logging
if (-not (Get-Module ModuleName)) {
    Install-Module ModuleName -Force
}

# Bad - Silent failures
Install-Module ModuleName -ErrorAction SilentlyContinue
```

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
    Script Name:    (exact filename including number)
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
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Internet connectivity (if using external modules)
        - PowerShell Gallery access (if using external modules)
    
    Required Modules (auto-installed if not present):
        - ModuleName1 (Latest or vX.Y+)
        - ModuleName2 (Latest or vX.Y+)
    
    Exit Codes:
        0 - Success
        1 - General error
        2 - Missing dependencies / Module installation failed
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
- **REQUIRED: List all external modules that will be auto-installed**
- **REQUIRED: Include exact filename with number in Script Name field**
- **REQUIRED: Include typical execution time from testing**
- **REQUIRED: State "User Interaction: NONE"**
- **REQUIRED: Document restart behavior**
- **REQUIRED: Document internet/PSGallery requirement if using modules**
- Document all exit codes used
- Include exit code 2 for module installation failures

---

## Naming Conventions

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
$RequiredModules  # For module list

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

# REQUIRED for module installation
Install-Module -Name ModuleName -Confirm:$false -Force

# Bad - Will hang waiting for confirmation
Remove-Item $TempFile
Stop-Service $ServiceName
Install-Module ModuleName  # May prompt user
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

# Module installation prompts
Install-Module ModuleName  # Without -Force -Confirm:$false
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
Write-Log "Processing completed" -Level INFO

# Instead of confirmations
# Always use -Confirm:$false
Remove-Item $File -Confirm:$false -Force
Install-Module ModuleName -Confirm:$false -Force
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

(continuing with rest of document...)

**Document Version:** 1.4  
**Last Updated:** February 9, 2026  
**Changes:** Added mandatory module dependency auto-installation requirements  
**Next Review:** Quarterly or when significant changes needed
