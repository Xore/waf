# Windows Automation Framework - Standards Documentation

**Last Updated:** February 9, 2026

---

## Overview

This directory contains all coding standards, best practices, and technical guides for the Windows Automation Framework. All contributors must follow these standards to ensure consistency, reliability, and maintainability.

---

## Core Standards

### [CODING_STANDARDS.md](CODING_STANDARDS.md)
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

## Technical Guides

### [OUTPUT_FORMATTING.md](OUTPUT_FORMATTING.md)
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

**Critical Requirement:**
- **ALL scripts MUST use plain text output only**
- Never use Write-Host with -ForegroundColor
- Never use emojis or special Unicode characters
- Never use ANSI color codes
- Never use Write-Progress for long operations
- Use words instead of symbols ("Success" not "✓")

**Rationale:**
- NinjaRMM console displays plain text only
- Log files corrupted by UTF-8 emojis
- SIEM/monitoring tools require plain text
- Accessibility (screen readers)
- Cross-platform compatibility

**Quick Reference:**
| Prohibited | Alternative |
|------------|-------------|
| "Status: ✓" | "Status: Success" |
| "CPU: 75%" | "CPU: 75 percent" |
| Write-Host -ForegroundColor Green | Write-Log -Level INFO |
| Write-Progress | Log milestone percentages |
| "100 → 200" | "Changed from 100 to 200" |
| "Temp: 45°C" | "Temperature: 45 degrees Celsius" |

### [LANGUAGE_AWARE_PATHS.md](LANGUAGE_AWARE_PATHS.md)
**Language-aware path handling for German and English Windows**

**Version:** 1.0

Comprehensive guide for handling file system paths that vary between Windows language versions:

**Key Features:**
- **Get-LocalizedPath function** (handles German and English folder names)
- **Common folder translations** (Desktop/Schreibtisch, Documents/Dokumente, etc.)
- **Environment variable usage** (language-independent paths)
- **Registry-based resolution** (shell folder paths)
- **System folder handling** (Program Files/Programme, Users/Benutzer)
- Complete usage examples
- Testing guidelines
- Best practices and anti-patterns

**Critical Requirement:**
- **ALL scripts MUST support both German and English path variants**
- Never hardcode single-language paths
- Use Get-LocalizedPath function for user folders
- Prefer environment variables when available
- Log which path variant was found

**Common Folder Translations:**
| English | German |
|---------|--------|
| Desktop | Schreibtisch |
| Documents | Dokumente |
| Pictures | Bilder |
| Music | Musik |
| Public | Öffentlich |

---

## Template Files

### SCRIPT_HEADER_TEMPLATE.ps1
**Standard script template** (to be created)

Starter template including:
- Comment-based help structure
- Required parameters section
- Initialization with $StartTime
- Write-Log function
- Set-NinjaField function with CLI fallback
- Module dependency installation pattern
- Main execution block
- Finally block with execution time logging

---

## Quick Start Guide

### Creating a New Script

1. **Get next sequential number:**
   ```powershell
   Get-ChildItem -Filter "*.ps1" -Recurse |
       Where-Object { $_.Name -match ' (\d+)\.ps1$' } |
       ForEach-Object { [int]$Matches[1] } |
       Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
   # Add 1 to this number
   ```

2. **Name your script:**
   - Format: `[Description] [Number].ps1`
   - Example: `Disk Space Monitor 47.ps1`
   - 2-5 words, human-readable
   - Title Case

3. **Use the template:**
   - Copy `SCRIPT_HEADER_TEMPLATE.ps1`
   - Update comment-based help
   - Include required functions (Write-Log, Set-NinjaField)
   - Add module installation if needed
   - Add Get-LocalizedPath if using user folders

4. **Implement output standards:**
   ```powershell
   # REQUIRED - Plain text only
   Write-Log "Status: Success" -Level INFO
   Write-Log "CPU usage: 75 percent" -Level INFO
   
   # FORBIDDEN - No emojis, symbols, or colors
   # Write-Host "Status: ✓" -ForegroundColor Green  # NEVER do this
   ```

5. **Implement language-aware paths:**
   ```powershell
   # Include Get-LocalizedPath function from LANGUAGE_AWARE_PATHS.md
   
   # Use for user folders
   $DesktopPath = Get-LocalizedPath -FolderType 'Desktop'
   
   # Or use environment variables
   $AppData = $env:APPDATA  # Language-independent
   ```

6. **Test thoroughly:**
   - Runs without errors
   - No user interaction
   - Execution time logged
   - Fields populate correctly
   - Works on German Windows
   - Works on English Windows
   - Handles missing modules
   - No unexpected restarts
   - **No emojis, symbols, or colors in output**

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
- [ ] Percentages written as "75 percent" not "75%"
- [ ] Status indicators are text ("Running" not "▶")

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
- [ ] Module auto-installation tested
- [ ] Log output verified (plain text, no symbols)

---

## Document Version History

### CODING_STANDARDS.md
- **v1.4** (2026-02-09): Added module dependency auto-installation requirements
- **v1.3** (2026-02-09): Added file naming schema with sequential numbering
- **v1.2** (Earlier): Added execution time tracking and dual-method field setting

### OUTPUT_FORMATTING.md
- **v1.0** (2026-02-09): Initial release with emoji/symbol/color prohibition

### LANGUAGE_AWARE_PATHS.md
- **v1.0** (2026-02-09): Initial release with German/English path support

---

## Contributing to Standards

If you identify areas for improvement:

1. Document the issue or proposed change
2. Discuss with team (if major change)
3. Update relevant standard document(s)
4. Increment version number
5. Update this README.md
6. Commit with clear message: `[Standards] Description of change`

---

## Related Resources

### GitHub Repository
- **Main Repo:** [Xore/waf](https://github.com/Xore/waf)
- **Issues:** Report standard issues or suggestions
- **Wiki:** Extended documentation (if available)

### External References
- [PowerShell Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines)
- [NinjaRMM Documentation](https://www.ninjarmm.com/documentation/)
- [Windows PowerShell Language](https://learn.microsoft.com/en-us/powershell/scripting/overview)

---

## Support

For questions or clarifications about standards:

1. Check existing documentation first
2. Review code examples in repository
3. Ask team members
4. Create issue for clarification if needed

---

**Standards Directory:** `docs/standards/`  
**Repository:** https://github.com/Xore/waf  
**Maintained by:** Windows Automation Framework Team
