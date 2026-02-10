# Contributing to Windows Automation Framework

**Thank you for your interest in contributing!**

This document provides guidelines for contributing to the Windows Automation Framework (WAF). Following these guidelines helps maintain code quality, consistency, and makes the review process smoother for everyone.

---

## 📜 Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Standards](#development-standards)
4. [Testing Requirements](#testing-requirements)
5. [Pull Request Process](#pull-request-process)
6. [Documentation](#documentation)
7. [Style Guidelines](#style-guidelines)

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

2. **Review Standards Documentation**
   - **[Coding Standards](archive/docs/standards/CODING_STANDARDS.md)** - Complete V3 requirements
   - **[Output Formatting](archive/docs/standards/OUTPUT_FORMATTING.md)** - No emojis/colors
   - **[Language-Aware Paths](archive/docs/standards/LANGUAGE_AWARE_PATHS.md)** - German/English support
   - **[Script Header Template](archive/docs/standards/SCRIPT_HEADER_TEMPLATE.ps1)** - Standard template
   - **[Refactoring Guide](archive/docs/standards/SCRIPT_REFACTORING_GUIDE.md)** - V2 to V3 migration
   - **[Standards Checklist](docs/standards/README.md)** - Quick compliance check

3. **Create a Branch**
   ```bash
   # Create feature branch from main
   git checkout -b feature/your-feature-name
   
   # Or for bug fixes
   git checkout -b fix/issue-description
   ```

4. **Install Development Tools**
   ```powershell
   # Install PSScriptAnalyzer
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
   
   # Install Pester (testing)
   Install-Module -Name Pester -Scope CurrentUser -Force
   ```

---

## ⚙️ Development Standards

### V3 Framework Standards (MANDATORY)

**All new scripts and modifications MUST follow V3 standards.**

Complete standards documentation available:
- **[Coding Standards](archive/docs/standards/CODING_STANDARDS.md)** - Full standard requirements
- **[Quick Reference](docs/standards/README.md)** - Compliance checklist

### Critical Requirements Summary

#### 1. Output Standards ⚠️ CRITICAL

**Plain ASCII Text Only - No Emojis, Symbols, or Colors:**

See [Output Formatting Standards](archive/docs/standards/OUTPUT_FORMATTING.md) for complete details.

```powershell
# ✅ CORRECT - Plain text
Write-Log "Status: Success"
Write-Log "CPU usage: 75 percent"

# ❌ PROHIBITED - Emojis, symbols, colors
# Write-Host "Status: ✓" -ForegroundColor Green
# Write-Host "CPU: 75%"
```

**Why This Matters:**
- NinjaRMM console displays plain text only
- Log files corrupted by UTF-8 emojis
- SIEM/monitoring tools require plain text
- Accessibility (screen readers)

#### 2. Multi-Language Support ⚠️ CRITICAL

**German and English Windows Path Support:**

See [Language-Aware Paths](archive/docs/standards/LANGUAGE_AWARE_PATHS.md) for complete guide.

```powershell
# ✅ CORRECT - Language-independent
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$AppData = $env:APPDATA

# ❌ PROHIBITED - Hardcoded single-language
# $DesktopPath = "C:\Users\$env:USERNAME\Desktop"
# $DocsPath = "C:\Users\$env:USERNAME\Dokumente"  # Only German
```

#### 3. Execution Time Tracking (MANDATORY)

```powershell
# At script start
$ExecutionStartTime = Get-Date
$ErrorsEncountered = 0
$ErrorDetails = @()

# In finally block (REQUIRED)
finally {
    $ExecutionDuration = ((Get-Date) - $ExecutionStartTime).TotalSeconds
    Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    
    if ($ErrorsEncountered -gt 0) {
        Write-Log "Errors: $ErrorsEncountered"
    }
}
```

#### 4. NinjaRMM Integration

**Use Set-NinjaField (not Set-NinjaRMMField):**

```powershell
function Set-NinjaField {
    param(
        [string]$FieldName,
        [AllowNull()][object]$Value
    )
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set -Name $FieldName -Value $Value
        }
    } catch {
        Write-Log "Failed to set field $FieldName" -Level WARNING
    }
}

# Usage
Set-NinjaField -FieldName "customField" -Value $Data
```

#### 5. Unattended Operation

**No User Interaction:**

```powershell
# ❌ PROHIBITED
# Read-Host "Press Enter to continue"
# Pause
# $confirm = Read-Host "Proceed? (Y/N)"

# ✅ CORRECT - Silent operation
if ($AllowRestart) {
    Restart-Computer -Force
} else {
    Write-Log "Restart required but not permitted"
    exit 2
}
```

#### 6. Module Auto-Installation

```powershell
# Auto-install required modules
if (-not (Get-Module -ListAvailable -Name RequiredModule)) {
    Write-Log "Installing RequiredModule..."
    Install-Module RequiredModule -Force -ErrorAction Stop
}
Import-Module RequiredModule -ErrorAction Stop
```

### Script Structure Template

See [Script Header Template](archive/docs/standards/SCRIPT_HEADER_TEMPLATE.ps1) for complete template.

---

## ✅ Testing Requirements

### Pre-Submission Testing Checklist

#### Standards Compliance
- [ ] **Output:** No emojis, symbols, or colors (plain ASCII only)
- [ ] **Paths:** Supports both German and English Windows
- [ ] **Tracking:** Execution time logged in finally block
- [ ] **Integration:** Uses Set-NinjaField (not Set-NinjaRMMField)
- [ ] **Operation:** No user interaction (Read-Host, Pause, etc.)
- [ ] **Modules:** Auto-installs dependencies if needed

#### Code Quality
- [ ] PSScriptAnalyzer passes (zero warnings/errors)
- [ ] All exit codes tested and documented
- [ ] Error handling comprehensive
- [ ] Custom fields update correctly
- [ ] Execution time < documented timeout

#### Testing
- [ ] Tested on English Windows
- [ ] Tested on German Windows (if using paths)
- [ ] Tested with missing dependencies
- [ ] Tested error scenarios
- [ ] Performance validated (<500 MB memory, acceptable CPU)

#### Documentation
- [ ] Comment-based help complete
- [ ] All parameters documented
- [ ] Examples tested and working
- [ ] CHANGELOG.md updated

### Automated Testing

```powershell
# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path .\YourScript.ps1 -Severity Warning,Error

# Check for prohibited patterns
Select-String -Path .\YourScript.ps1 -Pattern "Write-Host.*-ForegroundColor"
Select-String -Path .\YourScript.ps1 -Pattern "[✓✗→⏱]"
Select-String -Path .\YourScript.ps1 -Pattern "Set-NinjaRMMField"
Select-String -Path .\YourScript.ps1 -Pattern "Read-Host|Pause"

# All above should return NO matches
```

---

## 📤 Pull Request Process

### Before Creating PR

1. **Update Your Branch**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run Standards Compliance Check**
   ```powershell
   # Run automated checks
   .\scripts\test-compliance.ps1  # If available
   
   # Manual verification
   # - Check standards checklist
   # - Verify no emojis/symbols/colors
   # - Confirm German/English path support
   # - Validate execution time tracking
   ```

3. **Update Documentation**
   - Update CHANGELOG.md
   - Add/update script documentation
   - Update README if needed

### Creating the Pull Request

1. **Push Your Branch**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **PR Description Must Include:**
   ```markdown
   ## Description
   [Clear description of changes]
   
   ## Standards Compliance
   - [ ] No emojis, symbols, or colors in output
   - [ ] Supports German and English Windows paths
   - [ ] Execution time tracking implemented
   - [ ] Uses Set-NinjaField (not Set-NinjaRMMField)
   - [ ] No user interaction (unattended operation)
   - [ ] Module auto-installation implemented
   
   ## Testing
   - [ ] PSScriptAnalyzer passed
   - [ ] Tested on English Windows
   - [ ] Tested on German Windows (if applicable)
   - [ ] All exit codes verified
   - [ ] Error scenarios tested
   
   ## Documentation
   - [ ] CHANGELOG.md updated
   - [ ] Script documentation complete
   - [ ] Examples tested
   
   ## Related Issues
   Fixes #[issue number]
   ```

### Review Process

**Automated Checks:**
- PSScriptAnalyzer validation
- Standards compliance verification
- File naming conventions
- No prohibited patterns (emojis, colors, etc.)

**Manual Review:**
- Code quality and readability
- Standards compliance (V3 requirements)
- Security considerations
- Performance implications
- Documentation completeness

---

## 📚 Documentation

### Documentation Requirements

**Script Documentation:**
- Complete comment-based help
- Clear synopsis and description
- Detailed .NOTES section (see template)
- Working examples
- Custom field mappings
- Dependencies documented

**Code Comments:**
- Complex logic explained
- Non-obvious decisions documented
- Threshold rationale included
- Reference external docs where relevant

### Key Documentation Files

**Must Read:**
- [Coding Standards](archive/docs/standards/CODING_STANDARDS.md) - V3 requirements
- [Output Formatting](archive/docs/standards/OUTPUT_FORMATTING.md) - Plain text rules
- [Language-Aware Paths](archive/docs/standards/LANGUAGE_AWARE_PATHS.md) - Multi-language support
- [Script Header Template](archive/docs/standards/SCRIPT_HEADER_TEMPLATE.ps1) - Standard template

**Reference:**
- [Framework Architecture](FRAMEWORK_ARCHITECTURE.md) - System design
- [Standards Checklist](docs/standards/README.md) - Quick compliance check
- [Refactoring Guide](archive/docs/standards/SCRIPT_REFACTORING_GUIDE.md) - V2 to V3 migration

---

## 🎨 Style Guidelines

### Naming Conventions

**Scripts:**
- Format: "Description Number.ps1"
- Example: `Hyper-V VM Inventory 1.ps1`
- 2-5 words, human-readable
- Title Case with spaces
- Sequential numbering

**Variables:**
- PascalCase: `$VMCount`, `$HostResources`
- Descriptive, not abbreviated
- Avoid single-letter except loops

**Functions:**
- Verb-Noun format: `Get-VMMetrics`, `New-HTMLReport`
- Use approved PowerShell verbs
- PascalCase

**Custom Fields:**
- camelCase: `hypervVMCount`, `hypervStatus`
- Consistent prefix per category
- Descriptive suffix

### Code Formatting

**Indentation:** 4 spaces (no tabs)  
**Line Length:** Prefer <120 characters  
**Braces:** Opening brace on same line for control structures

---

## 🔒 Security Considerations

**Requirements:**
1. No hardcoded credentials
2. Input validation on all parameters
3. Least privilege principle
4. Never log sensitive data
5. Sanitize error messages

---

## ❓ Questions & Support

**Resources:**
- [Standards Documentation](archive/docs/standards/)
- [Framework Documentation](docs/README.md)
- [GitHub Issues](https://github.com/Xore/waf/issues)
- [GitHub Discussions](https://github.com/Xore/waf/discussions)

**Before Asking:**
1. Check existing documentation
2. Search closed issues
3. Review standards thoroughly
4. Test your changes

---

## 🌟 Recognition

Contributors will be:
- Listed in CHANGELOG.md
- Credited in documentation
- Acknowledged in release notes
- Invited to planning discussions

---

## 📝 License

By contributing, you agree that your contributions will be licensed under the same terms as the project.

---

## Quick Standards Reference

### Critical "DO NOT" List

❌ **NEVER** use emojis or Unicode symbols in output  
❌ **NEVER** use Write-Host with -ForegroundColor or -BackgroundColor  
❌ **NEVER** use Write-Progress for long operations  
❌ **NEVER** hardcode single-language paths  
❌ **NEVER** use Read-Host, Pause, or prompt for user input  
❌ **NEVER** use Set-NinjaRMMField (use Set-NinjaField)  
❌ **NEVER** skip the finally block with execution time  
❌ **NEVER** restart without checking -AllowRestart parameter

### Critical "ALWAYS" List

✅ **ALWAYS** use plain ASCII text only  
✅ **ALWAYS** support German and English Windows paths  
✅ **ALWAYS** track execution time in finally block  
✅ **ALWAYS** use Set-NinjaField function  
✅ **ALWAYS** test on both English and German Windows  
✅ **ALWAYS** implement comprehensive error handling  
✅ **ALWAYS** auto-install module dependencies  
✅ **ALWAYS** document all custom fields

---

**Thank you for contributing to Windows Automation Framework!**

**Last Updated:** 2026-02-11  
**Standards Version:** 3.0
