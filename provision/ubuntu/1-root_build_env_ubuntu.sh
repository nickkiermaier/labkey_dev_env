#!/bin/bash
# run as root
apt update
apt upgrade -y
apt install -y git zip unzip wget curl dos2unix subversion curl python python3 dos2unix net-tools



# output network speed
cd /tmp
wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli
python speedtest-cli --simple > speedtest
cat speedtest


