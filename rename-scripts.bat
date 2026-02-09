@echo off
REM Batch script to rename NinjaRMM WAF scripts
REM Run this from the plaintext_scripts directory
echo Starting rename process...
echo.

echo [1] Renaming: Active Directory - Domain Controller Health Report.txt
ren "Active Directory - Domain Controller Health Report.txt" "AD-DomainControllerHealthReport.ps1"

echo [2] Renaming: Active Directory - Get OU Members.txt
ren "Active Directory - Get OU Members.txt" "AD-GetOUMembers.ps1"

echo [3] Renaming: Active Directory - Get Organizational Unit (OU).txt
ren "Active Directory - Get Organizational Unit (OU).txt" "AD-GetOrganizationalUnit.ps1"

echo [4] Renaming: Active Directory - Join Computer to a Domain.txt
ren "Active Directory - Join Computer to a Domain.txt" "AD-JoinComputerToDomain.ps1"

echo [5] Renaming: Active Directory - Remove Computer from the Domain.txt
ren "Active Directory - Remove Computer from the Domain.txt" "AD-RemoveComputerFromDomain.ps1"

echo [6] Renaming: Active Directory - Replication Health Report.txt
ren "Active Directory - Replication Health Report.txt" "AD-ReplicationHealthReport.ps1"

echo [7] Renaming: Active Directory Monitor.txt
ren "Active Directory Monitor.txt" "AD-Monitor.ps1"

echo [8] Renaming: Active Power Plan Report.txt
ren "Active Power Plan Report.txt" "Power-ActivePlanReport.ps1"

echo [9] Renaming: Add Moeller-Wifi Profile to computer.txt
ren "Add Moeller-Wifi Profile to computer.txt" "WiFi-AddMoellerProfile.ps1"

echo [10] Renaming: Alert on DHCP Lease Low.txt
ren "Alert on DHCP Lease Low.txt" "DHCP-AlertOnLeaseLow.ps1"

echo [11] Renaming: Allow Windows 10 to 11 Upgrade.txt
ren "Allow Windows 10 to 11 Upgrade.txt" "Windows-AllowWin10to11Upgrade.ps1"

echo [12] Renaming: Audit UAC Level.txt
ren "Audit UAC Level.txt" "Security-AuditUACLevel.ps1"

echo [13] Renaming: BDE Terminals - Start SAP and Browser.txt
ren "BDE Terminals - Start SAP and Browser.txt" "BDE-StartSAPandBrowser.ps1"

echo [14] Renaming: Backup Event Log to Local Disk.txt
ren "Backup Event Log to Local Disk.txt" "EventLog-BackupToLocalDisk.ps1"

echo [15] Renaming: Block Windows 10 to 11 Upgrade.txt
ren "Block Windows 10 to 11 Upgrade.txt" "Windows-BlockWin10to11Upgrade.ps1"

echo [16] Renaming: Blue Screen Alert.txt
ren "Blue Screen Alert.txt" "System-BlueScreenAlert.ps1"

echo [17] Renaming: Check Battery Health.txt
ren "Check Battery Health.txt" "Hardware-CheckBatteryHealth.ps1"

echo [18] Renaming: Check and Disable SMBv1.txt
ren "Check and Disable SMBv1.txt" "Network-CheckAndDisableSMBv1.ps1"

echo [19] Renaming: Check for Brute Force login attempts.txt
ren "Check for Brute Force login attempts.txt" "Security-CheckBruteForceAttempts.ps1"

echo [20] Renaming: Check for Stopped Automatic Services.txt
ren "Check for Stopped Automatic Services.txt" "Services-CheckStoppedAutomatic.ps1"

echo [21] Renaming: Clear DNS Cache.txt
ren "Clear DNS Cache.txt" "Network-ClearDNSCache.ps1"

echo [22] Renaming: Clear Teams Cache.txt
ren "Clear Teams Cache.txt" "Teams-ClearCache.ps1"

echo [23] Renaming: Collect MSSQL Instances.txt
ren "Collect MSSQL Instances.txt" "SQL-CollectMSSQLInstances.ps1"

echo [24] Renaming: Copy Folder with robocopy.txt
ren "Copy Folder with robocopy.txt" "FileOps-CopyFolderRobocopy.ps1"

echo [25] Renaming: Copy file to Onedrive desktop.txt
ren "Copy file to Onedrive desktop.txt" "OneDrive-CopyFileToDesktop.ps1"

echo [26] Renaming: Create Desktop Shortcut - EXE.txt
ren "Create Desktop Shortcut - EXE.txt" "Shortcuts-CreateDesktopEXE.ps1"

echo [27] Renaming: Create Desktop Shortcut - RDP.txt
ren "Create Desktop Shortcut - RDP.txt" "Shortcuts-CreateDesktopRDP.ps1"

echo [28] Renaming: Create Desktop Shortcut - URL.txt
ren "Create Desktop Shortcut - URL.txt" "Shortcuts-CreateDesktopURL.ps1"

echo [29] Renaming: Credential Guard Status.txt
ren "Credential Guard Status.txt" "Security-CredentialGuardStatus.ps1"

echo [30] Renaming: Delete file or folder.txt
ren "Delete file or folder.txt" "FileOps-DeleteFileOrFolder.ps1"

echo [31] Renaming: Deploy WiFi Profile.txt
ren "Deploy WiFi Profile.txt" "WiFi-DeployProfile.ps1"

echo [32] Renaming: Detect Installed Antivirus.txt
ren "Detect Installed Antivirus.txt" "Security-DetectInstalledAntivirus.ps1"

echo [33] Renaming: Device Uptime Percentage Monitor.txt
ren "Device Uptime Percentage Monitor.txt" "Monitoring-DeviceUptimePercentage.ps1"

echo [34] Renaming: Disable SAP AutomaticUpdate.txt
ren "Disable SAP AutomaticUpdate.txt" "SAP-DisableAutomaticUpdate.ps1"

echo [35] Renaming: Disable Weak TLS and SSL Protocols.txt
ren "Disable Weak TLS and SSL Protocols.txt" "Security-DisableWeakTLSandSSL.ps1"

echo [36] Renaming: Display Toast Message - Important Notifications.txt
ren "Display Toast Message - Important Notifications.txt" "Notifications-DisplayToastMessage.ps1"

echo [37] Renaming: Download File From URL.txt
ren "Download File From URL.txt" "FileOps-DownloadFromURL.ps1"

echo [38] Renaming: Enable Mini-Dumps for BSOD (Blue Screen).txt
ren "Enable Mini-Dumps for BSOD (Blue Screen).txt" "System-EnableMiniDumpsForBSOD.ps1"

echo [39] Renaming: Enable or Disable Autorun and Autoplay on All Drives.txt
ren "Enable or Disable Autorun and Autoplay on All Drives.txt" "Security-SetAutorunAndAutoplay.ps1"

echo [40] Renaming: Enable or Disable Fast Startup.txt
ren "Enable or Disable Fast Startup.txt" "Power-SetFastStartup.ps1"

echo [41] Renaming: Enable or Disable LM Hash Storage.txt
ren "Enable or Disable LM Hash Storage.txt" "Security-SetLMHashStorage.ps1"

echo [42] Renaming: Enable or Disable NetBios.txt
ren "Enable or Disable NetBios.txt" "Network-SetNetBios.ps1"

echo [43] Renaming: Enable or Disable New Outlook Forced Migration.txt
ren "Enable or Disable New Outlook Forced Migration.txt" "Outlook-SetForcedMigration.ps1"

echo [44] Renaming: Enable or Disable Remote Desktop (RDP).txt
ren "Enable or Disable Remote Desktop (RDP).txt" "RDP-SetRemoteDesktop.ps1"

echo [45] Renaming: Enable or Disable Show Hidden Files or Folders.txt
ren "Enable or Disable Show Hidden Files or Folders.txt" "Explorer-SetShowHiddenFiles.ps1"

echo [46] Renaming: Enable or Disable SmartScreen.txt
ren "Enable or Disable SmartScreen.txt" "Security-SetSmartScreen.ps1"

echo [47] Renaming: Enable or Disable Windows 10 Key Logger.txt
ren "Enable or Disable Windows 10 Key Logger.txt" "Security-SetWindows10KeyLogger.ps1"

echo [48] Renaming: Exchange Version Check.txt
ren "Exchange Version Check.txt" "Exchange-VersionCheck.ps1"

echo [49] Renaming: File Modification Alert.txt
ren "File Modification Alert.txt" "Monitoring-FileModificationAlert.ps1"

echo [50] Renaming: Find Rogue DHCP Servers Using Nmap.txt
ren "Find Rogue DHCP Servers Using Nmap.txt" "DHCP-FindRogueServersNmap.ps1"

echo [51] Renaming: Firewall - Audit Status 2.txt
ren "Firewall - Audit Status 2.txt" "Firewall-AuditStatus2.ps1"

echo [52] Renaming: Firewall - Audit Status.txt
ren "Firewall - Audit Status.txt" "Firewall-AuditStatus.ps1"

echo [53] Renaming: Get Device Description.txt
ren "Get Device Description.txt" "System-GetDeviceDescription.ps1"

echo [54] Renaming: Get Enrollment Status.txt
ren "Get Enrollment Status.txt" "System-GetEnrollmentStatus.ps1"

echo [55] Renaming: Get Expiring SSL Certificates.txt
ren "Get Expiring SSL Certificates.txt" "Certificates-GetExpiring.ps1"

echo [56] Renaming: Get IIS Bindings.txt
ren "Get IIS Bindings.txt" "IIS-GetBindings.ps1"

echo [57] Renaming: Get LLDP  info.txt
ren "Get LLDP  info.txt" "Network-GetLLDPInfo.ps1"

echo [58] Renaming: Get Server Roles.txt
ren "Get Server Roles.txt" "Server-GetRoles.ps1"

echo [59] Renaming: Get WiFi Driver Info.txt
ren "Get WiFi Driver Info.txt" "WiFi-GetDriverInfo.ps1"

echo [60] Renaming: Get attached monitors.txt
ren "Get attached monitors.txt" "Hardware-GetAttachedMonitors.ps1"

echo [61] Renaming: Get-OneDriveConfig.txt
ren "Get-OneDriveConfig.txt" "OneDrive-GetConfig.ps1"

echo [62] Renaming: Group Policy Monitor.txt
ren "Group Policy Monitor.txt" "GPO-Monitor.ps1"

echo [63] Renaming: Host File Changed Alert.txt
ren "Host File Changed Alert.txt" "Monitoring-HostFileChangedAlert.ps1"

echo [64] Renaming: Hyper-V - Checkpoint Expiration Alert.txt
ren "Hyper-V - Checkpoint Expiration Alert.txt" "HyperV-CheckpointExpirationAlert.ps1"

echo [65] Renaming: Hyper-V - Get Host Server Name from Guest.txt
ren "Hyper-V - Get Host Server Name from Guest.txt" "HyperV-GetHostFromGuest.ps1"

echo [66] Renaming: Hyper-V - Replication Alert.txt
ren "Hyper-V - Replication Alert.txt" "HyperV-ReplicationAlert.ps1"

echo [67] Renaming: Install Catia BMW R2024 SP2 HFX10.txt
ren "Install Catia BMW R2024 SP2 HFX10.txt" "Software-InstallCatiaBMW-R2024SP2HFX10.ps1"

echo [68] Renaming: Install Catia BMW R2024 SP5.txt
ren "Install Catia BMW R2024 SP5.txt" "Software-InstallCatiaBMW-R2024SP5.ps1"

echo [69] Renaming: Install Dell Command & Update.txt
ren "Install Dell Command ^& Update.txt" "Software-InstallDellCommandUpdate.ps1"

echo [70] Renaming: Install Net Framework 3.5
ren "Install Net Framework 3.5" "Software-InstallNetFramework35.ps1"

echo [71] Renaming: Install Office 365 with options.txt
ren "Install Office 365 with options.txt" "Software-InstallOffice365.ps1"

echo [72] Renaming: Install Siemens NX  2.txt
ren "Install Siemens NX  2.txt" "Software-InstallSiemensNX2.ps1"

echo [73] Renaming: Install Siemens NX .txt
ren "Install Siemens NX .txt" "Software-InstallSiemensNX.ps1"

echo [74] Renaming: Install Sysmon with Config.txt
ren "Install Sysmon with Config.txt" "Software-InstallSysmon.ps1"

echo [75] Renaming: Install and Run BGInfo.txt
ren "Install and Run BGInfo.txt" "Software-InstallAndRunBGInfo.ps1"

echo [76] Renaming: Internet Speed Test.txt
ren "Internet Speed Test.txt" "Network-InternetSpeedTest.ps1"

echo [77] Renaming: Last Reboot Reason.txt
ren "Last Reboot Reason.txt" "System-LastRebootReason.ps1"

echo [78] Renaming: List Browser Extensions.txt
ren "List Browser Extensions.txt" "Browser-ListExtensions.ps1"

echo [79] Renaming: Local Admins Report.txt
ren "Local Admins Report.txt" "Security-LocalAdminsReport.ps1"

echo [80] Renaming: Local Certificate Expiration Alert.txt
ren "Local Certificate Expiration Alert.txt" "Certificates-LocalExpirationAlert.ps1"

echo [81] Renaming: Locked Out User Report.txt
ren "Locked Out User Report.txt" "AD-LockedOutUserReport.ps1"

echo [82] Renaming: Log Off Users.txt
ren "Log Off Users.txt" "System-LogOffUsers.ps1"

echo [83] Renaming: Map Network Drives.txt
ren "Map Network Drives.txt" "Network-MapDrives.ps1"

echo [84] Renaming: Microsoft Entra Audit.txt
ren "Microsoft Entra Audit.txt" "Entra-Audit.ps1"

echo [85] Renaming: Modify Users Group Membership.txt
ren "Modify Users Group Membership.txt" "AD-ModifyUserGroupMembership.ps1"

echo [86] Renaming: Monitor SQL Server.txt
ren "Monitor SQL Server.txt" "SQL-MonitorServer.ps1"

echo [87] Renaming: Monitor Time difference to NTP server.txt
ren "Monitor Time difference to NTP server.txt" "Monitoring-NTPTimeDifference.ps1"

echo [88] Renaming: Mount myPLM as Z drive.txt
ren "Mount myPLM as Z drive.txt" "Network-MountMyPLMasZ.ps1"

echo [89] Renaming: Office 365 Modern Auth Alert.txt
ren "Office 365 Modern Auth Alert.txt" "Office365-ModernAuthAlert.ps1"

echo [90] Renaming: Optimize EventLog.txt
ren "Optimize EventLog.txt" "EventLog-Optimize.ps1"

echo [91] Renaming: Rebuild Search Index.txt
ren "Rebuild Search Index.txt" "System-RebuildSearchIndex.ps1"

echo [92] Renaming: Remote Desktop - Check Status and Port.txt
ren "Remote Desktop - Check Status and Port.txt" "RDP-CheckStatusAndPort.ps1"

echo [93] Renaming: Remove  Uninstall Catia R2024SP2_BMW.txt
ren "Remove  Uninstall Catia R2024SP2_BMW.txt" "Software-UninstallCatiaBMW-R2024SP2.ps1"

echo [94] Renaming: Remove  Uninstall Catia R2024SP5_BMW.txt
ren "Remove  Uninstall Catia R2024SP5_BMW.txt" "Software-UninstallCatiaBMW-R2024SP5.ps1"

echo [95] Renaming: Remove Microsoft Bloatware.txt
ren "Remove Microsoft Bloatware.txt" "Software-RemoveMicrosoftBloatware.ps1"

echo [96] Renaming: Remove PuTTY.txt
ren "Remove PuTTY.txt" "Software-UninstallPuTTY.ps1"

echo [97] Renaming: Remove Uninstall Siemens NX 2412.txt
ren "Remove Uninstall Siemens NX 2412.txt" "Software-UninstallSiemensNX2412.ps1"

echo [98] Renaming: Repair AD trust.txt
ren "Repair AD trust.txt" "AD-RepairTrust.ps1"

echo [99] Renaming: Report on Large OST and PST Files.txt
ren "Report on Large OST and PST Files.txt" "Outlook-ReportLargeOSTandPST.ps1"

echo [100] Renaming: Restart a service.txt
ren "Restart a service.txt" "Services-RestartService.ps1"

echo [101] Renaming: Restrict IPv4 IGMP (Multicast) for all adapters.txt
ren "Restrict IPv4 IGMP (Multicast) for all adapters.txt" "Network-RestrictIPv4IGMP.ps1"

echo [102] Renaming: SSD Wear Health Alert.txt
ren "SSD Wear Health Alert.txt" "Hardware-SSDWearHealthAlert.ps1"

echo [103] Renaming: STAT Field Validator .txt
ren "STAT Field Validator .txt" "NinjaRMM-STATFieldValidator.ps1"

echo [104] Renaming: Save Hard Drive Type to Custom Field.txt
ren "Save Hard Drive Type to Custom Field.txt" "NinjaRMM-SaveHardDriveType.ps1"

echo [105] Renaming: Script 22 Capacity Trend Forecaster.txt
ren "Script 22 Capacity Trend Forecaster.txt" "Monitoring-CapacityTrendForecaster.ps1"

echo [106] Renaming: Script 6 Telemetry Collector.txt
ren "Script 6 Telemetry Collector.txt" "Monitoring-TelemetryCollector.ps1"

echo [107] Renaming: Search DNS Cache Entries.txt
ren "Search DNS Cache Entries.txt" "Network-SearchDNSCache.ps1"

echo [108] Renaming: Search Event Log.txt
ren "Search Event Log.txt" "EventLog-Search.ps1"

echo [109] Renaming: Search TCP or UDP Connections for Specified IP Address.txt
ren "Search TCP or UDP Connections for Specified IP Address.txt" "Network-SearchTCPUDPConnections.ps1"

echo [110] Renaming: Search for Listening and Established Ports.txt
ren "Search for Listening and Established Ports.txt" "Network-SearchListeningPorts.ps1"

echo [111] Renaming: Secure Boot Compliance Report.txt
ren "Secure Boot Compliance Report.txt" "Security-SecureBootComplianceReport.ps1"

echo [112] Renaming: Set Default Filetype Associations.txt
ren "Set Default Filetype Associations.txt" "Explorer-SetDefaultFiletypeAssociations.ps1"

echo [113] Renaming: Set LLMNR(DNS MultiCast).txt
ren "Set LLMNR(DNS MultiCast).txt" "Network-SetLLMNR.ps1"

echo [114] Renaming: Set News and Interests.txt
ren "Set News and Interests.txt" "Windows-SetNewsAndInterests.ps1"

echo [115] Renaming: Set UAC Settings.txt
ren "Set UAC Settings.txt" "Security-SetUACSettings.ps1"

echo [116] Renaming: Set or Modify DNS Server Address.txt
ren "Set or Modify DNS Server Address.txt" "Network-SetDNSServerAddress.ps1"

echo [117] Renaming: Set the LM Compatibility Level.txt
ren "Set the LM Compatibility Level.txt" "Security-SetLMCompatibilityLevel.ps1"

echo [118] Renaming: Show Actual Wifi Profile.txt
ren "Show Actual Wifi Profile.txt" "WiFi-ShowActualProfile.ps1"

echo [119] Renaming: Shutdown Computer.txt
ren "Shutdown Computer.txt" "System-ShutdownComputer.ps1"

echo [120] Renaming: Software Removal - Uninstall Dell Support Assist.txt
ren "Software Removal - Uninstall Dell Support Assist.txt" "Software-UninstallDellSupportAssist.ps1"

echo [121] Renaming: Start Kisters 2025.4.529 Setup
ren "Start Kisters 2025.4.529 Setup" "Software-StartKistersSetup.ps1"

echo [122] Renaming: System Performance Check.txt
ren "System Performance Check.txt" "Monitoring-SystemPerformanceCheck.ps1"

echo [123] Renaming: TEMPLARE - Invoke as User.txt
ren "TEMPLARE - Invoke as User.txt" "Template-InvokeAsUser.ps1"

echo [124] Renaming: Time Sync - Configure Settings.txt
ren "Time Sync - Configure Settings.txt" "System-ConfigureTimeSync.ps1"

echo [125] Renaming: Treesize Ultimate.txt
ren "Treesize Ultimate.txt" "Software-TreesizeUltimate.ps1"

echo [126] Renaming: Troubleshoot Printers and Clear Print Queue.txt
ren "Troubleshoot Printers and Clear Print Queue.txt" "Printing-TroubleshootAndClearQueue.ps1"

echo [127] Renaming: USB Drive Alert.txt
ren "USB Drive Alert.txt" "Hardware-USBDriveAlert.ps1"

echo [128] Renaming: Unencrypted Disk Alert.txt
ren "Unencrypted Disk Alert.txt" "Security-UnencryptedDiskAlert.ps1"

echo [129] Renaming: Uninstall Windows Defender.txt
ren "Uninstall Windows Defender.txt" "Software-UninstallWindowsDefender.ps1"

echo [130] Renaming: Uninstall a Windows Application.txt
ren "Uninstall a Windows Application.txt" "Software-UninstallApplication.ps1"

echo [131] Renaming: Unlicensed Copy of Windows Alert.txt
ren "Unlicensed Copy of Windows Alert.txt" "Licensing-UnlicensedWindowsAlert.ps1"

echo [132] Renaming: Unsigned Driver Alert.txt
ren "Unsigned Driver Alert.txt" "Security-UnsignedDriverAlert.ps1"

echo [133] Renaming: Update Device Description.txt
ren "Update Device Description.txt" "NinjaRMM-UpdateDeviceDescription.ps1"

echo [134] Renaming: Update Location Custom Field based on GeoIP.txt
ren "Update Location Custom Field based on GeoIP.txt" "NinjaRMM-UpdateLocationGeoIP.ps1"

echo [135] Renaming: Update PowerShell to Version 5.1
ren "Update PowerShell to Version 5.1" "Software-UpdatePowerShell51.ps1"

echo [136] Renaming: Update and report Group Policies.txt
ren "Update and report Group Policies.txt" "GPO-UpdateAndReport.ps1"

echo [137] Renaming: User Login History Report.txt
ren "User Login History Report.txt" "AD-UserLoginHistoryReport.ps1"

echo [138] Renaming: User Logon History.txt
ren "User Logon History.txt" "AD-UserLogonHistory.ps1"

echo [139] Renaming: User or Group Membership Report.txt
ren "User or Group Membership Report.txt" "AD-UserGroupMembershipReport.ps1"

echo [140] Renaming: Veeam Backup Monitor.txt
ren "Veeam Backup Monitor.txt" "Veeam-BackupMonitor.ps1"

echo [141] Renaming: Verify running processes are signed.txt
ren "Verify running processes are signed.txt" "Security-VerifyRunningProcessesSigned.ps1"

echo.
echo Rename complete! 141 files renamed.
pause
