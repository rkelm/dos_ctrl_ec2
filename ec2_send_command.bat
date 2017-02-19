@ECHO OFF
REM Batch file to launch ec2 instance.
SETLOCAL enabledelayedexpansion

REM Check command line paramters.
IF [%2] == [] (
	REM Complain about missing parameter.
	ECHO Bitte geben sie ein Kommando als zweiten Parameter an.
	EXIT /B 1
)

SET SERVER_COMMAND=%2 %3 %4 %5 %6 %7 %8 %9

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

REM Check for running instance by searching for tag in aws cloud.
aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
REM Delete instance id file if it is empty.
for %%F in ("%INSTIDFILE%") do if %%~zF equ 0 del "%%F"
IF NOT EXIST %INSTIDFILE% (
  ECHO Es läuft keine %APP_NAME% Server Instanz!
  ECHO Kommando kann nicht ausgeführt werden.
  ECHO Bitte erst eine Instanz starten.
  EXIT /b 1
)
SET /P INSTANCEID=<%INSTIDFILE%

REM Send command.
aws ssm send-command --instance-ids %INSTANCEID% --document-name "AWS-RunShellScript" --parameters commands="%SERVER_COMMAND%" --output text --query Command.CommandId > commandid.txt
SET /P COMMANDID=<commandid.txt

REM Wait till command execution terminates.
:CMD_EXECUTION
aws ssm list-command-invocations --command-id "%COMMANDID%" --detail --query CommandInvocations[*].Status --output text > cmd_status.txt
SET /P status=<cmd_status.txt
IF [%STATUS%]==[InProgress] (
	TIMEOUT /T 1 /NOBREAK > nul
	GOTO CMD_EXECUTION
)

IF [%STATUS%] == "Success" (
	REM Get command output.
	aws ssm list-command-invocations --command-id "%COMMANDID%" --detail --query CommandInvocations[*].CommandPlugins[*].Output --output text			
) ELSE (
	aws ssm list-command-invocations --command-id "%COMMANDID%" --detail --query CommandInvocations[*].CommandPlugins[*].Output --output text		
	EXIT /B 1
)

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
