#!/bin/bash
# run as root !!!


# set env vars
APP_ROOT=/labkey_apps
JAVA_ZIP_FILE="openjdk-15.0.2_linux-x64_bin.tar.gz"
JAVA_URL=https://download.java.net/java/GA/jdk15.0.2/0d1cfde4252546c6931946de8db48ee2/7/GPL/openjdk-15.0.2_linux-x64_bin.tar.gz
JAVA_VERSION="openjdk-15.0.2"
JAVA_HOME=$APP_ROOT/apps/$JAVA_VERSION

# make apps directories if not exist
mkdir $APP_ROOT $APP_ROOT/src $APP_ROOT/apps
chmod 777 -R $APP_ROOT


echo "Removing old Java"
rm -rf $JAVA_HOME

echo "Download/Extract Java"
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java
cd $APP_ROOT/src || exit
wget  $JAVA_URL --progress=bar:force
tar -xvzf $JAVA_ZIP_FILE -C "$APP_ROOT/apps"



# setup environmental variables
file=/etc/profile.d/labkey_java_config.sh
if test -f "$file"; then
    rm $file
fi
touch $file
echo "export JAVA_HOME=\"$JAVA_HOME\"" >> $file
echo "export PATH=\$PATH:$JAVA_HOME/bin" >> $file
