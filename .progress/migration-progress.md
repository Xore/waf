# Script Migration Progress

**Last Updated:** February 11, 2026  
**Purpose:** Track migration of scripts from plaintext_scripts to NinjaRMM format

## Migration Status

**Total Scripts in plaintext_scripts:** ~250+  
**Migrated to NinjaRMM format:** 1  
**Completion:** <1%

## Recently Completed Migrations

### RegistryManagement-SetValue.ps1
- **Status:** ✅ Migrated
- **Date:** February 11, 2026
- **Location:** `ninjarmm_scripts/Registry/RegistryManagement-SetValue.ps1`
- **Compliance:** Fully compliant with WAF standards

## Next Scripts to Migrate

Priority scripts needing migration (alphabetical by category):

### Active Directory (AD)
1. AD-DomainControllerHealthReport.ps1
2. AD-GetOUMembers.ps1
3. AD-GetOrganizationalUnit.ps1
4. AD-JoinComputerToDomain.ps1
5. AD-JoinDomain.ps1
6. AD-LockedOutUserReport.ps1
7. AD-ModifyUserGroupMembership.ps1
8. AD-Monitor.ps1
9. AD-RemoveComputerFromDomain.ps1
10. AD-RepairTrust.ps1
11. AD-ReplicationHealthReport.ps1
12. AD-UserGroupMembershipReport.ps1
13. AD-UserLoginHistoryReport.ps1
14. AD-UserLogonHistory.ps1

### Browser
1. Browser-ListExtensions.ps1

### Certificates
1. Certificates-GetExpiring.ps1
2. Certificates-LocalExpirationAlert.ps1

### DHCP
1. DHCP-AlertOnLeaseLow.ps1
2. DHCP-FindRogueServersNmap.ps1

### Device
1. Device-UpdateLocation.ps1

### Disk
1. Disk-GetSMARTStatus.ps1

### EventLog
1. EventLog-BackupToLocalDisk.ps1
2. EventLog-Optimize.ps1
3. EventLog-Search.ps1

### Explorer
1. Explorer-SetDefaultFiletypeAssociations.ps1
2. Explorer-SetShowHiddenFiles.ps1

### FileOps
1. FileOps-CopyFileToAllDesktops.ps1
2. FileOps-CopyFileToFolder.ps1
3. FileOps-CopyFolderRobocopy.ps1
4. FileOps-DeleteFileOrFolder.ps1
5. FileOps-DownloadFromURL.ps1

### Firewall
1. Firewall-AuditStatus.ps1
2. Firewall-AuditStatus2.ps1

### GPO
1. GPO-Monitor.ps1
2. GPO-UpdateAndReport.ps1

### Hardware
1. Hardware-CheckBatteryHealth.ps1
2. Hardware-GetAttachedMonitors.ps1
3. Hardware-GetCPUTemp.ps1
4. Hardware-GetDellDockInfo.ps1
5. Hardware-SSDWearHealthAlert.ps1
6. Hardware-USBDriveAlert.ps1

### HyperV
1. HyperV-CheckpointExpirationAlert.ps1
2. HyperV-GetHostFromGuest.ps1
3. HyperV-ReplicationAlert.ps1

### IIS
1. IIS-GetBindings.ps1
2. IIS-RestartAppPool.ps1
3. IIS-RestartApplicationPool.ps1
4. IIS-RestartSite.ps1

### Licensing
1. Licensing-UnlicensedWindowsAlert.ps1

### LocalAdmin
1. LocalAdmin-CheckForUnknown.ps1
2. LocalAdmin-Monitor.ps1

### Monitoring
1. Monitoring-CapacityTrendForecaster.ps1
2. Monitoring-DeviceUptimePercentage.ps1
3. Monitoring-FileModificationAlert.ps1
4. Monitoring-HostFileChangedAlert.ps1
5. Monitoring-NTPTimeDifference.ps1
6. Monitoring-SystemPerformanceCheck.ps1
7. Monitoring-TelemetryCollector.ps1

### Network
1. Network-AlertWiredSub1Gbps.ps1
2. Network-CheckAndDisableSMBv1.ps1
3. Network-ClearDNSCache.ps1
4. Network-GetLLDPInfo.ps1
5. Network-GetPublicIP.ps1
6. Network-InternetSpeedTest.ps1
7. Network-MapDrives.ps1
8. Network-MountMyPLMasZ.ps1
9. Network-RestrictIPv4IGMP.ps1
10. Network-SearchDNSCache.ps1
11. Network-SearchListeningPorts.ps1
12. Network-SearchTCPUDPConnections.ps1
13. Network-SetDNSServerAddress.ps1
14. Network-SetLLMNR.ps1
15. Network-SetNetBios.ps1
16. Network-TestConnectivity.ps1

### NinjaRMM
1. NinjaRMM-STATFieldValidator.ps1
2. NinjaRMM-SaveHardDriveType.ps1
3. NinjaRMM-UpdateDeviceDescription.ps1
4. NinjaRMM-UpdateLocationGeoIP.ps1

### Notifications
1. Notifications-DisplayToastMessage.ps1

### Office/Office365
1. Office-GetVersion.ps1
2. Office365-ModernAuthAlert.ps1

### OneDrive
1. OneDrive-CopyFileToDesktop.ps1
2. OneDrive-GetConfig.ps1

### Outlook
1. Outlook-ReportLargeOSTandPST.ps1
2. Outlook-SetForcedMigration.ps1

### Power
1. Power-ActivePlanReport.ps1
2. Power-SetFastStartup.ps1
3. PowerManagement-SetPlan.ps1

### Printer
1. PrinterManagement-AddNetworkPrinter.ps1
2. Printing-TroubleshootAndClearQueue.ps1

### Process
1. Process-CloseAllOfficeApps.ps1
2. Process-CloseSAPandChrome.ps1

### RDP
1. RDP-CheckStatusAndPort.ps1
2. RDP-SetRemoteDesktop.ps1

### Security
1. Security-AuditUACLevel.ps1
2. Security-CheckBruteForceAttempts.ps1
3. Security-CheckFirewallStatus.ps1
4. Security-CredentialGuardStatus.ps1
5. Security-DetectInstalledAntivirus.ps1
6. Security-DisableWeakTLSandSSL.ps1
7. Security-LocalAdminsReport.ps1
8. Security-SecureBootComplianceReport.ps1
9. Security-SetAutorunAndAutoplay.ps1
10. Security-SetLMCompatibilityLevel.ps1
11. Security-SetLMHashStorage.ps1
12. Security-SetSmartScreen.ps1
13. Security-SetUACSettings.ps1
14. Security-SetWindows10KeyLogger.ps1
15. Security-UnencryptedDiskAlert.ps1
16. Security-UnsignedDriverAlert.ps1
17. Security-VerifyRunningProcessesSigned.ps1

### Services
1. ServiceManagement-RestartService.ps1
2. Services-CheckStoppedAutomatic.ps1
3. Services-RestartService.ps1

### Shortcuts
1. Shortcuts-CreateDesktopEXE.ps1
2. Shortcuts-CreateDesktopRDP.ps1
3. Shortcuts-CreateDesktopURL.ps1

### Software
1. Software-InstallAndRunBGInfo.ps1
2. Software-InstallDellCommandUpdate.ps1
3. Software-InstallNetFramework35.ps1
4. Software-InstallOffice365.ps1
5. Software-InstallSysmon.ps1
6. Software-InstallWindowsStoreApp.ps1
7. Software-ListInstalledApplications.ps1
8. Software-RemoveCCMClient.ps1
9. Software-RemoveMicrosoftBloatware.ps1
10. Software-UninstallApplication.ps1
11. Software-UninstallDellSupportAssist.ps1
12. Software-UninstallPuTTY.ps1
13. Software-UninstallWindowsDefender.ps1
14. Software-UpdatePowerShell51.ps1

### SQL
1. SQL-CollectMSSQLInstances.ps1
2. SQL-MonitorServer.ps1

### System
1. System-BlueScreenAlert.ps1
2. System-ConfigureTimeSync.ps1
3. System-EnableMiniDumpsForBSOD.ps1
4. System-EnableMinidumps.ps1
5. System-GetDeviceDescription.ps1
6. System-GetEnrollmentStatus.ps1
7. System-RebuildSearchIndex.ps1

### Windows
1. Windows-SetNewsAndInterests.ps1
2. Windows-UpdateSystem.ps1

## Migration Strategy

1. **One script at a time** - Each script is fully migrated, tested, and documented before moving to the next
2. **Category-based** - Complete entire categories when possible for consistency
3. **Priority order** - Focus on most-used and critical scripts first
4. **Quality over speed** - Ensure all WAF standards are met for each script

## Notes

- All migrated scripts must follow WAF standards (no emojis, no checkmarks/crosses)
- Each migrated script gets its own commit
- Progress is tracked in this file after each migration
- Some scripts may require consolidation or splitting based on functionality
