# Plaintext Scripts Inventory & Rename Mapping

**Project:** Windows Automation Framework (WAF)  
**Date:** February 9, 2026  
**Total Scripts:** 200+  
**Status:** Documentation Phase

---

## Overview

This document provides a complete inventory of all scripts in the `plaintext_scripts` folder with proposed standardized names following WAF naming conventions.

### Naming Conventions

**Monitoring Scripts:**
```
Script_XX_Description_Monitor.ps1
```

**Automation Scripts:**
```
XX_Description_Action.ps1
```

---

## Duplicate Scripts - Require Resolution

| Current Name | Duplicate Of | File Size | Action | Priority |
|--------------|--------------|-----------|--------|----------|
| Firewall - Audit Status 2.txt | Firewall - Audit Status.txt | 11,090 bytes (both) | Delete duplicate | High |
| Install Siemens NX  2.txt | Install Siemens NX .txt | Similar | Merge and delete | High |
| enable minidumps.txt | Enable Mini-Dumps for BSOD (Blue Screen).txt | Similar | Merge and delete | Medium |

---

## Category 1: Active Directory Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 1 | Active Directory - Domain Controller Health Report.txt | Script_01_Active_Directory_Domain_Controller_Health_Monitor.ps1 | 15,175 | Comprehensive DC health monitoring |
| 2 | Active Directory - Get OU Members.txt | 01_Active_Directory_Get_OU_Members.ps1 | 2,702 | Retrieves organizational unit members |
| 3 | Active Directory - Get Organizational Unit (OU).txt | 02_Active_Directory_Get_Organizational_Unit.ps1 | 8,492 | Gets OU information and structure |
| 4 | Active Directory - Join Computer to a Domain.txt | 03_Active_Directory_Join_Computer_to_Domain.ps1 | 13,976 | Joins computer to domain with validation |
| 5 | Active Directory - Remove Computer from the Domain.txt | 04_Active_Directory_Remove_Computer_from_Domain.ps1 | 10,584 | Removes computer from domain |
| 6 | Active Directory - Replication Health Report.txt | Script_02_Active_Directory_Replication_Health_Monitor.ps1 | 18,757 | Monitors AD replication status |
| 7 | Active Directory Monitor.txt | Script_03_Active_Directory_General_Monitor.ps1 | 16,794 | General Active Directory monitoring |
| 8 | Repair AD trust.txt | 05_Active_Directory_Repair_Computer_Trust.ps1 | TBD | Repairs computer trust relationship |

---

## Category 2: System Monitoring Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 9 | Active Power Plan Report.txt | Script_04_Power_Plan_Monitor.ps1 | 14,009 | Reports active power plan configuration |
| 10 | Audit UAC Level.txt | Script_05_UAC_Level_Audit_Monitor.ps1 | 9,962 | Audits User Account Control levels |
| 11 | Check Battery Health.txt | Script_06_Battery_Health_Monitor.ps1 | 73,557 | Checks laptop battery health status |
| 12 | Blue Screen Alert.txt | Script_07_Blue_Screen_Alert_Monitor.ps1 | 4,344 | Monitors for BSOD events |
| 13 | Check for Stopped Automatic Services.txt | Script_08_Stopped_Services_Monitor.ps1 | 8,852 | Monitors stopped automatic services |
| 14 | Credential Guard Status.txt | Script_09_Credential_Guard_Status_Monitor.ps1 | 13,364 | Checks Credential Guard configuration |
| 15 | Device Uptime Percentage Monitor.txt | Script_10_Device_Uptime_Percentage_Monitor.ps1 | 22,491 | Tracks device uptime percentage |
| 16 | Last Reboot Reason.txt | Script_11_Last_Reboot_Reason_Monitor.ps1 | TBD | Determines last system reboot reason |
| 17 | System Performance Check.txt | Script_12_System_Performance_Monitor.ps1 | TBD | Comprehensive performance monitoring |
| 18 | Get Device Description.txt | 06_Get_Device_Description.ps1 | 8,120 | Retrieves device description field |
| 19 | Update Device Description.txt | 07_Update_Device_Description.ps1 | TBD | Updates device description field |

---

## Category 3: Security & Compliance Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 20 | Check and Disable SMBv1.txt | Script_13_SMBv1_Compliance_Monitor.ps1 | 10,058 | Checks and disables SMBv1 protocol |
| 21 | Check for Brute Force login attempts.txt | Script_14_Brute_Force_Login_Alert_Monitor.ps1 | 5,224 | Monitors for brute force attacks |
| 22 | Detect Installed Antivirus.txt | Script_15_Antivirus_Detection_Monitor.ps1 | 50,770 | Detects installed antivirus software |
| 23 | Microsoft Entra Audit.txt | Script_16_Microsoft_Entra_Audit_Monitor.ps1 | TBD | Audits Entra ID status |
| 24 | Secure Boot Compliance Report.txt | Script_17_Secure_Boot_Compliance_Monitor.ps1 | TBD | Reports Secure Boot status |
| 25 | SSD Wear Health Alert.txt | Script_18_SSD_Wear_Health_Monitor.ps1 | TBD | Monitors SSD wear level |
| 26 | Unencrypted Disk Alert.txt | Script_19_Unencrypted_Disk_Alert_Monitor.ps1 | TBD | Alerts on unencrypted disks |
| 27 | Unsigned Driver Alert.txt | Script_20_Unsigned_Driver_Alert_Monitor.ps1 | TBD | Detects unsigned drivers |
| 28 | USB Drive Alert.txt | Script_21_USB_Drive_Alert_Monitor.ps1 | TBD | Monitors USB drive connections |

---

## Category 4: Network Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 29 | Add Moeller-Wifi Profile to computer.txt | 08_WiFi_Add_Moeller_Profile.ps1 | 3,250 | Adds specific WiFi profile |
| 30 | Alert on DHCP Lease Low.txt | Script_22_DHCP_Lease_Low_Alert_Monitor.ps1 | 8,278 | Monitors DHCP lease availability |
| 31 | Clear DNS Cache.txt | 09_Clear_DNS_Cache.ps1 | 2,836 | Clears DNS client cache |
| 32 | Deploy WiFi Profile.txt | 10_WiFi_Deploy_Profile.ps1 | 22,486 | Deploys WiFi configuration |
| 33 | Find Rogue DHCP Servers Using Nmap.txt | Script_23_Rogue_DHCP_Detection_Monitor.ps1 | 6,734 | Detects unauthorized DHCP servers |
| 34 | Get LLDP  info.txt | Script_24_LLDP_Information_Monitor.ps1 | 579 | Gathers LLDP neighbor information |
| 35 | Get WiFi Driver Info.txt | 11_Get_WiFi_Driver_Information.ps1 | 1,854 | Retrieves WiFi driver details |
| 36 | Set or Modify DNS Server Address.txt | 12_Set_DNS_Server_Address.ps1 | TBD | Configures DNS server addresses |
| 37 | WiFi Report.txt | Script_25_WiFi_Configuration_Monitor.ps1 | TBD | Generates WiFi configuration report |
| 38 | Wired Network Sub 1Gbps Alert.txt | Script_26_Wired_Network_Speed_Alert_Monitor.ps1 | TBD | Alerts on slow wired connections |
| 39 | delete old wifi networks - forklift.txt | 13_WiFi_Delete_Old_Profiles_Forklift.ps1 | TBD | Removes old WiFi profiles |
| 40 | Show Actual Wifi Profile.txt | 14_WiFi_Show_Active_Profile.ps1 | TBD | Displays current WiFi profile |

---

## Category 5: Firewall & Security Policy Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 41 | Firewall - Audit Status.txt | Script_27_Firewall_Status_Audit_Monitor.ps1 | 11,090 | Audits firewall configuration |
| 42 | Firewall - Audit Status 2.txt | DELETE_DUPLICATE | 11,090 | Exact duplicate - DELETE |
| 43 | Disable Weak TLS and SSL Protocols.txt | 15_Disable_Weak_TLS_SSL_Protocols.ps1 | 3,494 | Disables insecure protocols |
| 44 | Enable or Disable LM Hash Storage.txt | 16_Configure_LM_Hash_Storage.ps1 | 3,259 | Configures LM hash storage |
| 45 | Enable or Disable NetBios.txt | 17_Configure_NetBios.ps1 | 3,085 | Enables/disables NetBIOS |
| 46 | Enable or Disable Remote Desktop (RDP).txt | 18_Configure_Remote_Desktop.ps1 | 5,338 | Configures RDP settings |
| 47 | Enable or Disable SmartScreen.txt | 19_Configure_SmartScreen.ps1 | 30,151 | Configures SmartScreen filter |
| 48 | Enable or Disable Windows 10 Key Logger.txt | 20_Configure_Windows_Keylogger.ps1 | 7,322 | Configures diagnostic data collection |
| 49 | Set UAC Settings.txt | 21_Set_UAC_Level.ps1 | TBD | Configures UAC level |
| 50 | Set the LM Compatibility Level.txt | 22_Set_LM_Compatibility_Level.ps1 | TBD | Sets LM compatibility level |
| 51 | Set LLMNR(DNS MultiCast).txt | 23_Configure_LLMNR.ps1 | TBD | Configures LLMNR settings |
| 52 | Restrict IPv4 IGMP (Multicast) for all adapters.txt | 24_Restrict_IGMP_Multicast.ps1 | TBD | Restricts multicast traffic |

---

## Category 6: Windows Update & Patching Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 53 | Allow Windows 10 to 11 Upgrade.txt | 25_Windows_Allow_11_Upgrade.ps1 | 1,546 | Enables Windows 11 upgrade |
| 54 | Block Windows 10 to 11 Upgrade.txt | 26_Windows_Block_11_Upgrade.ps1 | 4,424 | Blocks Windows 11 upgrade |
| 55 | Windows 11 Upgrade Compatibility.txt | Script_28_Windows_11_Compatibility_Monitor.ps1 | TBD | Checks Windows 11 compatibility |
| 56 | Windows Update Diagnostic.txt | Script_29_Windows_Update_Diagnostic_Monitor.ps1 | TBD | Diagnoses Windows Update issues |
| 57 | block KB5027397.txt | 27_Windows_Block_Specific_Update.ps1 | TBD | Blocks specific Windows update |
| 58 | disable UseWUServer & clear WUServer, WUStatusServer.txt | 28_Windows_Update_Reset_WSUS_Config.ps1 | TBD | Resets WSUS configuration |
| 59 | get last Windows Update.txt | 29_Get_Last_Windows_Update.ps1 | TBD | Retrieves last update date |

---

## Category 7: Software Installation Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 60 | Install Catia BMW R2024 SP2 HFX10.txt | 30_Install_Catia_BMW_R2024_SP2_HFX10.ps1 | TBD | Installs specific Catia version |
| 61 | Install Catia BMW R2024 SP5.txt | 31_Install_Catia_BMW_R2024_SP5.ps1 | TBD | Installs specific Catia version |
| 62 | Install Dell Command & Update.txt | 32_Install_Dell_Command_Update.ps1 | TBD | Installs Dell Command Update |
| 63 | Install Net Framework 3.5 | 33_Install_Net_Framework_35.ps1 | TBD | Installs .NET Framework 3.5 |
| 64 | Install Office 365 with options.txt | 34_Install_Office_365_Custom.ps1 | TBD | Custom Office 365 installation |
| 65 | Install Siemens NX .txt | 35_Install_Siemens_NX.ps1 | TBD | Installs Siemens NX |
| 66 | Install Siemens NX  2.txt | DELETE_DUPLICATE | TBD | Duplicate - DELETE |
| 67 | Install Sysmon with Config.txt | 36_Install_Sysmon_With_Config.ps1 | TBD | Installs Sysmon with configuration |
| 68 | Install and Run BGInfo.txt | 37_Install_Run_BGInfo.ps1 | TBD | Installs and configures BGInfo |
| 69 | install azure vpn application package.txt | 38_Install_Azure_VPN_Package.ps1 | TBD | Installs Azure VPN client |
| 70 | install windows store application.txt | 39_Install_Windows_Store_Application.ps1 | TBD | Installs Store apps |

---

## Category 8: Software Removal Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 71 | Remove  Uninstall Catia R2024SP2_BMW.txt | 40_Uninstall_Catia_R2024_SP2_BMW.ps1 | TBD | Uninstalls Catia R2024 SP2 |
| 72 | Remove  Uninstall Catia R2024SP5_BMW.txt | 41_Uninstall_Catia_R2024_SP5_BMW.ps1 | TBD | Uninstalls Catia R2024 SP5 |
| 73 | Remove Microsoft Bloatware.txt | 42_Remove_Microsoft_Bloatware.ps1 | TBD | Removes default Windows apps |
| 74 | Remove PuTTY.txt | 43_Uninstall_PuTTY.ps1 | TBD | Uninstalls PuTTY |
| 75 | Remove Uninstall Siemens NX 2412.txt | 44_Uninstall_Siemens_NX_2412.ps1 | TBD | Uninstalls Siemens NX 2412 |
| 76 | Software Removal - Uninstall Dell Support Assist.txt | 45_Uninstall_Dell_Support_Assist.ps1 | TBD | Uninstalls Dell Support Assist |
| 77 | Uninstall Windows Defender.txt | 46_Uninstall_Windows_Defender.ps1 | TBD | Removes Windows Defender |
| 78 | Uninstall a Windows Application.txt | 47_Uninstall_Windows_Application.ps1 | TBD | Generic uninstaller script |

---

## Category 9: Desktop & User Interface Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 79 | Create Desktop Shortcut - EXE.txt | 48_Create_Desktop_Shortcut_EXE.ps1 | 23,404 | Creates EXE shortcut |
| 80 | Create Desktop Shortcut - RDP.txt | 49_Create_Desktop_Shortcut_RDP.ps1 | 10,950 | Creates RDP shortcut |
| 81 | Create Desktop Shortcut - URL.txt | 50_Create_Desktop_Shortcut_URL.ps1 | 6,667 | Creates URL shortcut |
| 82 | Display Toast Message - Important Notifications.txt | 51_Display_Toast_Notification.ps1 | 8,255 | Shows toast notification |
| 83 | Enable or Disable Autorun and Autoplay on All Drives.txt | 52_Configure_Autorun_Autoplay.ps1 | 14,058 | Configures autorun/autoplay |
| 84 | Enable or Disable Fast Startup.txt | 53_Configure_Fast_Startup.ps1 | 7,072 | Configures fast startup |
| 85 | Enable or Disable New Outlook Forced Migration.txt | 54_Configure_New_Outlook_Migration.ps1 | 36,154 | Controls Outlook migration |
| 86 | Enable or Disable Show Hidden Files or Folders.txt | 55_Configure_Show_Hidden_Files.ps1 | 14,888 | Configures hidden file display |
| 87 | Set Default Filetype Associations.txt | 56_Set_Default_File_Associations.ps1 | TBD | Sets default file handlers |
| 88 | Set News and Interests.txt | 57_Configure_News_And_Interests.ps1 | TBD | Configures taskbar news |
| 89 | create shortcut.txt | 58_Create_Generic_Shortcut.ps1 | TBD | Generic shortcut creator |
| 90 | create cepros shortcuts & copy to desktops.txt | 59_Create_Cepros_Shortcuts.ps1 | TBD | Creates Cepros shortcuts |

---

## Category 10: Server Role Monitoring Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 91 | Collect MSSQL Instances.txt | Script_30_SQL_Server_Instance_Monitor.ps1 | 10,413 | Collects SQL instance information |
| 92 | Exchange Version Check.txt | Script_31_Exchange_Version_Monitor.ps1 | 21,264 | Monitors Exchange version |
| 93 | Get Expiring SSL Certificates.txt | Script_32_SSL_Certificate_Expiration_Monitor.ps1 | 1,495 | Monitors SSL certificate expiration |
| 94 | Get IIS Bindings.txt | Script_33_IIS_Bindings_Monitor.ps1 | 653 | Retrieves IIS site bindings |
| 95 | Get Server Roles.txt | Script_34_Server_Roles_Monitor.ps1 | 38,767 | Detects installed server roles |
| 96 | Hyper-V - Checkpoint Expiration Alert.txt | Script_35_Hyper_V_Checkpoint_Age_Monitor.ps1 | 4,089 | Monitors Hyper-V checkpoint age |
| 97 | Hyper-V - Get Host Server Name from Guest.txt | Script_36_Hyper_V_Host_Detection_Monitor.ps1 | 9,842 | Gets Hyper-V host from guest |
| 98 | Hyper-V - Replication Alert.txt | Script_37_Hyper_V_Replication_Monitor.ps1 | 13,188 | Monitors Hyper-V replication |
| 99 | Monitor SQL Server.txt | Script_38_SQL_Server_Health_Monitor.ps1 | TBD | Comprehensive SQL monitoring |
| 100 | Veeam Backup Monitor.txt | Script_39_Veeam_Backup_Monitor.ps1 | TBD | Monitors Veeam backup status |

---

## Category 11: Group Policy & Configuration Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 101 | Group Policy Monitor.txt | Script_40_Group_Policy_Monitor.ps1 | 9,570 | Monitors GPO application |
| 102 | Update and report Group Policies.txt | 60_Update_Report_Group_Policies.ps1 | TBD | Forces GPO update and reports |
| 103 | Host File Changed Alert.txt | Script_41_Hosts_File_Change_Alert_Monitor.ps1 | 3,343 | Monitors hosts file changes |
| 104 | File Modification Alert.txt | Script_42_File_Modification_Alert_Monitor.ps1 | 7,503 | Monitors file modifications |

---

## Category 12: Event Log Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 105 | Backup Event Log to Local Disk.txt | 61_Backup_Event_Log_To_Disk.ps1 | 12,967 | Backs up event logs |
| 106 | Optimize EventLog.txt | 62_Optimize_Event_Log_Size.ps1 | TBD | Optimizes event log settings |
| 107 | Search Event Log.txt | 63_Search_Event_Log.ps1 | TBD | Searches event logs |

---

## Category 13: User Management Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 108 | Local Admins Report.txt | Script_43_Local_Admins_Report_Monitor.ps1 | TBD | Reports local administrators |
| 109 | Local Certificate Expiration Alert.txt | Script_44_Local_Certificate_Expiration_Monitor.ps1 | TBD | Monitors local cert expiration |
| 110 | Locked Out User Report.txt | Script_45_Locked_Out_User_Monitor.ps1 | TBD | Reports locked out users |
| 111 | Log Off Users.txt | 64_Log_Off_Users.ps1 | TBD | Logs off user sessions |
| 112 | Modify Users Group Membership.txt | 65_Modify_User_Group_Membership.ps1 | TBD | Modifies group membership |
| 113 | User Login History Report.txt | Script_46_User_Login_History_Monitor.ps1 | TBD | Reports user login history |
| 114 | User Logon History.txt | Script_47_User_Logon_Sessions_Monitor.ps1 | TBD | Monitors user logon sessions |
| 115 | User or Group Membership Report.txt | Script_48_User_Group_Membership_Monitor.ps1 | TBD | Reports group memberships |
| 116 | get display name from user.txt | 66_Get_User_Display_Name.ps1 | TBD | Retrieves user display name |

---

## Category 14: Disk & Storage Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 117 | Save Hard Drive Type to Custom Field.txt | 67_Save_Hard_Drive_Type.ps1 | TBD | Saves disk type to field |
| 118 | Script 22 Capacity Trend Forecaster.txt | Script_49_Capacity_Trend_Forecaster.ps1 | TBD | Forecasts disk capacity trends |

---

## Category 15: Network Mapping Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 119 | Map Network Drives.txt | 68_Map_Network_Drives.ps1 | TBD | Maps network drives |
| 120 | Mount myPLM as Z drive.txt | 69_Mount_MyPLM_Z_Drive.ps1 | TBD | Mounts myPLM share |

---

## Category 16: File Operations Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 121 | Copy Folder with robocopy.txt | 70_Copy_Folder_Robocopy.ps1 | 247 | Copies folders with robocopy |
| 122 | Copy file to Onedrive desktop.txt | 71_Copy_File_To_OneDrive_Desktop.ps1 | 142 | Copies to OneDrive desktop |
| 123 | Delete file or folder.txt | 72_Delete_File_Or_Folder.ps1 | 480 | Deletes files or folders |
| 124 | Download File From URL.txt | 73_Download_File_From_URL.ps1 | 21,891 | Downloads file from URL |
| 125 | copy Azure VPN config to user folder.txt | 74_Copy_Azure_VPN_Config.ps1 | TBD | Copies Azure VPN config |
| 126 | copy file to all desktops.txt | 75_Copy_File_To_All_Desktops.ps1 | TBD | Copies to all user desktops |
| 127 | copy file to folder.txt | 76_Copy_File_To_Folder.ps1 | TBD | Generic file copy operation |

---

## Category 17: Office & Teams Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 128 | Clear Teams Cache.txt | 77_Clear_Teams_Cache.ps1 | 3,528 | Clears Microsoft Teams cache |
| 129 | Office 365 Modern Auth Alert.txt | Script_50_Office_365_Modern_Auth_Monitor.ps1 | TBD | Monitors modern auth status |
| 130 | Report on Large OST and PST Files.txt | Script_51_Large_OST_PST_Monitor.ps1 | TBD | Monitors large Outlook files |
| 131 | close all office applications.txt | 78_Close_All_Office_Applications.ps1 | TBD | Closes Office applications |

---

## Category 18: OneDrive Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 132 | Get-OneDriveConfig.txt | Script_52_OneDrive_Configuration_Monitor.ps1 | 12,901 | Monitors OneDrive config |

---

## Category 19: SAP & Business Application Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 133 | BDE Terminals - Start SAP and Browser.txt | 79_BDE_Start_SAP_Browser.ps1 | 11,967 | Starts SAP and browser |
| 134 | Disable SAP AutomaticUpdate.txt | 80_Disable_SAP_Automatic_Update.ps1 | 106 | Disables SAP auto-update |
| 135 | close SAP & chrome.txt | 81_Close_SAP_Chrome.ps1 | TBD | Closes SAP and Chrome |
| 136 | delete SAP user profiles.txt | 82_Delete_SAP_User_Profiles.ps1 | TBD | Deletes SAP profiles |

---

## Category 20: Cepros Application Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 137 | fix permissions Cepros cdbpc.ini | 83_Fix_Cepros_Permissions.ps1 | TBD | Fixes Cepros file permissions |

---

## Category 21: Remote Management Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 138 | Remote Desktop - Check Status and Port.txt | Script_53_RDP_Status_Port_Monitor.ps1 | TBD | Checks RDP configuration |

---

## Category 22: System Actions Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 139 | Restart a service.txt | 84_Restart_Windows_Service.ps1 | TBD | Restarts specified service |
| 140 | Shutdown Computer.txt | 85_Shutdown_Computer.ps1 | TBD | Shuts down computer |

---

## Category 23: Diagnostics & Information Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 141 | Get Enrollment Status.txt | 86_Get_MDM_Enrollment_Status.ps1 | 1,899 | Gets device enrollment status |
| 142 | Get attached monitors.txt | 87_Get_Attached_Monitors.ps1 | 2,464 | Lists attached displays |
| 143 | Internet Speed Test.txt | Script_54_Internet_Speed_Test_Monitor.ps1 | TBD | Tests internet speed |
| 144 | List Browser Extensions.txt | Script_55_Browser_Extensions_Monitor.ps1 | TBD | Lists installed extensions |
| 145 | Monitor Time difference to NTP server.txt | Script_56_NTP_Time_Drift_Monitor.ps1 | TBD | Monitors time sync |
| 146 | Search DNS Cache Entries.txt | 88_Search_DNS_Cache.ps1 | TBD | Searches DNS cache |
| 147 | Search TCP or UDP Connections for Specified IP Address.txt | 89_Search_Network_Connections.ps1 | TBD | Searches active connections |
| 148 | Search for Listening and Established Ports.txt | 90_Search_Listening_Ports.ps1 | TBD | Lists open ports |
| 149 | Unlicensed Copy of Windows Alert.txt | Script_57_Windows_License_Status_Monitor.ps1 | TBD | Monitors Windows activation |
| 150 | Verify running processes are signed.txt | Script_58_Process_Signature_Monitor.ps1 | TBD | Checks process signatures |
| 151 | get Dell Dockingstation information.txt | 91_Get_Dell_Dock_Information.ps1 | TBD | Gets Dell dock details |

---

## Category 24: Additional Scripts

| # | Current Name | New Name | Size | Description |
|---|--------------|----------|------|-------------|
| 152 | Time Sync - Configure Settings.txt | 92_Configure_Time_Sync_Settings.ps1 | TBD | Configures NTP settings |
| 153 | Troubleshoot Printers and Clear Print Queue.txt | 93_Troubleshoot_Clear_Print_Queue.ps1 | TBD | Clears print queues |
| 154 | Rebuild Search Index.txt | 94_Rebuild_Windows_Search_Index.ps1 | TBD | Rebuilds search index |
| 155 | Treesize Ultimate.txt | 95_Run_TreeSize_Analysis.ps1 | TBD | Runs TreeSize scan |
| 156 | Start Kisters 2025.4.529 Setup | 96_Start_Kisters_Setup.ps1 | TBD | Starts Kisters installer |
| 157 | Update Location Custom Field based on GeoIP.txt | 97_Update_Location_GeoIP.ps1 | TBD | Updates location via GeoIP |
| 158 | Update PowerShell to Version 5.1 | 98_Update_PowerShell_To_51.ps1 | TBD | Updates PowerShell version |
| 159 | TEMPLARE - Invoke as User.txt | TEMPLATE_Invoke_As_User.ps1 | TBD | Template for user context |
| 160 | Script 6 Telemetry Collector.txt | Script_59_Telemetry_Collector.ps1 | TBD | Collects system telemetry |
| 161 | STAT Field Validator .txt | Script_60_STAT_Field_Validator.ps1 | TBD | Validates STAT fields |
| 162 | import Azure VPN config.txt | 99_Import_Azure_VPN_Config.ps1 | TBD | Imports Azure VPN profile |
| 163 | Enable Mini-Dumps for BSOD (Blue Screen).txt | 100_Enable_Mini_Dumps.ps1 | 4,031 | Enables crash dumps |
| 164 | enable minidumps.txt | DELETE_OR_MERGE | TBD | Similar to above - merge/delete |

---

## Summary Statistics

### By Category

| Category | Count | Percentage |
|----------|-------|------------|
| Active Directory | 8 | 4.8% |
| System Monitoring | 11 | 6.7% |
| Security & Compliance | 9 | 5.5% |
| Network | 12 | 7.3% |
| Firewall & Security Policy | 12 | 7.3% |
| Windows Update & Patching | 7 | 4.3% |
| Software Installation | 11 | 6.7% |
| Software Removal | 8 | 4.9% |
| Desktop & User Interface | 12 | 7.3% |
| Server Role Monitoring | 10 | 6.1% |
| Group Policy & Configuration | 4 | 2.4% |
| Event Log | 3 | 1.8% |
| User Management | 9 | 5.5% |
| File Operations | 7 | 4.3% |
| Office & Teams | 4 | 2.4% |
| SAP Applications | 4 | 2.4% |
| Diagnostics & Information | 11 | 6.7% |
| Other | 22 | 13.4% |

### By Type

| Type | Count | Percentage |
|------|-------|------------|
| Monitoring Scripts (Script_XX_) | ~60 | 36.5% |
| Automation Scripts (XX_) | ~100 | 60.9% |
| Templates | 1 | 0.6% |
| Duplicates (to delete) | 3 | 1.8% |

### Action Required

| Action | Count |
|--------|-------|
| Rename Only | 161 |
| Delete (Duplicates) | 3 |
| Total Scripts | 164 |

---

## Export Formats

### CSV Export

A CSV file `plaintext_scripts_rename_mapping.csv` will be generated with:
- OldName
- NewName
- Category
- FileSize
- Description
- Action (Rename/Delete/Merge)
- Priority (High/Medium/Low)

### PowerShell Array

For automated processing:
```powershell
$renameMapping = @(
    @{ Old = "Active Directory - Domain Controller Health Report.txt"; New = "Script_01_Active_Directory_Domain_Controller_Health_Monitor.ps1" },
    @{ Old = "Active Directory - Get OU Members.txt"; New = "01_Active_Directory_Get_OU_Members.ps1" }
    # ... additional entries
)
```

---

## Notes

### Files Requiring Special Attention

1. **Duplicates** - Need immediate resolution before renaming
2. **Templates** - Should be moved to separate template folder
3. **Company-Specific Scripts** - May need customization (Catia, SAP, Cepros, etc.)
4. **Large Files** - Scripts over 50KB should be reviewed for optimization

### Next Steps

1. Review and approve rename mapping
2. Resolve duplicates
3. Execute batch rename
4. Begin code standardization
5. Update documentation references

---

**Document Version:** 1.0  
**Last Updated:** February 9, 2026  
**Total Scripts Inventoried:** 164  
**Ready for Renaming:** 161
