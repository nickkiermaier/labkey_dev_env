#!/bin/bash

# BUILD TOMCAT

# make apps directories if not exist
mkdir $APP_ROOT $APP_ROOT/src $APP_ROOT/apps
chmod 777 -R $APP_ROOT


echo  "Downloading/extracting Tomcat"
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
wget  $TOMCAT_URL --progress=bar:force

# setup mssql
echo "Config tomcat directory for gradle msssql build"
chmod 777 -R $APP_ROOT


# setup environmental variable
file=/etc/profile.d/labkey_tomcat_config.sh
if test -f "$file"; then
    rm $file
fi
touch $file
echo "export \"" >> $file