#!/bin/bash

TOMCAT_VERSION="apache-tomcat-9.0.35"
APP_ROOT=/labkey_apps

echo "create generic tomcat symlinks"
sudo ln -s $APP_ROOT/apps/$TOMCAT_VERSION /usr/local/tomcat
chmod 777 -R $APP_ROOT


echo "config tomcat directory for gradle msssql build"
mkdir -p $CATALINA_HOME/conf/Catalina/localhost

