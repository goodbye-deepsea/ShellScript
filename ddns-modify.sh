#!/bin/bash

export TERM=xterm

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

INIT_FLAG="/mnt/.cf_ddns_initialized"
ENV_FILE="/mnt/ddns.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${Font_Yellow}配置文件 $ENV_FILE 不存在，将开始保存用户输入配置...${Font_Suffix}"
    # 用户输入配置
    read -sp "输入cf全局api密钥：" CFKEY
    echo
    read -p "输入CloudFlare 登陆邮箱（eg: mjj@gmail.com)：" CFUSER
    read -p "输入DDNS的一级域名（eg: mjj.com)：" CFZONE_NAME
    read -p "输入需要DDNS ipv4的二级域名(只需填写前缀)（eg:hkt，不需要直接跳过)：" CFRECORD_NAME_IPV4
    read -p "输入需要DDNS ipv6的二级域名(只需填写前缀)(eg:hkt-ipv6，不需要直接跳过)：" CFRECORD_NAME_IPV6
    echo

    if [ -z "$CFKEY" ] || [ -z "$CFUSER" ] || { [ -z "$CFRECORD_NAME_IPV4" ] && [ -z "$CFRECORD_NAME_IPV6" ]; }; then
        echo -e "${Font_Red}Error: 必须填写 Global API Key、CloudFlare 登陆邮箱，并且至少提供一个 DDNS 二级域名（IPv4 或 IPv6）。${Font_Suffix}"
        exit 1
    fi

    echo "CFKEY=$CFKEY" > "$ENV_FILE"
    echo "CFUSER=$CFUSER" >> "$ENV_FILE"
    echo "CFZONE_NAME=$CFZONE_NAME" >> "$ENV_FILE"
    echo "CFRECORD_NAME_IPV4=$CFRECORD_NAME_IPV4" >> "$ENV_FILE"
    echo "CFRECORD_NAME_IPV6=$CFRECORD_NAME_IPV6" >> "$ENV_FILE"
    echo -e "${Font_Green}配置已保存到 $ENV_FILE${Font_Suffix}"
fi

SCRIPT_PATH=$(realpath "$0")

make_script_executable() {
    if [[ -f "$SCRIPT_PATH" ]]; then
        chmod +x "$SCRIPT_PATH"
        echo -e  "${Font_Green}已赋予脚本执行权限：$SCRIPT_PATH${Font_Suffix}"
    else
        echo "${Font_Red}脚本文件未找到：$SCRIPT_PATH${Font_Suffix}"
        exit 1
    fi
}

add_cron_job() {
    local cron_line="*/3 * * * * ${SCRIPT_PATH} >> /var/log/cf-ddns.log 2>&1"
    
    if crontab -l 2>/dev/null | grep -Fxq "$cron_line"; then
        echo "定时任务已存在，跳过添加。日志路径：/var/log/cf-ddns.log，脚本路径：${SCRIPT_PATH}"
    else
        (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
        echo "定时任务已添加。每3分钟运行一次。日志路径：/var/log/cf-ddns.log，脚本路径：${SCRIPT_PATH}"
    fi
}

IPSITE="ip.sb"
FORCE=false

is_root() {
    [ "$(id -u)" -eq 0 ]
}

run_with_sudo() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

function install_requirement(){
    if command -v apt >/dev/null 2>&1; then 
        run_with_sudo apt update  
        run_with_sudo apt install -y curl jq dnsutils  
    elif command -v yum >/dev/null 2>&1; then
        run_with_sudo yum check-update 
        run_with_sudo yum install -y curl jq bind-utils  
    elif command -v apk >/dev/null 2>&1; then
        run_with_sudo apk update 
        run_with_sudo apk add curl jq bind-tools 
    else 
        echo "Error: Not Supported OS"
        exit 1
    fi
}

update_dns_record() {
    local  record_name=$1
    local  record_type=$2
    local  wan_ip=$3

    CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${CFZONE_NAME}"  \
-H "X-Auth-Email: ${CFUSER}"  \
-H "X-Auth-Key: ${CFKEY}"  \
-H "Content-Type: application/json"  | jq -r '.result[].id')

    if [[ -z "$CFZONE_ID" || "$CFZONE_ID" == "null" ]]; then
        echo "Failed to get zone id for ${CFZONE_NAME}"
        return
    fi

    local old_ip=$(dig +short ${record_type} ${record_name}.${CFZONE_NAME} | head -1)

    if [[ -z "${old_ip}" ]]; then
        echo -e "not found for the dns record for ${record_name}.${CFZONE_NAME},please check manually"
        return
    fi

    if [[ "$wan_ip" == "$old_ip" && "$FORCE" == "false" ]]; then
        echo "ip unchanged for ${record_name}.${CFZONE_NAME} (${wan_ip}),change FORCE to yes if you wanna change dns record forcely"
        return 
    fi

    local record_full_domain="${record_name}.${CFZONE_NAME}"

    record_id=$(
        curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CFZONE_ID}/dns_records?name=${record_full_domain}"  \
    -H "X-Auth-Email: ${CFUSER}"  \
    -H "X-Auth-Key: ${CFKEY}"   \
    -H "Content-Type: application/json"  | jq -r '.result[].id')

    if [[ -z "$record_id" || "$record_id" == "null" ]]; then
        echo "failed to fetch record id for ${record_full_domain}"
        return
    fi

    update_result=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CFZONE_ID}/dns_records/${record_id}"  \
    -H "X-Auth-Email: ${CFUSER}" -H "X-Auth-Key: ${CFKEY}" -H "Content-Type: application/json"  \
    --data "{\"id\":\"${CFZONE_ID}\",\"type\":\"${record_type^^}\",\"name\":\"${record_full_domain}\",\"content\":\"${wan_ip}\", \"ttl\":1}")
    success_flag=$(echo "$update_result" | jq -r '.success')
    if [[ "$success_flag" == "true" ]]; then
          echo "Updated succesfuly! old_ip:${old_ip}->new_ip:${wan_ip}"
    else
         echo -e 'Something went wrong : \n'
         echo "Response: $update_result"
         exit 1
    fi
}

if [ ! -f "$INIT_FLAG" ]; then
    install_requirement
    make_script_executable
    add_cron_job
    touch "$INIT_FLAG"
fi


WAN_IPv6=$(curl -s -6 "${IPSITE}")
WAN_IPv4=$(curl -s -4 "${IPSITE}")

if [[ -n "${CFRECORD_NAME_IPV6// /}" ]]; then
    update_dns_record "${CFRECORD_NAME_IPV6}" "aaaa" "${WAN_IPv6}"
fi
update_dns_record "${CFRECORD_NAME_IPV4}" "a" "${WAN_IPv4}"


