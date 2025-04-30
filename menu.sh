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

echo -e "${Font_Blue}==============================${Font_Suffix}"
echo -e "${Font_Blue}       欢迎使用玩机工具箱        ${Font_Suffix}"
echo -e "${Font_Blue}        Auther: NS-IU         ${Font_Suffix}"
echo -e "${Font_Blue}==============================${Font_Suffix}"
echo -e "${Font_Blue}1. 增加私钥并用密码保护该密钥${Font_Suffix}"
echo -e "${Font_Blue}2. 关闭密码登录，开启密钥登录${Font_Suffix}"
echo -e "${Font_Blue}3. DDNS懒人版${Font_Suffix}"
echo -e "${Font_Blue}4. 启用BBR加速${Font_Suffix}"
echo -e "${Font_Blue}5. 添加交换分区${Font_Suffix}"
echo -e "${Font_Blue}6. nezha-v0对接脚本${Font_Suffix}"
echo -e "${Font_Blue}7. 重装系统KVM-感谢leitbogioro${Font_Suffix}"
echo -e "${Font_Blue}8. 主机测试-感谢融合怪项目${Font_Suffix}"
echo -e "${Font_Blue}0. 退出${Font_Suffix}"
echo -e "${Font_Blue}==============================${Font_Suffix}"
read -p "请输入数字选择操作: " choice

case $choice in
    1)
        curl -sSL https://raw.githubusercontent.com/goodbye-deepsea/ShellScript/refs/heads/main/add-pk.sh -o add-pk.sh && chmod +x add-pk.sh && ./add-pk.sh
        ;;
    2)
        curl -sSL https://raw.githubusercontent.com/goodbye-deepsea/ShellScript/refs/heads/main/editsshd.sh -o editsshd.sh && chmod +x editsshd.sh && ./editsshd.sh
        ;;
    3)
        curl -sSL https://raw.githubusercontent.com/goodbye-deepsea/ShellScript/refs/heads/main/ddns-modify.sh -o ddns-modify.sh && chmod +x ddns-modify.sh && ./ddns-modify.sh
        ;;
    4)
        curl -sSL https://raw.githubusercontent.com/goodbye-deepsea/ShellScript/refs/heads/main/enablebbr.sh -o enablebbr.sh && chmod +x enablebbr.sh && ./enablebbr.sh
        ;;
    5)
        curl -sSL https://raw.githubusercontent.com/goodbye-deepsea/ShellScript/refs/heads/main/add-swap.sh -o swap.sh && chmod +x swap.sh && ./swap.sh
        ;;
    6)
        read -p "请输入主机名（如：a.mjj.xyz）: " host
        read -p "请输入端口（如：8976）: " port
        read -p "请输入密码（如：ADycONs2Ssr1Axqosn）: " pwd
        if [[ -z "$host" || -z "$port" || -z "$pwd" ]]; then
            echo "缺少参数，强制退出！"
            exit 1
        fi
        curl -sSL https://raw.githubusercontent.com/goodbye-deepsea/ShellScript/refs/heads/main/nezha-agent.sh -o nezha.sh && chmod +x nezha.sh && ./nezha.sh --host "$host" --port "$port" --pwd "$pwd" --arg1 --disable-auto-update --arg2 --disable-force-update --disable_selinux --disable_root_execute
        ;;
    7)
        read -p "请输入系统类型（如：debian12）: " system
        read -p "请输入主机密码（如：5a4asa71-f4fd-469e-ba80-0a04f8c333ed）: " password
        read -p "请输入交换分区大小（如：1024）: " swap_size
        if [[ -z "$system" || -z "$password" || -z "$swap_size" ]]; then
            echo "缺少参数，强制退出！"
            exit 1
        fi
        curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh -o reinstall.sh && chmod +x reinstall.sh && ./reinstall.sh -debian "$system" -pwd "$password" -swap "$swap_size"
        ;;
    8)
        read -p "请输入主机测试模式（如：1）: " mode
        read -p "请输入测试区域（如：s）: " test_type
        if [[ -z "$mode" || -z "$test_type" ]]; then
            echo "缺少参数，强制退出！"
            exit 1
        fi
        curl -sSL https://github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -m "$mode" -r "$test_type" -banup -ctype gb5
        ;;
    9)
        echo "退出程序! "
        exit 0
        ;;
    *)
        echo "无效的选择！"
        exit 1
        ;;
esac
