#!/bin/bash
# idempotent script to build labkey application
# after this is run these env vars need to be set


# set env vars
LABKEY_ROOT=~/Projects/labkey
LABKEY_HOME=$LABKEY_ROOT/labkey/trunk
LABKEY_HOME_WIN=$LABKEY_ROOT\\labkey\\trunk
PATH_ADDITION="C:\\Users\\nick\\Projects\\labkey\\trunk\\build\\deploy\\bin"


# cleanup
# delete entire app if present
rm -rf $LABKEY_ROOT
rm -rf ~/.gradle


# build folder structure
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#folder
mkdir -p $LABKEY_ROOT
mkdir -p $LABKEY_ROOT/apps
mkdir -p $LABKEY_ROOT/labkey
mkdir -p $LABKEY_ROOT/backups
mkdir -p $LABKEY_ROOT/src
mkdir -p $LABKEY_ROOT/src/labkey


# third party setup
# _______________________________________
# java
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#java
JAVA_DIR_LOCATION=$LABKEY_ROOT/apps/jdk-13.0.1
JAVA_ZIP_FILE=openjdk-13.0.1_windows-x64_bin.zip
JAVA_URL=https://download.java.net/java/GA/jdk13.0.1/cec27d702aa74d5a8630c65ae61e4305/9/GPL/openjdk-13.0.1_windows-x64_bin.zip
JAVA_HOME=C:\\Users\\nick\\Projects\\labkey\\apps\\jdk-13.0.1 # this is the windows path for apache
cd $LABKEY_ROOT/src
curl  $JAVA_URL -O
unzip $JAVA_ZIP_FILE -d "$LABKEY_ROOT/apps"


# # tomcat
# https://www.labkey.org/Documentation/wiki-page.view?name=installComponents#tom
TOMCAT_GRADLE_DIR_LOCATION=C:/Users/nick/Projects/labkey/apps/apache-tomcat-9.0.29 # this is the windows path for apache
CATALINA_HOME=C:\\Users\\nick\\Projects\\labkey\\apps\\apache-tomcat-9.0.29 # this is the windows path for apache
TOMCAT_URL=http://mirror.cc.columbia.edu/pub/software/apache/tomcat/tomcat-9/v9.0.29/bin/apache-tomcat-9.0.29-windows-x64.zip
TOMCAT_ZIP_FILE=apache-tomcat-9.0.29-windows-x64.zip
cd $LABKEY_ROOT/src
curl  $TOMCAT_URL -O
unzip $TOMCAT_ZIP_FILE -d "$LABKEY_ROOT/apps"

# # # checkout main app
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#checkout
svn checkout https://svn.mgt.labkey.host/stedi/trunk $LABKEY_HOME

# # clone modules
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#coregit
cd $LABKEY_HOME/server/modules
git clone https://github.com/LabKey/platform.git 
git clone https://github.com/LabKey/commonAssays.git 
cd ..
git clone https://github.com/LabKey/testAutomation.git


# # ~/.gradle setup
# https://www.labkey.org/Documentation/wiki-page.view?name=devMachine#gradle
cd ~
mkdir .gradle
cp $LABKEY_HOME/gradle/global_gradle.properties_template  ~/.gradle/gradle.properties
sed -i "s|systemProp.tomcat.home=/path/to/tomcat/home|systemProp.tomcat.home=$TOMCAT_WIN_DIR_LOCATION|g" ~/.gradle/gradle.properties


cp $LABKEY_HOME/.idea/workspace.template.xml $LABKEY_HOME/.idea/workspace.xml

echo "Please add these environmental variables."
echo "JAVA_HOME: $JAVA_HOME"
echo "CATALINA_HOME: $CATALINA_HOME"
echo "LABKEY_HOME: $LABKEY_HOME_WIN"

echo "Please add the following to your path"
echo $PATH_ADDITION

echo "Run $CATALINA_HOME\bin\startup.bat on windows or startup.sh on linux then visit localhost:8080."

