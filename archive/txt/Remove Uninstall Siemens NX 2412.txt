start "" /b /wait MsiExec.exe /X{F56493C9-7EDE-4664-8675-203572276A2A} /q
rmdir /s /q "C:\Program Files\Siemens\NX2412"

if %ERRORLEVEL%==0 (
    echo erfolgreich oder mit akzeptablen Warnungen beendet. (ERRORLEVEL: %ERRORLEVEL%)
    exit /b 0
) else (
    echo FEHLER! (ERRORLEVEL: %ERRORLEVEL%)
    exit /b %ERRORLEVEL%
)