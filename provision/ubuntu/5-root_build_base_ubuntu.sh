#!/bin/bash
# run as root


LABKEY_ROOT=/labkey


# remove labkey root if exists for idempotency
rm -rf $LABKEY_ROOT

# build folder structure
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#folder
sudo mkdir -p $LABKEY_ROOT/apps
sudo mkdir -p $LABKEY_ROOT/backups
sudo mkdir -p $LABKEY_ROOT/labkey
sudo mkdir -p $LABKEY_ROOT/labkey/externalModules
sudo mkdir -p $LABKEY_ROOT/src
sudo mkdir -p $LABKEY_ROOT/tomcat-tmp
chmod -R 777 $LABKEY_ROOT

