@ECHO OFF
REM Check for curl.
SET CURL_BIN=utils\curl.exe
IF NOT EXIST %CURL_BIN% (
	ECHO %CURL_BIN% not found 
	EXIT /b 1
)

REM Check call parameters.
SET SUBDOMAIN=%1
SET IPADDR=%2
IF NOT DEFINED SUBDOMAIN (
	ECHO Usage: setup_dns_goip.bat ^<hostname^> ^<ipaddr^>
	EXIT /b 1
)

IF NOT DEFINED IPADDR (
	ECHO Usage: setup_dns_goip.bat ^<hostname^> ^<ipaddr^>
	EXIT /b 1
)

REM Set environment variables for call to update dynDNS service.
SET AUTH_FILE=%USERPROFILE%\no-ip_config.bat
IF EXIST %AUTH_FILE% (
  CALL %AUTH_FILE%
) ELSE (
  ECHO Missing authentication file %AUTH_FILE%.
  EXIT /B 1
)
ECHO %DATE% %TIME% updating %SUBDOMAIN% to ip %IPADDR% (no-ip service)
%CURL_BIN% -s -k "https://%DNS_USER%:%DNS_PW%@dynupdate.no-ip.com/nic/update?hostname=%SUBDOMAIN%&myip=%IPADDR%"
