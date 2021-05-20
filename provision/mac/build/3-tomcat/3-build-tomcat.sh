#!/bin/bash
# run as root !!!

source ../shared-variables.sh

# make apps directories if not exist
mkdir $APP_ROOT $APP_ROOT/src $APP_ROOT/apps
chmod -R 777 $APP_ROOT


echo "Removing old Tomcat"
rm -rf $TOMCAT_HOME

echo  "Downloading/extracting Tomcat"
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
cd $APP_ROOT/src || exit
wget  $TOMCAT_URL --progress=bar:force
tar -xvzf $TOMCAT_ZIP_FILE -C "$APP_ROOT/apps"


# setup mssql
echo "Config tomcat directory for gradle msssql build"
chmod -R 777 $APP_ROOT
mkdir -p $TOMCAT_HOME/conf/Catalina/localhost

