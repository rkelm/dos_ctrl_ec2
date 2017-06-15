@ECHO OFF
REM Batch file to launch ec2 instance.
SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

SET _CONFIG=%1
IF NOT DEFINED _CONFIG (
  ECHO Es muss ein Konfigurationskuerzel als Paramter angegeben werden.
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
aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
REM Delete instance id file if it is empty.
for %%F in ("%INSTIDFILE%") do if %%~zF equ 0 del "%%F"
IF EXIST %INSTIDFILE% (
	ECHO Es laeuft bereits eine %APP_NAME% Server Instanz!
	ECHO Ein neuer Snapshot kann nur bei terminierter Instanz erstellt werden.
	ECHO Bitte erst die alte Instanz beenden.
	EXIT /b 1
)

REM Create new snapshot.
ECHO Erstelle neuen Snapshot des Volume mit ID %VOLUMEID% von %APP_NAME%.
aws ec2 create-snapshot --volume-id %VOLUMEID% --description "%1 %APP_NAME% Snapshot created %DATE% %TIME%." --output text --query SnapshotId > snapshotid.txt

IF ERRORLEVEL 1 (
  ECHO Fehler beim erstellen des Snapshot.
  EXIT /B 1
)

REM Snapshot ID
SET /P SNAPSHOTID=<snapshotid.txt
REM Tag new snapshot name with parameter or name of volume (default).
SET _NAMEVALUE=%2
IF NOT DEFINED _NAMEVALUE (
  aws ec2 describe-volumes --volume-id %VOLUMEID% --output text --query Volumes[*].Tags[?Key==`Name`].Value > output.txt  
  SET /P _NAMEVALUE=<output.txt
)
IF DEFINED _NAMEVALUE (
  aws ec2 create-tags --resources %SNAPSHOTID% --tags "Key=Name,Value=%_NAMEVALUE%"
)
aws ec2 create-tags --resources %SNAPSHOTID% --tags "Key=%TAGKEY%,Value=%TAGVALUE%"

REM Show snapshot size to user.
aws ec2 describe-volumes --volume-id %VOLUMEID% --output text --query Volumes[*].Size > output.txt  

SET /P VolumeSize=<output.txt
ECHO Snapshot erstellt, Groesse !VOLUMESIZE! GByte.

REM Restore previous current directory.
CD /D %EXCURRENTDIR%

