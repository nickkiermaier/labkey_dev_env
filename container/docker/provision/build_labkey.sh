#! /bin/bash
# idempotent script to build labkey application
# after this is run these env vars need to be set
start=`date +%s`
apt update 
apt install sudo git zip unzip wget subversion curl python nano -y


# output network speed
cd /tmp 
wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli 
python speedtest-cli --simple 

# set env vars
LABKEY_ROOT=/tmp/labkey
LABKEY_HOME=$LABKEY_ROOT/labkey

# remove labkey root if exists
rm -rf $LABKEY_ROOT

# build folder structure
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#folder
sudo mkdir -p $LABKEY_ROOT/apps
sudo mkdir -p $LABKEY_ROOT/backups
sudo mkdir -p $LABKEY_ROOT/labkey
sudo mkdir -p $LABKEY_ROOT/labkey/externalModules
sudo mkdir -p $LABKEY_ROOT/src
sudo mkdir -p $LABKEY_ROOT/tomcat-tmp


# third party setup
# _______________________________________
# java
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java
JAVA_VERSION="jdk-13.0.2"
JAVA_ZIP_FILE="openjdk-13.0.2_linux-x64_bin.tar.gz"
JAVA_URL="https://download.java.net/java/GA/jdk13.0.2/d4173c853231432d94f001e99d882ca7/8/GPL/$JAVA_ZIP_FILE"
cd $LABKEY_ROOT/src
wget  $JAVA_URL --progress=bar:force
tar -xvzf $JAVA_ZIP_FILE -C "$LABKEY_ROOT/apps"


# # tomcat
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
TOMCAT_VERSION="apache-tomcat-9.0.31"
TOMCAT_URL="http://apache-mirror.8birdsvideo.com/tomcat/tomcat-9/v9.0.31/bin/apache-tomcat-9.0.31.tar.gz"
TOMCAT_ZIP_FILE="apache-tomcat-9.0.31.tar.gz"
cd $LABKEY_ROOT/src
wget  $TOMCAT_URL --progress=bar:force
tar -xvzf $TOMCAT_ZIP_FILE -C "$LABKEY_ROOT/apps"

# # # checkout main app
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#checkout
cd $LABKEY_HOME

if svn checkout https://svn.mgt.labkey.host/stedi/trunk  ; then
    echo "svn chekcout succeeded"
else
	cd trunk
    svn cleanup
    svn update
fi


# # clone modules
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#coregit
cd trunk/server
git clone https://github.com/LabKey/testAutomation.git


echo "cloning module repos"

cd modules
git clone https://github.com/LabKey/platform.git
git clone https://github.com/LabKey/commonAssays.git
git clone https://github.com/LabKey/custommodules
git clone https://github.com/labkey/discvrlabkeymodules DiscvrLabKeyModules
git clone https://github.com/labkey/ehrModules
git clone https://github.com/labkey/LabDevKitModules
git clone https://github.com/labkey/platform


cd ../optionalmodules
git clone https://github.com/labkey/dataintegration
git clone https://github.com/labkey/tnprc_ehr

end=`date +%s`
runtime=$((end-start))
echo "Runtime is $runtime"