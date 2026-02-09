# Windows Automation Framework (WAF) - Script Repository

## Overview

This directory contains PowerShell scripts for Windows automation, system management, and monitoring. All scripts follow a standardized naming convention and are organized by functional category.

## Important: Standards Compliance

**Action Required:** All scripts in this repository must comply with WAF coding standards defined in `docs/standards/`.

**See:** [STANDARDS_COMPLIANCE_ACTION_PLAN.md](STANDARDS_COMPLIANCE_ACTION_PLAN.md) for the comprehensive action plan to verify and refactor all scripts for standards compliance.

**Key Standards:**
- No emojis or Unicode symbols in output
- No colors or Write-Progress
- Execution time tracking
- Unattended operation (no user interaction)
- Language-aware paths (German/English Windows support)
- Dual-method field setting (Set-NinjaField wrapper)

## Naming Convention

All scripts follow the format: `Category-ActionDescription.ps1`

**Example:** `AD-JoinDomain.ps1`, `Network-MapDrives.ps1`, `Security-AuditUACLevel.ps1`

## Script Categories

### Active Directory (AD)
Scripts for Active Directory management, user operations, and domain controller monitoring.
- Domain operations (join, remove, trust repair)
- User management (groups, lockouts, login history)
- Domain controller health monitoring
- Replication health reports
- OU management

### Browser
Browser configuration and extension management.
- Extension enumeration for Chrome, Edge, Firefox

### Certificates
Certificate management and monitoring.
- Expiration alerts
- Certificate enumeration

### DHCP
DHCP server monitoring and management.
- Lease monitoring and alerts
- Rogue server detection

### DNS
DNS troubleshooting and management.
- Cache operations
- DNS query validation

### Event Logs
Windows Event Log operations.
- Search and filtering
- Backup and archival
- Log optimization

### Exchange
Exchange Server monitoring.
- Version checking
- Health monitoring

### File Operations (FileOps)
File system operations and management.
- Copy, move, delete operations
- Robocopy wrapper functions
- URL downloads

### Firewall
Windows Firewall management.
- Status audits
- Configuration verification

### Group Policy (GPO)
Group Policy monitoring and updates.
- GPO application monitoring
- Force updates with reporting

### Hardware
Hardware monitoring and inventory.
- Battery health checks
- Monitor detection
- Dell dock information
- SSD wear monitoring
- USB device alerts

### Hyper-V
Hyper-V host and VM management.
- Checkpoint expiration alerts
- Replication monitoring
- Host-guest relationship detection

### IIS
IIS web server management.
- Binding enumeration
- App pool monitoring

### Licensing
Software licensing monitoring.
- Windows activation status
- Office licensing
- Unlicensed system alerts

### Monitoring
System performance and health monitoring.
- Capacity trend forecasting
- Device uptime tracking
- File modification alerts
- Host file change detection
- NTP time sync verification
- System performance checks
- Telemetry collection

### Network
Network configuration and monitoring.
- Adapter speed alerts
- DNS configuration
- Drive mapping
- LLDP information
- Internet speed tests
- LLMNR and NetBIOS configuration
- Port listening detection
- SMBv1 detection and removal
- TCP/UDP connection monitoring

### NinjaRMM
NinjaRMM-specific custom field management.
- Device description updates
- Location updates via GeoIP
- STAT field validation
- Hard drive type detection

### Notifications
User notification systems.
- Toast message display

### Office365/Outlook
Microsoft 365 and Outlook management.
- Modern authentication alerts
- OST/PST file reporting
- Profile migration

### OneDrive
OneDrive monitoring and configuration.
- Configuration enumeration
- File deployment

### Power Management
Power plan and startup configuration.
- Active plan reporting
- Fast startup configuration

### Printing
Print service management.
- Queue troubleshooting and clearing

### Process Management
Process control operations.
- Application termination
- Service management

### RDP (Remote Desktop)
Remote Desktop configuration and monitoring.
- Status and port verification
- RDP enablement

### SAP
SAP application management.
- Profile cleanup
- Automatic update control
- SAPGUI purging

### Security
Security auditing and hardening.
- Antivirus detection
- BitLocker monitoring
- Brute force detection
- Credential Guard status
- Local administrator auditing
- Secure Boot compliance
- SmartScreen configuration
- TLS/SSL hardening
- UAC configuration
- Unsigned driver detection
- Process signature verification

### Server Management
Server-specific operations.
- Role detection and inventory

### Services
Windows service management.
- Stopped service detection
- Service restart operations

### Shortcuts
Desktop shortcut creation.
- EXE shortcuts
- RDP shortcuts
- URL shortcuts
- Generic shortcut creation

### Software Management
Software installation, removal, and inventory.
- Application installation (Office, CATIA, Dell Command Update, etc.)
- Application removal
- Installed software enumeration
- Bloatware removal
- Windows Store app installation

### SQL Server
SQL Server monitoring and management.
- Instance enumeration
- Server health monitoring

### System Operations
Core system management.
- Blue screen detection
- Device description management
- Enrollment status
- Minidump configuration
- Reboot reason tracking
- User logoff
- Search index rebuilding
- Shutdown operations
- Time synchronization

### Teams
Microsoft Teams management.
- Cache clearing

### Templates
Script templates for common patterns.
- Invoke-AsUser template

### User Management
User account operations.
- Display name retrieval

### Veeam
Veeam Backup monitoring.
- Backup job monitoring
- Failure alerts

### VPN
VPN configuration and deployment.
- Azure VPN configuration
- Profile import

### WiFi
WiFi profile management.
- Profile deployment
- Report generation
- Driver information
- Network cleanup

### Windows
Windows OS configuration.
- Windows 10 to 11 upgrade control
- Windows Update configuration

## Usage Guidelines

### Script Execution

Most scripts are designed to run under SYSTEM context via NinjaRMM or other RMM platforms. Some scripts may require:

- Administrative privileges
- Specific PowerShell version (5.1 or higher)
- External modules or tools
- Network connectivity

### Parameters

Many scripts accept parameters for customization. Use `Get-Help` to view available parameters:

```powershell
Get-Help .\Category-ScriptName.ps1 -Full
```

### Custom Fields

Scripts that integrate with NinjaRMM use custom fields for data storage. Field names follow these conventions:
- **OPS** - Operational metrics
- **STAT** - Statistical/stability data
- **SEC** - Security information
- **CAP** - Capacity metrics
- **UPD** - Update/patch information
- **DRIFT** - Configuration drift
- **AUTO** - Automation flags
- **RISK** - Risk assessment
- **UX** - User experience

## Best Practices

1. **Test First** - Always test scripts on non-production systems
2. **Review Code** - Examine script contents before execution
3. **Check Dependencies** - Verify required modules and permissions
4. **Monitor Logs** - Review execution logs for errors
5. **Version Control** - Track changes to scripts
6. **Documentation** - Document custom modifications
7. **Follow Standards** - Comply with WAF coding standards (see action plan)

## Script Standards

### Formatting Rules

- No checkmark/cross characters in scripts
- No emojis in scripts
- No colors or Write-Progress
- Clear, descriptive output messages
- Proper error handling with try/catch blocks
- Exit codes (0 = success, 1 = failure)
- Plain ASCII text only

### Code Structure

```powershell
# Script header with description
# Parameter definitions
# Execution time tracking ($StartTime)
# Main execution block wrapped in try/catch
# Logging output (Write-Log function)
# Custom field updates (Set-NinjaField wrapper)
# Finally block with execution time logging
# Exit with appropriate code
```

### Critical Requirements

All scripts MUST:
- Track execution time
- Use Set-NinjaField wrapper (not direct Ninja-Property-Set)
- Operate unattended (no Read-Host, Pause, or confirmations)
- Support German and English Windows (if using file paths)
- Output plain text only (no emojis, symbols, or colors)

**See [STANDARDS_COMPLIANCE_ACTION_PLAN.md](STANDARDS_COMPLIANCE_ACTION_PLAN.md) for complete requirements.**

## Migration Status

All scripts have been migrated from `.txt` to `.ps1` format with standardized naming.

- **Total Scripts**: 219+
- **Format**: `.ps1` (PowerShell)
- **Naming**: `Category-ActionDescription.ps1`
- **PowerShell Compliance**: 100% (2 batch scripts converted)
- **Standards Compliance**: In Progress (see action plan)

See `MIGRATION_PROGRESS.md` for detailed migration tracking.

## Contributing

When adding new scripts:

1. Follow the naming convention: `Category-ActionDescription.ps1`
2. Comply with all WAF coding standards (see `docs/standards/`)
3. Add appropriate category if new functional area
4. Include script header with synopsis and description
5. Use consistent formatting and error handling
6. Update this README if adding new categories
7. Test thoroughly before committing (including German Windows)

## Support

For issues or questions about specific scripts:

1. Check script header comments for author and notes
2. Review execution logs for detailed error messages
3. Verify prerequisites (modules, permissions, connectivity)
4. Test in isolated environment before production use
5. Consult [STANDARDS_COMPLIANCE_ACTION_PLAN.md](STANDARDS_COMPLIANCE_ACTION_PLAN.md) for refactoring guidance

## Related Documentation

### In This Directory
- `MIGRATION_PROGRESS.md` - Script migration tracking
- `SCRIPT_INDEX.md` - Complete script catalog
- `BATCH_TO_POWERSHELL_CONVERSION.md` - Batch conversion log
- `STANDARDS_COMPLIANCE_ACTION_PLAN.md` - **Standards compliance action plan**

### Parent Directory Standards
- `../docs/standards/README.md` - Standards overview
- `../docs/standards/CODING_STANDARDS.md` - Coding standards (v1.4)
- `../docs/standards/OUTPUT_FORMATTING.md` - Output standards (v1.0)
- `../docs/standards/LANGUAGE_AWARE_PATHS.md` - Path handling (v1.0)
- `../docs/standards/SCRIPT_REFACTORING_GUIDE.md` - Refactoring guide
- `../docs/standards/SCRIPT_HEADER_TEMPLATE.ps1` - Script template

### NinjaRMM Framework
- NinjaRMM documentation files (in parent directory)
- Custom field definitions
- Dashboard templates

---

**Repository**: Xore/waf  
**Last Updated**: February 9, 2026, 11:09 PM CET  
**Version**: 2.1  
**Standards Compliance**: Action Plan Created
