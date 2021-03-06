# dos_ctrl_ec2
State: RELEASED  
MSDOS Batch files to launch and terminate an AWS EC2 linux instance running apps/services.

I created these batch files so my kids could start and stop their minecraft server on AWS EC2 with 
a simple click using client computers with MS operating systems. It can be used just as well to start and stop 
EC2 instances running other apps/services than minecraft.

Please be warned that using AWS services incurs charges for you.

Currently batch file output is in german only.


# features
* supports multiple configurations
* supports multiple clients. Start from one client, terminate from another.
* simple start/stop with one click
* allows only one running instance per configuration file
* tested with amazon linux instances
* allows sending commands to the instance

# prerequisites
* AWS cli installed
* AWS login
* AWS credentials written to environment variables "AWS_ACCESS_KEY_ID" and "AWS_SECRET_ACCESS_KEY" or a batch file which will set up both environment variables when run. See AppRunner_policy.json for an example AWS IAM policy document.
* prepared EBS volume containing the following
  * an installed version or installation files of the apps/services to be run on an EC2 instance
  * /start.sh script run as root, which installs and starts the apps/services
* Optional utility to update dynDNS service to point to the EC2 instance.

# file setup
* Download zip file.
* Unzip files to an empty directory.
* Create empty subdirectory "config".
* Ensure the user has the rights to execute the batch files, read "prepare_server.sh" and create&write to files in the root installation directory.
* Optional: For easy launch and termination operations with one click, create short cuts calling the batch files with the most common parameters.

# main files
The following are the main files used in this project.
* AppRunner_policy.json - AWS IAM policy document example. The json structure in this file shows an example for an IAM policy document you could attach to an IAM user to restrict permisssions. The example includes only the permisssions needed to execute the AWS cli calls used in the included batch files. The example only permits use of the AWS region "eu-central-1". You can change this by editing the file.
* ec2_config_default.bat - This is the standard configuration used, when no configuration is passed as a parameter to the batch files. Better than to edit this file, is to copy it for each different EC2 instance to the subdirectory "config" as a template and then edit the copied config file.
* ec2_launch.bat - Run this batch file with the _NAME_ of the config file as the only parameter. When the configuration file is correct, it will start the EC2 instance. If there already is an EC2 instance using the given tags, then no new instance will be started.
* ec2_terminate.bat - Run this batch with the _NAME_ of the config file as the only parameter. When the configuration file is correct, it will terminate the running EC2 instance. If no EC2 instance using the configured tags is running, the batch will complain and exit.
* ec2_create_snap.bat - Running this batch file with the _NAME_ of the config file as the only parameter, will create a new snapshot of the configured volume. 
* ec2_send_command.bat - Call this batch file with a command to be executed in the ec2 instance as the second paramter. First parameter identifies the configuration file to be used. The command is executed with root privileges on the ect instance.
* prepare_server.sh - This bash script is executed on the EC2 instance right after start up via AWS user data. It installs security patches, mounts the volume and runs "start.sh".
* setup_dns.bat - Optional example script to update dynDNS service. Update it to use your preferred dynDNS service. (I use the utility curl to update my no-ip dynDNS service.)
* build_package.bat - Batch file to run, to create deployment package.
* ToDo.txt - Scribble with some notes about what to implement next.

# runtime files
The following files are created at runtime for debugging and logging purposes. Some are overwritten each run. Look at these files if things don't work as expected.
* attachvolume.json - Contains output of the last attach-volume cli call.
* dos_ctrl_ec2.log - Main log file. 
* instanceid_NAME.txt - Contains the instance id of the last started instance.
* ipadress.txt - Contains the ipv4 address of the last created EC2 instance.
* messageid.txt - Contains the message id of the last created sns message.
* terminate.json - Contains output of the last terminate-instances cli call.
* output.txt - Contains output of an aws command.

# instance configuration
For each different EC2 instance you plan to launch, setup the following.
* Create one config file in the "config" subdirectory by copying "\ec2_config_default.bat".
* Config files must be named by the pattern "EC2_config_NAME.bat", where _NAME_ must not contain blanks and must be the unique name used to identify this instance configuration.
* Edit the created config file to fit your needs.
* Setup an EBS volume or EBS snapshot with the installation files or already installed files apps/services to run on EC2 instances.
(When creating a snapshot, one can use "zerofree" app to reduce storage size.)
* Setup a startup script named "start.sh" in the root directory of the volume. This script should setup and start the apps/services. Its executed as the linux root user.
* Optionally setup a hostname with your preferred dynDNS service and edit "setup_dns.bat" to update it at instance launch.

# usage
* Run "ec2_launch.bat _NAME_" to launch an EC2 instance using the specified configuration.
* Run "ec2_terminate.bat _NAME_" to terminate a running EC2 instance belonging to the specified configuration.
* Run "ec2_create_snap.bat _NAME_" to create a snapshot of the volume of a terminated EC2 instance belonging to the specified configuration.
* Run "ec2_send_command.bat _NAME_ _REMOTE-COMMAND_" to run _REMOTE-COMMAND_ on the EC2 instance.

# deinstallation
Terminate all running EC2 instances, delete the installation directory including all contained files and if you like delete alle volumes and snapshots.

# security
To use SSM to send commands to the ec2 instance with ec2_send_command.bat you need to add extensive permissions, which may be misused. Especially permissions ssm:SendCommand and iam:PassRole are dangerous as they may allow to elevate privileges if the access key is compromised. Read the AWS documentation to understand more about the dangers.
