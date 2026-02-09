if not exist C:\TEMP mkdir C:\TEMP
set TMP=C:\Temp

REM set UGS_LICENSE_SERVER=28000@bielic02
set SPLM_LICENSE_SERVER=28000@bielic02
REM set UGII_BASE_DIR=C:\NX\NX2412_MB
REM set UGII_ROOT_DIR=C:\NX\NX2412_MB

Set INSTALLDIR="C:\Program Files\Siemens\NX2412"
Set SETUPFILE="C:\Temp\NX\SiemensNX.msi"
Set LOGFILE="C:\Temp\NX2412_MB_Daimler_Install.log"
Set LICENSESERVER=%SPLM_LICENSE_SERVER%
Set LANGUAGE=english
Set SETUPTYPE=typical
Set ADDLOCAL=all

IF EXIST %INSTALLDIR% (
 rmdir /q /s  %INSTALLDIR%
)

start "" /b /wait "msiexec.exe"  /qn /L* %LOGFILE% /i %SETUPFILE% ADDLOCAL=%ADDLOCAL% SETUPTYPE=%SETUPTYPE% LANGUAGE=%LANGUAGE% LICENSESERVER=%LICENSESERVER% INSTALLDIR=%INSTALLDIR%

if %ERRORLEVEL% lss 8 (
    echo erfolgreich oder mit akzeptablen Warnungen beendet. (ERRORLEVEL: %ERRORLEVEL%)
    exit /b 0
) else (
    echo FEHLER! (ERRORLEVEL: %ERRORLEVEL%)
    exit /b %ERRORLEVEL%
)