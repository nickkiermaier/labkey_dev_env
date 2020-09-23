#!/bin/bash

# run as root!


# setup dependencies
apt update
apt upgrade -y
apt install -y git zip unzip wget curl dos2unix subversion curl python python3 dos2unix net-tools docker.io docker-compose


# source /etc/profile
tmp=$(mktemp)
file=~/.profile
grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
echo "source /etc/profile"  >> $file

file=~/.bashrc
grep -v "source /etc/profile" "$file" > "$tmp" && mv "$tmp" "$file"
echo "source /etc/profile"  >> $file


# add github keygen to prevent first time connection issues(note only do on dev machines)
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts
sleep 1


