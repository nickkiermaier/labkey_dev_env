#!/bin/bash
set -e

source ../shared-variables.sh

# configure Labkey

source ../get-env-setting.sh


read -p "Reset Intellij? Enter y for confirm.[yn] " choice
case "$choice" in
  y|Y ) echo "Resetting Intellij." && ./4-remove-intellij-config.sh;;
  n|N ) echo "Not resetting Intllij. Continuing.";;
  * ) echo "invalid";;
esac


./3-config-labkey.sh