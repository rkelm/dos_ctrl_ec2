#!/bin/bash
# This script will be executed on the server after server instance start.
# It will prepare the system and start the minecraft server.

# Log output to log file.
exec > >(tee /var/log/user-data.log) 2>&1

# Mount point for app volume. No slash at the end.
mnt_pt="/opt/app"

# Path to start script on app volume. Path is local to mount point mnt_pt.
start_script="start.sh"

# SSM Service installieren.
echo 'Installing AWS SSM Service.'
cd /tmp
curl https://amazon-ssm-eu-central-1.s3.amazonaws.com/latest/linux_amd64/amazon-ssm-agent.rpm -o amazon-ssm-agent.rpm
yum -y install amazon-ssm-agent.rpm

# Install security updates.
# Automatically installed before instance start.
# yum -y update --security

# screen is usually installed.
# yum install screen

# Wait for EBS volume to be online.
echo 'Waiting for EBS Volume /dev/xvdf or /dev/sdf to be online.'
echo 'Checking for EBS volume ...'
while [ ! -e /dev/xvdf -o ! -e /dev/sdf ] ; do
  sleep 2
  echo 'Checking for EBS volume ...'
done;
echo 'EBS volume is online.'

# Mount filesystem.
echo "Creating mount point ${mnt_pt}."
mkdir -p "$mnt_pt"

if [ -e /dev/xvdf ] ; then
  if [ -e /dev/xvdf5 ] ; then
	device='/dev/xvdf5'
  else
	device='/dev/xvdf1'
  fi
else
  if [ -e /dev/sdf1 ] ; then
	device='/dev/sdf1'
  else
	device='/dev/sdf5'
  fi
fi

echo "Mounting ${device}."
mount "$device" "$mnt_pt"

# cd "$mnt_pt"
echo Running start script 
if [ -e "${mnt_pt}/${start_script}" ] ; then
	"${mnt_pt}/${start_script}"
else 
	echo Start script "${mnt_pt}/${start_script}" not found.
fi	

echo 'prepare_server.sh script ending.'
