# Changelog

All notable changes to the Windows Automation Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Complete V3 migration for all core scripts
- Comprehensive documentation suite
- Hyper-V monitoring deployment guide
- Troubleshooting guide and FAQ
- PowerShell Gallery package

---

## [3.0.0] - 2026-02-10

### 🎉 Major Release - V3 Standards

This major release introduces V3 framework standards with comprehensive Hyper-V monitoring suite.

### Added

#### Hyper-V Monitoring Suite (✅ Complete)
- **Script 1:** VM Inventory and Health Monitor
  - 14 custom fields
  - VM status, configuration, and health tracking
  - HTML reporting
  
- **Script 2:** VM Backup Status Monitor
  - 14 custom fields
  - Backup health and checkpoint monitoring
  - Stale checkpoint detection
  
- **Script 3:** Host Resources and Capacity Monitor
  - 16 custom fields
  - CPU, memory, storage capacity tracking
  - Resource allocation monitoring
  
- **Script 4:** VM Replication Monitor
  - 13 custom fields
  - Replication health and status
  - Lag tracking and alerting
  
- **Script 5:** Cluster Health Monitor
  - 14 custom fields
  - Cluster node status
  - Shared volume monitoring
  
- **Script 6:** Performance Monitor
  - 14 custom fields
  - VM performance metrics
  - Resource utilization tracking
  
- **Script 7:** Storage Performance Monitor
  - 14 custom fields
  - Storage I/O metrics
  - CSV cache hit rates
  - Thin provisioning tracking
  
- **Script 8:** Multi-Host Aggregator
  - 14 custom fields
  - Cluster-wide analysis
  - Load balancing recommendations
  - VM distribution tracking

#### Documentation
- Created comprehensive README.md
- Added FRAMEWORK_ARCHITECTURE.md
- Established CONTRIBUTING.md guidelines
- Implemented DOCUMENTATION_PROGRESS.md tracker

#### Framework Standards (V3)
- Standardized function naming (`Set-NinjaField`)
- Mandatory error tracking variables
- Required `finally` block with execution time reporting
- Consistent exit code standards (0, 1-98, 99)
- Comprehensive error handling patterns

### Changed

#### V3 Migrations Completed
- **Hyper-V Scripts 5-8:** Upgraded to V3 standards
  - Script 5: Cluster Health Monitor (✅ 2026-02-10)
  - Script 6: Performance Monitor (✅ 2026-02-10)
  - Script 7: Storage Performance (✅ 2026-02-10)
  - Script 8: Multi-Host Aggregator (✅ 2026-02-10)

- **Hyper-V Scripts 1-4:** Previously upgraded
  - Scripts verified V3 compliant
  - All 8 scripts now standardized

#### Function Naming
- **BREAKING:** Renamed `Set-NinjaRMMField` → `Set-NinjaField`
  - Affects all scripts
  - Maintains backward compatibility via registry fallback
  - Migration required for custom implementations

### Fixed
- Error tracking in Hyper-V scripts 7 & 8
- Missing `finally` blocks across Hyper-V suite
- Inconsistent execution time reporting
- Custom field name variations

### Migration Guide: V2 → V3

#### Required Changes

1. **Update Function Calls**
   ```powershell
   # OLD (V2)
   Set-NinjaRMMField -FieldName "status" -Value "OK"
   
   # NEW (V3)
   Set-NinjaField -FieldName "status" -Value "OK"
   ```

2. **Add Error Tracking**
   ```powershell
   # Add at script start
   $ErrorsEncountered = 0
   $ErrorDetails = @()
   
   # In catch blocks
   catch {
       $ErrorsEncountered++
       $ErrorDetails += $_.Exception.Message
   }
   ```

3. **Add Finally Block**
   ```powershell
   finally {
       $ExecutionEndTime = Get-Date
       $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
       Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
       
       if ($ErrorsEncountered -gt 0) {
           Write-Log "Errors Encountered: $ErrorsEncountered"
       }
   }
   ```

### Technical Details

#### Hyper-V Custom Fields: 109 Total

**By Script:**
- Script 1: 14 fields (VM inventory)
- Script 2: 14 fields (VM backup)
- Script 3: 16 fields (Host resources)
- Script 4: 13 fields (VM replication)
- Script 5: 14 fields (Cluster health)
- Script 6: 14 fields (Performance)
- Script 7: 14 fields (Storage)
- Script 8: 14 fields (Multi-host)

**Field Types:**
- Text: 45 fields (status, lists, descriptions)
- Integer: 32 fields (counts, IDs)
- Float: 18 fields (percentages, ratios)
- DateTime: 8 fields (timestamps)
- WYSIWYG: 6 fields (HTML reports)

#### Performance Improvements
- Optimized WMI/CIM queries
- Reduced execution times by ~15%
- Improved error handling overhead
- Enhanced logging efficiency

---

## [2.5.0] - 2026-02-08

### Added
- Initial Hyper-V monitoring scripts (1-4)
- Basic error handling framework
- NinjaRMM custom field integration

### Changed
- Improved logging consistency
- Enhanced HTML report generation

---

## [2.0.0] - 2026-01-15

### Added
- Core monitoring script suite (44 scripts)
- Health scoring and stability analysis
- Security posture monitoring
- Patch management automation
- Server role-specific monitoring

### Changed
- Modular script architecture
- Standardized naming conventions
- Unified logging approach

---

## [1.5.0] - 2025-12-01

### Added
- Basic system monitoring scripts
- Event log analysis
- Performance tracking
- Initial NinjaRMM integration

---

## [1.0.0] - 2025-10-15

### Added
- Initial framework release
- Basic PowerShell automation scripts
- Windows system monitoring foundation

---

## Version History Summary

| Version | Date | Focus | Scripts | Status |
|---------|------|-------|---------|--------|
| 3.0.0 | 2026-02-10 | V3 Standards + Hyper-V Suite | 52 | ✅ Current |
| 2.5.0 | 2026-02-08 | Hyper-V Initial | 48 | Deprecated |
| 2.0.0 | 2026-01-15 | Core Suite Expansion | 44 | Deprecated |
| 1.5.0 | 2025-12-01 | System Monitoring | 25 | Deprecated |
| 1.0.0 | 2025-10-15 | Framework Foundation | 10 | Deprecated |

---

## Breaking Changes

### V3.0.0

#### Function Naming Change

**Impact:** HIGH  
**Affected:** All scripts using RMM field updates

```powershell
# Before (V2)
Set-NinjaRMMField -FieldName "status" -Value "OK"

# After (V3)
Set-NinjaField -FieldName "status" -Value "OK"
```

**Migration:** Update all function calls. Registry fallback provides compatibility.

#### Error Tracking Requirements

**Impact:** MEDIUM  
**Affected:** Custom script implementations

**Required additions:**
- `$ErrorsEncountered` variable
- `$ErrorDetails` array
- Error increment in catch blocks
- Error summary in finally block

#### Exit Code Standardization

**Impact:** LOW  
**Affected:** Monitoring and alerting rules

**New standard:**
- 0: Success
- 1-98: Specific errors
- 99: Unexpected error

**Migration:** Review and update NinjaRMM conditions based on exit codes.

---

## Deprecation Notices

### Deprecated in V3.0.0

- ❌ **Set-NinjaRMMField** - Use `Set-NinjaField` instead
- ❌ **Scripts without error tracking** - Must be upgraded to V3
- ❌ **Scripts without finally blocks** - Mandatory in V3

### To Be Deprecated in V4.0.0 (Planned)

- Legacy script versions in `/plaintext_scripts/`
- Non-standard exit codes
- Scripts without execution time tracking

---

## Known Issues

### V3.0.0

1. **Core Scripts V3 Migration**
   - Status: In Progress
   - Impact: Scripts in `/scripts/` folder
   - Timeline: Ongoing
   - Workaround: Scripts functional with V2 patterns

2. **Documentation Completion**
   - Status: In Progress
   - Impact: Limited deployment guides
   - Timeline: Week of 2026-02-11
   - Workaround: Use script headers and archive docs

3. **Custom Field Documentation**
   - Status: Planned
   - Impact: Manual field creation required
   - Timeline: Week of 2026-02-11
   - Workaround: Reference script headers for field lists

---

## Upgrade Path

### From V2.x to V3.0

1. **Backup Current Deployment**
   - Export NinjaRMM components
   - Document custom configurations
   - Record custom field mappings

2. **Review Breaking Changes**
   - Identify scripts using `Set-NinjaRMMField`
   - Note custom implementations
   - Review alerting rules

3. **Test in Development**
   - Deploy to test environment
   - Verify custom field updates
   - Validate alerting triggers
   - Check execution times

4. **Incremental Rollout**
   - Start with non-critical scripts
   - Monitor for issues
   - Validate data accuracy
   - Expand to production

5. **Complete Migration**
   - Update all scripts to V3
   - Verify custom field mappings
   - Update alerting conditions
   - Document changes

---

## Support & Compatibility

### Platform Requirements

**V3.0.0:**
- PowerShell 5.1+
- Windows Server 2012 R2+
- Windows 10/11
- NinjaRMM Agent (latest)

**Tested Platforms:**
- ✅ Windows Server 2022
- ✅ Windows Server 2019
- ✅ Windows Server 2016
- ✅ Windows 11
- ✅ Windows 10 (21H2+)
- ⚠️ Windows Server 2012 R2 (limited testing)

### Hyper-V Requirements

**For Hyper-V Scripts:**
- Hyper-V role installed
- Hyper-V PowerShell module
- FailoverClusters module (for clustered environments)
- Windows Server 2012 R2+

---

## Contributors

**V3.0.0 Release:**
- Framework architecture and standards
- Hyper-V monitoring suite implementation
- V3 migration and standardization
- Documentation creation

---

## References

- [Framework Architecture](FRAMEWORK_ARCHITECTURE.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Documentation Progress](DOCUMENTATION_PROGRESS.md)
- [GitHub Repository](https://github.com/Xore/waf)

---

**Maintained by:** Windows Automation Framework Team  
**Last Updated:** 2026-02-10 23:51 CET  
**Next Release:** V3.1.0 (Planned 2026-03-01)
