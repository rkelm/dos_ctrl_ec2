@ECHO OFF
REM Batch file to create package for distribution to users.
SET LOCAL_DIR=dos_ctrl_ec2\
SET DSTFILENAME=build\dos_ctrl_ec2.zip

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%
REM Switch current directory to installation directory.
CD /D %~dp0

REM Remove old package if it exists.
IF EXIST %DSTFILENAME% (
	DEL %DSTFILENAME%
) 
REM Move up one directory level.
CD ..

ECHO Creating deployment package %DSTFILENAME%
C:\Programme\7-Zip\7z.exe a %LOCAL_DIR%%DSTFILENAME% @%LOCAL_DIR%build_file_list.txt

IF ERRORLEVEL 1 (
	ECHO Error creating deployment package.
	) ELSE (
	ECHO Successfully created deployment package.
	)
	
REM Restore previous current directory.
CD /D %EXCURRENTDIR%

PAUSE

