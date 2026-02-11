# Changelog

All notable changes to the Windows Automation Framework (WAF) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.0.0] - 2026-02-11

### Added - Documentation Overhaul

**Core Documentation**
- Comprehensive README.md with accurate repository structure
- CONTRIBUTING.md with complete development workflow
- CHANGELOG.md for version tracking
- LICENSE file for open source compliance

**Repository Structure**
- Verified and documented actual folder organization
- 200+ scripts in `/plaintext_scripts/` catalogued
- Hyper-V enterprise suite (8 scripts) documented
- Priority validation system (P1-P4) explained
- Patch ring deployment (PR1-PR2) detailed

**Script Categories Documented**
- Active Directory (15+ scripts)
- Network Management (20+ scripts)
- Hardware Monitoring (10+ scripts)
- Server Roles (20+ scripts)
- Security & Compliance (15+ scripts)
- Application-Specific (25+ scripts)
- System Operations (30+ scripts)
- File Operations (10+ scripts)
- Monitoring & Telemetry (15+ scripts)

### Changed

**Documentation Accuracy**
- Corrected folder structure references
- Removed non-existent folder references (`/hyper-v monitoring/`)
- Updated script counts and locations
- Improved category organization

**Standards**
- Maintained V3 framework compliance documentation
- Enhanced coding standards references
- Updated script header template accessibility

### Fixed

- Inaccurate repository structure in README
- Missing contribution guidelines
- Incomplete project overview
- Broken documentation links

---

## [2.x] - Historical

### Framework Enhancements

**V3 Framework Introduction**
- Modular architecture implementation
- Comprehensive error handling patterns
- Structured logging system
- Extensive custom field definitions for NinjaOne

**Script Development**
- 200+ production scripts deployed
- Hyper-V monitoring suite created
- Priority-based device classification system
- Phased patch deployment framework
- Network operations automation
- Active Directory management tools
- Hardware health monitoring
- Security compliance checking

**NinjaOne Integration**
- 100+ custom fields defined
- Alert threshold configuration
- Dashboard widget templates
- Automated reporting system

**Standards Documentation**
- V3 Coding Standards established
- Language-aware path handling
- Output formatting guidelines
- Script refactoring guide
- Header template standardization

---

## [1.x] - Foundation

### Initial Framework

**Core Components**
- Basic monitoring scripts
- Initial NinjaOne integration
- Fundamental error handling
- Simple logging mechanism

**Script Categories**
- System monitoring basics
- Active Directory queries
- Network diagnostics
- Service management

---

## Version Numbering

### Semantic Versioning

Given a version number MAJOR.MINOR.PATCH:

- **MAJOR** - Incompatible API changes or complete framework overhaul
- **MINOR** - Backward-compatible functionality additions
- **PATCH** - Backward-compatible bug fixes

### Framework Versions

- **V3.x** - Current modular architecture with comprehensive standards
- **V2.x** - Enhanced monitoring with NinjaOne integration
- **V1.x** - Initial framework and basic automation

---

## Unreleased

### Planned

**Documentation**
- Getting Started guide (detailed)
- Script catalog with examples
- Troubleshooting guide
- Best practices documentation
- API reference for common functions

**Script Enhancements**
- Additional Hyper-V reporting scripts
- Enhanced security compliance checks
- Expanded hardware monitoring
- Cloud integration (Azure, M365)

**Framework Improvements**
- Common function library
- Centralized configuration management
- Enhanced logging framework
- Script performance optimization

**Testing**
- Automated script testing framework
- Validation test suite
- CI/CD pipeline integration

---

## How to Update This Changelog

### For Contributors

When submitting a pull request, update the "Unreleased" section:

```markdown
## [Unreleased]

### Added
- New feature or script description

### Changed
- Modification to existing functionality

### Deprecated
- Soon-to-be-removed features

### Removed
- Removed features or scripts

### Fixed
- Bug fixes

### Security
- Vulnerability patches
```

### For Maintainers

When releasing a new version:

1. Move "Unreleased" items to new version section
2. Add version number and date: `## [X.Y.Z] - YYYY-MM-DD`
3. Add comparison link at bottom
4. Update README.md version references
5. Tag release in Git

---

## Links

- [Repository](https://github.com/Xore/waf)
- [Standards Documentation](/docs/standards/)
- [Contributing Guidelines](/CONTRIBUTING.md)
- [Issue Tracker](https://github.com/Xore/waf/issues)

---

## Legend

- **Added** - New features or scripts
- **Changed** - Changes to existing functionality
- **Deprecated** - Soon-to-be-removed features
- **Removed** - Removed features or scripts
- **Fixed** - Bug fixes
- **Security** - Vulnerability patches and security improvements

---

**Note:** This changelog starts from version 3.0.0 with comprehensive documentation. Earlier versions are summarized historically as detailed records were not maintained.
