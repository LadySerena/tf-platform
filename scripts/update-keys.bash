#!/usr/bin/env bash

set -exo pipefail

function die() {
    echo "$1"
    exit 1
}

image_key_bucket="gs://pi-images.serenacodes.com/pi4-base"
key_bucket="gs://pi-host-keys.serenacodes.com"

while getopts i:h: options; do
  case $options in
    i) image_name=$OPTARG;;
    h) host_key=$OPTARG;;
    *) die "$OPTARG is not valid"
  esac
done

echo "image_name: $image_name, host_key: $host_key"

gsutil cp "$image_key_bucket/$image_name.img.xz" ./

gsutil cp "$key_bucket/$host_key.tar.gz" ./

tar -xzvf "$host_key.tar.gz"

xz -kd "$image_name.img.xz"

sudo losetup -Pf "$image_name.img"

sudo mount /dev/loop0p2 /mnt

sudo mount /dev/loop0p1 /mnt/boot/firmware

# todo for the rest of keys

#todo after untarring the host key dir is underscore instead of dash (replace dashes in arg with underscore)

dsa_private=$(cat "$host_key/ssh_host_dsa_key")

IFS= read -rd '' dsa_private < <(cat my_file)
dsa_private=$dsa_private ./yq '. + {"ssh_deletekeys": false, "ssh_keys": {"dsa_private": strenv(dsa_private)}}' /mnt/etc/cloud/cloud.cfg


