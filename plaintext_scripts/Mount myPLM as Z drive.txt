net use z: \\de.mgp.int\FS\myPLM

if %ERRORLEVEL%==0 (
    echo Drive mapped successfully!
    exit /b 0
) else (
    echo Failed to map drive.
    exit /b %ERRORLEVEL%
)