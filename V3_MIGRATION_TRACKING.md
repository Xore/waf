# V3 Migration Tracking - Scripts Requiring Migration

This document tracks the migration status of scripts that were moved into the `plaintext_scripts` folder (commit 79a9dc02) and need V3 migration to use NinjaRMM custom fields and WAF framework.

## Migration Status

**Total Scripts to Migrate:** 76
**Migrated:** 0
**In Progress:** 0
**Pending:** 76

---

## Pre-Migration Step: File Renaming

Before beginning V3 migration, run the batch file to rename all scripts to streamlined names:

```cmd
cd plaintext_scripts
rename_for_v3_migration.cmd
```

This will rename all 76 files from numbered/spaced names to clean PascalCase names.

---

## Scripts Requiring V3 Migration

### Health & Monitoring Scripts (39 scripts)

| Old Filename | New Filename | Status |
|--------------|--------------|--------|
| 01_Health_Score_Calculator.ps1 | HealthScoreCalculator.ps1 | [ ] |
| 02_Stability_Analyzer.ps1 | StabilityAnalyzer.ps1 | [ ] |
| 03_DNS_Server_Monitor.ps1 | DNSServerMonitor_v1.ps1 | [ ] |
| 03_Performance_Analyzer.ps1 | PerformanceAnalyzer.ps1 | [ ] |
| 04_Event_Log_Monitor.ps1 | EventLogMonitor_v1.ps1 | [ ] |
| 04_Security_Analyzer.ps1 | SecurityAnalyzer.ps1 | [ ] |
| 05_Capacity_Analyzer.ps1 | CapacityAnalyzer.ps1 | [ ] |
| 05_File_Server_Monitor.ps1 | FileServerMonitor_v1.ps1 | [ ] |
| 06_Print_Server_Monitor.ps1 | PrintServerMonitor_v1.ps1 | [ ] |
| 06_Telemetry_Collector.ps1 | TelemetryCollector.ps1 | [ ] |
| 07_BitLocker_Monitor.ps1 | BitLockerMonitor_v1.ps1 | [ ] |
| 08_HyperV_Host_Monitor.ps1 | HyperVHostMonitor_v1.ps1 | [ ] |
| 09_Risk_Classifier.ps1 | RiskClassifier.ps1 | [ ] |
| 10_Update_Assessment_Collector.ps1 | UpdateAssessmentCollector.ps1 | [ ] |
| 11_MySQL_Server_Monitor.ps1 | MySQLServerMonitor_v1.ps1 | [ ] |
| 11_Network_Location_Tracker.ps1 | NetworkLocationTracker.ps1 | [ ] |
| 12_Baseline_Manager.ps1 | BaselineManager.ps1 | [ ] |
| 12_FlexLM_License_Monitor.ps1 | FlexLMLicenseMonitor_v1.ps1 | [ ] |
| 13_Drift_Detector.ps1 | DriftDetector.ps1 | [ ] |
| 14_DNS_Server_Monitor.ps1 | DNSServerMonitor_v2.ps1 | [ ] |
| 14_Local_Admin_Drift_Analyzer.ps1 | LocalAdminDriftAnalyzer.ps1 | [ ] |
| 15_File_Server_Monitor.ps1 | FileServerMonitor_v2.ps1 | [ ] |
| 15_Security_Posture_Consolidator.ps1 | SecurityPostureConsolidator.ps1 | [ ] |
| 16_Print_Server_Monitor.ps1 | PrintServerMonitor_v2.ps1 | [ ] |
| 16_Suspicious_Login_Pattern_Detector.ps1 | SuspiciousLoginPatternDetector.ps1 | [ ] |
| 17_Application_Experience_Profiler.ps1 | ApplicationExperienceProfiler.ps1 | [ ] |
| 17_BitLocker_Monitor.ps1 | BitLockerMonitor_v2.ps1 | [ ] |
| 18_HyperV_Host_Monitor.ps1 | HyperVHostMonitor_v2.ps1 | [ ] |
| 18_Profile_Hygiene_Cleanup_Advisor.ps1 | ProfileHygieneCleanupAdvisor.ps1 | [ ] |
| 19_MySQL_Server_Monitor.ps1 | MySQLServerMonitor_v2.ps1 | [ ] |
| 19_Proactive_Remediation_Engine.ps1 | ProactiveRemediationEngine.ps1 | [ ] |
| 20_FlexLM_License_Monitor.ps1 | FlexLMLicenseMonitor_v2.ps1 | [ ] |
| 20_Server_Role_Identifier.ps1 | ServerRoleIdentifier.ps1 | [ ] |
| 21_Battery_Health_Monitor.ps1 | BatteryHealthMonitor.ps1 | [ ] |
| 28_Security_Surface_Telemetry.ps1 | SecuritySurfaceTelemetry.ps1 | [ ] |
| 29_Collaboration_Outlook_UX_Telemetry.ps1 | CollaborationOutlookUXTelemetry.ps1 | [ ] |
| 30_Advanced_Threat_Telemetry.ps1 | AdvancedThreatTelemetry.ps1 | [ ] |
| 31_Endpoint_Detection_Response.ps1 | EndpointDetectionResponse.ps1 | [ ] |
| 32_Compliance_Attestation_Reporter.ps1 | ComplianceAttestationReporter.ps1 | [ ] |

### Remediation Scripts (3 scripts)

| Old Filename | New Filename | Status |
|--------------|--------------|--------|
| 41_Restart_Print_Spooler.ps1 | RestartPrintSpooler.ps1 | [ ] |
| 42_Restart_Windows_Update.ps1 | RestartWindowsUpdate.ps1 | [ ] |
| 50_Emergency_Disk_Cleanup.ps1 | EmergencyDiskCleanup.ps1 | [ ] |

### Hyper-V Scripts (8 scripts)

| Old Filename | New Filename | Status |
|--------------|--------------|--------|
| Hyper-V Backup and Compliance Monitor 6.ps1 | HyperVBackupComplianceMonitor.ps1 | [ ] |
| Hyper-V Capacity Planner 4.ps1 | HyperVCapacityPlanner.ps1 | [ ] |
| Hyper-V Cluster Analytics 5.ps1 | HyperVClusterAnalytics.ps1 | [ ] |
| Hyper-V Health Check 2.ps1 | HyperVHealthCheck.ps1 | [ ] |
| Hyper-V Monitor 1.ps1 | HyperVMonitor.ps1 | [ ] |
| Hyper-V Multi-Host Aggregator 8.ps1 | HyperVMultiHostAggregator.ps1 | [ ] |
| Hyper-V Performance Monitor 3.ps1 | HyperVPerformanceMonitor.ps1 | [ ] |
| Hyper-V Storage Performance Monitor 7.ps1 | HyperVStoragePerformanceMonitor.ps1 | [ ] |

### Priority & Patch Ring Scripts (5 scripts)

| Old Filename | New Filename | Status |
|--------------|--------------|--------|
| P1_Critical_Device_Validator.ps1 | P1CriticalDeviceValidator.ps1 | [ ] |
| P2_High_Priority_Validator.ps1 | P2HighPriorityValidator.ps1 | [ ] |
| P3_P4_Medium_Low_Validator.ps1 | P3P4MediumLowValidator.ps1 | [ ] |
| PR1_Patch_Ring1_Deployment.ps1 | PR1PatchRing1Deployment.ps1 | [ ] |
| PR2_Patch_Ring2_Deployment.ps1 | PR2PatchRing2Deployment.ps1 | [ ] |

### Server Monitor Scripts (15 scripts)

| Old Filename | New Filename | Status |
|--------------|--------------|--------|
| Script_01_Apache_Web_Server_Monitor.ps1 | ApacheWebServerMonitor.ps1 | [ ] |
| Script_02_DHCP_Server_Monitor.ps1 | DHCPServerMonitor.ps1 | [ ] |
| Script_03_DNS_Server_Monitor.ps1 | DNSServerMonitor_v3.ps1 | [ ] |
| Script_37_IIS_Web_Server_Monitor.ps1 | IISWebServerMonitor.ps1 | [ ] |
| Script_38_MSSQL_Server_Monitor.ps1 | MSSQLServerMonitor.ps1 | [ ] |
| Script_39_MySQL_Server_Monitor.ps1 | MySQLServerMonitor_v3.ps1 | [ ] |
| Script_40_Network_Monitor.ps1 | NetworkMonitor.ps1 | [ ] |
| Script_41_Battery_Health_Monitor.ps1 | BatteryHealthMonitor_v2.ps1 | [ ] |
| Script_42_Active_Directory_Monitor.ps1 | ActiveDirectoryMonitor.ps1 | [ ] |
| Script_43_Group_Policy_Monitor.ps1 | GroupPolicyMonitor.ps1 | [ ] |
| Script_44_Event_Log_Monitor.ps1 | EventLogMonitor_v2.ps1 | [ ] |
| Script_45_File_Server_Monitor.ps1 | FileServerMonitor_v3.ps1 | [ ] |
| Script_46_Print_Server_Monitor.ps1 | PrintServerMonitor_v3.ps1 | [ ] |
| Script_47_FlexLM_License_Monitor.ps1 | FlexLMLicenseMonitor_v3.ps1 | [ ] |
| Script_48_Veeam_Backup_Monitor.ps1 | VeeamBackupMonitor.ps1 | [ ] |

---

## Migration Process

For each script, the V3 migration includes:

### 1. Framework Integration
- Add WAF module imports
- Implement proper error handling using WAF functions
- Add logging functionality

### 2. NinjaRMM Custom Fields
- Replace direct `Ninja-Property-Set` calls with proper custom field updates
- Use standardized field naming conventions
- Implement field validation

### 3. Code Standards
- Remove checkmark/cross characters
- Remove emoji characters  
- Follow PowerShell best practices
- Add proper documentation headers

### 4. Testing
- Verify functionality matches original script
- Test custom field updates
- Validate error handling

---

## Priority Order

### High Priority (Start Here)
1. **SecurityAnalyzer.ps1** - Core security monitoring
2. **SecurityPostureConsolidator.ps1** - Security posture consolidation
3. **SuspiciousLoginPatternDetector.ps1** - Login pattern detection
4. **SecuritySurfaceTelemetry.ps1** - Security surface telemetry
5. **AdvancedThreatTelemetry.ps1** - Threat telemetry
6. **EndpointDetectionResponse.ps1** - EDR functionality
7. **ComplianceAttestationReporter.ps1** - Compliance reporting
8. **P1CriticalDeviceValidator.ps1** - Priority 1 validation
9. **P2HighPriorityValidator.ps1** - Priority 2 validation
10. **P3P4MediumLowValidator.ps1** - Priority 3/4 validation
11. **PR1PatchRing1Deployment.ps1** - Patch ring 1
12. **PR2PatchRing2Deployment.ps1** - Patch ring 2
13. **HealthScoreCalculator.ps1** - Health scoring
14. **StabilityAnalyzer.ps1** - Stability analysis

### Medium Priority
1. Server monitors (Apache, DHCP, DNS, IIS, MSSQL, MySQL, Network)
2. Hyper-V monitoring suite (8 scripts)
3. Specific service monitors (DNS, File Server, Print Server, etc.)
4. Telemetry collectors

### Lower Priority
1. Remediation scripts (RestartPrintSpooler, RestartWindowsUpdate, EmergencyDiskCleanup)
2. Reporting/analysis scripts (Baseline, Drift, Risk)
3. Profile and application profilers

---

## Notes

- **Rename First**: Run `rename_for_v3_migration.cmd` before starting migration work
- These 76 scripts were all moved from the `scripts/` folder to `plaintext_scripts/` in commit 79a9dc02
- All scripts are currently in plaintext format and need conversion to V3 standards
- Some scripts have duplicate functionality (e.g., multiple DNS/MySQL monitors) and should be consolidated
- Version suffixes (_v1, _v2, _v3) indicate there are multiple versions that need review for consolidation

## Reference

- Original commit: https://github.com/Xore/waf/commit/79a9dc02a17ce5e2d4b160ca66968d4defc0ab91
- Rename batch file: `plaintext_scripts/rename_for_v3_migration.cmd`
- 76 script files to be renamed and migrated
- 6 documentation files moved to archive/docs/hyper-v monitoring/
