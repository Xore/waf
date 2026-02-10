@echo off
REM Batch file to rename scripts from asdf commit to streamlined names
REM This prepares scripts for V3 migration
REM Run from the plaintext_scripts directory

echo Starting file rename for V3 migration...
echo.

REM Health and Monitoring Scripts (01-32)
ren "01_Health_Score_Calculator.ps1" "HealthScoreCalculator.ps1"
ren "02_Stability_Analyzer.ps1" "StabilityAnalyzer.ps1"
ren "03_DNS_Server_Monitor.ps1" "DNSServerMonitor_v1.ps1"
ren "03_Performance_Analyzer.ps1" "PerformanceAnalyzer.ps1"
ren "04_Event_Log_Monitor.ps1" "EventLogMonitor_v1.ps1"
ren "04_Security_Analyzer.ps1" "SecurityAnalyzer.ps1"
ren "05_Capacity_Analyzer.ps1" "CapacityAnalyzer.ps1"
ren "05_File_Server_Monitor.ps1" "FileServerMonitor_v1.ps1"
ren "06_Print_Server_Monitor.ps1" "PrintServerMonitor_v1.ps1"
ren "06_Telemetry_Collector.ps1" "TelemetryCollector.ps1"
ren "07_BitLocker_Monitor.ps1" "BitLockerMonitor_v1.ps1"
ren "08_HyperV_Host_Monitor.ps1" "HyperVHostMonitor_v1.ps1"
ren "09_Risk_Classifier.ps1" "RiskClassifier.ps1"
ren "10_Update_Assessment_Collector.ps1" "UpdateAssessmentCollector.ps1"
ren "11_MySQL_Server_Monitor.ps1" "MySQLServerMonitor_v1.ps1"
ren "11_Network_Location_Tracker.ps1" "NetworkLocationTracker.ps1"
ren "12_Baseline_Manager.ps1" "BaselineManager.ps1"
ren "12_FlexLM_License_Monitor.ps1" "FlexLMLicenseMonitor_v1.ps1"
ren "13_Drift_Detector.ps1" "DriftDetector.ps1"
ren "14_DNS_Server_Monitor.ps1" "DNSServerMonitor_v2.ps1"
ren "14_Local_Admin_Drift_Analyzer.ps1" "LocalAdminDriftAnalyzer.ps1"
ren "15_File_Server_Monitor.ps1" "FileServerMonitor_v2.ps1"
ren "15_Security_Posture_Consolidator.ps1" "SecurityPostureConsolidator.ps1"
ren "16_Print_Server_Monitor.ps1" "PrintServerMonitor_v2.ps1"
ren "16_Suspicious_Login_Pattern_Detector.ps1" "SuspiciousLoginPatternDetector.ps1"
ren "17_Application_Experience_Profiler.ps1" "ApplicationExperienceProfiler.ps1"
ren "17_BitLocker_Monitor.ps1" "BitLockerMonitor_v2.ps1"
ren "18_HyperV_Host_Monitor.ps1" "HyperVHostMonitor_v2.ps1"
ren "18_Profile_Hygiene_Cleanup_Advisor.ps1" "ProfileHygieneCleanupAdvisor.ps1"
ren "19_MySQL_Server_Monitor.ps1" "MySQLServerMonitor_v2.ps1"
ren "19_Proactive_Remediation_Engine.ps1" "ProactiveRemediationEngine.ps1"
ren "20_FlexLM_License_Monitor.ps1" "FlexLMLicenseMonitor_v2.ps1"
ren "20_Server_Role_Identifier.ps1" "ServerRoleIdentifier.ps1"
ren "21_Battery_Health_Monitor.ps1" "BatteryHealthMonitor.ps1"
ren "28_Security_Surface_Telemetry.ps1" "SecuritySurfaceTelemetry.ps1"
ren "29_Collaboration_Outlook_UX_Telemetry.ps1" "CollaborationOutlookUXTelemetry.ps1"
ren "30_Advanced_Threat_Telemetry.ps1" "AdvancedThreatTelemetry.ps1"
ren "31_Endpoint_Detection_Response.ps1" "EndpointDetectionResponse.ps1"
ren "32_Compliance_Attestation_Reporter.ps1" "ComplianceAttestationReporter.ps1"

REM Remediation Scripts (41-50)
ren "41_Restart_Print_Spooler.ps1" "RestartPrintSpooler.ps1"
ren "42_Restart_Windows_Update.ps1" "RestartWindowsUpdate.ps1"
ren "50_Emergency_Disk_Cleanup.ps1" "EmergencyDiskCleanup.ps1"

REM Hyper-V Scripts
ren "Hyper-V Backup and Compliance Monitor 6.ps1" "HyperVBackupComplianceMonitor.ps1"
ren "Hyper-V Capacity Planner 4.ps1" "HyperVCapacityPlanner.ps1"
ren "Hyper-V Cluster Analytics 5.ps1" "HyperVClusterAnalytics.ps1"
ren "Hyper-V Health Check 2.ps1" "HyperVHealthCheck.ps1"
ren "Hyper-V Monitor 1.ps1" "HyperVMonitor.ps1"
ren "Hyper-V Multi-Host Aggregator 8.ps1" "HyperVMultiHostAggregator.ps1"
ren "Hyper-V Performance Monitor 3.ps1" "HyperVPerformanceMonitor.ps1"
ren "Hyper-V Storage Performance Monitor 7.ps1" "HyperVStoragePerformanceMonitor.ps1"

REM Priority and Patch Ring Scripts
ren "P1_Critical_Device_Validator.ps1" "P1CriticalDeviceValidator.ps1"
ren "P2_High_Priority_Validator.ps1" "P2HighPriorityValidator.ps1"
ren "P3_P4_Medium_Low_Validator.ps1" "P3P4MediumLowValidator.ps1"
ren "PR1_Patch_Ring1_Deployment.ps1" "PR1PatchRing1Deployment.ps1"
ren "PR2_Patch_Ring2_Deployment.ps1" "PR2PatchRing2Deployment.ps1"

REM Server Monitor Scripts
ren "Script_01_Apache_Web_Server_Monitor.ps1" "ApacheWebServerMonitor.ps1"
ren "Script_02_DHCP_Server_Monitor.ps1" "DHCPServerMonitor.ps1"
ren "Script_03_DNS_Server_Monitor.ps1" "DNSServerMonitor_v3.ps1"
ren "Script_37_IIS_Web_Server_Monitor.ps1" "IISWebServerMonitor.ps1"
ren "Script_38_MSSQL_Server_Monitor.ps1" "MSSQLServerMonitor.ps1"
ren "Script_39_MySQL_Server_Monitor.ps1" "MySQLServerMonitor_v3.ps1"
ren "Script_40_Network_Monitor.ps1" "NetworkMonitor.ps1"
ren "Script_41_Battery_Health_Monitor.ps1" "BatteryHealthMonitor_v2.ps1"
ren "Script_42_Active_Directory_Monitor.ps1" "ActiveDirectoryMonitor.ps1"
ren "Script_43_Group_Policy_Monitor.ps1" "GroupPolicyMonitor.ps1"
ren "Script_44_Event_Log_Monitor.ps1" "EventLogMonitor_v2.ps1"
ren "Script_45_File_Server_Monitor.ps1" "FileServerMonitor_v3.ps1"
ren "Script_46_Print_Server_Monitor.ps1" "PrintServerMonitor_v3.ps1"
ren "Script_47_FlexLM_License_Monitor.ps1" "FlexLMLicenseMonitor_v3.ps1"
ren "Script_48_Veeam_Backup_Monitor.ps1" "VeeamBackupMonitor.ps1"

echo.
echo Rename complete. 76 files renamed for V3 migration.
echo Files are now ready for V3 migration process.
echo.
echo Next steps:
echo 1. Review renamed files
echo 2. Begin V3 migration starting with high-priority scripts
echo 3. Update V3_MIGRATION_TRACKING.md as you progress
echo.
pause
