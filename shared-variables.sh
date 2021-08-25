# set env vars

# determine os type
OS_TYPE="$(uname -s)" # Darwin for mac Linux for Linux

echo "Using os_type: ${OS_TYPE}"

# locations
LABKEY_ROOT=~/labkey
APP_ROOT=$LABKEY_ROOT/apps
APP_SRC_ROOT=$LABKEY_ROOT/apps/src
LABKEY_HOME=$LABKEY_ROOT/labkey
LABKEY_REPO=$LABKEY_HOME/server

# Java
JAVA_HOME=$APP_ROOT/java
JAVA_VERSION="jdk-16.0.2.jdk"
JAVA_ZIP_FILE="openjdk-16.0.2_osx-x64_bin.tar.gz"
JAVA_URL=https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/$JAVA_ZIP_FILE

# tomcat
TOMCAT_HOME=$APP_ROOT/tomcat
TOMCAT_ZIP_FILE="apache-tomcat-10.0.10.tar.gz"
TOMCAT_URL=https://apache.osuosl.org/tomcat/tomcat-10/v10.0.10/bin/$TOMCAT_ZIP_FILE
TOMCAT_VERSION="apache-tomcat-10.0.10"


# git
GIT_BRANCH=release21.7-SNAPSHOT
LABKEY_SERVER_REPO_URL=git@github.com:LabKey/server.git
LABKEY_REPO_MODULES_TO_INSTALL=( tnprc_ehr tnprc_billing platform ehrModules LabDevKitModules dataintegration commonAssays)

# sql
SQL_USER=sa
SQL_PASSWORD=Labkey1098!



