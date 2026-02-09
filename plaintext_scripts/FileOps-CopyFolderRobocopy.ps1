robocopy %fromPath% %toPath% /E /mt /r:5

if %ERRORLEVEL% lss 8 (
    echo erfolgreich oder mit akzeptablen Warnungen beendet. (ERRORLEVEL: %ERRORLEVEL%)
    exit /b 0
) else (
    echo FEHLER! (ERRORLEVEL: %ERRORLEVEL%)
    exit /b %ERRORLEVEL%
)