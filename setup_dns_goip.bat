@ECHO OFF
REM Set environment variables for call to update dynDNS service.
IF EXIST %USERPROFILE%\goip_config.bat (
  CALL %USERPROFILE%\goip_config.bat
  )
ECHO %DATE% %TIME% UPDATING %1 TO IP %2
utils\curl.exe -s -k "https://www.goip.de/setip?username=%DNS_USER%&password=%DNS_PW%&subdomain=%1&ip=%2&shortResponse=true"
