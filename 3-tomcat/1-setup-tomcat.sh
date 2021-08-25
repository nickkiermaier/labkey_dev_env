#!/bin/bash
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java

source ../shared-variables.sh

echo "Removing old Tomcat"
cd $TOMCAT_HOME || exit
rm -rf ./*

echo "Download/Extracting Tomcat to $APP_SRC_ROOT"
cd $APP_SRC_ROOT || exit
rm -rf ./*
wget  $TOMCAT_URL --progress=bar:force
tar -xvzf $TOMCAT_ZIP_FILE


echo "Copying downloaded src to java home: $TOMCAT_HOME"
cp -R $TOMCAT_VERSION/*  $TOMCAT_HOME


# make the conf directory for labkey to write to
# mkdir -p $TOMCAT_HOME/conf/Catalina/localhost