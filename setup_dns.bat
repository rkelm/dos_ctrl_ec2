@ECHO OFF
REM Set environment variables for call to update dynDNS service.
IF EXIST %USERPROFILE%\no-ip_config.bat (
  CALL %USERPROFILE%\no-ip_config.bat
  )
ECHO %DATE% %TIME% UPDATING %1 TO IP %2
curl.exe -s -k "https://%DNS_USER%:%DNS_PW%@dynupdate.no-ip.com/nic/update?hostname=%1&myip=%2"
