# V3 Migration Tracking - Scripts Requiring Migration

This document tracks the migration status of scripts that were moved into the `plaintext_scripts` folder (commit 79a9dc02) and need V3 migration to use NinjaRMM custom fields and WAF framework.

## Migration Status

**Total Scripts to Migrate:** 76
**Migrated:** 0
**In Progress:** 0
**Pending:** 76

---

## Scripts Requiring V3 Migration

### Health & Monitoring Scripts (01-32)
- [ ] 01_Health_Score_Calculator.ps1
- [ ] 02_Stability_Analyzer.ps1
- [ ] 03_DNS_Server_Monitor.ps1
- [ ] 03_Performance_Analyzer.ps1
- [ ] 04_Event_Log_Monitor.ps1
- [ ] 04_Security_Analyzer.ps1
- [ ] 05_Capacity_Analyzer.ps1
- [ ] 05_File_Server_Monitor.ps1
- [ ] 06_Print_Server_Monitor.ps1
- [ ] 06_Telemetry_Collector.ps1
- [ ] 07_BitLocker_Monitor.ps1
- [ ] 08_HyperV_Host_Monitor.ps1
- [ ] 09_Risk_Classifier.ps1
- [ ] 10_Update_Assessment_Collector.ps1
- [ ] 11_MySQL_Server_Monitor.ps1
- [ ] 11_Network_Location_Tracker.ps1
- [ ] 12_Baseline_Manager.ps1
- [ ] 12_FlexLM_License_Monitor.ps1
- [ ] 13_Drift_Detector.ps1
- [ ] 14_DNS_Server_Monitor.ps1
- [ ] 14_Local_Admin_Drift_Analyzer.ps1
- [ ] 15_File_Server_Monitor.ps1
- [ ] 15_Security_Posture_Consolidator.ps1
- [ ] 16_Print_Server_Monitor.ps1
- [ ] 16_Suspicious_Login_Pattern_Detector.ps1
- [ ] 17_Application_Experience_Profiler.ps1
- [ ] 17_BitLocker_Monitor.ps1
- [ ] 18_HyperV_Host_Monitor.ps1
- [ ] 18_Profile_Hygiene_Cleanup_Advisor.ps1
- [ ] 19_MySQL_Server_Monitor.ps1
- [ ] 19_Proactive_Remediation_Engine.ps1
- [ ] 20_FlexLM_License_Monitor.ps1
- [ ] 20_Server_Role_Identifier.ps1
- [ ] 21_Battery_Health_Monitor.ps1
- [ ] 28_Security_Surface_Telemetry.ps1
- [ ] 29_Collaboration_Outlook_UX_Telemetry.ps1
- [ ] 30_Advanced_Threat_Telemetry.ps1
- [ ] 31_Endpoint_Detection_Response.ps1
- [ ] 32_Compliance_Attestation_Reporter.ps1

### Remediation Scripts (41-50)
- [ ] 41_Restart_Print_Spooler.ps1
- [ ] 42_Restart_Windows_Update.ps1
- [ ] 50_Emergency_Disk_Cleanup.ps1

### Hyper-V Scripts
- [ ] Hyper-V Backup and Compliance Monitor 6.ps1
- [ ] Hyper-V Capacity Planner 4.ps1
- [ ] Hyper-V Cluster Analytics 5.ps1
- [ ] Hyper-V Health Check 2.ps1
- [ ] Hyper-V Monitor 1.ps1
- [ ] Hyper-V Multi-Host Aggregator 8.ps1
- [ ] Hyper-V Performance Monitor 3.ps1
- [ ] Hyper-V Storage Performance Monitor 7.ps1

### Priority & Patch Ring Scripts
- [ ] P1_Critical_Device_Validator.ps1
- [ ] P2_High_Priority_Validator.ps1
- [ ] P3_P4_Medium_Low_Validator.ps1
- [ ] PR1_Patch_Ring1_Deployment.ps1
- [ ] PR2_Patch_Ring2_Deployment.ps1

### Server Monitor Scripts (Script_ prefix)
- [ ] Script_01_Apache_Web_Server_Monitor.ps1
- [ ] Script_02_DHCP_Server_Monitor.ps1
- [ ] Script_03_DNS_Server_Monitor.ps1
- [ ] Script_37_IIS_Web_Server_Monitor.ps1
- [ ] Script_38_MSSQL_Server_Monitor.ps1
- [ ] Script_39_MySQL_Server_Monitor.ps1
- [ ] Script_40_Network_Monitor.ps1
- [ ] Script_41_Battery_Health_Monitor.ps1
- [ ] Script_42_Active_Directory_Monitor.ps1
- [ ] Script_43_Group_Policy_Monitor.ps1
- [ ] Script_44_Event_Log_Monitor.ps1
- [ ] Script_45_File_Server_Monitor.ps1
- [ ] Script_46_Print_Server_Monitor.ps1
- [ ] Script_47_FlexLM_License_Monitor.ps1
- [ ] Script_48_Veeam_Backup_Monitor.ps1

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
1. Security monitoring scripts (04, 15, 16, 28, 30, 31, 32)
2. Priority validators (P1, P2, P3_P4)
3. Patch ring scripts (PR1, PR2)
4. Health monitoring (01, 02)

### Medium Priority
1. Server monitors (Script_ prefix)
2. Hyper-V monitoring suite
3. Specific service monitors (DNS, DHCP, SQL, etc.)

### Lower Priority
1. Remediation scripts (41, 42, 50)
2. Reporting/analysis scripts

---

## Notes

- These 76 scripts were all moved from the `scripts/` folder to `plaintext_scripts/` in commit 79a9dc02
- All scripts are currently in plaintext format and need conversion to V3 standards
- Some scripts may have similar functionality and could be consolidated during migration
- The `archive/` folder contains documentation that was also moved in this commit

## Reference

- Original commit: https://github.com/Xore/waf/commit/79a9dc02a17ce5e2d4b160ca66968d4defc0ab91
- 76 script files renamed/moved to plaintext_scripts
- 6 documentation files moved to archive/docs/hyper-v monitoring/
