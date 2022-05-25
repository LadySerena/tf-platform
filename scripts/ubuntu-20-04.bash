#!/usr/bin/env bash

set -ex pipefail

ubuntu_image_name_base="ubuntu-20.04.4-preinstalled-server-arm64+raspi"
ubuntu_image_name_archive="${ubuntu_image_name_base}.img.xz"
ubuntu_image_name_raw="${ubuntu_image_name_base}.img"

wget https://cdimage.ubuntu.com/releases/20.04/release/ubuntu-20.04.4-preinstalled-server-arm64+raspi.img.xz
echo "6aeba20c00ef13ee7b48c57217ad0d6fc3b127b3734c113981d9477aceb4dad7 *${ubuntu_image_name_archive}" | shasum -a 256 --check

xz -d "$ubuntu_image_name_archive"

sudo truncate -c -s +1000M "$ubuntu_image_name_raw"

sudo losetup -Pf "$ubuntu_image_name_raw"

IN=$(sudo parted /dev/loop0 print -m -s | tail -n 1)
# shellcheck disable=SC2206
# this is intentional splitting my dear linter!
arrIN=(${IN//:/ })

sudo parted /dev/loop0 resizepart 2 "${arrIN[2]}" -s
sudo e2fsck -pf /dev/loop0p2
sudo resize2fs /dev/loop0p2

sudo mount /dev/loop0p2 /mnt/
sudo mount /dev/loop0p1 /mnt/boot/firmware

sudo mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.bak
sudo cp /etc/resolv.conf /mnt/etc/resolv.conf

cat << 'INSTALL' > /tmp/install.bash
#!/usr/bin/env bash
# follow guide here https://disconnected.systems/blog/raspberry-pi-archlinuxarm-setup/

set -eo pipefail

function kernel-nonsense() {
  cat <<'EOF' | tee /boot/firmware/cmdline.txt
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=LABEL=writable rootfstype=ext4 elevator=deadline rootwait fixrtc quiet splash cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
EOF
  zcat -qf "/boot/firmware/vmlinuz" >"/boot/firmware/vmlinux"

  cat <<'EOF' | tee /boot/firmware/usercfg.txt
# Place "config.txt" changes (dtparam, dtoverlay, disable_overscan, etc.) in
# this file. Please refer to the README file for a description of the various
# configuration files on the boot partition.
[pi4]
max_framebuffers=2
dtoverlay=vc4-fkms-v3d
boot_delay
kernel=vmlinux
initramfs initrd.img followkernel
EOF

  cat <<'EOF' | tee /boot/auto_decompress_kernel
#!/bin/bash -e
# auto_decompress_kernel script
BTPATH=/boot/firmware
CKPATH=$BTPATH/vmlinuz
DKPATH=$BTPATH/vmlinux
# Check if compression needs to be done.
if [ -e $BTPATH/check.md5 ]; then
   if md5sum --status --ignore-missing -c $BTPATH/check.md5; then
      echo -e "\e[32mFiles have not changed, Decompression not needed\e[0m"
      exit 0
   else
      echo -e "\e[31mHash failed, kernel will be compressed\e[0m"
   fi
fi
# Backup the old decompressed kernel
mv $DKPATH $DKPATH.bak
if [ ! $? == 0 ]; then
   echo -e "\e[31mDECOMPRESSED KERNEL BACKUP FAILED!\e[0m"
   exit 1
else
   echo -e "\e[32mDecompressed kernel backup was successful\e[0m"
fi
# Decompress the new kernel
echo "Decompressing kernel: "$CKPATH".............."
zcat -qf $CKPATH > $DKPATH
if [ ! $? == 0 ]; then
   echo -e "\e[31mKERNEL FAILED TO DECOMPRESS!\e[0m"
   exit 1
else
   echo -e "\e[32mKernel Decompressed Succesfully\e[0m"
fi
# Hash the new kernel for checking
md5sum $CKPATH $DKPATH > $BTPATH/check.md5
if [ ! $? == 0 ]; then
   echo -e "\e[31mMD5 GENERATION FAILED!\e[0m"
else
   echo -e "\e[32mMD5 generated Succesfully\e[0m"
fi
exit 0
EOF

  echo 'DPkg::Post-Invoke {"/bin/bash /boot/auto_decompress_kernel"; };' | tee /etc/apt/apt.conf.d/999_decompress_rpi_kernel

}

function cloud-init-configuration() {

  cat <<'EOF' | tee /etc/cloud/cloud.cfg.d/06_user.cfg
users:
  - name: kat
    gecos: my user
    groups: [ adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video ]
    sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRGGe84zs3TxJ8BTbsiVDAsctSf2JF5AS6g/5CyGD2l kat@local-pis
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuS8Kd79MsGzWd68K7WrEIbtBM8WnsqTn0nNz1s+1V7 pi-key-mac

EOF

  cat <<'EOF' | tee /etc/cloud/cloud.cfg.d/07_network.cfg
  network:
    ethernets:
      eth0:
        dhcp4: true
        optional: false
        nameservers:
         search: [internal.serenacodes.com]
         addresses: [10.0.0.11, 8.8.8.8]
    version: 2
EOF

  cat <<'EOF' | sudo tee /etc/networkd-dispatcher/routable.d/promisc.sh

  #!/usr/bin/env sh

  sudo ip link set eth0 promisc on
EOF

}

function k8s-modules() {
  cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

  cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
}

function containerd-modules() {
  cat <<EOF | tee /etc/modules-load.d/containerd.conf
  overlay
  br_netfilter
EOF

  cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

}

function configure-containerd() {
  cat <<EOF | tee /etc/containerd/config.toml
version = 2
root = "/var/lib/containerd"
state = "/run/containerd"
plugin_dir = ""
disabled_plugins = []
required_plugins = []
oom_score = 0
[plugins]
[plugins."io.containerd.grpc.v1.cri".containerd]
snapshotter = "overlayfs"
default_runtime_name = "runc"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
SystemdCgroup = true
EOF
}

function cilium-sysctl() {
#  https://github.com/cilium/cilium/issues/10645
  cat <<EOF | tee /etc/sysctl.d/99-override_cilium_rp_filter.conf
net.ipv4.conf.lxc*.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
EOF
}

function install-kubernetes-binaries() {
  ARCH="arm64"

  CNI_VERSION="v0.8.2"
  mkdir -p /opt/cni/bin
  curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz

  DOWNLOAD_DIR=/usr/local/bin
  mkdir -p $DOWNLOAD_DIR

  CRICTL_VERSION="v1.22.0"
  curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | tar -C $DOWNLOAD_DIR -xz

  RELEASE="v1.23.6"
  RELEASE_VERSION="v0.4.0"
  (cd $DOWNLOAD_DIR; curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet,kubectl})
  (cd $DOWNLOAD_DIR; chmod +x {kubeadm,kubelet,kubectl})


  curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
  mkdir -p /etc/systemd/system/kubelet.service.d
  curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

  systemctl enable kubelet

}

kernel-nonsense
k8s-modules
containerd-modules

apt-get update
apt-get install -y openssh-server ca-certificates curl lsb-release wget gnupg sudo lm-sensors perl htop crudini bat apt-transport-https nftables conntrack
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io

configure-containerd

install-kubernetes-binaries

apt-get remove -y unattended-upgrades snapd

cloud-init-configuration

curl https://baltocdn.com/helm/signing.asc | apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
sudo apt-get install helm -y

cilium-sysctl

INSTALL

sudo chmod 0755 /tmp/install.bash
sudo cp /tmp/install.bash /mnt/install.bash

sudo systemd-nspawn -D /mnt /install.bash

sudo rm /mnt/etc/resolv.conf
sudo mv /mnt/etc/resolv.conf.bak /mnt/etc/resolv.conf

sudo umount /mnt/boot/firmware
sudo umount /mnt
sudo losetup --detach "/dev/loop0"

image_name="ubuntu-server-arm-20-04-$(date "+%F-%s").img"

mv "$ubuntu_image_name_raw" "$image_name"

xz -z -k -9 -e -T 0 -v "$image_name"

gsutil cp "${image_name}.xz" gs://pi-images.serenacodes.com/pi4-base/

NAME=$(curl -X GET http://metadata.google.internal/computeMetadata/v1/instance/name -H 'Metadata-Flavor: Google')
ZONE=$(curl -X GET http://metadata.google.internal/computeMetadata/v1/instance/zone -H 'Metadata-Flavor: Google')
gcloud --quiet compute instances delete "$NAME" --zone="$ZONE"
