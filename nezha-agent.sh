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

host=""
port=""
pwd=""
arg1=""
arg2=""
os_arch=""

NZ_BASE_PATH="/opt/nezha"
NZ_AGENT_PATH="${NZ_BASE_PATH}/agent"


show_help() {
    echo -e "${Font_Blue}Usage: $0 [options]${Font_Suffix}"
    echo -e "${Font_Green}Options:${Font_Suffix}"
    echo -e "  --host <host>      Specify the host address (required)"
    echo -e "  --port <port>      Specify the port number (required)"
    echo -e "  --pwd  <pwd>       Specify the secret key (required)"
    echo -e "  --arg1 <value>     Optional argument 1"
    echo -e "  --arg2 <value>     Optional argument 2"
    echo -e "  --"
    echo -e "  --help             Show this help message and exit"
    echo -e "  --disable_selinux"
    echo -e "  --disable_root_execute"
    echo -e "${Font_Yellow}Example:${Font_Suffix}"
    echo -e "  $0 --host 10.0.0.1 --port 8080 --pwd password --arg1 --disable-auto-update --arg2 --disable-force-update --disable_selinux --disable_root_execute"
    exit 0
}

if [[ "$1" == "--help" ]]; then
    show_help
fi

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

pre_check() {
    ## os_arch
    if uname -m | grep -q 'x86_64'; then
        os_arch="amd64"
    elif uname -m | grep -q 'i386\|i686'; then
        os_arch="386"
    elif uname -m | grep -q 'aarch64\|armv8b\|armv8l'; then
        os_arch="arm64"
    elif uname -m | grep -q 'arm'; then
        os_arch="arm"
    elif uname -m | grep -q 's390x'; then
        os_arch="s390x"
    elif uname -m | grep -q 'riscv64'; then
        os_arch="riscv64"
    else 
        echo -e "${Font_Red}Error: Unknown architecture.${Font_Suffix}"
        exit 1
    fi
}

selinux() {
    if command -v getenforce >/dev/null 2>&1; then
        status=$(getenforce)
        if [[ "$status" == "Enforcing" || "$status" == "Permissive" ]]; then
            echo "SELinux is $status, disabling it temporarily (requires reboot)."
            run_with_sudo setenforce 0 &>/dev/null
            run_with_sudo sed -ri 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        fi
    else
        echo "getenforce command not found.please disable selinux manually."
    fi
}

install_soft() {
    (command -v yum >/dev/null 2>&1 && run_with_sudo yum makecache && run_with_sudo yum install $@ selinux-policy -y) ||
    (command -v apt >/dev/null 2>&1 && run_with_sudo apt update && run_with_sudo apt install curl wget unzip tar vim  selinux-utils -y) ||
    (command -v pacman >/dev/null 2>&1 && run_with_sudo pacman -Syu $@ base-devel --noconfirm && install_arch) ||
    (command -v apt-get >/dev/null 2>&1 && run_with_sudo apt-get update && run_with_sudo apt-get install curl wget unzip tar vim  selinux-utils -y) ||
    (command -v apk >/dev/null 2>&1 && run_with_sudo apk update && run_with_sudo apk add $@ -f)
}

install_base() {
    (command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 && command -v getenforce >/dev/null 2>&1) ||
        (install_soft curl wget unzip libselinux-utils)
}

download_agent() {
    echo -e "${Font_Yellow}Downloading agent...${Font_Suffix}"
    region=$(curl -s ipinfo.io | awk '/"country"/ {print $2}' | tr -d ',"') &> /dev/null
    if [ "${region}" == "CN" ]; then
        NZ_AGENT_URL="https://github.com/nezhahq/agent/releases/download/v0.20.0/nezha-agent_linux_${os_arch}.zip"
    else
        NZ_AGENT_URL="https://github.com/nezhahq/agent/releases/download/v0.20.0/nezha-agent_linux_${os_arch}.zip"
    fi 
    echo -e "${Font_Yellow}Waiting...${Font_Suffix}"
    cd /opt && run_with_sudo wget -t 2 -T 60 -O nezha-agent_linux_${os_arch}.zip $NZ_AGENT_URL >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${Font_Red}Release download failed, please try again!${Font_Suffix}"
        return 1
    fi

    run_with_sudo mkdir -p $NZ_AGENT_PATH &> /dev/null
    run_with_sudo chmod -R 700 $NZ_AGENT_PATH
    
    run_with_sudo unzip -qo nezha-agent_linux_${os_arch}.zip &> /dev/null &&
    mv nezha-agent $NZ_AGENT_PATH &> /dev/null &&
    rm -rf nezha-agent_linux_${os_arch}.zip README.md
}

disable_root_execute(){
    if ! getent group nobody >/dev/null 2>&1; then
        run_with_sudo groupadd nobody
    fi
    if ! id -nG nobody | grep -qw nobody; then
        run_with_sudo usermod -a -G nobody nobody
    fi  
    run_with_sudo chown -R nobody:nobody /opt/nezha/agent/
    run_with_sudo sed -i.bak '/^WorkingDirectory/a User=nobody\nGroup=nobody' /etc/systemd/system/nezha-agent.service
    run_with_sudo systemctl daemon-reload &> /dev/null &&
    systemctl restart nezha-agent.service  &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${Font_Red}Disable root execute fail,you should disable it manually!${Font_Suffix}"
        exit 1
    else
        echo -e "${Font_Green}Disable root execute success!${Font_Suffix}"
    fi
}

install_agent() {
    while [ $# -gt 0 ]; do
        case $1 in
        --host)
            host=$2
            shift 2
            ;;
        --port)
            port=$2
            shift 2
            ;;
        --pwd)
            pwd=$2
            shift 2
            ;;
        --arg1)
            arg1=$2
            shift 2
            ;;
        --arg2)
            arg2=$2
            shift 2
            ;;
        --disable_selinux)
            disable_selinux=1
            shift 1
            ;;
        --disable_root_execute)
            disable_root_execute=1
            shift 1
            ;;
        *)
            echo -e "${Font_Red}Unknown Param: $1${Font_Suffix}"
            exit 1
            ;;
        esac
    done


    if [ -z "$host" ] || [ -z "$port" ] || [ -z "$pwd" ]; then
        echo -e "${Font_Red}Error: --host, --port, and --pwd are all required.${Font_Suffix}"
        exit 1
    fi

    install_base
    if [[ "${disable_selinux}"=="1" ]]; then
        selinux
    fi

    pre_check
    download_agent || exit 1 

    run_with_sudo ${NZ_AGENT_PATH}/nezha-agent service install -s "${host}:${port}" -p ${pwd} $arg1 $arg2 >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        run_with_sudo ${NZ_AGENT_PATH}/nezha-agent service uninstall >/dev/null 2>&1
        run_with_sudo ${NZ_AGENT_PATH}/nezha-agent service install -s "${host}:${port}" -p ${pwd} $arg1 $arg2 >/dev/null 2>&1
	run_with_sudo systemctl daemon-reload && run_with_sudo systemctl restart nezha-agent >/dev/null 2>&1
    fi
    run_with_sudo systemctl daemon-reload && run_with_sudo systemctl restart nezha-agent >/dev/null 2>&1

    if [[ "${disable_root_execute}"=="1" ]]; then
        disable_root_execute
    fi
    
    echo -e "${Font_Green}nezha-agent configuration  successfully, please reboot to take effect.${Font_Suffix}\n"
}

install_agent "$@"


