#!/usr/bin/env bash
set -e
mount_point=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/mount-point -H "Metadata-Flavor: Google")
owner=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/owner -H "Metadata-Flavor: Google")
disk_id=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/disk-id -H "Metadata-Flavor: Google")
volume_group_name=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/volume-group-name -H "Metadata-Flavor: Google")
lvm_name=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/lvm-name -H "Metadata-Flavor: Google")

create_lvm() {
    sudo pvcreate "/dev/disk/by-id/google-$disk_id"
    sudo vgcreate "$volume_group_name" "/dev/disk/by-id/google-$disk_id"
    sudo lvcreate -l +100%FREE "$volume_group_name" -n "$lvm_name"
}

create_fs() {
    sudo mkfs.ext4 "/dev/$volume_group_name/$lvm_name"
}

mount_lvm() {
    sudo mount "/dev/$volume_group_name/$lvm_name" "$mount_point"
}

if [ ! -d "$mount_point" ]; then
    echo "$mount_point doesn't exist creating it now"
    sudo mkdir -p "$mount_point"
    sudo chown -R $owner $mount_point

else
    echo "$mount_point exists skipping mkdir"
fi

if [ ! -d "/dev/$volume_group_name" ]; then
    echo "lvm doesn't exist now creating"
    create_lvm
else
    echo "lvm exists skipping lvm creation"
fi

# check if disk has been formatted if it hasn't then format it with ext4 filesystem
if ! sudo file -sL /dev/$volume_group_name/$lvm_name | grep ext4 >> /dev/null; then
    echo "creating filesystem"
    create_fs
else
    echo "disk is formatted skipping filesystem creation"
fi

if findmnt -M $mount_point >> /dev/null; then
    echo "lvm is already mounted skipping mounting"
else
    echo "mounting lvm"
    mount_lvm
fi
