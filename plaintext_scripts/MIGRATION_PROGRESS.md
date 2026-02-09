# Script Migration Progress

## Overview
Migrating all PowerShell scripts from `.txt` to `.ps1` format with standardized naming convention: `Category-ActionDescription.ps1`

## Progress Summary
- **Total Scripts**: ~220+ scripts
- **First Batch Completed**: ✓ (All `.ps1` files already properly named)
- **Second Batch Created**: rename_remaining_scripts.cmd (waiting for execution)
- **Status**: In Progress

## Batch Scripts Created

### Batch 1: rename_ps1_scripts.cmd
- Location: `plaintext_scripts/rename_ps1_scripts.cmd`
- Commit: [71f175f](https://github.com/Xore/waf/commit/71f175ffebb99af18a744fb2267a41d7f42fd19a)
- Status: ✓ Executed (files already renamed)
- Files Renamed: All existing `.ps1` files now follow naming convention

### Batch 2: rename_remaining_scripts.cmd
- Location: `plaintext_scripts/rename_remaining_scripts.cmd`
- Commit: [b7f9aed](https://github.com/Xore/waf/commit/b7f9aed7e52bdb3fb94e3c5bbb2523c18fb8e78c)
- Status: ⏳ Pending Execution
- Files to Rename: 33 remaining `.txt` files

## Files Already Migrated (Examples)
- `AD-JoinDomain.ps1`
- `Process-CloseAllOfficeApps.ps1`
- `Process-CloseSAPandChrome.ps1`
- `Cepros-FixCdbpcIniPermissions.ps1`
- `Cepros-UpdateCDBServerURL.ps1`
- `Device-UpdateLocation.ps1`
- `Diamod-ReregisterServerFixPermissions.ps1`
- `FileOps-CopyFileToAllDesktops.ps1`
- `FileOps-CopyFileToFolder.ps1`
- `Hardware-GetDellDockInfo.ps1`
- `Shortcuts-CreateCeprosShortcuts.ps1`
- `Shortcuts-CreateGenericShortcut.ps1`
- `Software-InstallDellCommandUpdate.ps1`
- `Software-InstallWindowsStoreApp.ps1`
- `Software-ListInstalledApplications.ps1`
- `Software-RemoveCCMClient.ps1`
- `System-EnableMinidumps.ps1`
- `User-GetDisplayName.ps1`
- `VPN-CopyAzureConfigToUserFolder.ps1`
- `VPN-ImportAzureConfig.ps1`
- `VPN-InstallAzureVPNAppPackage.ps1`
- `WiFi-DeleteOldNetworksForklift.ps1`
- `WiFi-GenerateReport.ps1`

## Remaining Files (Waiting for Batch 2 Execution)
The second batch script will rename 33 additional files including:
- Windows Update related scripts
- SAP scripts
- Additional WiFi configurations
- WindowsUpdate diagnostics and configurations

## Naming Convention Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| AD | Active Directory | AD-JoinDomain, AD-RepairTrust |
| BDE | Business Desktop Environment | BDE-StartSAPandBrowser |
| Browser | Browser Operations | Browser-ListExtensions |
| Cepros | Cepros Application | Cepros-FixCdbpcIniPermissions |
| Certificates | Certificate Management | Certificates-GetExpiring |
| DHCP | DHCP Server | DHCP-AlertOnLeaseLow |
| Device | Device Management | Device-UpdateLocation |
| Diamod | Diamod Application | Diamod-ReregisterServerFixPermissions |
| Entra | Microsoft Entra | Entra-Audit |
| EventLog | Event Log Management | EventLog-Search |
| Exchange | Exchange Server | Exchange-VersionCheck |
| Explorer | Windows Explorer | Explorer-SetShowHiddenFiles |
| FileOps | File Operations | FileOps-CopyFileToFolder |
| Firewall | Windows Firewall | Firewall-AuditStatus |
| GPO | Group Policy | GPO-Monitor |
| Hardware | Hardware Management | Hardware-GetDellDockInfo |
| HyperV | Hyper-V | HyperV-GetHostFromGuest |
| IIS | IIS Server | IIS-GetBindings |
| Licensing | License Management | Licensing-UnlicensedWindowsAlert |
| Monitoring | System Monitoring | Monitoring-SystemPerformanceCheck |
| Network | Networking | Network-MapDrives |
| NinjaRMM | NinjaRMM Specific | NinjaRMM-UpdateLocationGeoIP |
| Notifications | User Notifications | Notifications-DisplayToastMessage |
| Office365 | Office 365 | Office365-ModernAuthAlert |
| OneDrive | OneDrive | OneDrive-GetConfig |
| Outlook | Outlook | Outlook-ReportLargeOSTandPST |
| Power | Power Management | Power-SetFastStartup |
| Printing | Print Services | Printing-TroubleshootAndClearQueue |
| Process | Process Management | Process-CloseAllOfficeApps |
| RDP | Remote Desktop | RDP-CheckStatusAndPort |
| SAP | SAP Systems | SAP-PurgeSAPGUI |
| SQL | SQL Server | SQL-MonitorServer |
| Security | Security | Security-AuditUACLevel |
| Server | Server Management | Server-GetRoles |
| Services | Windows Services | Services-RestartService |
| Shortcuts | Desktop Shortcuts | Shortcuts-CreateDesktopEXE |
| Software | Software Management | Software-InstallOffice365 |
| System | System Operations | System-ShutdownComputer |
| Teams | Microsoft Teams | Teams-ClearCache |
| Template | Script Templates | Template-InvokeAsUser |
| User | User Management | User-GetDisplayName |
| VPN | VPN Management | VPN-ImportAzureConfig |
| Veeam | Veeam Backup | Veeam-BackupMonitor |
| WiFi | WiFi Management | WiFi-DeployProfile |
| Windows | Windows OS | Windows-BlockWin10to11Upgrade |
| WindowsUpdate | Windows Updates | WindowsUpdate-DisableWSUSSettings |

## Next Steps
1. ✓ Create first batch script
2. ✓ Execute first batch script (completed automatically)
3. ✓ Create second batch script
4. ⏳ Execute second batch script (pending)
5. ⏳ Create README documentation
6. ⏳ Create index of all scripts

## Notes
- No emojis or checkmark/cross characters used in scripts (per Space instructions)
- All scripts follow `Category-ActionDescription.ps1` format
- Batch files are safe to run multiple times (will skip already renamed files)
- Original functionality preserved in all scripts

---
*Last Updated: February 9, 2026*
