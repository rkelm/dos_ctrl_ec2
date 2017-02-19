@ECHO OFF
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
	EXIT /B 1
	)
	
REM Load configuration variables.
CALL %CONFIGFILE%

REM Check: "Is the last from this client startet instance still running?"
IF EXIST %INSTIDFILE% (
	REM Load old instance id from file.
	SET INSTANCEID=EMPTY
	SET /P INSTANCEID=<%INSTIDFILE%

	IF NOT [!INSTANCEID!] == [EMPTY] (
		REM Ask aws if this is a known running/pending/shutting-down instance.
		aws ec2 describe-instances --filters Name=instance-state-name,Values=running,shutting-down,pending Name=instance-id,Values=!INSTANCEID! --output=text --query Reservations[*].Instances[*].InstanceId > output.txt
		SET OUTPUT=EMPTY
		SET /P OUTPUT=<output.txt
		IF NOT [!OUTPUT!] == [EMPTY] (
			REM Instance ist still running. Complain to user and exit.
			ECHO Es läuft bereits eine %APP_NAME% Server Instanz!
			ECHO Start einer neuen Instanz wird abgebrochen.
			ECHO Bitte erst die alte Instanz beenden.
			EXIT /b 1
		)
    )
)

REM Check for running instance by searching for tag in aws cloud.
aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
REM Delete instance id file if it is empty.
for %%F in ("%INSTIDFILE%") do if %%~zF equ 0 del "%%F"
IF EXIST %INSTIDFILE% (
  ECHO Es läuft bereits eine %APP_NAME% Server Instanz!
  ECHO Start einer neuen Instanz wird abgebrochen.
  ECHO Bitte erst die alte Instanz beenden.
  EXIT /b 1
)

REM Prepare optional run-instances parameters.
IF NOT [%SECURITYGROUPSID%] == [] SET SECURITYGROUPSID_PARAM=--security-group-ids %SECURITYGROUPSID%
IF NOT [%SUBNETID%] == [] SET SUBNETID_PARAM=--subnet-id %SUBNETID%
IF NOT [%KEYPAIR%] == [] SET KEYPAIR_PARAM=--key-name %KEYPAIR%
IF NOT [%SSM_ROLE_NAME%] == [] (
	SET SSM_ROLE_NAME_PARAM=--iam-instance-profile Name=%SSM_ROLE_NAME%
)

REM Launch Amazon Linux Instance. Run prepare_server.sh on server.
ECHO Starte AWS EC2 Instanz für %APP_NAME%.
aws ec2 run-instances --image-id %IMAGEID% --instance-type %INSTANCETYPE% %KEYPAIR_PARAM% %SECURITYGROUPSID_PARAM% --instance-initiated-shutdown-behavior terminate --region %REGION% %SUBNETID_PARAM% %SSM_ROLE_NAME_PARAM% --user-data file://prepare_server.sh --output text --query Instances[*].InstanceId > %INSTIDFILE%
SET INSTANCEID=EMPTY
SET /P INSTANCEID=<%INSTIDFILE%

IF [%INSTANCEID%] == [EMPTY] (
	DEL %INSTIDFILE%
	ECHO Start der Instanz gescheitert.
	EXIT /b 1
)

ECHO AWS EC2 Instanz startet. (Instance ID %INSTANCEID%)
ECHO %DATE% %TIME% AWS EC2 Instanz startet. (Instance ID %INSTANCEID%) >> dos_ctrl_ec2.log

REM Send notice about starting instance.
IF NOT [%SNS_TOPIC_ARN%] == [] (
	aws sns publish --topic-arn "%SNS_TOPIC_ARN%" --subject "STARTE %APP_NAME% Server mit Instanz ID %INSTANCEID%" --message "Starte %APP_NAME% Server, Instanz ID %INSTANCEID%." --output text > messageid.txt
)
  
ECHO Warte auf Abschluss des Instanzstarts ...
aws ec2 wait instance-running --instance-ids %INSTANCEID%
aws ec2 wait instance-running --instance-ids %INSTANCEID%

REM Tag Instance for easy identification by 
REM other clients without knowledge of instance id.
aws ec2 create-tags --resources %INSTANCEID% --tags Key=%TAGKEY%,Value=%TAGVALUE%

REM Get ip address.
ECHO Frage Verbindungsdaten ab.
aws ec2 describe-instances --instance-ids %INSTANCEID% --output text --query Reservations[*].Instances[*].PublicIpAddress > ipaddress.txt
SET /P IPADDRESS=<ipaddress.txt

ECHO Die IP-Adresse der Instanz ist %IPADDRESS%

REM Call batch file to update DNS, if configured.
IF EXIST %DNSSETUPBATCH% (
	ECHO Aktualisiere DNS %DNSHOSTNAME% auf IP %IPADDRESS%.
	CALL %DNSSETUPBATCH% %DNSHOSTNAME% %IPADDRESS% >> dos_ctrl_ec2.log
)

ECHO Instanz erfolgreich gestartet, verbinde mit EBS Laufwerk.
aws ec2 attach-volume --volume-id %VOLUMEID% --instance-id %INSTANCEID% --device /dev/sdf > attachvolume.json

IF ERRORLEVEL 1 (
	ECHO Fehler beim Verbinden des %APP_NAME% Laufwerk-Volumes ID %VOLUMEID%
	ECHO Terminiere die gestartete Instanz.
	CALL ec2_terminate_mc.bat
	EXIT /b 1
	)

IF NOT [%CONNECTION_DATA%] == [] (
	ECHO Verbindungsdaten: %CONNECTION_DATA%
)

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
