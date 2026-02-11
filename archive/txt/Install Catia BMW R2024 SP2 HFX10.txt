@ECHO OFF
TITLE TECHNIA CATIA INSTALLATION

REM ------------------------------------------------------------------
REM VARIABLE DEFINITION
REM ------------------------------------------------------------------
SET CATIA_ID=R2024SP2BMW
SET CATIA_REL=R2024
SET CATIA_SP=SP2
SET CATIA_HFX=HFX10
SET CATIA_PATH=C:\CATIAV5\R2024SP2_BMW
SET MEDIA_REPO=C:\Temp\catia
SET LOG_FILE_DIR=C:\Temp
SET LOG_FILE=%LOG_FILE_DIR%\CATIA_%CATIA_ID%.log


REM ------------------------------------------------------------------
REM CREATE DIRECTORY FOR LOGFILE
REM ------------------------------------------------------------------
IF NOT EXIST %LOG_FILE_DIR% MD %LOG_FILE_DIR%


REM ------------------------------------------------------------------
REM WRITE LOG FILE HEADER
REM ------------------------------------------------------------------
ECHO #--------------------------------------------------------# 		>%LOG_FILE% 2>&1 
ECHO # LOGFILE ( %date:~0% - %time:~0,8% Uhr )							>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO.					 												>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION SETTINGS: 											>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO CATIA_ID=%CATIA_ID% 												>>%LOG_FILE% 2>&1 
ECHO CATIA_REL=%CATIA_REL% 												>>%LOG_FILE% 2>&1 
ECHO CATIA_SP=%CATIA_SP% 												>>%LOG_FILE% 2>&1 
ECHO CATIA_HFX=%CATIA_HFX% 												>>%LOG_FILE% 2>&1 
ECHO CATIA_PATH=%CATIA_PATH% 											>>%LOG_FILE% 2>&1 
ECHO MEDIA_REPO=%MEDIA_REPO% 											>>%LOG_FILE% 2>&1 
ECHO LOG_FILE=%LOG_FILE% 												>>%LOG_FILE% 2>&1



REM ------------------------------------------------------------------
REM SHOW PARAMETERS IN CONSOLE
REM ------------------------------------------------------------------
ECHO #--------------------------------------------------------#
ECHO # INSTALLATION SETTINGS:
ECHO #--------------------------------------------------------#
ECHO CATIA_ID=%CATIA_ID%
ECHO CATIA_REL=%CATIA_REL%
ECHO CATIA_SP=%CATIA_SP%
ECHO CATIA_HFX=%CATIA_HFX%
ECHO CATIA_PATH=%CATIA_PATH%
ECHO MEDIA_REPO=%MEDIA_REPO%
ECHO LOG_FILE=%LOG_FILE%


REM ------------------------------------------------------------------
REM SWITCH TO MEDIA REPOSITORY
REM ------------------------------------------------------------------
PUSHD %MEDIA_REPO%


REM ------------------------------------------------------------------
REM INSTALL CATIA GA CODE P2
REM ------------------------------------------------------------------
ECHO.					 												>>%LOG_FILE% 2>&1 
IF NOT EXIST %CATIA_REL%_GA_P2_64bit (
	ECHO %CATIA_REL%_GA_P2_64bit NOT FOUND!								>>%LOG_FILE% 2>&1 
	GOTO GA_P1
	)

ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% GA CODE P2 					>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------#			>>%LOG_FILE% 2>&1
ECHO CD %CATIA_REL%_GA_P2_64bit\win64 									>>%LOG_FILE% 2>&1 
ECHO StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -D %CATIA_PATH%\CATEnv -newdir -all -noreboot -noDesktopIcon >>%LOG_FILE% 2>&1 

ECHO #--------------------------------------------------------#
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% GA CODE P2
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
CD %CATIA_REL%_GA_P2_64bit\win64
StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -D %CATIA_PATH%\CATEnv -newdir -all -noreboot -noDesktopIcon
TIMEOUT 3 >NUL
CD ..\..


:GA_P1
REM ------------------------------------------------------------------
REM INSTALL CATIA GA CODE P1
REM ------------------------------------------------------------------
ECHO.					 												>>%LOG_FILE% 2>&1 
IF NOT EXIST %CATIA_REL%_GA_P1_64bit (
	ECHO %CATIA_REL%_GA_P1_64bit NOT FOUND! 							>>%LOG_FILE% 2>&1 
	GOTO GA_VX1
	) 

ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% GA CODE P1 					>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1
ECHO CD %CATIA_REL%_GA_P1_64bit\win64 									>>%LOG_FILE% 2>&1
ECHO StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -D %CATIA_PATH%\CATEnv -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon >>%LOG_FILE% 2>&1

ECHO #--------------------------------------------------------#
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% GA Code P1
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
CD %CATIA_REL%_GA_P1_64bit\win64
StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -D %CATIA_PATH%\CATEnv -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon
TIMEOUT 3 >NUL
CD ..\..


:GA_VX1
REM ------------------------------------------------------------------
REM INSTALL CATIA GA CODE VX1
REM ------------------------------------------------------------------
ECHO.					 												>>%LOG_FILE% 2>&1 
IF NOT EXIST %CATIA_REL%_GA_VX1_64bit (
	ECHO %CATIA_REL%_GA_VX1_64bit NOT FOUND! 							>>%LOG_FILE% 2>&1 
	GOTO GA_E3
	)

ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% GA CODE VX1 					>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO CD %CATIA_REL%_GA_VX1_64bit\win64 									>>%LOG_FILE% 2>&1 
ECHO StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -D %CATIA_PATH%\CATEnv -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon >>%LOG_FILE% 2>&1 

ECHO #--------------------------------------------------------#
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% GA CODE VX1
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
CD %CATIA_REL%_GA_VX1_64bit\win64
StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -D %CATIA_PATH%\CATEnv -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon
TIMEOUT 3 >NUL
CD ..\..


:GA_E3
REM ------------------------------------------------------------------
REM INSTALL CATIA GA CODE E3
REM ------------------------------------------------------------------
ECHO.					 												>>%LOG_FILE% 2>&1 
IF NOT EXIST %CATIA_REL%_GA_E3_64bit (
	ECHO %CATIA_REL%_GA_E3_64bit NOT FOUND! 							>>%LOG_FILE% 2>&1
	GOTO GA_MULTI
	)

ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% GA CODE E3 					>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1
ECHO CD %CATIA_REL%_GA_E3_64bit\win64 									>>%LOG_FILE% 2>&1
ECHO StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -D %CATIA_PATH%\CATEnv -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon >>%LOG_FILE% 2>&1

ECHO #--------------------------------------------------------#
ECHO  INSTALLATION: CATIA V5 %CATIA_REL% GA CODE E3
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
CD %CATIA_REL%_GA_E3_64bit\win64
StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -D %CATIA_PATH%\CATEnv -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon
TIMEOUT 3 >NUL
CD ..\..


:GA_MULTI
REM ------------------------------------------------------------------
REM INSTALL CATIA GA CODE MULTICAX
REM ------------------------------------------------------------------
ECHO.					 												>>%LOG_FILE% 2>&1 
IF NOT EXIST MultiCAX_%CATIA_REL%_64bit (
	ECHO %CATIA_REL%_GA_MultiCAX_64bit NOT FOUND! 						>>%LOG_FILE% 2>&1
	GOTO GA_DMU
	)

ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% MULTICAX CODE 				>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO CD MultiCAX_%CATIA_REL%_64bit\win64 								>>%LOG_FILE% 2>&1 
ECHO StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon >>%LOG_FILE% 2>&1 

ECHO #--------------------------------------------------------#
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% MULTICAX CODE
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
CD MultiCAX_%CATIA_REL%_64bit\win64
StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon
TIMEOUT 3 >NUL
CD ..\..


:GA_DMU
REM ------------------------------------------------------------------
REM INSTALL CATIA GA CODE DMU
REM ------------------------------------------------------------------
ECHO.					 												>>%LOG_FILE% 2>&1 
IF NOT EXIST %CATIA_REL%_GA_DMU_64bit (
	ECHO %CATIA_REL%_GA_DMU_64bit NOT FOUND! 							>>%LOG_FILE% 2>&1 
	GOTO SP
	)

ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% DMU CODE 						>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO CD %CATIA_REL%_GA_DMU_64bit\win64 									>>%LOG_FILE% 2>&1
ECHO StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon >>%LOG_FILE% 2>&1

ECHO #--------------------------------------------------------#
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% DMU CODE
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
CD %CATIA_REL%_GA_DMU_64bit\win64
StartB.exe -ident %CATIA_ID% -v -u %CATIA_PATH% -all -noreboot -noDesktopIcon -noStartMenuTools -noStartMenuIcon
TIMEOUT 3 >NUL
CD ..\..


:SP
REM ------------------------------------------------------------------
REM INSTALL CATIA SERVICEPACK
REM ------------------------------------------------------------------
ECHO.					 												>>%LOG_FILE% 2>&1 
IF NOT EXIST %CATIA_REL%_%CATIA_SP%_64bit (
	ECHO %CATIA_REL%_%CATIA_SP%_64bit NOT FOUND 						>>%LOG_FILE% 2>&1
	GOTO VBA				
	)				
				
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% %CATIA_SP% 					>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO CD %CATIA_REL%_%CATIA_SP%_64bit\win64 								>>%LOG_FILE% 2>&1 
ECHO StartSPKB.exe -v -bC -u %CATIA_PATH% -killprocess 					>>%LOG_FILE% 2>&1 

ECHO #--------------------------------------------------------#
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% %CATIA_SP%
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
CD %CATIA_REL%_%CATIA_SP%_64bit\win64
StartSPKB.exe -v -bC -u %CATIA_PATH% -killprocess
TIMEOUT 3 >NUL
CD ..\..


:HFX
REM ------------------------------------------------------------------
REM INSTALL CATIA HOTFIX
REM ------------------------------------------------------------------
ECHO.					 												>>%LOG_FILE% 2>&1 
IF NOT EXIST %CATIA_REL%_%CATIA_SP%_%CATIA_HFX%_64bit (
	ECHO %CATIA_REL%_%CATIA_SP%_%CATIA_HFX%_64bit NOT FOUND! 			>>%LOG_FILE% 2>&1 
	GOTO VBA
	)

ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% %CATIA_SP% %CATIA_HFX% 		>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO CD %CATIA_REL%_%CATIA_SP%_%CATIA_HFX%_64bit\win64 					>>%LOG_FILE% 2>&1 
ECHO Starthfxb -v -killprocess -u %CATIA_PATH% 							>>%LOG_FILE% 2>&1 

ECHO #--------------------------------------------------------#
ECHO # INSTALLATION: CATIA V5 %CATIA_REL% %CATIA_SP% %CATIA_HFX%
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
CD %CATIA_REL%_%CATIA_SP%_%CATIA_HFX%_64bit\win64
%CATIA_PATH%\win_b64\code\bin\CATSoftwareMgtB.exe -hfxR -killprocess
Starthfxb -v -killprocess -u %CATIA_PATH%
TIMEOUT 3 >NUL
CD ..\..


:VBA
REM ------------------------------------------------------------------
REM INSTALL VBA 6
REM ------------------------------------------------------------------
IF EXIST %MEDIA_REPO%\%CATIA_REL%_GA_P2_64bit\VBA\vba6.msi (
	ECHO.				 												>>%LOG_FILE% 2>&1 
	ECHO #--------------------------------------------------------# 	>>%LOG_FILE% 2>&1
	ECHO # INSTALLATION: VISUAL BASIC 6                            		>>%LOG_FILE% 2>&1
	ECHO #                                                        # 	>>%LOG_FILE% 2>&1
	ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ # 	>>%LOG_FILE% 2>&1
	ECHO #--------------------------------------------------------# 	>>%LOG_FILE% 2>&1
	ECHO MSIEXEC /q /i %MEDIA_REPO%\%CATIA_REL%_GA_P2_64bit\VBA\vba6.msi >>%LOG_FILE% 2>&1

	ECHO #--------------------------------------------------------#
	ECHO # INSTALLATION: VISUAL BASIC 6                           #
	ECHO #                                                        #
	ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
	ECHO #--------------------------------------------------------#
	MSIEXEC /q /i %MEDIA_REPO%\%CATIA_REL%_GA_P2_64bit\VBA\vba6.msi
)

REM ------------------------------------------------------------------
REM INSTALL VBA 7
REM ------------------------------------------------------------------
IF EXIST %MEDIA_REPO%\%CATIA_REL%_GA_P2_64bit\VBA\DSVBA71Installer.exe (
	ECHO.				 												>>%LOG_FILE% 2>&1 
	ECHO #--------------------------------------------------------# 	>>%LOG_FILE% 2>&1
	ECHO # INSTALLATION: VISUAL BASIC 7                            		>>%LOG_FILE% 2>&1 
	ECHO #                                                        # 	>>%LOG_FILE% 2>&1
	ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ # 	>>%LOG_FILE% 2>&1
	ECHO #--------------------------------------------------------# 	>>%LOG_FILE% 2>&1
	ECHO %MEDIA_REPO%\%CATIA_REL%_GA_P2_64bit\VBA\DSVBA71Installer.exe /quiet /install /log %LOG_FILE_DIR%\VBA_INSTALL.log >>%LOG_FILE% 2>&1
	
	ECHO #--------------------------------------------------------#
	ECHO # INSTALLATION: VISUAL BASIC 7
	ECHO #                                                        #
	ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
	ECHO #--------------------------------------------------------#
	%MEDIA_REPO%\%CATIA_REL%_GA_P2_64bit\VBA\DSVBA71Installer.exe /quiet /install /log %LOG_FILE_DIR%\VBA_INSTALL.log
)


:CLEANUP
REM ------------------------------------------------------------------
REM CLEANUP
REM ------------------------------------------------------------------
ECHO.				 													>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CLEANUP 											>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO DEL /F %PUBLIC%\DESKTOP\CATIA*.lnk 								>>%LOG_FILE% 2>&1

ECHO #--------------------------------------------------------# 
ECHO # INSTALLATION: CLEANUP
ECHO #--------------------------------------------------------#
DEL /F %PUBLIC%\DESKTOP\CATIA*.lnk


:REPORT
REM ------------------------------------------------------------------
REM CREATE REPORT
REM ------------------------------------------------------------------
ECHO.				 													>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO # INSTALLATION: CREATE REPORT 										>>%LOG_FILE% 2>&1 
ECHO #--------------------------------------------------------# 		>>%LOG_FILE% 2>&1 
ECHO %CATIA_PATH%\win_b64\code\bin\CATSoftwareMgtB.exe -L -o %CATIA_PATH%\InstLevel.txt >>%LOG_FILE% 2>&1 

ECHO #--------------------------------------------------------#
ECHO # INSTALLATION: CREATE REPORT
ECHO #                                                        #
ECHO # ------------ PLEASE WAIT FOR COMPLETION!! ------------ #
ECHO #--------------------------------------------------------#
%CATIA_PATH%\win_b64\code\bin\CATSoftwareMgtB.exe -L -o %CATIA_PATH%\InstLevel.txt



:EXIT
REM ------------------------------------------------------------------
REM DISCONNECT MEDIA REPOSITORY
REM ------------------------------------------------------------------
POPD