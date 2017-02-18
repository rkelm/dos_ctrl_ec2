@ECHO ON
REM Batch file to launch ec2 instance.
SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

REM Check if the default config file and instanceid.txt should be used.
IF [%1] == [] (
	SET CONFIGFILE=ec2_config_default.bat
    SET INSTIDFILE=instanceid.txt
) ELSE (
	SET CONFIGFILE=config\ec2_config_%1.bat
    SET INSTIDFILE=instanceid_%1.txt
)

REM Check if config file exists. If not complain.
IF NOT EXIST %CONFIGFILE% (
	ECHO Konfigurationsdatei %CONFIGFILE% nicht gefunden.
	EXIT /b 1
	)
	
REM Load configuration variables.
CALL %CONFIGFILE%

REM Check for running instance by searching for tag in aws cloud.
aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
REM Delete instance id file if it is empty.
for %%F in ("%INSTIDFILE%") do if %%~zF equ 0 del "%%F"
IF EXIST %INSTIDFILE% (
	ECHO Es läuft bereits eine %APP_NAME% Server Instanz!
	ECHO Ein neuer Snapshot kann nur bei terminierter Instanz erstellt werden.
	ECHO Bitte erst die alte Instanz beenden.
	EXIT /b 1
)

REM Create new snapshot.
aws ec2 create-snapshot --volume-id %VOLUMEID% --description "%1 %APP_NAME% Snapshot created %DATE% %TIME%." --output text --query VolumeSize > output.txt

IF NOT ERRORLEVEL 1 (
	SET VOLUMESIZE=EMPTY
	SET /P VOLUMESIZE=<output.txt
	ECHO Snapshot erstellt, Größe !VOLUMESIZE! GByte.
)

REM Restore previous current directory.
CD /D %EXCURRENTDIR%

