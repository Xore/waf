# Changelog

All notable changes to the Windows Automation Framework.

## [4.1.0] - 2026-02-09

### Added
- Comprehensive script repository documentation (plaintext_scripts/README.md)
- Complete script index catalog with 219+ scripts (plaintext_scripts/SCRIPT_INDEX.md)
- Migration tracking documentation (plaintext_scripts/MIGRATION_PROGRESS.md)
- Script categorization across 45 functional areas
- Usage guidelines and best practices documentation
- Integration documentation for NinjaRMM custom fields

### Changed
- All 219+ scripts migrated from .txt to .ps1 format
- Standardized naming convention: Category-ActionDescription.ps1
- Improved script discoverability and organization
- Enhanced documentation structure in plaintext_scripts directory

### Improved
- Script naming consistency (100% compliance)
- Repository organization and navigation
- Documentation completeness for script repository
- User onboarding for script deployment

### Migration Details
- **Total Scripts Migrated**: 219+
- **Script Categories**: 45
- **Documentation Created**: 29.2 KB (3 comprehensive markdown files)
- **Naming Standard**: Category-ActionDescription.ps1
- **Completion Date**: February 9, 2026

---

## [4.0.0] - 2026-02-08

### Added
- Complete reference documentation suite (5 comprehensive guides)
- 277+ custom fields fully documented with types, descriptions, examples
- 110 scripts including patching automation (PR1, PR2, P1-P4 validators)
- Dashboard templates with 50+ widget specifications
- Alert configuration guide with 50+ production-ready templates
- Complete deployment guide with 10 comprehensive phases
- Quick start guide for 5-minute initial setup
- Repository reorganization plan and implementation
- CHANGELOG.md for version tracking
- CONTRIBUTING.md for development guidelines

### Changed
- Repository structure reorganized for improved navigation
- Documentation streamlined and consolidated
- Historical development artifacts moved to archive/
- Root README.md enhanced with comprehensive overview
- docs/README.md transformed into documentation hub

### Improved
- Field naming consistency across all 277+ fields
- Script error handling and logging
- Documentation searchability and organization
- User onboarding experience
- Navigation structure and hierarchy

### Archived
- 28 historical documents moved to archive/development/
  - Phase tracking documents (18 files)
  - Completion summaries (6 files)
  - Session logs (4 files)
- All content preserved in git history

---

## [3.2.0] - 2026-02-03

### Added
- Unix Epoch date/time handling for all temporal fields
- Base64-encoded JSON for complex data structures
- LDAP:// protocol for Active Directory queries
- Language-neutral implementations (German/English Windows)

### Changed
- Active Directory queries migrated to ADSI (no RSAT required)
- Date/Time text fields converted to Unix Epoch format
- Complex data migrated to Base64-encoded JSON

### Removed
- RSAT dependencies eliminated
- External module dependencies removed
- Localized string matching eliminated

---

## [3.0.0] - 2026-02-01

### Added
- 110 complete monitoring and automation scripts
- Server role monitoring (IIS, SQL, MySQL, Hyper-V, etc.)
- Patching automation with ring-based deployment
- Advanced telemetry and predictive analytics
- Configuration drift detection
- User experience monitoring

### Improved
- Script execution performance
- Error handling and logging
- Field population reliability

---

## [2.0.0] - 2026-01-15

### Added
- Extended automation scripts
- Security posture monitoring
- Capacity forecasting
- Predictive analytics

---

## [1.0.0] - 2025-12-01

### Added
- Initial framework release
- Core monitoring scripts
- Basic custom field definitions
- Foundation for automation

---

## Version Numbering

WAF follows [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH**
- **MAJOR:** Breaking changes, incompatible API changes
- **MINOR:** New features, backward-compatible
- **PATCH:** Bug fixes, backward-compatible

---

## Upgrade Guides

### Upgrading to 4.1.0

**Changes:**
- All scripts now use .ps1 extension
- New documentation in plaintext_scripts directory
- Standardized naming convention implemented

**Action Required:**
- Update script references to use .ps1 extension
- Review new README.md in plaintext_scripts/
- Use SCRIPT_INDEX.md for script discovery

**Breaking Changes:** None (script content unchanged)

### Upgrading to 4.0.0

**Changes:**
- Repository structure reorganized
- Historical docs moved to archive/
- New Quick Start guide available

**Action Required:**
- Update documentation bookmarks
- Review new Quick Start guide
- Check reorganization plan for details

**Breaking Changes:** None

### Upgrading to 3.0.0

**Changes:**
- Date/Time fields now use Unix Epoch
- Complex data now uses Base64-encoded JSON
- RSAT no longer required

**Action Required:**
- Create new Date/Time custom fields in NinjaRMM
- Update field types if necessary
- Test scripts on non-RSAT systems

**Breaking Changes:**
- Field type changes for date/time fields
- Data format changes for complex fields

---

## Maintenance

This changelog is updated with each release following [Keep a Changelog](https://keepachangelog.com/) principles.

**Categories:**
- **Added** - New features
- **Changed** - Changes to existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security fixes

---

**Last Updated:** February 9, 2026, 11:00 PM CET
