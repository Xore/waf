C:\Windows\CCMSetup\CCMSetup.exe /uninstall

reg delete "HKLM\SOFTWARE\Microsoft\CCM" /f
reg delete "HKLM\SOFTWARE\Microsoft\SMS" /f

rmdir /s /q "C:\Windows\CCM"
rmdir /s /q "C:\Windows\CCMSetup"

del /f /q "C:\Windows\SMSCFG.ini"

winmgmt /salvagerepository