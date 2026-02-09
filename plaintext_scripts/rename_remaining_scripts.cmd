@echo off
echo Renaming remaining .txt files to .ps1 format...
echo.

rem Install Dell Command Update
ren "Install Dell Command & Update.txt" "Software-InstallDellCommandUpdate.ps1"

rem WiFi Report
ren "WiFi Report.txt" "WiFi-GenerateReport.ps1"

rem Windows 11 Upgrade Compatibility
ren "Windows 11 Upgrade Compatibility.txt" "Windows-CheckWin11UpgradeCompatibility.ps1"

rem Windows Update Diagnostic
ren "Windows Update Diagnostic.txt" "WindowsUpdate-RunDiagnostic.ps1"

rem Wired Network Sub 1Gbps Alert
ren "Wired Network Sub 1Gbps Alert.txt" "Network-AlertWiredSub1Gbps.ps1"

rem Block KB5027397
ren "block KB5027397.txt" "WindowsUpdate-BlockKB5027397.ps1"

rem Close SAP and Chrome
ren "close SAP & chrome.txt" "Process-CloseSAPandChrome.ps1"

rem Close all Office applications
ren "close all office applications.txt" "Process-CloseAllOfficeApps.ps1"

rem Copy Azure VPN config to user folder
ren "copy Azure VPN config to user folder.txt" "VPN-CopyAzureConfigToUserFolder.ps1"

rem Copy file to all desktops
ren "copy file to all desktops.txt" "FileOps-CopyFileToAllDesktops.ps1"

rem Copy file to folder
ren "copy file to folder.txt" "FileOps-CopyFileToFolder.ps1"

rem Create Cepros shortcuts and copy to desktops
ren "create cepros shortcuts & copy to desktops.txt" "Shortcuts-CreateCeprosShortcuts.ps1"

rem Create shortcut
ren "create shortcut.txt" "Shortcuts-CreateGenericShortcut.ps1"

rem Delete SAP user profiles
ren "delete SAP user profiles.txt" "SAP-DeleteUserProfiles.ps1"

rem Delete old wifi networks - forklift
ren "delete old wifi networks - forklift.txt" "WiFi-DeleteOldNetworksForklift.ps1"

rem Disable UseWUServer and clear WUServer, WUStatusServer
ren "disable UseWUServer & clear WUServer, WUStatusServer.txt" "WindowsUpdate-DisableWSUSSettings.ps1"

rem Enable minidumps
ren "enable minidumps.txt" "System-EnableMinidumps.ps1"

rem Fix permissions Cepros cdbpc.ini
ren "fix permissions Cepros cdbpc.ini" "Cepros-FixCdbpcIniPermissions.ps1"

rem Get Dell Dockingstation information
ren "get Dell Dockingstation information.txt" "Hardware-GetDellDockInfo.ps1"

rem Get display name from user
ren "get display name from user.txt" "User-GetDisplayName.ps1"

rem Get last Windows Update
ren "get last Windows Update.txt" "WindowsUpdate-GetLastUpdate.ps1"

rem Import Azure VPN config
ren "import Azure VPN config.txt" "VPN-ImportAzureConfig.ps1"

rem Install Azure VPN application package
ren "install azure vpn application package.txt" "VPN-InstallAzureVPNAppPackage.ps1"

rem Install Windows Store application
ren "install windows store application.txt" "Software-InstallWindowsStoreApp.ps1"

rem Join domain
ren "join domain.txt" "AD-JoinDomain.ps1"

rem List all Windows Updates
ren "list all Windows Updates.txt" "WindowsUpdate-ListAllUpdates.ps1"

rem List all installed applications
ren "list all installed applications.txt" "Software-ListInstalledApplications.ps1"

rem Purge SAP GUI
ren "purge SAP GUI.txt" "SAP-PurgeSAPGUI.ps1"

rem Re-register Diamod Server and fix permissions
ren "re-register Diamod Server and fix permissions.txt" "Diamod-ReregisterServerFixPermissions.ps1"

rem Remove CCM client
ren "remove CCM client.txt" "Software-RemoveCCMClient.ps1"

rem Reset Windows updates components
ren "reset Windows updates components.txt" "WindowsUpdate-ResetComponents.ps1"

rem Update CDB server url based on IP location
ren "update CDB server url based on IP location.txt" "Cepros-UpdateCDBServerURL.ps1"

rem Update device location
ren "update device location.txt" "Device-UpdateLocation.ps1"

echo.
echo Renaming complete!
echo.
echo Summary:
echo - 33 files renamed to proper .ps1 format
echo - All files now follow Category-ActionDescription.ps1 naming convention
echo.
pause
