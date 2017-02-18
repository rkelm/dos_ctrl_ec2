@ECHO OFFpwd
REM Batch file to create package for distribution to users.
SET DSTFILENAME=build\dos_ctrl_ec2.zip
IF EXIST %DSTFILENAME% (
	DEL %DSTFILENAME%
) 
C:\Programme\7-Zip\7z.exe a %DSTFILENAME% AppRunner_policy.json ec2_config_default.bat ec2_launch.bat ec2_terminate.bat LICENSE prepare_server.sh README.md setup_dns.bat ec2_create_snapshot.bat changes.txt ec2_send_command.bat

pause