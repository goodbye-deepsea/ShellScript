#! /bin/bash
clear

Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Suffix="\033[0m"

cat << EOF > /etc/sysctl.conf
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.icmp_echo_ignore_all = 0
EOF

sysctl -p

if [ $? -ne 0 ]; then
    echo -e "${Font_Red}something wrong,you should check your kernel and update manually!${Font_Suffix}" 
else
    echo -e "${Font_Green}已开启BBR加速及nat转发, 配置文件对应：/etc/sysctl.d/99-sysctl.conf${Font_Suffix}"
fi
