@ECHO OFF
REM Set environment variables for call to update dynDNS service.
SET AUTH_FILE=%USERPROFILE%\goip_config.bat
IF EXIST %AUTH_FILE% (
  CALL %AUTH_FILE%
) ELSE (
  ECHO Missing authentication file %AUTH_FILE%.
  EXIT /B 1  
)
ECHO %DATE% %TIME% updating %1 to ip %2 (goip service)
utils\curl.exe -s -k "https://www.goip.de/setip?username=%DNS_USER%&password=%DNS_PW%&subdomain=%1&ip=%2&shortResponse=true"
