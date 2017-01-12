# dos_ctrl_ec2
MSDOS Batch files to launch and terminate an AWS ec2 linux instance running apps/services.

I created these batch files so my kids could start and stop their minecraft server on AWS ec2 with 
a simple click using client computers with MS operating systems. It can be used just as well to start and stop 
ec2 instances running other apps/services than minecraft.

Please be warned that using AWS services incurs charges for you.

Currently batch file output is in german.


# features
* supports multiple configurations
* supports multiple clients. Start from one client, terminate from another.
* simple start/stop with one click
* allows only one running instance per configuration file
* tested with amazon linux instances

# prerequisites
* AWS cli installed
* AWS login
* AWS credentials written to environment variables "AWS_ACCESS_KEY_ID" and "AWS_SECRET_ACCESS_KEY" or a batch file which will set up both environment variables when run.
* prepared ec2 volume containing the following
  * an installed version or installation files of the apps/services to be run on an ec2 instance
  * /start.sh script run as root, which installs and starts the apps/services
* Optional utility to update dynDNS service to point to the ec2 instance.

# file setup
* Download zip file.
* Unzip files to an empty directory.
* Create empty subdirectory "config".
* Ensure the user has the rights to execute the batch files, read "prepare_server.sh" and create&write to files in the root installation directory.
* Optional: For easy launch and termination operations with one click, create short cuts calling the batch files with the most common parameters.

# main files
The following are the main files used in this project.
* AppRunner_policy.json - AWS IAM policy document example. The json structure in this file shows an example for an IAM policy document you could attach to an IAM user to restrict permisssions. The example includes only the permisssions needed to execute the AWS cli calls used in the included batch files. The example only permits use of the AWS region "eu-central-1". You can change this by editing the file.
* ec2_config_default.bat - This is the standard configuration used, when no configuration is passed as a parameter to the batch files. Better than to edit this file, is to copy it for each different ec2 instance to the subdirectory "config" as a template and then edit the copied config file.
* ec2_launch.bat - Run this batch file with the _NAME_ of the config file as the only parameter. When the configuration file is correct, it will start the ec2 instance. If there already is an ec2 instance using the given tags, then no new instance will be started.
* ec2_terminate.bat - Run this batch with the _NAME_ of the config file as the only parameter. When the configuration file is correct, it will terminate the running ec2 instance. If no ec2 instance using the configured tags is running, the batch will complain and exit.
* prepare_server.sh - This bash script is executed on the ec2 instance right after start up. It installs security patches, mounts the volume and runs "start.sh".
* setup_dns.bat - Optional example script to update dynDNS service. Update it to use your preferred dynDNS service. (I use the utility curl to update my no-ip dynDNS service.)
* ToDo.txt - Scribble with some notes about what to implement next.

# runtime files
The following files are created at runtime for debugging and logging purposes. Some are overwritten each run. Look at these files if things don't work as expected.
* attachvolume.json - Contains output of the last attach-volume cli call.
* dos_ctrl_ec2.log - Main log file. 
* instanceid_NAME.txt - Contains the instance id of the last started instance.
* ipadress.txt - Contains the ipv4 address of the last created ec2 instance.
* messageid.txt - Contains the message id of the last created sns message.
* terminate.json - contains output of the last terminate-instances cli call.

# instance configuration
For each different ec2 instance you plan to launch, setup the following.
* Create one config file in the "config" subdirectory by copying "\ec2_config_default.bat".
* Config files must be named by the pattern "ec2_config_NAME.bat", where _NAME_ must not contain blanks and must be the unique name used to identify this instance configuration.
* Edit the created config file to fit your needs.
* Setup an ec2 volume with the installation files or already installed files apps/services to run on ec2 instances.
* Setup a startup script named "start.sh" in the root directory of the volume. This script should setup and start the apps/services. Its executed as the linux root user.
* Optionally setup a hostname with your preferred dynDNS service and edit "setup_dns.bat" to update it at instance launch.


# usage
* Run "ec2_launch.bat _NAME_" to launch an ec2 instance using the specified configuration.
* Run "ec2_terminate.bat _NAME_" to terminate a running ec2 instance belonging to the specified configuration.


# deinstallation
Terminate all running ec2 instances, delete the installation directory including all contained files and if you like delete alle volumes and snapshots.
