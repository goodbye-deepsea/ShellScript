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

# Check if iptables and netfilter-persistent is installed and install if not
if [ -x "$(command -v apt)" ]; then
    # Ubuntu/Debian
    if ! dpkg -l | grep -q "iptables" || ! dpkg -l | grep -q "netfilter-persistent" ; then
        echo "iptables or netfilter-persistent is not installed. Installing..."
        apt update
        apt install iptables netfilter-persistent -y
    else
        echo "iptables and netfilter-persistent are already installed."
    fi
elif [ -x "$(command -v yum)" ]; then
    # CentOS
    if ! rpm -q iptables &> /dev/null || ! rpm -q iptables-services &> /dev/null; then
        echo "iptables or netfilter-persistent is not installed. Installing..."
        yum install iptables iptables-services -y
    else
        echo "iptables and netfilter-persistent are already installed."
    fi
else
    echo "Unsupported package manager. Please install iptables and netfilter-persistent manually."
    exit 1
fi

ip_list_file="/opt/cfcdn_ips.txt"

if ! curl -s https://www.cloudflare.com/ips-v4 -o "$ip_list_file"; then
    echo "Failed to download Cloudflare CDN IP addresses list. Exiting."
    exit 1
fi

if [ ! -s "$ip_list_file" ]; then
    echo "Cloudflare IP list file is empty or not found. Exiting."
    exit 1
fi

echo "Clear all exists rules"
#清空所有防火墙规则
iptables -F
#删除用户自定义的链
iptables -X
#清空链的计数
iptables -Z

echo "Insert new rules"
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp -s 1.2.3.4/24 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -s 5.6.7.8 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -s 20.20.20.20 --dport 22 -j ACCEPT

iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# 允许 Docker 网络的通信
iptables -A INPUT -i br-3339f52ce165 -j ACCEPT
iptables -A INPUT -i br-262905ad71c0 -j ACCEPT
iptables -A INPUT -i docker0 -j ACCEPT

iptables -A OUTPUT -o br-3339f52ce165 -j ACCEPT
iptables -A OUTPUT -o br-262905ad71c0 -j ACCEPT
iptables -A OUTPUT -o docker0 -j ACCEPT

iptables -A FORWARD -i br-3339f52ce165 -o eth0 -j ACCEPT
iptables -A FORWARD -i br-262905ad71c0 -o eth0 -j ACCEPT

while read -r ip; do
    iptables -A INPUT -p tcp -m multiport --dports http,https -s "$ip" -j ACCEPT
done < "${ip_list_file}"

iptables -A INPUT -p tcp -m multiport --dports http,https -j DROP

iptables -A INPUT -p tcp -s 172.23.0.0/16 --dport 3306 -j ACCEPT
iptables -A INPUT -p tcp -s 172.23.0.0/16 --dport 33060 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type 8 -j DROP

iptables -P INPUT DROP 
echo "Finished!"
