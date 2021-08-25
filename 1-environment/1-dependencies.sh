#!/bin/bash

source ../shared-variables.sh

if [ "$OS_TYPE" = "Darwin" ]; then
    brew install git zip unzip
fi


if [ "$OS_TYPE" = "Linux" ]; then
    apt update
    apt upgrade -y
    apt install -y git zip unzip
fi


# add github keygen to prevent first time connection issues(note only do on dev machines)
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts
sleep 1
