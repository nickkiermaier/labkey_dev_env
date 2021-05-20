#!/bin/bash
# run as root !!!

# get environmental variables
source ../shared-variables.sh

# make apps directories if not exist
mkdir $APP_ROOT $APP_ROOT/src $APP_ROOT/apps
chmod -R 777 $APP_ROOT

echo "Removing old Java"
rm -rf $JAVA_HOME

echo "Download/Extract Java"
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java
cd $APP_ROOT/src || exit
wget  $JAVA_URL --progress=bar:force
tar -xvzf $JAVA_ZIP_FILE -C "$APP_ROOT/apps"


