# Windows Automation Framework - Standards Documentation

**Last Updated:** February 11, 2026

---

## Overview

This directory contains all coding standards, best practices, and technical guides for the Windows Automation Framework. All contributors must follow these standards to ensure consistency, reliability, and maintainability.

---

## Core Standards

### [CODING_STANDARDS.md](../../archive/docs/standards/CODING_STANDARDS.md)
**Primary development standards document**

**Version:** 1.4

Comprehensive coding standards covering:
- **File naming schema** (human-readable descriptions with sequential numbers)
- **Execution time tracking** (mandatory for all scripts)
- **Dual-method field setting** (Set-NinjaField with CLI fallback)
- **Unattended operation** (no user interaction, no unexpected restarts)
- **Module dependency auto-installation** (NuGet and PowerShell modules)
- Script structure and templates
- Error handling patterns
- Logging standards
- Performance best practices
- Security guidelines
- Testing requirements

**Critical Requirements:**
- Track execution time in all scripts
- Use Set-NinjaField wrapper (never direct Ninja-Property-Set)
- No user interaction (Read-Host, Pause, confirmations)
- No restarts without -AllowRestart parameter
- Auto-install module dependencies
- File naming: "Description Number.ps1"

---

### [OUTPUT_FORMATTING.md](../../archive/docs/standards/OUTPUT_FORMATTING.md)
**Output formatting standards for scripts**

**Version:** 1.0

Critical standards for script output to ensure compatibility and readability:

**Key Requirements:**
- **No emojis** (encoding issues, log corruption)
- **No Unicode symbols** (checkmarks, arrows, bullets display incorrectly)
- **No colors** (-ForegroundColor stripped in logs)
- **No progress indicators** (Write-Progress not logged)
- **Plain ASCII text only** (maximum compatibility)
- Use Write-Log function for all output
- Use severity levels instead of colors (INFO, WARN, ERROR, DEBUG)
- Log milestone percentages instead of progress bars

---

### [LANGUAGE_AWARE_PATHS.md](../../archive/docs/standards/LANGUAGE_AWARE_PATHS.md)
**Language-aware path handling for German and English Windows**

**Version:** 1.0

**Critical Requirement:**
- **ALL scripts MUST support both German and English path variants**
- Never hardcode single-language paths
- Use Get-LocalizedPath function for user folders
- Prefer environment variables when available

---

## Template Files

### [SCRIPT_HEADER_TEMPLATE.ps1](../../archive/docs/standards/SCRIPT_HEADER_TEMPLATE.ps1)
**Standard script template**

Starter template including:
- Comment-based help structure
- Required parameters section
- Initialization with $StartTime
- Write-Log function
- Set-NinjaField function with CLI fallback
- Module dependency installation pattern
- Main execution block
- Finally block with execution time logging

### [SCRIPT_REFACTORING_GUIDE.md](../../archive/docs/standards/SCRIPT_REFACTORING_GUIDE.md)
**Guide for upgrading scripts to V3 standards**

Refactoring guidance for:
- V2 to V3 migration
- Function name updates
- Error handling improvements
- Testing and validation

---

## Standards Compliance Checklist

### Before Committing Any Script

#### File Naming & Structure
- [ ] Filename follows schema: "Description Number.ps1"
- [ ] Description is 2-5 words, clear and human-readable
- [ ] Sequential number assigned (next available)
- [ ] Uses spaces between words (Title Case)
- [ ] Comment-based help complete
- [ ] Script Name in header matches exact filename

#### Critical Requirements
- [ ] **Execution time tracking** ($StartTime in init, logged in finally)
- [ ] **Set-NinjaField function** included with CLI fallback
- [ ] **No user interaction** (no Read-Host, Pause, confirmations)
- [ ] **No restarts without parameter** (-AllowRestart check implemented)
- [ ] **Module dependencies** auto-install if needed
- [ ] **Language-aware paths** if accessing user folders
- [ ] **No emojis, symbols, or colors** in output
- [ ] All operations use `-Confirm:$false`

#### Output Formatting
- [ ] Uses Write-Log function (not Write-Host with colors)
- [ ] No emojis or Unicode symbols in messages
- [ ] No -ForegroundColor or -BackgroundColor
- [ ] No Write-Progress for long operations
- [ ] Plain ASCII text only
- [ ] Uses words not symbols ("Success" not "✓")

#### Code Quality
- [ ] Variables use PascalCase
- [ ] Functions use approved verbs (Get-, Set-, Test-, etc.)
- [ ] Try-catch blocks around critical operations
- [ ] Structured logging (Write-Log function)
- [ ] Error handling with graceful degradation
- [ ] No hardcoded credentials

#### Testing
- [ ] Tested on English Windows
- [ ] Tested on German Windows (if using paths)
- [ ] Runs unattended without hanging
- [ ] Execution time measured (5+ runs)
- [ ] Fields populate correctly
- [ ] Error scenarios tested

---

## Related Documentation

- [Framework Architecture](../../FRAMEWORK_ARCHITECTURE.md)
- [Contributing Guide](../../CONTRIBUTING.md)
- [Changelog](../../CHANGELOG.md)

---

**Standards Directory:** `docs/standards/`  
**Full Standards:** `archive/docs/standards/` (source files)  
**Repository:** https://github.com/Xore/waf  
**Maintained by:** Windows Automation Framework Team
