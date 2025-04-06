#!/bin/bash
#mount swap

clear

if [ -f "/swapfile" ] || [ -f "/swapspace" ]; then
    echo "Removing existing swapfile..."
    swapoff /swapfile &>/dev/null
    swapoff /swapspace &>/dev/null
    rm -f /swapfile  /swapspace &>/dev/null
    # Remove the swap entry from /etc/fstab
    sed -i '/\/swapfile/d' /etc/fstab
    sed -i '/\/swapspace/d' /etc/fstab
fi

if [ -x "$(command -v apt)" ]; then
    # Ubuntu/Debian
    read -p "Please input a swap file size (example: 2G): " size
    echo "Allocating a new swap file..."
    fallocate -l ${size} /swapfile
elif [ -x "$(command -v yum)" ]; then
    # CentOS
    read -p "Please input a swap file size (example: 4)(必须为整数,且不用加G,否则报错！！！): " size
    echo "Allocating a new swap file..."
    dd if=/dev/zero of=/swapfile bs=1M count=$((size * 1024))
else
    echo "Unsupported package manager. Please allocate swap file  manually."
    exit 1
fi

chmod 600 /swapfile
mkswap /swapfile

# Add the new swap entry to /etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
swapon /swapfile
if [ $? -eq 0 ];then
    echo "Swapfile has been created and mounted successfully."
else
    echo "Something wrong,please check it manually!"
fi
# show status of mount swap 
swapon --show