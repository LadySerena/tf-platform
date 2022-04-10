#!/usr/bin/env bash

set -x

function die() {
    echo "$1"
    exit 1
}

image_key_bucket="gs://pi-images.serenacodes.com/pi4-base"
key_bucket="gs://pi-host-keys.serenacodes.com"

while getopts i:h: options; do
  case $options in
    i) image_name=$OPTARG;;
    h) host=$OPTARG;;
    *) die "$OPTARG is not valid"
  esac
done

echo "image_name: $image_name, host: $host"

if [ -f "$image_name.img.xz" ];
then
  echo "file here skipping download"
else
  gsutil cp "$image_key_bucket/$image_name.img.xz" ./
fi

if [ -f "$host-host-key.tar.gz" ];
then
  echo "keys here skipping download"
else
  gsutil cp "$key_bucket/$host-host-key.tar.gz" ./
fi

host_path="${host}_host_key"

if [ -d "$host_path" ];
then
  echo "keys extracted skipping decompression"
else
  tar -xzvf "$host-host-key.tar.gz"
fi

if [ -f "$image_name.img" ];
then
  echo "skipping decompression of disk image"
else
  xz -k -d "$image_name.img.xz"
fi

sudo losetup -Pf "$image_name.img"

sudo mount /dev/loop0p2 /mnt

sudo mount /dev/loop0p1 /mnt/boot/firmware

dsa_public=$(cat "$host_path/ssh_host_dsa_key.pub")
ecdsa_public=$(cat "$host_path/ssh_host_ecdsa_key.pub")
ed25519_public=$(cat "$host_path/ssh_host_ed25519_key.pub")
rsa_public=$(cat "$host_path/ssh_host_rsa_key.pub")

IFS= read -rd '' dsa_private <  <(cat "$host_path/ssh_host_dsa_key")
IFS= read -rd '' ecdsa_private < <(cat "$host_path/ssh_host_ecdsa_key")
IFS= read -rd '' ed25519_private < <(cat "$host_path/ssh_host_ed25519_key")
IFS= read -rd '' rsa_private < <(cat "$host_path/ssh_host_rsa_key")

rsa_public=$rsa_public \
rsa_private=$rsa_private \
ed25519_public=$ed25519_public \
ed25519_private=$ed25519_private \
ecdsa_public=$ecdsa_public \
ecdsa_private=$ecdsa_private \
dsa_public=$dsa_public \
dsa_private=$dsa_private \
host=$host \
yq \
'. + {"ssh_deletekeys": false,
  "ssh_keys": {
    "dsa_private": strenv(dsa_private),
    "dsa_public": strenv(dsa_public),
    "ecdsa_private": strenv(ecdsa_private),
    "ecdsa_public": strenv(ecdsa_public),
    "ed25519_private": strenv(ed25519_private),
    "ed25519_public": strenv(ed25519_public),
    "rsa_public": strenv(rsa_public),
    "rsa_private": strenv(rsa_private)
  },
  "hostname": strenv(host)
}' \
/mnt/etc/cloud/cloud.cfg > /tmp/cloud.cfg

sudo mv /tmp/cloud.cfg /mnt/etc/cloud/cloud.cfg

bat --paging=never /mnt/etc/cloud/cloud.cfg

sudo umount /mnt/boot/firmware

sudo umount /mnt

sudo losetup --detach "/dev/loop0"

cp "$image_name.img" "$host.img"
