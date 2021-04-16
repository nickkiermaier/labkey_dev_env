# set env vars

# locations
APP_ROOT=/labkey_apps
LABKEY_ROOT=/labkey
LABKEY_HOME=$LABKEY_ROOT/labkey
LABKEY_REPO=$LABKEY_HOME/server



# Java
JAVA_ZIP_FILE="openjdk-15.0.2_linux-x64_bin.tar.gz"
JAVA_URL=https://download.java.net/java/GA/jdk15.0.2/0d1cfde4252546c6931946de8db48ee2/7/GPL/openjdk-15.0.2_linux-x64_bin.tar.gz
JAVA_VERSION="jdk-15.0.2"
JAVA_HOME=$APP_ROOT/apps/$JAVA_VERSION


# tomcat
TOMCAT_URL=https://downloads.apache.org/tomcat/tomcat-9/v9.0.37/bin/apache-tomcat-9.0.37.tar.gz
TOMCAT_ZIP_FILE="apache-tomcat-9.0.37.tar.gz"
TOMCAT_VERSION="apache-tomcat-9.0.37"
TOMCAT_HOME=$APP_ROOT/apps/$TOMCAT_VERSION

# git branches
GIT_BRANCH=release21.3-SNAPSHOT
LABKEY_SERVER_REPO_URL=git@github.com:LabKey/server.git
LABKEY_REPO_MODULES_TO_INSTALL=( tnprc_ehr tnprc_billing platform ehrModules LabDevKitModules dataintegration)

# sql
SQL_USER=sa
SQL_PASSWORD=Labkey1098!


