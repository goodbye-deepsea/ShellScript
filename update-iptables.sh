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


PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
source /etc/environment

# Check if iptables,netfilter-persistent,net-tools is installed and install if not
if [ -x "$(command -v apt)" ]; then
    # Ubuntu/Debian
    if ! dpkg -l | grep -q "iptables" || ! dpkg -l | grep -q "netfilter-persistent" || ! dpkg -l | grep -q "net-tools" || ! dpkg -l | grep -q "dnsutils"; then
        echo -e "${Font_Yellow}iptables or netfilter-persistent or net-tools or dnsutils are not installed. Installing...${Font_Suffix}"
        apt update 
        apt install iptables netfilter-persistent net-tools dnsutils -y
    else
        echo -e  "${Font_Green}iptables and netfilter-persistent and net-tools and dnsutils are already installed.${Font_Suffix}"
    fi
elif [ -x "$(command -v yum)" ]; then
    # CentOS
    if ! rpm -q iptables &> /dev/null || ! rpm -q iptables-services &> /dev/null || ! rpm -q net-tools &> /dev/null; then
        echo -e "${Font_Yellow}iptables or netfilter-persistent or net-tools or dnsutils are not installed. Installing...${Font_Suffix}"
        yum install iptables  iptables-services net-tools dnsutils -y
    else
        echo -e  "${Font_Green}iptables and netfilter-persistent and net-tools and dnsutils are already installed.${Font_Suffix}"
    fi
else
    echo "${Font_Red}Unsupported package manager. Please install iptables,net-tools,netfilter-persistent manually.${Font_Suffix}"
    exit 1
fi

CURRENT_DOMAIN_AZHK=$(dig +short hkcdn.??????.xyz)
CURRENT_DOMAIN_HKT=$(dig +short hkt.??????.me)

# 检查变量是否为空
if [ -z ${DOMAIN_AZHK} ] || \
   [ ${CURRENT_DOMAIN_AZHK} != ${DOMAIN_AZHK} ] || \
   [ -z ${DOMAIN_HKT} ] || \
   [ ${CURRENT_DOMAIN_HKT} != ${DOMAIN_HKT} ] || \
   [ -z ${INET_IP} ]; then
    # 如果变量为空，执行以下操作
    echo -e "${Font_Red}One or more variables are empty or change. Updating variables...${Font_Suffix}"

    update_var() {
        local var_name="$1"
        local var_value="$2"
        # 允许的变量名列表
        allowed_vars=("DOMAIN_AZHK" "DOMAIN_HKT")
        # 检查 var_name 是否在允许的列表中
        if [[ " ${allowed_vars[@]} " =~ " ${var_name} " ]]; then
            if grep -q "export ${var_name}=" /etc/environment; then
                sed -i "s/export ${var_name}=.*/export ${var_name}=\"${var_value}\"/" /etc/environment
            else
                echo "export ${var_name}=\"${var_value}\"" >> /etc/environment
            fi
        else
            echo "Skipping unnecessary variable ${var_name}"
        fi
    }
    DOMAIN_AZHK=$(dig +short hkcdn.??????.xyz)
    DOMAIN_HKT=$(dig +short hkt.??????.me)
    INET_IP=$(ifconfig eth0 | awk '/inet /{print $2}')

    update_var "DOMAIN_AZHK" ${DOMAIN_AZHK}
    update_var "DOMAIN_HKT" ${DOMAIN_HKT}
    update_var "INET_IP" ${INET_IP}

    source /etc/environment
else
    echo "All variables are already set... Continue"
fi


echo "Empty all exists nat rules"
iptables -t nat -F
echo "Insert new nat rules"
iptables -t nat -A PREROUTING -p tcp --dport 23100 -j DNAT --to-destination ${DOMAIN_AZHK}
iptables -t nat -A PREROUTING -p udp --dport 23100 -j DNAT --to-destination ${DOMAIN_AZHK}
iptables -t nat -A POSTROUTING -p tcp -d ${DOMAIN_AZHK} --dport 23100 -j SNAT --to-source ${INET_IP}
iptables -t nat -A POSTROUTING -p udp -d ${DOMAIN_AZHK} --dport 23100 -j SNAT --to-source ${INET_IP}

iptables -t nat -A PREROUTING -p tcp --dport 23200 -j DNAT --to-destination ${DOMAIN_HKT}
iptables -t nat -A PREROUTING -p udp --dport 23200 -j DNAT --to-destination ${DOMAIN_HKT}
iptables -t nat -A POSTROUTING -p tcp -d ${DOMAIN_HKT} --dport 23200 -j SNAT --to-source ${INET_IP}
iptables -t nat -A POSTROUTING -p udp -d ${DOMAIN_HKT} --dport 23200 -j SNAT --to-source ${INET_IP}

echo "Save nat rules"
mkdir /etc/iptables &> /dev/null
touch /etc/iptables/rules.v4  &> /dev/null
iptables-save > /etc/iptables/rules.v4

# 检查文件是否存在
if [ ! -f "/etc/systemd/system/restore-iptables.service" ]; then
    echo -e "${Font_Yellow}systemd service don't exist,creating...${Font_Suffix}"
    # 创建文件并写入内容
    cat <<EOF > /etc/systemd/system/restore-iptables.service
[Unit]
Description=Restore iptables rules on boot
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore  /etc/iptables/rules.v4

[Install]
WantedBy=multi-user.target
EOF

    # 启用和启动服务
    systemctl daemon-reload
    systemctl enable restore-iptables.service
    systemctl start restore-iptables.service
else
    echo "File /etc/systemd/system/restore-iptables.service already exists. Skipping."
fi

echo "Done,you nat rule are:"
iptables -t nat -nL
