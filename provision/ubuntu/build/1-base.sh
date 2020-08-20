#!/bin/bash

# run as root
apt update
apt upgrade -y
apt install -y git zip unzip wget curl dos2unix subversion curl python python3 dos2unix net-tools docker.io docker-compose


# docker post installation
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker


# source /etc/profile
file=~/.profile
grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
echo "source /etc/profile"  >> $file

file=~/.bashrc
grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
echo "source /etc/profile"  >> $file