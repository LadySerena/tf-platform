#!/usr/bin/env bash

set -eo pipefail

echo 'setting up files for raspberry pi image'
fallocate -l 3.5G "custom-pi.img"
sudo losetup --find --show "custom-pi.img"
sudo parted --script /dev/loop0 mklabel msdos
sudo parted --script /dev/loop0 mkpart primary fat32 0% 150M
sudo parted --script /dev/loop0 mkpart primary ext4 150M 100%
sudo mkfs.vfat -F32 /dev/loop0p1
sudo mkfs.ext4 -F /dev/loop0p2
sudo mount /dev/loop0p2 /mnt
sudo mkdir /mnt/boot
sudo mount /dev/loop0p1 /mnt/boot
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz.md5
md5sum --check ArchLinuxARM-rpi-aarch64-latest.tar.gz.md5
sudo tar -xpf "ArchLinuxARM-rpi-aarch64-latest.tar.gz" -C /mnt
sudo mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.bak
sudo cp /etc/resolv.conf /mnt/etc/resolv.conf
echo 'finished setup now beginning image customization'
cat << 'INSTALL' > /tmp/install.bash
#!/usr/bin/env bash
# follow guide here https://disconnected.systems/blog/raspberry-pi-archlinuxarm-setup/

set -eo pipefail

pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu --noconfirm
pacman -Sy --noconfirm --needed openssh ca-certificates curl lsb-release zsh wget parted gnupg containerd sudo lm_sensors perl uboot-tools python python-setuptools python-pip
sed -i 's/mmcblk0p1/sda1/g' /etc/fstab
cat /etc/fstab
sed -i 's/MODULES=()/MODULES=(pcie_brcmstb)/g' /etc/mkinitcpio.conf && mkinitcpio -P
cat /etc/mkinitcpio.conf
pip install crudini
crudini --set /etc/systemd/network/en.network Network DNS 8.8.8.8
crudini --set /etc/systemd/network/en.network DHCPv4 UseDNS false
crudini --set /etc/systemd/network/en.network DHCPv6 UseDNS false
# https://wiki.archlinux.org/title/Systemd-networkd#Configuration_files

# set the bootargs to console=ttyS1,115200 console=tty0 root=PARTUUID=${uuid} rw rootwait smsc95xx.macaddr="${usbethaddr}" cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset in /boot/boot.txt and run /boot/mkscr
# getting unknown parameters error
# Unknown command line parameters: cgroup_enable=cpuset cgroup_memory=1
sed -i 's/setenv.*/setenv bootargs console=ttyS1,115200 console=tty0 root=PARTUUID=${uuid} rw rootwait smsc95xx.macaddr="${usbethaddr}" cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset/g' /boot/boot.txt
cat /boot/boot.txt
cd /boot
/boot/mkscr
cd ~

userdel --remove alarm

groupadd katadmin

useradd -m -G katadmin -s /bin/zsh kat
chpasswd <<< "kat:$(openssl rand 22 | base64)"
passwd -S kat
echo '%katadmin ALL=(ALL) NOPASSWD: ALL' | EDITOR='tee' visudo -f /etc/sudoers.d/katadmin
sudo -ukat mkdir -p -m=00700 /home/kat/.ssh
sudo -ukat touch /home/kat/.ssh/authorized_keys
chmod 0600 /home/kat/.ssh/authorized_keys
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRGGe84zs3TxJ8BTbsiVDAsctSf2JF5AS6g/5CyGD2l kat@local-pis' > /home/kat/.ssh/authorized_keys
cat << EOF > /etc/ssh/sshd_config
# Supported HostKey algorithms by order of preference.
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key

KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com

# Password based logins are disabled - only public key based logins are allowed.
AuthenticationMethods publickey

# LogLevel VERBOSE logs user's key fingerprint on login. Needed to have a clear audit track of which key was using to log in.
LogLevel VERBOSE

# Log sftp level file access (read/write/etc.) that would not be easily logged otherwise.
Subsystem sftp  /usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO

# Root login is not allowed for auditing reasons. This is because it's difficult to track which process belongs to which root user:
#
# On Linux, user sessions are tracking using a kernel-side session id, however, this session id is not recorded by OpenSSH.
# Additionally, only tools such as systemd and auditd record the process session id.
# On other OSes, the user session id is not necessarily recorded at all kernel-side.
# Using regular users in combination with /bin/su or /usr/bin/sudo ensure a clear audit track.
PermitRootLogin No

# Use kernel sandbox mechanisms where possible in unprivileged processes
# Systrace on OpenBSD, Seccomp on Linux, seatbelt on MacOSX/Darwin, rlimit elsewhere.
UsePrivilegeSeparation sandbox

# allow my ssh user to login but not the serial user
AllowUsers kat
EOF

INSTALL
echo 'finished customizing image now compressing'
sudo chmod 0755 /tmp/install.bash
sudo cp /tmp/install.bash /mnt/install.bash

sudo systemd-nspawn -D /mnt /install.bash

image_name="arch-linux-arm-$(date "+%F-%s").img"

sudo rm /mnt/etc/resolv.conf
sudo mv /mnt/etc/resolv.conf.bak /mnt/etc/resolv.conf

sudo umount /mnt/boot
sudo umount /mnt
sudo losetup --detach "/dev/loop0"

mv "custom-pi.img" "$image_name"

xz -z -k -9 -e -T 0 -v "$image_name"

gsutil cp "${image_name}.xz" gs://pi-images.serenacodes.com/
NAME=$(curl -X GET http://metadata.google.internal/computeMetadata/v1/instance/name -H 'Metadata-Flavor: Google')
ZONE=$(curl -X GET http://metadata.google.internal/computeMetadata/v1/instance/zone -H 'Metadata-Flavor: Google')
gcloud --quiet compute instances delete "$NAME" --zone="$ZONE"