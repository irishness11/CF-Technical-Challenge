#!/bin/bash

# Specify the desired volume size in GiB
NEW_SIZE=100

# Get the ID of the instance
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Get the region of the instance
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Get the volume ID attached to /dev/xvda
VOLUME_ID=$(aws ec2 describe-instances --instance-id $INSTANCE_ID --region $REGION --query "Reservations[0].Instances[0].BlockDeviceMappings[?DeviceName==\`/dev/xvda\`].Ebs.VolumeId" --output text)

# Modify the volume size
aws ec2 modify-volume --volume-id $VOLUME_ID --size $NEW_SIZE --region $REGION

# Wait until the volume modification is completed
while [ "$(aws ec2 describe-volumes-modifications --volume-id $VOLUME_ID --region $REGION --query "VolumesModifications[0].ModificationState" --output text)" != "completed" ]; do
  echo "Waiting for volume modification to complete..."
  sleep 10
done

# Check the file system type
FS_TYPE=$(lsblk -f | grep xvda1 | awk '{print $2}')

# Resize the partition
sudo growpart /dev/xvda 1

# Resize the file system
if [ "$FS_TYPE" == "xfs" ]; then
  sudo xfs_growfs /
elif [ "$FS_TYPE" == "ext4" ]; then
  sudo resize2fs /dev/xvda1
else
  echo "Unsupported file system: $FS_TYPE"
  exit 1
fi

echo "EBS volume resized to ${NEW_SIZE}GiB and file system expanded successfully."
