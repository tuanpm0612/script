#!/bin/bash

# 1. Gỡ bỏ UFW triệt để
echo "Removing UFW..."
systemctl stop ufw
systemctl disable ufw
apt-get remove --purge ufw -y
rm -rf /etc/ufw

# 2. Cài đặt công cụ lưu rules iptables (Quan trọng để Reboot không mất)
echo "Installing persistent tools..."
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent netfilter-persistent

# 3. Tạo file cấu hình sạch (Mở toàn bộ port)
echo "Creating default allow rules..."
mkdir -p /etc/iptables
cat << EOT > /etc/iptables/rules.v4
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
EOT

# 4. Áp dụng rules ngay lập tức
echo "Applying iptables rules..."
iptables-restore < /etc/iptables/rules.v4

# 5. Lưu lại cấu hình để chắc chắn reboot vẫn nhớ
netfilter-persistent save
systemctl enable netfilter-persistent

# 6. Khôi phục mạng cho Docker (Vì bước trên đã lỡ xóa rules của Docker)
if systemctl is-active --quiet docker; then
    echo "Restarting Docker to restore container networking..."
    systemctl restart docker
fi

echo "DONE! Server is now open and ready."
