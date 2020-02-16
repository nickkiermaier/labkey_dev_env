#!/bin/bash
# idempotent script to build labkey application
# after this is run these env vars need to be set
apt update 
apt install git zip unzip wget subversion curl python -y

# output network speed
cd /tmp 
wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli 
python speedtest-cli --simple

# set env vars
LABKEY_ROOT=/vagrant/labkey
LABKEY_HOME=/vagrant/labkey/labkey

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
sudo mkdir -p $LABKEY_ROOT/additional_steps


# third party setup
# _______________________________________
# java
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java
JAVA_VERSION="jdk-13.0.1"
JAVA_ZIP_FILE="openjdk-13.0.1_windows-x64_bin.zip"
JAVA_URL=https://download.java.net/java/GA/jdk13.0.1/cec27d702aa74d5a8630c65ae61e4305/9/GPL/openjdk-13.0.1_windows-x64_bin.zip
cd $LABKEY_ROOT/src
wget  $JAVA_URL --progress=bar:force
unzip $JAVA_ZIP_FILE -d "$LABKEY_ROOT/apps"

# # tomcat
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
TOMCAT_VERSION="apache-tomcat-9.0.29"
TOMCAT_URL=http://mirror.cc.columbia.edu/pub/software/apache/tomcat/tomcat-9/v9.0.29/bin/apache-tomcat-9.0.29-windows-x64.zip
TOMCAT_ZIP_FILE="apache-tomcat-9.0.29-windows-x64.zip"
cd $LABKEY_ROOT/src
wget  $TOMCAT_URL --progress=bar:force
unzip $TOMCAT_ZIP_FILE -d "$LABKEY_ROOT/apps"

# # # checkout main app
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#checkout
cd $LABKEY_HOME
svn checkout https://svn.mgt.labkey.host/stedi/trunk 

# # clone modules
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#coregit
cd trunk/server
git clone https://github.com/LabKey/testAutomation.git &


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

cp $LABKEY_HOME/trunk/.idea/workspace.template.xml $LABKEY_HOME/trunk/.idea/workspace.xml



# further windows setup
cd $LABKEY_ROOT/additional_steps
mkdir windows && cd windows
touch windows_todo.md

BASE_WIN_LOCATION="C:\Users\nick\Projects"
LABKEY_WIN_ROOT="$BASE_WIN_LOCATION\labkey"
CATALINA_WIN_HOME="$LABKEY_WIN_ROOT\apps\\$TOMCAT_VERSION"
JAVA_WIN_HOME="$LABKEY_WIN_ROOT\apps\\$JAVA_VERSION"
LABKEY_WIN_HOME="$LABKEY_WIN_ROOT\labkey\trunk"
GRADLE_TOMCAT_LOCATION="C:/Users/nick/Projects/labkey/apps/$TOMCAT_VERSION"


# gradle file
cp $LABKEY_HOME/trunk/gradle/global_gradle.properties_template  ./gradle.properties
sed -i "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$GRADLE_TOMCAT_LOCATION|g" ./gradle.properties




cat >> windows_todo.md <<EOL
* put this entire compiled folder into $BASE_WIN_LOCATION
* add this to your path: $LABKEY_WIN_HOME\build\deploy\bin
* copy gradle.properties to ~/.gradle
* add these environmental variables.
	* JAVA_HOME: $JAVA_WIN_HOME
	* CATALINA_HOME: $CATALINA_WIN_HOME
	* LABKEY_HOME: $LABKEY_WIN_HOME 
* Run $CATALINA_WIN_HOME\bin\startup.bat on windows or startup.sh on linux then visit localhost:8080.
EOL