#!/bin/bash
# idempotent script to build labkey application
# This sets up everything in the labkey folder
# can be run as either root or user (depending on where ssh keys are located)

LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk

# clean out any jobs that may be stopped and holding up any of these files
kill -9 `jobs -ps`

# wipe/re-build folder structure
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#folder
echo "Wipe and Rebuild Labkey folder structure"
rm -rf $LABKEY_ROOT/*
mkdir -p $LABKEY_ROOT/apps \
 $LABKEY_ROOT/backups \
 $LABKEY_ROOT/labkey \
 $LABKEY_ROOT/labkey/externalModules \
 $LABKEY_ROOT/src \
 $LABKEY_ROOT/tomcat-tmp
chmod -R 777 $LABKEY_ROOT

# labkey setup
# ___________________________________________
# # # checkout main app
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#checkout
cd $LABKEY_REPO
svn checkout https://svn.mgt.labkey.host/stedi/trunk 
sleep 1
echo "SVN PULL SUCCESSFUL"

# add github keygen to prevent first time connection issues(note only do on dev machines)
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts
sleep 1
# # clone modules
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#coregit
cd trunk/server
git clone https://github.com/LabKey/testAutomation.git
sleep 1


# clone all of the module repes
echo "cloning module repos"
cd modules
git clone https://github.com/LabKey/platform.git
git clone https://github.com/LabKey/commonAssays.git
git clone https://github.com/LabKey/custommodules
git clone https://github.com/labkey/discvrlabkeymodules
git clone https://github.com/labkey/ehrModules
git clone https://github.com/labkey/LabDevKitModules
git clone git@github.com:LabKey/dataintegration.git
git clone git@github.com:LabKey/tnprc_ehr.git
wait

chown labkey -R $LABKEY_ROOT
