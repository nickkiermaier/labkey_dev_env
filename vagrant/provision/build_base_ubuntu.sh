#!/bin/bash
# idempotent script to build labkey application
# after this is run these env vars need to be set

# set env vars
LABKEY_ROOT=/labkey
LABKEY_REPO=$LABKEY_ROOT/labkey
LABKEY_HOME=$LABKEY_REPO/trunk

# remove labkey root if exists for idempotency
rm -rf $LABKEY_ROOT

# java env var
JAVA_ZIP_FILE="openjdk-13.0.2_linux-x64_bin.tar.gz"
JAVA_URL=https://download.java.net/java/GA/jdk13.0.2/d4173c853231432d94f001e99d882ca7/8/GPL/openjdk-13.0.2_linux-x64_bin.tar.gz

# tomcat env var
TOMCAT_URL=http://apache.spinellicreations.com/tomcat/tomcat-9/v9.0.31/bin/apache-tomcat-9.0.31.tar.gz
TOMCAT_ZIP_FILE="apache-tomcat-9.0.31.tar.gz"


# build folder structure
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#folder
sudo mkdir -p $LABKEY_ROOT/apps
sudo mkdir -p $LABKEY_ROOT/backups
sudo mkdir -p $LABKEY_ROOT/labkey
sudo mkdir -p $LABKEY_ROOT/labkey/externalModules
sudo mkdir -p $LABKEY_ROOT/src
sudo mkdir -p $LABKEY_ROOT/tomcat-tmp
sudo mkdir -p $LABKEY_ROOT/additional_steps


# third party setup
# _______________________________________
# java
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java
cd $LABKEY_ROOT/src
wget  $JAVA_URL --progress=bar:force
tar -xvzf $JAVA_ZIP_FILE -C "$LABKEY_ROOT/apps"

# # tomcat
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
cd $LABKEY_ROOT/src
wget  $TOMCAT_URL --progress=bar:force
tar -xvzf $TOMCAT_ZIP_FILE -C "$LABKEY_ROOT/apps"


# labkey setup
# ___________________________________________
# # # checkout main app
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#checkout
cd $LABKEY_REPO
svn checkout https://svn.mgt.labkey.host/stedi/trunk 

# add github keygen(note only do on dev machines)
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


cd ../optionalModules
git clone git@github.com:LabKey/dataintegration.git &
git clone git@github.com:LabKey/tnprc_ehr.git &
wait

chmod -R 777 $LABKEY_ROOT




