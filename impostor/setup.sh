#!/bin/bash

# Setup firewall
ufw reset
ufw default deny
ufw limit ssh
ufw enable

# Setup ssh
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Create user
useradd -mG wheel impostor
passwd -d impostor
mkdir -p /home/impostor/.ssh
cp ~/.ssh/authorized_keys /home/impostor/.ssh/authorized_keys
chown -R impostor:impostor /home/impostor/.ssh
chmod 755 /home/impostor/.ssh
chmod 644 /home/impostor/.ssh/authorized_keys

# Update and install packages
echo 'Server = https://mirrors.cat.net/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
pacman -Syyu --ignore linux-lts --noconfirm --needed docker docker-compose sudo
systemctl enable --now docker

# Modify user
usermod -aG docker impostor
echo -n '%wheel ALL=(ALL) ALL' >> /etc/sudoers
echo >> /etc/sudoers

# run impostor
su impostor -c "bash"
curl -fsL https://github.com/motorailgun/home-infra/raw/master/impostor/docker-compose.yaml -o /home/impostor/docker-compose.yaml
curl -fsL https://github.com/motorailgun/home-infra/raw/master/impostor/config.json -o /home/impostor/config.json
curl -fsL https://github.com/motorailgun/home-infra/raw/master/impostor/config_http.json -o /home/impostor/config_http.json
cd /home/impostor && docker-compose up -d
exit

# set ufw to allow impostor
ufw allow from any to any port 22023 proto any
ufw allow from any to any port 80 proto tcp
ufw allow from any to any port 443 proto tcp
ufw reload

# remove cloud-init ssh config
rm /etc/ssh/sshd_config.d/50-cloud-init.conf
systemctl restart sshd
