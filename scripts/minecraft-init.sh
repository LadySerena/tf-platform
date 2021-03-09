#!/usr/bin/env bash
set -e
# Disk Params
mount_point=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/mount-point -H "Metadata-Flavor: Google")
owner=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/owner -H "Metadata-Flavor: Google")
disk_id=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/disk-id -H "Metadata-Flavor: Google")
volume_group_name=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/volume-group-name -H "Metadata-Flavor: Google")
lvm_name=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/lvm-name -H "Metadata-Flavor: Google")

create_lvm() {
  pvcreate "/dev/disk/by-id/google-$disk_id"
  vgcreate "$volume_group_name" "/dev/disk/by-id/google-$disk_id"
  lvcreate -l +100%FREE "$volume_group_name" -n "$lvm_name"
}

create_fs() {
  mkfs.ext4 "/dev/$volume_group_name/$lvm_name"
}

mount_lvm() {
  mount "/dev/$volume_group_name/$lvm_name" "$mount_point"
}

if [ ! -d "$mount_point" ]; then
  echo "$mount_point doesn't exist creating it now"
  mkdir -p "$mount_point"

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
if ! file -sL "/dev/$volume_group_name/$lvm_name" | grep ext4 >>/dev/null; then
  echo "creating filesystem"
  create_fs
else
  echo "disk is formatted skipping filesystem creation"
fi

if findmnt -M "$mount_point" >>/dev/null; then
  echo "lvm is already mounted skipping mounting"
else
  echo "mounting lvm"
  mount_lvm
fi

echo "setting ownership of $mount_point to $owner"
chown -R "$owner" "$mount_point"

### Minecraft service config
echo "configuring minecraft server"
rcon_secret_name=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rcon-secret-name -H "Metadata-Flavor: Google")
rcon_password=$(gcloud secrets versions access "latest" --secret="$rcon_secret_name")
sed -e "s/{{rcon_password}}/$rcon_password/g" /opt/minecraft/rcon-config.yaml.template >/opt/minecraft/rcon-config.yaml
sed -e "s/{{rcon_password}}/$rcon_password/g" /opt/minecraft/server.properties.template >/opt/minecraft/server.properties
echo "finished minecraft server configuration"

### DBUS API config
echo "configuring dbus api"
auth_file_path="/etc/dbus-api/auth"
tls_key_path="/etc/dbus-api/key.pem"
tls_cert_path="/etc/dbus-api/cert.pem"
dbus_auth_file_secret_name=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/dbus-secret-name -H "Metadata-Flavor: Google")
api_managed_service=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/service-name -H "Metadata-Flavor: Google")
internal_ip=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H "Metadata-Flavor: Google")
tls_secret_name=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/tls-secret-name -H "Metadata-Flavor: Google")
tls_cert=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/tls-cert -H "Metadata-Flavor: Google")
dbus_password_file=$(gcloud secrets versions access "latest" --secret="$dbus_auth_file_secret_name")
tls_key=$(gcloud secrets versions access "latest" --secret="$tls_secret_name")
echo -n "$tls_key" >$tls_key_path
echo -n "$tls_cert" >$tls_cert_path
echo -n "$dbus_password_file" >$auth_file_path

cat <<EOF >/etc/dbus-api/environment
DBUS_API_SERVICE_NAME=$api_managed_service
DBUS_API_AUTH_FILE=$auth_file_path
DBUS_API_LISTEN_ADDRESS=$internal_ip:8080
DBUS_API_TLS_ENABLED=true
DBUS_API_TLS_CERT_PATH=$tls_cert_path
DBUS_API_TLS_KEY_PATH=$tls_key_path
EOF
echo "dbus api configured"
echo "init script finished"
