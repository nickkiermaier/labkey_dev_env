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


#compatibility matrix
# https://www.labkey.org/Documentation/wiki-page.view?name=supported

# Java
# https://jdk.java.net/archive/
JAVA_HOME=$APP_ROOT/java
JAVA_VERSION="jdk-15.0.2.jdk"
JAVA_ZIP_FILE="openjdk-15.0.2_osx-x64_bin.tar.gz"
JAVA_URL=https://download.java.net/java/GA/jdk15.0.2/0d1cfde4252546c6931946de8db48ee2/7/GPL/$JAVA_ZIP_FILE

# Tomcat
# https://tomcat.apache.org/download-90.cgi
TOMCAT_HOME=$APP_ROOT/tomcat
TOMCAT_ZIP_FILE="apache-tomcat-9.0.52.tar.gz"
TOMCAT_URL=https://downloads.apache.org/tomcat/tomcat-9/v9.0.52/bin/$TOMCAT_ZIP_FILE
TOMCAT_VERSION="apache-tomcat-9.0.52"


# git
GIT_BRANCH=release21.7-SNAPSHOT
LABKEY_SERVER_REPO_URL=git@github.com:LabKey/server.git
LABKEY_REPO_MODULES_TO_INSTALL=( tnprc_ehr tnprc_billing platform ehrModules LabDevKitModules dataintegration commonAssays)

# sql
SQL_USER=sa
SQL_PASSWORD=Labkey1098!



