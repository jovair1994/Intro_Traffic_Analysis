
#!/bin/bash

set -e
apt-get update
apt install docker.io git python3-pip python3 curl openssh-server wireshark -y 

echo "[ ] Install RDP"

apt install xfce4 xfce4-goodies -y
apt install xrdp -y
sudo systemctl enable xrdp

cat << EOF > /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf
polkit.addRule(function(action, subject) {
 if ((action.id == "org.freedesktop.color-manager.create-device" ||
 action.id == "org.freedesktop.color-manager.create-profile" ||
 action.id == "org.freedesktop.color-manager.delete-device" ||
 action.id == "org.freedesktop.color-manager.delete-profile" ||
 action.id == "org.freedesktop.color-manager.modify-device" ||
 action.id == "org.freedesktop.color-manager.modify-profile") &&
 subject.isInGroup("{users}")) {
 return polkit.Result.YES;
 }
 });
EOF

id -u sniffer &>/dev/null || useradd -m sniffer

echo "sniffer:sniffer" | chpasswd

sudo usermod -a -G wireshark sniffer

cat << EOF >> /opt/run.sh

#!/bin/bash

while true; do

curl -s 172.17.0.2

done

EOF

chmod +x /opt/run.sh

cat << EOF >> /etc/systemd/system/runni.service

Description=running

Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=/bin/bash /opt/run.sh
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target

EOF

service runni start

systemctl enable runni

git clone https://github.com/GioF71/portainer-systemd

cd portainer-systemd/

chmod +x *

## INSTALA PORTAINER1 - 1
./install.sh

echo 'sniffer ALL=(ALL:ALL) NOPASSWD: /usr/bin/wireshark' >> /etc/sudoers

echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
# sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1"/' /etc/default/grub
# sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub
# update-grub

hostnamectl set-hostname sniffer
echo -e 'root:sn1ff3r@2024' | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config


rm -rf /etc/hosts/root/.cache
rm -rf /root/.viminfo
rm -rf /home/sniffer/._as_admin_successful
rm -rf /home/sniffer/.cache
rm -rf /home/sniffer/.viminfo

ln -sf /dev/null /root/.bash_history
ln -sf /dev/null /home/sniffer/.bash_history

reboot
