#!/bin/bash

source ../shared-variables.sh


echo "Deleting old labkey folder"
rm -rf $LABKEY_REPO
ls -la $LABKEY_HOME



read -p "Reset Intellij? Enter y for confirm.[yn] " choice
case "$choice" in
  y|Y ) echo "Resetting Intellij." && ./4-remove-intellij-config.sh;;
  n|N ) echo "Not resetting Intllij. Continuing.";;
  * ) echo "invalid";;
esac

./1-build-labkey-server.sh
./2-build-labkey-modules.sh
./3-config-labkey.sh
