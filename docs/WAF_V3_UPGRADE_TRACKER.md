# Windows Automation Framework (WAF) V3.0.0 Upgrade Tracker

**Project:** Windows Automation Framework  
**Target:** Upgrade all scripts to V3.0.0 standards  
**Last Updated:** February 10, 2026, 10:49 PM CET

## Progress Overview

- **Total Scripts:** 219
- **Completed:** 89 (40.6%)
- **Remaining:** 130 (59.4%)

## V3.0.0 Compliance Checklist

Each script must meet these requirements:

- [ ] Uses `$script:ExitCode` (not `$ExitCode` or direct exit calls)
- [ ] Has `Write-Log` function (no `Write-Host`, `Write-Error`, or `Write-Warning`)
- [ ] Has `Set-NinjaField` function with CLI fallback
- [ ] Has error and warning counters (`$script:ErrorCount`, `$script:WarningCount`)
- [ ] Has execution summary block in `end {}`
- [ ] Has proper `try-catch-finally` structure
- [ ] Has `Set-StrictMode -Version Latest`
- [ ] Has comprehensive comment-based help documentation
- [ ] Has `begin`, `process`, `end` blocks (when appropriate)
- [ ] Has garbage collection in finally block
- [ ] No checkmarks/crosses/emojis in output
- [ ] All output is plain text via `Write-Output`

## Completed Scripts (89)

### Tonight's Session - Feb 10, 2026 (14 scripts)

#### Network (5)
- [x] Network-AlertWiredSub1Gbps.ps1
- [x] Network-GetLLDPInfo.ps1
- [x] Network-MountMyPLMasZ.ps1
- [x] Network-RestrictIPv4IGMP.ps1
- [x] Network-SetLLMNR.ps1

#### Security (6)
- [x] Security-CheckBruteForceAttempts.ps1
- [x] Security-CheckFirewallStatus.ps1
- [x] Security-CredentialGuardStatus.ps1
- [x] Security-DisableWeakTLSandSSL.ps1
- [x] Security-UnencryptedDiskAlert.ps1
- [x] Security-SetLMHashStorage.ps1

#### System (3)
- [x] System-BlueScreenAlert.ps1
- [x] System-EnableMinidumps.ps1
- [x] System-LastRebootReason.ps1

### Previous Sessions (75 scripts)

- [x] AD-DomainControllerHealthReport.ps1
- [x] BDE-StartSAPandBrowser.ps1
- [x] Browser-ListExtensions.ps1
- [x] Certificates-LocalExpirationAlert.ps1
- [x] Cepros-FixCdbpcIniPermissions.ps1
- [x] Cepros-UpdateCDBServerURL.ps1
- [x] DHCP-AlertOnLeaseLow.ps1
- [x] Disk-GetSMARTStatus.ps1
- [x] Entra-Audit.ps1
- [x] EventLog-Search.ps1
- [x] Exchange-VersionCheck.ps1
- [x] Explorer-SetDefaultFiletypeAssociations.ps1
- [x] Explorer-SetShowHiddenFiles.ps1
- [x] Firewall-AuditStatus2.ps1
- [x] GPO-UpdateAndReport.ps1
- [x] Hardware-CheckBatteryHealth.ps1
- [x] Hardware-GetAttachedMonitors.ps1
- [x] Hardware-GetCPUTemp.ps1
- [x] Hardware-SSDWearHealthAlert.ps1
- [x] Hardware-USBDriveAlert.ps1
- [x] HyperV-GetHostFromGuest.ps1
- [x] IIS-GetBindings.ps1
- [x] IIS-RestartAppPool.ps1
- [x] IIS-RestartSite.ps1
- [x] LocalAdmin-CheckForUnknown.ps1
- [x] LocalAdmin-Monitor.ps1
- [x] Logon-GetLastLoggedOnUser.ps1
- [x] LSASS-RunningProtectionCheck.ps1
- [x] MalwareBytes-UpdateDefinitions.ps1
- [x] Monitoring-CapacityTrendForecaster.ps1
- [x] Monitoring-DeviceUptimePercentage.ps1
- [x] Monitoring-SystemPerformanceCheck.ps1
- [x] Network-CheckAndDisableSMBv1.ps1
- [x] Network-SearchDNSCache.ps1
- [x] Network-SetDNSServerAddress.ps1
- [x] Network-TestConnectivity.ps1
- [x] NinjaRMM-UpdateDeviceDescription.ps1
- [x] Office-GetVersion.ps1
- [x] Office365-ModernAuthAlert.ps1
- [x] OneDrive-CopyFileToDesktop.ps1
- [x] Outlook-SetForcedMigration.ps1
- [x] RDP-CheckStatusAndPort.ps1
- [x] RDP-SetRemoteDesktop.ps1
- [x] RegistryManagement-SetValue.ps1
- [x] Security-SetLMCompatibilityLevel.ps1
- [x] Security-SetSmartScreen.ps1
- [x] ServiceManagement-RestartService.ps1
- [x] Services-RestartService.ps1
- [x] Shortcuts-CreateDesktopEXE.ps1
- [x] Software-InstallAndRunBGInfo.ps1
- [x] Software-InstallNetFramework35.ps1
- [x] Software-InstallOffice365.ps1
- [x] Software-InstallSiemensNX.ps1
- [x] Software-InstallSysmon.ps1
- [x] Software-UninstallApplication.ps1
- [x] Software-UninstallSiemensNX2412.ps1
- [x] System-RebuildSearchIndex.ps1
- [x] System-ShutdownComputer.ps1
- [x] User-GetLoggedOnUsers.ps1
- [x] VPN-InstallAzureVPNAppPackage.ps1
- [x] Windows-GetActivationStatus.ps1

_(Additional 15 scripts from previous sessions not fully listed here - see commit history)_

## Scripts Requiring Upgrade (130)

### AD - Active Directory (10 remaining)
- [ ] AD-GetOUMembers.ps1
- [ ] AD-GetOrganizationalUnit.ps1
- [ ] AD-JoinComputerToDomain.ps1
- [ ] AD-JoinDomain.ps1
- [ ] AD-LockedOutUserReport.ps1
- [ ] AD-ModifyUserGroupMembership.ps1
- [ ] AD-Monitor.ps1
- [ ] AD-RemoveComputerFromDomain.ps1
- [ ] AD-RepairTrust.ps1
- [ ] AD-ReplicationHealthReport.ps1
- [ ] AD-UserGroupMembershipReport.ps1
- [ ] AD-UserLoginHistoryReport.ps1
- [ ] AD-UserLogonHistory.ps1

### Certificates (1 remaining)
- [ ] Certificates-GetExpiring.ps1

### DHCP (1 remaining)
- [ ] DHCP-FindRogueServersNmap.ps1

### Device (1 remaining)
- [ ] Device-UpdateLocation.ps1

### Diamod (1 remaining)
- [ ] Diamod-ReregisterServerFixPermissions.ps1

### EventLog (2 remaining)
- [ ] EventLog-BackupToLocalDisk.ps1
- [ ] EventLog-Optimize.ps1

### FileOps (5 remaining)
- [ ] FileOps-CopyFileToAllDesktops.ps1
- [ ] FileOps-CopyFileToFolder.ps1
- [ ] FileOps-CopyFolderRobocopy.ps1
- [ ] FileOps-DeleteFileOrFolder.ps1
- [ ] FileOps-DownloadFromURL.ps1

### Firewall (1 remaining)
- [ ] Firewall-AuditStatus.ps1

### GPO (1 remaining)
- [ ] GPO-Monitor.ps1

### Hardware (1 remaining)
- [ ] Hardware-GetDellDockInfo.ps1

### HyperV (2 remaining)
- [ ] HyperV-CheckpointExpirationAlert.ps1
- [ ] HyperV-ReplicationAlert.ps1

### IIS (1 remaining)
- [ ] IIS-RestartApplicationPool.ps1

### Licensing (1 remaining)
- [ ] Licensing-UnlicensedWindowsAlert.ps1

### Monitoring (3 remaining)
- [ ] Monitoring-FileModificationAlert.ps1
- [ ] Monitoring-HostFileChangedAlert.ps1
- [ ] Monitoring-NTPTimeDifference.ps1
- [ ] Monitoring-TelemetryCollector.ps1

### Network (7 remaining)
- [ ] Network-ClearDNSCache.ps1
- [ ] Network-GetPublicIP.ps1
- [ ] Network-InternetSpeedTest.ps1
- [ ] Network-MapDrives.ps1
- [ ] Network-SearchListeningPorts.ps1
- [ ] Network-SearchTCPUDPConnections.ps1
- [ ] Network-SetNetBios.ps1

### NinjaRMM (3 remaining)
- [ ] NinjaRMM-STATFieldValidator.ps1
- [ ] NinjaRMM-SaveHardDriveType.ps1
- [ ] NinjaRMM-UpdateLocationGeoIP.ps1

### Notifications (1 remaining)
- [ ] Notifications-DisplayToastMessage.ps1

### OneDrive (1 remaining)
- [ ] OneDrive-GetConfig.ps1

### Outlook (1 remaining)
- [ ] Outlook-ReportLargeOSTandPST.ps1

### Power (2 remaining)
- [ ] Power-ActivePlanReport.ps1
- [ ] Power-SetFastStartup.ps1
- [ ] PowerManagement-SetPlan.ps1

### Printer (2 remaining)
- [ ] PrinterManagement-AddNetworkPrinter.ps1
- [ ] Printing-TroubleshootAndClearQueue.ps1

### Process (2 remaining)
- [ ] Process-CloseAllOfficeApps.ps1
- [ ] Process-CloseSAPandChrome.ps1

### SAP (3 remaining)
- [ ] SAP-DeleteUserProfiles.ps1
- [ ] SAP-DisableAutomaticUpdate.ps1
- [ ] SAP-PurgeSAPGUI.ps1

### SQL (2 remaining)
- [ ] SQL-CollectMSSQLInstances.ps1
- [ ] SQL-MonitorServer.ps1

### Security (7 remaining)
- [ ] Security-AuditUACLevel.ps1
- [ ] Security-DetectInstalledAntivirus.ps1
- [ ] Security-LocalAdminsReport.ps1
- [ ] Security-SecureBootComplianceReport.ps1
- [ ] Security-SetAutorunAndAutoplay.ps1
- [ ] Security-SetUACSettings.ps1
- [ ] Security-SetWindows10KeyLogger.ps1
- [ ] Security-UnsignedDriverAlert.ps1
- [ ] Security-VerifyRunningProcessesSigned.ps1

### Server (1 remaining)
- [ ] Server-GetRoles.ps1

### Services (1 remaining)
- [ ] Services-CheckStoppedAutomatic.ps1

### Shortcuts (5 remaining)
- [ ] Shortcuts-CreateCeprosShortcuts.ps1
- [ ] Shortcuts-CreateDesktopRDP.ps1
- [ ] Shortcuts-CreateDesktopURL.ps1
- [ ] Shortcuts-CreateGenericShortcut.ps1

### Software (13 remaining)
- [ ] Software-InstallCatiaBMW-R2024SP2HFX10.ps1
- [ ] Software-InstallCatiaBMW-R2024SP5.ps1
- [ ] Software-InstallDellCommandUpdate.ps1
- [ ] Software-InstallSiemensNX2.ps1
- [ ] Software-InstallWindowsStoreApp.ps1
- [ ] Software-ListInstalledApplications.ps1
- [ ] Software-RemoveCCMClient.ps1
- [ ] Software-RemoveMicrosoftBloatware.ps1
- [ ] Software-StartKistersSetup.ps1
- [ ] Software-TreesizeUltimate.ps1
- [ ] Software-UninstallCatiaBMW-R2024SP2.ps1
- [ ] Software-UninstallCatiaBMW-R2024SP5.ps1
- [ ] Software-UninstallDellSupportAssist.ps1
- [ ] Software-UninstallPuTTY.ps1
- [ ] Software-UninstallWindowsDefender.ps1
- [ ] Software-UpdatePowerShell51.ps1

### System (3 remaining)
- [ ] System-ConfigureTimeSync.ps1
- [ ] System-EnableMiniDumpsForBSOD.ps1
- [ ] System-GetDeviceDescription.ps1
- [ ] System-GetEnrollmentStatus.ps1
- [ ] System-LogOffUsers.ps1

### VPN (1 remaining)
- [ ] VPN-ImportAzureConfig.ps1

### Windows Update (1 remaining)
- [ ] WindowsUpdate-ListAllUpdates.ps1

---

## Upgrade Workflow

For each script, follow these steps:

1. **Check Compliance**: Review script against V3.0.0 checklist above
2. **Document Status**: Note which requirements are missing
3. **Upgrade Script**: Apply all missing requirements
4. **Test**: Verify script functions correctly
5. **Commit**: Use format "Upgrade [ScriptName] to v3.0.0 standards"
6. **Update Tracker**: Move script from "Requiring Upgrade" to "Completed"

## Notes

- WAF = **Windows Automation Framework** (Windows system management automation)
- All scripts in `plaintext_scripts/` directory
- Target completion: Upgrade all 219 scripts to V3.0.0 standards
- No emojis, checkmarks, or special characters in script output per space guidelines
- All output must be plain text for RMM system compatibility

## Session History

- **Feb 10, 2026 (Tonight)**: 14 scripts completed (Network 5, Security 6, System 3)
- **Previous Sessions**: 75 scripts completed across all categories
- **Total Progress**: 89/219 (40.6%)
