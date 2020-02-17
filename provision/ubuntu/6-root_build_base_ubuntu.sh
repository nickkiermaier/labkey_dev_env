#!/bin/bash
# idempotent script to build labkey application
# This sets up everything in the labkey folder
# can be run as either root or user (depending on where ssh keys are located)

LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk
SQL_INSTALL_USER='labkey'
SQL_INSTALL_USER_PASSWORD='Password01!'

kill -9 'jobs '

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

# add github keygen to prevent first time connection issues(note only do on dev machines)
ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts

# # clone modules
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#coregit
cd trunk/server
git clone https://github.com/LabKey/testAutomation.git &
sleep 1

echo "cloning module repos"
cd modules
git clone https://github.com/LabKey/platform.git &
git clone https://github.com/LabKey/commonAssays.git &
git clone https://github.com/LabKey/custommodules &
git clone https://github.com/labkey/discvrlabkeymodules DiscvrLabKeyModules &
git clone https://github.com/labkey/ehrModules &
git clone https://github.com/labkey/LabDevKitModules &

echo "cloning optional module repos"
cd ../optionalModules
git clone git@github.com:LabKey/dataintegration.git &
git clone git@github.com:LabKey/tnprc_ehr.git &
wait

echo "config gradle mssql.properties"
sed -i "s|jdbcUser=sa|jdbcUser=$SQL_INSTALL_USER|g" $LABKEY_HOME/server/configs/mssql.properties
sed -i "s|jdbcPassword=sa|jdbcPassword=$SQL_INSTALL_USER_PASSWORD|g" $LABKEY_HOME/server/configs/mssql.properties

echo "config intellij workspace template"
cp $LABKEY_HOME/.idea/workspace.template.xml $LABKEY_HOME/.idea/workspace.xml

