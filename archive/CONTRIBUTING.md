# Contributing to WAF

Thank you for your interest in contributing to the Windows Automation Framework!

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Guidelines](#development-guidelines)
4. [Submitting Changes](#submitting-changes)
5. [Coding Standards](#coding-standards)
6. [Documentation](#documentation)
7. [Testing](#testing)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors.

### Our Standards

- Be respectful and constructive
- Welcome diverse perspectives
- Focus on what is best for the community
- Show empathy towards others

---

## Getting Started

### Prerequisites

- Git installed and configured
- PowerShell 5.1 or later
- NinjaRMM test environment (recommended)
- Text editor or IDE

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/waf.git
   cd waf
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/Xore/waf.git
   ```

### Create a Branch

```bash
git checkout -b feature/your-feature-name
```

**Branch Naming:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring

---

## Development Guidelines

### Code Standards

**Follow [WAF_CODING_STANDARDS.md](docs/WAF_CODING_STANDARDS.md) for all script development.**

Key requirements:

1. **No RSAT dependencies** - Use LDAP:// for AD queries
2. **Self-contained scripts** - No external dependencies
3. **Language-neutral code** - Works on German/English Windows
4. **Proper error handling** - Try/catch blocks required
5. **Logging** - Human-readable output for troubleshooting

### Script Template

```powershell
<#
.SYNOPSIS
    Brief description

.DESCRIPTION
    Detailed description

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0
    Requires: PowerShell 5.1+
#>

try {
    # Feature check if using modules
    if (Get-Command Some-Cmdlet -ErrorAction SilentlyContinue) {
        # Module available
    }

    # Main script logic
    
    # Update custom fields
    Ninja-Property-Set fieldName $value
    
    # Human-readable logging
    Write-Output "SUCCESS: Operation completed"
    
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Submitting Changes

### Before Submitting

- [ ] Code follows WAF coding standards
- [ ] Scripts tested on test devices
- [ ] Documentation updated
- [ ] Custom fields documented
- [ ] Examples provided
- [ ] Changelog updated

### Pull Request Process

1. **Commit Changes:**
   ```bash
   git add .
   git commit -m "Add feature: description"
   ```

2. **Push to Fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request:**
   - Go to GitHub repository
   - Click "New Pull Request"
   - Select your branch
   - Fill out PR template

4. **PR Requirements:**
   - Clear description of changes
   - Link to related issues
   - Test results included
   - Documentation updates

### Commit Message Format

```
Type: Brief description (50 chars max)

Detailed explanation of changes:
- What changed
- Why it changed
- Impact of changes

Fixes #123
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Formatting changes
- `refactor:` - Code restructuring
- `test:` - Test updates
- `chore:` - Maintenance

---

## Coding Standards

### PowerShell Style

**Follow [WAF_CODING_STANDARDS.md](docs/WAF_CODING_STANDARDS.md) for complete details.**

**Quick Reference:**

1. **No checkmark/cross characters** (Space instructions)
2. **No emojis in scripts** (Space instructions)
3. **PascalCase** for variables: `$HealthScore`
4. **camelCase** for parameters: `$deviceName`
5. **Verb-Noun** functions: `Get-DeviceHealth`
6. **4-space indentation**
7. **UTF-8 encoding** with BOM
8. **CRLF line endings**

### Data Formats

**Complex Data:**
```powershell
# Use Base64-encoded JSON
$data = @{
    Property1 = "Value1"
    Property2 = "Value2"
}
$json = $data | ConvertTo-Json -Compress
$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
Ninja-Property-Set fieldName $encoded
```

**Date/Time:**
```powershell
# Use Unix Epoch
$timestamp = [DateTimeOffset]$dateTime | Select-Object -ExpandProperty ToUnixTimeSeconds
Ninja-Property-Set fieldName $timestamp
```

### Field Naming

**Format:** `CATEGORYPascalCaseDescriptor`

**Examples:**
- `opsHealthScore` (Operational health)
- `secAntivirusEnabled` (Security AV status)
- `capDiskFreePercent` (Capacity disk space)

---

## Documentation

### Required Documentation

**For New Scripts:**
1. Add to script catalog in docs/scripts/
2. Document custom fields in reference/CUSTOM_FIELDS_COMPLETE.md
3. Update field-to-script mapping
4. Provide usage examples
5. Document dependencies

**For New Fields:**
1. Field name, type, description
2. Possible values/format
3. Example values
4. Related fields
5. Populating script(s)

**For New Features:**
1. Update relevant guides
2. Add to CHANGELOG.md
3. Create examples
4. Update README.md if major feature

### Documentation Style

- Clear, concise language
- Code examples for complex topics
- Step-by-step procedures
- Screenshots when helpful
- Links to related documentation

---

## Testing

### Test Requirements

**Scripts Must Be Tested On:**
- [ ] Windows 10/11 workstation
- [ ] Windows Server 2019/2022
- [ ] Domain-joined system (if AD-related)
- [ ] Workgroup system (verify graceful handling)
- [ ] German Windows (if language-specific)

### Test Checklist

**For Each Script:**
- [ ] Runs without errors
- [ ] Completes within timeout (60s default)
- [ ] Custom fields populate correctly
- [ ] Error handling works
- [ ] Logging is clear
- [ ] No RSAT dependencies
- [ ] Works on non-English Windows
- [ ] Permissions adequate (SYSTEM account)

### Test Reporting

**Include in PR:**
```
Test Results:
- OS: Windows 10 Pro 22H2
- Domain Status: Domain-joined
- Script Execution: Success
- Field Population: Verified
- Execution Time: 15 seconds
- Errors: None
```

---

## Questions?

- **Documentation:** Check [docs/](docs/)
- **Issues:** [GitHub Issues](https://github.com/Xore/waf/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Xore/waf/discussions)

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to WAF!
