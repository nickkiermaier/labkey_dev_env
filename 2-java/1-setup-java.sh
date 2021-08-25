#!/bin/bash
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java

source ../shared-variables.sh

echo "Removing old Java"
cd $JAVA_HOME || exit
rm -rf ./*

echo "Download/Extracting Java to $APP_SRC_ROOT"
cd $APP_SRC_ROOT || exit
rm -rf ./*
wget  $JAVA_URL --progress=bar:force
tar -xvf $JAVA_ZIP_FILE


echo "Copying downloaded src to java home: $JAVA_HOME"
cp -R $JAVA_VERSION/Contents/Home/*  $JAVA_HOME
