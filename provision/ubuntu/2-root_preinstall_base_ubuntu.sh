#!/bin/bash
# run as root

APP_ROOT=/labkey_apps

echo "Removing App folders for idempotency"
rm -rf $APP_ROOT/*
echo "Making Labkey Apps folder stucture"
mkdir $APP_ROOT \
  $APP_ROOT/src \
  $APP_ROOT/apps

echo "chmod 777 app folders"
chmod -R 777 -R $APP_ROOT