#! /bin/bash
ip_address=$(ip a s eth0 |grep 'inet '| awk '{print $2}')
network=$(echo "$ip_address" | cut -d '.' -f 1-3)
for i in ${network}.{1..254}
do
    receive=$(ping $i -c 2  | awk 'NR==6{print $4}')
    if [[ $receive -gt 0 ]];then
        echo -e "\033[33m主机${i}在线\033[0m"
        let conut++
    else
        echo -e "\033[31m主机${i}不在线\033[0m"
    fi
done
echo -e "\033[33m网络中共有${count}主机存活\033[0m"
