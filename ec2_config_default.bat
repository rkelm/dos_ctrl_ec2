REM @ECHO OFF
REM ******* Configuration ******* 
REM Edit here to setup script for your environment.
REM Choose aws region. (Required)
SET REGION=eu-central-1
REM Choose a subnet from the availability zone where your volume resides. (Required)
REM Default Subnet for Region eu-central-1a
SET SUBNETID=subnet-ad287cc4
REM Default Subnet for Region eu-central-1b
REM SET SUBNETID=subnet-0a355e71

REM Set ID of existing Volume to mount to instance. (Required)
SET VOLUMEID=
REM Set the ID of your virtual firewall defintion (security group). (Required)
REM The firewall should at least define rules to allow tcp and udp traffic on the 
REM minecraft port (default: 25565) incoming and outgoing.
SET SECURITYGROUPSID=
REM Choose instance type. Typical instance types are c4.large, t2.medium, t2.small, t2.micro. (Required)
SET INSTANCETYPE=t2.small

REM Set Image ID for root device of instance. (Required)
REM Example: SET IMAGEID=ami-ea26ce85
SET IMAGEID=ami-f9619996

REM Set SNS topic arn if you would like to receive a notice by AWS SNS Service, at start
REM and termination of instance. (Optional)
SET SNS_TOPIC_ARN=

REM Name of EC2 Keypair for SSH Public Key Login. (Required)
REM Example: KEYPAIR=Power_User
SET KEYPAIR=Power_User

REM Tags for other clients to discover a running instance. (Required)
SET TAGKEY=APP-SERVER
SET TAGVALUE=VANILLA

REM Enter path and file name to AWS crendentials batch file here. (Optional)
REM The referenced batch file should set the aws environment variables
REM AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
REM Example: SET CREDENTIALSFILE=%USERPROFILE%\.aws\apprunner_credentials.bat
SET CREDENTIALSFILE=

REM Enter path and file name to batch file to setup dynamic DNS. (Optional)
REM IPv4 address will be passed as first and only parameter.
REM Example: DNSSETUPBATCH=setup_dns.bat
SET DNSSETUPBATCH=setup_dns.bat

REM Dynamic DNS host name, required only if you want to update dynamic dns. (Optional)
SET DNSHOSTNAME=my-ec2-server.somedomain.somedomain

REM Optional name of the app run on ec2. Used in messages. (Optional)
SET APP_NAME=my_app

REM Optional text shown at launch to user, for example hostname:port.
SET CONNECTION_DATA=%DNSHOSTNAME%

REM Load your AWS credentials into environment variables, if credentials file exists.
IF NOT [%CREDENTIALSFILE%] == [] (
 	IF EXIST "%CREDENTIALSFILE%" (
		CALL "%CREDENTIALSFILE%"
		)
	)
