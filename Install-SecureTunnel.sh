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

service_name="SecureTunnel"

echo -e "${Font_SkyBlue}SecureTunnel Installation Script Start${Font_Suffix}"

while [ -f "/etc/systemd/system/${service_name}.service" ]; do
    read -p "Service ${service_name} is exists, please input a new service name: " service_name
done

dir="/opt/${service_name}"

while [ $# -gt 0 ]; do
    case $1 in
    --api)
        api=$2
        shift
        ;;
    --id)
        id=$2
        shift
        ;;
    --secret)
        secret=$2
        shift
        ;;
    *)
        echo -e "${Font_Red} Unknown Param: $1 ${Font_Suffix}"
        exit
        ;;
    esac
    shift
done

if [ -z "${api}" ]; then
    echo -e "${Font_Red}param 'api' not found${Font_Suffix}"
    exit 1
fi
if [ -z "${id}" ]; then
    echo -e "${Font_Red}param 'id' not found${Font_Suffix}"
    exit 1
fi
if [ -z "${secret}" ]; then
    echo -e "${Font_Red}param 'secret' not found${Font_Suffix}"
    exit 1
fi

echo -e "${Font_Yellow} ** Start check system architecture${Font_Suffix}"
case $(uname -m) in
x86_64)
    cpu_flags=$(cat /proc/cpuinfo | grep flags | head -1 | awk -F ':' '{print $2}')
    if [[ ${cpu_flags} == *avx512* || ${cpu_flags} == *avx2* || ${cpu_flags} == *sse3* ]]; then
        arch="amd64v3"
        version="1.1.5"
    else
        arch="amd64v1"
        version="1.1.5"
    fi
    ;;
armv7*)
    arch="armv7"
    version="1.1.5"
    ;;
*)
    echo -e "${Font_Red}Unsupport architecture${Font_Suffix}"
    exit 1
    ;;
esac

mkdir /opt/${service_name}/ &>/dev/null
cd  /opt/${service_name}/ && curl -sSL -o SecureTunnel https://file.???.xyz/SecureTunnel_${version}_linux_${arch}  && chmod +x SecureTunnel
if [ ! -f "/opt/${service_name}/SecureTunnel" ]; then
    echo -e "${Font_Red}SecureTunnel download failed,exit...${Font_Suffix}"
    exit 1
fi

cd .. && curl -sSL  -o ${service_name}.service  https://file.???.xyz/SecureTunnel.service 
mv ${service_name}.service /etc/systemd/system/
sed -i "s#{dir}#${dir}#g" /etc/systemd/system/${service_name}.service
sed -i "s#{api}#${api}#g" /etc/systemd/system/${service_name}.service
sed -i "s#{id}#${id}#g" /etc/systemd/system/${service_name}.service
sed -i "s#{secret}#${secret}#g" /etc/systemd/system/${service_name}.service

systemctl daemon-reload
systemctl start ${service_name}
systemctl enable --now ${service_name}
echo -e "${Font_Green}[Success]Completed installation${Font_Suffix}"
