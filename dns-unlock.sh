#!/bin/bash

if [ -x "$(command -v apt)" ]; then
    # Ubuntu/Debian
    if ! dpkg -l | grep -q "dnsmasq" || ! dpkg -l | grep -q "dnsutils" || ! dpkg -l | grep -q "bind9-utils"; then
        echo "One or more packages (dnsmasq, dnsutils, bind9-utils) are not installed. Installing..."
        apt update
        apt install dnsmasq dnsutils bind9-utils -y
    else
        echo "All packages (dnsmasq, dnsutils, bind9-utils) are already installed."
    fi
elif [ -x "$(command -v yum)" ]; then
    # CentOS
    if ! rpm -q dnsmasq &> /dev/null || ! rpm -q bind-utils &> /dev/null; then
        echo "One or more packages (dnsmasq, bind-utils) are not installed. Installing..."
        yum check-update
        yum install dnsmasq bind-utils -y
    else
        echo "All packages (dnsmasq, bind-utils) are already installed."
    fi
else
    echo "Unsupported package manager. Please install dnsmasq, dnsutils, and bind9-utils manually."
    exit 1
fi

read -p "please input your dns unlock domain: " domain 
LOCK_IP=$(dig +short ${domain})

cat << EOF > /etc/resolv.conf
nameserver 127.0.0.1
EOF

cat << EOF > /etc/dnsmasq.d/unlock.conf
server=1.1.1.1
server=8.8.8.8
server=/fast.com/${LOCK_IP}
server=/netflix.com/${LOCK_IP}
server=/netflix.net/${LOCK_IP}
server=/nflximg.net/${LOCK_IP}
server=/nflximg.com/${LOCK_IP}
server=/nflxvideo.net/${LOCK_IP}
server=/nflxso.net/${LOCK_IP}
server=/nflxext.com/${LOCK_IP}
server=/browser-intake-datadoghq.com/${LOCK_IP}
server=/static.cloudflareinsights.com/${LOCK_IP}
server=/ai.com/${LOCK_IP}
server=/algolia.net/${LOCK_IP}
server=/api.statsig.com/${LOCK_IP}
server=/auth0.com/${LOCK_IP}
server=/chatgpt.com/${LOCK_IP}
server=/chatgpt.livekit.cloud/${LOCK_IP}
server=/client-api.arkoselabs.com/${LOCK_IP}
server=/events.statsigapi.net/${LOCK_IP}
server=/featuregates.org/${LOCK_IP}
server=/host.livekit.cloud/${LOCK_IP}
server=/identrust.com/${LOCK_IP}
server=/intercom.io/${LOCK_IP}
server=/intercomcdn.com/${LOCK_IP}
server=/launchdarkly.com/${LOCK_IP}
server=/oaistatic.com/${LOCK_IP}
server=/oaiusercontent.com/${LOCK_IP}
server=/observeit.net/${LOCK_IP}
server=/segment.io/${LOCK_IP}
server=/sentry.io/${LOCK_IP}
server=/stripe.com/${LOCK_IP}
server=/turn.livekit.cloud/${LOCK_IP}
server=/ai.google.dev/${LOCK_IP}
server=/makersuite.google.com/${LOCK_IP}
server=/alkalimakersuite-pa.clients6.google.com/${LOCK_IP}
server=/bard.google.com/${LOCK_IP}
server=/deepmind.com/${LOCK_IP}
server=/deepmind.google/${LOCK_IP}
server=/gemini.google.com/${LOCK_IP}
server=/generativeai.google/${LOCK_IP}
server=/proactivebackend-pa.googleapis.com/${LOCK_IP}
server=/apis.google.com/${LOCK_IP}
EOF

echo "stop systemd-resolved and enable dnsmasq as default dns resolve"
systemctl stop systemd-resolved &>/dev/null
systemctl disable systemd-resolved &>/dev/null
systemctl enable dnsmasq
systemctl restart dnsmasq

echo -e "all done,testing......\\n"
nslookup google.com
nslookup openai.com
