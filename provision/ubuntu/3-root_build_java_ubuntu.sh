#!/bin/bash
# run as root
# set env vars
APP_ROOT=/labkey_apps
mkdir $APP_ROOT $APP_ROOT/src $APP_ROOT/apps
JAVA_ZIP_FILE="openjdk-13.0.2_linux-x64_bin.tar.gz"
JAVA_URL=https://download.java.net/java/GA/jdk13.0.2/d4173c853231432d94f001e99d882ca7/8/GPL/openjdk-13.0.2_linux-x64_bin.tar.gz
JAVA_VERSION="jdk-13.0.2"

echo "download/extract java"
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java
cd $APP_ROOT/src
wget  $JAVA_URL --progress=bar:force
tar -xvzf $JAVA_ZIP_FILE -C "$APP_ROOT/apps"

echo "create generic java symlink"
sudo ln -s $APP_ROOT/apps/$JAVA_VERSION /usr/local/java
chmod 777 -R $APP_ROOT