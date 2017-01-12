@ECHO OFF
REM Batch file to terminate ec2 instance.

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

REM Simple Check: "Is an instance running?"
IF NOT EXIST %INSTIDFILE% (
   REM Check for running instance by searching for tag in aws cloud.
   ECHO Suche Instanzen mit Tag %TAGKEY% = %TAGVALUE% und Status running.
   aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
   REM Delete instance id file if it is empty.
   for %%F in ("%INSTIDFILE%") do if %%~zF equ 0 del "%%F"
   IF NOT EXIST %INSTIDFILE% (
		ECHO Es läuft keine Minecraft Server Instanz, die beendet werden kann.
		PAUSE
		EXIT /b 1
		)
   )

set /P INSTANCEID=<%INSTIDFILE%

REM Terminate instance.
ECHO Beende AWS EC2 Instanz mit ID %INSTANCEID%.
aws ec2 terminate-instances --instance-ids %INSTANCEID% > terminate.json

ECHO %DATE% %TIME% Beende AWS EC2 Instanz mit ID %INSTANCEID% >> dos_ctrl_ec2.log

REM Wait for end of Termination.
ECHO Warte auf Abschluss der Terminierung ...
aws ec2 wait instance-terminated --instance-ids %INSTANCEID%

ECHO Die Instanz ist terminiert.

REM Send notice about terminated instance.
IF NOT [%SNS_TOPIC_ARN%] == [] (
  aws sns publish --topic-arn "%SNS_TOPIC_ARN%" --subject "Minecraft Server mit Instanz ID %INSTANCEID% beendet" --message "Minecraft Server beendet, Instanz ID %INSTANCEID%." --output text > messageid.txt
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
  
PAUSE

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
