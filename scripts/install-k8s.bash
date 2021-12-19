#!/usr/bin/env bash

set -exo pipefail

# need to update world downloader thing to grab latest image
# add tracing to world downloader
# setup goreleaser for it?
# setup github actions for repo
# decompress image
# download image and mount it via `losetup -Pf ./arch-linux-arm-2021-11-23-1637701283.img`
# do config via nspawn
# upload it to the bucket


echo "installing k8s on top of base image"

image_name="arch-linux-pi4-arm-2021-12-30-1640905392"
gsutil cp "gs://pi-images.serenacodes.com/${image_name}.img.xz" ./
xz -d "${image_name}.img.xz"
sudo losetup -Pf "${image_name}.img"

sudo mount /dev/loop0p2 /mnt/
sudo mount /dev/loop0p1 /mnt/boot/

cat << 'INSTALL' > /tmp/install.bash
#!/usr/bin/env bash

ARCH="arm64"
VERSION="1.23.0"
set -exo pipefail

function setup_kubernetes_sysctl() {

  cat <<EOF | sudo tee /etc/modules-load.d/kubernetes.conf
  br_netfilter
EOF

  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
EOF

}

function setup_container_runtime() {

  sudo pacman -S --noconfirm cri-o=1.23.0-1 crictl cni-plugins

  cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
    overlay
    br_netfilter
EOF

  cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
  net.bridge.bridge-nf-call-iptables  = 1
  net.ipv4.ip_forward                 = 1
  net.bridge.bridge-nf-call-ip6tables = 1
EOF

  sudo crudini --set --list --list-sep=" " /etc/pacman.conf options IgnorePkg "cri-o crictl"

  sudo systemctl enable crio

}

function install_component() {
  binary=$1
  curl -LO "https://dl.k8s.io/release/v${VERSION}/bin/linux/${ARCH}/${binary}"
  curl -LO "https://dl.k8s.io/v${VERSION}/bin/linux/${ARCH}/${binary}.sha256"

  echo "$(<"${binary}.sha256") ${binary}" | sha256sum --check

  sudo install -o root -g root -m 0755 "${binary}" "/usr/local/bin/${binary}"
}

function install_kubectl() {

  install_component "kubectl"

  kubectl version --client
}

function install_kubeadm() {

  install_component "kubeadm"

  kubeadm version
}

function install_kubelet() {

  DOWNLOAD_DIR=/usr/local/bin
  sudo mkdir -p $DOWNLOAD_DIR

  install_component "kubelet"

  kubelet --version

  RELEASE_VERSION="v0.4.0"
  curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
  sudo mkdir -p /etc/systemd/system/kubelet.service.d
  curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

  systemctl enable kubelet

}

setup_kubernetes_sysctl
setup_container_runtime
install_kubectl
install_kubeadm
install_kubelet

INSTALL

sudo chmod 0755 /tmp/install.bash
sudo cp /tmp/install.bash /mnt/install.bash
sudo mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.bak
sudo cp /etc/resolv.conf /mnt/etc/resolv.conf

sudo systemd-nspawn -D /mnt /install.bash

sudo rm /mnt/etc/resolv.conf
sudo mv /mnt/etc/resolv.conf.bak /mnt/etc/resolv.conf

sudo umount /mnt/boot
sudo umount /mnt
sudo losetup --detach "/dev/loop0"
k8s_image_name="${image_name}-k8s.img"
mv "${image_name}.img" "$k8s_image_name"

xz -z -k -9 -e -T 0 -v "$k8s_image_name"

gsutil cp "${k8s_image_name}.xz" gs://pi-images.serenacodes.com/
NAME=$(curl -X GET http://metadata.google.internal/computeMetadata/v1/instance/name -H 'Metadata-Flavor: Google')
ZONE=$(curl -X GET http://metadata.google.internal/computeMetadata/v1/instance/zone -H 'Metadata-Flavor: Google')
gcloud --quiet compute instances delete "$NAME" --zone="$ZONE"
