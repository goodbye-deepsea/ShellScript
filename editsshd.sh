#!/bin/bash
#disable PasswordAuthentication && ChallengeResponseAuthentication
config_file="/etc/ssh/sshd_config"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_SUFFIX="\033[0m"

# Check if the config file exists
if [ ! -f "${config_file}" ]; then
    echo -e "${COLOR_RED}The SSH configuration file '${config_file}' does not exist.${COLOR_SUFFIX}"
    exit 1
fi

backup_file="${config_file}.$(date +%Y%m%d).bak"
echo -e "${COLOR_YELLOW}Start backup old ssh config file.${COLOR_SUFFIX}"
cp "${config_file}" "${backup_file}" && echo -e "${COLOR_GREEN}Backup successful: ${backup_file}${COLOR_SUFFIX}"

# Uncomment PubkeyAuthentication if it's commented
sed -i  '/^#PubkeyAuthentication/s/^#//' "${config_file}"

# Uncomment AuthorizedKeysFile lines if they are commented
sed -i  '/^#AuthorizedKeysFile/s/^#//' "${config_file}"

# Uncomment Include /etc/ssh/sshd_config.d/*.conf files if they are exists
sed -i  's|^Include /etc/ssh/sshd_config\.d/\*\.conf|#&|g' "${config_file}"

# Change PasswordAuthentication yes to PasswordAuthentication no
if grep -q "^PasswordAuthentication yes" "${config_file}"; then
    sed -i  's/^PasswordAuthentication yes/PasswordAuthentication no/' "${config_file}"
else
    echo -e "${COLOR_YELLOW}The 'PasswordAuthentication yes' line is not found in ${config_file}.PasswordAuthentication may have been closed!${COLOR_SUFFIX}"
fi

if grep -q "^#PasswordAuthentication yes" "${config_file}"; then
    sed -i  's/^#PasswordAuthentication yes/PasswordAuthentication no/' "${config_file}"
else
    echo -e "${COLOR_YELLOW}The '#PasswordAuthentication yes' line is not found in ${config_file}.PasswordAuthentication may have been closed!${COLOR_SUFFIX}"
fi

# Change #UseDNS yes to UseDNS no
if [ -x "$(command -v yum)" ]; then
    if grep -q "^#UseDNS yes" "${config_file}"; then
        sed -i -e 's/^#UseDNS yes/UseDNS no/' "${config_file}"
    else
        echo -e  "${COLOR_YELLOW}The '#UseDNS yes' line is not found in ${config_file}.${COLOR_SUFFIX}"
    fi
fi

if grep -q "^ChallengeResponseAuthentication" "${config_file}"; then
    sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "${config_file}"
    echo -e "${COLOR_GREEN}ChallengeResponseAuthentication have been disabled successfully!${COLOR_SUFFIX}"
else
    echo "ChallengeResponseAuthentication no" >> "${config_file}"
    echo -e "${COLOR_GREEN}ChallengeResponseAuthentication have been disabled successfully!${COLOR_SUFFIX}"
fi

# Check for '#UsePAM no' and change it to 'UsePAM yes'
if grep -q "#UsePAM no" "${config_file}"; then
    sed -i 's/^#UsePAM no/UsePAM yes/g' "${config_file}"
    echo -e "${COLOR_GREEN}Changed '#UsePAM no' to 'UsePAM yes' in ${config_file}.${COLOR_SUFFIX}"
elif ! grep -q "^UsePAM yes" "${config_file}"; then
    echo "UsePAM yes" >> "${config_file}"
    echo -e "${COLOR_GREEN}Added 'UsePAM yes' to ${config_file}.${COLOR_SUFFIX}"
fi

if grep -q "PermitRootLogin no" "${config_file}"; then
    sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' "${config_file}"
    echo -e "${COLOR_YELLOW}PermitRootLogin set to yes!${COLOR_SUFFIX}"
elif grep -q "PermitRootLogin yes" "${config_file}";then
    echo -e "${COLOR_GREEN}Root login is already permitted${COLOR_SUFFIX}"
else
    echo "PermitRootLogin yes" >> "${config_file}"
    echo -e "${COLOR_YELLOW}PermitRootLogin set to yes${COLOR_SUFFIX}"
fi

if grep -q "GSSAPIAuthentication yes" "${config_file}"; then 
    sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/g' "${config_file}"
    echo -e "${COLOR_GREEN}GSSAPIAuthentication is already closed${COLOR_SUFFIX}"
fi

echo -e  "${COLOR_GREEN}all change is done,restart sshd${COLOR_SUFFIX}"
# &符号用于明确指出我们在讨论文件描述符，而不是标准输出
systemctl restart sshd > /dev/null 2>&1
if [ $? -ne 0 ];then
    echo  -e "${COLOR_RED}sshd config have something wrong,you should check it manually!!!${COLOR_SUFFIX}"
else
    echo  -e "${COLOR_GREEN}PasswordAuthentication and ChallengeResponseAuthentication have disabled successfully!${COLOR_SUFFIX}"
fi

