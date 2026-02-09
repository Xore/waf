@echo off
if exist "C:\Temp\Catia\Uninstall.bat" del "C:\Temp\Catia\Uninstall.bat"
Copy "C:\CATIAV5\R2024SP2_BMW\win_b64\Uninstall.bat"  "C:\Temp\Catia\Uninstall.bat" 1>nul 2>nul
"C:\Temp\Catia\Uninstall.bat" 2>nul