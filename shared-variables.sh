# set env vars




# locations
LABKEY_ROOT=~/labkey
APP_ROOT=$LABKEY_ROOT/apps/apps
LABKEY_HOME=$LABKEY_ROOT/labkey
LABKEY_REPO=$LABKEY_HOME/server
JAVA_VERSION="jdk-15.0.2+7"
JAVA_HOME=$APP_ROOT/$JAVA_VERSION
TOMCAT_VERSION="apache-tomcat-9.0.46"
TOMCAT_HOME=$APP_ROOT/$TOMCAT_VERSION
GIT_BRANCH=release21.7-SNAPSHOT


# Java
JAVA_ZIP_FILE="openjdk-15.0.2_linux-x64_bin.tar.gz"
JAVA_URL=https://download.java.net/java/GA/jdk15.0.2/0d1cfde4252546c6931946de8db48ee2/7/GPL/openjdk-15.0.2_linux-x64_bin.tar.gz



# tomcat
TOMCAT_URL=https://downloads.apache.org/tomcat/tomcat-9/v9.0.46/bin/apache-tomcat-9.0.46.tar.gz
TOMCAT_ZIP_FILE="apache-tomcat-9.0.46.tar.gz"


# git branches
LABKEY_SERVER_REPO_URL=git@github.com:LabKey/server.git
LABKEY_REPO_MODULES_TO_INSTALL=( tnprc_ehr tnprc_billing platform ehrModules LabDevKitModules dataintegration commonAssays)

# sql
SQL_USER=sa
SQL_PASSWORD=Labkey1098!


