#!/bin/bash
# run as root !!!

source ../shared-variables.sh

# make apps directories if not exist
mkdir $APP_ROOT $APP_ROOT/src $APP_ROOT/apps
chmod 777 -R $APP_ROOT


echo "Removing old Tomcat"
rm -rf $TOMCAT_HOME

echo  "Downloading/extracting Tomcat"
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
cd $APP_ROOT/src || exit
wget  $TOMCAT_URL --progress=bar:force
tar -xvzf $TOMCAT_ZIP_FILE -C "$APP_ROOT/apps"


# setup mssql
echo "Config tomcat directory for gradle msssql build"
chmod 777 -R $APP_ROOT
mkdir -p $TOMCAT_HOME/conf/Catalina/localhost


# setup environmental variable
#file=/etc/profile.d/labkey_tomcat_config.sh
#if test -f "$file"; then
#    rm $file
#fi
#touch $file
#echo "export CATALINA_HOME=\"$TOMCAT_HOME\"" >> $file

