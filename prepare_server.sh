#!/bin/bash
# This script will be executed on the server after server instance start.
# It will prepare the system and start the minecraft server.

# Mount point for app volume. No slash at the end.
mnt_pt="/mnt/app"

# Path to start script on app volume. Path is local to mount point mnt_pt.
start_script="start.sh"

# SSM Service installieren.
# echo 'Installing AWS SSM Service.'
# cd /tmp
# curl https://amazon-ssm-eu-central-1.s3.amazonaws.com/latest/linux_amd64/amazon-ssm-agent.rpm -o amazon-ssm-agent.rpm
# yum install -y amazon-ssm-agent.rpm

# Install security updates.
yum update -y

# screen is usually installed.
# yum install screen

# Wait for EBS volume to be online.
echo 'Waiting for EBS Volume /dev/vxdf to be online.'
echo 'Checking for EBS volume ...'
while [ ! -e /dev/xvdf -o ! -e /dev/sdf ] ; do
  sleep 5
  echo 'Checking for EBS volume ...'
done;
echo 'EBS volume is online.'

# Mount filesystem.
echo "Creating mount point ${mnt_pt}."
mkdir -p "$mnt_pt"

if [ -e /dev/xvdf ] ; then
  echo 'Mounting /dev/xvdf1.'
  mount /dev/xvdf1 "$mnt_pt"
else
  echo 'Mounting /dev/sdf1.'
  mount /dev/sdf1 "$mnt_pt"
fi

# cd "$mnt_pt"
echo Running start script 
"${mnt_pt}/${start_script}"

echo 'Script ending.'
