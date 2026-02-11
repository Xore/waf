# V3 Migration Tracking - Scripts Requiring Migration

This document tracks the migration status of scripts that were moved into the `plaintext_scripts` folder and need V3 migration to use NinjaRMM custom fields and WAF framework.

## Migration Status

**Total Scripts to Migrate:** 76
**Files Renamed:** Complete (commit 1c4223f2)
**Migrated to V3:** 4
**In Progress:** 0
**Remaining:** 72
**Progress:** 5.3%

---

## Scripts Ready for V3 Migration

All scripts have been renamed to streamlined PascalCase names. Ready to begin V3 migration.

### High Priority - Security & Critical Monitoring (14 scripts)

**Start with these scripts first:**

1. [x] **SecurityAnalyzer.ps1** - Core security analysis and monitoring (Migrated: commit 75f7316d)
2. [x] **SecurityPostureConsolidator.ps1** - Consolidates security posture metrics (Migrated: commit ad9f58b9)
3. [x] **SuspiciousLoginPatternDetector.ps1** - Detects anomalous login patterns (Migrated: commit 177e65ea)
4. [x] **SecuritySurfaceTelemetry.ps1** - Security surface area telemetry (Migrated: commit 08b767d9)
5. [ ] **AdvancedThreatTelemetry.ps1** - Advanced threat detection telemetry
6. [ ] **EndpointDetectionResponse.ps1** - EDR functionality
7. [ ] **ComplianceAttestationReporter.ps1** - Compliance reporting
8. [ ] **P1CriticalDeviceValidator.ps1** - Critical priority validation
9. [ ] **P2HighPriorityValidator.ps1** - High priority validation
10. [ ] **P3P4MediumLowValidator.ps1** - Medium/low priority validation
11. [ ] **PR1PatchRing1Deployment.ps1** - Patch ring 1 deployment
12. [ ] **PR2PatchRing2Deployment.ps1** - Patch ring 2 deployment
13. [ ] **HealthScoreCalculator.ps1** - Overall health scoring
14. [ ] **StabilityAnalyzer.ps1** - System stability analysis

### High Priority - Core Monitoring (11 scripts)

15. [ ] **PerformanceAnalyzer.ps1** - Performance metrics analysis
16. [ ] **CapacityAnalyzer.ps1** - Capacity planning metrics
17. [ ] **TelemetryCollector.ps1** - General telemetry collection
18. [ ] **RiskClassifier.ps1** - Risk classification engine
19. [ ] **UpdateAssessmentCollector.ps1** - Update status assessment
20. [ ] **NetworkLocationTracker.ps1** - Network location tracking
21. [ ] **BaselineManager.ps1** - Baseline management
22. [ ] **DriftDetector.ps1** - Configuration drift detection
23. [ ] **LocalAdminDriftAnalyzer.ps1** - Local admin drift tracking
24. [ ] **ServerRoleIdentifier.ps1** - Server role identification
25. [ ] **ProactiveRemediationEngine.ps1** - Proactive remediation

### Medium Priority - Server Monitors (15 scripts)

**Consider consolidating duplicate monitors during migration:**

26. [ ] **ActiveDirectoryMonitor.ps1** - AD health monitoring
27. [ ] **GroupPolicyMonitor.ps1** - GPO monitoring
28. [ ] **ApacheWebServerMonitor.ps1** - Apache web server monitoring
29. [ ] **IISWebServerMonitor.ps1** - IIS web server monitoring
30. [ ] **MSSQLServerMonitor.ps1** - MSSQL server monitoring
31. [ ] **DHCPServerMonitor.ps1** - DHCP server monitoring
32. [ ] **NetworkMonitor.ps1** - Network monitoring
33. [ ] **VeeamBackupMonitor.ps1** - Veeam backup monitoring

**DNS Server Monitors (3 versions - consolidate):**
34. [ ] **DNSServerMonitor_v1.ps1**
35. [ ] **DNSServerMonitor_v2.ps1**
36. [ ] **DNSServerMonitor_v3.ps1**

**MySQL Server Monitors (3 versions - consolidate):**
37. [ ] **MySQLServerMonitor_v1.ps1**
38. [ ] **MySQLServerMonitor_v2.ps1**
39. [ ] **MySQLServerMonitor_v3.ps1**

**Event Log Monitors (2 versions - consolidate):**
40. [ ] **EventLogMonitor_v1.ps1**
41. [ ] **EventLogMonitor_v2.ps1**

### Medium Priority - Service Monitors (12 scripts)

**File Server Monitors (3 versions - consolidate):**
42. [ ] **FileServerMonitor_v1.ps1**
43. [ ] **FileServerMonitor_v2.ps1**
44. [ ] **FileServerMonitor_v3.ps1**

**Print Server Monitors (3 versions - consolidate):**
45. [ ] **PrintServerMonitor_v1.ps1**
46. [ ] **PrintServerMonitor_v2.ps1**
47. [ ] **PrintServerMonitor_v3.ps1**

**FlexLM License Monitors (3 versions - consolidate):**
48. [ ] **FlexLMLicenseMonitor_v1.ps1**
49. [ ] **FlexLMLicenseMonitor_v2.ps1**
50. [ ] **FlexLMLicenseMonitor_v3.ps1**

**BitLocker Monitors (2 versions - consolidate):**
51. [ ] **BitLockerMonitor_v1.ps1**
52. [ ] **BitLockerMonitor_v2.ps1**

**Battery Health Monitors (2 versions - consolidate):**
53. [ ] **BatteryHealthMonitor.ps1**
54. [ ] **BatteryHealthMonitor_v2.ps1**

### Medium Priority - Hyper-V Suite (10 scripts)

**Hyper-V Core Monitors:**
55. [ ] **HyperVMonitor.ps1** - Main Hyper-V monitoring
56. [ ] **HyperVHealthCheck.ps1** - Health check functionality
57. [ ] **HyperVPerformanceMonitor.ps1** - Performance metrics
58. [ ] **HyperVStoragePerformanceMonitor.ps1** - Storage performance
59. [ ] **HyperVCapacityPlanner.ps1** - Capacity planning
60. [ ] **HyperVClusterAnalytics.ps1** - Cluster analytics
61. [ ] **HyperVBackupComplianceMonitor.ps1** - Backup compliance
62. [ ] **HyperVMultiHostAggregator.ps1** - Multi-host aggregation

**Hyper-V Host Monitors (2 versions - consolidate):**
63. [ ] **HyperVHostMonitor_v1.ps1**
64. [ ] **HyperVHostMonitor_v2.ps1**

### Lower Priority - Telemetry & Profiling (3 scripts)

65. [ ] **CollaborationOutlookUXTelemetry.ps1** - Outlook UX telemetry
66. [ ] **ApplicationExperienceProfiler.ps1** - Application profiling
67. [ ] **ProfileHygieneCleanupAdvisor.ps1** - Profile cleanup advisor

### Lower Priority - Remediation Scripts (3 scripts)

68. [ ] **RestartPrintSpooler.ps1** - Print spooler restart
69. [ ] **RestartWindowsUpdate.ps1** - Windows Update restart
70. [ ] **EmergencyDiskCleanup.ps1** - Emergency disk cleanup

---

## V3 Migration Process

For each script, complete these steps:

### 1. Framework Integration
- Use begin/process/end blocks
- Implement Write-Log function with timestamp and level
- Add Set-NinjaProperty and Get-NinjaProperty helper functions
- Set proper error action preferences
- Implement script exit code handling

### 2. Error Handling
- Wrap main logic in try-catch blocks
- Use Write-Log with appropriate levels (INFO, WARNING, ERROR, CRITICAL, ALERT)
- Implement proper exit codes (0 = success, 1 = error)
- Track script execution time

### 3. NinjaRMM Custom Fields
- Replace `Ninja-Property-Set` with `Set-NinjaProperty` wrapper
- Replace `Ninja-Property-Get` with `Get-NinjaProperty` wrapper
- Use parameterized custom field names
- Support environment variable overrides
- Implement validation and error handling
- Add field documentation in header

### 4. Code Standards
- No checkmark/cross characters
- No emoji characters
- #Requires -Version 5.1 directive
- [CmdletBinding()] with proper parameters
- Comprehensive comment-based help
- Version tracking in header (3.0.0 for V3)
- Proper parameter documentation

### 5. Testing Checklist
- [ ] Script runs without errors
- [ ] Custom fields update correctly
- [ ] Error handling works properly
- [ ] Logging is functional and informative
- [ ] Original functionality preserved
- [ ] Exit codes work correctly
- [ ] Parameters work with defaults and overrides

---

## Completed Migrations

### Sprint 1: Security Scripts (In Progress - 4/7 complete)

1. **SecurityAnalyzer.ps1** - Migrated 2026-02-11
   - Location: `scripts/Security/SecurityAnalyzer.ps1`
   - Commit: [75f7316d](https://github.com/Xore/waf/commit/75f7316da83f595d70cd5c10700ae56110dd646d)
   - Custom Fields: OPSSecurityScore, OPSLastScoreUpdate
   - Features: Comprehensive security posture scoring (AV, firewall, BitLocker, SMBv1, patches)
   - Score Range: 0-100 with weighted deductions

2. **SecurityPostureConsolidator.ps1** - Migrated 2026-02-11
   - Location: `scripts/Security/SecurityPostureConsolidator.ps1`
   - Commit: [ad9f58b9](https://github.com/Xore/waf/commit/ad9f58b9a1932cdba9bc121be26aea460fd93e8c)
   - Custom Fields Written: secSecurityPostureScore, secFailedLogonCount24h, secAccountLockouts24h
   - Custom Fields Read: secAntivirusInstalled, secAntivirusEnabled, secAntivirusUpToDate, secFirewallEnabled, secBitLockerEnabled
   - Features: Aggregates security controls, monitors authentication (failed logons, lockouts)
   - Integration: Reads from other security scripts, adds real-time auth monitoring

3. **SuspiciousLoginPatternDetector.ps1** - Migrated 2026-02-11
   - Location: `scripts/Security/SuspiciousLoginPatternDetector.ps1`
   - Commit: [177e65ea](https://github.com/Xore/waf/commit/177e65eaad8fba2a0dbcc59ee0da0f9cf1fa4ef1)
   - Custom Fields: secSuspiciousLoginScore
   - Features: Behavioral analytics for authentication patterns, 4-hour rolling window
   - Indicators: Failed logons (20pts), Off-hours activity (15pts), Account lockouts (25pts), Privilege escalation (10pts)
   - Parameterized: Time window, all thresholds configurable
   - Threat Levels: Normal (0-25), Low (26-49), Medium (50-75), High (76-100)

4. **SecuritySurfaceTelemetry.ps1** - Migrated 2026-02-11
   - Location: `scripts/Security/SecuritySurfaceTelemetry.ps1`
   - Commit: [08b767d9](https://github.com/Xore/waf/commit/08b767d929b5c12cb9ad12bc6ee360aa279a2261)
   - Custom Fields: secInternetExposedPortsCount, secHighRiskServicesExposed, secSoonExpiringCertsCount, secSecuritySurfaceSummaryHtml
   - Features: Attack surface analysis, high-risk port detection, certificate expiration monitoring
   - High-Risk Ports: FTP(21), Telnet(23), RPC(135), NetBIOS(139), SMB(445), SQL(1433), RDP(3389), VNC(5900)
   - Output: HTML-formatted summary with color-coded risk indicators
   - Parameterized: Certificate expiration threshold (default 30 days)

---

## Consolidation Opportunities

Several scripts have multiple versions that should be reviewed and consolidated:

| Script Type | Versions | Action Needed |
|-------------|----------|---------------|
| DNS Server Monitor | 3 versions | Review and consolidate to single best version |
| MySQL Server Monitor | 3 versions | Review and consolidate to single best version |
| File Server Monitor | 3 versions | Review and consolidate to single best version |
| Print Server Monitor | 3 versions | Review and consolidate to single best version |
| FlexLM License Monitor | 3 versions | Review and consolidate to single best version |
| Event Log Monitor | 2 versions | Review and consolidate to single best version |
| BitLocker Monitor | 2 versions | Review and consolidate to single best version |
| Battery Health Monitor | 2 versions | Review and consolidate to single best version |
| Hyper-V Host Monitor | 2 versions | Review and consolidate to single best version |

**Total duplicates:** 24 scripts can potentially be consolidated into 9 unified scripts.

---

## Migration Workflow

1. **Select script** from priority order
2. **Review functionality** - understand what the script does
3. **Check for duplicates** - if multiple versions exist, compare them
4. **Migrate to V3** - apply framework integration and standards
5. **Test thoroughly** - verify all functionality
6. **Update this document** - mark script as complete
7. **Commit changes** - with descriptive message

---

## Progress Tracking

### Current Sprint (In Progress - 4/12 complete)
- [x] SecurityAnalyzer.ps1
- [x] SecurityPostureConsolidator.ps1
- [x] SuspiciousLoginPatternDetector.ps1
- [x] SecuritySurfaceTelemetry.ps1
- [ ] AdvancedThreatTelemetry.ps1 (next)
- [ ] EndpointDetectionResponse.ps1
- [ ] ComplianceAttestationReporter.ps1
- [ ] Priority validators (P1, P2, P3P4)
- [ ] Patch ring scripts (PR1, PR2)

### Next Sprint
- [ ] Health monitoring (HealthScoreCalculator, StabilityAnalyzer)
- [ ] Core monitoring (15-25)

### Future Sprints
- [ ] Server monitors (26-41)
- [ ] Service monitors (42-54)
- [ ] Hyper-V suite (55-64)
- [ ] Remaining scripts (65-70)

---

## Reference

- **Original move commit:** [79a9dc02](https://github.com/Xore/waf/commit/79a9dc02a17ce5e2d4b160ca66968d4defc0ab91)
- **Rename commit:** [1c4223f2](https://github.com/Xore/waf/commit/1c4223f2f1b67b809601b6fb495ad6f8d05ad789)
- **Scripts location:** `plaintext_scripts/` (source), `scripts/` (migrated)
- **Total scripts:** 76 (70 unique after consolidation)
- **V3 Standard Version:** 3.0.0
