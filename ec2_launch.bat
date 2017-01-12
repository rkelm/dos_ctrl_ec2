@ECHO OFF
REM Batch file to launch ec2 instance.

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

REM Simple Check: "Is instance already running?"
IF EXIST %INSTIDFILE% (
	ECHO Es läuft bereits eine %APP_NAME% Server Instanz!
	ECHO Start einer neuen Instanz wird abgebrochen.
	ECHO Bitte erst die alte Instanz beenden.
	PAUSE
	EXIT /b 1
)

REM Check for running instance by searching for tag in aws cloud.
aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
REM Delete instance id file if it is empty.
for %%F in ("%INSTIDFILE%") do if %%~zF equ 0 del "%%F"
IF EXIST %INSTIDFILE% (
  ECHO Es läuft bereits eine %APP_NAME% Server Instanz!
  ECHO Start einer neuen Instanz wird abgebrochen.
  ECHO Bitte erst die alte Instanz beenden.
  PAUSE
  EXIT /b 1
  )

REM Launch Amazon Linux Instance. Run prepare_server.sh on server.
ECHO Starte AWS EC2 Instanz.
aws ec2 run-instances --image-id %IMAGEID% --instance-type %INSTANCETYPE% --key-name %KEYPAIR% --security-group-ids %SECURITYGROUPSID% --instance-initiated-shutdown-behavior terminate --region %REGION% --subnet-id %SUBNETID% --user-data file://prepare_server.sh --output text --query Instances[*].InstanceId > %INSTIDFILE%
SET /P INSTANCEID=<%INSTIDFILE%

IF [%INSTANCEID%] == [] (
  DEL %INSTIDFILE%
  ECHO Start der Instanz gescheitert.
  EXIT /b 1
)

ECHO AWS EC2 Instanz startet. (Instance ID %INSTANCEID%)
ECHO %DATE% %TIME% AWS EC2 Instanz startet. (Instance ID %INSTANCEID%) >> dos_ctrl_ec2.log

REM Send notice about starting instance.
IF NOT [%SNS_TOPIC_ARN%] == [] (
  aws sns publish --topic-arn "%SNS_TOPIC_ARN%" --subject "%APP_NAME% Server mit Instanz ID %INSTANCEID% startet" --message "%APP_NAME% Server startet, Instanz ID %INSTANCEID%." --output text > messageid.txt
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

ECHO IP-Adresse %IPADDRESS%
ECHO Bitte warten. Gleich ist der Server erreichbar.
IF NOT [%CONNECTION_DATA%] == [] (
	ECHO Verbindungsdaten: %CONNECTION_DATA%
)

TIMEOUT /T 60 /NOBREAK
ECHO .
ECHO ********************************************
ECHO * Der Server sollte jetzt erreichbar sein. *
ECHO * Falls nicht bitte noch kurz warten.      *
ECHO ********************************************
ECHO .

ECHO Am Besten dieses Fenster erst schließen, wenn ihr fertig mit %APP_NAME% spielen seid.
ECHO Also erst später auf die Taste drücken!!
PAUSE

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
