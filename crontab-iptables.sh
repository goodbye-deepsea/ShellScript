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
TMP_CRON_FILE=$(mktemp)
echo "$CRON_JOB" > "$TMP_CRON_FILE"
crontab "$TMP_CRON_FILE"
rm "$TMP_CRON_FILE"
echo "计划任务已添加到Crontab。"

