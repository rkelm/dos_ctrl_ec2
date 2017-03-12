@ECHO OFF
REM Set environment variables for call to update dynDNS service.
SET AUTH_FILE=%USERPROFILE%\no-ip_config.bat
IF EXIST %AUTH_FILE% (
  CALL %AUTH_FILE%
) ELSE (
  ECHO Missing authentication file %AUTH_FILE%.
  EXIT /B 1
)
ECHO %DATE% %TIME% updating %1 to ip %2 (no-ip service)
utils\curl.exe -s -k "https://%DNS_USER%:%DNS_PW%@dynupdate.no-ip.com/nic/update?hostname=%1&myip=%2"
