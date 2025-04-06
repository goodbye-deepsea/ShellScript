#! /bin/bash
# add a new ssh privateKey

# Check if lrzsz is installed and install if not
if [ -x "$(command -v apt)" ]; then
    # Ubuntu/Debian
    if ! dpkg -l | grep -q "lrzsz"; then
        echo "lrzsz is not installed. Installing..."
        apt update
        apt install lrzsz -y
    else
        echo "lrzsz is already installed."
    fi
elif [ -x "$(command -v yum)" ]; then
    # CentOS
    if ! rpm -q lrzsz &> /dev/null; then
        echo "lrzsz is not installed. Installing..."
        yum install lrzsz -y
    else
        echo "lrzsz is already installed."
    fi
else
    echo "Unsupported package manager. Please install lrzsz manually."
    exit 1
fi

read -p "please into a privateKey name: " privateKey
read -sp "please into a privateKey password: " passwd
echo
while [ -f "/root/.ssh/${privateKey}" ]; do
	read -p "key name ${privateKey} is exists,please input a new private key name: " privateKey
done
ssh-keygen -b 2048 -t rsa -N ${passwd}  -f /root/.ssh/${privateKey}
touch /root/.ssh/authorized_keys
cat /root/.ssh/${privateKey}.pub >> /root/.ssh/authorized_keys

chmod 600 /root/.ssh/authorized_keys  /root/.ssh/${privateKey}
chmod 700 ~/.ssh

systemctl restart sshd
systemctl status sshd

sz /root/.ssh/${privateKey}