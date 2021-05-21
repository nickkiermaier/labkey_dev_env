#!/bin/bash

# run as root!


# docker needs to be installed manually with a Mac

# setup dependencies
brew install git zip unzip wget curl dos2unix curl dos2unix


# add github keygen to prevent first time connection issues(note only do on dev machines)
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts
sleep 1

# disable quarantine
sudo defaults write com.apple.LaunchServices LSQuarantine -bool NO
