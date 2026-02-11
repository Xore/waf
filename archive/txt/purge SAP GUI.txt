@ECHO off
echo  uninstall previous SAP GUI 8.00 PL8 versions

taskkill /F /IM saplogon.exe
echo SAP ist geschlossen, De-Installation wird jetzt gestartet.
echo Bitte warten bis das Fenster geschlossen ist... 
echo uninstall SAP allgemein
"C:\Program Files\SAP\SAPsetup\Setup\NwSapSetup.exe" /product:"SAPWUS" /uninstall /silent /quiet /noRestart
"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /product:"SCRIPTED" /uninstall /silent /quiet /noRestart

echo uninstall SAP 7.30
"C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" /uninstall /silent /quiet /product="ECL710+SAPDTS+BW350+KW710+GUI710ISHMED+GUI710TWEAK+JNet+SAPGUI710" /TitleComponent:"SAPGUI710" /IgnoreMissingProducts
"C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" /product:"ECL710" /uninstall /silent /quiet

echo uninstall SAP 7.40
"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /uninstall /silent /product="SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts

echo uninstall SAP 7.50
"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /uninstall /silent /quiet /product="SRX+SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts
"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /uninstall /silent /quiet /product="SCRIPTED+SCE+ECL+SAPDTS+KW+GUIISHMED+JNet+NWBCGUI+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts

echo uninstall SAP 7.60
"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /uninstall /silent /quiet /product="SCRIPTED+SCE+SAPDTS+KW+GUIISHMED+JNet+CALSYNC+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts
"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /product:"SCRIPTED" /uninstall /silent /quiet /noRestart
rd "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\SAP Front End" /S /Q

echo uninstall SAP 8.0
"C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" /product:"SCRIPTED" /uninstall /silent /quiet /noRestart

"C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" /uninstall /silent /quiet /product="SCRIPTED+SCE+SAPDTS+KW+GUIISHMED+JNet+CALSYNC+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts

"C:\Program Files\SAP\SAPsetup\setup\NwSapSetup.exe" /uninstall /silent /quiet /product="PdfPrintGui64+SCRIPTED64+KW64+GUIISHMED64+CALSYNC64+RFC64+SAPGUI64" /TitleComponent:"SAPGUI64" /IgnoreMissingProducts

"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /silent /uninstall /product="PdfPrintGui64+SCRIPTED64+KW64+GUIISHMED64+CALSYNC64+RFC64+SAPGUI64" /TitleComponent:"SAPGUI64" /IgnoreMissingProducts

"C:\Program Files (x86)\SAP\SAPsetup\setup\nwsapsetup.exe" /product:"PdfPrintGui64" /uninstall /silent

"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /product:"SCRIPTED" /uninstall /noRestart /silent

"C:\Program Files (x86)\SAP\SAPsetup\setup\NwSapSetup.exe" /silent /uninstall /product="SCRIPTED+SCE+SAPDTS+KW+GUIISHMED+JNet+CALSYNC+SAPGUI" /TitleComponent:"SAPGUI" /IgnoreMissingProducts

cls
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\SAP" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\SAP" /f
@for /f "delims=" %%i in ('dir /aD /b /s "%Userprofile%\..\Roaming"') do rd /q /s %%~si\SAP

rd "c:\SAPconfig" /S /Q
del "C:\windows\SAPUILandscape.xml" /F /Q 
del "C:\Users\Public\Desktop\SAP Logon.lnk" /F /Q 
del "C:\Users\Public\Desktop\SAP Logon 64.lnk" /F /Q 