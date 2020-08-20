#!/bin/bash
# run as root !!!

# set env vars
APP_ROOT=/labkey_apps
mkdir $APP_ROOT $APP_ROOT/src $APP_ROOT/apps
chmod 777 -R $APP_ROOT
TOMCAT_URL=https://downloads.apache.org/tomcat/tomcat-9/v9.0.37/bin/apache-tomcat-9.0.37.tar.gz
TOMCAT_ZIP_FILE="apache-tomcat-9.0.37.tar.gz"
TOMCAT_VERSION="apache-tomcat-9.0.37"
TOMCAT_HOME=$APP_ROOT/apps/$TOMCAT_VERSION

echo "Removing Tomcat"
rm -rf $TOMCAT_HOME

echo  "downloading/extracting tomcat"
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
cd $APP_ROOT/src
wget  $TOMCAT_URL --progress=bar:force
tar -xvzf $TOMCAT_ZIP_FILE -C "$APP_ROOT/apps"

echo "Config tomcat directory for gradle msssql build"
chmod 777 -R $APP_ROOT
mkdir -p $TOMCAT_HOME/conf/Catalina/localhost

file=/etc/profile.d/labkey_tomcat_config.sh
if test -f "$file"; then
    rm $file
fi
touch $file
echo "export CATALINA_HOME=\"$TOMCAT_HOME\"" >> $file

