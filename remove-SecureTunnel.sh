#! /bin/bash
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

if [ -d "/opt/SecureTunnel" ] || [ -f "/etc/systemd/system/SecureTunnel.service" ]; then
    systemctl stop SecureTunnel &> /dev/null
    systemctl disable SecureTunnel &> /dev/null
    rm -rf /opt/SecureTunnel
    rm -rf /etc/systemd/system/SecureTunnel.service 
    echo -e "${Font_Yellow}SecureTunnel has been deleted${Font_Suffix}"
else 
    echo -e "${Font_Red}File not exixts${Font_Suffix}"
fi
