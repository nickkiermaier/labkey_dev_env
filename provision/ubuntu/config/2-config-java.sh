#!/bin/bash

APP_ROOT=/labkey_apps
JAVA_VERSION="jdk-13.0.2"


echo "create generic java symlink"
sudo ln -s $APP_ROOT/apps/$JAVA_VERSION /usr/local/java
