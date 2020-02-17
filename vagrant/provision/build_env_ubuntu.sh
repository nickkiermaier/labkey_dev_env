#!/bin/bash
# idempotent script to build labkey application
LABKEY_ROOT=/labkey

apt update
apt upgrade -y
apt install git zip unzip wget curl dos2unix subversion curl python -y

# output network speed
cd /tmp
wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli
python speedtest-cli --simple > speedtest
cat speedtest

mkdir $LABKEY_ROOT
chmod 777 $LABKEY_ROOT