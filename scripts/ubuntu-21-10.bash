#!/usr/bin/env bash

set -exo pipefail

# fucking hell this is jank af

wget https://cdimage.ubuntu.com/releases/21.10/release/ubuntu-21.10-preinstalled-server-arm64+raspi.img.xz
echo "126f940d3b270a6c1fc5a183ac8a3d193805fead4f517296a7df9d3e7d691a03 *ubuntu-21.10-preinstalled-server-arm64+raspi.img.xz" | shasum -a 256 --check

xz -dk ubuntu-21.10-preinstalled-server-arm64+raspi.img.xz

sudo losetup -Pf ubuntu-21.10-preinstalled-server-arm64+raspi.img

sudo truncate -c -s +2048M ubuntu-21.10-preinstalled-server-arm64+raspi.img
IN=$(sudo parted /dev/loop0 print -m -s | tail -n 1)
# shellcheck disable=SC2206
# this is intentional splitting my dear linter!
arrIN=(${IN//:/ })

sudo parted /dev/loop0 resizepart 2 "${arrIN[2]}" -s
sudo e2fsck -p -f /dev/loop0p2
sudo resize2fs /dev/loop0p2

sudo mount /dev/loop0p2 /mnt/
sudo mount /dev/loop0p1 /mnt/boot/firmware

sudo mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.bak
sudo cp /etc/resolv.conf /mnt/etc/resolv.conf

cat << 'INSTALL' > /tmp/install.bash
#!/usr/bin/env bash

# follow guide here https://disconnected.systems/blog/raspberry-pi-archlinuxarm-setup/

set -exo pipefail

function kernel-nonsense() {
  cat <<'EOF' | tee /boot/firmware/cmdline.txt
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=LABEL=writable rootfstype=ext4 elevator=deadline rootwait fixrtc quiet splash cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
EOF
}

function cloud-init-fix() {

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
        optional: false
        nameservers:
         search: [internal.serenacodes.com]
         addresses: [10.0.0.11, 8.8.8.8]
    version: 2
EOF

}

function k8s-modules() {
  cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
veth
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

[grpc]
  address = "/run/containerd/containerd.sock"
  tcp_address = ""
  tcp_tls_cert = ""
  tcp_tls_key = ""
  uid = 0
  gid = 0
  max_recv_message_size = 16777216
  max_send_message_size = 16777216

[ttrpc]
  address = ""
  uid = 0
  gid = 0

[debug]
  address = ""
  uid = 0
  gid = 0
  level = ""

[metrics]
  address = ""
  grpc_histogram = false

[cgroup]
  path = ""

[timeouts]
  "io.containerd.timeout.shim.cleanup" = "5s"
  "io.containerd.timeout.shim.load" = "5s"
  "io.containerd.timeout.shim.shutdown" = "3s"
  "io.containerd.timeout.task.state" = "2s"

[plugins]
  [plugins."io.containerd.gc.v1.scheduler"]
    pause_threshold = 0.02
    deletion_threshold = 0
    mutation_threshold = 100
    schedule_delay = "0s"
    startup_delay = "100ms"
  [plugins."io.containerd.grpc.v1.cri"]
    disable_tcp_service = true
    stream_server_address = "127.0.0.1"
    stream_server_port = "0"
    stream_idle_timeout = "4h0m0s"
    enable_selinux = false
    selinux_category_range = 1024
    sandbox_image = "k8s.gcr.io/pause:3.2"
    stats_collect_period = 10
    systemd_cgroup = false
    enable_tls_streaming = false
    max_container_log_line_size = 16384
    disable_cgroup = false
    disable_apparmor = false
    restrict_oom_score_adj = false
    max_concurrent_downloads = 3
    disable_proc_mount = false
    unset_seccomp_profile = ""
    tolerate_missing_hugetlb_controller = true
    disable_hugetlb_controller = true
    ignore_image_defined_volumes = false
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
      default_runtime_name = "runc"
      no_pivot = false
      disable_snapshot_annotations = true
      discard_unpacked_layers = false
      [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime]
        runtime_type = ""
        runtime_engine = ""
        runtime_root = ""
        privileged_without_host_devices = false
        base_runtime_spec = ""
      [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime]
        runtime_type = ""
        runtime_engine = ""
        runtime_root = ""
        privileged_without_host_devices = false
        base_runtime_spec = ""
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          runtime_engine = ""
          runtime_root = ""
          privileged_without_host_devices = false
          base_runtime_spec = ""
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "/opt/cni/bin"
      conf_dir = "/etc/cni/net.d"
      max_conf_num = 1
      conf_template = ""
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://registry-1.docker.io"]
    [plugins."io.containerd.grpc.v1.cri".image_decryption]
      key_model = ""
    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
      tls_cert_file = ""
      tls_key_file = ""
  [plugins."io.containerd.internal.v1.opt"]
    path = "/opt/containerd"
  [plugins."io.containerd.internal.v1.restart"]
    interval = "10s"
  [plugins."io.containerd.metadata.v1.bolt"]
    content_sharing_policy = "shared"
  [plugins."io.containerd.monitor.v1.cgroups"]
    no_prometheus = false
  [plugins."io.containerd.runtime.v1.linux"]
    shim = "containerd-shim"
    runtime = "runc"
    runtime_root = ""
    no_shim = false
    shim_debug = false
  [plugins."io.containerd.runtime.v2.task"]
    platforms = ["linux/arm64/v8"]
  [plugins."io.containerd.service.v1.diff-service"]
    default = ["walking"]
  [plugins."io.containerd.snapshotter.v1.devmapper"]
    root_path = ""
    pool_name = ""
    base_image_size = ""
    async_remove = false
EOF
}

function cilium-sysctl() {
#  https://github.com/cilium/cilium/issues/10645
  echo 'net.ipv4.conf.lxc*.rp_filter = 0' > /etc/sysctl.d/99-override_cilium_rp_filter.conf

}

k8s-modules
containerd-modules

apt-get update
apt-get install -y openssh-server ca-certificates curl lsb-release wget gnupg sudo lm-sensors perl htop crudini bat \
  apt-transport-https nftables linux-modules-extra-raspi
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y containerd.io

configure-containerd

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y kubelet kubeadm kubectl

apt-mark hold kubelet kubeadm kubectl

apt-get remove -y unattended-upgrades snapd

cloud-init-fix

curl https://baltocdn.com/helm/signing.asc |  sudo tee /etc/apt/trusted.gpg.d/helm-repo.asc
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
sudo apt-get install helm -y

cilium-sysctl

curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-arm64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-arm64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-arm64.tar.gz /usr/local/bin
rm cilium-linux-arm64.tar.gz{,.sha256sum}

INSTALL

# TODO install bpftools via linux-tools-common and stern

sudo chmod 0755 /tmp/install.bash
sudo cp /tmp/install.bash /mnt/install.bash

sudo systemd-nspawn -D /mnt /install.bash

sudo rm /mnt/etc/resolv.conf
sudo mv /mnt/etc/resolv.conf.bak /mnt/etc/resolv.conf

sudo umount /mnt/boot/firmware
sudo umount /mnt
sudo losetup --detach "/dev/loop0"

image_name="ubuntu-server-21-10-arm-$(date "+%F-%s").img"

mv ubuntu-21.10-preinstalled-server-arm64+raspi.img "$image_name"

xz -z -k -9 -e -T 0 -v "$image_name"

gsutil cp "${image_name}.xz" gs://pi-images.serenacodes.com/pi4-base/

NAME=$(curl -X GET http://metadata.google.internal/computeMetadata/v1/instance/name -H 'Metadata-Flavor: Google')
ZONE=$(curl -X GET http://metadata.google.internal/computeMetadata/v1/instance/zone -H 'Metadata-Flavor: Google')
gcloud --quiet compute instances delete "$NAME" --zone="$ZONE"
