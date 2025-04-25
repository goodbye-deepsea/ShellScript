#!/bin/bash

if [ -x "$(command -v apt)" ]; then
    # Ubuntu/Debian
    if ! dpkg -l | grep -q "cron"; then
        echo "crontab is not installed. Installing..."
        apt update
        apt install cron -y
    else
        echo "crontab is already installed."
    fi
elif [ -x "$(command -v yum)" ]; then
    # CentOS
    if ! rpm -q cronie &> /dev/null; then
        echo "crontab is not installed. Installing..."
        yum install cronie -y
    else
        echo "crontab is already installed."
    fi
else
    echo "Unsupported package manager. Please install crontab manually."
    exit 1
fi

CRON_JOB="* 5 * * * /bin/bash /root/UpdateIptables.sh"
# 创建一个临时文件来保存计划任务
TMP_CRON_FILE=$(mktemp)
# 将计划任务写入临时文件
echo "$CRON_JOB" > "$TMP_CRON_FILE"
# 使用crontab命令导入临时文件中的计划任务
crontab "$TMP_CRON_FILE"
# 清理临时文件
rm "$TMP_CRON_FILE"
echo "计划任务已添加到Crontab。"
