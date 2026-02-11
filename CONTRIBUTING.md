# Contributing to Windows Automation Framework (WAF)

Thank you for your interest in contributing to WAF! This guide will help you understand our development process and standards.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Documentation](#documentation)

---

## Code of Conduct

We are committed to providing a welcoming and inclusive experience for everyone. Please:

- Be respectful and constructive in discussions
- Focus on technical merit and improvement
- Help maintain a positive community
- Report any unacceptable behavior to repository maintainers

---

## Getting Started

### Prerequisites

1. **Windows Environment** - Server 2016+ or Windows 10/11
2. **PowerShell** - Version 5.1 or later
3. **Git** - For version control
4. **Code Editor** - VS Code recommended with PowerShell extension
5. **Lab Environment** - For testing (virtual machines recommended)

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR-USERNAME/waf.git
cd waf

# Add upstream remote
git remote add upstream https://github.com/Xore/waf.git
```

### Branch Strategy

```bash
# Keep your main branch in sync
git checkout main
git pull upstream main

# Create a feature branch
git checkout -b feature/your-feature-name
# OR
git checkout -b fix/issue-description
```

---

## Development Workflow

### 1. Choose Your Contribution

**New Scripts**
- Identify a monitoring or automation need
- Check for similar existing scripts
- Design with V3 framework principles

**Script Improvements**
- Review existing scripts in `/plaintext_scripts/`
- Identify enhancement opportunities
- Maintain backward compatibility when possible

**Documentation**
- Update existing docs for accuracy
- Add missing guides or examples
- Improve clarity and completeness

**Bug Fixes**
- Check [Issues](https://github.com/Xore/waf/issues) for reported bugs
- Reproduce the issue in your lab
- Develop and test the fix

### 2. Implement Your Changes

**For New Scripts:**

1. Use script header template from `/docs/standards/SCRIPT_HEADER_TEMPLATE.ps1`
2. Follow V3 coding standards (see below)
3. Implement comprehensive error handling
4. Add inline documentation
5. Include usage examples in header

**For Modifications:**

1. Review refactoring guide: `/docs/standards/SCRIPT_REFACTORING_GUIDE.md`
2. Maintain existing functionality
3. Update version number and changelog in header
4. Document breaking changes clearly

### 3. Test Thoroughly

All contributions must be tested in a lab environment:

```powershell
# Test basic functionality
./your-script.ps1

# Test with various parameters
./your-script.ps1 -Parameter1 Value1 -Verbose

# Test error conditions
# - Missing permissions
# - Invalid inputs
# - Network failures
# - Missing dependencies
```

### 4. Document Your Changes

- Update README.md if adding new functionality
- Add or update relevant documentation in `/docs/`
- Include examples in script headers
- Update CHANGELOG.md (see template below)

---

## Coding Standards

### V3 Framework Compliance

All scripts must follow [V3 Coding Standards](/docs/standards/CODING_STANDARDS.md):

**Required Elements:**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Brief description of script purpose

.DESCRIPTION
    Detailed description of functionality

.PARAMETER ParameterName
    Description of each parameter

.EXAMPLE
    ./Script-Name.ps1
    Description of example

.NOTES
    Author: Your Name
    Version: 1.0.0
    Date: YYYY-MM-DD
    Requires: Dependencies listed here
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Parameter1 = "Default"
)

# Main script logic with error handling
try {
    # Implementation
}
catch {
    Write-Error "Descriptive error: $_"
    exit 1
}
```

**Key Standards:**

1. **Error Handling** - Try-catch blocks for all risky operations
2. **Logging** - Use Write-Verbose, Write-Warning, Write-Error appropriately
3. **Parameters** - Define with proper types and validation
4. **Functions** - Modular, single-responsibility functions
5. **Comments** - Explain why, not what (code should be self-documenting)
6. **Formatting** - Consistent indentation (4 spaces), line breaks for readability

### NinjaOne Integration

For scripts that populate custom fields:

```powershell
# Use Ninja-Property-Set for custom field updates
Ninja-Property-Set fieldName $value

# Follow field naming conventions
# - Prefix with category (hw_, sys_, net_, etc.)
# - Use descriptive names
# - Document field purpose in script header
```

### Naming Conventions

**Scripts:**
- Use PascalCase: `Get-SystemHealth.ps1`
- Include action verb: Get, Set, Test, Monitor, Update, etc.
- Group by prefix for organization: `AD-`, `Network-`, `Hardware-`

**Variables:**
- Use camelCase: `$computerName`, `$maxRetries`
- Be descriptive: `$diskFreeSpaceGB` not `$fs`

**Functions:**
- Use PascalCase with verb-noun: `Get-ServiceStatus`
- Follow PowerShell approved verbs

---

## Testing Requirements

### Minimum Testing

Before submitting, verify:

1. **Syntax** - Script runs without errors
2. **Basic Functionality** - Core purpose achieved
3. **Error Handling** - Graceful failure with clear messages
4. **Parameter Validation** - Invalid inputs handled properly
5. **Permissions** - Works with standard admin rights
6. **Dependencies** - All requirements documented and checked

### Test Environments

**Required Testing:**
- Windows Server 2016 or 2019
- Windows 10 or 11 (if applicable)
- Domain-joined and workgroup scenarios

**Recommended Testing:**
- Multiple PowerShell versions (5.1, 7.x)
- Various server roles if applicable
- Different language locales for path-dependent scripts

### Test Documentation

Include in your pull request:

```markdown
## Testing Performed

**Environment:**
- OS: Windows Server 2019
- PowerShell: 5.1.17763
- Domain: Member server

**Test Cases:**
1. Basic execution: ✅ Success
2. Invalid parameter: ✅ Handled correctly
3. Missing permissions: ✅ Clear error message
4. Edge case (describe): ✅ Result as expected

**Results:**
Script performed as expected across all test scenarios.
```

---

## Pull Request Process

### Before Submitting

1. **Sync with upstream**
   ```bash
   git checkout main
   git pull upstream main
   git checkout feature/your-branch
   git rebase main
   ```

2. **Self-review checklist:**
   - [ ] Code follows V3 standards
   - [ ] All tests passed
   - [ ] Documentation updated
   - [ ] Commit messages are clear
   - [ ] No sensitive information (passwords, IPs, etc.)

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "type: brief description
   
   Detailed explanation of changes
   - Bullet point 1
   - Bullet point 2
   
   Fixes #123"
   ```

   **Commit types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Submitting

1. **Push to your fork**
   ```bash
   git push origin feature/your-branch
   ```

2. **Create pull request on GitHub**
   - Clear title describing the change
   - Complete PR template (auto-filled)
   - Reference related issues
   - Add screenshots if UI-related

3. **PR Template Requirements**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] New script
   - [ ] Script enhancement
   - [ ] Bug fix
   - [ ] Documentation
   - [ ] Other (describe)

   ## Testing
   Describe testing performed

   ## Checklist
   - [ ] Follows V3 coding standards
   - [ ] Tested in lab environment
   - [ ] Documentation updated
   - [ ] Self-reviewed code
   ```

### Review Process

1. Automated checks run (if configured)
2. Maintainer reviews code and documentation
3. Feedback provided via PR comments
4. You address feedback with commits
5. Once approved, maintainer merges

**Response Time:** We aim to review within 7 days. Complex changes may take longer.

---

## Issue Guidelines

### Bug Reports

```markdown
**Script Name:** Name of affected script

**Description:** Clear description of the issue

**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior:** What should happen

**Actual Behavior:** What actually happens

**Environment:**
- OS: Windows Server 2019
- PowerShell: 5.1
- Script Version: 1.0.0

**Error Messages:**
```
Paste error output here
```

**Additional Context:** Any other relevant information
```

### Feature Requests

```markdown
**Feature Description:** Clear description of proposed feature

**Use Case:** Why this feature would be valuable

**Proposed Solution:** How you envision it working

**Alternatives Considered:** Other approaches you've thought about

**Additional Context:** Screenshots, examples, etc.
```

### Questions

For questions about usage:
- Check `/docs/` documentation first
- Search existing issues
- Use [GitHub Discussions](https://github.com/Xore/waf/discussions) for general questions
- Create issue only if documentation is unclear

---

## Documentation

### Documentation Structure

```
/docs/
├── standards/          # Coding and style standards
├── getting-started/    # Setup and deployment guides
├── scripts/           # Script-specific documentation
├── reference/         # Reference materials
└── troubleshooting/   # Common issues and solutions
```

### Documentation Standards

**Markdown Files:**
- Use clear headers (##, ###)
- Include table of contents for long docs
- Add code examples with syntax highlighting
- Link to related documents

**Code Examples:**
```powershell
# Always include comments
# Show realistic scenarios
# Include expected output when helpful
```

**Screenshots:**
- Use only when necessary
- Optimize file size
- Store in `/docs/images/` if needed

---

## Questions?

If you need help or clarification:

1. **Documentation:** Check `/docs/` directory
2. **Discussions:** [GitHub Discussions](https://github.com/Xore/waf/discussions)
3. **Issues:** Create an issue for documentation improvements

---

## License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.

---

**Thank you for contributing to WAF!** Your efforts help improve Windows automation for everyone.
