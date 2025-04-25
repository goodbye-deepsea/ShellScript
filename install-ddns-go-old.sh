#! /bin/bash
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

clear
echo -e  "${Font_Yellow}Start install wget${Font_Suffix}"
if [ -x "$(command -v apt)" ]; then
    # Ubuntu/Debian
    if ! dpkg -l | grep -q "wget"; then
        echo -e "${Font_SkyBlue}wget is not installed. Installing...${Font_Suffix}"
        apt update
        apt install wget -y
    else
        echo -e "${Font_Green}wget is already installed.${Font_Suffix}"
    fi
elif [ -x "$(command -v yum)" ]; then
    if ! rpm -q wget &> /dev/null; then
        echo -e "${Font_SkyBlue}wget is not installed. Installing...${Font_Suffix}"
        yum install wget -y
    else
        echo -e "${Font_Green}wget is already installed.${Font_Suffix}"
    fi
else
    echo -e "${Font_Red}Unsupported package manager. Please install  wget manually.${Font_Suffix}"
    exit 1
fi

wget -q -O /opt/ddns-go.tar.gz https://github.com/jeessy2/ddns-go/releases/download/v5.6.6/ddns-go_5.6.6_linux_x86_64.tar.gz
mkdir /opt/ddns-go-temp &> /dev/null
tar -xzf /opt/ddns-go.tar.gz -C /opt/ddns-go-temp

file_path="/opt/ddns-go-temp/ddns-go"
if [ ! -f ${file_path} ];then
    echo -e "${Font_Red}download fail,please check manually!${Font_Suffix}"
    exit 1
fi
cp /opt/ddns-go-temp/ddns-go /usr/local/bin/ddns-go
chmod +x /usr/local/bin/ddns-go
ddns-go -v

mkdir -p /usr/local/etc/ddns-go &> /dev/null
read  -p "please input your ddns-domain: " domain

cat << EOF > /usr/local/etc/ddns-go/config.yaml
dnsconf:
    - ipv4:
        enable: true
        gettype: url
        url: https://ifconfig.me,https://ddns.oray.com/checkip,https://ip.3322.net,https://4.ipw.cn,https://myip4.ipip.net
        netinterface: ""
        cmd: ""
        domains:
            - ${domain}
      ipv6:
        enable: false
        gettype: netInterface
        url: https://speed.neu6.edu.cn/getIP.php,https://v6.ident.me,https://6.ipw.cn
        netinterface: ""
        cmd: ""
        ipv6reg: ""
        domains:
            - ""
      dns:
        name: cloudflare
        id: ""
        secret: ???
      ttl: ""
user:
    username: root
    password: web-pwd
webhook:
    webhookurl: https://ddns-bot.vercel.app/api/hook/???
    webhookrequestbody: "{\r\n    \"ipv4\": {\r\n        \"result\": \"#{ipv4Result}\",\r\n        \"addr\": \"#{ipv4Addr}\",\r\n        \"domains\": \"#{ipv4Domains}\"\r\n    }\r\n     \r\n}"
    webhookheaders: ""
notallowwanaccess: false
EOF

cat << EOF > /etc/systemd/system/ddns-go.service 
[Unit]
Description=简单好用的DDNS。自动更新域名解析到公网IP
ConditionFileIsExecutable=/usr/local/bin/ddns-go
Requires=network.target  
After=network-online.target 

[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/local/bin/ddns-go "-l" ":9800" "-f" "300" "-cacheTimes" "5" "-c" "/usr/local/etc/ddns-go/config.yaml" "-noweb" "-dns" "1.1.1.1"
Restart=always
RestartSec=120
EnvironmentFile=-/etc/sysconfig/ddns-go

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start ddns-go
systemctl enable ddns-go

echo -e "${Font_Yellow}start clear extra files.${Font_Suffix}"
rm -rf /opt/ddns-go-temp
rm -rf /opt/ddns-go.tar.gz

systemctl status ddns-go > /dev/null 2>&1  
if [ $? -eq 0 ]; then
    echo "ddns-go works well,enjoy it!"
fi
