# Contributing to Windows Automation Framework

**Thank you for your interest in contributing!**

This document provides guidelines for contributing to the Windows Automation Framework (WAF). Following these guidelines helps maintain code quality, consistency, and makes the review process smoother for everyone.

---

## 📜 Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Standards](#development-standards)
4. [Script Templates](#script-templates)
5. [Testing Requirements](#testing-requirements)
6. [Pull Request Process](#pull-request-process)
7. [Documentation](#documentation)
8. [Style Guidelines](#style-guidelines)

---

## 🤝 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please:

- ✅ Be respectful and inclusive
- ✅ Accept constructive criticism gracefully
- ✅ Focus on what's best for the community
- ✅ Show empathy towards other contributors

### Unacceptable Behavior

- ❌ Harassment or discriminatory language
- ❌ Trolling or insulting comments
- ❌ Publishing others' private information
- ❌ Other unprofessional conduct

---

## 🚀 Getting Started

### Prerequisites

**Required:**
- PowerShell 5.1 or later
- Git for version control
- Text editor (VS Code recommended)
- Windows environment for testing

**Recommended:**
- PowerShell Extension for VS Code
- PSScriptAnalyzer
- Pester (testing framework)
- NinjaRMM test environment

### Setting Up Your Development Environment

1. **Fork the Repository**
   ```bash
   # On GitHub, click "Fork" button
   # Clone your fork locally
   git clone https://github.com/YOUR-USERNAME/waf.git
   cd waf
   ```

2. **Create a Branch**
   ```bash
   # Create feature branch from main
   git checkout -b feature/your-feature-name
   
   # Or for bug fixes
   git checkout -b fix/issue-description
   ```

3. **Install Development Tools**
   ```powershell
   # Install PSScriptAnalyzer
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
   
   # Install Pester (testing)
   Install-Module -Name Pester -Scope CurrentUser -Force
   ```

---

## ⚙️ Development Standards

### V3 Framework Standards (MANDATORY)

All new scripts and modifications MUST follow V3 standards:

#### 1. Script Structure

```powershell
#Requires -Version 5.1
#Requires -RunAsAdministrator  # If admin required

<#
.SYNOPSIS
    [One-line description]

.DESCRIPTION
    [Detailed multi-line description]
    [What the script does]
    [Key features]

.NOTES
    Author:         Windows Automation Framework
    Created:        YYYY-MM-DD
    Version:        1.0
    Purpose:        [Specific purpose]
    
    Execution Context:  SYSTEM
    Execution Frequency: [e.g., Every 15 minutes]
    Estimated Duration: [e.g., ~10 seconds]
    Timeout Setting:    [e.g., 60 seconds]
    
    Fields Updated:
    - fieldName1 (Type) - Description
    - fieldName2 (Type) - Description
    
    Dependencies:
    - [Module/Feature requirements]
    
    Exit Codes:
    0  = Success
    1  = [Specific error]
    99 = Unexpected error

.EXAMPLE
    .\Script-Name.ps1
    
.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param()

# Configuration section
# Functions section
# Main execution section
# Error handling
# Finally block (MANDATORY)
```

#### 2. Required Functions

**Write-Log Function (Standardized):**
```powershell
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'ERROR'   { Write-Error $LogMessage }
        'WARNING' { Write-Warning $LogMessage }
        'DEBUG'   { Write-Verbose $LogMessage }
        default   { Write-Output $LogMessage }
    }
}
```

**Set-NinjaField Function (REQUIRED):**
```powershell
function Set-NinjaField {
    param(
        [string]$FieldName,
        [AllowNull()]
        [object]$Value
    )
    
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set -Name $FieldName -Value $Value
        }
        
        $RegPath = "HKLM:\SOFTWARE\NinjaRMMAgent\CustomFields"
        if (Test-Path $RegPath) {
            Set-ItemProperty -Path $RegPath -Name $FieldName -Value $Value -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "Failed to set field $FieldName : $($_.Exception.Message)" -Level WARNING
    }
}
```

#### 3. Error Tracking (MANDATORY)

```powershell
# At script start
$ExecutionStartTime = Get-Date
$ErrorsEncountered = 0
$ErrorDetails = @()

# In try/catch blocks
try {
    # Main logic
} catch {
    Write-Log "Error: $($_.Exception.Message)" -Level ERROR
    $ErrorsEncountered++
    $ErrorDetails += $_.Exception.Message
    exit 99
}
```

#### 4. Finally Block (MANDATORY)

```powershell
finally {
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    
    Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    
    if ($ErrorsEncountered -gt 0) {
        Write-Log "Errors Encountered: $ErrorsEncountered"
        Write-Log "Error Summary: $($ErrorDetails -join '; ')"
    }
}
```

#### 5. Exit Codes (STANDARDIZED)

| Code | Meaning | Usage |
|------|---------|-------|
| 0 | Success | Normal completion |
| 1 | Not applicable | Feature not installed/available |
| 2 | Configuration error | Missing dependencies, config issues |
| 3-98 | Specific errors | Component-specific failures |
| 99 | Unexpected error | Unhandled exceptions |

---

## 📝 Script Templates

### Basic Monitoring Script Template

```powershell
#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    [Script purpose]

.DESCRIPTION
    [Detailed description]

.NOTES
    Author: Windows Automation Framework
    Created: 2026-02-10
    Version: 1.0
#>

[CmdletBinding()]
param()

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "1.0"
$ScriptName = "[Script Name]"
$FieldPrefix = "customPrefix"

$Thresholds = @{
    WarningLevel = 75
    CriticalLevel = 90
}

# ============================================================================
# EXECUTION TIME TRACKING (MANDATORY)
# ============================================================================

$ExecutionStartTime = Get-Date
$ErrorsEncountered = 0
$ErrorDetails = @()

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    # [Standard implementation]
}

function Set-NinjaField {
    # [Standard implementation]
}

# [Your custom functions]

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================"
    Write-Log "$ScriptName v$ScriptVersion"
    Write-Log "========================================"
    
    # [Your main logic here]
    
    Write-Log "Script completed successfully"
    exit 0
    
} catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    
    $ErrorsEncountered++
    $ErrorDetails += $_.Exception.Message
    
    Set-NinjaField -FieldName "$($FieldPrefix)Status" -Value "ERROR"
    
    exit 99
} finally {
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    
    if ($ErrorsEncountered -gt 0) {
        Write-Log "Errors Encountered: $ErrorsEncountered"
        Write-Log "Error Summary: $($ErrorDetails -join '; ')"
    }
}
```

---

## ✅ Testing Requirements

### Before Submitting

1. **PSScriptAnalyzer**
   ```powershell
   # Run analyzer
   Invoke-ScriptAnalyzer -Path .\YourScript.ps1 -Severity Warning,Error
   
   # Should return zero warnings/errors
   ```

2. **Manual Testing**
   - Test on target Windows version
   - Verify all exit codes
   - Check custom field updates
   - Validate HTML report generation (if applicable)
   - Test error handling paths

3. **Performance Testing**
   - Execution time < documented timeout
   - Memory usage reasonable (<500MB)
   - No resource leaks
   - Concurrent execution safe

4. **Documentation Testing**
   - Help content accurate (`Get-Help .\Script.ps1`)
   - Examples work as written
   - All parameters documented

### Test Checklist

- [ ] Script runs without errors
- [ ] All exit codes tested
- [ ] Custom fields updated correctly
- [ ] Error handling works
- [ ] Execution time logged
- [ ] PSScriptAnalyzer clean
- [ ] Documentation complete
- [ ] Examples tested

---

## 📤 Pull Request Process

### Before Creating PR

1. **Update Your Branch**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test Thoroughly**
   - Run all tests
   - Verify functionality
   - Check for breaking changes

3. **Update Documentation**
   - Update README if needed
   - Add to CHANGELOG.md
   - Update script documentation

### Creating the Pull Request

1. **Push Your Branch**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create PR on GitHub**
   - Use clear, descriptive title
   - Reference related issues
   - Fill out PR template completely

3. **PR Description Should Include:**
   - What changes were made
   - Why changes were needed
   - How to test the changes
   - Screenshots (if UI changes)
   - Breaking changes (if any)

### PR Template

```markdown
## Description
[Describe your changes]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Windows Server 2022
- [ ] Tested on Windows 10/11
- [ ] PSScriptAnalyzer passed
- [ ] Documentation updated

## Related Issues
Fixes #[issue number]

## Additional Notes
[Any additional context]
```

### Review Process

1. **Automated Checks**
   - PSScriptAnalyzer
   - Syntax validation
   - File naming conventions

2. **Manual Review**
   - Code quality
   - Standards compliance
   - Security considerations
   - Performance implications

3. **Approval Required**
   - At least one maintainer approval
   - All checks passing
   - Conflicts resolved

---

## 📚 Documentation

### Documentation Requirements

#### Script Documentation

**Synopsis Block (Required):**
- Clear one-line description
- Detailed multi-line description
- Complete .NOTES section
- Working examples
- Links to related docs

**Inline Comments:**
- Complex logic explained
- Non-obvious decisions documented
- Threshold rationale included
- External dependencies noted

#### Code Comments

**Good:**
```powershell
# Check for stale checkpoints (>7 days old)
# These can indicate backup issues or forgotten test snapshots
$StaleCheckpoints = $Checkpoints | Where-Object { 
    $_.CreationTime -lt (Get-Date).AddDays(-7) 
}
```

**Avoid:**
```powershell
# Get checkpoints
$Checkpoints = Get-VMCheckpoint
```

---

## 🎨 Style Guidelines

### Naming Conventions

**Scripts:**
- PascalCase: `Hyper-V VM Inventory 1.ps1`
- Descriptive names
- Include number for ordering

**Variables:**
- PascalCase: `$VMCount`, `$HostResources`
- Descriptive, not abbreviated (except common terms)
- Prefix for scope: `$Script:ConfigData`

**Functions:**
- Verb-Noun format: `Get-VMMetrics`, `New-HTMLReport`
- Approved PowerShell verbs
- PascalCase

**Custom Fields:**
- camelCase: `hypervVMCount`, `hypervStatus`
- Consistent prefix per script category
- Descriptive suffix

### Code Formatting

**Indentation:**
- 4 spaces (no tabs)
- Consistent throughout

**Line Length:**
- Prefer <120 characters
- Break long lines logically

**Braces:**
```powershell
# Opening brace on same line
if ($Condition) {
    # Code
}

# Functions - opening brace on new line
function Get-Data 
{
    # Code
}
```

**Operators:**
```powershell
# Space around operators
$Result = $Value1 + $Value2

# Comparison operators
if ($Count -gt 10) { }
```

---

## 🔒 Security Considerations

### Security Requirements

1. **No Hardcoded Credentials**
   - Never store passwords in scripts
   - Use Windows authentication
   - Leverage SYSTEM context

2. **Input Validation**
   - Validate all parameters
   - Sanitize user input
   - Use type constraints

3. **Least Privilege**
   - Request minimum required permissions
   - Document privilege requirements
   - Fail gracefully if insufficient

4. **Secure Logging**
   - Never log sensitive data
   - Sanitize error messages
   - Protect log files

---

## ❓ Questions & Support

### Getting Help

- **Documentation:** Check `/docs/` folder
- **Issues:** Search existing GitHub issues
- **Discussions:** Use GitHub Discussions
- **Examples:** Review Hyper-V monitoring scripts

### Contact

- **Issues:** [GitHub Issues](https://github.com/Xore/waf/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Xore/waf/discussions)
- **Security:** See SECURITY.md (if available)

---

## 🌟 Recognition

Contributors will be:
- Listed in CHANGELOG.md
- Credited in relevant documentation
- Acknowledged in release notes
- Invited to future planning discussions

---

## 📝 License

By contributing, you agree that your contributions will be licensed under the same terms as the project.

---

**Thank you for contributing to Windows Automation Framework!**

**Questions?** Open an issue or start a discussion.

**Last Updated:** 2026-02-10
