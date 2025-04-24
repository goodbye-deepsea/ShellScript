#! /bin/bash

# 填写 Global API Key
CFKEY=a7ef2520ee26e57a085d9a5c90755186db96d

# Username, eg: user@example.com
# 填写 CloudFlare 登陆邮箱
CFUSER=lovestrawberrymoon@gmail.com

# Zone name, eg: example.com
# 填写需要用来 DDNS 的一级域名
CFZONE_NAME=233338.xyz

# Hostname to update, eg: homeserver.example.com
# 填写 DDNS 的二级域名(只需填写前缀)
CFRECORD_NAME_IPV6=hkt2-ipv6
CFRECORD_NAME_IPV4=hkt2

# Cloudflare TTL for record, between 120 and 86400 seconds
CFTTL=120

# Record type, A(IPv4)|AAAA(IPv6), default IPv4
record_type=

#在线ip对比
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
        run_with_sudo apt update  >/dev/null
        run_with_sudo apt install -y curl jq dnsutils   >/dev/null
    elif command -v yum >/dev/null 2>&1; then
        run_with_sudo yum check-update >/dev/null
        run_with_sudo yum install -y curl jq bind-utils  >/dev/null
    elif command -v apk >/dev/null 2>&1; then
        run_with_sudo apk update >/dev/null
        run_with_sudo apk add curl jq bind-tools >/dev/null
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
--data "{\"id\":\"${CFZONE_ID}\",\"type\":\"${record_type^^}\",\"name\":\"${record_full_domain}\",\"content\":\"${wan_ip}\", \"ttl\":${CFTTL}}"
)
success_flag=$(echo "$update_result" | jq -r '.success')
if [[ "$success_flag" == "true" ]]; then
      echo "Updated succesfuly! old_ip:${old_ip}->new_ip:${wan_ip}"
else
     echo -e 'Something went wrong : \n'
     echo "Response: $update_result"
     exit 1
fi

}

install_requirement

WAN_IPv6=$(curl -s -6 "${IPSITE}")
WAN_IPv4=$(curl -s -4 "${IPSITE}")

update_dns_record "${CFRECORD_NAME_IPV6}" "aaaa" "${WAN_IPv6}"
update_dns_record "${CFRECORD_NAME_IPV4}" "a" "${WAN_IPv4}"












