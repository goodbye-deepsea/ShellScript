#!/bin/bash
clear
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

echo "Save nat rules"
mkdir /etc/iptables &> /dev/null
touch /etc/iptables/rules.v4  &> /dev/null
iptables-save > /etc/iptables/rules.v4

# 检查文件是否存在
if [ ! -f "/etc/systemd/system/recover-iptables.service" ]; then
    echo -e "${Font_Yellow}systemd service don't exist,creating...${Font_Suffix}"
    # 创建文件并写入内容
    cat <<EOF > /etc/systemd/system/recover-iptables.service
[Unit]
Description=recover iptables rules on boot
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4

[Install]
WantedBy=multi-user.target
EOF

    # 启用和启动服务
    systemctl daemon-reload
    systemctl enable recover-iptables.service
    systemctl start recover-iptables.service
else
    echo "File /etc/systemd/system/recover-iptables.service already exists. Skipping."
fi

echo "Done,you iptables rules are:"
iptables -nL
