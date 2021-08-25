#!/bin/bash

# Rebiuld Labkey directories from scratch

source ../shared-variables.sh

echo "Deleting old labkey folder"
rm -rf $LABKEY_REPO
ls -la $LABKEY_HOME

./1-build-labkey-server.sh
./2-build-labkey-modules.sh

