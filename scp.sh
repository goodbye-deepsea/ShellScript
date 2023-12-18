#!/bin/bash
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
# 获取文件路径
read -p "请输入要传输的文件路径，多文件需要用空格隔开(支持文件夹)，为避免错误必须使用绝对路径！: " file_path
if [ -z "${file_path}" ]; then
    echo -e "${Font_Red}空缺的文件地址，正在退出！${Font_Suffix}"
    exit 1
fi

# 获取目标主机和端口
read -p "请输入目标主机(ipv6必须用[ ]包裹目标地址): " host
if [ -z "${host}" ]; then
    echo -e "${Font_Red}空缺的目标主机地址，正在退出！${Font_Suffix}"
    exit 1
fi

read -p "请输入端口号: (不输入默认22)" port
if [ -z "${port}" ]; then
    port="22"
fi

# 让用户选择身份验证方式
read -p "请选择凭证类型（使用密钥连接请输入pk,使用密码连接输入pwd,不输入直接退出！）: " auth_type

if [ -z "${auth_type}" ]; then
    echo -e "${Font_Red}错误的认证凭据，正在退出！${Font_Suffix}"
    exit 1
fi

# 你要存放的目标主机位置
read -p "请输入你要存放到目标主机的位置,默认/opt,需要使用绝对路径: " target_dir
if [ -z "${target_dir}" ]; then
    target_dir="/opt/"
fi

#目标主机的用户名
read -p "请输入你在目标主机的身份,默认root: " target_user
# 如果用户没有输入任何内容，则将 target_user 设置为 root
if [ -z "${target_user}" ]; then
    target_user="root"
fi


if [[ "$auth_type" == "pk" ]]; then
    # 获取密钥位置
    read -p "请输入密钥文件路径: " key_path
    scp -r -P $port -i $key_path $file_path ${target_user}@${host}:${target_dir}
elif [[ "$auth_type" == "pwd" ]]; then
    # 获取密码
    read -s -p "请输入密码: " password
    echo
    scp -r -P $port $file_path ${target_user}@${host}:${target_dir}
else
    echo -e "${Font_Red}无效的凭证类型。请指定'密钥'路径或输入'密码'。${Font_Suffix}"
    exit 1
fi

# 检查SCP命令是否成功执行
if [ $? -eq 0 ]; then
    echo -e "${Font_Green}文件传输成功！${Font_Suffix}"
else
    echo -e "${Font_Red}连接失败或传输过程中发生错误。${Font_Suffix}"
fi
