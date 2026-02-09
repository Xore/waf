# Script Index - Windows Automation Framework

## Quick Reference Index

Complete alphabetical listing of all scripts with descriptions and categories.

---

## Active Directory (AD) - 14 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| AD-DomainControllerHealthReport.ps1 | Comprehensive DC health monitoring | Monitor DC replication, services, and overall health |
| AD-GetOUMembers.ps1 | List members of specific OU | OU membership reporting |
| AD-GetOrganizationalUnit.ps1 | Enumerate OUs in domain | OU structure discovery |
| AD-JoinComputerToDomain.ps1 | Join computer to domain with validation | Automated domain join |
| AD-JoinDomain.ps1 | Simple domain join | Quick domain join |
| AD-LockedOutUserReport.ps1 | Report on locked user accounts | Security troubleshooting |
| AD-ModifyUserGroupMembership.ps1 | Add/remove users from groups | User access management |
| AD-Monitor.ps1 | General AD health monitoring | Proactive AD monitoring |
| AD-RemoveComputerFromDomain.ps1 | Remove computer from domain | Domain unjoin operations |
| AD-RepairTrust.ps1 | Repair computer trust relationship | Fix trust relationship issues |
| AD-ReplicationHealthReport.ps1 | AD replication health and status | Replication monitoring |
| AD-UserGroupMembershipReport.ps1 | Comprehensive user group report | Access auditing |
| AD-UserLoginHistoryReport.ps1 | User login history from DC | Security auditing |
| AD-UserLogonHistory.ps1 | Detailed logon history | Login tracking |

---

## Browser - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Browser-ListExtensions.ps1 | List all browser extensions (Chrome, Edge, Firefox) | Extension inventory and security audit |

---

## Business Desktop Environment (BDE) - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| BDE-StartSAPandBrowser.ps1 | Launch SAP GUI and browser together | Automated business app startup |

---

## Cepros Application - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Cepros-FixCdbpcIniPermissions.ps1 | Fix CDBPC.INI file permissions | Permission repair |
| Cepros-UpdateCDBServerURL.ps1 | Update Cepros database server URL | Server migration |

---

## Certificates - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Certificates-GetExpiring.ps1 | List certificates expiring soon | Proactive certificate management |
| Certificates-LocalExpirationAlert.ps1 | Alert on local certificate expiration | Certificate monitoring |

---

## DHCP - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| DHCP-AlertOnLeaseLow.ps1 | Alert when DHCP scope is low | DHCP capacity monitoring |
| DHCP-FindRogueServersNmap.ps1 | Detect unauthorized DHCP servers | Security scanning |

---

## Device Management - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Device-UpdateLocation.ps1 | Update device location field | Device tracking |

---

## Diamod Application - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Diamod-ReregisterServerFixPermissions.ps1 | Re-register Diamod server and fix permissions | Diamod troubleshooting |

---

## Entra (Azure AD) - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Entra-Audit.ps1 | Audit Entra ID (Azure AD) configuration | Cloud identity auditing |

---

## Event Logs - 3 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| EventLog-BackupToLocalDisk.ps1 | Backup event logs to local disk | Log archival |
| EventLog-Optimize.ps1 | Optimize event log configuration | Performance tuning |
| EventLog-Search.ps1 | Advanced event log searching | Troubleshooting and forensics |

---

## Exchange - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Exchange-VersionCheck.ps1 | Check Exchange Server version and patch level | Exchange health monitoring |

---

## File Explorer - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Explorer-SetDefaultFiletypeAssociations.ps1 | Configure default file type associations | Standard desktop configuration |
| Explorer-SetShowHiddenFiles.ps1 | Show/hide hidden files and folders | User preferences |

---

## File Operations (FileOps) - 5 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| FileOps-CopyFileToAllDesktops.ps1 | Copy file to all user desktops | File distribution |
| FileOps-CopyFileToFolder.ps1 | Copy file to specified folder | File deployment |
| FileOps-CopyFolderRobocopy.ps1 | Copy folder using robocopy | Robust folder copying |
| FileOps-DeleteFileOrFolder.ps1 | Delete file or folder | Cleanup operations |
| FileOps-DownloadFromURL.ps1 | Download file from URL | File acquisition |

---

## Firewall - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Firewall-AuditStatus.ps1 | Audit Windows Firewall status | Security compliance |
| Firewall-AuditStatus2.ps1 | Alternative firewall audit | Firewall monitoring |

---

## Group Policy (GPO) - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| GPO-Monitor.ps1 | Monitor GPO application status | GPO troubleshooting |
| GPO-UpdateAndReport.ps1 | Force GPO update and generate report | Policy enforcement |

---

## Hardware - 5 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Hardware-CheckBatteryHealth.ps1 | Comprehensive battery health report | Laptop battery monitoring |
| Hardware-GetAttachedMonitors.ps1 | List attached monitors | Hardware inventory |
| Hardware-GetDellDockInfo.ps1 | Get Dell docking station information | Dell dock troubleshooting |
| Hardware-SSDWearHealthAlert.ps1 | Alert on SSD wear level | SSD health monitoring |
| Hardware-USBDriveAlert.ps1 | Alert when USB drive connected | USB security monitoring |

---

## Hyper-V - 3 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| HyperV-CheckpointExpirationAlert.ps1 | Alert on old VM checkpoints | VM maintenance |
| HyperV-GetHostFromGuest.ps1 | Determine Hyper-V host from guest VM | VM-to-host mapping |
| HyperV-ReplicationAlert.ps1 | Monitor Hyper-V replication health | Replication monitoring |

---

## IIS - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| IIS-GetBindings.ps1 | List IIS site bindings | IIS configuration review |

---

## Licensing - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Licensing-UnlicensedWindowsAlert.ps1 | Alert on unlicensed Windows | License compliance |

---

## Monitoring - 7 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Monitoring-CapacityTrendForecaster.ps1 | Forecast resource exhaustion | Capacity planning |
| Monitoring-DeviceUptimePercentage.ps1 | Calculate device uptime percentage | Reliability tracking |
| Monitoring-FileModificationAlert.ps1 | Alert on file modifications | File integrity monitoring |
| Monitoring-HostFileChangedAlert.ps1 | Alert on hosts file changes | Security monitoring |
| Monitoring-NTPTimeDifference.ps1 | Check time sync accuracy | Time synchronization |
| Monitoring-SystemPerformanceCheck.ps1 | Comprehensive performance check | Performance monitoring |
| Monitoring-TelemetryCollector.ps1 | Collect custom telemetry data | Data collection |

---

## Network - 16 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Network-AlertWiredSub1Gbps.ps1 | Alert when wired speed below 1 Gbps | Network performance |
| Network-CheckAndDisableSMBv1.ps1 | Check for and disable SMBv1 | Security hardening |
| Network-ClearDNSCache.ps1 | Clear DNS resolver cache | DNS troubleshooting |
| Network-GetLLDPInfo.ps1 | Get LLDP neighbor information | Network topology |
| Network-InternetSpeedTest.ps1 | Run internet speed test | Bandwidth testing |
| Network-MapDrives.ps1 | Map network drives | Drive mapping |
| Network-MountMyPLMasZ.ps1 | Mount specific network share as Z: | Custom drive mapping |
| Network-RestrictIPv4IGMP.ps1 | Restrict IGMP protocol | Network security |
| Network-SearchDNSCache.ps1 | Search DNS cache entries | DNS troubleshooting |
| Network-SearchListeningPorts.ps1 | List listening TCP/UDP ports | Port scanning |
| Network-SearchTCPUDPConnections.ps1 | Search active network connections | Connection monitoring |
| Network-SetDNSServerAddress.ps1 | Configure DNS server addresses | DNS configuration |
| Network-SetLLMNR.ps1 | Enable/disable LLMNR | Network protocol control |
| Network-SetNetBios.ps1 | Enable/disable NetBIOS | Legacy protocol control |

---

## NinjaRMM - 5 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| NinjaRMM-STATFieldValidator.ps1 | Validate STAT custom fields | Field validation |
| NinjaRMM-SaveHardDriveType.ps1 | Save HDD/SSD type to custom field | Hardware inventory |
| NinjaRMM-UpdateDeviceDescription.ps1 | Auto-update device description | Device documentation |
| NinjaRMM-UpdateLocationGeoIP.ps1 | Update location via GeoIP lookup | Geographic tracking |

---

## Notifications - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Notifications-DisplayToastMessage.ps1 | Display Windows toast notification | User notifications |

---

## Office365 - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Office365-ModernAuthAlert.ps1 | Alert if modern authentication disabled | Security compliance |

---

## OneDrive - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| OneDrive-CopyFileToDesktop.ps1 | Copy file from OneDrive to desktop | File deployment |
| OneDrive-GetConfig.ps1 | Get OneDrive configuration details | OneDrive troubleshooting |

---

## Outlook - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Outlook-ReportLargeOSTandPST.ps1 | Report on large OST/PST files | Mailbox management |
| Outlook-SetForcedMigration.ps1 | Force Outlook profile migration | Profile migration |

---

## Power Management - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Power-ActivePlanReport.ps1 | Report active power plan | Power management |
| Power-SetFastStartup.ps1 | Enable/disable fast startup | Boot configuration |

---

## Printing - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Printing-TroubleshootAndClearQueue.ps1 | Troubleshoot and clear print queue | Print troubleshooting |

---

## Process Management - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Process-CloseAllOfficeApps.ps1 | Close all Microsoft Office applications | Application management |
| Process-CloseSAPandChrome.ps1 | Close SAP GUI and Chrome | Specific app termination |

---

## Remote Desktop (RDP) - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| RDP-CheckStatusAndPort.ps1 | Check RDP status and port | RDP troubleshooting |
| RDP-SetRemoteDesktop.ps1 | Enable/disable Remote Desktop | RDP configuration |

---

## SAP - 3 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| SAP-DeleteUserProfiles.ps1 | Delete SAP user profiles | Profile cleanup |
| SAP-DisableAutomaticUpdate.ps1 | Disable SAP automatic updates | Update control |
| SAP-PurgeSAPGUI.ps1 | Complete SAPGUI removal | SAPGUI cleanup |

---

## SQL Server - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| SQL-CollectMSSQLInstances.ps1 | Enumerate SQL Server instances | SQL inventory |
| SQL-MonitorServer.ps1 | Monitor SQL Server health | SQL monitoring |

---

## Security - 16 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Security-AuditUACLevel.ps1 | Audit User Account Control level | Security compliance |
| Security-CheckBruteForceAttempts.ps1 | Detect brute force login attempts | Security monitoring |
| Security-CredentialGuardStatus.ps1 | Check Credential Guard status | Security feature verification |
| Security-DetectInstalledAntivirus.ps1 | Detect installed antivirus software | AV inventory |
| Security-DisableWeakTLSandSSL.ps1 | Disable weak TLS/SSL protocols | Security hardening |
| Security-LocalAdminsReport.ps1 | Report local administrator accounts | Access auditing |
| Security-SecureBootComplianceReport.ps1 | Report Secure Boot compliance | UEFI security |
| Security-SetAutorunAndAutoplay.ps1 | Configure Autorun/Autoplay settings | Malware prevention |
| Security-SetLMCompatibilityLevel.ps1 | Set LM compatibility level | Authentication security |
| Security-SetLMHashStorage.ps1 | Disable LM hash storage | Password security |
| Security-SetSmartScreen.ps1 | Configure SmartScreen settings | Web protection |
| Security-SetUACSettings.ps1 | Configure UAC settings | Privilege elevation |
| Security-SetWindows10KeyLogger.ps1 | Configure Windows 10 telemetry | Privacy settings |
| Security-UnencryptedDiskAlert.ps1 | Alert on unencrypted disks | BitLocker compliance |
| Security-UnsignedDriverAlert.ps1 | Alert on unsigned drivers | Driver security |
| Security-VerifyRunningProcessesSigned.ps1 | Verify process signatures | Process integrity |

---

## Server Management - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Server-GetRoles.ps1 | Detect installed server roles | Server inventory |

---

## Services - 2 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Services-CheckStoppedAutomatic.ps1 | Check for stopped automatic services | Service monitoring |
| Services-RestartService.ps1 | Restart Windows service | Service management |

---

## Shortcuts - 5 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Shortcuts-CreateCeprosShortcuts.ps1 | Create Cepros application shortcuts | App deployment |
| Shortcuts-CreateDesktopEXE.ps1 | Create desktop shortcut to EXE | Shortcut creation |
| Shortcuts-CreateDesktopRDP.ps1 | Create RDP desktop shortcut | RDP shortcut |
| Shortcuts-CreateDesktopURL.ps1 | Create URL desktop shortcut | Web shortcut |
| Shortcuts-CreateGenericShortcut.ps1 | Generic shortcut creation | Flexible shortcuts |

---

## Software Management - 16 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Software-InstallAndRunBGInfo.ps1 | Install and configure BGInfo | Desktop wallpaper info |
| Software-InstallCatiaBMW-R2024SP2HFX10.ps1 | Install CATIA BMW R2024 SP2 HFX10 | CATIA deployment |
| Software-InstallCatiaBMW-R2024SP5.ps1 | Install CATIA BMW R2024 SP5 | CATIA deployment |
| Software-InstallDellCommandUpdate.ps1 | Install Dell Command Update | Dell driver management |
| Software-InstallNetFramework35.ps1 | Install .NET Framework 3.5 | Framework installation |
| Software-InstallOffice365.ps1 | Install Microsoft 365 Apps | Office deployment |
| Software-InstallSiemensNX.ps1 | Install Siemens NX | CAD software deployment |
| Software-InstallSiemensNX2.ps1 | Alternative Siemens NX installer | NX deployment |
| Software-InstallSysmon.ps1 | Install Sysinternals Sysmon | Security monitoring |
| Software-InstallWindowsStoreApp.ps1 | Install Windows Store application | App deployment |
| Software-ListInstalledApplications.ps1 | List all installed applications | Software inventory |
| Software-RemoveCCMClient.ps1 | Remove ConfigMgr client | SCCM cleanup |
| Software-RemoveMicrosoftBloatware.ps1 | Remove Windows 10/11 bloatware | OS cleanup |
| Software-StartKistersSetup.ps1 | Launch Kisters installer | App deployment |
| Software-TreesizeUltimate.ps1 | Install TreeSize Ultimate | Disk analysis tool |
| Software-UninstallApplication.ps1 | Uninstall application by name/GUID | Software removal |
| Software-UninstallCatiaBMW-R2024SP2.ps1 | Uninstall CATIA R2024 SP2 | CATIA removal |
| Software-UninstallCatiaBMW-R2024SP5.ps1 | Uninstall CATIA R2024 SP5 | CATIA removal |
| Software-UninstallDellSupportAssist.ps1 | Remove Dell SupportAssist | Dell bloatware removal |
| Software-UninstallPuTTY.ps1 | Uninstall PuTTY | Software cleanup |
| Software-UninstallSiemensNX2412.ps1 | Uninstall Siemens NX 2412 | NX removal |
| Software-UninstallWindowsDefender.ps1 | Remove Windows Defender | Security software removal |
| Software-UpdatePowerShell51.ps1 | Update to PowerShell 5.1 | PowerShell upgrade |

---

## System Operations - 9 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| System-BlueScreenAlert.ps1 | Alert on blue screen events | Stability monitoring |
| System-ConfigureTimeSync.ps1 | Configure Windows time synchronization | Time management |
| System-EnableMiniDumpsForBSOD.ps1 | Enable minidump creation for BSOD | Crash diagnostics |
| System-EnableMinidumps.ps1 | Enable memory dump creation | Troubleshooting |
| System-GetDeviceDescription.ps1 | Get comprehensive device description | Device documentation |
| System-GetEnrollmentStatus.ps1 | Check MDM/Intune enrollment status | Enrollment verification |
| System-LastRebootReason.ps1 | Determine last reboot reason | Reboot tracking |
| System-LogOffUsers.ps1 | Log off all users | Session management |
| System-RebuildSearchIndex.ps1 | Rebuild Windows Search index | Search troubleshooting |
| System-ShutdownComputer.ps1 | Shutdown computer with options | Power management |

---

## Teams - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Teams-ClearCache.ps1 | Clear Microsoft Teams cache | Teams troubleshooting |

---

## Templates - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Template-InvokeAsUser.ps1 | Template for running code as logged-on user | Script template |

---

## User Management - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| User-GetDisplayName.ps1 | Get current user display name | User identification |

---

## Veeam Backup - 1 Script

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Veeam-BackupMonitor.ps1 | Monitor Veeam backup jobs | Backup monitoring |

---

## VPN - 3 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| VPN-CopyAzureConfigToUserFolder.ps1 | Copy Azure VPN config to user folder | VPN deployment |
| VPN-ImportAzureConfig.ps1 | Import Azure VPN configuration | VPN configuration |
| VPN-InstallAzureVPNAppPackage.ps1 | Install Azure VPN client | VPN client deployment |

---

## WiFi - 6 Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| WiFi-AddMoellerProfile.ps1 | Add Moeller WiFi profile | WiFi deployment |
| WiFi-DeleteOldNetworksForklift.ps1 | Remove old forklift WiFi networks | WiFi cleanup |
| WiFi-DeployProfile.ps1 | Deploy WiFi profile to system | WiFi configuration |
| WiFi-GenerateReport.ps1 | Generate comprehensive WiFi report | WiFi troubleshooting |
| WiFi-GetDriverInfo.ps1 | Get WiFi driver information | Hardware diagnostics |
| WiFi-ShowActualProfile.ps1 | Display current WiFi profile | WiFi verification |

---

## Windows - Multiple Scripts

| Script Name | Description | Use Case |
|-------------|-------------|----------|
| Windows-AllowWin10to11Upgrade.ps1 | Allow Windows 10 to 11 upgrade | OS upgrade control |
| Windows-BlockWin10to11Upgrade.ps1 | Block Windows 10 to 11 upgrade | OS version control |
| Windows-ConfigureWindowsUpdate.ps1 | Configure Windows Update settings | Update management |
| Windows-DisableConsumerFeatures.ps1 | Disable Windows consumer features | Enterprise configuration |
| Windows-DisableWSUSSettings.ps1 | Disable WSUS configuration | Update source control |
| Windows-EnableDarkMode.ps1 | Enable Windows dark mode | User experience |
| Windows-SetUpdateChannel.ps1 | Set Windows Update channel | Update ring management |

---

## Summary Statistics

- **Total Scripts**: 219+
- **Total Categories**: 45
- **Most Scripts**: Software Management (16), Security (16), Network (16)
- **Format**: All `.ps1` (PowerShell)
- **Naming Standard**: `Category-ActionDescription.ps1`

---

**Last Updated**: February 9, 2026
**Repository**: Xore/waf
**Version**: 2.0
