@ECHO OFF
REM Batch file to terminate ec2 instance.
SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

SET _CONFIG=%1
IF NOT DEFINED _CONFIG (
  ECHO Es muss ein Konfigurationskuerzel als Parameter angegeben werden.
  EXIT /B 1
)
SET CONFIGFILE=config\ec2_config_%_CONFIG%.bat
SET INSTIDFILE=instanceid_%CONFIG%.txt

REM Check if config file exists. If not complain.
IF NOT EXIST %CONFIGFILE% (
	ECHO Konfigurationsdatei %CONFIGFILE% nicht gefunden.
	EXIT /b 1
)

REM Load configuration variables.
CALL %CONFIGFILE%

REM Check for running instance by searching for tag in aws cloud.
ECHO Suche Instanzen mit Tag %TAGKEY% = %TAGVALUE% und Status running.
aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
REM Delete instance id file if it is empty.
FOR %%F IN ("%INSTIDFILE%") DO IF %%~zF equ 0 DEL "%%F"
IF NOT EXIST %INSTIDFILE% (
	ECHO Es laeuft keine %APP_NAME% Instanz, die beendet werden koennte.
	EXIT /B 1
)

SET /P INSTANCEID=<%INSTIDFILE%

REM Terminate instance.
ECHO Beende AWS EC2 Instanz mit ID %INSTANCEID%.
aws ec2 terminate-instances --instance-ids %INSTANCEID% > terminate.json

ECHO %DATE% %TIME% Beende AWS EC2 Instanz mit ID %INSTANCEID% >> dos_ctrl_ec2.log

REM Wait for end of Termination.
ECHO Warte auf Abschluss der Terminierung ...
aws ec2 wait instance-terminated --instance-ids %INSTANCEID%

IF NOT ERRORLEVEL 1 (
	ECHO Die Instanz ist terminiert.
	REM Send notice about terminated instance.
	IF NOT [%SNS_TOPIC_ARN%] == [] (
		aws sns publish --topic-arn "%SNS_TOPIC_ARN%" --subject "BEENDE %APP_NAME% Server mit Instanz ID %INSTANCEID%" --message "Beende %APP_NAME% Server mit Instanz ID %INSTANCEID%. (%DATE% %TIME%)" --output text > messageid.txt
	)
)

IF [%1] == [] (
	IF EXIST instanceid_bak.txt (
		DEL instanceid_bak.txt
	)
	RENAME instanceid.txt instanceid_bak.txt
) ELSE (
	IF EXIST instanceid_bak_%1.txt (
		DEL instanceid_bak_%1.txt
	)
	RENAME instanceid_%1.txt instanceid_bak_%1.txt
)

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
