#!/bin/bash

# set env vars
# run as root

APP_ROOT=/labkey_apps
mkdir $APP_ROOT $APP_ROOT/src $APP_ROOT/apps
chmod 777 -R $APP_ROOT
TOMCAT_URL=https://downloads.apache.org/tomcat/tomcat-9/v9.0.35/bin/apache-tomcat-9.0.35.tar.gz
TOMCAT_ZIP_FILE="apache-tomcat-9.0.35.tar.gz"
TOMCAT_VERSION="apache-tomcat-9.0.35"

echo  "downloading/extracting tomcat"
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
cd $APP_ROOT/src
wget  $TOMCAT_URL --progress=bar:force
tar -xvzf $TOMCAT_ZIP_FILE -C "$APP_ROOT/apps"


